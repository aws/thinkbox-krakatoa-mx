// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0
#pragma once

#include <frantic/channels/channel_map.hpp>
#include <frantic/channels/channel_map_adaptor.hpp>
#include <frantic/particles/streams/particle_istream.hpp>

#include <frantic/max3d/shaders/map_query.hpp>

class MaxKrakatoaStdMaterialIStreamData;

class MaxKrakatoaStdMaterialIStream : public frantic::particles::streams::delegated_particle_istream {
    // Holds the channel accessors, render context, thread-local shade_context, etc.
    MaxKrakatoaStdMaterialIStreamData* m_pData;

    Mtl* m_pMtl;
    TimeValue m_time;
    frantic::max3d::shaders::renderInformation m_renderInfo;

    bool m_doShadeColor;
    bool m_doShadeAbsorption;
    bool m_doShadeEmission;
    bool m_doShadeDensity;

    frantic::channels::channel_map_adaptor m_adaptor;
    frantic::channels::channel_map m_outPcm, m_nativePcm;

  public:
    MaxKrakatoaStdMaterialIStream( boost::shared_ptr<frantic::particles::streams::particle_istream> pDelegate,
                                   Mtl* pMtl, const frantic::max3d::shaders::renderInformation& renderInfo,
                                   bool doShadeColor, bool doShadeAbsorption, bool doShadeEmission, bool doShadeDensity,
                                   TimeValue t );

    virtual ~MaxKrakatoaStdMaterialIStream();

    void set_channel_map( const frantic::channels::channel_map& pcm );
    void set_default_particle( char* buffer );

    std::size_t particle_size() const { return m_outPcm.structure_size(); }

    const frantic::channels::channel_map& get_channel_map() const { return m_outPcm; }
    const frantic::channels::channel_map& get_native_channel_map() const { return m_nativePcm; }

    bool get_particle( char* outBuffer );
    bool get_particles( char* outBuffer, std::size_t& numParticles );
};
