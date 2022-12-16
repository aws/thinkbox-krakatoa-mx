// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0
#define KRAKATOA_PFOPTIONS_CLASSID Class_ID( 0x2597295b, 0x2cf97e0f )
#define KRAKATOA_PFOPTIONS_INTERFACE Interface_ID( 0x59e14298, 0x177a5230 )
#define GetKrakatoaPFOptionsInterface( obj )                                                                           \
    static_cast<IKrakatoaPFOptions*>( GetPFObject( obj )->GetInterface( KRAKATOA_PFOPTIONS_INTERFACE ) )

ClassDesc2* GetKrakatoaPFOptionsDesc();

enum { kEnableScriptedDensity, kEnableScriptedColor };

#pragma warning( push )
#pragma warning( disable : 4100 )
class IKrakatoaPFOptions : public FPMixinInterface {
  public:
    BEGIN_FUNCTION_MAP
    FN_0( kEnableScriptedDensity, TYPE_BOOL, IsScriptedDensityEnabled );
    FN_0( kEnableScriptedColor, TYPE_BOOL, IsScriptedColorEnabled );
    END_FUNCTION_MAP

    FPInterfaceDesc* GetDesc();
    virtual bool IsScriptedDensityEnabled() = 0;
    virtual bool IsScriptedColorEnabled() = 0;
};
#pragma warning( pop )

inline IKrakatoaPFOptions* KrakatoaPFOptionsInterface( Object* obj ) {
    return ( ( obj == NULL ) ? NULL : GetKrakatoaPFOptionsInterface( obj ) );
}

inline IKrakatoaPFOptions* KrakatoaPFOptionsInterface( INode* node ) {
    return ( ( node == NULL ) ? NULL : KrakatoaPFOptionsInterface( node->GetObjectRef() ) );
}

#pragma warning( push, 3 )
#pragma warning( disable : 4239 )

class KrakatoaPFOptions : public PFSimpleOperator, public IKrakatoaPFOptions {
  private:
    ParticleChannelMask m_usedChannels;

  public:
    KrakatoaPFOptions();
    virtual ~KrakatoaPFOptions() {}

    Class_ID ClassID();
#if MAX_VERSION_MAJOR >= 24
    void GetClassName( TSTR& s, bool localized );
#else
    void GetClassName( TSTR& s );
#endif

#if MAX_VERSION_MAJOR >= 24
    const TCHAR* GetObjectName( bool localized ) const;
#elif MAX_VERSION_MAJOR >= 15
    const TCHAR* GetObjectName();
#else
    TCHAR* GetObjectName();
#endif

    ClassDesc* GetClassDesc() const;
    BaseInterface* GetInterface( Interface_ID id );

    const Interval ActivityInterval() const;
    RefTargetHandle Clone( RemapDir& remap );
    void BeginEditParams( IObjParam* ip, ULONG flags, Animatable* prev );
    void EndEditParams( IObjParam* ip, ULONG flags, Animatable* next );

    const ParticleChannelMask& ChannelsUsed( const Interval& /* time*/ ) const;
    bool Proceed( IObject* pCont, PreciseTimeValue timeStart, PreciseTimeValue& timeEnd, Object* pSystem, INode* pNode,
                  INode* actioNode, IPFIntegrator* integrator );

    // From IKrakatoaPFRenderOp
    bool IsScriptedDensityEnabled() { return m_pblock->GetInt( kEnableScriptedDensity ) == TRUE; }
    bool IsScriptedColorEnabled() { return m_pblock->GetInt( kEnableScriptedColor ) == TRUE; }

    // from IPViewItem interface
    bool HasCustomPViewIcons() { return true; }
    HBITMAP GetActivePViewIcon();
    HBITMAP GetInactivePViewIcon();
};

#pragma warning( pop )
