// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0
#include "resource.h"
#include "stdafx.h"

#include "Render Elements\MaxKrakatoaRenderElement.h"

#include <krakatoa\tangent_render_element.hpp>

#define MaxKrakatoaTangentRenderElement_CLASS_NAME _T("Krakatoa Tangent")
#define MaxKrakatoaTangentRenderElement_CLASS_ID Class_ID( 0x5dc45f25, 0x16b36d65 )

class MaxKrakatoaTangentRenderElement : public MaxKrakatoaRenderElement<MaxKrakatoaTangentRenderElement> {
  protected:
    ClassDesc2* GetClassDesc();

  public:
    static void DefineParamBlock( ParamBlockDesc2* pParamDesc );

    MaxKrakatoaTangentRenderElement();
    virtual ~MaxKrakatoaTangentRenderElement();

    // From IKrakatoaRenderElement
    virtual krakatoa::render_element_interface* get_render_element( krakatoa::scene_context_ptr pSceneContext );

    // From ReferenceMaker
    virtual RefResult NotifyRefChanged( const Interval& changeInt, RefTargetHandle hTarget, PartID& partID,
                                        RefMessage message, BOOL propagate );
};

class MaxKrakatoaTangentRenderElementDesc : public ClassDesc2 {
    ParamBlockDesc2* m_pParamDesc;

  public:
    MaxKrakatoaTangentRenderElementDesc();
    virtual ~MaxKrakatoaTangentRenderElementDesc();

    int IsPublic() { return TRUE; }
    void* Create( BOOL ) { return new MaxKrakatoaTangentRenderElement; }
    const TCHAR* ClassName() { return MaxKrakatoaTangentRenderElement_CLASS_NAME; }
#if MAX_VERSION_MAJOR >= 24
    const TCHAR* NonLocalizedClassName() { return MaxKrakatoaTangentRenderElement_CLASS_NAME; }
#endif
    SClass_ID SuperClassID() { return RENDER_ELEMENT_CLASS_ID; }
    Class_ID ClassID() { return MaxKrakatoaTangentRenderElement_CLASS_ID; }
    const TCHAR* Category() { return _T(""); }

    const TCHAR* InternalName() {
        return MaxKrakatoaTangentRenderElement_CLASS_NAME;
    }                                           // returns fixed parsable name (scripter-visible name)
    HINSTANCE HInstance() { return hInstance; } // returns owning module handle
};

ClassDesc2* GetMaxKrakatoaTangentRenderElementDesc() {
    static MaxKrakatoaTangentRenderElementDesc theMaxKrakatoaTangentRenderElementDesc;
    return &theMaxKrakatoaTangentRenderElementDesc;
}

MaxKrakatoaTangentRenderElementDesc::MaxKrakatoaTangentRenderElementDesc() {
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

    MaxKrakatoaTangentRenderElement::DefineParamBlock( m_pParamDesc );
}

MaxKrakatoaTangentRenderElementDesc::~MaxKrakatoaTangentRenderElementDesc() {}

MaxKrakatoaTangentRenderElement::MaxKrakatoaTangentRenderElement() {
    GetMaxKrakatoaTangentRenderElementDesc()->MakeAutoParamBlocks( this );
}

MaxKrakatoaTangentRenderElement::~MaxKrakatoaTangentRenderElement() {}

ClassDesc2* MaxKrakatoaTangentRenderElement::GetClassDesc() { return GetMaxKrakatoaTangentRenderElementDesc(); }

void MaxKrakatoaTangentRenderElement::DefineParamBlock( ParamBlockDesc2* pParamDesc ) {
    MaxKrakatoaRenderElement<MaxKrakatoaTangentRenderElement>::DefineParamBlock( pParamDesc );

    pParamDesc->ParamOption( kElementName, p_default, MaxKrakatoaTangentRenderElement_CLASS_NAME, p_end );
}

krakatoa::render_element_interface*
MaxKrakatoaTangentRenderElement::get_render_element( krakatoa::scene_context_ptr pSceneContext ) {
    bool doAntialias = m_pblock->GetInt( kDoFilter ) != FALSE;

    std::auto_ptr<krakatoa::tangent_render_element> pElement(
        new krakatoa::tangent_render_element( pSceneContext, doAntialias ) );

    pElement->register_commit_callback( boost::bind( &MaxKrakatoaTangentRenderElement::write_back, this, _1 ) );

    return pElement.release();
}

RefResult MaxKrakatoaTangentRenderElement::NotifyRefChanged( const Interval& /*changeInt*/, RefTargetHandle hTarget,
                                                             PartID& /*partID*/, RefMessage message,
                                                             BOOL /*propagate*/ ) {
    return REF_SUCCEED;
}
