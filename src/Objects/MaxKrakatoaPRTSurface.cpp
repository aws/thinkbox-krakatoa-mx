// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0
#include "stdafx.h"

#include "resource.h"

#include "Objects/MaxKrakatoaPRTInterface.h"

#include <krakatoa/max3d/PRTObject.hpp>

#include <frantic/geometry/triangle_utils.hpp>
#include <frantic/particles/streams/empty_particle_istream.hpp>
#include <frantic/particles/streams/surface_particle_istream.hpp>
#include <frantic/shading/highlights.hpp>

#include <frantic/max3d/convert.hpp>
#include <frantic/max3d/maxscript/maxscript.hpp>

#include "Objects/MaxKrakatoaPRTObjectDisplay.hpp"
#include <boost/noncopyable.hpp>
#include <boost/random.hpp>

#define MaxKrakatoaPRTSurface_NAME "PRT Surface"
#define MaxKrakatoaPRTSurface_VERSION 1

#if MAX_VERSION_MAJOR < 15
#define p_end end
#endif

extern HINSTANCE hInstance;

using frantic::graphics::vector3f;

class max_mesh_surface : public boost::noncopyable {
    struct per_data {
        TriObject* m_pMeshObj;
        Mesh* m_pMesh;

        frantic::graphics::transform4f m_seedTM;    // This TM is applied to generated particles.
        frantic::graphics::transform4f m_invSeedTM; // The inverse of m_seedTM
    };

    std::vector<per_data> m_surfaceData;

    bool m_inWorldSpace;

    frantic::graphics::transform4f m_toRefTM; // If we have multiple sources, we use the first added one as the
                                              // reference TM and all other sources transform into this space.

    frantic::channels::channel_accessor<frantic::graphics::vector3f> m_posAccessor;
    frantic::channels::channel_cvt_accessor<frantic::graphics::vector3f> m_velocityAccessor;
    frantic::channels::channel_cvt_accessor<frantic::graphics::vector3f> m_normalAccessor;
    frantic::channels::channel_cvt_accessor<frantic::graphics::vector3f> m_tangentAccessor;

    typedef frantic::channels::channel_cvt_accessor<frantic::graphics::vector3f> map_accessor_type;

    std::vector<std::pair<int, map_accessor_type>> m_mapAccessors;

  private:
    max_mesh_surface( const max_mesh_surface& rhs );

    bool is_map_supported( int mapNum ) {
        for( std::vector<per_data>::iterator it = m_surfaceData.begin(), itEnd = m_surfaceData.end(); it != itEnd;
             ++it ) {
            if( it->m_pMesh->mapSupport( mapNum ) )
                return true;
        }
        return false;
    }

    bool has_tangent() {
        for( std::vector<per_data>::iterator it = m_surfaceData.begin(), itEnd = m_surfaceData.end(); it != itEnd;
             ++it ) {
            if( !it->m_pMesh->tvFace || !it->m_pMesh->tVerts )
                return false;
        }
        return true;
    }

  public:
    max_mesh_surface( bool inWorldSpace = false )
        : m_inWorldSpace( inWorldSpace ) {}

#if MAX_VERSION_MAJOR >= 15
    max_mesh_surface( max_mesh_surface&& rhs )
        : m_surfaceData( std::move( rhs.m_surfaceData ) )
        , m_mapAccessors( std::move( rhs.m_mapAccessors ) )
        , m_toRefTM( rhs.m_toRefTM ) {
        m_inWorldSpace = rhs.m_inWorldSpace;

        m_posAccessor = rhs.m_posAccessor;
        m_velocityAccessor = rhs.m_velocityAccessor;
        m_normalAccessor = rhs.m_normalAccessor;
        m_tangentAccessor = rhs.m_tangentAccessor;
    }
#endif

    ~max_mesh_surface() {
        for( std::vector<per_data>::iterator it = m_surfaceData.begin(), itEnd = m_surfaceData.end(); it != itEnd;
             ++it ) {
            if( it->m_pMeshObj )
                it->m_pMeshObj->MaybeAutoDelete();
            // else if( it->m_pMesh )
            //	it->m_pMesh->DeleteThis();
        }
    }

    void steal( max_mesh_surface& rhs ) {
        m_surfaceData.swap( rhs.m_surfaceData );
        m_mapAccessors.swap( rhs.m_mapAccessors );

        m_inWorldSpace = rhs.m_inWorldSpace;
        m_toRefTM = rhs.m_toRefTM;

        m_posAccessor = rhs.m_posAccessor;
        m_velocityAccessor = rhs.m_velocityAccessor;
        m_normalAccessor = rhs.m_normalAccessor;
        m_tangentAccessor = rhs.m_tangentAccessor;
    }

    void add_surface( TriObject* pTriObject, BOOL fOwnsObject, const Matrix3& toWorldTM ) {
        per_data newData;
        newData.m_pMeshObj = NULL;
        newData.m_pMesh = &pTriObject->GetMesh();

        if( fOwnsObject )
            newData.m_pMeshObj = pTriObject; // Record the TriObject if we own it, so we can delete it later.

        if( m_surfaceData.empty() && !m_inWorldSpace ) {
            m_toRefTM = frantic::max3d::from_max_t( toWorldTM ).to_inverse();
        } else {
            newData.m_seedTM = m_toRefTM * frantic::max3d::from_max_t( toWorldTM );
            newData.m_invSeedTM = newData.m_seedTM.to_inverse();
        }

        m_surfaceData.push_back( newData );
    }

    void get_native_map( frantic::channels::channel_map& outNativeMap ) {
        outNativeMap.define_channel<frantic::graphics::vector3f>( _T("Position") );
        outNativeMap.define_channel<frantic::graphics::vector3f>( _T("Velocity") );
        outNativeMap.define_channel<frantic::graphics::vector3f>( _T("Normal") );
        outNativeMap.define_channel<frantic::graphics::vector3f>( _T("Tangent") );

        if( this->is_map_supported( 0 ) )
            outNativeMap.define_channel<frantic::graphics::vector3f>( _T("Color") );
        if( this->is_map_supported( 1 ) )
            outNativeMap.define_channel<frantic::graphics::vector3f>( _T("TextureCoord") );

        for( int i = 2; i < MAX_MESHMAPS; ++i ) {
            if( this->is_map_supported( i ) )
                outNativeMap.define_channel<frantic::graphics::vector3f>( _T("Mapping") +
                                                                          boost::lexical_cast<frantic::tstring>( i ) );
        }
    }

    void set_channel_map( const frantic::channels::channel_map& outMap ) {
        m_velocityAccessor.reset();
        m_normalAccessor.reset();
        m_tangentAccessor.reset();
        m_mapAccessors.clear();

        m_posAccessor = outMap.get_accessor<frantic::graphics::vector3f>( _T("Position") );

        if( outMap.has_channel( _T("Velocity") ) )
            m_velocityAccessor = outMap.get_cvt_accessor<frantic::graphics::vector3f>( _T("Velocity") );

        if( outMap.has_channel( _T("Normal") ) )
            m_normalAccessor = outMap.get_cvt_accessor<frantic::graphics::vector3f>( _T("Normal") );

        if( outMap.has_channel( _T("Tangent") ) && this->has_tangent() )
            m_tangentAccessor = outMap.get_cvt_accessor<frantic::graphics::vector3f>( _T("Tangent") );

        if( outMap.has_channel( _T("Color") ) && this->is_map_supported( 0 ) )
            m_mapAccessors.push_back(
                std::make_pair( 0, outMap.get_cvt_accessor<frantic::graphics::vector3f>( _T("Color") ) ) );

        if( outMap.has_channel( _T("TextureCoord") ) && this->is_map_supported( 1 ) )
            m_mapAccessors.push_back(
                std::make_pair( 1, outMap.get_cvt_accessor<frantic::graphics::vector3f>( _T("TextureCoord") ) ) );

        for( int i = 2; i < MAX_MESHMAPS; ++i ) {
            if( !this->is_map_supported( i ) )
                continue;

            frantic::tstring channelName = _T("Mapping") + boost::lexical_cast<frantic::tstring>( i );
            if( outMap.has_channel( channelName ) )
                m_mapAccessors.push_back(
                    std::make_pair( i, outMap.get_cvt_accessor<frantic::graphics::vector3f>( channelName ) ) );
        }
    }

    std::size_t surface_count() const { return m_surfaceData.size(); }

    std::size_t element_count( std::size_t surfaceIndex ) const {
        return m_surfaceData[surfaceIndex].m_pMesh->getNumFaces();
    }

    float element_area( std::size_t surfaceIndex, std::size_t elementIndex ) {
        return 0.5f * Length( m_surfaceData[surfaceIndex].m_pMesh->FaceNormal( (DWORD)elementIndex, FALSE ) );
    }

    template <class RandomEngine>
    bool seed_particle( char* pOutParticle, std::size_t surfaceIndex, std::size_t elementIndex, RandomEngine& rndEng ) {
        float bc[3];

        frantic::geometry::random_barycentric_coordinate( bc, rndEng );

        per_data& surfaceData = m_surfaceData[surfaceIndex];

        Mesh& m = *surfaceData.m_pMesh;
        Face& f = m.faces[elementIndex];

        frantic::graphics::vector3f triVerts[] = { frantic::max3d::from_max_t( m.getVert( f.getVert( 0 ) ) ),
                                                   frantic::max3d::from_max_t( m.getVert( f.getVert( 1 ) ) ),
                                                   frantic::max3d::from_max_t( m.getVert( f.getVert( 2 ) ) ) };

        frantic::graphics::vector3f p = ( bc[0] * triVerts[0] + bc[1] * triVerts[1] + bc[2] * triVerts[2] );

        m_posAccessor.get( pOutParticle ) = surfaceData.m_seedTM * p;

        // TODO: We need another mesh sample to do finite differences velocity...
        // TODO: Node TM derivatives could provide a velocity too ...
        // if( m_velocityAccessor.is_valid() )
        //	m_velocityAccessor.set( pOutParticle, surfaceData.m_seedTM.transform_no_translation( ... ) );

        if( m_normalAccessor.is_valid() )
            m_normalAccessor.set( pOutParticle,
                                  surfaceData.m_invSeedTM.transpose_transform_no_translation(
                                      frantic::graphics::triangle_normal( triVerts[0], triVerts[1], triVerts[2] ) ) );

        if( m_tangentAccessor.is_valid() ) {
            TVFace& tvf = m.tvFace[elementIndex];

            UVVert tvs[] = { m.tVerts[tvf.getTVert( 0 )], m.tVerts[tvf.getTVert( 1 )], m.tVerts[tvf.getTVert( 2 )] };

            float uvs[][2] = { { tvs[0].x, tvs[0].y }, { tvs[1].x, tvs[1].y }, { tvs[2].x, tvs[2].y } };

            vector3f dPdu, dPdv;
            if( !frantic::geometry::compute_dPduv( triVerts, uvs, dPdu, dPdv ) ) {
                vector3f n = frantic::graphics::triangle_normal( triVerts[0], triVerts[1], triVerts[2] );

                m_tangentAccessor.set( pOutParticle, surfaceData.m_invSeedTM.transpose_transform_no_translation(
                                                         frantic::shading::compute_tangent( n ) ) );
            } else {
                m_tangentAccessor.set( pOutParticle, surfaceData.m_invSeedTM.transpose_transform_no_translation(
                                                         vector3f::normalize( dPdu ) ) );
            }
        }

        for( std::vector<std::pair<int, map_accessor_type>>::const_iterator it = m_mapAccessors.begin(),
                                                                            itEnd = m_mapAccessors.end();
             it != itEnd; ++it ) {
            if( !m.mapSupport( it->first ) ) // Not all surfaces are required to support each map we expose.
                continue;

            TVFace& tvf = m.mapFaces( it->first )[elementIndex];
            UVVert* tVerts = m.mapVerts( it->first );

            it->second.set( pOutParticle, bc[0] * frantic::max3d::from_max_t( tVerts[tvf.getTVert( 0 )] ) +
                                              bc[1] * frantic::max3d::from_max_t( tVerts[tvf.getTVert( 1 )] ) +
                                              bc[2] * frantic::max3d::from_max_t( tVerts[tvf.getTVert( 2 )] ) );
        }

        return true;
    }
};

namespace quantity_method {
enum option { count, area };
};

enum {
    kSourceNodes,
    kIgnoreSelection,
    kNumParticles,
    kAverageSpacing,
    kQuantityMethod,
    kViewPercentage,
    kRandomSeed,
    kIconSize,
    kInWorldSpace,
    kSelectedSource,
    kViewLimit,
    kUseViewLimit
};

class MaxKrakatoaPRTSurface : public krakatoa::max3d::MaxKrakatoaPRTObjectDisplay<MaxKrakatoaPRTSurface> {
  protected:
    virtual ClassDesc2* GetClassDesc();

    virtual Mesh* GetIconMesh( Matrix3& outTM );
#if MAX_VERSION_MAJOR >= 25
    virtual MaxSDK::SharedMeshPtr GetIconMeshShared( Matrix3& outTM );
#endif

    virtual bool InWorldSpace() const;

    virtual particle_istream_ptr
    GetInternalStream( INode* pNode, TimeValue t, Interval& inoutValidity,
                       frantic::max3d::particles::IMaxKrakatoaPRTEvalContextPtr pEvalContext );

  public:
    MaxKrakatoaPRTSurface( BOOL loading = FALSE );
    virtual ~MaxKrakatoaPRTSurface();

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

class MaxKrakatoaPRTSurfaceDesc : public ClassDesc2 {
    ParamBlockDesc2 m_paramDesc;

  public:
    MaxKrakatoaPRTSurfaceDesc();
    virtual ~MaxKrakatoaPRTSurfaceDesc();

    int IsPublic() { return TRUE; }
    void* Create( BOOL /*loading*/ ) { return new MaxKrakatoaPRTSurface; }
    const TCHAR* ClassName() { return _T( MaxKrakatoaPRTSurface_NAME ); }
#if MAX_VERSION_MAJOR >= 24
    const TCHAR* NonLocalizedClassName() { return _T( MaxKrakatoaPRTSurface_NAME ); }
#endif
    SClass_ID SuperClassID() { return GEOMOBJECT_CLASS_ID; }
    Class_ID ClassID() { return MaxKrakatoaPRTSurface_CLASSID; }
    const TCHAR* Category() { return _T("Krakatoa"); }

    const TCHAR* InternalName() {
        return _T( MaxKrakatoaPRTSurface_NAME );
    }                                           // returns fixed parsable name (scripter-visible name)
    HINSTANCE HInstance() { return hInstance; } // returns owning module handle
};

ClassDesc2* GetMaxKrakatoaPRTSurfaceDesc() {
    static MaxKrakatoaPRTSurfaceDesc theDesc;
    return &theDesc;
}

class PRTSurfacDlgProc : public ParamMap2UserDlgProc {
  public:
    PRTSurfacDlgProc();

    virtual ~PRTSurfacDlgProc();

    virtual INT_PTR DlgProc( TimeValue t, IParamMap2* map, HWND hWnd, UINT msg, WPARAM wParam, LPARAM lParam );

    virtual void DeleteThis();
};

PRTSurfacDlgProc::PRTSurfacDlgProc() {}

PRTSurfacDlgProc::~PRTSurfacDlgProc() {}

INT_PTR PRTSurfacDlgProc::DlgProc( TimeValue /*t*/, IParamMap2* /*map*/, HWND hWnd, UINT msg, WPARAM wParam,
                                   LPARAM lParam ) {
    switch( msg ) {
    case WM_INITDIALOG:
        break;
    case WM_COMMAND: {
        HWND rcvHandle = (HWND)lParam;
        WORD msg = HIWORD( wParam );
        if( rcvHandle == GetDlgItem( hWnd, IDC_PRTSURFACE_MODIFYSOURCE_BUTTON ) ) {
            if( msg == BN_CLICKED ) {
                frantic::max3d::mxs::expression(
                    _T("try( FranticParticleRenderMXS.OpenPRTSurfaceOptionsRCMenu() )catch()") )
                    .evaluate<void>();
                return TRUE;
            }
        }
    } break;
    case WM_CONTEXTMENU: {
        HWND rcvHandle = (HWND)wParam;
        if( rcvHandle == GetDlgItem( hWnd, IDC_PRTSURFACE_MODIFYSOURCE_BUTTON ) ) {
            frantic::max3d::mxs::expression(
                _T("try( FranticParticleRenderMXS.OpenPRTSurfaceOptionsRCMenu() )catch()") )
                .evaluate<void>();
            return TRUE;
        }
        break;
    }
    }
    return FALSE;
}

void PRTSurfacDlgProc::DeleteThis() {}

PRTSurfacDlgProc* GetPRTSurfacDlgProc() {
    static PRTSurfacDlgProc thePRTSurfacDlgProc;
    return &thePRTSurfacDlgProc;
}

class PRTSurfacePBValidator : public PBValidator {
  public:
    virtual BOOL Validate( PB2Value& v );
    virtual BOOL Validate( PB2Value& v, ReferenceMaker* owner, ParamID id, int tabIndex );
};

BOOL PRTSurfacePBValidator::Validate( PB2Value& /*v*/ ) {
    return FALSE; // Don't use this version, use the fancier one.
}

BOOL PRTSurfacePBValidator::Validate( PB2Value& v, ReferenceMaker* pOwner, ParamID id, int tabIndex ) {
    if( id != kSourceNodes || !v.r )
        return TRUE;

    INode* pNode = static_cast<INode*>( v.r );

    if( IParamBlock2* pb = pOwner->GetParamBlockByID( 0 ) ) {
        // Check if we already have this in the list, at a different position.
        for( int i = 0, iEnd = pb->Count( kSourceNodes ); i < iEnd; ++i ) {
            if( pb->GetINode( kSourceNodes, 0, i ) == pNode && i != tabIndex )
                return FALSE;
        }
    }

    ObjectState os = pNode->EvalWorldState(
        GetCOREInterface()
            ->GetTime() ); // We need a time and one isn't offered to Validate() so I pick the "current" time.

    if( !os.obj || os.obj == pOwner || !os.obj->CanConvertToType( triObjectClassID ) )
        return FALSE;

    return TRUE;
}

PRTSurfacePBValidator* GetPRTSurfacePBValidator() {
    static PRTSurfacePBValidator thePRTSurfacePBValidator;
    return &thePRTSurfacePBValidator;
}

class PRTSurfacePBAccessor : public PBAccessor {
  public:
    virtual void Get( PB2Value& v, ReferenceMaker* owner, ParamID id, int tabIndex, TimeValue t, Interval& valid );
    // virtual void Set(PB2Value &v, ReferenceMaker *owner, ParamID id, int tabIndex, TimeValue t);
    // virtual BOOL KeyFrameAtTime(ReferenceMaker *owner, ParamID id, int tabIndex, TimeValue t);
    // virtual MSTR GetLocalName(ReferenceMaker *owner, ParamID id, int tabIndex);
    // virtual void TabChanged(tab_changes changeCode, Tab< PB2Value > *tab, ReferenceMaker *owner, ParamID id, int
    // tabIndex, int count); virtual void DeleteThis();
};

void PRTSurfacePBAccessor::Get( PB2Value& v, ReferenceMaker* owner, ParamID id, int /*tabIndex*/, TimeValue t,
                                Interval& /*valid*/ ) {
    if( id != kSelectedSource || !owner )
        return;

    // Init the return value to NULL.
    v.r = NULL;

    IParamBlock2* pb = owner->GetParamBlockByID( 0 );
    if( !pb )
        return;

    IParamMap2* pm = pb->GetMap( 0 );
    if( pm != NULL ) { // I expect it to be NULL when not displayed.
        HWND hWndSources = GetDlgItem( pm->GetHWnd(), IDC_PRTSURFACE_SOURCES_LISTBOX );
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

PRTSurfacePBAccessor* GetPRTSurfacePBAccessor() {
    static PRTSurfacePBAccessor thePRTSurfacePBAccessor;
    return &thePRTSurfacePBAccessor;
}

MaxKrakatoaPRTSurfaceDesc::MaxKrakatoaPRTSurfaceDesc()
    : m_paramDesc( 0,                                                     // Block num
                   _T("Parameters"),                                      // Internal name
                   NULL,                                                  // Localized name
                   NULL,                                                  // ClassDesc2*
                   P_AUTO_CONSTRUCT + P_AUTO_UI + P_MULTIMAP + P_VERSION, // Flags
                   MaxKrakatoaPRTSurface_VERSION,
                   0,                                                    // PBlock Ref Num
                   1,                                                    // Num maps for P_MULTIMAP
                   0, IDD_PRTSURFACE, IDS_PRTSURFACE_ROLLOUT_NAME, 0, 0, // AutoUI stuff for panel 0
                   GetPRTSurfacDlgProc(), p_end ) {
    m_paramDesc.SetClassDesc( this );

    //------------------------------------------------------------------------------------------------------------------------------------------------------------------
    // Main rollout parameters
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------
    m_paramDesc.AddParam( kSourceNodes, _T("SourceNodes"), TYPE_INODE_TAB, 0, P_VARIABLE_SIZE,
                          IDS_PRTSURFACE_SOURCENODES, p_end );
    m_paramDesc.ParamOption( kSourceNodes, p_validator, GetPRTSurfacePBValidator() );
    m_paramDesc.ParamOption( kSourceNodes, p_ui, 0, TYPE_NODELISTBOX, IDC_PRTSURFACE_SOURCES_LISTBOX,
                             IDC_PRTSURFACE_ADDSOURCE_BUTTON, 0, IDC_PRTSURFACE_REMOVESOURCE_BUTTON, p_end );

    m_paramDesc.AddParam( kSelectedSource, _T("SelectedSource"), TYPE_INODE, P_TRANSIENT, 0, p_end );
    m_paramDesc.ParamOption( kSelectedSource, p_accessor, GetPRTSurfacePBAccessor() );

    // m_paramDesc.AddParam(kIgnoreSelection, _T("IgnoreSelection"), TYPE_BOOL, 0, 0, p_end);
    // m_paramDesc.ParamOption(kIgnoreSelection, p_default, FALSE);
    // m_paramDesc.ParamOption(kIgnoreSelection, p_ui, 0, TYPE_SPINNER, EDITTYPE_POS_INT, IDC_PRTSURFACE_VIEWCOUNT_EDIT,
    // IDC_PRTSURFACE_VIEWCOUNT_SPIN, SPIN_AUTOSCALE, p_end);

    m_paramDesc.AddParam( kNumParticles, _T("NumParticles"), TYPE_INT, P_ANIMATABLE, IDS_PRTSURFACE_NUMPARTICLES,
                          p_end );
    m_paramDesc.ParamOption( kNumParticles, p_default, 100000 );
    m_paramDesc.ParamOption( kNumParticles, p_range, 0, INT_MAX );
    m_paramDesc.ParamOption( kNumParticles, p_ui, 0, TYPE_SPINNER, EDITTYPE_POS_INT, IDC_PRTSURFACE_COUNT_EDIT,
                             IDC_PRTSURFACE_COUNT_SPIN, SPIN_AUTOSCALE, p_end );

    m_paramDesc.AddParam( kAverageSpacing, _T("AverageSpacing"), TYPE_WORLD, P_ANIMATABLE,
                          IDS_PRTSURFACE_AVERAGESPACING, p_end );
    m_paramDesc.ParamOption( kAverageSpacing, p_default, 1.f );
    m_paramDesc.ParamOption( kAverageSpacing, p_range, 0, FLT_MAX );
    m_paramDesc.ParamOption( kAverageSpacing, p_ui, 0, TYPE_SPINNER, EDITTYPE_POS_FLOAT, IDC_PRTSURFACE_SPACING_EDIT,
                             IDC_PRTSURFACE_SPACING_SPIN, SPIN_AUTOSCALE, p_end );

    m_paramDesc.AddParam( kQuantityMethod, _T("QuantityMethod"), TYPE_INT, 0, IDS_PRTSURFACE_QUANTITYMETHOD, p_end );
    m_paramDesc.ParamOption( kQuantityMethod, p_default, quantity_method::count );
    m_paramDesc.ParamOption( kQuantityMethod, p_ui, 0, TYPE_RADIO, 2, IDC_PRTSURFACE_SEEDING_COUNT_RADIO,
                             IDC_PRTSURFACE_SEEDING_SPACING_RADIO, p_end );

    m_paramDesc.AddParam( kViewPercentage, _T("ViewportPercentage"), TYPE_PCNT_FRAC, P_ANIMATABLE,
                          IDS_PRTSURFACE_VIEWPORTPERCENTAGE, p_end );
    m_paramDesc.ParamOption( kViewPercentage, p_default, 100.f );
    m_paramDesc.ParamOption( kViewPercentage, p_range, 0.f, 100.f );
    m_paramDesc.ParamOption( kViewPercentage, p_ui, 0, TYPE_SPINNER, EDITTYPE_POS_FLOAT,
                             IDC_PRTSURFACE_VIEWPERCENTAGE_EDIT, IDC_PRTSURFACE_VIEWPERCENTAGE_SPIN, SPIN_AUTOSCALE,
                             p_end );

    m_paramDesc.AddParam( kViewLimit, _T("ViewLimit"), TYPE_FLOAT, P_ANIMATABLE, IDS_PRTSURFACE_VIEWPORTLIMIT, p_end );
    m_paramDesc.ParamOption( kViewLimit, p_default, 100.f );
    m_paramDesc.ParamOption( kViewLimit, p_range, 0.f, FLT_MAX );
    m_paramDesc.ParamOption( kViewLimit, p_ui, 0, TYPE_SPINNER, EDITTYPE_POS_FLOAT, IDC_PRTSURFACE_VIEWLIMIT_EDIT,
                             IDC_PRTSURFACE_VIEWLIMIT_SPIN, SPIN_AUTOSCALE, p_end );

    m_paramDesc.AddParam( kUseViewLimit, _T("UseViewLimit"), TYPE_BOOL, 0, 0, p_end );
    m_paramDesc.ParamOption( kUseViewLimit, p_default, FALSE );
    m_paramDesc.ParamOption( kUseViewLimit, p_ui, 0, TYPE_SINGLECHEKBOX, IDC_PRTSURFACE_VIEWLIMIT_CHECK, p_end );

    m_paramDesc.AddParam( kRandomSeed, _T("RandomSeed"), TYPE_INT, P_RESET_DEFAULT | P_ANIMATABLE,
                          IDS_PRTSURFACE_RANDOMSEED, p_end );
    m_paramDesc.ParamOption( kRandomSeed, p_default, 1234 );
    m_paramDesc.ParamOption( kRandomSeed, p_range, 0, INT_MAX );
    m_paramDesc.ParamOption( kRandomSeed, p_ui, 0, TYPE_SPINNER, EDITTYPE_POS_INT, IDC_PRTSURFACE_RANDOMSEED_EDIT,
                             IDC_PRTSURFACE_RANDOMSEED_SPIN, SPIN_AUTOSCALE, p_end );

    m_paramDesc.AddParam( kIconSize, _T("IconSize"), TYPE_FLOAT, P_RESET_DEFAULT, 0, p_end );
    m_paramDesc.ParamOption( kIconSize, p_default, 30.f );
    m_paramDesc.ParamOption( kIconSize, p_range, 0.f, FLT_MAX );
    m_paramDesc.ParamOption( kIconSize, p_ui, 0, TYPE_SPINNER, EDITTYPE_POS_FLOAT, IDC_PRTSURFACE_ICONSIZE_EDIT,
                             IDC_PRTSURFACE_ICONSIZE_SPIN, SPIN_AUTOSCALE, p_end );

    m_paramDesc.AddParam( kInWorldSpace, _T("InWorldSpace"), TYPE_BOOL, 0, 0, p_end );
    m_paramDesc.ParamOption( kInWorldSpace, p_default, FALSE );
    m_paramDesc.ParamOption( kInWorldSpace, p_ui, 0, TYPE_SINGLECHEKBOX, IDC_PRTSURFACE_INWORLDSPACE_CHECK, p_end );
}

MaxKrakatoaPRTSurfaceDesc::~MaxKrakatoaPRTSurfaceDesc() {}

ClassDesc2* MaxKrakatoaPRTSurface::GetClassDesc() { return GetMaxKrakatoaPRTSurfaceDesc(); }

extern Mesh* GetPRTSurfaceIconMesh();
#if MAX_VERSION_MAJOR >= 25
extern MaxSDK::SharedMeshPtr GetPRTSurfaceIconMeshShared();
#endif

Mesh* MaxKrakatoaPRTSurface::GetIconMesh( Matrix3& outTM ) {
    float size = m_pblock->GetFloat( kIconSize );

    outTM.SetScale( Point3( size, size, size ) );

    return GetPRTSurfaceIconMesh();
}

#if MAX_VERSION_MAJOR >= 25
MaxSDK::SharedMeshPtr MaxKrakatoaPRTSurface::GetIconMeshShared( Matrix3& outTM ) {
    float size = m_pblock->GetFloat( kIconSize );

    outTM.SetScale( Point3( size, size, size ) );

    return GetPRTSurfaceIconMeshShared();
}
#endif

bool MaxKrakatoaPRTSurface::InWorldSpace() const {
    return ( m_pblock->Count( kSourceNodes ) > 1 ) || ( m_pblock->GetInt( kInWorldSpace ) != FALSE );
}

particle_istream_ptr
MaxKrakatoaPRTSurface::GetInternalStream( INode* /*pNode*/, TimeValue t, Interval& inoutValidity,
                                          frantic::max3d::particles::IMaxKrakatoaPRTEvalContextPtr pEvalContext ) {
    m_viewportValidity.SetInstant( t ); // Mark this object's validity. This is weird and should be different.
    m_objectValidity.SetInstant( t );   // Mark this object's validity. This is weird and should be different.

    inoutValidity.SetInstant( t );

    int numSources = m_pblock->Count( kSourceNodes );
    int numValidSources = 0;

    bool inWorldSpace = ( numSources > 1 ) || ( m_pblock->GetInt( kInWorldSpace ) != FALSE );

    max_mesh_surface meshImpl( inWorldSpace );

    for( int i = 0; i < numSources; ++i ) {
        INode* pSourceNode = m_pblock->GetINode( kSourceNodes, t, i );

        ObjectState os;
        Matrix3 toWorldTM;

        if( pSourceNode != NULL ) {
            os = pSourceNode->EvalWorldState( t );
            toWorldTM = pSourceNode->GetObjectTM( t );
        }

        if( !os.obj || !os.obj->CanConvertToType( triObjectClassID ) )
            continue;

        TriObject* pTriObj = static_cast<TriObject*>( os.obj->ConvertToType( t, triObjectClassID ) );

        assert( pTriObj != NULL );

        if( pTriObj->GetMesh().getNumFaces() > 0 ) {
            meshImpl.add_surface( pTriObj, ( pTriObj != os.obj ), toWorldTM );

            ++numValidSources;
        }
    }

    if( numValidSources == 0 )
        return particle_istream_ptr(
            new frantic::particles::streams::empty_particle_istream( pEvalContext->GetDefaultChannels() ) );

    boost::shared_ptr<frantic::particles::streams::surface_particle_istream<max_mesh_surface>> result(
        new frantic::particles::streams::surface_particle_istream<max_mesh_surface>(
#if MAX_VERSION_MAJOR >= 15
            std::move( meshImpl )
#else
            meshImpl, frantic::particles::streams::steal()
#endif
                ) );

    result->set_channel_map( pEvalContext->GetDefaultChannels() );

    int quantityMethod = m_pblock->GetInt( kQuantityMethod, t );

    float viewFraction = 1.f;

    boost::int64_t viewLimit = std::numeric_limits<boost::int64_t>::max();

    if( !m_inRenderMode ) {
        viewFraction = std::max( 0.f, std::min( 1.f, m_pblock->GetFloat( kViewPercentage, t ) ) );

        bool useViewLimit = m_pblock->GetInt( kUseViewLimit, t ) != FALSE;

        if( useViewLimit ) {
            float rawLimit = m_pblock->GetFloat( kViewLimit, t );

            viewLimit = static_cast<boost::int64_t>( std::ceil( 1000.0 * rawLimit ) );

            if( viewLimit < 0 )
                viewLimit = 0;
        }
    }

    if( quantityMethod == quantity_method::count ) {
        boost::int64_t count = m_pblock->GetInt( kNumParticles, t );
        if( !m_inRenderMode )
            count = std::min( static_cast<boost::int64_t>( std::ceil( static_cast<double>( count ) * viewFraction ) ),
                              viewLimit );

        result->set_particle_count( count );
    } else if( quantityMethod == quantity_method::area ) {
        float averageSpacing = m_pblock->GetFloat( kAverageSpacing, t );
        if( !m_inRenderMode )
            averageSpacing /= std::sqrt( viewFraction );

        result->set_particle_spacing( averageSpacing );

        if( !m_inRenderMode && result->particle_count() > viewLimit )
            result->set_particle_count( viewLimit );
    }

    int seed = m_pblock->GetInt( kRandomSeed, t );

    result->set_random_seed( static_cast<boost::uint32_t>( seed ) );

    return result;
}

MaxKrakatoaPRTSurface::MaxKrakatoaPRTSurface( BOOL loading ) {
    if( !loading )
        GetMaxKrakatoaPRTSurfaceDesc()->MakeAutoParamBlocks( this );
}

MaxKrakatoaPRTSurface::~MaxKrakatoaPRTSurface() {}

void MaxKrakatoaPRTSurface::SetIconSize( float size ) { m_pblock->SetValue( kIconSize, 0, size ); }

// From ReferenceMaker
RefResult MaxKrakatoaPRTSurface::NotifyRefChanged( const Interval& /*changeInt*/, RefTargetHandle hTarget,
                                                   PartID& /*partID*/, RefMessage message, BOOL /*propagate*/ ) {
    if( hTarget == m_pblock ) {
        int index = 0;
        ParamID id = m_pblock->LastNotifyParamID( index );

        if( message == REFMSG_CHANGE ) {
            switch( id ) {
            case kSourceNodes:
                // TODO: When we add a cache, invalidate it here.
                break;
            case kIgnoreSelection:
                return REF_STOP;
            case kNumParticles:
                if( m_pblock->GetInt( kQuantityMethod ) != quantity_method::count )
                    return REF_STOP;
                break;
            case kAverageSpacing:
                if( m_pblock->GetInt( kQuantityMethod ) != quantity_method::area )
                    return REF_STOP;
                break;
            case kViewPercentage:
                if( m_inRenderMode )
                    return REF_STOP;
                break;
            case kRandomSeed:
                break;
            case kIconSize:
                NotifyDependents( FOREVER, PART_DISPLAY, REFMSG_CHANGE );
                return REF_STOP;
            default:
                break;
            }

            NotifyDependents( FOREVER, PART_GEOM, REFMSG_CHANGE );
            return REF_STOP;
        }
    }

    return REF_SUCCEED;
}

// From BaseObject
#if MAX_VERSION_MAJOR >= 24
const TCHAR* MaxKrakatoaPRTSurface::GetObjectName( bool localized ) {
#elif MAX_VERSION_MAJOR >= 15
const TCHAR* MaxKrakatoaPRTSurface::GetObjectName() {
#else
TCHAR* MaxKrakatoaPRTSurface::GetObjectName() {
#endif
    return _T( MaxKrakatoaPRTSurface_NAME );
}

// From Object
void MaxKrakatoaPRTSurface::InitNodeName( MSTR& s ) { s = _T( MaxKrakatoaPRTSurface_NAME ); }
