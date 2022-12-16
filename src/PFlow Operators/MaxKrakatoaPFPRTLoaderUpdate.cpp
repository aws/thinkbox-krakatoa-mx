// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0
#include "stdafx.h"

#include "resource.h"

#include "Objects\MaxKrakatoaPRTLoader.h"
#include "PFlow Operators\MaxKrakatoaExcludePFlowValidator.hpp"
#include "PFlow Operators\MaxKrakatoaPFChannelInterface.h"
#include "PFlow Operators\MaxKrakatoaPFPRTLoaderUpdate.h"

#include <boost/assign.hpp>
#include <boost/make_shared.hpp>

#include <frantic/channels/channel_accessor.hpp>
#include <frantic/graphics/vector3f.hpp>
#include <frantic/logging/logging_level.hpp>

#include <frantic/max3d/particles/particle_stream_factory.hpp>
#include <frantic/max3d/particles/particle_system_validator.hpp>
#include <frantic/particles/particle_file_stream_factory.hpp>
#include <frantic/particles/streams/fractional_by_id_particle_istream.hpp>
#include <frantic/particles/streams/fractional_particle_istream.hpp>
#include <frantic/particles/streams/functor_particle_istream.hpp>
#include <frantic/particles/streams/transformed_particle_istream.hpp>

// I don't like disabling warning 4239 (doing so promotes non cross-platform compatible code), but the Particle Flow SDK
// basically forces my hand here.
#pragma warning( disable : 4239 )

using namespace std;
// using namespace boost;
using boost::shared_ptr;
using namespace frantic;
using namespace frantic::particles;
using namespace frantic::particles::streams;
using namespace frantic::channels;
using namespace frantic::max3d::particles;
using namespace frantic::max3d;

bool is_valid_pflow_channel( const frantic::tstring& name ) {

    if( name == _T("ID") )
        return true;
    if( name == _T("Position") )
        return true;
    if( name == _T("Velocity") )
        return true;
    if( name == _T("Acceleration") )
        return true;
    if( name == _T("Color") )
        return true;
    if( name == _T("Scale") )
        return true;
    if( name == _T("Orientation") )
        return true;
    if( name == _T("Spin") )
        return true;
    if( name == _T("TextureCoord") )
        return true;
    if( name == _T("Age") )
        return true;
    if( name == _T("LifeSpan") )
        return true;
    if( name == _T("New") )
        return true;
    if( name == _T("MXSFloat") )
        return true;
    if( name == _T("MXSVector") )
        return true;
    if( name == _T("MXSInt") )
        return true;
    if( name == _T("MtlIndex") )
        return true;
    for( int i = 2; i <= 100; ++i )
        if( name == _T("Mapping") + boost::lexical_cast<frantic::tstring>( i ) )
            return true;

    return false;
}

//----------------------------------------------------
// Class Descriptor stuff for exposing the plugin to Max
//----------------------------------------------------
class KrakatoaPFPRTLoaderUpdateDesc : public ClassDesc2 {
  public:
    static HBITMAP m_depotIcon;
    static HBITMAP m_depotMask;

    static ParamBlockDesc2 pblock_desc;
    static KrakatoaPFPRTLoaderUpdateParamProc* dialog_proc;

    void* Create( BOOL ) { return new KrakatoaPFPRTLoaderUpdate; }
    int IsPublic() { return FALSE; }
    const TCHAR* ClassName() { return GetString( IDS_PRTLOADERUPDATE_CLASSNAME ); }
#if MAX_VERSION_MAJOR >= 24
    const TCHAR* NonLocalizedClassName() { return GetString( IDS_PRTLOADERUPDATE_CLASSNAME ); }
#endif
    SClass_ID SuperClassID() { return HELPER_CLASS_ID; }
    Class_ID ClassID() { return KrakatoaPFPRTLoaderUpdate_Class_ID; }
    Class_ID SubClassID() { return PFOperatorSubClassID; }
    const TCHAR* Category() { return _T("Particle Flow"); }
    const TCHAR* InternalName() { return GetString( IDS_PRTLOADERUPDATE_CLASSNAME ); }
    HINSTANCE HInstance() { return hInstance; }

    INT_PTR Execute( int cmd, ULONG_PTR arg1, ULONG_PTR arg2, ULONG_PTR arg3 );
};

INT_PTR KrakatoaPFPRTLoaderUpdateDesc::Execute( int cmd, ULONG_PTR arg1, ULONG_PTR arg2, ULONG_PTR /*arg3*/ ) {
    TCHAR** res = NULL;
    HBITMAP* depotIcon;
    HBITMAP* depotMask;
    switch( cmd ) {
    case kPF_GetActionDescription:
        if( arg1 == NULL )
            return 0;
        res = (TCHAR**)arg1;
        *res = _T("Loads data from a sequence of particles in a selected PRT Object.");
        break;
    case kPF_PViewCategory:
        if( arg1 == NULL )
            return 0;
        res = (TCHAR**)arg1;
        *res = _T("Operator"); // Important: This makes the op show up in the correct category of the right click menu
        break;
    case kPF_PViewDepotIcon:
        if( arg1 == NULL )
            return 0;
        depotIcon = (HBITMAP*)arg1;
        if( arg2 == NULL )
            return 0;
        depotMask = (HBITMAP*)arg2;
        if( m_depotIcon == NULL )
            m_depotIcon = LoadBitmap( hInstance, MAKEINTRESOURCE( IDB_PRTLOADERUPDATE_ACTIVE_DEPOT ) );
        if( m_depotMask == NULL )
            m_depotMask = LoadBitmap( hInstance, MAKEINTRESOURCE( IDB_PRTLOADERUPDATE_MASK_DEPOT ) );
        *depotIcon = m_depotIcon;
        *depotMask = m_depotMask;
        break;
    default:
        return 0;
    }
    return 1;
}

HBITMAP KrakatoaPFPRTLoaderUpdateDesc::m_depotIcon = NULL;
HBITMAP KrakatoaPFPRTLoaderUpdateDesc::m_depotMask = NULL;

//----------------------------------------------------
// End of KrakatoaPFPRTLoaderUpdateDesc
//----------------------------------------------------

ClassDesc2* GetKrakatoaPFPRTLoaderUpdateDesc() {
    static KrakatoaPFPRTLoaderUpdateDesc theKrakatoaPFPRTLoaderUpdateDesc;
    return &theKrakatoaPFPRTLoaderUpdateDesc;
}

class KrakatoaPFPRTLoaderUpdateParamProc : public ParamMap2UserDlgProc {
    BOOL m_isInitializing;

  public:
    void handle_init( HWND hWnd, IParamBlock2* pblock );
    void handle_channel_list( HWND hWnd, IParamBlock2* pblock );
    void handle_channel_selection( HWND hWnd, IParamBlock2* pblock, int selection );
    void handle_channel_used( HWND hWnd, IParamBlock2* pblock );
    void handle_channel_alpha( HWND hWnd, IParamBlock2* pblock );
    void handle_channel_flags( HWND hWnd, IParamBlock2* pblock );

    void DeleteThis() {}
    INT_PTR DlgProc( TimeValue t, IParamMap2* map, HWND hWnd, UINT msg, WPARAM wParam, LPARAM lParam );
};

void KrakatoaPFPRTLoaderUpdateParamProc::handle_init( HWND hWnd, IParamBlock2* pblock ) {
    m_isInitializing = FALSE;

    // Init the list-view icons.
    HWND hListView = GetDlgItem( hWnd, IDC_PRTLOADERUPDATE_LISTVIEW );

    ListView_SetExtendedListViewStyleEx( hListView, LVS_EX_CHECKBOXES, LVS_EX_CHECKBOXES );

    /*int imgX = GetSystemMetrics(SM_CXSMICON);
    int imgY = GetSystemMetrics(SM_CYSMICON);
    HIMAGELIST hState = ImageList_Create(imgX, imgY, 0, 1, 1);

    HDC listDC = CreateCompatibleDC( GetDC( hListView ) );
    HBITMAP bmpChecked = CreateCompatibleBitmap( listDC, imgX, imgY );
    HBITMAP bmpUnChecked = CreateCompatibleBitmap( listDC, imgX, imgY );

    BOOL drawResult;
    RECT bmpRect;
    bmpRect.top = bmpRect.left = 0;
    bmpRect.right = imgX;
    bmpRect.bottom = imgY;

    SelectObject( listDC, bmpUnChecked );
    drawResult = DrawFrameControl( listDC, &bmpRect, DFC_BUTTON, DFCS_BUTTONCHECK | DFCS_CHECKED );

    SelectObject( listDC, bmpChecked );
    drawResult = DrawFrameControl( listDC, &bmpRect, DFC_BUTTON, DFCS_BUTTONCHECK | DFCS_CHECKED );

    int index1 = ImageList_Add( hState, bmpUnChecked, NULL );
    int index2 = ImageList_Add( hState, bmpChecked, NULL );

    DeleteObject( bmpUnChecked );
    DeleteObject( bmpChecked );
    DeleteObject( listDC );

    HANDLE hImgList = ListView_SetImageList( hListView, hState, LVSIL_STATE ); */

    RECT listRect;
    GetClientRect( hListView, &listRect );

    LVCOLUMN listCol;
    memset( &listCol, 0, sizeof( LVCOLUMN ) );

    listCol.mask = LVCF_FMT | LVCF_WIDTH | LVCF_TEXT;
    listCol.pszText = _T("Channel");
    listCol.fmt = LVCFMT_LEFT;
    listCol.cx = listRect.right - listRect.left - GetSystemMetrics( SM_CXVSCROLL ); // Make space for the scrollbar
    ListView_InsertColumn( hListView, 0, &listCol );

    ISpinnerControl* pSpin = GetISpinner( GetDlgItem( hWnd, IDC_PRTLOADERUPDATE_CHANNEL_AMOUNT_SPIN ) );
    pSpin->LinkToEdit( GetDlgItem( hWnd, IDC_PRTLOADERUPDATE_CHANNEL_AMOUNT ), EDITTYPE_FLOAT );
    pSpin->SetLimits( 0.f, 100.f, FALSE );
    pSpin->SetResetValue( 100.f );
    pSpin->SetAutoScale( TRUE );
    ReleaseISpinner( pSpin );

    handle_channel_list( hWnd, pblock );
    handle_channel_selection( hWnd, pblock, -1 );
}

void KrakatoaPFPRTLoaderUpdateParamProc::handle_channel_list( HWND hWnd, IParamBlock2* pblock ) {
    m_isInitializing = TRUE;

    HWND hListView = GetDlgItem( hWnd, IDC_PRTLOADERUPDATE_LISTVIEW );

    // Clear any current entries
    ListView_DeleteAllItems( hListView );

    // Set the list view entries, if there are any
    int numItems = pblock->Count( kKrakatoaPFPRTLoaderUpdate_channels );

    if( numItems > 0 ) {
        LVITEM lvI;
        ZeroMemory( &lvI, sizeof( LVITEM ) );

        lvI.mask = LVIF_TEXT;

        for( int i = 0; i < numItems; ++i ) {
            lvI.iItem = i;
            lvI.pszText = const_cast<TCHAR*>( pblock->GetStr( kKrakatoaPFPRTLoaderUpdate_channels, 0, i ) );
            int index = ListView_InsertItem( hListView, &lvI );
            if( index < 0 )
                throw std::runtime_error(
                    "KrakatoaPFPRTLoaderUpdateParamProc::handle_channel_list() Error setting list view item." );
            BOOL enabled = pblock->GetInt( kKrakatoaPFPRTLoaderUpdate_channel_use, 0, i );
            ListView_SetCheckState( hListView, i, enabled );
        }
    }

    m_isInitializing = FALSE;
}

void KrakatoaPFPRTLoaderUpdateParamProc::handle_channel_selection( HWND hWnd, IParamBlock2* pblock, int selection ) {
    KrakatoaPFPRTLoaderUpdate* pObj = static_cast<KrakatoaPFPRTLoaderUpdate*>( pblock->GetOwner() );
    if( !pObj )
        return;

    pObj->m_currentSelection = selection;

    int style = kKrakatoaPFPRTLoaderUpdate_channel_blend;
    BOOL currentUsed = BST_UNCHECKED;
    float currentAlpha = 0.f;

    if( selection >= 0 ) {
        if( pblock->GetInt( kKrakatoaPFPRTLoaderUpdate_channel_use, 0, selection ) != 0 )
            currentUsed = BST_CHECKED;
        currentAlpha = pblock->GetFloat( kKrakatoaPFPRTLoaderUpdate_channel_alphas, 0, selection );
        style = pblock->GetInt( kKrakatoaPFPRTLoaderUpdate_channel_options, 0, selection );
    }

    ISpinnerControl* pSpin = GetISpinner( GetDlgItem( hWnd, IDC_PRTLOADERUPDATE_CHANNEL_AMOUNT_SPIN ) );
    pSpin->SetValue( currentAlpha, FALSE );
    ReleaseISpinner( pSpin );

    switch( style ) {
    case kKrakatoaPFPRTLoaderUpdate_channel_blend:
        CheckRadioButton( hWnd, IDC_PRTLOADERUPDATE_BLEND, IDC_PRTLOADERUPDATE_ADD, IDC_PRTLOADERUPDATE_BLEND );
        break;
    case kKrakatoaPFPRTLoaderUpdate_channel_add:
        CheckRadioButton( hWnd, IDC_PRTLOADERUPDATE_BLEND, IDC_PRTLOADERUPDATE_ADD, IDC_PRTLOADERUPDATE_ADD );
        break;
    }

    SendMessage( GetDlgItem( hWnd, IDC_PRTLOADERUPDATE_USE_CHANNEL ), BM_SETCHECK, (WPARAM)currentUsed, (LPARAM)0 );
}

void KrakatoaPFPRTLoaderUpdateParamProc::handle_channel_used( HWND hWnd, IParamBlock2* pblock ) {
    KrakatoaPFPRTLoaderUpdate* pObj = static_cast<KrakatoaPFPRTLoaderUpdate*>( pblock->GetOwner() );
    if( !pObj )
        return;

    if( pObj->m_currentSelection >= 0 ) {
        BOOL currentUsed = IsDlgButtonChecked( hWnd, IDC_PRTLOADERUPDATE_USE_CHANNEL );

        pblock->SetValue( kKrakatoaPFPRTLoaderUpdate_channel_use, 0, currentUsed, pObj->m_currentSelection );

        // HWND hListView = GetDlgItem(hWnd, IDC_PRTLOADERUPDATE_LISTVIEW);
        // ListView_SetCheckState( hListView, pObj->m_currentSelection, currentUsed );
        HWND hListView = GetDlgItem( hWnd, IDC_PRTLOADERUPDATE_LISTVIEW );
        ListView_Update( hListView, pObj->m_currentSelection );
    }
}

void KrakatoaPFPRTLoaderUpdateParamProc::handle_channel_alpha( HWND hWnd, IParamBlock2* pblock ) {
    KrakatoaPFPRTLoaderUpdate* pObj = static_cast<KrakatoaPFPRTLoaderUpdate*>( pblock->GetOwner() );
    if( !pObj )
        return;

    if( pObj->m_currentSelection >= 0 ) {
        ISpinnerControl* pSpin = GetISpinner( GetDlgItem( hWnd, IDC_PRTLOADERUPDATE_CHANNEL_AMOUNT_SPIN ) );

        float currentAlpha = pSpin->GetFVal();
        pblock->SetValue( kKrakatoaPFPRTLoaderUpdate_channel_alphas, 0, currentAlpha, pObj->m_currentSelection );

        ReleaseISpinner( pSpin );
    }
}

void KrakatoaPFPRTLoaderUpdateParamProc::handle_channel_flags( HWND hWnd, IParamBlock2* pblock ) {
    KrakatoaPFPRTLoaderUpdate* pObj = static_cast<KrakatoaPFPRTLoaderUpdate*>( pblock->GetOwner() );
    if( !pObj )
        return;

    if( pObj->m_currentSelection >= 0 ) {
        int value = 0;
        if( IsDlgButtonChecked( hWnd, IDC_PRTLOADERUPDATE_BLEND ) ) {
            value = kKrakatoaPFPRTLoaderUpdate_channel_blend;
        } else if( IsDlgButtonChecked( hWnd, IDC_PRTLOADERUPDATE_ADD ) ) {
            value = kKrakatoaPFPRTLoaderUpdate_channel_add;
        }
        pblock->SetValue( kKrakatoaPFPRTLoaderUpdate_channel_options, 0, value, pObj->m_currentSelection );
    }
}

#define WM_USER_REDO_LISTVIEW WM_USER + 0x0005

INT_PTR KrakatoaPFPRTLoaderUpdateParamProc::DlgProc( TimeValue t, IParamMap2* map, HWND hWnd, UINT msg, WPARAM wParam,
                                                     LPARAM lParam ) {
    IParamBlock2* pblock = map->GetParamBlock();
    if( !pblock )
        return FALSE;

    KrakatoaPFPRTLoaderUpdate* pObj = static_cast<KrakatoaPFPRTLoaderUpdate*>( pblock->GetOwner() );
    if( !pObj )
        return FALSE;

    switch( msg ) {
    case WM_INITDIALOG:
        handle_init( hWnd, pblock );
        break;
    case WM_NOTIFY: {
        NMHDR* pInfo = reinterpret_cast<NMHDR*>( lParam );
        if( pInfo->idFrom == IDC_PRTLOADERUPDATE_LISTVIEW ) {
            /*if( pInfo->code == LVN_ITEMCHANGING ){
                    NMLISTVIEW* pViewInfo = reinterpret_cast<NMLISTVIEW*>( lParam );
                    SetWindowLongPtr( hWnd, DWLP_MSGRESULT, FALSE );
                    return TRUE;
            }else */
            if( pInfo->code == LVN_ITEMCHANGED ) {
                if( !m_isInitializing ) {
                    NMLISTVIEW* pViewInfo = reinterpret_cast<NMLISTVIEW*>( lParam );
                    if( ( pViewInfo->uChanged & LVIF_STATE ) != 0 ) {
                        if( ( ( pViewInfo->uOldState ^ pViewInfo->uNewState ) & LVIS_SELECTED ) != 0 ) {
                            int selID = -1;
                            if( ( pViewInfo->uNewState & LVIS_SELECTED ) != 0 )
                                selID = pViewInfo->iItem;
                            if( selID != pObj->m_currentSelection )
                                handle_channel_selection( hWnd, pblock, selID );
                        }

                        if( ( ( pViewInfo->uOldState ^ pViewInfo->uNewState ) & LVIS_STATEIMAGEMASK ) != 0 ) {
                            BOOL enabled = ( ( pViewInfo->uNewState & LVIS_STATEIMAGEMASK ) >> 12 ) == 2;
                            pblock->SetValue( kKrakatoaPFPRTLoaderUpdate_channel_use, 0, enabled, pViewInfo->iItem );

                            // Update the checkbox if this is the current selected item.
                            // if( pObj->m_currentSelection == pViewInfo->iItem )
                            //	CheckDlgButton( hWnd, IDC_PRTLOADERUPDATE_USE_CHANNEL, enabled ? BST_CHECKED :
                            //BST_UNCHECKED );
                        }
                    }
                }
            } // else if( pInfo->code == LVN_GETDISPINFO ){
            //	NMLVDISPINFO* pDispInfo = reinterpret_cast<NMLVDISPINFO*>( lParam );
            //	if( pDispInfo->item.iItem >= 0 ){
            //		if( (pDispInfo->item.mask & LVIF_TEXT) != 0 ){
            //			pDispInfo->item.pszText = (TCHAR*)pblock->GetStr( kKrakatoaPFPRTLoaderUpdate_channels, 0,
            //pDispInfo->item.iItem ); 		}else if( (pDispInfo->item.mask & LVIF_STATE) != 0 ){ 			if(
            //(pDispInfo->item.stateMask & LVIS_STATEIMAGEMASK) != 0 ){ 				BOOL enabled = pblock->GetInt(
            //kKrakatoaPFPRTLoaderUpdate_channel_use, 0, pDispInfo->item.iItem );
            //				//Clear the state bits, then set the new ones.
            //				pDispInfo->item.state &= LVIS_STATEIMAGEMASK;
            //				pDispInfo->item.state |= INDEXTOSTATEIMAGEMASK( (enabled ? 2 : 1) );
            //			}
            //		}
            //	}

            //	return TRUE;
            //}else if( pInfo->code == LVN_SETDISPINFO ){
            //	NMLVDISPINFO* pDispInfo = reinterpret_cast<NMLVDISPINFO*>( lParam );
            //	std::cout << "";
            //}
        }
        break;
    }
    case WM_COMMAND: {
        switch( LOWORD( wParam ) ) {
        case IDC_PRTLOADERUPDATE_CLEAR_PRT_LOADER:
            pblock->SetValue( kKrakatoaPFPRTLoaderUpdate_pick_PRT_loader, t, (INode*)NULL );
            map->SetText( kKrakatoaPFPRTLoaderUpdate_pick_PRT_loader, _T("None") );
            pObj->m_pPrevLoader = NULL;

            ListView_DeleteAllItems( GetDlgItem( hWnd, IDC_PRTLOADERUPDATE_LISTVIEW ) );
            handle_channel_selection( hWnd, pblock, -1 );
            break;
        /*case IDC_PRTLOADERUPDATE_USE_CHANNEL:
                if( HIWORD(wParam) == BN_CLICKED )
                        handle_channel_used(hWnd, pblock);
                break;*/
        case IDC_PRTLOADERUPDATE_BLEND:
        case IDC_PRTLOADERUPDATE_ADD:
            if( HIWORD( wParam ) == BN_CLICKED )
                handle_channel_flags( hWnd, pblock );
            break;
        }
        break;
    }
    case WM_USER_REDO_LISTVIEW:
        handle_channel_list( hWnd, pblock );
        break;
    case CC_SPINNER_CHANGE:
        if( LOWORD( wParam ) == IDC_PRTLOADERUPDATE_CHANNEL_AMOUNT_SPIN )
            handle_channel_alpha( hWnd, pblock );
        break;
    }
    return FALSE;
}

KrakatoaPFPRTLoaderUpdateParamProc* KrakatoaPFPRTLoaderUpdateDesc::dialog_proc =
    new KrakatoaPFPRTLoaderUpdateParamProc();

//----------------------------------------------------
// Param Block info
//----------------------------------------------------
ParamBlockDesc2 KrakatoaPFPRTLoaderUpdateDesc::pblock_desc(
    // required block spec
    kKrakatoaPFPRTLoaderUpdate_pblock_index, _T("Parameters"), IDS_PARAMS, GetKrakatoaPFPRTLoaderUpdateDesc(),
    P_AUTO_CONSTRUCT + P_AUTO_UI,
    // auto constuct block refno : none
    0,
    // auto ui parammap specs : none
    IDD_PRTLOADERUPDATE_PARAMETERS, IDS_PARAMS, 0,
    0, // open/closed
    KrakatoaPFPRTLoaderUpdateDesc::dialog_proc,

    kKrakatoaPFPRTLoaderUpdate_pick_PRT_loader, _T("PickPRTLoader"), TYPE_INODE, 0, IDS_GEOMETRYTEST_PICK_GEOMETRY_NODE,
    p_ui, TYPE_PICKNODEBUTTON, IDC_PRTLOADERUPDATE_PICK_PRT_LOADER, p_validator, GetMaxKrakatoaExcludePFlowValidator(),
    p_end,

    kKrakatoaPFPRTLoaderUpdate_channels, _T("UpdateChannels"), TYPE_STRING_TAB,
    0, // size
    P_VARIABLE_SIZE + P_AUTO_UI, IDS_FILEUPDATE_BLEND_CHANNEL_NAMES, p_ui, TYPE_STRINGLISTBOX,
    IDC_PRTLOADERUPDATE_CHANNEL_LIST, 0, 0, 0, 0, p_end,

    kKrakatoaPFPRTLoaderUpdate_channel_alphas, _T("ChannelAlphas"),
    TYPE_FLOAT_TAB,                     // type
    0,                                  // size
    P_VARIABLE_SIZE,                    // + P_ANIMATABLE + P_TV_SHOW_ALL,  // flags
    IDS_PRTLOADERUPDATE_CHANNEL_ALPHAS, // name
    p_end,

    kKrakatoaPFPRTLoaderUpdate_channel_use, _T("ChannelUse"),
    TYPE_INT_TAB,    // type
    0,               // size
    P_VARIABLE_SIZE, // flags
    IDS_FILEUPDATE_BLEND_CHANNEL_USE, p_end,

    kKrakatoaPFPRTLoaderUpdate_channel_options, _T("ChannelOptions"),
    TYPE_INT_TAB,    // type
    0,               // size
    P_VARIABLE_SIZE, // flags
    IDS_FILEUPDATE_BLEND_CHANNEL_USE, p_end, kKrakatoaPFPRTLoaderUpdate_adjust_position,
    _T("AdjustPositionForVelocity"), TYPE_BOOL, 0, 0, p_default, TRUE, p_ui, TYPE_SINGLECHEKBOX,
    IDC_PRTLOADERUPDATE_ADJUSTPOSITION_CHECK, p_end,

    p_end );
//----------------------------------------------------
// End of Param Block info
//----------------------------------------------------

//----------------------------------------------------
// Simple useless functions
//----------------------------------------------------
KrakatoaPFPRTLoaderUpdate::KrakatoaPFPRTLoaderUpdate() {
    GetClassDesc()->MakeAutoParamBlocks( this );

    m_pPrevLoader = NULL;
    m_currentSelection = -1;
}

KrakatoaPFPRTLoaderUpdate::~KrakatoaPFPRTLoaderUpdate() {}

// We need to save a backpatch ID of the pointer that is cached to the previous node.
IOResult KrakatoaPFPRTLoaderUpdate::Save( ISave* isave ) {
    int refID = -1;
    if( m_pPrevLoader )
        refID = isave->GetRefID( m_pPrevLoader );

    ULONG nWritten;
    IOResult status;

    isave->BeginChunk( 0 );
    status = isave->Write( &refID, sizeof( refID ), &nWritten );
    if( status != IO_OK )
        return status;
    isave->EndChunk();

    return PFSimpleOperator::Save( isave );
}

// We need to backpatch the cached pointer to the last picked PRT Loader node.
IOResult KrakatoaPFPRTLoaderUpdate::Load( ILoad* iload ) {
    ULONG nRead;
    int refID = -1;
    IOResult status;

    status = iload->OpenChunk();
    while( status != IO_END ) {
        switch( iload->CurChunkID() ) {
        case 0:
            status = iload->Read( &refID, sizeof( refID ), &nRead );
            if( status != IO_OK )
                return status;
            break;
        }

        status = iload->CloseChunk();
        if( status != IO_OK )
            return status;

        status = iload->OpenChunk();
        if( status == IO_ERROR )
            return status;
    }

    if( refID != -1 )
        iload->RecordBackpatch( refID, (void**)&m_pPrevLoader );
    return PFSimpleOperator::Load( iload );
}

Class_ID KrakatoaPFPRTLoaderUpdate::ClassID() { return GetClassDesc()->ClassID(); }

ClassDesc* KrakatoaPFPRTLoaderUpdate::GetClassDesc() const { return GetKrakatoaPFPRTLoaderUpdateDesc(); }

#if MAX_VERSION_MAJOR < 24
void KrakatoaPFPRTLoaderUpdate::GetClassName( TSTR& s ) {
#else
void KrakatoaPFPRTLoaderUpdate::GetClassName( TSTR& s, bool localized ) {
#endif
    s = GetKrakatoaPFPRTLoaderUpdateDesc()->ClassName();
}

void KrakatoaPFPRTLoaderUpdate::BeginEditParams( IObjParam* ip, ULONG flags, Animatable* prev ) {
    GetClassDesc()->BeginEditParams( ip, this, flags, prev );
}

void KrakatoaPFPRTLoaderUpdate::EndEditParams( IObjParam* ip, ULONG flags, Animatable* next ) {
    GetClassDesc()->EndEditParams( ip, this, flags, next );
}

const ParticleChannelMask& KrakatoaPFPRTLoaderUpdate::ChannelsUsed( const Interval& /*time*/ ) const {
    static ParticleChannelMask mask( PCU_Amount | PCU_Position | PCU_Speed, PCU_Position | PCU_Speed );
    return mask;
}

const Interval KrakatoaPFPRTLoaderUpdate::ActivityInterval() const {
    Interval interval;
    interval = GetCOREInterface()->GetAnimRange();
    return interval;
    // return Interval( interval.Start() - GetTicksPerFrame() * 2, interval.End() );
}

RefTargetHandle KrakatoaPFPRTLoaderUpdate::Clone( RemapDir& remap ) {
    KrakatoaPFPRTLoaderUpdate* newOp = new KrakatoaPFPRTLoaderUpdate();
    newOp->ReplaceReference( 0, remap.CloneRef( GetReference( 0 ) ) );
    BaseClone( this, newOp, remap );
    return newOp;
}

#if MAX_VERSION_MAJOR >= 24
const TCHAR* KrakatoaPFPRTLoaderUpdate::GetObjectName( bool localized ) const {
#elif MAX_VERSION_MAJOR >= 15
const TCHAR* KrakatoaPFPRTLoaderUpdate::GetObjectName() {
#else
TCHAR* KrakatoaPFPRTLoaderUpdate::GetObjectName() {
#endif
    return GetString( IDS_PRTLOADERUPDATE_CLASSNAME );
}

//----------------------------------------------------
// Meaty Important Functions
//----------------------------------------------------
RefResult KrakatoaPFPRTLoaderUpdate::NotifyRefChanged( const Interval& /*changeInt*/, RefTargetHandle hTarget,
                                                       PartID& partID, RefMessage message, BOOL /*propagate*/ ) {
    try {
        switch( message ) {
        case REFMSG_CHANGE: {
            if( hTarget == pblock() ) {
                int lastUpdateID = pblock()->LastNotifyParamID();
                switch( lastUpdateID ) {
                case kKrakatoaPFPRTLoaderUpdate_channels:
                case kKrakatoaPFPRTLoaderUpdate_channel_use:
                case kKrakatoaPFPRTLoaderUpdate_channel_alphas:
                case kKrakatoaPFPRTLoaderUpdate_channel_options: {
                    int numMaps = NumPViewParamMaps();
                    for( int i = 0; i < numMaps; ++i ) {
                        IParamMap2* pMap = GetPViewParamMap( i );
                        if( pMap && !pMap->DlgActive() )
                            SendMessage( pMap->GetHWnd(), WM_USER_REDO_LISTVIEW, (WPARAM)0,
                                         (LPARAM)0 ); // overkill, a simpler update is suggested.
                    }

                    NotifyDependents( FOREVER, 0, kPFMSG_InvalidateParticles, NOTIFY_ALL, TRUE );
                    break;
                }
                case kKrakatoaPFPRTLoaderUpdate_pick_PRT_loader: {
                    INode* prtLoaderNode = pblock()->GetINode( kKrakatoaPFPRTLoaderUpdate_pick_PRT_loader );

                    if( prtLoaderNode ) {
                        if( CheckForBadPRTSourceReference( prtLoaderNode, m_pblock, kTargetNode,
                                                           frantic::tstring( _T( "Krakatoa PRT Update" ) ) ) ) {
                            break;
                        }
                    }

                    // Cache the previously seen loader so that I can tell if a
                    // entirely new node has been picked. I hope there is an easier way
                    // than this.
                    bool isNewObj = ( m_pPrevLoader != prtLoaderNode );
                    m_pPrevLoader = prtLoaderNode;

                    if( !prtLoaderNode ) {
                        if( isNewObj ) {
                            pblock()->ZeroCount( kKrakatoaPFPRTLoaderUpdate_channels );
                            pblock()->ZeroCount( kKrakatoaPFPRTLoaderUpdate_channel_use );
                            pblock()->ZeroCount( kKrakatoaPFPRTLoaderUpdate_channel_alphas );
                            pblock()->ZeroCount( kKrakatoaPFPRTLoaderUpdate_channel_options );
                        }

                        break;
                    }

                    channel_map pcm;
                    pcm.define_channel<int>( _T( "ID" ) );
                    pcm.define_channel<frantic::graphics::vector3f>( _T( "Position" ) );
                    pcm.end_channel_definition( 1, true );
                    boost::shared_ptr<frantic::particles::streams::particle_istream> pin =
                        frantic::max3d::particles::max_particle_istream_factory( prtLoaderNode, pcm,
                                                                                 GetCOREInterface()->GetTime(), 0 );
                    if( !pin )
                        break;

                    frantic::channels::channel_map nativeChannelMap = pin->get_native_channel_map();

                    if( isNewObj && !nativeChannelMap.has_channel( _T("ID") ) ) {
                        static const TCHAR* NO_ID_ERROR_HEADER = _T("Krakatoa PRTLoaderUpdate WARNING");
                        static const TCHAR* NO_ID_ERROR_MSG =
                            _T("WARNING:  The selected PRT Object has no ID channel.\nParticles will be assigned IDs ")
                            _T("based upon the order that they appear in the file.\nThis is likely to cause ")
                            _T("inconsistent behavior.");

                        LogSys* log = GetCOREInterface()->Log();
                        if( log )
                            log->LogEntry( SYSLOG_WARN, DISPLAY_DIALOG, (TCHAR*)NO_ID_ERROR_HEADER,
                                           (TCHAR*)NO_ID_ERROR_MSG );
                    }

                    // We need to save the old selection information, so that it can be transferred to the new object.
                    Tab<const TCHAR*> oldChannels;
                    Tab<int> oldChannelsUse;
                    Tab<float> oldChannelsAlpha;
                    Tab<int> oldChannelsOptions;

                    int oldCount = pblock()->Count( kKrakatoaPFPRTLoaderUpdate_channels );
                    oldChannels.SetCount( oldCount );
                    oldChannelsUse.SetCount( oldCount );
                    oldChannelsAlpha.SetCount( oldCount );
                    oldChannelsOptions.SetCount( oldCount );

                    for( int i = 0; i < oldCount; ++i ) {
                        oldChannels[i] = pblock()->GetStr( kKrakatoaPFPRTLoaderUpdate_channels, 0, i );
                        oldChannelsUse[i] = pblock()->GetInt( kKrakatoaPFPRTLoaderUpdate_channel_use, 0, i );
                        oldChannelsAlpha[i] = pblock()->GetFloat( kKrakatoaPFPRTLoaderUpdate_channel_alphas, 0, i );
                        oldChannelsOptions[i] = pblock()->GetInt( kKrakatoaPFPRTLoaderUpdate_channel_options, 0, i );
                    }

                    int channelCount = 0;
                    for( int i = 0; i < (int)nativeChannelMap.channel_count(); ++i ) {
                        if( is_valid_pflow_channel( nativeChannelMap[i].name() ) )
                            ++channelCount;
                    }

                    pblock()->SetCount( kKrakatoaPFPRTLoaderUpdate_channels, channelCount );
                    pblock()->SetCount( kKrakatoaPFPRTLoaderUpdate_channel_use, channelCount );
                    pblock()->SetCount( kKrakatoaPFPRTLoaderUpdate_channel_alphas, channelCount );
                    pblock()->SetCount( kKrakatoaPFPRTLoaderUpdate_channel_options, channelCount );

                    channelCount = 0;
                    for( int i = 0; i < (int)nativeChannelMap.channel_count(); ++i ) {
                        const frantic::tstring& channelName = nativeChannelMap[i].name();
                        if( is_valid_pflow_channel( channelName ) ) {
                            int flags = 0;
                            float alpha = 100.f;
                            BOOL shouldSelect = FALSE;

                            // Do a linear search through the old selection information, looking for
                            // a matching enabled channel.
                            for( int j = 0; j < oldCount && !shouldSelect; ++j ) {
                                if( oldChannelsUse[j] && oldChannels[j] ) {
                                    // This channel was in use before. We need to check it.
                                    std::size_t testLen = std::char_traits<TCHAR>::length( oldChannels[j] );
                                    if( std::char_traits<TCHAR>::compare( oldChannels[j], channelName.c_str(),
                                                                          testLen ) == 0 ) {
                                        shouldSelect = TRUE;
                                        alpha = oldChannelsAlpha[j];
                                        flags = oldChannelsOptions[j];
                                    }
                                }
                            }

                            // When selecting for the first time, this is true. Force ID and Position
                            // to be selected for new objects.
                            if( isNewObj && ( channelName == _T("ID") || channelName == _T("Position") ) )
                                shouldSelect = TRUE;
                            pblock()->SetValue( kKrakatoaPFPRTLoaderUpdate_channel_use, 0, shouldSelect, channelCount );
                            pblock()->SetValue( kKrakatoaPFPRTLoaderUpdate_channels, 0, (TCHAR*)channelName.c_str(),
                                                channelCount );
                            pblock()->SetValue( kKrakatoaPFPRTLoaderUpdate_channel_alphas, 0, alpha, channelCount );
                            pblock()->SetValue( kKrakatoaPFPRTLoaderUpdate_channel_options, 0, flags, channelCount );

                            ++channelCount;
                        }
                    }

                    int numMaps = NumPViewParamMaps();
                    for( int i = 0; i < numMaps; ++i ) {
                        if( IParamMap2* pMap = GetPViewParamMap( i ) )
                            SendMessage( pMap->GetHWnd(), WM_USER_REDO_LISTVIEW, (WPARAM)0, (LPARAM)0 );
                    }

                    break;

                } break;
                }
            }
            break;
        }
        }
    } catch( const std::exception& e ) {
        FF_LOG( warning ) << _T("Error in KrakatoaPFPRTLoaderUpdate::NotifyRefChanged()\n\t") << e.what() << std::endl;
        GetCOREInterface()->Log()->LogEntry( SYSLOG_ERROR, DISPLAY_DIALOG,
                                             _T("MaxKrakatoaPFPRTLoaderUpdate::Proceed() Error"),
                                             HANDLE_STD_EXCEPTION_MSG( e ) );
        if( IsNetworkRenderServer() )
            throw MAXException( HANDLE_STD_EXCEPTION_MSG( e ) );
        return REF_STOP;
    }

    return REF_SUCCEED;
}

//+--------------------------------------------------------------------------+
//|							From IPViewItem
//|
//+--------------------------------------------------------------------------+
HBITMAP KrakatoaPFPRTLoaderUpdate::GetActivePViewIcon() {
    if( activeIcon() == NULL )
        _activeIcon() = (HBITMAP)LoadImage( hInstance, MAKEINTRESOURCE( IDB_PRTLOADERUPDATE_ACTIVE ), IMAGE_BITMAP,
                                            kActionImageWidth, kActionImageHeight, LR_SHARED );
    return activeIcon();
}

//+--------------------------------------------------------------------------+
//|							From IPViewItem
//|
//+--------------------------------------------------------------------------+
HBITMAP KrakatoaPFPRTLoaderUpdate::GetInactivePViewIcon() {
    if( inactiveIcon() == NULL )
        _inactiveIcon() = (HBITMAP)LoadImage( hInstance, MAKEINTRESOURCE( IDB_PRTLOADERUPDATE_INACTIVE ), IMAGE_BITMAP,
                                              kActionImageWidth, kActionImageHeight, LR_SHARED );
    return inactiveIcon();
}

// Used to integrate and subtract the change in position due to velocity
class AdjustPositionForVelocityFunctor {
  private:
    frantic::channels::channel_map m_pcm;
    const float m_timestep;
    const particle_flow_channel_interface m_pflowInterface;

  public:
    AdjustPositionForVelocityFunctor( PreciseTimeValue& timestep, particle_flow_channel_interface& pflowInterface )
        : m_timestep( TicksToSec( timestep.PreciseTime() ) )
        , m_pflowInterface( pflowInterface ) {}

    void set_channel_map( channel_map& inoutChannelMap, const channel_map& nativeMap ) { m_pcm = inoutChannelMap; }

    frantic::graphics::vector3f operator()( const char* particle ) const {
        static const frantic::graphics::vector3f origin( 0.0f, 0.0f, 0.0f );

        frantic::channels::channel_const_cvt_accessor<frantic::graphics::vector3f> positionAcc;
        frantic::channels::channel_const_cvt_accessor<frantic::graphics::vector3f> velocityAcc;
        frantic::channels::channel_const_cvt_accessor<boost::int32_t> idAcc;

        if( m_pcm.has_channel( _T( "Position" ) ) ) {
            positionAcc = m_pcm.get_const_cvt_accessor<frantic::graphics::vector3f>( _T( "Position" ) );
        } else {
            return origin;
        }

        if( !positionAcc.is_valid() ) {
            return origin;
        }

        const frantic::graphics::vector3f position = positionAcc.get( particle );

        if( m_pcm.has_channel( _T( "ID" ) ) ) {
            idAcc = m_pcm.get_const_cvt_accessor<boost::int32_t>( _T( "ID" ) );
        }

        // Don't integrate if the particle was born this frame, since PFlow will not iterpolate by velocity
        if( idAcc.is_valid() && m_pflowInterface.is_particle_new( idAcc.get( particle ) ) ) {
            return position;
        }

        if( m_pcm.has_channel( _T( "Velocity" ) ) ) {
            velocityAcc = m_pcm.get_const_cvt_accessor<frantic::graphics::vector3f>( _T( "Velocity" ) );
        } else {
            return position;
        }

        if( velocityAcc.is_valid() ) {
            const frantic::graphics::vector3f velocity = velocityAcc.get( particle );

            return position - ( velocity * m_timestep );
        } else {
            return position;
        }
    }
};

bool KrakatoaPFPRTLoaderUpdate::Proceed( IObject* pCont, PreciseTimeValue timeStart, PreciseTimeValue& timeEnd,
                                         Object* pSystem, INode* /*pNode*/, INode* /*actionNode*/,
                                         IPFIntegrator* /*integrator*/ ) {
    try {

        if( pblock() == NULL ) {
            if( this->GetParamBlock( 0 ) != NULL )
                throw std::runtime_error( "KrakatoaPFPRTLoaderUpdate's pblock was NULL, but Ref0 was not" );
            throw std::runtime_error( "KrakatoaPFPRTLoaderUpdate's pblock was NULL" );
        }

        IParticleObjectExt* poExt = GetParticleObjectExtInterface( GetPFObject( pSystem ) );
        if( poExt == NULL ) {
            throw std::runtime_error(
                "KrakatoaPFPRTLoaderUpdate: Could not set up the interface to ParticleObjectExt" );
        } // no handle for ParticleObjectExt interface

        IPFSystem* pfSys = GetPFSystemInterface( pSystem );
        if( pfSys == NULL ) {
            throw std::runtime_error( "KrakatoaPFPRTLoaderUpdate: Could not set up the interface to PFSystem" );
        } // no handle for PFSystem interface

        // Make sure we have a PRT Loader connected
        INode* prtLoaderNode = pblock()->GetINode( kKrakatoaPFPRTLoaderUpdate_pick_PRT_loader );
        if( !prtLoaderNode )
            return true;

        if( CheckForBadPRTSourceReference( prtLoaderNode, m_pblock, kTargetNode,
                                           frantic::tstring( _T( "Krakatoa PRT Update" ) ) ) ) {
            return true;
        }

        TimeValue evalTime = timeEnd;
        PreciseTimeValue timeStep = timeEnd - timeStart;

        channel_map pcm;
        pcm.define_channel<int>( _T( "ID" ) );
        pcm.define_channel<frantic::graphics::vector3f>( _T( "Position" ) );
        pcm.end_channel_definition( 1, true );
        boost::shared_ptr<frantic::particles::streams::particle_istream> pin =
            frantic::max3d::particles::max_particle_istream_factory( prtLoaderNode, pcm, evalTime,
                                                                     timeStep.TimeValue() );
        if( !pin )
            return true;

        // HACK: Fix for error when evaluating stream where there are no-particles. The returned stream doesn't have
        //        a native_channel_map that makes sense, so it will cause an error. I kick out early now to avoid this.
        if( pin->particle_count() == 0 )
            return true;

        // Build the pflow channel map from the channels indicated in the UI/paramblock string tab.
        // This should cause an exception if any of the files are missing a specified channel,
        // which I think is the right thing to do.
        bool hasID = false;
        std::vector<frantic::tstring> blendChannelNames;
        std::vector<int> blendTypes;
        std::vector<float> blendAlphas;
        float expFraction = float( timeEnd.TimeValue() - timeStart.TimeValue() ) / float( GetTicksPerFrame() );

        channel_map pflowPcm;
        for( int i = 0; i < pblock()->Count( kKrakatoaPFPRTLoaderUpdate_channels ); ++i ) {
            frantic::tstring channelName = pblock()->GetStr( kKrakatoaPFPRTLoaderUpdate_channels, timeStart, i );
            int useChannel = pblock()->GetInt( kKrakatoaPFPRTLoaderUpdate_channel_use, timeStart, i );
            if( useChannel || channelName == _T( "Position" ) ) {
                frantic::tstring channelName = pblock()->GetStr( kKrakatoaPFPRTLoaderUpdate_channels, timeStart, i );
                pflowPcm.define_channel( channelName, pin->get_native_channel_map()[channelName].arity(),
                                         pin->get_native_channel_map()[channelName].data_type() );

                if( useChannel ) {
                    if( channelName == _T( "ID" ) ) {
                        hasID = true;
                        continue;
                    }

                    float alpha = pblock()->GetFloat( kKrakatoaPFPRTLoaderUpdate_channel_alphas, timeStart, i ) / 100.f;
                    int option = pblock()->GetInt( kKrakatoaPFPRTLoaderUpdate_channel_options, timeStart, i );
                    blendChannelNames.push_back( channelName );
                    if( option == kKrakatoaPFPRTLoaderUpdate_channel_blend ) {
                        blendTypes.push_back( BLEND ); // regular blend
                        blendAlphas.push_back( 1.f - pow( 1.f - alpha, expFraction ) );
                    } else {
                        blendTypes.push_back( ADD ); // "additive" blend
                        blendAlphas.push_back( alpha * float( timeEnd - timeStart ) / GetTicksPerFrame() );
                    }
                }
            }
        }

        pflowPcm.end_channel_definition( 1, true );

        // If we have no channels to load into pflow, return.
        if( pflowPcm.channel_count() == 0 )
            return true;

        pin->set_channel_map( pflowPcm );

        // Set up the blending and try to acquire the pflow channels we need (will toss an exception if we can't)
        particle_flow_channel_interface pfci( pCont );
        pfci.initialize_channel_interface( pflowPcm, blendChannelNames, blendTypes, blendAlphas );

        float particleCountMultiplier = pfSys->GetMultiplier( timeStart );
        // int particlesLimit = pfSys->GetBornAllowance() - poExt->NumParticlesGenerated(); //BUG: This is the number
        // that can still be birthed and is totally wrong here.
        int particlesLimit =
            poExt->NumParticlesGenerated(); // The original idea was to load the same particles as the PRTLoaderBirth
                                            // but we can't know the correct number here. This is a decent upper bound.

        // BUG: Can't load partial particles because we can't guarantee we'll get exactly the IDs we need from disk.
        // Maybe better would be streaming them in and discarding ones that aren't in the current flow.

        //// if the stream has no IDs, then do a typical fractional load.  this has no guarantees for
        //// consistency and will only look decent if the particles are static and don't change order in the file
        if( !hasID )
            pin = apply_fractional_particle_istream( pin, particleCountMultiplier, particlesLimit, true );
        else
            pin = apply_fractional_by_id_particle_istream( pin, particleCountMultiplier, _T("ID"), particlesLimit );

        if( pin->particle_count() == 0 ) {
            return true;
        }

        // If Particle Flow is given a velocity, particles will be updated based on that velocity to be a frame ahead of
        // where they should be based on position. In order to both interpolate position from velocity on subframes, and
        // position particles correctly, we give the user the option to integrate the change 	in position which has
        //resulted from the velocity and subtract this from the final position.

        const bool adjustPositionForVelocity =
            static_cast<bool>( pblock()->GetInt( kKrakatoaPFPRTLoaderUpdate_adjust_position ) ); // User option

        if( adjustPositionForVelocity ) {
            pin = boost::shared_ptr<frantic::particles::streams::particle_istream>(
                new frantic::particles::streams::functor_particle_istream<AdjustPositionForVelocityFunctor,
                                                                          frantic::graphics::vector3f>(
                    pin, frantic::tstring( _T( "Position" ) ), AdjustPositionForVelocityFunctor( timeStep, pfci ) ) );
        }

        // Load the particles
        size_t particleSize = pflowPcm.structure_size(); // Size of the particle structure
        vector<char> buffer;                             // Temp storage
        unsigned counter;                                // Counts the number of particles in a reading batch
        int fileCount = 0;                               // Counts total number of particles read from file
        int pflowCount = pfci.get_particle_flow_count(); // Number of current pflow particles

        vector<char> particles;         // Local storage of particles from file
        vector<idPair> fileID;          // Indices and IDs of file particles
        vector<idPair> pflowID;         // Indices and IDs of pflow particles
        channel_general_accessor idAcc; // accessor for particle's ID info in the file
        if( hasID )
            idAcc = pflowPcm.get_general_accessor( _T("ID") );

        // We don't know how many particles we are reading...do batches?
        if( pin->particle_count() < 0 ) {
            buffer.resize( NUM_BUFFERED_PARTICLES * particleSize );
            do {
                char* pParticle = &buffer[0];
                for( counter = 0; counter < NUM_BUFFERED_PARTICLES; ++counter ) {
                    if( !pin->get_particle( pParticle ) )
                        break;
                    pParticle += particleSize;
                }

                if( counter == 0 )
                    break;

                // build id info
                fileID.resize( fileID.size() + counter );

                for( unsigned int i = 0; i < counter; i++ ) {
                    fileID[fileCount + i].index = fileCount + i;
                    if( hasID )
                        fileID[fileCount + i].id =
                            *( (int*)idAcc.get_channel_data_pointer( &buffer[i * particleSize] ) );
                    else
                        fileID[fileCount + i].id = fileCount + i;
                }

                // temp store of particle info
                particles.resize( particles.size() + counter * particleSize );
                memcpy( &particles[fileCount * particleSize], &buffer[0], counter * particleSize );
                fileCount += counter;

            } while( counter == NUM_BUFFERED_PARTICLES ); // Keep writing particles until we find a non-full batch
        }
        // Positive particle count, we know how many.
        else {

            fileCount = (int)pin->particle_count();
            particles.resize( fileCount * particleSize );
            fileID.resize( fileCount );
            for( int i = 0; i < fileCount; i++ ) {

                pin->get_particle( &particles[i * particleSize] );

                // build id info
                fileID[i].index = i;
                if( hasID )
                    fileID[i].id = *( (int*)idAcc.get_channel_data_pointer( &particles[i * particleSize] ) );
                else
                    fileID[i].id = i;
            }
        }

        // Grab all the pflow particle indices/ids
        pflowID.resize( pflowCount );
        for( int i = 0; i < pflowCount; i++ ) {
            pflowID[i].index = i;
            pflowID[i].id = pfci.get_particle_file_or_real_id( i );
            // pflowID[i].id = pfci.get_particle_file_id(i);
        }

        // sort the file index/ID pairs by ID
        if( hasID ) // only needs to be sorted if we had to load IDs from the file
            sort( fileID.begin(), fileID.end(), &KrakatoaPFPRTLoaderUpdate::sortFunction );
        sort( pflowID.begin(), pflowID.end(), &KrakatoaPFPRTLoaderUpdate::sortFunction );

        size_t fileCounter = 0, pflowCounter = 0;
        bool done = false;
        while( !done ) {
            if( fileCounter >= fileID.size() || pflowCounter >= pflowID.size() ) {
                // we hit the end of one of the ID arrays
                done = true;
            } else if( pflowID[pflowCounter].id == fileID[fileCounter].id ) {
                pfci.copy_particle( particles[fileID[fileCounter].index * particleSize], pflowID[pflowCounter].index,
                                    timeEnd, pfci.is_particle_new( pflowID[pflowCounter].index ) );
                pflowCounter++;
                fileCounter++;
            } else if( pflowID[pflowCounter].id < fileID[fileCounter].id ) {
                // the pflow particle doesnt have a match in the file, keep going
                pfci.set_particle_file_id( pflowID[pflowCounter].index, -1 );
                pflowCounter++;
            } else if( fileID[fileCounter].id < pflowID[pflowCounter].id ) {
                // the file ID doesn't exist in the pflow ID list, keep going
                fileCounter++;
            }
        }
        // since you might have just hit the end of one of the arrays, loop through the remaining
        // particles in pflow and flag them for deletion
        while( pflowCounter < pflowID.size() ) {
            pfci.set_particle_file_id( pflowID[pflowCounter].index, -1 );
            pflowCounter++;
        }

    } catch( const std::exception& e ) {
        FF_LOG( error ) << _T("Error in KrakatoaPFPRTLoaderUpdate::Proceed()\n\t") << e.what() << std::endl;
        GetCOREInterface()->Log()->LogEntry( SYSLOG_ERROR, DISPLAY_DIALOG,
                                             _T("KrakatoaPFPRTLoaderUpdate::Proceed() Error"),
                                             HANDLE_STD_EXCEPTION_MSG( e ) );
        if( IsNetworkRenderServer() )
            throw MAXException( HANDLE_STD_EXCEPTION_MSG( e ) );
        return false;
    }

    return true;
}

//+>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>+
//|							Function Publishing System
//|
//+>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>+
static FPInterfaceDesc pflow_action_FPInterfaceDesc(
    PFACTION_INTERFACE, _T("action"), 0, GetKrakatoaPFPRTLoaderUpdateDesc(), FP_MIXIN,

    IPFAction::kInit, _T("init"), 0, TYPE_bool, 0, 5, _T("container"), 0, TYPE_IOBJECT, _T("particleSystem"), 0,
    TYPE_OBJECT, _T("particleSystemNode"), 0, TYPE_INODE, _T("actions"), 0, TYPE_OBJECT_TAB_BR, _T("actionNodes"), 0,
    TYPE_INODE_TAB_BR, IPFAction::kRelease, _T("release"), 0, TYPE_bool, 0, 1, _T("container"), 0, TYPE_IOBJECT,
    // reserved for future use
    // IPFAction::kChannelsUsed, _T("channelsUsed"), 0, TYPE_VOID, 0, 2,
    //	_T("interval"), 0, TYPE_INTERVAL_BR,
    //	_T("channels"), 0, TYPE_FPVALUE,
    IPFAction::kActivityInterval, _T("activityInterval"), 0, TYPE_INTERVAL_BV, 0, 0, IPFAction::kIsFertile,
    _T("isFertile"), 0, TYPE_bool, 0, 0, IPFAction::kIsNonExecutable, _T("isNonExecutable"), 0, TYPE_bool, 0, 0,
    IPFAction::kSupportRand, _T("supportRand"), 0, TYPE_bool, 0, 0, IPFAction::kGetRand, _T("getRand"), 0, TYPE_INT, 0,
    0, IPFAction::kSetRand, _T("setRand"), 0, TYPE_VOID, 0, 1, _T("randomSeed"), 0, TYPE_INT, IPFAction::kNewRand,
    _T("newRand"), 0, TYPE_INT, 0, 0, IPFAction::kIsMaterialHolder, _T("isMaterialHolder"), 0, TYPE_bool, 0, 0,
    IPFAction::kSupportScriptWiring, _T("supportScriptWiring"), 0, TYPE_bool, 0, 0,

    p_end );

static FPInterfaceDesc pflow_operator_FPInterfaceDesc(
    PFOPERATOR_INTERFACE, _T("operator"), 0, GetKrakatoaPFPRTLoaderUpdateDesc(), FP_MIXIN,

    IPFOperator::kProceed, _T("proceed"), 0, TYPE_bool, 0, 7, _T("container"), 0, TYPE_IOBJECT, _T("timeStart"), 0,
    TYPE_TIMEVALUE, _T("timeEnd"), 0, TYPE_TIMEVALUE_BR, _T("particleSystem"), 0, TYPE_OBJECT, _T("particleSystemNode"),
    0, TYPE_INODE, _T("actionNode"), 0, TYPE_INODE, _T("integrator"), 0, TYPE_INTERFACE,

    p_end );

static FPInterfaceDesc pflow_PViewItem_FPInterfaceDesc(
    PVIEWITEM_INTERFACE, _T("PViewItem"), 0, GetKrakatoaPFPRTLoaderUpdateDesc(), FP_MIXIN,

    IPViewItem::kNumPViewParamBlocks, _T("numPViewParamBlocks"), 0, TYPE_INT, 0, 0, IPViewItem::kGetPViewParamBlock,
    _T("getPViewParamBlock"), 0, TYPE_REFTARG, 0, 1, _T("index"), 0, TYPE_INDEX, IPViewItem::kHasComments,
    _T("hasComments"), 0, TYPE_bool, 0, 1, _T("actionNode"), 0, TYPE_INODE, IPViewItem::kGetComments, _T("getComments"),
    0, TYPE_STRING, 0, 1, _T("actionNode"), 0, TYPE_INODE, IPViewItem::kSetComments, _T("setComments"), 0, TYPE_VOID, 0,
    2, _T("actionNode"), 0, TYPE_INODE, _T("comments"), 0, TYPE_STRING,

    p_end );

FPInterfaceDesc* KrakatoaPFPRTLoaderUpdate::GetDescByID( Interface_ID id ) {
    if( id == PFACTION_INTERFACE )
        return &pflow_action_FPInterfaceDesc;
    if( id == PFOPERATOR_INTERFACE )
        return &pflow_operator_FPInterfaceDesc;
    if( id == PVIEWITEM_INTERFACE )
        return &pflow_PViewItem_FPInterfaceDesc;
    return NULL;
}
