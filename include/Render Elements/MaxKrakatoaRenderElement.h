// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0
#pragma once

#include "MaxKrakatoaReferenceTarget.h"
#include "Render Elements\IMaxKrakatoaRenderElement.h"

#include <max.h>

template <class ChildClass>
class MaxKrakatoaRenderElement : public MaxKrakatoaReferenceTarget<IRenderElement, ChildClass>,
                                 public IMaxKrakatoaRenderElement {
  protected:
    enum {
        kEnabled,
        kElementName,
        kBitmap,
        kDoFilter,
        kMaxKrakatoaRenderElementLastParamNum // Must be last element in this enum
    };

    static void DefineParamBlock( ParamBlockDesc2* pParamDesc );

    void write_back( krakatoa::render_element_interface& elem );

  public:
    MaxKrakatoaRenderElement();
    virtual ~MaxKrakatoaRenderElement();

    // From Animatable
    virtual BaseInterface* GetInterface( Interface_ID id );

    // From IRenderElement
    virtual void SetEnabled( BOOL enabled );
    virtual BOOL IsEnabled() const;
    virtual void SetFilterEnabled( BOOL filterEnabled );
    virtual BOOL IsFilterEnabled() const;
    virtual BOOL BlendOnMultipass() const;
    virtual BOOL AtmosphereApplied() const;
    virtual BOOL ShadowsApplied() const;
    virtual void SetElementName( const MCHAR* newName );
    virtual const MCHAR* ElementName() const;
    virtual void SetPBBitmap( PBBitmap*& pPBBitmap ) const;
    virtual void GetPBBitmap( PBBitmap*& pPBBitmap ) const;
    virtual void* GetInterface( ULONG id );
    virtual void ReleaseInterface( ULONG id, void* i );

#if MAX_RELEASE < 12000
    virtual void SetElementName( TCHAR* name ) { SetElementName( (const TCHAR*)name ); }
#endif

    virtual BOOL SetDlgThing( IRenderElementParamDlg* dlg );
    virtual IRenderElementParamDlg* CreateParamDialog( IRendParams* ip );
};

template <class ChildClass>
void MaxKrakatoaRenderElement<ChildClass>::DefineParamBlock( ParamBlockDesc2* pParamDesc ) {
    pParamDesc->AddParam( kEnabled, _T("enabled"), TYPE_BOOL, P_RESET_DEFAULT, 0, p_end );
    pParamDesc->ParamOption( kEnabled, p_default, TRUE, p_end );

    pParamDesc->AddParam( kElementName, _T("elementName"), TYPE_STRING, P_RESET_DEFAULT, 0, p_end );

    pParamDesc->AddParam( kBitmap, _T("bitmap"), TYPE_BITMAP, P_RESET_DEFAULT, 0, p_end );

    pParamDesc->AddParam( kDoFilter, _T("doFilter"), TYPE_BOOL, P_RESET_DEFAULT, 0, p_end );
    pParamDesc->ParamOption( kDoFilter, p_default, TRUE, p_end );
}

template <class ChildClass>
void MaxKrakatoaRenderElement<ChildClass>::write_back( krakatoa::render_element_interface& elem ) {
    PBBitmap* pPBBmp = NULL;
    GetPBBitmap( pPBBmp );

    if( pPBBmp && pPBBmp->bm )
        elem.get_framebuffer().to_3dsMaxBitmap( pPBBmp->bm );
}

template <class ChildClass>
MaxKrakatoaRenderElement<ChildClass>::MaxKrakatoaRenderElement() {}

template <class ChildClass>
MaxKrakatoaRenderElement<ChildClass>::~MaxKrakatoaRenderElement() {}

template <class ChildClass>
BaseInterface* MaxKrakatoaRenderElement<ChildClass>::GetInterface( Interface_ID id ) {
    if( id == IMaxKrakatoaRenderElementID )
        return static_cast<IMaxKrakatoaRenderElement*>( static_cast<ChildClass*>( this ) );
    return IRenderElement::GetInterface( id );
}

template <class ChildClass>
void MaxKrakatoaRenderElement<ChildClass>::SetEnabled( BOOL enabled ) {
    m_pblock->SetValue( kEnabled, 0, enabled );
}

template <class ChildClass>
BOOL MaxKrakatoaRenderElement<ChildClass>::IsEnabled() const {
    return m_pblock->GetInt( kEnabled );
}

template <class ChildClass>
void MaxKrakatoaRenderElement<ChildClass>::SetFilterEnabled( BOOL filterEnabled ) {
    m_pblock->SetValue( kDoFilter, 0, filterEnabled );
}

template <class ChildClass>
BOOL MaxKrakatoaRenderElement<ChildClass>::IsFilterEnabled() const {
    return m_pblock->GetInt( kDoFilter );
}

template <class ChildClass>
BOOL MaxKrakatoaRenderElement<ChildClass>::BlendOnMultipass() const {
    return TRUE;
}

template <class ChildClass>
BOOL MaxKrakatoaRenderElement<ChildClass>::AtmosphereApplied() const {
    return FALSE;
}

template <class ChildClass>
BOOL MaxKrakatoaRenderElement<ChildClass>::ShadowsApplied() const {
    return FALSE;
}

template <class ChildClass>
void MaxKrakatoaRenderElement<ChildClass>::SetElementName( const MCHAR* newName ) {
#if MAX_VERSION_MAJOR >= 12
    m_pblock->SetValue( kElementName, 0, newName );
#else
    m_pblock->SetValue( kElementName, 0, (TCHAR*)newName );
#endif
}

template <class ChildClass>
const MCHAR* MaxKrakatoaRenderElement<ChildClass>::ElementName() const {
    return m_pblock->GetStr( kElementName );
}

template <class ChildClass>
void MaxKrakatoaRenderElement<ChildClass>::SetPBBitmap( PBBitmap*& pPBBitmap ) const {
    m_pblock->SetValue( kBitmap, 0, pPBBitmap );
}

template <class ChildClass>
void MaxKrakatoaRenderElement<ChildClass>::GetPBBitmap( PBBitmap*& pPBBitmap ) const {
    pPBBitmap = m_pblock->GetBitmap( kBitmap );
}

template <class ChildClass>
void* MaxKrakatoaRenderElement<ChildClass>::GetInterface( ULONG id ) {
    return SpecialFX::GetInterface( id );
}

template <class ChildClass>
void MaxKrakatoaRenderElement<ChildClass>::ReleaseInterface( ULONG id, void* i ) {
    SpecialFX::ReleaseInterface( id, i );
}

template <class ChildClass>
BOOL MaxKrakatoaRenderElement<ChildClass>::SetDlgThing( IRenderElementParamDlg* ) {
    return TRUE;
}

template <class ChildClass>
IRenderElementParamDlg* MaxKrakatoaRenderElement<ChildClass>::CreateParamDialog( IRendParams* ip ) {
    return GetClassDesc()->CreateParamDialogs( ip, static_cast<ChildClass*>( this ) );
}
