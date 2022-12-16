// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0
#pragma once

#include <frantic/max3d/particles/IMaxKrakatoaPRTObject.hpp>
#include <frantic/particles/streams/particle_istream.hpp>

#define MagmaModifier_INTERFACE Interface_ID( 0x724864a0, 0x6f785080 )

class IMagmaModifier : public FPMixinInterface {
  public:
    virtual ~IMagmaModifier() {}

    // From FPInterface
    virtual FPInterfaceDesc* GetDesc() { return this->GetDescByID( MagmaModifier_INTERFACE ); }

    virtual bool GetLastError( TYPE_TSTR_BR_TYPE outMessage, TYPE_INT_BR_TYPE outMagmaID ) const = 0;

    virtual IObject* EvaluateDebug( INode* node, int modIndex, TimeValue t = TIME_NegInfinity ) = 0;

  public:
    enum { kFnGetLastError, kFnEvaluateDebug };

#pragma warning( push )
#pragma warning( disable : 4238 4100 )
    BEGIN_FUNCTION_MAP
    FN_2( kFnGetLastError, TYPE_bool, GetLastError, TYPE_TSTR_BR, TYPE_INT_BR )
    FNT_2( kFnEvaluateDebug, TYPE_IOBJECT, EvaluateDebug, TYPE_INODE, TYPE_INDEX )
    END_FUNCTION_MAP
#pragma warning( pop )

  private:
    friend class MagmaModifier;
    friend class SpaceMagmaModifier;

    inline static void init_fpinterface_desc( FPInterfaceDesc& desc ) {
        desc.AppendFunction( kFnGetLastError, _T("GetLastError"), 0, TYPE_bool, 0, 2, _T("OutMessage"), 0, TYPE_TSTR_BR,
                             f_inOut, FPP_OUT_PARAM, f_keyArgDefault, NULL, _T("OutNodeID"), 0, TYPE_INT_BR, f_inOut,
                             FPP_OUT_PARAM, f_keyArgDefault, NULL, p_end );

        desc.AppendFunction( kFnEvaluateDebug, _T("EvaluateDebug"), 0, TYPE_IOBJECT, 0, 2, _T("Node"), 0, TYPE_INODE,
                             _T("ModIndex"), 0, TYPE_INDEX, p_end );
    }
};
