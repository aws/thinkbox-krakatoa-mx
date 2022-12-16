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

#include <ParticleFlow/PFSimpleOperator.h>

#pragma warning( pop )

#include <frantic/geometry/trimesh3.hpp>
#include <frantic/geometry/volume_collection.hpp>

#include <MeshNormalSpec.h>
#include <frantic/shading/highlights.hpp> // for frantic::shading::compute_tangent_binormal()
#include <frantic/strings/tstring.hpp>

#define KrakatoaPFGeometryLookup_Class_ID Class_ID( 0x33613198, 0x3881038a )

// param block and message IDs
enum { kKrakatoaPFGeometryLookup_message_init, kKrakatoaPFGeometryLookup_message_filename };

enum {
    kKrakatoaPFGeometryLookup_pick_geometry_node,
    kKrakatoaPFGeometryLookup_clear_selection,
    kKrakatoaPFGeometryLookup_distance,

    kKrakatoaPFGeometryLookup_use_position,
    kKrakatoaPFGeometryLookup_use_barycentric_coords,
    kKrakatoaPFGeometryLookup_use_normals,
    kKrakatoaPFGeometryLookup_use_surface_uwv,

    kKrakatoaPFGeometryLookup_position_put_to_choice,
    kKrakatoaPFGeometryLookup_position_to_uvw_index,
    kKrakatoaPFGeometryLookup_barycentric_coords_to_uvw_index,
    kKrakatoaPFGeometryLookup_normal_to_uvw_index,
    kKrakatoaPFGeometryLookup_surface_uvw_index_to_sample,
    kKrakatoaPFGeometryLookup_surface_uvw_to_uvw_index,

    kKrakatoaPFGeometryLookup_barycentric_coords_shift,

    kKrakatoaPFGeometryLookup_normal_put_choice,

    kKrakatoaPFGeometryLookup_applyOnce,
};

enum { kKrakatoaPFGeometryLookup_pblock_index };

class KrakatoaPFGeometryLookupParamProc : public ParamMap2UserDlgProc {
  public:
    INT_PTR DlgProc( TimeValue t, IParamMap2* map, HWND hWnd, UINT msg, WPARAM wParam, LPARAM lParam );
    void DeleteThis() {}

  private:
    void UpdateDlg( HWND hWnd, int type, float sizeVar, float scaleVar );
};

class KrakatoaPFGeometryLookupParamProc;

//	Descriptor declarations
class KrakatoaPFGeometryLookupDesc : public ClassDesc2 {
  public:
    ~KrakatoaPFGeometryLookupDesc();

    static ParamBlockDesc2 pblock_desc;
    static KrakatoaPFGeometryLookupParamProc* dialog_proc;

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

ClassDesc2* GetKrakatoaPFGeometryLookupDesc();

class KrakatoaPFGeometryLookup : public PFSimpleOperator {
  public:
    // constructor/destructor
    KrakatoaPFGeometryLookup();
    virtual ~KrakatoaPFGeometryLookup();

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
    const virtual TCHAR* GetObjectName( bool localized ) const;
#elif MAX_VERSION_MAJOR >= 15
    const virtual TCHAR* GetObjectName();
#else
    virtual TCHAR* GetObjectName();
#endif

    const ParticleChannelMask& ChannelsUsed( const Interval& time ) const;
    const Interval ActivityInterval() const { return FOREVER; }

    // from IPViewItem interface
    bool HasCustomPViewIcons() { return true; }
    HBITMAP GetActivePViewIcon();
    HBITMAP GetInactivePViewIcon();
    //	HBITMAP GetTruePViewIcon();
    //	HBITMAP GetFalsePViewIcon();

    // From IPFTest interface
    bool Proceed( IObject* pCont, PreciseTimeValue timeStart, PreciseTimeValue& timeEnd, Object* pSystem, INode* pNode,
                  INode* actionNode, IPFIntegrator* integrator );

    // supply ClassDesc descriptor for the concrete implementation of the test
    ClassDesc* GetClassDesc() const;

  private:
    frantic::geometry::trimesh3 m_cachedTrimesh3;
    boost::shared_ptr<frantic::geometry::trimesh3_kdtree> m_kdtree;
    TimeValue m_cachedAtTime;
    boost::shared_ptr<MeshNormalSpec> m_cachedNormals;

    void KrakatoaPFGeometryLookup::PassMessage( int message, LPARAM param );

    static HBITMAP s_activePViewIcon;
    static HBITMAP s_inactivePViewIcon;
};
