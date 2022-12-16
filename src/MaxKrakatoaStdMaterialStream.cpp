// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0
#include "stdafx.h"

#include "MaxKrakatoaStdMaterialStream.h"

#include <vector>

#include <boost/thread/tss.hpp>

#include <frantic/max3d/convert.hpp>
#include <frantic/max3d/shaders/max_environment_map_provider.hpp>

#include <frantic/channels/channel_accessor.hpp>
#include <frantic/graphics/vector3f.hpp>
#include <frantic/particles/streams/particle_istream.hpp>
#include <frantic/particles/particle_array_iterator.hpp>

#pragma warning( push, 3 )
#include <tbb/parallel_for.h>
#pragma warning( pop )

using namespace frantic::channels;
using namespace frantic::graphics;
using namespace frantic::particles;
using namespace frantic::particles::streams;
using namespace frantic::max3d::shaders;

//#define FRANTIC_DISABLE_THREADS

class MaxKrakatoaStdMaterialIStreamData {
    std::vector<std::pair<int, channel_cvt_accessor<vector3f>>> m_uvwAccessors;
    channel_accessor<vector3f> m_positionAccessor;
    channel_cvt_accessor<color3f> m_colorAccessor;
    channel_cvt_accessor<color3f> m_filterColorAccessor;
    channel_cvt_accessor<color3f> m_selfIllumAccessor;
    channel_cvt_accessor<vector3f> m_normalAccessor;
    channel_cvt_accessor<float> m_specLevelAccessor;
    channel_cvt_accessor<float> m_specPowerAccessor;
    channel_cvt_accessor<float> m_densityAccessor;
    channel_cvt_accessor<int> m_mtlIndexAccessor;

    Mtl* m_pMtl;
    TimeValue m_time;
    renderInformation m_renderInfo;

    mutable boost::thread_specific_ptr<multimapping_shadecontext> m_pShadeContext;

  public:
    MaxKrakatoaStdMaterialIStreamData( Mtl* pMtl, const renderInformation& renderInfo, const channel_map& outPcm,
                                       bool doShadeColor, bool doShadeAbsorption, bool doShadeEmission,
                                       bool doShadeDensity, boost::shared_ptr<particle_istream> pDelegate, TimeValue t )
        : m_renderInfo( renderInfo )
        , m_pMtl( pMtl )
        , m_time( t ) {
        // Update the material, and collect the required UVW channels from it.
        BitArray reqUVWs;
        frantic::max3d::shaders::update_material_for_shading( pMtl, m_time );
        frantic::max3d::shaders::collect_material_requirements( pMtl, reqUVWs );

        channel_map newDelegateMap = outPcm;
        const channel_map& delegateNativeMap = pDelegate->get_native_channel_map();

        // The 'Position' channel is always required
        if( !newDelegateMap.has_channel( _T("Position") ) )
            newDelegateMap.append_channel<vector3f>( _T("Position") );
        m_positionAccessor = newDelegateMap.get_accessor<vector3f>( _T("Position") );

        // Force the 'Normal' channel to exist
        if( !newDelegateMap.has_channel( _T("Normal") ) )
            newDelegateMap.append_channel<vector3f>( _T("Normal") );
        m_normalAccessor = newDelegateMap.get_cvt_accessor<vector3f>( _T("Normal") );

        if( !newDelegateMap.has_channel( _T("MtlIndex") ) && delegateNativeMap.has_channel( _T("MtlIndex") ) )
            newDelegateMap.append_channel<int>( _T("MtlIndex") );

        m_mtlIndexAccessor.reset( 0 );
        if( newDelegateMap.has_channel( _T("MtlIndex") ) )
            m_mtlIndexAccessor = newDelegateMap.get_cvt_accessor<int>( _T("MtlIndex") );

        // Only fill the output channels if they are requested further upstream.
        m_colorAccessor.reset();
        m_filterColorAccessor.reset();
        m_selfIllumAccessor.reset();
        m_densityAccessor.reset();

        if( doShadeColor && newDelegateMap.has_channel( _T("Color") ) )
            m_colorAccessor = newDelegateMap.get_cvt_accessor<color3f>( _T("Color") );
        if( doShadeAbsorption && newDelegateMap.has_channel( _T("Absorption") ) )
            m_filterColorAccessor = newDelegateMap.get_cvt_accessor<color3f>( _T("Absorption") );
        if( doShadeEmission && newDelegateMap.has_channel( _T("Emission") ) )
            m_selfIllumAccessor = newDelegateMap.get_cvt_accessor<color3f>( _T("Emission") );
        if( doShadeDensity && newDelegateMap.has_channel( _T("Density") ) )
            m_densityAccessor = newDelegateMap.get_cvt_accessor<float>( _T("Density") );

        // Optional Shader channels
        m_specLevelAccessor.reset();
        m_specPowerAccessor.reset();

        if( newDelegateMap.has_channel( _T("SpecularLevel") ) )
            m_specLevelAccessor = newDelegateMap.get_cvt_accessor<float>( _T("SpecularLevel") );
        if( newDelegateMap.has_channel( _T("SpecularPower") ) )
            m_specPowerAccessor = newDelegateMap.get_cvt_accessor<float>( _T("SpecularPower") );

        if( m_pMtl->ClassID() != Class_ID( DMTL_CLASS_ID, 0 ) &&
            ( m_filterColorAccessor.is_valid() || m_selfIllumAccessor.is_valid() ) ) {
            FF_LOG( warning ) << _T("The 'Absorption' and 'Emission' channels are only accessible from Std Materials ")
                                 _T("and Krakatoa Materials.")
                              << std::endl;
        }

        // Check for 'Color' specifically, since it does not match the general naming scheme.
        if( reqUVWs[0] ) {
            if( !newDelegateMap.has_channel( _T("Color") ) ) {
                if( !delegateNativeMap.has_channel( _T("Color") ) ) {
                    FF_LOG( warning ) << _T("The material: ") << pMtl->GetName()
                                      << _T(" requires map channel 0, which is not available") << std::endl;
                    m_uvwAccessors.push_back( std::make_pair( 0, channel_cvt_accessor<vector3f>( vector3f( 0 ) ) ) );
                } else {
                    const channel& ch = delegateNativeMap[_T("Color")];
                    newDelegateMap.append_channel( ch.name(), ch.arity(), ch.data_type() );
                    m_uvwAccessors.push_back(
                        std::make_pair( 0, newDelegateMap.get_cvt_accessor<vector3f>( _T("Color") ) ) );
                }
            } else {
                m_uvwAccessors.push_back(
                    std::make_pair( 0, newDelegateMap.get_cvt_accessor<vector3f>( _T("Color") ) ) );
            }
        }

        // Check for 'TextureCoord' specifically, since it does not match the general naming scheme.
        if( reqUVWs[1] ) {
            if( !newDelegateMap.has_channel( _T("TextureCoord") ) ) {
                if( !delegateNativeMap.has_channel( _T("TextureCoord") ) ) {
                    FF_LOG( warning ) << _T("The material: ") << pMtl->GetName()
                                      << _T(" requires map channel 1, which is not available") << std::endl;
                    m_uvwAccessors.push_back( std::make_pair( 1, channel_cvt_accessor<vector3f>( vector3f( 0 ) ) ) );
                } else {
                    const channel& ch = delegateNativeMap[_T("TextureCoord")];
                    newDelegateMap.append_channel( ch.name(), ch.arity(), ch.data_type() );
                    m_uvwAccessors.push_back(
                        std::make_pair( 1, newDelegateMap.get_cvt_accessor<vector3f>( _T("TextureCoord") ) ) );
                }
            } else {
                m_uvwAccessors.push_back(
                    std::make_pair( 1, newDelegateMap.get_cvt_accessor<vector3f>( _T("TextureCoord") ) ) );
            }
        }

        // Check for each required UVW channel, and request it from the delegate object if it is in the
        // native channel map.
        for( int i = 2; i < MAX_MESHMAPS; ++i ) {
            if( !reqUVWs[i] )
                continue;

            frantic::tstring chName = _T("Mapping") + boost::lexical_cast<frantic::tstring>( i );
            if( !newDelegateMap.has_channel( chName ) ) {
                if( !delegateNativeMap.has_channel( chName ) ) {
                    FF_LOG( warning ) << _T("The material: ") << pMtl->GetName() << _T(" requires map channel ") << i
                                      << _T(", which is not available") << std::endl;
                    m_uvwAccessors.push_back( std::make_pair( i, channel_cvt_accessor<vector3f>( vector3f( 0 ) ) ) );
                } else {
                    const channel& ch = delegateNativeMap[chName];
                    newDelegateMap.append_channel( ch.name(), ch.arity(), ch.data_type() );
                    m_uvwAccessors.push_back(
                        std::make_pair( i, newDelegateMap.get_cvt_accessor<vector3f>( chName ) ) );
                }
            } else {
                m_uvwAccessors.push_back( std::make_pair( i, newDelegateMap.get_cvt_accessor<vector3f>( chName ) ) );
            }
        }

        // Request the modified channel map from the delegate.
        // TODO: Only change the delegate's map if we appended an extra channel.
        pDelegate->set_channel_map( newDelegateMap );
    }

    virtual ~MaxKrakatoaStdMaterialIStreamData() { m_pShadeContext.reset(); }

    void shade_particle( char* particle ) const {
        // Dereferencing a boost::thread_specific_ptr is expensive. (Caused weird Noise map behaviour)
        multimapping_shadecontext* pSC = m_pShadeContext.get();
        if( !pSC ) {
            pSC = new multimapping_shadecontext;
            m_pShadeContext.reset( pSC );
        }

        // NOTE: Need to set this each time, or else some TexMaps are messing up.
        pSC->shadeTime = m_time;
        pSC->camPos = m_renderInfo.m_cameraPosition;
        pSC->position = frantic::max3d::to_max_t( m_positionAccessor.get( particle ) );
        pSC->normal = frantic::max3d::to_max_t( m_normalAccessor.get( particle ) );
        pSC->view = Normalize( pSC->position - pSC->camPos );
        pSC->toObjectSpaceTM = frantic::max3d::to_max_t( m_renderInfo.m_toObjectTM );
        pSC->toWorldSpaceTM = frantic::max3d::to_max_t( m_renderInfo.m_toWorldTM );
        pSC->mtlNum = m_mtlIndexAccessor.get( particle );

        for( std::size_t i = 0, iEnd = m_uvwAccessors.size(); i < iEnd; ++i )
            pSC->uvwArray[m_uvwAccessors[i].first] =
                frantic::max3d::to_max_t( m_uvwAccessors[i].second.get( particle ) );

        if( m_pMtl->ClassID() == Class_ID( DMTL_CLASS_ID, 0 ) ) {
            StdMat2* pStdMat = static_cast<StdMat2*>( m_pMtl );
            if( m_colorAccessor.is_valid() ) {
                Texmap* pMap = pStdMat->GetSubTexmap( ID_DI );
                Color baseColor = pStdMat->GetDiffuse( m_time );
                if( pStdMat->MapEnabled( ID_DI ) && pMap ) {
                    Color texColor = pMap->EvalColor( *pSC );
                    float alpha = pStdMat->GetTexmapAmt( ID_DI, m_time );
                    m_colorAccessor.set( particle,
                                         frantic::max3d::from_max_t( alpha * texColor + ( 1 - alpha ) * baseColor ) );
                } else {
                    m_colorAccessor.set( particle, frantic::max3d::from_max_t( baseColor ) );
                }
            }

            if( m_filterColorAccessor.is_valid() ) {
                Texmap* pMap = pStdMat->GetSubTexmap( ID_FI );
                Color baseColor = pStdMat->GetFilter( m_time );
                if( pStdMat->MapEnabled( ID_FI ) && pMap ) {
                    Color texColor = pMap->EvalColor( *pSC );
                    float alpha = pStdMat->GetTexmapAmt( ID_FI, m_time );
                    m_filterColorAccessor.set(
                        particle, frantic::max3d::from_max_t( alpha * texColor + ( 1 - alpha ) * baseColor ) );
                } else {
                    m_filterColorAccessor.set( particle, frantic::max3d::from_max_t( baseColor ) );
                }
            }

            if( m_selfIllumAccessor.is_valid() ) {
                Texmap* pMap = pStdMat->GetSubTexmap( ID_SI );
                Color baseColor = pStdMat->GetSelfIllumColor( m_time );
                if( !pStdMat->GetSelfIllumColorOn() )
                    baseColor.r = baseColor.g = baseColor.b = pStdMat->GetSelfIllum( m_time );

                if( pStdMat->MapEnabled( ID_SI ) && pMap ) {
                    Color texColor = pMap->EvalColor( *pSC );
                    float alpha = pStdMat->GetTexmapAmt( ID_SI, m_time );
                    m_selfIllumAccessor.set(
                        particle, frantic::max3d::from_max_t( alpha * texColor + ( 1 - alpha ) * baseColor ) );
                } else {
                    m_selfIllumAccessor.set( particle, frantic::max3d::from_max_t( baseColor ) );
                }
            }

            if( m_densityAccessor.is_valid() ) {
                Texmap* pMap = pStdMat->GetSubTexmap( ID_OP );
                float baseOpacity = pStdMat->GetOpacity( m_time );
                if( pStdMat->MapEnabled( ID_OP ) && pMap ) {
                    float texOpacity = pMap->EvalMono( *pSC );
                    float alpha = pStdMat->GetTexmapAmt( ID_OP, m_time );
                    float opacity = alpha * texOpacity + ( 1 - alpha ) * baseOpacity;
                    if( opacity != 1.f )
                        m_densityAccessor.set( particle, m_densityAccessor.get( particle ) * opacity );
                } else {
                    if( baseOpacity != 1.f )
                        m_densityAccessor.set( particle, m_densityAccessor.get( particle ) * baseOpacity );
                }
            }

            Shader* pShader = pStdMat->GetShader();
            if( m_specLevelAccessor.is_valid() ) {
                long ch = pShader->StdIDToChannel( ID_SS );

                float baseLevel = pShader->GetSpecularLevel( m_time );
                if( ch >= 0 ) {
                    Texmap* pMap = pStdMat->GetSubTexmap( ch );
                    if( pStdMat->MapEnabled( ch ) && pMap ) {
                        float texLevel = pMap->EvalMono( *pSC );
                        float alpha = pStdMat->GetTexmapAmt( ch, m_time );
                        m_specLevelAccessor.set( particle, baseLevel + alpha * ( texLevel - baseLevel ) );
                    } else {
                        m_specLevelAccessor.set( particle, baseLevel );
                    }
                } else {
                    m_specLevelAccessor.set( particle, baseLevel );
                }
            }

            if( m_specPowerAccessor.is_valid() ) {
                long ch = pShader->StdIDToChannel( ID_SH );

                float basePower = pShader->GetGlossiness( m_time ) * 100.f;
                if( ch >= 0 ) {
                    Texmap* pMap = pStdMat->GetSubTexmap( ch );
                    if( pStdMat->MapEnabled( ch ) && pMap ) {
                        float texPower = pMap->EvalMono( *pSC ) * 100.f;
                        float alpha = pStdMat->GetTexmapAmt( ch, m_time );
                        m_specPowerAccessor.set( particle, basePower + alpha * ( texPower - basePower ) );
                    } else {
                        m_specPowerAccessor.set( particle, basePower );
                    }
                } else {
                    m_specPowerAccessor.set( particle, basePower );
                }
            }
        } else {
            m_pMtl->Shade( *pSC );
            if( m_colorAccessor.is_valid() ) {
                color3f c( pSC->out.t.r != 1.f ? pSC->out.c.r / ( 1.f - pSC->out.t.r ) : 0.f,
                           pSC->out.t.g != 1.f ? pSC->out.c.g / ( 1.f - pSC->out.t.g ) : 0.f,
                           pSC->out.t.b != 1.f ? pSC->out.c.b / ( 1.f - pSC->out.t.b ) : 0.f );
                m_colorAccessor.set( particle, c );
            }
            if( m_densityAccessor.is_valid() ) {
                float f = ( 3.f - pSC->out.t.r - pSC->out.t.g - pSC->out.t.b ) / 3.f;
                m_densityAccessor.set( particle, m_densityAccessor.get( particle ) * f );
            }
        }
    }
};

MaxKrakatoaStdMaterialIStream::MaxKrakatoaStdMaterialIStream( boost::shared_ptr<particle_istream> pDelegate, Mtl* pMtl,
                                                              const renderInformation& renderInfo, bool doShadeColor,
                                                              bool doShadeAbsorption, bool doShadeEmission,
                                                              bool doShadeDensity, TimeValue t )
    : delegated_particle_istream( pDelegate )
    , m_pData( NULL )
    , m_pMtl( pMtl )
    , m_renderInfo( renderInfo )
    , m_time( t ) {
    m_doShadeColor = doShadeColor;
    m_doShadeAbsorption = doShadeAbsorption;
    m_doShadeEmission = doShadeEmission;
    m_doShadeDensity = doShadeDensity;

    m_nativePcm = pDelegate->get_native_channel_map();
    if( !m_nativePcm.has_channel( _T("Color") ) )
        m_nativePcm.append_channel<vector3f>( _T("Color") );

    set_channel_map( m_delegate->get_channel_map() );
}

MaxKrakatoaStdMaterialIStream::~MaxKrakatoaStdMaterialIStream() {
    delete m_pData;
    m_pData = NULL;
}

void MaxKrakatoaStdMaterialIStream::set_channel_map( const frantic::channels::channel_map& pcm ) {
    m_outPcm = pcm;

    // IMPORTANT! This ptr must be set to NULL after deletion in case the call to
    //   new MaxKrakatoaStdMaterialIStreamData() throws an exception. In that case
    //   the destructor will see the old (already deleted) address in m_pData and
    //   cause a double deletion.
    delete m_pData;
    m_pData = NULL;

    m_pData =
        new MaxKrakatoaStdMaterialIStreamData( m_pMtl, m_renderInfo, m_outPcm, m_doShadeColor, m_doShadeAbsorption,
                                               m_doShadeEmission, m_doShadeDensity, m_delegate, m_time );
    m_adaptor.set( m_outPcm, m_delegate->get_channel_map() );
}

void MaxKrakatoaStdMaterialIStream::set_default_particle( char* buffer ) {
    if( m_adaptor.is_identity() ) {
        m_delegate->set_default_particle( buffer );
    } else {
        frantic::channels::channel_map_adaptor tempAdaptor( m_delegate->get_channel_map(), m_outPcm );

        char* tempBuffer = (char*)_alloca( tempAdaptor.dest_size() );
        memset( tempBuffer, 0, tempAdaptor.dest_size() );

        tempAdaptor.copy_structure( tempBuffer, buffer );
        m_delegate->set_default_particle( tempBuffer );
    }
}

bool MaxKrakatoaStdMaterialIStream::get_particle( char* outBuffer ) {
    if( m_adaptor.is_identity() ) {
        if( !m_delegate->get_particle( outBuffer ) )
            return false;
        m_pData->shade_particle( outBuffer );
    } else {
        char* tempBuffer = (char*)_alloca( m_adaptor.source_size() );
        if( !m_delegate->get_particle( tempBuffer ) )
            return false;
        m_pData->shade_particle( tempBuffer );
        m_adaptor.copy_structure( outBuffer, tempBuffer );
    }
    return true;
}

class parallel_shade_proc {
    const MaxKrakatoaStdMaterialIStreamData* m_pData;

  public:
    typedef frantic::particles::particle_array_iterator range_iterator;
    typedef tbb::blocked_range<range_iterator> range_type;

  public:
    parallel_shade_proc( const MaxKrakatoaStdMaterialIStreamData& data ) { m_pData = &data; }

    void operator()( const range_type& r ) const {
        for( range_iterator it = r.begin(); it != r.end(); ++it )
            m_pData->shade_particle( *it );
    }
};

bool MaxKrakatoaStdMaterialIStream::get_particles( char* outBuffer, std::size_t& numParticles ) {
    bool result;
    if( m_adaptor.is_identity() ) {
        result = m_delegate->get_particles( outBuffer, numParticles );
        parallel_shade_proc::range_iterator itBegin( outBuffer, m_adaptor.dest_size() );
        parallel_shade_proc::range_iterator itEnd = itBegin + numParticles;

#ifndef FRANTIC_DISABLE_THREADS
        tbb::parallel_for( parallel_shade_proc::range_type( itBegin, itEnd ), parallel_shade_proc( *m_pData ) );
#else
#pragma message( "Threads are disabled" )
        parallel_shade_proc func( *m_pData );
        func( parallel_shade_proc::range_type( itBegin, itEnd ) );
#endif
    } else {
        boost::scoped_array<char> tempBuffer( new char[m_adaptor.source_size() * numParticles] );
        result = m_delegate->get_particles( tempBuffer.get(), numParticles );
        parallel_shade_proc::range_iterator itBegin( tempBuffer.get(), m_adaptor.source_size() );
        parallel_shade_proc::range_iterator itEnd = itBegin + numParticles;

#ifndef FRANTIC_DISABLE_THREADS
        tbb::parallel_for( parallel_shade_proc::range_type( itBegin, itEnd, 2000 ), parallel_shade_proc( *m_pData ) );
#else
#pragma message( "Threads are disabled" )
        parallel_shade_proc func( *m_pData );
        func( parallel_shade_proc::range_type( itBegin, itEnd, 2000 ) );
#endif

        for( std::size_t i = 0; i < numParticles; ++i )
            m_adaptor.copy_structure( outBuffer + i * m_adaptor.dest_size(),
                                      tempBuffer.get() + i * m_adaptor.source_size() );
    }

    return result;
}