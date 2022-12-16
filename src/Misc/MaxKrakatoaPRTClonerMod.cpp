// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0
#include "stdafx.h"

#include "resource.h"

//#include "MaxKrakatoaModifierInterface.h"
#include "MaxKrakatoaReferenceTarget.h"
#include "Objects\MaxKrakatoaPRTInterface.h"

#include <krakatoa/max3d/IPRTModifier.hpp>

#include <krakatoa/particle_repopulation.hpp>

#include <frantic/channels/channel_map_adaptor.hpp>
#include <frantic/channels/channel_map_const_iterator.hpp>
#include <frantic/graphics/boundbox3f.hpp>
#include <frantic/particles/particle_array.hpp>
#include <frantic/particles/particle_kdtree.hpp>
#include <frantic/particles/streams/empty_particle_istream.hpp>
#include <frantic/particles/streams/fractional_by_id_particle_istream.hpp>
#include <frantic/particles/streams/fractional_particle_istream.hpp>
#include <frantic/particles/streams/particle_container_particle_istream.hpp>
#include <frantic/particles/streams/transformed_particle_istream.hpp>

#include <frantic/max3d/convert.hpp>

#include <boost/algorithm/string.hpp>
#include <boost/random.hpp>

#define MaxKrakatoaPRTClonerMod_NAME _T("KrakatoaPRTCloner")
#define MaxKrakatoaPRTClonerModObject_CLASSID Class_ID( 0x20fc52ac, 0x4720336a )
#define MaxKrakatoaPRTClonerMod_VERSION 1

#define MaxKrakatoaPRTSpaceClonerMod_NAME _T( "KrakatoaPRTClonerWSM" )
#define MaxKrakatoaPRTSpaceClonerModObject_CLASSID Class_ID( 0x49b4699, 0x2c6f27eb )
#define MaxKrakatoaPRTSpaceClonerMod_VERSION 1

extern HINSTANCE hInstance;

using namespace frantic::graphics;
using frantic::channels::channel_accessor;
using frantic::channels::channel_cvt_accessor;

enum {
    // kSubsetFirstN,
    kSubsetEveryNth,
    kSubsetEveryNthID
};

enum { kCloneSelectionRoundRobin, kCloneSelectionShapeIndex };

enum { kUseClones, kUseSpheres, kUseRepopulation };

enum {
    kQuantityCount,
    kQuantitySpacing,
};

enum {
    kCloneNodes,
    kCloneNodeMethod,
    kViewportMode,
    kViewportLimit,
    kViewportPercentage,
    kCompensateDensityBySourceCount,
    kSetScaleToNeighborDistance,
    kScaleFactor,
    kCompensateSizeBySourceBounds,
    kReplacementMode,
    kSphereCount,
    kSphereRadius,
    kRandomSeed,
    kSphereSpacing,
    kSphereQuantityMode,
    kSphereFalloff,
    kRepopulationRadius,
    kRepopulationSubdivs,
    kRepopulationPerSubdiv,
    kRepopulationFalloffStart,
    kMultiplyColorChannels
};

enum { kMainPanel, kViewportPanel, kClonesPanel, kSpheresPanel, kRepopulationPanel, kMiscPanel };

ClassDesc2* GetMaxKrakatoaPRTClonerWSModDesc();
ClassDesc2* GetMaxKrakatoaPRTClonerOSModDesc();

template <typename ModType, typename Derived>
class MaxKrakatoaPRTClonerModBase : public MaxKrakatoaReferenceTarget<ModType, Derived>,
                                    public krakatoa::max3d::IPRTModifier {
    bool m_inRenderMode;

  public:
    MaxKrakatoaPRTClonerModBase() { m_inRenderMode = false; }

    virtual ~MaxKrakatoaPRTClonerModBase() {}

    // From IPRTModifier
    virtual particle_istream_ptr ApplyModifier( particle_istream_ptr pin, INode* pNode, TimeValue t,
                                                Interval& inoutValidity,
                                                frantic::max3d::particles::IMaxKrakatoaPRTEvalContextPtr evalContext ) {
        using namespace frantic::max3d::particles;

        particle_istream_ptr scatterStream = pin;

        if( m_pblock->GetInt( kSetScaleToNeighborDistance, t ) != FALSE ) {
            float scaleFactor = std::max( 1e-3f, m_pblock->GetFloat( kScaleFactor, t ) );

            scatterStream = apply_scale_by_neighbor_distance_stream( scatterStream, scaleFactor );
        }

        int replacementMode = m_pblock->GetInt( kReplacementMode );

        if( replacementMode == kUseClones ) {
            std::vector<particle_array_ptr> instanceParticles;

            for( int i = 0, iEnd = m_pblock->Count( kCloneNodes ); i < iEnd; ++i ) {
                INode* pSrcNode = m_pblock->GetINode( kCloneNodes, t, i );
                if( !pSrcNode )
                    continue;

                ObjectState os = pSrcNode->EvalWorldState( t );

                IMaxKrakatoaPRTObjectPtr srcObj = GetIMaxKrakatoaPRTObject( os.obj );
                if( !srcObj )
                    continue;

                Interval srcValidity = FOREVER;

                particle_istream_ptr pin = srcObj->CreateStream( pSrcNode, srcValidity, evalContext );

                inoutValidity &= srcValidity;

                // TODO: If we can request an ObjectSpace evaluation, we can get away with applying a single transform
                // here ...
                frantic::graphics::transform4f worldToNodeTM =
                    frantic::max3d::from_max_t( pSrcNode->GetNodeTM( t ) ).to_inverse();
                frantic::graphics::transform4f worldToNodeTMDeriv = frantic::graphics::transform4f::zero();

                pin = frantic::particles::streams::apply_transform_to_particle_istream( pin, worldToNodeTM,
                                                                                        worldToNodeTMDeriv );

                particle_array_ptr particles( new frantic::particles::particle_array( pin->get_native_channel_map() ) );

                particles->insert_particles( pin );

                instanceParticles.push_back( particles );
            }

            if( instanceParticles.empty() )
                return pin;

            int cloneSelectionMethod = m_pblock->GetInt( kCloneNodeMethod, t );
            const bool modulateColor = static_cast<bool>( m_pblock->GetInt( kMultiplyColorChannels, t ) );

            boost::shared_ptr<instancing_particle_istream> result( new instancing_particle_istream(
                scatterStream, instanceParticles, cloneSelectionMethod == kCloneSelectionShapeIndex, modulateColor ) );

            result->set_wants_shapeindex( cloneSelectionMethod == kCloneSelectionShapeIndex );

            result->set_compensate_density( m_pblock->GetInt( kCompensateDensityBySourceCount ) != FALSE );

            // result->set_compensate_size( scatterStream->get_native_channel_map().has_channel( _T("Scale") ) &&
            // m_pblock->GetInt(kCompensateSizeBySourceBounds) != FALSE );
            result->set_compensate_size( m_pblock->GetInt( kSetScaleToNeighborDistance, t ) != FALSE );

            scatterStream = result;

            if( !m_inRenderMode ) {
                int subsetMode = m_pblock->GetInt( kViewportMode, t );
                float percentage = frantic::math::clamp( m_pblock->GetFloat( kViewportPercentage, t ), 0.f, 1.f );
                boost::int64_t limit =
                    std::max( 0ll, static_cast<boost::int64_t>( m_pblock->GetFloat( kViewportLimit, t ) * 1000.0 ) );

                switch( subsetMode ) {
                /*case kSubsetFirstN:
                        scatterStream = frantic::particles::streams::apply_fractional_particle_istream( scatterStream,
                   percentage, limit, false ); break;*/
                default:
                case kSubsetEveryNth:
                    scatterStream = frantic::particles::streams::apply_fractional_particle_istream(
                        scatterStream, percentage, limit, true );
                    break;
                case kSubsetEveryNthID:
                    scatterStream = frantic::particles::streams::apply_fractional_by_id_particle_istream(
                        scatterStream, percentage, _T("ID"), limit );
                    break;
                }
            }

        } else if( replacementMode == kUseSpheres ) {
            boost::uint32_t randomSeed = static_cast<boost::uint32_t>( m_pblock->GetInt( kRandomSeed, t ) );

            int quantityMethod = m_pblock->GetInt( kSphereQuantityMode );

            int count = m_pblock->GetInt( kSphereCount, t );

            float radius = std::max( 1e-5f, m_pblock->GetFloat( kSphereRadius, t ) );

            float spacing = std::max( 1e-5f, m_pblock->GetFloat( kSphereSpacing, t ) );

            float falloff = std::max( 0.f, m_pblock->GetFloat( kSphereFalloff, t ) );

            bool compensateDensity = m_pblock->GetInt( kCompensateDensityBySourceCount ) != FALSE;

            const bool modulateColor = static_cast<bool>( m_pblock->GetInt( kMultiplyColorChannels, t ) );

            boost::shared_ptr<randomizing_particle_istream> result(
                new randomizing_particle_istream( scatterStream, randomSeed, modulateColor ) );

            if( quantityMethod == kQuantitySpacing ) {
                double sphereVolume = static_cast<double>( radius );
                sphereVolume *= sphereVolume * sphereVolume;
                sphereVolume *= ( 4.0 * M_PI / 3.0 );

                double particleVolume = static_cast<double>( spacing );
                particleVolume *= particleVolume * particleVolume;
                particleVolume *= ( 4.0 * M_PI / 3.0 );

                count = static_cast<int>( std::ceil( sphereVolume / particleVolume ) );
            }

            if( !m_inRenderMode ) {
                float percentage = frantic::math::clamp( m_pblock->GetFloat( kViewportPercentage, t ), 0.f, 1.f );

                count = static_cast<int>( std::ceil( static_cast<double>( count ) * percentage ) );
            }

            result->set_default_count( count );

            result->set_radius( radius );

            result->set_falloff( falloff );

            result->set_compensate_density( compensateDensity );

            scatterStream = result;

        } else if( replacementMode == kUseRepopulation ) {

            boost::uint32_t randomSeed = static_cast<boost::uint32_t>( m_pblock->GetInt( kRandomSeed, t ) );

            float radius = std::max( 1e-5f, m_pblock->GetFloat( kRepopulationRadius, t ) );

            int subdivs = std::max( 1, m_pblock->GetInt( kRepopulationSubdivs, t ) );

            int perSubdiv = std::max( 1, m_pblock->GetInt( kRepopulationPerSubdiv, t ) );

            float falloffStart = std::max( 1e-5f, m_pblock->GetFloat( kRepopulationFalloffStart, t ) );

            // bool compensateDensity = m_pblock->GetInt(kCompensateDensityBySourceCount) != FALSE;

            frantic::logging::null_progress_logger nullLogger;

            scatterStream = krakatoa::create_particle_repopulation_istream( scatterStream, radius, subdivs, perSubdiv,
                                                                            falloffStart, randomSeed, nullLogger );

            if( !m_inRenderMode ) {
                int subsetMode = m_pblock->GetInt( kViewportMode, t );
                float percentage = frantic::math::clamp( m_pblock->GetFloat( kViewportPercentage, t ), 0.f, 1.f );
                boost::int64_t limit =
                    std::max( 0ll, static_cast<boost::int64_t>( m_pblock->GetFloat( kViewportLimit, t ) * 1000.0 ) );

                switch( subsetMode ) {
                /*case kSubsetFirstN:
                        scatterStream = frantic::particles::streams::apply_fractional_particle_istream( scatterStream,
                   percentage, limit, false ); break;*/
                default:
                case kSubsetEveryNth:
                    scatterStream = frantic::particles::streams::apply_fractional_particle_istream(
                        scatterStream, percentage, limit, true );
                    break;
                case kSubsetEveryNthID:
                    scatterStream = frantic::particles::streams::apply_fractional_by_id_particle_istream(
                        scatterStream, percentage, _T("ID"), limit );
                    break;
                }
            }
        }

        scatterStream->set_channel_map( evalContext->GetDefaultChannels() );

        return scatterStream;
    }

    // From Animatable
    virtual BaseInterface* GetInterface( Interface_ID id ) {
        if( id == PRTModifier_INTERFACE )
            return static_cast<krakatoa::max3d::IPRTModifier*>( this );
        if( BaseInterface* result = krakatoa::max3d::IPRTModifier::GetInterface( id ) )
            return result;
        return MaxKrakatoaReferenceTarget<ModType, Derived>::GetInterface( id );
    }

    virtual int RenderBegin( TimeValue t, ULONG flags = 0 ) {
        m_inRenderMode = true;
        return TRUE;
    }

    virtual int RenderEnd( TimeValue t ) {
        m_inRenderMode = false;
        return TRUE;
    }

    // From ReferenceMaker
    virtual RefResult NotifyRefChanged( const Interval& changeInt, RefTargetHandle hTarget, PartID& partID,
                                        RefMessage message, BOOL /*propagate*/ ) {
        if( hTarget == m_pblock && message == REFMSG_CHANGE ) {
            int index = -1;
            ParamID paramID = m_pblock->LastNotifyParamID( index );

            RefResult result = REF_STOP;

            switch( paramID ) {
            case kCloneNodes:
                if( m_pblock->GetInt( kReplacementMode ) == kUseClones && index >= 0 &&
                    ( ( partID & PART_GEOM ) || ( partID & PART_TM ) ) )
                    result = REF_SUCCEED;
                break;
            case kCloneNodeMethod:
                if( m_pblock->GetInt( kReplacementMode ) == kUseClones )
                    result = REF_SUCCEED;
                break;

            case kScaleFactor:
                if( m_pblock->GetInt( kSetScaleToNeighborDistance ) != FALSE )
                    result = REF_SUCCEED;
                break;

            case kSphereCount:
            case kSphereRadius:
            case kSphereSpacing:
            case kSphereQuantityMode:
            case kSphereFalloff:
                if( m_pblock->GetInt( kReplacementMode ) == kUseSpheres )
                    result = REF_SUCCEED;
                break;

            case kRepopulationRadius:
            case kRepopulationSubdivs:
            case kRepopulationPerSubdiv:
            case kRepopulationFalloffStart:
                if( m_pblock->GetInt( kReplacementMode ) == kUseRepopulation )
                    result = REF_SUCCEED;
                break;

            default:
                result = REF_SUCCEED;
                break;
            };

            if( result == REF_SUCCEED )
                NotifyDependents( FOREVER, PART_GEOM, ( REFMSG_USER + 0x3561 ), NOTIFY_ALL, TRUE, this );

            return result;
        }
        return REF_DONTCARE;
    }

    // From BaseObject
#if MAX_VERSION_MAJOR >= 24
    virtual const TCHAR* GetObjectName( bool localized ) = 0;
#elif MAX_VERSION_MAJOR >= 15
    virtual const TCHAR* GetObjectName() = 0;
#else
    virtual TCHAR* GetObjectName() = 0;
#endif

    virtual CreateMouseCallBack* GetCreateMouseCallBack() { return NULL; }

    // From Modifier
    virtual Interval LocalValidity( TimeValue t ) {
        Interval iv = FOREVER;

        m_pblock->GetValidity( t, iv );

        if( !iv.InInterval( t ) )
            iv.SetInstant( t );

        return iv;
    }

    virtual ChannelMask ChannelsUsed() { return GEOM_CHANNEL; }

    virtual ChannelMask ChannelsChanged() { return 0; }

    virtual void ModifyObject( TimeValue /*t*/, ModContext& /*mc*/, ObjectState* /*os*/, INode* /*node*/ ) {}

    virtual Class_ID InputType() { return MaxKrakatoaPRTSourceObject_CLASSID; }
};

class MaxKrakatoaPRTClonerMod : public MaxKrakatoaPRTClonerModBase<OSModifier, MaxKrakatoaPRTClonerMod> {
  protected:
    virtual ClassDesc2* GetClassDesc() { return GetMaxKrakatoaPRTClonerOSModDesc(); }

  public:
    MaxKrakatoaPRTClonerMod() { GetClassDesc()->MakeAutoParamBlocks( this ); }

    // From BaseObject
#if MAX_VERSION_MAJOR >= 24
    virtual const TCHAR* GetObjectName( bool localized ) {
#elif MAX_VERSION_MAJOR >= 15
    virtual const TCHAR* GetObjectName(){
#else
    virtual TCHAR* GetObjectName() {
#endif
        return _T( "Krakatoa PRT Cloner" );
    }
};

class MaxKrakatoaPRTSpaceClonerMod : public MaxKrakatoaPRTClonerModBase<WSModifier, MaxKrakatoaPRTSpaceClonerMod> {
  protected:
    virtual ClassDesc2* GetClassDesc() { return GetMaxKrakatoaPRTClonerWSModDesc(); }

  public:
    MaxKrakatoaPRTSpaceClonerMod() { GetClassDesc()->MakeAutoParamBlocks( this ); }

    // From BaseObject
#if MAX_VERSION_MAJOR >= 24
    virtual const TCHAR* GetObjectName( bool localized )
#elif MAX_VERSION_MAJOR >= 15
    virtual const TCHAR* GetObjectName()
#else
    virtual TCHAR* GetObjectName()
#endif
    {
        return _T( "Krakatoa PRT Cloner" );
    }
};

class MaxKrakatoaPRTClonerModDesc : public ClassDesc2 {
    ParamBlockDesc2 m_paramDesc;

  public:
    MaxKrakatoaPRTClonerModDesc();

    virtual ~MaxKrakatoaPRTClonerModDesc() {}

    int IsPublic() { return TRUE; }
    virtual void* Create( BOOL /*loading*/ ) = 0;
    virtual const TCHAR* ClassName() = 0;
    virtual SClass_ID SuperClassID() = 0;
    virtual Class_ID ClassID() = 0;
    const TCHAR* Category() { return _T(""); }

    virtual const TCHAR* InternalName() = 0;    // returns fixed parsable name (scripter-visible name)
    HINSTANCE HInstance() { return hInstance; } // returns owning module handle
};

class MaxKrakatoaPRTClonerOSModDesc : public MaxKrakatoaPRTClonerModDesc {
    void* Create( BOOL /*loading*/ ) { return new MaxKrakatoaPRTClonerMod; }
    const TCHAR* ClassName() { return _T( "Krakatoa PRTCloner" ); }
#if MAX_VERSION_MAJOR >= 24
    const TCHAR* NonLocalizedClassName() { return _T( "Krakatoa PRTCloner" ); }
#endif
    SClass_ID SuperClassID() { return OSM_CLASS_ID; }
    Class_ID ClassID() { return MaxKrakatoaPRTClonerModObject_CLASSID; }
    const TCHAR* InternalName() { return _T( "KrakatoaPRTCloner" ); }
};

ClassDesc2* GetMaxKrakatoaPRTClonerOSModDesc() {
    static MaxKrakatoaPRTClonerOSModDesc theDesc;
    return &theDesc;
}

class MaxKrakatoaPRTClonerWSModDesc : public MaxKrakatoaPRTClonerModDesc {
    void* Create( BOOL /*loading*/ ) { return new MaxKrakatoaPRTSpaceClonerMod; }
    const TCHAR* ClassName() { return _T( "Krakatoa PRTCloner" ); }
#if MAX_VERSION_MAJOR >= 24
    const TCHAR* NonLocalizedClassName() { return _T( "Krakatoa PRTCloner" ); }
#endif
    SClass_ID SuperClassID() { return WSM_CLASS_ID; }
    Class_ID ClassID() { return MaxKrakatoaPRTSpaceClonerModObject_CLASSID; }
    const TCHAR* InternalName() { return _T( "KrakatoaPRTClonerWSM" ); }
};

ClassDesc2* GetMaxKrakatoaPRTClonerWSModDesc() {
    static MaxKrakatoaPRTClonerWSModDesc theDesc;
    return &theDesc;
}

class CloneNodeValidator : public PBValidator {
    static CloneNodeValidator s_theCloneNodeValidator;

  public:
    inline static PBValidator& GetInstance() { return s_theCloneNodeValidator; }

    virtual BOOL Validate( PB2Value& v ) {
        return v.r && static_cast<INode*>( v.r )->GetObjectRef()->FindBaseObject()->CanConvertToType(
                          MaxKrakatoaPRTSourceObject_CLASSID );
    }
};

CloneNodeValidator CloneNodeValidator::s_theCloneNodeValidator;

MaxKrakatoaPRTClonerModDesc::MaxKrakatoaPRTClonerModDesc()
    : m_paramDesc( 0,                                                     // Block num
                   _T("Parameters"),                                      // Internal name
                   NULL,                                                  // Localized name
                   NULL,                                                  // ClassDesc2*
                   P_AUTO_CONSTRUCT + P_AUTO_UI + P_MULTIMAP + P_VERSION, // Flags
                   MaxKrakatoaPRTClonerMod_VERSION,
                   0,                                                             // PBlock Ref Num
                   6, kMainPanel, IDD_PRTCLONER_MAIN, IDS_PARAMETERS, 0, 0, NULL, // AutoUI stuff for panel 0
                   kViewportPanel, IDD_PRTCLONER_VIEWPORT, IDS_PRTVOXEL_VIEWPORT, 0, 0,
                   NULL,                                                                     // AutoUI stuff for panel 1
                   kClonesPanel, IDD_PRTCLONER_CLONES, IDS_PRTCLONER_CLONES, 0, 0, NULL,     // AutoUI stuff for panel 2
                   kSpheresPanel, IDD_PRTCLONER_SPHERES, IDS_PRTCLONER_SPHERES, 0, 0, NULL,  // AutoUI stuff for panel 3
                   kRepopulationPanel, IDD_PRTCLONER_REPOP, IDS_PRTCLONER_REPOP, 0, 0, NULL, // AutoUI stuff for panel 4
                   kMiscPanel, IDD_PRTCLONER_MISC, IDS_PRTVOXEL_MISC, 0, 0, NULL,            // AutoUI stuff for panel 5
                   p_end ) {
    m_paramDesc.SetClassDesc( this );

    //------------------------------------------------------------------------------------------------------------------------------------------------------------------
    // Main rollout parameters
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------
    m_paramDesc.AddParam( kCloneNodes, _T("CloneNodes"), TYPE_INODE_TAB, 0, P_VARIABLE_SIZE, 0, p_end );
    m_paramDesc.ParamOption( kCloneNodes, p_validator, &CloneNodeValidator::GetInstance(), p_end );
    m_paramDesc.ParamOption( kCloneNodes, p_ui, kClonesPanel, TYPE_NODELISTBOX, IDC_PRTCLONER_CLONENODES_LIST,
                             IDC_PRTCLONER_CLONENODES_ADD_BUTTON, 0, IDC_PRTCLONER_CLONENODES_DELETE_BUTTON, p_end );

    m_paramDesc.AddParam( kCloneNodeMethod, _T("CloneSelectionMethod"), TYPE_INT, 0, 0, p_end );
    m_paramDesc.ParamOption( kCloneNodeMethod, p_default, kCloneSelectionRoundRobin, p_end );
    m_paramDesc.ParamOption( kCloneNodeMethod, p_ui, kClonesPanel, TYPE_RADIO, 2, IDC_PRTCLONER_ROUNDROBIN_RADIO,
                             IDC_PRTCLONER_SHAPEINDEX_RADIO, p_end );

    m_paramDesc.AddParam( kViewportMode, _T("ViewportMode"), TYPE_INT, 0, 0, p_end );
    m_paramDesc.ParamOption( kViewportMode, p_default, kSubsetEveryNth );
    m_paramDesc.ParamOption( kViewportMode, p_ui, kViewportPanel, TYPE_INT_COMBOBOX, IDC_PRTCLONER_SUBSET_DROPDOWN,
                             2 /*, IDS_SUBSET_TYPE1*/, IDS_SUBSET_TYPE2, IDS_SUBSET_TYPE3, p_end );

    m_paramDesc.AddParam( kViewportLimit, _T("ViewportLimit"), TYPE_FLOAT, 0, 0, p_end );
    m_paramDesc.ParamOption( kViewportLimit, p_default, 1000.f );
    m_paramDesc.ParamOption( kViewportLimit, p_range, 1.0f, 1000000.0f );
    m_paramDesc.ParamOption( kViewportLimit, p_ui, kViewportPanel, TYPE_SPINNER, EDITTYPE_POS_FLOAT,
                             IDC_PRTCLONER_LOADLIMIT_EDIT, IDC_PRTCLONER_LOADLIMIT_SPIN, SPIN_AUTOSCALE, p_end );

    m_paramDesc.AddParam( kViewportPercentage, _T("ViewportPercentage"), TYPE_PCNT_FRAC, 0, 0, p_end );
    m_paramDesc.ParamOption( kViewportPercentage, p_default, 0.1f );
    m_paramDesc.ParamOption( kViewportPercentage, p_ui, kViewportPanel, TYPE_SPINNER, EDITTYPE_POS_FLOAT,
                             IDC_PRTCLONER_LOADPERCENTAGE_EDIT, IDC_PRTCLONER_LOADPERCENTAGE_SPIN, SPIN_AUTOSCALE,
                             p_end );

    m_paramDesc.AddParam( kCompensateDensityBySourceCount, _T("CompensateDensity"), TYPE_BOOL, 0, 0, p_end );
    m_paramDesc.ParamOption( kCompensateDensityBySourceCount, p_default, TRUE );
    m_paramDesc.ParamOption( kCompensateDensityBySourceCount, p_ui, kMiscPanel, TYPE_SINGLECHEKBOX,
                             IDC_PRTCLONER_COMPENSATEDENSITY_CHECK, p_end );

    m_paramDesc.AddParam( kSetScaleToNeighborDistance, _T("SetScale"), TYPE_BOOL, 0, 0, p_end );
    m_paramDesc.ParamOption( kSetScaleToNeighborDistance, p_default, FALSE );
    m_paramDesc.ParamOption( kSetScaleToNeighborDistance, p_ui, kMiscPanel, TYPE_SINGLECHEKBOX,
                             IDC_PRTCLONER_SETSCALE_CHECK, p_end );

    m_paramDesc.AddParam( kScaleFactor, _T("ScaleFactor"), TYPE_FLOAT, P_ANIMATABLE, IDS_CLONER_SCALEFACTOR, p_end );
    m_paramDesc.ParamOption( kScaleFactor, p_default, 1.f );
    m_paramDesc.ParamOption( kScaleFactor, p_range, 1e-3f, FLT_MAX );
    m_paramDesc.ParamOption( kScaleFactor, p_ui, kMiscPanel, TYPE_SPINNER, EDITTYPE_POS_FLOAT,
                             IDC_PRTCLONER_SCALEMULTIPLY_EDIT, IDC_PRTCLONER_SCALEMULTIPLY_SPIN, SPIN_AUTOSCALE,
                             p_end );

    // m_paramDesc.AddParam(kCompensateSizeBySourceBounds, _T("CompensateSize"), TYPE_BOOL, 0, 0, p_end);
    // m_paramDesc.ParamOption(kCompensateSizeBySourceBounds, p_default, TRUE);
    // m_paramDesc.ParamOption(kCompensateSizeBySourceBounds, p_ui, kMiscPanel, TYPE_SINGLECHEKBOX,
    // IDC_PRTCLONER_COMPENSATEDENSITY_CHECK, p_end );

    m_paramDesc.AddParam( kReplacementMode, _T("ReplacementMode"), TYPE_INT, 0, 0, p_end );
    m_paramDesc.ParamOption( kReplacementMode, p_default, kUseSpheres );
    m_paramDesc.ParamOption( kReplacementMode, p_ui, kMainPanel, TYPE_RADIO, 3, IDC_PRTCLONER_USECLONES_RADIO,
                             IDC_PRTCLONER_USESPHERES_RADIO, IDC_PRTCLONER_USEREPOPULATION_RADIO, p_end );

    m_paramDesc.AddParam( kSphereCount, _T("SphereCount"), TYPE_INT, P_ANIMATABLE, IDS_PRTCLONER_COUNT, p_end );
    m_paramDesc.ParamOption( kSphereCount, p_default, 100 );
    m_paramDesc.ParamOption( kSphereCount, p_range, 1, INT_MAX );
    m_paramDesc.ParamOption( kSphereCount, p_ui, kSpheresPanel, TYPE_SPINNER, EDITTYPE_POS_INT,
                             IDC_PRTCLONER_SPHERECOUNT_EDIT, IDC_PRTCLONER_SPHERECOUNT_SPIN, SPIN_AUTOSCALE, p_end );

    m_paramDesc.AddParam( kSphereRadius, _T("SphereRadius"), TYPE_WORLD, P_ANIMATABLE, IDS_PRTCLONER_RADIUS, p_end );
    m_paramDesc.ParamOption( kSphereRadius, p_default, 1.f );
    m_paramDesc.ParamOption( kSphereRadius, p_range, 1e-4f, FLT_MAX );
    m_paramDesc.ParamOption( kSphereRadius, p_ui, kSpheresPanel, TYPE_SPINNER, EDITTYPE_POS_UNIVERSE,
                             IDC_PRTCLONER_SPHERERADIUS_EDIT, IDC_PRTCLONER_SPHERERADIUS_SPIN, SPIN_AUTOSCALE, p_end );

    m_paramDesc.AddParam( kRandomSeed, _T("RandomSeed"), TYPE_INT, P_ANIMATABLE, IDS_PRTCLONER_RANDOMSEED, p_end );
    m_paramDesc.ParamOption( kRandomSeed, p_default, 1234 );
    m_paramDesc.ParamOption( kRandomSeed, p_range, 0, INT_MAX );
    m_paramDesc.ParamOption( kRandomSeed, p_ui, kMainPanel, TYPE_SPINNER, EDITTYPE_POS_INT,
                             IDC_PRTCLONER_RANDOMSEED_EDIT, IDC_PRTCLONER_RANDOMSEED_SPIN, SPIN_AUTOSCALE, p_end );
    // m_paramDesc.ParamOption(kRandomSeed, p_ui, kSpheresPanel, TYPE_SPINNER, EDITTYPE_POS_INT,
    // IDC_PRTCLONER_RANDOMSEED_EDIT, IDC_PRTCLONER_RANDOMSEED_SPIN, SPIN_AUTOSCALE, p_end );
    // m_paramDesc.ParamOption(kRandomSeed, p_uix, kRepopulationPanel, p_end );

    m_paramDesc.AddParam( kSphereQuantityMode, _T("SphereQuantityMode"), TYPE_INT, 0, 0, p_end );
    m_paramDesc.ParamOption( kSphereQuantityMode, p_default, kQuantityCount );
    m_paramDesc.ParamOption( kSphereQuantityMode, p_ui, kSpheresPanel, TYPE_RADIO, 2, IDC_PRTCLONER_USECOUNT_RADIO,
                             IDC_PRTCLONER_USESPACING_RADIO, p_end );

    m_paramDesc.AddParam( kSphereSpacing, _T("kSphereSpacing"), TYPE_WORLD, P_ANIMATABLE, IDS_PRTCLONER_SPACING,
                          p_end );
    m_paramDesc.ParamOption( kSphereSpacing, p_default, 1.f );
    m_paramDesc.ParamOption( kSphereSpacing, p_range, 1e-4f, FLT_MAX );
    m_paramDesc.ParamOption( kSphereSpacing, p_ui, kSpheresPanel, TYPE_SPINNER, EDITTYPE_POS_UNIVERSE,
                             IDC_PRTCLONER_SPHERESPACING_EDIT, IDC_PRTCLONER_SPHERESPACING_SPIN, SPIN_AUTOSCALE,
                             p_end );

    m_paramDesc.AddParam( kSphereFalloff, _T("kSphereFalloff"), TYPE_FLOAT, P_ANIMATABLE, IDS_PRTCLONER_FALLOFF,
                          p_end );
    m_paramDesc.ParamOption( kSphereFalloff, p_default, 1.f );
    m_paramDesc.ParamOption( kSphereFalloff, p_range, 0.f, FLT_MAX );
    m_paramDesc.ParamOption( kSphereFalloff, p_ui, kSpheresPanel, TYPE_SPINNER, EDITTYPE_POS_FLOAT,
                             IDC_PRTCLONER_SPHEREFALLOFF_EDIT, IDC_PRTCLONER_SPHEREFALLOFF_SPIN, SPIN_AUTOSCALE,
                             p_end );

    m_paramDesc.AddParam( kRepopulationRadius, _T("RepopulationRadius"), TYPE_WORLD, P_ANIMATABLE, IDS_PRTCLONER_RADIUS,
                          p_end );
    m_paramDesc.ParamOption( kRepopulationRadius, p_default, 1.f );
    m_paramDesc.ParamOption( kRepopulationRadius, p_range, 1e-4f, FLT_MAX );
    m_paramDesc.ParamOption( kRepopulationRadius, p_ui, kRepopulationPanel, TYPE_SPINNER, EDITTYPE_POS_UNIVERSE,
                             IDC_PRTCLONER_REPOPRADIUS_EDIT, IDC_PRTCLONER_REPOPRADIUS_SPIN, SPIN_AUTOSCALE, p_end );

    m_paramDesc.AddParam( kRepopulationSubdivs, _T("RepopulationSubdivisions"), TYPE_INT, P_ANIMATABLE,
                          IDS_PRTCLONER_SUBDIVISIONS, p_end );
    m_paramDesc.ParamOption( kRepopulationSubdivs, p_default, 1 );
    m_paramDesc.ParamOption( kRepopulationSubdivs, p_range, 1, INT_MAX );
    m_paramDesc.ParamOption( kRepopulationSubdivs, p_ui, kRepopulationPanel, TYPE_SPINNER, EDITTYPE_POS_INT,
                             IDC_PRTCLONER_REPOPSUBDIVS_EDIT, IDC_PRTCLONER_REPOPSUBDIVS_SPIN, SPIN_AUTOSCALE, p_end );

    m_paramDesc.AddParam( kRepopulationPerSubdiv, _T("RepopulationPerSubdiv"), TYPE_INT, P_ANIMATABLE,
                          IDS_PRTCLONER_PERSUBDIVISION, p_end );
    m_paramDesc.ParamOption( kRepopulationPerSubdiv, p_default, 1 );
    m_paramDesc.ParamOption( kRepopulationPerSubdiv, p_range, 1, INT_MAX );
    m_paramDesc.ParamOption( kRepopulationPerSubdiv, p_ui, kRepopulationPanel, TYPE_SPINNER, EDITTYPE_POS_INT,
                             IDC_PRTCLONER_REPOPMULTIPLIER_EDIT, IDC_PRTCLONER_REPOPMULTIPLIER_SPIN, SPIN_AUTOSCALE,
                             p_end );

    m_paramDesc.AddParam( kRepopulationFalloffStart, _T("kRepopulationFalloffStart"), TYPE_WORLD, P_ANIMATABLE,
                          IDS_PRTCLONER_FALLOFFSTART, p_end );
    m_paramDesc.ParamOption( kRepopulationFalloffStart, p_default, 0.f );
    m_paramDesc.ParamOption( kRepopulationFalloffStart, p_range, 0.f, FLT_MAX );
    m_paramDesc.ParamOption( kRepopulationFalloffStart, p_ui, kRepopulationPanel, TYPE_SPINNER, EDITTYPE_POS_UNIVERSE,
                             IDC_PRTCLONER_REPOPFALLOFF_EDIT, IDC_PRTCLONER_REPOPFALLOFF_SPIN, SPIN_AUTOSCALE, p_end );

    m_paramDesc.AddParam( kMultiplyColorChannels, _T( "MultiplyColorChannels" ), TYPE_BOOL, 0, 0, p_end );
    m_paramDesc.ParamOption( kMultiplyColorChannels, p_default, TRUE );
    m_paramDesc.ParamOption( kMultiplyColorChannels, p_ui, kMiscPanel, TYPE_SINGLECHEKBOX,
                             IDC_PRTCLONER_MULTCOLOR_CHECK, p_end );
}

namespace {

typedef boost::shared_ptr<frantic::particles::streams::particle_istream> particle_istream_ptr;
typedef boost::shared_ptr<frantic::particles::particle_array> particle_array_ptr;

class instancing_particle_istream : public frantic::particles::streams::delegated_particle_istream {
  protected:
    boost::int64_t m_particleIndex;

    boost::scoped_array<char> m_defaultParticle;
    boost::scoped_array<char> m_curParticle;

    frantic::channels::channel_map_adaptor
        m_adaptor; // Only used for sources with 0 particles. The incoming particle is adapted without change.
    frantic::channels::channel_map m_channelMap, m_nativeMap;

    std::map<frantic::tstring, frantic::tstring>
        m_renamedChannels; // Record which delegate channels are conflicting and therefore should be renamed.
    frantic::channels::channel_map_adaptor
        m_delegateAdaptor; // The delegate's channels are passed through but prefixed with Source_

    struct source_data {
        particle_array_ptr particles;
        frantic::channels::channel_map_adaptor adaptor;
        size3f size;
    };

    std::vector<source_data> m_srcData;
    std::vector<source_data>::const_iterator m_currentSrc;
    frantic::particles::particle_array::const_iterator m_currentParticleIt, m_currentParticleItEnd;

    frantic::channels::channel_accessor<vector3f> m_posAccessor;
    frantic::channels::channel_cvt_accessor<quat4f> m_orientationAccessor;
    frantic::channels::channel_cvt_accessor<vector3f> m_scale3Accessor;
    frantic::channels::channel_cvt_accessor<vector3f> m_velAccessor;
    frantic::channels::channel_cvt_accessor<color3f> m_colorAccessor;
    frantic::channels::channel_cvt_accessor<float> m_scaleAccessor;
    frantic::channels::channel_cvt_accessor<float> m_densityAccessor;

    frantic::channels::channel_accessor<vector3f> m_destPosAccessor;
    frantic::channels::channel_cvt_accessor<vector3f> m_destVelAccessor;
    frantic::channels::channel_cvt_accessor<vector3f> m_destNormalAccessor;
    frantic::channels::channel_cvt_accessor<color3f> m_destColorAccessor;
    frantic::channels::channel_cvt_accessor<quat4f> m_destOrientationAccessor;
    frantic::channels::channel_cvt_accessor<float> m_destDensityAccessor;

    frantic::channels::channel_cvt_accessor<int> m_objIndexAccessor;

    bool m_compensateDensity;
    bool m_compensateSize;

    float m_densityFactor;
    vector3f m_destPos;
    vector3f m_destScale;
    vector3f m_destVelocity;
    color3f m_destColor;
    quat4f m_destOrientation;

    transform4f m_destXForm, m_destXFormInv;

    bool m_useShapeIndex;
    const bool m_modulateColor;

  public:
    inline static void get_delegate_channel_map( frantic::channels::channel_map& outMap,
                                                 const frantic::channels::channel_map& availableChannels ) {
        outMap.define_channel<vector3f>( _T("Position") );

        if( availableChannels.has_channel( _T("Density") ) )
            outMap.define_channel<float>( _T("Density") );

        if( availableChannels.has_channel( _T("Scale") ) ) {
            if( availableChannels[_T("Scale")].arity() == 1 )
                outMap.define_channel<float>( _T("Scale") );
            else
                outMap.define_channel<vector3f>( _T("Scale") );
        }

        if( availableChannels.has_channel( _T("Velocity") ) )
            outMap.define_channel<vector3f>( _T("Velocity") );

        if( availableChannels.has_channel( _T("Color") ) )
            outMap.define_channel<color3f>( _T("Color") );

        if( availableChannels.has_channel( _T("Orientation") ) )
            outMap.define_channel<quat4f>( _T("Orientation") );

        if( availableChannels.has_channel( _T("ShapeIndex") ) )
            outMap.define_channel<int>( _T("ShapeIndex") );
    }

  private:
    void init_native_map() {
        m_nativeMap.reset();
        m_renamedChannels.clear();

        for( std::vector<source_data>::const_iterator it = m_srcData.begin(), itEnd = m_srcData.end(); it != itEnd;
             ++it )
            m_nativeMap.union_channel_map( it->particles->get_channel_map() );

        // Some channels from the delegate are added to the native map too.
        const frantic::channels::channel_map& delegateNativeMap = m_delegate->get_native_channel_map();

        for( frantic::channels::channel_map_const_iterator it = frantic::channels::begin( delegateNativeMap ),
                                                           itEnd = frantic::channels::end( delegateNativeMap );
             it != itEnd; ++it ) {
            // If adding the delegate's channel would cause a name collision, we prefix the channel with "Source_"
            // If a "Source_*" channel already exists in the delegate stream, we don't use it to allow for multiple
            // layers of PRTCloner.
            if( !boost::algorithm::starts_with( it->name(), _T( "Source_" ) ) ) {
                if( m_nativeMap.has_channel( it->name() ) ) {
                    frantic::tstring newName = _T( "Source_" ) + it->name();

                    m_renamedChannels[it->name()] = newName;

                    if( !m_nativeMap.has_channel( newName ) ) {
                        m_nativeMap.define_channel( newName, it->arity(), it->data_type() );
                    }
                } else {
                    m_nativeMap.define_channel( it->name(), it->arity(), it->data_type() );
                }
            }
        }

        m_nativeMap.end_channel_definition();
    }

    template <class T>
    frantic::channels::channel_cvt_accessor<T> get_delegate_cvt_accessor( const frantic::channels::channel_map& map,
                                                                          const frantic::tstring& name,
                                                                          T defaultValue ) {
        return map.has_channel( *pName ) ? map.get_cvt_accessor<T>( *pName )
                                         : frantic::channels::channel_cvt_accessor<T>( defaultValue );
    }

    void init_delegate() {
        frantic::channels::channel_map delegateMap;

        const frantic::channels::channel_map& delegateNativeMap = m_delegate->get_native_channel_map();

        // Collect the channels we need for cloning.
        get_delegate_channel_map( delegateMap, delegateNativeMap );

        // Add any channels that should be forwarded from the delegate.
        for( frantic::channels::channel_map_const_iterator it = frantic::channels::begin( m_channelMap ),
                                                           itEnd = frantic::channels::end( m_channelMap );
             it != itEnd; ++it ) {
            const frantic::tstring* pName = &it->name();

            // This channel might have been renamed so search the rename list for a match so we can invert the name
            // mapping.
            // TODO: This is a linear search...
            for( std::map<frantic::tstring, frantic::tstring>::const_iterator itMap = m_renamedChannels.begin(),
                                                                              itMapEnd = m_renamedChannels.end();
                 itMap != itMapEnd; ++itMap ) {
                if( itMap->second == *pName ) {
                    pName = &itMap->first;
                    break;
                }
            }

            // If we haven't already requested this channel, add it to the delegate map if it is available.
            if( !delegateMap.has_channel( *pName ) && delegateNativeMap.has_channel( *pName ) ) {
                const frantic::channels::channel& ch = delegateNativeMap[*pName];
                delegateMap.define_channel( ch.name(), ch.arity(), ch.data_type() );
            }
        }

        delegateMap.end_channel_definition();

        // Some channels that might not be renamed (ie. they are passed through without a Source_ prefix), but need to
        // be handled specially (because we set their value manually) must be removed from the map used with
        // m_delegateAdaptor.
        frantic::channels::channel_map passThroughChannels = delegateMap;

        if( passThroughChannels.has_channel( _T("Position") ) &&
            m_renamedChannels.find( _T("Position") ) == m_renamedChannels.end() )
            passThroughChannels.delete_channel( _T("Position"), true );
        if( passThroughChannels.has_channel( _T("Density") ) &&
            m_renamedChannels.find( _T("Density") ) == m_renamedChannels.end() )
            passThroughChannels.delete_channel( _T("Density"), true );
        if( passThroughChannels.has_channel( _T("Velocity") ) &&
            m_renamedChannels.find( _T("Velocity") ) == m_renamedChannels.end() )
            passThroughChannels.delete_channel( _T("Velocity"), true );
        if( passThroughChannels.has_channel( _T("Color") ) &&
            m_renamedChannels.find( _T("Color") ) == m_renamedChannels.end() )
            passThroughChannels.delete_channel( _T("Color"), true );
        if( passThroughChannels.has_channel( _T("Orientation") ) &&
            m_renamedChannels.find( _T("Orientation") ) == m_renamedChannels.end() )
            passThroughChannels.delete_channel( _T("Orientation"), true );

        m_delegate->set_channel_map( delegateMap );
        m_adaptor.set( m_channelMap, delegateMap ); // We have an adaptor for when there are no particles in a clone so
                                                    // we pass through the delegate's particle unchanged.
        m_delegateAdaptor.set( m_channelMap, passThroughChannels,
                               m_renamedChannels ); // We have an adaptor for channels in the delegate that collide with
                                                    // the clone's channels.

        m_posAccessor = delegateMap.get_accessor<vector3f>( _T("Position") );
        m_densityAccessor = delegateMap.has_channel( _T("Density") )
                                ? delegateMap.get_cvt_accessor<float>( _T("Density") )
                                : frantic::channels::channel_cvt_accessor<float>( 1.f );
        m_velAccessor = delegateMap.has_channel( _T("Velocity") )
                            ? delegateMap.get_cvt_accessor<vector3f>( _T("Velocity") )
                            : frantic::channels::channel_cvt_accessor<vector3f>( vector3f() );
        m_colorAccessor = delegateMap.has_channel( _T("Color") )
                              ? delegateMap.get_cvt_accessor<color3f>( _T("Color") )
                              : frantic::channels::channel_cvt_accessor<color3f>( color3f::white() );
        m_orientationAccessor = delegateMap.has_channel( _T("Orientation") )
                                    ? delegateMap.get_cvt_accessor<quat4f>( _T("Orientation") )
                                    : frantic::channels::channel_cvt_accessor<quat4f>( quat4f() );

        m_scale3Accessor.reset();
        m_scaleAccessor.reset();

        if( delegateMap.has_channel( _T("Scale") ) ) {
            if( delegateMap[_T("Scale")].arity() == 1 )
                m_scaleAccessor = delegateMap.get_cvt_accessor<float>( _T("Scale") );
            else
                m_scale3Accessor = delegateMap.get_cvt_accessor<vector3f>( _T("Scale") );
        }

        if( m_useShapeIndex ) {
            m_objIndexAccessor.reset( 0 );
        } else {
            m_objIndexAccessor.reset();
        }

        if( delegateMap.has_channel( _T("ShapeIndex") ) && m_useShapeIndex )
            m_objIndexAccessor = delegateMap.get_cvt_accessor<int>( _T("ShapeIndex") );

        // TODO: This can cause failure now if someone calls set_channel_map after previously calling get_particle()
        // since this clobbers a cached particle.
        m_curParticle.reset( new char[delegateMap.structure_size()] );

        delegateMap.construct_structure( m_curParticle.get() );
    }

    void set_channel_map_impl( const frantic::channels::channel_map& map ) {
        m_channelMap = map;

        this->init_delegate();

        for( std::vector<source_data>::iterator it = m_srcData.begin(), itEnd = m_srcData.end(); it != itEnd; ++it )
            it->adaptor.set( m_channelMap, it->particles->get_channel_map() );

        m_destPosAccessor = m_channelMap.get_accessor<vector3f>( _T("Position") );
        m_destVelAccessor = m_channelMap.has_channel( _T("Velocity") )
                                ? m_channelMap.get_cvt_accessor<vector3f>( _T("Velocity") )
                                : channel_cvt_accessor<vector3f>();
        m_destNormalAccessor = m_channelMap.has_channel( _T("Normal") )
                                   ? m_channelMap.get_cvt_accessor<vector3f>( _T("Normal") )
                                   : channel_cvt_accessor<vector3f>();
        m_destColorAccessor =
            m_channelMap.has_channel( _T("Color") ) && m_delegate->get_channel_map().has_channel( _T("Color") )
                ? m_channelMap.get_cvt_accessor<color3f>( _T("Color") )
                : channel_cvt_accessor<color3f>();
        m_destOrientationAccessor = m_channelMap.has_channel( _T("Orientation") )
                                        ? m_channelMap.get_cvt_accessor<quat4f>( _T("Orientation") )
                                        : channel_cvt_accessor<quat4f>();
        m_destDensityAccessor = m_channelMap.has_channel( _T("Density") )
                                    ? m_channelMap.get_cvt_accessor<float>( _T("Density") )
                                    : channel_cvt_accessor<float>();
    }

  protected:
    inline virtual bool always_retain_color() { return false; }

    // instancing_particle_istream( particle_istream_ptr delegatePin )
    //	: frantic::particles::streams::delegated_particle_istream( delegatePin ), m_particleIndex( -1 )
    //{
    //	m_srcData.clear();
    //	m_currentSrc = m_srcData.end();

    //	m_compensateDensity = true;
    //	m_compensateSize = false;

    //	//Some channels from the delegate are added to the native map too.
    //	const frantic::channels::channel_map& delegateNativeMap = m_delegate->get_native_channel_map();

    //	if( !m_nativeMap.has_channel( _T("Orientation") ) && delegateNativeMap.has_channel( _T("Orientation") ) )
    //		m_nativeMap.define_channel<quat4f>( _T("Orientation") );
    //
    //	if( !m_nativeMap.has_channel( _T("Velocity") ) && delegateNativeMap.has_channel( _T("Velocity") ) )
    //		m_nativeMap.define_channel<vector3f>( _T("Velocity") );

    //	if( !m_nativeMap.has_channel( _T("Color") ) && delegateNativeMap.has_channel( _T("Color") ) )
    //		m_nativeMap.define_channel<color3f>( _T("Color") );

    //	if( !m_nativeMap.has_channel( _T("Density") ) && delegateNativeMap.has_channel( _T("Density") ) )
    //		m_nativeMap.define_channel<float>( _T("Density") );

    //	m_nativeMap.end_channel_definition();
    //	m_channelMap = m_delegate->get_channel_map();

    //	init_delegate();

    //	set_channel_map_impl( m_channelMap );

    //	m_destColor = color3f::white();
    //	m_destScale = vector3f( 1.f );
    //	m_densityFactor = 1.f;
    //}

    /**
     * Called when a new delegate particle is produced in order to choose the collection of particles that will replace
     * it.
     * @post The protected member variable: 'm_currentSrc', 'm_currentParticleIt', and 'm_currentParticleItEnd' will be
     * updated for the next particle's replacements
     */
    virtual void prepare_next_source() {
        if( !m_objIndexAccessor.is_valid() && !m_objIndexAccessor.is_default() ) {
            if( m_currentSrc == m_srcData.end() || ++m_currentSrc == m_srcData.end() )
                m_currentSrc = m_srcData.begin();
            m_currentParticleIt = m_currentSrc->particles->begin();
            m_currentParticleItEnd = m_currentSrc->particles->end();
        } else {
            std::ptrdiff_t index = (std::ptrdiff_t)std::abs( m_objIndexAccessor.get( m_curParticle.get() ) ) %
                                   (std::ptrdiff_t)m_srcData.size();

            m_currentSrc = m_srcData.begin() + index;
            m_currentParticleIt = m_currentSrc->particles->begin();
            m_currentParticleItEnd = m_currentSrc->particles->end();
        }
    }

  public:
    instancing_particle_istream( particle_istream_ptr delegatePin, const std::vector<particle_array_ptr>& srcParticles,
                                 bool useShapeIndex, bool modulateColor )
        : frantic::particles::streams::delegated_particle_istream( delegatePin )
        , m_particleIndex( -1 )
        , m_useShapeIndex( useShapeIndex )
        , m_modulateColor( modulateColor ) {
        m_srcData.resize( srcParticles.size() );
        m_currentSrc = m_srcData.end();

        m_compensateDensity = true;
        m_compensateSize = false;

        std::vector<source_data>::iterator itSrc = m_srcData.begin();
        for( std::vector<particle_array_ptr>::const_iterator it = srcParticles.begin(), itEnd = srcParticles.end();
             it != itEnd; ++it, ++itSrc ) {
            itSrc->particles = *it;
            itSrc->size = size3f( 1.f, 1.f, 1.f );
        }

        m_channelMap = m_delegate->get_channel_map();

        this->init_native_map();

        this->set_channel_map_impl( m_channelMap );

        m_destColor = color3f::white();
        m_destScale = vector3f( 1.f );
        m_densityFactor = 1.f;
    }

    void set_compensate_density( bool enabled = true ) { m_compensateDensity = enabled; }

    void set_compensate_size( bool enabled = true ) {
        m_compensateSize = enabled;

        if( m_compensateSize ) {
            // Calculate the bouding boxes of each source object so we can do the compensation.
            for( std::vector<source_data>::iterator it = m_srcData.begin(), itEnd = m_srcData.end(); it != itEnd;
                 ++it ) {
                channel_accessor<vector3f> posAccessor =
                    it->particles->get_channel_map().get_accessor<vector3f>( _T("Position") );

                if( it->particles->size() > 1 ) {
                    boundbox3f bounds;
                    for( particle_array_ptr::element_type::const_iterator itP = it->particles->begin(),
                                                                          itPEnd = it->particles->end();
                         itP != itPEnd; ++itP )
                        bounds += posAccessor.get( *itP );

                    // We want to store the radius so that a scale of 1.0 makes a sphere with radius R just overlap the
                    // center of another sphere that is R units away. NOTE: This assumes the source is centered about
                    // the local origin, we could re-center it too if we wanted.
                    it->size = 0.5f * bounds.size();
                } else {
                    it->size = frantic::graphics::size3f( 1.f, 1.f, 1.f );
                }
            }
        }
    }

    void set_wants_shapeindex( bool enabled = true ) {
        if( !enabled )
            m_objIndexAccessor.reset();
        else if( !m_objIndexAccessor.is_valid() ) {
            FF_LOG( warning ) << _T( "The \"ShapeIndex\" channel was not present in this node, 0 will be used instead" )
                              << std::endl;
            m_objIndexAccessor.reset( 0 );
        }
    }

    virtual ~instancing_particle_istream() { close(); }

    virtual void close() {}

    virtual frantic::tstring name() const { return _T("scattering particle istream"); }

    virtual std::size_t particle_size() const { return m_channelMap.structure_size(); }

    virtual boost::int64_t particle_count() const { return -1; }

    virtual boost::int64_t particle_index() const { return m_particleIndex; }

    virtual boost::int64_t particle_count_left() const { return -1; }

    virtual void set_channel_map( const frantic::channels::channel_map& newMap ) {
        boost::scoped_array<char> newDefault( new char[newMap.structure_size()] );

        newMap.construct_structure( newDefault.get() );

        if( m_defaultParticle ) {
            frantic::channels::channel_map_adaptor tempAdaptor( newMap, m_channelMap );

            tempAdaptor.copy_structure( newDefault.get(), m_defaultParticle.get() );
        }

        m_defaultParticle.swap( newDefault );

        set_channel_map_impl( newMap );
    }

    virtual const frantic::channels::channel_map& get_channel_map() const { return m_channelMap; }

    virtual const frantic::channels::channel_map& get_native_channel_map() const { return m_nativeMap; }

    virtual void set_default_particle( char* rawParticleBuffer ) {
        m_defaultParticle.reset( new char[m_channelMap.structure_size()] );
        m_channelMap.copy_structure( m_defaultParticle.get(), rawParticleBuffer );
    }

    virtual bool get_particle( char* rawParticleBuffer ) {
        if( m_currentParticleIt == m_currentParticleItEnd ) {
            if( !m_delegate->get_particle( m_curParticle.get() ) )
                return false;

            /*if( !m_objIndexAccessor.is_valid() ){
                    if( m_currentSrc == m_srcData.end() || ++m_currentSrc == m_srcData.end() )
                            m_currentSrc = m_srcData.begin();
                    m_currentParticleIt = m_currentSrc->particles->begin();
                    m_currentParticleItEnd = m_currentSrc->particles->end();
            }else{
                    std::ptrdiff_t index = (std::ptrdiff_t)std::abs( m_objIndexAccessor.get( m_curParticle.get() ) ) %
            (std::ptrdiff_t)m_srcData.size();

                    m_currentSrc = m_srcData.begin() + index;
                    m_currentParticleIt = m_currentSrc->particles->begin();
                    m_currentParticleItEnd = m_currentSrc->particles->end();
            }*/
            this->prepare_next_source();

            // If there were NO particles in this source we're left in a sticky situation. We pass through the particle
            // unchanged.
            if( m_currentParticleIt == m_currentParticleItEnd ) {
                m_adaptor.copy_structure( rawParticleBuffer, m_curParticle.get(), m_defaultParticle.get() );
                m_delegateAdaptor.copy_structure( rawParticleBuffer, m_curParticle.get() );

                ++m_particleIndex;

                return true;
            }

            m_destXForm.set_to_identity();

            m_destPos = m_posAccessor.get( m_curParticle.get() );
            m_destVelocity = m_velAccessor.get( m_curParticle.get() );
            m_destColor = m_colorAccessor.get( m_curParticle.get() );

            m_densityFactor = m_densityAccessor.get( m_curParticle.get() );

            if( m_compensateDensity )
                m_densityFactor /= (float)m_currentSrc->particles->size();

            if( m_orientationAccessor.is_valid() ) {
                m_destOrientation = m_orientationAccessor.get( m_curParticle.get() );
                m_destOrientation.as_transform4f( m_destXForm );
            }

            if( m_scale3Accessor.is_valid() )
                m_destScale = m_scale3Accessor.get( m_curParticle.get() );
            else if( m_scaleAccessor.is_valid() )
                m_destScale = vector3f( m_scaleAccessor.get( m_curParticle.get() ) );

            // Divide out the size of the source object, so that the scale value is normalized for the source's size.
            if( m_compensateSize ) {
                m_destScale.x /= m_currentSrc->size.xsize();
                m_destScale.y /= m_currentSrc->size.ysize();
                m_destScale.z /= m_currentSrc->size.zsize();
            }

            // Build the transformation to apply to particles.
            m_destOrientation.as_transform4f( m_destXForm );
            m_destXForm = m_destXForm * transform4f::from_scale( m_destScale );
            m_destXForm.set_translation( m_destPos );

            // This is potentially expensive, so I only do it if I am actually going to use the result.
            if( m_destNormalAccessor.is_valid() ) {
                try {
                    m_destXFormInv = m_destXForm.to_inverse(); // This is complete bullshit!
                } catch( ... ) {
                    m_destXFormInv = transform4f::zero();
                }
            }
        }

        // Copy all channels from the clone particle
        m_currentSrc->adaptor.copy_structure( rawParticleBuffer, *m_currentParticleIt, m_defaultParticle.get() );

        // Copy any channels requested to pass through from the delegate.
        m_delegateAdaptor.copy_structure( rawParticleBuffer, m_curParticle.get() );

        m_destPosAccessor.get( rawParticleBuffer ) = m_destXForm * m_destPosAccessor.get( rawParticleBuffer );

        // Add the velocity from the delegate stream to the (possibly scaled and rotated) velocity from the current
        // source's particle.
        if( m_destVelAccessor.is_valid() )
            m_destVelAccessor.set(
                rawParticleBuffer,
                m_destVelocity + m_destXForm.transform_no_translation( m_destVelAccessor.get( rawParticleBuffer ) ) );

        // Rotate the normal by the delegate stream's orientation.
        if( m_destNormalAccessor.is_valid() )
            m_destNormalAccessor.set( rawParticleBuffer, m_destXFormInv.transpose_transform_no_translation(
                                                             m_destNormalAccessor.get( rawParticleBuffer ) ) );

        // We might want to modulate the source particle's color by the delegate stream's particle color.
        if( always_retain_color() ) {
            if( m_destColorAccessor.is_valid() ) {
                m_destColorAccessor.set( rawParticleBuffer, m_destColor );
            }
        } else if( m_modulateColor ) {
            if( m_destColorAccessor.is_valid() )
                m_destColorAccessor.set( rawParticleBuffer,
                                         m_destColor * m_destColorAccessor.get( rawParticleBuffer ) );
        }

        // TODO: Add/Modulate Emission values, and Absorption values too! Maybe generalize this?

        // Apply the delegate stream's orientation to current source particle's orientation.
        if( m_destOrientationAccessor.is_valid() )
            m_destOrientationAccessor.set( rawParticleBuffer,
                                           m_destOrientation * m_destOrientationAccessor.get( rawParticleBuffer ) );

        if( m_destDensityAccessor.is_valid() )
            m_destDensityAccessor.set( rawParticleBuffer,
                                       m_densityFactor * m_destDensityAccessor.get( rawParticleBuffer ) );

        ++m_currentParticleIt;
        ++m_particleIndex;

        return true;
    }

    virtual bool get_particles( char* rawParticleBuffer, std::size_t& numParticles ) {
        for( std::size_t i = 0; i < numParticles; ++i, rawParticleBuffer += m_channelMap.structure_size() ) {
            if( !get_particle( rawParticleBuffer ) ) {
                numParticles = i;
                return false;
            }
        }

        return true;
    }
};

class randomizing_particle_istream : public instancing_particle_istream {
    frantic::channels::channel_const_cvt_accessor<int> m_numParticlesChannel;
    int m_numParticlesDefault;
    bool m_forceNumParticlesDefault;

    float m_radius;
    float m_falloff;

    boost::mt19937 m_rndEng;
    // boost::variate_generator< boost::mt19937&, boost::uniform_01<float> > m_rndGen;

  protected:
    struct particle_t {
        vector3f p;
        float d;
    };

    inline virtual bool always_retain_color() { return true; }

    inline void get_random_point_in_sphere( particle_t& outParticle ) {
        boost::variate_generator<boost::mt19937&, boost::uniform_real<float>> rnd(
            m_rndEng, boost::uniform_real<float>( -1.f, 1.f ) );

        vector3f result;
        float magnitude;

        // Generate a random point in a [-1,-1,-1] to [1,1,1] box, discarding those outside the sphere. I expect this to
        // take on average 2 tries before a point is accepted.
        do {
            result.x = rnd();
            result.y = rnd();
            result.z = rnd();

            magnitude = result.get_magnitude_squared();
        } while( magnitude >= 1.f );

        outParticle.p = m_radius * result;
        outParticle.d = std::pow( 1.f - std::sqrt( magnitude ), m_falloff );
    }

    virtual void prepare_next_source() {
        // Fill in the random particles.
        int numParticles = m_numParticlesChannel.get( m_curParticle.get() );
        if( numParticles < 0 )
            numParticles = 0;

        frantic::particles::particle_array& particles = *m_srcData.front().particles;

        particles.clear();
        particles.reserve( static_cast<std::size_t>( numParticles ) );

        // char* buffer = (char*)alloca( particles.get_channel_map().structure_size() );
        particle_t tempParticle;

        for( int i = 0; i < numParticles; ++i ) {
            this->get_random_point_in_sphere( tempParticle );

            particles.push_back( reinterpret_cast<char*>( &tempParticle ) );
        }

        // Update the iterators so the parent class implementation can see them.
        m_currentSrc = m_srcData.begin();
        m_currentParticleIt = m_currentSrc->particles->begin();
        m_currentParticleItEnd = m_currentSrc->particles->end();
    }

    inline static std::vector<particle_array_ptr> create_initial_particles() {
        frantic::channels::channel_map genMap;
        genMap.define_channel( _T("Position"), 3, frantic::channels::data_type_float32, offsetof( particle_t, p ) );
        genMap.define_channel( _T("Density"), 1, frantic::channels::data_type_float32, offsetof( particle_t, d ) );
        genMap.end_channel_definition();

        std::vector<particle_array_ptr> result;
        result.push_back( particle_array_ptr( new frantic::particles::particle_array( genMap ) ) );

        return result;
    }

  public:
    randomizing_particle_istream( particle_istream_ptr delegatePin, boost::uint32_t seed, bool modulateColor )
        : instancing_particle_istream( delegatePin, create_initial_particles(), false, modulateColor )
        , m_rndEng( seed ) {
        m_numParticlesChannel.reset( 1 );
        m_numParticlesDefault = 1;
        m_forceNumParticlesDefault = false;

        m_radius = 1.f;
    }

    void set_default_count( int count ) {
        m_numParticlesDefault = count;
        if( m_numParticlesChannel.is_default() )
            m_numParticlesChannel.reset( m_numParticlesDefault );
    }

    void enable_count_channel( bool enabled = true ) {
        m_forceNumParticlesDefault = !enabled;

        if( enabled )
            m_numParticlesChannel = m_delegate->get_channel_map().get_const_cvt_accessor<int>( _T("Count") );
        else
            m_numParticlesChannel.reset( m_numParticlesDefault );
    }

    void set_radius( float radius ) {
        m_radius = radius;
        m_srcData.front().size = size3f( 2.f * m_radius, 2.f * m_radius, 2.f * m_radius );
    }

    void set_falloff( float falloff ) { m_falloff = std::max( 0.f, falloff ); }

    virtual boost::int64_t particle_count_guess() const {
        boost::int64_t delegateGuess = m_delegate->particle_count_guess();
        if( delegateGuess < 0 )
            return -1;

        // NOTE: If we are using a count per-particle, then we can't really know but we need to guess something anyways.

        // if( m_numParticlesChannel.is_valid() && !m_numParticlesChannel.is_default() )
        //	return delegateGuess;

        return delegateGuess * m_numParticlesDefault;
    }
};

class caching_particle_istream : public frantic::particles::streams::particle_container_particle_istream<
                                     frantic::particles::particle_array::iterator> {
    boost::shared_ptr<frantic::particles::particle_array> m_particles;

  public:
    caching_particle_istream( boost::shared_ptr<frantic::particles::particle_array> particles )
        : particle_container_particle_istream( particles->begin(), particles->end(), particles->get_channel_map() )
        , m_particles( particles ) {}

    virtual ~caching_particle_istream() {}
};

struct particle_standin {
    vector3f pos;
    std::size_t id;

    particle_standin()
        : id( std::numeric_limits<std::size_t>::max() ) {}

    particle_standin( const vector3f& _pos, std::size_t _id )
        : pos( _pos )
        , id( _id ) {}

    float operator[]( int index ) const { return pos[index]; }

    operator const vector3f&() const { return pos; }
};

struct id_not_equals {
    std::size_t val;

    id_not_equals( std::size_t _val )
        : val( _val ) {}

    inline bool operator()( const particle_standin& rhs ) const { return rhs.id != val; }
};

particle_istream_ptr apply_scale_by_neighbor_distance_stream( particle_istream_ptr delegateStream,
                                                              float scaleFactor = 1.f ) {
    frantic::channels::channel_map delegateMap;

    instancing_particle_istream::get_delegate_channel_map( delegateMap, delegateStream->get_native_channel_map() );

    // if( !delegateMap.has_channel( "Scale" ) )
    //	delegateMap.define_channel<float>( "Scale" );

    // The delegate stream is prone to having a scale float32[3] that we don't actually want. We are going to write to
    // __ScaleScalar and then rename it.
    delegateMap.define_channel<float>( _T("__ScaleScalar") );

    delegateMap.end_channel_definition();

    // Delete the scale channel so the delegate doesn't fill it in. Its actually ok to keep it if its a float32[1] but
    // bad if its a float32[3].
    if( delegateMap.has_channel( _T("Scale") ) )
        delegateMap.delete_channel( _T("Scale") );

    boost::shared_ptr<frantic::particles::particle_array> particles(
        new frantic::particles::particle_array( delegateMap ) );

    particles->insert_particles( delegateStream );

    frantic::channels::channel_accessor<vector3f> posAccessor =
        particles->get_channel_map().get_accessor<vector3f>( _T("Position") );
    frantic::channels::channel_cvt_accessor<float> scaleAccessor =
        particles->get_channel_map().get_cvt_accessor<float>( _T("__ScaleScalar") );

    if( particles->size() > 1 ) {
        // We use a particle_kdtree to find the closest neighbor in the stream. This could likely be done cheaper, since
        // the kdtree is being constructed but only used once.
        frantic::particles::particle_kdtree<particle_standin> kdtree;

        std::size_t counter = 0;
        for( frantic::particles::particle_array::const_iterator it = particles->begin(), itEnd = particles->end();
             it != itEnd; ++it, ++counter )
            kdtree.add_particle( particle_standin( posAccessor.get( *it ), counter ) );

        kdtree.balance_kdtree();

        counter = 0;
        for( frantic::particles::particle_array::iterator it = particles->begin(), itEnd = particles->end();
             it != itEnd; ++it, ++counter ) {
            const particle_standin& p =
                kdtree.locate_closest_particle_if( posAccessor.get( *it ), id_not_equals( counter ) );

            scaleAccessor.set( *it, scaleFactor * vector3f::distance( p.pos, posAccessor.get( *it ) ) );
        }
    } else {
        // This catches the 0 and 1 particle cases
        for( frantic::particles::particle_array::iterator it = particles->begin(), itEnd = particles->end();
             it != itEnd; ++it )
            scaleAccessor.set( *it, scaleFactor );
    }

    // This is ugly, but I'm tired of looking at this problem.
    const_cast<frantic::channels::channel_map&>( particles->get_channel_map() )
        .rename_channel( _T("__ScaleScalar"), _T("Scale") );

    return particle_istream_ptr( new caching_particle_istream( particles ) );
}

} // namespace
