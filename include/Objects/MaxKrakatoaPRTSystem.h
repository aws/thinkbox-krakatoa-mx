// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0
#pragma once

#if false
#include "Objects\MaxKrakatoaPRTInterface.h"

#include <frantic/max3d/shaders/map_query.hpp> //For renderInformation TODO: Move it to its own header
#include <frantic/particles/particle_array.hpp>
#include <frantic/particles/streams/particle_istream.hpp>

#include <max.h>
#include <object.h>

class MaxKrakatoaPRTSystem : public GeomObject, public IMaxKrakatoaPRTObject {
	typedef std::pair<frantic::graphics::vector3f,frantic::graphics::vector3f> particle_t;

	IParamBlock2* m_pblock;
	
	//The currently stored simulation frame.
	int m_curSimFrame;

	//The first frame to simulate.
	int m_initialSimFrame;

	//The particles at frame: curSimFrame
	frantic::particles::particle_array m_particles;

	//The initial values for the particles at frame: initialSimFrame
	frantic::particles::particle_array m_particlesInitial;

	bool m_inRenderMode;
	Box3 m_viewportBounds;

	//Time for the viewport cache
	TimeValue m_viewportTime;

	//The display cache for the viewport
	std::vector<particle_t> m_viewportCache;

private:
	void CacheInitialParticles();
	void CacheViewportDisplay(INode* pNode, TimeValue t);

	void InvalidateSim();
	void InvalidateViewport();
	void InvalidateInitialParticles();

public:
	MaxKrakatoaPRTSystem();
	virtual ~MaxKrakatoaPRTSystem();

	//From IMaxKrakatoaPRTObject
	virtual particle_istream_ptr GetParticleStream( IEvalContext* globContext, INode* pNode );

	//From Animatable
	virtual Class_ID ClassID();
	virtual SClass_ID SuperClassID();
#if MAX_VERSION_MAJOR >= 24
	virtual void GetClassName(MSTR& s, bool localized);
#else
	virtual void GetClassName(MSTR& s);
#endif

	virtual int NumRefs();
	virtual ReferenceTarget* GetReference(int i);
	virtual void SetReference(int i, ReferenceTarget* r);
	
	virtual int NumSubs();
	virtual Animatable* SubAnim(int i);
	virtual TSTR SubAnimName( int i );
	
	virtual int NumParamBlocks();
	virtual IParamBlock2* GetParamBlock(int i);
	virtual IParamBlock2* GetParamBlockByID( BlockID i);

	virtual void BeginEditParams( IObjParam* ip, ULONG flags, Animatable* prev = NULL );
	virtual void EndEditParams( IObjParam* ip, ULONG flags, Animatable* next = NULL );
	
	virtual void DeleteThis();

	virtual int RenderBegin(TimeValue t, ULONG flags);
	virtual int RenderEnd(TimeValue t);

	virtual BaseInterface* GetInterface( Interface_ID id );

	//From ReferenceMaker
	virtual RefResult NotifyRefChanged(Interval,RefTargetHandle,PartID &,RefMessage);

	//From ReferenceTarget
	virtual ReferenceTarget* Clone( RemapDir& remap );

	//From BaseObject
	virtual
#if MAX_VERSION_MAJOR >= 15
		const
#endif
		TCHAR *GetObjectName();
	virtual int Display(TimeValue t, INode* inode, ViewExp *pView, int flags);
	virtual int HitTest(TimeValue t, INode *inode, int type, int crossing, int flags, IPoint2 *p, ViewExp *vpt);
	virtual void GetWorldBoundBox(TimeValue t, INode* inode, ViewExp* vpt, Box3& box);
	virtual void GetLocalBoundBox(TimeValue t, INode* inode, ViewExp* vpt, Box3& box);
	virtual CreateMouseCallBack* GetCreateMouseCallBack(void);

	//From Object
	virtual void InitNodeName( MSTR& s );
	virtual void GetDeformBBox(TimeValue t, Box3 &box, Matrix3 *tm=NULL, BOOL useSel=FALSE); 
	virtual Interval ObjectValidity(TimeValue t);
	virtual ObjectState Eval(TimeValue);

	virtual void WSStateInvalidate();
	virtual BOOL CanCacheObject() { return FALSE; }
	virtual BOOL IsWorldSpaceObject() { return TRUE; }

	//From GeomObject
	virtual Mesh* GetRenderMesh(TimeValue t, INode* inode, View& view, BOOL& needDelete);
};
#endif
