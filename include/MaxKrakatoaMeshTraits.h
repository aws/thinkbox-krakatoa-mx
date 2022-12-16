// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0
#pragma once

#include <frantic/max3d/convert.hpp>

#include <frantic/geometry/raytracing.hpp>
#include <frantic/geometry/triangle_utils.hpp>

#pragma warning( push, 3 )
#include <render.h>
#pragma warning( pop )

// Max's CrossProd is a function call for some reason.
#define InlineCrossProd( a, b )                                                                                        \
    Point3( ( a.y * b.z ) - ( a.z * b.y ), ( a.z * b.x ) - ( a.x * b.z ), ( a.x * b.y ) - ( a.y * b.x ) )

struct MaxMeshTraits {
    typedef RenderInstance mesh_type;
    typedef const RenderInstance* mesh_type_const_ptr;

    typedef frantic::geometry::raytrace_intersection raytrace_result;
    typedef frantic::geometry::nearest_point_search_result nearest_point_result;

    inline static unsigned get_count( const mesh_type& inst ) { return static_cast<unsigned>( inst.mesh->numFaces ); }

    inline static frantic::graphics::boundbox3f get_bounds( const mesh_type& inst ) {
        return frantic::max3d::from_max_t( inst.obBox );
    }

    inline static frantic::graphics::boundbox3f get_clipped_bounds( const mesh_type& inst, unsigned index,
                                                                    const frantic::graphics::boundbox3f& bounds ) {
        Point3 tri[3];
        frantic::graphics::boundbox3f clippedBounds;

        const_cast<RenderInstance&>( inst ).GetObjVerts( (int)index, tri );

        bounds.intersect_with_triangle( frantic::max3d::from_max_t( tri[0] ), frantic::max3d::from_max_t( tri[1] ),
                                        frantic::max3d::from_max_t( tri[2] ), clippedBounds );

        return clippedBounds;
    }

    inline static bool intersect_ray( const mesh_type& inst, unsigned index, const frantic::graphics::ray3f& ray,
                                      double tMin, double tMax, raytrace_result& outIntersection,
                                      bool ignoreBackfaces = false ) {
        Point3 tri[3];

        const_cast<RenderInstance&>( inst ).GetObjVerts( (int)index, tri );

        Point3 p1p0 = tri[1] - tri[0];
        Point3 p2p0 = tri[2] - tri[0];
        Point3 pAp0 = frantic::max3d::to_max_t( ray.origin() ) - tri[0];
        Point3 d = frantic::max3d::to_max_t( ray.direction() );

        Point3 dXp2p0 = InlineCrossProd( d, p2p0 );
        Point3 pAp0Xp1p0 = InlineCrossProd( pAp0, p1p0 );

        float V = DotProd( dXp2p0, p1p0 );
        float Va = DotProd( pAp0Xp1p0, p2p0 );

        float t = Va / V;
        if( t < tMax && t > tMin ) {
            float V1 = DotProd( dXp2p0, pAp0 );
            float V2 = DotProd( pAp0Xp1p0, d );

            float b = V1 / V;
            float c = V2 / V;
            float a = 1.f - b - c;

            if( a >= 0 && b >= 0.f && c >= 0.f ) {
                if( ignoreBackfaces ) {
                    frantic::graphics::vector3f normal =
                        frantic::max3d::from_max_t( const_cast<mesh_type&>( inst ).GetFaceNormal( (int)index ) );
                    const bool notBackface = frantic::graphics::vector3f::dot( ray.direction(), normal ) <= 0;
                    if( notBackface ) {
                        outIntersection.distance = t;
                        outIntersection.faceIndex = (int)index;
                        outIntersection.barycentricCoords.x = a;
                        outIntersection.barycentricCoords.y = b;
                        outIntersection.barycentricCoords.z = c;
                    }
                    return notBackface;
                } else {
                    outIntersection.distance = t;
                    outIntersection.faceIndex = (int)index;
                    outIntersection.barycentricCoords.x = a;
                    outIntersection.barycentricCoords.y = b;
                    outIntersection.barycentricCoords.z = c;
                    return true;
                }
            }
        }

        return false;
    }

    inline static bool find_nearest_point( const mesh_type& inst, unsigned index,
                                           const frantic::graphics::vector3f& point, double maxDistance,
                                           nearest_point_result& outNearestPoint, bool ignoreBackfaces = false ) {
        Point3 tri[3];

        const_cast<RenderInstance&>( inst ).GetObjVerts( (int)index, tri );

        using frantic::graphics::vector3f;

        vector3f A = frantic::max3d::from_max_t( tri[0] ), B = frantic::max3d::from_max_t( tri[1] ),
                 C = frantic::max3d::from_max_t( tri[2] );
        vector3f norm = vector3f::normalize( vector3f::cross( B - A, C - A ) );
        vector3f proj = point - vector3f::dot( ( point - A ), norm ) * norm;

        float dist2 = vector3f::distance_squared( point, proj );
        if( dist2 >= maxDistance * maxDistance )
            return false;

        vector3f baryC = compute_barycentric_coordinates( proj, A, B, C );

        frantic::geometry::detail::nearest_point_on_triangle( proj, baryC, A, B, C );

        double dist = vector3f::distance_double( point, proj );
        if( dist >= maxDistance )
            return false;

        if( ignoreBackfaces ) {
            frantic::graphics::vector3f normal =
                frantic::max3d::from_max_t( const_cast<mesh_type&>( inst ).GetFaceNormal( (int)index ) );
            const frantic::graphics::vector3f direction = proj - point;
            const bool notBackface = frantic::graphics::vector3f::dot( direction, normal ) <= 0;
            if( notBackface ) {
                outNearestPoint.distance = (float)dist;
                outNearestPoint.position = proj;
                outNearestPoint.geometricNormal = norm;
                outNearestPoint.faceIndex = (int)index;
                outNearestPoint.barycentricCoords = baryC;
            }
            return notBackface;
        } else {
            outNearestPoint.distance = (float)dist;
            outNearestPoint.position = proj;
            outNearestPoint.geometricNormal = norm;
            outNearestPoint.faceIndex = (int)index;
            outNearestPoint.barycentricCoords = baryC;
            return true;
        }
    }
};
