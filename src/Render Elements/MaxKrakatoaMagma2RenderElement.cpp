// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0
#include "stdafx.h"

#include "resource.h"

#include "MaxKrakatoaChannelModifier.h"
#include "MaxKrakatoaMagmaHolder.h"
#include "MaxKrakatoaSceneContext.h"
#include "Render Elements\MaxKrakatoaRenderElement.h"
#include "magma\MagmaMaxContext.hpp"

#include <krakatoa/particle_render_element_interface.hpp>
#include <krakatoa/render_element.hpp>

#include <frantic/magma/simple_compiler/simple_particle_compiler.hpp>

#include <frantic/max3d/windows.hpp>

#define MaxKrakatoaMagmaRenderElement_CLASS_NAME _T("Krakatoa CustomData")
#define MaxKrakatoaMagmaRenderElement_CLASS_ID Class_ID( 0x1f4f382b, 0x6ce2f2f )

class magma_render_element : public krakatoa::render_element<krakatoa::particle_render_element_interface> {
    frantic::channels::channel_map m_outputMap;
    frantic::channels::channel_const_cvt_accessor<frantic::graphics::color3f> m_accessor;

    boost::shared_ptr<frantic::magma::magma_interface> m_magmaInterface;
    frantic::magma::simple_compiler::simple_particle_compiler m_compiler;

    bool m_doAntiAlias;

  private:
    magma_render_element();

  public:
    magma_render_element( bool antiAlias, krakatoa::scene_context_ptr sceneContext,
                          boost::shared_ptr<frantic::magma::magma_interface> magma );
    virtual ~magma_render_element();

    /**
     * see render_element_interface::clone()
     */
    virtual krakatoa::render_element_interface* clone();

    /**
     * see particle_render_element_interface::get_drawing_type()
     */
    virtual draw_type get_drawing_type() const;

    /**
     * see particle_render_element_interface::set_channel_map()
     */
    virtual void set_channel_map( const frantic::channels::channel_map& pcm );

    /**
     * see particle_render_element_interface::add_required_channels()
     */
    virtual void add_required_channels( frantic::channels::channel_map& pcm );

    /**
     * see particle_render_element_interface::evaluate()
     */
    virtual frantic::graphics::color3f evaluate( const char* particle );
};

class MaxKrakatoaMagma2RenderElement : public MaxKrakatoaRenderElement<MaxKrakatoaMagma2RenderElement> {
  protected:
    ClassDesc2* GetClassDesc();

  public:
    enum {
        kMagmaHolder = kMaxKrakatoaRenderElementLastParamNum,
    };

    static void DefineParamBlock( ParamBlockDesc2* pParamDesc );

    MaxKrakatoaMagma2RenderElement();
    virtual ~MaxKrakatoaMagma2RenderElement();

    // From IKrakatoaRenderElement
    virtual krakatoa::render_element_interface* get_render_element( krakatoa::scene_context_ptr pSceneContext );

    // From ReferenceMaker
    virtual RefResult NotifyRefChanged( const Interval& changeInt, RefTargetHandle hTarget, PartID& partID,
                                        RefMessage message, BOOL propagate );
};

class MaxKrakatoaMagma2RenderElementDesc : public ClassDesc2 {
    ParamBlockDesc2* m_pParamDesc;

  public:
    MaxKrakatoaMagma2RenderElementDesc();
    virtual ~MaxKrakatoaMagma2RenderElementDesc();

    int IsPublic() { return TRUE; }
    void* Create( BOOL ) { return new MaxKrakatoaMagma2RenderElement; }
    const TCHAR* ClassName() { return MaxKrakatoaMagmaRenderElement_CLASS_NAME; }
#if MAX_VERSION_MAJOR >= 24
    const TCHAR* NonLocalizedClassName() { return MaxKrakatoaMagmaRenderElement_CLASS_NAME; }
#endif
    SClass_ID SuperClassID() { return RENDER_ELEMENT_CLASS_ID; }
    Class_ID ClassID() { return MaxKrakatoaMagmaRenderElement_CLASS_ID; }
    const TCHAR* Category() { return _T(""); }

    const TCHAR* InternalName() {
        return MaxKrakatoaMagmaRenderElement_CLASS_NAME;
    }                                           // returns fixed parsable name (scripter-visible name)
    HINSTANCE HInstance() { return hInstance; } // returns owning module handle
};

ClassDesc2* GetMaxKrakatoaMagma2RenderElementDesc() {
    static MaxKrakatoaMagma2RenderElementDesc theMaxKrakatoaMagmaRenderElementDesc;
    return &theMaxKrakatoaMagmaRenderElementDesc;
}

ParamMap2UserDlgProc* GetMaxKrakatoaMagma2RenderElementDlgProc();

MaxKrakatoaMagma2RenderElementDesc::MaxKrakatoaMagma2RenderElementDesc() {
    m_pParamDesc = new ParamBlockDesc2( 0,                                        // Block num
                                        _T("Parameters"),                         // Internal name
                                        NULL,                                     // Localized name
                                        this,                                     // ClassDesc2*
                                        P_AUTO_CONSTRUCT | P_VERSION | P_AUTO_UI, // Flags
                                        0,                                        // Version
                                        0,                                        // PBlock Ref Num
                                        IDD_RENDERELEMENT_MAGMA, IDS_RENDELEM_DATA, 0, 0,
                                        GetMaxKrakatoaMagma2RenderElementDlgProc(), p_end );

    MaxKrakatoaMagma2RenderElement::DefineParamBlock( m_pParamDesc );
}

MaxKrakatoaMagma2RenderElementDesc::~MaxKrakatoaMagma2RenderElementDesc() {}

MaxKrakatoaMagma2RenderElement::MaxKrakatoaMagma2RenderElement() {
    GetMaxKrakatoaMagma2RenderElementDesc()->MakeAutoParamBlocks( this );

    m_pblock->SetValue( kMagmaHolder, 0, CreateKrakatoaMagmaHolder() );
}

MaxKrakatoaMagma2RenderElement::~MaxKrakatoaMagma2RenderElement() {}

ClassDesc2* MaxKrakatoaMagma2RenderElement::GetClassDesc() { return GetMaxKrakatoaMagma2RenderElementDesc(); }

void MaxKrakatoaMagma2RenderElement::DefineParamBlock( ParamBlockDesc2* pParamDesc ) {
    MaxKrakatoaRenderElement<MaxKrakatoaMagma2RenderElement>::DefineParamBlock( pParamDesc );

    pParamDesc->ParamOption( kElementName, p_default, MaxKrakatoaMagmaRenderElement_CLASS_NAME, p_end );

    pParamDesc->AddParam( kMagmaHolder, _T("magmaHolder"), TYPE_REFTARG, P_RESET_DEFAULT | P_SUBANIM, 0, p_end );
}

krakatoa::render_element_interface*
MaxKrakatoaMagma2RenderElement::get_render_element( krakatoa::scene_context_ptr pSceneContext ) {
    bool doAntialias = m_pblock->GetInt( kDoFilter ) != FALSE;
    ReferenceTarget* pMagmaHolder = m_pblock->GetReferenceTarget( kMagmaHolder );

    boost::shared_ptr<frantic::magma::magma_interface> magmaInterface = GetMagmaInterface( pMagmaHolder );

    std::auto_ptr<magma_render_element> pElement(
        new magma_render_element( doAntialias, pSceneContext, magmaInterface ) );

    pElement->register_commit_callback( boost::bind( &MaxKrakatoaMagma2RenderElement::write_back, this, _1 ) );

    return pElement.release();
}

RefResult MaxKrakatoaMagma2RenderElement::NotifyRefChanged( const Interval& /*changeInt*/, RefTargetHandle /*hTarget*/,
                                                            PartID& /*partID*/, RefMessage /*message*/,
                                                            BOOL /*propagate*/ ) {
    return REF_SUCCEED;
}

class MaxKrakatoaMagma2RenderElementDlgProc : public ParamMap2UserDlgProc {
  public:
    MaxKrakatoaMagma2RenderElementDlgProc() {}

    virtual ~MaxKrakatoaMagma2RenderElementDlgProc() {}

    virtual INT_PTR DlgProc( TimeValue t, IParamMap2* map, HWND hWnd, UINT msg, WPARAM wParam, LPARAM lParam );

    virtual void DeleteThis() {}
};

ParamMap2UserDlgProc* GetMaxKrakatoaMagma2RenderElementDlgProc() {
    static MaxKrakatoaMagma2RenderElementDlgProc theMaxKrakatoaMagmaRenderElementDlgProc;
    return &theMaxKrakatoaMagmaRenderElementDlgProc;
}

INT_PTR MaxKrakatoaMagma2RenderElementDlgProc::DlgProc( TimeValue /*t*/, IParamMap2* map, HWND /*hWnd*/, UINT msg,
                                                        WPARAM wParam, LPARAM /*lParam*/ ) {
    IParamBlock2* pblock = map->GetParamBlock();
    if( !pblock )
        return FALSE;

    switch( msg ) {
    case WM_COMMAND:
        if( HIWORD( wParam ) == BN_CLICKED ) {
            if( LOWORD( wParam ) == IDC_BUTTON_RENDERELEMENT_MAGMA ) {
                // try{
                //	frantic::max3d::mxs::expression( "::FranticParticleRenderMXS.openMagmaFlowEditor magmaHolder" )
                //		.bind( "magmaHolder",
                //pblock->GetReferenceTarget(MaxKrakatoaMagma2RenderElement::kMagmaHolder) ) 		.evaluate<void>(); }catch(
                // const std::exception& e ){
                //	//e.sprin1( thread_local(current_stdout) );
                //	frantic::max3d::MsgBox( e.what(), "Error openening Magma editor" );
                // }
                try {
                    frantic::max3d::mxs::expression(
                        _T("try(::MagmaFlowEditor_Functions.OpenMagmaFlowEditor magmaHolder)catch()") )
                        .bind( _T("magmaHolder"),
                               pblock->GetReferenceTarget( MaxKrakatoaMagma2RenderElement::kMagmaHolder ) )
                        .evaluate<void>();
                } catch( const std::exception& e ) {
                    FF_LOG( error ) << e.what() << std::endl;
                } catch( ... ) {
                    // Can't allow max to crash by propogating any exceptions.
                    FF_LOG( error ) << _T("Unhandled exception in: ") << __FILE__ << _T(" line: ") << __LINE__
                                    << std::endl;
                }

                return TRUE;
            }
        }
        break;
    }

    return FALSE;
}

magma_render_element::magma_render_element()
    : m_doAntiAlias( true ) {}

namespace {
void null_deleter( void* ) {}
} // namespace

magma_render_element::magma_render_element( bool antiAlias, krakatoa::scene_context_ptr sceneContext,
                                            boost::shared_ptr<frantic::magma::magma_interface> magma ) {
    m_doAntiAlias = antiAlias;

    MaxKrakatoaRenderGlobalContext* rgc = NULL;
    if( MaxKrakatoaSceneContext* maxSceneContext = dynamic_cast<MaxKrakatoaSceneContext*>( sceneContext.get() ) )
        rgc = const_cast<MaxKrakatoaRenderGlobalContext*>(
            dynamic_cast<const MaxKrakatoaRenderGlobalContext*>( maxSceneContext->get_render_global_context() ) );

    frantic::max3d::particles::IMaxKrakatoaPRTEvalContextPtr pEvalContext( rgc, &null_deleter );

    boost::shared_ptr<MagmaMaxContextInterface> context( new MagmaMaxContextInterface( NULL, pEvalContext ) );

    m_magmaInterface = magma;
    // m_compiler.set_magma_interface( *m_magmaInterface );
    // m_compiler.set_context_data( context );
    m_compiler.set_abstract_syntax_tree( m_magmaInterface );
    m_compiler.set_compilation_context( context );
}

magma_render_element::~magma_render_element() {}

magma_render_element::draw_type magma_render_element::get_drawing_type() const {
    if( m_doAntiAlias ) {
        return draw_type_antialias;
    } else {
        return draw_type_solid;
    }
}

krakatoa::render_element_interface* magma_render_element::clone() {
    std::auto_ptr<magma_render_element> pResult( new magma_render_element );

    pResult->m_magmaInterface = m_magmaInterface;
    pResult->m_compiler.set_abstract_syntax_tree( m_magmaInterface );
    pResult->m_compiler.set_compilation_context( m_compiler.get_context_ptr() );

    pResult->m_doAntiAlias = m_doAntiAlias;
    pResult->m_outputMap = m_outputMap;
    pResult->m_accessor = m_accessor;

    if( m_accessor.is_valid() )
        pResult->m_compiler.reset( m_compiler.get_channel_map(), m_compiler.get_native_channel_map() );

    pResult->get_framebuffer().set_size( get_framebuffer().size() );
    pResult->get_framebuffer().fill( frantic::graphics::color6f( 0.f ) );

    return pResult.release();
}

void magma_render_element::set_channel_map( const frantic::channels::channel_map& pcm ) {
    m_compiler.reset( pcm, pcm );

    if( m_magmaInterface->get_num_outputs( frantic::magma::magma_interface::TOPMOST_LEVEL ) != 1 )
        throw std::runtime_error(
            "magma_render_element::set_channel_map() The specified flow has multiple outputs which is not valid" );

    frantic::magma::magma_interface::magma_id outputID =
        m_magmaInterface->get_output( frantic::magma::magma_interface::TOPMOST_LEVEL, 0 ).first;
    if( outputID < 0 )
        throw std::runtime_error(
            "magma_render_element::set_channel_map() The specified flow does not have a valid output #1" );

    frantic::tstring channelName;
    if( !m_magmaInterface->get_property<frantic::tstring>( outputID, _T("channelName"), channelName ) )
        throw std::runtime_error( "magma_render_element::set_channel_map() The specified flow does not have a valid "
                                  "output #1 with property \"channelName\"" );

    m_accessor = m_compiler.get_channel_map().get_const_cvt_accessor<frantic::graphics::color3f>( channelName );
    m_outputMap = pcm;
}

void magma_render_element::add_required_channels( frantic::channels::channel_map& pcm ) {
    typedef std::map<frantic::tstring, std::pair<frantic::channels::data_type_t, std::size_t>> type_map;
    static type_map g_channelDefaults;

    // HACK: This should be some sort of globally accessible thing at the very least. Possibly through
    //        krakatoa_context. A hard-coded list doesn't really make a ton of sense anyways though.
    if( g_channelDefaults.empty() ) {
        g_channelDefaults[_T("Position")] = std::make_pair( frantic::channels::data_type_float32, 3 );
        g_channelDefaults[_T("Velocity")] = std::make_pair( frantic::channels::data_type_float16, 3 );
        g_channelDefaults[_T("Color")] = std::make_pair( frantic::channels::data_type_float16, 3 );
        g_channelDefaults[_T("Absorption")] = std::make_pair( frantic::channels::data_type_float16, 3 );
        g_channelDefaults[_T("Emission")] = std::make_pair( frantic::channels::data_type_float16, 3 );
        g_channelDefaults[_T("Normal")] = std::make_pair( frantic::channels::data_type_float16, 3 );
        g_channelDefaults[_T("Tangent")] = std::make_pair( frantic::channels::data_type_float16, 3 );
        g_channelDefaults[_T("TextureCoord")] = std::make_pair( frantic::channels::data_type_float16, 3 );
        g_channelDefaults[_T("MXSVector")] = std::make_pair( frantic::channels::data_type_float16, 3 );
        g_channelDefaults[_T("Scale")] = std::make_pair( frantic::channels::data_type_float16, 3 );
        g_channelDefaults[_T("Acceleration")] = std::make_pair( frantic::channels::data_type_float16, 3 );
        g_channelDefaults[_T("DensityGradient")] = std::make_pair( frantic::channels::data_type_float16, 3 );

        g_channelDefaults[_T("Density")] = std::make_pair( frantic::channels::data_type_float16, 1 );
        g_channelDefaults[_T("Eccentricity")] = std::make_pair( frantic::channels::data_type_float16, 1 );
        g_channelDefaults[_T("SpecularPower")] = std::make_pair( frantic::channels::data_type_float16, 1 );
        g_channelDefaults[_T("SpecularLevel")] = std::make_pair( frantic::channels::data_type_float16, 1 );
        g_channelDefaults[_T("Selection")] = std::make_pair( frantic::channels::data_type_float16, 1 );
        g_channelDefaults[_T("MXSFloat")] = std::make_pair( frantic::channels::data_type_float16, 1 );
        g_channelDefaults[_T("SignedDistance")] = std::make_pair( frantic::channels::data_type_float16, 1 );
        g_channelDefaults[_T("Fire")] = std::make_pair( frantic::channels::data_type_float16, 1 );
        g_channelDefaults[_T("Fuel")] = std::make_pair( frantic::channels::data_type_float16, 1 );
        g_channelDefaults[_T("Temperature")] = std::make_pair( frantic::channels::data_type_float16, 1 );

        g_channelDefaults[_T("Age")] = std::make_pair( frantic::channels::data_type_float32, 1 );
        g_channelDefaults[_T("LifeSpan")] = std::make_pair( frantic::channels::data_type_float32, 1 );
        g_channelDefaults[_T("ID")] = std::make_pair( frantic::channels::data_type_int32, 1 );

        g_channelDefaults[_T("MtlIndex")] = std::make_pair( frantic::channels::data_type_int16, 1 );
        g_channelDefaults[_T("MXSInteger")] = std::make_pair( frantic::channels::data_type_int16, 1 );
    }

    // HACK: Make this recursive since its going to miss InputChannel nodes hidden inside of BLOPs at the moment.
    for( int i = 0, iEnd = m_magmaInterface->get_num_nodes( frantic::magma::magma_interface::TOPMOST_LEVEL ); i < iEnd;
         ++i ) {
        frantic::magma::magma_interface::magma_id id =
            m_magmaInterface->get_id( frantic::magma::magma_interface::TOPMOST_LEVEL, i );

        if( m_magmaInterface->get_type( id ) == _T("InputChannel") ) {
            frantic::tstring chName;
            m_magmaInterface->get_property<frantic::tstring>( id, _T("channelName"), chName );

            if( !pcm.has_channel( chName ) ) {
                type_map::const_iterator it = g_channelDefaults.find( chName );
                if( it != g_channelDefaults.end() )
                    pcm.define_channel( chName, it->second.second, it->second.first );
                else if( chName.substr( 0, 7 ) == _T("Mapping") )
                    pcm.define_channel( chName, 3, frantic::channels::data_type_float16 );
                else
                    throw std::runtime_error(
                        "A CustomData render element requires channel \"" + frantic::strings::to_string( chName ) +
                        "\" which is not a channel that is available while rendering.\nIf this channel is actually "
                        "available via your PRT object, you can use a KCM to move that channel into one of the "
                        "Mapping## channels which are available at render time." );
            }
        } /*else{
                 for( int j = 0, jEnd = m_magmaInterface->get_num_nodes( id ); j < jEnd; ++j )
                         recursive_call( m_magmaInterface, id, pcm, g_channelDefaults );
          }*/
    }
}

frantic::graphics::color3f magma_render_element::evaluate( const char* particle ) {
    char* tempBuffer = (char*)alloca( m_compiler.get_channel_map().structure_size() );

    // We can memcpy here since the destination particle is a subset of the particle layout used in m_compiledExpr.
    memcpy( tempBuffer, particle, m_outputMap.structure_size() );

    m_compiler.eval( tempBuffer, (std::size_t)-1 );

    return m_accessor.get( tempBuffer );
}
