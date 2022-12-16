// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0
#pragma once

#include <krakatoa/max3d/IPRTModifier.hpp>
#include <krakatoa/max3d/PRTObject.hpp>

#include <frantic/max3d/rendering/renderplugin_utils.hpp>

#include "MaxKrakatoaReferenceTarget.h"

#include "magma/IMagmaModifier.hpp"
#include "Objects/MaxKrakatoaPRTInterface.h"

#include <frantic/magma/magma_exception.hpp>
#include <frantic/magma/magma_interface.hpp>

#include <frantic/logging/progress_logger.hpp>

#include <interval.h>

extern int GetMaximumDebuggerIterations();

template <typename ModifierType, typename Impl>
class IMagmaModifierImpl : public MaxKrakatoaReferenceTarget<ModifierType, Impl>,
                           public krakatoa::max3d::IPRTModifier,
                           public IMagmaModifier {
  private:
    friend class MagmaModifierDlgProc;
    friend class SpaceMagmaModifierDlgProc;

  protected:
    enum { kMagmaHolderRef };

    struct errorInfoStruct {
        bool present;
        frantic::tstring message;
        frantic::magma::magma_interface::magma_id nodeID;

        errorInfoStruct()
            : present( false )
            , nodeID( -43 )
            , message( _M( "No Error" ) ) {}
    } m_errorInfo;

    void clear_error();
    void set_error( const frantic::magma::magma_exception& e );
    void set_error( const frantic::tstring& message,
                    frantic::magma::magma_interface::magma_id id = frantic::magma::magma_interface::INVALID_ID );
    void notify_error_changed();

  public:
    IMagmaModifierImpl() {}
    virtual ~IMagmaModifierImpl() {}

    virtual BaseInterface* GetInterface( Interface_ID id );

    virtual particle_istream_ptr ApplyModifier( particle_istream_ptr pin, INode* pNode, TimeValue t,
                                                Interval& inoutValidity,
                                                frantic::max3d::particles::IMaxKrakatoaPRTEvalContextPtr evalContext );

    virtual bool GetLastError( TYPE_TSTR_BR_TYPE outMessage, TYPE_INT_BR_TYPE outMagmaID ) const;

    virtual IObject* EvaluateDebug( INode* node, int modIndex, TimeValue t = TIME_NegInfinity );

    virtual RefResult NotifyRefChanged( const Interval& changeInt, RefTargetHandle hTarget, PartID& partID,
                                        RefMessage message, BOOL propagate );

    virtual CreateMouseCallBack* GetCreateMouseCallBack( void );

#if MAX_VERSION_MAJOR >= 24
    virtual const MCHAR* GetObjectName( bool localized );
#elif MAX_VERSION_MAJOR >= 15
    virtual const MCHAR* GetObjectName();
#else
    virtual MCHAR* GetObjectName();
#endif

    virtual Interval LocalValidity( TimeValue t );
    virtual ChannelMask ChannelsUsed();
    virtual ChannelMask ChannelsChanged();
    virtual Class_ID InputType();
    virtual void ModifyObject( TimeValue t, ModContext& mc, ObjectState* os, INode* node );
};

class DebugEvalContext : public krakatoa::max3d::IMaxKrakatoaEvalContext {
  public:
    frantic::graphics::camera<float> renderCamera;
    frantic::channels::channel_map map;
    RenderGlobalContext globContext;

    Modifier* stopMod;
    ModContext* stopModContext;

    mutable frantic::logging::null_progress_logger logger;

    DebugEvalContext()
        : stopMod( NULL )
        , stopModContext( NULL ) {
        frantic::max3d::rendering::initialize_renderglobalcontext( globContext );

        globContext.camToWorld = frantic::max3d::to_max_t( renderCamera.world_transform() );
        globContext.worldToCam = frantic::max3d::to_max_t( renderCamera.world_transform_inverse() );
        globContext.nearRange = renderCamera.near_distance();
        globContext.farRange = renderCamera.far_distance();
        globContext.devAspect = renderCamera.pixel_aspect();
        globContext.devWidth = renderCamera.get_output_size().xsize;
        globContext.devHeight = renderCamera.get_output_size().ysize;
        globContext.projType = ( renderCamera.projection_mode() == frantic::graphics::projection_mode::orthographic )
                                   ? PROJ_PARALLEL
                                   : PROJ_PERSPECTIVE;

        globContext.xc = (float)globContext.devWidth * 0.5f;
        globContext.yc = (float)globContext.devHeight * 0.5f;

        if( globContext.projType == PROJ_PERSPECTIVE ) {
            float v = globContext.xc / std::tan( 0.5f * renderCamera.horizontal_fov() );
            globContext.xscale = -v;
            globContext.yscale = v * globContext.devAspect;
        } else {
            const float VIEW_DEFAULT_WIDTH = 400.f;
            globContext.xscale =
                (float)globContext.devWidth / ( VIEW_DEFAULT_WIDTH * renderCamera.orthographic_width() );
            globContext.yscale = -globContext.devAspect * globContext.xscale;
        }
    }

    // From IMaxKrakatoaEvalContext
    virtual std::pair<Modifier*, ModContext*> get_eval_endpoint() const {
        return std::pair<Modifier*, ModContext*>( stopMod, stopModContext );
    }

    // From IEvalContext
    virtual Class_ID GetContextID() const { return Class_ID( 0, 0 ); }

    virtual bool WantsWorldSpaceParticles() const { return false; }

    virtual bool WantsMaterialEffects() const { return false; }

    virtual RenderGlobalContext& GetRenderGlobalContext() const {
        return const_cast<DebugEvalContext*>( this )->globContext;
    }

    virtual const frantic::graphics::camera<float>& GetCamera() const { return renderCamera; }

    virtual const frantic::channels::channel_map& GetDefaultChannels() const { return map; }

    virtual frantic::logging::progress_logger& GetProgressLogger() const { return logger; }

    virtual bool GetProperty( const Class_ID& /*propID*/, void* /*pTarget*/ ) const { return false; }
};

template <typename ModifierType, typename Impl>
BaseInterface* IMagmaModifierImpl<ModifierType, Impl>::GetInterface( Interface_ID id ) {
    if( id == PRTModifier_INTERFACE )
        return static_cast<krakatoa::max3d::IPRTModifier*>( this );
    if( id == MagmaModifier_INTERFACE )
        return static_cast<IMagmaModifier*>( this );
    if( BaseInterface* result = krakatoa::max3d::IPRTModifier::GetInterface( id ) )
        return result;
    return MaxKrakatoaReferenceTarget<ModifierType, Impl>::GetInterface( id );
}

template <typename ModifierType, typename Impl>
void IMagmaModifierImpl<ModifierType, Impl>::clear_error() {
    if( m_errorInfo.present ) {
        m_errorInfo.present = false;
        notify_error_changed();
    }
}

template <typename ModifierType, typename Impl>
void IMagmaModifierImpl<ModifierType, Impl>::set_error( const frantic::magma::magma_exception& e ) {
    set_error( e.get_message( true ), e.get_node_id() );
}

template <typename ModifierType, typename Impl>
void IMagmaModifierImpl<ModifierType, Impl>::set_error( const frantic::tstring& message,
                                                        frantic::magma::magma_interface::magma_id id ) {
    if( !m_errorInfo.present || m_errorInfo.nodeID != id || message != m_errorInfo.message ) {
        m_errorInfo.present = true;
        m_errorInfo.nodeID = id;
        m_errorInfo.message = message;

        notify_error_changed();
    }
}

template <typename ModifierType, typename Impl>
void IMagmaModifierImpl<ModifierType, Impl>::notify_error_changed() {
    frantic::max3d::mxs::expression expr( _M(
        "try(::MagmaFlowEditor_Functions.ErrorCallback __magmaHolder __nodeID __errorMessage __futureArgs)catch()" ) );

    if( m_errorInfo.present ) {
        FF_LOG( error ) << m_errorInfo.message << std::endl;

        expr.bind( _M( "__magmaHolder" ), this );
        expr.bind( _M( "__nodeID" ), Integer::intern( m_errorInfo.nodeID ) );
        expr.bind( _M( "__errorMessage" ), new String( m_errorInfo.message.c_str() ) );
        expr.bind( _M( "__futureArgs" ), &undefined );
    } else {
        expr.bind( _M( "__magmaHolder" ), this );
        expr.bind( _M( "__nodeID" ), &undefined );
        expr.bind( _M( "__errorMessage" ), &undefined );
        expr.bind( _M( "__futureArgs" ), &undefined );
    }

    expr.evaluate<void>();
}

template <typename ModifierType, typename Impl>
RefResult IMagmaModifierImpl<ModifierType, Impl>::NotifyRefChanged( const Interval& /*changeInt*/,
                                                                    RefTargetHandle hTarget, PartID& partID,
                                                                    RefMessage message, BOOL /*propagate*/ ) {
    if( hTarget == m_pblock ) {
        int tabIndex;
        ParamID paramID = m_pblock->LastNotifyParamID( tabIndex );

        if( paramID == kMagmaHolderRef ) {
            if( message == REFMSG_CHANGE ) {
                // By looking at ModApp::NotifyRefChanged() in the Max debug source code, I determined that it was
                // clobbering my PartID because it replaces it with the Modifier's ChannelsChanged(). I leave
                // ChannelsChanged() empty strictly to prevent Object::MakeShallowCopy() from being called on our PRT
                // objects, so instead I send this specialmessage that people listening to my modifiers need to know
                // about. The value for this is defined in MaxKrakatoaNodeMonitor.h. Hopefully we can scrap that whole
                // mess in some future version of Krakatoa but that's a pretty big hope.
                if( ( partID & ( PART_OBJ | PART_TM ) ) != 0 )
                    NotifyDependents( FOREVER, partID, ( REFMSG_USER + 0x3561 ), NOTIFY_ALL, TRUE, this );
                return REF_SUCCEED;
            }
        }
    }
    return REF_DONTCARE;
}

template <typename ModifierType, typename Impl>
CreateMouseCallBack* IMagmaModifierImpl<ModifierType, Impl>::GetCreateMouseCallBack( void ) {
    return NULL;
}

template <typename ModifierType, typename Impl>
#if MAX_VERSION_MAJOR >= 24
const MCHAR* IMagmaModifierImpl<ModifierType, Impl>::GetObjectName( bool localized ) {
#elif MAX_VERSION_MAJOR >= 15
const MCHAR* IMagmaModifierImpl<ModifierType, Impl>::GetObjectName() {
#else
MCHAR* IMagmaModifierImpl<ModifierType, Impl>::GetObjectName() {
#endif

    return _T( "Magma PRT Op" );
}

template <typename ModifierType, typename Impl>
Interval IMagmaModifierImpl<ModifierType, Impl>::LocalValidity( TimeValue t ) {
    Interval iv = FOREVER;
    if( ReferenceTarget* magmaHolder = m_pblock->GetReferenceTarget( kMagmaHolderRef ) )
        iv = GetMagmaValidity( magmaHolder, t );

    if( !iv.InInterval( t ) )
        iv.SetInstant( t );

    return iv;
}

template <typename ModifierType, typename Impl>
ChannelMask IMagmaModifierImpl<ModifierType, Impl>::ChannelsUsed() {
    return GEOM_CHANNEL;
}

template <typename ModifierType, typename Impl>
ChannelMask IMagmaModifierImpl<ModifierType, Impl>::ChannelsChanged() {
    return 0;
}

template <typename ModifierType, typename Impl>
Class_ID IMagmaModifierImpl<ModifierType, Impl>::InputType() {
    return MaxKrakatoaPRTSourceObject_CLASSID;
}

template <typename ModifierType, typename Impl>
void IMagmaModifierImpl<ModifierType, Impl>::ModifyObject( TimeValue t, ModContext&, ObjectState* os, INode* ) {
    os->obj->UpdateValidity( GEOM_CHAN_NUM, LocalValidity( t ) );
}

template <typename ModifierType, typename Impl>
particle_istream_ptr IMagmaModifierImpl<ModifierType, Impl>::ApplyModifier(
    particle_istream_ptr pin, INode* pNode, TimeValue /*t*/, Interval& /*inoutValidity*/,
    frantic::max3d::particles::IMaxKrakatoaPRTEvalContextPtr evalContext ) {
    ReferenceTarget* magmaHolder = m_pblock->GetReferenceTarget( kMagmaHolderRef );

    if( magmaHolder != NULL ) {

        try {
            boost::shared_ptr<MagmaMaxContextInterface> magmaContext(
                new MagmaMaxContextInterface( pNode, evalContext ) );

            boost::shared_ptr<frantic::magma::magma_interface> magmaInterface = GetMagmaInterface( magmaHolder );
            if( magmaInterface && pin->particle_count() != 0 )
                pin = frantic::magma::simple_compiler::apply_simple_compiler_expression(
                    pin, magmaInterface, magmaContext,
                    boost::bind( ( void( IMagmaModifierImpl<ModifierType, Impl>::* )(
                                     const frantic::magma::magma_exception& ) ) &
                                     IMagmaModifierImpl<ModifierType, Impl>::set_error,
                                 this, _1 ) );
            else if( magmaInterface && pin->particle_count() == 0 ) {
                FF_LOG( warning ) << _T( "No particles from " ) << frantic::tstring( pNode->GetName() )
                                  << ( ". The Magma modifier will not be evaluated." ) << std::endl;
            }

            clear_error();
        } catch( const frantic::magma::magma_exception& e ) {
            set_error( e );

            if( GetCOREInterface7()->IsRenderActive() )
                throw std::runtime_error( frantic::strings::to_string( e.get_message( true ) ) );
        } catch( const std::exception& e ) {
            set_error( frantic::strings::to_tstring( e.what() ) );

            if( GetCOREInterface7()->IsRenderActive() )
                throw;
        }
    }

    return pin;
}

template <typename ModifierType, typename Impl>
bool IMagmaModifierImpl<ModifierType, Impl>::GetLastError( TYPE_TSTR_BR_TYPE outMessage,
                                                           TYPE_INT_BR_TYPE outMagmaID ) const {
    if( m_errorInfo.present ) {
        if( &outMessage != NULL )
            outMessage = m_errorInfo.message.c_str();

        if( &outMagmaID != NULL )
            outMagmaID = m_errorInfo.nodeID;
    }

    return m_errorInfo.present;
}

template <typename ModifierType, typename Impl>
IObject* IMagmaModifierImpl<ModifierType, Impl>::EvaluateDebug( INode* node, int modIndex, TimeValue t ) {
    using frantic::magma::max3d::DebugInformation;

    boost::shared_ptr<DebugEvalContext> ctx( new DebugEvalContext );

    boost::shared_ptr<frantic::particles::streams::particle_istream> pin;

    Interval validInterval = FOREVER;

    try {
        int derIndex = -1;
        Modifier* theMod = NULL;
        IDerivedObject* derObj = GetCOREInterface7()->FindModifier( *node, modIndex, derIndex, theMod );

        if( derObj && theMod == this ) {
            frantic::max3d::particles::IMaxKrakatoaPRTObjectPtr prtObj =
                frantic::max3d::particles::GetIMaxKrakatoaPRTObject( derObj->FindBaseObject() );
            if( prtObj ) {
                // TODO: Intialize the camera with the active viewport.

                ctx->map.define_channel<frantic::graphics::vector3f>( _T( "Position" ) );
                ctx->map.end_channel_definition();
                ctx->globContext.time = t;
                ctx->stopMod = const_cast<IMagmaModifierImpl<ModifierType, Impl>*>( this );
                ctx->stopModContext = derObj->GetModContext( derIndex );

                pin = prtObj->CreateStream( node, validInterval, ctx );
            }
        }
    } catch( const std::exception& e ) {
        FF_LOG( error ) << e.what() << std::endl;
        pin.reset();
    } catch( ... ) {
        FF_LOG( error ) << _T( "MagmaModifier::EvaluateDebug() Unknown error evaluating the geometry pipeline" )
                        << std::endl;
        pin.reset();
    }

    std::auto_ptr<DebugInformation> result;
    if( pin ) {
        ReferenceTarget* magmaHolder = m_pblock->GetReferenceTarget( kMagmaHolderRef );

        if( magmaHolder ) {
            try {
                boost::shared_ptr<frantic::magma::magma_interface> magmaInterface = GetMagmaInterface( magmaHolder );

                if( magmaInterface ) {
                    boost::shared_ptr<MagmaMaxContextInterface> magmaContext(
                        new MagmaMaxContextInterface( node, ctx ) );

                    frantic::magma::simple_compiler::simple_particle_compiler compiler;
                    compiler.reset( *magmaInterface, pin->get_channel_map(), pin->get_native_channel_map(),
                                    magmaContext );

                    if( compiler.get_channel_map() != pin->get_channel_map() )
                        pin->set_channel_map( compiler.get_channel_map() );

                    boost::int64_t particleCount = pin->particle_count();
                    if( particleCount < 0 || particleCount > GetMaximumDebuggerIterations() )
                        particleCount = GetMaximumDebuggerIterations();

                    std::size_t count = static_cast<std::size_t>( particleCount );
                    std::size_t index;

                    result.reset( new DebugInformation );
                    result->get_storage().resize( count );

                    char* tempParticle = (char*)alloca( pin->get_channel_map().structure_size() );
                    for( index = 0; index < count && pin->get_particle( tempParticle ); ++index )
                        compiler.eval_debug( tempParticle, index, result->get_storage()[index] );

                    result->get_storage().resize( index );
                }

                clear_error();
            } catch( const frantic::magma::magma_exception& e ) {
                set_error( e );
                result.reset();
            } catch( const std::exception& e ) {
                set_error( frantic::strings::to_tstring( e.what() ) );
                result.reset();
            } catch( ... ) {
                FF_LOG( error ) << _T( "MagmaModifier::EvaluateDebug() Unknown error evaluating the magma expression" )
                                << std::endl;
                result.reset();
            }
        }
    }

    return result.release();
}