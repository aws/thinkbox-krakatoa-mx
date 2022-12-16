// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0
#include "stdafx.h"

#include "resource.h"

#include "MaxKrakatoa.h"
#include "MaxKrakatoaParamDlg.h"

#include <frantic/max3d/maxscript/maxscript.hpp>

using namespace std;
using namespace frantic;
using namespace frantic::max3d;

// The GUI for a renderer involves the rollups for both the main renderer GUI and the rollup
// which appears in the progress dialog.  The param dialog class deals with both of them.

INT_PTR CALLBACK ParticleRenderRendParamsDlgProc( HWND hWnd, UINT msg, WPARAM wParam, LPARAM lParam );

MaxKrakatoaParamDlg::MaxKrakatoaParamDlg( MaxKrakatoa* r, IRendParams* i, bool isProgressDialog ) {
    m_hFont = CreateFont( 14, 0, 0, 0, FW_BOLD, 0, 0, 0, 0, 0, 0, 0, VARIABLE_PITCH | FF_SWISS, _T("") );
    m_renderer = r;
    m_ir = i;
    m_isProgressDialog = isProgressDialog;

    // Create the rollup pages.
    // If we are doing the progress dialog..
    if( m_isProgressDialog ) {
        m_hPanel = m_ir->AddRollupPage( hInstance, MAKEINTRESOURCE( IDD_ProgressDialog ),
                                        ParticleRenderRendParamsDlgProc, _T("Krakatoa"), (LPARAM)this );
    } else {
        // ...or the user config dialog
        m_hPanel =
            m_ir->AddTabRollupPage( MaxKrakatoaTab_CLASS_ID, hInstance, MAKEINTRESOURCE( IDD_FranticParticleRender ),
                                    ParticleRenderRendParamsDlgProc, _T("Krakatoa"), (LPARAM)this );
    }
}

MaxKrakatoaParamDlg::~MaxKrakatoaParamDlg() {
    // Delete the font
    DeleteObject( m_hFont );
    // And the rollup page
    m_ir->DeleteRollupPage( m_hPanel );
}

// Initialize the progress dialog
void MaxKrakatoaParamDlg::InitProgDialog( HWND /*hWnd*/ ) {}

// Initialize the render dialog
void MaxKrakatoaParamDlg::InitParamDialog( HWND /*hWnd*/ ) {
    try {
        frantic::max3d::mxs::expression( _T("FranticParticleRenderMXS.GlobalRefreshGUI()") ).evaluate<Value*>();
    } catch( const std::exception& e ) {
#if MAX_VERSION_MAJOR >= 15
        frantic::max3d::MsgBox( MSTR::FromACP( e.what() ).data(),
                                _T("Error in FranticParticleRenderMXS.GlobalRefreshGUI()") );
#else
        frantic::max3d::MsgBox( e.what(), "Error in FranticParticleRenderMXS.GlobalRefreshGUI()" );
#endif
    }
}

//***************************************************************************
// Accept parameters.
// This is called if the user clicks "Ok" or "Close"
//***************************************************************************

void MaxKrakatoaParamDlg::AcceptParams() {
    try {
        frantic::max3d::mxs::expression( _T("FranticParticleRenderMXS.CloseGUI()") ).evaluate<Value*>();
    } catch( std::exception& e ) {
#if MAX_VERSION_MAJOR >= 15
        frantic::max3d::MsgBox( MSTR::FromACP( e.what() ).data(), _T("Error in FranticParticleRenderMXS.CloseGUI()") );
#else
        frantic::max3d::MsgBox( e.what(), "Error in FranticParticleRenderMXS.CloseGUI()" );
#endif
    }
}

// Called if the user cancels the render param dialog.
// Reset any options you have changed here.
// Since we don't update the parameters until AcceptParams() is called,
// we don't need to do anything here.
void MaxKrakatoaParamDlg::RejectParams() {
    try {
        frantic::max3d::mxs::expression( _T("FranticParticleRenderMXS.CancelGUI()") ).evaluate<Value*>();
    } catch( std::exception& e ) {
#if MAX_VERSION_MAJOR >= 15
        frantic::max3d::MsgBox( MSTR::FromACP( e.what() ).data(), _T("Error Canceling the Krakatoa UI.") );
#else
        frantic::max3d::MsgBox( e.what(), "Error Canceling the Krakatoa UI." );
#endif
    }
}

INT_PTR CALLBACK ParticleRenderRendParamsDlgProc( HWND hWnd, UINT msg, WPARAM wParam, LPARAM lParam ) {
    MaxKrakatoaParamDlg* dlg = (MaxKrakatoaParamDlg*)GetWindowLongPtr( hWnd, GWLP_USERDATA );
    switch( msg ) {
    case WM_INITDIALOG:
        dlg = (MaxKrakatoaParamDlg*)lParam;
        SetWindowLongPtr( hWnd, GWLP_USERDATA, lParam );
        if( dlg ) {
            if( dlg->m_isProgressDialog )
                dlg->InitProgDialog( hWnd );
            else
                dlg->InitParamDialog( hWnd );
        }
        break;
    case WM_DESTROY:
        //			if (!dlg->m_isProgressDialog) {
        //				ReleaseISpinner(dlg->depthSpinner);
        //			}
        break;
    case WM_COMMAND:
        switch( LOWORD( wParam ) ) {
        case IDC_FRANTICPARTICLERENDER_OPENGUI:
            try {
                Renderer* r = GetCOREInterface()->GetCurrentRenderer();
                if( r->ClassID() == MaxKrakatoa_CLASS_ID ) {
                    frantic::max3d::mxs::expression( _T("FranticParticleRenderMXS.OpenGUI()") ).evaluate<Value*>();
                } else {
                    frantic::max3d::MsgBox(
                        _T("Could not start the Krakatoa GUI because the current renderer is not Krakatoa."),
                        _T("Krakatoa Error") );
                }
            } catch( const std::exception& e ) {
#if MAX_VERSION_MAJOR >= 15
                frantic::max3d::MsgBox( MSTR::FromACP( e.what() ).data(), _T("Error Starting The Krakatoa GUI") );
#else
                frantic::max3d::MsgBox( e.what(), "Error Starting The Krakatoa GUI" );
#endif
            }
            break;
        }
        break;

    case WM_LBUTTONDOWN:
    case WM_MOUSEMOVE:
    case WM_LBUTTONUP:
        dlg->m_ir->RollupMouseMessage( hWnd, msg, wParam, lParam );
        break;
    default:
        return FALSE;
    }
    return TRUE;
}
