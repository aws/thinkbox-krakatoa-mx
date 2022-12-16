// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0
#pragma once

#include <frantic/channels/channel_operation_nodes.hpp>
#include <frantic/channels/named_channel_data.hpp>

#include <krakatoa/scene_context.hpp>

namespace texmap_output {
enum output_t { color, mono, bump };
}

/**
 * Creates and returns an instance of frantic::channels::channel_op_node that will evaluate the TexMap in the given
 * context.
 *
 * @param id The unique non-negativer id of channel_op_node.
 * @param theMap The TexMap object to evaluate.
 * @param outputType The particular output of the TexMap to query. 3 types are supported.
 * @param sceneContext The context to evaluate the TexMap in. Must be convertible to a MaxKrakatoaSceneContext object,
 * since we need to get Max specific data out.
 * @param pNode The scene node this evaluation is associated with.
 * @param inWorldSpace True if the incoming data is already in worldspace, false if pNode->GetNodeTM() must first be
 * applied to incoming data.
 */
frantic::channels::channel_op_node* CreateMaxKrakatoaChannelTexmapOperator( int id, Texmap* theMap,
                                                                            texmap_output::output_t outputType,
                                                                            krakatoa::scene_context_ptr sceneContext,
                                                                            INode* pNode, bool inWorldSpace = false );
