-- Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
-- SPDX-License-Identifier: Apache-2.0
(
	global Krakatoa_VFB_methods, Krakatoa_GUI_Main, Krakatoa_GUI_RenderGlobalValues, Krakatoa_CustomizeRollouts_Dialog
	global Krakatoa_VFB_Overlay_Rollout, Krakatoa_VFB_Left_Rollout, Krakatoa_VFB_Right_Rollout

	global Krakatoa_PresetsArrowBitmap, Krakatoa_PresetsArrowBitmap_Base
	
	local useBorder = true

	fn RefreshMainGUI =
	(
		FranticParticles.LogDebug "  !VFB: RefreshMainGUI() Called!"
		try(Krakatoa_GUI_Main.refresh_GUI())catch()
		Krakatoa_VFB_Overlay_Rollout.refresh_GUI()	
	)
	
	fn RefreshGlobalValuesGUI =
	(
		FranticParticles.LogDebug "  !VFB: RefreshGlobalValuesGUI() Called!"
		
		try(
			Krakatoa_GUI_RenderGlobalValues.refresh_GUI()
		)catch()
		Krakatoa_VFB_Overlay_Rollout.refresh_GUI()			
	)
	
	rollout Krakatoa_InitializeGUI_Dialog "Initializing Krakatoa GUI..."
	(
		label lbl_init01 "Initializing Krakatoa GUI...This might take a moment."
	)
	
	fn initializeKrakatoaGUI =
	(
		FranticParticles.LogDebug "  !VFB: initializeKrakatoaGUI() Called!"
		
		if Krakatoa_Gui_floater == undefined do 
		(
			--createDialog Krakatoa_InitializeGUI_Dialog 300 30
			FranticParticleRenderMXS.OpenGUI initOnly:true
			--macros.run "Krakatoa" "KrakatoaGUI"
			--destroyDialog Krakatoa_InitializeGUI_Dialog
		)	
	)	
	
	global Krakatoa_VFB_Menus 
	struct Krakatoa_VFB_Menus_Struct
	(
		RenderModeRCMenu,
		ScatterModeRCMenu,
		
		LightingPassDensityRCMenu,
		FinalPassDensityRCMenu,
		DrawPointFilterRCMenu,
		SelfShadowFilterRCMenu,
		PresetsAndHistoryRolloutRCMenu,
		MainControlsRolloutRCMenu,
		ChannelsRolloutRCMenu,
		ParticleSystemsAndLoadersRCMenu,
		MatteObjectsRolloutRCMenu,
		ShadowsOnGeometryRolloutRCMenu,
		AmbientPMERolloutRCMenu,
		PreferencesRolloutRCMenu,
		InteractiveUpdatesRCMenu
	)
	
	rcMenu RenderModeRCMenu 
	(
		local state = try(FranticParticles.getProperty "RenderingMethod" == "Particle Rendering")catch(true)
		menuItem mnu_Particles "Particles" checked:state
		menuItem mnu_Voxels "Voxels" checked:(not state)
		on mnu_Particles picked do
		(
			FranticParticles.SetProperty "RenderingMethod" "Particle Rendering"
			RefreshMainGUI()
			Krakatoa_VFB_Left_Rollout.Refresh_GUI()
			Krakatoa_VFB_methods.InteractiveUpdate()
		)
		on mnu_Voxels picked do
		(
			FranticParticles.SetProperty "RenderingMethod" "Voxel Rendering"
			RefreshMainGUI()
			Krakatoa_VFB_Left_Rollout.Refresh_GUI()
			Krakatoa_VFB_methods.InteractiveUpdate()
		)		
	)
	

	rcMenu ScatterModeRCMenu
	(
		local state = try(findItem #("Isotropic","Phong Surface", "Henyey-Greenstein","Schlick","Kajiya-Kay Hair","Marschner Hair") (FranticParticles.getProperty "PhaseFunction"))catch(0)
		menuItem mnu_Isotropic "Isotropic" checked:(state == 1)
		menuItem mnu_PhongSurface "Phong Surface" checked:(state == 2)
		menuItem mnu_HGreenstein "Henyey-Greenstein" checked:(state == 3)
		menuItem mnu_Schlick "Schlick" checked:(state == 4)
		menuItem mnu_KajiyaKay "Kajiya-Kay Hair" checked:(state == 5)
		menuItem mnu_Marschner "Marschner Hair" checked:(state == 6)
			
		on mnu_Isotropic picked do
		(
			FranticParticles.SetProperty "PhaseFunction" "Isotropic"
			FranticParticleRenderMXS.defineShaderRollout (FranticParticles.GetProperty "PhaseFunction")
			RefreshMainGUI()
			Krakatoa_VFB_Left_Rollout.Refresh_GUI()
			Krakatoa_VFB_methods.InteractiveUpdate()
		)		
		on mnu_PhongSurface picked do
		(
			FranticParticles.SetProperty "PhaseFunction" "Phong Surface"
			FranticParticleRenderMXS.defineShaderRollout (FranticParticles.GetProperty "PhaseFunction")
			RefreshMainGUI()
			Krakatoa_VFB_Left_Rollout.Refresh_GUI()
			Krakatoa_VFB_methods.InteractiveUpdate()
		)		
		on mnu_HGreenstein picked do
		(
			FranticParticles.SetProperty "PhaseFunction" "Henyey-Greenstein"
			FranticParticleRenderMXS.defineShaderRollout (FranticParticles.GetProperty "PhaseFunction")
			RefreshMainGUI()
			Krakatoa_VFB_Left_Rollout.Refresh_GUI()
			Krakatoa_VFB_methods.InteractiveUpdate()
		)		
		on mnu_Schlick picked do
		(
			FranticParticles.SetProperty "PhaseFunction" "Schlick"
			FranticParticleRenderMXS.defineShaderRollout (FranticParticles.GetProperty "PhaseFunction")
			RefreshMainGUI()
			Krakatoa_VFB_Left_Rollout.Refresh_GUI()
			Krakatoa_VFB_methods.InteractiveUpdate()
		)		
		on mnu_KajiyaKay picked do
		(
			FranticParticles.SetProperty "PhaseFunction" "Kajiya-Kay Hair"
			FranticParticleRenderMXS.defineShaderRollout (FranticParticles.GetProperty "PhaseFunction")
			RefreshMainGUI()
			Krakatoa_VFB_Left_Rollout.Refresh_GUI()
			Krakatoa_VFB_methods.InteractiveUpdate()
		)	
		on mnu_Marschner picked do
		(
			FranticParticles.SetProperty "PhaseFunction" "Marschner Hair"
			FranticParticleRenderMXS.defineShaderRollout (FranticParticles.GetProperty "PhaseFunction")
			RefreshMainGUI()
			Krakatoa_VFB_Left_Rollout.Refresh_GUI()
			Krakatoa_VFB_methods.InteractiveUpdate()
		)			
	)
	

	rcMenu LightingPassDensityRCMenu 
	(
		local state = try(FranticParticles.GetProperty "Lighting:Density:DensityMethod")catch(0)
		menuItem mnu_VolumetricDensity "Lighting Pass : Volumetric Density" checked:(state == "Volumetric Density")
		menuItem mnu_ConstantAlpha "Lighting Pass : Constant Alpha" checked:(state == "Constant Alpha")
		
		on mnu_VolumetricDensity picked do
		(
			FranticParticles.SetProperty "Lighting:Density:DensityMethod" "Volumetric Density"
			Krakatoa_VFB_Left_Rollout.refresh_GUI()
			RefreshMainGUI()			
			Krakatoa_VFB_methods.InteractiveUpdate()
		)
		on mnu_ConstantAlpha picked do
		(
			FranticParticles.SetProperty "Lighting:Density:DensityMethod" "Constant Alpha"
			Krakatoa_VFB_Left_Rollout.refresh_GUI()
			RefreshMainGUI()		
			Krakatoa_VFB_methods.InteractiveUpdate()			
		)		
	)
	
	rcMenu FinalPassDensityRCMenu 
	(
		local state = try(FranticParticles.GetProperty "Density:DensityMethod")catch(0)
		menuItem mnu_VolumetricDensity "Final Pass : Volumetric Density" checked:(state == "Volumetric Density")
		menuItem mnu_AdditiveDensity "Final Pass : Additive Density" checked:(state == "Additive Density")
		menuItem mnu_ConstantAlpha "Final Pass : Constant Alpha" checked:(state == "Constant Alpha")
		
		on mnu_VolumetricDensity picked do
		(
			FranticParticles.SetProperty "Density:DensityMethod" "Volumetric Density"
			Krakatoa_VFB_Left_Rollout.refresh_GUI()
			RefreshMainGUI()	
			Krakatoa_VFB_methods.InteractiveUpdate()			
		)
		on mnu_AdditiveDensity picked do
		(
			FranticParticles.SetProperty "Density:DensityMethod" "Additive Density"
			Krakatoa_VFB_Left_Rollout.refresh_GUI()
			RefreshMainGUI()		
			Krakatoa_VFB_methods.InteractiveUpdate()			
		)		
		on mnu_ConstantAlpha picked do
		(
			FranticParticles.SetProperty "Density:DensityMethod" "Constant Alpha"
			Krakatoa_VFB_Left_Rollout.refresh_GUI()
			RefreshMainGUI()			
			Krakatoa_VFB_methods.InteractiveUpdate()
		)			
	)	
	
	rcMenu DrawPointFilterRCMenu 
	(
		local state = try(FranticParticles.GetProperty "DrawPointFilter")catch(0)
		menuItem mnu_NearestNeighbor "Draw Point Filter : Nearest Neighbor" checked:(state == "Nearest Neighbor")
		menuItem mnu_Bilenear "Draw Point Filter : Bilinear" checked:(state == "Bilinear")
		/*menuItem mnu_Bilenear2 "Draw Point Filter : Bilinear Filter 2" checked:(state == "Bilinear2")
		menuItem mnu_Bilenear4 "Draw Point Filter : Bilinear Filter 4" checked:(state == "Bilinear4")
		menuItem mnu_Bilenear8 "Draw Point Filter : Bilinear Filter 8" checked:(state == "Bilinear8")*/
		menuItem mnu_Bicubic "Draw Point Filter : Bicubic" checked:(state == "Bicubic")
		
		fn setDrawPointFilter mode =
		(
			FranticParticles.SetProperty "DrawPointFilter" mode 
			Krakatoa_VFB_Right_Rollout.refresh_GUI()
			RefreshMainGUI()
			Krakatoa_VFB_methods.InteractiveUpdate()
		)
		
		on mnu_NearestNeighbor picked do setDrawPointFilter "Nearest Neighbor"
		on mnu_Bilenear picked do setDrawPointFilter "Bilinear"
		/*on mnu_Bilenear2 picked do setDrawPointFilter "Bilinear2"
		on mnu_Bilenear4 picked do setDrawPointFilter "Bilinear4"
		on mnu_Bilenear8 picked do setDrawPointFilter "Bilinear8"*/
		on mnu_Bicubic picked do setDrawPointFilter "Bicubic"
		
	)	

	rcMenu SelfShadowFilterRCMenu 
	(
		local state = try(FranticParticles.GetProperty "AttenuationLookupFilter")catch(0)
		menuItem mnu_NearestNeighbor "Self-Shadow Filter : Nearest Neighbor" checked:(state == "Nearest Neighbor")

		menuItem mnu_Bilenear "Self-Shadow Filter : Bilinear" checked:(state == "Bilinear")
		/*menuItem mnu_Bilenear2 "Self-Shadow Filter : Bilinear Filter 2" checked:(state == "Bilinear2")
		menuItem mnu_Bilenear4 "Self-Shadow Filter : Bilinear Filter 4" checked:(state == "Bilinear4")
		menuItem mnu_Bilenear8 "Self-Shadow Filter : Bilinear Filter 8" checked:(state == "Bilinear8")*/
		menuItem mnu_Bicubic "Self-Shadow Filter : Bicubic" checked:(state == "Bicubic")

		fn setAttenuationLookupFilter mode =
		(
			FranticParticles.SetProperty "AttenuationLookupFilter" mode 
			Krakatoa_VFB_Right_Rollout.refresh_GUI()
			RefreshMainGUI()
			Krakatoa_VFB_methods.InteractiveUpdate()
		)		
		
		on mnu_NearestNeighbor picked do setAttenuationLookupFilter "Nearest Neighbor"
		on mnu_Bilenear picked do setAttenuationLookupFilter "Bilinear"
		/*on mnu_Bilenear2 picked do setAttenuationLookupFilter "Bilinear2"
		on mnu_Bilenear4 picked do setAttenuationLookupFilter "Bilinear4"
		on mnu_Bilenear8 picked do setAttenuationLookupFilter "Bilinear8"*/
		on mnu_Bicubic picked do setAttenuationLookupFilter "Bicubic"
	)	
	
	fn navigateToKrakatoaRollout theRollout =
	(
		FranticParticles.LogDebug "  !VFB: navigateToKrakatoaRollout() Called!"

		if Krakatoa_Gui_floater == undefined do macros.run "Krakatoa" "KrakatoaGUI"
		try
		(
			if findItem Krakatoa_Gui_floater.rollouts theRollout > 0 then
			(
				if not Krakatoa_Gui_floater.open do FranticParticleRenderMXS.OpenGUI()
				for i in Krakatoa_Gui_floater.rollouts do i.open = false
				theRollout.open = true
				theRollout.scrollPos = 0 
			)
			else if findItem Krakatoa_Gui_floater_2.rollouts theRollout > 0 then
			(
				if not Krakatoa_Gui_floater_2.open do FranticParticleRenderMXS.OpenGUI()				
				for i in Krakatoa_GUI_Floater_2.rollouts do i.open = false
				theRollout.open = true
				theRollout.scrollPos = 0 
			)
			else if findItem Krakatoa_Gui_floater_3.rollouts theRollout > 0 then
			(
				try(removeRollout theRollout Krakatoa_Gui_floater_3)catch()
				try(createDialog theRollout)catch()
			)
			else createDialog theRollout
		)catch()
	)
	
	rcMenu PresetsAndHistoryRolloutRCMenu 
	(
		menuItem mnu_OpenRollout "Open [Presets And History] Rollout"
		on mnu_OpenRollout picked do navigateToKrakatoaRollout Krakatoa_GUI_Presets
	)
	
	rcMenu MainControlsRolloutRCMenu
	(
		menuItem mnu_OpenRollout_GlobalRV "Open [Global Render Values] Rollout"
		on mnu_OpenRollout_GlobalRV picked do navigateToKrakatoaRollout Krakatoa_GUI_RenderGlobalValues
		
		menuItem mnu_OpenRollout "Open [Main Controls] Rollout"
		on mnu_OpenRollout picked do navigateToKrakatoaRollout Krakatoa_GUI_Main
	)
	
	rcMenu ChannelsRolloutRCMenu
	(
		menuItem mnu_OpenChannelsRollout "Open [Memory Channels] Rollout"
		separator sep_channels_10
		menuItem mnu_OpenSaveParticlesRollout "Open [Save Particles] Rollout"
		menuItem mnu_OpenPartitionRollout "Open [Partitioning] Rollout"
		
		on mnu_OpenChannelsRollout picked do navigateToKrakatoaRollout Krakatoa_GUI_Channels
		on mnu_OpenSaveParticlesRollout picked do navigateToKrakatoaRollout Krakatoa_GUI_SaveParticles
		on mnu_OpenPartitionRollout picked do navigateToKrakatoaRollout Krakatoa_GUI_Partition
			
	)
	
	rcMenu ParticleSystemsAndLoadersRCMenu
	(
		menuItem mnu_OpenExplorer "Open [Krakatoa Explorers] Floater..."
		menuItem mnu_OpenSchematicFlow "Open [Krakatoa Schematic Flow] Dialog..."
		separator sep_explorers_10
		menuItem mnu_OpenParticleDataViewer "Open [Krakatoa Particle Data Viewer] Dialog..."
		menuItem mnu_OpenPRTScanner "Open [Krakatoa PRT Scanner] Floater..."
		separator sep_explorers_20		
		menuItem mnu_OpenShadowsExplorer "Open [Krakatoa Shadows Explorer] Dialog..."
		menuItem mnu_OpenMatteObjectsExplorer "Open [Krakatoa Matte Objects Explorer] Dialog..."
		
		on mnu_OpenExplorer picked do macros.run "Krakatoa" "KrakatoaExplorers"
		on mnu_OpenSchematicFlow picked do macros.run "Krakatoa" "SchematicFlow"
		on mnu_OpenParticleDataViewer picked do macros.run "Krakatoa" "KrakatoaParticleDataViewer"
		on mnu_OpenPRTScanner picked do macros.run "Krakatoa" "KrakatoaPRTscan"
		on mnu_OpenShadowsExplorer picked do macros.run "Krakatoa" "KrakatoaShadows"
		on mnu_OpenMatteObjectsExplorer picked do macros.run "Krakatoa" "KrakatoaMatteObjectsExplorer"
			
	)
	
	rcMenu	MatteObjectsRolloutRCMenu
	(
		menuItem mnu_OpenRollout "Open [Matte Objects] Rollout"
		on mnu_OpenRollout picked do navigateToKrakatoaRollout Krakatoa_GUI_MatteObjects
	)
	
	rcMenu	ShadowsOnGeometryRolloutRCMenu
	(
		menuItem mnu_OpenShadowsExplorer "Open [Krakatoa Shadows Explorer] Floater..."
		on mnu_OpenShadowsExplorer picked do macros.run "Krakatoa" "KrakatoaShadows"
	)
	
	rcMenu	AmbientPMERolloutRCMenu
	(
		menuItem mnu_OpenRollout "Open [Ambient PME] Rollout"
		on mnu_OpenRollout picked do navigateToKrakatoaRollout Krakatoa_GUI_AmbientPME
	)
	
	rcMenu	PreferencesRolloutRCMenu	
	(
		menuItem mnu_OpenRollout "Open [Preferences] Dialog..."
		separator sep_10	
		menuItem mnu_OpenLogWindow "Open [Krakatoa Log Window]..."
		separator sep_20	
		menuItem mnu_OpenNotesRollout "Open [Notes] Dialog..."
		menuItem mnu_OpenAboutRollout "Open [About] Dialog..."
		
		on mnu_OpenRollout picked do macros.run "Krakatoa" "KrakatoaPreferences"	
		on mnu_OpenNotesRollout picked do macros.run "Krakatoa" "KrakatoaNotes"	
		on mnu_OpenAboutRollout picked do macros.run "Krakatoa" "AboutKrakatoa"	
			
		on mnu_OpenLogWindow picked do 
		(
			FranticParticles.LogWindowVisible = true
			updateToolbarButtons()				
		)
	)
	
	rcMenu InteractiveUpdatesRCMenu 
	(
		menuitem mnu_renderRes_2 "Double Resolution" checked:((FranticParticles.GetProperty "IterativeRender:ScaleFactor") =="2")
		separator sep_10
		menuitem mnu_renderRes_1 "Full Resolution" checked:((FranticParticles.GetProperty "IterativeRender:ScaleFactor") =="1")
		separator sep_20
		menuitem mnu_renderRes_1_2 "1/2 Resolution" checked:((FranticParticles.GetProperty "IterativeRender:ScaleFactor") =="1/2")
		menuitem mnu_renderRes_1_4 "1/4 Resolution" checked:((FranticParticles.GetProperty "IterativeRender:ScaleFactor") =="1/4")
		menuitem mnu_renderRes_1_8 "1/8 Resolution" checked:((FranticParticles.GetProperty "IterativeRender:ScaleFactor") =="1/8")
		menuitem mnu_renderRes_1_16 "1/16 Resolution" checked:((FranticParticles.GetProperty "IterativeRender:ScaleFactor") =="1/16")
		separator sep_30
		
		menuItem mnu_Threshold1 "InterActive Update Threshold: 1 sec." checked:(FranticParticles.GetProperty "VFB:InteractiveUpdateThreshold" == "1000")
		menuItem mnu_Threshold2 "InterActive Update Threshold: 2 sec." checked:(FranticParticles.GetProperty "VFB:InteractiveUpdateThreshold" == "2000")
		menuItem mnu_Threshold5 "InterActive Update Threshold: 5 sec." checked:(FranticParticles.GetProperty "VFB:InteractiveUpdateThreshold" == "5000")
		menuItem mnu_Threshold10 "InterActive Update Threshold: 10 sec." checked:(FranticParticles.GetProperty "VFB:InteractiveUpdateThreshold" == "10000")
		separator sep_50
		menuItem mnu_ToggleInteractiveUpdates "Enable InterActive Updates" checked:(FranticParticles.GetBoolProperty "VFB:InteractiveUpdate")
		
		on mnu_ToggleInteractiveUpdates picked do
		(
			FranticParticles.SetProperty "VFB:InteractiveUpdate" ( (not (FranticParticles.GetBoolProperty "VFB:InteractiveUpdate") ) as string)
			Krakatoa_VFB_Right_Rollout.refresh_GUI()
		)	
		on mnu_Threshold1 picked do FranticParticles.SetProperty "VFB:InteractiveUpdateThreshold" "1000"
		on mnu_Threshold2 picked do FranticParticles.SetProperty "VFB:InteractiveUpdateThreshold" "2000"
		on mnu_Threshold5 picked do FranticParticles.SetProperty "VFB:InteractiveUpdateThreshold" "5000"
		on mnu_Threshold10 picked do FranticParticles.SetProperty "VFB:InteractiveUpdateThreshold" "10000"
			
		on mnu_ScaleDensity picked do 
		(
			Krakatoa_RCMenu_Struct.IterativeOptions_ScaleDensity = not Krakatoa_RCMenu_Struct.IterativeOptions_ScaleDensity
		)	
		
		on mnu_renderRes_2 picked do 
		(
			FranticParticles.SetProperty "IterativeRender:ScaleFactor" "2"
			Krakatoa_VFB_Right_Rollout.refresh_GUI()
			
		)	
		on mnu_renderRes_1 picked do 
		(
			FranticParticles.SetProperty "IterativeRender:ScaleFactor" "1"
			Krakatoa_VFB_Right_Rollout.refresh_GUI()
			Krakatoa_GUI_Main.updateIterativeRenderText()
		)	
		on mnu_renderRes_1_2 picked do 
		(
			FranticParticles.SetProperty "IterativeRender:ScaleFactor" "1/2"
			Krakatoa_VFB_Right_Rollout.refresh_GUI()
			Krakatoa_GUI_Main.updateIterativeRenderText()
		)	
		on mnu_renderRes_1_4 picked do 
		(
			FranticParticles.SetProperty "IterativeRender:ScaleFactor" "1/4"
			Krakatoa_VFB_Right_Rollout.refresh_GUI()
			Krakatoa_GUI_Main.updateIterativeRenderText()
		)	
		on mnu_renderRes_1_8 picked do 
		(
			FranticParticles.SetProperty "IterativeRender:ScaleFactor" "1/8"
			Krakatoa_VFB_Right_Rollout.refresh_GUI()
			Krakatoa_GUI_Main.updateIterativeRenderText()
		)	
		on mnu_renderRes_1_16 picked do 
		(
			FranticParticles.SetProperty "IterativeRender:ScaleFactor" "1/16"
			Krakatoa_VFB_Right_Rollout.refresh_GUI()
			Krakatoa_GUI_Main.updateIterativeRenderText()
		)			
	)	

	Krakatoa_VFB_Menus = Krakatoa_VFB_Menus_Struct()
	
	Krakatoa_VFB_Menus.RenderModeRCMenu = RenderModeRCMenu
	Krakatoa_VFB_Menus.ScatterModeRCMenu = ScatterModeRCMenu
	
	Krakatoa_VFB_Menus.LightingPassDensityRCMenu = LightingPassDensityRCMenu
	Krakatoa_VFB_Menus.FinalPassDensityRCMenu = FinalPassDensityRCMenu
	Krakatoa_VFB_Menus.DrawPointFilterRCMenu = DrawPointFilterRCMenu
	Krakatoa_VFB_Menus.SelfShadowFilterRCMenu = SelfShadowFilterRCMenu
	Krakatoa_VFB_Menus.PresetsAndHistoryRolloutRCMenu = PresetsAndHistoryRolloutRCMenu 
	Krakatoa_VFB_Menus.MainControlsRolloutRCMenu = MainControlsRolloutRCMenu 
	Krakatoa_VFB_Menus.ChannelsRolloutRCMenu = ChannelsRolloutRCMenu 
	Krakatoa_VFB_Menus.ParticleSystemsAndLoadersRCMenu = ParticleSystemsAndLoadersRCMenu 
	Krakatoa_VFB_Menus.MatteObjectsRolloutRCMenu = MatteObjectsRolloutRCMenu 
	Krakatoa_VFB_Menus.ShadowsOnGeometryRolloutRCMenu = ShadowsOnGeometryRolloutRCMenu 
	Krakatoa_VFB_Menus.AmbientPMERolloutRCMenu = AmbientPMERolloutRCMenu 
	Krakatoa_VFB_Menus.PreferencesRolloutRCMenu = PreferencesRolloutRCMenu 
	Krakatoa_VFB_Menus.InteractiveUpdatesRCMenu = InteractiveUpdatesRCMenu

	struct Krakatoa_VFB_methods_struct
	(
		VFB_Interface,
		theFloaterArray = #(),
		
		fn InteractiveUpdate =
		(
			FranticParticles.LogDebug "  !VFB: InteractiveUpdate() Called!"
			
			if DaylightSimulationUtilities.IsRenderIterative() and (FranticParticles.GetBoolProperty "VFB:InteractiveUpdate") do
			(
				local theTime = FranticParticleRenderMXS.lastFrameRenderEndTime  - FranticParticleRenderMXS.lastFrameRenderStartTime
				if theTime < (FranticParticles.GetIntProperty "VFB:InteractiveUpdateThreshold") do  --AND Krakatoa_VFB_Right_Rollout.chk_enableParticleCache.checked 
				(
					Krakatoa_VFB_Right_Rollout.btn_render.caption = "Rendering..."
					initializeKrakatoaGUI()
					Krakatoa_GUI_Main.btn_quickRender.pressed()					
					Krakatoa_VFB_Right_Rollout.btn_render.caption = "RENDER"
				)	
			)
		),		
		
		fn VFB_DefineRollouts =
		(
			FranticParticles.LogDebug "  !VFB: VFB_DefineRollouts() Called!"
			
			try
			(
				Krakatoa_PresetsArrowBitmap_Base = openbitmap (getDir #usericons + "\\krakatoaGUI.bmp")
				Krakatoa_PresetsArrowBitmap = bitmap 512 16 color:red
				copy Krakatoa_PresetsArrowBitmap_Base Krakatoa_PresetsArrowBitmap 
			)
			catch	
			(
				Krakatoa_PresetsArrowBitmap_Base = bitmap 512 16 color:red
				Krakatoa_PresetsArrowBitmap = bitmap 512 16 color:red
			)		
			FranticParticleRenderMXS.updateIconColors()			
			
			--format ">KVFB: VFB_DefineRollouts Called...\n"
			rollout Krakatoa_VFB_Left_Rollout ""
			(
				button btn_renderMode "" pos:[0,0] width:70 height:18 border:useBorder tooltip:"Switch between Particle and Voxel Rendering."
				--button btn_densityMode "" pos:[0,18] width:70 height:18 border:useBorder tooltip:"Switch between Volumetric, Additive and\nConstant Alpha Density Modes."
				button btn_scatterMode "" pos:[0,18] width:70 height:18 border:useBorder tooltip:"Switch between Isotropic, Phong Surface, Henyey-Greenstein, Schlick, Kajiya-Kay and Marschner Scattering Models."
				
				label lbl_voxelSize "Voxel/Filter" pos:[72,1]
				spinner spn_voxelSize  range:[0.001,100000,1] pos:[95+30,1] fieldwidth:40
				button btn_voxelSizePresets ">>" height:18 width:18 pos:[147+30,0] 
				spinner spn_FilterRadius  range:[1,100,1] pos:[163+30,1] fieldwidth:32 type:#integer
				button btn_FilterRadiusPresets ">>" height:18 width:18 pos:[207+30,0] 
				
				checkbutton chk_useScatter "Color" pos:[225+30,0] width:45 height:18 border:useBorder enabled:false tooltip:"" highlightcolor:KrakatoaSkinColorsStruct.VFB
				checkbutton chk_colorOverride "O" pos:[270+30,0] width:15 height:18 border:useBorder tooltip:"Check to override the Color Channel with a Custom Color or Map." highlightcolor:KrakatoaSkinColorsStruct.VFB
				colorpicker clr_customColor pos:[282+30,0] width:20 height:18 modal:false color:white
				progressbar prg_colorOverrideMapAmount pos:[302+30,0] height:18 width:27 color:(white*0.5) value:100
				mapbutton map_colorOverride "n" pos:[330+30,0] width:17 height:18 border:useBorder tooltip:"Click to assign a Custom Color Map."
				
				checkbutton chk_useEmission "Emissn." pos:[225+30,18] width:45 height:18 border:useBorder tooltip:"Check to use the Emission Channel to make particles self-illuminated." highlightcolor:KrakatoaSkinColorsStruct.VFB
				checkbutton chk_EmissionOverride "O" pos:[270+30,18] width:15 height:18 border:useBorder tooltip:"Check to override the Emission Channel with a Custom Color or Map." highlightcolor:KrakatoaSkinColorsStruct.VFB
				colorpicker clr_EmissionColor pos:[282+30,18] width:20 height:18 modal:false color:black
				progressbar prg_EmissionOverrideMapAmount pos:[302+30,18] height:18 width:27 color:(white*0.5) value:50
				mapbutton map_EmissionOverride "n" pos:[330+30,18] width:17 height:18 border:useBorder tooltip:"Click to assign a Custom Emission Map."

				checkbutton chk_useAbsorption "Absorp." pos:[225+30,36] width:45 height:18 border:useBorder tooltip:"Check to use the Absorption Channel to cause particles to absorp R, G and B differently." highlightcolor:KrakatoaSkinColorsStruct.VFB
				checkbutton chk_AbsorptionOverride "O" pos:[270+30,36] width:15 height:18 border:useBorder tooltip:"Check to override the Absorption Channel with a Custom Color or Map." highlightcolor:KrakatoaSkinColorsStruct.VFB
				colorpicker clr_AbsorptionColor pos:[282+30,36] width:20 height:18 modal:false color:black
				progressbar prg_AbsorptionOverrideMapAmount pos:[302+30,36] height:18 width:27 color:(white*0.5) value:50
				mapbutton map_AbsorptionOverride "n" pos:[330+30,36] width:17 height:18 border:useBorder tooltip:"Click to assign a Custom Absorption Map."
				
				button btn_useDensity "Density" pos:[225+30,54] width:45 height:18 border:useBorder enabled:false
				checkbutton chk_DensityOverride "O" pos:[270+30,54] width:15 height:18 border:useBorder tooltip:"Check to override the Density Channel with a Custom Color or Map." highlightcolor:KrakatoaSkinColorsStruct.VFB
				colorpicker clr_DensityColor pos:[282+30,54] width:20 height:18 modal:false color:white
				progressbar prg_DensityOverrideMapAmount pos:[302+30,54] height:18 width:27 color:(white*0.5) value:50
				mapbutton map_DensityOverride "n" pos:[330+30,54] width:17 height:18 border:useBorder tooltip:"Click to assign a Custom Density Map."

				button btn_floatShaderParameters "Shader" pos:[70,18] width:40 height:18 border:useBorder --tooltip:"When checked, the PhaseEccentricity channel will be allocated per particle." highlightcolor:KrakatoaSkinColorsStruct.VFB
				
				
				button btn_SelfShadowFilter "Shdw:BiCube" pos:[0,36] width:70 height:18 border:useBorder tooltip:"Self-Shadow Filter"
				button btn_DrawPointFilter "Draw:BiLin" pos:[0,54] width:70 height:18 border:useBorder tooltip:"Draw Point Filter"
				checkbutton chk_EmissionStrength "Emission Strength" pos:[0,72] width:100 height:18 border:useBorder tooltip:"Use Emission Strength.\n\nWhen checked, the Emission Strength value will be used to scale the Emission channel.\n\nWhen unchecked, the Emission will be scaled by the Final Pass Density."
				checkbutton chk_RelativeEmissionStrength "Rel" pos:[100,72] width:23 height:18 border:useBorder tooltip:"Relative Emission Strenght.\n\nWhen checked, the Emission Strength value can be specified as a fraction of the Final Pass Density value.\n\nWhen unchecked, the Emission Strength value will be taken as absolute value."

				checkbutton chk_useEnvReflections "Env.Refl." pos:[110,18] width:56 height:18 border:useBorder tooltip:"Check to enable the rendering of Environment Reflection Maps." highlightcolor:KrakatoaSkinColorsStruct.VFB
				checkbutton chk_allocateReflectionStrength "Alloc." pos:[166,18] width:30 height:18 border:useBorder tooltip:"Check to allocate a ReflectionStrength Channel in memory." highlightcolor:KrakatoaSkinColorsStruct.VFB
				spinner spn_ReflectionStrength "" range:[0,1000.0,1.0] pos:[193,19] fieldwidth:32 type:#float scale:0.01
				button btn_ReflectionStrengthPreset ">>" width:18 height:18 pos:[237,18] images:#(Krakatoa_PresetsArrowBitmap,Krakatoa_PresetsArrowBitmap, 32,1,1,2,2)
				
				checkbutton chk_ignoreSceneLights "Ignore Lights" pos:[192+30,72] width:78 height:18 border:useBorder tooltip:"Check to ignore scene lights." highlightcolor:KrakatoaSkinColorsStruct.VFB
				checkbutton chk_additiveMode "Force Additive" pos:[270+30,72] width:77 height:18 border:useBorder tooltip:"Check to force Additive Rendering." highlightcolor:KrakatoaSkinColorsStruct.VFB
				
				spinner spn_shadowBilinearFilter "" range:[1,64,1] pos:[67,37] fieldwidth:25 type:#integer
				spinner spn_drawBilinearFilter "" range:[1,64,1] pos:[67,55] fieldwidth:25 type:#integer
				button btn_shadowBilinearFilterPreset ">>" width:18 height:18 pos:[68+37,36] images:#(Krakatoa_PresetsArrowBitmap,Krakatoa_PresetsArrowBitmap, 32,1,1,2,2)
				button btn_drawBilinearFilterPreset ">>" width:18 height:18 pos:[68+37,54] images:#(Krakatoa_PresetsArrowBitmap,Krakatoa_PresetsArrowBitmap, 32,1,1,2,2)
				
				spinner spn_LightingDensity "" range:[0,100000,100] pos:[68+53,37] fieldwidth:37
				spinner spn_FinalDensity "" range:[0,100000,100] pos:[68+53,55] fieldwidth:37
				spinner spn_EmissionStrength "" range:[0,100000,100] pos:[68+53,73] fieldwidth:37

				spinner spn_LightingDensityExp "" range:[-30,30,-1] pos:[120+47,37] fieldwidth:25 type:#integer
				spinner spn_FinalDensityExp "" range:[-30,30,-1] pos:[120+47,55] fieldwidth:25 type:#integer
				spinner spn_EmissionStrengthExp "" range:[-30,30,-1] pos:[120+47,73] fieldwidth:25 type:#integer
				
				button btn_lightingDensityPreset ">>" width:18 height:18 pos:[172+32,36] images:#(Krakatoa_PresetsArrowBitmap,Krakatoa_PresetsArrowBitmap, 32,1,1,2,2)
				button btn_finalDensityPreset ">>" width:18 height:18 pos:[172+32,54] images:#(Krakatoa_PresetsArrowBitmap,Krakatoa_PresetsArrowBitmap, 32,1,1,2,2)
				button btn_EmissionStrengthPreset ">>" width:18 height:18 pos:[172+32,72] images:#(Krakatoa_PresetsArrowBitmap,Krakatoa_PresetsArrowBitmap, 32,1,1,2,2)
				
				checkbutton chk_LightingPassDensity "Use" pos:[192+30,36] width:33 height:18 border:useBorder tooltip:"Check to use Lighting Pass Density.\n\nUncheck to lock to and use the Final Pass Density values for both Lighting and Final Pass Density."  highlightcolor:KrakatoaSkinColorsStruct.VFB
				checkbutton chk_RelativeLightingPassDensity "Rel." pos:[192+30,54] width:33 height:18 border:useBorder tooltip:"Relative Lighting Pass Density.\n\nWhen checked, the Lighting Pass Density value can be specified as a fraction of the Final Pass Density.\n\nWhen unchecked, the Lighting Pass Density will be used as absolute value."  highlightcolor:KrakatoaSkinColorsStruct.VFB
				
				dropdownlist ddl_viewsToRender pos:[348+30,-2] width:125
				button btn_UpdateViewport "Update List!" pos:[348+30,18] width:90 height:18 border:useBorder tooltip:"There is no automatic way to update the Viewports List when the viewports layout changes.\n\nPress this button to ensure the list above represents the actual viewports configuration." 
				button btn_SelectCamera "Select Camera!" pos:[348+30,36] width:90 height:18 border:useBorder tooltip:"Selects the current view's Camera for editing (if applicable)." 
				
				checkbutton chk_LockViewport "LOCK" pos:[348+120,20] width:34 height:34 border:useBorder tooltip:"When checked, the selected View will be locked for rendering.\n\nWhen unchecked, the active viewport will be rendered." 
				
				colorpicker clr_BackgroundColor pos:[348+120-3,54] width:37 height:18 modal:false color:black alpha:true
				checkbutton chk_OverrideBackgroundColor "Override BG Color" pos:[378,54] width:90 height:18 border:useBorder tooltip:"When checked, the background color will be replaced by the specified color value.\n\nWhen unchecked, the 3ds Max Environment Color or Map will be used." 
				
				button btn_GlobalChannelOverrides "[Global Overrides OFF]" pos:[378,72] width:124 height:18 border:useBorder tooltip:"Global Channel Overrides" 
				
				on btn_SelectCamera pressed do 
				(
					local theCamera = getNodeByName ddl_viewsToRender.selected
					if isValidNode theCamera do 
					(
						max modify mode
						select theCamera
					)
				)
				
				local indexArray = #()
				fn updateViewportsList =
				(
					renderSceneDialog.commit()
					local count = if rendUseActiveView then viewport.numViews else 4
					indexArray = for i = 1 to 4 collect viewport.GetID i
					ddl_viewsToRender.items = for i = 1 to count collect 
					(
						local theCamera = viewport.getCamera index:i 
						if isValidNode theCamera then
							theCamera.name
						else
						(
							case (viewport.getType index:i) of
							(
								default: ((viewport.getType index:i) as string)
								#view_persp_user: "Perspective"
								#view_front: "Front"
								#view_back: "Back"
								#view_top: "Top"
								#view_bottom: "Bottom"
								#view_left: "Left"
								#view_right: "Right"
								#view_grid: "Grid"
								#view_iso_user: "Orthographic"
							)
						)
					)
					if rendUseActiveView then 
						ddl_viewsToRender.selection = viewport.activeViewport 
					else
						if rendViewIndex != undefined and rendViewIndex > 0 do ddl_viewsToRender.selection = indexArray[rendViewIndex]
					chk_LockViewport.checked = not rendUseActiveView
					ddl_viewsToRender.tooltip = ddl_viewsToRender.selected
					btn_SelectCamera.enabled = (isValidNode (getNodeByName ddl_viewsToRender.selected)) 
				)
				
				on btn_UpdateViewport pressed do updateViewportsList()
				on ddl_viewsToRender selected itm do
				(
					local oldState = renderSceneDialog.isOpen()
					renderSceneDialog.close()
					rendViewIndex = indexArray[itm]
					if oldState do renderSceneDialog.open()
					ddl_viewsToRender.tooltip = ddl_viewsToRender.selected
					btn_SelectCamera.enabled = (isValidNode (getNodeByName ddl_viewsToRender.selected)) 
					setFocus ddl_viewsToRender
				)
				on chk_LockViewport changed state do 
				(
					local oldState = renderSceneDialog.isOpen()
					renderSceneDialog.close()
					rendUseActiveView = not state
					if oldState do renderSceneDialog.open()
					if rendViewIndex != undefined and not rendUseActiveView and rendViewIndex > 0 do ddl_viewsToRender.selection = indexArray[rendViewIndex]
					updateViewportsList()
				)
				
					
				fn updateIcons =
				(
					btn_voxelSizePresets.images = #(Krakatoa_PresetsArrowBitmap,Krakatoa_PresetsArrowBitmap, 32,1,1,2,2)
					btn_FilterRadiusPresets.images = #(Krakatoa_PresetsArrowBitmap,Krakatoa_PresetsArrowBitmap, 32,1,1,2,2)
					btn_lightingDensityPreset.images = #(Krakatoa_PresetsArrowBitmap,Krakatoa_PresetsArrowBitmap, 32,1,1,2,2)
					btn_finalDensityPreset.images = #(Krakatoa_PresetsArrowBitmap,Krakatoa_PresetsArrowBitmap, 32,1,1,2,2)
					btn_EmissionStrengthPreset.images = #(Krakatoa_PresetsArrowBitmap,Krakatoa_PresetsArrowBitmap, 32,1,1,2,2)
					btn_ReflectionStrengthPreset.images = #(Krakatoa_PresetsArrowBitmap,Krakatoa_PresetsArrowBitmap, 32,1,1,2,2)
				)				
				
				on chk_colorOverride changed state do
				(
					FranticParticles.SetProperty "ColorOverride:Enabled" (state as string)
					RefreshGlobalValuesGUI()
					RefreshMainGUI()	
					Krakatoa_VFB_methods.InteractiveUpdate()
				)
				on clr_customColor changed val do
				(
					FranticParticles.SetProperty "ColorOverride:Color" (val as string)
					RefreshGlobalValuesGUI()		
					Krakatoa_VFB_methods.InteractiveUpdate()
				)
				on prg_colorOverrideMapAmount clicked val do
				(
					FranticParticles.SetProperty "ColorOverride:BlendAmount" (val as string)
					RefreshGlobalValuesGUI()			
					prg_colorOverrideMapAmount.value = val
					Krakatoa_VFB_methods.InteractiveUpdate()					
				)
				
				on chk_EmissionOverride changed state do
				(
					FranticParticles.SetProperty "EmissionOverride:Enabled" (state as string)
					RefreshGlobalValuesGUI()
					RefreshMainGUI()	
					Krakatoa_VFB_methods.InteractiveUpdate()
				)	
				on clr_EmissionColor changed val do
				(
					FranticParticles.SetProperty "EmissionOverride:Color" (val as string)
					RefreshGlobalValuesGUI()					
					Krakatoa_VFB_methods.InteractiveUpdate()
				)		
				on prg_EmissionOverrideMapAmount clicked val do
				(
					FranticParticles.SetProperty "EmissionOverride:BlendAmount" (val as string)
					RefreshGlobalValuesGUI()			
					prg_EmissionOverrideMapAmount.value = val
					Krakatoa_VFB_methods.InteractiveUpdate()					
				)				

				on chk_AbsorptionOverride changed state do
				(
					FranticParticles.SetProperty "AbsorptionOverride:Enabled" (state as string)
					RefreshGlobalValuesGUI()
					RefreshMainGUI()	
					Krakatoa_VFB_methods.InteractiveUpdate()
				)		
				on clr_AbsorptionColor changed val do
				(
					FranticParticles.SetProperty "AbsorptionOverride:Color" (val as string)
					RefreshGlobalValuesGUI()					
					Krakatoa_VFB_methods.InteractiveUpdate()
				)	
				on prg_AbsorptionOverrideMapAmount clicked val do
				(
					FranticParticles.SetProperty "AbsorptionOverride:BlendAmount" (val as string)
					RefreshGlobalValuesGUI()			
					prg_AbsorptionOverrideMapAmount.value = val
					Krakatoa_VFB_methods.InteractiveUpdate()					
				)	
				
				on chk_DensityOverride changed state do
				(
					FranticParticles.SetProperty "DensityOverride:Enabled" (state as string)
					RefreshGlobalValuesGUI()
					RefreshMainGUI()	
					Krakatoa_VFB_methods.InteractiveUpdate()
				)		
				on clr_DensityColor changed val do
				(
					FranticParticles.SetProperty "DensityOverride:Value" ((val.value/255.0) as string)
					RefreshGlobalValuesGUI()					
					Krakatoa_VFB_methods.InteractiveUpdate()
				)					
				on prg_DensityOverrideMapAmount clicked val do
				(
					FranticParticles.SetProperty "DensityOverride:BlendAmount" (val as string)
					RefreshGlobalValuesGUI()			
					prg_DensityOverrideMapAmount.value = val
					Krakatoa_VFB_methods.InteractiveUpdate()					
				)	

				on spn_ReflectionStrength entered do
				(
					FranticParticles.SetProperty "EnvironmentReflectionStrength" (spn_ReflectionStrength.value as string)
					RefreshMainGUI()					
					Krakatoa_VFB_methods.InteractiveUpdate()					
				)

				
				on clr_BackgroundColor changed val do
				(
					FranticParticles.SetProperty "BackgroundColor" ((val) as string)
					RefreshGlobalValuesGUI()					
					Krakatoa_VFB_methods.InteractiveUpdate()
				)	
				
				on chk_overrideBackgroundColor changed state do
				(
					FranticParticles.SetProperty "UseEnvironmentColor" ((not state) as string)
					RefreshGlobalValuesGUI()		
					Krakatoa_VFB_methods.InteractiveUpdate()
				)
				
				on spn_voxelSize	entered do 
				(
					FranticParticles.SetProperty "VoxelSize" (spn_voxelSize.value as string)
					RefreshMainGUI()					
					Krakatoa_VFB_methods.InteractiveUpdate()
				)
				

				on spn_FilterRadius	entered  do 
				(
					FranticParticles.SetProperty "VoxelFilterRadius" (spn_FilterRadius.value as string)
					RefreshMainGUI()
					Krakatoa_VFB_methods.InteractiveUpdate()
				)
				
				on spn_LightingDensity entered do
				(
					if chk_RelativeLightingPassDensity.checked then
						FranticParticles.SetProperty "Lighting:Density:RelativeDensityPerParticle"  (spn_LightingDensity.value as string)
					else
						FranticParticles.SetProperty "Lighting:Density:DensityPerParticle" (spn_LightingDensity.value as string)
					RefreshMainGUI()
					Krakatoa_VFB_methods.InteractiveUpdate()					
				)
				on spn_LightingDensityExp entered do
				(
					if chk_RelativeLightingPassDensity.checked then
						FranticParticles.SetProperty "Lighting:Density:RelativeDensityExponent" (spn_LightingDensityExp.value as string)
					else
						FranticParticles.SetProperty "Lighting:Density:DensityExponent" (spn_LightingDensityExp.value as string)
					RefreshMainGUI()
					Krakatoa_VFB_methods.InteractiveUpdate()					
				)		

				on spn_FinalDensity entered do
				(
					FranticParticles.SetProperty "Density:DensityPerParticle" (spn_FinalDensity.value as string)
					RefreshMainGUI()
					Krakatoa_VFB_methods.InteractiveUpdate()					
				)
				on spn_FinalDensityExp entered do
				(
					FranticParticles.SetProperty "Density:DensityExponent" (spn_FinalDensityExp.value as string)
					RefreshMainGUI()
					Krakatoa_VFB_methods.InteractiveUpdate()					
				)		
				
				on chk_EmissionStrength changed state do
				(
					FranticParticles.SetProperty "Emission:UseStrength" (state as string)
					RefreshMainGUI()
					Krakatoa_VFB_methods.InteractiveUpdate()						
				)
				
				on spn_EmissionStrength entered do
				(
					if chk_RelativeEmissionStrength.checked then
						FranticParticles.SetProperty "Emission:RelativeStrength" (spn_EmissionStrength.value as string)
					else
						FranticParticles.SetProperty "Emission:Strength" (spn_EmissionStrength.value as string)
					RefreshMainGUI()
					Krakatoa_VFB_methods.InteractiveUpdate()					
				)
				on spn_EmissionStrengthExp entered do
				(
					if chk_RelativeEmissionStrength.checked then
						FranticParticles.SetProperty "Emission:RelativeStrengthExponent" (spn_EmissionStrengthExp.value as string)
					else
						FranticParticles.SetProperty "Emission:StrengthExponent" (spn_EmissionStrengthExp.value as string)
					RefreshMainGUI()
					Krakatoa_VFB_methods.InteractiveUpdate()					
				)						
				
				
				fn refresh_GUI =
				(
					FranticParticles.LogDebug "  !VFB: Left Panel refresh_GUI() Called!"
					--chk_ShowBottomPanel.state = Krakatoa_VFB_methods.VFB_Interface.GetRolloutWindowVisible #Bottom
					
					updateViewportsList()
					
					local enableLightingControls = (FranticParticles.GetProperty "Density:DensityMethod") != "Additive Density"
					
					btn_renderMode.caption = if (FranticParticles.GetProperty "RenderingMethod") == "Particle Rendering" then "[Particles]" else "[Voxels]"
					btn_FilterRadiusPresets.enabled = btn_voxelSizePresets.enabled = spn_FilterRadius.enabled = lbl_voxelSize.enabled = spn_voxelSize.enabled = btn_renderMode.caption == "[Voxels]"
					
					chk_useEmission.state = FranticParticles.getBoolProperty "UseEmissionColor"
					chk_useAbsorption.state= FranticParticles.getBoolProperty "UseFilterColor"

					clr_customColor.color = execute (FranticParticles.GetProperty "ColorOverride:Color")
					clr_EmissionColor.color = execute (FranticParticles.GetProperty "EmissionOverride:Color")
					clr_AbsorptionColor.color = execute (FranticParticles.GetProperty "AbsorptionOverride:Color")
					clr_DensityColor.color = white * execute (FranticParticles.GetProperty "DensityOverride:Value")
					
					chk_colorOverride.state = execute (FranticParticles.GetProperty "ColorOverride:Enabled")
					chk_EmissionOverride.state = execute (FranticParticles.GetProperty "EmissionOverride:Enabled")
					chk_AbsorptionOverride.state = execute (FranticParticles.GetProperty "AbsorptionOverride:Enabled")
					chk_DensityOverride.state = execute (FranticParticles.GetProperty "DensityOverride:Enabled")
			
					prg_colorOverrideMapAmount.value= execute (FranticParticles.GetProperty "ColorOverride:BlendAmount")
					prg_EmissionOverrideMapAmount.value = execute (FranticParticles.GetProperty "EmissionOverride:BlendAmount")
					prg_AbsorptionOverrideMapAmount.value = execute (FranticParticles.GetProperty "AbsorptionOverride:BlendAmount")
					prg_DensityOverrideMapAmount.value = execute (FranticParticles.GetProperty "DensityOverride:BlendAmount")
					
					chk_additiveMode.state = (FranticParticles.GetBoolProperty "AdditiveMode")
					chk_IgnoreSceneLights.state = (FranticParticles.GetBoolProperty "IgnoreSceneLights")
					chk_useEnvReflections.state = (FranticParticles.GetBoolProperty "UseEnvironmentReflections")		
					chk_allocateReflectionStrength.state = (FranticParticles.GetBoolProperty "Channel:Allocate:ReflectionStrength")		
					chk_EmissionStrength.checked = FranticParticles.GetBoolProperty "Emission:UseStrength"
					
					
					--spn_ReflectionStrength.enabled = btn_ReflectionStrengthPreset.enabled = chk_useEnvReflections.state
					
					
					chk_OverrideBackgroundColor.state = not (FranticParticles.GetBoolProperty "UseEnvironmentColor")	
					clr_BackgroundColor.color = execute ( FranticParticles.GetProperty "BackgroundColor")

					spn_voxelSize.value = execute (FranticParticles.GetProperty "VoxelSize")
					spn_FilterRadius.value = execute ( FranticParticles.GetProperty "VoxelFilterRadius")
					
					local theNode = getNodeByName (FranticParticles.GetProperty "GlobalDataHolder")
					btn_GlobalChannelOverrides.caption = if isValidNode theNode then theNode.name else "[Global Overrides OFF]"
					btn_GlobalChannelOverrides.tooltip = if isValidNode theNode then 
					(
						local txt = "==Base Object=="
						for m in theNode.modifiers do 
						(
							local theNoteArray = try(filterString m.note "\n")catch(#(""))
							local theNote = ""
							for i in theNoteArray do theNote += i + " "
							
							if matchPattern theNote pattern:"*Enter Notes Here*" then 
								theNote = ""
							else
								theNote = " [ " + theNote  + "]"
							local theName = m.name 
							if matchPattern theName pattern:"KCM_*" do theName = substring theName 5 -1
							txt = (if not m.enabled then "--" else "") + theName + theNote +"\n" + txt
						)	
						txt
					)
					else "Channel Overrides DISABLED"	
					
					
					
					case (FranticParticles.GetProperty "PhaseFunction") of
					(
						"Isotropic": (
							btn_scatterMode.caption = "[Isotropic]"
							btn_floatShaderParameters.enabled = false
						)
						"Phong Surface": (
							btn_scatterMode.caption ="[Phong Surf.]"
							btn_floatShaderParameters.enabled = true
						)
						"Henyey-Greenstein": (
							btn_scatterMode.caption ="[Hen-Green]"
							btn_floatShaderParameters.enabled = true
						)
						"Schlick": (
							btn_scatterMode.caption ="[Schlick]"
							btn_floatShaderParameters.enabled = true
						)
						"Kajiya-Kay Hair": (
							btn_scatterMode.caption ="[Kajiya-Kay]"
							btn_floatShaderParameters.enabled = true
						)		
						"Marschner Hair": (
							btn_scatterMode.caption ="[Marschner]"
							btn_floatShaderParameters.enabled = true
						)							
						default: (
							btn_scatterMode.caption ="???"
							btn_floatShaderParameters.enabled = false
						)
					)
					
					local lightingIsEnabled = FranticParticles.GetBoolProperty "UseLighting"
					
					spn_ReflectionStrength.value = (FranticParticles.GetFloatProperty "EnvironmentReflectionStrength")

					spn_FinalDensity.value = (FranticParticles.GetFloatProperty "Density:DensityPerParticle")
					spn_FinalDensityExp.value = (FranticParticles.GetFloatProperty "Density:DensityExponent")

					chk_RelativeLightingPassDensity.state = FranticParticles.GetBoolProperty "Density:RelativeLightingDensity"
					
					if chk_RelativeLightingPassDensity.checked then
					(
						spn_LightingDensity.value = FranticParticles.GetFloatProperty "Lighting:Density:RelativeDensityPerParticle"
						spn_LightingDensityExp.value = FranticParticles.GetIntProperty "Lighting:Density:RelativeDensityExponent"	
							
						local newLPD = spn_FinalDensity.value*spn_LightingDensity.value 
						local newLPDE =  spn_FinalDensityExp.value + spn_LightingDensityExp.value
						FranticParticles.SetProperty "Lighting:Density:DensityPerParticle" (newLPD as string)
						FranticParticles.SetProperty "Lighting:Density:DensityExponent" (newLPDE as string)
					)
					else
					(
						spn_LightingDensity.value = (FranticParticles.GetFloatProperty "Lighting:Density:DensityPerParticle")
						spn_LightingDensityExp.value = (FranticParticles.GetFloatProperty "Lighting:Density:DensityExponent") 
					)					
					
					chk_RelativeEmissionStrength.state = FranticParticles.GetBoolProperty "Emission:UseRelativeStrength"

					if chk_RelativeEmissionStrength.checked then
					(
						spn_EmissionStrength.value = FranticParticles.GetFloatProperty "Emission:RelativeStrength"
						spn_EmissionStrengthExp.value = FranticParticles.GetIntProperty "Emission:RelativeStrengthExponent"	
							
						local newES = spn_FinalDensity.value*spn_EmissionStrength.value 
						local newESE =  spn_FinalDensityExp.value + spn_EmissionStrengthExp.value
						FranticParticles.SetProperty "Emission:Strength" (newES as string)
						FranticParticles.SetProperty "Emission:StrengthExponent" (newESE as string)
					)
					else
					(
						spn_EmissionStrength.value = (FranticParticles.GetFloatProperty "Emission:Strength")
						spn_EmissionStrengthExp.value = (FranticParticles.GetFloatProperty "Emission:StrengthExponent")
					)					
					
					chk_LightingPassDensity.state = not (FranticParticles.GetBoolProperty "Density:LinkLightingAndRenderingDensity")
					chk_LightingPassDensity.enabled = not chk_IgnoreSceneLights.checked
					btn_lightingDensityPreset.enabled = spn_LightingDensity.enabled = spn_LightingDensityExp.enabled = chk_LightingPassDensity.state and not chk_IgnoreSceneLights.state
					
					spn_EmissionStrength.enabled = spn_EmissionStrengthExp.enabled = btn_EmissionStrengthPreset.enabled = FranticParticles.GetBoolProperty "UseEmissionColor"
					
					local state = FranticParticles.GetProperty "DrawPointFilter"
					btn_DrawPointFilter.caption = case state of
					(
						"Nearest Neighbor": "[Draw:NN]"
						"Bicubic": "[Draw:BC]"
						default: (
							if matchPattern state pattern:"Bilinear*" then
								"[Draw:BL]"
							else 
								"[Draw:??]"
						)						
					)
					if matchPattern state pattern:"Bilinear*" then
					(
						local theFilter = execute (substring state 9 -1)
						if superclassof theFilter != Number do theFilter = 1
						spn_drawBilinearFilter.value = theFilter	
						spn_drawBilinearFilter.enabled = btn_drawBilinearFilterPreset.enabled = true
					)
					else
						spn_drawBilinearFilter.enabled = btn_drawBilinearFilterPreset.enabled = false
					
					btn_DrawPointFilter.tooltip = case state of
					(
						"Nearest Neighbor": "Draw Point Filter : Nearest Neighbor"
						"Bilinear": "Draw Point Filter : Bilinear"
						"Bicubic": "Draw Point Filter : Bicubic"
						default: (
							if matchPattern state pattern:"Bilinear*" then
								"[Draw Point Filter : Bilinear Filter "+(substring state 9 -1)+"]"
							else 
								"[Draw Point Filter : Unknown]"
						)						
					)					
					local state = FranticParticles.GetProperty "AttenuationLookupFilter"
					btn_SelfShadowFilter.caption = case state of
					(
						"Nearest Neighbor": "[Shdw:NN]"
						"Bicubic": "[Shdw:BC]"
						default: (
							if matchPattern state pattern:"Bilinear*" then
								"[Shdw:BL]"
							else 
								"[Shdw:??]"
						)
					)
					if matchPattern state pattern:"Bilinear*" then
					(
						local theFilter = execute (substring state 9 -1)
						if superclassof theFilter != Number do theFilter = 1
						spn_shadowBilinearFilter.value = theFilter
						spn_shadowBilinearFilter.enabled = btn_shadowBilinearFilterPreset.enabled = true
					)
					else
						spn_shadowBilinearFilter.enabled = btn_shadowBilinearFilterPreset.enabled = false
					
					btn_SelfShadowFilter.tooltip = case state of
					(
						"Nearest Neighbor": "Self-Shadow Filter : Nearest Neighbor"
						"Bilinear": "Self-Shadow Filter : Bilinear"
						"Bicubic": "Self-Shadow Filter : Bicubic"
						default: (
							if matchPattern state pattern:"Bilinear*" then
								"Self-Shadow Filter : Bilinear Filter "+(substring state 9 -1)
							else 
								"Self-Shadow Filter : Unknown"
						)
					)				


					map_colorOverride.caption = try(if renderers.current.ColorOverrideTexmap != undefined then "M" else "n")catch("n")
					map_EmissionOverride.caption = try(if renderers.current.emissionOverrideTexmap != undefined then "M" else "n")catch("n")
					map_AbsorptionOverride.caption = try(if renderers.current.absorptionOverrideTexmap != undefined then "M" else "n")catch("n")
					map_DensityOverride.caption = try(if renderers.current.densityOverrideTexmap != undefined then "M" else "n")catch("n")
					
					map_colorOverride.tooltip = try(renderers.current.ColorOverrideTexmap.name + " (" + (classof renderers.current.ColorOverrideTexmap ) as string + ")")catch("No Map Assigned.")
					map_EmissionOverride.tooltip = try(renderers.current.emissionOverrideTexmap.name + " (" + (classof renderers.current.emissionOverrideTexmap ) as string + ")")catch("No Map Assigned.")
					map_AbsorptionOverride.tooltip = try(renderers.current.absorptionOverrideTexmap.name + " (" + (classof renderers.current.absorptionOverrideTexmap ) as string + ")")catch("No Map Assigned.")
					map_DensityOverride.tooltip = try(renderers.current.densityOverrideTexmap.name + " (" + (classof renderers.current.densityOverrideTexmap ) as string + ")")catch("No Map Assigned.")				
					
				)--end refresh_gui
				
				on btn_floatShaderParameters pressed do
				(
					setIniSetting (GetDir #plugcfg + "/Krakatoa/KrakatoaPreferences.ini") "RolloutVisible" Krakatoa_GUI_ShaderDynamic.title "true"
					FranticParticleRenderMXS.floatOrDockRollout Krakatoa_GUI_ShaderDynamic forceMode:#float
					Krakatoa_CustomizeRollouts_Dialog.Refresh_GUI()
				)
				
				on map_colorOverride picked val do 
				(
					try(renderers.current.ColorOverrideTexmap = val)catch()
					refresh_GUI()
					RefreshGlobalValuesGUI()
				)
				on map_EmissionOverride picked val do 
				(
					try(renderers.current.emissionOverrideTexmap = val)catch()
					refresh_GUI()
					RefreshGlobalValuesGUI()
				)		
				on map_AbsorptionOverride picked val do 
				(
					try(renderers.current.absorptionOverrideTexmap = val)catch()
					refresh_GUI()
					RefreshGlobalValuesGUI()
				)		
				on map_DensityOverride picked val do 
				(
					try(renderers.current.densityOverrideTexmap = val)catch()
					refresh_GUI()
					RefreshGlobalValuesGUI()
				)			
				
				on map_colorOverride rightClick do
				(
					Krakatoa_GUI_RenderGlobalValues_MapOptions_Selection = #color
					popupMenu Krakatoa_GUI_RenderGlobalValues_MapOptions	pos:mouse.screenPos					
				)
				on map_EmissionOverride rightClick do
				(
					Krakatoa_GUI_RenderGlobalValues_MapOptions_Selection = #emission
					popupMenu Krakatoa_GUI_RenderGlobalValues_MapOptions	pos:mouse.screenPos						
				)
				on map_AbsorptionOverride rightClick do
				(
					Krakatoa_GUI_RenderGlobalValues_MapOptions_Selection = #absorption
					popupMenu Krakatoa_GUI_RenderGlobalValues_MapOptions	pos:mouse.screenPos
				)
				on map_DensityOverride rightClick do
				(
					Krakatoa_GUI_RenderGlobalValues_MapOptions_Selection = #density
					popupMenu Krakatoa_GUI_RenderGlobalValues_MapOptions	pos:mouse.screenPos
				)				
				
				on Krakatoa_VFB_Left_Rollout open do 
				(
					updateIcons()
					refresh_GUI()			
				)	
				
				on btn_GlobalChannelOverrides pressed do 
				(
					local theHolders = join #("--Disable Global Channel Overrides--") (for o in objects where classof o.baseobject == KrakatoaMXGlobalDataHolder collect o.name)
					global Krakatoa_GlobalChannelOverridesRCMenu
					local txt = "rcmenu Krakatoa_GlobalChannelOverridesRCMenu (\n"
					for i = 1 to theHolders.count do
					(
						txt += "menuItem mnu_globalHolder"+i as string +" \""+theHolders[i]+"\" \n"
						if i == 1 then
						(
							txt += "on mnu_globalHolder"+i as string +" picked do (\n"
							txt += "FranticParticles.SetProperty \"GlobalDataHolder\" \"\""
							txt += "try(Krakatoa_GUI_RenderGlobalValues.refresh_GUI())catch()\n"
							txt += "Krakatoa_VFB_Left_Rollout.refresh_GUI()\n"
							txt += ")\n"
						)	
						else
						(
							txt += "on mnu_globalHolder"+i as string +" picked do \n("
							txt += "FranticParticles.SetProperty \"GlobalDataHolder\" \""+theHolders[i]+"\"\n"
							txt += "try(Krakatoa_GUI_RenderGlobalValues.refresh_GUI())catch()\n"
							txt += "Krakatoa_VFB_Left_Rollout.refresh_GUI()\n"
							txt += "select (getNodeByName \""+theHolders[i]+ "\" )\n"
							txt += ")\n"
						)	
					)	
					txt += "separator sep_10\n"
					txt += "menuItem mnu_addSet \"Create New Channel Override Set...\" \n"					
					txt += "on mnu_addSet picked do (\n"
					txt += "try(Krakatoa_GUI_RenderGlobalValues.createNewOverrideSet()\n"
					txt += "Krakatoa_GUI_RenderGlobalValues.refresh_GUI())catch()\n"
					txt += ")\n"
					
					txt+=")\n"
					execute txt
					popupMenu Krakatoa_GlobalChannelOverridesRCMenu pos:mouse.ScreenPos
				)
				
				on btn_GlobalChannelOverrides rightclick do 
				(
					local theNode = getNodeByName (FranticParticles.GetProperty "GlobalDataHolder")
					if isValidNode theNode then
					(
						local theMods = (for m in theNode.modifiers collect m.name)
						append theMods "==Base Object=="
						global Krakatoa_GlobalChannelOverridesRCMenu
						local txt = "rcmenu Krakatoa_GlobalChannelOverridesRCMenu (\n"
						for i = 1 to theMods.count do
						(
							txt += "menuItem mnu_globalHolder"+i as string +" \""+ theMods[i]+"\" \n"
							txt += "on mnu_globalHolder"+i as string +" picked do (\n"
							txt += "max modify mode\n"
							txt += "select (getNodeByName (FranticParticles.GetProperty \"GlobalDataHolder\"))\n"
							if i == theMods.count then
								txt += "modPanel.setCurrentObject ((getNodeByName (FranticParticles.GetProperty \"GlobalDataHolder\")).baseobject)\n"
							else	
								txt += "modPanel.setCurrentObject ((getNodeByName (FranticParticles.GetProperty \"GlobalDataHolder\")).modifiers[" + i as string +"])\n"
							txt += "try(Krakatoa_GUI_RenderGlobalValues.refresh_GUI())catch()\n"
							txt += ")\n"
						)	
						txt += "separator sep_10\n"
						txt += "menuItem mnu_addModifier \"Add New KCM...\" \n"
						txt += "on mnu_addModifier picked do (\n"
						txt += "with undo \"Add KCM\" on addModifier (getNodeByName (FranticParticles.GetProperty \"GlobalDataHolder\")) (KrakatoaChannelsModifier name:\"KCM_Color\")  \n"
						txt += "try(Krakatoa_GUI_RenderGlobalValues.refresh_GUI())catch()\n"
						txt += ")\n"
						txt+=")\n"
						execute txt
						popupMenu Krakatoa_GlobalChannelOverridesRCMenu pos:mouse.ScreenPos
					)
				)				
				
				
				
				on btn_renderMode pressed do popupMenu Krakatoa_VFB_Menus.RenderModeRCMenu pos:mouse.ScreenPos
				on btn_renderMode rightclick do popupMenu Krakatoa_VFB_Menus.RenderModeRCMenu pos:mouse.ScreenPos
					
					
				on btn_scatterMode pressed do popupMenu Krakatoa_VFB_Menus.ScatterModeRCMenu pos:mouse.ScreenPos
				on btn_scatterMode rightclick do popupMenu Krakatoa_VFB_Menus.ScatterModeRCMenu pos:mouse.ScreenPos				
					
				on chk_LightingPassDensity changed state do 
				(
					FranticParticles.SetProperty "Density:LinkLightingAndRenderingDensity" ((not state) as string)
					RefreshMainGUI()					
					Krakatoa_VFB_methods.InteractiveUpdate()
				)
				

				on btn_DrawPointFilter pressed do popupMenu Krakatoa_VFB_Menus.DrawPointFilterRCMenu pos:mouse.ScreenPos
				on btn_DrawPointFilter rightclick do popupMenu Krakatoa_VFB_Menus.DrawPointFilterRCMenu pos:mouse.ScreenPos
					
				on btn_SelfShadowFilter pressed do popupMenu Krakatoa_VFB_Menus.SelfShadowFilterRCMenu pos:mouse.ScreenPos
				on btn_SelfShadowFilter rightclick do popupMenu Krakatoa_VFB_Menus.SelfShadowFilterRCMenu pos:mouse.ScreenPos		
				
				--on chk_LightingPassDensity rightclick do popupMenu Krakatoa_VFB_Menus.LightingPassDensityRCMenu pos:mouse.ScreenPos
				
				on chk_useEmission changed state do
				(
					initializeKrakatoaGUI()
					FranticParticles.setProperty "UseEmissionColor" (state as string)
					RefreshMainGUI()
					Krakatoa_VFB_methods.InteractiveUpdate()
				)			

				on chk_useAbsorption changed state do
				(
					initializeKrakatoaGUI()
					FranticParticles.setProperty "UseFilterColor" (state as string)
					RefreshMainGUI()
					Krakatoa_VFB_methods.InteractiveUpdate()
				)		

				on chk_useEnvReflections changed state do
				(
					initializeKrakatoaGUI()
					FranticParticles.setProperty "UseEnvironmentReflections" (state as string)
					RefreshMainGUI()
					Krakatoa_VFB_methods.InteractiveUpdate()
				)	

				on chk_allocateReflectionStrength changed state do
				(
					initializeKrakatoaGUI()
					FranticParticles.setProperty "Channel:Allocate:ReflectionStrength" (state as string)
					RefreshMainGUI()
					Krakatoa_VFB_methods.InteractiveUpdate()
				)					
				
				on chk_additiveMode changed state do
				(
					initializeKrakatoaGUI()
					FranticParticles.SetProperty "Density:DensityMethod" (if state then "Additive Density" else "Volumetric Density")
					FranticParticles.setProperty "AdditiveMode" (state as string)
					RefreshMainGUI()
					Krakatoa_VFB_methods.InteractiveUpdate()
				)					
				
				on chk_ignoreSceneLights changed state do
				(
					initializeKrakatoaGUI()
					FranticParticles.setProperty "IgnoreSceneLights" (state as string)
					RefreshMainGUI()
					refresh_GUI()
					Krakatoa_VFB_methods.InteractiveUpdate()
				)	
				
				on btn_voxelSizePresets pressed do
				(
					initializeKrakatoaGUI()
					Krakatoa_GUI_Main.createPresetsRCMenu type:#voxelsize
					popUpMenu Krakatoa_RCMenu_Struct.Presets_RCMenu position:mouse.screenPos
					--refresh_GUI()
					--Krakatoa_VFB_methods.InteractiveUpdate()
				)			
				
				on btn_FilterRadiusPresets pressed do
				(
					initializeKrakatoaGUI()
					Krakatoa_GUI_Main.createPresetsRCMenu type:#VoxelFilterRadius
					popUpMenu Krakatoa_RCMenu_Struct.Presets_RCMenu position:mouse.screenPos
					--refresh_GUI()
					--Krakatoa_VFB_methods.InteractiveUpdate()
				)					
				
				on btn_lightingDensityPreset pressed do
				(
					initializeKrakatoaGUI()
					if chk_RelativeLightingPassDensity.checked then
						Krakatoa_GUI_Main.createPresetsRCMenu type:#lightingdensityrelative
					else
						Krakatoa_GUI_Main.createPresetsRCMenu type:#lightingdensity
					popUpMenu Krakatoa_RCMenu_Struct.Presets_RCMenu position:mouse.screenPos
					--Krakatoa_VFB_methods.InteractiveUpdate()
				)	
				on btn_lightingDensityPreset rightclick do
				(
					initializeKrakatoaGUI()
					if chk_RelativeLightingPassDensity.checked then
						Krakatoa_GUI_Main.createPresetsRCMenu type:#lightingdensityrelative
					else
						Krakatoa_GUI_Main.createPresetsRCMenu type:#lightingdensity
					popUpMenu Krakatoa_RCMenu_Struct.Presets_RCMenu position:mouse.screenPos
					--Krakatoa_VFB_methods.InteractiveUpdate()
				)	
				
				on btn_finalDensityPreset pressed do
				(
					initializeKrakatoaGUI()
					Krakatoa_GUI_Main.createPresetsRCMenu type:#finaldensity
					popUpMenu Krakatoa_RCMenu_Struct.Presets_RCMenu position:mouse.screenPos
					--Krakatoa_VFB_methods.InteractiveUpdate()
				)	
				on btn_finalDensityPreset rightclick do
				(
					initializeKrakatoaGUI()
					Krakatoa_GUI_Main.createPresetsRCMenu type:#finaldensity
					popUpMenu Krakatoa_RCMenu_Struct.Presets_RCMenu position:mouse.screenPos
					--Krakatoa_VFB_methods.InteractiveUpdate()
				)		
				
				on btn_EmissionStrengthPreset pressed do
				(
					initializeKrakatoaGUI()
					if chk_RelativeEmissionStrength.checked then
						Krakatoa_GUI_Main.createPresetsRCMenu type:#emissionstrengthrelative
					else
						Krakatoa_GUI_Main.createPresetsRCMenu type:#emissionstrength
					popUpMenu Krakatoa_RCMenu_Struct.Presets_RCMenu position:mouse.screenPos
					--Krakatoa_VFB_methods.InteractiveUpdate()
				)	
				on btn_EmissionStrengthPreset rightclick do
				(
					initializeKrakatoaGUI()
					if chk_RelativeEmissionStrength.checked then
						Krakatoa_GUI_Main.createPresetsRCMenu type:#emissionstrengthrelative
					else
						Krakatoa_GUI_Main.createPresetsRCMenu type:#emissionstrength
					popUpMenu Krakatoa_RCMenu_Struct.Presets_RCMenu position:mouse.screenPos
					--Krakatoa_VFB_methods.InteractiveUpdate()
				)		

				on btn_reflectionStrengthPreset pressed do
				(
					initializeKrakatoaGUI()
					Krakatoa_GUI_Main.createPresetsRCMenu type:#reflectionstrength
					popUpMenu Krakatoa_RCMenu_Struct.Presets_RCMenu position:mouse.screenPos
				)	
				on btn_reflectionStrengthPreset rightclick do
				(
					initializeKrakatoaGUI()
					Krakatoa_GUI_Main.createPresetsRCMenu type:#reflectionstrength
					popUpMenu Krakatoa_RCMenu_Struct.Presets_RCMenu position:mouse.screenPos
				)		

				on btn_shadowBilinearFilterPreset pressed do 
				(
					initializeKrakatoaGUI()
					Krakatoa_GUI_Main.createPresetsRCMenu type:#shadowBilinearFilter
					popUpMenu Krakatoa_RCMenu_Struct.Presets_RCMenu position:mouse.screenPos
				)
				on btn_shadowBilinearFilterPreset rightclick do 
				(
					initializeKrakatoaGUI()
					Krakatoa_GUI_Main.createPresetsRCMenu type:#shadowBilinearFilter
					popUpMenu Krakatoa_RCMenu_Struct.Presets_RCMenu position:mouse.screenPos
				)				
				
				
				on spn_drawBilinearFilter entered do
				(
					theFilter = "Bilinear"
					if spn_drawBilinearFilter.value > 1 do theFilter += spn_drawBilinearFilter.value as string
					FranticParticles.SetProperty "DrawPointFilter" theFilter 
					RefreshMainGUI()
					Krakatoa_VFB_methods.InteractiveUpdate()					
				)
				on spn_shadowBilinearFilter entered do
				(
					theFilter = "Bilinear"
					if spn_shadowBilinearFilter.value > 1 do theFilter += spn_shadowBilinearFilter.value as string
					FranticParticles.SetProperty "AttenuationLookupFilter" theFilter 
					RefreshMainGUI()
					Krakatoa_VFB_methods.InteractiveUpdate()					
				)
				
				on btn_drawBilinearFilterPreset pressed do
				(
					initializeKrakatoaGUI()
					Krakatoa_GUI_Main.createPresetsRCMenu type:#drawBilinearFilter
					popUpMenu Krakatoa_RCMenu_Struct.Presets_RCMenu position:mouse.screenPos
				)
				on btn_drawBilinearFilterPreset rightclick do
				(
					initializeKrakatoaGUI()
					Krakatoa_GUI_Main.createPresetsRCMenu type:#drawBilinearFilter
					popUpMenu Krakatoa_RCMenu_Struct.Presets_RCMenu position:mouse.screenPos
				)				

				
				on chk_PostDivideByAlpha changed state do 
				(
					FranticParticles.SetProperty "PostDivideByAlpha" (state as string)
					RefreshMainGUI()
					Krakatoa_VFB_methods.InteractiveUpdate()
				)	
				
				on chk_ShadingMode changed state do
				(
					FranticParticles.SetProperty "Lighting:Specular:Enabled" (state as string)
					RefreshMainGUI()			
					Krakatoa_VFB_Right_Rollout.Refresh_GUI()	
					Krakatoa_VFB_methods.InteractiveUpdate()					
				)
				
				on chk_RelativeLightingPassDensity changed state do
				(
					FranticParticles.SetProperty "Density:RelativeLightingDensity" (state as string)
					RefreshMainGUI()
				)
				on chk_RelativeEmissionStrength changed state do
				(
					FranticParticles.SetProperty "Emission:UseRelativeStrength" (state as string)
					RefreshMainGUI()	
				)
			)
			
			rollout Krakatoa_VFB_Right_Rollout ""
			(
				checkbutton chk_EnableMotionBlur "MBlur" pos:[0,0] width:40 height:18 border:useBorder tooltip:"Enable Motion Blur" highlightcolor:KrakatoaSkinColorsStruct.VFB
				checkbutton chk_JitteredMotionBlur "Jittered" pos:[165,0] width:63 height:18 border:useBorder tooltip:"Enable Jittered Motion Blur" highlightcolor:KrakatoaSkinColorsStruct.VFB
				checkbutton chk_DisableCameraMotionBlur "No Cam.MB" pos:[165,18] width:63 height:18 border:useBorder tooltip:"Disable Motion Blur From Camera Motion" highlightcolor:KrakatoaSkinColorsStruct.VFB
				
				spinner spn_MotionBlurSegments "" range:[1,1000,1] pos:[38,1] fieldwidth:30 type:#integer tooltip:"Motion Blur Particle Segments"
				button btn_MotionBlurSegments_Preset ">>" width:18 height:16 pos:[80,1] 
				
				spinner spn_MotionBlurShutter "" range:[0,100000.0,180] pos:[95,1] fieldwidth:40 type:#float tooltip:"Motion Blur Shutter Angle in degrees"
				button btn_MotionBlurShutter_Preset ">>" width:18 height:16 pos:[147,1] 

				spinner spn_MatteMotionBlurSegments "" range:[1,1000,1] pos:[38,18] fieldwidth:30 type:#integer tooltip:"Motion Blur Segments"
				button btn_matteMotionBlurSegmentsPreset ">>" width:18 height:16 pos:[80,19] 
				
				spinner spn_MatteMotionBlurBias "" range:[-1,1,0] pos:[95,19] fieldwidth:40 type:#float scale:0.01 tooltip:"Motion Blur Bias"
				button btn_MatteMotionBlurBias_Preset ">>" width:18 height:16 pos:[147,19] 
				
				checkbutton chk_DeformationMotionBlur "G" pos:[0,18] width:13 height:18 border:useBorder  tooltip:"Toggle Geometry Sub-Sampling"  highlightcolor:KrakatoaSkinColorsStruct.VFB
				checkbutton chk_useMatteSegments "Use" pos:[13,18] width:27 height:18 border:useBorder tooltip:"Use Matte Segments\n\nDecouples the Matte Geometry Sampling from the Particle Sampling.\n\nUseful to speed up rendering when the Matte Geometry is not deforming and moving mostly in linear fashion." highlightcolor:KrakatoaSkinColorsStruct.VFB

				checkbutton chk_EnableAdaptiveMotionBlur "Adapt." pos:[0,36] width:40 height:36 border:useBorder tooltip:"Enable Adaptive Motion Blur" highlightcolor:KrakatoaSkinColorsStruct.VFB
				
				spinner spn_AdaptiveMotionBlurSegmentLowerBound "" range:[1,1000,1] pos:[38,36] fieldwidth:30 type:#integer tooltip:"Adaptive Motion Blur Minimum Particle Segments"
				button btn_AdaptiveMotionBlurSegmentLowerBound_Preset ">>" width:18 height:16 pos:[80,36] 

				spinner spn_AdaptiveMotionBlurSegmentUpperBound "" range:[1,1000,1] pos:[95,36] fieldwidth:40 type:#integer tooltip:"Adaptive Motion Blur Maximum Particle Segments"
				button btn_AdaptiveMotionBlurSegmentUpperBound_Preset ">>" width:18 height:16 pos:[147,36] 


				spinner spn_AdaptiveMotionBlurSmoothness "" range:[0.01,10,1] pos:[38,54] scale:0.01 fieldwidth:30 type:#float tooltip:"Adaptive Motion Blur Smoothness"
				button btn_AdaptiveMotionBlurSmoothness_Preset ">>" width:18 height:16 pos:[80,54] tooltip:"Adaptive Motion Blur Smoothness Preset"

				spinner spn_AdaptiveMotionBlurExponent "" range:[0.01,10,1] pos:[95,54] fieldwidth:40 type:#float tooltip:"Adaptive Motion Blur Smoothness Bias"
				button btn_AdaptiveMotionBlurExponent_Preset ">>" width:18 height:16 pos:[147,54] tooltip:"Adaptive Motion Blur Smoothness Bias Preset"

				checkbutton chk_EnableDepthOfField "DOF" pos:[165,36] width:33 height:18 border:useBorder tooltip:"Toggle Depth Of Field" highlightcolor:KrakatoaSkinColorsStruct.VFB
				checkbutton ckk_AllocateBokehBlendInfluence "Alloc." pos:[198,36] width:30 height:18 border:useBorder tooltip:"Allocate 'BokehBlendInfluence' Channel" highlightcolor:KrakatoaSkinColorsStruct.VFB
				
				spinner spn_DepthOfFieldSampleRate "" range:[0.01,1000,1] pos:[163,54] fieldwidth:35 type:#float tooltip:"Depth Of Field Sample Rate\n\nHigher values increase quality at cost of render time by producing more samples within the circle of confusion."
				button btn_DepthOfFieldSampleRate_Preset ">>" width:18 height:16 pos:[210,54] 
				
				
				checkbutton chk_PFg "PG" pos:[0,72] width:20 height:18 border:useBorder tooltip:"Include Particle Flow Geometry" highlightcolor:KrakatoaSkinColorsStruct.VFB
				checkbutton chk_PFp "PP" pos:[20,72] width:20 height:18 border:useBorder tooltip:"Include Particle Flow Phantom" highlightcolor:KrakatoaSkinColorsStruct.VFB
				checkbutton chk_PFb "PB" pos:[40,72] width:20 height:18 border:useBorder tooltip:"Include Particle Flow Bounding Box" highlightcolor:KrakatoaSkinColorsStruct.VFB
				checkbutton chk_LP "LP" pos:[60,72] width:20 height:18 border:useBorder tooltip:"Include 3ds Max Legacy Particles" highlightcolor:KrakatoaSkinColorsStruct.VFB
				
				checkbutton chk_TP "TP" pos:[80,72] width:20 height:18 border:useBorder tooltip:"Include Thinking Particles" highlightcolor:KrakatoaSkinColorsStruct.VFB
				checkbutton chk_Fume "FF" pos:[100,72] width:20 height:18 border:useBorder tooltip:"Include FumeFX Simulations" highlightcolor:KrakatoaSkinColorsStruct.VFB
				checkbutton chk_Phoenix "PH" pos:[120,72] width:20 height:18 border:useBorder tooltip:"Include Phoenix FD Simulations" highlightcolor:KrakatoaSkinColorsStruct.VFB
				checkbutton chk_GV "GV" pos:[140,72] width:20 height:18 border:useBorder tooltip:"Include Geometry Vertices" highlightcolor:KrakatoaSkinColorsStruct.VFB
				
				button btn_RenderParticlesFrom_Preset ">>" pos:[320,72] width:30 height:18 border:useBorder tooltip:"'Render Particles From' Presets..." 

				checkbutton chk_PRT "Ldr" pos:[160,72] width:20 height:18 border:useBorder tooltip:"Include PRT Loaders" highlightcolor:KrakatoaSkinColorsStruct.VFB
				checkbutton chk_PRTVolume "Vol" pos:[180,72] width:20 height:18 border:useBorder	tooltip:"Include PRT Volume Objects" highlightcolor:KrakatoaSkinColorsStruct.VFB
				checkbutton chk_PRTSurface "Srf" pos:[200,72] width:20 height:18 border:useBorder	tooltip:"Include PRT Surface Objects" highlightcolor:KrakatoaSkinColorsStruct.VFB
				checkbutton chk_Hair "Hr" pos:[220,72] width:20 height:18 border:useBorder tooltip:"Include PRT Hair Particles" highlightcolor:KrakatoaSkinColorsStruct.VFB
				
				checkbutton chk_Creator "Mkr" pos:[240,72] width:20 height:18 border:useBorder tooltip:"Include PRT Maker Particles" highlightcolor:KrakatoaSkinColorsStruct.VFB
				checkbutton chk_Source "Src" pos:[260,72] width:20 height:18 border:useBorder tooltip:"Include PRT Source Particles" highlightcolor:KrakatoaSkinColorsStruct.VFB
				checkbutton chk_Field "Fld" pos:[280,72] width:20 height:18 border:useBorder tooltip:"Include Stoke PRT Field Particles" highlightcolor:KrakatoaSkinColorsStruct.VFB
				checkbutton chk_Stoke "Sk" pos:[300,72] width:20 height:18 border:useBorder tooltip:"Include Stoke Particles" highlightcolor:KrakatoaSkinColorsStruct.VFB
				
				checkbutton chk_enableLightingCache "LCache" pos:[228,0] width:42 height:33 border:useBorder tooltip:"Enable Lighting Cache" highlightcolor:KrakatoaSkinColorsStruct.VFB
				progressbar prg_cacheStatus  pos:[228,33] width:42 height:7 value:100 color:green 
				checkbutton chk_enableParticleCache "PCache" pos:[228,39] width:42 height:33 border:useBorder tooltip:"Enable Particle Cache" highlightcolor:KrakatoaSkinColorsStruct.VFB

				checkbutton chk_iterativeRender "Iterative" pos:[270,0] width:80 height:17 border:useBorder tooltip:"Iterative Mode - Render Current Frame Without Saving" highlightcolor:KrakatoaSkinColorsStruct.VFB
				button btn_render "RENDER" pos:[270,17] width:80 height:38 border:useBorder 
				
				spinner spn_globalPercent "" range:[0,100,100] fieldwidth:40 pos:[267,55]
				button btn_globalPercent "%..." pos:[320,55] height:17 width:30 tooltip:"'Load Percentage of All Particles' Presets..."

				fn updateIcons =
				(
					btn_MotionBlurSegments_Preset.images = #(Krakatoa_PresetsArrowBitmap,Krakatoa_PresetsArrowBitmap, 32,1,1,2,2)
					btn_matteMotionBlurSegmentsPreset.images = #(Krakatoa_PresetsArrowBitmap,Krakatoa_PresetsArrowBitmap, 32,1,1,2,2)
					btn_MotionBlurShutter_Preset.images = #(Krakatoa_PresetsArrowBitmap,Krakatoa_PresetsArrowBitmap, 32,1,1,2,2)
					
					btn_AdaptiveMotionBlurSegmentLowerBound_Preset.images = #(Krakatoa_PresetsArrowBitmap,Krakatoa_PresetsArrowBitmap, 32,1,1,2,2)
					btn_AdaptiveMotionBlurSegmentUpperBound_Preset.images = #(Krakatoa_PresetsArrowBitmap,Krakatoa_PresetsArrowBitmap, 32,1,1,2,2)
					btn_AdaptiveMotionBlurSmoothness_Preset.images = #(Krakatoa_PresetsArrowBitmap,Krakatoa_PresetsArrowBitmap, 32,1,1,2,2)
					btn_AdaptiveMotionBlurExponent_Preset.images =  #(Krakatoa_PresetsArrowBitmap,Krakatoa_PresetsArrowBitmap, 32,1,1,2,2)					
					
					btn_DepthOfFieldSampleRate_Preset.images = #(Krakatoa_PresetsArrowBitmap,Krakatoa_PresetsArrowBitmap, 32,1,1,2,2)
					btn_MatteMotionBlurBias_Preset.images = #(Krakatoa_PresetsArrowBitmap,Krakatoa_PresetsArrowBitmap, 32,1,1,2,2)
					btn_RenderParticlesFrom_Preset.images = #(Krakatoa_PresetsArrowBitmap,Krakatoa_PresetsArrowBitmap, 32,1,1,2,2)
				)
				
				
				on btn_render pressed do 
				(
					initializeKrakatoaGUI()
					Krakatoa_GUI_Main.btn_quickRender.pressed()
				)	
				
				on btn_render rightclick do 
				(
					if renderSceneDialog.isOpen() do renderSceneDialog.commit()
					Krakatoa_RCMenu_Struct.RenderButton_RCMenu.mnu_singleFrame.text = "Single Frame [" + (currentTime.frame as integer) as string + "]"
					Krakatoa_RCMenu_Struct.RenderButton_RCMenu.mnu_activeSegment.text = "Active Segment [" + (animationrange.start.frame as integer) as string + "-" + (animationrange.end.frame as integer) as string + "] Nth: " + rendNthFrame as string
					Krakatoa_RCMenu_Struct.RenderButton_RCMenu.mnu_customRange.text = "Custom Range [" + (rendStart.frame as integer) as string + "-" + (rendEnd .frame as integer) as string + "] Nth: " + rendNthFrame as string
					Krakatoa_RCMenu_Struct.RenderButton_RCMenu.mnu_CustomFrames.text = "Custom Frames ["  + rendPickupFrames + "] Nth: " + rendNthFrame as string
					popupmenu Krakatoa_RCMenu_Struct.RenderButton_RCMenu position:mouse.ScreenPos 
				)	
				
				on chk_enableLightingCache rightclick do Krakatoa_GUI_Main.showCacheSize()
				on chk_enableParticleCache rightclick do Krakatoa_GUI_Main.showCacheSize()
				

					
				on btn_MotionBlurSegments_Preset pressed do
				(
					initializeKrakatoaGUI()
					Krakatoa_GUI_Main.createPresetsRCMenu type:#mblur
					popUpMenu Krakatoa_RCMenu_Struct.Presets_RCMenu position:mouse.screenPos
				)	
				on btn_MotionBlurSegments_Preset rightclick do
				(
					initializeKrakatoaGUI()
					Krakatoa_GUI_Main.createPresetsRCMenu type:#mblur
					popUpMenu Krakatoa_RCMenu_Struct.Presets_RCMenu position:mouse.screenPos
				)	
				
				on btn_matteMotionBlurSegmentsPreset pressed do
				(
					initializeKrakatoaGUI()
					Krakatoa_GUI_Main.createPresetsRCMenu type:#geosamples
					popUpMenu Krakatoa_RCMenu_Struct.Presets_RCMenu position:mouse.screenPos
				)	
				on btn_matteMotionBlurSegmentsPreset rightclick do
				(
					initializeKrakatoaGUI()
					Krakatoa_GUI_Main.createPresetsRCMenu type:#geosamples
					popUpMenu Krakatoa_RCMenu_Struct.Presets_RCMenu position:mouse.screenPos
				)					

				on btn_MotionBlurShutter_Preset pressed do
				(
					initializeKrakatoaGUI()
					Krakatoa_GUI_Main.createPresetsRCMenu type:#shutter
					popUpMenu Krakatoa_RCMenu_Struct.Presets_RCMenu position:mouse.screenPos
				)	
				on btn_MotionBlurShutter_Preset rightclick do
				(
					initializeKrakatoaGUI()
					Krakatoa_GUI_Main.createPresetsRCMenu type:#shutter
					popUpMenu Krakatoa_RCMenu_Struct.Presets_RCMenu position:mouse.screenPos
				)		

				on btn_MatteMotionBlurBias_Preset pressed do
				(
					initializeKrakatoaGUI()
					Krakatoa_GUI_Main.createPresetsRCMenu type:#bias
					popUpMenu Krakatoa_RCMenu_Struct.Presets_RCMenu position:mouse.screenPos
				)	
				on btn_MatteMotionBlurBias_Preset rightclick do
				(
					initializeKrakatoaGUI()
					Krakatoa_GUI_Main.createPresetsRCMenu type:#bias
					popUpMenu Krakatoa_RCMenu_Struct.Presets_RCMenu position:mouse.screenPos
				)	
				
				on btn_AdaptiveMotionBlurSegmentLowerBound_Preset pressed do
				(
					initializeKrakatoaGUI()
					Krakatoa_GUI_Main.createPresetsRCMenu type:#lowerbound
					popUpMenu Krakatoa_RCMenu_Struct.Presets_RCMenu position:mouse.screenPos
				)	

				on btn_AdaptiveMotionBlurSegmentLowerBound_Preset rightclick do
				(
					initializeKrakatoaGUI()
					Krakatoa_GUI_Main.createPresetsRCMenu type:#lowerbound
					popUpMenu Krakatoa_RCMenu_Struct.Presets_RCMenu position:mouse.screenPos
				)	
				
				on btn_AdaptiveMotionBlurSegmentUpperBound_Preset pressed do
				(
					initializeKrakatoaGUI()
					Krakatoa_GUI_Main.createPresetsRCMenu type:#upperbound
					popUpMenu Krakatoa_RCMenu_Struct.Presets_RCMenu position:mouse.screenPos
				)	

				on btn_AdaptiveMotionBlurSegmentUpperBound_Preset rightclick do
				(
					initializeKrakatoaGUI()
					Krakatoa_GUI_Main.createPresetsRCMenu type:#upperbound
					popUpMenu Krakatoa_RCMenu_Struct.Presets_RCMenu position:mouse.screenPos
				)		

				on btn_AdaptiveMotionBlurSmoothness_Preset pressed do
				(
					initializeKrakatoaGUI()
					Krakatoa_GUI_Main.createPresetsRCMenu type:#smoothness
					popUpMenu Krakatoa_RCMenu_Struct.Presets_RCMenu position:mouse.screenPos
				)	

				on btn_AdaptiveMotionBlurSmoothness_Preset rightclick do
				(
					initializeKrakatoaGUI()
					Krakatoa_GUI_Main.createPresetsRCMenu type:#smoothness
					popUpMenu Krakatoa_RCMenu_Struct.Presets_RCMenu position:mouse.screenPos
				)				
				on btn_AdaptiveMotionBlurExponent_Preset pressed do
				(
					initializeKrakatoaGUI()
					Krakatoa_GUI_Main.createPresetsRCMenu type:#adaptivembexponent
					popUpMenu Krakatoa_RCMenu_Struct.Presets_RCMenu position:mouse.screenPos
				)	

				on btn_AdaptiveMotionBlurExponent_Preset rightclick do
				(
					initializeKrakatoaGUI()
					Krakatoa_GUI_Main.createPresetsRCMenu type:#adaptivembexponent
					popUpMenu Krakatoa_RCMenu_Struct.Presets_RCMenu position:mouse.screenPos
				)					
				
				
				on btn_DepthOfFieldSampleRate_Preset pressed do
				(
					initializeKrakatoaGUI()
					Krakatoa_GUI_Main.createPresetsRCMenu type:#dofsamplerate
					popUpMenu Krakatoa_RCMenu_Struct.Presets_RCMenu position:mouse.screenPos
				)	
				on btn_DepthOfFieldSampleRate_Preset rightclick do
				(
					initializeKrakatoaGUI()
					Krakatoa_GUI_Main.createPresetsRCMenu type:#dofsamplerate
					popUpMenu Krakatoa_RCMenu_Struct.Presets_RCMenu position:mouse.screenPos
				)		
				
				on btn_globalPercent pressed do
				(
					initializeKrakatoaGUI()
					Krakatoa_GUI_Main.createPresetsRCMenu type:#globalpercentage
					popUpMenu Krakatoa_RCMenu_Struct.Presets_RCMenu position:mouse.screenPos
				)	
				on btn_globalPercent rightclick do
				(
					initializeKrakatoaGUI()
					Krakatoa_GUI_Main.createPresetsRCMenu type:#globalpercentage
					popUpMenu Krakatoa_RCMenu_Struct.Presets_RCMenu position:mouse.screenPos
				)					

				on btn_RenderParticlesFrom_Preset pressed do
				(
					initializeKrakatoaGUI()
					Krakatoa_GUI_Main.createSourcePresetsRCMenu()
					popUpMenu Krakatoa_RCMenu_Struct.Presets_RCMenu position:mouse.screenPos
				)	
				on btn_RenderParticlesFrom_Preset rightclick do
				(
					initializeKrakatoaGUI()
					Krakatoa_GUI_Main.createSourcePresetsRCMenu() 
					popUpMenu Krakatoa_RCMenu_Struct.Presets_RCMenu position:mouse.screenPos
				)			
				
				

				fn updateIterativeRenderText =
				(
					local theString = case (FranticParticles.GetProperty "IterativeRender:ScaleFactor") of
					(
						"2": "x2"
						"1": "Full"
						"1/2": "1/2"
						"1/4": "1/4"
						"1/8": "1/8"
						"1/16": "1/16"
					)
					chk_iterativeRender.text = (if (FranticParticles.GetBoolProperty "VFB:InteractiveUpdate") then "InterActive " else "Iterative ") + theString
				)	
				
				
				fn refreshCacheStatus =
				(
					prg_cacheStatus.color = case FranticParticleRenderMXS.IsCacheValid() of
					(
						#valid: green
						#invalid: yellow
						#validchanged: orange--(color 100 200 255)
						default: ((colorman.getColor #background)*255)
					)
				)		
					
				fn refresh_GUI =
				(
					FranticParticles.LogDebug "  !VFB: Right Panel refresh_GUI() Called!"
					
					local enableSaveParticleFileControls = (FranticParticles.GetProperty "ParticleMode") == "Save Particles To File Sequence"
					
					chk_EnableMotionBlur.state = FranticParticles.GetBoolProperty "EnableMotionBlur"
					chk_JitteredMotionBlur.state = FranticParticles.GetBoolProperty "JitteredMotionBlur"
					chk_disableCameraMotionBlur.state = FranticParticles.GetBoolProperty "DisableCameraMotionBlur"
					chk_DeformationMotionBlur.state = FranticParticles.GetBoolProperty "DeformationMotionBlur"
					
					chk_EnableDepthOfField.state = FranticParticles.GetBoolProperty "EnableDepthOfField"
					ckk_AllocateBokehBlendInfluence.state = FranticParticles.GetBoolProperty "Channel:Allocate:BokehBlendInfluence"
					
					spn_MotionBlurSegments.value = FranticParticles.GetFloatProperty "MotionBlurSegments"
					spn_MatteMotionBlurSegments.value = FranticParticles.GetFloatProperty "MatteMotionBlurSegments"

					spn_MotionBlurShutter.value = FranticParticles.GetFloatProperty "ShutterAngleInDegrees"
					spn_MatteMotionBlurBias.value = FranticParticles.GetFloatProperty "ShutterBias"
					spn_DepthOfFieldSampleRate.value = FranticParticles.GetFloatProperty "DepthOfFieldSampleRate"
					
					chk_useMatteSegments.state = 	FranticParticles.GetBoolProperty "UseMatteMotionBlurSegments"
					
					chk_PFg.state = FranticParticles.GetBoolProperty "RenderParticleFlowGeometry"
					chk_PFp.state = FranticParticles.GetBoolProperty "RenderParticleFlowPhantom"
					chk_PFb.state = FranticParticles.GetBoolProperty "RenderParticleFlowBBox"
					chk_LP.state = FranticParticles.GetBoolProperty "RenderMaxParticles"
					
					chk_TP.state = FranticParticles.GetBoolProperty "RenderThinkingParticles"
					chk_Fume.state = FranticParticles.GetBoolProperty "RenderFumeFX"
					chk_Phoenix.state = FranticParticles.GetBoolProperty "RenderPhoenixFD"
					chk_GV.state = FranticParticles.GetBoolProperty "RenderGeometryVertices"
					
					chk_PRT.state = FranticParticles.GetBoolProperty "RenderKrakatoaLoaders"
					chk_PRTVolume.state = FranticParticles.GetBoolProperty "RenderGeometryVolumes"
					chk_PRTSurface.state = FranticParticles.GetBoolProperty "RenderPRTSurface"
					chk_Hair.state = FranticParticles.GetBoolProperty "RenderPRTHair"
					
					chk_Creator.state = FranticParticles.GetBoolProperty "RenderPRTCreator"
					chk_Source.state = FranticParticles.GetBoolProperty "RenderPRTSource"
					chk_Field.state = FranticParticles.GetBoolProperty "RenderPRTField"
					chk_Stoke.state = FranticParticles.GetBoolProperty "RenderStoke"
					
					chk_enableParticleCache.state = FranticParticles.GetBoolProperty "EnableParticleCache" 
					chk_enableLightingCache.state = FranticParticles.GetBoolProperty "EnableLightingCache" 			
					
					chk_iterativeRender.state = FranticParticles.GetBoolProperty "IterativeRender"
					
					chk_enableParticleCache.enabled = not enableSaveParticleFileControls  
					chk_enableLightingCache.enabled = not enableSaveParticleFileControls and not (FranticParticles.GetBoolProperty "IgnoreSceneLights") --and not (FranticParticles.GetBoolProperty "Lighting:Specular:Enabled")
					btn_render.enabled = chk_iterativeRender.enabled = not enableSaveParticleFileControls  
					spn_globalPercent.value = FranticParticles.GetFloatProperty "GlobalParticlePercentage" 
					
					
					chk_EnableAdaptiveMotionBlur.state  = FranticParticles.GetBoolProperty "EnableAdaptiveMotionBlur"
					spn_AdaptiveMotionBlurSmoothness.value = FranticParticles.GetFloatProperty "AdaptiveMotionBlurSmoothness"
					spn_AdaptiveMotionBlurExponent.value = FranticParticles.GetFloatProperty "AdaptiveMotionBlurExponent"
					spn_AdaptiveMotionBlurSegmentLowerBound.value = FranticParticles.GetFloatProperty "AdaptiveMotionBlurSegmentLowerBound"
					spn_AdaptiveMotionBlurSegmentUpperBound.value = FranticParticles.GetFloatProperty "AdaptiveMotionBlurSegmentUpperBound"
					
					
					btn_matteMotionBlurSegmentsPreset.enabled = spn_matteMotionBlurSegments.enabled = chk_useMatteSegments.state and chk_EnableMotionBlur.state
					chk_DisableCameraMotionBlur.enabled = btn_MatteMotionBlurBias_Preset.enabled = btn_MotionBlurShutter_Preset.enabled = btn_MotionBlurSegments_Preset.enabled = chk_useMatteSegments.enabled = chk_JitteredMotionBlur.enabled = chk_DeformationMotionBlur.enabled = spn_MotionBlurSegments.enabled = spn_MotionBlurShutter.enabled = spn_MatteMotionBlurBias.enabled = chk_EnableMotionBlur.state
					spn_AdaptiveMotionBlurSegmentLowerBound.enabled = spn_AdaptiveMotionBlurSegmentUpperBound.enabled = spn_AdaptiveMotionBlurSmoothness.enabled = spn_AdaptiveMotionBlurExponent.enabled = chk_EnableMotionBlur.state  AND chk_EnableAdaptiveMotionBlur.state  
					btn_AdaptiveMotionBlurSegmentLowerBound_Preset.enabled = btn_AdaptiveMotionBlurSegmentUpperBound_Preset.enabled = btn_AdaptiveMotionBlurSmoothness_Preset.enabled = btn_AdaptiveMotionBlurExponent_Preset.enabled = chk_EnableMotionBlur.state AND chk_EnableAdaptiveMotionBlur.state  
					chk_EnableAdaptiveMotionBlur.enabled = chk_EnableMotionBlur.state  
					ckk_AllocateBokehBlendInfluence.enabled = btn_DepthOfFieldSampleRate_Preset.enabled = spn_DepthOfFieldSampleRate.enabled = (chk_EnableDepthOfField.state AND (FranticParticles.GetProperty "RenderingMethod") != "Voxel Rendering" )

					refreshCacheStatus()
					updateIterativeRenderText()
				)
				
				on spn_globalPercent changed val do 
				(
					FranticParticles.SetProperty "GlobalParticlePercentage" (val as string)
					RefreshMainGUI()					
				)
				
				on chk_useMatteSegments changed val do 
				(
					FranticParticles.SetProperty "UseMatteMotionBlurSegments" (val as string)
					--btn_matteMotionBlurSegmentsPreset.enabled = spn_matteMotionBlurSegments.enabled = val
					refresh_GUI()
					RefreshMainGUI()
					Krakatoa_VFB_methods.InteractiveUpdate()					
				)	
				
				on chk_iterativeRender changed state do 
				(
					FranticParticles.SetProperty "IterativeRender" (state as string)
					DaylightSimulationUtilities.SetRenderIterative state
					Krakatoa_GUI_Main.chk_iterativeRender.state = state
					RefreshMainGUI()
				)	
				
				on chk_iterativeRender rightClick do 
				(
					popupMenu Krakatoa_VFB_Menus.InteractiveUpdatesRCMenu pos:mouse.screenpos
				)				
				
				on chk_enableParticleCache changed state do 
				(
					FranticParticles.SetProperty "EnableParticleCache" (state as string)
					if not state do FranticParticles.SetProperty "EnableLightingCache" (state as string)
					RefreshMainGUI()
				)	
				on chk_enableLightingCache changed state do 
				(
					FranticParticles.SetProperty "EnableLightingCache" (state as string)
					if state do FranticParticles.SetProperty "EnableParticleCache" (state as string)
					RefreshMainGUI()
				)				
				
				on chk_PFg changed state do 
				(
					FranticParticles.SetProperty "RenderParticleFlowGeometry" (state as string)
					RefreshMainGUI()
				)
				on chk_PFp changed state do 
				(
					FranticParticles.SetProperty "RenderParticleFlowPhantom" (state as string)
					RefreshMainGUI()
				)		
				on chk_PFb changed state do 
				(
					FranticParticles.SetProperty "RenderParticleFlowBBox" (state as string)
					RefreshMainGUI()
				)			
				on chk_LP changed state do 
				(
					FranticParticles.SetProperty "RenderMaxParticles" (state as string)
					RefreshMainGUI()
				)
				
				on chk_TP changed state do 
				(
					FranticParticles.SetProperty "RenderThinkingParticles" (state as string)
					RefreshMainGUI()
				)	
				on chk_Fume changed state do 
				(
					FranticParticles.SetProperty "RenderFumeFX" (state as string)
					RefreshMainGUI()
				)
				on chk_Phoenix changed state do 
				(
					FranticParticles.SetProperty "RenderPhoenixFD" (state as string)
					RefreshMainGUI()
				)				
				on chk_GV changed state do 
				(
					FranticParticles.SetProperty "RenderGeometryVertices" (state as string)
					RefreshMainGUI()
				)	
	
				on chk_PRT changed state do 
				(
					FranticParticles.SetProperty "RenderKrakatoaLoaders" (state as string)
					RefreshMainGUI()
				)			
				on chk_PRTVolume changed state do 
				(
					FranticParticles.SetProperty "RenderGeometryVolumes" (state as string)
					RefreshMainGUI()
				)	
				on chk_PRTSurface changed state do 
				(
					FranticParticles.SetProperty "RenderPRTSurface" (state as string)
					RefreshMainGUI()
				)					
				on chk_Hair changed state do 
				(
					FranticParticles.SetProperty "RenderPRTHair" (state as string)
					RefreshMainGUI()
				)	
				
				on chk_Creator changed state do 
				(
					FranticParticles.SetProperty "RenderPRTCreator" (state as string)
					RefreshMainGUI()
				)	
				on chk_Source changed state do 
				(
					FranticParticles.SetProperty "RenderPRTSource" (state as string)
					RefreshMainGUI()
				)	
				on chk_Field changed state do 
				(
					FranticParticles.SetProperty "RenderPRTField" (state as string)
					RefreshMainGUI()
				)	
				on chk_Stoke changed state do 
				(
					FranticParticles.SetProperty "RenderStoke" (state as string)
					RefreshMainGUI()
				)					
				
				on chk_EnableMotionBlur changed state do 
				(
					FranticParticles.SetProperty "EnableMotionBlur" (state as string)
					RefreshMainGUI()
					Krakatoa_VFB_methods.InteractiveUpdate()
				)	
				
				on chk_JitteredMotionBlur changed val do
				(
					FranticParticles.SetProperty "JitteredMotionBlur" (val as string)
					RefreshMainGUI()
					if chk_EnableMotionBlur.checked do Krakatoa_VFB_methods.InteractiveUpdate()
				)
				
				on chk_DisableCameraMotionBlur changed val do
				(
					FranticParticles.SetProperty "DisableCameraMotionBlur" (val as string)
					RefreshMainGUI()
					if chk_EnableMotionBlur.checked do Krakatoa_VFB_methods.InteractiveUpdate()					
				)
				
				on chk_DeformationMotionBlur changed val do
				(
					FranticParticles.SetProperty "DeformationMotionBlur" (val as string)
					RefreshMainGUI()			
					Krakatoa_VFB_methods.InteractiveUpdate()					
				)
				
				on chk_EnableAdaptiveMotionBlur changed val do
				(
					FranticParticles.SetProperty "EnableAdaptiveMotionBlur" (val as string)
					RefreshMainGUI()			
					Krakatoa_VFB_methods.InteractiveUpdate()							
				)
				
				on spn_AdaptiveMotionBlurSegmentLowerBound changed val do
				(
					FranticParticles.SetProperty "AdaptiveMotionBlurSegmentLowerBound" (val as string)
					RefreshMainGUI()			
					Krakatoa_VFB_methods.InteractiveUpdate()							
				)

				on spn_AdaptiveMotionBlurSegmentUpperBound changed val do
				(
					FranticParticles.SetProperty "AdaptiveMotionBlurSegmentUpperBound" (val as string)
					RefreshMainGUI()			
					Krakatoa_VFB_methods.InteractiveUpdate()							
				)	

				on spn_AdaptiveMotionBlurSmoothness changed val do
				(
					FranticParticles.SetProperty "AdaptiveMotionBlurSmoothness" (val as string)
					RefreshMainGUI()			
					Krakatoa_VFB_methods.InteractiveUpdate()							
				)	
				
				on spn_AdaptiveMotionBlurExponent changed val do
				(
					FranticParticles.SetProperty "AdaptiveMotionBlurExponent" (val as string)
					RefreshMainGUI()			
					Krakatoa_VFB_methods.InteractiveUpdate()							
				)					
				
				on chk_EnableDepthOfField changed val do
				(
					FranticParticles.SetProperty "EnableDepthOfField" (val as string)
					RefreshMainGUI()
					btn_DepthOfFieldSampleRate_Preset.enabled = spn_DepthOfFieldSampleRate.enabled = (val AND (FranticParticles.GetProperty "RenderingMethod") != "Voxel Rendering" )
					Krakatoa_VFB_methods.InteractiveUpdate()
				)
				
				on ckk_AllocateBokehBlendInfluence changed val do
				(
					FranticParticles.SetProperty "Channel:Allocate:BokehBlendInfluence" (val as string)
					RefreshMainGUI()		
				)
				
				on spn_MotionBlurSegments changed val do
				(
					FranticParticles.SetProperty "MotionBlurSegments" (val as string)
					RefreshMainGUI()
					if chk_EnableMotionBlur.checked do Krakatoa_VFB_methods.InteractiveUpdate()
				)

				on spn_MotionBlurShutter changed val do
				(
					FranticParticles.SetProperty "ShutterAngleInDegrees" (val as string)
					RefreshMainGUI()
					if chk_EnableMotionBlur.checked do Krakatoa_VFB_methods.InteractiveUpdate()
				)
				
				on spn_MatteMotionBlurBias changed val do
				(
					FranticParticles.SetProperty "ShutterBias" (val as string)
					RefreshMainGUI()
					if chk_EnableMotionBlur.checked do Krakatoa_VFB_methods.InteractiveUpdate()
				)		
				
				on spn_MatteMotionBlurSegments changed val do
				(
					FranticParticles.SetProperty "MatteMotionBlurSegments" (val as string)
					RefreshMainGUI()
					if chk_EnableMotionBlur.checked do Krakatoa_VFB_methods.InteractiveUpdate()
				)						
				

				on spn_DepthOfFieldSampleRate changed val do
				(
					FranticParticles.SetProperty "DepthOfFieldSampleRate" (val as string)
					RefreshMainGUI()
					if chk_EnableDepthOfField.checked do Krakatoa_VFB_methods.InteractiveUpdate()
				)			
					
				on Krakatoa_VFB_Right_Rollout open do 
				(
					updateIcons()
					refresh_GUI()
				)
			)

			rollout Krakatoa_VFB_Overlay_Rollout "" width:640 height:100
			(
				local timeMode = 5
				local countMode = 4
				local memoryMode = 4
				
				button btn_lastTime "Last Frame:" border:useBorder pos:[0,0] width:150 height:20 tooltip:"Click repeatedly to cycle through time display modes: milliseconds, seconds, hh:mm:ss.d, hh:mm:ss, [Automatic Format]\n\nRight-click to copy value to Windows Clipboard."
				button btn_BytesPerParticle "Bytes/Particle:" border:useBorder pos:[0,20] width:150 height:20 tooltip:"Displays the number of Bytes per Particle. Has no alternative display modes.\n\nRight-click to copy value to Windows Clipboard." 
				button btn_CacheCount "Cache Count:" border:useBorder pos:[0,40] width:150 height:20  tooltip:"Click repeatedly to cycle through particle count display modes: Particles, Thousands, Millions, [Automatic Units].\n\nRight-click to copy value to Windows Clipboard."
				button btn_CacheMemory "Cache Memory:" border:useBorder pos:[0,60] width:150 height:20 tooltip:"Click repeatedly to cycle through memory display modes: Bytes, Kilobytes, Megabytes, [Automatic Units].\n\nRight-click to copy value to Windows Clipboard."
				listbox lbx_activeMemoryChannels pos:[150,-2] height:6 width:200

				
				checkbutton chk_saveHistory ">Save History" border:useBorder pos:[290+60,0] width:100 height:20 highlightcolor:KrakatoaSkinColorsStruct.VFB
				checkbutton chk_saveImages ">Save Images" border:useBorder pos:[365+60+25,0] width:100 height:20 highlightcolor:KrakatoaSkinColorsStruct.VFB
				button btn_presetsAndHistoryRollout ">>" border:useBorder pos:[440+110,0] width:28 height:20 

				button btn_mainControlsRolloutLabel "Global Values & Main Controls" border:useBorder pos:[290+60,20] width:200 height:20 
				button btn_mainControlsRollout ">>" border:useBorder pos:[440+110,20] width:28 height:20 
				
				button btn_channelsRolloutLabel "Memory Channels & Saving" border:useBorder pos:[290+60,40] width:200 height:20 
				button btn_channelsRollout ">>" border:useBorder pos:[440+110,40] width:28 height:20 
				
				button btn_sceneParticleSystemsRolloutLabel "Krakatoa Explorers..." border:useBorder pos:[290+60,60] width:200 height:20 
				button btn_sceneParticleSystemsRollout ">>" border:useBorder pos:[440+110,60] width:28 height:20 
				
				checkbutton chk_useMatteObjects ">Use Matte" border:useBorder pos:[470+60+50-2,0] width:100 height:20 highlightcolor:KrakatoaSkinColorsStruct.VFB
				checkbutton chk_saveLayers ">Save Layers" border:useBorder pos:[542+60+28+50-2,0] width:100 height:20 highlightcolor:KrakatoaSkinColorsStruct.VFB
				button btn_matteObjectsRollout ">>" border:useBorder pos:[614+60+56+50-2,0] width:28 height:20 

				checkbutton chk_useDepthFiles ">Depth Files" border:useBorder pos:[470+60+50-2,20] width:100 height:20 highlightcolor:KrakatoaSkinColorsStruct.VFB
				checkbutton chk_saveAttenuationMaps ">Save Attenuation" border:useBorder pos:[542+60+28+50-2,20] width:100 height:20 highlightcolor:KrakatoaSkinColorsStruct.VFB
				button btn_shadowsOnGeometryRollout ">>" border:useBorder pos:[614+60+56+50-2,20] width:28 height:20 
				
				checkbutton chk_UseAmbientPME ">Use APME" border:useBorder pos:[470+60+50-2,40] width:100 height:20 highlightcolor:KrakatoaSkinColorsStruct.VFB
				bitmap bmp_APME pos:[542+60+28+50-2,40] width:100 height:20 
				button btn_ambientPMERollout ">>" border:useBorder pos:[614+60+56+50-2,40] width:28 height:20 
				
				button btn_preferencesRolloutLabel "Preferences..." border:useBorder pos:[470+60+50-2,60] width:100 height:20 
				button btn_LogRolloutLabel "Log Window..." border:useBorder pos:[542+60+28+50-2,60] width:100 height:20 
				button btn_preferencesRollout ">>" border:useBorder pos:[614+60+56+50-2,60] width:28 height:20 
			
				fn updateIcons = 
				(
					btn_presetsAndHistoryRollout.images=#(Krakatoa_PresetsArrowBitmap,Krakatoa_PresetsArrowBitmap, 32,1,1,2,2)
					btn_mainControlsRollout.images=#(Krakatoa_PresetsArrowBitmap,Krakatoa_PresetsArrowBitmap, 32,1,1,2,2)
					btn_channelsRollout.images=#(Krakatoa_PresetsArrowBitmap,Krakatoa_PresetsArrowBitmap, 32,1,1,2,2)
					btn_sceneParticleSystemsRollout.images=#(Krakatoa_PresetsArrowBitmap,Krakatoa_PresetsArrowBitmap, 32,1,1,2,2)
					btn_matteObjectsRollout.images=#(Krakatoa_PresetsArrowBitmap,Krakatoa_PresetsArrowBitmap, 32,1,1,2,2)
					btn_shadowsOnGeometryRollout.images=#(Krakatoa_PresetsArrowBitmap,Krakatoa_PresetsArrowBitmap, 32,1,1,2,2)
					btn_ambientPMERollout.images=#(Krakatoa_PresetsArrowBitmap,Krakatoa_PresetsArrowBitmap, 32,1,1,2,2)
					btn_preferencesRollout.images=#(Krakatoa_PresetsArrowBitmap,Krakatoa_PresetsArrowBitmap, 32,1,1,2,2)
				)
			
				fn updateAPME =
				(
					FranticParticles.LogDebug "  !VFB: updateAPME() Called!"
					
					try
					(
						tempBmp = bitmap 100 20
						copy Krakatoa_GUI_AmbientPME.thePMEBitmap tempBmp
						bmp_APME.bitmap = tempBmp 
					)catch()					
				)
				
				fn refreshLastCacheButtons =
				(
					FranticParticles.LogDebug "  !VFB: refreshLastCacheButtons() Called!"
					
					local theTime = FranticParticleRenderMXS.lastFrameRenderEndTime  - FranticParticleRenderMXS.lastFrameRenderStartTime
					local tmMode = timeMode
					if timeMode == 5 do
					(
						local theTimeCount = theTime/1000.0
						tmMode = 1
						if theTimeCount > 0 do tmMode = 2
						if theTimeCount > 60 do tmMode = 3
						if theTimeCount > 360 do tmMode = 4
					)
					
					local theTimeString = case tmMode of
					(
						1: FranticParticleRenderMXS.addCommas (theTime as string) + " ms"
						2: FranticParticleRenderMXS.addCommas ((theTime/1000.0) as string) + " sec."
						3: FranticParticleRenderMXS.convertToHMS (theTime/1000.0) precision:#float
						4: FranticParticleRenderMXS.convertToHMS (theTime/1000.0) precision:#integer
					)
					btn_lastTime.caption = (if timeMode == 5 then "[Last Frame]: " else "Last Frame: ")  + theTimeString
					
					local theCount = try((FranticParticles.GetCachedParticleCount()) )catch(0)
					
					local cntMode = countMode
					if countMode == 4 do
					(
						local theCountNum = (theCount as string).count
						cntMode = 1
						if theCountNum > 3 do cntMode = 2
						if theCountNum > 6 do cntMode = 3
					)	
					
					local theCacheCount = case cntMode of 
					(
						1: FranticParticleRenderMXS.addCommas (theCount as string)
						2: (FranticParticleRenderMXS.addCommas ((theCount/1000.0)  as string)) + " Thousand"
						3: (FranticParticleRenderMXS.addCommas ((theCount/1000000.0) as string)) + " Million"
					)
					btn_CacheCount.caption =  (if countMode == 4 then "[Cached]: " else "Cached: ") + theCacheCount

					local memMode = memoryMode
					local theMemory = try((FranticParticles.getCacheSize()) )catch(0)			
					if memoryMode == 4 then
					(
						memMode = 1
						if theMemory*1024 > 1 do memMode = 2
						if theMemory > 1 do memMode = 3
					)
						
					local theCacheMemory = case memMode of
					(
						1: FranticParticleRenderMXS.addCommas ((((theMemory as Integer64) *1024*1024) as integer) as string) + " Bytes" 
						2: (FranticParticleRenderMXS.addCommas ((theMemory*1024) as string)) + " KB" 
						3: (FranticParticleRenderMXS.addCommas (theMemory as string)) + " MB" 
					)
					btn_CacheMemory.caption = (if memoryMode == 4 then "[Memory]: " else "Memory: ") + theCacheMemory
					
				)
				
				fn refresh_GUI =
				(
					FranticParticles.LogDebug "  !VFB: Bottom Panel refresh_GUI() Called!"
					
					refreshLastCacheButtons()
					try
					(
						--Krakatoa_GUI_Channels.updateMemChannels()
						local activeMemChannels = try(FranticParticles.GetRenderParticleChannels())catch(#()) 
						local theCachedChannels = try(FranticParticles.GetCachedParticleChannels())catch(#())
						local theCachedChannelsArray = for i in theCachedChannels collect i[1]
							
						lbx_activeMemoryChannels.items = for i in activeMemChannels collect 
						(
							local isCached = if FranticParticles.getCacheSize() == 0.0 then "-- " else
								if findItem theCachedChannelsArray i[1] > 0 then "+ " else "-- "
							if i[3] == 1 then
								(isCached + i[1] + "  :  " + i[2])
							else
								(isCached + i[1] + "  :  " + i[2] + "[" + i[3] as string + "]")
						)				
						local theMemPerParticle = FranticParticleRenderMXS.calculateMemoryUsage activeMemChannels
						local txt = "Bytes/Particle: "+ theMemPerParticle[1] as string
						if theMemPerParticle[2] > 0 do txt += "(+"+theMemPerParticle[2] as string + "?)"
						btn_BytesPerParticle.text = txt
					)
					catch
					(
						lbx_activeMemoryChannels.items = #("???")
						btn_BytesPerParticle.text = "Bytes/Particle: ???" 
					)
					lbx_activeMemoryChannels.selection = 0
					
					chk_useMatteObjects.state = FranticParticles.GetBoolProperty "Matte:UseMatteObjects"
					chk_saveLayers.state = FranticParticles.GetBoolProperty "Matte:SaveMultipleLayers"
					chk_useDepthFiles.state = FranticParticles.GetBoolProperty "Matte:UseDepthMapFiles"
					chk_saveAttenuationMaps.state = FranticParticles.GetBoolProperty "EnableAttenuationMapSaving"
					chk_UseAmbientPME.state = FranticParticles.GetBoolProperty "PME:UseExtinction"
					local currentState =  execute (getIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "RolloutVisible" Krakatoa_GUI_Presets.title )
					chk_saveHistory.state = FranticParticles.GetBoolProperty "Presets:SaveRenderHistory"
					chk_saveImages.state = FranticParticles.GetBoolProperty "Presets:SaveImageSample"
					
					try(Krakatoa_GUI_AmbientPME.setExtinction())catch(updateAPME())
				)
				
				on chk_saveHistory changed state do 
				(
					Krakatoa_GUI_Presets.chk_SaveRenderHistory.state = state
					FranticParticles.SetProperty "Presets:SaveRenderHistory" (state as string)
					try(Krakatoa_GUI_Presets.refresh_GUI())catch()
				)
				on chk_saveImages changed state do 
				(
					Krakatoa_GUI_Presets.chk_SaveImageSample.state = state
					FranticParticles.SetProperty "Presets:SaveImageSample" (state as string)
					try(Krakatoa_GUI_Presets.refresh_GUI())catch()
				)
				
				on chk_UseAmbientPME changed state do 
				(
					FranticParticles.SetProperty "PME:UseExtinction" (state as string)
					try(Krakatoa_GUI_AmbientPME.refresh_GUI())catch()
					RefreshMainGUI()	
					updateToolbarButtons()
				)					

				on chk_useMatteObjects changed state do 
				(
					FranticParticles.SetProperty "Matte:UseMatteObjects" (state as string)
					try(Krakatoa_GUI_MatteObjects.refresh_GUI())catch()
					RefreshMainGUI()	
					updateToolbarButtons()
				)	
				on chk_saveLayers changed state do 
				(
					FranticParticles.SetProperty "Matte:SaveMultipleLayers" (state as string)
					if state do FranticParticleRenderMXS.addRenderElement "OccludedLayer" ""
					FranticParticleRenderMXS.toggleRenderElementByClass Krakatoa_OccludedLayer state							
					try(Krakatoa_GUI_MatteObjects.refresh_GUI())catch()
					RefreshMainGUI()	
					updateToolbarButtons()					
				)
				on chk_useDepthFiles changed state do 
				(
					FranticParticles.SetProperty "Matte:UseDepthMapFiles" (state as string)
					try(Krakatoa_GUI_MatteObjects.refresh_GUI())catch()
					RefreshMainGUI()	
					updateToolbarButtons()					
				)		
				on chk_saveAttenuationMaps changed state do 
				(
					FranticParticles.SetProperty "EnableAttenuationMapSaving" (state as string)
					try(Krakatoa_GUI_Shadows.refresh_GUI())catch()
					RefreshMainGUI()	
					updateToolbarButtons()					
				)		
				
				on btn_presetsAndHistoryRollout pressed do popupMenu Krakatoa_VFB_Menus.PresetsAndHistoryRolloutRCMenu pos:mouse.ScreenPos
				on btn_presetsAndHistoryRollout rightclick do popupMenu Krakatoa_VFB_Menus.PresetsAndHistoryRolloutRCMenu pos:mouse.ScreenPos
					
				on chk_saveHistory rightclick do popupMenu Krakatoa_VFB_Menus.PresetsAndHistoryRolloutRCMenu pos:mouse.ScreenPos
				on chk_saveImages rightclick do popupMenu Krakatoa_VFB_Menus.PresetsAndHistoryRolloutRCMenu pos:mouse.ScreenPos
				
				on btn_mainControlsRolloutLabel pressed do popupMenu Krakatoa_VFB_Menus.MainControlsRolloutRCMenu pos:mouse.ScreenPos
				on btn_mainControlsRolloutLabel rightclick do popupMenu Krakatoa_VFB_Menus.MainControlsRolloutRCMenu pos:mouse.ScreenPos
				on btn_mainControlsRollout pressed do popupMenu Krakatoa_VFB_Menus.MainControlsRolloutRCMenu pos:mouse.ScreenPos
				on btn_mainControlsRollout rightclick do popupMenu Krakatoa_VFB_Menus.MainControlsRolloutRCMenu pos:mouse.ScreenPos
					
				
				on btn_channelsRolloutLabel pressed do popupMenu Krakatoa_VFB_Menus.ChannelsRolloutRCMenu pos:mouse.ScreenPos					
				on btn_channelsRolloutLabel rightclick do popupMenu Krakatoa_VFB_Menus.ChannelsRolloutRCMenu pos:mouse.ScreenPos					
				on btn_channelsRollout pressed do popupMenu Krakatoa_VFB_Menus.ChannelsRolloutRCMenu pos:mouse.ScreenPos					
				on btn_channelsRollout rightclick do popupMenu Krakatoa_VFB_Menus.ChannelsRolloutRCMenu pos:mouse.ScreenPos					
				
				
				
				on btn_sceneParticleSystemsRolloutLabel pressed do popupMenu Krakatoa_VFB_Menus.ParticleSystemsAndLoadersRCMenu pos:mouse.ScreenPos					
				on btn_sceneParticleSystemsRolloutLabel rightclick do popupMenu Krakatoa_VFB_Menus.ParticleSystemsAndLoadersRCMenu pos:mouse.ScreenPos					
				on btn_sceneParticleSystemsRollout pressed do popupMenu Krakatoa_VFB_Menus.ParticleSystemsAndLoadersRCMenu pos:mouse.ScreenPos					
				on btn_sceneParticleSystemsRollout rightclick do popupMenu Krakatoa_VFB_Menus.ParticleSystemsAndLoadersRCMenu pos:mouse.ScreenPos					
					
				
				on btn_matteObjectsRollout pressed do popupMenu Krakatoa_VFB_Menus.MatteObjectsRolloutRCMenu pos:mouse.ScreenPos					
				on btn_matteObjectsRollout rightclick do popupMenu Krakatoa_VFB_Menus.MatteObjectsRolloutRCMenu pos:mouse.ScreenPos					
				on chk_useMatteObjects rightclick do popupMenu Krakatoa_VFB_Menus.MatteObjectsRolloutRCMenu pos:mouse.ScreenPos					
				on chk_useDepthFiles rightclick do popupMenu Krakatoa_VFB_Menus.MatteObjectsRolloutRCMenu pos:mouse.ScreenPos					
				on chk_saveLayers rightclick do popupMenu Krakatoa_VFB_Menus.MatteObjectsRolloutRCMenu pos:mouse.ScreenPos					
				
				on btn_shadowsOnGeometryRollout pressed do popupMenu Krakatoa_VFB_Menus.ShadowsOnGeometryRolloutRCMenu pos:mouse.ScreenPos					
				on btn_shadowsOnGeometryRollout rightclick do popupMenu Krakatoa_VFB_Menus.ShadowsOnGeometryRolloutRCMenu pos:mouse.ScreenPos					
				
				on btn_ambientPMERollout pressed do popupMenu Krakatoa_VFB_Menus.AmbientPMERolloutRCMenu pos:mouse.ScreenPos					
				on btn_ambientPMERollout rightclick do popupMenu Krakatoa_VFB_Menus.AmbientPMERolloutRCMenu pos:mouse.ScreenPos					
				on chk_UseAmbientPME rightclick do popupMenu Krakatoa_VFB_Menus.AmbientPMERolloutRCMenu pos:mouse.ScreenPos					
					
				
				
				on btn_preferencesRolloutLabel pressed do 
				(
					macros.run "Krakatoa" "KrakatoaPreferences"	
					--navigateToKrakatoaRollout Krakatoa_GUI_Preferences	
--					popupMenu Krakatoa_VFB_Menus.PreferencesRolloutRCMenu pos:mouse.ScreenPos					
				)
				on btn_preferencesRolloutLabel rightclick do 
				(
					macros.run "Krakatoa" "KrakatoaPreferences"	
					--navigateToKrakatoaRollout Krakatoa_GUI_Preferences	
				--	popupMenu Krakatoa_VFB_Menus.PreferencesRolloutRCMenu pos:mouse.ScreenPos					
				)
				
				on btn_LogRolloutLabel pressed do 
				(
					FranticParticles.LogWindowVisible = true
					updateToolbarButtons()					
				)
				on btn_LogRolloutLabel rightclick do 
				(
					FranticParticles.LogWindowVisible = true
					updateToolbarButtons()					
				)
				
				on btn_preferencesRollout pressed do popupMenu Krakatoa_VFB_Menus.PreferencesRolloutRCMenu pos:mouse.ScreenPos					
				on btn_preferencesRollout rightclick do popupMenu Krakatoa_VFB_Menus.PreferencesRolloutRCMenu pos:mouse.ScreenPos					
				
				on lbx_activeMemoryChannels selected itm do lbx_activeMemoryChannels.selection = 0

				on btn_lastTime pressed do 
				(
					TimeMode+=1 
					if TimeMode > 5 do TimeMode =1 
					refreshLastCacheButtons()
				)			
				on btn_lastTime rightClick do
				(
					setclipboardText btn_lastTime.text
				)
				
				on btn_BytesPerParticle rightClick do
				(
					setclipboardText btn_CacheMemory.text
				)	
				
				on btn_CacheCount pressed do 
				(
					countMode+=1 
					if countMode > 4 do countMode =1 
					refreshLastCacheButtons()
				)		
				on btn_CacheCount rightClick do
				(
					setclipboardText btn_CacheCount.text
				)
				
				
				on btn_CacheMemory pressed do 
				(
					memoryMode+=1 
					if memoryMode > 4 do memoryMode =1 
					refreshLastCacheButtons()
				)		
				on btn_CacheMemory rightClick do
				(
					setclipboardText btn_CacheMemory.text
				)				
				
				on Krakatoa_VFB_Overlay_Rollout open do 
				(
					updateIcons()
					refresh_GUI()
				)
			)
		),
		fn VFB_AddRollouts params  =
		(
			FranticParticles.LogDebug "  !VFB: VFB_AddRollouts() Called!"
			
			VFB_Interface = params
			if VFB_Interface != undefined and VFB_Interface.IsFramebuffer then
			(
				--if VFB_IsInitialized() do
				(
					VFB_Interface.InitLayout()
					-- Set layout metrics
					VFB_Interface.showRollups = false
					VFB_Interface.SetMetric #horzMarginLeft		0
					VFB_Interface.SetMetric #horzMarginCenter	0
					VFB_Interface.SetMetric #horzMarginRight	0
					VFB_Interface.SetMetric #vertMarginTop		0
					VFB_Interface.SetMetric #vertMarginCenter	0
					VFB_Interface.SetMetric #vertMarginBottom	0
					VFB_Interface.SetMetric #minClientWidth		0
					VFB_Interface.SetMetric #minClientHeight	0
					VFB_Interface.showRollups = true
					VFB_Interface.showOverlays = true
					local padWidth = 10 -- For future tweaking, currently has no effect
					local padHeight = 3
					
					if classof renderers.current == Krakatoa do
					(
						theFloaterArray[1] = VFB_Interface.InitRolloutWindow #TopLeft (360+155) 97
						addRollout Krakatoa_VFB_Left_Rollout theFloaterArray[1] border:false
						VFB_Interface.SetRolloutWindowVisible #TopLeft true

						theFloaterArray[2] = VFB_Interface.InitRolloutWindow #TopRight 365 97

						addRollout Krakatoa_VFB_Right_Rollout theFloaterArray[2] border:false
						VFB_Interface.SetRolloutWindowVisible #TopRight true

						theFloaterArray[3] = VFB_Interface.InitRolloutWindow #Bottom (665+155+60) 91
						addRollout Krakatoa_VFB_Overlay_Rollout theFloaterArray[3] border:false
						VFB_Interface.SetRolloutWindowVisible #Bottom true
					)	
					VFB_Interface.InitLayout()
				)				
			)
		),
		fn VFB_RemoveRollouts =
		(
			FranticParticles.LogDebug "  !VFB: VFB_RemoveRollouts() Called!"
			
			if Krakatoa_VFB_methods.VFB_Interface != undefined do
			(
				Krakatoa_VFB_methods.VFB_Interface.SetRolloutWindowVisible #Bottom true
				Krakatoa_VFB_methods.VFB_Interface.SetRolloutWindowVisible #TopLeft false
				Krakatoa_VFB_methods.VFB_Interface.SetRolloutWindowVisible #TopRight false
				removeRollout Krakatoa_VFB_Left_Rollout theFloaterArray[1] 
				removeRollout Krakatoa_VFB_Right_Rollout theFloaterArray[2] 
				removeRollout Krakatoa_VFB_Overlay_Rollout theFloaterArray[3] 
			)
		),
		fn VFB_ResetRollouts =
		(
			FranticParticles.LogDebug "  !VFB: VFB_ResetRollouts() Called!"
			
				Krakatoa_VFB_methods.VFB_RemoveRollouts()
				if Krakatoa_VFB_methods.VFB_Interface != undefined do
				(
					Krakatoa_VFB_methods.VFB_AddRollouts Krakatoa_VFB_methods.VFB_Interface
					Krakatoa_VFB_methods.VFB_Interface.InitLayout()
				)
		),
		fn registerCallbacks =
		(
			FranticParticles.LogDebug "  !VFB: registerCallbacks() Called!"
			
			if (maxVersion())[1]>10000 do
			(
				callbacks.removeScripts id:#VFB_Rollouts 
				if VFB_methods.VFB_Interface != undefined AND not isDeleted VFB_methods.VFB_Interface then
				(
					VFB_methods.VFB_RemoveRollouts() --remove the rollouts from the original VFB
					Krakatoa_VFB_methods.VFB_Interface = VFB_methods.VFB_Interface
					Krakatoa_VFB_methods.VFB_DefineRollouts() --redefine the rollouts
					Krakatoa_VFB_methods.VFB_ResetRollouts() --reset the rollouts, including closing the old ones, 
				)
				
				callbacks.removeScripts id:#Krakatoa_VFB_Rollouts 
				
				initializeKrakatoaGUI()
				
				callbacks.addScript #preImageViewerDisplay "try(Krakatoa_VFB_methods.VFB_DefineRollouts();Krakatoa_VFB_methods.VFB_AddRollouts (callbacks.notificationParam()) )catch()" id:#Krakatoa_VFB_Rollouts  
				callbacks.addScript #preRenderFrame "try(FranticParticleRenderMXS.framePreRender())catch()" id:#Krakatoa_VFB_Rollouts  
				callbacks.addScript #filePostOpen "try(if (callbacks.notificationParam() !=2)  do VFB_methods_struct.Reset())catch()" id:#VFB_Rollouts
				callbacks.addScript #systemPostReset "try(VFB_methods_struct.Reset())catch()" id:#VFB_Rollouts
				callbacks.addScript #systemPostNew "try(VFB_methods_struct.Reset())catch()" id:#VFB_Rollouts				
				
				callbacks.addScript #postRenderFrame "try(FranticParticleRenderMXS.framePostRender(); Krakatoa_VFB_Overlay_Rollout.refresh_GUI())catch()" id:#Krakatoa_VFB_Rollouts  
			)
		),
		fn resetCallbacks =
		(
			FranticParticles.LogDebug "  !VFB: resetCallbacks() Called!"
			
			--check if Max 2009+ is running:
			if (maxVersion())[1]>10000 do
			(
				callbacks.removeScripts id:#VFB_Rollouts
				callbacks.removeScripts id:#Krakatoa_VFB_Rollouts 
				
				--if the current VFB interface is valid,
				if Krakatoa_VFB_methods.VFB_Interface != undefined and not isDeleted Krakatoa_VFB_methods.VFB_Interface do
				(
					VFB_methods.VFB_Interface = Krakatoa_VFB_methods.VFB_Interface --set the interface in the VFB struct
					Krakatoa_VFB_methods.VFB_RemoveRollouts() --reset the rollouts of Krakatoa
					VFB_methods.VFB_ResetRollouts() --reset the original VFB rollouts, which includes removing them, adding them again and reinitializing the layout
				)
				
				callbacks.addScript #preImageViewerDisplay "try(VFB_methods.VFB_AddRollouts (callbacks.notificationParam()))catch()" id:#VFB_Rollouts
				callbacks.addScript #filePostOpen "try(if (callbacks.notificationParam() !=2)  do VFB_methods_struct.Reset())catch()" id:#VFB_Rollouts
				callbacks.addScript #systemPostReset "try(VFB_methods_struct.Reset())catch()" id:#VFB_Rollouts
				callbacks.addScript #systemPostNew "try(VFB_methods_struct.Reset())catch()" id:#VFB_Rollouts				
			)
		)
	)
	Krakatoa_VFB_methods = Krakatoa_VFB_methods_struct()
	
	callbacks.removeScripts id:#Krakatoa_VFB_2009
	if (maxVersion())[1]>10000 do
	(
		callbacks.addScript #postRendererChange "try(if classof renderers.current != Krakatoa then (Krakatoa_VFB_methods.resetCallbacks())else(Krakatoa_VFB_methods.registerCallbacks()))catch()" id:#Krakatoa_VFB_2009
		callbacks.addScript #filePostOpen "try(if classof renderers.current != Krakatoa then (Krakatoa_VFB_methods.resetCallbacks())else(Krakatoa_VFB_methods.registerCallbacks()))catch()" id:#Krakatoa_VFB_2009
	)	
)

