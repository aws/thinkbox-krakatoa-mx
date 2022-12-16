// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0
#include "stdafx.h"

#include "MaxKrakatoa.h"
#include "MaxKrakatoaChannelModifier.h"
#include "MaxKrakatoaChannelTexmapOperator.h"
#include "MaxKrakatoaGeometryRenderer.h"
#include "MaxKrakatoaShadowGenerator.h"
//#include "MaxKrakatoaModifierInterface.h"

#include <krakatoa/atmosphere_impl.hpp>
#include <krakatoa/raytrace_renderer/raytrace_renderer.hpp>
#include <krakatoa/shader_functions.hpp>
#include <krakatoa/splat_renderer/splat_renderer.hpp>
#include <krakatoa/voxel_renderer/default_filter3f.hpp>
#include <krakatoa/voxel_renderer/voxel_renderer.hpp>
#include <krakatoa/watermark.hpp>

#include <krakatoa/max3d/IPRTModifier.hpp>

#include <frantic/max3d/geometry/auto_mesh.hpp>
#include <frantic/max3d/geometry/mesh.hpp>
#include <frantic/max3d/geopipe/named_selection_sets.hpp>
#include <frantic/max3d/particles/max3d_particle_utils.hpp>
#include <frantic/max3d/rendering/renderglobalcontext_view.hpp>
#include <frantic/max3d/shaders/map_query.hpp>
#include <frantic/max3d/shaders/max_environment_map_provider.hpp>

#include <frantic/geometry/trimesh3.hpp>
#include <frantic/graphics/camera.hpp>
#include <frantic/graphics/color3f.hpp>
#include <frantic/graphics/vector3f.hpp>
#include <frantic/particles/streams/apply_function_particle_istream.hpp>
#include <frantic/particles/streams/channel_operation_particle_istream.hpp>
#include <frantic/particles/streams/concatenated_particle_istream.hpp>
#include <frantic/particles/streams/fractional_particle_istream.hpp>
#include <frantic/particles/streams/particle_array_particle_istream.hpp>
#include <frantic/rendering/lights/directlight.hpp>
#include <frantic/rendering/lights/lightinterface.hpp>
#include <frantic/rendering/lights/pointlight.hpp>
#include <frantic/rendering/lights/spotlight.hpp>
#include <frantic/rendering/lights_accessor.hpp>

#include <boost/array.hpp>

#pragma warning( push )
#pragma warning( disable : 4100 4239 )
#include <lslights.h>
#include <shadgen.h>
#pragma warning( pop )

#define MR_OMNI_LIGHT_CLASS_ID Class_ID( 112233, 554433 )
#define MR_SPOT_LIGHT_CLASS_ID Class_ID( 112233, 554434 )

using namespace frantic;
using namespace frantic::particles;
using namespace frantic::particles::streams;
using namespace frantic::max3d;
using namespace frantic::max3d::particles;
using namespace frantic::max3d::particles::streams;

using frantic::graphics::alpha3f;
using frantic::graphics::camera;
using frantic::graphics::color3f;
using frantic::graphics::color6f;
using frantic::graphics::vector3f;
using frantic::graphics2d::framebuffer;

namespace {
inline bool try_get_bool( const frantic::properties::property_container& props, const frantic::tstring& name,
                          bool defaultValue = false ) {
    if( props.exists( name ) )
        return props.get_bool( name );
    return defaultValue;
}

inline int try_get_int( const frantic::properties::property_container& props, const frantic::tstring& name,
                        int defaultValue = 0 ) {
    if( props.exists( name ) )
        return props.get_int( name );
    return defaultValue;
}

inline float try_get_float( const frantic::properties::property_container& props, const frantic::tstring& name,
                            float defaultValue = 0.f ) {
    if( props.exists( name ) )
        return props.get_float( name );
    return defaultValue;
}
} // namespace

namespace particle_density_method {
enum particle_density_method_enum { volumetric_density, additive_density, constant_alpha };

inline particle_density_method_enum from_string( const frantic::tstring& str ) {
    if( str == _T("Volumetric Density") )
        return particle_density_method::volumetric_density;
    else if( str == _T("Additive Density") )
        return particle_density_method::additive_density;
    else if( str == _T("Constant Alpha") )
        return particle_density_method::constant_alpha;
    else
        throw std::runtime_error( "particle_density_method_enum::from_string(): Invalid density mode: \"" +
                                  frantic::strings::to_string( str ) + "\"" );
}
} // namespace particle_density_method

namespace matte_depth_map_method {
enum matte_depth_map_method_enum { camera_space, normalized_camera_space, normalized_camera_space_inverted };

inline matte_depth_map_method_enum from_string( const frantic::tstring& str ) {
    if( str == _T("Camera Space Z Depth") )
        return camera_space;
    else if( str == _T("Normalized Z Depth") )
        return normalized_camera_space;
    else if( str == _T("Inverted Normalized Z Depth") )
        return normalized_camera_space_inverted;
    else
        throw std::runtime_error( "matte_depth_map_method::from_string() received an invalid string: \"" +
                                  frantic::strings::to_string( str ) + "\"" );
}
} // namespace matte_depth_map_method

inline bool IsZero( Matrix3& m ) {
    float* data = (float*)m.GetAddr();
    for( int i = 0; i < 12; ++i, ++data ) {
        if( std::abs( *data ) > 0.00001f )
            return false;
    }
    return true;
}

struct ops {
    static color3f color_by_cam_z( const vector3f& pos, const camera<float>& cam ) {
        return color3f( -( cam.world_transform_inverse() * pos ).z );
    }
    static color3f color_by_cam_dist( const vector3f& pos, const camera<float>& cam ) {
        return color3f( ( cam.world_transform_inverse() * pos ).get_magnitude() );
    }

    // Parameter names for each operation
    static boost::array<frantic::tstring, 1> colorByCamZChannels;
    static boost::array<frantic::tstring, 1> colorByCamDistChannels;
};

boost::array<frantic::tstring, 1> ops::colorByCamZChannels = { _T("Position") };
boost::array<frantic::tstring, 1> ops::colorByCamDistChannels = { _T("Position") };

frantic::tstring MaxKrakatoa::GetRenderOutputFiles( TimeValue time ) {
    int frame = time / GetTicksPerFrame();

    frantic::tstring imageFile;

    frantic::tstring renderTarget = m_properties.get( _T("RenderTarget") );
    if( renderTarget == _T("Direct Render") ) {
        if( GetCOREInterface()->GetRendSaveFile() ) {
            imageFile = GetCOREInterface()->GetRendFileBI().Name();
            if( GetCOREInterface()->GetRendTimeType() != REND_TIMESINGLE )
                imageFile = files::replace_sequence_number( imageFile, frame, 4 );
        }
    } else if( renderTarget == _T("Save To XML") ) {
        frantic::tstring xmlFile = m_properties.get( _T("XMLOutputFiles") );
        if( GetCOREInterface()->GetRendSaveFile() ) {
            imageFile = files::replace_extension( GetCOREInterface()->GetRendFileBI().Name(), _T(".exr") );
        } else {
            imageFile = files::replace_extension( xmlFile, _T(".exr") );
        }
        imageFile = files::replace_sequence_number( imageFile, frame );
    }

    return imageFile;
}

frantic::tstring MaxKrakatoa::GetShadowOutputFiles( TimeValue t ) {
    if( GetCOREInterface()->GetRendSaveFile() ) {
        const TCHAR* outFile = GetCOREInterface()->GetRendFileBI().Name();
        if( outFile ) {
            frantic::tstring filename;
            filename = frantic::files::filename_from_path( outFile );
            filename = frantic::files::replace_sequence_number( filename, t / GetTicksPerFrame() );
            filename = frantic::files::replace_extension( filename, _T(".exr") );

            boost::filesystem::path p( outFile );
            p = p.branch_path() / _T("shadows") / filename;

            boost::filesystem::create_directory( p.parent_path() ); // Ensure the containing directory exists

            return p.string<frantic::tstring>();
        }
    }

    return _T("");
}

#define TOSTRING_IMPL( x ) #x
#define TOSTRING( x ) TOSTRING_IMPL( x )

void null_deleter( void* ) {}

MaxKrakatoa::particle_istream_ptr MaxKrakatoa::ApplyChannelOverrides( MaxKrakatoa::particle_istream_ptr pin ) {
    if( !m_pblockOverrides ) {
        FF_LOG( error )
            << _T("Fatal error in MaxKrakatoa::ApplyChannelOverrides() The renderer's parameter block was NULL")
            << std::endl;

        return pin;
    }

    Interval validity = FOREVER;

    frantic::max3d::particles::IMaxKrakatoaPRTEvalContextPtr pEvalContext( &m_renderGlobalContext, &null_deleter );

    float globalPercentage = m_properties.get_float( _T("GlobalParticlePercentage") );
    if( globalPercentage <= 0.f )
        return boost::shared_ptr<particle_istream>( new empty_particle_istream( pin->get_channel_map() ) );
    else if( globalPercentage < 100.f ) {
        pin.reset( new fractional_particle_istream( pin, globalPercentage * 0.01f ) );
        pin.reset( new density_scale_particle_istream( pin, 100.f / globalPercentage ) );
    }

    frantic::tstring globalHolderName = m_properties.get( _T("GlobalDataHolder") );
    if( !globalHolderName.empty() ) {
        INode* pNode = GetCOREInterface()->GetINodeByName( globalHolderName.c_str() );
        if( !pNode ) {
            FF_LOG( warning ) << _T("The GlobalOverride KCM holder \"") << globalHolderName
                              << _T("\"  was not found. Did you delete it?") << std::endl;
        } else {
            std::vector<Modifier*> mods;
            frantic::max3d::get_modifier_stack( mods, pNode );

            for( std::vector<Modifier*>::reverse_iterator it = mods.rbegin(), itEnd = mods.rend(); it != itEnd; ++it ) {
                if( krakatoa::max3d::IPRTModifier* imod = krakatoa::max3d::GetPRTModifierInterface( *it ) )
                    pin = imod->ApplyModifier( pin, pNode, pEvalContext->GetTime(), validity, pEvalContext );
                else if( is_krakatoa_channel_modifier( *it ) )
                    pin = get_krakatoa_channel_modifier_particle_istream(
                        pin, m_renderGlobalContext.get_scene_context(), pNode, *it );
            }

            FF_LOG( debug ) << _T("Applied KCMs from global holder: \"") << globalHolderName << std::endl;
        }
    }

    if( m_properties.get_bool( _T("ColorOverride:Enabled") ) ) {
        FF_LOG( debug ) << _T("Applying color override") << std::endl;
        std::vector<frantic::channels::channel_op_node*> pNodes;
        Texmap* pMap = m_pblockOverrides->GetTexmap( kColorOverrideTexmap );
        color3f overrideColor = color6f::parse_maxscript( m_properties.get( _T("ColorOverride:Color") ) ).c;
        if( pMap ) {
            float blendAmount = m_properties.get_float( _T("ColorOverride:BlendAmount") );
            if( blendAmount < 100.f ) {
                blendAmount /= 100.f;
                pNodes.push_back( new frantic::channels::output_channel_op_node(
                    0, 1, "Color", 3, frantic::channels::data_type_float32 ) );
                pNodes.push_back( new frantic::channels::blend_node( 1, 2, 3, 4 ) );
                pNodes.push_back( new frantic::channels::input_value_op_node<float, 3>( 2, &overrideColor.r ) );
                pNodes.push_back( CreateMaxKrakatoaChannelTexmapOperator(
                    3, pMap, texmap_output::color, m_renderGlobalContext.get_scene_context(), NULL, true ) );
                pNodes.push_back( new frantic::channels::input_value_op_node<float, 1>( 4, &blendAmount ) );
            } else {
                pNodes.push_back( new frantic::channels::output_channel_op_node(
                    0, 1, "Color", 3, frantic::channels::data_type_float32 ) );
                pNodes.push_back( CreateMaxKrakatoaChannelTexmapOperator(
                    1, pMap, texmap_output::color, m_renderGlobalContext.get_scene_context(), NULL, true ) );
            }
        } else {
            pNodes.push_back( new frantic::channels::output_channel_op_node( 0, 1, "Color", 3,
                                                                             frantic::channels::data_type_float32 ) );
            pNodes.push_back( new frantic::channels::input_value_op_node<float, 3>( 1, &overrideColor.r ) );
        }
        pin.reset( new frantic::particles::streams::channel_operation_particle_istream( pin, pNodes, NULL ) );
    }

    if( m_properties.get_bool( _T("AbsorptionOverride:Enabled") ) ) {
        FF_LOG( debug ) << _T("Applying absorption override") << std::endl;
        std::vector<frantic::channels::channel_op_node*> pNodes;
        Texmap* pMap = m_pblockOverrides->GetTexmap( kAbsorptionOverrideTexmap );
        color3f overrideColor = color6f::parse_maxscript( m_properties.get( _T("AbsorptionOverride:Color") ) ).c;
        if( pMap ) {
            float blendAmount = m_properties.get_float( _T("AbsorptionOverride:BlendAmount") );
            if( blendAmount < 100.f ) {
                blendAmount /= 100.f;
                pNodes.push_back( new frantic::channels::output_channel_op_node(
                    0, 1, "Absorption", 3, frantic::channels::data_type_float32 ) );
                pNodes.push_back( new frantic::channels::blend_node( 1, 2, 3, 4 ) );
                pNodes.push_back( new frantic::channels::input_value_op_node<float, 3>( 2, &overrideColor.r ) );
                pNodes.push_back( CreateMaxKrakatoaChannelTexmapOperator(
                    3, pMap, texmap_output::color, m_renderGlobalContext.get_scene_context(), NULL, true ) );
                pNodes.push_back( new frantic::channels::input_value_op_node<float, 1>( 4, &blendAmount ) );
            } else {
                pNodes.push_back( new frantic::channels::output_channel_op_node(
                    0, 1, "Absorption", 3, frantic::channels::data_type_float32 ) );
                pNodes.push_back( CreateMaxKrakatoaChannelTexmapOperator(
                    1, pMap, texmap_output::color, m_renderGlobalContext.get_scene_context(), NULL, true ) );
            }
        } else {
            pNodes.push_back( new frantic::channels::output_channel_op_node( 0, 1, "Absorption", 3,
                                                                             frantic::channels::data_type_float32 ) );
            pNodes.push_back( new frantic::channels::input_value_op_node<float, 3>( 1, &overrideColor.r ) );
        }
        pin.reset( new frantic::particles::streams::channel_operation_particle_istream( pin, pNodes, NULL ) );
    }

    if( m_properties.get_bool( _T("EmissionOverride:Enabled") ) ) {
        FF_LOG( debug ) << _T("Applying emission override") << std::endl;
        std::vector<frantic::channels::channel_op_node*> pNodes;
        Texmap* pMap = m_pblockOverrides->GetTexmap( kEmissionOverrideTexmap );
        color3f overrideColor = color6f::parse_maxscript( m_properties.get( _T("EmissionOverride:Color") ) ).c;
        if( pMap ) {
            float blendAmount = m_properties.get_float( _T("EmissionOverride:BlendAmount") );
            if( blendAmount < 100.f ) {
                blendAmount /= 100.f;
                pNodes.push_back( new frantic::channels::output_channel_op_node(
                    0, 1, "Emission", 3, frantic::channels::data_type_float32 ) );
                pNodes.push_back( new frantic::channels::blend_node( 1, 2, 3, 4 ) );
                pNodes.push_back( new frantic::channels::input_value_op_node<float, 3>( 2, &overrideColor.r ) );
                pNodes.push_back( CreateMaxKrakatoaChannelTexmapOperator(
                    3, pMap, texmap_output::color, m_renderGlobalContext.get_scene_context(), NULL, true ) );
                pNodes.push_back( new frantic::channels::input_value_op_node<float, 1>( 4, &blendAmount ) );
            } else {
                pNodes.push_back( new frantic::channels::output_channel_op_node(
                    0, 1, "Emission", 3, frantic::channels::data_type_float32 ) );
                pNodes.push_back( CreateMaxKrakatoaChannelTexmapOperator(
                    1, pMap, texmap_output::color, m_renderGlobalContext.get_scene_context(), NULL, true ) );
            }
        } else {
            pNodes.push_back( new frantic::channels::output_channel_op_node( 0, 1, "Emission", 3,
                                                                             frantic::channels::data_type_float32 ) );
            pNodes.push_back( new frantic::channels::input_value_op_node<float, 3>( 1, &overrideColor.r ) );
        }
        pin.reset( new frantic::particles::streams::channel_operation_particle_istream( pin, pNodes, NULL ) );
    }

    if( m_properties.get_bool( _T("DensityOverride:Enabled") ) ) {
        FF_LOG( debug ) << _T("Applying density override") << std::endl;
        std::vector<frantic::channels::channel_op_node*> pNodes;
        Texmap* pMap = m_pblockOverrides->GetTexmap( kDensityOverrideTexmap );
        float overrideValue = m_properties.get_float( _T("DensityOverride:Value") );

        if( pMap ) {
            float blendAmount = m_properties.get_float( _T("DensityOverride:BlendAmount") );
            if( blendAmount < 100.f ) {
                blendAmount /= 100.f;
                pNodes.push_back( new frantic::channels::output_channel_op_node(
                    0, 1, "Density", 1, frantic::channels::data_type_float32 ) );
                pNodes.push_back( new frantic::channels::blend_node( 1, 2, 3, 4 ) );
                pNodes.push_back( new frantic::channels::input_value_op_node<float, 1>( 2, &overrideValue ) );
                pNodes.push_back( CreateMaxKrakatoaChannelTexmapOperator(
                    3, pMap, texmap_output::mono, m_renderGlobalContext.get_scene_context(), NULL, true ) );
                pNodes.push_back( new frantic::channels::input_value_op_node<float, 1>( 4, &blendAmount ) );
            } else {
                pNodes.push_back( new frantic::channels::output_channel_op_node(
                    0, 1, "Density", 1, frantic::channels::data_type_float32 ) );
                pNodes.push_back( CreateMaxKrakatoaChannelTexmapOperator(
                    1, pMap, texmap_output::mono, m_renderGlobalContext.get_scene_context(), NULL, true ) );
            }
        } else {
            pNodes.push_back( new frantic::channels::output_channel_op_node( 0, 1, "Density", 1,
                                                                             frantic::channels::data_type_float32 ) );
            pNodes.push_back( new frantic::channels::input_value_op_node<float, 1>( 1, &overrideValue ) );
        }
        pin.reset( new frantic::particles::streams::channel_operation_particle_istream( pin, pNodes, NULL ) );
    }

    return pin;
}

boost::shared_ptr<particle_istream> MaxKrakatoa::GetSceneParticleStream( const channel_map& pcm,
                                                                         const frantic::tstring& savingFile ) {
    frantic::diagnostics::profiling_section psGetSceneParticleStream( _T("Evaluating Particle Objects") );
    psGetSceneParticleStream.enter();

    boost::shared_ptr<particle_istream> pin;
    {
        std::vector<boost::shared_ptr<particle_istream>> pins;
        for( std::size_t i = 0; i < m_particleSystems.size(); ++i ) {
            FF_LOG( debug ) << _T("Evaluating particle stream from ") << m_particleSystems[i].GetNode()->GetName()
                            << _T(" at time ") << m_renderGlobalContext.time << std::endl;

            m_particleSystems[i].AssertNotLoadingFrom( savingFile );

            boost::shared_ptr<particle_istream> curPin =
                m_particleSystems[i].GetParticleStream( &m_renderGlobalContext );

            if( curPin ) {
                pins.push_back( curPin );
            } else {
                FF_LOG( warning ) << _T("NULL particle_istream returned from \"")
                                  << m_particleSystems[i].GetNode()->GetName() << _T("\"") << std::endl;
            }
        }

        if( pins.size() == 0 )
            pin.reset( new empty_particle_istream( pcm ) );
        else if( pins.size() == 1 )
            pin = pins[0];
        else
            pin.reset( new concatenated_particle_istream( pins ) );
    }

    // Don't apply any more streams to empty particle streams.
    if( pin->particle_count() != 0 )
        pin = ApplyChannelOverrides( pin );

    FF_LOG( debug ) << _T("The stream contained ")
                    << ( pin->particle_count() >= 0 ? boost::lexical_cast<frantic::tstring>( pin->particle_count() )
                                                    : _T("an unknown amount of") )
                    << _T(" particles") << std::endl;

    psGetSceneParticleStream.exit();

    FF_LOG( stats ) << psGetSceneParticleStream << std::endl;

    return pin;
}

void MaxKrakatoa::RetrieveParticles( ParticleContainerType& outParticles ) {
    frantic::max3d::logging::maxrender_progress_logger progress( m_progressCallback, _T("Updating Objects") );

    const channels::channel_map& pcm = outParticles.get_channel_map();
    boost::shared_ptr<particle_istream> pin = GetSceneParticleStream( pcm, _T("") );
    pin->set_channel_map( pcm );

    boost::scoped_array<char> defaultParticle( new char[pcm.structure_size()] );
    memset( defaultParticle.get(), 0, pcm.structure_size() );
    if( pcm.has_channel( _T("Density") ) )
        pcm.get_cvt_accessor<float>( _T("Density") ).set( defaultParticle.get(), 1.f );
    if( pcm.has_channel( _T("Selection") ) )
        pcm.get_cvt_accessor<float>( _T("Selection") ).set( defaultParticle.get(), 1.f );
    if( pcm.has_channel( _T("Color") ) )
        pcm.get_cvt_accessor<color3f>( _T("Color") ).set( defaultParticle.get(), color3f( 1.f ) );
    if( pcm.has_channel( _T( "BokehBlendInfluence" ) ) ) {
        pcm.get_cvt_accessor<float>( _T( "BokehBlendInfluence" ) ).set( defaultParticle.get(), m_bokehBlendInfluence );
    }

    // TODO: These should not be hard-coded, but set by the shader.
    if( pcm.has_channel( _T("Eccentricity") ) )
        pcm.get_cvt_accessor<float>( _T("Eccentricity") )
            .set( defaultParticle.get(), m_properties.get_float( _T("PhaseEccentricity") ) );
    if( pcm.has_channel( _T("SpecularPower") ) )
        pcm.get_cvt_accessor<float>( _T("SpecularPower") )
            .set( defaultParticle.get(), m_properties.get_float( _T("Lighting:Specular:SpecularPower") ) );
    if( pcm.has_channel( _T("SpecularLevel") ) )
        pcm.get_cvt_accessor<float>( _T("SpecularLevel") )
            .set( defaultParticle.get(), m_properties.get_float( _T("Lighting:Specular:Level") ) / 100.f );
    pin->set_default_particle( defaultParticle.get() );

    progress.set_title( _T("Retrieving Particles") );
    frantic::diagnostics::profiling_section psRetrieve( _T("Retrieving Particles") );

    psRetrieve.enter();
    outParticles.resize( 0 );

#ifdef _WIN64
    if( pin->particle_count() < 0 ) {
        boost::int64_t streamGuess = pin->particle_count_guess();
        boost::int64_t userGuess = 0;
        if( m_properties.get_bool( _T("Memory:PreAllocation:Use") ) )
            userGuess = static_cast<boost::int64_t>(
                static_cast<double>( m_properties.get_float( _T("Memory:PreAllocation:ParticleCountInMillions") ) ) *
                1000000.0 );

        boost::int64_t guess = std::max( streamGuess, userGuess );
        if( guess < 1000000 )
            guess = 1000000;

        outParticles.reserve( guess );
        FF_LOG( debug ) << _T("The stream guesses that it has about ") << guess << _T(" particles") << std::endl;
    } else {
        outParticles.reserve( pin->particle_count() );
    }
#endif

    outParticles.insert_particles( pin, progress );

    psRetrieve.exit();

    // Do a check for infinite or NaN positions, deleting these particles.
    frantic::channels::channel_accessor<vector3f> posAccessor = pcm.get_accessor<vector3f>( _T("Position") );
    for( ParticleContainerType::iterator it = outParticles.begin(), itEnd = outParticles.end(); it != itEnd;
         /*Do nothing*/ ) {
        if( !posAccessor.get( *it ).is_finite() ) {
            if( --itEnd != it )
                memcpy( *it, *itEnd, pcm.structure_size() );
            outParticles.pop_back();
        } else
            ++it;
    }

    FF_LOG( stats ) << psRetrieve << std::endl;
}

void MaxKrakatoa::SetupCamera( frantic::graphics::camera<float>& outCamera, frantic::graphics::transform4f& outDerivTM,
                               bool& outIsEnvCamera, frantic::graphics2d::size2 imageSize, ViewParams* viewParams,
                               TimeValue t ) {
    using namespace frantic::graphics;
    using frantic::max3d::get_parameter;

    float motionBlurInterval = m_properties.get_float( _T("ShutterAngleInDegrees") ) / 360.f;
    float shutterBias = m_properties.get_float( _T("ShutterBias") );

    outIsEnvCamera = false;

    if( m_viewNode ) {
        bool disableCameraMotionBlur = m_properties.get_bool( _T( "DisableCameraMotionBlur" ) );
        outCamera =
            camera<float>( m_viewNode, t, imageSize, motionBlurInterval, shutterBias, 0, disableCameraMotionBlur );

        Matrix3 curTM = Inverse( m_viewNode->GetNodeTM( t ) );
        Matrix3 nextTM = Inverse( m_viewNode->GetNodeTM( t + 10 ) );

        nextTM -= curTM;
        nextTM *= static_cast<float>( static_cast<double>( TIME_TICKSPERSEC ) / 10.0 );

        outDerivTM = frantic::max3d::from_max_t( nextTM );

        std::vector<Modifier*> modStack;
        frantic::max3d::get_modifier_stack( modStack, m_viewNode );

        // Krakatoa has a scripted camera modifier that allows various parameters to be overriden.
        // We need to check if it is present.
        for( std::vector<Modifier*>::reverse_iterator it = modStack.rbegin(), itEnd = modStack.rend(); it != itEnd;
             ++it ) {
            if( ( *it )->IsEnabled() && ( *it )->ClassID() == Class_ID( 0x134f9c63, 0x366ca300 ) ) {
                if( get_parameter<bool>( *it, t, _T("useCameraType") ) ) {
                    int mode = get_parameter<int>( *it, t, _T("cameraType") ) - 1;

                    projection_mode::projection_mode modes[] = {
                        projection_mode::perspective, projection_mode::orthographic, projection_mode::spherical,
                        projection_mode::perspective };

                    if( mode == 3 ) // This isn't ideal...
                        outIsEnvCamera = true;

                    outCamera.set_projection_mode( modes[mode] );
                }

                if( get_parameter<bool>( *it, t, _T("useFOV") ) ) {
                    float fov = get_parameter<float>( *it, t, _T("FOV") );
                    outCamera.set_horizontal_fov_degrees( fov );
                }

                if( get_parameter<bool>( *it, t, _T("dofOn") ) ) {
                    float fStop = get_parameter<float>( *it, t, _T("fStop") );
                    outCamera.set_fstop( fStop );
                }

                if( get_parameter<bool>( *it, t, _T("useSubPixelOffset") ) ) {
                    float subpixelOffsetX = get_parameter<float>( *it, t, _T("subPixelOffsetX") );
                    float subpixelOffsetY = get_parameter<float>( *it, t, _T("subPixelOffsetY") );
                    outCamera.set_subpixel_offset( frantic::graphics2d::vector2f( subpixelOffsetX, subpixelOffsetY ) );
                }

                if( get_parameter<bool>( *it, t, _T("focalDepthOn") ) ) {
                    float dist = get_parameter<float>( *it, t, _T("focalDepth") );
                    outCamera.set_focal_distance( dist );
                }
            }
        }

        FF_LOG( debug ) << _T("Created a ") << frantic::strings::to_tstring( outCamera.projection_mode_string() )
                        << _T(" camera from node: ") << m_viewNode->GetName() << std::endl;
    } else if( m_useViewParams ) {
        outCamera = camera<float>( m_viewParams, imageSize );
        FF_LOG( debug ) << _T("Created a ") << frantic::strings::to_tstring( outCamera.projection_mode_string() )
                        << _T(" camera from ViewParams.") << std::endl;
    } else
        throw std::runtime_error(
            "MaxKrakatoa::GetCamera() - A camera could not be created because there is no viewnode or viewparams" );

    // See if there is an override on the camera's TM (Caused by Multi-pass DOF)
    if( viewParams && !IsZero( viewParams->affineTM ) ) {
        viewParams->affineTM.Invert();
        viewParams->affineTM.NoScale();
        outCamera.set_transform( viewParams->affineTM );

        viewParams->prevAffineTM.Invert();
        viewParams->prevAffineTM.NoScale();

        Matrix3 diff = viewParams->affineTM;
        diff -= viewParams->prevAffineTM;
        diff *=
            static_cast<float>( static_cast<double>( TIME_TICKSPERSEC ) / 2.0 ); // prevAffineTM if from 2 ticks ago.

        outDerivTM = frantic::max3d::from_max_t( diff );
    }
}

namespace {
bool IsSubClassOf_GenLight( Object* obj ) {
    return obj->IsSubClassOf( Class_ID( OMNI_LIGHT_CLASS_ID, 0x0 ) ) ||
           obj->IsSubClassOf( Class_ID( SPOT_LIGHT_CLASS_ID, 0x0 ) ) ||
           obj->IsSubClassOf( Class_ID( FSPOT_LIGHT_CLASS_ID, 0x0 ) ) ||
           obj->IsSubClassOf( Class_ID( DIR_LIGHT_CLASS_ID, 0x0 ) ) ||
           obj->IsSubClassOf( Class_ID( TDIR_LIGHT_CLASS_ID, 0x0 ) ) || obj->IsSubClassOf( MR_OMNI_LIGHT_CLASS_ID ) ||
           obj->IsSubClassOf( MR_SPOT_LIGHT_CLASS_ID );
}
} // namespace

void GetLightsRecursive( INode* rootNode, MaxKrakatoaRenderGlobalContext& rcontext ) {
    for( int i = 0, iEnd = rootNode->NumberOfChildren(); i < iEnd; ++i )
        GetLightsRecursive( rootNode->GetChildNode( i ), rcontext );

    ObjectState os = rootNode->EvalWorldState( rcontext.time );

    if( os.obj && os.obj->SuperClassID() == LIGHT_CLASS_ID )
        rcontext.add_light( rootNode );
}

void GetLights( INode* sceneRoot, MaxKrakatoaRenderGlobalContext& rcontext ) {
    for( int i = 0, iEnd = sceneRoot->NumberOfChildren(); i < iEnd; ++i )
        GetLightsRecursive( sceneRoot->GetChildNode( i ), rcontext );

    // Don't process the scene root since it's not a real node.
}

#pragma warning( push )
#pragma warning( disable : 4706 )
void SetupLightsRecursive( std::vector<boost::shared_ptr<frantic::rendering::lights::lightinterface>>& outLights,
                           INode* pNode, std::set<INode*>& doneNodes, TimeValue t,
                           frantic::logging::progress_logger& progress, float motionInterval, float motionBias,
                           bool saveAtten ) {
    if( !pNode || doneNodes.find( pNode ) != doneNodes.end() )
        return;
    doneNodes.insert( pNode );

    FF_LOG( debug ) << _T("Processing node \"") << pNode->GetName() << _T("\" for extracting lights") << std::endl;

    // This if statement might look silly, but it was the most concise way to do what I wanted without nesting
    // uselessly.
    Object* pObj = pNode->GetObjectRef();
    if( pObj && ( pObj = pObj->FindBaseObject() ) && pObj->SuperClassID() == LIGHT_CLASS_ID ) {
        progress.set_title( _T("Updating Light \"") + frantic::tstring( pNode->GetName() ) + _T("\"") );

        LightObject* lightObj = static_cast<LightObject*>( pObj );
        LightState lightState;

        Interval ivalid = FOREVER;
        if( lightObj->EvalLightState( t, ivalid, &lightState ) == REF_SUCCEED && lightState.on &&
            lightState.intens > 0.f ) {
            int decayExponent = 2;
            float unitDecayDistance = 40.f;
            float shadowDensity = 1.f;

            ShadowType* pShadType = NULL;

            if( IsSubClassOf_GenLight( lightObj ) ) {
                decayExponent = ( (GenLight*)lightObj )->GetDecayType();
                unitDecayDistance = ( (GenLight*)lightObj )->GetDecayRadius( t );
                pShadType = ( (GenLight*)lightObj )->GetShadowGenerator();
                shadowDensity = ( (GenLight*)lightObj )->GetShadMult( t );
            } else if( lightObj->IsSubClassOf( LIGHTSCAPE_LIGHT_CLASS ) ) {
                pShadType = ( (LightscapeLight*)lightObj )->GetShadowGenerator();
            }

            int shadowMapSize = 512;
            if( pShadType ) {
                shadowMapSize = pShadType->GetMapSize( t );
                if( shadowMapSize <= 0 )
                    shadowMapSize = 512;
            }

            // These were causing assertions in the debug builds of max ...
            // float shadowDensity = max3d::mxs::expression(_T("try(obj.shadowMultiplier)catch(1.0)")).bind(_T("obj"),
            // lightObj).at_time(t).evaluate<float>(); int shadowMapSize =
            // max3d::mxs::expression(_T("try(obj.mapsize)catch(512)")).bind(_T("obj"),
            // lightObj).at_time(t).evaluate<int>();

            float multiplier = lightState.intens * 4 * (float)M_PI;
            if( decayExponent == 1 )
                multiplier *= unitDecayDistance;
            else if( decayExponent == 2 )
                multiplier *= unitDecayDistance * unitDecayDistance;

            color3f color = color3f( lightState.color ) * multiplier;
            frantic::graphics::motion_blurred_transform<float> lightTransform( pNode, t, motionInterval, motionBias,
                                                                               NULL );

            frantic::tstring name = pNode->GetName();
            bool shadowsEnabled = ( lightState.shadow != FALSE );

            // for near/far threshold light attenuation
            bool useNearAtten = ( lightState.useNearAtten != FALSE );
            bool useFarAtten = ( lightState.useAtten != FALSE );
            float nearAttenuationStart = lightState.nearAttenStart;
            float nearAttenuationEnd = lightState.nearAttenEnd;
            float farAttenuationStart = lightState.attenStart;
            float farAttenuationEnd = lightState.attenEnd;
            if( farAttenuationEnd < farAttenuationStart )
                farAttenuationEnd = farAttenuationStart;
            if( nearAttenuationEnd < nearAttenuationStart )
                nearAttenuationEnd = nearAttenuationStart;

            frantic::tstring attenPath = _T("");
            int numAttenSamples = 1;
            float attenSampleSpacing = 1.f;
            bool attenSampleExponential = false;

            if( pShadType && pShadType->ClassID() == Class_ID( 0x7987316c, 0x2892318f ) && saveAtten ) {
                frantic::max3d::mxs::frame<1> f;
                frantic::max3d::mxs::local<Value> result( f );

                static const MCHAR* script = _T("#(")
                                             _T("obj.ShadowGenerator.GetExpandedSavePath obj, ")
                                             _T("obj.ShadowGenerator.ShadowSampleCount, ")
                                             _T("obj.ShadowGenerator.ShadowSampleSpacing, ")
                                             _T("obj.ShadowGenerator.ShadowSampleSpacingIsExponential, ")
                                             _T("obj.ShadowGenerator.ShadowFilenameAutoUpdate")
                                             _T(")");

                result =
                    frantic::max3d::mxs::expression( script ).bind( _T("obj"), pNode ).at_time( t ).evaluate<Value*>();

                bool autoUpdate = false;
                boost::tie( attenPath, numAttenSamples, attenSampleSpacing, attenSampleExponential, autoUpdate ) =
                    frantic::max3d::mxs::extract_tuple<frantic::tstring, int, float, bool, bool>( result );

                // Substitute the closest frame number in here. This might not be the best way to handle it.
                saveAtten = !attenPath.empty();
                if( saveAtten ) {
                    if( autoUpdate ) {
                        frantic::max3d::mxs::frame<1> f;
                        frantic::max3d::mxs::local<String> thePath( f );

                        thePath = new String( attenPath.c_str() );

                        frantic::max3d::mxs::expression( _T("obj.ShadowGenerator.ShadowFilename = thePath") )
                            .bind( _T("obj"), pNode )
                            .bind( _T("thePath"), thePath )
                            .evaluate<void>();
                    }
                    attenPath = frantic::files::replace_sequence_number(
                        attenPath, (int)floor( (float)t / (float)GetTicksPerFrame() + 0.5f ) );
                }
            }

            // ensure the directory for the attenuation file that will be saved is created.
            if( saveAtten ) {
                if( !attenPath.empty() ) {
                    boost::filesystem::path saveDir( attenPath );
                    if( !boost::filesystem::is_directory( saveDir ) )
                        saveDir = saveDir.branch_path();
                    boost::filesystem::create_directories( saveDir );
                }
            }

            // add this light to outLights
            switch( lightState.type ) {
            case OMNI_LGT: {
                boost::shared_ptr<frantic::rendering::lights::lightinterface> pLight(
                    new frantic::rendering::lights::pointlight(
                        name, lightTransform, color, decayExponent, shadowsEnabled, shadowDensity, shadowMapSize,
                        useNearAtten, useFarAtten, nearAttenuationStart, nearAttenuationEnd, farAttenuationStart,
                        farAttenuationEnd ) );
                if( saveAtten ) {
                    boost::shared_ptr<frantic::rendering::atten_saver> attenSaver(
                        new frantic::rendering::cubeface_atten_exr_saver(
                            attenPath, shadowMapSize, numAttenSamples, attenSampleSpacing, attenSampleExponential ) );
                    pLight->set_attenuation_saver( attenSaver );
                }
                // pLight->set_attenuation_loader( attenLoader ); //TODO: someday add importing pre-rendered deep
                // shadows into MX like this (like SR)
                outLights.push_back( pLight );
                break;
            }
            case SPOT_LGT: {
                frantic::rendering::lights::LIGHT_SHAPE shape =
                    (frantic::rendering::lights::LIGHT_SHAPE)lightState.shape;
                float aspect = ( shape == frantic::rendering::lights::LIGHT_SHAPE_SQUARE ) ? lightState.aspect : 1.f;
                float innerRadius = math::degrees_to_radians(
                    lightState.hotsize / 2 ); // divide by two since the constructor takes the half angle
                float outerRadius = math::degrees_to_radians(
                    lightState.fallsize / 2 ); // divide by two since the constructor takes the half angle

                if( outerRadius < innerRadius )
                    outerRadius = innerRadius;

                boost::shared_ptr<frantic::rendering::lights::lightinterface> pLight(
                    new frantic::rendering::lights::spotlight(
                        name, lightTransform, color, decayExponent, shadowsEnabled, shadowDensity, shadowMapSize,
                        useNearAtten, useFarAtten, nearAttenuationStart, nearAttenuationEnd, farAttenuationStart,
                        farAttenuationEnd, shape, aspect, innerRadius, outerRadius ) );
                if( saveAtten ) {
                    frantic::graphics2d::size2 mapDim( shadowMapSize, shadowMapSize );
                    boost::shared_ptr<frantic::rendering::atten_saver> attenSaver(
                        new frantic::rendering::singleface_atten_exr_saver(
                            attenPath, mapDim, numAttenSamples, attenSampleSpacing, attenSampleExponential ) );
                    pLight->set_attenuation_saver( attenSaver );
                }
                // pLight->set_attenuation_loader( attenLoader ); //TODO: someday add importing pre-rendered deep
                // shadows into MX like this (like SR)
                outLights.push_back( pLight );
                break;
            }
            case DIRECT_LGT: {
                frantic::rendering::lights::LIGHT_SHAPE shape =
                    (frantic::rendering::lights::LIGHT_SHAPE)lightState.shape;
                float aspect = ( shape == frantic::rendering::lights::LIGHT_SHAPE_SQUARE ) ? lightState.aspect : 1.f;
                float innerRadius = lightState.hotsize;
                float outerRadius = lightState.fallsize;

                if( outerRadius < innerRadius )
                    outerRadius = innerRadius;

                boost::shared_ptr<frantic::rendering::lights::lightinterface> pLight(
                    new frantic::rendering::lights::directlight(
                        name, lightTransform, color, decayExponent, shadowsEnabled, shadowDensity, shadowMapSize,
                        useNearAtten, useFarAtten, nearAttenuationStart, nearAttenuationEnd, farAttenuationStart,
                        farAttenuationEnd, shape, aspect, innerRadius, outerRadius ) );
                if( saveAtten ) {
                    frantic::graphics2d::size2 mapDim( shadowMapSize, shadowMapSize );
                    boost::shared_ptr<frantic::rendering::atten_saver> attenSaver(
                        new frantic::rendering::singleface_atten_exr_saver(
                            attenPath, mapDim, numAttenSamples, attenSampleSpacing, attenSampleExponential ) );
                    pLight->set_attenuation_saver( attenSaver );
                }
                // pLight->set_attenuation_loader( attenLoader ); //TODO: someday add importing pre-rendered deep
                // shadows into MX like this (like SR)
                outLights.push_back( pLight );
                break;
            }
            default:
                FF_LOG( error ) << _T("MaxKrakatoa::SetupLightsRecursive() Unexpected light type: ") << lightState.type
                                << _T(" for light \"") << name << _T("\"") << std::endl;
                break;
            }
        }
    }

    for( int i = 0, iEnd = pNode->NumberOfChildren(); i < iEnd; ++i )
        SetupLightsRecursive( outLights, pNode->GetChildNode( i ), doneNodes, t, progress, motionInterval, motionBias,
                              saveAtten );
}
#pragma warning( pop )

void MaxKrakatoa::SetupLights( std::vector<boost::shared_ptr<frantic::rendering::lights::lightinterface>>& outLights,
                               TimeValue t, frantic::logging::progress_logger& progress, float motionInterval,
                               float motionBias ) {
    progress.set_title( _T("Updating Lights") );

    bool saveAtten = m_properties.get_bool( _T("EnableAttenuationMapSaving") );

    std::set<INode*> doneNodes;
    SetupLightsRecursive( outLights, m_scene, doneNodes, t, progress, motionInterval, motionBias, saveAtten );
}

krakatoa::renderer_ptr MaxKrakatoa::SetupRenderer( MaxKrakatoaSceneContextPtr sceneContext ) {
    krakatoa::renderer_ptr krakRenderer;

    TimeValue t = SecToTicks( sceneContext->get_time() );

    color6f backgroundColor;
    bool useEnvironBackground = m_properties.get_bool( _T("UseEnvironmentColor") );

    if( useEnvironBackground ) {
        Interval gbg;
        Point3 envColor = GetCOREInterface()->GetBackGround( t, gbg );
        backgroundColor = color6f( color3f( envColor.x, envColor.y, envColor.z ), alpha3f( 0.f ) );
    } else
        backgroundColor = color6f::parse_maxscript( m_properties.get( _T("BackgroundColor") ) );

    color3f watermarkColor =
        color3f( backgroundColor.c.r + 0.5f, backgroundColor.c.g + 0.5f, backgroundColor.c.b + 0.5f );
    while( watermarkColor.r > 1.f )
        watermarkColor.r -= 1.f;
    while( watermarkColor.g > 1.f )
        watermarkColor.g -= 1.f;
    while( watermarkColor.b > 1.f )
        watermarkColor.b -= 1.f;

    bool watermarkCrackUsed = false;
    boost::function<void( framebuffer<color6f>& )> watermarkFunc = &krakatoa::null_watermark;

    float renderDensity = m_properties.get_float( _T("Density:DensityPerParticle") );
    renderDensity *= powf( 10, (float)m_properties.get_int( _T("Density:DensityExponent") ) );

    float lightDensity;
    if( m_properties.get_bool( _T("Density:LinkLightingAndRenderingDensity") ) ) {
        lightDensity = renderDensity;
    } else {
        lightDensity = m_properties.get_float( _T("Lighting:Density:DensityPerParticle") );
        lightDensity *= powf( 10, (float)m_properties.get_int( _T("Lighting:Density:DensityExponent") ) );
    }

    float emissionStrength;
    if( !m_properties.get_bool( _T("Emission:UseStrength") ) ) {
        emissionStrength = renderDensity;
    } else {
        emissionStrength = m_properties.get_float( _T("Emission:Strength") );
        emissionStrength *= powf( 10.f, (float)m_properties.get_int( _T("Emission:StrengthExponent") ) );
        if( emissionStrength < 0 )
            emissionStrength = 0;
    }

    if( m_properties.get( _T("RenderingMethod") ) == _T("Voxel Rendering") ) {
        krakatoa::voxel_renderer::voxel_renderer_ptr renderer(
            krakatoa::voxel_renderer::voxel_renderer::create_instance() );

        boost::shared_ptr<krakatoa::voxel_renderer::default_filter3f> particleFilter(
            new krakatoa::voxel_renderer::default_filter3f( (float)m_properties.get_int( _T("VoxelFilterRadius") ) ) );
        renderer->set_particle_filter( particleFilter );

        float voxelSize = m_properties.get_float( _T("VoxelSize") );
        renderer->set_voxel_size( voxelSize );

        float spacingFactor = ( voxelSize * voxelSize * voxelSize );
        renderDensity /= spacingFactor;
        lightDensity /= spacingFactor;
        emissionStrength /= spacingFactor;

        krakRenderer = renderer;
    } else if( m_properties.get( _T("RenderingMethod") ) == _T("Particle Rendering") ) {
        krakatoa::splat_renderer::splat_renderer_ptr renderer;

        if( !sceneContext->is_environment_camera() ) {
            renderer = krakatoa::splat_renderer::splat_renderer::create_instance();
        } else {
            renderer = krakatoa::splat_renderer::create_cube_splat_renderer();
        }

        renderer->set_splat_filter(
            krakatoa::splat_renderer::filter2f::create_instance( m_properties.get( _T("DrawPointFilter") ) ) );

        if( !m_properties.get_bool( _T("IgnoreSceneLights") ) && !m_properties.get_bool( _T("AdditiveMode") ) ) {
            krakatoa::splat_renderer::splat_lighting_ptr lightEngine =
                krakatoa::splat_renderer::splat_lighting::create_instance();

            lightEngine->set_splat_filter( krakatoa::splat_renderer::filter2f::create_instance(
                m_properties.get( _T("AttenuationLookupFilter") ) ) );

            lightEngine->disable_threading( !m_properties.get_bool( _T("Performance:MT:Lighting") ) );

            renderer->set_lighting_engine( lightEngine );
        }

        renderer->apply_area_differential( try_get_bool( m_properties, _T("ApplyAreaDifferential"), true ),
                                           try_get_float( m_properties, _T("AreaDifferentialMax"), FLT_MAX ) );

        krakRenderer = renderer;
    } else if( m_properties.get( _T("RenderingMethod") ) == _T("Raytracer") ) {
        krakatoa::raytrace_renderer::raytrace_renderer_ptr raytracer =
            krakatoa::raytrace_renderer::raytrace_renderer::create_instance();
        krakRenderer = raytracer;
    } else {
        throw std::runtime_error( "Unknown renderer type: \"" +
                                  frantic::strings::to_string( m_properties.get( _T("RenderingMethod") ) ) + "\"" );
    }

    int mblurSamples = 0;
    bool mblurJittered = false;
    float mblurBias = 0;
    float mblurDuration = 0;
    bool enableAdaptiveMBlur = false;
    int adaptiveMBlurSegmentLowerBound = 2;
    int adaptiveMBlurSegmentUpperBound = 1024;
    float adaptiveMBlurSmoothness = 1.0f;
    float adaptiveMBlurExponent = 1.0f;
    if( m_properties.get_bool( _T("EnableMotionBlur") ) ) {
        mblurSamples = m_properties.get_int( _T("MotionBlurSegments") );
        mblurBias = m_properties.get_float( _T("ShutterBias") );
        mblurDuration = m_properties.get_float( _T("ShutterAngleInDegrees") ) / ( 360.f * (float)GetFrameRate() );
        mblurJittered = m_properties.get_bool( _T("JitteredMotionBlur") );

        enableAdaptiveMBlur = m_properties.get_bool( _T( "EnableAdaptiveMotionBlur" ) );
        if( enableAdaptiveMBlur ) {
            adaptiveMBlurSegmentLowerBound =
                std::max( 1, m_properties.get_int( _T( "AdaptiveMotionBlurSegmentLowerBound" ) ) );
            adaptiveMBlurSegmentUpperBound =
                std::max( 1, m_properties.get_int( _T( "AdaptiveMotionBlurSegmentUpperBound" ) ) );
            adaptiveMBlurSmoothness = m_properties.get_float( _T( "AdaptiveMotionBlurSmoothness" ) );
            adaptiveMBlurExponent = m_properties.get_float( _T( "AdaptiveMotionBlurExponent" ) );
        }
    }

    bool dofAllowed = m_properties.get_bool( _T("EnableDepthOfField") );
    float dofSampleRate = m_properties.get_float( _T("DepthOfFieldSampleRate") );

    boost::shared_ptr<frantic::max3d::shaders::max_environment_map_provider> environment;

    Texmap* envMap = GetCOREInterface()->GetEnvironmentMap();
    if( GetCOREInterface()->GetUseEnvironmentMap() && envMap ) {
        environment.reset( new frantic::max3d::shaders::max_environment_map_provider( envMap, t ) );
        environment->set_context( sceneContext->get_render_global_context() );
    }

    float reflectionStrength = 0.f;
    if( m_properties.get_bool( _T("UseEnvironmentReflections") ) )
        reflectionStrength = m_properties.exists( _T("EnvironmentReflectionStrength") )
                                 ? m_properties.get_float( _T("EnvironmentReflectionStrength") )
                                 : 1.f;

    krakatoa::atmosphere_interface_ptr atmosphere;
    if( m_properties.get_bool( _T("PME:UseExtinction") ) ) {
        color3f apme = color3f::parse( m_properties.get( _T("AmbientParticipatingMediumExtinction") ) );

        boost::shared_ptr<krakatoa::atmosphere_impl> atmosImpl( new krakatoa::atmosphere_impl );
        atmosImpl->set_extinction( apme );
        atmosImpl->set_volume( m_apmVolumeCache );

        atmosphere = atmosImpl;
    }

    krakatoa::renderer::mode_type::enum_t renderMode = krakatoa::renderer::mode_type::normal;
    if( m_properties.get_bool( _T("AdditiveMode") ) )
        renderMode = krakatoa::renderer::mode_type::additive;

    int matteSupersampling = m_properties.get_int( _T("Matte:RayDivisions") );

    boost::shared_ptr<MaxKrakatoaMatteInterface> matteInterface;

    if( m_properties.get_bool( _T("Matte:UseMatteObjects") ) ) {

        int motionBlurSegments = m_properties.get_int( _T("MotionBlurSegments") );
        int matteMotionBlurSegments = m_properties.get_int( _T("MatteMotionBlurSegments") );
        bool deformingBlur = m_properties.get_bool( _T("DeformationMotionBlur") );

        if( !m_properties.get_bool( _T("EnableMotionBlur") ) ) {
            // Delay evaluation of geometry and transforms until the renderer actually asks for them (it will only do it
            // once since motion blur is disabled).
            matteMotionBlurSegments = 0;
        } else if( deformingBlur ) {
            // We are sampling the geometry, and if the number of samples/segments has not been explicitly set then we
            // should indicate that it should be sampled on every time-change. This is indicated by passing 0 segments.
            if( !m_properties.get_bool( _T("UseMatteMotionBlurSegments") ) )
                matteMotionBlurSegments = 0;
        } else {
            // We are not sampling the geometry, only the transform matrix. If we only need a single sample (due to a
            // single motion segment), then we should take a single TM sample at the appropriate time. If we are doing
            // multiple samples, we need at least 1 segment (1 sample at each endpoint) for interpolation purposes.
            if( !m_properties.get_bool( _T("UseMatteMotionBlurSegments") ) ) {
                if( motionBlurSegments > 1 )
                    matteMotionBlurSegments = 1;
                else
                    matteMotionBlurSegments = 0;
            }
        }

        TimeValue tStart = t - SecToTicks( 0.5f * ( 1.f - mblurBias ) * mblurDuration );
        TimeValue tEnd = t + SecToTicks( 0.5f * ( 1.f + mblurBias ) * mblurDuration );

        // add our nodes to the matte object collection in the sceneContext
        for( std::vector<INode*>::iterator it = m_geometryNodes.begin(), itEnd = m_geometryNodes.end(); it != itEnd;
             ++it ) {
            INode* pNode = *it;
            ObjectState os = pNode->EvalWorldState( tStart );
            if( os.obj &&
                ( os.obj->SuperClassID() == GEOMOBJECT_CLASS_ID || os.obj->SuperClassID() == SHAPE_CLASS_ID ) ) {
                boost::shared_ptr<MaxMattePrimitive> prim(
                    new MaxMattePrimitive( pNode, Interval( tStart, tEnd ), deformingBlur, matteMotionBlurSegments ) );
                prim->set_render_global_context( sceneContext->get_render_global_context() );
                sceneContext->add_matte_object( prim );
            }
        }

        // create a new matte interface. this will be given to the renderer.
        // the matte interface will get its mesh objects though the sceneContext.
        matteInterface.reset( new MaxKrakatoaMatteInterface( sceneContext ) );

        // disable threading? this was removed prior to refactoring, so i've commented it out.
        // matteInterface->disable_threading( !m_properties.get_bool( "Performance:MT:Drawing" ) );

        // handle intial user-defined depth file
        boost::shared_ptr<frantic::rendering::depthbuffer_singleface> pInitialDepthImage;
        if( m_properties.get_bool( _T("Matte:UseDepthMapFiles") ) ) {
            // Round to the nearest frame
            int frameNumber = static_cast<int>( t / (float)GetTicksPerFrame() + 0.5f );
            frantic::tstring targetFile =
                frantic::files::replace_sequence_number( m_properties.get( _T("Matte:DepthMapFiles") ), frameNumber );
            frantic::tstring mapType = m_properties.get( _T("Matte:DepthMapMode") );
            float n = m_properties.get_float( _T("Matte:DepthMapNear") );
            float f = m_properties.get_float( _T("Matte:DepthMapFar") );

            pInitialDepthImage.reset( new frantic::rendering::depthbuffer_singleface( targetFile ) );

            switch( matte_depth_map_method::from_string( mapType ) ) {
            case matte_depth_map_method::normalized_camera_space:
                pInitialDepthImage->denormalize_values( n, f, false );
                break;
            case matte_depth_map_method::normalized_camera_space_inverted:
                pInitialDepthImage->denormalize_values( n, f, true );
                break;
            case matte_depth_map_method::camera_space:
            default:
                break;
            }
        }
        matteInterface->set_initial_depthmap( pInitialDepthImage );
    }

    std::vector<boost::shared_ptr<frantic::rendering::lights::lightinterface>> renderLights;
    if( !m_properties.get_bool( _T("IgnoreSceneLights") ) && !m_properties.get_bool( _T("AdditiveMode") ) ) {
        float mblurDurationFrames = mblurDuration * (float)GetFrameRate();

        max3d::logging::maxrender_progress_logger lightProgress( m_progressCallback, _T("Updating Lights") );
        SetupLights( renderLights, t, lightProgress, mblurDurationFrames, mblurBias );
    }

    for( size_t i = 0, iEnd = renderLights.size(); i < iEnd; ++i ) {
        krakatoa::light_object_ptr lightObj = krakatoa::light_object::create( renderLights[i] );
        lightObj->set_atmosphere( atmosphere );

        krakatoa::shadow_map_generator_ptr shadowMapGen;
        if( matteInterface )
            shadowMapGen.reset( new krakatoa::shadow_map_generator( matteInterface ) );
        lightObj->set_shadow_map_generator( shadowMapGen );

        sceneContext->add_light_object( lightObj );
    }

    // if a crack was used, set all the densities to zero
    if( watermarkCrackUsed ) {
        renderDensity = 0.0f;
        lightDensity = 0.0f;
        emissionStrength = 0.0f;
    }

    krakRenderer->set_use_emission( m_properties.get_bool( _T( "UseEmissionColor" ) ) );
    krakRenderer->set_use_absorption( m_properties.get_bool( _T( "UseFilterColor" ) ) );

    std::vector<Modifier*> modStack;
    frantic::max3d::get_modifier_stack( modStack, m_viewNode );

    for( std::vector<Modifier*>::reverse_iterator it = modStack.rbegin(), itEnd = modStack.rend(); it != itEnd; ++it ) {
        if( ( *it )->IsEnabled() && ( *it )->ClassID() == Class_ID( 0x134f9c63, 0x366ca300 ) ) {
            if( get_parameter<bool>( *it, t, _T( "applyAnamorphicSqueeze" ) ) ) {
                const float anamorphicSqueeze = get_parameter<float>( *it, t, _T( "anamorphicSqueeze" ) );
                krakRenderer->set_anamorphic_squeeze( anamorphicSqueeze );
            }

            const bool doMask = get_parameter<bool>( *it, t, _T( "applyBokehFilter" ) );
            const bool doBlend = get_parameter<bool>( *it, t, _T( "applyBlendRGB" ) );

            if( doMask || doBlend ) {

                Texmap* maxTexture =
                    try_get_parameter<Texmap*>( *it, t, _T( "BokehFilter" ), static_cast<Texmap*>( NULL ) );
                const float blendAmount = doBlend ? get_parameter<float>( *it, t, _T( "BlendRGB" ) ) / 100.0f : 0.0f;
                if( blendAmount > 0.0f ) {
                    m_bokehBlendInfluence = blendAmount;
                }

                const int blendMipmapResCoefficient =
                    try_get_parameter<int>( *it, t, _T( "BokehMipmapResCoefficient" ), 1 );
                krakRenderer->set_mipmap_resolution_coefficient( blendMipmapResCoefficient );

                if( maxTexture ) {
                    const static WORD mapSize = 256;
                    const static frantic::graphics2d::size2 mapDimensions( static_cast<int>( mapSize ),
                                                                           static_cast<int>( mapSize ) );
                    const static frantic::graphics::color3f black( 0.0f, 0.0f, 0.0f );

                    BitmapInfo bi;
                    bi.SetType( BMM_TRUE_64 );
                    bi.SetWidth( mapSize );
                    bi.SetHeight( mapSize );
                    bi.SetFlags( MAP_HAS_ALPHA );
                    bi.SetCustomFlag( 0 );

                    Bitmap* theBitmap = TheManager->Create( &bi );
                    if( theBitmap ) {
                        maxTexture->RenderBitmap( t, theBitmap );

                        frantic::graphics2d::image_channel<frantic::graphics::color3f> bokehBlendMap;
                        frantic::graphics2d::image_channel<float> bokehMask;

                        if( doMask ) {
                            bokehMask.set_size( mapDimensions );
                        }

                        if( doBlend ) {
                            bokehBlendMap.set_size( mapDimensions );
                        }

                        // Alpha detection
                        bool hasAlpha = false;
                        for( int i = 0; i < mapSize && !hasAlpha; ++i ) {
                            boost::scoped_array<BMM_Color_fl> scanline( new BMM_Color_fl[mapSize] );
                            for( int j = 0; j < mapSize && !hasAlpha; ++j ) {
                                if( scanline[j].a != 1.0f ) {
                                    hasAlpha = true;
                                }
                            }
                        }

                        for( int i = 0; i < mapSize; ++i ) {
                            boost::scoped_array<BMM_Color_fl> scanline( new BMM_Color_fl[mapSize] );
                            int numPixels = theBitmap->GetPixels( 0, ( mapSize - 1 ) - i, mapSize, scanline.get() );
                            for( int j = 0; j < mapSize; ++j ) {
                                if( j >= numPixels ) {
                                    if( doBlend ) {
                                        bokehBlendMap.set_pixel(
                                            j, i,
                                            frantic::graphics::color3f( scanline[j].r, scanline[j].g, scanline[j].b ) );
                                    }

                                    if( doMask ) {
                                        if( hasAlpha ) {
                                            bokehMask.set_pixel( j, i, scanline[j].a );
                                        } else {
                                            bokehMask.set_pixel(
                                                j, i,
                                                std::max( std::max( scanline[j].r, scanline[j].g ), scanline[j].b ) );
                                        }
                                    }
                                } else {
                                    if( doBlend ) {
                                        bokehBlendMap.set_pixel( j, i, black );
                                    }

                                    if( doMask ) {
                                        bokehMask.set_pixel( j, i, 0.0f );
                                    }
                                }
                            }
                        }

                        if( doMask ) {
                            krakRenderer->set_bokeh_mask( bokehMask );
                        }

                        if( doBlend ) {
                            krakRenderer->set_bokeh_blend_map( bokehBlendMap );
                            krakRenderer->set_bokeh_blend_amount( blendAmount );
                        }

                        theBitmap->DeleteThis();
                    }
                }
            }
        }
    }

    krakRenderer->set_atmosphere( atmosphere );
    krakRenderer->set_environment( environment, reflectionStrength );
    // krakRenderer->set_deep_matte_map( myDeepMatteMap ); //enable sampling exr deep matte files by using this.
    krakRenderer->set_matte_sampler( matteInterface, matteSupersampling );
    krakRenderer->set_particles( &m_particleCache );
    krakRenderer->set_scene_context( sceneContext );
    krakRenderer->set_watermark( watermarkFunc );

    krakRenderer->set_background_color( backgroundColor, useEnvironBackground );
    krakRenderer->set_density_scale( renderDensity, lightDensity );
    krakRenderer->set_depth_of_field_enabled( dofAllowed, dofSampleRate );
    krakRenderer->set_emission_scale( emissionStrength );
    krakRenderer->set_motion_blur_interval( mblurDuration, mblurBias );
    krakRenderer->set_motion_blur_samples( mblurSamples );
    krakRenderer->set_motion_blur_jittered( mblurJittered );
    krakRenderer->set_enable_adaptive_motion_blur( enableAdaptiveMBlur );
    krakRenderer->set_adaptive_motion_blur_min_samples( adaptiveMBlurSegmentLowerBound );
    krakRenderer->set_adaptive_motion_blur_max_samples( adaptiveMBlurSegmentUpperBound );
    krakRenderer->set_adaptive_motion_blur_smoothness( adaptiveMBlurSmoothness );
    krakRenderer->set_adaptive_motion_blur_exponent( adaptiveMBlurExponent );
    krakRenderer->disable_threading( !m_properties.get_bool( _T("Performance:MT:Drawing") ) );
    krakRenderer->disable_threading_for_sort( !m_properties.get_bool( _T("Performance:MT:Sorting") ) );
    krakRenderer->set_render_mode( renderMode );

    return krakRenderer;
}

boost::shared_ptr<krakatoa::krakatoa_shader> MaxKrakatoa::GetShader() const {
    // call krakatoa::create_shader function with fully populated parameter object.
    krakatoa::shader_params shaderParams;
    shaderParams.phaseFunction = m_properties.get( _T("PhaseFunction") );
    shaderParams.allocatePhaseEccentricty = m_properties.get_bool( _T("Channel:Allocate:PhaseEccentricity") );
    shaderParams.phaseEccentricity = m_properties.get_float( _T("PhaseEccentricity") );
    shaderParams.allocateSpecularLevel = m_properties.get_bool( _T("Channel:Allocate:SpecularLevel") );
    shaderParams.specularLevel = m_properties.get_float( _T("Lighting:Specular:Level") );
    shaderParams.allocateSpecularPower = m_properties.get_bool( _T("Channel:Allocate:SpecularPower") );
    shaderParams.specularPower = m_properties.get_float( _T("Lighting:Specular:SpecularPower") );

    shaderParams.kingKongSpecularGlossinessVarying =
        try_get_bool( m_properties, _T("Shader:Marschner Hair:SpecularGlossiness:Varying"),
                      try_get_bool( m_properties, _T("Shader:King Kong Hair:SpecularGlossiness:Varying"), false ) );
    shaderParams.kingKongSpecularGlossiness =
        try_get_float( m_properties, _T("Shader:Marschner Hair:SpecularGlossiness"),
                       try_get_float( m_properties, _T("Shader:King Kong Hair:SpecularGlossiness"), 0.f ) );

    shaderParams.kingKongSpecularLevelVarying =
        try_get_bool( m_properties, _T("Shader:Marschner Hair:SpecularLevel:Varying"),
                      try_get_bool( m_properties, _T("Shader:King Kong Hair:SpecularLevel:Varying"), false ) );
    shaderParams.kingKongSpecularLevel =
        try_get_float( m_properties, _T("Shader:Marschner Hair:SpecularLevel"),
                       try_get_float( m_properties, _T("Shader:King Kong Hair:SpecularLevel"), 0.f ) );

    shaderParams.kingKongSpecularShiftVarying =
        try_get_bool( m_properties, _T("Shader:Marschner Hair:SpecularShift:Varying"),
                      try_get_bool( m_properties, _T("Shader:King Kong Hair:SpecularShift:Varying"), false ) );
    shaderParams.kingKongSpecularShift =
        try_get_float( m_properties, _T("Shader:Marschner Hair:SpecularShift"),
                       try_get_float( m_properties, _T("Shader:King Kong Hair:SpecularShift"), 0.f ) );

    shaderParams.kingKongSpecular2GlossinessVarying =
        try_get_bool( m_properties, _T("Shader:Marschner Hair:Specular2Glossiness:Varying"),
                      try_get_bool( m_properties, _T("Shader:King Kong Hair:Specular2Glossiness:Varying"), false ) );
    shaderParams.kingKongSpecular2Glossiness =
        try_get_float( m_properties, _T("Shader:Marschner Hair:Specular2Glossiness"),
                       try_get_float( m_properties, _T("Shader:King Kong Hair:Specular2Glossiness"), 0.f ) );

    shaderParams.kingKongSpecular2LevelVarying =
        try_get_bool( m_properties, _T("Shader:Marschner Hair:Specular2Level:Varying"),
                      try_get_bool( m_properties, _T("Shader:King Kong Hair:Specular2Level:Varying"), false ) );
    shaderParams.kingKongSpecular2Level =
        try_get_float( m_properties, _T("Shader:Marschner Hair:Specular2Level"),
                       try_get_float( m_properties, _T("Shader:King Kong Hair:Specular2Level"), 0.f ) );

    shaderParams.kingKongSpecular2ShiftVarying =
        try_get_bool( m_properties, _T("Shader:Marschner Hair:Specular2Shift:Varying"),
                      try_get_bool( m_properties, _T("Shader:King Kong Hair:Specular2Shift:Varying"), false ) );
    shaderParams.kingKongSpecular2Shift =
        try_get_float( m_properties, _T("Shader:Marschner Hair:Specular2Shift"),
                       try_get_float( m_properties, _T("Shader:King Kong Hair:Specular2Shift"), 0.f ) );

    shaderParams.kingKongGlintLevelVarying =
        try_get_bool( m_properties, _T("Shader:Marschner Hair:GlintLevel:Varying"),
                      try_get_bool( m_properties, _T("Shader:King Kong Hair:GlintLevel:Varying"), false ) );
    shaderParams.kingKongGlintLevel =
        try_get_float( m_properties, _T("Shader:Marschner Hair:GlintLevel"),
                       try_get_float( m_properties, _T("Shader:King Kong Hair:GlintLevel"), 0.f ) );

    shaderParams.kingKongGlintSizeVarying =
        try_get_bool( m_properties, _T("Shader:Marschner Hair:GlintSize:Varying"),
                      try_get_bool( m_properties, _T("Shader:King Kong Hair:GlintSize:Varying"), false ) );
    shaderParams.kingKongGlintSize =
        try_get_float( m_properties, _T("Shader:Marschner Hair:GlintSize"),
                       try_get_float( m_properties, _T("Shader:King Kong Hair:GlintSize"), 0.f ) );

    shaderParams.kingKongGlintGlossinessVarying =
        try_get_bool( m_properties, _T("Shader:Marschner Hair:GlintGlossiness:Varying"),
                      try_get_bool( m_properties, _T("Shader:King Kong Hair:GlintGlossiness:Varying"), false ) );
    shaderParams.kingKongGlintGlossiness =
        try_get_float( m_properties, _T("Shader:Marschner Hair:GlintGlossiness"),
                       try_get_float( m_properties, _T("Shader:King Kong Hair:GlintGlossiness"), 0.f ) );

    shaderParams.kingKongDiffuseLevelVarying =
        try_get_bool( m_properties, _T("Shader:Marschner Hair:DiffuseLevel:Varying"),
                      try_get_bool( m_properties, _T("Shader:King Kong Hair:DiffuseLevel:Varying"), false ) );
    shaderParams.kingKongDiffuseLevel =
        try_get_float( m_properties, _T("Shader:Marschner Hair:DiffuseLevel"),
                       try_get_float( m_properties, _T("Shader:King Kong Hair:DiffuseLevel"), 1.f ) );

    return krakatoa::create_shader( shaderParams );
}

void MaxKrakatoa::CacheParticles( const frantic::channels::channel_map& desiredChannels ) {
    // If the cache is enabled, and currently valid, check to ensure all the desired channels are cached.
    if( m_properties.get_bool( _T("EnableParticleCache") ) ) {
        if( m_cacheValid[k_particleFlag] ) {
            const frantic::channels::channel_map& cachedMap = m_particleCache.get_channel_map();
            for( std::size_t i = 0; i < desiredChannels.channel_count() && m_cacheValid[k_particleFlag]; ++i ) {
                if( !cachedMap.has_channel( desiredChannels[i].name() ) )
                    m_cacheValid[k_particleFlag] = false;
            }

            if( m_cacheValid[k_particleFlag] )
                FF_LOG( debug ) << _T("Using cached particle data") << std::endl;
        }
    } else
        m_cacheValid[k_particleFlag] = false;

    // Retrieve the scene particles if the cache needs to be updated.
    if( !m_cacheValid[k_particleFlag] ) {
        m_particleCache.reset( desiredChannels );
        RetrieveParticles( m_particleCache );
        m_cacheValid[k_lightingFlag] = false;
        m_cacheValid[k_particleFlag] = true;
    }
}

/*
void MaxKrakatoa::CacheMatteGeometry(frantic::logging::progress_logger&, TimeValue t){
        frantic::diagnostics::profiling_section psCacheMatteGeometry( _T("Collecting Matte Objects") );
        psCacheMatteGeometry.enter();

        if( m_geometryNodes.size() > 0 ){
                int motionBlurSegments = m_properties.get_int("MotionBlurSegments");
                int matteMotionBlurSegments = m_properties.get_int("MatteMotionBlurSegments");
                float motionBlurInterval = m_properties.get_float("ShutterAngleInDegrees") / 360.f;
                float shutterBias = m_properties.get_float("ShutterBias");
                bool deformingBlur = m_properties.get_bool("DeformationMotionBlur");
                bool rasterDepthMaps = true;

                if( !m_properties.get_bool("EnableMotionBlur") ){
                        //Delay evaluation of geometry and transforms until the renderer actually asks for them (it will
only do it once since motion blur is disabled). motionBlurSegments = matteMotionBlurSegments = 0; }else if(
deformingBlur ){
                        //We are sampling the geometry, and if the number of samples/segments has not been explicitly
set then we should indicate
                        //that it should be sampled on every time-change. This is indicated by passing 0 segments.
                        if( !m_properties.get_bool("UseMatteMotionBlurSegments") )
                                matteMotionBlurSegments = 0;
                }else{
                        //We are not sampling the geometry, only the transform matrix. If we only need a single sample
(due to a single motion segment), then we should
                        //take a single TM sample at the appropriate time. If we are doing multiple samples, we need at
least 1 segment (1 sample at each endpoint) for
                        //interpolation purposes.
                        if( !m_properties.get_bool("UseMatteMotionBlurSegments")  ){
                                if( motionBlurSegments > 1 )
                                        matteMotionBlurSegments = 1;
                                else
                                        matteMotionBlurSegments = 0;
                        }
                }

                TimeValue tStart = t - TimeValue(0.5f * (1.f - shutterBias) * motionBlurInterval * GetTicksPerFrame());
                TimeValue tEnd = t + TimeValue(0.5f * (1.f + shutterBias) * motionBlurInterval * GetTicksPerFrame());
                m_matteGeometryCache.reset( new MaxKrakatoaMatteGeometryCollection( Interval(tStart, tEnd),
deformingBlur, rasterDepthMaps, matteMotionBlurSegments ) );

                for(std::size_t i = 0; i < m_geometryNodes.size(); ++i)
                        m_matteGeometryCache->add_object( m_geometryNodes[i] );
        }else{
                m_matteGeometryCache.reset();
        }

        psCacheMatteGeometry.exit();

        FF_LOG(stats) << psCacheMatteGeometry << std::endl;
}
*/

void MaxKrakatoa::CacheAPMVolumes( frantic::logging::progress_logger& /*progressLog*/, TimeValue t ) {
    using frantic::max3d::geometry::append_inodes_to_mesh;

    frantic::diagnostics::profiling_section psCacheAPMVolumes( _T("Collecting APM Volumes") );
    psCacheAPMVolumes.enter();

    if( m_participatingMediumNodes.size() > 0 ) {
        frantic::geometry::trimesh3 mesh;

        append_inodes_to_mesh( m_participatingMediumNodes.begin(), m_participatingMediumNodes.end(), t, mesh );

        m_apmVolumeCache.reset( new frantic::geometry::trimesh3_kdtree_volume_collection( mesh ) );
    } else {
        m_apmVolumeCache.reset();
    }

    psCacheAPMVolumes.exit();

    FF_LOG( stats ) << psCacheAPMVolumes << std::endl;
}

void MaxKrakatoa::GetMatteSceneObjects( TimeValue time, std::vector<INode*>& matteObjects, bool bHideFrozen,
                                        std::set<INode*>& doneNodes ) {
    using frantic::max3d::geopipe::get_named_selection_set_union;

    if( m_properties.get_bool( _T("Matte:UseMatteObjects") ) ) {
        std::vector<frantic::tstring> namedSets =
            frantic::max3d::fpwrapper::MaxTypeTraits<std::vector<frantic::tstring>>::FromValue(
                mxs::expression( m_properties.get( _T("Matte:NamedSelectionSets") ) ).evaluate<Value*>() );

        matteObjects.clear();
        get_named_selection_set_union( namedSets, matteObjects );

        // Remove any invalid matte objects (ie. Non-Renderable)
        for( unsigned i = 0; i < matteObjects.size(); /*Nothing*/ ) {
            INode* pNode = matteObjects[i];
            if( !pNode )
                continue;

            ObjectState os = pNode->EvalWorldState( time );

            if( pNode->IsNodeHidden( true ) || !pNode->Renderable() || pNode->GetVisibility( time ) <= 0.f ||
                !os.obj->IsRenderable() || ( bHideFrozen && pNode->IsFrozen() ) ||
                doneNodes.find( pNode ) != doneNodes.end() ) {
                doneNodes.insert( pNode );

                matteObjects[i] = matteObjects.back();
                matteObjects.pop_back();
            } else
                ++i;
        }

        doneNodes.insert( matteObjects.begin(), matteObjects.end() );
    }
}

void MaxKrakatoa::GetPMESceneObjects( TimeValue time, std::vector<INode*>& geomObjects, std::set<INode*>& doneNodes ) {
    using frantic::max3d::geopipe::get_named_selection_set_union;

    color3f apme = color3f::parse( m_properties.get( _T("AmbientParticipatingMediumExtinction") ) );
    // Skip getting these objects if the extinction is 0 or if it's turned off.
    if( apme != color3f( 0 ) && m_properties.get_bool( _T("PME:UseExtinction") ) ) {
        std::vector<frantic::tstring> namedSets = mxs::expression( m_properties.get( _T("PME:NamedSelectionSets") ) )
                                                      .evaluate<std::vector<frantic::tstring>>();

        geomObjects.clear();
        get_named_selection_set_union( namedSets, geomObjects );

        // Remove any invalid PME objects (ie. Non-Renderable)
        for( unsigned i = 0; i < geomObjects.size(); /*Nothing*/ ) {
            ObjectState os = geomObjects[i]->EvalWorldState( time );

            if( geomObjects[i]->IsNodeHidden( true ) || !os.obj->IsRenderable() ||
                doneNodes.find( geomObjects[i] ) != doneNodes.end() ) {
                doneNodes.insert( geomObjects[i] );

                geomObjects[i] = geomObjects.back();
                geomObjects.pop_back();
            } else
                ++i;
        }

        doneNodes.insert( geomObjects.begin(), geomObjects.end() );
    }
}

void MaxKrakatoa::GetParticleSceneObjects( TimeValue time, std::vector<KrakatoaParticleSource>& particleObjects,
                                           INode* pScene, bool bHideFrozen, std::set<INode*>& geomNodes,
                                           std::set<INode*>& doneNodes ) {
    std::vector<boost::shared_ptr<KrakatoaParticleSourceFactory>> factories;

    create_particle_factories( factories, this );

    collect_particle_objects( pScene, bHideFrozen, time, particleObjects, factories, geomNodes, doneNodes );
}

void MaxKrakatoa::GetRenderParticleChannels( channel_map& outPcm ) {
    if( !outPcm.has_channel( _T("Position") ) )
        outPcm.define_channel( _T("Position"), 3, frantic::channels::data_type_float32 );

    if( !outPcm.has_channel( _T("Color") ) )
        outPcm.define_channel( _T("Color"), 3, frantic::channels::data_type_float16 );

    if( !outPcm.has_channel( _T("Density") ) )
        outPcm.define_channel( _T("Density"), 1, frantic::channels::data_type_float16 );

    if( !m_properties.get_bool( _T("IgnoreSceneLights") ) ) {
        if( m_properties.get( _T("RenderingMethod") ) != _T("Voxel Rendering") &&
            !outPcm.has_channel( _T("Lighting") ) )
            outPcm.define_channel( _T("Lighting"), 3, frantic::channels::data_type_float16 );
    }

    if( m_properties.get_bool( _T("EnableMotionBlur") ) ) {
        if( !outPcm.has_channel( _T("Velocity") ) )
            outPcm.define_channel( _T("Velocity"), 3, frantic::channels::data_type_float16 );

        if( m_properties.get_bool( _T("JitteredMotionBlur") ) && !outPcm.has_channel( _T("MBlurTime") ) )
            outPcm.define_channel( _T("MBlurTime"), 1, frantic::channels::data_type_float16 );
    }

    if( m_properties.get_bool( _T("UseFilterColor") ) && !outPcm.has_channel( _T("Absorption") ) )
        outPcm.define_channel( _T("Absorption"), 3, frantic::channels::data_type_float16 );
    if( m_properties.get_bool( _T("UseEmissionColor") ) && !outPcm.has_channel( _T("Emission") ) )
        outPcm.define_channel( _T("Emission"), 3, frantic::channels::data_type_float16 );

    if( m_properties.get_bool( _T("UseEnvironmentReflections") ) && !outPcm.has_channel( _T("Normal") ) )
        outPcm.define_channel( _T("Normal"), 3, frantic::channels::data_type_float16 );

    if( m_properties.get_bool( _T( "Channel:Allocate:ReflectionStrength" ) ) &&
        ( m_properties.get_bool( _T( "UseEnvironmentReflections" ) ) ||
          m_properties.get_bool( _T( "UseEmissionColor" ) ) ) &&
        !outPcm.has_channel( _T( "ReflectionStrength" ) ) ) {
        outPcm.define_channel( _T( "ReflectionStrength" ), 1, frantic::channels::data_type_float16 );
    }

    const bool doDOF = m_properties.get_bool( _T( "EnableDepthOfField" ) );
    bool allocateBlendInfluence = true;
    allocateBlendInfluence = m_properties.get_bool( _T( "Channel:Allocate:BokehBlendInfluence" ) );
    if( doDOF && allocateBlendInfluence && !outPcm.has_channel( _T( "BokehBlendInfluence" ) ) ) {
        outPcm.define_channel( _T( "BokehBlendInfluence" ), 1, frantic::channels::data_type_float16 );
    }
}

void MaxKrakatoa::ApplyChannelDataTypeOverrides( frantic::channels::channel_map& inoutMap ) {
    // Override the default data type for channels in the channel_map.
    for( std::size_t i = 0, iEnd = inoutMap.channel_count(); i < iEnd; ++i ) {
        frantic::tstring propName = _T("Memory:Channel:") + inoutMap[i].name();
        if( m_properties.exists( propName ) )
            inoutMap.set_channel_data_type(
                inoutMap[i].name(), frantic::channels::channel_data_type_from_string( m_properties.get( propName ) ) );
    }

    // For some reason the Eccentricity channel has a different named property so get it specifically.
    frantic::channels::data_type_t eccentricityType =
        frantic::channels::channel_data_type_from_string( m_properties.get( _T("Memory:Channel:PhaseEccentricity") ) );
    if( inoutMap.has_channel( _T("Eccentricity") ) )
        inoutMap.set_channel_data_type( _T("Eccentricity"), eccentricityType );
}

void MaxKrakatoa::GetCachedParticleChannels( channel_map& outPcm ) {
    outPcm = m_particleCache.get_channel_map();
    outPcm.end_channel_definition();
}

void MaxKrakatoa::SaveMatteObjectsToFileSequence( const frantic::tstring& /*filename*/,
                                                  const std::vector<INode*>& /*nodes*/, int /*startFrame*/,
                                                  int /*endFrame*/ ) {
    // using frantic::graphics::motion_blurred_transform;
    //
    // std::vector< std::pair<INode*,frantic::tstring> > validNodes;	//Array of nodes which had valid meshes, and their
    // releative paths for mesh sequences validNodes.reserve(nodes.size());

    ////Generate paths for the output meshes
    // for(std::size_t i = 0; i < nodes.size(); ++i){
    //	if( !nodes[i] || !nodes[i]->Renderable() || !nodes[i]->GetPrimaryVisibility() || nodes[i]->IsNodeHidden(TRUE) )
    //		continue;

    //	frantic::tstring objName = frantic::files::clean_directory_name(nodes[i]->GetName(), _T("_")) + _T("_") +
    //boost::lexical_cast<frantic::tstring>(nodes[i]->GetHandle());
    //
    //	validNodes.push_back( std::make_pair(nodes[i], _T("Geometry/") + objName + _T("/") + objName +
    //_T("_0000.xmesh")) ); 	frantic::files::create_directories_l( frantic::files::replace_filename(filename,
    //_T("Geometry/")+objName) );
    //}
    //
    //// Get the shutter angle and bias.
    // float motionBlurInterval = m_properties.get_float(_T("ShutterAngleInDegrees")) / 360.f;
    // float shutterBias = m_properties.get_float(_T("ShutterBias"));

    ////For each frame, write the valid geometry and xml scene descriptions
    // for(int frame = startFrame; frame <= endFrame; frame++){
    //	TimeValue t = frame * GetTicksPerFrame();
    //
    //	frantic::tstring sceneFile = frantic::files::replace_sequence_number(filename, frame);
    //	std::ofstream fout(sceneFile.c_str(), std::ios::out);

    //	if( !fout )
    //		throw std::runtime_error("MaxKrakatoa::SaveMatteObjectsToFileSequence() - Could not open file \"" +
    //frantic::strings::to_string(sceneFile) + "\" for writing." );

    //	fout << _T("<scene>\n");
    //	for(std::size_t i = 0; i < validNodes.size(); ++i){
    //		if(validNodes[i].first->GetVisibility(t) <= 0 )
    //			continue;

    //		ObjectState os = validNodes[i].first->EvalWorldState(t);
    //		if( !os.obj->CanConvertToType(triObjectClassID) )
    //			continue;

    //		frantic::geometry::trimesh3 tempMesh;
    //		frantic::tstring relativePath = frantic::files::replace_sequence_number(validNodes[i].second, frame);
    //		motion_blurred_transform xform = motion_blurred_transform::from_objtmafterwsm(validNodes[i].first, t,
    //motionBlurInterval, shutterBias);
    //
    //		TriObject* pTriObj = static_cast<TriObject*>(os.obj->ConvertToType(t, triObjectClassID));
    //		frantic::max3d::geometry::mesh_copy(tempMesh, pTriObj->GetMesh());
    //		if(pTriObj != os.obj)
    //			pTriObj->MaybeAutoDelete();

    //		frantic::geometry::write_mesh_file(frantic::files::replace_filename(filename, relativePath), tempMesh);

    //		fout << _T("\t<geometry>\n");
    //		fout << _T("\t\t<filename>") << relativePath << _T("</filename>\n");
    //		xform.write_xml(fout, _T("\t\t"));
    //		fout << _T("\t</geometry>\n");
    //	}
    //	fout << _T("</scene>\n");
    //}
}

bool MaxKrakatoa::is_valid_particle_node( INode* node, TimeValue t ) {
    std::vector<boost::shared_ptr<KrakatoaParticleSourceFactory>> srcFactories;
    std::vector<KrakatoaParticleSource> srcs;

    create_particle_factories( srcFactories, this );

    for( std::vector<boost::shared_ptr<KrakatoaParticleSourceFactory>>::const_iterator it = srcFactories.begin(),
                                                                                       itEnd = srcFactories.end();
         it != itEnd; ++it ) {
        if( ( *it )->Process( node, t, srcs ) )
            return !srcs.empty();
    }

    return false;
}

bool MaxKrakatoa::is_valid_matte_node( INode* node, TimeValue t ) {
    ObjectState os = node->EvalWorldState( t );

    if( os.obj->SuperClassID() != GEOMOBJECT_CLASS_ID && !os.obj->CanConvertToType( triObjectClassID ) )
        return false;

    return !is_valid_particle_node( node, t );
}