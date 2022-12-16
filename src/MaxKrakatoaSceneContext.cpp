// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0
#include "stdafx.h"

#include <krakatoa/camera_manager.hpp>

#include "MaxKrakatoaSceneContext.h"

MaxKrakatoaSceneContext::MaxKrakatoaSceneContext()
    : m_renderGlobalContext( NULL )
    , m_cameraManager( new krakatoa::camera_manager ) {}

MaxKrakatoaSceneContext::~MaxKrakatoaSceneContext() {}

double MaxKrakatoaSceneContext::get_time() const { return m_time; }

void MaxKrakatoaSceneContext::set_time( double time ) { m_time = time; }

const frantic::graphics::camera<float>& MaxKrakatoaSceneContext::get_camera() const {
    return m_cameraManager->get_current_camera();
}

frantic::graphics::camera<float>& MaxKrakatoaSceneContext::get_camera() {
    return m_cameraManager->get_current_camera();
}

void MaxKrakatoaSceneContext::set_camera( const frantic::graphics::camera<float>& cam ) {
    m_cameraManager = krakatoa::camera_manager_ptr( new krakatoa::camera_manager( cam ) );
}

void MaxKrakatoaSceneContext::set_camera( const std::vector<frantic::graphics::camera<float>>& cams ) {
    m_cameraManager = krakatoa::camera_manager_ptr( new krakatoa::camera_manager( cams ) );
}

bool MaxKrakatoaSceneContext::is_environment_camera() const { return m_isEnvironmentRender; }

void MaxKrakatoaSceneContext::set_is_environment_camera( bool enabled ) { m_isEnvironmentRender = enabled; }

const MaxKrakatoaSceneContext::matte_collection& MaxKrakatoaSceneContext::get_matte_objects() const {
    return m_matteObjects;
}

void MaxKrakatoaSceneContext::add_matte_object( krakatoa::matte_primitive_ptr pObj ) {
    m_matteObjects.push_back( pObj );
}

const MaxKrakatoaSceneContext::light_collection& MaxKrakatoaSceneContext::get_light_objects() const {
    return m_lightObjects;
}

void MaxKrakatoaSceneContext::add_light_object( krakatoa::light_object_ptr pLightObj ) {
    m_lightObjects.push_back( pLightObj );
}

const RenderGlobalContext* MaxKrakatoaSceneContext::get_render_global_context() const { return m_renderGlobalContext; }

void MaxKrakatoaSceneContext::set_render_global_context( RenderGlobalContext* globalContext ) {
    m_renderGlobalContext = globalContext;
}
