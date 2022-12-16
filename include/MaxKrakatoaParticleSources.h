// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0
#pragma once

#pragma warning( push )
#pragma warning( disable : 4702 )
#include <bitset>
#include <map>
#include <set>
#pragma warning( pop )

#include "MaxKrakatoaRenderGlobalContext.h"

#include <frantic/channels/channel_map.hpp>
#include <frantic/max3d/particles/particle_flow_access.hpp>
#include <frantic/max3d/shaders/map_query.hpp>
#include <frantic/particles/streams/particle_istream.hpp>

// using frantic::particles::streams::particle_istream;
// using frantic::channels::channel_map;

/**
 * Defines a class using the pimpl idiom that holds the neccessary information to produce a particle stream from a given
 * INode at runtime.
 */
class KrakatoaParticleSource {
  public:
    class KrakatoaParticleSourceImpl {
      protected:
        INode* m_pNode;
        KrakatoaParticleSourceImpl( INode* pNode )
            : m_pNode( pNode ) {}

        friend class KrakatoaParticleSource;

      public:
        virtual void AssertNotLoadingFrom( const frantic::tstring& /*file*/ ) const {}
        virtual boost::shared_ptr<frantic::particles::streams::particle_istream>
        GetParticleStream( MaxKrakatoaRenderGlobalContext* globContext ) const = 0;
    };

  private:
    boost::shared_ptr<KrakatoaParticleSourceImpl> m_impl;

  public:
    KrakatoaParticleSource( KrakatoaParticleSourceImpl* impl )
        : m_impl( impl ) {}

    INode* GetNode() { return m_impl->m_pNode; }

    boost::shared_ptr<frantic::particles::streams::particle_istream>
    GetParticleStream( MaxKrakatoaRenderGlobalContext* globContext ) const {
        return m_impl->GetParticleStream( globContext );
    }

    void AssertNotLoadingFrom( const frantic::tstring& file ) { m_impl->AssertNotLoadingFrom( file ); }
};

/**
 * Defines a class which can produce KrakatoaParticleSources from a given node. It is designed so that a given node may
 * produce multiple sources. (ie. a PFlow system w/ multiple render events, Thinking Particles groups, etc.)
 */
class KrakatoaParticleSourceFactory {
  public:
    virtual bool Process( INode* pNode, TimeValue t, std::vector<KrakatoaParticleSource>& outSources ) const = 0;
};

class PFlowParticleSourceFactory : public KrakatoaParticleSourceFactory {
  private:
    class PFlowParticleSource;
    std::bitset<frantic::max3d::particles::kPFRender_type_num> m_enabledTypes;

  public:
    PFlowParticleSourceFactory( bool doNoneType = false, bool doBBoxType = false, bool doGeomType = true,
                                bool doPhantomType = false );
    bool Process( INode* pNode, TimeValue t, std::vector<KrakatoaParticleSource>& outSources ) const;
};

class GeometryParticleSourceFactory : public KrakatoaParticleSourceFactory {
  private:
    class GeometryParticleSource;
    bool m_enabled;

  public:
    GeometryParticleSourceFactory( bool enabled )
        : m_enabled( enabled ) {}
    bool Process( INode* pNode, TimeValue t, std::vector<KrakatoaParticleSource>& outSources ) const;
};

class LegacyParticleSourceFactory : public KrakatoaParticleSourceFactory {
  private:
    class LegacyParticleSource;
    bool m_enabled;

  public:
    LegacyParticleSourceFactory( bool enabled )
        : m_enabled( enabled ) {}
    bool Process( INode* pNode, TimeValue t, std::vector<KrakatoaParticleSource>& outSources ) const;
};

class ThinkingParticleSourceFactory : public KrakatoaParticleSourceFactory {
  private:
    class ThinkingParticleSource;

    bool m_enabled;
    void ( *get_tp_groups )( INode*, std::vector<ReferenceTarget*>& );

  public:
    ThinkingParticleSourceFactory( bool enabled );
    bool Process( INode* pNode, TimeValue t, std::vector<KrakatoaParticleSource>& outSources ) const;
};

#if defined( FUMEFX_SDK_AVAILABLE )
class FumeFXParticleSourceFactory : public KrakatoaParticleSourceFactory {
  private:
    class FumeFXParticleSource;

    bool m_enabled;

  public:
    FumeFXParticleSourceFactory( bool enabled );
    bool Process( INode* pNode, TimeValue t, std::vector<KrakatoaParticleSource>& outSources ) const;
};
#endif

#if defined( PHOENIX_SDK_AVAILABLE )
class PhoenixParticleSourceFactory : public KrakatoaParticleSourceFactory {
  private:
    class PhoenixParticleSource;

    bool m_enabled;

  public:
    PhoenixParticleSourceFactory( bool enabled );
    bool Process( INode* /*pNode*/, std::vector<KrakatoaParticleSource>& /*outSources*/ ) const { return false; }
    bool Process( INode* pNode, TimeValue t, std::vector<KrakatoaParticleSource>& outSources ) const;
};
#endif

class PRTLoaderParticleSourceFactory : public KrakatoaParticleSourceFactory {
  private:
    class PRTLoaderParticleSource;

    bool m_enabled;

  public:
    PRTLoaderParticleSourceFactory( bool enabled )
        : m_enabled( enabled ) {}
    bool Process( INode* pNode, TimeValue t, std::vector<KrakatoaParticleSource>& outSources ) const;
};

class PRTObjectParticleSourceFactory : public KrakatoaParticleSourceFactory {
  private:
    class PRTObjectParticleSource;

    bool m_enabled;
    Class_ID m_classID;

  public:
    // @note Set sourceClassID to Class_ID(0,0) if you want all PRT objects
    PRTObjectParticleSourceFactory( bool enabled, Class_ID sourceClassID = Class_ID( 0, 0 ) )
        : m_enabled( enabled )
        , m_classID( sourceClassID ) {}
    bool Process( INode* pNode, TimeValue t, std::vector<KrakatoaParticleSource>& outSources ) const;
};

class MaxKrakatoa; // Fwd decl.

/**
 * Will generate a list of factory object that create Krakatoa particle sources. Will optionally use the supplied
 * Krakatoa instance to determine which factories are enabled. If 'pKrakatoa' is NULL, all factories are enabled.
 * @param[out] outFactories The created factories are stored here.
 * @param pKrakatoa Optional. If provided, its settings are used to enable/disable the factories. If NULL, all factories
 * are enabled.
 */
void create_particle_factories( std::vector<boost::shared_ptr<KrakatoaParticleSourceFactory>>& outFactories,
                                MaxKrakatoa* pKrakatoa = NULL );

/**
 * Function that will process all nodes in a scene, collecting KrakatoaParticleSource objects by using
 * a supplied collection of KrakatoaParticleSourceFactory objects.
 */
void collect_particle_objects( INode* sceneRoot, bool hideFrozen, TimeValue t,
                               std::vector<KrakatoaParticleSource>& outSources,
                               const std::vector<boost::shared_ptr<KrakatoaParticleSourceFactory>>& factories,
                               std::set<INode*> geomNodes, std::set<INode*> doneNodes );

/**
 * Extract particle groups from a PFlow node.
 */
void extract_connected_particle_groups( INode* node, std::set<INode*>& groups );