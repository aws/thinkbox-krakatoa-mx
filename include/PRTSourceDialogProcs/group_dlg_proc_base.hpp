// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0
// File pulled from FrostMX

#pragma once

#include "KrakatoaGUIResources.hpp"
#include "edit_particle_groups_dlg_proc.hpp"
#include "listbox_with_inplace_tooltip.hpp"
#include "particle_group_filter_entry.hpp"

#include <boost/foreach.hpp>

template <class group_dlg_proc_traits>
class group_dlg_proc_base : public ParamMap2UserDlgProc {
    MaxKrakatoaPRTSourceObject* m_obj;
    HWND m_hwnd;
    HWND m_hwndTooltip;
    listbox_with_inplace_tooltip m_inplaceTooltip;

    static bool has_selected_group( const std::vector<particle_group_filter_entry::ptr_type>& groups ) {
        for( std::size_t i = 0; i < groups.size(); ++i ) {
            if( groups[i]->is_included() ) {
                return true;
            }
        }
        return false;
    }

    static bool has_change( const std::vector<bool>& initialIncludeList,
                            const std::vector<particle_group_filter_entry::ptr_type>& groups ) {
        if( initialIncludeList.size() != groups.size() ) {
            return true;
        }
        for( std::size_t i = 0; i < groups.size(); ++i ) {
            if( initialIncludeList[i] != groups[i]->is_included() ) {
                return true;
            }
        }
        return false;
    }

    void invalidate_event_list( HWND hwnd ) {
        if( m_obj && m_obj->editObj == m_obj ) {
            HWND hwndCtrl = GetDlgItem( hwnd, IDC_LIST );
            if( hwndCtrl ) {
                std::vector<frantic::tstring> eventNames;
                group_dlg_proc_traits::get_group_names( m_obj, eventNames );
                frantic::win32::ffListBox_SetStrings( hwndCtrl, eventNames );
            }
        }
    }

    void update_control_enable( HWND hwnd ) {
        if( !m_obj ) {
            return;
        }
        IParamBlock2* pb = m_obj->GetParamBlockByID( 0 );
        if( !pb ) {
            return;
        }
        IParamMap2* pm = pb->GetMap( group_dlg_proc_traits::PARAM_MAP );
        if( !pm ) {
            return;
        }
        if( !hwnd ) {
            return;
        }

        bool inCreateMode = GetCOREInterface()->GetCommandPanelTaskMode() == TASK_MODE_CREATE;

        bool hasSelectedItem = false;
        HWND hwndListBox = GetDlgItem( hwnd, IDC_LIST );
        if( hwndListBox ) {
            int selCount = frantic::win32::ffListBox_GetSelCount( hwndListBox );
            if( selCount > 0 ) {
                hasSelectedItem = true;
            }
        }

        bool useSelectedEvents =
            pb->GetInt( group_dlg_proc_traits::FILTER_MODE_PARAMETER ) == group_dlg_proc_traits::FILTER_MODE_SELECTED;

        frantic::max3d::EnableCustButton( GetDlgItem( hwnd, IDC_ADD ), !inCreateMode && useSelectedEvents );
        frantic::max3d::EnableCustButton( GetDlgItem( hwnd, IDC_REMOVE ),
                                          hasSelectedItem && !inCreateMode && useSelectedEvents );
        frantic::max3d::EnableCustButton( GetDlgItem( hwnd, IDC_OPTIONS ), !inCreateMode && useSelectedEvents );
        ListBox_Enable( GetDlgItem( hwnd, IDC_LIST ), !inCreateMode && useSelectedEvents );
    }

  public:
    group_dlg_proc_base()
        : m_obj( 0 )
        , m_hwndTooltip( 0 ) {}
    group_dlg_proc_base( MaxKrakatoaPRTSourceObject* obj )
        : m_obj( obj ) {}

    INT_PTR DlgProc( TimeValue t, IParamMap2* map, HWND hwnd, UINT msg, WPARAM wParam, LPARAM /*lParam*/ ) {
        m_hwnd = hwnd;
        try {
            if( !m_obj ) {
                throw std::runtime_error( "Error: class object is NULL" );
            }
            if( !map ) {
                throw std::runtime_error( "Error: parameter map is NULL" );
            }
            int id = LOWORD( wParam );
            int notifyCode = HIWORD( wParam );
            switch( msg ) {
            case WM_INITDIALOG: {
                int fastForwardButtons[] = { IDC_OPTIONS };
                BOOST_FOREACH( int idc, fastForwardButtons ) {
                    GetKrakatoaGuiResources()->apply_custbutton_fast_forward_icon( GetDlgItem( hwnd, idc ) );
                    CustButton_SetRightClickNotify( GetDlgItem( hwnd, idc ), true );
                }

                typedef std::pair<int, int> control_tooltip_t;
                control_tooltip_t buttonTooltips[] = {
                    std::make_pair<int, int>( IDC_ADD, group_dlg_proc_traits::ADD_TOOLTIP ),
                    std::make_pair<int, int>( IDC_REMOVE, group_dlg_proc_traits::REMOVE_TOOLTIP ),
                    std::make_pair<int, int>( IDC_OPTIONS, group_dlg_proc_traits::OPTIONS_TOOLTIP ) };
                BOOST_FOREACH( const control_tooltip_t& buttonTooltip, buttonTooltips ) {
                    CustButton_SetTooltip( GetDlgItem( hwnd, buttonTooltip.first ), GetString( buttonTooltip.second ) );
                }

                LRESULT result = SendMessage( GetDlgItem( hwnd, IDC_FILTER_MODE_ALL ), WM_SETTEXT, 0,
                                              (LPARAM)group_dlg_proc_traits::get_all_radio_label() );
                result = SendMessage( GetDlgItem( hwnd, IDC_FILTER_MODE_SELECTED ), WM_SETTEXT, 0,
                                      (LPARAM)group_dlg_proc_traits::get_selected_radio_label() );

                Update( t );
                invalidate_event_list( hwnd );
                update_control_enable( hwnd );

                m_inplaceTooltip.attach( GetDlgItem( hwnd, IDC_LIST ) );
            } break;
            case WM_DESTROY:
                m_inplaceTooltip.detach( GetDlgItem( hwnd, IDC_LIST ) );
                break;
            case WM_COMMAND:
                switch( id ) {
                case IDC_ADD: {
                    // TODO : notify if there are no particle flow objects in the object list ?
                    std::vector<particle_group_filter_entry::ptr_type> groupList;

                    group_dlg_proc_traits::get_groups( m_obj, groupList );

                    std::vector<bool> initialIncludedList( groupList.size(), false );
                    for( std::size_t i = 0; i < groupList.size(); ++i ) {
                        if( groupList[i]->is_included() ) {
                            initialIncludedList[i] = true;
                        }
                    }

                    show_edit_particle_groups_dialog( hInstance, GetCOREInterface()->GetMAXHWnd(),
                                                      group_dlg_proc_traits::get_particle_system_type(),
                                                      group_dlg_proc_traits::get_group_type_plural(), groupList );

                    if( has_change( initialIncludedList, groupList ) ) {
                        if( !theHold.Holding() ) {
                            theHold.Begin();
                        }
                        group_dlg_proc_traits::clear_groups( m_obj );
                        BOOST_FOREACH( particle_group_filter_entry::ptr_type group, groupList ) {
                            if( group->is_included() ) {
                                group->add_to_prt_source( *m_obj );
                            }
                        }
                        theHold.Accept( ::GetString( IDS_ADD_PARTICLE_GROUPS ) );
                    }
                } break;
                case IDC_REMOVE: {
                    HWND hwndEventList = GetDlgItem( hwnd, IDC_LIST );
                    if( hwndEventList ) {
                        std::vector<int> selectedIndices;
                        frantic::win32::ffListBox_GetSelItems( hwndEventList, selectedIndices );
                        if( selectedIndices.size() > 0 ) {
                            // split into pflow and tp indices
                            IParamBlock2* pb = m_obj->GetParamBlockByID( 0 );
                            if( pb ) {
                                if( !theHold.Holding() ) {
                                    theHold.Begin();
                                }
                                group_dlg_proc_traits::remove_groups( m_obj, selectedIndices );

                                theHold.Accept( ::GetString( IDS_REMOVE_PARTICLE_GROUPS ) );
                            }
                        }
                    }
                } break;
                case IDC_OPTIONS:
                    frantic::max3d::mxs::expression(
                        frantic::tstring() + _T("if (PRTSourceCallbacks!=undefined) do (PRTSourceCallbacks.") +
                        group_dlg_proc_traits::get_mxs_options_callback() + _T(" MaxKrakatoaPRTSourceObjectNode)") )
                        .bind( _T("MaxKrakatoaPRTSourceObjectNode"), m_obj )
                        .at_time( t )
                        .evaluate<void>();
                    break;
                case IDC_LIST:
                    switch( notifyCode ) {
                    case LBN_SELCHANGE:
                        update_control_enable( hwnd );
                        break;
                    case LBN_SELCANCEL:
                        update_control_enable( hwnd );
                        break;
                    }
                    break;
                }
                break;
            }
        } catch( const std::exception& e ) {
            frantic::tstring errmsg = group_dlg_proc_traits::get_dlg_proc_name() +
                                      frantic::tstring( _T("::DlgProc: ") ) + frantic::strings::to_tstring( e.what() ) +
                                      _T("\n");
            FF_LOG( debug ) << errmsg << std::endl;
            LogSys* log = GetCOREInterface()->Log();
            log->LogEntry( SYSLOG_ERROR, NO_DIALOG, _T("PRTSource Error"), _T("%s"), errmsg.c_str() );
        }
        return FALSE;
    }

    void Update( TimeValue /*t*/ ) {
        try {
            update_control_enable( m_hwnd );
        } catch( const std::exception& e ) {
            frantic::tstring errmsg = group_dlg_proc_traits::get_dlg_proc_name() +
                                      frantic::tstring( _T("::Update: ") ) + frantic::strings::to_tstring( e.what() ) +
                                      _T("\n");
            FF_LOG( error ) << errmsg << std::endl;
            LogSys* log = GetCOREInterface()->Log();
            log->LogEntry( SYSLOG_ERROR, NO_DIALOG, _T("PRTSource Error"), _T("%s"), errmsg.c_str() );
        }
    }

    void SetThing( ReferenceTarget* obj ) { m_obj = (MaxKrakatoaPRTSourceObject*)obj; }

    void SetMaxKrakatoaPRTSourceObject( MaxKrakatoaPRTSourceObject* MaxKrakatoaPRTSourceObject ) {
        m_obj = MaxKrakatoaPRTSourceObject;
    }

    void InvalidateUI( HWND hwnd, int element ) {
        if( !hwnd ) {
            return;
        }
        switch( element ) {
        case group_dlg_proc_traits::GROUP_LIST_PARAMETER:
            if( m_obj && m_obj->editObj == m_obj ) {
                invalidate_event_list( hwnd );
                update_control_enable( hwnd );
            }
            break;
        }
    }

    void get_group_list_selection( std::vector<int>& outSelection ) {
        outSelection.clear();
        if( ( !m_obj ) || ( m_obj != m_obj->editObj ) ) {
            return;
        }
        IParamBlock2* pb = m_obj->GetParamBlockByID( 0 );
        if( !pb ) {
            return;
        }
        IParamMap2* pm = pb->GetMap( group_dlg_proc_traits::PARAM_MAP );
        if( !pm ) {
            return;
        }
        const HWND hwnd = pm->GetHWnd();
        if( !hwnd ) {
            return;
        }
        const HWND hwndNodeList = GetDlgItem( hwnd, IDC_LIST );
        std::vector<int> result;
        get_list_box_selection_mxs( hwndNodeList, result );
        outSelection.swap( result );
    }

    void set_group_list_selection( const std::vector<int>& selection ) {
        if( ( !m_obj ) || ( m_obj != m_obj->editObj ) ) {
            return;
        }
        IParamBlock2* pb = m_obj->GetParamBlockByID( 0 );
        if( !pb ) {
            return;
        }
        IParamMap2* pm = pb->GetMap( group_dlg_proc_traits::PARAM_MAP );
        if( !pm ) {
            return;
        }
        const HWND hwnd = pm->GetHWnd();
        if( !hwnd ) {
            return;
        }
        const HWND hwndNodeList = GetDlgItem( hwnd, IDC_LIST );
        set_list_box_selection_mxs( hwndNodeList, selection );
        update_control_enable( hwnd );
    }

    void invalidate_group_list_labels() {
        if( m_obj && m_obj->editObj == m_obj && m_hwnd ) {
            IParamBlock2* pb = m_obj->GetParamBlockByID( 0 );
            if( !pb ) {
                return;
            }
            IParamMap2* pm = pb->GetMap( group_dlg_proc_traits::PARAM_MAP );
            if( !pm ) {
                return;
            }
            const HWND hwnd = pm->GetHWnd();
            if( !hwnd ) {
                return;
            }
            HWND hwndCtrl = GetDlgItem( hwnd, IDC_LIST );
            if( hwndCtrl ) {
                std::vector<frantic::tstring> eventNames;
                group_dlg_proc_traits::get_group_names( m_obj, eventNames );
                if( eventNames.size() == ListBox_GetCount( hwndCtrl ) ) {
                    // try to keep selection and scroll pos
                    const int topIndex = ListBox_GetTopIndex( hwndCtrl );
                    std::vector<int> selection;
                    frantic::win32::ffListBox_GetSelItems( hwndCtrl, selection );
                    frantic::win32::ffListBox_SetStrings( hwndCtrl, eventNames );
                    frantic::win32::ffListBox_SetSelItems( hwndCtrl, selection );
                    ListBox_SetTopIndex( hwndCtrl, topIndex );
                } else {
                    frantic::win32::ffListBox_SetStrings( hwndCtrl, eventNames );
                }
            }
        }
    }

    void DeleteThis() {
        // static !
        // delete this;
    }
};
