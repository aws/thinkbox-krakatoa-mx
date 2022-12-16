// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0
#include "stdafx.h"

#include <magma/parser_interface.hpp>

#include <frantic/channels/channel_operation_nodes.hpp>
#include <frantic/max3d/maxscript/maxscript.hpp>

namespace magma {

template <class NodeType, int NumConnections>
class simple_operator_factory : public parser_interface {
  public:
    virtual void apply( const base_node& node, magma_mxs_parser& parser,
                        std::vector<frantic::channels::channel_op_node*>& outExpr ) = 0;
};

template <class NodeType>
class simple_operator_factory<NodeType, 1> : public parser_interface {
  public:
    virtual void apply( const base_node& node, magma_mxs_parser&,
                        std::vector<frantic::channels::channel_op_node*>& outExpr ) {
        outExpr.push_back( new NodeType( node.id, node.get_connection( 0 ) ) );
    }
};

template <class NodeType>
class simple_operator_factory<NodeType, 2> : public parser_interface {
  public:
    virtual void apply( const base_node& node, magma_mxs_parser&,
                        std::vector<frantic::channels::channel_op_node*>& outExpr ) {
        outExpr.push_back( new NodeType( node.id, node.get_connection( 0 ), node.get_connection( 1 ) ) );
    }
};

template <class NodeType>
class simple_operator_factory<NodeType, 3> : public parser_interface {
  public:
    virtual void apply( const base_node& node, magma_mxs_parser&,
                        std::vector<frantic::channels::channel_op_node*>& outExpr ) {
        outExpr.push_back(
            new NodeType( node.id, node.get_connection( 0 ), node.get_connection( 1 ), node.get_connection( 2 ) ) );
    }
};

class curve_factory : public parser_interface {
  public:
    virtual void apply( const base_node& node, magma_mxs_parser&,
                        std::vector<frantic::channels::channel_op_node*>& outExpr ) {
        using namespace frantic::math;

        int inputs[] = { node.get_connection( 0 ) };

        Value* pCurvePointsVal = node.get_property<Value*>( 1 );
        if( !is_array( pCurvePointsVal ) )
            throw channel_compiler_error( node.id, "Invalid curve array" );
        Array* pCurvePoints = static_cast<Array*>( pCurvePointsVal );
        if( pCurvePoints->size < 2 )
            throw channel_compiler_error( node.id, "Expected at least two elements in curve array" );

        std::vector<bezier_curve_point<frantic::graphics2d::vector2f>> points;
        for( int i = 0; i < pCurvePoints->size; ++i ) {
            Value* pPointVal = pCurvePoints->get( 1 + i );
            if( !is_array( pPointVal ) || static_cast<Array*>( pPointVal )->size < 3 )
                throw channel_compiler_error( node.id, "Invalid element " + boost::lexical_cast<std::string>( i + 1 ) +
                                                           " in curve array" );

            Array* pPoint = static_cast<Array*>( pPointVal );

            bezier_curve_point<frantic::graphics2d::vector2f> cp;
            cp.position = frantic::max3d::from_max_t( pPoint->get( 1 + 0 )->to_point2() );
            cp.inTan = frantic::max3d::from_max_t( pPoint->get( 1 + 1 )->to_point2() );
            cp.outTan = frantic::max3d::from_max_t( pPoint->get( 1 + 2 )->to_point2() );

            points.push_back( cp );
        }

        outExpr.push_back( new frantic::channels::bezier_x_to_y_node( node.id, inputs[0], points ) );
    }
};

class transform_factory : public parser_interface {
  public:
    virtual void apply( const base_node& node, magma_mxs_parser& parser,
                        std::vector<frantic::channels::channel_op_node*>& outExpr ) {
        TimeValue t = SecToTicks( parser.get_scene_context().get_time() );

        int inputs[] = { node.get_connection( 0 ) };

        std::string operatorType = node.get_property<std::string>( 0 );
        std::string operandType = node.get_property<std::string>( 1 );

        frantic::graphics::transform4f tm;

        if( operatorType == "ToSpace" || operatorType == "FromSpace" ) {
            std::string transformNodeName = node.get_property<std::string>( 2 );

            // TODO: The scene context should probably expose a way to get at named objects, instead of going this
            // route.
            INode* pTMNode =
                GetCOREInterface()->GetINodeByName( frantic::strings::to_tstring( transformNodeName ).c_str() );
            if( !pTMNode )
                throw channel_compiler_error( node.id, "Could not find node by name: \"" + transformNodeName + "\"" );

            tm = frantic::max3d::from_max_t( pTMNode->GetNodeTM( t ) );

            if( operatorType.compare( 0, 2, "To" ) == 0 )
                tm = tm.to_inverse();
        } else if( operatorType == "ToWorld" || operatorType == "FromWorld" ) {
            INode* pBoundNode = parser.get_bound_inode();
            if( !pBoundNode )
                throw channel_compiler_error(
                    node.id, "This operation is not supported in this context, since there is no node" );

            tm = frantic::max3d::from_max_t( pBoundNode->GetNodeTM( t ) );

            if( operatorType.compare( 0, 4, "From" ) == 0 )
                tm = tm.to_inverse();
        } else if( operatorType == "ToView" ) {
            tm = parser.get_scene_context().get_camera().world_transform_inverse();
        } else if( operatorType == "FromView" ) {
            tm = parser.get_scene_context().get_camera().world_transform();
        }

        if( operandType == "Point" ) {
            outExpr.push_back( new frantic::channels::transform_point_node( node.id, inputs[0], tm ) );
        } else if( operandType == "Vector" ) {
            outExpr.push_back( new frantic::channels::transform_vector_node( node.id, inputs[0], tm ) );
        } else if( operandType == "Normal" ) {
            outExpr.push_back( new frantic::channels::transform_normal_node( node.id, inputs[0], tm ) );
        } else
            throw channel_compiler_error( node.id, "Unexpected transformation operand type: " + operandType );
    }
};

class surfacedata_factory : public parser_interface {
  public:
    virtual void apply( const base_node& node, magma_mxs_parser&,
                        std::vector<frantic::channels::channel_op_node*>& outExpr ) {
        using frantic::channels::surf_data_value_node;

        int srcIndex[] = { node.get_connection( 0 ) };

        std::string type = node.get_property<std::string>( 1 );
        surf_data_value_node::target_result rTarget = surf_data_value_node::RESULT_INVALID;

        if( type == "Position" ) {
            rTarget = surf_data_value_node::RESULT_POSITION;
        } else if( type == "SignedDistance" ) {
            rTarget = surf_data_value_node::RESULT_SIGNED_DIST;
        } else if( type == "FaceNormal" ) {
            rTarget = surf_data_value_node::RESULT_FACE_NORMAL;
        } else if( type == "SmoothNormal" ) {
            rTarget = surf_data_value_node::RESULT_SMOOTH_NORMAL;
        } else if( type == "MeshIndex" ) {
            rTarget = surf_data_value_node::RESULT_MESH_INDEX;
        } else if( type == "FaceIndex" ) {
            rTarget = surf_data_value_node::RESULT_FACE_INDEX;
        } else if( type == "FaceNormal" ) {
            rTarget = surf_data_value_node::RESULT_FACE_NORMAL;
        } else if( type == "FaceMatID" ) {
            rTarget = surf_data_value_node::RESULT_FACE_MAT_ID;
        } else if( type == "SmoothGroup" ) {
            rTarget = surf_data_value_node::RESULT_SMOOTH_GROUP;
        } else if( type == "BaryCoords" ) {
            rTarget = surf_data_value_node::RESULT_BARY_COORDS;
        } else if( type == "TextureCoord" ) {
            rTarget = surf_data_value_node::RESULT_TEXTURE_COORD;
        } else if( type == "Valid" ) {
            rTarget = surf_data_value_node::RESULT_INTERSECTED;
        } else
            throw channel_compiler_error( node.id, "Invalid surface data value target: \"" + type + "\"" );

        outExpr.push_back( new surf_data_value_node( node.id, srcIndex[0], rTarget ) );
    }
};

void register_operator_parsers( std::map<std::string, parser_interface*>& outFactories ) {
    // Arithmetic Nodes
    outFactories["Add"] = new simple_operator_factory<frantic::channels::addition_node, 2>;
    outFactories["Subtract"] = new simple_operator_factory<frantic::channels::subtraction_node, 2>;
    outFactories["Multiply"] = new simple_operator_factory<frantic::channels::multiplication_node, 2>;
    outFactories["Divide"] = new simple_operator_factory<frantic::channels::division_node, 2>;
    outFactories["Power"] = new simple_operator_factory<frantic::channels::power_node, 2>;
    outFactories["SquareRoot"] = new simple_operator_factory<frantic::channels::sqrt_node, 1>;
    outFactories["Modulo"] = new simple_operator_factory<frantic::channels::modulo_node, 2>;
    outFactories["AbsoluteValue"] = new simple_operator_factory<frantic::channels::abs_node, 1>;
    outFactories["Floor"] = new simple_operator_factory<frantic::channels::floor_node, 1>;
    outFactories["Ceil"] = new simple_operator_factory<frantic::channels::ceil_node, 1>;
    outFactories["Negate"] = new simple_operator_factory<frantic::channels::negate_node, 1>;
    outFactories["Logarithm"] = new simple_operator_factory<frantic::channels::log_node, 1>;

    // Function Nodes
    outFactories["Blend"] = new simple_operator_factory<frantic::channels::blend_node, 3>;
    outFactories["Clamp"] = new simple_operator_factory<frantic::channels::clamp_node, 3>;
    outFactories["Curve"] = new curve_factory;
    outFactories["Noise"] = new simple_operator_factory<frantic::channels::noise_node, 3>;
    outFactories["DNoise"] = new simple_operator_factory<frantic::channels::dnoise_node, 3>;

    // Vector op Nodes
    outFactories["Normalize"] = new simple_operator_factory<frantic::channels::normalize_node, 1>;
    outFactories["Magnitude"] = new simple_operator_factory<frantic::channels::magnitude_node, 1>;
    outFactories["ComponentSum"] = new simple_operator_factory<frantic::channels::component_sum_node, 1>;
    outFactories["DotProduct"] = new simple_operator_factory<frantic::channels::vector_dot_node, 2>;
    outFactories["CrossProduct"] = new simple_operator_factory<frantic::channels::vector_cross_node, 2>;

    // Trig Nodes
    outFactories["Sin"] = new simple_operator_factory<frantic::channels::sin_trig_node, 1>;
    outFactories["Cos"] = new simple_operator_factory<frantic::channels::cos_trig_node, 1>;
    outFactories["Tan"] = new simple_operator_factory<frantic::channels::tan_trig_node, 1>;
    outFactories["ASin"] = new simple_operator_factory<frantic::channels::asin_trig_node, 1>;
    outFactories["ACos"] = new simple_operator_factory<frantic::channels::acos_trig_node, 1>;
    outFactories["ATan"] = new simple_operator_factory<frantic::channels::atan_trig_node, 1>;
    outFactories["ATan2"] = new simple_operator_factory<frantic::channels::atan2_trig_node, 2>;

    // Convert Nodes
    outFactories["FromQuat"] = new simple_operator_factory<frantic::channels::quat_to_vector_node, 2>;
    outFactories["ToQuat"] = new simple_operator_factory<frantic::channels::vectors_to_quat_node, 3>;
    outFactories["ToVector"] = new simple_operator_factory<frantic::channels::scalars_to_vector_node, 3>;
    outFactories["ToFloat"] = new simple_operator_factory<frantic::channels::convert_node<float, 1>, 1>;
    outFactories["ToInteger"] = new simple_operator_factory<frantic::channels::convert_node<int, 1>, 1>;
    outFactories["ToScalar"] = new simple_operator_factory<frantic::channels::vector_to_scalar_node, 2>;

    // Transformation Nodes
    outFactories["ToWorld"] = outFactories["FromWorld"] = outFactories["ToSpace"] = outFactories["FromSpace"] =
        outFactories["ToView"] = outFactories["FromView"] = new transform_factory;
    outFactories["TransformByQuat"] = new simple_operator_factory<frantic::channels::transform_by_quat_node, 2>;

    // Surface Query Nodes
    outFactories["SurfDataValue"] = new surfacedata_factory;
    outFactories["RayIntersect"] = new simple_operator_factory<frantic::channels::ray_intersect_node, 3>;
    outFactories["NearestPoint"] = new simple_operator_factory<frantic::channels::nearest_point_node, 2>;

    // Logic Nodes
    outFactories["Less"] = new simple_operator_factory<frantic::channels::less_comparison_node, 2>;
    outFactories["LessOrEqual"] = new simple_operator_factory<frantic::channels::less_or_equal_comparison_node, 2>;
    outFactories["Greater"] = new simple_operator_factory<frantic::channels::greater_comparison_node, 2>;
    outFactories["GreaterOrEqual"] =
        new simple_operator_factory<frantic::channels::greater_or_equal_comparison_node, 2>;
    outFactories["Equal"] = new simple_operator_factory<frantic::channels::equal_comparison_node, 2>;
    outFactories["LogicalAnd"] = new simple_operator_factory<frantic::channels::logical_and_node, 2>;
    outFactories["LogicalOr"] = new simple_operator_factory<frantic::channels::logical_or_node, 2>;
    outFactories["LogicalNot"] = new simple_operator_factory<frantic::channels::logical_not_node, 1>;
    outFactories["Switch"] = new simple_operator_factory<frantic::channels::switch_node, 3>;
}

} // namespace magma
