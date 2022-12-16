// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0
#include "stdafx.h"

#include "Magma/nodes/magma_texmap_op_node.hpp"

#include <frantic/magma/max3d/MagmaMaxContext.hpp>
#include <frantic/magma/max3d/MagmaTexmapExpression.hpp>
#include <frantic/magma/max3d/magma_max_node_impl.hpp>

#include <frantic/magma/simple_compiler/simple_particle_compiler.hpp>

#include <frantic/max3d/convert.hpp>
#include <frantic/max3d/particles/IMaxKrakatoaPRTObject.hpp>
#include <frantic/max3d/shaders/map_query.hpp>

#include <boost/algorithm/string/predicate.hpp>

using frantic::graphics::vector3f;
using frantic::magma::max3d::MagmaTexmapExpression;
using frantic::magma::simple_compiler::base_compiler;

namespace frantic {
namespace magma {
namespace nodes {
namespace max3d {

MAGMA_DEFINE_MAX_TYPE( "InputTexmap", "Input", magma_texmap_op_node )
MAGMA_ENUM_PROPERTY( resultType, "Color", "Mono", "Perturb" )
MAGMA_EXPOSE_PROPERTY( texmap, Texmap* )
MAGMA_EXPOSE_PROPERTY( channels, std::vector<frantic::tstring> )
MAGMA_DESCRIPTION( "Evaluates a texture map." )
MAGMA_DEFINE_TYPE_END

void magma_texmap_op_node::max_impl::DefineParameters( ParamBlockDesc2& paramDesc ) {
    paramDesc.AddParam( kTexmap, _T("texmap"), TYPE_TEXMAP, 0, 0, p_end );
}

magma_texmap_op_node::magma_texmap_op_node() { set_resultType( _T("Color") ); }

MSTR magma_texmap_op_node::max_impl::s_ClassName( _T("MagmaEvalTexmapNode") );
Class_ID magma_texmap_op_node::max_impl::s_ClassID( 0x55154eba, 0x35b03c52 );

inline const magma_texmap_op_node::channel_data*
magma_texmap_op_node::find_channel( const frantic::tstring& name ) const {
    std::vector<channel_data>::const_iterator it = m_inputs.begin();
    std::vector<channel_data>::const_iterator itEnd = m_inputs.end();

    for( ; it != itEnd && it->name != name; ++it )
        ;

    return it != itEnd ? &*it : NULL;
}

void magma_texmap_op_node::compile_as_extension_type( frantic::magma::magma_compiler_interface& compiler ) {
    Texmap* texmap = get_texmap();
    if( !texmap )
        throw magma_exception() << magma_exception::node_id( get_id() )
                                << magma_exception::property_name( _T("texmap") )
                                << magma_exception::error_name( _T("The texmap was undefined or deleted") );

    MagmaTexmapExpression::result_type::enum_t resultType =
        MagmaTexmapExpression::result_type::from_string( get_resultType() );
    if( resultType == MagmaTexmapExpression::result_type::error )
        throw magma_exception() << magma_exception::node_id( get_id() )
                                << magma_exception::property_name( _T("resultType") )
                                << magma_exception::error_name( _T("The result type \"") + get_resultType() +
                                                                _T("\" was unknown") );

    TimeValue t = TIME_NegInfinity;
    compiler.get_context_data().get_property( _T("Time"), t );

    RenderGlobalContext* globContext = NULL;
    compiler.get_context_data().get_property( _T("MaxRenderGlobalContext"), globContext );

    INode* curNode = NULL;
    compiler.get_context_data().get_property( _T("CurrentINode"), curNode );

    bool inWorldSpace = true;
    compiler.get_context_data().get_property( _T("InWorldSpace"), inWorldSpace );

    if( frantic::magma::simple_compiler::simple_particle_compiler* sc =
            dynamic_cast<frantic::magma::simple_compiler::simple_particle_compiler*>( &compiler ) ) {
        std::auto_ptr<MagmaTexmapExpression> expr(
            new MagmaTexmapExpression( texmap, globContext, NULL, curNode, inWorldSpace, resultType ) );

        std::vector<std::pair<magma_interface::magma_id, int>> inputs;
        std::vector<magma_data_type> inputTypes;
        // Just used to keep track of how many sockets came before the TextureCoord socket if one exists in-case we have
        // to throw an error.
        int socketCount = 0;
        if( const channel_data* cd = find_channel( _T("Position") ) ) {
            inputs.push_back( cd->socket );
            ++socketCount;
        } else {
            inputs.push_back( sc->compile_default_input_channel( _T("Position"),
                                                                 magma_singleton::get_named_data_type( _T("Vec3") ) ) );
        }
        inputTypes.push_back( *magma_singleton::get_named_data_type( _T("Vec3") ) );

        if( const channel_data* cd = find_channel( _T("Color") ) ) {
            inputs.push_back( cd->socket );
            ++socketCount;
        } else if( sc->get_native_channel_map().has_channel( _T("Color") ) ) {
            inputs.push_back(
                sc->compile_default_input_channel( _T("Color"), magma_singleton::get_named_data_type( _T("Vec3") ) ) );
        } else {
            inputs.push_back( sc->compile_constant( vec3( 0, 0, 0 ) ) );
        }
        inputTypes.push_back( *magma_singleton::get_named_data_type( _T("Vec3") ) );

        if( const channel_data* cd = find_channel( _T("TextureCoord") ) ) {
            if( cd->socket.first < 0 ) {
                throw magma_exception() << magma_exception::node_id( get_id() )
                                        << magma::magma_exception::input_index( socketCount )
                                        << magma_exception::error_name( _T( "Unconnected Input Socket" ) );
            }
            inputs.push_back( cd->socket );
        } else if( sc->get_native_channel_map().has_channel( _T("TextureCoord") ) ) {
            inputs.push_back( sc->compile_default_input_channel( _T("TextureCoord"),
                                                                 magma_singleton::get_named_data_type( _T("Vec3") ) ) );
        } else {
            inputs.push_back( sc->compile_constant( vec3( 0, 0, 0 ) ) );
        }
        inputTypes.push_back( *magma_singleton::get_named_data_type( _T("Vec3") ) );

        if( const channel_data* cd = find_channel( _T("Normal") ) ) {
            inputs.push_back( cd->socket );
        } else if( sc->get_native_channel_map().has_channel( _T("Normal") ) ) { // TODO: Or extract from orientation?
            inputs.push_back(
                sc->compile_default_input_channel( _T("Normal"), magma_singleton::get_named_data_type( _T("Vec3") ) ) );
        } else {
            inputs.push_back( sc->compile_constant( vec3( 0, 0, 0 ) ) );
        }
        inputTypes.push_back( *magma_singleton::get_named_data_type( _T("Vec3") ) );

        if( const channel_data* cd = find_channel( _T("MtlIndex") ) ) {
            inputs.push_back( cd->socket );
        } else if( sc->get_native_channel_map().has_channel( _T("MtlIndex") ) ) {
            inputs.push_back( sc->compile_default_input_channel( _T("MtlIndex"),
                                                                 magma_singleton::get_named_data_type( _T("Int") ) ) );
        } else {
            inputs.push_back( sc->compile_constant( 0 ) );
        }
        inputTypes.push_back( *magma_singleton::get_named_data_type( _T("Int") ) );

        if( const channel_data* cd = find_channel( _T("IOR") ) ) {
            inputs.push_back( cd->socket );
        } else if( sc->get_native_channel_map().has_channel( _T("IOR") ) ) {
            inputs.push_back(
                sc->compile_default_input_channel( _T("IOR"), magma_singleton::get_named_data_type( _T("Float") ) ) );
        } else {
            inputs.push_back( sc->compile_constant( 1.f ) );
        }
        inputTypes.push_back( *magma_singleton::get_named_data_type( _T("Float") ) );

        // Add any Mapping## channels that were explicitly set by exposing a socket.
        for( std::vector<channel_data>::const_iterator it = m_inputs.begin(), itEnd = m_inputs.end(); it != itEnd;
             ++it ) {
            if( boost::starts_with( it->name, _T("Mapping") ) ) {
                int channel = boost::lexical_cast<int>( it->name.substr( 7 ) );
                if( channel >= 2 && channel < MAX_MESHMAPS ) {
                    std::size_t inputIndex = inputs.size();

                    inputs.push_back( it->socket );
                    inputTypes.push_back( *magma_singleton::get_named_data_type( _T("Vec3") ) );

                    expr->bind_input_to_channel( inputIndex, channel );
                }
            }
        }

        BitArray reqUVWs;
        frantic::max3d::shaders::collect_map_requirements( texmap, reqUVWs );

        // Add any required channels that weren't explicitly set via a socket (ie. those that don't appear via
        // find_channel()) Start at 2 to avoid Mapping0 and Mapping1 that are actually called Color and TextureCoord
        // respectively.
        for( int i = 2; i < MAX_MESHMAPS; ++i ) {
            if( reqUVWs[i] ) {
                frantic::tstring channelName = _T("Mapping") + boost::lexical_cast<frantic::tstring>( i );
                if( find_channel( channelName ) == NULL ) {
                    std::size_t inputIndex = inputs.size();

                    if( sc->get_native_channel_map().has_channel( channelName ) ) {
                        inputs.push_back( sc->compile_default_input_channel(
                            channelName, magma_singleton::get_named_data_type( _T("Vec3") ) ) );
                    } else {
                        inputs.push_back( sc->compile_constant( vec3( 0, 0, 0 ) ) );
                    }
                    inputTypes.push_back( *magma_singleton::get_named_data_type( _T("Vec3") ) );

                    expr->bind_input_to_channel( inputIndex, i );
                }
            }
        }

        sc->compile_expression( static_cast<std::auto_ptr<base_compiler::expression>>( expr ), this->get_id(), inputs,
                                inputTypes );
    } else {
        magma_node_base::compile_as_extension_type( compiler );
    }
}

} // namespace max3d
} // namespace nodes
} // namespace magma
} // namespace frantic

using frantic::magma::max3d::MagmaMaxNodeExtension;

template <>
MagmaMaxNodeExtension<frantic::magma::nodes::max3d::magma_texmap_op_node::max_impl>::MyClassDesc
    MagmaMaxNodeExtension<frantic::magma::nodes::max3d::magma_texmap_op_node::max_impl>::s_classDesc;

ClassDesc2* GetMagmaEvalTexmapNodeDesc() {
    return &frantic::magma::nodes::max3d::magma_texmap_op_node::max_impl::s_classDesc;
}
