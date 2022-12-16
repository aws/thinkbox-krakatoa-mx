// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0
#pragma once

#include <modstack.h>

#include <boost/smart_ptr.hpp>

#include <frantic/channels/channel_operation_compiler.hpp>
#include <frantic/channels/channel_operation_nodes.hpp>
#include <frantic/particles/streams/particle_istream.hpp>

#include <frantic/max3d/particles/IMaxKrakatoaPRTObject.hpp>
#include <frantic/max3d/shaders/map_query.hpp>

#include <krakatoa/scene_context.hpp>

inline bool is_krakatoa_channel_modifier( ReferenceTarget* pMod ) {
    return ( pMod->ClassID() == Class_ID( 0x17776900, 0x2de0f78 ) ) != FALSE;
}

inline bool is_krakatoa_delete_modifier( ReferenceTarget* pMod ) {
    return
        // Normal delete modifier
        ( pMod->ClassID() == Class_ID( 0x7fc844e7, 0x1fe348d5 ) ) != FALSE ||
        // WSM version
        ( pMod->ClassID() == Class_ID( 0x13b4570d, 0x4c44758b ) ) != FALSE;
}

void create_kcm_ast_nodes( std::vector<frantic::channels::channel_op_node*>& outNodes,
                           krakatoa::scene_context_ptr sceneContext, INode* pNode, ReferenceTarget* pMagmaHolder );

boost::shared_ptr<frantic::particles::streams::particle_istream> get_krakatoa_channel_modifier_particle_istream(
    boost::shared_ptr<frantic::particles::streams::particle_istream> delegatePin,
    krakatoa::scene_context_ptr sceneContext, INode* pNode, ReferenceTarget* pMagmaHolder );

boost::shared_ptr<frantic::particles::streams::particle_istream> get_krakatoa_channel_modifier_particle_istream(
    boost::shared_ptr<frantic::particles::streams::particle_istream> delegatePin,
    frantic::max3d::particles::IMaxKrakatoaPRTEvalContextPtr sceneContext, INode* pNode,
    ReferenceTarget* pMagmaHolder );
