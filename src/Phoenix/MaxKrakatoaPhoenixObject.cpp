// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0
#include "stdafx.h"

#if defined( PHOENIX_SDK_AVAILABLE )
#include <Phoenix/MaxKrakatoaPhoenixObject.hpp>

#include "resource.h"

#include <Phoenix/MaxKrakatoaPhoenixDialogProcs.hpp>
#include <Phoenix/MaxKrakatoaPhoenixParticleIstream.hpp>
#include <Phoenix/ParamIDs.hpp>

#include <krakatoa/particle_volume.hpp>

#include <frantic/max3d/node_transform.hpp>
#include <frantic/max3d/paramblock_builder.hpp>
#include <frantic/particles/streams/concatenated_particle_istream.hpp>
#include <frantic/particles/streams/empty_particle_istream.hpp>
#include <frantic/particles/streams/fractional_particle_istream.hpp>
#include <frantic/particles/streams/transformed_particle_istream.hpp>

#include <phoenixfd/aurinterface.h>
#include <phoenixfd/phxcontent.h>

using namespace krakatoa::phoenix::param;
using namespace frantic::particles::streams;

extern Mesh* GetPRTPhoenixIconMesh();
#if MAX_VERSION_MAJOR >= 25
extern MaxSDK::SharedMeshPtr GetPRTPhoenixIconMeshShared();
#endif

namespace {
const char* const g_phoenixGroupNameLiquid = "Liquid";
const char* const g_phoenixGroupNameSplashes = "Splashes";
const char* const g_phoenixGroupNameFoam = "Foam";
const char* const g_phoenixGroupNameMist = "Mist";
const char* const g_phoenixGroupNameWetMap = "WetMap";
} // namespace

void MaxKrakatoaPhoenixObject::GetDeformBBox( TimeValue t, Box3& box, Matrix3* tm, BOOL useSel ) {
    INode* pNode = m_pblock->GetINode( kTargetNode );
    if( pNode ) {
        ViewExp* viewExp =
#if MAX_VERSION_MAJOR >= 15
            &GetCOREInterface()->GetActiveViewExp();
#else
            GetCOREInterface()->GetActiveViewport();
#endif
        pNode->GetObjectRef()->FindBaseObject()->GetLocalBoundBox( t, pNode, viewExp, box );
        if( tm )
            box = box * ( *tm );
    } else {
        box.Init();
        box.pmin.x = -10.f;
        box.pmax.x = 10.f;
        box.pmin.y = -10.f;
        box.pmax.y = 10.f;
        box.pmin.z = 0.f;
        box.pmax.z = 20.f;
    }
}

void MaxKrakatoaPhoenixObject::SetIconSize( float size ) { m_pblock->SetValue( kIconSize, 0, size ); }

particle_istream_ptr MaxKrakatoaPhoenixObject::GetInternalStream( INode* /*pNode*/, TimeValue t, Interval& outValidity,
                                                                  boost::shared_ptr<IEvalContext> pEvalContext ) {
    auto pin = GetRenderStream( t, outValidity, pEvalContext->GetDefaultChannels() );
    if( m_inRenderMode ) {
        return pin;
    } else {
        auto loadFraction = 1.f;
        if( m_pblock->GetInt( kViewportUsePercentage ) ) {
            // Do not divide by 100. The parameter was declared to be a percentage in the pblock.
            loadFraction = m_pblock->GetFloat( kViewportPercentage );
        }
        auto loadLimit = std::numeric_limits<boost::int64_t>::max();
        if( m_pblock->GetInt( kViewportUseLimit ) )
            loadLimit = boost::int64_t( 1000.0 * m_pblock->GetFloat( kViewportLimit ) );

        return apply_fractional_particle_istream( pin, loadFraction, loadLimit );
    }
}

particle_istream_ptr
MaxKrakatoaPhoenixObject::GetRenderStream( TimeValue t, Interval& outValidity,
                                           const frantic::channels::channel_map& requestedChannels ) {

    INode* pPhoenixNode = m_pblock->GetINode( kTargetNode );

    if( !pPhoenixNode || ( !m_inRenderMode && !m_pblock->GetInt( kViewportEnabled ) ) )
        return boost::make_shared<empty_particle_istream>( requestedChannels );

    outValidity.SetInstant( t );

    ObjectState os = pPhoenixNode->EvalWorldState( t );

    if( IPhoenixFD* phoenix = (IPhoenixFD*)( os.obj ? os.obj->GetInterface( PHOENIXFD_INTERFACE ) : nullptr ) ) {
        if( IAur* aur = phoenix->GetSimData( pPhoenixNode ) ) {
            std::vector<particle_istream_ptr> pins;

            // Liquid simulations
            if( m_pblock->GetInt( kShowLiquid ) )
                AppendGroup( pins, g_phoenixGroupNameLiquid, t, outValidity, requestedChannels, aur, pPhoenixNode );
            if( m_pblock->GetInt( kShowSplashes ) )
                AppendGroup( pins, g_phoenixGroupNameSplashes, t, outValidity, requestedChannels, aur, pPhoenixNode );
            if( m_pblock->GetInt( kShowFoam ) )
                AppendGroup( pins, g_phoenixGroupNameFoam, t, outValidity, requestedChannels, aur, pPhoenixNode );
            if( m_pblock->GetInt( kShowMist ) )
                AppendGroup( pins, g_phoenixGroupNameMist, t, outValidity, requestedChannels, aur, pPhoenixNode );
            if( m_pblock->GetInt( kShowWetMap ) )
                AppendGroup( pins, g_phoenixGroupNameWetMap, t, outValidity, requestedChannels, aur, pPhoenixNode );

            // Volume simulations
            if( m_pblock->GetInt( kSeedInSmoke ) || m_pblock->GetInt( kSeedInTemperature ) ) {
                const unsigned subdivCount =
                    ( m_pblock->GetInt( kSubdivideEnabled ) ? m_pblock->GetInt( kSubdivideCount ) : 0 );
                const auto doJitter = static_cast<bool>( m_pblock->GetInt( kJitterEnabled ) );
                const auto numPerVoxel =
                    ( m_pblock->GetInt( kMultiplePerRegionEnabled ) ? m_pblock->GetInt( kMultiplePerRegionCount ) : 1 );
                const unsigned randomSeed = m_pblock->GetInt( kRandomSeed );
                const std::size_t randomCount = m_pblock->GetInt( kRandomCount );
                const auto jitterWellDistributed = static_cast<bool>( m_pblock->GetInt( kJitterWellDistributed ) );
                auto sampler = krakatoa::get_particle_volume_voxel_sampler(
                    subdivCount, doJitter, numPerVoxel, randomSeed, randomCount, jitterWellDistributed );

                const auto minimumSmoke = ( m_pblock->GetInt( kSeedInSmoke ) ? m_pblock->GetFloat( kSeedInSmokeMinimum )
                                                                             : std::numeric_limits<float>::max() );
                const auto minimumTemperature =
                    ( m_pblock->GetInt( kSeedInTemperature ) ? m_pblock->GetFloat( kSeedInTemperatureMinimum )
                                                             : std::numeric_limits<float>::max() );
                pins.push_back( GetPhoenixParticleIstreamFromVolume( pPhoenixNode, t, requestedChannels, sampler,
                                                                     minimumSmoke, minimumTemperature ) );
            }

            return ( pins.empty() ? boost::make_shared<empty_particle_istream>( requestedChannels )
                                  : static_cast<particle_istream_ptr>(
                                        boost::make_shared<concatenated_particle_istream>( pins ) ) );
        }
    }
    return boost::make_shared<empty_particle_istream>( requestedChannels );
}

RefResult MaxKrakatoaPhoenixObject::NotifyRefChanged( const Interval& changeInt, RefTargetHandle hTarget,
                                                      PartID& partID, RefMessage message, BOOL propagate ) {
    if( hTarget == m_pblock ) {
        int param = m_pblock->LastNotifyParamID();

        if( message == REFMSG_CHANGE ) {
            switch( param ) {
            case kTargetNode:
                if( !( partID & PART_GEOM ) )
                    return REF_STOP;
                break;
            case kRandomSeed:
            case kRandomCount:
                if( !m_pblock->GetInt( kJitterEnabled ) )
                    return REF_STOP;
                break;
            case kSubdivideCount:
                if( !m_pblock->GetInt( kSubdivideEnabled ) ||
                    ( !m_inRenderMode && m_pblock->GetInt( kViewportDisableSubdivision ) ) )
                    return REF_STOP;
                break;
            case kJitterWellDistributed:
            case kMultiplePerRegionEnabled:
                if( !m_pblock->GetInt( kJitterEnabled ) )
                    return REF_STOP;
                break;
            case kMultiplePerRegionCount:
                if( !m_pblock->GetInt( kMultiplePerRegionEnabled ) || !m_pblock->GetInt( kJitterEnabled ) ||
                    ( !m_inRenderMode && m_pblock->GetInt( kViewportDisableSubdivision ) ) )
                    return REF_STOP;
                break;
            case kSeedInSmokeMinimum:
                if( !m_pblock->GetInt( kSeedInSmoke ) )
                    return REF_STOP;
                break;
            case kSeedInTemperatureMinimum:
                if( !m_pblock->GetInt( kSeedInTemperature ) )
                    return REF_STOP;
                break;
            case kViewportDisableSubdivision:
                if( !m_pblock->GetInt( kSubdivideEnabled ) && !m_pblock->GetInt( kMultiplePerRegionEnabled ) &&
                    !m_pblock->GetInt( kJitterEnabled ) )
                    return REF_STOP;
                break;
            case kIconSize:
                return REF_SUCCEED; // Skip invalidating any cache since its just the icon size changing
            default:
                break;
            }
            InvalidateViewport();
        }
    }

    return REF_SUCCEED;
};

Interval MaxKrakatoaPhoenixObject::ObjectValidity( TimeValue t ) {
    INode* pNode = m_pblock->GetINode( kTargetNode );
    if( pNode )
        return pNode->GetObjectRef()->FindBaseObject()->ObjectValidity( t );
    else
        return FOREVER;
};

inline void MaxKrakatoaPhoenixObject::AppendGroup( std::vector<particle_istream_ptr>& pins, const char* name,
                                                   TimeValue transformedTime, Interval validity,
                                                   const frantic::channels::channel_map& requestedChannels, IAur* aur,
                                                   INode* pPhoenixNode ) {
    if( IPhoenixFDPrtGroup* pGroup = aur->GetParticleGroupByName( name ) ) {
        auto pin = GetPhoenixParticleIstream( pPhoenixNode, pGroup, transformedTime, requestedChannels );
        if( !pin )
            return;
        pins.push_back( pin );
    }
}

class MaxKrakatoaPhoenixObjectDesc : public ClassDesc2 {

    frantic::max3d::ParamBlockBuilder m_paramDesc;

  public:
    MaxKrakatoaPhoenixObjectDesc();

    virtual ~MaxKrakatoaPhoenixObjectDesc() {}

    int IsPublic() { return TRUE; }

    void* Create( BOOL /*loading*/ ) { return new MaxKrakatoaPhoenixObject; }

    const TCHAR* ClassName() { return MaxKrakatoaPhoenixObject_NAME; }
#if MAX_VERSION_MAJOR >= 24
    const TCHAR* NonLocalizedClassName() { return MaxKrakatoaPhoenixObject_NAME; }
#endif

    SClass_ID SuperClassID() { return GEOMOBJECT_CLASS_ID; }

    Class_ID ClassID() { return MaxKrakatoaPhoenixObject_CLASS_ID; }

    /**
     * The drop down list category when adding new objects to the scene.
     */
    const TCHAR* Category() { return _T("Krakatoa"); }

    /**
     * Return fixed parsable name (scripter-visible name).
     */
    const TCHAR* InternalName() { return MaxKrakatoaPhoenixObject_NAME; }

    /**
     * Return owning module handle.
     */
    HINSTANCE HInstance() { return hInstance; }
};

enum {

    kSourceRollout,
    kSeedingRollout,
    kViewportRollout

};

MaxKrakatoaPhoenixObjectDesc::MaxKrakatoaPhoenixObjectDesc()
    : m_paramDesc( 0, _T("Parameters"), NULL, MaxKrakatoaPhoenixObject_VERSION ) {

    m_paramDesc.OwnerClassDesc( this );
    m_paramDesc.OwnerRefNum( 0 );

    m_paramDesc.RolloutTemplate( kSourceRollout, IDD_PHOENIX_SOURCE, IDS_PRTVOXEL_SOURCE,
                                 PhoenixMainPanelDialogProc::GetInstance() );
    m_paramDesc.RolloutTemplate( kSeedingRollout, IDD_PHOENIX_SEEDING, IDS_PRTVOXEL_SEEDING, nullptr );
    m_paramDesc.RolloutTemplate( kViewportRollout, IDD_PHOENIX_VIEWPORT, IDS_PRTVOXEL_VIEWPORT,
                                 PhoenixViewportPanelDialogProc::GetInstance() );

    // Source

    m_paramDesc.Parameter<INode*>( kTargetNode, _T("TargetNode") )
        .PickNodeButtonUI( kSourceRollout, IDC_PHOENIX_TARGETNODE, NULL );

    m_paramDesc.Parameter<bool>( kShowLiquid, _T("ShowLiquid") )
        .DefaultValue( false )
        .CheckBoxUI( kSourceRollout, IDC_PHOENIX_LIQUID_CHECK );
    m_paramDesc.Parameter<bool>( kShowSplashes, _T("ShowSplashes") )
        .DefaultValue( false )
        .CheckBoxUI( kSourceRollout, IDC_PHOENIX_SPLASHES_CHECK );
    m_paramDesc.Parameter<bool>( kShowMist, _T("ShowMist") )
        .DefaultValue( false )
        .CheckBoxUI( kSourceRollout, IDC_PHOENIX_MIST_CHECK );
    m_paramDesc.Parameter<bool>( kShowFoam, _T("ShowFoam") )
        .DefaultValue( false )
        .CheckBoxUI( kSourceRollout, IDC_PHOENIX_FOAM_CHECK );
    m_paramDesc.Parameter<bool>( kShowWetMap, _T("ShowWetMap") )
        .DefaultValue( false )
        .CheckBoxUI( kSourceRollout, IDC_PHOENIX_WETMAP_CHECK );

    m_paramDesc.Parameter<bool>( kSeedInSmoke, _T("SeedInSmoke") )
        .DefaultValue( false )
        .CheckBoxUI( kSourceRollout, IDC_PHOENIX_SEEDINSMOKE_CHECK );

    m_paramDesc.Parameter<float>( kSeedInSmokeMinimum, _T("SeedInSmokeMinimum") )
        .DefaultValue( 0.01f )
        .Range( 0.f, FLT_MAX )
        .SpinnerUI( kSourceRollout, EDITTYPE_POS_FLOAT, IDC_PHOENIX_SEEDINSMOKE_EDIT, IDC_PHOENIX_SEEDINSMOKE_SPIN,
                    true );

    m_paramDesc.Parameter<bool>( kSeedInTemperature, _T("SeedInTemperature") )
        .DefaultValue( false )
        .CheckBoxUI( kSourceRollout, IDC_PHOENIX_SEEDINTEMPERATURE_CHECK );

    // While Phoenix FD does have a fuel channel, most simulations represent fire as air above a certain temperature.
    // This value is in Kelvins.
    m_paramDesc.Parameter<float>( kSeedInTemperatureMinimum, _T("SeedInTemperatureMinimum") )
        .DefaultValue( 1273.f ) // roughly 1,000 deg C
        .Range( 0.f, FLT_MAX )
        .SpinnerUI( kSourceRollout, EDITTYPE_POS_FLOAT, IDC_PHOENIX_SEEDINTEMPERATURE_EDIT,
                    IDC_PHOENIX_SEEDINTEMPERATURE_SPIN, true );

    // Seeding

    m_paramDesc.Parameter<bool>( kSubdivideEnabled, _T("SubdivideEnabled") )
        .DefaultValue( false )
        .CheckBoxUI( kSeedingRollout, IDC_PHOENIX_SUBDIVISIONS_CHECK );

    m_paramDesc.Parameter<int>( kSubdivideCount, _T("SubdivideCount") )
        .DefaultValue( 1 )
        .Range( 1, INT_MAX )
        .SpinnerUI( kSeedingRollout, EDITTYPE_POS_INT, IDC_PHOENIX_SUBDIVISIONS_EDIT, IDC_PHOENIX_SUBDIVISIONS_SPIN,
                    true );

    m_paramDesc.Parameter<bool>( kJitterEnabled, _T("JitterEnabled") )
        .DefaultValue( true )
        .CheckBoxUI( kSeedingRollout, IDC_PHOENIX_JITTER_CHECK );

    m_paramDesc.Parameter<bool>( kJitterWellDistributed, _T("JitterWellDistributed") )
        .DefaultValue( false )
        .CheckBoxUI( kSeedingRollout, IDC_PHOENIX_JITTER_WELLDISTRIBUTED_CHECK );

    m_paramDesc.Parameter<bool>( kMultiplePerRegionEnabled, _T("MultiplePerRegionEnabled") )
        .DefaultValue( false )
        .CheckBoxUI( kSeedingRollout, IDC_PHOENIX_JITTER_MULTIPLE_CHECK );

    m_paramDesc.Parameter<int>( kMultiplePerRegionCount, _T("MultiplePerRegionCount") )
        .DefaultValue( 2 )
        .Range( 2, INT_MAX )
        .SpinnerUI( kSeedingRollout, EDITTYPE_POS_INT, IDC_PHOENIX_JITTER_MULTIPLE_EDIT,
                    IDC_PHOENIX_JITTER_MULTIPLE_SPIN, true );

    m_paramDesc.Parameter<int>( kRandomCount, _T("RandomCount") )
        .DefaultValue( 1024 )
        .Range( 1, INT_MAX )
        .SpinnerUI( kSeedingRollout, EDITTYPE_POS_INT, IDC_PHOENIX_RANDOMCOUNT_EDIT, IDC_PHOENIX_RANDOMCOUNT_SPIN,
                    true );

    m_paramDesc.Parameter<int>( kRandomSeed, _T("RandomSeed") )
        .DefaultValue( 42 )
        .Range( 0, INT_MAX )
        .EnableAnimation( true, IDS_PRTCLONER_RANDOMSEED )
        .SpinnerUI( kSeedingRollout, EDITTYPE_POS_INT, IDC_PHOENIX_RANDOMSEED_EDIT, IDC_PHOENIX_RANDOMSEED_SPIN );

    // Viewport

    m_paramDesc.Parameter<float>( kIconSize, _T("IconSize") )
        .DefaultValue( 30.f )
        .Range( 0.f, FLT_MAX )
        .SpinnerUI( kViewportRollout, EDITTYPE_POS_FLOAT, IDC_PHOENIX_ICONSIZE_EDIT, IDC_PHOENIX_ICONSIZE_SPIN );

    m_paramDesc.Parameter<bool>( kViewportEnabled, _T("ViewportEnabled") )
        .DefaultValue( true )
        .CheckBoxUI( kViewportRollout, IDC_PHOENIX_VIEWPORTENABLED );

    m_paramDesc.Parameter<bool>( kViewportUsePercentage, _T("ViewportUsePercentage") )
        .DefaultValue( false )
        .CheckBoxUI( kViewportRollout, IDC_PHOENIX_LOADPERCENTAGE_CHECK );

    m_paramDesc.Parameter<float>( kViewportPercentage, _T("ViewportPercentage") )
        .DefaultValue( .1f )
        .Units( frantic::max3d::parameter_units::percentage )
        .SpinnerUI( kViewportRollout, EDITTYPE_POS_FLOAT, IDC_PHOENIX_LOADPERCENTAGE_EDIT,
                    IDC_PHOENIX_LOADPERCENTAGE_SPIN );

    m_paramDesc.Parameter<bool>( kViewportUseLimit, _T("ViewportUseLimit") )
        .DefaultValue( false )
        .CheckBoxUI( kViewportRollout, IDC_PHOENIX_LOADLIMIT_CHECK );

    m_paramDesc.Parameter<float>( kViewportLimit, _T("ViewportLimit") )
        .DefaultValue( 1000.f )
        .Range( 0.f, FLT_MAX )
        .SpinnerUI( kViewportRollout, EDITTYPE_POS_FLOAT, IDC_PHOENIX_LOADLIMIT_EDIT, IDC_PHOENIX_LOADLIMIT_SPIN );
}

// This is a separate free function because of DllEntry.cpp.
ClassDesc2* GetMaxKrakatoaPhoenixObjectDesc() {
    static MaxKrakatoaPhoenixObjectDesc theDesc;
    return &theDesc;
}

ClassDesc2* MaxKrakatoaPhoenixObject::GetClassDesc() { return GetMaxKrakatoaPhoenixObjectDesc(); }

MaxKrakatoaPhoenixObject::MaxKrakatoaPhoenixObject() { GetMaxKrakatoaPhoenixObjectDesc()->MakeAutoParamBlocks( this ); }

Mesh* MaxKrakatoaPhoenixObject::GetIconMesh( Matrix3& outTM ) {
    const float iconSize = m_pblock->GetFloat( kIconSize );
    outTM.SetScale( Point3( iconSize, iconSize, iconSize ) );
    return GetPRTPhoenixIconMesh();
}

#if MAX_VERSION_MAJOR >= 25
MaxSDK::SharedMeshPtr MaxKrakatoaPhoenixObject::GetIconMeshShared( Matrix3& outTM ) {
    float size = m_pblock->GetFloat( kIconSize );
    outTM.SetScale( Point3( size, size, size ) );
    return GetPRTPhoenixIconMeshShared();
}
#endif

#endif
