// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0
#pragma once

#include "MaxKrakatoaMeshTraits.h"
#include "MaxKrakatoaRenderGlobalContext.h"

#include <krakatoa/geometry_renderer.hpp>

#include <frantic/geometry/generic_mesh_kdtree.hpp>

#pragma warning( push, 3 )
#include <tbb/atomic.h>
#include <tbb/mutex.h>
#pragma warning( pop )

#pragma warning( push, 3 )
#include <render.h>
#pragma warning( pop )

class MaxKrakatoaRenderInstance : public RenderInstance {
    MaxKrakatoaRenderInstance* m_next;
    MaxKrakatoaRenderGlobalContext* m_globContext;

    INode* m_pNode;

    // If we couldn't get a mtl from the node, then we need a fake stand-in material, and it needs to get deleted later.
    BOOL m_deleteMtl;

    Interval m_validIval;
    ObjectState m_evalObject;

    BOOL m_deleteMesh;

  public:
    MaxKrakatoaRenderInstance( MaxKrakatoaRenderGlobalContext* globContext, INode* pNode );

    virtual ~MaxKrakatoaRenderInstance();

    void set_next( MaxKrakatoaRenderInstance* next );

    bool intersect_ray( const Ray& ray, float tMin, float tMax, ISect& outInfo );

    virtual RenderInstance* Next();

    virtual INode* GetINode();

    virtual Mtl* GetMtl( int /*faceNum*/ );

    virtual ULONG MtlRequirements( int mtlNum, int /*faceNum*/ );

    virtual int NumLights();

    virtual LightDesc* Light( int n );

    virtual int CastsShadowsFrom( const ObjLightDesc& lt );

    virtual Interval MeshValidity();

    virtual Object* GetEvalObject();

    virtual Point3 GetFaceNormal( int faceNum );

    virtual Point3 GetFaceVertNormal( int faceNum, int vertNum );

    virtual void GetFaceVertNormals( int faceNum, Point3 n[3] );

    virtual Point3 GetCamVert( int vertnum );

    virtual void GetObjVerts( int fnum, Point3 obp[3] );

    virtual void GetCamVerts( int fnum, Point3 cp[3] );

  private:
    frantic::geometry::generic_mesh_kdtree<MaxMeshTraits> m_kdtree;
    tbb::mutex m_buildTreeMutex;
    tbb::atomic<bool> m_buildTreeFlag;

    void ensure_kdtree_init();
};
