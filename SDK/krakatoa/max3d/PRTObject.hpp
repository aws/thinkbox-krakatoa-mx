// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0
#pragma once

#include <frantic/max3d/GenericReferenceTarget.hpp>
#include <frantic/max3d/particles/IMaxKrakatoaPRTObject.hpp>
#include <frantic/max3d/particles/IMaxKrakatoaParticleInterface.hpp>

#pragma warning( push, 3 )
#include <mesh.h>
#pragma warning( pop )

#if MAX_VERSION_MAJOR >= 25
#include <SharedMesh.h>
#endif

#undef base_type

template <class ChildType>
class MaxKraktoaPRTObject;

namespace krakatoa {
namespace max3d {

using frantic::particles::particle_istream_ptr;

class PRTObjectBase : public GeomObject,
                      public frantic::max3d::particles::IMaxKrakatoaPRTObject,
                      public IMaxKrakatoaParticleInterface {
  public:
    typedef frantic::max3d::particles::IMaxKrakatoaPRTEvalContext IEvalContext;

  protected:
    struct particle_t {
        Point3 m_position;
        Point3 m_vector;
        Color m_color;
    };

    std::vector<particle_t> m_viewportCache;

    Interval m_viewportValidity;
    Interval m_objectValidity;

    Box3 m_viewportBounds;

    bool m_inRenderMode;
    bool m_hasVectors;

  protected:
    virtual Mesh* GetIconMesh( Matrix3& outTM ) = 0;
#if MAX_VERSION_MAJOR >= 25
    virtual MaxSDK::SharedMeshPtr GetIconMeshShared( Matrix3& outTM ) = 0;
#endif

    virtual bool InWorldSpace() const { return false; }

    /**
     * This will create the initial (ie. source) particle_istream for an object.
     * @param pNode The
     * @param globContext The context in which to create the stream.
     * @param pNode The instance of this object to create the stream for.
     */
    virtual particle_istream_ptr GetInternalStream( INode* pNode, TimeValue t, Interval& outValidity,
                                                    boost::shared_ptr<IEvalContext> pEvalContext ) = 0;

    /**
     * This will decorate the stream with particle_istreams corresponding to the object space modifiers of the node. It
     * will optionally apply the object to world transform, and the node's material.
     * @param pin The source stream to decorate
     * @param pNode The instance of this object to evaluate
     * @param t The time to evaluate modifiers at
     * @param inoutValidity The time interval around 't' where particles from 'pin' are unchanging. This will be updated
     * by applied modifiers.
     * @param pEvalContext Provides extra information about the evaluation
     * @return A decorated version of pin with the modifiers and such applied
     */
    virtual particle_istream_ptr ApplyModifiersAndMtl( particle_istream_ptr pin, INode* pNode, TimeValue t,
                                                       Interval& inoutValidity,
                                                       boost::shared_ptr<IEvalContext> pEvalContext );

  public:
    PRTObjectBase();
    virtual ~PRTObjectBase();

    virtual void BuildViewportCache( INode* pNode, ViewExp* pView, TimeValue t );
    virtual void ClearViewportCaches();

    virtual void InvalidateViewport();

    virtual void InvalidateObjectAndViewport();

    virtual void SetIconSize( float scale ) = 0;

    // From IMaxKrakatoaPRTObject
    virtual particle_istream_ptr CreateStream( INode* pNode, Interval& outValidity,
                                               boost::shared_ptr<IEvalContext> pEvalContext );
    virtual void GetStreamNativeChannels( INode* pNode, TimeValue t, frantic::channels::channel_map& outChannelMap );

    // From Animatable
    virtual int RenderBegin( TimeValue t, ULONG flags );
    virtual int RenderEnd( TimeValue t );
    virtual BaseInterface* GetInterface( Interface_ID id );

    // From ReferenceMaker
    virtual RefResult NotifyRefChanged( const Interval& changeInt, RefTargetHandle hTarget, PartID& partID,
                                        RefMessage message, BOOL propagate ) = 0;

    // From BaseObject
    // virtual TCHAR *GetObjectName();
    virtual int Display( TimeValue t, INode* inode, ViewExp* pView, int flags );
    virtual int HitTest( TimeValue t, INode* inode, int type, int crossing, int flags, IPoint2* p, ViewExp* vpt );
    virtual void GetWorldBoundBox( TimeValue t, INode* inode, ViewExp* vpt, Box3& box );
    virtual void GetLocalBoundBox( TimeValue t, INode* inode, ViewExp* vpt, Box3& box );
    virtual CreateMouseCallBack* GetCreateMouseCallBack( void );

    // From Object
    // virtual void InitNodeName( MSTR& s );
    virtual void GetDeformBBox( TimeValue t, Box3& box, Matrix3* tm = NULL, BOOL useSel = FALSE );
    virtual Interval ObjectValidity( TimeValue t );
    virtual ObjectState Eval( TimeValue );
    virtual BOOL CanConvertToType( Class_ID obtype );
    virtual Object* ConvertToType( TimeValue t, Class_ID obtype );
    virtual Object* MakeShallowCopy( ChannelMask channels );

    virtual void WSStateInvalidate();
    virtual BOOL CanCacheObject();
    virtual BOOL IsWorldSpaceObject();

    // From GeomObject
    virtual Mesh* GetRenderMesh( TimeValue t, INode* inode, View& view, BOOL& needDelete );
};

template <class ChildType>
class PRTObject : public frantic::max3d::GenericReferenceTarget<PRTObjectBase, ChildType> {
  public:
    // This class provides no actual members or any implementation. It merely works around the fact that you can't make
    // template typedefs.
};

/**
 * This abstract interface is provided to extend IEvalContext with new functionality within Krakatoa,
 * without breaking binary compatibility with clients of IEvalContext. I'm looking at you Frost.
 */
class IMaxKrakatoaEvalContext : public frantic::max3d::particles::IMaxKrakatoaPRTEvalContext {
  public:
    /**
     * By supplying a Modifier and ModContext we can evaluate only a portion of the modifier stack up to, BUT NOT
     * INCLUDING, the specified modifier/modcontext.
     */
    virtual std::pair<Modifier*, ModContext*> get_eval_endpoint() const = 0;
};

} // namespace max3d
} // namespace krakatoa
