// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0
#pragma once

#include <imtl.h>

//#include <frantic/max3d/shaders/map_query.hpp>
#include <frantic/particles/streams/particle_istream.hpp>
#include <krakatoa/max3d/IPRTMaterial.hpp>

#include <krakatoa/scene_context.hpp>

#define MaxKrakatoaMaterial_CLASS_NAME "Krakatoa Material"
#define MaxKrakatoaMaterial_CLASS_ID Class_ID( 0x42385994, 0x6a7439ae )

inline bool is_krakatoa_material( Animatable* pAnim ) {
    return ( pAnim->ClassID() == MaxKrakatoaMaterial_CLASS_ID ) != FALSE;
}

class MaxKrakatoaMaterial : public Mtl, public krakatoa::max3d::IPRTMaterial {
    IParamBlock2* m_pblock;

  public:
    MaxKrakatoaMaterial();
    virtual ~MaxKrakatoaMaterial() {}

    /**
     * Will apply a decorator particle_istream that sets the "Color", "Absorption", "Emission" and "Density" values
     * of the stream based on the material's configuration.
     * @param pin The stream to decorate
     * @param sceneContext The context in which to evaluate TexMaps
     * @param pNode The node that the shading is being applied to
     * @return A particle_istream that reads from pin and modifies some of the channels.
     */
    virtual boost::shared_ptr<frantic::particles::streams::particle_istream>
    ApplyMaterial( boost::shared_ptr<frantic::particles::streams::particle_istream> pin, INode* pNode, TimeValue t,
                   Interval& inoutValidity, frantic::max3d::particles::IMaxKrakatoaPRTEvalContextPtr pEvalContext );

    bool AffectsScatterColor();

    // From Mtl
    virtual Color GetAmbient( int mtlNum = 0, BOOL backFace = FALSE );
    virtual Color GetDiffuse( int mtlNum = 0, BOOL backFace = FALSE );
    virtual Color GetSpecular( int mtlNum = 0, BOOL backFace = FALSE );
    virtual float GetShininess( int mtlNum = 0, BOOL backFace = FALSE );
    virtual float GetShinStr( int mtlNum = 0, BOOL backFace = FALSE );
    virtual float GetXParency( int mtlNum = 0, BOOL backFace = FALSE );

    virtual void SetAmbient( Color c, TimeValue t );
    virtual void SetDiffuse( Color c, TimeValue t );
    virtual void SetSpecular( Color c, TimeValue t );
    virtual void SetShininess( float v, TimeValue t );

    virtual void Shade( ShadeContext& sc );

    // From MtlBase
    virtual void Update( TimeValue t, Interval& valid );
    virtual void Reset();
    virtual Interval Validity( TimeValue t );
    virtual ParamDlg* CreateParamDlg( HWND hwMtlEdit, IMtlParams* imp );

    // From ISubMap
    virtual int NumSubTexmaps();
    virtual Texmap* GetSubTexmap( int i );
    virtual int MapSlotType( int i );
    virtual void SetSubTexmap( int i, Texmap* m );
    virtual int SubTexmapOn( int i );
#if MAX_VERSION_MAJOR >= 24
    virtual MSTR GetSubTexmapSlotName( int i, bool localized );
#else
    virtual MSTR GetSubTexmapSlotName( int i );
#endif
    virtual MSTR GetSubTexmapTVName( int i );
    virtual BOOL SetDlgThing( ParamDlg* dlg );

    // From ReferenceTarget
    virtual RefTargetHandle Clone( RemapDir& remap );

    // From ReferenceMaker
    virtual int NumRefs();
    virtual RefTargetHandle GetReference( int i );
    virtual void SetReference( int i, RefTargetHandle rtarg );
    virtual RefResult NotifyRefChanged( const Interval& changeInt, RefTargetHandle hTarget, PartID& partID,
                                        RefMessage message, BOOL propagate );

#if MAX_VERSION_MAJOR < 17
    virtual RefResult NotifyRefChanged( Interval changeInt, RefTargetHandle hTarget, PartID& partID,
                                        RefMessage message ) {
        return this->NotifyRefChanged( changeInt, hTarget, partID, message, TRUE );
    }
#endif

    // From Animatable
    virtual int NumSubs();
    virtual Animatable* SubAnim( int i );
#if MAX_VERSION_MAJOR < 24
    virtual TSTR SubAnimName( int i );
#else
    virtual TSTR SubAnimName( int i, bool localized );
#endif
    virtual int NumParamBlocks();
    virtual IParamBlock2* GetParamBlock( int i );
    virtual IParamBlock2* GetParamBlockByID( BlockID i );
    virtual void DeleteThis();
#if MAX_VERSION_MAJOR < 24
    virtual void GetClassName( MSTR& s );
#else
    virtual void GetClassName( MSTR& s, bool localized );
#endif
    virtual BaseInterface* GetInterface( Interface_ID id );

    SClass_ID SuperClassID() { return MATERIAL_CLASS_ID; }
    Class_ID ClassID() { return MaxKrakatoaMaterial_CLASS_ID; }
};
