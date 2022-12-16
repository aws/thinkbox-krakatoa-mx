// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0
#include "stdafx.h"

#include "resource.h"

#include <max.h>

#include <frantic/graphics/camera.hpp>
#include <frantic/particles/streams/concatenated_particle_istream.hpp>

#include <frantic/max3d/particles/IMaxKrakatoaPRTObject.hpp>

#include <krakatoa/raytrace_renderer/raytrace_renderer.hpp>
#include <krakatoa/shader_functions.hpp>

#include <tbb/task_scheduler_init.h>

#include "MaxKrakatoaGeometryRenderer.h"
#include "MaxKrakatoaParticleSources.h"
#include "MaxKrakatoaReferenceTarget.h"
#include "MaxKrakatoaRenderGlobalContext.h"
#include "MaxKrakatoaSceneContext.h"

using frantic::graphics::color3f;
using frantic::graphics::vector3f;

#define MaxKrakatoaAtmospheric_NAME "KrakatoaAtmospheric"
#define MaxKrakatoaAtmospheric_CLASSID Class_ID( 0x7f1e439b, 0x34a842e9 )
#define MaxKrakatoaPRTSourceObject_VERSION 0

enum {
    kParticleNodes,
    kVoxelLength,
    kUseEmission,
    kUseAbsorption,
    kRaymarchStepMin,
    kRaymarchStepMax,
    kCameraDensityScale,
    kCameraDensityScaleExponent,
    kUseCameraEmissionScale,
    kCameraEmissionScale,
    kCameraEmissionScaleExponent,
    kUseLightDensityScale,
    kLightDensityScale,
    kLightDensityScaleExponent,
};

ClassDesc2* GetMaxKrakatoaAtmosphericDesc();

// Implementation in MaxKrakatoaUtils.cpp
extern void SetupLightsRecursive( std::vector<boost::shared_ptr<frantic::rendering::lights::lightinterface>>& outLights,
                                  INode* pNode, std::set<INode*>& doneNodes, TimeValue t,
                                  frantic::logging::progress_logger& progress, float motionInterval, float motionBias,
                                  bool saveAtten );

class MaxKrakatoaAtmospheric : public MaxKrakatoaReferenceTarget<Atmospheric, MaxKrakatoaAtmospheric> {
    krakatoa::raytrace_renderer::raytrace_renderer_ptr m_raytracer;
    krakatoa::renderer::particle_container_type m_particles;

    MaxKrakatoaRenderGlobalContext m_globContext;

    frantic::max3d::particles::IMaxKrakatoaPRTEvalContextPtr m_pEvalContext;

  protected:
    virtual ClassDesc2* GetClassDesc() { return GetMaxKrakatoaAtmosphericDesc(); }

  public:
    MaxKrakatoaAtmospheric();

    // From ReferenceMaker
    virtual RefResult NotifyRefChanged( const Interval& changeInt, RefTargetHandle hTarget, PartID& partID,
                                        RefMessage message, BOOL propagate );

    // From SpecialEffect
#if MAX_VERSION_MAJOR < 24
    virtual MSTR GetName();
#else
    virtual MSTR GetName( bool localized );
#endif
    virtual void Update( TimeValue t, Interval& valid );

    // From Atmospheric
    virtual AtmosParamDlg* CreateParamDialog( IRendParams* ip );
    virtual void Shade( ShadeContext& sc, const Point3& p0, const Point3& p1, Color& color, Color& trans,
                        BOOL isBG = FALSE );
};

class MaxKrakatoaAtmosphericDesc : public ClassDesc2 {
  public:
    ParamBlockDesc2 m_paramDesc;

  public:
    MaxKrakatoaAtmosphericDesc();

    int IsPublic() { return TRUE; }
    void* Create( BOOL /*loading*/ ) { return new MaxKrakatoaAtmospheric; }
    const TCHAR* ClassName() { return _T( MaxKrakatoaAtmospheric_NAME ); }
#if MAX_VERSION_MAJOR >= 24
    const TCHAR* NonLocalizedClassName() { return _T( MaxKrakatoaAtmospheric_NAME ); }
#endif
    SClass_ID SuperClassID() { return ATMOSPHERIC_CLASS_ID; }
    Class_ID ClassID() { return MaxKrakatoaAtmospheric_CLASSID; }
    const TCHAR* Category() { return _T("Krakatoa"); }

    const TCHAR* InternalName() {
        return _T( MaxKrakatoaAtmospheric_NAME );
    }                                           // returns fixed parsable name (scripter-visible name)
    HINSTANCE HInstance() { return hInstance; } // returns owning module handle
};

class MaxKrakatoaAtmosphericDlgProc;

MaxKrakatoaAtmosphericDlgProc* GetMaxKrakatoaAtmosphericDlgProc();

MaxKrakatoaAtmosphericDesc::MaxKrakatoaAtmosphericDesc()
    : m_paramDesc( 0,                                        // Block num
                   _T("Parameters"),                         // Internal name
                   NULL,                                     // Localized name
                   NULL,                                     // ClassDesc2*
                   P_AUTO_CONSTRUCT + P_VERSION + P_AUTO_UI, // Flags
                   MaxKrakatoaPRTSourceObject_VERSION,
                   0,                                     // PBlock Ref Num
                   IDD_ATMOSPHERIC, IDS_PARAMETERS, 0, 0, // AutoUI stuff
                   GetMaxKrakatoaAtmosphericDlgProc(),    // Custom UI handling
                   p_end ) {
    m_paramDesc.SetClassDesc( this );
    m_paramDesc.AddParam( kParticleNodes, _T("ParticleNodes"), TYPE_INODE_TAB, 0, P_VARIABLE_SIZE, 0, p_end );
    m_paramDesc.AddParam( kVoxelLength, _T("VoxelLength"), TYPE_FLOAT, 0, 0, p_end );
    m_paramDesc.AddParam( kUseEmission, _T("UseEmission"), TYPE_BOOL, 0, 0, p_end );
    m_paramDesc.AddParam( kUseAbsorption, _T("UseAbsorption"), TYPE_BOOL, 0, 0, p_end );
    m_paramDesc.AddParam( kRaymarchStepMin, _T("RaymarchStepMin"), TYPE_FLOAT, 0, 0, p_end );
    m_paramDesc.AddParam( kRaymarchStepMax, _T("RaymarchStepMax"), TYPE_FLOAT, 0, 0, p_end );
    m_paramDesc.AddParam( kCameraDensityScale, _T("CameraDensityScale"), TYPE_FLOAT, 0, 0, p_end );
    m_paramDesc.AddParam( kCameraDensityScaleExponent, _T("CameraDensityScaleExponent"), TYPE_FLOAT, 0, 0, p_end );
    m_paramDesc.AddParam( kUseCameraEmissionScale, _T("UseCameraEmissionScale"), TYPE_BOOL, 0, 0, p_end );
    m_paramDesc.AddParam( kCameraEmissionScale, _T("CameraEmissionScale"), TYPE_FLOAT, 0, 0, p_end );
    m_paramDesc.AddParam( kCameraEmissionScaleExponent, _T("CameraEmissionScaleExponent"), TYPE_FLOAT, 0, 0, p_end );
    m_paramDesc.AddParam( kUseLightDensityScale, _T("UseLightDensityScale"), TYPE_BOOL, 0, 0, p_end );
    m_paramDesc.AddParam( kLightDensityScale, _T("LightDensityScale"), TYPE_FLOAT, 0, 0, p_end );
    m_paramDesc.AddParam( kLightDensityScaleExponent, _T("LightDensityScaleExponent"), TYPE_FLOAT, 0, 0, p_end );

    m_paramDesc.ParamOption( kVoxelLength, p_default, 1.f, p_end );
    m_paramDesc.ParamOption( kUseEmission, p_default, FALSE, p_end );
    m_paramDesc.ParamOption( kUseAbsorption, p_default, FALSE, p_end );
    m_paramDesc.ParamOption( kRaymarchStepMin, p_default, 1.f, p_end );
    m_paramDesc.ParamOption( kRaymarchStepMax, p_default, 1.f, p_end );
    m_paramDesc.ParamOption( kCameraDensityScale, p_default, 5.f, p_end );
    m_paramDesc.ParamOption( kCameraDensityScaleExponent, p_default, -1.f, p_end );
    m_paramDesc.ParamOption( kUseCameraEmissionScale, p_default, FALSE, p_end );
    m_paramDesc.ParamOption( kCameraEmissionScale, p_default, 5.f, p_end );
    m_paramDesc.ParamOption( kCameraEmissionScaleExponent, p_default, -1.f, p_end );
    m_paramDesc.ParamOption( kUseLightDensityScale, p_default, FALSE, p_end );
    m_paramDesc.ParamOption( kLightDensityScale, p_default, 5.f, p_end );
    m_paramDesc.ParamOption( kLightDensityScaleExponent, p_default, -1.f, p_end );
}

ClassDesc2* GetMaxKrakatoaAtmosphericDesc() {
    static MaxKrakatoaAtmosphericDesc theMaxKrakatoaAtmosphericDesc;
    return &theMaxKrakatoaAtmosphericDesc;
}

class MaxKrakatoaAtmosphericDlgProc : public ParamMap2UserDlgProc {
  public:
    MaxKrakatoaAtmosphericDlgProc();
    virtual ~MaxKrakatoaAtmosphericDlgProc();
    virtual INT_PTR DlgProc( TimeValue t, IParamMap2* map, HWND hWnd, UINT msg, WPARAM wParam, LPARAM lParam );
    virtual void DeleteThis() { /*delete this;*/
    }
};

MaxKrakatoaAtmosphericDlgProc::MaxKrakatoaAtmosphericDlgProc() {}

MaxKrakatoaAtmosphericDlgProc::~MaxKrakatoaAtmosphericDlgProc() {}

INT_PTR MaxKrakatoaAtmosphericDlgProc::DlgProc( TimeValue /*t*/, IParamMap2* map, HWND /*hWnd*/, UINT msg,
                                                WPARAM wParam, LPARAM /*lParam*/ ) {
    IParamBlock2* pblock = map->GetParamBlock();
    if( !pblock )
        return FALSE;

    switch( msg ) {
    case WM_COMMAND:
        if( HIWORD( wParam ) != BN_CLICKED )
            break;

        if( LOWORD( wParam ) == IDC_ATMOSPHERIC_OPEN_BUTTON ) {

            frantic::max3d::mxs::expression( _T("FranticParticleRenderMXS.OpenKrakatoaAtmosphericDialog arg") )
                .bind( _T("arg"), static_cast<ReferenceTarget*>( pblock->GetOwner() ) )
                .evaluate<void>();

            return TRUE;
        }
        break;
    }

    return FALSE;
}

MaxKrakatoaAtmosphericDlgProc* GetMaxKrakatoaAtmosphericDlgProc() {
    static MaxKrakatoaAtmosphericDlgProc theMaxKrakatoaAtmosphericDlgProc;
    return &theMaxKrakatoaAtmosphericDlgProc;
}

MaxKrakatoaAtmospheric::MaxKrakatoaAtmospheric() { GetMaxKrakatoaAtmosphericDesc()->MakeAutoParamBlocks( this ); }

RefResult MaxKrakatoaAtmospheric::NotifyRefChanged( const Interval& /*changeInt*/, RefTargetHandle hTarget,
                                                    PartID& /*partID*/, RefMessage message, BOOL /*propagate*/ ) {
    return REF_SUCCEED;
}

#if MAX_VERSION_MAJOR < 24
MSTR MaxKrakatoaAtmospheric::GetName() {
#else
MSTR MaxKrakatoaAtmospheric::GetName( bool localized ) {
#endif
    return _T("Krakatoa Atmospheric");
}

void collect_shadow_casters( INode* curNode, TimeValue t,
                             /*std::set<INode*>& visitedNodes, */ std::set<INode*>& shadowCasters ) {
    for( int i = 0, iEnd = curNode->NumberOfChildren(); i < iEnd; ++i ) {
        INode* child = curNode->GetChildNode( i );

        // BOOL isHidden = child->IsNodeHidden(TRUE);
        // BOOL isHidden2 = child->IsHidden(0, TRUE);
        // BOOL isHidden3 = child->IsHidden();
        // BOOL castsShadows = child->CastShadows();
        // BOOL isREnderable = child->Renderable();

        if( child && !child->IsNodeHidden( TRUE ) && child->CastShadows() && child->Renderable() ) {
            ObjectState os = child->EvalWorldState( t );

            if( os.obj && os.obj->IsRenderable() && os.obj->SuperClassID() == GEOMOBJECT_CLASS_ID ) {
                SClass_ID sclassID = os.obj->SuperClassID();
                BOOL isRenderableObj = os.obj->IsRenderable();

                shadowCasters.insert( child );

                if( frantic::logging::is_logging_debug() ) {
                    M_STD_STRING name = child->GetName();

                    frantic::logging::debug << _T("KRAtmospheric found shadow caster: ") << name << std::endl;
                }
            }
        }

        collect_shadow_casters( child, t, shadowCasters );
    }
}

void MaxKrakatoaAtmospheric::Update( TimeValue t, Interval& valid ) {
    m_raytracer.reset();

    valid.SetInstant( t );

    frantic::graphics::camera<float> m_camera;

    frantic::channels::channel_map pcm;
    pcm.define_channel<frantic::graphics::vector3f>( _T("Position") );
    pcm.define_channel<frantic::graphics::color3f>( _T("Color") );
    if( m_pblock->GetInt( kUseEmission ) )
        pcm.define_channel<frantic::graphics::color3f>( _T("Emission") );
    if( m_pblock->GetInt( kUseAbsorption ) )
        pcm.define_channel<frantic::graphics::color3f>( _T("Absorption") );
    pcm.define_channel<float>( _T("Density") );
    pcm.end_channel_definition();

    MaxKrakatoaSceneContextPtr sceneContext( new MaxKrakatoaSceneContext );
    sceneContext->set_camera( m_camera );
    sceneContext->set_time( TicksToSec( t ) );
    sceneContext->set_render_global_context( &m_globContext );

    {
        INode* sceneRoot = GetCOREInterface()->GetRootNode();

        std::set<INode*> shadowCasters;

        if( sceneRoot )
            collect_shadow_casters( sceneRoot, t, shadowCasters );

        krakatoa::matte_interface_ptr matteInterface;

        if( !shadowCasters.empty() ) {
            // add our nodes to the matte object collection in the sceneContext
            for( std::set<INode*>::iterator it = shadowCasters.begin(), itEnd = shadowCasters.end(); it != itEnd;
                 ++it ) {
                krakatoa::matte_primitive_ptr prim( new MaxMattePrimitive( *it, Interval( t, t ), true, 0 ) );

                sceneContext->add_matte_object( prim );
            }

            // create a new matte interface. this will be given to the renderer.
            // the matte interface will get its mesh objects though the sceneContext.
            matteInterface.reset( new MaxKrakatoaMatteInterface( sceneContext ) );
        }

        std::set<INode*> doneNodes;
        std::vector<boost::shared_ptr<frantic::rendering::lights::lightinterface>> renderLights;
        frantic::logging::null_progress_logger logger;

        SetupLightsRecursive( renderLights, GetCOREInterface()->GetRootNode(), doneNodes, t, logger, 0, 0, false );

        for( size_t i = 0, iEnd = renderLights.size(); i < iEnd; ++i ) {
            krakatoa::light_object_ptr lightObj = krakatoa::light_object::create( renderLights[i] );

            krakatoa::shadow_map_generator_ptr shadowMapGen;
            if( matteInterface )
                shadowMapGen.reset( new krakatoa::shadow_map_generator( matteInterface ) );
            lightObj->set_shadow_map_generator( shadowMapGen );

            sceneContext->add_light_object( lightObj );
        }
    }

    m_globContext.reset( sceneContext );
    m_globContext.set_channel_map( pcm );
    m_globContext.set_renderprogress_callback( NULL );

    Interval ivalid = FOREVER;

    std::vector<KrakatoaParticleSource> sources;
    std::vector<boost::shared_ptr<KrakatoaParticleSourceFactory>> factories;
    std::vector<boost::shared_ptr<frantic::particles::streams::particle_istream>> pins;

    create_particle_factories( factories );

    for( int i = 0, iEnd = m_pblock->Count( kParticleNodes ); i < iEnd; ++i ) {
        INode* pNode = m_pblock->GetINode( kParticleNodes, t, i );
        if( !pNode )
            continue;

        for( std::vector<boost::shared_ptr<KrakatoaParticleSourceFactory>>::const_iterator
                 itFactory = factories.begin(),
                 itFactoryEnd = factories.end();
             itFactory != itFactoryEnd; ++itFactory ) {
            if( ( *itFactory )->Process( pNode, t, sources ) )
                break;
        }

        ObjectState os = pNode->EvalWorldState( t );

        ivalid &= os.Validity( t );
    }

    for( std::vector<KrakatoaParticleSource>::const_iterator it = sources.begin(), itEnd = sources.end(); it != itEnd;
         ++it )
        pins.push_back( it->GetParticleStream( &m_globContext ) );

    m_particles.reset( pcm );

    boost::shared_ptr<frantic::particles::streams::particle_istream> resultStream;

    if( pins.size() > 0 ) {
        if( pins.size() > 1 )
            resultStream.reset( new frantic::particles::streams::concatenated_particle_istream( pins ) );
        else
            resultStream = pins.back();
    }

    if( resultStream ) {
        boost::scoped_array<char> defaultParticle( new char[pcm.structure_size()] );

        pcm.construct_structure( defaultParticle.get() );
        if( pcm.has_channel( _T("Density") ) )
            pcm.get_cvt_accessor<float>( _T("Density") ).set( defaultParticle.get(), 1.f );
        if( pcm.has_channel( _T("Selection") ) )
            pcm.get_cvt_accessor<float>( _T("Selection") ).set( defaultParticle.get(), 1.f );
        if( pcm.has_channel( _T("Color") ) )
            pcm.get_cvt_accessor<color3f>( _T("Color") ).set( defaultParticle.get(), color3f( 1.f ) );

        resultStream->set_channel_map( pcm );
        resultStream->set_default_particle( defaultParticle.get() );

        m_particles.insert_particles( resultStream );
    }

    if( m_particles.size() == 0 )
        return;

    krakatoa::shader_params params;
    params.phaseFunction = _T("Isotropic");

    float voxelLength = std::max( 1e-4f, m_pblock->GetFloat( kVoxelLength, t ) );
    float maxStepsize = std::max( 1e-4f, m_pblock->GetFloat( kRaymarchStepMax, t ) * voxelLength );
    float minStepsize =
        std::max( 1e-4f, std::min( maxStepsize, m_pblock->GetFloat( kRaymarchStepMin, t ) ) ) * voxelLength;

    float cameraDensityScale = m_pblock->GetFloat( kCameraDensityScale, t ) *
                               powf( 10.f, m_pblock->GetFloat( kCameraDensityScaleExponent, t ) );
    float cameraEmissionScale = !m_pblock->GetInt( kUseCameraEmissionScale, t )
                                    ? cameraDensityScale
                                    : m_pblock->GetFloat( kCameraEmissionScale, t ) *
                                          powf( 10.f, m_pblock->GetFloat( kCameraEmissionScaleExponent, t ) );
    float lightDensityScale = !m_pblock->GetInt( kUseLightDensityScale, t )
                                  ? cameraDensityScale
                                  : m_pblock->GetFloat( kLightDensityScale, t ) *
                                        powf( 10.f, m_pblock->GetFloat( kLightDensityScaleExponent, t ) );

    Interval garbage;
    Point3 ambientLight = 0.25f * GetCOREInterface()->GetAmbient(
                                      t, garbage ); // Arbitrary factor of 4 to make it look about right. *sigh*

    m_raytracer = krakatoa::raytrace_renderer::raytrace_renderer::create_instance();
    m_raytracer->set_density_scale( cameraDensityScale, lightDensityScale );
    m_raytracer->set_emission_scale( cameraEmissionScale );
    m_raytracer->set_voxel_length( voxelLength );
    m_raytracer->set_raymarch_stepsize( minStepsize, maxStepsize );
    m_raytracer->set_particles( &m_particles );
    m_raytracer->set_scene_context( m_globContext.get_scene_context() );
    m_raytracer->set_shader( krakatoa::create_shader( params ) );
    m_raytracer->set_ambient_light( frantic::graphics::color3f( ambientLight.x, ambientLight.y, ambientLight.z ) );

    m_raytracer->initialize();

    if( !ivalid.InInterval( t ) )
        ivalid.SetInstant( t );

    valid &= ivalid;
}

AtmosParamDlg* MaxKrakatoaAtmospheric::CreateParamDialog( IRendParams* ip ) {
    return GetMaxKrakatoaAtmosphericDesc()->CreateParamDialogs( ip, this );
}

void MaxKrakatoaAtmospheric::Shade( ShadeContext& sc, const Point3& p0, const Point3& p1, Color& color, Color& trans,
                                    BOOL isBG ) {
    if( !m_raytracer )
        return;

    frantic::graphics::vector3f start, dir;
    double t0 = 0.0, t1 = 1.0;

    start = frantic::max3d::from_max_t( sc.PointTo( p0, REF_WORLD ) );

    if( isBG ) {
        dir = frantic::max3d::from_max_t( sc.VectorTo( sc.V(), REF_WORLD ) );
        t1 = std::numeric_limits<float>::max();
    } else {
        dir = frantic::max3d::from_max_t( sc.PointTo( p1, REF_WORLD ) );
        dir -= start;
    }

    frantic::graphics::vector3f end = frantic::max3d::from_max_t( p1 );
    frantic::graphics::ray3f r( start, dir );

    krakatoa::renderer::color_type light;
    krakatoa::renderer::alpha_type alpha;

    if( sc.mode == SCMODE_SHADOW ) {
        m_raytracer->raymarch_opacity( r, t0, t1, alpha );
    } else {
        m_raytracer->raymarch( r, t0, t1, light, alpha );
    }

    color.r = light.r + ( 1.f - alpha.ar ) * color.r;
    color.g = light.g + ( 1.f - alpha.ag ) * color.g;
    color.b = light.b + ( 1.f - alpha.ab ) * color.b;

    trans.r = 1.f - ( alpha.ar + ( 1.f - alpha.ar ) * ( 1.f - trans.r ) );
    trans.g = 1.f - ( alpha.ag + ( 1.f - alpha.ag ) * ( 1.f - trans.g ) );
    trans.b = 1.f - ( alpha.ab + ( 1.f - alpha.ab ) * ( 1.f - trans.b ) );
}
