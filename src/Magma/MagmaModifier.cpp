// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0
#include "stdafx.h"

#include "resource.h"

#include "MaxKrakatoaMagmaHolder.h"
#include "magma\IMagmaModifierImpl.hpp"
#include "magma\MagmaMaxContext.hpp"
#include "objects\MaxKrakatoaPRTInterface.h"

#include <frantic/magma/max3d/DebugInformation.hpp>

#include <frantic/magma/magma_exception.hpp>
#include <frantic/magma/simple_compiler/magma_particle_istream.hpp>
#include <frantic/magma/simple_compiler/simple_particle_compiler.hpp>

typedef boost::shared_ptr<frantic::particles::streams::particle_istream> particle_istream_ptr;

#define REFMSG_MODIFIER_CHANGED ( REFMSG_USER + 0x3561 )

class MagmaModifier : public IMagmaModifierImpl<OSModifier, MagmaModifier> {
  public:
    static MSTR s_ClassName;
    static Class_ID s_ClassID;
    static const SClass_ID s_SuperClassID = OSM_CLASS_ID;

  private:
    class MyClassDesc : public ClassDesc2 {
        ParamBlockDesc2 m_paramDesc;
        FPInterfaceDesc m_magmaModifierDesc;

        friend class MagmaModifier;

      public:
        MyClassDesc();

        int IsPublic() { return TRUE; }
        void* Create( BOOL loading ) { return new MagmaModifier( loading ); }
        const TCHAR* ClassName() { return s_ClassName; }
#if MAX_VERSION_MAJOR >= 24
        const TCHAR* NonLocalizedClassName() { return s_ClassName; }
#endif
        SClass_ID SuperClassID() { return s_SuperClassID; }
        Class_ID ClassID() { return s_ClassID; }
        const TCHAR* Category() { return _T(""); }

        const TCHAR* InternalName() { return s_ClassName; } // returns fixed parsable name (scripter-visible name)
        HINSTANCE HInstance() { return hInstance; }
    };

    static MyClassDesc s_ClassDesc;

    friend ClassDesc2* GetMagmaModifierDesc();

  protected:
    virtual ClassDesc2* GetClassDesc() { return &s_ClassDesc; }

  public:
    MagmaModifier( BOOL loading = FALSE );
    ~MagmaModifier();

    virtual FPInterfaceDesc* GetDescByID( Interface_ID id );
};

MSTR MagmaModifier::s_ClassName( _T("MagmaModifier") );

Class_ID MagmaModifier::s_ClassID( 0x5761505e, 0x5938522d );

MagmaModifier::MyClassDesc MagmaModifier::s_ClassDesc;

class MagmaModifierDlgProc : public ParamMap2UserDlgProc {
  public:
    static MagmaModifierDlgProc* GetInstance() {
        static MagmaModifierDlgProc s_instance;
        return &s_instance;
    }

    virtual INT_PTR DlgProc( TimeValue /*t*/, IParamMap2* map, HWND hWnd, UINT msg, WPARAM wParam, LPARAM /*lParam*/ ) {
        IParamBlock2* pblock = map->GetParamBlock();
        if( !pblock )
            return FALSE;

        BOOL checkedVal = TRUE;

        switch( msg ) {
        case WM_INITDIALOG:
            if( ReferenceTarget* rtarg = pblock->GetReferenceTarget( MagmaModifier::kMagmaHolderRef ) )
                checkedVal = rtarg->GetParamBlock( 0 )->GetInt( KrakatoaMagmaHolderParams::kMagmaAutomaticRenameOFF );
            CheckDlgButton( hWnd, IDC_MAGMAMODIFIER_AUTORENAME_CHECK, !checkedVal ? BST_CHECKED : BST_UNCHECKED );
            break;
        case WM_COMMAND:
            if( HIWORD( wParam ) == BN_CLICKED ) {
                if( LOWORD( wParam ) == IDC_MAGMAMODIFIER_OPEN_BUTTON ) {
                    try {
                        frantic::max3d::mxs::expression(
                            _T("try(::MagmaFlowEditor_Functions.OpenMagmaFlowEditor magmaHolder)catch()") )
                            .bind( _T("magmaHolder"), pblock->GetReferenceTarget( MagmaModifier::kMagmaHolderRef ) )
                            .evaluate<void>();
                    } catch( const std::exception& e ) {
                        FF_LOG( error ) << e.what() << std::endl;
                    } catch( ... ) {
                        // Can't allow max to crash by propogating any exceptions.
                        FF_LOG( error ) << _T("Unhandled exception in: ") << __FILE__ << _T(" line: ") << __LINE__
                                        << std::endl;
                    }

                    return TRUE;
                } else if( LOWORD( wParam ) == IDC_MAGMAMODIFIER_AUTORENAME_CHECK ) {
                    checkedVal = ( IsDlgButtonChecked( hWnd, IDC_MAGMAMODIFIER_AUTORENAME_CHECK ) == BST_CHECKED );
                    if( ReferenceTarget* rtarg = pblock->GetReferenceTarget( MagmaModifier::kMagmaHolderRef ) )
                        rtarg->GetParamBlock( 0 )->SetValue( KrakatoaMagmaHolderParams::kMagmaAutomaticRenameOFF, 0,
                                                             !checkedVal );
                }
            }
            break;
        }

        return FALSE;
    }

    virtual void DeleteThis() {}
};

MagmaModifier::MyClassDesc::MyClassDesc()
    : m_paramDesc( (BlockID)0, _T("Parameters"), IDS_PARAMETERS, NULL, P_AUTO_CONSTRUCT | P_VERSION | P_AUTO_UI, 0, 0,
                   IDD_MAGMAMODIFIER, IDS_MAGMAMODIFIER_TITLE, 0, 0, MagmaModifierDlgProc::GetInstance(), p_end )
    , m_magmaModifierDesc( MagmaModifier_INTERFACE, _T("MagmaModifier"), 0, NULL, FP_MIXIN, p_end ) {
    m_paramDesc.SetClassDesc( this );
    m_paramDesc.AddParam( kMagmaHolderRef, _T("magmaHolder"), TYPE_REFTARG, P_SUBANIM, IDS_MAGMA_HOLDER, p_end );
    m_paramDesc.ParamOption( kMagmaHolderRef, p_classID, KrakatoaMagmaHolder_CLASS_ID, p_end );

    m_magmaModifierDesc.SetClassDesc( this );
    IMagmaModifier::init_fpinterface_desc( m_magmaModifierDesc );
}

ClassDesc2* GetMagmaModifierDesc() { return &MagmaModifier::s_ClassDesc; }

MagmaModifier::MagmaModifier( BOOL loading ) {
    if( !loading ) {
        s_ClassDesc.MakeAutoParamBlocks( this );
        m_pblock->SetValue( kMagmaHolderRef, 0, CreateKrakatoaMagmaHolder() );
    }
}

MagmaModifier::~MagmaModifier() {}

FPInterfaceDesc* MagmaModifier::GetDescByID( Interface_ID id ) {
    if( id == MagmaModifier_INTERFACE )
        return &MagmaModifier::s_ClassDesc.m_magmaModifierDesc;
    return IMagmaModifier::GetDescByID( id );
}
