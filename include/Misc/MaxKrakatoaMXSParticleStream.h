// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0
#pragma once

#include <frantic/max3d/fnpublish/StandaloneInterface.hpp>

#include <frantic/particles/streams/particle_istream.hpp>
#include <frantic/particles/streams/particle_ostream.hpp>

#include <boost/shared_ptr.hpp>

class KrakatoaParticleOStream : public frantic::max3d::fnpublish::StandaloneInterface<KrakatoaParticleOStream> {
  public:
    KrakatoaParticleOStream( const frantic::tstring& path, const frantic::channels::channel_map& outMap );

    void close();

    void write_particle( Value* pParticleValue );

  private:
    virtual ThisInterfaceDesc* GetDesc();

  private:
    boost::shared_ptr<frantic::particles::streams::particle_ostream> m_pImpl;

    // Store a function for each channel that can convert from a MAXScript Value* into the appropriate channel type.
    std::vector<void ( * )( void*, Value*, std::size_t )> m_writeFunctions;

    bool m_isOpen;
};

class KrakatoaParticleIStream : public frantic::max3d::fnpublish::StandaloneInterface<KrakatoaParticleIStream> {
  public:
    KrakatoaParticleIStream( frantic::particles::particle_istream_ptr pStream );

    boost::int64_t get_count();

    TYPE_STRING_TAB_BV_TYPE get_channels();

    void close();

    void skip_particles( int numParticlesToSkip );

    Value* read_particle();

  private:
    virtual ThisInterfaceDesc* GetDesc();

  private:
    boost::shared_ptr<frantic::particles::streams::particle_istream> m_pImpl;

    // Store a function for each channel that can convert from a MAXScript Value* into the appropriate channel type.
    std::vector<Value* (*)( const void*, std::size_t )> m_readFunctions;

    // Provide persistent storage for the strings returned by get_channels() since Max doesn't bother to manage the
    // memory of object contained in Tab<> objects.
    std::vector<MSTR> m_channelStrings;

    bool m_isOpen;
};
