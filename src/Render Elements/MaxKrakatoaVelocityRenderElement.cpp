// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0
#include "stdafx.h"

#include "resource.h"

#include "Render Elements\MaxKrakatoaRenderElement.h"

#include <krakatoa\velocity_render_element.hpp>

#define MaxKrakatoaVelocityRenderElement_CLASS_NAME _T("Krakatoa Velocity")
#define MaxKrakatoaVelocityRenderElement_CLASS_ID Class_ID( 0x2a6d6a9a, 0x1c247148 )

class MaxKrakatoaVelocityRenderElement : public MaxKrakatoaRenderElement<MaxKrakatoaVelocityRenderElement> {
    enum { kUseMaxVelocity = kMaxKrakatoaRenderElementLastParamNum, kMaxVelocity };

  protected:
    ClassDesc2* GetClassDesc();

  public:
    static void DefineParamBlock( ParamBlockDesc2* pParamDesc );

    MaxKrakatoaVelocityRenderElement();
    virtual ~MaxKrakatoaVelocityRenderElement();

    // From IKrakatoaRenderElement
    virtual krakatoa::render_element_interface* get_render_element( krakatoa::scene_context_ptr pSceneContext );

    // From ReferenceMaker
    virtual RefResult NotifyRefChanged( const Interval& changeInt, RefTargetHandle hTarget, PartID& partID,
                                        RefMessage message, BOOL propagate );
};

class MaxKrakatoaVelocityRenderElementDesc : public ClassDesc2 {
    ParamBlockDesc2* m_pParamDesc;

  public:
    MaxKrakatoaVelocityRenderElementDesc();
    virtual ~MaxKrakatoaVelocityRenderElementDesc();

    int IsPublic() { return TRUE; }
    void* Create( BOOL ) { return new MaxKrakatoaVelocityRenderElement; }
    const TCHAR* ClassName() { return MaxKrakatoaVelocityRenderElement_CLASS_NAME; }
#if MAX_VERSION_MAJOR >= 24
    const TCHAR* NonLocalizedClassName() { return MaxKrakatoaVelocityRenderElement_CLASS_NAME; }
#endif
    SClass_ID SuperClassID() { return RENDER_ELEMENT_CLASS_ID; }
    Class_ID ClassID() { return MaxKrakatoaVelocityRenderElement_CLASS_ID; }
    const TCHAR* Category() { return _T(""); }

    const TCHAR* InternalName() {
        return MaxKrakatoaVelocityRenderElement_CLASS_NAME;
    }                                           // returns fixed parsable name (scripter-visible name)
    HINSTANCE HInstance() { return hInstance; } // returns owning module handle
};

ClassDesc2* GetMaxKrakatoaVelocityRenderElementDesc() {
    static MaxKrakatoaVelocityRenderElementDesc theMaxKrakatoaVelocityRenderElementDesc;
    return &theMaxKrakatoaVelocityRenderElementDesc;
}

MaxKrakatoaVelocityRenderElementDesc::MaxKrakatoaVelocityRenderElementDesc() {
    m_pParamDesc = new ParamBlockDesc2( 0,                                        // Block num
                                        _T("Parameters"),                         // Internal name
                                        NULL,                                     // Localized name
                                        this,                                     // ClassDesc2*
                                        P_AUTO_CONSTRUCT | P_VERSION | P_AUTO_UI, // Flags
                                        0,                                        // Version
                                        0,                                        // PBlock Ref Num
                                        IDD_RENDERELEMENT_VELOCITY, IDS_PARAMETERS, 0, 0, NULL, p_end );

    MaxKrakatoaVelocityRenderElement::DefineParamBlock( m_pParamDesc );
}

MaxKrakatoaVelocityRenderElementDesc::~MaxKrakatoaVelocityRenderElementDesc() {}

MaxKrakatoaVelocityRenderElement::MaxKrakatoaVelocityRenderElement() {
    GetMaxKrakatoaVelocityRenderElementDesc()->MakeAutoParamBlocks( this );
}

MaxKrakatoaVelocityRenderElement::~MaxKrakatoaVelocityRenderElement() {}

ClassDesc2* MaxKrakatoaVelocityRenderElement::GetClassDesc() { return GetMaxKrakatoaVelocityRenderElementDesc(); }

void MaxKrakatoaVelocityRenderElement::DefineParamBlock( ParamBlockDesc2* pParamDesc ) {
    MaxKrakatoaRenderElement<MaxKrakatoaVelocityRenderElement>::DefineParamBlock( pParamDesc );

    pParamDesc->ParamOption( kElementName, p_default, MaxKrakatoaVelocityRenderElement_CLASS_NAME, p_end );

    pParamDesc->AddParam( kUseMaxVelocity, _T("useMaxVelocity"), TYPE_BOOL, P_RESET_DEFAULT, 0, p_end );
    pParamDesc->ParamOption( kUseMaxVelocity, p_default, FALSE, p_end );
    pParamDesc->ParamOption( kUseMaxVelocity, p_ui, TYPE_SINGLECHEKBOX, IDC_CHECK_RENDERELEMENT_VELOCITY_USEMAX,
                             p_end );

    pParamDesc->AddParam( kMaxVelocity, _T("maxVelocity"), TYPE_FLOAT, P_RESET_DEFAULT, 0, p_end );
    pParamDesc->ParamOption( kMaxVelocity, p_range, 0.f, FLT_MAX );
    pParamDesc->ParamOption( kMaxVelocity, p_default, 100.f );
    pParamDesc->ParamOption( kMaxVelocity, p_ui, TYPE_SPINNER, EDITTYPE_POS_UNIVERSE,
                             IDC_EDIT_RENDERELEMENT_VELOCITY_MAX, IDC_SPIN_RENDERELEMENT_VELOCITY_MAX, SPIN_AUTOSCALE );
}

krakatoa::render_element_interface*
MaxKrakatoaVelocityRenderElement::get_render_element( krakatoa::scene_context_ptr pSceneContext ) {
    bool doAntialias = m_pblock->GetInt( kDoFilter ) != FALSE;
    bool doVelocityMax = m_pblock->GetInt( kUseMaxVelocity ) != FALSE;
    float maxVelocity = m_pblock->GetFloat( kMaxVelocity );
    float frameRate = (float)GetFrameRate();

    std::auto_ptr<krakatoa::velocity_render_element> pElement(
        new krakatoa::velocity_render_element( pSceneContext, doAntialias, frameRate, doVelocityMax, maxVelocity ) );

    pElement->register_commit_callback( boost::bind( &MaxKrakatoaVelocityRenderElement::write_back, this, _1 ) );

    return pElement.release();
}

RefResult MaxKrakatoaVelocityRenderElement::NotifyRefChanged( const Interval& /*changeInt*/, RefTargetHandle hTarget,
                                                              PartID& /*partID*/, RefMessage message,
                                                              BOOL /*propagate*/ ) {
    return REF_SUCCEED;
}
