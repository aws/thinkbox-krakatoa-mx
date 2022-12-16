// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0
#include "stdafx.h"

#include "MaxKrakatoaChannelTexmapOperator.h"

#include <magma/parser_interface.hpp>

#include <frantic/channels/channel_operation_nodes.hpp>
#include <frantic/max3d/geometry/auto_mesh.hpp>
#include <frantic/max3d/geometry/mesh.hpp>
#include <frantic/max3d/geometry/null_view.hpp>
#include <frantic/max3d/maxscript/maxscript.hpp>

namespace magma {

class input_channel_factory : public parser_interface {
  public:
    virtual void apply( const base_node& node, magma_mxs_parser&,
                        std::vector<frantic::channels::channel_op_node*>& outExpr ) {
        outExpr.push_back(
            new frantic::channels::input_channel_op_node( node.id, node.get_property<std::string>( 1 ) ) );
    }
};

class input_value_factory : public parser_interface {
  private:
    static ITrackViewNode* FindTrackByName( ITrackViewNode* curTrack, const std::string& name ) {
        for( int i = 0, iEnd = curTrack->NumItems(); i < iEnd; ++i ) {
            if( frantic::strings::to_string( curTrack->GetName( i ) ) == name )
                return curTrack->GetNode( i );
        }
        return NULL;
    }

    static ReferenceTarget* GetTrackByPath( int nodeId, const std::string& path ) {
        Interface* ip = GetCOREInterface();
        ITrackViewNode* curTrackNode = ip->GetTrackViewRootNode();
        if( !curTrackNode )
            throw channel_compiler_error( nodeId, "Could not get track view root for path: \"" + path + "\"" );

        std::string::size_type prevDelimiter = 0;
        std::string::size_type nextDelimiter = path.find( '.' );
        if( nextDelimiter == std::string::npos || path.substr( 0, nextDelimiter ) != "trackViewNodes" )
            throw channel_compiler_error( nodeId, "Invalid path to track: \"" + path + "\"" );

        prevDelimiter = nextDelimiter + 1;
        nextDelimiter = path.find( '.', prevDelimiter );

        std::string curTrack;
        while( nextDelimiter != std::string::npos ) {
            curTrack = path.substr( prevDelimiter, nextDelimiter - prevDelimiter );
            curTrackNode = FindTrackByName( curTrackNode, curTrack );
            if( !curTrackNode )
                throw channel_compiler_error( nodeId,
                                              "Invalid path to track: \"" + path + "\" at element: " + curTrack );

            prevDelimiter = nextDelimiter + 1;
            nextDelimiter = path.find( '.', prevDelimiter );
        }

        curTrack = path.substr( prevDelimiter );
        return FindTrackByName( curTrackNode, curTrack );
    }

  public:
    virtual void apply( const base_node& node, magma_mxs_parser& parser,
                        std::vector<frantic::channels::channel_op_node*>& outExpr ) {
        std::string valueType = node.get_property<std::string>( 1 );
        std::string trackPath = node.get_property<std::string>( 2 );

        ReferenceTarget* pTrackHolder = GetTrackByPath( node.id, trackPath );
        if( !pTrackHolder || pTrackHolder->NumSubs() != 3 )
            throw channel_compiler_error( node.id, "Failed to get the track holder" );

        TimeValue t = SecToTicks( parser.get_scene_context().get_time() );

        if( valueType == "Integer" ) {
            Control* pIntControl = static_cast<Control*>( pTrackHolder->SubAnim( 0 ) );
            if( pIntControl->SuperClassID() != CTRL_FLOAT_CLASS_ID )
                throw channel_compiler_error( node.id, "Invalid Integer controller in " + trackPath );

            float theVal;
            Interval ivalid = FOREVER;
            pIntControl->GetValue( t, &theVal, ivalid );

            // Max Integer controllers are just float controllers that the UI rounds by
            // adding 0.5 then flooring.
            boost::int32_t theIntVal = (boost::int32_t)std::floor( theVal + 0.5f );

            outExpr.push_back( new frantic::channels::input_value_op_node<boost::int32_t, 1>( node.id, &theIntVal ) );
        } else if( valueType == "Float" ) {
            Control* pFloatControl = static_cast<Control*>( pTrackHolder->SubAnim( 1 ) );
            if( pFloatControl->SuperClassID() != CTRL_FLOAT_CLASS_ID )
                throw channel_compiler_error( node.id, "Invalid controller in the Input:Value:Float node" );

            float theVal;
            Interval ivalid = FOREVER;
            pFloatControl->GetValue( t, &theVal, ivalid );

            outExpr.push_back( new frantic::channels::input_value_op_node<float, 1>( node.id, &theVal ) );
        } else if( valueType == "Vector" ) {
            Control* pPoint3Control = static_cast<Control*>( pTrackHolder->SubAnim( 2 ) );
            if( pPoint3Control->SuperClassID() != CTRL_POINT3_CLASS_ID )
                throw channel_compiler_error( node.id, "Invalid controller in the Input:Value:Vector node" );

            Point3 theVal;
            Interval ivalid = FOREVER;
            pPoint3Control->GetValue( t, &theVal, ivalid );

            outExpr.push_back( new frantic::channels::input_value_op_node<float, 3>( node.id, (float*)theVal ) );
        } else
            throw channel_compiler_error( node.id, "Unexpected Input:Value type \"" + valueType + "\"" );
    }
};

class input_texmap_factory : public parser_interface {
  public:
    virtual void apply( const base_node& node, magma_mxs_parser& parser,
                        std::vector<frantic::channels::channel_op_node*>& outExpr ) {
        int texIndex = node.get_property<int>( 1 ) - 1;
        if( texIndex < 0 )
            throw channel_compiler_error( node.id, "Invalid texture map index: " +
                                                       boost::lexical_cast<std::string>( texIndex ) );

        texmap_output::output_t evalType;

        std::string evalTypeString = "Color";
        if( node.property_count() > 2 )
            evalTypeString = node.get_property<std::string>( 2 );

        if( evalTypeString == "Color" )
            evalType = texmap_output::color;
        else if( evalTypeString == "Mono" )
            evalType = texmap_output::mono;
        else if( evalTypeString == "Perturb" )
            evalType = texmap_output::bump;
        else
            throw channel_compiler_error( node.id, "Invalid texture map output type: \"" + evalTypeString + "\"." );

        INode* pNode = parser.get_bound_inode();

        // Adapt info from the scene context into the renderInformation struct
        // frantic::max3d::shaders::renderInformation ri;
        // ri.m_camera = parser.get_scene_context().get_camera();
        // ri.m_cameraPosition = frantic::max3d::to_max_t( ri.m_camera.camera_position() );
        // ri.m_renderGlobalContext = const_cast<MaxKrakatoaRenderGlobalContext*>(
        // parser.get_scene_context().get_render_global_context() ); if( pNode ){ 	ri.m_toWorldTM =
        //frantic::max3d::from_max_t( pNode->GetNodeTM( t ) ); if( ri.m_renderGlobalContext ) ri.m_currentInstance =
        // const_cast<RenderInstance*>( parser.get_scene_context().get_render_global_context()->get_instance_from_node(
        // pNode ) );
        //}

        if( texIndex == 0 ) {
            if( !pNode )
                throw channel_compiler_error(
                    node.id, "The selected texture map is not valid in this context. Please choose a different one." );

            Color c;

            Mtl* pMtl = pNode->GetMtl();
            if( pMtl ) {
                if( pMtl->ClassID() == Class_ID( DMTL_CLASS_ID, 0 ) ) {
                    StdMat* pStdMtl = static_cast<StdMat*>( pMtl );
                    Texmap* pTexmap = pStdMtl->GetSubTexmap( ID_DI );
                    if( pTexmap && pStdMtl->MapEnabled( ID_DI ) ) {
                        outExpr.push_back( CreateMaxKrakatoaChannelTexmapOperator(
                            node.id, pTexmap, evalType, parser.get_scene_context_ptr(), pNode, false ) );
                        return;
                    }
                }

                c = pMtl->GetDiffuse( SecToTicks( parser.get_scene_context().get_time() ) );
            } else
                c = Color( pNode->GetWireColor() );

            switch( evalType ) {
            case texmap_output::color:
                outExpr.push_back( new frantic::channels::input_value_op_node<float, 3>( node.id, (float*)c ) );
                break;
            case texmap_output::mono:
                c.r = Intens( c );
                outExpr.push_back( new frantic::channels::input_value_op_node<float, 1>( node.id, (float*)c ) );
                break;
            case texmap_output::bump: {
                Point3 p = Point3::Origin;
                outExpr.push_back( new frantic::channels::input_value_op_node<float, 3>( node.id, (float*)p ) );
            } break;
            default:
                __assume( 0 );
            }
        } else {
            ReferenceTarget* pMagmaHolder = parser.get_max_data();

            // Can't use pMagmaHolder's paramblocks because several different types of objects qualify as a MagmaHolder
            // other than a MagmaHolder object instance. Blarg.
            Value* pTexmapVal = frantic::max3d::mxs::expression(
                                    frantic::strings::to_tstring( "theMod.TextureMapSources[" +
                                                                  boost::lexical_cast<std::string>( texIndex ) + "]" ) )
                                    .bind( _T("theMod"), pMagmaHolder )
                                    .evaluate<Value*>();

            Texmap* pTexmap = pTexmapVal->to_texmap();
            if( !pTexmap )
                throw channel_compiler_error( node.id,
                                              "The selected texture map is not valid. Please choose a different one." );

            outExpr.push_back( CreateMaxKrakatoaChannelTexmapOperator( node.id, pTexmap, evalType,
                                                                       parser.get_scene_context_ptr(), pNode, false ) );
        }
    }
};

class input_script_factory : public parser_interface {
  public:
    virtual void apply( const base_node& node, magma_mxs_parser& parser,
                        std::vector<frantic::channels::channel_op_node*>& outExpr ) {
        TimeValue t = SecToTicks( parser.get_scene_context().get_time() );

        std::string theScript = node.get_property<std::string>( 1 );

        Value* pScriptResult =
            frantic::max3d::mxs::expression( frantic::strings::to_tstring( "execute \"" + theScript + "\"" ) )
                .at_time( t )
                .evaluate<Value*>();
        if( !pScriptResult )
            throw channel_compiler_error( node.id, "Result of Input:Script was invalid" );

        if( is_point3( pScriptResult ) ) {
            Point3 theVal = pScriptResult->to_point3();
            outExpr.push_back( new frantic::channels::input_value_op_node<float, 3>( node.id, (float*)theVal ) );
        } else if( is_int( pScriptResult ) ) {
            int theVal = pScriptResult->to_int();
            outExpr.push_back( new frantic::channels::input_value_op_node<int, 1>( node.id, &theVal ) );
        } else if( is_number( pScriptResult ) ) {
            float theVal = pScriptResult->to_float();
            outExpr.push_back( new frantic::channels::input_value_op_node<float, 1>( node.id, &theVal ) );
        } else
            throw channel_compiler_error( node.id, "Result of Input:Script was invalid" );
    }
};

class input_geometry_factory : public parser_interface {
  public:
    virtual void apply( const base_node& node, magma_mxs_parser& parser,
                        std::vector<frantic::channels::channel_op_node*>& outExpr ) {
        TimeValue t = SecToTicks( parser.get_scene_context().get_time() );

        Value* pGeomsListVal = node.get_property<Value*>( 1 );
        if( !is_array( pGeomsListVal ) )
            throw channel_compiler_error( node.id, "Malformed geometry input. Expected an array for property 2." );

        geometry_provider& geoProvider = parser.get_geometry_provider();

        std::auto_ptr<frantic::channels::geometry_input_node> pResult(
            new frantic::channels::geometry_input_node( node.id ) );

        Array* pGeomsList = static_cast<Array*>( pGeomsListVal );
        for( int i = 0; i < pGeomsList->size; ++i ) {
            std::string nodeName = frantic::strings::to_string( pGeomsList->get( 1 + i )->to_string() );

            if( !geoProvider.has_geometry( nodeName ) ) {
                INode* meshNode =
                    GetCOREInterface()->GetINodeByName( frantic::strings::to_tstring( nodeName ).c_str() );
                if( !meshNode )
                    throw channel_compiler_error( node.id, "A node object named: \"" + nodeName +
                                                               "\" was not found. Did you delete it?" );

                geometry_provider::mesh_ptr_type pNewMesh( new geometry_provider::mesh_type );

                frantic::max3d::geometry::null_view dummyView;
                frantic::graphics::transform4f toWorldTM =
                    frantic::max3d::from_max_t( meshNode->GetObjTMAfterWSM( t ) );

                // get the mesh object, then copy it into the trimesh, applying the node's transform to worldspace while
                // we're at it
                frantic::max3d::geometry::AutoMesh pMaxMesh =
                    frantic::max3d::geometry::get_mesh_from_inode( meshNode, t, dummyView );
                frantic::max3d::geometry::mesh_copy( *pNewMesh, toWorldTM, *pMaxMesh, false );

                geoProvider.set_geometry( nodeName, pNewMesh );
            }

            geometry_provider::value_type& geomData = geoProvider.get_geometry( nodeName );

            pResult->add_mesh( geomData.first, geomData.second );
        }

        outExpr.push_back( pResult.release() );
    }
};

void register_input_parsers( std::map<std::string, parser_interface*>& outFactories ) {
    outFactories["Channel"] = new input_channel_factory;
    outFactories["Value"] = new input_value_factory;
    outFactories["TextureMap"] = new input_texmap_factory;
    outFactories["Script"] = new input_script_factory;
    outFactories["Geometry"] = new input_geometry_factory;
}

} // namespace magma
