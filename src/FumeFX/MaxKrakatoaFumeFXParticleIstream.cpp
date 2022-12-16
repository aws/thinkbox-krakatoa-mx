// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0
/**
 * TODO: Combine this with the Stoke implementation and refactor into the FranticMaxLibrary.
 */

#include "resource.h"
#include "stdafx.h"

#if defined( FUMEFX_SDK_AVAILABLE )

#include "FumeFX\MaxKrakatoaFumeFXParticleIStream.h"

class shdParams_Standard;
class vfShader;
class vfLightSampler;
class vfMapSampler;

#include <fumefxio/VoxelFlowBase.h>

#include <frantic/channels/channel_map_adaptor.hpp>
#include <frantic/math/splines/bezier_spline.hpp>
#include <frantic/particles/streams/apply_function_particle_istream.hpp>
#include <frantic/particles/streams/empty_particle_istream.hpp>
#include <frantic/particles/streams/particle_istream.hpp>

#include <MaxKrakatoa.h>
#include <frantic/max3d/geopipe/get_inodes.hpp>
#include <frantic/max3d/maxscript/maxscript.hpp>
#include <frantic/max3d/standard_max_includes.hpp>

#include <maxversion.h>

// From <frantic/volumetrics/levelset/rle_trilerp.hpp>
namespace frantic {
namespace volumetrics {
namespace levelset {
extern void get_trilerp_weights( const float* deltas, float* outWeights );
}
} // namespace volumetrics
} // namespace frantic

using frantic::graphics::vector3f;
using frantic::particles::streams::particle_istream;

/**
 * End of function pointer, DLL hackery
 */

namespace {
void init_native_map( frantic::channels::channel_map& outMap, const SimulationHeader& vfb ) {
    outMap.reset();
    outMap.define_channel<vector3f>( _T("Position") );

    if( vfb.loadedOutputVars & SIM_USEDENS ) {
        outMap.define_channel<float>( _T("Density") );
        outMap.define_channel<vector3f>( _T("DensityGradient") );
    }
    if( vfb.loadedOutputVars & SIM_USEVEL ) {
        outMap.define_channel<vector3f>( _T("Velocity") );
        outMap.define_channel<vector3f>( _T("Vorticity") );
    }
    if( vfb.loadedOutputVars & SIM_USETEXT )
        outMap.define_channel<vector3f>( _T("TextureCoord") );
    if( vfb.loadedOutputVars & SIM_USECOLOR )
        outMap.define_channel<vector3f>( _T("Color") );
    if( vfb.loadedOutputVars & SIM_USETEMP )
        outMap.define_channel<float>( _T("Temperature") );
    if( vfb.loadedOutputVars & SIM_USEFUEL ) {
        outMap.define_channel<float>( _T("Fuel") );
        outMap.define_channel<float>( _T("Fire") );
    }

    outMap.end_channel_definition();
}
} // namespace

class fumefx_particle_istream : public particle_istream {
    VoxelFlowBase* m_pFumeData;
    SimulationHeader m_simHeader;

    frantic::tstring m_streamName;
    frantic::tstring m_fumePath;

    int m_disabledChannels;

    boost::int64_t m_particleIndex;
    boost::int64_t m_progressIndex;
    boost::int64_t m_progressCount;
    boost::scoped_array<char> m_defaultParticle;

    frantic::channels::channel_map m_outMap;
    frantic::channels::channel_map m_nativeMap;

    frantic::volumetrics::voxel_sampler_interface_ptr m_pSampleGen;

    // Scale the values of density and fire to counteract the increase in particles from
    // subdivision and voxel spacing.
    float m_spacingFactor;

    frantic::channels::channel_accessor<vector3f> m_posAccessor;
    frantic::channels::channel_cvt_accessor<vector3f> m_velocityAccessor;
    frantic::channels::channel_cvt_accessor<vector3f> m_vorticityAccessor;
    frantic::channels::channel_cvt_accessor<vector3f> m_texCoordAccessor;
    frantic::channels::channel_cvt_accessor<vector3f> m_colorAccessor;
    frantic::channels::channel_cvt_accessor<vector3f> m_densityGradAccessor;
    frantic::channels::channel_cvt_accessor<float> m_densityAccessor;
    frantic::channels::channel_cvt_accessor<float> m_temperatureAccessor;
    frantic::channels::channel_cvt_accessor<float> m_fireAccessor;
    frantic::channels::channel_cvt_accessor<float> m_fuelAccessor;

    bool m_seedDensity;
    float m_minDensity;

    bool m_seedFire;
    float m_minFire;

    frantic::graphics::vector3 m_currentVoxel;

    // Cached values for the 2x2x2 box with min() == 'm_currentVoxel'
    int m_cachedChannels;
    float m_cachedDensity[8];
    float m_cachedFuel[8];
    float m_cachedTemp[8];
    frantic::graphics::vector3f m_cachedVelocity[8];
    frantic::graphics::vector3f m_cachedTextureCoord[8];
    frantic::graphics::vector3f m_cachedColor[8];

    inline void cache_voxel_value( int cacheItem, int voxelIndex ) {
        if( m_cachedChannels & SIM_USEDENS )
            m_cachedDensity[cacheItem] = m_pFumeData->GetRo2( voxelIndex );
        if( m_cachedChannels & SIM_USEFUEL )
            m_cachedFuel[cacheItem] = m_pFumeData->GetFuel2( voxelIndex );
        if( m_cachedChannels & SIM_USETEMP )
            m_cachedTemp[cacheItem] = m_pFumeData->GetTemp2( voxelIndex );
        if( m_cachedChannels & SIM_USEVEL )
            m_pFumeData->GetVel2( voxelIndex, m_cachedVelocity[cacheItem].x, m_cachedVelocity[cacheItem].y,
                                  m_cachedVelocity[cacheItem].z );
        if( m_cachedChannels & SIM_USETEXT )
            m_pFumeData->GetXYZ2( voxelIndex, m_cachedTextureCoord[cacheItem].x, m_cachedTextureCoord[cacheItem].y,
                                  m_cachedTextureCoord[cacheItem].z );
        if( m_cachedChannels & SIM_USECOLOR ) {
            SDColor c;
            m_pFumeData->GetColor2( voxelIndex, c );

            m_cachedColor[cacheItem].x = c.r;
            m_cachedColor[cacheItem].y = c.g;
            m_cachedColor[cacheItem].z = c.b;
        }
    }

    inline void clear_voxel_value( int cacheItem ) {
        if( m_cachedChannels & SIM_USEDENS )
            m_cachedDensity[cacheItem] = 0.f;
        if( m_cachedChannels & SIM_USEFUEL )
            m_cachedFuel[cacheItem] = 0.f;
        if( m_cachedChannels & SIM_USETEMP )
            m_cachedTemp[cacheItem] = 0.f;
        if( m_cachedChannels & SIM_USEVEL )
            m_cachedVelocity[cacheItem].set( 0.f );
        if( m_cachedChannels & SIM_USETEXT )
            m_cachedTextureCoord[cacheItem].set( 0.f );
        if( m_cachedChannels & SIM_USECOLOR )
            m_cachedColor[cacheItem].set( 0.f );
    }

    inline void shift_cached_values() {
        for( int i = 0; i < 4; ++i )
            m_cachedDensity[i] = m_cachedDensity[i + 4];
        for( int i = 0; i < 4; ++i )
            m_cachedFuel[i] = m_cachedFuel[i + 4];
        for( int i = 0; i < 4; ++i )
            m_cachedTemp[i] = m_cachedTemp[i + 4];
        for( int i = 0; i < 4; ++i )
            m_cachedVelocity[i] = m_cachedVelocity[i + 4];
        for( int i = 0; i < 4; ++i )
            m_cachedTextureCoord[i] = m_cachedTextureCoord[i + 4];
        for( int i = 0; i < 4; ++i )
            m_cachedColor[i] = m_cachedColor[i + 4];
    }

    void cache_voxel_values() {
        static const int ROW_START = -1;
        if( m_currentVoxel.z > ROW_START ) {
            shift_cached_values();
        } else {
            for( int i = 0; i < 4; ++i )
                clear_voxel_value( i );
        }

        // Use something like this when we support filters that are larger.
        /*frantic::graphics::boundbox3 lookupBounds( m_currentVoxel.x, m_currentVoxel.x + 1, m_currentVoxel.y,
        m_currentVoxel.y + 1, m_currentVoxel.z, m_currentVoxel.z + 1 ); if( m_currentVoxel.x < 0 )
                ++lookupBounds.minimum().x;
        else if( m_currentVoxel.x > m_pFumeData->nx )
                --lookupBounds.maximum().x;

        if( m_currentVoxel.y < 0 )
                ++lookupBounds.minimum().y;
        else if( m_currentVoxel.y > m_pFumeData->ny )
                --lookupBounds.maximum().y;*/

        if( m_currentVoxel.z + 1 < m_pFumeData->nz ) {
            int voxelIndex =
                m_pFumeData->nyz * m_currentVoxel.x + m_pFumeData->nz * m_currentVoxel.y + m_currentVoxel.z + 1;
            if( (unsigned)m_currentVoxel.x < (unsigned)m_pFumeData->nx ) {
                if( (unsigned)m_currentVoxel.y < (unsigned)m_pFumeData->ny )
                    cache_voxel_value( 4, voxelIndex );
                else
                    clear_voxel_value( 4 );

                if( (unsigned)( m_currentVoxel.y + 1 ) < (unsigned)m_pFumeData->ny )
                    cache_voxel_value( 6, voxelIndex + m_pFumeData->nz );
                else
                    clear_voxel_value( 6 );
            } else {
                clear_voxel_value( 4 );
                clear_voxel_value( 6 );
            }

            if( (unsigned)( m_currentVoxel.x + 1 ) < (unsigned)m_pFumeData->nx ) {
                if( (unsigned)m_currentVoxel.y < (unsigned)m_pFumeData->ny )
                    cache_voxel_value( 5, voxelIndex + m_pFumeData->nyz );
                else
                    clear_voxel_value( 5 );

                if( (unsigned)( m_currentVoxel.y + 1 ) < (unsigned)m_pFumeData->ny )
                    cache_voxel_value( 7, voxelIndex + m_pFumeData->nyz + m_pFumeData->nz );
                else
                    clear_voxel_value( 7 );
            } else {
                clear_voxel_value( 5 );
                clear_voxel_value( 7 );
            }
        } else {
            for( int i = 4; i < 8; ++i )
                clear_voxel_value( i );
        }
    }

  private:
    void init() {
        m_seedDensity = ( m_minDensity != ( std::numeric_limits<float>::max )() );
        m_seedFire = ( m_minFire != ( std::numeric_limits<float>::max )() );

        init_native_map( m_nativeMap, m_simHeader );

        m_particleIndex = -1;
        m_progressIndex = -1;
        m_progressCount = ( m_pFumeData->nx + 1 ) * ( m_pFumeData->ny + 1 ) * ( m_pFumeData->nz + 1 );

        m_cachedChannels = 0;

        m_spacingFactor = ( m_pFumeData->dx * m_pFumeData->dx * m_pFumeData->dx );

        m_currentVoxel = frantic::graphics::vector3( -1, -1, -1 );
        m_pSampleGen->update_for_voxel(
            m_currentVoxel + frantic::graphics::vector3( m_pFumeData->nx0, m_pFumeData->ny0, m_pFumeData->nz0 ) );
    }

    /**
     * @fn load_voxels()
     * This will load the full FumeFX voxel field, based on the channels requested by the user.
     * This is done in a lazy manner, on the first call to get_particle() so that only the required
     * Fume channels will be loaded. This is helpful to minimize the memory footprint caused by
     * loading the entire velocity field for renders with no motion blur.
     */
    void load_voxels() {
        int requestedChannels = 0;
        if( !( m_disabledChannels & SIM_USEDENS ) &&
            ( m_outMap.has_channel( _T("Density") ) || m_outMap.has_channel( _T("DensityGradient") ) ||
              m_seedDensity ) )
            requestedChannels |= SIM_USEDENS;
        if( !( m_disabledChannels & SIM_USEVEL ) &&
            ( m_outMap.has_channel( _T("Velocity") ) || m_outMap.has_channel( _T("Vorticity") ) ) )
            requestedChannels |= SIM_USEVEL;
        if( !( m_disabledChannels & SIM_USETEXT ) && m_outMap.has_channel( _T("TextureCoord") ) )
            requestedChannels |= SIM_USETEXT;
        if( !( m_disabledChannels & SIM_USECOLOR ) && m_outMap.has_channel( _T("Color") ) )
            requestedChannels |= SIM_USECOLOR;
        if( !( m_disabledChannels & SIM_USETEMP ) && m_outMap.has_channel( _T("Temperature") ) )
            requestedChannels |= SIM_USETEMP;
        if( !( m_disabledChannels & SIM_USEFUEL ) &&
            ( m_outMap.has_channel( _T("Fuel") ) || m_outMap.has_channel( _T("Fire") ) || m_seedFire ) )
            requestedChannels |= SIM_USEFUEL;

        m_cachedChannels = requestedChannels;

        FumeFXSaveToFileData saveData;
        int loadResult = m_pFumeData->LoadOutput( m_fumePath.c_str(), saveData, requestedChannels, requestedChannels );
        if( loadResult != LOAD_OK )
            throw std::runtime_error(
                "fumefx_particle_istream::load_voxels() - Failed to load the FumeFX voxel data from:\n\n\t\"" +
                frantic::strings::to_string( m_fumePath ) + "\"" );

        m_cachedChannels &= m_simHeader.loadedOutputVars;
        if( m_cachedChannels != requestedChannels ) {
            std::basic_stringstream<frantic::tchar> ss;

            ss << _T("fumefx_particle_istream::load_voxels() - Failed to load some channels from .fxd file \"")
               << m_fumePath << _T("\"\n");
            if( ( requestedChannels & SIM_USEDENS ) && ( m_cachedChannels & SIM_USEDENS ) == 0 )
                ss << _T("\tDensity was not able to be loaded\n");
            if( ( requestedChannels & SIM_USEVEL ) && ( m_cachedChannels & SIM_USEVEL ) == 0 )
                ss << _T("\tVelocity was not able to be loaded\n");
            if( ( requestedChannels & SIM_USETEXT ) && ( m_cachedChannels & SIM_USETEXT ) == 0 )
                ss << _T("\tTextureCoord was not able to be loaded\n");
            if( ( requestedChannels & SIM_USECOLOR ) && ( m_cachedChannels & SIM_USECOLOR ) == 0 )
                ss << _T("\tColor was not able to be loaded\n");
            if( ( requestedChannels & SIM_USETEMP ) && ( m_cachedChannels & SIM_USETEMP ) == 0 )
                ss << _T("\tTemperature was not able to be loaded\n");
            if( ( requestedChannels & SIM_USEFUEL ) && ( m_cachedChannels & SIM_USEFUEL ) == 0 )
                ss << _T("\tFuel was not able to be loaded\n");

            FF_LOG( warning ) << ss.str() << std::endl;
        }

        // Hook up the data channels now.
        if( ( m_simHeader.loadedOutputVars & SIM_USEVEL ) && ( requestedChannels & SIM_USEVEL ) ) {
            if( m_outMap.has_channel( _T("Velocity") ) )
                m_velocityAccessor = m_outMap.get_cvt_accessor<vector3f>( _T("Velocity") );
            if( m_outMap.has_channel( _T("Vorticity") ) )
                m_vorticityAccessor = m_outMap.get_cvt_accessor<vector3f>( _T("Vorticity") );
        }

        if( ( m_simHeader.loadedOutputVars & SIM_USETEXT ) && ( requestedChannels & SIM_USETEXT ) )
            m_texCoordAccessor = m_outMap.get_cvt_accessor<vector3f>( _T("TextureCoord") );

        if( ( m_simHeader.loadedOutputVars & SIM_USECOLOR ) && ( requestedChannels & SIM_USECOLOR ) )
            m_colorAccessor = m_outMap.get_cvt_accessor<vector3f>( _T("Color") );

        if( ( m_simHeader.loadedOutputVars & SIM_USETEMP ) && ( requestedChannels & SIM_USETEMP ) )
            m_temperatureAccessor = m_outMap.get_cvt_accessor<float>( _T("Temperature") );

        if( ( m_simHeader.loadedOutputVars & SIM_USEFUEL ) && ( requestedChannels & SIM_USEFUEL ) ) {
            if( m_outMap.has_channel( _T("Fuel") ) )
                m_fuelAccessor = m_outMap.get_cvt_accessor<float>( _T("Fuel") );
            if( m_outMap.has_channel( _T("Fire") ) )
                m_fireAccessor = m_outMap.get_cvt_accessor<float>( _T("Fire") );
        }

        // Initialize the first voxel's values.
        memset( m_cachedDensity, 0, sizeof( float ) * 8 );
        memset( m_cachedFuel, 0, sizeof( float ) * 8 );
        for( int i = 0; i < 7; ++i )
            clear_voxel_value( i );
        cache_voxel_value( 7, 0 );
    }

    bool advance_iterator() {
        if( ++m_currentVoxel.z >= m_pFumeData->nz ) {
            if( ++m_currentVoxel.y >= m_pFumeData->ny ) {
                if( ++m_currentVoxel.x >= m_pFumeData->nx )
                    return false;
                m_currentVoxel.y = -1;
            }
            m_currentVoxel.z = -1;
        }

        m_pSampleGen->update_for_voxel(
            m_currentVoxel + frantic::graphics::vector3( m_pFumeData->nx0, m_pFumeData->ny0, m_pFumeData->nz0 ) );
        return true;
    }

  public:
    fumefx_particle_istream( VoxelFlowBase* pFumeData, const frantic::tstring& path, int disabledChannels,
                             frantic::volumetrics::voxel_sampler_interface_ptr pSampleGen,
                             const frantic::channels::channel_map& pcm, const SimulationHeader& simHeader,
                             const frantic::tstring& name = _T(""), float minDensity = 0.f, float minFire = 0.f )
        : m_pFumeData( pFumeData )
        , m_fumePath( path )
        , m_streamName( name )
        , m_disabledChannels( disabledChannels )
        , m_minDensity( minDensity )
        , m_minFire( minFire )
        , m_pSampleGen( pSampleGen )
        , m_simHeader( simHeader ) {
        init();
        set_channel_map( pcm );
    }

    virtual ~fumefx_particle_istream() { close(); }

    virtual void close() {
        if( m_pFumeData )
            ::DeleteVoxelFlow( m_pFumeData );
        m_pFumeData = NULL;
    }

    virtual frantic::tstring name() const { return m_streamName; }
    virtual std::size_t particle_size() const { return m_outMap.structure_size(); }

    virtual boost::int64_t particle_count() const { return -1; }
    virtual boost::int64_t particle_index() const { return m_particleIndex; }
    virtual boost::int64_t particle_count_left() const { return -1; }

    virtual boost::int64_t particle_progress_count() const { return m_progressCount; }
    virtual boost::int64_t particle_progress_index() const { return m_progressIndex; }

    virtual const frantic::channels::channel_map& get_channel_map() const { return m_outMap; }
    virtual const frantic::channels::channel_map& get_native_channel_map() const { return m_nativeMap; }

    virtual void set_channel_map( const frantic::channels::channel_map& particleChannelMap ) {
        boost::scoped_array<char> newDefaultParticle( new char[particleChannelMap.structure_size()] );

        if( m_defaultParticle ) {
            frantic::channels::channel_map_adaptor tempAdaptor( particleChannelMap, m_outMap );
            tempAdaptor.copy_structure( newDefaultParticle.get(), m_defaultParticle.get() );
        } else
            memset( newDefaultParticle.get(), 0, particleChannelMap.structure_size() );

        m_outMap = particleChannelMap;
        m_defaultParticle.swap( newDefaultParticle );

        m_fuelAccessor.reset();
        m_fireAccessor.reset();
        m_velocityAccessor.reset();
        m_vorticityAccessor.reset();
        m_texCoordAccessor.reset();
        m_colorAccessor.reset();
        m_densityGradAccessor.reset();
        m_temperatureAccessor.reset();

        m_posAccessor = m_outMap.get_accessor<vector3f>( _T("Position") );

        // Even if the Smoke channel isn't present we need to assign a zero density.
        if( m_outMap.has_channel( _T("Density") ) )
            m_densityAccessor = m_outMap.get_cvt_accessor<float>( _T("Density") );
        if( m_outMap.has_channel( _T("DensityGradient") ) )
            m_densityGradAccessor = m_outMap.get_cvt_accessor<vector3f>( _T("DensityGradient") );
    }

    virtual void set_default_particle( char* rawParticleBuffer ) {
        m_defaultParticle.reset( new char[m_outMap.structure_size()] );
        m_outMap.copy_structure( m_defaultParticle.get(), rawParticleBuffer );
    }

    virtual bool get_particle( char* rawParticleBuffer ) {
        if( !m_pFumeData )
            return false;

        if( m_particleIndex < 0 )
            load_voxels();

        float fuel;
        float density;
        float weights[8];

        float compensationFactor;
        frantic::graphics::vector3f samplePos;

        do {
            if( !m_pSampleGen->get_next_position( samplePos, compensationFactor ) ) {
                do {
                    if( !advance_iterator() )
                        return false;
                    ++m_progressIndex;
                } while( !m_pSampleGen->get_next_position( samplePos, compensationFactor ) );

                cache_voxel_values();
            }

            frantic::volumetrics::levelset::get_trilerp_weights( &samplePos.x, weights );

            density = weights[0] * m_cachedDensity[0] + weights[1] * m_cachedDensity[1] +
                      weights[2] * m_cachedDensity[2] + weights[3] * m_cachedDensity[3] +
                      weights[4] * m_cachedDensity[4] + weights[5] * m_cachedDensity[5] +
                      weights[6] * m_cachedDensity[6] + weights[7] * m_cachedDensity[7];

            fuel = weights[0] * m_cachedFuel[0] + weights[1] * m_cachedFuel[1] + weights[2] * m_cachedFuel[2] +
                   weights[3] * m_cachedFuel[3] + weights[4] * m_cachedFuel[4] + weights[5] * m_cachedFuel[5] +
                   weights[6] * m_cachedFuel[6] + weights[7] * m_cachedFuel[7];
        } while( density <= m_minDensity && fuel <= m_minFire );

        compensationFactor *= m_spacingFactor;

        ++m_particleIndex;

        // Copy the default values into the particle
        m_outMap.copy_structure( rawParticleBuffer, m_defaultParticle.get() );

        m_posAccessor( rawParticleBuffer )
            .set( ( m_pFumeData->nx0 + m_currentVoxel.x + samplePos.x ) * m_pFumeData->dx - m_pFumeData->midx,
                  ( m_pFumeData->ny0 + m_currentVoxel.y + samplePos.y ) * m_pFumeData->dx - m_pFumeData->midy,
                  ( m_pFumeData->nz0 + m_currentVoxel.z + samplePos.z ) * m_pFumeData->dx );

        if( m_densityAccessor.is_valid() )
            m_densityAccessor.set( rawParticleBuffer, density * compensationFactor );

        if( m_fuelAccessor.is_valid() && fuel < 0 )
            m_fuelAccessor.set( rawParticleBuffer, -fuel ); // Fuel is negative valued fuel voxel values.

        if( m_fireAccessor.is_valid() && fuel > 0 )
            m_fireAccessor.set( rawParticleBuffer, fuel ); // Fire is positive valued fuel voxel values.

        if( m_temperatureAccessor.is_valid() ) {
            float temp = weights[0] * m_cachedTemp[0] + weights[1] * m_cachedTemp[1] + weights[2] * m_cachedTemp[2] +
                         weights[3] * m_cachedTemp[3] + weights[4] * m_cachedTemp[4] + weights[5] * m_cachedTemp[5] +
                         weights[6] * m_cachedTemp[6] + weights[7] * m_cachedTemp[7];

            m_temperatureAccessor.set( rawParticleBuffer, temp );
        }

        if( m_velocityAccessor.is_valid() ) {
            frantic::graphics::vector3f v( 0.f );
            v += weights[0] * m_cachedVelocity[0];
            v += weights[1] * m_cachedVelocity[1];
            v += weights[2] * m_cachedVelocity[2];
            v += weights[3] * m_cachedVelocity[3];
            v += weights[4] * m_cachedVelocity[4];
            v += weights[5] * m_cachedVelocity[5];
            v += weights[6] * m_cachedVelocity[6];
            v += weights[7] * m_cachedVelocity[7];

            v *= static_cast<float>( GetFrameRate() );
            m_velocityAccessor.set( rawParticleBuffer, v );
        }

        if( m_texCoordAccessor.is_valid() ) {
            frantic::graphics::vector3f tc( 0.f );
            tc += weights[0] * m_cachedTextureCoord[0];
            tc += weights[1] * m_cachedTextureCoord[1];
            tc += weights[2] * m_cachedTextureCoord[2];
            tc += weights[3] * m_cachedTextureCoord[3];
            tc += weights[4] * m_cachedTextureCoord[4];
            tc += weights[5] * m_cachedTextureCoord[5];
            tc += weights[6] * m_cachedTextureCoord[6];
            tc += weights[7] * m_cachedTextureCoord[7];

            m_texCoordAccessor.set( rawParticleBuffer, tc );
        }

        if( m_colorAccessor.is_valid() ) {
            frantic::graphics::vector3f tc( 0.f );
            tc += weights[0] * m_cachedColor[0];
            tc += weights[1] * m_cachedColor[1];
            tc += weights[2] * m_cachedColor[2];
            tc += weights[3] * m_cachedColor[3];
            tc += weights[4] * m_cachedColor[4];
            tc += weights[5] * m_cachedColor[5];
            tc += weights[6] * m_cachedColor[6];
            tc += weights[7] * m_cachedColor[7];

            m_colorAccessor.set( rawParticleBuffer, tc );
        }

        if( m_densityGradAccessor.is_valid() ) {
            frantic::graphics::vector3f grad =
                frantic::graphics::trilerp_gradient( &samplePos.x, m_cachedDensity, m_pFumeData->dx );
            m_densityGradAccessor.set( rawParticleBuffer, grad );
        }

        if( m_vorticityAccessor.is_valid() ) {
            frantic::graphics::vector3f vort =
                frantic::graphics::trilerp_curl( &samplePos.x, m_cachedVelocity, m_pFumeData->dx );
            m_vorticityAccessor.set( rawParticleBuffer, vort );
        }

        return true;
    }

    virtual bool get_particles( char* rawParticleBuffer, std::size_t& numParticles ) {
        for( std::size_t i = 0; i < numParticles; ++i, rawParticleBuffer += m_outMap.structure_size() ) {
            if( !get_particle( rawParticleBuffer ) ) {
                numParticles = i;
                return false;
            }
        }
        return true;
    }
};

#define FUME_FX_SHADER_CLASS_ID Class_ID( 1159425859, 687288261 )

/**
 * @fn get_fume_fx_particle_istream
 * This function will create and return a particle_istream that places particles in the voxels
 * of a FumeFX voxel field.
 *
 * @note This is a separate function instead of exposing the stream's constructor so that it makes
 * dependencies on the FumeFX SDK optional. Additionally this function will lazily load the FumeFX
 * DLL in order to gracefully handle installations without FumeFX.
 *
 * @param pNode A ptr to the INode that is the FumeFX simulation object in the scene.
 * @param t The time at which to get the voxel field.
 * @param pcm The channel map to apply to the particle stream.
 * @return A shared_ptr to a fumefx_particle_istream.
 */
boost::shared_ptr<particle_istream>
get_fume_fx_particle_istream( INode* pNode, TimeValue t, const frantic::channels::channel_map& pcm,
                              frantic::volumetrics::voxel_sampler_interface_ptr pSampleGen, int disabledChannels,
                              float minDensity, float minFire ) {
    int frameOffset =
        frantic::max3d::mxs::expression( _T("fumeNode.Offset") ).bind( _T("fumeNode"), pNode ).evaluate<int>();
    int startFrame =
        frantic::max3d::mxs::expression( _T("fumeNode.playFrom") ).bind( _T("fumeNode"), pNode ).evaluate<int>();
    int endFrame =
        frantic::max3d::mxs::expression( _T("fumeNode.playTo") ).bind( _T("fumeNode"), pNode ).evaluate<int>();

    frantic::tstring simPath;
    static const frantic::tchar* CACHE_TYPES[] = { _T("default"), _T("wavelet"), _T("retimer"), _T("preview") };

    int cacheType =
        frantic::max3d::mxs::expression( _T("fumeNode.selectedCache") ).bind( _T("fumeNode"), pNode ).evaluate<int>();

    if( cacheType < 0 || cacheType > 2 )
        throw std::runtime_error( "Unexpected FumeFX cache type: " + boost::lexical_cast<std::string>( cacheType ) +
                                  " for node " + frantic::strings::to_string( pNode->GetName() ) );

    simPath = frantic::max3d::mxs::expression( _T("fumeNode.GetPath \"") +
                                               frantic::strings::tstring( CACHE_TYPES[cacheType] ) + _T("\"") )
                  .bind( _T("fumeNode"), pNode )
                  .evaluate<frantic::tstring>();

    // The frameOffset changes the apparent Max frame time.
    // The startFrame is the first frame to load when the maxTime is 'frameOffset'
    // The endFrame is the last frame to load when maxTime is 'frameOffset' + endFrame - startFrame
    int curFrame = t / GetTicksPerFrame();
    if( curFrame < frameOffset )
        return boost::shared_ptr<particle_istream>(
            new frantic::particles::streams::empty_particle_istream( pcm, get_fumefx_native_map( pNode ) ) );

    curFrame = ( curFrame - frameOffset ) + startFrame;
    if( curFrame > endFrame )
        return boost::shared_ptr<particle_istream>(
            new frantic::particles::streams::empty_particle_istream( pcm, get_fumefx_native_map( pNode ) ) );

    TCHAR outPath[MAX_PATH];
    VoxelFlowBase* pFumeData = NULL;
    SimulationHeader simHeader;
    try {
        pFumeData = ::CreateVoxelFlow();

        memset( outPath, 0, MAX_PATH );
        ::vfMakeOutputName( outPath, (TCHAR*)simPath.c_str(), curFrame, -1 );

        int loadResult = pFumeData->LoadHeader( outPath, simHeader );
        const int oldOutputVars = simHeader.loadedOutputVars;
        if( loadResult != LOAD_OK ) {
            if( loadResult == LOAD_USERCANCEL )
                throw std::runtime_error( "get_fume_fx_particle_istream() - User cancelled during load" );
            if( loadResult == LOAD_FILEOPENERROR )
                throw std::runtime_error( "get_fume_fx_particle_istream() - Error opening file \"" +
                                          frantic::strings::to_string( outPath ) + "\"" );
            if( loadResult == LOAD_FILELOADERROR )
                throw std::runtime_error( "get_fume_fx_particle_istream() - Error loading from file \"" +
                                          frantic::strings::to_string( outPath ) + "\"" );

            // This one always seems to come back. My guess is that LoadHeader doesn't actually use these return codes,
            // and just returns FALSE when there is an error.
            if( loadResult == LOAD_RAMERR )
                throw std::runtime_error( "get_fume_fx_particle_istream() - Error during load of file \"" +
                                          frantic::strings::to_string( outPath ) +
                                          "\". Check if this file actually exists (or adjust the Start/End Frame in "
                                          "the FumeFX UI to indicate the valid range)." );
        }

        if( !( simHeader.loadedOutputVars & SIM_USEDENS ) && !( simHeader.loadedOutputVars & SIM_USEFUEL ) ) {
            frantic::channels::channel_map nativeMap;
            init_native_map( nativeMap, simHeader );

            return boost::shared_ptr<particle_istream>(
                new frantic::particles::streams::empty_particle_istream( pcm, nativeMap ) );
        }
        // throw std::runtime_error( "get_fume_fx_particle_istream() - The file \"" + std::string(outPath) + "\" did not
        // have the requisite seeding channels (ie. Smoke and/or Fuel)." );

        FF_LOG( debug ) << _T("Got fume sim w/ name \"") << pNode->GetName() << _T("\"\n")
                        << _T("Loaded file \"") << outPath << _T("\"\n")
                        << _T("Voxel size: ") << simHeader.dx << _T("\n")
                        << _T("Got voxel dimensions [") << simHeader.nx << _T(",") << simHeader.ny << _T(",")
                        << simHeader.nz << _T("]\n")
                        << _T("loadedOutputVars: ") << std::hex << oldOutputVars << std::dec << std::endl;

    } catch( ... ) {
        ::DeleteVoxelFlow( pFumeData );
        throw;
    }

    // Translate from the enum used in our headers to the ones used by FumeFX
    int realDisabledChannels = 0;
    if( disabledChannels & fume_velocity_channel )
        realDisabledChannels |= SIM_USEVEL;

    // return boost::shared_ptr<particle_istream>( new fumefx_particle_istream(pFumeData, outPath, disabledChannels,
    // pcm, pNode->GetName()) );
    return boost::shared_ptr<particle_istream>( new fumefx_particle_istream(
        pFumeData, outPath, realDisabledChannels, pSampleGen, pcm, simHeader, pNode->GetName(), minDensity, minFire ) );
}
#endif
