// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0
#include "stdafx.h"

#include <limits>

#include <frantic/graphics/color3f.hpp>
#include <frantic/math/utils.hpp>
#include <frantic/max3d/geometry/mesh.hpp>
#include <frantic/max3d/geopipe/named_selection_sets.hpp>
#include <frantic/max3d/max_utility.hpp>
#include <frantic/max3d/units.hpp>
#include <frantic/max3d/viewport/BoxRenderItem.hpp>
#include <frantic/max3d/viewport/DecoratedMeshEdgeRenderItem.hpp>

#include <maxversion.h>
#if MAX_VERSION_MAJOR >= 17
#include <Graphics/Utilities/MeshEdgeRenderItem.h>
#endif

#include "MaxKrakatoa.h"
#include "MaxKrakatoaChannelModifier.h"
// #include "MaxKrakatoaNodeMonitor.h"
#include "Objects\MaxKrakatoaPRTLoader.h"

#include <krakatoa/max3d/IPRTMaterial.hpp>
#include <krakatoa/max3d/IPRTModifier.hpp>

#include <frantic/files/filename_sequence.hpp>
#include <frantic/particles/particle_classes.hpp>

#include <frantic/particles/streams/apply_function_particle_istream.hpp>
#include <frantic/particles/streams/channel_operation_particle_istream.hpp>
#include <frantic/particles/streams/concatenated_parallel_particle_istream.hpp>
#include <frantic/particles/streams/concatenated_particle_istream.hpp>
#include <frantic/particles/streams/density_scale_particle_istream.hpp>
#include <frantic/particles/streams/empty_particle_istream.hpp>
#include <frantic/particles/streams/fractional_by_id_particle_istream.hpp>
#include <frantic/particles/streams/fractional_particle_istream.hpp>
#include <frantic/particles/streams/instancing_particle_istream.hpp>
#include <frantic/particles/streams/particle_array_particle_istream.hpp>
#include <frantic/particles/streams/particle_container_particle_istream.hpp>
#include <frantic/particles/streams/selection_culled_particle_istream.hpp>
#include <frantic/particles/streams/set_channel_particle_istream.hpp>
#include <frantic/particles/streams/surface_culled_particle_istream.hpp>
#include <frantic/particles/streams/time_interpolation_particle_istream.hpp>
#include <frantic/particles/streams/transformed_particle_istream.hpp>
#include <frantic/particles/streams/volume_culled_particle_istream.hpp>

#include <frantic/max3d/AutoViewExp.hpp>
#include <frantic/max3d/logging/status_panel_progress_logger.hpp>
#include <frantic/max3d/particles/streams/deformed_particle_istream.hpp>
#include <frantic/max3d/particles/streams/material_affected_particle_istream.hpp>
#include <frantic/max3d/particles/streams/ticks_to_seconds_particle_istream.hpp>
#include <frantic/max3d/time.hpp>
#include <frantic/max3d/viewport/ParticleRenderItem.hpp>

#include <boost/bind.hpp>
#include <boost/filesystem/convenience.hpp>
#include <boost/filesystem/path.hpp>

#include <AssetManagement/IAssetAccessor.h>

#include <krakatoa/max3d/IPRTModifier.hpp>

namespace krakatoa {
namespace max3d {

extern IParticleObjectExt* MakeIParticleObjectExtWrapper( frantic::max3d::particles::IMaxKrakatoaPRTObjectPtr prtObj );

extern boost::shared_ptr<frantic::particles::streams::particle_istream>
ApplyStdMaterial( boost::shared_ptr<frantic::particles::streams::particle_istream> pin, Mtl* pMtl,
                  const frantic::max3d::shaders::renderInformation& renderInfo, bool doShadeColor,
                  bool doShadeAbsorption, bool doShadeEmission, bool doShadeDensity, TimeValue t );

} // namespace max3d
} // namespace krakatoa

using namespace frantic;
using namespace frantic::max3d;
using namespace frantic::channels;

using boost::shared_ptr;
using frantic::geometry::trimesh3;
using frantic::geometry::volume_collection;
using frantic::graphics::color3f;
using frantic::graphics::transform4f;
using frantic::graphics::vector3f;
using frantic::particles::particle_array;
using frantic::particles::particle_file_istream_factory;
using frantic::particles::streams::particle_istream;

extern HINSTANCE hInstance;
extern Mesh* GetPRTLoaderIconMesh();
#if MAX_VERSION_MAJOR >= 25
extern MaxSDK::SharedMeshPtr GetPRTLoaderIconMeshShared();
#endif

namespace clamp_mode {
enum clamp_mode_enum { hold = 1, blank };
}

namespace enabled_mode {
enum enabled_mode_enum { viewport = ( 1 << 0 ), render = ( 1 << 1 ) };
}

struct ops {
    static vector3f add_velocity_to_pos( const vector3f& pos, const vector3f& velocity, float scale ) {
        return pos + ( scale * velocity );
    }

    static vector3f scale_vector( const vector3f& v, float scale ) { return scale * v; }

    static vector3f uvw_from_density( float density ) { return vector3f( density ); }

    static float square_density( float density ) { return density * density; }

    static color3f clamp_color( const color3f& color ) {
        return color3f( frantic::math::clamp( color.r, 0.f, 1.f ), frantic::math::clamp( color.g, 0.f, 1.f ),
                        frantic::math::clamp( color.b, 0.f, 1.f ) );
    }
};

class MaxKrakatoaPRTLoaderDesc : public ClassDesc2 {
  public:
    int IsPublic() { return FALSE; }
    void* Create( BOOL /*loading*/ ) { return new MaxKrakatoaPRTLoader(); }
    const TCHAR* ClassName() { return _T( MaxKrakatoaPRTLoader_CLASS_NAME ); }
#if MAX_VERSION_MAJOR >= 24
    const TCHAR* NonLocalizedClassName() { return _T( MaxKrakatoaPRTLoader_CLASS_NAME ); }
#endif
    SClass_ID SuperClassID() { return GEOMOBJECT_CLASS_ID; }
    Class_ID ClassID() { return MaxKrakatoaPRTLoader_CLASS_ID; }
    const TCHAR* Category() { return _T(""); }

    const TCHAR* InternalName() {
        return _T( MaxKrakatoaPRTLoader_CLASS_NAME );
    }                                           // returns fixed parsable name (scripter-visible name)
    HINSTANCE HInstance() { return hInstance; } // returns owning module handle
};

ClassDesc2* GetMaxKrakatoaPRTLoaderDesc() {
    static MaxKrakatoaPRTLoaderDesc theDesc;
    return &theDesc;
}

ParamBlockDesc2 prtLoadPBDesc( 0,                // BlockID
                               _T("References"), //
                               0,                // ResourceID
                               GetMaxKrakatoaPRTLoaderDesc(),
                               P_AUTO_CONSTRUCT, // Flags
                               0,                // Block's GetReference() index

                               kCullingRefs, _T("CullingRefs"), TYPE_INODE_TAB, 0, P_VARIABLE_SIZE, 0, p_end, kNodeRefs,
                               _T("NodeRefs"), TYPE_REFTARG_TAB, 0, P_VARIABLE_SIZE | P_TRANSIENT, 0, p_end, kOwnerRef,
                               _T("OwnerRef"), TYPE_REFTARG, 0, 0, p_end, p_end );

MaxKrakatoaPRTLoader::MaxKrakatoaPRTLoader() {
    m_refBlock = NULL;
    m_inRenderMode = false;

    GetMaxKrakatoaPRTLoaderDesc()->MakeAutoParamBlocks( this );

    if( !m_refBlock )
        throw std::runtime_error( "MaxKrakatoaPRTLoader - unable to create parameter block" );

    m_channelMap.define_channel<vector3f>( _T("Position") );
    m_channelMap.define_channel<vector3f>( _T("Velocity") );
    m_channelMap.define_channel<vector3f>( _T("Normal") );
    m_channelMap.define_channel<vector3f>( _T("Tangent") );
    m_channelMap.define_channel<color3f>( _T("Color") );
    m_channelMap.end_channel_definition();

    m_posAccessor = m_channelMap.get_accessor<vector3f>( _T("Position") );
    m_velocityAccessor = m_channelMap.get_cvt_accessor<vector3f>( _T("Velocity") );
    m_normalAccessor = m_channelMap.get_cvt_accessor<vector3f>( _T("Normal") );
    m_tangentAccessor = m_channelMap.get_cvt_accessor<vector3f>( _T("Tangent") );
    m_colorAccessor = m_channelMap.get_cvt_accessor<color3f>( _T("Color") );

    m_validInterval = NEVER;
    m_cullingInterval = NEVER;

    m_cachedObjectParticles.reset( m_channelMap );
    m_iparticleobjectWrapper = krakatoa::max3d::CreatePRTParticleObjectExt( this );

    // Render load parameters
    m_enabledInRender = m_parent.get_accessor<bool>( _T("enabledInRender") );
    m_renderLoadMode = m_parent.get_accessor<int>( _T("renderLoadMode") );
    m_percentRenderer = m_parent.get_accessor<float>( _T("percentRenderer") );
    m_useRenderLimit = m_parent.get_accessor<bool>( _T("useRenderLimit") );
    m_renderLimit = m_parent.get_accessor<float>( _T("renderLimit") );
    m_particleColorSource = m_parent.get_accessor<int>( _T("particleColorSource") );
    m_resetDensities = m_parent.get_accessor<bool>( _T("resetDensities") );
    m_copyDensitiesToMapChannel = m_parent.get_accessor<bool>( _T("copyDensitiesToMapChannel") );
    m_densityMapChannel = m_parent.get_accessor<int>( _T("densityMapChannel") );

    // Viewport load parameters
    m_enabledInView = m_parent.get_accessor<bool>( _T("enabledInView") );
    m_viewLoadMode = m_parent.get_accessor<int>( _T("viewLoadMode") );
    m_percentViewport = m_parent.get_accessor<float>( _T("percentViewport") );
    m_useViewportLimit = m_parent.get_accessor<bool>( _T("useViewportLimit") );
    m_viewportLimit = m_parent.get_accessor<float>( _T("viewportLimit") );
    m_showCountInViewport = m_parent.get_accessor<int>( _T("showCountInViewport") );
    m_viewportParticleColorSource = m_parent.get_accessor<int>( _T("viewportParticleColorSource") );
    m_viewportParticleDisplayMode = m_parent.get_accessor<int>( _T("viewportParticleDisplayMode") );
    m_scaleNormals = m_parent.get_accessor<float>( _T("scaleNormals") );
    m_ignoreMaterial = m_parent.get_accessor<bool>( _T("ignoreMaterial") );

    // Frame and file loading parameters
    m_enablePlaybackGraph = m_parent.get_accessor<bool>( _T("enablePlaybackGraph") );
    m_playbackGraphTime = m_parent.get_accessor<float>( _T("playbackGraphTime") );
    m_frameOffset = m_parent.get_accessor<int>( _T("frameOffset") );
    m_limitToRange = m_parent.get_accessor<bool>( _T("limitToRange") );
    m_rangeStartFrame = m_parent.get_accessor<int>( _T("rangeStartFrame") );
    m_rangeEndFrame = m_parent.get_accessor<int>( _T("rangeEndFrame") );
    m_loadSingleFrame = m_parent.get_accessor<bool>( _T("loadSingleFrame") );
    m_beforeRangeMode = m_parent.get_accessor<int>( _T("beforeRangeBehavior") );
    m_afterRangeMode = m_parent.get_accessor<int>( _T("afterRangeBehavior") );
    m_fileList = m_parent.get_accessor<M_STD_STRING>( _T("fileList") );
    m_fileListFlags = m_parent.get_accessor<int>( _T("fileListFlags") );
    m_keepVelocityChannel = m_parent.get_accessor<bool>( _T("keepVelocityChannel") );
    m_interpolateFrames = m_parent.get_accessor<bool>( _T("interpolateFrames") );

    // Icon and gizmo parameters
    m_showIcon = m_parent.get_accessor<bool>( _T("showIcon") );
    m_iconSize = m_parent.get_accessor<float>( _T("iconSize") );
    m_showBoundingBox = m_parent.get_accessor<bool>( _T("showBoundingBox") );
    m_deformBoxX = m_parent.get_accessor<float>( _T("gizmoBoxX") );
    m_deformBoxY = m_parent.get_accessor<float>( _T("gizmoBoxY") );
    m_deformBoxZ = m_parent.get_accessor<float>( _T("gizmoBoxZ") );
    m_useTransform = m_parent.get_accessor<bool>( _T("useTransform") );

    // Culling parameters
    m_cullingNamedSelectionSet = m_parent.get_accessor<M_STD_STRING>( _T("cullingNamedSelectionSet") );
    m_useCullingGizmo = m_parent.get_accessor<bool>( _T("useCullingGizmo") );
    m_invertCullingGizmo = m_parent.get_accessor<bool>( _T("invertCullingGizmo") );
    m_useThresholdCulling = m_parent.get_accessor<bool>( _T("useThresholdCulling") );
    m_cullingThreshold = m_parent.get_accessor<float>( _T("cullingThreshold") );
    m_getCullingSurfaceNormals = m_parent.get_accessor<bool>( _T("getCullingSurfaceNormals") );

    //////////////////////////////////////////// Realflow legacy load hack ////////////////////////////////
    m_useLegacyRealflowBinLoading = m_parent.get_accessor<bool>( _T("useLegacyRealflowBinLoading") );
    ///////////////////////////////////////////////////////////////////////////////////////////////////////

    FFCreateDescriptor c( this, MaxKrakatoaPRTLoader_INTERFACE_ID, _T("KrakatoaPreviewObjectInterface"),
                          GetMaxKrakatoaPRTLoaderDesc() );
    c.add_function( &MaxKrakatoaPRTLoader::InvalidateObjectSpaceCache, _T("InvalidateObjectSpaceCache") );
    c.add_function( &MaxKrakatoaPRTLoader::InvalidateWorldSpaceCache, _T("InvalidateWorldSpaceCache") );
    c.add_function( &MaxKrakatoaPRTLoader::UpdateCullingNodes, _T("UpdateCullingNodes") );
    c.add_function( &MaxKrakatoaPRTLoader::GetFileParticleCount, _T("GetParticleCount") );
    c.add_function( &MaxKrakatoaPRTLoader::GetViewParticleCount, _T("GetParticleCountView") );
    c.add_function( &MaxKrakatoaPRTLoader::GetRenderParticleCount, _T("GetParticleCountRender") );
    c.add_property( &MaxKrakatoaPRTLoader::GetLastErrorMessage, _T("LastErrorMessage") );
    c.add_function( &MaxKrakatoaPRTLoader::set_scripted_owner, _T("SetScriptedOwner"), _T("ScriptedPluginInstance") );

    // mprintf("MaxKrakatoaPRTLoader() - Constructing @ 0x%x\n", this);

#if MAX_VERSION_MAJOR >= 17
    m_initialized = false;
#endif
}

MaxKrakatoaPRTLoader::~MaxKrakatoaPRTLoader() {
    // mprintf("MaxKrakatoaPRTLoader() - Destructing @ 0x%x!\n", this);
    DeleteAllRefsFromMe();
}

RefTargetHandle MaxKrakatoaPRTLoader::Clone( RemapDir& remap ) {
    MaxKrakatoaPRTLoader* newob = new MaxKrakatoaPRTLoader();

    for( int i = 0; i < NumRefs(); ++i )
        newob->ReplaceReference( i, remap.CloneRef( GetReference( i ) ) );

    BaseClone( this, newob, remap );
    return ( newob );
}

int MaxKrakatoaPRTLoader::RenderBegin( TimeValue /*t*/, ULONG /*flags*/ ) {
    m_inRenderMode = true;

    return TRUE;
}

int MaxKrakatoaPRTLoader::RenderEnd( TimeValue /*t*/ ) {
    m_inRenderMode = false;

    return TRUE;
}

class PathAccessor : public IAssetAccessor {
    IParamBlock2* m_pblock;
    ParamID m_id;
    int m_index;

  public:
    PathAccessor( IParamBlock2* pb, ParamID id, int index = 0 )
        : m_pblock( pb )
        , m_id( id )
        , m_index( index ) {}

    virtual MaxSDK::AssetManagement::AssetUser GetAsset() const { return m_pblock->GetAssetUser( m_id, 0, m_index ); }

    virtual bool SetAsset( const MaxSDK::AssetManagement::AssetUser& aNewAssetUser ) {
        BOOL result = m_pblock->SetValue( m_id, 0, aNewAssetUser, m_index );
        return result != FALSE;
    }

    // asset client information
    virtual MaxSDK::AssetManagement::AssetType GetAssetType() const { return MaxSDK::AssetManagement::kOtherAsset; }

    virtual const MCHAR* GetAssetDesc() const { return _T("Particle Files"); }

    virtual const MCHAR* GetAssetClientDesc() const { return _T("PRT Loader"); }
};

void MaxKrakatoaPRTLoader::EnumAuxFiles( AssetEnumCallback& assetEnum, DWORD flags ) {
    using namespace MaxSDK::AssetManagement;

    RefTargetHandle rtarg = m_parent.get_target();
    if( rtarg != NULL ) {
        for( int i = 0, iEnd = rtarg->NumParamBlocks(); i < iEnd; ++i ) {
            IParamBlock2* pb = rtarg->GetParamBlock( i );
            if( !pb )
                continue;

            // pb->EnumAuxFiles( assetEnum, flags );

            for( int j = 0, jEnd = pb->NumParams(); j < jEnd; ++j ) {
                ParamID id = pb->IndextoID( j );
                int type = pb->GetParameterType( id );

                if( type == TYPE_FILENAME || type == TYPE_FILENAME_TAB ) {
                    // int count = (type & TYPE_TAB) ? pb->Count( id ) : 1;
                    // if( count > 1 && (flags & FILE_ENUM_ACCESSOR_INTERFACE) )
                    // static_cast<IEnumAuxAssetsCallback&>(assetEnum).DeclareGroup( "" );

                    for( int k = 0, kEnd = ( type & TYPE_TAB ) ? pb->Count( id ) : 1; k < kEnd; ++k ) {
                        PathAccessor acc( pb, id, k );

                        if( flags & FILE_ENUM_ACCESSOR_INTERFACE ) {
                            static_cast<IEnumAuxAssetsCallback&>( assetEnum ).DeclareAsset( acc );
                        } else {
                            AssetUser asset = acc.GetAsset();

                            MaxSDK::Util::Path filePath;
                            asset.GetFullFilePath( filePath );

                            if( ( flags & FILE_ENUM_MISSING_ONLY ) == 0 ||
                                !boost::filesystem::exists( filePath.GetCStr() ) )
                                assetEnum.RecordAsset( asset );
                        }
                    }
                }
            }
        }
    }

    GeomObject::EnumAuxFiles( assetEnum, flags );
}

void MaxKrakatoaPRTLoader::set_scripted_owner( ReferenceTarget* rtarg ) { m_parent.attach_to( rtarg ); }

particle_istream_ptr
MaxKrakatoaPRTLoader::CreateStream( INode* pNode, Interval& outValidity,
                                    frantic::max3d::particles::IMaxKrakatoaPRTEvalContextPtr pEvalContext ) {
    TimeValue t = pEvalContext->GetTime();

    if( m_inRenderMode )
        return GetRenderParticleStream( pNode, t, outValidity, pEvalContext );

    outValidity = FOREVER;

    using namespace frantic::particles::streams;

    if( !m_parent.get_target() ) {
        FF_LOG( warning ) << _T("\"") << pNode->GetName()
                          << _T("\" was not correctly bound to its scripted object. This may not be an error if your ")
                             _T("scene uses Afterburn 4.0b")
                          << std::endl;

        return boost::shared_ptr<particle_istream>(
            new frantic::particles::streams::empty_particle_istream( pEvalContext->GetDefaultChannels() ) );
    }

    TimeValue timeStep = 20;

    if( !this->m_enabledInView.at_time( t ) )
        return boost::shared_ptr<particle_istream>( new empty_particle_istream( pEvalContext->GetDefaultChannels() ) );

    float percentage = m_percentViewport.at_time( t ) * m_percentRenderer.at_time( t ) * 0.0001f;
    boost::int64_t limit = m_useViewportLimit.at_time( t )
                               ? static_cast<boost::int64_t>( m_viewportLimit.at_time( t ) * 1000 )
                               : std::numeric_limits<boost::int64_t>::max();
    /*bool loadEvenly =
            (m_viewLoadMode.at_time(t) == viewport::PARTICLELOAD_EVENLY_DISTRIBUTE) ||
            (m_viewLoadMode.at_time(t) == viewport::PARTICLELOAD_USE_RENDER_SETTING && m_renderLoadMode.at_time(t) ==
       render::PARTICLELOAD_EVENLY_DISTRIBUTE);*/
    ::viewport::RENDER_LOAD_PARTICLE_MODE viewLoadMode =
        static_cast<::viewport::RENDER_LOAD_PARTICLE_MODE>( (int)m_viewLoadMode.at_time( t ) );
    render::RENDER_LOAD_PARTICLE_MODE renderLoadMode;
    if( viewLoadMode == ::viewport::PARTICLELOAD_USE_RENDER_SETTING )
        renderLoadMode = static_cast<render::RENDER_LOAD_PARTICLE_MODE>( (int)m_renderLoadMode.at_time( t ) );
    else
        renderLoadMode = static_cast<render::RENDER_LOAD_PARTICLE_MODE>( viewLoadMode - 1 );

    boost::shared_ptr<volume_collection> pCullingVolume = GetCullingVolume( t );

    boost::shared_ptr<particle_istream> pin;
    pin = GetFileParticleStream( pEvalContext->GetDefaultChannels(), t, 0x02, true );
    pin = GetObjectSpaceParticleStream( pin, percentage, limit, renderLoadMode, t, timeStep );
    pin = GetWorldSpaceParticleStream( pin, pNode, t, outValidity, pEvalContext, pCullingVolume, false );

    // Account for the density change due to loading only a fraction of the particles.
    if( percentage > 0 && percentage < 1 )
        pin.reset( new density_scale_particle_istream( pin, 1.f / percentage ) );

    // render::COLORMODE cMode = static_cast<render::COLORMODE>( (int)m_particleColorSource.at_time(t) );
    pin = GetShadedParticleStream( pin, pNode, t, outValidity, pEvalContext, false );

    return pin;
}

void MaxKrakatoaPRTLoader::GetStreamNativeChannels( INode* pNode, TimeValue /*t*/,
                                                    frantic::channels::channel_map& outChannelMap ) {
    this->get_render_channels( pNode, outChannelMap );
}

particle_istream_ptr
MaxKrakatoaPRTLoader::create_particle_stream( INode* pNode, Interval& outValidity,
                                              frantic::max3d::particles::IMaxKrakatoaPRTEvalContextPtr pEvalContext ) {
    return this->CreateStream( pNode, outValidity, pEvalContext );
}

int MaxKrakatoaPRTLoader::NumInterfaces() { return 4; }
void* MaxKrakatoaPRTLoader::GetInterface( int i ) {
    if( i == 0 )
        return GetInterface( MaxKrakatoaPRTLoader_INTERFACE_ID );
    else if( i == 1 )
        return GetInterface( MAXKRAKATOAPRTOBJECT_INTERFACE );
    else if( i == 2 )
        return GetInterface( PARTICLEOBJECTEXT_INTERFACE );
    else if( i == 3 )
        return GetInterface( MAXKRAKATOA_PARTICLE_INTERFACE_ID );
    return GeomObject::GetInterface( i );
}

BaseInterface* MaxKrakatoaPRTLoader::GetInterface( Interface_ID id ) {
    if( id == MaxKrakatoaPRTLoader_INTERFACE_ID )
        return static_cast<frantic::max3d::fpwrapper::FFMixinInterface<MaxKrakatoaPRTLoader>*>( this );
    if( id == MAXKRAKATOAPRTOBJECT_LEGACY1_INTERFACE )
        return static_cast<IMaxKrakatoaPRTObject_Legacy1*>( this );
    if( id == MAXKRAKATOAPRTOBJECT_LEGACY2_INTERFACE )
        return static_cast<IMaxKrakatoaPRTObject_Legacy2*>( this );
    if( id == MAXKRAKATOAPRTOBJECT_INTERFACE )
        return static_cast<IMaxKrakatoaPRTObject*>( this );
    if( id == PARTICLEOBJECTEXT_INTERFACE )
        return m_iparticleobjectWrapper.get();
    if( id == MAXKRAKATOA_PARTICLE_INTERFACE_ID )
        return static_cast<IMaxKrakatoaParticleInterface*>( this );
    return GeomObject::GetInterface( id );
}

RefResult MaxKrakatoaPRTLoader::NotifyRefChanged( const Interval& /*changeInt*/, RefTargetHandle hTarget,
                                                  PartID& partID, RefMessage message, BOOL /*propagate*/ ) {
    if( hTarget == m_refBlock ) {
        int index = 0;
        ParamID pid = m_refBlock->LastNotifyParamID( index );

        switch( pid ) {
        case kCullingRefs:
            if( message == REFMSG_CHANGE && ( partID & PART_TM || partID & PART_OBJ ) ) {
                m_cullingInterval = NEVER;
                InvalidateWorldSpaceCache();
            } else if( message == REFMSG_TARGET_DELETED ) {
                m_refBlock->SetValue( pid, 0, NULL, index );

                m_cullingInterval = NEVER;
                InvalidateWorldSpaceCache();
            }
        case kNodeRefs:
            // This is happening a lot in non-2008 variety Max.
            if( index < 0 || index >= m_refBlock->Count( kNodeRefs ) )
                return REF_DONTCARE;

//             MaxKrakatoaNodeMonitor* pMonitor =
//                 static_cast<MaxKrakatoaNodeMonitor*>( m_refBlock->GetReferenceTarget( kNodeRefs, 0, index ) );
// 
//             // We can get messages from an invalid index during undo, so make sure it is a valid ptr.
//             if( pMonitor ) {
//                 if( message == REFMSG_KRAKATOA_CHANGE ||
//                     ( message == REFMSG_CHANGE && ( partID & ( PART_OBJ | PART_TM ) ) != 0 ) ) {
//                     INode* pNode = pMonitor->GetNode();
//                     InvalidateWSCache( pNode );
// #if MAX_VERSION_MAJOR >= 17
//                     WSStateInvalidate();
// #endif
//                 } else if( message == REFMSG_NODEMONITOR_TARGET_DELETED ) {
//                     INode* pNode = pMonitor->GetNode();
//                     DeleteWSCache( pNode );
// 
//                     m_refBlock->SetValue( kNodeRefs, 0, (ReferenceTarget*)NULL, index );
//                     return REF_AUTO_DELETE;
//                 }
//             }

            return REF_STOP;
        }
    }

    return REF_SUCCEED;
}

void MaxKrakatoaPRTLoader::GetWorldBoundBox( TimeValue t, INode* inode, ViewExp* vpt, Box3& box ) {
    CacheParticlesAtTime( t, inode, vpt );
    box = m_cachedWorldParticles[inode].boundBox;

    if( m_showIcon.at_time( t ) ) {
        Box3 b = GetPRTLoaderIconMesh()->getBoundingBox();
        b.Scale( m_iconSize.at_time( t ) );

        box += b * inode->GetNodeTM( t );
    }
}

void MaxKrakatoaPRTLoader::GetLocalBoundBox( TimeValue t, INode* inode, ViewExp* vpt, Box3& box ) {
    GetWorldBoundBox( t, inode, vpt, box );

    Matrix3 tm = inode->GetNodeTM( t );
    tm.Invert();

    box = to_max_t( from_max_t( tm ) * from_max_t( box ) );
}

BOOL MaxKrakatoaPRTLoader::CanConvertToType( Class_ID obtype ) {
    if( obtype == Class_ID( 0x766a7a0d, 0x311b4fbd ) ) // Hardcoded since this impl should be temporary
        return TRUE;
    return GeomObject::CanConvertToType( obtype );
}

Object* MaxKrakatoaPRTLoader::ConvertToType( TimeValue t, Class_ID obtype ) {
    if( obtype == Class_ID( 0x766a7a0d, 0x311b4fbd ) ) // Hardcoded since this impl should be temporary
        return this;
    return GeomObject::ConvertToType( t, obtype );
}

void MaxKrakatoaPRTLoader::GetDeformBBox( TimeValue t, Box3& box, Matrix3* /*tm*/, BOOL /*useSel*/ ) {
    try {
        float x = m_deformBoxX.at_time( t );
        float y = m_deformBoxY.at_time( t );
        float z = m_deformBoxZ.at_time( t );

        box.Init();
        box.pmin = Point3( -x / 2, -y / 2, 0.f );
        box.pmax = Point3( x / 2, y / 2, z );
    } catch( const std::exception& e ) {
        // Swallow this error, because this function is directly exposed to Max, and will crash
        // the program when an exception occurs.
        FF_LOG( error ) << e.what();
        box.Init();
    }
}

int MaxKrakatoaPRTLoader::Display( TimeValue t, INode* pNode, ViewExp* pView, int /*flags*/ ) {
    try {
        if( !pNode || !pView )
            return 0;

        CacheParticlesAtTime( t, pNode, pView );

        GraphicsWindow* gw = pView->getGW();
        DWORD rndLimits = gw->getRndLimits();

        gw->setRndLimits( GW_Z_BUFFER | GW_WIREFRAME );
        gw->setTransform( Matrix3( 1 ) );

        particle_cache_t& pc = m_cachedWorldParticles[pNode];

        switch( m_viewportParticleDisplayMode.at_time( t ) ) {
        default:
        case ::viewport::DISPLAYMODE_DOT1:
        case ::viewport::DISPLAYMODE_DOT2: {
            MarkerType style = ( m_viewportParticleDisplayMode.at_time( t ) == ::viewport::DISPLAYMODE_DOT1 )
                                   ? POINT_MRKR
                                   : SM_DOT_MRKR;

            gw->startMarkers();
            for( particle_array::iterator it = pc.particles.begin(); it != pc.particles.end(); ++it ) {
                color3f c = m_colorAccessor.get( *it );
                Point3 p = to_max_t( m_posAccessor.get( *it ) );
                gw->setColor( LINE_COLOR, c.r, c.g, c.b );
                gw->marker( &p, style );
            }
            gw->endMarkers();
            break;
        }
        case ::viewport::DISPLAYMODE_VELOCITY: {
            gw->startSegments();
            for( particle_array::iterator it = pc.particles.begin(); it != pc.particles.end(); ++it ) {
                Point3 p[2];

                color3f c = m_colorAccessor.get( *it );
                p[0] = p[1] = to_max_t( m_posAccessor.get( *it ) );
                p[1] += to_max_t( m_velocityAccessor.get( *it ) );

                gw->setColor( LINE_COLOR, c.r, c.g, c.b );
                gw->segment( p, TRUE );
            }
            gw->endSegments();
            break;
        }
        case ::viewport::DISPLAYMODE_NORMAL: {
            float scaleNormals = m_scaleNormals.at_time( t );

            gw->startSegments();
            for( particle_array::iterator it = pc.particles.begin(); it != pc.particles.end(); ++it ) {
                Point3 p[2];

                color3f c = m_colorAccessor.get( *it );
                p[0] = p[1] = to_max_t( m_posAccessor.get( *it ) );
                p[1] += to_max_t( scaleNormals * m_normalAccessor.get( *it ) );

                gw->setColor( LINE_COLOR, c.r, c.g, c.b );
                gw->segment( p, TRUE );
            }
            gw->endSegments();
            break;
        }
        case ::viewport::DISPLAYMODE_TANGENT: {
            float scale = m_scaleNormals.at_time( t );

            gw->startSegments();
            for( particle_array::iterator it = pc.particles.begin(); it != pc.particles.end(); ++it ) {
                Point3 p[2];

                color3f c = m_colorAccessor.get( *it );
                p[0] = p[1] = to_max_t( m_posAccessor.get( *it ) );
                p[1] += to_max_t( scale * m_tangentAccessor.get( *it ) );

                gw->setColor( LINE_COLOR, c.r, c.g, c.b );
                gw->segment( p, TRUE );
            }
            gw->endSegments();
            break;
        }
        }

        if( m_showBoundingBox.at_time( t ) ) {
            gw->setColor( LINE_COLOR, 1, 1, 1 );
            frantic::max3d::DrawBox( gw, pc.boundBox );
        }

        if( m_showCountInViewport.at_time( t ) ) {
            Point3 p = pc.boundBox.Max();
            M_STD_STRING msg = boost::lexical_cast<M_STD_STRING>( pc.particles.size() );
            gw->setColor( TEXT_COLOR, Color( 1, 1, 1 ) );
            gw->text( &p, const_cast<MCHAR*>( msg.c_str() ) );
        }

        if( m_showIcon.at_time( t ) ) {
            float scale = m_iconSize.at_time( t );

            Matrix3 tm = pNode->GetNodeTM( t );
            tm.Scale( Point3( scale, scale, scale ) );

            gw->setTransform( tm );
            frantic::max3d::draw_mesh_wireframe( gw, GetPRTLoaderIconMesh(),
                                                 pNode->Selected() ? color3f( 1 )
                                                                   : color3f::from_RGBA( pNode->GetWireColor() ) );
        }

        gw->setRndLimits( rndLimits );
        return TRUE;
    } catch( const std::exception& e ) {
        max3d::MsgBox(
#if MAX_VERSION_MAJOR >= 15
            MSTR::FromACP( e.what() ).data()
#else
            e.what()
#endif
                ,
            _T("Krakatoa Exception!"), MB_OK );
        return FALSE;
    }
}

int MaxKrakatoaPRTLoader::HitTest( TimeValue t, INode* inode, int type, int crossing, int flags, IPoint2* p,
                                   ViewExp* vpt ) {
    try {
        GraphicsWindow* gw = vpt->getGW();

        if( ( ( flags & HIT_SELONLY ) && !inode->Selected() ) || gw == NULL || inode == NULL )
            return 0;

        HitRegion hitRegion;
        MakeHitRegion( hitRegion, type, crossing, 4, p );

        gw->setRndLimits( GW_PICK | GW_WIREFRAME );
        gw->setHitRegion( &hitRegion );
        gw->clearHitCode();

        particle_cache_t& pi = m_cachedWorldParticles[inode];

        gw->setTransform( Matrix3( 1 ) );
        DrawBox( gw, pi.boundBox );
        if( gw->checkHitCode() )
            return true;

        gw->startMarkers();

        for( particle_array::iterator it = pi.particles.begin(); it != pi.particles.end(); ++it ) {
            Point3 pos = to_max_t( m_posAccessor.get( *it ) );

            gw->marker( &pos, POINT_MRKR );
            if( gw->checkHitCode() )
                return true;
        }

        gw->endMarkers();

        // Hit test against the icon if necessary
        if( m_showIcon.at_time( t ) ) {
            Matrix3 iconMatrix = inode->GetNodeTM( t );
            float scale = m_iconSize.at_time( t );

            iconMatrix.Scale( Point3( scale, scale, scale ) );

            gw->setTransform( iconMatrix );
            if( GetPRTLoaderIconMesh()->select( gw, NULL, &hitRegion ) )
                return true;
        }

        return false;
    } catch( const std::exception& e ) {
        FF_LOG( error ) << _T("Krakatoa PRT Loader: HitTest: ") << frantic::strings::to_tstring( e.what() )
                        << std::endl;
        return false;
    }
}

void MaxKrakatoaPRTLoader::CacheParticlesAtTime( TimeValue t, INode* pNode, ViewExp* pView ) {
    using namespace frantic::particles::streams;

    try {
        if( !m_validInterval.InInterval( t ) ) {
            m_validInterval = FOREVER;
            m_cachedObjectParticles.clear();

            m_lastErrorCode = 0;
            m_lastErrorMessage = _T("");

            // Invalidate all the world space caches
            for( std::map<INode*, particle_cache_t>::iterator it = m_cachedWorldParticles.begin();
                 it != m_cachedWorldParticles.end(); ++it )
                it->second.iv = NEVER;

            if( m_enabledInView.at_time( t ) ) {
                if( !m_loadSingleFrame.at_time( t ) )
                    m_validInterval.SetInstant( t );

                float percentage = m_percentViewport.at_time( t ) * m_percentRenderer.at_time( t ) * 0.0001f;
                boost::int64_t limit = m_useViewportLimit.at_time( t )
                                           ? static_cast<boost::int64_t>( m_viewportLimit.at_time( t ) * 1000 )
                                           : std::numeric_limits<boost::int64_t>::max();
                /*bool loadEvenly =
                        (m_viewLoadMode.at_time(t) == viewport::PARTICLELOAD_EVENLY_DISTRIBUTE) ||
                        (m_viewLoadMode.at_time(t) == viewport::PARTICLELOAD_USE_RENDER_SETTING &&
                   m_renderLoadMode.at_time(t) == render::PARTICLELOAD_EVENLY_DISTRIBUTE);*/
                ::viewport::RENDER_LOAD_PARTICLE_MODE viewLoadMode =
                    static_cast<::viewport::RENDER_LOAD_PARTICLE_MODE>( (int)m_viewLoadMode.at_time( t ) );
                render::RENDER_LOAD_PARTICLE_MODE renderLoadMode;
                if( viewLoadMode == ::viewport::PARTICLELOAD_USE_RENDER_SETTING )
                    renderLoadMode =
                        static_cast<render::RENDER_LOAD_PARTICLE_MODE>( (int)m_renderLoadMode.at_time( t ) );
                else
                    renderLoadMode = static_cast<render::RENDER_LOAD_PARTICLE_MODE>( viewLoadMode - 1 );

                boost::shared_ptr<particle_istream> pin;
                pin = GetFileParticleStream( m_channelMap, t, 0x01, false );
                pin = GetObjectSpaceParticleStream( pin, percentage, limit, renderLoadMode, t, GetTicksPerFrame() / 4 );

                // We need to ensure that we get all the channels in the file, but enforce a Position
                // channel at the very least.
                channel_map pcm = pin->get_native_channel_map();
                if( !pcm.has_channel( _T("Position") ) )
                    pcm.append_channel<vector3f>( _T("Position") );

                try {
                    m_cachedObjectParticles.reset( pcm );
                    m_cachedObjectParticles.insert_particles( pin );
                } catch( ... ) {
                    m_cachedObjectParticles.reset( pcm );
                    throw;
                }
            }
        }

        if( !m_cullingInterval.InInterval( t ) ) {
            RecacheCullingVolume( t );

            // Invalidate all the world space caches
            for( std::map<INode*, particle_cache_t>::iterator it = m_cachedWorldParticles.begin();
                 it != m_cachedWorldParticles.end(); ++it )
                it->second.iv = NEVER;
        }

        std::map<INode*, particle_cache_t>::iterator it = m_cachedWorldParticles.find( pNode );
        if( it == m_cachedWorldParticles.end() ) {
            it = m_cachedWorldParticles.insert( std::make_pair( pNode, particle_cache_t() ) ).first;

            // Check if our cache was deleted, but there is already a nodemonitor for this node.
            // MaxKrakatoaNodeMonitor* pMonitor = NULL;
            // for( int i = 0, iEnd = m_refBlock->Count( kNodeRefs ); i < iEnd && !pMonitor; ++i ) {
            //     MaxKrakatoaNodeMonitor* pCurMonitor =
            //         static_cast<MaxKrakatoaNodeMonitor*>( m_refBlock->GetReferenceTarget( kNodeRefs, t, i ) );
            //     if( pCurMonitor && pCurMonitor->GetNode() == pNode )
            //         pMonitor = pCurMonitor;
            // }

            // if( !pMonitor ) {
            //     try {
            //         pMonitor = static_cast<MaxKrakatoaNodeMonitor*>(
            //             CreateInstance( REF_TARGET_CLASS_ID, KRAKATOA_NODEMONITOR_CLASS_ID ) );
            //         pMonitor->SetNode( pNode );

            //         m_refBlock->Append( kNodeRefs, 1, (ReferenceTarget**)( &pMonitor ) );
            //     } catch( const std::exception& ) {
            //         if( pMonitor )
            //             pMonitor->MaybeAutoDelete();
            //         throw;
            //     }
            // }
        }

        particle_cache_t& pc = it->second;
        if( !pc.iv.InInterval( t ) ) {
            pc.iv = FOREVER;
            pc.boundBox.Init();
            pc.particles.reset( m_channelMap );

            if( m_enabledInView.at_time( t ) ) {
                render::COLORMODE cMode = static_cast<render::COLORMODE>( (int)m_particleColorSource.at_time( t ) );

                if( m_viewportParticleColorSource.at_time( t ) != ::viewport::COLORMODE_USE_RENDER_SETTING ) {
                    switch( m_viewportParticleColorSource.at_time( t ) ) {
                    case ::viewport::COLORMODE_FILE_COLOR:
                        cMode = render::COLORMODE_FILE_COLOR;
                        break;
                    case ::viewport::COLORMODE_MATERIAL:
                        cMode = render::COLORMODE_MATERIAL;
                        break;
                    case ::viewport::COLORMODE_WIREFRAME:
                        cMode = render::COLORMODE_WIREFRAME;
                        break;
                    }
                }

                // Set the validity of this cache to the node's validity.
                // Manually include the mtl & TM validity because max doesn't seem to (The ObjectState funcs are
                // useless).
                /*const ObjectState& os = pNode->EvalWorldState(t);
                pc.iv &= os.Validity(t);
                pc.iv &= os.mtlValid();
                pc.iv &= os.tmValid();*/

                pc.iv &= pNode->EvalWorldState( t ).obj->ObjectValidity( t );

                if( m_useTransform.at_time( t ) )
                    pNode->GetObjectTM( t, &pc.iv );

                Mtl* pMtl = pNode->GetMtl();
                if( pMtl && cMode == render::COLORMODE_MATERIAL )
                    pc.iv &= pMtl->Validity( t );

                frantic::graphics::camera<float> theCamera;
                {
                    frantic::max3d::AutoViewExp activeView;
                    if( !pView ) {
                        pView =
#if MAX_VERSION_MAJOR >= 15
                            &GetCOREInterface()->GetActiveViewExp();
#else
                            GetCOREInterface()->GetActiveViewport();
#endif
                        activeView.reset( pView );
                    }

                    Matrix3 tm;
                    pView->GetAffineTM( tm );

                    theCamera.set_transform( frantic::max3d::from_max_t( Inverse( tm ) ) );
                    theCamera.set_horizontal_fov( pView->GetFOV() );
                    theCamera.set_projection_mode( pView->IsPerspView()
                                                       ? frantic::graphics::projection_mode::perspective
                                                       : frantic::graphics::projection_mode::orthographic );
                }

                // boost::scoped_ptr<IMaxKrakatoaPRTObject::IEvalContext> theContext(
                // IMaxKrakatoaPRTObject::CreateDefaultEvalContext( m_channelMap, theCamera, t ) );
                frantic::max3d::particles::IMaxKrakatoaPRTEvalContextPtr theContext =
                    frantic::max3d::particles::CreateMaxKrakatoaPRTEvalContext( t, Class_ID( 0x5ccc4d89, 0x35345085 ),
                                                                                &theCamera, &m_channelMap );

                Interval viewValidity = FOREVER;

                boost::shared_ptr<particle_istream> pin(
                    new particle_array_particle_istream( m_cachedObjectParticles, m_channelMap ) );
                pin = GetWorldSpaceParticleStream( pin, pNode, t, viewValidity, theContext, m_cachedCullingVolume,
                                                   false );
                pin = GetShadedParticleStream( pin, pNode, t, viewValidity, theContext, false );

                struct CopyChannels {
                    static color3f fn( const color3f& inChannel ) { return inChannel; }
                };

                boost::array<frantic::tstring, 1> copySrcChannels = { _T("PRTViewportColor") };

                if( pin->get_native_channel_map().has_channel( _T("PRTViewportColor") ) )
                    pin.reset(
                        new frantic::particles::streams::apply_function_particle_istream<color3f( const color3f& )>(
                            pin, &CopyChannels::fn, _T("Color"), copySrcChannels ) );

                boost::scoped_array<char> pParticle( new char[m_channelMap.structure_size()] );

                m_channelMap.construct_structure( pParticle.get() );
                m_colorAccessor.set( pParticle.get(), color3f( 1.f ) );
                pin->set_default_particle( pParticle.get() );

                float fps = static_cast<float>( GetFrameRate() );

                while( pin->get_particle( pParticle.get() ) ) {
                    m_velocityAccessor.set( pParticle.get(), m_velocityAccessor.get( pParticle.get() ) /
                                                                 fps ); // Set vel. to units/frame
                    m_colorAccessor.set( pParticle.get(),
                                         m_colorAccessor.get( pParticle.get() ).to_clamped() ); // Clamp the colors

                    pc.boundBox += to_max_t( m_posAccessor( pParticle.get() ) );
                    pc.particles.push_back( pParticle.get() );
                }
            } // if enabledInView.at_time(t)

            max3d::mxs::expression( _T("obj.showstate ") + boost::lexical_cast<frantic::tstring>( m_lastErrorCode ) )
                .bind( _T("obj"), m_parent.get_target() )
                .at_time( t )
                .evaluate<Value*>();
        }

        return;
    } catch( const std::exception& e ) {
        m_lastErrorCode = 1;
        m_lastErrorMessage += frantic::strings::to_tstring( e.what() );
        m_lastErrorMessage += _T( '\n' );
    }

    // This try/catch is for updating the state after an error occurred. It is not in the catch handler to avoid a
    // double exception.
    try {
        max3d::mxs::expression( _T("obj.showstate ") + boost::lexical_cast<frantic::tstring>( m_lastErrorCode ) )
            .bind( _T("obj"), m_parent.get_target() )
            .at_time( t )
            .evaluate<Value*>();
    } catch( const std::exception& e ) {
        FF_LOG( error ) << e.what() << std::endl;
    }
}

void MaxKrakatoaPRTLoader::RecacheCullingVolume( TimeValue t ) {
    frantic::geometry::trimesh3 mesh;

    m_cullingInterval = FOREVER;

    std::size_t validCount = 0;
    for( int i = 0; i < m_refBlock->Count( kCullingRefs ); ++i ) {
        if( INode* pNode = m_refBlock->GetINode( kCullingRefs, t, i ) ) {
            ++validCount;
            frantic::max3d::geometry::append_inode_to_mesh( pNode, t, m_cullingInterval, mesh );
        }
    }

    m_cachedCullingVolume.reset( validCount > 0 ? new frantic::geometry::trimesh3_kdtree_volume_collection( mesh )
                                                : NULL );
}

void MaxKrakatoaPRTLoader::UpdateCullingNodes( TimeValue t ) {
    // This needs to be in a try...catch block since it is exposed to MAXScript
    try {
        frantic::tstring cullingSelectionSet = m_cullingNamedSelectionSet.at_time( t );

        std::vector<INode*> newCullingNodes;
        frantic::max3d::geopipe::get_named_selection_set_nodes( cullingSelectionSet, newCullingNodes );

        // In Max 9, this was the most stable method of setting multiple culling nodes.
        m_refBlock->ZeroCount( kCullingRefs );
        if( newCullingNodes.size() > 0 )
            m_refBlock->Append( kCullingRefs, (int)newCullingNodes.size(), &newCullingNodes[0] );

        m_cullingInterval = NEVER;
    } catch( const std::exception& e ) {
        FF_LOG( error ) << frantic::strings::to_tstring( e.what() ) << std::endl;
        if( !IsNetworkRenderServer() )
            MessageBox( NULL, frantic::strings::to_tstring( e.what() ).c_str(), _T("PRT Loader Error"), MB_OK );
    }
}

boost::shared_ptr<volume_collection> MaxKrakatoaPRTLoader::GetCullingVolume( TimeValue t ) {
    using frantic::geometry::trimesh3_kdtree_volume_collection;

    boost::shared_ptr<volume_collection> result;

    if( m_useCullingGizmo.at_time( t ) || m_useThresholdCulling.at_time( t ) ||
        m_getCullingSurfaceNormals.at_time( t ) ) {
        std::vector<INode*> cullingNodes;
        frantic::max3d::geopipe::get_named_selection_set_nodes( m_cullingNamedSelectionSet.at_time( t ), cullingNodes );

        if( cullingNodes.size() > 0 ) {
            trimesh3 mesh;
            frantic::max3d::geometry::append_inodes_to_mesh( cullingNodes.begin(), cullingNodes.end(), t, mesh );

            result.reset( new trimesh3_kdtree_volume_collection( mesh ) );
        }
    }

    return result;
}

void MaxKrakatoaPRTLoader::GetParticleFilenames( int frame, std::vector<frantic::tstring>& outFilenames, int mask ) {
    bool bSingleFrame = m_loadSingleFrame.at_time( 0 );
    for( std::size_t i = 0; i < m_fileList.size(); ++i ) {
        if( ( m_fileListFlags[(int)i].at_time( 0 ) & mask ) != 0 || mask == 0x00 ) {
            frantic::tstring filename( m_fileList[(int)i].at_time( 0 ).operator const frantic::strings::tstring() );
            if( !bSingleFrame )
                filename = frantic::files::replace_sequence_number( filename, frame );

            outFilenames.push_back( filename );
        }
    } // for i = 0 to m_fileList.size()
}

void MaxKrakatoaPRTLoader::AssertNotLoadingFrom( const frantic::tstring& file ) {
    TimeValue t = GetCOREInterface()->GetTime();

    if( m_enabledInRender.at_time( t ) ) {
        if( m_loadSingleFrame.at_time( t ) ) {
            for( std::size_t i = 0; i < m_fileList.size(); ++i ) {
                // Only check files that are enabled in render mode.
                if( ( m_fileListFlags[(int)i].at_time( t ) & enabled_mode::render ) &&
                    file.compare( m_fileList[(int)i].at_time( t ) ) == 0 )
                    throw std::runtime_error( "Cannot save to file: " + frantic::strings::to_string( file ) +
                                              " since a PRTLoader is loading from there" );
            }
        } else {
            files::filename_pattern fp( file );
            for( std::size_t i = 0; i < m_fileList.size(); ++i ) {
                // Only check files that are enabled in render mode.
                if( ( m_fileListFlags[(int)i].at_time( t ) & enabled_mode::render ) &&
                    fp.matches_pattern( m_fileList[(int)i].at_time( t ) ) )
                    throw std::runtime_error( "Cannot save to file: " + frantic::strings::to_string( file ) +
                                              " since a PRTLoader is loading from the file: \"" +
                                              frantic::strings::to_string( m_fileList[(int)i].at_time( t ) ) +
                                              "\" which is from the same sequence" );
            }
        }
    }
}

boost::shared_ptr<particle_istream> MaxKrakatoaPRTLoader::GetFileParticleStream( const channel_map& pcm, TimeValue t,
                                                                                 int mask, bool throwOnError ) {
    using namespace frantic::particles::streams;

    Interval valid = FOREVER;

    PB2Value* playbackVal = NULL;

    if( m_enablePlaybackGraph.at_time( t ) )
        playbackVal = &m_playbackGraphTime.as_pbvalue();

    double interpFrameD, interpParam, timeDerivative;
    double frameD = frantic::max3d::get_sequence_whole_frame( t, playbackVal, m_frameOffset.at_time( t ), interpFrameD,
                                                              interpParam, timeDerivative, valid );
    int frame = (int)frameD;
    int interpFrame = (int)interpFrameD;

    bool interpolate = m_interpolateFrames.at_time( t );
    bool blankInterpFrame = false;

    if( !m_loadSingleFrame.at_time( t ) && m_limitToRange.at_time( t ) ) {
        int start = m_rangeStartFrame.at_time( t );
        int end = m_rangeEndFrame.at_time( t );
        if( frame < start ) {
            if( m_beforeRangeMode.at_time( t ) == clamp_mode::blank ) {
                return boost::shared_ptr<particle_istream>(
                    new frantic::particles::streams::empty_particle_istream( pcm, pcm ) );
            } else if( m_beforeRangeMode.at_time( t ) == clamp_mode::hold ) {
                frame = interpFrame = start;
                interpParam = 0;
            }
        } else if( frame > end ) {
            if( m_afterRangeMode.at_time( t ) == clamp_mode::blank ) {
                return boost::shared_ptr<particle_istream>(
                    new frantic::particles::streams::empty_particle_istream( pcm, pcm ) );
            } else if( m_afterRangeMode.at_time( t ) == clamp_mode::hold ) {
                frame = interpFrame = end;
                interpParam = 0;
            }
        }

        if( interpFrame < start ) {
            if( m_beforeRangeMode.at_time( t ) == clamp_mode::blank ) {
                blankInterpFrame = true;
                interpParam = 0;
            } else if( m_beforeRangeMode.at_time( t ) == clamp_mode::hold ) {
                interpFrame = start;
            }
        } else if( interpFrame > end ) {
            if( m_afterRangeMode.at_time( t ) == clamp_mode::blank ) {
                blankInterpFrame = true;
                interpParam = 0;
            } else if( m_afterRangeMode.at_time( t ) == clamp_mode::hold ) {
                interpFrame = end;
            }
        }
    }

    // Make sure each file exists, throwing or recording errors based on the user requests.
    std::vector<frantic::tstring> files, otherFiles;
    std::vector<boost::shared_ptr<particle_istream>> pins;

    bool ignoreRenderErrors = false;
    bool allowThreading = true;
    Renderer* r = GetCOREInterface()->GetCurrentRenderer();
    if( r && r->ClassID() == MaxKrakatoa_CLASS_ID ) {
        ignoreRenderErrors = static_cast<MaxKrakatoa*>( r )->properties().get_bool( _T("IgnoreMissingParticles") );
        allowThreading = static_cast<MaxKrakatoa*>( r )->properties().get_bool( _T("Performance:MT:Loading") );
    }

    GetParticleFilenames( frame, files, mask );
    GetParticleFilenames( interpFrame, otherFiles, mask );

    // Set up the output file factory here.

    for( size_t i = 0; i < files.size(); ++i ) {
        try {
            frantic::particles::particle_file_stream_factory_object factory;
            factory.set_coordinate_system( frantic::graphics::coordinate_system::right_handed_zup );
            factory.set_length_unit_in_meters( frantic::max3d::get_scale_to_meters() );
            factory.set_frame_rate( GetFrameRate(), 1 );

            //////////////////////////////////////////// Realflow legacy load hack ////////////////////////////////
            if( m_useLegacyRealflowBinLoading.at_time( t ) &&
                frantic::files::extension_iequals( files[i], _T( ".bin" ) ) ) {
                factory.set_length_unit_in_meters( 0.0 );
            }
            ///////////////////////////////////////////////////////////////////////////////////////////////////////

            pins.push_back( factory.create_istream( files[i], pcm ) );

            pins.back() = frantic::max3d::particles::streams::convert_time_channels_to_seconds( pins.back() );

            try {
                int partitionIndex;
                int partitionCount;
                frantic::files::get_part_from_filename( files[i], partitionIndex, partitionCount );
                pins.back() =
                    boost::make_shared<frantic::particles::streams::set_channel_particle_istream<boost::int32_t>>(
                        pins.back(), _T( "PartitionIndex" ), partitionIndex );
                pins.back() =
                    boost::make_shared<frantic::particles::streams::set_channel_particle_istream<boost::int32_t>>(
                        pins.back(), _T( "PartitionCount" ), partitionCount );
            } catch( std::runtime_error ) {
            }

            if( interpolate && std::abs( interpParam ) > 1e-3 ) {
                double timeStepSeconds = 1.0 / static_cast<double>( GetFrameRate() ); // ie. Seconds per frame.

                if( interpParam < 0 ) {
                    interpParam = -interpParam;
                    timeStepSeconds = -timeStepSeconds;
                }

                boost::shared_ptr<particle_istream> otherPin;
                if( blankInterpFrame ) {
                    otherPin = boost::make_shared<frantic::particles::streams::empty_particle_istream>( pcm );
                } else {
                    otherPin = factory.create_istream( otherFiles[i], pcm );
                }

                otherPin = frantic::max3d::particles::streams::convert_time_channels_to_seconds( otherPin );

                pins.back() = boost::make_shared<time_interpolation_particle_istream>(
                    pins.back(), otherPin, static_cast<float>( timeStepSeconds ), static_cast<float>( interpParam ) );
            }
        } catch( const std::exception& e ) {
            if( throwOnError ) {
                if( !ignoreRenderErrors )
                    throw;
                else
                    FF_LOG( warning ) << _T("Krakatoa is ignoring an invalid or missing file: \"") << files[i]
                                      << _T("\"") << std::endl;
            } else {
                m_lastErrorCode = 1;
                m_lastErrorMessage += frantic::strings::to_tstring( e.what() );
                m_lastErrorMessage += _T("\n");
            }
        }
    }

    if( pins.size() > 0 ) {
        if( pins.size() > 1 ) {
            if( ( mask & enabled_mode::render ) && allowThreading )
                return boost::shared_ptr<particle_istream>( new concatenated_parallel_particle_istream( pins ) );
            else
                return boost::shared_ptr<particle_istream>( new concatenated_particle_istream( pins ) );
        }

        return pins[0];
    }

    return boost::shared_ptr<particle_istream>( new empty_particle_istream( pcm, pcm ) );
}

boost::shared_ptr<particle_istream> MaxKrakatoaPRTLoader::GetObjectSpaceParticleStream(
    boost::shared_ptr<particle_istream> pin, float percentage, boost::int64_t limit,
    // bool loadEvenly,
    render::RENDER_LOAD_PARTICLE_MODE loadMode, TimeValue t, TimeValue /*timeStep*/ ) {
    using namespace frantic::particles::streams;

    if( pin->particle_count() == 0 || percentage == 0 || limit == 0 )
        return boost::shared_ptr<particle_istream>(
            new empty_particle_istream( pin->get_channel_map(), pin->get_native_channel_map() ) );

    Interval valid = FOREVER;

    PB2Value* playbackVal = NULL;

    if( m_enablePlaybackGraph.at_time( t ) )
        playbackVal = &m_playbackGraphTime.as_pbvalue();

    double interpFrame, interpParam, timeDerivative;
    double frame = frantic::max3d::get_sequence_whole_frame( t, playbackVal, m_frameOffset.at_time( t ), interpFrame,
                                                             interpParam, timeDerivative, valid );

    // Convert from frames to seconds.
    double timeOffset = interpParam / static_cast<double>( GetFrameRate() );

    const bool hasPosition = pin->get_channel_map().has_channel( _T("Position") );
    const bool hasVelocity = pin->get_channel_map().has_channel( _T("Velocity") );
    const bool hasNativeVelocity = pin->get_native_channel_map().has_channel( _T( "Velocity" ) );
    // bool hasDensity = pin->get_channel_map().has_channel("Density");

    boost::shared_ptr<particle_istream> result;
    if( loadMode == render::PARTICLELOAD_EVENLY_DISTRIBUTE )
        result = apply_fractional_particle_istream( pin, percentage, limit, true );
    else if( loadMode == render::PARTICLELOAD_FIRST_N )
        result = apply_fractional_particle_istream( pin, percentage, limit, false );
    else if( loadMode == render::PARTICLELOAD_EVENLY_DISTRIBUTE_IDS ) {
        if( pin->get_native_channel_map().has_channel( _T("ID") ) )
            result = apply_fractional_by_id_particle_istream( pin, percentage, _T("ID"), limit );
        else
            result = apply_fractional_particle_istream( pin, percentage, limit, true );
    }

    if( ( hasVelocity || hasNativeVelocity ) && !m_keepVelocityChannel.at_time( t ) &&
        ( m_loadSingleFrame.at_time( t ) ||
          ( m_limitToRange.at_time( t ) && m_rangeStartFrame.at_time( t ) == m_rangeEndFrame.at_time( t ) ||
            abs( timeDerivative ) < 1e-4 ) ) ) {
        channel_map beforeChannelMap = pin->get_channel_map();
        result.reset( new set_channel_particle_istream<vector3f>( result, _T( "Velocity" ), vector3f( 0.f ) ) );
        if( hasNativeVelocity && !hasVelocity ) {
            result->set_channel_map( beforeChannelMap );
        }
    }

    static boost::array<frantic::tstring, 2> subframePushChannels = { _T("Position"), _T("Velocity") };
    static boost::array<frantic::tstring, 1> velocityScaleChannels = { _T("Velocity") };

    bool inRange = true;
    if( m_limitToRange.at_time( t ) &&
        ( frame < m_rangeStartFrame.at_time( t ) || frame > m_rangeEndFrame.at_time( t ) ) ) {
        inRange = false;
        timeOffset = 0.0;
        timeDerivative = 0.0;
    }

    if( inRange && hasPosition && abs( timeOffset ) > 1e-4 && !m_interpolateFrames.at_time( t ) )
        result.reset( new apply_function_particle_istream<vector3f( const vector3f&, const vector3f& )>(
            result, boost::bind( &ops::add_velocity_to_pos, _1, _2, static_cast<float>( timeOffset ) ), _T("Position"),
            subframePushChannels ) );

    if( inRange && hasVelocity && abs( timeDerivative - 1.0 ) > 1e-3 )
        result.reset( new apply_function_particle_istream<vector3f( const vector3f& )>(
            result, boost::bind( &ops::scale_vector, _1, static_cast<float>( timeDerivative ) ), _T("Velocity"),
            velocityScaleChannels ) );

    return result;
}

boost::shared_ptr<particle_istream> MaxKrakatoaPRTLoader::GetWorldSpaceParticleStream(
    boost::shared_ptr<particle_istream> pin, INode* pNode, TimeValue t, Interval& inoutValidity,
    frantic::max3d::particles::IMaxKrakatoaPRTEvalContextPtr pEvalContext,
    boost::shared_ptr<volume_collection> pCullingVol, bool renderMode ) {
    using namespace frantic::particles::streams;
    using namespace frantic::max3d::particles::streams;

    TimeValue timeStep = 20;

    if( pin->particle_count_left() == 0 )
        return boost::shared_ptr<particle_istream>(
            new empty_particle_istream( pin->get_channel_map(), pin->get_native_channel_map() ) );

    transform4f tm = GetParticleTM( t, pNode );
    transform4f tmDeriv = GetParticleTM( t + timeStep, pNode );
    tmDeriv -= tm;
    tmDeriv *= ( 1.f * TIME_TICKSPERSEC / timeStep );

    std::vector<frantic::max3d::particles::modifier_info_t> theMods;
    frantic::max3d::collect_node_modifiers( pNode, theMods, 0, renderMode );

    // TODO: This logic is shared by several objects now. It should be put in some shared header.
    if( theMods.size() > 0 ) {
        // We are reversing the iteration order here in order to get the modifiers in the
        // order of application to an object flowing through.
        std::vector<frantic::max3d::particles::modifier_info_t>::reverse_iterator it = theMods.rbegin(),
                                                                                  itEnd = theMods.rend();

        Modifier* stopMod = NULL;
        ModContext* stopModContext = NULL;

        if( IMaxKrakatoaEvalContext* krakCtx = dynamic_cast<IMaxKrakatoaEvalContext*>( pEvalContext.get() ) ) {
            boost::tie( stopMod, stopModContext ) = krakCtx->get_eval_endpoint();
        }

        // Collect OSModifiers, stopping when passing a KCM.
        std::vector<frantic::max3d::particles::modifier_info_t> osMods;
        for( ; it != itEnd && it->first->SuperClassID() == OSM_CLASS_ID &&
               ( it->first != stopMod || it->second != stopModContext );
             ++it ) {
            if( krakatoa::max3d::IPRTModifier* imod = krakatoa::max3d::GetPRTModifierInterface( it->first ) ) {
                if( osMods.size() > 0 )
                    pin.reset( new deformed_particle_istream( pin, osMods, pNode, t, timeStep ) );
                osMods.clear();
                pin = imod->ApplyModifier( pin, m_useTransform.at_time( t ) ? pNode : NULL, t, inoutValidity,
                                           pEvalContext ); // DH 9/6/2012 Seems easiest to pass NULL here, but I could
                                                           // be causing problems later :(
            } else if( is_krakatoa_channel_modifier( it->first ) ) {
                if( osMods.size() > 0 )
                    pin.reset( new deformed_particle_istream( pin, osMods, pNode, t, timeStep ) );
                osMods.clear();
                pin = get_krakatoa_channel_modifier_particle_istream( pin, pEvalContext, pNode, it->first );
            } else if( is_krakatoa_delete_modifier( it->first ) ) {
                if( osMods.size() > 0 )
                    pin.reset( new deformed_particle_istream( pin, osMods, pNode, t, timeStep ) );
                osMods.clear();

                bool useSoftSel = frantic::max3d::mxs::expression( _T("theMod.SelectionMode") )
                                      .bind( _T("theMod"), it->first )
                                      .evaluate<int>() == 2;

                bool resetSelection = frantic::max3d::mxs::expression( _T("try(theMod.ResetSelection)catch(false)") )
                                          .bind( _T("theMod"), it->first )
                                          .evaluate<bool>();

                if( useSoftSel && !pin->get_native_channel_map().has_channel( _T("ID") ) ) {
                    bool warnIfNoID = true;
                    if( !renderMode ) {
                        warnIfNoID = frantic::max3d::mxs::expression(
                                         _T("if theMod.showMissingIDWarning then ( theMod.showMissingIDWarning = ")
                                         _T("false; true ) else ( false )") )
                                         .bind( _T("theMod"), it->first )
                                         .evaluate<bool>();
                    }

                    if( warnIfNoID ) {
                        FF_LOG( warning ) << _T("Krakatoa Delete requires a valid ID channel for a soft-selection ")
                                             _T("delete. It is falling back on the Index channel which may give ")
                                             _T("inconsistent results.")
                                          << std::endl;
                    }
                }

                pin.reset( new selection_culled_particle_istream( pin, useSoftSel, resetSelection ) );
            } else {
                bool skip = false;

                // Add further hard-coded crap here.
                if( it->first->ClassID() == Class_ID( SELECTOSM_CLASS_ID, 0 ) ) {
                    skip = frantic::max3d::mxs::expression( _T("theMod.volume == 3") )
                               .bind( _T("theMod"), it->first )
                               .evaluate<bool>();
                }

                if( !skip )
                    osMods.push_back( *it );
            }
        }
        if( osMods.size() > 0 )
            pin.reset( new deformed_particle_istream( pin, osMods, pNode, t, timeStep ) );

        // We may have requested a partial pipeline evaluation (via. IMaxKrakatoaEvalContext::get_eval_endpoint()) so we
        // return early.
        if( it != itEnd && it->first == stopMod && it->second == stopModContext )
            return pin;

        // Apply the transformation into world space.
        pin = apply_transform_to_particle_istream( pin, tm, tmDeriv );

        // Collect WSModifiers
        std::vector<frantic::max3d::particles::modifier_info_t> wsMods;
        for( ; it != itEnd && it->first->SuperClassID() == WSM_CLASS_ID; ++it ) {
            if( is_krakatoa_delete_modifier( it->first ) ) {
                if( osMods.size() > 0 )
                    pin.reset( new deformed_particle_istream( pin, osMods, pNode, t, timeStep ) );
                osMods.clear();

                bool useSoftSel = frantic::max3d::mxs::expression( _T( "theMod.SelectionMode" ) )
                                      .bind( _T( "theMod" ), it->first )
                                      .evaluate<int>() == 2;

                bool resetSelection = frantic::max3d::mxs::expression( _T( "try(theMod.ResetSelection)catch(false)" ) )
                                          .bind( _T( "theMod" ), it->first )
                                          .evaluate<bool>();

                if( useSoftSel && !pin->get_native_channel_map().has_channel( _T( "ID" ) ) ) {
                    bool warnIfNoID = true;
                    if( !renderMode ) {
                        warnIfNoID =
                            frantic::max3d::mxs::expression(
                                _T( "if theMod.showMissingIDWarning then ( theMod.showMissingIDWarning = false; true ) else ( false )" ) )
                                .bind( _T( "theMod" ), it->first )
                                .evaluate<bool>();
                    }

                    if( warnIfNoID ) {
                        FF_LOG( warning ) << _T( "Krakatoa Delete requires a valid ID channel for a soft-selection " )
                                             _T( "delete. It is falling back on the Index channel which may give " )
                                             _T( "inconsistent results." )
                                          << std::endl;
                    }
                }

                pin.reset( new frantic::particles::streams::selection_culled_particle_istream( pin, useSoftSel,
                                                                                               resetSelection ) );
            } else if( krakatoa::max3d::IPRTModifier* imod = krakatoa::max3d::GetPRTModifierInterface( it->first ) ) {
                if( !wsMods.empty() ) {
                    pin.reset( new deformed_particle_istream( pin, wsMods, pNode, t, timeStep ) );
                    wsMods.clear();
                    inoutValidity.SetInstant( t );
                }
                pin = imod->ApplyModifier( pin, pNode, t, inoutValidity, pEvalContext );
            } else {
                wsMods.push_back( *it );
                pin.reset( new deformed_particle_istream( pin, wsMods, pNode, t, timeStep ) );
                wsMods.clear();
            }
        }

    } else {
        // There are no modifiers so just transform into worldspace and move on.
        pin = apply_transform_to_particle_istream( pin, tm, tmDeriv );
    }

    if( m_useCullingGizmo.at_time( t ) && pCullingVol )
        pin.reset( new volume_culled_particle_istream(
            pin, boost::make_tuple( pCullingVol, !m_invertCullingGizmo.at_time( t ) ) ) );

    if( ( m_useThresholdCulling.at_time( t ) || m_getCullingSurfaceNormals.at_time( t ) ) && pCullingVol ) {
        float cullDistance = m_cullingThreshold.at_time( t );
        bool useThresholdCulling = m_useThresholdCulling.at_time( t );
        bool useSurfaceNormals = m_getCullingSurfaceNormals.at_time( t );
        pin.reset( new surface_culled_particle_istream(
            pin, boost::make_tuple( pCullingVol, useThresholdCulling, useSurfaceNormals, cullDistance ) ) );
    }

    // We only want to change the object validity when operating in the viewport, since the caching
    // mechanism is only for viewport settings.
    // TODO: This should affect the node cache validity, not the object validity.
    if( !renderMode ) {
        Interval modifierInterval = FOREVER;
        for( std::size_t i = 0; i < theMods.size(); ++i )
            modifierInterval &= theMods[i].first->LocalValidity( t );

        m_validInterval &= modifierInterval;
        if( m_validInterval.Empty() )
            m_validInterval.SetInstant( t );
    }

    return pin;
}

boost::shared_ptr<particle_istream> MaxKrakatoaPRTLoader::GetShadedParticleStream(
    boost::shared_ptr<particle_istream> pin, INode* pNode, TimeValue t, Interval& inoutValidity,
    frantic::max3d::particles::IMaxKrakatoaPRTEvalContextPtr pEvalContext, bool renderMode ) {
    using namespace frantic::particles::streams;

    Mtl* pMtl = pNode->GetMtl();
    if( pMtl && ( renderMode || !m_ignoreMaterial.at_time( t ) ) ) {
        if( krakatoa::max3d::IPRTMaterial* prtMtl = krakatoa::max3d::GetPRTMaterialInterface( pMtl ) ) {
            pin = prtMtl->ApplyMaterial( pin, pNode, t, inoutValidity, pEvalContext );
        } else {
            frantic::max3d::shaders::renderInformation localRenderInfo;
            localRenderInfo.m_camera = pEvalContext->GetCamera();
            localRenderInfo.m_cameraPosition = frantic::max3d::to_max_t( localRenderInfo.m_camera.camera_position() );
            localRenderInfo.m_toObjectTM = frantic::max3d::from_max_t( Inverse( pNode->GetNodeTM( t ) ) );
            localRenderInfo.m_toWorldTM = frantic::graphics::transform4f::identity();

            pin = krakatoa::max3d::ApplyStdMaterial( pin, pMtl, localRenderInfo, true, true, true, true, t );
            // pin.reset( new MaxKrakatoaStdMaterialIStream(pin, pMtl, localRenderInfo, true, true, true, true, t) );
        }
    }

    // If we have no mtl, or the mtl doesn't affect the Color channel, then we should apply wire color.
    if( !pin->get_native_channel_map().has_channel( _T("Color") ) )
        pin.reset( new set_channel_particle_istream<color3f>( pin, _T("Color"),
                                                              color3f::from_RGBA( pNode->GetWireColor() ) ) );

    return pin;
}

boost::shared_ptr<particle_istream>
MaxKrakatoaPRTLoader::GetRenderParticleStream( INode* pNode, TimeValue t, Interval& inoutValidity,
                                               frantic::max3d::particles::IMaxKrakatoaPRTEvalContextPtr pEvalContext ) {
    using namespace frantic::particles::streams;

    if( !m_parent.get_target() ) {
        FF_LOG( warning ) << _T("\"") << pNode->GetName()
                          << _T("\" was not correctly bound to its scripted object. This may not be an error if your ")
                             _T("scene uses Afterburn 4.0b")
                          << std::endl;
        return boost::shared_ptr<particle_istream>(
            new frantic::particles::streams::empty_particle_istream( pEvalContext->GetDefaultChannels() ) );
    }

    TimeValue timeStep = 20;

    if( !m_enabledInRender.at_time( t ) )
        return boost::shared_ptr<particle_istream>( new empty_particle_istream( pEvalContext->GetDefaultChannels() ) );

    float percent = m_percentRenderer.at_time( t ) * 0.01f;
    boost::int64_t limit = m_useRenderLimit.at_time( t )
                               ? static_cast<boost::int64_t>( m_renderLimit.at_time( t ) * 1000 )
                               : std::numeric_limits<boost::int64_t>::max();
    render::RENDER_LOAD_PARTICLE_MODE loadMode =
        static_cast<render::RENDER_LOAD_PARTICLE_MODE>( (int)m_renderLoadMode.at_time( t ) );
    // bool loadEvenly = (m_renderLoadMode.at_time(t) == render::PARTICLELOAD_EVENLY_DISTRIBUTE);

    boost::shared_ptr<volume_collection> pCullingVolume = GetCullingVolume( t );

    boost::shared_ptr<particle_istream> pin;
    pin = GetFileParticleStream( pEvalContext->GetDefaultChannels(), t, 0x02, true );
    pin = GetObjectSpaceParticleStream( pin, percent, limit, loadMode, t, timeStep );
    pin = GetWorldSpaceParticleStream( pin, pNode, t, inoutValidity, pEvalContext, pCullingVolume, true );

    // Account for the density change due to loading only a fraction of the particles.
    if( percent > 0 && percent < 1 )
        pin.reset( new density_scale_particle_istream( pin, 1.f / percent ) );

    // render::COLORMODE cMode = static_cast<render::COLORMODE>( (int)m_particleColorSource.at_time(t) );
    pin = GetShadedParticleStream( pin, pNode, t, inoutValidity, pEvalContext, true );

    return pin;
}

void MaxKrakatoaPRTLoader::get_render_channels( INode* pNode, frantic::channels::channel_map& outMap ) {
    using namespace frantic::particles::streams;

    std::vector<boost::shared_ptr<particle_istream>> pins;
    for( size_t i = 0; i < m_fileList.size(); ++i ) {
        if( ( m_fileListFlags[(int)i].at_time( 0 ) & 0x02 ) == 0 )
            continue;

        M_STD_STRING filename = m_fileList[(int)i].at_time( 0 );
        pins.push_back( particle_file_istream_factory( filename ) );

        pins.back() = frantic::max3d::particles::streams::convert_time_channels_to_seconds( pins.back() );
    }

    if( pins.size() == 0 ) {
        outMap.end_channel_definition();
        return;
    }

    boost::shared_ptr<particle_istream> pin;
    if( pins.size() == 1 )
        pin = pins[0];
    else
        pin.reset( new concatenated_particle_istream( pins ) );

    boost::shared_ptr<volume_collection> pCullingVolume;
    frantic::max3d::shaders::renderInformation renderInfo;
    render::RENDER_LOAD_PARTICLE_MODE loadMode = render::PARTICLELOAD_FIRST_N;

    // frantic::channels::channel_map channelMap;
    // channelMap.define_channel<vector3f>( _T("Position") );
    // channelMap.end_channel_definition();

    TimeValue t = GetCOREInterface()->GetTime();

    Interval validity = FOREVER;

    // boost::scoped_ptr<IMaxKrakatoaPRTObject::IEvalContext> theContext(
    // IMaxKrakatoaPRTObject::CreateDefaultEvalContext( channelMap, frantic::graphics::camera(), t ) );
    frantic::max3d::particles::IMaxKrakatoaPRTEvalContextPtr theContext =
        frantic::max3d::particles::CreateMaxKrakatoaPRTEvalContext( t, Class_ID( 0, 0 ) );

    pin = GetObjectSpaceParticleStream( pin, 1.0f, INT_MAX, loadMode, t, 0 );
    pin = GetWorldSpaceParticleStream( pin, pNode, t, validity, theContext, pCullingVolume, true );
    pin = GetShadedParticleStream( pin, pNode, t, validity, theContext, true );

    outMap = pin->get_native_channel_map();
}

int MaxKrakatoaPRTLoader::GetFileParticleCount( FPTimeValue t ) {
    boost::shared_ptr<particle_istream> pin;
    pin = GetFileParticleStream( m_channelMap, t, 0x00, false );

    return static_cast<int>( pin->particle_count() );
}

int MaxKrakatoaPRTLoader::GetViewParticleCount( FPTimeValue t ) {
    boost::shared_ptr<particle_istream> pin;
    pin = GetFileParticleStream( m_channelMap, t, 0x01, false );

    float fraction = m_percentRenderer.at_time( t ) * m_percentViewport.at_time( t ) * 0.0001f;
    int limit = m_useViewportLimit.at_time( t ) ? static_cast<int>( m_viewportLimit.at_time( t ) * 1000 )
                                                : std::numeric_limits<int>::max();

    return math::clamp( static_cast<int>( pin->particle_count() * fraction ), 0, limit );
}

int MaxKrakatoaPRTLoader::GetRenderParticleCount( FPTimeValue t ) {
    boost::shared_ptr<particle_istream> pin;
    pin = GetFileParticleStream( m_channelMap, t, 0x02, false );

    float fraction = m_percentRenderer.at_time( t ) * 0.01f;
    int limit = m_useRenderLimit.at_time( t ) ? static_cast<int>( m_renderLimit.at_time( t ) * 1000 )
                                              : std::numeric_limits<int>::max();

    return math::clamp( static_cast<int>( pin->particle_count() * fraction ), 0, limit );
}

bool MaxKrakatoaPRTLoader::DoesModifyParticles() {
    TimeValue t = GetCOREInterface()->GetTime();

    return ( m_particleColorSource.at_time( t ) != render::COLORMODE_FILE_COLOR || m_resetDensities.at_time( t ) ||
             m_useCullingGizmo.at_time( t ) || m_enablePlaybackGraph.at_time( t ) );
}

bool MaxKrakatoaPRTLoader::EnabledInRender() {
    TimeValue t = GetCOREInterface()->GetTime();
    return m_enabledInRender.at_time( t );
}

#if MAX_VERSION_MAJOR >= 17

void MaxKrakatoaPRTLoader::WSStateInvalidate() {
    if( m_initialized ) {
        ULONG handle = 0;
        INode* currentNode = GetWorldSpaceObjectNode();

        if( currentNode ) {
            std::vector<frantic::max3d::particles::modifier_info_t> theMods;
            frantic::max3d::collect_node_modifiers( currentNode, theMods );

            std::vector<frantic::max3d::particles::modifier_info_t>::iterator it = theMods.begin();
            bool doGPUUpdate = false;
            for( it; it != theMods.end(); ++it ) {
                frantic::tstring name = it->first->GetName();
                if( name.find( _T( "Magma" ) ) != frantic::tstring::npos ) {
                    doGPUUpdate = true;
                    break;
                }
            }

            Box3 boundingBox = m_cachedWorldParticles[currentNode].boundBox;

            TimeValue currentTime = GetCOREInterface()->GetTime();

            UpdateParticlesRenderItem( currentTime, boundingBox, currentNode, doGPUUpdate );
        }
    }
}

unsigned long MaxKrakatoaPRTLoader::GetObjectDisplayRequirement() const { return 0; }

bool MaxKrakatoaPRTLoader::PrepareDisplay( const MaxSDK::Graphics::UpdateDisplayContext& /*prepareDisplayContext*/ ) {

    return true;
}

bool MaxKrakatoaPRTLoader::UpdatePerNodeItems( const MaxSDK::Graphics::UpdateDisplayContext& updateDisplayContext,
                                               MaxSDK::Graphics::UpdateNodeContext& nodeContext,
                                               MaxSDK::Graphics::IRenderItemContainer& targetRenderItemContainer ) {

    TimeValue t = updateDisplayContext.GetDisplayTime();
    CacheParticlesAtTime( t, nodeContext.GetRenderNode().GetMaxNode(),
                          &GetCOREInterface7()->getViewExp( GetCOREInterface7()->getActiveViewportIndex() ) );
    Box3 boundingBox = m_cachedWorldParticles[nodeContext.GetRenderNode().GetMaxNode()].boundBox;

    targetRenderItemContainer.ClearAllRenderItems();

    // Generate and add the render item for particles
    GenerateParticlesRenderItem( t, boundingBox, nodeContext );
    targetRenderItemContainer.AddRenderItem( m_markerRenderItem );

    // If the icon should be shown, generate and add its render item
    if( m_showIcon.at_time( t ) ) {
        GenerateIconRenderItem( t );
        targetRenderItemContainer.AddRenderItem( m_iconRenderItem );
    }

    // If the bounding box should be shown, generate and add its render item
    if( m_showBoundingBox.at_time( t ) ) {
        GenerateBoundingBoxRenderItem( t, boundingBox );
        targetRenderItemContainer.AddRenderItem( m_boundsRenderItem );
    }

    m_initialized = true;

    return true;
}

bool MaxKrakatoaPRTLoader::UpdatePerViewItems( const MaxSDK::Graphics::UpdateDisplayContext& /*updateDisplayContext*/,
                                               MaxSDK::Graphics::UpdateNodeContext& /*nodeContext*/,
                                               MaxSDK::Graphics::UpdateViewContext& /*viewContext*/,
                                               MaxSDK::Graphics::IRenderItemContainer& /*targetRenderItemContainer*/ ) {

    // TimeValue t = updateDisplayContext.GetDisplayTime();
    // CacheParticlesAtTime(t, nodeContext.GetRenderNode().GetMaxNode(), viewContext.GetView());

    return true;
}

frantic::max3d::viewport::render_type MaxKrakatoaPRTLoader::GetCurrentDisplayMode() {
    TimeValue currentTime = GetCOREInterface()->GetTime();
    switch( m_viewportParticleDisplayMode.at_time( currentTime ) ) {
    default:
    case ::viewport::DISPLAYMODE_DOT1:
        return frantic::max3d::viewport::RT_POINT;
        break;
    case ::viewport::DISPLAYMODE_DOT2: {
        return frantic::max3d::viewport::RT_POINT_LARGE;
        break;
    }
    case ::viewport::DISPLAYMODE_VELOCITY: {
        return frantic::max3d::viewport::RT_VELOCITY;
        break;
    }
    case ::viewport::DISPLAYMODE_NORMAL: {
        return frantic::max3d::viewport::RT_NORMAL;
        break;
    }
    case ::viewport::DISPLAYMODE_TANGENT: {
        return frantic::max3d::viewport::RT_TANGENT;
        break;
    }
    }

    return frantic::max3d::viewport::RT_POINT;
}

void MaxKrakatoaPRTLoader::GenerateParticlesRenderItem( TimeValue& t, Box3& boundingBox,
                                                        MaxSDK::Graphics::UpdateNodeContext& nodeContext ) {
    boost::filesystem::path shaderPath( frantic::win32::GetModuleFileName( hInstance ) );
    shaderPath =
        ( shaderPath.parent_path() / _T( "\\..\\Shaders\\particle_small.fx" ) ).string<frantic::tstring>().c_str();
    if( !boost::filesystem::exists( shaderPath ) ) {
        FF_LOG( error ) << shaderPath.c_str() << " doesn't exist. Please re-install KrakatoaMX.";
    }

    std::auto_ptr<frantic::max3d::viewport::ParticleRenderItem<>> newRenderItem(
        new frantic::max3d::viewport::ParticleRenderItem<>( shaderPath.c_str() ) );

    frantic::particles::particle_array pc = m_cachedWorldParticles[nodeContext.GetRenderNode().GetMaxNode()].particles;

    frantic::max3d::viewport::render_type renderType = GetCurrentDisplayMode();

    newRenderItem->Initialize( pc, renderType, m_scaleNormals.at_time( t ) );

    Point3 p( 0.5f * ( boundingBox.pmax.x + boundingBox.pmin.x ), 0.5f * ( boundingBox.pmax.y + boundingBox.pmin.y ),
              boundingBox.pmax.z );

    if( m_showCountInViewport.at_time( t ) ) {
        M_STD_STRING msg = boost::lexical_cast<M_STD_STRING>( pc.size() );
        newRenderItem->SetMessage( p, const_cast<MCHAR*>( msg.c_str() ) );
    }

    m_markerRenderItem.Release();
    m_markerRenderItem.Initialize();
    m_markerRenderItem.SetCustomImplementation( newRenderItem.release() );
}

void MaxKrakatoaPRTLoader::UpdateParticlesRenderItem( TimeValue& t, Box3& boundingBox, INode* nodeContext,
                                                      bool doGPUUpload ) {
    auto uncheckedCurrentRenderItem = m_markerRenderItem.GetCustomeImplementation();
    TimeValue currentTime = GetCOREInterface()->GetTime();

    frantic::max3d::viewport::render_type renderType = GetCurrentDisplayMode();

    frantic::particles::particle_array pc = m_cachedWorldParticles[nodeContext].particles;

    if( uncheckedCurrentRenderItem ) {
        frantic::max3d::viewport::ParticleRenderItem<>* currentRenderItem =
            dynamic_cast<frantic::max3d::viewport::ParticleRenderItem<>*>( uncheckedCurrentRenderItem );

        if( currentRenderItem ) {

            Point3 p( 0.5f * ( boundingBox.pmax.x + boundingBox.pmin.x ),
                      0.5f * ( boundingBox.pmax.y + boundingBox.pmin.y ), boundingBox.pmax.z );

            if( m_showCountInViewport.at_time( t ) ) {
                M_STD_STRING msg = boost::lexical_cast<M_STD_STRING>( pc.size() );
                currentRenderItem->SetMessage( p, const_cast<MCHAR*>( msg.c_str() ) );
            }

            if( doGPUUpload ) {
                currentRenderItem->Initialize( pc, renderType,
                                               m_scaleNormals.at_time( GetCOREInterface()->GetTime() ) );
            }
        }
    }
}

void MaxKrakatoaPRTLoader::GenerateIconRenderItem( TimeValue& t ) {
    float scale = m_iconSize.at_time( t );
    MaxSDK::Graphics::Matrix44 iconTM;
    Point3 scalePoint = Point3( scale, scale, scale );
    m_viewportData.m_iconTM.SetScale( scalePoint );
    MaxSDK::Graphics::MaxWorldMatrixToMatrix44( iconTM, m_viewportData.m_iconTM );

#if MAX_VERSION_MAJOR >= 25
    std::auto_ptr<MaxSDK::Graphics::Utilities::MeshEdgeRenderItem> iconImpl(
        new frantic::max3d::viewport::DecoratedMeshEdgeRenderItem( GetPRTLoaderIconMeshShared(), false, iconTM ) );
#else
    std::auto_ptr<MaxSDK::Graphics::Utilities::MeshEdgeRenderItem> iconImpl(
        new frantic::max3d::viewport::DecoratedMeshEdgeRenderItem( GetPRTLoaderIconMesh(), false, false, iconTM ) );
#endif

    m_iconRenderItem.Release();
    m_iconRenderItem.Initialize();
    m_iconRenderItem.SetCustomImplementation( iconImpl.release() );
}

void MaxKrakatoaPRTLoader::GenerateBoundingBoxRenderItem( TimeValue& /*t*/, Box3& boundingBox ) {
    std::auto_ptr<frantic::max3d::viewport::BoxRenderItem> boundsImpl( new frantic::max3d::viewport::BoxRenderItem );

    boundsImpl->Initialize( boundingBox );

    m_boundsRenderItem.Release();
    m_boundsRenderItem.Initialize();
    m_boundsRenderItem.SetCustomImplementation( boundsImpl.release() );
}

using namespace frantic::max3d;

void MaxKrakatoaPRTLoader::addPointsForDots( std::vector<Point3, std::allocator<Point3>>& pointVector,
                                             frantic::particles::particle_array& pc ) {

    for( particle_array::iterator it = pc.begin(); it != pc.end(); ++it ) {
        Point3 currentP = to_max_t( m_posAccessor.get( *it ) );
        pointVector.push_back( currentP );
    }
}

void MaxKrakatoaPRTLoader::addPointsForVelocity( std::vector<Point3, std::allocator<Point3>>& pointVector,
                                                 frantic::particles::particle_array& pc ) {

    for( particle_array::iterator it = pc.begin(); it != pc.end(); ++it ) {
        Point3 currentP = to_max_t( m_posAccessor.get( *it ) );
        Point3 velocityP = currentP + to_max_t( m_velocityAccessor.get( *it ) );
        pointVector.push_back( currentP );
        pointVector.push_back( velocityP );
    }
}

void MaxKrakatoaPRTLoader::addPointsForNormals( std::vector<Point3, std::allocator<Point3>>& pointVector,
                                                frantic::particles::particle_array& pc, TimeValue& t ) {

    for( particle_array::iterator it = pc.begin(); it != pc.end(); ++it ) {
        float scaleNormals = m_scaleNormals.at_time( t );
        Point3 currentP = to_max_t( m_posAccessor.get( *it ) );
        Point3 normalP = currentP + to_max_t( scaleNormals * m_normalAccessor.get( *it ) );
        pointVector.push_back( currentP );
        pointVector.push_back( normalP );
    }
}

void MaxKrakatoaPRTLoader::addPointsForTangents( std::vector<Point3, std::allocator<Point3>>& pointVector,
                                                 frantic::particles::particle_array& pc, TimeValue& t ) {

    for( particle_array::iterator it = pc.begin(); it != pc.end(); ++it ) {
        float scaleNormals = m_scaleNormals.at_time( t );
        Point3 currentP = to_max_t( m_posAccessor.get( *it ) );
        Point3 tangentP = currentP + to_max_t( scaleNormals * m_tangentAccessor.get( *it ) );
        pointVector.push_back( currentP );
        pointVector.push_back( tangentP );
    }
}

void MaxKrakatoaPRTLoader::addColorData( std::vector<Point4, std::allocator<Point4>>& colorVector,
                                         frantic::particles::particle_array& pc, int times ) {

    for( particle_array::iterator it = pc.begin(); it != pc.end(); ++it ) {
        for( int i = 0; i < times; i++ ) {
            frantic::graphics::color3f c = m_colorAccessor.get( *it );
            Point4 colorPoint;
            colorPoint.x = c.r;
            colorPoint.y = c.g;
            colorPoint.z = c.b;
            colorVector.push_back( colorPoint );
        }
    }
}
#endif
