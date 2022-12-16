// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0
/**
 * TODO: Combine this with the Stoke implementation and refactor into the FranticMaxLibrary.
 */

#include "stdafx.h"

#if defined( FUMEFX_SDK_AVAILABLE )

#include "FumeFX\MaxKrakatoaFumeFXParticleIStream.h"
#include "MaxKrakatoaParticleSources.h"
#include "Objects\MaxKrakatoaPRTInterface.h"

#include <frantic/max3d/particles/max3d_particle_utils.hpp>

using namespace frantic::particles::streams;

namespace {
void no_delete( void* ) {}
} // namespace

class FumeFXParticleSourceFactory::FumeFXParticleSource : public KrakatoaParticleSource::KrakatoaParticleSourceImpl {
    IMaxKrakatoaPRTObjectPtr m_pPRTObj;

  public:
    FumeFXParticleSource( INode* pNode, IMaxKrakatoaPRTObjectPtr pPRTObj )
        : KrakatoaParticleSource::KrakatoaParticleSourceImpl( pNode )
        , m_pPRTObj( pPRTObj ) {}

    virtual boost::shared_ptr<particle_istream> GetParticleStream( MaxKrakatoaRenderGlobalContext* globContext ) const {
        using namespace frantic::max3d::particles;
        using namespace frantic::particles::streams;

        Interval validInterval = FOREVER;

        frantic::max3d::particles::IMaxKrakatoaPRTEvalContextPtr pEvalContext( globContext, &no_delete );

        boost::shared_ptr<particle_istream> pin = m_pPRTObj->CreateStream( m_pNode, validInterval, pEvalContext );
        pin = visibility_density_scale_stream_with_inode( m_pNode, globContext->time, pin );
        return pin;
    }
};

FumeFXParticleSourceFactory::FumeFXParticleSourceFactory( bool enabled )
    : m_enabled( enabled ) {}

#define FUME_FX_CLASS_ID Class_ID( 902511643, 1454773937 )
bool FumeFXParticleSourceFactory::Process( INode* pNode, TimeValue /*t*/,
                                           std::vector<KrakatoaParticleSource>& outSources ) const {
    Object* pObj = pNode->GetObjectRef();
    if( !pObj )
        return false;
    pObj = pObj->FindBaseObject();

    if( IMaxKrakatoaPRTObjectPtr pPRTObj = GetIMaxKrakatoaPRTObject( pObj ) ) {
        if( pObj->ClassID() == MaxKrakatoaFumeFXObject_CLASS_ID ) {
            if( m_enabled )
                outSources.push_back( KrakatoaParticleSource( new FumeFXParticleSource( pNode, pPRTObj ) ) );
            return true;
        }
    }

    return false;
}

// HACK: This should look at a valid file in the sequence in order to determine this...
frantic::channels::channel_map get_fumefx_native_map( INode* /*pNode*/ ) {
    frantic::channels::channel_map map;

    if( /*pNode*/ false ) {
        // TODO: Use the node here.
    } else {
        map.define_channel<frantic::graphics::vector3f>( _T("Position") );
        map.define_channel<frantic::graphics::vector3f>( _T("Velocity") );
        map.define_channel<frantic::graphics::vector3f>( _T("TextureCoord") );
        map.define_channel<frantic::graphics::vector3f>( _T("Color") );
        map.define_channel<float>( _T("Density") );
        map.define_channel<float>( _T("Temperature") );
        map.define_channel<float>( _T("Fuel") );
        map.define_channel<float>( _T("Fire") );

        map.define_channel<frantic::graphics::vector3f>( _T("Vorticity") );
        map.define_channel<frantic::graphics::vector3f>( _T("DensityGradient") );
    }

    map.end_channel_definition();

    return map;
}
#endif
