// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0
#pragma once

#include "MaxKrakatoaPFParticleChannelFileIDInteger.h"
#include <ParticleFlow/PFSimpleOperator.h>
#include <frantic/channels/channel_map.hpp>
#include <frantic/graphics/vector3f.hpp>
#include <frantic/graphics/vector4f.hpp>
#include <frantic/max3d/fpwrapper/mixin_wrapper.hpp>

#define KrakatoaPFFileUpdate_Interface_ID Interface_ID( 0x6c543a21, 0x33ff440b )
#define KrakatoaPFFileUpdate_Class_ID Class_ID( 0x6a9961f8, 0x190331de )

// param block and message IDs
enum {
    kKrakatoaPFFileUpdate_message_init,
    kKrakatoaPFFileUpdate_message_filename,
};

enum {
    kKrakatoaPFFileUpdate_filepattern,
    kKrakatoaPFFileUpdate_frame_offset,
    kKrakatoaPFFileUpdate_single_frame_only,
    kKrakatoaPFFileUpdate_limit_to_custom_range,
    kKrakatoaPFFileUpdate_custom_range_start,
    kKrakatoaPFFileUpdate_custom_range_end,
    kKrakatoaPFFileUpdate_use_additive_blend_unused,
    kKrakatoaPFFileUpdate_position_blend_percent_unused,
    kKrakatoaPFFileUpdate_velocity_blend_percent_unused,
    kKrakatoaPFFileUpdate_acceleration_blend_percent_unused,
    kKrakatoaPFFileUpdate_orientation_blend_percent_unused,
    kKrakatoaPFFileUpdate_interpolatebetweenframes_unused,
    kKrakatoaPFFileUpdate_evenlydistributeloading_unused,
    kKrakatoaPFFileUpdate_linktoobjecttm,
    kKrakatoaPFFileUpdate_objectfortm_unused,
    kKrakatoaPFFileUpdate_loadfilepartition_unused,
    kKrakatoaPFFileUpdate_filepartitionpart_unused,
    kKrakatoaPFFileUpdate_filepartitiontotal_unused,
    kKrakatoaPFFileUpdate_particle_scale,
    kKrakatoaPFFileUpdate_blend_channel_alphas,
    kKrakatoaPFFileUpdate_blend_channel_names,
    kKrakatoaPFFileUpdate_target_channel_names,
    kKrakatoaPFFileUpdate_blend_channel_arity,
    kKrakatoaPFFileUpdate_blend_channel_use,
    kKrakatoaPFFileUpdate_blend_channel_data_type,
    kKrakatoaPFFileUpdate_blend_channel_blend_type,
};

enum { kKrakatoaPFFileUpdate_pblock_index };

class KrakatoaPFFileUpdateParamProc : public ParamMap2UserDlgProc {
  public:
    void DeleteThis() {}
    INT_PTR DlgProc( TimeValue /*t*/, IParamMap2* map, HWND hWnd, UINT msg, WPARAM wParam, LPARAM lParam );
};

//----------------------------------------------------
// Class Descriptor stuff for exposing the plugin to Max
//----------------------------------------------------
class KrakatoaPFFileUpdateDesc : public ClassDesc2 {
  public:
    static HBITMAP m_depotIcon;
    static HBITMAP m_depotMask;

    static ParamBlockDesc2 pblock_desc;
    static KrakatoaPFFileUpdateParamProc* dialog_proc;

    int IsPublic() { return FALSE; }
    const TCHAR* ClassName() { return GetString( IDS_FILEUPDATE_CLASSNAME ); }
    SClass_ID SuperClassID() { return HELPER_CLASS_ID; }
    Class_ID ClassID() { return KrakatoaPFFileUpdate_Class_ID; }
    Class_ID SubClassID() { return PFOperatorSubClassID; }
    const TCHAR* Category() { return GetString( IDS_CATEGORY ); }
    const TCHAR* InternalName() { return GetString( IDS_FILEUPDATE_CLASSNAME ); }
    HINSTANCE HInstance() { return hInstance; }

    void* Create( BOOL );
    INT_PTR Execute( int cmd, ULONG_PTR arg1, ULONG_PTR arg2, ULONG_PTR arg3 );
};

ClassDesc2* GetKrakatoaPFFileUpdateDesc();

//----------------------------------------------------
// End of KrakatoaPFFileUpdateDesc
//----------------------------------------------------

// Operator definition.
class KrakatoaPFFileUpdate : public PFSimpleOperator,
                             public frantic::max3d::fpwrapper::FFMixinInterface<KrakatoaPFFileUpdate> {
  public:
    KrakatoaPFFileUpdate();
    virtual ~KrakatoaPFFileUpdate();

    // functions to expose to max
    std::string get_channel_data();
    void set_channel_data( std::string );

    virtual bool Proceed( IObject* pCont, PreciseTimeValue timeStart, PreciseTimeValue& timeEnd, Object* pSystem,
                          INode* pNode, INode* actioNode, IPFIntegrator* integrator );
    virtual RefResult NotifyRefChanged( const Interval& changeInt, RefTargetHandle hTarget, PartID& partID,
                                        RefMessage message, BOOL propogate );

#if MAX_VERSION_MAJOR < 17
    virtual RefResult NotifyRefChanged( Interval changeInt, RefTargetHandle hTarget, PartID& partID,
                                        RefMessage message ) {
        return this->NotifyRefChanged( changeInt, hTarget, partID, message, TRUE );
    }
#endif

    virtual bool IsFertile() const { return false; }

    virtual void BeginEditParams( IObjParam* ip, ULONG flags, Animatable* prev );
    virtual const ParticleChannelMask& ChannelsUsed( const Interval& time ) const;
    virtual const Interval ActivityInterval() const;
    virtual ClassDesc* GetClassDesc() const;
    virtual void EndEditParams( IObjParam* ip, ULONG flags, Animatable* next );
    virtual RefTargetHandle Clone( RemapDir& remap );
    virtual TCHAR* GetObjectName();
    virtual Class_ID ClassID();

    // from IPViewItem interface
    bool HasCustomPViewIcons() { return true; }
    HBITMAP GetActivePViewIcon();
    HBITMAP GetInactivePViewIcon();

  private:
    // passes a message to the param map dialog proc
    void PassMessage( int message, LPARAM param );

    // for function publishing
    void InitializeFPDescriptor();
    int NumInterfaces() { return 1; }

    BaseInterface* GetInterface( int i ) {
        if( i == 0 )
            return GetInterface( KrakatoaPFFileUpdate_Interface_ID );
        return NULL;
    }

    BaseInterface* GetInterface( Interface_ID id ) {
        if( id == KrakatoaPFFileUpdate_Interface_ID )
            return static_cast<frantic::max3d::fpwrapper::FFMixinInterface<KrakatoaPFFileUpdate>*>( this );
        return PFSimpleOperator::GetInterface( id );
    }

    // for loading and sorting particles
    static const unsigned NUM_BUFFERED_PARTICLES = 200;
    static bool sortFunction( idPair i, idPair j ) { return ( i.id < j.id ); }
};
