// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0
#pragma once

#include <frantic/max3d/convert.hpp>
#include <frantic/max3d/particles/streams/max_pflow_particle_istream.hpp>
#include <frantic/max3d/time.hpp>

#include <PFlow Operators/MaxKrakatoaPFParticleChannelFileIDInteger.h>

#include <frantic/channels/channel_map.hpp>

// The particle flow SDK requires that I do this...
#pragma warning( push )
#pragma warning( disable : 4239 )

enum blend_type { BLEND, ADD };

// This class wraps up all the access to the particle flow channels that are needed by a given particle
// configuration described by the particle channel map.
class particle_flow_channel_interface {

    IObject* m_particleContainer;
    frantic::channels::channel_map m_pflowMap;

    struct channel_info {
        int channelNum;
        IParticleChannelMapR* R;
        IParticleChannelMapW* W;
        frantic::channels::channel_cvt_accessor<frantic::graphics::vector3f> acc;
        int blendType;
        float blendAlpha;
        channel_info( int num, IParticleChannelMapR* readMap, IParticleChannelMapW* writeMap,
                      const frantic::channels::channel_cvt_accessor<frantic::graphics::vector3f>& accessor,
                      int inBlendType, float inBlendAlpha ) {
            channelNum = num;
            R = readMap;
            W = writeMap;
            acc = accessor;
            blendType = inBlendType;
            blendAlpha = inBlendAlpha;
        }
    };

    class channels {

      public:
        // container data
        IChannelContainer* channelContainer;
        IParticleChannelAmountR* amountR;
        IParticleChannelAmountW* amountW;

        // typically only used in birthing
        IParticleChannelPTVR* birthR;
        IParticleChannelPTVW* birthW;
        IParticleChannelPTVR* timeR;
        IParticleChannelPTVW* timeW;
        IParticleChannelIDR* idR;
        IParticleChannelIDW* idW;
        IParticleChannelNewR* newR;
        IParticleChannelNewW* newW;

        // non blendable channels
        IParticleChannelIntR* fidR;
        IParticleChannelIntW* fidW;
        IParticleChannelIDR* indexR;
        IParticleChannelIDW* indexW;
        IParticleChannelPTVR* deathR;
        IParticleChannelPTVW* deathW;
        IParticleChannelPTVR* lifeSpanR;
        IParticleChannelPTVW* lifeSpanW;
        IParticleChannelIntR* materialIndexR;
        IParticleChannelIntW* materialIndexW;
        IParticleChannelIntR* mxsIntegerR;
        IParticleChannelIntW* mxsIntegerW;
        IParticleChannelMeshMapR* meshMapR;
        IParticleChannelMeshMapW* meshMapW;

        // blendable channels
        IParticleChannelPoint3R* positionR;
        IParticleChannelPoint3W* positionW;
        int positionBlendType;
        float positionBlendAlpha;

        IParticleChannelPoint3R* velocityR;
        IParticleChannelPoint3W* velocityW;
        int velocityBlendType;
        float velocityBlendAlpha;

        IParticleChannelPoint3R* accelerationR;
        IParticleChannelPoint3W* accelerationW;
        int accelerationBlendType;
        float accelerationBlendAlpha;

        IParticleChannelPoint3R* scaleR;
        IParticleChannelPoint3W* scaleW;
        int scaleBlendType;
        float scaleBlendAlpha;

        IParticleChannelQuatR* orientationR;
        IParticleChannelQuatW* orientationW;
        int orientationBlendType;
        float orientationBlendAlpha;

        IParticleChannelAngAxisR* spinR;
        IParticleChannelAngAxisW* spinW;
        int spinBlendType;
        float spinBlendAlpha;

        IParticleChannelFloatR* mxsFloatR;
        IParticleChannelFloatW* mxsFloatW;
        int mxsFloatBlendType;
        float mxsFloatBlendAlpha;

        IParticleChannelPoint3R* mxsVectorR;
        IParticleChannelPoint3W* mxsVectorW;
        int mxsVectorBlendType;
        float mxsVectorBlendAlpha;

        IParticleChannelMapR* colorR;
        IParticleChannelMapW* colorW;
        int colorBlendType;
        float colorBlendAlpha;

        IParticleChannelMapR* textureCoordR;
        IParticleChannelMapW* textureCoordW;
        int textureCoordBlendType;
        float textureCoordBlendAlpha;

        channels() {
            channelContainer = NULL;
            amountR = NULL;
            amountW = NULL;

            birthR = NULL;
            birthW = NULL;
            timeR = NULL;
            timeW = NULL;
            newR = NULL;
            newW = NULL;
            idR = NULL;
            idW = NULL;

            fidR = NULL;
            fidW = NULL;
            indexR = NULL;
            indexW = NULL;
            deathR = NULL;
            deathW = NULL;
            lifeSpanR = NULL;
            lifeSpanW = NULL;
            materialIndexR = NULL;
            materialIndexW = NULL;
            mxsIntegerR = NULL;
            mxsIntegerW = NULL;
            meshMapR = NULL;
            meshMapW = NULL;

            positionR = NULL;
            positionW = NULL;
            velocityR = NULL;
            velocityW = NULL;
            accelerationR = NULL;
            accelerationW = NULL;
            scaleR = NULL;
            scaleW = NULL;
            orientationR = NULL;
            orientationW = NULL;
            spinR = NULL;
            spinW = NULL;
            mxsFloatR = NULL;
            mxsFloatW = NULL;
            mxsVectorR = NULL;
            mxsVectorW = NULL;
            colorR = NULL;
            colorW = NULL;
            textureCoordR = NULL;
            textureCoordW = NULL;
        }
    };
    channels m_channels;

    class accessors {

      public:
        bool hasPosition;
        bool hasDensity;
        bool hasColor;
        bool hasTextureCoord;
        bool hasVelocity;
        bool hasAcceleration;
        bool hasNormal;
        bool hasOrientation;
        bool hasSpin;
        bool hasScale;
        bool hasID;
        bool hasMaterialIndex;
        bool hasAge;
        bool hasLifeSpan;
        bool hasMXSInteger;
        bool hasMXSFloat;
        bool hasMXSVector;

        frantic::channels::channel_cvt_accessor<frantic::graphics::vector3f> position;
        frantic::channels::channel_cvt_accessor<frantic::graphics::vector3f> color;
        frantic::channels::channel_cvt_accessor<frantic::graphics::vector3f> textureCoord;
        frantic::channels::channel_cvt_accessor<frantic::graphics::vector3f> velocity;
        frantic::channels::channel_cvt_accessor<frantic::graphics::vector3f> acceleration;
        frantic::channels::channel_cvt_accessor<frantic::graphics::vector3f> normal;
        frantic::channels::channel_cvt_accessor<frantic::graphics::vector4f> orientation;
        frantic::channels::channel_cvt_accessor<frantic::graphics::vector4f> spin;
        frantic::channels::channel_cvt_accessor<frantic::graphics::vector3f> scale;
        frantic::channels::channel_cvt_accessor<float> density;
        frantic::channels::channel_cvt_accessor<int> id;
        frantic::channels::channel_cvt_accessor<float> age;
        frantic::channels::channel_cvt_accessor<float> lifeSpan;
        frantic::channels::channel_cvt_accessor<int> materialIndex;
        frantic::channels::channel_cvt_accessor<int> mxsInteger;
        frantic::channels::channel_cvt_accessor<float> mxsFloat;
        frantic::channels::channel_cvt_accessor<frantic::graphics::vector3f> mxsVector;

        std::vector<channel_info> mappings; // Stores accessors for map channels 2 through 99

        accessors() {
            hasPosition = false;
            hasDensity = false;
            hasColor = false;
            hasTextureCoord = false;
            hasVelocity = false;
            hasAcceleration = false;
            hasNormal = false;
            hasOrientation = false;
            hasSpin = false;
            hasScale = false;
            hasID = false;
            hasMaterialIndex = false;
            hasAge = false;
            hasLifeSpan = false;
            hasMXSInteger = false;
            hasMXSFloat = false;
            hasMXSVector = false;
        }
    };
    accessors m_accessors;

  public:
    particle_flow_channel_interface( IObject* pCont ) {
        if( pCont == NULL )
            throw std::runtime_error(
                "particle_flow_channel_interface::constructor: Particle container has NULL reference" );
        m_particleContainer = pCont;
    }

    int get_particle_file_id( int index ) const {
        if( m_channels.fidR )
            return m_channels.fidR->GetValue( index );
        else
            throw std::runtime_error(
                "particle_flow_channel_interface::get_particle_file_id - File ID channel interface not initialized." );
    }

    int get_particle_file_or_real_id( int index ) const {
        if( m_channels.fidR )
            return m_channels.fidR->GetValue( index );
        else if( m_channels.idR )
            return m_channels.idR->GetID( index ).born;
        else
            throw std::runtime_error( "particle_flow_channel_interface::get_particle_file_or_real_id - File ID and ID "
                                      "channel interface not initialized." );
    }

    void set_particle_file_id( int index, int value ) const {
        if( m_channels.fidW )
            m_channels.fidW->SetValue( index, value );
        else
            throw std::runtime_error(
                "particle_flow_channel_interface::set_particle_file_id - File ID channel interface not initialized." );
    }

    int get_particle_flow_count() const {
        if( m_channels.amountR )
            return m_channels.amountR->Count();
        else
            throw std::runtime_error( "particle_flow_channel_interface::get_particle_flow_count - AmountR channel "
                                      "interface not initialized." );
    }

    bool is_particle_new( int index ) const {
        if( m_channels.newR )
            return m_channels.newR->IsNew( index );
        else
            throw std::runtime_error(
                "particle_flow_channel_interface::get_particle_flow_count - NewR channel interface not initialized." );
    }

    void copy_particle( char& particleData, int toIndex, TimeValue time, bool noBlend = false ) {
        try {
            // Blendables

            // Position
            if( m_accessors.hasPosition ) {
                frantic::graphics::vector3f position =
                    frantic::max3d::from_max_t( m_channels.positionR->GetValue( toIndex ) );
                if( noBlend )
                    m_channels.positionW->SetValue(
                        toIndex, frantic::max3d::to_max_t( m_accessors.position.get( &particleData ) ) );
                else if( m_channels.positionBlendType == BLEND ) // regular
                    m_channels.positionW->SetValue(
                        toIndex, frantic::max3d::to_max_t( m_channels.positionBlendAlpha *
                                                               m_accessors.position.get( &particleData ) +
                                                           ( 1.f - m_channels.positionBlendAlpha ) * position ) );
                else if( m_channels.positionBlendType == ADD ) // additive
                    m_channels.positionW->SetValue(
                        toIndex,
                        frantic::max3d::to_max_t(
                            m_channels.positionBlendAlpha * m_accessors.position.get( &particleData ) + position ) );
            }

            // Velocity
            if( m_accessors.hasVelocity ) {
                frantic::graphics::vector3f velocity =
                    frantic::max3d::from_max_t( m_channels.velocityR->GetValue( toIndex ) );
                if( noBlend ) {
                    frantic::graphics::vector3f thevelocity = m_accessors.velocity.get( &particleData );
                    frantic::graphics::vector3f modifiedvelocity = thevelocity / float( TIME_TICKSPERSEC );
                    m_channels.velocityW->SetValue( toIndex, frantic::max3d::to_max_t( modifiedvelocity ) );
                } else if( m_channels.velocityBlendType == BLEND ) { // regular
                    m_channels.velocityW->SetValue(
                        toIndex, frantic::max3d::to_max_t( m_channels.velocityBlendAlpha *
                                                               m_accessors.velocity.get( &particleData ) /
                                                               float( TIME_TICKSPERSEC ) +
                                                           ( 1.f - m_channels.velocityBlendAlpha ) * velocity ) );
                } else if( m_channels.velocityBlendType == ADD ) { // additive
                    m_channels.velocityW->SetValue(
                        toIndex, frantic::max3d::to_max_t( m_channels.velocityBlendAlpha *
                                                               m_accessors.velocity.get( &particleData ) /
                                                               float( TIME_TICKSPERSEC ) +
                                                           velocity ) );
                }
            }

            // Acceleration
            if( m_accessors.hasAcceleration ) {
                frantic::graphics::vector3f acceleration =
                    frantic::max3d::from_max_t( m_channels.accelerationR->GetValue( toIndex ) );
                if( noBlend )
                    m_channels.accelerationW->SetValue(
                        toIndex, frantic::max3d::to_max_t( m_accessors.acceleration.get( &particleData ) /
                                                           float( TIME_TICKSPERSEC * TIME_TICKSPERSEC ) ) );
                else if( m_channels.accelerationBlendType == BLEND ) // regular
                    m_channels.accelerationW->SetValue(
                        toIndex, frantic::max3d::to_max_t(
                                     m_channels.accelerationBlendAlpha * m_accessors.acceleration.get( &particleData ) /
                                         float( TIME_TICKSPERSEC * TIME_TICKSPERSEC ) +
                                     ( 1.f - m_channels.accelerationBlendAlpha ) * acceleration ) );
                else if( m_channels.accelerationBlendType == ADD ) // additive
                    m_channels.accelerationW->SetValue(
                        toIndex, frantic::max3d::to_max_t( m_channels.accelerationBlendAlpha *
                                                               m_accessors.acceleration.get( &particleData ) /
                                                               float( TIME_TICKSPERSEC * TIME_TICKSPERSEC ) +
                                                           acceleration ) );
            }

            // Scale
            if( m_accessors.hasScale ) {
                frantic::graphics::vector3f scale =
                    frantic::max3d::from_max_t( m_channels.scaleR->GetValue( toIndex ) );
                if( noBlend )
                    m_channels.scaleW->SetValue( toIndex,
                                                 frantic::max3d::to_max_t( m_accessors.scale.get( &particleData ) ) );
                else if( m_channels.scaleBlendType == BLEND ) // regular
                    m_channels.scaleW->SetValue(
                        toIndex,
                        frantic::max3d::to_max_t( m_channels.scaleBlendAlpha * m_accessors.scale.get( &particleData ) +
                                                  ( 1.f - m_channels.scaleBlendAlpha ) * scale ) );
                else if( m_channels.scaleBlendType == ADD ) // additive
                    m_channels.scaleW->SetValue(
                        toIndex, frantic::max3d::to_max_t(
                                     m_channels.scaleBlendAlpha * m_accessors.scale.get( &particleData ) + scale ) );
            }

            // Orientation
            if( m_accessors.hasOrientation ) {
                Quat pflowQ = m_channels.orientationR->GetValue( toIndex );
                Quat fileQ(
                    m_accessors.orientation.get( &particleData ).x, m_accessors.orientation.get( &particleData ).y,
                    m_accessors.orientation.get( &particleData ).z, -m_accessors.orientation.get( &particleData ).w );
                Quat slerpQ;
                if( noBlend )
                    m_channels.orientationW->SetValue( toIndex, fileQ );
                else if( m_channels.orientationBlendType == BLEND ) { // regular
                    pflowQ.Normalize();
                    fileQ.Normalize();
                    slerpQ = Slerp( pflowQ, fileQ, m_channels.orientationBlendAlpha );
                    m_channels.orientationW->SetValue( toIndex, slerpQ );
                } else if( m_channels.orientationBlendType == ADD ) { // additive
                    // TODO:  This isn't right.  How do you do additive orientation blending?
                    m_channels.orientationW->SetValue( toIndex, pflowQ + m_channels.orientationBlendAlpha * fileQ );
                }
            }

            // Spin
            if( m_accessors.hasSpin ) {
                Quat pflowQ = m_channels.spinR->GetValue( toIndex );
                Quat fileQ( m_accessors.spin.get( &particleData ).x, m_accessors.spin.get( &particleData ).y,
                            m_accessors.spin.get( &particleData ).z, m_accessors.spin.get( &particleData ).w );
                Quat slerpQ;
                if( noBlend )
                    m_channels.spinW->SetValue( toIndex, fileQ );
                else if( m_channels.spinBlendType == BLEND ) { // regular
                    slerpQ = Slerp( pflowQ, fileQ, m_channels.spinBlendAlpha );
                    m_channels.spinW->SetValue( toIndex, slerpQ );
                } else if( m_channels.spinBlendType == ADD ) { // additive
                    // TODO:  This isn't right.  How do you do additive spin blending?
                    m_channels.spinW->SetValue( toIndex, pflowQ + m_channels.spinBlendAlpha * fileQ );
                }
            }

            // MXSFloat
            if( m_accessors.hasMXSFloat ) {
                float mxsFloat = m_channels.mxsFloatR->GetValue( toIndex );
                if( noBlend )
                    m_channels.mxsFloatW->SetValue( toIndex, m_accessors.mxsFloat.get( &particleData ) );
                else if( m_channels.mxsFloatBlendType == BLEND ) // regular
                    m_channels.mxsFloatW->SetValue( toIndex, m_channels.mxsFloatBlendAlpha *
                                                                     m_accessors.mxsFloat.get( &particleData ) +
                                                                 ( 1.f - m_channels.mxsFloatBlendAlpha ) * mxsFloat );
                else if( m_channels.mxsFloatBlendType == ADD ) // additive
                    m_channels.mxsFloatW->SetValue(
                        toIndex, m_channels.mxsFloatBlendAlpha * m_accessors.mxsFloat.get( &particleData ) + mxsFloat );
            }

            // MXSVector
            if( m_accessors.hasMXSVector ) {
                frantic::graphics::vector3f mxsVector =
                    frantic::max3d::from_max_t( m_channels.mxsVectorR->GetValue( toIndex ) );
                if( noBlend )
                    m_channels.mxsVectorW->SetValue(
                        toIndex, frantic::max3d::to_max_t( m_accessors.mxsVector.get( &particleData ) ) );
                else if( m_channels.mxsVectorBlendType == BLEND ) // regular
                    m_channels.mxsVectorW->SetValue(
                        toIndex, frantic::max3d::to_max_t( m_channels.mxsVectorBlendAlpha *
                                                               m_accessors.mxsVector.get( &particleData ) +
                                                           ( 1.f - m_channels.mxsVectorBlendAlpha ) * mxsVector ) );
                else if( m_channels.mxsVectorBlendType == ADD ) // additive
                    m_channels.mxsVectorW->SetValue(
                        toIndex,
                        frantic::max3d::to_max_t(
                            m_channels.mxsVectorBlendAlpha * m_accessors.mxsVector.get( &particleData ) + mxsVector ) );
            }

            // Color
            if( m_accessors.hasColor ) {
                const TabUVVert* uv = m_channels.colorR->GetUVVert( toIndex );
                if( !uv || uv->Count() == 0 )
                    throw std::runtime_error( "particle_flow_channel_interface::copy_particle() - the Vertex Color "
                                              "Channel (map channel 0) was present but empty." );
                frantic::graphics::vector3f color = frantic::max3d::from_max_t( ( *uv )[0] );
                if( noBlend )
                    m_channels.colorW->SetUVVert( toIndex,
                                                  frantic::max3d::to_max_t( m_accessors.color.get( &particleData ) ) );
                else if( m_channels.colorBlendType == BLEND ) // regular
                    m_channels.colorW->SetUVVert(
                        toIndex,
                        frantic::max3d::to_max_t( m_channels.colorBlendAlpha * m_accessors.color.get( &particleData ) +
                                                  ( 1.f - m_channels.colorBlendAlpha ) * color ) );
                else if( m_channels.colorBlendType == ADD ) // additive
                    m_channels.colorW->SetUVVert(
                        toIndex, frantic::max3d::to_max_t(
                                     m_channels.colorBlendAlpha * m_accessors.color.get( &particleData ) + color ) );
                uv = m_channels.colorR->GetUVVert( toIndex );
                color = frantic::max3d::from_max_t( ( *uv )[0] );
            }

            // TextureCoords
            if( m_accessors.hasTextureCoord ) {
                const TabUVVert* uv = m_channels.textureCoordR->GetUVVert( toIndex );
                if( !uv || uv->Count() == 0 )
                    throw std::runtime_error( "particle_flow_channel_interface::copy_particle() - the TextureCoord "
                                              "Channel (map channel 1) was present but empty." );
                frantic::graphics::vector3f textureCoord = frantic::max3d::from_max_t( ( *uv )[0] );
                if( noBlend )
                    m_channels.textureCoordW->SetUVVert(
                        toIndex, frantic::max3d::to_max_t( m_accessors.textureCoord.get( &particleData ) ) );
                else if( m_channels.textureCoordBlendType == BLEND ) // regular
                    m_channels.textureCoordW->SetUVVert(
                        toIndex, frantic::max3d::to_max_t(
                                     m_channels.textureCoordBlendAlpha * m_accessors.textureCoord.get( &particleData ) +
                                     ( 1.f - m_channels.textureCoordBlendAlpha ) * textureCoord ) );
                else if( m_channels.textureCoordBlendType == ADD ) // additive
                    m_channels.textureCoordW->SetUVVert(
                        toIndex, frantic::max3d::to_max_t( m_channels.textureCoordBlendAlpha *
                                                               m_accessors.textureCoord.get( &particleData ) +
                                                           textureCoord ) );
            }

            for( std::size_t i = 0; i < m_accessors.mappings.size(); ++i ) {
                const TabUVVert* uv = m_accessors.mappings[i].R->GetUVVert( toIndex );
                if( !uv || uv->Count() == 0 )
                    throw std::runtime_error( "max_pflow_particle_istream::get_particle() - the Map Channel[" +
                                              boost::lexical_cast<std::string>( m_accessors.mappings[i].channelNum ) +
                                              "] was present but empty." );
                frantic::graphics::vector3f mapData = frantic::max3d::from_max_t( ( *uv )[0] );
                if( noBlend )
                    m_accessors.mappings[i].W->SetUVVert(
                        toIndex, frantic::max3d::to_max_t( m_accessors.mappings[i].acc.get( &particleData ) ) );
                else if( m_accessors.mappings[i].blendType == BLEND ) // regular
                    m_accessors.mappings[i].W->SetUVVert(
                        toIndex, frantic::max3d::to_max_t( m_accessors.mappings[i].blendAlpha *
                                                               m_accessors.mappings[i].acc.get( &particleData ) +
                                                           ( 1.f - m_accessors.mappings[i].blendAlpha ) * mapData ) );
                else if( m_accessors.mappings[i].blendType == ADD ) // additive
                    m_accessors.mappings[i].W->SetUVVert(
                        toIndex, frantic::max3d::to_max_t( m_accessors.mappings[i].blendAlpha *
                                                               m_accessors.mappings[i].acc.get( &particleData ) +
                                                           mapData ) );
            }

            // Non-blendables

            // Age
            if( m_accessors.hasAge ) {
                m_channels.birthW->SetValue( toIndex,
                                             time - frantic::max3d::to_ticks( m_accessors.age.get( &particleData ) ) );
            }

            // LifeSpan
            if( m_accessors.hasLifeSpan ) {
                TimeValue lifeSpan = frantic::max3d::to_ticks( m_accessors.lifeSpan.get( &particleData ) );
                TimeValue birthTime = m_channels.birthR->GetTick( toIndex );
                m_channels.deathW->SetValue( toIndex, ( birthTime + lifeSpan ) );
                m_channels.lifeSpanW->SetValue( toIndex, lifeSpan );
            }

            // MXSInteger
            if( m_accessors.hasMXSInteger ) {
                m_channels.mxsIntegerW->SetValue( toIndex, m_accessors.mxsInteger.get( &particleData ) );
            }

            // Material Index
            if( m_accessors.hasMaterialIndex ) {
                m_channels.materialIndexW->SetValue( toIndex, m_accessors.materialIndex.get( &particleData ) );
            }

        } catch( std::exception& e ) {
            GetCOREInterface()->Log()->LogEntry( SYSLOG_ERROR, DISPLAY_DIALOG,
                                                 _T("particle_flow_channel_interface::copy_particle() Error"),
                                                 HANDLE_STD_EXCEPTION_MSG( e ) );
            if( IsNetworkRenderServer() )
                throw MAXException( HANDLE_STD_EXCEPTION_MSG( e ) );
        }
    }

    /**
     *	This function does several things.  It initializes each of the required channel interfaces as indicated
     *  by a previously set channel map.  It intializes the particle accessors as indicated by the channel map.
     *	It sets any appropriate blending information for the required channels as indicated by the channel map.
     **/
    void initialize_channel_interface( frantic::channels::channel_map& pflowMap,
                                       std::vector<frantic::tstring>& blendChannelNames,
                                       std::vector<int>& blendChannelTypes, std::vector<float>& blendChannelAlphas,
                                       bool fertile = false ) {

        m_pflowMap = pflowMap;

        // TODO:  There should probably be some error checking here to make sure the args being
        // passed are consistent.

        // make a map of the blend info for easier access
        std::map<frantic::tstring, std::pair<int, float>> blendMap;
        for( size_t i = 0; i < blendChannelNames.size(); ++i ) {
            std::pair<int, float> blendParams( blendChannelTypes[i], blendChannelAlphas[i] );
            blendMap[blendChannelNames[i]] = blendParams;
        }

        try {
            // Make sure we can check on the current particles in the container
            m_channels.amountR = GetParticleChannelAmountRInterface( m_particleContainer );
            if( m_channels.amountR == NULL )
                throw std::runtime_error(
                    "pflow_particle_interface: Could not set up the interface to IParticleChannelAmountR" );

            // Make sure we can add new particles to this container
            m_channels.amountW = GetParticleChannelAmountWInterface( m_particleContainer );
            if( m_channels.amountW == NULL )
                throw std::runtime_error(
                    "pflow_particle_interface: Could not set up the interface to IParticleChannelAmountR" );

            // Get access to ChannelContainer interface
            m_channels.channelContainer = GetChannelContainerInterface( m_particleContainer );
            if( m_channels.channelContainer == NULL )
                throw std::runtime_error(
                    "pflow_particle_interface: Could not set up the interface to ChannelContainer" );

            // we always want the ID, of some sort
            if( fertile ) {
                m_channels.fidW = (IParticleChannelIntW*)m_channels.channelContainer->EnsureInterface(
                    PARTICLECHANNELFILEIDINTEGERW_INTERFACE, ParticleChannelInt_Class_ID, true,
                    PARTICLECHANNELFILEIDINTEGERR_INTERFACE, PARTICLECHANNELFILEIDINTEGERW_INTERFACE, true );
                if( !m_channels.fidW )
                    throw std::runtime_error( "pflow_particle_interface::init_channels - Could not obtain the pflow "
                                              "FileIDIntegerW interface." );
                m_channels.fidR = GetParticleChannelFileIDIntegerRInterface( m_channels.channelContainer );
                if( !m_channels.fidR )
                    throw std::runtime_error( "pflow_particle_interface::init_channels - Could not obtain the pflow "
                                              "FileIDIntegerR interface." );
            } else {
                m_channels.fidW = GetParticleChannelFileIDIntegerWInterface( m_channels.channelContainer );
                m_channels.fidR = GetParticleChannelFileIDIntegerRInterface( m_channels.channelContainer );
            }

            // don't force this interface.
            m_channels.idW = GetParticleChannelIDWInterface( m_channels.channelContainer );
            m_channels.idR = GetParticleChannelIDRInterface( m_channels.channelContainer );

            // need this interface for new particle checks
            m_channels.newW = (IParticleChannelNewW*)m_channels.channelContainer->EnsureInterface(
                PARTICLECHANNELNEWW_INTERFACE, ParticleChannelNew_Class_ID, false, Interface_ID( 0, 0 ),
                Interface_ID( 0, 0 ) );
            if( !m_channels.newW )
                throw std::runtime_error(
                    "pflow_particle_interface::init_channels - Could not set up the interface to ParticleChannelNewW" );
            m_channels.newR = GetParticleChannelNewRInterface( m_channels.channelContainer );
            if( !m_channels.newR )
                throw std::runtime_error(
                    "pflow_particle_interface::init_channels - Could not obtain the pflow NewR interface." );

            if( m_pflowMap.has_channel( _T("Position") ) ) {
                m_channels.positionW = (IParticleChannelPoint3W*)m_channels.channelContainer->EnsureInterface(
                    PARTICLECHANNELPOSITIONW_INTERFACE, ParticleChannelPoint3_Class_ID, true,
                    PARTICLECHANNELPOSITIONR_INTERFACE, PARTICLECHANNELPOSITIONW_INTERFACE, true );
                if( !m_channels.positionW )
                    throw std::runtime_error(
                        "pflow_particle_interface::init_channels - Could not obtain the pflow PositionW interface." );
                m_channels.positionR = GetParticleChannelPositionRInterface( m_channels.channelContainer );
                if( !m_channels.positionR )
                    throw std::runtime_error(
                        "pflow_particle_interface::init_channels - Could not obtain the pflow PositionR interface." );
                m_accessors.hasPosition = true;
                m_accessors.position = m_pflowMap.get_cvt_accessor<frantic::graphics::vector3f>( _T("Position") );
                m_channels.positionBlendType = blendMap[_T("Position")].first;
                m_channels.positionBlendAlpha = blendMap[_T("Position")].second;
            }

            if( m_pflowMap.has_channel( _T("Velocity") ) ) {
                m_channels.velocityW = (IParticleChannelPoint3W*)m_channels.channelContainer->EnsureInterface(
                    PARTICLECHANNELSPEEDW_INTERFACE, ParticleChannelPoint3_Class_ID, true,
                    PARTICLECHANNELSPEEDR_INTERFACE, PARTICLECHANNELSPEEDW_INTERFACE, true );
                if( !m_channels.velocityW )
                    throw std::runtime_error( "pflow_particle_interface::init_channels - Could not obtain the pflow "
                                              "SpeedW (velocity) interface." );
                m_channels.velocityR = GetParticleChannelSpeedRInterface( m_channels.channelContainer );
                if( !m_channels.velocityR )
                    throw std::runtime_error( "pflow_particle_interface::init_channels - Could not obtain the pflow "
                                              "SpeedR (velocity) interface." );
                m_accessors.hasVelocity = true;
                m_accessors.velocity = m_pflowMap.get_cvt_accessor<frantic::graphics::vector3f>( _T("Velocity") );
                m_channels.velocityBlendType = blendMap[_T("Velocity")].first;
                m_channels.velocityBlendAlpha = blendMap[_T("Velocity")].second;
            }

            if( m_pflowMap.has_channel( _T("Acceleration") ) ) {
                m_channels.accelerationW = (IParticleChannelPoint3W*)m_channels.channelContainer->EnsureInterface(
                    PARTICLECHANNELACCELERATIONW_INTERFACE, ParticleChannelPoint3_Class_ID, true,
                    PARTICLECHANNELACCELERATIONR_INTERFACE, PARTICLECHANNELACCELERATIONW_INTERFACE, true );
                if( !m_channels.accelerationW )
                    throw std::runtime_error( "pflow_particle_interface::init_channels - Could not obtain the pflow "
                                              "AccelerationW interface." );
                m_channels.accelerationR = GetParticleChannelAccelerationRInterface( m_channels.channelContainer );
                if( !m_channels.accelerationR )
                    throw std::runtime_error( "pflow_particle_interface::init_channels - Could not obtain the pflow "
                                              "AccelerationR interface." );
                m_accessors.hasAcceleration = true;
                m_accessors.acceleration =
                    m_pflowMap.get_cvt_accessor<frantic::graphics::vector3f>( _T("Acceleration") );
                m_channels.accelerationBlendType = blendMap[_T("Acceleration")].first;
                m_channels.accelerationBlendAlpha = blendMap[_T("Acceleration")].second;
            }

            if( m_pflowMap.has_channel( _T("Orientation") ) ) {
                m_channels.orientationW = (IParticleChannelQuatW*)m_channels.channelContainer->EnsureInterface(
                    PARTICLECHANNELORIENTATIONW_INTERFACE, ParticleChannelQuat_Class_ID, true,
                    PARTICLECHANNELORIENTATIONR_INTERFACE, PARTICLECHANNELORIENTATIONW_INTERFACE, true );
                if( !m_channels.orientationW )
                    throw std::runtime_error( "pflow_particle_interface::init_channels - Could not obtain the pflow "
                                              "OrientationW interface." );
                m_channels.orientationR = GetParticleChannelOrientationRInterface( m_channels.channelContainer );
                if( !m_channels.orientationR )
                    throw std::runtime_error( "pflow_particle_interface::init_channels - Could not obtain the pflow "
                                              "OrientationR interface." );
                m_accessors.hasOrientation = true;
                m_accessors.orientation = m_pflowMap.get_cvt_accessor<frantic::graphics::vector4f>( _T("Orientation") );
                m_channels.orientationBlendType = blendMap[_T("Orientation")].first;
                m_channels.orientationBlendAlpha = blendMap[_T("Orientation")].second;
            }

            if( m_pflowMap.has_channel( _T("Spin") ) ) {
                m_channels.spinW = (IParticleChannelAngAxisW*)m_channels.channelContainer->EnsureInterface(
                    PARTICLECHANNELSPINW_INTERFACE, ParticleChannelAngAxis_Class_ID, true,
                    PARTICLECHANNELSPINR_INTERFACE, PARTICLECHANNELSPINW_INTERFACE, true );
                if( !m_channels.spinW )
                    throw std::runtime_error(
                        "pflow_particle_interface::init_channels - Could not obtain the pflow SpinW interface." );
                m_channels.spinR = GetParticleChannelSpinRInterface( m_channels.channelContainer );
                if( !m_channels.spinR )
                    throw std::runtime_error(
                        "pflow_particle_interface::init_channels - Could not obtain the pflow SpinR interface." );
                m_accessors.hasSpin = true;
                m_accessors.spin = m_pflowMap.get_cvt_accessor<frantic::graphics::vector4f>( _T("Spin") );
                m_channels.spinBlendType = blendMap[_T("Spin")].first;
                m_channels.spinBlendAlpha = blendMap[_T("Spin")].second;
            }

            if( m_pflowMap.has_channel( _T("Scale") ) ) {
                m_channels.scaleW = (IParticleChannelPoint3W*)m_channels.channelContainer->EnsureInterface(
                    PARTICLECHANNELSCALEW_INTERFACE, ParticleChannelPoint3_Class_ID, true,
                    PARTICLECHANNELSCALER_INTERFACE, PARTICLECHANNELSCALEW_INTERFACE, true );
                if( !m_channels.scaleW )
                    throw std::runtime_error(
                        "pflow_particle_interface::init_channels - Could not obtain the pflow ScaleW interface." );
                m_channels.scaleR = GetParticleChannelScaleRInterface( m_channels.channelContainer );
                if( !m_channels.scaleR )
                    throw std::runtime_error(
                        "pflow_particle_interface::init_channels - Could not obtain the pflow ScaleR interface." );
                m_accessors.hasScale = true;
                m_accessors.scale = m_pflowMap.get_cvt_accessor<frantic::graphics::vector3f>( _T("Scale") );
                m_channels.scaleBlendType = blendMap[_T("Scale")].first;
                m_channels.scaleBlendAlpha = blendMap[_T("Scale")].second;
            }

            if( m_pflowMap.has_channel( _T("MtlIndex") ) ) {
                m_channels.materialIndexW = (IParticleChannelIntW*)m_channels.channelContainer->EnsureInterface(
                    PARTICLECHANNELMTLINDEXW_INTERFACE, ParticleChannelInt_Class_ID, true,
                    PARTICLECHANNELMTLINDEXR_INTERFACE, PARTICLECHANNELMTLINDEXW_INTERFACE, true );
                if( !m_channels.materialIndexW )
                    throw std::runtime_error( "pflow_particle_interface::init_channels - Could not obtain the pflow "
                                              "MaterialIndexW interface." );
                m_channels.materialIndexR = GetParticleChannelMtlIndexRInterface( m_channels.channelContainer );
                if( !m_channels.materialIndexR )
                    throw std::runtime_error( "pflow_particle_interface::init_channels - Could not obtain the pflow "
                                              "MaterialIndexR interface." );
                m_accessors.hasMaterialIndex = true;
                m_accessors.materialIndex = m_pflowMap.get_cvt_accessor<int>( _T("MtlIndex") );
            }

            if( m_pflowMap.has_channel( _T("Age") ) || m_pflowMap.has_channel( _T("LifeSpan") ) ) {
                m_channels.birthW = (IParticleChannelPTVW*)m_channels.channelContainer->EnsureInterface(
                    PARTICLECHANNELBIRTHTIMEW_INTERFACE, ParticleChannelPTV_Class_ID, true,
                    PARTICLECHANNELBIRTHTIMER_INTERFACE, PARTICLECHANNELBIRTHTIMEW_INTERFACE, true );
                if( !m_channels.birthW )
                    throw std::runtime_error(
                        "pflow_particle_interface::init_channels - Could not obtain the pflow BirthTimeW interface." );
                m_channels.birthR = GetParticleChannelBirthTimeRInterface( m_channels.channelContainer );
                if( !m_channels.birthR )
                    throw std::runtime_error(
                        "pflow_particle_interface::init_channels - Could not obtain the pflow BirthTimeR interface." );

                m_channels.deathW = (IParticleChannelPTVW*)m_channels.channelContainer->EnsureInterface(
                    PARTICLECHANNELDEATHTIMEW_INTERFACE, ParticleChannelPTV_Class_ID, true,
                    PARTICLECHANNELDEATHTIMER_INTERFACE, PARTICLECHANNELDEATHTIMEW_INTERFACE, true );
                if( !m_channels.deathW )
                    throw std::runtime_error(
                        "pflow_particle_interface::init_channels - Could not obtain the pflow DeathTimeW interface." );
                m_channels.deathR = GetParticleChannelDeathTimeRInterface( m_channels.channelContainer );
                if( !m_channels.deathR )
                    throw std::runtime_error(
                        "pflow_particle_interface::init_channels - Could not obtain the pflow DeathTimeR interface." );

                m_channels.lifeSpanW = (IParticleChannelPTVW*)m_channels.channelContainer->EnsureInterface(
                    PARTICLECHANNELLIFESPANW_INTERFACE, ParticleChannelPTV_Class_ID, true,
                    PARTICLECHANNELLIFESPANR_INTERFACE, PARTICLECHANNELLIFESPANW_INTERFACE, true );
                if( !m_channels.lifeSpanW )
                    throw std::runtime_error(
                        "pflow_particle_interface::init_channels - Could not obtain the pflow LifeSpanW interface." );
                m_channels.lifeSpanR = GetParticleChannelLifespanRInterface( m_channels.channelContainer );
                if( !m_channels.lifeSpanR )
                    throw std::runtime_error(
                        "pflow_particle_interface::init_channels - Could not obtain the pflow LifeSpanR interface." );

                if( m_pflowMap.has_channel( _T("Age") ) ) {
                    m_accessors.hasAge = true;
                    m_accessors.age = m_pflowMap.get_cvt_accessor<float>( _T("Age") );
                }

                if( m_pflowMap.has_channel( _T("LifeSpan") ) ) {
                    m_accessors.hasLifeSpan = true;
                    m_accessors.lifeSpan = m_pflowMap.get_cvt_accessor<float>( _T("LifeSpan") );
                }
            }

            if( m_pflowMap.has_channel( _T("MXSInteger") ) ) {
                m_channels.mxsIntegerW = (IParticleChannelIntW*)m_channels.channelContainer->EnsureInterface(
                    PARTICLECHANNELMXSINTEGERW_INTERFACE, ParticleChannelInt_Class_ID, true,
                    PARTICLECHANNELMXSINTEGERR_INTERFACE, PARTICLECHANNELMXSINTEGERW_INTERFACE, true );
                if( !m_channels.mxsIntegerW )
                    throw std::runtime_error(
                        "pflow_particle_interface::init_channels - Could not obtain the pflow MXSIntegerW interface." );
                m_channels.mxsIntegerR = GetParticleChannelMXSIntegerRInterface( m_channels.channelContainer );
                if( !m_channels.mxsIntegerR )
                    throw std::runtime_error(
                        "pflow_particle_interface::init_channels - Could not obtain the pflow MXSIntegerR interface." );
                m_accessors.hasMXSInteger = true;
                m_accessors.mxsInteger = m_pflowMap.get_cvt_accessor<int>( _T("MXSInteger") );
            }

            if( m_pflowMap.has_channel( _T("MXSFloat") ) ) {
                m_channels.mxsFloatW = (IParticleChannelFloatW*)m_channels.channelContainer->EnsureInterface(
                    PARTICLECHANNELMXSFLOATW_INTERFACE, ParticleChannelFloat_Class_ID, true,
                    PARTICLECHANNELMXSFLOATR_INTERFACE, PARTICLECHANNELMXSFLOATW_INTERFACE, true );
                if( !m_channels.mxsFloatW )
                    throw std::runtime_error(
                        "pflow_particle_interface::init_channels - Could not obtain the pflow MXSFloatW interface." );
                m_channels.mxsFloatR = GetParticleChannelMXSFloatRInterface( m_channels.channelContainer );
                if( !m_channels.mxsFloatR )
                    throw std::runtime_error(
                        "pflow_particle_interface::init_channels - Could not obtain the pflow MXSFloatR interface." );
                m_accessors.hasMXSFloat = true;
                m_accessors.mxsFloat = m_pflowMap.get_cvt_accessor<float>( _T("MXSFloat") );
                m_channels.mxsFloatBlendType = blendMap[_T("MXSFloat")].first;
                m_channels.mxsFloatBlendAlpha = blendMap[_T("MXSFloat")].second;
            }

            if( m_pflowMap.has_channel( _T("MXSVector") ) ) {
                m_channels.mxsVectorW = (IParticleChannelPoint3W*)m_channels.channelContainer->EnsureInterface(
                    PARTICLECHANNELMXSVECTORW_INTERFACE, ParticleChannelPoint3_Class_ID, true,
                    PARTICLECHANNELMXSVECTORR_INTERFACE, PARTICLECHANNELMXSVECTORW_INTERFACE, true );
                if( !m_channels.mxsVectorW )
                    throw std::runtime_error(
                        "pflow_particle_interface::init_channels - Could not obtain the pflow MXSVectorW interface." );
                m_channels.mxsVectorR = GetParticleChannelMXSVectorRInterface( m_channels.channelContainer );
                if( !m_channels.mxsVectorR )
                    throw std::runtime_error(
                        "pflow_particle_interface::init_channels - Could not obtain the pflow MXSVectorR interface." );
                m_accessors.hasMXSVector = true;
                m_accessors.mxsVector = m_pflowMap.get_cvt_accessor<frantic::graphics::vector3f>( _T("MXSVector") );
                m_channels.mxsVectorBlendType = blendMap[_T("MXSVector")].first;
                m_channels.mxsVectorBlendAlpha = blendMap[_T("MXSVector")].second;
            }

            // the mapping channels work slightly differently.  channel 0 is saved with the name
            // "Color" and channel 1 with the name "TextureCoords".  the rest are saved as "Mapping#", so i have
            // to loop through the particle channel map to see if any of these are there and initialize
            // appropriately

            // check to see if there is a color, texture or other map channel
            bool needMeshMap = false;
            if( m_pflowMap.has_channel( _T("Color") ) || m_pflowMap.has_channel( _T("TextureCoord") ) )
                needMeshMap = true;
            for( size_t i = 2; i < MAX_MESHMAPS; i++ )
                if( m_pflowMap.has_channel( _T("Mapping") + boost::lexical_cast<frantic::tstring>( i ) ) )
                    needMeshMap = true;

            if( needMeshMap ) {

                m_channels.meshMapW = (IParticleChannelMeshMapW*)m_channels.channelContainer->EnsureInterface(
                    PARTICLECHANNELSHAPETEXTUREW_INTERFACE, ParticleChannelMeshMap_Class_ID, true,
                    PARTICLECHANNELSHAPETEXTURER_INTERFACE, PARTICLECHANNELSHAPETEXTUREW_INTERFACE, true );
                if( !m_channels.meshMapW )
                    throw std::runtime_error( "pflow_particle_interface::init_channels - Could not obtain the pflow "
                                              "ShapeTextureW interface (Required for mesh map channels)." );
                m_channels.meshMapR = GetParticleChannelShapeTextureRInterface( m_channels.channelContainer );
                if( !m_channels.meshMapR )
                    throw std::runtime_error( "pflow_particle_interface::init_channels - Could not obtain the pflow "
                                              "ShapeTextureR interface (Required for mesh map channels)." );

                if( m_pflowMap.has_channel( _T("Color") ) ) {

                    if( !m_channels.meshMapR->MapSupport( 0 ) )
                        m_channels.meshMapW->SetMapSupport( 0 );
                    m_channels.colorW = m_channels.meshMapW->GetMapChannel( 0 );
                    m_channels.colorR = m_channels.meshMapR->GetMapReadChannel( 0 );

                    m_accessors.hasColor = true;
                    m_accessors.color = m_pflowMap.get_cvt_accessor<frantic::graphics::vector3f>( _T("Color") );
                    m_channels.colorBlendType = blendMap[_T("Color")].first;
                    m_channels.colorBlendAlpha = blendMap[_T("Color")].second;
                }

                if( m_pflowMap.has_channel( _T("TextureCoord") ) ) {

                    if( !m_channels.meshMapR->MapSupport( 1 ) )
                        m_channels.meshMapW->SetMapSupport( 1 );
                    m_channels.textureCoordW = m_channels.meshMapW->GetMapChannel( 1 );
                    m_channels.textureCoordR = m_channels.meshMapR->GetMapReadChannel( 1 );

                    m_accessors.hasTextureCoord = true;
                    m_accessors.textureCoord =
                        m_pflowMap.get_cvt_accessor<frantic::graphics::vector3f>( _T("TextureCoord") );
                    m_channels.textureCoordBlendType = blendMap[_T("TextureCoord")].first;
                    m_channels.textureCoordBlendAlpha = blendMap[_T("TextureCoord")].second;
                }

                int mapCount = 0;
                for( int i = 0; i < MAX_MESHMAPS; ++i ) {
                    frantic::tstring channelName = _T("Mapping") + boost::lexical_cast<frantic::tstring>( i );
                    if( m_pflowMap.has_channel( channelName ) ) {
                        if( !m_channels.meshMapR->MapSupport( i ) )
                            m_channels.meshMapW->SetMapSupport( i );

                        m_accessors.mappings.push_back( channel_info(
                            i, m_channels.meshMapR->GetMapReadChannel( i ), m_channels.meshMapW->GetMapChannel( i ),
                            m_pflowMap.get_cvt_accessor<frantic::graphics::vector3f>( channelName ),
                            blendMap[channelName].first, blendMap[channelName].second ) );

                        mapCount++;
                    }
                }
            }

        } catch( std::exception& e ) {
            GetCOREInterface()->Log()->LogEntry( SYSLOG_ERROR, DISPLAY_DIALOG,
                                                 _T("ParticleFlow Channel Interface Error"),
                                                 HANDLE_STD_EXCEPTION_MSG( e ) );
            if( IsNetworkRenderServer() )
                throw MAXException( HANDLE_STD_EXCEPTION_MSG( e ) );
        }
    }
};

#pragma warning( pop )
