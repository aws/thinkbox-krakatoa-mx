// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0
#include "stdafx.h"

#include "PFlow Operators\MaxKrakatoaPFGeometryTest.h"
#include "resource.h"

#include <frantic/max3d/convert.hpp>
#include <frantic/max3d/geometry/auto_mesh.hpp>
#include <frantic/max3d/geometry/mesh.hpp>
#include <frantic/max3d/geometry/null_view.hpp>

// I don't like disabling warning 4239 (doing so promotes non cross-platform compatible code), but the Particle Flow SDK
// basically forces my hand here.
#pragma warning( disable : 4239 )

extern HINSTANCE hInstance;

INT_PTR KrakatoaPFGeometryTestParamProc::DlgProc( TimeValue t, IParamMap2* map, HWND /*hWnd*/, UINT msg, WPARAM wParam,
                                                  LPARAM /*lParam*/ ) {
    TSTR buf;

    switch( msg ) {
    case WM_INITDIALOG:
        break;
    case WM_COMMAND:
        switch( LOWORD( wParam ) ) {
        case IDC_GEOMETRYTEST_CLEAR_SELECTION:
            // Clear the selected node entry in the param block.
            map->GetParamBlock()->SetValue( kKrakatoaPFGeometryTest_pick_geometry_node, t, (INode*)NULL );
            map->GetParamBlock()->NotifyDependents( FOREVER, 0, IDC_GEOMETRYTEST_CLEAR_SELECTION );
            break;
        }

        break;
    }
    return FALSE;
}

KrakatoaPFGeometryTestParamProc* KrakatoaPFGeometryTestDesc::dialog_proc = new KrakatoaPFGeometryTestParamProc();

// KrakatoaPFGeometryTest Test param block
ParamBlockDesc2 KrakatoaPFGeometryTestDesc::pblock_desc(
    // required block spec
    kKrakatoaPFGeometryTest_pblock_index, _T("Parameters"), IDS_PARAMS,
    GetKrakatoaPFGeometryTestDesc(), //&TheKrakatoaPFGeometryTestDesc,
    P_AUTO_CONSTRUCT + P_AUTO_UI,
    // auto constuct block refno : none
    kKrakatoaPFGeometryTest_pblock_index,

    // auto ui parammap specs : none
    IDD_GEOMETRYTEST_PARAMETERS, IDS_PARAMS, 0,
    0, // open/closed
    KrakatoaPFGeometryTestDesc::dialog_proc,
    // required param specs
    // test type

    kKrakatoaPFGeometryTest_test_condition, _T("TestCondition"), TYPE_INT, P_RESET_DEFAULT + P_ANIMATABLE,
    IDS_GEOMETRYTEST_TEST_CONDITION,
    // optional tagged param specs
    p_default, kKrakatoaPFGeometryTest_inside, p_ms_default, kKrakatoaPFGeometryTest_inside,
    // p_range,		kKrakatoaPFGeometryTest_inside, kKrakatoaPFGeometryTest_outside,
    p_ui, TYPE_RADIO, 3, IDC_GEOMETRYTEST_INSIDE, IDC_GEOMETRYTEST_OUTSIDE, IDC_GEOMETRYTEST_SURFACE, p_end,

    kKrakatoaPFGeometryTest_select_by_distance, _T("SelectByDistance"), TYPE_INT, P_RESET_DEFAULT + P_ANIMATABLE,
    IDS_GEOMETRYTEST_SELECT_BY_DISTANCE,
    // optional tagged param specs
    p_default, kKrakatoaPFGeometryTest_no_distance, p_ms_default, kKrakatoaPFGeometryTest_no_distance,
    // p_range,		kKrakatoaPFGeometryTest_no_distance, kKrakatoaPFGeometryTest_greater_than_distance,
    p_ui, TYPE_RADIO, 3, IDC_GEOMETRYTEST_NO_DISTANCE, IDC_GEOMETRYTEST_LESS_THAN_DISTANCE,
    IDC_GEOMETRYTEST_GREATER_THAN_DISTANCE, p_end,

    kKrakatoaPFGeometryTest_pick_geometry_node, _T("PickGeometryNode"), TYPE_INODE, 0,
    IDS_GEOMETRYTEST_PICK_GEOMETRY_NODE,
    // optional tagged param specs
    p_ui, TYPE_PICKNODEBUTTON, IDC_GEOMETRYTEST_PICK_GEOMETRY_NODE, p_end,

    kKrakatoaPFGeometryTest_distance, _T("Distance"), TYPE_FLOAT, P_RESET_DEFAULT + P_ANIMATABLE,
    IDS_GEOMETRYTEST_DISTANCE,
    // optional tagged param specs
    p_default, 0.f, p_ms_default, 0.f, p_range, 0.f, 10000.f, p_enabled, TRUE, p_ui, TYPE_SPINNER, EDITTYPE_FLOAT,
    IDC_GEOMETRYTEST_DISTANCE, IDC_GEOMETRYTEST_DISTANCE_SPIN, 0.1f, p_end,

    kKrakatoaPFGeometryTest_animated_geometry, _T("IsAnimatedGeometry"), TYPE_BOOL, P_RESET_DEFAULT,
    IDS_COLLISIONTEST_ANIMATED_GEOMETRY, p_default, TRUE, p_ms_default, TRUE, p_enabled, TRUE, p_ui, TYPE_SINGLECHEKBOX,
    IDC_GEOMETRYTEST_ANIMATED_GEOMETRY, p_end,

    p_end );

// Each plug-in should have one instance of the ClassDesc class
ClassDesc2* GetKrakatoaPFGeometryTestDesc() {
    static KrakatoaPFGeometryTestDesc TheKrakatoaPFGeometryTestDesc;
    return &TheKrakatoaPFGeometryTestDesc;
}

HBITMAP KrakatoaPFGeometryTestDesc::m_depotIcon = NULL;
HBITMAP KrakatoaPFGeometryTestDesc::m_depotMask = NULL;
frantic::tstring KrakatoaPFGeometryTestDesc::s_unavailableDepotName;

KrakatoaPFGeometryTestDesc::~KrakatoaPFGeometryTestDesc() {
    if( m_depotIcon != NULL ) {
        DeleteObject( m_depotIcon );
        m_depotIcon = NULL;
    }
    if( m_depotMask != NULL ) {
        DeleteObject( m_depotMask );
        m_depotMask = NULL;
    }
}

int KrakatoaPFGeometryTestDesc::IsPublic() { return 0; }

void* KrakatoaPFGeometryTestDesc::Create( BOOL /*loading*/ ) { return new KrakatoaPFGeometryTest(); }

const TCHAR* KrakatoaPFGeometryTestDesc::ClassName() { return GetString( IDS_GEOMETRYTEST_CLASSNAME ); }

#if MAX_VERSION_MAJOR >= 24
const TCHAR* KrakatoaPFGeometryTestDesc::NonLocalizedClassName() { return GetString( IDS_GEOMETRYTEST_CLASSNAME ); }
#endif

SClass_ID KrakatoaPFGeometryTestDesc::SuperClassID() { return HELPER_CLASS_ID; }

Class_ID KrakatoaPFGeometryTestDesc::ClassID() { return KrakatoaPFGeometryTest_Class_ID; }

Class_ID KrakatoaPFGeometryTestDesc::SubClassID() { return PFTestSubClassID; }

const TCHAR* KrakatoaPFGeometryTestDesc::Category() { return _T("Test"); }

const TCHAR* KrakatoaPFGeometryTestDesc::InternalName() { return GetString( IDS_GEOMETRYTEST_CLASSNAME ); }

HINSTANCE KrakatoaPFGeometryTestDesc::HInstance() { return hInstance; }

INT_PTR KrakatoaPFGeometryTestDesc::Execute( int cmd, ULONG_PTR arg1, ULONG_PTR arg2, ULONG_PTR /*arg3*/ ) {
    const TCHAR** res = NULL;
    bool* isPublic;
    HBITMAP* depotIcon;
    HBITMAP* depotMask;
    switch( cmd ) {
    case kPF_GetActionDescription:
        if( arg1 == NULL )
            return 0;
        res = (const TCHAR**)arg1;
        *res = _T("Test particles to determine whether they are inside or outside of a given node's geometry.");
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
            m_depotIcon = LoadBitmap( hInstance, MAKEINTRESOURCE( IDB_GEOMETRYTEST_ACTIVE_DEPOT ) );
        if( m_depotMask == NULL )
            m_depotMask = LoadBitmap( hInstance, MAKEINTRESOURCE( IDB_GEOMETRYTEST_MASK_DEPOT ) );
        *depotIcon = m_depotIcon;
        *depotMask = m_depotMask;
        break;
    default:
        return 0;
    }
    return 1;
}

using namespace frantic::geometry;
using namespace frantic::max3d;
using namespace frantic::max3d::geometry;

// namespace PFActions {

HBITMAP KrakatoaPFGeometryTest::s_activePViewIcon = NULL;
HBITMAP KrakatoaPFGeometryTest::s_truePViewIcon = NULL;
HBITMAP KrakatoaPFGeometryTest::s_falsePViewIcon = NULL;

// constructors/destructors
KrakatoaPFGeometryTest::KrakatoaPFGeometryTest() //: m_cachedKdtree(m_cachedTrimesh3)
{
    GetClassDesc()->MakeAutoParamBlocks( this );
    m_cachedAtTime = TIME_NegInfinity;
    m_cachedKDTree.reset( new trimesh3_kdtree( m_cachedTrimesh3 ) );
}

KrakatoaPFGeometryTest::~KrakatoaPFGeometryTest() {}

//+>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>+
//|							From Animatable
//|
//+>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>+
#if MAX_VERSION_MAJOR >= 24
void KrakatoaPFGeometryTest::GetClassName( TSTR& s, bool localized )
#else
void KrakatoaPFGeometryTest::GetClassName( TSTR& s )
#endif
{
    s = GetKrakatoaPFGeometryTestDesc()->ClassName();
}

//+--------------------------------------------------------------------------+
//|							From Animatable
//|
//+--------------------------------------------------------------------------+
Class_ID KrakatoaPFGeometryTest::ClassID() { return KrakatoaPFGeometryTest_Class_ID; }

//+--------------------------------------------------------------------------+
//|							From Animatable
//|
//+--------------------------------------------------------------------------+
void KrakatoaPFGeometryTest::BeginEditParams( IObjParam* ip, ULONG flags, Animatable* prev ) {
    GetClassDesc()->BeginEditParams( ip, this, flags, prev );
}

//+--------------------------------------------------------------------------+
//|							From Animatable
//|
//+--------------------------------------------------------------------------+
void KrakatoaPFGeometryTest::EndEditParams( IObjParam* ip, ULONG flags, Animatable* next ) {
    GetClassDesc()->EndEditParams( ip, this, flags, next );
}

RefResult KrakatoaPFGeometryTest::NotifyRefChanged( const Interval& /*changeInt*/, RefTargetHandle hTarget,
                                                    PartID& partID, RefMessage message, BOOL /*propagate*/ ) {
    try {
        if( hTarget == pblock() ) {
            ParamID lastUpdateID = pblock()->LastNotifyParamID();
            if( message == REFMSG_CHANGE ) {
                switch( lastUpdateID ) {
                case kKrakatoaPFGeometryTest_distance:
                case kKrakatoaPFGeometryTest_test_condition:
                case kKrakatoaPFGeometryTest_select_by_distance:
                    NotifyDependents( FOREVER, 0, kPFMSG_InvalidateParticles, NOTIFY_ALL, TRUE );
                    break;
                case kKrakatoaPFGeometryTest_pick_geometry_node:
                    if( partID & PART_GEOM ) {
                        m_cachedAtTime = TIME_NegInfinity;
                        NotifyDependents( FOREVER, 0, kPFMSG_InvalidateParticles, NOTIFY_ALL, TRUE );
                    }
                    break;
                }
                UpdatePViewUI( lastUpdateID );
            } else if( message == IDC_GEOMETRYTEST_CLEAR_SELECTION ) {
                m_cachedAtTime = TIME_NegInfinity;
                NotifyDependents( FOREVER, 0, kPFMSG_InvalidateParticles, NOTIFY_ALL, TRUE );
            }
        }
    } catch( std::exception& e ) {
        GetCOREInterface()->Log()->LogEntry( SYSLOG_ERROR, DISPLAY_DIALOG,
                                             _T("KrakatoaPFGeometryTest::NotifyRefChanged() Error"),
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
RefTargetHandle KrakatoaPFGeometryTest::Clone( RemapDir& remap ) {
    KrakatoaPFGeometryTest* newTest = new KrakatoaPFGeometryTest();
    newTest->ReplaceReference( 0, remap.CloneRef( pblock() ) );
    BaseClone( this, newTest, remap );
    return newTest;
}

//+>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>+
//|							From BaseObject
//|
//+>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>+
#if MAX_VERSION_MAJOR >= 24
const TCHAR* KrakatoaPFGeometryTest::GetObjectName( bool localized ) const {
#elif MAX_VERSION_MAJOR >= 15
const TCHAR* KrakatoaPFGeometryTest::GetObjectName() {
#else
TCHAR* KrakatoaPFGeometryTest::GetObjectName() {
#endif
    return GetString( IDS_GEOMETRYTEST_CLASSNAME );
}

//+--------------------------------------------------------------------------+
//|							From IPFAction
//|
//+--------------------------------------------------------------------------+
const ParticleChannelMask& KrakatoaPFGeometryTest::ChannelsUsed( const Interval& /*time*/ ) const {
    static ParticleChannelMask mask( PCU_Amount, PCU_Amount );
    return mask;
}

//+--------------------------------------------------------------------------+
//|							From IPViewItem
//|
//+--------------------------------------------------------------------------+
HBITMAP KrakatoaPFGeometryTest::GetActivePViewIcon() {
    if( s_activePViewIcon == NULL )
        s_activePViewIcon = (HBITMAP)LoadImage( hInstance, MAKEINTRESOURCE( IDB_GEOMETRYTEST_ACTIVE ), IMAGE_BITMAP,
                                                kActionImageWidth, kActionImageHeight, LR_SHARED );
    _activeIcon() = s_activePViewIcon;
    return activeIcon();
}

//+--------------------------------------------------------------------------+
//|							From IPViewItem
//|
//+--------------------------------------------------------------------------+
HBITMAP KrakatoaPFGeometryTest::GetTruePViewIcon() {
    if( s_truePViewIcon == NULL )
        s_truePViewIcon = (HBITMAP)LoadImage( hInstance, MAKEINTRESOURCE( IDB_GEOMETRYTEST_TRUE ), IMAGE_BITMAP,
                                              kActionImageWidth, kActionImageHeight, LR_SHARED );
    _trueIcon() = s_truePViewIcon;
    return trueIcon();
}

//+--------------------------------------------------------------------------+
//|							From IPViewItem
//|
//+--------------------------------------------------------------------------+
HBITMAP KrakatoaPFGeometryTest::GetFalsePViewIcon() {
    if( s_falsePViewIcon == NULL )
        s_falsePViewIcon = (HBITMAP)LoadImage( hInstance, MAKEINTRESOURCE( IDB_GEOMETRYTEST_FALSE ), IMAGE_BITMAP,
                                               kActionImageWidth, kActionImageHeight, LR_SHARED );
    _falseIcon() = s_falsePViewIcon;
    return falseIcon();
}

//+>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>+
//|							From IPFTest
//|
//+>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>+
bool KrakatoaPFGeometryTest::Proceed( IObject* pCont, PreciseTimeValue /*timeStart*/, PreciseTimeValue& timeEnd,
                                      Object* /*pSystem*/, INode* /*pNode*/, INode* /*actionNode*/,
                                      IPFIntegrator* integrator, BitArray& testResult, Tab<float>& testTime ) {

    try {
        if( pblock() == NULL ) {
            if( this->GetParamBlock( 0 ) != NULL )
                throw std::runtime_error( "KrakatoaPFGeometryTest's pblock was NULL, but Ref0 was not" );
            throw std::runtime_error( "KrakatoaPFGeometryTest's pblock was NULL" );
        }

        // get channel container interface
        IChannelContainer* chCont;
        chCont = GetChannelContainerInterface( pCont );
        if( chCont == NULL )
            throw std::runtime_error( "KrakatoaPFGeometryTest: Could not set up the interface to ChannelContainer" );

        // Make sure we can read the number of current particles in the container
        IParticleChannelAmountR* chAmountR = GetParticleChannelAmountRInterface( pCont );
        if( chAmountR == NULL )
            throw std::runtime_error(
                "KrakatoaPFGeometryTest: Could not set up the interface to IParticleChannelAmountR" );

        int count = chAmountR->Count();
        if( count <= 0 )
            return true;

        TimeValue evalTime = timeEnd;

        INode* geometryNode = pblock()->GetINode( kKrakatoaPFGeometryTest_pick_geometry_node, evalTime );

        if( geometryNode == NULL ) // no node selected yet
            return true;

        // grab the object validity from max.  the transform one appears to be incorrect,
        // so I can't use that one.  but it's kind of irrelevant since I should probably just
        // transform the ray using the obj transform anyways.  the kdtree only needs to be
        // rebuilt when the geometry changes, not the transform.
        ObjectState os = geometryNode->EvalWorldState( evalTime );
        Interval objValidity = os.Validity( evalTime );
        if( m_cachedAtTime == TIME_NegInfinity || ( pblock()->GetInt( kKrakatoaPFGeometryTest_animated_geometry ) &&
                                                    !objValidity.InInterval( m_cachedAtTime ) ) ) {

            // grab the mesh from max
            AutoMesh nodeMesh = get_mesh_from_inode( geometryNode, evalTime, null_view() );
            mesh_copy( m_cachedTrimesh3, *nodeMesh.get(), true );

            // reset the kdtree
            m_cachedKDTree.reset( new trimesh3_kdtree( m_cachedTrimesh3 ) );
            m_cachedAtTime = evalTime;
        }

        int testCondition = pblock()->GetInt( kKrakatoaPFGeometryTest_test_condition, evalTime );
        int selectByDistance = pblock()->GetInt( kKrakatoaPFGeometryTest_select_by_distance, evalTime );
        float distance = pblock()->GetFloat( kKrakatoaPFGeometryTest_distance, evalTime );

        IParticleChannelPTVR* chTimeR = GetParticleChannelTimeRInterface( pCont );
        if( chTimeR == NULL ) {
            throw std::runtime_error(
                "KrakatoaPFCollisionTest: Could not set up the interface to ParticleChannelTimeR" );
        }
        IParticleChannelNewR* chNewR = GetParticleChannelNewRInterface( pCont );
        if( chNewR == NULL ) {
            throw std::runtime_error( "KrakatoaPFGeometryTest: Could not set up the interface to ParticleChannelNewR" );
        }
        IParticleChannelPoint3R* chPosR = GetParticleChannelPositionRInterface( pCont );
        if( chPosR == NULL ) {
            throw std::runtime_error(
                "KrakatoaPFGeometryTest: Could not set up the interface to ParticleChannelPositionR" );
        }
        /*IParticleChannelPoint3W* chPosW =
           (IParticleChannelPoint3W*)chCont->EnsureInterface(PARTICLECHANNELPOSITIONW_INTERFACE,
                                                                                                                                                        ParticleChannelPoint3_Class_ID,
                                                                                                                                                        true, PARTICLECHANNELPOSITIONR_INTERFACE,
                                                                                                                                                        PARTICLECHANNELPOSITIONW_INTERFACE, true);*/
        IParticleChannelPoint3R* chVelocityR = GetParticleChannelSpeedRInterface( pCont );
        IParticleChannelPoint3R* chAccelerationR = GetParticleChannelAccelerationRInterface( pCont );

        testResult.SetSize( count );
        testResult.ClearAll();
        testTime.SetCount( count );

        // pull the current object transform in order to transform the velocity rays into the object space
        Interval tmValidity;
        Matrix3 objTM = geometryNode->GetObjTMAfterWSM( evalTime, &tmValidity );
        transform4f tm = from_max_t( objTM ), tm_inv = tm.to_inverse();

        // mprintf("tm_inv: %s\n", tm_inv.str().c_str());
        //  test all the particles to see if they are inside/outside the geometry at the end of the step as though they
        //  were advected with their current properties
        Point3 vel, accel;
        vector3f pos;
        float timeStep, timeVal = timeEnd;
        bool firstProceed = true;
        for( int i = 0; i < count; ++i ) {

            timeStep = float( timeEnd - chTimeR->GetValue( i ) );

            if( timeStep < 0.f )
                continue;

            // this is how pflow does advection, as evidenced by the SpawnCollisionTest sample code
            chAccelerationR ? accel = chAccelerationR->GetValue( i ) : accel = Point3::Origin;
            chVelocityR ? vel = chVelocityR->GetValue( i ) : vel = Point3::Origin;
            vel = vel + ( 0.5f * timeStep ) * accel;
            pos = from_max_t( chPosR->GetValue( i ) + vel * timeStep );

            // mprintf("pos: %s\n", pos.str().c_str());

            // transform into kdtree space
            pos = tm_inv * pos;

            // mprintf("tranformed pos: %s\n", pos.str().c_str());

            bool isInside = m_cachedKDTree->is_point_in_volume( pos );
            vector3f normal, nearestPoint;

            if( testCondition == kKrakatoaPFGeometryTest_inside ) {
                if( isInside ) {
                    testTime[i] = timeVal;
                    testResult.Set( i );
                } else if( selectByDistance == kKrakatoaPFGeometryTest_less_than_distance ) {
                    float d = m_cachedKDTree->get_distance_to_surface( pos, &nearestPoint, &normal );
                    if( d < distance ) {
                        testTime[i] = timeVal;
                        testResult.Set( i );
                    }
                } else if( selectByDistance == kKrakatoaPFGeometryTest_greater_than_distance ) {
                    float d = m_cachedKDTree->get_distance_to_surface( pos, &nearestPoint, &normal );
                    if( d > distance ) {
                        testTime[i] = timeVal;
                        testResult.Set( i );
                    }
                }
            } else if( testCondition == kKrakatoaPFGeometryTest_outside ) {
                if( !isInside ) {
                    testTime[i] = timeVal;
                    testResult.Set( i );
                } else if( selectByDistance == kKrakatoaPFGeometryTest_less_than_distance ) {
                    float d = m_cachedKDTree->get_distance_to_surface( pos, &nearestPoint, &normal );
                    if( d < distance ) {
                        testTime[i] = timeVal;
                        testResult.Set( i );
                    }
                } else if( selectByDistance == kKrakatoaPFGeometryTest_greater_than_distance ) {
                    float d = m_cachedKDTree->get_distance_to_surface( pos, &nearestPoint, &normal );
                    if( d > distance ) {
                        testTime[i] = timeVal;
                        testResult.Set( i );
                    }
                }
            } else {
                float d = m_cachedKDTree->get_distance_to_surface( pos, &nearestPoint, &normal );
                if( d == 0.f ) {
                    testTime[i] = timeVal;
                    testResult.Set( i );
                } else if( selectByDistance == kKrakatoaPFGeometryTest_less_than_distance ) {
                    if( d < distance ) {
                        testTime[i] = timeVal;
                        testResult.Set( i );
                    }
                } else if( selectByDistance == kKrakatoaPFGeometryTest_greater_than_distance ) {
                    if( d > distance ) {
                        testTime[i] = timeVal;
                        testResult.Set( i );
                    }
                }
            }

            if( testResult[i] ) {
                if( firstProceed ) {
                    integrator->Proceed( pCont, timeEnd, i );
                    firstProceed = false;
                } else {
                    integrator->Proceed( NULL, timeEnd, i );
                }
            }
        }
    } catch( std::exception& e ) {
        GetCOREInterface()->Log()->LogEntry( SYSLOG_ERROR, DISPLAY_DIALOG,
                                             _T("KrakatoaPFGeometryTest::Proceed() Error"),
                                             HANDLE_STD_EXCEPTION_MSG( e ) );
        if( IsNetworkRenderServer() )
            throw MAXException( HANDLE_STD_EXCEPTION_MSG( e ) );
        return false;
    }

    return true;
}

ClassDesc* KrakatoaPFGeometryTest::GetClassDesc() const { return GetKrakatoaPFGeometryTestDesc(); }

//} // end of namespace PFActions
