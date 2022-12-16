// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0
#pragma once
#pragma warning( push )
#pragma warning( disable : 4100 4003 4512 4245 4238 4239 )

#include <ParticleFlow/PFSimpleTest.h>

#pragma warning( pop )

#include <frantic/geometry/trimesh3.hpp>
#include <frantic/geometry/volume_collection.hpp>
#include <frantic/strings/tstring.hpp>

#define KrakatoaPFGeometryTest_Class_ID Class_ID( 0x47724a6, 0x6871588 )

// param block and message IDs
enum { kKrakatoaPFGeometryTest_message_init, kKrakatoaPFGeometryTest_message_filename };

enum {
    kKrakatoaPFGeometryTest_test_condition,
    kKrakatoaPFGeometryTest_pick_geometry_node,
    kKrakatoaPFGeometryTest_clear_selection,
    kKrakatoaPFGeometryTest_use_distance_unused,
    kKrakatoaPFGeometryTest_distance,
    kKrakatoaPFGeometryTest_select_by_distance,
    kKrakatoaPFGeometryTest_animated_geometry,
};

// enum for radio buttons
enum {
    kKrakatoaPFGeometryTest_inside,
    kKrakatoaPFGeometryTest_outside,
    kKrakatoaPFGeometryTest_surface,
};
enum {
    kKrakatoaPFGeometryTest_no_distance,
    kKrakatoaPFGeometryTest_less_than_distance,
    kKrakatoaPFGeometryTest_greater_than_distance,
};

enum { kKrakatoaPFGeometryTest_pblock_index };

class KrakatoaPFGeometryTestParamProc : public ParamMap2UserDlgProc {
  public:
    INT_PTR DlgProc( TimeValue t, IParamMap2* map, HWND hWnd, UINT msg, WPARAM wParam, LPARAM lParam );
    void DeleteThis() {}

  private:
    void UpdateDlg( HWND hWnd, int type, float sizeVar, float scaleVar );
};

class KrakatoaPFGeometryTestParamProc;

//	Descriptor declarations
class KrakatoaPFGeometryTestDesc : public ClassDesc2 {
  public:
    ~KrakatoaPFGeometryTestDesc();

    static ParamBlockDesc2 pblock_desc;
    static KrakatoaPFGeometryTestParamProc* dialog_proc;

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

ClassDesc2* GetKrakatoaPFGeometryTestDesc();

class KrakatoaPFGeometryTest : public PFSimpleTest {
  public:
    // constructor/destructor
    KrakatoaPFGeometryTest();
    virtual ~KrakatoaPFGeometryTest();

    // From Animatable
#if MAX_VERSION_MAJOR >= 24
    void GetClassName( TSTR& s, bool localized );
#else
    void GetClassName( TSTR& s );
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
    boost::shared_ptr<frantic::geometry::trimesh3_kdtree> m_cachedKDTree;

    TimeValue m_cachedAtTime;

    static HBITMAP s_activePViewIcon;
    static HBITMAP s_truePViewIcon;
    static HBITMAP s_falsePViewIcon;
};
