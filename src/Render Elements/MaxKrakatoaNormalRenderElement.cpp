// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0
#include "resource.h"
#include "stdafx.h"

#include "Render Elements\MaxKrakatoaRenderElement.h"

#include <krakatoa\normal_render_element.hpp>

#define MaxKrakatoaNormalRenderElement_CLASS_NAME _T("Krakatoa Normal")
#define MaxKrakatoaNormalRenderElement_CLASS_ID Class_ID( 0x761d705e, 0x2aaf172a )

class MaxKrakatoaNormalRenderElement : public MaxKrakatoaRenderElement<MaxKrakatoaNormalRenderElement> {
  protected:
    ClassDesc2* GetClassDesc();

  public:
    static void DefineParamBlock( ParamBlockDesc2* pParamDesc );

    MaxKrakatoaNormalRenderElement();
    virtual ~MaxKrakatoaNormalRenderElement();

    // From IKrakatoaRenderElement
    virtual krakatoa::render_element_interface* get_render_element( krakatoa::scene_context_ptr pSceneContext );

    // From ReferenceMaker
    virtual RefResult NotifyRefChanged( const Interval& changeInt, RefTargetHandle hTarget, PartID& partID,
                                        RefMessage message, BOOL propagate );
};

class MaxKrakatoaNormalRenderElementDesc : public ClassDesc2 {
    ParamBlockDesc2* m_pParamDesc;

  public:
    MaxKrakatoaNormalRenderElementDesc();
    virtual ~MaxKrakatoaNormalRenderElementDesc();

    int IsPublic() { return TRUE; }
    void* Create( BOOL ) { return new MaxKrakatoaNormalRenderElement; }
    const TCHAR* ClassName() { return MaxKrakatoaNormalRenderElement_CLASS_NAME; }
#if MAX_VERSION_MAJOR >= 24
    const TCHAR* NonLocalizedClassName() { return MaxKrakatoaNormalRenderElement_CLASS_NAME; }
#endif
    SClass_ID SuperClassID() { return RENDER_ELEMENT_CLASS_ID; }
    Class_ID ClassID() { return MaxKrakatoaNormalRenderElement_CLASS_ID; }
    const TCHAR* Category() { return _T(""); }

    const TCHAR* InternalName() {
        return MaxKrakatoaNormalRenderElement_CLASS_NAME;
    }                                           // returns fixed parsable name (scripter-visible name)
    HINSTANCE HInstance() { return hInstance; } // returns owning module handle
};

ClassDesc2* GetMaxKrakatoaNormalRenderElementDesc() {
    static MaxKrakatoaNormalRenderElementDesc theMaxKrakatoaNormalRenderElementDesc;
    return &theMaxKrakatoaNormalRenderElementDesc;
}

MaxKrakatoaNormalRenderElementDesc::MaxKrakatoaNormalRenderElementDesc() {
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

    MaxKrakatoaNormalRenderElement::DefineParamBlock( m_pParamDesc );
}

MaxKrakatoaNormalRenderElementDesc::~MaxKrakatoaNormalRenderElementDesc() {}

MaxKrakatoaNormalRenderElement::MaxKrakatoaNormalRenderElement() {
    GetMaxKrakatoaNormalRenderElementDesc()->MakeAutoParamBlocks( this );
}

MaxKrakatoaNormalRenderElement::~MaxKrakatoaNormalRenderElement() {}

ClassDesc2* MaxKrakatoaNormalRenderElement::GetClassDesc() { return GetMaxKrakatoaNormalRenderElementDesc(); }

void MaxKrakatoaNormalRenderElement::DefineParamBlock( ParamBlockDesc2* pParamDesc ) {
    MaxKrakatoaRenderElement<MaxKrakatoaNormalRenderElement>::DefineParamBlock( pParamDesc );

    pParamDesc->ParamOption( kElementName, p_default, MaxKrakatoaNormalRenderElement_CLASS_NAME, p_end );
}

krakatoa::render_element_interface*
MaxKrakatoaNormalRenderElement::get_render_element( krakatoa::scene_context_ptr pSceneContext ) {
    bool doAntialias = m_pblock->GetInt( kDoFilter ) != FALSE;

    std::auto_ptr<krakatoa::normal_render_element> pElement(
        new krakatoa::normal_render_element( pSceneContext, doAntialias, true ) );

    pElement->register_commit_callback( boost::bind( &MaxKrakatoaNormalRenderElement::write_back, this, _1 ) );

    return pElement.release();
}

RefResult MaxKrakatoaNormalRenderElement::NotifyRefChanged( const Interval& /*changeInt*/, RefTargetHandle hTarget,
                                                            PartID& /*partID*/, RefMessage message,
                                                            BOOL /*propagate*/ ) {
    return REF_SUCCEED;
}
