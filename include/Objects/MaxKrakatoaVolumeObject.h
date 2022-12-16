// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0
#pragma once

//#include "Objects\MaxKrakatoaPRTInterface.h"
//
//#include <frantic/particles/particle_array.hpp>
//#include <frantic/particles/streams/particle_istream.hpp>
//#include <frantic/volumetrics/levelset/rle_level_set.hpp>
//
//#include <frantic/max3d/shaders/map_query.hpp> //For renderInformation TODO: Move it to its own header
//
//#include <max.h>
//#include <object.h>
//
// class MaxKrakatoaVolumeObject : public GeomObject, public IMaxKrakatoaPRTObject{
//	typedef std::pair<frantic::graphics::vector3f,frantic::graphics::vector3f> particle_t;
//
//	IParamBlock2* m_pblock;
//
//	boost::shared_ptr<frantic::volumetrics::levelset::rle_level_set> m_pLevelset;
//	boost::shared_ptr< std::vector<frantic::graphics::vector3f> > m_pSamplePoints;
//
//	//This cached radius is used to determine is the current sample point cache is adequate.
//	float m_cachedRadius;
//
//	bool m_inRenderMode;
//	Box3 m_objectBounds;
//	Box3 m_viewportBounds;
//	Interval m_objectValidity;
//	TimeValue m_viewportValidTime;
//
//	std::vector<particle_t> m_viewportCache;
//
// private:
//	void CacheLevelset( TimeValue t, bool forRender );
//	void CacheViewportDisplay(INode* pNode, ViewExp* pView, TimeValue t);
//
//	boost::shared_ptr<frantic::particles::streams::particle_istream> GetParticleStream(
//		const frantic::channels::channel_map& pcm,
//		const frantic::max3d::shaders::renderInformation& renderInfo,
//		INode* pNode,
//		bool forRender,
//		TimeValue t,
//		TimeValue timeStep );
//
// public:
//	MaxKrakatoaVolumeObject();
//	virtual ~MaxKrakatoaVolumeObject();
//
//	//From IMaxKrakatoaPRTObject
//	virtual boost::shared_ptr<frantic::particles::streams::particle_istream> GetRenderStream(
//		const frantic::channels::channel_map& pcm,
//		const frantic::max3d::shaders::renderInformation& renderInfo,
//		INode* pNode,
//		TimeValue t,
//		TimeValue timeStep );
//
//	//From Animatable
//	virtual Class_ID ClassID();
//	virtual SClass_ID SuperClassID();
//	virtual void GetClassName(MSTR& s, bool localized);
//
//	virtual int NumRefs();
//	virtual ReferenceTarget* GetReference(int i);
//	virtual void SetReference(int i, ReferenceTarget* r);
//
//	virtual int NumSubs();
//	virtual Animatable* SubAnim(int i);
//	virtual TSTR SubAnimName( int i );
//
//	virtual int NumParamBlocks();
//	virtual IParamBlock2* GetParamBlock(int i);
//	virtual IParamBlock2* GetParamBlockByID( BlockID i);
//
//	virtual BaseInterface* GetInterface( Interface_ID id );
//
//	virtual void BeginEditParams( IObjParam* ip, ULONG flags, Animatable* prev = NULL );
//	virtual void EndEditParams( IObjParam* ip, ULONG flags, Animatable* next = NULL );
//
//	virtual void DeleteThis();
//
//	virtual int RenderBegin(TimeValue t, ULONG flags);
//	virtual int RenderEnd(TimeValue t);
//
//	//From ReferenceMaker
//	virtual RefResult NotifyRefChanged(Interval,RefTargetHandle,PartID &,RefMessage);
//
//	//From ReferenceTarget
//	virtual ReferenceTarget* Clone( RemapDir& remap );
//
//	//From BaseObject
//	virtual TCHAR *GetObjectName();
//	virtual int Display(TimeValue t, INode* inode, ViewExp *pView, int flags);
//	virtual int HitTest(TimeValue t, INode *inode, int type, int crossing, int flags, IPoint2 *p, ViewExp *vpt);
//	virtual void GetWorldBoundBox(TimeValue t, INode* inode, ViewExp* vpt, Box3& box);
//	virtual void GetLocalBoundBox(TimeValue t, INode* inode, ViewExp* vpt, Box3& box);
//	virtual CreateMouseCallBack* GetCreateMouseCallBack(void);
//
//	//From Object
//	virtual void InitNodeName( MSTR& s );
//	virtual void GetDeformBBox(TimeValue t, Box3 &box, Matrix3 *tm=NULL, BOOL useSel=FALSE);
//	virtual Interval ObjectValidity(TimeValue t);
//	virtual ObjectState Eval(TimeValue);
//	virtual Object* MakeShallowCopy( ChannelMask channels ) ;
//
//	virtual void WSStateInvalidate();
//	virtual BOOL CanCacheObject() { return FALSE; }
//	virtual BOOL IsWorldSpaceObject() { return TRUE; }
//
//	//From GeomObject
//	virtual Mesh* GetRenderMesh(TimeValue t, INode* inode, View& view, BOOL& needDelete);
//};
