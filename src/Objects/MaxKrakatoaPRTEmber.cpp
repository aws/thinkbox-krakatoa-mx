// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0
#include "stdafx.h"
#ifdef DONTBUILDTHIS
#include "resource.h"

#include <boost/any.hpp>
#include <boost/exception/all.hpp>
#include <boost/shared_array.hpp>

#include "MaxKrakatoaReferenceTarget.h"
#include "Objects/MaxKrakatoaPRTObject.h"

#include <frantic/magma/simple_compiler/simple_compiler.hpp>
#include <frantic/particles/streams/empty_particle_istream.hpp>
#include <frantic/particles/streams/particle_container_particle_istream.hpp>
#include <krakatoa/prt_maker.hpp>

#include <ember/max3d/IEmberHolder.hpp>
#include <ember/particles.hpp>

#include <frantic/max3d/convert.hpp>

#define MaxKrakatoaPRTEmberObject_CLASSID Class_ID( 0x9eb138e, 0x56734087 )
#define MaxKrakatoaPRTEmber_NAME "PRT Ember"
#define MaxKrakatoaPRTEmber_VERSION 1

#define EmberHolder_CLASS Class_ID( 0x2b493510, 0x5134620d )

extern HINSTANCE hInstance;

using frantic::graphics::vector3f;

enum { kIconSize, kMagmaHolderRef, kBoundsMin, kBoundsMax, kSpacing };

class MaxKrakatoaPRTEmber
    : public MaxKrakatoaReferenceTarget<MaxKrakatoaPRTObject<MaxKrakatoaPRTEmber>, MaxKrakatoaPRTEmber> {
  protected:
    virtual ClassDesc2* GetClassDesc();
    virtual Mesh* GetIconMesh( Matrix3& outTM );

    virtual particle_istream_ptr GetInternalStream( IEvalContext* globContext, INode* pNode );

  public:
    MaxKrakatoaPRTEmber( BOOL loading = FALSE );
    virtual ~MaxKrakatoaPRTEmber();

    virtual void SetIconSize( float size );

    // From ReferenceMaker
    virtual RefResult NotifyRefChanged( Interval, RefTargetHandle, PartID&, RefMessage );

    // From BaseObject
    virtual
#if MAX_VERSION_MAJOR >= 15
        const
#endif
        TCHAR*
        GetObjectName();

    // From Object
    virtual void InitNodeName( MSTR& s );
};

class MaxKrakatoaPRTEmberDesc : public ClassDesc2 {
    ParamBlockDesc2 m_paramDesc;

  public:
    MaxKrakatoaPRTEmberDesc();
    virtual ~MaxKrakatoaPRTEmberDesc();

    int IsPublic() { return TRUE; }
    void* Create( BOOL /*loading*/ ) { return new MaxKrakatoaPRTEmber; }
    const TCHAR* ClassName() { return _T( MaxKrakatoaPRTEmber_NAME ); }
    SClass_ID SuperClassID() { return GEOMOBJECT_CLASS_ID; }
    Class_ID ClassID() { return MaxKrakatoaPRTEmberObject_CLASSID; }
    const TCHAR* Category() { return _T("Krakatoa"); }

    const TCHAR* InternalName() {
        return _T( MaxKrakatoaPRTEmber_NAME );
    }                                           // returns fixed parsable name (scripter-visible name)
    HINSTANCE HInstance() { return hInstance; } // returns owning module handle
};

ClassDesc2* GetMaxKrakatoaPRTEmberDesc() {
    static MaxKrakatoaPRTEmberDesc theDesc;
    return &theDesc;
}

MaxKrakatoaPRTEmberDesc::MaxKrakatoaPRTEmberDesc()
    : m_paramDesc( 0,                                                        // Block num
                   _T("Parameters"),                                         // Internal name
                   NULL,                                                     // Localized name
                   NULL,                                                     // ClassDesc2*
                   P_AUTO_CONSTRUCT + /*P_AUTO_UI + P_MULTIMAP*/ +P_VERSION, // Flags
                   MaxKrakatoaPRTEmber_VERSION,
                   0, // PBlock Ref Num
                   // 1,                                                     //multimap count
                   // 0, IDD_PRTCREATOR, IDS_PARAMETERS, 0, 0, NULL,            //AutoUI stuff for panel 0
                   p_end ) {
    m_paramDesc.SetClassDesc( this );

    //------------------------------------------------------------------------------------------------------------------------------------------------------------------
    // Main rollout parameters
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------
    m_paramDesc.AddParam( kIconSize, _T("IconSize"), TYPE_FLOAT, P_RESET_DEFAULT, 0, p_end );
    m_paramDesc.ParamOption( kIconSize, p_default, 30.f );
    m_paramDesc.ParamOption( kIconSize, p_range, 0.f, FLT_MAX );
    // m_paramDesc.ParamOption(kIconSize, p_ui, 0, TYPE_SPINNER, EDITTYPE_POS_FLOAT, IDC_PRTCREATOR_ICONSIZE_EDIT,
    // IDC_PRTCREATOR_ICONSIZE_SPIN, SPIN_AUTOSCALE, p_end);

    m_paramDesc.AddParam( kMagmaHolderRef, _T("magmaHolder"), TYPE_REFTARG, P_SUBANIM, IDS_MAGMA_HOLDER, p_end );
    m_paramDesc.ParamOption( kMagmaHolderRef, p_classID, EmberHolder_CLASS, p_end );

    m_paramDesc.AddParam( kBoundsMin, _T("BoundsMin"), TYPE_POINT3, 0, 0, p_end );
    m_paramDesc.ParamOption( kBoundsMin, p_default, Point3( -10, -10, -10 ) );
    // m_paramDesc.ParamOption(kBoundsMin, p_range, 0.f, FLT_MAX);
    // m_paramDesc.ParamOption(kBoundsMin, p_ui, 0, TYPE_SPINNER, EDITTYPE_POS_FLOAT, IDC_PRTCREATOR_ICONSIZE_EDIT,
    // IDC_PRTCREATOR_ICONSIZE_SPIN, SPIN_AUTOSCALE, p_end);

    m_paramDesc.AddParam( kBoundsMax, _T("BoundsMax"), TYPE_POINT3, 0, 0, p_end );
    m_paramDesc.ParamOption( kBoundsMax, p_default, Point3( 10, 10, 10 ) );
    // m_paramDesc.ParamOption(kBoundsMax, p_range, 0.f, FLT_MAX);
    // m_paramDesc.ParamOption(kBoundsMax, p_ui, 0, TYPE_SPINNER, EDITTYPE_POS_FLOAT, IDC_PRTCREATOR_ICONSIZE_EDIT,
    // IDC_PRTCREATOR_ICONSIZE_SPIN, SPIN_AUTOSCALE, p_end);

    m_paramDesc.AddParam( kSpacing, _T("Spacing"), TYPE_FLOAT, 0, 0, p_end );
    m_paramDesc.ParamOption( kSpacing, p_default, 1.f );
    m_paramDesc.ParamOption( kSpacing, p_range, 0.f, FLT_MAX );
    // m_paramDesc.ParamOption(kIconSize, p_ui, 0, TYPE_SPINNER, EDITTYPE_POS_FLOAT, IDC_PRTCREATOR_ICONSIZE_EDIT,
    // IDC_PRTCREATOR_ICONSIZE_SPIN, SPIN_AUTOSCALE, p_end);
}

MaxKrakatoaPRTEmberDesc::~MaxKrakatoaPRTEmberDesc() {}

ClassDesc2* MaxKrakatoaPRTEmber::GetClassDesc() { return GetMaxKrakatoaPRTEmberDesc(); }

extern Mesh* GetPRTMakerIconMesh();

Mesh* MaxKrakatoaPRTEmber::GetIconMesh( Matrix3& outTM ) {
    float size = m_pblock->GetFloat( kIconSize );

    outTM.SetScale( Point3( size, size, size ) );

    return GetPRTMakerIconMesh();
}

template <class Container>
class caching_particle_istream
    : public frantic::particles::streams::particle_container_particle_istream<typename Container::iterator> {
    boost::shared_ptr<Container> m_particles;

  public:
    caching_particle_istream( boost::shared_ptr<Container> particles )
        : particle_container_particle_istream( particles->begin(), particles->end(), particles->get_channel_map() )
        , m_particles( particles ) {}

    virtual ~caching_particle_istream() {}
};

MaxKrakatoaPRTEmber::particle_istream_ptr MaxKrakatoaPRTEmber::GetInternalStream( IEvalContext* globContext,
                                                                                  INode* pNode ) {
    ReferenceTarget* rtargHolder = m_pblock->GetReferenceTarget( kMagmaHolderRef );
    if( !rtargHolder )
        return particle_istream_ptr();

    ember::max3d::IEmberHolder* emberHolder =
        (ember::max3d::IEmberHolder*)rtargHolder->GetInterface( EmberHolder_INTERFACE );
    if( !emberHolder )
        return particle_istream_ptr();

    Interval garbage;
    std::map<frantic::tstring, ember::field_interface_ptr> emberFields;

    try {
        emberHolder->get_all_fields( pNode, globContext->get_max_context(), emberFields, garbage );

        if( emberFields.find( _T("Density") ) == emberFields.end() )
            throw std::runtime_error( "A \"Density\" field must be set in order to seed particles" );

        Point3 boundsMin = m_pblock->GetPoint3( kBoundsMin, globContext->get_time() );
        Point3 boundsMax = m_pblock->GetPoint3( kBoundsMax, globContext->get_time() );
        float spacing = m_pblock->GetFloat( kSpacing, globContext->get_time() );

        int bounds[] = {
            (int)std::floor( boundsMin.x / spacing - 0.5f ), (int)std::ceil( boundsMax.x / spacing - 0.5f ) + 1,
            (int)std::floor( boundsMin.y / spacing - 0.5f ), (int)std::ceil( boundsMax.y / spacing - 0.5f ) + 1,
            (int)std::floor( boundsMin.z / spacing - 0.5f ), (int)std::ceil( boundsMax.z / spacing - 0.5f ) + 1,
        };

        ember::particle_sampler sampler;
        sampler.set_domain( bounds, spacing );
        sampler.set_density_field( emberFields[_T("Density")] );
        for( std::map<frantic::tstring, ember::field_interface_ptr>::iterator it = emberFields.begin(),
                                                                              itEnd = emberFields.end();
             it != itEnd; ++it ) {
            if( it->first != _T("Density") )
                sampler.add_auxiliary_field( it->first, it->second );
        }

        boost::shared_ptr<ember::particle_sampler::particle_collection> particles(
            new ember::particle_sampler::particle_collection );

        sampler.sample_to_particles( *particles, true );

        particle_istream_ptr result(
            new caching_particle_istream<ember::particle_sampler::particle_collection>( particles ) );

        result->set_channel_map( globContext->get_channel_map() );

        return result;
    } catch( const frantic::magma::magma_exception& e ) {
        FF_LOG( error ) << e.get_message( true ) << std::endl;
    } catch( const std::exception& e ) {
        FF_LOG( error ) << frantic::strings::to_tstring( e.what() ) << std::endl;
    }

    return particle_istream_ptr( new frantic::particles::streams::empty_particle_istream(
        globContext->get_channel_map(), globContext->get_channel_map() ) );
}

MaxKrakatoaPRTEmber::MaxKrakatoaPRTEmber( BOOL loading ) {
    GetMaxKrakatoaPRTEmberDesc()->MakeAutoParamBlocks( this );

    m_pblock->SetValue( kMagmaHolderRef, 0,
                        (ReferenceTarget*)CreateInstance( REF_TARGET_CLASS_ID, EmberHolder_CLASS ) );
}

MaxKrakatoaPRTEmber::~MaxKrakatoaPRTEmber() {}

void MaxKrakatoaPRTEmber::SetIconSize( float size ) { m_pblock->SetValue( kIconSize, 0, size ); }

// From ReferenceMaker
RefResult MaxKrakatoaPRTEmber::NotifyRefChanged( Interval, RefTargetHandle, PartID&, RefMessage ) {
    return REF_SUCCEED;
}

// From BaseObject
#if MAX_VERSION_MAJOR >= 15
const
#endif
    TCHAR*
    MaxKrakatoaPRTEmber::GetObjectName() {
    return _T( MaxKrakatoaPRTEmber_NAME );
}

// From Object
void MaxKrakatoaPRTEmber::InitNodeName( MSTR& s ) { s = _T( MaxKrakatoaPRTEmber_NAME ); }
#endif
