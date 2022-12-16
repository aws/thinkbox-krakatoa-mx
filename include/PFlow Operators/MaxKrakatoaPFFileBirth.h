// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0
#pragma once

#include "MaxKrakatoaPFParticleChannelFileIDInteger.h"

#include <frantic/channels/channel_map.hpp>
#include <frantic/files/filename_sequence.hpp>
#include <frantic/graphics/vector3f.hpp>
#include <map>

#include <ParticleFlow/pfactionstatedesc.h>

#define KrakatoaPFFileBirth_Class_ID Class_ID( 0x2eed7080, 0x2195679a )

// Paramater block and message enums

// block IDs
enum { kFileBirth_mainPBlockIndex };

// param IDs
enum {
    kFileBirth_filepattern,
    kFileBirth_frame_offset,
    kFileBirth_single_frame_only,
    kFileBirth_limit_to_custom_range,
    kFileBirth_custom_range_start,
    kFileBirth_custom_range_end,
    kFileBirth_update_unused,
    kFileBirth_velocity_blend_percent_unused,
    kFileBirth_position_blend_percent_unused,
    kFileBirth_evenlydistributeloading_unused, // Evenly distributes the loaded particles across the input file, for a
                                               // representative sample.
    kFileBirth_linktoobjecttm,                 // Link to an object's TM
    kFileBirth_amount_unused,                  // amount of particles emitted
    kFileBirth_objectfortm_unused,             // The object whose TM to use
    kFileBirth_loadfilepartition_unused,       // Flag to enable splitting the file into partitions
    kFileBirth_filepartitionpart_unused,       // Which # of the different partitions
    kFileBirth_filepartitiontotal_unused,      // How many different partitions
    kFileBirth_particle_scale,
    kFileBirth_write_ID_to_MXSInteger,
};

enum { kFileBirth_amountMax = 10000000 };

// User Defined Reference Messages from PB
enum { kFileBirth_RefMsg_InitDlg = REFMSG_USER + 13279 };

// dialog messages
enum {
    kFileBirth_message_type = 100, // type change message
    kFileBirth_message_filechoose,
    kFileBirth_message_amount // amount change message
};

class KrakatoaPFFileBirthDlgProc : public ParamMap2UserDlgProc {
  public:
    INT_PTR DlgProc( TimeValue t, IParamMap2* map, HWND hWnd, UINT msg, WPARAM wParam, LPARAM lParam );
    void DeleteThis() {}
};

//	Descriptor declaration

class KrakatoaPFFileBirthDesc : public ClassDesc2 {
  public:
    ~KrakatoaPFFileBirthDesc();

    static HBITMAP m_depotIcon;
    static HBITMAP m_depotMask;

    // static ParamBlockDesc2 pblock_desc;
    // static FileBirthParamProc* dialog_proc;

    int IsPublic() { return 0; }
    const TCHAR* ClassName() { return GetString( IDS_FILEBIRTH_CLASSNAME ); }
    SClass_ID SuperClassID() { return HELPER_CLASS_ID; }
    Class_ID ClassID() { return KrakatoaPFFileBirth_Class_ID; }
    Class_ID SubClassID() { return PFOperatorSubClassID; }
    const TCHAR* Category() { return GetString( IDS_CATEGORY ); }
    const TCHAR* InternalName() { return GetString( IDS_FILEBIRTH_CLASSNAME ); }
    HINSTANCE HInstance() { return hInstance; }

    void* Create( BOOL );
    INT_PTR Execute( int cmd, ULONG_PTR arg1, ULONG_PTR arg2, ULONG_PTR arg3 );
};

ClassDesc2* GetKrakatoaPFFileBirthDesc();

// Particle structure used for birthing.
class BirthParticle {
  public:
    int id;
    frantic::graphics::vector3f position;

    static void define_channel_map( frantic::channels::channel_map& pcm ) {
        pcm = frantic::channels::channel_map();
        pcm.define_channel<int>( "ID" );
        pcm.define_channel<frantic::graphics::vector3f>( "Position" );
    }
};

// Operator definition
class KrakatoaPFFileBirth : public PFSimpleOperator {

  public:
    KrakatoaPFFileBirth();

    // From Animatable
    void GetClassName( TSTR& s );
    Class_ID ClassID();
    void BeginEditParams( IObjParam* ip, ULONG flags, Animatable* prev );
    void EndEditParams( IObjParam* ip, ULONG flags, Animatable* next );

    // From ReferenceMaker
    RefResult NotifyRefChanged( const Interval& changeInt, RefTargetHandle hTarget, PartID& partID, RefMessage message,
                                BOOL propogate );

#if MAX_VERSION_MAJOR < 17
    virtual RefResult NotifyRefChanged( Interval changeInt, RefTargetHandle hTarget, PartID& partID,
                                        RefMessage message ) {
        return this->NotifyRefChanged( changeInt, hTarget, partID, message, TRUE );
    }
#endif

    // From ReferenceTarget
    RefTargetHandle Clone( RemapDir& remap );

    // From BaseObject
    virtual
#if MAX_VERSION_MAJOR >= 15
        const
#endif
        TCHAR*
        GetObjectName();

    // From IPFAction interface
    const ParticleChannelMask& ChannelsUsed( const Interval& time ) const;
    const Interval ActivityInterval() const;
    bool IsFertile() const { return true; }
    bool IsEmitterPropDependent() const { return true; }
    bool IsEmitterTMDependent() const;

    // From IPFOperator interface
    bool Proceed( IObject* pCont, PreciseTimeValue timeStart, PreciseTimeValue& timeEnd, Object* pSystem, INode* pNode,
                  INode* actionNode, IPFIntegrator* integrator );

    // from IPViewItem interface
    bool HasCustomPViewIcons() { return true; }
    HBITMAP GetActivePViewIcon();
    HBITMAP GetInactivePViewIcon();

    // supply ClassDesc descriptor for the concrete implementation of the operator
    ClassDesc* GetClassDesc() const;

  private:
    static const unsigned NUM_BUFFERED_PARTICLES = 200;
    static bool sortFunction( idPair i, idPair j ) { return ( i.id < j.id ); }

    // a cache of the previous file's IDs so that we know which ones not to rebirth if they move out
    // of the brith container
    std::vector<idPair> m_lastIDs;
    int m_lastTimeValue; // the time of the last proceed call

    void RefreshFilenameUI() const;

    // const access to class members
    int emitTotalAmount() const { return m_emitTotalAmount; }

    // access to class members
    int& _emitTotalAmount() { return m_emitTotalAmount; }
    std::map<IObject*, float>& _accumLevel() { return m_accumLevel; }
    float& _accumLevel( IObject* pCont ) { return m_accumLevel[pCont]; }
    std::map<IObject*, int>& _particlesGenerated() { return m_particlesGenerated; }
    int& _particlesGenerated( IObject* pCont ) { return m_particlesGenerated[pCont]; }

    mutable int m_emitTotalAmount;
    std::map<IObject*, float> m_accumLevel;       // indicate accumulated rate growth for a particle generation
    std::map<IObject*, int> m_particlesGenerated; // amount of particles currently generated
};
