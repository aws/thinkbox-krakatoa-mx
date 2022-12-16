// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0
#pragma once

#include <iparamm2.h>

#include <frantic/max3d/particles/particle_system_validator.hpp>

#include "../Objects/MaxKrakatoaPRTSource.hpp"

/**
 * A PBValidator which disallows other PFlow systems, or PRTSource which recursively have a PFlow system as their
 * source.
 */

namespace detail {

struct prtsource_custom_validator_function {
    static BOOL Validate( PB2Value& v );
};

typedef frantic::max3d::particles::list_and_particle_system_validator<detail::prtsource_custom_validator_function>
    validator_t;

} // namespace detail

detail::validator_t* GetMaxKrakatoaExcludePFlowValidator();

BOOL CheckForBadPRTSourceReference( INode* target, IParamBlock2* selfParams, int nodeParamID,
                                    frantic::tstring& operatorName );