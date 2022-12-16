// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0
#pragma once

// new standard particle channel "FileIDInteger"
#define PARTICLECHANNELFILEIDINTEGERR_INTERFACE Interface_ID( 0x25dc5240, 0x563a7348 )
#define PARTICLECHANNELFILEIDINTEGERW_INTERFACE Interface_ID( 0x25dc5240, 0x563a7349 )

#define GetParticleChannelFileIDIntegerRInterface( obj )                                                               \
    ( (IParticleChannelIntR*)obj->GetInterface( PARTICLECHANNELFILEIDINTEGERR_INTERFACE ) )
#define GetParticleChannelFileIDIntegerWInterface( obj )                                                               \
    ( (IParticleChannelIntW*)obj->GetInterface( PARTICLECHANNELFILEIDINTEGERW_INTERFACE ) )

typedef struct {
    int index;
    int id;
} idPair;
