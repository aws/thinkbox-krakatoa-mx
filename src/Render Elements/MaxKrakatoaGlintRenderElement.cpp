// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0
#include "resource.h"
#include "stdafx.h"

#include "Render Elements\MaxKrakatoaRenderElement.h"

#include <krakatoa/shader_render_element.hpp>

#define MaxKrakatoaGlintRenderElement_CLASS_NAME _T("Krakatoa Glint")
#define MaxKrakatoaGlintRenderElement_CLASS_ID Class_ID( 0x1595edb, 0x2af07e51 )

class MaxKrakatoaGlintRenderElement : public MaxKrakatoaRenderElement<MaxKrakatoaGlintRenderElement> {
  protected:
    ClassDesc2* GetClassDesc();

  public:
    static void DefineParamBlock( ParamBlockDesc2* pParamDesc );

    MaxKrakatoaGlintRenderElement();
    virtual ~MaxKrakatoaGlintRenderElement();

    // From IKrakatoaRenderElement
    virtual krakatoa::render_element_interface* get_render_element( krakatoa::scene_context_ptr pSceneContext );

    // From ReferenceMaker
    virtual RefResult NotifyRefChanged( const Interval& changeInt, RefTargetHandle hTarget, PartID& partID,
                                        RefMessage message, BOOL propagate );
};

class MaxKrakatoaGlintRenderElementDesc : public ClassDesc2 {
    ParamBlockDesc2* m_pParamDesc;

  public:
    MaxKrakatoaGlintRenderElementDesc();
    virtual ~MaxKrakatoaGlintRenderElementDesc();

    int IsPublic() { return TRUE; }
    void* Create( BOOL ) { return new MaxKrakatoaGlintRenderElement; }
    const TCHAR* ClassName() { return MaxKrakatoaGlintRenderElement_CLASS_NAME; }
#if MAX_VERSION_MAJOR >= 24
    const TCHAR* NonLocalizedClassName() { return MaxKrakatoaGlintRenderElement_CLASS_NAME; }
#endif
    SClass_ID SuperClassID() { return RENDER_ELEMENT_CLASS_ID; }
    Class_ID ClassID() { return MaxKrakatoaGlintRenderElement_CLASS_ID; }
    const TCHAR* Category() { return _T(""); }

    const TCHAR* InternalName() {
        return MaxKrakatoaGlintRenderElement_CLASS_NAME;
    }                                           // returns fixed parsable name (scripter-visible name)
    HINSTANCE HInstance() { return hInstance; } // returns owning module handle
};

ClassDesc2* GetMaxKrakatoaGlintRenderElementDesc() {
    static MaxKrakatoaGlintRenderElementDesc theMaxKrakatoaGlintRenderElementDesc;
    return &theMaxKrakatoaGlintRenderElementDesc;
}

MaxKrakatoaGlintRenderElementDesc::MaxKrakatoaGlintRenderElementDesc() {
    m_pParamDesc = new ParamBlockDesc2( 0,                                            // Block num
                                        _T("Parameters"),                             // Internal name
                                        NULL,                                         // Localized name
                                        this,                                         // ClassDesc2*
                                        P_AUTO_CONSTRUCT | P_VERSION /*| P_AUTO_UI*/, // Flags
                                        0,                                            // Version
                                        0,                                            // PBlock Ref Num
                                        p_end );

    MaxKrakatoaGlintRenderElement::DefineParamBlock( m_pParamDesc );
}

MaxKrakatoaGlintRenderElementDesc::~MaxKrakatoaGlintRenderElementDesc() {}

MaxKrakatoaGlintRenderElement::MaxKrakatoaGlintRenderElement() {
    GetMaxKrakatoaGlintRenderElementDesc()->MakeAutoParamBlocks( this );
}

MaxKrakatoaGlintRenderElement::~MaxKrakatoaGlintRenderElement() {}

ClassDesc2* MaxKrakatoaGlintRenderElement::GetClassDesc() { return GetMaxKrakatoaGlintRenderElementDesc(); }

void MaxKrakatoaGlintRenderElement::DefineParamBlock( ParamBlockDesc2* pParamDesc ) {
    MaxKrakatoaRenderElement<MaxKrakatoaGlintRenderElement>::DefineParamBlock( pParamDesc );

    pParamDesc->ParamOption( kElementName, p_default, MaxKrakatoaGlintRenderElement_CLASS_NAME, p_end );
}

krakatoa::render_element_interface* MaxKrakatoaGlintRenderElement::get_render_element( krakatoa::scene_context_ptr ) {
    std::auto_ptr<krakatoa::shader_render_element> pElement( new krakatoa::shader_render_element( _T("Specular3") ) );

    pElement->register_commit_callback( boost::bind( &MaxKrakatoaGlintRenderElement::write_back, this, _1 ) );

    return pElement.release();
}

RefResult MaxKrakatoaGlintRenderElement::NotifyRefChanged( const Interval& /*changeInt*/, RefTargetHandle hTarget,
                                                           PartID& /*partID*/, RefMessage message,
                                                           BOOL /*propagate*/ ) {
    return REF_SUCCEED;
}
