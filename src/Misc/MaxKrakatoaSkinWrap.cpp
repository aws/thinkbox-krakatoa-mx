// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0
#include "stdafx.h"

#include "resource.h"

#include <frantic/geometry/trimesh3_file_io.hpp>
#include <frantic/geometry/trimesh3_kdtree.hpp>
#include <frantic/logging/logging_level.hpp>
#include <frantic/max3d/convert.hpp>
#include <frantic/max3d/geometry/mesh.hpp>
#include <frantic/max3d/iostream.hpp>

using frantic::graphics::transform4f;
using frantic::graphics::vector3;
using frantic::graphics::vector3f;

extern HINSTANCE hInstance;

enum { k_blockID };

enum { k_meshNode, k_exponent, k_maxTessellation, k_baseFrame, k_radius, k_mode, k_triCount };

enum { mode_radius, mode_count };

class KrakatoaSkinWrap;
class KrakatoaSkinWrapClassDesc : public ClassDesc2 {
    static Class_ID classID;
    static KrakatoaSkinWrapClassDesc theDesc;
    static ParamBlockDesc2* thePBDesc;

    friend ClassDesc2* GetKrakatoaSkinWrapClassDesc();
    friend class KrakatoaSkinWrap;

  public:
    KrakatoaSkinWrapClassDesc();
    ~KrakatoaSkinWrapClassDesc();

    static void CreateParamBlock2( ReferenceMaker* blockOwner );

    int IsPublic() { return TRUE; }
    void* Create( BOOL loading = FALSE );
    const TCHAR* ClassName() { return _T("Krakatoa Skin Wrap"); }
#if MAX_VERSION_MAJOR >= 24
    const TCHAR* NonLocalizedClassName() { return _T("Krakatoa Skin Wrap"); }
#endif
    SClass_ID SuperClassID() { return WSM_CLASS_ID; }
    Class_ID ClassID() { return classID; }
    const TCHAR* Category() { return _T("Krakatoa"); }
    const TCHAR* InternalName() { return _T("KrakatoaSkinWrap"); }
    HINSTANCE HInstance() { return hInstance; }
};

Class_ID KrakatoaSkinWrapClassDesc::classID = Class_ID( 0x7f76050e, 0x54ce7122 );
KrakatoaSkinWrapClassDesc KrakatoaSkinWrapClassDesc::theDesc;
ParamBlockDesc2* KrakatoaSkinWrapClassDesc::thePBDesc = NULL;

ClassDesc2* GetKrakatoaSkinWrapClassDesc() { return &KrakatoaSkinWrapClassDesc::theDesc; }

KrakatoaSkinWrapClassDesc::KrakatoaSkinWrapClassDesc() {
    thePBDesc = new ParamBlockDesc2( k_blockID, _T("Parameters"), 0, &theDesc, P_AUTO_UI, IDD_SKINWRAP, IDS_PARAMETERS,
                                     0, 0, NULL, p_end );

    thePBDesc->AddParam( k_meshNode, _T("SkinNode"), TYPE_INODE, 0, 0, p_end );
    thePBDesc->AddParam( k_exponent, _T("Exponent"), TYPE_FLOAT, 0, 0, p_default, 6.0f, p_end );
    thePBDesc->AddParam( k_maxTessellation, _T("Tessellation"), TYPE_INT, 0, 0, p_default, 1, p_end );
    thePBDesc->AddParam( k_baseFrame, _T("BaseFrame"), TYPE_INT, 0, 0, p_default, 0, p_end );
    thePBDesc->AddParam( k_radius, _T("Radius"), TYPE_FLOAT, 0, 0, p_default, 1.5f, p_end );
    thePBDesc->AddParam( k_mode, _T("Mode"), TYPE_INT, 0, 0, p_default, 0, p_end );
    thePBDesc->AddParam( k_triCount, _T("TriCount"), TYPE_INT, 0, 0, p_default, 4, p_end );

    thePBDesc->ParamOption( k_meshNode, p_ui, TYPE_PICKNODEBUTTON, IDC_SKINNODE );
    thePBDesc->ParamOption( k_radius, p_ui, TYPE_SPINNER, EDITTYPE_FLOAT, IDC_RADIUSEDIT, IDC_RADIUSSPIN,
                            SPIN_AUTOSCALE );
    thePBDesc->ParamOption( k_exponent, p_ui, TYPE_SPINNER, EDITTYPE_FLOAT, IDC_EXPONENTEDIT, IDC_EXPONENTSPIN,
                            SPIN_AUTOSCALE );
    thePBDesc->ParamOption( k_maxTessellation, p_ui, TYPE_SPINNER, EDITTYPE_INT, IDC_TESSELLATIONEDIT,
                            IDC_TESSELLATIONSPIN, SPIN_AUTOSCALE );
    thePBDesc->ParamOption( k_baseFrame, p_ui, TYPE_SPINNER, EDITTYPE_INT, IDC_FRAMEEDIT, IDC_FRAMESPIN,
                            SPIN_AUTOSCALE );
    thePBDesc->ParamOption( k_mode, p_ui, TYPE_RADIO, 2, IDC_MODERADIUS, IDC_MODECOUNT );
    thePBDesc->ParamOption( k_triCount, p_ui, TYPE_SPINNER, EDITTYPE_INT, IDC_COUNTEDIT, IDC_COUNTSPIN,
                            SPIN_AUTOSCALE );

    thePBDesc->ParamOption( k_baseFrame, p_range, INT_MIN, INT_MAX );
    thePBDesc->ParamOption( k_radius, p_range, 1.01f, FLT_MAX );
    thePBDesc->ParamOption( k_triCount, p_range, 1, INT_MAX );
}

KrakatoaSkinWrapClassDesc::~KrakatoaSkinWrapClassDesc() { delete thePBDesc; }

void KrakatoaSkinWrapClassDesc::CreateParamBlock2( ReferenceMaker* blockOwner ) {
    blockOwner->ReplaceReference( 0, CreateParameterBlock2( thePBDesc, blockOwner ) );
}

float weight_recursive( const vector3f& a, const vector3f& b, const vector3f& c, const vector3f& p, float centerWeight,
                        float expon, int maxDepth ) {
    vector3f subdiv[] = { 0.5f * ( a + b ), 0.5f * ( b + c ), 0.5f * ( c + a ) };
    float weights[] = { 1.f / std::pow( ( ( a + subdiv[0] + subdiv[2] ) / 3.f - p ).get_magnitude_squared(), expon ),
                        1.f / std::pow( ( ( subdiv[0] + b + subdiv[1] ) / 3.f - p ).get_magnitude_squared(), expon ),
                        1.f / std::pow( ( ( subdiv[2] + subdiv[1] + c ) / 3.f - p ).get_magnitude_squared(), expon ) };

    float result = 0.25f * ( centerWeight + weights[0] + weights[1] + weights[2] );
    if( std::abs( result - centerWeight ) < 0.01f * centerWeight || maxDepth <= 0 )
        return result;

    weights[0] = weight_recursive( a, subdiv[0], subdiv[2], p, weights[0], expon, maxDepth - 1 );
    weights[1] = weight_recursive( subdiv[0], b, subdiv[1], p, weights[1], expon, maxDepth - 1 );
    weights[2] = weight_recursive( subdiv[2], subdiv[1], c, p, weights[2], expon, maxDepth - 1 );
    centerWeight = weight_recursive( subdiv[0], subdiv[1], subdiv[2], p, centerWeight, expon, maxDepth - 1 );

    return 0.25f * ( centerWeight + weights[0] + weights[1] + weights[2] );
}

inline float weight( const vector3f& a, const vector3f& b, const vector3f& c, const vector3f& p, float expon,
                     int maxDepth ) {
    float weight = 1.f / std::pow( ( ( a + b + c ) / 3.f - p ).get_magnitude_squared(), expon );
    float area = 0.5f * ( vector3f::cross( ( b - a ), ( c - a ) ) ).get_magnitude();

    if( maxDepth <= 0 )
        return area * weight;
    return area * weight_recursive( a, b, c, p, weight, expon, maxDepth - 1 );
}

class KrakatoaSkinWrap : public WSModifier {
    IParamBlock2* m_pblock;
    Interval m_valid;

    frantic::geometry::trimesh3 m_baseMesh;
    std::auto_ptr<frantic::geometry::trimesh3_kdtree> m_baseTree;

    // So this part gets a little weird ... Krakatoa typically will evaluate a modifier
    // at time T then at time T+(deltaT) in order to calculate the velocity caused by
    // an animated parameter in the modifier. This was causing a lot of invalidation
    // of the modifier's caches, so I made the modifier use a 2 entry cache. Each cache
    // entry has a validity Interval associated with it, and an array transformations.
    int m_transformCacheSize;
    Interval m_transformCacheValidity[2];
    boost::scoped_array<transform4f> m_transformCache[2];

  public:
    KrakatoaSkinWrap() {
        m_pblock = NULL;
        m_valid = NEVER;

        m_transformCacheSize = 0;

        KrakatoaSkinWrapClassDesc::CreateParamBlock2( this );
    }

    // From Animatable
    int NumSubs() { return 1; }
    Animatable* SubAnim( int i ) { return ( i == 0 ) ? m_pblock : NULL; }
#if MAX_VERSION_MAJOR < 24
    TSTR SubAnimName( int i )
#else
    TSTR SubAnimName( int i, bool localized )
#endif
    {
        return ( i == 0 ) ? _T("Parameters") : NULL;
    }

    int NumParamBlocks() { return 1; }
    IParamBlock2* GetParamBlock( int i ) { return ( i == 0 ) ? m_pblock : NULL; }
    IParamBlock2* GetParamBlockByID( short id ) { return ( id == 0 ) ? m_pblock : NULL; }

    Class_ID ClassID() { return KrakatoaSkinWrapClassDesc::classID; }

    void BeginEditParams( IObjParam* ip, ULONG flags, Animatable* prev ) {
        GetKrakatoaSkinWrapClassDesc()->BeginEditParams( ip, this, flags, prev );
    }

    void EndEditParams( IObjParam* ip, ULONG flags, Animatable* next ) {
        GetKrakatoaSkinWrapClassDesc()->EndEditParams( ip, this, flags, next );
    }

    // From ReferenceTarget
    ReferenceTarget* Clone( RemapDir& remap ) {
        KrakatoaSkinWrap* result = new KrakatoaSkinWrap();
        BaseClone( this, result, remap );
        result->ReplaceReference( 0, m_pblock->Clone( remap ) );
        return result;
    }

    // From ReferenceMaker
    int NumRefs() { return 1; }
    void SetReference( int i, ReferenceTarget* r ) {
        if( i == 0 )
            m_pblock = static_cast<IParamBlock2*>( r );
    }
    ReferenceTarget* GetReference( int i ) { return ( i == 0 ) ? m_pblock : NULL; }

    RefResult NotifyRefChanged( const Interval& /*changeInt*/, RefTargetHandle hTarget, PartID& /*partID*/,
                                RefMessage message, BOOL /*propagate*/ ) {
        if( hTarget == m_pblock ) {
            ParamID pbID = m_pblock->LastNotifyParamID();
            if( pbID == k_meshNode ) {
                if( message == REFMSG_CHANGE )
                    m_valid.SetEmpty();
                else if( message == REFMSG_TARGET_DELETED )
                    m_pblock->SetValue( k_meshNode, 0, NULL );
            } else if( pbID == k_baseFrame ) {
                if( message == REFMSG_CHANGE )
                    m_valid.SetEmpty();
            }
        }
        return REF_SUCCEED;
    }

#if MAX_VERSION_MAJOR < 17
    virtual RefResult NotifyRefChanged( Interval changeInt, RefTargetHandle hTarget, PartID& partID,
                                        RefMessage message ) {
        return this->NotifyRefChanged( changeInt, hTarget, partID, message, TRUE );
    }
#endif

    // From BaseObject
#if MAX_VERSION_MAJOR >= 24
    const TCHAR* GetObjectName( bool localized ) { return _T("Krakatoa Skin Wrap"); }
#elif MAX_VERSION_MAJOR >= 15
    const TCHAR* GetObjectName() { return _T("Krakatoa Skin Wrap"); }
#else
    TCHAR* GetObjectName() { return _T("Krakatoa Skin Wrap"); }
#endif

    CreateMouseCallBack* GetCreateMouseCallBack() { return NULL; }

    // From Modifier
    ChannelMask ChannelsUsed() { return GEOM_CHANNEL; }
    ChannelMask ChannelsChanged() { return GEOM_CHANNEL; }
    Class_ID InputType() { return defObjectClassID; }

    Interval LocalValidity( TimeValue /*t*/ ) {
        // return m_valid;

        // because of the caching that is done with the transforms the
        // valid Interval maintained with this plugin can become an instant
        // that is not the current time.  This can cause an objects validity
        // to get set to a time that is not now (particulary the PRT loader when
        // load single frame is checked) causing the object to continuously be
        // reevaluated
        return NEVER;
    }

    void ModifyObject( TimeValue t, ModContext& /*mc*/, ObjectState* os, INode* ) {
        try {

            INode* updateNode = m_pblock->GetINode( k_meshNode, t );
            if( !updateNode ) {
                m_valid = FOREVER;
                return;
            }

            if( os->obj->NumPoints() == 0 )
                return;

            if( m_valid.Empty() ) {
                for( int i = 0; i < m_transformCacheSize; ++i ) {
                    m_transformCache[i].reset();
                    m_transformCacheValidity[i].SetEmpty();
                }
                m_transformCacheSize = 0;

                TimeValue baseFrame = m_pblock->GetInt( k_baseFrame ) * GetTicksPerFrame();

                ObjectState baseOS = updateNode->EvalWorldState( baseFrame );
                if( !baseOS.obj->CanConvertToType( triObjectClassID ) )
                    throw std::runtime_error(
                        "KrakatoaSkinWrap.ModifyObject: Cannot convert the skinwrap object to a TriObject" );
                TriObject* basePoseObj =
                    static_cast<TriObject*>( baseOS.obj->ConvertToType( baseFrame, triObjectClassID ) );

                m_baseMesh.clear();
                frantic::max3d::geometry::mesh_copy( m_baseMesh, updateNode->GetNodeTM( baseFrame ),
                                                     basePoseObj->GetMesh(), true );

                if( basePoseObj != baseOS.obj )
                    basePoseObj->MaybeAutoDelete();

                m_baseTree.reset( new frantic::geometry::trimesh3_kdtree( m_baseMesh ) );
            }

            int lowestIndex = 0;
            transform4f* m_triTransforms = NULL;
            for( int i = 0; i < m_transformCacheSize && m_triTransforms == NULL; ++i ) {
                if( m_transformCacheValidity[i].InInterval( t ) ) {
                    m_triTransforms = m_transformCache[i].get();
                    m_valid = m_transformCacheValidity[i];
                } else if( m_transformCacheValidity[i].Start() < m_transformCacheValidity[lowestIndex].Start() )
                    lowestIndex = i;
            }

            // if( !m_valid.InInterval(t) ){
            if( !m_triTransforms ) {
                ObjectState updateOS = updateNode->EvalWorldState( t );
                if( !updateOS.obj->CanConvertToType( triObjectClassID ) )
                    throw std::runtime_error(
                        "KrakatoaSkinWrap.ModifyObject: Cannot convert the skinwrap object to a TriObject" );
                TriObject* curPoseObj = static_cast<TriObject*>( updateOS.obj->ConvertToType( t, triObjectClassID ) );

                int numFaces = curPoseObj->mesh.numFaces;
                if( numFaces != (int)m_baseMesh.face_count() )
                    throw std::runtime_error(
                        "KrakatoaSkinWrap.ModifyObject: Skin Object has changing topology. Base: " +
                        boost::lexical_cast<std::string>( m_baseMesh.face_count() ) +
                        " vs. Current: " + boost::lexical_cast<std::string>( numFaces ) );

                if( m_transformCacheSize < 2 ) {
                    m_transformCacheValidity[m_transformCacheSize] = updateOS.Validity( t );
                    m_transformCache[m_transformCacheSize].reset( new transform4f[numFaces] );
                    m_triTransforms = m_transformCache[m_transformCacheSize].get();
                    ++m_transformCacheSize;
                } else {
                    m_transformCacheValidity[lowestIndex] = updateOS.Validity( t );
                    m_transformCache[lowestIndex].reset( new transform4f[numFaces] );
                    m_triTransforms = m_transformCache[lowestIndex].get();
                }

                // m_triTransforms.reset( new transform4f[numFaces] );

                transform4f curPoseTM = updateNode->GetNodeTM( t );
                for( int i = 0; i < numFaces; ++i ) {
                    Face f = curPoseObj->mesh.faces[i];

                    vector3f a0 = m_baseMesh.get_vertex( f.v[0] );
                    vector3f a10 = m_baseMesh.get_vertex( f.v[1] ) - a0;
                    vector3f a20 = m_baseMesh.get_vertex( f.v[2] ) - a0;
                    vector3f b0 = curPoseTM * static_cast<vector3f>( curPoseObj->mesh.verts[f.v[0]] );
                    vector3f b10 = curPoseTM * static_cast<vector3f>( curPoseObj->mesh.verts[f.v[1]] ) - b0;
                    vector3f b20 = curPoseTM * static_cast<vector3f>( curPoseObj->mesh.verts[f.v[2]] ) - b0;

                    transform4f a( a10, a20, vector3f::cross( a10, a20 ) );
                    transform4f b( b10, b20, vector3f::cross( b10, b20 ) );

                    try {
                        m_triTransforms[i] = b * a.to_inverse();
                        m_triTransforms[i].set_translation( b0 );
                    } catch( const std::exception& ) {
                        // Exceptions here are caused when the matrix is not invertible.
                        // TODO: C++ try/catch is pretty slow for this sort of thing. Consider a return value.
                        FF_LOG( warning ) << "Triangle #" << i << " of node " << updateNode->GetName()
                                          << " was not invertible." << std::endl;
                        m_triTransforms[i] = transform4f::from_translation( b0 );
                    }
                }

                if( curPoseObj != updateOS.obj )
                    curPoseObj->MaybeAutoDelete();

                m_valid = updateOS.Validity( t );
            }

            float expon = 0.5f * m_pblock->GetFloat( k_exponent );
            float searchRadius = std::max( 1.002f, m_pblock->GetFloat( k_radius ) );
            int maxTessellation = m_pblock->GetInt( k_maxTessellation );
            int mode = m_pblock->GetInt( k_mode );
            int triCount = m_pblock->GetInt( k_triCount );

            std::vector<int> closeFaces;

            DWORD selLevel;
            if( os->obj->IsSubClassOf( patchObjectClassID ) )
                selLevel = ( (PatchObject*)os->obj )->GetPatchMesh( t ).selLevel;
            else if( os->obj->IsSubClassOf( triObjectClassID ) )
                selLevel = ( (TriObject*)os->obj )->GetMesh().selLevel;
            else if( os->obj->IsSubClassOf( polyObjectClassID ) )
                selLevel = ( (PolyObject*)os->obj )->mm.selLevel;
            else
                selLevel = MESH_OBJECT;

            for( int i = 0, iEnd = os->obj->NumPoints(); i < iEnd; ++i ) {
                float selWeight;

                if( MESH_VERTEX & selLevel )
                    selWeight = os->obj->PointSelection( i );
                else
                    selWeight = 1.0f;

                if( selWeight != 0.0f ) {

                    vector3f p = frantic::max3d::from_max_t( os->obj->GetPoint( i ) );
                    vector3f result( 0, 0, 0 );
                    float normalizeFactor = 0;

                    if( mode == 1 ) {
                        std::vector<frantic::geometry::nearest_point_search_result> faces;
                        m_baseTree->collect_nearest_faces( p, triCount, faces );

                        for( std::vector<frantic::geometry::nearest_point_search_result>::iterator it = faces.begin(),
                                                                                                   itEnd = faces.end();
                             it != itEnd; ++it ) {
                            vector3 f = m_baseMesh.get_face( it->faceIndex );
                            vector3f a = m_baseMesh.get_vertex( f[0] );
                            vector3f b = m_baseMesh.get_vertex( f[1] );
                            vector3f c = m_baseMesh.get_vertex( f[2] );

                            float w = weight( a, b, c, p, expon, maxTessellation );
                            result += w * ( m_triTransforms[it->faceIndex] * ( p - a ) );
                            normalizeFactor += w;
                        }
                    } else {
                        frantic::geometry::nearest_point_search_result npsr;
                        m_baseTree->find_nearest_point( p, std::numeric_limits<float>::max(), npsr );

                        closeFaces.clear();

                        if( npsr.distance < 0.001f )
                            closeFaces.push_back( npsr.faceIndex );
                        else {
                            m_baseTree->collect_faces_within_range( p, searchRadius * npsr.distance, closeFaces );
                            if( closeFaces.size() == 0 ) {
                                os->obj->SetPoint( i, Point3( 0, 0, 0 ) );
                                continue;
                            }
                        }

                        for( std::vector<int>::iterator it = closeFaces.begin(), itEnd = closeFaces.end(); it != itEnd;
                             ++it ) {
                            vector3 f = m_baseMesh.get_face( *it );
                            vector3f a = m_baseMesh.get_vertex( f[0] );
                            vector3f b = m_baseMesh.get_vertex( f[1] );
                            vector3f c = m_baseMesh.get_vertex( f[2] );

                            float w = weight( a, b, c, p, expon, maxTessellation );
                            result += w * ( m_triTransforms[*it] * ( p - a ) );
                            normalizeFactor += w;
                        }
                    }

                    vector3f newPoint = result / normalizeFactor;
                    vector3f delta = newPoint - p;
                    newPoint = p + delta * selWeight;

                    os->obj->SetPoint( i, frantic::max3d::to_max_t( newPoint ) );
                }
            }

            os->obj->PointsWereChanged();
            os->obj->UpdateValidity( GEOM_CHAN_NUM, m_valid );

        } catch( const std::exception& e ) {
            MessageBoxA( NULL, e.what(), "KrakatoaSkinWrap.ModifyObject: ERROR", MB_OK );
            DisableMod();
        }
    }
};

void* KrakatoaSkinWrapClassDesc::Create( BOOL /*loading*/ ) { return new KrakatoaSkinWrap; }