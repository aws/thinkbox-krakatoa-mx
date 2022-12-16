// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0
#include "stdafx.h"

#include "resource.h"

#include "KrakatoaGUIResources.hpp"

#include <frantic/max3d/maxscript/maxscript.hpp>

extern HINSTANCE hInstance;

KrakatoaGUIResources::KrakatoaGUIResources()
    : m_loadedIcons( false )
    , m_himlIcons( 0 ) {}

KrakatoaGUIResources::~KrakatoaGUIResources() {
    if( m_himlIcons ) {
        ImageList_Destroy( m_himlIcons );
        m_himlIcons = 0;
    }
}

void KrakatoaGUIResources::load_icons() {
    if( !m_loadedIcons ) {
        m_himlIcons = 0;

        HBITMAP hbmKrakatoaGui = (HBITMAP)LoadImage( hInstance, MAKEINTRESOURCE( IDB_KRAKATOA_GUI ), IMAGE_BITMAP, 512,
                                                     16, LR_DEFAULTCOLOR );

        if( hbmKrakatoaGui ) {
            m_himlIcons = ImageList_Create( 16, 16, ILC_COLOR24 | ILC_MASK, 0, 32 );

            if( m_himlIcons ) {
                int err = ImageList_AddMasked( m_himlIcons, hbmKrakatoaGui, RGB( 0xff, 0xff, 0xff ) );
                if( err == -1 ) {
                    ImageList_Destroy( m_himlIcons );
                    m_himlIcons = 0;
                }
            }

            DeleteObject( hbmKrakatoaGui );
        }

        m_loadedIcons = true;
    }
}

KrakatoaGUIResources& KrakatoaGUIResources::get_instance() {
    static KrakatoaGUIResources frostGuiResources;
    return frostGuiResources;
}

void KrakatoaGUIResources::apply_custbutton_fast_forward_icon( HWND hwnd ) {
    load_icons();
    if( hwnd && m_himlIcons ) {
        ICustButton* button = GetICustButton( hwnd );
        if( button ) {
            button->SetImage( m_himlIcons, 0, 0, 1, 1, 16, 16 );
            ReleaseICustButton( button );
        }
    }
}
void KrakatoaGUIResources::apply_custbutton_x_icon( HWND hwnd ) {
    load_icons();
    if( hwnd && m_himlIcons ) {
        ICustButton* button = GetICustButton( hwnd );
        if( button ) {
            button->SetImage( m_himlIcons, 13, 13, 18, 18, 16, 16 );
            ReleaseICustButton( button );
        }
    }
}

void KrakatoaGUIResources::apply_custbutton_down_arrow_icon( HWND hwnd ) {
    load_icons();
    if( hwnd && m_himlIcons ) {
        ICustButton* button = GetICustButton( hwnd );
        if( button ) {
            button->SetImage( m_himlIcons, 14, 14, 16, 16, 16, 16 );
            ReleaseICustButton( button );
        }
    }
}

void KrakatoaGUIResources::apply_custbutton_up_arrow_icon( HWND hwnd ) {
    load_icons();
    if( hwnd && m_himlIcons ) {
        ICustButton* button = GetICustButton( hwnd );
        if( button ) {
            button->SetImage( m_himlIcons, 15, 15, 17, 17, 16, 16 );
            ReleaseICustButton( button );
        }
    }
}

void KrakatoaGUIResources::apply_custbutton_right_arrow_icon( HWND hwnd ) {
    load_icons();
    if( hwnd && m_himlIcons ) {
        ICustButton* button = GetICustButton( hwnd );
        if( button ) {
            button->SetImage( m_himlIcons, 5, 5, 7, 7, 16, 16 );
            ReleaseICustButton( button );
        }
    }
}

void KrakatoaGUIResources::apply_custbutton_left_arrow_icon( HWND hwnd ) {
    load_icons();
    if( hwnd && m_himlIcons ) {
        ICustButton* button = GetICustButton( hwnd );
        if( button ) {
            button->SetImage( m_himlIcons, 6, 6, 8, 8, 16, 16 );
            ReleaseICustButton( button );
        }
    }
}

KrakatoaGUIResources* GetKrakatoaGuiResources() { return &KrakatoaGUIResources::get_instance(); }

void CustButton_SetRightClickNotify( HWND hwndButton, bool enable ) {
    if( hwndButton ) {
        ICustButton* custButton = GetICustButton( hwndButton );
        if( custButton ) {
            custButton->SetRightClickNotify( enable );
            ReleaseICustButton( custButton );
        }
    }
}

void CustButton_SetTooltip( HWND hwndButton, const TCHAR* tooltip, bool enable ) {
    if( hwndButton ) {
        ICustButton* custButton = GetICustButton( hwndButton );
        if( custButton ) {
            custButton->SetTooltip( enable, const_cast<TCHAR*>( tooltip ) );
            ReleaseICustButton( custButton );
        }
    }
}