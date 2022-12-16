// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0

#pragma once

#include "MaxKrakatoaParticleSources.h"
#include "MaxKrakatoaRenderGlobalContext.h"
#include "MaxKrakatoaSceneContext.h"

#include <frantic/channels/channel_map.hpp>
#include <frantic/diagnostics/profiling_section.hpp>
#include <frantic/geometry/volume_collection.hpp>
#include <frantic/graphics/camera.hpp>
#include <frantic/misc/property_container.hpp>
#include <frantic/particles/particle_array.hpp>
#include <frantic/particles/particle_deque.hpp>

#include <frantic/max3d/logging/max_progress_logger.hpp>
#include <frantic/max3d/particles/max3d_particle_streams.hpp>

#include <krakatoa/renderer.hpp>

#include <boost/cstdint.hpp>

#include <tbb/task_scheduler_init.h>

#pragma warning( push, 3 )
#pragma warning( disable : 4100 )
#include <ITabDialog.h>
#pragma warning( pop )

extern TCHAR* GetString( int id );
extern HINSTANCE hInstance;

#define MaxKrakatoa_CLASS_ID Class_ID( 0xb836c39a, 0xe829b319 )
#define MaxKrakatoaTab_CLASS_ID Class_ID( 0x25773d05, 0x1ee72d0b )
extern ClassDesc2* GetMaxKrakatoaDesc();

#ifdef _WIN64
typedef frantic::particles::particle_array ParticleContainerType;
#else
typedef frantic::particles::particle_deque ParticleContainerType;
#endif

enum { kColorOverrideTexmap, kAbsorptionOverrideTexmap, kEmissionOverrideTexmap, kDensityOverrideTexmap };

class MaxKrakatoa : public Renderer
#if MAX_RELEASE >= 8000    // Only do this for the max 8 build
#if MAX_VERSION_MAJOR < 19 // In Max 2017+ these are just typedefs of Renderer
    ,
                    public IRendererRequirements,
                    public IRenderElementCompatible
#endif
    ,
                    public ITabDialogObject
#endif
{
    // tbb::task_scheduler_init m_tbbScheduler;

    IParamBlock2* m_pblockOverrides;
    // RenderGlobalContext m_renderGlobalContext;
    MaxKrakatoaRenderGlobalContext m_renderGlobalContext;
    RendProgressCallback* m_progressCallback;

    // Properties that are used during a render
    INode* m_scene;
    INode* m_viewNode;
    ViewParams m_viewParams;
    bool m_useViewParams;
    bool m_fileOverwriteFlag;

    // Collected scene objects from the Open call.
    std::vector<KrakatoaParticleSource> m_particleSystems;
    std::vector<INode*> m_geometryNodes; // TODO: replace this with simply setting these in the scene_context object
                                         // (which gets passed into the renderer)
    std::vector<INode*> m_participatingMediumNodes;
    std::vector<DefaultLight*> m_defaultLights;

    ParticleContainerType m_particleCache;
    boost::shared_ptr<frantic::geometry::volume_collection> m_apmVolumeCache;
    // boost::shared_ptr<MaxKrakatoaMatteGeometryCollection> m_matteGeometryCache;

    std::bitset<4> m_cacheValid;
    enum { k_particleFlag, k_lightingFlag, k_apmFlag, k_matteFlag };

    // All the renderer properties
    // NOTE: frantic::properties::property_container is a deprecated class, consider changing it to
    // frantic::channels::property_map
    frantic::properties::property_container m_properties;
    bool m_setDirtyBit;

    float m_bokehBlendInfluence;

    frantic::diagnostics::profiling_section m_psRenderOpen;
    frantic::diagnostics::profiling_section m_psRenderClose;
    frantic::diagnostics::profiling_section m_psRender;

    // Have we called the MAXScript InitRenderer() function?
    bool m_doneInitRenderer;

  public:
    //////////////////////////////////////////////
    // Constructors and I/O
    //////////////////////////////////////////////

    MaxKrakatoa();
    virtual ~MaxKrakatoa();

    virtual void BaseClone( ReferenceTarget* from, ReferenceTarget* to, RemapDir& remap );
    virtual ReferenceTarget* Clone( RemapDir& remap );

    IOResult Load( ILoad* iload );
    IOResult Save( ISave* isave );

    //////////////////////////////////////////////
    // Utility functions
    //////////////////////////////////////////////

    void CacheParticles( const frantic::channels::channel_map& desiredChannels );
    // void CacheMatteGeometry(frantic::logging::progress_logger& progressLog, TimeValue t);
    void CacheAPMVolumes( frantic::logging::progress_logger& progressLog, TimeValue t );

    void SetupCamera( frantic::graphics::camera<float>& outCamera, frantic::graphics::transform4f& outDerivTM,
                      bool& outIsEnvCamera, frantic::graphics2d::size2, ViewParams* vp, TimeValue t );
    void SetupLights( std::vector<boost::shared_ptr<frantic::rendering::lights::lightinterface>>& outLights,
                      TimeValue t, frantic::logging::progress_logger& progress, float motionInterval = 0.5f,
                      float motionBias = 0.f );
    krakatoa::renderer_ptr SetupRenderer( MaxKrakatoaSceneContextPtr sceneContext );

    // frantic::rendering::krakatoa_phase_function* GetPhaseFunction( const frantic::channels::channel_map& pcm ) const;
    boost::shared_ptr<krakatoa::krakatoa_shader> GetShader() const;

  public:
    //////////////////////////////////////////////
    // Required functions
    //////////////////////////////////////////////

    virtual int NumRefs();
    virtual RefTargetHandle GetReference( int i );
    virtual void SetReference( int i, RefTargetHandle rtarg );

    virtual int NumParamBlocks();
    virtual IParamBlock2* GetParamBlock( int i );
    virtual IParamBlock2* GetParamBlockByID( short id );

    RefResult NotifyRefChanged( const Interval& /*changeInt*/, RefTargetHandle /*hTarget*/, PartID& /*partID*/,
                                RefMessage /*message*/, BOOL /*propagate*/ ) {
        return REF_SUCCEED;
    }

#if MAX_VERSION_MAJOR < 17
    virtual RefResult NotifyRefChanged( Interval changeInt, RefTargetHandle hTarget, PartID& partID,
                                        RefMessage message ) {
        return this->NotifyRefChanged( changeInt, hTarget, partID, message, TRUE );
    }
#endif

#if MAX_VERSION_MAJOR >= 19
    virtual bool IsStopSupported() const override;
    virtual void StopRendering() override;
    virtual PauseSupport IsPauseSupported() const override;
    virtual void PauseRendering() override;
    virtual void ResumeRendering() override;
    virtual bool CompatibleWithAnyRenderElement() const override;
    virtual bool CompatibleWithRenderElement( IRenderElement& pIRenderElement ) const override;
    virtual IInteractiveRender* GetIInteractiveRender() override;
    virtual void GetVendorInformation( MSTR& info ) const override;
    virtual void GetPlatformInformation( MSTR& info ) const override;
#endif

    void ResetParams();
    void DeleteThis() { delete this; }
    Class_ID ClassID() { return MaxKrakatoa_CLASS_ID; }
#if MAX_VERSION_MAJOR >= 24
    void GetClassName( TSTR& s, bool localized )
#else
    void GetClassName( TSTR& s )
#endif
    {
        s = GetMaxKrakatoaDesc()->ClassName();
    }

    BaseInterface* GetInterface( Interface_ID id );
    void* GetInterface( ULONG id );

    // From IRendererRequirements
    bool HasRequirement( Renderer::Requirement requirement );

    // From IRenderElementCompatible
    virtual BOOL IsCompatible( IRenderElement* pIRenderElement );

    // From ITabDialogObject
    virtual int AcceptTab( ITabDialogPluginTab* tab );
    virtual void AddTabToDialog( ITabbedDialog* dialog, ITabDialogPluginTab* tab );

    // Create the use interface dialog
    RendParamDlg* CreateParamDialog( IRendParams* ir, BOOL prog );

    //////////////////////////////////////////////
    // Other Stuff
    //////////////////////////////////////////////

    frantic::tstring GetRenderOutputFiles( TimeValue time );
    frantic::tstring GetShadowOutputFiles( TimeValue t );

    typedef boost::shared_ptr<frantic::particles::streams::particle_istream> particle_istream_ptr;

    particle_istream_ptr GetSceneParticleStream( const frantic::channels::channel_map& pcm,
                                                 const frantic::tstring& savingFile );
    particle_istream_ptr ApplyChannelOverrides( boost::shared_ptr<frantic::particles::streams::particle_istream> );
    void RetrieveParticles( ParticleContainerType& outParticles );

    // TODO: Replace with scripted objects.
    void GetMatteSceneObjects( TimeValue time, std::vector<INode*>& matteObjects, bool bHideFrozen,
                               std::set<INode*>& doneNodes );
    void GetPMESceneObjects( TimeValue time, std::vector<INode*>& geomObjects, std::set<INode*>& doneNodes );
    void GetParticleSceneObjects( TimeValue time, std::vector<KrakatoaParticleSource>& particleObjects, INode* pScene,
                                  bool bHideFrozen, std::set<INode*>& geomNodes, std::set<INode*>& doneNodes );

    float GetCacheSize() {
        return m_particleCache.size() * m_particleCache.get_channel_map().structure_size() / 1048576.f;
    }
    void InvalidateParticleCache() {
        m_cacheValid[k_particleFlag] = false;
        m_cacheValid[k_lightingFlag] = false;
        m_particleCache.clear();
    }
    void InvalidateLightingCache() {
        m_cacheValid[k_lightingFlag] = false;

        const frantic::channels::channel_map& pcm = m_particleCache.get_channel_map();
        if( pcm.has_channel( _T("Lighting") ) ) {
            frantic::channels::channel_cvt_accessor<frantic::graphics::color3f> lighting =
                pcm.get_cvt_accessor<frantic::graphics::color3f>( _T("Lighting") );
            for( ParticleContainerType::iterator p = m_particleCache.begin(), end = m_particleCache.end(); p != end;
                 ++p )
                lighting.set( *p, frantic::graphics::color3f( 0 ) );
        }
    }
    // void InvalidateMatteObjectCache(){ m_cacheValid[k_matteFlag] = false; m_matteGeometryCache.reset(); }
    void InvalidateAPMVolumeCache() {
        m_cacheValid[k_apmFlag] = false;
        m_apmVolumeCache.reset();
    }

    void SaveMatteObjectsToFileSequence( const frantic::tstring& filename, const std::vector<INode*>& inodes,
                                         int startFrame, int endFrame );

    void ApplyChannelDataTypeOverrides( frantic::channels::channel_map& inoutMap );

    void GetRenderParticleChannels( frantic::channels::channel_map& outPcm );
    void GetCachedParticleChannels( frantic::channels::channel_map& outPcm );
    size_t GetCachedParticleCount() { return m_particleCache.size(); }

    // Functions that actually do the render
    int Open( INode* scene, INode* vnode, ViewParams* viewPar, RendParams& rpar, HWND hwnd,
              DefaultLight* defaultLights = NULL, int numDefLights = 0
#if MAX_RELEASE >= 8900
              ,
              RendProgressCallback* prog = NULL
#endif
    );
    int Render( TimeValue time, Bitmap* tobm, FrameRendParams& frp, HWND hwnd, RendProgressCallback* prog,
                ViewParams* viewPar );
    void Close( HWND hwnd
#if MAX_RELEASE >= 8900
                ,
                RendProgressCallback* prog = NULL
#endif
    );

    // TODO: Name these better ...
    void RenderSceneParticles( TimeValue time, ViewParams* viewParams, Bitmap* tobm );
    void RenderSceneToMaterialEditor( TimeValue time, Bitmap* tobm );
    void RenderSceneToXML( TimeValue time, ViewParams* viewParams );
    void RenderSceneParticlesToFile( TimeValue time, ViewParams* viewParams );

    // Property access
    void add_property( const frantic::tstring& name ) { m_properties.add( name ); }

    void set_property( const frantic::tstring& name, const frantic::tstring& value ) {
        m_properties.set( name, value );
        if( m_setDirtyBit )
            SetSaveRequiredFlag();
    }
    void set_property( const frantic::tstring& name, int value ) {
        m_properties.set( name, value );
        if( m_setDirtyBit )
            SetSaveRequiredFlag();
    }
    void set_property( const frantic::tstring& name, float value ) {
        m_properties.set( name, value );
        if( m_setDirtyBit )
            SetSaveRequiredFlag();
    }
    void set_property( const frantic::tstring& name, bool value ) {
        m_properties.set( name, value );
        if( m_setDirtyBit )
            SetSaveRequiredFlag();
    }

    void erase_property( const frantic::tstring& name ) {
        m_properties.erase( name );
        if( m_setDirtyBit )
            SetSaveRequiredFlag();
    }

    bool is_valid_particle_node( INode* node, TimeValue t );
    bool is_valid_matte_node( INode* node, TimeValue t );

  private:
    template <class T>
    struct property_helper {};
    template <>
    struct property_helper<bool> {
        static bool get( const frantic::properties::property_container& props, const frantic::tstring& propName ) {
            return props.get_bool( propName );
        }
    };
    template <>
    struct property_helper<int> {
        static int get( const frantic::properties::property_container& props, const frantic::tstring& propName ) {
            return props.get_int( propName );
        }
    };
    template <>
    struct property_helper<float> {
        static float get( const frantic::properties::property_container& props, const frantic::tstring& propName ) {
            return props.get_float( propName );
        }
    };
    template <>
    struct property_helper<frantic::tstring> {
        static frantic::tstring get( const frantic::properties::property_container& props,
                                     const frantic::tstring& propName ) {
            return props.get( propName );
        }
    };

  public:
    template <class T>
    T get_property( const frantic::tstring& name ) const {
        return property_helper<T>::get( m_properties, name );
    }

    const frantic::properties::property_container& properties() const {
        // NOTE: frantic::properties::property_container is a deprecated class, consider changing it to
        // frantic::channels::property_map
        return m_properties;
    }

  private:
    /**
     * Return true if ActiveShade may be being initialized now (early during
     * 3ds Max startup), and false otherwise.
     *
     * Based on our testing, we assume that MaxKrakatoa instances created
     * during such ActiveShade initialization will not be used to render.
     */
    bool in_active_shade_init() const;
};

// Function which returns the global render plugin (or throws an exception if it's not set)
MaxKrakatoa* GetMaxKrakatoa();
