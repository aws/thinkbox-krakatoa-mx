-- Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
-- SPDX-License-Identifier: Apache-2.0
macroScript MB category:"KrakatoaToolbar" tooltip:"Motion Blur Toggle" icon:#("KrakatoaTools",1)
(
	on isEnabled return (renderers.current.classid as string == "#(-1204370534, -399920359)" or renderers.current.classid as string == "#(3090596762L, 3895046937L)")
	on isChecked return try(FranticParticles.getBoolProperty "EnableMotionBlur")catch(false)
	on execute do (
		try(
			FranticParticles.setProperty "EnableMotionBlur" ((not (FranticParticles.getBoolProperty "EnableMotionBlur")) as string)
			Krakatoa_GUI_Main.refresh_GUI()
			Krakatoa_GUI_Channels.updateMemChannels()
		)catch()
	)
)

macroScript DF category:"KrakatoaToolbar" tooltip:"Depth Of Field Toggle" icon:#("KrakatoaTools",2)
(
	on isEnabled return (renderers.current.classid as string == "#(-1204370534, -399920359)" or renderers.current.classid as string == "#(3090596762L, 3895046937L)")
	on isChecked return try(FranticParticles.getBoolProperty "EnableDepthOfField")catch(false)
	on execute do (
		try(
			FranticParticles.setProperty "EnableDepthOfField" ((not (FranticParticles.getBoolProperty "EnableDepthOfField")) as string)
			Krakatoa_GUI_Main.refresh_GUI()
		)catch()
	)
)

/*
macroScript LT category:"KrakatoaToolbar" tooltip:"Use Lighting Toggle" icon:#("KrakatoaTools",3)
(
	on isEnabled return (renderers.current.classid as string == "#(-1204370534, -399920359)" or renderers.current.classid as string == "#(3090596762L, 3895046937L)")
	on isChecked return try(FranticParticles.getBoolProperty "UseLighting")catch(false)
	on execute do (
		try(
			FranticParticles.setProperty "UseLighting" ((not (FranticParticles.getBoolProperty "UseLighting")) as string)
			Krakatoa_GUI_Main.refresh_GUI()
			Krakatoa_GUI_Channels.updateMemChannels()
		)catch()
	)
)
*/

macroScript MO category:"KrakatoaToolbar" tooltip:"Use Matte Objects Toggle" icon:#("KrakatoaTools",5)
(
	on isEnabled return (renderers.current.classid as string == "#(-1204370534, -399920359)" or renderers.current.classid as string == "#(3090596762L, 3895046937L)")
	on isChecked return try(FranticParticles.getBoolProperty "Matte:UseMatteObjects")catch(false)
	on execute do (
		try(
			FranticParticles.setProperty "Matte:UseMatteObjects" ((not (FranticParticles.getBoolProperty "Matte:UseMatteObjects")) as string)
			Krakatoa_GUI_MatteObjects.refresh_GUI()
			Krakatoa_GUI_Main.refresh_GUI()
		)catch()
	)
)

macroScript JT category:"KrakatoaToolbar" tooltip:"Jittered Motion Blur Toggle" icon:#("KrakatoaTools",6)
(
	on isEnabled return (renderers.current.classid as string == "#(-1204370534, -399920359)" or renderers.current.classid as string == "#(3090596762L, 3895046937L)")
	on isChecked return try(FranticParticles.getBoolProperty "JitteredMotionBlur")catch(false)
	on execute do (
		try(
			FranticParticles.setProperty "JitteredMotionBlur" ((not (FranticParticles.getBoolProperty "JitteredMotionBlur")) as string)
			Krakatoa_GUI_Main.refresh_GUI()
		)catch()
	)
)

macroScript DT category:"KrakatoaToolbar" tooltip:"Deformation Motion Blur Toggle" icon:#("KrakatoaTools",23)
(
	on isEnabled return (renderers.current.classid as string == "#(-1204370534, -399920359)" or renderers.current.classid as string == "#(3090596762L, 3895046937L)")
	on isChecked return try(FranticParticles.getBoolProperty "DeformationMotionBlur")catch(false)
	on execute do (
		try(
			FranticParticles.setProperty "DeformationMotionBlur" ((not (FranticParticles.getBoolProperty "DeformationMotionBlur")) as string)
			Krakatoa_GUI_Main.refresh_GUI()
		)catch()
	)
)

macroScript CO category:"KrakatoaToolbar" tooltip:"Override Color Channel Toggle" icon:#("KrakatoaTools",7)
(
	on isEnabled return (renderers.current.classid as string == "#(-1204370534, -399920359)" or renderers.current.classid as string == "#(3090596762L, 3895046937L)")
	on isChecked return try(FranticParticles.getBoolProperty "ColorOverride:Enabled")catch(false)
	on execute do (
		try(FranticParticles.setProperty "ColorOverride:Enabled" ((not (FranticParticles.getBoolProperty "ColorOverride:Enabled")) as string))catch()
		try(Krakatoa_GUI_RenderGlobalValues.refresh_GUI())catch()
		--try(Krakatoa_GUI_Main.refresh_GUI())catch()
		try(Krakatoa_GUI_Main.update2009VFBControls side:#left)catch()
		try(Krakatoa_GUI_Channels.updateMemChannels())catch()
	)
)

macroScript EmissionOverride category:"KrakatoaToolbar" tooltip:"Override Emission Channel Toggle" icon:#("KrakatoaTools",24)
(
	on isEnabled return (renderers.current.classid as string == "#(-1204370534, -399920359)" or renderers.current.classid as string == "#(3090596762L, 3895046937L)")
	on isChecked return try(FranticParticles.getBoolProperty "EmissionOverride:Enabled")catch(false)
	on execute do (
		try(FranticParticles.setProperty "EmissionOverride:Enabled" ((not (FranticParticles.getBoolProperty "EmissionOverride:Enabled")) as string))catch()
		try(Krakatoa_GUI_RenderGlobalValues.refresh_GUI())catch()
		--try(Krakatoa_GUI_Main.refresh_GUI())catch()
		try(Krakatoa_GUI_Main.update2009VFBControls side:#left)catch()
		try(Krakatoa_GUI_Channels.updateMemChannels())catch()
	)
)

macroScript AbsorptionOverride category:"KrakatoaToolbar" tooltip:"Override Absorption Channel Toggle" icon:#("KrakatoaTools",25)
(
	on isEnabled return (renderers.current.classid as string == "#(-1204370534, -399920359)" or renderers.current.classid as string == "#(3090596762L, 3895046937L)")
	on isChecked return try(FranticParticles.getBoolProperty "AbsorptionOverride:Enabled")catch(false)
	on execute do (
		try(FranticParticles.setProperty "AbsorptionOverride:Enabled" ((not (FranticParticles.getBoolProperty "AbsorptionOverride:Enabled")) as string))catch()
		try(Krakatoa_GUI_RenderGlobalValues.refresh_GUI())catch()
		--try(Krakatoa_GUI_Main.refresh_GUI())catch()
		try(Krakatoa_GUI_Main.update2009VFBControls side:#left)catch()
		try(Krakatoa_GUI_Channels.updateMemChannels())catch()
	)
)

macroScript DensityOverride category:"KrakatoaToolbar" tooltip:"Override Density Channel Toggle" icon:#("KrakatoaTools",26)
(
	on isEnabled return (renderers.current.classid as string == "#(-1204370534, -399920359)" or renderers.current.classid as string == "#(3090596762L, 3895046937L)")
	on isChecked return try(FranticParticles.getBoolProperty "DensityOverride:Enabled")catch(false)
	on execute do (
		try(FranticParticles.setProperty "DensityOverride:Enabled" ((not (FranticParticles.getBoolProperty "DensityOverride:Enabled")) as string))catch()
		try(Krakatoa_GUI_RenderGlobalValues.refresh_GUI())catch()
		--try(Krakatoa_GUI_Main.refresh_GUI())catch()
		try(Krakatoa_GUI_Main.update2009VFBControls side:#left)catch()
		try(Krakatoa_GUI_Channels.updateMemChannels())catch()
	)
)

macroScript AE category:"KrakatoaToolbar" tooltip:"Ambient Extinction Toggle" icon:#("KrakatoaTools",8)
(
	on isEnabled return (renderers.current.classid as string == "#(-1204370534, -399920359)" or renderers.current.classid as string == "#(3090596762L, 3895046937L)")
	on isChecked return try(FranticParticles.getBoolProperty "PME:UseExtinction")catch(false)
	on execute do (
		try(
			FranticParticles.setProperty "PME:UseExtinction" ((not (FranticParticles.getBoolProperty "PME:UseExtinction")) as string)
			Krakatoa_GUI_AmbientPME.refresh_GUI()
			Krakatoa_GUI_Main.refresh_GUI()
		)catch()
	)
)


macroScript PC category:"KrakatoaToolbar" tooltip:"Particle Cache Toggle" icon:#("KrakatoaTools",9)
(
	on isEnabled return (renderers.current.classid as string == "#(-1204370534, -399920359)" or renderers.current.classid as string == "#(3090596762L, 3895046937L)")
	on isChecked return try(FranticParticles.getBoolProperty "EnableParticleCache")catch(false)
	on execute do (
		try(
			FranticParticles.setProperty "EnableParticleCache" ((not (FranticParticles.getBoolProperty "EnableParticleCache")) as string)
			Krakatoa_GUI_Main.refresh_GUI()
		)catch()
	)
)

macroScript LC category:"KrakatoaToolbar" tooltip:"Lighting Cache Toggle" icon:#("KrakatoaTools",10)
(
	on isEnabled return (renderers.current.classid as string == "#(-1204370534, -399920359)" or renderers.current.classid as string == "#(3090596762L, 3895046937L)")
	on isChecked return try(FranticParticles.getBoolProperty "EnableLightingCache")catch(false)
	on execute do (
		try(
			FranticParticles.setProperty "EnableLightingCache" ((not (FranticParticles.getBoolProperty "EnableLightingCache")) as string)
			Krakatoa_GUI_Main.refresh_GUI()
		)catch()
	)
)

macroScript PCX category:"KrakatoaToolbar" tooltip:"Clear Particle and Lighting Caches" icon:#("KrakatoaTools",32)
(
	on isEnabled return (renderers.current.classid as string == "#(-1204370534, -399920359)" or renderers.current.classid as string == "#(3090596762L, 3895046937L)" AND FranticParticles.GetCachedParticleCount() != 0)
	on execute do (
		try(FranticParticles.InvalidateParticleCache())catch()
		try(Krakatoa_GUI_Main.refreshCacheStatus())catch()
		try(Krakatoa_GUI_Channels.updateMemChannels())catch()
		try(Krakatoa_VFB_Overlay_Rollout.refresh_GUI())catch()
		try(Krakatoa_updateSchematicFlow())catch()
	)
)
macroScript LCX category:"KrakatoaToolbar" tooltip:"Clear Lighting Cache" icon:#("KrakatoaTools",33)
(
	on isEnabled return (renderers.current.classid as string == "#(-1204370534, -399920359)" or renderers.current.classid as string == "#(3090596762L, 3895046937L)" AND FranticParticles.GetCachedParticleCount() != 0)
	on execute do (
		try(FranticParticles.InvalidateLightingCache())catch()
		try(Krakatoa_GUI_Main.refreshCacheStatus())catch()
		try(Krakatoa_GUI_Channels.updateMemChannels())catch()
		try(Krakatoa_VFB_Overlay_Rollout.refresh_GUI())catch()
		try(Krakatoa_updateSchematicFlow())catch()
	)
)


macroScript PFg category:"KrakatoaToolbar" tooltip:"Render PFlow Geometry" icon:#("KrakatoaTools",11)
(
	on isEnabled return (renderers.current.classid as string == "#(-1204370534, -399920359)" or renderers.current.classid as string == "#(3090596762L, 3895046937L)")
	on isChecked return try(FranticParticles.getBoolProperty "RenderParticleFlowGeometry")catch(false)
	on execute do (
		try(
			FranticParticles.setProperty "RenderParticleFlowGeometry" ((not (FranticParticles.getBoolProperty "RenderParticleFlowGeometry")) as string)
			Krakatoa_GUI_Main.refresh_GUI()
			Krakatoa_GUI_Main.update2009VFBControls side:#right
		)catch()
	)
)

macroScript PFp category:"KrakatoaToolbar" tooltip:"Render PFlow Phantom" icon:#("KrakatoaTools",12)
(
	on isEnabled return (renderers.current.classid as string == "#(-1204370534, -399920359)" or renderers.current.classid as string == "#(3090596762L, 3895046937L)")
	on isChecked return try(FranticParticles.getBoolProperty "RenderParticleFlowPhantom")catch(false)
	on execute do (
		try(
			FranticParticles.setProperty "RenderParticleFlowPhantom" ((not (FranticParticles.getBoolProperty "RenderParticleFlowPhantom")) as string)
			Krakatoa_GUI_Main.refresh_GUI()
			Krakatoa_GUI_Main.update2009VFBControls side:#right
		)catch()
	)
)

macroScript PFb category:"KrakatoaToolbar" tooltip:"Render PFlow BBox" icon:#("KrakatoaTools",13)
(
	on isEnabled return (renderers.current.classid as string == "#(-1204370534, -399920359)" or renderers.current.classid as string == "#(3090596762L, 3895046937L)")
	on isChecked return try(FranticParticles.getBoolProperty "RenderParticleFlowBBox")catch(false)
	on execute do (
		try(
			FranticParticles.setProperty "RenderParticleFlowBBox" ((not (FranticParticles.getBoolProperty "RenderParticleFlowBBox")) as string)
			Krakatoa_GUI_Main.refresh_GUI()
			Krakatoa_GUI_Main.update2009VFBControls side:#right
		)catch()
	)
)

macroScript GV category:"KrakatoaToolbar" tooltip:"Render Geometry Vertices" icon:#("KrakatoaTools",14)
(
	on isEnabled return (renderers.current.classid as string == "#(-1204370534, -399920359)" or renderers.current.classid as string == "#(3090596762L, 3895046937L)")
	on isChecked return try(FranticParticles.getBoolProperty "RenderGeometryVertices")catch(false)
	on execute do (
		try(
			FranticParticles.setProperty "RenderGeometryVertices" ((not (FranticParticles.getBoolProperty "RenderGeometryVertices")) as string)
			Krakatoa_GUI_Main.refresh_GUI()
			Krakatoa_GUI_Main.update2009VFBControls side:#right
		)catch()
	)
)

macroScript LP category:"KrakatoaToolbar" tooltip:"Render Legacy Particles" icon:#("KrakatoaTools",15)
(
	on isEnabled return (renderers.current.classid as string == "#(-1204370534, -399920359)" or renderers.current.classid as string == "#(3090596762L, 3895046937L)")
	on isChecked return try(FranticParticles.getBoolProperty "RenderMaxParticles")catch(false)
	on execute do (
		try(
			FranticParticles.setProperty "RenderMaxParticles" ((not (FranticParticles.getBoolProperty "RenderMaxParticles")) as string)
			Krakatoa_GUI_Main.refresh_GUI()
			Krakatoa_GUI_Main.update2009VFBControls side:#right
		)catch()
	)
)

macroScript TP category:"KrakatoaToolbar" tooltip:"Render Thinking Particles" icon:#("KrakatoaTools",16)
(
	on isEnabled return (renderers.current.classid as string == "#(-1204370534, -399920359)" or renderers.current.classid as string == "#(3090596762L, 3895046937L)")
	on isChecked return try(FranticParticles.getBoolProperty "RenderThinkingParticles")catch(false)
	on execute do (
		try(
			FranticParticles.setProperty "RenderThinkingParticles" ((not (FranticParticles.getBoolProperty "RenderThinkingParticles")) as string)
			Krakatoa_GUI_Main.refresh_GUI()
			Krakatoa_GUI_Main.update2009VFBControls side:#right
		)catch()
	)
)

macroScript PRT category:"KrakatoaToolbar" tooltip:"Render PRT Loaders" icon:#("KrakatoaTools",17)
(
	on isEnabled return (renderers.current.classid as string == "#(-1204370534, -399920359)" or renderers.current.classid as string == "#(3090596762L, 3895046937L)")
	on isChecked return try(FranticParticles.getBoolProperty "RenderKrakatoaLoaders")catch(false)
	on execute do (
		try(
			FranticParticles.setProperty "RenderKrakatoaLoaders" ((not (FranticParticles.getBoolProperty "RenderKrakatoaLoaders")) as string)
			Krakatoa_GUI_Main.refresh_GUI()
			Krakatoa_GUI_Main.update2009VFBControls side:#right
		)catch()
	)
)

macroScript PRTV category:"KrakatoaToolbar" tooltip:"Render PRT Volumes" icon:#("KrakatoaTools",21) 
(
	on isEnabled return (renderers.current.classid as string == "#(-1204370534, -399920359)" or renderers.current.classid as string == "#(3090596762L, 3895046937L)")
	on isChecked return try(FranticParticles.getBoolProperty "RenderGeometryVolumes")catch(false)
	on execute do (
		try(
			FranticParticles.setProperty "RenderGeometryVolumes" ((not (FranticParticles.getBoolProperty "RenderGeometryVolumes")) as string)
			Krakatoa_GUI_Main.refresh_GUI()
			Krakatoa_GUI_Main.update2009VFBControls side:#right
		)catch()
	)
)

macroScript FumeFX category:"KrakatoaToolbar" tooltip:"Render FumeFX" icon:#("KrakatoaTools",22) --FIXME!
(
	on isEnabled return (renderers.current.classid as string == "#(-1204370534, -399920359)" or renderers.current.classid as string == "#(3090596762L, 3895046937L)")
	on isChecked return try(FranticParticles.getBoolProperty "RenderFumeFX")catch(false)
	on execute do (
		try(
			FranticParticles.setProperty "RenderFumeFX" ((not (FranticParticles.getBoolProperty "RenderFumeFX")) as string)
			Krakatoa_GUI_Main.refresh_GUI()
			Krakatoa_GUI_Main.update2009VFBControls side:#right
		)catch()
	)
)


macroScript SAV category:"KrakatoaToolbar" tooltip:"Save Particles To Disk Mode" icon:#("KrakatoaTools",19)
(
	on isEnabled return (renderers.current.classid as string == "#(-1204370534, -399920359)" or renderers.current.classid as string == "#(3090596762L, 3895046937L)")
	on isChecked return try((FranticParticles.getProperty "ParticleMode") == "Save Particles To File Sequence")catch(false)
	on execute do (
		try(
			local oldMode = (FranticParticles.getProperty "ParticleMode")
			if oldMode == "Save Particles To File Sequence" then
				FranticParticles.setProperty "ParticleMode" "Render Scene Particles"
			else
				FranticParticles.setProperty "ParticleMode" "Save Particles To File Sequence"
			Krakatoa_GUI_Main.refresh_GUI()
		)catch()
	)
)

macroScript RND category:"KrakatoaToolbar" tooltip:"Render Scene Particles" icon:#("KrakatoaTools",20)
(
	on isEnabled return (renderers.current.classid as string == "#(-1204370534, -399920359)" or renderers.current.classid as string == "#(3090596762L, 3895046937L)")
	on isChecked return try((FranticParticles.getProperty "ParticleMode") == "Render Scene Particles")catch(false)
	on execute do (
		try(
			local oldMode = (FranticParticles.getProperty "ParticleMode")
			if oldMode == "Render Scene Particles"  then
				FranticParticles.setProperty "ParticleMode" "Save Particles To File Sequence"
			else
				FranticParticles.setProperty "ParticleMode" "Render Scene Particles" 
			Krakatoa_GUI_Main.refresh_GUI()
		)catch()
	)
)



macroScript AllocateGlossinessChannel category:"KrakatoaToolbar" tooltip:"Allocate Glossiness Channel Toggle" icon:#("KrakatoaTools",27)
(
	on isEnabled return (renderers.current.classid as string == "#(-1204370534, -399920359)" or renderers.current.classid as string == "#(3090596762L, 3895046937L)")
	on isChecked return try(FranticParticles.getBoolProperty "Channel:Allocate:Glossiness")catch(false)
	on execute do (
		try(FranticParticles.setProperty "Channel:Allocate:Glossiness" ((not (FranticParticles.getBoolProperty "Channel:Allocate:Glossiness")) as string))catch()
		try(Krakatoa_GUI_Main.refresh_GUI())catch()
		try(Krakatoa_GUI_Main.update2009VFBControls side:#left)catch()
		try(Krakatoa_GUI_Channels.updateMemChannels())catch()
	)
)

macroScript AllocateEccentricityChannel category:"KrakatoaToolbar" tooltip:"Allocate Eccentricity Channel Toggle" icon:#("KrakatoaTools",28)
(
	on isEnabled return (renderers.current.classid as string == "#(-1204370534, -399920359)" or renderers.current.classid as string == "#(3090596762L, 3895046937L)")
	on isChecked return try(FranticParticles.getBoolProperty "Channel:Allocate:PhaseEccentricity")catch(false)
	on execute do (
		try(FranticParticles.setProperty "Channel:Allocate:PhaseEccentricity" ((not (FranticParticles.getBoolProperty "Channel:Allocate:PhaseEccentricity")) as string))catch()
		try(Krakatoa_GUI_Main.refresh_GUI())catch()
		try(Krakatoa_GUI_Main.update2009VFBControls side:#left)catch()
		try(Krakatoa_GUI_Channels.updateMemChannels())catch()
	)
)

macroScript AllocateSpecularLevelChannel category:"KrakatoaToolbar" tooltip:"Allocate SpecularLevel Channel Toggle" icon:#("KrakatoaTools",29)
(
	on isEnabled return (renderers.current.classid as string == "#(-1204370534, -399920359)" or renderers.current.classid as string == "#(3090596762L, 3895046937L)")
	on isChecked return try(FranticParticles.getBoolProperty "Channel:Allocate:SpecularLevel")catch(false)
	on execute do (
		try(FranticParticles.setProperty "Channel:Allocate:SpecularLevel" ((not (FranticParticles.getBoolProperty "Channel:Allocate:SpecularLevel")) as string))catch()
		try(Krakatoa_GUI_Main.refresh_GUI())catch()
		try(Krakatoa_GUI_Main.update2009VFBControls side:#left)catch()
		try(Krakatoa_GUI_Channels.updateMemChannels())catch()
	)
)

macroScript UseEmissionChannel category:"KrakatoaToolbar" tooltip:"Use Emission Channel Toggle" icon:#("KrakatoaTools",30)
(
	on isEnabled return (renderers.current.classid as string == "#(-1204370534, -399920359)" or renderers.current.classid as string == "#(3090596762L, 3895046937L)")
	on isChecked return try(FranticParticles.getBoolProperty "UseEmissionColor")catch(false)
	on execute do (
		try(FranticParticles.setProperty "UseEmissionColor" ((not (FranticParticles.getBoolProperty "UseEmissionColor")) as string))catch()
		try(Krakatoa_GUI_Main.refresh_GUI())catch()
		try(Krakatoa_GUI_Main.update2009VFBControls side:#left)catch()
		try(Krakatoa_GUI_Channels.updateMemChannels())catch()
	)
)

macroScript UseAbsorptionChannel category:"KrakatoaToolbar" tooltip:"Use Absorption Channel Toggle" icon:#("KrakatoaTools",31)
(
	on isEnabled return (renderers.current.classid as string == "#(-1204370534, -399920359)" or renderers.current.classid as string == "#(3090596762L, 3895046937L)")
	on isChecked return try(FranticParticles.getBoolProperty "UseFilterColor")catch(false)
	on execute do (
		try(FranticParticles.setProperty "UseFilterColor" ((not (FranticParticles.getBoolProperty "UseFilterColor")) as string))catch()
		try(Krakatoa_GUI_Main.refresh_GUI())catch()
		try(Krakatoa_GUI_Main.update2009VFBControls side:#left)catch()
		try(Krakatoa_GUI_Channels.updateMemChannels())catch()
	)
)