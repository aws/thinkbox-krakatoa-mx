// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0
#pragma once

struct tp_group_info {
    INode* node;
    ReferenceTarget* group;
    frantic::tstring name;
    tp_group_info( INode* node, ReferenceTarget* group, const frantic::tstring& name )
        : node( node )
        , group( group )
        , name( name ) {}
};
