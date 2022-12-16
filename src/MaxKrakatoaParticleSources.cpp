// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0
#include "stdafx.h"

#include "MaxKrakatoa.h"
#include "MaxKrakatoaMaterial.hpp"
#include "MaxKrakatoaParticleSources.h"
#include "Objects/MaxKrakatoaPRTInterface.h"
#include "Objects/MaxKrakatoaPRTLoader.h"
#include "Objects/MaxKrakatoaVolumeObject.h"
#include "PFlow Operators\MaxKrakatoaPFOptions.h"
#include "Phoenix/MaxKrakatoaPhoenixObject.hpp"
#include "Phoenix/MaxKrakatoaPhoenixParticleIstream.hpp"

#include <frantic/particles/streams/apply_function_particle_istream.hpp>
#include <frantic/particles/streams/fractional_particle_istream.hpp>

#include <frantic/max3d/geometry/null_view.hpp>
#include <frantic/max3d/node_transform.hpp>
#include <frantic/max3d/particles/max3d_particle_utils.hpp>

#include <frantic/max3d/particles/streams/max_geometry_vert_particle_istream.hpp>
#include <frantic/max3d/particles/streams/max_legacy_particle_istream.hpp>
#include <frantic/max3d/particles/streams/max_pflow_particle_istream.hpp>

#include <frantic/max3d/geometry/auto_mesh.hpp>
#include <frantic/max3d/parameter_extraction.hpp>

#pragma warning( push, 3 )
#include <ParticleFlow/IPFRender.h>
#pragma warning( pop )

using namespace std;
using namespace frantic::particles;
using namespace frantic::particles::streams;
using namespace frantic::max3d;
using namespace frantic::max3d::particles;

namespace krakatoa {
namespace max3d {

boost::shared_ptr<frantic::particles::streams::particle_istream>
ApplyStdMaterial( boost::shared_ptr<frantic::particles::streams::particle_istream> pin, Mtl* pMtl,
                  const frantic::max3d::shaders::renderInformation& renderInfo, bool doShadeColor,
                  bool doShadeAbsorption, bool doShadeEmission, bool doShadeDensity, TimeValue t );

}
} // namespace krakatoa

namespace {
/**
 * Operations applied to particle istreams using the apply_function_particle_istream class
 */
struct ops {
    static float scale_density_by_mxsfloat( float density, float mxsFloat ) { return density * mxsFloat; }
    static color3f color_by_mxsvector( const color3f& mxsVector ) { return mxsVector; }

    static boost::array<M_STD_STRING, 2> scaleDensityByMXSFloatChannels;
    static boost::array<M_STD_STRING, 1> colorByMXSVectorChannels;
};

boost::array<M_STD_STRING, 2> ops::scaleDensityByMXSFloatChannels = { _T("Density"), _T("MXSFloat") };
boost::array<M_STD_STRING, 1> ops::colorByMXSVectorChannels = { _T("MXSVector") };
} // namespace

namespace {
void null_deleter( void* ) {}
} // namespace

/**
 * Function that applies the effects of the KrakatoaOptions Particle Flow operator to a stream.
 */
inline boost::shared_ptr<particle_istream> ApplyKrakatoaOptionsOperator( INode* pNode,
                                                                         boost::shared_ptr<particle_istream> pin ) {
    IPFActionList* pActions = PFActionListInterface( ParticleGroupInterface( pNode )->GetActionList() );
    for( int i = 0; i < pActions->NumActions(); ++i ) {
        if( !pActions->IsActionActive( i ) )
            continue;

        if( IKrakatoaPFOptions* pOptions = KrakatoaPFOptionsInterface( pActions->GetAction( i ) ) ) {
            if( pOptions->IsScriptedColorEnabled() )
                pin.reset( new apply_function_particle_istream<color3f( const color3f& )>(
                    pin, &ops::color_by_mxsvector, _T("Color"), ops::colorByMXSVectorChannels ) );
            if( pOptions->IsScriptedDensityEnabled() )
                pin.reset( new apply_function_particle_istream<float( float, float )>(
                    pin, &ops::scale_density_by_mxsfloat, _T("Density"), ops::scaleDensityByMXSFloatChannels ) );

            return pin;
        }
    }

    // TODO: global ActionList too!
    return pin;
}

inline boost::shared_ptr<particle_istream>
ApplyKrakatoaMaterialStream( boost::shared_ptr<particle_istream> pin, INode* pNode, TimeValue t,
                             Interval& inoutValidity,
                             frantic::max3d::particles::IMaxKrakatoaPRTEvalContextPtr pEvalContext ) {
    if( Mtl* pMtl = pNode->GetMtl() ) {
        if( is_krakatoa_material( pMtl ) ) {
            pin =
                static_cast<MaxKrakatoaMaterial*>( pMtl )->ApplyMaterial( pin, pNode, t, inoutValidity, pEvalContext );
        } else {
            frantic::max3d::shaders::renderInformation localRenderInfo;
            localRenderInfo.m_camera = pEvalContext->GetCamera();
            localRenderInfo.m_cameraPosition = frantic::max3d::to_max_t( localRenderInfo.m_camera.camera_position() );
            localRenderInfo.m_toObjectTM =
                frantic::max3d::from_max_t( Inverse( pNode->GetNodeTM( pEvalContext->GetTime() ) ) );
            localRenderInfo.m_toWorldTM = frantic::graphics::transform4f::identity();

            inoutValidity &= Interval( t, t );

            // pin.reset( new MaxKrakatoaStdMaterialIStream(pin, pMtl, localRenderInfo, true, true, true, true,
            // globContext->time) );
            pin = krakatoa::max3d::ApplyStdMaterial( pin, pMtl, localRenderInfo, true, true, true, true,
                                                     pEvalContext->GetTime() );
        }
    } else if( !pin->get_native_channel_map().has_channel( _T("Color") ) )
        pin.reset( new set_channel_particle_istream<color3f>( pin, _T("Color"),
                                                              color3f::from_RGBA( pNode->GetWireColor() ) ) );

    return pin;
}

/**
 * A particle source for pflow objects.
 */
class PFlowParticleSourceFactory::PFlowParticleSource : public KrakatoaParticleSource::KrakatoaParticleSourceImpl {
    bool m_updateOnly;

  public:
    PFlowParticleSource( INode* pNode, bool updateOnly )
        : KrakatoaParticleSource::KrakatoaParticleSourceImpl( pNode )
        , m_updateOnly( updateOnly ) {}
    virtual boost::shared_ptr<particle_istream> GetParticleStream( MaxKrakatoaRenderGlobalContext* globContext ) const {
        boost::shared_ptr<particle_istream> pin( new frantic::max3d::particles::streams::max_pflow_particle_istream(
            m_pNode, globContext->GetTime(), globContext->GetDefaultChannels() ) );
        pin = ApplyKrakatoaOptionsOperator( m_pNode, pin );
        // pin = ApplyKrakatoaMaterialStream(pin, globContext, m_pNode);

        // I was finding that the INode::GetMtl() wasn't consistently returning an assigned material for PFlow objects
        // in at least Max 2011. Using IParticleGroup::GetMaterial() is more consistent.
        if( IParticleGroup* pGroup = ParticleGroupInterface( m_pNode ) ) {
            Mtl* groupMtl = pGroup->GetMaterial();
            if( groupMtl ) {
                frantic::max3d::shaders::renderInformation localRenderInfo;
                localRenderInfo.m_camera = globContext->get_scene_context()->get_camera();
                localRenderInfo.m_cameraPosition =
                    frantic::max3d::to_max_t( localRenderInfo.m_camera.camera_position() );
                localRenderInfo.m_toObjectTM =
                    frantic::max3d::from_max_t( Inverse( m_pNode->GetNodeTM( globContext->time ) ) );
                localRenderInfo.m_toWorldTM = frantic::graphics::transform4f::identity();

                // pin.reset( new MaxKrakatoaStdMaterialIStream(pin, groupMtl, localRenderInfo, true, true, true, true,
                // globContext->time) );
                pin = krakatoa::max3d::ApplyStdMaterial( pin, groupMtl, localRenderInfo, true, true, true, true,
                                                         globContext->time );
            } else if( !pin->get_native_channel_map().has_channel( _T("Color") ) )
                pin.reset( new set_channel_particle_istream<color3f>( pin, _T("Color"),
                                                                      color3f::from_RGBA( pGroup->GetWireColor() ) ) );
        }

        pin = visibility_density_scale_stream_with_inode( m_pNode, globContext->time, pin );
        if( m_updateOnly )
            pin.reset( new fractional_particle_istream( pin, 1.0, 0, false ) );
        return pin;
    }
};

PFlowParticleSourceFactory::PFlowParticleSourceFactory( bool /*doNoneType*/, bool doBBoxType, bool doGeomType,
                                                        bool doPhanType ) {
    /*if(doNoneType)*/ m_enabledTypes.set( kPFRender_type_none );
    if( doBBoxType )
        m_enabledTypes.set( kPFRender_type_boundingBoxes );
    if( doGeomType )
        m_enabledTypes.set( kPFRender_type_geometry );
    if( doPhanType )
        m_enabledTypes.set( kPFRender_type_phantom );
}

void extract_connected_particle_groups( INode* node, std::set<INode*>& groups ) {
    if( !node ) {
        throw std::runtime_error( "extract_connected_particle_groups: got a NULL INode." );
    }

    Object* nodeObj = node->GetObjectRef();
    // first, make sure this inode has something to do with particles.
    if( nodeObj && GetParticleObjectExtInterface( nodeObj ) ) {
        std::set<IPFActionList*> connectedActionLists;

        const int numSubs = nodeObj->NumSubs();
        for( int i = 0; i < numSubs; ++i ) {
            if( Animatable* subanim = nodeObj->SubAnim( i ) ) {
                IPFActionList* actionList =
                    dynamic_cast<IPFActionList*>( subanim->GetInterface( PFACTIONLIST_INTERFACE ) );
                if( actionList ) {
                    connectedActionLists.insert( actionList );
                }
            }
        }

        // try to get the groups from the node.
        std::vector<INode*> inodes;
        frantic::max3d::get_referring_inodes( inodes, node );

        std::vector<INode*>::iterator i = inodes.begin();
        for( ; i != inodes.end(); i++ ) {
            if( *i ) {
                Object* obj = ( *i )->GetObjectRef();
                if( obj ) {
                    if( IParticleGroup* pGroup = ParticleGroupInterface( obj ) ) {
                        INode* actionListNode = pGroup->GetActionList();
                        IPFActionList* actionList = GetPFActionListInterface( actionListNode->GetObjectRef() );
                        if( pGroup->GetParticleContainer() &&
                            connectedActionLists.find( actionList ) != connectedActionLists.end() ) {
                            groups.insert( *i );
                        }
                    }
                }
            }
        }
    }
}

bool PFlowParticleSourceFactory::Process( INode* pNode, TimeValue /*t*/,
                                          std::vector<KrakatoaParticleSource>& outSources ) const {
    if( IParticleGroup* pGroup = ParticleGroupInterface( pNode ) ) {
        const int type = get_render_operator_type( pGroup );
        if( type >= 0 && m_enabledTypes[type] )
            outSources.push_back(
                KrakatoaParticleSource( new PFlowParticleSource( pNode, type == kPFRender_type_none ) ) );
        return true;
    } else {
        std::set<INode*> groups;
        extract_connected_particle_groups( pNode, groups );
        int numFound = 0;
        for( std::set<INode*>::iterator it = groups.begin(); it != groups.end(); ++it ) {
            if( IParticleGroup* pGroup = ParticleGroupInterface( *it ) ) {
                const int type = get_render_operator_type( pGroup );
                if( type >= 0 && m_enabledTypes[type] ) {
                    outSources.push_back(
                        KrakatoaParticleSource( new PFlowParticleSource( *it, type == kPFRender_type_none ) ) );
                    ++numFound;
                }
            }
        }
        return numFound > 0;
    }
}

/**
 * A particle source that uses the MNMesh structure to generate particles
 */
class GeometryParticleSourceFactory::GeometryParticleSource
    : public KrakatoaParticleSource::KrakatoaParticleSourceImpl {
  public:
    GeometryParticleSource( INode* pNode )
        : KrakatoaParticleSource::KrakatoaParticleSourceImpl( pNode ) {}
    virtual boost::shared_ptr<particle_istream> GetParticleStream( MaxKrakatoaRenderGlobalContext* globContext ) const {
        Interval validInterval = FOREVER;

        frantic::max3d::particles::IMaxKrakatoaPRTEvalContextPtr pEvalContext( globContext, &null_deleter );

        boost::shared_ptr<particle_istream> pin(
            new frantic::max3d::particles::streams::max_geometry_vert_particle_istream(
                m_pNode, globContext->GetTime(), 20, globContext->GetDefaultChannels() ) );
        pin = transform_stream_with_inode( m_pNode, pEvalContext->GetTime(), 20, pin );
        pin = ApplyKrakatoaMaterialStream( pin, m_pNode, pEvalContext->GetTime(), validInterval, pEvalContext );
        pin = visibility_density_scale_stream_with_inode( m_pNode, pEvalContext->GetTime(), pin );
        return pin;
    }
};

bool GeometryParticleSourceFactory::Process( INode* pNode, TimeValue /*t*/,
                                             std::vector<KrakatoaParticleSource>& outSources ) const {
    Object* pObj = pNode->GetObjectRef();
    if( pObj && pObj->FindBaseObject()->CanConvertToType( polyObjectClassID ) ) {
        if( m_enabled )
            outSources.push_back( KrakatoaParticleSource( new GeometryParticleSource( pNode ) ) );
        return true;
    }
    return false;
}

/**
 * A particle source for the legacy particle systems in max such as PArray and SuperSpray
 */
class LegacyParticleSourceFactory::LegacyParticleSource : public KrakatoaParticleSource::KrakatoaParticleSourceImpl {
  public:
    LegacyParticleSource( INode* pNode )
        : KrakatoaParticleSource::KrakatoaParticleSourceImpl( pNode ) {}
    virtual boost::shared_ptr<particle_istream> GetParticleStream( MaxKrakatoaRenderGlobalContext* globContext ) const {
        Interval validInterval = FOREVER;

        frantic::max3d::particles::IMaxKrakatoaPRTEvalContextPtr pEvalContext( globContext, &null_deleter );

        boost::shared_ptr<particle_istream> pin( new frantic::max3d::particles::streams::max_legacy_particle_istream(
            m_pNode, pEvalContext->GetTime(), pEvalContext->GetDefaultChannels() ) );
        pin = ApplyKrakatoaMaterialStream( pin, m_pNode, pEvalContext->GetTime(), validInterval, pEvalContext );
        pin = visibility_density_scale_stream_with_inode( m_pNode, pEvalContext->GetTime(), pin );
        return pin;
    }
};

bool LegacyParticleSourceFactory::Process( INode* pNode, TimeValue /*t*/,
                                           std::vector<KrakatoaParticleSource>& outSources ) const {
    Object* pObj = pNode->GetObjectRef();
    if( pObj && pObj->FindBaseObject()->GetInterface( I_SIMPLEPARTICLEOBJ ) ) {
        if( m_enabled )
            outSources.push_back( KrakatoaParticleSource( new LegacyParticleSource( pNode ) ) );
        return true;
    }

    return false;
}

/**
 * A particle source for the Krakatoa PRT Loader object.
 */
class PRTLoaderParticleSourceFactory::PRTLoaderParticleSource
    : public KrakatoaParticleSource::KrakatoaParticleSourceImpl {
  private:
    MaxKrakatoaPRTLoader* m_prtLoader;

  public:
    PRTLoaderParticleSource( INode* pNode )
        : KrakatoaParticleSource::KrakatoaParticleSourceImpl( pNode ) {
        m_prtLoader = GetMaxKrakatoaPRTLoader( pNode->GetObjectRef()->FindBaseObject() );
    }

    void AssertNotLoadingFrom( const M_STD_STRING& file ) const { m_prtLoader->AssertNotLoadingFrom( file ); }

    virtual boost::shared_ptr<particle_istream> GetParticleStream( MaxKrakatoaRenderGlobalContext* globContext ) const {
        Interval validInterval = FOREVER;

        frantic::max3d::particles::IMaxKrakatoaPRTEvalContextPtr pEvalContext( globContext, &null_deleter );

        boost::shared_ptr<particle_istream> pin = m_prtLoader->CreateStream( m_pNode, validInterval, pEvalContext );
        pin = visibility_density_scale_stream_with_inode( m_pNode, globContext->time, pin );
        return pin;
    }
};

bool PRTLoaderParticleSourceFactory::Process( INode* pNode, TimeValue /*t*/,
                                              std::vector<KrakatoaParticleSource>& outSources ) const {
    Object* pObj = pNode->GetObjectRef();
    if( !pObj )
        return false;
    pObj = pObj->FindBaseObject();

    if( GetMaxKrakatoaPRTLoader( pObj ) ) {
        if( m_enabled )
            outSources.push_back( KrakatoaParticleSource( new PRTLoaderParticleSource( pNode ) ) );
        return true;
    }

    return false;
}

/**
 * A particle source for Krakatoa PRT Objects.
 */
class PRTObjectParticleSourceFactory::PRTObjectParticleSource
    : public KrakatoaParticleSource::KrakatoaParticleSourceImpl {
  private:
    IMaxKrakatoaPRTObjectPtr m_pObj;

  public:
    PRTObjectParticleSource( INode* pNode, IMaxKrakatoaPRTObjectPtr pObj )
        : KrakatoaParticleSource::KrakatoaParticleSourceImpl( pNode )
        , m_pObj( pObj ) {}
    virtual boost::shared_ptr<particle_istream> GetParticleStream( MaxKrakatoaRenderGlobalContext* globContext ) const {
        Interval validInterval = FOREVER;

        frantic::max3d::particles::IMaxKrakatoaPRTEvalContextPtr pEvalContext( globContext, &null_deleter );

        boost::shared_ptr<particle_istream> pin = m_pObj->CreateStream( m_pNode, validInterval, pEvalContext );
        pin = visibility_density_scale_stream_with_inode( m_pNode, globContext->time, pin );
        return pin;
    }
};

bool PRTObjectParticleSourceFactory::Process( INode* pNode, TimeValue t,
                                              std::vector<KrakatoaParticleSource>& outSources ) const {
    /*Object* pObj = pNode->GetObjectRef();
    if( !pObj )
            return false;
    pObj = pObj->FindBaseObject();*/
    ObjectState os = pNode->EvalWorldState( t );

    if( IMaxKrakatoaPRTObjectPtr pPRTObj = GetIMaxKrakatoaPRTObject( os.obj ) ) {
        if( os.obj->ClassID() == m_classID || ( m_classID.PartA() == 0 && m_classID.PartB() == 0 ) ) {
            if( m_enabled )
                outSources.push_back( KrakatoaParticleSource( new PRTObjectParticleSource( pNode, pPRTObj ) ) );
            return true;
        }
    }

    return false;
}

#if defined( PHOENIX_SDK_AVAILABLE )
class PhoenixParticleSourceFactory::PhoenixParticleSource : public KrakatoaParticleSource::KrakatoaParticleSourceImpl {
  public:
    PhoenixParticleSource( INode* pNode )
        : KrakatoaParticleSource::KrakatoaParticleSourceImpl( pNode ) {}
    virtual boost::shared_ptr<particle_istream> GetParticleStream( MaxKrakatoaRenderGlobalContext* globContext ) const {
        if( Object* pObj = m_pNode->GetObjectRef() ) {
            pObj = pObj->FindBaseObject();
            if( IMaxKrakatoaPRTObjectPtr pPRTObj = GetIMaxKrakatoaPRTObject( pObj ) ) {
                if( pObj->ClassID() == MaxKrakatoaPhoenixObject_CLASS_ID ) {
                    Interval validity;
                    auto pin = static_cast<MaxKrakatoaPhoenixObject*>( pObj )->GetRenderStream(
                        globContext->GetTime(), validity, globContext->GetDefaultChannels() );
                    auto transform = frantic::max3d::get_node_transform( m_pNode, globContext->time, validity );
                    pin = boost::make_shared<transformed_particle_istream<float>>(
                        pin, transform, frantic::graphics::transform4f::zero() );
                    return visibility_density_scale_stream_with_inode( m_pNode, globContext->time, pin );
                }
            }
        }
        return boost::make_shared<empty_particle_istream>( globContext->GetDefaultChannels() );
    }
};

PhoenixParticleSourceFactory::PhoenixParticleSourceFactory( bool enabled )
    : m_enabled( enabled ) {}

bool PhoenixParticleSourceFactory::Process( INode* pNode, TimeValue t,
                                            std::vector<KrakatoaParticleSource>& outSources ) const {
    if( IsPhoenixObject( pNode, t ) ) {
        if( m_enabled )
            outSources.push_back( KrakatoaParticleSource( new PhoenixParticleSource( pNode ) ) );
        return true;
    }

    return false;
}
#endif

// Copied from ember project. Can't directly reference the project since KrakatoaMX can't depend on Ember...
#define PRTEmberObject_CLASSID Class_ID( 0x34d96c50, 0x7f532d01 )

// COpied from the stoke project.
#define StokeObject_CLASSID Class_ID( 0x2cf34591, 0x38e6602 )

void create_particle_factories( std::vector<boost::shared_ptr<KrakatoaParticleSourceFactory>>& outFactories,
                                MaxKrakatoa* pKrakatoa ) {
    bool doPRTloaders = true, doPRTVolume = true, doPRTHair = true, doPRTCreator = true, doPRTSource = true,
         doPRTSurface = true, doPRTEmber = true, doStoke = true;
    bool doPFlowGeomType = true, doPFlowBBoxType = true, doPFlowPhanType = true;
    bool doThinking = true;
    bool doFumeFX = true;
    bool doPhoenix = true;
    bool doLegacyMax = true;
    bool doGeometryVerts = true;

    if( pKrakatoa != NULL ) {
        doPRTloaders = pKrakatoa->get_property<bool>( _T("RenderKrakatoaLoaders") );
        doPRTVolume = pKrakatoa->get_property<bool>( _T("RenderGeometryVolumes") );
        doPRTHair = pKrakatoa->get_property<bool>( _T("RenderPRTHair") );
        doPRTCreator = pKrakatoa->get_property<bool>( _T("RenderPRTCreator") );
        doPRTSource = pKrakatoa->get_property<bool>( _T("RenderPRTSource") );
        doPRTSurface = pKrakatoa->get_property<bool>( _T("RenderPRTSurface") );
        doPRTEmber = pKrakatoa->get_property<bool>( _T("RenderPRTField") );
        doStoke = pKrakatoa->get_property<bool>( _T("RenderStoke") );

        doPFlowGeomType = pKrakatoa->get_property<bool>( _T("RenderParticleFlowGeometry") );
        doPFlowBBoxType = pKrakatoa->get_property<bool>( _T("RenderParticleFlowBBox") );
        doPFlowPhanType = pKrakatoa->get_property<bool>( _T("RenderParticleFlowPhantom") );

        doThinking = pKrakatoa->get_property<bool>( _T("RenderThinkingParticles") );
        doFumeFX = pKrakatoa->get_property<bool>( _T("RenderFumeFX") );
        doPhoenix = pKrakatoa->get_property<bool>( _T("RenderPhoenixFD") );

        doLegacyMax = pKrakatoa->get_property<bool>( _T("RenderMaxParticles") );
        doGeometryVerts = pKrakatoa->get_property<bool>( _T("RenderGeometryVertices") );
    }

    outFactories.push_back(
        boost::shared_ptr<KrakatoaParticleSourceFactory>( new PRTLoaderParticleSourceFactory( doPRTloaders ) ) );

    outFactories.push_back( boost::shared_ptr<KrakatoaParticleSourceFactory>(
        new PRTObjectParticleSourceFactory( doPRTVolume, MaxKrakatoaVolumeObject_CLASSID ) ) );
    outFactories.push_back( boost::shared_ptr<KrakatoaParticleSourceFactory>(
        new PRTObjectParticleSourceFactory( doPRTHair, MaxKrakatoaHairObject_CLASSID ) ) );
    outFactories.push_back( boost::shared_ptr<KrakatoaParticleSourceFactory>(
        new PRTObjectParticleSourceFactory( doPRTCreator, MaxKrakatoaPRTMakerObject_CLASSID ) ) );
    outFactories.push_back( boost::shared_ptr<KrakatoaParticleSourceFactory>(
        new PRTObjectParticleSourceFactory( doPRTSource, MaxKrakatoaPRTSourceObject_CLASSID ) ) );
    outFactories.push_back( boost::shared_ptr<KrakatoaParticleSourceFactory>(
        new PRTObjectParticleSourceFactory( doPRTSurface, MaxKrakatoaPRTSurface_CLASSID ) ) );
    outFactories.push_back( boost::shared_ptr<KrakatoaParticleSourceFactory>(
        new PRTObjectParticleSourceFactory( doPRTEmber, PRTEmberObject_CLASSID ) ) );
    outFactories.push_back( boost::shared_ptr<KrakatoaParticleSourceFactory>(
        new PRTObjectParticleSourceFactory( doStoke, StokeObject_CLASSID ) ) );

    outFactories.push_back( boost::shared_ptr<KrakatoaParticleSourceFactory>(
        new PFlowParticleSourceFactory( false, doPFlowBBoxType, doPFlowGeomType, doPFlowPhanType ) ) );
#if defined( THINKING_PARTICLES_SDK_AVAILABLE )
    outFactories.push_back(
        boost::shared_ptr<KrakatoaParticleSourceFactory>( new ThinkingParticleSourceFactory( doThinking ) ) );
#endif
#if defined( FUMEFX_SDK_AVAILABLE )
    outFactories.push_back(
        boost::shared_ptr<KrakatoaParticleSourceFactory>( new FumeFXParticleSourceFactory( doFumeFX ) ) );
#endif
#if defined( PHOENIX_SDK_AVAILABLE )
    outFactories.push_back(
        boost::shared_ptr<KrakatoaParticleSourceFactory>( new PhoenixParticleSourceFactory( doPhoenix ) ) );
#endif

    // Fallback for non-explicit class of PRTObject. Default to using it.
    outFactories.push_back( boost::shared_ptr<KrakatoaParticleSourceFactory>(
        new PRTObjectParticleSourceFactory( true, Class_ID( 0, 0 ) ) ) );

    outFactories.push_back(
        boost::shared_ptr<KrakatoaParticleSourceFactory>( new LegacyParticleSourceFactory( doLegacyMax ) ) );
    outFactories.push_back(
        boost::shared_ptr<KrakatoaParticleSourceFactory>( new GeometryParticleSourceFactory( doGeometryVerts ) ) );
}

void collect_particle_objects( INode* sceneRoot, bool hideFrozen, TimeValue t,
                               std::vector<KrakatoaParticleSource>& outSources,
                               const std::vector<boost::shared_ptr<KrakatoaParticleSourceFactory>>& factories,
                               std::set<INode*> geomNodes, std::set<INode*> doneNodes ) {
    if( doneNodes.find( sceneRoot ) != doneNodes.end() )
        return;

    if( sceneRoot ) {
        FF_LOG( debug ) << _T("Inspecting \"") << sceneRoot->GetName() << _T("\"") << std::endl;
    }

    doneNodes.insert( sceneRoot );

    if( !sceneRoot->IsNodeHidden( true ) && sceneRoot->Renderable() && sceneRoot->GetPrimaryVisibility() &&
        ( !sceneRoot->IsFrozen() || !hideFrozen ) && geomNodes.find( sceneRoot ) == geomNodes.end() ) {
        // Interval tmValid(FOREVER);
        // Matrix3 objToWorld = sceneRoot->GetObjTMAfterWSM(t,&tmValid);
        //
        ////NOTE: We have to evaluate the world state of the object to handle pesky
        ////       modifiers and such.
        // sceneRoot->EvalWorldState( t );

        geomNodes.insert( sceneRoot );
        for( std::size_t i = 0; i < factories.size(); ++i ) {
            if( factories[i]->Process( sceneRoot, t, outSources ) )
                break;
        }
    }

    for( int i = 0; i < sceneRoot->NumberOfChildren(); ++i )
        collect_particle_objects( sceneRoot->GetChildNode( i ), hideFrozen, t, outSources, factories, geomNodes,
                                  doneNodes );
}
