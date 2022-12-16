// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0
#pragma once

#include <imtl.h>
#include <interval.h>
#if MAX_RELEASE >= 25000
#include <geom/matrix3.h>
#else
#include <matrix3.h>
#endif
#include <mesh.h>
#include <object.h>
#if MAX_RELEASE >= 25000
#include <geom/point3.h>
#else
#include <point3.h>
#endif
#include <render.h>

#include <boost/shared_ptr.hpp>

#include <frantic/logging/progress_logger.hpp>
#include <frantic/max3d/geometry/null_view.hpp>
#include <frantic/max3d/logging/max_progress_logger.hpp>

#include <krakatoa/scene_context.hpp>

#include "Objects/MaxKrakatoaPRTInterface.h"

class MaxKrakatoaRenderInstance;
class MaxKrakatoaParticleRenderInstance;

typedef boost::shared_ptr<MaxKrakatoaRenderInstance> MaxKrakatoaRenderInstancePtr;
typedef boost::shared_ptr<MaxKrakatoaParticleRenderInstance> MaxKrakatoaParticleRenderInstancePtr;

class MaxKrakatoaRenderInstance;

class MaxKrakatoaRenderGlobalContext : public RenderGlobalContext,
                                       public frantic::max3d::particles::IMaxKrakatoaPRTEvalContext {
    krakatoa::scene_context_ptr m_sceneContext;
    std::vector<boost::shared_ptr<MaxKrakatoaRenderInstance>> m_instances;
    std::vector<boost::shared_ptr<ObjLightDesc>> m_lightDescs;

    ViewParams m_viewParams;

    frantic::channels::channel_map m_channelMap;

    frantic::max3d::logging::maxrender_progress_logger m_progressLogger;

  public:
    MaxKrakatoaRenderGlobalContext();
    virtual ~MaxKrakatoaRenderGlobalContext();

    void reset();
    void reset( krakatoa::scene_context_ptr sceneContext );

    const krakatoa::scene_context_ptr get_scene_context() const;
    krakatoa::scene_context_ptr get_scene_context();

    void set_renderprogress_callback( RendProgressCallback* rendProgressCallback );
    void set_channel_map( const frantic::channels::channel_map& pcm );

    RenderInstance* add_geometry_instance( INode* pNode );
    RenderInstance* add_particle_instance( INode* pNode );
    RenderInstance* get_instance_from_node( INode* pNode ) const;

    void add_light( INode* pNode );

    ObjLightDesc* get_light_desc( int i );
    int get_num_light_desc() const;

    // From IEvalContext_Legacy2
    /*virtual const frantic::graphics::camera<float>& get_camera() const;
    virtual const frantic::channels::channel_map& get_channel_map() const;
    virtual frantic::logging::progress_logger& get_progress_logger();
    virtual RenderGlobalContext& get_max_context();
    virtual std::pair<float,float> get_motion_blur_params() const;*/

    // From IMaxKrakatoaPRTEvalContext
    virtual Class_ID GetContextID() const;
    virtual bool WantsWorldSpaceParticles() const;
    virtual bool WantsMaterialEffects() const;
    virtual RenderGlobalContext& GetRenderGlobalContext() const;
    virtual const frantic::graphics::camera<float>& GetCamera() const;
    virtual const frantic::channels::channel_map& GetDefaultChannels() const;
    virtual frantic::logging::progress_logger& GetProgressLogger() const;
    virtual bool GetProperty( const Class_ID& propID, void* pTarget ) const;

    // From RenderGlobalContext
    virtual int NumRenderInstances();
    virtual RenderInstance* GetRenderInstance( int i );
    virtual FilterKernel* GetAAFilterKernel();
    virtual float GetAAFilterSize();
    virtual AColor EvalGlobalEnvironMap( ShadeContext& sc, Ray& r, BOOL applyAtmos );
    virtual void IntersectRay( RenderInstance* inst, Ray& ray, ISect& isct, ISectList& xpList, BOOL findExit );
    virtual BOOL IntersectWorld( Ray& ray, int skipID, ISect& hit, ISectList& xplist, int blurFrame = NO_MOTBLUR );
    virtual ViewParams* GetViewParams();
};
