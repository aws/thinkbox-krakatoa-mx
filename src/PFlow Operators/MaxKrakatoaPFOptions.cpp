// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0
#include "stdafx.h"

#include "resource.h"

#include "PFlow Operators\MaxKrakatoaPFOptions.h"

static FPInterfaceDesc theIKrakatoaPFOptionsDesc( KRAKATOA_PFOPTIONS_INTERFACE, _T("IKrakatoaPFRenderOp"), 0,
                                                  GetKrakatoaPFOptionsDesc(), FP_MIXIN,

                                                  kEnableScriptedDensity, _T("IsScriptedDensityEnabled"), 0, TYPE_BOOL,
                                                  0, 0, kEnableScriptedColor, _T("IsScriptedColorEnabled"), 0,
                                                  TYPE_BOOL, 0, 0, p_end );

FPInterfaceDesc* IKrakatoaPFOptions::GetDesc() { return &theIKrakatoaPFOptionsDesc; }

extern HINSTANCE hInstance;
class KrakatoaPFOptionsDesc : public ClassDesc2 {
  public:
    BOOL IsPublic() { return FALSE; }
    void* Create( BOOL ) { return new KrakatoaPFOptions; }
    const TCHAR* ClassName() { return _T("Krakatoa Options "); }
#if MAX_VERSION_MAJOR >= 24
    const TCHAR* NonLocalizedClassName() { return _T("Krakatoa Options "); }
#endif
    SClass_ID SuperClassID() { return HELPER_CLASS_ID; }
    Class_ID ClassID() { return KRAKATOA_PFOPTIONS_CLASSID; }
    Class_ID SubClassID() { return PFOperatorSubClassID; }
    const TCHAR* Category() { return _T("Particle Flow"); }

    const TCHAR* InternalName() { return _T("KrakatoaOptions"); }
    HINSTANCE HInstance() { return hInstance; }

    INT_PTR Execute( int cmd, ULONG_PTR arg1, ULONG_PTR arg2, ULONG_PTR arg3 );
    ~KrakatoaPFOptionsDesc() {
        if( m_depotIcon )
            DeleteObject( m_depotIcon );
        if( m_depotMask )
            DeleteObject( m_depotMask );
    }

    static HBITMAP m_depotIcon;
    static HBITMAP m_depotMask;
};

HBITMAP KrakatoaPFOptionsDesc::m_depotIcon = NULL;
HBITMAP KrakatoaPFOptionsDesc::m_depotMask = NULL;

ClassDesc2* GetKrakatoaPFOptionsDesc() {
    static KrakatoaPFOptionsDesc theDesc;
    return &theDesc;
}

INT_PTR KrakatoaPFOptionsDesc::Execute( int cmd, ULONG_PTR arg1, ULONG_PTR arg2, ULONG_PTR /*arg3*/ ) {
    TCHAR** res = NULL;
    bool* isPublic;
    bool* isNonExecute;
    HBITMAP* depotIcon;
    HBITMAP* depotMask;
    switch( cmd ) {
    case kPF_GetActionDescription:
        if( arg1 == NULL )
            return 0;
        res = (TCHAR**)arg1;
        *res = _T("Can set the color and density of particles from scripted channels");
        break;
    case kPF_PViewPublic:
        if( arg1 == NULL )
            return 0;
        isPublic = (bool*)arg1;
        *isPublic = true;
        break;
    case kPF_IsNonExecutable:
        if( arg1 == NULL )
            return 0;
        isNonExecute = (bool*)arg1;
        *isNonExecute = true;
        break;
    case kPF_PViewCategory:
        if( arg1 == NULL )
            return 0;
        res = (TCHAR**)arg1;
        *res = _T("Operator"); // Important: This makes the op show up in the correct category of the right click menu
        break;
    case kPF_PViewDepotIcon:
        if( arg1 == NULL )
            return 0;
        depotIcon = (HBITMAP*)arg1;
        if( arg2 == NULL )
            return 0;
        depotMask = (HBITMAP*)arg2;
        if( m_depotIcon == NULL )
            m_depotIcon = LoadBitmap( hInstance, MAKEINTRESOURCE( IDB_KRAKATOAOPTIONS_DEPOT ) );
        if( m_depotMask == NULL )
            m_depotMask = LoadBitmap( hInstance, MAKEINTRESOURCE( IDB_KRAKATOAOPTIONS_MASK_DEPOT ) );
        *depotIcon = m_depotIcon;
        *depotMask = m_depotMask;
        break;
    default:
        return 0;
    }
    return 1;
}

static ParamBlockDesc2 pbDesc( 0, _T("Parameters"), NULL, GetKrakatoaPFOptionsDesc(), P_AUTO_CONSTRUCT | P_AUTO_UI, 0,
                               IDD_KRAKATOA_PFOPTIONS, 0 /*IDS_PARAMETERS*/, 0, 0, NULL, kEnableScriptedDensity,
                               _T("EnableScriptedDensity"), TYPE_BOOL, 0, 0, p_default, FALSE, p_ui, TYPE_SINGLECHEKBOX,
                               IDC_KRAKATOA_PFRENDEROP_DENSITY, p_end, kEnableScriptedColor, _T("EnableScriptedColor"),
                               TYPE_BOOL, 0, 0, p_default, FALSE, p_ui, TYPE_SINGLECHEKBOX,
                               IDC_KRAKATOA_PFRENDEROP_COLOR, p_end, p_end );

KrakatoaPFOptions::KrakatoaPFOptions() {
    SetReference( 0, NULL );
    GetKrakatoaPFOptionsDesc()->MakeAutoParamBlocks( this );
}

BaseInterface* KrakatoaPFOptions::GetInterface( Interface_ID id ) {
    if( id == KRAKATOA_PFOPTIONS_INTERFACE )
        return static_cast<IKrakatoaPFOptions*>( this );
    return PFSimpleOperator::GetInterface( id );
}

#if MAX_VERSION_MAJOR < 24
void KrakatoaPFOptions::GetClassName( TSTR& s ) {
#else
void KrakatoaPFOptions::GetClassName( TSTR& s, bool localized ) {
#endif
    s = GetKrakatoaPFOptionsDesc()->ClassName();
}

Class_ID KrakatoaPFOptions::ClassID() { return GetKrakatoaPFOptionsDesc()->ClassID(); }

ClassDesc* KrakatoaPFOptions::GetClassDesc() const { return GetKrakatoaPFOptionsDesc(); }

void KrakatoaPFOptions::BeginEditParams( IObjParam* ip, ULONG flags, Animatable* prev ) {
    GetKrakatoaPFOptionsDesc()->BeginEditParams( ip, this, flags, prev );
}

void KrakatoaPFOptions::EndEditParams( IObjParam* ip, ULONG flags, Animatable* next ) {
    GetKrakatoaPFOptionsDesc()->EndEditParams( ip, this, flags, next );
}

const ParticleChannelMask& KrakatoaPFOptions::ChannelsUsed( const Interval& /* time*/ ) const { return m_usedChannels; }

const Interval KrakatoaPFOptions::ActivityInterval() const { return FOREVER; }

#if MAX_VERSION_MAJOR >= 24
const TCHAR* KrakatoaPFOptions::GetObjectName( bool localized ) const {
#elif MAX_VERSION_MAJOR >= 15
const TCHAR* KrakatoaPFOptions::GetObjectName() {
#else
TCHAR* KrakatoaPFOptions::GetObjectName() {
#endif
    return const_cast<TCHAR*>( GetKrakatoaPFOptionsDesc()->ClassName() );
}

RefTargetHandle KrakatoaPFOptions::Clone( RemapDir& remap ) {
    KrakatoaPFOptions* newOp = new KrakatoaPFOptions;
    newOp->SetReference( 0, remap.CloneRef( pblock() ) );
    BaseClone( this, newOp, remap );
    return newOp;
}

HBITMAP KrakatoaPFOptions::GetActivePViewIcon() {
    if( activeIcon() == NULL )
        _activeIcon() = (HBITMAP)LoadImage( hInstance, MAKEINTRESOURCE( IDB_KRAKATOAOPTIONS_ACTIVE ), IMAGE_BITMAP,
                                            kActionImageWidth, kActionImageHeight, LR_SHARED );
    return activeIcon();
}

HBITMAP KrakatoaPFOptions::GetInactivePViewIcon() {
    if( inactiveIcon() == NULL )
        _inactiveIcon() = (HBITMAP)LoadImage( hInstance, MAKEINTRESOURCE( IDB_KRAKATOAOPTIONS_INACTIVE ), IMAGE_BITMAP,
                                              kActionImageWidth, kActionImageHeight, LR_SHARED );
    return inactiveIcon();
}

bool KrakatoaPFOptions::Proceed( IObject*, PreciseTimeValue, PreciseTimeValue&, Object*, INode*, INode*,
                                 IPFIntegrator* ) {
    return true;
}
