// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0
#include "stdafx.h"

#include "resource.h"

#include "MaxKrakatoaReferenceTarget.h"
#include "Objects\MaxKrakatoaPRTInterface.h"

#include <krakatoa/max3d/IPRTModifier.hpp>

#define MaxKrakatoaPRTSpaceDeleteMod_NAME _T( "KrakatoaDeleteWSM" )
#define MaxKrakatoaPRTSpaceDeleteModObject_CLASSID Class_ID( 0x13b4570d, 0x4c44758b )
#define MaxKrakatoaPRTSpaceDeleteMod_VERSION 1

extern HINSTANCE hInstance;

enum { kMainPanel };

enum { kSelectionMode, kResetSelection, kWarnIfMissingID };

enum { kSelectionSelection, kSelectionSoftSelection };

ClassDesc2* GetMaxKrakatoaPRTSpaceDeleteDesc();

class MaxKrakatoaPRTSpaceDeleteMod : public MaxKrakatoaReferenceTarget<WSModifier, MaxKrakatoaPRTSpaceDeleteMod> {
  protected:
    virtual ClassDesc2* GetClassDesc() { return GetMaxKrakatoaPRTSpaceDeleteDesc(); }

  public:
    MaxKrakatoaPRTSpaceDeleteMod() { GetClassDesc()->MakeAutoParamBlocks( this ); }

    virtual RefResult NotifyRefChanged( const Interval& changeInt, RefTargetHandle hTarget, PartID& partID,
                                        RefMessage message, BOOL /*propagate*/ ) {
        if( hTarget == m_pblock && message == REFMSG_CHANGE ) {
            int index = -1;
            ParamID paramID = m_pblock->LastNotifyParamID( index );

            RefResult result = REF_STOP;

            if( paramID == kSelectionMode ) {
                m_pblock->SetValue( kWarnIfMissingID, 0, TRUE );
                result = REF_SUCCEED;
            }

            return result;
        }
        return REF_DONTCARE;
    }

#if MAX_VERSION_MAJOR >= 24
    virtual const TCHAR* GetObjectName( bool localized )
#elif MAX_VERSION_MAJOR >= 15
    virtual const TCHAR* GetObjectName()
#else
    virtual TCHAR* GetObjectName()
#endif
    {
        return _T( "Krakatoa Delete" );
    }

    virtual CreateMouseCallBack* GetCreateMouseCallBack() { return NULL; }

    // From Modifier
    virtual Interval LocalValidity( TimeValue t ) {
        Interval iv = FOREVER;

        m_pblock->GetValidity( t, iv );

        if( !iv.InInterval( t ) )
            iv.SetInstant( t );

        return iv;
    }

    virtual ChannelMask ChannelsUsed() { return GEOM_CHANNEL; }

    virtual ChannelMask ChannelsChanged() { return 0; }

    virtual void ModifyObject( TimeValue /*t*/, ModContext& /*mc*/, ObjectState* /*os*/, INode* /*node*/ ) {}

    virtual Class_ID InputType() { return MaxKrakatoaPRTSourceObject_CLASSID; }
};

class MaxKrakatoaPRTSpaceDeleteModDesc : public ClassDesc2 {
    ParamBlockDesc2 m_paramDesc;

  public:
    MaxKrakatoaPRTSpaceDeleteModDesc();

    virtual ~MaxKrakatoaPRTSpaceDeleteModDesc() {}

    int IsPublic() { return TRUE; }
    virtual void* Create( BOOL /*loading*/ ) { return new MaxKrakatoaPRTSpaceDeleteMod; }
    virtual const TCHAR* ClassName() { return _T( "Krakatoa Delete" ); }
#if MAX_VERSION_MAJOR >= 24
    virtual const TCHAR* NonLocalizedClassName() { return _T( "Krakatoa Delete" ); }
#endif
    virtual SClass_ID SuperClassID() { return WSM_CLASS_ID; }
    virtual Class_ID ClassID() { return MaxKrakatoaPRTSpaceDeleteModObject_CLASSID; }
    const TCHAR* Category() { return _T( "" ); }

    // returns fixed parsable name (scripter-visible name)
    virtual const TCHAR* InternalName() { return _T( "KrakatoaDeleteWSM" ); }
    HINSTANCE HInstance() { return hInstance; } // returns owning module handle
};

ClassDesc2* GetMaxKrakatoaPRTSpaceDeleteDesc() {
    static MaxKrakatoaPRTSpaceDeleteModDesc theDesc;
    return &theDesc;
}

MaxKrakatoaPRTSpaceDeleteModDesc::MaxKrakatoaPRTSpaceDeleteModDesc()
    : m_paramDesc( 0,                                                     // Block num
                   _T( "Krakatoa Delete" ),                               // Internal name
                   NULL,                                                  // Localized name
                   NULL,                                                  // ClassDesc2*
                   P_AUTO_CONSTRUCT + P_AUTO_UI + P_MULTIMAP + P_VERSION, // Flags
                   MaxKrakatoaPRTSpaceDeleteMod_VERSION,
                   0,                                                                  // PBlock Ref Num
                   1, kMainPanel, IDD_PRTSPACEDELETE_MAIN, IDS_PARAMETERS, 0, 0, NULL, // AutoUI stuff for panel 0
                   p_end ) {
    m_paramDesc.SetClassDesc( this );

    m_paramDesc.AddParam( kSelectionMode, _T( "SelectionMode" ), TYPE_INT, 0, 0, p_end );
    m_paramDesc.ParamOption( kSelectionMode, p_default, kSelectionSelection, p_end );
    m_paramDesc.ParamOption( kSelectionMode, p_ui, kMainPanel, TYPE_RADIO, 2, IDC_PRTSPACEDELETE_SELECTION_RDX,
                             IDC_PRTSPACEDELETE_SOFTSELECTION_RDX, p_end );

    m_paramDesc.AddParam( kResetSelection, _T( "ResetSelection" ), TYPE_BOOL, 0, 0, p_end );
    m_paramDesc.ParamOption( kResetSelection, p_default, TRUE );
    m_paramDesc.ParamOption( kResetSelection, p_ui, kMainPanel, TYPE_SINGLECHEKBOX, IDC_PRTSPACEDELETE_RESET_CHK,
                             p_end );

    // Internal, don't show in the UI.
    m_paramDesc.AddParam( kWarnIfMissingID, _T( "showMissingIDWarning" ), TYPE_BOOL, 0, 0, p_end );
    m_paramDesc.ParamOption( kWarnIfMissingID, p_default, true );
}