// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0
#include "stdafx.h"

#include "MaxKrakatoaChannelTexmapOperator.h"
#include "MaxKrakatoaSceneContext.h"

#include <frantic/max3d/convert.hpp>
#include <frantic/max3d/shaders/map_query.hpp>

#include <frantic/channels/channel_operation_nodes.hpp>
#include <frantic/logging/logging_level.hpp>


using namespace frantic::graphics;
using namespace frantic::channels;

namespace {

class MaxKrakatoaChannelTexmapOperator : public frantic::channels::channel_op_node {
    Texmap* m_pMap;

    RenderGlobalContext* m_globContext;
    RenderInstance* m_rendInstance;

    texmap_output::output_t m_outputType;
    bool m_inWorldSpace;

  public:
    MaxKrakatoaChannelTexmapOperator( int id, Texmap* theMap, texmap_output::output_t outputType,
                                      RenderGlobalContext* globContext, RenderInstance* rendInstance,
                                      bool inWorldSpace );
    virtual ~MaxKrakatoaChannelTexmapOperator();
    virtual void compile( const std::vector<frantic::channels::channel_op_node*>& expressionTree,
                          frantic::channels::channel_operation_compiler& inoutCompData );
};

} // namespace

channel_op_node* CreateMaxKrakatoaChannelTexmapOperator( int id, Texmap* theMap, texmap_output::output_t outputType,
                                                         krakatoa::scene_context_ptr sceneContext, INode* pNode,
                                                         bool inWorldSpace ) {
    MaxKrakatoaSceneContextPtr maxSceneContext = boost::dynamic_pointer_cast<MaxKrakatoaSceneContext>( sceneContext );
    if( !maxSceneContext )
        throw std::runtime_error( "CreateMaxKrakatoaChannelTexmapOperator() Cannot create a "
                                  "MaxKrakatoaChannelTexmapOperator operator in this context." );

    RenderGlobalContext* globContext = const_cast<RenderGlobalContext*>( maxSceneContext->get_render_global_context() );
    if( !globContext )
        throw std::runtime_error(
            "CreateMaxKrakatoaChannelTexmapOperator() A non-NULL RenderGlobalContext is required" );

    // Find the RenderInstance associated with the specified INode.
    RenderInstance* rendInstance = NULL;
    if( pNode != NULL ) {
        for( int i = 0, iEnd = globContext->NumRenderInstances(); i < iEnd && !rendInstance; ++i ) {
            RenderInstance* curInstance = globContext->GetRenderInstance( i );
            if( curInstance && curInstance->GetINode() == pNode )
                rendInstance = curInstance;
        }
    }

    return new MaxKrakatoaChannelTexmapOperator( id, theMap, outputType, globContext, rendInstance, inWorldSpace );
}

namespace {

class texmap_op {
    int m_outOffset;
    int m_numUVWAccessors;

    Texmap* m_texmap;
    RenderGlobalContext* m_renderGlobalContext;
    RenderInstance* m_currentInstance;

    texmap_output::output_t m_outputType;

    Matrix3 m_dataToCam, m_normalToCam;

    frantic::channels::channel_accessor<vector3f> m_posAccessor;
    frantic::channels::channel_cvt_accessor<vector3f> m_normalAccessor;
    frantic::channels::channel_cvt_accessor<int> m_mtlIndexAccessor;

  public:
    typedef std::pair<int, frantic::channels::channel_cvt_accessor<vector3f>> uvw_channel_type;

    void init( int outOffset, const frantic::channels::channel_map& pcm, Texmap* pMap, RenderGlobalContext* globContext,
               RenderInstance* rendInst, int numUVWChannels, texmap_output::output_t outputType, bool isWorldSpace ) {
        m_outOffset = outOffset;
        m_texmap = pMap;
        m_numUVWAccessors = numUVWChannels;
        m_outputType = outputType;
        m_renderGlobalContext = globContext;
        m_currentInstance = rendInst;

        m_dataToCam = ( !isWorldSpace && rendInst ) ? rendInst->objToCam : globContext->worldToCam;

        // Compute the transposed inverse for transforming the normal vector.
        m_normalToCam = Inverse( m_dataToCam );
        m_normalToCam.Set( m_normalToCam.GetColumn3( 0 ), m_normalToCam.GetColumn3( 1 ), m_normalToCam.GetColumn3( 2 ),
                           Point3( 0, 0, 0 ) );

        m_posAccessor = pcm.get_accessor<vector3f>( _T("Position") );
        m_normalAccessor.reset();
        m_mtlIndexAccessor.reset( 0 );

        if( pcm.has_channel( _T("Normal") ) )
            m_normalAccessor = pcm.get_cvt_accessor<vector3f>( _T("Normal") );
        if( pcm.has_channel( _T("MtlIndex") ) )
            m_mtlIndexAccessor = pcm.get_cvt_accessor<int>( _T("MtlIndex") );
    }

    static void eval( char* particle, char* temporaries, void* data ) {
        texmap_op* thisData = static_cast<texmap_op*>( data );

        Point3 p, n, v;

        p = frantic::max3d::to_max_t( thisData->m_posAccessor.get( particle ) );
        p = thisData->m_dataToCam.PointTransform( p );

        v = Normalize( p );

        frantic::max3d::shaders::multimapping_shadecontext sc;

        sc.position = p;
        sc.camPos = Point3( 0, 0, 0 );
        sc.origView = sc.view = v;
        sc.mtlNum = thisData->m_mtlIndexAccessor.get( particle );
        sc.globContext = thisData->m_renderGlobalContext;
        sc.shadeTime = thisData->m_renderGlobalContext->time;
        sc.toWorldSpaceTM = thisData->m_renderGlobalContext->camToWorld;

        if( thisData->m_currentInstance ) {
            sc.toObjectSpaceTM = thisData->m_currentInstance->camToObj;
            sc.inode = thisData->m_currentInstance->GetINode();
            sc.evalObject = thisData->m_currentInstance->GetEvalObject();
            sc.nLights = thisData->m_currentInstance->NumLights();
        } else {
            sc.toObjectSpaceTM = thisData->m_renderGlobalContext->camToWorld;
        }

        // If we have valid normal data ...
        if( thisData->m_normalAccessor.is_valid() ) {
            n = frantic::max3d::to_max_t( thisData->m_normalAccessor.get( particle ) );
            n = Normalize( thisData->m_normalToCam.VectorTransform( n ) );

            // 3dsMax wants to normal facing the camera, and a flag indicating a backface.
            if( DotProd( n, v ) > 0 ) {
                n = -n;
                sc.backFace = TRUE;
            }

            sc.origNormal = sc.normal = n;
        } else {
            sc.origNormal = sc.normal = -v;
        }

        // Clobber the ambient light
        sc.ambientLight.Black();

        uvw_channel_type* uvwAccessors = reinterpret_cast<uvw_channel_type*>( (char*)data + sizeof( texmap_op ) );
        for( int i = 0; i < thisData->m_numUVWAccessors; ++i )
            sc.uvwArray[uvwAccessors[i].first] = frantic::max3d::to_max_t( uvwAccessors[i].second.get( particle ) );

        float* pDest = reinterpret_cast<float*>( temporaries + thisData->m_outOffset );

        switch( thisData->m_outputType ) {
        case texmap_output::color: {
            AColor c = thisData->m_texmap->EvalColor( sc );
            pDest[0] = c.r;
            pDest[1] = c.g;
            pDest[2] = c.b;
        } break;
        case texmap_output::mono: {
            pDest[0] = thisData->m_texmap->EvalMono( sc );
        } break;
        case texmap_output::bump: {
            Point3 p = thisData->m_texmap->EvalNormalPerturb( sc );
            pDest[0] = p.x;
            pDest[1] = p.y;
            pDest[2] = p.z;
        } break;
        default:
            __assume( 0 );
        }
    }
};

} // namespace

MaxKrakatoaChannelTexmapOperator::MaxKrakatoaChannelTexmapOperator( int id, Texmap* theMap,
                                                                    texmap_output::output_t outputType,
                                                                    RenderGlobalContext* globContext,
                                                                    RenderInstance* rendInstance, bool inWorldSpace )
    : channel_op_node( id )
    , m_outputType( outputType )
    , m_pMap( theMap )
    , m_inWorldSpace( inWorldSpace )
    , m_globContext( globContext )
    , m_rendInstance( rendInstance ) {}

MaxKrakatoaChannelTexmapOperator::~MaxKrakatoaChannelTexmapOperator() {}

void MaxKrakatoaChannelTexmapOperator::compile( const std::vector<channel_op_node*>& /*expressionTree*/,
                                                channel_operation_compiler& inoutCompData ) {
    BitArray m_reqUVWs;

    frantic::max3d::shaders::update_map_for_shading( m_pMap, m_globContext->time );
    frantic::max3d::shaders::collect_map_requirements( m_pMap, m_reqUVWs );

    if( frantic::logging::is_logging_debug() ) {
        frantic::logging::debug << _T("For map: \"") << m_pMap->GetName() << _T("\"") << std::endl;
        for( int i = 0; i < MAX_MESHMAPS; ++i ) {
            if( m_reqUVWs[i] )
                frantic::logging::debug << _T("\tRequires map channel: ") + boost::lexical_cast<M_STD_STRING>( i )
                                        << std::endl;
        }
    }

    int outputArity = 3;
    if( m_outputType == texmap_output::mono )
        outputArity = 1;

    temporary_result* r = inoutCompData.allocate_temporary( m_nodeId, data_type_float32, outputArity );
    int numUVWChannels = m_reqUVWs.NumberSet();

    void* pData = malloc( sizeof( texmap_op ) + numUVWChannels * sizeof( texmap_op::uvw_channel_type ) );

    if( !inoutCompData.get_channel_map().has_channel( _T("Position") ) ) {
        if( !inoutCompData.get_native_channel_map().has_channel( _T("Position") ) )
            throw std::runtime_error( "Unable to get channel \"Position\"" );
        const channel& theChannel = inoutCompData.get_native_channel_map()[_T("Position")];
        inoutCompData.get_channel_map().append_channel( theChannel.name(), theChannel.arity(), theChannel.data_type() );
    }
    if( !inoutCompData.get_channel_map().has_channel( _T("Normal") ) ) {
        if( inoutCompData.get_native_channel_map().has_channel( _T("Normal") ) ) {
            const channel& theChannel = inoutCompData.get_native_channel_map()[_T("Normal")];
            inoutCompData.get_channel_map().append_channel( theChannel.name(), theChannel.arity(),
                                                            theChannel.data_type() );
        }
    }
    if( !inoutCompData.get_channel_map().has_channel( _T("MtlIndex") ) ) {
        if( inoutCompData.get_native_channel_map().has_channel( _T("MtlIndex") ) ) {
            const channel& theChannel = inoutCompData.get_native_channel_map()[_T("MtlIndex")];
            inoutCompData.get_channel_map().append_channel( theChannel.name(), theChannel.arity(),
                                                            theChannel.data_type() );
        }
    }

    texmap_op::uvw_channel_type* pUVWChannels =
        reinterpret_cast<texmap_op::uvw_channel_type*>( (char*)pData + sizeof( texmap_op ) );
    if( m_reqUVWs[0] ) {
        if( !inoutCompData.get_channel_map().has_channel( _T("Color") ) ) {
            if( !inoutCompData.get_native_channel_map().has_channel( _T("Color") ) )
                throw std::runtime_error( "Unable to get channel \"Color\"" );
            const channel& theChannel = inoutCompData.get_native_channel_map()[_T("Color")];
            inoutCompData.get_channel_map().append_channel( theChannel.name(), theChannel.arity(),
                                                            theChannel.data_type() );
        }
        pUVWChannels->first = 0;
        pUVWChannels->second = inoutCompData.get_channel_map().get_cvt_accessor<vector3f>( _T("Color") );
        ++pUVWChannels;
    }
    if( m_reqUVWs[1] ) {
        if( !inoutCompData.get_channel_map().has_channel( _T("TextureCoord") ) ) {
            if( !inoutCompData.get_native_channel_map().has_channel( _T("TextureCoord") ) )
                throw std::runtime_error( "Unable to get channel \"TextureCoord\"" );
            const channel& theChannel = inoutCompData.get_native_channel_map()[_T("TextureCoord")];
            inoutCompData.get_channel_map().append_channel( theChannel.name(), theChannel.arity(),
                                                            theChannel.data_type() );
        }
        pUVWChannels->first = 1;
        pUVWChannels->second = inoutCompData.get_channel_map().get_cvt_accessor<vector3f>( _T("TextureCoord") );
        ++pUVWChannels;
    }
    for( int i = 2; i < MAX_MESHMAPS; ++i ) {
        if( m_reqUVWs[i] ) {
            M_STD_STRING channelName = _T("Mapping") + boost::lexical_cast<M_STD_STRING>( i );
            if( !inoutCompData.get_channel_map().has_channel( channelName ) ) {
                if( !inoutCompData.get_native_channel_map().has_channel( channelName ) )
                    throw std::runtime_error( "Unable to get channel \"" + frantic::strings::to_string( channelName ) +
                                              "\"" );
                const channel& theChannel = inoutCompData.get_native_channel_map()[channelName];
                inoutCompData.get_channel_map().append_channel( theChannel.name(), theChannel.arity(),
                                                                theChannel.data_type() );
            }
            pUVWChannels->first = i;
            pUVWChannels->second = inoutCompData.get_channel_map().get_cvt_accessor<vector3f>( channelName );
            ++pUVWChannels;
        }
    }

    frantic::channels::detail::code_segment theSeg;
    theSeg.codePtr = &texmap_op::eval;
    theSeg.codeData = pData;
    reinterpret_cast<texmap_op*>( theSeg.codeData )
        ->init( r->offset, inoutCompData.get_channel_map(), m_pMap, m_globContext, m_rendInstance, numUVWChannels,
                m_outputType, m_inWorldSpace );

    inoutCompData.append_code_segment( theSeg );
}
