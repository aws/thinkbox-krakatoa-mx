// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0
/** This copy of MaxKrakatoaTPParticleIstream will use the ThinkingParticles 3.0 headers.
 */

#include "stdafx.h"
#ifdef DONTBUILDTHIS
#include <frantic/channels/channel_map_adaptor.hpp>
#include <frantic/graphics/color3f.hpp>
#include <frantic/graphics/vector3f.hpp>
#include <frantic/graphics/vector4f.hpp>
#include <frantic/max3d/convert.hpp>
#include <frantic/particles/streams/particle_istream.hpp>

#define WIN32_LEAN_AND_MEAN
#define NOMINMAX
#include <windows.h>

#include <frantic/win32/utility.hpp>

using std::max;
using std::min;

#pragma warning( push, 3 )
#include <IParticleObjectExt.h>
#include <MatterWaves.h>
#pragma warning( pop )

using frantic::channels::channel_cvt_accessor;
using frantic::channels::channel_map;
using frantic::graphics::color3f;
using frantic::graphics::vector3f;
using frantic::graphics::vector4f;
using frantic::particles::streams::particle_istream;

#if defined _WIN64
#pragma message( "Linking with ThinkingParticles-max9-x64.lib" )
#define GROUP_FN( ms, p ) g_groupFn( ms, p )
#define GROUP_FN_NAME "?Group@MasterSystem@@QEAAPEAVPGroup@@H@Z"
typedef PGroup* ( *GROUP_FN )( MasterSystem*, int );
#elif defined WIN32
#if _MSC_VER >= 1400
#pragma message( "Linking with ThinkingParticles-max9-win32.lib" )
#define GROUP_FN( ms, p ) g_groupFn( ms, p )
#define GROUP_FN_NAME "?Group@MasterSystem@@QAEPAVPGroup@@H@Z"
typedef PGroup*( __thiscall* GROUP_FN )( MasterSystem*, int );
#else
#pragma message( "Linking with ThinkingParticles-max8-win32.lib" )
#define GROUP_FN( ms, p ) g_groupFn( ms, ms, p )
#define GROUP_FN_NAME "?Group@MasterSystem@@QAEPAVPGroup@@H@Z"
typedef PGroup*( __fastcall* GROUP_FN )( MasterSystem*, MasterSystem*, int );
#endif
#else
#error "You cannot compile Thinking Particles 2.5 support for this platform"
#endif

namespace {
HMODULE g_tpHandle = NULL;
GROUP_FN g_groupFn = NULL;
} // namespace

class thinking_particle_istream : public particle_istream {
  private:
    ParticleMat* m_pMat;
    PGroup* m_pGroup;
    IParticleObjectExt* m_pParticles;

    std::string m_name;
    TimeValue m_time;
    float m_fps;

    Tab<int> m_indices;
    int m_currentParticle;

    std::map<std::string, int> m_customTPChannels;

    std::vector<std::pair<int, frantic::channels::channel_cvt_accessor<int>>> m_intAccessors;
    std::vector<std::pair<int, frantic::channels::channel_cvt_accessor<float>>> m_floatAccessors;
    std::vector<std::pair<int, frantic::channels::channel_cvt_accessor<color3f>>> m_colorAccessors;
    std::vector<std::pair<int, frantic::channels::channel_cvt_accessor<vector3f>>> m_vectorAccessors;

    channel_map m_outMap;
    channel_map m_nativeMap;
    boost::scoped_array<char> m_defaultParticle;

    struct {
        channel_cvt_accessor<vector4f> orientation;
        // channel_cvt_accessor<vector4f> spin;
        channel_cvt_accessor<vector3f> position;
        channel_cvt_accessor<vector3f> velocity;
        channel_cvt_accessor<vector3f> scale;
        channel_cvt_accessor<vector3f> normal;
        channel_cvt_accessor<vector3f> tangent;
        channel_cvt_accessor<color3f> color;
        channel_cvt_accessor<TimeValue> age;
        channel_cvt_accessor<TimeValue> lifeSpan;
        channel_cvt_accessor<int> id;
    } m_accessors;

    void init_accessors( const channel_map& pcm ) {
        m_accessors.orientation.reset();
        // m_accessors.spin.reset();
        m_accessors.position.reset();
        m_accessors.velocity.reset();
        m_accessors.scale.reset();
        m_accessors.normal.reset();
        m_accessors.tangent.reset();
        m_accessors.color.reset();
        m_accessors.age.reset();
        m_accessors.lifeSpan.reset();
        m_accessors.id.reset();

        for( std::size_t i = 0; i < pcm.channel_count(); ++i ) {
            const frantic::channels::channel& ch = pcm[i];

            std::map<std::string, int>::iterator it = m_customTPChannels.find( ch.name() );
            if( it == m_customTPChannels.end() )
                continue;
            if( it->second >= 0 ) {
                int tpChannelIndex = it->second;
                int type = m_pMat->DataChannelType( m_pGroup, tpChannelIndex );

                if( type == PORT_TYPE_INT )
                    m_intAccessors.push_back(
                        std::make_pair( tpChannelIndex, pcm.get_cvt_accessor<int>( ch.name() ) ) );
                else if( type == PORT_TYPE_FLOAT )
                    m_floatAccessors.push_back(
                        std::make_pair( tpChannelIndex, pcm.get_cvt_accessor<float>( ch.name() ) ) );
                else if( type == PORT_TYPE_COLOR )
                    m_colorAccessors.push_back(
                        std::make_pair( tpChannelIndex, pcm.get_cvt_accessor<color3f>( ch.name() ) ) );
                else if( type == PORT_TYPE_POINT3 )
                    m_vectorAccessors.push_back(
                        std::make_pair( tpChannelIndex, pcm.get_cvt_accessor<vector3f>( ch.name() ) ) );
                else
                    throw std::runtime_error( "The channel \"" + ch.name() + "\" has an unsupported type" );
            } else {
                if( ch.name() == "Orientation" )
                    m_accessors.orientation = pcm.get_cvt_accessor<vector4f>( "Orientation" );
                // else if( ch.name() == "Spin" )
                //	m_accessors.spin = pcm.get_cvt_accessor<vector4f>("Spin");
                else if( ch.name() == "Position" )
                    m_accessors.position = pcm.get_cvt_accessor<vector3f>( "Position" );
                else if( ch.name() == "Velocity" )
                    m_accessors.velocity = pcm.get_cvt_accessor<vector3f>( "Velocity" );
                else if( ch.name() == "Scale" )
                    m_accessors.scale = pcm.get_cvt_accessor<vector3f>( "Scale" );
                else if( ch.name() == "Normal" )
                    m_accessors.normal = pcm.get_cvt_accessor<vector3f>( "Normal" );
                else if( ch.name() == "Tangent" )
                    m_accessors.tangent = pcm.get_cvt_accessor<vector3f>( "Tangent" );
                else if( ch.name() == "Color" )
                    m_accessors.color = pcm.get_cvt_accessor<color3f>( "Color" );
                else if( ch.name() == "Age" )
                    m_accessors.age = pcm.get_cvt_accessor<TimeValue>( "Age" );
                else if( ch.name() == "LifeSpan" )
                    m_accessors.lifeSpan = pcm.get_cvt_accessor<TimeValue>( "LifeSpan" );
                else if( ch.name() == "ID" )
                    m_accessors.id = pcm.get_cvt_accessor<int>( "ID" );
            }
        }
    }

  public:
    thinking_particle_istream( INode* pNode, PGroup* group, TimeValue t, const channel_map& pcm )
        : m_time( t )
        , m_name( "Thinking Particles particle istream for group: " + std::string( group->GetName() ) ) {
        Object* pObj = pNode->GetObjectRef();
        if( !pObj || ( pObj = pObj->FindBaseObject() )->ClassID() != MATTERWAVES_CLASS_ID )
            throw std::runtime_error( std::string() + "thinking_particle_istream() - Node: " + pNode->GetName() +
                                      " is not a Thinking Particles object" );

        m_pMat = static_cast<ParticleMat*>( pObj );
        m_pGroup = group;

        m_pParticles = GetParticleObjectExtInterface( pObj );

        if( !m_pParticles )
            throw std::runtime_error( std::string() + "thinking_particle_istream() - Node: " + pNode->GetName() +
                                      " had a TP object, but did not implement IParticleObjectExt" );

        m_pMat->UpdateParticles( t, pNode );
        m_pMat->GetGroupParticles( m_pGroup, &m_indices );

        { // Loop through all the particles ... removing indices that are not actually members of this group. HACK!
            MasterSystem* pSys = static_cast<DynMaster*>( m_pMat->GetReference( 2 ) )->dyn.mastersystem;
            int back = m_indices.Count();
            for( int i = 0; i < back; /*Nothing*/ ) {
                if( GROUP_FN( pSys, m_indices[i] ) != m_pGroup || !m_pMat->Alive( m_indices[i] ) ) {
                    m_indices[i] = m_indices[back - 1];
                    --back;
                } else
                    ++i;
            }

            m_indices.Resize( back );
        }

        m_currentParticle = -1;

        // Thinking Particles messed up the Spin & Velocity channels. They are supposed to be per-frame according to the
        // Max header documentation but Cebas has made them per tick. m_fps = static_cast<float>( GetFrameRate() );
        m_fps = static_cast<float>( TIME_TICKSPERSEC );

        // Add all the default channels into the map, in order to catch custom channels
        // with conflicting names.
        m_customTPChannels.insert( std::make_pair( "Orientation", -1 ) );
        // m_customTPChannels.insert( std::make_pair("Spin",-1) );
        m_customTPChannels.insert( std::make_pair( "Position", -1 ) );
        m_customTPChannels.insert( std::make_pair( "Velocity", -1 ) );
        m_customTPChannels.insert( std::make_pair( "Scale", -1 ) );
        m_customTPChannels.insert( std::make_pair( "Normal", -1 ) );
        m_customTPChannels.insert( std::make_pair( "Tangent", -1 ) );
        m_customTPChannels.insert( std::make_pair( "Age", -1 ) );
        m_customTPChannels.insert( std::make_pair( "LifeSpan", -1 ) );
        m_customTPChannels.insert( std::make_pair( "ID", -1 ) );

        m_nativeMap.define_channel<vector4f>( "Orientation" );
        // m_nativeMap.define_channel<vector4f>("Spin");
        m_nativeMap.define_channel<vector3f>( "Position" );
        m_nativeMap.define_channel<vector3f>( "Velocity" );
        m_nativeMap.define_channel<vector3f>( "Scale" );
        m_nativeMap.define_channel<vector3f>( "Normal" );
        m_nativeMap.define_channel<vector3f>( "Tangent" );
        m_nativeMap.define_channel<TimeValue>( "Age" );
        m_nativeMap.define_channel<TimeValue>( "LifeSpan" );
        m_nativeMap.define_channel<int>( "ID" );

        // TP supports custom data channels with type Float, Int, Vector, Alignment, and Color.
        // These will be passed through, as long as the names do not interfere with other channels.
        int numDataChannels = m_pMat->NumDataChannels( m_pGroup );
        for( int i = 0; i < numDataChannels; ++i ) {
            std::string channelName = m_pMat->DataChannelName( m_pGroup, i );
            if( m_customTPChannels.find( channelName ) != m_customTPChannels.end() )
                throw std::runtime_error( "The channel \"" + channelName + "\" already exists in TP object " + m_name );

            int type = m_pMat->DataChannelType( m_pGroup, i );
            if( type == PORT_TYPE_FLOAT )
                m_nativeMap.define_channel<float>( channelName );
            else if( type == PORT_TYPE_INT )
                m_nativeMap.define_channel<int>( channelName );
            else if( type == PORT_TYPE_COLOR || type == PORT_TYPE_POINT3 )
                m_nativeMap.define_channel<vector3f>( channelName );
            else {
                FF_LOG( warning ) << "The channel \"" << channelName
                                  << "\" in object: " + m_name + " has an unsupported type" << std::endl;
                continue;
            }
            m_customTPChannels.insert( std::make_pair( channelName, i ) );
        }

        if( m_customTPChannels.find( "Color" ) == m_customTPChannels.end() ) {
            m_customTPChannels.insert( std::make_pair( "Color", -1 ) );
            m_nativeMap.define_channel<color3f>( "Color" );
        }
        m_nativeMap.end_channel_definition();

        set_channel_map( pcm );
    }

    virtual ~thinking_particle_istream() { close(); }
    void close() {}

    void set_channel_map( const channel_map& pcm ) {
        boost::scoped_array<char> newDefaultParticle( new char[pcm.structure_size()] );
        if( m_defaultParticle ) {
            frantic::channels::channel_map_adaptor defaultAdaptor( pcm, m_outMap );
            defaultAdaptor.copy_structure( newDefaultParticle.get(), m_defaultParticle.get() );
        } else
            memset( newDefaultParticle.get(), 0, pcm.structure_size() );
        m_defaultParticle.swap( newDefaultParticle );

        m_outMap = pcm;
        init_accessors( m_outMap );
    }

    const channel_map& get_channel_map() const { return m_outMap; }
    const channel_map& get_native_channel_map() const { return m_nativeMap; }

    virtual std::string name() const { return m_name; }

    virtual std::size_t particle_size() const { return m_outMap.structure_size(); }

    virtual boost::int64_t particle_count() const { return m_indices.Count(); }
    virtual boost::int64_t particle_index() const { return m_currentParticle; }
    virtual boost::int64_t particle_count_left() const { return m_indices.Count() - m_currentParticle - 1; }
    virtual boost::int64_t particle_progress_count() const { return m_indices.Count(); }
    virtual boost::int64_t particle_progress_index() const { return m_currentParticle; }

    virtual void set_default_particle( char* rawParticleBuffer ) {
        memcpy( m_defaultParticle.get(), rawParticleBuffer, m_outMap.structure_size() );
    }

    virtual bool get_particle( char* rawParticleBuffer ) {
        if( ++m_currentParticle >= m_indices.Count() )
            return false;

        memcpy( rawParticleBuffer, m_defaultParticle.get(), m_outMap.structure_size() );

        if( m_accessors.position.is_valid() )
            m_accessors.position.set( rawParticleBuffer,
                                      frantic::max3d::from_max_t(
                                          *m_pParticles->GetParticlePositionByIndex( m_indices[m_currentParticle] ) ) );

        if( m_accessors.velocity.is_valid() )
            m_accessors.velocity.set(
                rawParticleBuffer,
                frantic::max3d::from_max_t( *m_pParticles->GetParticleSpeedByIndex( m_indices[m_currentParticle] ) *
                                            m_fps ) );

        if( m_accessors.scale.is_valid() )
            m_accessors.scale.set( rawParticleBuffer,
                                   frantic::max3d::from_max_t(
                                       *m_pParticles->GetParticleScaleXYZByIndex( m_indices[m_currentParticle] ) ) );

        if( m_accessors.age.is_valid() )
            m_accessors.age.set( rawParticleBuffer,
                                 m_pParticles->GetParticleAgeByIndex( m_indices[m_currentParticle] ) );

        if( m_accessors.lifeSpan.is_valid() )
            m_accessors.lifeSpan.set( rawParticleBuffer,
                                      m_pParticles->GetParticleLifeSpanByIndex( m_indices[m_currentParticle] ) );

        if( m_accessors.id.is_valid() )
            m_accessors.id.set( rawParticleBuffer, m_indices[m_currentParticle] );

        // Orientation is stored as a Quaternion. GetParticleOrientationByIndex returns radians instead of
        // degrees like the documentation suggests they should
        if( m_accessors.orientation.is_valid() ) {
            Quat q;
            EulerToQuat( *m_pParticles->GetParticleOrientationByIndex( m_indices[m_currentParticle] ), q,
                         EULERTYPE_XYZ );

            m_accessors.orientation.set( rawParticleBuffer, q );
        }

        // The normal is the x-axis of the matrix created from the orientation.
        // GetParticleOrientationByIndex returns radians instead of degrees like the IParticleObjExt
        // documentation suggests
        if( m_accessors.normal.is_valid() || m_accessors.tangent.is_valid() ) {
            Matrix3 m;
            EulerToMatrix( *m_pParticles->GetParticleOrientationByIndex( m_indices[m_currentParticle] ), m,
                           EULERTYPE_XYZ );

            if( m_accessors.normal.is_valid() )
                m_accessors.normal.set( rawParticleBuffer, frantic::max3d::from_max_t( m.GetRow( 0 ) ) );
            if( m_accessors.tangent.is_valid() )
                m_accessors.normal.set( rawParticleBuffer, frantic::max3d::from_max_t( m.GetRow( 1 ) ) );
        }

        // Spin is stored as an Angle-Axis. GetParticleSpinByIndex returns radians instead of
        // degrees like the IParticleObjExt documentation suggests
        /*	if( m_accessors.spin.is_valid() ){
                        AngAxis* pA = m_pParticles->GetParticleSpinByIndex(m_indices[m_currentParticle]);
                        m_accessors.spin.set(rawParticleBuffer, AngAxis(pA->axis, pA->angle * m_fps));
                }*/

        if( m_accessors.color.is_valid() )
            m_accessors.color.set( rawParticleBuffer, color3f( m_pGroup->GetColor() ) );

        union {
            float f[4];
            int i[1];
        } tempData;

        int currentIndex = m_indices[m_currentParticle];

        { // Copy the custom integer channels
            std::vector<std::pair<int, frantic::channels::channel_cvt_accessor<int>>>::iterator it, itEnd;
            for( it = m_intAccessors.begin(), itEnd = m_intAccessors.end(); it != itEnd; ++it ) {
                BOOL result = m_pMat->GetValue( currentIndex, it->first, tempData.i, PORT_TYPE_INT );
                if( !result )
                    throw std::runtime_error( "Failed to read from integer TP channel " +
                                              boost::lexical_cast<std::string>( it->first ) + " in TP object " +
                                              m_name );
                it->second.set( rawParticleBuffer, tempData.i[0] );
            }
        }

        { // Copy the custom float channels
            std::vector<std::pair<int, frantic::channels::channel_cvt_accessor<float>>>::iterator it, itEnd;
            for( it = m_floatAccessors.begin(), itEnd = m_floatAccessors.end(); it != itEnd; ++it ) {
                BOOL result = m_pMat->GetValue( currentIndex, it->first, tempData.f, PORT_TYPE_FLOAT );
                if( !result )
                    throw std::runtime_error( "Failed to read from float TP channel " +
                                              boost::lexical_cast<std::string>( it->first ) + " in TP object " +
                                              m_name );
                it->second.set( rawParticleBuffer, tempData.f[0] );
            }
        }

        { // Copy the custom Point3 channels
            std::vector<std::pair<int, frantic::channels::channel_cvt_accessor<vector3f>>>::iterator it, itEnd;
            for( it = m_vectorAccessors.begin(), itEnd = m_vectorAccessors.end(); it != itEnd; ++it ) {
                BOOL result = m_pMat->GetValue( currentIndex, it->first, tempData.f, PORT_TYPE_POINT3 );
                if( !result )
                    throw std::runtime_error( "Failed to read from Point3 TP channel " +
                                              boost::lexical_cast<std::string>( it->first ) + " in TP object " +
                                              m_name );
                it->second.set( rawParticleBuffer, vector3f( tempData.f[0], tempData.f[1], tempData.f[2] ) );
            }
        }

        { // Copy the custom Color channels
            std::vector<std::pair<int, frantic::channels::channel_cvt_accessor<color3f>>>::iterator it, itEnd;
            for( it = m_colorAccessors.begin(), itEnd = m_colorAccessors.end(); it != itEnd; ++it ) {
                BOOL result = m_pMat->GetValue( currentIndex, it->first, tempData.f, PORT_TYPE_COLOR );
                if( !result )
                    throw std::runtime_error( "Failed to read from Point3 TP channel " +
                                              boost::lexical_cast<std::string>( it->first ) + " in TP object " +
                                              m_name );
                it->second.set( rawParticleBuffer, color3f( tempData.f[0], tempData.f[1], tempData.f[2] ) );
            }
        }

        return true;
    }

    bool get_particles( char* buffer, std::size_t& numParticles ) {
        for( std::size_t i = 0; i < numParticles; ++i ) {
            if( !this->get_particle( buffer ) ) {
                numParticles = i;
                return false;
            }

            buffer += m_outMap.structure_size();
        }

        return true;
    }
};

boost::shared_ptr<frantic::particles::streams::particle_istream>
get_thinking_particle_istream_30( INode* pNode, ReferenceTarget* pGroup, TimeValue t,
                                  const frantic::channels::channel_map& pcm ) {
    if( !g_tpHandle ) {
        g_tpHandle = LoadLibrary( "ThinkingParticles.dlo" );
        if( !g_tpHandle )
            throw std::runtime_error( "Failed to load ThinkingParticles.dlo because:\n" +
                                      frantic::win32::GetLastErrorMessage() );

        try {
            g_groupFn = (GROUP_FN)GetProcAddress( g_tpHandle, GROUP_FN_NAME );
            if( !g_groupFn )
                throw std::runtime_error( "Failed to load " GROUP_FN_NAME " from ThinkingParticles.dlo because:\n" +
                                          frantic::win32::GetLastErrorMessage() );
        } catch( ... ) {
            FreeLibrary( g_tpHandle );
            g_tpHandle = NULL;
            throw;
        }
    }

    return boost::shared_ptr<particle_istream>( new thinking_particle_istream( pNode, (PGroup*)pGroup, t, pcm ) );
}

void get_tp_groups_30( INode* pNode, std::vector<ReferenceTarget*>& outGroups ) {
    Object* pObj = pNode->GetObjectRef();
    if( !pObj || pObj->FindBaseObject()->ClassID() != MATTERWAVES_CLASS_ID )
        throw std::runtime_error( "get_tp_groups_30() - The node was not a TP node" );

    ParticleMat* pMat = static_cast<ParticleMat*>( pObj->FindBaseObject() );

    Tab<DynNameBase*> groups;
    pMat->GetALLGroups( &groups );

    outGroups.clear();
    for( int i = 0; i < groups.Count(); ++i )
        outGroups.push_back( groups[i] );
}
#endif
