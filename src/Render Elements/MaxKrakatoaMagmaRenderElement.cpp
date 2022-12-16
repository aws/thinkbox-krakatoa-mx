// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0
#include "stdafx.h"

#include "resource.h"

#include "MaxKrakatoaChannelModifier.h"
#include "MaxKrakatoaMagmaHolder.h"
#include "MaxKrakatoaSceneContext.h"
#include "Render Elements\MaxKrakatoaRenderElement.h"

#include <krakatoa/magma_render_element.hpp>

#include <frantic/max3d/windows.hpp>

#define MaxKrakatoaMagmaRenderElement_CLASS_NAME _T("Krakatoa CustomData OBSOLETE")
#define MaxKrakatoaMagmaRenderElement_CLASS_ID Class_ID( 0x5af166a8, 0x1b6b445c )

class MaxKrakatoaMagmaRenderElement : public MaxKrakatoaRenderElement<MaxKrakatoaMagmaRenderElement> {
  protected:
    ClassDesc2* GetClassDesc();

  public:
    enum {
        kMagmaHolder = kMaxKrakatoaRenderElementLastParamNum,
    };

    static void DefineParamBlock( ParamBlockDesc2* pParamDesc );

    MaxKrakatoaMagmaRenderElement();
    virtual ~MaxKrakatoaMagmaRenderElement();

    // From IKrakatoaRenderElement
    virtual krakatoa::render_element_interface* get_render_element( krakatoa::scene_context_ptr pSceneContext );

    // From ReferenceMaker
    virtual RefResult NotifyRefChanged( const Interval& changeInt, RefTargetHandle hTarget, PartID& partID,
                                        RefMessage message, BOOL propagate );
};

class MaxKrakatoaMagmaRenderElementDesc : public ClassDesc2 {
    ParamBlockDesc2* m_pParamDesc;

  public:
    MaxKrakatoaMagmaRenderElementDesc();
    virtual ~MaxKrakatoaMagmaRenderElementDesc();

    int IsPublic() { return FALSE; }
    void* Create( BOOL ) { return new MaxKrakatoaMagmaRenderElement; }
    const TCHAR* ClassName() { return MaxKrakatoaMagmaRenderElement_CLASS_NAME; }
#if MAX_VERSION_MAJOR >= 24
    const TCHAR* NonLocalizedClassName() { return MaxKrakatoaMagmaRenderElement_CLASS_NAME; }
#endif
    SClass_ID SuperClassID() { return RENDER_ELEMENT_CLASS_ID; }
    Class_ID ClassID() { return MaxKrakatoaMagmaRenderElement_CLASS_ID; }
    const TCHAR* Category() { return _T(""); }

    const TCHAR* InternalName() {
        return MaxKrakatoaMagmaRenderElement_CLASS_NAME;
    }                                           // returns fixed parsable name (scripter-visible name)
    HINSTANCE HInstance() { return hInstance; } // returns owning module handle
};

ClassDesc2* GetMaxKrakatoaMagmaRenderElementDesc() {
    static MaxKrakatoaMagmaRenderElementDesc theMaxKrakatoaMagmaRenderElementDesc;
    return &theMaxKrakatoaMagmaRenderElementDesc;
}

ParamMap2UserDlgProc* GetMaxKrakatoaMagmaRenderElementDlgProc();

MaxKrakatoaMagmaRenderElementDesc::MaxKrakatoaMagmaRenderElementDesc() {
    m_pParamDesc = new ParamBlockDesc2( 0,                                        // Block num
                                        _T("Parameters"),                         // Internal name
                                        NULL,                                     // Localized name
                                        this,                                     // ClassDesc2*
                                        P_AUTO_CONSTRUCT | P_VERSION | P_AUTO_UI, // Flags
                                        0,                                        // Version
                                        0,                                        // PBlock Ref Num
                                        IDD_RENDERELEMENT_MAGMA, IDS_RENDELEM_DATA, 0, 0,
                                        GetMaxKrakatoaMagmaRenderElementDlgProc(), p_end );

    MaxKrakatoaMagmaRenderElement::DefineParamBlock( m_pParamDesc );
}

MaxKrakatoaMagmaRenderElementDesc::~MaxKrakatoaMagmaRenderElementDesc() {}

MaxKrakatoaMagmaRenderElement::MaxKrakatoaMagmaRenderElement() {
    GetMaxKrakatoaMagmaRenderElementDesc()->MakeAutoParamBlocks( this );

    m_pblock->SetValue( kMagmaHolder, 0, CreateKrakatoaMagmaHolder() );
}

MaxKrakatoaMagmaRenderElement::~MaxKrakatoaMagmaRenderElement() {}

ClassDesc2* MaxKrakatoaMagmaRenderElement::GetClassDesc() { return GetMaxKrakatoaMagmaRenderElementDesc(); }

void MaxKrakatoaMagmaRenderElement::DefineParamBlock( ParamBlockDesc2* pParamDesc ) {
    MaxKrakatoaRenderElement<MaxKrakatoaMagmaRenderElement>::DefineParamBlock( pParamDesc );

    pParamDesc->ParamOption( kElementName, p_default, MaxKrakatoaMagmaRenderElement_CLASS_NAME, p_end );

    pParamDesc->AddParam( kMagmaHolder, _T("magmaHolder"), TYPE_REFTARG, P_RESET_DEFAULT | P_SUBANIM, 0, p_end );
}

krakatoa::render_element_interface*
MaxKrakatoaMagmaRenderElement::get_render_element( krakatoa::scene_context_ptr pSceneContext ) {
    bool doAntialias = m_pblock->GetInt( kDoFilter ) != FALSE;
    ReferenceTarget* pMagmaHolder = m_pblock->GetReferenceTarget( kMagmaHolder );

    std::vector<frantic::channels::channel_op_node*> exprTree;
    create_kcm_ast_nodes( exprTree, pSceneContext, NULL, pMagmaHolder );

    std::auto_ptr<krakatoa::magma_render_element> pElement(
        new krakatoa::magma_render_element( doAntialias, exprTree ) );

    pElement->register_commit_callback( boost::bind( &MaxKrakatoaMagmaRenderElement::write_back, this, _1 ) );

    return pElement.release();
}

RefResult MaxKrakatoaMagmaRenderElement::NotifyRefChanged( const Interval& /*changeInt*/, RefTargetHandle hTarget,
                                                           PartID& /*partID*/, RefMessage message,
                                                           BOOL /*propagate*/ ) {
    return REF_SUCCEED;
}

class MaxKrakatoaMagmaRenderElementDlgProc : public ParamMap2UserDlgProc {
  public:
    MaxKrakatoaMagmaRenderElementDlgProc() {}

    virtual ~MaxKrakatoaMagmaRenderElementDlgProc() {}

    virtual INT_PTR DlgProc( TimeValue t, IParamMap2* map, HWND hWnd, UINT msg, WPARAM wParam, LPARAM lParam );

    virtual void DeleteThis() {}
};

ParamMap2UserDlgProc* GetMaxKrakatoaMagmaRenderElementDlgProc() {
    static MaxKrakatoaMagmaRenderElementDlgProc theMaxKrakatoaMagmaRenderElementDlgProc;
    return &theMaxKrakatoaMagmaRenderElementDlgProc;
}

INT_PTR MaxKrakatoaMagmaRenderElementDlgProc::DlgProc( TimeValue /*t*/, IParamMap2* map, HWND /*hWnd*/, UINT msg,
                                                       WPARAM wParam, LPARAM /*lParam*/ ) {
    IParamBlock2* pblock = map->GetParamBlock();
    if( !pblock )
        return FALSE;

    switch( msg ) {
    case WM_COMMAND:
        if( HIWORD( wParam ) == BN_CLICKED ) {
            if( LOWORD( wParam ) == IDC_BUTTON_RENDERELEMENT_MAGMA ) {
                try {
                    frantic::max3d::mxs::expression( _T("::FranticParticleRenderMXS.openMagmaFlowEditor magmaHolder") )
                        .bind( _T("magmaHolder"),
                               pblock->GetReferenceTarget( MaxKrakatoaMagmaRenderElement::kMagmaHolder ) )
                        .evaluate<void>();
                } catch( const std::exception& e ) {
                    // e.sprin1( thread_local(current_stdout) );
                    frantic::max3d::MsgBox( HANDLE_STD_EXCEPTION_MSG( e ), _T("Error openening Magma editor") );
                }

                return TRUE;
            }
        }
        break;
    }

    return FALSE;
}
