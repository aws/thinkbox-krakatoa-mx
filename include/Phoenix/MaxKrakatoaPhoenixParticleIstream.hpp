// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0
#pragma once

#if defined( PHONEIX_SDK_AVAILABLE )

#include <frantic/particles/streams/particle_istream.hpp>
#include <frantic/volumetrics/voxel_sampler_interface.hpp>

class INode;
typedef int TimeValue;
class IPhoenixFDPrtGroup;

/**
 * Return true iff the INode is a PRT Phoenix Object.
 */
bool IsPhoenixObject( INode* pNode, TimeValue t );

/**
 * Get a particle_istream for a specific IPhoenixFDPrtGroup in a Phoenix FD simulation.
 *
 * Position is in object space.
 */
boost::shared_ptr<frantic::particles::streams::particle_istream>
GetPhoenixParticleIstream( INode* pNode, IPhoenixFDPrtGroup* particles, TimeValue t,
                           const frantic::channels::channel_map& pcm );

/**
 * Get a particle_istream which gets the results of seeding inside the Phoenix FD simulation at `pNode` using the voxel
 * sampler.
 */
frantic::particles::particle_istream_ptr
GetPhoenixParticleIstreamFromVolume( INode* pNode, TimeValue t, const frantic::channels::channel_map& pcm,
                                     frantic::volumetrics::voxel_sampler_interface_ptr pVoxelIter, float minSmoke,
                                     float minTemperature );
#endif
