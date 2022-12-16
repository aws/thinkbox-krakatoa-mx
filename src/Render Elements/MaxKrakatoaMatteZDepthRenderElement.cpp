// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0
#include "stdafx.h"

#include "resource.h"

#include "Render Elements\MaxKrakatoaRenderElement.h"

#include <krakatoa\matte_zdepth_render_element.hpp>

#define MaxKrakatoaMatteZDepthRenderElement_CLASS_NAME _T("Krakatoa MatteZDepth")
#define MaxKrakatoaMatteZDepthRenderElement_CLASS_ID Class_ID( 0x10a743cf, 0x778b49ec )

class MaxKrakatoaMatteZDepthRenderElement : public MaxKrakatoaRenderElement<MaxKrakatoaMatteZDepthRenderElement> {
  protected:
    ClassDesc2* GetClassDesc();

    enum { kUseDepthRange = kMaxKrakatoaRenderElementLastParamNum, kDepthMin, kDepthMax };

    void write_back( krakatoa::render_element_interface& elem );

  public:
    static void DefineParamBlock( ParamBlockDesc2* pParamDesc );

    MaxKrakatoaMatteZDepthRenderElement();
    virtual ~MaxKrakatoaMatteZDepthRenderElement();

    // From IKrakatoaRenderElement
    virtual krakatoa::render_element_interface* get_render_element( krakatoa::scene_context_ptr pSceneContext );

    // From ReferenceMaker
    virtual RefResult NotifyRefChanged( const Interval& changeInt, RefTargetHandle hTarget, PartID& partID,
                                        RefMessage message, BOOL propagate );
};

class MaxKrakatoaMatteZDepthRenderElementDesc : public ClassDesc2 {
    ParamBlockDesc2* m_pParamDesc;

  public:
    MaxKrakatoaMatteZDepthRenderElementDesc();
    virtual ~MaxKrakatoaMatteZDepthRenderElementDesc();

    int IsPublic() { return TRUE; }
    void* Create( BOOL ) { return new MaxKrakatoaMatteZDepthRenderElement; }
    const TCHAR* ClassName() { return MaxKrakatoaMatteZDepthRenderElement_CLASS_NAME; }
#if MAX_VERSION_MAJOR >= 24
    const TCHAR* NonLocalizedClassName() { return MaxKrakatoaMatteZDepthRenderElement_CLASS_NAME; }
#endif
    SClass_ID SuperClassID() { return RENDER_ELEMENT_CLASS_ID; }
    Class_ID ClassID() { return MaxKrakatoaMatteZDepthRenderElement_CLASS_ID; }
    const TCHAR* Category() { return _T(""); }

    const TCHAR* InternalName() {
        return MaxKrakatoaMatteZDepthRenderElement_CLASS_NAME;
    }                                           // returns fixed parsable name (scripter-visible name)
    HINSTANCE HInstance() { return hInstance; } // returns owning module handle
};

ClassDesc2* GetMaxKrakatoaMatteZDepthRenderElementDesc() {
    static MaxKrakatoaMatteZDepthRenderElementDesc theMaxKrakatoaMatteZDepthRenderElementDesc;
    return &theMaxKrakatoaMatteZDepthRenderElementDesc;
}

MaxKrakatoaMatteZDepthRenderElementDesc::MaxKrakatoaMatteZDepthRenderElementDesc() {
    m_pParamDesc = new ParamBlockDesc2( 0,                                        // Block num
                                        _T("Parameters"),                         // Internal name
                                        IDS_PARAMETERS,                           // Localized name
                                        this,                                     // ClassDesc2*
                                        P_AUTO_CONSTRUCT | P_VERSION | P_AUTO_UI, // Flags
                                        0,                                        // Version
                                        0,                                        // PBlock Ref Num
                                        IDD_RENDERELEMENT_MATTEZDEPTH, IDS_PARAMETERS, 0, 0, NULL, p_end );

    MaxKrakatoaMatteZDepthRenderElement::DefineParamBlock( m_pParamDesc );
}

MaxKrakatoaMatteZDepthRenderElementDesc::~MaxKrakatoaMatteZDepthRenderElementDesc() {}

MaxKrakatoaMatteZDepthRenderElement::MaxKrakatoaMatteZDepthRenderElement() {
    GetMaxKrakatoaMatteZDepthRenderElementDesc()->MakeAutoParamBlocks( this );
}

MaxKrakatoaMatteZDepthRenderElement::~MaxKrakatoaMatteZDepthRenderElement() {}

ClassDesc2* MaxKrakatoaMatteZDepthRenderElement::GetClassDesc() { return GetMaxKrakatoaMatteZDepthRenderElementDesc(); }

void MaxKrakatoaMatteZDepthRenderElement::write_back( krakatoa::render_element_interface& elem ) {
    const frantic::rendering::depthbuffer_singleface& db =
        static_cast<krakatoa::matte_zdepth_render_element&>( elem ).get_depthbuffer();

    PBBitmap* pPBBmp = NULL;
    GetPBBitmap( pPBBmp );

    if( pPBBmp && pPBBmp->bm )
        frantic::graphics2d::image::to_3dsMaxBitmap( pPBBmp->bm, db.data(), db.size() );
}

void MaxKrakatoaMatteZDepthRenderElement::DefineParamBlock( ParamBlockDesc2* pParamDesc ) {
    MaxKrakatoaRenderElement<MaxKrakatoaMatteZDepthRenderElement>::DefineParamBlock( pParamDesc );

    pParamDesc->ParamOption( kElementName, p_default, MaxKrakatoaMatteZDepthRenderElement_CLASS_NAME, p_end );
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
MaxKrakatoaMatteZDepthRenderElement::get_render_element( krakatoa::scene_context_ptr ) {
    bool applyRange = m_pblock->GetInt( kUseDepthRange ) != FALSE;
    float depthMin = m_pblock->GetFloat( kDepthMin );
    float depthMax = m_pblock->GetFloat( kDepthMax );

    std::auto_ptr<krakatoa::matte_zdepth_render_element> pElement(
        new krakatoa::matte_zdepth_render_element( applyRange, depthMin, depthMax ) );

    pElement->register_commit_callback( boost::bind( &MaxKrakatoaMatteZDepthRenderElement::write_back, this, _1 ) );

    return pElement.release();
}

RefResult MaxKrakatoaMatteZDepthRenderElement::NotifyRefChanged( const Interval& /*changeInt*/, RefTargetHandle hTarget,
                                                                 PartID& /*partID*/, RefMessage message,
                                                                 BOOL /*propagate*/ ) {
    return REF_SUCCEED;
}
