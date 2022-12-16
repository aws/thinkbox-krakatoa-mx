// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0
#include <frantic/graphics/camera.hpp>
#include <frantic/magma/magma_compiler_interface.hpp>
#include <frantic/max3d/convert.hpp>
#include <frantic/max3d/particles/IMaxKrakatoaPRTObject.hpp>

#include <max.h>

class MagmaMaxContextInterface : public frantic::magma::magma_compiler_interface::context_base {
    INode* m_node;
    frantic::max3d::particles::IMaxKrakatoaPRTEvalContextPtr m_pEvalContext;

  public:
    MagmaMaxContextInterface( INode* node, frantic::max3d::particles::IMaxKrakatoaPRTEvalContextPtr pEvalContext )
        : m_node( node )
        , m_pEvalContext( pEvalContext ) {}

    virtual frantic::tstring get_name() const { return _T("3dsMax"); }

    bool InWorldSpace() const { return ( m_node == NULL ); }

    INode* GetCurrentNode() const { return m_node; }

    frantic::max3d::particles::IMaxKrakatoaPRTEvalContextPtr GetPRTObjectEvalContext() const { return m_pEvalContext; }

    virtual frantic::graphics::transform4f get_world_transform( bool inverse ) const {
        if( !m_pEvalContext || !m_node )
            return frantic::graphics::transform4f();

        if( InWorldSpace() )
            inverse = !inverse;

        frantic::graphics::transform4f result =
            frantic::max3d::to_max_t( m_node->GetNodeTM( m_pEvalContext->GetTime() ) );

        return !inverse ? result : result.to_inverse();
    }

    virtual frantic::graphics::transform4f get_camera_transform( bool inverse ) const {
        if( !m_pEvalContext )
            return frantic::graphics::transform4f();

        return inverse ? m_pEvalContext->GetCamera().world_transform()
                       : m_pEvalContext->GetCamera().world_transform_inverse();
    }

    virtual boost::any get_property( const frantic::tstring& name ) const {
        if( name == _T("Time") )
            return boost::any( m_pEvalContext ? m_pEvalContext->GetTime() : TIME_NegInfinity );
        else if( name == _T("MaxRenderGlobalContext") )
            return boost::any( m_pEvalContext ? &m_pEvalContext->GetRenderGlobalContext()
                                              : (RenderGlobalContext*)NULL );
        else if( name == _T("CurrentINode") )
            return boost::any( GetCurrentNode() );
        else if( name == _T("InWorldSpace") )
            return boost::any( InWorldSpace() );
        else if( name == _T("IMaxKrakatoaPRTObject::EvalContext") )
            return boost::any( m_pEvalContext );
        return frantic::magma::magma_compiler_interface::context_base::get_property( name );
    }
};
