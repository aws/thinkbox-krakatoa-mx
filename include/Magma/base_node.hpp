// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0
#pragma once

#include <frantic/channels/channel_operation_compiler.hpp>
#include <frantic/max3d/fpwrapper/max_typetraits.hpp>

namespace magma {

using frantic::channels::channel_compiler_error;

class base_node {
    Array* properties;
    Array* connections;

  public:
    enum node_type { type_output, type_input, type_operator, type_unknown };

  public:
    int id;
    node_type type;
    bool disabled;

  private:
    static node_type parse_node_type( const std::string& typeString ) {
        if( typeString == "Output" )
            return type_output;
        if( typeString == "Input" )
            return type_input;
        if( typeString == "Operator" )
            return type_operator;
        return type_unknown;
    }

  public:
    base_node()
        : properties( NULL )
        , connections( NULL ) {}

    void reset( Value* pNode, int _id ) {
        id = _id;
        type = type_unknown;
        properties = NULL;
        connections = NULL;
        disabled = false;

        if( !pNode || !is_array( pNode ) )
            throw channel_compiler_error( id, "Malformed Magma Node. Expected an array" );

        Array* pNodeAsArray = static_cast<Array*>( pNode );
        if( pNodeAsArray->size != 5 )
            throw channel_compiler_error( id, "Malformed Magma Node. Expected an array with 5 elements, got " +
                                                  boost::lexical_cast<std::string>( pNodeAsArray->size ) );
        if( !is_string( pNodeAsArray->get( 1 + 0 ) ) )
            throw channel_compiler_error( id, "Malformed Magma Node. Expected a String in element 1" );
        if( !is_array( pNodeAsArray->get( 1 + 1 ) ) )
            throw channel_compiler_error( id, "Malformed Magma Node. Expected an Array in element 2" );
        if( !is_array( pNodeAsArray->get( 1 + 2 ) ) )
            throw channel_compiler_error( id, "Malformed Magma Node. Expected an Array in element 3" );
        if( !is_array( pNodeAsArray->get( 1 + 3 ) ) )
            throw channel_compiler_error( id, "Malformed Magma Node. Expected an Array in element 4" );
        if( !is_bool( pNodeAsArray->get( 1 + 4 ) ) )
            throw channel_compiler_error( id, "Malformed Magma Node. Expected a Bool in element 5" );

        type = parse_node_type( frantic::strings::to_string( pNodeAsArray->get( 1 + 0 )->to_string() ) );
        properties = static_cast<Array*>( pNodeAsArray->get( 1 + 2 ) );
        connections = static_cast<Array*>( pNodeAsArray->get( 1 + 1 ) );
        disabled = ( pNodeAsArray->get( 1 + 4 )->to_bool() == FALSE );
    }

    int property_count() const { return properties ? properties->size : 0; }

    int connection_count() const { return connections ? connections->size : 0; }

    template <class T>
    T get_property( int index ) const {
        Value* prop = NULL;
        if( properties && index < properties->size )
            prop = properties->get( 1 + index );

        if( !prop )
            throw channel_compiler_error( id, "Missing property #" + boost::lexical_cast<std::string>( 1 + index ) );

        return frantic::max3d::fpwrapper::MaxTypeTraits<T>::FromValue( prop );
    }

#ifdef _UNICODE
    template <>
    std::string get_property<std::string>( int index ) const {
        Value* prop = NULL;
        if( properties && index < properties->size )
            prop = properties->get( 1 + index );

        if( !prop )
            throw channel_compiler_error( id, "Missing property #" + boost::lexical_cast<std::string>( 1 + index ) );

        return frantic::strings::to_string( frantic::max3d::fpwrapper::MaxTypeTraits<std::wstring>::FromValue( prop ) );
    }
#endif

    int get_connection( int index ) const {
        Value* conn = NULL;
        if( connections && index < connections->size )
            conn = connections->get( 1 + index );

        if( !conn )
            throw channel_compiler_error( id, "Missing connection #" + boost::lexical_cast<std::string>( 1 + index ) );

        return conn->to_int() - 1;
    }
};

} // namespace magma
