// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0
#pragma once

#include <frantic/max3d/particles/IMaxKrakatoaPRTObject.hpp>
#include <frantic/particles/streams/particle_istream.hpp>

#define MaxKrakatoaModifier_INTERFACE Interface_ID( 0x325a76b9, 0x65554143 )

class MaxKrakatoaModifierInterface : public BaseInterface {
  public:
    typedef boost::shared_ptr<frantic::particles::streams::particle_istream> particle_istream_ptr;

    virtual Interface_ID GetID() { return MaxKrakatoaModifier_INTERFACE; }

    virtual particle_istream_ptr
    apply_modifier( particle_istream_ptr pin, INode* pNode,
                    frantic::max3d::particles::IMaxKrakatoaPRTObject::IEvalContext* evalContext ) = 0;
};

inline MaxKrakatoaModifierInterface* GetMaxKrakatoaModifierInterface( Animatable* anim ) {
    return static_cast<MaxKrakatoaModifierInterface*>( anim ? anim->GetInterface( MaxKrakatoaModifier_INTERFACE )
                                                            : NULL );
}
