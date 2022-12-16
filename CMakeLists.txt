# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
cmake_minimum_required( VERSION 3.20 FATAL_ERROR )

project( KrakatoaMX )

find_package( thinkboxcmlibrary REQUIRED )
include( PrecompiledHeader )
include( ThinkboxCMLibrary )

set( SUPPORTED_MAX_VERSIONS 2022 2023 )

option( MAX_VERSION "The version of the 3ds Max SDK to build the library against." 2022 )

if( NOT MAX_VERSION IN_LIST SUPPORTED_MAX_VERSIONS )
  message( FATAL_ERROR "ERROR: Cannot build for unsupported 3ds Max version ${MAX_VERSION}" )
endif()

add_library( krakatoamx SHARED )

set_property( TARGET krakatoamx PROPERTY CXX_STANDARD 14 )

set_target_properties( krakatoamx PROPERTIES OUTPUT_NAME "MaxKrakatoa" )
set_target_properties( krakatoamx PROPERTIES PREFIX "" )
set_target_properties( krakatoamx PROPERTIES SUFFIX ".dlr" )

target_include_directories( krakatoamx PUBLIC
                            $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}>
                            $<INSTALL_INTERFACE:include> )

target_include_directories( krakatoamx PUBLIC ${CMAKE_CURRENT_SOURCE_DIR}/include )

file( GLOB_RECURSE H_FILES RELATIVE ${CMAKE_CURRENT_SOURCE_DIR}
        "include/*.h"
        "include/*.hpp"
)

file( GLOB_RECURSE CXX_FILES ${CMAKE_CURRENT_SOURCE}
    "src/*.cpp"
)

target_sources( krakatoamx PRIVATE
    "MaxKrakatoa.rc"
    "KrakatoaMXVersion.rc"
    "resource.h"
    "stdafx.h"
    "stdafx.cpp"
    ${H_FILES}
    ${CXX_FILES}
)


# The Conan version of Boost was built with this, and it changes the library names.
# As a result, we need to set this to tell Boost to look for the right libraries to
# link against.
target_compile_definitions( krakatoamx PUBLIC BOOST_AUTO_LINK_SYSTEM )

find_package( thinkboxlibrary REQUIRED )
find_package( thinkboxmxlibrary REQUIRED )
find_package( krakatoa REQUIRED )
find_package( krakatoamxsdk REQUIRED )
find_package( magma REQUIRED )
find_package( magmamx REQUIRED )
# find_package( nodeview REQUIRED )
find_package( maxsdk REQUIRED )
find_package( libb2 REQUIRED )
find_package( Boost REQUIRED )
find_package( fmt REQUIRED )
find_package( OpenEXR REQUIRED )
find_package( ZLIB REQUIRED )
find_package( TBB REQUIRED )
find_package( tinyxml2 REQUIRED )
find_package( xxHash REQUIRED )
find_package( OpenImageIO REQUIRED )

target_include_directories( krakatoamx PUBLIC ${thinkboxlibrary_INCLUDE_DIRS} )
target_include_directories( krakatoamx PUBLIC ${maxsdk_INCLUDE_DIRS} )
target_include_directories( krakatoamx PUBLIC ${thinkboxmxlibrary_INCLUDE_DIRS} )
target_include_directories( krakatoamx PUBLIC ${krakatoa_INCLUDE_DIRS} )
target_include_directories( krakatoamx PUBLIC ${krakatoamxsdk_INCLUDE_DIRS} )
target_include_directories( krakatoamx PUBLIC ${magma_INCLUDE_DIRS} )
target_include_directories( krakatoamx PUBLIC ${magmamx_INCLUDE_DIRS} )
# target_include_directories( krakatoamx PUBLIC ${nodeview_INCLUDE_DIRS} )
target_include_directories( krakatoamx PUBLIC ${libb2_INCLUDE_DIRS} )
target_include_directories( krakatoamx PUBLIC ${Boost_INCLUDE_DIRS} )
target_include_directories( krakatoamx PUBLIC ${fmt_INCLUDE_DIRS} )
target_include_directories( krakatoamx PUBLIC ${OpenEXR_INCLUDE_DIRS} )
target_include_directories( krakatoamx PUBLIC ${ZLIB_INCLUDE_DIRS} )
target_include_directories( krakatoamx PUBLIC ${TBB_INCLUDE_DIRS} )
target_include_directories( krakatoamx PUBLIC ${tinyxml2_INCLUDE_DIRS} )
target_include_directories( krakatoamx PUBLIC ${xxHash_INCLUDE_DIRS} )
target_include_directories( krakatoamx PUBLIC ${OpenImageIO_INCLUDE_DIRS} )

target_link_libraries( krakatoamx PUBLIC thinkboxlibrary::thinkboxlibrary )
target_link_libraries( krakatoamx PUBLIC maxsdk::maxsdk )
target_link_libraries( krakatoamx PUBLIC thinkboxmxlibrary::thinkboxmxlibrary )
target_link_libraries( krakatoamx PUBLIC krakatoa::krakatoa )
target_link_libraries( krakatoamx PUBLIC krakatoamxsdk::krakatoamxsdk )
target_link_libraries( krakatoamx PUBLIC magma::magma )
target_link_libraries( krakatoamx PUBLIC magmamx::magmamx )
# target_link_libraries( krakatoamx PUBLIC nodeview::nodeview )
target_link_libraries( krakatoamx PUBLIC libb2::libb2 )
target_link_libraries( krakatoamx PUBLIC Boost::Boost )
target_link_libraries( krakatoamx PUBLIC fmt::fmt )
target_link_libraries( krakatoamx PUBLIC OpenEXR::OpenEXR )
target_link_libraries( krakatoamx PUBLIC ZLIB::ZLIB )
target_link_libraries( krakatoamx PUBLIC TBB::tbb )
target_link_libraries( krakatoamx PUBLIC tinyxml2::tinyxml2 )
target_link_libraries( krakatoamx PUBLIC xxHash::xxHash )
target_link_libraries( krakatoamx PUBLIC OpenImageIO::OpenImageIO )

add_precompiled_header( krakatoamx stdafx.h SOURCE_CXX stdafx.cpp )

frantic_common_platform_setup( krakatoamx )
frantic_default_source_groups( krakatoamx HEADERDIR include SOURCEDIR src )

# Disable optimization for the RelWithDebInfo configuration.
# This allows breakpoints to be hit reliably when debugging in Visual Studio.
target_compile_options( krakatoamx PRIVATE "$<$<CONFIG:Release>:/O2>$<$<CONFIG:RelWithDebInfo>:/Od>" )

install( TARGETS krakatoamx
          RUNTIME DESTINATION bin
          LIBRARY DESTINATION lib
          ARCHIVE DESTINATION lib
)
