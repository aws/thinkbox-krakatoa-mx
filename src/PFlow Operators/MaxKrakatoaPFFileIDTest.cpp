// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0

#include "stdafx.h"

#include "resource.h"

#pragma warning( push )
#pragma warning( disable : 4100 )
#pragma warning( disable : 4003 )
#pragma warning( disable : 4512 )
#pragma warning( disable : 4245 )
#pragma warning( disable : 4238 )
#pragma warning( disable : 4239 )

#include "PFlow Operators\MaxKrakatoaPFFileIDTest.h"

#pragma warning( pop )

// custom update dialog process
KrakatoaPFFileIDTestDlgProc theKrakatoaPFFileIDTestDlgProc;

// KrakatoaPFFileIDTest param block
ParamBlockDesc2 KrakatoaPFFileIDTest_paramBlockDesc(
    // required block spec
    kKrakatoaPFFileIDTest_pblock_index, _T("Parameters"), IDS_PARAMS,
    GetKrakatoaPFFileIDTestDesc(), //&TheKrakatoaPFFileIDTestDesc,
    P_AUTO_CONSTRUCT + P_AUTO_UI,
    // auto constuct block refno : none
    kKrakatoaPFFileIDTest_pblock_index,

    // auto ui parammap specs : none
    IDD_FILEIDTEST_PARAMETERS, IDS_PARAMS, 0,
    0, // open/closed
    &theKrakatoaPFFileIDTestDlgProc,
    // required param specs
    // test type
    kKrakatoaPFFileIDTest_use_less_than, _T("UseLessThan"), TYPE_BOOL, P_RESET_DEFAULT, IDS_FILEIDTEST_USELESSTHAN,
    // optional tagged param specs
    p_default, TRUE, p_ms_default, TRUE, p_ui, TYPE_SINGLECHEKBOX, IDC_FILEIDTEST_USELESSTHAN, p_enable_ctrls, 1,
    kKrakatoaPFFileIDTest_less_than, p_end,

    kKrakatoaPFFileIDTest_less_than, _T("LessThan"), TYPE_INT, P_RESET_DEFAULT, IDS_FILEIDTEST_LESSTHAN,
    // optional tagged param specs
    p_default, 0, p_ms_default, 0, p_range, -0x7FFF000, 0x7FFF000, p_ui, TYPE_SPINNER, EDITTYPE_INT,
    IDC_FILEIDTEST_LESSTHAN, IDC_FILEIDTEST_LESSTHAN_SPIN, 1.0f, p_end,

    kKrakatoaPFFileIDTest_use_greater_than, _T("UseGreaterThan"), TYPE_BOOL, P_RESET_DEFAULT,
    IDS_FILEIDTEST_USEGREATERTHAN,
    // optional tagged param specs
    p_default, FALSE, p_ms_default, FALSE, p_ui, TYPE_SINGLECHEKBOX, IDC_FILEIDTEST_USEGREATERTHAN, p_enable_ctrls, 1,
    kKrakatoaPFFileIDTest_greater_than, p_end,

    kKrakatoaPFFileIDTest_greater_than, _T("GreaterThan"), TYPE_INT, P_RESET_DEFAULT, IDS_FILEIDTEST_GREATERTHAN,
    // optional tagged param specs
    p_default, 0, p_ms_default, 0, p_range, -0x7FFF000, 0x7FFF000, p_ui, TYPE_SPINNER, EDITTYPE_INT,
    IDC_FILEIDTEST_GREATERTHAN, IDC_FILEIDTEST_GREATERTHAN_SPIN, 1.0f, p_end,

    // force overlapping: additive or maximum
    kKrakatoaPFFileIDTest_AndOr, _T("AndOr"), TYPE_RADIOBTN_INDEX, P_RESET_DEFAULT, IDS_FILEIDTEST_ANDOR,
    // optional tagged param specs
    p_default, kKrakatoaPFFileIDTest_Or, p_range, 0, kKrakatoaPFFileIDTest_AndOr_num - 1, p_ui, TYPE_RADIO,
    kKrakatoaPFFileIDTest_AndOr_num, IDC_FILEIDTEST_OR, IDC_FILEIDTEST_AND, p_end, p_end );

//+>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>+
//|					custom UI update for Scale Test  					 |
//+>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>+
INT_PTR KrakatoaPFFileIDTestDlgProc::DlgProc( TimeValue /*t*/, IParamMap2* map, HWND /*hWnd*/, UINT msg,
                                              WPARAM /*wParam*/, LPARAM /*lParam*/ ) {
    switch( msg ) {
    case WM_INITDIALOG:
        // Send the message to notify the initialization of dialog
        map->GetParamBlock()->NotifyDependents( FOREVER, (PartID)map, kKrakatoaPFFileIDTest_RefMsg_InitDlg );
        break;
        /*
                case WM_DESTROY:
                        break;
                case WM_COMMAND:
                        pblock = map->GetParamBlock();
                        switch ( LOWORD( wParam ) )
                        {
                        case kKrakatoaPFFileIDTest_message_update:
                                break;
                        }
        */
    }
    return FALSE;
}

// Each plug-in should have one instance of the ClassDesc class

ClassDesc2* GetKrakatoaPFFileIDTestDesc() {
    static KrakatoaPFFileIDTestDesc TheKrakatoaPFFileIDTestDesc;
    return &TheKrakatoaPFFileIDTestDesc;
}

HBITMAP KrakatoaPFFileIDTestDesc::m_depotIcon = NULL;
HBITMAP KrakatoaPFFileIDTestDesc::m_depotMask = NULL;

KrakatoaPFFileIDTestDesc::~KrakatoaPFFileIDTestDesc() {
    if( m_depotIcon != NULL ) {
        DeleteObject( m_depotIcon );
        m_depotIcon = NULL;
    }
    if( m_depotMask != NULL ) {
        DeleteObject( m_depotMask );
        m_depotMask = NULL;
    }
}

int KrakatoaPFFileIDTestDesc::IsPublic() { return 0; }

void* KrakatoaPFFileIDTestDesc::Create( BOOL /*loading*/ ) { return new KrakatoaPFFileIDTest(); }

const TCHAR* KrakatoaPFFileIDTestDesc::ClassName() { return GetString( IDS_FILEIDTEST_CLASSNAME ); }

#if MAX_VERSION_MAJOR >= 24
const TCHAR* KrakatoaPFFileIDTestDesc::NonLocalizedClassName() { return GetString( IDS_FILEIDTEST_CLASSNAME ); }
#endif

SClass_ID KrakatoaPFFileIDTestDesc::SuperClassID() { return HELPER_CLASS_ID; }

Class_ID KrakatoaPFFileIDTestDesc::ClassID() { return KrakatoaPFFileIDTest_Class_ID; }

Class_ID KrakatoaPFFileIDTestDesc::SubClassID() { return PFTestSubClassID; }

const TCHAR* KrakatoaPFFileIDTestDesc::Category() { return GetString( IDS_CATEGORY ); }

const TCHAR* KrakatoaPFFileIDTestDesc::InternalName() { return GetString( IDS_FILEIDTEST_CLASSNAME ); }

HINSTANCE KrakatoaPFFileIDTestDesc::HInstance() { return hInstance; }

INT_PTR KrakatoaPFFileIDTestDesc::Execute( int cmd, ULONG_PTR arg1, ULONG_PTR arg2, ULONG_PTR /*arg3*/ ) {
    TCHAR** res = NULL;
    bool* isPublic;
    HBITMAP* depotIcon;
    HBITMAP* depotMask;
    switch( cmd ) {
    case kPF_GetActionDescription:
        if( arg1 == NULL )
            return 0;
        res = (TCHAR**)arg1;
        *res = GetString( IDS_FILEIDTEST_DESCRIPTION );
        break;
    case kPF_PViewPublic:
        if( arg1 == NULL )
            return 0;
        isPublic = (bool*)arg1;
        *isPublic = true;
        break;
    case kPF_PViewCategory:
        if( arg1 == NULL )
            return 0;
        res = (TCHAR**)arg1;
        *res = GetString( IDS_FILEIDTEST_CATEGORY );
        break;
    case kPF_PViewDepotIcon:
        if( arg1 == NULL )
            return 0;
        depotIcon = (HBITMAP*)arg1;
        if( arg2 == NULL )
            return 0;
        depotMask = (HBITMAP*)arg2;
        if( m_depotIcon == NULL )
            m_depotIcon = LoadBitmap( hInstance, MAKEINTRESOURCE( IDB_FILEIDTEST_ACTIVE_DEPOT ) );
        if( m_depotMask == NULL )
            m_depotMask = LoadBitmap( hInstance, MAKEINTRESOURCE( IDB_FILEIDTEST_MASK_DEPOT ) );
        *depotIcon = m_depotIcon;
        *depotMask = m_depotMask;
        break;
    default:
        return 0;
    }
    return 1;
}

extern HINSTANCE hInstance;

// constructors/destructors
KrakatoaPFFileIDTest::KrakatoaPFFileIDTest() { GetClassDesc()->MakeAutoParamBlocks( this ); }

//+>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>+
//|							From Animatable
//|
//+>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>+
#if MAX_VERSION_MAJOR < 24
void KrakatoaPFFileIDTest::GetClassName( TSTR& s )
#else
void KrakatoaPFFileIDTest::GetClassName( TSTR& s, bool localized )
#endif
{
    s = GetString( IDS_FILEIDTEST_CLASSNAME );
}

//+--------------------------------------------------------------------------+
//|							From Animatable
//|
//+--------------------------------------------------------------------------+
Class_ID KrakatoaPFFileIDTest::ClassID() { return KrakatoaPFFileIDTest_Class_ID; }

//+--------------------------------------------------------------------------+
//|							From Animatable
//|
//+--------------------------------------------------------------------------+
void KrakatoaPFFileIDTest::BeginEditParams( IObjParam* ip, ULONG flags, Animatable* prev ) {
    GetClassDesc()->BeginEditParams( ip, this, flags, prev );
}

//+--------------------------------------------------------------------------+
//|							From Animatable
//|
//+--------------------------------------------------------------------------+
void KrakatoaPFFileIDTest::EndEditParams( IObjParam* ip, ULONG flags, Animatable* next ) {
    GetClassDesc()->EndEditParams( ip, this, flags, next );
}

//+>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>+
//|							From ReferenceMaker
//|
//+>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>+
RefResult KrakatoaPFFileIDTest::NotifyRefChanged( const Interval& /*changeInt*/, RefTargetHandle hTarget,
                                                  PartID& /*partID*/, RefMessage message, BOOL /*propagate*/ ) {
    switch( message ) {
    case REFMSG_CHANGE:
        if( hTarget == pblock() ) {
            ParamID lastUpdateID = pblock()->LastNotifyParamID();
            switch( lastUpdateID ) {
            case kKrakatoaPFFileIDTest_use_less_than:
            case kKrakatoaPFFileIDTest_less_than:
            case kKrakatoaPFFileIDTest_use_greater_than:
            case kKrakatoaPFFileIDTest_greater_than:
                NotifyDependents( FOREVER, 0, kPFMSG_InvalidateParticles, NOTIFY_ALL, TRUE );
                break;
            }
            UpdatePViewUI( lastUpdateID );
        }
        break;
    }
    return REF_SUCCEED;
}

//+--------------------------------------------------------------------------+
//|							From ReferenceMaker
//|
//+--------------------------------------------------------------------------+
RefTargetHandle KrakatoaPFFileIDTest::Clone( RemapDir& remap ) {
    KrakatoaPFFileIDTest* newTest = new KrakatoaPFFileIDTest();
    newTest->ReplaceReference( 0, remap.CloneRef( pblock() ) );
    BaseClone( this, newTest, remap );
    return newTest;
}

//+>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>+
//|							From BaseObject
//|
//+>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>+
#if MAX_VERSION_MAJOR >= 24
const TCHAR* KrakatoaPFFileIDTest::GetObjectName( bool localized ) const {
#elif MAX_VERSION_MAJOR >= 15
const TCHAR* KrakatoaPFFileIDTest::GetObjectName() {
#else
TCHAR* KrakatoaPFFileIDTest::GetObjectName() {
#endif
    return GetString( IDS_FILEIDTEST_CLASSNAME );
}

//+--------------------------------------------------------------------------+
//|							From IPFAction
//|
//+--------------------------------------------------------------------------+
const ParticleChannelMask& KrakatoaPFFileIDTest::ChannelsUsed( const Interval& /*time*/ ) const {
    //  read
    //  &	write channels
    static ParticleChannelMask mask( PCU_Amount, PCU_Amount );
    static bool maskSet( false );
    if( !maskSet ) {
        maskSet = true;
    }
    return mask;
}

//+--------------------------------------------------------------------------+
//|							From IPViewItem
//|
//+--------------------------------------------------------------------------+
HBITMAP KrakatoaPFFileIDTest::GetActivePViewIcon() {
    if( activeIcon() == NULL )
        _activeIcon() = (HBITMAP)LoadImage( hInstance, MAKEINTRESOURCE( IDB_FILEIDTEST_ACTIVE ), IMAGE_BITMAP,
                                            kActionImageWidth, kActionImageHeight, LR_SHARED );
    return activeIcon();
}

HBITMAP KrakatoaPFFileIDTest::GetTruePViewIcon() {
    if( trueIcon() == NULL )
        _trueIcon() = (HBITMAP)LoadImage( hInstance, MAKEINTRESOURCE( IDB_FILEIDTEST_TRUE ), IMAGE_BITMAP,
                                          kActionImageWidth, kActionImageHeight, LR_SHARED );
    return trueIcon();
}

HBITMAP KrakatoaPFFileIDTest::GetFalsePViewIcon() {
    if( falseIcon() == NULL )
        _falseIcon() = (HBITMAP)LoadImage( hInstance, MAKEINTRESOURCE( IDB_FILEIDTEST_FALSE ), IMAGE_BITMAP,
                                           kActionImageWidth, kActionImageHeight, LR_SHARED );
    return falseIcon();
}

//+>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>+
//|							From IPFTest
//|
//+>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>+
bool KrakatoaPFFileIDTest::Proceed( IObject* pCont, PreciseTimeValue timeStart, PreciseTimeValue& timeEnd,
                                    Object* /*pSystem*/, INode* /*pNode*/, INode* /*actionNode*/,
                                    IPFIntegrator* /*integrator*/, BitArray& testResult, Tab<float>& testTime ) {

    try {
        if( pblock() == NULL ) {
            if( this->GetParamBlock( 0 ) != NULL )
                throw std::runtime_error( "KrakatoaPFFileIDTest's pblock was NULL, but Ref0 was not" );
            throw std::runtime_error( "KrakatoaPFFileIDTest's pblock was NULL" );
        }

        // get channel container interface
        IChannelContainer* chCont;
        chCont = GetChannelContainerInterface( pCont );
        if( chCont == NULL )
            throw std::runtime_error( "KrakatoaPFFileIDTest: Could not set up the interface to ChannelContainer" );

        // Make sure we can read the number of current particles in the container
        IParticleChannelAmountR* chAmountR = GetParticleChannelAmountRInterface( pCont );
        if( chAmountR == NULL )
            throw std::runtime_error(
                "KrakatoaPFFileIDTest: Could not set up the interface to IParticleChannelAmountR" );

        int count = chAmountR->Count();
        if( count <= 0 )
            return true;

        // Set up to read from Frantic ID integer channel
        IParticleChannelIntR* chFIDR = GetParticleChannelFileIDIntegerRInterface( pCont );

        if( chFIDR == NULL )
            throw std::runtime_error( "KrakatoaPFFileIDTest: Could not set up the interface to FileIDIntegerR" );

        TimeValue evalTime = ( timeStart.TimeValue() + timeEnd.TimeValue() ) / 2;

        // grab the tests we are using
        int useLessThan = pblock()->GetInt( kKrakatoaPFFileIDTest_use_less_than, evalTime );
        int lessThan = pblock()->GetInt( kKrakatoaPFFileIDTest_less_than, evalTime );
        int useGreaterThan = pblock()->GetInt( kKrakatoaPFFileIDTest_use_greater_than, evalTime );
        int greaterThan = pblock()->GetInt( kKrakatoaPFFileIDTest_greater_than, evalTime );
        int andOr = pblock()->GetInt( kKrakatoaPFFileIDTest_AndOr, 0 );

        testResult.SetSize( count );
        testResult.ClearAll();
        testTime.SetCount( count );

        // check if the radio button enum val is for "or"
        if( andOr == kKrakatoaPFFileIDTest_Or ) {

            if( useLessThan ) {
                for( int i = 0; i < count; i++ ) {
                    if( chFIDR->GetValue( i ) < lessThan ) {
                        testTime[i] = 0.0f;
                        testResult.Set( i );
                    }
                }
            }
            if( useGreaterThan ) {
                for( int i = 0; i < count; i++ ) {
                    if( chFIDR->GetValue( i ) > greaterThan ) {
                        testTime[i] = 0.0f;
                        testResult.Set( i );
                    }
                }
            }
        } else {

            if( useLessThan ) {
                for( int i = 0; i < count; i++ ) {
                    if( chFIDR->GetValue( i ) < lessThan ) {
                        testTime[i] = 0.0f;
                        testResult.Set( i );
                    }
                }
            } else
                testResult.SetAll();

            if( useGreaterThan ) {
                for( int i = 0; i < count; i++ ) {
                    if( chFIDR->GetValue( i ) <= greaterThan ) {
                        testTime[i] = 0.0f;
                        testResult.Clear( i );
                    }
                }
            }
        }

    } catch( std::exception& e ) {
        GetCOREInterface()->Log()->LogEntry( SYSLOG_ERROR, DISPLAY_DIALOG, _T("KrakatoaPFFileIDTest::Proceed() Error"),
                                             HANDLE_STD_EXCEPTION_MSG( e ) );
        if( IsNetworkRenderServer() )
            throw MAXException( HANDLE_STD_EXCEPTION_MSG( e ) );
        return false;
    }

    return true;
}

ClassDesc* KrakatoaPFFileIDTest::GetClassDesc() const { return GetKrakatoaPFFileIDTestDesc(); }
