// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0
#include "stdafx.h"

#include "resource.h"

#include "Render Elements\MaxKrakatoaRenderElement.h"

#include <krakatoa\zdepth_render_element.hpp>

#define MaxKrakatoaZDepthRenderElement_CLASS_NAME _T("Krakatoa ZDepth")
#define MaxKrakatoaZDepthRenderElement_CLASS_ID Class_ID( 0x79df3212, 0x3f7548c3 )

class MaxKrakatoaZDepthRenderElement : public MaxKrakatoaRenderElement<MaxKrakatoaZDepthRenderElement> {
    enum { kUseDepthRange = kMaxKrakatoaRenderElementLastParamNum, kDepthMin, kDepthMax };

  protected:
    ClassDesc2* GetClassDesc();

  public:
    static void DefineParamBlock( ParamBlockDesc2* pParamDesc );

    MaxKrakatoaZDepthRenderElement();
    virtual ~MaxKrakatoaZDepthRenderElement();

    // From IKrakatoaRenderElement
    virtual krakatoa::render_element_interface* get_render_element( krakatoa::scene_context_ptr pSceneContext );

    // From ReferenceMaker
    virtual RefResult NotifyRefChanged( const Interval& changeInt, RefTargetHandle hTarget, PartID& partID,
                                        RefMessage message, BOOL propagate );
};

class MaxKrakatoaZDepthRenderElementDesc : public ClassDesc2 {
    ParamBlockDesc2* m_pParamDesc;

  public:
    MaxKrakatoaZDepthRenderElementDesc();
    virtual ~MaxKrakatoaZDepthRenderElementDesc();

    int IsPublic() { return TRUE; }
    void* Create( BOOL ) { return new MaxKrakatoaZDepthRenderElement; }
    const TCHAR* ClassName() { return MaxKrakatoaZDepthRenderElement_CLASS_NAME; }
#if MAX_VERSION_MAJOR >= 24
    const TCHAR* NonLocalizedClassName() { return MaxKrakatoaZDepthRenderElement_CLASS_NAME; }
#endif
    SClass_ID SuperClassID() { return RENDER_ELEMENT_CLASS_ID; }
    Class_ID ClassID() { return MaxKrakatoaZDepthRenderElement_CLASS_ID; }
    const TCHAR* Category() { return _T(""); }

    const TCHAR* InternalName() {
        return MaxKrakatoaZDepthRenderElement_CLASS_NAME;
    }                                           // returns fixed parsable name (scripter-visible name)
    HINSTANCE HInstance() { return hInstance; } // returns owning module handle
};

ClassDesc2* GetMaxKrakatoaZDepthRenderElementDesc() {
    static MaxKrakatoaZDepthRenderElementDesc theMaxKrakatoaZDepthRenderElementDesc;
    return &theMaxKrakatoaZDepthRenderElementDesc;
}

MaxKrakatoaZDepthRenderElementDesc::MaxKrakatoaZDepthRenderElementDesc() {
    m_pParamDesc = new ParamBlockDesc2( 0,                                        // Block num
                                        _T("Parameters"),                         // Internal name
                                        NULL,                                     // Localized name
                                        this,                                     // ClassDesc2*
                                        P_AUTO_CONSTRUCT | P_VERSION | P_AUTO_UI, // Flags
                                        0,                                        // Version
                                        0,                                        // PBlock Ref Num
                                        IDD_RENDERELEMENT_MATTEZDEPTH, IDS_PARAMETERS, 0, 0,
                                        NULL, // Reusing the MatteZDepth UI. Might need to be changed later.
                                        p_end );

    MaxKrakatoaZDepthRenderElement::DefineParamBlock( m_pParamDesc );
}

MaxKrakatoaZDepthRenderElementDesc::~MaxKrakatoaZDepthRenderElementDesc() {}

MaxKrakatoaZDepthRenderElement::MaxKrakatoaZDepthRenderElement() {
    GetMaxKrakatoaZDepthRenderElementDesc()->MakeAutoParamBlocks( this );
}

MaxKrakatoaZDepthRenderElement::~MaxKrakatoaZDepthRenderElement() {}

ClassDesc2* MaxKrakatoaZDepthRenderElement::GetClassDesc() { return GetMaxKrakatoaZDepthRenderElementDesc(); }

void MaxKrakatoaZDepthRenderElement::DefineParamBlock( ParamBlockDesc2* pParamDesc ) {
    MaxKrakatoaRenderElement<MaxKrakatoaZDepthRenderElement>::DefineParamBlock( pParamDesc );

    pParamDesc->ParamOption( kElementName, p_default, MaxKrakatoaZDepthRenderElement_CLASS_NAME, p_end );
    pParamDesc->ParamOption( kDoFilter, p_default, FALSE, p_end );

    pParamDesc->AddParam( kUseDepthRange, _T("useDepthRange"), TYPE_BOOL, P_RESET_DEFAULT, 0, p_end );
    pParamDesc->ParamOption( kUseDepthRange, p_default, FALSE );
    pParamDesc->ParamOption( kUseDepthRange, p_ui, TYPE_SINGLECHEKBOX, IDC_CHECK_RENDERELEMENT_MATTEZDEPTH_USERANGE );

    pParamDesc->AddParam( kDepthMin, _T("depthMin"), TYPE_FLOAT, P_RESET_DEFAULT, 0, p_end );
    pParamDesc->ParamOption( kDepthMin, p_default, 0.f );
    pParamDesc->ParamOption( kDepthMin, p_range, 0.f, FLT_MAX );
    pParamDesc->ParamOption( kDepthMin, p_ui, TYPE_SPINNER, EDITTYPE_POS_UNIVERSE,
                             IDC_EDIT_RENDERELEMENT_MATTEZDEPTH_MIN, IDC_SPIN_RENDERELEMENT_MATTEZDEPTH_MIN,
                             SPIN_AUTOSCALE );

    pParamDesc->AddParam( kDepthMax, _T("depthMax"), TYPE_FLOAT, P_RESET_DEFAULT, 0, p_end );
    pParamDesc->ParamOption( kDepthMax, p_default, 1000.f );
    pParamDesc->ParamOption( kDepthMax, p_range, 0.f, FLT_MAX );
    pParamDesc->ParamOption( kDepthMax, p_ui, TYPE_SPINNER, EDITTYPE_POS_UNIVERSE,
                             IDC_EDIT_RENDERELEMENT_MATTEZDEPTH_MAX, IDC_SPIN_RENDERELEMENT_MATTEZDEPTH_MAX,
                             SPIN_AUTOSCALE );
}

krakatoa::render_element_interface*
MaxKrakatoaZDepthRenderElement::get_render_element( krakatoa::scene_context_ptr pSceneContext ) {
    bool doAntialias = m_pblock->GetInt( kDoFilter ) != FALSE;
    bool doDepthRange = m_pblock->GetInt( kUseDepthRange ) != FALSE;
    float minDepth = m_pblock->GetFloat( kDepthMin );
    float maxDepth = m_pblock->GetFloat( kDepthMax );

    std::auto_ptr<krakatoa::zdepth_render_element> pElement(
        new krakatoa::zdepth_render_element( pSceneContext, doAntialias, doDepthRange, minDepth, maxDepth ) );

    pElement->register_commit_callback( boost::bind( &MaxKrakatoaZDepthRenderElement::write_back, this, _1 ) );

    return pElement.release();
}

RefResult MaxKrakatoaZDepthRenderElement::NotifyRefChanged( const Interval& /*changeInt*/, RefTargetHandle hTarget,
                                                            PartID& /*partID*/, RefMessage message,
                                                            BOOL /*propagate*/ ) {
    return REF_SUCCEED;
}
