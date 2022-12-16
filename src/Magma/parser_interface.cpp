// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0
#include "stdafx.h"

#include <frantic/channels/channel_operation_nodes.hpp>
#include <magma/parser_interface.hpp>

namespace magma {

namespace {
std::map<std::string, parser_interface*> g_inputFactories;
std::map<std::string, parser_interface*> g_operatorFactories;
} // namespace

extern void register_input_parsers( std::map<std::string, parser_interface*>& outFactories );
extern void register_operator_parsers( std::map<std::string, parser_interface*>& outFactories );

void parser_interface::parse_node( const base_node& node, magma_mxs_parser& parser,
                                   std::vector<frantic::channels::channel_op_node*>& outExpr ) {
    switch( node.type ) {
    case base_node::type_input: {
        if( g_inputFactories.empty() )
            register_input_parsers( g_inputFactories );

        std::string type = node.get_property<std::string>( 0 );

        std::map<std::string, parser_interface*>::iterator itParser = g_inputFactories.find( type );
        if( itParser == g_inputFactories.end() )
            throw frantic::channels::channel_compiler_error( node.id, "Unknown Input type: \"" + type + "\"" );

        itParser->second->apply( node, parser, outExpr );
    } break;

    case base_node::type_operator: {
        if( g_operatorFactories.empty() )
            register_operator_parsers( g_operatorFactories );

        std::string type = node.get_property<std::string>( 0 );

        std::map<std::string, parser_interface*>::iterator itParser = g_operatorFactories.find( type );
        if( itParser == g_operatorFactories.end() )
            throw frantic::channels::channel_compiler_error( node.id, "Unknown Operator type: \"" + type + "\"" );

        itParser->second->apply( node, parser, outExpr );
    } break;

    case base_node::type_output: {
        int inputIndices[] = { node.get_connection( 0 ) };

        std::string outChannel = node.get_property<std::string>( 0 );
        frantic::channels::data_type_t channelType =
            frantic::channels::channel_data_type_from_string( node.get_property<std::string>( 1 ) );
        int channelArity = node.get_property<int>( 2 );

        outExpr.push_back( new frantic::channels::output_channel_op_node( node.id, inputIndices[0], outChannel,
                                                                          channelArity, channelType ) );
    } break;
    default:
        throw frantic::channels::channel_compiler_error( node.id, "Unknown node type" );
    }
}

} // namespace magma
