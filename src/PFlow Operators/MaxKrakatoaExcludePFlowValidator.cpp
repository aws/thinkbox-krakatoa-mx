// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0
#include "stdafx.h"

#include <PFlow Operators/MaxKrakatoaExcludePFlowValidator.hpp>

#include <boost/assign.hpp>

BOOL detail::prtsource_custom_validator_function::Validate( PB2Value& v ) {
    INode* nodeObj = dynamic_cast<INode*>( v.r );
    if( !nodeObj ) {
        return TRUE;
    }

    const TimeValue t = GetCOREInterface()->GetTime();

    MaxKrakatoaPRTSourceObject* source = MaxKrakatoaPRTSourceObject::GetMaxKrakatoaPRTSource( nodeObj, t );
    if( !source ) {
        return TRUE;
    }

    frantic::max3d::particles::particle_system_type type = source->GetSourceType( t );
    return type != frantic::max3d::particles::kParticleTypeParticleGroup &&
           type != frantic::max3d::particles::kParticleTypeParticleObjectExt;
}

static detail::validator_t s_validator =
    detail::validator_t( boost::assign::list_of( frantic::max3d::particles::kParticleTypeParticleGroup )(
                             frantic::max3d::particles::kParticleTypeParticleObjectExt )
                             .convert_to_container<std::vector<frantic::max3d::particles::particle_system_type>>(),
                         true );

detail::validator_t* GetMaxKrakatoaExcludePFlowValidator() { return &s_validator; }

BOOL CheckForBadPRTSourceReference( INode* target, IParamBlock2* selfParams, int nodeParamID,
                                    frantic::tstring& operatorName ) {
    MaxKrakatoaPRTSourceObject* prtSource =
        MaxKrakatoaPRTSourceObject::GetMaxKrakatoaPRTSource( target, GetCOREInterface()->GetTime() );
    if( prtSource ) {
        frantic::max3d::particles::particle_system_type type =
            prtSource->GetSourceType( GetCOREInterface()->GetTime() );
        if( type == frantic::max3d::particles::kParticleTypeParticleGroup ||
            type == frantic::max3d::particles::kParticleTypeParticleObjectExt ) {
            selfParams->SetValue( nodeParamID, 0, (INode*)NULL );
            static const frantic::tstring NO_ID_ERROR_HEADER =
                frantic::tstring( _T( "Krakatoa " ) ) + operatorName + frantic::tstring( _T( " WARNING" ) );
            static const frantic::tstring NO_ID_ERROR_MSG =
                frantic::tstring( _T( "WARNING: " ) ) + operatorName +
                frantic::tstring(
                    _T( " cannot reference a PRTSource which references a Particle Flow Event.\nThe reference to the PRTSource has been removed." ) );

            LogSys* log = GetCOREInterface()->Log();
            if( log )
                log->LogEntry( SYSLOG_WARN, DISPLAY_DIALOG, const_cast<MCHAR*>( NO_ID_ERROR_HEADER.c_str() ),
                               const_cast<MCHAR*>( NO_ID_ERROR_MSG.c_str() ) );
            return TRUE;
        }
    }

    return FALSE;
}