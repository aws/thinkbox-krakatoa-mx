// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0
#pragma once

#include "MaxKrakatoaPFParticleChannelFileIDInteger.h"
#include <ParticleFlow/PFSimpleTest.h>

#define KrakatoaPFFileIDTest_Class_ID Class_ID( 0x472873d5, 0x75460e37 )

// paramater block and message IDs
enum {
    kKrakatoaPFFileIDTest_use_less_than,
    kKrakatoaPFFileIDTest_less_than,
    kKrakatoaPFFileIDTest_use_greater_than,
    kKrakatoaPFFileIDTest_greater_than,
    kKrakatoaPFFileIDTest_AndOr
};

enum { kKrakatoaPFFileIDTest_Or, kKrakatoaPFFileIDTest_And, kKrakatoaPFFileIDTest_AndOr_num = 2 };

enum { kKrakatoaPFFileIDTest_pblock_index };

// User Defined Reference Messages from PB
enum { kKrakatoaPFFileIDTest_RefMsg_InitDlg = REFMSG_USER + 13279, kKrakatoaPFFileIDTest_RefMsg_NewRand };

// dialog messages
enum {
    kKrakatoaPFFileIDTest_message_update = 100 // variation or type change message
};

// extern KrakatoaPFFileIDTestDesc TheKrakatoaPFFileIDTestDesc;
extern ParamBlockDesc2 KrakatoaPFFileIDTest_paramBlockDesc;

class KrakatoaPFFileIDTestDlgProc : public ParamMap2UserDlgProc {
  public:
    INT_PTR DlgProc( TimeValue t, IParamMap2* map, HWND hWnd, UINT msg, WPARAM wParam, LPARAM lParam );
    void DeleteThis() {}

  private:
    void UpdateDlg( HWND hWnd, int type, float sizeVar, float scaleVar );
};

extern HINSTANCE hInstance;

//	Descriptor declarations
class KrakatoaPFFileIDTestDesc : public ClassDesc2 {
  public:
    ~KrakatoaPFFileIDTestDesc();
    int IsPublic();
    void* Create( BOOL loading = FALSE );
    const TCHAR* ClassName();
#if MAX_VERSION_MAJOR >= 24
    const TCHAR* NonLocalizedClassName();
#endif
    SClass_ID SuperClassID();
    Class_ID ClassID();
    Class_ID SubClassID();
    const TCHAR* Category();

    const TCHAR* InternalName();
    HINSTANCE HInstance();

    INT_PTR Execute( int cmd, ULONG_PTR arg1, ULONG_PTR arg2, ULONG_PTR arg3 );

    static HBITMAP m_depotIcon;
    static HBITMAP m_depotMask;
};

ClassDesc2* GetKrakatoaPFFileIDTestDesc();

class KrakatoaPFFileIDTest : public PFSimpleTest {
  public:
    // constructor/destructor
    KrakatoaPFFileIDTest();

    // From Animatable
#if MAX_VERSION_MAJOR < 24
    void GetClassName( TSTR& s );
#else
    void GetClassName( TSTR& s, bool localized );
#endif
    Class_ID ClassID();
    void BeginEditParams( IObjParam* ip, ULONG flags, Animatable* prev );
    void EndEditParams( IObjParam* ip, ULONG flags, Animatable* next );

    // From ReferenceMaker
    RefResult NotifyRefChanged( const Interval& changeInt, RefTargetHandle hTarget, PartID& partID, RefMessage message,
                                BOOL propagate );

#if MAX_VERSION_MAJOR < 17
    virtual RefResult NotifyRefChanged( Interval changeInt, RefTargetHandle hTarget, PartID& partID,
                                        RefMessage message ) {
        return this->NotifyRefChanged( changeInt, hTarget, partID, message, TRUE );
    }
#endif

    // From ReferenceTarget
    RefTargetHandle Clone( RemapDir& remap );

    // From BaseObject
#if MAX_VERSION_MAJOR >= 24
    virtual const TCHAR* GetObjectName( bool localized ) const;
#elif MAX_VERSION_MAJOR >= 15
    virtual const TCHAR* GetObjectName();
#else
    virtual TCHAR* GetObjectName();
#endif

    const ParticleChannelMask& ChannelsUsed( const Interval& time ) const;
    const Interval ActivityInterval() const { return FOREVER; }

    // from IPViewItem interface
    bool HasCustomPViewIcons() { return true; }
    HBITMAP GetActivePViewIcon();
    HBITMAP GetTruePViewIcon();
    HBITMAP GetFalsePViewIcon();

    // From IPFTest interface
    bool Proceed( IObject* pCont, PreciseTimeValue timeStart, PreciseTimeValue& timeEnd, Object* pSystem, INode* pNode,
                  INode* actionNode, IPFIntegrator* integrator, BitArray& testResult, Tab<float>& testTime );

    // supply ClassDesc descriptor for the concrete implementation of the test
    ClassDesc* GetClassDesc() const;
};
