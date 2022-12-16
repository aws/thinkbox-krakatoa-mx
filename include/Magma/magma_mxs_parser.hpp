// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0
#pragma once

#include "krakatoa/scene_context.hpp"
#include <magma/geometry_provider.hpp>

#include <boost/shared_ptr.hpp>

#include <frantic/channels/channel_operation_compiler.hpp>

#include <max.h>

namespace magma {

class magma_mxs_parser;

magma_mxs_parser* create_mxs_parser();

class magma_mxs_parser {
  public:
    virtual ~magma_mxs_parser() {}

    /**
     * Setters
     */
    virtual void set_max_data( ReferenceTarget* pMagmaHolder ) = 0;

    virtual void set_bound_inode( INode* pNode ) = 0;

    virtual void set_scene_context( krakatoa::scene_context_ptr pSceneContext ) = 0;

    virtual void set_geometry_provider( geometry_provider_ptr pGeomProvider ) = 0;

    /**
     * Getters
     */
    virtual INode* get_bound_inode() = 0;

    virtual ReferenceTarget* get_max_data() = 0;

    virtual geometry_provider& get_geometry_provider() = 0;

    virtual krakatoa::scene_context& get_scene_context() = 0;

    virtual krakatoa::scene_context_ptr get_scene_context_ptr() = 0;

    /**
     * Methods
     */
    virtual void create_expression( std::vector<frantic::channels::channel_op_node*>& outExpr ) = 0;
};

} // namespace magma
