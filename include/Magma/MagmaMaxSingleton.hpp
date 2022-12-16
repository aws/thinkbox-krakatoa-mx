// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0
#pragma once

#include <frantic/magma/magma_singleton.hpp>

class MagmaMaxSingleton : public frantic::magma::magma_singleton {
    // static MagmaMaxSingleton s_instance;

    MagmaMaxSingleton();

    virtual ~MagmaMaxSingleton() {}

  public:
    static MagmaMaxSingleton& get_instance();
};
