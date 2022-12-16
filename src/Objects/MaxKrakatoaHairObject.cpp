// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0
#include "stdafx.h"

#pragma warning( disable : 4100 )

#include "Objects\MaxKrakatoaHairObject.h"
#include "resource.h"

#include "MaxKrakatoa.h"
#include "MaxKrakatoaChannelModifier.h"
#include "MaxKrakatoaMaterial.hpp"
//#include "MaxKrakatoaReferenceTarget.h"
#include "MaxKrakatoaStdMaterialStream.h"
//#include "Objects\MaxKrakatoaPRTObject.h"

#include <boost/random.hpp>
#include <boost/tuple/tuple.hpp>

#include <frantic/diagnostics/profiling_section.hpp>
#include <frantic/particles/streams/apply_function_particle_istream.hpp>
#include <frantic/particles/streams/concatenated_particle_istream.hpp>
#include <frantic/particles/streams/empty_particle_istream.hpp>
#include <frantic/particles/streams/fractional_particle_istream.hpp>
#include <frantic/particles/streams/selection_culled_particle_istream.hpp>
#include <frantic/particles/streams/set_channel_particle_istream.hpp>
#include <frantic/particles/streams/spline_view_adaptive_particle_istream.hpp>
#include <frantic/particles/streams/transformed_particle_istream.hpp>
#include <frantic/strings/tstring.hpp>

#include <frantic/max3d/geometry/null_view.hpp>
#include <frantic/max3d/max_utility.hpp>
#include <frantic/max3d/particles/streams/deformed_particle_istream.hpp>

#include <custcont.h>
#include <iparamm2.h>

#if defined( ORNATRIX_SDK_AVAILABLE )
#include <StrandTopology.h>
#include <ihair.h>
#endif

#define MaxKrakatoaHairObject_NAME "PRT Hair"
#define MaxKrakatoaHairObject_VERSION 1

#define WM_UPDATEFILES WM_USER + 0x001

extern HINSTANCE hInstance;

extern Mesh* GetPRTHairIconMesh();
#if MAX_VERSION_MAJOR >= 25
extern MaxSDK::SharedMeshPtr GetPRTHairIconMeshShared();
#endif

using namespace frantic::graphics;
using namespace frantic::geometry;
using namespace frantic::particles::streams;
using namespace frantic::max3d::particles::streams;

#pragma warning( disable : 4189 4018 )

frantic::diagnostics::profiling_section psCacheSplines( _T("Cache Splines") ),
    psEvalWorldState( _T("Eval World State") ), psCreateStream( _T("Create Stream") ),
    psSplineTotal( _T("Spline Total") ), psComputeLength( _T("Compute Length") ), psBezierSolve( _T("Bezier Solve") ),
    psRootSolve( _T("Root Solve") );

class MaxKrakatoaHairObjectDesc : public ClassDesc2 {
    ParamBlockDesc2 m_paramDesc;

  public:
    MaxKrakatoaHairObjectDesc();
    virtual ~MaxKrakatoaHairObjectDesc();

    int IsPublic() { return TRUE; }
    void* Create( BOOL /*loading*/ ) { return new MaxKrakatoaHairObject; }
    const TCHAR* ClassName() { return _T( MaxKrakatoaHairObject_NAME ); }
#if MAX_VERSION_MAJOR >= 24
    const TCHAR* NonLocalizedClassName() { return _T( MaxKrakatoaHairObject_NAME ); }
#endif
    SClass_ID SuperClassID() { return GEOMOBJECT_CLASS_ID; }
    Class_ID ClassID() { return MaxKrakatoaHairObject_CLASSID; }
    const TCHAR* Category() { return _T("Krakatoa"); }

    // returns fixed parsable name (scripter-visible name)
    const TCHAR* InternalName() { return _T( MaxKrakatoaHairObject_NAME ); }
    HINSTANCE HInstance() { return hInstance; } // returns owning module handle
};

ClassDesc2* GetMaxKrakatoaHairObjectDesc() {
    static MaxKrakatoaHairObjectDesc theDesc;
    return &theDesc;
}

enum { kSourceTypeNode, kSourceTypeHairAndFur };

enum viewport_display_type { kDisplayPoints, kDisplayTangents };

enum {
    kTargetNode_deprecated,
    kSpacing,
    kFileList,
    kSourceType,
    kViewportSpacing,
    kViewportHairLimit,
    kUseViewAdaptive,
    kCameraNode,
    kPixelSpacing,
    kViewportUseViewAdaptive,
    kViewportDisplayType,
    kReferenceTime,
    kReferenceEnabled,
    kViewportEnabled,
    kDensityFalloff,
    kIconSize,
    kSourceNodes,
    kSelectedSource,
    kInWorldSpace
};

class MaxKrakatoaHairObjectDlgProc : public ParamMap2UserDlgProc {
  public:
    MaxKrakatoaHairObjectDlgProc();
    virtual ~MaxKrakatoaHairObjectDlgProc();
    virtual INT_PTR DlgProc( TimeValue t, IParamMap2* map, HWND hWnd, UINT msg, WPARAM wParam, LPARAM lParam );
    virtual void DeleteThis() { /*delete this;*/
    }
};

MaxKrakatoaHairObjectDlgProc::MaxKrakatoaHairObjectDlgProc() {}

MaxKrakatoaHairObjectDlgProc::~MaxKrakatoaHairObjectDlgProc() {}

INT_PTR MaxKrakatoaHairObjectDlgProc::DlgProc( TimeValue t, IParamMap2* map, HWND hWnd, UINT msg, WPARAM wParam,
                                               LPARAM lParam ) {
    // mprintf( "Got msg: 0x%X\n", msg );

    IParamBlock2* pblock = map->GetParamBlock();
    if( !pblock )
        return FALSE;

    switch( msg ) {
    case WM_INITDIALOG: {
        SendMessage( hWnd, WM_UPDATEFILES, 0, 0 );
        break;
    }
    case WM_COMMAND: {
        WORD msg = HIWORD( wParam );
        if( msg != BN_CLICKED )
            break;

        HWND rcvHandle = (HWND)lParam;

        if( rcvHandle == GetDlgItem( hWnd, IDC_HAIROBJECT_TARGETMENU_BUTTON ) ) {
            if( msg == BN_CLICKED ) {
                frantic::max3d::mxs::expression( _T("FranticParticleRenderMXS.OpenPRTHairOptionsRCMenu()") )
                    .evaluate<void>();
                return TRUE;
            }
        }

        break;
    }
    case WM_UPDATEFILES: {
        return TRUE;
    }
    }
    return FALSE;
}

MaxKrakatoaHairObjectDlgProc* GetMaxKrakatoaHairObjectDlgProc() {
    static MaxKrakatoaHairObjectDlgProc theMaxKrakatoaHairObjectDlgProc;
    return &theMaxKrakatoaHairObjectDlgProc;
}

class MaxKrakatoaHairObjectAccessor : public PBAccessor {
  public:
    virtual void Get( PB2Value& v, ReferenceMaker* owner, ParamID id, int tabIndex, TimeValue t, Interval& valid );
};

void MaxKrakatoaHairObjectAccessor::Get( PB2Value& v, ReferenceMaker* owner, ParamID id, int tabIndex, TimeValue t,
                                         Interval& valid ) {
    if( id != kSelectedSource || !owner )
        return;

    v.r = NULL;

    IParamBlock2* pb = owner->GetParamBlockByID( 0 );
    if( !pb )
        return;

    IParamMap2* pm = pb->GetMap( 0 );
    if( pm != NULL ) {
        HWND hWndSources = GetDlgItem( pm->GetHWnd(), IDC_HAIROBJECT_SOURCES_LISTBOX );
        int selIndex = -1;

        if( hWndSources != 0 )
            selIndex = ListBox_GetCurSel( hWndSources );

        const int stringLength = ListBox_GetTextLen( hWndSources, selIndex );
        std::vector<frantic::strings::tchar> selectedStringBuffer( stringLength + 1 );

        ListBox_GetText( hWndSources, selIndex, &selectedStringBuffer[0] );
        std::string selectedString = frantic::strings::to_string( &selectedStringBuffer[0] );

        if( selIndex >= 0 && selIndex < pb->Count( kSourceNodes ) ) {
            INode* sourceNode = pb->GetINode( kSourceNodes, t, selIndex );
            std::string sourceNodeString = frantic::strings::to_string( sourceNode->GetName() );

            if( selectedString != sourceNodeString ) {
                INode* currentNode = NULL;
                for( int i = 0; i < pb->Count( kSourceNodes ); ++i ) {
                    currentNode = pb->GetINode( kSourceNodes, t, i );
                    std::string currentString = frantic::strings::to_string( currentNode->GetName() );

                    if( currentString == selectedString ) {
                        break;
                    }
                }

                v.r = currentNode;
            } else {
                v.r = pb->GetINode( kSourceNodes, t, selIndex );
            }
        }
    }
}

PBAccessor* GetMaxKrakatoaHairObjectAccessor() {
    static MaxKrakatoaHairObjectAccessor theMaxKrakatoaHairObjectAccessor;
    return &theMaxKrakatoaHairObjectAccessor;
}

// interface IDs -- from shavemax project
const Interface_ID cHairInterfaceID( 0x4aa37035, 0xf3a686d );

// helper functions

template <class T>
inline frantic::graphics::vector3f get_hair_vert( T* hairNode, int vertIndex ) {
    float x, y, z;
    hairNode->GetVert( vertIndex, x, y, z );

    return frantic::graphics::vector3f( x, y, z );
}

template <class T>
inline frantic::graphics::vector3f get_hair_velocity( T* hairNode, int vertIndex ) {
    float x, y, z;
    hairNode->GetVelocity( vertIndex, x, y, z );

    return frantic::graphics::vector3f( x, y, z );
}

void export_hair_and_fur( const frantic::tstring& filename, TimeValue t ) {
    FPInterface* fpi = GetCOREInterface( cHairInterfaceID );
    if( !fpi )
        return;

    FunctionID fid = fpi->FindFn( _T("ExportDRA") );
    if( fid == FP_NO_FUNCTION )
        return;

    // Tab<int> ids;

    FPParams params( 3, TYPE_STRING, filename.c_str(), TYPE_INT, t, TYPE_INT, 1 //,
                                                                                // TYPE_INT_TAB_BR, &ids
    );

    FPValue result;

    FPStatus res = fpi->Invoke( fid, t, result, &params );

    if( res != FPS_OK )
        return;

    /*const FPValue& itabval = params.params[3];
    int n = itabval.i_tab->Count();
    if(n > 0)
    {
            shaveNodeIDs.Append(n,itabval.i_tab->Addr(0));
    }*/

    return;
}

#if defined( ORNATRIX_SDK_AVAILABLE )
void cache_splines_from_ornatrix( Ephere::Plugins::Autodesk::Max::Ornatrix::IHair* ihair, spline_container& outSplines,
                                  Box3* pBounds );
#endif

static inline frantic::graphics::vector3f transform_to_worldspace( const Point3& sourcePoint, const Matrix3& toWorldTM,
                                                                   const Matrix3& nodeInverseTM ) {
    Point3 transformedPoint = toWorldTM.PointTransform( sourcePoint );
    transformedPoint = nodeInverseTM.PointTransform( transformedPoint );

    return frantic::max3d::from_max_t( transformedPoint );
}

void cache_splines_from_node( INode* pHairNode, INode* pSourceNode, TimeValue t, Interval& outValid,
                              spline_container& outSplines, Box3* pBounds, bool inWorldSpace ) {
    outValid = FOREVER;
    outSplines.clear();

    // NOTE: This is the most expensive call here.
    psEvalWorldState.enter();
    ObjectState os = pSourceNode->EvalWorldState( t );
    psEvalWorldState.exit();

#if defined( ORNATRIX_SDK_AVAILABLE )
    typedef Ephere::Plugins::Autodesk::Max::Ornatrix::IHair IOrnatrixHair;

    if( IOrnatrixHair* ihair = static_cast<IOrnatrixHair*>(
            os.obj->GetInterface( Ephere::Plugins::Autodesk::Max::Ornatrix::IHairInterfaceID ) ) ) {
        cache_splines_from_ornatrix( ihair, outSplines, pBounds );
    } else
#endif
        if( os.obj->CanConvertToType( splineShapeClassID ) ) {
        BOOL doDelete = FALSE;
        SplineShape* pSplineShape = NULL;

        pSplineShape = (SplineShape*)os.obj->ConvertToType( t, splineShapeClassID );
        doDelete = pSplineShape != os.obj;
        outValid = os.Validity( t );

        BezierShape& theShape = pSplineShape->GetShape();
        outSplines.resize( theShape.SplineCount() );

        FF_LOG( debug ) << _T("PRT Hair target node: \"") << pSourceNode->GetName() << _T("\" had ")
                        << theShape.SplineCount() << _T(" splines at frame: ")
                        << ( (float)t / (float)GetTicksPerFrame() ) << std::endl;

        Matrix3 sourceMatrix3( true );
        Matrix3 hairMatrix3Inverse( true );
        if( inWorldSpace ) {
            sourceMatrix3 = pSourceNode->GetObjectTM( t, &outValid );
            hairMatrix3Inverse = pHairNode->GetObjectTM( t, &outValid );
            hairMatrix3Inverse.Invert();
        }

        for( std::size_t i = 0, iEnd = outSplines.size(); i < iEnd; ++i ) {
            Spline3D* pSpline = theShape.GetSpline( (int)i );

            int knotCount = pSpline->KnotCount();
            if( knotCount < 2 )
                continue;

            outSplines[i].reserve( 3 * knotCount - 2 );

            // if inWorldSpace is false, these are all identity matrix multiplications, so the result is not changed
            outSplines[i].push_back(
                transform_to_worldspace( pSpline->GetKnotPoint( 0 ), sourceMatrix3, hairMatrix3Inverse ) );
            outSplines[i].push_back(
                transform_to_worldspace( pSpline->GetOutVec( 0 ), sourceMatrix3, hairMatrix3Inverse ) );

            for( std::size_t j = 1, jEnd = std::size_t( knotCount - 1 ); j < jEnd; ++j ) {
                outSplines[i].push_back(
                    transform_to_worldspace( pSpline->GetInVec( (int)j ), sourceMatrix3, hairMatrix3Inverse ) );
                outSplines[i].push_back(
                    transform_to_worldspace( pSpline->GetKnotPoint( (int)j ), sourceMatrix3, hairMatrix3Inverse ) );
                outSplines[i].push_back(
                    transform_to_worldspace( pSpline->GetOutVec( (int)j ), sourceMatrix3, hairMatrix3Inverse ) );
            }

            outSplines[i].push_back(
                transform_to_worldspace( pSpline->GetInVec( knotCount - 1 ), sourceMatrix3, hairMatrix3Inverse ) );
            outSplines[i].push_back(
                transform_to_worldspace( pSpline->GetKnotPoint( knotCount - 1 ), sourceMatrix3, hairMatrix3Inverse ) );

            // Fill in the object bounds if it is desired.
            if( pBounds ) {
                for( std::size_t j = 0, jEnd = outSplines[i].size(); j < jEnd; ++j )
                    ( *pBounds ) += frantic::max3d::to_max_t( outSplines[i][j] );
            }
        }

        // TODO: This isn't freeing the memory for HairFarm objects, since they seem to cache the splines. Something
        // more must be done in that case.
        if( doDelete )
            pSplineShape->MaybeAutoDelete();
    } else {
        std::basic_stringstream<frantic::tchar> ss;
        ss << _T("PRT Hair target node: \"") << pSourceNode->GetName()
           << _T("\" was NOT able to be converted to splines.") << std::endl;

        throw std::runtime_error( frantic::strings::to_string( ss.str() ) );
    }
}

#if defined( ORNATRIX_SDK_AVAILABLE )
void cache_splines_from_ornatrix( Ephere::Plugins::Autodesk::Max::Ornatrix::IHair* ihair, spline_container& outSplines,
                                  Box3* pBounds ) {
    using namespace Ephere::Plugins::Autodesk::Max::Ornatrix;

    outSplines.clear();
    outSplines.resize( ihair->NumRoots() );

    bool useRootTM = ihair->HasRootTM();

    Matrix3 tm( TRUE );

    FF_LOG( debug ) << _T("Ornatrix Num Frames: ") << ihair->NumFrames() << std::endl;

    for( unsigned i = 0, iEnd = ihair->NumRoots(); i < iEnd; ++i ) {
        unsigned numVerts = ihair->NumPts( i );
        if( numVerts < 2 )
            continue;

        outSplines[i].reserve( 3 * numVerts - 2 );

        if( useRootTM )
            ihair->GetRootTM( i, tm );

        frantic::graphics::vector3f p = frantic::max3d::from_max_t( ihair->GetPoint( i, 0 ) * tm );
        frantic::graphics::vector3f pNext = frantic::max3d::from_max_t( ihair->GetPoint( i, 1 ) * tm );
        frantic::graphics::vector3f pNext2, tan;

        // First and last segments get linear tangents, the other segments use Catmull-Rom tangents.
        outSplines[i].push_back( p );
        outSplines[i].push_back( p + ( pNext - p ) / 3.f );

        for( unsigned j = 2; j < numVerts; ++j ) {
            pNext2 = frantic::max3d::from_max_t( ihair->GetPoint( i, j ) * tm );

            tan = ( pNext2 - p ) / 6.f;

            outSplines[i].push_back( pNext - tan );
            outSplines[i].push_back( pNext );
            outSplines[i].push_back( pNext + tan );

            p = pNext;
            pNext = pNext2;
        }

        outSplines[i].push_back( pNext + ( p - pNext ) / 3.f );
        outSplines[i].push_back( pNext );

        // Fill in the object bounds if it is desired.
        if( pBounds ) {
            for( spline_container::value_type::const_iterator it = outSplines[i].begin(), itEnd = outSplines[i].end();
                 it != itEnd; ++it )
                ( *pBounds ) += frantic::max3d::to_max_t( *it );
        }
    }
}
#endif

struct HairObjectPBValidator : public PBValidator {
    virtual BOOL Validate( PB2Value& v );
    virtual BOOL Validate( PB2Value& v, ReferenceMaker* owner, ParamID id, int tabIndex );
};

BOOL HairObjectPBValidator::Validate( PB2Value& v ) {
    return FALSE; // Don't use this version, use the fancier one
}

BOOL HairObjectPBValidator::Validate( PB2Value& v, ReferenceMaker* owner, ParamID id, int tabIndex ) {
    if( id != kSourceNodes || !v.r )
        return TRUE;

    INode* pNode = static_cast<INode*>( v.r );

    if( IParamBlock2* pb = owner->GetParamBlockByID( 0 ) ) {
        // Check if we already have this in the list, at a different position.
        for( int i = 0, iEnd = pb->Count( kSourceNodes ); i < iEnd; ++i ) {
            if( pb->GetINode( kSourceNodes, 0, i ) == pNode )
                return FALSE;
        }
    }

    // We need a time and one isn't offered to Validate() so I pick the "current" time.
    ObjectState os = pNode->EvalWorldState( GetCOREInterface()->GetTime() );

    if( !os.obj || os.obj == owner || !os.obj->CanConvertToType( splineShapeClassID ) )
        return FALSE;

    return TRUE;
}

HairObjectPBValidator* GetHairObjectPBValidator() {
    static HairObjectPBValidator hairObjectPBValidator;
    return &hairObjectPBValidator;
}

MaxKrakatoaHairObjectDesc::MaxKrakatoaHairObjectDesc()
    : m_paramDesc( 0,                                                     // Block num
                   _T("Parameters"),                                      // Internal name
                   NULL,                                                  // Localized name
                   NULL,                                                  // ClassDesc2*
                   P_AUTO_CONSTRUCT + P_AUTO_UI + P_MULTIMAP + P_VERSION, // Flags
                   MaxKrakatoaHairObject_VERSION,
                   0,                                                 // PBlock Ref Num
                   1, 0, IDD_HAIROBJECT, IDS_HAIR_ROLLOUT_NAME, 0, 0, // AutoUI stuff
                   GetMaxKrakatoaHairObjectDlgProc(),                 // Custom UI handling
                   p_end ) {
    m_paramDesc.SetClassDesc( this );

    m_paramDesc.AddParam( kTargetNode_deprecated, _T("TargetNode"), TYPE_INODE, 0, IDS_HAIR_TARGETNODE, p_end );
    m_paramDesc.AddParam( kFileList, _T("FileList"), TYPE_FILENAME_TAB, 0, P_VARIABLE_SIZE | P_RESET_DEFAULT, 0,
                          p_end );

    m_paramDesc.AddParam( kSourceType, _T("SourceType"), TYPE_INT, P_RESET_DEFAULT, IDS_HAIR_SOURCETYPE, p_end );
    m_paramDesc.ParamOption( kSourceType, p_default, kSourceTypeNode );

    //-----------------------------------------------------------------------------------------------------------------------------------------------------------------
    // Source
    //-----------------------------------------------------------------------------------------------------------------------------------------------------------------
    m_paramDesc.AddParam( kSourceNodes, _T("SourceNodes"), TYPE_INODE_TAB, 0, P_VARIABLE_SIZE, IDS_HAIR_SOURCENODES,
                          p_end );
    m_paramDesc.ParamOption( kSourceNodes, p_validator, GetHairObjectPBValidator() );
    m_paramDesc.ParamOption( kSourceNodes, p_ui, 0, TYPE_NODELISTBOX, IDC_HAIROBJECT_SOURCES_LISTBOX,
                             IDC_HAIROBJECT_ADDSOURCE_BUTTON, 0, IDC_HAIROBJECT_REMOVESOURCE_BUTTON, p_end );

    m_paramDesc.AddParam( kSelectedSource, _T("SelectedSource"), TYPE_INODE, P_TRANSIENT, 0, p_end );
    m_paramDesc.ParamOption( kSelectedSource, p_accessor, GetMaxKrakatoaHairObjectAccessor() );

    //-----------------------------------------------------------------------------------------------------------------------------------------------------------------
    // Generation
    //-----------------------------------------------------------------------------------------------------------------------------------------------------------------
    m_paramDesc.AddParam( kSpacing, _T("Spacing"), TYPE_FLOAT, P_ANIMATABLE | P_RESET_DEFAULT, IDS_HAIR_SPACING,
                          p_end );
    m_paramDesc.ParamOption( kSpacing, p_default, 0.1f );
    m_paramDesc.ParamOption( kSpacing, p_range, 1e-5f, FLT_MAX );
    m_paramDesc.ParamOption( kSpacing, p_ui, 0, TYPE_SPINNER, EDITTYPE_POS_FLOAT, IDC_HAIROBJECT_SPACING_EDIT,
                             IDC_HAIROBJECT_SPACING_SPIN, SPIN_AUTOSCALE, p_end );

    m_paramDesc.AddParam( kViewportEnabled, _T("ViewportEnabled"), TYPE_BOOL, P_RESET_DEFAULT, IDS_HAIR_VIEWPORTENABLED,
                          p_end );
    m_paramDesc.ParamOption( kViewportEnabled, p_default, TRUE );
    m_paramDesc.ParamOption( kViewportEnabled, p_ui, 0, TYPE_SINGLECHEKBOX, IDC_HAIROBJECT_VIEWENABLED_CHECK );

    m_paramDesc.AddParam( kViewportSpacing, _T("ViewportSpacing"), TYPE_FLOAT, P_ANIMATABLE | P_RESET_DEFAULT,
                          IDS_HAIR_VIEWPORTSPACING, p_end );
    m_paramDesc.ParamOption( kViewportSpacing, p_default, 1.f );
    m_paramDesc.ParamOption( kViewportSpacing, p_range, 1e-3f, FLT_MAX );
    m_paramDesc.ParamOption( kViewportSpacing, p_ui, 0, TYPE_SPINNER, EDITTYPE_POS_FLOAT,
                             IDC_HAIROBJECT_VIEWSPACING_EDIT, IDC_HAIROBJECT_VIEWSPACING_SPIN, SPIN_AUTOSCALE, p_end );

    m_paramDesc.AddParam( kViewportHairLimit, _T("ViewportHairLimit"), TYPE_INT, P_ANIMATABLE | P_RESET_DEFAULT,
                          IDS_HAIR_VIEWPORTHAIRLIMIT, p_end );
    m_paramDesc.ParamOption( kViewportHairLimit, p_default, 1000 );
    m_paramDesc.ParamOption( kViewportHairLimit, p_range, 1, INT_MAX );
    m_paramDesc.ParamOption( kViewportHairLimit, p_ui, 0, TYPE_SPINNER, EDITTYPE_POS_INT, IDC_HAIROBJECT_VIEWLIMIT_EDIT,
                             IDC_HAIROBJECT_VIEWLIMIT_SPIN, SPIN_AUTOSCALE, p_end );

    m_paramDesc.AddParam( kInWorldSpace, _T("InWorldSpace"), TYPE_BOOL, P_RESET_DEFAULT, IDS_HAIR_WORLDSPACE, p_end );
    m_paramDesc.ParamOption( kInWorldSpace, p_default, FALSE );
    m_paramDesc.ParamOption( kInWorldSpace, p_ui, 0, TYPE_SINGLECHEKBOX, IDC_HAIROBJECT_WORLDSPACE_CHECK );

    //------------------------------------------------------------------------------------------------------------------------------------------------------------------
    // Data Controls
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------
    m_paramDesc.AddParam( kDensityFalloff, _T("DensityFalloff"), TYPE_FLOAT, P_ANIMATABLE | P_RESET_DEFAULT,
                          IDS_HAIR_DENSITYFALLOFF, p_end );
    m_paramDesc.ParamOption( kDensityFalloff, p_default, 5.f );
    m_paramDesc.ParamOption( kDensityFalloff, p_range, 0.f, FLT_MAX );
    m_paramDesc.ParamOption( kDensityFalloff, p_ui, 0, TYPE_SPINNER, EDITTYPE_POS_FLOAT,
                             IDC_HAIROBJECT_DENSITYFALLOFF_EDIT, IDC_HAIROBJECT_DENSITYFALLOFF_SPIN, SPIN_AUTOSCALE,
                             p_end );

    //------------------------------------------------------------------------------------------------------------------------------------------------------------------
    // View Adaptive
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------
    m_paramDesc.AddParam( kUseViewAdaptive, _T("UseViewAdaptive"), TYPE_BOOL, P_RESET_DEFAULT, IDS_HAIR_USEVIEWADAPTIVE,
                          p_end );
    m_paramDesc.ParamOption( kUseViewAdaptive, p_default, FALSE );
    m_paramDesc.ParamOption( kUseViewAdaptive, p_ui, 0, TYPE_SINGLECHEKBOX, IDC_HAIROBJECT_VIEWADAPTIVE_CHECK );

    m_paramDesc.AddParam( kViewportUseViewAdaptive, _T("ViewportUseViewAdaptive"), TYPE_BOOL, P_RESET_DEFAULT,
                          IDS_HAIR_VIEWPORTUSEVIEWADAPTIVE, p_end );
    m_paramDesc.ParamOption( kViewportUseViewAdaptive, p_default, FALSE );
    m_paramDesc.ParamOption( kViewportUseViewAdaptive, p_ui, 0, TYPE_SINGLECHEKBOX,
                             IDC_HAIROBJECT_VIEWADAPTIVEVIEWPORT_CHECK );

    m_paramDesc.AddParam( kCameraNode, _T("CameraNode"), TYPE_INODE, 0, IDS_HAIR_CAMERANODE, p_end );
    m_paramDesc.ParamOption( kCameraNode, p_sclassID, CAMERA_CLASS_ID, p_end );
    m_paramDesc.ParamOption( kCameraNode, p_ui, 0, TYPE_PICKNODEBUTTON, IDC_HAIROBJECT_CAMERANODE, p_end );

    m_paramDesc.AddParam( kPixelSpacing, _T("PixelSpacing"), TYPE_FLOAT, P_ANIMATABLE | P_RESET_DEFAULT,
                          IDS_HAIR_PIXELSPACING, p_end );
    m_paramDesc.ParamOption( kPixelSpacing, p_default, 0.5f );
    m_paramDesc.ParamOption( kPixelSpacing, p_range, 1e-3f, 5.f );
    m_paramDesc.ParamOption( kPixelSpacing, p_ui, 0, TYPE_SPINNER, EDITTYPE_POS_FLOAT, IDC_HAIROBJECT_PIXELSPACING_EDIT,
                             IDC_HAIROBJECT_PIXELSPACING_SPIN, SPIN_AUTOSCALE, p_end );

    //------------------------------------------------------------------------------------------------------------------------------------------------------------------
    // Reference Position
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------
    m_paramDesc.AddParam( kReferenceEnabled, _T("ReferencePositionEnabled"), TYPE_BOOL, 0,
                          IDS_HAIR_REFERENCEPOSITIONENABLED, p_end );
    m_paramDesc.ParamOption( kReferenceEnabled, p_default, FALSE );
    m_paramDesc.ParamOption( kReferenceEnabled, p_ui, 0, TYPE_SINGLECHEKBOX, IDC_HAIROBJECT_REFERENCEFRAME_ENABLE );

    m_paramDesc.AddParam( kReferenceTime, _T("ReferenceTime"), TYPE_INT, P_RESET_DEFAULT, IDS_HAIR_REFERENCETIME,
                          p_end );
    m_paramDesc.ParamOption( kReferenceTime, p_default, 0 );
    m_paramDesc.ParamOption( kReferenceTime, p_range, INT_MIN, INT_MAX );
    m_paramDesc.ParamOption( kReferenceTime, p_ui, 0, TYPE_SPINNER, EDITTYPE_INT, IDC_HAIROBJECT_REFERENCEFRAME_EDIT,
                             IDC_HAIROBJECT_REFERENCEFRAME_SPIN, SPIN_AUTOSCALE );

    //------------------------------------------------------------------------------------------------------------------------------------------------------------------
    // Extra Options
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------
    m_paramDesc.AddParam( kViewportDisplayType, _T("ViewportDisplayType"), TYPE_INT, P_RESET_DEFAULT,
                          IDS_HAIR_VIEWPORTDISPLAYTYPE, p_end );
    m_paramDesc.ParamOption( kViewportDisplayType, p_default, kDisplayPoints );

#if MAX_RELEASE >= 12000
    m_paramDesc.ParamOption( kViewportDisplayType, p_ui, 0, TYPE_INT_COMBOBOX, IDC_HAIROBJECT_VIEWTYPE_COMBO, 2,
                             IDS_PRTHAIR_DISPLAY0, IDS_PRTHAIR_DISPLAY1 );
#endif

    m_paramDesc.AddParam( kIconSize, _T("IconSize"), TYPE_FLOAT, P_RESET_DEFAULT, IDS_HAIR_ICONSIZE, p_end );
    m_paramDesc.ParamOption( kIconSize, p_default, 30.f );
    m_paramDesc.ParamOption( kIconSize, p_range, 0.f, FLT_MAX );
    m_paramDesc.ParamOption( kIconSize, p_ui, 0, TYPE_SPINNER, EDITTYPE_POS_FLOAT, IDC_HAIROBJECT_ICONSIZE_EDIT,
                             IDC_HAIROBJECT_ICONSIZE_SPIN, SPIN_AUTOSCALE, p_end );
}

MaxKrakatoaHairObjectDesc::~MaxKrakatoaHairObjectDesc() {}

Mesh* MaxKrakatoaHairObject::GetIconMesh( Matrix3& outTM ) {
    float size = m_pblock->GetFloat( kIconSize );

    outTM.SetScale( Point3( size, size, size ) );
    return GetPRTHairIconMesh();
}

#if MAX_VERSION_MAJOR >= 25
MaxSDK::SharedMeshPtr MaxKrakatoaHairObject::GetIconMeshShared( Matrix3& outTM ) {
    float size = m_pblock->GetFloat( kIconSize );

    outTM.SetScale( Point3( size, size, size ) );
    return GetPRTHairIconMeshShared();
}
#endif

MaxKrakatoaHairObject::MaxKrakatoaHairObject() {
    for( int i = 0, iEnd = NumRefs(); i < iEnd; ++i )
        SetReference( i, NULL );

    GetMaxKrakatoaHairObjectDesc()->MakeAutoParamBlocks( this );

    m_isEvaluatingNode = false;

    m_timeStep = GetTicksPerFrame();

    m_cachedSplines.push_back( spline_container() );
    m_cachedSplinesOffsetTime.push_back( spline_container() );
    m_cachedSplinesReferenceTime.push_back( spline_container() );

    m_cachedSplinesValid.push_back( NEVER );
    m_cachedSplinesOffsetTimeValid.push_back( NEVER );
    m_cachedSplinesReferenceTimeValid.push_back( NEVER );

    m_objectBounds.push_back( Box3() );
}

MaxKrakatoaHairObject::~MaxKrakatoaHairObject() {
    // If we are writing Hair&Fur to a temp file, make sure to clean up the file.
    if( !m_shavePath.empty() ) {
#ifndef FRANTIC_USE_WCHAR
        remove( m_shavePath.c_str() );
        remove( ( m_shavePath + "ref.tmp" ).c_str() );
#else
        _wremove( m_shavePath.c_str() );
        _wremove( ( m_shavePath + L"ref.tmp" ).c_str() );
#endif
    }
}

ClassDesc2* MaxKrakatoaHairObject::GetClassDesc() { return GetMaxKrakatoaHairObjectDesc(); }

void MaxKrakatoaHairObject::InvalidateReferenceFrame() {
    super_type::InvalidateObjectAndViewport();

    m_cachedSplinesReferenceTimeValid.assign( m_cachedSplinesReferenceTimeValid.size(), NEVER );
}

void MaxKrakatoaHairObject::InvalidateObjectAndViewport() {
    super_type::InvalidateObjectAndViewport();

    m_cachedSplinesValid.assign( m_cachedSplinesValid.size(), NEVER );
    m_cachedSplinesOffsetTimeValid.assign( m_cachedSplinesOffsetTimeValid.size(), NEVER );
    m_cachedSplinesReferenceTimeValid.assign( m_cachedSplinesReferenceTimeValid.size(), NEVER );
}

void MaxKrakatoaHairObject::SetIconSize( float size ) { m_pblock->SetValue( kIconSize, 0, size ); }

struct density_falloff_shader {
    static const boost::array<frantic::tstring, 3> s_channels;

    static float apply( float density, float distance, float hairLength, float power ) {
        return density * ( 1.f - powf( distance / hairLength, power ) );
    }
};

void MaxKrakatoaHairObject::ClearSplines() {
    m_objectBounds.clear();

    m_cachedSplines.clear();
    m_cachedSplinesOffsetTime.clear();
    m_cachedSplinesReferenceTime.clear();

    m_cachedSplinesValid.clear();
    m_cachedSplinesOffsetTimeValid.clear();
    m_cachedSplinesReferenceTimeValid.clear();
}

void MaxKrakatoaHairObject::ClearSpline( spline_container* cachedSpline, spline_container* cachedSplineOffsetTime,
                                         spline_container* cachedSplineReferenceTime, Interval* cachedSplineValid,
                                         Interval* cachedSplineOffsetTimeValid,
                                         Interval* cachedSplineReferenceTimeValid, Box3* objectBounds ) {
    objectBounds->Init();
    cachedSpline->clear();
    cachedSplineOffsetTime->clear();
    cachedSplineReferenceTime->clear();

    *cachedSplineValid = FOREVER;
    *cachedSplineOffsetTimeValid = FOREVER;
    *cachedSplineReferenceTimeValid = FOREVER;
}

bool MaxKrakatoaHairObject::InWorldSpace() {
    int numSources = m_pblock->Count( kSourceNodes );
    return ( numSources > 1 ) || ( m_pblock->GetInt( kInWorldSpace ) != FALSE );
}

const boost::array<frantic::tstring, 3> density_falloff_shader::s_channels = { _T("Density"), _T("Distance"),
                                                                               _T("HairLength") };

particle_istream_ptr
MaxKrakatoaHairObject::GetInternalStream( INode* pNode, TimeValue t, Interval& inoutValidity,
                                          frantic::max3d::particles::IMaxKrakatoaPRTEvalContextPtr evalContext ) {
    boost::shared_ptr<frantic::particles::streams::particle_istream> pin;
    boost::shared_ptr<frantic::graphics::camera<float>> pCamera;

    // loading data from older versions of PRT Hair
    INode* targetNode = m_pblock->GetINode( kTargetNode_deprecated, t );
    if( targetNode && !targetNode->IsRootNode() ) {
        m_pblock->Append( kSourceNodes, 1, &targetNode );

        Interface* maxInterface = GetCOREInterface();
        INode* rootNode = maxInterface->GetRootNode();
        m_pblock->SetValue( kTargetNode_deprecated, t, rootNode );
    }

    int numSources = m_pblock->Count( kSourceNodes );
    if( numSources == 0 ) {
        ClearSplines();
        return particle_istream_ptr(
            new frantic::particles::streams::empty_particle_istream( evalContext->GetDefaultChannels() ) );
    }

    m_cachedSplines.resize( numSources );
    m_cachedSplinesOffsetTime.resize( numSources );
    m_cachedSplinesReferenceTime.resize( numSources );
    m_cachedSplinesValid.resize( numSources );
    m_cachedSplinesOffsetTimeValid.resize( numSources );
    m_cachedSplinesReferenceTimeValid.resize( numSources );
    m_objectBounds.resize( numSources );

    std::vector<particle_istream_ptr> particleStreams;

    bool inWorldSpace = InWorldSpace();

    float pixelSpacing = 1.0f;
    if( m_pblock->GetInt( kUseViewAdaptive ) && ( m_inRenderMode || m_pblock->GetInt( kViewportUseViewAdaptive ) ) ) {
        INode* pCameraNode = m_pblock->GetINode( kCameraNode );
        if( !pCameraNode )
            return particle_istream_ptr(
                new frantic::particles::streams::empty_particle_istream( evalContext->GetDefaultChannels() ) );

        Interface* ip = GetCOREInterface();
        int width = ip->GetRendWidth();
        int height = ip->GetRendHeight();
        pCamera.reset(
            new frantic::graphics::camera<float>( pCameraNode, t, frantic::graphics2d::size2( width, height ) ) );

        transform4f worldToCamTM;
        worldToCamTM = pCamera->world_transform_inverse() * frantic::max3d::from_max_t( pNode->GetObjectTM( t ) );
        worldToCamTM = worldToCamTM.to_inverse();

        pCamera->set_transform( worldToCamTM );

        pixelSpacing = m_pblock->GetFloat( kPixelSpacing, t );
    }

    for( int sourceIndex = 0; sourceIndex < numSources; ++sourceIndex ) {
        INode* pSourceNode = m_pblock->GetINode( kSourceNodes, t, sourceIndex );
        spline_container* cachedSpline = &m_cachedSplines[sourceIndex];
        spline_container* cachedSplineOffsetTime = &m_cachedSplinesOffsetTime[sourceIndex];
        spline_container* cachedSplineReferenceTime = &m_cachedSplinesReferenceTime[sourceIndex];
        Interval* cachedSplineValid = &m_cachedSplinesValid[sourceIndex];
        Interval* cachedSplineOffsetTimeValid = &m_cachedSplinesOffsetTimeValid[sourceIndex];
        Interval* cachedSplineReferenceTimeValid = &m_cachedSplinesReferenceTimeValid[sourceIndex];
        Box3* objectBounds = &m_objectBounds[sourceIndex];

        if( inWorldSpace ) {
            *cachedSplineValid = NEVER;
            *cachedSplineOffsetTimeValid = NEVER;
            *cachedSplineReferenceTimeValid = NEVER;
        }

        CacheSpline( t, m_inRenderMode, pNode, pSourceNode, cachedSpline, cachedSplineOffsetTime,
                     cachedSplineReferenceTime, cachedSplineValid, cachedSplineOffsetTimeValid,
                     cachedSplineReferenceTimeValid, objectBounds );

        if( cachedSpline->size() == 0 ) {
            continue;
        }

        psCreateStream.enter();
        if( m_inRenderMode ) {
            float distanceStep = m_pblock->GetFloat( kSpacing, t );
            float timeStep = (float)m_timeStep / (float)TIME_TICKSPERSEC;

            std::vector<std::vector<frantic::graphics::vector3f>> splinesReferenceTime;

            if( cachedSplineReferenceTime->size() > 0 ) {
                splinesReferenceTime.resize( cachedSplineReferenceTime->size() );

                TimeValue referenceTime = GetTicksPerFrame() * m_pblock->GetTimeValue( kReferenceTime );
                frantic::graphics::transform4f refTM = frantic::max3d::from_max_t( pNode->GetNodeTM( referenceTime ) );

                // Have to transform these splines into worldspace (at the reference time) in order to get a useful
                // "reference pose"
                for( std::size_t i = 0, iEnd = splinesReferenceTime.size(); i < iEnd; ++i ) {
                    splinesReferenceTime[i].reserve( ( *cachedSplineReferenceTime )[i].size() );
                    for( std::size_t j = 0, jEnd = ( *cachedSplineReferenceTime )[i].size(); j < jEnd; ++j )
                        splinesReferenceTime[i].push_back( refTM * ( *cachedSplineReferenceTime )[i][j] );
                }
            }

            pin.reset( new frantic::particles::streams::spline_particle_istream(
                *cachedSpline, *cachedSplineOffsetTime, splinesReferenceTime, timeStep, distanceStep, pCamera,
                pixelSpacing ) );
        } else {
            float distanceStep = m_pblock->GetFloat( kViewportSpacing, t );
            float timeStep = (float)m_timeStep / (float)TIME_TICKSPERSEC;

            std::size_t hairLimit = (std::size_t)m_pblock->GetInt( kViewportHairLimit, t );
            if( cachedSpline->size() < hairLimit )
                hairLimit = cachedSpline->size();

            std::vector<std::vector<frantic::graphics::vector3f>> splines;
            std::vector<std::vector<frantic::graphics::vector3f>> splinesOffsetTime;
            std::vector<std::vector<frantic::graphics::vector3f>> splinesReferenceTime;

            splines.assign( cachedSpline->begin(), cachedSpline->begin() + hairLimit );

            if( cachedSplineOffsetTime->size() > 0 )
                splinesOffsetTime.assign( cachedSplineOffsetTime->begin(),
                                          cachedSplineOffsetTime->begin() + hairLimit );

            if( cachedSplineReferenceTime->size() > 0 ) {
                splinesReferenceTime.resize( hairLimit );

                TimeValue referenceTime = GetTicksPerFrame() * m_pblock->GetTimeValue( kReferenceTime );
                frantic::graphics::transform4f refTM = frantic::max3d::from_max_t( pNode->GetNodeTM( referenceTime ) );

                // Have to transform these splines into worldspace (at the reference time) in order to get a useful
                // "reference pose"
                for( std::size_t i = 0, iEnd = splinesReferenceTime.size(); i < iEnd; ++i ) {
                    splinesReferenceTime[i].reserve( ( *cachedSplineReferenceTime )[i].size() );
                    for( std::size_t j = 0, jEnd = ( *cachedSplineReferenceTime )[i].size(); j < jEnd; ++j )
                        splinesReferenceTime[i].push_back( refTM * ( *cachedSplineReferenceTime )[i][j] );
                }
            }

            // TODO: Make a constructor that takes a pair of iterators instead of a vector
            pin.reset( new frantic::particles::streams::spline_particle_istream(
                splines, splinesOffsetTime, splinesReferenceTime, timeStep, distanceStep, pCamera, pixelSpacing ) );

            if( m_pblock->GetInt( kViewportDisplayType ) == kDisplayTangents ) {
                class Tangent_to_PRTViewportVector {
                  public:
                    static frantic::graphics::vector3f fn( const frantic::graphics::transform4f& fromWorldTM,
                                                           const frantic::graphics::vector3f& inTangent ) {
                        return fromWorldTM.transpose_transform_no_translation( inTangent );
                    }
                };

                frantic::graphics::transform4f toWorldTM = frantic::max3d::from_max_t( pNode->GetNodeTM( t ) );
                frantic::graphics::transform4f fromWorldTM = toWorldTM.to_inverse();

                boost::array<frantic::tstring, 1> copy_op_inputs = { _T("Tangent") };
                pin.reset(
                    new frantic::particles::streams::apply_function_particle_istream<vector3f( const vector3f& )>(
                        pin, boost::bind( &Tangent_to_PRTViewportVector::fn, fromWorldTM, _1 ), _T("PRTViewportVector"),
                        copy_op_inputs ) );
            }
        }

        float densityFalloff = m_pblock->GetFloat( kDensityFalloff, t );
        if( densityFalloff > 0 )
            pin.reset( new frantic::particles::streams::apply_function_particle_istream<float( float, float, float )>(
                pin, boost::bind( &density_falloff_shader::apply, _1, _2, _3, densityFalloff ), _T("Density"),
                density_falloff_shader::s_channels ) );

        psCreateStream.exit();

        pin->set_channel_map( evalContext->GetDefaultChannels() );
        particleStreams.push_back( pin );
    }

    inoutValidity &= Interval( t, t );

    particle_istream_ptr concatenatedStreams = create_concatenated_particle_istream( particleStreams );
    return concatenatedStreams;
}

void MaxKrakatoaHairObject::CacheSpline( TimeValue t, bool forRender, INode* pHairNode, INode* pSourceNode,
                                         spline_container* cachedSpline, spline_container* cachedSplineOffsetTime,
                                         spline_container* cachedSplineReferenceTime, Interval* cachedSplineValid,
                                         Interval* cachedSplineOffsetTimeValid,
                                         Interval* cachedSplineReferenceTimeValid, Box3* objectBounds ) {
    bool inWorldSpace = InWorldSpace();

    if( !m_inRenderMode && !m_pblock->GetInt( kViewportEnabled ) ) {
        m_objectValidity = FOREVER;
        ClearSpline( cachedSpline, cachedSplineOffsetTime, cachedSplineReferenceTime, cachedSplineValid,
                     cachedSplineOffsetTimeValid, cachedSplineReferenceTimeValid, objectBounds );
        return;
    }

    try {
        switch( m_pblock->GetInt( kSourceType ) ) {
        case kSourceTypeNode:
        case kSourceTypeHairAndFur: {
            m_timeStep = GetTicksPerFrame(); // Use a whole frame as the timestep since some HairFarm scenes were only
                                             // valid at wholeframes.=
            TimeValue referenceTime = GetTicksPerFrame() * m_pblock->GetTimeValue( kReferenceTime );
            TimeValue offsetTime = t - m_timeStep; // This is negative because I want to evaluate in a forward manner,
                                                   // and have time 't' be the last eval.

            if( !pSourceNode ) {
                ClearSpline( cachedSpline, cachedSplineOffsetTime, cachedSplineReferenceTime, cachedSplineValid,
                             cachedSplineOffsetTimeValid, cachedSplineReferenceTimeValid, objectBounds );
                m_objectValidity = FOREVER;

                return;
            }

            m_objectValidity = FOREVER;

            if( !cachedSplineReferenceTimeValid->InInterval( referenceTime ) || forRender ) {
                if( m_pblock->GetInt( kReferenceEnabled ) ) {
                    m_isEvaluatingNode = true;
                    cache_splines_from_node( pHairNode, pSourceNode, referenceTime, *cachedSplineReferenceTimeValid,
                                             *cachedSplineReferenceTime, NULL, inWorldSpace );
                    m_isEvaluatingNode = false;
                } else {
                    cachedSplineReferenceTime->clear();
                    *cachedSplineReferenceTimeValid = FOREVER;
                }
            }

            if( !cachedSplineOffsetTimeValid->InInterval( offsetTime ) || forRender ) {
                // TODO: This may not be great for the viewport since it is evaluating the splines at a different time
                // than 't'.
                m_isEvaluatingNode = true;
                cache_splines_from_node( pHairNode, pSourceNode, offsetTime, *cachedSplineOffsetTimeValid,
                                         *cachedSplineOffsetTime, NULL, inWorldSpace );
                m_isEvaluatingNode = false;
            }

            m_objectValidity &= Interval( cachedSplineOffsetTimeValid->Start() + m_timeStep,
                                          cachedSplineOffsetTimeValid->End() + m_timeStep );

            if( !cachedSplineValid->InInterval( t ) || forRender ) {
                objectBounds->Init();

                if( cachedSplineOffsetTimeValid->InInterval( t ) && !forRender ) {
                    // We can reuse the velocity splines if the object isn't changing over this interval.
                    *cachedSpline = *cachedSplineOffsetTime;
                    *cachedSplineValid = *cachedSplineOffsetTimeValid;
                } else {
                    m_isEvaluatingNode = true;
                    cache_splines_from_node( pHairNode, pSourceNode, t, *cachedSplineValid, *cachedSpline, objectBounds,
                                             inWorldSpace );
                    m_isEvaluatingNode = false;

                    if( cachedSpline->size() != cachedSplineOffsetTime->size() ) {
                        std::basic_stringstream<MCHAR> ss;
                        ss << _T("MaxKrakatoaHairObject::CacheSpline() - Different spline counts for node: \"")
                           << pSourceNode->GetName() << _T("\" at time: ") << t << _T(" and: ") << offsetTime
                           << std::endl;
                        throw std::runtime_error( frantic::strings::to_string( ss.str() ) );
                    }

                    if( cachedSplineReferenceTime->size() > 0 &&
                        cachedSpline->size() != cachedSplineReferenceTime->size() ) {
                        std::basic_stringstream<MCHAR> ss;
                        ss << _T("MaxKrakatoaHairObject::CacheSpline() - Different spline counts for node: \"")
                           << pSourceNode->GetName() << _T("\" at time: ") << t << _T(" and: ") << referenceTime
                           << std::endl;
                        throw std::runtime_error( frantic::strings::to_string( ss.str() ) );
                    }

                    // Try to fix up broken HairFarm splines. HairFarm can produce variable numbers of spline knots (
                    // usually only one different ), but  it can also easily produce bullshit NaN values for its splines
                    // too. I deal with this by discarding velocity information.
                    for( std::size_t i = 0, iEnd = cachedSpline->size(); i < iEnd; ++i ) {
                        std::size_t nowSize = cachedSpline->at( i ).size();
                        std::size_t thenSize = cachedSplineOffsetTime->at( i ).size();

                        if( nowSize != thenSize ) {
                            ( *cachedSplineOffsetTime )[i] = cachedSpline->at( i );

                            FF_LOG( warning )
                                << _T("MaxKrakatoaHairObject::CacheSpline() - HairFarm stupidness! Spline: ") << i
                                << _T(" for node: \"") << pSourceNode->GetName() << _T("\" at time: ") << t
                                << _T(" and: ") << offsetTime << _T(" had counts: ") << nowSize << _T(" vs. ")
                                << thenSize << _T(" respectively.") << std::endl;
                        }

                        if( cachedSplineReferenceTime->size() > 0 ) {
                            std::size_t refSize = cachedSplineReferenceTime->at( i ).size();
                            if( nowSize != refSize ) {
                                FF_LOG( warning )
                                    << _T("MaxKrakatoaHairObject::CacheSpline() - HairFarm stupidness! Spline: ") << i
                                    << _T(" for node: \"") << pSourceNode->GetName() << _T("\" at time: ") << t
                                    << _T(" and: ") << referenceTime << _T(" had counts: ") << nowSize << _T(" vs. ")
                                    << refSize << _T(" respectively.") << std::endl;

                                if( nowSize < refSize ) {
                                    cachedSplineReferenceTime->at( i ).resize( nowSize );
                                } else {
                                    // Just fill out the back with copies of the last vertex. This appears to be what
                                    // HairFarm is doing anyways.
                                    for( ; refSize < nowSize; ++refSize )
                                        cachedSplineReferenceTime->at( i ).push_back(
                                            cachedSplineReferenceTime->at( i ).back() );
                                }
                            }
                        }
                    }

                    // Mark the viewport cache as invalid.
                    // m_viewportValidTime = std::numeric_limits<TimeValue>::min();
                }
                m_objectValidity &= *cachedSplineValid;
            }

            if( forRender )
                m_objectValidity.SetInstant( t );

            FF_LOG( debug ) << _T("For node: \"") << pSourceNode->GetName() << _T("\" there were ")
                            << cachedSpline->size() << _T(" splines cached in ")
                            << ( m_inRenderMode ? _T("render") : _T("viewport") ) << _T(" mode.") << std::endl;

            if( cachedSpline->size() == 0 && m_inRenderMode ) {
                FF_LOG( warning ) << _T("The node: \"") << pSourceNode->GetName() << _T("\" produced NO splines!")
                                  << std::endl;
            }
        } break;
        default:
            throw std::runtime_error( "MaxKrakatoaHairObject::CacheSpline() Unknown source type: " +
                                      boost::lexical_cast<std::string>( m_pblock->GetInt( kSourceType ) ) );
        }
    } catch( ... ) {
        m_objectValidity = FOREVER;
        ClearSpline( cachedSpline, cachedSplineOffsetTime, cachedSplineReferenceTime, cachedSplineValid,
                     cachedSplineOffsetTimeValid, cachedSplineReferenceTimeValid, objectBounds );
        throw;
    }
}

#if MAX_VERSION_MAJOR >= 24
const TCHAR* MaxKrakatoaHairObject::GetObjectName( bool localized ) {
#elif MAX_VERSION_MAJOR >= 15
const TCHAR* MaxKrakatoaHairObject::GetObjectName() {
#else
TCHAR* MaxKrakatoaHairObject::GetObjectName() {
#endif
    return _T("PRTHair");
}

// We need to clear the cache when switching to and from render mode, because
// the render and viewport settings are potentially different.
int MaxKrakatoaHairObject::RenderBegin( TimeValue t, ULONG flags ) {
    // Need to clear the spline caches since the target object might have a different result in render mode.
    for( int i = 0; i < m_cachedSplinesValid.size(); ++i ) {
        // NOTE: assumes they have the same size (which they should)
        m_cachedSplinesValid[i].SetEmpty();
        m_cachedSplinesOffsetTimeValid[i].SetEmpty();
    }
    InvalidateReferenceFrame();

    m_cachedSplines.clear();
    m_cachedSplinesOffsetTime.clear();
    m_cachedSplinesReferenceTime.clear();

    psCacheSplines.reset();
    psEvalWorldState.reset();
    psCreateStream.reset();
    psSplineTotal.reset();
    psComputeLength.reset();
    psBezierSolve.reset();
    psRootSolve.reset();

    return super_type::RenderBegin( t, flags );
}

// We need to clear the cache when switching to and from render mode, because
// the render and viewport settings are potentially different.
int MaxKrakatoaHairObject::RenderEnd( TimeValue t ) {
    /*std::basic_stringstream<MCHAR> ss;
    ss << _T("Profiling results:\n");
    ss << psCacheSplines << _T("\n");
    ss << psEvalWorldState << _T("\n");
    ss << psCreateStream << _T("\n");
    ss << psSplineTotal << _T("\n");
    ss << psComputeLength << _T("\n");
    ss << psBezierSolve << _T("\n");
    ss << psRootSolve << _T("\n");*/

    // FF_LOG(stats) << ss.str() << std::endl;

    // mprintf( "%s\n", ss.str().c_str() );

    return super_type::RenderEnd( t );
}

RefResult MaxKrakatoaHairObject::NotifyRefChanged( const Interval& /*changeInt*/, RefTargetHandle hTarget,
                                                   PartID& partID, RefMessage message, BOOL /*propagate*/ ) {
    if( hTarget == m_pblock ) {
        ParamID id = m_pblock->LastNotifyParamID();

        if( id < 0 )
            return REF_DONTCARE;

        // By default we should propagate messages. Some messages can be safely ignored though, and
        // will improve viewport performance if we do so.
        if( message == REFMSG_CHANGE ) {
            switch( id ) {

            case kSourceNodes:
                if( ( partID & PART_GEOM ) && !m_isEvaluatingNode )
                    InvalidateObjectAndViewport();
                break;

            case kSourceType:
                InvalidateObjectAndViewport();
                break;
            case kViewportEnabled:
                InvalidateObjectAndViewport();
                break;

            case kInWorldSpace:
                InvalidateObjectAndViewport();
                break;

            case kReferenceTime:
                if( !m_pblock->GetInt( kReferenceEnabled ) )
                    return REF_STOP;
                InvalidateReferenceFrame();
                break;
            case kReferenceEnabled:
                InvalidateReferenceFrame();
                break;
            }
            InvalidateViewport();
        }
    }

    return REF_SUCCEED;
}

void MaxKrakatoaHairObject::InitNodeName( MSTR& s ) { s = _T( MaxKrakatoaHairObject_NAME ); }

void MaxKrakatoaHairObject::GetDeformBBox( TimeValue t, Box3& box, Matrix3* tm, BOOL useSel ) {
    try {
        Box3 newBox;
        int numSources = m_pblock->Count( kSourceNodes );
        for( int i = 0; i < numSources; ++i ) {
            INode* hairNode = GetCOREInterface()->GetINodeByName( _T( MaxKrakatoaHairObject_NAME ) );
            INode* sourceNode = m_pblock->GetINode( kSourceNodes, t );
            spline_container* cachedSpline = &m_cachedSplines[i];
            spline_container* cachedSplineOffsetTime = &m_cachedSplinesOffsetTime[i];
            spline_container* cachedSplineReferenceTime = &m_cachedSplinesReferenceTime[i];
            Interval* cachedSplineValid = &m_cachedSplinesValid[i];
            Interval* cachedSplineOffsetTimeValid = &m_cachedSplinesOffsetTimeValid[i];
            Interval* cachedSplineReferenceTimeValid = &m_cachedSplinesReferenceTimeValid[i];
            Box3* objectBounds = &m_objectBounds[i];

            CacheSpline( t, m_inRenderMode, hairNode, sourceNode, cachedSpline, cachedSplineOffsetTime,
                         cachedSplineReferenceTime, cachedSplineValid, cachedSplineOffsetTimeValid,
                         cachedSplineReferenceTimeValid, objectBounds );

            if( newBox.IsEmpty() ) {
                newBox = m_objectBounds[i];
            } else {
                newBox += m_objectBounds[i];
            }
        }
        box = newBox;

        if( tm )
            box = box * ( *tm );
    } catch( const std::exception& e ) {
        FF_LOG( error ) << e.what() << std::endl;
    }
}
