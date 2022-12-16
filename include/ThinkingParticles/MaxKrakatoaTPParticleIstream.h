// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0
#pragma once

#include <boost/smart_ptr.hpp>
#include <frantic/particles/streams/particle_istream.hpp>

class INode;
class PGroup;
class ReferenceTarget;

boost::shared_ptr<frantic::particles::streams::particle_istream>
get_thinking_particle_istream_40( INode* pNode, ReferenceTarget* pGroup, TimeValue t,
                                  const frantic::channels::channel_map& pcm );

boost::shared_ptr<frantic::particles::streams::particle_istream>
get_thinking_particle_istream_30( INode* pNode, ReferenceTarget* pGroup, TimeValue t,
                                  const frantic::channels::channel_map& pcm );

boost::shared_ptr<frantic::particles::streams::particle_istream>
get_thinking_particle_istream_25( INode* pNode, ReferenceTarget* pGroup, TimeValue t,
                                  const frantic::channels::channel_map& pcm );

void get_tp_groups_25( INode* pNode, std::vector<ReferenceTarget*>& outGroups );

void get_tp_groups_30( INode* pNode, std::vector<ReferenceTarget*>& outGroups );

void get_tp_groups_40( INode* pNode, std::vector<ReferenceTarget*>& outGroups );
