// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0
#include "stdafx.h"

#include "MaxKrakatoaMaterial.hpp"
#include "MaxKrakatoa.h"
#include "MaxKrakatoaSceneContext.h"
#include "resource.h"

#include <frantic/channels/channel_map_adaptor.hpp>
#include <frantic/graphics/color3f.hpp>
#include <frantic/max3d/shaders/map_query.hpp>
#include <frantic/particles/streams/density_scale_particle_istream.hpp>
#include <frantic/particles/streams/functor_particle_istream.hpp>
#include <frantic/particles/streams/set_channel_particle_istream.hpp>

#include <boost/math/special_functions/fpclassify.hpp>

#include <imtl.h>

extern HINSTANCE hInstance;

class MaxKrakatoaMaterialDesc : public ClassDesc2 {
  public:
    int IsPublic() { return TRUE; }
    void* Create( BOOL /*loading*/ ) { return new MaxKrakatoaMaterial; }
    const TCHAR* ClassName() { return _T( MaxKrakatoaMaterial_CLASS_NAME ); }
#if MAX_VERSION_MAJOR >= 24
    const TCHAR* NonLocalizedClassName() { return _T( MaxKrakatoaMaterial_CLASS_NAME ); }
#endif
    SClass_ID SuperClassID() { return MATERIAL_CLASS_ID; }
    Class_ID ClassID() { return MaxKrakatoaMaterial_CLASS_ID; }
    const TCHAR* Category() { return _T(""); }
    const TCHAR* InternalName() { return _T( MaxKrakatoaMaterial_CLASS_NAME ); }
    HINSTANCE HInstance() { return hInstance; } // returns owning module handle
};

ClassDesc2* GetMaxKrakatoaMaterialDesc() {
    static MaxKrakatoaMaterialDesc theDesc;
    return &theDesc;
}

enum {
    kMainRollout // Rollout / IParamMap2 ID
};

enum {
    kScatteringColor,
    kScatteringTexmap,
    kScatteringBlend,
    kScatteringEnabled,

    kAbsorptionColor,
    kAbsorptionTexmap,
    kAbsorptionBlend,
    kAbsorptionEnabled,

    kEmissionColor,
    kEmissionTexmap,
    kEmissionBlend,
    kEmissionEnabled,

    kDensityScale,
    kDensityTexmap,
    kDensityEnabled,

    kReflectionEnabled,
    kReflectAtmosphere,
    kEmissionIsProportionalToDensity,
    kReflectionStrength,
    kReflectBackfacing,
    kReflectEnvironment
};

// enum {
//	WM_TEXMAP_CHANGED = WM_USER + 500 //msg sent when a texmap is changed. WPARAM is the param id.
// };

class MaxKrakatoaMaterialDialogProc : public ParamMap2UserDlgProc {
  public:
    virtual INT_PTR DlgProc( TimeValue t, IParamMap2* map, HWND hWnd, UINT msg, WPARAM wParam, LPARAM lParam );
    virtual void DeleteThis();
};

INT_PTR MaxKrakatoaMaterialDialogProc::DlgProc( TimeValue /*t*/, IParamMap2* /*map*/, HWND /*hWnd*/, UINT /*msg*/,
                                                WPARAM /*wParam*/, LPARAM /*lParam*/ ) {
    return FALSE;
}

void MaxKrakatoaMaterialDialogProc::DeleteThis() {
    // I am making this a singleton, so don't pass it to delete (its not dynamic memory)
    // delete this;
}

static ParamMap2UserDlgProc* GetMaxKrakatoaMaterialDialogProc() {
    static MaxKrakatoaMaterialDialogProc theProc;
    return &theProc;
}

// clang-format off
static ParamBlockDesc2 MaxKrakatoaMaterialPBDesc(
	0,						                   //BlockID
	_T("Parameters"),		                   //
	0,						                   //ResourceID
	GetMaxKrakatoaMaterialDesc(),
	P_AUTO_CONSTRUCT + P_AUTO_UI + P_MULTIMAP, //Flags
	0,						                   //Block's GetReference() index
	1,
	kMainRollout, IDD_MATERIAL_PARAMETERS, IDS_MATERIAL_NAME, 0, 0, GetMaxKrakatoaMaterialDialogProc(),

	kScatteringColor, _T("ScatteringColor"), TYPE_RGBA, P_ANIMATABLE, 0,
		p_default, Color(1,1,1),
		p_ui, kMainRollout, TYPE_COLORSWATCH, IDC_MATERIAL_SCATTERINGCOLOR,
		p_end,
	kScatteringTexmap, _T("ScatteringMap"), TYPE_TEXMAP, 0, 0,
		p_subtexno, 0,
		p_ui, kMainRollout, TYPE_TEXMAPBUTTON, IDC_MATERIAL_SCATTERINGMAP,
		p_end,
	kScatteringBlend, _T("ScatteringBlend"), TYPE_FLOAT, 0, 0,
		p_default, 100.f,
		p_range, 0.f, 100.f,
		p_ui, kMainRollout, TYPE_SPINNER, EDITTYPE_INT, IDC_MATERIAL_SCATTERINGEDIT, IDC_MATERIAL_SCATTERINGSPIN, SPIN_AUTOSCALE,
		p_end,
	kScatteringEnabled, _T("ScatteringEnabled"), TYPE_BOOL, 0, 0,
		p_default, TRUE,
		p_ui, kMainRollout, TYPE_SINGLECHEKBOX, IDC_MATERIAL_SCATTERINGENABLED,
		p_end,
	kAbsorptionColor, _T("AbsorptionColor"), TYPE_RGBA, P_ANIMATABLE, 0,
		p_default, Color(0,0,0),
		p_ui, kMainRollout, TYPE_COLORSWATCH, IDC_MATERIAL_ABSORPTIONCOLOR,
		p_end,
	kAbsorptionTexmap, _T("AbsorptionMap"), TYPE_TEXMAP, 0, 0,
		p_subtexno, 1,
		p_ui, kMainRollout, TYPE_TEXMAPBUTTON, IDC_MATERIAL_ABSORPTIONMAP,
		p_end,
	kAbsorptionBlend, _T("AbsorptionBlend"), TYPE_FLOAT, 0, 0,
		p_default, 100.f,
		p_range, 0.f, 100.f,
		p_ui, kMainRollout, TYPE_SPINNER, EDITTYPE_INT, IDC_MATERIAL_ABSORPTIONEDIT, IDC_MATERIAL_ABSORPTIONSPIN, SPIN_AUTOSCALE,
		p_end,
	kAbsorptionEnabled, _T("AbsorptionEnabled"), TYPE_BOOL, 0, 0,
		p_default, FALSE,
		p_ui, kMainRollout, TYPE_SINGLECHEKBOX, IDC_MATERIAL_ABSORPTIONENABLED,
		p_end,
	kEmissionColor, _T("EmissionColor"), TYPE_RGBA, P_ANIMATABLE, 0,
		p_default, Color(0,0,0),
		p_ui, kMainRollout, TYPE_COLORSWATCH, IDC_MATERIAL_EMISSIONCOLOR,
		p_end,
	kEmissionTexmap, _T("EmissionMap"), TYPE_TEXMAP, 0, 0,
		p_subtexno, 2,
		p_ui, kMainRollout, TYPE_TEXMAPBUTTON, IDC_MATERIAL_EMISSIONMAP,
		p_end,
	kEmissionBlend, _T("EmissionBlend"), TYPE_FLOAT, 0, 0,
		p_default, 100.f,
		p_range, 0.f, 100.f,
		p_ui, kMainRollout, TYPE_SPINNER, EDITTYPE_INT, IDC_MATERIAL_EMISSIONEDIT, IDC_MATERIAL_EMISSIONSPIN, SPIN_AUTOSCALE,
		p_end,
	kEmissionEnabled, _T("EmissionEnabled"), TYPE_BOOL, 0, 0,
		p_default, FALSE,
		p_ui, kMainRollout, TYPE_SINGLECHEKBOX, IDC_MATERIAL_EMISSIONENABLED,
		p_end,
	kDensityScale, _T("DensityScale"), TYPE_FLOAT, P_ANIMATABLE, 0,
		p_default, 1.f,
		p_range, 1e-3f, FLT_MAX,
		p_ui, kMainRollout, TYPE_SPINNER, EDITTYPE_FLOAT, IDC_MATERIAL_DENSITYEDIT, IDC_MATERIAL_DENSITYSPIN, SPIN_AUTOSCALE,
		p_end,
	kDensityTexmap, _T("DensityMap"), TYPE_TEXMAP, 0, 0,
		p_subtexno, 3,
		p_ui, kMainRollout, TYPE_TEXMAPBUTTON, IDC_MATERIAL_DENSITYMAP,
		p_end,
	kDensityEnabled, _T("DensityEnabled"), TYPE_BOOL, 0, 0,
		p_default, FALSE,
		p_ui, kMainRollout, TYPE_SINGLECHEKBOX, IDC_MATERIAL_DENSITYENABLED,
		p_end,
	kReflectionEnabled, _T("ReflectionEnabled"), TYPE_BOOL, 0, 0,
		p_default, FALSE,
		p_ui, kMainRollout, TYPE_SINGLECHEKBOX, IDC_MATERIAL_REFLECTIONENABLED,
		p_end,
	kReflectAtmosphere, _T("ReflectAtmosphere"), TYPE_BOOL, 0, 0,
		p_default, TRUE,
		p_ui, kMainRollout, TYPE_SINGLECHEKBOX, IDC_MATERIAL_REFLECTATMOSPHERE,
		p_end,
	kEmissionIsProportionalToDensity, _T("EmissionIsProportionalToDensity"), TYPE_BOOL, 0, 0,
		p_default, TRUE,
		p_ui, kMainRollout, TYPE_SINGLECHEKBOX, IDC_MATERIAL_EMISSIONPROPORTIONAL,
		p_end,
	kReflectionStrength, _T("ReflectionStrength"), TYPE_FLOAT, 0, 0,
		p_default, 1.f,
		p_range, 0.f, FLT_MAX,
		p_ui, kMainRollout, TYPE_SPINNER, EDITTYPE_FLOAT, IDC_MATERIAL_REFLECTIONEDIT, IDC_MATERIAL_REFLECTIONSPIN, SPIN_AUTOSCALE,
		p_end,
	kReflectBackfacing, _T("ReflectBackfacing"), TYPE_BOOL, 0, 0,
		p_default, FALSE,
		p_ui, kMainRollout, TYPE_SINGLECHEKBOX, IDC_MATERIAL_REFLECTBACKFACING,
		p_end,
	kReflectEnvironment, _T("ReflectEnvironment"), TYPE_BOOL, 0, 0,
		p_default, TRUE,
		p_ui, kMainRollout, TYPE_SINGLECHEKBOX, IDC_MATERIAL_REFLECTENVIRONMENT,
		p_end,
	p_end
);
// clang-format on

MaxKrakatoaMaterial::MaxKrakatoaMaterial()
    : m_pblock( NULL ) {
    GetMaxKrakatoaMaterialDesc()->MakeAutoParamBlocks( this );
}

Color MaxKrakatoaMaterial::GetAmbient( int /*mtlNum*/, BOOL /*backFac*/ ) { return Color( 0, 0, 0 ); }
Color MaxKrakatoaMaterial::GetDiffuse( int /*mtlNum*/, BOOL /*backFac*/ ) { return Color( 0, 0, 0 ); }
Color MaxKrakatoaMaterial::GetSpecular( int /*mtlNum*/, BOOL /*backFac*/ ) { return Color( 0, 0, 0 ); }
float MaxKrakatoaMaterial::GetShininess( int /*mtlNum*/, BOOL /*backFac*/ ) { return 0.f; }
float MaxKrakatoaMaterial::GetShinStr( int /*mtlNum*/, BOOL /*backFac*/ ) { return 0.f; }
float MaxKrakatoaMaterial::GetXParency( int /*mtlNum*/, BOOL /*backFac*/ ) { return 0.f; }

void MaxKrakatoaMaterial::SetAmbient( Color /*c*/, TimeValue /*t*/ ) {}
void MaxKrakatoaMaterial::SetDiffuse( Color /*c*/, TimeValue /*t*/ ) {}
void MaxKrakatoaMaterial::SetSpecular( Color /*c*/, TimeValue /*t*/ ) {}
void MaxKrakatoaMaterial::SetShininess( float /*v*/, TimeValue /*t*/ ) {}

void MaxKrakatoaMaterial::Shade( ShadeContext& sc ) { sc.out.c = Color( 1.0f, 0.0f, 0.0f ); }

void MaxKrakatoaMaterial::Update( TimeValue t, Interval& valid ) { valid.SetInstant( t ); }

void MaxKrakatoaMaterial::Reset() { m_pblock->ResetAll(); }

Interval MaxKrakatoaMaterial::Validity( TimeValue t ) { return Interval( t, t ); }
ParamDlg* MaxKrakatoaMaterial::CreateParamDlg( HWND hwMtlEdit, IMtlParams* imp ) {
    return GetMaxKrakatoaMaterialDesc()->CreateParamDlgs( hwMtlEdit, imp, this );
}

int MaxKrakatoaMaterial::NumSubTexmaps() {
    // mprintf("MaxKrakatoaMaterial::NumSubTexmaps()\n");
    return 4;
}

Texmap* MaxKrakatoaMaterial::GetSubTexmap( int i ) {
    // mprintf("MaxKrakatoaMaterial::GetSubTexmap(%d)\n", i);
    switch( i ) {
    case 0:
        return m_pblock->GetTexmap( kScatteringTexmap );
    case 1:
        return m_pblock->GetTexmap( kAbsorptionTexmap );
    case 2:
        return m_pblock->GetTexmap( kEmissionTexmap );
    case 3:
        return m_pblock->GetTexmap( kDensityTexmap );
    default:
        return NULL;
    };
}

int MaxKrakatoaMaterial::MapSlotType( int /*i*/ ) { return MAPSLOT_TEXTURE; }

void MaxKrakatoaMaterial::SetSubTexmap( int i, Texmap* m ) {
    switch( i ) {
    case 0:
        m_pblock->SetValue( kScatteringTexmap, 0, m );
        break;
    case 1:
        m_pblock->SetValue( kAbsorptionTexmap, 0, m );
        break;
    case 2:
        m_pblock->SetValue( kEmissionTexmap, 0, m );
        break;
    case 3:
        m_pblock->SetValue( kDensityTexmap, 0, m );
        break;
    };
}

int MaxKrakatoaMaterial::SubTexmapOn( int i ) {
    switch( i ) {
    case 0:
        return m_pblock->GetTexmap( kScatteringTexmap ) != NULL;
    case 1:
        return m_pblock->GetTexmap( kAbsorptionTexmap ) != NULL;
    case 2:
        return m_pblock->GetTexmap( kEmissionTexmap ) != NULL;
    case 3:
        return m_pblock->GetTexmap( kDensityTexmap ) != NULL;
    default:
        return FALSE;
    };
}

#if MAX_VERSION_MAJOR < 24
MSTR MaxKrakatoaMaterial::GetSubTexmapSlotName( int i ) {
#else
MSTR MaxKrakatoaMaterial::GetSubTexmapSlotName( int i, bool localized ) {
#endif
    switch( i ) {
    case 0:
        return _T("Scattering");
    case 1:
        return _T("Absorption");
    case 2:
        return _T("Emission");
    case 3:
        return _T("DensityScale");
    default:
        return _T("");
    };
}

MSTR MaxKrakatoaMaterial::GetSubTexmapTVName( int /*i*/ ) { return _T(""); }

BOOL MaxKrakatoaMaterial::SetDlgThing( ParamDlg* /*dlg*/ ) { return FALSE; }

RefTargetHandle MaxKrakatoaMaterial::Clone( RemapDir& remap ) {
    MaxKrakatoaMaterial* pNewMtl = new MaxKrakatoaMaterial;
    pNewMtl->ReplaceReference( 0, m_pblock->Clone( remap ) );

    BaseClone( this, pNewMtl, remap );
    return pNewMtl;
}

int MaxKrakatoaMaterial::NumSubs() { return 1; }

Animatable* MaxKrakatoaMaterial::SubAnim( int i ) {
    switch( i ) {
    case 0:
        return m_pblock;
    default:
        return NULL;
    }
}

#if MAX_VERSION_MAJOR < 24
TSTR MaxKrakatoaMaterial::SubAnimName( int i ) {
#else
TSTR MaxKrakatoaMaterial::SubAnimName( int i, bool localized ) {
#endif
    switch( i ) {
    case 0:
        return _T("Parameters");
    default:
        return _T("");
    }
}

int MaxKrakatoaMaterial::NumParamBlocks() { return 1; }

IParamBlock2* MaxKrakatoaMaterial::GetParamBlock( int i ) {
    switch( i ) {
    case 0:
        return m_pblock;
    default:
        return NULL;
    }
}

IParamBlock2* MaxKrakatoaMaterial::GetParamBlockByID( BlockID id ) {
    return ( m_pblock->ID() == id ) ? m_pblock : NULL;
}

int MaxKrakatoaMaterial::NumRefs() { return 1; }

RefTargetHandle MaxKrakatoaMaterial::GetReference( int i ) {
    switch( i ) {
    case 0:
        return m_pblock;
    default:
        return NULL;
    }
}

void MaxKrakatoaMaterial::SetReference( int i, RefTargetHandle rtarg ) {
    switch( i ) {
    case 0:
        m_pblock = (IParamBlock2*)rtarg;
        break;
    }
}

RefResult MaxKrakatoaMaterial::NotifyRefChanged( const Interval& /*changeInt*/, RefTargetHandle hTarget,
                                                 PartID& /*partID*/, RefMessage message, BOOL /*propagate*/ ) {
    if( hTarget == m_pblock ) {
        if( message == REFMSG_CHANGE ) {
            IParamMap2* pMap = m_pblock->GetMap();
            ParamID id = m_pblock->LastNotifyParamID();

            switch( id ) {
            case kScatteringTexmap:
            case kAbsorptionTexmap:
            case kEmissionTexmap:
            case kDensityTexmap:
                if( pMap ) {
                    pMap->Invalidate( id );
                    // SendMessage( pMap->GetHWnd(), WM_TEXMAP_CHANGED, (WPARAM)id, 0 );
                }
                break;
            };
        }
    }

    return REF_SUCCEED;
}

void MaxKrakatoaMaterial::DeleteThis() { delete this; }

#if MAX_VERSION_MAJOR < 24
void MaxKrakatoaMaterial::GetClassName( MSTR& s ) {
#else
void MaxKrakatoaMaterial::GetClassName( MSTR& s, bool localized ) {
#endif
    s = _T("Krakatoa Mtl");
}

BaseInterface* MaxKrakatoaMaterial::GetInterface( Interface_ID id ) {
    if( id == PRTMaterial_INTERFACE )
        return static_cast<IPRTMaterial*>( this );
    if( BaseInterface* bi = IPRTMaterial::GetInterface( id ) )
        return bi;
    return Mtl::GetInterface( id );
}

using namespace frantic::graphics;
using namespace frantic::channels;
using namespace frantic::particles;
using namespace frantic::particles::streams;

bool MaxKrakatoaMaterial::AffectsScatterColor() { return m_pblock->GetInt( kScatteringEnabled ) != FALSE; }

class texmap_functor {
    BitArray m_reqUVWs;

    channel_accessor<vector3f> m_posAccessor;
    channel_const_cvt_accessor<vector3f> m_normalAccessor;
    channel_const_cvt_accessor<int> m_mtlIndexAccessor;
    std::vector<std::pair<int, channel_const_cvt_accessor<vector3f>>> m_mapBindings;

    Matrix3 m_toCameraSpace, m_toCameraSpaceInvTrans, m_camToObjectSpace;
    RenderInstance* m_currentInstance;

  protected:
    Texmap* m_map;
    RenderGlobalContext* m_globContext;

  public:
    texmap_functor( INode* node, Texmap* map, RenderGlobalContext* globContext, bool inWorldSpace = true )
        : m_map( map )
        , m_globContext( globContext ) {
        if( !m_globContext || !map )
            throw std::logic_error( "" );

        frantic::max3d::shaders::update_map_for_shading( map, globContext->time );
        frantic::max3d::shaders::collect_map_requirements( map, m_reqUVWs );

        m_currentInstance = NULL;

        if( node ) {
            for( int i = 0, iEnd = globContext->NumRenderInstances(); i < iEnd && m_currentInstance == NULL; ++i ) {
                RenderInstance* ri = globContext->GetRenderInstance( i );
                if( ri && ri->GetINode() == node )
                    m_currentInstance = ri;
            }
        }

        if( m_currentInstance ) {
            if( !inWorldSpace ) {
                m_toCameraSpace = m_currentInstance->objToCam;
                m_camToObjectSpace = m_currentInstance->camToObj;
            } else {
                m_toCameraSpace = globContext->worldToCam;
                m_camToObjectSpace = m_currentInstance->camToObj;
            }
        } else if( node ) {
            if( !inWorldSpace ) {
                m_toCameraSpace = node->GetNodeTM( globContext->time ) * globContext->worldToCam;
                m_camToObjectSpace = Inverse( m_toCameraSpace );
            } else {
                m_toCameraSpace = globContext->worldToCam;
                m_camToObjectSpace = globContext->camToWorld * Inverse( node->GetNodeTM( globContext->time ) );
            }
        } else {
            m_toCameraSpace = globContext->worldToCam;
            m_camToObjectSpace = globContext->camToWorld;
        }

        m_toCameraSpaceInvTrans = Inverse( m_toCameraSpace );
        m_toCameraSpaceInvTrans.Set( m_toCameraSpaceInvTrans.GetColumn3( 0 ), m_toCameraSpaceInvTrans.GetColumn3( 1 ),
                                     m_toCameraSpaceInvTrans.GetColumn3( 2 ), Point3() );
    }

    void set_channel_map( channel_map& map, const channel_map& nativeMap ) {
        m_posAccessor = map.get_accessor<vector3f>( _T("Position") );

        if( !map.has_channel( _T("Normal") ) && nativeMap.has_channel( _T("Normal") ) )
            map.append_channel<vector3f>( _T("Normal") );
        m_normalAccessor = map.has_channel( _T("Normal") )
                               ? map.get_const_cvt_accessor<vector3f>( _T("Normal") )
                               : channel_const_cvt_accessor<vector3f>( vector3f( 0, 0, 0 ) );

        if( !map.has_channel( _T("MtlIndex") ) && nativeMap.has_channel( _T("MtlIndex") ) )
            map.append_channel<int>( _T("MtlIndex") );
        m_mtlIndexAccessor = map.has_channel( _T("MtlIndex") ) ? map.get_const_cvt_accessor<int>( _T("MtlIndex") )
                                                               : channel_const_cvt_accessor<int>( 0 );

        if( m_reqUVWs[0] ) {
            if( !map.has_channel( _T("Color") ) ) {
                if( !nativeMap.has_channel( _T("Color") ) )
                    FF_LOG( error ) << "Particles Have No \"Color\" Channel. Cannot evaluate material." << std::endl;
                map.append_channel<vector3f>( _T("Color") );
            }

            m_mapBindings.push_back( std::make_pair( 0, map.get_const_cvt_accessor<vector3f>( _T("Color") ) ) );
        }

        if( m_reqUVWs[1] ) {
            if( !map.has_channel( _T("TextureCoord") ) ) {
                if( !nativeMap.has_channel( _T( "TextureCoord" ) ) )
                    FF_LOG( error ) << "Particles Have No \"TextureCoord\" Channel. Cannot evaluate material."
                                    << std::endl;
                map.append_channel<vector3f>( _T("TextureCoord") );
            }

            m_mapBindings.push_back( std::make_pair( 1, map.get_const_cvt_accessor<vector3f>( _T("TextureCoord") ) ) );
        }

        for( int i = 2; i < MAX_MESHMAPS; ++i ) {
            if( m_reqUVWs[i] ) {
                M_STD_STRING name = _T("Mapping") + boost::lexical_cast<M_STD_STRING>( i );
                if( !map.has_channel( name ) ) {
                    if( !nativeMap.has_channel( name ) )
                        FF_LOG( error ) << _T( "Particles Have No \"" ) + name +
                                               _T( "\" Channel. Cannot evaluate material." )
                                        << std::endl;
                    map.append_channel<vector3f>( name );
                }

                m_mapBindings.push_back( std::make_pair( i, map.get_const_cvt_accessor<vector3f>( name ) ) );
            }
        }
    }

    void setup_shadecontext( frantic::max3d::shaders::multimapping_shadecontext& sc, const char* particle ) const {
        Point3 p, n, v;

        p = frantic::max3d::to_max_t( m_posAccessor.get( particle ) );
        p = m_toCameraSpace.PointTransform( p );

        n = Normalize( frantic::max3d::to_max_t( m_normalAccessor.get( particle ) ) );
        n = m_toCameraSpaceInvTrans.VectorTransform( n );
        n = Normalize( n );

        v = Normalize( p );

        sc.position = p;
        sc.camPos = Point3( 0, 0, 0 );
        sc.origView = sc.view = v;
        sc.mtlNum = m_mtlIndexAccessor.get( particle );
        sc.origNormal = sc.normal = DotProd( v, n ) < 0 ? n : -n;
        sc.globContext = m_globContext;
        sc.shadeTime = m_globContext->time;
        sc.toWorldSpaceTM = m_globContext->camToWorld;
        sc.toObjectSpaceTM = m_camToObjectSpace;

        if( m_currentInstance ) {
            sc.inode = m_currentInstance->GetINode();
            sc.evalObject = m_currentInstance->GetEvalObject();
            sc.nLights = m_currentInstance->NumLights();
        }

        // Clobber the ambient light
        sc.ambientLight.Black();

        for( std::vector<std::pair<int, channel_const_cvt_accessor<vector3f>>>::const_iterator
                 it = m_mapBindings.begin(),
                 itEnd = m_mapBindings.end();
             it != itEnd; ++it )
            sc.uvwArray[it->first] = frantic::max3d::to_max_t( it->second.get( particle ) );
    }

    color3f operator()( const char* particle ) const {
        frantic::max3d::shaders::multimapping_shadecontext sc;

        setup_shadecontext( sc, particle );

        AColor c = m_map->EvalColor( sc );

        return color3f( c.r, c.g, c.b );
    }
};

class texmap_mono_functor : public texmap_functor {
  public:
    texmap_mono_functor( INode* node, Texmap* map, RenderGlobalContext* globContext, bool inWorldSpace = true )
        : texmap_functor( node, map, globContext, inWorldSpace ) {}

    float operator()( const char* particle ) const {
        frantic::max3d::shaders::multimapping_shadecontext sc;

        setup_shadecontext( sc, particle );

        return m_map->EvalMono( sc );
    }
};

class blend_functor {
    texmap_functor m_texmapFunctor;
    frantic::graphics::color3f m_color;
    float m_blendAmount;

  public:
    blend_functor( INode* node, Texmap* map, RenderGlobalContext* globContext, const color3f& color, float blendAmount,
                   bool inWorldSpace = true )
        : m_texmapFunctor( node, map, globContext, inWorldSpace )
        , m_color( color )
        , m_blendAmount( blendAmount ) {}

    color3f operator()( const char* particle ) const {
        return m_color + m_blendAmount * ( m_texmapFunctor( particle ) - m_color );
    }

    void set_channel_map( channel_map& map, const channel_map& nativeMap ) {
        m_texmapFunctor.set_channel_map( map, nativeMap );
    }
};

class density_map_functor {
    texmap_mono_functor m_texmapFunctor;
    float m_scale;

    channel_const_cvt_accessor<float> m_densityAccessor;

  public:
    density_map_functor( INode* node, Texmap* map, RenderGlobalContext* globContext, float scale,
                         bool inWorldSpace = true )
        : m_texmapFunctor( node, map, globContext, inWorldSpace )
        , m_scale( scale ) {}

    void set_channel_map( channel_map& map, const channel_map& nativeMap ) {
        if( !map.has_channel( _T("Density") ) && nativeMap.has_channel( _T("Density") ) )
            map.append_channel<float>( _T("Density") );
        m_densityAccessor = map.has_channel( _T("Density") ) ? map.get_const_cvt_accessor<float>( _T("Density") )
                                                             : channel_const_cvt_accessor<float>( 1.f );

        m_texmapFunctor.set_channel_map( map, nativeMap );
    }

    float operator()( const char* particle ) const {
        return m_scale * m_densityAccessor.get( particle ) * m_texmapFunctor( particle );
    }
};

template <class Fn>
class density_scaled_functor {
    Fn m_baseFunctor;
    bool m_densityProportional;
    channel_const_cvt_accessor<float> m_densityAccessor;

  public:
    density_scaled_functor( const Fn& baseFn, bool densityProportional )
        : m_baseFunctor( baseFn )
        , m_densityProportional( densityProportional ) {}

    void set_channel_map( channel_map& map, const channel_map& nativeMap ) {
        if( !map.has_channel( _T("Density") ) && nativeMap.has_channel( _T("Density") ) )
            map.append_channel<float>( _T("Density") );
        m_densityAccessor = map.has_channel( _T("Density") ) ? map.get_const_cvt_accessor<float>( _T("Density") )
                                                             : channel_const_cvt_accessor<float>( 1.f );

        if( !m_densityProportional )
            m_densityAccessor.reset( 1.f );

        m_baseFunctor.set_channel_map( map, nativeMap );
    }

    color3f operator()( const char* particle ) const {
        return m_densityAccessor.get( particle ) * m_baseFunctor( particle );
    }
};

typedef density_scaled_functor<texmap_functor> emission_map_functor;
typedef density_scaled_functor<blend_functor> emission_blend_functor;

class raytrace_reflection_functor {
    Matrix3 m_toCameraSpace, m_toCameraSpaceInvTrans, m_camToObjectSpace;
    bool m_applyAtmosphere;
    bool m_applyEnvironment;
    bool m_twoSided;
    float m_reflectionStrength;
    bool m_doReflectionStrengthScale;

    channel_accessor<vector3f> m_posAccessor;
    channel_const_cvt_accessor<vector3f> m_normalAccessor;
    channel_const_cvt_accessor<color3f> m_emissionAccessor;
    channel_const_cvt_accessor<float> m_densityAccessor;
    channel_const_cvt_accessor<float> m_reflectionAccessor;

    RenderGlobalContext* m_globContext;

  public:
    raytrace_reflection_functor( INode* node, RenderGlobalContext* globContext, float reflStrength = 1.f,
                                 bool applyEnvironment = true, bool applyAtmosphere = true, bool twoSided = false,
                                 bool inWorldSpace = true ) {
        m_globContext = globContext;
        m_applyEnvironment = applyEnvironment;
        m_applyAtmosphere = applyAtmosphere;
        m_twoSided = twoSided;
        float rendererReflectionStrength =
            GetMaxKrakatoa()->properties().get_float( _T( "EnvironmentReflectionStrength" ) );
        m_reflectionStrength = reflStrength * rendererReflectionStrength;
        m_doReflectionStrengthScale = false;

        if( node ) {
            if( !inWorldSpace ) {
                m_toCameraSpace = node->GetNodeTM( globContext->time ) * globContext->worldToCam;
                m_camToObjectSpace = Inverse( m_toCameraSpace );
            } else {
                m_toCameraSpace = globContext->worldToCam;
                m_camToObjectSpace = globContext->camToWorld * Inverse( node->GetNodeTM( globContext->time ) );
            }
        } else {
            m_toCameraSpace = globContext->worldToCam;
            m_camToObjectSpace = globContext->camToWorld;
        }

        m_toCameraSpaceInvTrans = Inverse( m_toCameraSpace );
        m_toCameraSpaceInvTrans.Set( m_toCameraSpaceInvTrans.GetColumn3( 0 ), m_toCameraSpaceInvTrans.GetColumn3( 1 ),
                                     m_toCameraSpaceInvTrans.GetColumn3( 2 ), Point3() );
    }

    void set_channel_map( channel_map& map, const channel_map& nativeMap ) {
        m_posAccessor = map.get_accessor<vector3f>( _T("Position") );

        if( !map.has_channel( _T("Normal") ) && nativeMap.has_channel( _T("Normal") ) )
            map.append_channel<vector3f>( _T("Normal") );
        m_normalAccessor = map.has_channel( _T("Normal") )
                               ? map.get_const_cvt_accessor<vector3f>( _T("Normal") )
                               : channel_const_cvt_accessor<vector3f>( vector3f::from_zaxis() );
        if( !map.has_channel( _T("Density") ) && nativeMap.has_channel( _T("Density") ) )
            map.append_channel<float>( _T("Density") );
        m_densityAccessor = map.has_channel( _T("Density") ) ? map.get_const_cvt_accessor<float>( _T("Density") )
                                                             : channel_const_cvt_accessor<float>( 1.f );

        m_emissionAccessor = map.has_channel( _T("Emission") )
                                 ? map.get_const_cvt_accessor<color3f>( _T("Emission") )
                                 : channel_const_cvt_accessor<color3f>( color3f::black() );

        if( map.has_channel( _T( "ReflectionStrength" ) ) && nativeMap.has_channel( _T( "ReflectionStrength" ) ) ) {
            m_reflectionAccessor = map.get_const_cvt_accessor<float>( _T( "ReflectionStrength" ) );
            m_doReflectionStrengthScale = true;
        } else {
            m_reflectionAccessor = channel_const_cvt_accessor<float>( m_reflectionStrength );
            m_doReflectionStrengthScale = false;
        }
    }

    color3f operator()( const char* particle ) const {
        Point3 n;

        n = Normalize( frantic::max3d::to_max_t( m_normalAccessor.get( particle ) ) );
        n = m_toCameraSpaceInvTrans.VectorTransform( n );
        n = Normalize( n );

        Ray r;

        r.p = frantic::max3d::to_max_t( m_posAccessor.get( particle ) );
        r.p = m_toCameraSpace.PointTransform( r.p );

        r.dir = Normalize( r.p );

        if( DotProd( r.dir, n ) > 0 ) {
            if( !m_twoSided )
                return color3f::black();
            n = -n;
        }

        r.dir = r.dir - 2 * DotProd( r.dir, n ) * n; // Reflect it.;

        ISect isct;
        ISectList xpList;

        BOOL result = m_globContext->IntersectWorld( r, -1, isct, xpList );
        if( result ) {
            class rt_shadecontext : public ShadeContext {
              public:
                Ray r;
                ISect isct;

                Point3 curView, curNormal;
                float ior;

              private:
                Point3 GetBarycentricNormal() {
                    return Normalize( isct.bc.x * isct.inst->GetFaceVertNormal( isct.fnum, 0 ) +
                                      isct.bc.y * isct.inst->GetFaceVertNormal( isct.fnum, 1 ) +
                                      isct.bc.z * isct.inst->GetFaceVertNormal( isct.fnum, 2 ) );
                }

              public:
                rt_shadecontext( const Ray& _r, const ISect& _isct, RenderGlobalContext& _globContext ) {
                    r = _r;
                    isct = _isct;
                    globContext = &_globContext;

                    curView = r.dir;
                    curNormal = GetBarycentricNormal(); // TODO: Fix.

                    nLights = isct.inst->NumLights();
                    mtlNum = isct.mtlNum;
                    doMaps = filterMaps = TRUE;
                    backFace = isct.backFace;
                    ambientLight.Black();
                }

                BOOL InMtlEditor() { return globContext->inMtlEdit; }
                LightDesc* Light( int n ) { return isct.inst->Light( n ); }
                Object* GetEvalObject() { return isct.inst->GetEvalObject(); }
                INode* Node() { return isct.inst->GetINode(); }
                int NodeID() { return isct.inst->nodeID; }
                int ProjType() { return globContext->projType; }
                int FaceNumber() { return isct.fnum; }
                TimeValue CurTime() { return globContext->time; }
                Point3 Normal() { return curNormal; }
                Point3 OrigNormal() { return GetBarycentricNormal(); }
                Point3 GNormal() {
                    return isct.inst->normalObjToCam.VectorTransform( isct.inst->GetFaceNormal( isct.fnum ) );
                }
                void SetNormal( Point3 p ) { curNormal = p; }
                Point3 ReflectVector() { return V() - 2 * DotProd( V(), Normal() ) * Normal(); }
                Point3 RefractVector( float ior ) {
                    // Taken from Max SDK cjrender sample.

                    float VN, nur, k;
                    VN = DotProd( -V(), Normal() );
                    if( backFace )
                        nur = ior;
                    else
                        nur = ( ior != 0.0f ) ? 1.0f / ior : 1.0f;
                    k = 1.0f - nur * nur * ( 1.0f - VN * VN );
                    if( k <= 0.0f ) {
                        // Total internal reflection:
                        return ReflectVector();
                    } else {
                        return ( nur * VN - (float)sqrt( k ) ) * Normal() + nur * V();
                    }
                }
                void SetIOR( float _ior ) { ior = _ior; }
                float GetIOR() { return ior; }
                Point3 CamPos() { return r.p; }
                Point3 V() { return curView; }
                Point3 OrigView() { return r.dir; }
                void SetView( Point3 v ) { curView = v; }
                Point3 P() { return isct.pc; }
                Point3 DP() { return Point3( 0, 0, 0 ); }
                Point3 PObj() { return isct.inst->camToObj.PointTransform( P() ); }
                Point3 DPObj() { return Point3( 0, 0, 0 ); }
                Box3 ObjectBox() { return isct.inst->obBox; }
                Point3 PObjRelBox() { return Point3( 0, 0, 0 ); }
                Point3 DPObjRelBox() { return Point3( 0, 0, 0 ); }
                Point3 UVW( int chan ) {
                    Mesh* m = isct.inst->mesh;
                    if( m && m->mapSupport( chan ) && isct.fnum >= 0 && isct.fnum < m->numFaces ) {
                        Point3 uvws[] = { m->mapVerts( chan )[m->mapFaces( chan )[isct.fnum].t[0]],
                                          m->mapVerts( chan )[m->mapFaces( chan )[isct.fnum].t[1]],
                                          m->mapVerts( chan )[m->mapFaces( chan )[isct.fnum].t[2]] };

                        return isct.bc.x * uvws[0] + isct.bc.y * uvws[1] + isct.bc.z * uvws[2];
                    }

                    return Point3( 0, 0, 0 );
                }
                Point3 DUVW( int /*chan*/ ) { return Point3( 0, 0, 0 ); }
                void DPdUVW( Point3 dP[3], int /*chan*/ ) { dP[0] = dP[1] = dP[2] = Point3( 0, 0, 0 ); }
                void ScreenUV( Point2& uv, Point2& duv ) {
                    Point2 p2 = globContext->MapToScreen( P() );
                    uv.x = p2.x / (float)globContext->devWidth;
                    uv.y = p2.y / (float)globContext->devHeight;
                    duv.x = 0.f;
                    duv.y = 0.f;
                }
                IPoint2 ScreenCoord() {
                    Point2 p2 = globContext->MapToScreen( P() );
                    return IPoint2( (int)floorf( p2.x + 0.5f ), (int)floorf( p2.y + 0.5f ) );
                }

                Point3 PointTo( const Point3& p, RefFrame ito ) {
                    switch( ito ) {
                    default:
                    case REF_CAMERA:
                        return p;
                    case REF_OBJECT:
                        return isct.inst->camToObj.PointTransform( p );
                    case REF_WORLD:
                        return globContext->camToWorld.PointTransform( p );
                    }
                }
                Point3 PointFrom( const Point3& p, RefFrame ifrom ) {
                    switch( ifrom ) {
                    case REF_OBJECT:
                        return isct.inst->objToCam.PointTransform( p );
                    case REF_WORLD:
                        return globContext->worldToCam.PointTransform( p );
                    case REF_CAMERA:
                    default:
                        return p;
                    }
                }
                Point3 VectorTo( const Point3& p, RefFrame ito ) {
                    switch( ito ) {
                    default:
                    case REF_CAMERA:
                        return p;
                    case REF_OBJECT:
                        return isct.inst->camToObj.VectorTransform( p );
                    case REF_WORLD:
                        return globContext->camToWorld.VectorTransform( p );
                    }
                }
                Point3 VectorFrom( const Point3& p, RefFrame ifrom ) {
                    switch( ifrom ) {
                    case REF_OBJECT:
                        return isct.inst->objToCam.VectorTransform( p );
                    case REF_WORLD:
                        return globContext->worldToCam.VectorTransform( p );
                    case REF_CAMERA:
                    default:
                        return p;
                    }
                }
                void GetBGColor( Color& bgcol, Color& transp, BOOL /*fogBG*/ ) {
                    bgcol.Black();
                    transp.White();
                }
            } raySC( r, isct, *m_globContext );

            if( isct.inst->mtl )
                isct.inst->mtl->Shade( raySC );

            Color result = raySC.out.c;

            if( m_applyAtmosphere && raySC.globContext->atmos != NULL ) {
                Color transp = raySC.out.t;
                raySC.globContext->atmos->Shade( raySC, r.p, isct.pc, result, transp, FALSE );
            }

            float refStrengthScale = m_reflectionAccessor.get( particle );
            if( m_doReflectionStrengthScale ) {
                refStrengthScale *= m_reflectionStrength;
            }
            float reflScale = refStrengthScale * m_densityAccessor.get( particle );

            return m_emissionAccessor.get( particle ) + reflScale * frantic::max3d::from_max_t( result );
        } else {
            class bg_shadecontext : public ShadeContext {
              public:
                Ray r;
                Point3 curView, curNormal, origNormal;
                Matrix3 toObject;
                float ior;

              public:
                bg_shadecontext( const Ray& _r, const Point3& _normal, const Matrix3& _toObject,
                                 RenderGlobalContext& _globContext )
                    : toObject( _toObject ) {
                    r = _r;
                    globContext = &_globContext;

                    curView = r.dir;
                    curNormal = origNormal = _normal;

                    mtlNum = 0;
                    doMaps = filterMaps = TRUE;
                    backFace = FALSE;
                    ambientLight.Black();
                }

                BOOL InMtlEditor() { return globContext->inMtlEdit; }
                LightDesc* Light( int /*n*/ ) { return NULL; }
                Object* GetEvalObject() { return NULL; }
                INode* Node() { return NULL; }
                int NodeID() { return -1; }
                int ProjType() { return globContext->projType; }
                int FaceNumber() { return 0; }
                TimeValue CurTime() { return globContext->time; }
                Point3 Normal() { return curNormal; }
                Point3 OrigNormal() { return origNormal; }
                Point3 GNormal() { return origNormal; }
                void SetNormal( Point3 p ) { curNormal = p; }
                Point3 ReflectVector() { return V() - 2 * DotProd( V(), Normal() ) * Normal(); }
                Point3 RefractVector( float ior ) {
                    // Taken from Max SDK cjrender sample.

                    float VN, nur, k;
                    VN = DotProd( -V(), Normal() );
                    if( backFace )
                        nur = ior;
                    else
                        nur = ( ior != 0.0f ) ? 1.0f / ior : 1.0f;
                    k = 1.0f - nur * nur * ( 1.0f - VN * VN );
                    if( k <= 0.0f ) {
                        // Total internal reflection:
                        return ReflectVector();
                    } else {
                        return ( nur * VN - (float)sqrt( k ) ) * Normal() + nur * V();
                    }
                }
                void SetIOR( float _ior ) { ior = _ior; }
                float GetIOR() { return ior; }
                Point3 CamPos() { return Point3( 0, 0, 0 ); }
                Point3 V() { return curView; }
                Point3 OrigView() { return r.dir; }
                void SetView( Point3 v ) { curView = v; }
                Point3 P() { return r.p; }
                Point3 DP() { return Point3( 0, 0, 0 ); }
                Point3 PObj() { return toObject.PointTransform( P() ); }
                Point3 DPObj() { return Point3( 0, 0, 0 ); }
                Box3 ObjectBox() { return Box3( Point3( 0, 0, 0 ), Point3( 0, 0, 0 ) ); }
                Point3 PObjRelBox() { return Point3( 0, 0, 0 ); }
                Point3 DPObjRelBox() { return Point3( 0, 0, 0 ); }
                Point3 UVW( int /*chan*/ ) { return Point3( 0, 0, 0 ); }
                Point3 DUVW( int /*chan*/ ) { return Point3( 0, 0, 0 ); }
                void DPdUVW( Point3 dP[3], int /*chan*/ ) { dP[0] = dP[1] = dP[2] = Point3( 0, 0, 0 ); }
                void ScreenUV( Point2& uv, Point2& duv ) {
                    Point2 p2 = globContext->MapToScreen( P() );
                    uv.x = p2.x / (float)globContext->devWidth;
                    uv.y = p2.y / (float)globContext->devHeight;
                    duv.x = 0.f;
                    duv.y = 0.f;
                }
                IPoint2 ScreenCoord() {
                    Point2 p2 = globContext->MapToScreen( P() );
                    return IPoint2( (int)floorf( p2.x + 0.5f ), (int)floorf( p2.y + 0.5f ) );
                }

                Point3 PointTo( const Point3& p, RefFrame ito ) {
                    switch( ito ) {
                    default:
                    case REF_CAMERA:
                        return p;
                    case REF_OBJECT:
                        return toObject.PointTransform( p );
                    case REF_WORLD:
                        return globContext->camToWorld.PointTransform( p );
                    }
                }
                Point3 PointFrom( const Point3& p, RefFrame ifrom ) {
                    switch( ifrom ) {
                    case REF_OBJECT:
                        return p; // Wrong
                    case REF_WORLD:
                        return globContext->worldToCam.PointTransform( p );
                    case REF_CAMERA:
                    default:
                        return p;
                    }
                }
                Point3 VectorTo( const Point3& p, RefFrame ito ) {
                    switch( ito ) {
                    default:
                    case REF_CAMERA:
                        return p;
                    case REF_OBJECT:
                        return toObject.VectorTransform( p );
                    case REF_WORLD:
                        return globContext->camToWorld.VectorTransform( p );
                    }
                }
                Point3 VectorFrom( const Point3& p, RefFrame ifrom ) {
                    switch( ifrom ) {
                    case REF_OBJECT:
                        return p; // Wrong
                    case REF_WORLD:
                        return globContext->worldToCam.VectorTransform( p );
                    case REF_CAMERA:
                    default:
                        return p;
                    }
                }
                void GetBGColor( Color& bgcol, Color& transp, BOOL /*fogBG*/ ) {
                    bgcol.Black();
                    transp.White();
                }
            } bgSC( r, n, m_camToObjectSpace, *m_globContext );

            Color result( 0.f, 0.f, 0.f );

            if( m_applyEnvironment && m_globContext->envMap != NULL ) {
                result = (Color)m_globContext->envMap->EvalColor( bgSC );

                if( !boost::math::isfinite(
                        result.r ) /*|| !boost::math::isfinite(result.g) || !boost::math::isfinite(result.b)*/ ) // Only
                                                                                                                 // need
                                                                                                                 // to
                                                                                                                 // check
                                                                                                                 // one.
                    result.Black();
            }

            if( m_applyAtmosphere && m_globContext->atmos != NULL ) {
                Color transp( 1.f, 1.f, 1.f );
                Point3 end = FLT_MAX * r.dir;
                m_globContext->atmos->Shade( bgSC, r.p, end, result, transp, TRUE );

                if( !boost::math::isfinite(
                        result.r ) /*|| !boost::math::isfinite(result.g) || !boost::math::isfinite(result.b)*/ ) // Only
                                                                                                                 // need
                                                                                                                 // to
                                                                                                                 // check
                                                                                                                 // one.
                    result.Black();
            }

            float refStrengthScale = m_reflectionAccessor.get( particle );
            if( m_doReflectionStrengthScale ) {
                refStrengthScale *= m_reflectionStrength;
            }
            float reflScale = refStrengthScale * m_densityAccessor.get( particle );

            return m_emissionAccessor.get( particle ) + reflScale * frantic::max3d::from_max_t( result );
        }
    }
};

boost::shared_ptr<particle_istream>
MaxKrakatoaMaterial::ApplyMaterial( boost::shared_ptr<particle_istream> pin, INode* pNode, TimeValue t,
                                    Interval& inoutValidity,
                                    frantic::max3d::particles::IMaxKrakatoaPRTEvalContextPtr pEvalContext ) {
    // MaxKrakatoaSceneContextPtr maxSceneContext = boost::dynamic_pointer_cast<MaxKrakatoaSceneContext>( sceneContext
    // ); if( !maxSceneContext ) 	return pin;

    // RenderGlobalContext* globContext = const_cast<RenderGlobalContext*>( maxSceneContext->get_render_global_context()
    // ); //Max sin't const correct yet... if( !globContext ) 	return pin;

    RenderGlobalContext* globContext = &pEvalContext->GetRenderGlobalContext();

    if( m_pblock->GetInt( kScatteringEnabled ) ) {
        Texmap* pMap = m_pblock->GetTexmap( kScatteringTexmap );
        float blend = m_pblock->GetFloat( kScatteringBlend );
        color3f c = frantic::max3d::from_max_t( m_pblock->GetColor( kScatteringColor, t ) );

        if( pMap && blend > 0.f ) {
            if( blend >= 100.f ) {
                pin.reset( new functor_particle_istream<texmap_functor, color3f>(
                    pin, _T("Color"), texmap_functor( pNode, pMap, globContext, true ) ) );
            } else {
                pin.reset( new functor_particle_istream<blend_functor, color3f>(
                    pin, _T("Color"), blend_functor( pNode, pMap, globContext, c, blend / 100.f, true ) ) );
            }
        } else {
            pin.reset( new set_channel_particle_istream<color3f>( pin, _T("Color"), c ) );
        }
    }

    if( m_pblock->GetInt( kAbsorptionEnabled ) ) {
        Texmap* pMap = m_pblock->GetTexmap( kAbsorptionTexmap );
        float blend = m_pblock->GetFloat( kAbsorptionBlend );
        color3f c = frantic::max3d::from_max_t( m_pblock->GetColor( kAbsorptionColor, t ) );

        if( pMap && blend > 0.f ) {
            if( blend >= 100.f ) {
                pin.reset( new functor_particle_istream<texmap_functor, color3f>(
                    pin, _T("Absorption"), texmap_functor( pNode, pMap, globContext, true ) ) );
            } else {
                pin.reset( new functor_particle_istream<blend_functor, color3f>(
                    pin, _T("Absorption"), blend_functor( pNode, pMap, globContext, c, blend / 100.f, true ) ) );
            }
        } else {
            pin.reset( new set_channel_particle_istream<color3f>( pin, _T("Absorption"), c ) );
        }
    }

    if( m_pblock->GetInt( kEmissionEnabled ) ) {
        Texmap* pMap = m_pblock->GetTexmap( kEmissionTexmap );
        float blend = m_pblock->GetFloat( kEmissionBlend );
        color3f c = frantic::max3d::from_max_t( m_pblock->GetColor( kEmissionColor, t ) );

        bool densityProportional = ( m_pblock->GetInt( kEmissionIsProportionalToDensity ) != FALSE );

        if( pMap && blend > 0.f ) {
            if( blend >= 100.f ) {
                // pin.reset( new functor_particle_istream< texmap_functor, color3f >( pin, _T("Emission"),
                // texmap_functor( pNode, pMap, globContext, true ) ) );
                pin.reset( new functor_particle_istream<emission_map_functor, color3f>(
                    pin, _T("Emission"),
                    emission_map_functor( texmap_functor( pNode, pMap, globContext, true ), densityProportional ) ) );
            } else {
                // pin.reset( new functor_particle_istream< blend_functor, color3f >( pin, _T("Emission"),
                // blend_functor( pNode, pMap, globContext, c, blend / 100.f, true ) ) );
                pin.reset( new functor_particle_istream<emission_blend_functor, color3f>(
                    pin, _T("Emission"),
                    emission_blend_functor( blend_functor( pNode, pMap, globContext, c, blend / 100.f, true ),
                                            densityProportional ) ) );
            }
        } else {
            pin.reset( new set_channel_particle_istream<color3f>( pin, _T("Emission"), c ) );
        }

        if( m_pblock->GetInt( kReflectionEnabled ) ) {
            float reflStrength = m_pblock->GetFloat( kReflectionStrength );
            bool doAtmos = ( m_pblock->GetInt( kReflectAtmosphere ) != FALSE );
            bool doEnviron = ( m_pblock->GetInt( kReflectEnvironment ) != FALSE );
            bool twoSided = ( m_pblock->GetInt( kReflectBackfacing ) != FALSE );

            pin.reset( new functor_particle_istream<raytrace_reflection_functor, color3f>(
                pin, _T("Emission"),
                raytrace_reflection_functor( pNode, globContext, reflStrength, doEnviron, doAtmos, twoSided, true ) ) );
        }
    }

    if( m_pblock->GetInt( kDensityEnabled ) ) {
        Texmap* pMap = m_pblock->GetTexmap( kDensityTexmap );
        float densityScale = m_pblock->GetFloat( kDensityScale, t );

        if( densityScale < 0 )
            densityScale = 0;

        if( pMap ) {
            pin.reset( new functor_particle_istream<density_map_functor, float>(
                pin, _T("Density"), density_map_functor( pNode, pMap, globContext, densityScale, true ) ) );
        } else if( densityScale != 1.f ) {
            pin.reset( new density_scale_particle_istream( pin, densityScale ) );
        }
    }

    return pin;
}