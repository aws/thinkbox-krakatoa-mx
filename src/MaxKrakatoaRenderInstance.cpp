// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0
#include "stdafx.h"

#include "MaxKrakatoaMeshTraits.h"
#include "MaxKrakatoaRenderInstance.h"

MaxKrakatoaRenderInstance::MaxKrakatoaRenderInstance( MaxKrakatoaRenderGlobalContext* globContext, INode* pNode )
    : m_globContext( globContext )
    , m_pNode( pNode )
    , m_deleteMtl( FALSE ) {
    m_buildTreeFlag = false;

    TimeValue t = globContext->time;

    vis = pNode->GetVisibility( t );
    objMotBlurFrame = NO_MOTBLUR;
    objBlurID = 0;
    flags = 0;

    if( pNode->RcvShadows() )
        flags |= INST_RCV_SHADOWS;

    mtl = pNode->GetMtl();
    if( !mtl ) {
        mtl = NewDefaultStdMat();
        mtl->SetDiffuse( Color( pNode->GetWireColor() ), t );
        m_deleteMtl = TRUE;
    }

    wireSize = mtl->WireSize();

    obBox.Init();
    radsq = 0.f;

    m_evalObject = pNode->EvalWorldState( t );
    m_validIval = m_evalObject.Validity( t );

    objToWorld = pNode->GetObjTMAfterWSM( t );
    objToCam = objToWorld *
               frantic::max3d::to_max_t( globContext->get_scene_context()->get_camera().world_transform_inverse() );
    camToObj = Inverse( objToCam );
    normalObjToCam.Set( camToObj.GetColumn3( 0 ), camToObj.GetColumn3( 1 ), camToObj.GetColumn3( 2 ),
                        Point3( 0, 0, 0 ) );

    mesh = NULL;
    m_deleteMesh = FALSE;

    obBox.Init();
    center = Point3( 0, 0, 0 );
    radsq = 0.f;

    if( m_evalObject.obj->SuperClassID() == GEOMOBJECT_CLASS_ID ) {
        frantic::max3d::geometry::null_view view;

        mesh = static_cast<GeomObject*>( m_evalObject.obj )->GetRenderMesh( t, pNode, view, m_deleteMesh );

        mesh->buildNormals();
        mesh->buildBoundingBox();

        obBox = mesh->getBoundingBox();
        center = objToCam.PointTransform( obBox.Center() );

        // Compute the camera-space bounding sphere.
        for( int i = 0, iEnd = mesh->numVerts; i < iEnd; ++i ) {
            float d = LengthSquared( objToCam.PointTransform( mesh->getVert( i ) ) - center );
            if( d > radsq )
                radsq = d;
        }

        // We are going to lazily create the kdtree when needed.
        // m_kdtree.set_mesh( this );
        // m_kdtree.finalize();
    }
}

MaxKrakatoaRenderInstance::~MaxKrakatoaRenderInstance() {
    if( m_deleteMtl )
        mtl->MaybeAutoDelete(); // If your object is a ReferenceTarget, this is the way to delete it.
    if( m_deleteMesh && mesh )
        mesh->DeleteThis();
}

void MaxKrakatoaRenderInstance::set_next( MaxKrakatoaRenderInstance* next ) { m_next = next; }

RenderInstance* MaxKrakatoaRenderInstance::Next() { return m_next; }

INode* MaxKrakatoaRenderInstance::GetINode() { return m_pNode; }

Object* MaxKrakatoaRenderInstance::GetEvalObject() { return m_evalObject.obj; }

Mtl* MaxKrakatoaRenderInstance::GetMtl( int /*faceNum*/ ) { return mtl; }

ULONG MaxKrakatoaRenderInstance::MtlRequirements( int mtlNum, int /*faceNum*/ ) {
    if( mtl )
        return mtl->Requirements( mtlNum );
    return 0;
}

int MaxKrakatoaRenderInstance::NumLights() { return m_globContext->get_num_light_desc(); }

LightDesc* MaxKrakatoaRenderInstance::Light( int n ) { return m_globContext->get_light_desc( n ); }

int MaxKrakatoaRenderInstance::CastsShadowsFrom( const ObjLightDesc& lt ) {
    ExclList* list = const_cast<ObjLightDesc&>( lt ).GetExclList();
    if( !list || !list->TestFlag( NT_AFFECT_SHADOWCAST ) )
        return TRUE;

    if( list->TestFlag( NT_INCLUDE ) )
        return list->FindNode( m_pNode ) >= 0;
    else
        return list->FindNode( m_pNode ) < 0;
}

Interval MaxKrakatoaRenderInstance::MeshValidity() { return m_validIval; }

Point3 MaxKrakatoaRenderInstance::GetFaceNormal( int faceNum ) { return mesh->getFaceNormal( faceNum ); }

Point3 MaxKrakatoaRenderInstance::GetFaceVertNormal( int faceNum, int vertNum ) {
    Face& f = mesh->faces[faceNum];
    RVertex& rv = mesh->getRVert( f.getVert( vertNum ) );

    int nNormals = (int)( rv.rFlags & NORCT_MASK );
    if( f.getSmGroup() != 0 && nNormals > 0 ) {
        if( nNormals > 1 ) {
            for( int i = 0; i < nNormals; ++i ) {
                if( rv.ern[i].getSmGroup() & f.getSmGroup() )
                    return normalObjToCam.VectorTransform( rv.ern[i].getNormal() );
            }
            // Should we ever get here??!?!?
            return normalObjToCam.VectorTransform( mesh->getFaceNormal( faceNum ) );
        } else {
            return normalObjToCam.VectorTransform( rv.rn.getNormal() );
        }
    } else {
        return normalObjToCam.VectorTransform( mesh->getFaceNormal( faceNum ) );
    }
}

void MaxKrakatoaRenderInstance::GetFaceVertNormals( int faceNum, Point3 n[3] ) {
    n[0] = GetFaceVertNormal( faceNum, 0 );
    n[1] = GetFaceVertNormal( faceNum, 1 );
    n[2] = GetFaceVertNormal( faceNum, 2 );
}

Point3 MaxKrakatoaRenderInstance::GetCamVert( int vertnum ) {
    return objToCam.PointTransform( mesh->getVert( vertnum ) );
}

void MaxKrakatoaRenderInstance::GetObjVerts( int fnum, Point3 obp[3] ) {
    obp[0] = mesh->getVert( mesh->faces[fnum].getVert( 0 ) );
    obp[1] = mesh->getVert( mesh->faces[fnum].getVert( 1 ) );
    obp[2] = mesh->getVert( mesh->faces[fnum].getVert( 2 ) );
}

void MaxKrakatoaRenderInstance::GetCamVerts( int fnum, Point3 cp[3] ) {
    cp[0] = objToCam.PointTransform( mesh->getVert( mesh->faces[fnum].getVert( 0 ) ) );
    cp[1] = objToCam.PointTransform( mesh->getVert( mesh->faces[fnum].getVert( 1 ) ) );
    cp[2] = objToCam.PointTransform( mesh->getVert( mesh->faces[fnum].getVert( 2 ) ) );
}

inline void MaxKrakatoaRenderInstance::ensure_kdtree_init() {
    if( !m_buildTreeFlag ) {
        tbb::mutex::scoped_lock lock( m_buildTreeMutex );
        if( !m_buildTreeFlag ) {
            m_kdtree.set_mesh( this );
            m_kdtree.finalize();
            m_buildTreeFlag = true;
        }
    }
}

bool MaxKrakatoaRenderInstance::intersect_ray( const Ray& ray, float tMin, float tMax, ISect& outInfo ) {
    ensure_kdtree_init();

    frantic::graphics::ray3f r( frantic::max3d::from_max_t( this->camToObj.PointTransform( ray.p ) ),
                                frantic::max3d::from_max_t( this->camToObj.VectorTransform( ray.dir ) ) );

    frantic::geometry::raytrace_intersection ri;

    if( m_kdtree.intersect_ray( r, tMin, tMax, ri ) ) {
        outInfo.t = (float)ri.distance;
        outInfo.inst = this;
        outInfo.fnum = ri.faceIndex;
        outInfo.bc = frantic::max3d::to_max_t( ri.barycentricCoords );

        return true;
    } else {
        return false;
    }
}