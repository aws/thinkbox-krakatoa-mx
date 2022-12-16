// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0
#include "stdafx.h"

#include "PFlow Operators\MaxKrakatoaPFGeometryLookup.h"
#include "resource.h"

#include <frantic/max3d/convert.hpp>
#include <frantic/max3d/geometry/auto_mesh.hpp>
#include <frantic/max3d/geometry/mesh.hpp>
#include <frantic/max3d/geometry/null_view.hpp>

// I don't like disabling warning 4239 (doing so promotes non cross-platform compatible code), but the Particle Flow SDK
// basically forces my hand here.
#pragma warning( disable : 4239 )

extern HINSTANCE hInstance;

INT_PTR KrakatoaPFGeometryLookupParamProc::DlgProc( TimeValue t, IParamMap2* map, HWND /*hWnd*/, UINT msg,
                                                    WPARAM wParam, LPARAM /*lParam*/ ) {
    TSTR buf;

    switch( msg ) {
    case WM_INITDIALOG:
        break;
    case WM_COMMAND:
        switch( LOWORD( wParam ) ) {
        case IDC_GEOMETRYLOOKUP_CLEAR_SELECTION:
            // Clear the selected node entry in the param block.
            map->GetParamBlock()->SetValue( kKrakatoaPFGeometryLookup_pick_geometry_node, t, (INode*)NULL );
            map->GetParamBlock()->NotifyDependents( FOREVER, 0, IDC_GEOMETRYLOOKUP_CLEAR_SELECTION );
            break;
        }

        break;
    }
    return FALSE;
}

KrakatoaPFGeometryLookupParamProc* KrakatoaPFGeometryLookupDesc::dialog_proc = new KrakatoaPFGeometryLookupParamProc();

// clang-format off
// KrakatoaPFGeometryLookup Test param block
ParamBlockDesc2 KrakatoaPFGeometryLookupDesc::pblock_desc 
(
	// required block spec
		kKrakatoaPFGeometryLookup_pblock_index, 
		_T("Parameters"),
		IDS_PARAMS,
		GetKrakatoaPFGeometryLookupDesc(), //&TheKrakatoaPFGeometryLookupDesc,
		P_AUTO_CONSTRUCT + P_AUTO_UI,
	// auto constuct block refno : none
		kKrakatoaPFGeometryLookup_pblock_index, 
		
	// auto ui parammap specs : none
		IDD_GEOMETRYLOOKUP_PARAMETERS, 
		IDS_PARAMS,
		0,
		0, // open/closed
		KrakatoaPFGeometryLookupDesc::dialog_proc,
	// required param specs
			kKrakatoaPFGeometryLookup_pick_geometry_node,	_T("PickGeometryNode"),
									TYPE_INODE,
									0,
									IDS_GEOMETRYLOOKUP_PICK_GEOMETRY_NODE,
			// optional tagged param specs
							p_ui,	TYPE_PICKNODEBUTTON, IDC_GEOMETRYLOOKUP_PICK_GEOMETRY_NODE,
			p_end,

			kKrakatoaPFGeometryLookup_distance,	_T("Distance"),
									TYPE_FLOAT,
									P_RESET_DEFAULT + P_ANIMATABLE,
									IDS_GEOMETRYLOOKUP_DISTANCE,
			// optional tagged param specs
					p_default,		10.f,
					p_ms_default,	0.f,
					p_range,		0.f, 100000.f,
					p_enabled,		TRUE, 
					p_ui,			TYPE_SPINNER,	EDITTYPE_FLOAT,	IDC_GEOMETRYLOOKUP_DISTANCE,	IDC_GEOMETRYLOOKUP_DISTANCE_SPIN,	0.1f,
			p_end,

			kKrakatoaPFGeometryLookup_use_position,	_T("UsePosition"),
									TYPE_BOOL, 
									P_RESET_DEFAULT,
									IDS_GEOMETRYLOOKUP_USE_POSITION,
					p_default, 		true,	
					p_ui, 			TYPE_SINGLECHEKBOX, IDC_GEOMETRYLOOKUP_CHECK_USE_POSITION, 
			p_end,
			kKrakatoaPFGeometryLookup_position_put_to_choice, 	_T("PutPositionTo"),
									TYPE_INT,
									P_ANIMATABLE,
									IDS_GEOMETRYLOOKUP_RADIO_POS_TO,
					p_default, 		0,	
					p_ui, 			TYPE_RADIO, 2,IDC_GEOMETRYLOOKUP_RADIO_POS_TO_MXSV,IDC_GEOMETRYLOOKUP_RADIO_POS_TO_UVWCH,
					p_vals,			0,1,
			p_end,
			kKrakatoaPFGeometryLookup_position_to_uvw_index,	_T("PutPositionToUVWIndex"),
									TYPE_INT, 
									P_ANIMATABLE,
									IDS_GEOMETRYLOOKUP_POS_TO_UVW_INDEX,
					p_default, 		2,	
					p_range, 		0, 100, 
					p_ui, 			TYPE_SPINNER, EDITTYPE_INT, IDC_GEOMETRYLOOKUP_POS_TO_UVW_INDEX, IDC_GEOMETRYLOOKUP_POS_TO_UVW_INDEX_SPIN, 1.0f,
			p_end,
			kKrakatoaPFGeometryLookup_use_barycentric_coords,	_T("UseBarycentricCoords"),
									TYPE_BOOL, 
									P_RESET_DEFAULT,
									IDS_GEOMETRYLOOKUP_USE_BARY_COORDS,
					p_default, 		true,	
					p_ui, 			TYPE_SINGLECHEKBOX, IDC_GEOMETRYLOOKUP_CHECK_USE_BARY_COORDS, 
			p_end,
			kKrakatoaPFGeometryLookup_barycentric_coords_to_uvw_index,	_T("PutBarycoordsToUVWIndex"),
									TYPE_INT, 
									P_ANIMATABLE,
									IDS_GEOMETRYLOOKUP_BARY_TO_UVW_INDEX,
					p_default, 		3,	
					p_range, 		0, 100, 
					p_ui, 			TYPE_SPINNER, EDITTYPE_INT, IDC_GEOMETRYLOOKUP_BARY_TO_UVW_INDEX, IDC_GEOMETRYLOOKUP_BARY_TO_UVW_INDEX_SPIN, 1.0f,
			p_end,
			kKrakatoaPFGeometryLookup_barycentric_coords_shift,	_T("ShiftBarycentricCoords"),
									TYPE_BOOL, 
									P_RESET_DEFAULT,
									IDS_GEOMETRYLOOKUP_SHIFT_COORDS,
					p_default, 		true,	
					p_ui, 			TYPE_SINGLECHEKBOX, IDC_GEOMETRYLOOKUP_CHECK_SHIFT_COORDS, 
			p_end,
			kKrakatoaPFGeometryLookup_use_normals,	_T("UseNormals"),
									TYPE_BOOL, 
									P_RESET_DEFAULT,
									IDS_GEOMETRYLOOKUP_USE_NORMALS,
					p_default, 		false,	
					p_ui, 			TYPE_SINGLECHEKBOX, IDC_GEOMETRYLOOKUP_CHECK_USE_NORMALS, 
			p_end,
			kKrakatoaPFGeometryLookup_normal_put_choice, 	_T("PutNormalsTo"),
									TYPE_INT,
									P_ANIMATABLE,
									IDS_GEOMETRYLOOKUP_RADIO_NORMAL_TO,
					p_default, 		0,	
					p_ui, 			TYPE_RADIO, 3,IDC_GEOMETRYLOOKUP_RADIO_NORMAL_TO_TM,IDC_GEOMETRYLOOKUP_RADIO_NORMAL_TO_MXSTM,IDC_GEOMETRYLOOKUP_RADIO_NORMAL_TO_UVWCH,
					p_vals,			0,1,2,
			p_end,
			kKrakatoaPFGeometryLookup_normal_to_uvw_index,	_T("PutNormalsToUVWIndex"),
									TYPE_INT, 
									P_ANIMATABLE,
									IDS_GEOMETRYLOOKUP_NORMAL_TO_UVW_INDEX,
					p_default, 		4,	
					p_range, 		0, 100, 
					p_ui, 			TYPE_SPINNER, EDITTYPE_INT, IDC_GEOMETRYLOOKUP_NORMAL_TO_UVW_INDEX, IDC_GEOMETRYLOOKUP_NORMAL_TO_UVW_INDEX_SPIN, 1.0f,
			p_end,
			kKrakatoaPFGeometryLookup_use_surface_uwv,	_T("UseSurfaceUVWs"),
									TYPE_BOOL, 
									P_RESET_DEFAULT,
									IDS_GEOMETRYLOOKUP_USE_SURFACE_UVW,
					p_default, 		false,	
					p_ui, 			TYPE_SINGLECHEKBOX, IDC_GEOMETRYLOOKUP_CHECK_USE_SURFACE_UVW, 
			p_end,
			kKrakatoaPFGeometryLookup_surface_uvw_index_to_sample,	_T("SurfaceUVWAtPointIndex"),
									TYPE_INT, 
									P_ANIMATABLE,
									IDS_GEOMETRYLOOKUP_UVW_TO_SAMPLE_INDEX,
					p_default, 		1,	
					p_range, 		0, 100, 
					p_ui, 			TYPE_SPINNER, EDITTYPE_INT, IDC_GEOMETRYLOOKUP_UVW_TO_SAMPLE_INDEX, IDC_GEOMETRYLOOKUP_UVW_TO_SAMPLE_INDEX_SPIN, 1.0f,
			p_end,
			kKrakatoaPFGeometryLookup_surface_uvw_to_uvw_index,	_T("PutSurfaceUVWsToUVWIndex"),
									TYPE_INT, 
									P_ANIMATABLE,
									IDS_GEOMETRYLOOKUP_UVW_TO_UVW_INDEX,
					p_default, 		5,	
					p_range, 		0, 100, 
					p_ui, 			TYPE_SPINNER, EDITTYPE_INT, IDC_GEOMETRYLOOKUP_UVW_TO_UVW_INDEX, IDC_GEOMETRYLOOKUP_UVW_TO_UVW_INDEX_SPIN, 1.0f,
			p_end,
			kKrakatoaPFGeometryLookup_applyOnce, _T("ApplyOnce"),
									TYPE_INT,
									FALSE,
									IDS_GEOMETRYLOOKUP_APPLY_ONCE,
					p_default,		0,
					p_ui,			TYPE_SINGLECHEKBOX, IDC_GEOMETRYLOOKUP_APPLY_ONCE,
			p_end,
		p_end 
);
// clang-format on

// Each plug-in should have one instance of the ClassDesc class
ClassDesc2* GetKrakatoaPFGeometryLookupDesc() {
    static KrakatoaPFGeometryLookupDesc TheKrakatoaPFGeometryLookupDesc;
    return &TheKrakatoaPFGeometryLookupDesc;
}

HBITMAP KrakatoaPFGeometryLookupDesc::m_depotIcon = NULL;
HBITMAP KrakatoaPFGeometryLookupDesc::m_depotMask = NULL;
frantic::tstring KrakatoaPFGeometryLookupDesc::s_unavailableDepotName;

KrakatoaPFGeometryLookupDesc::~KrakatoaPFGeometryLookupDesc() {
    if( m_depotIcon != NULL ) {
        DeleteObject( m_depotIcon );
        m_depotIcon = NULL;
    }
    if( m_depotMask != NULL ) {
        DeleteObject( m_depotMask );
        m_depotMask = NULL;
    }
}

int KrakatoaPFGeometryLookupDesc::IsPublic() { return 0; }

void* KrakatoaPFGeometryLookupDesc::Create( BOOL /*loading*/ ) { return new KrakatoaPFGeometryLookup(); }

const TCHAR* KrakatoaPFGeometryLookupDesc::ClassName() { return GetString( IDS_GEOMETRYLOOKUP_CLASSNAME ); }

#if MAX_VERSION_MAJOR >= 24
const TCHAR* KrakatoaPFGeometryLookupDesc::NonLocalizedClassName() { return GetString( IDS_GEOMETRYLOOKUP_CLASSNAME ); }
#endif

SClass_ID KrakatoaPFGeometryLookupDesc::SuperClassID() { return HELPER_CLASS_ID; }

Class_ID KrakatoaPFGeometryLookupDesc::ClassID() { return KrakatoaPFGeometryLookup_Class_ID; }

Class_ID KrakatoaPFGeometryLookupDesc::SubClassID() { return PFOperatorSubClassID; }

const TCHAR* KrakatoaPFGeometryLookupDesc::Category() { return _T("Test"); }

const TCHAR* KrakatoaPFGeometryLookupDesc::InternalName() { return GetString( IDS_GEOMETRYLOOKUP_CLASSNAME ); }

HINSTANCE KrakatoaPFGeometryLookupDesc::HInstance() { return hInstance; }

INT_PTR KrakatoaPFGeometryLookupDesc::Execute( int cmd, ULONG_PTR arg1, ULONG_PTR arg2, ULONG_PTR /*arg3*/ ) {
    const TCHAR** res = NULL;
    bool* isPublic;
    HBITMAP* depotIcon;
    HBITMAP* depotMask;
    switch( cmd ) {
    case kPF_GetActionDescription:
        if( arg1 == NULL )
            return 0;
        res = (const TCHAR**)arg1;
        *res = _T("Looks up the closest point of a given surface and puts its location into the MXS Vector channel.");
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
            m_depotIcon = LoadBitmap( hInstance, MAKEINTRESOURCE( IDB_GEOMETRYLOOKUP_ACTIVE_DEPOT ) );
        if( m_depotMask == NULL )
            m_depotMask = LoadBitmap( hInstance, MAKEINTRESOURCE( IDB_GEOMETRYLOOKUP_MASK_DEPOT ) );
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

// namespace PFActions {

HBITMAP KrakatoaPFGeometryLookup::s_activePViewIcon = NULL;
HBITMAP KrakatoaPFGeometryLookup::s_inactivePViewIcon = NULL;

// constructors/destructors
KrakatoaPFGeometryLookup::KrakatoaPFGeometryLookup() //: m_cachedKdtree(m_cachedTrimesh3)
{
    GetClassDesc()->MakeAutoParamBlocks( this );
    m_cachedAtTime = TIME_NegInfinity;
    m_kdtree.reset( new trimesh3_kdtree( m_cachedTrimesh3 ) );
    m_cachedNormals.reset( new MeshNormalSpec );
}

KrakatoaPFGeometryLookup::~KrakatoaPFGeometryLookup() {}

//+>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>+
//|							From Animatable
//|
//+>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>+
#if MAX_VERSION_MAJOR < 24
void KrakatoaPFGeometryLookup::GetClassName( TSTR& s )
#else
void KrakatoaPFGeometryLookup::GetClassName( TSTR& s, bool localized )
#endif
{
    s = GetKrakatoaPFGeometryLookupDesc()->ClassName();
}

//+--------------------------------------------------------------------------+
//|							From Animatable
//|
//+--------------------------------------------------------------------------+
Class_ID KrakatoaPFGeometryLookup::ClassID() { return KrakatoaPFGeometryLookup_Class_ID; }

//+--------------------------------------------------------------------------+
//|							From Animatable
//|
//+--------------------------------------------------------------------------+
void KrakatoaPFGeometryLookup::BeginEditParams( IObjParam* ip, ULONG flags, Animatable* prev ) {
    GetClassDesc()->BeginEditParams( ip, this, flags, prev );
}

//+--------------------------------------------------------------------------+
//|							From Animatable
//|
//+--------------------------------------------------------------------------+
void KrakatoaPFGeometryLookup::EndEditParams( IObjParam* ip, ULONG flags, Animatable* next ) {
    GetClassDesc()->EndEditParams( ip, this, flags, next );
}

void KrakatoaPFGeometryLookup::PassMessage( int message, LPARAM param ) {
    if( pblock() == NULL )
        return;

    IParamMap2* map = pblock()->GetMap();
    if( ( map == NULL ) && ( NumPViewParamMaps() == 0 ) )
        return;

    HWND hWnd;
    if( map != NULL ) {
        hWnd = map->GetHWnd();
        if( hWnd ) {
            SendMessage( hWnd, WM_COMMAND, message, param );
        }
    }

    for( int i = 0; i < NumPViewParamMaps(); i++ ) {
        hWnd = GetPViewParamMap( i )->GetHWnd();
        if( hWnd ) {
            SendMessage( hWnd, WM_COMMAND, message, param );
        }
    }
}

RefResult KrakatoaPFGeometryLookup::NotifyRefChanged( const Interval& /*changeInt*/, RefTargetHandle hTarget,
                                                      PartID& /*partID*/, RefMessage message, BOOL /*propagate*/ ) {

    try {
        switch( message ) {

        case REFMSG_CHANGE:
            if( hTarget == pblock() ) {
                ParamID lastUpdateID = pblock()->LastNotifyParamID();
                switch( lastUpdateID ) {
                case kKrakatoaPFGeometryLookup_distance:
                case kKrakatoaPFGeometryLookup_pick_geometry_node:
                case kKrakatoaPFGeometryLookup_use_position:
                case kKrakatoaPFGeometryLookup_use_barycentric_coords:
                case kKrakatoaPFGeometryLookup_use_normals:
                case kKrakatoaPFGeometryLookup_use_surface_uwv:
                case kKrakatoaPFGeometryLookup_position_put_to_choice:
                case kKrakatoaPFGeometryLookup_position_to_uvw_index:
                case kKrakatoaPFGeometryLookup_barycentric_coords_to_uvw_index:
                case kKrakatoaPFGeometryLookup_normal_to_uvw_index:
                case kKrakatoaPFGeometryLookup_surface_uvw_index_to_sample:
                case kKrakatoaPFGeometryLookup_surface_uvw_to_uvw_index:
                case kKrakatoaPFGeometryLookup_normal_put_choice:
                case kKrakatoaPFGeometryLookup_applyOnce:
                    NotifyDependents( FOREVER, 0, kPFMSG_InvalidateParticles, NOTIFY_ALL, TRUE );
                    break;
                }
                UpdatePViewUI( lastUpdateID );
            }
        case IDC_GEOMETRYLOOKUP_CLEAR_SELECTION:
            NotifyDependents( FOREVER, 0, kPFMSG_InvalidateParticles, NOTIFY_ALL, TRUE );
            break;
        }
    } catch( std::exception& e ) {
        GetCOREInterface()->Log()->LogEntry( SYSLOG_ERROR, DISPLAY_DIALOG,
                                             _T("KrakatoaPFGeometryLookup::NotifyRefChanged() Error"),
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
RefTargetHandle KrakatoaPFGeometryLookup::Clone( RemapDir& remap ) {
    KrakatoaPFGeometryLookup* newTest = new KrakatoaPFGeometryLookup();
    newTest->ReplaceReference( 0, remap.CloneRef( pblock() ) );
    BaseClone( this, newTest, remap );
    return newTest;
}

//+>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>+
//|							From BaseObject
//|
//+>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>+
#if MAX_VERSION_MAJOR >= 24
const TCHAR* KrakatoaPFGeometryLookup::GetObjectName( bool localized ) const {
#elif MAX_VERSION_MAJOR >= 15
const TCHAR* KrakatoaPFGeometryLookup::GetObjectName() {
#else
TCHAR* KrakatoaPFGeometryLookup::GetObjectName() {
#endif

    return GetString( IDS_GEOMETRYLOOKUP_CLASSNAME );
}

//+--------------------------------------------------------------------------+
//|							From IPFAction
//|
//+--------------------------------------------------------------------------+
const ParticleChannelMask& KrakatoaPFGeometryLookup::ChannelsUsed( const Interval& /*time*/ ) const { // read channels:
    static ParticleChannelMask mask( PCU_Amount | PCU_New | PCU_Time | PCU_Position | PCU_ShapeTexture,
                                     // write channels:
                                     PCU_ShapeTexture | PCU_MXSInteger | PCU_MXSVector | PCU_MXSMatrix |
                                         PCU_Orientation );

    return mask;
}

//+--------------------------------------------------------------------------+
//|							From IPViewItem
//|
//+--------------------------------------------------------------------------+
HBITMAP KrakatoaPFGeometryLookup::GetActivePViewIcon() {
    if( s_activePViewIcon == NULL )
        s_activePViewIcon = (HBITMAP)LoadImage( hInstance, MAKEINTRESOURCE( IDB_GEOMETRYLOOKUP_ACTIVE ), IMAGE_BITMAP,
                                                kActionImageWidth, kActionImageHeight, LR_SHARED );
    _activeIcon() = s_activePViewIcon;

    return activeIcon();
}

HBITMAP KrakatoaPFGeometryLookup::GetInactivePViewIcon() {
    if( s_inactivePViewIcon == NULL )
        s_inactivePViewIcon = (HBITMAP)LoadImage( hInstance, MAKEINTRESOURCE( IDB_GEOMETRYLOOKUP_INACTIVE ),
                                                  IMAGE_BITMAP, kActionImageWidth, kActionImageHeight, LR_SHARED );
    _inactiveIcon() = s_inactivePViewIcon;
    return inactiveIcon();
}

bool KrakatoaPFGeometryLookup::Proceed( IObject* pCont, PreciseTimeValue timeStart, PreciseTimeValue& timeEnd,
                                        Object* /*pSystem*/, INode* /*pNode*/, INode* actionNode,
                                        IPFIntegrator* /*integrator*/ ) {

    try {
        if( pblock() == NULL ) {
            if( this->GetParamBlock( 0 ) != NULL )
                throw std::runtime_error( "KrakatoaPFGeometryLookup's pblock was NULL, but Ref0 was not" );
            throw std::runtime_error( "KrakatoaPFGeometryLookup's pblock was NULL" );
        }

        // get channel container interface
        IChannelContainer* chCont;
        chCont = GetChannelContainerInterface( pCont );
        if( chCont == NULL )
            throw std::runtime_error( "KrakatoaPFGeometryLookup: Could not set up the interface to ChannelContainer" );

        // Make sure we can read the number of current particles in the container
        IParticleChannelAmountR* chAmountR = GetParticleChannelAmountRInterface( pCont );
        if( chAmountR == NULL )
            throw std::runtime_error(
                "KrakatoaPFGeometryLookup: Could not set up the interface to IParticleChannelAmountR" );

        int count = chAmountR->Count();
        if( count <= 0 )
            return true;

        TimeValue evalTime = timeStart;

        // Get the validity of the mesh from the node you have picked.
        // If our cached mesh wasn't cached at a time within that validity interval, redo
        // the cache.
        INode* geometryNode = pblock()->GetINode( kKrakatoaPFGeometryLookup_pick_geometry_node, evalTime );

        if( geometryNode == NULL ) // no node selected yet
            return true;

        // grab the transformation and object validities from max
        ObjectState os = geometryNode->EvalWorldState( evalTime );
        Interval objValidity = os.Validity( evalTime );
        Interval tmValidity;
        Matrix3 objTM = geometryNode->GetObjTMAfterWSM( evalTime, &tmValidity );

        // clock_t t1 = -clock();
        int usePosition = pblock()->GetInt( kKrakatoaPFGeometryLookup_use_position );
        int useBaryCoords = pblock()->GetInt( kKrakatoaPFGeometryLookup_use_barycentric_coords );
        int useNormals = pblock()->GetInt( kKrakatoaPFGeometryLookup_use_normals );
        int useSurfaceUVW = pblock()->GetInt( kKrakatoaPFGeometryLookup_use_surface_uwv );
        int shiftBaryCoords = pblock()->GetInt( kKrakatoaPFGeometryLookup_barycentric_coords_shift );
        int positionChoice = pblock()->GetInt( kKrakatoaPFGeometryLookup_position_put_to_choice );
        int normalChoice = pblock()->GetInt( kKrakatoaPFGeometryLookup_normal_put_choice );

        float distance = pblock()->GetFloat( kKrakatoaPFGeometryLookup_distance, evalTime );

        AutoMesh nodeMesh; // we want to keep the nodeMesh for normal lookups

        // if the "cached at" time is not in these intervals, redo the cache
        if( !objValidity.InInterval( m_cachedAtTime ) || !tmValidity.InInterval( m_cachedAtTime ) ) {
            // grab the mesh from max
            nodeMesh = get_mesh_from_inode( geometryNode, evalTime, null_view() );
            mesh_copy( m_cachedTrimesh3, frantic::graphics::transform4f( objTM ), *nodeMesh.get(), true );

            // reset the kdtree
            m_kdtree.reset( new trimesh3_kdtree( m_cachedTrimesh3 ) );
            m_cachedNormals.reset( new MeshNormalSpec );

            if( useNormals ) {
                m_cachedNormals->SetParent( nodeMesh.get() );
                m_cachedNormals->CheckNormals();
                m_cachedNormals->SetParent( NULL );
            }
            // m_cachedVolume.reset( new trimesh3_kdtree_volume_collection(m_cachedTrimesh3) );
            m_cachedAtTime = evalTime;
        }

        // t1 += clock();
        // mprintf("Tree building time: %d\n", t1);

        IParticleChannelPTVR* chTimeR = GetParticleChannelTimeRInterface( pCont );
        if( chTimeR == NULL ) {
            throw std::runtime_error(
                "KrakatoaPFCollisionTest: Could not set up the interface to ParticleChannelTimeR" );
        }
        IParticleChannelNewR* chNewR = GetParticleChannelNewRInterface( pCont );
        if( chNewR == NULL ) {
            throw std::runtime_error(
                "KrakatoaPFGeometryLookup: Could not set up the interface to ParticleChannelNewR" );
        }
        IParticleChannelPoint3R* chPosR = GetParticleChannelPositionRInterface( pCont );
        if( chPosR == NULL ) {
            throw std::runtime_error(
                "KrakatoaPFGeometryLookup: Could not set up the interface to ParticleChannelPositionR" );
        }
        IParticleChannelPoint3R* chVelocityR = GetParticleChannelSpeedRInterface( pCont );
        IParticleChannelPoint3R* chAccelerationR = GetParticleChannelAccelerationRInterface( pCont );

        // Make put the result in the MXS Vector channel
        IParticleChannelPoint3W* chMXSVectorW = NULL;
        IParticleChannelMatrix3W* chMXSMatrixW = NULL;
        IParticleChannelIntW* chMXSIntegerW = NULL;
        IParticleChannelQuatW* chOrientationW = NULL;

        if( usePosition && ( positionChoice == 0 ) ) {
            chMXSVectorW = (IParticleChannelPoint3W*)chCont->EnsureInterface(
                PARTICLECHANNELMXSVECTORW_INTERFACE, ParticleChannelPoint3_Class_ID, true,
                PARTICLECHANNELMXSVECTORR_INTERFACE, PARTICLECHANNELMXSVECTORW_INTERFACE, true );
            if( !chMXSVectorW )
                throw std::runtime_error(
                    "pflow_particle_interface::init_channels - Could not obtain the pflow MXSVectorW interface." );
        }

        IParticleChannelMeshMapW* chMap = (IParticleChannelMeshMapW*)chCont->EnsureInterface(
            PARTICLECHANNELSHAPETEXTUREW_INTERFACE, ParticleChannelMeshMap_Class_ID, true,
            PARTICLECHANNELSHAPETEXTURER_INTERFACE, PARTICLECHANNELSHAPETEXTUREW_INTERFACE, false, actionNode, NULL );
        if( chMap == NULL )
            throw std::runtime_error(
                "pflow_particle_interface::init_channels - Could not obtain the pflow MeshMapW interface." );

        int positionToUVWIndex = 0;
        int baryToUVWIndex = 0;
        int normalToUVWIndex = 0;
        int surfaceUVWIndex = 0;
        int surfaceUVWToUVWIndex = 0;

        IParticleChannelMapW* positionToUVWChannel = NULL;
        IParticleChannelMapW* baryToUVWChannel = NULL;
        IParticleChannelMapW* normalToUVWChannel = NULL;
        IParticleChannelMapW* surfaceUVWToUVWChannel = NULL;

        TVFace* surfaceUVWFaces = NULL;
        UVVert* surfaceUVWVerts = NULL;

        if( usePosition && ( positionChoice == 1 ) ) {
            positionToUVWIndex = pblock()->GetInt( kKrakatoaPFGeometryLookup_position_to_uvw_index );
            chMap->SetMapSupport( positionToUVWIndex, true );
            positionToUVWChannel = chMap->GetMapChannel( positionToUVWIndex );
            if( positionToUVWChannel == NULL )
                throw std::runtime_error(
                    "pflow_particle_interface::init_channels - Could not obtain the pflow map channel interface." );
            positionToUVWChannel->SetTVFace( NULL ); // no tvFace data for all particles
        }
        if( useBaryCoords ) {
            chMXSIntegerW = (IParticleChannelIntW*)chCont->EnsureInterface(
                PARTICLECHANNELMXSINTEGERW_INTERFACE, ParticleChannelInt_Class_ID, true,
                PARTICLECHANNELMXSINTEGERR_INTERFACE, PARTICLECHANNELMXSINTEGERW_INTERFACE, true );
            if( !chMXSIntegerW )
                throw std::runtime_error(
                    "pflow_particle_interface::init_channels - Could not obtain the pflow MXSVectorW interface." );

            baryToUVWIndex = pblock()->GetInt( kKrakatoaPFGeometryLookup_barycentric_coords_to_uvw_index );
            chMap->SetMapSupport( baryToUVWIndex, true );
            baryToUVWChannel = chMap->GetMapChannel( baryToUVWIndex );
            if( baryToUVWChannel == NULL )
                throw std::runtime_error(
                    "pflow_particle_interface::init_channels - Could not obtain the pflow map channel interface." );
            baryToUVWChannel->SetTVFace( NULL ); // no tvFace data for all particles
        }
        if( useNormals ) {
            if( normalChoice == 0 ) {
                chOrientationW = (IParticleChannelQuatW*)chCont->EnsureInterface(
                    PARTICLECHANNELORIENTATIONW_INTERFACE, ParticleChannelQuat_Class_ID, true,
                    PARTICLECHANNELORIENTATIONR_INTERFACE, PARTICLECHANNELORIENTATIONW_INTERFACE, true );
                if( chOrientationW == NULL )
                    throw std::runtime_error( "pflow_particle_interface::init_channels - Could not obtain the pflow "
                                              "OrientationW interface." );
            } else if( normalChoice == 1 ) {
                chMXSMatrixW = (IParticleChannelMatrix3W*)chCont->EnsureInterface(
                    PARTICLECHANNELMXSMATRIXW_INTERFACE, ParticleChannelMatrix3_Class_ID, true,
                    PARTICLECHANNELMXSMATRIXR_INTERFACE, PARTICLECHANNELMXSMATRIXW_INTERFACE, true );
                if( !chMXSMatrixW )
                    throw std::runtime_error(
                        "pflow_particle_interface::init_channels - Could not obtain the pflow MXSMatrix3W interface." );
            } else if( normalChoice == 2 ) {
                normalToUVWIndex = pblock()->GetInt( kKrakatoaPFGeometryLookup_normal_to_uvw_index );
                chMap->SetMapSupport( normalToUVWIndex, true );
                normalToUVWChannel = chMap->GetMapChannel( normalToUVWIndex );
                if( normalToUVWChannel == NULL )
                    throw std::runtime_error(
                        "pflow_particle_interface::init_channels - Could not obtain the pflow map channel interface." );
                normalToUVWChannel->SetTVFace( NULL ); // no tvFace data for all particles
            }
        }

        if( useSurfaceUVW &&
            ( nodeMesh.get()->mapSupport(
                surfaceUVWIndex = pblock()->GetInt( kKrakatoaPFGeometryLookup_surface_uvw_index_to_sample ) ) ) ) {
            surfaceUVWToUVWIndex = pblock()->GetInt( kKrakatoaPFGeometryLookup_surface_uvw_to_uvw_index );

            chMap->SetMapSupport( surfaceUVWToUVWIndex, true );
            surfaceUVWToUVWChannel = chMap->GetMapChannel( surfaceUVWToUVWIndex );
            if( surfaceUVWToUVWChannel == NULL )
                throw std::runtime_error(
                    "pflow_particle_interface::init_channels - Could not obtain the pflow map channel interface." );
            surfaceUVWToUVWChannel->SetTVFace( NULL ); // no tvFace data for all particles

            surfaceUVWFaces = nodeMesh.get()->mapFaces( surfaceUVWIndex );
            surfaceUVWVerts = nodeMesh.get()->mapVerts( surfaceUVWIndex );
        } else
            useSurfaceUVW =
                false; // if we want to use the surface uvw, but its not a supported map, force this parameter off

        bool newParticlesOnly = ( pblock()->GetInt( kKrakatoaPFGeometryLookup_applyOnce ) != FALSE );

        frantic::geometry::nearest_point_search_result nearestPoint;

        // test all the particles to see if they are inside/outside the geometry
        Point3 vel, accel;
        float timeStep;
        vector3f pos;
        for( int i = 0; i < count; ++i ) {
            if( newParticlesOnly && !chNewR->IsNew( i ) )
                continue;

            timeStep = float( timeEnd - chTimeR->GetValue( i ) );
            if( timeStep < 0.f )
                continue;

            // this is how pflow does advection, as evidenced by the SpawnCollisionTest sample code
            chAccelerationR ? accel = chAccelerationR->GetValue( i ) : accel = Point3::Origin;
            chVelocityR ? vel = chVelocityR->GetValue( i ) : vel = Point3::Origin;
            vel = vel + ( 0.5f * timeStep ) * accel;
            pos = from_max_t( chPosR->GetValue( i ) + vel * timeStep );

            bool res = m_kdtree->find_nearest_point( pos, distance, nearestPoint );
            if( !res )
                continue; // We didn't find a closest point, so there really isn't anything to do.

            if( usePosition ) {
                if( positionChoice == 0 )
                    chMXSVectorW->SetValue( i, to_max_t( nearestPoint.position ) );
                else
                    positionToUVWChannel->SetUVVert( i, UVVert( to_max_t( nearestPoint.position ) ) );
            }
            if( useBaryCoords ) {
                chMXSIntegerW->SetValue( i, nearestPoint.faceIndex );
                if( shiftBaryCoords ) {
                    baryToUVWChannel->SetUVVert(
                        i, UVVert( nearestPoint.barycentricCoords.y, nearestPoint.barycentricCoords.z, 0.f ) );
                } else {
                    baryToUVWChannel->SetUVVert( i, UVVert( to_max_t( nearestPoint.barycentricCoords ) ) );
                }
            }

            if( useNormals ) {
                UVVert normal;
                normal = m_cachedNormals->GetNormal( nearestPoint.faceIndex, 0 ) * nearestPoint.barycentricCoords.x;
                normal += m_cachedNormals->GetNormal( nearestPoint.faceIndex, 1 ) * nearestPoint.barycentricCoords.y;
                normal += m_cachedNormals->GetNormal( nearestPoint.faceIndex, 2 ) * nearestPoint.barycentricCoords.z;
                normal = normal.Normalize();
                if( normalChoice == 0 ) {
                    vector3f t, b;
                    frantic::shading::compute_tangent_binormal( from_max_t( normal ), t, b );

                    chOrientationW->SetValue( i, Quat( Matrix3( normal, to_max_t( t ), to_max_t( b ), Point3() ) ) );
                } else if( normalChoice == 1 ) {
                    vector3f t, b;
                    frantic::shading::compute_tangent_binormal( from_max_t( normal ), t, b );
                    chMXSMatrixW->SetValue( i, Matrix3( normal, to_max_t( t ), to_max_t( b ), to_max_t( pos ) ) );
                } else if( normalChoice == 2 ) {
                    normalToUVWChannel->SetUVVert( i, normal );
                }
            }

            if( useSurfaceUVW ) {
                Point3 uvwPoint;
                uvwPoint =
                    surfaceUVWVerts[surfaceUVWFaces[nearestPoint.faceIndex].t[0]] * nearestPoint.barycentricCoords.x;
                uvwPoint +=
                    surfaceUVWVerts[surfaceUVWFaces[nearestPoint.faceIndex].t[1]] * nearestPoint.barycentricCoords.y;
                uvwPoint +=
                    surfaceUVWVerts[surfaceUVWFaces[nearestPoint.faceIndex].t[2]] * nearestPoint.barycentricCoords.z;
                surfaceUVWToUVWChannel->SetUVVert( i, uvwPoint );
            }

            // bool isInside = m_cachedVolume->is_point_in_volume(pos);
            // vector3f normal;
        }
        // t1 += clock();
        // mprintf("Point lookup time: %d\n", t1);

    } catch( std::exception& e ) {
        GetCOREInterface()->Log()->LogEntry( SYSLOG_ERROR, DISPLAY_DIALOG,
                                             _T("KrakatoaPFGeometryLookup::Proceed() Error"),
                                             HANDLE_STD_EXCEPTION_MSG( e ) );
        if( IsNetworkRenderServer() )
            throw MAXException( HANDLE_STD_EXCEPTION_MSG( e ) );
        return false;
    }

    return true;
}

ClassDesc* KrakatoaPFGeometryLookup::GetClassDesc() const { return GetKrakatoaPFGeometryLookupDesc(); }

//} // end of namespace PFActions
