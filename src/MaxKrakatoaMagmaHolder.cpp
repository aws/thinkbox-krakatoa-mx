// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0
#include "resource.h"
#include "stdafx.h"

#include "Magma/MagmaMaxContext.hpp"
#include "Magma/MagmaMaxSingleton.hpp"
#include "MaxKrakatoa.h"
#include "MaxKrakatoaMagmaHolder.h"

#include <frantic/magma/max3d/MagmaHolder.hpp>
#include <frantic/magma/max3d/MagmaMaxNodeExtension.hpp>

#include <frantic/magma/magma_exception.hpp>
#include <frantic/magma/simple_compiler/simple_particle_compiler.hpp>

#include <frantic/max3d/channels/property_map_interop.hpp>
#include <frantic/max3d/maxscript/maxscript.hpp>

#include <frantic/channels/property_map.hpp>
#include <frantic/graphics/camera.hpp>

extern HINSTANCE hInstance;

#include <frantic/magma/max3d/nodes/magma_curve_op_node.hpp>
#include <frantic/magma/max3d/nodes/magma_geometry_input_node.hpp>
#include <frantic/magma/max3d/nodes/magma_input_field_node.hpp>
#include <frantic/magma/max3d/nodes/magma_input_object_node.hpp>
#include <frantic/magma/max3d/nodes/magma_input_particles_node.hpp>
#include <frantic/magma/max3d/nodes/magma_input_value_node.hpp>
#include <frantic/magma/max3d/nodes/magma_script_op_node.hpp>
#include <frantic/magma/max3d/nodes/magma_transform_node.hpp>

namespace frantic {
namespace magma {
namespace nodes {
namespace max3d {
Class_ID magma_from_space_node::max_impl::s_ClassID( 0x5c35334b, 0x6f0d5c67 );
Class_ID magma_to_space_node::max_impl::s_ClassID( 0x3a53048f, 0x26046e57 );
Class_ID magma_input_value_node::max_impl::s_ClassID( 0x4b2d56d2, 0x4bf864b7 );
Class_ID magma_input_particles_node::max_impl::s_ClassID( 0x52ef7e6a, 0x20452f80 );
Class_ID magma_input_object_node::max_impl::s_ClassID( 0x5b72a14, 0x2f64316b );
Class_ID magma_curve_op_node::max_impl::s_ClassID( 0x5fb062e7, 0x97b4b05 );
Class_ID magma_input_geometry_node::max_impl::s_ClassID( 0x5cfc3c74, 0x67c95180 );
Class_ID magma_script_op_node::max_impl::s_ClassID( 0x53fd5036, 0x7ebf2032 );
Class_ID magma_field_input_node::max_impl::s_ClassID( 0x37ca7a07, 0x8d415ce );
} // namespace max3d
} // namespace nodes
} // namespace magma
} // namespace frantic

#define MaxKrakatoaMagmaHolder_INTERFACE Interface_ID( 0x2972101e, 0x4d235de7 )

class IMaxKrakatoaMagmaHolder : public FPMixinInterface {
  public:
    virtual ~IMaxKrakatoaMagmaHolder() {}

    virtual FPInterfaceDesc* GetDesc();

    virtual Value* compile_and_execute( Value* values, frantic::magma::max3d::IMagmaHolder::index_type index,
                                        bool forDebug, TimeValue t ) = 0;

  public:
    enum {
        kFnCompileAndExecute,
    };

#pragma warning( push )
#pragma warning( disable : 4238 )
    BEGIN_FUNCTION_MAP
    FNT_3( kFnCompileAndExecute, TYPE_VALUE, compile_and_execute, TYPE_VALUE, TYPE_INDEX, TYPE_bool )
    END_FUNCTION_MAP;

    static void append_fpinterfacedesc( FPInterfaceDesc& fpDesc ) {
        fpDesc.AppendFunction( kFnCompileAndExecute, _T("CompileAndExecute"), 0, TYPE_VALUE, 0, 3, _T("InputsArray"), 0,
                               TYPE_VALUE, _T("Index"), 0, TYPE_INDEX, _T("ForDebug"), 0, TYPE_bool, p_end );
    }
#pragma warning( pop )
};

class MaxKrakatoaMagmaHolderClassDesc : public frantic::magma::max3d::MagmaHolderClassDesc {
  public:
    FPInterfaceDesc m_fpDescKrakatoa;

  public:
    MaxKrakatoaMagmaHolderClassDesc();

    virtual ~MaxKrakatoaMagmaHolderClassDesc();

    virtual const MCHAR* ClassName();
#if MAX_VERSION_MAJOR >= 24
    virtual const MCHAR* NonLocalizedClassName();
#endif
    virtual HINSTANCE HInstance();
    virtual Class_ID ClassID();
    virtual void* Create( BOOL loading );
};

class MaxKrakatoaMagmaHolder : public frantic::magma::max3d::MagmaHolder, public IMaxKrakatoaMagmaHolder {
  protected:
    virtual ClassDesc2* GetClassDesc();

  public:
    MaxKrakatoaMagmaHolder( BOOL loading );

    virtual ~MaxKrakatoaMagmaHolder();

    virtual BaseInterface* GetInterface( Interface_ID id );

    virtual Value* compile_and_execute( Value* values, index_type index, bool forDebug, TimeValue t );
};

ReferenceTarget* CreateKrakatoaMagmaHolder() { return new MaxKrakatoaMagmaHolder( FALSE ); }

ClassDesc2* GetKrakatoaMagmaHolderDesc() {
    static MaxKrakatoaMagmaHolderClassDesc theMaxKrakatoaMagmaHolderClassDesc;
    return &theMaxKrakatoaMagmaHolderClassDesc;
}

MaxKrakatoaMagmaHolderClassDesc::MaxKrakatoaMagmaHolderClassDesc()
    : m_fpDescKrakatoa( MaxKrakatoaMagmaHolder_INTERFACE, _T("KrakatoaMagma"), 0, NULL, FP_MIXIN, p_end ) {
    m_fpDescKrakatoa.SetClassDesc( this );
    IMaxKrakatoaMagmaHolder::append_fpinterfacedesc( m_fpDescKrakatoa );
}

MaxKrakatoaMagmaHolderClassDesc::~MaxKrakatoaMagmaHolderClassDesc() {}

const MCHAR* MaxKrakatoaMagmaHolderClassDesc::ClassName() { return KrakatoaMagmaHolder_NAME; }

#if MAX_VERSION_MAJOR >= 24
const MCHAR* MaxKrakatoaMagmaHolderClassDesc::NonLocalizedClassName() { return KrakatoaMagmaHolder_NAME; }
#endif

HINSTANCE MaxKrakatoaMagmaHolderClassDesc::HInstance() { return hInstance; }

Class_ID MaxKrakatoaMagmaHolderClassDesc::ClassID() { return KrakatoaMagmaHolder_CLASS_ID; }

void* MaxKrakatoaMagmaHolderClassDesc::Create( BOOL loading ) { return new MaxKrakatoaMagmaHolder( loading ); }

FPInterfaceDesc* IMaxKrakatoaMagmaHolder::GetDesc() {
    return &static_cast<MaxKrakatoaMagmaHolderClassDesc*>( GetKrakatoaMagmaHolderDesc() )->m_fpDescKrakatoa;
}

ClassDesc2* MaxKrakatoaMagmaHolder::GetClassDesc() { return GetKrakatoaMagmaHolderDesc(); }

MaxKrakatoaMagmaHolder::MaxKrakatoaMagmaHolder( BOOL /*loading*/ )
    : frantic::magma::max3d::MagmaHolder( MagmaMaxSingleton::get_instance().create_magma_instance() ) {
    // We need our paramblock always because the loading code will touch it (possibly inappropriately). We might want to
    // rework that. if( !loading )
    GetKrakatoaMagmaHolderDesc()->MakeAutoParamBlocks( this );
}

MaxKrakatoaMagmaHolder::~MaxKrakatoaMagmaHolder() {}

BaseInterface* MaxKrakatoaMagmaHolder::GetInterface( Interface_ID id ) {
    if( id == MaxKrakatoaMagmaHolder_INTERFACE )
        return static_cast<IMaxKrakatoaMagmaHolder*>( this );
    // Don't need to check FPMixinInterface here because MagmaHolder::GetInterface() does.
    return frantic::magma::max3d::MagmaHolder::GetInterface( id );
}

Value* MaxKrakatoaMagmaHolder::compile_and_execute( Value* values, index_type index, bool forDebug, TimeValue t ) {
    try {
        // Build a property map from the input MXS values.
        frantic::channels::property_map inProps;
        frantic::max3d::channels::get_mxs_parameters( values, t, false, inProps );

        typedef frantic::max3d::particles::IMaxKrakatoaPRTObject IMaxKrakatoaPRTObject;

        // TODO: Use the active viewport I suppose ...
        frantic::graphics::camera<float> defaultCam;

        // std::auto_ptr<IMaxKrakatoaPRTObject::IEvalContext> context( IMaxKrakatoaPRTObject::CreateDefaultEvalContext(
        // inProps.get_channel_map(), defaultCam, t ) );

        frantic::max3d::particles::IMaxKrakatoaPRTEvalContextPtr context =
            frantic::max3d::particles::CreateMaxKrakatoaPRTEvalContext( t, KrakatoaMagmaHolder_CLASS_ID, &defaultCam,
                                                                        &inProps.get_channel_map() );

        boost::shared_ptr<MagmaMaxContextInterface> magmaContext( new MagmaMaxContextInterface( NULL, context ) );

        boost::shared_ptr<frantic::magma::magma_interface> magma = get_magma_interface();

        frantic::magma::simple_compiler::simple_particle_compiler compiler;
        compiler.reset( *magma, inProps.get_channel_map(), inProps.get_channel_map(), magmaContext );

        // The input props may have different channels than the compiler decided to provide, so we use this separate
        // merged prop map.
        frantic::channels::property_map tempProps( compiler.get_channel_map() );
        tempProps.merge_property_map( inProps );

        if( !forDebug ) {
            compiler.eval( const_cast<char*>( tempProps.get_raw_buffer() ), (std::size_t)index );

            frantic::max3d::mxs::frame<1> f;
            frantic::max3d::mxs::local<Array> valuesArray( f, new Array( 0 ) );

            for( int i = 0, iEnd = magma->get_num_outputs( frantic::magma::magma_interface::TOPMOST_LEVEL ); i < iEnd;
                 ++i ) {
                magma_id outputID = magma->get_output( frantic::magma::magma_interface::TOPMOST_LEVEL, 0 ).first;
                if( outputID == frantic::magma::magma_interface::INVALID_ID )
                    continue;

                bool enabled;
                if( magma->get_property<bool>( outputID, _T("enabled"), enabled ) && !enabled )
                    continue;

                M_STD_STRING outputChannel;
                magma->get_property( outputID, _T("channelName"), outputChannel );

                // Extract the output channel value and return it.
                const frantic::channels::channel& ch = tempProps.get_channel_map()[outputChannel];
                const char* ptr = ch.get_channel_data_pointer( tempProps.get_raw_buffer() );
                valuesArray->append( frantic::max3d::channels::channel_to_value( ptr, ch.arity(), ch.data_type() ) );
            }
#if MAX_VERSION_MAJOR < 19
            return_protected( valuesArray.ptr() );
#else
            return_value( valuesArray.ptr() );
#endif
        } else {
            frantic::magma::debug_data debugResults;

            compiler.eval_debug( const_cast<char*>( tempProps.get_raw_buffer() ), (std::size_t)index, debugResults );

            // Output nodes don't actually have an entry on the stack, so I need to explicitly grab the values from the
            // node each output is connected to.
            for( int i = 0, iEnd = magma->get_num_outputs( frantic::magma::magma_interface::TOPMOST_LEVEL ); i < iEnd;
                 ++i ) {
                magma_id outputID = magma->get_output( frantic::magma::magma_interface::TOPMOST_LEVEL, i ).first;
                if( outputID == frantic::magma::magma_interface::INVALID_ID )
                    continue;

                bool enabled;
                if( magma->get_property<bool>( outputID, _T("enabled"), enabled ) && !enabled )
                    continue;

                std::pair<magma_id, int> conn = magma->get_input( outputID, 0 );

                debugResults.append_value( outputID, debugResults.find( conn.first )->second[conn.second] );
            }

            frantic::max3d::mxs::frame<3> f;
            frantic::max3d::mxs::local<Array> resultArray( f, new Array( 0 ) );
            frantic::max3d::mxs::local<Array> nodeArray( f );
            frantic::max3d::mxs::local<Array> valuesArray( f );

            for( frantic::magma::debug_data::const_iterator it = debugResults.begin(), itEnd = debugResults.end();
                 it != itEnd; ++it ) {
                nodeArray = new Array( 0 );
                nodeArray->append( Integer::intern( it->first ) );

                valuesArray = new Array( 0 );
                for( frantic::magma::debug_data::const_value_iterator itOutputs = it->second.begin(),
                                                                      itOutputsEnd = it->second.end();
                     itOutputs != itOutputsEnd; ++itOutputs ) {
                    if( itOutputs->type() == typeid( float ) ) {
                        valuesArray->append( frantic::max3d::fpwrapper::MaxTypeTraits<float>::to_value(
                            boost::get<float>( *itOutputs ) ) );
                    } else if( itOutputs->type() == typeid( int ) ) {
                        valuesArray->append(
                            frantic::max3d::fpwrapper::MaxTypeTraits<int>::to_value( boost::get<int>( *itOutputs ) ) );
                    } else if( itOutputs->type() == typeid( bool ) ) {
                        valuesArray->append( frantic::max3d::fpwrapper::MaxTypeTraits<bool>::to_value(
                            boost::get<bool>( *itOutputs ) ) );
                    } else if( itOutputs->type() == typeid( frantic::graphics::vector3f ) ) {
                        valuesArray->append( frantic::max3d::fpwrapper::MaxTypeTraits<Point3>::to_value(
                            frantic::max3d::to_max_t( boost::get<frantic::graphics::vector3f>( *itOutputs ) ) ) );
                    } else if( itOutputs->type() == typeid( float ) ) {
                        valuesArray->append( new( GC_IN_HEAP ) QuatValue(
                            frantic::max3d::to_max_t( boost::get<frantic::graphics::quat4f>( *itOutputs ) ) ) );
                    } else {
                        valuesArray->append( &undefined );
                    }

                    nodeArray->append( valuesArray->size > 1 ? valuesArray.ptr() : valuesArray->data[0] );
                }

                resultArray->append( nodeArray.ptr() );
            }
#if MAX_VERSION_MAJOR < 19
            return_protected( resultArray.ptr() );
#else
            return_value( resultArray.ptr() );
#endif
        }
    } catch( const frantic::magma::magma_exception& e ) {
        throw MAXException( const_cast<MCHAR*>( e.get_message( true ).c_str() ) );
    } catch( const std::exception& e ) {
        FF_LOG( error ) << e.what() << std::endl;

        throw MAXException( _T("Magma Internal Error") );
    }
}

boost::shared_ptr<frantic::magma::magma_interface> GetMagmaInterface( ReferenceTarget* magmaHolder ) {
    using namespace frantic::magma::max3d;
    if( IMagmaHolder* holder = GetMagmaHolderInterface( magmaHolder ) ) {
        boost::shared_ptr<frantic::magma::magma_interface> pResult = holder->get_magma_interface();

        MaxKrakatoa* pKrakatoa = NULL;

        if( Renderer* pRenderer = GetCOREInterface()->GetCurrentRenderer() ) {
            if( pRenderer->ClassID() == MaxKrakatoa_CLASS_ID )
                pKrakatoa = static_cast<MaxKrakatoa*>( pRenderer );
        }

        // Krakatoa will override the type of certain channels so we are going to manually assign the type in the output
        // nodes
        if( pResult && pKrakatoa ) {
            frantic::channels::channel_map rendererChannels;

            pKrakatoa->GetRenderParticleChannels( rendererChannels );
            pKrakatoa->ApplyChannelDataTypeOverrides( rendererChannels );

            rendererChannels.end_channel_definition();

            for( int i = 0, iEnd = pResult->get_num_outputs( frantic::magma::magma_interface::TOPMOST_LEVEL ); i < iEnd;
                 ++i ) {
                std::pair<frantic::magma::magma_interface::magma_id, int> theOutput =
                    pResult->get_output( frantic::magma::magma_interface::TOPMOST_LEVEL, i );

                frantic::tstring channelName;
                frantic::magma::magma_data_type channelType;

                if( !pResult->get_property<frantic::tstring>( theOutput.first, _T("channelName"), channelName ) )
                    continue;

                if( !pResult->get_property<frantic::magma::magma_data_type>( theOutput.first, _T("channelType"),
                                                                             channelType ) )
                    continue;

                if( rendererChannels.has_channel( channelName ) ) {
                    const frantic::channels::channel& ch = rendererChannels[channelName];
                    if( ( ch.arity() == channelType.m_elementCount && ch.data_type() != channelType.m_elementType ) ||
                        channelType.m_elementType == frantic::channels::data_type_invalid ) {
                        channelType.m_elementCount = ch.arity();
                        channelType.m_elementType = ch.data_type();

                        pResult->set_property<frantic::magma::magma_data_type>( theOutput.first, _T("channelType"),
                                                                                channelType );
                    }
                }
            }
        }

        return pResult;
    }
    return boost::shared_ptr<frantic::magma::magma_interface>();
}

Interval GetMagmaValidity( ReferenceTarget* magmaHolder, TimeValue t ) {
    using namespace frantic::magma::max3d;
    if( IMagmaHolder* holder = GetMagmaHolderInterface( magmaHolder ) )
        return holder->get_validity( t );
    return FOREVER;
}
