// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0
#include "stdafx.h"

#include "resource.h"

#include "Render Elements\MaxKrakatoaRenderElement.h"

#include <krakatoa\emission_render_element.hpp>

#define MaxKrakatoaEmissionRenderElement_CLASS_NAME _T("Krakatoa Emission")
#define MaxKrakatoaEmissionRenderElement_CLASS_ID Class_ID( 0x609b24bc, 0x21b126f8 )

class MaxKrakatoaEmissionRenderElement : public MaxKrakatoaRenderElement<MaxKrakatoaEmissionRenderElement> {

  protected:
    ClassDesc2* GetClassDesc();

  public:
    static void DefineParamBlock( ParamBlockDesc2* pParamDesc );

    MaxKrakatoaEmissionRenderElement();
    virtual ~MaxKrakatoaEmissionRenderElement();

    // From IKrakatoaRenderElement
    virtual krakatoa::render_element_interface* get_render_element( krakatoa::scene_context_ptr pSceneContext );

    // From ReferenceMaker
    virtual RefResult NotifyRefChanged( const Interval& changeInt, RefTargetHandle hTarget, PartID& partID,
                                        RefMessage message, BOOL propagate );
};

class MaxKrakatoaEmissionRenderElementDesc : public ClassDesc2 {
    ParamBlockDesc2* m_pParamDesc;

  public:
    MaxKrakatoaEmissionRenderElementDesc();
    virtual ~MaxKrakatoaEmissionRenderElementDesc();

    int IsPublic() { return TRUE; }
    void* Create( BOOL ) { return new MaxKrakatoaEmissionRenderElement; }
    const TCHAR* ClassName() { return MaxKrakatoaEmissionRenderElement_CLASS_NAME; }
#if MAX_VERSION_MAJOR >= 24
    const TCHAR* NonLocalizedClassName() { return MaxKrakatoaEmissionRenderElement_CLASS_NAME; }
#endif
    SClass_ID SuperClassID() { return RENDER_ELEMENT_CLASS_ID; }
    Class_ID ClassID() { return MaxKrakatoaEmissionRenderElement_CLASS_ID; }
    const TCHAR* Category() { return _T(""); }

    // returns fixed parsable name (scripter-visible name)
    const TCHAR* InternalName() { return MaxKrakatoaEmissionRenderElement_CLASS_NAME; }
    HINSTANCE HInstance() { return hInstance; } // returns owning module handle
};

ClassDesc2* GetMaxKrakatoaEmissionRenderElementDesc() {
    static MaxKrakatoaEmissionRenderElementDesc theMaxKrakatoaEmissionRenderElementDesc;
    return &theMaxKrakatoaEmissionRenderElementDesc;
}

MaxKrakatoaEmissionRenderElementDesc::MaxKrakatoaEmissionRenderElementDesc() {
    m_pParamDesc = new ParamBlockDesc2( 0,                                            // Block num
                                        _T("Parameters"),                             // Internal name
                                        NULL,                                         // Localized name
                                        this,                                         // ClassDesc2*
                                        P_AUTO_CONSTRUCT | P_VERSION /*| P_AUTO_UI*/, // Flags
                                        0,                                            // Version
                                        0,                                            // PBlock Ref Num
                                        // IDD_RENDERELEMENT_DATA,
                                        // IDS_RENDELEM_DATA,
                                        // 0,
                                        // 0,
                                        // NULL,
                                        p_end );

    MaxKrakatoaEmissionRenderElement::DefineParamBlock( m_pParamDesc );
}

MaxKrakatoaEmissionRenderElementDesc::~MaxKrakatoaEmissionRenderElementDesc() {}

MaxKrakatoaEmissionRenderElement::MaxKrakatoaEmissionRenderElement() {
    GetMaxKrakatoaEmissionRenderElementDesc()->MakeAutoParamBlocks( this );
}

MaxKrakatoaEmissionRenderElement::~MaxKrakatoaEmissionRenderElement() {}

ClassDesc2* MaxKrakatoaEmissionRenderElement::GetClassDesc() { return GetMaxKrakatoaEmissionRenderElementDesc(); }

void MaxKrakatoaEmissionRenderElement::DefineParamBlock( ParamBlockDesc2* pParamDesc ) {
    MaxKrakatoaRenderElement<MaxKrakatoaEmissionRenderElement>::DefineParamBlock( pParamDesc );

    pParamDesc->ParamOption( kElementName, p_default, MaxKrakatoaEmissionRenderElement_CLASS_NAME, p_end );
}

krakatoa::render_element_interface*
MaxKrakatoaEmissionRenderElement::get_render_element( krakatoa::scene_context_ptr ) {
    std::auto_ptr<krakatoa::emission_render_element> pElement( new krakatoa::emission_render_element );

    pElement->register_commit_callback( boost::bind( &MaxKrakatoaEmissionRenderElement::write_back, this, _1 ) );

    return pElement.release();
}

RefResult MaxKrakatoaEmissionRenderElement::NotifyRefChanged( const Interval& /*changeInt*/, RefTargetHandle hTarget,
                                                              PartID& /*partID*/, RefMessage message,
                                                              BOOL /*propagate*/ ) {
    return REF_SUCCEED;
}
