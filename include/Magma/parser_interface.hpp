// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0
#pragma once

#include <magma/base_node.hpp>
#include <magma/magma_mxs_parser.hpp>

namespace magma {

class parser_interface {
  private:
    friend class magma_mxs_parser_impl;

    static void parse_node( const base_node& node, magma_mxs_parser& parser,
                            std::vector<frantic::channels::channel_op_node*>& outExpr );

  public:
    /**
     * Interface methods
     */
    virtual ~parser_interface() {}

    virtual void apply( const base_node& node, magma_mxs_parser& parser,
                        std::vector<frantic::channels::channel_op_node*>& outExpr ) = 0;
};

} // namespace magma
