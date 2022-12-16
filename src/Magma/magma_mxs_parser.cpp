// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0
#include "stdafx.h"
#include <magma/base_node.hpp>
#include <magma/magma_mxs_parser.hpp>
#include <magma/parser_interface.hpp>

#include <frantic/channels/channel_operation_nodes.hpp>

namespace magma {

class geometry_provider_impl : public geometry_provider {
    std::map<std::string, geometry_provider::value_type> m_geometryMap;

  public:
    virtual void clear() { m_geometryMap.clear(); }

    virtual bool has_geometry( const std::string& name ) { return m_geometryMap.find( name ) != m_geometryMap.end(); }

    virtual value_type& get_geometry( const std::string& name ) {
        std::map<std::string, value_type>::iterator it = m_geometryMap.find( name );
        if( it == m_geometryMap.end() )
            throw std::runtime_error( "No geometry with name: \"" + name + "\"" );
        return it->second;
    }

    virtual void set_geometry( const std::string& name, mesh_ptr_type pMesh ) {
        kdtree_ptr_type pTree( new kdtree_type( *pMesh ) );
        m_geometryMap.insert( std::make_pair( name, value_type( pMesh, pTree ) ) );
    }
};

class magma_mxs_parser_impl : public magma_mxs_parser {
    geometry_provider_ptr m_geomProvider;
    krakatoa::scene_context_ptr m_sceneContext;

    INode* m_pBoundNode;
    ReferenceTarget* m_pMagmaHolder;

  private:
    void parse_input( const base_node& node, std::vector<frantic::channels::channel_op_node*>& outExpr );

    void parse_output( const base_node& node, std::vector<frantic::channels::channel_op_node*>& outExpr );

    void parse_operator( const base_node& node, std::vector<frantic::channels::channel_op_node*>& outExpr );

  public:
    magma_mxs_parser_impl()
        : m_pMagmaHolder( NULL )
        , m_pBoundNode( NULL )
        , m_geomProvider( new geometry_provider_impl ) {}

    virtual ~magma_mxs_parser_impl() {}

    virtual void set_max_data( ReferenceTarget* pMagmaHolder );

    virtual void set_bound_inode( INode* pNode );

    virtual void set_scene_context( krakatoa::scene_context_ptr pSceneContext );

    virtual void set_geometry_provider( geometry_provider_ptr pGeomProvider );

    virtual INode* get_bound_inode();

    virtual ReferenceTarget* get_max_data();

    virtual geometry_provider& get_geometry_provider();

    virtual krakatoa::scene_context& get_scene_context();

    virtual krakatoa::scene_context_ptr get_scene_context_ptr();

    virtual void create_expression( std::vector<frantic::channels::channel_op_node*>& outExpr );
};

magma_mxs_parser* create_mxs_parser() { return new magma_mxs_parser_impl; }

void magma_mxs_parser_impl::set_max_data( ReferenceTarget* pMagmaHolder ) { m_pMagmaHolder = pMagmaHolder; }

void magma_mxs_parser_impl::set_bound_inode( INode* pNode ) { m_pBoundNode = pNode; }

void magma_mxs_parser_impl::set_scene_context( krakatoa::scene_context_ptr pSceneContext ) {
    m_sceneContext = pSceneContext;
}

void magma_mxs_parser_impl::set_geometry_provider( geometry_provider_ptr pGeomProvider ) {
    m_geomProvider = pGeomProvider;
}

INode* magma_mxs_parser_impl::get_bound_inode() { return m_pBoundNode; }

ReferenceTarget* magma_mxs_parser_impl::get_max_data() { return m_pMagmaHolder; }

geometry_provider& magma_mxs_parser_impl::get_geometry_provider() { return *m_geomProvider; }

krakatoa::scene_context& magma_mxs_parser_impl::get_scene_context() { return *m_sceneContext; }

krakatoa::scene_context_ptr magma_mxs_parser_impl::get_scene_context_ptr() { return m_sceneContext; }

void magma_mxs_parser_impl::create_expression( std::vector<frantic::channels::channel_op_node*>& outExpr ) {
    using namespace frantic::channels;

    if( !m_pMagmaHolder )
        return;

    try {
        base_node parsedNode;

        Value* pNodeArrayVal = frantic::max3d::mxs::expression( _T("execute theMod.flow") )
                                   .bind( _T("theMod"), m_pMagmaHolder )
                                   .evaluate<Value*>();

        if( !pNodeArrayVal || !is_array( pNodeArrayVal ) )
            throw channel_compiler_error( -1, "Invalid .flow property in modifier" );

        Array* pNodeArray = static_cast<Array*>( pNodeArrayVal );

        for( int i = 0; i < pNodeArray->size; ++i ) {
            parsedNode.reset( pNodeArray->get( 1 + i ), i );

            if( parsedNode.disabled ) {
                int passThroughIndex = -1;
                if( parsedNode.connection_count() > 0 ) {
                    passThroughIndex = parsedNode.get_connection( 0 );
                    if( passThroughIndex >= pNodeArray->size )
                        passThroughIndex = -1;
                }

                outExpr.push_back( new disabled_op_node( i, passThroughIndex ) );
            } else {
                parser_interface::parse_node( parsedNode, *this, outExpr );
            }
        }

        // TODO: Verify the structure of the created expression.
    } catch( MAXScriptException& e ) {
        frantic::max3d::mxs::frame<1> f;
        frantic::max3d::mxs::local<StringStream> stream( f );

        stream = new StringStream();
        e.sprin1( stream );

        throw std::runtime_error( frantic::strings::to_string( stream->to_string() ) );
    }
}

} // namespace magma
