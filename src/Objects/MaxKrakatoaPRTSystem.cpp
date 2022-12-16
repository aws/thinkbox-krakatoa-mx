// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0
#include "stdafx.h"
#ifdef DONTBUILDTHIS
#include "MaxKrakatoa.h"
#include "MaxKrakatoaChannelModifier.h"
#include "MaxKrakatoaMaterial.hpp"
#include "MaxKrakatoaStdMaterialStream.h"
#include "Objects\MaxKrakatoaPRTSystem.h"
#include "resource.h"

#include <frantic/channels/channel_operation_compiler.hpp>
#include <frantic/diagnostics/profiling_section.hpp>
#include <frantic/particles/streams/empty_particle_istream.hpp>
#include <frantic/particles/streams/fractional_particle_istream.hpp>
#include <frantic/particles/streams/particle_array_particle_istream.hpp>
#include <frantic/particles/streams/selection_culled_particle_istream.hpp>
#include <frantic/particles/streams/set_channel_particle_istream.hpp>
#include <frantic/particles/streams/transformed_particle_istream.hpp>

#include <frantic/max3d/geometry/null_view.hpp>
#include <frantic/max3d/max_utility.hpp>
#include <frantic/max3d/particles/streams/deformed_particle_istream.hpp>

#include <custcont.h>
#include <iparamm2.h>

#include <boost/tuple/tuple.hpp>

#include <tbb/blocked_range.h>
#include <tbb/parallel_for.h>

#define MaxKrakatoaPRTSystem_NAME "PRT System"

extern HINSTANCE hInstance;
extern Mesh* GetPRTLoaderIconMesh();

using namespace frantic::graphics;
using namespace frantic::geometry;
using namespace frantic::particles::streams;
using namespace frantic::volumetrics::levelset;
using namespace frantic::max3d::particles::streams;

#pragma warning( disable : 4100 4238 )

frantic::diagnostics::profiling_section psTotal( _T("Total") ), psCompile( _T("Compilation") ),
    psSimulate( _T("Simulation") );

void showProfilingResults() {
    std::basic_stringstream<MCHAR> ss;
    ss << psTotal << _T("\n");
    ss << psCompile << _T("\n");
    ss << psSimulate << _T("\n");
    ss << _T("TBB reports: ") << tbb::task_scheduler_init::default_num_threads() << std::endl;

    MessageBox( NULL, ss.str().c_str(), _T("Results"), MB_OK );
}

void resetProfilingResults() {
    psTotal.reset();
    psCompile.reset();
    psSimulate.reset();
}

class MaxKrakatoaPRTSystemDesc : public ClassDesc2 {
    ParamBlockDesc2* m_pParamDesc;

  public:
    MaxKrakatoaPRTSystemDesc();
    virtual ~MaxKrakatoaPRTSystemDesc();

    int IsPublic() { return TRUE; }
    void* Create( BOOL /*loading*/ ) { return new MaxKrakatoaPRTSystem; }
    const TCHAR* ClassName() { return _T( MaxKrakatoaPRTSystem_NAME ); }
    SClass_ID SuperClassID() { return GEOMOBJECT_CLASS_ID; }
    Class_ID ClassID() { return MaxKrakatoaPRTSystem_CLASSID; }
    const TCHAR* Category() { return _T("Krakatoa"); }

    const TCHAR* InternalName() {
        return _T( MaxKrakatoaPRTSystem_NAME );
    }                                           // returns fixed parsable name (scripter-visible name)
    HINSTANCE HInstance() { return hInstance; } // returns owning module handle
};

ClassDesc2* GetMaxKrakatoaPRTSystemDesc() {
    static MaxKrakatoaPRTSystemDesc theDesc;
    return &theDesc;
}

enum { kSourceFile, kStoredChannels, kStepsPerFrame, kTimeStepSeconds };

class MaxKrakatoaPRTSystemDlgProc : public ParamMap2UserDlgProc {
  public:
    MaxKrakatoaPRTSystemDlgProc();
    virtual ~MaxKrakatoaPRTSystemDlgProc();
    virtual INT_PTR DlgProc( TimeValue t, IParamMap2* map, HWND hWnd, UINT msg, WPARAM wParam, LPARAM lParam );
    virtual void DeleteThis() { /*delete this;*/
    }
};

MaxKrakatoaPRTSystemDlgProc::MaxKrakatoaPRTSystemDlgProc() {}

MaxKrakatoaPRTSystemDlgProc::~MaxKrakatoaPRTSystemDlgProc() {}

INT_PTR MaxKrakatoaPRTSystemDlgProc::DlgProc( TimeValue t, IParamMap2* map, HWND hWnd, UINT msg, WPARAM wParam,
                                              LPARAM lParam ) {
    IParamBlock2* pblock = map->GetParamBlock();
    if( !pblock )
        return FALSE;

    switch( msg ) {
    case WM_INITDIALOG: {
        /*ICustButton* pResultsButton = GetICustButton( GetDlgItem(hWnd, IDC_PRTSYSTEM_RESULTS) );
        pResultsButton->SetType(CBT_PUSH);
        pResultsButton->SetText( "Get Results" );
        ReleaseICustButton(pResultsButton);*/
        return TRUE;
    }
    case WM_COMMAND: {
        WORD msg = HIWORD( wParam );
        if( msg != BN_CLICKED )
            break;
        HWND rcvHandle = (HWND)lParam;
        if( rcvHandle == GetDlgItem( hWnd, IDC_PRTSYSTEM_RESULTS ) ) {
            showProfilingResults();
            resetProfilingResults();
            return TRUE;
        }
        break;
    }
    }

    return FALSE;
}

MaxKrakatoaPRTSystemDlgProc* GetMaxKrakatoaPRTSystemDlgProc() {
    static MaxKrakatoaPRTSystemDlgProc theMaxKrakatoaPRTSystemDlgProc;
    return &theMaxKrakatoaPRTSystemDlgProc;
}

class MaxKrakatoaPRTSystemTimeStepAccessor : public PBAccessor {
    virtual void Get( PB2Value& v, ReferenceMaker* owner, ParamID id, int tabIndex, TimeValue t, Interval& valid );
    virtual void Set( PB2Value& v, ReferenceMaker* owner, ParamID id, int tabIndex, TimeValue t );
    virtual void DeleteThis() { /*Nothing */
        ;
    }
};

void MaxKrakatoaPRTSystemTimeStepAccessor::Get( PB2Value& v, ReferenceMaker* owner, ParamID id, int tabIndex,
                                                TimeValue t, Interval& valid ) {
    if( id == kTimeStepSeconds ) {
        v.f = static_cast<float>(
            1.0 / ( (double)GetFrameRate() * (double)owner->GetParamBlock( 0 )->GetInt( kStepsPerFrame ) ) );
        valid = FOREVER;
    }
}

void MaxKrakatoaPRTSystemTimeStepAccessor::Set( PB2Value& v, ReferenceMaker* owner, ParamID id, int tabIndex,
                                                TimeValue t ) {}

PBAccessor* GetMaxKrakatoaPRTSystemTimeStepAccessor() {
    static MaxKrakatoaPRTSystemTimeStepAccessor theAccessor;
    return &theAccessor;
}

MaxKrakatoaPRTSystemDesc::MaxKrakatoaPRTSystemDesc() {
    m_pParamDesc = new ParamBlockDesc2( 0,                                   // Block num
                                        _T("Parameters"),                    // Internal name
                                        NULL,                                // Localized name
                                        this,                                // ClassDesc2*
                                        P_AUTO_CONSTRUCT + P_AUTO_UI,        // Flags
                                        0,                                   // PBlock Ref Num
                                        IDD_PRTSYSTEM, IDS_PARAMETERS, 0, 0, // AutoUI stuff
                                        GetMaxKrakatoaPRTSystemDlgProc(),    // Custom UI handling
                                        p_end );

    m_pParamDesc->AddParam( kSourceFile, _T("SourceFile"), TYPE_FILENAME, P_RESET_DEFAULT, 0, p_end );
    m_pParamDesc->ParamOption( kSourceFile, p_ui, TYPE_FILEOPENBUTTON, IDC_PRTSYSTEM_FILE_OPEN, p_end );

    m_pParamDesc->AddParam( kStoredChannels, _T("StoredChannels"), TYPE_STRING_TAB, 0,
                            P_RESET_DEFAULT | P_VARIABLE_SIZE, 0, p_end );

    m_pParamDesc->AddParam( kStepsPerFrame, _T("StepsPerFrame"), TYPE_INT, P_RESET_DEFAULT, 0, p_end );
    m_pParamDesc->ParamOption( kStepsPerFrame, p_range, 1, INT_MAX, p_end );
    m_pParamDesc->ParamOption( kStepsPerFrame, p_default, 1, p_end );

    m_pParamDesc->AddParam( kTimeStepSeconds, _T("TimeStep"), TYPE_FLOAT, P_RESET_DEFAULT | P_TRANSIENT | P_READ_ONLY,
                            0, p_end );
    m_pParamDesc->ParamOption( kTimeStepSeconds, p_accessor, GetMaxKrakatoaPRTSystemTimeStepAccessor(), p_end );
}

MaxKrakatoaPRTSystemDesc::~MaxKrakatoaPRTSystemDesc() {
    delete m_pParamDesc;
    m_pParamDesc = NULL;
}

class MaxKrakatoaPRTSystemCreateCallBack : public CreateMouseCallBack {
  public:
    virtual int proc( ViewExp* vpt, int msg, int point, int flags, IPoint2 m, Matrix3& mat );
};

int MaxKrakatoaPRTSystemCreateCallBack::proc( ViewExp* vpt, int msg, int point, int flags, IPoint2 m, Matrix3& mat ) {
    if( msg == MOUSE_POINT || msg == MOUSE_MOVE ) {
        switch( point ) {
        case 0: // only happens with MOUSE_POINT msg
            Point3 p = vpt->SnapPoint( m, m, NULL, SNAP_IN_3D );
            mat.IdentityMatrix();
            mat.SetTrans( p );
            return CREATE_STOP;
        }
        // TODO: handle more clicks
    } else if( msg == MOUSE_FREEMOVE ) {
        vpt->SnapPreview( m, m, NULL, SNAP_IN_3D );
    } else if( msg == MOUSE_ABORT ) {
        return CREATE_ABORT;
    }

    return TRUE;
}

CreateMouseCallBack* MaxKrakatoaPRTSystem::GetCreateMouseCallBack( void ) {
    static MaxKrakatoaPRTSystemCreateCallBack theCallback;
    return &theCallback;
}

MaxKrakatoaPRTSystem::MaxKrakatoaPRTSystem() {
    m_pblock = NULL;
    m_inRenderMode = false;

    m_curSimFrame = TIME_NegInfinity;
    m_initialSimFrame = TIME_NegInfinity;
    m_viewportTime = TIME_NegInfinity;

    GetMaxKrakatoaPRTSystemDesc()->MakeAutoParamBlocks( this );

    frantic::channels::channel_map pcm;
    pcm.define_channel<frantic::graphics::vector3f>( _T("Position") );
    pcm.define_channel<frantic::graphics::vector3f>( _T("Velocity") );
    pcm.end_channel_definition();

    m_particles.reset( pcm );
    m_particlesInitial.reset( pcm );
}

MaxKrakatoaPRTSystem::~MaxKrakatoaPRTSystem() {}

MaxKrakatoaPRTSystem::particle_istream_ptr MaxKrakatoaPRTSystem::GetParticleStream( IEvalContext* /*globContext*/,
                                                                                    INode* /*pNode*/ ) {
    return particle_istream_ptr();
}

/**
 * This class add scope to a vector of pointers, they will be deleted when the object goes
 * out of scope.
 */
template <class T>
class scoped_ptr_vector {
    std::vector<T*> m_data;

  public:
    scoped_ptr_vector() {}

    ~scoped_ptr_vector() { clear(); }

    void clear() {
        for( std::vector<T*>::iterator it = m_data.begin(), itEnd = m_data.end(); it != itEnd; ++it )
            delete *it;
        m_data.clear();
    }

    std::size_t size() { return m_data.size(); }

    operator std::vector<T*>&() { return m_data; }

    T* operator[]( std::size_t i ) { return m_data[i]; }
};

struct parallel_eval {
    frantic::particles::particle_array* m_particles;
    const frantic::channels::channel_map* m_map;
    const std::vector<frantic::channels::channel_operation_compiler>* m_comps;

    parallel_eval( frantic::particles::particle_array& particles, const frantic::channels::channel_map& internalMap,
                   const std::vector<frantic::channels::channel_operation_compiler>& comps ) {
        m_map = &internalMap;
        m_particles = &particles;
        m_comps = &comps;
    }

    void operator()( const tbb::blocked_range<int>& range ) const {
        char* tempBuffer = (char*)_alloca( m_map->structure_size() );
        int baseSize = (int)m_particles->get_channel_map().structure_size();
        int extendedSize = std::max( 0, (int)m_map->structure_size() - baseSize );
        for( int i = range.begin(); i < range.end(); ++i ) {
            char* particle = ( *m_particles )[i];

            memcpy( tempBuffer, particle, baseSize );
            memset( tempBuffer + baseSize, 0, extendedSize );
            for( std::size_t j = 0, jEnd = m_comps->size(); j < jEnd; ++j )
                ( *m_comps )[j].eval( tempBuffer, i );
            memcpy( particle, tempBuffer, baseSize );
        }
    }
};

void MaxKrakatoaPRTSystem::InvalidateSim() {
    m_curSimFrame = TIME_NegInfinity;
    if( !m_inRenderMode )
        InvalidateViewport();
}

void MaxKrakatoaPRTSystem::InvalidateViewport() { m_viewportTime = TIME_NegInfinity; }

void MaxKrakatoaPRTSystem::InvalidateInitialParticles() {
    m_initialSimFrame = TIME_NegInfinity;
    InvalidateSim();
}

// boost::shared_ptr<particle_istream> MaxKrakatoaPRTSystem::GetParticleStream(
//	const frantic::channels::channel_map& pcm,
//	const frantic::max3d::shaders::renderInformation& renderInfo,
//	INode* pNode,
//	bool forRender,
//	TimeValue t,
//	TimeValue timeStep )
//{
//	frantic::diagnostics::scoped_profile spTotal( psTotal );
//
//	if( m_initialSimFrame == TIME_NegInfinity )
//		CacheInitialParticles();
//
//	TimeValue tpf = GetTicksPerFrame();
//	TimeValue targetFrame = (t / tpf);
//
//	//If we are going to a frame before the sim starts, there are no particles.
//	if( targetFrame < m_initialSimFrame ){
//		m_particles.clear();
//		return boost::shared_ptr<particle_istream>( new
//frantic::particles::streams::particle_array_particle_istream( m_particles, pcm ) );
//	}
//
//	//On the first frame, copy the initial particles into the working cache and return
//	if( targetFrame == m_initialSimFrame ){
//		if( m_curSimFrame != m_initialSimFrame ){
//			m_curSimFrame = m_initialSimFrame;
//			m_particles.clear();
//			m_particles.insert_particles( m_particlesInitial.get_channel_map(), m_particlesInitial.begin(),
//m_particlesInitial.end() );
//		}
//		return boost::shared_ptr<particle_istream>( new
//frantic::particles::streams::particle_array_particle_istream( m_particles, pcm ) );
//	}
//
//	//If we are already at or after the correct integration time. This has a side-effect that if the user scrubs
//	//backwards then the sim will do nothing until the scrub past the current cache time, or hit the initial sim
//time. 	if( m_curSimFrame >= targetFrame ) 		return boost::shared_ptr<particle_istream>( new
//frantic::particles::streams::particle_array_particle_istream( m_particles, pcm ) );
//
//	//Otherwise, we need to integrate from m_curSimFrame to targetFrame
//	std::vector<frantic::max3d::particles::modifier_info_t> theMods;
//	frantic::max3d::collect_node_modifiers( pNode, theMods, OSM_CLASS_ID, forRender );
//
//	if( theMods.size() == 0 ){
//		m_curSimFrame = targetFrame;
//		return boost::shared_ptr<particle_istream>( new
//frantic::particles::streams::particle_array_particle_istream( m_particles, pcm ) );
//	}
//
//	std::vector<frantic::channels::channel_operation_compiler> theComps;
//	theComps.resize( theMods.size() );
//
//	scoped_ptr_vector<frantic::channels::channel_op_node> astNodes;
//
//	try{
//		int numSubFrames = m_pblock->GetInt(kStepsPerFrame);
//		for( ; m_curSimFrame < targetFrame; ++m_curSimFrame ){
//			for( int subFrame = 0; subFrame < numSubFrames; ++subFrame ){
//				TimeValue subT = static_cast<TimeValue>( (double)tpf * ((double)subFrame /
//(double)numSubFrames) ); 				TimeValue curT = m_curSimFrame * tpf + subT;
//
//				const frantic::channels::channel_map& originalChannels = m_particles.get_channel_map();
//				frantic::channels::channel_map usedChannels = pcm, availChannels = originalChannels;
//
//				//We are reversing the iteration order here in order to get the modifiers in the
//				//order of application to an object flowing through.
//				std::vector<frantic::max3d::particles::modifier_info_t>::reverse_iterator it =
//theMods.rbegin(), itEnd = theMods.rend();
//
//				psCompile.enter();
//				for( std::size_t i = 0; it != itEnd; ++it, ++i ){
//					//Temp disabled this. Needed if we ever use this code!
//					//create_kcm_ast_nodes( astNodes, pNode, it->first, renderInfo, curT );
//
//					theComps[i].reset( usedChannels, availChannels );
//					if( astNodes.size() > 0 )
//						astNodes[0]->compile( astNodes, theComps[i] );
//					usedChannels = theComps[i].get_channel_map();
//					availChannels = theComps[i].get_native_channel_map();
//
//					astNodes.clear();
//				}
//				psCompile.exit();
//
//				psSimulate.enter();
//#if 1
//				tbb::parallel_for(
//					tbb::blocked_range<int>( 0, (int)m_particles.size(), 1000 ),
//					parallel_eval( m_particles, usedChannels, theComps )
//				);
//#else
//				parallel_eval fn( m_particles, usedChannels, theComps );
//				fn( tbb::blocked_range<int>( 0, (int)m_particles.size() ) );
//#endif
//				psSimulate.exit();
//			}
//		}
//
//	}catch( frantic::channels::channel_compiler_error& e ){
//		MessageBox( NULL, e.what(), "", MB_OK );
//
//		m_particles.clear();
//		m_curSimFrame = targetFrame;
//	}
//
//	return boost::shared_ptr<particle_istream>( new frantic::particles::streams::particle_array_particle_istream(
//m_particles, pcm ) );
// }

void MaxKrakatoaPRTSystem::CacheInitialParticles() {
    frantic::channels::channel_map newPCM;
    newPCM.define_channel<vector3f>( _T("Position") );
    newPCM.define_channel<vector3f>( _T("Velocity") );

    int numChannels = m_pblock->Count( kStoredChannels );
    for( int i = 0; i < numChannels; ++i ) {
        const MCHAR* pChannelDesc = m_pblock->GetStr( kStoredChannels, 0, i );
        if( !pChannelDesc || *pChannelDesc == '\0' )
            continue;

        frantic::tstring descString( pChannelDesc );
        frantic::tstring::size_type spacePos = descString.find( ' ' );
        frantic::tstring chName = descString.substr( 0, spacePos );
        frantic::tstring chType = descString.substr( spacePos + 1 );

        std::pair<frantic::channels::data_type_t, std::size_t> typeInfo =
            frantic::channels::channel_data_type_and_arity_from_string( chType );
        newPCM.define_channel( chName, typeInfo.second, typeInfo.first );
    }
    newPCM.end_channel_definition();

    m_initialSimFrame = 0; // TODO: Make this settable by the user.
    m_particles.reset( newPCM );
    m_particlesInitial.reset( newPCM );

    const MCHAR* pSourceFile = m_pblock->GetStr( kSourceFile );
    if( !pSourceFile || *pSourceFile == _T( '\0' ) )
        return;

    m_particlesInitial.insert_particles(
        frantic::particles::particle_file_istream_factory( pSourceFile, m_particlesInitial.get_channel_map() ) );
}

void MaxKrakatoaPRTSystem::CacheViewportDisplay( INode* pNode, TimeValue t ) {
    if( m_viewportTime == t )
        return;

    try {
        m_viewportTime = t;
        m_viewportCache.clear();
        m_viewportBounds.Init();

        frantic::channels::channel_map pcm;
        pcm.define_channel<vector3f>( _T("Position") );
        pcm.end_channel_definition();

        frantic::channels::channel_accessor<vector3f> posAccessor = pcm.get_accessor<vector3f>( _T("Position") );

        frantic::max3d::shaders::renderInformation ri;

        boost::shared_ptr<particle_istream> pin; // = GetParticleStream(pcm, ri, pNode, false, t, 0);

        char* tempParticle = (char*)_alloca( pcm.structure_size() );
        memset( tempParticle, 0, pcm.structure_size() );

        while( pin->get_particle( tempParticle ) ) {
            vector3f pos = posAccessor.get( tempParticle );
            vector3f col = vector3f( 1, 1, 1 );

            m_viewportBounds += frantic::max3d::to_max_t( pos );

            // Need to clamp viewport colors
            col.x = frantic::math::clamp( col.x, 0.f, 1.f );
            col.y = frantic::math::clamp( col.y, 0.f, 1.f );
            col.z = frantic::math::clamp( col.z, 0.f, 1.f );
            m_viewportCache.push_back( particle_t( pos, col ) );
        }
    } catch( const std::exception& e ) {
        FF_LOG( debug ) << e.what() << std::endl;
        m_viewportCache.clear();
        return;
    }
}

Class_ID MaxKrakatoaPRTSystem::ClassID() { return MaxKrakatoaPRTSystem_CLASSID; }

SClass_ID MaxKrakatoaPRTSystem::SuperClassID() { return GEOMOBJECT_CLASS_ID; }

#if MAX_VERSION_MAJOR >= 15
const
#endif
    TCHAR*
    MaxKrakatoaPRTSystem::GetObjectName() {
    return _T("PRTSystem");
}

void MaxKrakatoaPRTSystem::GetClassName( MSTR& s ) { s = GetMaxKrakatoaPRTSystemDesc()->ClassName(); }

int MaxKrakatoaPRTSystem::NumRefs() { return 1; }

ReferenceTarget* MaxKrakatoaPRTSystem::GetReference( int i ) {
    switch( i ) {
    case 0:
        return m_pblock;
    default:
        return NULL;
    }
}

void MaxKrakatoaPRTSystem::SetReference( int i, ReferenceTarget* r ) {
    switch( i ) {
    case 0:
        m_pblock = (IParamBlock2*)r;
        break;
    }
}

int MaxKrakatoaPRTSystem::NumSubs() { return 1; }

Animatable* MaxKrakatoaPRTSystem::SubAnim( int i ) {
    switch( i ) {
    case 0:
        return m_pblock;
    default:
        return NULL;
    }
}

TSTR MaxKrakatoaPRTSystem::SubAnimName( int i ) {
    switch( i ) {
    case 0:
        return m_pblock->GetLocalName();
    default:
        return _T("");
    }
}

int MaxKrakatoaPRTSystem::NumParamBlocks() { return 1; }

IParamBlock2* MaxKrakatoaPRTSystem::GetParamBlock( int i ) { return ( i == 0 ) ? m_pblock : NULL; }

IParamBlock2* MaxKrakatoaPRTSystem::GetParamBlockByID( BlockID i ) { return ( i == m_pblock->ID() ) ? m_pblock : NULL; }

BaseInterface* MaxKrakatoaPRTSystem::GetInterface( Interface_ID id ) {
    if( id == MAXKRAKATOAPRTOBJECT_INTERFACE )
        return static_cast<IMaxKrakatoaPRTObject*>( this );
    return GeomObject::GetInterface( id );
}

void MaxKrakatoaPRTSystem::BeginEditParams( IObjParam* ip, ULONG flags, Animatable* prev ) {
    GetMaxKrakatoaPRTSystemDesc()->BeginEditParams( ip, this, flags, prev );
}

void MaxKrakatoaPRTSystem::EndEditParams( IObjParam* ip, ULONG flags, Animatable* next ) {
    GetMaxKrakatoaPRTSystemDesc()->EndEditParams( ip, this, flags, next );
}

void MaxKrakatoaPRTSystem::DeleteThis() { delete this; }

// We need to clear the cache when switching to and from render mode, because
// the render and viewport settings are potentially different.
int MaxKrakatoaPRTSystem::RenderBegin( TimeValue t, ULONG flags ) {
    if( flags & RENDERBEGIN_IN_MEDIT )
        return FALSE;
    m_inRenderMode = true;

    std::vector<particle_t>().swap( m_viewportCache );
    m_viewportTime = TIME_NegInfinity;

    return TRUE;
}

// We need to clear the cache when switching to and from render mode, because
// the render and viewport settings are potentially different.
int MaxKrakatoaPRTSystem::RenderEnd( TimeValue t ) {
    if( !m_inRenderMode )
        return FALSE;

    m_inRenderMode = false;
    return TRUE;
}

ReferenceTarget* MaxKrakatoaPRTSystem::Clone( RemapDir& remap ) {
    MaxKrakatoaPRTSystem* pResult = new MaxKrakatoaPRTSystem;
    pResult->ReplaceReference( 0, remap.CloneRef( m_pblock ) );
    BaseClone( this, pResult, remap );
    return pResult;
}

RefResult MaxKrakatoaPRTSystem::NotifyRefChanged( Interval, RefTargetHandle rtarg, PartID&, RefMessage msg ) {
    if( rtarg == m_pblock ) {
        ParamID id = m_pblock->LastNotifyParamID();

        // We don't really care about anything other than change notifications.
        if( msg != REFMSG_CHANGE )
            return REF_DONTCARE;

        // HACK: This appears to get sent if you pick a node, delete it, undo the deletion, then redo
        // the deletion.
        if( id < 0 ) {
            InvalidateInitialParticles();
            return REF_SUCCEED;
        }

        // By default we should propagate messages. Some messages can be safely ignored though, and
        // will improve viewport performance if we do so.
        switch( id ) {
        case kSourceFile:
        case kStoredChannels:
            InvalidateInitialParticles();
            break;
        }

        InvalidateViewport();
        return REF_SUCCEED;
    }
    return REF_SUCCEED;
}

Interval MaxKrakatoaPRTSystem::ObjectValidity( TimeValue t ) { return Interval( t, t ); }

ObjectState MaxKrakatoaPRTSystem::Eval( TimeValue ) { return ObjectState( this ); }

void MaxKrakatoaPRTSystem::WSStateInvalidate() { InvalidateViewport(); }

void MaxKrakatoaPRTSystem::InitNodeName( MSTR& s ) { s = _T("PRT System"); }

void MaxKrakatoaPRTSystem::GetWorldBoundBox( TimeValue t, INode* inode, ViewExp* /*vpt*/, Box3& box ) {
    try {
        // TODO: Should this be modified for when in render mode?
        CacheViewportDisplay( inode, t );

        box = m_viewportBounds;

        Matrix3 iconScaleTM( 1 );
        iconScaleTM.SetScale( Point3( 10.f, 10.f, 10.f ) );
        iconScaleTM = iconScaleTM * inode->GetObjTMBeforeWSM( t );

        box += GetPRTLoaderIconMesh()->getBoundingBox() * iconScaleTM;
    } catch( const std::exception& e ) {
        FF_LOG( error ) << e.what() << std::endl;
    }
}

void MaxKrakatoaPRTSystem::GetLocalBoundBox( TimeValue t, INode* inode, ViewExp* vpt, Box3& box ) {
    try {
        GetWorldBoundBox( t, inode, vpt, box );

        Matrix3 worldToObjectTM = inode->GetObjTMBeforeWSM( t );
        worldToObjectTM.Invert();

        box = box * worldToObjectTM;
    } catch( const std::exception& e ) {
        FF_LOG( error ) << e.what() << std::endl;
    }
}

void MaxKrakatoaPRTSystem::GetDeformBBox( TimeValue t, Box3& box, Matrix3* tm, BOOL useSel ) {
    try {
        box = m_viewportBounds;
        if( tm )
            box = box * ( *tm );
    } catch( const std::exception& e ) {
        FF_LOG( error ) << e.what() << std::endl;
    }
}

int MaxKrakatoaPRTSystem::Display( TimeValue t, INode* inode, ViewExp* pView, int flags ) {
    try {
        if( inode->IsNodeHidden() || inode->GetBoxMode() )
            return TRUE;

        CacheViewportDisplay( inode, t );

        GraphicsWindow* gw = pView->getGW();
        DWORD rndLimits = gw->getRndLimits();

        std::vector<particle_t>::const_iterator it = m_viewportCache.begin();
        std::vector<particle_t>::const_iterator itEnd = m_viewportCache.end();

        Matrix3 tm = inode->GetObjTMBeforeWSM( t );
        tm.Scale( Point3( 10.f, 10.f, 10.f ) );

        gw->setTransform( tm );
        frantic::max3d::draw_mesh_wireframe( gw, GetPRTLoaderIconMesh(),
                                             inode->Selected() ? color3f( 1 )
                                                               : color3f::from_RGBA( inode->GetWireColor() ) );

        tm.IdentityMatrix();
        gw->setTransform( tm );

        gw->startMarkers();
        for( ; it != itEnd; ++it ) {
            Point3 pos = frantic::max3d::to_max_t( it->first );
            gw->setColor( LINE_COLOR, it->second.x, it->second.y, it->second.z );
            gw->marker( &pos, SM_DOT_MRKR );
        }
        gw->endMarkers();

        // Draw the particle count
        frantic::tstring countString = boost::lexical_cast<frantic::tstring>( m_viewportCache.size() );
        gw->setColor( TEXT_COLOR, Color( 1, 1, 1 ) );
        gw->text( &m_viewportBounds.Max(), const_cast<MCHAR*>( countString.c_str() ) );

        gw->setRndLimits( rndLimits );
    } catch( const std::exception& e ) {
        FF_LOG( error ) << frantic::strings::to_tstring( e.what() ) << std::endl;
        return FALSE;
    }

    return TRUE;
}

int MaxKrakatoaPRTSystem::HitTest( TimeValue t, INode* inode, int type, int crossing, int flags, IPoint2* p,
                                   ViewExp* vpt ) {
    try {
        CacheViewportDisplay( inode, t );

        GraphicsWindow* gw = vpt->getGW();
        DWORD rndLimits = gw->getRndLimits();

        if( ( ( flags & HIT_SELONLY ) && !inode->Selected() ) || gw == NULL || inode == NULL )
            return 0;

        HitRegion hitRegion;
        MakeHitRegion( hitRegion, type, crossing, 4, p );

        gw->setRndLimits( GW_PICK | GW_WIREFRAME );
        gw->setHitRegion( &hitRegion );
        gw->clearHitCode();

        std::vector<particle_t>::const_iterator it = m_viewportCache.begin();
        std::vector<particle_t>::const_iterator itEnd = m_viewportCache.end();

        Matrix3 tm = inode->GetObjTMBeforeWSM( t );
        tm.Scale( Point3( 10.f, 10.f, 10.f ) );

        gw->setTransform( tm );
        if( GetPRTLoaderIconMesh()->select( gw, NULL, &hitRegion ) )
            return TRUE;

        tm.IdentityMatrix();
        gw->setTransform( tm );

        gw->startMarkers();
        for( ; it != itEnd; ++it ) {
            Point3 pos = frantic::max3d::to_max_t( it->first );
            gw->marker( &pos, SM_DOT_MRKR );
            if( gw->checkHitCode() )
                return true;
        }
        gw->endMarkers();
        gw->setRndLimits( rndLimits );
    } catch( const std::exception& e ) {
        FF_LOG( error ) << e.what() << std::endl;
        return FALSE;
    }

    return FALSE;
}

Mesh* MaxKrakatoaPRTSystem::GetRenderMesh( TimeValue /*t*/, INode* /*inode*/, View& /*view*/, BOOL& needDelete ) {
    static Mesh* pEmptyMesh = NULL;
    if( !pEmptyMesh )
        pEmptyMesh = new Mesh;

    needDelete = FALSE;
    return pEmptyMesh;
}
#endif