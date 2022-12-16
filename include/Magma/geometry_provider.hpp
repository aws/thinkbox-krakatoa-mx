// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0
#pragma once

#include <boost/shared_ptr.hpp>

#include <frantic/geometry/trimesh3.hpp>
#include <frantic/geometry/trimesh3_kdtree.hpp>

namespace magma {

class geometry_provider {
  public:
    typedef boost::shared_ptr<geometry_provider> ptr_type;

    typedef frantic::geometry::trimesh3 mesh_type;
    typedef frantic::geometry::trimesh3_kdtree kdtree_type;

    typedef boost::shared_ptr<mesh_type> mesh_ptr_type;
    typedef boost::shared_ptr<kdtree_type> kdtree_ptr_type;

    typedef std::pair<mesh_ptr_type, kdtree_ptr_type> value_type;

  public:
    virtual ~geometry_provider() {}

    virtual void clear() = 0;

    virtual bool has_geometry( const std::string& name ) = 0;

    virtual value_type& get_geometry( const std::string& name ) = 0;

    virtual void set_geometry( const std::string& name, mesh_ptr_type pMesh ) = 0;
};

typedef geometry_provider::ptr_type geometry_provider_ptr;

} // namespace magma
