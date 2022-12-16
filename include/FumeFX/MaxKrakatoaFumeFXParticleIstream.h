// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0
/**
 * TODO: Combine this with the Stoke implementation and refactor into the FranticMaxLibrary.
 */

#pragma once

#if defined( FUMEFX_SDK_AVAILABLE )
#include <boost/smart_ptr.hpp>
#include <frantic/graphics/boundbox3.hpp>
#include <frantic/graphics/vector3f.hpp>
#include <frantic/particles/streams/particle_istream.hpp>
#include <frantic/volumetrics/voxel_sampler_interface.hpp>

class INode;

enum fume_channels {
    fume_smoke_channel = ( 1 << 0 ),
    fume_fuel_channel = ( 1 << 1 ),
    fume_velocity_channel = ( 1 << 2 ),
    fume_temperature_channel = ( 1 << 3 ),
    fume_texturecoord_channel = ( 1 << 4 )
};

frantic::channels::channel_map get_fumefx_native_map( INode* pNode );

boost::shared_ptr<frantic::particles::streams::particle_istream>
get_fume_fx_particle_istream( INode* pNode, TimeValue t, const frantic::channels::channel_map& pcm,
                              frantic::volumetrics::voxel_sampler_interface_ptr pVoxelIter,
                              int disabledChannels, // A bit combination of enum fume_channels;
                              float minDensity, float minFire );

boost::shared_ptr<frantic::particles::streams::particle_istream>
apply_fume_fx_emission_shading_istream( boost::shared_ptr<frantic::particles::streams::particle_istream> pin,
                                        INode* pNode, TimeValue t, float scalar );
#endif
