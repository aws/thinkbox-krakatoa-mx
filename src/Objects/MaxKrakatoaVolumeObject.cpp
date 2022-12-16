// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0
#include "stdafx.h"

#include "resource.h"

#include "krakatoa/particle_volume.hpp"

#include "Objects/MaxKrakatoaPRTInterface.h"
#include "Objects/MaxKrakatoaPRTObjectDisplay.hpp"
#include "Objects/MaxKrakatoaVolumeObject.h"

#include "MaxKrakatoaChannelModifier.h"
#include "MaxKrakatoaMaterial.hpp"
#include "MaxKrakatoaStdMaterialStream.h"

#include <frantic/particles/streams/fractional_particle_istream.hpp>
#include <frantic/particles/streams/rle_levelset_particle_istream.hpp>
#include <frantic/volumetrics/levelset/rle_level_set.hpp>

#include <frantic/max3d/AutoViewExp.hpp>
#include <frantic/max3d/geometry/null_view.hpp>
#include <frantic/max3d/max_utility.hpp>
#include <frantic/max3d/paramblock_builder.hpp>
#include <frantic/max3d/particles/streams/deformed_particle_istream.hpp>

#include <custcont.h>
#include <iparamm2.h>

#include <boost/tuple/tuple.hpp>

#define MaxKrakatoaVolumeObject_NAME "PRT Volume"
#define MaxKrakatoaVolumeObject_VERSION 2

extern HINSTANCE hInstance;
extern Mesh* GetPRTVolumeIconMesh();
#if MAX_VERSION_MAJOR >= 25
extern MaxSDK::SharedMeshPtr GetPRTVolumeIconMeshShared();
#endif

using namespace frantic::graphics;
using namespace frantic::geometry;
using namespace frantic::particles::streams;
using namespace frantic::volumetrics::levelset;
using namespace frantic::max3d::particles::streams;

class MaxKrakatoaVolumeObject : public krakatoa::max3d::MaxKrakatoaPRTObjectDisplay<MaxKrakatoaVolumeObject> {
    // cached level set variables
    boost::shared_ptr<frantic::volumetrics::levelset::rle_level_set> m_pLevelset;
    Interval m_meshValidity;
    Box3 m_levelsetBounds;
    float m_voxelSpacing;

    // cached voxel sampler variables
    boost::shared_ptr<krakatoa::particle_volume_voxel_sampler> m_voxelSampler;

    bool m_doJitter;
    unsigned int m_randomSeed;
    size_t m_randomCount;
    bool m_jitterWellDistributed;

  protected:
    virtual ClassDesc2* GetClassDesc();

    virtual bool InWorldSpace() const;
    virtual Mesh* GetIconMesh( Matrix3& outTM );
#if MAX_VERSION_MAJOR >= 25
    virtual MaxSDK::SharedMeshPtr GetIconMeshShared( Matrix3& outTM );
#endif

    virtual particle_istream_ptr
    GetInternalStream( INode* pNode, TimeValue t, Interval& inoutValidity,
                       frantic::max3d::particles::IMaxKrakatoaPRTEvalContextPtr pEvalContext );

  private:
    void CacheLevelset( TimeValue t, frantic::logging::progress_logger& progressLogger );
    void CacheVoxelSampler( TimeValue t );

    friend class MaxKrakatoaVolumeObject_PLCB;
    void PostLoadCallback( ILoad* iload );

  public:
    MaxKrakatoaVolumeObject( bool loading );
    virtual ~MaxKrakatoaVolumeObject();

    virtual void SetIconSize( float scale );

    // From Animatable

    // From ReferenceMaker
    virtual IOResult Load( ILoad* iload );
    virtual RefResult NotifyRefChanged( const Interval& changeInt, RefTargetHandle hTarget, PartID& partID,
                                        RefMessage message, BOOL propagate );

    // From BaseObject
#if MAX_VERSION_MAJOR >= 24
    virtual const TCHAR* GetObjectName( bool localized );
#elif MAX_VERSION_MAJOR >= 15
    virtual const TCHAR* GetObjectName();
#else
    virtual TCHAR* GetObjectName();
#endif

    // From Object
    virtual void InitNodeName( MSTR& s );
    virtual void GetDeformBBox( TimeValue t, Box3& box, Matrix3* tm = NULL, BOOL useSel = FALSE );

    void ForceInvalidate() {
        m_pLevelset.reset();
        m_voxelSampler.reset();
    }
};

class MaxKrakatoaVolumeObjectDesc : public ClassDesc2 {
    frantic::max3d::ParamBlockBuilder m_paramDesc;

  public:
    MaxKrakatoaVolumeObjectDesc();

    int IsPublic() { return TRUE; }
    void* Create( BOOL loading ) { return new MaxKrakatoaVolumeObject( loading != FALSE ); }
    const TCHAR* ClassName() { return _T( MaxKrakatoaVolumeObject_NAME ); }
#if MAX_VERSION_MAJOR >= 24
    const TCHAR* NonLocalizedClassName() { return _T( MaxKrakatoaVolumeObject_NAME ); }
#endif
    SClass_ID SuperClassID() { return GEOMOBJECT_CLASS_ID; }
    Class_ID ClassID() { return MaxKrakatoaVolumeObject_CLASSID; }
    const TCHAR* Category() { return _T("Krakatoa"); }

    // returns fixed parsable name (scripter-visible name)
    const TCHAR* InternalName() { return _T( MaxKrakatoaVolumeObject_NAME ); }
    HINSTANCE HInstance() { return hInstance; } // returns owning module handle
};

ClassDesc2* GetMaxKrakatoaVolumeObjectDesc() {
    static MaxKrakatoaVolumeObjectDesc theDesc;
    return &theDesc;
}

enum { kSeedingModeRegularGrid = 0, kSeedingModeRandom = 1 };

enum {
    kTargetNode,
    kVoxelLength,
    kUseShell,
    kShellStart,
    kShellThickness,
    kViewportUsePercentage,
    kViewportPercentage,
    kViewportUseLimit,
    kViewportLimit,
    kUseViewportVoxelLength,
    kViewportVoxelLength,
    kViewportIgnoreMaterial,
    kSeedingMode, // obsolete
    kMultipleCount,
    kSubdivideCount,
    kViewportEnabled,
    kRandomCount,
    kRandomSeed,
    kJitterSample,
    kSubdivideEnabled,
    kMultiplePerRegion,
    kJitterWellDistributed,
    kViewportDisableSubdivision,
    kIconSize,
    kUseDensityCompensation,
    kInWorldSpace,
    kDisableVertexVelocity
};

class MainDlgProc : public ParamMap2UserDlgProc {
  public:
    MainDlgProc() {}
    virtual ~MainDlgProc() {}
    virtual INT_PTR DlgProc( TimeValue t, IParamMap2* map, HWND hWnd, UINT msg, WPARAM wParam, LPARAM lParam );
    virtual void DeleteThis() {}
};

INT_PTR MainDlgProc::DlgProc( TimeValue /*t*/, IParamMap2* /*map*/, HWND hWnd, UINT msg, WPARAM wParam,
                              LPARAM lParam ) {
    switch( msg ) {
    case WM_INITDIALOG: {
        ISpinnerControl* pSpinner = NULL;
        try {
            pSpinner = GetISpinner( GetDlgItem( hWnd, IDC_PRTVOXEL_VOLUME_SPACING_SPIN ) );
            pSpinner->SetResetValue( 1.f );
            ReleaseISpinner( pSpinner );
        } catch( ... ) {
            ReleaseISpinner( pSpinner );
            throw;
        }
        try {
            pSpinner = GetISpinner( GetDlgItem( hWnd, IDC_PRTVOXEL_VOLUME_VIEWPORTSPACING_SPIN ) );
            pSpinner->SetResetValue( 2.f );
            ReleaseISpinner( pSpinner );
        } catch( ... ) {
            ReleaseISpinner( pSpinner );
            throw;
        }

        break;
    }
    case WM_COMMAND: {
        HWND rcvHandle = (HWND)lParam;
        WORD msg = HIWORD( wParam );
        if( rcvHandle == GetDlgItem( hWnd, IDC_PRTVOXEL_VOLUME_TARGETMENU_BUTTON ) ) {
            if( msg == BN_CLICKED ) {
                frantic::max3d::mxs::expression( _T("FranticParticleRenderMXS.OpenPRTVolumeOptionsRCMenu()") )
                    .evaluate<void>();
                return TRUE;
            }
        }
        break;
    }
    case WM_CONTEXTMENU: {
        HWND rcvHandle = (HWND)wParam;
        if( rcvHandle == GetDlgItem( hWnd, IDC_PRTVOXEL_VOLUME_TARGETNODE_PICK ) ) {
            frantic::max3d::mxs::expression( _T("FranticParticleRenderMXS.OpenPRTVolumeOptionsRCMenu()") )
                .evaluate<void>();
            return TRUE;
        }
        break;
    }
    }
    return FALSE;
}

MainDlgProc* GetMainDlgProc() {
    static MainDlgProc theMaxKrakatoaVolumeObjectDlgProc;
    return &theMaxKrakatoaVolumeObjectDlgProc;
}

class ViewportDlgProc : public ParamMap2UserDlgProc {
  public:
    ViewportDlgProc() {}
    virtual ~ViewportDlgProc() {}
    virtual INT_PTR DlgProc( TimeValue t, IParamMap2* map, HWND hWnd, UINT msg, WPARAM wParam, LPARAM lParam );
    virtual void DeleteThis() {}
};

INT_PTR ViewportDlgProc::DlgProc( TimeValue /*t*/, IParamMap2* map, HWND hWnd, UINT msg, WPARAM wParam,
                                  LPARAM lParam ) {
    switch( msg ) {
    case WM_INITDIALOG:
        break;
    case WM_COMMAND: {
        HWND rcvHandle = (HWND)lParam;
        WORD msg = HIWORD( wParam );
        if( rcvHandle == GetDlgItem( hWnd, IDC_PRTVOXEL_UPDATE_BUTTON ) ) {
            if( msg == BN_CLICKED ) {
                IParamBlock2* pblock = map->GetParamBlock();
                if( pblock ) {
                    MaxKrakatoaVolumeObject* pOwner = static_cast<MaxKrakatoaVolumeObject*>( pblock->GetOwner() );
                    pOwner->ForceInvalidate();
                    pOwner->NotifyDependents( FOREVER, PART_GEOM, REFMSG_CHANGE ); // Force the scene to be updated.
                }
                return TRUE;
            }
        }
        break;
    }
    }
    return FALSE;
}

ViewportDlgProc* GetViewportDlgProc() {
    static ViewportDlgProc theMaxKrakatoaVolumeObjectDlgProc;
    return &theMaxKrakatoaVolumeObjectDlgProc;
}

enum { kMainBlockID };

enum { kMainRollout, kSeedingRollout, kViewportRollout, kMiscRollout };

MaxKrakatoaVolumeObjectDesc::MaxKrakatoaVolumeObjectDesc()
    : m_paramDesc( kMainBlockID, _T("Parameters"), NULL, MaxKrakatoaVolumeObject_VERSION ) {
    m_paramDesc.OwnerClassDesc( this );
    m_paramDesc.OwnerRefNum( 0 );

    m_paramDesc.RolloutTemplate( kMainRollout, IDD_PRTVOXEL_VOLUME_MAIN, IDS_PRTVOXEL_ROLLOUT_NAME, GetMainDlgProc() );
    m_paramDesc.RolloutTemplate( kSeedingRollout, IDD_PRTVOXEL_RENDERSETTINGS, IDS_PRTVOXEL_SEEDING );
    m_paramDesc.RolloutTemplate( kViewportRollout, IDD_PRTVOXEL_VIEWPORTSETTINGS, IDS_PRTVOXEL_VIEWPORT,
                                 GetViewportDlgProc() );
    m_paramDesc.RolloutTemplate( kMiscRollout, IDD_PRTVOXEL_VOLUME_MISC, IDS_PRTVOXEL_MISC );

    //------------------------------------------------------------------------------------------------------------------------------------------------------------------
    // Main rollout parameters
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------
    m_paramDesc.Parameter<INode*>( kTargetNode, _T("TargetNode"), NULL )
        .PickNodeButtonUI( kMainRollout, IDC_PRTVOXEL_VOLUME_TARGETNODE_PICK, NULL );

    m_paramDesc.Parameter<float>( kVoxelLength, _T("VoxelLength"), IDS_VOLUME_VOXELLENGTH, true, P_RESET_DEFAULT )
        .DefaultValue( 1.f )
        .Range( 0.0001f, FLT_MAX )
        .Units( frantic::max3d::parameter_units::world )
        .SpinnerUI( kMainRollout, EDITTYPE_POS_UNIVERSE, IDC_PRTVOXEL_VOLUME_SPACING_EDIT,
                    IDC_PRTVOXEL_VOLUME_SPACING_SPIN );

    m_paramDesc.Parameter<bool>( kUseViewportVoxelLength, _T("UseViewportVoxelLength"), NULL, false, P_RESET_DEFAULT )
        .DefaultValue( true )
        .CheckBoxUI( kMainRollout, IDC_PRTVOXEL_VOLUME_VIEWPORTSPACING_CHECK );

    m_paramDesc
        .Parameter<float>( kViewportVoxelLength, _T("ViewportVoxelLength"), IDS_VOLUME_VIEWPORTVOXELLENGTH, true,
                           P_RESET_DEFAULT )
        .DefaultValue( 3.f )
        .Range( 0.0001f, FLT_MAX )
        .Units( frantic::max3d::parameter_units::world )
        .SpinnerUI( kMainRollout, EDITTYPE_POS_UNIVERSE, IDC_PRTVOXEL_VOLUME_VIEWPORTSPACING_EDIT,
                    IDC_PRTVOXEL_VOLUME_VIEWPORTSPACING_SPIN );

    m_paramDesc.Parameter<bool>( kInWorldSpace, _T("InWorldSpace"), NULL, false, P_RESET_DEFAULT )
        .DefaultValue( false )
        .CheckBoxUI( kMainRollout, IDC_PRTVOXEL_VOLUME_WORLDSPACE_CHECK );

    // NOTE: Not exposed in the UI. The default is false (so existing scenes will get the default I think). In the
    // constructor for non-loading objects I set this to true.
    m_paramDesc.Parameter<bool>( kUseDensityCompensation, _T("UseDensityCompensation"), NULL ).DefaultValue( false );

    // NOTE: Not exposed in the UI.
    m_paramDesc.Parameter<bool>( kDisableVertexVelocity, _T("DisableVertexVelocity"), NULL ).DefaultValue( false );

    //------------------------------------------------------------------------------------------------------------------------------------------------------------------
    // Seeding rollout parameters
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------
    m_paramDesc.Parameter<int>( kSeedingMode, _T(""), NULL, false, P_OBSOLETE ); // ?

    m_paramDesc.Parameter<bool>( kSubdivideEnabled, _T("SubdivideEnabled"), NULL )
        .DefaultValue( false )
        .CheckBoxUI( kSeedingRollout, IDC_PRTVOXEL_SUBDIVISIONS_CHECK );

    m_paramDesc.Parameter<int>( kSubdivideCount, _T("SubdivideCount"), NULL )
        .DefaultValue( 1 )
        .Range( 1, INT_MAX )
        .SpinnerUI( kSeedingRollout, EDITTYPE_POS_INT, IDC_PRTVOXEL_SUBDIVISIONS_EDIT, IDC_PRTVOXEL_SUBDIVISIONS_SPIN );

    m_paramDesc.Parameter<bool>( kJitterSample, _T("JitterSamples"), NULL )
        .DefaultValue( true )
        .CheckBoxUI( kSeedingRollout, IDC_PRTVOXEL_JITTER_CHECK );

    m_paramDesc.Parameter<bool>( kJitterWellDistributed, _T("JitterWellDistributed"), NULL )
        .DefaultValue( false )
        .CheckBoxUI( kSeedingRollout, IDC_PRTVOXEL_JITTERWELLDISTRIBUTED_CHECK );

    m_paramDesc.Parameter<bool>( kMultiplePerRegion, _T("MultiplePerRegion"), NULL )
        .DefaultValue( false )
        .CheckBoxUI( kSeedingRollout, IDC_PRTVOXEL_MULTIPLECOUNT_CHECK );

    m_paramDesc.Parameter<int>( kMultipleCount, _T("MultiplePerRegionCount"), NULL )
        .DefaultValue( 2 )
        .Range( 2, INT_MAX )
        .SpinnerUI( kSeedingRollout, EDITTYPE_POS_INT, IDC_PRTVOXEL_MULTIPLECOUNT_EDIT,
                    IDC_PRTVOXEL_MULTIPLECOUNT_SPIN );

    m_paramDesc.Parameter<int>( kRandomSeed, _T("RandomSeed"), IDS_VOLUME_RANDOMSEED, true, P_RESET_DEFAULT )
        .DefaultValue( 42 )
        .Range( 0, INT_MAX )
        .SpinnerUI( kSeedingRollout, EDITTYPE_POS_INT, IDC_PRTVOXEL_RANDOMSEED_EDIT, IDC_PRTVOXEL_RANDOMSEED_SPIN );

    m_paramDesc.Parameter<int>( kRandomCount, _T("RandomCount"), NULL )
        .DefaultValue( 1024 )
        .Range( 1, INT_MAX )
        .SpinnerUI( kSeedingRollout, EDITTYPE_POS_INT, IDC_PRTVOXEL_RANDOMCOUNT_EDIT, IDC_PRTVOXEL_RANDOMCOUNT_SPIN );

    //------------------------------------------------------------------------------------------------------------------------------------------------------------------
    // Viewport rollout parameters
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------
    m_paramDesc.Parameter<bool>( kViewportEnabled, _T("ViewportEnabled"), NULL )
        .DefaultValue( true )
        .CheckBoxUI( kViewportRollout, IDC_PRTVOXEL_VIEWPORTENABLED_CHECK );

    m_paramDesc.Parameter<bool>( kViewportDisableSubdivision, _T("ViewportDisableSubdivision"), NULL )
        .DefaultValue( true )
        .CheckBoxUI( kViewportRollout, IDC_PRTVOXEL_DISABLESUBDIVISION_CHECK );

    m_paramDesc.Parameter<bool>( kViewportUsePercentage, _T("ViewportUsePercentage"), NULL )
        .DefaultValue( false )
        .CheckBoxUI( kViewportRollout, IDC_PRTVOXEL_LOADPERCENTAGE_CHECK );

    m_paramDesc.Parameter<float>( kViewportPercentage, _T("ViewportPercentage"), NULL, false, P_RESET_DEFAULT )
        .DefaultValue( .1f )
        .Units( frantic::max3d::parameter_units::percentage )
        .SpinnerUI( kViewportRollout, EDITTYPE_POS_FLOAT, IDC_PRTVOXEL_LOADPERCENTAGE_EDIT,
                    IDC_PRTVOXEL_LOADPERCENTAGE_SPIN );

    m_paramDesc.Parameter<bool>( kViewportUseLimit, _T("ViewportUseLimit"), NULL )
        .DefaultValue( false )
        .CheckBoxUI( kViewportRollout, IDC_PRTVOXEL_LOADLIMIT_CHECK );

    m_paramDesc.Parameter<float>( kViewportLimit, _T("ViewportLimit"), NULL, false, P_RESET_DEFAULT )
        .DefaultValue( 1000.f )
        .Range( 0.f, FLT_MAX )
        .SpinnerUI( kViewportRollout, EDITTYPE_POS_FLOAT, IDC_PRTVOXEL_LOADLIMIT_EDIT, IDC_PRTVOXEL_LOADLIMIT_SPIN );

    m_paramDesc.Parameter<bool>( kViewportIgnoreMaterial, _T("ViewportIgnoreMaterial"), NULL )
        .DefaultValue( false )
        .CheckBoxUI( kViewportRollout, IDC_PRTVOXEL_IGNOREMATERIAL_CHECK );

    m_paramDesc.Parameter<float>( kIconSize, _T("IconSize"), NULL, false, P_RESET_DEFAULT )
        .DefaultValue( 30.f )
        .Range( 0.f, FLT_MAX )
        .SpinnerUI( kViewportRollout, EDITTYPE_POS_FLOAT, IDC_PRTVOXEL_ICONSIZE_EDIT, IDC_PRTVOXEL_ICONSIZE_SPIN );

    //------------------------------------------------------------------------------------------------------------------------------------------------------------------
    // Misc rollout parameters
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------
    int childControlIDs[] = { kShellStart, kShellThickness };

    m_paramDesc.Parameter<bool>( kUseShell, _T("UseShell"), NULL, false, P_RESET_DEFAULT )
        .DefaultValue( false )
        .CheckBoxUI( kMiscRollout, IDC_PRTVOXEL_VOLUME_SEEDINSHELL_CHECK, childControlIDs );

    m_paramDesc.Parameter<float>( kShellStart, _T("ShellStart"), NULL, true )
        .DefaultValue( 0.f )
        .Range( 0.f, FLT_MAX )
        .SpinnerUI( kMiscRollout, EDITTYPE_POS_FLOAT, IDC_PRTVOXEL_VOLUME_SHELLSTART_EDIT,
                    IDC_PRTVOXEL_VOLUME_SHELLSTART_SPIN );

    m_paramDesc.Parameter<float>( kShellThickness, _T("ShellThickness"), NULL, true )
        .DefaultValue( 1.f )
        .Range( 0.f, FLT_MAX )
        .SpinnerUI( kMiscRollout, EDITTYPE_POS_FLOAT, IDC_PRTVOXEL_VOLUME_SHELLTHICKNESS_EDIT,
                    IDC_PRTVOXEL_VOLUME_SHELLTHICKNESS_SPIN );
}

ClassDesc2* MaxKrakatoaVolumeObject::GetClassDesc() { return GetMaxKrakatoaVolumeObjectDesc(); }

bool MaxKrakatoaVolumeObject::InWorldSpace() const { return ( m_pblock->GetInt( kInWorldSpace ) != FALSE ); }

Mesh* MaxKrakatoaVolumeObject::GetIconMesh( Matrix3& outTM ) {
    float iconSize = m_pblock->GetFloat( kIconSize );

    outTM.SetScale( Point3( iconSize, iconSize, iconSize ) );
    return GetPRTVolumeIconMesh();
}
#if MAX_VERSION_MAJOR >= 25
MaxSDK::SharedMeshPtr MaxKrakatoaVolumeObject::GetIconMeshShared( Matrix3& outTM ) {
    float iconSize = m_pblock->GetFloat( kIconSize );

    outTM.SetScale( Point3( iconSize, iconSize, iconSize ) );
    return GetPRTVolumeIconMeshShared();
}
#endif

MaxKrakatoaVolumeObject::MaxKrakatoaVolumeObject( bool loading ) {
    m_pblock = NULL;
    GetMaxKrakatoaVolumeObjectDesc()->MakeAutoParamBlocks( this );

    // Set defaults for new (ie. non loaded) objects, since scenes that are being loaded will have their paramblocks
    // clobbered after this point.
    if( !loading )
        m_pblock->SetValue( kUseDensityCompensation, 0, TRUE );

    // init data members
    m_levelsetBounds.Init();
    m_meshValidity.SetEmpty();
    m_voxelSpacing = 0.0f;
    m_doJitter = false;
    m_randomSeed = 0;
    m_randomCount = 0;
    m_jitterWellDistributed = false;
}

MaxKrakatoaVolumeObject::~MaxKrakatoaVolumeObject() {}

void MaxKrakatoaVolumeObject::SetIconSize( float scale ) { m_pblock->SetValue( kIconSize, 0, scale ); }

particle_istream_ptr
MaxKrakatoaVolumeObject::GetInternalStream( INode* /*pNode*/, TimeValue t, Interval& inoutValidity,
                                            frantic::max3d::particles::IMaxKrakatoaPRTEvalContextPtr pEvalContext ) {
    // make sure we're working with the latest m_pLevelset and m_voxelSampler. these calls will ensure that (rebuilding
    // them only if needed).
    CacheLevelset( t, pEvalContext->GetProgressLogger() );
    CacheVoxelSampler( t );

    inoutValidity &= Interval( t, t );

    if( !m_pLevelset )
        return boost::shared_ptr<particle_istream>( new empty_particle_istream( pEvalContext->GetDefaultChannels() ) );

    // get some user variables for the stream object
    float outerDistance = m_pblock->GetFloat( kShellStart, t );
    float innerDistance = outerDistance + m_pblock->GetFloat( kShellThickness, t );
    if( !m_pblock->GetInt( kUseShell ) ) {
        outerDistance = 0.f;
        innerDistance = std::numeric_limits<float>::max();
    }
    bool useDensityCompensation = ( FALSE != m_pblock->GetInt( kUseDensityCompensation ) );

    // create stream from cached m_pLevelset and m_voxelSampler.
    boost::shared_ptr<particle_istream> pin =
        boost::shared_ptr<particle_istream>( new frantic::particles::streams::rle_levelset_particle_istream(
            pEvalContext->GetDefaultChannels(), m_pLevelset, m_voxelSampler, -innerDistance, -outerDistance,
            useDensityCompensation ) );

    // apply fractional stream for viewports.
    if( !m_inRenderMode ) {
        double viewFraction = 1.f;
        boost::int64_t viewLimit = std::numeric_limits<boost::int64_t>::max();
        if( m_pblock->GetInt( kViewportUsePercentage ) )
            viewFraction = m_pblock->GetFloat( kViewportPercentage );
        if( m_pblock->GetInt( kViewportUseLimit ) )
            viewLimit = static_cast<boost::int64_t>( 1000.0 * m_pblock->GetFloat( kViewportLimit ) );
        pin = apply_fractional_particle_istream( pin, viewFraction, viewLimit, true );
    }

    return pin;
}

void MaxKrakatoaVolumeObject::CacheLevelset(
    TimeValue t, frantic::logging::progress_logger& progressLogger ) { // TODO: REMOVE THIS FUNCTION?

    // This is the only parameter that affects the object's validity interval.
    float voxelSpacing;
    if( m_inRenderMode || !m_pblock->GetInt( kUseViewportVoxelLength ) )
        voxelSpacing = m_pblock->GetFloat( kVoxelLength, t );
    else
        voxelSpacing = m_pblock->GetFloat( kViewportVoxelLength, t );

    // check to see if we can return, if the voxel length has changed, or if the mesh we used to make the levelset is no
    // longer valid at the current time.
    if( m_pLevelset && voxelSpacing == m_voxelSpacing && m_meshValidity.InInterval( t ) )
        return;

    // cache the voxel spacing value, so we know when to reevaluate if it changes
    m_voxelSpacing = voxelSpacing;

    m_pLevelset.reset();
    m_levelsetBounds.Init();
    m_meshValidity.Set( t, t ); // this will be modified later if we could actually get a mesh from the object

    INode* pNode = m_pblock->GetINode( kTargetNode );
    if( !pNode )
        return;

    if( ( !m_inRenderMode && m_pblock->GetInt( kViewportEnabled ) == FALSE ) || m_voxelSpacing <= 0.f )
        return;

    class MyView : public frantic::max3d::geometry::null_view {
        frantic::logging::progress_logger* m_progLog;

      public:
        MyView( frantic::logging::progress_logger& progLog )
            : m_progLog( &progLog ) {}

        virtual ~MyView() {}

        virtual BOOL CheckForRenderAbort() {
            try {
                m_progLog->check_for_abort();
            } catch( const frantic::logging::progress_cancel_exception& ) {
                return TRUE;
            }
            return FALSE;
        }
    } theView( progressLogger );

    ObjectState os = pNode->EvalWorldState( t );

    Box3 meshBounds;
    Mesh* pMesh = NULL;
    GeomObject* pGeomObj = NULL;
    BOOL needsObjDelete = FALSE;
    BOOL needsMeshDelete = FALSE;

    if( os.obj->IsSubClassOf( triObjectClassID ) )
        pGeomObj = static_cast<TriObject*>( os.obj );
    else {
        if( !os.obj->CanConvertToType( triObjectClassID ) )
            return;
        pGeomObj = (TriObject*)os.obj->ConvertToType( t, triObjectClassID );
        needsObjDelete = ( pGeomObj != os.obj );
    }

    m_meshValidity = os.obj->ObjectValidity( t );

    frantic::geometry::trimesh3 theTriMesh;
    try {
        pMesh = pGeomObj->GetRenderMesh( t, pNode, theView, needsMeshDelete );

        if( this->InWorldSpace() ) {
            frantic::graphics::transform4f tm = frantic::max3d::from_max_t( pNode->GetObjectTM( t, &m_meshValidity ) );
            frantic::max3d::geometry::mesh_copy( theTriMesh, tm, *pMesh );
        } else {
            frantic::max3d::geometry::mesh_copy( theTriMesh, *pMesh );
        }

        if( needsObjDelete )
            pGeomObj->MaybeAutoDelete();
        if( needsMeshDelete )
            pMesh->DeleteThis();
    } catch( ... ) {
        // Doesn't matter what exception is thrown, we need to clean up these temporaries.
        if( needsObjDelete )
            pGeomObj->MaybeAutoDelete();
        if( needsMeshDelete )
            pMesh->DeleteThis();
        throw;
    }

    bool doVelocity = ( m_pblock->GetInt( kDisableVertexVelocity ) == FALSE );

    if( doVelocity ) {
        // If the validity interval is non-instant then we can assume the velocity is 0. That being said, some objects
        // like to be weird and have a 2-tick validity interval so I consider small intervals the same as instant.
        // Looking at you PhoenixFD!
        if( m_meshValidity.End() - m_meshValidity.Start() > 3 ) {
            theTriMesh.add_vertex_channel<frantic::graphics::vector3f>( _T("Velocity") );

            frantic::geometry::trimesh3_vertex_channel_accessor<frantic::graphics::vector3f> velAcc =
                theTriMesh.get_vertex_channel_accessor<frantic::graphics::vector3f>( _T("Velocity") );
            for( std::size_t i = 0, iEnd = velAcc.size(); i < iEnd; ++i )
                velAcc[i].set( 0, 0, 0 );
        } else {
            TimeValue tFuture = t + GetTicksPerFrame() / 4; // Hard-coded quarter frame offset.

            os = pNode->EvalWorldState( tFuture );

            if( os.obj->IsSubClassOf( triObjectClassID ) )
                pGeomObj = static_cast<TriObject*>( os.obj );
            else {
                if( !os.obj->CanConvertToType( triObjectClassID ) )
                    return;
                pGeomObj = (TriObject*)os.obj->ConvertToType( tFuture, triObjectClassID );
                needsObjDelete = ( pGeomObj != os.obj );
            }

            try {
                pMesh = pGeomObj->GetRenderMesh( tFuture, pNode, theView, needsMeshDelete );

                if( this->InWorldSpace() ) {
                    frantic::graphics::transform4f tm = frantic::max3d::from_max_t( pNode->GetObjectTM( tFuture ) );
                    frantic::max3d::geometry::mesh_copy_velocity_to_mesh( theTriMesh, tm, *pMesh,
                                                                          TicksToSec( tFuture - t ) );
                } else {
                    frantic::graphics::transform4f tm; // Identity matrix.
                    frantic::max3d::geometry::mesh_copy_velocity_to_mesh( theTriMesh, tm, *pMesh,
                                                                          TicksToSec( tFuture - t ) );
                }

                if( needsObjDelete )
                    pGeomObj->MaybeAutoDelete();
                if( needsMeshDelete )
                    pMesh->DeleteThis();
            } catch( ... ) {
                // Doesn't matter what exception is thrown, we need to clean up these temporaries.
                if( needsObjDelete )
                    pGeomObj->MaybeAutoDelete();
                if( needsMeshDelete )
                    pMesh->DeleteThis();
                throw;
            }
        }
    }

    // TODO: Warn the user if they are about to make a terrible mistake . . .
    //       Potentially they are about to make a gigantic levelset.
    // pMesh->buildBoundingBox();
    // meshBounds = pMesh->getBoundingBox();

    // cache levelset and bounds to member variables
    m_pLevelset = krakatoa::get_particle_volume_levelset( theTriMesh, voxelSpacing, progressLogger );
    m_levelsetBounds = frantic::max3d::to_max_t( m_pLevelset->world_outer_bounds() );
}

void MaxKrakatoaVolumeObject::CacheVoxelSampler( TimeValue t ) {

    // make sure we're working with the latest voxel sampler. this call will set that.
    unsigned int subdivCount = 0;
    if( m_pblock->GetInt( kSubdivideEnabled ) &&
        ( m_inRenderMode || !m_pblock->GetInt( kViewportDisableSubdivision ) ) )
        subdivCount = (unsigned int)std::max( 1, m_pblock->GetInt( kSubdivideCount ) );
    bool doJitter = ( m_pblock->GetInt( kJitterSample ) != FALSE );
    int numPerVoxel = 1;
    if( doJitter && m_pblock->GetInt( kMultiplePerRegion ) &&
        ( m_inRenderMode || !m_pblock->GetInt( kViewportDisableSubdivision ) ) )
        numPerVoxel = std::max( 2, m_pblock->GetInt( kMultipleCount ) );
    unsigned int randomSeed = (unsigned int)m_pblock->GetInt( kRandomSeed, t );
    size_t randomCount = (size_t)m_pblock->GetInt( kRandomCount );
    bool jitterWellDistributed = m_pblock->GetInt( kJitterWellDistributed ) != FALSE;

    // We are more aggresive with our caching here, since it costs very little to change the subdivs, but ALOT to change
    // the jittered distribution (mostly due to jitterWellDistributed).
    if( m_voxelSampler && doJitter == m_doJitter ) {
        if( !doJitter || ( randomSeed == m_randomSeed && randomCount == m_randomCount &&
                           jitterWellDistributed == m_jitterWellDistributed ) ) {
            m_voxelSampler->set_subdivs( subdivCount, numPerVoxel );
            return;
        }
    }

    // compare previous values to current values, and see if we need to cache a new voxel sampler
    // if( m_voxelSampler && subdivCount == m_subdivCount && doJitter == m_doJitter && numPerVoxel == m_numPerVoxel &&
    // randomSeed == m_randomSeed && randomCount == m_randomCount && jitterWellDistributed == m_jitterWellDistributed )
    //	return;

    // create a new voxel sampler
    m_voxelSampler = krakatoa::get_particle_volume_voxel_sampler( subdivCount, doJitter, numPerVoxel, randomSeed,
                                                                  randomCount, jitterWellDistributed );

    // cache current voxel sampler variables
    m_doJitter = doJitter;
    m_randomSeed = randomSeed;
    m_randomCount = randomCount;
    m_jitterWellDistributed = jitterWellDistributed;
}

void MaxKrakatoaVolumeObject::PostLoadCallback( ILoad* iload ) {
    IParamBlock2PostLoadInfo* postLoadInfo =
        (IParamBlock2PostLoadInfo*)m_pblock->GetInterface( IPARAMBLOCK2POSTLOADINFO_ID );
    if( postLoadInfo && postLoadInfo->GetVersion() != MaxKrakatoaVolumeObject_VERSION ) {
        m_pblock->SetValue( kRandomCount, 0, 1024 );

        int mode = m_pblock->GetInt( kSeedingMode );
        if( mode == kSeedingModeRegularGrid ) {
            int subdivCount = m_pblock->GetInt( kSubdivideCount ) - 1;
            if( subdivCount <= 0 ) {
                m_pblock->SetValue( kSubdivideEnabled, 0, FALSE );
                m_pblock->SetValue( kSubdivideCount, 0, 1 );
            } else {
                m_pblock->SetValue( kSubdivideEnabled, 0, TRUE );
                m_pblock->SetValue( kSubdivideCount, 0, subdivCount );
            }
            m_pblock->SetValue( kJitterSample, 0, FALSE );
            m_pblock->SetValue( kJitterWellDistributed, 0, FALSE );
            m_pblock->SetValue( kMultiplePerRegion, 0, FALSE );
        } else if( mode == kSeedingModeRandom ) {
            int subdivCount = std::max( 1, m_pblock->GetInt( kSubdivideCount ) - 1 );
            m_pblock->SetValue( kSubdivideCount, 0, subdivCount );
            m_pblock->SetValue( kSubdivideEnabled, 0, FALSE );

            m_pblock->SetValue( kJitterSample, 0, TRUE );
            m_pblock->SetValue( kJitterWellDistributed, 0, TRUE );
            m_pblock->SetValue( kMultiplePerRegion, 0, TRUE );
        }

        iload->SetObsolete();
    }
}

#if MAX_VERSION_MAJOR >= 24
const TCHAR* MaxKrakatoaVolumeObject::GetObjectName( bool localized ) {
#elif MAX_VERSION_MAJOR >= 15
const TCHAR* MaxKrakatoaVolumeObject::GetObjectName() {
#else
TCHAR* MaxKrakatoaVolumeObject::GetObjectName() {
#endif
    return _T("PRTVolume");
}

class MaxKrakatoaVolumeObject_PLCB : public PostLoadCallback {
    MaxKrakatoaVolumeObject* m_pOwner;

  public:
    MaxKrakatoaVolumeObject_PLCB( MaxKrakatoaVolumeObject* pOwner )
        : m_pOwner( pOwner ) {}

    virtual ~MaxKrakatoaVolumeObject_PLCB() {}

    virtual void proc( ILoad* iload ) {
        m_pOwner->PostLoadCallback( iload );
        delete this;
    }

    virtual int Priority() { return 1; }
};

IOResult MaxKrakatoaVolumeObject::Load( ILoad* iload ) {
    iload->RegisterPostLoadCallback( new MaxKrakatoaVolumeObject_PLCB( this ) );
    return MaxKrakatoaPRTObject<MaxKrakatoaVolumeObject>::Load( iload );
}

RefResult MaxKrakatoaVolumeObject::NotifyRefChanged( const Interval& /*changeInt*/, RefTargetHandle hTarget,
                                                     PartID& partID, RefMessage message, BOOL /*propagate*/ ) {
    if( hTarget == m_pblock ) {
        int param = m_pblock->LastNotifyParamID();

        if( message == REFMSG_CHANGE ) {
            switch( param ) {
            case kInWorldSpace: // Intentional fallthrough
            case kDisableVertexVelocity:
            case kTargetNode:
                if( !( partID & PART_GEOM ) && !( m_pblock->GetInt( kInWorldSpace ) && ( partID & PART_TM ) ) )
                    return REF_STOP;
                m_pLevelset.reset(); // clear the current levelset so it must be rebuilt
                break;
            case kVoxelLength:
                if( !m_inRenderMode && m_pblock->GetInt( kUseViewportVoxelLength ) )
                    return REF_STOP;
                break;
            case kViewportVoxelLength:
                if( m_inRenderMode || !m_pblock->GetInt( kUseViewportVoxelLength ) )
                    return REF_STOP;
                break;
            case kViewportEnabled: // We want to disable or re-enable the levelset, so we need to clear the existing
                                   // one.
                if( m_inRenderMode )
                    return REF_STOP;
                m_pLevelset.reset();
                break;
            case kRandomSeed: // intentional fallthrough
            case kRandomCount:
                if( !m_pblock->GetInt( kJitterSample ) )
                    return REF_STOP;
                break;
            case kSubdivideCount:
                if( !m_pblock->GetInt( kSubdivideEnabled ) ||
                    ( !m_inRenderMode && m_pblock->GetInt( kViewportDisableSubdivision ) ) )
                    return REF_STOP;
                break;
            case kJitterWellDistributed: // intentional fallthrough
            case kMultiplePerRegion:
                if( !m_pblock->GetInt( kJitterSample ) )
                    return REF_STOP;
                break;
            case kMultipleCount:
                if( !m_pblock->GetInt( kMultiplePerRegion ) || !m_pblock->GetInt( kJitterSample ) ||
                    ( !m_inRenderMode && m_pblock->GetInt( kViewportDisableSubdivision ) ) )
                    return REF_STOP;
                break;
            case kIconSize:
                return REF_SUCCEED; // Skip invalidating any cache since its just the icon size changing
            default:
                break;
            }

            // force a viewport update if one of the above hasn't returned REF_STOP
            InvalidateViewport();
        }
    }

    return REF_SUCCEED;
}

void MaxKrakatoaVolumeObject::InitNodeName( MSTR& s ) { s = _T("PRT Volume"); }

void MaxKrakatoaVolumeObject::GetDeformBBox( TimeValue t, Box3& box, Matrix3* tm, BOOL /*useSel*/ ) {
    try {
        frantic::logging::null_progress_logger nullProgress;

        CacheLevelset( t, nullProgress );
        box = m_levelsetBounds;
        if( tm )
            box = box * ( *tm );
    } catch( const std::exception& e ) {
        FF_LOG( error ) << e.what() << std::endl;
    }
}
