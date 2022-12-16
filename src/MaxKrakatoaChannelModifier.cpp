// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0
#include "stdafx.h"

#include "MaxKrakatoaChannelModifier.h"
#include "MaxKrakatoaChannelTexmapOperator.h"
#include "MaxKrakatoaRenderGlobalContext.h"
#include "MaxKrakatoaSceneContext.h"

#include <frantic/channels/named_channel_data.hpp>
#include <frantic/max3d/geometry/auto_mesh.hpp>
#include <frantic/max3d/geometry/mesh.hpp>
#include <frantic/max3d/geometry/null_view.hpp>
#include <frantic/max3d/maxscript/maxscript.hpp>
#include <frantic/particles/streams/channel_operation_particle_istream.hpp>

#include <frantic/graphics/transform4f.hpp>

using namespace frantic::channels;
using namespace frantic::math;
using namespace frantic::particles::streams;

#include <magma/magma_mxs_parser.hpp>

namespace {

bool compilation_error_callback( ReferenceTarget* pMagmaHolder, int nodeId, const char* pMsg ) {
    frantic::max3d::mxs::frame<2> locals;
    frantic::max3d::mxs::local<Integer> theInt( locals );
    frantic::max3d::mxs::local<String> theMsg( locals );

    theInt = new( GC_IN_HEAP ) Integer( nodeId + 1 );
#if MAX_VERSION_MAJOR < 15
    theMsg = new( GC_IN_HEAP ) String( pMsg );
#else
    theMsg = new( GC_IN_HEAP ) String( MSTR::FromACP( pMsg ).data() );
#endif

    bool displayError = true;
    try {
        displayError = frantic::max3d::mxs::expression( _T("theMod.setCompilerError theNode theMsg") )
                           .bind( _T("theMod"), pMagmaHolder )
                           .bind( _T("theNode"), theInt.ptr() )
                           .bind( _T("theMsg"), theMsg.ptr() )
                           .evaluate<bool>();
    } catch( MAXScriptException& e ) {
        frantic::max3d::mxs::frame<1> locals;
        frantic::max3d::mxs::local<StringStream> theStream( locals );

        theStream = new( GC_IN_HEAP ) StringStream;
        e.sprin1( theStream.ptr() );

        MessageBox( NULL, theStream->to_string(), _T("MXSException during KCE error report"), MB_OK );
    }

    return displayError;
}

} // end of anonymous namespace

void create_kcm_ast_nodes( std::vector<frantic::channels::channel_op_node*>& outNodes,
                           krakatoa::scene_context_ptr sceneContext, INode* pNode, ReferenceTarget* pMagmaHolder ) {
    boost::scoped_ptr<magma::magma_mxs_parser> parser( magma::create_mxs_parser() );

    parser->set_bound_inode( pNode );
    parser->set_max_data( pMagmaHolder );
    parser->set_scene_context( sceneContext );

    parser->create_expression( outNodes );
}

boost::shared_ptr<particle_istream>
get_krakatoa_channel_modifier_particle_istream( boost::shared_ptr<particle_istream> pin,
                                                krakatoa::scene_context_ptr sceneContext, INode* pNode,
                                                ReferenceTarget* pMagmaHolder ) {
    using namespace frantic::particles::streams;
    using namespace frantic::channels;

    if( !pNode || !pMagmaHolder )
        return pin;

    try {
        std::vector<channel_op_node*> theNodes;
        create_kcm_ast_nodes( theNodes, sceneContext, pNode, pMagmaHolder );

        if( theNodes.size() > 0 ) {
            boost::function<bool( int, const char* )> errorCallback =
                boost::bind( &compilation_error_callback, pMagmaHolder, _1, _2 );
            pin.reset(
                new frantic::particles::streams::channel_operation_particle_istream( pin, theNodes, errorCallback ) );
        }
    } catch( const channel_compiler_error& e ) {
        bool showError = compilation_error_callback( pMagmaHolder, e.which_node(), e.what() );
        if( !showError )
            throw std::runtime_error( "" ); // Use an empty exception so it won't show up in the log window.
        throw;
    }

    return pin;
}

boost::shared_ptr<frantic::particles::streams::particle_istream> get_krakatoa_channel_modifier_particle_istream(
    boost::shared_ptr<frantic::particles::streams::particle_istream> delegatePin,
    frantic::max3d::particles::IMaxKrakatoaPRTEvalContextPtr sceneContext, INode* pNode,
    ReferenceTarget* pMagmaHolder ) {
    krakatoa::scene_context_ptr krakatoaSceneContext;
    if( MaxKrakatoaRenderGlobalContext* pInternalContext =
            dynamic_cast<MaxKrakatoaRenderGlobalContext*>( sceneContext.get() ) ) {
        krakatoaSceneContext = pInternalContext->get_scene_context();
    } else {
        // This means we are being evaluated outside of the context of a Krakatoa render, so we make our own temporary
        // scene_context with the data from globContext.
        MaxKrakatoaSceneContextPtr tempContext( new MaxKrakatoaSceneContext );
        tempContext->set_camera( sceneContext->GetCamera() );
        tempContext->set_time( TicksToSec( sceneContext->GetTime() ) );
        tempContext->set_render_global_context(
            &sceneContext->GetRenderGlobalContext() ); // BUG: This is a lifetime issue, since sceneContext likely owns
                                                       // this referenced object!

        krakatoaSceneContext = tempContext;
    }

    return get_krakatoa_channel_modifier_particle_istream( delegatePin, krakatoaSceneContext, pNode, pMagmaHolder );
}