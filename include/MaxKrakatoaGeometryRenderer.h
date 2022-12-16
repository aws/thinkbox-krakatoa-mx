// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0
#pragma once

#include <boost/logic/tribool.hpp>

#include <frantic/rendering/depthbuffer_singleface.hpp>

#include <frantic/geometry/matte_geometry_interface.hpp>
#include <frantic/geometry/primitive_kdtree.hpp>
#include <frantic/geometry/trimesh3_kdtree.hpp>
#include <frantic/graphics/motion_blurred_transform.hpp>
#include <frantic/graphics2d/framebuffer.hpp>
#include <frantic/rendering/framebuffer_cubeface.hpp>
#include <krakatoa/geometry_renderer.hpp>

/**
 * Implementation of the matte interface class for 3ds max renderer.
 * Used in the scene context object.
 */
class MaxKrakatoaMatteInterface : public krakatoa::matte_interface {
    boost::shared_ptr<frantic::rendering::depthbuffer_singleface> m_initialMatteDepthmap;

  public:
    typedef boost::shared_ptr<MaxKrakatoaMatteInterface> ptr_type;

  public:
    MaxKrakatoaMatteInterface( const krakatoa::scene_context_ptr context )
        : matte_interface( context ) {}

    // for a Max Krakatoa feature allow the user to select a pre-existing depth image to be combined with.
    void set_initial_depthmap( boost::shared_ptr<frantic::rendering::depthbuffer_singleface> initialDepthmap );

    // this implementation calls the superclass, but adds in the 3dsmax custom intial depthmap (as defined above)
    virtual void generate_depth_map( const frantic::graphics::camera<float>& renderCam, float mblurTime,
                                     frantic::graphics2d::framebuffer<float>& outDepthImg, bool forLight );
};

typedef MaxKrakatoaMatteInterface::ptr_type MaxKrakatoaMatteInterfacePtr;

/**
 * Implementation of the matte primitive for 3dsmax INodes
 * Objects of this type are used as a collection for the scene context.
 */
class MaxMattePrimitive : public krakatoa::matte_primitive {
    INode* m_pNode;
    Interval m_motionInterval;

    const RenderGlobalContext* m_globContext;

    bool m_sampleGeometry;
    int m_numSegments;

    float m_alpha;
    int m_currentSegment;

    mutable boost::tribool m_missingMaterial;

    // This transform stores the node's transform at the start of the current segment. Only populated if 'm_numSamples'
    // > 0.
    frantic::graphics::transform4f m_leftTM;

    // This transform stores the node's transform at the end of the current segment. Only populated if 'm_numSamples' >
    // 0.
    frantic::graphics::transform4f m_rightTM;

    // This transform stores the node's transform at the current time. It is interpolated from 'm_leftTM' and
    // 'm_rightTM' if 'm_numSamples' > 0, otherwise it is filled directly from the node.
    frantic::graphics::transform4f m_currentTM;

    // This mesh stores the geometry sampled at the start of the current segment. Only populated if 'm_sampleGeometry'
    // is true and 'm_numSamples' is > 0.
    frantic::geometry::trimesh3 m_leftMesh;

    // This mesh stores the geometry sampled at the end of the current segment. Only populated if 'm_sampleGeometry' is
    // true and 'm_numSamples' is > 0.
    frantic::geometry::trimesh3 m_rightMesh;

    // This mesh stores the geometry sampled at the current time. It is interpolated from 'm_leftMesh' and 'm_rightMesh'
    // if 'm_sampleGeometry' is true and 'm_numSamples' is > 0 and a call to get_mesh() is made. It is populated
    // directly from the node if 'm_sampleGeometry' is true and 'm_numSamples' == 0. If 'm_sampleGeometry' is false,
    // this will store a sample of the node's geometry at an arbitrary time in the motion interval (currently the
    // center).
    frantic::geometry::trimesh3 m_currentMesh;

    // Holds accessors for retrieving UVW data from a mesh for doing opacity shading. It stores two for interpolation
    // mode.
    typedef boost::tuple<int, frantic::geometry::const_trimesh3_vertex_channel_general_accessor,
                         frantic::geometry::const_trimesh3_vertex_channel_general_accessor>
        accessor_type;

    Mtl* m_pMtl;
    BitArray m_reqMaps;
    std::vector<accessor_type> m_uvwAccessors;

  private:
    void update_accessors();

  public:
    typedef boost::shared_ptr<MaxMattePrimitive> ptr_type;

  public:
    MaxMattePrimitive( INode* pNode, Interval motionInterval, bool sampleGeometry, int numSegments );

    void set_render_global_context( const RenderGlobalContext* globContext ) { m_globContext = globContext; }

    virtual bool is_visible_to_lights() const;

    virtual bool is_visible_to_cameras() const;

    virtual std::size_t get_triangle_count() const;

    virtual void get_triangle( std::size_t index, frantic::graphics::vector3f outVertices[] ) const;

    virtual float get_opacity( const frantic::geometry::raytrace_intersection& ri ) const;

    virtual frantic::graphics::transform4f get_transform() const;

    virtual void get_mesh_copy( frantic::geometry::trimesh3& outMesh ) const;

    virtual void set_time( float motionSegmentTime );

    bool missing_material() const;

    bool missing_material_recursive( Mtl* mtl ) const;

    bool missing_texturemap( Mtl* mtl ) const;

    bool missing_texturemap_recursive( Texmap* texMap ) const;
};

typedef MaxMattePrimitive::ptr_type MaxMattePrimitivePtr;
