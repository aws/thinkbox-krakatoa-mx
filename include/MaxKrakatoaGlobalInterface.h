// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0
#pragma once
#include <krakatoa/shaders.hpp>

#include <frantic/win32/log_window.hpp>

#include <frantic/max3d/fpwrapper/FPTimeValue.hpp>
#include <frantic/max3d/fpwrapper/iobject_wrapper.hpp>
#include <frantic/max3d/fpwrapper/max_typetraits.hpp>
#include <frantic/max3d/fpwrapper/static_wrapper.hpp>

#include <boost/cstdint.hpp>

// Exposes the MaxScript functions of Krakatoa
class ParticleRenderGlobalInterface
    : public frantic::max3d::fpwrapper::FFStaticInterface<ParticleRenderGlobalInterface, FP_CORE> {
  private:
    frantic::win32::log_window m_logWindow;
    M_STD_STRING m_logFile;
    bool m_bDoLogPopups;

  public:
    ParticleRenderGlobalInterface();

    //-------------------------------------
    // Logging functions
    //-------------------------------------
    void InitializeLogging();

    void LogError( const M_STD_STRING& msg );
    void LogWarning( const M_STD_STRING& msg );
    void LogProgress( const M_STD_STRING& msg );
    void LogStats( const M_STD_STRING& msg );
    void LogDebug( const M_STD_STRING& msg );

    void LogErrorInternal( const MCHAR* szMsg );
    void LogWarningInternal( const MCHAR* szMsg );
    void LogMessageInternal( const M_STD_STRING& msg );

    bool GetPopupLogWindowOnMessage();
    void SetPopupLogWindowOnMessage( bool shouldPopup );
    bool GetLogWindowVisible();
    void SetLogWindowVisible( bool visible );

    //-------------------------------------
    // Property functions
    //-------------------------------------
    void SetProperty( const M_STD_STRING& propName, Value* value );
    void AddProperty( const M_STD_STRING& propName, Value* value );
    Value* GetProperty( const M_STD_STRING& propName );
    bool HasProperty( const M_STD_STRING& propName );

    int GetIntProperty( const M_STD_STRING& propName );
    float GetFloatProperty( const M_STD_STRING& propName );
    bool GetBoolProperty( const M_STD_STRING& propName );

    //-------------------------------------
    // Renderer functions
    //-------------------------------------
    void InvalidateParticleCache();
    void InvalidateLightingCache();
    float GetCacheSize();
    M_STD_STRING GetParticleOutputFiles( FPTimeValue t );
    M_STD_STRING GetRenderOutputFiles( FPTimeValue t );
    // void SaveMatteObjectsToFileSequence( const M_STD_STRING& filename, Value * value, int startFrame, int endFrame );

    //-------------------------------------
    // Filename Manipulation
    //-------------------------------------
    M_STD_STRING ReplaceSequenceNumberWithHashes( const M_STD_STRING& file );
    M_STD_STRING ReplaceSequenceNumber( const M_STD_STRING& file, int frame );
    M_STD_STRING MakePartitionFilename( const M_STD_STRING& filename, int index, int count );
    std::vector<int> GetPartitionFromFilename( const M_STD_STRING& filename );
    M_STD_STRING ReplacePartitionInFilename( const M_STD_STRING& filename, int index );

    //-------------------------------------
    // Streams
    //-------------------------------------
    FPInterface* GetPRTObjectIStream( INode* pNode, bool applyTM, bool applyMtl, FPTimeValue t );
    FPInterface* CreateParticleOStream( const M_STD_STRING& path, const std::vector<M_STD_STRING>& channels );
    bool SaveParticleObjectsToFile( const std::vector<INode*>& nodes, const M_STD_STRING& filename,
                                    const std::vector<M_STD_STRING>& channels, FPTimeValue t );
    std::vector<M_STD_STRING> GetParticleObjectChannels( const std::vector<INode*>& nodes, FPTimeValue t );
    INT64 get_particle_count( INode* node, bool useRenderParticles, FPTimeValue t );
    void ParticleRenderGlobalInterface::generate_sticky_channels(
        const M_STD_STRING& inSequence, const M_STD_STRING& outSequence, const M_STD_STRING& inChannel,
        const M_STD_STRING& outChannel, const M_STD_STRING& idChannel, const float startFrame, const bool ignoreError,
        const bool overwriteChannel, const bool overwriteFile );

    //-------------------------------------
    // Misc functions
    //-------------------------------------
    M_STD_STRING GetVersion();
    M_STD_STRING GetKrakatoaHome();
    M_STD_STRING Blake2Hash( const M_STD_STRING& input );

#if defined( THINKING_PARTICLES_SDK_AVAILABLE )
    void EnableTPExpertMode();
#endif

    Value* get_file_particle_channels( const M_STD_STRING& file );
    Value* get_file_particle_count( const M_STD_STRING& file );
    Value* get_render_particle_channels();
    Value* get_cached_particle_channels();
    INT64 get_cached_particle_count();

    Value* get_file_particle_metadata( const M_STD_STRING& file );

    bool is_valid_channel_name( const M_STD_STRING& file );
    bool is_valid_particle_node( INode* node, FPTimeValue t );
    bool is_valid_matte_node( INode* node, FPTimeValue t );

    Value* debug_eval_kcm( INode* pNode, RefTargetHandle modifier, Value* testValues, FPTimeValue t );

    void set_max_debug_iterations( int maxIterations );
    int get_max_debug_iterations();

    void test( INode* node, FPTimeValue t );

    void test_particle_object_ext( Object* obj, const M_STD_STRING& command, const FPValue& param, FPTimeValue t );

    bool spherical_distortion( const M_STD_STRING& inputFile, const M_STD_STRING& outputFile, int outputWidth,
                               int outputHeight, int inputProjection, int outputProjection, int inputCubefaceMapping,
                               int outputCubefaceMapping );
};

ParticleRenderGlobalInterface* GetMaxKrakatoaInterface();
void InitializeKrakatoaLogging();
