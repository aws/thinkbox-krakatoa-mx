// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0
#pragma once
#include <max.h>

#include <krakatoa\render_element_interface.hpp>
#include <krakatoa\scene_context.hpp>

#define IMaxKrakatoaRenderElementID Interface_ID( 0x64765004, 0x15052033 )

class IMaxKrakatoaRenderElement : public BaseInterface {
  public:
    virtual ~IMaxKrakatoaRenderElement() {}

    virtual krakatoa::render_element_interface* get_render_element( krakatoa::scene_context_ptr pSceneContext ) = 0;
};
