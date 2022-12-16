// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0
#include "stdafx.h"

#include "resource.h"

#include <boost/smart_ptr.hpp>

#include <frantic/graphics/camera.hpp>
#include <frantic/rendering/deep_attenuation_loaders.hpp>

#include <frantic/max3d/fpwrapper/mixin_wrapper.hpp>
#include <frantic/max3d/standard_max_includes.hpp>

#include "MaxKrakatoaShadowGenerator.h"

#pragma warning( disable : 4100 4239 )

#define IMaxKrakatoaShadowGeneratorMixinID Interface_ID( 0x589a75ef, 0x23521ff8 )

// From MaxKrakatoa.h, but copied to avoid excessive includes.
#define MaxKrakatoa_CLASS_ID Class_ID( 0xb836c39a, 0xe829b319 )

class MaxKrakatoaShadowGenerator : public ShadowType,
                                   public frantic::max3d::fpwrapper::FFMixinInterface<MaxKrakatoaShadowGenerator> {
    IParamBlock2* m_pblock;

  private:
    virtual frantic::tstring GetRealSavePath( INode* pNode );

  public:
    MaxKrakatoaShadowGenerator();
    virtual ~MaxKrakatoaShadowGenerator();

    // From Animatable
    virtual Class_ID ClassID();
    virtual SClass_ID SuperClassID();
#if MAX_VERSION_MAJOR < 24
    virtual void GetClassName( MSTR& s );
#else
    virtual void GetClassName( MSTR& s, bool localized );
#endif

    virtual int NumRefs();
    virtual ReferenceTarget* GetReference( int i );
    virtual void SetReference( int i, ReferenceTarget* r );

    virtual int NumSubs();
    virtual Animatable* SubAnim( int i );
#if MAX_VERSION_MAJOR < 24
    virtual TSTR SubAnimName( int i );
#else
    virtual TSTR SubAnimName( int i, bool localized );
#endif

    virtual int NumParamBlocks();
    virtual IParamBlock2* GetParamBlock( int i );
    virtual IParamBlock2* GetParamBlockByID( BlockID i );

    virtual void BeginEditParams( IObjParam* ip, ULONG flags, Animatable* prev = NULL );
    virtual void EndEditParams( IObjParam* ip, ULONG flags, Animatable* next = NULL );

    virtual void DeleteThis();

    virtual int RenderBegin( TimeValue t, ULONG flags );
    virtual int RenderEnd( TimeValue t );

    virtual BaseInterface* GetInterface( Interface_ID id );

    // From ReferenceMaker
    virtual RefResult NotifyRefChanged( const Interval& changeInt, RefTargetHandle hTarget, PartID& partID,
                                        RefMessage message, BOOL propagate );

#if MAX_VERSION_MAJOR < 17
    virtual RefResult NotifyRefChanged( Interval changeInt, RefTargetHandle hTarget, PartID& partID,
                                        RefMessage message ) {
        return this->NotifyRefChanged( changeInt, hTarget, partID, message, TRUE );
    }
#endif

    // From ReferenceTarget
    virtual ReferenceTarget* Clone( RemapDir& remap );

    // From ShadowType
    virtual BOOL CanDoOmni() { return TRUE; }
    virtual ShadowParamDlg* CreateShadowParamDlg( Interface* ip );
    virtual ShadowGenerator* CreateShadowGenerator( LightObject* l, ObjLightDesc* ld, ULONG flags );

    virtual int GetMapSize( TimeValue t, Interval& valid = Interval( 0, 0 ) );
};

class MaxKrakatoaShadowGeneratorDesc : public ClassDesc2 {
    ParamBlockDesc2* thePBDesc;

  public:
    MaxKrakatoaShadowGeneratorDesc();
    virtual ~MaxKrakatoaShadowGeneratorDesc();

    int IsPublic() { return TRUE; }
    void* Create( BOOL /*loading*/ ) { return new MaxKrakatoaShadowGenerator; }
    const TCHAR* ClassName() { return _T( MaxKrakatoaShadowGenerator_NAME ); }
#if MAX_VERSION_MAJOR >= 24
    const TCHAR* NonLocalizedClassName() { return _T( MaxKrakatoaShadowGenerator_NAME ); }
#endif
    SClass_ID SuperClassID() { return SHADOW_TYPE_CLASS_ID; }
    Class_ID ClassID() { return MaxKrakatoaShadowGenerator_CLASSID; }
    const TCHAR* Category() { return _T("Krakatoa"); }

    // returns fixed parsable name (scripter-visible name)
    const TCHAR* InternalName() { return _T( MaxKrakatoaShadowGenerator_NAME ); }
    HINSTANCE HInstance() { return hInstance; } // returns owning module handle
};

enum {
    kShadowFilename,
    kNumShadowLayers,
    kShadowLayerSeparation,
    kShadowMapSize,
    kDelegateGenerator,
    kShadowSavePath,
    kDelegateOn,
    kShadowFilenameAutoUpdate,
    kShadowManipulatorDistance,
    kShadowExponentialSeparation
};

#define WM_KRAKATOA_SHADOWS_FILENAME_CHANGE ( WM_USER + 0x0001 )
#define WM_KRAKATOA_SHADOWS_DELEGATE_CHANGE ( WM_USER + 0x0002 )
#define WM_KRAKATOA_SHADOWS_UPDATE                                                                                     \
    ( WM_USER + 0x0003 ) // Send when a param changes. WPARAM is the pblock ID, LPARAM is unused.

class MyPBAccessor : public PBAccessor {
    static MyPBAccessor g_theAccessor;

  public:
    static MyPBAccessor* GetInstance() { return &g_theAccessor; }

    virtual void Set( PB2Value& v, ReferenceMaker* owner, ParamID id, int tabIndex, TimeValue t ) {
        IParamBlock2* pblock = static_cast<MaxKrakatoaShadowGenerator*>( owner )->GetParamBlock( 0 );
        if( id == kDelegateGenerator ) {
            IParamMap2* pmap = pblock->GetMap();
            if( pmap )
                SendMessage( pmap->GetHWnd(), WM_KRAKATOA_SHADOWS_UPDATE, (WPARAM)kDelegateGenerator, 0 );
        }
    }

    virtual void DeleteThis() {} // Do Nothing
};

MyPBAccessor MyPBAccessor::g_theAccessor;

MaxKrakatoaShadowGeneratorDesc::MaxKrakatoaShadowGeneratorDesc() {
    thePBDesc = new ParamBlockDesc2( 0,                // Block num
                                     _T("Parameters"), // Internal name
                                     NULL,             // Localized name
                                     this,             // ClassDesc2*
                                     P_AUTO_CONSTRUCT, // Flags
                                     0,                // PBlock Ref Num
                                     p_end );

    thePBDesc->AddParam( kShadowFilename, _T("ShadowFilename"), TYPE_FILENAME, P_RESET_DEFAULT, 0, p_end );
    thePBDesc->ParamOption( kShadowFilename, p_default, _T("") );
    thePBDesc->ParamOption( kShadowFilename, p_ui, TYPE_EDITBOX, IDC_KRAKATOA_SHADOWS_FILELOAD_EDIT, p_end );

    thePBDesc->AddParam( kNumShadowLayers, _T("ShadowSampleCount"), TYPE_INT, P_RESET_DEFAULT, 0, p_end );
    thePBDesc->ParamOption( kNumShadowLayers, p_default, 1 );
    thePBDesc->ParamOption( kNumShadowLayers, p_range, 1, INT_MAX );
    thePBDesc->ParamOption( kNumShadowLayers, p_ui, TYPE_SPINNER, EDITTYPE_POS_INT, IDC_KRAKATOA_SHADOWS_NUMLAYERS_EDIT,
                            IDC_KRAKATOA_SHADOWS_NUMLAYERS_SPIN, 1, p_end );

    thePBDesc->AddParam( kShadowLayerSeparation, _T("ShadowSampleSpacing"), TYPE_WORLD, P_RESET_DEFAULT, 0, p_end );
    thePBDesc->ParamOption( kShadowLayerSeparation, p_default, 1.f );
    thePBDesc->ParamOption( kShadowLayerSeparation, p_range, 0.001f, FLT_MAX );
    thePBDesc->ParamOption( kShadowLayerSeparation, p_ui, TYPE_SPINNER, EDITTYPE_POS_UNIVERSE,
                            IDC_KRAKATOA_SHADOWS_LAYERSEP_EDIT, IDC_KRAKATOA_SHADOWS_LAYERSEP_SPIN, SPIN_AUTOSCALE,
                            p_end );

    thePBDesc->AddParam( kShadowMapSize, _T("MapSize"), TYPE_INT, P_RESET_DEFAULT, 0, p_end );
    thePBDesc->ParamOption( kShadowMapSize, p_default, 512 );
    thePBDesc->ParamOption( kShadowMapSize, p_range, 1, INT_MAX );
    thePBDesc->ParamOption( kShadowMapSize, p_ui, TYPE_SPINNER, EDITTYPE_POS_INT, IDC_KRAKATOA_SHADOWS_MAPSIZE_EDIT,
                            IDC_KRAKATOA_SHADOWS_MAPSIZE_SPIN, 1, p_end );

    thePBDesc->AddParam( kDelegateGenerator, _T("DelegateGenerator"), TYPE_REFTARG, P_RESET_DEFAULT, 0, p_end );
    thePBDesc->ParamOption( kDelegateGenerator, p_default, NULL );
    thePBDesc->ParamOption( kDelegateGenerator, p_accessor, MyPBAccessor::GetInstance() );

    thePBDesc->AddParam( kShadowSavePath, _T("ShadowSavePath"), TYPE_STRING, P_RESET_DEFAULT, 0, p_end );
    thePBDesc->ParamOption( kShadowSavePath, p_default, _T("$renderdir\\Shadows\\$objectname_0000.exr") );
    thePBDesc->ParamOption( kShadowSavePath, p_ui, TYPE_EDITBOX, IDC_KRAKATOA_SHADOWS_FILESAVE_EDIT, p_end );

    thePBDesc->AddParam( kDelegateOn, _T("DelegateOn"), TYPE_BOOL, P_RESET_DEFAULT, 0, p_end );
    thePBDesc->ParamOption( kDelegateOn, p_default, TRUE );
    thePBDesc->ParamOption( kDelegateOn, p_ui, TYPE_SINGLECHEKBOX, IDC_KRAKATOA_SHADOWS_DELEGATE_CHECK, p_end );

    thePBDesc->AddParam( kShadowFilenameAutoUpdate, _T("ShadowFilenameAutoUpdate"), TYPE_BOOL, P_RESET_DEFAULT, 0,
                         p_end );
    thePBDesc->ParamOption( kShadowFilenameAutoUpdate, p_default, TRUE );
    thePBDesc->ParamOption( kShadowFilenameAutoUpdate, p_ui, TYPE_SINGLECHEKBOX, IDC_KRAKATOA_SHADOWS_FILELOAD_CHECK,
                            p_end );

    thePBDesc->AddParam( kShadowManipulatorDistance, _T("ShadowManipulatorDistance"), TYPE_FLOAT,
                         P_RESET_DEFAULT | P_ANIMATABLE | P_INVISIBLE, 0, p_end );
    thePBDesc->ParamOption( kShadowManipulatorDistance, p_default, 40.f );

    thePBDesc->AddParam( kShadowExponentialSeparation, _T("ShadowSampleSpacingIsExponential"), TYPE_BOOL,
                         P_RESET_DEFAULT, 0, p_end );
    thePBDesc->ParamOption( kShadowExponentialSeparation, p_default, TRUE );
    thePBDesc->ParamOption( kShadowExponentialSeparation, p_ui, TYPE_SINGLECHEKBOX,
                            IDC_KRAKATOA_SHADOWS_SPACINGEXP_CHECK, p_end );
}

MaxKrakatoaShadowGeneratorDesc::~MaxKrakatoaShadowGeneratorDesc() {
    delete thePBDesc;
    thePBDesc = NULL;
}

ClassDesc2* GetMaxKrakatoaShadowGeneratorDesc() {
    static MaxKrakatoaShadowGeneratorDesc theDesc;
    return &theDesc;
}

MaxKrakatoaShadowGenerator::MaxKrakatoaShadowGenerator() {
    m_pblock = NULL;

    GetMaxKrakatoaShadowGeneratorDesc()->MakeAutoParamBlocks( this );

    ReferenceTarget* pDelegate = NewDefaultShadowMapType();
    m_pblock->SetValue( kDelegateGenerator, 0, pDelegate );

    FFCreateDescriptor c( this, IMaxKrakatoaShadowGeneratorMixinID, _T("IKrakatoa Shadows"),
                          GetMaxKrakatoaShadowGeneratorDesc() );
    c.add_function( &MaxKrakatoaShadowGenerator::GetRealSavePath, _T("GetExpandedSavePath"), _T("LightNode") );
}

MaxKrakatoaShadowGenerator::~MaxKrakatoaShadowGenerator() {}

#pragma warning( push )
#pragma warning( disable : 4127 )
static bool strmatch( const MCHAR* szLeft, const MCHAR* szRight ) {
    do {
        if( *szLeft == '\0' || *szRight == '\0' )
            return true;
        if( *szLeft != *szRight )
            return false;
        ++szLeft;
        ++szRight;
    } while( 1 );
}
#pragma warning( pop )

// Does macro expansion on the path to create a saving path.
frantic::tstring MaxKrakatoaShadowGenerator::GetRealSavePath( INode* pNode ) {
    Interface* ip = GetCOREInterface();

    const MCHAR* szRenderPath = ip->GetRendFileBI().Name();
    if( !szRenderPath )
        szRenderPath = _T("");

    const MCHAR* szNodeName = pNode->GetName();
    if( !szNodeName )
        szNodeName = _T("");

    std::basic_string<MCHAR> rawPath = m_pblock->GetStr( kShadowSavePath );
    std::basic_stringstream<MCHAR> ss;

    std::basic_string<MCHAR>::size_type prev = 0;
    std::basic_string<MCHAR>::size_type next = rawPath.find( _T( '$' ), prev );
    while( next != std::basic_string<MCHAR>::npos ) {
        if( strmatch( rawPath.c_str() + next, _T("$renderdir") ) ) {
            if( *szRenderPath == '\0' )
                throw std::runtime_error(
                    "MaxKrakatoaShadowGenerator::GetRealSavePath() Unable to substitute render output path in \"" +
                    frantic::strings::to_string( rawPath ) + "\"" );
            ss << rawPath.substr( prev, next - prev ) << frantic::files::directory_from_path( szRenderPath );
            next += sizeof( _T("$renderdir") ) - 1; // Skip the end NULL
        } else if( strmatch( rawPath.c_str() + next, _T("$objectname") ) ) {
            ss << rawPath.substr( prev, next - prev ) << szNodeName;
            next += sizeof( _T("$objectname") ) - 1; // Skip the end NULL
        }
        prev = next;
        next = rawPath.find( _T( '$' ), prev ); // Find the start of the next macro.
    }
    // Add the end part of the path.
    ss << rawPath.c_str() + prev;

    return ss.str();
}

// From Animatable
Class_ID MaxKrakatoaShadowGenerator::ClassID() { return GetMaxKrakatoaShadowGeneratorDesc()->ClassID(); }

SClass_ID MaxKrakatoaShadowGenerator::SuperClassID() { return GetMaxKrakatoaShadowGeneratorDesc()->SuperClassID(); }

#if MAX_VERSION_MAJOR >= 24
void MaxKrakatoaShadowGenerator::GetClassName( MSTR& s, bool localized )
#else
void MaxKrakatoaShadowGenerator::GetClassName( MSTR& s )
#endif
{
    s = GetMaxKrakatoaShadowGeneratorDesc()->ClassName();
}

int MaxKrakatoaShadowGenerator::NumRefs() { return 1; }

ReferenceTarget* MaxKrakatoaShadowGenerator::GetReference( int i ) { return ( i == 0 ) ? m_pblock : NULL; }

void MaxKrakatoaShadowGenerator::SetReference( int i, ReferenceTarget* r ) {
    if( i == 0 )
        m_pblock = (IParamBlock2*)r;
}

int MaxKrakatoaShadowGenerator::NumSubs() { return 1; }

Animatable* MaxKrakatoaShadowGenerator::SubAnim( int i ) { return ( i == 0 ) ? m_pblock : NULL; }

#if MAX_VERSION_MAJOR < 24
TSTR MaxKrakatoaShadowGenerator::SubAnimName( int i )
#else
TSTR MaxKrakatoaShadowGenerator::SubAnimName( int i, bool localized )
#endif
{
    return ( i == 0 ) ? _T("Parameters") : _T("");
}

int MaxKrakatoaShadowGenerator::NumParamBlocks() { return 1; }

IParamBlock2* MaxKrakatoaShadowGenerator::GetParamBlock( int i ) { return ( i == 0 ) ? m_pblock : NULL; }

IParamBlock2* MaxKrakatoaShadowGenerator::GetParamBlockByID( BlockID i ) {
    if( i == m_pblock->ID() )
        return m_pblock;
    else
        return NULL;
}

void MaxKrakatoaShadowGenerator::BeginEditParams( IObjParam* ip, ULONG flags, Animatable* prev ) {
    GetMaxKrakatoaShadowGeneratorDesc()->BeginEditParams( ip, this, flags, prev );
}

void MaxKrakatoaShadowGenerator::EndEditParams( IObjParam* ip, ULONG flags, Animatable* next ) {
    GetMaxKrakatoaShadowGeneratorDesc()->EndEditParams( ip, this, flags, next );
}

void MaxKrakatoaShadowGenerator::DeleteThis() { delete this; }

int MaxKrakatoaShadowGenerator::RenderBegin( TimeValue t, ULONG flags ) { return TRUE; }

int MaxKrakatoaShadowGenerator::RenderEnd( TimeValue t ) { return TRUE; }

BaseInterface* MaxKrakatoaShadowGenerator::GetInterface( Interface_ID id ) {
    if( id == IMaxKrakatoaShadowGeneratorMixinID )
        return static_cast<frantic::max3d::fpwrapper::FFMixinInterface<MaxKrakatoaShadowGenerator>*>( this );
    return ShadowType::GetInterface( id );
}

// From ReferenceMaker
RefResult MaxKrakatoaShadowGenerator::NotifyRefChanged( const Interval& /*changeInt*/, RefTargetHandle hTarget,
                                                        PartID& /*partID*/, RefMessage message, BOOL /*propagate*/ ) {
    if( hTarget == m_pblock ) {
        IParamMap2* pmap = m_pblock->GetMap( 0 );

        int tabIndex = 0;
        int id = m_pblock->LastNotifyParamID( tabIndex );

        switch( id ) {
        case kShadowFilename:
            if( message == REFMSG_CHANGE ) {
                // TODO: Verify this is a valid choice of file sequence.
                if( pmap && !pmap->DlgActive() )
                    pmap->Invalidate( kShadowFilename );
                // SendMessage( pmap->GetHWnd(), WM_KRAKATOA_SHADOWS_UPDATE, (WPARAM)kShadowFilename, 0 );
            }
            break;
        case kShadowSavePath:
            if( message == REFMSG_CHANGE ) {
                if( pmap && !pmap->DlgActive() )
                    pmap->Invalidate( kShadowSavePath );
                // SendMessage( pmap->GetHWnd(), WM_KRAKATOA_SHADOWS_UPDATE, (WPARAM)kShadowSavePath, 0 );
            }
        case kShadowManipulatorDistance:
            return REF_STOP;
        }
    }

    return REF_SUCCEED;
}

// From ReferenceTarget
ReferenceTarget* MaxKrakatoaShadowGenerator::Clone( RemapDir& remap ) {
    MaxKrakatoaShadowGenerator* pResult = new MaxKrakatoaShadowGenerator;
    pResult->ReplaceReference( 0, remap.CloneRef( m_pblock ) );
    BaseClone( this, pResult, remap );
    return pResult;
}

int MaxKrakatoaShadowGenerator::GetMapSize( TimeValue t, Interval& valid ) {
    int result = ShadowType::GetMapSize( t, valid );

    // Set the validity on the mapsize to instant so we get update calls once per frame. We could actually make this
    // cover every tick in the +- half frame interval.
    valid.SetInstant( t );

    return result;
}

class MyShadowParamDlg : public ShadowParamDlg {
    Interface* m_ip;
    IParamMap2* m_pmap;
    IParamBlock2* m_pblock;

    ShadowParamDlg* m_delegateDlg;

  public:
    MyShadowParamDlg( Interface* ip, IParamBlock2* pblock );

    virtual ~MyShadowParamDlg() {
        DestroyCPParamMap2( m_pmap );

        if( m_delegateDlg ) {
            m_delegateDlg->DeleteThis();
            m_delegateDlg = NULL;
        }
    }
    virtual void DeleteThis() { delete this; }

    void update_delegate_shadows() {
        if( m_delegateDlg ) {
            m_delegateDlg->DeleteThis();
            m_delegateDlg = NULL;
        }

        ShadowType* delegateShadows = static_cast<ShadowType*>( m_pblock->GetReferenceTarget( kDelegateGenerator ) );
        if( delegateShadows )
            m_delegateDlg = delegateShadows->CreateShadowParamDlg( m_ip );
    }
};

class MyParamMap2UserDlgProc : public ParamMap2UserDlgProc {
    MyShadowParamDlg* m_pOwner;
    bool m_processingUserInteraction;

  public:
    MyParamMap2UserDlgProc( MyShadowParamDlg* pOwner )
        : m_pOwner( pOwner )
        , m_processingUserInteraction( false ) {}

    virtual ~MyParamMap2UserDlgProc() {}

    void DeleteThis() { delete this; }

    INT_PTR DlgProc( TimeValue t, IParamMap2* map, HWND hWnd, UINT msg, WPARAM wParam, LPARAM lParam ) {
        IParamBlock2* pblock = map->GetParamBlock();
        if( !pblock )
            return FALSE;

        Interface* ip = GetCOREInterface();
        ICustButton* pButton;

        HWND hComboBox;

        switch( msg ) {
        case WM_INITDIALOG:
            pButton = GetICustButton( GetDlgItem( map->GetHWnd(), IDC_KRAKATOA_SHADOWS_FILESAVE_PICK ) );
            pButton->SetText( _T("Pick a save location ...") );
            ReleaseICustButton( pButton );

            pButton = GetICustButton( GetDlgItem( map->GetHWnd(), IDC_KRAKATOA_SHADOWS_FILELOAD_PICK ) );
            pButton->SetText( _T("Pick a load location ...") );
            ReleaseICustButton( pButton );

            hComboBox = GetDlgItem( map->GetHWnd(), IDC_KRAKATOA_SHADOWS_DELEGATE_COMBO );
            {
                // Add each shadow type to the list.
                SubClassList& shadowTypes = *ip->GetDllDir().ClassDir().GetClassList( SHADOW_TYPE_CLASS_ID );
                for( int i = shadowTypes.GetFirst( ACC_PUBLIC ); i != -1; i = shadowTypes.GetNext( ACC_PUBLIC ) ) {
                    ClassEntry& classEntry = shadowTypes[i];
                    if( classEntry.ClassID() == MaxKrakatoaShadowGenerator_CLASSID )
                        continue;
                    ComboBox_AddString( hComboBox, classEntry.ClassName().data() );
                }

                ReferenceTarget* pDelegate = pblock->GetReferenceTarget( kDelegateGenerator );
                if( pDelegate ) {
                    int selClass = shadowTypes.FindClass( pDelegate->ClassID() );
                    if( selClass >= 0 ) {
                        ClassEntry& classEntry = shadowTypes[selClass];
                        ComboBox_SelectString( hComboBox, -1, classEntry.ClassName().data() );
                    }
                } else
                    ComboBox_SetCurSel( hComboBox, -1 );
            }

            return TRUE;
        case WM_KRAKATOA_SHADOWS_UPDATE:
            if( wParam == kShadowFilename ) {
                // pEdit = GetICustEdit( GetDlgItem(map->GetHWnd(), IDC_KRAKATOA_SHADOWS_FILELOAD_EDIT) );
                // pEdit->SetText( pblock->GetStr(kShadowFilename) );
                // ReleaseICustEdit( pEdit );
            } else if( wParam == kShadowSavePath ) {
                // pEdit = GetICustEdit( GetDlgItem(map->GetHWnd(), IDC_KRAKATOA_SHADOWS_FILESAVE_EDIT) );
                // pEdit->SetText( pblock->GetStr(kShadowSavePath) );
                // ReleaseICustEdit( pEdit );
            } else if( wParam == kDelegateGenerator ) {
                if( !m_processingUserInteraction ) {
                    // Set the drop down to the correct value, since its value was changed but not via the UI.
                    ReferenceTarget* pDelegate = pblock->GetReferenceTarget( kDelegateGenerator );

                    MSTR delegateType = _T("");
                    if( pDelegate )
                        pDelegate->GetClassName( delegateType );

                    hComboBox = GetDlgItem( map->GetHWnd(), IDC_KRAKATOA_SHADOWS_DELEGATE_COMBO );

                    int foundIndex = ComboBox_FindStringExact( hComboBox, -1, delegateType.data() );
                    ComboBox_SetCurSel( hComboBox, foundIndex );
                }
                m_pOwner->update_delegate_shadows();
            }
            return TRUE;
        case WM_COMMAND:
            if( HIWORD( wParam ) == CBN_SELCHANGE ) {
                if( LOWORD( wParam ) == IDC_KRAKATOA_SHADOWS_DELEGATE_COMBO ) {
                    int sel = ComboBox_GetCurSel( (HWND)lParam );
                    if( sel != CB_ERR ) {
                        int sz = ComboBox_GetLBTextLen( (HWND)lParam, sel );
                        boost::scoped_array<MCHAR> string( new MCHAR[sz] );

                        ComboBox_GetLBText( (HWND)lParam, sel, string.get() );

                        SubClassList& shadowTypes = *ip->GetDllDir().ClassDir().GetClassList( SHADOW_TYPE_CLASS_ID );
                        int selClass = shadowTypes.FindClass( string.get() );
                        if( selClass >= 0 ) {
                            ClassEntry& classEntry = shadowTypes[selClass];

                            ReferenceTarget* pDelegate =
                                (ReferenceTarget*)CreateInstance( SHADOW_TYPE_CLASS_ID, classEntry.ClassID() );
                            m_processingUserInteraction = true;
                            pblock->SetValue( kDelegateGenerator, 0, pDelegate );
                            m_processingUserInteraction = false;
                        }
                    }
                    return TRUE;
                }
            } else if( HIWORD( wParam ) == BN_CLICKED ) {
                if( LOWORD( wParam ) == IDC_KRAKATOA_SHADOWS_FILESAVE_PICK ) {
                    MSTR result = _T("");
                    MSTR initialDir = pblock->GetStr( kShadowSavePath );

                    FilterList filterList;
                    filterList.Append( _T("OpenEXR Files(*.exr)") );
                    filterList.Append( _T("*.exr") );
                    filterList.Append( _T("All Files(*)") );
                    filterList.Append( _T("*") );

                    if( GetCOREInterface8()->DoMaxSaveAsDialog( hWnd, _T("Pick a location ..."), result, initialDir,
                                                                filterList ) ) {
                        m_processingUserInteraction = true;
                        pblock->SetValue( kShadowSavePath, 0, result.data() );
                        m_processingUserInteraction = false;
                    }

                    return TRUE;
                }
                if( LOWORD( wParam ) == IDC_KRAKATOA_SHADOWS_FILELOAD_PICK ) {
                    MSTR result = _T("");
                    MSTR initialDir = pblock->GetStr( kShadowFilename );

                    FilterList filterList;
                    filterList.Append( _T("OpenEXR Files(*.exr)") );
                    filterList.Append( _T("*.exr") );
                    filterList.Append( _T("All Files(*)") );
                    filterList.Append( _T("*") );

                    if( GetCOREInterface8()->DoMaxOpenDialog( hWnd, _T("Pick An Attenuation Map ..."), result,
                                                              initialDir, filterList ) ) {
                        m_processingUserInteraction = true;
                        pblock->SetValue( kShadowFilename, 0, result.data() );
                        m_processingUserInteraction = false;
                    }

                    return TRUE;
                }
            }
            break;
        }

        return FALSE;
    }
};

MyShadowParamDlg::MyShadowParamDlg( Interface* ip, IParamBlock2* pblock ) {
    m_ip = ip;
    m_pblock = pblock;
    m_delegateDlg = NULL;
    m_pmap = CreateCPParamMap2( 0, pblock, ip, hInstance, MAKEINTRESOURCE( IDD_KRAKATOA_SHADOWS ),
                                _T("Krakatoa Shadows"), 0, new MyParamMap2UserDlgProc( this ) );

    update_delegate_shadows();
}

ShadowParamDlg* MaxKrakatoaShadowGenerator::CreateShadowParamDlg( Interface* ip ) {
    return new MyShadowParamDlg( ip, m_pblock );
}

class KrakatoaShadowGenerator : public ShadowGenerator {
    LightObject* m_pLight;
    ObjLightDesc* m_pLightDesc;

    // Pointer to ShadowType's paramblock that produced this object.
    IParamBlock2* m_pblock;

    frantic::graphics::camera<float> m_lightCam;
    boost::shared_ptr<frantic::rendering::singleface_atten_loader> m_singleFaceAttenMap;

    ShadowGenerator* m_delegate;

  public:
    KrakatoaShadowGenerator( LightObject* pLight, ObjLightDesc* pDesc, IParamBlock2* pblock,
                             ShadowGenerator* pDelegate = NULL ) {
        m_pLight = pLight;
        m_pLightDesc = pDesc;
        m_pblock = pblock;
        m_delegate = pDelegate;
    }

    virtual ~KrakatoaShadowGenerator() {}

    virtual int Update( TimeValue t, const RendContext& rendCntxt, RenderGlobalContext* rgc, Matrix3& lightToWorld,
                        float aspect, float param, float clipDist = DONT_CLIP ) {
        LightState& ls = m_pLightDesc->ls;

        try {
            if( ls.type != SPOT_LGT && ls.type != DIRECT_LGT )
                throw std::runtime_error( "KrakatoaShadowGenerator::Update() - The specified light type was invalid" );

            float fallsizeRads = frantic::math::degrees_to_radians( ls.fallsize );
            float sqrtAspect = sqrt( ls.aspect ); // Used to keep visible area constant over aspect changes.

            if( !rgc || !rgc->renderer || rgc->renderer->ClassID() != MaxKrakatoa_CLASS_ID ) {
                const MCHAR* pszPath = m_pblock->GetStr( kShadowFilename );
                if( !pszPath )
                    pszPath = _T("");

                if( pszPath[0] == _T( '\0' ) )
                    throw std::runtime_error(
                        "KrakatoaShadowGenerator::Update() - The path to your shadow sequence was empty" );

                // int numLayers = m_pblock->GetInt(kNumShadowLayers);
                // if( numLayers < 1 )
                //	numLayers = 1;

                // float layerSpacing = m_pblock->GetFloat(kShadowLayerSeparation);
                // if( layerSpacing < 1e-5f )
                //	layerSpacing = 1e-5f;

                int frame = TimeValue( float( t ) / GetTicksPerFrame() + 0.5f );
                M_STD_STRING curPath = frantic::files::replace_sequence_number( frantic::tstring( pszPath ), frame );

                // load this deep image file
                m_singleFaceAttenMap = frantic::rendering::create_singleface_atten_loader( curPath );

                // set up camera object
                m_lightCam.set_projection_mode( ( ls.type == SPOT_LGT )
                                                    ? frantic::graphics::projection_mode::perspective
                                                    : frantic::graphics::projection_mode::orthographic );
                m_lightCam.set_output_size( m_singleFaceAttenMap->size() );
                m_lightCam.set_pixel_aspect( aspect * m_singleFaceAttenMap->size().ysize /
                                             m_singleFaceAttenMap->size().xsize );
                m_lightCam.set_horizontal_fov(
                    ( ls.shape == RECT_LIGHT ) ? 2.0f * atanf( tanf( fallsizeRads / 2 ) * sqrtAspect ) : fallsizeRads );
                m_lightCam.set_orthographic_width( 2 * ls.fallsize );
                m_lightCam.set_near( 0.001f );
                m_lightCam.set_far( 1e+10f );
                m_lightCam.set_transform( lightToWorld );

            } else {
                m_singleFaceAttenMap.reset();
            }

        } catch( const std::exception& e ) {
            // FF_LOG(error) << e.what();
            // mprintf( "ERR: %s\n", e.what() );
            // return FALSE;
            // FF_LOG(debug) << e.what() << std::endl;

            GetCOREInterface()->Log()->LogEntry( SYSLOG_ERROR, DISPLAY_DIALOG, _T("Krakatoa Shadows Error"),
                                                 _T( "There was an error updating Krakatoa Shadows:\n\n%s" ),
                                                 HANDLE_STD_EXCEPTION_MSG( e ) );

            m_singleFaceAttenMap.reset();
        }

        if( m_delegate )
            return m_delegate->Update( t, rendCntxt, rgc, lightToWorld, aspect, param, clipDist );
        return TRUE;
    }

    virtual int UpdateViewDepParams( const Matrix3& worldToCam ) {
        if( m_delegate )
            return m_delegate->UpdateViewDepParams( worldToCam );
        return TRUE;
    }

    virtual void FreeBuffer() {
        if( m_delegate )
            m_delegate->FreeBuffer();
    }

    virtual void DeleteThis() {
        if( m_delegate )
            m_delegate->DeleteThis();
        delete this;
    }

    virtual float Sample( ShadeContext& sc, Point3& norm, Color& color ) {
        if( !m_singleFaceAttenMap )
            return 1.f;

        bool isValid = true;
        frantic::graphics::vector3f pWorldSpace = frantic::max3d::from_max_t( sc.PointTo( sc.P(), REF_WORLD ) );
        frantic::graphics::vector3f pLightSpace = m_lightCam.world_transform_inverse() * pWorldSpace;
        frantic::graphics2d::vector2f pScreenSpace = m_lightCam.from_cameraspace_position( pLightSpace, isValid );

        if( !isValid )
            return 1.f;

        frantic::graphics::alpha3f a =
            m_singleFaceAttenMap->get_sample_bilinear( pScreenSpace.x, pScreenSpace.y, -pLightSpace.z );

        float result = 1.f - std::min( a.ar, std::min( a.ag, a.ab ) );

        // Max takes the returned transmittance and multiplies it by the "color" of the shadow. We need to divide out
        // the transmittance we are returning in order for this calculation to be correct. If you need to verify, try
        // looking at the Shadows render element with Default Scanline. It will have weird alpha holes if this is done
        // incorrectly, even though the beauty pass looks correct.
        if( result != 0.f )
            color = frantic::max3d::to_max_t( a.occlude( frantic::max3d::from_max_t( color ) ) / result );

        if( m_delegate )
            result *= m_delegate->Sample( sc, norm, color );
        return result;
    }
};

class KrakatoaOmniShadowGenerator : public ShadowGenerator {
    LightObject* m_pLight;
    ObjLightDesc* m_pLightDesc;

    // Pointer to ShadowType's paramblock that produced this object.
    IParamBlock2* m_pblock;

    frantic::graphics::transform4f m_worldToLightTM;
    boost::shared_ptr<frantic::rendering::cubeface_atten_loader> m_cubefaceAttenMap;

    ShadowGenerator* m_delegates[6];

  public:
    KrakatoaOmniShadowGenerator( LightObject* pLight, ObjLightDesc* pDesc, IParamBlock2* pblock,
                                 ShadowGenerator* pDelegates[] ) {
        m_pLight = pLight;
        m_pLightDesc = pDesc;
        m_pblock = pblock;

        // Copy the 6 sub shadow generators
        for( int i = 0; i < 6; ++i )
            m_delegates[i] = pDelegates[i];
    }

    virtual ~KrakatoaOmniShadowGenerator() {}

    virtual int Update( TimeValue t, const RendContext& rendCntxt, RenderGlobalContext* rgc, Matrix3& lightToWorld,
                        float aspect, float param, float clipDist = DONT_CLIP ) {
        LightState& ls = m_pLightDesc->ls;

        try {
            if( ls.type != OMNI_LGT )
                throw std::runtime_error(
                    "KrakatoaOmniShadowGenerator::Update() - The specified light type was invalid" );

            const MCHAR* pszPath = m_pblock->GetStr( kShadowFilename );
            if( !pszPath )
                pszPath = _T("");

            int numLayers = m_pblock->GetInt( kNumShadowLayers );
            if( numLayers < 1 )
                numLayers = 1;

            float layerSpacing = m_pblock->GetFloat( kShadowLayerSeparation );
            if( layerSpacing < 1e-5f )
                layerSpacing = 1e-5f;

            int frame = TimeValue( float( t ) / GetTicksPerFrame() + 0.5f );
            M_STD_STRING curPath = frantic::files::replace_sequence_number( frantic::tstring( pszPath ), frame );

            // load deep attenuation map
            m_cubefaceAttenMap = frantic::rendering::create_cubeface_atten_loader( curPath );
            m_worldToLightTM = frantic::max3d::from_max_t( lightToWorld );
            m_worldToLightTM = m_worldToLightTM.to_inverse();
        } catch( const std::exception& e ) {
            GetCOREInterface()->Log()->LogEntry( SYSLOG_ERROR, DISPLAY_DIALOG, _T("Krakatoa Shadows Error"),
                                                 _T( "There was an error updating Krakatoa Shadows:\n\n%s" ),
                                                 HANDLE_STD_EXCEPTION_MSG( e ) );

            m_cubefaceAttenMap.reset();
            return FALSE;
        }

        if( m_delegates[0] ) {
            if( !m_delegates[1] ) {
                if( !m_delegates[0]->Update( t, rendCntxt, rgc, lightToWorld, aspect, param, clipDist ) )
                    return FALSE;
            } else {
                Matrix3 subGenTM;
                for( int i = 0; i < 6; ++i ) {
                    frantic::graphics::cube_face::default_cube_face face =
                        static_cast<frantic::graphics::cube_face::default_cube_face>( i );
                    subGenTM = frantic::max3d::to_max_t( frantic::max3d::from_max_t( lightToWorld ) *
                                                         frantic::graphics::transform4f::from_cubeface( face ) );
                    if( !m_delegates[i]->Update( t, rendCntxt, rgc, subGenTM, aspect, param, clipDist ) )
                        return FALSE;
                }
            }
        }

        return TRUE;
    }

    virtual int UpdateViewDepParams( const Matrix3& worldToCam ) {
        for( int i = 0; i < 6; ++i ) {
            if( m_delegates[i] )
                m_delegates[i]->UpdateViewDepParams( worldToCam );
        }
        return TRUE;
    }

    virtual void FreeBuffer() {
        for( int i = 0; i < 6; ++i ) {
            if( m_delegates[i] )
                m_delegates[i]->FreeBuffer();
        }
    }

    virtual void DeleteThis() {
        for( int i = 0; i < 6; ++i ) {
            if( m_delegates[i] )
                m_delegates[i]->DeleteThis();
            m_delegates[i] = NULL;
        }
        delete this;
    }

    virtual float Sample( ShadeContext& sc, Point3& norm, Color& color ) {
        if( !m_cubefaceAttenMap )
            return 1.f;

        frantic::graphics::vector3f pWorldSpace = frantic::max3d::from_max_t( sc.PointTo( sc.P(), REF_WORLD ) );
        frantic::graphics::vector3f pLightSpace = m_worldToLightTM * pWorldSpace;
        frantic::graphics::alpha3f a = m_cubefaceAttenMap->get_sample_bilinear( pLightSpace );

        float result = ( 1.f - a.to_float() );

        // Max takes the returned transmittance and multiplies it by the "color" of the shadow. We need to divide out
        // the transmittance we are returning in order for this calculation to be correct. If you need to verify, try
        // looking at the Shadows render element with Default Scanline. It will have weird alpha holes if this is done
        // incorrectly, even though the beauty pass looks correct.
        if( result != 0.f )
            color = frantic::max3d::to_max_t( a.occlude( frantic::max3d::from_max_t( color ) ) / result );

        if( m_delegates[0] ) {
            if( !m_delegates[1] ) {
                result *= m_delegates[0]->Sample( sc, norm, color );
            } else {
                // TODO: Should I average or something when close to the border? What is there now is what the Max Omni
                // light does by default.
                result *= m_delegates[frantic::graphics::get_cube_face( pLightSpace )]->Sample( sc, norm, color );
            }
        }

        return result;
    }
};

ShadowGenerator* MaxKrakatoaShadowGenerator::CreateShadowGenerator( LightObject* l, ObjLightDesc* ld, ULONG flags ) {
    ShadowType* pDelegateType = NULL;
    if( m_pblock->GetInt( kDelegateOn ) )
        pDelegateType = (ShadowType*)m_pblock->GetReferenceTarget( kDelegateGenerator );

    ShadowGenerator* ppDelegates[] = { NULL, NULL, NULL, NULL, NULL, NULL };
    if( pDelegateType ) {
        if( pDelegateType->CanDoOmni() && ( flags & SHAD_OMNI ) ) {
            ppDelegates[0] = pDelegateType->CreateShadowGenerator( l, ld, flags );
        } else {
            for( int i = 0; i < 6; ++i )
                ppDelegates[i] = pDelegateType->CreateShadowGenerator( l, ld, flags & ~SHAD_OMNI );
        }
    }

    if( ( flags & SHAD_OMNI ) )
        return new KrakatoaOmniShadowGenerator( l, ld, m_pblock, ppDelegates );
    else
        return new KrakatoaShadowGenerator( l, ld, m_pblock, ppDelegates[0] );
}