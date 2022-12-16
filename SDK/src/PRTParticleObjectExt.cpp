// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0
#include "stdafx.h"

#include <krakatoa/max3d/IPRTParticleObjectExt.hpp>

#include <frantic/channels/named_channel_data.hpp>
#include <frantic/graphics/camera.hpp>
#include <frantic/logging/logging_level.hpp>
#include <frantic/particles/particle_array.hpp>
#include <frantic/particles/streams/apply_function_particle_istream.hpp>
#include <frantic/particles/streams/empty_particle_istream.hpp>

#include <boost/call_traits.hpp>
#include <boost/foreach.hpp>
#include <boost/make_shared.hpp>
#include <boost/scoped_ptr.hpp>

using frantic::max3d::particles::IMaxKrakatoaPRTObject;
using frantic::max3d::particles::IMaxKrakatoaPRTObjectPtr;
using namespace frantic::channels;
using namespace frantic::graphics;

typedef boost::shared_ptr<frantic::particles::streams::particle_istream> particle_istream_ptr;

namespace frantic {
namespace channels {

template <>
struct channel_data_type_traits<Point3> {
    typedef Point3 value_type;
    inline static size_t arity() { return 3; }
    inline static data_type_t data_type() { return data_type_float32; }
    inline static M_STD_STRING type_str() { return channel_data_type_str( arity(), data_type() ); }
};

template <>
struct channel_data_type_traits<AngAxis> {
    typedef Point3 value_type;
    inline static size_t arity() { return 4; }
    inline static data_type_t data_type() { return data_type_float32; }
    inline static M_STD_STRING type_str() { return channel_data_type_str( arity(), data_type() ); }
};

template <>
struct channel_data_type_traits<Quat> {
    typedef Point3 value_type;
    inline static size_t arity() { return 4; }
    inline static data_type_t data_type() { return data_type_float32; }
    inline static M_STD_STRING type_str() { return channel_data_type_str( arity(), data_type() ); }
};

} // namespace channels
} // namespace frantic

namespace krakatoa {
namespace max3d {

/**
 * This  class wraps a IMaxKrakatoaPRTObject and caches its data at a specific time in order
 * to adapt the data to the IParticleObjectExt interface.
 */
class PRTParticleObjectExt : public IParticleObjectExt {
    IPRTParticleObjectExtOwner* m_owner;
    TimeValue m_currentTime;
    AnimHandle m_currentNodeHandle;
    int m_currentParticle;

    typedef frantic::particles::particle_array container_type;

    container_type m_particles;

    struct {
        channel_accessor<Point3> pos;
        channel_accessor<Point3> vel;
        channel_accessor<Point3> scaleXYZ;
        channel_accessor<Point3> orientation;

        channel_accessor<AngAxis> spin;

        channel_accessor<float> scale;
        channel_accessor<float> selection;

        channel_accessor<int> id;
        channel_accessor<TimeValue> age;
        channel_accessor<TimeValue> lifespan;
    } m_accessors;

    inline INode* get_current_node() const {
        return m_currentNodeHandle != 0 ? static_cast<INode*>( Animatable::GetAnimByHandle( m_currentNodeHandle ) )
                                        : NULL;
    }

    inline void reset_current_node( INode* node = NULL ) {
        m_currentNodeHandle = node ? Animatable::GetHandleByAnim( node ) : 0;
    }

    char* get_particle_by_id( int id );

    template <class T>
    inline T get_by_index( const channel_accessor<T>& acc, int index, T defaultVal );

    template <class T>
    inline T* get_ptr_by_index( const channel_accessor<T>& acc, int index );

    template <class T>
    inline T get_by_id( const channel_accessor<T>& acc, int id, T defaultVal );

    template <class T>
    inline T* get_ptr_by_id( const channel_accessor<T>& acc, int id );

    template <class T>
    inline void set_by_index( const channel_accessor<T>& acc, int index,
                              typename boost::call_traits<T>::param_type val );

    template <class T>
    inline void set_by_id( const channel_accessor<T>& acc, int id, typename boost::call_traits<T>::param_type val );

  public:
    PRTParticleObjectExt( IPRTParticleObjectExtOwner* pOwner )
        : m_owner( pOwner )
        , m_currentNodeHandle( 0 )
        , m_currentTime( TIME_NegInfinity )
        , m_currentParticle( 0 ) {
        assert( m_owner != NULL );
    }

    virtual ~PRTParticleObjectExt() {}

    // Implemented by the Plug-In.
    // This method is called so the particle system can update its state to reflect
    // the current time passed.  This may involve generating new particle that are born,
    // eliminating old particles that have expired, computing the impact of collisions or
    // force field effects, and modify properties of the particles.
    // Parameters:
    //		TimeValue t
    //			The particles should be updated to reflect this time.
    //		INode *node
    //			This is the emitter node.
    // the method is not exposed in maxscript
    virtual void UpdateParticles( INode* node, TimeValue t );

    // Implemented by the Plug-in
    // Use this method to retrieve time of the current update step. The update time maybe unrelated to
    // the current time of the scene.
    virtual TimeValue GetUpdateTime();
    // Implemented by the Plug-in
    // Use this method to retrieve time interval of the current update step. The update time maybe unrelated to
    // the current time of the scene. The GetUpdateTime method above retrieves the finish time.
    virtual void GetUpdateInterval( TimeValue& start, TimeValue& finish );

    // Implemented by the Plug-In.
    // The method returns how many particles are currently in the particle system.
    // Some of these particles may be dead or not born yet (indicated by GetAge(..) method =-1).
    virtual int NumParticles();

    // Implemented by the Plug-In.
    // Each particle is given a unique ID (consecutive) upon its birth. The method
    // allows us to distinguish physically different particles even if they are using
    // the same particle index (because of the "index reusing").
    // Parameters:
    //		int i
    //			index of the particle in the range of [0, NumParticles-1]
    virtual int GetParticleBornIndex( int i );

    // Implemented by the Plug-In.
    // the methods verifies if a particle with a given particle id (born index) is present
    // in the particle system. The methods returns Particle Group node the particle belongs to,
    // and index in this group. If there is no such particle, the method returns false.
    // Parameters:
    //		int bornIndex
    //			particle born index
    //		INode*& groupNode
    //			particle group the particle belongs to
    //		int index
    //			particle index in the particle group or particle system
    virtual bool HasParticleBornIndex( int bornIndex, int& index );
    virtual INode* GetParticleGroup( int index );
    virtual int GetParticleIndex( int bornIndex );

    // Implemented by the Plug-In.
    // The following four methods define "current" index or bornIndex. This index is used
    // in the property methods below to get the property without specifying the index.
    virtual int GetCurrentParticleIndex();
    virtual int GetCurrentParticleBornIndex();
    virtual void SetCurrentParticleIndex( int index );
    virtual void SetCurrentParticleBornIndex( int bornIndex );

    // Implemented by the Plug-In.
    // The following six methods define age of the specified particle. Particle is specified by either its
    // index in the particle group or particle system, or by its born index
    // if no index is specified then the "current" index is used
    // Parameters:
    //		int id
    //			particle born index
    //		int index
    //			particle index in the particle group
    //		TimeValue age
    //			new age value to set for a particle
    virtual TimeValue GetParticleAgeByIndex( int index );
    virtual TimeValue GetParticleAgeByBornIndex( int id );
    virtual void SetParticleAgeByIndex( int index, TimeValue age );
    virtual void SetParticleAgeByBornIndex( int id, TimeValue age );
    virtual TimeValue GetParticleAge();
    virtual void SetParticleAge( TimeValue age );

    // Implemented by the Plug-In.
    // The following six methods define lifespan of the specified particle. Particle is specified by either its
    // index in the particle group or particle system, or by its born index
    // if no index is specified then the "current" index is used
    // Parameters:
    //		int id
    //			particle born index
    //		int index
    //			particle index in the particle group
    //		TimeValue lifespan
    //			new lifespan value to set for a particle
    virtual TimeValue GetParticleLifeSpanByIndex( int index );
    virtual TimeValue GetParticleLifeSpanByBornIndex( int id );
    virtual void SetParticleLifeSpanByIndex( int index, TimeValue LifeSpan );
    virtual void SetParticleLifeSpanByBornIndex( int id, TimeValue LifeSpan );
    virtual TimeValue GetParticleLifeSpan();
    virtual void SetParticleLifeSpan( TimeValue lifespan );

    // Implemented by the Plug-In.
    // The following six methods define for how long the specified particle was staying in the current
    // particle group. Particle is specified by either its
    // index in the particle group or particle system, or by its born index
    // if no index is specified then the "current" index is used
    // Parameters:
    //		int id
    //			particle born index
    //		int index
    //			particle index in the particle group
    //		TimeValue time
    //			how long particle was staying in the current particle group
    virtual TimeValue GetParticleGroupTimeByIndex( int index );
    virtual TimeValue GetParticleGroupTimeByBornIndex( int id );
    // virtual void SetParticleGroupTimeByIndex(int index, TimeValue time);
    // virtual void SetParticleGroupTimeByBornIndex(int id, TimeValue time);
    virtual TimeValue GetParticleGroupTime();
    // virtual void SetParticleGroupTime(TimeValue time);

    // Implemented by the Plug-In.
    // The following six methods define position of the specified particle in the current state.
    // Particle is specified by either its index in the particle group or particle system, or by its born index
    // if no index is specified then the "current" index is used
    // Parameters:
    //		int id
    //			particle born index
    //		int index
    //			particle index in the particle group
    //		Point3 pos
    //			position of the particle
    virtual Point3* GetParticlePositionByIndex( int index );
    virtual Point3* GetParticlePositionByBornIndex( int id );
    virtual void SetParticlePositionByIndex( int index, Point3 pos );
    virtual void SetParticlePositionByBornIndex( int id, Point3 pos );
    virtual Point3* GetParticlePosition();
    virtual void SetParticlePosition( Point3 pos );

    // Implemented by the Plug-In.
    // The following six methods define speed of the specified particle in the current state.
    // Particle is specified by either its index in the particle group or particle system, or by its born index
    // if no index is specified then the "current" index is used
    // Parameters:
    //		int id
    //			particle born index
    //		int index
    //			particle index in the particle group
    //		Point3 speed
    //			speed of the particle in units per frame
    virtual Point3* GetParticleSpeedByIndex( int index );
    virtual Point3* GetParticleSpeedByBornIndex( int id );
    virtual void SetParticleSpeedByIndex( int index, Point3 speed );
    virtual void SetParticleSpeedByBornIndex( int id, Point3 speed );
    virtual Point3* GetParticleSpeed();
    virtual void SetParticleSpeed( Point3 speed );

    // Implemented by the Plug-In.
    // The following six methods define orientation of the specified particle in the current state.
    // Particle is specified by either its index in the particle group or particle system, or by its born index
    // if no index is specified then the "current" index is used
    // Parameters:
    //		int id
    //			particle born index
    //		int index
    //			particle index in the particle group
    //		Point3 orient
    //			orientation of the particle. The orientation is defined by incremental rotations
    //			by world axes X, Y and Z. The rotation values are in degrees.
    virtual Point3* GetParticleOrientationByIndex( int index );
    virtual Point3* GetParticleOrientationByBornIndex( int id );
    virtual void SetParticleOrientationByIndex( int index, Point3 orient );
    virtual void SetParticleOrientationByBornIndex( int id, Point3 orient );
    virtual Point3* GetParticleOrientation();
    virtual void SetParticleOrientation( Point3 orient );

    // Implemented by the Plug-In.
    // The following six methods define angular speed of the specified particle in the current state.
    // Particle is specified by either its index in the particle group or particle system, or by its born index
    // if no index is specified then the "current" index is used
    // Parameters:
    //		int id
    //			particle born index
    //		int index
    //			particle index in the particle group
    //		AngAxis spin
    //			angular speed of the particle in rotation per frame
    //			axis defines rotation axis, angle defines rotation amount per frame
    virtual AngAxis* GetParticleSpinByIndex( int index );
    virtual AngAxis* GetParticleSpinByBornIndex( int id );
    virtual void SetParticleSpinByIndex( int index, AngAxis spin );
    virtual void SetParticleSpinByBornIndex( int id, AngAxis spin );
    virtual AngAxis* GetParticleSpin();
    virtual void SetParticleSpin( AngAxis spin );

    // Implemented by the Plug-In.
    // The following twelve methods define scale factor of the specified particle in the current state.
    // The XYZ form is used for non-uniform scaling
    // Particle is specified by either its index in the particle group or particle system, or by its born index
    // if no index is specified then the "current" index is used
    // Parameters:
    //		int id
    //			particle born index
    //		int index
    //			particle index in the particle group
    //		float scale
    //			uniform scale factor
    //		Point3 scale
    //			scale factor for each local axis of the particle
    virtual float GetParticleScaleByIndex( int index );
    virtual float GetParticleScaleByBornIndex( int id );
    virtual void SetParticleScaleByIndex( int index, float scale );
    virtual void SetParticleScaleByBornIndex( int id, float scale );
    virtual float GetParticleScale();
    virtual void SetParticleScale( float scale );
    virtual Point3* GetParticleScaleXYZByIndex( int index );
    virtual Point3* GetParticleScaleXYZByBornIndex( int id );
    virtual void SetParticleScaleXYZByIndex( int index, Point3 scale );
    virtual void SetParticleScaleXYZByBornIndex( int id, Point3 scale );
    virtual Point3* GetParticleScaleXYZ();
    virtual void SetParticleScaleXYZ( Point3 scale );

    // Implemented by the Plug-In.
    // The following six methods define selection status of the specified particle in the current state.
    // Particle is specified by either its index in the particle group or particle system, or by its born index
    // if no index is specified then the "current" index is used
    // Parameters:
    //		int id
    //			particle born index
    //		int index
    //			particle index in the particle group
    //		bool selected
    //			selection status of the particle
    virtual bool GetParticleSelectedByIndex( int index );
    virtual bool GetParticleSelectedByBornIndex( int id );
    virtual void SetParticleSelectedByIndex( int index, bool selected );
    virtual void SetParticleSelectedByBornIndex( int id, bool selected );
    virtual bool GetParticleSelected();
    virtual void SetParticleSelected( bool selected );
};

boost::shared_ptr<IParticleObjectExt> CreatePRTParticleObjectExt( IPRTParticleObjectExtOwner* pOwner ) {
    return boost::make_shared<PRTParticleObjectExt>( pOwner );
}

char* PRTParticleObjectExt::get_particle_by_id( int id ) {
    if( m_accessors.id.is_valid() ) {
        for( container_type::iterator it = m_particles.begin(), itEnd = m_particles.end(); it != itEnd; ++it ) {
            if( m_accessors.id( *it ) == id )
                return *it;
        }
    }

    return NULL;
}

template <class T>
T PRTParticleObjectExt::get_by_index( const channel_accessor<T>& acc, int index, T defaultVal ) {
    if( acc.is_valid() && index >= 0 && index < static_cast<int>( m_particles.size() ) )
        return acc( m_particles.at( static_cast<std::size_t>( index ) ) );
    return defaultVal;
}

template <class T>
T* PRTParticleObjectExt::get_ptr_by_index( const channel_accessor<T>& acc, int index ) {
    if( acc.is_valid() && index >= 0 && index < static_cast<int>( m_particles.size() ) )
        return const_cast<T*>( &acc( m_particles.at( static_cast<std::size_t>( index ) ) ) );
    return NULL;
}

template <class T>
T PRTParticleObjectExt::get_by_id( const channel_accessor<T>& acc, int id, T defaultVal ) {
    char* p = get_particle_by_id( id );
    if( acc.is_valid() && p )
        return acc( p );
    return defaultVal;
}

template <class T>
T* PRTParticleObjectExt::get_ptr_by_id( const channel_accessor<T>& acc, int id ) {
    char* p = get_particle_by_id( id );
    if( acc.is_valid() && p != NULL )
        return const_cast<T*>( &acc( p ) );
    return NULL;
}

template <class T>
void PRTParticleObjectExt::set_by_index( const channel_accessor<T>& acc, int index,
                                         typename boost::call_traits<T>::param_type val ) {
    if( acc.is_valid() && index >= 0 && index < static_cast<int>( m_particles.size() ) )
        const_cast<T&>( acc( m_particles.at( static_cast<std::size_t>( index ) ) ) ) = val;
}

template <class T>
void PRTParticleObjectExt::set_by_id( const channel_accessor<T>& acc, int id,
                                      typename boost::call_traits<T>::param_type val ) {
    char* p = get_particle_by_id( id );
    if( acc.is_valid() && p != NULL )
        const_cast<T&>( acc( p ) ) = val;
}

Point3 QuatToEulerDegs( const Quat& q ) { // Quat axis seems to be negated ...
    Point3 result;
    q.GetEuler( &result.x, &result.y, &result.z );
    result.x = RadToDeg( result.x );
    result.y = RadToDeg( result.y );
    result.z = RadToDeg( result.z );
    return result;
}

Point3 SpeedInTicks( const Point3& v ) { return v / (float)TIME_TICKSPERSEC; }

TimeValue SecondsToTicks( float secs ) { return SecToTicks( secs ); }

void PRTParticleObjectExt::UpdateParticles( INode* node, TimeValue t ) {
    // Drop the memory for now.
    m_particles.clear();
    m_currentTime = t;
    m_currentParticle = 0;
    reset_current_node( node );

    // If we've updated to a NULL node, that means we should return.
    if( node == NULL ) {
        channel_map defaultMap;
        defaultMap.define_channel<vector3f>( _T("Position") );
        defaultMap.end_channel_definition();

        m_particles.reset( defaultMap );

        return;
    }

    channel_map defaultMap;
    defaultMap.define_channel<Point3>( _T("Position") );
    defaultMap.define_channel<Point3>( _T("Velocity") );
    // defaultMap.define_channel<Point3>( _T("OrientationXYZ") );
    // defaultMap.define_channel<Point3>( _T("ScaleXYZ") );
    // defaultMap.define_channel<AngAxis>( _T("Spin") );
    defaultMap.define_channel<float>( _T("Selection") );
    defaultMap.define_channel<int>( _T("ID") );
    // defaultMap.define_channel<TimeValue>( _T("AgeTicks") );
    // defaultMap.define_channel<TimeValue>( _T("LifeSpanTicks") );
    defaultMap.end_channel_definition();

    try {
        // This try block is for catching more general errors. There are more specific ones to handle certain calls.

        frantic::graphics::camera<float> defaultCam;

        frantic::max3d::particles::IMaxKrakatoaPRTEvalContextPtr ctx =
            frantic::max3d::particles::CreateMaxKrakatoaPRTEvalContext(
                m_currentTime, Class_ID( 0x5ccc4d89, 0x35345085 ), &defaultCam, &defaultMap );

        particle_istream_ptr pin;

        Interval validInterval = FOREVER;

        try {
            pin = m_owner->create_particle_stream( get_current_node(), validInterval, ctx );

            if( !pin )
                pin.reset( new frantic::particles::streams::empty_particle_istream( defaultMap, defaultMap ) );
        } catch( const std::exception& e ) {
            FF_LOG( debug ) << _T("IParticleObjectExt line ") << __LINE__ << _T(" error evaluating \"")
                            << ( node ? node->GetName() : _T("(null)") ) << _T("\": ") << e.what() << std::endl;

            // We couldn't get the particle stream, so pretend there are no particles.
            pin.reset( new frantic::particles::streams::empty_particle_istream( defaultMap, defaultMap ) );
        }

        const channel_map& nativeMap = pin->get_native_channel_map();

        channel_map newMap;
        newMap.define_channel<Point3>( _T("Position") );
        if( nativeMap.has_channel( _T("VelocityTicks") ) )
            newMap.define_channel<Point3>( _T("VelocityTicks") );
        else if( nativeMap.has_channel( _T("Velocity") ) ) {
            // The documentation for the interface says to return speed in units per frame, but we are matching PFlow w/
            // units per tick.
            const boost::array<M_STD_STRING, 1> INPUTS = { _T("Velocity") };
            pin.reset( new frantic::particles::streams::apply_function_particle_istream<Point3( const Point3& )>(
                pin, &SpeedInTicks, _T("VelocityTicks"), INPUTS ) );
            newMap.define_channel<Point3>( _T("VelocityTicks") );
        }
        if( nativeMap.has_channel( _T("Scale") ) ) {
            if( nativeMap[_T("Scale")].arity() == 3 )
                newMap.define_channel<Point3>( _T("Scale") );
            else
                newMap.define_channel<float>( _T("Scale") );
        }
        if( nativeMap.has_channel( _T("OrientationXYZ") ) )
            newMap.define_channel<Point3>( _T("OrientationXYZ") );
        else if( nativeMap.has_channel( _T("Orientation") ) ) {
            const boost::array<M_STD_STRING, 1> INPUTS = { _T("Orientation") };
            pin.reset( new frantic::particles::streams::apply_function_particle_istream<Point3( const Quat& )>(
                pin, &QuatToEulerDegs, _T("OrientationXYZ"), INPUTS ) );
            newMap.define_channel<Point3>( _T("OrientationXYZ") );
        }
        if( nativeMap.has_channel( _T("Selection") ) )
            newMap.define_channel<float>( _T("Selection") );
        if( nativeMap.has_channel( _T("ID") ) )
            newMap.define_channel<int>( _T("ID") );
        if( nativeMap.has_channel( _T("AgeTicks") ) )
            newMap.define_channel<TimeValue>( _T("AgeTicks") );
        else if( nativeMap.has_channel( _T("Age") ) ) {
            // We initially needed to support both floating point seconds and TimeValue ticks for Age and LifeSpan. We
            // should only ever have float now. Perhaps this can be simplified?
            if( is_channel_data_type_float( nativeMap[_T("Age")].data_type() ) ) {
                const boost::array<M_STD_STRING, 1> INPUTS = { _T("Age") };
                pin.reset( new frantic::particles::streams::apply_function_particle_istream<TimeValue( float )>(
                    pin, &SecondsToTicks, _T("AgeTicks"), INPUTS ) );
                newMap.define_channel<TimeValue>( _T("AgeTicks") );
            } else {
                newMap.define_channel<TimeValue>( _T("Age") );
            }
        }
        if( nativeMap.has_channel( _T("LifeSpan") ) ) {
            // We initially needed to support both floating point seconds and TimeValue ticks for Age and LifeSpan. We
            // should only ever have float now. Perhaps this can be simplified?
            if( is_channel_data_type_float( nativeMap[_T("LifeSpan")].data_type() ) ) {
                const boost::array<M_STD_STRING, 1> INPUTS = { _T("LifeSpan") };
                pin.reset( new frantic::particles::streams::apply_function_particle_istream<TimeValue( float )>(
                    pin, &SecondsToTicks, _T("LifeSpanTicks"), INPUTS ) );
                newMap.define_channel<TimeValue>( _T("LifeSpanTicks") );
            } else {
                newMap.define_channel<TimeValue>( _T("LifeSpan") );
            }
        }
        newMap.end_channel_definition();

        m_accessors.pos = newMap.get_accessor<Point3>( _T("Position") );
        m_accessors.vel = newMap.has_channel( _T("VelocityTicks") ) ? newMap.get_accessor<Point3>( _T("VelocityTicks") )
                                                                    : channel_accessor<Point3>();
        m_accessors.orientation = newMap.has_channel( _T("OrientationXYZ") )
                                      ? newMap.get_accessor<Point3>( _T("OrientationXYZ") )
                                      : channel_accessor<Point3>();
        m_accessors.spin =
            newMap.has_channel( _T("Spin") ) ? newMap.get_accessor<AngAxis>( _T("Spin") ) : channel_accessor<AngAxis>();
        m_accessors.selection = newMap.has_channel( _T("Selection") ) ? newMap.get_accessor<float>( _T("Selection") )
                                                                      : channel_accessor<float>();
        m_accessors.id =
            newMap.has_channel( _T("ID") ) ? newMap.get_accessor<int>( _T("ID") ) : channel_accessor<int>();

        m_accessors.age.reset();
        if( newMap.has_channel( _T("AgeTicks") ) )
            m_accessors.age = newMap.get_accessor<TimeValue>( _T("AgeTicks") );
        else if( newMap.has_channel( _T("Age") ) )
            // If Age was non-TimeValue, then it would have been converted to AgeTicks!
            m_accessors.age = newMap.get_accessor<TimeValue>( _T("Age") );

        m_accessors.lifespan.reset();
        if( newMap.has_channel( _T("LifeSpanTicks") ) )
            m_accessors.lifespan = newMap.get_accessor<TimeValue>( _T("LifeSpanTicks") );
        else if( newMap.has_channel( _T("LifeSpan") ) )
            // If LifeSpan was non-TimeValue, then it would have been converted to LifespanTicks!
            m_accessors.lifespan = newMap.get_accessor<TimeValue>( _T("LifeSpan") );

        m_accessors.scale.reset();
        m_accessors.scaleXYZ.reset();

        if( newMap.has_channel( _T("Scale") ) ) {
            if( newMap[_T("Scale")].arity() == 3 )
                m_accessors.scaleXYZ = newMap.get_accessor<Point3>( _T("Scale") );
            else
                m_accessors.scale = newMap.get_accessor<float>( _T("Scale") );
        }

        m_particles.reset( newMap );

        try {
            m_particles.insert_particles( pin );
        } catch( const std::exception& e ) {
            FF_LOG( debug ) << _T("IParticleObjectExt line ") << __LINE__ << _T(" error evaluating \"")
                            << ( node ? node->GetName() : _T("(null)") ) << _T("\": ") << e.what() << std::endl;

            // Resets the map, and clear any existing particles.
            m_particles.reset( newMap );
        }
    } catch( const std::exception& e ) {
        FF_LOG( debug ) << _T("IParticleObjectExt line ") << __LINE__ << _T(" error evaluating \"")
                        << ( node ? node->GetName() : _T("(null)") ) << _T("\": ") << e.what() << std::endl;

        m_particles.reset( defaultMap );

        m_accessors.pos = defaultMap.get_accessor<Point3>( _T("Position") );
        m_accessors.vel.reset();
        m_accessors.orientation.reset();
        m_accessors.spin.reset();
        m_accessors.selection.reset();
        m_accessors.id.reset();
        m_accessors.age.reset();
        m_accessors.lifespan.reset();
        m_accessors.scale.reset();
        m_accessors.scaleXYZ.reset();
    }
}

TimeValue PRTParticleObjectExt::GetUpdateTime() { return m_currentTime; }

void PRTParticleObjectExt::GetUpdateInterval( TimeValue& start, TimeValue& finish ) {
    start = finish = this->GetUpdateTime();
}

int PRTParticleObjectExt::NumParticles() { return static_cast<int>( m_particles.size() ); }

int PRTParticleObjectExt::GetParticleBornIndex( int i ) { return get_by_index( m_accessors.id, i, -1 ); }

bool PRTParticleObjectExt::HasParticleBornIndex( int bornIndex, int& index ) {
    if( !m_accessors.id.is_valid() )
        return false;

    int counter = 0;
    for( container_type::const_iterator it = m_particles.begin(), itEnd = m_particles.end(); it != itEnd;
         ++it, ++counter ) {
        if( m_accessors.id( *it ) == bornIndex ) {
            index = counter;
            return true;
        }
    }

    return false;
}

INode* PRTParticleObjectExt::GetParticleGroup( int /*index*/ ) { return get_current_node(); }

int PRTParticleObjectExt::GetParticleIndex( int bornIndex ) {
    int result;
    if( this->HasParticleBornIndex( bornIndex, result ) )
        return result;
    return -1;
}

int PRTParticleObjectExt::GetCurrentParticleIndex() { return m_currentParticle; }

int PRTParticleObjectExt::GetCurrentParticleBornIndex() {
    return get_by_index( m_accessors.id, m_currentParticle, -1 );
}

void PRTParticleObjectExt::SetCurrentParticleIndex( int index ) { m_currentParticle = index; }

void PRTParticleObjectExt::SetCurrentParticleBornIndex( int bornIndex ) {
    // This updates the current particle to be the one with the specified ID (if it is found).
    if( !this->HasParticleBornIndex( bornIndex, m_currentParticle ) )
        m_currentParticle = -1;
}

TimeValue PRTParticleObjectExt::GetParticleAgeByIndex( int index ) { return get_by_index( m_accessors.age, index, 0 ); }

TimeValue PRTParticleObjectExt::GetParticleAgeByBornIndex( int id ) { return get_by_id( m_accessors.age, id, 0 ); }

void PRTParticleObjectExt::SetParticleAgeByIndex( int index, TimeValue age ) {
    set_by_index( m_accessors.age, index, age );
}

void PRTParticleObjectExt::SetParticleAgeByBornIndex( int id, TimeValue age ) { set_by_id( m_accessors.age, id, age ); }

TimeValue PRTParticleObjectExt::GetParticleAge() { return get_by_index( m_accessors.age, m_currentParticle, 0 ); }

void PRTParticleObjectExt::SetParticleAge( TimeValue age ) { set_by_index( m_accessors.age, m_currentParticle, age ); }

TimeValue PRTParticleObjectExt::GetParticleLifeSpanByIndex( int index ) {
    return get_by_index( m_accessors.lifespan, index, TIME_PosInfinity );
}

TimeValue PRTParticleObjectExt::GetParticleLifeSpanByBornIndex( int id ) {
    return get_by_id( m_accessors.lifespan, id, TIME_PosInfinity );
}

void PRTParticleObjectExt::SetParticleLifeSpanByIndex( int index, TimeValue lifespan ) {
    set_by_index( m_accessors.lifespan, index, lifespan );
}

void PRTParticleObjectExt::SetParticleLifeSpanByBornIndex( int id, TimeValue lifespan ) {
    set_by_id( m_accessors.lifespan, id, lifespan );
}

TimeValue PRTParticleObjectExt::GetParticleLifeSpan() {
    return get_by_index( m_accessors.lifespan, m_currentParticle, TIME_PosInfinity );
}

void PRTParticleObjectExt::SetParticleLifeSpan( TimeValue lifespan ) {
    set_by_index( m_accessors.lifespan, m_currentParticle, lifespan );
}

TimeValue PRTParticleObjectExt::GetParticleGroupTimeByIndex( int index ) {
    return get_by_index( m_accessors.age, index, 0 );
}

TimeValue PRTParticleObjectExt::GetParticleGroupTimeByBornIndex( int id ) {
    return get_by_id( m_accessors.age, id, 0 );
}

TimeValue PRTParticleObjectExt::GetParticleGroupTime() { return get_by_index( m_accessors.age, m_currentParticle, 0 ); }

Point3* PRTParticleObjectExt::GetParticlePositionByIndex( int index ) {
    return get_ptr_by_index( m_accessors.pos, index );
}

Point3* PRTParticleObjectExt::GetParticlePositionByBornIndex( int id ) { return get_ptr_by_id( m_accessors.pos, id ); }

void PRTParticleObjectExt::SetParticlePositionByIndex( int index, Point3 pos ) {
    set_by_index( m_accessors.pos, index, pos );
}

void PRTParticleObjectExt::SetParticlePositionByBornIndex( int id, Point3 pos ) {
    set_by_id( m_accessors.pos, id, pos );
}

Point3* PRTParticleObjectExt::GetParticlePosition() { return get_ptr_by_index( m_accessors.pos, m_currentParticle ); }

void PRTParticleObjectExt::SetParticlePosition( Point3 pos ) {
    set_by_index( m_accessors.pos, m_currentParticle, pos );
}

Point3* PRTParticleObjectExt::GetParticleSpeedByIndex( int index ) {
    return get_ptr_by_index( m_accessors.vel, index );
}

Point3* PRTParticleObjectExt::GetParticleSpeedByBornIndex( int id ) { return get_ptr_by_id( m_accessors.vel, id ); }

void PRTParticleObjectExt::SetParticleSpeedByIndex( int index, Point3 speed ) {
    set_by_index( m_accessors.vel, index, speed );
}

void PRTParticleObjectExt::SetParticleSpeedByBornIndex( int id, Point3 speed ) {
    set_by_id( m_accessors.vel, id, speed );
}

Point3* PRTParticleObjectExt::GetParticleSpeed() { return get_ptr_by_index( m_accessors.vel, m_currentParticle ); }

void PRTParticleObjectExt::SetParticleSpeed( Point3 speed ) {
    set_by_index( m_accessors.vel, m_currentParticle, speed );
}

Point3* PRTParticleObjectExt::GetParticleOrientationByIndex( int index ) {
    return get_ptr_by_index( m_accessors.orientation, index );
}

Point3* PRTParticleObjectExt::GetParticleOrientationByBornIndex( int id ) {
    return get_ptr_by_id( m_accessors.orientation, id );
}

void PRTParticleObjectExt::SetParticleOrientationByIndex( int index, Point3 orient ) {
    set_by_index( m_accessors.orientation, index, orient );
}

void PRTParticleObjectExt::SetParticleOrientationByBornIndex( int id, Point3 orient ) {
    set_by_id( m_accessors.orientation, id, orient );
}

Point3* PRTParticleObjectExt::GetParticleOrientation() {
    return get_ptr_by_index( m_accessors.orientation, m_currentParticle );
}

void PRTParticleObjectExt::SetParticleOrientation( Point3 orient ) {
    set_by_index( m_accessors.orientation, m_currentParticle, orient );
}

AngAxis* PRTParticleObjectExt::GetParticleSpinByIndex( int index ) {
    return get_ptr_by_index( m_accessors.spin, index );
}

AngAxis* PRTParticleObjectExt::GetParticleSpinByBornIndex( int id ) { return get_ptr_by_id( m_accessors.spin, id ); }

void PRTParticleObjectExt::SetParticleSpinByIndex( int index, AngAxis spin ) {
    set_by_index( m_accessors.spin, index, spin );
}

void PRTParticleObjectExt::SetParticleSpinByBornIndex( int id, AngAxis spin ) {
    set_by_id( m_accessors.spin, id, spin );
}

AngAxis* PRTParticleObjectExt::GetParticleSpin() { return get_ptr_by_index( m_accessors.spin, m_currentParticle ); }

void PRTParticleObjectExt::SetParticleSpin( AngAxis spin ) {
    set_by_index( m_accessors.spin, m_currentParticle, spin );
}

float PRTParticleObjectExt::GetParticleScaleByIndex( int index ) {
    if( m_accessors.scaleXYZ.is_valid() )
        return get_by_index( m_accessors.scaleXYZ, index, Point3( 1.f, 1.f, 1.f ) ).x;
    return get_by_index( m_accessors.scale, index, 1.f );
}

float PRTParticleObjectExt::GetParticleScaleByBornIndex( int id ) {
    if( m_accessors.scaleXYZ.is_valid() )
        return get_by_id( m_accessors.scaleXYZ, id, Point3( 1.f, 1.f, 1.f ) ).x;
    return get_by_id( m_accessors.scale, id, 1.f );
}

void PRTParticleObjectExt::SetParticleScaleByIndex( int index, float scale ) {
    if( m_accessors.scaleXYZ.is_valid() )
        set_by_index( m_accessors.scaleXYZ, index, Point3( scale, scale, scale ) );
    return set_by_index( m_accessors.scale, index, scale );
}

void PRTParticleObjectExt::SetParticleScaleByBornIndex( int id, float scale ) {
    if( m_accessors.scaleXYZ.is_valid() )
        set_by_id( m_accessors.scaleXYZ, id, Point3( scale, scale, scale ) );
    return set_by_id( m_accessors.scale, id, scale );
}

float PRTParticleObjectExt::GetParticleScale() {
    if( m_accessors.scaleXYZ.is_valid() )
        return get_by_index( m_accessors.scaleXYZ, m_currentParticle, Point3( 1.f, 1.f, 1.f ) ).x;
    return get_by_index( m_accessors.scale, m_currentParticle, 1.f );
}

void PRTParticleObjectExt::SetParticleScale( float scale ) {
    if( m_accessors.scaleXYZ.is_valid() )
        set_by_index( m_accessors.scaleXYZ, m_currentParticle, Point3( scale, scale, scale ) );
    return set_by_index( m_accessors.scale, m_currentParticle, scale );
}

Point3* PRTParticleObjectExt::GetParticleScaleXYZByIndex( int index ) {
    return get_ptr_by_index( m_accessors.scaleXYZ, index );
}

Point3* PRTParticleObjectExt::GetParticleScaleXYZByBornIndex( int id ) {
    return get_ptr_by_id( m_accessors.scaleXYZ, id );
}

void PRTParticleObjectExt::SetParticleScaleXYZByIndex( int index, Point3 scale ) {
    set_by_index( m_accessors.scaleXYZ, index, scale );
}

void PRTParticleObjectExt::SetParticleScaleXYZByBornIndex( int id, Point3 scale ) {
    set_by_id( m_accessors.scaleXYZ, id, scale );
}

Point3* PRTParticleObjectExt::GetParticleScaleXYZ() {
    return get_ptr_by_index( m_accessors.scaleXYZ, m_currentParticle );
}

void PRTParticleObjectExt::SetParticleScaleXYZ( Point3 scale ) {
    set_by_index( m_accessors.scaleXYZ, m_currentParticle, scale );
}

bool PRTParticleObjectExt::GetParticleSelectedByIndex( int index ) {
    return get_by_index( m_accessors.selection, index, 0.f ) != 0.f;
}

bool PRTParticleObjectExt::GetParticleSelectedByBornIndex( int id ) {
    return get_by_id( m_accessors.selection, id, 0.f ) != 0.f;
}

void PRTParticleObjectExt::SetParticleSelectedByIndex( int index, bool selected ) {
    set_by_index( m_accessors.selection, index, selected ? 1.f : 0.f );
}

void PRTParticleObjectExt::SetParticleSelectedByBornIndex( int id, bool selected ) {
    set_by_id( m_accessors.selection, id, selected ? 1.f : 0.f );
}

bool PRTParticleObjectExt::GetParticleSelected() {
    return get_by_index( m_accessors.selection, m_currentParticle, 0.f ) != 0.f;
}

void PRTParticleObjectExt::SetParticleSelected( bool selected ) {
    set_by_index( m_accessors.selection, m_currentParticle, selected ? 1.f : 0.f );
}

} // namespace max3d
} // namespace krakatoa
