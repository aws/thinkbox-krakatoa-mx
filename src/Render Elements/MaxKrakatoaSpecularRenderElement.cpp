// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0
#include "resource.h"
#include "stdafx.h"

#include "Render Elements\MaxKrakatoaRenderElement.h"

#include <krakatoa/specular_render_element.hpp>

#define MaxKrakatoaSpecularRenderElement_CLASS_NAME _T("Krakatoa Specular")
#define MaxKrakatoaSpecularRenderElement_CLASS_ID Class_ID( 0x3a4d5bb7, 0x3c6b7426 )

class MaxKrakatoaSpecularRenderElement : public MaxKrakatoaRenderElement<MaxKrakatoaSpecularRenderElement> {
  protected:
    ClassDesc2* GetClassDesc();

  public:
    static void DefineParamBlock( ParamBlockDesc2* pParamDesc );

    MaxKrakatoaSpecularRenderElement();
    virtual ~MaxKrakatoaSpecularRenderElement();

    // From IKrakatoaRenderElement
    virtual krakatoa::render_element_interface* get_render_element( krakatoa::scene_context_ptr pSceneContext );

    // From ReferenceMaker
    virtual RefResult NotifyRefChanged( const Interval& changeInt, RefTargetHandle hTarget, PartID& partID,
                                        RefMessage message, BOOL propagate );
};

class MaxKrakatoaSpecularRenderElementDesc : public ClassDesc2 {
    ParamBlockDesc2* m_pParamDesc;

  public:
    MaxKrakatoaSpecularRenderElementDesc();
    virtual ~MaxKrakatoaSpecularRenderElementDesc();

    int IsPublic() { return TRUE; }
    void* Create( BOOL ) { return new MaxKrakatoaSpecularRenderElement; }
    const TCHAR* ClassName() { return MaxKrakatoaSpecularRenderElement_CLASS_NAME; }
#if MAX_VERSION_MAJOR >= 24
    const TCHAR* NonLocalizedClassName() { return MaxKrakatoaSpecularRenderElement_CLASS_NAME; }
#endif
    SClass_ID SuperClassID() { return RENDER_ELEMENT_CLASS_ID; }
    Class_ID ClassID() { return MaxKrakatoaSpecularRenderElement_CLASS_ID; }
    const TCHAR* Category() { return _T(""); }

    const TCHAR* InternalName() {
        return MaxKrakatoaSpecularRenderElement_CLASS_NAME;
    }                                           // returns fixed parsable name (scripter-visible name)
    HINSTANCE HInstance() { return hInstance; } // returns owning module handle
};

ClassDesc2* GetMaxKrakatoaSpecularRenderElementDesc() {
    static MaxKrakatoaSpecularRenderElementDesc theMaxKrakatoaSpecularRenderElementDesc;
    return &theMaxKrakatoaSpecularRenderElementDesc;
}

MaxKrakatoaSpecularRenderElementDesc::MaxKrakatoaSpecularRenderElementDesc() {
    m_pParamDesc = new ParamBlockDesc2( 0,                                            // Block num
                                        _T("Parameters"),                             // Internal name
                                        NULL,                                         // Localized name
                                        this,                                         // ClassDesc2*
                                        P_AUTO_CONSTRUCT | P_VERSION /*| P_AUTO_UI*/, // Flags
                                        0,                                            // Version
                                        0,                                            // PBlock Ref Num
                                        p_end );

    MaxKrakatoaSpecularRenderElement::DefineParamBlock( m_pParamDesc );
}

MaxKrakatoaSpecularRenderElementDesc::~MaxKrakatoaSpecularRenderElementDesc() {}

MaxKrakatoaSpecularRenderElement::MaxKrakatoaSpecularRenderElement() {
    GetMaxKrakatoaSpecularRenderElementDesc()->MakeAutoParamBlocks( this );
}

MaxKrakatoaSpecularRenderElement::~MaxKrakatoaSpecularRenderElement() {}

ClassDesc2* MaxKrakatoaSpecularRenderElement::GetClassDesc() { return GetMaxKrakatoaSpecularRenderElementDesc(); }

void MaxKrakatoaSpecularRenderElement::DefineParamBlock( ParamBlockDesc2* pParamDesc ) {
    MaxKrakatoaRenderElement<MaxKrakatoaSpecularRenderElement>::DefineParamBlock( pParamDesc );

    pParamDesc->ParamOption( kElementName, p_default, MaxKrakatoaSpecularRenderElement_CLASS_NAME, p_end );
}

krakatoa::render_element_interface*
MaxKrakatoaSpecularRenderElement::get_render_element( krakatoa::scene_context_ptr ) {
    std::auto_ptr<krakatoa::specular_render_element> pElement( new krakatoa::specular_render_element );

    pElement->register_commit_callback( boost::bind( &MaxKrakatoaSpecularRenderElement::write_back, this, _1 ) );

    return pElement.release();
}

RefResult MaxKrakatoaSpecularRenderElement::NotifyRefChanged( const Interval& /*changeInt*/, RefTargetHandle hTarget,
                                                              PartID& /*partID*/, RefMessage message,
                                                              BOOL /*propagate*/ ) {
    return REF_SUCCEED;
}
