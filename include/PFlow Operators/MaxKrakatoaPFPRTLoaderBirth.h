// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0
#pragma once

#include "MaxKrakatoaPFParticleChannelFileIDInteger.h"

#include <frantic/channels/channel_map.hpp>
#include <frantic/graphics/vector3f.hpp>
#include <map>

#include <ParticleFlow/pfactionstatedesc.h>

#define KrakatoaPFPRTLoaderBirth_Class_ID Class_ID( 0x5e45765b, 0x61b809f4 )

// Paramater block and message enums

// block IDs
enum { kPRTLoaderBirth_mainPBlockIndex };

// param IDs
enum { kPRTLoaderBirth_pick_PRT_loader };

class KrakatoaPFPRTLoaderBirthDlgProc : public ParamMap2UserDlgProc {
  public:
    INT_PTR DlgProc( TimeValue t, IParamMap2* map, HWND hWnd, UINT msg, WPARAM wParam, LPARAM lParam );
    void DeleteThis() {}
};

//	Descriptor declaration

class KrakatoaPFPRTLoaderBirthDesc : public ClassDesc2 {
  public:
    ~KrakatoaPFPRTLoaderBirthDesc();

    static HBITMAP m_depotIcon;
    static HBITMAP m_depotMask;

    int IsPublic() { return 0; }
    const TCHAR* ClassName() { return GetString( IDS_PRTLOADERBIRTH_CLASSNAME ); }
#if MAX_VERSION_MAJOR >= 24
    const TCHAR* NonLocalizedClassName() { return GetString( IDS_PRTLOADERBIRTH_CLASSNAME ); }
#endif
    SClass_ID SuperClassID() { return HELPER_CLASS_ID; }
    Class_ID ClassID() { return KrakatoaPFPRTLoaderBirth_Class_ID; }
    Class_ID SubClassID() { return PFOperatorSubClassID; }
    const TCHAR* Category() { return GetString( IDS_CATEGORY ); }
    const TCHAR* InternalName() { return GetString( IDS_PRTLOADERBIRTH_CLASSNAME ); }
    HINSTANCE HInstance() { return hInstance; }

    void* Create( BOOL );
    INT_PTR Execute( int cmd, ULONG_PTR arg1, ULONG_PTR arg2, ULONG_PTR arg3 );
};

ClassDesc2* GetKrakatoaPFPRTLoaderBirthDesc();

// Particle structure used for birthing.
class BirthParticle {
  public:
    int id;
    frantic::graphics::vector3f position;

    static void define_channel_map( frantic::channels::channel_map& pcm ) {
        pcm = frantic::channels::channel_map();
        pcm.define_channel<int>( _T("ID") );
        pcm.define_channel<frantic::graphics::vector3f>( _T("Position") );
    }
};

// Operator definition
class KrakatoaPFPRTLoaderBirth : public PFSimpleOperator {

  public:
    KrakatoaPFPRTLoaderBirth();

    // from FPMixinInterface
    virtual FPInterfaceDesc* GetDescByID( Interface_ID id );

    // From Animatable
#if MAX_VERSION_MAJOR < 24
    void GetClassName( TSTR& s );
#else
    void GetClassName( TSTR& s, bool localized );
#endif
    Class_ID ClassID();
    void BeginEditParams( IObjParam* ip, ULONG flags, Animatable* prev );
    void EndEditParams( IObjParam* ip, ULONG flags, Animatable* next );

    // From ReferenceMaker
    RefResult NotifyRefChanged( const Interval& changeInt, RefTargetHandle hTarget, PartID& partID, RefMessage message,
                                BOOL propagate );

#if MAX_VERSION_MAJOR < 17
    virtual RefResult NotifyRefChanged( Interval changeInt, RefTargetHandle hTarget, PartID& partID,
                                        RefMessage message ) {
        return this->NotifyRefChanged( changeInt, hTarget, partID, message, TRUE );
    }
#endif

    // From ReferenceTarget
    RefTargetHandle Clone( RemapDir& remap );

    // From BaseObject
#if MAX_VERSION_MAJOR >= 24
    virtual const TCHAR* GetObjectName( bool localized ) const;
#elif MAX_VERSION_MAJOR >= 15
    virtual const TCHAR* GetObjectName();
#else
    virtual TCHAR* GetObjectName();
#endif

    // From IPFAction interface
    const ParticleChannelMask& ChannelsUsed( const Interval& time ) const;
    const Interval ActivityInterval() const;
    bool IsFertile() const { return true; }
    bool IsEmitterPropDependent() const { return true; }
    bool IsEmitterTMDependent() const;
    IObject* GetCurrentState( IObject* pContainer );
    void SetCurrentState( IObject* actionState, IObject* pContainer );

    // From IPFOperator interface
    bool Proceed( IObject* pCont, PreciseTimeValue timeStart, PreciseTimeValue& timeEnd, Object* pSystem, INode* pNode,
                  INode* actionNode, IPFIntegrator* integrator );

    // from IPViewItem interface
    bool HasCustomPViewIcons() { return true; }
    HBITMAP GetActivePViewIcon();
    HBITMAP GetInactivePViewIcon();

    // supply ClassDesc descriptor for the concrete implementation of the operator
    ClassDesc* GetClassDesc() const;

    // from ReferenceMaker
    virtual IOResult Load( ILoad* iload );
    virtual IOResult Save( ISave* isave );

  private:
    static const unsigned NUM_BUFFERED_PARTICLES = 200;
    static bool sortFunction( idPair i, idPair j ) { return ( i.id < j.id ); }

    // a cache of the previous file's IDs so that we know which ones not to rebirth if they move out
    // of the brith container
    // std::vector<idPair> m_lastIDs;
    // int m_lastTimeValue; // the time of the last proceed call

    // Cache the last seen input loader, so I can tell if a new loader has been selected.
    INode* m_pPrevLoader;

    std::map<IObject*, IObject*> m_stateMap;
};
