// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0
#include "stdafx.h"
#if defined( FUMEFX_SDK_AVAILABLE )
#include "resource.h"

#include <frantic/graphics/poisson_sphere.hpp>
#include <frantic/particles/streams/apply_function_particle_istream.hpp>
#include <frantic/particles/streams/empty_particle_istream.hpp>
#include <frantic/particles/streams/fractional_particle_istream.hpp>
#include <frantic/particles/streams/selection_culled_particle_istream.hpp>
#include <frantic/particles/streams/set_channel_particle_istream.hpp>

#include <frantic/max3d/convert.hpp>
#include <frantic/max3d/geopipe/get_inodes.hpp>
#include <frantic/max3d/max_utility.hpp>
#include <frantic/max3d/particles/max3d_particle_utils.hpp>
#include <frantic/max3d/particles/modifier_utils.hpp>
#include <frantic/max3d/particles/streams/deformed_particle_istream.hpp>
#include <frantic/max3d/shaders/map_query.hpp>

#include "FumeFX\MaxKrakatoaFumeFXParticleIStream.h"
#include "MaxKrakatoaChannelModifier.h"
#include "MaxKrakatoaMaterial.hpp"
#include "MaxKrakatoaStdMaterialStream.h"
#include "Objects/MaxKrakatoaPRTInterface.h"
#include "krakatoa/particle_volume.hpp"

#pragma warning( push, 3 )
#include <boost/assign.hpp>
#include <boost/bind.hpp>
#include <boost/foreach.hpp>
#include <boost/random.hpp>
#include <boost/random/linear_congruential.hpp>
#pragma warning( pop )

#if MAX_VERSION_MAJOR >= 25
#include <SharedMesh.h>
#endif

#define FUME_FX_CLASS_ID Class_ID( 902511643, 1454773937 )

#define MaxKrakatoaFumeFXObject_NAME _T("PRT FumeFX")
//#define MaxKrakatoaFumeFXObject_CLASS_ID Class_ID(0x3a380a24, 0xb230c50)

extern Mesh* GetPRTFumeFXIconMesh();
#if MAX_VERSION_MAJOR >= 25
extern MaxSDK::SharedMeshPtr GetPRTFumeFXIconMeshShared();
#endif

#pragma warning( push )
#pragma warning( disable : 4100 )

namespace {
enum {
    kTargetNode,
    kRandomSeed,
    kRandomCount,
    kSubdivideEnabled,
    kSubdivideCount,
    kJitterSample,
    kJitterWellDistributed,
    kMultiplePerRegion,
    kMultipleCount,
    kSeedInSmoke,
    kSeedInSmokeMinimum,
    kSeedInFire,
    kSeedInFireMinimum,
    kEmissionEnabled,
    kDontUseThisItsDisabled1, // kEmissionColor,
    kEmissionColorMultiplier,
    // kDisabledChannels
    kDisableVelocity,
    kViewportEnabled,
    kViewportDisableSubdivision,
    kViewportUsePercentage,
    kViewportPercentage,
    kViewportUseLimit,
    kViewportLimit,
    kViewportIgnoreMaterial,
    kGenerateNormal,
    kIconSize,
    kFrameOffset,
    kLimitToCustomRange,
    kCustomRangeBegin,
    kCustomRangeEnd,
    kBelowRangePolicy,
    kAboveRangePolicy,
    kPlaybackGraphFrame,
    kUsePlaybackGraph
};
}

namespace detail {
// Just the playback graph frame
inline static TimeValue GetEffectiveTime( TimeValue sceneTime, IParamBlock2* pblock );
// Current frame after all retiming controls
static TimeValue CalculateCurrentFrame( TimeValue t, IParamBlock2* pblock );
// Is there a custom range, is the current frame outside of the custom range, and if so, is the policy to show a blank
// frame
static BOOL IsBlankFrame( TimeValue t, IParamBlock2* pblock );
// Is the policy to hold a frame below the custom range
inline static BOOL HoldLowerFrame( IParamBlock2* pblock );
// Is the policy to hold a frame above the custom range
inline static BOOL HoldUpperFrame( IParamBlock2* pblock );
// If there's a custom range, what's the lower bound, otherwise INT_MIN
inline static TimeValue FrameRangeBottom( IParamBlock2* pblock );
// If there's a custom range, what's the upper bound, otherwise INT_MAX
inline static TimeValue FrameRangeTop( IParamBlock2* pblock );

inline static TimeValue GetEffectiveTime( TimeValue sceneTime, IParamBlock2* pblock ) {
    const BOOL usePlaybackGraph = static_cast<BOOL>( pblock->GetInt( kUsePlaybackGraph ) );
    if( usePlaybackGraph ) {
        return static_cast<TimeValue>( pblock->GetFloat( kPlaybackGraphFrame, sceneTime ) * GetTicksPerFrame() );
    }

    return sceneTime;
}

static TimeValue CalculateCurrentFrame( TimeValue t, IParamBlock2* pblock ) {
    const TimeValue frameOffset = pblock->GetTimeValue( kFrameOffset );
    const BOOL useCustomRange = pblock->GetInt( kLimitToCustomRange );
    TimeValue result = GetEffectiveTime( t, pblock ) + frameOffset;
    if( useCustomRange ) {
        const TimeValue lowerBound = pblock->GetTimeValue( kCustomRangeBegin );
        const TimeValue upperBound = pblock->GetTimeValue( kCustomRangeEnd );

        if( result < lowerBound && HoldLowerFrame( pblock ) ) {
            result = lowerBound;
        }

        if( result > upperBound && HoldUpperFrame( pblock ) ) {
            result = upperBound;
        }
    }

    return result;
}

static BOOL IsBlankFrame( TimeValue t, IParamBlock2* pblock ) {
    const BOOL holdLower = HoldLowerFrame( pblock );
    const BOOL holdUpper = HoldUpperFrame( pblock );
    const BOOL useCustomRange = pblock->GetInt( kLimitToCustomRange );

    if( ( holdLower && holdUpper ) || !useCustomRange ) {
        return FALSE;
    }

    const TimeValue frameOffset = pblock->GetTimeValue( kFrameOffset );
    const TimeValue currentFrame = GetEffectiveTime( t, pblock ) + frameOffset;
    const TimeValue lowerBound = pblock->GetTimeValue( kCustomRangeBegin );
    const TimeValue upperBound = pblock->GetTimeValue( kCustomRangeEnd );

    if( !holdLower && currentFrame < lowerBound ) {
        return TRUE;
    }

    if( !holdUpper && currentFrame > upperBound ) {
        return TRUE;
    }

    return FALSE;
}

inline static BOOL HoldLowerFrame( IParamBlock2* pblock ) {
    const BOOL useCustomRange = pblock->GetInt( kLimitToCustomRange );
    if( useCustomRange ) {
        return !pblock->GetInt( kBelowRangePolicy );
    }
    return FALSE;
}

inline static BOOL HoldUpperFrame( IParamBlock2* pblock ) {
    const BOOL useCustomRange = pblock->GetInt( kLimitToCustomRange );
    if( useCustomRange ) {
        return !pblock->GetInt( kAboveRangePolicy );
    }
    return FALSE;
}

inline static TimeValue FrameRangeBottom( IParamBlock2* pblock ) {
    const BOOL useCustomRange = pblock->GetTimeValue( kLimitToCustomRange );
    if( useCustomRange ) {
        return pblock->GetTimeValue( kCustomRangeBegin );
    }
    return INT_MIN;
}

inline static TimeValue FrameRangeTop( IParamBlock2* pblock ) {
    const BOOL useCustomRange = pblock->GetTimeValue( kLimitToCustomRange );
    if( useCustomRange ) {
        return pblock->GetTimeValue( kCustomRangeEnd );
    }
    return INT_MAX;
}
} // namespace detail

class MaxKrakatoaFumeFXObject : public MaxKrakatoaPRTObject<MaxKrakatoaFumeFXObject> {
    std::size_t m_requestedPoissonSamples; // For determining if the cache is valid since the actual number may differ.
    std::vector<frantic::graphics::vector3f> m_poissonSamples;

  protected:
    virtual Mesh* GetIconMesh( Matrix3& outTM );
#if MAX_VERSION_MAJOR >= 25
    virtual MaxSDK::SharedMeshPtr GetIconMeshShared( Matrix3& outTM );
#endif
    virtual ClassDesc2* GetClassDesc();

  public:
    MaxKrakatoaFumeFXObject();
    virtual ~MaxKrakatoaFumeFXObject() {}

    // From MaxKrakatoaPRTObject
    virtual void SetIconSize( float size );

    virtual particle_istream_ptr GetInternalStream( INode* pNode, TimeValue t, Interval& outValidity,
                                                    boost::shared_ptr<IEvalContext> pEvalContext );

    // From Animatable

    // From ReferenceMaker
    virtual RefResult NotifyRefChanged( const Interval& changeInt, RefTargetHandle hTarget, PartID& partID,
                                        RefMessage message, BOOL propagate );

    // From BaseObject
#if MAX_VERSION_MAJOR >= 24
    virtual const MCHAR* GetObjectName( bool localized );
#elif MAX_VERSION_MAJOR >= 15
    virtual const MCHAR* GetObjectName();
#else
    virtual MCHAR* GetObjectName();
#endif

    // From Object
    virtual void InitNodeName( MSTR& s );
    virtual void GetDeformBBox( TimeValue t, Box3& box, Matrix3* tm = NULL, BOOL useSel = FALSE );
    virtual Interval ObjectValidity( TimeValue t );
};

class MainPanelDialogProc : public ParamMap2UserDlgProc {
    static MainPanelDialogProc s_theMainPanelDialogProc;

  public:
    static MainPanelDialogProc* GetInstance() { return &s_theMainPanelDialogProc; }

    virtual ~MainPanelDialogProc() {}

    virtual void DeleteThis() {}

    virtual INT_PTR DlgProc( TimeValue t, IParamMap2* map, HWND hWnd, UINT msg, WPARAM wParam, LPARAM lParam );
    virtual void Update( TimeValue t, Interval& valid, IParamMap2* pmap );

  private:
    inline void EnableTimingControls( BOOL enable, const HWND& dialog );
    inline void EnablePlaybackGraphControls( BOOL enable, const HWND& dialog );
    inline void EnableSpinner( INT idc, BOOL enable, const HWND& dialog );
    void UpdateLoadingFrame( IParamBlock2* pblock, TimeValue t, HWND& dialog );
};

MainPanelDialogProc MainPanelDialogProc::s_theMainPanelDialogProc;

class ViewportPanelDialogProc : public ParamMap2UserDlgProc {
    static ViewportPanelDialogProc s_theViewportPanelDialogProc;

  public:
    static ViewportPanelDialogProc* GetInstance() { return &s_theViewportPanelDialogProc; }

    virtual ~ViewportPanelDialogProc() {}

    virtual void DeleteThis() {}

    virtual INT_PTR DlgProc( TimeValue t, IParamMap2* map, HWND hWnd, UINT msg, WPARAM wParam, LPARAM lParam );
};

ViewportPanelDialogProc ViewportPanelDialogProc::s_theViewportPanelDialogProc;

class MaxKrakatoaFumeFXObjectTimingAccessor : public PBAccessor {
  public:
    virtual void Set( PB2Value& v, ReferenceMaker* owner, ParamID id, int tabIndex, TimeValue t ) {
        // Make sure the custom range always begins at value lower than or equal to where it ends.
        IParamBlock2* pblock = owner->GetParamBlock( 0 );

        switch( id ) {
        case kCustomRangeBegin: {
            TimeValue end = pblock->GetTimeValue( kCustomRangeEnd );
            if( v.t > end ) {
                pblock->SetValue( kCustomRangeEnd, 0, v.t );
            }
            break;
        }

        case kCustomRangeEnd: {
            TimeValue begin = pblock->GetTimeValue( kCustomRangeBegin );
            if( v.t < begin ) {
                pblock->SetValue( kCustomRangeBegin, 0, v.t );
            }
            break;
        }
        default:
            break;
        }
    }
    virtual void DeleteThis() {}
};

PBAccessor* GetMaxKrakatoaFumeFXObjectTimingAccessor() {
    static MaxKrakatoaFumeFXObjectTimingAccessor theMaxKrakatoaFumeFXObjectAccessor;
    return &theMaxKrakatoaFumeFXObjectAccessor;
}

class MaxKrakatoaFumeFXObjectDesc : public ClassDesc2 {
    ParamBlockDesc2* m_pParamDesc;

  public:
    MaxKrakatoaFumeFXObjectDesc();
    virtual ~MaxKrakatoaFumeFXObjectDesc();

    int IsPublic() { return TRUE; }
    void* Create( BOOL /*loading*/ ) { return new MaxKrakatoaFumeFXObject; }
    const TCHAR* ClassName() { return MaxKrakatoaFumeFXObject_NAME; }
#if MAX_VERSION_MAJOR >= 24
    const TCHAR* NonLocalizedClassName() { return MaxKrakatoaFumeFXObject_NAME; }
#endif
    SClass_ID SuperClassID() { return GEOMOBJECT_CLASS_ID; }
    Class_ID ClassID() { return MaxKrakatoaFumeFXObject_CLASS_ID; }
    const TCHAR* Category() { return _T("Krakatoa"); }

    // returns fixed parsable name (scripter-visible name)
    const TCHAR* InternalName() { return MaxKrakatoaFumeFXObject_NAME; }
    HINSTANCE HInstance() { return hInstance; } // returns owning module handle
};

ClassDesc2* GetMaxKrakatoaFumeFXObjectDesc() {
    static MaxKrakatoaFumeFXObjectDesc theDesc;
    return &theDesc;
}

MaxKrakatoaFumeFXObjectDesc::MaxKrakatoaFumeFXObjectDesc() {
    m_pParamDesc = new ParamBlockDesc2(
        0,                                         // Block num
        _T("Parameters"),                          // Internal name
        NULL,                                      // Localized name
        this,                                      // ClassDesc2*
        P_AUTO_CONSTRUCT + P_AUTO_UI + P_MULTIMAP, // Flags
        0,                                         // PBlock Ref Num
        4,                                         // Number of rollup panels
        0, IDD_PRTVOXEL_FUMEFX_MAIN, IDS_PRTVOXEL_SOURCE, 0, 0,
        MainPanelDialogProc::GetInstance(),                               // AutoUI stuff for panel 0
        1, IDD_PRTVOXEL_RENDERSETTINGS, IDS_PRTVOXEL_SEEDING, 0, 0, NULL, // AutoUI stuff for panel 1
        2, IDD_PRTVOXEL_VIEWPORTSETTINGS, IDS_PRTVOXEL_VIEWPORT, 0, 0,
        ViewportPanelDialogProc::GetInstance(),                     // AutoUI stuff for panel 2
        3, IDD_PRTVOXEL_FUMEFX_MISC, IDS_PRTVOXEL_MISC, 0, 0, NULL, // AutoUI stuff for panel 3
        p_end );

    m_pParamDesc->AddParam( kTargetNode, _T("TargetNode"), TYPE_INODE, 0, 0, p_end );
    m_pParamDesc->ParamOption( kTargetNode, p_classID, FUME_FX_CLASS_ID, p_end );
    m_pParamDesc->ParamOption( kTargetNode, p_ui, 0, TYPE_PICKNODEBUTTON, IDC_PRTVOXEL_FUMEFX_TARGETNODE_PICK, p_end );
    // m_pParamDesc->ParamOption(kTargetNode, p_accessor, GetMaxKrakatoaHairObjectAccessor());

    m_pParamDesc->AddParam( kRandomSeed, _T("RandomSeed"), TYPE_INT, P_RESET_DEFAULT, 0, p_end );
    m_pParamDesc->ParamOption( kRandomSeed, p_default, 42 );
    m_pParamDesc->ParamOption( kRandomSeed, p_range, 0, INT_MAX );
    m_pParamDesc->ParamOption( kRandomSeed, p_ui, 1, TYPE_SPINNER, EDITTYPE_POS_INT, IDC_PRTVOXEL_RANDOMSEED_EDIT,
                               IDC_PRTVOXEL_RANDOMSEED_SPIN, SPIN_AUTOSCALE, p_end );

    m_pParamDesc->AddParam( kRandomCount, _T("RandomCount"), TYPE_INT, 0, 0, p_end );
    m_pParamDesc->ParamOption( kRandomCount, p_default, 1024 );
    m_pParamDesc->ParamOption( kRandomCount, p_range, 1, INT_MAX );
    m_pParamDesc->ParamOption( kRandomCount, p_ui, 1, TYPE_SPINNER, EDITTYPE_POS_INT, IDC_PRTVOXEL_RANDOMCOUNT_EDIT,
                               IDC_PRTVOXEL_RANDOMCOUNT_SPIN, SPIN_AUTOSCALE, p_end );

    m_pParamDesc->AddParam( kSubdivideEnabled, _T("SubdivideEnabled"), TYPE_BOOL, 0, 0, p_end );
    m_pParamDesc->ParamOption( kSubdivideEnabled, p_default, FALSE );
    m_pParamDesc->ParamOption( kSubdivideEnabled, p_ui, 1, TYPE_SINGLECHEKBOX, IDC_PRTVOXEL_SUBDIVISIONS_CHECK, p_end );

    m_pParamDesc->AddParam( kSubdivideCount, _T("SubdivideCount"), TYPE_INT, 0, 0, p_end );
    m_pParamDesc->ParamOption( kSubdivideCount, p_default, 1 );
    m_pParamDesc->ParamOption( kSubdivideCount, p_range, 1, INT_MAX );
    m_pParamDesc->ParamOption( kSubdivideCount, p_ui, 1, TYPE_SPINNER, EDITTYPE_POS_INT, IDC_PRTVOXEL_SUBDIVISIONS_EDIT,
                               IDC_PRTVOXEL_SUBDIVISIONS_SPIN, SPIN_AUTOSCALE, p_end );

    m_pParamDesc->AddParam( kJitterSample, _T("JitterSamples"), TYPE_BOOL, 0, 0, p_end );
    m_pParamDesc->ParamOption( kJitterSample, p_default, TRUE );
    m_pParamDesc->ParamOption( kJitterSample, p_ui, 1, TYPE_SINGLECHEKBOX, IDC_PRTVOXEL_JITTER_CHECK, p_end );

    m_pParamDesc->AddParam( kJitterWellDistributed, _T("JitterWellDistributed"), TYPE_BOOL, 0, 0, p_end );
    m_pParamDesc->ParamOption( kJitterWellDistributed, p_default, FALSE );
    m_pParamDesc->ParamOption( kJitterWellDistributed, p_ui, 1, TYPE_SINGLECHEKBOX,
                               IDC_PRTVOXEL_JITTERWELLDISTRIBUTED_CHECK, p_end );

    m_pParamDesc->AddParam( kMultiplePerRegion, _T("MultiplePerRegion"), TYPE_BOOL, 0, 0, p_end );
    m_pParamDesc->ParamOption( kMultiplePerRegion, p_default, FALSE );
    m_pParamDesc->ParamOption( kMultiplePerRegion, p_ui, 1, TYPE_SINGLECHEKBOX, IDC_PRTVOXEL_MULTIPLECOUNT_CHECK,
                               p_end );

    m_pParamDesc->AddParam( kMultipleCount, _T("MultiplePerRegionCount"), TYPE_INT, 0, 0, p_end );
    m_pParamDesc->ParamOption( kMultipleCount, p_default, 2 );
    m_pParamDesc->ParamOption( kMultipleCount, p_range, 2, INT_MAX );
    m_pParamDesc->ParamOption( kMultipleCount, p_ui, 1, TYPE_SPINNER, EDITTYPE_POS_INT, IDC_PRTVOXEL_MULTIPLECOUNT_EDIT,
                               IDC_PRTVOXEL_MULTIPLECOUNT_SPIN, SPIN_AUTOSCALE, p_end );

    m_pParamDesc->AddParam( kSeedInSmoke, _T("SeedInSmoke"), TYPE_BOOL, 0, 0, p_end );
    m_pParamDesc->ParamOption( kSeedInSmoke, p_default, TRUE );
    m_pParamDesc->ParamOption( kSeedInSmoke, p_ui, 0, TYPE_SINGLECHEKBOX, IDC_PRTVOXEL_FUMEFX_SEEDINSMOKE_CHECK,
                               p_end );

    m_pParamDesc->AddParam( kSeedInSmokeMinimum, _T("SeedInSmokeMinimum"), TYPE_FLOAT, 0, 0, p_end );
    m_pParamDesc->ParamOption( kSeedInSmokeMinimum, p_default, 0.01f );
    m_pParamDesc->ParamOption( kSeedInSmokeMinimum, p_range, 0.f, FLT_MAX );
    m_pParamDesc->ParamOption( kSeedInSmokeMinimum, p_ui, 0, TYPE_SPINNER, EDITTYPE_POS_FLOAT,
                               IDC_PRTVOXEL_FUMEFX_SEEDINSMOKE_EDIT, IDC_PRTVOXEL_FUMEFX_SEEDINSMOKE_SPIN,
                               SPIN_AUTOSCALE, p_end );

    m_pParamDesc->AddParam( kSeedInFire, _T("SeedInFire"), TYPE_BOOL, 0, 0, p_end );
    m_pParamDesc->ParamOption( kSeedInFire, p_default, TRUE );
    m_pParamDesc->ParamOption( kSeedInFire, p_ui, 0, TYPE_SINGLECHEKBOX, IDC_PRTVOXEL_FUMEFX_SEEDINFIRE_CHECK, p_end );

    m_pParamDesc->AddParam( kSeedInFireMinimum, _T("SeedInFireMinimum"), TYPE_FLOAT, 0, 0, p_end );
    m_pParamDesc->ParamOption( kSeedInFireMinimum, p_default, 0.f );
    m_pParamDesc->ParamOption( kSeedInFireMinimum, p_range, 0.f, FLT_MAX );
    m_pParamDesc->ParamOption( kSeedInFireMinimum, p_ui, 0, TYPE_SPINNER, EDITTYPE_POS_FLOAT,
                               IDC_PRTVOXEL_FUMEFX_SEEDINFIRE_EDIT, IDC_PRTVOXEL_FUMEFX_SEEDINFIRE_SPIN, SPIN_AUTOSCALE,
                               p_end );

    m_pParamDesc->AddParam( kEmissionEnabled, _T("GenerateEmission"), TYPE_BOOL, 0, 0, p_end );
    m_pParamDesc->ParamOption( kEmissionEnabled, p_default, FALSE );
    m_pParamDesc->ParamOption( kEmissionEnabled, p_ui, 3, TYPE_SINGLECHEKBOX,
                               IDC_PRTVOXEL_FUMEFX_GENERATEEMISSION_CHECK, p_end );

    // m_pParamDesc->AddParam(kEmissionColor, _T("EmissionColor"), TYPE_POINT3, P_RESET_DEFAULT, 0, p_end);
    // m_pParamDesc->ParamOption(kEmissionColor, p_default, Point3(0.835294f,0.615686f,0.235294f));
    // m_pParamDesc->ParamOption(kEmissionColor, p_ui, 3, TYPE_COLORSWATCH, IDC_PRTVOXEL_FUMEFX_EMISSION_COLOR,
    // p_end);

    m_pParamDesc->AddParam( kEmissionColorMultiplier, _T("EmissionMultiplier"), TYPE_FLOAT, P_RESET_DEFAULT, 0, p_end );
    m_pParamDesc->ParamOption( kEmissionColorMultiplier, p_default, 10.f );
    m_pParamDesc->ParamOption( kEmissionColorMultiplier, p_range, 0.f, FLT_MAX );
    m_pParamDesc->ParamOption( kEmissionColorMultiplier, p_ui, 3, TYPE_SPINNER, EDITTYPE_POS_FLOAT,
                               IDC_PRTVOXEL_FUMEFX_EMISSION_EDIT, IDC_PRTVOXEL_FUMEFX_EMISSION_SPIN, SPIN_AUTOSCALE,
                               p_end );

    m_pParamDesc->AddParam( kDisableVelocity, _T("DisableVelocity"), TYPE_BOOL, 0, 0, p_end );
    m_pParamDesc->ParamOption( kDisableVelocity, p_default, FALSE );
    m_pParamDesc->ParamOption( kDisableVelocity, p_ui, 3, TYPE_SINGLECHEKBOX, IDC_PRTVOXEL_FUMEFX_DISABLEVELOCITY_CHECK,
                               p_end );

    m_pParamDesc->AddParam( kViewportEnabled, _T("ViewportEnabled"), TYPE_BOOL, 0, 0, p_end );
    m_pParamDesc->ParamOption( kViewportEnabled, p_default, TRUE );
    m_pParamDesc->ParamOption( kViewportEnabled, p_ui, 2, TYPE_SINGLECHEKBOX, IDC_PRTVOXEL_VIEWPORTENABLED_CHECK,
                               p_end );

    m_pParamDesc->AddParam( kViewportDisableSubdivision, _T("ViewportDisableSubdivision"), TYPE_BOOL, 0, 0, p_end );
    m_pParamDesc->ParamOption( kViewportDisableSubdivision, p_default, TRUE );
    m_pParamDesc->ParamOption( kViewportDisableSubdivision, p_ui, 2, TYPE_SINGLECHEKBOX,
                               IDC_PRTVOXEL_DISABLESUBDIVISION_CHECK, p_end );

    m_pParamDesc->AddParam( kViewportUsePercentage, _T("ViewportUsePercentage"), TYPE_BOOL, 0, 0, p_end );
    m_pParamDesc->ParamOption( kViewportUsePercentage, p_default, FALSE );
    m_pParamDesc->ParamOption( kViewportUsePercentage, p_ui, 2, TYPE_SINGLECHEKBOX, IDC_PRTVOXEL_LOADPERCENTAGE_CHECK,
                               p_end );

    m_pParamDesc->AddParam( kViewportPercentage, _T("ViewportPercentage"), TYPE_FLOAT, P_RESET_DEFAULT, 0, p_end );
    m_pParamDesc->ParamOption( kViewportPercentage, p_default, 1.f );
    m_pParamDesc->ParamOption( kViewportPercentage, p_range, 0.f, 100.f );
    m_pParamDesc->ParamOption( kViewportPercentage, p_ui, 2, TYPE_SPINNER, EDITTYPE_POS_FLOAT,
                               IDC_PRTVOXEL_LOADPERCENTAGE_EDIT, IDC_PRTVOXEL_LOADPERCENTAGE_SPIN, SPIN_AUTOSCALE,
                               p_end );

    m_pParamDesc->AddParam( kViewportUseLimit, _T("ViewportUseLimit"), TYPE_BOOL, 0, 0, p_end );
    m_pParamDesc->ParamOption( kViewportUseLimit, p_default, TRUE );
    m_pParamDesc->ParamOption( kViewportUseLimit, p_ui, 2, TYPE_SINGLECHEKBOX, IDC_PRTVOXEL_LOADLIMIT_CHECK, p_end );

    m_pParamDesc->AddParam( kViewportLimit, _T("ViewportLimit"), TYPE_FLOAT, P_RESET_DEFAULT, 0, p_end );
    m_pParamDesc->ParamOption( kViewportLimit, p_default, 1000.f );
    m_pParamDesc->ParamOption( kViewportLimit, p_range, 0.f, FLT_MAX );
    m_pParamDesc->ParamOption( kViewportLimit, p_ui, 2, TYPE_SPINNER, EDITTYPE_POS_FLOAT, IDC_PRTVOXEL_LOADLIMIT_EDIT,
                               IDC_PRTVOXEL_LOADLIMIT_SPIN, SPIN_AUTOSCALE, p_end );

    m_pParamDesc->AddParam( kViewportIgnoreMaterial, _T("ViewportIgnoreMaterial"), TYPE_BOOL, 0, 0, p_end );
    m_pParamDesc->ParamOption( kViewportIgnoreMaterial, p_default, FALSE );
    m_pParamDesc->ParamOption( kViewportIgnoreMaterial, p_ui, 2, TYPE_SINGLECHEKBOX, IDC_PRTVOXEL_IGNOREMATERIAL_CHECK,
                               p_end );

    m_pParamDesc->AddParam( kGenerateNormal, _T("GenerateNormal"), TYPE_BOOL, 0, 0, p_end );
    m_pParamDesc->ParamOption( kGenerateNormal, p_default, FALSE );
    m_pParamDesc->ParamOption( kGenerateNormal, p_ui, 3, TYPE_SINGLECHEKBOX, IDC_PRTVOXEL_FUMEFX_GENERATENORMAL_CHECK,
                               p_end );

    m_pParamDesc->AddParam( kIconSize, _T("IconSize"), TYPE_FLOAT, P_RESET_DEFAULT, 0, p_end );
    m_pParamDesc->ParamOption( kIconSize, p_default, 30.f );
    m_pParamDesc->ParamOption( kIconSize, p_range, 0.f, FLT_MAX );
    m_pParamDesc->ParamOption( kIconSize, p_ui, 2, TYPE_SPINNER, EDITTYPE_POS_FLOAT, IDC_PRTVOXEL_ICONSIZE_EDIT,
                               IDC_PRTVOXEL_ICONSIZE_SPIN, SPIN_AUTOSCALE, p_end );

    m_pParamDesc->AddParam( kFrameOffset, _T( "FrameOffset" ), TYPE_TIMEVALUE, P_RESET_DEFAULT, 0, p_end );
    m_pParamDesc->ParamOption( kFrameOffset, p_default, 0 );
    m_pParamDesc->ParamOption( kFrameOffset, p_range, INT_MIN, INT_MAX );
    m_pParamDesc->ParamOption( kFrameOffset, p_ui, 0, TYPE_SPINNER, EDITTYPE_INT, IDC_PRTVOXEL_FUMEFX_FRAMEOFFSET_EDIT,
                               IDC_PRTVOXEL_FUMEFX_FRAMEOFFSET_SPIN, SPIN_AUTOSCALE, p_end );

    m_pParamDesc->AddParam( kLimitToCustomRange, _T( "LimitToCustomRange" ), TYPE_BOOL, P_RESET_DEFAULT, 0, p_end );
    m_pParamDesc->ParamOption( kLimitToCustomRange, p_default, FALSE );
    m_pParamDesc->ParamOption( kLimitToCustomRange, p_ui, 0, TYPE_SINGLECHEKBOX, IDC_PRTVOXELFUMEFX_CUSTOMRANGE_CHECK,
                               p_end );

    m_pParamDesc->AddParam( kCustomRangeBegin, _T( "CustomRangeBegin" ), TYPE_TIMEVALUE, P_RESET_DEFAULT, 0, p_end );
    m_pParamDesc->ParamOption( kCustomRangeBegin, p_default, 0 );
    m_pParamDesc->ParamOption( kCustomRangeBegin, p_range, INT_MIN, INT_MAX );
    m_pParamDesc->ParamOption( kCustomRangeBegin, p_accessor, GetMaxKrakatoaFumeFXObjectTimingAccessor() );
    m_pParamDesc->ParamOption( kCustomRangeBegin, p_ui, 0, TYPE_SPINNER, EDITTYPE_INT,
                               IDC_PRTVOXELFUMEFX_CUSTOMRANGESTART_EDIT, IDC_PRTVOXELFUMEFX_CUSTOMRANGESTART_SPIN,
                               SPIN_AUTOSCALE, p_end );

    m_pParamDesc->AddParam( kCustomRangeEnd, _T( "CustomRangeEnd" ), TYPE_TIMEVALUE, P_RESET_DEFAULT, 0, p_end );
    m_pParamDesc->ParamOption( kCustomRangeEnd, p_default, 100 );
    m_pParamDesc->ParamOption( kCustomRangeEnd, p_range, INT_MIN, INT_MAX );
    m_pParamDesc->ParamOption( kCustomRangeEnd, p_accessor, GetMaxKrakatoaFumeFXObjectTimingAccessor() );
    m_pParamDesc->ParamOption( kCustomRangeEnd, p_ui, 0, TYPE_SPINNER, EDITTYPE_INT,
                               IDC_PRTVOXELFUMEFX_CUSTOMRANGEEND_EDIT, IDC_PRTVOXELFUMEFX_CUSTOMRANGEEND_SPIN,
                               SPIN_AUTOSCALE, p_end );

    m_pParamDesc->AddParam( kBelowRangePolicy, _T( "BelowRangePolicy" ), TYPE_INT, P_RESET_DEFAULT, 0, p_end );
    m_pParamDesc->ParamOption( kBelowRangePolicy, p_default, 0 );
    m_pParamDesc->ParamOption( kBelowRangePolicy, p_ui, 0, TYPE_INT_COMBOBOX,
                               IDC_PRTVOXELFUMEFX_CUSTOMRANGEPOLICYBELOW_COMBO, 2, IDS_PRTVOXELFUMEFX_HOLDFIRST,
                               IDS_PRTVOXELFUMEFX_BLANK, p_end );

    m_pParamDesc->AddParam( kAboveRangePolicy, _T( "AboveRangePolicy" ), TYPE_INT, P_RESET_DEFAULT, 0, p_end );
    m_pParamDesc->ParamOption( kAboveRangePolicy, p_default, 0 );
    m_pParamDesc->ParamOption( kAboveRangePolicy, p_ui, 0, TYPE_INT_COMBOBOX,
                               IDC_PRTVOXELFUMEFX_CUSTOMRANGEPOLICYABOVE_COMBO, 2, IDS_PRTVOXELFUMEFX_HOLDLAST,
                               IDS_PRTVOXELFUMEFX_BLANK, p_end );

    m_pParamDesc->AddParam( kPlaybackGraphFrame, _T( "playbackGraphTime" ), TYPE_FLOAT, P_RESET_DEFAULT | P_ANIMATABLE,
                            IDS_PRTSOURCE_PBGRAPHTIME, p_end );
    m_pParamDesc->ParamOption( kPlaybackGraphFrame, p_default, 0.0f );
    m_pParamDesc->ParamOption( kPlaybackGraphFrame, p_range, FLT_MIN, FLT_MAX );
    m_pParamDesc->ParamOption( kPlaybackGraphFrame, p_ui, 0, TYPE_SPINNER, EDITTYPE_FLOAT,
                               IDC_PRTVOXELFUMEFX_PLAYBACKGRAPHFRAME_EDIT, IDC_PRTVOXELFUMEFX_PLAYBACKGRAPHFRAME_SPIN,
                               SPIN_AUTOSCALE, p_end );

    m_pParamDesc->AddParam( kUsePlaybackGraph, _T( "UsePlaybackGraph" ), TYPE_BOOL, P_RESET_DEFAULT, 0, p_end );
    m_pParamDesc->ParamOption( kUsePlaybackGraph, p_default, FALSE );
    m_pParamDesc->ParamOption( kUsePlaybackGraph, p_ui, 0, TYPE_SINGLECHEKBOX,
                               IDC_PRTVOXELFUMEFX_USEPLAYBACKGRAPH_CHECK, p_end );
}

MaxKrakatoaFumeFXObjectDesc::~MaxKrakatoaFumeFXObjectDesc() {
    if( m_pParamDesc ) {
        delete m_pParamDesc;
        m_pParamDesc = NULL;
    }
}

INT_PTR MainPanelDialogProc::DlgProc( TimeValue t, IParamMap2* map, HWND hWnd, UINT msg, WPARAM wParam,
                                      LPARAM lParam ) {
    IParamBlock2* pblock = map->GetParamBlock();
    switch( msg ) {
    case WM_INITDIALOG: {
        const BOOL isChecked = pblock->GetInt( kLimitToCustomRange );
        EnableTimingControls( isChecked, hWnd );
        const BOOL graphIsChecked = pblock->GetInt( kUsePlaybackGraph );
        EnablePlaybackGraphControls( graphIsChecked, hWnd );
    } break;
    case WM_COMMAND:
        if( HIWORD( wParam ) == BN_CLICKED ) {
            switch( LOWORD( wParam ) ) {
            case IDC_PRTVOXEL_FUMEFX_TARGETMENU_BUTTON:
                frantic::max3d::mxs::expression( _T( "FranticParticleRenderMXS.OpenPRTFumeFXOptionsRCMenu()" ) )
                    .evaluate<void>();
                return TRUE;
            case IDC_PRTVOXEL_FUMEFX_GRAPH_MENU:
                frantic::max3d::mxs::expression( _T( "PRTFFX_openPlaybackGraphMenu()" ) ).evaluate<void>();
                return TRUE;
            case IDC_PRTVOXELFUMEFX_CUSTOMRANGE_CHECK: {
                const BOOL isChecked = pblock->GetInt( kLimitToCustomRange );
                EnableTimingControls( isChecked, hWnd );
                break;
            }
            case IDC_PRTVOXELFUMEFX_USEPLAYBACKGRAPH_CHECK: {
                const BOOL isChecked = pblock->GetInt( kUsePlaybackGraph );
                EnablePlaybackGraphControls( isChecked, hWnd );
            }
            }
        }

        break;
    case WM_CONTEXTMENU: {
        HWND rcvHandle = (HWND)wParam;
        if( rcvHandle == GetDlgItem( hWnd, IDC_PRTVOXEL_FUMEFX_TARGETNODE_PICK ) ) {
            frantic::max3d::mxs::expression( _T("FranticParticleRenderMXS.OpenPRTFumeFXOptionsRCMenu()") )
                .evaluate<void>();
            return TRUE;
        }
    } break;
    }

    return FALSE;
}

void MainPanelDialogProc::Update( TimeValue t, Interval& valid, IParamMap2* pmap ) {
    HWND dialog = pmap->GetHWnd();
    UpdateLoadingFrame( pmap->GetParamBlock(), t, dialog );
    valid = Interval( t, t );
}

inline void MainPanelDialogProc::EnableTimingControls( BOOL enable, const HWND& dialog ) {
    EnableWindow( GetDlgItem( dialog, IDC_PRTVOXELFUMEFX_CUSTOMRANGESTART_EDIT ), enable );
    EnableWindow( GetDlgItem( dialog, IDC_PRTVOXELFUMEFX_CUSTOMRANGEEND_EDIT ), enable );
    EnableWindow( GetDlgItem( dialog, IDC_PRTVOXELFUMEFX_CUSTOMRANGEPOLICYBELOW_COMBO ), enable );
    EnableWindow( GetDlgItem( dialog, IDC_PRTVOXELFUMEFX_CUSTOMRANGEPOLICYABOVE_COMBO ), enable );

    EnableSpinner( IDC_PRTVOXELFUMEFX_CUSTOMRANGESTART_SPIN, enable, dialog );
    EnableSpinner( IDC_PRTVOXELFUMEFX_CUSTOMRANGEEND_SPIN, enable, dialog );
}

inline void MainPanelDialogProc::EnablePlaybackGraphControls( BOOL enable, const HWND& dialog ) {
    EnableWindow( GetDlgItem( dialog, IDC_PRTVOXELFUMEFX_PLAYBACKGRAPHFRAME_EDIT ), enable );
    EnableSpinner( IDC_PRTVOXELFUMEFX_PLAYBACKGRAPHFRAME_SPIN, enable, dialog );
}

inline void MainPanelDialogProc::EnableSpinner( INT idc, BOOL enable, const HWND& dialog ) {
    ISpinnerControl* const spinner = GetISpinner( GetDlgItem( dialog, idc ) );
    spinner->Enable( enable );
    ReleaseISpinner( spinner );
}

void MainPanelDialogProc::UpdateLoadingFrame( IParamBlock2* pblock, TimeValue t, HWND& dialog ) {
    const BOOL isBlank = detail::IsBlankFrame( t, pblock );
    const frantic::tstring frameLoading =
        isBlank
            ? frantic::tstring( _T( "Blank" ) )
            : boost::lexical_cast<frantic::tstring>( detail::CalculateCurrentFrame( t, pblock ) / GetTicksPerFrame() );
    const frantic::tstring newText = _T( "Loading Frame: " ) + frameLoading;
    HWND label = GetDlgItem( dialog, IDC_PRTVOXEL_FUMEFX_LOADINGFRAME_LABEL );
    SetWindowText( label, newText.c_str() );
}

INT_PTR ViewportPanelDialogProc::DlgProc( TimeValue t, IParamMap2* map, HWND hWnd, UINT msg, WPARAM wParam,
                                          LPARAM lParam ) {
    switch( msg ) {
    case WM_INITDIALOG:
        break;
    case WM_COMMAND:
        if( HIWORD( wParam ) == BN_CLICKED ) {
            if( LOWORD( wParam ) == IDC_PRTVOXEL_UPDATE_BUTTON ) {
                IParamBlock2* pblock = map->GetParamBlock();
                if( pblock ) {
                    MaxKrakatoaFumeFXObject* pOwner = static_cast<MaxKrakatoaFumeFXObject*>( pblock->GetOwner() );
                    pOwner->InvalidateObjectAndViewport();
                    pOwner->NotifyDependents( FOREVER, PART_GEOM, REFMSG_CHANGE ); // Force the scene to be updated.
                }
                return TRUE;
            }
        }
        break;
    }

    return FALSE;
}

//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------

ClassDesc2* MaxKrakatoaFumeFXObject::GetClassDesc() { return GetMaxKrakatoaFumeFXObjectDesc(); }

Mesh* MaxKrakatoaFumeFXObject::GetIconMesh( Matrix3& outTM ) {
    float iconSize = m_pblock->GetFloat( kIconSize );

    outTM.SetScale( Point3( iconSize, iconSize, iconSize ) );
    return GetPRTFumeFXIconMesh();
}

#if MAX_VERSION_MAJOR >= 25
MaxSDK::SharedMeshPtr MaxKrakatoaFumeFXObject::GetIconMeshShared( Matrix3& outTM ) {
    float iconSize = m_pblock->GetFloat( kIconSize );
    outTM.SetScale( Point3( iconSize, iconSize, iconSize ) );
    return GetPRTFumeFXIconMeshShared();
}
#endif

// From MaxKrakatoaFumeFXObject
MaxKrakatoaFumeFXObject::MaxKrakatoaFumeFXObject() {
    for( int i = 0, iEnd = NumRefs(); i < iEnd; ++i )
        SetReference( i, NULL );

    GetMaxKrakatoaFumeFXObjectDesc()->MakeAutoParamBlocks( this );

    m_requestedPoissonSamples = (std::size_t)-1;
}

void MaxKrakatoaFumeFXObject::SetIconSize( float size ) { m_pblock->SetValue( kIconSize, 0, size ); }

struct channel_ops {
    static boost::array<M_STD_STRING, 1> create_emission_channels;
    static frantic::graphics::color3f create_emission( float fireChannel, const frantic::graphics::color3f& userColor,
                                                       float userMultiplier ) {
        return userColor * ( fireChannel * userMultiplier );
    }

    static boost::array<M_STD_STRING, 1> create_normal_channels;
    static frantic::graphics::vector3f create_normal( const frantic::graphics::vector3f& densityGradChannel ) {
        return -frantic::graphics::vector3f::normalize( densityGradChannel );
    }
};

boost::array<M_STD_STRING, 1> channel_ops::create_emission_channels = { _T("Fire") };
boost::array<M_STD_STRING, 1> channel_ops::create_normal_channels = { _T("DensityGradient") };

particle_istream_ptr MaxKrakatoaFumeFXObject::GetInternalStream( INode* pNode, TimeValue t, Interval& outValidity,
                                                                 boost::shared_ptr<IEvalContext> pEvalContext ) {
    INode* pFumeNode = m_pblock->GetINode( kTargetNode );

    if( !pFumeNode || ( !m_inRenderMode && !m_pblock->GetInt( kViewportEnabled ) ) ) {
        return boost::shared_ptr<frantic::particles::streams::particle_istream>(
            new frantic::particles::streams::empty_particle_istream( pEvalContext->GetDefaultChannels(),
                                                                     get_fumefx_native_map( pFumeNode ) ) );
    }

    outValidity.SetInstant( t );

    const TimeValue transformedTime = detail::CalculateCurrentFrame( t, m_pblock );

    const bool outsideRange =
        m_pblock->GetInt( kLimitToCustomRange ) && ( transformedTime < detail::FrameRangeBottom( m_pblock ) ||
                                                     transformedTime > detail::FrameRangeTop( m_pblock ) );
    if( outsideRange ) {
        return boost::shared_ptr<frantic::particles::streams::particle_istream>(
            new frantic::particles::streams::empty_particle_istream( pEvalContext->GetDefaultChannels(),
                                                                     get_fumefx_native_map( pFumeNode ) ) );
    }

    // TODO: Remove MOST of this code and use krakatoa::get_particle_volume_voxel_sampler instead.
    // The code to create a voxel sampler for MaxKrakatoaVolumeObject was factored out into particle_volume.cpp/hpp.
    // The following code can also be removed to use that file.

    boost::shared_ptr<frantic::particles::streams::particle_istream> pin;

    int subdivCount = 0;
    if( m_pblock->GetInt( kSubdivideEnabled ) &&
        ( m_inRenderMode || !m_pblock->GetInt( kViewportDisableSubdivision ) ) )
        subdivCount = std::max( 1, m_pblock->GetInt( kSubdivideCount ) );

    bool doJitter = ( m_pblock->GetInt( kJitterSample ) != FALSE );

    int numPerVoxel = 1;
    if( doJitter && m_pblock->GetInt( kMultiplePerRegion ) &&
        ( m_inRenderMode || !m_pblock->GetInt( kViewportDisableSubdivision ) ) )
        numPerVoxel = std::max( 2, m_pblock->GetInt( kMultipleCount ) );

    boost::shared_ptr<krakatoa::particle_volume_voxel_sampler> pSampleGen(
        new krakatoa::particle_volume_voxel_sampler );

    pSampleGen->set_subdivs( subdivCount, numPerVoxel );

    if( doJitter ) {
        boost::mt19937 gen( (unsigned)m_pblock->GetInt( kRandomSeed ) );
        boost::uniform_01<float> range;
        boost::variate_generator<boost::mt19937, boost::uniform_01<float>> rng( gen, range );

        std::size_t requestedSamples = (std::size_t)m_pblock->GetInt( kRandomCount );
        if( (std::size_t)numPerVoxel > requestedSamples )
            throw std::runtime_error( "The number of samples per voxel is larger than the number of available random "
                                      "values. Please increase the number of potential random values." );

        if( m_pblock->GetInt( kJitterWellDistributed ) ) {
            if( m_requestedPoissonSamples != requestedSamples ) {
                m_poissonSamples.clear();
                m_requestedPoissonSamples = requestedSamples;

                boost::mt19937 gen( (unsigned)m_pblock->GetInt( kRandomSeed ) );
                boost::uniform_01<float> range;
                boost::variate_generator<boost::mt19937, boost::uniform_01<float>> rng( gen, range );

                float radius = std::pow( 4 * std::sqrt( 2.f ) * (float)requestedSamples / 0.6f, -1.f / 3.f );
                if( radius > 0.1f )
                    radius = 0.1f;

                frantic::graphics::build_poisson_sphere_tiles( rng, &m_poissonSamples, 1, radius, 0.6f, 200000 );
            }

            if( numPerVoxel > (int)m_poissonSamples.size() )
                throw std::runtime_error(
                    "The number of samples generated from the poisson sphere was less than the number requested per "
                    "voxel. Please increase the number of potential random values." );

            for( std::vector<frantic::graphics::vector3f>::iterator it = m_poissonSamples.begin(),
                                                                    itEnd = m_poissonSamples.end();
                 it != itEnd; ++it )
                pSampleGen->add_sample_position( *it );
        } else {
            for( std::size_t i = 0; i < requestedSamples; ++i )
                pSampleGen->add_sample_position( frantic::graphics::vector3f::from_random( rng ) );
        }
    } else {
        pSampleGen->add_sample_position( frantic::graphics::vector3f( 0.5f ) );
    }

    int disabledChannels = 0;
    if( m_pblock->GetInt( kDisableVelocity ) )
        disabledChannels |= fume_velocity_channel;

    float minDensity = m_pblock->GetFloat( kSeedInSmokeMinimum );
    if( !m_pblock->GetInt( kSeedInSmoke ) )
        minDensity = std::numeric_limits<float>::max();

    float minFire = m_pblock->GetFloat( kSeedInFireMinimum );
    if( !m_pblock->GetInt( kSeedInFire ) )
        minFire = std::numeric_limits<float>::max();

    pin = get_fume_fx_particle_istream( pFumeNode, transformedTime, pEvalContext->GetDefaultChannels(), pSampleGen,
                                        disabledChannels, minDensity, minFire );

    if( !m_inRenderMode ) {
        float loadPercentage = 1.f;
        if( m_pblock->GetInt( kViewportUsePercentage ) )
            loadPercentage = m_pblock->GetFloat( kViewportPercentage ) / 100.f;

        boost::int64_t loadLimit = std::numeric_limits<boost::int64_t>::max();
        if( m_pblock->GetInt( kViewportUseLimit ) )
            loadLimit = ( boost::int64_t )( 1000.0 * (double)m_pblock->GetFloat( kViewportLimit ) );

        pin = frantic::particles::streams::apply_fractional_particle_istream( pin, loadPercentage, loadLimit, true );
    }

    if( m_pblock->GetInt( kEmissionEnabled ) ) {
        float m =
            m_pblock->GetFloat( kEmissionColorMultiplier, transformedTime ) * pSampleGen->get_compensation_factor();
        pin = apply_fume_fx_emission_shading_istream( pin, pFumeNode, transformedTime, m );
    }

    if( m_pblock->GetInt( kGenerateNormal ) ) {
        pin.reset( new frantic::particles::streams::apply_function_particle_istream<frantic::graphics::vector3f(
                       const frantic::graphics::vector3f& )>( pin, boost::bind( &channel_ops::create_normal, _1 ),
                                                              _T("Normal"), channel_ops::create_normal_channels ) );
    }

    return pin;
}

// From Animatable

// From ReferenceMaker
RefResult MaxKrakatoaFumeFXObject::NotifyRefChanged( const Interval& /*changeInt*/, RefTargetHandle hTarget,
                                                     PartID& partID, RefMessage message, BOOL /*propagate*/ ) {
    if( hTarget == m_pblock ) {
        int param = m_pblock->LastNotifyParamID();

        if( message == REFMSG_CHANGE ) {
            switch( param ) {
            case kTargetNode:
                if( !( partID & PART_GEOM ) )
                    return REF_STOP;
                break;
            case kRandomSeed:
            case kRandomCount:
                if( !m_pblock->GetInt( kJitterSample ) )
                    return REF_STOP;
                break;
            case kSubdivideCount:
                if( !m_pblock->GetInt( kSubdivideEnabled ) ||
                    ( !m_inRenderMode && m_pblock->GetInt( kViewportDisableSubdivision ) ) )
                    return REF_STOP;
                break;
            case kJitterWellDistributed:
            case kMultiplePerRegion:
                if( !m_pblock->GetInt( kJitterSample ) )
                    return REF_STOP;
                break;
            case kMultipleCount:
                if( !m_pblock->GetInt( kMultiplePerRegion ) || !m_pblock->GetInt( kJitterSample ) ||
                    ( !m_inRenderMode && m_pblock->GetInt( kViewportDisableSubdivision ) ) )
                    return REF_STOP;
                break;
            case kSeedInSmokeMinimum:
                if( !m_pblock->GetInt( kSeedInSmoke ) )
                    return REF_STOP;
                break;
            case kSeedInFireMinimum:
                if( !m_pblock->GetInt( kSeedInFire ) )
                    return REF_STOP;
                break;
            // case kEmissionColor:
            case kEmissionColorMultiplier:
                if( !m_pblock->GetInt( kEmissionEnabled ) )
                    return REF_STOP;
                break;
            case kViewportDisableSubdivision:
                if( !m_pblock->GetInt( kSubdivideEnabled ) && !m_pblock->GetInt( kMultiplePerRegion ) &&
                    !m_pblock->GetInt( kJitterSample ) )
                    return REF_STOP;
                break;
            case kIconSize:
                return REF_SUCCEED; // Skip invalidating any cache since its just the icon size changing
            default:
                break;
            }
            InvalidateViewport();
        }
    }

    return REF_SUCCEED;
}

// From BaseObject
#if MAX_VERSION_MAJOR >= 24
const MCHAR* MaxKrakatoaFumeFXObject::GetObjectName( bool localized ) {
#elif MAX_VERSION_MAJOR >= 15
const MCHAR* MaxKrakatoaFumeFXObject::GetObjectName() {
#else
MCHAR* MaxKrakatoaFumeFXObject::GetObjectName() {
#endif
    return MaxKrakatoaFumeFXObject_NAME;
}

// From Object
void MaxKrakatoaFumeFXObject::InitNodeName( MSTR& s ) { s = MaxKrakatoaFumeFXObject_NAME; }

void MaxKrakatoaFumeFXObject::GetDeformBBox( TimeValue t, Box3& box, Matrix3* tm, BOOL useSel ) {
    INode* pNode = m_pblock->GetINode( kTargetNode );
    if( pNode ) {
        ViewExp* viewExp =
#if MAX_VERSION_MAJOR >= 15
            &GetCOREInterface()->GetActiveViewExp();
#else
            GetCOREInterface()->GetActiveViewport();
#endif
        const TimeValue transformedTime = detail::CalculateCurrentFrame( t, m_pblock );
        pNode->GetObjectRef()->FindBaseObject()->GetLocalBoundBox( transformedTime, pNode, viewExp, box );
        if( tm )
            box = box * ( *tm );
        return;
    }

    box.Init();
    box.pmin.x = -10.f;
    box.pmax.x = 10.f;
    box.pmin.y = -10.f;
    box.pmax.y = 10.f;
    box.pmin.z = 0.f;
    box.pmax.z = 20.f;
}

Interval MaxKrakatoaFumeFXObject::ObjectValidity( TimeValue t ) {
    INode* pNode = m_pblock->GetINode( kTargetNode );
    if( pNode ) {
        return pNode->GetObjectRef()->FindBaseObject()->ObjectValidity( t );
    }
    return FOREVER;
}

#pragma warning( pop )
#endif