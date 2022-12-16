// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0
// File pulled from FrostMX
#pragma once

#include "particle_group_filter_entry.hpp"

void show_edit_particle_groups_dialog( HINSTANCE hInstance, HWND hwnd, const frantic::tstring& particleSystemType,
                                       const frantic::tstring& groupTypePlural,
                                       std::vector<particle_group_filter_entry::ptr_type>& groups );
