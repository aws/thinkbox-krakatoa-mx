// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0
#include "stdafx.h"

#include "PFlow Operators\MaxKrakatoaPFCollisionTest.h"
#include "resource.h"

#include <boost/bind.hpp>
#include <frantic/max3d/convert.hpp>
#include <frantic/max3d/geometry/auto_mesh.hpp>
#include <frantic/max3d/geometry/mesh.hpp>
#include <frantic/max3d/geometry/null_view.hpp>

#include <ParticleFlow/PFSimpleActionState.h>

// I don't like disabling warning 4239 (doing so promotes non cross-platform compatible code), but the Particle Flow SDK
// basically forces my hand here.
#pragma warning( disable : 4239 )

extern HINSTANCE hInstance;

INT_PTR KrakatoaPFCollisionTestParamProc::DlgProc( TimeValue t, IParamMap2* map, HWND /*hWnd*/, UINT msg, WPARAM wParam,
                                                   LPARAM /*lParam*/ ) {
    TSTR buf;

    switch( msg ) {
    case WM_INITDIALOG:
        break;
    case WM_COMMAND:
        switch( LOWORD( wParam ) ) {
        case IDC_COLLISIONTEST_CLEAR_SELECTION:
            // Clear the selected node entry in the param block.
            map->GetParamBlock()->SetValue( kKrakatoaPFCollisionTest_pick_geometry_node, t, (INode*)NULL );
            map->GetParamBlock()->NotifyDependents( FOREVER, 0, IDC_COLLISIONTEST_CLEAR_SELECTION );
            break;
        }

        break;
    }
    return FALSE;
}

KrakatoaPFCollisionTestParamProc* KrakatoaPFCollisionTestDesc::dialog_proc = new KrakatoaPFCollisionTestParamProc();

// KrakatoaPFCollisionTest Test param block
ParamBlockDesc2 KrakatoaPFCollisionTestDesc::pblock_desc(
    // required block spec
    kKrakatoaPFCollisionTest_pblock_index, _T("Parameters"), IDS_PARAMS,
    GetKrakatoaPFCollisionTestDesc(), //&TheKrakatoaPFCollisionTestDesc,
    P_AUTO_CONSTRUCT + P_AUTO_UI,
    // auto constuct block refno : none
    kKrakatoaPFCollisionTest_pblock_index,

    // auto ui parammap specs : none
    IDD_COLLISIONTEST_PARAMETERS, IDS_PARAMS, 0,
    0, // open/closed
    KrakatoaPFCollisionTestDesc::dialog_proc,
    // required param specs
    // test type

    kKrakatoaPFCollisionTest_test_condition, _T("TestCondition"), TYPE_INT, P_RESET_DEFAULT,
    IDS_COLLISIONTEST_TEST_CONDITION, p_default, kKrakatoaPFCollisionTest_frontfaces, p_ms_default,
    kKrakatoaPFCollisionTest_frontfaces, p_ui, TYPE_RADIO, 3, IDC_COLLISIONTEST_FRONTFACES, IDC_COLLISIONTEST_BACKFACES,
    IDC_COLLISIONTEST_BOTHFACES, p_end,

    kKrakatoaPFCollisionTest_collision_offset, _T("Collision Offset"), TYPE_FLOAT, P_RESET_DEFAULT + P_ANIMATABLE,
    IDS_COLLISIONTEST_COLLISION_OFFSET, p_default, 0.f, p_ms_default, 0.f, p_range, 0.f, 10000.f, p_enabled, TRUE, p_ui,
    TYPE_SPINNER, EDITTYPE_FLOAT, IDC_COLLISIONTEST_COLLISION_OFFSET, IDC_COLLISIONTEST_COLLISION_OFFSET_SPIN, 0.1f,
    p_end,

    kKrakatoaPFCollisionTest_collision_limit, _T("Number of Collisions"), TYPE_INT, P_RESET_DEFAULT + P_ANIMATABLE,
    IDS_COLLISIONTEST_NUMBER_COLLISIONS, p_default, 1, p_ms_default, 1, p_range, 1, 10000, p_enabled, TRUE, p_ui,
    TYPE_SPINNER, EDITTYPE_INT, IDC_COLLISIONTEST_NUMBER_COLLISIONS, IDC_COLLISIONTEST_NUMBER_COLLISIONS_SPIN,
    SPIN_AUTOSCALE, p_end,

    kKrakatoaPFCollisionTest_random_seed, _T("Random Seed"), TYPE_INT, P_RESET_DEFAULT, IDS_COLLISIONTEST_SEED,
    p_default, 12345, p_ms_default, 12345, p_range, 0, 99999, p_enabled, TRUE, p_ui, TYPE_SPINNER, EDITTYPE_INT,
    IDC_COLLISIONTEST_SEED, IDC_COLLISIONTEST_SEED_SPIN, SPIN_AUTOSCALE, p_end,

    kKrakatoaPFCollisionTest_reflect_amount, _T("Reflect Probability"), TYPE_FLOAT, P_RESET_DEFAULT + P_ANIMATABLE,
    IDS_COLLISIONTEST_REFLECT_AMOUNT, p_default, 100.f, p_ms_default, 100.f, p_range, 0.f, 100.f, p_enabled, TRUE, p_ui,
    TYPE_SPINNER, EDITTYPE_FLOAT, IDC_COLLISIONTEST_REFLECT_AMOUNT, IDC_COLLISIONTEST_REFLECT_AMOUNT_SPIN, 0.1f, p_end,

    kKrakatoaPFCollisionTest_reflect_magnitude, _T("Reflect Magnitude"), TYPE_FLOAT, P_RESET_DEFAULT + P_ANIMATABLE,
    IDS_COLLISIONTEST_REFLECT_MAGNITUDE, p_default, 100.f, p_ms_default, 100.f, p_range, 0.f, 10000.f, p_enabled, TRUE,
    p_ui, TYPE_SPINNER, EDITTYPE_FLOAT, IDC_COLLISIONTEST_REFLECT_MAGNITUDE, IDC_COLLISIONTEST_REFLECT_MAGNITUDE_SPIN,
    0.1f, p_end,

    kKrakatoaPFCollisionTest_reflect_variation, _T("Reflect Variation"), TYPE_FLOAT, P_RESET_DEFAULT + P_ANIMATABLE,
    IDS_COLLISIONTEST_REFLECT_VARIATION, p_default, 0.f, p_ms_default, 0.f, p_range, 0.f, 100.f, p_enabled, TRUE, p_ui,
    TYPE_SPINNER, EDITTYPE_FLOAT, IDC_COLLISIONTEST_REFLECT_VARIATION, IDC_COLLISIONTEST_REFLECT_VARIATION_SPIN, 0.1f,
    p_end,

    kKrakatoaPFCollisionTest_reflect_chaos, _T("Reflect Chaos"), TYPE_FLOAT, P_RESET_DEFAULT + P_ANIMATABLE,
    IDS_COLLISIONTEST_REFLECT_CHAOS, p_default, 0.f, p_ms_default, 0.f, p_range, 0.f, 100.f, p_enabled, TRUE, p_ui,
    TYPE_SPINNER, EDITTYPE_FLOAT, IDC_COLLISIONTEST_REFLECT_CHAOS, IDC_COLLISIONTEST_REFLECT_CHAOS_SPIN, 0.1f, p_end,

    kKrakatoaPFCollisionTest_reflect_elasticity, _T("Reflect Elasticity"), TYPE_FLOAT, P_RESET_DEFAULT + P_ANIMATABLE,
    IDS_COLLISIONTEST_REFLECT_ELASTICITY, p_default, 100.f, p_ms_default, 100.f, p_range, 0.f, 100.f, p_enabled, TRUE,
    p_ui, TYPE_SPINNER, EDITTYPE_FLOAT, IDC_COLLISIONTEST_REFLECT_ELASTICITY, IDC_COLLISIONTEST_REFLECT_ELASTICITY_SPIN,
    0.1f, p_end,

    kKrakatoaPFCollisionTest_pick_geometry_node, _T("PickGeometryNode"), TYPE_INODE, 0,
    IDS_COLLISIONTEST_PICK_GEOMETRY_NODE, p_ui, TYPE_PICKNODEBUTTON, IDC_COLLISIONTEST_PICK_GEOMETRY_NODE, p_end,

    kKrakatoaPFCollisionTest_animated_geometry, _T("IsAnimatedGeometry"), TYPE_BOOL, P_RESET_DEFAULT,
    IDS_COLLISIONTEST_ANIMATED_GEOMETRY, p_default, TRUE, p_ms_default, TRUE, p_enabled, TRUE, p_ui, TYPE_SINGLECHEKBOX,
    IDC_COLLISIONTEST_ANIMATED_GEOMETRY, p_end,

    p_end );

// Each plug-in should have one instance of the ClassDesc class
ClassDesc2* GetKrakatoaPFCollisionTestDesc() {
    static KrakatoaPFCollisionTestDesc TheKrakatoaPFCollisionTestDesc;
    return &TheKrakatoaPFCollisionTestDesc;
}

HBITMAP KrakatoaPFCollisionTestDesc::m_depotIcon = NULL;
HBITMAP KrakatoaPFCollisionTestDesc::m_depotMask = NULL;
frantic::tstring KrakatoaPFCollisionTestDesc::s_unavailableDepotName;

KrakatoaPFCollisionTestDesc::~KrakatoaPFCollisionTestDesc() {
    if( m_depotIcon != NULL ) {
        DeleteObject( m_depotIcon );
        m_depotIcon = NULL;
    }
    if( m_depotMask != NULL ) {
        DeleteObject( m_depotMask );
        m_depotMask = NULL;
    }
}

int KrakatoaPFCollisionTestDesc::IsPublic() { return 0; }

void* KrakatoaPFCollisionTestDesc::Create( BOOL /*loading*/ ) { return new KrakatoaPFCollisionTest(); }

const TCHAR* KrakatoaPFCollisionTestDesc::ClassName() { return GetString( IDS_COLLISIONTEST_CLASSNAME ); }

#if MAX_VERSION_MAJOR >= 24
const TCHAR* KrakatoaPFCollisionTestDesc::NonLocalizedClassName() { return GetString( IDS_COLLISIONTEST_CLASSNAME ); }
#endif

SClass_ID KrakatoaPFCollisionTestDesc::SuperClassID() { return HELPER_CLASS_ID; }

Class_ID KrakatoaPFCollisionTestDesc::ClassID() { return KrakatoaPFCollisionTest_Class_ID; }

Class_ID KrakatoaPFCollisionTestDesc::SubClassID() { return PFTestSubClassID; }

const TCHAR* KrakatoaPFCollisionTestDesc::Category() { return _T("Test"); }

const TCHAR* KrakatoaPFCollisionTestDesc::InternalName() { return GetString( IDS_COLLISIONTEST_CLASSNAME ); }

HINSTANCE KrakatoaPFCollisionTestDesc::HInstance() { return hInstance; }

INT_PTR KrakatoaPFCollisionTestDesc::Execute( int cmd, ULONG_PTR arg1, ULONG_PTR arg2, ULONG_PTR /*arg3*/ ) {
    const TCHAR** res = NULL;
    bool* isPublic;
    HBITMAP* depotIcon;
    HBITMAP* depotMask;
    switch( cmd ) {
    case kPF_GetActionDescription:
        if( arg1 == NULL )
            return 0;
        res = (const TCHAR**)arg1;
        *res = _T("Test particles to determine whether they collide with a given node's geometry.");
        break;
    case kPF_PViewPublic:
        if( arg1 == NULL )
            return 0;
        isPublic = (bool*)arg1;
        *isPublic = true;
        break;
    case kPF_PViewCategory:
        if( arg1 == NULL )
            return 0;
        res = (const TCHAR**)arg1;
        *res = _T("Test");
        break;
    case kPF_PViewDepotIcon:
        if( arg1 == NULL )
            return 0;
        depotIcon = (HBITMAP*)arg1;
        if( arg2 == NULL )
            return 0;
        depotMask = (HBITMAP*)arg2;
        if( m_depotIcon == NULL )
            m_depotIcon = LoadBitmap( hInstance, MAKEINTRESOURCE( IDB_COLLISIONTEST_ACTIVE_DEPOT ) );
        if( m_depotMask == NULL )
            m_depotMask = LoadBitmap( hInstance, MAKEINTRESOURCE( IDB_COLLISIONTEST_MASK_DEPOT ) );
        *depotIcon = m_depotIcon;
        *depotMask = m_depotMask;
        break;
    default:
        return 0;
    }
    return 1;
}

using namespace frantic::geometry;
using namespace frantic::max3d::geometry;
using namespace frantic::max3d;

HBITMAP KrakatoaPFCollisionTest::s_activePViewIcon = NULL;
HBITMAP KrakatoaPFCollisionTest::s_truePViewIcon = NULL;
HBITMAP KrakatoaPFCollisionTest::s_falsePViewIcon = NULL;

// namespace PFActions {

// constructors/destructors
KrakatoaPFCollisionTest::KrakatoaPFCollisionTest()
    : m_cachedTrimesh3()
    , m_cachedCollisionDetector() {
    GetClassDesc()->MakeAutoParamBlocks( this );
    m_cachedAtTime = TIME_NegInfinity;
}

KrakatoaPFCollisionTest::~KrakatoaPFCollisionTest() {}

//+>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>+
//|							From Animatable
//|
//+>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>+
#if MAX_VERSION_MAJOR < 24
void KrakatoaPFCollisionTest::GetClassName( TSTR& s )
#else
void KrakatoaPFCollisionTest::GetClassName( TSTR& s, bool localized )
#endif
{
    s = GetKrakatoaPFCollisionTestDesc()->ClassName();
}

//+--------------------------------------------------------------------------+
//|							From Animatable
//|
//+--------------------------------------------------------------------------+
Class_ID KrakatoaPFCollisionTest::ClassID() { return KrakatoaPFCollisionTest_Class_ID; }

//+--------------------------------------------------------------------------+
//|							From Animatable
//|
//+--------------------------------------------------------------------------+
void KrakatoaPFCollisionTest::BeginEditParams( IObjParam* ip, ULONG flags, Animatable* prev ) {
    GetClassDesc()->BeginEditParams( ip, this, flags, prev );
}

//+--------------------------------------------------------------------------+
//|							From Animatable
//|
//+--------------------------------------------------------------------------+
void KrakatoaPFCollisionTest::EndEditParams( IObjParam* ip, ULONG flags, Animatable* next ) {
    GetClassDesc()->EndEditParams( ip, this, flags, next );
}

RefResult KrakatoaPFCollisionTest::NotifyRefChanged( const Interval& /*changeInt*/, RefTargetHandle hTarget,
                                                     PartID& /*partID*/, RefMessage message, BOOL /*propagate*/ ) {

    try {
        switch( message ) {

        case REFMSG_CHANGE:
            if( hTarget == pblock() ) {
                int lastUpdateID = pblock()->LastNotifyParamID();
                switch( lastUpdateID ) {
                case kKrakatoaPFCollisionTest_test_condition:
                    NotifyDependents( FOREVER, 0, kPFMSG_InvalidateParticles, NOTIFY_ALL, TRUE );
                    break;
                case kKrakatoaPFCollisionTest_pick_geometry_node:
                    // reset the collision mesh kdtree
                    m_cachedCollisionDetector.clear();
                    m_cachedAtTime = TIME_NegInfinity;

                    NotifyDependents( FOREVER, 0, kPFMSG_InvalidateParticles, NOTIFY_ALL, TRUE );

                    break;
                }
                UpdatePViewUI( static_cast<ParamID>( lastUpdateID ) );
            }
            break;
        case IDC_COLLISIONTEST_CLEAR_SELECTION:
            // reset the collision mesh kdtree
            m_cachedCollisionDetector.clear();
            m_cachedAtTime = TIME_NegInfinity;

            NotifyDependents( FOREVER, 0, kPFMSG_InvalidateParticles, NOTIFY_ALL, TRUE );

            break;
        }
    } catch( std::exception& e ) {
        GetCOREInterface()->Log()->LogEntry( SYSLOG_ERROR, DISPLAY_DIALOG,
                                             _T("KrakatoaPFOperatorCollisionTest::NotifyRefChanged() Error"),
                                             HANDLE_STD_EXCEPTION_MSG( e ) );
        if( IsNetworkRenderServer() )
            throw MAXException( HANDLE_STD_EXCEPTION_MSG( e ) );
    }
    return REF_SUCCEED;
}

//+--------------------------------------------------------------------------+
//|							From ReferenceMaker
//|
//+--------------------------------------------------------------------------+
RefTargetHandle KrakatoaPFCollisionTest::Clone( RemapDir& remap ) {
    KrakatoaPFCollisionTest* newTest = new KrakatoaPFCollisionTest();
    newTest->ReplaceReference( 0, remap.CloneRef( pblock() ) );
    BaseClone( this, newTest, remap );
    return newTest;
}

//+>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>+
//|							From BaseObject
//|
//+>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>+
#if MAX_VERSION_MAJOR >= 24
const TCHAR* KrakatoaPFCollisionTest::GetObjectName( bool localized ) const {
#elif MAX_VERSION_MAJOR >= 15
const TCHAR* KrakatoaPFCollisionTest::GetObjectName() {
#else
TCHAR* KrakatoaPFCollisionTest::GetObjectName() {
#endif
    return GetString( IDS_COLLISIONTEST_CLASSNAME );
}

//+>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>+
//|							From IPFAction
//|
//+>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>+
bool KrakatoaPFCollisionTest::Init( IObject* pCont, Object* /*pSystem*/, INode* /*node*/, Tab<Object*>& /*actions*/,
                                    Tab<INode*>& /*actionNodes*/ ) {
    //_givenIntegrator(pCont) = NULL;
    return _randLinker().Init( pCont, GetRand() );
}

//+--------------------------------------------------------------------------+
//|							From IPFAction
//|
//+--------------------------------------------------------------------------+
bool KrakatoaPFCollisionTest::Release( IObject* pCont ) {
    //_givenIntegrator(pCont) = NULL;
    _randLinker().Release( pCont );
    return true;
}

//+--------------------------------------------------------------------------+
//|							From IPFAction
//|
//+--------------------------------------------------------------------------+
int KrakatoaPFCollisionTest::GetRand() { return pblock()->GetInt( kKrakatoaPFCollisionTest_random_seed ); }

//+--------------------------------------------------------------------------+
//|							From IPFAction
//|
//+--------------------------------------------------------------------------+
void KrakatoaPFCollisionTest::SetRand( int seed ) {
    pblock()->SetValue( kKrakatoaPFCollisionTest_random_seed, 0, seed );
}

//+--------------------------------------------------------------------------+
//|							From IPFAction
//|
//+--------------------------------------------------------------------------+
const ParticleChannelMask& KrakatoaPFCollisionTest::ChannelsUsed( const Interval& /*time*/ ) const {
    static ParticleChannelMask mask( PCU_Amount, PCU_Amount );
    return mask;
}

//+--------------------------------------------------------------------------+
//|							From IPFAction
//|
//+--------------------------------------------------------------------------+
IObject* KrakatoaPFCollisionTest::GetCurrentState( IObject* pContainer ) {
    RandGenerator* randGen = randLinker().GetRandGenerator( pContainer );
    if( randGen != NULL ) {
        PFSimpleActionState* actionState =
            (PFSimpleActionState*)CreateInstance( REF_TARGET_CLASS_ID, PFSimpleActionState_Class_ID );
        if( actionState->randGen() != NULL )
            memcpy( actionState->_randGen(), randGen, sizeof( RandGenerator ) );
        return actionState;
    }
    return NULL;
}

//+--------------------------------------------------------------------------+
//|							From IPFAction
//|
//+--------------------------------------------------------------------------+
void KrakatoaPFCollisionTest::SetCurrentState( IObject* aSt, IObject* pContainer ) {
    if( aSt == NULL )
        return;
    PFSimpleActionState* actionState = (PFSimpleActionState*)aSt;
    RandGenerator* randGen = randLinker().GetRandGenerator( pContainer );
    if( randGen == NULL )
        return;
    memcpy( randGen, actionState->randGen(), sizeof( RandGenerator ) );
}

//+--------------------------------------------------------------------------+
//|							From IPViewItem
//|
//+--------------------------------------------------------------------------+
HBITMAP KrakatoaPFCollisionTest::GetActivePViewIcon() {
    if( s_activePViewIcon == NULL )
        s_activePViewIcon = (HBITMAP)LoadImage( hInstance, MAKEINTRESOURCE( IDB_COLLISIONTEST_ACTIVE ), IMAGE_BITMAP,
                                                kActionImageWidth, kActionImageHeight, LR_SHARED );
    _activeIcon() = s_activePViewIcon;

    return activeIcon();
}

//+--------------------------------------------------------------------------+
//|							From IPViewItem
//|
//+--------------------------------------------------------------------------+
HBITMAP KrakatoaPFCollisionTest::GetTruePViewIcon() {
    if( s_truePViewIcon == NULL )
        s_truePViewIcon = (HBITMAP)LoadImage( hInstance, MAKEINTRESOURCE( IDB_COLLISIONTEST_TRUE ), IMAGE_BITMAP,
                                              kActionImageWidth, kActionImageHeight, LR_SHARED );
    _trueIcon() = s_truePViewIcon;
    return trueIcon();
}

//+--------------------------------------------------------------------------+
//|							From IPViewItem
//|
//+--------------------------------------------------------------------------+
HBITMAP KrakatoaPFCollisionTest::GetFalsePViewIcon() {
    if( s_falsePViewIcon == NULL )
        s_falsePViewIcon = (HBITMAP)LoadImage( hInstance, MAKEINTRESOURCE( IDB_COLLISIONTEST_FALSE ), IMAGE_BITMAP,
                                               kActionImageWidth, kActionImageHeight, LR_SHARED );
    _falseIcon() = s_falsePViewIcon;
    return falseIcon();
}

//+>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>+
//|							From IPFTest
//|
//+>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>+
bool KrakatoaPFCollisionTest::Proceed( IObject* pCont, PreciseTimeValue timeStart, PreciseTimeValue& timeEnd,
                                       Object* /*pSystem*/, INode* /*pNode*/, INode* /*actionNode*/,
                                       IPFIntegrator* integrator, BitArray& testResult, Tab<float>& testTime ) {

    try {
        if( pblock() == NULL ) {
            if( this->GetParamBlock( 0 ) != NULL )
                throw std::runtime_error( "KrakatoaPFCollisionTest's pblock was NULL, but Ref0 was not" );
            throw std::runtime_error( "KrakatoaPFCollisionTest's pblock was NULL" );
        }

        // get channel container interface
        IChannelContainer* chCont;
        chCont = GetChannelContainerInterface( pCont );
        if( chCont == NULL )
            throw std::runtime_error( "KrakatoaPFCollisionTest: Could not set up the interface to ChannelContainer" );

        // Make sure we can read the number of current particles in the container
        IParticleChannelAmountR* chAmountR = GetParticleChannelAmountRInterface( pCont );
        if( chAmountR == NULL )
            throw std::runtime_error(
                "KrakatoaPFCollisionTest::Proceed() - Could not set up the interface to IParticleChannelAmountR" );

        int count = chAmountR->Count();
        if( count <= 0 )
            return true;

        PreciseTimeValue evalTime = timeEnd - timeStart;
        evalTime /= 2;
        evalTime += timeStart;

        INode* geometryNode = pblock()->GetINode( kKrakatoaPFCollisionTest_pick_geometry_node, evalTime );

        if( geometryNode == NULL ) // no node selected yet
            return true;

        // grab the object validity from max.  the transform one appears to be incorrect,
        // so I can't use that one.  but it's kind of irrelevant since I should probably just
        // transform the ray using the obj transform anyways.  the kdtree only needs to be
        // rebuilt when the geometry changes, not the transform.
        ObjectState os = geometryNode->EvalWorldState( evalTime );
        Interval validity = os.Validity( evalTime );
        if( m_cachedAtTime == TIME_NegInfinity || ( pblock()->GetInt( kKrakatoaPFCollisionTest_animated_geometry ) &&
                                                    !validity.InInterval( m_cachedAtTime ) ) ) {
            // grab the mesh from max
            AutoMesh nodeMesh = get_mesh_from_inode( geometryNode, evalTime, null_view() );
            mesh_copy( m_cachedTrimesh3, *nodeMesh.get(), true );

            // reset the kdtree
            m_cachedCollisionDetector.clear();
            m_cachedCollisionDetector.add_rigid_object(
                motion_blurred_transform<float>( from_max_t( geometryNode->GetObjTMAfterWSM( timeStart, &validity ) ),
                                                 from_max_t( geometryNode->GetObjTMAfterWSM( timeEnd, &validity ) ) ),
                m_cachedTrimesh3 );
            m_cachedCollisionDetector.prepare_kdtrees( true );
            m_cachedAtTime = evalTime;
        }

        IParticleChannelNewR* chNewR = GetParticleChannelNewRInterface( pCont );
        if( chNewR == NULL ) {
            throw std::runtime_error(
                "KrakatoaPFCollisionTest: Could not set up the interface to ParticleChannelNewR" );
        }

        IParticleChannelPoint3R* chPosR = GetParticleChannelPositionRInterface( pCont );
        if( chPosR == NULL ) {
            throw std::runtime_error(
                "KrakatoaPFCollisionTest: Could not set up the interface to ParticleChannelPositionR" );
        }
        IParticleChannelPoint3W* chPosW = (IParticleChannelPoint3W*)chCont->EnsureInterface(
            PARTICLECHANNELPOSITIONW_INTERFACE, ParticleChannelPoint3_Class_ID, true,
            PARTICLECHANNELPOSITIONR_INTERFACE, PARTICLECHANNELPOSITIONW_INTERFACE, true );
        if( chPosW == NULL ) {
            throw std::runtime_error(
                "KrakatoaPFCollisionTest: Could not set up the interface to ParticleChannelPositionW" );
            return false;
        }

        IParticleChannelPTVR* chTimeR = GetParticleChannelTimeRInterface( pCont );
        if( chTimeR == NULL ) {
            throw std::runtime_error(
                "KrakatoaPFCollisionTest: Could not set up the interface to ParticleChannelTimeR" );
        }
        IParticleChannelPTVW* chTimeW = (IParticleChannelPTVW*)chCont->EnsureInterface(
            PARTICLECHANNELTIMEW_INTERFACE, ParticleChannelPTV_Class_ID, true, PARTICLECHANNELTIMER_INTERFACE,
            PARTICLECHANNELTIMEW_INTERFACE, true );
        if( chTimeW == NULL ) {
            throw std::runtime_error(
                "KrakatoaPFCollisionTest: Could not set up the interface to ParticleChannelTimeW" );
            return false;
        }

        IParticleChannelQuatR* chOrientR = GetParticleChannelOrientationRInterface( pCont );
        IParticleChannelQuatW* chOrientW = (IParticleChannelQuatW*)chCont->EnsureInterface(
            PARTICLECHANNELORIENTATIONW_INTERFACE, ParticleChannelQuat_Class_ID, true,
            PARTICLECHANNELORIENTATIONR_INTERFACE, PARTICLECHANNELORIENTATIONW_INTERFACE, true );
        if( chOrientW == NULL ) {
            throw std::runtime_error(
                "KrakatoaPFCollisionTest: Could not set up the interface to ParticleChannelOrientationW" );
            return false;
        }

        // We need access to the particle velocity and acceleration
        IParticleChannelPoint3R* chVelR = GetParticleChannelSpeedRInterface( pCont );
        IParticleChannelPoint3W* chVelW = (IParticleChannelPoint3W*)chCont->EnsureInterface(
            PARTICLECHANNELSPEEDW_INTERFACE, ParticleChannelPoint3_Class_ID, true, PARTICLECHANNELSPEEDR_INTERFACE,
            PARTICLECHANNELSPEEDW_INTERFACE, true );
        if( chVelW == NULL ) {
            throw std::runtime_error(
                "KrakatoaPFCollisionTest: Could not set up the interface to ParticleChannelSpeedW" );
            return false;
        }
        IParticleChannelPoint3R* chAccR = GetParticleChannelAccelerationRInterface( pCont );
        IParticleChannelPoint3W* chAccW = (IParticleChannelPoint3W*)chCont->EnsureInterface(
            PARTICLECHANNELACCELERATIONW_INTERFACE, ParticleChannelPoint3_Class_ID, true,
            PARTICLECHANNELACCELERATIONR_INTERFACE, PARTICLECHANNELACCELERATIONW_INTERFACE, true );
        if( chAccW == NULL ) {
            throw std::runtime_error(
                "KrakatoaPFCollisionTest: Could not set up the interface to ParticleChannelAccelerationW" );
            return false;
        }

        // IParticleChannelIDR * chIDR = GetParticleChannelIDRInterface( pCont );
        // if (chIDR == NULL) {
        // throw std::runtime_error("KrakatoaPFVelocityCollisionTest: Could not set up the interface to
        // ParticleChannelIDR"); return false;
        //}

        testResult.SetSize( count );
        testResult.ClearAll();
        testTime.SetCount( count );

        Tab<Point3> velTab, posTab;
        velTab.SetCount( count );
        posTab.SetCount( count );

        Tab<PreciseTimeValue> timeToAdvance;
        timeToAdvance.SetCount( count );

        // collision test params
        int testCondition = pblock()->GetInt( kKrakatoaPFCollisionTest_test_condition, evalTime );
        float collisionOffset = pblock()->GetFloat( kKrakatoaPFCollisionTest_collision_offset, evalTime );
        int collisionLimit = pblock()->GetInt( kKrakatoaPFCollisionTest_collision_limit, evalTime );

        // reflection params
        float reflectAmount = pblock()->GetFloat( kKrakatoaPFCollisionTest_reflect_amount, evalTime ) / 100.f;
        float magnitude = pblock()->GetFloat( kKrakatoaPFCollisionTest_reflect_magnitude, evalTime ) / 100.f;
        float variation = pblock()->GetFloat( kKrakatoaPFCollisionTest_reflect_variation, evalTime ) / 100.f;
        float chaos = pblock()->GetFloat( kKrakatoaPFCollisionTest_reflect_chaos, evalTime ) / 100.f;
        float elasticity = pblock()->GetFloat( kKrakatoaPFCollisionTest_reflect_elasticity, evalTime ) / 100.f;

        // grab the random number generator
        RandGenerator* randGen = randLinker().GetRandGenerator( pCont );
        if( randGen == NULL )
            throw std::runtime_error(
                "KrakatoaPFCollisionTest: The random number generator could not be initialized." );

        // pull the current object transform in order to transform the velocity rays into the object space
        // Matrix3 objTM = geometryNode->GetObjTMAfterWSM ( evalTime, &validity );
        // transform4f tm = from_max_t(objTM), tm_inv = tm.to_inverse();

        transform4f startTM = from_max_t( geometryNode->GetObjTMAfterWSM( timeStart, &validity ) );
        transform4f endTM = from_max_t( geometryNode->GetObjTMAfterWSM( timeEnd, &validity ) );

        m_cachedCollisionDetector.change_transform( motion_blurred_transform<float>( startTM, endTM ), 0 );
        m_cachedCollisionDetector.prepare_master_kdtree();

        // variables for hanlding the collision offset time
        // TODO: I'm not sure at what time the transforms and variables
        // should be sampled ?

        // The user-defined collisionOffset shifts the start of the
        // time interval in which we look for collisions.
        // This is the start of that shifted time interval.
        PreciseTimeValue collisionOffsetStartTime = timeStart + collisionOffset * float( GetTicksPerFrame() );

        // Change the timeEnd to include the collision offset.
        // Also keep the original timeEnd so we can
        // reset it when we're done ( similar to the Max SDK's PFTestCollisionSpaceWarp.cpp )
        const PreciseTimeValue originalTimeEnd = timeEnd;
        timeEnd += collisionOffset * float( GetTicksPerFrame() );

        // test all the particles to see if they collide
        Point3 vel, accel;
        vector3f startPos, startVel;
        float timeStep;
        for( int i = 0; i < count; ++i ) {
            // const int particleID = chIDR->GetParticleIndex( i );

            PreciseTimeValue particleTime = chTimeR->GetValue( i );
            PreciseTimeValue initialParticleTime = particleTime;

            timeStep = float( timeEnd - particleTime );
            if( timeStep < 0.f )
                continue;

            // this is how pflow does advection, as evidenced by the Spawn Collision Test sample code
            chAccR ? accel = chAccR->GetValue( i ) : accel = Point3::Origin;
            chVelR ? vel = chVelR->GetValue( i ) : vel = Point3::Origin;

            vel = vel + ( 0.5f * timeStep ) * accel;

            startPos = from_max_t( chPosR->GetValue( i ) ); // + vel * float(GetTicksPerFrame()) * collisionOffset);
            startVel = from_max_t( vel * ( timeEnd - timeStart ) );

            Quat orient = chOrientR ? chOrientR->GetValue( i ) : Quat();

            // this loop handles multiple collisions per frame.  the way it's currently being done, the tmin stays
            // at 0.0, and the origin and direction of the ray are changed depending on where any collision
            // has happened.  so typically, the origin is moved to the new collision position, and the direction is
            // assigned whatever new (or same) velocity resulted from a collision, but tmax is scaled back to reflect
            // the time remaining in the interval.

            // I've changed this so that [tMin,tMax] always corresponds
            // to [timeStart,timeEnd].  I did this so that the particle
            // intersection will use the animated transform for the correct
            // time.  Alternatively, you could keep tMin fixed at 0 and
            // change the transforms as you sweep though time.
            vector3f newPos = startPos, newVel = startVel;

            double tStart = double( particleTime - timeStart ) / double( timeEnd - timeStart );
            double tNew;
            const double tEnd = 1.0;
            for( int c = 0; c < collisionLimit; ++c ) {
                // const bool printDebug = false;
                // if( printDebug ) {
                // frantic::logging::set_logging_level( frantic::logging::level::debug );
                // FF_LOG( debug ) << "[" << timeStart.TimeValue() << "]" << particleID << std::endl;
                //}
                // else {
                // frantic::logging::set_logging_level( frantic::logging::level::stats );
                //}

                // collision test
                frantic::geometry::raytrace_intersection intersection;
                // ray.at(tStart) should be ~startPos
                const frantic::geometry::ray3f ray( startPos - startVel * static_cast<float>( tStart ), startVel );
                const bool collided =
                    m_cachedCollisionDetector.collides_with_particle( ray, tStart, tEnd, intersection );
                // bool collided = m_cachedKdtree.intersect_particle( ray, tStart, tEnd, intersection );
                // if( printDebug )
                // mprintf( "[%d]%d starting from position %s (%s), going to %s.  tStart = %g\n", timeStart.TimeValue(),
                // particleID, ray.at( tStart ).str().c_str(), ray.origin().str().c_str(),
                // ray.direction().str().c_str(), tStart );

                // if we collided, take the appropriate action
                if( collided ) {
                    // if( printDebug )
                    // mprintf( " hit at %s, t = %g, ray at t = %s \n", intersection.position.str().c_str(),
                    // intersection.distance, ray.at( intersection.distance ).str().c_str() );

                    bool reflected = false;

                    // check the normal to see if it was a back face or front face hit
                    const float dotProduct =
                        vector3f::dot( intersection.geometricNormal, intersection.ray.direction() );

                    particleTime =
                        timeStart + static_cast<float>( intersection.distance * double( timeEnd - timeStart ) );

                    const vector3f relativeVel( startVel - intersection.motionDuringTimeStep );

                    // We nudge the particle by this distance at the end of
                    // this scope.
                    // TODO: this should be a better epsilon
                    vector3f nudgePos( 0 );
                    if( relativeVel.max_abs_component() > 0 )
                        nudgePos = ( 10.f * std::numeric_limits<float>::epsilon() *
                                     ( fabs( intersection.position.x ) + fabs( intersection.position.y ) +
                                       fabs( intersection.position.z ) + fabs( relativeVel.x ) + fabs( relativeVel.y ) +
                                       fabs( relativeVel.z ) ) *
                                     ( vector3f::dot( relativeVel, intersection.geometricNormal ) *
                                       intersection.geometricNormal )
                                         .to_normalized() );

                    // If it isn't the type of collision we're looking for (front/back face), set the positon
                    // to the collision point, don't touch the velocity, and keep going
                    if( ( dotProduct < 0.f && testCondition == kKrakatoaPFCollisionTest_backfaces ) ||
                        ( dotProduct >= 0.f && testCondition == kKrakatoaPFCollisionTest_frontfaces ) ) {
                        // bump forward in an attempt to avoid hitting the same plane
                        // again by accident
                        startPos = intersection.position;
                        tStart = intersection.distance;
                    } else {
                        // otherwise, we have to compute the reaction.
                        if( collisionOffset > 0 ) {
                            if( particleTime > collisionOffsetStartTime ) {
                                testTime[i] = particleTime - collisionOffsetStartTime;
                            } else {
                                testTime[i] = initialParticleTime - timeStart; // ?
                            }
                        } else {
                            testTime[i] = particleTime - timeStart;
                        }

                        testResult.Set( i );

                        const float randVal = randGen->Rand01();

                        if( randVal <= reflectAmount && reflectAmount > 0 ) {
                            reflect_particle( startVel, tStart, intersection,
                                              //(dotProduct < 0),
                                              magnitude, variation, chaos, elasticity, randGen, newVel );
                            // newPos = ray.at( intersection.distance );
                            reflected = true;
                        }

                        newPos = intersection.position;
                        tNew = intersection.distance;

                        if( collisionOffset > 0 ) {
                            // if( printDebug ) {
                            // mprintf( "particle %d detected collision at %g (%g..%g), ray: %s\n", particleID,
                            // intersection.distance, tStart, tEnd, ray.str().c_str() ); mprintf( "startPos = %s = %s +
                            // %s * %g * %g .  accel = %s\n", startPos.str().c_str(),
                            // from_max_t(chPosR->GetValue(i)).str().c_str(), from_max_t(vel).str().c_str(),
                            // float(GetTicksPerFrame()), collisionOffset, from_max_t(accel).str().c_str() ); mprintf(
                            // "newPos = %s\n", newPos.str().c_str() );
                            //}
                            if( particleTime > collisionOffsetStartTime ) {
                                // timeEnd was already pushed back by collisionOffset
                                newPos -= startVel * collisionOffset * float( GetTicksPerFrame() ) /
                                          float( timeEnd - timeStart );
                                // if( printDebug )
                                // mprintf( "updated newPos: %s ( subtracted %s * %g / ( %g - %g )\n",
                                // newPos.str().c_str(), startVel.str().c_str(), collisionOffset, double(timeEnd),
                                // double(timeStart) );
                            } else {
                                // don't jump back if we didn't make it to the offset ?
                                // so do nothing in this case ?
                                // or just go back to where we started ?
                                newPos = startPos;
                                // if( printDebug ) {
                                // mprintf( "particle %d detected collision at %g (%g..%g), ray: %s\n", particleID,
                                // intersection.distance, tStart, tEnd, ray.str().c_str() ); mprintf( "updated newPos =
                                // startPos = %s\n", newPos.str().c_str() );
                                //}
                            }
                        }

                        startVel = newVel;
                        startPos = newPos;
                        tStart = tNew;
                    }

                    if( reflected ) {
                        startPos -= nudgePos;
                    } else {
                        startPos += nudgePos;
                    }
                } else { // the particle did not collide
                    // if( printDebug )
                    // mprintf( "particle %d did not hit starting from position %s (%s), going to %s.  tStart = %g\n",
                    // particleID, ray.at( tStart ).str().c_str(), ray.origin().str().c_str(),
                    // ray.direction().str().c_str(), tStart );

                    break;
                }
            }
            // if ( collisionOffset > 0.f )
            // newPos = newPos - from_max_t(vel * float(GetTicksPerFrame()) * collisionOffset);

            posTab[i] = to_max_t( startPos );
            velTab[i] = to_max_t( startVel / float( timeEnd - timeStart ) );
        }

        if( integrator != NULL ) {
            for( int i = 0; i < count; ++i ) {
                if( testResult[i] )
                    timeToAdvance[i] = timeStart + testTime[i];
            }
            integrator->Proceed( pCont, timeToAdvance, testResult );
        }

        for( int i = 0; i < count; ++i ) {
            if( testResult[i] ) {
                chPosW->SetValue( i, posTab[i] );
                chVelW->SetValue( i, velTab[i] );
                // chAccW->SetValue( i, to_max_t( vector3f( 0 ) ) );
            }
        }

        timeEnd = originalTimeEnd;

    } catch( std::exception& e ) {
        GetCOREInterface()->Log()->LogEntry( SYSLOG_ERROR, DISPLAY_DIALOG,
                                             _T("KrakatoaPFOperatorCollisionTest::Proceed() Error"),
                                             HANDLE_STD_EXCEPTION_MSG( e ) );
        if( IsNetworkRenderServer() )
            throw MAXException( HANDLE_STD_EXCEPTION_MSG( e ) );

        return false;
    }

    return true;
}

// time is measured as a fraction of the current time step
void KrakatoaPFCollisionTest::reflect_particle( const vector3f& startVel, const double /*startTime*/,
                                                const frantic::geometry::raytrace_intersection& intersection,
                                                float magnitude, float variation, float chaos, float elasticity,
                                                RandGenerator* randGen, vector3f& newVel ) {
    const vector3f v( startVel - intersection.motionDuringTimeStep );
    newVel = startVel -
             ( 1.0f + elasticity ) * vector3f::dot( v, intersection.geometricNormal ) * intersection.geometricNormal;

    newVel *= magnitude;

    // mprintf( "start: %s, new: %s, magnitude: %g\n", startVel.str().c_str(), newVel.str().c_str(), double( magnitude )
    // );

    if( variation > 0.f )
        newVel *= 1.f + variation * ( randGen->Rand01() * 2.f - 1.f );
    if( chaos > 0.f ) {
        vector3f chaosVec = vector3f::from_unit_random( boost::bind( &RandGenerator::Rand01, randGen ) );
        if( vector3f::dot( chaosVec, intersection.geometricNormal ) < 0 )
            chaosVec *= -1.f;
        float scale = newVel.get_magnitude();
        newVel.normalize();
        newVel = scale * ( newVel * ( 1.f - chaos ) + chaosVec * ( chaos ) );
    }
}

ClassDesc* KrakatoaPFCollisionTest::GetClassDesc() const { return GetKrakatoaPFCollisionTestDesc(); }

//} // end of namespace PFActions
