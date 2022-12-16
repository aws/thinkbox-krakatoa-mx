// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0
#include "Objects\IMaxKrakatoaPRTSource.h"
#include "Objects\MaxKrakatoaPRTInterface.h"
#include <frantic\particles\prt_file_header.hpp>

#include <maxversion.h>

#include <krakatoa/max3d/IPRTParticleObjectExt.hpp>

#include <frantic/channels/channel_map.hpp>
#include <frantic/particles/particle_array.hpp>
#include <frantic/particles/particle_file_stream_factory.hpp>

#include <frantic/geometry/volume_collection.hpp>
#include <frantic/max3d/geometry/mesh.hpp>
#include <frantic/max3d/geopipe/named_selection_sets.hpp>
#include <frantic/max3d/maxscript/scripted_object_ref_impl.hpp>
#include <frantic/max3d/parameter_extraction.hpp>
#include <frantic/max3d/particles/modifier_utils.hpp>
#include <frantic/max3d/shaders/map_query.hpp>

#include <frantic/max3d/fpwrapper/fptimevalue.hpp>
#include <frantic/max3d/fpwrapper/mixin_wrapper.hpp>
#include <frantic/max3d/viewport/ParticleRenderItem.hpp>

#define MaxKrakatoaPRTLoader_CLASS_ID Class_ID( 0x6fc6ba13, 0x1b5eaf6a )
#define MaxKrakatoaPRTLoader_SCRIPTED_CLASS_ID Class_ID( 0x46b7f5c2, 0x4d2a17b6 )
#define MaxKrakatoaPRTLoader_INTERFACE_ID Interface_ID( 0x31b8ba1c, 0x9c7016b )
#define MaxKrakatoaPRTLoader_CLASS_NAME "KrakatoaPrtLoaderBase"

class MaxKrakatoaPRTLoader;
inline MaxKrakatoaPRTLoader* GetMaxKrakatoaPRTLoader( Object* obj ) {
    if( obj->ClassID() == MaxKrakatoaPRTLoader_SCRIPTED_CLASS_ID && obj->NumRefs() > 0 ) {
        ReferenceTarget* pDelegate = obj->GetReference( 0 );
        if( pDelegate->ClassID() == MaxKrakatoaPRTLoader_CLASS_ID )
            return reinterpret_cast<MaxKrakatoaPRTLoader*>( pDelegate );
    }

    return NULL;
}

enum { kCullingRefs, kNodeRefs, kOwnerRef };

namespace render {
enum RENDER_LOAD_PARTICLE_MODE {
    PARTICLELOAD_EVENLY_DISTRIBUTE = 1,
    PARTICLELOAD_FIRST_N,
    PARTICLELOAD_EVENLY_DISTRIBUTE_IDS,
};

enum COLORMODE { COLORMODE_FILE_COLOR = 1, COLORMODE_WIREFRAME, COLORMODE_MATERIAL };

enum DENSITYMODE {
    DENSITYMODE_FILE_DENSITY = 1,
    DENSITYMODE_MATERIAL_OPACITY,
    DENSITYMODE_MATERIAL_OPACITY_MULTIPLY,
    DENSITYMODE_GLOBAL
};
} // namespace render

namespace viewport {
enum RENDER_LOAD_PARTICLE_MODE {
    PARTICLELOAD_USE_RENDER_SETTING = 1,
    PARTICLELOAD_EVENLY_DISTRIBUTE,
    PARTICLELOAD_FIRST_N,
    PARTICLELOAD_EVENLY_DISTRIBUTE_IDS
};

enum COLORMODE { COLORMODE_USE_RENDER_SETTING = 1, COLORMODE_FILE_COLOR, COLORMODE_WIREFRAME, COLORMODE_MATERIAL };

enum DISPLAYCOUNTMODE {
    DISPLAYCOUNTMODE_NONE = 0,
    DISPLAYCOUNTMODE_DISK,
    DISPLAYCOUNTMODE_RENDER,
    DISPLAYCOUNTMODE_VIEWPORT
};

enum DISPLAYMODE {
    DISPLAYMODE_DOT1 = 1,
    DISPLAYMODE_DOT2,
    DISPLAYMODE_VELOCITY,
    DISPLAYMODE_NORMAL,
    DISPLAYMODE_TANGENT
};
} // namespace viewport

// Import these classes into the global namespace to reduce typing.
using frantic::max3d::maxscript::scripted_object_accessor;
using frantic::max3d::maxscript::scripted_object_ref;

class MaxKrakatoaPRTLoader : public GeomObject,
                             public IMaxKrakatoaPRTObject,
                             public IMaxKrakatoaParticleInterface,
                             public frantic::max3d::fpwrapper::FFMixinInterface<MaxKrakatoaPRTLoader>,
                             public krakatoa::max3d::IPRTParticleObjectExtOwner {
  private:
    struct particle_cache_t {
        frantic::particles::particle_array particles;
        Interval iv;
        Box3 boundBox;

        bool hasVectors;

        particle_cache_t()
            : iv( NEVER )
            , hasVectors( false ) {}
    };

    Interval m_validInterval;
    Interval m_cullingInterval;

    bool m_inRenderMode;

    frantic::particles::particle_array
        m_cachedObjectParticles; // Stores object space particles which have been cached before modifiers, xforms, etc.
    std::map<INode*, particle_cache_t>
        m_cachedWorldParticles; // Stores world space particles which have been cached after modifiers, xforms, etc.

    boost::shared_ptr<frantic::geometry::volume_collection> m_cachedCullingVolume;

    boost::shared_ptr<IParticleObjectExt> m_iparticleobjectWrapper;

    // Channel map and accessors for the (node-cache) viewport particle layout
    frantic::channels::channel_map m_channelMap;
    frantic::channels::channel_accessor<frantic::graphics::vector3f> m_posAccessor;
    frantic::channels::channel_cvt_accessor<frantic::graphics::vector3f> m_velocityAccessor;
    frantic::channels::channel_cvt_accessor<frantic::graphics::vector3f> m_normalAccessor;
    frantic::channels::channel_cvt_accessor<frantic::graphics::vector3f> m_tangentAccessor;
    frantic::channels::channel_cvt_accessor<frantic::graphics::color3f> m_colorAccessor;

    int m_lastErrorCode;             // Indicates the error status of the last file I/O
    M_STD_STRING m_lastErrorMessage; // This is the error message corresponding to the error code.

    IParamBlock2* m_refBlock;     // ParamBlock that holds various references to culling nodes.
    scripted_object_ref m_parent; // Allows access to the reference messages and paramblocks of the scripted superclass

    // Render parameters
    scripted_object_accessor<bool> m_enabledInRender;
    scripted_object_accessor<int> m_renderLoadMode;
    scripted_object_accessor<float> m_percentRenderer;
    scripted_object_accessor<bool> m_useRenderLimit;
    scripted_object_accessor<float> m_renderLimit;
    scripted_object_accessor<int> m_particleColorSource;
    scripted_object_accessor<bool> m_resetDensities;
    scripted_object_accessor<bool> m_copyDensitiesToMapChannel;
    scripted_object_accessor<int> m_densityMapChannel;

    // Viewport parameters
    scripted_object_accessor<bool> m_enabledInView;
    scripted_object_accessor<int> m_viewLoadMode;
    scripted_object_accessor<float> m_percentViewport;
    scripted_object_accessor<bool> m_useViewportLimit;
    scripted_object_accessor<float> m_viewportLimit;
    scripted_object_accessor<int> m_showCountInViewport;
    scripted_object_accessor<int> m_viewportParticleColorSource;
    scripted_object_accessor<int> m_viewportParticleDisplayMode;
    scripted_object_accessor<float> m_scaleNormals;
    scripted_object_accessor<bool> m_ignoreMaterial;

    // Playback parameters
    scripted_object_accessor<bool> m_enablePlaybackGraph;
    scripted_object_accessor<float> m_playbackGraphTime;
    scripted_object_accessor<int> m_frameOffset;
    scripted_object_accessor<bool> m_limitToRange;
    scripted_object_accessor<int> m_rangeStartFrame;
    scripted_object_accessor<int> m_rangeEndFrame;
    scripted_object_accessor<bool> m_loadSingleFrame;
    scripted_object_accessor<int> m_beforeRangeMode;
    scripted_object_accessor<int> m_afterRangeMode;
    scripted_object_accessor<M_STD_STRING> m_fileList;
    scripted_object_accessor<int> m_fileListFlags;
    scripted_object_accessor<bool> m_keepVelocityChannel;
    scripted_object_accessor<bool> m_interpolateFrames;

    // Icon parameters
    scripted_object_accessor<bool> m_showIcon;
    scripted_object_accessor<float> m_iconSize;
    scripted_object_accessor<bool> m_showBoundingBox;

    // Object DeformBBox params
    scripted_object_accessor<float> m_deformBoxX;
    scripted_object_accessor<float> m_deformBoxY;
    scripted_object_accessor<float> m_deformBoxZ;

    // World space modification parameters
    scripted_object_accessor<bool> m_useTransform;
    scripted_object_accessor<bool> m_useCullingGizmo;
    scripted_object_accessor<bool> m_invertCullingGizmo;
    scripted_object_accessor<M_STD_STRING> m_cullingNamedSelectionSet;
    scripted_object_accessor<bool> m_useThresholdCulling;
    scripted_object_accessor<float> m_cullingThreshold;
    scripted_object_accessor<bool> m_getCullingSurfaceNormals;

    //////////////////////////////// Realflow legacy load hack //////////////////////////////////////

    scripted_object_accessor<bool> m_useLegacyRealflowBinLoading;

    /////////////////////////////////////////////////////////////////////////////////////////////////

#if MAX_VERSION_MAJOR >= 17
    bool m_initialized;
#endif

  public:
    MaxKrakatoaPRTLoader();
    virtual ~MaxKrakatoaPRTLoader();

    // From IMaxKrakatoaPRTObject
    virtual particle_istream_ptr CreateStream( INode* pNode, Interval& outValidity,
                                               frantic::max3d::particles::IMaxKrakatoaPRTEvalContextPtr pEvalContext );
    virtual void GetStreamNativeChannels( INode* pNode, TimeValue t, frantic::channels::channel_map& outChannelMap );

    // From IPRTParticleObjectExtOwner
    virtual particle_istream_ptr
    create_particle_stream( INode* pNode, Interval& outValidity,
                            frantic::max3d::particles::IMaxKrakatoaPRTEvalContextPtr pEvalContext );

    // From GeomObject
    BOOL IsRenderable() { return FALSE; }
    Mesh* GetRenderMesh( TimeValue /*t*/, INode* /*inode*/, View& /*view*/, BOOL& /*needDelete*/ ) { return NULL; }

    // From Object
    Interval ObjectValidity( TimeValue /*t*/ ) { return m_validInterval; }
    ObjectState Eval( TimeValue /*t*/ ) { return ObjectState( this ); }
    virtual BOOL CanConvertToType( Class_ID obtype );
    virtual Object* ConvertToType( TimeValue t, Class_ID obtype );

    void GetDeformBBox( TimeValue t, Box3& box, Matrix3* tm = NULL, BOOL useSel = FALSE );

    // From BaseObject
    CreateMouseCallBack* GetCreateMouseCallBack() { return NULL; }

#if MAX_VERSION_MAJOR >= 24
    const MCHAR* GetObjectName( bool localized )
#elif MAX_VERSION_MAJOR >= 15
    const MCHAR* GetObjectName()
#else
    MCHAR* GetObjectName()
#endif
    {
        return _T( MaxKrakatoaPRTLoader_CLASS_NAME );
    }

#if MAX_VERSION_MAJOR >= 17
    // Max 2015+ uses a new viewport system.

    // Update particles as the node is transformed

    void WSStateInvalidate();

    virtual unsigned long GetObjectDisplayRequirement() const;

    virtual bool PrepareDisplay( const MaxSDK::Graphics::UpdateDisplayContext& prepareDisplayContext );

    virtual bool UpdatePerNodeItems( const MaxSDK::Graphics::UpdateDisplayContext& updateDisplayContext,
                                     MaxSDK::Graphics::UpdateNodeContext& nodeContext,
                                     MaxSDK::Graphics::IRenderItemContainer& targetRenderItemContainer );

    virtual bool UpdatePerViewItems( const MaxSDK::Graphics::UpdateDisplayContext& updateDisplayContext,
                                     MaxSDK::Graphics::UpdateNodeContext& nodeContext,
                                     MaxSDK::Graphics::UpdateViewContext& viewContext,
                                     MaxSDK::Graphics::IRenderItemContainer& targetRenderItemContainer );

    MaxSDK::Graphics::CustomRenderItemHandle m_markerRenderItem;
    MaxSDK::Graphics::CustomRenderItemHandle m_iconRenderItem;
    MaxSDK::Graphics::CustomRenderItemHandle m_boundsRenderItem;

    frantic::max3d::viewport::render_type GetCurrentDisplayMode();

    virtual void GenerateParticlesRenderItem( TimeValue& t, Box3& boundingBox,
                                              MaxSDK::Graphics::UpdateNodeContext& nodeContext );
    virtual void UpdateParticlesRenderItem( TimeValue& t, Box3& boundingBox, INode* nodeContext, bool doGPUUpload );
    virtual void GenerateIconRenderItem( TimeValue& t );
    virtual void GenerateBoundingBoxRenderItem( TimeValue& t, Box3& boundingBox );

    virtual void addPointsForDots( std::vector<Point3, std::allocator<Point3>>& pointVector,
                                   frantic::particles::particle_array& pc );
    virtual void addPointsForVelocity( std::vector<Point3, std::allocator<Point3>>& pointVector,
                                       frantic::particles::particle_array& pc );
    virtual void addPointsForNormals( std::vector<Point3, std::allocator<Point3>>& pointVector,
                                      frantic::particles::particle_array& pc, TimeValue& t );
    virtual void addPointsForTangents( std::vector<Point3, std::allocator<Point3>>& pointVector,
                                       frantic::particles::particle_array& pc, TimeValue& t );
    virtual void addColorData( std::vector<Point4, std::allocator<Point4>>& colorVector,
                               frantic::particles::particle_array& pc, int times = 1 );
#else
    // virtual bool RequiresSupportForLegacyDisplayMode() const;
#endif

    void GetWorldBoundBox( TimeValue t, INode* inode, ViewExp* vpt, Box3& box );
    void GetLocalBoundBox( TimeValue t, INode* inode, ViewExp* vpt, Box3& box );
    int Display( TimeValue t, INode* inode, ViewExp* pView, int flags );
    int HitTest( TimeValue t, INode* inode, int type, int crossing, int flags, IPoint2* p, ViewExp* vpt );

    // From ReferenceMaker
    RefResult NotifyRefChanged( const Interval& changeInt, RefTargetHandle hTarget, PartID& partID, RefMessage message,
                                BOOL propagate );

#if MAX_VERSION_MAJOR < 17
    virtual RefResult NotifyRefChanged( Interval changeInt, RefTargetHandle hTarget, PartID& partID,
                                        RefMessage message ) {
        return this->NotifyRefChanged( changeInt, hTarget, partID, message, TRUE );
    }
#endif

    int NumRefs() { return 1; }
    RefTargetHandle GetReference( int i ) { return ( i == 0 ) ? m_refBlock : NULL; }
    void SetReference( int i, RefTargetHandle rtarg ) {
        if( i == 0 )
            m_refBlock = static_cast<IParamBlock2*>( rtarg );
    }

    // From ReferenceTarget
    RefTargetHandle Clone( RemapDir& remap );

    // From Animatable
    void DeleteThis() { delete this; }
    Class_ID ClassID() { return MaxKrakatoaPRTLoader_CLASS_ID; }
    SClass_ID SuperClassID() { return GEOMOBJECT_CLASS_ID; }

    int NumParamBlocks() { return 1; }
    IParamBlock2* GetParamBlock( int i ) { return ( i == 0 ) ? m_refBlock : NULL; }
    IParamBlock2* GetParamBlockByID( short id ) { return ( m_refBlock->ID() == id ) ? m_refBlock : NULL; }

    int NumInterfaces();
    void* GetInterface( int i );
    BaseInterface* GetInterface( Interface_ID id );

    int RenderBegin( TimeValue t, ULONG flags );
    int RenderEnd( TimeValue t );

    virtual void EnumAuxFiles( AssetEnumCallback& assetEnum, DWORD flags = FILE_ENUM_ALL );

    //-----------------------------------------
    // MaxKrakatoaPRTLoader specific functions
    //-----------------------------------------
    void set_scripted_owner( ReferenceTarget* rtarg );

    inline void DeleteWSCache( INode* pNode ) {
        if( pNode != NULL ) {
            m_cachedWorldParticles.erase( pNode );
            if( m_cachedWorldParticles.size() == 0 ) { // Hack to prevent large MaxScript memory leak
                m_validInterval = NEVER;
                m_cachedObjectParticles.clear();
            }
        }
    }

    void InvalidateWSCache( INode* pNode ) {
        if( pNode != NULL )
            m_cachedWorldParticles[pNode].iv = NEVER;
    }

    void InvalidateWorldSpaceCache() {
        for( std::map<INode*, particle_cache_t>::iterator it = m_cachedWorldParticles.begin();
             it != m_cachedWorldParticles.end(); ++it )
            it->second.iv = NEVER;
    }

    void InvalidateObjectSpaceCache() {
        m_validInterval = NEVER;
        InvalidateWorldSpaceCache();
    }

    bool EnabledInRender();
    bool DoesModifyParticles();

    void GetParticleFilenames( int frame, std::vector<M_STD_STRING>& outFilenames, int mask );
    void AssertNotLoadingFrom( const M_STD_STRING& file );

    M_STD_STRING GetLastErrorMessage() { return m_lastErrorMessage; }

    int GetFileParticleCount( FPTimeValue t );
    int GetViewParticleCount( FPTimeValue t );
    int GetRenderParticleCount( FPTimeValue t );

    boost::shared_ptr<frantic::geometry::volume_collection> GetCullingVolume( TimeValue t );

    boost::shared_ptr<frantic::particles::streams::particle_istream>
    GetFileParticleStream( const frantic::channels::channel_map& pcm, TimeValue t, int mask = 0x02,
                           bool throwOnError = true );

    boost::shared_ptr<frantic::particles::streams::particle_istream>
    GetObjectSpaceParticleStream( boost::shared_ptr<frantic::particles::streams::particle_istream> pin,
                                  float percentage, boost::int64_t limit,
                                  // bool loadEvenly,
                                  render::RENDER_LOAD_PARTICLE_MODE loadMode, TimeValue t, TimeValue timeStep );

    /*boost::shared_ptr<frantic::particles::streams::particle_istream> GetWorldSpaceParticleStream(
            boost::shared_ptr<frantic::particles::streams::particle_istream> pin,
            INode* pNode,
            boost::shared_ptr<frantic::geometry::volume_collection> pCullingVol,
            frantic::max3d::shaders::renderInformation& renderInfo,
            bool renderMode,
            TimeValue t,
            TimeValue timeStep
    );

    boost::shared_ptr<frantic::particles::streams::particle_istream> GetShadedParticleStream(
            boost::shared_ptr<frantic::particles::streams::particle_istream> pin,
            INode* pNode,
            render::COLORMODE cMode,
            bool doDensityShading,
            frantic::max3d::shaders::renderInformation renderInfo,
            bool renderMode,
            TimeValue t
    );

    boost::shared_ptr<frantic::particles::streams::particle_istream> GetRenderParticleStream(
            const frantic::channels::channel_map& pcm,
            INode* pNode,
            bool doShading,
            bool doDensityShading,
            frantic::max3d::shaders::renderInformation renderInfo,
            TimeValue t,
            TimeValue timeStep);*/

    boost::shared_ptr<frantic::particles::streams::particle_istream>
    GetWorldSpaceParticleStream( boost::shared_ptr<frantic::particles::streams::particle_istream> pin, INode* pNode,
                                 TimeValue t, Interval& inoutValidity,
                                 frantic::max3d::particles::IMaxKrakatoaPRTEvalContextPtr pEvalContext,
                                 boost::shared_ptr<frantic::geometry::volume_collection> pCullingVol,
                                 // frantic::max3d::shaders::renderInformation& renderInfo,
                                 bool renderMode //,
                                                 // TimeValue t,
                                 // TimeValue timeStep
    );

    boost::shared_ptr<frantic::particles::streams::particle_istream>
    GetShadedParticleStream( boost::shared_ptr<frantic::particles::streams::particle_istream> pin, INode* pNode,
                             TimeValue t, Interval& inoutValidity,
                             frantic::max3d::particles::IMaxKrakatoaPRTEvalContextPtr pEvalContext,
                             // render::COLORMODE cMode,
                             // bool doDensityShading,
                             // frantic::max3d::shaders::renderInformation renderInfo,
                             bool renderMode );

    boost::shared_ptr<frantic::particles::streams::particle_istream> GetRenderParticleStream(
		//const frantic::channels::channel_map& pcm, 
		INode* pNode,
		TimeValue t,
		Interval& inoutValidity,
		frantic::max3d::particles::IMaxKrakatoaPRTEvalContextPtr pEvalContext//, 
		/*bool doShading, 
		bool doDensityShading, 
		frantic::max3d::shaders::renderInformation renderInfo, 
		TimeValue t, 
		TimeValue timeStep*/);

    /**
     * This function will collect the channels found in the files specified in the
     * PRT Loader's UI. This will not do any frame substitution.
     */
    void get_render_channels( INode* pNode, frantic::channels::channel_map& outMap );

    void RecacheCullingVolume( TimeValue t );
    void UpdateCullingNodes( TimeValue t );

  private:
    void CacheParticlesAtTime( TimeValue t, INode* inode, ViewExp* pView );

    // Helper gets the current TM of the particles.
    Matrix3 GetParticleTM( TimeValue t, INode* inode ) {
        if( !inode || !m_useTransform.at_time( t ) )
            return Matrix3( 1 );
        return inode->GetObjTMBeforeWSM( t );
    }

    struct viewport_data {
        frantic::tstring m_scalarChannel; // Which channel are we displaying
        frantic::tstring m_vectorChannel; // Which channel are we displaying
        frantic::tstring m_colorChannel;  // Which channel are we displaying
        // display_mode::option m_displayMode; // What sort of visualization do we want

        int m_res[3];
        float m_spacing[3];
        int m_reduce;
        // spacing_mode::option m_spacingMode;

        bool m_normalizeVectors;
        float m_vectorScale;

        float m_scalarMin, m_scalarMax;
        float m_dotSize;

        bool m_drawBounds;

        frantic::channels::channel_cvt_accessor<float> m_floatAccessor;
        frantic::channels::channel_cvt_accessor<frantic::graphics::vector3f> m_vecAccessor;
        frantic::channels::channel_cvt_accessor<frantic::graphics::color3f> m_colorAccessor;
        frantic::channels::channel_cvt_accessor<float> m_scalarColorAccessor;

        Mesh* m_pIcon; // For use in legacy viewports.

#if MAX_VERSION_MAJOR >= 17
        MaxSDK::Graphics::RenderItemHandleArray m_hIconMeshes; // For use in Nitrous viewports
#endif
        Matrix3 m_iconTM;

        viewport_data()
            : m_pIcon( NULL )
            , m_iconTM( TRUE ) {
            // m_displayMode = display_mode::kDisplayNone;
            // m_spacingMode = spacing_mode::kSpacingConstant;
            m_res[0] = m_res[1] = m_res[2] = 10;
            m_scalarMin = 0.f;
            m_scalarMax = std::numeric_limits<float>::infinity();
            m_dotSize = 3.f;
            m_drawBounds = false;
        }
    } m_viewportData;
};
