// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0
#include "stdafx.h"

#include "resource.h"

#include "Render Elements\MaxKrakatoaRenderElement.h"

#include <krakatoa/light_render_element.hpp>

#define MaxKrakatoaLightRenderElement_CLASS_NAME _T("Krakatoa SpecificLight")
#define MaxKrakatoaLightRenderElement_CLASS_ID Class_ID( 0x652a4627, 0x155a54b1 )

class MaxKrakatoaLightRenderElement : public MaxKrakatoaRenderElement<MaxKrakatoaLightRenderElement> {
    enum { kLightNode = kMaxKrakatoaRenderElementLastParamNum };

    static int s_instanceCount;

  protected:
    ClassDesc2* GetClassDesc();

  public:
    static void DefineParamBlock( ParamBlockDesc2* pParamDesc );

    MaxKrakatoaLightRenderElement();
    virtual ~MaxKrakatoaLightRenderElement();

    // From IKrakatoaRenderElement
    virtual krakatoa::render_element_interface* get_render_element( krakatoa::scene_context_ptr pSceneContext );

    // From ReferenceMaker
    virtual RefResult NotifyRefChanged( const Interval& changeInt, RefTargetHandle hTarget, PartID& partID,
                                        RefMessage message, BOOL propagate );
};

int MaxKrakatoaLightRenderElement::s_instanceCount = 0;

class MaxKrakatoaLightRenderElementDesc : public ClassDesc2 {
    ParamBlockDesc2* m_pParamDesc;

  public:
    MaxKrakatoaLightRenderElementDesc();
    virtual ~MaxKrakatoaLightRenderElementDesc();

    int IsPublic() { return TRUE; }
    void* Create( BOOL ) { return new MaxKrakatoaLightRenderElement; }
    const TCHAR* ClassName() { return MaxKrakatoaLightRenderElement_CLASS_NAME; }
#if MAX_VERSION_MAJOR >= 24
    const TCHAR* NonLocalizedClassName() { return MaxKrakatoaLightRenderElement_CLASS_NAME; }
#endif
    SClass_ID SuperClassID() { return RENDER_ELEMENT_CLASS_ID; }
    Class_ID ClassID() { return MaxKrakatoaLightRenderElement_CLASS_ID; }
    const TCHAR* Category() { return _T(""); }

    const TCHAR* InternalName() {
        return MaxKrakatoaLightRenderElement_CLASS_NAME;
    }                                           // returns fixed parsable name (scripter-visible name)
    HINSTANCE HInstance() { return hInstance; } // returns owning module handle
};

ClassDesc2* GetMaxKrakatoaLightRenderElementDesc() {
    static MaxKrakatoaLightRenderElementDesc theMaxKrakatoaLightRenderElementDesc;
    return &theMaxKrakatoaLightRenderElementDesc;
}

ParamMap2UserDlgProc* GetMaxKrakatoaLightRenderElementDlgProc();

MaxKrakatoaLightRenderElementDesc::MaxKrakatoaLightRenderElementDesc() {
    m_pParamDesc = new ParamBlockDesc2( 0,                                        // Block num
                                        _T("Parameters"),                         // Internal name
                                        NULL,                                     // Localized name
                                        this,                                     // ClassDesc2*
                                        P_AUTO_CONSTRUCT | P_VERSION | P_AUTO_UI, // Flags
                                        0,                                        // Version
                                        0,                                        // PBlock Ref Num
                                        IDD_RENDERELEMENT_LIGHT, IDS_PARAMETERS, 0, 0,
                                        GetMaxKrakatoaLightRenderElementDlgProc(), p_end );

    MaxKrakatoaLightRenderElement::DefineParamBlock( m_pParamDesc );
}

MaxKrakatoaLightRenderElementDesc::~MaxKrakatoaLightRenderElementDesc() {}

MaxKrakatoaLightRenderElement::MaxKrakatoaLightRenderElement() {
    GetMaxKrakatoaLightRenderElementDesc()->MakeAutoParamBlocks( this );

    // std::string newName = std::string( ElementName() ) + ( ++s_instanceCount <= 9 ? frantic::strings::zero_pad(
    // s_instanceCount, 2 ) : boost::lexical_cast<std::string>(s_instanceCount) );

    // SetElementName( newName.c_str() );
}

MaxKrakatoaLightRenderElement::~MaxKrakatoaLightRenderElement() {}

ClassDesc2* MaxKrakatoaLightRenderElement::GetClassDesc() { return GetMaxKrakatoaLightRenderElementDesc(); }

void MaxKrakatoaLightRenderElement::DefineParamBlock( ParamBlockDesc2* pParamDesc ) {
    MaxKrakatoaRenderElement<MaxKrakatoaLightRenderElement>::DefineParamBlock( pParamDesc );

    pParamDesc->ParamOption( kElementName, p_default, MaxKrakatoaLightRenderElement_CLASS_NAME, p_end );

    pParamDesc->AddParam( kLightNode, _T("lightNode"), TYPE_INODE, 0, 0, p_end );
    pParamDesc->ParamOption( kLightNode, p_sclassID, LIGHT_CLASS_ID );
    pParamDesc->ParamOption( kLightNode, p_prompt, IDS_RENDERELEMENT_LIGHT_PROMPT );
    pParamDesc->ParamOption( kLightNode, p_ui, TYPE_PICKNODEBUTTON, IDC_PICK_RENDERELEMENT_LIGHT );
}

krakatoa::render_element_interface* MaxKrakatoaLightRenderElement::get_render_element( krakatoa::scene_context_ptr ) {
    INode* pLightNode = m_pblock->GetINode( kLightNode );
    if( !pLightNode )
        return NULL;

    frantic::tstring lightName = pLightNode->GetName();
    frantic::tstring internalName =
        lightName + _T("_") + boost::lexical_cast<frantic::tstring>( pLightNode->GetHandle() );

    std::auto_ptr<krakatoa::light_render_element> pElement(
        new krakatoa::light_render_element( lightName, internalName ) );

    pElement->register_commit_callback( boost::bind( &MaxKrakatoaLightRenderElement::write_back, this, _1 ) );

    return pElement.release();
}

RefResult MaxKrakatoaLightRenderElement::NotifyRefChanged( const Interval& /*changeInt*/, RefTargetHandle hTarget,
                                                           PartID& /*partID*/, RefMessage message,
                                                           BOOL /*propagate*/ ) {
    return REF_SUCCEED;
}

class MaxKrakatoaLightRenderElementDlgProc : public ParamMap2UserDlgProc {
  public:
    MaxKrakatoaLightRenderElementDlgProc() {}

    virtual ~MaxKrakatoaLightRenderElementDlgProc() {}

    virtual INT_PTR DlgProc( TimeValue t, IParamMap2* map, HWND hWnd, UINT msg, WPARAM wParam, LPARAM lParam );

    virtual void DeleteThis() {}
};

ParamMap2UserDlgProc* GetMaxKrakatoaLightRenderElementDlgProc() {
    static MaxKrakatoaLightRenderElementDlgProc theMaxKrakatoaLightRenderElementDlgProc;
    return &theMaxKrakatoaLightRenderElementDlgProc;
}

INT_PTR MaxKrakatoaLightRenderElementDlgProc::DlgProc( TimeValue /*t*/, IParamMap2* map, HWND hWnd, UINT msg,
                                                       WPARAM wParam, LPARAM lParam ) {
    switch( msg ) {
    case WM_INITDIALOG:
        return TRUE;
    case WM_COMMAND: {
        HWND rcvHandle = (HWND)lParam;
        WORD msg = HIWORD( wParam );
        if( rcvHandle == GetDlgItem( hWnd, IDC_BUTTON_RENDERELEMENT_LIGHT_CONTEXT ) ) {
            if( msg == BN_CLICKED ) {
                IParamBlock2* pblock = map->GetParamBlock();
                if( pblock ) {
                    frantic::max3d::mxs::expression(
                        _T("FranticParticleRenderMXS.OpenSpecificLightRenderElementOptionsRCMenu self") )
                        .bind( _T("self"), (ReferenceTarget*)pblock->GetOwner() )
                        .evaluate<void>();
                }
                return TRUE;
            }
        }
    } break;
    case WM_CONTEXTMENU: {
        HWND rcvHandle = (HWND)wParam;
        if( rcvHandle == GetDlgItem( hWnd, IDC_PICK_RENDERELEMENT_LIGHT ) ) {
            IParamBlock2* pblock = map->GetParamBlock();
            if( pblock ) {
                frantic::max3d::mxs::expression(
                    _T("FranticParticleRenderMXS.OpenSpecificLightRenderElementOptionsRCMenu self") )
                    .bind( _T("self"), (ReferenceTarget*)pblock->GetOwner() )
                    .evaluate<void>();
            }
            return TRUE;
        }
    } break;
    }
    return FALSE;
}
