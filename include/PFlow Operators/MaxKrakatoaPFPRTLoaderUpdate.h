// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0
#pragma once

#include "MaxKrakatoaPFParticleChannelFileIDInteger.h"
#include <ParticleFlow/PFSimpleOperator.h>
#include <frantic/channels/channel_map.hpp>
#include <frantic/graphics/vector3f.hpp>
#include <frantic/graphics/vector4f.hpp>
#include <frantic/max3d/fpwrapper/mixin_wrapper.hpp>

// Important! The class ID must end in a PFlow specific value in order to not
//   show up in the scene explorer. In the interests of not breaking backwards compatibility
//   I have not done so here. New plugins probably should though.
#define KrakatoaPFPRTLoaderUpdate_Interface_ID Interface_ID( 0x6c543a21, 0x33ff440b )
#define KrakatoaPFPRTLoaderUpdate_Class_ID Class_ID( 0x4afe1ff9, 0x3ad34cd4 )

// param block and message IDs
enum {
    kKrakatoaPFPRTLoaderUpdate_pick_PRT_loader,
    kKrakatoaPFPRTLoaderUpdate_channels,
    kKrakatoaPFPRTLoaderUpdate_channel_use,
    kKrakatoaPFPRTLoaderUpdate_channel_alphas,
    kKrakatoaPFPRTLoaderUpdate_channel_options,
    kKrakatoaPFPRTLoaderUpdate_current_channel_alpha,
    kKrakatoaPFPRTLoaderUpdate_current_use_channel,
    kKrakatoaPFPRTLoaderUpdate_current_channel_option,
    kKrakatoaPFPRTLoaderUpdate_adjust_position
};

// channel options radio buttons
enum { kKrakatoaPFPRTLoaderUpdate_channel_blend, kKrakatoaPFPRTLoaderUpdate_channel_add };

enum { kKrakatoaPFPRTLoaderUpdate_pblock_index };

ClassDesc2* GetKrakatoaPFPRTLoaderUpdateDesc();

// Operator definition.
class KrakatoaPFPRTLoaderUpdate : public PFSimpleOperator {
  public:
    KrakatoaPFPRTLoaderUpdate();
    virtual ~KrakatoaPFPRTLoaderUpdate();

    // From Animatable
#if MAX_VERSION_MAJOR < 24
    void GetClassName( TSTR& s );
#else
    void GetClassName( TSTR& s, bool localized );
#endif
    virtual Class_ID ClassID();
    virtual void BeginEditParams( IObjParam* ip, ULONG flags, Animatable* prev );
    virtual void EndEditParams( IObjParam* ip, ULONG flags, Animatable* next );

    // From ReferenceMaker
    virtual IOResult Load( ILoad* iload );
    virtual IOResult Save( ISave* isave );
    virtual RefResult NotifyRefChanged( const Interval& changeInt, RefTargetHandle hTarget, PartID& partID,
                                        RefMessage message, BOOL propagate );

#if MAX_VERSION_MAJOR < 17
    virtual RefResult NotifyRefChanged( Interval changeInt, RefTargetHandle hTarget, PartID& partID,
                                        RefMessage message ) {
        return this->NotifyRefChanged( changeInt, hTarget, partID, message, TRUE );
    }
#endif

    // From ReferenceTarget
    virtual RefTargetHandle Clone( RemapDir& remap );

    // From BaseObject
#if MAX_VERSION_MAJOR >= 24
    virtual const TCHAR* GetObjectName( bool localized ) const;
#elif MAX_VERSION_MAJOR >= 15
    virtual const TCHAR* GetObjectName();
#else
    virtual TCHAR* GetObjectName();
#endif

    // from FPMixinInterface
    virtual FPInterfaceDesc* GetDescByID( Interface_ID id );

    // From IPFAction interface
    virtual const ParticleChannelMask& ChannelsUsed( const Interval& time ) const;
    virtual const Interval ActivityInterval() const;
    virtual bool IsFertile() const { return false; }

    // From IPFOperator interface
    virtual bool Proceed( IObject* pCont, PreciseTimeValue timeStart, PreciseTimeValue& timeEnd, Object* pSystem,
                          INode* pNode, INode* actionNode, IPFIntegrator* integrator );

    // from IPViewItem interface
    virtual bool HasCustomPViewIcons() { return true; }
    virtual HBITMAP GetActivePViewIcon();
    virtual HBITMAP GetInactivePViewIcon();

    // supply ClassDesc descriptor for the concrete implementation of the operator
    virtual ClassDesc* GetClassDesc() const;

  private:
    friend class KrakatoaPFPRTLoaderUpdateParamProc;

    // for loading and sorting particles
    static const unsigned NUM_BUFFERED_PARTICLES = 200;
    static bool sortFunction( idPair i, idPair j ) { return ( i.id < j.id ); }

    // This cached value is used to determine when a new PRT Loader has been chosen, so that the
    // list of channels can be reset to defaults.
    INode* m_pPrevLoader;

    int m_currentSelection;
    std::vector<std::string> m_channels;
};
