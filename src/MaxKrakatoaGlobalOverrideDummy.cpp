// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0
#include "stdafx.h"

#include "resource.h"

#include "MaxKrakatoaReferenceTarget.h"
#include "Objects/MaxKrakatoaPRTInterface.h"

#define MaxKrakatoaGlobalOverrideDummy_CLASSID Class_ID( 0x6bee3065, 0x32b4d0d )
#define MaxKrakatoaGlobalOverrideDummy_NAME "Global Override Dummy"
#define MaxKrakatoaGlobalOverrideDummy_VERSION 1

extern HINSTANCE hInstance;

class MaxKrakatoaGlobalOverrideDummy : public MaxKrakatoaReferenceTarget<GeomObject, MaxKrakatoaGlobalOverrideDummy> {
  protected:
    virtual ClassDesc2* GetClassDesc();

  public:
    MaxKrakatoaGlobalOverrideDummy();
    virtual ~MaxKrakatoaGlobalOverrideDummy();

    // From ReferenceMaker
    virtual RefResult NotifyRefChanged( const Interval& changeInt, RefTargetHandle hTarget, PartID& partID,
                                        RefMessage message, BOOL propagate );

    ////From BaseObject
    // virtual TCHAR *GetObjectName();
    virtual CreateMouseCallBack* GetCreateMouseCallBack();

    ////From Object
    virtual ObjectState Eval( TimeValue t );
    BOOL CanConvertToType( Class_ID obtype );
    Object* ConvertToType( TimeValue t, Class_ID obtype );
    // virtual void InitNodeName( MSTR& s );
};

class MaxKrakatoaGlobalOverrideDummyDesc : public ClassDesc2 {
    // ParamBlockDesc2 m_paramDesc;

  public:
    MaxKrakatoaGlobalOverrideDummyDesc();

    int IsPublic() { return FALSE; }
    void* Create( BOOL /*loading*/ ) { return new MaxKrakatoaGlobalOverrideDummy; }
    const TCHAR* ClassName() { return _T( MaxKrakatoaGlobalOverrideDummy_NAME ); }
#if MAX_VERSION_MAJOR >= 24
    const TCHAR* NonLocalizedClassName() { return _T( MaxKrakatoaGlobalOverrideDummy_NAME ); }
#endif
    SClass_ID SuperClassID() { return GEOMOBJECT_CLASS_ID; }
    Class_ID ClassID() { return MaxKrakatoaGlobalOverrideDummy_CLASSID; }
    const TCHAR* Category() { return _T("Krakatoa"); }

    // returns fixed parsable name (scripter-visible name)
    const TCHAR* InternalName() { return _T( MaxKrakatoaGlobalOverrideDummy_NAME ); }
    HINSTANCE HInstance() { return hInstance; } // returns owning module handle
};

ClassDesc2* GetMaxKrakatoaGlobalOverrideDummyDesc() {
    static MaxKrakatoaGlobalOverrideDummyDesc theDesc;
    return &theDesc;
}

MaxKrakatoaGlobalOverrideDummyDesc::MaxKrakatoaGlobalOverrideDummyDesc()
//: m_paramDesc(
//	0,                                                     //Block num
//	"Parameters",                                          //Internal name
//	NULL,                                                  //Localized name
//	this,                                                  //ClassDesc2*
//	P_AUTO_CONSTRUCT + P_VERSION, //Flags
//	MaxKrakatoaPRTSourceObject_VERSION,
//	0,                                                     //PBlock Ref Num
//	end
//)
{}

ClassDesc2* MaxKrakatoaGlobalOverrideDummy::GetClassDesc() { return GetMaxKrakatoaGlobalOverrideDummyDesc(); }

MaxKrakatoaGlobalOverrideDummy::MaxKrakatoaGlobalOverrideDummy() {
    // GetMaxKrakatoaPRTSourceObjectDesc()->MakeAutoParamBlocks(this);
}

MaxKrakatoaGlobalOverrideDummy::~MaxKrakatoaGlobalOverrideDummy() {}

RefResult MaxKrakatoaGlobalOverrideDummy::NotifyRefChanged( const Interval& /*changeInt*/, RefTargetHandle hTarget,
                                                            PartID& /*partID*/, RefMessage message,
                                                            BOOL /*propagate*/ ) {
    return REF_SUCCEED;
}

// TCHAR* MaxKrakatoaGlobalOverrideDummy::GetObjectName(){
//	return const_cast<TCHAR*>( GetClassDesc()->ClassName() );
//}

CreateMouseCallBack* MaxKrakatoaGlobalOverrideDummy::GetCreateMouseCallBack() { return NULL; }

ObjectState MaxKrakatoaGlobalOverrideDummy::Eval( TimeValue /*t*/ ) { return ObjectState( this ); }

// void MaxKrakatoaGlobalOverrideDummy::InitNodeName( MSTR& s ){
//	s = _T("Krakatoa Global Override Holder");
//}

BOOL MaxKrakatoaGlobalOverrideDummy::CanConvertToType( Class_ID obtype ) {
    if( obtype == MaxKrakatoaPRTSourceObject_CLASSID )
        return TRUE;
    return GeomObject::CanConvertToType( obtype );
}

Object* MaxKrakatoaGlobalOverrideDummy::ConvertToType( TimeValue t, Class_ID obtype ) {
    if( obtype == MaxKrakatoaPRTSourceObject_CLASSID )
        return this;
    return GeomObject::ConvertToType( t, obtype );
}
