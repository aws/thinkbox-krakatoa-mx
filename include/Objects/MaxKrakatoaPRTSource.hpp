// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0
#pragma once

#include "Objects/MaxKrakatoaPRTObjectDisplay.hpp"

#include "PRTSourceDialogProcs/tp_group_info.hpp"

#include <frantic/particles/particle_array.hpp>
#include <frantic/particles/streams/particle_istream.hpp>

#include <frantic/max3d/particles/particle_stream_factory.hpp>

namespace PARTICLE_GROUP_FILTER_MODE {
enum particle_group_filter_mode_enum { ALL, SELECTED, COUNT };
}

enum {
    kTargetNode,
    kViewportDisable,
    kIconSize,
    // Viewport Limits
    kViewPercentage,
    kViewLimit,
    kUseViewLimit,
    // Particle Flow
    kPFEventList,
    kPFEventFilterMode,
    // Thinking Particles
    kTPGroupList,
    kTPGroupFilterMode
};

enum { kMainParamRollout, kPFLowEventParamRollout, kTPGroupParamRollout };

class MaxKrakatoaPRTSourceObject : public krakatoa::max3d::MaxKrakatoaPRTObjectDisplay<MaxKrakatoaPRTSourceObject> {
    Box3 m_internalBounds;
    frantic::particles::particle_array m_internalParticles;
    bool m_canAcceptPFlow;

  private:
    void CacheInternal( TimeValue t, bool forRender );

  protected:
    virtual ClassDesc2* GetClassDesc();
    virtual Mesh* GetIconMesh( Matrix3& outTM );
#if MAX_VERSION_MAJOR >= 25
    virtual MaxSDK::SharedMeshPtr GetIconMeshShared( Matrix3& outTM );
#endif

    virtual frantic::particles::particle_istream_ptr
    GetInternalStream( INode* pNode, TimeValue t, Interval& inoutValidity,
                       frantic::max3d::particles::IMaxKrakatoaPRTEvalContextPtr pEvalContext );

  public:
    static IObjParam* ip;
    static MaxKrakatoaPRTSourceObject* editObj;

    static MaxKrakatoaPRTSourceObject* GetMaxKrakatoaPRTSource( INode* pNode, TimeValue t );

    MaxKrakatoaPRTSourceObject();
    virtual ~MaxKrakatoaPRTSourceObject();

    virtual void SetIconSize( float size );
    virtual frantic::max3d::particles::particle_system_type GetSourceType( TimeValue t ) const;

    // From ReferenceMaker
    virtual RefResult NotifyRefChanged( const Interval& changeInt, RefTargetHandle hTarget, PartID& partID,
                                        RefMessage message, BOOL /*propagate*/ );

    // From BaseObject
#if MAX_VERSION_MAJOR >= 24
    virtual const TCHAR* GetObjectName( bool localized );
#else
    virtual const TCHAR* GetObjectName();
#endif
    virtual void BeginEditParams( IObjParam* ip, ULONG flags, Animatable* prev );

    // From Object
    virtual void InitNodeName( MSTR& s );
    virtual void GetDeformBBox( TimeValue t, Box3& box, Matrix3* tm = NULL, BOOL useSel = FALSE );
    void OnParamSet( PB2Value& v, ParamID id, int tabIndex, TimeValue t );
    void OnTabChanged( PBAccessor::tab_changes changeCode, Tab<PB2Value>* tab, ParamID id, int tabIndex, int count );
    void AddParticleFlowEvent( INode* node );
    void AddTPGroup( INode* node, ReferenceTarget* group );
    bool IsAcceptablePFlowEvent( INode* node );
    bool IsAcceptableTPGroup( INode* node, ReferenceTarget* group );

    void GetAllParticleFlowEvents( std::vector<INode*>& out );
    void ClearParticleFlowEvents();
    void RemoveParticleFlowEvents( const std::vector<int>& indicesIn );
    void GetParticleFlowEventNames( std::vector<frantic::tstring>& eventNames );
    void GetSelectedParticleFlowEvents( std::vector<INode*>& outEvents );

    void GetTPGroupNames( std::vector<frantic::tstring>& outGroupNames );
    void ClearTPGroups();
    void RemoveTPGroups( const std::vector<int>& indicesIn );
    void GetSelectedTPGroups( std::vector<tp_group_info>& outGroups );
    void GetAllTPGroups( std::vector<tp_group_info>& outGroups );
};