// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0
#pragma once

#include <frantic/magma/nodes/magma_node_property.hpp>
#include <frantic/magma/nodes/magma_simple_operator.hpp>

#include <frantic/magma/max3d/MagmaMaxNodeExtension.hpp>

namespace frantic {
namespace magma {
namespace nodes {
namespace max3d {

class magma_texmap_op_node : public magma_max_node_base {
    struct channel_data {
        frantic::tstring name;
        std::pair<magma_interface::magma_id, int> socket;
    };

    std::vector<channel_data> m_inputs;
    std::vector<frantic::tstring> m_channels;

  private:
    const channel_data* find_channel( const frantic::tstring& name ) const;

  public:
    enum { kTexmap = 1 };

    class max_impl : public MagmaMaxNodeExtension<max_impl> {
      public:
        static MSTR s_ClassName;
        static Class_ID s_ClassID;

        static void DefineParameters( ParamBlockDesc2& paramDesc );

        virtual RefResult NotifyRefChanged( const Interval& /*changeInt*/, RefTargetHandle hTarget, PartID& /*partID*/,
                                            RefMessage message, BOOL /*propagate*/ ) {
            if( hTarget == m_pblock ) {
                if( message == REFMSG_CHANGE )
                    return REF_SUCCEED;
            }

            return REF_DONTCARE;
        }
    };

  public:
    MAGMA_MAX_REQUIRED_METHODS( magma_texmap_op_node );
    MAGMA_PROPERTY( resultType, frantic::tstring );
    // MAGMA_PROPERTY( channels, std::vector<std::string> ); //exposed by creating set_channels() and get_channels()
    // below.
    MAGMA_MAX_PROPERTY( texmap, Texmap, kTexmap );

    magma_texmap_op_node();

    inline void set_channels( const std::vector<frantic::tstring>& value );
    inline const std::vector<frantic::tstring>& get_channels() const;

    virtual int get_num_inputs() const { return (int)m_inputs.size(); }
    virtual void set_num_inputs( int /*numInputs*/ ) {}
    virtual std::pair<magma_interface::magma_id, int> get_input( int index ) const { return m_inputs[index].socket; }
    virtual void set_input( int index, magma_interface::magma_id id, int outputIndex ) {
        m_inputs[index].socket.first = id;
        m_inputs[index].socket.second = outputIndex;
    }
    virtual void get_input_description( int i, frantic::tstring& outDescription ) { outDescription = m_inputs[i].name; }
};

inline void magma_texmap_op_node::set_channels( const std::vector<frantic::tstring>& value ) {
    m_channels = value;

    std::vector<channel_data> newVals;

    for( std::vector<frantic::tstring>::const_iterator it = value.begin(), itEnd = value.end(); it != itEnd; ++it ) {
        channel_data newData;
        newData.name = *it;
        newData.socket = std::make_pair( magma_interface::INVALID_ID, 0 );

        for( std::vector<channel_data>::const_iterator itOld = m_inputs.begin(), itOldEnd = m_inputs.end();
             itOld != itOldEnd; ++itOld ) {
            if( itOld->name == newData.name ) {
                newData.socket = itOld->socket;
                break;
            }
        }

        newVals.push_back( newData );
    }

    m_inputs.swap( newVals );
}

inline const std::vector<frantic::tstring>& magma_texmap_op_node::get_channels() const {
    return m_channels;
    /*std::vector<std::string> result;

    for( std::vector< channel_data >::const_iterator it = m_inputs.begin(), itEnd = m_inputs.end(); it != itEnd; ++it )
            result.push_back( it->name );

    return result;*/
}

} // namespace max3d
} // namespace nodes
} // namespace magma
} // namespace frantic
