// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0
#include "resource.h"
#include "stdafx.h"

#include "FumeFX\MaxKrakatoaFumeFXParticleIStream.h"

#include <frantic/channels/channel_map_adaptor.hpp>
#include <frantic/math/splines/bezier_spline.hpp>
#include <frantic/particles/streams/apply_function_particle_istream.hpp>
#include <frantic/particles/streams/empty_particle_istream.hpp>
#include <frantic/particles/streams/particle_istream.hpp>

#include <frantic/max3d/geopipe/get_inodes.hpp>
#include <frantic/max3d/maxscript/maxscript.hpp>

namespace detail {
struct gradient_sample {
    float position;
    frantic::graphics::color3f color;
    float tension;
    float continuity;
    float bias;
    float easeTo;
    float easeFrom;
};
} // namespace detail

class fume_fx_shader {
    std::vector<detail::gradient_sample> m_colorGradient;
    std::vector<frantic::math::bezier_curve_point<frantic::graphics2d::vector2f>> m_opacityCurve;
    float m_scalar;
    bool m_is_TCB;

  private:
    frantic::graphics::color3f pt_tangent_in( detail::gradient_sample tcbVals, float leftDist, float rightDist,
                                              frantic::graphics::color3f leftVal, frantic::graphics::color3f atVal,
                                              frantic::graphics::color3f rightVal ) const {

        frantic::graphics::color3f left( 0, 0, 0 );
        frantic::graphics::color3f right( 0, 0, 0 );

        if( leftDist > 0.0f ) {
            left = ( atVal - leftVal ) / leftDist * 0.5 * ( 1 - tcbVals.tension ) * ( 1 + tcbVals.bias ) *
                   ( 1 - tcbVals.continuity );
        }

        if( rightDist > 0.0f ) {
            right = ( rightVal - atVal ) / rightDist * 0.5 * ( 1 - tcbVals.tension ) * ( 1 - tcbVals.bias ) *
                    ( 1 + tcbVals.continuity );
        }

        return left + right;
    }

    frantic::graphics::color3f pt_tangent_out( detail::gradient_sample tcbVals, float leftDist, float rightDist,
                                               frantic::graphics::color3f leftVal, frantic::graphics::color3f atVal,
                                               frantic::graphics::color3f rightVal ) const {

        frantic::graphics::color3f left( 0, 0, 0 );
        frantic::graphics::color3f right( 0, 0, 0 );

        if( leftDist > 0.0f ) {
            left = ( atVal - leftVal ) / leftDist * 0.5 * ( 1 - tcbVals.tension ) * ( 1 + tcbVals.bias ) *
                   ( 1 + tcbVals.continuity );
        }

        if( rightDist > 0.0f ) {
            right = ( rightVal - atVal ) / rightDist * 0.5 * ( 1 - tcbVals.tension ) * ( 1 - tcbVals.bias ) *
                    ( 1 - tcbVals.continuity );
        }

        return left + right;
    }

    frantic::graphics::color3f eval_tcb_gradient( float fire ) const {
        frantic::graphics::color3f outColor( 1.f );

        // calculate the index of m_colorGradient for the next control point after our current position
        std::size_t currIndex = 0;
        while( fire > m_colorGradient[currIndex].position && currIndex < m_colorGradient.size() )
            ++currIndex;

        if( currIndex < m_colorGradient.size() ) {
            float leftSizeIN, leftSizeOUT, rightSizeIN, rightSizeOUT;

            // calculate distances between control points for tangent calculations
            if( currIndex > 1 ) {
                leftSizeIN = m_colorGradient[currIndex - 1].position - m_colorGradient[currIndex - 2].position;
            } else {
                leftSizeIN = 0.0f;
            }
            leftSizeOUT = m_colorGradient[currIndex].position - m_colorGradient[currIndex - 1].position;

            rightSizeIN = leftSizeOUT;
            if( currIndex < m_colorGradient.size() - 1 ) {
                rightSizeOUT = m_colorGradient[currIndex + 1].position - m_colorGradient[currIndex].position;
            } else {
                rightSizeOUT = 0;
            }

            // calculate 'imaginary' color values because using the ones at the control points assumes equal spacing of
            // control points which may not be the case
            frantic::graphics::color3f imaginaryLeftColor;
            frantic::graphics::color3f imaginaryRightColor;
            imaginaryLeftColor = m_colorGradient[currIndex - 1].color -
                                 ( m_colorGradient[currIndex].color - m_colorGradient[currIndex - 1].color ) *
                                     ( leftSizeIN / leftSizeOUT );
            imaginaryRightColor = m_colorGradient[currIndex].color +
                                  ( m_colorGradient[currIndex].color - m_colorGradient[currIndex - 1].color ) *
                                      ( rightSizeIN / rightSizeOUT );

            frantic::graphics::color3f startInTangent;
            frantic::graphics::color3f startOutTangent;
            frantic::graphics::color3f startTangent;
            float inMagnitude, outMagnitude;

            // calculate start and end tangents
            startInTangent = pt_tangent_in( m_colorGradient[currIndex - 1], leftSizeIN, leftSizeOUT, imaginaryLeftColor,
                                            m_colorGradient[currIndex - 1].color, m_colorGradient[currIndex].color );
            startOutTangent =
                pt_tangent_out( m_colorGradient[currIndex - 1], leftSizeIN, leftSizeOUT, imaginaryLeftColor,
                                m_colorGradient[currIndex - 1].color, m_colorGradient[currIndex].color );
            inMagnitude = sqrt( startInTangent[0] * startInTangent[0] + startInTangent[1] * startInTangent[1] +
                                startInTangent[2] * startInTangent[2] );
            outMagnitude = sqrt( startOutTangent[0] * startOutTangent[0] + startOutTangent[1] * startOutTangent[1] +
                                 startOutTangent[2] * startOutTangent[2] );
            if( inMagnitude > 0 || outMagnitude > 0 ) {
                startTangent = startOutTangent * 2 * ( inMagnitude / ( inMagnitude + outMagnitude ) );
            }

            frantic::graphics::color3f endInTangent;
            frantic::graphics::color3f endOutTangent;
            frantic::graphics::color3f endTangent;

            endInTangent = pt_tangent_in( m_colorGradient[currIndex], rightSizeIN, rightSizeOUT,
                                          m_colorGradient[currIndex - 1].color, m_colorGradient[currIndex].color,
                                          imaginaryRightColor );
            endOutTangent = pt_tangent_out( m_colorGradient[currIndex], rightSizeIN, rightSizeOUT,
                                            m_colorGradient[currIndex - 1].color, m_colorGradient[currIndex].color,
                                            imaginaryRightColor );
            inMagnitude = sqrt( endInTangent[0] * endInTangent[0] + endInTangent[1] * endInTangent[1] +
                                endInTangent[2] * endInTangent[2] );
            outMagnitude = sqrt( endOutTangent[0] * endOutTangent[0] + endOutTangent[1] * endOutTangent[1] +
                                 endOutTangent[2] * endOutTangent[2] );
            if( inMagnitude > 0 || outMagnitude > 0 ) {
                endTangent = endTangent * 2 * ( outMagnitude / ( inMagnitude + outMagnitude ) );
            }

            float delta = m_colorGradient[currIndex].position - m_colorGradient[currIndex - 1].position;
            float t = ( fire - m_colorGradient[currIndex - 1].position ) / delta;

            // do bilinear interpolation on values of fitted 6th order polynomials with boundary conditions of the
            // easing values and use those values to adjust t with a 6th order polynomial
            float f00[] = { 0.0f, -0.113953f, 4.389870f, -7.183178f, 8.878994f, -7.276164f, 2.304432f };
            float f01[] = { 0.0f, 0.199897f, 11.048450f, -26.397375f, 26.189629f, -12.473798f, 2.433197f };
            float f10[] = { 0.0f, -0.1989384f, 1.8801302f, -6.617484f, 14.148923f, -8.9427606f, 0.7301298f };
            float f11[] = { 0.0f, 2.7608f, -32.708f, 132.54f, -215.39f, 156.19f, -42.397f };
            float f00part;
            float f01part;
            float f10part;
            float f11part;
            float easingFcn[7];
            float eT = m_colorGradient[currIndex].easeTo;
            float eF = m_colorGradient[currIndex - 1].easeFrom;

            for( int i = 0; i < 7; i++ ) {
                f00part = f00[i] * ( 1 - eF ) * ( 1 - eT );
                f01part = f01[i] * ( 1 - eF ) * eT;
                f10part = f10[i] * eF * ( 1 - eT );
                f11part = f11[i] * eF * eT;
                easingFcn[i] = f00part + f01part + f10part + f11part;
            }

            // Use horner's rule to compute result of polynomial.
            float baseT = t;
            t = easingFcn[6] * baseT;
            t = ( t + easingFcn[5] ) * baseT;
            t = ( t + easingFcn[4] ) * baseT;
            t = ( t + easingFcn[3] ) * baseT;
            t = ( t + easingFcn[2] ) * baseT;
            t = ( t + easingFcn[1] ) * baseT;
            t += easingFcn[0];

            // clamp t if necessary
            if( t < 0 )
                t = 0;

            if( t > 1 )
                t = 1;

            float t2 = t * t;
            float t3 = t * t2;

            // evaluated as a tcb spline or Kochanek-Bartels spline
            outColor = m_colorGradient[currIndex - 1].color * ( 2 * t3 - 3 * t2 + 1 ) +
                       m_colorGradient[currIndex].color * ( -2 * t3 + 3 * t2 ) +
                       startTangent * delta * ( t3 - 2 * t2 + t ) + endTangent * delta * ( t3 - t2 );
        }

        return outColor;
    }

  public:
    fume_fx_shader()
        : m_scalar( 1.f ) {}

    virtual ~fume_fx_shader() {}

    void add_color_gradient_knot( float pos, const frantic::graphics::color3f& colorKnot, float tension = 0.0f,
                                  float continuity = 0.0f, float bias = 0.0f, float easeTo = 0.0f,
                                  float easeFrom = 0.0f ) {

        detail::gradient_sample sample = {
            sample.position = pos, sample.color = colorKnot, sample.tension = tension,  sample.continuity = continuity,
            sample.bias = bias,    sample.easeTo = easeTo,   sample.easeFrom = easeFrom };
        m_colorGradient.push_back( sample );
    }

    void add_opacity_curve_knot( frantic::graphics2d::vector2f pos, frantic::graphics2d::vector2f inVec,
                                 frantic::graphics2d::vector2f outVec ) {
        frantic::math::bezier_curve_point<frantic::graphics2d::vector2f> newPoint;
        newPoint.position = pos;
        newPoint.inTan = inVec;
        newPoint.outTan = outVec;

        m_opacityCurve.push_back( newPoint );
    }

    void set_TCB( bool isTCB ) { m_is_TCB = isTCB; }

    void set_scalar( float scalar ) { m_scalar = scalar; }

    frantic::graphics::color3f apply( float fire ) const {
        frantic::graphics::color3f outColor( 1.f );

        if( m_colorGradient.size() > 0 ) {
            if( m_colorGradient.size() == 1 ) {
                outColor = m_colorGradient[0].color;
            } else if( fire <= m_colorGradient.front().position ) {
                outColor = m_colorGradient.front().color;
            } else if( fire >= m_colorGradient.back().position ) {
                outColor = m_colorGradient.back().color;
            } else {
                if( m_is_TCB ) {
                    outColor = this->eval_tcb_gradient( fire );
                } else {
                    std::size_t i = 1;
                    while( fire >= m_colorGradient[i].position )
                        ++i;

                    float t = ( fire - m_colorGradient[i - 1].position ) /
                              ( m_colorGradient[i].position - m_colorGradient[i - 1].position );
                    outColor =
                        m_colorGradient[i - 1].color + t * ( m_colorGradient[i].color - m_colorGradient[i - 1].color );
                }
            }
        }

        float scalar = m_scalar;
        if( m_opacityCurve.size() >= 2 )
            scalar *= frantic::math::bezier_curve_x_to_y( m_opacityCurve, fire );

        outColor *= scalar;

        return outColor;
    }

  public:
    static boost::array<frantic::tstring, 1> input_channels;
};

boost::array<frantic::tstring, 1> fume_fx_shader::input_channels = { _T("Fire") };

boost::shared_ptr<frantic::particles::streams::particle_istream>
apply_fume_fx_emission_shading_istream( boost::shared_ptr<frantic::particles::streams::particle_istream> pin,
                                        INode* pNode, TimeValue t, float scalar ) {
    class fume_fx_emission_shading_error : public std::runtime_error {
      public:
        fume_fx_emission_shading_error( INode* pNode )
            : std::runtime_error( "Error accessing FumeFX shading parameters for node: \"" +
                                  frantic::strings::to_string( pNode->GetName() ) + "\"" ) {}

        virtual ~fume_fx_emission_shading_error() {}
    };

    try {
        frantic::max3d::mxs::frame<1> f;
        frantic::max3d::mxs::local<Value> results( f );

        results =
            frantic::max3d::mxs::expression( _T("FranticParticleRenderMXS.getFumeShaderParameters theFumeObject") )
                .bind( _T("theFumeObject"), pNode )
                .at_time( t )
                .evaluate<Value*>();

        if( !is_array( results.ptr() ) )
            throw fume_fx_emission_shading_error( pNode );

        Array* pShaderDataArray = static_cast<Array*>( results.ptr() );
        if( pShaderDataArray->size != 6 ) {
            if( pShaderDataArray->size == 1 && !pShaderDataArray->data[0]->to_bool() )
                return pin;
            throw fume_fx_emission_shading_error( pNode );
        }

        if( pShaderDataArray->get( 1 + 0 )->to_bool() ) {
            float colorScale = pShaderDataArray->get( 1 + 1 )->to_float();

            if( !is_array( pShaderDataArray->get( 1 + 2 ) ) )
                throw fume_fx_emission_shading_error( pNode );
            Array* colorGradientArray = static_cast<Array*>( pShaderDataArray->get( 1 + 2 ) );

            float opacityScale = pShaderDataArray->get( 1 + 3 )->to_float();
            if( !is_array( pShaderDataArray->get( 1 + 4 ) ) )
                throw fume_fx_emission_shading_error( pNode );
            Array* opacityCurveArray = static_cast<Array*>( pShaderDataArray->get( 1 + 4 ) );

            boost::shared_ptr<fume_fx_shader> pStreamShader( new fume_fx_shader );
            pStreamShader->set_scalar( colorScale * opacityScale * scalar );
            pStreamShader->set_TCB( pShaderDataArray->get( 1 + 5 )->to_bool() != false );

            for( int i = 0; i < colorGradientArray->size; ++i ) {
                Value* pVal = colorGradientArray->get( 1 + i );

                if( !is_array( pVal ) )
                    throw fume_fx_emission_shading_error( pNode );
                Array* pColorKnot = static_cast<Array*>( pVal );
                float pos = pColorKnot->get( 1 + 0 )->to_float();
                Color color = pColorKnot->get( 1 + 1 )->to_acolor();

                if( !is_array( pColorKnot->get( 1 + 2 ) ) )
                    throw fume_fx_emission_shading_error( pNode );

                Array* pTCBValues = static_cast<Array*>( pColorKnot->get( 1 + 2 ) );

                float tension, continuity, bias, easeTo, easeFrom;
                tension = pTCBValues->get( 1 + 0 )->to_float();
                continuity = pTCBValues->get( 1 + 1 )->to_float();
                bias = pTCBValues->get( 1 + 2 )->to_float();
                easeTo = pTCBValues->get( 1 + 3 )->to_float();
                easeFrom = pTCBValues->get( 1 + 4 )->to_float();

                pStreamShader->add_color_gradient_knot( pos, frantic::graphics::color3f( color.r, color.g, color.b ),
                                                        tension, continuity, bias, easeTo, easeFrom );
            }

            for( int i = 0; i < opacityCurveArray->size; ++i ) {
                Value* pVal = opacityCurveArray->get( 1 + i );

                if( !is_array( pVal ) )
                    throw fume_fx_emission_shading_error( pNode );
                Array* pOpacityKnot = static_cast<Array*>( pVal );

                Point2 pos = pOpacityKnot->get( 1 + 0 )->to_point2();
                Point2 inVec = pOpacityKnot->get( 1 + 1 )->to_point2();
                Point2 outVec = pOpacityKnot->get( 1 + 2 )->to_point2();
                pStreamShader->add_opacity_curve_knot( frantic::graphics2d::vector2f( pos.x, pos.y ),
                                                       frantic::graphics2d::vector2f( inVec.x, inVec.y ),
                                                       frantic::graphics2d::vector2f( outVec.x, outVec.y ) );
            }

            pin.reset(
                new frantic::particles::streams::apply_function_particle_istream<frantic::graphics::color3f( float )>(
                    pin, boost::bind( &fume_fx_shader::apply, pStreamShader, _1 ), _T("Emission"),
                    fume_fx_shader::input_channels ) );
        }
    } catch( MAXScriptException& e ) {
        throw std::runtime_error( frantic::strings::to_string( frantic::max3d::mxs::to_string( e ) ) );
    }

    return pin;
}