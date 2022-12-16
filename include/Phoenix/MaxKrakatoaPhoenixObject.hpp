// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0
#pragma once

#include <Objects/MaxKrakatoaPRTInterface.h>

#include <frantic/max3d/paramblock_builder.hpp>

// The name "PRT Phoenix FD" is too long to fit on the button
#define MaxKrakatoaPhoenixObject_NAME _T("PRT Phoenix")
#define MaxKrakatoaPhoenixObject_VERSION 1

class IAur;

/**
 * Object for working with Phoenix FD simulations, similar to the MaxKrakatoaFumeFXObject.
 */
class MaxKrakatoaPhoenixObject : public MaxKrakatoaPRTObject<MaxKrakatoaPhoenixObject> {
  protected:
    virtual Mesh* GetIconMesh( Matrix3& outTM );
#if MAX_VERSION_MAJOR >= 25
    virtual MaxSDK::SharedMeshPtr GetIconMeshShared( Matrix3& outTM );
#endif

    virtual ClassDesc2* GetClassDesc();

  public:
    MaxKrakatoaPhoenixObject();

    virtual ~MaxKrakatoaPhoenixObject() {}

    // From MaxKrakatoaPRTObject

    virtual void SetIconSize( float size );

    /**
     * Get the stream of particles, for either display or rendering purposes, in object space.
     */
    virtual particle_istream_ptr GetInternalStream( INode* /*pNode*/, TimeValue t, Interval& outValidity,
                                                    boost::shared_ptr<IEvalContext> pEvalContext );

    /**
     * Get the stream of particles for rendering purposes, in object space.
     */
    particle_istream_ptr GetRenderStream( TimeValue t, Interval& outValidity,
                                          const frantic::channels::channel_map& requestedChannels );

    // From ReferenceMaker

    virtual RefResult NotifyRefChanged( const Interval& changeInt, RefTargetHandle hTarget, PartID& partID,
                                        RefMessage message, BOOL propagate );

    // From BaseObject

#if MAX_VERSION_MAJOR >= 24
    virtual const MCHAR* GetObjectName( bool localized ) {
#elif MAX_VERSION_MAJOR >= 15
    virtual const MCHAR* GetObjectName() {
#else
    virtual MCHAR* GetObjectName() {
#endif
        return MaxKrakatoaPhoenixObject_NAME;
    }

    // From Object

    virtual void InitNodeName( MSTR& s ) { s = MaxKrakatoaPhoenixObject_NAME; }

    virtual void GetDeformBBox( TimeValue t, Box3& box, Matrix3* tm = NULL, BOOL useSel = FALSE );

    virtual Interval ObjectValidity( TimeValue t );

  private:
    inline void AppendGroup( std::vector<particle_istream_ptr>& pins, const char* name, TimeValue, Interval,
                             const frantic::channels::channel_map& requestedChannels, IAur* aur, INode* pPhoenixNode );
};
