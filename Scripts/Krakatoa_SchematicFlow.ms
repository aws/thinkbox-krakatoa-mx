-- Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
-- SPDX-License-Identifier: Apache-2.0
(
	global Krakatoa_SchematicFlow_Rollout
	global Krakatoa_updateSchematicFlow
	global Krakatoa_SchematicFlow_LastUpdate = 0
	global Krakatoa_SchematicFlow_MainMenu
	global KrakatoaCameraModifier
	global FranticParticles
	
	try(destroyDialog Krakatoa_SchematicFlow_Rollout)catch()
	
	global Krakatoa_SchematicFlow_Tree = #()
	global Krakatoa_SchematicFlow_showAllNodes = ((getInisetting (getDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "SchematicView" "ShowAllNodes" )!="false" )
	
	rcmenu Krakatoa_SchematicFlow_MainMenu
	(
		submenu "View"
		(
			menuitem mnu_ShowAllNodes "Show Inactive Nodes" checked:Krakatoa_SchematicFlow_showAllNodes
		)
		menuitem mnu_Update "Update!" 
		on mnu_Update picked do 
		(
			::Krakatoa_SchematicFlow_LastUpdate = 0
			::Krakatoa_updateSchematicFlow()
		)

		on mnu_ShowAllNodes picked do 
		(
			Krakatoa_SchematicFlow_showAllNodes = not Krakatoa_SchematicFlow_showAllNodes
			::Krakatoa_updateSchematicFlow()
			setInisetting (getDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "SchematicView" "ShowAllNodes" (Krakatoa_SchematicFlow_showAllNodes as string)
		)
	)
	local Krakatoa_SchematicFlow_RightClickMenus 
	struct RightClickMenusStruct 
	(
		RenderElementsRCMenu,
		
		RenderNodeRCMenu,
		MemoryNodeRCMenu,
		MotionBlurNodeRCMenu,
		ShadingNodeRCMenu,
		SpecularPowerNodeRCMenu,
		SpecularLevelNodeRCMenu,
		PhaseEccentricityNodeRCMenu,
		
		DOFNodeRCMenu,
		EnvReflectionNodeRCMenu,
		APMENodeRCMenu,
		MatteObjectsNodeRCMenu,
		DepthMatteNodeRCMenu,
		ImageFileNodeRCMenu,
		AttenuationFileNodeRCMenu,
		--BackgroundImageFileNodeRCMenu,
		ParticleFileOutputRCMenu,
		
		VFBNodeRCMenu,
		
		ColorOverrideNodeRCMenu,
		EmissionOverrideNodeRCMenu,
		AbsorptionOverrideNodeRCMenu,
		DensityOverrideNodeRCMenu,
		
		ForceAdditiveModeNodeRCMenu,
		EmissionNodeRCMenu,
		AbsorptionNodeRCMenu,
		
		MaterialNodeRCMenu,
		GetParticlesFromNodeRCMenu,
		LightsNodeRCMenu,
		ViewsNodeRCMenu,
		PRTLoadersNodeRCMenu,
		PRTVolumesNodeRCMenu,
		PRTSurfacesNodeRCMenu,
		GeometryVerticesNodeRCMenu,
		LegacySystemsNodeRCMenu,
		TPNodeRCMenu,
		PFlowGeometryNodeRCMenu,
		PFlowPhantomNodeRCMenu,
		PFlowBBoxNodeRCMenu,
		FumeFXNodeRCMenu,
		PhoenixNodeRCMenu,
		PRTHairNodeRCMenu,
		PRTMakerNodeRCMenu,
		PRTSourceNodeRCMenu,
		PRTFieldNodeRCMenu,
		StokeNodeRCMenu,

		ChannelOverrideNodeRCMenu,
		
		KCMsNodeRCMenu
	)
	
	Krakatoa_SchematicFlow_RightClickMenus = RightClickMenusStruct()
	
	rcmenu MaterialNodeRCMenu
	(
		menuitem mnu_MaterialEditor "Open Material Editor..." checked:(MatEditor.isopen())
		on mnu_MaterialEditor  picked do 
		(
			if MatEditor.isopen() then MatEditor.close() else MatEditor.open()
		)
	)
	Krakatoa_SchematicFlow_RightClickMenus.MaterialNodeRCMenu = MaterialNodeRCMenu
	
	rcmenu RenderNodeRCMenu
	(
		menuitem mnu_RenderNow "RENDER FRAME NOW!" enabled:(if FranticParticles != undefined then ((FranticParticles.GetProperty "ParticleMode") != "Save Particles To File Sequence")else(false))
		separator sep_10
		menuitem mnu_RenderParticles "Particle Rendering" --checked:(try((FranticParticles.GetProperty "RenderingMethod") == "Particle Rendering")catch(false))
		menuitem mnu_RenderVoxes "Voxel Rendering" --checked:(try((FranticParticles.GetProperty "RenderingMethod") == "Voxel Rendering")catch(false))
		separator sep_20
		menuitem mnu_SaveSceneParticles "Save Particles To File Sequence" --checked:(try((FranticParticles.GetProperty "ParticleMode") == "Save Particles To File Sequence")catch(false))
		menuitem mnu_LightSceneParticles "Light Scene Particles" --checked:(try((FranticParticles.GetProperty "ParticleMode") == "Light Scene Particles")catch(false))
		separator sep_30
		menuitem mnu_saveLighting "Save Lighting As Emission Channel" --checked:(try(FranticParticles.GetBoolProperty "SaveLightingAsEmission")catch(false))
		
		on mnu_saveLighting picked do
		(
			FranticParticles.SetProperty "SaveLightingAsEmission" ((not (FranticParticles.GetBoolProperty "SaveLightingAsEmission")) as string)
			if (FranticParticles.GetBoolProperty "SaveLightingAsEmission") do
			(
				FranticParticles.SetProperty "RenderingMethod" "Particle Rendering"
				FranticParticles.SetProperty "ParticleMode" "Save Particles To File Sequence"
			)
			try(Krakatoa_GUI_Main.refresh_GUI())catch()
			try(Krakatoa_GUI_Channels.refresh_GUI())catch()			
			::Krakatoa_updateSchematicFlow()
		)
		
		on mnu_RenderNow picked do
		(
			if ((FranticParticles.GetProperty "ParticleMode") != "Save Particles To File Sequence") then 
			(
				local oldState = renderSceneDialog.isOpen()
				renderSceneDialog.close()
				
				local oldSaveFile = rendSaveFile 
				local oldTimeType = rendTimeType 
				
				rendSaveFile = false
				rendTimeType = 1
				local oldWidth = renderWidth
				local oldHeight = renderHeight
				
				local theScaleFactor = case (FranticParticles.GetProperty "IterativeRender:ScaleFactor") of
				(
					"2" : 2
					"1" : 1
					"1/2" : 0.5
					"1/4" : 0.25
					"1/8" : 0.125
					"1/16" : 0.0625
				)
				renderWidth = oldWidth*theScaleFactor
				renderHeight = oldHeight*theScaleFactor
				
				local oldDensity = FranticParticles.getFloatProperty "Density:DensityPerParticle"
				if FranticParticles.getProperty "Density:DensityMethod" != "Volumetric Density" and FranticParticles.getProperty "RenderingMethod" != "Voxel Rendering" do 
					FranticParticles.setProperty "Density:DensityPerParticle" (((oldDensity)*(theScaleFactor^2))as string)
				
				try
					(max quick render)
				catch
					(messagebox "KABOOM!\n3ds Max attempted to crash, but the Krakatoa GUI caught the exception.\nThis is usually a sign that there has been a memory problem or other instability inside the 3ds Max system\nand not necessarily something wrong with Krakatoa or your scene.\nPlease try to save a copy of your work and restart 3ds Max immediately.\n\nIf the problem persists, please contact Krakatoa Support - support@thinkboxsoftware.com" message:"Krakatoa Prevented A Big Explosion!")

				FranticParticles.setProperty "Density:DensityPerParticle" (oldDensity as string)
				rendTimeType = oldTimeType 
				rendSaveFile = oldSaveFile 
				renderWidth = oldWidth 
				renderHeight = oldHeight
				if oldState do renderSceneDialog.Open()		
			)
		)
		
		on mnu_RenderParticles picked do 
		(
			FranticParticles.SetProperty "RenderingMethod" "Particle Rendering"
			FranticParticles.SetProperty "ParticleMode" "Render Scene Particles"
			::Krakatoa_updateSchematicFlow()
			try(Krakatoa_GUI_Main.refresh_GUI())catch()
			try(Krakatoa_GUI_Channels.refresh_GUI())catch()
		)
		on mnu_RenderVoxes picked do 
		(
			FranticParticles.SetProperty "RenderingMethod" "Voxel Rendering"
			FranticParticles.SetProperty "ParticleMode" "Render Scene Particles"
			::Krakatoa_updateSchematicFlow()
			try(Krakatoa_GUI_Main.refresh_GUI())catch()
			try(Krakatoa_GUI_Channels.refresh_GUI())catch()
		)		
		on mnu_SaveSceneParticles picked do 
		(
			if FranticParticles.GetProperty "ParticleMode" != "Save Particles To File Sequence" then
			(
				FranticParticles.SetProperty "ParticleMode" "Save Particles To File Sequence"
				FranticParticles.SetProperty "RenderingMethod" "Particle Rendering"
			)
			else
				FranticParticles.SetProperty "ParticleMode" "Render Scene Particles"
			
			::Krakatoa_updateSchematicFlow()
			try(Krakatoa_GUI_Main.refresh_GUI())catch()
			try(Krakatoa_GUI_Channels.refresh_GUI())catch()
		)				
		on mnu_LightSceneParticles picked do 
		(
			if FranticParticles.GetProperty "ParticleMode" != "Light Scene Particles" then
				FranticParticles.SetProperty "ParticleMode" "Light Scene Particles"
			else
				FranticParticles.SetProperty "ParticleMode" "Render Scene Particles"
			
			::Krakatoa_updateSchematicFlow()
			try(Krakatoa_GUI_Main.refresh_GUI())catch()
			try(Krakatoa_GUI_Channels.refresh_GUI())catch()
		)				
		
	)
	
	Krakatoa_SchematicFlow_RightClickMenus.RenderNodeRCMenu = RenderNodeRCMenu 
	
	rcmenu MemoryNodeRCMenu
	(
		menuItem mnu_enablePCache "Enable PCache" --checked:(try(FranticParticles.GetBoolProperty "EnableParticleCache")catch(false)) enabled:((try(FranticParticles.GetCachedParticleCount())catch(0)) > 0)
		menuItem mnu_enableLCache "Enable LCache" --checked:(try(FranticParticles.GetBoolProperty "EnableLightingCache")catch(false)) enabled:((try(FranticParticles.GetCachedParticleCount())catch(0)) > 0)
		separator sep_10
		menuItem mnu_clearLCache "Clear LCache" --enabled:((try(FranticParticles.GetCachedParticleCount())catch(0)) > 0)
		menuItem mnu_clearBothCaches "Clear Both Caches" --enabled:((try(FranticParticles.GetCachedParticleCount())catch(0)) > 0)
			
		on mnu_clearLCache picked do
		(
			FranticParticles.InvalidateLightingCache()
			try(Krakatoa_GUI_Main.refreshCacheStatus())catch()
			try(Krakatoa_GUI_Channels.updateMemChannels())catch()
			try(Krakatoa_VFB_Overlay_Rollout.refresh_GUI())catch()
			::Krakatoa_updateSchematicFlow()
		)
		on mnu_clearBothCaches picked do
		(
			FranticParticles.InvalidateParticleCache()
			try(Krakatoa_GUI_Main.refreshCacheStatus())catch()
			try(Krakatoa_GUI_Channels.updateMemChannels())catch()
			try(Krakatoa_VFB_Overlay_Rollout.refresh_GUI())catch()
			::Krakatoa_updateSchematicFlow()
		)		
			
		on mnu_enablePCache picked do 
		(
			FranticParticles.SetProperty "EnableParticleCache" ((not (FranticParticles.GetBoolProperty "EnableParticleCache" )) as string)
			if not (FranticParticles.GetBoolProperty "EnableParticleCache" ) do
				FranticParticles.SetProperty "EnableLightingCache" "false"
			
			::Krakatoa_updateSchematicFlow()
			try(Krakatoa_GUI_Main.refresh_GUI())catch()
		)		
		on mnu_enableLCache picked do 
		(
			FranticParticles.SetProperty "EnableLightingCache" ((not (FranticParticles.GetBoolProperty "EnableLightingCache" )) as string)
			if (FranticParticles.GetBoolProperty "EnableLightingCache" ) do
				FranticParticles.SetProperty "EnableParticleCache" "true"
			
			::Krakatoa_updateSchematicFlow()
			try(Krakatoa_GUI_Main.refresh_GUI())catch()
		)			
	)
	
	Krakatoa_SchematicFlow_RightClickMenus.MemoryNodeRCMenu = MemoryNodeRCMenu 
	
	rcmenu ShadingNodeRCMenu
	(
		menuItem mnu_isotropic "Isotropic" --checked:(try(matchpattern (FranticParticles.GetProperty "PhaseFunction") pattern:"Isotropic" )catch(false))
		menuItem mnu_phong "Phong Surface" --checked:(try(matchpattern (FranticParticles.GetProperty "PhaseFunction") pattern:"Phong*" )catch(false))
		menuItem mnu_hengreen "Henyey-Greenstein" --checked:(try(matchpattern (FranticParticles.GetProperty "PhaseFunction") pattern:"Henyey*" )catch(false))
		menuItem mnu_schlick "Schlick" --checked:(try(matchpattern (FranticParticles.GetProperty "PhaseFunction") pattern:"Schlick" )catch(false))
		menuItem mnu_kajiyakay "Kajiya-Kay Hair" --checked:(try(matchpattern (FranticParticles.GetProperty "PhaseFunction") pattern:"*Kajiya*" )catch(false))
		menuItem mnu_marschner "Marschner (King Kong) Hair" --checked:(try(matchpattern (FranticParticles.GetProperty "PhaseFunction") pattern:"*Kong*" )catch(false))
			
		fn updatePhaseFunction theMode =
		(
			FranticParticles.SetProperty "PhaseFunction" theMode
			::Krakatoa_updateSchematicFlow()
			try(Krakatoa_GUI_Main.refresh_GUI())catch()
			try(Krakatoa_GUI_Channels.refresh_GUI())catch()
		)
		
		on mnu_isotropic picked do updatePhaseFunction "Isotropic"
		on mnu_phong picked do updatePhaseFunction "Phong Surface"
		on mnu_hengreen picked do updatePhaseFunction "Henyey-Greenstein"
		on mnu_schlick picked do	updatePhaseFunction "Schlick"
		on mnu_kajiyakay picked do	updatePhaseFunction "Kajiya-Kay Hair"
		on mnu_marschner picked do updatePhaseFunction"King Kong Hair"
	)
	Krakatoa_SchematicFlow_RightClickMenus.ShadingNodeRCMenu = ShadingNodeRCMenu 
	
	
	rcmenu SpecularPowerNodeRCMenu 
	(
		menuitem mnu_toggle "Allocate SpecularPower Channel" --checked:(try(FranticParticles.GetBoolProperty "Channel:Allocate:SpecularPower")catch(false))
		on mnu_toggle picked do
		(
			FranticParticles.SetProperty "Channel:Allocate:SpecularPower" (not (FranticParticles.GetBoolProperty "Channel:Allocate:SpecularPower" ))
			::Krakatoa_updateSchematicFlow()
			try(Krakatoa_GUI_Main.refresh_GUI())catch()
			try(Krakatoa_GUI_Channels.refresh_GUI())catch()			
		)
	)
	Krakatoa_SchematicFlow_RightClickMenus.SpecularPowerNodeRCMenu = SpecularPowerNodeRCMenu
	
	rcmenu SpecularLevelNodeRCMenu 
	(
		menuitem mnu_toggle "Allocate SpecularLevel Channel" --checked:(try(FranticParticles.GetBoolProperty "Channel:Allocate:SpecularLevel")catch(false))
		on mnu_toggle picked do
		(
			FranticParticles.SetProperty "Channel:Allocate:SpecularLevel" (not (FranticParticles.GetBoolProperty "Channel:Allocate:SpecularLevel" ))
			::Krakatoa_updateSchematicFlow()
			try(Krakatoa_GUI_Main.refresh_GUI())catch()
			try(Krakatoa_GUI_Channels.refresh_GUI())catch()			
		)		
	)
	Krakatoa_SchematicFlow_RightClickMenus.SpecularLevelNodeRCMenu = SpecularLevelNodeRCMenu

	rcmenu PhaseEccentricityNodeRCMenu 
	(
		menuitem mnu_toggle "Allocate PhaseEccentricity Channel" --checked:(try(FranticParticles.GetBoolProperty "Channel:Allocate:PhaseEccentricity")catch(false))
		on mnu_toggle picked do
		(
			FranticParticles.SetProperty "Channel:Allocate:PhaseEccentricity" (not (FranticParticles.GetBoolProperty "Channel:Allocate:PhaseEccentricity" ))
			::Krakatoa_updateSchematicFlow()
			try(Krakatoa_GUI_Main.refresh_GUI())catch()
			try(Krakatoa_GUI_Channels.refresh_GUI())catch()			
		)			
	)
	Krakatoa_SchematicFlow_RightClickMenus.PhaseEccentricityNodeRCMenu = PhaseEccentricityNodeRCMenu
	

	rcmenu MotionBlurNodeRCMenu
	(
		menuItem mnu_enableMBlur "Enable Motion Blur" --checked:(try(FranticParticles.GetBoolProperty "EnableMotionBlur" )catch(false))
		separator sep_10
		menuItem mnu_enableJitteredMBlur "Jittered Motion Blur" --checked:(try(FranticParticles.GetBoolProperty "JitteredMotionBlur" )catch(false))
		menuItem mnu_enableDeformMBlur "Sub-Sample Geometry" --checked:(try(FranticParticles.GetBoolProperty "DeformationMotionBlur" )catch(false))
		separator sep_20
		menuItem mnu_setMotionBlurSegments "Set Particle Segments..."
		menuItem mnu_setMotionBlurShutter "Set Shutter Degrees..."
		menuItem mnu_setMatteSegments "Set Matte Segments..."
		menuItem mnu_setMatteBias "Set Matte Bias..."
		
		on mnu_setMotionBlurSegments picked do
		(
			Krakatoa_GUI_Main.createPresetsRCMenu type:#mblur
			popUpMenu Krakatoa_RCMenu_Struct.Presets_RCMenu position:mouse.screenPos
		)
		on mnu_setMotionBlurShutter picked do
		(
			Krakatoa_GUI_Main.createPresetsRCMenu type:#shutter
			popUpMenu Krakatoa_RCMenu_Struct.Presets_RCMenu position:mouse.screenPos
		)
		on mnu_setMatteSegments picked do
		(
			Krakatoa_GUI_Main.createPresetsRCMenu type:#geosamples
			popUpMenu Krakatoa_RCMenu_Struct.Presets_RCMenu position:mouse.screenPos
		)
		on mnu_setMatteBias picked do
		(
			Krakatoa_GUI_Main.createPresetsRCMenu type:#bias
			popUpMenu Krakatoa_RCMenu_Struct.Presets_RCMenu position:mouse.screenPos
		)		
		
		on mnu_enableMBlur picked do 
		(
			FranticParticles.SetProperty "EnableMotionBlur" ((not (FranticParticles.GetBoolProperty "EnableMotionBlur" )) as string)
			::Krakatoa_updateSchematicFlow()
			try(Krakatoa_GUI_Main.refresh_GUI())catch()
			try(Krakatoa_GUI_Channels.refresh_GUI())catch()
		)	
		on mnu_enableJitteredMBlur picked do 
		(
			FranticParticles.SetProperty "JitteredMotionBlur" ((not (FranticParticles.GetBoolProperty "JitteredMotionBlur" )) as string)
			::Krakatoa_updateSchematicFlow()
			try(Krakatoa_GUI_Main.refresh_GUI())catch()
			try(Krakatoa_GUI_Channels.refresh_GUI())catch()
		)	
		on mnu_enableDeformMBlur picked do 
		(
			FranticParticles.SetProperty "DeformationMotionBlur" ((not (FranticParticles.GetBoolProperty "DeformationMotionBlur" )) as string)
			::Krakatoa_updateSchematicFlow()
			try(Krakatoa_GUI_Main.refresh_GUI())catch()
			try(Krakatoa_GUI_Channels.refresh_GUI())catch()
		)			
	)
	
	Krakatoa_SchematicFlow_RightClickMenus.MotionBlurNodeRCMenu =MotionBlurNodeRCMenu
	
	rcmenu DOFNodeRCMenu
	(
		fn canAddKrakatoaCameraMod = viewport.getCamera() != undefined and (for m in (viewport.getCamera()).modifiers where classof m == KrakatoaCameraModifier collect m).count == 0
		menuItem mnu_enableDOF "Enable Depth Of Field" --checked:(try(FranticParticles.GetBoolProperty "EnableDepthOfField" )catch(false))
		separator sep_10 
		menuItem mnu_setDOFSampleRate "Set Sample Rate..."
		separator sep_100 filter:canAddKrakatoaCameraMod
		menuItem mnu_addCameraModifier "FIX:Add Krakatoa Camera Modifier..." filter:canAddKrakatoaCameraMod
			
		on mnu_setDOFSampleRate picked do
		(
			Krakatoa_GUI_Main.createPresetsRCMenu type:#dofsamplerate
			popUpMenu Krakatoa_RCMenu_Struct.Presets_RCMenu position:mouse.screenPos
		)
		
		on mnu_enableDOF picked do 
		(
			FranticParticles.SetProperty "EnableDepthOfField" ((not (FranticParticles.GetBoolProperty "EnableDepthOfField" )) as string)
			::Krakatoa_updateSchematicFlow()
			try(Krakatoa_GUI_Main.refresh_GUI())catch()
		)			

		on mnu_addCameraModifier picked do
		(
			local theCamera = viewport.getCamera() 
			local theMod = KrakatoaCameraModifier dofOn:true
			addModifier theCamera theMod
			max modify mode
			select theCamera
		)
	)
	Krakatoa_SchematicFlow_RightClickMenus.DOFNodeRCMenu = DOFNodeRCMenu
	
	rcmenu EnvReflectionNodeRCMenu 
	(
		menuItem mnu_enableReflections "Enable Environment Reflections" --checked:(try(FranticParticles.GetBoolProperty "UseEnvironmentReflections" )catch(false))
		separator sep_10
		menuItem mnu_enableEnvironmentMap "Use Environment Map" checked:(useEnvironmentMap)
		separator sep_20
		menuItem mnu_openEnvDialog "Open Environment Dialog..."
		
		on mnu_enableEnvironmentMap picked do
		(
			useEnvironmentMap = not useEnvironmentMap
		)
		on mnu_openEnvDialog picked do
		(
			editAtmospheric()
		)
		on mnu_enableReflections picked do 
		(
			FranticParticles.SetProperty "UseEnvironmentReflections" ((not (FranticParticles.GetBoolProperty "UseEnvironmentReflections" )) as string)
			::Krakatoa_updateSchematicFlow()
			try(Krakatoa_GUI_Main.refresh_GUI())catch()
			try(Krakatoa_GUI_Channels.refresh_GUI())catch()
		)			
	)
	Krakatoa_SchematicFlow_RightClickMenus.EnvReflectionNodeRCMenu = EnvReflectionNodeRCMenu
	
	
	rcmenu APMENodeRCMenu 
	(
		menuItem mnu_enableAPME "Enable Ambient PME" --checked:(try(FranticParticles.GetBoolProperty "PME:UseExtinction" )catch(false))
		on mnu_enableAPME picked do 
		(
			FranticParticles.SetProperty "PME:UseExtinction" ((not (FranticParticles.GetBoolProperty "PME:UseExtinction" )) as string)
			::Krakatoa_updateSchematicFlow()
			try(Krakatoa_GUI_Main.refresh_GUI())catch()
		)			
	)
	Krakatoa_SchematicFlow_RightClickMenus.APMENodeRCMenu = APMENodeRCMenu
	
	rcmenu DepthMatteNodeRCMenu 
	(
		menuItem mnu_enableDepthMapMatte "Enable Depth Map Matte" --checked:(try(FranticParticles.GetBoolProperty "Matte:UseDepthMapFiles" )catch(false))
		on mnu_enableDepthMapMatte picked do 
		(
			FranticParticles.SetProperty "Matte:UseDepthMapFiles" ((not (FranticParticles.GetBoolProperty "Matte:UseDepthMapFiles" )) as string)
			::Krakatoa_updateSchematicFlow()
			try(Krakatoa_GUI_Main.refresh_GUI())catch()
		)				
		
	)
	
	Krakatoa_SchematicFlow_RightClickMenus.DepthMatteNodeRCMenu  = DepthMatteNodeRCMenu 
	
	rcmenu VFBNodeRCMenu 
	(
		menuItem mnu_enableVFB "Virtual Frame Buffer (Rendered Frame Window)" checked:(rendshowVFB)
		on mnu_enableVFB picked do 
		(
			renderSceneDialog.close()
			rendshowVFB = not rendshowVFB
			::Krakatoa_updateSchematicFlow()
			try(Krakatoa_GUI_Main.refresh_GUI())catch()
		)			
	)
	Krakatoa_SchematicFlow_RightClickMenus.VFBNodeRCMenu = VFBNodeRCMenu
	
	
	rcmenu AttenuationFileNodeRCMenu
	(
		menuItem mnu_enableAttenuationFile "Save Attenuation Map Image File" --checked:(try(FranticParticles.GetBoolProperty "EnableAttenuationMapSaving" )catch(false))
		on mnu_enableAttenuationFile picked do 
		(
			FranticParticles.SetProperty "EnableAttenuationMapSaving" ((not (FranticParticles.GetBoolProperty "EnableAttenuationMapSaving" )) as string)
			::Krakatoa_updateSchematicFlow()
			try(Krakatoa_GUI_Main.refresh_GUI())catch()
		)			
	)
	Krakatoa_SchematicFlow_RightClickMenus.AttenuationFileNodeRCMenu = AttenuationFileNodeRCMenu
	
	rcmenu ImageFileNodeRCMenu
	(
		menuItem mnu_enableImageFile "Save Image File" checked:(rendSaveFile)
		separator sep_10
		menuItem mnu_SelectImageFile "Set Render Output Filename..."  checked:(rendOutputFilename!="")
		
		on mnu_enableImageFile picked do 
		(
			renderSceneDialog.close()
			rendSaveFile = not rendSaveFile
			::Krakatoa_updateSchematicFlow()
			try(Krakatoa_GUI_Main.refresh_GUI())catch()
		)		

		on mnu_SelectImageFile picked do
		(
			local oldState = renderSceneDialog.isOpen()
			local keepOpen = ((getIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "Preferences" "KeepRenderSceneDialogOpen")=="true")
			renderSceneDialog.close()
			theBitmapPath = getBitmapSaveFileName filename:rendOutputFilename
			if theBitmapPath != undefined do
			(
				rendOutputFilename = theBitmapPath 
				rendSaveFile = true
			)	
			if oldState and keepOpen do renderSceneDialog.open()	
			try(::Krakatoa_updateSchematicFlow())catch()
		)
			
	)
	Krakatoa_SchematicFlow_RightClickMenus.ImageFileNodeRCMenu = ImageFileNodeRCMenu
	
	rcmenu ParticleFileOutputRCMenu 
	(
		menuItem mnu_saveParticleFile "Save Particle File..."
		on mnu_saveParticleFile picked do
		(
			try(Krakatoa_GUI_SaveParticles.particleFiles_Pressed_FN())catch()
		)
	)
	Krakatoa_SchematicFlow_RightClickMenus.ParticleFileOutputRCMenu = ParticleFileOutputRCMenu
	
	/*
	rcmenu BackgroundImageFileNodeRCMenu
	(
		menuItem mnu_saveMultipleLayers "Save Background Image File" checked:(FranticParticles.GetBoolProperty "Matte:SaveMultipleLayers")
		on mnu_saveMultipleLayers picked do 
		(
			FranticParticles.SetProperty "Matte:SaveMultipleLayers" ((not (FranticParticles.GetBoolProperty "Matte:SaveMultipleLayers" )) as string)
			::Krakatoa_updateSchematicFlow()
			try(Krakatoa_GUI_Main.refresh_GUI())catch()
		)					
		
	)
	Krakatoa_SchematicFlow_RightClickMenus.BackgroundImageFileNodeRCMenu = BackgroundImageFileNodeRCMenu
	*/
	
	rcmenu ColorOverrideNodeRCMenu
	(
		menuItem mnu_overrideColor "Override Color Channel" --checked:(try(FranticParticles.GetBoolProperty "ColorOverride:Enabled")catch(false))
		on mnu_overrideColor picked do 
		(
			FranticParticles.SetProperty "ColorOverride:Enabled" ((not (FranticParticles.GetBoolProperty "ColorOverride:Enabled" )) as string)
			::Krakatoa_updateSchematicFlow()
			try(Krakatoa_GUI_Main.refresh_GUI())catch()
			try(Krakatoa_GUI_Channels.refresh_GUI())catch()
		)	
	)
	Krakatoa_SchematicFlow_RightClickMenus.ColorOverrideNodeRCMenu = ColorOverrideNodeRCMenu
	rcmenu EmissionOverrideNodeRCMenu
	(
		menuItem mnu_overrideEmission "Override Emission Channel" --checked:(try(FranticParticles.GetBoolProperty "EmissionOverride:Enabled")catch(false))
		on mnu_overrideEmission picked do 
		(
			FranticParticles.SetProperty "EmissionOverride:Enabled" ((not (FranticParticles.GetBoolProperty "EmissionOverride:Enabled" )) as string)
			::Krakatoa_updateSchematicFlow()
			try(Krakatoa_GUI_Main.refresh_GUI())catch()
			try(Krakatoa_GUI_Channels.refresh_GUI())catch()
		)	
	)	
	Krakatoa_SchematicFlow_RightClickMenus.EmissionOverrideNodeRCMenu = EmissionOverrideNodeRCMenu
	rcmenu AbsorptionOverrideNodeRCMenu
	(
		menuItem mnu_overrideAbsorption "Override Absorption Channel" --checked:(try(FranticParticles.GetBoolProperty "AbsorptionOverride:Enabled")catch(false))

		on mnu_overrideAbsorption picked do 
		(
			FranticParticles.SetProperty "AbsorptionOverride:Enabled" ((not (FranticParticles.GetBoolProperty "AbsorptionOverride:Enabled" )) as string)
			::Krakatoa_updateSchematicFlow()
			try(Krakatoa_GUI_Main.refresh_GUI())catch()
			try(Krakatoa_GUI_Channels.refresh_GUI())catch()
		)	
	)		
	Krakatoa_SchematicFlow_RightClickMenus.AbsorptionOverrideNodeRCMenu = AbsorptionOverrideNodeRCMenu
	
	rcmenu DensityOverrideNodeRCMenu
	(
		menuItem mnu_overrideDensity "Override Density Channel" --checked:(try(FranticParticles.GetBoolProperty "DensityOverride:Enabled")catch(false))
		on mnu_overrideDensity picked do 
		(
			FranticParticles.SetProperty "DensityOverride:Enabled" ((not (FranticParticles.GetBoolProperty "DensityOverride:Enabled" )) as string)
			::Krakatoa_updateSchematicFlow()
			try(Krakatoa_GUI_Main.refresh_GUI())catch()
			try(Krakatoa_GUI_Channels.refresh_GUI())catch()
		)			
	)
	Krakatoa_SchematicFlow_RightClickMenus.DensityOverrideNodeRCMenu = DensityOverrideNodeRCMenu
	
	
	rcmenu ForceAdditiveModeNodeRCMenu
	(
		menuItem mnu_ForceAdditive "Force Additive Mode" --checked:(try(FranticParticles.GetBoolProperty "AdditiveMode")catch(false))
		on mnu_ForceAdditive picked do 
		(
			FranticParticles.SetProperty "AdditiveMode" ((not (FranticParticles.GetBoolProperty "AdditiveMode" )) as string)
			::Krakatoa_updateSchematicFlow()
			try(Krakatoa_GUI_Main.refresh_GUI())catch()
			try(Krakatoa_GUI_Channels.refresh_GUI())catch()
		)	
	)
	Krakatoa_SchematicFlow_RightClickMenus.ForceAdditiveModeNodeRCMenu = ForceAdditiveModeNodeRCMenu	
	
	rcmenu EmissionNodeRCMenu
	(
		menuItem mnu_UseEmission "Use Emission" --checked:(try(FranticParticles.GetBoolProperty "UseEmissionColor")catch(false)) enabled:(try(not (FranticParticles.GetBoolProperty "AdditiveMode"))catch(false))

		on mnu_UseEmission picked do 
		(
			FranticParticles.SetProperty "UseEmissionColor" ((not (FranticParticles.GetBoolProperty "UseEmissionColor" )) as string)
			::Krakatoa_updateSchematicFlow()
			try(Krakatoa_GUI_Main.refresh_GUI())catch()
			try(Krakatoa_GUI_Channels.refresh_GUI())catch()
		)	
	)
	Krakatoa_SchematicFlow_RightClickMenus.EmissionNodeRCMenu = EmissionNodeRCMenu
	
	rcmenu AbsorptionNodeRCMenu
	(	
		menuItem mnu_UseAbsorption "Use Absorption" --checked:(try(FranticParticles.GetBoolProperty "UseFilterColor")catch(false)) enabled:(try(not (FranticParticles.GetBoolProperty "AdditiveMode"))catch(false))

		on mnu_UseAbsorption picked do 
		(
			FranticParticles.SetProperty "UseFilterColor" ((not (FranticParticles.GetBoolProperty "UseFilterColor" )) as string)
			::Krakatoa_updateSchematicFlow()
			try(Krakatoa_GUI_Main.refresh_GUI())catch()
			try(Krakatoa_GUI_Channels.refresh_GUI())catch()
		)
		
	)
	Krakatoa_SchematicFlow_RightClickMenus.AbsorptionNodeRCMenu = AbsorptionNodeRCMenu
	
	/*
	rcmenu GetParticlesFromNodeRCMenu 
	(
		menuItem mnu_ForceAdditive "Force Additive Mode" checked:(FranticParticles.GetBoolProperty "AdditiveMode")
		
	)
	Krakatoa_SchematicFlow_RightClickMenus.GetParticlesFromNodeRCMenu = GetParticlesFromNodeRCMenu
	*/
	
	rollout Krakatoa_SchematicFlow_Rollout "Krakatoa Schematic Flow" width:900
	(
		local inputCount = 0
		local nextOffset = #(0,0)
		local theOriginX = 780
		local theTreeHeight = 0
		local theMemoryPoolIndex = 0
		
		KrakatoaSchematicControl hc "" width:900 height:600 pos:[0,0] 
		--edittext edt_info readOnly:true
		
		fn getNextOffset =
		(
			if inputCount >= 4 then
			(
				inputCount = 0
				nextOffset =#(120,-150)
			)
			else
				nextOffset = #(20,50)			
		)
		
		fn defineMenu menuName theNodes thePropName =
		(
			local txt = StringStream ""
			format "rcmenu % (\n" menuName to:txt
			format"fn filterSeparator = (% > 0) \n" theNodes.count to:txt
			format"menuItem mnu_enable_type \"Enabled For Rendering\" checked:(FranticParticles.GetBoolProperty \"%\")\n" thePropName to:txt
			format "on mnu_enable_type picked do (\n" to:txt
			format "FranticParticles.SetProperty \"%\" (not (FranticParticles.GetBoolProperty \"%\"))\n" thePropName thePropName to:txt
			format "try(Krakatoa_GUI_Main.refresh_GUI())catch()\n" to:txt
			format "::Krakatoa_updateSchematicFlow())\n" to:txt
			
			if menuName == "PRTLoadersNodeRCMenu" do
			(
				format "separator sep_10\n" to:txt
				format "menuitem mnu_create \"Create PRT Loader Object(s)\"\n" to:txt
				format "separator sep_20\n" to:txt
				format "menuitem mnu_explorer \"Open Krakatoa Explorers...\"\n" to:txt
				format "on mnu_create picked do (macros.run \"Krakatoa\" \"PRTLoader\"; ::Krakatoa_updateSchematicFlow()) \n" to:txt
				format "on mnu_explorer picked do macros.run \"Krakatoa\" \"KrakatoaExplorers\" \n" to:txt
			)
			if menuName == "PRTVolumesNodeRCMenu" do
			(
				format "separator sep_10\n" to:txt
				format "menuitem mnu_create \"Create PRT Volume Object(s)\"\n" to:txt
				format "separator sep_20\n" to:txt
				format "menuitem mnu_explorer \"Open Krakatoa Explorers...\"\n" to:txt
				
				format "on mnu_create picked do (macros.run \"Krakatoa\" \"PRTVolume\"; ::Krakatoa_updateSchematicFlow()) \n" to:txt
				format "on mnu_explorer picked do macros.run \"Krakatoa\" \"KrakatoaExplorers\" \n" to:txt
			)	
			if menuName == "PRTSurfacesNodeRCMenu" do
			(
				format "separator sep_10\n" to:txt
				format "menuitem mnu_create \"Create PRT Surface Object(s)\"\n" to:txt
				--format "separator sep_20\n" to:txt
				--format "menuitem mnu_explorer \"Open Krakatoa Explorers...\"\n" to:txt
				format "on mnu_create picked do ((if selection.count == 0 then (prt_Surface()) else (macros.run \"Krakatoa\" \"PRTSurface\")); ::Krakatoa_updateSchematicFlow()) \n" to:txt
				--format "on mnu_explorer picked do macros.run \"Krakatoa\" \"KrakatoaExplorers\" \n" to:txt				
			)
			if menuName == "FumeFXNodeRCMenu" do
			(
				format "separator sep_10\n" to:txt
				format "menuitem mnu_create \"Create PRT FumeFX Object(s)\"\n" to:txt
				format "separator sep_20\n" to:txt
				format "menuitem mnu_explorer \"Open Krakatoa Explorers...\"\n" to:txt
				
				format "on mnu_create picked do (macros.run \"Krakatoa\" \"PRTFumeFX\"; ::Krakatoa_updateSchematicFlow()) \n" to:txt
				format "on mnu_explorer picked do macros.run \"Krakatoa\" \"KrakatoaExplorers\" \n" to:txt
			)	
			if menuName == "PhoenixNodeRCMenu" do
			(
			
			)
			if menuName == "PRTHairNodeRCMenu" do
			(
				format "separator sep_10\n" to:txt
				format "menuitem mnu_create \"Create PRT Hair Object(s)\"\n" to:txt
				format "separator sep_20\n" to:txt
				format "menuitem mnu_explorer \"Open Krakatoa Explorers...\"\n" to:txt
				
				format "on mnu_create picked do (macros.run \"Krakatoa\" \"PRTHair\"; ::Krakatoa_updateSchematicFlow())\n" to:txt
				format "on mnu_explorer picked do (macros.run \"Krakatoa\" \"KrakatoaExplorers\") \n" to:txt
			)
			if menuName == "PRTMakerNodeRCMenu" do
			(
				format "separator sep_10\n" to:txt
				format "menuitem mnu_create \"Create a PRT Maker Object at World Origin\"\n" to:txt
				format "separator sep_20\n" to:txt
				format "menuitem mnu_explorer \"Open PRT Maker Designer Dialog...\"\n" to:txt
				
				format "on mnu_create picked do (select (PRT_Maker()); ::Krakatoa_updateSchematicFlow())\n" to:txt
				format "on mnu_explorer picked do macros.run \"Krakatoa\" \"PRTMakerDesigner\" \n" to:txt				
			)
			if menuName == "PRTSourceNodeRCMenu" do
			(
				format "separator sep_10\n" to:txt
				format "menuitem mnu_create \"Create PRT Source Object at World Origin\"\n" to:txt
				format "on mnu_create picked do (select (PRT_Source()); ::Krakatoa_updateSchematicFlow() )\n" to:txt
			)			
			if menuName == "PRTFieldNodeRCMenu" do
			(
				
			)
			
			format "separator sep_100 filter:filterSeparator\n" to:txt
			local cnt = 0
			for aNode in theNodes while cnt < 40 do
			(
				cnt+=1
				local theName = (if aNode.isHiddenInVpt then "-- " else if aNode.renderable then "+ " else "-r ") +  aNode.name 
				if not aNode.renderable then 
					theName += " [object not renderable]"
				else if aNode.isNodeHidden then 
					theName += " [object hidden]"
				else if aNode.isHidden then 
					theName += " [layer hidden]"
				if aNode.isFrozen and maxOps.hideFrozenObjects then 
					theName += " [hide frozen]"
				else if aNode.isHiddenInVpt and not aNode.isNodeHidden and not aNode.isHidden then theName += " [hidden by category]"
				
					
				format  "menuItem mnu_node_% \"%\" \n" cnt theName to:txt
				format  "on mnu_node_% picked do (\n" cnt to:txt
				format  "if keyboard.controlPressed then \n" to:txt
				format  "try(max modify mode;select (getNodeByName \"%\"); (getNodeByName \"%\").isHidden = not (getNodeByName \"%\").isHidden; ::Krakatoa_updateSchematicFlow())catch() \n" aNode.name aNode.name aNode.name   to:txt
				format "else\n" to:txt
				format "try(max modify mode;select (getNodeByName \"%\"))catch() \n" aNode.name to:txt
				format ")\n" to:txt
			)
			
			if theNodes.count > 40 do 
				format "menuItem mnu_node_etcetera \"...And % more objects...\" \n" (theNodes.count - 40) to:txt
			
			format ")\n" to:txt
			execute (txt as string)
		)
		
		fn defineMatteMenu badMatteNodes goodMatteNodes =
		(
				local txt = StringStream ""
				format "rcmenu MatteObjectsNodeRCMenu (\n" to:txt
				format "fn filterSeparator = (% > 0) \n" (badMatteNodes.count+goodMatteNodes.count) to:txt
				format "menuItem mnu_enableMatteObjects \"Enable Matte Objects\" checked:(FranticParticles.GetBoolProperty \"Matte:UseMatteObjects\" ) \n" to:txt
				format "separator sep_10 \n" to:txt
				format "menuItem mnu_openMatteObjectsExplorer \"Open Matte Objects Explorer\" \n" to:txt
					
				format "on mnu_enableMatteObjects picked do (\n" to:txt
				format "FranticParticles.SetProperty \"Matte:UseMatteObjects\" ((not (FranticParticles.GetBoolProperty \"Matte:UseMatteObjects\" )) as string) \n" to:txt
				format "::Krakatoa_updateSchematicFlow()\n" to:txt
				format "try(Krakatoa_GUI_Main.refresh_GUI())catch()\n" to:txt
				format ")\n" to:txt
				format "on mnu_openMatteObjectsExplorer picked do \n" to:txt
				format "try(macros.run \"Krakatoa\" \"KrakatoaMatteObjectsExplorer\")catch()\n" to:txt
			
				format "separator sep_100 filter:filterSeparator\n" to:txt
				local cnt = 0
				for aNode in badMatteNodes while cnt < 40 do
				(
					cnt+=1
					format "menuItem mnu_node_% \"%\" \n" cnt aNode[2] to:txt
					format "on mnu_node_% picked do (\n" cnt to:txt
					format "try(max modify mode;modPanel.setCurrentObject ((getNodeByName \"%\").baseobject))catch() \n" aNode[1].name to:txt
					format  ")\n" to:txt
				)	
				for aNode in goodMatteNodes while cnt < 40 do
				(
					cnt+=1
					format "menuItem mnu_node_% \"%\" \n" cnt aNode[2] to:txt
					format "on mnu_node_% picked do (\n" cnt to:txt
					format "try(max modify mode;modPanel.setCurrentObject ((getNodeByName \"%\").baseobject))catch() \n" aNode[1].name to:txt
					format  ")\n" to:txt
				)				
				if badMatteNodes.count + goodMatteNodes.count > 40 do 
					format "menuItem mnu_node_etcetera \"...And % more objects...\" \n" (badMatteNodes.count + goodMatteNodes.count-40) to:txt
				format  ")\n" to:txt
				Krakatoa_SchematicFlow_RightClickMenus.MatteObjectsNodeRCMenu = execute (txt as string)
		)

		local hasCulling, thePRTLoaders, thePRTVolumes, thePRTSources, PRTLhasDeformations, PRTLhasKCMs, PRTVhasDeformations, PRTVhasKCMs, PRTFhasDeformations, PRTFhasKCMs, PRTShasDeformations, PRTShasKCMs 
		
		fn defineTree =
		(
			Krakatoa_SchematicFlow_Tree = #()
			append Krakatoa_SchematicFlow_Tree #("OK", #(1), #(white, [110,45],false,true),#(120,0), #("",""), undefined, "Error Status Indicator")			
			
			local st1 = timestamp()
			
			local legacyParticles = #(PArray, PCloud, SuperSpray, Blizzard, Snow, Spray)
			local imageBuffers = #()
			local enableNode = false
			local theCacheCount = try(FranticParticles.GetCachedParticleCount())catch(0)
			local theMemory = try(FranticParticles.getCacheSize())catch(0)
			local theSceneLights = for o in objects where findItem light.classes (classof o) > 0 collect o
			local theActiveLights = (for o in theSceneLights where (try(o.on)catch(false)) OR (try(o.enabled)catch(false)) collect o)
			local theActiveVoxelLights = (for o in theActiveLights where  classof o != OmniLight collect o)
			local theActiveOmniLights = (for o in theActiveLights where classof o == OmniLight collect o)
			local lightsAreOff = FranticParticles.getBoolProperty "IgnoreSceneLights" 
				
			local useNamedSelectionSets = execute (FranticParticles.GetProperty "Matte:NamedSelectionSets")
			local matteSelSets = for i = 1 to selectionSets.count where findItem useNamedSelectionSets (getNamedSelSetName i) != 0 collect selectionSets[i]
			local matteObjects = #()
			for i in matteSelSets do 
				join matteObjects (for o in i collect o)				
			local badMattes = #()	
			local goodMattes = #()
				
			--format "Collecting Nodes: % sec.\n" ((timeStamp()-st1)/1000.0)
			
			local txt = stringStream ""
			format "rcmenu LightsNodeRCMenu (\n" to:txt
			format "menuItem mnu_ignoreSceneLights \"Ignore Scene Lights\" checked:(FranticParticles.GetBoolProperty \"IgnoreSceneLights\")\n" to:txt
			
			format "on mnu_ignoreSceneLights picked do (\n" to:txt
			format "FranticParticles.SetProperty \"IgnoreSceneLights\" (not (FranticParticles.GetBoolProperty \"IgnoreSceneLights\")) \n" to:txt
			format "try(Krakatoa_GUI_Main.Refresh_GUI())catch()\n)\n"	 to:txt
			format "separator sep_10 \n" to:txt
			
			if theActiveOmniLights.count > 0 and not lightsAreOff then
			(
				format  "menuItem mnu_disableOmnis \"FIX:Turn Off Omni Lights\"\n" to:txt
				format  "on mnu_disableOmnis picked do ((for o in objects where classof o.baseobject == OmniLight do o.on = off); ::Krakatoa_updateSchematicFlow())\n" to:txt
				format  "separator sep_20 \n" to:txt
			)			
				
			local cnt = 0
			for aLight in theSceneLights do
			(
				cnt+=1
				local theName = if (isProperty aLight #on and aLight.on) or (isProperty aLight #enabled and aLight.enabled) then "+ " else "-- " 
				theName += aLight.name 
				format  "menuItem mnu_light_% \"%\" checked:(%)\n" cnt theName aLight.isSelected to:txt
				format  "on mnu_light_% picked do (\n" cnt to:txt
				format  "try(select (getNodeByName \"%\");max modify mode)catch() \n" aLight.name  to:txt
				format  ")\n" to:txt
			)
			if theSceneLights.count > 0 do 
				format "separator sep_30 \n" to:txt
			
			--if theSceneLights.count == 0 or (theActiveVoxelLights.count== 0)  do 
			(
				format  "menuItem mnu_defaultLight \"Create Default Spotlight\" \n"  to:txt
				format  "on mnu_defaultLight picked do (\n"  to:txt
				format  "local theTarget = TargetObject pos:[0,0,0]\n"  to:txt
				format  "local theSpot = TargetSpot target:theTarget pos:[-1000,0,1000]\n"  to:txt
				format  "theTarget.name = theSpot.name + \".Target\"\n"  to:txt
				format  "try(max modify mode \n select theSpot)catch()\n"  to:txt
				--format  "try(::Krakatoa_updateSchematicFlow())catch()\n"  to:txt
				format  ")\n"  to:txt
				format  "separator sep_40 \n"  to:txt
			)
			
			format  "menuItem mnu_lightLister \"Open Light Lister...\" \n"  to:txt
			format  "on mnu_lightLister picked do macros.run \"Lights and Cameras\" \"Light_List\"\n"  to:txt
			format ")\n"  to:txt
			Krakatoa_SchematicFlow_RightClickMenus.LightsNodeRCMenu = execute (txt as string)
			
			local hasLights = if theActiveLights.count > 0 then 1.0 else 0.5
			/*if showLights do
			(
				append Krakatoa_SchematicFlow_Tree #("Scene Lights", #(), #(color 255  235 225, [110,45],false,true),undefined, #("Light","Light"), #(theOriginX,0), "Illuminate Particles")
			)*/
				
			if (FranticParticles.GetProperty "ParticleMode") == "Save Particles To File Sequence" do
			(
					local theColor = color 255  255 150
					local theInfo = "Saves particle files (.PRT, .CSV or .BIN) to disk."
					if FranticParticles.GetProperty "ParticleFiles" == "" do 
					(
						theColor = red
						theInfo = "ERROR: The Save Particles filename is empty - no files can be saved!"
					)
					append Krakatoa_SchematicFlow_Tree #("Particle File Output", #(Krakatoa_SchematicFlow_Tree.count+2), #(theColor, [110,45],false,true),#(120,0), #("Particles","Particles"), undefined, theInfo)
					

					if FranticParticles.GetBoolProperty "SaveLightingAsEmission" then
					(
						theColor = (color 255 200 255)
						theInfo = "Copies the internal Light channel into the particles' Emission channel to be saved to disk."
						enableNode = not (FranticParticles.GetBoolProperty "IgnoreSceneLights")
						if theActiveLights.count == 0 do
						(
							theColor = color 255 50 50
							theInfo = "WARNING: No light in the scene, no Lighting data will be saved to the Emission channel!"
						)
						if not enableNode do 
						(
							theColor = (color 255 50 50)
							theInfo = "WARNING: Lighting is disabled, no lighting channel will be generated and saved."
						)
						if enableNode or Krakatoa_SchematicFlow_showAllNodes do 
						(
							append Krakatoa_SchematicFlow_Tree #("Light To Emission", #(Krakatoa_SchematicFlow_Tree.count+2), #(theColor, [110,45], false, false), #(120,0) , #("Particles","Particles"), undefined , theInfo )
							append Krakatoa_SchematicFlow_Tree #("Attenuation", #(Krakatoa_SchematicFlow_Tree.count+2), #((color 255 200 150)*(if enableNode then 1 else 0.1), [110,45]), #(120,0) , #("Lit Particles","Particles"), undefined, "Calculates Attenuation of Light as it passes through the particle cloud." )
							append Krakatoa_SchematicFlow_Tree #("Sort For "+theActiveLights.count as string+ (if theActiveLights.count == 1 then " Light" else " Lights"), #(Krakatoa_SchematicFlow_Tree.count+2), #((color 220 220 240)*(if enableNode then 1 else 0.1), [110,45], false, false), #(120,0) , #("Sorted Particles","Particles"), #(0,0,10,0), "Sorts particles relatively to each light source for Attenuation generation." )
						)
					)		
					else append imageBuffers Krakatoa_SchematicFlow_Tree.count	
				
			)
			if (FranticParticles.GetProperty "ParticleMode") == "Light Scene Particles" do
			(
				(
					local hasImageOutput = rendOutputFilename != ""
					local ImageOutputEnabled = rendSaveFile == true 
					local iterativeRendererOff = FranticParticles.getBoolProperty "IterativeRender" == false
					local imageOutputEnabled =(ImageOutputEnabled and hasImageOutput and iterativeRendererOff)
					local particleRendering = (FranticParticles.GetProperty "RenderingMethod") == "Particle Rendering"
					local nodeEnabled = (FranticParticles.GetBoolProperty "EnableAttenuationMapSaving")
					if imageOutputEnabled  or Krakatoa_SchematicFlow_showAllNodes do 
					(
						local theColor = (color 255 255 150)
						if not imageOutputEnabled do theColor = color 255 50 50
						local theInfo = "Saves Attenuation Maps To EXR Files in the \Shadows sub-folder of the current output path."
						if not hasImageOutput then 
							theInfo = "WARNING: Valid Output Image Path must be specified for Attenuation Maps to be saved!"
						else if not ImageOutputEnabled then 
							theInfo = "WARNING: Output Image Saving must be enabled for Attenuation Maps to be saved!"
						
						if not particleRendering do theInfo = "Attenuation Maps are not supported in Voxel Mode."
							
						if nodeEnabled or Krakatoa_SchematicFlow_showAllNodes do 
						(
							append Krakatoa_SchematicFlow_Tree #("Attenuation File", #(Krakatoa_SchematicFlow_Tree.count+2), #(theColor*(if nodeEnabled then 1 else 0.1), [110,45]),#(120,0), #("Pixels","Pixels"), undefined, theInfo )
							--append imageBuffers Krakatoa_SchematicFlow_Tree.count	
						)
					)
					enableNode = not (FranticParticles.GetBoolProperty "IgnoreSceneLights")
					if enableNode or Krakatoa_SchematicFlow_showAllNodes do 
					(
						append Krakatoa_SchematicFlow_Tree #("Attenuation", #(Krakatoa_SchematicFlow_Tree.count+2), #((color 255 200 150)*(if enableNode then 1 else 0.1), [110,45]), #(120,0) , #("Lit Particles","Particles") )
						append Krakatoa_SchematicFlow_Tree #("Sort For "+theActiveLights.count as string+ (if theActiveLights.count == 1 then " Light" else " Lights"), #(Krakatoa_SchematicFlow_Tree.count+2), #((color 220 220 240)*(if enableNode then 1 else 0.1), [110,45], false, false), #(120,0) , #("Sorted Particles","Particles"), #(0,0,10,0), "Sorts particles relatively to each light source for Attenuation generation." )
					)
					
					--append Krakatoa_SchematicFlow_Tree #("Frame Buffer", #(Krakatoa_SchematicFlow_Tree.count+2), #(color 255  255 150, [110,45],true,true),#(120,0), #("Pixels","Pixels"))
					--append imageBuffers Krakatoa_SchematicFlow_Tree.count	
				)
			)			
			
			if (FranticParticles.GetProperty "ParticleMode") == "Render Scene Particles" do
			(
				local imageOutputEnabled =(rendSaveFile == true and rendOutputFilename != "" and FranticParticles.getBoolProperty "IterativeRender" == false)
				
				--RENDER ELEMENTS
				if imageOutputEnabled or Krakatoa_SchematicFlow_showAllNodes do
				(
					local renderElementsList = #()
					local re = maxOps.GetCurRenderElementMgr()
					
					local theColor = color 200 200 255 --(color 255  225 200)
					local theInfo = "The Krakatoa Render Elements can save Renderer, Shader or Custom Channel Data to Images for compositing purposes."
					
					if FranticParticles.GetBoolProperty "AdditiveMode" do 
					(
						theColor = red
						theInfo = "WARNING: Render Elements will contain NO VALID DATA when Force Additive Mode is on!"
					)
					
					local willNotRenderElements = re.NumRenderElements() == 0 or not re.GetElementsActive() --or not imageOutputEnabled --
					if willNotRenderElements then 
						theColor *=0.1
						
					local txt = StringStream ""
					format "rcmenu RenderElementsNodeRCMenu (\n" to:txt
					format "local re = maxOps.GetCurRenderElementMgr()\n" to:txt
					format "menuItem mnu_RenderElementsOn \"Render Elements On\" checked:((maxOps.GetCurRenderElementMgr()).GetElementsActive())\n" to:txt
					
					format "on mnu_RenderElementsOn picked do (\n" to:txt
					
					format "re.SetElementsActive (not re.GetElementsActive()) \n" to:txt
					format "::Krakatoa_updateSchematicFlow()\n" to:txt
					format ")\n" to:txt
					

					if re.NumRenderElements() > 0 do
					(
						format "separator sep_20\n" to:txt
						for i = 0 to (re.NumRenderElements()-1) do 
						(
							local m = re.getRenderElement i
							local theName = m.elementName
							local theInfo2 = case (classof m) of
							(
								default: ("["+theName + "] Render Element")
								Krakatoa_OccludedLayer : ("The ["+theName+"] Render Element outputs the particles occluded by Matte Objects.")
								Krakatoa_Diffuse : ("The ["+theName+"] Render Element outputs the Diffuse component of the Shader.")
								Krakatoa_Specular : ("The ["+theName+"] Render Element outputs the Specular component of the Shader.")
								Krakatoa_Emission : ("The ["+theName+"] Render Element outputs the Emission channel of the particles.")
								Krakatoa_ZDepth : ("The ["+theName+"] Render Element outputs the Z-Depth of the particles in Camera Space.")
								Krakatoa_MatteZDepth : ("The ["+theName+"] Render Element outputs the Z-Depth Buffer generated by the Matte Objects Rasterizer.")
								Krakatoa_CustomData : ("The ["+theName+"] Render Element outputs arbitrary data based on a custom MagmaFlow.")
								Krakatoa_Normal : ("The ["+theName+"] Render Element outputs the Normal channel of the particles.")
								Krakatoa_Tangent : ("The ["+theName+"] Render Element outputs the Tangent channel of the particles.")
								Krakatoa_Velocity : ("The ["+theName+"] Render Element outputs the Velocity channel converted to Screen Space.")
								Krakatoa_SpecificLight : (
									if isValidNode m.lightNode then
										("The ["+theName+"] Render Element outputs the Lighting contribution of ["+m.lightNode.name+"]")
									else
										("The ["+theName+"] Render Element outputs the Lighting contribution of a specified Light, but none has been picked.")
								)
							)
							local theColor2 = (color 255  225 225)
							if m.enabled or Krakatoa_SchematicFlow_showAllNodes do
							(
								if FranticParticles.GetBoolProperty "AdditiveMode" do 
								(
									theColor2 = red			
									theInfo2 = "WARNING: The Render Element will contain NO VALID DATA when Force Additive Mode is on!"
								)
								append Krakatoa_SchematicFlow_Tree #("RE:"+theName, #(), #(theColor2*(if willNotRenderElements then 0.1 else if  m.enabled then 1.0 else 0.3), [110,45],false,true),#(120,0), #("Pixels","Particles"),undefined,theInfo2)
								append renderElementsList Krakatoa_SchematicFlow_Tree.count
							)
							
							format "menuItem mnu_RenderElement_% \"%\" checked:((re.getRenderElement %).enabled)\n" i theName i to:txt
							format "on mnu_RenderElement_% picked do (\n" i to:txt
							format "(re.getRenderElement %).enabled = not (re.getRenderElement %).enabled\n" i i to:txt
							format "::Krakatoa_updateSchematicFlow()\n" to:txt
							format ")\n" to:txt
							
						)
					)
					format "separator sep_50\n" to:txt
					format  "menuItem mnu_OpenRenderElements  \"Open Render Elements Dialog\"\n" to:txt
					format  "on mnu_OpenRenderElements picked do (\n" to:txt
					format  "RenderSceneDialog.open()\n" to:txt
					format  "tabbedDialogs.setCurrentPage #render #(1547006576, 1564889954)\n" to:txt
					format  ")\n" to:txt
					format ")\n" to:txt
					Krakatoa_SchematicFlow_RightClickMenus.RenderElementsRCMenu = execute (txt as string)
					

					
					append Krakatoa_SchematicFlow_Tree #("Render Elements", #(), #(theColor, [110,45],false,true),#(120,0), #("Particles","Particles"),#(theOriginX,60),theInfo)
					append imageBuffers Krakatoa_SchematicFlow_Tree.count
					
					for j in renderElementsList do Krakatoa_SchematicFlow_Tree[j][2] = #(Krakatoa_SchematicFlow_Tree.count)
				)
				
				--VFB
				if rendShowVFB or Krakatoa_SchematicFlow_showAllNodes do
				(
					append Krakatoa_SchematicFlow_Tree #("Frame Buffer", #(), #((color 255  255 150)*(if rendShowVFB then 1 else 0.1), [110,45],false,true),#(120,0), #("Pixels","Particles"),undefined,"Represents the 3ds Max Virtual Frame Buffer (a.k.a. Rendered Frame Window)")
					append imageBuffers Krakatoa_SchematicFlow_Tree.count
				)
					
				
				
				--IMAGE FILE OUTPUT
				if imageOutputEnabled or Krakatoa_SchematicFlow_showAllNodes do
				(
					local theColor = color 255 255 150
					local theInfo = if rendOutputFilename != "" then 
					(
						if rendSaveFile then 
						(
							if FranticParticles.getBoolProperty "IterativeRender" == true then
								("Would save to ["+rendOutputFilename +"] if Iterative Mode were disabled.") 
							else
								("Will save to ["+rendOutputFilename +"]") 
						)
						else
							("Would save to ["+rendOutputFilename +"] if enabled.") 
					)
					else 
						("Would save the render output to an image file if specified.")
					append Krakatoa_SchematicFlow_Tree #("Image File", #(), #(theColor*(if Krakatoa_SchematicFlow_showAllNodes and not imageOutputEnabled then 0.1 else 1), [110,45],true,true),#(120,0), #("Pixels","Particles"), undefined, theInfo)
					append imageBuffers Krakatoa_SchematicFlow_Tree.count
						
					/*	
					enableNode = FranticParticles.GetBoolProperty "Matte:SaveMultipleLayers"							
					if enableNode or 	Krakatoa_SchematicFlow_showAllNodes do
					(
						local theInfo = if rendOutputFilename != "" then 
							if rendSaveFile then 
								if enableNode then
									("Will save the background layer to ["+rendOutputFilename +"]") 
								else
									("Would save the background layer to ["+rendOutputFilename +"] if enabled.") 
							else
								if enableNode then
									("Would save the background layer to ["+rendOutputFilename +"] if Image File saving were enabled.") 
								else
									("Would save the background layer to ["+rendOutputFilename +"] if enabled and if Image File saving were enabled.") 
						else 
							("Would save the background layer of the render output to an EXR file if specified.")						
						append Krakatoa_SchematicFlow_Tree #("Background Image File", #(), #(theColor*(if Krakatoa_SchematicFlow_showAllNodes and (not imageOutputEnabled or not enableNode) then 0.1 else 1), [110,45],true,true),#(120,0), #("Pixels","Particles"), undefined, theInfo)
						append imageBuffers Krakatoa_SchematicFlow_Tree.count							
					)
					*/
				)
				if (FranticParticles.GetProperty "RenderingMethod") == "Particle Rendering" then						
				(
					local enableNode = (FranticParticles.GetBoolProperty "EnableAttenuationMapSaving")
					if (imageOutputEnabled and enableNode ) or Krakatoa_SchematicFlow_showAllNodes do 
					(
						local ImageOutputEnabled = rendSaveFile == true 
						local hasImageOutput = rendOutputFilename != ""
						local theInfo = "Would Save Attenuation Maps To EXR Files in the \Shadows sub-folder of the current output path."
						if enableNode then
						(
							theInfo = "Saves Attenuation Maps To EXR Files in the \Shadows sub-folder of the current output path."
							if not hasImageOutput then 
								theInfo = "WARNING: Valid Output Image Path must be specified for Attenuation Maps to be saved!"
							else if not ImageOutputEnabled then 
								theInfo = "WARNING: Output Image Saving must be enabled for Attenuation Maps to be saved!"
						)
						local theColor = color 255 255 150
						if (Krakatoa_SchematicFlow_showAllNodes and not enableNode) or not imageOutputEnabled do theColor *= 0.1
						append Krakatoa_SchematicFlow_Tree #("Attenuation File", #(), #(theColor, [110,45],true,true),#(120,0), #("Pixels","Particles"), undefined, theInfo)
						append imageBuffers Krakatoa_SchematicFlow_Tree.count
					)
				)
			)
			
			local willRender = if lightsAreOff then 
				(FranticParticles.GetBoolProperty "UseEmissionColor" or FranticParticles.GetBoolProperty "AdditiveMode") 
			else
				(theActiveLights.count > 0 or FranticParticles.GetBoolProperty "UseEmissionColor" or FranticParticles.GetBoolProperty "AdditiveMode") --and theActiveOmniLights.count == 0
			
			
			if (FranticParticles.GetProperty "RenderingMethod") == "Particle Rendering" then
			(
				if (FranticParticles.GetProperty "ParticleMode") == "Light Scene Particles" do
				(
					imageBuffers = #()					
					append Krakatoa_SchematicFlow_Tree #("RENDER PARTICLES", #(), #((color 200 220 255)*0.5, [110,45], false, true), undefined, #("",""), #(theOriginX,0,theOriginX,0), "No particles will be rendered in this mode, only Attenuation Maps will be saved." )
					Krakatoa_SchematicFlow_Tree[Krakatoa_SchematicFlow_Tree.count][2] = #(Krakatoa_SchematicFlow_Tree.count+1)
				)
				if (FranticParticles.GetProperty "ParticleMode") == "Save Particles To File Sequence" do
				(
					imageBuffers = #()					
					append Krakatoa_SchematicFlow_Tree #("SAVE PARTICLES", #(), #((color 200 220 255)*0.5, [110,45], false, true), undefined, #("",""), #(theOriginX,0,theOriginX,0), "No particles will be rendered in this mode, only Particle Files will be saved." )
					Krakatoa_SchematicFlow_Tree[Krakatoa_SchematicFlow_Tree.count][2] = #(Krakatoa_SchematicFlow_Tree.count+1)
				)				
				
				if (FranticParticles.GetProperty "ParticleMode") == "Render Scene Particles" do
				(
					local theInfo = if willRender then 
					(
						if lightsAreOff then
							"Lights are off, will Sort and Render the particles without Sorting for Lights." 
						else
							"Will Sort and calculate Attenuation Once per Light, then Sort and Render from Back to Front in Camera space." 
					)
					else 
						if lightsAreOff then
						"WARNING: Particles will render BLACK RGB unless '>Ignore Scene Lights' is unchecked or either '>Use Emission' or '>Force Additive Mode' is checked."
						else
						"WARNING: Particles will render BLACK RGB unless at least one Light is created or either '>Use Emission' or '>Force Additive Mode' is checked."
					
					--local theColor = color 200 220 255
					append Krakatoa_SchematicFlow_Tree #("RENDER PARTICLES", #(Krakatoa_SchematicFlow_Tree.count+2), #((if willRender then (color 200 220 255) else (color 255 50 50)), [110,45], false, true), undefined, #("Particles","Particles"), #(theOriginX,0,theOriginX,0), theInfo )
					for j in imageBuffers do Krakatoa_SchematicFlow_Tree[j][2] = #(Krakatoa_SchematicFlow_Tree.count)						
					imageBuffers = #()
				)
			)
			else
			(
				local theColor = (color 200 220 255) 
				local theInfo = ""
				if theActiveOmniLights.count > 0 and not lightsAreOff then 
				(
					theInfo = "ERROR: There are active Omni Lights in the scene, Voxel Mode will fail until they are turned off or removed." 
					theColor = (color 255 50 50)
				)
				else if willRender then 
				(
					if lightsAreOff then
						theInfo = "Lights are off, will Render the Voxel Grid once, one Slice Plane at a time, oriented im camera space." 
					else
						theInfo = "Will Render the Voxel Grid once per light, one Planar Slice at a time, oriented halfway between camera and light ." 
				)
				else 
				(
					theColor = color 255 50 50
					theInfo = "WARNING: Voxel Mode will NOT render unless at least one Light is active or Emission or Force Additive Mode is enabled."
				)
				
				if (FranticParticles.GetProperty "ParticleMode") == "Save Particles To File Sequence" do
				(
					imageBuffers = #()					
					local theInfo = "No particles will be rendered in this mode, only Particle Files will be saved."
					local theColor = (color 200 220 255)
					if FranticParticles.GetBoolProperty "SaveLightingAsEmission" do 
					(
						theInfo = "ERROR: No Lighting can be saved to the Emission channel in Voxel mode since no Lighting channel is allocated."						
						theColor = red
					)
					append Krakatoa_SchematicFlow_Tree #("SAVE PARTICLES", #(), #(theColor, [110,45], false, true), undefined, #("",""), #(theOriginX,0,theOriginX,0), theInfo )
					Krakatoa_SchematicFlow_Tree[Krakatoa_SchematicFlow_Tree.count][2] = #(Krakatoa_SchematicFlow_Tree.count+1)
				)
				
				if (FranticParticles.GetProperty "ParticleMode") == "Light Scene Particles" do
				(
					imageBuffers = #()					
					append Krakatoa_SchematicFlow_Tree #("LIGHT PARTICLES", #(), #((color 200 220 255), [110,45], false, true), undefined, #("",""), #(theOriginX,0,theOriginX,0), "No particles will be rendered, only Attenuation Maps will be saved." )
					Krakatoa_SchematicFlow_Tree[Krakatoa_SchematicFlow_Tree.count][2] = #(Krakatoa_SchematicFlow_Tree.count+1)
				)				
				
				if (FranticParticles.GetProperty "ParticleMode") == "Render Scene Particles" do
				(
					append Krakatoa_SchematicFlow_Tree #("RENDER VOXELS", #(Krakatoa_SchematicFlow_Tree.count+2), #(theColor, [110,45], false, true), undefined, #("Pixels","Voxels"), #(theOriginX,0), theInfo )
					for j in imageBuffers do Krakatoa_SchematicFlow_Tree[j][2] = #(Krakatoa_SchematicFlow_Tree.count)						
					imageBuffers = #()

					enableNode =(FranticParticles.GetBoolProperty "UseEnvironmentReflections") 
					if enableNode or Krakatoa_SchematicFlow_showAllNodes do 
					(
						local theColor = (color 255 200 150)  
						local theInfo = "Calculates an additional light source from the 3ds Max Environment Map using texel lookup along the particle normals."
						if enableNode and environmentMap == undefined do 
						(
							theColor = (color 255 50 50)
							theInfo = "WARNING: No Environment Reflections will be rendered because the Environment Map is not defined in the 3ds Max Environment Dialog."
						)
						append Krakatoa_SchematicFlow_Tree #("Env.Reflection Pass", #(Krakatoa_SchematicFlow_Tree.count+2), #(theColor*(if enableNode then 1 else 0.1), [110,45]), #(120,0) , #("Lit Voxels","Voxels"), undefined, theInfo )
					)
						
					enableNode = not (FranticParticles.GetBoolProperty "IgnoreSceneLights")
					if enableNode or Krakatoa_SchematicFlow_showAllNodes do 
					(
						local theInfo = ""
						local theColor = (color 255 200 150)
						if theActiveVoxelLights.count == 0 then 
						(
							theColor = color 255 50 50
							theInfo = ("WARNING: There are no valid lights in the scene. " +(if theActiveOmniLights.count > 0 then "There are only Omni lights which are not supported in Voxel Mode." else "" ))
						)
						else if theActiveOmniLights.count > 0 then 
						(
							theColor = red
							theInfo = "WARNING: There are Omni Lights in the scene. The Voxel Rendering will FAIL until they are disabled/removed." 
						)
						else
						(
							theInfo = "One pass per active light will be rendered."
						)
						append Krakatoa_SchematicFlow_Tree #(theActiveVoxelLights.count as string + (if theActiveVoxelLights.count == 1 then " Light Pass" else " Light Passes"), #(Krakatoa_SchematicFlow_Tree.count+2), #(theColor*(if theActiveVoxelLights.count > 0 then 1 else 0.5)*(if enableNode then 1.0 else 0.1), [110,45]), #(120,0) , #("Lit Voxels","Voxels"), undefined, theInfo )
							
					)
					append Krakatoa_SchematicFlow_Tree #("Particles To Grid", #(Krakatoa_SchematicFlow_Tree.count+2), #(color 200 200 255, [110,45] ), #(120,0) , #("Voxels","Particles"), undefined, "Particles are being loaded onto the Grid for rendering. Cannot be turned off." )
				)						
			)
			
			if (FranticParticles.GetProperty "ParticleMode") == "Render Scene Particles" do	
			(
				enableNode = FranticParticles.GetBoolProperty "Matte:UseMatteObjects"
				theInfo = "Occludes particles behind geometry objects specified using Named Selection Sets."
				local theColor = (color 200 200 220)
				badMattes = #()
				for o in matteObjects do
				(
					theLayer = o.layer 
					if o.renderable == false then 
						append badMattes #(o,"["+o.name +"] Renderable is Off - Won't Render!")
					else if o.primaryVisibility == false then
						append badMattes #(o,"["+o.name +"] 'Visible To Camera' is Off - Won't Render!")
					else if o.isHidden then 
						append badMattes #(o,"["+o.name +"] Is Hidden - Won't Render!")
					else if not theLayer.on then 
						append badMattes #(o,"["+o.name +"] Is on a Disabled Layer - Won't Render!")
					else if not theLayer.renderable then 
						append badMattes #(o,"["+o.name +"] Is on a Non-Renderable Layer - Won't Render!")
					else if theLayer.isHidden then 
						append badMattes #(o,"["+o.name +"] Is on a Hidden Layer - Won't Render!")
					else if not theLayer.primaryVisibility then
						append badMattes #(o,"["+o.name +"] Is on a Layer with 'Visible To Camera' Off - Won't Render!")
					else if o.isHiddenInVpt then
						append badMattes #(o,"["+o.name +"] Is Frozen and Hide Frozen is On - Won't Render!")
					else 
						append goodMattes #(o,"["+o.name +"] - OK")
				)
				if badMattes.count > 0 do
				(
					theColor = red
					if enableNode do theInfo = "WARNING: Some Matte Objects Will Not Render! Right-Click 'Objects Matte' node for details..."
				)
				
				if enableNode or Krakatoa_SchematicFlow_showAllNodes do
					append Krakatoa_SchematicFlow_Tree #("Objects Matte", #(Krakatoa_SchematicFlow_Tree.count+2), #(theColor*(if enableNode then 1 else 0.1) , [110,45]), #(120,0) , #("Matted Particles","Particles"), undefined, theInfo  )
				
				defineMatteMenu badMattes goodMattes
				
				enableNode = FranticParticles.GetBoolProperty "Matte:UseDepthMapFiles"
				if enableNode or Krakatoa_SchematicFlow_showAllNodes do
				(
					local theColor = (color 200 200 220)
					local theInfo = "Loads a sequence of Z-Depth files as initial value of the Matte buffer. Useful for matting out by rendertime-generated geometry from other renderers."
					local theFiles = FranticParticles.GetProperty "Matte:DepthMapFiles" 
					
					if theFiles == "" then
					(
						theColor = red
						if enableNode do theInfo = "ERROR: No Depth Matte Files have been specified. The Rendering will FAIL!"
					)
					else
					(
						if not (doesFileExist theFiles) then
						(
							theColor = red
							if enableNode do theInfo = "WARNING: The specified Depth Matte File could not be found."
						)
					)
					append Krakatoa_SchematicFlow_Tree #("Depth Map Matte", #(Krakatoa_SchematicFlow_Tree.count+2), #(theColor*(if enableNode then 1 else 0.1), [110,45]), #(120,0) , #("Matted Particles","Particles"), undefined, theInfo )
				)

				enableNode = FranticParticles.GetBoolProperty "PME:UseExtinction"
				if enableNode or Krakatoa_SchematicFlow_showAllNodes do
					append Krakatoa_SchematicFlow_Tree #("Ambient PME", #(Krakatoa_SchematicFlow_Tree.count+2), #((color 255 200 150)*(if enableNode then 1 else 0.1), [110,45]), #(120,0) , #("Extinct Particles","Particles"), undefined, "Calculates Color Extinction based on a Participating Medium other than the Particles themselves."  )

				if (FranticParticles.GetProperty "RenderingMethod") == "Particle Rendering" then	
				(						
					enableNode =(FranticParticles.GetBoolProperty "UseEnvironmentReflections") 
					if enableNode or Krakatoa_SchematicFlow_showAllNodes do 
					(
						local theColor = (color 255 200 150)
						local theInfo = "Looks up colors from the 3ds Max Environment Map along the Particle Normals as an additional light source."
						if environmentMap == undefined do 
						(
							theColor = (color 255 0 0)
							if enableNode do theInfo = "WARNING: No Environment Reflections will be rendered because the Environment Map is not defined in the 3ds Max Environment dialog."
						)
						append Krakatoa_SchematicFlow_Tree #("Env.Reflections", #(Krakatoa_SchematicFlow_Tree.count+2), #(theColor*(if enableNode then 1 else 0.1), [110,45]), #(120,0) , #("Lit Particles","Particles"), undefined, theInfo )
					)
				)
				
				enableNode =	FranticParticles.GetBoolProperty "EnableDepthOfField" 
				if enableNode or Krakatoa_SchematicFlow_showAllNodes do 	
				(
					local theColor = (color 200 220 255)
					local theCamera = viewport.getCamera() 
					local theInfo = "Calculates a Depth Of Field effect. Requires Krakatoa Camera modifier on the current Camera to provide an f-stop value." 
					
					if theCamera == undefined then
					(
						theColor = red
						if enableNode do theInfo = "WARNING: No Depth Of Field effect will be rendered because the view is not a Camera with a Krakatoa Camera Modifier."
					)
					else
					(
						if (for m in theCamera.modifiers where classof m == KrakatoaCameraModifier collect m).count == 0 do
						(
							theColor = red
							if enableNode do theInfo = "WARNING: No DOF effect will be rendered - the current Camera does not have a Krakatoa Camera Modifier to provide the f-stop value."
						)
					)

					append Krakatoa_SchematicFlow_Tree #("Depth Of Field", #(Krakatoa_SchematicFlow_Tree.count+2), #(theColor*(if enableNode then 1 else 0.1), [110,45]), #(120,0) , #("Sample Rate:"+((floor((FranticParticles.GetFloatProperty "DepthOfFieldSampleRate")*100))/100) as string,"Particles"), undefined, theInfo)
				)
				
				local theShadingMode = FranticParticles.GetProperty "PhaseFunction"
				append Krakatoa_SchematicFlow_Tree #(theShadingMode , #(Krakatoa_SchematicFlow_Tree.count+2), #((color 255 200 150), [110,45], false, true), #(120,0) , #("Shaded Particles" ,"Particles"), undefined, "Performs Shading Based On the Selected Phase Function.") --#(theOriginX,60) 
				

				enableNode = FranticParticles.GetBoolProperty "EnableMotionBlur" 
				if enableNode or Krakatoa_SchematicFlow_showAllNodes do 	
				(
					local mblurPasses = FranticParticles.GetIntProperty "MotionBlurSegments" 
					local useMatteSegments = FranticParticles.GetBoolProperty "UseMatteMotionBlurSegments"
					local mattePasses = if useMatteSegments then FranticParticles.GetIntProperty "MatteMotionBlurSegments" else mblurPasses 
					if mattePasses > mblurPasses do mattePasses = mblurPasses
					append Krakatoa_SchematicFlow_Tree #(mblurPasses as string+ "/" +mattePasses as string  + (if mblurPasses == 1 then " Pass" else " Passes") +" MBlur "+(if FranticParticles.GetBoolProperty "JitteredMotionBlur" then "J" else "")+(if FranticParticles.GetBoolProperty "DeformationMotionBlur" then "G" else "") , #(Krakatoa_SchematicFlow_Tree.count+2), #((color 255 200 225)*(if enableNode then 1 else 0.1), [110,45], false, true), #(120,0) , #("Shttr:"+(FranticParticles.GetFloatProperty "ShutterAngleInDegrees") as string+ " Bias:"+ (floor ((FranticParticles.GetFloatProperty "ShutterBias")*100)/100) as string  ,"Particles"), undefined, "Causes the Rendering of Multiple Passes to produce a Motion Blur Effect.") --#(theOriginX,60) 
				)
					
				local ignoreSceneLights = (FranticParticles.GetBoolProperty "IgnoreSceneLights")
				if not ignoreSceneLights and theCacheCount > 0 and FranticParticles.GetBoolProperty "EnableLightingCache" and (FranticParticles.GetProperty "RenderingMethod") == "Particle Rendering" then
				(
					append Krakatoa_SchematicFlow_Tree #("LIGHTING CACHE", #(Krakatoa_SchematicFlow_Tree.count+2), #((color 200 255 255), [110,45], false,true), #(120,0) , #(FranticParticleRenderMXS.addCommas (theCacheCount as string) + " Prts ","Particles"), #(theOriginX,60), "Stores the last content of the Lighting channel in Particle Mode" )
				)
				else
				(
					if (FranticParticles.GetProperty "RenderingMethod") == "Particle Rendering" then		
					(
						append Krakatoa_SchematicFlow_Tree #("Sort For View", #(Krakatoa_SchematicFlow_Tree.count+2), #((color 220 230 250), [110,45]), #(120,0) , #("Sorted Particles","Particles"), undefined, "Sorts the particles back to front relatively to the current view." )
						
						local txt = stringStream ""
						format "rcmenu ViewsNodeRCMenu (\n" to:txt
						local cnt = 0
						local theSceneCameras=for o in objects where findItem Camera.classes (classof o) != 0 collect o
						for aCamera in theSceneCameras do
						(
							cnt+=1
							local theName = aCamera.name 
							format  "menuItem mnu_camera_% \"%\" checked:(%)\n" cnt theName (viewport.getCamera() == aCamera) to:txt
							format  "on mnu_camera_% picked do (\n" cnt to:txt
							format  "try(select (getNodeByName \"%\");max modify mode;viewport.setCamera (getNodeByName \"%\") )catch() \n" aCamera.name  aCamera.name  to:txt
							format  ")\n" to:txt
						)
						if cnt > 0 do format "separator sep_01\n" to:txt
						format  "menuItem mnu_camerafromview \"Camera From View\" enabled:(viewport.getCamera() == undefined)\n" to:txt
						format  "on mnu_camerafromview picked do\n" to:txt
						format  "macros.run \"Lights and Cameras\" \"Camera_CreateFromView\"\n" to:txt
						format ")\n" to:txt
						Krakatoa_SchematicFlow_RightClickMenus.ViewsNodeRCMenu = execute (txt as string)
						
						if (not ignoreSceneLights and theActiveLights.count > 0) or Krakatoa_SchematicFlow_showAllNodes do
						(
							append Krakatoa_SchematicFlow_Tree #("Attenuation", #(Krakatoa_SchematicFlow_Tree.count+2), #((color 255 200 150)*hasLights*(if not ignoreSceneLights then 1 else 0.1), [110,45]), #(120,0) , #("Lit Particles","Particles"), undefined, "Calculates Light Attenuation Map For Each Light" )
							append Krakatoa_SchematicFlow_Tree #("Sort For "+theActiveLights.count as string+ (if theActiveLights.count == 1 then " Light" else " Lights"), #(Krakatoa_SchematicFlow_Tree.count+2), #((color 220 220 240)*hasLights*(if not ignoreSceneLights then 1 else 0.1), [110,45]), #(120,0) , #("Sorted Particles","Particles"), #(0,0,120,0), "Sorts particles relatively to each light source for Attenuation generation." ) --#(0,0,theOriginX,0)
						)
					)
				)
			)
			


			if theCacheCount > 0 and FranticParticles.GetBoolProperty "EnableParticleCache" then
			(
				append Krakatoa_SchematicFlow_Tree #("PARTICLE CACHE", #(Krakatoa_SchematicFlow_Tree.count+2), #(color 200 255 255, [110,45], false, true), undefined, #(FranticParticleRenderMXS.addCommas (theCacheCount as string) + " Prts",(theMemory as string) + " MB"), #(theOriginX,0), "The Particle Cache freezes the content of the Memory Pool and allows the fast re-rendering of the loaded particles." )
			)
			else
			(
				local theInfo = "The Memory Pool collects all particles scheduled for lighting"
				local theColor = color 200 255 255 
				if (FranticParticles.GetProperty "ParticleMode") == "Render Scene Particles" do theInfo += " and rendering."
				
				if (FranticParticles.GetProperty "ParticleMode") == "Save Particles To File Sequence" do 
				(
					if FranticParticles.GetBoolProperty "SaveLightingAsEmission" then 
						theInfo = "The Memory Pool will be used during saving because Lighting is scheduled to be saved as Emission channel."						
					else 
					(
						theInfo = "The Memory Pool will not be used when saving particles."
						theColor *= 0.5
					)
				)
				
				append Krakatoa_SchematicFlow_Tree #("MEMORY POOL", #(Krakatoa_SchematicFlow_Tree.count+2), #(theColor, [110,45], false, true), undefined, #(FranticParticleRenderMXS.addCommas (theCacheCount as string) + " Prts", (if theMemory > 0 then  (theMemory as string) + " MB" else "Particles")), #(theOriginX,0), theInfo )
				theMemoryPoolIndex = Krakatoa_SchematicFlow_Tree.count
				for j in imageBuffers do Krakatoa_SchematicFlow_Tree[j][2] = #(Krakatoa_SchematicFlow_Tree.count)
					
				local theShadingMode = FranticParticles.GetProperty "PhaseFunction"
				if matchPattern theShadingMode pattern:"Phong*" do
				(
					enableNode = FranticParticles.GetBoolProperty "Channel:Allocate:SpecularLevel" 
					append Krakatoa_SchematicFlow_Tree #("Use SpecularLevel", #(Krakatoa_SchematicFlow_Tree.count+2), #((color 255 200 150)*(if enableNode then 1 else 0.1), [110,45]), #(120,0) , #("Particles" ,"Particles"), undefined, "Allocates SpecularLevel Channel for Phong Shading.")
					enableNode = FranticParticles.GetBoolProperty "Channel:Allocate:SpecularPower" 					
					append Krakatoa_SchematicFlow_Tree #("Use SpecularPower", #(Krakatoa_SchematicFlow_Tree.count+2), #((color 255 200 150)*(if enableNode then 1 else 0.1), [110,45]), #(120,0) , #("Particles" ,"Particles"), undefined, "Allocates SpecularPower Channel for Phong Shading.")
				)
				
				if matchPattern theShadingMode pattern:"Henyey*" or matchPattern theShadingMode pattern:"Schlick" do
				(
					enableNode = FranticParticles.GetBoolProperty "Channel:Allocate:PhaseEccentricity" 
					append Krakatoa_SchematicFlow_Tree #("Use PhaseEccentricity", #(Krakatoa_SchematicFlow_Tree.count+2), #((color 255 200 150)*(if enableNode then 1 else 0.1), [110,45]), #(120,0) , #("Particles" ,"Particles"), undefined, "Allocates PhaseEccentricity Channel for Henyey-Greenstein or Schlick Shading.")
				)					
					
				enableNode = FranticParticles.GetBoolProperty "UseFilterColor" --or FranticParticles.GetBoolProperty "AdditiveMode"
				if enableNode or Krakatoa_SchematicFlow_showAllNodes do 
					append Krakatoa_SchematicFlow_Tree #("Use Absorption", #(Krakatoa_SchematicFlow_Tree.count+2), #((color 255 200 150)*(if enableNode then 1 else 0.1), [110,45],false,true), #(120,0) , #("Shaded Particles","Particles"), undefined, "Allocates the Absorption channel which causes light to be attenuated independently in R,G and B as it passes through dense particles." )
				
				enableNode =FranticParticles.GetBoolProperty "UseEmissionColor" --or FranticParticles.GetBoolProperty "AdditiveMode"
				if enableNode or Krakatoa_SchematicFlow_showAllNodes do 
					append Krakatoa_SchematicFlow_Tree #("Use Emission", #(Krakatoa_SchematicFlow_Tree.count+2), #((color 255 200 150)*(if enableNode then 1 else 0.1), [110,45]), #(120,0) , #("Emissive Particles","Particles"), undefined, "Allocates the Emission channel which makes the particles render as self-illuminated even when no scene lights are present." )
					
				enableNode =	FranticParticles.GetBoolProperty "AdditiveMode"
				if enableNode or Krakatoa_SchematicFlow_showAllNodes do 
					append Krakatoa_SchematicFlow_Tree #("Force Additive Mode", #(Krakatoa_SchematicFlow_Tree.count+2), #((color 255 200 150)*(if enableNode then 1 else 0.1), [110,45]), #(120,0) , #("Clr->Emiss;0->Abs","Particles"), undefined, "Forces Additive Rendering by enabling internally the Emission and Absorption channel and copying the Color into the Emission while setting Absorption to Black." )
				
					
				enableNode =FranticParticles.GetBoolProperty "DensityOverride:Enabled"
				if enableNode or Krakatoa_SchematicFlow_showAllNodes do 
					append Krakatoa_SchematicFlow_Tree #("Density Override", #(Krakatoa_SchematicFlow_Tree.count+2), #((color 255 200 200)*(if enableNode then 1 else 0.1) , [110,45],false,false), #(120,0),#("Density Channel","Particles"), #(theOriginX,60), "The Density Channel Override REPLACES the density value in all particles being loaded regardless of their source.")
				
				enableNode =FranticParticles.GetBoolProperty "AbsorptionOverride:Enabled"
				if enableNode or Krakatoa_SchematicFlow_showAllNodes do 
					append Krakatoa_SchematicFlow_Tree #("Absorption Override", #(Krakatoa_SchematicFlow_Tree.count+2), #((color 255 200 200)*(if enableNode then 1 else 0.1) , [110,45],false,false), #(120,0), #("Absorption Chnl","Particles"), undefined, "The Absorption Channel Override REPLACES the absorption value in all particles being loaded regardless of their source.")

				enableNode =FranticParticles.GetBoolProperty "EmissionOverride:Enabled"
				if enableNode or Krakatoa_SchematicFlow_showAllNodes do 
					append Krakatoa_SchematicFlow_Tree #("Emission Override", #(Krakatoa_SchematicFlow_Tree.count+2), #((color 255 200 200)*(if enableNode then 1 else 0.1) , [110,45],false,false), #(120,0), #("Emission Channel","Particles"), undefined, "The Emission Channel Override REPLACES the emission value in all particles being loaded regardless of their source.")
				
				enableNode =FranticParticles.GetBoolProperty "ColorOverride:Enabled" 
				if enableNode or Krakatoa_SchematicFlow_showAllNodes do 
					append Krakatoa_SchematicFlow_Tree #("Color Override", #(Krakatoa_SchematicFlow_Tree.count+2), #((color 255 200 200)*(if enableNode then 1 else 0.1) , [110,45],false,false), #(120,0), #("Color Channel","Particles"), undefined, "The Color Channel Override REPLACES the color value in all particles being loaded regardless of their source.")

				enableNode =FranticParticles.GetProperty "GlobalDataHolder" != ""
				if enableNode or Krakatoa_SchematicFlow_showAllNodes do 
					append Krakatoa_SchematicFlow_Tree #("Channel Override", #(Krakatoa_SchematicFlow_Tree.count+2), #((color 255 200 200)*(if enableNode then 1 else 0.1) , [110,45]), #(120,0), #("Channels","Channels"), undefined, "The Global Channel Override runs Krakatoa Channels Modifiers on all particles being loaded regardless of their source.")
					
				local theHolders = (for o in objects where try(classof o.baseobject == KrakatoaGlobalDataHolder)catch(false) collect o) 
				local theHolderNames = join #("") (for o in theHolders collect o.name)
				local theHolderDisplay = join #("--Disable Global Channel Overrides--") (for o in theHolders collect o.name)	
				local txt = StringStream ""
				format "rcmenu ChannelOverrideNodeRCMenu (\n" to:txt
				for i = 1 to theHolderNames.count do
				(
					format "menuItem mnu_globalHolder% \"%\" checked:(\"%\"==\"%\")\n" i theHolderDisplay[i] theHolderNames[i] (FranticParticles.GetProperty "GlobalDataHolder") to:txt
					format "on mnu_globalHolder% picked do \n(" i to:txt
					format "FranticParticles.SetProperty \"GlobalDataHolder\" \"%\"\n" theHolderNames[i] to:txt
					format "try(if Krakatoa_GUI_RenderGlobalValues.open do Krakatoa_GUI_RenderGlobalValues.refresh_GUI())catch()\n" to:txt
					format "try(if Krakatoa_VFB_Left_Rollout.open do Krakatoa_VFB_Left_Rollout.refresh_GUI())catch()\n" to:txt
					format "try(select (getNodeByName \"%\"))catch()\n" theHolderNames[i] to:txt
					format "::Krakatoa_updateSchematicFlow()\n" to:txt
					format ")\n" to:txt
				)	
				format "separator sep_10\n" to:txt
				format "menuItem mnu_addSet \"Create New Channel Override Set...\" \n"	to:txt
				format "on mnu_addSet picked do (\n" to:txt
				format "try(Krakatoa_GUI_RenderGlobalValues.createNewOverrideSet()\n" to:txt
				format "if Krakatoa_GUI_RenderGlobalValues.open do Krakatoa_GUI_RenderGlobalValues.refresh_GUI()\n" to:txt
				format ")catch()\n" to:txt
				format "::Krakatoa_updateSchematicFlow()\n" to:txt
				format ")\n)\n" to:txt
				
				Krakatoa_SchematicFlow_RightClickMenus.ChannelOverrideNodeRCMenu = execute (txt as string)
				
				append Krakatoa_SchematicFlow_Tree #("Material", #(), #(color 200 200 255, [110,45],false,true),undefined, #("Shaded Particles","Particles"), #(theOriginX-(if Krakatoa_SchematicFlow_showAllNodes then 210 else 0),10), "The Material is applied after the modifier stack and overwrites Color, Density, Absorption and Emission unless explicitly unchecked in a Krakatoa Material." )
				local theMatRoot = Krakatoa_SchematicFlow_Tree.count
					
				local st1 = timestamp()
				
				hasCulling = (for o in getClassInstances KrakatoaPRTLoader where o.useCullingGizmo collect o).count > 0 and FranticParticles.GetBoolProperty "RenderKrakatoaLoaders" 
				thePRTLoaders = for o in objects where classof o == KrakatoaPRTLoader collect o --and not o.isHiddenInVpt and o.renderable and o.baseobject.enabledInRender 
				thePRTVolumes = for o in objects where classof o == PRT_Volume collect o  --and not o.isHiddenInVpt and o.renderable
				thePRTSurfaces = for o in objects where classof o == PRT_Surface collect o  --and not o.isHiddenInVpt and o.renderable
					
				thePRTSources = for o in objects where classof o == PRT_Source collect o  --and not o.isHiddenInVpt and o.renderable
				thePRTFumes = for o in objects where classof o == PRT_FumeFX collect o  --and not o.isHiddenInVpt and o.renderable
				thePRTField = for o in objects where classof o == PRT_Field collect o  --and not o.isHiddenInVpt and o.renderable

				PRTLhasDeformations = (for o in thePRTLoaders where (for m in o.modifiers where (classof m == KrakatoaChannelsModifier or classof m == MagmaModifier) and m.enabled collect m).count > 0 collect o).count > 0 and FranticParticles.GetBoolProperty "RenderKrakatoaLoaders" 
				PRTLhasKCMs = (for o in thePRTLoaders where (for m in o.modifiers where (classof m == KrakatoaChannelsModifier or classof m == MagmaModifier) and m.enabled collect m).count > 0 collect o).count > 0 and FranticParticles.GetBoolProperty "RenderKrakatoaLoaders" 
				PRTVhasDeformations = (for o in thePRTVolumes where (for m in o.modifiers where (classof m == KrakatoaChannelsModifier or classof m == MagmaModifier) and m.enabled collect m).count > 0 collect o).count > 0 and FranticParticles.GetBoolProperty "RenderGeometryVolumes" 
				PRTVhasKCMs = (for o in thePRTVolumes where (for m in o.modifiers where (classof m == KrakatoaChannelsModifier or classof m == MagmaModifier) and m.enabled collect m).count > 0 collect o).count > 0 and FranticParticles.GetBoolProperty "RenderGeometryVolumes" 
				PRTShasDeformations = (for o in thePRTSources where (for m in o.modifiers where (classof m == KrakatoaChannelsModifier or classof m == MagmaModifier) and m.enabled collect m).count > 0 collect o).count > 0 and FranticParticles.GetBoolProperty "RenderKrakatoaLoaders" 
				PRTShasKCMs = (for o in thePRTSources where (for m in o.modifiers where (classof m == KrakatoaChannelsModifier or classof m == MagmaModifier) and m.enabled collect m).count > 0 collect o).count > 0 and FranticParticles.GetBoolProperty "RenderKrakatoaLoaders" 

				PRTSurfHasDeformations = (for o in thePRTSurfaces where (for m in o.modifiers where (classof m == KrakatoaChannelsModifier or classof m == MagmaModifier) and m.enabled collect m).count > 0 collect o).count > 0 and FranticParticles.GetBoolProperty "RenderPRTSurface" 
				PRTSurfHasKCMs = (for o in thePRTSurfaces where (for m in o.modifiers where (classof m == KrakatoaChannelsModifier or classof m == MagmaModifier) and m.enabled collect m).count > 0 collect o).count > 0 and FranticParticles.GetBoolProperty "RenderPRTSurface" 
				
				PRTFhasDeformations = (for o in thePRTFumes where (for m in o.modifiers where (classof m == KrakatoaChannelsModifier or classof m == MagmaModifier) and m.enabled collect m).count > 0 collect o).count > 0 and FranticParticles.GetBoolProperty "RenderFumeFX" 
				PRTFhasKCMs = (for o in thePRTFumes where (for m in o.modifiers where (classof m == KrakatoaChannelsModifier or classof m == MagmaModifier) and m.enabled collect m).count > 0 collect o).count > 0 and FranticParticles.GetBoolProperty "RenderFumeFX" 

				PRTEhasDeformations = (for o in thePRTField where (for m in o.modifiers where (classof m == KrakatoaChannelsModifier or classof m == MagmaModifier) and m.enabled collect m).count > 0 collect o).count > 0 and FranticParticles.GetBoolProperty "RenderPRTField" 
				PRTEhasKCMs = (for o in thePRTField where (for m in o.modifiers where (classof m == KrakatoaChannelsModifier or classof m == MagmaModifier) and m.enabled collect m).count > 0 collect o).count > 0 and FranticParticles.GetBoolProperty "RenderPRTField" 
				
				if hasCulling or PRTLhasDeformations or PRTLhasKCMs or PRTVhasDeformations or PRTVhasKCMs do Krakatoa_SchematicFlow_Tree[theMatRoot][2] = #(Krakatoa_SchematicFlow_Tree.count+1)
					
				if hasCulling or Krakatoa_SchematicFlow_showAllNodes do 
				(
					append Krakatoa_SchematicFlow_Tree #("Culling", #(Krakatoa_SchematicFlow_Tree.count+2), #((color 200 200 255)*(if hasCulling then 1 else 0.1), [110,45],false, false), #(120,0),  #("Culled Particles","Particles"), undefined, "Particle Culling is performed by a PRT Loader after the stack evaluation by testing positions against the volumes of specified geometry objects." )
					theCullingRoot = Krakatoa_SchematicFlow_Tree.count
				)
				if PRTLhasDeformations or PRTVhasDeformations or PRTFhasDeformations or Krakatoa_SchematicFlow_showAllNodes do 
				(
					append Krakatoa_SchematicFlow_Tree #("Deformations", #(Krakatoa_SchematicFlow_Tree.count+2), #((color 200 200 255)*(if PRTLhasDeformations or PRTVhasDeformations or PRTFhasDeformations then 1 else 0.1), [110,45],false, false), #(120,0) , #("Deformed Particles","Particles"), undefined, "Deformation Modifiers and Space Warps are applied to the stack of PRT objects and affect the Position, Velocity and Normal channels." )
					theDeformRoot = Krakatoa_SchematicFlow_Tree.count
				)
				
				if PRTLhasKCMs or PRTVhasKCMs or PRTFhasKCMs or PRTSurfHasKCMs or Krakatoa_SchematicFlow_showAllNodes do 
				(
					append Krakatoa_SchematicFlow_Tree #("Local KCMs", #(), #((color 200 200 255)*(if PRTLhasKCMs or PRTVhasKCMs or PRTFhasKCMs then 1 else 0.1), [110,45],false, false), #(120,0),  #("Modified Channels","Particles"), undefined, "Local Krakatoa Channels Modifiers are applied to the modifier stack of PRT Loaders, PRT Volumes and PRT FumeFX in object space." )
					theKCMRoot = Krakatoa_SchematicFlow_Tree.count
					
					local allKCMs = getClassInstances KrakatoaChannelsModifier 
					join allKCMs (getClassInstances MagmaModifier)
					local txt = stringStream ""
					format "rcmenu KCMsNodeRCMenu\n(\n" to:txt
					local cnt = 0
					for kcm in allKCMs do 
					(
						cnt+=1
						local theNodes = for o in refs.dependents kcm where (classof (superclassof o)) == Node and (try(classof o.baseobject != KrakatoaGlobalDataHolder)catch(false)) collect o
						if theNodes.count > 0 do
						(
							local theLine = "menuItem mnu_"+ cnt as string + " \"" + kcm.name + " ("
							local isShortened = false
							for o = theNodes.count to 1 by -1 do 
							(
								if theLine.count < 100 then 
									theLine += theNodes[o].name+","
								else
									isShortened = true
							)
							theLine = substring theLine 1 (theLine.count-1)
							if isShortened do theLine += "..." + theNodes[1].name
							theLine+=")\" checked:"+ (modPanel.getCurrentObject() == kcm) as string+"\n"
							format "%" theLine to:txt
							format "on mnu_%  picked do(\n" cnt to:txt
							format "max modify mode\n" to:txt
							local theIndex = findItem theNodes[1].modifiers kcm
							format "modPanel.setCurrentObject ((getNodeByName \"%\").modifiers[%] )\n" theNodes[1].name (theIndex as string) to:txt
							format ")\n" to:txt
						)
					)--end kcm loop
					format ")\n" to:txt
					Krakatoa_SchematicFlow_RightClickMenus.KCMsNodeRCMenu = execute (txt as string)
				)
				
				Krakatoa_SchematicFlow_Tree[Krakatoa_SchematicFlow_Tree.count][6] = #(0,0,theOriginX,30)
				
				--format "PRT Modifiers, Culling etc.: % sec.\n" ((timestamp()-st1)/1000.0)
				local st1 = timestamp()	
				
				local theStackRoot = Krakatoa_SchematicFlow_Tree.count
				inputCount = 0
				
				allRenderableSystems = #()

				enableNode =FranticParticles.GetBoolProperty "RenderParticleFlowGeometry"
				if enableNode or Krakatoa_SchematicFlow_showAllNodes do 
				(
					local theSystems = #()
					for theRenderOp in (getClassInstances RenderParticles) where theRenderOp.type == 2 do 
						(for o in refs.dependents theRenderOp where classof o == PF_Source and isProperty o #name do if findItem theSystems o == 0 do append theSystems o )
					local theRenderableSystems = for o in theSystems where not o.isHiddenInVpt and o.renderable and o.Enable_Particles collect o
					local theInfo = if theSystems.count == 0 then 
					(
						if enableNode then 
							"Loads Particles from PFlow Events with Render Operator set to Geometry, but there are currently no such Events in the scene."
						else
							"Loads Particles from PFlow Events with Render Operator set to Geometry, but there are no such Events and the '>PFlow Geometry' option is currently unchecked."
					)
					else
					(
						if theRenderableSystems.count == 0 then 
						(
							if enableNode then 
								"Loads Particles from PFlow Events with Render Operator set to Geometry, but the host PFlow System is not renderable."
							else
								"Loads Particles from PFlow Events set to Geometry, but the host PFlow is not renderable and the '>PFlow Geometry' option is currently unchecked."
						)
						else
						(
							if enableNode then 
								"Loads Particles from PFlow Events with Render Operator set to Geometry."
							else
								"Would load Particles from PFlow Events with Render Operator set to Geometry, but the '>PFlow Geometry' option is currently unchecked."
						)
					)
					local multiplier = if theSystems.count > 0 then 1.0 else 0.5
					append Krakatoa_SchematicFlow_Tree #( theRenderableSystems.count as string +"/"+theSystems.count as string + " PFlow Geometry", #(), #((color 200 255 200)*multiplier*(if enableNode then 1 else 0.1) , [120,35], true,true), getNextOffset(), #("Particles"), undefined, theInfo )
					append Krakatoa_SchematicFlow_Tree[theMatRoot][2] Krakatoa_SchematicFlow_Tree.count
					inputCount += 1
					
					if enableNode and theSystems.count > 0 do join allRenderableSystems theRenderableSystems
					
					Krakatoa_SchematicFlow_RightClickMenus.PFlowGeometryNodeRCMenu = defineMenu "PFlowGeometryNodeRCMenu" theSystems "RenderParticleFlowGeometry"
				)
				
				--format "PFlow Geo: % sec.\n" ((timestamp()-st1)/1000.0)
				local st1 = timestamp()
				
				enableNode =FranticParticles.GetBoolProperty "RenderParticleFlowPhantom"
				if enableNode or Krakatoa_SchematicFlow_showAllNodes do 
				(				
					local theSystems = #()
					for theRenderOp in (getClassInstances RenderParticles) where theRenderOp.type == 3 do 
						(for o in refs.dependents theRenderOp where classof o == PF_Source and isProperty o #name do if findItem theSystems o == 0 do append theSystems o )
					local theRenderableSystems = for o in theSystems where not o.isHiddenInVpt and o.renderable and o.Enable_Particles collect o
					local theInfo = if theSystems.count == 0 then 
					(
						if enableNode then 
							"Loads Particles from PFlow Events with Render Operator set to Phantom, but there are currently no such Events in the scene."
						else
							"Loads Particles from PFlow Events with Render Operator set to Phantom, but there are no such Events and the '>PFlow Phantom' option is currently unchecked."
					)
					else
					(
						if theRenderableSystems.count == 0 then 
						(
							if enableNode then 
								"Loads Particles from PFlow Events with Render Operator set to Phantom, but the host PFlow System is not renderable."
							else
								"Loads Particles from PFlow Events set to Phantom, but the host PFlow is not renderable and the '>PFlow Phantom' option is currently unchecked."
						)
						else
						(
							if enableNode then 
								"Loads Particles from PFlow Events with Render Operator set to Phantom."
							else
								"Would load Particles from PFlow Events with Render Operator set to Phantom, but the '>PFlow Phantom' option is currently unchecked."
						)
					)	
					local multiplier = if theSystems.count > 0 then 1.0 else 0.5
					append Krakatoa_SchematicFlow_Tree #(theRenderableSystems.count as string + "/"+theSystems.count as string + " PFlow Phantom", #(), #((color 200 255 200)*multiplier*(if enableNode then 1 else 0.1)  , [120,35],true,true), getNextOffset(), #("Particles"), undefined, theInfo )
					append Krakatoa_SchematicFlow_Tree[theMatRoot][2] Krakatoa_SchematicFlow_Tree.count
					inputCount += 1
					Krakatoa_SchematicFlow_RightClickMenus.PFlowPhantomNodeRCMenu = defineMenu "PFlowPhantomNodeRCMenu" theSystems "RenderParticleFlowPhantom"
					
					if enableNode and theSystems.count > 0 do join allRenderableSystems theRenderableSystems
					
				)

				--format "PFlow Phantom: % sec.\n" ((timestamp()-st1)/1000.0)
				local st1 = timestamp()
				
				enableNode =FranticParticles.GetBoolProperty "RenderParticleFlowBBox"
				if enableNode or Krakatoa_SchematicFlow_showAllNodes do 
				(					
					local theSystems = #()
					for theRenderOp in (getClassInstances RenderParticles) where theRenderOp.type == 1 do 
						(for o in refs.dependents theRenderOp where classof o == PF_Source and isProperty o #name do if findItem theSystems o == 0 do append theSystems o )
					local theRenderableSystems = for o in theSystems where not o.isHiddenInVpt and o.renderable and o.Enable_Particles collect o
					local theInfo = if theSystems.count == 0 then 
					(
						if enableNode then 
							"Loads Particles from PFlow Events with Render Operator set to Bounding Box, but there are currently no such Events in the scene."
						else
							"Loads Particles from PFlow Events with Render Operator set to Bounding Box, but there are no such Events and the '>PFlow BBox' option is currently unchecked."
					)
					else
					(
						if theRenderableSystems.count == 0 then 
						(
							if enableNode then 
								"Loads Particles from PFlow Events with Render Operator set to Bounding Box, but the host PFlow System is not renderable."
							else
								"Loads Particles from PFlow Events set to Bounding Box, but the host PFlow is not renderable and the '>PFlow BBox' option is currently unchecked."
						)
						else
						(
							if enableNode then 
								"Loads Particles from PFlow Events with Render Operator set to Bounding Box."
							else
								"Would load Particles from PFlow Events with Render Operator set to Bounding Box, but the '>PFlow BBox' option is currently unchecked."
						)
					)						
					local multiplier = if theRenderableSystems.count > 0 then 1.0 else 0.5
					append Krakatoa_SchematicFlow_Tree #(theRenderableSystems.count as string +"/"+theSystems.count as string +" PFlow BBox", #(), #((color 200 255 200)*multiplier*(if enableNode then 1 else 0.1)  , [120,35], true,true), getNextOffset(), #("Particles"), undefined, theInfo  )
					append Krakatoa_SchematicFlow_Tree[theMatRoot][2] Krakatoa_SchematicFlow_Tree.count
					inputCount += 1
					Krakatoa_SchematicFlow_RightClickMenus.PFlowBBoxNodeRCMenu = defineMenu "PFlowBBoxNodeRCMenu" theSystems "RenderParticleFlowBBox"	
					
					if enableNode and theSystems.count > 0 do join allRenderableSystems theRenderableSystems
				)

				--format "PFlow BBox: % sec.\n" ((timestamp()-st1)/1000.0)
				local st1 = timestamp()

				enableNode =FranticParticles.GetBoolProperty "RenderMaxParticles"
				if enableNode or Krakatoa_SchematicFlow_showAllNodes do 
				(
					local theSystems =(for o in objects where findItem legacyParticles (classof o) > 0 collect o) 
					local theRenderableSystems = for o in theSystems where not o.isHiddenInVpt and o.renderable collect o
					local multiplier = if theRenderableSystems.count > 0 then 1.0 else 0.5

					local theInfo = if theSystems.count == 0 then 
					(
						if enableNode then 
							"Loads Particles from 3ds Max Legacy particle systems, but there are currently no such systems in the scene."
						else
							"Loads Particles from 3ds Max Legacy particle systems, but there are no such systems and the '>Legacy Particles' option is currently unchecked."
					)
					else
					(
						if theRenderableSystems.count == 0 then 
						(
							if enableNode then 
								"Loads Particles from 3ds Max Legacy particle systems, but there are currently no renderable systems in the scene."
							else
								"Loads Particles from 3ds Max Legacy particle systems, but there are no renderable systems and the '>Legacy Particles' option is currently unchecked."
						)
						else
						(
							if enableNode then 
								"Loads the Particles from 3ds Max Legacy particle systems."
							else
								"Would load Particles from 3ds Max Legacy particle systems, but the '>Legacy Particles' option is currently unchecked."
						)
					)						
					append Krakatoa_SchematicFlow_Tree #(theRenderableSystems.count as string + "/" +theSystems.count as string  + (if theRenderableSystems.count == 1 then " Legacy System" else " Legacy Systems"), #(), #((color 200 255 200)*multiplier*(if enableNode then 1 else 0.1) , [120,35], true,true), getNextOffset(), #("Particles"), undefined, theInfo  )
					append Krakatoa_SchematicFlow_Tree[theMatRoot][2] Krakatoa_SchematicFlow_Tree.count
					inputCount += 1
					
					Krakatoa_SchematicFlow_RightClickMenus.LegacySystemsNodeRCMenu = defineMenu "LegacySystemsNodeRCMenu" theSystems "RenderMaxParticles" 
					
					if enableNode and theRenderableSystems.count > 0 do join allRenderableSystems theRenderableSystems
					
				)
				
				
				--format "Max Particles: % sec.\n" ((timestamp()-st1)/1000.0)
				local st1 = timestamp()

				
				enableNode =FranticParticles.GetBoolProperty "RenderThinkingParticles"
				if enableNode or Krakatoa_SchematicFlow_showAllNodes do 
				(
					local theSystems = (for o in objects where classof o == Thinking collect o)
					local theRenderableSystems = for o in theSystems where not o.isHiddenInVpt and o.renderable collect o
					local multiplier = if theRenderableSystems.count > 0 then 1.0 else 0.5
					local theInfo = if theSystems.count == 0 then 
					(
						if enableNode then 
							"Would load Particles from Thinking Particles systems, but there are currently no TP systems in the scene."
						else
							"Would load Particles from Thinking Particles systems, but there are no TP systems and the '>ThinkingParticles' option is currently unchecked."
					)
					else
					(
						if enableNode then 
							"Loads the Particles from Thinking Particles systems."
						else
							"Would load Particles from Thinking Particles systems, but the >ThinkingParticles option is currently unchecked."
					)							
					append Krakatoa_SchematicFlow_Tree #(theRenderableSystems.count as string +"/"+theSystems.count as string + " Thinking Particles", #(), #((color 200 255 200)*multiplier*(if enableNode then 1 else 0.1) , [120,35], true,true), getNextOffset(), #("Particles"), undefined, theInfo  )
					append Krakatoa_SchematicFlow_Tree[theMatRoot][2] Krakatoa_SchematicFlow_Tree.count
					inputCount += 1
					Krakatoa_SchematicFlow_RightClickMenus.TPNodeRCMenu = defineMenu "TPNodeRCMenu" theSystems "RenderThinkingParticles"
					
					if enableNode and theSystems.count > 0 do join allRenderableSystems theRenderableSystems
				)
							--format "TP : % sec.\n" ((timestamp()-st1)/1000.0)
	
				
		
				
				local st1 = timestamp()
				

				enableNode =FranticParticles.GetBoolProperty "RenderFumeFX"
				if enableNode or Krakatoa_SchematicFlow_showAllNodes do 
				(
					local theSystems =(for o in objects where classof o == PRT_FumeFX collect o)
					local theRenderableSystems = for o in theSystems where not o.isHiddenInVpt and o.renderable collect o
					
					local multiplier = if theRenderableSystems.count > 0 then 1.0 else 0.5
					local theInfo = if theSystems.count == 0 then 
					(
						if enableNode then 
							"Loads Particles from PRT FumeFX objects, but there are currently no PRT FumeFX Objects in the scene."
						else
							"Loads Particles from PRT FumeFX objects, but there are none and the '>FumeFX' option is currently unchecked."
					)
					else
					(
						if theRenderableSystems.count == 0 then
						(
							if enableNode then 
								"Loads Particles from PRT FumeFX objects, but there are currently no renderable PRT FumeFX objects in the scene."
							else
								"Loads Particles from PRT FumeFX objects, there are renderable PRT FumeFX objects, but the '>FumeFX' option is currently unchecked."
						)
						else
						(
							if enableNode then 
								"Loads Particles from PRT FumeFX objects."
							else
								"Would load Particles from PRT FumeFX objects, but the '>FumeFX' option is currently unchecked."
						)
					)								
					append Krakatoa_SchematicFlow_Tree #(theRenderableSystems.count as string +"/"+theSystems.count as string +" PRT FumeFX", #(), #((color 200 255 200)*multiplier*(if enableNode then 1 else 0.1) , [120,35], PRTFhasKCMs or PRTFhasDeformations, PRTFhasKCMs or PRTFhasDeformations), getNextOffset(), #("Voxels As Particles"), undefined, theInfo )
					if PRTFhasKCMs then
						append Krakatoa_SchematicFlow_Tree[theKCMRoot][2] Krakatoa_SchematicFlow_Tree.count
					else if PRTFhasDeformations then 
						append Krakatoa_SchematicFlow_Tree[theDeformRoot][2] Krakatoa_SchematicFlow_Tree.count
					else
						append Krakatoa_SchematicFlow_Tree[theMatRoot][2] Krakatoa_SchematicFlow_Tree.count
					inputCount += 1
					
					Krakatoa_SchematicFlow_RightClickMenus.FumeFXNodeRCMenu = defineMenu "FumeFXNodeRCMenu" theSystems "RenderFumeFX"
					
					if enableNode and theSystems.count > 0 do join allRenderableSystems theRenderableSystems
				)		

				enableNode =FranticParticles.GetBoolProperty "RenderPhoenixFD"
				if enableNode or Krakatoa_SchematicFlow_showAllNodes do 
				(
					local theSystems =(for o in objects where classof o == PhoenixFD collect o)
					local theRenderableSystems = for o in theSystems where not o.isHiddenInVpt and o.renderable collect o
					
					local multiplier = if theRenderableSystems.count > 0 then 1.0 else 0.5
					local theInfo = if theSystems.count == 0 then 
					(
						if enableNode then 
							"Loads Particles from Phoenix FD objects, but there are currently no Phoenix FD Objects in the scene."
						else
							"Loads Particles from Phoenix FD objects, but there are none and the '>Phoenix' option is currently unchecked."
					)
					else
					(
						if theRenderableSystems.count == 0 then
						(
							if enableNode then 
								"Loads Particles from Phoenix FD objects, but there are currently no renderable Phoenix FD objects in the scene."
							else
								"Loads Particles from Phoenix FD objects, there are renderable Phoenix FDobjects, but the '>Phoenix' option is currently unchecked."
						)
						else
						(
							if enableNode then 
								"Loads Particles from Phoenix FD objects."
							else
								"Would load Particles from Phoenix FD objects, but the '>Phoenix' option is currently unchecked."
						)
					)								
					append Krakatoa_SchematicFlow_Tree #(theRenderableSystems.count as string +"/"+theSystems.count as string +" Phoenix", #(), #((color 200 255 200)*multiplier*(if enableNode then 1 else 0.1) , [120,35], false, false), getNextOffset(), #("Phoenix Particles"), undefined, theInfo )
					append Krakatoa_SchematicFlow_Tree[theMatRoot][2] Krakatoa_SchematicFlow_Tree.count
					inputCount += 1
					
					Krakatoa_SchematicFlow_RightClickMenus.PhoenixNodeRCMenu = defineMenu "PhoenixNodeRCMenu" theSystems "RenderPhoenixFD"
					
					if enableNode and theSystems.count > 0 do join allRenderableSystems theRenderableSystems
				)						
				
				local st1 = timestamp()
				
				enableNode =FranticParticles.GetBoolProperty "RenderGeometryVertices"
				if enableNode or Krakatoa_SchematicFlow_showAllNodes do 
				(
					local theSystems = (for o in objects where findItem GeometryClass.classes (classof o) > 0 AND (findItem #(TargetObject , Thinking, PRT_FumeFX, PRT_Source,ParticleGroup,KrakatoaPrtLoader,PRT_Hair, PRT_Maker, PRT_Surface,  PF_Source ) (classof o.baseobject) == 0) AND findItem legacyParticles (classof o) == 0 AND findItem matteObjects o == 0  AND classof o.baseobject != KrakatoaGlobalDataHolder AND not FranticParticleRenderMXS.isGeoVolume o collect o)
					local theRenderableSystems = for o in theSystems where not o.isHiddenInVpt and o.renderable collect o
					local multiplier = if theRenderableSystems.count > 0 then 1.0 else 0.5
					
					local theInfo = if theSystems.count == 0 then 
					(
						if enableNode then 
							"Would load Vertices of Geometry Objects as Particles, but there are currently no Geometry Objects in the scene."
						else
							"Would load Vertices of Geometry Objects as Particles, but the '>Geo.Vertices' option is currently unchecked."
					)
					else
					(
						if enableNode then 
							"Loads the Vertices of the scene Geometry Objects as Particles."
						else
							"Would load the Vertices of the scene Geometry Objects as Particles, but the '>Geo.Vertices' option is currently unchecked."
					)
					
					append Krakatoa_SchematicFlow_Tree #(theRenderableSystems.count as string + "/" + theSystems.count as string  + (if theRenderableSystems.count == 1 then " Geometry Object " else " Geometry Objects"), #(), #((color 200 255 200)*multiplier*(if enableNode then 1 else 0.1) , [120,35]), getNextOffset(), #("Vertices As Particles"), undefined, theInfo )
					append Krakatoa_SchematicFlow_Tree[theMatRoot][2] Krakatoa_SchematicFlow_Tree.count
					inputCount += 1
					
					Krakatoa_SchematicFlow_RightClickMenus.GeometryVerticesNodeRCMenu = defineMenu "GeometryVerticesNodeRCMenu" theSystems "RenderGeometryVertices"
					
					if enableNode and theRenderableSystems.count > 0 do join allRenderableSystems theRenderableSystems
				)					
				
				
				--format "Vertices: % sec.\n" ((timestamp()-st1)/1000.0)						
				
				local st1 = timestamp()
				
		
				enableNode =FranticParticles.GetBoolProperty "RenderKrakatoaLoaders"
				if enableNode or Krakatoa_SchematicFlow_showAllNodes do 
				(
					local theRenderableSystems = for o in thePRTLoaders where not o.isHiddenInVpt and o.renderable and o.baseobject.enabledInRender collect o
					local multiplier = if theRenderableSystems.count > 0 then 1.0 else 0.5
					local theInfo = if thePRTLoaders.count == 0 and thePRTSources.count == 0 then 
					(
						if enableNode then 
							"Would load Particles from PRT Loader objects, but there are currently no PRT Loader objects in the scene."
						else
							"Would load Particles PRT Loader objects but there are none and the '>PRT Loaders' option is currently unchecked."
					)
					else
					(
						if theRenderableSystems.count == 0 then
						(
							if enableNode then 
								"Would load Particles from PRT Loader objects, but there are currently no renderable objects of these types in the scene."
							else
								"Would load Particles from PRT Loader objects but there are no renderable objects and the '>PRT Loaders' option is currently unchecked."
						)
						else
						(
							if enableNode then 
								"Loads the Particles from PRT Loader objects."
							else
								"Would load the Particles from PRT Loader objects, but the '>PRT Loaders' option is currently unchecked."
						)
					)						
					append Krakatoa_SchematicFlow_Tree #(theRenderableSystems.count as string + "/" + thePRTLoaders.count as string +  (if thePRTLoaders.count == 1 then " PRT Loader" else " PRT Loaders"), #(), #((color 200 255 200)*multiplier*(if enableNode then 1 else 0.1) , [120,35], PRTLhasKCMs or  PRTLhasDeformations or hasCulling, PRTLhasKCMs or PRTLhasDeformations or hasCulling ), getNextOffset(), #("Loaded Particles"), undefined, theInfo)
					if PRTLhasKCMs then
						append Krakatoa_SchematicFlow_Tree[theKCMRoot][2] Krakatoa_SchematicFlow_Tree.count
					else if PRTLhasDeformations then 
						append Krakatoa_SchematicFlow_Tree[theDeformRoot][2] Krakatoa_SchematicFlow_Tree.count
					else if hasCulling then 
						append Krakatoa_SchematicFlow_Tree[theCullingRoot][2] Krakatoa_SchematicFlow_Tree.count
					else
						append Krakatoa_SchematicFlow_Tree[theMatRoot][2] Krakatoa_SchematicFlow_Tree.count
					inputCount += 1
					
					Krakatoa_SchematicFlow_RightClickMenus.PRTLoadersNodeRCMenu = defineMenu "PRTLoadersNodeRCMenu" thePRTLoaders "RenderKrakatoaLoaders"					
					
					if enableNode and thePRTLoaders.count > 0 do join allRenderableSystems theRenderableSystems
				)
				

				--format "PRT Loaders: % sec.\n" ((timestamp()-st1)/1000.0)
				local st1 = timestamp()

				enableNode =FranticParticles.GetBoolProperty "RenderGeometryVolumes"
				if enableNode or Krakatoa_SchematicFlow_showAllNodes do 
				(
					local theRenderableSystems = for o in thePRTVolumes where not o.isHiddenInVpt and o.renderable collect o
					local multiplier = if theRenderableSystems.count > 0 then 1.0 else 0.5
					local theInfo = if theRenderableSystems.count == 0 then 
					(
						if enableNode then 
							"Loads Particles created by PRT Volume objects, but there are currently no PRT Volume objects in the scene."
						else
							"Loads Particles created by PRT Volume objects but there are none and the '>PRT Vol/Surf' option is currently unchecked."
					)
					else
					(
						if enableNode then 
							"Loads Particles created by the PRT Volume objects filling Geometry volumes."
						else
							"Would load the Particles created by the PRT Volume objects, but the '>PRT Vol/Surf' option is currently unchecked."
					)
					
					append Krakatoa_SchematicFlow_Tree #(theRenderableSystems.count as string + "/" + thePRTVolumes.count as string + (if theRenderableSystems.count == 1 then " PRT Volume" else " PRT Volumes"), #(), #((color 200 255 200)*multiplier*(if enableNode then 1 else 0.1)  , [120,35], PRTVhasDeformations or PRTVhasKCMs,PRTVhasDeformations or PRTVhasKCMs), getNextOffset(), #("Volume Particles"), undefined, theInfo)
					if PRTVhasKCMs then
						append Krakatoa_SchematicFlow_Tree[theKCMRoot][2] Krakatoa_SchematicFlow_Tree.count
					else if PRTVhasDeformations then 
						append Krakatoa_SchematicFlow_Tree[theDeformRoot][2] Krakatoa_SchematicFlow_Tree.count
					else
						append Krakatoa_SchematicFlow_Tree[theMatRoot][2] Krakatoa_SchematicFlow_Tree.count
					inputCount += 1
					
					Krakatoa_SchematicFlow_RightClickMenus.PRTVolumesNodeRCMenu = defineMenu "PRTVolumesNodeRCMenu" thePRTVolumes "RenderGeometryVolumes"
					
					if enableNode and theRenderableSystems.count > 0 do join allRenderableSystems theRenderableSystems
				)
				
				enableNode =FranticParticles.GetBoolProperty "RenderPRTSurface"
				if enableNode or Krakatoa_SchematicFlow_showAllNodes do 
				(
					local theRenderableSystems = for o in thePRTSurfaces where not o.isHiddenInVpt and o.renderable collect o
					local multiplier = if theRenderableSystems.count > 0 then 1.0 else 0.5
					local theInfo = if theRenderableSystems.count == 0 then 
					(
						if enableNode then 
							"Loads Particles created by PRT Surface objects, but there are currently no PRT Surface objects in the scene."
						else
							"Loads Particles created by PRT Surface objects but there are none and the '>PRT Surface' option is currently unchecked."
					)
					else
					(
						if enableNode then 
							"Loads Particles created by the PRT Surface objects covering Geometry volumes."
						else
							"Would load the Particles created by the PRT Surface objects, but the '>PRT Surface' option is currently unchecked."
					)
					
					append Krakatoa_SchematicFlow_Tree #(theRenderableSystems.count as string + "/" + thePRTSurfaces.count as string + (if theRenderableSystems.count == 1 then " PRT Surface" else " PRT Surfaces"), #(), #((color 200 255 200)*multiplier*(if enableNode then 1 else 0.1)  , [120,35], PRTSurfHasDeformations or PRTSurfHasKCMs,PRTSurfHasDeformations or PRTSurfHasKCMs), getNextOffset(), #("Surface Particles"), undefined, theInfo)
					if PRTSurfHasKCMs then
						append Krakatoa_SchematicFlow_Tree[theKCMRoot][2] Krakatoa_SchematicFlow_Tree.count
					else if PRTSurfHasDeformations then 
						append Krakatoa_SchematicFlow_Tree[theDeformRoot][2] Krakatoa_SchematicFlow_Tree.count
					else
						append Krakatoa_SchematicFlow_Tree[theMatRoot][2] Krakatoa_SchematicFlow_Tree.count
					inputCount += 1
					
					Krakatoa_SchematicFlow_RightClickMenus.PRTSurfacesNodeRCMenu = defineMenu "PRTSurfacesNodeRCMenu" thePRTSurfaces "RenderPRTSurface"
					
					if enableNode and theRenderableSystems.count > 0 do join allRenderableSystems theRenderableSystems					
					
				)
				

				--format "PRT Volumes: % sec.\n" ((timestamp()-st1)/1000.0)
	

				enableNode =FranticParticles.GetBoolProperty "RenderPRTHair"
				if enableNode or Krakatoa_SchematicFlow_showAllNodes do 
				(
					local theSystems =(for o in objects where classof o.baseobject == PRT_Hair collect o)
					local theRenderableSystems = for o in theSystems where not o.isHiddenInVpt and o.renderable collect o
					
					local multiplier = if theRenderableSystems.count > 0 then 1.0 else 0.5
					local theInfo = if theSystems.count == 0 then 
					(
						if enableNode then 
							"Would load Particles generated from Splines or Hair&Fur objects, but there are currently no PRT Hair Objects in the scene."
						else
							"Would load Particles generated from Splines or Hair&Fur objects, but there are none and the '>PRT Hair' option is currently unchecked."
					)
					else
					(
						if theRenderableSystems.count == 0 then
						(
							if enableNode then 
								"Would load Particles generated from Splines or Hair&Fur objects, but there are currently no renderable PRT Hair objects in the scene."
							else
								"Would load Particles generated from Splines or Hair&Fur objects, there are renderable PRT Hair objects, but the '>PRT Hair' option is currently unchecked."
						)
						else
						(
							if enableNode then 
								"Loads Particles from PRT Hair objects."
							else
								"Would load Particles from PRT Hair objects, but the '>PRT Hair' option is currently unchecked."
						)
					)								
					append Krakatoa_SchematicFlow_Tree #(theRenderableSystems.count as string +"/"+theSystems.count as string +" PRT Hair", #(), #((color 200 255 200)*multiplier*(if enableNode then 1 else 0.1) , [120,35], PRTFhasKCMs or PRTFhasDeformations, PRTFhasKCMs or PRTFhasDeformations), getNextOffset(), #("Splines To Particles"), undefined, theInfo )
					if PRTFhasKCMs then
						append Krakatoa_SchematicFlow_Tree[theKCMRoot][2] Krakatoa_SchematicFlow_Tree.count
					else if PRTFhasDeformations then 
						append Krakatoa_SchematicFlow_Tree[theDeformRoot][2] Krakatoa_SchematicFlow_Tree.count
					else
						append Krakatoa_SchematicFlow_Tree[theMatRoot][2] Krakatoa_SchematicFlow_Tree.count
					inputCount += 1

					Krakatoa_SchematicFlow_RightClickMenus.PRTHairNodeRCMenu = defineMenu "PRTHairNodeRCMenu" theSystems "RenderPRTHair"
					
					if enableNode and theSystems.count > 0 do join allRenderableSystems theRenderableSystems
				)					
				
				enableNode =FranticParticles.GetBoolProperty "RenderPRTCreator"
				if enableNode or Krakatoa_SchematicFlow_showAllNodes do 
				(
					local theSystems =(for o in objects where classof o.baseobject == PRT_Maker collect o)
					local theRenderableSystems = for o in theSystems where not o.isHiddenInVpt and o.renderable collect o
					
					local multiplier = if theRenderableSystems.count > 0 then 1.0 else 0.5
					local theInfo = if theSystems.count == 0 then 
					(
						if enableNode then 
							"Would load procedurally generated particles, but there are currently no PRT Maker Objects in the scene."
						else
							"Would load procedurally generated particles, but there are none and the '>PRT Makers' option is currently unchecked."
					)
					else
					(
						if theRenderableSystems.count == 0 then
						(
							if enableNode then 
								"Would load procedurally generated particles, but there are currently no renderable PRT Maker objects in the scene."
							else
								"Would load procedurally generated particles, there are renderable PRT Maker objects, but the '>PRT Makers' option is currently unchecked."
						)
						else
						(
							if enableNode then 
								"Loads Particles generated procedurally by PRT Maker objects."
							else
								"Would load Particles generated procedurally by PRT Maker objects, but the '>PRT Makers' option is currently unchecked."
						)
					)								
					append Krakatoa_SchematicFlow_Tree #(theRenderableSystems.count as string +"/"+theSystems.count as string +" PRT Makers", #(), #((color 200 255 200)*multiplier*(if enableNode then 1 else 0.1) , [120,35], PRTFhasKCMs or PRTFhasDeformations, PRTFhasKCMs or PRTFhasDeformations), getNextOffset(), #("Procedural Particles"), undefined, theInfo )
					if PRTFhasKCMs then
						append Krakatoa_SchematicFlow_Tree[theKCMRoot][2] Krakatoa_SchematicFlow_Tree.count
					else if PRTFhasDeformations then 
						append Krakatoa_SchematicFlow_Tree[theDeformRoot][2] Krakatoa_SchematicFlow_Tree.count
					else
						append Krakatoa_SchematicFlow_Tree[theMatRoot][2] Krakatoa_SchematicFlow_Tree.count
					inputCount += 1
					Krakatoa_SchematicFlow_RightClickMenus.PRTMakerNodeRCMenu = defineMenu "PRTMakerNodeRCMenu" theSystems "RenderPRTCreator"
					
					if enableNode and theSystems.count > 0 do join allRenderableSystems theRenderableSystems
				)		

				enableNode =FranticParticles.GetBoolProperty "RenderPRTSource"
				if enableNode or Krakatoa_SchematicFlow_showAllNodes do 
				(
					local theSystems =(for o in objects where classof o.baseobject == PRT_Source collect o)
					local theRenderableSystems = for o in theSystems where not o.isHiddenInVpt and o.renderable collect o
					
					local multiplier = if theRenderableSystems.count > 0 then 1.0 else 0.5
					local theInfo = if theSystems.count == 0 then 
					(
						if enableNode then 
							"Would load particles from 3rd party sources, but there are currently no PRT Source Objects in the scene."
						else
							"Would load particles from 3rd party sources, but there are none and the '>PRT Sources' option is currently unchecked."
					)
					else
					(
						if theRenderableSystems.count == 0 then
						(
							if enableNode then 
								"Would load particles from 3rd party sources, but there are currently no renderable PRT Source objects in the scene."
							else
								"Would load particles from 3rd party sources, there are renderable PRT Source objects, but the '>PRT Sources' option is currently unchecked."
						)
						else
						(
							if enableNode then 
								"Loads Particles from 3rd party sources."
							else
								"Would load Particles from 3rd party sources, but the '>PRT Sources' option is currently unchecked."
						)
					)								
					append Krakatoa_SchematicFlow_Tree #(theRenderableSystems.count as string +"/"+theSystems.count as string +" PRT Sources", #(), #((color 200 255 200)*multiplier*(if enableNode then 1 else 0.1) , [120,35], PRTFhasKCMs or PRTFhasDeformations, PRTFhasKCMs or PRTFhasDeformations), getNextOffset(), #("3rd Party Particles"), undefined, theInfo )
					if PRTFhasKCMs then
						append Krakatoa_SchematicFlow_Tree[theKCMRoot][2] Krakatoa_SchematicFlow_Tree.count
					else if PRTFhasDeformations then 
						append Krakatoa_SchematicFlow_Tree[theDeformRoot][2] Krakatoa_SchematicFlow_Tree.count
					else
						append Krakatoa_SchematicFlow_Tree[theMatRoot][2] Krakatoa_SchematicFlow_Tree.count
					inputCount += 1
					
					Krakatoa_SchematicFlow_RightClickMenus.PRTSourceNodeRCMenu = defineMenu "PRTSourceNodeRCMenu" theSystems "RenderPRTSource"
					
					if enableNode and theSystems.count > 0 do join allRenderableSystems theRenderableSystems
				)						
				
				enableNode =FranticParticles.GetBoolProperty "RenderPRTField"
				if enableNode or Krakatoa_SchematicFlow_showAllNodes do 
				(
					local theSystems =(for o in objects where classof o.baseobject == PRT_Field collect o)
					local theRenderableSystems = for o in theSystems where not o.isHiddenInVpt and o.renderable collect o
					
					local multiplier = if theRenderableSystems.count > 0 then 1.0 else 0.5
					local theInfo = if theSystems.count == 0 then 
					(
						if enableNode then 
							"Would load particles from Stoke PRT Field Objects, but there are currently no PRT Field Objects in the scene."
						else
							"Would load particles from Stoke PRT Field Objects, but there are none and the '>PRT Field' option is currently unchecked."
					)
					else
					(
						if theRenderableSystems.count == 0 then
						(
							if enableNode then 
								"Would load particles from Stoke PRT Field Objects, but there are currently no renderable PRT Field objects in the scene."
							else
								"Would load particles from Stoke PRT Field Objects, there are renderable PRT Field objects, but the '>PRT Field' option is currently unchecked."
						)
						else
						(
							if enableNode then 
								"Loads Particles from Stoke PRT Field Objects."
							else
								"Would load Particles from Stoke PRT Field Objects, but the '>PRT Field' option is currently unchecked."
						)
					)								
					append Krakatoa_SchematicFlow_Tree #(theRenderableSystems.count as string +"/"+theSystems.count as string +" PRT Field", #(), #((color 200 255 200)*multiplier*(if enableNode then 1 else 0.1) , [120,35], PRTEhasKCMs or PRTEhasDeformations, PRTEhasKCMs or PRTEhasDeformations), getNextOffset(), #("PRT Field Particles"), undefined, theInfo )
					if PRTEhasKCMs then
						append Krakatoa_SchematicFlow_Tree[theKCMRoot][2] Krakatoa_SchematicFlow_Tree.count
					else if PRTEhasDeformations then 
						append Krakatoa_SchematicFlow_Tree[theDeformRoot][2] Krakatoa_SchematicFlow_Tree.count
					else
						append Krakatoa_SchematicFlow_Tree[theMatRoot][2] Krakatoa_SchematicFlow_Tree.count
					inputCount += 1
					
					Krakatoa_SchematicFlow_RightClickMenus.PRTFieldNodeRCMenu = defineMenu "PRTFieldNodeRCMenu" theSystems "RenderPRTField"
					
					if enableNode and theSystems.count > 0 do join allRenderableSystems theRenderableSystems
				)	
				
				enableNode =FranticParticles.GetBoolProperty "RenderStoke"
				if enableNode or Krakatoa_SchematicFlow_showAllNodes do 
				(
					local theSystems =(for o in objects where classof o.baseobject == Stoke collect o)
					local theRenderableSystems = for o in theSystems where not o.isHiddenInVpt and o.renderable collect o
					
					local multiplier = if theRenderableSystems.count > 0 then 1.0 else 0.5
					local theInfo = if theSystems.count == 0 then 
					(
						if enableNode then 
							"Would load particles from Stoke Objects, but there are currently no Stoke Objects in the scene."
						else
							"Would load particles from Stoke Objects, but there are none and the '>Stoke' option is currently unchecked."
					)
					else
					(
						if theRenderableSystems.count == 0 then
						(
							if enableNode then 
								"Would load particles from Stoke Objects, but there are currently no renderable Stoke objects in the scene."
							else
								"Would load particles from Stoke Objects, there are renderable Stoke objects, but the '>Stoke' option is currently unchecked."
						)
						else
						(
							if enableNode then 
								"Loads Particles from Stoke Objects."
							else
								"Would load Particles from Stoke Objects, but the '>Stoke' option is currently unchecked."
						)
					)								
					append Krakatoa_SchematicFlow_Tree #(theRenderableSystems.count as string +"/"+theSystems.count as string +" Stoke", #(), #((color 200 255 200)*multiplier*(if enableNode then 1 else 0.1) , [120,35], PRTEhasKCMs or PRTEhasDeformations, PRTEhasKCMs or PRTEhasDeformations), getNextOffset(), #("Stoke Particles"), undefined, theInfo )
					if PRTEhasKCMs then
						append Krakatoa_SchematicFlow_Tree[theKCMRoot][2] Krakatoa_SchematicFlow_Tree.count
					else if PRTEhasDeformations then 
						append Krakatoa_SchematicFlow_Tree[theDeformRoot][2] Krakatoa_SchematicFlow_Tree.count
					else
						append Krakatoa_SchematicFlow_Tree[theMatRoot][2] Krakatoa_SchematicFlow_Tree.count
					inputCount += 1
					
					Krakatoa_SchematicFlow_RightClickMenus.StokeNodeRCMenu = defineMenu "StokeNodeRCMenu" theSystems "RenderStoke"
					
					if enableNode and theSystems.count > 0 do join allRenderableSystems theRenderableSystems
				)					

				
				if allRenderableSystems.count == 0 do 
				(
					Krakatoa_SchematicFlow_Tree[theMemoryPoolIndex][3][1] = color 255 50 50 
					Krakatoa_SchematicFlow_Tree[theMemoryPoolIndex][7] = "WARNING: The scene provides NO PARTICLES. Please create/unhide/enable one or more particle sources."
				)
							
			)
		)--end fn
		
		fn createNodeTree init:false=
		(
			theTreeHeight = 0
			if init do
			(
				for i = hc.getNodeCount to 1 by -1 do 
				(
					hc.activeNode = i	
					hc.deleteActiveNode
				)
			)	
			hc.setInfo = "Krakatoa Schematic Flow - Left-Click Anywhere to Force Update..."
			local x = theOriginX+120
			local y = 10
			
			local currentNode = Krakatoa_SchematicFlow_Tree[1]
			if init do hc.addNode
			hc.activeNode = 1
			hc.isCollapsible = false
			hc.nodeName =  "OK"
			hc.nodeColor = green
			hc.viewAlign = 1
			hc.nodeSize = [45,12]
			hc.drawLayer = 2

			for i = 2 to Krakatoa_SchematicFlow_Tree.count do
			(
				local currentNode = Krakatoa_SchematicFlow_Tree[i]
				if currentNode[4] != undefined then
				(
					x -= currentNode[4][1]
					y += currentNode[4][2]
				)
				else
				(
					x += 0
					y += 60
				)			
				if currentNode[6] != undefined do 
				(
					if currentNode[6][1] > 0 do 
					(
						x = currentNode[6][1]
						y += currentNode[6][2]
					)
				)		
				if x < 100 do 
				(
					x = theOriginX
					y += 60
				)

				if init do hc.addNode
				hc.activeNode = i
				hc.nodeName =  currentNode[1] 
				hc.nodeColor = currentNode[3][1]
				
				hc.activeNodePos = [x,y]
				if y+60 > theTreeHeight do theTreeHeight = y+60
				hc.isCollapsible = false
				hc.drawLayer = 1
				hc.viewAlign = 0
				if init do hc.addOutSocket
				hc.activeSocket = 1
				hc.connectionColor = blue
				hc.socketPosition = [5,20]
				if currentNode[3][4] ==true do try(hc.activeSocketFlipped  = true)catch()
				hc.socketName = if currentNode[5] != undefined then 
					currentNode[5][1]
				else ""
				
				hc.activeSocketShowValue = false
				
				if currentNode[2].count > 0 do
				(
					if init do hc.addInSocket
					hc.activeSocket = 2
					hc.socketPosition = [5,32]

					if currentNode[3][3] ==true do try(hc.activeSocketFlipped  = true)catch()

					hc.socketName = if currentNode[5] != undefined then 
						currentNode[5][2]
					else ""
					hc.connectionColor = blue
				)
				
				hc.nodeCollapsedSize = [currentNode[3][2].x ,20]	
				hc.nodeSize = currentNode[3][2]
	
				if currentNode[6] != undefined and i < Krakatoa_SchematicFlow_Tree.count do 
				(
					if currentNode[6].count > 2 do 
					(
						x = currentNode[6][3]
						y += currentNode[6][4]
					)
				)
				if currentNode[7] != undefined do
				(
					if matchpattern currentNode[7]  pattern:"WARNING*" do 
					(
						hc.setInfo = currentNode[7] 
						hc.activeNode = 1
						hc.nodeColor = color 255 200 100
						hc.nodeName = "WARN"
					)
					
					if matchpattern currentNode[7]  pattern:"ERROR*" do
					(
						hc.setInfo = currentNode[7] 
						hc.activeNode = 1
						hc.nodeColor = red
						hc.nodeName = "ERROR"
					)
				)				
			)
			
			if init do 
			(
				for i = 1 to Krakatoa_SchematicFlow_Tree.count do
				(
					local currentNode = Krakatoa_SchematicFlow_Tree[i]
					local theConnections = currentNode[2]
					for c = 1 to theConnections.count do
					(
						if theConnections[c] != undefined and theConnections[c] > 0 and theConnections[c] <= Krakatoa_SchematicFlow_Tree.count do
						(
							hc.activeNode = theConnections[c]
							hc.activeSocket = 1
							hc.toggleConnection = [i,2]
						)	
					)
				)
			)
			hc.redrawView	
		)
		
		fn showGrid =
		(
			return false 
			
			local enabled = true
			local theBackgroundColor = white*0.68
			local theGridColor = theBackgroundColor  --white*0.65
			local GridSizeX = 10
			local GridSizeY = 10
			
			local theX = GridSizeX*hc.zoom
			local theY = GridSizeY*hc.zoom

			local theBitmap = bitmap theX theY color:theBackgroundColor 
			
			if enabled and hc.zoom > 0.9 do
			(
				thePixels = for i = 1 to theX collect theGridColor
				setPixels theBitmap [0,0] thePixels
				for i = 1 to theY do 
					setPixels theBitmap [0,i-1] #(theGridColor)
			)
			
			hc.backgroundBitmap = theBitmap
			hc.tileBackground = true
		)		


        local dotnetSystemInfo = dotNetClass "System.Windows.Forms.SystemInformation"
		
		on hc mouseMoved do
		(
			local theHeightOffset = try(dotnetSystemInfo.CaptionHeight + dotnetSystemInfo.MenuHeight + dotnetSystemInfo.FrameBorderSize.height)catch(50)
			local theWidthOffset = try(dotnetSystemInfo.FrameBorderSize.width)catch(5) 					
			
			local theMouse = (mouse.screenpos - (getDialogPos Krakatoa_SchematicFlow_Rollout))-[theWidthOffset,theHeightOffset]
			local theNode = (hc.findNodeByPos = theMouse)
			if theNode > 0 and theNode <= Krakatoa_SchematicFlow_Tree.count then
			(
				if Krakatoa_SchematicFlow_Tree[theNode][7] != undefined do hc.setInfo = Krakatoa_SchematicFlow_Tree[theNode][7]
				hc.activeNode = theNode
				theColor = Krakatoa_SchematicFlow_Tree[theNode][3][1] + [50,50,50]
				if theColor.r > 255 do theColor.r = 255
				if theColor.g > 255 do theColor.g = 255
				if theColor.b > 255 do theColor.b = 255
				hc.nodeColor = theColor 
				hc.redrawView	
			)
			else 
				Krakatoa_SchematicFlow_Rollout.createNodeTree init:true
			--::Krakatoa_updateSchematicFlow()
		)
			
			
		on hc LButtonDown do
		(
			if classof renderers.current != Krakatoa then 
			(
				destroyDialog Krakatoa_SchematicFlow_Rollout
			)
			else
			(
				lastMouseClick = mouse.screenpos
				local theHeightOffset = try(dotnetSystemInfo.CaptionHeight + dotnetSystemInfo.MenuHeight + dotnetSystemInfo.FrameBorderSize.height)catch(50)
				local theWidthOffset = try(dotnetSystemInfo.FrameBorderSize.width)catch(5) 					
				local theMouse = (lastMouseClick - (getDialogPos Krakatoa_SchematicFlow_Rollout))-[theWidthOffset,theHeightOffset]
				lastNodeClick = (hc.findNodeByPos = theMouse)
				hc.setInfo = ""
				if lastNodeClick > 0 and lastNodeClick <= Krakatoa_SchematicFlow_Tree.count do
				(
					if Krakatoa_SchematicFlow_Tree[lastNodeClick][7] != undefined do
					(
						hc.setInfo = Krakatoa_SchematicFlow_Tree[lastNodeClick][7]
					)
				)
				hc.redrawView			
				::Krakatoa_SchematicFlow_LastUpdate = 0
				::Krakatoa_updateSchematicFlow()
			)
		)			
		
		on hc RButtonDown do
		(
			if classof renderers.current != Krakatoa do destroyDialog(Krakatoa_SchematicFlow_Rollout)
			lastMouseClick = mouse.screenpos
			local theHeightOffset = try(dotnetSystemInfo.CaptionHeight + dotnetSystemInfo.MenuHeight + dotnetSystemInfo.FrameBorderSize.height)catch(50)
			if Krakatoa_SchematicFlow_Rollout.inViewport do 
				theHeightOffset = try(dotnetSystemInfo.MenuHeight+0)catch(19)
			
			local theWidthOffset = try(dotnetSystemInfo.FrameBorderSize.width)catch(5) 					
			local theMouse = (lastMouseClick - (getDialogPos Krakatoa_SchematicFlow_Rollout))-[theWidthOffset,theHeightOffset]
			lastNodeClick = (hc.findNodeByPos = theMouse)
			if lastNodeClick > 0 and lastNodeClick <= Krakatoa_SchematicFlow_Tree.count then
			(
				case Krakatoa_SchematicFlow_Tree[lastNodeClick][1] of
				(
					"Render Elements": popupmenu Krakatoa_SchematicFlow_RightClickMenus.RenderElementsRCMenu pos:mouse.screenpos 
					"RENDER VOXELS": popupmenu Krakatoa_SchematicFlow_RightClickMenus.RenderNodeRCMenu pos:mouse.screenpos
					"RENDER PARTICLES": popupmenu Krakatoa_SchematicFlow_RightClickMenus.RenderNodeRCMenu pos:mouse.screenpos
					"SAVE PARTICLES": popupmenu Krakatoa_SchematicFlow_RightClickMenus.RenderNodeRCMenu pos:mouse.screenpos
					"LIGHT PARTICLES": popupmenu Krakatoa_SchematicFlow_RightClickMenus.RenderNodeRCMenu pos:mouse.screenpos
					"MEMORY POOL": popupmenu Krakatoa_SchematicFlow_RightClickMenus.MemoryNodeRCMenu pos:mouse.screenpos
					"PARTICLE CACHE": popupmenu Krakatoa_SchematicFlow_RightClickMenus.MemoryNodeRCMenu pos:mouse.screenpos
					"LIGHTING CACHE": popupmenu Krakatoa_SchematicFlow_RightClickMenus.MemoryNodeRCMenu pos:mouse.screenpos
					"Depth Of Field":  popupmenu Krakatoa_SchematicFlow_RightClickMenus.DOFNodeRCMenu pos:mouse.screenpos
					"Ambient PME": popupmenu Krakatoa_SchematicFlow_RightClickMenus.APMENodeRCMenu  pos:mouse.screenpos
					--"Background Image File": popupmenu Krakatoa_SchematicFlow_RightClickMenus.BackgroundImageFileNodeRCMenu pos:mouse.screenpos
					"Depth Map Matte": popupmenu Krakatoa_SchematicFlow_RightClickMenus.DepthMatteNodeRCMenu pos:mouse.screenpos
					"Objects Matte": popupmenu Krakatoa_SchematicFlow_RightClickMenus.MatteObjectsNodeRCMenu pos:mouse.screenpos
					"Attenuation File": popupmenu Krakatoa_SchematicFlow_RightClickMenus.AttenuationFileNodeRCMenu pos:mouse.screenpos
					"Image File": popupmenu Krakatoa_SchematicFlow_RightClickMenus.ImageFileNodeRCMenu pos:mouse.screenpos
					"Frame Buffer": popupmenu Krakatoa_SchematicFlow_RightClickMenus.VFBNodeRCMenu pos:mouse.screenpos
					
					"Force Additive Mode": popupmenu Krakatoa_SchematicFlow_RightClickMenus.ForceAdditiveModeNodeRCMenu pos:mouse.screenpos
					"Use Emission": popupmenu Krakatoa_SchematicFlow_RightClickMenus.EmissionNodeRCMenu pos:mouse.screenpos
					"Use Absorption": popupmenu Krakatoa_SchematicFlow_RightClickMenus.AbsorptionNodeRCMenu pos:mouse.screenpos
					"Local KCMs":  popupmenu Krakatoa_SchematicFlow_RightClickMenus.KCMsNodeRCMenu pos:mouse.screenpos 
					"Particle File Output": popupmenu Krakatoa_SchematicFlow_RightClickMenus.ParticleFileOutputRCMenu pos:mouse.screenpos 
					"Material": popupmenu Krakatoa_SchematicFlow_RightClickMenus.MaterialNodeRCMenu pos:mouse.screenpos 
					
				)
				
				if matchPattern Krakatoa_SchematicFlow_Tree[lastNodeClick][1] pattern:"*MBlur*" do popupmenu Krakatoa_SchematicFlow_RightClickMenus.MotionBlurNodeRCMenu pos:mouse.screenpos
				if matchPattern Krakatoa_SchematicFlow_Tree[lastNodeClick][1] pattern:"*Env.Refl*" do 
				(
					Krakatoa_SchematicFlow_RightClickMenus.EnvReflectionNodeRCMenu.mnu_enableEnvironmentMap.text = if EnvironmentMap == undefined then "No Environment Map" else "Use ["+ EnvironmentMap as string+"]"
					popupmenu Krakatoa_SchematicFlow_RightClickMenus.EnvReflectionNodeRCMenu	pos:mouse.screenpos
				)
				if matchPattern Krakatoa_SchematicFlow_Tree[lastNodeClick][1] pattern:"Channel Override" then popupmenu Krakatoa_SchematicFlow_RightClickMenus.ChannelOverrideNodeRCMenu pos:mouse.screenpos
				if matchPattern Krakatoa_SchematicFlow_Tree[lastNodeClick][1] pattern:"Color Override*" do popupmenu Krakatoa_SchematicFlow_RightClickMenus.ColorOverrideNodeRCMenu pos:mouse.screenpos
				if matchPattern Krakatoa_SchematicFlow_Tree[lastNodeClick][1] pattern:"Emission Override*" do popupmenu Krakatoa_SchematicFlow_RightClickMenus.EmissionOverrideNodeRCMenu pos:mouse.screenpos
				if matchPattern Krakatoa_SchematicFlow_Tree[lastNodeClick][1] pattern:"Absorption Override*" do popupmenu Krakatoa_SchematicFlow_RightClickMenus.AbsorptionOverrideNodeRCMenu pos:mouse.screenpos
				if matchPattern Krakatoa_SchematicFlow_Tree[lastNodeClick][1] pattern:"Density Override*" do popupmenu Krakatoa_SchematicFlow_RightClickMenus.DensityOverrideNodeRCMenu pos:mouse.screenpos
					
				--if matchPattern Krakatoa_SchematicFlow_Tree[lastNodeClick][1] pattern:"*Object*Vertices*" do popupmenu Krakatoa_SchematicFlow_RightClickMenus.GetParticlesFromNodeRCMenu pos:mouse.screenpos 
				
				if matchPattern Krakatoa_SchematicFlow_Tree[lastNodeClick][1] pattern:"RE:*" do popupmenu Krakatoa_SchematicFlow_RightClickMenus.RenderElementsRCMenu pos:mouse.screenpos 
				if matchPattern Krakatoa_SchematicFlow_Tree[lastNodeClick][1] pattern:"Sort For*Light*" do popupmenu Krakatoa_SchematicFlow_RightClickMenus.LightsNodeRCMenu pos:mouse.screenpos 
				if matchPattern Krakatoa_SchematicFlow_Tree[lastNodeClick][1] pattern:"*Light Pass*" do popupmenu Krakatoa_SchematicFlow_RightClickMenus.LightsNodeRCMenu pos:mouse.screenpos 
					
				if matchPattern Krakatoa_SchematicFlow_Tree[lastNodeClick][1] pattern:"Sort For View*" do popupmenu Krakatoa_SchematicFlow_RightClickMenus.ViewsNodeRCMenu pos:mouse.screenpos 
				if matchPattern Krakatoa_SchematicFlow_Tree[lastNodeClick][1] pattern:"*PRT Loader*" do popupmenu Krakatoa_SchematicFlow_RightClickMenus.PRTLoadersNodeRCMenu pos:mouse.screenpos 
				if matchPattern Krakatoa_SchematicFlow_Tree[lastNodeClick][1] pattern:"*PRT Volume*" do popupmenu Krakatoa_SchematicFlow_RightClickMenus.PRTVolumesNodeRCMenu pos:mouse.screenpos 
				if matchPattern Krakatoa_SchematicFlow_Tree[lastNodeClick][1] pattern:"*PRT Surface*" do popupmenu Krakatoa_SchematicFlow_RightClickMenus.PRTSurfacesNodeRCMenu pos:mouse.screenpos 
					
				if matchPattern Krakatoa_SchematicFlow_Tree[lastNodeClick][1] pattern:"*Geometry Object*" do popupmenu Krakatoa_SchematicFlow_RightClickMenus.GeometryVerticesNodeRCMenu pos:mouse.screenpos 
				if matchPattern Krakatoa_SchematicFlow_Tree[lastNodeClick][1] pattern:"*Legacy System*" do popupmenu Krakatoa_SchematicFlow_RightClickMenus.LegacySystemsNodeRCMenu pos:mouse.screenpos 
				if matchPattern Krakatoa_SchematicFlow_Tree[lastNodeClick][1] pattern:"*Thinking Particles*" do popupmenu Krakatoa_SchematicFlow_RightClickMenus.TPNodeRCMenu pos:mouse.screenpos 

				if matchPattern Krakatoa_SchematicFlow_Tree[lastNodeClick][1] pattern:"*PFlow Geometry*" do popupmenu Krakatoa_SchematicFlow_RightClickMenus.PFlowGeometryNodeRCMenu pos:mouse.screenpos 
				if matchPattern Krakatoa_SchematicFlow_Tree[lastNodeClick][1] pattern:"*PFlow Phantom*" do popupmenu Krakatoa_SchematicFlow_RightClickMenus.PFlowPhantomNodeRCMenu pos:mouse.screenpos 
				if matchPattern Krakatoa_SchematicFlow_Tree[lastNodeClick][1] pattern:"*PFlow BBox*" do popupmenu Krakatoa_SchematicFlow_RightClickMenus.PFlowBBoxNodeRCMenu pos:mouse.screenpos 
				if matchPattern Krakatoa_SchematicFlow_Tree[lastNodeClick][1] pattern:"*FumeFX*" do popupmenu Krakatoa_SchematicFlow_RightClickMenus.FumeFXNodeRCMenu pos:mouse.screenpos 
				if matchPattern Krakatoa_SchematicFlow_Tree[lastNodeClick][1] pattern:"*Phoenix*" do popupmenu Krakatoa_SchematicFlow_RightClickMenus.PhoenixNodeRCMenu pos:mouse.screenpos 
				
				if matchPattern Krakatoa_SchematicFlow_Tree[lastNodeClick][1] pattern:"*PRT Hair*" do popupmenu Krakatoa_SchematicFlow_RightClickMenus.PRTHairNodeRCMenu pos:mouse.screenpos 
				if matchPattern Krakatoa_SchematicFlow_Tree[lastNodeClick][1] pattern:"*PRT Maker*" do popupmenu Krakatoa_SchematicFlow_RightClickMenus.PRTMakerNodeRCMenu pos:mouse.screenpos 
				if matchPattern Krakatoa_SchematicFlow_Tree[lastNodeClick][1] pattern:"*PRT Source*" do popupmenu Krakatoa_SchematicFlow_RightClickMenus.PRTSourceNodeRCMenu pos:mouse.screenpos 
				if matchPattern Krakatoa_SchematicFlow_Tree[lastNodeClick][1] pattern:"*PRT Field*" do popupmenu Krakatoa_SchematicFlow_RightClickMenus.PRTFieldNodeRCMenu pos:mouse.screenpos 
				if matchPattern Krakatoa_SchematicFlow_Tree[lastNodeClick][1] pattern:"*Stoke*" do popupmenu Krakatoa_SchematicFlow_RightClickMenus.StokeNodeRCMenu pos:mouse.screenpos 
					
				if matchPattern Krakatoa_SchematicFlow_Tree[lastNodeClick][1] pattern:"Isotropic" or \
					matchPattern Krakatoa_SchematicFlow_Tree[lastNodeClick][1] pattern:"Phong Surface"  or \
					matchPattern Krakatoa_SchematicFlow_Tree[lastNodeClick][1] pattern:"Henyey*"  or \
					matchPattern Krakatoa_SchematicFlow_Tree[lastNodeClick][1] pattern:"Schlick" or \
					matchPattern Krakatoa_SchematicFlow_Tree[lastNodeClick][1] pattern:"*Kajiya*" or \
					matchPattern Krakatoa_SchematicFlow_Tree[lastNodeClick][1] pattern:"*Kong*" do
						popupmenu Krakatoa_SchematicFlow_RightClickMenus.ShadingNodeRCMenu pos:mouse.screenpos 
				
				if matchPattern Krakatoa_SchematicFlow_Tree[lastNodeClick][1] pattern:"*SpecularPower*" do  popupmenu Krakatoa_SchematicFlow_RightClickMenus.SpecularPowerNodeRCMenu pos:mouse.screenpos  
				if matchPattern Krakatoa_SchematicFlow_Tree[lastNodeClick][1] pattern:"*SpecularLevel*" do  popupmenu Krakatoa_SchematicFlow_RightClickMenus.SpecularLevelNodeRCMenu pos:mouse.screenpos  
				if matchPattern Krakatoa_SchematicFlow_Tree[lastNodeClick][1] pattern:"*PhaseEccentricity*" do  popupmenu Krakatoa_SchematicFlow_RightClickMenus.PhaseEccentricityNodeRCMenu pos:mouse.screenpos  
				
			)
			else
				::Krakatoa_updateSchematicFlow()
		)
		
		on hc connectionChanged fromNodeIndex toNodeIndex toSocketID fromSocketID status toSocketCount do
		(
			::Krakatoa_updateSchematicFlow()
		)
		on Krakatoa_SchematicFlow_Rollout open do
		(
			try(hc.useDrawLayers = true)catch()
			hc.drawShadows = true
			hc.allowZoom  = true
			try(hc.zoomAboutMouse = false)catch()
			hc.drawMenuBars = true
			hc.allowUIDelete = false
			showGrid()
			--Krakatoa_SchematicFlow_Rollout.title = "Krakatoa v"+ FranticParticles.Version + " Schematic Flow"
		)
		
		on Krakatoa_SchematicFlow_Rollout resized val do 
		(
			hc.width = val.x
			hc.height = val.y
			hc.activeNode = Krakatoa_SchematicFlow_Tree.count
			hc.pan = ([hc.width, hc.height] - [900,theTreeHeight]*hc.zoom + [0,-10])
			setIniSetting (getDir #plugcfg + "/Krakatoa/KrakatoaPreferences.ini") "SchematicFlow" "Size" (val as string)
		)
		
		on hc mouseScroll do
		(
			if hc.zoom > 1.0 do hc.zoom = 1.0
			hc.pan = ([hc.width, hc.height] - [900,theTreeHeight]*hc.zoom + [0,-10])
			showGrid()
		)
		
		on Krakatoa_SchematicFlow_Rollout moved pos do
		(
			setIniSetting (getDir #plugcfg + "/Krakatoa/KrakatoaPreferences.ini") "SchematicFlow" "Position" (pos as string)
		)
		
		on Krakatoa_SchematicFlow_Rollout close do
		(
			deleteAllChangeHandlers id:#KrakatoaSchematicFlow
			callbacks.removeScripts id:#KrakatoaSchematicFlow
		)
		
		fn registerCallbacks =
		(
			deleteAllChangeHandlers id:#KrakatoaSchematicFlow
			if selection.count > 0 do
			(
				when parameters selection change id:#KrakatoaSchematicFlow handleAt:#redrawViews do 
				(
					::Krakatoa_updateSchematicFlow()
				)
			)
		)
	)
	
	fn Krakatoa_updateSchematicFlow =
	(
		--print Krakatoa_SchematicFlow_Rollout.open
		if classof renderers.current == Krakatoa and Krakatoa_SchematicFlow_Rollout.open == true and (timeStamp() - ::Krakatoa_SchematicFlow_LastUpdate) > 1000.0 do --
		(
			::Krakatoa_SchematicFlow_LastUpdate = timeStamp()
			Krakatoa_SchematicFlow_Rollout.title = "Krakatoa Schematic Flow - Updating..."
			local st = timeStamp()
			Krakatoa_SchematicFlow_Rollout.defineTree()
			--format "defineTree: % sec.\n" ((timeStamp()-st)/1000.0)
			local st = timeStamp()
			Krakatoa_SchematicFlow_Rollout.createNodeTree init:true			
			--format "createNodeTree: % sec.\n" ((timeStamp()-st)/1000.0)
			
			local theSize = [Krakatoa_SchematicFlow_Rollout.width, Krakatoa_SchematicFlow_Rollout.height]
			--if theSize.y < Krakatoa_SchematicFlow_Rollout.theTreeHeight+10 do theSize.y = Krakatoa_SchematicFlow_Rollout.theTreeHeight+10
			Krakatoa_SchematicFlow_Rollout.resized theSize
			Krakatoa_SchematicFlow_Rollout.title = "Krakatoa Schematic Flow"
		)
	)		
	
)	
macroScript SchematicFlow category:"Krakatoa" icon:#("Krakatoa",10) tooltip:"Krakatoa Schematic Flow"
(	
	on isEnabled return classof renderers.current == Krakatoa
	on execute do
	(
		::Krakatoa_SchematicFlow_LastUpdate = 0
		try(destroyDialog Krakatoa_SchematicFlow_Rollout)catch()
		local thePos = execute (getIniSetting (getDir #plugcfg + "/Krakatoa/KrakatoaPreferences.ini") "SchematicFlow" "Position")
		if thePos == OK do thePos = [100,100]
		local theSize = execute (getIniSetting (getDir #plugcfg + "/Krakatoa/KrakatoaPreferences.ini") "SchematicFlow" "Size")
		if theSize == OK do theSize = [900,600]
		if theSize.x < 300 do theSize.x = 400
		if theSize.y < 300 do theSize.y = 300
		if thePos.x+theSize.x > sysinfo.DesktopSize.x do thePos.x = sysinfo.DesktopSize.x-theSize.x
		if thePos.x<0 do thePos.x = 0
		if thePos.y+theSize.y > sysinfo.DesktopSize.y do thePos.y = sysinfo.DesktopSize.y-theSize.y
		if thePos.y<0 do thePos.y = 0
			
		createDialog Krakatoa_SchematicFlow_Rollout theSize.x theSize.y thePos.x thePos.y style:#(#style_titlebar, #style_border, #style_sysmenu, #style_resizing, #style_minimizebox, #style_maximizebox) menu:Krakatoa_SchematicFlow_MainMenu
		registerViewWindow Krakatoa_SchematicFlow_Rollout
		::Krakatoa_updateSchematicFlow()
		
		callbacks.removeScripts id:#KrakatoaSchematicFlow
		--callbacks.addScript #SelectionSetChanged "try(Krakatoa_SchematicFlow_Rollout.registerCallbacks())catch()" id:#KrakatoaSchematicFlow
	)
)
