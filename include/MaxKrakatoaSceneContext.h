// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0
#pragma once

#include "MaxKrakatoaRenderGlobalContext.h"

#include <krakatoa/camera_manager.hpp>
#include <krakatoa/scene_context.hpp>

#include <maxtypes.h>

class MaxKrakatoaSceneContext : public krakatoa::scene_context {
    krakatoa::camera_manager_ptr m_cameraManager;
    double m_time;
    bool m_isEnvironmentRender;

    krakatoa::collection_wrapper<krakatoa::matte_primitive_ptr, std::vector> m_matteObjects;
    krakatoa::collection_wrapper<krakatoa::light_object_ptr, std::vector> m_lightObjects;

    RenderGlobalContext*
        m_renderGlobalContext; // Not a smart ptr, because MaxKrakatoaRenderGlobalContext keeps a shared_ptr to *this

  public:
    typedef boost::intrusive_ptr<MaxKrakatoaSceneContext> ptr_type;

    MaxKrakatoaSceneContext();
    virtual ~MaxKrakatoaSceneContext();

    virtual double get_time() const;
    virtual void set_time( double time );

    virtual const frantic::graphics::camera<float>& get_camera() const;
    virtual frantic::graphics::camera<float>& get_camera();

    virtual void set_camera( const frantic::graphics::camera<float>& cam );
    virtual void set_camera( const std::vector<frantic::graphics::camera<float>>& cams );

    virtual bool is_environment_camera() const;
    virtual void set_is_environment_camera( bool enabled = true );

    virtual const matte_collection& get_matte_objects() const;
    virtual const light_collection& get_light_objects() const;

    virtual void add_matte_object( krakatoa::matte_primitive_ptr pObj );
    virtual void add_light_object( krakatoa::light_object_ptr pLightObj );

    virtual const RenderGlobalContext* get_render_global_context() const;
    virtual void set_render_global_context( RenderGlobalContext* globalContext );
};

typedef MaxKrakatoaSceneContext::ptr_type MaxKrakatoaSceneContextPtr;

inline int krakatoa_time_to_ticks( double time ) {
    return static_cast<TimeValue>( static_cast<double>( TIME_TICKSPERSEC ) * time );
}

inline double ticks_to_krakatoa_time( TimeValue t ) {
    return static_cast<double>( t ) / static_cast<double>( TIME_TICKSPERSEC );
}
