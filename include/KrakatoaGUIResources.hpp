// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0
#pragma once

#include <CommCtrl.h>

class KrakatoaGUIResources {
    bool m_loadedIcons;
    HIMAGELIST m_himlIcons;

    KrakatoaGUIResources();
    ~KrakatoaGUIResources();

    void load_icons();

    KrakatoaGUIResources( const KrakatoaGUIResources& );
    KrakatoaGUIResources& operator=( const KrakatoaGUIResources& );

  public:
    static KrakatoaGUIResources& get_instance();

    void apply_custbutton_fast_forward_icon( HWND hwnd );
    void apply_custbutton_x_icon( HWND hwnd );
    void apply_custbutton_down_arrow_icon( HWND hwnd );
    void apply_custbutton_up_arrow_icon( HWND hwnd );
    void apply_custbutton_right_arrow_icon( HWND hwnd );
    void apply_custbutton_left_arrow_icon( HWND hwnd );
};

KrakatoaGUIResources* GetKrakatoaGuiResources();

void CustButton_SetRightClickNotify( HWND hwndButton, bool enable );

void CustButton_SetTooltip( HWND hwndButton, const TCHAR* tooltip, bool enable = true );
