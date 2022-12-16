# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
cmake_minimum_required( VERSION 3.20 FATAL_ERROR )

project( KrakatoaMXSDK )

find_package( thinkboxcmlibrary REQUIRED )
include( PrecompiledHeader )
include( ThinkboxCMLibrary )

set( SUPPORTED_MAX_VERSIONS 2022 2023 )

option( MAX_VERSION "The version of the 3ds Max SDK to build the library against." 2022 )

if( NOT MAX_VERSION IN_LIST SUPPORTED_MAX_VERSIONS )
  message( FATAL_ERROR "ERROR: Cannot build for unsupported 3ds Max version ${MAX_VERSION}" )
endif()

add_library( krakatoamxsdk STATIC )

set_property( TARGET krakatoamxsdk PROPERTY CXX_STANDARD 17 )

target_include_directories( krakatoamxsdk PUBLIC
	$<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}>
	$<INSTALL_INTERFACE:include>
)
 
file( GLOB_RECURSE H_FILES RELATIVE ${CMAKE_CURRENT_SOURCE_DIR}
        "krakatoa/*.h"
        "krakatoa/*.hpp"
)

file( GLOB_RECURSE CXX_FILES ${CMAKE_CURRENT_SOURCE}
    "src/*.cpp"
)

target_sources( krakatoamxsdk PRIVATE
    stdafx.cpp
    stdafx.h
    ${H_FILES}
    ${CXX_FILES}
)

# The Conan version of Boost was built with this, and it changes the library names.
# As a result, we need to set this to tell Boost to look for the right libraries to
# link against.
target_compile_definitions( krakatoamxsdk PUBLIC BOOST_AUTO_LINK_SYSTEM )

add_precompiled_header( krakatoamxsdk stdafx.h SOURCE_CXX stdafx.cpp )

find_package( thinkboxlibrary REQUIRED )
find_package( thinkboxmxlibrary REQUIRED )
find_package( Boost REQUIRED )
find_package( TBB REQUIRED )
find_package( tinyxml2 REQUIRED )
find_package( OpenEXR REQUIRED )
find_package( maxsdk REQUIRED )

target_include_directories( krakatoamxsdk PUBLIC ${thinkboxlibrary_INCLUDE_DIRS} )
target_include_directories( krakatoamxsdk PUBLIC ${thinkboxmxlibrary_INCLUDE_DIRS} )
target_include_directories( krakatoamxsdk PUBLIC ${Boost_INCLUDE_DIRS} )
target_include_directories( krakatoamxsdk PUBLIC ${TBB_INCLUDE_DIRS} )
target_include_directories( krakatoamxsdk PUBLIC ${tinyxml2_INCLUDE_DIRS} )
target_include_directories( krakatoamxsdk PUBLIC ${OpenEXR_INCLUDE_DIRS} )
target_include_directories( krakatoamxsdk PUBLIC ${maxsdk_INCLUDE_DIRS} )

target_link_libraries( krakatoamxsdk INTERFACE thinkboxlibrary::thinkboxlibrary )
target_link_libraries( krakatoamxsdk INTERFACE thinkboxmxlibrary::thinkboxmxlibrary )
target_link_libraries( krakatoamxsdk INTERFACE Boost::Boost )
target_link_libraries( krakatoamxsdk INTERFACE TBB::tbb )
target_link_libraries( krakatoamxsdk INTERFACE tinyxml2::tinyxml2 )
target_link_libraries( krakatoamxsdk INTERFACE OpenEXR::OpenEXR )
target_link_libraries( krakatoamxsdk INTERFACE maxsdk::maxsdk )

frantic_common_platform_setup( krakatoamxsdk )
frantic_default_source_groups( krakatoamxsdk HEADERDIR krakatoa SOURCEDIR src )

# Disable optimization for the RelWithDebInfo configuration on Windows.
# This allows breakpoints to be hit reliably when debugging in Visual Studio.
if( WIN32 )
	target_compile_options( krakatoamxsdk PRIVATE "$<$<CONFIG:Release>:/O2>$<$<CONFIG:RelWithDebInfo>:/Od>" )
endif()

install( DIRECTORY krakatoa
          DESTINATION include
          FILES_MATCHING PATTERN "*.h" PATTERN "*.hpp"
)
install( TARGETS krakatoamxsdk
          RUNTIME DESTINATION bin
          LIBRARY DESTINATION lib
          ARCHIVE DESTINATION lib
)
