// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0
#include "stdafx.h"

// File birth has been deprecated for a while now, so I'm just going to not include it anymore.
#if MAX_VERSION_MAJOR < 15

#include "resource.h"

#include "PFlow Operators\MaxKrakatoaPFFileBirth.h"

#include <frantic/particles/particle_file_stream_factory.hpp>
#include <frantic/particles/particle_utilities.hpp>
#include <frantic/particles/streams/fractional_particle_istream.hpp>
#include <frantic/particles/streams/transformed_particle_istream.hpp>

#include <frantic/max3d/particles/particle_stream_factory.hpp>

extern HINSTANCE hInstance;

// I don't like disabling warning 4239 (doing so promotes non cross-platform compatible code), but the Particle Flow SDK
// basically forces my hand here.
#pragma warning( disable : 4239 )

using namespace frantic;
using namespace frantic::max3d;

using boost::shared_ptr;
using frantic::channels::channel_map;
using frantic::particles::streams::particle_istream;
using std::string;
using std::vector;

HBITMAP KrakatoaPFFileBirthDesc::m_depotIcon = NULL;
HBITMAP KrakatoaPFFileBirthDesc::m_depotMask = NULL;

KrakatoaPFFileBirthDesc::~KrakatoaPFFileBirthDesc() {
    if( m_depotIcon != NULL ) {
        DeleteObject( m_depotIcon );
        m_depotIcon = NULL;
    }
    if( m_depotMask != NULL ) {
        DeleteObject( m_depotMask );
        m_depotMask = NULL;
    }
}

void* KrakatoaPFFileBirthDesc::Create( BOOL /*loading = FALSE*/ ) { return new KrakatoaPFFileBirth(); }

INT_PTR KrakatoaPFFileBirthDesc::Execute( int cmd, ULONG_PTR arg1, ULONG_PTR arg2, ULONG_PTR /*arg3*/ ) {
    TCHAR** res = NULL;
    bool* isPublic;
    bool* isFertile;
    HBITMAP* depotIcon;
    HBITMAP* depotMask;
    switch( cmd ) {
    case kPF_GetActionDescription:
        if( arg1 == NULL )
            return 0;
        res = (TCHAR**)arg1;
        *res = _T("Loads a set of particles with an initial position and velocity from a file.");
        break;
    case kPF_PViewPublic:
        if( arg1 == NULL )
            return 0;
        isPublic = (bool*)arg1;
        *isPublic = false; // Make it invisible since it is deprecated.
        break;
    case kPF_PViewCategory:
        if( arg1 == NULL )
            return 0;
        res = (TCHAR**)arg1;
        *res = _T("Birth");
        break;
    case kPF_IsFertile:
        if( arg1 == NULL )
            return 0;
        isFertile = (bool*)arg1;
        *isFertile = true;
        break;
    case kPF_PViewDepotIcon:
        if( arg1 == NULL )
            return 0;
        depotIcon = (HBITMAP*)arg1;
        if( arg2 == NULL )
            return 0;
        depotMask = (HBITMAP*)arg2;
        if( m_depotIcon == NULL )
            m_depotIcon = LoadBitmap( hInstance, MAKEINTRESOURCE( IDB_FILEBIRTH_ACTIVE_DEPOT ) );
        if( m_depotMask == NULL )
            m_depotMask = LoadBitmap( hInstance, MAKEINTRESOURCE( IDB_FILEBIRTH_MASK_DEPOT ) );
        *depotIcon = m_depotIcon;
        *depotMask = m_depotMask;
        break;
    default:
        return 0;
    }
    return 1;
}

// Each plug-in should have one instance of the ClassDesc class.
KrakatoaPFFileBirthDesc TheKrakatoaPFFileBirthDesc;
ClassDesc2* GetKrakatoaPFFileBirthDesc() { return &TheKrakatoaPFFileBirthDesc; }

// Dialog Proc
KrakatoaPFFileBirthDlgProc TheKrakatoaPFFileBirthDlgProc;

// SampleBirth Operator param block
// ParamBlockDesc2 FileBirthDesc::pblock_desc
ParamBlockDesc2 KrakatoaPFFileBirth_paramBlockDesc(
    // required block spec
    kFileBirth_mainPBlockIndex, _T("Parameters"), IDS_PARAMS, &TheKrakatoaPFFileBirthDesc, P_AUTO_CONSTRUCT + P_AUTO_UI,
    // auto constuct block refno : none
    kFileBirth_mainPBlockIndex,
    // auto ui parammap specs : none
    IDD_FILEBIRTH_PARAMETERS, IDS_PARAMS, 0,
    0, // open/closed
    &TheKrakatoaPFFileBirthDlgProc,
    // required param specs
    kFileBirth_filepattern, _T("InputFileSequence"), TYPE_FILENAME, 0, IDS_FILEBIRTH_FILENAME, p_default, "", p_caption,
    IDS_FILEBIRTH_CAPTION, p_file_types, IDS_FILETYPES, p_ui, TYPE_FILEOPENBUTTON, IDC_FILEBIRTH_FILEBUTTON, end,

    kFileBirth_frame_offset, _T("FrameOffset"), TYPE_INT, P_RESET_DEFAULT, IDS_FILEBIRTH_FRAMEOFFSET,
    // optional tagged param specs
    p_default, 0, p_ms_default, 0, p_range, -0x7FFF000, 0x7FFF000, p_ui, TYPE_SPINNER, EDITTYPE_INT,
    IDC_FILEBIRTH_FRAME_OFFSET, IDC_FILEBIRTH_FRAME_OFFSET_SPIN, 1.0f, end,

    kFileBirth_single_frame_only, _T("SingleFrameOnly"), TYPE_BOOL, P_RESET_DEFAULT, IDS_FILEBIRTH_SINGLEFRAMEONLY,
    // optional tagged param specs
    p_default, FALSE, p_ms_default, FALSE, p_ui, TYPE_SINGLECHEKBOX, IDC_FILEBIRTH_SINGLE_FRAME_ONLY, end,

    kFileBirth_limit_to_custom_range, _T("LimitToCustomRange"), TYPE_BOOL, P_RESET_DEFAULT,
    IDS_FILEBIRTH_LIMITTOCUSTOMRANGE,
    // optional tagged param specs
    p_default, FALSE, p_ms_default, FALSE, p_ui, TYPE_SINGLECHEKBOX, IDC_FILEBIRTH_LIMIT_TO_CUSTOM_RANGE,
    p_enable_ctrls, 2, kFileBirth_custom_range_start, kFileBirth_custom_range_end, end,

    kFileBirth_custom_range_start, _T("CustomRangeStart"), TYPE_INT, P_RESET_DEFAULT, IDS_FILEBIRTH_CUSTOMRANGESTART,
    // optional tagged param specs
    p_default, 0, p_ms_default, 0, p_range, -0x7FFF000, 0x7FFF000, p_ui, TYPE_SPINNER, EDITTYPE_INT,
    IDC_FILEBIRTH_CUSTOM_RANGE_START, IDC_FILEBIRTH_CUSTOM_RANGE_START_SPIN, 1.0f, end,

    kFileBirth_custom_range_end, _T("CustomRangeEnd"), TYPE_INT, P_RESET_DEFAULT, IDS_FILEBIRTH_CUSTOMRANGEEND,
    // optional tagged param specs
    p_default, 100, p_ms_default, 100, p_range, -0x7FFF000, 0x7FFF000, p_ui, TYPE_SPINNER, EDITTYPE_INT,
    IDC_FILEBIRTH_CUSTOM_RANGE_END, IDC_FILEBIRTH_CUSTOM_RANGE_END_SPIN, 1.0f, end,

    kFileBirth_linktoobjecttm, _T("LinkToObjectTM"), TYPE_BOOL, P_RESET_DEFAULT, IDS_FILEBIRTH_LINKTOOBJECTTM,
    // optional tagged param specs
    p_default, FALSE, p_ms_default, FALSE, p_ui, TYPE_SINGLECHEKBOX, IDC_FILEBIRTH_LINKTOOBJECTTM,
    // p_enable_ctrls, 1, kFileBirth_objectfortm,
    end,

    end );

INT_PTR KrakatoaPFFileBirthDlgProc::DlgProc( TimeValue /*t*/, IParamMap2* map, HWND hWnd, UINT msg, WPARAM wParam,
                                             LPARAM lParam ) {
    TSTR buf;
    switch( msg ) {
    case WM_INITDIALOG:
        // setup the /initial path with the previous param block data
        map->GetParamBlock()->GetParamDef( kFileBirth_filepattern ).init_file =
            const_cast<MCHAR*>( map->GetParamBlock()->GetStr( kFileBirth_filepattern ) );
        // Send the message to notify the initialization of dialog
        map->GetParamBlock()->NotifyDependents( FOREVER, (PartID)map, kFileBirth_RefMsg_InitDlg );
        break;
    case WM_DESTROY:
        break;
    case WM_COMMAND:
        switch( LOWORD( wParam ) ) {
        case kFileBirth_message_filechoose:
            // setup the filename field/initial path with the chosen filename
            SetDlgItemText( hWnd, IDC_FILEBIRTH_FILENAME,
                            _T( frantic::files::filename_from_path( std::string( (char*)lParam ) ).c_str() ) );
            map->GetParamBlock()->GetParamDef( kFileBirth_filepattern ).init_file =
                const_cast<MCHAR*>( map->GetParamBlock()->GetStr( kFileBirth_filepattern ) );
            break;
        }
        break;
    }
    return FALSE;
}

//+>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>+
//|							From FileBirth						 |
//+>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>+
KrakatoaPFFileBirth::KrakatoaPFFileBirth() {
    GetClassDesc()->MakeAutoParamBlocks( this );
    m_lastIDs.clear();
}

bool KrakatoaPFFileBirth::IsEmitterTMDependent() const { return FALSE; }

void KrakatoaPFFileBirth::GetClassName( TSTR& s ) { s = GetKrakatoaPFFileBirthDesc()->ClassName(); }

Class_ID KrakatoaPFFileBirth::ClassID() { return KrakatoaPFFileBirth_Class_ID; }

void KrakatoaPFFileBirth::BeginEditParams( IObjParam* ip, ULONG flags, Animatable* prev ) {
    GetClassDesc()->BeginEditParams( ip, this, flags, prev );
}

void KrakatoaPFFileBirth::EndEditParams( IObjParam* ip, ULONG flags, Animatable* next ) {
    GetClassDesc()->EndEditParams( ip, this, flags, next );
}

RefResult KrakatoaPFFileBirth::NotifyRefChanged( const Interval& /*changeInt*/, RefTargetHandle hTarget,
                                                 PartID& /*partID*/, RefMessage message, BOOL /*propagate*/ ) {
    switch( message ) {
    case REFMSG_CHANGE:
        if( hTarget == pblock() ) {
            int lastUpdateID = pblock()->LastNotifyParamID();
            switch( lastUpdateID ) {
            case kFileBirth_filepattern: {
                // query the file for a particle channel map when it gets changed and stick it in
                // the member variable
                std::string filename = pblock()->GetStr( kFileBirth_filepattern );
                shared_ptr<particle_istream> pin = frantic::particles::particle_file_istream_factory( filename );
                frantic::channels::channel_map channelMap = pin->get_channel_map();
                if( !channelMap.has_channel( "ID" ) ) {
                    std::string msg( "WARNING:  The selected particle file (" + filename +
                                     ") has no ID channel.  Particles will be assigned IDs based upon the order that "
                                     "they appear in the file." );
                    mprintf( "%s\n", msg.c_str() );
                    LogSys* log = GetCOREInterface()->Log();
                    log->LogEntry( SYSLOG_ERROR, DISPLAY_DIALOG, _T("FileBirth Error"), _T("%s"), msg.c_str() );
                }
            }
            case kFileBirth_frame_offset:
            case kFileBirth_single_frame_only:
            case kFileBirth_limit_to_custom_range:
            case kFileBirth_custom_range_start:
            case kFileBirth_custom_range_end:
            case kFileBirth_linktoobjecttm:
                RefreshFilenameUI();
                NotifyDependents( FOREVER, 0, kPFMSG_InvalidateParticles, NOTIFY_ALL, TRUE );
                break;
            }

            UpdatePViewUI( lastUpdateID );
        }
        break;
    // Initialization of Dialog
    case kFileBirth_RefMsg_InitDlg:
        RefreshFilenameUI();
        return REF_STOP;
    }
    return REF_SUCCEED;
}

RefTargetHandle KrakatoaPFFileBirth::Clone( RemapDir& remap ) {
    KrakatoaPFFileBirth* newOp = new KrakatoaPFFileBirth();
    newOp->ReplaceReference( 0, remap.CloneRef( pblock() ) );
    BaseClone( this, newOp, remap );
    return newOp;
}

#if MAX_VERSION_MAJOR >= 15
const
#endif
    TCHAR*
    KrakatoaPFFileBirth::GetObjectName() {
    return GetString( IDS_FILEBIRTH_CLASSNAME );
}

const ParticleChannelMask& KrakatoaPFFileBirth::ChannelsUsed( const Interval& /*time*/ ) const {
    //  read    &	write channels
    static ParticleChannelMask mask( PCU_Amount, PCU_Amount | PCU_New | PCU_ID | PCU_Time | PCU_BirthTime |
                                                     PCU_Position | PCU_Speed );
    return mask;
}

const Interval KrakatoaPFFileBirth::ActivityInterval() const {
    if( pblock()->GetInt( kFileBirth_limit_to_custom_range ) )
        return Interval(
            GetTicksPerFrame() * pblock()->GetInt( kFileBirth_custom_range_start ) - GetTicksPerFrame() / 2,
            GetTicksPerFrame() * pblock()->GetInt( kFileBirth_custom_range_end ) + GetTicksPerFrame() / 2 );
    else {
        Interval interval;
        interval = GetCOREInterface()->GetAnimRange();
        return interval;
    }
}

//+--------------------------------------------------------------------------+
//|							From IPViewItem
//|
//+--------------------------------------------------------------------------+
HBITMAP KrakatoaPFFileBirth::GetActivePViewIcon() {
    if( activeIcon() == NULL )
        _activeIcon() = (HBITMAP)LoadImage( hInstance, MAKEINTRESOURCE( IDB_FILEBIRTH_ACTIVE ), IMAGE_BITMAP,
                                            kActionImageWidth, kActionImageHeight, LR_SHARED );
    return activeIcon();
}

//+--------------------------------------------------------------------------+
//|							From IPViewItem
//|
//+--------------------------------------------------------------------------+
HBITMAP KrakatoaPFFileBirth::GetInactivePViewIcon() {
    if( inactiveIcon() == NULL )
        _inactiveIcon() = (HBITMAP)LoadImage( hInstance, MAKEINTRESOURCE( IDB_FILEBIRTH_INACTIVE ), IMAGE_BITMAP,
                                              kActionImageWidth, kActionImageHeight, LR_SHARED );
    return inactiveIcon();
}

bool KrakatoaPFFileBirth::Proceed( IObject* pCont,
                                   PreciseTimeValue timeStart, // interval start to produce particles (exclusive)
                                   PreciseTimeValue& timeEnd,  // interval end to produce particles (inclusive)
                                   Object* pSystem,
                                   INode* pNode,          // inode of the emitter
                                   INode* /*actionNode*/, // inode of the operator
                                   IPFIntegrator* /*integrator*/ ) {
    try {

        IParticleObjectExt* poExt = GetParticleObjectExtInterface( GetPFObject( pSystem ) );
        if( poExt == NULL ) {
            throw std::runtime_error( "PFOperatorFileBirth: Could not set up the interface to ParticleObjectExt" );
            return false; // no handle for ParticleObjectExt interface
        }
        IPFSystem* pfSys = GetPFSystemInterface( pSystem );
        if( pfSys == NULL ) {
            throw std::runtime_error( "PFOperatorFileBirth: Could not set up the interface to PFSystem" );
            return false; // no handle for PFSystem interface
        }

        int numParticlesGen = poExt->NumParticlesGenerated();

        // force a particle multiplier of 100% for file operations
        float mult = 1.0f;
        float indexRatio = 1.0f / mult;

        TimeValue evalTime = timeEnd;
        int frameNumber = (int)ceil( double( evalTime ) / (double)GetTicksPerFrame() );
        // int frameNumber = (evalTime + GetTicksPerFrame()/2) / GetTicksPerFrame();

        if( pblock()->GetInt( kFileBirth_limit_to_custom_range ) ) {
            TimeValue customRangeStart = pblock()->GetInt( kFileBirth_custom_range_start );
            TimeValue customRangeEnd = pblock()->GetInt( kFileBirth_custom_range_end );

            // Return success if it's outside the range
            if( frameNumber < customRangeStart || frameNumber > customRangeEnd )
                return true;
        }

        const MCHAR* file = pblock()->GetStr( kFileBirth_filepattern );
        if( !file ) {
            m_lastIDs.clear();
            throw std::runtime_error( "PFOperatorFileBirth: No input file name specified." );
            return false;
        }

        std::string targetFile = file;

        // Substitute the frame number
        if( !pblock()->GetInt( kFileBirth_single_frame_only ) ) {
            frameNumber += pblock()->GetInt( kFileBirth_frame_offset );
            targetFile = files::replace_sequence_number( targetFile, frameNumber );
        }

        //-----------------------------------------------
        // Ensure access to the required particle channels
        //-----------------------------------------------

        // Make sure we can check on the current particles in the container
        IParticleChannelAmountR* chAmountR = GetParticleChannelAmountRInterface( pCont );
        if( chAmountR == NULL ) {
            throw std::runtime_error(
                "PFOperatorFileBirth: Could not set up the interface to IParticleChannelAmountR" );
            return false;
        }

        // Make sure we can add new particles to this container
        IParticleChannelAmountW* chAmountW = GetParticleChannelAmountWInterface( pCont );
        if( chAmountW == NULL ) {
            throw std::runtime_error(
                "PFOperatorFileBirth: Could not set up the interface to IParticleChannelAmountR" );
            return false;
        }

        // Get access to ChannelContainer interface
        IChannelContainer* chCont;
        chCont = GetChannelContainerInterface( pCont );
        if( chCont == NULL ) {
            throw std::runtime_error( "PFOperatorFileBirth: Could not set up the interface to ChannelContainer" );
            return false;
        }

        IParticleChannelNewW* chNewW =
            (IParticleChannelNewW*)chCont->EnsureInterface( PARTICLECHANNELNEWW_INTERFACE, ParticleChannelNew_Class_ID,
                                                            false, Interface_ID( 0, 0 ), Interface_ID( 0, 0 ) );
        if( chNewW == NULL ) {
            throw std::runtime_error( "PFOperatorFileBirth: Could not set up the interface to ParticleChannelNewW" );
            return false;
        };

        IParticleChannelPTVW* chTimeW = (IParticleChannelPTVW*)chCont->EnsureInterface(
            PARTICLECHANNELTIMEW_INTERFACE, ParticleChannelPTV_Class_ID, true, PARTICLECHANNELTIMER_INTERFACE,
            PARTICLECHANNELTIMEW_INTERFACE );
        if( chTimeW == NULL ) {
            throw std::runtime_error( "PFOperatorFileBirth: Could not set up the interface to ParticleChannelTimeW" );
            return false;
        }

        IParticleChannelIDW* chIDW =
            (IParticleChannelIDW*)chCont->EnsureInterface( PARTICLECHANNELIDW_INTERFACE, ParticleChannelID_Class_ID,
                                                           false, Interface_ID( 0, 0 ), Interface_ID( 0, 0 ) );
        if( chIDW == NULL ) {
            throw std::runtime_error( "PFOperatorFileBirth: Could not set up the interface to ParticleChannelIDW" );
            return false;
        }
        IParticleChannelIDR* chIDR = GetParticleChannelIDRInterface( pCont );
        if( chIDR == NULL ) {
            throw std::runtime_error( "PFOperatorFileBirth: Could not set up the interface to ParticleChannelIDR" );
            return false;
        } // can't read particle ID

        IParticleChannelPTVW* chBirthTimeW = (IParticleChannelPTVW*)chCont->EnsureInterface(
            PARTICLECHANNELBIRTHTIMEW_INTERFACE, ParticleChannelPTV_Class_ID, true, PARTICLECHANNELBIRTHTIMER_INTERFACE,
            PARTICLECHANNELBIRTHTIMEW_INTERFACE );
        if( chBirthTimeW == NULL ) {
            throw std::runtime_error(
                "PFOperatorFileBirth: Could not set up the interface to ParticleChannelBirthTimeW" );
            return false;
        }

        IParticleChannelPoint3W* chPosW = (IParticleChannelPoint3W*)chCont->EnsureInterface(
            PARTICLECHANNELPOSITIONW_INTERFACE, ParticleChannelPoint3_Class_ID, true,
            PARTICLECHANNELPOSITIONR_INTERFACE, PARTICLECHANNELPOSITIONW_INTERFACE, true );
        if( chPosW == NULL ) {
            throw std::runtime_error(
                "PFOperatorFileBirth: Could not set up the interface to ParticleChannelPositionW" );
            return false;
        }
        IParticleChannelPoint3R* chPosR = GetParticleChannelPositionRInterface( pCont );
        if( chPosR == NULL ) {
            throw std::runtime_error(
                "PFOperatorFileBirth: Could not set up the interface to ParticleChannelPositionR" );
            return false;
        } // can't read

        IParticleChannelIntW* chFIDW = (IParticleChannelIntW*)chCont->EnsureInterface(
            PARTICLECHANNELFILEIDINTEGERW_INTERFACE, ParticleChannelInt_Class_ID, true,
            PARTICLECHANNELFILEIDINTEGERR_INTERFACE, PARTICLECHANNELFILEIDINTEGERW_INTERFACE, true );
        if( chFIDW == NULL ) {
            throw std::runtime_error( "PFOperatorFileBirth: Could not set up the interface to FileIDIntegerW" );

        } // can't write
        IParticleChannelIntR* chFIDR = GetParticleChannelFileIDIntegerRInterface( pCont );
        if( chFIDR == NULL ) {
            throw std::runtime_error( "PFOperatorFileBirth: Could not set up the interface to FileIDIntegerR" );

        } // can't read

        // On a missing file, don't reset the ID cache or flag particles for deletion, just let
        // the particles keep doing whatever they were doing. If you get an empty file, that's when
        // you delete everything.  This should allow me to do subframe birthing/updating whenever
        // a file is present in an interval without any kind of behavioural conflicts.
        if( !files::file_exists( targetFile ) ) {
            // TODO: some icon notifying that there is no file for this time.
            return false;
        }

        // Read the particles from the file

        // first I need to check that the file has ID info
        channel_map pcm;
        shared_ptr<particle_istream> pin = frantic::particles::particle_file_istream_factory( targetFile );
        pcm = pin->get_channel_map();
        bool hasID = false;
        if( pcm.has_channel( "ID" ) )
            hasID = true;

        // set up the stream to read birth particle info
        BirthParticle::define_channel_map( pcm );
        pcm.end_channel_definition( 1, true );
        pin.reset();
        pin = frantic::particles::particle_file_istream_factory( targetFile, pcm );

        float particleCountMultiplier = 1.0f; // pfSys->GetMultiplier(timeStart);
        int particlesLimit = pfSys->GetBornAllowance() - poExt->NumParticlesGenerated();
        bool evenlyDistributeLoading = true;
        if( pin->particle_count() > 0 )
            pin = apply_fractional_particle_istream( pin, particleCountMultiplier, particlesLimit,
                                                     evenlyDistributeLoading );

        // if the file has no particles, flag all the pflow ones for deletion and return
        int pflowCount = chAmountR->Count(); // Number of current pflow particles
        if( pin->particle_count() == 0 ) {
            for( int i = 0; i < pflowCount; i++ )
                chFIDW->SetValue( i, -1 );
            m_lastIDs.clear();
            return true;
        }

        bool useNodeTransform = ( pblock()->GetInt( kFileBirth_linktoobjecttm ) != FALSE );
        if( useNodeTransform && pNode )
            pin = frantic::max3d::particles::transform_stream_with_inode( pNode, timeStart,
                                                                          ( timeEnd - timeStart ).TimeValue(), pin );

        BirthParticle buffer[NUM_BUFFERED_PARTICLES]; // Temporary storage

        unsigned counter;  // Counts the number of particles in a reading batch
        int fileCount = 0; // Counts total number of particles read from file

        vector<BirthParticle> particles; // Local storage of particles from file
        vector<idPair> fileID;           // Indices and IDs of file particles
        vector<idPair> pflowID;          // Indices and IDs of pflow particles

        // We don't know how many particles we are reading...do batches?
        if( pin->particle_count() < 0 ) {
            do {

                BirthParticle* pParticle = &buffer[0];
                for( counter = 0; counter < NUM_BUFFERED_PARTICLES; ++counter ) {
                    if( !pin->get_particle( (char*)( pParticle++ ) ) )
                        break;
                }

                if( counter == 0 )
                    break;

                // build id info
                fileID.resize( fileID.size() + counter );
                for( unsigned i = 0; i < counter; i++ ) {
                    fileID[fileCount + i].index = fileCount + i;
                    if( hasID )
                        fileID[fileCount + i].id = buffer[i].id;
                    else
                        fileID[fileCount + i].id = fileCount + i;
                }

                // temp store of particle info
                particles.resize( particles.size() + counter );
                memcpy( &particles[fileCount], &buffer[0], counter * sizeof( BirthParticle ) );
                fileCount += counter;

            } while( counter == NUM_BUFFERED_PARTICLES ); // Keep writing particles until we find a non-full batch

        }
        // Positive particle count, we know how many.
        else {
            fileCount = (int)pin->particle_count();
            particles.resize( fileCount );
            fileID.resize( fileCount );
            BirthParticle pParticle;
            for( int i = 0; i < fileCount; i++ ) {
                // temp store of particle info
                pin->get_particle( (char*)&pParticle );
                particles[i] = pParticle;
                // build id info
                fileID[i].index = i;
                if( hasID )
                    fileID[i].id = pParticle.id;
                else
                    fileID[i].id = i;
            }
        }

        // reset the ID cache if we are going backward or not moving.  the proceed function of this
        // operator appears to be called when other things get updated.  this means that all the
        // particles will be marked incorrectly for deletion if the ID cache isn't wiped between
        // calls at the same time.
        if( m_lastTimeValue >= timeStart.tick ) {
            m_lastIDs.clear();
        }
        m_lastTimeValue = timeStart.tick;

        // Grab all the pflow particle indices/ids
        pflowID.resize( pflowCount );
        for( int i = 0; i < pflowCount; i++ ) {
            pflowID[i].index = i;
            pflowID[i].id = chFIDR->GetValue( i ); // grab the particle's file ID
        }

        // sort the file index/ID pairs by ID
        std::sort( fileID.begin(), fileID.end(), &KrakatoaPFFileBirth::sortFunction );
        std::sort( pflowID.begin(), pflowID.end(), &KrakatoaPFFileBirth::sortFunction );

        // step through the sorted IDs leaving pflow particles that still exist, and flagging the particles
        // that need to be killed.
        size_t fileCounter = 0, pflowCounter = 0;
        size_t lastIDCounter = 0;
        bool done = false;

        vector<size_t> particlesToAdd( 0 );
        while( !done ) {

            if( fileCounter >= fileID.size() || pflowCounter >= pflowID.size() ) {
                // we hit the end of one of the ID arrays
                done = true;
            } else if( pflowID[pflowCounter].id == fileID[fileCounter].id ) {
                // we found an ID match, no add or delete necessary
                pflowCounter++;
                fileCounter++;
            } else if( pflowID[pflowCounter].id < fileID[fileCounter].id ) {
                // the pflow particle no longer exists in the file, flag it for deletion and
                // increment the pflow counter
                chFIDW->SetValue( pflowID[pflowCounter].index, -1 );
                pflowCounter++;
            } else if( fileID[fileCounter].id < pflowID[pflowCounter].id ) {
                // the file ID doesn't exist in the pflow ID list, so add the particle, as long as it wasn't
                // in the last file
                while( lastIDCounter < m_lastIDs.size() && m_lastIDs[lastIDCounter].id < fileID[fileCounter].id )
                    lastIDCounter++;
                if( lastIDCounter == m_lastIDs.size() || m_lastIDs[lastIDCounter].id != fileID[fileCounter].id )
                    particlesToAdd.push_back( fileCounter );
                fileCounter++;
            }
        }

        // since you might have just hit the end of one of the arrays, loop through the remaining
        // particles in each array and either add or flag them for deletion
        while( pflowCounter < pflowID.size() ) {
            chFIDW->SetValue( pflowID[pflowCounter].index, -1 );
            pflowCounter++;
        }

        while( fileCounter < fileID.size() ) {
            // the file ID doesn't exist in the pflow ID list, so add the particle, as long as it wasn't
            // in the last file
            while( lastIDCounter < m_lastIDs.size() && m_lastIDs[lastIDCounter].id < fileID[fileCounter].id )
                lastIDCounter++;
            if( lastIDCounter == m_lastIDs.size() || m_lastIDs[lastIDCounter].id != fileID[fileCounter].id )
                particlesToAdd.push_back( fileCounter );
            fileCounter++;
        }

        // Add the particles into pflow
        int newCount = int( particlesToAdd.size() );
        if( !chAmountW->AppendNum( newCount ) ) {
            mprintf( "PFOperatorFileBirth: Unable to append %d particles to the particle flow container.",
                     particlesToAdd.size() );
            throw std::runtime_error( "PFOperatorFileBirth: Unable to append " +
                                      boost::lexical_cast<string>( newCount ) +
                                      " particles to the particle flow container." );
            return false; // can't append new particles
        }

        for( int i = 0; i < newCount; i++ ) {
            int newIndex = pflowCount + i;
            chNewW->SetNew( newIndex );
            chTimeW->SetValue( newIndex, timeEnd );
            chIDW->SetID( newIndex, int( floor( ( numParticlesGen + i ) * indexRatio + 0.5f ) ), numParticlesGen + i );
            chBirthTimeW->SetValue( newIndex, timeEnd );
            chPosW->SetValue( newIndex, to_max_t( particles[fileID[particlesToAdd[i]].index].position ) );
            chFIDW->SetValue( newIndex, fileID[particlesToAdd[i]].id );
        }

        // swap the sorted array of ids for this file into the cache of last file IDs
        m_lastIDs.swap( fileID );

        return true;

    } catch( const std::exception& e ) {

        mprintf( "Error in KrakatoaPFFileBirth::Proceed()\n\t%s\n", e.what() );

        if( GetCOREInterface()->IsNetworkRenderServer() )
            throw MAXException( const_cast<char*>( e.what() ) );

        return false;
    }
}

ClassDesc* KrakatoaPFFileBirth::GetClassDesc() const { return GetKrakatoaPFFileBirthDesc(); }

void KrakatoaPFFileBirth::RefreshFilenameUI() const {
    if( pblock() == NULL )
        return;

    const MCHAR* str = pblock()->GetStr( kFileBirth_filepattern );
    if( !str )
        str = _T("");

    IParamMap2* map = pblock()->GetMap();
    if( ( map == NULL ) && ( NumPViewParamMaps() == 0 ) )
        return;

    HWND hWnd;
    if( map != NULL ) {
        hWnd = map->GetHWnd();
        if( hWnd ) {
            SendMessage( hWnd, WM_COMMAND, kFileBirth_message_filechoose, (LPARAM)str );
        }
    }

    for( int i = 0; i < NumPViewParamMaps(); i++ ) {
        hWnd = GetPViewParamMap( i )->GetHWnd();
        if( hWnd ) {
            SendMessage( hWnd, WM_COMMAND, kFileBirth_message_filechoose, (LPARAM)str );
        }
    }
}
#endif
