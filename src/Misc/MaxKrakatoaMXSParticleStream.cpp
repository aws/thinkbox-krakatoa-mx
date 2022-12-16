// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0
#include "stdafx.h"

#include "Misc\MaxKrakatoaMXSParticleStream.h"

#include <frantic/max3d/maxscript/maxscript.hpp>
#include <frantic/max3d/units.hpp>

#include <frantic/particles/particle_file_stream_factory.hpp>

template <class T>
struct write_float_value {
    static void apply( void* pDest_, Value* src, std::size_t arity ) {
        T* pDest = static_cast<T*>( pDest_ );

        try {
            if( is_array( src ) && static_cast<std::size_t>( static_cast<Array*>( src )->size ) == arity ) {
                for( std::size_t i = 0, iEnd = arity; i < iEnd; ++i )
                    pDest[i] = static_cast<T>( static_cast<Array*>( src )->data[i]->to_float() );
            } else {
                switch( arity ) {
                case 1u:
                    pDest[0] = static_cast<T>( src->to_float() );
                    break;
                case 2u: {
                    Point2 val = src->to_point2();
                    pDest[0] = static_cast<T>( val.x );
                    pDest[1] = static_cast<T>( val.y );
                } break;
                case 3u: {
                    Point3 val;
                    if( is_color( src ) )
                        val = static_cast<Point3>( static_cast<ColorValue*>( src )->to_color() );
                    else
                        val = src->to_point3();
                    pDest[0] = static_cast<T>( val.x );
                    pDest[1] = static_cast<T>( val.y );
                    pDest[2] = static_cast<T>( val.z );
                } break;
                case 4u: {
                    Point4 val;
                    if( is_color( src ) )
                        val = static_cast<Point3>( src->to_point4() );
                    else if( is_quat( src ) ) {
                        Quat q = src->to_quat();
                        val.x = q.x;
                        val.y = q.y;
                        val.z = q.z;
                        val.w = q.w;
                    } else if( is_angaxis( src ) ) {
                        AngAxis a = src->to_angaxis();
                        val.x = a.axis.x;
                        val.y = a.axis.y;
                        val.z = a.axis.z;
                        val.w = -a.angle;
                    } else
                        val = src->to_point4();
                    pDest[0] = static_cast<T>( val.x );
                    pDest[1] = static_cast<T>( val.y );
                    pDest[2] = static_cast<T>( val.z );
                    pDest[3] = static_cast<T>( val.w );
                } break;
                default:
                    throw ConversionError( src, _M( "Array" ) );
                }
            }
        } catch( MAXScriptException& e ) {
            throw MAXException( const_cast<TCHAR*>( frantic::max3d::mxs::to_string( e ).c_str() ) );
        }
    }
};

template <class T>
struct write_int_value {
    static void apply( void* pDest_, Value* src, std::size_t arity ) {
        T* pDest = static_cast<T*>( pDest_ );

        try {
            if( is_array( src ) && static_cast<std::size_t>( static_cast<Array*>( src )->size ) == arity ) {
                for( std::size_t i = 0, iEnd = arity; i < iEnd; ++i )
                    pDest[i] = static_cast<T>( static_cast<Array*>( src )->data[i]->to_int() );
            } else {
                switch( arity ) {
                case 1u:
                    pDest[0] = static_cast<T>( src->to_int() );
                    break;
                case 2u: {
                    IPoint2 val = to_ipoint2( src );
                    pDest[0] = static_cast<T>( val.x );
                    pDest[1] = static_cast<T>( val.y );
                } break;
                case 3u: {
                    IPoint3 val = to_ipoint3( src );
                    pDest[0] = static_cast<T>( val.x );
                    pDest[1] = static_cast<T>( val.y );
                    pDest[2] = static_cast<T>( val.z );
                } break;
                default:
                    throw ConversionError( src, _M( "Array" ) );
                }
            }
        } catch( MAXScriptException& e ) {
            throw MAXException( const_cast<TCHAR*>( frantic::max3d::mxs::to_string( e ).c_str() ) );
        }
    }
};

KrakatoaParticleOStream::KrakatoaParticleOStream( const frantic::tstring& path,
                                                  const frantic::channels::channel_map& outMap )
    : m_isOpen( false ) {
    frantic::particles::particle_file_stream_factory_object factory;
    factory.set_coordinate_system( frantic::graphics::coordinate_system::right_handed_zup );
    factory.set_length_unit_in_meters( frantic::max3d::get_scale_to_meters() );
    factory.set_frame_rate( GetFrameRate(), 1 );

    // TODO: Add a scale option (or more general transformation option) to the factory.

    frantic::channels::channel_map fileMap;
    for( std::size_t i = 0, iEnd = outMap.channel_count(); i < iEnd; ++i ) {
        const frantic::channels::channel& ch = outMap[i];

        switch( ch.data_type() ) {
        case frantic::channels::data_type_float16:
            m_writeFunctions.push_back( &write_float_value<half>::apply );
            break;
        case frantic::channels::data_type_float32:
            m_writeFunctions.push_back( &write_float_value<float>::apply );
            break;
        case frantic::channels::data_type_float64:
            m_writeFunctions.push_back( &write_float_value<double>::apply );
            break;
        case frantic::channels::data_type_int8:
            m_writeFunctions.push_back( &write_int_value<boost::int8_t>::apply );
            break;
        case frantic::channels::data_type_int16:
            m_writeFunctions.push_back( &write_int_value<boost::int16_t>::apply );
            break;
        case frantic::channels::data_type_int32:
            m_writeFunctions.push_back( &write_int_value<boost::int32_t>::apply );
            break;
        case frantic::channels::data_type_int64:
            m_writeFunctions.push_back( &write_int_value<boost::int64_t>::apply );
            break;
        case frantic::channels::data_type_uint8:
            m_writeFunctions.push_back( &write_int_value<boost::uint8_t>::apply );
            break;
        case frantic::channels::data_type_uint16:
            m_writeFunctions.push_back( &write_int_value<boost::uint16_t>::apply );
            break;
        case frantic::channels::data_type_uint32:
            m_writeFunctions.push_back( &write_int_value<boost::uint32_t>::apply );
            break;
        case frantic::channels::data_type_uint64:
            m_writeFunctions.push_back( &write_int_value<boost::uint64_t>::apply );
            break;
        default: {
            MSTR errString;
            errString.printf( _T("Invalid data type \"%s\""), ch.type_str().c_str() );

            throw MAXException( errString.data() );
        }
        }

        fileMap.define_channel( ch.name(), ch.arity(), ch.data_type() );
    }
    fileMap.end_channel_definition( 1u, false, true );

    m_pImpl = factory.create_ostream( path, outMap, fileMap );
    m_isOpen = true;
}

KrakatoaParticleOStream::ThisInterfaceDesc* KrakatoaParticleOStream::GetDesc() {
    static ThisInterfaceDesc theDesc( Interface_ID( 0x216e4240, 0x6cf74e39 ), _T("KrakatoaParticleOStream") );

    if( theDesc.empty() ) {
        theDesc.function( _T("Close"), &KrakatoaParticleOStream::close );
        theDesc.function( _T("WriteParticle"), &KrakatoaParticleOStream::write_particle )
            .param( _T("ParticleDataArray") );
    }

    return &theDesc;
}

void KrakatoaParticleOStream::close() {
    m_isOpen = false;
    m_pImpl->close();
    m_pImpl.reset();
}

void KrakatoaParticleOStream::write_particle( Value* pParticleValue ) {
    if( !m_isOpen )
        throw MAXException( _T("WriteParticle cannot be called on a closed stream") );

    if( !is_array( pParticleValue ) )
        throw MAXException( _T("WriteParticle expected an array argument") );

    const frantic::channels::channel_map& map = m_pImpl->get_channel_map();

    Array* pParticleArray = static_cast<Array*>( pParticleValue );
    if( static_cast<std::size_t>( pParticleArray->size ) != map.channel_count() )
        throw MAXException( const_cast<TCHAR*>(
            ( _T("WriteParticle an array of size ") + boost::lexical_cast<frantic::tstring>( map.channel_count() ) )
                .c_str() ) );

    char* buffer = static_cast<char*>( alloca( map.structure_size() ) );

    for( int i = 0, iEnd = pParticleArray->size; i < iEnd; ++i ) {
        const frantic::channels::channel& ch = map[static_cast<std::size_t>( i )];

        m_writeFunctions[i]( ch.get_channel_data_pointer( buffer ), pParticleArray->data[i], ch.arity() );
    }

    m_pImpl->put_particle( buffer );
}

template <class T>
struct read_float_to_maxscript {
    static Value* apply( const void* pSrc_, std::size_t arity ) {
        one_value_local( pResult );

        const T* pSrc = static_cast<const T*>( pSrc_ );

        switch( arity ) {
        case 1u:
            vl.pResult = new Float( static_cast<float>( pSrc[0] ) );
            break;
        case 3u:
            vl.pResult = new Point3Value( static_cast<float>( pSrc[0] ), static_cast<float>( pSrc[1] ),
                                          static_cast<float>( pSrc[2] ) );
            break;
        default:
            vl.pResult = new Array( static_cast<int>( arity ) );
            for( std::size_t i = 0; i < arity; ++i )
                static_cast<Array*>( vl.pResult )->append( new Float( static_cast<float>( pSrc[i] ) ) );
            break;
        }

        return_value( vl.pResult );
    };
};

template <class T>
struct int_to_value {
    inline static Value* apply( T val ) { return new Integer( static_cast<int>( val ) ); }
};

template <>
struct int_to_value<boost::int64_t> {
    inline static Value* apply( boost::int64_t val ) { return new Integer64( val ); }
};

template <class T>
struct read_int_to_maxscript {
    static Value* apply( const void* pSrc_, std::size_t arity ) {
        one_value_local( pResult );

        const T* pSrc = static_cast<const T*>( pSrc_ );

        switch( arity ) {
        case 1u:
            vl.pResult = int_to_value<T>::apply( pSrc[0] );
            break;
        default:
            vl.pResult = new Array( static_cast<int>( arity ) );
            for( std::size_t i = 0; i < arity; ++i )
                static_cast<Array*>( vl.pResult )->append( int_to_value<T>::apply( pSrc[i] ) );
            break;
        }

        return_value( vl.pResult );
    };
};

KrakatoaParticleIStream::KrakatoaParticleIStream( frantic::particles::particle_istream_ptr pStream )
    : m_isOpen( false )
    , m_pImpl( pStream ) {
    const frantic::channels::channel_map& map = m_pImpl->get_channel_map();

    for( std::size_t i = 0, iEnd = map.channel_count(); i < iEnd; ++i ) {
        const frantic::channels::channel& ch = map[i];

        // This should be less painful (possibly using MSTR::ToMCHAR, except its not well documented whether the result
        // is a copy or not!).
        MSTR channelString;

        channelString.printf( _T("%s %s[%d]"), ch.name().c_str(),
                              frantic::channels::channel_data_type_str( ch.data_type() ), ch.arity() );

        m_channelStrings.push_back( channelString );

        switch( ch.data_type() ) {
        case frantic::channels::data_type_float16:
            m_readFunctions.push_back( &read_float_to_maxscript<half>::apply );
            break;
        case frantic::channels::data_type_float32:
            m_readFunctions.push_back( &read_float_to_maxscript<float>::apply );
            break;
        case frantic::channels::data_type_float64:
            m_readFunctions.push_back( &read_float_to_maxscript<double>::apply );
            break;
        case frantic::channels::data_type_int8:
            m_readFunctions.push_back( &read_int_to_maxscript<boost::int8_t>::apply );
            break;
        case frantic::channels::data_type_int16:
            m_readFunctions.push_back( &read_int_to_maxscript<boost::int16_t>::apply );
            break;
        case frantic::channels::data_type_int32:
            m_readFunctions.push_back( &read_int_to_maxscript<boost::int32_t>::apply );
            break;
        case frantic::channels::data_type_int64:
            m_readFunctions.push_back( &read_int_to_maxscript<boost::int64_t>::apply );
            break;
        case frantic::channels::data_type_uint8:
            m_readFunctions.push_back( &read_int_to_maxscript<boost::uint8_t>::apply );
            break;
        case frantic::channels::data_type_uint16:
            m_readFunctions.push_back( &read_int_to_maxscript<boost::uint16_t>::apply );
            break;
        case frantic::channels::data_type_uint32:
            m_readFunctions.push_back( &read_int_to_maxscript<boost::uint32_t>::apply );
            break;
        case frantic::channels::data_type_uint64:
            m_readFunctions.push_back( &read_int_to_maxscript<boost::uint64_t>::apply );
            break;
        default: {
            MSTR errString;
            errString.printf( _T("Invalid data type \"%s\""), ch.type_str().c_str() );

            throw MAXException( errString.data() );
        }
        }
    }

    m_isOpen = true;
}

boost::int64_t KrakatoaParticleIStream::get_count() {
    if( !m_isOpen )
        return 0;
    return m_pImpl->particle_count();
}

TYPE_STRING_TAB_BV_TYPE KrakatoaParticleIStream::get_channels() {
    TYPE_STRING_TAB_BV_TYPE result;

    if( m_isOpen ) {
        result.SetCount( static_cast<int>( m_channelStrings.size() ) );

        for( std::size_t i = 0, iEnd = m_channelStrings.size(); i < iEnd; ++i )
            result[i] = const_cast<TYPE_STRING_TYPE>( m_channelStrings[i].data() );
    }

    return result;
}

void KrakatoaParticleIStream::close() {
    if( m_isOpen ) {
        m_isOpen = false;
        m_pImpl->close();
        m_pImpl.reset();
    }
}

void KrakatoaParticleIStream::skip_particles( int numParticlesToSkip ) {
    if( m_isOpen ) {
        char* buffer = static_cast<char*>( alloca( m_pImpl->get_channel_map().structure_size() ) );
        while( numParticlesToSkip > 0 && m_pImpl->get_particle( buffer ) )
            --numParticlesToSkip;
    }
}

Value* KrakatoaParticleIStream::read_particle() {
    if( !m_isOpen )
        return &undefined;

    const frantic::channels::channel_map& map = m_pImpl->get_channel_map();

    char* buffer = static_cast<char*>( alloca( map.structure_size() ) );

    if( !m_pImpl->get_particle( buffer ) )
        return &undefined;

    one_typed_value_local( Array * pResult );

    vl.pResult = new Array( static_cast<int>( map.channel_count() ) );

    for( std::size_t i = 0, iEnd = map.channel_count(); i < iEnd; ++i ) {
        const frantic::channels::channel& ch = map[i];
        const char* pData = ch.get_channel_data_pointer( buffer );
        std::size_t arity = ch.arity();

        vl.pResult->append( m_readFunctions[i]( pData, arity ) );
    }

    return_value( vl.pResult );
}

KrakatoaParticleIStream::ThisInterfaceDesc* KrakatoaParticleIStream::GetDesc() {
    static ThisInterfaceDesc theDesc( Interface_ID( 0x3878463b, 0xd0a1409 ), _T("KrakatoaParticleIStream") );

    if( theDesc.empty() ) {
        theDesc.function( _T("GetCount"), &KrakatoaParticleIStream::get_count );
        theDesc.function( _T("GetChannels"), &KrakatoaParticleIStream::get_channels );
        theDesc.function( _T("Close"), &KrakatoaParticleIStream::close );
        theDesc.function( _T("ReadParticle"), &KrakatoaParticleIStream::read_particle );
        theDesc.function( _T("SkipParticles"), &KrakatoaParticleIStream::skip_particles ).param( _T("NumToSkip") );
    }

    return &theDesc;
}
