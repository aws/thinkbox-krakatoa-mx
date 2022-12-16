// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0
#include "stdafx.h"

// File birth has been deprecated for a while now, so I'm just going to not include it anymore.
#if MAX_VERSION_MAJOR < 15

#include "resource.h"

#include "PFlow Operators\MaxKrakatoaPFChannelInterface.h"
#include "PFlow Operators\MaxKrakatoaPFFileUpdate.h"

#include <frantic/channels/channel_accessor.hpp>
#include <frantic/files/files.hpp>

#include <autolink_openexr.hpp>
#include <frantic/graphics/vector3f.hpp>
#include <frantic/logging/logging_level.hpp>

#include <frantic/particles/particle_file_stream_factory.hpp>
#include <frantic/particles/streams/fractional_particle_istream.hpp>
#include <frantic/particles/streams/transformed_particle_istream.hpp>

#include <frantic/max3d/geopipe/get_inodes.hpp>
#include <frantic/max3d/particles/particle_stream_factory.hpp>

#include <frantic/files/files.hpp>
#include <frantic/max3d/maxscript/maxscript.hpp>

void* KrakatoaPFFileUpdateDesc::Create( BOOL ) { return new KrakatoaPFFileUpdate; }

INT_PTR KrakatoaPFFileUpdateDesc::Execute( int cmd, ULONG_PTR arg1, ULONG_PTR arg2, ULONG_PTR /*arg3*/ ) {
    TCHAR** res = NULL;
    bool* isPublic;
    HBITMAP* depotIcon;
    HBITMAP* depotMask;
    switch( cmd ) {
    case kPF_GetActionDescription:
        if( arg1 == NULL )
            return 0;
        res = (TCHAR**)arg1;
        *res =
            _T("Loads position and velocity data from a sequence of particle files."); /*GetString(IDS_KrakatoaPFFileUpdate_DESCRIPTION)*/
        ;
        break;
    case kPF_PViewPublic:
        if( arg1 == NULL )
            return 0;
        isPublic = (bool*)arg1;
        *isPublic = false;
        break;
    case kPF_PViewCategory:
        if( arg1 == NULL )
            return 0;
        res = (TCHAR**)arg1;
        *res = _T("Operator");
        break;
    case kPF_PViewDepotIcon:
        if( arg1 == NULL )
            return 0;
        depotIcon = (HBITMAP*)arg1;
        if( arg2 == NULL )
            return 0;
        depotMask = (HBITMAP*)arg2;
        if( m_depotIcon == NULL )
            m_depotIcon = LoadBitmap( hInstance, MAKEINTRESOURCE( IDB_FILEUPDATE_ACTIVE_DEPOT ) );
        if( m_depotMask == NULL )
            m_depotMask = LoadBitmap( hInstance, MAKEINTRESOURCE( IDB_FILEUPDATE_MASK_DEPOT ) );
        *depotIcon = m_depotIcon;
        *depotMask = m_depotMask;
        break;
    default:
        return 0;
    }
    return 1;
}

HBITMAP KrakatoaPFFileUpdateDesc::m_depotIcon = NULL;
HBITMAP KrakatoaPFFileUpdateDesc::m_depotMask = NULL;

ClassDesc2* GetKrakatoaPFFileUpdateDesc() {
    static KrakatoaPFFileUpdateDesc theKrakatoaPFFileUpdateDesc;
    return &theKrakatoaPFFileUpdateDesc;
}
INT_PTR KrakatoaPFFileUpdateParamProc::DlgProc( TimeValue /*t*/, IParamMap2* map, HWND hWnd, UINT msg, WPARAM wParam,
                                                LPARAM lParam ) {

    switch( msg ) {
    case WM_INITDIALOG:
        map->GetParamBlock()->GetParamDef( kKrakatoaPFFileUpdate_filepattern ).init_file =
            const_cast<MCHAR*>( map->GetParamBlock()->GetStr( kKrakatoaPFFileUpdate_filepattern ) );

        // Send the message to notify the initialization of dialog
        map->GetParamBlock()->NotifyDependents( FOREVER, (PartID)map, kKrakatoaPFFileUpdate_message_init );
        break;
    case WM_COMMAND:
        switch( LOWORD( wParam ) ) {
        case kKrakatoaPFFileUpdate_message_filename:
            if( !lParam )
                break;
            SetDlgItemText( hWnd, IDC_FILEUPDATE_FILEPATTERN,
                            _T( frantic::files::filename_from_path( reinterpret_cast<char*>( lParam ) ).c_str() ) );
            map->GetParamBlock()->GetParamDef( kKrakatoaPFFileUpdate_filepattern ).init_file =
                const_cast<char*>( map->GetParamBlock()->GetStr( kKrakatoaPFFileUpdate_filepattern ) );

            break;
        case IDC_FILEUPDATE_CHANNEL_SETUP_BUTTON:
            // The only dependant of this param block should be the file update operator it belongs to, so
            // only that one thing should get notified.
            map->GetParamBlock()->NotifyDependents( FOREVER, 0, IDC_FILEUPDATE_CHANNEL_SETUP_BUTTON );
            break;
        }
        break;
    }
    return FALSE;
}

class channel_name_link : public PBAccessor {
    TSTR GetLocalName( ReferenceMaker* owner, ParamID /*id*/, int tabIndex ) {
        KrakatoaPFFileUpdate* pFU = (KrakatoaPFFileUpdate*)owner;
        if( pFU && pFU->GetParamBlock( 0 ) ) {
            return pFU->GetParamBlock( 0 )->GetStr( kKrakatoaPFFileUpdate_blend_channel_names, 0, tabIndex );
        } else {
            return "";
        }
    }
};
static channel_name_link channel_name_link_object;

KrakatoaPFFileUpdateParamProc* KrakatoaPFFileUpdateDesc::dialog_proc = new KrakatoaPFFileUpdateParamProc();

//----------------------------------------------------
// Param Block info
//----------------------------------------------------
ParamBlockDesc2 KrakatoaPFFileUpdateDesc::pblock_desc(
    // required block spec
    kKrakatoaPFFileUpdate_pblock_index, _T("Parameters"), IDS_PARAMS, GetKrakatoaPFFileUpdateDesc(),
    P_AUTO_CONSTRUCT + P_AUTO_UI,
    // auto constuct block refno : none
    0,
    // auto ui parammap specs : none
    IDD_FILEUPDATE_PARAMETERS, IDS_PARAMS, 0,
    0, // open/closed
    KrakatoaPFFileUpdateDesc::dialog_proc,
    // required param specs

    // These are for channel-wise blending
    kKrakatoaPFFileUpdate_blend_channel_names, _T("BlendChannelNames"),
    TYPE_STRING_TAB, // type
    0,               // size
    P_READ_ONLY,     // flags
    IDS_FILEUPDATE_BLEND_CHANNEL_NAMES, end, kKrakatoaPFFileUpdate_blend_channel_alphas, _T("BlendChannelAlphas"),
    TYPE_FLOAT_TAB,                                 // type
    0,                                              // size
    P_ANIMATABLE + P_TV_SHOW_ALL + P_COMPUTED_NAME, // flags
    IDS_FILEUPDATE_BLEND_CHANNEL_ALPHAS,            // name
    p_accessor, &channel_name_link_object,          // optional tags
    end,

    // These are for saving the channel data params
    kKrakatoaPFFileUpdate_blend_channel_arity, _T(""),
    TYPE_INT_TAB, // type
    0,            // size
    P_INVISIBLE,  // flags
    IDS_FILEUPDATE_BLEND_CHANNEL_ARITY, end, kKrakatoaPFFileUpdate_blend_channel_use, _T(""),
    TYPE_INT_TAB, // type
    0,            // size
    P_INVISIBLE,  // flags
    IDS_FILEUPDATE_BLEND_CHANNEL_USE, end, kKrakatoaPFFileUpdate_blend_channel_data_type, _T(""),
    TYPE_INT_TAB, // type
    0,            // size
    P_INVISIBLE,  // flags
    IDS_FILEUPDATE_BLEND_CHANNEL_DATATYPE, end, kKrakatoaPFFileUpdate_blend_channel_blend_type, _T(""),
    TYPE_STRING_TAB, // type
    0,               // size
    P_INVISIBLE,     // flags
    IDS_FILEUPDATE_BLEND_CHANNEL_BLENDTYPE, end, kKrakatoaPFFileUpdate_target_channel_names, _T(""),
    TYPE_STRING_TAB, // type
    0,               // size
    P_INVISIBLE,     // flags
    IDS_FILEUPDATE_TARGET_CHANNEL_NAMES, end,

    // The rest of the options
    kKrakatoaPFFileUpdate_filepattern, _T("InputFileSequence"), TYPE_FILENAME, 0, IDS_FILEUPDATE_FILENAME, p_default,
    "", p_caption, IDS_FILEUPDATE_CAPTION, p_file_types, IDS_FILETYPES, p_ui, TYPE_FILEOPENBUTTON,
    IDC_FILEUPDATE_FILEBUTTON, end,

    kKrakatoaPFFileUpdate_frame_offset, _T("FrameOffset"), TYPE_INT, P_RESET_DEFAULT, IDS_FILEUPDATE_FRAMEOFFSET,
    // optional tagged param specs
    p_default, 0, p_ms_default, 0, p_range, -0x7FFF000, 0x7FFF000, p_ui, TYPE_SPINNER, EDITTYPE_INT,
    IDC_FILEUPDATE_FRAME_OFFSET, IDC_FILEUPDATE_FRAME_OFFSET_SPIN, 1.0f, end,

    kKrakatoaPFFileUpdate_single_frame_only, _T("SingleFrameOnly"), TYPE_BOOL, P_RESET_DEFAULT,
    IDS_FILEUPDATE_SINGLEFRAMEONLY,
    // optional tagged param specs
    p_default, FALSE, p_ms_default, FALSE, p_ui, TYPE_SINGLECHEKBOX, IDC_FILEUPDATE_SINGLE_FRAME_ONLY, end,

    kKrakatoaPFFileUpdate_limit_to_custom_range, _T("LimitToCustomRange"), TYPE_BOOL, P_RESET_DEFAULT,
    IDS_FILEUPDATE_LIMITTOCUSTOMRANGE,
    // optional tagged param specs
    p_default, FALSE, p_ms_default, FALSE, p_ui, TYPE_SINGLECHEKBOX, IDC_FILEUPDATE_LIMIT_TO_CUSTOM_RANGE,
    p_enable_ctrls, 2, kKrakatoaPFFileUpdate_custom_range_start, kKrakatoaPFFileUpdate_custom_range_end, end,

    kKrakatoaPFFileUpdate_custom_range_start, _T("CustomRangeStart"), TYPE_INT, P_RESET_DEFAULT,
    IDS_FILEUPDATE_CUSTOMRANGESTART,
    // optional tagged param specs
    p_default, 0, p_ms_default, 0, p_range, -0x7FFF000, 0x7FFF000, p_ui, TYPE_SPINNER, EDITTYPE_INT,
    IDC_FILEUPDATE_CUSTOM_RANGE_START, IDC_FILEUPDATE_CUSTOM_RANGE_START_SPIN, 1.0f, end,

    kKrakatoaPFFileUpdate_custom_range_end, _T("CustomRangeEnd"), TYPE_INT, P_RESET_DEFAULT,
    IDS_FILEUPDATE_CUSTOMRANGEEND,
    // optional tagged param specs
    p_default, 100, p_ms_default, 100, p_range, -0x7FFF000, 0x7FFF000, p_ui, TYPE_SPINNER, EDITTYPE_INT,
    IDC_FILEUPDATE_CUSTOM_RANGE_END, IDC_FILEUPDATE_CUSTOM_RANGE_END_SPIN, 1.0f, end,

    kKrakatoaPFFileUpdate_linktoobjecttm, _T("LinkToObjectTM"), TYPE_BOOL, P_RESET_DEFAULT,
    IDS_FILEUPDATE_LINKTOOBJECTTM,
    // optional tagged param specs
    p_default, FALSE, p_ms_default, FALSE, p_ui, TYPE_SINGLECHEKBOX, IDC_FILEUPDATE_LINKTOOBJECTTM,
    // p_enable_ctrls, 1, kKrakatoaPFFileUpdate_objectfortm,
    end,

    end );
//----------------------------------------------------
// End of Param Block info
//----------------------------------------------------

// I don't like disabling warning 4239 (doing so promotes non cross-platform compatible code), but the Particle Flow SDK
// basically forces my hand here.
#pragma warning( disable : 4239 )

using namespace std;
using namespace boost;
using namespace frantic;
// using namespace frantic::graphics;
using namespace frantic::particles;
using namespace frantic::particles::streams;
using namespace frantic::channels;
using namespace frantic::max3d::particles;
using namespace frantic::max3d;

//----------------------------------------------------
// Simple useless functions
//----------------------------------------------------
KrakatoaPFFileUpdate::KrakatoaPFFileUpdate() {
    InitializeFPDescriptor();
    GetClassDesc()->MakeAutoParamBlocks( this );
}

KrakatoaPFFileUpdate::~KrakatoaPFFileUpdate() {}

Class_ID KrakatoaPFFileUpdate::ClassID() { return GetClassDesc()->ClassID(); }

ClassDesc* KrakatoaPFFileUpdate::GetClassDesc() const { return GetKrakatoaPFFileUpdateDesc(); }

void KrakatoaPFFileUpdate::BeginEditParams( IObjParam* ip, ULONG flags, Animatable* prev ) {
    GetClassDesc()->BeginEditParams( ip, this, flags, prev );
}

void KrakatoaPFFileUpdate::EndEditParams( IObjParam* ip, ULONG flags, Animatable* next ) {
    GetClassDesc()->EndEditParams( ip, this, flags, next );
}

const ParticleChannelMask& KrakatoaPFFileUpdate::ChannelsUsed( const Interval& /*time*/ ) const {
    static ParticleChannelMask mask( PCU_Amount | PCU_Position | PCU_Speed, PCU_Speed );
    return mask;
}

const Interval KrakatoaPFFileUpdate::ActivityInterval() const {
    //	return Interval(pblock()->GetInt(kKrakatoaPFFileUpdate_start), TIME_PosInfinity);
    if( pblock()->GetInt( kKrakatoaPFFileUpdate_limit_to_custom_range ) )
        return Interval(
            GetTicksPerFrame() * pblock()->GetInt( kKrakatoaPFFileUpdate_custom_range_start ) - GetTicksPerFrame() / 2,
            GetTicksPerFrame() * pblock()->GetInt( kKrakatoaPFFileUpdate_custom_range_end ) + GetTicksPerFrame() / 2 );
    else {
        Interval interval;
        interval = GetCOREInterface()->GetAnimRange();
        return interval;
    }
}

RefTargetHandle KrakatoaPFFileUpdate::Clone( RemapDir& remap ) {
    KrakatoaPFFileUpdate* newOp = new KrakatoaPFFileUpdate();
    newOp->ReplaceReference( 0, remap.CloneRef( GetReference( 0 ) ) );
    BaseClone( this, newOp, remap );
    return newOp;
}

#if MAX_VERSION_MAJOR >= 15
const
#endif
    TCHAR*
    KrakatoaPFFileUpdate::GetObjectName() {
    return _T("Krakatoa File Update ");
}

void KrakatoaPFFileUpdate::PassMessage( int message, LPARAM param ) {
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

//----------------------------------------------------
// Meaty Important Functions
//----------------------------------------------------
RefResult KrakatoaPFFileUpdate::NotifyRefChanged( const Interval& changeInt, RefTargetHandle hTarget,
                                                  PartID& /*partID*/, RefMessage message, BOOL /*propagate*/ ) {

    switch( message ) {
    case REFMSG_CHANGE:
        if( hTarget == pblock() ) {
            int lastUpdateID = pblock()->LastNotifyParamID();
            switch( lastUpdateID ) {
            case kKrakatoaPFFileUpdate_filepattern: {
                // query the file for a particle channel map when it gets changed and stick it in
                // the member variable
                std::string filename = pblock()->GetStr( kKrakatoaPFFileUpdate_filepattern );
                shared_ptr<particle_istream> pin = frantic::particles::particle_file_istream_factory( filename );
                frantic::channels::channel_map channelMap = pin->get_channel_map();

                if( !channelMap.has_channel( "ID" ) ) {
                    std::string msg( "WARNING:  The selected particle file (" + filename +
                                     ") has no ID channel.  Particles will be assigned IDs based upon the order that "
                                     "they appear in the file." );
                    mprintf( "%s\n", msg.c_str() );
                    LogSys* log = GetCOREInterface()->Log();
                    log->LogEntry( SYSLOG_ERROR, DISPLAY_DIALOG, _T("KrakatoaPFFileUpdate WARNING"), _T("%s"),
                                   msg.c_str() );
                }
                // reset the channelData structures and include any default information
                pblock()->SetCount( kKrakatoaPFFileUpdate_blend_channel_names, (int)channelMap.channel_count() );
                pblock()->SetCount( kKrakatoaPFFileUpdate_target_channel_names, (int)channelMap.channel_count() );
                pblock()->SetCount( kKrakatoaPFFileUpdate_blend_channel_alphas, (int)channelMap.channel_count() );
                pblock()->SetCount( kKrakatoaPFFileUpdate_blend_channel_arity, (int)channelMap.channel_count() );
                pblock()->SetCount( kKrakatoaPFFileUpdate_blend_channel_data_type, (int)channelMap.channel_count() );
                pblock()->SetCount( kKrakatoaPFFileUpdate_blend_channel_use, (int)channelMap.channel_count() );
                pblock()->SetCount( kKrakatoaPFFileUpdate_blend_channel_blend_type, (int)channelMap.channel_count() );
                for( unsigned int i = 0; i < channelMap.channel_count(); ++i ) {

                    pblock()->SetValue( kKrakatoaPFFileUpdate_blend_channel_names, 0,
                                        (TCHAR*)channelMap[i].name().c_str(), i );
                    pblock()->SetValue( kKrakatoaPFFileUpdate_blend_channel_arity, 0, (int)channelMap[i].arity(), i );
                    pblock()->SetValue( kKrakatoaPFFileUpdate_blend_channel_data_type, 0, channelMap[i].data_type(),
                                        i );

                    // default position and ID to "on"
                    if( channelMap[i].name().compare( "Position" ) == 0 || channelMap[i].name().compare( "ID" ) == 0 )
                        pblock()->SetValue( kKrakatoaPFFileUpdate_blend_channel_use, 0, 1, i );
                    else
                        pblock()->SetValue( kKrakatoaPFFileUpdate_blend_channel_use, 0, 0, i );

                    pblock()->SetValue( kKrakatoaPFFileUpdate_blend_channel_blend_type, 0, (TCHAR*)"Blend", i );
                    pblock()->SetValue( kKrakatoaPFFileUpdate_blend_channel_alphas, 0, 100.f, (int)i );
                    pblock()->SetValue( kKrakatoaPFFileUpdate_target_channel_names, 0,
                                        (TCHAR*)channelMap[i].name().c_str(), i );

                    // default density to go to MXSFloat
                    if( channelMap[i].name().compare( "Density" ) == 0 )
                        pblock()->SetValue( kKrakatoaPFFileUpdate_target_channel_names, 0, (TCHAR*)"MXSFloat", i );
                }

                PassMessage( kKrakatoaPFFileUpdate_message_filename,
                             (LPARAM)pblock()->GetStr( kKrakatoaPFFileUpdate_filepattern ) );
            }
            case kKrakatoaPFFileUpdate_frame_offset:
            case kKrakatoaPFFileUpdate_single_frame_only:
            case kKrakatoaPFFileUpdate_limit_to_custom_range:
            case kKrakatoaPFFileUpdate_custom_range_start:
            case kKrakatoaPFFileUpdate_custom_range_end:
            case kKrakatoaPFFileUpdate_linktoobjecttm:
                NotifyDependents( FOREVER, 0, kPFMSG_InvalidateParticles, NOTIFY_ALL, TRUE );
                break;
            }
            UpdatePViewUI( lastUpdateID );
        }
        break;
    // Initialization of Dialog
    case kKrakatoaPFFileUpdate_message_init:
        PassMessage( kKrakatoaPFFileUpdate_message_filename,
                     (LPARAM)pblock()->GetStr( kKrakatoaPFFileUpdate_filepattern ) );
        return REF_STOP;
    case IDC_FILEUPDATE_CHANNEL_SETUP_BUTTON:
        try {

            // make sure we have some data to pass first.  ie, that a file has been selected.
            std::string file = pblock()->GetStr( kKrakatoaPFFileUpdate_filepattern );
            if( file.empty() )
                break;

            std::string scriptString =
                "Krakatoa_PFlowOperator_Functions.OpenChannelSelectorDialog KrakatoaPFFileUpdateObject";
            frantic::max3d::mxs::expression( scriptString )
                .bind( "KrakatoaPFFileUpdateObject", this )
                .at_time( changeInt.Start() )
                .evaluate<Value*>();

            break;

        } catch( const std::exception& e ) {
            mprintf( "Error in KrakatoaPFFileUpdate::NotifyRefChanged()\n\t%s\n", e.what() );
            LogSys* log = GetCOREInterface()->Log();
            log->LogEntry( SYSLOG_ERROR, DISPLAY_DIALOG, _T("KrakatoaPFFileUpdate Error"), _T("%s"), e.what() );
            if( GetCOREInterface()->IsNetworkRenderServer() )
                throw MAXException( const_cast<char*>( e.what() ) );
        }
    }
    return REF_SUCCEED;
}

//+--------------------------------------------------------------------------+
//|							From IPViewItem
//|
//+--------------------------------------------------------------------------+
HBITMAP KrakatoaPFFileUpdate::GetActivePViewIcon() {
    if( activeIcon() == NULL )
        _activeIcon() = (HBITMAP)LoadImage( hInstance, MAKEINTRESOURCE( IDB_FILEUPDATE_ACTIVE ), IMAGE_BITMAP,
                                            kActionImageWidth, kActionImageHeight, LR_SHARED );
    return activeIcon();
}

//+--------------------------------------------------------------------------+
//|							From IPViewItem
//|
//+--------------------------------------------------------------------------+
HBITMAP KrakatoaPFFileUpdate::GetInactivePViewIcon() {
    if( inactiveIcon() == NULL )
        _inactiveIcon() = (HBITMAP)LoadImage( hInstance, MAKEINTRESOURCE( IDB_FILEUPDATE_INACTIVE ), IMAGE_BITMAP,
                                              kActionImageWidth, kActionImageHeight, LR_SHARED );
    return inactiveIcon();
}

std::string KrakatoaPFFileUpdate::get_channel_data() {

    std::string channelDataString;
    int channelCount = pblock()->Count( kKrakatoaPFFileUpdate_blend_channel_names );
    for( int i = 0; i < channelCount; ++i ) {
        channelDataString.append(
            std::string( pblock()->GetStr( kKrakatoaPFFileUpdate_blend_channel_names, 0, i ) ) + "," +
            channel_data_type_str( (frantic::channels::data_type_t)pblock()->GetInt(
                kKrakatoaPFFileUpdate_blend_channel_data_type, 0, i ) ) +
            "," +
            boost::lexical_cast<std::string>( pblock()->GetInt( kKrakatoaPFFileUpdate_blend_channel_arity, 0, i ) ) +
            "," +
            boost::lexical_cast<std::string>( pblock()->GetInt( kKrakatoaPFFileUpdate_blend_channel_use, 0, i ) ) +
            "," + std::string( pblock()->GetStr( kKrakatoaPFFileUpdate_blend_channel_blend_type, 0, i ) ) + "," +
            std::string( pblock()->GetStr( kKrakatoaPFFileUpdate_target_channel_names, 0, i ) ) + "," );
    }
    channelDataString.erase( channelDataString.size() - 1 );
    // mprintf("get_channel_data(): channelDataString: %s\n", channelDataString.c_str());
    // ofstream //fout("C:\\maxtests\\particleflow\\krakatoa\\debug.txt", std::ios_base::app);
    // fout << "get_channel_data(): channelDataString: " << channelDataString << std::endl;
    return channelDataString;
}

void KrakatoaPFFileUpdate::set_channel_data( std::string channelDataString ) {
    // mprintf("set_channel_data(): channelDataString: %s\n", channelDataString.c_str());
    // ofstream //fout("C:\\maxtests\\particleflow\\krakatoa\\debug.txt", std::ios_base::app);
    // fout << "set_channel_data(): channelDataString: " << channelDataString << std::endl;
    try {

        vector<string> tokens;
        frantic::strings::split( channelDataString, tokens, ',' );

        size_t tokenCount = 0;
        int channelCount = 0;

        while( tokenCount < tokens.size() ) {

            pblock()->SetValue( kKrakatoaPFFileUpdate_blend_channel_names, 0, (TCHAR*)tokens[tokenCount++].c_str(),
                                channelCount );

            if( tokenCount > tokens.size() )
                throw std::runtime_error(
                    "KrakatoaPFFileUpdate::SetChannelData: Could not read channel type.  Token did not exist." );
            frantic::channels::data_type_t dataType = channel_data_type_from_string( tokens[tokenCount++] );
            pblock()->SetValue( kKrakatoaPFFileUpdate_blend_channel_data_type, 0, dataType, channelCount );

            if( tokenCount > tokens.size() )
                throw std::runtime_error(
                    "KrakatoaPFFileUpdate::SetChannelData: Could not read channel arity.  Token did not exist." );
            int arity = boost::lexical_cast<int, string>( tokens[tokenCount++] );
            if( arity < 1 )
                throw std::runtime_error(
                    "KrakatoaPFFileUpdate::SetChannelData: Bad channel arity token.  Value converts to 0 or less." );

            pblock()->SetValue( kKrakatoaPFFileUpdate_blend_channel_arity, 0, arity, channelCount );

            if( tokenCount > tokens.size() )
                throw std::runtime_error(
                    "KrakatoaPFFileUpdate::SetChannelData: Could not read use channel flag.  Token did not exist." );
            int useChannel = boost::lexical_cast<int, string>( tokens[tokenCount++] );

            pblock()->SetValue( kKrakatoaPFFileUpdate_blend_channel_use, 0, useChannel, channelCount );

            if( tokenCount > tokens.size() )
                throw std::runtime_error(
                    "KrakatoaPFFileUpdate::SetChannelData: Could not read blend type.  Token did not exist." );

            pblock()->SetValue( kKrakatoaPFFileUpdate_blend_channel_blend_type, 0, (TCHAR*)tokens[tokenCount++].c_str(),
                                channelCount );

            if( tokenCount > tokens.size() )
                throw std::runtime_error( "KrakatoaPFFileUpdate::SetChannelData: Could not read particle flow channel "
                                          "name.  Token did not exist." );

            pblock()->SetValue( kKrakatoaPFFileUpdate_target_channel_names, 0, (TCHAR*)tokens[tokenCount++].c_str(),
                                channelCount );

            if( tokenCount > tokens.size() )
                throw std::runtime_error( "KrakatoaPFFileUpdate::SetChannelData: Could not read particle channel name. "
                                          " Token did not exist." );

            channelCount++;
        }

    } catch( const std::exception& e ) {
        mprintf( "Error in KrakatoaPFFileUpdate::SetChannelData()\n\t%s\n", e.what() );
        LogSys* log = GetCOREInterface()->Log();
        log->LogEntry( SYSLOG_ERROR, DISPLAY_DIALOG, _T("KrakatoaPFFileUpdate Error"), _T("%s"), e.what() );
        if( GetCOREInterface()->IsNetworkRenderServer() )
            throw MAXException( const_cast<char*>( e.what() ) );
    }
}

bool KrakatoaPFFileUpdate::Proceed( IObject* pCont, PreciseTimeValue timeStart, PreciseTimeValue& timeEnd,
                                    Object* pSystem, INode* pNode, INode* /*actionNode*/,
                                    IPFIntegrator* /*integrator*/ ) {
    try {
        if( pblock() == NULL ) {
            if( this->GetParamBlock( 0 ) != NULL )
                throw std::runtime_error( "KrakatoaPFFileUpdate's pblock was NULL, but Ref0 was not" );
            throw std::runtime_error( "KrakatoaPFFileUpdate's pblock was NULL" );
        }

        // ofstream fout("C:\\maxtests\\particleflow\\krakatoa\\debug.txt");
        // mprintf("\n\nExecuting KrakatoaPFFileUpdate::Proceed\n");
        // fout << "KrakatoaPFFileUpdate::Proceed\n" << std::endl;

        IParticleObjectExt* poExt = GetParticleObjectExtInterface( GetPFObject( pSystem ) );
        if( poExt == NULL ) {
            throw std::runtime_error( "KrakatoaPFFileUpdate: Could not set up the interface to ParticleObjectExt" );
        } // no handle for ParticleObjectExt interface

        IPFSystem* pfSys = GetPFSystemInterface( pSystem );
        if( pfSys == NULL ) {
            throw std::runtime_error( "KrakatoaPFFileUpdate: Could not set up the interface to PFSystem" );
        } // no handle for PFSystem interface

        TimeValue evalTime = timeEnd;
        int frameNumber = (int)ceil( double( evalTime ) / (double)GetTicksPerFrame() );
        // int frameNumber = (evalTime + GetTicksPerFrame()/2) / GetTicksPerFrame();

        // mprintf("KrakatoaPFFileUpdate: evalTime %d  frameNumber %d\n", evalTime, frameNumber);
        // fout << "KrakatoaPFFileUpdate: evalTime " << evalTime << " frameNumber " << frameNumber << std::endl;
        // fout << "timestart " << timeStart.TimeValue() << "  timeEnd " << timeEnd.TimeValue() << std::endl;
        if( pblock()->GetInt( kKrakatoaPFFileUpdate_limit_to_custom_range ) ) {
            TimeValue customRangeStart = pblock()->GetInt( kKrakatoaPFFileUpdate_custom_range_start );
            TimeValue customRangeEnd = pblock()->GetInt( kKrakatoaPFFileUpdate_custom_range_end );

            // Return success if it's outside the range
            if( frameNumber < customRangeStart || frameNumber > customRangeEnd )
                return true;
        }

        std::string targetFile = pblock()->GetStr( kKrakatoaPFFileUpdate_filepattern );
        if( targetFile.empty() )
            return true;

        // Substitute the frame number
        bool singleFrameOnly = ( pblock()->GetInt( kKrakatoaPFFileUpdate_single_frame_only ) != FALSE );
        if( !singleFrameOnly ) {
            frameNumber += pblock()->GetInt( kKrakatoaPFFileUpdate_frame_offset );
            targetFile = frantic::files::replace_sequence_number( targetFile, frameNumber );
        }

        if( !frantic::files::file_exists( targetFile ) ) {
            // throw std::runtime_error("PFOperatorKrakatoaPFFileUpdate: The input file: " + targetFile + " does not
            // exist.");
            return false;
        }

        // Define the source and destination channel maps.  We're only allowing a shuffling of channels
        // of the same type/arity at the moment, so I basically just have to switch the names of the channels.
        // I should be enforcing this with a check though, really.
        channel_map filePcm, pflowPcm;
        for( int i = 0; i < pblock()->Count( kKrakatoaPFFileUpdate_blend_channel_names ); ++i ) {
            if( pblock()->GetInt( kKrakatoaPFFileUpdate_blend_channel_use, 0, i ) == 1 ) {
                filePcm.define_channel(
                    pblock()->GetStr( kKrakatoaPFFileUpdate_blend_channel_names, 0, i ),
                    pblock()->GetInt( kKrakatoaPFFileUpdate_blend_channel_arity, 0, i ),
                    (data_type_t)pblock()->GetInt( kKrakatoaPFFileUpdate_blend_channel_data_type, 0, i ) );
                pflowPcm.define_channel(
                    pblock()->GetStr( kKrakatoaPFFileUpdate_target_channel_names, 0, i ),
                    pblock()->GetInt( kKrakatoaPFFileUpdate_blend_channel_arity, 0, i ),
                    (data_type_t)pblock()->GetInt( kKrakatoaPFFileUpdate_blend_channel_data_type, 0, i ) );
            }
        }
        filePcm.end_channel_definition( 1, true );
        pflowPcm.end_channel_definition( 1, true );

        if( filePcm.channel_count() == 0 )
            return true;

        // fout << "done pcm definitions " << std::endl;
        // for (size_t i = 0; i < filePcm.channel_count(); ++i) {
        // fout << filePcm[i].name() << ",";
        //}
        // fout << std::endl;
        // for (size_t i = 0; i < pflowPcm.channel_count(); ++i){
        // fout << pflowPcm[i].name() << ",";
        //}
        // fout << std::endl;

        // Set up the blending and try to acquire the channels we need (will toss an exception if we can't)
        std::vector<string> blendChannelNames;
        std::vector<int> blendTypes;
        std::vector<float> blendAlphas;
        float expFraction = float( timeEnd.TimeValue() - timeStart.TimeValue() ) / float( GetTicksPerFrame() );

        for( int i = 0; i < pblock()->Count( kKrakatoaPFFileUpdate_blend_channel_names ); ++i ) {
            if( pblock()->GetInt( kKrakatoaPFFileUpdate_blend_channel_use, timeStart, i ) ) {
                float alpha = pblock()->GetFloat( kKrakatoaPFFileUpdate_blend_channel_alphas, timeStart, i ) / 100.f;
                blendChannelNames.push_back(
                    pblock()->GetStr( kKrakatoaPFFileUpdate_target_channel_names, timeStart, i ) );
                // fout << pblock()->GetStr(kKrakatoaPFFileUpdate_blend_channel_names,timeStart,i);
                // fout << "   " << pblock()->GetStr(kKrakatoaPFFileUpdate_blend_channel_blend_type,timeStart,i) << "
                // alpha: " << alpha << std::endl;
                if( !string( "Blend" ).compare(
                        pblock()->GetStr( kKrakatoaPFFileUpdate_blend_channel_blend_type, timeStart, i ) ) ) {
                    blendTypes.push_back( 0 ); // regular blend
                    blendAlphas.push_back( 1.f - pow( 1.f - alpha, expFraction ) );
                } else {
                    blendTypes.push_back( 1 ); // "additive" blend
                    blendAlphas.push_back( alpha * float( timeEnd - timeStart ) / GetTicksPerFrame() );
                }
            }
        }
        // fout << "done blending map data" << std::endl;

        particle_flow_channel_interface pfci( pCont );
        pfci.initialize_channel_interface( pflowPcm, blendChannelNames, blendTypes, blendAlphas );
        // fout << "done channel initialization " << std::endl;

        // mprintf( "Getting particles from \"%s\"\n", targetFile.c_str() );
        // fout << "Geting particles from " << targetFile << std::endl;

        // Set up the stream for reading
        shared_ptr<particle_istream> pin = frantic::particles::particle_file_istream_factory( targetFile, filePcm );

        // TODO:  Come up with some sort of hashing scheme to allow the fractional loading to work correctly.
        // Right now, you have to load everything if you want it to work correctly.  Fractionally loading does
        // not guarantee (on the contrary, it's highly unlikely) that you'll get consistent IDs for the
        // birthing/updating, unless particles IDs are completely static throughout the sequence.

        // force a particle multiplier of 100% for file operations
        float particleCountMultiplier = 1.0f; // pfSys->GetMultiplier(timeStart);
        int particlesLimit = pfSys->GetBornAllowance() - poExt->NumParticlesGenerated();
        bool evenlyDistributeLoading = true;

        if( pin->particle_count() > 0 )
            pin = apply_fractional_particle_istream( pin, particleCountMultiplier, particlesLimit,
                                                     evenlyDistributeLoading );

        if( pin->particle_count() == 0 ) {
            return true;
        }
        // fout << "num particles " << pin->particle_count() << std::endl;

        bool useNodeTransform = ( pblock()->GetInt( kKrakatoaPFFileUpdate_linktoobjecttm ) != FALSE );
        if( useNodeTransform && pNode )
            pin = frantic::max3d::particles::transform_stream_with_inode( pNode, timeStart,
                                                                          ( timeEnd - timeStart ).TimeValue(), pin );

        // Load the particles

        size_t particleSize = filePcm.structure_size();  // Size of the particle structure
        vector<char> buffer;                             // Temp storage
        unsigned counter;                                // Counts the number of particles in a reading batch
        int fileCount = 0;                               // Counts total number of particles read from file
        int pflowCount = pfci.get_particle_flow_count(); // Number of current pflow particles

        vector<char> particles;         // Local storage of particles from file
        vector<idPair> fileID;          // Indices and IDs of file particles
        vector<idPair> pflowID;         // Indices and IDs of pflow particles
        channel_general_accessor idAcc; // accessor for particle's ID info in the file
        bool hasID = false;
        if( filePcm.has_channel( "ID" ) ) {
            idAcc = filePcm.get_general_accessor( "ID" );
            hasID = true;
        }

        // fout << "Particle size: " << particleSize << " buffer size: " << buffer.size() << std::endl;
        //  We don't know how many particles we are reading...do batches?
        if( pin->particle_count() < 0 ) {
            buffer.resize( NUM_BUFFERED_PARTICLES * particleSize );
            do {
                char* pParticle = &buffer[0];
                for( counter = 0; counter < NUM_BUFFERED_PARTICLES; ++counter ) {
                    if( !pin->get_particle( pParticle ) )
                        break;
                    pParticle += particleSize;
                }

                if( counter == 0 )
                    break;

                // build id info
                fileID.resize( fileID.size() + counter );

                for( unsigned int i = 0; i < counter; i++ ) {
                    fileID[fileCount + i].index = fileCount + i;
                    if( hasID )
                        fileID[fileCount + i].id =
                            *( (int*)idAcc.get_channel_data_pointer( &buffer[i * particleSize] ) );
                    else
                        fileID[fileCount + i].id = fileCount + i;
                }

                // temp store of particle info
                particles.resize( particles.size() + counter * particleSize );
                memcpy( &particles[fileCount * particleSize], &buffer[0], counter * particleSize );
                fileCount += counter;

            } while( counter == NUM_BUFFERED_PARTICLES ); // Keep writing particles until we find a non-full batch
        }
        // Positive particle count, we know how many.
        else {

            fileCount = (int)pin->particle_count();
            particles.resize( fileCount * particleSize );
            fileID.resize( fileCount );
            for( int i = 0; i < fileCount; i++ ) {

                pin->get_particle( &particles[i * particleSize] );

                // build id info
                fileID[i].index = i;
                if( hasID )
                    fileID[i].id = *( (int*)idAcc.get_channel_data_pointer( &particles[i * particleSize] ) );
                else
                    fileID[i].id = i;
            }
        }

        // fout << "Done fetching particles from file" << std::endl;

        // Grab all the pflow particle indices/ids
        pflowID.resize( pflowCount );
        for( int i = 0; i < pflowCount; i++ ) {
            pflowID[i].index = i;
            pflowID[i].id = pfci.get_particle_file_id( i );
        }

        // fout << "Done fetching pflow ids" << std::endl;

        // sort the file index/ID pairs by ID
        if( hasID ) // only needs to be sorted if we had to load IDs from the file
            sort( fileID.begin(), fileID.end(), &KrakatoaPFFileUpdate::sortFunction );
        sort( pflowID.begin(), pflowID.end(), &KrakatoaPFFileUpdate::sortFunction );

        /*
                        mprintf("\nKrakatoaPFFileUpdate Particles\n");
                        mprintf("Interval: %d %d\n", timeStart.tick, timeEnd.tick);
                        mprintf("BEFORE\n");
                        mprintf("File particles (but with the pflow map):\n");
                        for(unsigned int i = 0;i < fileID.size(); i++) {
                                mprintf("FID: %d\t", fileID[i].id);
                                if ( pflowPcm.has_channel("Position") ) {
                                        channel_cvt_accessor<frantic::graphics::vector3f> pa =
           pflowPcm.get_cvt_accessor<frantic::graphics::vector3f>("Position"); frantic::graphics::vector3f pos =
           pa.get(&particles[i*particleSize]); mprintf("pos: %s\t", pos.str().c_str());
                                }
                                if ( pflowPcm.has_channel("Velocity") ) {
                                        channel_cvt_accessor<frantic::graphics::vector3f> va =
           pflowPcm.get_cvt_accessor<frantic::graphics::vector3f>("Velocity"); frantic::graphics::vector3f vel =
           va.get(&particles[i*particleSize]); mprintf("vel: %s\t", vel.str().c_str());
                                }
                                mprintf("\n");
                        }
                        mprintf("Pflow particles BEFORE:\n");
                        for(unsigned int i = 0; i < pflowID.size(); i++)  {
                                mprintf("FID: %d\t", pflowID[i].id);
                                if (pfci.m_channels.positionR){
                                        frantic::graphics::vector3f pos = pfci.m_channels.positionR->GetValue(i);
                                        mprintf("pos: %s  blend:%f\t", pos.str().c_str(),
           pfci.m_channels.positionBlendAlpha);
                                }
                                if (pfci.m_channels.velocityR) {
                                        frantic::graphics::vector3f vel = pfci.m_channels.velocityR->GetValue(i);
                                        mprintf("vel: %s  blend:%f\t", vel.str().c_str(),
           pfci.m_channels.velocityBlendAlpha);
                                }
                                mprintf("\n");
                        }
        */

        // fout << "Done sorting ids" << std::endl;
        size_t fileCounter = 0, pflowCounter = 0;
        bool done = false;
        while( !done ) {
            if( fileCounter >= fileID.size() || pflowCounter >= pflowID.size() ) {
                // we hit the end of one of the ID arrays
                done = true;
            } else if( pflowID[pflowCounter].id == fileID[fileCounter].id ) {
                pfci.copy_particle( particles[fileID[fileCounter].index * particleSize], pflowID[pflowCounter].index,
                                    timeEnd, pfci.is_particle_new( pflowID[pflowCounter].index ) );
                pflowCounter++;
                fileCounter++;
            } else if( pflowID[pflowCounter].id < fileID[fileCounter].id ) {
                // the pflow particle doesnt have a match in the file, keep going
                pfci.set_particle_file_id( pflowID[pflowCounter].index, -1 );
                pflowCounter++;
            } else if( fileID[fileCounter].id < pflowID[pflowCounter].id ) {
                // the file ID doesn't exist in the pflow ID list, keep going
                fileCounter++;
            }
        }
        // since you might have just hit the end of one of the arrays, loop through the remaining
        // particles in pflow and flag them for deletion
        while( pflowCounter < pflowID.size() ) {
            pfci.set_particle_file_id( pflowID[pflowCounter].index, -1 );
            pflowCounter++;
        }

        /*
                        mprintf("Pflow particles AFTER:\n");
                        for(unsigned int i = 0; i < pflowID.size(); i++)  {
                                mprintf("FID: %d\t", pflowID[i].id);
                                if (pfci.m_channels.positionR){
                                        frantic::graphics::vector3f pos = pfci.m_channels.positionR->GetValue(i);
                                        mprintf("pos: %s\t", pos.str().c_str());
                                }
                                if (pfci.m_channels.velocityR) {
                                        frantic::graphics::vector3f vel = pfci.m_channels.velocityR->GetValue(i);
                                        mprintf("vel: %s\t", vel.str().c_str());
                                }
                                mprintf("\n");
                        }
        */
    } catch( const std::exception& e ) {
        mprintf( "Error in KrakatoaPFFileUpdate::Proceed()\n\t%s\n", e.what() );
        // LogSys* log = GetCOREInterface()->Log();
        // log->LogEntry( SYSLOG_ERROR, DISPLAY_DIALOG, _T("KrakatoaPFFileUpdate Error"), _T("%s"), e.what() );
        if( GetCOREInterface()->IsNetworkRenderServer() )
            throw MAXException( const_cast<char*>( e.what() ) );
        return false;
    }

    return true;
}

void KrakatoaPFFileUpdate::InitializeFPDescriptor() {
    FFCreateDescriptor c( this, KrakatoaPFFileUpdate_Interface_ID, "KrakatoaPFFileUpdateInterface",
                          GetKrakatoaPFFileUpdateDesc() );

    c.add_function( &KrakatoaPFFileUpdate::get_channel_data, "GetChannelData" );
    c.add_function( &KrakatoaPFFileUpdate::set_channel_data, "SetChannelData", "ChannelDataString" );
}
#endif
