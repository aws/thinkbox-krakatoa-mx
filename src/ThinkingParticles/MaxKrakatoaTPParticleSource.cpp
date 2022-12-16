// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0
#include "stdafx.h"

#if defined( THINKING_PARTICLES_SDK_AVAILABLE )
#include "MaxKrakatoaParticleSources.h"

#include <frantic/max3d/particles/max3d_particle_utils.hpp>
#include <frantic/max3d/particles/tp_interface.hpp>

using namespace frantic::max3d::particles;
using namespace frantic::particles::streams;
using frantic::max3d::particles::tp_interface;

/**
 * A particle source for Thinking Particles objects. You must create one per TP group.
 */
class ThinkingParticleSourceFactory::ThinkingParticleSource
    : public KrakatoaParticleSource::KrakatoaParticleSourceImpl {
  public:
    ThinkingParticleSource( INode* pNode )
        : KrakatoaParticleSource::KrakatoaParticleSourceImpl( pNode ) {}

    virtual boost::shared_ptr<particle_istream> GetParticleStream( MaxKrakatoaRenderGlobalContext* globContext ) const {
        boost::shared_ptr<particle_istream> pin;
        pin = tp_interface::get_instance().get_particle_stream( globContext->GetDefaultChannels(), m_pNode, NULL,
                                                                globContext->GetTime() );
        pin = visibility_density_scale_stream_with_inode( m_pNode, globContext->GetTime(), pin );
        return pin;
    }
};

ThinkingParticleSourceFactory::ThinkingParticleSourceFactory( bool enabled )
    : m_enabled( enabled )
    , get_tp_groups( NULL ) {}

bool ThinkingParticleSourceFactory::Process( INode* pNode, TimeValue /*t*/,
                                             std::vector<KrakatoaParticleSource>& outSources ) const {
    if( tp_interface::get_instance().is_node_thinking_particles( pNode ) ) {
        if( m_enabled )
            outSources.push_back( KrakatoaParticleSource( new ThinkingParticleSource( pNode ) ) );
        return true;
    }

    return false;
}
#endif
