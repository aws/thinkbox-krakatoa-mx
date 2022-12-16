// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0
#include "stdafx.h"

#if defined( PHOENIX_SDK_AVAILABLE )
#include <Phoenix/MaxKrakatoaPhoenixParticleIstream.hpp>

#include <Phoenix/MaxKrakatoaPhoenixObject.hpp>

#include <frantic/channels/channel_map_adaptor.hpp>
#include <frantic/graphics/quat4f.hpp>
#include <frantic/graphics/vector3.hpp>
#include <frantic/particles/streams/concatenated_particle_istream.hpp>
#include <frantic/particles/streams/particle_istream.hpp>
#include <frantic/volumetrics/levelset/rle_trilerp.hpp>

#include <frantic/max3d/convert.hpp>

#include <boost/optional.hpp>

#include <max3d/inode.h>
#include <max3d/object.h>
#include <max3d/units.h>
#include <phoenixfd/aurinterface.h>
#include <phoenixfd/phxcontent.h>

using namespace frantic::graphics;
using frantic::particles::streams::particle_istream;

namespace {
template <typename T>
inline T trilerp( T values[], float weights[8] ) {
    return weights[0] * values[0] + weights[1] * values[1] + weights[2] * values[2] + weights[3] * values[3] +
           weights[4] * values[4] + weights[5] * values[5] + weights[6] * values[6] + weights[7] * values[7];
}

inline transform4f get_object_to_grid_transform( IAur* aur ) {
    float objToGridTM[12];
    aur->GetObject2GridTransform( objToGridTM );
    return transform4f( vector3f( objToGridTM[0], objToGridTM[1], objToGridTM[2] ),
                        vector3f( objToGridTM[3], objToGridTM[4], objToGridTM[5] ),
                        vector3f( objToGridTM[6], objToGridTM[7], objToGridTM[8] ),
                        vector3f( objToGridTM[9], objToGridTM[10], objToGridTM[11] ) );
}

const std::string g_phoenixGridChannelNames[] = {
    "", "Temperature", "Smoke", "Speed", "VelocityX", "VelocityY", "VelocityZ", "U", "V", "W", "Fuel" };

inline float get_grid_value( IAur* aur, int channel, int voxelIndex, const frantic::strings::tstring& streamName ) {
    if( aur->ChannelPresent( channel ) ) {
        if( auto expanded = aur->ExpandChannel( channel ) ) {
            return expanded[voxelIndex];
        } else {
            const auto arraySize = sizeof( g_phoenixGridChannelNames ) / sizeof( g_phoenixGridChannelNames[0] );
            const auto name = frantic::strings::to_string( streamName );
            if( channel <= 0 || channel >= arraySize ) {
                throw std::runtime_error( "An unknown Phoenix FD channel with the value " +
                                          boost::lexical_cast<std::string>( channel ) + " was present in " + name +
                                          " but could not be decompressed." );
            } else {
                throw std::runtime_error( "The Phoenix FD channel " + g_phoenixGridChannelNames[channel] +
                                          " was present in " + name + " but could not be decompressed." );
            }
        }
    }
    return 0.f;
}
} // namespace

class MaxKrakatoaPhoenixParticleIstream : public frantic::particles::streams::particle_istream {
    boost::int64_t m_particleCount, m_particleIndex;

    frantic::channels::channel_map m_outMap, m_nativeMap;
    frantic::graphics::transform4f m_gridTM;

    boost::scoped_array<char> m_defaultParticle;

    IPhoenixFDPrtGroup* m_particles;

    struct {
        frantic::channels::channel_accessor<vector3f> pos;
        frantic::channels::channel_cvt_accessor<vector3f> vel;
        frantic::channels::channel_cvt_accessor<vector3f> texturecoord;
        frantic::channels::channel_cvt_accessor<vector3f> color;
        frantic::channels::channel_cvt_accessor<quat4f> orientation;
        frantic::channels::channel_cvt_accessor<float> size;
        frantic::channels::channel_cvt_accessor<float> age;
        frantic::channels::channel_cvt_accessor<float> density;
        frantic::channels::channel_cvt_accessor<float> temp;
        frantic::channels::channel_cvt_accessor<float> fuel;
    } m_accessors;

    inline void init_accessors();

  public:
    MaxKrakatoaPhoenixParticleIstream( IPhoenixFDPrtGroup* particles, const frantic::graphics::transform4f& toWorldTM,
                                       const frantic::channels::channel_map& pcm );

    // Virtual destructor so that we can use allocated pointers (generally with boost::shared_ptr)
    virtual ~MaxKrakatoaPhoenixParticleIstream() {}

    virtual void close();

    // The stream can return its filename or other identifier for better error messages.
    virtual frantic::tstring name() const;

    // TODO: We should add a verbose_name function, which all wrapping streams are required to mark up in some way

    // This is the size of the particle structure which will be loaded, in bytes.
    virtual std::size_t particle_size() const;

    // Returns the number of particles, or -1 if unknown
    virtual boost::int64_t particle_count() const;
    virtual boost::int64_t particle_index() const;
    virtual boost::int64_t particle_count_left() const;

    virtual boost::int64_t particle_progress_count() const;
    virtual boost::int64_t particle_progress_index() const;

    // This allows you to change the particle layout that's being loaded on the fly, in case it couldn't
    // be set correctly at creation time.
    virtual void set_channel_map( const frantic::channels::channel_map& particleChannelMap );

    // This is the particle channel map which specifies the byte layout of the particle structure that is being used.
    virtual const frantic::channels::channel_map& get_channel_map() const;

    // This is the particle channel map which specifies the byte layout of the input to this stream.
    // NOTE: This value is allowed to change after the following conditions:
    //    * set_channel_map() is called (for example, the empty_particle_istream equates the native map with the
    //    external map)
    virtual const frantic::channels::channel_map& get_native_channel_map() const;

    /** This provides a default particle which should be used to fill in channels of the requested channel map
     *	which are not supplied by the native channel map.
     *	IMPORTANT: Make sure the buffer you pass in is at least as big as particle_size() bytes.
     */
    virtual void set_default_particle( char* rawParticleBuffer );

    // This reads a particle into a buffer matching the channel_map.
    // It returns true if a particle was read, false otherwise.
    // IMPORTANT: Make sure the buffer you pass in is at least as big as particle_size() bytes.
    virtual bool get_particle( char* rawParticleBuffer );

    // This reads a group of particles. Returns false if the end of the source
    // was reached during the read.
    virtual bool get_particles( char* rawParticleBuffer, std::size_t& numParticles );
};

boost::shared_ptr<particle_istream> GetPhoenixParticleIstream( INode* pNode, IPhoenixFDPrtGroup* particles, TimeValue t,
                                                               const frantic::channels::channel_map& pcm ) {
    ObjectState os = pNode->EvalWorldState( t );
    IPhoenixFD* phoenix = (IPhoenixFD*)( os.obj ? os.obj->GetInterface( PHOENIXFD_INTERFACE ) : nullptr );
    if( particles && phoenix && particles->IsChannelSupported( PHXPRT_POS ) ) {
        transform4f xform = get_object_to_grid_transform( phoenix->GetSimData( pNode ) ).to_inverse();
        return boost::make_shared<MaxKrakatoaPhoenixParticleIstream>( particles, xform, pcm );
    } else {
        // This can happen sometimes when there are 0 particles for the current time.
        return boost::shared_ptr<particle_istream>();
    }
}

bool IsPhoenixObject( INode* pNode, TimeValue t ) {
    ObjectState os = pNode->EvalWorldState( t );

    if( Object* pObj = pNode->GetObjectRef() ) {
        pObj = pObj->FindBaseObject();
        IMaxKrakatoaPRTObjectPtr pPRTObj = GetIMaxKrakatoaPRTObject( pObj );
        if( pPRTObj && pObj->ClassID() == MaxKrakatoaPhoenixObject_CLASS_ID )
            return true;
    }

    return false;
}

inline void MaxKrakatoaPhoenixParticleIstream::init_accessors() {
    m_accessors.pos = m_outMap.get_accessor<vector3f>( _T("Position") );

    m_accessors.vel.reset();
    m_accessors.texturecoord.reset();
    m_accessors.orientation.reset();
    m_accessors.size.reset();
    m_accessors.age.reset();
    m_accessors.temp.reset();
    m_accessors.density.reset();
    m_accessors.fuel.reset();

    if( m_outMap.has_channel( _T("Velocity") ) && m_particles->IsChannelSupported( PHXPRT_VEL ) )
        m_accessors.vel = m_outMap.get_cvt_accessor<vector3f>( _T("Velocity") );

    if( m_outMap.has_channel( _T("TextureCoord") ) && m_particles->IsChannelSupported( PHXPRT_OR ) )
        m_accessors.texturecoord = m_outMap.get_cvt_accessor<vector3f>( _T("TextureCoord") );

    if( m_outMap.has_channel( _T("Color") ) )
        m_accessors.color = m_outMap.get_cvt_accessor<vector3f>( _T("Color") );

    if( m_outMap.has_channel( _T("Orientation") ) && m_particles->IsChannelSupported( PHXPRT_OR ) )
        m_accessors.orientation = m_outMap.get_cvt_accessor<quat4f>( _T("Orientation") );

    if( m_outMap.has_channel( _T("Size") ) && m_particles->IsChannelSupported( PHXPRT_SIZE ) )
        m_accessors.size = m_outMap.get_cvt_accessor<float>( _T("Size") );

    if( m_outMap.has_channel( _T("Age") ) && m_particles->IsChannelSupported( PHXPRT_AGE ) )
        m_accessors.age = m_outMap.get_cvt_accessor<float>( _T("Age") );

    if( m_outMap.has_channel( _T("Temperature") ) && m_particles->IsChannelSupported( PHXPRT_T ) )
        m_accessors.temp = m_outMap.get_cvt_accessor<float>( _T("Temperature") );

    if( m_outMap.has_channel( _T("Density") ) && m_particles->IsChannelSupported( PHXPRT_SM ) )
        m_accessors.density = m_outMap.get_cvt_accessor<float>( _T("Density") );

    if( m_outMap.has_channel( _T("Fuel") ) && m_particles->IsChannelSupported( PHXPRT_FL ) )
        m_accessors.fuel = m_outMap.get_cvt_accessor<float>( _T("Fuel") );
}

MaxKrakatoaPhoenixParticleIstream::MaxKrakatoaPhoenixParticleIstream( IPhoenixFDPrtGroup* particles,
                                                                      const frantic::graphics::transform4f& toWorldTM,
                                                                      const frantic::channels::channel_map& pcm )
    : m_outMap( pcm ) {
    m_particles = particles;
    m_particleCount = particles->NumParticles();
    m_particleIndex = -1;

    if( !m_particles->IsChannelSupported( PHXPRT_POS ) )
        throw std::runtime_error(
            "MaxKrakatoaPhoenixParticleIstream() Cannot use particles without a position from source: \"" +
            frantic::strings::to_string( particles->GetName() ) + "\"" );

    m_nativeMap.define_channel<vector3f>( _T("Position") );
    if( m_particles->IsChannelSupported( PHXPRT_VEL ) )
        m_nativeMap.define_channel<vector3f>( _T("Velocity") );
    if( m_particles->IsChannelSupported( PHXPRT_UVW ) )
        m_nativeMap.define_channel<vector3f>( _T("TextureCoord") );
    if( m_particles->IsChannelSupported( PHXPRT_OR ) )
        m_nativeMap.define_channel<quat4f>( _T("Orientation") );
    if( m_particles->IsChannelSupported( PHXPRT_SIZE ) )
        m_nativeMap.define_channel<float>( _T("Size") );
    if( m_particles->IsChannelSupported( PHXPRT_AGE ) )
        m_nativeMap.define_channel<float>( _T("Age") );
    if( m_particles->IsChannelSupported( PHXPRT_SM ) )
        m_nativeMap.define_channel<float>( _T("Density") );
    if( m_particles->IsChannelSupported( PHXPRT_T ) )
        m_nativeMap.define_channel<float>( _T("Temperature") );
    if( m_particles->IsChannelSupported( PHXPRT_FL ) )
        m_nativeMap.define_channel<float>( _T("Fuel") );
    m_nativeMap.define_channel<vector3f>( _T("Color") );
    m_nativeMap.end_channel_definition();

    m_gridTM = toWorldTM;

    init_accessors();
}

void MaxKrakatoaPhoenixParticleIstream::close() {}

frantic::tstring MaxKrakatoaPhoenixParticleIstream::name() const {
    return frantic::strings::to_tstring( m_particles->GetName() );
}

std::size_t MaxKrakatoaPhoenixParticleIstream::particle_size() const { return m_outMap.structure_size(); }

boost::int64_t MaxKrakatoaPhoenixParticleIstream::particle_count() const { return m_particleCount; }

boost::int64_t MaxKrakatoaPhoenixParticleIstream::particle_index() const { return m_particleIndex; }

boost::int64_t MaxKrakatoaPhoenixParticleIstream::particle_count_left() const {
    return m_particleCount - m_particleIndex - 1;
}

boost::int64_t MaxKrakatoaPhoenixParticleIstream::particle_progress_count() const { return m_particleCount; }

boost::int64_t MaxKrakatoaPhoenixParticleIstream::particle_progress_index() const { return m_particleIndex; }

void MaxKrakatoaPhoenixParticleIstream::set_channel_map( const frantic::channels::channel_map& particleChannelMap ) {
    if( m_outMap != particleChannelMap ) {
        m_outMap = particleChannelMap;
        m_defaultParticle.reset();
        init_accessors();
    }
}

const frantic::channels::channel_map& MaxKrakatoaPhoenixParticleIstream::get_channel_map() const { return m_outMap; }

const frantic::channels::channel_map& MaxKrakatoaPhoenixParticleIstream::get_native_channel_map() const {
    return m_nativeMap;
}

void MaxKrakatoaPhoenixParticleIstream::set_default_particle( char* rawParticleBuffer ) {
    if( !m_defaultParticle )
        m_defaultParticle.reset( new char[m_outMap.structure_size()] );
    m_outMap.copy_structure( m_defaultParticle.get(), rawParticleBuffer );
}

bool MaxKrakatoaPhoenixParticleIstream::get_particle( char* rawParticleBuffer ) {
    if( ++m_particleIndex >= m_particleCount )
        return false;

    if( m_defaultParticle )
        m_outMap.copy_structure( rawParticleBuffer, m_defaultParticle.get() );

    float tempSpace[9];

    m_particles->GetChannel( (int)m_particleIndex, PHXPRT_POS, tempSpace );
    m_accessors.pos.get( rawParticleBuffer ) = m_gridTM * vector3f( tempSpace[0], tempSpace[1], tempSpace[2] );

    if( m_accessors.vel.is_valid() ) {
        m_particles->GetChannel( (int)m_particleIndex, PHXPRT_VEL, tempSpace );
        m_accessors.vel.set( rawParticleBuffer, m_gridTM.transform_no_translation(
                                                    vector3f( tempSpace[0], tempSpace[1], tempSpace[2] ) ) );
    }

    if( m_accessors.texturecoord.is_valid() ) {
        m_particles->GetChannel( (int)m_particleIndex, PHXPRT_UVW, tempSpace );
        m_accessors.texturecoord.set( rawParticleBuffer, vector3f( tempSpace[0], tempSpace[1], tempSpace[2] ) );
    }

    if( m_accessors.orientation.is_valid() ) {
        m_particles->GetChannel( (int)m_particleIndex, PHXPRT_OR, tempSpace );

        quat4f result = quat4f::from_coord_sys( vector3f( tempSpace[0], tempSpace[1], tempSpace[2] ),
                                                vector3f( tempSpace[3], tempSpace[4], tempSpace[5] ),
                                                vector3f( tempSpace[6], tempSpace[7], tempSpace[8] ) );

        m_accessors.orientation.set( rawParticleBuffer, result );
    }

    if( m_accessors.size.is_valid() ) {
        m_particles->GetChannel( (int)m_particleIndex, PHXPRT_SIZE, tempSpace );
        m_accessors.size.set( rawParticleBuffer, tempSpace[0] );
    }

    if( m_accessors.age.is_valid() ) {
        m_particles->GetChannel( (int)m_particleIndex, PHXPRT_AGE, tempSpace );
        m_accessors.age.set( rawParticleBuffer, tempSpace[0] );
    }

    if( m_accessors.temp.is_valid() ) {
        m_particles->GetChannel( (int)m_particleIndex, PHXPRT_T, tempSpace );
        m_accessors.temp.set( rawParticleBuffer, tempSpace[0] );
    }

    if( m_accessors.density.is_valid() ) {
        m_particles->GetChannel( (int)m_particleIndex, PHXPRT_SM, tempSpace );
        m_accessors.density.set( rawParticleBuffer, tempSpace[0] );
    }

    if( m_accessors.fuel.is_valid() ) {
        m_particles->GetChannel( (int)m_particleIndex, PHXPRT_FL, tempSpace );
        m_accessors.fuel.set( rawParticleBuffer, tempSpace[0] );
    }

    if( m_accessors.color.is_valid() ) {
        m_accessors.color.set( rawParticleBuffer, vector3f( 1 ) );
    }

    return true;
}

bool MaxKrakatoaPhoenixParticleIstream::get_particles( char* rawParticleBuffer, std::size_t& numParticles ) {
    for( std::size_t i = 0; i < numParticles; ++i, rawParticleBuffer += m_outMap.structure_size() ) {
        if( !this->get_particle( rawParticleBuffer ) ) {
            numParticles = i;
            return false;
        }
    }

    return true;
}

/**
 * An istream which seeds particles inside Phoenix FD fire-smoke simulations.  Based on fumefx_particle_istream4_0.
 */
class PhoenixVolumeSeedingIstream : public particle_istream {
    // Pointer to the Phoenix FD simulation access interface
    IAur* m_aur;
    // The channel map used for output
    frantic::channels::channel_map m_outMap;
    // The channels available in the simulation
    frantic::channels::channel_map m_nativeMap;
    // Generates voxel samples.
    frantic::volumetrics::voxel_sampler_interface_ptr m_sampleGen;
    // The name of the stream
    frantic::tstring m_name;
    // The size of a voxel, in generic units
    frantic::graphics::vector3f m_voxelSize;
    // Whether or not to seed particles in smoke volumes above m_minSmoke
    bool m_seedSmoke;
    // Whether or not to seed particles in temperature volumes above m_minTemperature
    bool m_seedTemperature;
    // Minimum value of the smoke channel in order to get included by this stream
    float m_minSmoke;
    // Minimum value of the temperature channel in order to get included by this stream
    float m_minTemperature;
    // Current number of particles seen
    boost::int64_t m_particleIndex;
    // Number of voxels traversed
    boost::int64_t m_progressIndex;
    // Total number of voxels
    boost::int64_t m_progressCount;
    // The values to use for missing channels
    boost::scoped_array<char> m_defaultParticle;
    // The voxel corresponding to the current progress index
    frantic::graphics::vector3 m_currentVoxel;
    // m_currentVoxel must be smaller than m_voxelBounds in all components
    frantic::graphics::vector3 m_voxelBounds;
    // Cached values for the 2x2x2 box with min() == m_currentVoxel. Used for interpolation.  These are only valid if
    // they are requested, to save memory, as Phoenix has to decompress any channels that we need
    std::array<float, 8> m_cachedSmoke;
    std::array<float, 8> m_cachedFuel;
    std::array<float, 8> m_cachedTemperature;
    std::array<frantic::graphics::vector3f, 8> m_cachedVelocity;
    std::array<frantic::graphics::vector3f, 8> m_cachedTextureCoord;
    // Accessors used for output. Accessors for channels that don't appear in m_outMap will not be valid.
    frantic::channels::channel_accessor<vector3f> m_positionAcc;
    frantic::channels::channel_cvt_accessor<vector3f> m_velocityAcc;
    frantic::channels::channel_cvt_accessor<vector3f> m_vorticityAcc;
    frantic::channels::channel_cvt_accessor<vector3f> m_texCoordAcc;
    frantic::channels::channel_cvt_accessor<float> m_densityAcc;
    frantic::channels::channel_cvt_accessor<float> m_smokeAcc;
    frantic::channels::channel_cvt_accessor<vector3f> m_densityGradAcc;
    frantic::channels::channel_cvt_accessor<float> m_temperatureAcc;
    frantic::channels::channel_cvt_accessor<float> m_fuelAcc;
    frantic::channels::channel_cvt_accessor<vector3f> m_colorAcc;

  public:
    PhoenixVolumeSeedingIstream( INode* phoenixNode, TimeValue t, const frantic::channels::channel_map& pcm,
                                 frantic::volumetrics::voxel_sampler_interface_ptr pSampleGen,
                                 const frantic::tstring& name, float minSmoke, float minTemperature )
        : m_sampleGen( pSampleGen )
        , m_name( name )
        , m_seedSmoke( minSmoke != std::numeric_limits<float>::max() )
        , m_seedTemperature( minTemperature != std::numeric_limits<float>::max() )
        , m_minSmoke( minSmoke )
        , m_minTemperature( minTemperature )
        , m_particleIndex( -1 )
        , m_progressIndex( 0 )
        , m_progressCount( -1 )
        , m_defaultParticle( new char[pcm.structure_size()]() )
        , m_currentVoxel( 0, 0, 0 )
        , m_cachedSmoke()
        , m_cachedFuel()
        , m_cachedTemperature()
        , m_cachedVelocity()
        , m_cachedTextureCoord() {

        ObjectState os = phoenixNode->EvalWorldState( t );
        if( !os.obj )
            throw std::runtime_error( "PhoenixVolumeSeedingIstream: The ObjectState did not contain a valid object. "
                                      "Simulation data for the given node could not be found." );
        IPhoenixFD* phoenix = static_cast<IPhoenixFD*>( os.obj->GetInterface( PHOENIXFD_INTERFACE ) );
        if( !phoenix )
            throw std::runtime_error(
                "PhoenixVolumeSeedingIstream: The given node did not contain a Phoenix FD interface." );
        m_aur = phoenix->GetSimData( phoenixNode );
        if( !m_aur )
            throw std::runtime_error( "PhoenixVolumeSeedingIstream: The given node had no simulation data." );

        int dimensions[3];
        m_aur->GetDim( dimensions );
        m_voxelBounds = vector3( dimensions );
        m_progressCount = m_voxelBounds.x * m_voxelBounds.y * m_voxelBounds.z;

        Box3 bbox;
        os.obj->GetLocalBoundBox( t, phoenixNode, nullptr, bbox );
        m_voxelSize =
            frantic::max3d::from_max_t( bbox.Width() / Point3( dimensions[0], dimensions[1], dimensions[2] ) );

        m_sampleGen->update_for_voxel( m_currentVoxel );

        init_native_map();
        set_channel_map( pcm );
    }

    virtual void close() { m_aur = nullptr; }

    virtual frantic::tstring name() const { return m_name; }

    virtual std::size_t particle_size() const { return m_outMap.structure_size(); }

    virtual boost::int64_t particle_count() const { return -1; }

    virtual boost::int64_t particle_index() const { return m_particleIndex; }

    virtual boost::int64_t particle_count_left() const { return -1; }

    virtual boost::int64_t particle_progress_count() const { return m_progressCount; }

    virtual boost::int64_t particle_progress_index() const { return m_progressIndex; }

    virtual void set_channel_map( const frantic::channels::channel_map& cm ) {
        if( m_outMap.channel_definition_complete() ) {
            boost::scoped_array<char> newDefaultParticle( new char[cm.structure_size()] );
            frantic::channels::channel_map_adaptor tempAdaptor( cm, m_outMap );
            tempAdaptor.copy_structure( newDefaultParticle.get(), m_defaultParticle.get() );
            m_defaultParticle.swap( newDefaultParticle );
        }

        m_outMap = cm;
        init_accessors();
    }

    virtual const frantic::channels::channel_map& get_channel_map() const { return m_outMap; }

    virtual const frantic::channels::channel_map& get_native_channel_map() const { return m_nativeMap; }

    virtual void set_default_particle( char* buffer ) { m_outMap.copy_structure( &m_defaultParticle[0], buffer ); }

    virtual bool get_particle( char* rawParticleBuffer ) {
        if( !m_aur )
            return false;

        if( m_particleIndex < 0 )
            load_voxels();

        float smoke( 0 );
        float temperature( 0 );
        float weights[8];
        float compensationFactor;
        frantic::graphics::vector3f samplePos;

        do {
            if( !m_sampleGen->get_next_position( samplePos, compensationFactor ) ) {
                do {
                    if( !advance_iterator() )
                        return false;
                    ++m_progressIndex;
                } while( !m_sampleGen->get_next_position( samplePos, compensationFactor ) );

                cache_voxel_values();
            }

            frantic::volumetrics::levelset::get_trilerp_weights( &samplePos.x, weights );

            smoke = trilerp( m_cachedSmoke.data(), weights );
            temperature = trilerp( m_cachedTemperature.data(), weights );
        } while( smoke <= m_minSmoke && temperature <= m_minTemperature );

        compensationFactor *= ( m_voxelSize.x * m_voxelSize.y * m_voxelSize.z );

        ++m_particleIndex;

        // Copy the default values into the particle
        m_outMap.copy_structure( rawParticleBuffer, &m_defaultParticle[0] );

        const auto gridToObjectTransform = get_object_to_grid_transform( m_aur ).to_inverse();
        const auto position = gridToObjectTransform * ( m_currentVoxel + samplePos );
        m_positionAcc( rawParticleBuffer ).set( position.x, position.y, position.z );

        if( m_densityAcc.is_valid() )
            m_densityAcc.set( rawParticleBuffer, smoke * compensationFactor );

        if( m_smokeAcc.is_valid() )
            m_smokeAcc.set( rawParticleBuffer, smoke * compensationFactor );

        if( m_fuelAcc.is_valid() ) {
            const auto fuel = trilerp( m_cachedFuel.data(), weights );
            m_fuelAcc.set( rawParticleBuffer, fuel );
        }

        if( m_temperatureAcc.is_valid() ) {
            const auto temp = trilerp( m_cachedTemperature.data(), weights );
            m_temperatureAcc.set( rawParticleBuffer, temp );
        }

        if( m_velocityAcc.is_valid() ) {
            frantic::graphics::vector3f v( 0.f );
            for( int i = 0; i < m_cachedVelocity.size(); ++i )
                v += weights[i] * m_cachedVelocity[i];
            v = gridToObjectTransform * v;
            m_velocityAcc.set( rawParticleBuffer, v );
        }

        if( m_texCoordAcc.is_valid() ) {
            frantic::graphics::vector3f tc( 0.f );
            for( int i = 0; i < m_cachedTextureCoord.size(); ++i )
                tc += weights[i] * m_cachedTextureCoord[i];
            m_texCoordAcc.set( rawParticleBuffer, tc );
        }

        if( m_densityGradAcc.is_valid() ) {
            frantic::graphics::vector3f grad =
                frantic::graphics::trilerp_gradient( &samplePos.x, m_cachedSmoke.data(), m_voxelSize.x );
            m_densityGradAcc.set( rawParticleBuffer, grad );
        }

        if( m_vorticityAcc.is_valid() ) {
            frantic::graphics::vector3f vort =
                frantic::graphics::trilerp_curl( &samplePos.x, m_cachedVelocity.data(), m_voxelSize.x );
            m_vorticityAcc.set( rawParticleBuffer, vort );
        }

        if( m_colorAcc.is_valid() ) {
            m_colorAcc.set( rawParticleBuffer,
                            vector3f( 1 ) ); // Default to white, to be consistent with the other Phoenix streams
        }

        return true;
    }

    virtual bool get_particles( char* particleBuffer, std::size_t& numParticles ) {
        const std::size_t particleSize = m_outMap.structure_size();
        for( std::size_t i = 0; i < numParticles; ++i ) {
            if( !get_particle( particleBuffer + i * particleSize ) ) {
                numParticles = i;
                return false;
            }
        }
        return true;
    }

  private:
    void init_native_map() {
        m_nativeMap.reset();
        m_nativeMap.define_channel<vector3f>( _T("Position") );
        if( m_aur->ChannelPresent( PHX_T ) )
            m_nativeMap.define_channel<float>( _T("Temperature") );
        if( m_aur->ChannelPresent( PHX_SM ) ) {
            m_nativeMap.define_channel<float>( _T("Smoke") );
            m_nativeMap.define_channel<float>( _T("Density") );
        }
        if( m_aur->ChannelPresent( PHX_Vx ) && m_aur->ChannelPresent( PHX_Vy ) && m_aur->ChannelPresent( PHX_Vz ) )
            m_nativeMap.define_channel<vector3f>( _T("Velocity") );
        if( m_aur->ChannelPresent( PHX_U ) && m_aur->ChannelPresent( PHX_V ) && m_aur->ChannelPresent( PHX_W ) )
            m_nativeMap.define_channel<vector3f>( _T("TextureCoord") );
        if( m_aur->ChannelPresent( PHX_Fl ) )
            m_nativeMap.define_channel<float>( _T("Fuel") );
        // Defining the Color channel in the native map ensures that the wireframe colour won't be used
        m_nativeMap.define_channel<vector3f>( _T("Color") );
        m_nativeMap.end_channel_definition();
    }

    void init_accessors() {
        m_velocityAcc.reset();
        m_vorticityAcc.reset();
        m_texCoordAcc.reset();
        m_densityAcc.reset();
        m_smokeAcc.reset();
        m_temperatureAcc.reset();
        m_fuelAcc.reset();
        m_colorAcc.reset();

        m_positionAcc = m_outMap.get_accessor<vector3f>( _T("Position") );
        if( m_outMap.has_channel( _T("Density") ) )
            m_densityAcc = m_outMap.get_cvt_accessor<float>( _T("Density") );
        if( m_outMap.has_channel( _T("Smoke") ) )
            m_smokeAcc = m_outMap.get_cvt_accessor<float>( _T("Smoke") );
        if( m_outMap.has_channel( _T("DensityGradient") ) )
            m_densityGradAcc = m_outMap.get_cvt_accessor<vector3f>( _T("DensityGradient") );
        if( m_outMap.has_channel( _T("Temperature") ) )
            m_temperatureAcc = m_outMap.get_cvt_accessor<float>( _T("Temperature") );
        if( m_outMap.has_channel( _T("Fuel") ) )
            m_fuelAcc = m_outMap.get_cvt_accessor<float>( _T("Fuel") );
        if( m_outMap.has_channel( _T("Velocity") ) )
            m_velocityAcc = m_outMap.get_cvt_accessor<vector3f>( _T("Velocity") );
        if( m_outMap.has_channel( _T("Vorticity") ) )
            m_vorticityAcc = m_outMap.get_cvt_accessor<vector3f>( _T("Vorticity") );
        if( m_outMap.has_channel( _T("TextureCoord") ) )
            m_texCoordAcc = m_outMap.get_cvt_accessor<vector3f>( _T("TextureCoord") );
        if( m_outMap.has_channel( _T("Color") ) )
            m_colorAcc = m_outMap.get_cvt_accessor<vector3f>( _T("Color") );
    }

    /**
     * @see Comment on fumefx_particle_istream4_0::load_voxels.
     */
    void load_voxels() {
        init_accessors();

        // Initialize the first voxel's values.
        for( int i = 0; i < 7; ++i )
            clear_voxel_value( i );
        cache_voxel_value( 7, 0 );
    }

    bool advance_iterator() {
        if( ++m_currentVoxel.x >= m_voxelBounds.x ) {
            if( ++m_currentVoxel.y >= m_voxelBounds.y ) {
                if( ++m_currentVoxel.z >= m_voxelBounds.z )
                    return false;
                m_currentVoxel.y = -1;
            }
            m_currentVoxel.x = -1;
        }

        m_sampleGen->update_for_voxel( m_currentVoxel );
        return true;
    }

    // Voxel grid caching

    inline void cache_voxel_value( int cacheItem, int voxelIndex ) {
        if( m_densityAcc.is_valid() || m_seedSmoke )
            m_cachedSmoke[cacheItem] = get_grid_value( m_aur, PHX_SM, voxelIndex, m_name );
        if( m_fuelAcc.is_valid() )
            m_cachedFuel[cacheItem] = get_grid_value( m_aur, PHX_Fl, voxelIndex, m_name );
        if( m_temperatureAcc.is_valid() || m_seedTemperature )
            m_cachedTemperature[cacheItem] = get_grid_value( m_aur, PHX_T, voxelIndex, m_name );
        if( m_velocityAcc.is_valid() || m_vorticityAcc.is_valid() ) {
            vector3f v( get_grid_value( m_aur, PHX_Vx, voxelIndex, m_name ),
                        get_grid_value( m_aur, PHX_Vy, voxelIndex, m_name ),
                        get_grid_value( m_aur, PHX_Vz, voxelIndex, m_name ) );
            m_cachedVelocity[cacheItem] = v;
        }
        if( m_texCoordAcc.is_valid() ) {
            vector3f v( get_grid_value( m_aur, PHX_U, voxelIndex, m_name ),
                        get_grid_value( m_aur, PHX_V, voxelIndex, m_name ),
                        get_grid_value( m_aur, PHX_W, voxelIndex, m_name ) );
            m_cachedTextureCoord[cacheItem] = v;
        }
    }

    inline void clear_voxel_value( int cacheItem ) {
        m_cachedSmoke[cacheItem] = 0.f;
        m_cachedFuel[cacheItem] = 0.f;
        m_cachedTemperature[cacheItem] = 0.f;
        m_cachedVelocity[cacheItem] = frantic::graphics::vector3f( 0.f );
        m_cachedTextureCoord[cacheItem] = frantic::graphics::vector3f( 0.f );
    }

    inline void shift_cached_values() {
        for( int i = 0; i < 4; ++i )
            m_cachedSmoke[i] = m_cachedSmoke[i + 4];
        for( int i = 0; i < 4; ++i )
            m_cachedFuel[i] = m_cachedFuel[i + 4];
        for( int i = 0; i < 4; ++i )
            m_cachedTemperature[i] = m_cachedTemperature[i + 4];
        for( int i = 0; i < 4; ++i )
            m_cachedVelocity[i] = m_cachedVelocity[i + 4];
        for( int i = 0; i < 4; ++i )
            m_cachedTextureCoord[i] = m_cachedTextureCoord[i + 4];
    }

    void cache_voxel_values() {
        static const int ROW_START = 0;
        if( m_currentVoxel.x > ROW_START ) {
            shift_cached_values();
        } else {
            for( int i = 0; i < 4; ++i )
                clear_voxel_value( i );
        }

        if( m_currentVoxel.x + 1 < m_voxelBounds.x ) {
            const int voxelIndex =
                m_currentVoxel.x + m_voxelBounds.x * ( m_currentVoxel.y + m_voxelBounds.y * m_currentVoxel.z ) + 1;
            if( m_currentVoxel.z < m_voxelBounds.z ) {
                if( m_currentVoxel.y < m_voxelBounds.y )
                    cache_voxel_value( 4, voxelIndex );
                else
                    clear_voxel_value( 4 );

                if( ( m_currentVoxel.y + 1 ) < m_voxelBounds.y )
                    cache_voxel_value( 6, voxelIndex + m_voxelBounds.x );
                else
                    clear_voxel_value( 6 );
            } else {
                clear_voxel_value( 4 );
                clear_voxel_value( 6 );
            }

            if( ( m_currentVoxel.z + 1 ) < m_voxelBounds.z ) {
                if( m_currentVoxel.y < m_voxelBounds.y )
                    cache_voxel_value( 5, voxelIndex + m_voxelBounds.y * m_voxelBounds.x );
                else
                    clear_voxel_value( 5 );

                if( ( m_currentVoxel.y + 1 ) < m_voxelBounds.y )
                    cache_voxel_value( 7, voxelIndex + m_voxelBounds.y * m_voxelBounds.x + m_voxelBounds.x );
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
};

frantic::particles::particle_istream_ptr
GetPhoenixParticleIstreamFromVolume( INode* phoenixNode, TimeValue t, const frantic::channels::channel_map& pcm,
                                     frantic::volumetrics::voxel_sampler_interface_ptr pVoxelIter, float minSmoke,
                                     float minTemperature ) {
    return boost::make_shared<PhoenixVolumeSeedingIstream>( phoenixNode, t, pcm, pVoxelIter, phoenixNode->GetName(),
                                                            minSmoke, minTemperature );
}
#endif
