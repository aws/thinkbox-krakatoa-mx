// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0
#pragma once
#pragma warning( push )
#pragma warning( disable : 4100 )
#pragma warning( disable : 4003 )
#pragma warning( disable : 4512 )
#pragma warning( disable : 4245 )
#pragma warning( disable : 4238 )
#pragma warning( disable : 4239 )

#include <ParticleFlow/PFSimpleTest.h>

#pragma warning( pop )

#include <frantic/geometry/particle_collision_detector.hpp>
#include <frantic/geometry/raytraced_geometry_collection.hpp>
#include <frantic/geometry/trimesh3.hpp>
#include <frantic/geometry/volume_collection.hpp>
#include <frantic/strings/tstring.hpp>

#define KrakatoaPFCollisionTest_Class_ID Class_ID( 0x6b8d278d, 0x39571e8a )

// param block and message IDs
enum { kKrakatoaPFCollisionTest_message_init, kKrakatoaPFCollisionTest_message_filename };

enum {
    kKrakatoaPFCollisionTest_pick_geometry_node,
    kKrakatoaPFCollisionTest_clear_selection,
    kKrakatoaPFCollisionTest_test_condition,
    kKrakatoaPFCollisionTest_reflect_amount,
    kKrakatoaPFCollisionTest_reflect_magnitude,
    kKrakatoaPFCollisionTest_reflect_variation,
    kKrakatoaPFCollisionTest_reflect_chaos,
    kKrakatoaPFCollisionTest_collision_offset,
    kKrakatoaPFCollisionTest_reflect_elasticity,
    kKrakatoaPFCollisionTest_collision_limit,
    kKrakatoaPFCollisionTest_random_seed,
    kKrakatoaPFCollisionTest_animated_geometry,
};

// enum for radio buttons
enum {
    kKrakatoaPFCollisionTest_frontfaces,
    kKrakatoaPFCollisionTest_backfaces,
    kKrakatoaPFCollisionTest_bothfaces,
};

enum { kKrakatoaPFCollisionTest_pblock_index };

class KrakatoaPFCollisionTestParamProc : public ParamMap2UserDlgProc {
  public:
    INT_PTR DlgProc( TimeValue t, IParamMap2* map, HWND hWnd, UINT msg, WPARAM wParam, LPARAM lParam );
    void DeleteThis() {}

  private:
    void UpdateDlg( HWND hWnd, int type, float sizeVar, float scaleVar );
};

class KrakatoaPFCollisionTestParamProc;

//	Descriptor declarations
class KrakatoaPFCollisionTestDesc : public ClassDesc2 {
  public:
    ~KrakatoaPFCollisionTestDesc();

    static ParamBlockDesc2 pblock_desc;
    static KrakatoaPFCollisionTestParamProc* dialog_proc;

    int IsPublic();
    void* Create( BOOL loading = FALSE );
    const TCHAR* ClassName();
#if MAX_VERSION_MAJOR >= 24
    const TCHAR* NonLocalizedClassName();
#endif
    SClass_ID SuperClassID();
    Class_ID ClassID();
    Class_ID SubClassID();
    const TCHAR* Category();

    const TCHAR* InternalName();
    HINSTANCE HInstance();

    INT_PTR Execute( int cmd, ULONG_PTR arg1, ULONG_PTR arg2, ULONG_PTR arg3 );

    static HBITMAP m_depotIcon;
    static HBITMAP m_depotMask;

  private:
    static frantic::tstring s_unavailableDepotName;
};

ClassDesc2* GetKrakatoaPFCollisionTestDesc();

class KrakatoaPFCollisionTest : public PFSimpleTest {
  public:
    // constructor/destructor
    KrakatoaPFCollisionTest();
    virtual ~KrakatoaPFCollisionTest();

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

    // Duration Test supports randomness
    bool SupportRand() const { return true; }
    int GetRand();
    void SetRand( int seed );

    // From IPFAction interface
    bool Init( IObject* pCont, Object* pSystem, INode* node, Tab<Object*>& actions, Tab<INode*>& actionNodes );
    bool Release( IObject* pCont );
    IObject* GetCurrentState( IObject* pContainer );
    void SetCurrentState( IObject* actionState, IObject* pContainer );
    const ParticleChannelMask& ChannelsUsed( const Interval& time ) const;
    const Interval ActivityInterval() const { return FOREVER; }

    // from IPViewItem interface
    bool HasCustomPViewIcons() { return true; }
    HBITMAP GetActivePViewIcon();
    HBITMAP GetTruePViewIcon();
    HBITMAP GetFalsePViewIcon();

    // From IPFTest interface
    bool Proceed( IObject* pCont, PreciseTimeValue timeStart, PreciseTimeValue& timeEnd, Object* pSystem, INode* pNode,
                  INode* actionNode, IPFIntegrator* integrator, BitArray& testResult, Tab<float>& testTime );

    // supply ClassDesc descriptor for the concrete implementation of the test
    ClassDesc* GetClassDesc() const;

  private:
    frantic::geometry::trimesh3 m_cachedTrimesh3;
    frantic::geometry::particle_collision_detector m_cachedCollisionDetector;

    TimeValue m_cachedAtTime;

    void reflect_particle( const frantic::graphics::vector3f& startVel, const double startTime,
                           const frantic::geometry::raytrace_intersection& intersection, float magnitude,
                           float variation, float chaos, float elasticity, RandGenerator* randGen,
                           frantic::graphics::vector3f& newVel );

    // This is straight out of some PFlow sample code, and I'm
    // not sure of the full implications of it, but it's required
    // in order to use the pflow randomization system.

    // to keep track of client particle systems
    // the test may serve several particle systems at once
    // each particle system has its own randomization scheme
    RandObjLinker m_randLinker;

    static HBITMAP s_activePViewIcon;
    static HBITMAP s_truePViewIcon;
    static HBITMAP s_falsePViewIcon;
};
