// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0
#include "stdafx.h"

#include "resource.h"

#include "Objects/MaxKrakatoaPRTObjectDisplay.hpp"
#include <boost/any.hpp>
#include <boost/exception/all.hpp>
#include <boost/shared_array.hpp>

#include "MaxKrakatoaMagmaHolder.h"
#include "MaxKrakatoaReferenceTarget.h"
#include "Objects/MaxKrakatoaPRTInterface.h"
#include "Objects/MaxKrakatoaPRTObjectDisplay.hpp"

#include <frantic/particles/streams/concatenated_parallel_particle_istream.hpp>
#include <frantic/particles/streams/empty_particle_istream.hpp>
#include <krakatoa/prt_maker.hpp>

#include <frantic/max3d/convert.hpp>

#define MaxKrakatoaPRTMaker_NAME "PRT Maker"
#define MaxKrakatoaPRTMaker_VERSION 1

#if MAX_VERSION_MAJOR >= 25
#include <SharedMesh.h>
#endif

extern HINSTANCE hInstance;

using frantic::graphics::vector3f;

enum { kMethodSimple, kMethodIFS };

enum {
    kParticleCount,
    kRandomSeed,
    kViewportCount,
    kUseViewportCount,
    kIconSize,
    kMethod,
    kAffineTMCount,
    kTMControllers
};

class MakerController : public MaxKrakatoaReferenceTarget<ReferenceTarget, MakerController> {
    Control* m_prsControl;          // PRS
    Control* m_skewRotationControl; // Skew Rotation
    Control* m_skewAngleControl;    // Skew Angle [0, 90) degrees
    Control* m_weight;              // Scalar weight, will be used to normalize the probability of selecting this TM

  protected:
    virtual ClassDesc2* GetClassDesc();

  public:
    MakerController( bool loading = false );
    virtual ~MakerController();

    // From MakerController
    virtual void Evaluate( TimeValue t, Matrix3& outTM, float& outWeight, Interval& inoutValid );

    // From Animatable
    virtual int NumRefs();
    virtual ReferenceTarget* GetReference( int i );
    virtual void SetReference( int i, ReferenceTarget* rtarg );

    virtual int NumSubs();
    virtual Animatable* SubAnim( int i );
#if MAX_VERSION_MAJOR < 24
    virtual MSTR SubAnimName( int i );
#else
    virtual MSTR SubAnimName( int i, bool localized );
#endif
    virtual int SubNumToRefNum( int subNum );
    virtual BOOL AssignController( Animatable* control, int subAnim );
    virtual BOOL CanAssignController( int subAnim );

    // From ReferenceMaker
    virtual RefResult NotifyRefChanged( const Interval& changeInt, RefTargetHandle hTarget, PartID& partID,
                                        RefMessage message, BOOL propagate );
};

ClassDesc2* GetMakerControllerDesc();

MakerController::MakerController( bool loading )
    : m_prsControl( NULL )
    , m_skewRotationControl( NULL )
    , m_skewAngleControl( NULL )
    , m_weight( NULL ) {
    if( !loading ) {
        GetMakerControllerDesc()->MakeAutoParamBlocks( this );

        ReplaceReference( 1, CreatePRSControl() );
        ReplaceReference( 2, NewDefaultRotationController() );
        ReplaceReference( 3, NewDefaultFloatController() );
        ReplaceReference( 4, NewDefaultFloatController() );

        float one = 1.f;
        m_weight->SetValue( 0, &one );
    }
}

MakerController::~MakerController() {}

ClassDesc2* MakerController::GetClassDesc() { return GetMakerControllerDesc(); }

void MakerController::Evaluate( TimeValue t, Matrix3& outTM, float& outWeight, Interval& inoutValid ) {
    Matrix3 prsTM( TRUE );
    Quat skewOrienation = IdentQuat();
    float skewAngle = 0.f;

    if( m_prsControl && m_prsControl->SuperClassID() == CTRL_MATRIX3_CLASS_ID )
        m_prsControl->GetValue( t, &prsTM, inoutValid, CTRL_RELATIVE );

    if( m_skewRotationControl && m_skewRotationControl->SuperClassID() == CTRL_ROTATION_CLASS_ID )
        m_skewRotationControl->GetValue( t, &skewOrienation, inoutValid );

    if( m_skewAngleControl && m_skewAngleControl->SuperClassID() == CTRL_FLOAT_CLASS_ID )
        m_skewAngleControl->GetValue( t, &skewAngle, inoutValid );

    skewAngle = frantic::math::clamp( frantic::math::degrees_to_radians( skewAngle ), 0.f, (float)M_PI );

    outTM.IdentityMatrix();
    outTM.SetRow( 2, Point3( sinf( skewAngle ), 0.f, cosf( skewAngle ) ) );
    RotateMatrix( outTM, skewOrienation );
    PreRotateMatrix( outTM, skewOrienation.Invert() );
    outTM *= prsTM;

    outWeight = 1.f;
    if( m_weight )
        m_weight->GetValue( t, &outWeight, inoutValid );
}

int MakerController::NumRefs() {
    return 5; // 4 controllers + pblock
}

ReferenceTarget* MakerController::GetReference( int i ) {
    switch( i ) {
    case 0:
        return m_pblock;
    case 1:
        return m_prsControl;
    case 2:
        return m_skewRotationControl;
    case 3:
        return m_skewAngleControl;
    case 4:
        return m_weight;
    default:
        return NULL;
    }
}

void MakerController::SetReference( int i, ReferenceTarget* rtarg ) {
    switch( i ) {
    case 0:
        m_pblock = (IParamBlock2*)rtarg;
        break;
    case 1:
        m_prsControl = (Control*)rtarg;
        break;
    case 2:
        m_skewRotationControl = (Control*)rtarg;
        break;
    case 3:
        m_skewAngleControl = (Control*)rtarg;
        break;
    case 4:
        m_weight = (Control*)rtarg;
        break;
    default:
        break;
    }
}

int MakerController::NumSubs() { return 5; }

Animatable* MakerController::SubAnim( int i ) { return MakerController::GetReference( i ); }

#if MAX_VERSION_MAJOR < 24
MSTR MakerController::SubAnimName( int i ) {
#else
MSTR MakerController::SubAnimName( int i, bool localized ) {
#endif
    switch( i ) {
    case 0:
        return m_pblock->GetLocalName();
    case 1:
        return _T("Base Transform");
    case 2:
        return _T("Skew Orientation");
    case 3:
        return _T("Skew Angle");
    case 4:
        return _T("Weight");
    default:
        return _T("");
    }
}

int MakerController::SubNumToRefNum( int subNum ) { return subNum; }

BOOL MakerController::AssignController( Animatable* control, int subAnim ) {
    BOOL result = FALSE;

    switch( subAnim ) {
    case 0:
        return FALSE;
    case 1:
        if( control->SuperClassID() == CTRL_MATRIX3_CLASS_ID ) {
            ReplaceReference( subAnim, static_cast<Control*>( control ) );
            result = TRUE;
        }
        break;
    case 2:
        if( control->SuperClassID() == CTRL_ROTATION_CLASS_ID ) {
            ReplaceReference( subAnim, static_cast<Control*>( control ) );
            result = TRUE;
        }
        break;
    case 3:
        if( control->SuperClassID() == CTRL_FLOAT_CLASS_ID ) {
            ReplaceReference( subAnim, static_cast<Control*>( control ) );
            result = TRUE;
        }
        break;
    case 4:
        if( control->SuperClassID() == CTRL_FLOAT_CLASS_ID ) {
            ReplaceReference( subAnim, static_cast<Control*>( control ) );
            result = TRUE;
        }
        break;
    default:
        break;
    }

    if( result != FALSE )
        NotifyDependents( FOREVER, (PartID)PART_ALL, REFMSG_SUBANIM_STRUCTURE_CHANGED );

    return result;
}

BOOL MakerController::CanAssignController( int subAnim ) { return subAnim > 0 && subAnim < 5; }

// From ReferenceMaker
RefResult MakerController::NotifyRefChanged( const Interval& /*changeInt*/, RefTargetHandle /*hTarget*/,
                                             PartID& /*partID*/, RefMessage /*message*/, BOOL /*propagate*/ ) {
    return REF_SUCCEED;
}

class MakerControllerDesc : public ClassDesc2 {
    ParamBlockDesc2 m_paramDesc;

  public:
    MakerControllerDesc();
    virtual ~MakerControllerDesc() {}

    int IsPublic() { return FALSE; }
    void* Create( BOOL loading ) { return new MakerController( loading != FALSE ); }
    const TCHAR* ClassName() { return _T("PRT Maker TM Controller"); }
#if MAX_VERSION_MAJOR >= 24
    const TCHAR* NonLocalizedClassName() { return _T("PRT Maker TM Controller"); }
#endif
    SClass_ID SuperClassID() { return REF_TARGET_CLASS_ID; }
    Class_ID ClassID() { return Class_ID( 0x55074573, 0x25f545cd ); }
    const TCHAR* Category() { return _T(""); }

    // returns fixed parsable name (scripter-visible name)
    const TCHAR* InternalName() { return _T("PRTMakerTMController"); }
    HINSTANCE HInstance() { return hInstance; } // returns owning module handle
};

ClassDesc2* GetMakerControllerDesc() {
    static MakerControllerDesc theDesc;
    return &theDesc;
}

MakerControllerDesc::MakerControllerDesc()
    : m_paramDesc( 0,                                                         // Block num
                   _T("Parameters"),                                          // Internal name
                   NULL,                                                      // Localized name
                   NULL,                                                      // ClassDesc2*
                   P_AUTO_CONSTRUCT + /*P_AUTO_UI + P_MULTIMAP +*/ P_VERSION, // Flags
                   MaxKrakatoaPRTMaker_VERSION,
                   0, // PBlock Ref Num
                   // 1,
                   // 0, IDD_PRTCREATOR, IDS_PARAMETERS, 0, 0, NULL,            //AutoUI stuff for panel 0
                   p_end ) {
    m_paramDesc.SetClassDesc( this );
}

inline MakerController* GetMakerController( ReferenceTarget* rtarg ) {
    if( rtarg && rtarg->ClassID() == GetMakerControllerDesc()->ClassID() )
        return static_cast<MakerController*>( rtarg );
    return NULL;
}

class MaxKrakatoaPRTMaker : public krakatoa::max3d::MaxKrakatoaPRTObjectDisplay<MaxKrakatoaPRTMaker> {
  protected:
    virtual ClassDesc2* GetClassDesc();
    virtual Mesh* GetIconMesh( Matrix3& outTM );
#if MAX_VERSION_MAJOR >= 25
    virtual MaxSDK::SharedMeshPtr GetIconMeshShared( Matrix3& outTM );
#endif

    virtual particle_istream_ptr
    GetInternalStream( INode* pNode, TimeValue t, Interval& inoutValidity,
                       frantic::max3d::particles::IMaxKrakatoaPRTEvalContextPtr pEvalContext );

  public:
    MaxKrakatoaPRTMaker( BOOL loading = FALSE );
    virtual ~MaxKrakatoaPRTMaker();

    virtual void SetIconSize( float size );

    // From ReferenceMaker
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
};

class MaxKrakatoaPRTMakerDesc : public ClassDesc2 {
    ParamBlockDesc2* m_pParamDesc;

  public:
    MaxKrakatoaPRTMakerDesc();
    virtual ~MaxKrakatoaPRTMakerDesc();

    int IsPublic() { return TRUE; }
    void* Create( BOOL /*loading*/ ) { return new MaxKrakatoaPRTMaker; }
    const TCHAR* ClassName() { return _T( MaxKrakatoaPRTMaker_NAME ); }
#if MAX_VERSION_MAJOR >= 24
    const TCHAR* NonLocalizedClassName() { return _T( MaxKrakatoaPRTMaker_NAME ); }
#endif
    SClass_ID SuperClassID() { return GEOMOBJECT_CLASS_ID; }
    Class_ID ClassID() { return MaxKrakatoaPRTMakerObject_CLASSID; }
    const TCHAR* Category() { return _T("Krakatoa"); }

    // returns fixed parsable name (scripter-visible name)
    const TCHAR* InternalName() { return _T( MaxKrakatoaPRTMaker_NAME ); }
    HINSTANCE HInstance() { return hInstance; } // returns owning module handle
};

ClassDesc2* GetMaxKrakatoaPRTMakerDesc() {
    static MaxKrakatoaPRTMakerDesc theDesc;
    return &theDesc;
}

PBAccessor* GetMaxKrakatoaPRTMakerAccessor();

MaxKrakatoaPRTMakerDesc::MaxKrakatoaPRTMakerDesc() {
    m_pParamDesc =
        new ParamBlockDesc2( 0,                                                     // Block num
                             _T("Parameters"),                                      // Internal name
                             NULL,                                                  // Localized name
                             this,                                                  // ClassDesc2*
                             P_AUTO_CONSTRUCT + P_AUTO_UI + P_MULTIMAP + P_VERSION, // Flags
                             MaxKrakatoaPRTMaker_VERSION,
                             0,                                                           // PBlock Ref Num
                             1, 0, IDD_PRTCREATOR, IDS_PRTMAKER_ROLLOUT_NAME, 0, 0, NULL, // AutoUI stuff for panel 0
                             p_end );

    //------------------------------------------------------------------------------------------------------------------------------------------------------------------
    // Main rollout parameters
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------
    m_pParamDesc->AddParam( kParticleCount, _T("ParticleCount"), TYPE_INT, P_ANIMATABLE, IDS_MAKER_PARTICLECOUNT,
                            p_end );
    m_pParamDesc->ParamOption( kParticleCount, p_default, 1000000 );
    m_pParamDesc->ParamOption( kParticleCount, p_range, 0, INT_MAX );
    m_pParamDesc->ParamOption( kParticleCount, p_ui, 0, TYPE_SPINNER, EDITTYPE_POS_INT, IDC_PRTCREATOR_COUNT_EDIT,
                               IDC_PRTCREATOR_COUNT_SPIN, SPIN_AUTOSCALE, p_end );

    m_pParamDesc->AddParam( kViewportCount, _T("ViewportCount"), TYPE_INT, P_ANIMATABLE, IDS_MAKER_VIEWPORTCOUNT,
                            p_end );
    m_pParamDesc->ParamOption( kViewportCount, p_default, 1000 );
    m_pParamDesc->ParamOption( kViewportCount, p_range, 0, INT_MAX );
    m_pParamDesc->ParamOption( kViewportCount, p_ui, 0, TYPE_SPINNER, EDITTYPE_POS_INT, IDC_PRTCREATOR_VIEWCOUNT_EDIT,
                               IDC_PRTCREATOR_VIEWCOUNT_SPIN, SPIN_AUTOSCALE, p_end );

    m_pParamDesc->AddParam( kUseViewportCount, _T("UseViewportCount"), TYPE_BOOL, 0, 0, p_end );
    m_pParamDesc->ParamOption( kUseViewportCount, p_default, TRUE );
    m_pParamDesc->ParamOption( kUseViewportCount, p_ui, 0, TYPE_SINGLECHEKBOX, IDC_PRTCREATOR_USEVIEWCOUNT_CHECK,
                               p_end );

    m_pParamDesc->AddParam( kRandomSeed, _T("RandomSeed"), TYPE_INT, P_RESET_DEFAULT, 0, p_end );
    m_pParamDesc->ParamOption( kRandomSeed, p_default, 12345 );
    m_pParamDesc->ParamOption( kRandomSeed, p_range, 0, INT_MAX );
    m_pParamDesc->ParamOption( kRandomSeed, p_ui, 0, TYPE_SPINNER, EDITTYPE_POS_INT, IDC_PRTCREATOR_RANDOMSEED_EDIT,
                               IDC_PRTCREATOR_RANDOMSEED_SPIN, SPIN_AUTOSCALE, p_end );

    m_pParamDesc->AddParam( kAffineTMCount, _T("AffineTMCount"), TYPE_INT, P_TRANSIENT, 0, p_end );
    m_pParamDesc->ParamOption( kAffineTMCount, p_accessor, GetMaxKrakatoaPRTMakerAccessor(), p_end );

    m_pParamDesc->AddParam( kIconSize, _T("IconSize"), TYPE_FLOAT, P_RESET_DEFAULT, 0, p_end );
    m_pParamDesc->ParamOption( kIconSize, p_default, 30.f );
    m_pParamDesc->ParamOption( kIconSize, p_range, 0.f, FLT_MAX );
    m_pParamDesc->ParamOption( kIconSize, p_ui, 0, TYPE_SPINNER, EDITTYPE_POS_FLOAT, IDC_PRTCREATOR_ICONSIZE_EDIT,
                               IDC_PRTCREATOR_ICONSIZE_SPIN, SPIN_AUTOSCALE, p_end );

    m_pParamDesc->AddParam( kMethod, _T("Method"), TYPE_INT, P_RESET_DEFAULT, 0, p_end );
    m_pParamDesc->ParamOption( kMethod, p_default, kMethodSimple, p_end );

    m_pParamDesc->AddParam( kTMControllers, _T("TMControllers"), TYPE_REFTARG_TAB, 0, P_SUBANIM,
                            IDS_MAKER_TMCONTROLLERS, p_end );
}

PBAccessor* GetMaxKrakatoaPRTMakerAccessor() {
    class MyPBAccessor : public PBAccessor {
      public:
        virtual void Get( PB2Value& v, ReferenceMaker* owner, ParamID id, int /*tabIndex*/, TimeValue /*t*/,
                          Interval& /*valid*/ ) {
            if( id == kAffineTMCount )
                v.i = owner->GetParamBlock( 0 )->Count( kTMControllers );
        }

        virtual void Set( PB2Value& v, ReferenceMaker* owner, ParamID id, int /*tabIndex*/, TimeValue /*t*/ ) {
            if( id == kAffineTMCount ) {
                int curCount = owner->GetParamBlock( 0 )->Count( kTMControllers );
                owner->GetParamBlock( 0 )->SetCount( kTMControllers, v.i );
                for( int i = curCount; i < v.i; ++i )
                    owner->GetParamBlock( 0 )->SetValue( kTMControllers, 0, new MakerController, i );
            }
        }

        virtual void DeleteThis() {}
    } static theAccessor;

    return &theAccessor;
}

MaxKrakatoaPRTMakerDesc::~MaxKrakatoaPRTMakerDesc() { delete m_pParamDesc; }

ClassDesc2* MaxKrakatoaPRTMaker::GetClassDesc() { return GetMaxKrakatoaPRTMakerDesc(); }

extern Mesh* GetPRTMakerIconMesh();
#if MAX_VERSION_MAJOR >= 25
extern MaxSDK::SharedMeshPtr GetPRTMakerIconMeshShared();
#endif

Mesh* MaxKrakatoaPRTMaker::GetIconMesh( Matrix3& outTM ) {
    float size = m_pblock->GetFloat( kIconSize );

    outTM.SetScale( Point3( size, size, size ) );

    return GetPRTMakerIconMesh();
}

#if MAX_VERSION_MAJOR >= 25
MaxSDK::SharedMeshPtr MaxKrakatoaPRTMaker::GetIconMeshShared( Matrix3& outTM ) {
    float size = m_pblock->GetFloat( kIconSize );

    outTM.SetScale( Point3( size, size, size ) );

    return GetPRTMakerIconMeshShared();
}
#endif

particle_istream_ptr
MaxKrakatoaPRTMaker::GetInternalStream( INode* /*pNode*/, TimeValue t, Interval& inoutValidity,
                                        frantic::max3d::particles::IMaxKrakatoaPRTEvalContextPtr pEvalContext ) {
    boost::int64_t particleCount;

    inoutValidity &= Interval( t, t );

    if( m_inRenderMode || ( m_pblock->GetInt( kUseViewportCount ) == FALSE ) )
        particleCount = std::max( 0, m_pblock->GetInt( kParticleCount, t ) );
    else
        particleCount = std::max( 0, m_pblock->GetInt( kViewportCount, t ) );

    particle_istream_ptr result;

    int seed = m_pblock->GetInt( kRandomSeed, t );

    int numTMs = m_pblock->GetInt( kAffineTMCount );

    if( m_pblock->GetInt( kMethod ) == kMethodIFS && numTMs > 0 ) {
        const int numThreads = m_inRenderMode ? tbb::task_scheduler_init::default_num_threads() : 1;

        std::vector<particle_istream_ptr> pins;

        boost::int64_t realParticleCount = particleCount / numThreads;
        boost::int64_t leftOver = particleCount % numThreads;

        for( int j = 0; j < numThreads; ++j ) {
            boost::shared_ptr<krakatoa::ifs_particle_istream> ifsStream( new krakatoa::ifs_particle_istream(
                pEvalContext->GetDefaultChannels(), ( j < leftOver ) ? realParticleCount + 1 : realParticleCount,
                seed + 7 * j ) );

            for( int i = 0; i < numTMs; ++i ) {
                Matrix3 tm( TRUE );
                float weight = 1.f;

                if( MakerController* c = GetMakerController( m_pblock->GetReferenceTarget( kTMControllers, t, i ) ) ) {
                    Interval valid = FOREVER;
                    c->Evaluate( t, tm, weight, valid );
                }

                ifsStream->add_affine_transform( frantic::max3d::from_max_t( tm ), weight );
            }

            pins.push_back( ifsStream );
        }

        if( pins.size() > 1 )
            result.reset( new frantic::particles::streams::concatenated_parallel_particle_istream( pins ) );
        else
            result = pins[0];
    } else {
        result.reset(
            new krakatoa::simple_particle_istream( pEvalContext->GetDefaultChannels(), particleCount, seed ) );
    }

    return result;
}

MaxKrakatoaPRTMaker::MaxKrakatoaPRTMaker( BOOL loading ) {
    if( !loading )
        GetMaxKrakatoaPRTMakerDesc()->MakeAutoParamBlocks( this );
}

MaxKrakatoaPRTMaker::~MaxKrakatoaPRTMaker() {}

void MaxKrakatoaPRTMaker::SetIconSize( float size ) { m_pblock->SetValue( kIconSize, 0, size ); }

// From ReferenceMaker
RefResult MaxKrakatoaPRTMaker::NotifyRefChanged( const Interval& /*changeInt*/, RefTargetHandle /*hTarget*/,
                                                 PartID& /*partID*/, RefMessage /*message*/, BOOL /*propagate*/ ) {
    return REF_SUCCEED;
}

// From BaseObject
#if MAX_VERSION_MAJOR >= 24
const TCHAR* MaxKrakatoaPRTMaker::GetObjectName( bool localized ) {
#elif MAX_VERSION_MAJOR >= 15
const TCHAR* MaxKrakatoaPRTMaker::GetObjectName() {
#else
TCHAR* MaxKrakatoaPRTMaker::GetObjectName() {
#endif
    return _T( MaxKrakatoaPRTMaker_NAME );
}

// From Object
void MaxKrakatoaPRTMaker::InitNodeName( MSTR& s ) { s = _T( MaxKrakatoaPRTMaker_NAME ); }
