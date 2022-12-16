// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0
#pragma once

#include "stdafx.h"
#include <frantic/max3d/max_utility.hpp>
#include <frantic/max3d/particles/modifier_utils.hpp>
#include <frantic/max3d/viewport/DecoratedMeshEdgeRenderItem.hpp>
#include <frantic/max3d/viewport/ParticleRenderItem.hpp>
#include <krakatoa/max3d/PRTObject.hpp>

namespace krakatoa {
namespace max3d {

template <class CHILD>
class MaxKrakatoaPRTObjectDisplay : public PRTObject<CHILD> {
    // From IObjectDisplay2
#if MAX_VERSION_MAJOR >= 17

  private:
    MaxSDK::Graphics::CustomRenderItemHandle m_markerRenderItem;
    MaxSDK::Graphics::CustomRenderItemHandle m_iconRenderItem;
    bool m_initialized;

  public:
    MaxKrakatoaPRTObjectDisplay()
        : m_initialized( false ) {}

    unsigned long GetObjectDisplayRequirement() const { return 0; }

    // Called while the object is being transformed
    void WSStateInvalidate() {
        PRTObject<CHILD>::WSStateInvalidate();

        if( m_initialized ) {
            ULONG handle = 0;
            GetCOREInterface()->GetSelNode( 0 );

            INode* currentNode = GetWorldSpaceObjectNode();

            if( currentNode ) {
                std::vector<frantic::max3d::particles::modifier_info_t> theMods;
                frantic::max3d::collect_node_modifiers( currentNode, theMods );

                std::vector<frantic::max3d::particles::modifier_info_t>::iterator it = theMods.begin();
                bool doUpdate = false;
                for( it; it != theMods.end(); ++it ) {
                    frantic::tstring name = it->first->GetName();

                    if( name.find( _T( "Magma" ) ) != frantic::tstring::npos ) {
                        doUpdate = true;
                        break;
                    }
                }

                Box3 boundingBox;
                GetWorldBoundBox( GetCOREInterface()->GetTime(), currentNode,
                                  &GetCOREInterface7()->getViewExp( GetCOREInterface7()->getActiveViewportIndex() ),
                                  boundingBox );

                UpdateParticlesRenderItem( boundingBox, currentNode, m_markerRenderItem, doUpdate );
            }
        }
    }

    bool PrepareDisplay( const MaxSDK::Graphics::UpdateDisplayContext& /*prepareDisplayContext*/ ) { return true; }

    bool UpdatePerNodeItems( const MaxSDK::Graphics::UpdateDisplayContext& updateDisplayContext,
                             MaxSDK::Graphics::UpdateNodeContext& nodeContext,
                             MaxSDK::Graphics::IRenderItemContainer& targetRenderItemContainer ) {

        TimeValue t = updateDisplayContext.GetDisplayTime();
        BuildViewportCache( nodeContext.GetRenderNode().GetMaxNode(),
                            &GetCOREInterface7()->getViewExp( GetCOREInterface7()->getActiveViewportIndex() ), t );

        targetRenderItemContainer.ClearAllRenderItems();

        Box3 boundingBox;
        GetWorldBoundBox( t, nodeContext.GetRenderNode().GetMaxNode(),
                          &GetCOREInterface7()->getViewExp( GetCOREInterface7()->getActiveViewportIndex() ),
                          boundingBox );

        // Generate and add the render item for particles
        GenerateParticlesRenderItem( t, boundingBox, nodeContext.GetRenderNode().GetMaxNode(), m_markerRenderItem );
        targetRenderItemContainer.AddRenderItem( m_markerRenderItem );

        // Generate and add its render item
        GenerateIconRenderItem( t, nodeContext, m_iconRenderItem );
        targetRenderItemContainer.AddRenderItem( m_iconRenderItem );

        m_initialized = true;

        return true;
    }

    bool UpdatePerViewItems( const MaxSDK::Graphics::UpdateDisplayContext& /*updateDisplayContext*/,
                             MaxSDK::Graphics::UpdateNodeContext& /*nodeContext*/,
                             MaxSDK::Graphics::UpdateViewContext& /*viewContext*/,
                             MaxSDK::Graphics::IRenderItemContainer& /*targetRenderItemContainer*/ ) {

        return true;
    }

  private:
    void GenerateParticlesRenderItem( TimeValue& /*t*/, Box3& boundingBox, INode* nodeContext,
                                      MaxSDK::Graphics::CustomRenderItemHandle& markerRenderItem ) {

        boost::filesystem::path shaderPath( frantic::win32::GetModuleFileName( hInstance ) );
        shaderPath =
            ( shaderPath.parent_path() / _T("\\..\\Shaders\\particle_small.fx") ).string<frantic::tstring>().c_str();
        if( !boost::filesystem::exists( shaderPath ) ) {
            FF_LOG( error ) << shaderPath.c_str() << " doesn't exist. Please re-install KrakatoaMX.";
        }

        std::auto_ptr<frantic::max3d::viewport::ParticleRenderItem<CHILD::particle_t>> newRenderItem(
            new frantic::max3d::viewport::ParticleRenderItem<CHILD::particle_t>( shaderPath.c_str() ) );

        frantic::max3d::viewport::render_type renderType = frantic::max3d::viewport::RT_POINT_LARGE;

        if( !m_hasVectors || nodeContext->GetVertTicks() ) {
            renderType = frantic::max3d::viewport::RT_POINT_LARGE;
        } else {
            renderType = frantic::max3d::viewport::RT_VELOCITY;
        }

        newRenderItem->Initialize( m_viewportCache, renderType );

        Point3 p( 0.5f * ( boundingBox.pmax.x + boundingBox.pmin.x ),
                  0.5f * ( boundingBox.pmax.y + boundingBox.pmin.y ), boundingBox.pmax.z );

        M_STD_STRING msg = boost::lexical_cast<M_STD_STRING>( m_viewportCache.size() );
        newRenderItem->SetMessage( p, const_cast<MCHAR*>( msg.c_str() ) );

        markerRenderItem.Release();
        markerRenderItem.Initialize();
        markerRenderItem.SetCustomImplementation( newRenderItem.release() );
    }

    void UpdateParticlesRenderItem( Box3& boundingBox, INode* nodeContext,
                                    MaxSDK::Graphics::CustomRenderItemHandle& markerRenderItem, bool doGPUUpload ) {

        frantic::max3d::viewport::render_type renderType = frantic::max3d::viewport::RT_POINT_LARGE;

        if( !m_hasVectors || nodeContext->GetVertTicks() ) {
            renderType = frantic::max3d::viewport::RT_POINT_LARGE;
        } else {
            renderType = frantic::max3d::viewport::RT_VELOCITY;
        }

        auto uncheckedCurrentRenderItem = markerRenderItem.GetCustomeImplementation();

        if( uncheckedCurrentRenderItem ) {
            frantic::max3d::viewport::ParticleRenderItem<CHILD::particle_t>* currentRenderItem =
                dynamic_cast<frantic::max3d::viewport::ParticleRenderItem<CHILD::particle_t>*>( uncheckedCurrentRenderItem );

            if( currentRenderItem ) {

                Point3 p( 0.5f * ( boundingBox.pmax.x + boundingBox.pmin.x ),
                          0.5f * ( boundingBox.pmax.y + boundingBox.pmin.y ), boundingBox.pmax.z );

                M_STD_STRING msg = boost::lexical_cast<M_STD_STRING>( m_viewportCache.size() );
                currentRenderItem->SetMessage( p, const_cast<MCHAR*>( msg.c_str() ) );

                if( doGPUUpload ) {
                    currentRenderItem->Initialize( m_viewportCache, renderType );
                }
            }
        }
    }

    void GenerateIconRenderItem( TimeValue& /*t*/, MaxSDK::Graphics::UpdateNodeContext& /*nodeContext*/,
                                 MaxSDK::Graphics::CustomRenderItemHandle& iconRenderItem ) {

        Matrix3 tm( true );
#if MAX_VERSION_MAJOR >= 25
        MaxSDK::SharedMeshPtr pIconMesh = GetIconMeshShared( tm );
#else
        Mesh* pIconMesh = GetIconMesh( tm );
#endif
        MaxSDK::Graphics::Matrix44 iconTM;
        MaxSDK::Graphics::MaxWorldMatrixToMatrix44( iconTM, tm );

#if MAX_VERSION_MAJOR >= 25
        std::auto_ptr<MaxSDK::Graphics::Utilities::MeshEdgeRenderItem> iconImpl(
            new frantic::max3d::viewport::DecoratedMeshEdgeRenderItem( pIconMesh, false, iconTM ) );
#else
        std::auto_ptr<MaxSDK::Graphics::Utilities::MeshEdgeRenderItem> iconImpl(
            new frantic::max3d::viewport::DecoratedMeshEdgeRenderItem( pIconMesh, false, false, iconTM ) );
#endif

        iconRenderItem.Release();
        iconRenderItem.Initialize();
        iconRenderItem.SetCustomImplementation( iconImpl.release() );
    }

#endif
};

} // namespace max3d
} // namespace krakatoa