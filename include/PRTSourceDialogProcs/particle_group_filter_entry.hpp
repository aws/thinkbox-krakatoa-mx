// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0
// File pulled from FrostMX

#pragma once

#include <Objects/MaxKrakatoaPRTSource.hpp>

class particle_group_filter_entry {
    bool m_include;

  public:
    typedef boost::shared_ptr<particle_group_filter_entry> ptr_type;

    particle_group_filter_entry()
        : m_include( false ) {}
    virtual ~particle_group_filter_entry() {}
    virtual const TCHAR* get_name() = 0;
    virtual void add_to_prt_source( MaxKrakatoaPRTSourceObject& prtSource ) = 0;

    void set_include( bool include = true ) { m_include = include; }
    bool is_included() { return m_include; }
    bool is_excluded() { return !m_include; }
};

class thinking_particles_group_filter_entry : public particle_group_filter_entry {
    INode* m_node;
    ReferenceTarget* m_group;
    frantic::tstring m_groupName;
    frantic::tstring m_name;

  public:
    thinking_particles_group_filter_entry( INode* node, ReferenceTarget* group, const frantic::tstring& groupName )
        : m_node( node )
        , m_group( group )
        , m_groupName( groupName ) {
        if( m_node ) {
            if( m_node->GetName() ) {
                m_name = m_node->GetName();
            } else {
                m_name = _T("<unknown>");
            }
            m_name += _T("->");
            m_name += m_groupName;
        } else {
            m_name = _T("<none>");
        }
    }
    const TCHAR* get_name() { return m_name.c_str(); }
    void add_to_prt_source( MaxKrakatoaPRTSourceObject& prtSource ) { prtSource.AddTPGroup( m_node, m_group ); }
};

class particle_flow_group_filter_entry : public particle_group_filter_entry {
    INode* m_node;

  public:
    particle_flow_group_filter_entry( INode* node )
        : m_node( node ) {}
    const TCHAR* get_name() {
        if( m_node ) {
            return m_node->GetName();
        } else {
            return _T("<none>");
        }
    }
    void add_to_prt_source( MaxKrakatoaPRTSourceObject& prtSource ) { prtSource.AddParticleFlowEvent( m_node ); }
};
