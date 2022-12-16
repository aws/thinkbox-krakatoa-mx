// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0
#pragma once

#include "group_dlg_proc_base.hpp"
#include "tp_group_info.hpp"
#include <Objects/MaxKrakatoaPRTSource.hpp>

#include <boost/foreach.hpp>

class tp_groups_dlg_proc_traits {
  public:
    enum { PARAM_MAP = kTPGroupParamRollout };
    enum { GROUP_LIST_PARAMETER = kTPGroupList };
    enum { FILTER_MODE_PARAMETER = kTPGroupFilterMode };
    enum { FILTER_MODE_SELECTED = PARTICLE_GROUP_FILTER_MODE::SELECTED };

    enum { ADD_TOOLTIP = IDS_PARTICLE_GROUPS_ADD_TOOLTIP };
    enum { REMOVE_TOOLTIP = IDS_PARTICLE_GROUPS_REMOVE_TOOLTIP };
    enum { OPTIONS_TOOLTIP = IDS_PARTICLE_GROUPS_OPTIONS_TOOLTIP };

    static void get_group_names( MaxKrakatoaPRTSourceObject* source, std::vector<frantic::tstring>& outNames ) {
        source->GetTPGroupNames( outNames );
    }

    static void clear_groups( MaxKrakatoaPRTSourceObject* source ) { source->ClearTPGroups(); }

    static void remove_groups( MaxKrakatoaPRTSourceObject* source, const std::vector<int>& indices ) {
        source->RemoveTPGroups( indices );
    }

    static void get_groups( MaxKrakatoaPRTSourceObject* source,
                            std::vector<particle_group_filter_entry::ptr_type>& outGroupList ) {
        // we need to get all TP groups, but also get the currently selected ones,
        // in case the TP object still exists but it has been ( temporarily ? ) removed from the particle objects list
        // so we'll need a set of "all" groups, then append the current groups that aren't in "all"
        std::vector<tp_group_info> selectedTpGroups;
        source->GetSelectedTPGroups( selectedTpGroups );
        std::vector<tp_group_info> allTpGroups;
        source->GetAllTPGroups( allTpGroups );

        std::set<ReferenceTarget*> allTpGroupSet;
        std::set<ReferenceTarget*> selectedTpGroupSet;

        BOOST_FOREACH( tp_group_info& groupInfo, allTpGroups ) {
            allTpGroupSet.insert( groupInfo.group );
        }

        // for each selected group,
        // if not in "all" set,
        // append it to the "all" set
        BOOST_FOREACH( tp_group_info& groupInfo, selectedTpGroups ) {
            if( allTpGroupSet.find( groupInfo.group ) == allTpGroupSet.end() ) {
                allTpGroups.push_back( groupInfo );
                allTpGroupSet.insert( groupInfo.group );
            }
            selectedTpGroupSet.insert( groupInfo.group );
        }

        outGroupList.clear();
        outGroupList.reserve( allTpGroups.size() );
        BOOST_FOREACH( tp_group_info& groupInfo, allTpGroups ) {
            if( groupInfo.group ) {
                bool keep = true; // false;
                bool include = false;
                if( selectedTpGroupSet.find( groupInfo.group ) != selectedTpGroupSet.end() ) {
                    include = true;
                }
                /*
                if( source->is_acceptable_tp_group( groupInfo.node, groupInfo.group ) ) {
                        keep = true;
                        include = false;
                } else if( source->has_tp_group( groupInfo.node, groupInfo.group ) ) {
                        keep = true;
                        include = true;
                }
                */
                if( keep ) {
                    particle_group_filter_entry::ptr_type entry(
                        new thinking_particles_group_filter_entry( groupInfo.node, groupInfo.group, groupInfo.name ) );
                    entry->set_include( include );
                    outGroupList.push_back( entry );
                }
            }
        }
        /*
        outGroupList.clear();
        outGroupList.reserve( allTpGroups.size() );
        BOOST_FOREACH( tp_group_info & groupInfo, allTpGroups ) {
                if( groupInfo.group ) {
                        bool keep = false;
                        bool include = false;
                        if( source->is_acceptable_tp_group( groupInfo.node, groupInfo.group ) ) {
                                keep = true;
                                include = false;
                        } else if( source->has_tp_group( groupInfo.node, groupInfo.group ) ) {
                                keep = true;
                                include = true;
                        }
                        if( keep ) {
                                particle_group_filter_entry::ptr_type entry( new thinking_particles_group_filter_entry(
        groupInfo.node, groupInfo.group, groupInfo.name ) ); entry->set_include( include ); outGroupList.push_back(
        entry );
                        }
                }
        }
        */
    }

    static const TCHAR* get_mxs_options_callback() { return _T("on_TPGroupListOptions_pressed"); }

    static const TCHAR* get_dlg_proc_name() { return _T("tp_groups_dlg_proc"); }

    static const TCHAR* get_all_radio_label() { return _T("All Groups"); }

    static const TCHAR* get_selected_radio_label() { return _T("Selected Groups:"); }

    static const TCHAR* get_particle_system_type() { return _T("Thinking Particles"); }

    static const TCHAR* get_group_type_plural() { return _T("Groups"); }
};

typedef group_dlg_proc_base<tp_groups_dlg_proc_traits> tp_groups_dlg_proc;
