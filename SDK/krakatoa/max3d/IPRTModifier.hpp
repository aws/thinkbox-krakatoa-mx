// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0
#pragma once

#include <frantic/max3d/particles/IMaxKrakatoaPRTObject.hpp>
#include <frantic/particles/streams/particle_istream.hpp>

#define PRTModifier_INTERFACE Interface_ID( 0x325a76b9, 0x65554143 )

namespace krakatoa {
namespace max3d {

/**
 * This interface is provided by Modifier derived classes that affect Krakatoa PRT objects.
 */
class IPRTModifier : public BaseInterface {
  public:
    typedef boost::shared_ptr<frantic::particles::streams::particle_istream> particle_istream_ptr;

  public:
    virtual Interface_ID GetID() { return PRTModifier_INTERFACE; }

    /**
     * Applies the effects of this modifier to the particle_istream.
     * \param pin The particle_istream to modify.
     * \param pNode The scene node that produced these particles.
     * \param t The time to modify the particles at.
     * \param inoutValidity Will be updated with the validity interval of this modification. Represents the time range
     * around 't' where the resulting particle_istream has constant (or 0) velocity. \param evalContext Provides extra
     * information about how the particles are being evaluated. \return If this modifier has no effect it returns 'pin',
     * otherwise a new stream that wraps and changes the particles from 'pin'.
     */
    virtual particle_istream_ptr
    ApplyModifier( particle_istream_ptr pin, INode* pNode, TimeValue t, Interval& inoutValidity,
                   frantic::max3d::particles::IMaxKrakatoaPRTEvalContextPtr evalContext ) = 0;
};

inline IPRTModifier* GetPRTModifierInterface( Animatable* anim ) {
    return static_cast<IPRTModifier*>( anim ? anim->GetInterface( PRTModifier_INTERFACE ) : NULL );
}

} // namespace max3d
} // namespace krakatoa
