// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0
#include "stdafx.h"

#include "KrakatoaMXVersion.h"
#include "MaxKrakatoa.h"
#include "MaxKrakatoaChannelModifier.h"
#include "MaxKrakatoaGlobalInterface.h"
#include "MaxKrakatoaParamDlg.h"
#include "MaxKrakatoaSceneContext.h"
#include "Render Elements\IMaxKrakatoaRenderElement.h"

#include <krakatoa/renderer.hpp>
#include <krakatoa/splat_renderer/splat_renderer.hpp>
#include <krakatoa/velocity_render_element.hpp>

#include <frantic/max3d/geometry/null_view.hpp>
#include <frantic/max3d/max_utility.hpp>
#include <frantic/max3d/maxscript/maxscript.hpp>
#include <frantic/max3d/particles/streams/max_geometry_vert_particle_istream.hpp>
#include <frantic/max3d/rendering/renderplugin_utils.hpp>
#include <frantic/max3d/shaders/max_environment_map_provider.hpp>
#include <frantic/max3d/units.hpp>

#include <frantic/graphics/color_with_alpha.hpp>
#include <frantic/graphics2d/framebuffer.hpp>
#include <frantic/particles/streams/apply_function_particle_istream.hpp>
#include <frantic/particles/streams/particle_container_particle_istream.hpp>
#include <frantic/particles/streams/transformed_particle_istream.hpp>

#include <tbb/tbb_exception.h>

#include <boost/random.hpp>

#include <render.h>

//#define KRAKATOA_PROFILING 1
//#define KRAKATOA_IO_PROFILING

#if defined( KRAKATOA_PROFILING ) && !defined( KRAKATOA_IO_PROFILING )
#define KRAKATOA_GLOBAL_PROFILING
#endif

#if defined( _WIN32 ) && defined( KRAKATOA_PROFILING ) /*&& _MSC_VER >= 1600*/
#pragma message( "Profiling Enabled" )
#include <VSPerf.h>
#pragma comment( lib, "VSPerf.lib" )

class scoped_vs_profile {
    bool isProfiling;

  public:
    scoped_vs_profile()
        : isProfiling( false ) {
        PROFILE_COMMAND_STATUS status;

        status = StartProfile( PROFILE_GLOBALLEVEL, PROFILE_CURRENTID );
        if( status == PROFILE_OK ) {
            status = ResumeProfile( PROFILE_GLOBALLEVEL, PROFILE_CURRENTID );
            if( status == PROFILE_OK )
                isProfiling = true;
        }
    }

    ~scoped_vs_profile() {
        PROFILE_COMMAND_STATUS status;

        if( isProfiling ) {
            status = SuspendProfile( PROFILE_GLOBALLEVEL, PROFILE_CURRENTID );
            if( status != PROFILE_OK )
                MessageBox( NULL,
                            ( "ResumeProfile result was: " + boost::lexical_cast<M_STD_STRING>( status ) ).c_str(),
                            "ResumeProfile ERROR", MB_OK );

            status = StopProfile( PROFILE_GLOBALLEVEL, PROFILE_CURRENTID );
            if( status != PROFILE_OK )
                MessageBox( NULL, ( "StopProfile result was: " + boost::lexical_cast<M_STD_STRING>( status ) ).c_str(),
                            "ResumeProfile ERROR", MB_OK );
        }
    }
} profile;
#endif

using namespace frantic;
using namespace frantic::rendering;
using namespace frantic::max3d;
using namespace frantic::max3d::rendering;

using boost::shared_ptr;

using frantic::channels::channel_data_type_from_string;
using frantic::channels::channel_map;
using frantic::graphics::alpha3f;
using frantic::graphics::camera;
using frantic::graphics::color3f;
using frantic::graphics::color6f;
using frantic::graphics::vector3f;
using frantic::graphics2d::framebuffer;
using frantic::graphics2d::size2;
using frantic::particles::streams::particle_istream;

using frantic::max3d::logging::maxrender_progress_logger;

class MaxKrakatoaClassDesc : public ClassDesc2 {
  public:
    int IsPublic() { return TRUE; }
    void* Create( BOOL /*loading*/ ) { return new MaxKrakatoa(); }
    const TCHAR* ClassName() { return _T("Krakatoa"); }
#if MAX_VERSION_MAJOR >= 24
    const TCHAR* NonLocalizedClassName() { return _T("Krakatoa"); }
#endif
    SClass_ID SuperClassID() { return RENDERER_CLASS_ID; }
    Class_ID ClassID() { return MaxKrakatoa_CLASS_ID; }
    const TCHAR* Category() { return _T(""); }

    // returns fixed parsable name (scripter-visible name)
    const TCHAR* InternalName() { return _T("FranticParticleRender"); }
    HINSTANCE HInstance() { return hInstance; } // returns owning module handle
};

ClassDesc2* GetMaxKrakatoaDesc() {
    static MaxKrakatoaClassDesc MaxKrakatoaDesc;
    return &MaxKrakatoaDesc;
}

// ParamBlockDesc for channel override texmaps
ParamBlockDesc2 OverridePblockDesc( 0, _T("ChannelOverrides"), NULL, GetMaxKrakatoaDesc(), P_AUTO_CONSTRUCT, 0,
                                    kColorOverrideTexmap, _T("ColorOverrideTexmap"), TYPE_TEXMAP, 0, 0, p_end,
                                    kAbsorptionOverrideTexmap, _T("AbsorptionOverrideTexmap"), TYPE_TEXMAP, 0, 0, p_end,
                                    kEmissionOverrideTexmap, _T("EmissionOverrideTexmap"), TYPE_TEXMAP, 0, 0, p_end,
                                    kDensityOverrideTexmap, _T("DensityOverrideTexmap"), TYPE_TEXMAP, 0, 0, p_end,
                                    p_end );

// Global variable which gets set to the currently rendering particle renderer
MaxKrakatoa* renderingMaxKrakatoa = 0;

// Global variable to track whether the NOTIFY_MXS_STARTUP callback has been
// invoked.
//
// In 3ds Max 2019 update 3, 3ds Max began to instantiate MaxKrakatoa early
// during startup.  Based on the presence of "ActiveShade" in the callstack
// when this occurs, we believe that this is done for the sake of initializing
// 3ds Max's new ActiveShade viewport (which Krakatoa doesn't support).
// This instantiation occurs before Krakatoa's MAXScripts are loaded.  This
// causes Krakatoa's call to FranticParticleRenderMXS.InitRenderer() to
// fail, which leads to an error popup in interactive mode, or a failed
// render in network rendering mode.
//
// We discriminate between the ActiveShade instantiation and a "real"
// instantiation with which the user might actually render based on whether
// the NOTIFY_MXS_STARTUP callback has been invoked (and so this variable
// has been set to true).
bool g_doneMxsStartup = false;

namespace {
void DoInitializeMaxKrakatoaDoneMxsStartup( void* /*param*/, NotifyInfo* /*info*/ ) { g_doneMxsStartup = true; }
} // namespace

void InitializeMaxKrakatoaDoneMxsStartup() {
    RegisterNotification( &DoInitializeMaxKrakatoaDoneMxsStartup, NULL, NOTIFY_MXS_STARTUP );
}

// This function retrieves the current Krakatoa plugin , for use by maxscript
MaxKrakatoa* GetMaxKrakatoa() {
    if( renderingMaxKrakatoa != 0 ) {
        return renderingMaxKrakatoa;
    } else {
        Renderer* r = GetCOREInterface()->GetCurrentRenderer();
        if( r->ClassID() == MaxKrakatoa_CLASS_ID ) {
            return static_cast<MaxKrakatoa*>( r );
        } else {
            throw MAXException( _T("Current renderer must be set to Krakatoa to access its properties.") );
        }
    }
}

class render_cancelled_exception : public std::exception {
  public:
    render_cancelled_exception() {}
    render_cancelled_exception( const std::string& err )
        : exception( err.c_str() ) {}
};

//--- MaxKrakatoa -------------------------------------------------------

MaxKrakatoa::MaxKrakatoa()
    : m_properties( true )
    , m_pblockOverrides( NULL )
    , m_bokehBlendInfluence( 0.0f )
    , m_viewNode( NULL )
    , m_doneInitRenderer( false ) {
    m_setDirtyBit = false;

    m_psRenderOpen.set_name( _T("Renderer::Open()") );
    m_psRenderClose.set_name( _T("Renderer::Close()") );
    m_psRender.set_name( _T("Renderer::Render()") );

    // We're holding some manual references, and need to set these to NULL initially.
    for( int i = 0; i < NumRefs(); ++i )
        SetReference( i, NULL );

    GetMaxKrakatoaDesc()->MakeAutoParamBlocks( this );

    initialize_renderglobalcontext( m_renderGlobalContext );
    m_renderGlobalContext.renderer = this;
    m_progressCallback = 0;

    // A default channel map
    channels::channel_map pcm;
    pcm.define_channel<vector3f>( _T("Position") );
    pcm.end_channel_definition();

    m_cacheValid.reset();
    m_particleCache.reset( pcm );
    m_apmVolumeCache.reset();

    // Back up the current setting of the globally accessible renderer
    MaxKrakatoa* backupRenderer = renderingMaxKrakatoa;
    // Avoid calling the InitRenderer() MAXScript function during ActiveShade
    // initialization, because this occurs before the function has been loaded.
    if( !in_active_shade_init() ) {
        try {
            // Set the globally accessible renderer so maxscript sees it during initialization.
            renderingMaxKrakatoa = this;
            mxs::expression( _T("FranticParticleRenderMXS.InitRenderer()") ).evaluate<Value*>();
            m_doneInitRenderer = true;
        } catch( std::exception& e ) {
            max3d::MsgBox( HANDLE_STD_EXCEPTION_MSG( e ),
                           _T("Krakatoa error in MAXScript function FranticParticleRenderMXS.InitRenderer()") );
        }
    }
    renderingMaxKrakatoa = backupRenderer;

    m_setDirtyBit = true;
}

MaxKrakatoa::~MaxKrakatoa() {}

int MaxKrakatoa::NumRefs() { return 1; }

RefTargetHandle MaxKrakatoa::GetReference( int i ) { return ( i == 0 ) ? m_pblockOverrides : NULL; }

void MaxKrakatoa::SetReference( int i, RefTargetHandle rtarg ) {
    if( i == 0 )
        m_pblockOverrides = (IParamBlock2*)rtarg;
}

int MaxKrakatoa::NumParamBlocks() { return 1; }

IParamBlock2* MaxKrakatoa::GetParamBlock( int i ) { return ( i == 0 ) ? m_pblockOverrides : NULL; }

IParamBlock2* MaxKrakatoa::GetParamBlockByID( short id ) {
    return ( id == m_pblockOverrides->ID() ) ? m_pblockOverrides : NULL;
}

void MaxKrakatoa::BaseClone( ReferenceTarget* from, ReferenceTarget* to, RemapDir& remap ) {
    Renderer::BaseClone( from, to, remap );

    ReplaceReference( 0, remap.CloneRef( from->GetReference( 0 ) ) );

    static_cast<MaxKrakatoa*>( to )->m_properties = static_cast<MaxKrakatoa*>( from )->m_properties;
    static_cast<MaxKrakatoa*>( to )->m_setDirtyBit = static_cast<MaxKrakatoa*>( from )->m_setDirtyBit;
}

ReferenceTarget* MaxKrakatoa::Clone( RemapDir& remap ) {
    MaxKrakatoa* cloned = new MaxKrakatoa();

    this->BaseClone( this, cloned, remap );

    return cloned;
}

const int PROPERTIES_CHUNK = 0x120;

IOResult MaxKrakatoa::Load( ILoad* iload ) {
    m_setDirtyBit = false;

    IOResult res;
    while( IO_OK == ( res = iload->OpenChunk() ) ) {
        switch( iload->CurChunkID() ) {
        case PROPERTIES_CHUNK:
            res = max3d::iload_read_strmap( iload, m_properties.storage() );
            break;
        }
        iload->CloseChunk();
        if( res != IO_OK )
            return res;
    }

    // Back up the current setting of the globally accessible renderer
    MaxKrakatoa* backupRenderer = renderingMaxKrakatoa;
    try {
        // Set the globally accessible renderer so maxscript sees it during initialization.
        renderingMaxKrakatoa = this;
        mxs::expression( _T("FranticParticleRenderMXS.PostLoadEvent()") ).evaluate<Value*>();
    } catch( std::exception& e ) {
        max3d::MsgBox( HANDLE_STD_EXCEPTION_MSG( e ),
                       _T("Error in MAXScript function FranticParticleRenderMXS.PostLoadEvent()") );
    }
    renderingMaxKrakatoa = backupRenderer;

    m_setDirtyBit = true;

    return IO_OK;
}

IOResult MaxKrakatoa::Save( ISave* isave ) {
    IOResult res = IO_OK;

    isave->BeginChunk( PROPERTIES_CHUNK );
    res = max3d::isave_write_strmap( isave, m_properties.storage() );
    isave->EndChunk();

    return res;
}

BaseInterface* MaxKrakatoa::GetInterface( Interface_ID id ) {
#if MAX_VERSION_MAJOR < 19
    if( id == IRENDERERREQUIREMENTS_INTERFACE_ID )
        return static_cast<IRendererRequirements*>( this );
#endif
    if( id == TAB_DIALOG_OBJECT_INTERFACE_ID )
        return static_cast<ITabDialogObject*>( this );
    return Renderer::GetInterface( id );
}

void* MaxKrakatoa::GetInterface( ULONG id ) {
#if MAX_VERSION_MAJOR < 19
    if( id == IRenderElementCompatible::IID )
        return static_cast<IRenderElementCompatible*>( this );
#endif
    return Renderer::GetInterface( id );
}

bool MaxKrakatoa::HasRequirement( Renderer::Requirement requirement ) {
    try {
        // If we're just saving the particles to a file, or we're outputing the data to an xml file,
        // then don't save the output.
        bool savingXML = m_properties.get( _T("RenderTarget") ) == _T("Save To XML");
        bool savingParticles = m_properties.get( _T("ParticleMode") ) == _T("Save Particles To File Sequence");

        bool usingFramebuffer = !savingXML && !savingParticles;
        switch( requirement ) {
#if MAX_VERSION_MAJOR < 19
        case kRequirement_NoPauseSupport:
            return true;
#endif
        // If we're only saving particle files, then don't save the render output
        case kRequirement_NoVFB:
        case kRequirement_DontSaveRenderOutput:
            return !usingFramebuffer;
            // Output 32 bit float if we're rendering an image, otherwise ask for 16 bit to conserve memory.
#if MAX_VERSION_MAJOR < 19
        case kRequirement8_Wants32bitFPOutput:
#else
        case kRequirement_Wants32bitFPOutput:
#endif
            return usingFramebuffer;
        default:
            return false;
        }
    } catch( std::exception& e ) {
        GetCOREInterface()->Log()->LogEntry( SYSLOG_ERROR, DISPLAY_DIALOG, _T("Error Getting Krakatoa Requirements"),
                                             HANDLE_STD_EXCEPTION_MSG( e ) );
        return false;
    }
}

BOOL MaxKrakatoa::IsCompatible( IRenderElement* pIRenderElement ) {
    return ( pIRenderElement->GetInterface( IMaxKrakatoaRenderElementID ) != NULL );
}

int MaxKrakatoa::AcceptTab( ITabDialogPluginTab* tab ) {
    if( tab->GetSuperClassID() == RADIOSITY_CLASS_ID )
        return TAB_DIALOG_REMOVE_TAB;
    if( tab->GetClassID() == Class_ID( 0x4fa95e9b, 0x9a26e66 ) ) // raytrace dialog
        return TAB_DIALOG_REMOVE_TAB;
    return TAB_DIALOG_ADD_TAB;
}

// Create the user interface object
RendParamDlg* MaxKrakatoa::CreateParamDialog( IRendParams* ir, BOOL isProgressDialog ) {
    return new MaxKrakatoaParamDlg( this, ir, isProgressDialog != 0 );
}

void MaxKrakatoa::AddTabToDialog( ITabbedDialog* dialog, ITabDialogPluginTab* tab ) {
    dialog->AddRollout( _T("Renderer"),             // Title
                        NULL,                       // Dialog Proc
                        MaxKrakatoaTab_CLASS_ID,    // Tab ID
                        tab,                        // Owner plugin
                        -1,                         // ControlID
                        215,                        // Width
                        0,                          // bottomMargin
                        0,                          // HelpID
                        ITabbedDialog::kSystemPage, // Order
                        -1                          // Image
    );
}

// Called by Max when Max is reset
void MaxKrakatoa::ResetParams() {
    m_setDirtyBit = false;
    m_doneInitRenderer = false;
    // We're holding some manual references, and need to reset these to NULL.
    for( int i = 0; i < NumRefs(); ++i )
        ReplaceReference( i, NULL );

    GetMaxKrakatoaDesc()->MakeAutoParamBlocks( this );

    initialize_renderglobalcontext( m_renderGlobalContext );
    m_renderGlobalContext.renderer = this;
    m_progressCallback = 0;
    m_properties.storage().clear();

    // Back up the current setting of the globally accessible renderer
    MaxKrakatoa* backupRenderer = renderingMaxKrakatoa;
    try {
        // Set the globally accessible renderer so maxscript sees it during initialization.
        renderingMaxKrakatoa = this;
        mxs::expression( _T("FranticParticleRenderMXS.InitRenderer()") ).evaluate<Value*>();
        m_doneInitRenderer = true;
    } catch( std::exception& e ) {
        max3d::MsgBox( HANDLE_STD_EXCEPTION_MSG( e ),
                       _T("Krakatoa error in MAXScript function FranticParticleRenderMXS.InitRenderer()") );
    }
    renderingMaxKrakatoa = backupRenderer;

    m_setDirtyBit = true;

    // TODO: Reset other parameters as they're added as well
}

int MaxKrakatoa::Open( INode* scene, INode* viewNode, ViewParams* viewParams, RendParams& rendParams, HWND /*hwnd*/,
                       DefaultLight* defaultLights, int defaultLightsSize
#if MAX_RELEASE >= 8900
                       ,
                       RendProgressCallback* /*prog*/
#endif
) {

    m_psRenderOpen.reset();
    m_psRenderClose.reset();
    m_psRender.reset();

    try {
        frantic::diagnostics::scoped_profile spOpen( m_psRenderOpen );

        if( !m_doneInitRenderer ) {
            throw std::runtime_error(
                "MaxKrakatoa::Open Internal Error: Attempting to open renderer without calling InitRenderer()" );
        }

        // Suspend undo, macro recorder, animation, auto backup, and maintain the "Save Required" flag
#if MAX_RELEASE >= 8900
        SuspendAll uberSuspend( TRUE, TRUE, TRUE, TRUE, TRUE, TRUE );
#elif MAX_RELEASE >= 8000
        UberSuspend uberSuspend( TRUE, TRUE, TRUE, TRUE, TRUE, TRUE );
#endif

        // Also enable it again in Renderer::Close()
        GetCOREInterface()->DisableSceneRedraw();

        m_fileOverwriteFlag = false;
        initialize_renderglobalcontext( m_renderGlobalContext );

        m_scene = scene;
        m_viewNode = viewNode;

        if( viewParams ) {
            m_useViewParams = true;
            m_viewParams = *viewParams;
        } else
            m_useViewParams = false;

        m_renderGlobalContext.renderer = this;
        m_renderGlobalContext.atmos = rendParams.atmos;
        m_renderGlobalContext.envMap = rendParams.envMap;
        m_renderGlobalContext.pToneOp = rendParams.pToneOp;
        m_renderGlobalContext.inMtlEdit = rendParams.inMtlEdit;
        m_renderGlobalContext.time = rendParams.firstFrame;
        m_renderGlobalContext.SetRenderElementMgr( rendParams.GetRenderElementMgr() );

        // The Max 'Hair and Fur' modifier is causing Krakatoa to crash on BroadcastNotification(NOTIFY_PRE_RENDERFRAME)
        // I can't see any way that I have done my RenderGlobalContext incorrectly, so I have instead chosen
        // to disable any 'Hair and Fur' render effects when rendering.
        Interface* ip = GetCOREInterface();
        if( ip->NumEffects() > 0 ) {
            for( int i = ip->NumEffects() - 1; i >= 0; --i ) {
                Effect* pEffect = ip->GetEffect( i );
                if( pEffect && pEffect->ClassID() == Class_ID( 0x3AE606B9, 0x141D4589 ) ) {
                    pEffect->SetAFlag( A_ATMOS_DISABLED );
                    FF_LOG( warning ) << _T("The Hair and Fur render effect is not supported. It has been disabled.")
                                      << std::endl;
                }
            }
        }

        // Disable Non-Krakatoa render elements.
        for( int i = 0, iEnd = m_renderGlobalContext.NRenderElements(); i < iEnd; ++i ) {
            IRenderElement* pRElem = m_renderGlobalContext.GetRenderElement( i );
            BaseInterface* pKrakatoElem = pRElem->GetInterface( IMaxKrakatoaRenderElementID );
            if( pRElem->IsEnabled() && !pKrakatoElem )
                pRElem->SetEnabled( FALSE );
        }

        if( !m_renderGlobalContext.inMtlEdit )
            BroadcastNotification( NOTIFY_PRE_RENDER, (void*)&rendParams );

        renderingMaxKrakatoa = this;

        // Call render begin on all the particle systems.  This is currently being done on all the nodes in the whole
        // scene, but we could specialize it in the future to just do it for the particle systems and matte objects we
        // need it for.
        std::set<ReferenceMaker*> doneRecursNodes;
        refmaker_call_recursive( scene, doneRecursNodes,
                                 render_begin_function( m_renderGlobalContext.time,
                                                        m_renderGlobalContext.inMtlEdit ? RENDERBEGIN_IN_MEDIT : 0 ) );

        TimeValue t = m_renderGlobalContext.time;
        bool bHideFrozen = ( rendParams.extraFlags & RENDER_HIDE_FROZEN ) != 0;

        if( defaultLights && defaultLightsSize > 0 ) {
            for( int i = 0; i < defaultLightsSize; ++i )
                m_defaultLights.push_back( defaultLights + i );
        }

        // Collect all the scene nodes which interest me.
        std::set<INode*> geomNodes;
        GetMatteSceneObjects( t, m_geometryNodes, bHideFrozen, geomNodes );
        GetPMESceneObjects( t, m_participatingMediumNodes, geomNodes );

        std::set<INode*> doneNodes;
        GetParticleSceneObjects( t, m_particleSystems, scene, bHideFrozen, geomNodes, doneNodes );
    } catch( const std::exception& e ) {
        GetCOREInterface()->EnableSceneRedraw();
        GetCOREInterface()->Log()->LogEntry( SYSLOG_ERROR, DISPLAY_DIALOG, _T("Error opening Krakatoa renderer"),
                                             HANDLE_STD_EXCEPTION_MSG( e ) );
        return 0;
    }

    return 1;
}

void MaxKrakatoa::Close( HWND /*hwnd*/
#if MAX_RELEASE >= 8900
                         ,
                         RendProgressCallback* /*prog*/
#endif
) {
    m_psRenderClose.enter();

    // Suspend undo, macro recorder, animation, auto backup, and maintain the "Save Required" flag
#if MAX_RELEASE >= 8900
    SuspendAll uberSuspend( TRUE, TRUE, TRUE, TRUE, TRUE, TRUE );
#elif MAX_RELEASE >= 8000
    UberSuspend uberSuspend( TRUE, TRUE, TRUE, TRUE, TRUE, TRUE );
#endif

    std::set<ReferenceMaker*> doneNodes;
    // Call render begin on all the particle systems
    refmaker_call_recursive( m_scene, doneNodes, render_end_function( m_renderGlobalContext.time ) );

    m_particleSystems.clear();
    m_geometryNodes.clear();
    m_participatingMediumNodes.clear();
    m_defaultLights.clear();

    m_renderGlobalContext.reset();

    if( !m_properties.get_bool( _T("CacheLastFrame") ) ) {
        if( !m_properties.get_bool( _T("EnableParticleCache") ) )
            InvalidateParticleCache();
        else if( !m_properties.get_bool( _T("EnableLightingCache") ) )
            InvalidateLightingCache();
    } else if( IsNetworkRenderServer() && !m_properties.get_bool( _T("UseCacheInWorkerMode") ) ) {
        InvalidateParticleCache();
    }

    // TODO: Don't always invalidate this cache, it may be useful.
    InvalidateAPMVolumeCache();

    m_fileOverwriteFlag = false;

    renderingMaxKrakatoa = 0;
    m_scene = 0;

    if( !m_renderGlobalContext.inMtlEdit )
        BroadcastNotification( NOTIFY_POST_RENDER );

    GetCOREInterface()->EnableSceneRedraw();

    m_psRenderClose.exit();

    FF_LOG( stats ) << m_psRenderOpen << _T("\n") << m_psRenderClose << _T("\n") << m_psRender << std::endl;
}

int MaxKrakatoa::Render( TimeValue time, Bitmap* tobm, FrameRendParams& frp, HWND /*hWnd*/, RendProgressCallback* prog,
                         ViewParams* viewParams ) {

#ifdef KRAKATOA_GLOBAL_PROFILING
    scoped_vs_profile theProfileSection;
#endif

    frantic::diagnostics::scoped_profile spRender( m_psRender );

    Interface* pI = GetCOREInterface();

    // Make sure the passed in data structures are a-ok
    if( !tobm ) {
        pI->Log()->LogEntry( SYSLOG_ERROR, DISPLAY_DIALOG, _T("Krakatoa Error"), _T("%s"),
                             _T("Render() function was passed a NULL framebuffer parameter.") );
        return 0;
    }

    // Suspend undo, macro recorder, animation, auto backup, and maintain the "Save Required" flag
#if MAX_RELEASE >= 8900
    SuspendAll uberSuspend( TRUE, TRUE, TRUE, TRUE, TRUE, TRUE );
#elif MAX_RELEASE >= 8000
    UberSuspend uberSuspend( TRUE, TRUE, TRUE, TRUE, TRUE, TRUE );
#endif

    int result = TRUE;

    FF_LOG( debug ) << _T("frp.frameDuration: ") << frp.frameDuration << _T("\nfrp.relSubFrameDuration: ")
                    << frp.relSubFrameDuration << std::endl;

    try {
        m_progressCallback = prog;
        if( m_progressCallback ) {
            m_progressCallback->SetTitle( _T("Getting Scene") );
            m_progressCallback->Progress( 0, 0 );
        }

        if( !tobm )
            throw std::runtime_error( "The bitmap supplied to the Render() call was NULL" );

        m_renderGlobalContext.time = time;

        FF_LOG( progress ) << _T("Rendering frame ") << ( (double)time / (double)GetTicksPerFrame() ) << std::endl;

        frantic::tstring particleMode = m_properties.get( _T("ParticleMode") );
        if( m_properties.get( _T("RenderTarget") ) == _T("Save To XML") ) // HACK
            particleMode = _T("Save To XML");

        if( !m_properties.get_bool( _T("EnableParticleCache") ) ||
            ( IsNetworkRenderServer() && !m_properties.get_bool( _T("UseCacheInWorkerMode") ) ) )
            InvalidateParticleCache();
        else if( !m_properties.get_bool( _T("EnableLightingCache") ) )
            InvalidateLightingCache();

        if( m_renderGlobalContext.inMtlEdit ) // Must check if we are in the material editor
            RenderSceneToMaterialEditor( time, tobm );
        else if( particleMode == _T("Render Scene Particles") || particleMode == _T("Light Scene Particles") )
            RenderSceneParticles( time, viewParams, tobm );
        else if( particleMode == _T("Save To XML") )
            RenderSceneToXML( time, viewParams );
        else if( particleMode == _T("Save Particles To File Sequence") )
            RenderSceneParticlesToFile( time, viewParams );
        else
            throw exception_stream() << "Unknown render mode: \"" << frantic::strings::to_string( particleMode )
                                     << "\"";

        FF_LOG( progress ) << _T("Finished rendering frame: ") << ( time / GetTicksPerFrame() ) << std::endl;

    } catch( const frantic::logging::progress_cancel_exception& ) {
        result = FALSE;
    } catch( const render_cancelled_exception& ) {
        result = FALSE;
    } catch( const tbb::captured_exception& e ) {
        if( strcmp( e.name(), typeid( frantic::logging::progress_cancel_exception ).name() ) != 0 ) {
            LogSys* log = GetCOREInterface()->Log();
            log->LogEntry( SYSLOG_ERROR, m_renderGlobalContext.inMtlEdit ? NO_DIALOG : DISPLAY_DIALOG,
                           _T("Krakatoa Error"), _T("%s"), HANDLE_STD_EXCEPTION_MSG( e ) );
        }
        result = FALSE;
    } catch( const std::exception& e ) {
        LogSys* log = GetCOREInterface()->Log();
        log->LogEntry( SYSLOG_ERROR, m_renderGlobalContext.inMtlEdit ? NO_DIALOG : DISPLAY_DIALOG, _T("Krakatoa Error"),
                       _T("%s"), HANDLE_STD_EXCEPTION_MSG( e ) );

        result = FALSE;
    } catch( ... ) {
        LogSys* log = GetCOREInterface()->Log();
        log->LogEntry( SYSLOG_ERROR, m_renderGlobalContext.inMtlEdit ? NO_DIALOG : DISPLAY_DIALOG, _T("Krakatoa Error"),
                       _T("Krakatoa has had a fatal error. Sorry about that, please report this to the developers ")
                       _T("via. support@thinkboxsoftware.com") );

        throw;
    }

    m_progressCallback = NULL;
    return result;
}

extern void GetLights( INode* sceneRoot, MaxKrakatoaRenderGlobalContext& rcontext );

void MaxKrakatoa::RenderSceneParticles( TimeValue t, ViewParams* viewParams, Bitmap* tobm ) {
    BroadcastNotification( NOTIFY_PRE_RENDERFRAME, (void*)&m_renderGlobalContext );

    // Update the atmosphere and environment maps.
    if( m_renderGlobalContext.envMap != NULL )
        frantic::max3d::shaders::update_map_for_shading( m_renderGlobalContext.envMap, t );

    if( m_renderGlobalContext.atmos != NULL ) {
        Interval garbage = FOREVER;
        m_renderGlobalContext.atmos->Update( t, garbage );
    }

    boost::shared_ptr<krakatoa::krakatoa_shader> pShader = GetShader();

    frantic::graphics::camera<float> renderCamera;
    frantic::graphics::transform4f renderCameraDerivative;
    bool isEnvCamera = false;

    SetupCamera( renderCamera, renderCameraDerivative, isEnvCamera, size2( tobm->Width(), tobm->Height() ), viewParams,
                 t );

    MaxKrakatoaSceneContextPtr pSceneContext( new MaxKrakatoaSceneContext );

    pSceneContext->set_camera( renderCamera );
    pSceneContext->set_is_environment_camera( isEnvCamera );
    pSceneContext->set_time( ticks_to_krakatoa_time( t ) );
    pSceneContext->set_render_global_context( &m_renderGlobalContext );

    channels::channel_map pcm;

    // Add the channels needed for the renderer to the channel_map
    GetRenderParticleChannels( pcm );

    // Add the channels needed for the shader to the channel_map
    pShader->define_required_channels( pcm );

    std::vector<krakatoa::render_element_interface_ptr> renderElements;

    // Collect render elements, adding the channels needed for each render element to the channel_map
    for( int i = 0, iEnd = m_renderGlobalContext.NRenderElements(); i < iEnd; ++i ) {
        IRenderElement* pElem = m_renderGlobalContext.GetRenderElement( i );
        if( !pElem || !pElem->IsEnabled() )
            continue;

        IMaxKrakatoaRenderElement* pMaxKrakatoaElem =
            static_cast<IMaxKrakatoaRenderElement*>( pElem->GetInterface( IMaxKrakatoaRenderElementID ) );

        if( pMaxKrakatoaElem ) {
            krakatoa::render_element_interface* pKrakatoaElem = pMaxKrakatoaElem->get_render_element( pSceneContext );
            if( pKrakatoaElem ) {
                if( krakatoa::particle_render_element_interface* pParticleElem =
                        dynamic_cast<krakatoa::particle_render_element_interface*>( pKrakatoaElem ) ) {
                    krakatoa::particle_render_element_interface_ptr pSharedParticleElem( pParticleElem );
                    pSharedParticleElem->add_required_channels( pcm );

                    // TODO: FIND THE CAMERA DERIVATIVE AND ADD IT TO THE VELOCITY ELEMENT (this works in SR/MY).
                    // add camera derivative for velocity element only
                    if( krakatoa::velocity_render_element* pVelocityElem =
                            dynamic_cast<krakatoa::velocity_render_element*>( pParticleElem ) )
                        pVelocityElem->set_world_to_camera_deriv( renderCameraDerivative );

                    renderElements.push_back( pSharedParticleElem );
                } else {
                    renderElements.push_back( krakatoa::render_element_interface_ptr( pKrakatoaElem ) );
                }
            }
        }
    }

    ApplyChannelDataTypeOverrides( pcm );

    pcm.end_channel_definition();

    FF_LOG( debug ) << _T("Using particle layout:\n") << pcm << std::endl;

    BroadcastNotification( NOTIFY_RENDER_PREEVAL, &t );

    { // Fill the apm volume cache
        max3d::logging::maxrender_progress_logger geomProgress(
            m_progressCallback, _T("Collecting ") +
                                    boost::lexical_cast<M_STD_STRING>( m_participatingMediumNodes.size() ) +
                                    _T(" Ambient Participating Medium Volumes") );
        CacheAPMVolumes( geomProgress, t );
    }

    boost::shared_ptr<frantic::logging::render_progress_logger> renderProgress(
        new frantic::max3d::logging::maxrender_progress_logger( m_progressCallback, _T("Rendering"), tobm ) );

    krakatoa::renderer_ptr krakRenderer = SetupRenderer( pSceneContext );

    krakRenderer->set_shader( pShader );
    krakRenderer->set_progress_logger( renderProgress );

    m_renderGlobalContext.reset( pSceneContext );
    m_renderGlobalContext.set_renderprogress_callback( m_progressCallback );
    m_renderGlobalContext.set_channel_map( pcm );

    // The call to reset is setting the time in ticks from the time on seconds stored in the scene_context which is
    // causing floating point error to screw me. This is a quick and dirty fix.
    m_renderGlobalContext.time = t;

    { // Get particle instances
        for( std::vector<KrakatoaParticleSource>::iterator it = m_particleSystems.begin(),
                                                           itEnd = m_particleSystems.end();
             it != itEnd; ++it )
            m_renderGlobalContext.add_particle_instance( it->GetNode() );
    }

    { // Get geometry instances This is used by raytracing texmaps via RenderGlobalContext::GetRenderInstance()
        for( std::vector<INode*>::iterator it = m_geometryNodes.begin(), itEnd = m_geometryNodes.end(); it != itEnd;
             ++it )
            m_renderGlobalContext.add_geometry_instance( *it );
    }

    { // Get light instances
        GetLights( m_scene, m_renderGlobalContext );
    }

    { // Fill the particle cache
#ifdef KRAKATOA_IO_PROFILING
        scoped_vs_profile theProfileSection;
#endif
        CacheParticles( pcm );

        FF_LOG( progress ) << _T("Rendering ") << m_particleCache.size() << _T(" particles.") << std::endl;
    }

    for( std::vector<krakatoa::render_element_interface_ptr>::iterator it = renderElements.begin(),
                                                                       itEnd = renderElements.end();
         it != itEnd; ++it )
        krakRenderer->add_render_element( *it );

    if( !m_properties.get_bool( _T("AdditiveMode") ) && !m_cacheValid[k_lightingFlag] ) {
        krakRenderer->precompute_lighting();
        m_cacheValid[k_lightingFlag] = true;
    }

    if( m_properties.get( _T("ParticleMode") ) != _T("Light Scene Particles") ) {
        framebuffer<color6f> renderFramebuffer( pSceneContext->get_camera().get_output_size() );

        // Set the rendering thread limit
        //  <= 0 means it will be determined automatically
        krakRenderer->set_rendering_thread_limit( m_properties.get_int( _T( "RenderThreadLimit" ) ) );
        krakRenderer->set_fram_buffer_available_memory_fraction(
            m_properties.get_float( _T( "FrameBufferAvailPhysMemoryFraction" ) ) );

        krakRenderer->render( renderFramebuffer );

        if( m_progressCallback ) {
            m_progressCallback->SetTitle( _T("Post-Processing Framebuffer") );
            m_progressCallback->Progress( 0, 0 );
        }

        // If requested, divide all the pixel values by their alphas.  The first use of this was for creating blended z
        // depth maps, where the division produces RGB values that actually represent the depth
        if( m_properties.get_bool( _T("PostDivideByAlpha") ) ) {
            std::vector<color6f>& data = renderFramebuffer.data();
            for( unsigned i = 0; i < data.size(); ++i ) {
                alpha3f a = data[i].a;
                if( a.ar != 0 )
                    data[i].c.r /= a.ar;
                if( a.ag != 0 )
                    data[i].c.g /= a.ag;
                if( a.ab != 0 )
                    data[i].c.b /= a.ab;
            }
        }

        if( m_progressCallback ) {
            m_progressCallback->SetTitle( _T("Returning Framebuffer") );
            m_progressCallback->Progress( 0, 0 );
        }

        renderFramebuffer.to_3dsMaxBitmap( tobm );
        tobm->RefreshWindow();
    }

    if( m_progressCallback ) {
        m_progressCallback->SetTitle( _T("Updating Scene") );
        m_progressCallback->Progress( 0, 0 );
    }

    BroadcastNotification( NOTIFY_POST_RENDERFRAME, (void*)&m_renderGlobalContext );

    if( m_progressCallback ) {
        m_progressCallback->SetTitle( _T("Done") );
        m_progressCallback->Progress( 0, 0 );
    }
}

struct save_op {
    static boost::array<M_STD_STRING, 3> channels;
    static color3f op( const color3f& emission, const color3f& lighting, float density ) {
        return emission + lighting * density;
    }
};

boost::array<M_STD_STRING, 3> save_op::channels = { _T("Emission"), _T("Lighting"), _T("Density") };

void MaxKrakatoa::RenderSceneParticlesToFile( TimeValue time, ViewParams* /*viewParams*/ ) {
    using namespace frantic::particles;
    using namespace frantic::particles::streams;

    BroadcastNotification( NOTIFY_PRE_RENDERFRAME, (void*)&m_renderGlobalContext );

    M_STD_STRING outputFile = m_properties.get( _T("ParticleFiles") );

    if( outputFile.empty() )
        throw std::runtime_error( "Krakatoa cannot save the particles - File not specified." );

    outputFile = files::replace_sequence_number( outputFile, time / GetTicksPerFrame() );

    if( files::file_exists( outputFile ) ) {
        if( m_properties.get_bool( _T("SkipExistingParticleFiles") ) ) {
            BroadcastNotification( NOTIFY_POST_RENDERFRAME, (void*)&m_renderGlobalContext );
            return;
        } else if( !IsNetworkRenderServer() && !m_fileOverwriteFlag ) {
            std::basic_stringstream<MCHAR> ss;
            ss << _T("Warning:  The file \"") << outputFile
               << _T("\" already exists. Do you want to overwrite this sequence?") << std::endl;
            if( IDNO == MessageBox( GetCOREInterface()->GetMAXHWnd(), ss.str().c_str(), _T("Krakatoa Warning"),
                                    MB_YESNO | MB_ICONQUESTION ) )
                throw render_cancelled_exception();
            m_fileOverwriteFlag = true;
        }
    }

    frantic::channels::channel_map savingPcm;
    {
        std::vector<M_STD_STRING> channels;
        frantic::strings::split( m_properties.get( _T("ActiveParticleChannels") ), channels, _T( ',' ) );

        if( channels.size() < 2 )
            throw std::runtime_error( "MaxKrakatoa::RenderSceneParticlesToFile() - Could not save particles to file. "
                                      "You must specify at least 1 channel to save." );

        for( std::size_t i = 2; i < channels.size(); i += 3 )
            savingPcm.define_channel( channels[i - 2], boost::lexical_cast<int>( channels[i] ),
                                      channel_data_type_from_string( channels[i - 1] ) );
        savingPcm.end_channel_definition( 1 );
    }

    frantic::graphics::camera<float> renderCamera;
    frantic::graphics::transform4f renderCameraDerivative;
    bool isEnvCamera = false;

    SetupCamera( renderCamera, renderCameraDerivative, isEnvCamera,
                 size2( GetCOREInterface()->GetRendWidth(), GetCOREInterface()->GetRendHeight() ), NULL, time );

    MaxKrakatoaSceneContextPtr pSceneContext( new MaxKrakatoaSceneContext );
    pSceneContext->set_camera( renderCamera );
    pSceneContext->set_time( ticks_to_krakatoa_time( time ) );
    pSceneContext->set_render_global_context( &m_renderGlobalContext );

    m_renderGlobalContext.reset( pSceneContext );
    m_renderGlobalContext.set_renderprogress_callback( m_progressCallback );
    m_renderGlobalContext.set_channel_map( savingPcm );

    // The call to reset is setting the time in ticks from the time on seconds stored in the scene_context which is
    // causing floating point error to screw me. This is a quick and dirty fix.
    m_renderGlobalContext.time = time;

    { // Get particle instances
        for( std::vector<KrakatoaParticleSource>::iterator it = m_particleSystems.begin(),
                                                           itEnd = m_particleSystems.end();
             it != itEnd; ++it )
            m_renderGlobalContext.add_particle_instance( it->GetNode() );
    }

    { // Get geometry instances
        for( std::vector<INode*>::iterator it = m_geometryNodes.begin(), itEnd = m_geometryNodes.end(); it != itEnd;
             ++it )
            m_renderGlobalContext.add_geometry_instance( *it );
    }

    { // Get lights
        GetLights( m_scene, m_renderGlobalContext );
    }

    boost::shared_ptr<particle_istream> pin;
    boost::shared_ptr<maxrender_progress_logger> particleProgress(
        new maxrender_progress_logger( m_progressCallback, _T("Updating Particles") ) );

    if( m_properties.get_bool( _T("SaveLightingAsEmission") ) && !m_properties.get_bool( _T("IgnoreSceneLights") ) ) {
        if( m_properties.get( _T("RenderingMethod") ) == _T("Voxel Rendering") )
            throw std::runtime_error( "MaxKrakatoa::RenderSceneParticlesToFile() - Cannot save particle lighting "
                                      "information in voxel mode. Please switch to Particle rendering mode." );

        boost::shared_ptr<krakatoa::krakatoa_shader> pShader( GetShader() );

        channels::channel_map pcm;

        // Add the channels needed for the renderer to the channel_map
        //  We need at least the channels that will affect the particle lighting.
        pcm.define_channel( _T("Position"), 3, frantic::channels::data_type_float32 );
        pcm.define_channel( _T("Lighting"), 3, frantic::channels::data_type_float16 );
        pcm.define_channel( _T("Color"), 3, frantic::channels::data_type_float16 );
        if( m_properties.get_bool( _T("UseFilterColor") ) )
            pcm.define_channel( _T("Absorption"), 3, frantic::channels::data_type_float16 );
        pcm.define_channel( _T("Density"), 1, frantic::channels::data_type_float16 );

        // Add the channels needed for the shader to the channel_map
        pShader->define_required_channels( pcm );

        // Add all the channels in the saving list
        pcm.union_channel_map( savingPcm );

        ApplyChannelDataTypeOverrides( pcm );

        pcm.end_channel_definition();

        FF_LOG( debug ) << _T("Using particle layout:\n") << pcm << std::endl;

        { // Fill the apm volume cache
            max3d::logging::maxrender_progress_logger geomProgress(
                m_progressCallback, _T("Collecting ") +
                                        boost::lexical_cast<M_STD_STRING>( m_participatingMediumNodes.size() ) +
                                        _T(" Ambient Participating Medium Volumes") );
            CacheAPMVolumes( geomProgress, time );
        }

        krakatoa::renderer_ptr krakRenderer = SetupRenderer( pSceneContext );

        krakRenderer->set_shader( pShader );
        krakRenderer->set_progress_logger( particleProgress );

        { // Fill the particle cache
            CacheParticles( pcm );

            FF_LOG( progress ) << _T("Rendering ") << m_particleCache.size() << _T(" particles.") << std::endl;
        }

        if( !m_properties.get_bool( _T("AdditiveMode") ) && !m_cacheValid[k_lightingFlag] ) {
            krakRenderer->precompute_lighting();
            m_cacheValid[k_lightingFlag] = true;
        }

        pin = make_particle_container_particle_istream( m_particleCache.begin(), m_particleCache.end(),
                                                        m_particleCache.get_channel_map(), _T("<particle cache>") );

        pin.reset( new apply_function_particle_istream<color3f( const color3f&, const color3f&, float )>(
            pin, &save_op::op, _T("Emission"), save_op::channels ) );
        pin->set_channel_map( savingPcm );
    } else {
        pin = GetSceneParticleStream( savingPcm, outputFile );
    }

    // Create default values for channels where zero is not appropriate, since we might have requested to save some
    // channels that didn't get meaningful values.
    {
        const frantic::channels::channel_map& curMap = pin->get_channel_map();

        boost::scoped_ptr<char> defaultParticle( new char[curMap.structure_size()] );
        memset( defaultParticle.get(), 0, curMap.structure_size() );
        if( curMap.has_channel( _T("Density") ) )
            curMap.get_cvt_accessor<float>( _T("Density") ).set( defaultParticle.get(), 1.f );
        if( curMap.has_channel( _T("Color") ) )
            curMap.get_cvt_accessor<color3f>( _T("Color") ).set( defaultParticle.get(), color3f( 1.f ) );

        // TODO: These should not be hard-coded, but set by the shader.
        if( curMap.has_channel( _T("Eccentricity") ) )
            curMap.get_cvt_accessor<float>( _T("Eccentricity") )
                .set( defaultParticle.get(), m_properties.get_float( _T("PhaseEccentricity") ) );
        if( curMap.has_channel( _T("SpecularPower") ) )
            curMap.get_cvt_accessor<float>( _T("SpecularPower") )
                .set( defaultParticle.get(), m_properties.get_float( _T("Lighting:Specular:SpecularPower") ) );
        if( curMap.has_channel( _T("SpecularLevel") ) )
            curMap.get_cvt_accessor<float>( _T("SpecularLevel") )
                .set( defaultParticle.get(), m_properties.get_float( _T("Lighting:Specular:Level") ) / 100.f );

        pin->set_default_particle( defaultParticle.get() );
    }

    // Stream the particles to disk.
    {
        int prtCompressionLevel = -1;
        if( m_properties.exists( _T("PRTCompressionLevel") ) ) // This is an experimental property, so it is optional.
            prtCompressionLevel = std::max( -1, std::min( 9, m_properties.get_int( _T("PRTCompressionLevel") ) ) );

        frantic::particles::particle_file_stream_factory_object factory;
        factory.set_coordinate_system( frantic::graphics::coordinate_system::right_handed_zup );
        factory.set_length_unit_in_meters( frantic::max3d::get_scale_to_meters() );
        factory.set_frame_rate( GetFrameRate(), 1 );

        boost::shared_ptr<frantic::particles::streams::particle_ostream> pout = factory.create_ostream(
            outputFile, pin->get_channel_map(), pin->get_channel_map(), pin->particle_count(), prtCompressionLevel );

        particleProgress->set_title( _T("Saving The Particles") );
        save_particle_stream( pin, pout, *particleProgress );
    }

    BroadcastNotification( NOTIFY_POST_RENDERFRAME, (void*)&m_renderGlobalContext );
}

void MaxKrakatoa::RenderSceneToXML( TimeValue /*time*/, ViewParams* /*viewParams*/ ) {}

extern void SetupLightsRecursive( std::vector<boost::shared_ptr<frantic::rendering::lights::lightinterface>>& outLights,
                                  INode* pNode, std::set<INode*>& doneNodes, TimeValue t,
                                  frantic::logging::progress_logger& progress, float motionInterval, float motionBias,
                                  bool saveAtten );

void MaxKrakatoa::RenderSceneToMaterialEditor( TimeValue /*t*/, Bitmap* tobm ) {
    tobm->Fill( 0, 0, 0, 0 );
    tobm->RefreshWindow();
}

#if MAX_VERSION_MAJOR >= 19
bool MaxKrakatoa::IsStopSupported() const { return false; }

void MaxKrakatoa::StopRendering() {}

Renderer::PauseSupport MaxKrakatoa::IsPauseSupported() const { return Renderer::PauseSupport::None; }

void MaxKrakatoa::PauseRendering() {}

void MaxKrakatoa::ResumeRendering() {}

bool MaxKrakatoa::CompatibleWithAnyRenderElement() const { return true; }

bool MaxKrakatoa::CompatibleWithRenderElement( IRenderElement& pIRenderElement ) const {
    return ( pIRenderElement.GetInterface( IMaxKrakatoaRenderElementID ) != NULL );
}

IInteractiveRender* MaxKrakatoa::GetIInteractiveRender() { return nullptr; }

void MaxKrakatoa::GetVendorInformation( MSTR& info ) const {
    // This is truncated if more than 32 characters.
    std::wstringstream ss;
    ss << _T( "Krakatoa v" );
    ss << FRANTIC_VERSION;
    info = MSTR( ss.str().c_str() );
}

void MaxKrakatoa::GetPlatformInformation( MSTR& info ) const {
    // TODO: Set this?
}
#endif

bool MaxKrakatoa::in_active_shade_init() const {
#if MAX_VERSION_MAJOR >= 21
    // Assume that ActiveShade initialization is taking place before the
    // NOTIFY_MXS_STARTUP callback is invoked.
    return !g_doneMxsStartup;
#else
    // We don't need to worry about this in earlier versions of 3ds Max.
    return false;
#endif
}
