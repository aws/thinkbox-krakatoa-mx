// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0
#pragma once

#include <frantic/max3d/particles/IMaxKrakatoaPRTObject.hpp>

#include <IParticleObjectExt.h>

namespace krakatoa {
namespace max3d {

class IPRTParticleObjectExtOwner;

boost::shared_ptr<IParticleObjectExt> CreatePRTParticleObjectExt( IPRTParticleObjectExtOwner* pOwner );

/**
 * This interface is used by PRTIParticleObjectExt in order to interact with the object that "owns" the
 * PRTIParticleObjectExt interface. ex. class SomePRTObject : public IPRTParticleObjectExtOwner{ private:
 *      boost::shared_ptr<IParticleObjectExt> m_particleObjectExt;
 *
 *   public:
 *      SomePRTObject(){
 *        m_particleObjectExt = CreatePRTParticleObjectExt( static_cast<IPRTParticleObjectExtOwner*>( this ) );
 *      }
 *
 *      BaseInterface* GetInterface( Interface_ID id ){
 *        if( id == ParticleObjectExt_INTERFACE )
 *          return m_particleObjectExt.get();
 *      }
 *   };
 */
class IPRTParticleObjectExtOwner {
  public:
    virtual ~IPRTParticleObjectExtOwner() {}

    /**
     * Called to create the particle stream from the owner object.
     */
    virtual frantic::particles::particle_istream_ptr
    create_particle_stream( INode* pNode, Interval& outValidity,
                            boost::shared_ptr<frantic::max3d::particles::IMaxKrakatoaPRTEvalContext> pEvalContext ) = 0;
};

} // namespace max3d
} // namespace krakatoa
