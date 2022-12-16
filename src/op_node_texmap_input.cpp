// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0
#include "stdafx.h"
#ifdef DONTBUILDTHIS
#include "op_node_texmap_input.hpp"

#include <frantic/logging/logging_level.hpp>
#include <frantic/max3d/convert.hpp>
#include <frantic/max3d/shaders/map_query.hpp>

#include <frantic/channels/expression/code_segment_generator.hpp>

using namespace frantic::graphics;
using namespace frantic::channels;

op_node_texmap_input::op_node_texmap_input( int nodeID, Texmap* theMap,
                                            const frantic::max3d::shaders::renderInformation& renderInfo, TimeValue t )
    : op_node_basis_input( nodeID )
    , m_renderInfo( renderInfo ) {
    m_runTimeData.m_texmap = theMap;
    m_runTimeData.m_evalTime = t;
}

op_node_texmap_input::~op_node_texmap_input() {}

void op_node_texmap_input::validate_impl( const channel_map& nativePCM, channel_map& inoutCurrentPCM ) {
    BitArray m_reqUVWs;

    frantic::max3d::shaders::update_map_for_shading( m_runTimeData.m_texmap, m_runTimeData.m_evalTime );
    frantic::max3d::shaders::collect_map_requirements( m_runTimeData.m_texmap, m_reqUVWs );

    if( frantic::logging::is_logging_debug() ) {
        frantic::logging::debug << "For map: \"" << m_runTimeData.m_texmap->GetName() << "\"" << std::endl;

        for( int i = 0; i < MAX_MESHMAPS; ++i ) {
            if( m_reqUVWs[i] ) {
                frantic::logging::debug << "\tRequires map channel: " + boost::lexical_cast<std::string>( i )
                                        << std::endl;
            }
        }
    }

    int numUVWChannels = m_reqUVWs.NumberSet();

    /**
     * VERY VERY IMPORTANT: you must explicitly set the size of the vector here, because it is possible that
     * this node will undergo validation multiple times, and hence we cannot guarantee that it will be empty
     * at any given time.  I use 'resize' to explicity set the size, rather than 'clear' and 'push_back' for
     * the purposes of efficiency.
     */
    /////////////////////////
    m_runTimeData.m_uvwAccessors.resize( numUVWChannels );
    /////////////////////////

    if( !inoutCurrentPCM.has_channel( "Position" ) ) {
        if( !nativePCM.has_channel( "Position" ) ) {
            throw std::runtime_error( "Unable to get channel \"Position\"" );
        }

        const channel& theChannel = nativePCM["Position"];
        inoutCurrentPCM.append_channel( theChannel.name(), theChannel.arity(), theChannel.data_type() );
    }
    if( !inoutCurrentPCM.has_channel( "Normal" ) ) {
        if( nativePCM.has_channel( "Normal" ) ) {
            const channel& theChannel = nativePCM["Normal"];
            inoutCurrentPCM.append_channel( theChannel.name(), theChannel.arity(), theChannel.data_type() );
        }
    }
    if( !inoutCurrentPCM.has_channel( "MtlIndex" ) ) {
        if( nativePCM.has_channel( "MtlIndex" ) ) {
            const channel& theChannel = nativePCM["MtlIndex"];
            inoutCurrentPCM.append_channel( theChannel.name(), theChannel.arity(), theChannel.data_type() );
        }
    }

    if( m_reqUVWs[0] ) {
        if( !inoutCurrentPCM.has_channel( "Color" ) ) {
            if( !nativePCM.has_channel( "Color" ) ) {
                throw std::runtime_error( "Unable to get channel \"Color\"" );
            }

            const channel& theChannel = nativePCM["Color"];
            inoutCurrentPCM.append_channel( theChannel.name(), theChannel.arity(), theChannel.data_type() );
        }

        m_runTimeData.m_uvwAccessors[0] = inoutCurrentPCM.get_cvt_accessor<vector3f>( "Color" );
    }

    if( m_reqUVWs[1] ) {
        if( !inoutCurrentPCM.has_channel( "TextureCoord" ) ) {
            if( !nativePCM.has_channel( "TextureCoord" ) ) {
                throw std::runtime_error( "Unable to get channel \"TextureCoord\"" );
            }

            const channel& theChannel = nativePCM["TextureCoord"];
            inoutCurrentPCM.append_channel( theChannel.name(), theChannel.arity(), theChannel.data_type() );
        }

        m_runTimeData.m_uvwAccessors[1] = inoutCurrentPCM.get_cvt_accessor<vector3f>( "TextureCoord" );
    }

    for( int i = 2; i < MAX_MESHMAPS; ++i ) {
        if( m_reqUVWs[i] ) {
            std::string channelName = "Mapping" + boost::lexical_cast<std::string>( i );

            if( !inoutCurrentPCM.has_channel( channelName ) ) {
                if( !nativePCM.has_channel( channelName ) ) {
                    throw std::runtime_error( "Unable to get channel \"" + channelName + "\"" );
                }

                const channel& theChannel = nativePCM[channelName];
                inoutCurrentPCM.append_channel( theChannel.name(), theChannel.arity(), theChannel.data_type() );
            }

            m_runTimeData.m_uvwAccessors[i] = inoutCurrentPCM.get_cvt_accessor<vector3f>( channelName );
        }
    }

    m_runTimeData.m_numUVWAccessors = numUVWChannels;
    m_runTimeData.m_cameraPos = frantic::max3d::from_max_t( m_renderInfo.m_cameraPosition );

    m_runTimeData.m_posAccessor = inoutCurrentPCM.get_accessor<vector3f>( "Position" );
    m_runTimeData.m_normalAccessor.reset( vector3f( 0 ) );
    m_runTimeData.m_mtlIndexAccessor.reset( 0 );

    if( inoutCurrentPCM.has_channel( "Normal" ) ) {
        m_runTimeData.m_normalAccessor = inoutCurrentPCM.get_cvt_accessor<vector3f>( "Normal" );
    }

    if( inoutCurrentPCM.has_channel( "MtlIndex" ) ) {
        m_runTimeData.m_mtlIndexAccessor = inoutCurrentPCM.get_cvt_accessor<int>( "MtlIndex" );
    }

    // set the op_node arity and type related data
    m_outputArity = 3;
    m_outputType = data_type_float32;
}

CREATE_CODE_SEGMENT( texmap_input ) {
    vector3f pos = m_posAccessor.get( particle );

    frantic::max3d::shaders::multimapping_shadecontext sc;
    sc.position = frantic::max3d::to_max_t( pos );
    sc.camPos = frantic::max3d::to_max_t( m_cameraPos );
    sc.view = frantic::max3d::to_max_t( vector3f::normalize( pos - m_cameraPos ) );
    sc.normal = frantic::max3d::to_max_t( vector3f::normalize( m_normalAccessor.get( particle ) ) );
    sc.mtlNum = m_mtlIndexAccessor.get( particle );
    sc.shadeTime = m_evalTime;

    for( int i = 0; i < m_numUVWAccessors; ++i ) {
        sc.uvwArray[i] = frantic::max3d::to_max_t( m_uvwAccessors[i].get( particle ) );
    }

    AColor c = m_texmap->EvalColor( sc );

    float* pDest = reinterpret_cast<float*>( scratch + this->get_scratch_pos() );
    pDest[0] = c.r;
    pDest[1] = c.g;
    pDest[2] = c.b;
}
#endif
