// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0
#include "resource.h"
#include "stdafx.h"

#include "Render Elements\MaxKrakatoaRenderElement.h"

#include <krakatoa/diffuse_render_element.hpp>

#define MaxKrakatoaDiffuseRenderElement_CLASS_NAME _T("Krakatoa Diffuse")
#define MaxKrakatoaDiffuseRenderElement_CLASS_ID Class_ID( 0x189d3cf0, 0x5be22576 )

class MaxKrakatoaDiffuseRenderElement : public MaxKrakatoaRenderElement<MaxKrakatoaDiffuseRenderElement> {
  protected:
    ClassDesc2* GetClassDesc();

  public:
    static void DefineParamBlock( ParamBlockDesc2* pParamDesc );

    MaxKrakatoaDiffuseRenderElement();
    virtual ~MaxKrakatoaDiffuseRenderElement();

    // From IKrakatoaRenderElement
    virtual krakatoa::render_element_interface* get_render_element( krakatoa::scene_context_ptr pSceneContext );

    // From ReferenceMaker
    virtual RefResult NotifyRefChanged( const Interval& changeInt, RefTargetHandle hTarget, PartID& partID,
                                        RefMessage message, BOOL propagate );
};

class MaxKrakatoaDiffuseRenderElementDesc : public ClassDesc2 {
    ParamBlockDesc2* m_pParamDesc;

  public:
    MaxKrakatoaDiffuseRenderElementDesc();
    virtual ~MaxKrakatoaDiffuseRenderElementDesc();

    int IsPublic() { return TRUE; }
    void* Create( BOOL ) { return new MaxKrakatoaDiffuseRenderElement; }
    const TCHAR* ClassName() { return MaxKrakatoaDiffuseRenderElement_CLASS_NAME; }
#if MAX_VERSION_MAJOR >= 24
    const TCHAR* NonLocalizedClassName() { return MaxKrakatoaDiffuseRenderElement_CLASS_NAME; }
#endif
    SClass_ID SuperClassID() { return RENDER_ELEMENT_CLASS_ID; }
    Class_ID ClassID() { return MaxKrakatoaDiffuseRenderElement_CLASS_ID; }
    const TCHAR* Category() { return _T(""); }

    const TCHAR* InternalName() {
        return MaxKrakatoaDiffuseRenderElement_CLASS_NAME;
    }                                           // returns fixed parsable name (scripter-visible name)
    HINSTANCE HInstance() { return hInstance; } // returns owning module handle
};

ClassDesc2* GetMaxKrakatoaDiffuseRenderElementDesc() {
    static MaxKrakatoaDiffuseRenderElementDesc theMaxKrakatoaDiffuseRenderElementDesc;
    return &theMaxKrakatoaDiffuseRenderElementDesc;
}

MaxKrakatoaDiffuseRenderElementDesc::MaxKrakatoaDiffuseRenderElementDesc() {
    m_pParamDesc = new ParamBlockDesc2( 0,                                            // Block num
                                        _T("Parameters"),                             // Internal name
                                        NULL,                                         // Localized name
                                        this,                                         // ClassDesc2*
                                        P_AUTO_CONSTRUCT | P_VERSION /*| P_AUTO_UI*/, // Flags
                                        0,                                            // Version
                                        0,                                            // PBlock Ref Num
                                        p_end );

    MaxKrakatoaDiffuseRenderElement::DefineParamBlock( m_pParamDesc );
}

MaxKrakatoaDiffuseRenderElementDesc::~MaxKrakatoaDiffuseRenderElementDesc() {}

MaxKrakatoaDiffuseRenderElement::MaxKrakatoaDiffuseRenderElement() {
    GetMaxKrakatoaDiffuseRenderElementDesc()->MakeAutoParamBlocks( this );
}

MaxKrakatoaDiffuseRenderElement::~MaxKrakatoaDiffuseRenderElement() {}

ClassDesc2* MaxKrakatoaDiffuseRenderElement::GetClassDesc() { return GetMaxKrakatoaDiffuseRenderElementDesc(); }

void MaxKrakatoaDiffuseRenderElement::DefineParamBlock( ParamBlockDesc2* pParamDesc ) {
    MaxKrakatoaRenderElement<MaxKrakatoaDiffuseRenderElement>::DefineParamBlock( pParamDesc );

    pParamDesc->ParamOption( kElementName, p_default, MaxKrakatoaDiffuseRenderElement_CLASS_NAME, p_end );
}

krakatoa::render_element_interface* MaxKrakatoaDiffuseRenderElement::get_render_element( krakatoa::scene_context_ptr ) {
    std::auto_ptr<krakatoa::diffuse_render_element> pElement( new krakatoa::diffuse_render_element );

    pElement->register_commit_callback( boost::bind( &MaxKrakatoaDiffuseRenderElement::write_back, this, _1 ) );

    return pElement.release();
}

RefResult MaxKrakatoaDiffuseRenderElement::NotifyRefChanged( const Interval& /*changeInt*/, RefTargetHandle hTarget,
                                                             PartID& /*partID*/, RefMessage message,
                                                             BOOL /*propagate*/ ) {
    return REF_SUCCEED;
}
