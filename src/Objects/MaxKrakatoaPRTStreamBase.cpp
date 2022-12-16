// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0
#include "stdafx.h"
#ifdef DONTBUILD
#include "MaxKrakatoaMaterial.hpp"
#include "MaxKrakatoaReferenceTarget.h"
#include "MaxKrakatoaStdMaterialStream.h"

#include "Objects\MaxKrakatoaPRTInterface.h"

#include <frantic/particles/particle_array.hpp>
#include <frantic/particles/streams/apply_function_particle_istream.hpp>
#include <frantic/particles/streams/empty_particle_istream.hpp>
#include <frantic/particles/streams/particle_array_particle_istream.hpp>
#include <frantic/particles/streams/particle_istream.hpp>
#include <frantic/particles/streams/selection_culled_particle_istream.hpp>

#include <frantic/max3d/convert.hpp>

#pragma warning( disable : 4100 )

class MaxKrakatoaPRTPipelineObject;

#define MaxKrakatoaPRTPipelineObject_CLASS_NAME _T("PRTPipelineObject")
#define MaxKrakatoaPRTPipelineObject_CLASS_ID Class_ID( 0xe5b1c85, 0x7e966d67 )

static int numPipeObjs = 0;
static int numCachedPipeObjs = 0;

class stream_provider {
  public:
    virtual boost::shared_ptr<frantic::particles::streams::particle_istream> create_stream() = 0;
};

class shared_cache {
    boost::shared_ptr<frantic::particles::particle_array> m_pCacheData;

  public:
    shared_cache() {}
    ~shared_cache() {}

    void reset() { m_pCacheData.reset(); }

    void reset( frantic::particles::particle_array* pNewCache ) { m_pCacheData.reset( pNewCache ); }

    void steal( shared_cache& rhs ) {
        rhs.m_pCacheData = m_pCacheData;
        m_pCacheData.reset();
    }

    frantic::particles::particle_array* operator->() { return m_pCacheData.get(); }
};

class MaxKrakatoaPRTPipelineObject : public MaxKrakatoaReferenceTarget<GeomObject, MaxKrakatoaPRTPipelineObject> {
  protected:
    Box3 m_objectBounds;

    frantic::channels::channel_accessor<frantic::graphics::vector3f> m_posAccessor;
    frantic::channels::channel_accessor<frantic::graphics::color3f> m_colorAccessor;

    Interval m_cacheValidity;
    frantic::particles::particle_array m_particleCache;

  protected:
    virtual ClassDesc2* GetClassDesc();
    virtual void fill_cache( TimeValue t );

  public:
    // This object will be modified by modifiers (duh!) to create a chain of delegated
    // boost::shared_ptr<stream_provider> that can produce a particle_istream for the particles.
    boost::shared_ptr<stream_provider> m_particleStreamProvider;

    // Validity of the stream provider
    Interval m_objectValidity;

  public:
    MaxKrakatoaPRTPipelineObject();
    virtual ~MaxKrakatoaPRTPipelineObject();

    // From Animatable
    virtual int RenderBegin( TimeValue t, ULONG flags );
    virtual int RenderEnd( TimeValue t );
    virtual void FreeCaches();

    // From ReferenceMaker
    virtual RefResult NotifyRefChanged( const Interval&, RefTargetHandle, PartID&, RefMessage, BOOL );

    // From BaseObject
    virtual const TCHAR* GetObjectName() override;
    virtual int Display( TimeValue t, INode* inode, ViewExp* pView, int flags );
    virtual int HitTest( TimeValue t, INode* inode, int type, int crossing, int flags, IPoint2* p, ViewExp* vpt );
    virtual void GetWorldBoundBox( TimeValue t, INode* inode, ViewExp* vpt, Box3& box );
    virtual void GetLocalBoundBox( TimeValue t, INode* inode, ViewExp* vpt, Box3& box );
    virtual CreateMouseCallBack* GetCreateMouseCallBack( void );

    // From Object
    virtual void InitNodeName( MSTR& s );
    virtual void GetDeformBBox( TimeValue t, Box3& box, Matrix3* tm = NULL, BOOL useSel = FALSE );
    virtual Interval ObjectValidity( TimeValue t );
    virtual ObjectState Eval( TimeValue );

    virtual BOOL PolygonCount( TimeValue t, int& numFaces, int& numVerts );

    virtual void ReduceCaches( TimeValue t );
    virtual void ReduceDisplayCaches();

    virtual int CanConvertToType( Class_ID obtype );
    virtual Object* ConvertToType( TimeValue t, Class_ID obtype );

    // virtual BOOL  CanCacheObject () { return FALSE; }
    // virtual BOOL  IsWorldSpaceObject () { return TRUE; }

    virtual Object* MakeShallowCopy( ChannelMask channels );
    virtual void ShallowCopy( Object* fromOb, ChannelMask channels );
    virtual void FreeChannels( ChannelMask channels );
    virtual void NewAndCopyChannels( ChannelMask channels );
    // virtual void UpdateValidity( int nchan, Interval v );

    virtual Interval ChannelValidity( TimeValue t, int nchan );
    virtual void SetChannelValidity( int nchan, Interval v );
    virtual void InvalidateChannels( ChannelMask channels );

    // From GeomObject
    virtual Mesh* GetRenderMesh( TimeValue t, INode* inode, View& view, BOOL& needDelete );
};

class MaxKrakatoaPRTPipelineObjectDesc : public ClassDesc2 {
    ParamBlockDesc2* m_pParamDesc;

  public:
    MaxKrakatoaPRTPipelineObjectDesc();
    virtual ~MaxKrakatoaPRTPipelineObjectDesc();

    int IsPublic() { return FALSE; }
    void* Create( BOOL /*loading*/ ) { return new MaxKrakatoaPRTPipelineObject; }
    const TCHAR* ClassName() { return MaxKrakatoaPRTPipelineObject_CLASS_NAME; }
    SClass_ID SuperClassID() { return GEOMOBJECT_CLASS_ID; }
    Class_ID ClassID() { return MaxKrakatoaPRTPipelineObject_CLASS_ID; }
    const TCHAR* Category() { return _T("Krakatoa"); }

    const TCHAR* InternalName() {
        return MaxKrakatoaPRTPipelineObject_CLASS_NAME;
    }                                           // returns fixed parsable name (scripter-visible name)
    HINSTANCE HInstance() { return hInstance; } // returns owning module handle
};

ClassDesc2* GetMaxKrakatoaPRTPipelineObjectDesc() {
    static MaxKrakatoaPRTPipelineObjectDesc theDesc;
    return &theDesc;
}

MaxKrakatoaPRTPipelineObjectDesc::MaxKrakatoaPRTPipelineObjectDesc() {
    m_pParamDesc = new ParamBlockDesc2( 0,                            // Block num
                                        _T( "Parameters" ),           // Internal name
                                        NULL,                         // Localized name
                                        this,                         // ClassDesc2*
                                        P_AUTO_CONSTRUCT | P_VERSION, // Flags
                                        0,                            // Version
                                        0,                            // PBlock Ref Num
                                        p_end );
}

MaxKrakatoaPRTPipelineObjectDesc::~MaxKrakatoaPRTPipelineObjectDesc() {}

ClassDesc2* MaxKrakatoaPRTPipelineObject::GetClassDesc() { return GetMaxKrakatoaPRTPipelineObjectDesc(); }

void MaxKrakatoaPRTPipelineObject::fill_cache( TimeValue t ) {
    if( m_cacheValidity.InInterval( t ) )
        return;

    Eval( t );

    m_cacheValidity = m_objectValidity;

    frantic::channels::channel_map pcm;
    pcm.define_channel( _T( "Position" ), 3, frantic::channels::data_type_float32 );
    pcm.define_channel( _T( "Color" ), 3, frantic::channels::data_type_float32 );
    pcm.end_channel_definition();

    m_particleCache.reset( pcm );

    m_posAccessor = pcm.get_accessor<frantic::graphics::vector3f>( _T( "Position" ) );
    m_colorAccessor = pcm.get_accessor<frantic::graphics::color3f>( _T( "Color" ) );
    // TODO: Cache the velocity channel in order to do sub-frame times.

    if( m_particleStreamProvider )
        m_particleCache.insert_particles( m_particleStreamProvider->create_stream() );

    frantic::particles::particle_array_iterator it = m_particleCache.begin();
    frantic::particles::particle_array_iterator itEnd = m_particleCache.end();

    m_objectBounds.Init();
    for( ; it != itEnd; ++it )
        m_objectBounds += frantic::max3d::to_max_t( m_posAccessor.get( *it ) );
}

MaxKrakatoaPRTPipelineObject::MaxKrakatoaPRTPipelineObject() {
    m_cacheValidity = NEVER;
    m_objectValidity = FOREVER;
}

MaxKrakatoaPRTPipelineObject::~MaxKrakatoaPRTPipelineObject() {}

int MaxKrakatoaPRTPipelineObject::RenderBegin( TimeValue t, ULONG flags ) { return TRUE; }

int MaxKrakatoaPRTPipelineObject::RenderEnd( TimeValue t ) { return TRUE; }

void MaxKrakatoaPRTPipelineObject::FreeCaches() {
    m_particleCache.clear();
    m_cacheValidity = NEVER;
}

// From ReferenceMaker
RefResult MaxKrakatoaPRTPipelineObject::NotifyRefChanged( const Interval&, RefTargetHandle, PartID&, RefMessage,
                                                          BOOL ) {
    return REF_SUCCEED;
}

// From BaseObject
const TCHAR* MaxKrakatoaPRTPipelineObject::GetObjectName() { return _T( "" ); }

int MaxKrakatoaPRTPipelineObject::Display( TimeValue t, INode* inode, ViewExp* pView, int flags ) {
    try {
        if( inode->IsNodeHidden() || inode->GetBoxMode() )
            return TRUE;

        fill_cache( t );

        GraphicsWindow* gw = pView->getGW();
        DWORD rndLimits = gw->getRndLimits();

        frantic::particles::particle_array_iterator it = m_particleCache.begin();
        frantic::particles::particle_array_iterator itEnd = m_particleCache.end();

        Matrix3 tm = inode->GetNodeTM( t );
        gw->setTransform( tm );

        // TODO: Should this be batched? Should we have separate paths for different drivers?
        gw->startMarkers();
        for( ; it != itEnd; ++it ) {
            Point3 p = frantic::max3d::to_max_t( m_posAccessor.get( *it ) );
            Color c = frantic::max3d::to_max_t( m_colorAccessor.get( *it ) );
            gw->setColor( LINE_COLOR, c.r, c.g, c.b );
            gw->marker( &p, SM_DOT_MRKR );
        }
        gw->endMarkers();

        // Draw the particle count
        Point3 p = m_objectBounds.Max();

        std::basic_stringstream<TCHAR> viewportMessage;
        viewportMessage
            << _T( "Count: " ) << m_particleCache.size()
            << ' '; // Added the extra space since Max can't figure out how to NOT clip the end of the text off.
        if( inode->GetMtl() )
            viewportMessage << _T( "[mtl]" );

        gw->setColor( TEXT_COLOR, Color( 1, 1, 1 ) );
        gw->text( &p, const_cast<TCHAR*>( viewportMessage.str().c_str() ) );

        gw->setRndLimits( rndLimits );
    } catch( const std::exception& e ) {
        FF_LOG( error ) << e.what() << std::endl;
        return FALSE;
    }

    return TRUE;
}

int MaxKrakatoaPRTPipelineObject::HitTest( TimeValue t, INode* inode, int type, int crossing, int flags, IPoint2* p,
                                           ViewExp* vpt ) {
    fill_cache( t );
    return FALSE;
}

void MaxKrakatoaPRTPipelineObject::GetWorldBoundBox( TimeValue t, INode* inode, ViewExp* vpt, Box3& box ) {
    fill_cache( t );

    Matrix3 tm = inode->GetNodeTM( t );

    box = m_objectBounds * tm;
}

void MaxKrakatoaPRTPipelineObject::GetLocalBoundBox( TimeValue t, INode* inode, ViewExp* vpt, Box3& box ) {
    fill_cache( t );
    box = m_objectBounds;
}

CreateMouseCallBack* MaxKrakatoaPRTPipelineObject::GetCreateMouseCallBack( void ) { return NULL; }

// From Object
void MaxKrakatoaPRTPipelineObject::InitNodeName( MSTR& s ) {}

void MaxKrakatoaPRTPipelineObject::GetDeformBBox( TimeValue t, Box3& box, Matrix3* tm, BOOL useSel ) {
    fill_cache( t );
    if( tm )
        box = m_objectBounds * ( *tm );
    else
        box = m_objectBounds;
}

Interval MaxKrakatoaPRTPipelineObject::ObjectValidity( TimeValue t ) {
    Interval result = m_objectValidity;
    result &= MaxKrakatoaReferenceTarget<GeomObject, MaxKrakatoaPRTPipelineObject>::ObjectValidity( t );

    return result;
}

ObjectState MaxKrakatoaPRTPipelineObject::Eval( TimeValue ) { return ObjectState( this ); }

BOOL MaxKrakatoaPRTPipelineObject::PolygonCount( TimeValue t, int& numFaces, int& numVerts ) {
    fill_cache( t );

    numFaces = 0;
    numVerts = (int)m_particleCache.size();

    return TRUE;
}

void MaxKrakatoaPRTPipelineObject::ReduceCaches( TimeValue t ) {}

void MaxKrakatoaPRTPipelineObject::ReduceDisplayCaches() { FreeCaches(); }

int MaxKrakatoaPRTPipelineObject::CanConvertToType( Class_ID obtype ) {
    if( obtype == MaxKrakatoaPRTPipelineObject_CLASS_ID )
        return TRUE;
    return FALSE;
}

Object* MaxKrakatoaPRTPipelineObject::ConvertToType( TimeValue t, Class_ID obtype ) {
    if( obtype == MaxKrakatoaPRTPipelineObject_CLASS_ID )
        return this;
    return NULL;
}

Object* MaxKrakatoaPRTPipelineObject::MakeShallowCopy( ChannelMask channels ) {
    MaxKrakatoaPRTPipelineObject* pNewObj = new MaxKrakatoaPRTPipelineObject;
    pNewObj->ShallowCopy( this, channels );
    return pNewObj;
}

void MaxKrakatoaPRTPipelineObject::ShallowCopy( Object* fromOb, ChannelMask channels ) {
    Object::ShallowCopy( fromOb, channels );
    if( fromOb->IsSubClassOf( MaxKrakatoaPRTPipelineObject_CLASS_ID ) ) {
        MaxKrakatoaPRTPipelineObject* prtObj = static_cast<MaxKrakatoaPRTPipelineObject*>( fromOb );
        if( channels & GEOM_CHANNEL ) {
            m_particleStreamProvider = prtObj->m_particleStreamProvider;
        }
    }
}

void MaxKrakatoaPRTPipelineObject::FreeChannels( ChannelMask channels ) {
    Object::FreeChannels( channels );
    if( channels & GEOM_CHANNEL ) {
        m_particleStreamProvider.reset();
        m_particleCache.clear();
    }
}

void MaxKrakatoaPRTPipelineObject::NewAndCopyChannels( ChannelMask channels ) {
    Object::NewAndCopyChannels( channels );
    if( channels & GEOM_CHANNEL ) {
        // TODO: Clone?
    }
}

// void MaxKrakatoaPRTPipelineObject::UpdateValidity( int nchan, Interval v ){
//	if( nchan == GEOM_CHAN_NUM )
//		m_objectValidity &= v;
// }

Interval MaxKrakatoaPRTPipelineObject::ChannelValidity( TimeValue t, int nchan ) {
    if( nchan == GEOM_CHAN_NUM )
        return m_objectValidity;
    else if( IsBaseClassOwnedChannel( nchan ) )
        return MaxKrakatoaReferenceTarget<GeomObject, MaxKrakatoaPRTPipelineObject>::ChannelValidity( t, nchan );
    return FOREVER;
}

void MaxKrakatoaPRTPipelineObject::SetChannelValidity( int nchan, Interval v ) {
    if( nchan == GEOM_CHAN_NUM )
        m_objectValidity = v;
    MaxKrakatoaReferenceTarget<GeomObject, MaxKrakatoaPRTPipelineObject>::SetChannelValidity( nchan, v );
}

void MaxKrakatoaPRTPipelineObject::InvalidateChannels( ChannelMask channels ) {
    if( channels & GEOM_CHANNEL )
        m_objectValidity.SetEmpty();
    MaxKrakatoaReferenceTarget<GeomObject, MaxKrakatoaPRTPipelineObject>::InvalidateChannels( channels );
}

// From GeomObject
Mesh* MaxKrakatoaPRTPipelineObject::GetRenderMesh( TimeValue t, INode* inode, View& view, BOOL& needDelete ) {
    static Mesh* pEmptyMesh;
    if( !pEmptyMesh )
        pEmptyMesh = new Mesh;
    return pEmptyMesh;
}

class file_stream_provider : public stream_provider {
    frantic::tstring m_file;

  public:
    file_stream_provider() {
        m_file =
            _T( "C:\\Documents and Settings\\darcy.harrison\\My Documents\\particles\\FurryTeapot\\fur_particles_0000.prt" );
    }

    virtual stream_provider* clone() { return new file_stream_provider( *this ); }

    virtual boost::shared_ptr<frantic::particles::streams::particle_istream> create_stream() {
        return frantic::particles::particle_file_istream_factory( m_file );
    }
};

#define MaxKrakatoaPRTFileObject_CLASS_NAME _T("PRTFileObject")
#define MaxKrakatoaPRTFileObject_CLASS_ID Class_ID( 0xe5b1c86, 0x7e966d67 )

class MaxKrakatoaPRTFileObject : public MaxKrakatoaPRTPipelineObject {
  public:
    MaxKrakatoaPRTFileObject() { m_particleStreamProvider.reset( new file_stream_provider ); }

    // From Animatable
    virtual Class_ID ClassID() { return MaxKrakatoaPRTFileObject_CLASS_ID; }
    virtual void GetClassName( MSTR& s ) { s = MaxKrakatoaPRTFileObject_CLASS_NAME; }

    virtual BOOL IsSubClassOf( Class_ID classID ) {
        if( classID == MaxKrakatoaPRTPipelineObject_CLASS_ID )
            return TRUE;
        return MaxKrakatoaPRTPipelineObject::IsSubClassOf( classID );
    }

    BaseInterface* GetInterface( Interface_ID id ) { return MaxKrakatoaPRTPipelineObject::GetInterface( id ); }

    // From ReferenceTarget
    ReferenceTarget* MaxKrakatoaPRTFileObject::Clone( RemapDir& remap ) {
        MaxKrakatoaPRTFileObject* pOldObj = static_cast<MaxKrakatoaPRTFileObject*>( this );
        MaxKrakatoaPRTFileObject* pNewObj = new MaxKrakatoaPRTFileObject;
        for( int i = 0, iEnd = pNewObj->NumRefs(); i < iEnd; ++i )
            pNewObj->ReplaceReference( i, remap.CloneRef( pOldObj->GetReference( i ) ) );
        pOldObj->BaseClone( pOldObj, pNewObj, remap );
        return pNewObj;
    }

    // From BaseObject
    virtual const TCHAR* GetObjectName() { return MaxKrakatoaPRTFileObject_CLASS_NAME; }

    // From Object
    virtual void InitNodeName( MSTR& s ) { s = MaxKrakatoaPRTFileObject_CLASS_NAME; }
    // virtual Interval ObjectValidity(TimeValue t){ return FOREVER; }
    virtual ObjectState Eval( TimeValue t ) {
        if( m_objectValidity.InInterval( t ) ) {
            m_objectValidity = FOREVER;
            // TODO: Update m_particleStreamProvider if needed.
        }
        return ObjectState( this );
    }
};

class MaxKrakatoaPRTFileObjectDesc : public ClassDesc2 {
    ParamBlockDesc2* m_pParamDesc;

  public:
    MaxKrakatoaPRTFileObjectDesc() {}
    virtual ~MaxKrakatoaPRTFileObjectDesc() {}

    int IsPublic() { return TRUE; }
    void* Create( BOOL /*loading*/ ) { return new MaxKrakatoaPRTFileObject; }
    const TCHAR* ClassName() { return MaxKrakatoaPRTFileObject_CLASS_NAME; }
    SClass_ID SuperClassID() { return GEOMOBJECT_CLASS_ID; }
    Class_ID ClassID() { return MaxKrakatoaPRTFileObject_CLASS_ID; }
    const TCHAR* Category() { return _T("Krakatoa"); }

    const TCHAR* InternalName() {
        return MaxKrakatoaPRTFileObject_CLASS_NAME;
    }                                           // returns fixed parsable name (scripter-visible name)
    HINSTANCE HInstance() { return hInstance; } // returns owning module handle
};

ClassDesc2* GetMaxKrakatoaPRTFileObjectDesc() {
    static MaxKrakatoaPRTFileObjectDesc theDesc;
    return &theDesc;
}

#define MaxKrakatoaPRTCullMod_CLASS_NAME _T("PRTCullMod")
#define MaxKrakatoaPRTCullMod_CLASS_ID Class_ID( 0xe5b1c87, 0x7e966d67 )

class cull_stream_provider : public stream_provider {
    boost::shared_ptr<stream_provider> m_delegateProvider;

  public:
    cull_stream_provider( boost::shared_ptr<stream_provider> delegateProvider )
        : m_delegateProvider( delegateProvider ) {}

    static boost::array<frantic::tstring, 1> select_particle_inputs;
    static float select_particle( const frantic::graphics::vector3f& pos ) {
        if( fabs( pos.x ) < 10.f || fabs( pos.y ) < 10.f || fabs( pos.z ) < 10.f )
            return 1.f;
        return 0.f;
    }

    virtual boost::shared_ptr<frantic::particles::streams::particle_istream> create_stream() {
        if( !m_delegateProvider )
            return boost::shared_ptr<frantic::particles::streams::particle_istream>(
                new frantic::particles::streams::empty_particle_istream( frantic::channels::channel_map() ) );

        boost::shared_ptr<frantic::particles::streams::particle_istream> pResult = m_delegateProvider->create_stream();

        pResult.reset( new frantic::particles::streams::apply_function_particle_istream<float(
                           const frantic::graphics::vector3f& )>( pResult, &select_particle, _T( "Selection" ),
                                                                  select_particle_inputs ) );
        pResult.reset( new frantic::particles::streams::selection_culled_particle_istream( pResult, false ) );

        return pResult;
    }
};

boost::array<frantic::tstring, 1> cull_stream_provider::select_particle_inputs = { _T( "Position" ) };

class CullMod : public OSModifier {
  public:
    CullMod() {}

    // From Animatable
    virtual Class_ID ClassID() { return MaxKrakatoaPRTCullMod_CLASS_ID; }
    virtual void GetClassName( MSTR& s ) { s = MaxKrakatoaPRTCullMod_CLASS_NAME; }

    virtual int NumRefs() { return 0; }
    virtual ReferenceTarget* GetReference( int i ) { return NULL; }
    virtual void SetReference( int i, ReferenceTarget* r ) {}

    virtual int NumSubs() { return 0; }
    virtual Animatable* SubAnim( int i ) { return NULL; }
    virtual TSTR SubAnimName( int i ) { return _T( "" ); }

    virtual int NumParamBlocks() { return 0; }
    virtual IParamBlock2* GetParamBlock( int i ) { return NULL; }
    virtual IParamBlock2* GetParamBlockByID( BlockID i ) { return NULL; }

    virtual void BeginEditParams( IObjParam* ip, ULONG flags, Animatable* prev = NULL ) {}
    virtual void EndEditParams( IObjParam* ip, ULONG flags, Animatable* next = NULL ) {}

    // From ReferenceMaker
#if MAX_VERSION_MAJOR < 17
    virtual RefResult NodifyRefChanged( Interval, RefTargetHandle, PartID&, RefMessage ) { return REF_SUCCEED; }
#else
    virtual RefResult NotifyRefChanged( const Interval&, RefTargetHandle, PartID&, RefMessage, BOOL ) {
        return REF_SUCCEED;
    }
#endif
    // From ReferenceTarget
    virtual ReferenceTarget* Clone( RemapDir& remap ) {
        CullMod* pNewObj = new CullMod;
        for( int i = 0, iEnd = NumRefs(); i < iEnd; ++i )
            pNewObj->ReplaceReference( i, remap.CloneRef( GetReference( i ) ) );
        BaseClone( this, pNewObj, remap );
        return pNewObj;
    }

    // From BaseObject
    virtual const TCHAR* GetObjectName() { return MaxKrakatoaPRTCullMod_CLASS_NAME; }
    virtual void GetWorldBoundBox( TimeValue t, INode* inode, ViewExp* vpt, Box3& box ) {}
    virtual void GetLocalBoundBox( TimeValue t, INode* inode, ViewExp* vpt, Box3& box ) {}
    virtual CreateMouseCallBack* GetCreateMouseCallBack( void ) { return NULL; }

    // From Modifier
    virtual Class_ID InputType() { return MaxKrakatoaPRTPipelineObject_CLASS_ID; }
    virtual ChannelMask ChannelsUsed() { return (ChannelMask)ALL_CHANNELS; }
    virtual ChannelMask ChannelsChanged() { return GEOM_CHANNEL; }

    virtual Interval LocalValidity( TimeValue t ) { return FOREVER; }

    virtual void ModifyObject( TimeValue t, ModContext& mc, ObjectState* os, INode* node ) {
        if( os->obj->ClassID() != MaxKrakatoaPRTPipelineObject_CLASS_ID )
            return;

        MaxKrakatoaPRTPipelineObject* pObj = static_cast<MaxKrakatoaPRTPipelineObject*>( os->obj );
        pObj->m_particleStreamProvider.reset( new cull_stream_provider( pObj->m_particleStreamProvider ) );
        pObj->UpdateValidity( GEOM_CHAN_NUM, FOREVER );
    }
};

class MaxKrakatoaPRTCullModDesc : public ClassDesc2 {
    ParamBlockDesc2* m_pParamDesc;

  public:
    MaxKrakatoaPRTCullModDesc() {}
    virtual ~MaxKrakatoaPRTCullModDesc() {}

    int IsPublic() { return TRUE; }
    void* Create( BOOL /*loading*/ ) { return new CullMod; }
    const TCHAR* ClassName() { return MaxKrakatoaPRTCullMod_CLASS_NAME; }
    SClass_ID SuperClassID() { return OSM_CLASS_ID; }
    Class_ID ClassID() { return MaxKrakatoaPRTCullMod_CLASS_ID; }
    const TCHAR* Category() { return _T("Krakatoa"); }

    const TCHAR* InternalName() {
        return MaxKrakatoaPRTCullMod_CLASS_NAME;
    }                                           // returns fixed parsable name (scripter-visible name)
    HINSTANCE HInstance() { return hInstance; } // returns owning module handle
};

ClassDesc2* GetMaxKrakatoaPRTCullModDesc() {
    static MaxKrakatoaPRTCullModDesc theDesc;
    return &theDesc;
}
#endif
