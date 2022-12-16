// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0
#pragma once

#include "MaxKrakatoaReferenceTarget.h"
#include "Objects/MaxKrakatoaPRTInterface.h"

#include "Objects/MaxKrakatoaPRTObjectDisplay.hpp"

#if MAX_VERSION_MAJOR >= 25
#include <SharedMesh.h>
#endif

typedef std::vector<std::vector<frantic::graphics::vector3f>> spline_container;

void export_hair_and_fur( const frantic::tstring& filename, TimeValue t );
void cache_splines_from_node( INode* pHairNode, INode* pSourceNode, TimeValue t, Interval& outValid,
                              spline_container& outSplines, Box3* pBounds = NULL, bool inWorldSpace = false );

class MaxKrakatoaHairObject : public krakatoa::max3d::MaxKrakatoaPRTObjectDisplay<MaxKrakatoaHairObject> {
    typedef MaxKrakatoaPRTObject<MaxKrakatoaHairObject> super_type;

    std::vector<spline_container> m_cachedSplines;
    // This is a copy of the splines evaluated at m_objectValidity.Start() - m_timeStep
    std::vector<spline_container> m_cachedSplinesOffsetTime;
    // This is a copy of the splines evaluated at kReferenceTime
    std::vector<spline_container> m_cachedSplinesReferenceTime;

    // This variable is a guard to ignore extra REFMSG_CHANGE messages when calling EvalWorldState on the target node to
    // build caches.
    bool m_isEvaluatingNode;

    TimeValue m_timeStep;

    // Validity interval for cached splines
    std::vector<Interval> m_cachedSplinesValid;
    // Validity interval for cached splines at another time, for finite differencing.
    std::vector<Interval> m_cachedSplinesOffsetTimeValid;
    // Validity interval for cached splines at kReferenceTime. This doesn't really matter, except if it needs to be
    // re-cached.
    std::vector<Interval> m_cachedSplinesReferenceTimeValid;

    std::vector<Box3> m_objectBounds;
    Interval m_objectValidity;

    frantic::tstring m_shavePath;

  private:
    void CacheSpline( TimeValue t, bool forRender, INode* pHairNode, INode* pSourceNode, spline_container* cachedSpline,
                      spline_container* cachedSplineOffsetTime, spline_container* cachedSplineReferenceTime,
                      Interval* cachedSplineValid, Interval* cachedSplineOffsetTimeValid,
                      Interval* cachedSplineReferenceTimeValid, Box3* objectBounds );

    void ClearSplines();
    void ClearSpline( spline_container* cachedSpline, spline_container* cachedSplineOffsetTime,
                      spline_container* cachedSplineReferenceTime, Interval* cachedSplineValid,
                      Interval* cachedSplineOffsetTimeValid, Interval* cachedSplineReferenceTimeValid,
                      Box3* objectBounds );

    bool InWorldSpace();

  protected:
    virtual ClassDesc2* GetClassDesc();
    virtual Mesh* GetIconMesh( Matrix3& outTM );
#if MAX_VERSION_MAJOR >= 25
    virtual MaxSDK::SharedMeshPtr GetIconMeshShared( Matrix3& outTM );
#endif

    // From MaxKrakatoaPRTObject
    virtual particle_istream_ptr
    GetInternalStream( INode* pNode, TimeValue t, Interval& inoutValidity,
                       frantic::max3d::particles::IMaxKrakatoaPRTEvalContextPtr evalContext );

  public:
    MaxKrakatoaHairObject();
    virtual ~MaxKrakatoaHairObject();

    void InvalidateReferenceFrame();

    virtual void InvalidateObjectAndViewport();

    virtual void SetIconSize( float size );

    // From Animatable
    virtual BOOL RenderBegin( TimeValue t, ULONG flags );
    virtual BOOL RenderEnd( TimeValue t );

    // From ReferenceMaker
    virtual RefResult NotifyRefChanged( const Interval& changeInt, RefTargetHandle hTarget, PartID& partID,
                                        RefMessage message, BOOL propagate );

    // From BaseObject

#if MAX_VERSION_MAJOR >= 24
    virtual const TCHAR* GetObjectName( bool localized );
#elif MAX_VERSION_MAJOR >= 15
    virtual const TCHAR* GetObjectName();
#else
    virtual TCHAR* GetObjectName();
#endif

    // From Object
    virtual void InitNodeName( MSTR& s );
    virtual void GetDeformBBox( TimeValue t, Box3& box, Matrix3* tm = NULL, BOOL useSel = FALSE );
};
