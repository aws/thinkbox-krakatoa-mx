// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0
#pragma once

#include <max.h>

template <class BaseClass, class ChildClass>
class MaxKrakatoaReferenceTarget : public BaseClass {
  protected:
    IParamBlock2* m_pblock;

  protected:
    virtual ClassDesc2* GetClassDesc() = 0;

  public:
    MaxKrakatoaReferenceTarget();

    virtual ~MaxKrakatoaReferenceTarget();

    // From Animatable
    virtual Class_ID ClassID();
#if MAX_VERSION_MAJOR >= 24
    virtual void GetClassName( MSTR& s, bool localized );
#else
    virtual void GetClassName( MSTR& s );
#endif

    virtual int NumRefs();
    virtual ReferenceTarget* GetReference( int i );
    virtual void SetReference( int i, ReferenceTarget* r );

    virtual int NumSubs();
    virtual Animatable* SubAnim( int i );
#if MAX_VERSION_MAJOR >= 24
    virtual TSTR SubAnimName( int i, bool localized );
#else
    virtual TSTR SubAnimName( int i );
#endif

    virtual int NumParamBlocks();
    virtual IParamBlock2* GetParamBlock( int i );
    virtual IParamBlock2* GetParamBlockByID( BlockID i );

    virtual void BeginEditParams( IObjParam* ip, ULONG flags, Animatable* prev = NULL );
    virtual void EndEditParams( IObjParam* ip, ULONG flags, Animatable* next = NULL );

    virtual void DeleteThis();

    // From ReferenceMaker
    virtual RefResult NotifyRefChanged( const Interval& changeInt, RefTargetHandle hTarget, PartID& partID,
                                        RefMessage message, BOOL propagate ) = 0;

#if MAX_VERSION_MAJOR < 17
    virtual RefResult NotifyRefChanged( Interval changeInt, RefTargetHandle hTarget, PartID& partID,
                                        RefMessage message ) {
        return this->NotifyRefChanged( changeInt, hTarget, partID, message, TRUE );
    }
#endif

    // From ReferenceTarget
    virtual ReferenceTarget* Clone( RemapDir& remap );
};

template <class BaseClass, class ChildClass>
MaxKrakatoaReferenceTarget<BaseClass, ChildClass>::MaxKrakatoaReferenceTarget() {
    m_pblock = NULL;
}

template <class BaseClass, class ChildClass>
MaxKrakatoaReferenceTarget<BaseClass, ChildClass>::~MaxKrakatoaReferenceTarget() {}

template <class BaseClass, class ChildClass>
Class_ID MaxKrakatoaReferenceTarget<BaseClass, ChildClass>::ClassID() {
    return GetClassDesc()->ClassID();
}

template <class BaseClass, class ChildClass>
#if MAX_VERSION_MAJOR < 24
void MaxKrakatoaReferenceTarget<BaseClass, ChildClass>::GetClassName( MSTR& s ) {
#else
void MaxKrakatoaReferenceTarget<BaseClass, ChildClass>::GetClassName( MSTR& s, bool localized ) {
#endif
    s = GetClassDesc()->ClassName();
}

template <class BaseClass, class ChildClass>
int MaxKrakatoaReferenceTarget<BaseClass, ChildClass>::NumRefs() {
    return 1;
}

template <class BaseClass, class ChildClass>
ReferenceTarget* MaxKrakatoaReferenceTarget<BaseClass, ChildClass>::GetReference( int i ) {
    return ( i == 0 ) ? m_pblock : NULL;
}

template <class BaseClass, class ChildClass>
void MaxKrakatoaReferenceTarget<BaseClass, ChildClass>::SetReference( int i, ReferenceTarget* r ) {
    if( i == 0 )
        m_pblock = static_cast<IParamBlock2*>( r );
}

template <class BaseClass, class ChildClass>
int MaxKrakatoaReferenceTarget<BaseClass, ChildClass>::NumSubs() {
    return 1;
}

template <class BaseClass, class ChildClass>
Animatable* MaxKrakatoaReferenceTarget<BaseClass, ChildClass>::SubAnim( int i ) {
    return ( i == 0 ) ? m_pblock : NULL;
}

template <class BaseClass, class ChildClass>
#if MAX_VERSION_MAJOR < 24
TSTR MaxKrakatoaReferenceTarget<BaseClass, ChildClass>::SubAnimName( int i ) {
#else
TSTR MaxKrakatoaReferenceTarget<BaseClass, ChildClass>::SubAnimName( int i, bool localized ) {
#endif
    return ( i == 0 ) ? m_pblock->GetLocalName() : _T("");
}

template <class BaseClass, class ChildClass>
int MaxKrakatoaReferenceTarget<BaseClass, ChildClass>::NumParamBlocks() {
    return 1;
}

template <class BaseClass, class ChildClass>
IParamBlock2* MaxKrakatoaReferenceTarget<BaseClass, ChildClass>::GetParamBlock( int i ) {
    return ( i == 0 ) ? m_pblock : NULL;
}

template <class BaseClass, class ChildClass>
IParamBlock2* MaxKrakatoaReferenceTarget<BaseClass, ChildClass>::GetParamBlockByID( BlockID i ) {
    return ( i == m_pblock->ID() ) ? m_pblock : NULL;
}

template <class BaseClass, class ChildClass>
void MaxKrakatoaReferenceTarget<BaseClass, ChildClass>::BeginEditParams( IObjParam* ip, ULONG flags,
                                                                         Animatable* prev = NULL ) {
    GetClassDesc()->BeginEditParams( ip, this, flags, prev );
}

template <class BaseClass, class ChildClass>
void MaxKrakatoaReferenceTarget<BaseClass, ChildClass>::EndEditParams( IObjParam* ip, ULONG flags,
                                                                       Animatable* next = NULL ) {
    GetClassDesc()->EndEditParams( ip, this, flags, next );
}

template <class BaseClass, class ChildClass>
void MaxKrakatoaReferenceTarget<BaseClass, ChildClass>::DeleteThis() {
    delete this;
}

template <class BaseClass, class ChildClass>
ReferenceTarget* MaxKrakatoaReferenceTarget<BaseClass, ChildClass>::Clone( RemapDir& remap ) {
    ChildClass* pOldObj = static_cast<ChildClass*>( this );
    ChildClass* pNewObj = new ChildClass;
    for( int i = 0, iEnd = pNewObj->NumRefs(); i < iEnd; ++i )
        pNewObj->ReplaceReference( i, remap.CloneRef( pOldObj->GetReference( i ) ) );
    pOldObj->BaseClone( pOldObj, pNewObj, remap );
    return pNewObj;
}
