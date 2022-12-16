// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0
#include "stdafx.h"

#include "resource.h"

#include <Phoenix/MaxKrakatoaPhoenixDialogProcs.hpp>

#include <Phoenix/MaxKrakatoaPhoenixObject.hpp>

#include <frantic/max3d/max_utility.hpp>

PhoenixMainPanelDialogProc PhoenixMainPanelDialogProc::s_theDialogProc;
PhoenixViewportPanelDialogProc PhoenixViewportPanelDialogProc::s_theDialogProc;

INT_PTR PhoenixMainPanelDialogProc::DlgProc( TimeValue t, IParamMap2* map, HWND hWnd, UINT msg, WPARAM wParam,
                                             LPARAM lParam ) {
    IParamBlock2* pblock = map->GetParamBlock();
    switch( msg ) {
    case WM_COMMAND:
        if( HIWORD( wParam ) == BN_CLICKED ) {
            switch( LOWORD( wParam ) ) {
            case IDC_PHOENIX_TARGETMENU_BUTTON:
                frantic::max3d::mxs::expression( _T( "FranticParticleRenderMXS.OpenPRTPhoenixOptionsRCMenu()" ) )
                    .evaluate<void>();
                return TRUE;
            }
        }
        break;
    case WM_CONTEXTMENU: {
        HWND rcvHandle = (HWND)wParam;
        if( rcvHandle == GetDlgItem( hWnd, IDC_PHOENIX_TARGETNODE_PICK ) ) {
            frantic::max3d::mxs::expression( _T("FranticParticleRenderMXS.OpenPRTPhoenixOptionsRCMenu()") )
                .evaluate<void>();
            return TRUE;
        }
    } break;
    }

    return FALSE;
}

INT_PTR PhoenixViewportPanelDialogProc::DlgProc( TimeValue t, IParamMap2* map, HWND hWnd, UINT msg, WPARAM wParam,
                                                 LPARAM lParam ) {
    switch( msg ) {
    case WM_INITDIALOG:
        break;
    case WM_COMMAND:
        if( HIWORD( wParam ) == BN_CLICKED ) {
            if( LOWORD( wParam ) == IDC_PHOENIX_UPDATE_BUTTON ) {
                IParamBlock2* pblock = map->GetParamBlock();
                if( pblock ) {
                    MaxKrakatoaPhoenixObject* pOwner = static_cast<MaxKrakatoaPhoenixObject*>( pblock->GetOwner() );
                    pOwner->InvalidateObjectAndViewport();
                    pOwner->NotifyDependents( FOREVER, PART_GEOM, REFMSG_CHANGE ); // Force the scene to be updated.
                }
                return TRUE;
            }
        }
        break;
    }

    return FALSE;
}
