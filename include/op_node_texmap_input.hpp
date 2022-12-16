// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0
#pragma once
#if false

#include <frantic/channels/named_channel_data.hpp>
#include <frantic/max3d/shaders/map_query.hpp>

#include <frantic/graphics/vector3f.hpp>

#include <frantic/channels/expression/op_node.hpp>

#include <vector>

class op_node_texmap_input: public frantic::channels::op_node_basis_input
{
public:
	struct run_time_data
	{
		int m_numUVWAccessors;
		Texmap* m_texmap;
		TimeValue m_evalTime;
		frantic::graphics::vector3f m_cameraPos;
		frantic::channels::channel_accessor<frantic::graphics::vector3f> m_posAccessor;
		frantic::channels::channel_cvt_accessor<frantic::graphics::vector3f> m_normalAccessor;
		frantic::channels::channel_cvt_accessor<int> m_mtlIndexAccessor;

		//!use of a vector here is kind of akward, but it seems like the only reasonable way to solve this...
		std::vector<frantic::channels::channel_cvt_accessor<frantic::graphics::vector3f> > m_uvwAccessors;
	} m_runTimeData;

private:
	frantic::max3d::shaders::renderInformation m_renderInfo;

public:
	op_node_texmap_input( int nodeID, Texmap* theMap, const frantic::max3d::shaders::renderInformation& renderInfo, TimeValue t );

	virtual ~op_node_texmap_input();

protected:
	virtual void validate_impl( const frantic::channels::channel_map& nativePCM, frantic::channels::channel_map& inoutCurrentPCM );

};
#endif
