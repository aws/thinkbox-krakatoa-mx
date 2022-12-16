// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0
#pragma once

// Disable unreachable code warning, and deprecated function warnings
#pragma warning( disable : 4702 4996 )

#pragma warning( push, 3 )
#pragma warning( disable : 4701 4267 4103 )
#include <boost/bind.hpp>
#include <boost/function.hpp>
#include <boost/fusion/tuple/make_tuple.hpp>
#include <boost/lexical_cast.hpp>
#include <boost/mpl/apply.hpp>
#include <boost/random.hpp>
#include <boost/regex.hpp>
#include <boost/thread.hpp>
#pragma warning( pop )

// Put all the standard C++ includes here.
// Because they never change, they should be in the precompiled header to optimize compile times.
#pragma warning( push )
#pragma warning( disable : 4267 ) // Bizarre that MS's standard headers have such warnings...
#include <algorithm>
#pragma warning( pop )
#include <cmath>
#include <map>
#include <set>
#include <sstream>
#include <string>
#include <vector>

#include <frantic/max3d/standard_max_includes.hpp>

#ifdef base_type
#undef base_type
#endif

TCHAR* GetString( int id );

#if MAX_VERSION_MAJOR >= 15
#define HANDLE_STD_EXCEPTION_MSG( e ) MSTR::FromACP( ( e ).what() ).data()
#else
#define HANDLE_STD_EXCEPTION_MSG( e ) const_cast<TCHAR*>( ( e ).what() )
#endif

inline bool IsNetworkRenderServer() {
    return GetCOREInterface()->IsNetworkRenderServer();
}
