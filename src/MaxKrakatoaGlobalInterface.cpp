// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0

#include "resource.h"
#include "stdafx.h"

#include <boost/assign.hpp>
#include <boost/assign/list_of.hpp>
#include <boost/filesystem/operations.hpp>

#pragma warning( push, 3 )
#pragma warning( disable : 4512 )
#include <boost/scope_exit.hpp>
#pragma warning( pop )

#include "KrakatoaMXVersion.h"
#include "MaxKrakatoa.h"
#include "MaxKrakatoaChannelModifier.h"
#include "MaxKrakatoaGlobalInterface.h"
#include "MaxKrakatoaParticleSources.h"
#include "MaxKrakatoaSceneContext.h"
#include "Misc/MaxKrakatoaMXSParticleStream.h"
#include "Objects/MaxKrakatoaHairObject.h"
#include "Objects/MaxKrakatoaPRTInterface.h"
#include "Objects/MaxKrakatoaPRTLoader.h"
#include "Render Elements/IMaxKrakatoaRenderElement.h"

#include <frantic/channels/channel_map.hpp>
#include <frantic/channels/channel_map_const_iterator.hpp>
#include <frantic/diagnostics/profiling_section.hpp>
#include <frantic/files/filename_sequence.hpp>
#include <frantic/files/paths.hpp>
#include <frantic/graphics2d/size2.hpp>
#include <frantic/graphics2d/spherical_distortion.hpp>
#include <frantic/hashing/blake2_hash.hpp>
#include <frantic/hashing/hashing.hpp>
#include <frantic/logging/logging_level.hpp>
#include <frantic/particles/particle_utilities.hpp>
#include <frantic/particles/streams/prt_particle_istream.hpp>
#include <frantic/particles/streams/realflow_bin_particle_istream.hpp>
#include <frantic/particles/streams/set_channel_particle_istream.hpp>

#include <frantic/max3d/channels/mxs_channel_map.hpp>
#include <frantic/max3d/channels/property_map_interop.hpp>
#include <frantic/max3d/logging/max_progress_logger.hpp>
#include <frantic/max3d/max_utility.hpp>
#include <frantic/max3d/particles/particle_stream_factory.hpp>
#include <frantic/max3d/rendering/renderplugin_utils.hpp>
#include <frantic/max3d/units.hpp>

#include <krakatoa/birth_channel_gen.hpp>
#include <krakatoa/particle_render_element_interface.hpp>

// 3ds Max defines these macros that conflict with
// functions in OpenImageIO
#undef is_array
#undef is_box2
#undef is_box3
#include <OpenImageIO/imageio.h>

using namespace std;
using namespace frantic;
using namespace frantic::particles;
using namespace frantic::particles::streams;
using namespace frantic::graphics;

extern HINSTANCE hInstance;

// temp variable used for testing light filtering
int g_filterRadius = 0; // 0 = disabled, > 0 is the radius of the tent filter to use.

//-------------------------------------
// class ParticleRenderGlobalInterface, Implementation
//	This class exposes a global namespace to Maxscript. It's basically a wrapper that forwards
//	MaxScript requests to a bunch of global functions.
//-------------------------------------

static ParticleRenderGlobalInterface theKrakatoaInterface;
ParticleRenderGlobalInterface* GetMaxKrakatoaInterface() { return &theKrakatoaInterface; }

ParticleRenderGlobalInterface::ParticleRenderGlobalInterface()
    : m_logWindow( _T("Krakatoa Log Window"), 0, 0, true )
    , m_bDoLogPopups( false )
    , m_logFile( GetKrakatoaHome() + _T("KrakatoaTempLog.log") ) {
    FFCreateDescriptor c( this, Interface_ID( 0x757122b, 0x71026b36 ), _T("FranticParticles"), 0 );

    c.add_function( &ParticleRenderGlobalInterface::AddProperty, _T("AddProperty"), _T("PropertyName"), _T("Value") );
    c.add_function( &ParticleRenderGlobalInterface::SetProperty, _T("SetProperty"), _T("PropertyName"), _T("Value") );
    c.add_function( &ParticleRenderGlobalInterface::GetProperty, _T("GetProperty"), _T("PropertyName") );
    c.add_function( &ParticleRenderGlobalInterface::GetIntProperty, _T("GetIntProperty"), _T("PropertyName") );
    c.add_function( &ParticleRenderGlobalInterface::GetFloatProperty, _T("GetFloatProperty"), _T("PropertyName") );
    c.add_function( &ParticleRenderGlobalInterface::GetBoolProperty, _T("GetBoolProperty"), _T("PropertyName") );
    c.add_function( &ParticleRenderGlobalInterface::HasProperty, _T("HasProperty"), _T("PropertyName") );

    c.add_property( &ParticleRenderGlobalInterface::GetRenderOutputFiles, _T("RenderOutputFiles") );
    // c.add_function( &ParticleRenderGlobalInterface::SaveMatteObjectsToFileSequence,
    // _T("SaveMatteObjectsToFileSequence"), _T("Filename"), _T("ObjectArray"), _T("StartFrame"), _T("EndFrame") );
    c.add_function( &ParticleRenderGlobalInterface::InvalidateParticleCache, _T("InvalidateParticleCache") );
    c.add_function( &ParticleRenderGlobalInterface::InvalidateLightingCache, _T("InvalidateLightingCache") );
    c.add_function( &ParticleRenderGlobalInterface::GetCacheSize, _T("GetCacheSize") );

    c.add_function( &ParticleRenderGlobalInterface::GetPRTObjectIStream, _T("GetPRTObjectIStream"), _T("PRTObject"),
                    _T("InWorldSpace"), _T("ApplyMtl") );
    c.add_function( &ParticleRenderGlobalInterface::CreateParticleOStream, _T("CreateParticleOStream"), _T("Filename"),
                    _T("Channels") );
    c.add_function( &ParticleRenderGlobalInterface::SaveParticleObjectsToFile, _T("SaveParticleObjectsToFile"),
                    _T("Nodes"), _T("Filename"), _T("Channels") );
    c.add_function( &ParticleRenderGlobalInterface::GetParticleObjectChannels, _T( "GetParticleObjectChannels" ),
                    _T( "Nodes" ) );
    c.add_function( &ParticleRenderGlobalInterface::get_particle_count, _T("GetParticleCount"), _T("Node"),
                    _T("UseRenderParticles") );
    const std::vector<frantic::strings::tstring> stickyChannelParams =
        boost::assign::list_of( _T("InSequence") )( _T("OutSequence") )( _T("InChannel") )( _T("OutChannel") )(
            _T("IdChannel") )( _T("StartFrame") )( _T("IgnoreError") )( _T("OverwriteChannel") )( _T("OverwriteFile") );
    c.add_function( &ParticleRenderGlobalInterface::generate_sticky_channels, _T("GenerateStickyChannels"),
                    stickyChannelParams );

    c.add_function( &ParticleRenderGlobalInterface::ReplaceSequenceNumberWithHashes,
                    _T("ReplaceSequenceNumberWithHashes"), _T("FileName") );
    c.add_function( &ParticleRenderGlobalInterface::ReplaceSequenceNumber, _T("ReplaceSequenceNumber"), _T("FileName"),
                    _T("Frame") );
    c.add_function( &ParticleRenderGlobalInterface::MakePartitionFilename, _T("MakePartitionFilename"), _T("Filename"),
                    _T("Index"), _T("Count") );
    c.add_function( &ParticleRenderGlobalInterface::GetPartitionFromFilename, _T("GetPartitionFromFilename"),
                    _T("Filename") );
    c.add_function( &ParticleRenderGlobalInterface::ReplacePartitionInFilename, _T("ReplacePartitionInFilename"),
                    _T("Filename"), _T("Index") );
    c.add_function( &ParticleRenderGlobalInterface::get_file_particle_channels, _T("GetFileParticleChannels"),
                    _T("File") );
    c.add_function( &ParticleRenderGlobalInterface::get_file_particle_count, _T("GetFileParticleCount"), _T("File") );
    c.add_function( &ParticleRenderGlobalInterface::get_render_particle_channels, _T("GetRenderParticleChannels") );
    c.add_function( &ParticleRenderGlobalInterface::get_cached_particle_channels, _T("GetCachedParticleChannels") );
    c.add_function( &ParticleRenderGlobalInterface::get_cached_particle_count, _T("GetCachedParticleCount") );

    c.add_function( &ParticleRenderGlobalInterface::get_file_particle_metadata, _T("GetFileParticleMetadata"),
                    _T("Filename") );

    c.add_function( &ParticleRenderGlobalInterface::is_valid_channel_name, _T("IsValidChannelName"), _T("Name") );
    c.add_function( &ParticleRenderGlobalInterface::is_valid_particle_node, _T("IsValidParticleNode"), _T("Node") );
    c.add_function( &ParticleRenderGlobalInterface::is_valid_matte_node, _T("IsValidMatteNode"), _T("Node") );

    c.add_property( &ParticleRenderGlobalInterface::GetVersion, _T("Version") );
    c.add_property( &ParticleRenderGlobalInterface::GetKrakatoaHome, _T("KrakatoaHome") );
    c.add_function( &ParticleRenderGlobalInterface::Blake2Hash, _T( "Blake2Hash" ), _T( "Input" ) );
#if defined( THINKING_PARTICLES_SDK_AVAILABLE )
    c.add_function( &ParticleRenderGlobalInterface::EnableTPExpertMode, _T("EnableTPExpertMode") );
#endif

    c.add_function( &ParticleRenderGlobalInterface::debug_eval_kcm, _T("DebugEvalKCM"), _T("Node"), _T("Modifier"),
                    _T("TestParticle") );
    c.add_property( &ParticleRenderGlobalInterface::get_max_debug_iterations,
                    &ParticleRenderGlobalInterface::set_max_debug_iterations, _T("MaxDebuggerIterations") );

    c.add_function( &ParticleRenderGlobalInterface::test, _T("Test"), _T("Node") );
    c.add_function( &ParticleRenderGlobalInterface::test_particle_object_ext, _T("TestParticleObjectExt"),
                    _T("Command"), _T("Parameter") );

    c.add_function( &ParticleRenderGlobalInterface::LogError, _T("LogError"), _T("Msg") );
    c.add_function( &ParticleRenderGlobalInterface::LogWarning, _T("LogWarning"), _T("Msg") );
    c.add_function( &ParticleRenderGlobalInterface::LogProgress, _T("LogProgress"), _T("Msg") );
    c.add_function( &ParticleRenderGlobalInterface::LogStats, _T("LogStats"), _T("Msg") );
    c.add_function( &ParticleRenderGlobalInterface::LogDebug, _T("LogDebug"), _T("Msg") );
    c.add_property( &ParticleRenderGlobalInterface::GetPopupLogWindowOnMessage,
                    &ParticleRenderGlobalInterface::SetPopupLogWindowOnMessage, _T("PopupLogWindowOnMessage") );
    c.add_property( &ParticleRenderGlobalInterface::GetLogWindowVisible,
                    &ParticleRenderGlobalInterface::SetLogWindowVisible, _T("LogWindowVisible") );

    c.add_function( &ParticleRenderGlobalInterface::spherical_distortion, _T( "SphericalDistortion" ),
                    _T( "InputFilename" ), _T( "OutputFilename" ), _T( "InputProjection" ), _T( "OutputProjection" ),
                    _T( "InputCubeFaceMapping" ), _T( "OutputCubeFaceMapping" ) );
}

void to_krakatoa_error_log( const MCHAR* szMsg ) { GetMaxKrakatoaInterface()->LogErrorInternal( szMsg ); }

void to_krakatoa_warning_log( const MCHAR* szMsg ) { GetMaxKrakatoaInterface()->LogWarningInternal( szMsg ); }

struct to_krakatoa_log {
    M_STD_STRING m_prefix;

  public:
    to_krakatoa_log( const M_STD_STRING& prefix )
        : m_prefix( prefix ) {}

    void operator()( const MCHAR* szMsg ) { GetMaxKrakatoaInterface()->LogMessageInternal( m_prefix + szMsg ); }
};

void init_notify_proc( void* param, NotifyInfo* /*info*/ ) {
    frantic::win32::log_window* pLogWindow = reinterpret_cast<frantic::win32::log_window*>( param );
    if( pLogWindow )
        pLogWindow->init( hInstance, GetCOREInterface()->GetMAXHWnd() );
}

void ParticleRenderGlobalInterface::InitializeLogging() {
    frantic::logging::debug.rdbuf( frantic::logging::new_ffstreambuf( to_krakatoa_log( _T("DBG: ") ) ) );
    frantic::logging::stats.rdbuf( frantic::logging::new_ffstreambuf( to_krakatoa_log( _T("STS: ") ) ) );
    frantic::logging::progress.rdbuf( frantic::logging::new_ffstreambuf( to_krakatoa_log( _T("PRG: ") ) ) );
    frantic::logging::warning.rdbuf( frantic::logging::new_ffstreambuf( &to_krakatoa_warning_log ) );
    frantic::logging::error.rdbuf( frantic::logging::new_ffstreambuf( &to_krakatoa_error_log ) );

    int result = RegisterNotification( &init_notify_proc, &m_logWindow, NOTIFY_SYSTEM_STARTUP );
    if( !result )
        m_logWindow.init( hInstance, NULL );
}

void ParticleRenderGlobalInterface::LogError( const M_STD_STRING& msg ) {
    if( frantic::logging::is_logging_errors() )
        LogErrorInternal( msg.c_str() );
}

void ParticleRenderGlobalInterface::LogWarning( const M_STD_STRING& msg ) {
    if( frantic::logging::is_logging_warnings() )
        LogWarningInternal( msg.c_str() );
}

void ParticleRenderGlobalInterface::LogProgress( const M_STD_STRING& msg ) {
    if( frantic::logging::is_logging_progress() )
        LogMessageInternal( _T("PRG: ") + msg );
}

void ParticleRenderGlobalInterface::LogStats( const M_STD_STRING& msg ) {
    if( frantic::logging::is_logging_stats() )
        LogMessageInternal( _T("STS: ") + msg );
}

void ParticleRenderGlobalInterface::LogDebug( const M_STD_STRING& msg ) {
    if( frantic::logging::is_logging_debug() )
        LogMessageInternal( _T("DBG: ") + msg );
}

void ParticleRenderGlobalInterface::LogErrorInternal( const MCHAR* szMsg ) {
    // Avoid displaying empty messages. This is used in places to prevent the log window from popping up.
    if( *szMsg != '\0' ) {
        if( m_bDoLogPopups && !m_logWindow.is_visible() )
            m_logWindow.show();
        m_logWindow.log( M_STD_STRING( _T("ERR: ") ) + szMsg );

        if( LogSys* theLog = GetCOREInterface()->Log() )
            theLog->LogEntry( SYSLOG_ERROR, FALSE, _T("Krakatoa"), _T("%s"), szMsg );

        // if( std::cerr.rdbuf() != frantic::logging::error.rdbuf() )
        //	std::cerr << _T("ERR: ") << szMsg;

        // TODO: Add file-based logging
    }
}

void ParticleRenderGlobalInterface::LogWarningInternal( const MCHAR* szMsg ) {
    // Avoid displaying empty messages. This is used in places to prevent the log window from popping up.
    if( *szMsg != '\0' ) {
        if( m_bDoLogPopups && !m_logWindow.is_visible() )
            m_logWindow.show();
        m_logWindow.log( M_STD_STRING( _T("WRN: ") ) + szMsg );

        if( LogSys* theLog = GetCOREInterface()->Log() )
            theLog->LogEntry( SYSLOG_WARN, FALSE, _T("Krakatoa"), _T("%s"), szMsg );

        // if( std::cout.rdbuf() != frantic::logging::warning.rdbuf() )
        //	std::cout << _T("WRN: ") << szMsg;

        // TODO: Add file-based logging
    }
}

void ParticleRenderGlobalInterface::LogMessageInternal( const M_STD_STRING& msg ) { m_logWindow.log( msg ); }

bool ParticleRenderGlobalInterface::GetPopupLogWindowOnMessage() { return m_bDoLogPopups; }

void ParticleRenderGlobalInterface::SetPopupLogWindowOnMessage( bool shouldPopup ) { m_bDoLogPopups = shouldPopup; }

bool ParticleRenderGlobalInterface::GetLogWindowVisible() { return m_logWindow.is_visible(); }

void ParticleRenderGlobalInterface::SetLogWindowVisible( bool visible ) { m_logWindow.show( visible ); }

void ParticleRenderGlobalInterface::SetProperty( const M_STD_STRING& propName, Value* value ) {
    if( value->is_kind_of( class_tag( Undefined ) ) ) {
        GetMaxKrakatoa()->erase_property( propName );
    } else if( value->is_kind_of( class_tag( Integer ) ) ) {
        GetMaxKrakatoa()->set_property( propName, value->to_int() );
    } else if( value->is_kind_of( class_tag( Float ) ) ) {
        GetMaxKrakatoa()->set_property( propName, value->to_float() );
    } else if( value->is_kind_of( class_tag( Boolean ) ) ) {
        GetMaxKrakatoa()->set_property( propName, value->to_bool() != 0 );
    } else {
        GetMaxKrakatoa()->set_property( propName, M_STD_STRING( value->to_string() ) );
    }
}

void ParticleRenderGlobalInterface::AddProperty( const M_STD_STRING& propName, Value* value ) {
    GetMaxKrakatoa()->add_property( propName );
    SetProperty( propName, value );
}

Value* ParticleRenderGlobalInterface::GetProperty( const M_STD_STRING& propName ) {
    // Get the property directly, or let the get() function throw if it's not a valid property name
    if( GetMaxKrakatoa()->properties().exists( propName ) ||
        !GetMaxKrakatoa()->properties().valid_property_name( propName ) ) {
        return new String( const_cast<MCHAR*>( GetMaxKrakatoa()->properties().get( propName ).c_str() ) );
    } else {
        return &undefined;
    }
}

int ParticleRenderGlobalInterface::GetIntProperty( const M_STD_STRING& propName ) {
    return GetMaxKrakatoa()->properties().get_int( propName );
}

float ParticleRenderGlobalInterface::GetFloatProperty( const M_STD_STRING& propName ) {
    return GetMaxKrakatoa()->properties().get_float( propName );
}

bool ParticleRenderGlobalInterface::GetBoolProperty( const M_STD_STRING& propName ) {
    return GetMaxKrakatoa()->properties().get_bool( propName );
}

bool ParticleRenderGlobalInterface::HasProperty( const M_STD_STRING& propName ) {
    return GetMaxKrakatoa()->properties().exists( propName ) ||
           GetMaxKrakatoa()->properties().valid_property_name( propName );
}

//-------------------------------------
// Renderer functions
//-------------------------------------
void ParticleRenderGlobalInterface::InvalidateParticleCache() { GetMaxKrakatoa()->InvalidateParticleCache(); }

void ParticleRenderGlobalInterface::InvalidateLightingCache() { GetMaxKrakatoa()->InvalidateLightingCache(); }

float ParticleRenderGlobalInterface::GetCacheSize() { return GetMaxKrakatoa()->GetCacheSize(); }

M_STD_STRING ParticleRenderGlobalInterface::GetRenderOutputFiles( FPTimeValue t ) {
    return GetMaxKrakatoa()->GetRenderOutputFiles( t );
}

// void ParticleRenderGlobalInterface::SaveMatteObjectsToFileSequence( const M_STD_STRING& filename, Value * value, int
// startFrame, int endFrame )
//{
//	// convert Value * to vector of inodes.
//	if(startFrame > endFrame)
//		throw std::runtime_error("SaveMatteObjectsToFileSequence invalid frame sequence (startFrame >
//endFrame)");
//	// list of inodes built from the Value pointer.
//	std::vector<INode *> objs;
//	frantic::max3d::build_inode_list(value, objs);
//
//	// save the file sequence.
//	GetMaxKrakatoa()->SaveMatteObjectsToFileSequence(filename, objs, startFrame, endFrame);
// }

//-------------------------------------
// Filename Manipulation
//-------------------------------------
M_STD_STRING ParticleRenderGlobalInterface::ReplaceSequenceNumberWithHashes( const M_STD_STRING& file ) {
    frantic::files::filename_pattern fp( file );
    return fp.get_pattern();
}

M_STD_STRING ParticleRenderGlobalInterface::ReplaceSequenceNumber( const M_STD_STRING& file, int frame ) {
    frantic::files::filename_pattern fp( file, frantic::files::FS_REPLACE_LEADING_ZERO );
    return fp[frame];
}

M_STD_STRING ParticleRenderGlobalInterface::MakePartitionFilename( const M_STD_STRING& filename, int index,
                                                                   int count ) {
    M_STD_STRING of = boost::lexical_cast<M_STD_STRING>( count );
    M_STD_STRING part = frantic::strings::zero_pad( index, of.size() );
    M_STD_STRING partitionInfo = _T("_part") + part + _T("of") + of + _T("_");

    return frantic::files::filename_pattern::add_before_sequence_number( filename, partitionInfo );
}

std::vector<int> ParticleRenderGlobalInterface::GetPartitionFromFilename( const M_STD_STRING& filename ) {
    std::vector<int> result;
    try {
        int index = 0, count = 0;
        frantic::files::get_part_from_filename( filename, index, count );
        result.push_back( index );
        result.push_back( count );
    } catch( std::exception& ) {
        result.push_back( 0 );
        result.push_back( 0 );
    }
    return result;
}

M_STD_STRING ParticleRenderGlobalInterface::ReplacePartitionInFilename( const M_STD_STRING& filename, int index ) {
    return files::replace_part_in_filename( filename, index );
}

class scoped_render_begin {
    ReferenceMaker* m_pObj;
    TimeValue m_time;

    static void render_begin_recursive( ReferenceMaker* pMaker, TimeValue t, std::set<ReferenceMaker*>& doneMakers ) {
        if( pMaker && doneMakers.find( pMaker ) == doneMakers.end() ) {
            doneMakers.insert( pMaker );

            pMaker->RenderBegin( t );
            for( int i = 0, iEnd = pMaker->NumRefs(); i < iEnd; ++i )
                render_begin_recursive( pMaker->GetReference( i ), t, doneMakers );
        }
    }

    static void render_end_recursive( ReferenceMaker* pMaker, TimeValue t, std::set<ReferenceMaker*>& doneMakers ) {
        if( pMaker && doneMakers.find( pMaker ) == doneMakers.end() ) {
            doneMakers.insert( pMaker );

            pMaker->RenderEnd( t );
            for( int i = 0, iEnd = pMaker->NumRefs(); i < iEnd; ++i )
                render_end_recursive( pMaker->GetReference( i ), t, doneMakers );
        }
    }

  public:
    scoped_render_begin( ReferenceMaker* pObj, TimeValue t ) {
        m_pObj = pObj;
        m_time = t;

        std::set<ReferenceMaker*> doneObjs;
        render_begin_recursive( pObj, t, doneObjs );
    }

    ~scoped_render_begin() {
        if( m_pObj && !std::uncaught_exception() ) {
            std::set<ReferenceMaker*> doneObjs;
            render_end_recursive( m_pObj, m_time, doneObjs );
        }
    }
};

//-------------------------------------
// Streams
//-------------------------------------
FPInterface* ParticleRenderGlobalInterface::GetPRTObjectIStream( INode* pNode, bool applyTM, bool applyMtl,
                                                                 FPTimeValue t ) {
    if( !pNode )
        return NULL;

    ObjectState os = pNode->EvalWorldState( t );

    IMaxKrakatoaPRTObjectPtr pParticleObj = GetIMaxKrakatoaPRTObject( os.obj );
    if( !pParticleObj )
        return NULL;

    scoped_render_begin scopedRender( os.obj, t );

    frantic::max3d::mxs::frame<1> f;
    frantic::max3d::mxs::local<KrakatoaParticleIStream> pStream( f );

    class MyEvalContext : public IMaxKrakatoaEvalContext {
      public:
        frantic::graphics::camera<float> renderCamera;
        frantic::channels::channel_map map;

        RenderGlobalContext globContext;

        bool doTM;
        bool doMtl;

        mutable frantic::logging::null_progress_logger logger;

        // From IMaxKrakatoaEvalContext
        virtual std::pair<Modifier*, ModContext*> get_eval_endpoint() const {
            return std::pair<Modifier*, ModContext*>( (Modifier*)NULL, (ModContext*)NULL );
        }

        // From IEvalContext
        virtual Class_ID GetContextID() const { return Class_ID( 0, 0 ); }

        virtual bool WantsWorldSpaceParticles() const { return doTM; }

        virtual bool WantsMaterialEffects() const { return doMtl; }

        virtual RenderGlobalContext& GetRenderGlobalContext() const {
            return const_cast<MyEvalContext*>( this )->globContext;
        }

        virtual const frantic::graphics::camera<float>& GetCamera() const { return renderCamera; }

        virtual const frantic::channels::channel_map& GetDefaultChannels() const { return map; }

        virtual frantic::logging::progress_logger& GetProgressLogger() const { return logger; }

        virtual bool GetProperty( const Class_ID& /*propID*/, void* /*pTarget*/ ) const { return false; }
    };

    boost::shared_ptr<MyEvalContext> ctx( new MyEvalContext );

    ctx->map.define_channel<vector3f>( _T("Position") );
    ctx->map.define_channel<vector3f>(
        _T("Color") ); // Need to define this since a color is typically available but not in the native channel map
    ctx->map.define_channel<float>(
        _T("Density") ); // Need to define this since a density is typically available but not in the native channel map
    ctx->map.end_channel_definition();

    frantic::max3d::rendering::initialize_renderglobalcontext( ctx->globContext );
    ctx->globContext.time = t;

    ctx->doTM = applyTM;
    ctx->doMtl = applyMtl;

    M_STD_STRING streamName = M_STD_STRING( pNode->GetName() ) + _T(" at time: ") +
                              boost::lexical_cast<M_STD_STRING>( float( t ) / float( GetTicksPerFrame() ) );

    Interval validInterval = FOREVER;

    boost::shared_ptr<frantic::particles::streams::particle_istream> pin =
        pParticleObj->CreateStream( pNode, validInterval, ctx );

    pin = frantic::max3d::particles::visibility_density_scale_stream_with_inode( pNode, t, pin );

    pin->set_channel_map( pin->get_native_channel_map() );

    return new KrakatoaParticleIStream( pin );
}

FPInterface* ParticleRenderGlobalInterface::CreateParticleOStream( const M_STD_STRING& path,
                                                                   const std::vector<M_STD_STRING>& channels ) {
    frantic::channels::channel_map inMap;
    for( std::vector<M_STD_STRING>::const_iterator it = channels.begin(), itEnd = channels.end(); it != itEnd; ++it ) {
        frantic::tstring::size_type spacePos = it->find_first_of( _T( ' ' ), 0 );
        if( spacePos == frantic::tstring::npos )
            throw MAXException( _T("Invalid channel string") );

        frantic::tstring::size_type typePos = it->find_first_not_of( _T( ' ' ), spacePos );
        if( spacePos == frantic::tstring::npos )
            throw MAXException( _T("Invalid channel string") );

        std::pair<frantic::channels::data_type_t, std::size_t> typeAndArity =
            frantic::channels::channel_data_type_and_arity_from_string( it->substr( typePos ) );

        inMap.define_channel( it->substr( 0, spacePos ), typeAndArity.second, typeAndArity.first );
    }
    inMap.end_channel_definition( 1u, true, true );

    return new KrakatoaParticleOStream( path, inMap );
}

bool ParticleRenderGlobalInterface::SaveParticleObjectsToFile( const std::vector<INode*>& nodes,
                                                               const M_STD_STRING& filename,
                                                               const std::vector<M_STD_STRING>& channels,
                                                               FPTimeValue t ) {
    typedef boost::shared_ptr<frantic::particles::streams::particle_istream> particle_istream_ptr;

    std::set<ReferenceMaker*> refTreeSet;

    for( std::vector<INode*>::const_iterator it = nodes.begin(), itEnd = nodes.end(); it != itEnd; ++it ) {
        if( !( *it ) ) {
            throw MAXException( _T( "Invalid INode" ) );
        }
        frantic::max3d::rendering::refmaker_call_recursive( *it, refTreeSet,
                                                            frantic::max3d::rendering::render_begin_function( t, 0 ) );
    }

#pragma warning( push )
#pragma warning( disable : 4512 )
    BOOST_SCOPE_EXIT( ( &refTreeSet )( t ) ) {
        for( std::set<ReferenceMaker*>::const_iterator it = refTreeSet.begin(), itEnd = refTreeSet.end(); it != itEnd;
             ++it )
            ( *it )->RenderEnd( t );
    }
    BOOST_SCOPE_EXIT_END;
#pragma warning( pop )

    std::vector<boost::shared_ptr<KrakatoaParticleSourceFactory>> factories;

    create_particle_factories( factories );

    std::vector<KrakatoaParticleSource> sources;

    // For each node, apply each factory to it stopping when one of them claims it can handle the node.
    for( std::vector<INode*>::const_iterator it = nodes.begin(), itEnd = nodes.end(); it != itEnd; ++it ) {
        for( std::vector<boost::shared_ptr<KrakatoaParticleSourceFactory>>::const_iterator
                 itFactory = factories.begin(),
                 itFactoryEnd = factories.end();
             itFactory != itFactoryEnd; ++itFactory ) {
            if( ( *itFactory )->Process( *it, t, sources ) )
                break;
        }
    }

    bool useNativeMap = false;
    frantic::channels::channel_map pcm;

    if( !channels.empty() ) {
        for( std::vector<M_STD_STRING>::const_iterator it = channels.begin(), itEnd = channels.end(); it != itEnd;
             ++it ) {
            // std::pair<data_type_t, std::size_t> channel_data_type_and_arity_from_string
            M_STD_STRING::size_type splitPos = it->find_first_of( ' ', 0 );
            if( splitPos == M_STD_STRING::npos )
                throw std::runtime_error( "SaveParticleObjectsToFile() - Channel \"" +
                                          frantic::strings::to_string( *it ) + "\" is not a valid channel" );

            frantic::channels::data_type_t chDataType;
            std::size_t chArity;

            M_STD_STRING chName = it->substr( 0, splitPos );

            boost::tie( chDataType, chArity ) =
                frantic::channels::channel_data_type_and_arity_from_string( it->substr( splitPos + 1 ) );

            if( chDataType == frantic::channels::data_type_invalid || chArity == 0 ||
                !frantic::channels::is_valid_channel_name( chName ) )
                throw std::runtime_error( "SaveParticleObjectsToFile() - Channel \"" +
                                          frantic::strings::to_string( *it ) + "\" is not a valid channel" );

            pcm.define_channel( chName, chArity, chDataType );
        }
        pcm.end_channel_definition( 1 );
    } else {
        useNativeMap = true;

        // Make a default map for the request, but we'll overwrite it later with the native map from the stream.
        pcm.define_channel<frantic::graphics::vector3f>( _T("Position") );
        pcm.end_channel_definition( 1 );
    }

    if( !pcm.has_channel( _T("Position") ) || pcm[_T("Position")].data_type() != frantic::channels::data_type_float32 ||
        pcm[_T("Position")].arity() != 3 )
        throw std::runtime_error(
            "SaveParticleObjectsToFile() - Position channel is required to exist and be float32[3]" );

    MaxKrakatoaRenderGlobalContext globContext;

    MaxKrakatoaSceneContextPtr sceneContext( new MaxKrakatoaSceneContext );
    sceneContext->set_time( TicksToSec( t ) );
    sceneContext->set_render_global_context( &globContext );

    globContext.reset( sceneContext );
    globContext.set_channel_map( pcm );

    std::vector<particle_istream_ptr> pins;

    for( std::vector<KrakatoaParticleSource>::iterator it = sources.begin(), itEnd = sources.end(); it != itEnd;
         ++it ) {
        it->AssertNotLoadingFrom( filename );
        frantic::particles::particle_istream_ptr pin = it->GetParticleStream( &globContext );
        if( pin->get_native_channel_map().has_channel( _T( "Density" ) ) ||
            ( !useNativeMap && !pin->get_channel_map().has_channel( _T( "Density" ) ) ) ) {
            pins.push_back( pin );
        } else {
            pins.push_back( frantic::particles::particle_istream_ptr(
                new frantic::particles::streams::set_channel_particle_istream<float>( pin, _T( "Density" ), 1.f ) ) );
        }
    }

    if( pins.empty() )
        return false;

    particle_istream_ptr stream;

    if( pins.size() == 1 )
        stream = pins.back();
    else
        stream.reset( new frantic::particles::streams::concatenated_particle_istream( pins ) );

    if( useNativeMap )
        stream->set_channel_map( stream->get_native_channel_map() );

    frantic::particles::particle_file_stream_factory_object factory;
    factory.set_coordinate_system( frantic::graphics::coordinate_system::right_handed_zup );
    factory.set_length_unit_in_meters( frantic::max3d::get_scale_to_meters() );
    factory.set_frame_rate( GetFrameRate(), 1 );

    boost::shared_ptr<frantic::particles::streams::particle_ostream> pout = factory.create_ostream(
        filename, stream->get_channel_map(), stream->get_channel_map(), stream->particle_count(), -1 );

    frantic::particles::save_particle_stream( stream, pout, frantic::logging::null_progress_logger() );

    return true;
}

std::vector<M_STD_STRING> ParticleRenderGlobalInterface::GetParticleObjectChannels( const std::vector<INode*>& nodes,
                                                                                    FPTimeValue t ) {
    typedef boost::shared_ptr<frantic::particles::streams::particle_istream> particle_istream_ptr;

    std::set<ReferenceMaker*> refTreeSet;

    for( std::vector<INode*>::const_iterator it = nodes.begin(), itEnd = nodes.end(); it != itEnd; ++it ) {
        if( !( *it ) ) {
            throw MAXException( _T( "Invalid INode" ) );
        }
        frantic::max3d::rendering::refmaker_call_recursive( *it, refTreeSet,
                                                            frantic::max3d::rendering::render_begin_function( t, 0 ) );
    }

#pragma warning( push )
#pragma warning( disable : 4512 )
    BOOST_SCOPE_EXIT( ( &refTreeSet )( t ) ) {
        for( std::set<ReferenceMaker*>::const_iterator it = refTreeSet.begin(), itEnd = refTreeSet.end(); it != itEnd;
             ++it )
            ( *it )->RenderEnd( t );
    }
    BOOST_SCOPE_EXIT_END;
#pragma warning( pop )

    std::vector<boost::shared_ptr<KrakatoaParticleSourceFactory>> factories;

    create_particle_factories( factories );

    std::vector<KrakatoaParticleSource> sources;

    // For each node, apply each factory to it stopping when one of them claims it can handle the node.
    for( std::vector<INode*>::const_iterator it = nodes.begin(), itEnd = nodes.end(); it != itEnd; ++it ) {
        for( std::vector<boost::shared_ptr<KrakatoaParticleSourceFactory>>::const_iterator
                 itFactory = factories.begin(),
                 itFactoryEnd = factories.end();
             itFactory != itFactoryEnd; ++itFactory ) {
            if( ( *itFactory )->Process( *it, t, sources ) )
                break;
        }
    }

    frantic::channels::channel_map pcm;
    pcm.define_channel<frantic::graphics::vector3f>( _T("Position") );
    pcm.end_channel_definition( 1 );

    MaxKrakatoaRenderGlobalContext globContext;

    MaxKrakatoaSceneContextPtr sceneContext( new MaxKrakatoaSceneContext );
    sceneContext->set_time( TicksToSec( t ) );
    sceneContext->set_render_global_context( &globContext );

    globContext.reset( sceneContext );
    globContext.set_channel_map( pcm );

    std::vector<particle_istream_ptr> pins;

    for( std::vector<KrakatoaParticleSource>::iterator it = sources.begin(), itEnd = sources.end(); it != itEnd;
         ++it ) {
        frantic::particles::particle_istream_ptr pin = it->GetParticleStream( &globContext );
        if( pin->get_native_channel_map().has_channel( _T( "Density" ) ) ) {
            pins.push_back( pin );
        } else {
            pins.push_back( frantic::particles::particle_istream_ptr(
                new frantic::particles::streams::set_channel_particle_istream<float>( pin, _T( "Density" ), 1.f ) ) );
        }
    }
    if( pins.empty() ) {
        std::vector<M_STD_STRING>();
    }

    particle_istream_ptr stream;

    if( pins.size() == 1 ) {
        stream = pins.back();
    } else {
        stream.reset( new frantic::particles::streams::concatenated_particle_istream( pins ) );
    }

    std::vector<M_STD_STRING> result;
    for( std::size_t i = 0; i < stream->get_native_channel_map().channel_count(); ++i ) {
#if defined( FRANTIC_USE_WCHAR )
        std::wstringstream ss;
#else
        std::stringstream ss;
#endif
        const frantic::channels::channel& channel = stream->get_native_channel_map()[i];
        ss << channel.name() << _T( ' ' ) << channel.type_str();
        result.push_back( ss.str() );
    }

    return result;
}

INT64 ParticleRenderGlobalInterface::get_particle_count( INode* node, bool useRenderParticles, FPTimeValue t ) {
    if( node ) {
        ObjectState os = node->EvalWorldState( t );
        IMaxKrakatoaPRTObjectPtr pParticleObj = GetIMaxKrakatoaPRTObject( os.obj );
        if( pParticleObj ) {
            BaseInterface* baseInterface = pParticleObj->GetInterface( MAXKRAKATOA_PARTICLE_INTERFACE_ID );
            if( baseInterface ) {
                IMaxKrakatoaParticleInterface* particleInterface =
                    static_cast<IMaxKrakatoaParticleInterface*>( baseInterface );
                if( particleInterface ) {
                    KrakatoaParticleStream* stream =
                        particleInterface->create_stream( node, t, FOREVER, true, true, useRenderParticles );
                    BOOST_SCOPE_EXIT( &particleInterface, &stream ) { particleInterface->destroy_stream( stream ); }
                    BOOST_SCOPE_EXIT_END;
                    if( stream ) {
                        const INT64 cachedCount = stream->particle_count();
                        if( cachedCount >= 0 ) {
                            return cachedCount;
                        }

                        INT64 manualCount = 0;
                        const INT64 particleSize = stream->particle_size();
                        boost::scoped_array<char> buffer( new char[particleSize] );
                        while( stream->get_next_particle( buffer.get() ) ) {
                            ++manualCount;
                        }
                        return manualCount;
                    }
                }
            }
        }
    }
    throw std::runtime_error( "Error: invalid particle node" );
}

void ParticleRenderGlobalInterface::generate_sticky_channels(
    const M_STD_STRING& inSequence, const M_STD_STRING& outSequence, const M_STD_STRING& inChannel,
    const M_STD_STRING& outChannel, const M_STD_STRING& idChannel, const float startFrame, const bool ignoreError,
    const bool overwriteChannel, const bool overwriteFile ) {
    birth_channel_gen::options opts;
    opts.m_inSequence = static_cast<frantic::tstring>( inSequence );
    opts.m_outSequence = static_cast<frantic::tstring>( outSequence );
    opts.m_inChannel = static_cast<frantic::tstring>( inChannel );
    opts.m_outChannel = static_cast<frantic::tstring>( outChannel );
    opts.m_idChannel = static_cast<frantic::tstring>( idChannel );
    opts.m_startFrame = startFrame;
    opts.m_ignoreError = ignoreError;
    if( overwriteChannel ) {
        opts.m_overwriteChannel = birth_channel_gen::scope_answer::yes_all;
    } else {
        opts.m_overwriteChannel = birth_channel_gen::scope_answer::no_all;
    }
    if( overwriteFile ) {
        opts.m_overwriteFile = birth_channel_gen::scope_answer::yes_all;
    } else {
        opts.m_overwriteFile = birth_channel_gen::scope_answer::no_all;
    }

    birth_channel_gen::generate_sticky_channels( opts );
}

//-------------------------------------
// Misc.
//-------------------------------------
M_STD_STRING ParticleRenderGlobalInterface::GetVersion() { return _T( FRANTIC_VERSION ); }

// Krakatoa is kept within a max version folder (ie. 3dsmax9Plugin) and then within a platform folder (ie. Win32)
// Example: /3dsmax8Plugin/Win32/
M_STD_STRING ParticleRenderGlobalInterface::GetKrakatoaHome() {
    boost::filesystem::path homePath( win32::GetModuleFileName( hInstance ) );

    return files::ensure_trailing_pathseparator( homePath.parent_path().parent_path().string<M_STD_STRING>() );
}

M_STD_STRING ParticleRenderGlobalInterface::Blake2Hash( const M_STD_STRING& input ) {
    return frantic::strings::to_tstring(
        frantic::hashing::get_hash<frantic::hashing::blake2b_hash>( input.c_str(), sizeof( MCHAR ) * input.size() ) );
}

Value* ParticleRenderGlobalInterface::debug_eval_kcm( INode* pNode, RefTargetHandle theMod, Value* testValues,
                                                      FPTimeValue t ) {
    using namespace frantic::channels;
    using namespace frantic::max3d::channels;

    try {
        if( !is_krakatoa_channel_modifier( theMod ) )
            throw std::runtime_error( "TestKCM() Expected a Krakatoa Channel Modifier as argument 2" );

        frantic::graphics::camera<float> theCamera;

        Interface* pIP = GetCOREInterface();
        ViewExp* pView =
#if MAX_VERSION_MAJOR >= 15
            &pIP->GetActiveViewExp();
#else
            pIP->GetActiveViewport();
#endif

#if MAX_VERSION_MAJOR < 15
        try {
#endif
            if( INode* pCamNode = pView->GetViewCamera() ) {
                theCamera.set_transform( frantic::max3d::from_max_t( pCamNode->GetObjectTM( t ) ) );
            } else if( INode* pLightNode = pView->GetViewSpot() ) {
                theCamera.set_transform( frantic::max3d::from_max_t( pLightNode->GetObjectTM( t ) ) );
            } else {
                Matrix3 viewTM;
                pView->GetAffineTM( viewTM );
                viewTM.Invert();

                theCamera.set_transform( frantic::max3d::from_max_t( viewTM ) );
            }
#if MAX_VERSION_MAJOR < 15
        } catch( ... ) {
            pIP->ReleaseViewport( pView );
            throw;
        }
        pIP->ReleaseViewport( pView );
#endif

        int sizeX = GetCOREInterface()->GetRendWidth();
        int sizeY = GetCOREInterface()->GetRendHeight();

        theCamera.set_output_size( frantic::graphics2d::size2( sizeX, sizeY ) );

        MaxKrakatoaSceneContextPtr sceneContext( new MaxKrakatoaSceneContext );
        sceneContext->set_time( t );
        sceneContext->set_camera( theCamera );

        std::vector<channel_op_node*> theNodes;
        create_kcm_ast_nodes( theNodes, sceneContext, pNode, theMod );

        if( theNodes.size() == 0 )
            throw std::runtime_error( "TestKCM() Got an empty flow" );

        // Build a property map from the input MXS values.
        property_map inProps;
        get_mxs_parameters( testValues, t, false, inProps );

        // Get the output channel's name. The first KCM node should be the output node.
        output_channel_op_node* pOutput = dynamic_cast<output_channel_op_node*>( theNodes[0] );
        if( !pOutput )
            throw std::runtime_error( "TestKCM() Node 1 should be an output node" );

        // Ensure the supplied particle has an initial value for the output node.
        std::string outputName = pOutput->get_channel_name();
        if( !inProps.get_channel_map().has_channel( frantic::strings::to_tstring( outputName ) ) )
            throw std::runtime_error( "TestKCM() Input particle is missing channel: \"" + outputName + "\"" );

        // Set up the compiler's inputs and generate the code for the AST nodes.
        channel_operation_compiler compiler( inProps.get_channel_map(), inProps.get_channel_map() );
        theNodes[0]->compile( theNodes, compiler );

        // TODO: Should enforce compiler.get_channel_map() to be equal to inProps.get_channel_map().

        // Evaluate the compiled code using the property map's data. The const cast is needed
        // because the property map tries to prevent outside users from changing the data, but
        // the output of the evaluation will be stored into one of the values.
        compiler.eval( const_cast<char*>( inProps.get_raw_buffer() ), static_cast<std::size_t>( -1 ) );

        // Extract the output channel value and return it.
        const channel& ch = inProps.get_channel_map()[frantic::strings::to_tstring( outputName )];
        return channel_to_value( ch.get_channel_data_pointer( inProps.get_raw_buffer() ), ch.arity(), ch.data_type() );
    } catch( const std::exception& e ) {
        throw MAXException(
#if MAX_VERSION_MAJOR >= 15
            MSTR::FromACP( e.what() ).data()
#else
            const_cast<MCHAR*>( e.what() ) // Old max versions were not const correct
#endif
        );
    }
}

#if defined( THINKING_PARTICLES_SDK_AVAILABLE )
void ParticleRenderGlobalInterface::EnableTPExpertMode() {
    frantic::max3d::particles::thinking_particles_interface::disable_version_check();
}
#endif

Value* ParticleRenderGlobalInterface::get_file_particle_count( const M_STD_STRING& file ) {
    if( !files::file_exists( file ) )
        return &undefined;

    boost::shared_ptr<particle_istream> pin = frantic::particles::particle_file_istream_factory( file );

    one_typed_value_local( Integer64 * out );
    vl.out = new Integer64( static_cast<INT64>( pin->particle_count() ) );

    return_value( vl.out );
}

Value* ParticleRenderGlobalInterface::get_file_particle_channels( const M_STD_STRING& file ) {
    if( !files::file_exists( file ) )
        return &undefined;

    boost::shared_ptr<particle_istream> pin = frantic::particles::particle_file_istream_factory( file );
    return max3d::channels::get_mxs_channel_map( pin->get_native_channel_map() );
}

Value* ParticleRenderGlobalInterface::get_render_particle_channels() {
    MaxKrakatoa* pKrakatoa = GetMaxKrakatoa();

    frantic::channels::channel_map pcm;

    boost::shared_ptr<krakatoa::krakatoa_shader> pShader( pKrakatoa->GetShader() );
    pShader->define_required_channels( pcm );

    pKrakatoa->GetRenderParticleChannels( pcm );

    krakatoa::scene_context_ptr pSceneContext( new MaxKrakatoaSceneContext );

    IRenderElementMgr* pElemManager = GetCOREInterface()->GetCurRenderElementMgr();
    if( pElemManager && pElemManager->GetElementsActive() ) {

        for( int i = 0, iEnd = pElemManager->NumRenderElements(); i < iEnd; ++i ) {
            IRenderElement* pElem = pElemManager->GetRenderElement( i );
            if( !pElem || !pElem->IsEnabled() )
                continue;

            IMaxKrakatoaRenderElement* pMaxKrakatoaElem =
                static_cast<IMaxKrakatoaRenderElement*>( pElem->GetInterface( IMaxKrakatoaRenderElementID ) );

            if( pMaxKrakatoaElem ) {
                boost::scoped_ptr<krakatoa::render_element_interface> pKrakatoaElem(
                    pMaxKrakatoaElem->get_render_element( pSceneContext ) );
                if( pKrakatoaElem ) {
                    if( krakatoa::particle_render_element_interface* pParticleElem =
                            dynamic_cast<krakatoa::particle_render_element_interface*>( pKrakatoaElem.get() ) )
                        pParticleElem->add_required_channels( pcm );
                }
            }
        }
    }

    pKrakatoa->ApplyChannelDataTypeOverrides( pcm );

    pcm.end_channel_definition();

    return max3d::channels::get_mxs_channel_map( pcm );
}

Value* ParticleRenderGlobalInterface::get_cached_particle_channels() {
    channel_map pcm;
    GetMaxKrakatoa()->GetCachedParticleChannels( pcm );

    return max3d::channels::get_mxs_channel_map( pcm );
}

INT64 ParticleRenderGlobalInterface::get_cached_particle_count() {
    return static_cast<INT64>( GetMaxKrakatoa()->GetCachedParticleCount() );
}

Value* ParticleRenderGlobalInterface::get_file_particle_metadata( const M_STD_STRING& file ) {
    four_typed_value_locals( Array * result, Array * curChannel, Array * curItems, Array * curItem );

    vl.result = new Array( 0 );
    particle_file_stream_factory_object factory;

    frantic::particles::particle_file_metadata metadataObject;
    boost::shared_ptr<frantic::particles::streams::particle_istream> prtFile =
        factory.create_istream( frantic::strings::tstring( file ), &metadataObject );

    frantic::channels::property_map globalProps = metadataObject.get_general_metadata();

    if( !globalProps.empty() ) {
        vl.curItems = new Array( 0 );

        for( frantic::channels::channel_map_const_iterator
                 it = frantic::channels::begin( globalProps.get_channel_map() ),
                 itEnd = frantic::channels::end( globalProps.get_channel_map() );
             it != itEnd; ++it ) {
            vl.curItem = new Array( 2 );
            vl.curItem->append( new String( it->name().c_str() ) );
            vl.curItem->append( frantic::max3d::channels::channel_to_value(
                it->get_channel_data_pointer( globalProps.get_raw_buffer() ), it->arity(), it->data_type() ) );

            vl.curItems->append( vl.curItem );
        }

        vl.curChannel = new Array( 2 );
        vl.curChannel->append( new String( _T("") ) ); // Global data is an empty channel string.
        vl.curChannel->append( vl.curItems );

        vl.result->append( vl.curChannel );
    }

    const frantic::channels::channel_map& nativeMap = prtFile->get_native_channel_map();
    for( frantic::channels::channel_map_const_iterator it = frantic::channels::begin( nativeMap ),
                                                       itEnd = frantic::channels::end( nativeMap );
         it != itEnd; ++it ) {

        const frantic::channels::property_map* props = metadataObject.get_channel_metadata( it->name() );

        if( !props || props->empty() )
            continue;

        vl.curItems = new Array( 0 );

        for( frantic::channels::channel_map_const_iterator
                 itMeta = frantic::channels::begin( props->get_channel_map() ),
                 itMetaEnd = frantic::channels::end( props->get_channel_map() );
             itMeta != itMetaEnd; ++itMeta ) {
            vl.curItem = new Array( 2 );
            vl.curItem->append( new String( itMeta->name().c_str() ) );
            vl.curItem->append( frantic::max3d::channels::channel_to_value(
                itMeta->get_channel_data_pointer( props->get_raw_buffer() ), itMeta->arity(), itMeta->data_type() ) );

            vl.curItems->append( vl.curItem );
        }

        vl.curChannel = new Array( 2 );
        vl.curChannel->append( new String( it->name().c_str() ) );
        vl.curChannel->append( vl.curItems );

        vl.result->append( vl.curChannel );
    }

    return_value( vl.result );
}

bool ParticleRenderGlobalInterface::is_valid_channel_name( const M_STD_STRING& channelName ) {
    return frantic::channels::is_valid_channel_name( channelName );
}

bool ParticleRenderGlobalInterface::is_valid_particle_node( INode* node, FPTimeValue t ) {
    return GetMaxKrakatoa()->is_valid_particle_node( node, t );
}

bool ParticleRenderGlobalInterface::is_valid_matte_node( INode* node, FPTimeValue t ) {
    return GetMaxKrakatoa()->is_valid_matte_node( node, t );
}

bool ParticleRenderGlobalInterface::spherical_distortion( const M_STD_STRING& inputFile, const M_STD_STRING& outputFile,
                                                          int outputWidth, int outputHeight, int inputProjection,
                                                          int outputProjection, int inputCubefaceMapping,
                                                          int outputCubefaceMapping ) {
    static const std::vector<cube_face::cube_face_mapping> cubefaceMappings =
        boost::assign::list_of<cube_face::cube_face_mapping>( cube_face::CROSS_VERTICAL )(
            cube_face::CROSS_HORIZONTAL )( cube_face::RECTANGLE_HORIZONTAL )( cube_face::STRIP_VERTICAL );
    if( inputProjection < 0 || outputProjection < 0 ||
        inputProjection >= static_cast<int>( frantic::graphics2d::last_projection_type ) ||
        outputProjection >= static_cast<int>( frantic::graphics2d::last_projection_type ) ) {
        FF_LOG( error ) << "Invalid projection type." << std::endl;
        return false;
    }
    if( inputCubefaceMapping < 0 || outputCubefaceMapping < 0 || inputCubefaceMapping >= cubefaceMappings.size() ||
        outputCubefaceMapping >= cubefaceMappings.size() ) {
        FF_LOG( error ) << "Invalid cubeface mapping." << std::endl;
        return false;
    }
    OIIO::ImageInput::unique_ptr in = OIIO::ImageInput::open( frantic::strings::to_string( inputFile ) );
    OIIO::ImageOutput::unique_ptr out = NULL;
    if( !in ) {
        return false;
    }
    bool readComplete = false;
    bool outputStarted = false;
    BOOST_SCOPE_EXIT( &in, &out, &readComplete, &outputStarted ) {
        if( !readComplete ) {
            in->close();
        }
        if( outputStarted ) {
            out->close();
        }
    }
    BOOST_SCOPE_EXIT_END;

    const OIIO::ImageSpec& spec = in->spec();
    frantic::graphics2d::openimageio_data imageData( frantic::graphics2d::size2( spec.width, spec.height ),
                                                     spec.nchannels );
    in->read_image( OIIO::TypeDesc::FLOAT, &imageData.m_data[0] );
    in->close();
    readComplete = true;

    frantic::graphics2d::spherical_distortion distortion(
        static_cast<frantic::graphics2d::projection_type>( inputProjection ),
        static_cast<frantic::graphics2d::projection_type>( outputProjection ), cubefaceMappings[inputCubefaceMapping],
        cubefaceMappings[outputCubefaceMapping] );

    frantic::graphics2d::openimageio_data outputData( frantic::graphics2d::size2( outputWidth, outputHeight ),
                                                      spec.nchannels );
    try {
        distortion.do_distortion( imageData, outputData );
    } catch( std::runtime_error& e ) {
        FF_LOG( error ) << e.what() << std::endl;
    }

    out = OIIO::ImageOutput::create( frantic::strings::to_string( outputFile ) );
    if( !out ) {
        return false;
    }
    outputStarted = true;
    OIIO::ImageSpec outSpec( outputWidth, outputHeight, spec.nchannels, OIIO::TypeDesc::FLOAT );
    out->open( frantic::strings::to_string( outputFile ), outSpec );
    out->write_image( OIIO::TypeDesc::FLOAT, &outputData.m_data[0] );
    return true;
}

namespace {
int g_maxDebuggerIterations = 10000;
}

// This global function provides access to the value stored, without exposing it as a global variable.
int GetMaximumDebuggerIterations() { return g_maxDebuggerIterations; }

void ParticleRenderGlobalInterface::set_max_debug_iterations( int maxIterations ) {
    g_maxDebuggerIterations = std::max( maxIterations, 0 );
}

int ParticleRenderGlobalInterface::get_max_debug_iterations() { return g_maxDebuggerIterations; }

void ParticleRenderGlobalInterface::test( INode* /*node*/, FPTimeValue /*t*/ ) {
    // Object* baseObj = node->GetObjectRef();
    // if( !baseObj )
    //	return;

    // ReferenceTarget* targ = baseObj->FindBaseObject();
    // if( !targ )
    //	return;

    ////Workaround for MXS plugins that get in the way.
    // MSPlugin* mxsObj = (MSPlugin*)targ->GetInterface( I_MAXSCRIPTPLUGIN );
    // if( mxsObj )
    //	targ = mxsObj->get_delegate();

    // IMaxKrakatoaPRTObject* prtObj = (IMaxKrakatoaPRTObject*)targ->GetInterface( MAXKRAKATOAPRTOBJECT_INTERFACE );
    // if( prtObj ){
    //	IParticleObjectExt* particleObjectExt = (IParticleObjectExt*)prtObj->GetInterface( PARTICLEOBJECTEXT_INTERFACE
    //); 	if( particleObjectExt ){ 		particleObjectExt->UpdateParticles( node, t );

    //		mprintf( "The IParticleObjectExt interface was acquired for %s\n", node->GetName() );
    //		mprintf( "There were %d particles\n", particleObjectExt->NumParticles() );

    //		struct deref{
    //			inline static Point3 apply( Point3* p ){ return p ? *p : Point3(0,0,0); }
    //		};

    //		for( int i = 0, iEnd = particleObjectExt->NumParticles(); i < iEnd; ++i ){
    //			Point3 pos = deref::apply( particleObjectExt->GetParticlePositionByIndex( i ) );
    //			Point3 vel = deref::apply( particleObjectExt->GetParticleSpeedByIndex( i ) );
    //			Point3 scaleXYZ = deref::apply( particleObjectExt->GetParticleScaleXYZByIndex( i ) );
    //			Point3 orient = deref::apply( particleObjectExt->GetParticleOrientationByIndex( i ) );
    //			float scale = particleObjectExt->GetParticleScaleByIndex( i );
    //			int id = particleObjectExt->GetParticleBornIndex( i );
    //			TimeValue age = particleObjectExt->GetParticleAgeByIndex( i );
    //			TimeValue lifespan = particleObjectExt->GetParticleLifeSpanByIndex( i );

    //			mprintf( "\tIndex: %d, ID: %d, Pos: [%f,%f,%f], Vel: [%f,%f,%f], Orient: [%f,%f,%f], ScaleXYZ: [%f,%f,%f],
    //Scale: %f, Age: %d, Life: %d\n", i, id, pos.x, pos.y, pos.z, vel.x, vel.y, vel.z, orient.x, orient.y, orient.z,
    //scaleXYZ.x, scaleXYZ.y, scaleXYZ.z, scale, age, lifespan );
    //		}
    //	}
    //}
}

void ParticleRenderGlobalInterface::test_particle_object_ext( Object* obj, const M_STD_STRING& command,
                                                              const FPValue& param_, FPTimeValue t ) {
    const FPValue* param = &param_;
    if( param->type == TYPE_FPVALUE )
        param = TYPE_FPVALUE_FIELD( *param );

    if( IParticleObjectExt* pExt = GetParticleObjectExtInterface( obj ) ) {
        if( command == _T("NumParticles") ) {
            mprintf( _T("NumParticles: %d\n"), pExt->NumParticles() );
        } else if( command == _T("UpdateParticles") ) {
            INode* pNode = param ? ( param->type == TYPE_INODE ? TYPE_INODE_FIELD( *param ) : NULL ) : NULL;

            pExt->UpdateParticles( pNode, t );

            mprintf( _T("UpdateParticles: %s @ %d\n"), ( pNode ? pNode->GetName() : _T("<null>") ),
                     static_cast<TimeValue>( t ) );
        }
    }
}

void InitializeKrakatoaLogging() { theKrakatoaInterface.InitializeLogging(); }
