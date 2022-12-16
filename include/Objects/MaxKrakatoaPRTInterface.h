// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0
#pragma once

#include <frantic/max3d/particles/IMaxKrakatoaPRTObject.hpp>
#include <krakatoa/max3d/PRTObject.hpp>

using frantic::particles::particle_istream_ptr;

// A list of the class IDs of objects supporting this interface
#define MaxKrakatoaHairObject_CLASSID Class_ID( 0x16b1d56, 0x2264727c )
#define MaxKrakatoaVolumeObject_CLASSID Class_ID( 0x5dca3970, 0x6b502d65 )
#define MaxKrakatoaPRTSystem_CLASSID Class_ID( 0x3c4814fe, 0x76cf26ae )
#define MaxKrakatoaFumeFXObject_CLASS_ID Class_ID( 0x3a380a24, 0xb230c50 )
#define MaxKrakatoaPhoenixObject_CLASS_ID Class_ID( 0x6e742b9, 0x1d2d1bc4 )
#define MaxKrakatoaPRTSourceObject_CLASSID Class_ID( 0x766a7a0d, 0x311b4fbd )
#define MaxKrakatoaPRTMakerObject_CLASSID Class_ID( 0x71e803f8, 0x5d227184 )
#define MaxKrakatoaPRTSurface_CLASSID Class_ID( 0x4f39184b, 0x4af218d7 )

// Import frantic::max3d::particles::IMaxKrakatoaPRTObject (and pals) into the global namespace for legacy reasons
using frantic::max3d::particles::GetIMaxKrakatoaPRTObject;
using frantic::max3d::particles::IMaxKrakatoaPRTObject;
using frantic::max3d::particles::IMaxKrakatoaPRTObject_Legacy1;
using frantic::max3d::particles::IMaxKrakatoaPRTObjectPtr;

// Moved this to KrakatoaMX_SDK project, and added this using & macro to make the existing names compatible.
using krakatoa::max3d::PRTObject;
#define MaxKrakatoaPRTObject PRTObject

// For legacy reasons, this is considered to not be a nestged class.
// typedef frantic::max3d::particles::IMaxKrakatoaPRTObject::IEvalContext IEvalContext;

using krakatoa::max3d::IMaxKrakatoaEvalContext;

///**
// * This abstract interface is provided to extend IEvalContext with new functionality within Krakatoa,
// * without breaking binary compatibility with clients of IEvalContext. I'm looking at you Frost.
// */
// class IMaxKrakatoaEvalContext : public frantic::max3d::particles::IMaxKrakatoaPRTObject::IEvalContext{
// public:
//	/**
//	 * If true, the node transform and worldspace modifiers should be applied to the object.
//	 */
//	virtual bool want_worldspace_particles() const = 0;
//
//	/**
//	 * If true, the node's material should be applied to the object.
//	 */
//	virtual bool want_material_applied() const = 0;
//
//	/**
//	 * By supplying a Modifier and ModContext we can evaluate only a portion of the modifier stack up to, BUT NOT
//INCLUDING, the specified modifier/modcontext.
//	 */
//	virtual std::pair<Modifier*,ModContext*> get_eval_endpoint() const = 0;
//};
