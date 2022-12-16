// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0
#pragma once

class MaxKrakatoaParamDlg : public RendParamDlg {
  public:
    MaxKrakatoa* m_renderer;
    IRendParams* m_ir;
    HWND m_hPanel;
    bool m_isProgressDialog;
    HFONT m_hFont;

    MaxKrakatoaParamDlg( MaxKrakatoa* r, IRendParams* i, bool prog );
    ~MaxKrakatoaParamDlg();
    void AcceptParams();
    void RejectParams();
    void DeleteThis() { delete this; }
    void InitParamDialog( HWND hWnd );
    void InitProgDialog( HWND hWnd );
};
