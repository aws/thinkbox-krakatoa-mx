// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0
#include "resource.h"
#include "stdafx.h"

#include "Render Elements\MaxKrakatoaRenderElement.h"

#include <krakatoa/shader_render_element.hpp>

#define MaxKrakatoaSpecular2RenderElement_CLASS_NAME _T("Krakatoa Specular2")
#define MaxKrakatoaSpecular2RenderElement_CLASS_ID Class_ID( 0xbc30b0, 0x1b513a23 )

class MaxKrakatoaSpecular2RenderElement : public MaxKrakatoaRenderElement<MaxKrakatoaSpecular2RenderElement> {
  protected:
    ClassDesc2* GetClassDesc();

  public:
    static void DefineParamBlock( ParamBlockDesc2* pParamDesc );

    MaxKrakatoaSpecular2RenderElement();
    virtual ~MaxKrakatoaSpecular2RenderElement();

    // From IKrakatoaRenderElement
    virtual krakatoa::render_element_interface* get_render_element( krakatoa::scene_context_ptr pSceneContext );

    // From ReferenceMaker
    virtual RefResult NotifyRefChanged( const Interval& changeInt, RefTargetHandle hTarget, PartID& partID,
                                        RefMessage message, BOOL propagate );
};

class MaxKrakatoaSpecular2RenderElementDesc : public ClassDesc2 {
    ParamBlockDesc2* m_pParamDesc;

  public:
    MaxKrakatoaSpecular2RenderElementDesc();
    virtual ~MaxKrakatoaSpecular2RenderElementDesc();

    int IsPublic() { return TRUE; }
    void* Create( BOOL ) { return new MaxKrakatoaSpecular2RenderElement; }
    const TCHAR* ClassName() { return MaxKrakatoaSpecular2RenderElement_CLASS_NAME; }
#if MAX_VERSION_MAJOR >= 24
    const TCHAR* NonLocalizedClassName() { return MaxKrakatoaSpecular2RenderElement_CLASS_NAME; }
#endif
    SClass_ID SuperClassID() { return RENDER_ELEMENT_CLASS_ID; }
    Class_ID ClassID() { return MaxKrakatoaSpecular2RenderElement_CLASS_ID; }
    const TCHAR* Category() { return _T(""); }

    const TCHAR* InternalName() {
        return MaxKrakatoaSpecular2RenderElement_CLASS_NAME;
    }                                           // returns fixed parsable name (scripter-visible name)
    HINSTANCE HInstance() { return hInstance; } // returns owning module handle
};

ClassDesc2* GetMaxKrakatoaSpecular2RenderElementDesc() {
    static MaxKrakatoaSpecular2RenderElementDesc theMaxKrakatoaSpecular2RenderElementDesc;
    return &theMaxKrakatoaSpecular2RenderElementDesc;
}

MaxKrakatoaSpecular2RenderElementDesc::MaxKrakatoaSpecular2RenderElementDesc() {
    m_pParamDesc = new ParamBlockDesc2( 0,                                            // Block num
                                        _T("Parameters"),                             // Internal name
                                        NULL,                                         // Localized name
                                        this,                                         // ClassDesc2*
                                        P_AUTO_CONSTRUCT | P_VERSION /*| P_AUTO_UI*/, // Flags
                                        0,                                            // Version
                                        0,                                            // PBlock Ref Num
                                        p_end );

    MaxKrakatoaSpecular2RenderElement::DefineParamBlock( m_pParamDesc );
}

MaxKrakatoaSpecular2RenderElementDesc::~MaxKrakatoaSpecular2RenderElementDesc() {}

MaxKrakatoaSpecular2RenderElement::MaxKrakatoaSpecular2RenderElement() {
    GetMaxKrakatoaSpecular2RenderElementDesc()->MakeAutoParamBlocks( this );
}

MaxKrakatoaSpecular2RenderElement::~MaxKrakatoaSpecular2RenderElement() {}

ClassDesc2* MaxKrakatoaSpecular2RenderElement::GetClassDesc() { return GetMaxKrakatoaSpecular2RenderElementDesc(); }

void MaxKrakatoaSpecular2RenderElement::DefineParamBlock( ParamBlockDesc2* pParamDesc ) {
    MaxKrakatoaRenderElement<MaxKrakatoaSpecular2RenderElement>::DefineParamBlock( pParamDesc );

    pParamDesc->ParamOption( kElementName, p_default, MaxKrakatoaSpecular2RenderElement_CLASS_NAME, p_end );
}

krakatoa::render_element_interface*
MaxKrakatoaSpecular2RenderElement::get_render_element( krakatoa::scene_context_ptr ) {
    std::auto_ptr<krakatoa::shader_render_element> pElement( new krakatoa::shader_render_element( _T("Specular2") ) );

    pElement->register_commit_callback( boost::bind( &MaxKrakatoaSpecular2RenderElement::write_back, this, _1 ) );

    return pElement.release();
}

RefResult MaxKrakatoaSpecular2RenderElement::NotifyRefChanged( const Interval& /*changeInt*/, RefTargetHandle hTarget,
                                                               PartID& /*partID*/, RefMessage message,
                                                               BOOL /*propagate*/ ) {
    return REF_SUCCEED;
}
