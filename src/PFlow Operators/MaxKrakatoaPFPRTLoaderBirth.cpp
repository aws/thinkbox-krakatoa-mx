// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0
#include "stdafx.h"

#include "resource.h"

#include "Objects\MaxKrakatoaPRTLoader.h"
#include "PFlow Operators\MaxKrakatoaExcludePFlowValidator.hpp"
#include "PFlow Operators\MaxKrakatoaPFPRTLoaderBirth.h"

#include <boost/assign.hpp>

#include <frantic/particles/particle_file_stream_factory.hpp>
#include <frantic/particles/particle_utilities.hpp>
#include <frantic/particles/streams/fractional_by_id_particle_istream.hpp>
#include <frantic/particles/streams/fractional_particle_istream.hpp>
#include <frantic/particles/streams/transformed_particle_istream.hpp>

#include <frantic/max3d/particles/particle_stream_factory.hpp>
#include <frantic/max3d/particles/particle_system_validator.hpp>

#include <krakatoa/max3d/PRTObject.hpp>

//#include <ParticleFlow/IPFActionState.h>

extern HINSTANCE hInstance;

// I don't like disabling warning 4239 (doing so promotes non cross-platform compatible code), but the Particle Flow SDK
// basically forces my hand here.
#pragma warning( disable : 4239 )

using namespace std;
// using namespace boost;
using namespace frantic;
using namespace frantic::graphics;
using namespace frantic::particles;
using namespace frantic::max3d::particles;
using namespace frantic::particles::streams;

using boost::shared_ptr;

HBITMAP KrakatoaPFPRTLoaderBirthDesc::m_depotIcon = NULL;
HBITMAP KrakatoaPFPRTLoaderBirthDesc::m_depotMask = NULL;

KrakatoaPFPRTLoaderBirthDesc::~KrakatoaPFPRTLoaderBirthDesc() {
    if( m_depotIcon != NULL ) {
        DeleteObject( m_depotIcon );
        m_depotIcon = NULL;
    }
    if( m_depotMask != NULL ) {
        DeleteObject( m_depotMask );
        m_depotMask = NULL;
    }
}

void* KrakatoaPFPRTLoaderBirthDesc::Create( BOOL /*loading*/ ) { return new KrakatoaPFPRTLoaderBirth(); }

INT_PTR KrakatoaPFPRTLoaderBirthDesc::Execute( int cmd, ULONG_PTR arg1, ULONG_PTR arg2, ULONG_PTR /*arg3*/ ) {
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
        *res = _T("Loads a set of particles from a selected PRT Object.");
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
            m_depotIcon = LoadBitmap( hInstance, MAKEINTRESOURCE( IDB_PRTLOADERBIRTH_ACTIVE_DEPOT ) );
        if( m_depotMask == NULL )
            m_depotMask = LoadBitmap( hInstance, MAKEINTRESOURCE( IDB_PRTLOADERBIRTH_MASK_DEPOT ) );
        *depotIcon = m_depotIcon;
        *depotMask = m_depotMask;
        break;
    default:
        return 0;
    }
    return 1;
}

// Each plug-in should have one instance of the ClassDesc class.
KrakatoaPFPRTLoaderBirthDesc TheKrakatoaPFPRTLoaderBirthDesc;
ClassDesc2* GetKrakatoaPFPRTLoaderBirthDesc() { return &TheKrakatoaPFPRTLoaderBirthDesc; }

// Dialog Proc
KrakatoaPFPRTLoaderBirthDlgProc TheKrakatoaPFPRTLoaderBirthDlgProc;

// SampleBirth Operator param block
ParamBlockDesc2 KrakatoaPFPRTLoaderBirth_paramBlockDesc(
    // required block spec
    kPRTLoaderBirth_mainPBlockIndex, _T("Parameters"), IDS_PARAMS, &TheKrakatoaPFPRTLoaderBirthDesc,
    P_AUTO_CONSTRUCT + P_AUTO_UI,
    // auto constuct block refno : none
    kPRTLoaderBirth_mainPBlockIndex,
    // auto ui parammap specs : none
    IDD_PRTLOADERBIRTH_PARAMETERS, IDS_PARAMS, 0,
    0, // open/closed
    &TheKrakatoaPFPRTLoaderBirthDlgProc,

    kPRTLoaderBirth_pick_PRT_loader, _T("PickPRTLoader"), TYPE_INODE, 0, IDS_PRTLOADERBIRTH_PICK_PRT_LOADER, p_ui,
    TYPE_PICKNODEBUTTON, IDC_PRTLOADERBIRTH_PICK_PRT_LOADER, p_validator, GetMaxKrakatoaExcludePFlowValidator(), p_end,

    p_end );

INT_PTR KrakatoaPFPRTLoaderBirthDlgProc::DlgProc( TimeValue t, IParamMap2* map, HWND /*hWnd*/, UINT msg, WPARAM wParam,
                                                  LPARAM /*lParam*/ ) {
    TSTR buf;
    switch( msg ) {
    case WM_INITDIALOG:
        break;
    case WM_DESTROY:
        break;
    case WM_COMMAND:
        switch( LOWORD( wParam ) ) {
        case IDC_PRTLOADERBIRTH_CLEAR_PRT_LOADER:
            // Clear the selected node entry in the param block.
            map->GetParamBlock()->SetValue( kPRTLoaderBirth_pick_PRT_loader, t, (INode*)NULL );
            map->GetParamBlock()->NotifyDependents( FOREVER, 0, IDC_PRTLOADERBIRTH_CLEAR_PRT_LOADER );
            break;
        }
        break;
    }
    return FALSE;
}

//+>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>+
//|							From PRTLoaderBirth |
//+>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>+
KrakatoaPFPRTLoaderBirth::KrakatoaPFPRTLoaderBirth() {
    GetClassDesc()->MakeAutoParamBlocks( this );
    m_pPrevLoader = NULL;
}

// We need to save a backpatch ID of the pointer that is cached to the previous node.
IOResult KrakatoaPFPRTLoaderBirth::Save( ISave* isave ) {
    int refID = -1;
    if( m_pPrevLoader )
        refID = isave->GetRefID( m_pPrevLoader );

    ULONG nWritten;
    IOResult status;

    isave->BeginChunk( 0 );
    status = isave->Write( &refID, sizeof( refID ), &nWritten );
    if( status != IO_OK )
        return status;
    isave->EndChunk();

    return PFSimpleOperator::Save( isave );
}

// We need to backpatch the cached pointer to the last picked PRT Loader node.
IOResult KrakatoaPFPRTLoaderBirth::Load( ILoad* iload ) {
    ULONG nRead;
    int refID = -1;
    IOResult status;

    status = iload->OpenChunk();
    while( status != IO_END ) {
        switch( iload->CurChunkID() ) {
        case 0:
            status = iload->Read( &refID, sizeof( refID ), &nRead );
            if( status != IO_OK )
                return status;
            break;
        }

        status = iload->CloseChunk();
        if( status != IO_OK )
            return status;

        status = iload->OpenChunk();
        if( status == IO_ERROR )
            return status;
    }

    if( refID != -1 )
        iload->RecordBackpatch( refID, (void**)&m_pPrevLoader );
    return PFSimpleOperator::Load( iload );
}

bool KrakatoaPFPRTLoaderBirth::IsEmitterTMDependent() const { return false; }

class MyState : public IObject, public IPFActionState {
  public:
    MyState();

    void CopyFrom( const MyState& other );

    TimeValue GetTime() const;
    void SetTime( TimeValue t );

    const std::vector<idPair>& GetLastIDs();
    void SwapLastIDs( std::vector<idPair>& newIDs );
    void ClearLastIDs();

    // From IObject::BaseInterfaceServer
    virtual int NumInterfaces() const;
    virtual BaseInterface* GetInterfaceAt( int index ) const;
    virtual BaseInterface* GetInterface( Interface_ID id );

    // From IObject
    virtual void AcquireIObject();
    virtual void ReleaseIObject();
    virtual void DeleteIObject();

    // From IPFActionState
    virtual Class_ID GetClassID();
    virtual ULONG GetActionHandle() const;
    virtual void SetActionHandle( ULONG actionHandle );
    virtual IOResult Save( ISave* isave ) const;
    virtual IOResult Load( ILoad* iload );

  private:
    volatile LONG m_refCount;
    ULONG m_handle;

    TimeValue m_t;
    std::vector<idPair> m_lastIDs;
};

MyState::MyState()
    : m_refCount( 0 )
    , m_handle( -1 )
    , m_t( TIME_NegInfinity ) {}

void MyState::CopyFrom( const MyState& other ) {
    assert( &other != NULL );

    m_t = other.m_t;
    m_lastIDs = other.m_lastIDs; // Could probably steal them really ...
}

TimeValue MyState::GetTime() const { return m_t; }

void MyState::SetTime( TimeValue t ) { m_t = t; }

const std::vector<idPair>& MyState::GetLastIDs() { return m_lastIDs; }

void MyState::SwapLastIDs( std::vector<idPair>& newIDs ) { m_lastIDs.swap( newIDs ); }

void MyState::ClearLastIDs() { m_lastIDs.clear(); }

int MyState::NumInterfaces() const { return 1; }

BaseInterface* MyState::GetInterfaceAt( int i ) const {
    return i == 0 ? const_cast<MyState*>( this )->GetInterface( PFACTIONSTATE_INTERFACE ) : NULL;
}

BaseInterface* MyState::GetInterface( Interface_ID id ) {
    if( id == PFACTIONSTATE_INTERFACE )
        return static_cast<IPFActionState*>( this );
    return IObject::GetInterface( id );
}

void MyState::AcquireIObject() { InterlockedIncrement( &m_refCount ); }

void MyState::ReleaseIObject() {
    if( 0 == InterlockedDecrement( &m_refCount ) )
        this->DeleteIObject();
}

void MyState::DeleteIObject() { delete this; }

#define MYSTATE_ID Class_ID( 0x74160ffb, 0x72d12f2a )

Class_ID MyState::GetClassID() { return MYSTATE_ID; }

ULONG MyState::GetActionHandle() const { return m_handle; }

void MyState::SetActionHandle( ULONG actionHandle ) { m_handle = actionHandle; }

IOResult MyState::Save( ISave* isave ) const {
    ULONG nb = 0;
    IOResult res = IO_OK;

    isave->BeginChunk( IPFActionState::kChunkActionHandle );

    isave->Write( &m_handle, sizeof( ULONG ), &nb );
    if( res != IO_OK )
        return res;

    isave->EndChunk();

    return res;
}

IOResult MyState::Load( ILoad* iload ) {
    IOResult res = iload->OpenChunk();
    ULONG nb = 0;

    while( IO_OK == res ) {
        switch( iload->CurChunkID() ) {
        case IPFActionState::kChunkActionHandle:
            res = iload->Read( &m_handle, sizeof( ULONG ), &nb );
            break;
        }

        if( IO_OK == res )
            res = iload->OpenChunk();
    }

    return res;
}

IObject* KrakatoaPFPRTLoaderBirth::GetCurrentState( IObject* pContainer ) {
    std::map<IObject*, IObject*>::const_iterator it = m_stateMap.find( pContainer );

    std::auto_ptr<MyState> newState( new MyState );

    if( it != m_stateMap.end() )
        newState->CopyFrom( *static_cast<MyState*>( it->second ) );

    return newState.release();
}

void KrakatoaPFPRTLoaderBirth::SetCurrentState( IObject* actionState, IObject* pContainer ) {
    if( !actionState )
        return;

    if( IPFActionState* pState =
            static_cast<IPFActionState*>( actionState->GetInterface( PFACTIONSTATE_INTERFACE ) ) ) {
        if( pState->GetClassID() == MYSTATE_ID ) {
            std::map<IObject*, IObject*>::iterator it = m_stateMap.lower_bound( pContainer );
            if( it == m_stateMap.end() || it->first != pContainer ) {
                std::auto_ptr<MyState> newState( new MyState );

                it = m_stateMap.insert( it, std::pair<IObject*, IObject*>( pContainer, newState.get() ) );

                newState->AcquireInterface();
                newState.release();
            }

            static_cast<MyState*>( it->second )->CopyFrom( *static_cast<MyState*>( actionState ) );
        }
    }
}

#if MAX_VERSION_MAJOR < 24
void KrakatoaPFPRTLoaderBirth::GetClassName( TSTR& s )
#else
void KrakatoaPFPRTLoaderBirth::GetClassName( TSTR& s, bool localized )
#endif
{
    s = GetKrakatoaPFPRTLoaderBirthDesc()->ClassName();
}

Class_ID KrakatoaPFPRTLoaderBirth::ClassID() { return KrakatoaPFPRTLoaderBirth_Class_ID; }

void KrakatoaPFPRTLoaderBirth::BeginEditParams( IObjParam* ip, ULONG flags, Animatable* prev ) {
    GetClassDesc()->BeginEditParams( ip, this, flags, prev );
}

void KrakatoaPFPRTLoaderBirth::EndEditParams( IObjParam* ip, ULONG flags, Animatable* next ) {
    GetClassDesc()->EndEditParams( ip, this, flags, next );
}

RefResult KrakatoaPFPRTLoaderBirth::NotifyRefChanged( const Interval& /*changeInt*/, RefTargetHandle hTarget,
                                                      PartID& /*partID*/, RefMessage message, BOOL /*propagate*/ ) {
    try {
        switch( message ) {
        case REFMSG_CHANGE:
            if( hTarget == pblock() ) {
                int lastUpdateID = pblock()->LastNotifyParamID();
                switch( lastUpdateID ) {
                case kPRTLoaderBirth_pick_PRT_loader: {
                    // query the source for a particle channel map when it gets changed and stick it in
                    // the member variable
                    TimeValue currentTime = GetCOREInterface()->GetTime();

                    INode* prtLoaderNode = pblock()->GetINode( kPRTLoaderBirth_pick_PRT_loader, currentTime );

                    if( prtLoaderNode ) {
                        if( CheckForBadPRTSourceReference( prtLoaderNode, m_pblock, kTargetNode,
                                                           frantic::tstring( _T( "Krakatoa PRT Birth" ) ) ) ) {
                            break;
                        }
                    }

                    // Cache the previously seen loader so that I can tell if a
                    // entirely new node has been picked. I hope there is an easier way
                    // than this.
                    bool isNewObj = ( m_pPrevLoader != prtLoaderNode );
                    m_pPrevLoader = prtLoaderNode;

                    if( !prtLoaderNode )
                        break;

                    if( !frantic::max3d::particles::is_particle_istream_source( prtLoaderNode, currentTime ) )
                        break;

                    frantic::channels::channel_map nativeChannelMap;
                    channel_map pcm;
                    BirthParticle::define_channel_map( pcm );
                    pcm.end_channel_definition( 1, true );

                    boost::shared_ptr<frantic::particles::streams::particle_istream> pin =
                        frantic::max3d::particles::max_particle_istream_factory( prtLoaderNode, pcm, currentTime, 0 );

                    nativeChannelMap = pin->get_native_channel_map();

                    if( isNewObj ) {
                        if( !nativeChannelMap.has_channel( _T("ID") ) ) {
                            static const TCHAR* NO_ID_ERROR_HEADER = _T("Krakatoa PRTLoaderBirth WARNING");
                            static const TCHAR* NO_ID_ERROR_MSG =
                                _T("WARNING:  The selected Krakatoa particle object has no ID channel.  Particles ")
                                _T("will be assigned IDs based upon the order that they appear in the file.");

                            LogSys* log = GetCOREInterface()->Log();
                            if( log )
                                log->LogEntry( SYSLOG_WARN, DISPLAY_DIALOG, (TCHAR*)NO_ID_ERROR_HEADER,
                                               (TCHAR*)NO_ID_ERROR_MSG );
                        }
                        /*if( prtLoaderNode->Renderable() ){
                                static const TCHAR* RENDERABLE_ERROR_HEADER = _T("Krakatoa PRTLoaderBirth WARNING");
                                static const TCHAR* RENDERABLE_ERROR_MSG = _T("WARNING:  The selected Krakatoa particle
                        object is currently renderable.\nIf you do not want the source's particles rendered in addition
                        to the Particle Flow particles, you need to disable the 'Renderable' checkbox in the source
                        node's Object Properties.\n\nClick 'Yes' if you would like this done for you automatically right
                        now.\nClick 'No' if you would like to do this manually later.");

                                LogSys* log = GetCOREInterface()->Log();
                                if( log )
                                        log->LogEntry( SYSLOG_WARN, NO_DIALOG, (TCHAR*)RENDERABLE_ERROR_HEADER,
                        (TCHAR*)RENDERABLE_ERROR_MSG );

                                int result = MessageBox( GetCOREInterface()->GetMAXHWnd(), RENDERABLE_ERROR_MSG,
                        RENDERABLE_ERROR_HEADER, MB_YESNO|MB_ICONWARNING ); switch ( result ){ case IDYES:
                                                prtLoaderNode->SetRenderable(false);
                                                break;
                                        case IDNO:
                                        default:
                                                break;
                                }
                        }*/
                    }
                }
                }
                UpdatePViewUI( static_cast<ParamID>( lastUpdateID ) );
            }
            break;
        }
        return REF_SUCCEED;
    } catch( const std::exception& e ) {
        FF_LOG( error ) << _T("Error in KrakatoaPFPRTLoaderBirth::NotifyRefChanged()\n\t")
                        << HANDLE_STD_EXCEPTION_MSG( e ) << std::endl;
        GetCOREInterface()->Log()->LogEntry( SYSLOG_ERROR, DISPLAY_DIALOG,
                                             _T("KrakatoaPFPRTLoaderBirth::NotifyRefChanged() Error"),
                                             HANDLE_STD_EXCEPTION_MSG( e ) );
        if( IsNetworkRenderServer() )
            throw MAXException( HANDLE_STD_EXCEPTION_MSG( e ) );
        return REF_STOP;
    }
}

RefTargetHandle KrakatoaPFPRTLoaderBirth::Clone( RemapDir& remap ) {
    KrakatoaPFPRTLoaderBirth* newOp = new KrakatoaPFPRTLoaderBirth();
    newOp->ReplaceReference( 0, remap.CloneRef( pblock() ) );
    BaseClone( this, newOp, remap );
    return newOp;
}

#if MAX_VERSION_MAJOR >= 24
const TCHAR* KrakatoaPFPRTLoaderBirth::GetObjectName( bool localized ) const {
#elif MAX_VERSION_MAJOR >= 15
const TCHAR* KrakatoaPFPRTLoaderBirth::GetObjectName() {
#else
TCHAR* KrakatoaPFPRTLoaderBirth::GetObjectName() {
#endif
    return GetString( IDS_PRTLOADERBIRTH_CLASSNAME );
}

const ParticleChannelMask& KrakatoaPFPRTLoaderBirth::ChannelsUsed( const Interval& /*time*/ ) const {
    //  read    &	write channels
    static ParticleChannelMask mask( PCU_Amount,
                                     PCU_Amount | PCU_New | PCU_ID | PCU_Time | PCU_BirthTime | PCU_Position );
    return mask;
}

const Interval KrakatoaPFPRTLoaderBirth::ActivityInterval() const {
    Interval interval;
    interval = GetCOREInterface()->GetAnimRange();
    return interval;
    // return Interval( interval.Start() - GetTicksPerFrame() * 2, interval.End() );
}

//+--------------------------------------------------------------------------+
//|							From IPViewItem
//|
//+--------------------------------------------------------------------------+
HBITMAP KrakatoaPFPRTLoaderBirth::GetActivePViewIcon() {
    if( activeIcon() == NULL )
        _activeIcon() = (HBITMAP)LoadImage( hInstance, MAKEINTRESOURCE( IDB_PRTLOADERBIRTH_ACTIVE ), IMAGE_BITMAP,
                                            kActionImageWidth, kActionImageHeight, LR_SHARED );
    return activeIcon();
}

//+--------------------------------------------------------------------------+
//|							From IPViewItem
//|
//+--------------------------------------------------------------------------+
HBITMAP KrakatoaPFPRTLoaderBirth::GetInactivePViewIcon() {
    if( inactiveIcon() == NULL )
        _inactiveIcon() = (HBITMAP)LoadImage( hInstance, MAKEINTRESOURCE( IDB_PRTLOADERBIRTH_INACTIVE ), IMAGE_BITMAP,
                                              kActionImageWidth, kActionImageHeight, LR_SHARED );
    return inactiveIcon();
}

bool KrakatoaPFPRTLoaderBirth::Proceed( IObject* pCont,
                                        PreciseTimeValue timeStart, // interval start to produce particles (exclusive)
                                        PreciseTimeValue& timeEnd,  // interval end to produce particles (inclusive)
                                        Object* pSystem, INode* /*pNode*/, // inode of the emitter
                                        INode* /*actionNode*/,             // inode of the operator
                                        IPFIntegrator* /*integrator*/ ) {
    try {
        // MyState* pState = static_cast<MyState*>( this->GetCurrentState( pCont ) );
        std::map<IObject*, IObject*>::iterator it = m_stateMap.lower_bound( pCont );
        if( it == m_stateMap.end() || it->first != pCont ) {
            std::auto_ptr<MyState> newState( new MyState );

            it = m_stateMap.insert( it, std::pair<IObject*, IObject*>( pCont, newState.get() ) );

            newState->AcquireInterface();
            newState.release();
        }

        MyState& myState = *static_cast<MyState*>( it->second );

        assert( &myState != NULL );

        IParticleObjectExt* poExt = GetParticleObjectExtInterface( GetPFObject( pSystem ) );
        if( poExt == NULL ) {
            throw std::runtime_error( "PFOperatorPRTLoaderBirth: Could not set up the interface to ParticleObjectExt" );
            return false; // no handle for ParticleObjectExt interface
        }
        IPFSystem* pfSys = GetPFSystemInterface( pSystem );
        if( pfSys == NULL ) {
            throw std::runtime_error( "PFOperatorPRTLoaderBirth: Could not set up the interface to PFSystem" );
            return false; // no handle for PFSystem interface
        }

        int numParticlesGen = poExt->NumParticlesGenerated();

        // force a particle multiplier of 100% for file operations
        float mult = 1.0f;
        float indexRatio = 1.0f / mult;

        TimeValue evalTime = timeEnd;
        // int frameNumber = (int)ceil(double(evalTime) / (double)GetTicksPerFrame());
        // int frameNumber = (evalTime + GetTicksPeFrFrame()/2) / GetTicksPerFrame();

        // set up the input particle stream (from file or from a PRT Loader)
        boost::shared_ptr<particle_istream> pin;
        INode* prtLoaderNode = pblock()->GetINode( kPRTLoaderBirth_pick_PRT_loader, evalTime );
        bool hasID = false;

        frantic::max3d::particles::IMaxKrakatoaPRTEvalContextPtr theContext;

        if( prtLoaderNode == NULL )
            return false;

        if( CheckForBadPRTSourceReference( prtLoaderNode, m_pblock, kTargetNode,
                                           frantic::tstring( _T( "Krakatoa PRT Birth" ) ) ) ) {
            return false;
        }

        channel_map pcm;
        BirthParticle::define_channel_map( pcm );
        pcm.end_channel_definition( 1, true );

        pin = frantic::max3d::particles::max_particle_istream_factory( prtLoaderNode, pcm, evalTime, 0 );

        if( pin->get_native_channel_map().has_channel( _T("ID") ) )
            hasID = true;

        //-----------------------------------------------
        // Ensure access to the required particle channels
        //-----------------------------------------------

        // Make sure we can check on the current particles in the container
        IParticleChannelAmountR* chAmountR = GetParticleChannelAmountRInterface( pCont );
        if( chAmountR == NULL ) {
            throw std::runtime_error(
                "PFOperatorPRTLoaderBirth: Could not set up the interface to IParticleChannelAmountR" );
            return false;
        }

        // Make sure we can add new particles to this container
        IParticleChannelAmountW* chAmountW = GetParticleChannelAmountWInterface( pCont );
        if( chAmountW == NULL ) {
            throw std::runtime_error(
                "PFOperatorPRTLoaderBirth: Could not set up the interface to IParticleChannelAmountR" );
            return false;
        }

        // Get access to ChannelContainer interface
        IChannelContainer* chCont;
        chCont = GetChannelContainerInterface( pCont );
        if( chCont == NULL ) {
            throw std::runtime_error( "PFOperatorPRTLoaderBirth: Could not set up the interface to ChannelContainer" );
            return false;
        }

        IParticleChannelNewW* chNewW =
            (IParticleChannelNewW*)chCont->EnsureInterface( PARTICLECHANNELNEWW_INTERFACE, ParticleChannelNew_Class_ID,
                                                            false, Interface_ID( 0, 0 ), Interface_ID( 0, 0 ) );
        if( chNewW == NULL ) {
            throw std::runtime_error(
                "PFOperatorPRTLoaderBirth: Could not set up the interface to ParticleChannelNewW" );
            return false;
        };

        IParticleChannelPTVW* chTimeW = (IParticleChannelPTVW*)chCont->EnsureInterface(
            PARTICLECHANNELTIMEW_INTERFACE, ParticleChannelPTV_Class_ID, true, PARTICLECHANNELTIMER_INTERFACE,
            PARTICLECHANNELTIMEW_INTERFACE );
        if( chTimeW == NULL ) {
            throw std::runtime_error(
                "PFOperatorPRTLoaderBirth: Could not set up the interface to ParticleChannelTimeW" );
            return false;
        }

        IParticleChannelIDW* chIDW =
            (IParticleChannelIDW*)chCont->EnsureInterface( PARTICLECHANNELIDW_INTERFACE, ParticleChannelID_Class_ID,
                                                           false, Interface_ID( 0, 0 ), Interface_ID( 0, 0 ) );
        if( chIDW == NULL ) {
            throw std::runtime_error(
                "PFOperatorPRTLoaderBirth: Could not set up the interface to ParticleChannelIDW" );
            return false;
        }
        IParticleChannelIDR* chIDR = GetParticleChannelIDRInterface( pCont );
        if( chIDR == NULL ) {
            throw std::runtime_error(
                "PFOperatorPRTLoaderBirth: Could not set up the interface to ParticleChannelIDR" );
            return false;
        } // can't read particle ID

        IParticleChannelPTVW* chBirthTimeW = (IParticleChannelPTVW*)chCont->EnsureInterface(
            PARTICLECHANNELBIRTHTIMEW_INTERFACE, ParticleChannelPTV_Class_ID, true, PARTICLECHANNELBIRTHTIMER_INTERFACE,
            PARTICLECHANNELBIRTHTIMEW_INTERFACE );
        if( chBirthTimeW == NULL ) {
            throw std::runtime_error(
                "PFOperatorPRTLoaderBirth: Could not set up the interface to ParticleChannelBirthTimeW" );
            return false;
        }

        IParticleChannelPoint3W* chPosW = (IParticleChannelPoint3W*)chCont->EnsureInterface(
            PARTICLECHANNELPOSITIONW_INTERFACE, ParticleChannelPoint3_Class_ID, true,
            PARTICLECHANNELPOSITIONR_INTERFACE, PARTICLECHANNELPOSITIONW_INTERFACE, true );
        if( chPosW == NULL ) {
            throw std::runtime_error(
                "PFOperatorPRTLoaderBirth: Could not set up the interface to ParticleChannelPositionW" );
            return false;
        }
        IParticleChannelPoint3R* chPosR = GetParticleChannelPositionRInterface( pCont );
        if( chPosR == NULL ) {
            throw std::runtime_error(
                "PFOperatorPRTLoaderBirth: Could not set up the interface to ParticleChannelPositionR" );
            return false;
        } // can't read

        IParticleChannelIntW* chFIDW = (IParticleChannelIntW*)chCont->EnsureInterface(
            PARTICLECHANNELFILEIDINTEGERW_INTERFACE, ParticleChannelInt_Class_ID, true,
            PARTICLECHANNELFILEIDINTEGERR_INTERFACE, PARTICLECHANNELFILEIDINTEGERW_INTERFACE, true );
        if( chFIDW == NULL ) {
            throw std::runtime_error( "PFOperatorPRTLoaderBirth: Could not set up the interface to FileIDIntegerW" );

        } // can't write
        IParticleChannelIntR* chFIDR = GetParticleChannelFileIDIntegerRInterface( pCont );
        if( chFIDR == NULL ) {
            throw std::runtime_error( "PFOperatorPRTLoaderBirth: Could not set up the interface to FileIDIntegerR" );

        } // can't read

        float particleCountMultiplier = pfSys->GetMultiplier( timeStart );
        int particlesLimit = pfSys->GetBornAllowance() - poExt->NumParticlesGenerated();

        // if the stream has no IDs, then do a typical fractional load.  this has no guarantees for
        // consistency and will only look decent if the particles are static and don't change order in the file
        // if (!pin->get_channel_map().has_channel(_T("ID")) && !pin->get_native_channel_map().has_channel(_T("ID")))
        if( !hasID )
            pin = apply_fractional_particle_istream( pin, particleCountMultiplier, particlesLimit, true );
        else
            pin = apply_fractional_by_id_particle_istream( pin, particleCountMultiplier, _T("ID"), particlesLimit );

        // if the file has no particles, flag all the pflow ones for deletion and return
        int pflowCount = chAmountR->Count(); // Number of current pflow particles
        if( pin->particle_count() == 0 ) {
            // If there are no particles in the stream, all of the previous particles died.
            for( int i = 0; i < pflowCount; i++ )
                chFIDW->SetValue( i, -1 );

            // Clear the "last ids" since we are seeing none in the current sample.
            myState.ClearLastIDs();
            myState.SetTime( timeStart.tick );
            return true;
        }

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
        TimeValue lastTime = myState.GetTime();
        if( lastTime >= timeStart.tick )
            myState.ClearLastIDs();

        myState.SetTime( timeStart.tick );

        // Grab all the pflow particle indices/ids
        pflowID.resize( pflowCount );
        for( int i = 0; i < pflowCount; i++ ) {
            pflowID[i].index = i;
            pflowID[i].id = chFIDR->GetValue( i ); // grab the particle's file ID
        }

        // sort the file index/ID pairs by ID
        std::sort( fileID.begin(), fileID.end(), &KrakatoaPFPRTLoaderBirth::sortFunction );
        std::sort( pflowID.begin(), pflowID.end(), &KrakatoaPFPRTLoaderBirth::sortFunction );

        // step through the sorted IDs leaving pflow particles that still exist, and flagging the particles
        // that need to be killed.
        size_t fileCounter = 0, pflowCounter = 0;
        size_t lastIDCounter = 0;
        bool done = false;

        const vector<idPair>& lastIDs = myState.GetLastIDs();

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
                while( lastIDCounter < lastIDs.size() && lastIDs[lastIDCounter].id < fileID[fileCounter].id )
                    lastIDCounter++;
                if( lastIDCounter == lastIDs.size() || lastIDs[lastIDCounter].id != fileID[fileCounter].id )
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
            while( lastIDCounter < lastIDs.size() && lastIDs[lastIDCounter].id < fileID[fileCounter].id )
                lastIDCounter++;
            if( lastIDCounter == lastIDs.size() || lastIDs[lastIDCounter].id != fileID[fileCounter].id )
                particlesToAdd.push_back( fileCounter );
            fileCounter++;
        }

        // Add the particles into pflow
        int newCount = int( particlesToAdd.size() );
        if( !chAmountW->AppendNum( newCount ) ) {
            throw std::runtime_error( "PFOperatorPRTLoaderBirth: Unable to append " +
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
            chPosW->SetValue( newIndex,
                              frantic::max3d::to_max_t( particles[fileID[particlesToAdd[i]].index].position ) );
            chFIDW->SetValue( newIndex, fileID[particlesToAdd[i]].id );
        }

        // swap the sorted array of ids for this file into the cache of last file IDs
        myState.SwapLastIDs( fileID );

        return true;

    } catch( const std::exception& e ) {
        FF_LOG( error ) << _T("Error in KrakatoaPFPRTLoaderBirth::Proceed()\n\t") << HANDLE_STD_EXCEPTION_MSG( e )
                        << std::endl;
        GetCOREInterface()->Log()->LogEntry( SYSLOG_ERROR, DISPLAY_DIALOG,
                                             _T("KrakatoaPFPRTLoaderBirth::Proceed() Error"),
                                             HANDLE_STD_EXCEPTION_MSG( e ) );
        if( IsNetworkRenderServer() )
            throw MAXException( HANDLE_STD_EXCEPTION_MSG( e ) );

        return false;
    }
}

ClassDesc* KrakatoaPFPRTLoaderBirth::GetClassDesc() const { return GetKrakatoaPFPRTLoaderBirthDesc(); }

//+>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>+
//|							Function Publishing System
//|
//+>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>+
static FPInterfaceDesc pflow_action_FPInterfaceDesc(
    PFACTION_INTERFACE, _T("action"), 0, GetKrakatoaPFPRTLoaderBirthDesc(), FP_MIXIN,

    IPFAction::kInit, _T("init"), 0, TYPE_bool, 0, 5, _T("container"), 0, TYPE_IOBJECT, _T("particleSystem"), 0,
    TYPE_OBJECT, _T("particleSystemNode"), 0, TYPE_INODE, _T("actions"), 0, TYPE_OBJECT_TAB_BR, _T("actionNodes"), 0,
    TYPE_INODE_TAB_BR, IPFAction::kRelease, _T("release"), 0, TYPE_bool, 0, 1, _T("container"), 0, TYPE_IOBJECT,
    // reserved for future use
    // IPFAction::kChannelsUsed, _T("channelsUsed"), 0, TYPE_VOID, 0, 2,
    //	_T("interval"), 0, TYPE_INTERVAL_BR,
    //	_T("channels"), 0, TYPE_FPVALUE,
    IPFAction::kActivityInterval, _T("activityInterval"), 0, TYPE_INTERVAL_BV, 0, 0, IPFAction::kIsFertile,
    _T("isFertile"), 0, TYPE_bool, 0, 0, IPFAction::kIsNonExecutable, _T("isNonExecutable"), 0, TYPE_bool, 0, 0,
    IPFAction::kSupportRand, _T("supportRand"), 0, TYPE_bool, 0, 0, IPFAction::kGetRand, _T("getRand"), 0, TYPE_INT, 0,
    0, IPFAction::kSetRand, _T("setRand"), 0, TYPE_VOID, 0, 1, _T("randomSeed"), 0, TYPE_INT, IPFAction::kNewRand,
    _T("newRand"), 0, TYPE_INT, 0, 0, IPFAction::kIsMaterialHolder, _T("isMaterialHolder"), 0, TYPE_bool, 0, 0,
    IPFAction::kSupportScriptWiring, _T("supportScriptWiring"), 0, TYPE_bool, 0, 0,

    p_end );

static FPInterfaceDesc pflow_operator_FPInterfaceDesc(
    PFOPERATOR_INTERFACE, _T("operator"), 0, GetKrakatoaPFPRTLoaderBirthDesc(), FP_MIXIN,

    IPFOperator::kProceed, _T("proceed"), 0, TYPE_bool, 0, 7, _T("container"), 0, TYPE_IOBJECT, _T("timeStart"), 0,
    TYPE_TIMEVALUE, _T("timeEnd"), 0, TYPE_TIMEVALUE_BR, _T("particleSystem"), 0, TYPE_OBJECT, _T("particleSystemNode"),
    0, TYPE_INODE, _T("actionNode"), 0, TYPE_INODE, _T("integrator"), 0, TYPE_INTERFACE,

    p_end );

static FPInterfaceDesc pflow_PViewItem_FPInterfaceDesc(
    PVIEWITEM_INTERFACE, _T("PViewItem"), 0, GetKrakatoaPFPRTLoaderBirthDesc(), FP_MIXIN,

    IPViewItem::kNumPViewParamBlocks, _T("numPViewParamBlocks"), 0, TYPE_INT, 0, 0, IPViewItem::kGetPViewParamBlock,
    _T("getPViewParamBlock"), 0, TYPE_REFTARG, 0, 1, _T("index"), 0, TYPE_INDEX, IPViewItem::kHasComments,
    _T("hasComments"), 0, TYPE_bool, 0, 1, _T("actionNode"), 0, TYPE_INODE, IPViewItem::kGetComments, _T("getComments"),
    0, TYPE_STRING, 0, 1, _T("actionNode"), 0, TYPE_INODE, IPViewItem::kSetComments, _T("setComments"), 0, TYPE_VOID, 0,
    2, _T("actionNode"), 0, TYPE_INODE, _T("comments"), 0, TYPE_STRING,

    p_end );

FPInterfaceDesc* KrakatoaPFPRTLoaderBirth::GetDescByID( Interface_ID id ) {
    if( id == PFACTION_INTERFACE )
        return &pflow_action_FPInterfaceDesc;
    if( id == PFOPERATOR_INTERFACE )
        return &pflow_operator_FPInterfaceDesc;
    if( id == PVIEWITEM_INTERFACE )
        return &pflow_PViewItem_FPInterfaceDesc;
    return NULL;
}
