// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0
#pragma once

#include "group_dlg_proc_base.hpp"
#include <Objects/MaxKrakatoaPRTSource.hpp>

#include <boost/foreach.hpp>

class particle_flow_events_dlg_proc_traits {
  public:
    enum { PARAM_MAP = kPFLowEventParamRollout };
    enum { GROUP_LIST_PARAMETER = kPFEventList };
    enum { FILTER_MODE_PARAMETER = kPFEventFilterMode };
    enum { FILTER_MODE_SELECTED = PARTICLE_GROUP_FILTER_MODE::SELECTED };

    enum { ADD_TOOLTIP = IDS_PARTICLE_FLOW_EVENTS_ADD_TOOLTIP };
    enum { REMOVE_TOOLTIP = IDS_PARTICLE_FLOW_EVENTS_REMOVE_TOOLTIP };
    enum { OPTIONS_TOOLTIP = IDS_PARTICLE_FLOW_EVENTS_OPTIONS_TOOLTIP };

    static void get_group_names( MaxKrakatoaPRTSourceObject* source, std::vector<frantic::tstring>& outNames ) {
        source->GetParticleFlowEventNames( outNames );
    }

    static void clear_groups( MaxKrakatoaPRTSourceObject* source ) { source->ClearParticleFlowEvents(); }

    static void remove_groups( MaxKrakatoaPRTSourceObject* source, const std::vector<int>& indices ) {
        source->RemoveParticleFlowEvents( indices );
    }

    static void get_groups( MaxKrakatoaPRTSourceObject* source,
                            std::vector<particle_group_filter_entry::ptr_type>& outGroupList ) {
        std::vector<INode*> allPfEvents;
        source->GetAllParticleFlowEvents( allPfEvents );

        std::vector<INode*> selectedPfEvents;
        source->GetSelectedParticleFlowEvents( selectedPfEvents );

        std::set<INode*> allPfEventSet;
        std::set<INode*> selectedPfEventSet;

        BOOST_FOREACH( INode* event, allPfEvents ) {
            allPfEventSet.insert( event );
        }

        BOOST_FOREACH( INode* selectedEvent, selectedPfEvents ) {
            if( allPfEventSet.find( selectedEvent ) == allPfEventSet.end() ) {
                allPfEvents.push_back( selectedEvent );
                allPfEventSet.insert( selectedEvent );
            }
            selectedPfEventSet.insert( selectedEvent );
        }

        outGroupList.clear();
        outGroupList.reserve( allPfEvents.size() );
        BOOST_FOREACH( INode* node, allPfEvents ) {
            if( node ) {
                bool keep = true; // false;
                bool include = false;
                if( selectedPfEventSet.find( node ) != selectedPfEventSet.end() ) {
                    include = true;
                }
                if( keep ) {
                    particle_group_filter_entry::ptr_type entry( new particle_flow_group_filter_entry( node ) );
                    entry->set_include( include );
                    outGroupList.push_back( entry );
                }
            }
        }
    }

    static const TCHAR* get_mxs_options_callback() { return _T("on_PFEventListOptions_pressed"); }

    static const TCHAR* get_dlg_proc_name() { return _T("particle_flow_events_dlg_proc"); }

    static const TCHAR* get_all_radio_label() { return _T("All Events"); }

    static const TCHAR* get_selected_radio_label() { return _T("Selected Events:"); }

    static const TCHAR* get_particle_system_type() { return _T("Particle Flow"); }

    static const TCHAR* get_group_type_plural() { return _T("Events"); }
};

typedef group_dlg_proc_base<particle_flow_events_dlg_proc_traits> particle_flow_events_dlg_proc;
