// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0
#pragma once

namespace krakatoa {
namespace phoenix {

namespace param {
enum {

    // Source
    kTargetNode,
    kShowLiquid,
    kShowSplashes,
    kShowMist,
    kShowFoam,
    kShowWetMap,
    kSeedInSmoke,
    kSeedInSmokeMinimum,
    kSeedInTemperature,
    kSeedInTemperatureMinimum,

    // Seeding
    kSubdivideEnabled,
    kSubdivideCount,
    kJitterEnabled,
    kJitterWellDistributed,
    kMultiplePerRegionEnabled,
    kMultiplePerRegionCount,
    kRandomCount,
    kRandomSeed,

    // Viewport
    kIconSize,
    kViewportEnabled,
    kViewportDisableSubdivision,
    kViewportUsePercentage,
    kViewportPercentage,
    kViewportUseLimit,
    kViewportLimit

};
}

} // namespace phoenix
} // namespace krakatoa
