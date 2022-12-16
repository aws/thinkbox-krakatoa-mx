// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0
#include "stdafx.h"

#include "MaxKrakatoaGeometryRenderer.h"
#include <boost/bind.hpp>
#include <krakatoa/scene_context.hpp>

#include <frantic/graphics/cubeface.hpp>
#include <frantic/graphics/plane3f.hpp>
#include <frantic/graphics/vector4f.hpp>

#include <frantic/max3d/geometry/auto_mesh.hpp>
#include <frantic/max3d/geometry/mesh.hpp>
#include <frantic/max3d/geometry/null_view.hpp>
#include <frantic/max3d/rendering/renderplugin_utils.hpp>
#include <frantic/max3d/shaders/map_query.hpp>

#include <wchar.h>
#pragma warning( push, 3 )
#include <boost/thread/locks.hpp>
#include <boost/thread/mutex.hpp>
#include <boost/thread/thread.hpp>
#pragma warning( pop )

using namespace frantic::geometry;
using namespace frantic::graphics;
using namespace frantic::graphics2d;

using frantic::rendering::framebuffer_cubeface;

typedef boost::function<float( const raytrace_intersection& )> opacity_shader;

frantic::diagnostics::profiling_section g_psEvalWorldState( _T("MaxKrakatoaGeometryPrimitive::EvalWorldState()") );
frantic::diagnostics::profiling_section g_psEvalMotionTM( _T("MaxKrakatoaGeometryPrimitive::GetObjTMAfterWSM()") );
frantic::diagnostics::profiling_section g_psMtl( _T("MaxKrakatoaGeometryPrimitive::EvalMtl()") );
frantic::diagnostics::profiling_section g_psMeshCopy( _T("MaxKrakatoaGeometryPrimitive::MeshCopy()") );

//
//
// MaxKrakatoaMatteInterface class
//
//

void MaxKrakatoaMatteInterface::generate_depth_map( const frantic::graphics::camera<float>& renderCam, float mblurTime,
                                                    frantic::graphics2d::framebuffer<float>& outDepthImg,
                                                    bool forLight ) {

    // call parent class's function (it does all the work)
    matte_interface::generate_depth_map( renderCam, mblurTime, outDepthImg, forLight );

    // combine with the user-defined initial matte depth map
    if( m_initialMatteDepthmap && !forLight ) {
        frantic::rendering::depthbuffer_singleface tempBuffer;

        tempBuffer.set_with_swap( outDepthImg );
        tempBuffer.resample_combine( *m_initialMatteDepthmap );

        outDepthImg.swap( tempBuffer.as_framebuffer() );
    }
}

void MaxKrakatoaMatteInterface::set_initial_depthmap(
    boost::shared_ptr<frantic::rendering::depthbuffer_singleface> initialDepthmap ) {
    m_initialMatteDepthmap = initialDepthmap;
}

//
//
// MaxMattePrimitive class
//
//

// These are the various matte/shadow materials that people have a tendency to want to stick on matte objects when
// rendering with Krakatoa. Since they are completely the wrong materials for this, I need to special case them away.
// Details: They always report alpha of 0.
#define MatteShadow_CLASS_ID Class_ID( MATTE_CLASS_ID, 0 )
#define fR_MatteShadow_CLASS_ID Class_ID( 79703123, 139619938 )
#define MR_MatteShadow_CLASS_ID Class_ID( 2004030991, -1355984577 )

MaxMattePrimitive::MaxMattePrimitive( INode* pNode, Interval motionInterval, bool sampleGeometry, int numSegments )
    : m_pNode( pNode )
    , m_motionInterval( motionInterval )
    , m_sampleGeometry( sampleGeometry )
    , m_numSegments( numSegments )
    , m_globContext( NULL )
    , m_missingMaterial( boost::indeterminate ) {
    if( m_numSegments < 0 )
        m_numSegments = 1;

    m_currentSegment = std::numeric_limits<int>::max();
    m_alpha = 0;

    m_pMtl = m_pNode->GetMtl();
    if( m_pMtl ) {
        if( m_pMtl->ClassID() == MatteShadow_CLASS_ID || m_pMtl->ClassID() == fR_MatteShadow_CLASS_ID ||
            m_pMtl->ClassID() == MR_MatteShadow_CLASS_ID ) {
            m_pMtl = NULL;
        } else {
            TimeValue mtlTime = ( m_motionInterval.Start() + m_motionInterval.End() ) / 2;
            frantic::max3d::shaders::update_material_for_shading( m_pMtl, mtlTime );
        }
    }
}

void MaxMattePrimitive::update_accessors() {
    // TimeValue t = TimeValue( m_motionInterval.Start() + this->get_time() * ( m_motionInterval.End() -
    // m_motionInterval.Start() ) );
    // TODO: Allow sampling the material.

    BitArray reqMaps( MAX_MESHMAPS );
    frantic::max3d::shaders::collect_material_requirements( m_pMtl, reqMaps );

    m_uvwAccessors.clear();

    if( m_sampleGeometry && m_numSegments > 0 ) {
        if( reqMaps[0] && m_leftMesh.has_vertex_channel( _T("Color") ) &&
            m_rightMesh.has_vertex_channel( _T("Color") ) )
            m_uvwAccessors.push_back( accessor_type( 0, m_leftMesh.get_vertex_channel_general_accessor( _T("Color") ),
                                                     m_rightMesh.get_vertex_channel_general_accessor( _T("Color") ) ) );
        if( reqMaps[1] && m_leftMesh.has_vertex_channel( _T("TextureCoord") ) &&
            m_rightMesh.has_vertex_channel( _T("TextureCoord") ) )
            m_uvwAccessors.push_back(
                accessor_type( 1, m_leftMesh.get_vertex_channel_general_accessor( _T("TextureCoord") ),
                               m_rightMesh.get_vertex_channel_general_accessor( _T("TextureCoord") ) ) );

        for( int i = 2; i < MAX_MESHMAPS; ++i ) {
            if( reqMaps[i] ) {
                M_STD_STRING channelName = _T("Mapping") + boost::lexical_cast<M_STD_STRING>( i );
                if( m_leftMesh.has_vertex_channel( channelName ) && m_rightMesh.has_vertex_channel( channelName ) )
                    m_uvwAccessors.push_back(
                        accessor_type( i, m_leftMesh.get_vertex_channel_general_accessor( channelName ),
                                       m_rightMesh.get_vertex_channel_general_accessor( channelName ) ) );
            }
        }
    } else {
        // Use a dummy accessor since we are looking up values from a single mesh.
        frantic::geometry::const_trimesh3_vertex_channel_general_accessor dummyAcc;

        if( reqMaps[0] && m_currentMesh.has_vertex_channel( _T("Color") ) )
            m_uvwAccessors.push_back(
                accessor_type( 0, m_currentMesh.get_vertex_channel_general_accessor( _T("Color") ), dummyAcc ) );
        if( reqMaps[1] && m_currentMesh.has_vertex_channel( _T("TextureCoord") ) )
            m_uvwAccessors.push_back(
                accessor_type( 1, m_currentMesh.get_vertex_channel_general_accessor( _T("TextureCoord") ), dummyAcc ) );

        for( int i = 2; i < MAX_MESHMAPS; ++i ) {
            if( reqMaps[i] ) {
                M_STD_STRING channelName = _T("Mapping") + boost::lexical_cast<M_STD_STRING>( i );
                if( m_currentMesh.has_vertex_channel( channelName ) )
                    m_uvwAccessors.push_back( accessor_type(
                        i, m_currentMesh.get_vertex_channel_general_accessor( channelName ), dummyAcc ) );
            }
        }
    }

    if( frantic::logging::is_logging_debug() ) {
        frantic::logging::debug << _T("Matte node \"") << m_pNode->GetName() << _T("\" has opacity mapping enabled.")
                                << std::endl;
        for( int i = 0; i < (int)m_uvwAccessors.size(); ++i )
            frantic::logging::debug << _T("\tRequires map channel: ") << m_uvwAccessors[i].get<0>() << std::endl;
    }
}

bool MaxMattePrimitive::is_visible_to_lights() const { return ( m_pNode->CastShadows() != FALSE ); }

bool MaxMattePrimitive::is_visible_to_cameras() const { return ( m_pNode->GetPrimaryVisibility() != FALSE ); }

void MaxMattePrimitive::set_time( float motionSegmentTime ) {
    matte_primitive::set_time( motionSegmentTime );

    if( m_numSegments > 0 ) {
        int segment = (int)floor( motionSegmentTime * m_numSegments );
        if( segment == m_numSegments )
            segment = m_numSegments - 1;

        float segmentStart = (float)segment / (float)m_numSegments;
        float segmentEnd = (float)( segment + 1 ) / (float)m_numSegments;

        TimeValue tStart = TimeValue( m_motionInterval.Start() +
                                      segmentStart * ( m_motionInterval.End() - m_motionInterval.Start() ) );
        TimeValue tEnd =
            TimeValue( m_motionInterval.Start() + segmentEnd * ( m_motionInterval.End() - m_motionInterval.Start() ) );

        if( segment != m_currentSegment ) {
            // Check if we can re-use previously cached data when moving to the next segment.
            if( segment == m_currentSegment + 1 ) {
                if( m_sampleGeometry )
                    m_leftMesh.swap( m_rightMesh );
                m_leftTM = m_rightTM;
            } else {
                if( m_sampleGeometry ) {
                    m_leftMesh.clear();

                    frantic::max3d::geometry::null_view nullView;
                    frantic::max3d::geometry::AutoMesh maxMesh;

                    maxMesh = frantic::max3d::geometry::get_mesh_from_inode( m_pNode, tStart, nullView );
                    frantic::max3d::geometry::mesh_copy( m_leftMesh, *maxMesh.get(), !m_pMtl );
                }
                m_leftTM = frantic::max3d::from_max_t( m_pNode->GetObjTMAfterWSM( tStart ) );
            }

            if( m_sampleGeometry ) {
                m_rightMesh.clear();

                frantic::max3d::geometry::null_view nullView;
                frantic::max3d::geometry::AutoMesh maxMesh;

                maxMesh = frantic::max3d::geometry::get_mesh_from_inode( m_pNode, tEnd, nullView );
                frantic::max3d::geometry::mesh_copy( m_rightMesh, *maxMesh.get(), !m_pMtl );

                if( m_leftMesh.vertex_count() != m_rightMesh.vertex_count() ) {
                    // The number of vertices changed but we are trying to interpolate. This is grade A+ badness. I'm
                    // not sure what to do other than toss an exception. Ideally we would like to tell the user at the
                    // start of the render so time isn't wasted, but that check is very expensive in some (common)
                    // cases. The performance considerations is deemed more important in this case.
                    std::basic_stringstream<MCHAR> ss;
                    ss << _T("The node: \"") << m_pNode->GetName() << _T("\" had ") << m_leftMesh.vertex_count()
                       << _T(" vertices at time (in ticks): ") << tStart << _T(" and ") << m_rightMesh.vertex_count()
                       << _T(" vertices at time (in ticks): ") << tEnd
                       << _T(" so interpolation of the mesh for motion blur is not possible.");

                    throw std::runtime_error( frantic::strings::to_string( ss.str() ) );
                }
            }
            m_rightTM = frantic::max3d::from_max_t( m_pNode->GetObjTMAfterWSM( tEnd ) );
        }

        m_currentSegment = segment;

        m_alpha = ( motionSegmentTime - segmentStart ) / ( segmentEnd - segmentStart );
        m_currentTM = frantic::graphics::transform4f::linear_interpolate( m_leftTM, m_rightTM, m_alpha );
    } else {
        TimeValue t = TimeValue( m_motionInterval.Start() +
                                 motionSegmentTime * ( m_motionInterval.End() - m_motionInterval.Start() ) );

        if( m_sampleGeometry ) {
            m_currentMesh.clear();

            frantic::max3d::geometry::null_view nullView;
            frantic::max3d::geometry::AutoMesh maxMesh;

            maxMesh = frantic::max3d::geometry::get_mesh_from_inode( m_pNode, t, nullView );
            frantic::max3d::geometry::mesh_copy( m_currentMesh, *maxMesh.get(), !m_pMtl );
        }

        m_currentTM = frantic::max3d::from_max_t( m_pNode->GetObjTMAfterWSM( t ) );
    }

    // If we aren't sampling geometry we need to have cached the geometry at least once.
    // TODO: Its probably better style to use a boolean flag than having vertex_count() == 0.
    if( !m_sampleGeometry && m_currentMesh.vertex_count() == 0 ) {
        TimeValue t = ( m_motionInterval.Start() + m_motionInterval.End() ) / 2;

        frantic::max3d::geometry::null_view nullView;
        frantic::max3d::geometry::AutoMesh maxMesh;

        maxMesh = frantic::max3d::geometry::get_mesh_from_inode( m_pNode, t, nullView );
        frantic::max3d::geometry::mesh_copy( m_currentMesh, *maxMesh.get(), !m_pMtl );
    }

    if( m_pMtl )
        update_accessors();
}

void MaxMattePrimitive::get_triangle( std::size_t index, frantic::graphics::vector3f outVertices[] ) const {
    if( m_sampleGeometry && m_numSegments > 0 ) {
        frantic::graphics::vector3 f = m_leftMesh.get_face( index );
        outVertices[0] = m_leftMesh.get_vertex( f.x );
        outVertices[0] += m_alpha * ( m_rightMesh.get_vertex( f.x ) - outVertices[0] );
        outVertices[1] = m_leftMesh.get_vertex( f.y );
        outVertices[1] += m_alpha * ( m_rightMesh.get_vertex( f.y ) - outVertices[1] );
        outVertices[2] = m_leftMesh.get_vertex( f.z );
        outVertices[2] += m_alpha * ( m_rightMesh.get_vertex( f.z ) - outVertices[2] );
    } else {
        frantic::graphics::vector3 f = m_currentMesh.get_face( index );
        outVertices[0] = m_currentMesh.get_vertex( f.x );
        outVertices[1] = m_currentMesh.get_vertex( f.y );
        outVertices[2] = m_currentMesh.get_vertex( f.z );
    }
}

std::size_t MaxMattePrimitive::get_triangle_count() const {
    if( m_sampleGeometry && m_numSegments > 0 ) {
        return m_leftMesh.face_count();
    } else {
        return m_currentMesh.face_count();
    }
}

frantic::graphics::transform4f MaxMattePrimitive::get_transform() const { return m_currentTM; }

inline Point3 reflect( const Point3& v, const Point3& n ) { return v - 2 * DotProd( v, n ) * n; }

void MaxMattePrimitive::get_mesh_copy( frantic::geometry::trimesh3& outMesh ) const {
    // We need to interpolate the mesh since it isn't currently cached.
    if( m_sampleGeometry && m_numSegments > 0 )
        outMesh.linear_interpolation( m_leftMesh, m_rightMesh, m_alpha );
    outMesh = m_currentMesh; // returns a *COPY* of the mesh.
}

class MatteOpacityShadeContext : public ShadeContext {
    // RenderGlobalContext m_globContext;
    Point3 m_pos, m_norm, m_origNorm, m_view, m_origView, m_baryC;
    int m_faceIndex;

  public:
    MatteOpacityShadeContext( const RenderGlobalContext* globContext,
                              const frantic::geometry::raytrace_intersection& ri ) {
        m_faceIndex = ri.faceIndex;
        m_pos = frantic::max3d::to_max_t( ri.position );
        m_norm = m_origNorm = frantic::max3d::to_max_t( ri.geometricNormal );
        m_view = m_origView = frantic::max3d::to_max_t( ri.ray.direction() );
        m_baryC = frantic::max3d::to_max_t( ri.barycentricCoords );

        this->ambientLight.Black();
        this->atmosSkipLight = NULL;
        this->backFace = FALSE;
        this->doMaps = TRUE;
        this->filterMaps = TRUE;
        // this->globContext = &m_globContext;
        this->globContext = const_cast<RenderGlobalContext*>( globContext );
        this->mode = SCMODE_SHADOW;
        this->mtlNum = 0;
        this->nLights = 0;
        this->rayLevel = 0;
        this->shadow = FALSE;
        this->xshadeID = 0;

        // frantic::max3d::rendering::initialize_renderglobalcontext( m_globContext );

        // m_globContext.time = t;
        // m_globContext.
    }

    Point3 uvwArray[MAX_MESHMAPS];

    virtual BOOL InMtlEditor() { return FALSE; }
    virtual int Antialias() { return TRUE; }
    virtual int ProjType() { return PROJ_PERSPECTIVE; }
    virtual LightDesc* Light( int n ) { return NULL; }
    virtual TimeValue CurTime() { return globContext->time; }
    virtual int NodeID() { return -1; }
    virtual INode* Node() { return NULL; }
    virtual Object* GetEvalObject() { return NULL; }
    virtual Point3 BarycentricCoords() { return m_baryC; }
    virtual int FaceNumber() { return m_faceIndex; }
    virtual Point3 Normal() { return m_norm; }
    virtual void SetNormal( Point3 p ) { m_norm = p; }
    virtual Point3 OrigNormal() { return m_origNorm; }
    virtual Point3 GNormal() { return m_origNorm; }
    virtual float Curve() { return 0.f; }
    virtual Point3 V() { return m_view; }
    virtual void SetView( Point3 p ) { m_view = p; }
    virtual Point3 OrigView() { return m_origView; }
    virtual Point3 ReflectVector() { return reflect( m_view, m_norm ); }
    virtual Point3 RefractVector( float /*ior*/ ) { return m_view; }
    virtual void SetIOR( float /*ior*/ ) {}
    virtual float GetIOR() { return 1.f; }
    virtual Point3 CamPos() { return Point3( 0, 0, 0 ); }
    virtual Point3 P() { return m_pos; }
    virtual Point3 DP() { return Point3( 0, 0, 0 ); }
    virtual void DP( Point3& dpdx, Point3& dpdy ) {
        dpdx = Point3( 0, 0, 0 );
        dpdy = Point3( 0, 0, 0 );
    }
    virtual Point3 PObj() { return Point3( 0, 0, 0 ); }
    virtual Point3 DPObj() { return Point3( 0, 0, 0 ); }
    virtual Box3 ObjectBox() { return Box3( Point3( 0, 0, 0 ), Point3( 0, 0, 0 ) ); }
    virtual Point3 PObjRelBox() { return Point3( 0, 0, 0 ); }
    virtual Point3 DPObjRelBox() { return Point3( 0, 0, 0 ); }
    virtual void ScreenUV( Point2& uv, Point2& duv ) {
        uv = Point2( 0.f, 0.f );
        duv = Point2( 0.f, 0.f );
    }
    virtual IPoint2 ScreenCoord() { return IPoint2( 0, 0 ); }
    virtual Point2 SurfacePtScreen() { return Point2( 0.f, 0.f ); }
    virtual Point3 UVW( int channel = 0 );
    virtual Point3 DUVW( int /*channel=0*/ ) { return Point3( 0, 0, 0 ); }
    virtual void DPdUVW( Point3 dP[3], int /*channel=0*/ ) { dP[0] = dP[1] = dP[2] = Point3( 0, 0, 0 ); }
    // virtual int BumpBasisVectors (Point3 dP[2], int axis, int channel=0)
    // virtual BOOL IsSuperSampleOn ()
    // virtual BOOL IsTextureSuperSampleOn ()
    // virtual int GetNSuperSample ()
    // virtual float GetSampleSizeScale ()
    // virtual Point3 UVWNormal (int channel=0)
    // virtual float RayDiam ()
    // virtual float RayConeAngle ()
    // virtual CoreExport AColor EvalEnvironMap (Texmap *map, Point3 view)
    virtual void GetBGColor( Color& bgcol, Color& transp, BOOL /*fogBG=TRUE*/ ) {
        bgcol.Black();
        transp.Black();
    }
    // virtual float CamNearRange ()
    // virtual float CamFarRange ()
    virtual Point3 PointTo( const Point3& p, RefFrame /*ito*/ ) { return p; }
    virtual Point3 PointFrom( const Point3& p, RefFrame /*ifrom*/ ) { return p; }
    virtual Point3 VectorTo( const Point3& p, RefFrame /*ito*/ ) { return p; }
    virtual Point3 VectorFrom( const Point3& p, RefFrame /*ifrom*/ ) { return p; }
};

Point3 MatteOpacityShadeContext::UVW( int channel ) { return uvwArray[channel]; }

float MaxMattePrimitive::get_opacity( const frantic::geometry::raytrace_intersection& ri ) const {
    if( !m_pMtl )
        return 1.f;

    // Need to ensure that there are no missing materials and textures in order to avoid some rendering anomolies
    // that occur when a plugin is installed on a workstation, but not the farm computers.
    if( missing_material() )
        return 1.f;

    TimeValue t = TimeValue( m_motionInterval.Start() +
                             this->get_time() * ( m_motionInterval.End() - m_motionInterval.Start() ) );

    // MatteOpacityShadeContext sc( ri, t );
    MatteOpacityShadeContext sc( this->m_globContext, ri );
    /*frantic::max3d::shaders::multimapping_shadecontext sc;
    sc.position = frantic::max3d::to_max_t(ri.position);
    sc.normal = frantic::max3d::to_max_t(ri.geometricNormal);
    sc.shadeTime = TimeValue( m_motionInterval.Start() + this->get_time() * ( m_motionInterval.End() -
    m_motionInterval.Start() ) ); sc.mtlNum = 0;*/

    if( !m_sampleGeometry || m_numSegments == 0 ) {
        for( std::size_t i = 0; i < m_uvwAccessors.size(); ++i )
            m_uvwAccessors[i].get<1>().get_barycentric( ri.faceIndex, ri.barycentricCoords,
                                                        (char*)( sc.uvwArray + m_uvwAccessors[i].get<0>() ) );
    } else {
        frantic::graphics::vector3f uvw[2];
        for( std::size_t i = 0; i < m_uvwAccessors.size(); ++i ) {
            m_uvwAccessors[i].get<1>().get_barycentric( ri.faceIndex, ri.barycentricCoords, (char*)( &uvw[0] ) );
            m_uvwAccessors[i].get<2>().get_barycentric( ri.faceIndex, ri.barycentricCoords, (char*)( &uvw[1] ) );
            sc.uvwArray[m_uvwAccessors[i].get<0>()] =
                frantic::max3d::to_max_t( frantic::graphics::linear_interpolate( uvw[0], uvw[1], m_alpha ) );
        }
    }

    m_pMtl->Shade( sc );

    return 1.f - Intens( sc.out.t );
}

// Check the materials to see if there are any missing materials or texture maps.
bool MaxMattePrimitive::missing_material() const {
    if( boost::indeterminate( m_missingMaterial ) ) {
        m_missingMaterial = missing_material_recursive( m_pMtl );
    }

    return static_cast<bool>( m_missingMaterial );
}

bool MaxMattePrimitive::missing_material_recursive( Mtl* mtl ) const {

    // get the name of the material's class.
    MSTR className;
    mtl->GetClassName( className );
    frantic::tstring mtlClass = className.data();
    frantic::tstring mtlMissing = _T( "Missing Material" ); // name of the missing material class

    // if the class name matches the missing one or a texturemap involved is missing, set the flag.
    if( mtlClass == mtlMissing || missing_texturemap( mtl ) )
        return true;

    int numSubMtls = mtl->NumSubMtls();
    // recursively check the materials to see if they are missing, stop when a missing one is encountered.
    for( int i = 0; i < numSubMtls; ++i ) {
        Mtl* subMtl = mtl->GetSubMtl( i );

        // ensure the submaterial is non-null.
        if( subMtl && missing_material_recursive( subMtl ) ) {
            return true;
        }
    }

    return false;
}

bool MaxMattePrimitive::missing_texturemap( Mtl* mtl ) const {

    // check through all sub texturemaps to ensure none are missing.
    int subTexmaps = mtl->NumSubTexmaps();
    for( int i = 0; i < subTexmaps; ++i ) {
        Texmap* texMap = mtl->GetSubTexmap( i );

        // ensure the texturemap is non-null.
        if( texMap ) {
            MSTR className;
            texMap->GetClassName( className );
            frantic::tstring texName = className.data();
            frantic::tstring texMissing = _T( "Missing TextureMap" ); // name of the missing texturemap class.
            // check to see if missing, if not, continue searching.
            if( texName == texMissing || missing_texturemap_recursive( texMap ) ) {
                return true;
            }
        }
    }

    return false;
}

bool MaxMattePrimitive::missing_texturemap_recursive( Texmap* texMap ) const {

    // check through all sub texturemaps to ensure none are missing.
    int subTexmaps = texMap->NumSubTexmaps();
    for( int i = 0; i < subTexmaps; ++i ) {
        Texmap* subTexmap = texMap->GetSubTexmap( i );

        // ensure the texturemap is non-null.
        if( subTexmap ) {
            MSTR className;
            subTexmap->GetClassName( className );
            frantic::tstring texName = className.data();
            frantic::tstring texMissing = _T( "Missing TextureMap" ); // name of the missing texturemap class.
            // check to see if missing, if not, continue searching.
            if( texName == texMissing || missing_texturemap_recursive( subTexmap ) ) {
                return true;
            }
        }
    }

    return false;
}