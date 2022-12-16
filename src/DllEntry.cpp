// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0

#include "stdafx.h"

#include "resource.h"

#include <tbb/task_scheduler_init.h>

extern ClassDesc2* GetMaxKrakatoaDesc();
extern ClassDesc2* GetMaxKrakatoaPRTLoaderDesc();
// extern ClassDesc2* GetMaxKrakatoaNodeMonitorDesc();
extern ClassDesc2* GetKrakatoaPFOptionsDesc();
extern ClassDesc2* GetKrakatoaPFPRTLoaderBirthDesc();
extern ClassDesc2* GetKrakatoaPFPRTLoaderUpdateDesc();
extern ClassDesc2* GetKrakatoaPFFileIDTestDesc();
extern ClassDesc2* GetKrakatoaPFGeometryTestDesc();
extern ClassDesc2* GetKrakatoaPFCollisionTestDesc();
extern ClassDesc2* GetKrakatoaPFGeometryLookupDesc();
extern ClassDesc2* GetKrakatoaSkinWrapClassDesc();
extern ClassDesc2* GetMaxKrakatoaMaterialDesc();
extern ClassDesc2* GetMaxKrakatoaVolumeObjectDesc();
extern ClassDesc2* GetMaxKrakatoaHairObjectDesc();
extern ClassDesc2* GetMaxKrakatoaShadowGeneratorDesc();
extern ClassDesc2* GetKrakatoaMagmaHolderDesc();
#if defined( FUMEFX_SDK_AVAILABLE )
extern ClassDesc2* GetMaxKrakatoaFumeFXObjectDesc();
#endif
#if defined( PHOENIX_SDK_AVAILABLE )
extern ClassDesc2* GetMaxKrakatoaPhoenixObjectDesc();
#endif
extern ClassDesc2* GetMaxKrakatoaPRTMakerDesc();
extern ClassDesc2* GetMaxKrakatoaPRTClonerOSModDesc();
extern ClassDesc2* GetMaxKrakatoaPRTClonerWSModDesc();
extern ClassDesc2* GetMaxKrakatoaPRTSpaceDeleteDesc();
extern ClassDesc2* GetMakerControllerDesc();

extern ClassDesc2* GetMaxKrakatoaDiffuseRenderElementDesc();
extern ClassDesc2* GetMaxKrakatoaSpecularRenderElementDesc();
extern ClassDesc2* GetMaxKrakatoaEmissionRenderElementDesc();
extern ClassDesc2* GetMaxKrakatoaZDepthRenderElementDesc();
extern ClassDesc2* GetMaxKrakatoaVelocityRenderElementDesc();
extern ClassDesc2* GetMaxKrakatoaNormalRenderElementDesc();
extern ClassDesc2* GetMaxKrakatoaTangentRenderElementDesc();
extern ClassDesc2* GetMaxKrakatoaMagmaRenderElementDesc();
extern ClassDesc2* GetMaxKrakatoaMagma2RenderElementDesc();
extern ClassDesc2* GetMaxKrakatoaMatteZDepthRenderElementDesc();
extern ClassDesc2* GetMaxKrakatoaLightRenderElementDesc();
extern ClassDesc2* GetMaxKrakatoaOccludedLayerRenderElementDesc();
extern ClassDesc2* GetMaxKrakatoaSpecular2RenderElementDesc();
extern ClassDesc2* GetMaxKrakatoaGlintRenderElementDesc();
extern ClassDesc2* GetMaxKrakatoaPRTSourceObjectDesc();
extern ClassDesc2* GetMaxKrakatoaAtmosphericDesc();
extern ClassDesc2* GetMagmaModifierDesc();
extern ClassDesc2* GetSpaceMagmaModifierDesc();
extern ClassDesc2* GetMaxKrakatoaGlobalOverrideDummyDesc();
extern ClassDesc2* GetMagmaEvalTexmapNodeDesc();
extern ClassDesc2* GetMaxKrakatoaPRTSurfaceDesc();

namespace frantic {
namespace magma {
namespace nodes {
namespace max3d {
extern void GetClassDescs( std::vector<ClassDesc*>& outClassDescs );
}
} // namespace nodes
} // namespace magma
} // namespace frantic

namespace ember {
namespace max3d {
extern ClassDesc2* GetFieldNodeDesc();
}
} // namespace ember

extern void InitializeKrakatoaLogging();
extern void InitializeMaxKrakatoaDoneMxsStartup();

HINSTANCE hInstance;
int controlsInit = FALSE;

inline static std::vector<ClassDesc*>& GetClassDescs() {
    static std::vector<ClassDesc*> theDescs;
    return theDescs;
}

// This function is called by Windows when the DLL is loaded.  This
// function may also be called many times during time critical operations
// like rendering.  Therefore developers need to be careful what they
// do inside this function.  In the code below, note how after the DLL is
// loaded the first time only a few statements are executed.
BOOL WINAPI DllMain( HINSTANCE hinstDLL, ULONG fdwReason, LPVOID /*lpvReserved*/ ) {
    if( fdwReason == DLL_PROCESS_ATTACH ) {
        hInstance = hinstDLL; // Hang on to this DLL's instance handle.

        if( !controlsInit ) {
            controlsInit = TRUE;

            // Renderer
            GetClassDescs().push_back( GetMaxKrakatoaDesc() );

            // PRT Objects
            GetClassDescs().push_back( GetMaxKrakatoaPRTLoaderDesc() );
            GetClassDescs().push_back( GetMaxKrakatoaVolumeObjectDesc() );
            GetClassDescs().push_back( GetMaxKrakatoaPRTSurfaceDesc() );
            GetClassDescs().push_back( GetMaxKrakatoaHairObjectDesc() );
            GetClassDescs().push_back( GetMaxKrakatoaPRTMakerDesc() );
            GetClassDescs().push_back( GetMakerControllerDesc() );
            GetClassDescs().push_back( GetMaxKrakatoaPRTSourceObjectDesc() );
#if defined( FUMEFX_SDK_AVAILABLE )
            GetClassDescs().push_back( GetMaxKrakatoaFumeFXObjectDesc() );
#endif
#if defined( PHONEIX_SDK_AVAILABLE )
            GetClassDescs().push_back( GetMaxKrakatoaPhoenixObjectDesc() );
#endif

            // Particle Flow
            // GetClassDescs().push_back( GetMaxKrakatoaNodeMonitorDesc() );
            GetClassDescs().push_back( GetKrakatoaPFOptionsDesc() );
            GetClassDescs().push_back( GetKrakatoaPFPRTLoaderBirthDesc() );
            GetClassDescs().push_back( GetKrakatoaPFPRTLoaderUpdateDesc() );
            GetClassDescs().push_back( GetKrakatoaPFFileIDTestDesc() );
            GetClassDescs().push_back( GetKrakatoaPFGeometryTestDesc() );
            GetClassDescs().push_back( GetKrakatoaPFCollisionTestDesc() );
            GetClassDescs().push_back( GetKrakatoaPFGeometryLookupDesc() );

            // Render elements
            GetClassDescs().push_back( GetMaxKrakatoaDiffuseRenderElementDesc() );
            GetClassDescs().push_back( GetMaxKrakatoaSpecularRenderElementDesc() );
            GetClassDescs().push_back( GetMaxKrakatoaEmissionRenderElementDesc() );
            GetClassDescs().push_back( GetMaxKrakatoaZDepthRenderElementDesc() );
            GetClassDescs().push_back( GetMaxKrakatoaVelocityRenderElementDesc() );
            GetClassDescs().push_back( GetMaxKrakatoaNormalRenderElementDesc() );
            GetClassDescs().push_back( GetMaxKrakatoaTangentRenderElementDesc() );
            GetClassDescs().push_back( GetMaxKrakatoaMagmaRenderElementDesc() );
            GetClassDescs().push_back( GetMaxKrakatoaMagma2RenderElementDesc() );
            GetClassDescs().push_back( GetMaxKrakatoaMatteZDepthRenderElementDesc() );
            GetClassDescs().push_back( GetMaxKrakatoaLightRenderElementDesc() );
            GetClassDescs().push_back( GetMaxKrakatoaOccludedLayerRenderElementDesc() );
            GetClassDescs().push_back( GetMaxKrakatoaSpecular2RenderElementDesc() );
            GetClassDescs().push_back( GetMaxKrakatoaGlintRenderElementDesc() );

            // Modifiers
            GetClassDescs().push_back( GetMaxKrakatoaPRTClonerOSModDesc() );
            GetClassDescs().push_back( GetMaxKrakatoaPRTClonerWSModDesc() );
            GetClassDescs().push_back( GetMaxKrakatoaPRTSpaceDeleteDesc() );

            // Magma
            GetClassDescs().push_back( GetKrakatoaMagmaHolderDesc() );
            GetClassDescs().push_back( GetMagmaModifierDesc() );
            GetClassDescs().push_back( GetSpaceMagmaModifierDesc() );
            frantic::magma::nodes::max3d::GetClassDescs( GetClassDescs() );
            GetClassDescs().push_back( GetMagmaEvalTexmapNodeDesc() );
            GetClassDescs().push_back( ember::max3d::GetFieldNodeDesc() );

            // Misc
            GetClassDescs().push_back( GetKrakatoaSkinWrapClassDesc() );
            GetClassDescs().push_back( GetMaxKrakatoaMaterialDesc() );
            GetClassDescs().push_back( GetMaxKrakatoaShadowGeneratorDesc() );
            GetClassDescs().push_back( GetMaxKrakatoaAtmosphericDesc() );
            GetClassDescs().push_back( GetMaxKrakatoaGlobalOverrideDummyDesc() );
        }
    }

    return ( TRUE );
}

// This global tbb::task_scheduler_init will defer thread construction since it is a bad idea to
// to do this complicated of work in DLLMain. It was causing a hang on close too.
static tbb::task_scheduler_init g_tbbScheduler( tbb::task_scheduler_init::deferred );

extern "C" {
__declspec( dllexport ) int LibInitialize() {
    // IMPORTANT! This is in LibInitialize since g_tbbScheduler was created with deferred
    //  initialization.
    // NOTE: if the number of threads TBB is initialized with changes from the default,
    // the code in MaxKrakatoa.cpp which tells Krakatoa what the thread pool size is must also be updated
    // see: krakRenderer->set_rendering_thread_limit right before the call to actually do the rendering
    g_tbbScheduler.initialize();
    InitializeKrakatoaLogging();
    InitializeMaxKrakatoaDoneMxsStartup();

    return TRUE;
}

__declspec( dllexport ) int LibShutdown() {
    // IMPORTANT! This is in LibShutdown since the destructor on g_tbbScheduler was hanging
    //  under certain conditions.
    g_tbbScheduler.terminate();
    return TRUE;
}

// This function returns a string that describes the DLL and where the user
// could purchase the DLL if they don't have it.
__declspec( dllexport ) const TCHAR* LibDescription() { return GetString( IDS_LIBDESCRIPTION ); }

// This function returns the number of plug-in classes this DLL
// TODO: Must change this number when adding a new class
__declspec( dllexport ) int LibNumberClasses() { return (int)GetClassDescs().size(); }

// This function returns the number of plug-in classes this DLL
__declspec( dllexport ) ClassDesc* LibClassDesc( int i ) { return GetClassDescs()[i]; }

// This function returns a pre-defined constant indicating the version of
// the system under which it was compiled.  It is used to allow the system
// to catch obsolete DLLs.
__declspec( dllexport ) ULONG LibVersion() { return VERSION_3DSMAX; }

} // extern "C"

TCHAR* GetString( int id ) {
    static TCHAR buf[256];

    if( hInstance )
        return LoadString( hInstance, id, buf, sizeof( buf ) / sizeof( TCHAR ) ) ? buf : NULL;
    return NULL;
}
