// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0
#include "stdafx.h"

#include "resource.h"

#include "Render Elements\MaxKrakatoaRenderElement.h"

#include <krakatoa\occluded_layer_render_element.hpp>

#define MaxKrakatoaOccludedLayerRenderElement_CLASS_NAME _T("Krakatoa OccludedLayer")
#define MaxKrakatoaOccludedLayerRenderElement_CLASS_ID Class_ID( 0x3d127acb, 0x7b9569c8 )

class MaxKrakatoaOccludedLayerRenderElement : public MaxKrakatoaRenderElement<MaxKrakatoaOccludedLayerRenderElement> {
  protected:
    ClassDesc2* GetClassDesc();

  public:
    static void DefineParamBlock( ParamBlockDesc2* pParamDesc );

    MaxKrakatoaOccludedLayerRenderElement();
    virtual ~MaxKrakatoaOccludedLayerRenderElement();

    // From IKrakatoaRenderElement
    virtual krakatoa::render_element_interface* get_render_element( krakatoa::scene_context_ptr pSceneContext );

    // From ReferenceMaker
    virtual RefResult NotifyRefChanged( const Interval& changeInt, RefTargetHandle hTarget, PartID& partID,
                                        RefMessage message, BOOL propagate );
};

class MaxKrakatoaOccludedLayerRenderElementDesc : public ClassDesc2 {
    ParamBlockDesc2* m_pParamDesc;

  public:
    MaxKrakatoaOccludedLayerRenderElementDesc();
    virtual ~MaxKrakatoaOccludedLayerRenderElementDesc();

    int IsPublic() { return TRUE; }
    void* Create( BOOL ) { return new MaxKrakatoaOccludedLayerRenderElement; }
    const TCHAR* ClassName() { return MaxKrakatoaOccludedLayerRenderElement_CLASS_NAME; }
#if MAX_VERSION_MAJOR >= 24
    const TCHAR* NonLocalizedClassName() { return MaxKrakatoaOccludedLayerRenderElement_CLASS_NAME; }
#endif
    SClass_ID SuperClassID() { return RENDER_ELEMENT_CLASS_ID; }
    Class_ID ClassID() { return MaxKrakatoaOccludedLayerRenderElement_CLASS_ID; }
    const TCHAR* Category() { return _T(""); }

    const TCHAR* InternalName() {
        return MaxKrakatoaOccludedLayerRenderElement_CLASS_NAME;
    }                                           // returns fixed parsable name (scripter-visible name)
    HINSTANCE HInstance() { return hInstance; } // returns owning module handle
};

ClassDesc2* GetMaxKrakatoaOccludedLayerRenderElementDesc() {
    static MaxKrakatoaOccludedLayerRenderElementDesc theMaxKrakatoaOccludedLayerRenderElementDesc;
    return &theMaxKrakatoaOccludedLayerRenderElementDesc;
}

MaxKrakatoaOccludedLayerRenderElementDesc::MaxKrakatoaOccludedLayerRenderElementDesc() {
    m_pParamDesc = new ParamBlockDesc2( 0,                            // Block num
                                        _T("Parameters"),             // Internal name
                                        IDS_PARAMETERS,               // Localized name
                                        this,                         // ClassDesc2*
                                        P_AUTO_CONSTRUCT | P_VERSION, // Flags
                                        0,                            // Version
                                        0,                            // PBlock Ref Num
                                        p_end );

    MaxKrakatoaOccludedLayerRenderElement::DefineParamBlock( m_pParamDesc );
}

MaxKrakatoaOccludedLayerRenderElementDesc::~MaxKrakatoaOccludedLayerRenderElementDesc() {}

MaxKrakatoaOccludedLayerRenderElement::MaxKrakatoaOccludedLayerRenderElement() {
    GetMaxKrakatoaOccludedLayerRenderElementDesc()->MakeAutoParamBlocks( this );
}

MaxKrakatoaOccludedLayerRenderElement::~MaxKrakatoaOccludedLayerRenderElement() {}

ClassDesc2* MaxKrakatoaOccludedLayerRenderElement::GetClassDesc() {
    return GetMaxKrakatoaOccludedLayerRenderElementDesc();
}

void MaxKrakatoaOccludedLayerRenderElement::DefineParamBlock( ParamBlockDesc2* pParamDesc ) {
    MaxKrakatoaRenderElement<MaxKrakatoaOccludedLayerRenderElement>::DefineParamBlock( pParamDesc );

    pParamDesc->ParamOption( kElementName, p_default, MaxKrakatoaOccludedLayerRenderElement_CLASS_NAME, p_end );
    pParamDesc->ParamOption( kDoFilter, p_default, FALSE, p_end );
}

krakatoa::render_element_interface*
MaxKrakatoaOccludedLayerRenderElement::get_render_element( krakatoa::scene_context_ptr ) {
    std::auto_ptr<krakatoa::occluded_layer_render_element> pElement( new krakatoa::occluded_layer_render_element );

    pElement->register_commit_callback( boost::bind( &MaxKrakatoaOccludedLayerRenderElement::write_back, this, _1 ) );

    return pElement.release();
}

RefResult MaxKrakatoaOccludedLayerRenderElement::NotifyRefChanged( const Interval& /*changeInt*/,
                                                                   RefTargetHandle hTarget, PartID& /*partID*/,
                                                                   RefMessage message, BOOL /*propagate*/ ) {
    return REF_SUCCEED;
}
