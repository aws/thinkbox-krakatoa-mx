// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0
#include "stdafx.h"

#include "Magma/MagmaMaxSingleton.hpp"
#include "frantic/magma/max3d/nodes/magma_texmap_op_node.hpp"

#include <frantic/magma/max3d/nodes/magma_input_field_node.hpp>
#include <frantic/magma/nodes/magma_standard_operators.hpp>

namespace frantic {
namespace magma {
namespace nodes {
namespace max3d {
void define_max_nodes( frantic::magma::magma_singleton& ms );
}
} // namespace nodes
} // namespace magma
} // namespace frantic

// MagmaMaxSingleton MagmaMaxSingleton::s_instance;

MagmaMaxSingleton::MagmaMaxSingleton()
    : frantic::magma::magma_singleton( true ) {
    frantic::magma::nodes::max3d::define_max_nodes( *this );
    this->define_node_type<frantic::magma::nodes::max3d::magma_texmap_op_node>();
    this->define_node_type<frantic::magma::nodes::magma_to_camera_node>();
    this->define_node_type<frantic::magma::nodes::magma_from_camera_node>();
    this->define_node_type<frantic::magma::nodes::max3d::magma_field_input_node>();
}

MagmaMaxSingleton& MagmaMaxSingleton::get_instance() {
    static MagmaMaxSingleton theMagmaMaxSingleton;
    return theMagmaMaxSingleton;
    // return s_instance;
}
