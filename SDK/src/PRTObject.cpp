// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0
#include "stdafx.h"

#include <krakatoa/max3d/IPRTMaterial.hpp>
#include <krakatoa/max3d/IPRTModifier.hpp>
#include <krakatoa/max3d/PRTObject.hpp>

#include <frantic/max3d/AutoViewExp.hpp>
#include <frantic/max3d/logging/status_panel_progress_logger.hpp>
#include <frantic/max3d/max_utility.hpp>
#include <frantic/max3d/particles/streams/deformed_particle_istream.hpp>
#include <frantic/max3d/shaders/map_query.hpp>

#include <frantic/graphics/camera.hpp>
#include <frantic/particles/streams/apply_function_particle_istream.hpp>
#include <frantic/particles/streams/empty_particle_istream.hpp>
#include <frantic/particles/streams/selection_culled_particle_istream.hpp>
#include <frantic/particles/streams/set_channel_particle_istream.hpp>
#include <frantic/particles/streams/transformed_particle_istream.hpp>

#include <boost/scoped_ptr.hpp>

#define KMX_SUPPORT_MESH_MODIFIERS

using frantic::graphics::color3f;
using frantic::graphics::vector3f;
using frantic::max3d::particles::IMaxKrakatoaPRTObject;

namespace krakatoa {
namespace max3d {

extern boost::shared_ptr<frantic::particles::streams::particle_istream>
ApplyStdMaterial( boost::shared_ptr<frantic::particles::streams::particle_istream> pin, Mtl* pMtl,
                  const frantic::max3d::shaders::renderInformation& renderInfo, bool doShadeColor,
                  bool doShadeAbsorption, bool doShadeEmission, bool doShadeDensity, TimeValue t );

#ifndef LEGACY_KCM_ENABLED
inline bool is_krakatoa_delete_modifier( ReferenceTarget* pMod ) {
    return
        // Normal delete modifier
        ( pMod->ClassID() == Class_ID( 0x7fc844e7, 0x1fe348d5 ) ) != FALSE ||
        // WSM version
        ( pMod->ClassID() == Class_ID( 0x13b4570d, 0x4c44758b ) ) != FALSE;
}
#endif

PRTObjectBase::PRTObjectBase() {
    m_viewportValidity = NEVER;
    m_objectValidity = NEVER;

    m_viewportBounds.Init();
    m_inRenderMode = false;
    m_hasVectors = false;
}

PRTObjectBase::~PRTObjectBase() {}

void PRTObjectBase::BuildViewportCache( INode* pNode, ViewExp* pView, TimeValue t ) {
    if( m_viewportValidity.InInterval( t ) )
        return;

    m_viewportBounds.Init();
    m_viewportCache.clear();
    m_viewportValidity = FOREVER;

    frantic::graphics::camera<float> theCamera;
    {
        frantic::max3d::AutoViewExp activeView;
        if( !pView ) {
            pView =
#if MAX_VERSION_MAJOR >= 15
                &GetCOREInterface()->GetActiveViewExp();
#else
                GetCOREInterface()->GetActiveViewport();
#endif
            activeView.reset( pView );
        }

        Matrix3 tm;
        pView->GetAffineTM( tm );

        theCamera.set_transform( frantic::max3d::from_max_t( Inverse( tm ) ) );
        theCamera.set_horizontal_fov( pView->GetFOV() );
        theCamera.set_projection_mode( pView->IsPerspView() ? frantic::graphics::projection_mode::perspective
                                                            : frantic::graphics::projection_mode::orthographic );
    }

    frantic::channels::channel_map viewportMap;
    viewportMap.define_channel( _T("Position"), 3, frantic::channels::data_type_float32,
                                offsetof( particle_t, m_position ) );
    viewportMap.define_channel( _T("PRTViewportVector"), 3, frantic::channels::data_type_float32,
                                offsetof( particle_t, m_vector ) );
    viewportMap.define_channel( _T("PRTViewportColor"), 3, frantic::channels::data_type_float32,
                                offsetof( particle_t, m_color ) );
    viewportMap.end_channel_definition( 4u, true, false );

    frantic::max3d::particles::IMaxKrakatoaPRTEvalContextPtr theContext =
        frantic::max3d::particles::CreateMaxKrakatoaPRTEvalContext( t, Class_ID( 0x5ccc4d89, 0x35345085 ), &theCamera,
                                                                    &viewportMap );

    boost::shared_ptr<frantic::particles::streams::particle_istream> pin =
        this->CreateStream( pNode, m_viewportValidity, theContext );

    if( !m_viewportValidity.InInterval( t ) )
        m_viewportValidity.SetInstant( t );

    m_hasVectors = pin->get_native_channel_map().has_channel( _T("PRTViewportVector") );

    if( !pin->get_native_channel_map().has_channel( _T("PRTViewportColor") ) ) {
        if( pin->get_native_channel_map().has_channel( _T("Color") ) ) {
            class Color_to_PRTViewportColor {
              public:
                static frantic::graphics::color3f fn( const frantic::graphics::color3f& inColor ) { return inColor; }
            };

            boost::array<frantic::tstring, 1> copy_op_inputs = { _T("Color") };
            pin.reset( new frantic::particles::streams::apply_function_particle_istream<color3f( const color3f& )>(
                pin, &Color_to_PRTViewportColor::fn, _T("PRTViewportColor"), copy_op_inputs ) );
        }
    }

    boost::int64_t numParticles = pin->particle_count();
    if( numParticles >= 0 )
        m_viewportCache.reserve( (std::size_t)numParticles );

    particle_t tempParticle;
    memset( &tempParticle, 0, sizeof( particle_t ) );

    pin->set_default_particle( (char*)&tempParticle );

    while( pin->get_particle( (char*)&tempParticle ) ) {
        tempParticle.m_color.r = frantic::math::clamp( tempParticle.m_color.r, 0.f, 1.f );
        tempParticle.m_color.g = frantic::math::clamp( tempParticle.m_color.g, 0.f, 1.f );
        tempParticle.m_color.b = frantic::math::clamp( tempParticle.m_color.b, 0.f, 1.f );

        m_viewportBounds += tempParticle.m_position;
        if( m_hasVectors )
            m_viewportBounds += tempParticle.m_position + tempParticle.m_vector;
        m_viewportCache.push_back( tempParticle );
    }

    pin.reset();
}

void PRTObjectBase::ClearViewportCaches() {
    this->InvalidateViewport();
    m_viewportCache.clear();
}

void PRTObjectBase::InvalidateViewport() { m_viewportValidity.SetEmpty(); }

void PRTObjectBase::InvalidateObjectAndViewport() {
    m_objectValidity.SetEmpty();
    InvalidateViewport();
}

template <class Fn>
void EvalPipelineModifiers( IDerivedObject* pDerivObj, Fn& fn ) {
    Object* pNextObj = pDerivObj->GetObjRef();
    if( pNextObj && pNextObj->SuperClassID() == GEN_DERIVOB_CLASS_ID )
        EvalPipelineModifiers( (IDerivedObject*)pNextObj, fn );

    for( int i = pDerivObj->NumModifiers() - 1; i >= 0; --i )
        fn( pDerivObj->GetModifier( i ), pDerivObj->GetModContext( i ) );
}

template <class Fn>
void EvalPipelineModifiers( INode* pNode, Fn& fn ) {
    Object* pObj = pNode->GetObjOrWSMRef();

    if( pObj && pObj->SuperClassID() == GEN_DERIVOB_CLASS_ID )
        EvalPipelineModifiers( (IDerivedObject*)pObj, fn );
}

void GetPipelineModifiers( INode* pNode, std::vector<std::pair<Modifier*, ModContext*>>& outModifiers,
                           bool forRender ) {
    class GetModifiersFn : boost::noncopyable {
        std::vector<std::pair<Modifier*, ModContext*>>& m_result;
        bool m_forRender;

      public:
        GetModifiersFn( std::vector<std::pair<Modifier*, ModContext*>>& outputLocation, bool forRender )
            : m_result( outputLocation )
            , m_forRender( forRender ) {}

        void operator()( Modifier* mod, ModContext* modContext ) {
            if( mod->IsEnabled() && ( m_forRender ? mod->IsEnabledInRender() : mod->IsEnabledInViews() ) )
                m_result.push_back( std::make_pair( mod, modContext ) );
        }
    } fn( outModifiers, forRender );

    EvalPipelineModifiers( pNode, fn );
}

particle_istream_ptr PRTObjectBase::ApplyModifiersAndMtl( particle_istream_ptr pin, INode* pNode, TimeValue t,
                                                          Interval& inoutValidity,
                                                          boost::shared_ptr<IEvalContext> pEvalContext ) {
    Modifier* stopMod = NULL;
    ModContext* stopModContext = NULL;

    if( IMaxKrakatoaEvalContext* krakCtx = dynamic_cast<IMaxKrakatoaEvalContext*>( pEvalContext.get() ) ) {
        boost::tie( stopMod, stopModContext ) = krakCtx->get_eval_endpoint();
    }

    bool applyTM = pEvalContext->WantsWorldSpaceParticles() && !this->InWorldSpace();
    bool applyMtl = pEvalContext->WantsMaterialEffects();

    Interval tmValid = FOREVER;

    frantic::graphics::transform4f tm = frantic::max3d::from_max_t( pNode->GetObjTMBeforeWSM( t, &tmValid ) );
    frantic::graphics::transform4f tmDeriv = frantic::max3d::from_max_t( pNode->GetObjTMBeforeWSM( t + 20 ) );
    tmDeriv -= tm;
    tmDeriv *= ( 1.f * TIME_TICKSPERSEC / 20 );

    std::vector<std::pair<Modifier*, ModContext*>> nodeMods, curLegacyMods;
    GetPipelineModifiers( pNode, nodeMods, m_inRenderMode );

    std::vector<std::pair<Modifier*, ModContext*>>::iterator it = nodeMods.begin(), itEnd = nodeMods.end();

    for( ; it != itEnd && it->first->SuperClassID() == OSM_CLASS_ID &&
           ( it->first != stopMod || it->second != stopModContext );
         ++it ) {
        IPRTModifier* imod = GetPRTModifierInterface( it->first );

        // Check for scripted PRTModifiers
        if( !imod ) {
            void* scriptedMod = it->first->GetInterface( I_MAXSCRIPTPLUGIN );
            if( scriptedMod ) {
                MSPluginModifier* msScriptedMod = static_cast<MSPluginModifier*>( scriptedMod );
                if( msScriptedMod ) {
                    imod = GetPRTModifierInterface( msScriptedMod->get_delegate() );
                }
            }
        }

        if( imod ) {
            if( !curLegacyMods.empty() ) {
                pin.reset( new frantic::max3d::particles::streams::deformed_particle_istream( pin, curLegacyMods, pNode,
                                                                                              t, 20 ) );
                curLegacyMods.clear();

                // We don't have validity information for this, so conservatively set it to 't'.
                inoutValidity.SetInstant( t );
            }
            pin = imod->ApplyModifier( pin, pNode, t, inoutValidity, pEvalContext );

#ifdef LEGACY_KCM_ENABLED
        } else if( is_krakatoa_channel_modifier( it->first ) ) {
            if( !curLegacyMods.empty() ) {
                pin.reset( new frantic::max3d::particles::streams::deformed_particle_istream( pin, curLegacyMods, pNode,
                                                                                              t, 20 ) );
                curLegacyMods.clear();

                // We don't have validity information for this, so conservatively set it to 't'.
                inoutValidity.SetInstant( t );
            }
            pin = get_krakatoa_channel_modifier_particle_istream( pin, globContext, pNode, it->first );

            // We don't have validity information for this, so conservatively set it to 't'.
            inoutValidity.SetInstant( t );
#endif
        } else if( is_krakatoa_delete_modifier( it->first ) ) {
            if( !curLegacyMods.empty() ) {
                pin.reset( new frantic::max3d::particles::streams::deformed_particle_istream( pin, curLegacyMods, pNode,
                                                                                              t, 20 ) );
                curLegacyMods.clear();

                // We don't have validity information for this, so conservatively set it to 't'.
                inoutValidity.SetInstant( t );
            }

            bool useSoftSel = frantic::max3d::mxs::expression( _T("theMod.SelectionMode") )
                                  .bind( _T("theMod"), it->first )
                                  .evaluate<int>() == 2;

            bool resetSelection = frantic::max3d::mxs::expression( _T("try(theMod.ResetSelection)catch(false)") )
                                      .bind( _T("theMod"), it->first )
                                      .evaluate<bool>();

            if( useSoftSel && !pin->get_native_channel_map().has_channel( _T("ID") ) ) {
                bool warnIfNoID = true;
                if( !m_inRenderMode ) {
                    warnIfNoID = frantic::max3d::mxs::expression(
                                     _T("if theMod.showMissingIDWarning then ( theMod.showMissingIDWarning = false; ")
                                     _T("true ) else ( false )") )
                                     .bind( _T("theMod"), it->first )
                                     .evaluate<bool>();
                }

                if( warnIfNoID ) {
                    FF_LOG( warning ) << _T("Krakatoa Delete requires a valid ID channel for a soft-selection ")
                                         _T("delete. It is falling back on the Index channel which may give ")
                                         _T("inconsistent results.")
                                      << std::endl;
                }
            }

            pin.reset(
                new frantic::particles::streams::selection_culled_particle_istream( pin, useSoftSel, resetSelection ) );
        } else {
            bool skip = false;

            // Add further hard-coded crap here.
            if( it->first->ClassID() == Class_ID( SELECTOSM_CLASS_ID, 0 ) ) {
                skip = frantic::max3d::mxs::expression( _T("theMod.volume == 3") )
                           .bind( _T("theMod"), it->first )
                           .evaluate<bool>();
            }

#ifdef KMX_SUPPORT_MESH_MODIFIERS
            if( !skip )
                curLegacyMods.push_back( *it );
#endif
        }
    }

    if( !curLegacyMods.empty() ) {
        pin.reset(
            new frantic::max3d::particles::streams::deformed_particle_istream( pin, curLegacyMods, pNode, t, 20 ) );
        curLegacyMods.clear();

        // We don't have validity information for this, so conservatively set it to 't'.
        inoutValidity.SetInstant( t );
    }

    // We may have requested a partial pipeline evaluation (via. IMaxKrakatoaEvalContext::get_eval_endpoint()) so we
    // return early.
    if( it != itEnd && it->first == stopMod && it->second == stopModContext )
        return pin;

    if( applyTM ) {
        // Apply the transformation into world space.
        pin = apply_transform_to_particle_istream( pin, tm, tmDeriv );

        inoutValidity &= tmValid;
    }

    // Collect WSModifiers
#ifdef KMX_SUPPORT_MESH_MODIFIERS
    for( ; it != itEnd && it->first->SuperClassID() == WSM_CLASS_ID; ++it ) {
        if( is_krakatoa_delete_modifier( it->first ) ) {
            if( !curLegacyMods.empty() ) {
                pin.reset( new frantic::max3d::particles::streams::deformed_particle_istream( pin, curLegacyMods, pNode,
                                                                                              t, 20 ) );
                curLegacyMods.clear();

                // We don't have validity information for this, so conservatively set it to 't'.
                inoutValidity.SetInstant( t );
            }

            bool useSoftSel = frantic::max3d::mxs::expression( _T( "theMod.SelectionMode" ) )
                                  .bind( _T( "theMod" ), it->first )
                                  .evaluate<int>() == 2;

            bool resetSelection = frantic::max3d::mxs::expression( _T( "try(theMod.ResetSelection)catch(false)" ) )
                                      .bind( _T( "theMod" ), it->first )
                                      .evaluate<bool>();

            if( useSoftSel && !pin->get_native_channel_map().has_channel( _T( "ID" ) ) ) {
                bool warnIfNoID = true;
                if( !m_inRenderMode ) {
                    warnIfNoID =
                        frantic::max3d::mxs::expression(
                            _T( "if theMod.showMissingIDWarning then ( theMod.showMissingIDWarning = false; true ) else ( false )" ) )
                            .bind( _T( "theMod" ), it->first )
                            .evaluate<bool>();
                }

                if( warnIfNoID ) {
                    FF_LOG( warning ) << _T( "Krakatoa Delete requires a valid ID channel for a soft-selection " )
                                         _T( "delete. It is falling back on the Index channel which may give " )
                                         _T( "inconsistent results." )
                                      << std::endl;
                }
            }

            pin.reset(
                new frantic::particles::streams::selection_culled_particle_istream( pin, useSoftSel, resetSelection ) );
        } else if( IPRTModifier* imod = GetPRTModifierInterface( it->first ) ) {
            if( !curLegacyMods.empty() ) {
                pin.reset( new frantic::max3d::particles::streams::deformed_particle_istream( pin, curLegacyMods, pNode,
                                                                                              t, 20 ) );
                curLegacyMods.clear();

                // We don't have validity information for this, so conservatively set it to 't'.
                inoutValidity.SetInstant( t );
            }
            pin = imod->ApplyModifier( pin, pNode, t, inoutValidity, pEvalContext );
        } else {
            curLegacyMods.push_back( *it );
        }
    }
#endif

    if( !curLegacyMods.empty() ) {
        pin.reset(
            new frantic::max3d::particles::streams::deformed_particle_istream( pin, curLegacyMods, pNode, t, 20 ) );

        // We don't have validity information for this, so conservatively set it to 't'.
        inoutValidity.SetInstant( t );
    }

    Mtl* pMtl = pNode->GetMtl();
    if( pMtl && applyMtl ) {
        if( IPRTMaterial* prtMtl = GetPRTMaterialInterface( pMtl ) ) {
            pin = prtMtl->ApplyMaterial( pin, pNode, t, inoutValidity, pEvalContext );
        } else {
            frantic::max3d::shaders::renderInformation localRenderInfo;
            localRenderInfo.m_camera = pEvalContext->GetCamera();
            localRenderInfo.m_cameraPosition = frantic::max3d::to_max_t( localRenderInfo.m_camera.camera_position() );
            localRenderInfo.m_toObjectTM = frantic::max3d::from_max_t( Inverse( pNode->GetNodeTM( t ) ) );
            localRenderInfo.m_toWorldTM = frantic::graphics::transform4f::identity();

            pin = ApplyStdMaterial( pin, pMtl, localRenderInfo, true, true, true, true, t );

            // We don't have validity information for this, so conservatively set it to 't'.
            inoutValidity.SetInstant( t );
        }
    }

    // If we have no mtl, or the mtl doesn't affect the Color channel, then we should apply wire color.
    if( !pin->get_native_channel_map().has_channel( _T("Color") ) )
        pin.reset( new frantic::particles::streams::set_channel_particle_istream<frantic::graphics::color3f>(
            pin, _T("Color"), frantic::graphics::color3f::from_RGBA( pNode->GetWireColor() ) ) );

    return pin;
}

// From IMaxKrakatoaPRTObject
particle_istream_ptr PRTObjectBase::CreateStream( INode* pNode, Interval& outValidity,
                                                  boost::shared_ptr<IEvalContext> pEvalContext ) {
    FF_LOG( debug ) << _T("Evaluating PRT object from node: \"") << ( pNode ? pNode->GetName() : _T("") ) << _T("\" ")
                    << ( m_inRenderMode ? _T("") : _T("not") ) << _T(" in render mode") << std::endl;

    outValidity = FOREVER;

    TimeValue t = pEvalContext->GetTime();

    // TODO: We can potentially temporarily switch to render mode for this (and all references) when evaluating the
    // stream if 'pEvalContext' requests it.

    particle_istream_ptr result = this->GetInternalStream( pNode, t, outValidity, pEvalContext );

    // If we didn't produce a valid stream (which might not be the best idea, but its going to happen anyways) make an
    // empty stream instead.
    if( !result ) {
        frantic::channels::channel_map defaultMap;
        defaultMap.define_channel( _T("Position"), 3, frantic::channels::data_type_float32 );
        defaultMap.end_channel_definition();

        result.reset( new frantic::particles::streams::empty_particle_istream( defaultMap ) );
    }

    result = ApplyModifiersAndMtl( result, pNode, t, outValidity, pEvalContext );

    if( !outValidity.InInterval( t ) )
        outValidity.SetInstant( t );

    return result;
}

void PRTObjectBase::GetStreamNativeChannels( INode* pNode, TimeValue t,
                                             frantic::channels::channel_map& outChannelMap ) {
    Interval garbageInterval;

    particle_istream_ptr pStream =
        this->IMaxKrakatoaPRTObject::CreateStream( pNode, t, garbageInterval, Class_ID( 0, 0 ) );

    outChannelMap = pStream->get_native_channel_map();
}

// From Animatable
int PRTObjectBase::RenderBegin( TimeValue /*t*/, ULONG /*flags*/ ) {
    InvalidateObjectAndViewport();
    m_inRenderMode = true;

    return TRUE;
}

int PRTObjectBase::RenderEnd( TimeValue /*t*/ ) {
    InvalidateObjectAndViewport();
    m_inRenderMode = false;

    return TRUE;
}

BaseInterface* PRTObjectBase::GetInterface( Interface_ID id ) {
    // Support the legacy interface.
    if( id == MAXKRAKATOAPRTOBJECT_LEGACY1_INTERFACE )
        return static_cast<IMaxKrakatoaPRTObject_Legacy1*>( this );

    if( id == MAXKRAKATOAPRTOBJECT_LEGACY2_INTERFACE )
        return static_cast<IMaxKrakatoaPRTObject_Legacy2*>( this );

    // Support the current interface
    if( id == MAXKRAKATOAPRTOBJECT_INTERFACE )
        return static_cast<IMaxKrakatoaPRTObject*>( this );

    // PRT interface API
    if( id == MAXKRAKATOA_PARTICLE_INTERFACE_ID )
        return static_cast<IMaxKrakatoaParticleInterface*>( this );

    if( BaseInterface* bi = IMaxKrakatoaPRTObject::GetInterface( id ) )
        return bi;

    return GeomObject::GetInterface( id );
}

// From BaseObject
int PRTObjectBase::Display( TimeValue t, INode* inode, ViewExp* pView, int /*flags*/ ) {
    try {
        if( inode->IsNodeHidden() || inode->GetBoxMode() )
            return TRUE;

        BuildViewportCache( inode, pView, t );

        GraphicsWindow* gw = pView->getGW();
        DWORD rndLimits = gw->getRndLimits();

        std::vector<particle_t>::const_iterator it = m_viewportCache.begin();
        std::vector<particle_t>::const_iterator itEnd = m_viewportCache.end();

        Matrix3 tm;
        Mesh* pIconMesh = GetIconMesh( tm );

        tm = tm * inode->GetNodeTM( t );

        gw->setTransform( tm );
        frantic::max3d::draw_mesh_wireframe(
            gw, pIconMesh, inode->Selected() ? color3f( 1 ) : color3f::from_RGBA( inode->GetWireColor() ) );

        tm.IdentityMatrix();
        gw->setTransform( tm );

        if( !m_hasVectors || inode->GetVertTicks() != FALSE ) {
            // TODO: Should this be batched? Should we have separate paths for different drivers?
            gw->startMarkers();
            for( ; it != itEnd; ++it ) {
                Point3 p = it->m_position;
                gw->setColor( LINE_COLOR, it->m_color.r, it->m_color.g, it->m_color.b );
                gw->marker( &p, SM_DOT_MRKR );
            }
            gw->endMarkers();
        } else {
            gw->startSegments();
            for( ; it != itEnd; ++it ) {
                Point3 p[] = { it->m_position, it->m_position + it->m_vector };
                gw->setColor( LINE_COLOR, it->m_color.r, it->m_color.g, it->m_color.b );
                gw->segment( p, TRUE );
            }
            gw->endSegments();
        }

        // Draw the particle count
        Point3 p = m_viewportBounds.Max();

        std::basic_stringstream<MCHAR> viewportMessage;
        viewportMessage
            << _T("Count: ") << m_viewportCache.size()
            << _T( ' ' ); // Added the extra space since Max can't figure out how to NOT clip the end of the text off.
        if( inode->GetMtl() )
            viewportMessage << _T("[mtl]");

        gw->setColor( TEXT_COLOR, Color( 1, 1, 1 ) );
        gw->text( &p, const_cast<MCHAR*>( viewportMessage.str().c_str() ) );

        gw->setRndLimits( rndLimits );
    } catch( const std::exception& e ) {
        FF_LOG( error ) << frantic::strings::to_tstring( e.what() ) << std::endl;
        return FALSE;
    }

    return TRUE;
}

int PRTObjectBase::HitTest( TimeValue t, INode* inode, int type, int crossing, int flags, IPoint2* p, ViewExp* vpt ) {
    try {
        BuildViewportCache( inode, vpt, t );

        GraphicsWindow* gw = vpt->getGW();
        DWORD rndLimits = gw->getRndLimits();

        if( ( ( flags & HIT_SELONLY ) && !inode->Selected() ) || gw == NULL || inode == NULL )
            return 0;

        HitRegion hitRegion;
        MakeHitRegion( hitRegion, type, crossing, 4, p );

        gw->setRndLimits( GW_PICK | GW_WIREFRAME );
        gw->setHitRegion( &hitRegion );
        gw->clearHitCode();

        std::vector<particle_t>::const_iterator it = m_viewportCache.begin();
        std::vector<particle_t>::const_iterator itEnd = m_viewportCache.end();

        Matrix3 tm;
        Mesh* pIconMesh = GetIconMesh( tm );

        tm = tm * inode->GetNodeTM( t );

        gw->setTransform( tm );
        if( pIconMesh->select( gw, NULL, &hitRegion ) )
            return TRUE;

        tm.IdentityMatrix();
        gw->setTransform( tm );

        if( !m_hasVectors || inode->GetVertTicks() != FALSE ) {
            gw->startMarkers();
            for( ; it != itEnd; ++it ) {
                Point3 p = it->m_position;
                gw->marker( &p, SM_DOT_MRKR );
            }
            gw->endMarkers();
        } else {
            gw->startSegments();
            for( ; it != itEnd; ++it ) {
                Point3 p[] = { it->m_position, it->m_position + it->m_vector };
                gw->segment( p, TRUE );
            }
            gw->endSegments();
        }
        if( gw->checkHitCode() )
            return TRUE;

        gw->setRndLimits( rndLimits );
    } catch( const std::exception& e ) {
        FF_LOG( error ) << e.what() << std::endl;
        return FALSE;
    }

    return FALSE;
}

void PRTObjectBase::GetWorldBoundBox( TimeValue t, INode* inode, ViewExp* vpt, Box3& box ) {
    try {
        BuildViewportCache( inode, vpt, t );

        box = m_viewportBounds;

        Matrix3 tm;
        Mesh* pIconMesh = GetIconMesh( tm );

        tm = tm * inode->GetNodeTM( t );

        box += pIconMesh->getBoundingBox() * tm;
    } catch( const std::exception& e ) {
        FF_LOG( error ) << e.what() << std::endl;
    }
}

void PRTObjectBase::GetLocalBoundBox( TimeValue t, INode* inode, ViewExp* vpt, Box3& box ) {
    try {
        BuildViewportCache( inode, vpt, t );

        Matrix3 worldToObjectTM = inode->GetNodeTM( t );
        worldToObjectTM.Invert();

        box = m_viewportBounds * worldToObjectTM;

        Matrix3 tm;
        Mesh* pIconMesh = GetIconMesh( tm );

        box += pIconMesh->getBoundingBox() * tm;
    } catch( const std::exception& e ) {
        FF_LOG( error ) << e.what() << std::endl;
    }
}

class PRTObjectCreateCallBack : public CreateMouseCallBack {
    IPoint2 sp1;
    PRTObjectBase* m_obj;

  public:
    void SetObject( PRTObjectBase* obj );

    virtual int proc( ViewExp* vpt, int msg, int point, int flags, IPoint2 m, Matrix3& mat );
};

void PRTObjectCreateCallBack::SetObject( PRTObjectBase* obj ) { m_obj = obj; }

int PRTObjectCreateCallBack::proc( ViewExp* vpt, int msg, int point, int /*flags*/, IPoint2 m, Matrix3& mat ) {
    if( msg == MOUSE_POINT ) {
        switch( point ) {
        case 0: {
            sp1 = m;

            Point3 p = vpt->SnapPoint( m, m, NULL, SNAP_IN_3D );
            mat.IdentityMatrix();
            mat.SetTrans( p );
        } break;
        case 1:
            return CREATE_STOP;
        }
    } else if( msg == MOUSE_MOVE ) {
        switch( point ) {
        case 1: {
            float dist = vpt->GetCPDisp( Point3( 0, 0, 0 ), Point3( (float)M_SQRT2, (float)M_SQRT2, 0.f ), sp1, m );
            dist = vpt->SnapLength( dist );
            dist = 2.f * fabsf( dist );

            m_obj->SetIconSize( dist );
        } break;
        }
    } else if( msg == MOUSE_ABORT ) {
        return CREATE_ABORT;
    }

    return CREATE_CONTINUE;
}

CreateMouseCallBack* PRTObjectBase::GetCreateMouseCallBack( void ) {
    static PRTObjectCreateCallBack theCallback;
    theCallback.SetObject( this );
    return &theCallback;
}

// From Object
// virtual void InitNodeName( MSTR& s );
void PRTObjectBase::GetDeformBBox( TimeValue /*t*/, Box3& box, Matrix3* tm, BOOL /*useSel*/ ) {
    try {
        box.MakeCube( Point3::Origin, 10.f );
        if( tm )
            box = box * ( *tm );
    } catch( const std::exception& e ) {
        FF_LOG( error ) << e.what() << std::endl;
    }
}

Interval PRTObjectBase::ObjectValidity( TimeValue /*t*/ ) { return m_viewportValidity; }

ObjectState PRTObjectBase::Eval( TimeValue /*t*/ ) { return ObjectState( this ); }

#define MaxKrakatoaPRTSourceObject_CLASSID Class_ID( 0x766a7a0d, 0x311b4fbd )

BOOL PRTObjectBase::CanConvertToType( Class_ID obtype ) {
    if( obtype == MaxKrakatoaPRTSourceObject_CLASSID )
        return TRUE;
    return GeomObject::CanConvertToType( obtype );
}

Object* PRTObjectBase::ConvertToType( TimeValue t, Class_ID obtype ) {
    if( obtype == MaxKrakatoaPRTSourceObject_CLASSID )
        return this;
    return GeomObject::ConvertToType( t, obtype );
}

Object* PRTObjectBase::MakeShallowCopy( ChannelMask /*channels*/ ) { return NULL; }

void PRTObjectBase::WSStateInvalidate() { InvalidateViewport(); }

BOOL PRTObjectBase::CanCacheObject() { return FALSE; }

BOOL PRTObjectBase::IsWorldSpaceObject() { return TRUE; }

// From GeomObject
Mesh* PRTObjectBase::GetRenderMesh( TimeValue /*t*/, INode* /*inode*/, View& /*view*/, BOOL& needDelete ) {
    static Mesh* pEmptyMesh = NULL;
    if( !pEmptyMesh )
        pEmptyMesh = new Mesh;

    needDelete = FALSE;

    return pEmptyMesh;
}

} // namespace max3d
} // namespace krakatoa
