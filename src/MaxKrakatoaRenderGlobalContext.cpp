// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0
#include "stdafx.h"

#include <frantic/geometry/generic_mesh_kdtree.hpp>
#include <frantic/geometry/triangle_utils.hpp>
#include <frantic/max3d/convert.hpp>
#include <frantic/max3d/rendering/renderplugin_utils.hpp>

#include "MaxKrakatoaRenderGlobalContext.h"
#include "MaxKrakatoaRenderInstance.h"
#include "MaxKrakatoaSceneContext.h"

#include <shadgen.h>

MaxKrakatoaRenderGlobalContext::MaxKrakatoaRenderGlobalContext()
    : m_progressLogger( NULL, _T("Rendering Particles") ) {
    frantic::max3d::rendering::initialize_renderglobalcontext( *this );
}

MaxKrakatoaRenderGlobalContext::~MaxKrakatoaRenderGlobalContext() {}

void MaxKrakatoaRenderGlobalContext::reset() {
    m_sceneContext.reset();
    m_instances.clear();
    m_lightDescs.clear();
}

void MaxKrakatoaRenderGlobalContext::reset( krakatoa::scene_context_ptr sceneContext ) {
    if( sceneContext == m_sceneContext )
        return;

    m_sceneContext = sceneContext;
    m_instances.clear();
    m_lightDescs.clear();

    m_channelMap.reset();
    m_channelMap.define_channel<frantic::graphics::vector3f>( _T("Position") );
    m_channelMap.end_channel_definition();

    const frantic::graphics::camera<float>& renderCam = sceneContext->get_camera();

    camToWorld = frantic::max3d::to_max_t( renderCam.world_transform() );
    worldToCam = frantic::max3d::to_max_t( renderCam.world_transform_inverse() );
    nearRange = renderCam.near_distance();
    farRange = renderCam.far_distance();
    devAspect = renderCam.pixel_aspect();
    devWidth = renderCam.get_output_size().xsize;
    devHeight = renderCam.get_output_size().ysize;
    projType = ( renderCam.projection_mode() == frantic::graphics::projection_mode::orthographic ) ? PROJ_PARALLEL
                                                                                                   : PROJ_PERSPECTIVE;
    time = SecToTicks( sceneContext->get_time() );

    xc = (float)devWidth * 0.5f;
    yc = (float)devHeight * 0.5f;

    if( projType == PROJ_PERSPECTIVE ) {
        float v = xc / std::tan( 0.5f * renderCam.horizontal_fov() );
        xscale = -v;
        yscale = v * devAspect;
    } else {
        const float VIEW_DEFAULT_WIDTH = 400.f;
        xscale = (float)devWidth / ( VIEW_DEFAULT_WIDTH * renderCam.orthographic_width() );
        yscale = -devAspect * xscale;
    }

    m_viewParams.affineTM = worldToCam;
    m_viewParams.prevAffineTM = worldToCam;
    m_viewParams.projType = projType;
    m_viewParams.hither = renderCam.near_distance();
    m_viewParams.yon = renderCam.far_distance();
    m_viewParams.distance = renderCam.focal_distance();
    m_viewParams.zoom = renderCam.orthographic_width();
    m_viewParams.fov = renderCam.horizontal_fov();
    m_viewParams.nearRange = m_viewParams.hither;
    m_viewParams.farRange = m_viewParams.yon;
}

const krakatoa::scene_context_ptr MaxKrakatoaRenderGlobalContext::get_scene_context() const { return m_sceneContext; }

krakatoa::scene_context_ptr MaxKrakatoaRenderGlobalContext::get_scene_context() { return m_sceneContext; }

void MaxKrakatoaRenderGlobalContext::set_renderprogress_callback( RendProgressCallback* rendProgressCallback ) {
    m_progressLogger.set_render_progress_callback( rendProgressCallback );
}

void MaxKrakatoaRenderGlobalContext::set_channel_map( const frantic::channels::channel_map& pcm ) {
    m_channelMap = pcm;

    if( !m_channelMap.channel_definition_complete() )
        m_channelMap.end_channel_definition();
}

RenderInstance* MaxKrakatoaRenderGlobalContext::add_geometry_instance( INode* pNode ) {
    boost::shared_ptr<MaxKrakatoaRenderInstance> result( new MaxKrakatoaRenderInstance( this, pNode ) );
    result->nodeID = (int)m_instances.size();
    result->GetINode()->SetRenderID( (UWORD)result->nodeID );

    if( !m_instances.empty() )
        m_instances.back()->set_next( result.get() );
    m_instances.push_back( result );

    return result.get();
}

RenderInstance* MaxKrakatoaRenderGlobalContext::add_particle_instance( INode* /*pNode*/ ) {
    return NULL;
}

RenderInstance* MaxKrakatoaRenderGlobalContext::get_instance_from_node( INode* pNode ) const {
    int index = pNode->GetRenderID();
    if( index >= 0 && index < (int)m_instances.size() )
        return m_instances[index].get();
    return NULL;
}

namespace {
bool IsSubClassOf_GenLight( Object* obj ) {
    return obj->IsSubClassOf( Class_ID( OMNI_LIGHT_CLASS_ID, 0x0 ) ) ||
           obj->IsSubClassOf( Class_ID( SPOT_LIGHT_CLASS_ID, 0x0 ) ) ||
           obj->IsSubClassOf( Class_ID( FSPOT_LIGHT_CLASS_ID, 0x0 ) ) ||
           obj->IsSubClassOf( Class_ID( DIR_LIGHT_CLASS_ID, 0x0 ) ) ||
           obj->IsSubClassOf( Class_ID( TDIR_LIGHT_CLASS_ID, 0x0 ) ) || obj->IsSubClassOf( MR_OMNI_LIGHT_CLASS_ID ) ||
           obj->IsSubClassOf( MR_SPOT_LIGHT_CLASS_ID );
}
} // namespace

void MaxKrakatoaRenderGlobalContext::add_light( INode* pNode ) {
    ObjectState os = pNode->EvalWorldState( time );

    if( !os.obj || os.obj->SuperClassID() != LIGHT_CLASS_ID )
        return;

    LightObject* pLight = static_cast<LightObject*>( os.obj );

    /*if( !IsSubClassOf_GenLight(pLight) ){
            FF_LOG(warning) << _T("Light: \"" pNode->GetName() << _T("\" is ignored in reflections") << std::endl;
            return;
    }*/

    if( IsSubClassOf_GenLight( pLight ) ) {
        ShadowType* pShad = static_cast<GenLight*>( pLight )->GetShadowGenerator();
        if( pShad && pLight->GetShadow() && pShad->ClassID() == Class_ID( 1377054321, 1344292659 ) ) {
            FF_LOG( warning ) << _T("Light: \"") << pNode->GetName()
                              << _T("\" with VRayShadowMap is not support by Krakatoa!") << std::endl;
            return;
        }
    }

    struct MyDeleter {
        static void eval( ObjLightDesc* obj ) {
            if( obj )
                obj->DeleteThis();
        }
    };

    boost::shared_ptr<ObjLightDesc> result( pLight->CreateLightDesc( this, pNode ), &MyDeleter::eval );

    // CreateLightDesc() can return NULL, so we have to bail.
    if( !result ) {
        FF_LOG( warning ) << _T("Light: \"") << pNode->GetName() << _T("\" did not have a valid ObjLightDesc")
                          << std::endl;
        return;
    }

    pNode->SetRenderData( result.get() );

    class MyRendContext : public RendContext {
        frantic::logging::progress_logger* m_pProgress;

      public:
        MyRendContext( frantic::logging::progress_logger& progressLogger )
            : m_pProgress( &progressLogger ) {}

        virtual int Progress( int done, int total ) const {
            try {
                m_pProgress->update_progress( done, total );
                return TRUE;
            } catch( const frantic::logging::progress_cancel_exception& ) {
                return FALSE;
            }
        }

        virtual Color GlobalLightLevel() const { return Color( 1, 1, 1 ); }
    } theRendContext( m_progressLogger );

    result->renderNumber = (int)m_lightDescs.size();
    result->Update( this->time, theRendContext, this, TRUE, TRUE );
    result->UpdateViewDepParams( this->worldToCam ); // TODO: This should happen once per mblur pass...

    m_lightDescs.push_back( result );
}

ObjLightDesc* MaxKrakatoaRenderGlobalContext::get_light_desc( int i ) { return m_lightDescs[i].get(); }

int MaxKrakatoaRenderGlobalContext::get_num_light_desc() const { return (int)m_lightDescs.size(); }

// const frantic::graphics::camera<float>& MaxKrakatoaRenderGlobalContext::get_camera() const {
//	return m_sceneContext->get_camera();
// }
//
// const frantic::channels::channel_map& MaxKrakatoaRenderGlobalContext::get_channel_map() const {
//	return m_channelMap;
// }
//
// frantic::logging::progress_logger& MaxKrakatoaRenderGlobalContext::get_progress_logger(){
//	return m_progressLogger;
// }
//
// RenderGlobalContext& MaxKrakatoaRenderGlobalContext::get_max_context(){
//	return *this;
// }
//
// std::pair<float,float> MaxKrakatoaRenderGlobalContext::get_motion_blur_params() const {
//	return std::pair<float,float>(0.f,0.f);
// }
Class_ID MaxKrakatoaRenderGlobalContext::GetContextID() const {
    return /*MaxKrakatoa_CLASS_ID*/ Class_ID( 0xb836c39a, 0xe829b319 );
}

bool MaxKrakatoaRenderGlobalContext::WantsWorldSpaceParticles() const { return true; }

bool MaxKrakatoaRenderGlobalContext::WantsMaterialEffects() const { return true; }

RenderGlobalContext& MaxKrakatoaRenderGlobalContext::GetRenderGlobalContext() const {
    return const_cast<MaxKrakatoaRenderGlobalContext&>( *this );
}

const frantic::graphics::camera<float>& MaxKrakatoaRenderGlobalContext::GetCamera() const {
    return m_sceneContext->get_camera();
}

const frantic::channels::channel_map& MaxKrakatoaRenderGlobalContext::GetDefaultChannels() const {
    return m_channelMap;
}

frantic::logging::progress_logger& MaxKrakatoaRenderGlobalContext::GetProgressLogger() const {
    return const_cast<frantic::max3d::logging::maxrender_progress_logger&>( m_progressLogger );
}

bool MaxKrakatoaRenderGlobalContext::GetProperty( const Class_ID& /*propID*/, void* /*pTarget*/ ) const {
    return false;
}

int MaxKrakatoaRenderGlobalContext::NumRenderInstances() { return (int)m_instances.size(); }

RenderInstance* MaxKrakatoaRenderGlobalContext::GetRenderInstance( int i ) {
    return i >= 0 ? m_instances[i].get() : NULL;
}

FilterKernel* MaxKrakatoaRenderGlobalContext::GetAAFilterKernel() { return RenderGlobalContext::GetAAFilterKernel(); }

float MaxKrakatoaRenderGlobalContext::GetAAFilterSize() { return RenderGlobalContext::GetAAFilterSize(); }

AColor MaxKrakatoaRenderGlobalContext::EvalGlobalEnvironMap( ShadeContext& sc, Ray& r, BOOL applyAtmos ) {
    return RenderGlobalContext::EvalGlobalEnvironMap( sc, r, applyAtmos );
}

bool intersect_mesh( RenderInstance* instance, const Ray& _ray, float& inoutT, int& faceNum, Point3& baryCoord );

void MaxKrakatoaRenderGlobalContext::IntersectRay( RenderInstance* inst, Ray& ray, ISect& isct, ISectList& /*xpList*/,
                                                   BOOL /*findExit*/ ) {
    // return RenderGlobalContext::IntersectRay(inst, ray, isct, xpList, findExit);
    if( !inst || inst->mesh == NULL )
        return;

    isct.t = FLT_MAX;

    /*if( intersect_mesh(inst, ray, isct.t, isct.fnum, isct.bc) ){
            isct.backFace = FALSE;
            isct.exit = FALSE;
            isct.next = NULL;
            isct.inst = inst;

            isct.mtlNum = isct.inst->mesh->faces[isct.fnum].getMatID();
            isct.matreq = isct.inst->MtlRequirements(isct.mtlNum, isct.fnum);

            Point3 tri[3];
            isct.inst->GetObjVerts( isct.fnum, tri );
            isct.p = isct.bc.x * tri[0] + isct.bc.y * tri[1] + isct.bc.z * tri[2];
            isct.pc = isct.inst->objToCam.PointTransform( isct.p );
    }*/
    Point3 pc = inst->center - ray.p;
    float v = DotProd( pc, ray.dir );
    if( inst->radsq - DotProd( pc, pc ) + v * v >= 0.0f )
        static_cast<MaxKrakatoaRenderInstance*>( inst )->intersect_ray( ray, 0.f, isct.t, isct );

    isct.backFace = FALSE;
    isct.exit = FALSE;
    isct.next = NULL;

    if( isct.inst != NULL ) {
        isct.mtlNum = isct.inst->mesh->faces[isct.fnum].getMatID();
        isct.matreq = isct.inst->MtlRequirements( isct.mtlNum, isct.fnum );

        Point3 tri[3];
        isct.inst->GetObjVerts( isct.fnum, tri );

        isct.p = isct.bc.x * tri[0] + isct.bc.y * tri[1] + isct.bc.z * tri[2];
        isct.pc = isct.inst->objToCam.PointTransform( isct.p );
    }
}

BOOL MaxKrakatoaRenderGlobalContext::IntersectWorld( Ray& ray, int skipID, ISect& hit, ISectList& /*xplist*/,
                                                     int blurFrame ) {
    // return RenderGlobalContext::IntersectWorld(ray,skipID, hit, xplist, blurFrame);
    hit.t = FLT_MAX;
    hit.inst = NULL;

    for( std::vector<boost::shared_ptr<MaxKrakatoaRenderInstance>>::const_iterator it = m_instances.begin(),
                                                                                   itEnd = m_instances.end();
         it != itEnd; ++it ) {
        if( skipID == ( *it )->nodeID || ( *it )->mesh == NULL ||
            ( blurFrame != NO_MOTBLUR && ( *it )->objMotBlurFrame != NO_MOTBLUR &&
              ( *it )->objMotBlurFrame != blurFrame ) )
            continue;

        // Reject object based on bounding sphere.
        Point3 pc = ( *it )->center - ray.p;
        float v = DotProd( pc, ray.dir );
        if( ( *it )->radsq - DotProd( pc, pc ) + v * v >= 0.0f ) {
            // ISect isct;
            // isct.t = hit.t;
            // isct.inst = (*it).get();
            // MaxKrakatoaRenderInstance* inst = (*it).get();

            /*if( inst->get_kdtree().get_mesh_ptr() != NULL ){
                    frantic::geometry::raytrace_intersection ri;
                    frantic::graphics::ray3f r(
                            frantic::max3d::from_max_t( inst->camToObj.PointTransform(ray.p) ),
                            frantic::max3d::from_max_t( inst->camToObj.VectorTransform(ray.dir) ) );

                    if( inst->get_kdtree().intersect_ray( r, 0.f, hit.t, ri ) ){
                            hit.t = (float)ri.distance;
                            hit.inst = inst;
                            hit.fnum = ri.faceIndex;
                            hit.bc = frantic::max3d::to_max_t( ri.barycentricCoords );
                    }
            }*/
            // if( intersect_mesh(isct.inst, ray, isct.t, isct.fnum, isct.bc) )
            //	hit = isct;

            ( *it )->intersect_ray( ray, 0.f, hit.t, hit );
        }
    }

    hit.backFace = FALSE;
    hit.exit = FALSE;
    hit.next = NULL;

    if( hit.inst != NULL ) {
        hit.mtlNum = hit.inst->mesh->faces[hit.fnum].getMatID();
        hit.matreq = hit.inst->MtlRequirements( hit.mtlNum, hit.fnum );

        Point3 tri[3];
        hit.inst->GetObjVerts( hit.fnum, tri );

        hit.p = hit.bc.x * tri[0] + hit.bc.y * tri[1] + hit.bc.z * tri[2];
        hit.pc = hit.inst->objToCam.PointTransform( hit.p );

        return TRUE;
    }

    return FALSE;
}

ViewParams* MaxKrakatoaRenderGlobalContext::GetViewParams() { return &m_viewParams; }
