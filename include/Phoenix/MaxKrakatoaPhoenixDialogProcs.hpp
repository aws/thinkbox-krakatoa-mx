// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0
#pragma once

#include <Phoenix/ParamIDs.hpp>

class PhoenixMainPanelDialogProc : public ParamMap2UserDlgProc {
    static PhoenixMainPanelDialogProc s_theDialogProc;

  public:
    static PhoenixMainPanelDialogProc* GetInstance() { return &s_theDialogProc; }

    virtual ~PhoenixMainPanelDialogProc() {}

    virtual void DeleteThis() {}

    /**
     * Handles the right click menu (also accessible by clicking the > button).
     */
    virtual INT_PTR DlgProc( TimeValue t, IParamMap2* map, HWND hWnd, UINT msg, WPARAM wParam, LPARAM lParam );

    virtual void Update( TimeValue t, Interval& valid, IParamMap2* pmap ) { valid = Interval( t, t ); }
};

class PhoenixViewportPanelDialogProc : public ParamMap2UserDlgProc {
    static PhoenixViewportPanelDialogProc s_theDialogProc;

  public:
    static PhoenixViewportPanelDialogProc* GetInstance() { return &s_theDialogProc; }

    virtual ~PhoenixViewportPanelDialogProc() {}

    virtual void DeleteThis() {}

    virtual INT_PTR DlgProc( TimeValue t, IParamMap2* map, HWND hWnd, UINT msg, WPARAM wParam, LPARAM lParam );
};
