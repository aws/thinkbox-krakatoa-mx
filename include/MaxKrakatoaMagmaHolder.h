// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0
#pragma once

#include <boost/shared_ptr.hpp>

#define KrakatoaMagmaHolder_NAME _T("MagmaHolder")
#define KrakatoaMagmaHolder_CLASS_ID Class_ID( 0x6e4e5356, 0x5f7045a )

namespace KrakatoaMagmaHolderParams {
enum {
    kMagmaFlow,
    kMagmaInternalFlow,
    kMagmaNote,
    kMagmaTrackID,
    kMagmaTextureMapSources,
    kMagmaCurrentPreset,
    kMagmaCurrentFolder,
    kMagmaAutoUpdate,
    kMagmaInteractiveMode,
    kMagmaAutomaticRenameOFF,
    kMagmaGeometryObjectsList,
    kMagmaNeedCAUpdate,
    kMagmaIsRenderElement,

    kMagmaLastErrorMessage,
    kMagmaLastErrorNode,

    kMagmaNodeMaxDataDEPRECATED, // MAX-specific data, stored as a sparse tab of sorted RefTargets of type
                                 // MagmaNodeMaxData
    kMagmaNodeMaxData
};
}

ReferenceTarget* CreateKrakatoaMagmaHolder();

namespace frantic {
namespace magma {
class magma_interface;
}
} // namespace frantic

boost::shared_ptr<frantic::magma::magma_interface> GetMagmaInterface( ReferenceTarget* magmaHolder );

Interval GetMagmaValidity( ReferenceTarget* magmaHolder, TimeValue t );
