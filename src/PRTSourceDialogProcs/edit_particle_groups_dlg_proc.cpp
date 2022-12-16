// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0
#include "stdafx.h"

#include <boost/foreach.hpp>
#include <boost/utility.hpp>

#include "resource.h"

#include "KrakatoaGUIResources.hpp"
#include <PRTSourceDialogProcs\listbox_with_inplace_tooltip.hpp>
#include <PRTSourceDialogProcs\particle_group_filter_entry.hpp>

#include <frantic/logging/logging_level.hpp>

extern TCHAR* GetString( int id );

struct edit_particle_groups_dlg_state : boost::noncopyable {
    std::vector<particle_group_filter_entry::ptr_type>& groupList;
    std::vector<bool> includeList;
    std::vector<int> excludeToGroupListIndex;
    std::vector<int> includeToGroupListIndex;
    frantic::tstring particleSystemType;
    frantic::tstring groupTypePlural;
    listbox_with_inplace_tooltip excludeListbox;
    listbox_with_inplace_tooltip includeListbox;

    edit_particle_groups_dlg_state( const frantic::tstring& particleSystemType, const frantic::tstring& groupTypePlural,
                                    std::vector<particle_group_filter_entry::ptr_type>& groupList )
        : groupList( groupList )
        , particleSystemType( particleSystemType )
        , groupTypePlural( groupTypePlural ) {
        includeList.clear();
        includeList.resize( groupList.size(), false );

        for( std::size_t i = 0; i < groupList.size(); ++i ) {
            particle_group_filter_entry::ptr_type group = groupList[i];
            if( group && group->is_included() ) {
                includeList[i] = true;
            } else {
                includeList[i] = false;
            }
        }
    }
};

class edit_particle_groups_dlg_proc {
    static void select_all( HWND hwnd ) {
        if( hwnd ) {
            SendMessage( hwnd, LB_SETSEL, TRUE, -1 );
        }
    }

    static void select_invert( HWND hwnd ) {
        if( hwnd ) {
            LRESULT itemCount = SendMessage( hwnd, LB_GETCOUNT, 0, 0 );
            if( itemCount != LB_ERR && itemCount > 0 ) {
                for( LRESULT i = 0; i < itemCount; ++i ) {
                    LRESULT currentState = SendMessage( hwnd, LB_GETSEL, i, 0 );
                    if( currentState != LB_ERR ) {
                        LRESULT newState = currentState == 0 ? TRUE : FALSE;
                        SendMessage( hwnd, LB_SETSEL, newState, i );
                    }
                }
            }
        }
    }

    static void update_exclude_and_include_lists( HWND hwndDlg, edit_particle_groups_dlg_state* state,
                                                  std::vector<int>* selection = 0, bool focusInclude = false ) {
        if( hwndDlg && state ) {
            HWND hwndIncludeList = GetDlgItem( hwndDlg, IDC_INCLUDE_LIST );
            HWND hwndExcludeList = GetDlgItem( hwndDlg, IDC_EXCLUDE_LIST );

            if( hwndIncludeList && hwndExcludeList ) {
                SendMessage( hwndIncludeList, LB_RESETCONTENT, 0, 0 );
                SendMessage( hwndExcludeList, LB_RESETCONTENT, 0, 0 );

                std::size_t excludeCount = 0;
                std::size_t includeCount = 0;
                LPARAM preallocExclude = 0;
                LPARAM preallocInclude = 0;

                if( state->includeList.size() != state->groupList.size() ) {
                    return;
                }

                // indicate whether this entry in groupList is selected
                std::vector<char> selectionTag( state->groupList.size(), 0 );
                if( selection ) {
                    for( std::size_t i = 0; i < selection->size(); ++i ) {
                        const int eventIndex = ( *selection )[i];
                        if( eventIndex >= 0 && static_cast<std::size_t>( eventIndex ) < state->groupList.size() ) {
                            selectionTag[eventIndex] = 1;
                        }
                    }
                }

                // get include/exclude list sizes for preallocation
                for( std::size_t i = 0; i < state->groupList.size(); ++i ) {
                    particle_group_filter_entry::ptr_type group = state->groupList[i];
                    if( group ) {
                        const LPARAM len = 1 + _tcsclen( group->get_name() );
                        if( state->includeList[i] ) {
                            preallocInclude += len;
                            ++includeCount;
                        } else {
                            preallocExclude += len;
                            ++excludeCount;
                        }
                    }
                }

                LRESULT lRet = SendMessage( hwndExcludeList, LB_INITSTORAGE, excludeCount, preallocExclude );
                lRet = SendMessage( hwndIncludeList, LB_INITSTORAGE, includeCount, preallocInclude );

                std::vector<int> newSelection;
                newSelection.reserve( selection ? selection->size() : 0 );

                state->includeToGroupListIndex.clear();
                state->excludeToGroupListIndex.clear();

                // add items to list boxes, and
                // build state->includeToGroupListIndex and excludeToGroupListIndex lists
                for( std::size_t i = 0, ie = state->groupList.size(); i < ie; ++i ) {
                    particle_group_filter_entry::ptr_type group = state->groupList[i];
                    if( group ) {
                        const bool isIncluded = state->includeList[i];
                        HWND hwndDestList = isIncluded ? hwndIncludeList : hwndExcludeList;
                        lRet = SendMessage( hwndDestList, LB_ADDSTRING, 0, (LPARAM)( group->get_name() ) );
                        if( lRet == LB_ERR ) {
                            // An error occurred
                            MessageBox(
                                GetCOREInterface()->GetMAXHWnd(),
                                _T("An error occurred while populating the node list.  Please contact support."),
                                _T("Krakatoa : Error"), MB_ICONEXCLAMATION | MB_OK );
                        } else if( lRet == LB_ERRSPACE ) {
                            // Insufficient space to store new string
                            MessageBox( GetCOREInterface()->GetMAXHWnd(),
                                        _T("Insufficient space to store the node list.  Please contact support."),
                                        _T("Krakatoa : Error"), MB_ICONEXCLAMATION | MB_OK );
                        } else if( lRet >= 0 ) {
                            if( isIncluded ) {
                                if( i >= state->includeToGroupListIndex.size() ) {
                                    state->includeToGroupListIndex.resize( lRet + 1, LB_ERR );
                                }
                                state->includeToGroupListIndex[lRet] = static_cast<int>( i );
                            } else {
                                if( i >= state->excludeToGroupListIndex.size() ) {
                                    state->excludeToGroupListIndex.resize( lRet + 1, LB_ERR );
                                }
                                state->excludeToGroupListIndex[lRet] = static_cast<int>( i );
                            }
                            if( isIncluded == focusInclude && selectionTag[i] ) {
                                newSelection.push_back( static_cast<int>( lRet ) );
                            }
                        } else {
                            // unknown error occurred
                            MessageBox( GetCOREInterface()->GetMAXHWnd(),
                                        _T("An unknown error occurred while populating the node list.  Please contact ")
                                        _T("support."),
                                        _T("Krakatoa : Error"), MB_ICONEXCLAMATION | MB_OK );
                        }
                    }
                }
                if( focusInclude ) {
                    // remove selection from exclude
                    // set selection in include
                    BOOST_FOREACH( int i, newSelection ) {
                        ListBox_SetSel( hwndIncludeList, TRUE, i );
                    }
                } else {
                    // remove selection from include
                    // set selection in exclude
                    BOOST_FOREACH( int i, newSelection ) {
                        ListBox_SetSel( hwndExcludeList, TRUE, i );
                    }
                }
            }
        }
    }

    static void include_to_exclude( HWND hwndDlg, edit_particle_groups_dlg_state* state ) {
        if( state ) {
            std::vector<int> selectedIncludeIndices;
            frantic::win32::ffListBox_GetSelItems( GetDlgItem( hwndDlg, IDC_INCLUDE_LIST ), selectedIncludeIndices );
            std::vector<int> selectedIndices;
            BOOST_FOREACH( int includeIndex, selectedIncludeIndices ) {
                if( includeIndex >= 0 &&
                    static_cast<std::size_t>( includeIndex ) < state->includeToGroupListIndex.size() ) {
                    selectedIndices.push_back( state->includeToGroupListIndex[includeIndex] );
                }
            }
            BOOST_FOREACH( int index, selectedIndices ) {
                if( index >= 0 && static_cast<std::size_t>( index ) < state->includeList.size() ) {
                    state->includeList[index] = false;
                }
            }
            update_exclude_and_include_lists( hwndDlg, state, &selectedIndices, false );
        }
    }

    static void exclude_to_include( HWND hwndDlg, edit_particle_groups_dlg_state* state ) {
        if( state ) {
            std::vector<int> selectedExcludeIndices;
            frantic::win32::ffListBox_GetSelItems( GetDlgItem( hwndDlg, IDC_EXCLUDE_LIST ), selectedExcludeIndices );
            std::vector<int> selectedIndices;
            BOOST_FOREACH( int excludeIndex, selectedExcludeIndices ) {
                if( excludeIndex >= 0 &&
                    static_cast<std::size_t>( excludeIndex ) < state->excludeToGroupListIndex.size() ) {
                    selectedIndices.push_back( state->excludeToGroupListIndex[excludeIndex] );
                }
            }
            BOOST_FOREACH( int index, selectedIndices ) {
                if( index >= 0 && static_cast<std::size_t>( index ) < state->includeList.size() ) {
                    state->includeList[index] = true;
                }
            }
            update_exclude_and_include_lists( hwndDlg, state, &selectedIndices, true );
        }
    }

  public:
    static INT_PTR CALLBACK DlgProc( __in HWND hwndDlg, __in UINT uMsg, __in WPARAM wParam, __in LPARAM lParam ) {
        try {
            edit_particle_groups_dlg_state* state =
                reinterpret_cast<edit_particle_groups_dlg_state*>( GetWindowLongPtr( hwndDlg, DWLP_USER ) );

            switch( uMsg ) {
            case WM_INITDIALOG: {
                // TODO use text instead for now maybe?
                GetKrakatoaGuiResources()->apply_custbutton_right_arrow_icon( GetDlgItem( hwndDlg, IDC_INCLUDE ) );
                GetKrakatoaGuiResources()->apply_custbutton_left_arrow_icon( GetDlgItem( hwndDlg, IDC_EXCLUDE ) );

                state = reinterpret_cast<edit_particle_groups_dlg_state*>( lParam );

                SetWindowLongPtr( hwndDlg, DWLP_USER, (LONG_PTR)state );

                if( state ) {
                    SetWindowText(
                        hwndDlg,
                        ( _T("Select ") + state->particleSystemType + _T(" ") + state->groupTypePlural ).c_str() );
                    SetWindowText( GetDlgItem( hwndDlg, IDC_EXCLUDE_STATIC ),
                                   ( _T("Ignore ") + state->groupTypePlural + _T(":") ).c_str() );
                    SetWindowText( GetDlgItem( hwndDlg, IDC_INCLUDE_STATIC ),
                                   ( _T("Get Particles from ") + state->groupTypePlural + _T(":") ).c_str() );
                    update_exclude_and_include_lists( hwndDlg, state );
                } else {
                    MessageBox( GetCOREInterface()->GetMAXHWnd(),
                                _T("Internal Error: node list state is NULL.  Please contact support."),
                                _T("Frost : Error"), MB_ICONEXCLAMATION | MB_OK );
                }

                typedef std::pair<int, int> control_tooltip_t;
                control_tooltip_t buttonTooltips[] = {
                    std::make_pair( IDC_INCLUDE, IDS_INCLUDE_TOOLTIP ),
                    std::make_pair( IDC_EXCLUDE, IDS_EXCLUDE_TOOLTIP ),
                    std::make_pair( IDC_EXCLUDE_SELECT_ALL, IDS_EXCLUDE_SELECT_ALL_TOOLTIP ),
                    std::make_pair( IDC_EXCLUDE_SELECT_INVERT, IDS_EXCLUDE_SELECT_INVERT_TOOLTIP ),
                    std::make_pair( IDC_INCLUDE_SELECT_ALL, IDS_INCLUDE_SELECT_ALL_TOOLTIP ),
                    std::make_pair( IDC_INCLUDE_SELECT_INVERT, IDS_INCLUDE_SELECT_INVERT_TOOLTIP ) };
                BOOST_FOREACH( const control_tooltip_t& buttonTooltip, buttonTooltips ) {
                    CustButton_SetTooltip( GetDlgItem( hwndDlg, buttonTooltip.first ),
                                           GetString( buttonTooltip.second ) );
                }

                state->excludeListbox.attach( GetDlgItem( hwndDlg, IDC_EXCLUDE_LIST ) );
                state->includeListbox.attach( GetDlgItem( hwndDlg, IDC_INCLUDE_LIST ) );

                return TRUE;
            }
            case WM_DESTROY:
                if( state ) {
                    state->includeListbox.detach( GetDlgItem( hwndDlg, IDC_INCLUDE_LIST ) );
                    state->excludeListbox.detach( GetDlgItem( hwndDlg, IDC_EXCLUDE_LIST ) );
                }
                SetWindowLongPtr( hwndDlg, DWLP_USER, 0 );
                return 0;
            case WM_COMMAND: {
                int id = LOWORD( wParam );
                int notifyCode = HIWORD( wParam );

                switch( id ) {
                case IDC_EXCLUDE_LIST:
                    if( LBN_DBLCLK == notifyCode ) {
                        exclude_to_include( hwndDlg, state );
                    }
                    break;
                case IDC_INCLUDE_LIST:
                    if( LBN_DBLCLK == notifyCode ) {
                        include_to_exclude( hwndDlg, state );
                    }
                    break;
                case IDC_EXCLUDE_SELECT_ALL:
                    select_all( GetDlgItem( hwndDlg, IDC_EXCLUDE_LIST ) );
                    break;
                case IDC_EXCLUDE_SELECT_INVERT:
                    select_invert( GetDlgItem( hwndDlg, IDC_EXCLUDE_LIST ) );
                    break;
                case IDC_INCLUDE:
                    exclude_to_include( hwndDlg, state );
                    break;
                case IDC_EXCLUDE:
                    include_to_exclude( hwndDlg, state );
                    break;
                case IDC_INCLUDE_SELECT_ALL:
                    select_all( GetDlgItem( hwndDlg, IDC_INCLUDE_LIST ) );
                    break;
                case IDC_INCLUDE_SELECT_INVERT:
                    select_invert( GetDlgItem( hwndDlg, IDC_INCLUDE_LIST ) );
                    break;
                case IDOK:
                    if( state ) {
                        if( state->includeList.size() == state->groupList.size() ) {
                            for( std::size_t i = 0; i < state->groupList.size(); ++i ) {
                                state->groupList[i]->set_include( state->includeList[i] );
                            }
                        }
                    }
                    EndDialog( hwndDlg, IDOK );
                    break;
                case IDCANCEL:
                    EndDialog( hwndDlg, IDCANCEL );
                    break;
                }
            } break;
            default:
                return FALSE;
            }

            return FALSE;
        } catch( const std::exception& e ) {
            frantic::tstring errmsg =
                _T("edit_particle_groups_dlg_proc::DlgProc: ") + frantic::strings::to_tstring( e.what() ) + _T("\n");
            FF_LOG( error ) << errmsg << std::endl;
            LogSys* log = GetCOREInterface()->Log();
            log->LogEntry( SYSLOG_ERROR, NO_DIALOG, _T("Frost Error"), _T("%s"), errmsg.c_str() );
        }
        return FALSE;
    }
};

void show_edit_particle_groups_dialog( HINSTANCE hInstance, HWND hwnd, const frantic::tstring& particleSystemType,
                                       const frantic::tstring& groupTypePlural,
                                       std::vector<particle_group_filter_entry::ptr_type>& groups ) {
    edit_particle_groups_dlg_state state( particleSystemType, groupTypePlural, groups );

    DialogBoxParam( hInstance, MAKEINTRESOURCE( IDD_EDIT_PARTICLE_GROUPS ), hwnd,
                    &edit_particle_groups_dlg_proc::DlgProc, (LPARAM)( &state ) );
}
