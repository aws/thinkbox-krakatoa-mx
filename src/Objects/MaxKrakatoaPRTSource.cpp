// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0
#include "resource.h"
#include "stdafx.h"

#include "Objects/MaxKrakatoaPRTInterface.h"
#include "Objects\IMaxKrakatoaPRTSource.h"
#include "Objects\MaxKrakatoaPRTLoader.h"
#include "Objects\MaxKrakatoaPRTSource.hpp"

#include "PRTSourceDialogProcs\group_dlg_proc_base.hpp"
#include "PRTSourceDialogProcs\particle_flow_events_dlg_proc.hpp"
#include "PRTSourceDialogProcs\tp_groups_dlg_proc.hpp"

#include "MaxKrakatoaChannelModifier.h"
#include "MaxKrakatoaMaterial.hpp"
#include "MaxKrakatoaParticleSources.h"
#include "MaxKrakatoaReferenceTarget.h"
#include "MaxKrakatoaStdMaterialStream.h"

#include <frantic/particles/prt_file_header.hpp>
#include <frantic/particles/streams/concatenated_particle_istream.hpp>
#include <frantic/particles/streams/empty_particle_istream.hpp>
#include <frantic/particles/streams/fractional_by_id_particle_istream.hpp>
#include <frantic/particles/streams/fractional_particle_istream.hpp>
#include <frantic/particles/streams/particle_array_particle_istream.hpp>
#include <frantic/particles/streams/selection_culled_particle_istream.hpp>
#include <frantic/particles/streams/set_channel_particle_istream.hpp>
#include <frantic/particles/streams/transformed_particle_istream.hpp>

#include <frantic/max3d/AutoViewExp.hpp>
#include <frantic/max3d/geometry/null_view.hpp>
#include <frantic/max3d/max_utility.hpp>
#include <frantic/max3d/particles/particle_system_validator.hpp>
#include <frantic/max3d/particles/streams/deformed_particle_istream.hpp>
#include <frantic/max3d/particles/tp_interface.hpp>

#include <custcont.h>
#include <iparamm2.h>

#include <boost/cstdint.hpp>
#include <boost/tuple/tuple.hpp>

#define MaxKrakatoaPRTSourceObject_NAME "PRT Source"
#define MaxKrakatoaPRTSourceObject_VERSION 1

extern HINSTANCE hInstance;
extern Mesh* GetPRTSourceIconMesh();
#if MAX_VERSION_MAJOR >= 25
extern MaxSDK::SharedMeshPtr GetPRTSourceIconMeshShared();
#endif

using namespace frantic::graphics;
using namespace frantic::geometry;
using namespace frantic::particles::streams;
using namespace frantic::max3d::particles::streams;

struct prt_source_validator {
    static BOOL Validate( PB2Value& v ) {
        INode* nodeObj = dynamic_cast<INode*>( v.r );
        if( !nodeObj ) {
            return FALSE;
        }
        const ObjectState os = nodeObj->EvalWorldState( GetCOREInterface()->GetTime() );
        return static_cast<IMaxKrakatoaPRTSource*>( os.obj->GetInterface( IMaxKrakatoaPRTSource_ID ) ) != NULL;
    }
};

static frantic::max3d::particles::list_or_particle_system_validator<prt_source_validator>
    s_validator( std::vector<frantic::max3d::particles::particle_system_type>(), true );

#define DEFAULT_PARTICLE_GROUP_FILTER_MODE ( PARTICLE_GROUP_FILTER_MODE::ALL )

// find the referring inodes which support ParticleGroupInterface
void extract_particle_groups( INode* node, std::set<INode*>& outGroups );
bool is_node_particle_flow( INode* node );

// get thinkingParticles groups
void extract_tp_groups( INode* node, std::set<ReferenceTarget*>& outGroups );

class redirect_stream_in_scope {
    std::basic_ostream<frantic::tchar>* m_stream;
    std::basic_streambuf<frantic::tchar>* m_oldBuff;

    redirect_stream_in_scope()
        : m_stream( 0 )
        , m_oldBuff( 0 ) {}

  public:
    redirect_stream_in_scope( std::basic_ostream<frantic::tchar>& stream,
                              std::basic_streambuf<frantic::tchar>* newBuff )
        : m_stream( 0 )
        , m_oldBuff( 0 ) {
        m_oldBuff = stream.rdbuf( newBuff );
        m_stream = &stream;
    }
    ~redirect_stream_in_scope() {
        if( m_stream ) {
            m_stream->rdbuf( m_oldBuff );
        }
    }
};

class prt_source_pb_accessor : public PBAccessor {
  public:
    void Set( PB2Value& v, ReferenceMaker* owner, ParamID id, int tabIndex, TimeValue t );
    void TabChanged( tab_changes changeCode, Tab<PB2Value>* tab, ReferenceMaker* owner, ParamID id, int tabIndex,
                     int count );
};

prt_source_pb_accessor* GetPRTSourcePBAccessor();

void prt_source_pb_accessor::Set( PB2Value& v, ReferenceMaker* owner, ParamID id, int tabIndex, TimeValue t ) {
    MaxKrakatoaPRTSourceObject* obj = (MaxKrakatoaPRTSourceObject*)owner;
    if( !obj ) {
        return;
    }
    IParamBlock2* pb = obj->GetParamBlockByID( 0 );
    if( !pb ) {
        return;
    }

    try {
        obj->OnParamSet( v, id, tabIndex, t );
    } catch( std::exception& e ) {
        frantic::tstring errmsg = _T( "PRTSource: Set: " ) + frantic::strings::to_tstring( e.what() ) + _T( "\n" );
        FF_LOG( error ) << errmsg << std::endl;
        LogSys* log = GetCOREInterface()->Log();
        log->LogEntry( SYSLOG_ERROR, NO_DIALOG, _T( "PRTSource Error" ), _T( "%s" ), errmsg.c_str() );
    }
}

void prt_source_pb_accessor::TabChanged( tab_changes changeCode, Tab<PB2Value>* tab, ReferenceMaker* owner, ParamID id,
                                         int tabIndex, int count ) {
    MaxKrakatoaPRTSourceObject* obj = (MaxKrakatoaPRTSourceObject*)owner;
    if( !obj ) {
        return;
    }
    IParamBlock2* pb = obj->GetParamBlockByID( 0 );
    if( !pb ) {
        return;
    }

    try {
        obj->OnTabChanged( changeCode, tab, id, tabIndex, count );
    } catch( std::exception& e ) {
        frantic::tstring errmsg =
            _T( "PRTSource: TabChanged: " ) + frantic::strings::to_tstring( e.what() ) + _T( "\n" );
        FF_LOG( error ) << errmsg << std::endl;
        LogSys* log = GetCOREInterface()->Log();
        log->LogEntry( SYSLOG_ERROR, NO_DIALOG, _T( "PRTSource Error" ), _T( "%s" ), errmsg.c_str() );
    }
}

prt_source_pb_accessor* GetPRTSourcePBAccessor() {
    static prt_source_pb_accessor prtSourcePBAccessor;
    return &prtSourcePBAccessor;
}

class MaxKrakatoaPRTSourceObjectDesc : public ClassDesc2 {
    ParamBlockDesc2* m_pParamDesc;

  public:
    MaxKrakatoaPRTSourceObjectDesc();
    virtual ~MaxKrakatoaPRTSourceObjectDesc();

    int IsPublic() { return TRUE; }
    void* Create( BOOL /*loading*/ ) { return new MaxKrakatoaPRTSourceObject; }
    const TCHAR* ClassName() { return _T( MaxKrakatoaPRTSourceObject_NAME ); }
#if MAX_VERSION_MAJOR >= 24
    const TCHAR* NonLocalizedClassName() { return _T( MaxKrakatoaPRTSourceObject_NAME ); }
#endif
    SClass_ID SuperClassID() { return GEOMOBJECT_CLASS_ID; }
    Class_ID ClassID() { return MaxKrakatoaPRTSourceObject_CLASSID; }
    const TCHAR* Category() { return _T("Krakatoa"); }

    const TCHAR* InternalName() {
        return _T( MaxKrakatoaPRTSourceObject_NAME );
    }                                           // returns fixed parsable name (scripter-visible name)
    HINSTANCE HInstance() { return hInstance; } // returns owning module handle
};

ClassDesc2* GetMaxKrakatoaPRTSourceObjectDesc() {
    static MaxKrakatoaPRTSourceObjectDesc theDesc;
    return &theDesc;
}

namespace {

class MainDlgProc : public ParamMap2UserDlgProc {
  public:
    MainDlgProc() {}
    virtual ~MainDlgProc() {}
    virtual INT_PTR DlgProc( TimeValue t, IParamMap2* map, HWND hWnd, UINT msg, WPARAM wParam, LPARAM lParam );
    virtual void DeleteThis() {}
};

MainDlgProc* GetMainDlgProc();

} // namespace

particle_flow_events_dlg_proc* GetPFlowDialogProc() {
    static particle_flow_events_dlg_proc thePFlowDialogProc;
    return &thePFlowDialogProc;
}

// #if defined(THINKING_PARTICLES_SDK_AVAILABLE)
tp_groups_dlg_proc* GetTPDialogProc() {
    static tp_groups_dlg_proc theTPDialogProc;
    return &theTPDialogProc;
}
// #endif

MaxKrakatoaPRTSourceObjectDesc::MaxKrakatoaPRTSourceObjectDesc() {
    m_pParamDesc = new ParamBlockDesc2( 0,                                                     // Block num
                                        _T("Parameters"),                                      // Internal name
                                        NULL,                                                  // Localized name
                                        this,                                                  // ClassDesc2*
                                        P_AUTO_CONSTRUCT + P_AUTO_UI + P_MULTIMAP + P_VERSION, // Flags
                                        MaxKrakatoaPRTSourceObject_VERSION,
                                        0, // PBlock Ref Num
                                        3, kMainParamRollout, IDD_PRTSOURCE, IDS_PRTSOURCE_ROLLOUT_NAME, 0, 0,
                                        GetMainDlgProc(), // AutoUI stuff for panel 0
                                        kPFLowEventParamRollout, IDD_PARTICLE_GROUPS, IDS_PARTICLE_FLOW_DIALOG_TITLE, 0,
                                        APPENDROLL_CLOSED, GetPFlowDialogProc(), kTPGroupParamRollout,
                                        IDD_PARTICLE_GROUPS, IDS_THINKING_PARTICLES_GROUPS_DIALOG_TITLE, 0,
                                        APPENDROLL_CLOSED, GetTPDialogProc(), p_end );

    //------------------------------------------------------------------------------------------------------------------------------------------------------------------
    // Main rollout parameters
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------
    m_pParamDesc->AddParam( kTargetNode, _T("TargetNode"), TYPE_INODE, 0, 0, p_end );
    m_pParamDesc->ParamOption( kTargetNode, p_validator, &s_validator );
    m_pParamDesc->ParamOption( kTargetNode, p_accessor, GetPRTSourcePBAccessor() );
    m_pParamDesc->ParamOption( kTargetNode, p_ui, kMainParamRollout, TYPE_PICKNODEBUTTON, IDC_PRTSOURCE_TARGETNODE_PICK,
                               p_end );

    m_pParamDesc->AddParam( kViewportDisable, _T("DisableViewport"), TYPE_BOOL, 0, 0, p_end );
    m_pParamDesc->ParamOption( kViewportDisable, p_default, FALSE );
    m_pParamDesc->ParamOption( kViewportDisable, p_ui, kMainParamRollout, TYPE_SINGLECHEKBOX,
                               IDC_PRTSOURCE_DISABLEVIEWPORT_CHECK, p_end );

    m_pParamDesc->AddParam( kIconSize, _T("IconSize"), TYPE_FLOAT, P_RESET_DEFAULT, 0, p_end );
    m_pParamDesc->ParamOption( kIconSize, p_default, 30.f );
    m_pParamDesc->ParamOption( kIconSize, p_range, 0.f, FLT_MAX );
    m_pParamDesc->ParamOption( kIconSize, p_ui, kMainParamRollout, TYPE_SPINNER, EDITTYPE_POS_FLOAT,
                               IDC_PRTSOURCE_ICONSIZE_EDIT, IDC_PRTSOURCE_ICONSIZE_SPIN, SPIN_AUTOSCALE, p_end );

    // Viewport Limits
    m_pParamDesc->AddParam( kViewPercentage, _T( "ViewportPercentage" ), TYPE_PCNT_FRAC, P_ANIMATABLE,
                            IDS_PRTSURFACE_VIEWPORTPERCENTAGE, p_end );
    m_pParamDesc->ParamOption( kViewPercentage, p_default, 100.f );
    m_pParamDesc->ParamOption( kViewPercentage, p_range, 0.f, 100.f );
    m_pParamDesc->ParamOption( kViewPercentage, p_ui, kMainParamRollout, TYPE_SPINNER, EDITTYPE_POS_FLOAT,
                               IDC_PRTSOURCE_VIEWPERCENTAGE_EDIT, IDC_PRTSOURCE_VIEWPERCENTAGE_SPIN, SPIN_AUTOSCALE,
                               p_end );

    m_pParamDesc->AddParam( kViewLimit, _T( "ViewLimit" ), TYPE_FLOAT, P_ANIMATABLE, IDS_PRTSURFACE_VIEWPORTLIMIT,
                            p_end );
    m_pParamDesc->ParamOption( kViewLimit, p_default, 100.f );
    m_pParamDesc->ParamOption( kViewLimit, p_range, 0.f, FLT_MAX );
    m_pParamDesc->ParamOption( kViewLimit, p_ui, kMainParamRollout, TYPE_SPINNER, EDITTYPE_POS_FLOAT,
                               IDC_PRTSOURCE_VIEWLIMIT_EDIT, IDC_PRTSOURCE_VIEWLIMIT_SPIN, SPIN_AUTOSCALE, p_end );

    m_pParamDesc->AddParam( kUseViewLimit, _T( "UseViewLimit" ), TYPE_BOOL, 0, 0, p_end );
    m_pParamDesc->ParamOption( kUseViewLimit, p_default, FALSE );
    m_pParamDesc->ParamOption( kUseViewLimit, p_ui, kMainParamRollout, TYPE_SINGLECHEKBOX,
                               IDC_PRTSOURCE_VIEWLIMIT_CHECK, p_end );

    // Particle Flow Events
    m_pParamDesc->AddParam( kPFEventList, _T( "pfEventList" ), TYPE_INODE_TAB, 0, P_VARIABLE_SIZE, IDS_PFEVENTLIST,
                            p_end );
    m_pParamDesc->ParamOption( kPFEventList, p_accessor, GetPRTSourcePBAccessor() );

    m_pParamDesc->AddParam( kPFEventFilterMode, _T( "pfEventFilterMode" ), TYPE_INT, P_RESET_DEFAULT,
                            IDS_PFEVENTFILTERMODE, p_end );
    m_pParamDesc->ParamOption( kPFEventFilterMode, p_default, DEFAULT_PARTICLE_GROUP_FILTER_MODE );
    m_pParamDesc->ParamOption( kPFEventFilterMode, p_accessor, GetPRTSourcePBAccessor() );
    m_pParamDesc->ParamOption( kPFEventFilterMode, p_ui, kPFLowEventParamRollout, TYPE_RADIO, 2, IDC_FILTER_MODE_ALL,
                               IDC_FILTER_MODE_SELECTED, p_vals, ( PARTICLE_GROUP_FILTER_MODE::ALL ),
                               ( PARTICLE_GROUP_FILTER_MODE::SELECTED ) );

    // Thinking Particles Groups
    m_pParamDesc->AddParam( kTPGroupList, _T( "tpGroupList" ), TYPE_REFTARG_TAB, 0, P_VARIABLE_SIZE, IDS_TPGROUPLIST,
                            p_end );
    m_pParamDesc->ParamOption( kTPGroupList, p_accessor, GetPRTSourcePBAccessor() );

    m_pParamDesc->AddParam( kTPGroupFilterMode, _T( "tpGroupFilterMode" ), TYPE_INT, P_RESET_DEFAULT,
                            IDS_TPGROUPFILTERMODE, p_end );
    m_pParamDesc->ParamOption( kTPGroupFilterMode, p_default, DEFAULT_PARTICLE_GROUP_FILTER_MODE );
    m_pParamDesc->ParamOption( kTPGroupFilterMode, p_accessor, GetPRTSourcePBAccessor() );
    m_pParamDesc->ParamOption( kTPGroupFilterMode, p_ui, kTPGroupParamRollout, TYPE_RADIO, 2, IDC_FILTER_MODE_ALL,
                               IDC_FILTER_MODE_SELECTED, p_vals, ( PARTICLE_GROUP_FILTER_MODE::ALL ),
                               ( PARTICLE_GROUP_FILTER_MODE::SELECTED ) );
}

namespace {

INT_PTR MainDlgProc::DlgProc( TimeValue /*t*/, IParamMap2* /*map*/, HWND hWnd, UINT msg, WPARAM wParam,
                              LPARAM lParam ) {
    switch( msg ) {
    case WM_INITDIALOG:
        GetPFlowDialogProc()->SetMaxKrakatoaPRTSourceObject( NULL );
#if defined( THINKING_PARTICLES_SDK_AVAILABLE )
        GetTPDialogProc()->SetMaxKrakatoaPRTSourceObject( NULL );
#endif
        break;
    case WM_COMMAND: {
        HWND rcvHandle = (HWND)lParam;
        WORD msg = HIWORD( wParam );
        if( rcvHandle == GetDlgItem( hWnd, IDC_PRTSOURCE_TARGETMENU_BUTTON ) ) {
            if( msg == BN_CLICKED ) {
                frantic::max3d::mxs::expression( _T("FranticParticleRenderMXS.OpenPRTSourceOptionsRCMenu()") )
                    .evaluate<void>();
                return TRUE;
            }
        }
    } break;
    case WM_CONTEXTMENU: {
        HWND rcvHandle = (HWND)wParam;
        if( rcvHandle == GetDlgItem( hWnd, IDC_PRTSOURCE_TARGETNODE_PICK ) ) {
            frantic::max3d::mxs::expression( _T("FranticParticleRenderMXS.OpenPRTSourceOptionsRCMenu()") )
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

} // namespace

MaxKrakatoaPRTSourceObjectDesc::~MaxKrakatoaPRTSourceObjectDesc() {
    delete m_pParamDesc;
    m_pParamDesc = NULL;
}

IObjParam* MaxKrakatoaPRTSourceObject::ip;
MaxKrakatoaPRTSourceObject* MaxKrakatoaPRTSourceObject::editObj;

ClassDesc2* MaxKrakatoaPRTSourceObject::GetClassDesc() { return GetMaxKrakatoaPRTSourceObjectDesc(); }

void MaxKrakatoaPRTSourceObject::BeginEditParams( IObjParam* ip, ULONG flags, Animatable* prev ) {
    this->editObj = this;
    this->ip = ip;

    krakatoa::max3d::MaxKrakatoaPRTObjectDisplay<MaxKrakatoaPRTSourceObject>::BeginEditParams( ip, flags, prev );

    GetPFlowDialogProc()->SetMaxKrakatoaPRTSourceObject( this );
#if defined( THINKING_PARTILCES_SDK_AVAILABLE )
    GetTPDialogProc()->SetMaxKrakatoaPRTSourceObject( this );
#endif

    GetPFlowDialogProc()->invalidate_group_list_labels();
#if defined( THINKING_PARTILCES_SDK_AVAILABLE )
    GetTPDialogProc()->invalidate_group_list_labels();
#endif
}

Mesh* MaxKrakatoaPRTSourceObject::GetIconMesh( Matrix3& outTM ) {
    float iconSize = m_pblock->GetFloat( kIconSize );

    outTM.SetScale( Point3( iconSize, iconSize, iconSize ) );
    return GetPRTSourceIconMesh();
}

#if MAX_VERSION_MAJOR >= 25
MaxSDK::SharedMeshPtr MaxKrakatoaPRTSourceObject::GetIconMeshShared( Matrix3& outTM ) {
    float iconSize = m_pblock->GetFloat( kIconSize );

    outTM.SetScale( Point3( iconSize, iconSize, iconSize ) );
    return GetPRTSourceIconMeshShared();
}
#endif

MaxKrakatoaPRTSourceObject::MaxKrakatoaPRTSourceObject()
    : m_canAcceptPFlow( true ) {
    GetMaxKrakatoaPRTSourceObjectDesc()->MakeAutoParamBlocks( this );
}

MaxKrakatoaPRTSourceObject::~MaxKrakatoaPRTSourceObject() {}

void MaxKrakatoaPRTSourceObject::SetIconSize( float size ) { m_pblock->SetValue( kIconSize, 0, size ); }

particle_istream_ptr
MaxKrakatoaPRTSourceObject::GetInternalStream( INode* /*pNode*/, TimeValue t, Interval& inoutValidity,
                                               frantic::max3d::particles::IMaxKrakatoaPRTEvalContextPtr pEvalContext ) {
    CacheInternal( t, m_inRenderMode );

    inoutValidity.SetInstant( t );

    boost::shared_ptr<frantic::particles::streams::particle_istream> pin(
        new frantic::particles::streams::particle_array_particle_istream( m_internalParticles,
                                                                          pEvalContext->GetDefaultChannels() ) );

    return pin;
}

class IMaxKrakatoaPRTSourceStreamAdaptor : public std::streambuf {
    IMaxKrakatoaPRTSource::Stream* m_src;
    pos_type m_streamPos;

  public:
    IMaxKrakatoaPRTSourceStreamAdaptor( IMaxKrakatoaPRTSource::Stream* pSrc )
        : m_src( pSrc ) {}

    ~IMaxKrakatoaPRTSourceStreamAdaptor() { m_src->DeleteThis(); }

    virtual int_type uflow() {
        char result;
        int count;
        do {
            count = m_src->Read( &result, 1 );
            if( count == IMaxKrakatoaPRTSource::Stream::eof )
                return traits_type::eof();
        } while( count < 1 );

        m_streamPos += 1;

        return traits_type::to_int_type( result );
    }

    virtual std::streamsize xsgetn( char_type* _Ptr, std::streamsize _Count ) {
        int result;
        for( result = 0; result < _Count; ) {
            int thisCount = m_src->Read( _Ptr, (int)_Count );
            if( thisCount == IMaxKrakatoaPRTSource::Stream::eof )
                break;
            result += thisCount;
        }

        m_streamPos += result;

        return (std::streamsize)result;
    }

    virtual std::streamsize _Xsgetn_s( char_type* _Ptr, size_t /*_Ptr_size*/, std::streamsize _Count ) {
        return xsgetn( _Ptr, _Count );
    }

    virtual pos_type seekoff( off_type _Off, std::ios_base::seekdir _Way, std::ios_base::openmode _Which ) {
        if( _Which == std::ios_base::in && _Way != std::ios_base::end ) {
            if( _Way == std::ios::beg )
                _Off -= m_streamPos; // Convert absolute position into relative position.

            if( _Off < 0 )
                return pos_type( -1 );

            for( off_type i = 0; i < _Off; ++i ) {
                if( traits_type::eof() == sbumpc() )
                    return m_streamPos;
            }

            return m_streamPos;
        }
        return pos_type( -1 );
    }

    virtual pos_type seekpos( off_type _Off, std::ios_base::openmode _Which ) {
        return seekoff( _Off, std::ios_base::beg, _Which );
    }
};

class MaxKrakatoaPRTSourceParticleIStream : public frantic::particles::streams::particle_istream {
    IMaxKrakatoaPRTSourceStreamAdaptor m_adaptor;
    std::istream m_dataStream;
    frantic::particles::prt_file_header m_prtHeader;
    const frantic::tstring m_name;
    frantic::channels::channel_map m_channelMap;
    boost::int64_t m_index;
    boost::shared_array<char> m_defaultParticle;
    frantic::channels::channel_map_adaptor m_channelAdaptor;

  public:
    MaxKrakatoaPRTSourceParticleIStream( INode* pNode, IMaxKrakatoaPRTSource* pSource, TimeValue t,
                                         Interval& objectValidity )
        : m_adaptor( pSource->CreateStream( t, objectValidity ) )
        , m_dataStream( &m_adaptor )
        , m_index( -1 )
        , m_name( frantic::tstring( _T( "PRTSource<" ) ) + frantic::tstring( pNode->GetName() ) +
                  frantic::tstring( _T( ">" ) ) ) {
        m_prtHeader.set_allow_negative_count( true );
        m_prtHeader.read_header( m_dataStream, pNode->GetName() );
        m_channelMap = m_prtHeader.get_channel_map();
        m_channelAdaptor.set( m_channelMap, m_channelMap );
    }

    virtual void close() {}

    virtual frantic::tstring name() const { return m_name; }

    virtual std::size_t particle_size() const { return m_prtHeader.get_channel_map().structure_size(); }

    virtual boost::int64_t particle_count() const { return m_prtHeader.particle_count(); }

    virtual boost::int64_t particle_index() const { return m_index; }

    virtual boost::int64_t particle_count_left() const {
        if( boost::int64_t pc = particle_count() >= 0 ) {
            return pc - ( m_index + 1 );
        }
        return -1;
    }

    virtual boost::int64_t particle_progress_count() const { return particle_count(); }

    virtual boost::int64_t particle_progress_index() const { return particle_index(); }

    virtual void set_channel_map( const frantic::channels::channel_map& particleChannelMap ) {
        m_channelMap = particleChannelMap;
        m_defaultParticle.reset( new char[m_channelMap.structure_size()] );
        memset( m_defaultParticle.get(), 0, m_channelMap.structure_size() );
        m_channelAdaptor.set( m_channelMap, get_native_channel_map() );
    }

    virtual const frantic::channels::channel_map& get_channel_map() const { return m_channelMap; }

    virtual const frantic::channels::channel_map& get_native_channel_map() const {
        return m_prtHeader.get_channel_map();
    }

    virtual void set_default_particle( char* rawParticleBuffer ) {
        m_defaultParticle.reset( new char[m_channelMap.structure_size()] );
        m_channelMap.copy_structure( m_defaultParticle.get(), rawParticleBuffer );
    }

    virtual bool get_particle( char* rawParticleBuffer ) {
        const std::size_t nativeStructureSize = m_prtHeader.get_channel_map().structure_size();
        boost::scoped_array<char> nativeParticle( new char[nativeStructureSize] );
        m_dataStream.read( nativeParticle.get(), nativeStructureSize );

        m_channelAdaptor.copy_structure( rawParticleBuffer, nativeParticle.get(), m_defaultParticle.get() );
        ++m_index;
        return !m_dataStream.eof();
    }

    virtual bool get_particles( char* rawParticleBuffer, std::size_t& inoutNumParticles ) {
        std::size_t particleSize = m_channelMap.structure_size();
        for( std::size_t i = 0; i < inoutNumParticles; ++i ) {
            if( !get_particle( rawParticleBuffer + i * particleSize ) ) {
                inoutNumParticles = i;
                return false;
            }
        }

        return true;
    }
};

void MaxKrakatoaPRTSourceObject::CacheInternal( TimeValue t, bool /*forRender*/ ) {
    if( m_objectValidity.InInterval( t ) )
        return;

    m_internalBounds.Init();
    m_internalParticles.clear();

    if( !m_inRenderMode && m_pblock->GetInt( kViewportDisable ) )
        return;

    INode* pNode = m_pblock->GetINode( kTargetNode );
    if( !pNode )
        return;

    ObjectState os = pNode->EvalWorldState( t );
    if( !os.obj )
        return;

    try {
        const frantic::graphics::transform4f nodeTM = frantic::max3d::from_max_t( pNode->GetNodeTM( t ) ).to_inverse();
        const frantic::graphics::transform4f nodeTMDeriv =
            ( (float)TIME_TICKSPERSEC / 20.f ) *
            ( nodeTM - frantic::max3d::from_max_t( pNode->GetNodeTM( t + 20 ) ).to_inverse() );
        frantic::channels::channel_map pcm;
        pcm.define_channel( _T( "Position" ), 3, frantic::channels::data_type_float32 );
        pcm.end_channel_definition();
        frantic::particles::particle_istream_ptr pin =
            boost::make_shared<frantic::particles::streams::empty_particle_istream>( pcm );

        if( frantic::max3d::particles::is_particle_istream_source( pNode, t ) ) {
            std::set<INode*> particleGroupNodes;
            extract_particle_groups( pNode, particleGroupNodes );
#if defined( THINKING_PARTICLES_SDK_AVAILABLE )
            if( frantic::max3d::particles::tp_interface::get_instance().is_node_thinking_particles( pNode ) ) {
                FF_LOG( debug ) << "Getting stream from Thinking Particles" << std::endl;
                bool allGroupsFilteredOut = false;
                std::set<ReferenceTarget*> groups;
                extract_tp_groups( pNode, groups );
                if( m_pblock->GetInt( kTPGroupFilterMode ) == PARTICLE_GROUP_FILTER_MODE::SELECTED ) {
                    std::set<ReferenceTarget*> allowlist;
                    for( std::size_t i = 0; i < m_pblock->Count( kTPGroupList ); ++i ) {
                        allowlist.insert( m_pblock->GetReferenceTarget( kTPGroupList, t, static_cast<int>( i ) ) );
                    }
                    std::set<ReferenceTarget*> acceptedGroups;
                    std::set_intersection(
                        groups.begin(), groups.end(), allowlist.begin(), allowlist.end(),
                        std::insert_iterator<std::set<ReferenceTarget*>>( acceptedGroups, acceptedGroups.begin() ) );
                    if( groups.size() > 0 && acceptedGroups.size() == 0 ) {
                        allGroupsFilteredOut = true;
                    }
                    std::swap( groups, acceptedGroups );
                }
                std::vector<boost::shared_ptr<particle_istream>> pins;
                BOOST_FOREACH( ReferenceTarget* group, groups ) {
                    boost::shared_ptr<particle_istream> stream(
                        frantic::max3d::particles::tp_interface::get_instance().get_particle_stream( pcm, pNode, group,
                                                                                                     t ) );
                    stream->set_channel_map( stream->get_native_channel_map() );
                    pins.push_back( stream );
                }
                if( pins.size() == 1 ) {
                    pin = pins[0];
                } else if( pins.size() > 1 ) {
                    pin.reset( new frantic::particles::streams::concatenated_particle_istream( pins ) );
                } else if( allGroupsFilteredOut ) {
                    // Create an empty particle_istream so we don't cause any problems
                    // higher up.
                    // TODO: how should we handle the channel map?  radius, id, etc
                    // would be defined if this was a regular particle flow event
                    frantic::channels::channel_map channelMap = pcm;
                    channelMap.append_channel<boost::int32_t>( _T( "ID" ) );
                    pin.reset( new empty_particle_istream( channelMap, channelMap ) );
                }
                if( !pin && !frantic::max3d::particles::tp_interface::get_instance().is_available() ) {
                    // get_particle_stream() currently throws an exception that explains the problem
                    frantic::max3d::particles::tp_interface::get_instance().get_particle_stream( pcm, pNode, NULL, t );
                    // backup in case get_particle_stream()'s behaviour changes
                    throw std::runtime_error( "Thinking Particles is not loaded, or version is not supported, but it "
                                              "is required to get particles from node: " +
                                              std::string( frantic::strings::to_string( pNode->GetName() ) ) );
                }
            } else
#endif
                if( particleGroupNodes.size() ) {
                FF_LOG( debug ) << "Getting stream from Particle Flow" << std::endl;
                bool allEventsFilteredOut = false;
                if( m_pblock->GetInt( kPFEventFilterMode ) == PARTICLE_GROUP_FILTER_MODE::SELECTED ) {
                    std::set<INode*> allowlist;
                    for( std::size_t i = 0; i < m_pblock->Count( kPFEventList ); ++i ) {
                        allowlist.insert( m_pblock->GetINode( kPFEventList, t, static_cast<int>( i ) ) );
                    }
                    std::set<INode*> acceptedParticleGroupNodes;
                    std::set_intersection( particleGroupNodes.begin(), particleGroupNodes.end(), allowlist.begin(),
                                           allowlist.end(),
                                           std::insert_iterator<std::set<INode*>>(
                                               acceptedParticleGroupNodes, acceptedParticleGroupNodes.begin() ) );
                    if( particleGroupNodes.size() > 0 && acceptedParticleGroupNodes.size() == 0 ) {
                        allEventsFilteredOut = true;
                    }
                    std::swap( particleGroupNodes, acceptedParticleGroupNodes );
                }
                std::vector<boost::shared_ptr<particle_istream>> pins;
                BOOST_FOREACH( INode* particleGroupNode, particleGroupNodes ) {
                    IParticleGroup* particleGroup = GetParticleGroupInterface( particleGroupNode->GetObjectRef() );
                    if( !particleGroup )
                        throw std::runtime_error(
                            "Could not get the Particle Flow IParticleGroup interface from node: " +
                            std::string( frantic::strings::to_string( pNode->GetName() ) ) );

                    redirect_stream_in_scope redirectStreamInScope( frantic::logging::warning,
                                                                    frantic::logging::debug.rdbuf() );
                    boost::shared_ptr<particle_istream> stream(
                        new frantic::max3d::particles::streams::max_pflow_particle_istream( particleGroupNode, t, pcm,
                                                                                            false ) );
                    stream->set_channel_map( stream->get_native_channel_map() );
                    pins.push_back( stream );
                }
                if( pins.size() > 0 ) {
                    pin.reset( new concatenated_particle_istream( pins ) );
                } else if( allEventsFilteredOut ) {
                    // Create an empty particle_istream so we don't cause any problems
                    // higher up.
                    // TODO: how should we handle the channel map?  radius, id, etc
                    // would be defined if this was a regular particle flow event
                    frantic::channels::channel_map channelMap = pcm;
                    channelMap.append_channel<boost::int32_t>( _T( "ID" ) );
                    pin.reset( new empty_particle_istream( channelMap, channelMap ) );
                }
            } else {
                pin = frantic::max3d::particles::max_particle_istream_factory( pNode, pcm, t, GetTicksPerFrame() );
                pin->set_channel_map( pin->get_native_channel_map() );
            }
        } else if( IMaxKrakatoaPRTSource* pSource =
                       static_cast<IMaxKrakatoaPRTSource*>( os.obj->GetInterface( IMaxKrakatoaPRTSource_ID ) ) ) {
            pin.reset( new MaxKrakatoaPRTSourceParticleIStream( pNode, pSource, t, m_objectValidity ) );
        }

        if( !m_inRenderMode ) {
            float viewFraction = std::max( 0.f, std::min( 1.f, m_pblock->GetFloat( kViewPercentage, t ) ) );
            boost::int64_t viewLimit = std::numeric_limits<boost::int64_t>::max();
            const BOOL useViewLimit = static_cast<BOOL>( m_pblock->GetInt( kUseViewLimit ) );
            if( useViewLimit ) {
                const float rawViewLimit = m_pblock->GetFloat( kViewLimit );
                viewLimit = static_cast<boost::int64_t>( std::ceil( 1000 * rawViewLimit ) );
                if( viewLimit < 0 ) {
                    viewLimit = 0;
                }
            }

            if( pin->get_channel_map().has_channel( _T( "ID" ) ) ) {
                pin = boost::make_shared<frantic::particles::streams::fractional_by_id_particle_istream>(
                    pin, viewFraction, _T( "ID" ), viewLimit );
            } else {
                pin = boost::make_shared<frantic::particles::streams::fractional_particle_istream>( pin, viewFraction,
                                                                                                    viewLimit );
            }
        }

        pin = frantic::particles::streams::apply_transform_to_particle_istream( pin, nodeTM, nodeTMDeriv );

        m_internalParticles.reset( pin->get_channel_map() );
        m_internalParticles.insert_particles( pin );

        frantic::channels::channel_accessor<vector3f> posAccessor =
            m_internalParticles.get_channel_map().get_accessor<vector3f>( _T( "Position" ) );
        for( frantic::particles::particle_array::iterator it = m_internalParticles.begin(),
                                                          itEnd = m_internalParticles.end();
             it != itEnd; ++it )
            m_internalBounds += frantic::max3d::to_max_t( posAccessor.get( *it ) );

        m_objectValidity.SetInstant( t );

    } catch( ... ) {
        m_internalBounds.Init();
        m_objectValidity.SetInstant( t );
        m_internalParticles.clear();

        throw;
    }
}

RefResult MaxKrakatoaPRTSourceObject::NotifyRefChanged( const Interval& /*changeInt*/, RefTargetHandle hTarget,
                                                        PartID& partID, RefMessage message, BOOL /*propagate*/ ) {
    if( hTarget == m_pblock ) {
        int param = m_pblock->LastNotifyParamID();

        if( message == REFMSG_CHANGE ) {
            switch( param ) {
            case kTargetNode:
                if( !( partID & PART_GEOM ) ) // Want to avoid changes to random crap like selected and so on.
                    return REF_STOP;
                InvalidateObjectAndViewport();
                break;
            case kUseViewLimit:
            case kViewLimit:
            case kViewPercentage:
                InvalidateObjectAndViewport();
                break;
            case kViewportDisable:
                if( m_inRenderMode ) // Probably don't need to be checking for this...
                    return REF_STOP;
                InvalidateObjectAndViewport();
                break;
            case kIconSize:
                return REF_SUCCEED; // Skip invalidating any cache since its just the icon size changing
            default:
                break;
            }

            InvalidateViewport();
        } else if( message == ( REFMSG_USER + 0x3561 ) && param == kTargetNode ) {
            // This is a message from a MagmaModifier on a PRT Object
            if( !( partID & PART_GEOM ) )
                return REF_STOP;
            InvalidateObjectAndViewport();
        }
    }

    return REF_SUCCEED;
}

#if MAX_VERSION_MAJOR >= 24
const TCHAR* MaxKrakatoaPRTSourceObject::GetObjectName( bool localized ) {
#elif MAX_VERSION_MAJOR >= 15
const TCHAR* MaxKrakatoaPRTSourceObject::GetObjectName() {
#else
TCHAR* MaxKrakatoaPRTSourceObject::GetObjectName() {
#endif
    return const_cast<TCHAR*>( GetClassDesc()->ClassName() );
}

void MaxKrakatoaPRTSourceObject::InitNodeName( MSTR& s ) { s = _T("PRT Source"); }

void MaxKrakatoaPRTSourceObject::GetDeformBBox( TimeValue t, Box3& box, Matrix3* tm, BOOL /*useSel*/ ) {
    try {
        CacheInternal( t, m_inRenderMode );
        box = m_internalBounds;
        if( tm )
            box = box * ( *tm );
    } catch( const std::exception& e ) {
        FF_LOG( error ) << e.what() << std::endl;
    }
}

void MaxKrakatoaPRTSourceObject::OnParamSet( PB2Value& v, ParamID id, int /*tabIndex*/, TimeValue t ) {
    switch( id ) {
    case kPFEventFilterMode:
    case kTPGroupFilterMode:
        InvalidateObjectAndViewport();
        break;
    case kPFEventList:
    case kTPGroupList:
        OnTabChanged( PBAccessor::tab_changes::tab_append, NULL, id, 0, 0 ); // Only the id parameter maters here
        break;
    }
}

void MaxKrakatoaPRTSourceObject::OnTabChanged( PBAccessor::tab_changes /*changeCode*/, Tab<PB2Value>* /*tab*/,
                                               ParamID id, int /*tabIndex*/, int /*count*/ ) {
    switch( id ) {
    case kPFEventList: {
        IParamMap2* pm = m_pblock->GetMap( kPFLowEventParamRollout );
        if( pm ) {
            HWND hwnd = pm->GetHWnd();
            GetPFlowDialogProc()->InvalidateUI( hwnd, id );
        }
        InvalidateObjectAndViewport();
        break;
    }

#if defined( THINKING_PARTICLES_SDK_AVAILABLE )
    case kTPGroupList: {
        IParamMap2* pm = m_pblock->GetMap( kTPGroupParamRollout );
        if( pm ) {
            HWND hwnd = pm->GetHWnd();
            GetTPDialogProc()->InvalidateUI( hwnd, id );
        }
        InvalidateObjectAndViewport();
        break;
    }
#endif
    }
}

void MaxKrakatoaPRTSourceObject::AddParticleFlowEvent( INode* node ) {
    if( m_pblock && IsAcceptablePFlowEvent( node ) ) {
        m_pblock->Append( kPFEventList, 1, &node );
    }
}

void MaxKrakatoaPRTSourceObject::AddTPGroup( INode* node, ReferenceTarget* group ) {
#if defined( THINKING_PARTICLES_SDK_AVAILABLE )
    if( m_pblock && IsAcceptableTPGroup( node, group ) ) {
        m_pblock->Append( kTPGroupList, 1, &group );
    }
#endif
}

bool MaxKrakatoaPRTSourceObject::IsAcceptablePFlowEvent( INode* node ) {
    if( node ) {
        Object* obj = node->GetObjectRef();
        if( obj ) {
            if( IParticleGroup* pGroup = ParticleGroupInterface( obj ) ) {
                int size = m_pblock->Count( kPFEventList );
                for( std::size_t i = 0; i < size; ++i ) {
                    if( node == m_pblock->GetINode( kPFEventList, static_cast<int>( i ) ) ) {
                        return false;
                    }
                }
                return true;
            }
        }
    }
    return false;
}

#if defined( THINKING_PARTICLES_SDK_AVAILABLE )
bool MaxKrakatoaPRTSourceObject::IsAcceptableTPGroup( INode* node, ReferenceTarget* group ) {
    if( !node || !group ) {
        return false;
    }
    if( !frantic::max3d::particles::tp_interface::get_instance().is_node_thinking_particles( node ) ) {
        return false;
    }
    // TODO : check group's class
    std::vector<ReferenceTarget*> tpGroupList;
    int size = m_pblock->Count( kTPGroupList );

    for( std::size_t i = 0; i < size; ++i ) {
        if( group == m_pblock->GetReferenceTarget( kTPGroupList, static_cast<int>( i ) ) ) {
            return false;
        }
    }
    return true;
}
#endif

void MaxKrakatoaPRTSourceObject::GetAllParticleFlowEvents( std::vector<INode*>& out ) {
    out.clear();
    std::set<INode*> particleGroupSet;

    extract_connected_particle_groups( m_pblock->GetINode( kTargetNode ), particleGroupSet );

    out.reserve( particleGroupSet.size() );
    BOOST_FOREACH( INode* particleGroup, particleGroupSet ) {
        out.push_back( particleGroup );
    }
}

void MaxKrakatoaPRTSourceObject::ClearParticleFlowEvents() {
    if( !m_pblock ) {
        return;
    }
    m_pblock->ZeroCount( kPFEventList );
}

void MaxKrakatoaPRTSourceObject::RemoveParticleFlowEvents( const std::vector<int>& indicesIn ) {
    if( !m_pblock ) {
        return;
    }
    std::vector<int> indexList( indicesIn.begin(), indicesIn.end() );
    std::sort( indexList.begin(), indexList.end(), std::greater<int>() );
    BOOST_FOREACH( int index, indexList ) {
        if( index >= 0 && static_cast<std::size_t>( index ) < m_pblock->Count( kPFEventList ) ) {
            m_pblock->Delete( kPFEventList, index, 1 );
        }
    }
}

void MaxKrakatoaPRTSourceObject::GetParticleFlowEventNames( std::vector<frantic::tstring>& eventNames ) {
    eventNames.clear();
    if( !m_pblock ) {
        return;
    }
    for( std::size_t i = 0, ie = m_pblock->Count( kPFEventList ); i < ie; ++i ) {
        INode* node = 0;
        Interval valid;
        BOOL success = m_pblock->GetValue( kPFEventList, GetCOREInterface()->GetTime(), node, valid, (int)i );
        if( success ) {
            if( node ) {
                eventNames.push_back( node->GetName() );
            } else {
                eventNames.push_back( _T( "<deleted>" ) );
            }
        } else {
            eventNames.push_back( _T( "<error>" ) );
        }
    }
}

void MaxKrakatoaPRTSourceObject::GetSelectedParticleFlowEvents( std::vector<INode*>& outEvents ) {
    outEvents.clear();
    if( m_pblock ) {
        const int count = m_pblock->Count( kPFEventList );
        if( count > 0 ) {
            outEvents.reserve( count );
            for( int i = 0; i < count; ++i ) {
                INode* node = 0;
                Interval valid;
                BOOL success = m_pblock->GetValue( kPFEventList, GetCOREInterface()->GetTime(), node, valid, i );
                if( success ) {
                    outEvents.push_back( node );
                }
            }
        }
    }
}

void MaxKrakatoaPRTSourceObject::GetTPGroupNames( std::vector<frantic::tstring>& outGroupNames ) {
    outGroupNames.clear();

#if defined( THINKING_PARTICLES_SDK_AVAILABLE )
    std::vector<tp_group_info> groupInfoList;

    GetSelectedTPGroups( groupInfoList );

    outGroupNames.reserve( groupInfoList.size() );

    BOOST_FOREACH( tp_group_info& groupInfo, groupInfoList ) {
        outGroupNames.push_back( groupInfo.name );
    }
#endif
}

void MaxKrakatoaPRTSourceObject::ClearTPGroups() {
#if defined( THINKING_PARTICLES_SDK_AVAILABLE )
    if( !m_pblock ) {
        return;
    }
    m_pblock->ZeroCount( kTPGroupList );
#endif
}

void MaxKrakatoaPRTSourceObject::RemoveTPGroups( const std::vector<int>& indicesIn ) {
#if defined( THINKING_PARTICLES_SDK_AVAILABLE )
    if( !m_pblock ) {
        return;
    }
    std::vector<int> indexList( indicesIn.begin(), indicesIn.end() );
    std::sort( indexList.begin(), indexList.end(), std::greater<int>() );
    BOOST_FOREACH( int index, indexList ) {
        if( index >= 0 && static_cast<std::size_t>( index ) < m_pblock->Count( kTPGroupList ) ) {
            m_pblock->Delete( kTPGroupList, index, 1 );
        }
    }
#endif
}

void MaxKrakatoaPRTSourceObject::GetSelectedTPGroups( std::vector<tp_group_info>& outGroups ) {
    outGroups.clear();
#if defined( THINKING_PARTICLES_SDK_AVAILABLE )
    if( m_pblock && frantic::max3d::particles::tp_interface::get_instance().is_available() ) {
        TimeValue t = GetCOREInterface()->GetTime();
        std::map<ReferenceTarget*, INode*> groupToNode;
        const int groupCount = m_pblock->Count( kTPGroupList );
        INode* node = m_pblock->GetINode( kTargetNode );
        if( node && groupCount > 0 ) {
            std::vector<ReferenceTarget*> nodeGroups;
            nodeGroups.clear();
            if( frantic::max3d::particles::tp_interface::get_instance().is_node_thinking_particles( node ) ) {
                frantic::max3d::particles::tp_interface::get_instance().get_groups( node, nodeGroups );
                BOOST_FOREACH( ReferenceTarget* group, nodeGroups ) {
                    groupToNode[group] = node;
                }
            }
        }

        if( groupCount > 0 ) {
            outGroups.reserve( groupCount );
            for( int groupIndex = 0; groupIndex < groupCount; ++groupIndex ) {
                ReferenceTarget* group = 0;
                Interval valid;
                BOOL success = m_pblock->GetValue( kTPGroupList, t, group, valid, groupIndex );
                if( success ) {
                    if( group ) {
                        std::map<ReferenceTarget*, INode*>::iterator i = groupToNode.find( group );
                        INode* node = 0;
                        frantic::tstring s;
                        if( i == groupToNode.end() ) {
                            s += _T( "<missing>" );
                        } else {
                            node = i->second;
                            if( node ) {
                                if( node->GetName() ) {
                                    s += frantic::tstring( node->GetName() );
                                } else {
                                    s += _T( "<null>" );
                                }
                            } else {
                                s += _T( "<deleted>" );
                            }
                        }

                        const frantic::tstring groupName =
                            frantic::max3d::particles::tp_interface::get_instance().get_group_name( group );
                        if( groupName.empty() ) {
                            s += _T( "-><empty>" );
                        } else {
                            s += _T( "->" ) + groupName;
                        }

                        outGroups.push_back( tp_group_info( node, group, s ) );
                    } else {
                        outGroups.push_back( tp_group_info( 0, 0, _T( "<deleted>" ) ) );
                    }
                } else {
                    outGroups.push_back( tp_group_info( 0, 0, _T( "<error>" ) ) );
                }
            }
        }
    }
#endif
}

void MaxKrakatoaPRTSourceObject::GetAllTPGroups( std::vector<tp_group_info>& outGroups ) {
    outGroups.clear();
#if defined( THINKING_PARTICLES_SDK_AVAILABLE )
    if( frantic::max3d::particles::tp_interface::get_instance().is_available() ) {
        typedef std::pair<frantic::tstring, ReferenceTarget*> named_group_t;
        struct node_and_name {
            INode* node;
            frantic::tstring name;
            node_and_name( INode* node = 0, const frantic::tstring& name = _T( "<none>" ) )
                : node( node )
                , name( name ) {}
        };
        std::vector<ReferenceTarget*> nodeGroups;
        typedef std::map<ReferenceTarget*, INode*> group_info_t;
        group_info_t groupInfo;
        INode* node = m_pblock->GetINode( kTargetNode );
        if( node ) {
            if( frantic::max3d::particles::tp_interface::get_instance().is_node_thinking_particles( node ) ) {
                nodeGroups.clear();
                frantic::max3d::particles::tp_interface::get_instance().get_groups( node, nodeGroups );
                BOOST_FOREACH( ReferenceTarget* group, nodeGroups ) {
                    groupInfo[group] = node;
                }
            }
        }
        outGroups.reserve( groupInfo.size() );
        for( group_info_t::iterator i = groupInfo.begin(); i != groupInfo.end(); ++i ) {
            outGroups.push_back(
                tp_group_info( i->second, i->first,
                               frantic::max3d::particles::tp_interface::get_instance().get_group_name( i->first ) ) );
        }
    }
#endif
}

MaxKrakatoaPRTSourceObject* MaxKrakatoaPRTSourceObject::GetMaxKrakatoaPRTSource( INode* pNode, TimeValue t ) {
    ObjectState os = pNode->EvalWorldState( t );
    if( !os.obj || os.obj->ClassID() != MaxKrakatoaPRTSourceObject_CLASSID )
        return NULL;

    return reinterpret_cast<MaxKrakatoaPRTSourceObject*>( os.obj );
}

frantic::max3d::particles::particle_system_type MaxKrakatoaPRTSourceObject::GetSourceType( TimeValue t ) const {
    using namespace frantic::max3d::particles;
    INode* node = m_pblock->GetINode( kTargetNode );
    if( node ) {
        const particle_system_type type = get_particle_system_type( node, t );
        if( type == kParticleTypeKrakatoa ) {
            const MaxKrakatoaPRTSourceObject* source = GetMaxKrakatoaPRTSource( node, t );
            if( source ) {
                return source->GetSourceType( t );
            }

            return kParticleTypeKrakatoa;
        }

        return type;
    }

    return kParticleTypeInvalid;
}

#if defined( THINKING_PARTICLES_SDK_AVAILABLE )
void extract_tp_groups( INode* node, std::set<ReferenceTarget*>& outGroups ) {
    if( !node ) {
        throw std::runtime_error( "extract_tp_groups: got a NULL INode." );
    }

    if( frantic::max3d::particles::tp_interface::get_instance().is_node_thinking_particles( node ) ) {
        typedef std::pair<std::string, ReferenceTarget*> named_tp_group;
        std::vector<ReferenceTarget*> groups;
        frantic::max3d::particles::tp_interface::get_instance().get_groups( node, groups );
        BOOST_FOREACH( ReferenceTarget* group, groups ) {
            outGroups.insert( group );
        }
    }
}
#endif

void extract_particle_groups( INode* node, std::set<INode*>& groups ) {
    if( !node ) {
        throw std::runtime_error( "extract_particle_groups: got a NULL INode." );
    }

    Object* nodeObj = node->GetObjectRef();
    // first, make sure this inode has something to do with particles.
    if( nodeObj && GetParticleObjectExtInterface( nodeObj ) ) {
        // try to get the groups from the node.
        std::vector<INode*> inodes;
        frantic::max3d::get_referring_inodes( inodes, node );

        std::vector<INode*>::iterator i = inodes.begin();
        for( ; i != inodes.end(); i++ ) {
            if( *i ) {
                Object* obj = ( *i )->GetObjectRef();
                if( obj ) {
                    if( IParticleGroup* pGroup = ParticleGroupInterface( obj ) ) {
                        groups.insert( *i );
                    }
                }
            }
        }
    }
}

bool is_node_particle_flow( INode* node ) {
    if( !node ) {
        return false;
    }
    Object* obj = node->GetObjectRef();
    if( obj ) {
        IParticleGroup* group = GetParticleGroupInterface( obj );
        if( group ) {
            IPFSystem* particleSystem = PFSystemInterface( group->GetParticleSystem() );
            if( particleSystem ) {
                return true;
            }
        }
    }
    return false;
}