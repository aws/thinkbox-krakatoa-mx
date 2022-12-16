-- Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
-- SPDX-License-Identifier: Apache-2.0
------------------------------------------------------------------------------------------------------------------------
--PARTICLE LOADER FILE SEQUENCE MANAGER
------------------------------------------------------------------------------------------------------------------------
global Krakatoa_PRTLoader_FileEditor
global Krakatoa_PRTLoader_FileEditor_CutCopyPasteBuffer 
if Krakatoa_PRTLoader_FileEditor_CutCopyPasteBuffer == undefined do 
	Krakatoa_PRTLoader_FileEditor_CutCopyPasteBuffer = #()
global Krakatoa_PRTLoader_FileEditor_RCMenu 
global Krakatoa_PRTLoader_FileEditor_MainMenu 
global Krakatoa_CurrentPRTLoader


rollout Krakatoa_PRTLoader_Presets_Rollout "Presets"
(
	button btn_savePreset "Save..." align:#left across:2 offset:[-8,-3] height:18 width:76 tooltip:"Save Current Settings as New Preset"
	button btn_setAsDefault "Set Default..." align:#right offset:[8,-3] height:18 width:76 tooltip:"Save Current Settings as New Preset"
	listbox ddl_presets items:#("------Custom Settings------") width:160 align:#center offset:[0,-3] height:5
	button btn_deletePreset "Delete..." align:#left across:2 offset:[-8,-3] height:18 width:76 tooltip:"Save Current Settings as New Preset"
	button btn_explorePresets "Explore..." align:#right offset:[8,-3] height:18 width:76 tooltip:"Save Current Settings as New Preset"
	

	fn populatePresetsList =
	(
		theFiles = getFiles (GetDir #plugcfg + "\\Krakatoa\\presets\\*.KPS")
		ddl_presets.items= join #("------Custom Settings------") (for f in theFiles collect getFileNameFile f)
		if customPresetName != "" do ddl_presets.selection = findItem ddl_presets.items customPresetName 
	)
	
	on btn_explorePresets pressed do
	(
		makeDir (GetDir #plugcfg + "\\Krakatoa\\presets\\") all:true
		shellLaunch "explorer.exe" (GetDir #plugcfg + "\\Krakatoa\\presets\\")
	)
	
	on btn_deletePreset pressed do
	(
		thePresetFile = (GetDir #plugcfg + "\\Krakatoa\\presets\\" + ddl_presets.selected + ".KPS") 
		if doesFileExist thePresetFile and (querybox ("Do you really want to delete the Preset File [" + ddl_presets.selected +"]?") title:"KRAKATOA Particle File Loader: Delete Preset") do
		(
			deleteFile thePresetFile 
			populatePresetsList()
		)
	)
	
	on btn_setAsDefault pressed do
	(
		thePresetFile = (GetDir #plugcfg + "\\Krakatoa\\presets\\" + ddl_presets.selected + ".KPS") 
		if doesFileExist thePresetFile and (querybox ("Do you really want to SET the Preset File [" + ddl_presets.selected +"] as Default for Newly Created Loaders?") title:"KRAKATOA Particle File Loader: Default Preset") do
		(
			setIniSetting ( GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "PRTLoaders" "PresetName" ddl_presets.selected
			setIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "PRTLoaders" "UsePreset" "true"
		)			
	)
	
	on btn_savePreset pressed do
	(
		createDialog Krakatoa_PRTLoader_PresetsOptions 200 500 modal:true
		if Krakatoa_PRTLoader_PresetsOptions_Filename != "" and Krakatoa_PRTLoader_PresetsOptions_Selection.numberset > 0 then
		(
			makeDir (GetDir #plugcfg + "\\Krakatoa\\presets\\") all:true
			thePresetFile = (GetDir #plugcfg + "\\Krakatoa\\presets\\" + Krakatoa_PRTLoader_PresetsOptions_Filename + ".KPS") 
			val = Krakatoa_PRTLoader_PresetsOptions_Selection
			if val[1] do setIniSetting thePresetFile "Settings" "renderLoadMode" (Krakatoa_CurrentPRTLoader.renderLoadMode as string)
			if val[2] do setIniSetting thePresetFile "Settings" "enabledInRender" (Krakatoa_CurrentPRTLoader.enabledInRender as string)
			if val[3] do setIniSetting thePresetFile "Settings" "percentRenderer" (Krakatoa_CurrentPRTLoader.percentRenderer as string)
			if val[4] do setIniSetting thePresetFile "Settings" "useRenderLimit" (Krakatoa_CurrentPRTLoader.useRenderLimit as string)
			if val[5] do setIniSetting thePresetFile "Settings" "renderLimit" (Krakatoa_CurrentPRTLoader.renderLimit as string)
			if val[6] do setIniSetting thePresetFile "Settings" "particleColorSource" (Krakatoa_CurrentPRTLoader.particleColorSource as string)
			if val[7] do setIniSetting thePresetFile "Settings" "resetDensities" (Krakatoa_CurrentPRTLoader.resetDensities as string)
			
			if val[8] do setIniSetting thePresetFile "Settings" "copyDensitiesToMapChannel" (Krakatoa_CurrentPRTLoader.copyDensitiesToMapChannel as string)
			if val[9] do setIniSetting thePresetFile "Settings" "densityMapChannel" (Krakatoa_CurrentPRTLoader.densityMapChannel as string)

			
				
			if val[10] do setIniSetting thePresetFile "Settings" "viewLoadMode" (Krakatoa_CurrentPRTLoader.viewLoadMode as string)
			if val[11] do setIniSetting thePresetFile "Settings" "enabledInView" (Krakatoa_CurrentPRTLoader.enabledInView as string)
			if val[12] do setIniSetting thePresetFile "Settings" "percentViewport" (Krakatoa_CurrentPRTLoader.percentViewport as string)
			if val[13] do setIniSetting thePresetFile "Settings" "useViewportLimit" (Krakatoa_CurrentPRTLoader.useViewportLimit as string)
			if val[14] do setIniSetting thePresetFile "Settings" "viewportLimit" (Krakatoa_CurrentPRTLoader.viewportLimit as string)
			if val[15] do setIniSetting thePresetFile "Settings" "viewportParticleColorSource" (Krakatoa_CurrentPRTLoader.viewportParticleColorSource as string)
			if val[16] do setIniSetting thePresetFile "Settings" "viewportParticleDisplayMode" (Krakatoa_CurrentPRTLoader.viewportParticleDisplayMode as string)

			if val[17] do setIniSetting thePresetFile "Settings" "scaleNormals" (Krakatoa_CurrentPRTLoader.scaleNormals as string)

			if val[18] do setIniSetting thePresetFile "Settings" "getCullingSurfaceNormals" (Krakatoa_CurrentPRTLoader.getCullingSurfaceNormals as string)
			if val[19] do setIniSetting thePresetFile "Settings" "useThresholdCulling" (Krakatoa_CurrentPRTLoader.useThresholdCulling as string)
			if val[20] do setIniSetting thePresetFile "Settings" "cullingThreshold" (Krakatoa_CurrentPRTLoader.cullingThreshold as string)

			if val[21] do setIniSetting thePresetFile "Settings" "limitToRange" (Krakatoa_CurrentPRTLoader.limitToRange as string)
			if val[22] do setIniSetting thePresetFile "Settings" "loadSingleFrame" (Krakatoa_CurrentPRTLoader.loadSingleFrame as string)
			if val[23] do setIniSetting thePresetFile "Settings" "frameOffset" (Krakatoa_CurrentPRTLoader.frameOffset as string)
			if val[24] do setIniSetting thePresetFile "Settings" "enablePlaybackGraph" (Krakatoa_CurrentPRTLoader.enablePlaybackGraph as string)
			if val[25] do setIniSetting thePresetFile "Settings" "useTransform" (Krakatoa_CurrentPRTLoader.useTransform as string)
			
			if val[26] do setIniSetting thePresetFile "Settings" "showBoundingBox" (Krakatoa_CurrentPRTLoader.showBoundingBox as string)
			if val[27] do setIniSetting thePresetFile "Settings" "showIcon" (Krakatoa_CurrentPRTLoader.showIcon as string)
			if val[28] do setIniSetting thePresetFile "Settings" "iconSize" (Krakatoa_CurrentPRTLoader.iconSize as string)
			if val[29] do setIniSetting thePresetFile "Settings" "showCountInViewport" (Krakatoa_CurrentPRTLoader.showCountInViewport as string)
			if val[30] do setIniSetting thePresetFile "Settings" "graphMode" (Krakatoa_CurrentPRTLoader.graphMode as string)
				
			populatePresetsList()
		)	
	)
	
	fn loadSettingFromPresetFile thePresetFile theName theProperty =
	(
		theVal = execute (getIniSetting thePresetFile "Settings" theName )
		if theVal != OK do 
		(
			try(setProperty Krakatoa_CurrentPRTLoader theProperty theVal)catch()
		)
	)
	
	fn loadPreset thePresetFile =
	(
		loadSettingFromPresetFile thePresetFile "renderLoadMode" #renderLoadMode --1
		loadSettingFromPresetFile thePresetFile "enabledInRender" #enabledInRender  --2
		loadSettingFromPresetFile thePresetFile "percentRenderer" #percentRenderer --3
		loadSettingFromPresetFile thePresetFile "useRenderLimit" #useRenderLimit --4
		loadSettingFromPresetFile thePresetFile "RenderLimit" #RenderLimit --5
		loadSettingFromPresetFile thePresetFile "particleColorSource" #particleColorSource --6
		loadSettingFromPresetFile thePresetFile "resetDensities" #resetDensities--7
		loadSettingFromPresetFile thePresetFile "copyDensitiesToMapChannel" #copyDensitiesToMapChannel --8
		loadSettingFromPresetFile thePresetFile "densityMapChannel" #densityMapChannel --9
		
		loadSettingFromPresetFile thePresetFile "viewLoadMode" #viewLoadMode  --10
		loadSettingFromPresetFile thePresetFile "enabledInView" #enabledInView  --11
		loadSettingFromPresetFile thePresetFile "percentViewport" #percentViewport --12
		loadSettingFromPresetFile thePresetFile "useViewportLimit" #useViewportLimit --13
		loadSettingFromPresetFile thePresetFile "ViewportLimit" #ViewportLimit --14
		loadSettingFromPresetFile thePresetFile "ViewportParticleColorSource" #ViewportParticleColorSource --15
		loadSettingFromPresetFile thePresetFile "ViewportParticleDisplayMode" #ViewportParticleDisplayMode --16
		
		loadSettingFromPresetFile thePresetFile "scaleNormals" #scaleNormals --17
		loadSettingFromPresetFile thePresetFile "getCullingSurfaceNormals" #getCullingSurfaceNormals --18
		loadSettingFromPresetFile thePresetFile "useThresholdCulling" #useThresholdCulling --19
		loadSettingFromPresetFile thePresetFile "cullingThreshold" #cullingThreshold --20
		
		loadSettingFromPresetFile thePresetFile "limitToRange" #limitToRange --21
		loadSettingFromPresetFile thePresetFile "loadSingleFrame" #loadSingleFrame --22
		loadSettingFromPresetFile thePresetFile "frameOffset" #frameOffset --23
		loadSettingFromPresetFile thePresetFile "enablePlaybackGraph" #enablePlaybackGraph --24
		loadSettingFromPresetFile thePresetFile "useTransform" #useTransform --25

		loadSettingFromPresetFile thePresetFile "showBoundingBox" #showBoundingBox --26
		loadSettingFromPresetFile thePresetFile "showIcon" #showIcon --27
		loadSettingFromPresetFile thePresetFile "iconSize" #iconSize --28
		loadSettingFromPresetFile thePresetFile "showCountInViewport" #showCountInViewport --29
		 
		theVal = execute (getIniSetting thePresetFile "Settings" "graphMode" ) --30
		if theVal != OK do 
			try
			(
				graphMode = theVal 
				Krakatoa_CurrentPRTLoader.countdisplay.ddl_graphMode.selection = Krakatoa_CurrentPRTLoader.graphMode
				if Krakatoa_CurrentPRTLoader.autoUpdateGraph do Krakatoa_CurrentPRTLoader.countdisplay.updateGraph()
			)catch()
			
		Krakatoa_CurrentPRTLoader.params.UpdateGUI()
	)	
	
	on ddl_presets selected itm do
	(
		if itm > 1 do
		(
			thePresetFile = (GetDir #plugcfg + "\\Krakatoa\\presets\\" + ddl_presets.selected + ".KPS")
			if doesFileExist thePresetFile do
			(
				loadPreset thePresetFile
			)	
		)	
		ddl_presets.selection = itm
		customPresetName = ddl_presets.selected			
	)
	on presets_rollout open do 
	(
		populatePresetsList()
		isCreating = false
	)	 
	on Krakatoa_PRTLoader_Presets_Rollout rolledUp val do
	(
		Krakatoa_PRTLoader_FileEditor.updateSubRollouts()
	)	
)

rollout Krakatoa_PRTLoader_Timing_Rollout "Timing"
(
	checkbox chk_loadSingleFrame "Load Single Frame Only" offset:[0,-3]

	checkbox chk_enablePlaybackGraph "" offset:[0,-3] across:2
	spinner spn_playbackGraphTime "Use Graph [a]:" range:[-10000000,10000000,0] fieldwidth:42 offset:[4,-3] type:#float enabled:false

	spinner spn_frameOffset "Frame Offset:" range:[-10000000,10000000,0] fieldwidth:42 offset:[4,-3] type:#integer

	checkbox chk_limitToRange "Limit To Custom Range:" offset:[0,-3]
	button btn_getCurrentSafeRange "Range" width:40 height:18 align:#left offset:[-3,-4] across:3 tooltip:"Check availability of frames and set the Custom Range to the intersection of all good intervals." 
	spinner spn_rangeStartFrame "" range:[-10000000,1000000,0] fieldwidth:35 offset:[-8,-3] type:#integer across:2 align:#left 
	spinner spn_rangeEndFrame "-" range:[-10000000,10000000,0] fieldwidth:42 offset:[5,-3] type:#integer align:#right
	--button btn_getCurrentSafeRange "Set Using Existing Frames" width:148 align:#center offset:[0,-3] tooltip:"Check availability of frames and set the Custom Range to the intersection of all good intervals."
	dropdownlist ddl_beforeRangeBehavior items:#("Hold First","Blank") across:2 width:72 offset:[-3,0]
	dropdownlist ddl_afterRangeBehavior items:#("Hold Last","Blank") width:72 offset:[3,0]
	
	
		fn UpdateGUI =
		(
			--updateVRFlags()
			chk_enablePlaybackGraph.enabled = spn_frameOffset.enabled = not chk_loadSingleFrame.checked
			spn_playbackGraphTime.enabled = chk_enablePlaybackGraph.checked and not chk_loadSingleFrame.checked
			spn_rangeStartFrame.enabled = spn_rangeEndFrame.enabled = Krakatoa_CurrentPRTLoader.limitToRange
			--countdisplay.updateInfo()
			--updateVRCheckboxes()
			--try(Krakatoa_PRTLoader_FileEditor.update())catch()
		)	

		fn getBaseFrame theName =
		(	
			theName = getFileNameFile theName
			txt = ""
			for i = theName.count to 1 by -1 do
			(
				if try(classof (execute (substring theName i -1)) == Integer)catch(false) then
					txt = theName[i] + txt
				else
					exit	
			)
			if txt.count > 0 then txt else false
		)
		
		
		fn getValidRange =
		(
			local st = timestamp()
			local theRangesArray = #()
			for aFile in Krakatoa_CurrentPRTLoader.fileList do
			(
				local theBaseFrame = getBaseFrame aFile
				if theBaseFrame != false then
				(
					thePattern = getFileNamePath aFile + substring (getFileNameFile aFile) 1 ((getFileNameFile aFile).count-theBaseFrame.count ) + "*"+ getFileNameType aFile
					theFiles = sort (getFiles thePattern)
					theFiles = for i in theFiles where abs(i.count-aFile.count) < 2 collect i
					allNumbers = #()
					for i in theFiles do
					(
						theDigits = getBaseFrame i
						if theDigits != false do append allNumbers (execute theDigits)
					)
					sort allNumbers 
					if allNumbers.count > 0 then
						append theRangesArray #(allNumbers[1], allNumbers[allNumbers.count])
					else	
					(
						messagebox ("Cannot determine a safe range. The Sequence\n"+ aFile +"\nappers to be completely empty or missing.") title:"Krakatoa Range"
						return false
					)
				)
				else
				(
					messagebox ("Cannot determine a safe range. The Sequence\n"+ aFile +"\ndoes not have a frame number.\nIt will render correctly only in 'Load Single Frame Only' mode which is currently "+ (if loadSingleFrame then "ON" else "OFF")) title:"Krakatoa Range"
					return false			
				)
			)	
			if theRangesArray.count > 0 do
			(
				Krakatoa_CurrentPRTLoader.rangeStartFrame = amax (for i in theRangesArray collect i[1])
				Krakatoa_CurrentPRTLoader.rangeEndFrame = amin (for i in theRangesArray collect i[2])					
			)	
			pushprompt ("Safe Range Set in " + (timestamp()-st) as string + "ms.")
		)
		
		
		on btn_getCurrentSafeRange pressed do getValidRange()
		
		on chk_limitToRange changed state do UpdateGUI ()

		on chk_enablePlaybackGraph changed state do 
		(
			spn_playbackGraphTime.enabled = state
			--countdisplay.updateInfo()
		)	
		on chk_loadSingleFrame changed state do 
		(
			chk_enablePlaybackGraph.enabled = spn_frameOffset.enabled  = not state
			spn_playbackGraphTime.enabled = Krakatoa_CurrentPRTLoader.enablePlaybackGraph AND not state
			--countdisplay.updateInfo()
		)
		
		--on spn_playbackGraphTime changed val do countdisplay.updateInfo()
		
		on params open do
		(
			UpdateGUI()
		)	
	
	on Krakatoa_PRTLoader_Timing_Rollout rolledUp val do
	(
		Krakatoa_PRTLoader_FileEditor.updateSubRollouts()
	)	
)


rollout Krakatoa_PRTLoader_Rendering_Rollout "Rendering"
(
	progressbar prg_renderLoadMode color:(color 255 200 100) width:11 height:21 align:#left across:2 offset:[-8,-3] value:100
	dropdownlist ddl_renderLoadMode items:#("Load Every Nth Particle","Load First N Particles") width:145 align:#right offset:[11,-3]
	checkbox chk_enabledInRender  align:#left across:3 offset:[-8,-3]
	button btn_percentRenderer "Percent [a]" height:16 width:67 offset:[-16,-3]
	spinner spn_percentRenderer range:[0,100,100] fieldwidth:50 offset:[10,-3]
	
	checkbox chk_useRenderLimit across:3 align:#left offset:[-8,-3]
	button btn_RenderLimit "Limit (x1000)" height:16 width:67 offset:[-13,-3]
	spinner spn_RenderLimit range:[0,100000,1000] fieldwidth:50 type:#float offset:[10,-3]
	
	dropdownlist ddl_particleColorSource items:#("Saved Particle Colors","Loader's Wireframe Color","Loader's Material Color") width:156 align:#center offset:[1,-3]
	checkbox chk_copyDensitiesToMapChannel "Density->Mapping #" offset:[-8,-3] across:2
	spinner spn_DensityMapChannel range:[0,99,42] fieldwidth:25 type:#integer offset:[9,-3]
	checkbox chk_resetDensities "Assume Density of 1.0" offset:[-8,-3]
	
	fn createPresetsRCMenu type:#renderpercent =
	(
		local Krakatoa_PresetsDirectory = GetDir #plugcfg + "\\Krakatoa"
		makedir Krakatoa_PresetsDirectory all:true
		case type of
		(
			#renderpercent : (
						presetName = "RenderPercentPresets"
						theParameter = "percentRenderer"
					)	
			#viewpercent : (
						presetName = "ViewPercentPresets"
						theParameter = "percentViewport"
					)	
			#renderlimit: (
						presetName = "RenderLimitPresets"
						theParameter = "RenderLimit"
					)						
			#viewlimit: (
						presetName = "ViewLimitPresets"
						theParameter = "ViewportLimit"
					)	
		)
		local presetsList = #()
		local theKeys = for i in (getIniSetting (Krakatoa_PresetsDirectory + "//KrakatoaPreferences.ini") presetName  ) collect (execute i)
		sort theKeys 
		if theKeys.count == 0 then 
		(
			theKeys = case type of
			(
				#renderpercent : #(1.0,10.0,25.0,33.0,50.0,75.0,100.0)
				#viewpercent : #(1.0,10.0,50.0,100.0)
				#renderlimit: #(1000.0,10000.0,100000.0)
				#viewlimit: #(1.0,10.0,100.0,1000.0)
			)
			for i in theKeys do
				setIniSetting (Krakatoa_PresetsDirectory + "//KrakatoaPreferences.ini") presetName (i as string) (i as string)
		)
		for k in theKeys do
			if findItem presetsList theValue == 0 do append presetsList k

		theValue = execute ("selection[1]." + theParameter)
		global Krakatoa_Presets_RCMenu
		local txt = "rcmenu Krakatoa_Presets_RCMenu\n(\n"
		
		if findItem presetsList theValue == 0 do 
		(
			txt += "menuItem mnu_AddPreset \"Add "+ theValue as string+"\"\n" 
			txt += "on mnu_AddPreset picked do setIniSetting (Krakatoa_PresetsDirectory + \"//KrakatoaPreferences.ini\") \""+ presetName + "\" \""+ theValue as string +"\" \""+ theValue as string +"\" \n"
			txt += "separator spr_01\n" 
		)	
		
		cnt = 0
		for i in presetsList do
		(
			cnt += 1
			txt += "menuItem mnu_preset"+ cnt as string +" \"" + i as string + "\" \n" 
			txt += "on mnu_preset" + cnt as string + " picked do Krakatoa_CurrentPRTLoader."+ theParameter +" = "+ i as string +"\n"
		)
		
		if findItem presetsList theValue != 0 do 
		(
			txt += "separator spr_01\n" 
			txt += "menuItem mnu_RemovePreset \"Remove "+ theValue as string+"\"\n" 
			txt += "on mnu_RemovePreset picked do delIniSetting (Krakatoa_PresetsDirectory + \"//KrakatoaPreferences.ini\") \""+ presetName +"\" \""+ theValue as string +"\" \n"
		)	
		txt += ")\n"
		execute txt
	)		
	
	on btn_percentRenderer pressed do
	(
		createPresetsRCMenu type:#renderpercent 
		popUpMenu Krakatoa_Presets_RCMenu position:mouse.screenPos
	)	
	on btn_RenderLimit pressed do
	(
		createPresetsRCMenu type:#renderlimit
		popUpMenu Krakatoa_Presets_RCMenu position:mouse.screenPos
	)

	fn UpdateGUI =
	(
		chk_resetDensities.enabled = not Krakatoa_CurrentPRTLoader.copyDensitiesToMapChannel
		prg_renderLoadMode.color = case Krakatoa_CurrentPRTLoader.renderLoadMode of
		(
			1: (color 255 200 100)
			2: green
			3: blue
			4: yellow
			default: black
		)
	)

	--on chk_enabledInRender changed state do countdisplay.updateInfo() 
	--on spn_percentRenderer changed val do countdisplay.updateInfo()
	--on spn_RenderLimit changed val do countdisplay.updateInfo()

	on ddl_renderLoadMode selected itm do 
	(
		UpdateGUI()
		if viewLoadMode == 1 do invalidate() 
	)	

	on chk_copyDensitiesToMapChannel changed state do 
	(
		Krakatoa_CurrentPRTLoader.resetDensities = Krakatoa_CurrentPRTLoader.copyDensitiesToMapChannel
		UpdateGUI()
	)	
	
	on renderingRollout open do
	(
		UpdateGUI()
	)	
	
	on Krakatoa_PRTLoader_Rendering_Rollout rolledUp val do
	(
		--Krakatoa_PRTLoader_FileEditor.theRollouts[3][2] = not  val
		Krakatoa_PRTLoader_FileEditor.updateSubRollouts()
	)			
)	

rollout Krakatoa_PRTLoader_Viewport_Rollout "Viewport"	
(
	progressbar prg_viewLoadMode color:(color 255 255 255) width:11 height:21 align:#left across:2 offset:[-8,-3] value:100
	dropdownlist ddl_viewLoadMode items:#("Load Using Render Mode","Load Every Nth Particle","Load First N Particles") width:145 align:#right offset:[11,-3]
	checkbox chk_enabledInView across:3 align:#left  offset:[-8,-3]
	button btn_percentViewport "% of Render" height:16 width:67 offset:[-13,-3]			
	spinner spn_percentViewport range:[0,100,1] fieldwidth:50 offset:[10,-3] 
	checkbox chk_useViewportLimit  across:3 align:#left offset:[-8,-3]
	button btn_ViewportLimit "Limit (x1000)" height:16 width:67 offset:[-13,-3]
	spinner spn_ViewportLimit range:[0,100000,100] fieldwidth:50 type:#float offset:[10,-3]
	dropdownlist ddl_ViewportParticleColorSource items:#("Colors Using Render Mode","Saved Particle Colors","Loader's Wireframe Color","Loader's Material Color") width:156 align:#center offset:[1,-3] --,"Density Channel As Color"
	dropdownlist ddl_ViewportParticleDisplayMode items:#("Display As Small Dots","Display As Large Dots","Display Velocities","Display Normals","Display Tangents") width:156 align:#center offset:[1,-3]
	spinner spn_scaleNormals "Scale Normals:" range:[0,10000000,10] fieldwidth:50 type:#float offset:[8,-3]
	checkbox chk_showBoundingBox "Display Bounding Box" offset:[-8,-4]
	checkbox chk_showIcon "Icon" across:2 offset:[-8,-4]
	spinner spn_iconSize "Size [a]:" range:[0,10000000,10] fieldwidth:50 type:#worldunits offset:[8,-3]
	button btn_updateDisplay "UPDATE VIEW CACHE" width:156 align:#center offset:[0,-3]
	
	on Krakatoa_PRTLoader_Viewport_Rollout rolledUp val do
	(
		Krakatoa_PRTLoader_FileEditor.updateSubRollouts()
	)		
)

rollout Krakatoa_PRTLoader_Culling_Rollout "Culling and Deformations"	
(
	fn filterGizmos obj = findItem GeometryClass.classes (classof obj) > 0 and findItem #(TargetObject, PF_Source, KrakatoaPrtLoader) (classof obj) == 0 

	group "Particle Culling [a]"	
	(
		checkbox chk_useCullingGizmo "On:" enabled:true offset:[-5,-3] across:2 align:#left 
		checkbox chk_invertCullingGizmo "Invert-Cull Inside" enabled:true offset:[5,-3] align:#right
		dropdownlist ddl_cullingNamedSelectionSets items:#() width:148 align:#center offset:[0,-3]
		pickbutton pck_createNSS "Pick Culling Volume..." width:150 align:#center offset:[0,-3] filter:filterGizmos

		checkbox chk_useThresholdCulling "Culling Dist.:" align:#left across:2 offset:[-5,-3]
		spinner spn_cullingThreshold range:[0,10000,100] fieldwidth:50 offset:[6,-3] type:#worldunits

		checkbox chk_getCullingSurfaceNormals "Normals From Surface" offset:[-5,-4] align:#left 
--			checkbox chk_useThresholdNormals "Normals Dist.:" align:#left across:2 offset:[-5,-3]
--			spinner spn_normalsThreshold range:[0,10000,100] fieldwidth:50 offset:[6,-3] type:#worldunits
	)	

	group "Modifier Gizmo Size:"
	(
		button btn_getXFromObject "Get" across:2 align:#left offset:[-7,-5] height:18 width:30
		spinner spn_gizmoBoxX "Width [a]:" range:[0,10000000,10] type:#worldunits fieldwidth:55 offset:[5,-4]
		button btn_getYFromObject "Get" across:2 align:#left offset:[-7,-5] height:18 width:30
		spinner spn_gizmoBoxY "Length [a]:" range:[0,10000000,10] type:#worldunits fieldwidth:55 offset:[5,-4]
		button btn_getZFromObject "Get" across:2 align:#left offset:[-7,-5] height:18 width:30
		spinner spn_gizmoBoxZ "Height [a]:" range:[0,10000000,10] type:#worldunits fieldwidth:55 offset:[5,-4]
		button btn_getBBoxFromObject  "Get All From Object" width:150 align:#center offset:[0,-4]
	)
	
	on Krakatoa_PRTLoader_Culling_Rollout rolledUp val do
	(
		Krakatoa_PRTLoader_FileEditor.updateSubRollouts()
	)			
)

rollout Krakatoa_PRTLoader_Counts_Rollout  "Particle Counts"
(
	bitmap bmp_stateIndicator height:18 width:53 align:#left across:2 offset:[-7,-3] --bitmap:noFilesBitmap
	button btn_infoUpdate "Update Info" width:95 height:18 align:#right offset:[7,-3]

--	checkbutton chk_infoHeader01 ">Disk: " align:#left across:2 width:53 height:18 offset:[-7,-3]
	button btn_infoHeader01 " Disk: " align:#left across:2 width:53 height:18 offset:[-7,-3] enabled:false
	edittext edt_info01 "" align:#right fieldwidth:95 offset:[7,-2]
	
--		checkbutton chk_infoHeader02 ">Render: " align:#left across:2 width:53 height:18 offset:[-7,-3]
	button btn_infoHeader02 " Render: " align:#left across:2 width:53 height:18 offset:[-7,-3] enabled:false
	edittext edt_info02 "" align:#right fieldwidth:95 offset:[7,-2]
	
	checkbutton chk_infoHeader03 ">View: " align:#left across:2 width:53 height:18 offset:[-7,-3]
	edittext edt_info03 "" align:#right fieldwidth:95 offset:[7,-2]


	dropdownlist ddl_graphMode items:#("File Availability Graph","Particle Count Graph") width:154 align:#center
	bitmap bmp_graph height:82 width:154 offset:[0,-5] align:#center
	progressbar prg_graphprogress width:154 align:#center offset:[0,-7] height:6 color:blue
	checkbutton chk_autoUpdateGraph ">Auto" align:#left across:2 width:53 height:18 offset:[-3,-3]
	button btn_graphUpdate "Update Graph" width:85 height:18 align:#right offset:[0,-3]
	button btn_disableMissingSequences "Don't Render Missing Files" align:#center width:143 offset:[-2,-3]
	
	on Krakatoa_PRTLoader_Counts_Rollout rolledUp val do
	(
		Krakatoa_PRTLoader_FileEditor.updateSubRollouts()
	)		
)		
	
rcmenu Krakatoa_PRTLoader_FileEditor_MainMenu 
(
	submenu "File"
	(
		menuItem loadFiles "Load File List..."
		menuItem saveFiles "Save File List..."
		menuItem saveSelectedFiles "Save Selected Files..."
		separator file_separator01
		menuItem addFiles "Add Files..."
		separator file_separator5
		menuItem repathFiles "Repath Selected Files..."
		separator file_separator10
		menuItem removeFiles "Remove Selected..."
		menuItem removeAll "Remove All..."
		separator file_separator20
		menuItem closeDialog "Close"
	)
	submenu "Edit"
	(
		menuItem selectAll "Select All"
		menuItem selectInvert "Select Invert"
		separator edit_separator01
		menuItem cutFiles "Cut Selected"
		menuItem copyFiles "Copy Selected"
		menuItem pasteFiles "Paste" --enabled:(doesFileExist (getDir #plugcfg + "\\krakatoa\\FileSequences\\_Clipboard.txt")) --(Krakatoa_PRTLoader_FileEditor_CutCopyPasteBuffer.count > 0)
	)
	submenu "Reorder"	
	(
		menuItem moveTop "Move To Top"
		menuItem moveUp  "Move Up"
		menuItem moveDown  "Move Down"
		menuItem moveBottom "Move To Bottom"
		separator edit_separator02
		menuItem sortList "Sort File List"
	)	
	submenu "Toggle"
	(
		menuItem toggleSelInView "Toggle Selected In View"
		menuItem toggleAllInView "Toggle All In View"
		separator toggle_separator01
		menuItem toggleSelInRender "Toggle Selected In Render"
		menuItem toggleAllInRender "Toggle All In Render"
		separator toggle_separator05
		menuItem enableSelInView "Enable Selected In View"
		menuItem disableSelInView "Disable Selected In View"
		menuItem enableAllInView "Enable All In View"
		menuItem disableAllInView "Disable All In View"
		separator toggle_separator10
		menuItem enableSelInRender "Enable Selected In Render"
		menuItem disableSelInRender "Disable Selected In Render"
		menuItem enableAllInRender "Enable All In Render"
		menuItem disableAllInRender "Disable All In Render"
		separator toggle_separator20
		menuItem soloSelInView "Solo Selected In View"
		menuItem soloSelInRender "Solo Selected In Render"
	)
	
	on saveFiles picked do Krakatoa_PRTLoader_FileEditor.saveFiles selectedOnly:false
	on saveSelectedFiles picked do Krakatoa_PRTLoader_FileEditor.saveFiles selectedOnly:true
	on loadFiles picked do Krakatoa_PRTLoader_FileEditor.loadFiles()
	
	on addFiles picked do Krakatoa_PRTLoader_FileEditor.addFiles()
	on repathFiles picked do Krakatoa_PRTLoader_FileEditor.repathFiles()
	
	on selectAll picked do Krakatoa_PRTLoader_FileEditor.selectAll()
	on selectInvert picked do Krakatoa_PRTLoader_FileEditor.selectInvert()
	
	on moveTop picked do Krakatoa_PRTLoader_FileEditor.moveBlock #top
	on moveBottom picked do Krakatoa_PRTLoader_FileEditor.moveBlock #bottom
	on moveUp picked do Krakatoa_PRTLoader_FileEditor.moveBlock #up
	on moveDown picked do Krakatoa_PRTLoader_FileEditor.moveBlock #down
	on sortList picked do Krakatoa_PRTLoader_FileEditor.sortSequences()
	
	on cutFiles picked do Krakatoa_PRTLoader_FileEditor.cutSequences()
	on copyFiles picked do Krakatoa_PRTLoader_FileEditor.copySequences()
	on pasteFiles picked do Krakatoa_PRTLoader_FileEditor.pasteSequences()
	
	on removeFiles picked do Krakatoa_PRTLoader_FileEditor.removeFiles selectedOnly:true
	on removeAll picked do Krakatoa_PRTLoader_FileEditor.removeFiles selectedOnly:false

	on closeDialog picked do try(destroyDialog Krakatoa_PRTLoader_FileEditor)catch()

	on toggleSelInView picked do Krakatoa_PRTLoader_FileEditor.ToggleVRIn #View true selectedOnly:true invert:true
	on toggleAllInView picked do Krakatoa_PRTLoader_FileEditor.ToggleVRIn #View true selectedOnly:false invert:true
	on toggleSelInRender picked do Krakatoa_PRTLoader_FileEditor.ToggleVRIn #Render true selectedOnly:true invert:true
	on toggleAllInRender picked do Krakatoa_PRTLoader_FileEditor.ToggleVRIn #Render true selectedOnly:false invert:true
	
	on enableSelInView picked do Krakatoa_PRTLoader_FileEditor.ToggleVRIn #View true selectedOnly:true
	on disableSelInView picked do Krakatoa_PRTLoader_FileEditor.ToggleVRIn #View false selectedOnly:true
	on enableAllInView picked do Krakatoa_PRTLoader_FileEditor.ToggleVRIn #View true selectedOnly:false
	on disableAllInView picked do Krakatoa_PRTLoader_FileEditor.ToggleVRIn #View false selectedOnly:false

	on enableSelInRender picked do Krakatoa_PRTLoader_FileEditor.ToggleVRIn #Render true selectedOnly:true
	on disableSelInRender picked do Krakatoa_PRTLoader_FileEditor.ToggleVRIn #Render false selectedOnly:true
	on enableAllInRender picked do Krakatoa_PRTLoader_FileEditor.ToggleVRIn #Render true selectedOnly:false
	on disableAllInRender picked do Krakatoa_PRTLoader_FileEditor.ToggleVRIn #Render false selectedOnly:false

	on soloSelInView picked do 
	(
		Krakatoa_PRTLoader_FileEditor.ToggleVRIn #View false selectedOnly:false
		Krakatoa_PRTLoader_FileEditor.ToggleVRIn #View true selectedOnly:true
	)	
	on soloSelInRender picked do 
	(
		Krakatoa_PRTLoader_FileEditor.ToggleVRIn #Render false selectedOnly:false
		Krakatoa_PRTLoader_FileEditor.ToggleVRIn #Render true selectedOnly:true
	)		
)

rcmenu Krakatoa_PRTLoader_FileEditor_RcMenu 
(
	subMenu "File List Loading And Saving"
	(
		menuItem loadFiles "Load File List..."
		menuItem saveFiles "Save File List..."
		menuItem saveSelectedFiles "Save Selected Files..."	
	)	
	separator file_separator01
	menuItem addFiles "Add Files..."
	separator file_separator5
	menuItem repathFiles "Repath Selected Files..."
	separator file_separator10
	menuItem selectAll "Select All"
	menuItem selectInvert "Select Invert"
	separator file_separator20
	menuItem cutFiles "Cut Selected"
	menuItem copyFiles "Copy Selected"
	menuItem pasteFiles "Paste" --enabled:(Krakatoa_PRTLoader_FileEditor_CutCopyPasteBuffer.count > 0)
	
	separator edit_separator10
	subMenu "Reorder List"
	(
		menuItem moveTop "Move To Top"
		menuItem moveUp  "Move Up"
		menuItem moveDown  "Move Down"
		menuItem moveBottom "Move To Bottom"
		separator edit_separator20
		menuItem sortList "Sort File List"
	)	
	separator edit_separator30
	subMenu "Toggle"
	(
		menuItem toggleSelInView "Toggle Selected In View"
		menuItem toggleAllInView "Toggle All In View"
		separator toggle_separator01
		menuItem toggleSelInRender "Toggle Selected In Render"
		menuItem toggleAllInRender "Toggle All In Render"
		separator toggle_separator05
		menuItem enableSelInView "Enable Selected In View"
		menuItem disableSelInView "Disable Selected In View"
		menuItem enableAllInView "Enable All In View"
		menuItem disableAllInView "Disable All In View"
		separator toggle_separator10
		menuItem enableSelInRender "Enable Selected In Render"
		menuItem disableSelInRender "Disable Selected In Render"
		menuItem enableAllInRender "Enable All In Render"
		menuItem disableAllInRender "Disable All In Render"
		separator toggle_separator20
		menuItem soloSelInView "Solo Selected In View"
		menuItem soloSelInRender "Solo Selected In Render"
	)
	separator edit_separator40
	subMenu "Remove"
	(
		menuItem removeFiles "Remove Selected..."
		menuItem removeAll "Remove All..."	
	)	


	on saveFiles picked do Krakatoa_PRTLoader_FileEditor.saveFiles selectedOnly:false
	on saveSelectedFiles picked do Krakatoa_PRTLoader_FileEditor.saveFiles selectedOnly:true
	
	on loadFiles picked do Krakatoa_PRTLoader_FileEditor.loadFiles()
	
	on addFiles picked do Krakatoa_PRTLoader_FileEditor.addFiles()
	on repathFiles picked do Krakatoa_PRTLoader_FileEditor.repathFiles()
	
	on selectAll picked do Krakatoa_PRTLoader_FileEditor.selectAll()
	on selectInvert picked do Krakatoa_PRTLoader_FileEditor.selectInvert()
	
	on moveTop picked do Krakatoa_PRTLoader_FileEditor.moveBlock #top
	on moveBottom picked do Krakatoa_PRTLoader_FileEditor.moveBlock #bottom
	on moveUp picked do Krakatoa_PRTLoader_FileEditor.moveBlock #up
	on moveDown picked do Krakatoa_PRTLoader_FileEditor.moveBlock #down
	on sortList picked do Krakatoa_PRTLoader_FileEditor.sortSequences()
	
	on cutFiles picked do Krakatoa_PRTLoader_FileEditor.cutSequences()
	on copyFiles picked do Krakatoa_PRTLoader_FileEditor.copySequences()
	on pasteFiles picked do Krakatoa_PRTLoader_FileEditor.pasteSequences()
	
	on removeFiles picked do Krakatoa_PRTLoader_FileEditor.removeFiles selectedOnly:true
	on removeAll picked do Krakatoa_PRTLoader_FileEditor.removeFiles selectedOnly:false

	on toggleSelInView picked do Krakatoa_PRTLoader_FileEditor.ToggleVRIn #View true selectedOnly:true invert:true
	on toggleAllInView picked do Krakatoa_PRTLoader_FileEditor.ToggleVRIn #View true selectedOnly:false invert:true
	on toggleSelInRender picked do Krakatoa_PRTLoader_FileEditor.ToggleVRIn #Render true selectedOnly:true invert:true
	on toggleAllInRender picked do Krakatoa_PRTLoader_FileEditor.ToggleVRIn #Render true selectedOnly:false invert:true

	on enableSelInView picked do Krakatoa_PRTLoader_FileEditor.ToggleVRIn #View true selectedOnly:true
	on disableSelInView picked do Krakatoa_PRTLoader_FileEditor.ToggleVRIn #View false selectedOnly:true
	on enableAllInView picked do Krakatoa_PRTLoader_FileEditor.ToggleVRIn #View true selectedOnly:false
	on disableAllInView picked do Krakatoa_PRTLoader_FileEditor.ToggleVRIn #View false selectedOnly:false

	on enableSelInRender picked do Krakatoa_PRTLoader_FileEditor.ToggleVRIn #Render true selectedOnly:true
	on disableSelInRender picked do Krakatoa_PRTLoader_FileEditor.ToggleVRIn #Render false selectedOnly:true
	on enableAllInRender picked do Krakatoa_PRTLoader_FileEditor.ToggleVRIn #Render true selectedOnly:false
	on disableAllInRender picked do Krakatoa_PRTLoader_FileEditor.ToggleVRIn #Render false selectedOnly:false

	on soloSelInView picked do 
	(
		Krakatoa_PRTLoader_FileEditor.ToggleVRIn #View false selectedOnly:false
		Krakatoa_PRTLoader_FileEditor.ToggleVRIn #View true selectedOnly:true
	)	
	on soloSelInRender picked do 
	(
		Krakatoa_PRTLoader_FileEditor.ToggleVRIn #Render false selectedOnly:false
		Krakatoa_PRTLoader_FileEditor.ToggleVRIn #Render true selectedOnly:true
	)	
	
)



rollout Krakatoa_PRTLoader_FileEditor "Krakatoa PRT Loader - File Sequence Manager"
(
	--local currentPRTLoader
	local layout_def = #()
	local layout_dynamic = #()
	
	fn getSelection lv =
	(
		local theSel = #()
		for i in 0 to lv.Items.count-1 do
		(
			li = lv.Items.item[i]
			if li.selected do append theSel (i+1)
		)
		theSel
	)		
	
	fn setSelection lv theSel =
	(
		for i in theSel do
			lv.Items.item[(i-1)].selected = true
		lv.update()		
	)
	
	fn invertSelection lv =
	(
		for i in 0 to lv.Items.count-1 do
			lv.Items.item[i].selected = not lv.Items.item[i].selected
		lv.update()	
	)	
	
	fn initListView lv = 
	(
		lv.backColor = (dotNetClass "System.Drawing.Color").fromARGB 221 221 225
		lv.View = (dotNetClass "System.Windows.Forms.View").Details
		lv.gridLines = true 
		lv.fullRowSelect = true 
		lv.checkboxes = false
		lv.hideSelection = false
		for i in layout_def do lv.Columns.add i[1] i[2]
	)
	
	fn fillInSpreadSheet lv =
	(
		lv.Items.clear()	
		theRange = #() 
		for theFile = 1 to Krakatoa_CurrentPRTLoader.fileList.count do
		(
			local li = dotNetObject "System.Windows.Forms.ListViewItem" (getFileNameFile Krakatoa_CurrentPRTLoader.fileList[theFile])
			local sub_li = li.SubItems.add (getFileNameType Krakatoa_CurrentPRTLoader.fileList[theFile])
			local sub_li = li.SubItems.add (if bit.Get Krakatoa_CurrentPRTLoader.fileListFlags[theFile] 1 then "View" else "--")
			local sub_li = li.SubItems.add (if bit.Get Krakatoa_CurrentPRTLoader.fileListFlags[theFile] 2 then "Rend" else "--")
			
			local sub_li = li.SubItems.add (getFileNamePath Krakatoa_CurrentPRTLoader.fileList[theFile])
			local sub_li = li.SubItems.add (if doesFileExist Krakatoa_CurrentPRTLoader.fileList[theFile] then "Yes" else "No")
			

			local theChannels = (FranticParticles.GetFileParticleChannels Krakatoa_CurrentPRTLoader.fileList[theFile])
			if theChannels == undefined do theChannels = #()
			for i in layout_dynamic do
			(
				local theChannel = for c in theChannels where matchPattern c[1] pattern:i collect c
				if theChannel.count == 1 then
					sub_li = li.SubItems.add (theChannel[1][2]+"["+theChannel[1][3] as string +"]")
				else
					sub_li = li.SubItems.add "--"
			)
			append theRange li
		)
		lv.Items.AddRange theRange 	

	)

	fn getFileDialogSize =
	(
		theSize = execute (getIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "Dialog" "FileManagerSize")
		if classof theSize != Point2 then theSize = [800,500] 
		if theSize.x < 200 do theSize.x = 200
		if theSize.y < 200 do theSize.y = 200
		theSize
	)
--End Part 1	

	local rightPaneWidthLocked = 180

	dotNetControl lv_filesToLoad "System.Windows.Forms.ListView" \
		width:((getFileDialogSize()).x-180) \
		height:((getFileDialogSize()).y-5) \
		align:#left 
	on lv_filesToLoad MouseClick itm do 
		if itm.Button.Equals itm.Button.Right then 
			popupmenu Krakatoa_PRTLoader_FileEditor_RCMenu pos:mouse.screenpos

	checkbutton chk_autoColumns "Auto Columns" height:18 width:80 pos:[(getFileDialogSize()).x-180,0] checked:true
	checkbutton chk_column1 "1" height:18 width:18 pos:[(getFileDialogSize()).x-100,0]
	checkbutton chk_column2 "2" height:18 width:18 pos:[(getFileDialogSize()).x-100+18,0]
	checkbutton chk_column3 "3" height:18 width:18 pos:[(getFileDialogSize()).x-100+18+18,0]
	checkbutton chk_column4 "4" height:18 width:18 pos:[(getFileDialogSize()).x-100+18+18+18,0]
	checkbutton chk_column5 "5" height:18 width:18 pos:[(getFileDialogSize()).x-100+18+18+18+18,0]

		
	subRollout sub_1 width:180 height:390 	pos:[1000,10]
	subRollout sub_2 width:180  height:390  pos:[1000,10]
	subRollout sub_3 width:180  height:390 pos:[1000,10]
	subRollout sub_4 width:180  height:390 pos:[1000,10]
	subRollout sub_5 width:180  height:390 pos:[1000,10]		
		
	local theRollouts = #(
		#(Krakatoa_PRTLoader_Presets_Rollout, true,119),
		#(Krakatoa_PRTLoader_Timing_Rollout, false,121),
		#(Krakatoa_PRTLoader_Rendering_Rollout, false,124),
		#(Krakatoa_PRTLoader_Viewport_Rollout, false,188),
		#(Krakatoa_PRTLoader_Culling_Rollout, true,229),
		#(Krakatoa_PRTLoader_Counts_Rollout, false,249)
	)
	
	local theSubRollouts = #(
		sub_1, sub_2, sub_3, sub_4, sub_5
	)
		

	on Krakatoa_PRTLoader_FileEditor rbuttondown pos do
		popupmenu Krakatoa_PRTLoader_FileEditor_RCMenu pos:mouse.screenpos

	fn refreshColumns =
	(
		--Krakatoa_CurrentPRTLoader.params.btn_editFiles.pressed()
	)
	
	fn stillSelected =
	(
		isValidNode Krakatoa_CurrentPRTLoader and Krakatoa_CurrentPRTLoader.isSelected
	)

	fn moveBlock mode =
	(
		if stillSelected()  then
		(
			if Krakatoa_CurrentPRTLoader.fileList.count > 1 then
			(
				with undo "PRT Move Block" on
				(
					theSel = getSelection lv_filesToLoad
					theTemp = for i in theSel collect Krakatoa_CurrentPRTLoader.fileList[i]
					theTemp2 = for i in theSel collect Krakatoa_CurrentPRTLoader.fileListFlags[i]
					for i = theSel.count to 1 by -1 do 
					(
						deleteItem Krakatoa_CurrentPRTLoader.fileList theSel[i]
						deleteItem Krakatoa_CurrentPRTLoader.fileListFlags theSel[i]
					)	
					case mode of
					(
						#top: 
						(
							theSel = for i = 1 to theTemp.count collect i
							Krakatoa_CurrentPRTLoader.fileList = join theTemp Krakatoa_CurrentPRTLoader.fileList
							Krakatoa_CurrentPRTLoader.fileListFlags = join theTemp2 Krakatoa_CurrentPRTLoader.fileListFlags
						)	
						#bottom: 
						(
							Krakatoa_CurrentPRTLoader.fileList = join (for i in Krakatoa_CurrentPRTLoader.fileList collect i) theTemp 
							Krakatoa_CurrentPRTLoader.fileListFlags = join (for i in Krakatoa_CurrentPRTLoader.fileListFlags collect i) theTemp2 
							theSel = for i = 1 to theTemp.count collect Krakatoa_CurrentPRTLoader.fileList.count-i+1
						)	
						#up: 
						(
							cnt = 0
							theSel = for i in theSel collect (if i > 1 then (i-1) else i)
							for i in theSel do
							(
								cnt += 1
								Krakatoa_CurrentPRTLoader.fileList = insertItem theTemp[cnt] Krakatoa_CurrentPRTLoader.fileList (i)
								Krakatoa_CurrentPRTLoader.fileListFlags = insertItem theTemp2[cnt] Krakatoa_CurrentPRTLoader.fileListFlags (i)
							)	
						)
						#down: 
						(
							cnt = 0
							theSel = for i in theSel collect (if i < Krakatoa_CurrentPRTLoader.fileList.count then (i+1) else i)
							for i in theSel do
							(
								cnt += 1
								Krakatoa_CurrentPRTLoader.fileList = insertItem theTemp[cnt] Krakatoa_CurrentPRTLoader.fileList (i)
								Krakatoa_CurrentPRTLoader.fileListFlags = insertItem theTemp2[cnt] Krakatoa_CurrentPRTLoader.fileListFlags (i)
							)	
						)			
					)
					fillInSpreadSheet lv_filesToLoad
					setSelection lv_filesToLoad theSel
				)	
			)
		)
		else
			try(destroyDialog Krakatoa_PRTLoader_FileEditor)catch()
	)
	
	fn compareFN v1 v2 valArray: =
	(
		local v1i = valArray[v1]
		local v2i = valArray[v2]
		if v1i > v2i then 1 else -1
	)
	
	fn sortSequences =
	(
		if stillSelected() then
		(	
			with undo "PRT Sort" on 
			(
				indexArray = for i = 1 to Krakatoa_CurrentPRTLoader.fileList.count collect i
				qsort indexArray compareFN valArray:Krakatoa_CurrentPRTLoader.fileList
				Krakatoa_CurrentPRTLoader.fileList = for i in indexArray collect Krakatoa_CurrentPRTLoader.fileList[i]
				Krakatoa_CurrentPRTLoader.fileListFlags = for i in indexArray collect Krakatoa_CurrentPRTLoader.fileListFlags[i]
			)
			fillInSpreadSheet lv_filesToLoad
		)	
		else
			try(destroyDialog Krakatoa_PRTLoader_FileEditor)catch()		
	)	
	fn selectInvert = 
	( 
		if stillSelected() then
		(	
			invertSelection lv_filesToLoad 
		)	
		else
			try(destroyDialog Krakatoa_PRTLoader_FileEditor)catch()			
	)
	
	fn selectAll = 
	( 
		if stillSelected() then
		(	
			setSelection lv_filesToLoad (for i = 1 to Krakatoa_CurrentPRTLoader.fileList.count collect i) 
		)
		else
			try(destroyDialog Krakatoa_PRTLoader_FileEditor)catch()	
	)
	


	fn addFiles =
	(
		if stillSelected() then
		(	
			Krakatoa_CurrentPRTLoader.params.btn_addFiles.pressed()
			fillInSpreadSheet lv_filesToLoad
		)	
		else
			try(destroyDialog Krakatoa_PRTLoader_FileEditor)catch()				
	)	
	
	local fullDirectoriesList = #()
	fn recurseDirectories theDirToScan =
	(
		theSubs = getDirectories (theDirToScan + "*")
		for s in theSubs do 
		(
			append fullDirectoriesList s
			recurseDirectories s
		)	
	)	

	fn repathFiles =
	(
		if stillSelected() then
		(		
			theSel = getSelection lv_filesToLoad
			if theSel.count > 0 then
			(
				with undo "PRT Repath" on 
				(
					theNewPath = getSavePath()
					if theNewPath != undefined do
					(
						fullDirectoriesList = #(theNewPath)
						recurseDirectories theNewPath
						for i in theSel do 
						(
							theBaseFile = filenameFromPath Krakatoa_CurrentPRTLoader.fileList[i]
							for d in fullDirectoriesList do
							(
								theNewFile = d + theBaseFile 
								if doesFileExist theNewFile do 
								(
									Krakatoa_CurrentPRTLoader.fileList[i] = theNewFile
									exit
								)
							)	
						)--end i loop
						fillInSpreadSheet lv_filesToLoad
					)--end if path defined
				)--end undo
			)--end if selection > 0
		)--end if node valid	
		else
			try(destroyDialog Krakatoa_PRTLoader_FileEditor)catch()			
	)
	
	fn removeFiles selectedOnly:true =
	(
		if stillSelected() then
		(	
			if selectedOnly then 
				Krakatoa_CurrentPRTLoader.params.lbx_filesToLoad.selection = (getSelection lv_filesToLoad) as bitarray
			else	
				Krakatoa_CurrentPRTLoader.params.lbx_filesToLoad.selection = ((for i = 1 to Krakatoa_CurrentPRTLoader.params.lbx_filesToLoad.items.count collect i) as bitarray)
			Krakatoa_CurrentPRTLoader.params.btn_removeFile.pressed()
			fillInSpreadSheet lv_filesToLoad
		)	
		else
			try(destroyDialog Krakatoa_PRTLoader_FileEditor)catch()				
	)
	
	fn saveFiles selectedOnly:false UserFilename:""=
	(
		if stillSelected() then
		(	
			makeDir (GetDir #plugcfg + "\\Krakatoa\\FileSequences") all:true
			if UserFilename == "" then
				theSaveFile = getSaveFilename caption:"Enter Filename To Save File Sequence To:" filename:(GetDir #plugcfg + "\\Krakatoa\\FileSequences\\" + Krakatoa_CurrentPRTLoader.name ) types:"Krakatoa PRT File List (*.kfl)|*.kfl"
			else	
				theSaveFile = (GetDir #plugcfg + "\\Krakatoa\\FileSequences\\") + UserFilename
			if theSaveFile != undefined do
			(
				theFileToSave = createFile theSaveFile 
				if selectedOnly then
				(
					theSel = getSelection lv_filesToLoad
					for i in theSel do 
						format "%, %\n" Krakatoa_CurrentPRTLoader.fileList[i] Krakatoa_CurrentPRTLoader.fileListFlags[i] to:theFileToSave 
				)
				else
				(
					for i = 1 to Krakatoa_CurrentPRTLoader.fileList.count do 
						format "%, %\n" Krakatoa_CurrentPRTLoader.fileList[i] Krakatoa_CurrentPRTLoader.fileListFlags[i] to:theFileToSave 
				)		
				close theFileToSave 	
			)	
		)	
	)
	
	fn loadFiles userFilename:""=
	(
		if stillSelected() then
		(	
			makeDir (GetDir #plugcfg + "\\Krakatoa\\FileSequences") all:true
			if userFilename == "" then
				theLoadFile = getOpenFilename caption:"Enter Filename To Load File Sequence From:" filename:(GetDir #plugcfg + "\\Krakatoa\\FileSequences\\") types:"Krakatoa PRT File List (*.kfl)|*.kfl"
			else
				theLoadFile = (GetDir #plugcfg + "\\Krakatoa\\FileSequences\\") + userFilename 
			if theLoadFile != undefined and doesFileExist theLoadFile do
			(
				theFileToLoad = openFile theLoadFile 
				local theList = #()
				local theFlags = #()
				theOldList = for i in Krakatoa_CurrentPRTLoader.fileList collect i
				theOldFlagList = for i in Krakatoa_CurrentPRTLoader.fileListFlags collect i
				
				while not eof theFileToLoad do
				(
					thePath = readline theFileToLoad
					if not matchPattern thePath pattern:"*, *" then thePath += ", 3"
					strStream = thePath as stringStream
					local theFilePath = readDelimitedString strStream ","
					local theFileFlag = execute (readLine strStream )
					if doesFileExist theFilePath and findItem theOldList theFilePath == 0 do 
					(
						append theList theFilePath 
						append theFlags theFileFlag 
					)	
				)
				close theFileToLoad
				with undo "PRT Load List" on
				(
					Krakatoa_CurrentPRTLoader.fileList = join theOldList theList 
					Krakatoa_CurrentPRTLoader.fileListFlags = join theOldFlagList theFlags 
				)	
				fillInSpreadSheet lv_filesToLoad
			)	
		)	
	)	
	
	fn cutSequences =
	(
		if stillSelected() then
		(	
			theSel = getSelection lv_filesToLoad
--			Krakatoa_PRTLoader_FileEditor_CutCopyPasteBuffer = for i in theSel collect Krakatoa_CurrentPRTLoader.fileList[i]
			saveFiles selectedOnly:true userFilename:"_Clipboard.txt"
			with undo "PRT Cut Sequence" on
			(
				for i = theSel.count to 1 by -1 do 
				(
					deleteItem Krakatoa_CurrentPRTLoader.fileList theSel[i]
					deleteItem Krakatoa_CurrentPRTLoader.fileListFlags theSel[i]
				)	
			)	
			fillInSpreadSheet lv_filesToLoad
		)	
		else
			try(destroyDialog Krakatoa_PRTLoader_FileEditor)catch()			
	)
	
	fn copySequences =
	(
		if stillSelected() then
		(		
			theSel = getSelection lv_filesToLoad
			--Krakatoa_PRTLoader_FileEditor_CutCopyPasteBuffer = for i in theSel collect Krakatoa_CurrentPRTLoader.fileList[i]
			if theSel.count > 0 then
				saveFiles selectedOnly:true userFilename:"_Clipboard.txt"
		)	
		else
			try(destroyDialog Krakatoa_PRTLoader_FileEditor)catch()			
	)	
	
	fn pasteSequences =
	(
		if stillSelected() then
		(	
			/*
			tempArray = for i in Krakatoa_PRTLoader_FileEditor_CutCopyPasteBuffer where findItem Krakatoa_CurrentPRTLoader.fileList i == 0 collect i
			if tempArray.count > 0 do
			(
				theSel  = getSelection lv_filesToLoad
				theTargetLocation = if theSel.count > 0 then theSel[1]+1 else 1
				fileArray = for i in Krakatoa_CurrentPRTLoader.fileList collect i
				for i = tempArray.count to 1 by -1 do
					insertItem tempArray[i] fileArray theTargetLocation
				theSel = for i = 1 to tempArray.count collect (i+theTargetLocation-1)
				Krakatoa_CurrentPRTLoader.fileList = fileArray 
				fillInSpreadSheet lv_filesToLoad
				setSelection lv_filesToLoad theSel
			)
			*/
			loadFiles userFilename:"_Clipboard.txt"	
		)	
		else
			try(destroyDialog Krakatoa_PRTLoader_FileEditor)catch()		
	)		
	
	
	fn ToggleVRIn VorR OnOff selectedOnly:true invert:false = 
	( 
		if stillSelected() then
		(	
			local oldSel = getSelection lv_filesToLoad
			if selectedOnly then 
				theSel = getSelection lv_filesToLoad
			else
				theSel = #{1..Krakatoa_CurrentPRTLoader.fileListFlags.count}
			theBit = if VorR == #View then 1 else 2
			for i in theSel do
				if invert then
					Krakatoa_CurrentPRTLoader.fileListFlags[i] = bit.set Krakatoa_CurrentPRTLoader.fileListFlags[i] theBit (not (bit.get Krakatoa_CurrentPRTLoader.fileListFlags[i] theBit))
				else
					Krakatoa_CurrentPRTLoader.fileListFlags[i] = bit.set Krakatoa_CurrentPRTLoader.fileListFlags[i] theBit OnOff 
				
			if modPanel.getCurrentObject() == Krakatoa_CurrentPRTLoader.baseobject do 
			(
				select Krakatoa_CurrentPRTLoader
				modPanel.setCurrentObject Krakatoa_CurrentPRTLoader.baseobject
			)	
			fillInSpreadSheet lv_filesToLoad
			setSelection lv_filesToLoad oldSel 
		)	
		else
			try(destroyDialog Krakatoa_PRTLoader_FileEditor)catch()			
	)	

	
	on Krakatoa_PRTLoader_FileEditor resized val do 
	(
		if keyboard.ShiftPressed then --chk_lockLeftPane.state
		(
			newWidth = lv_filesToLoad.width
			rightPaneWidthLocked = val.x-newWidth 
			if val.x < newWidth + 180 do val.x = newWidth + 180
			Krakatoa_PRTLoader_FileEditor.width = val.x
		)
		else		
		(
			local newWidth = val.x-rightPaneWidthLocked
			if newWidth < 50 do newWidth  = 50
		)
		Krakatoa_PRTLoader_FileEditor.width = newWidth+rightPaneWidthLocked
		lv_filesToLoad.pos = [0,0]
		lv_filesToLoad.width = newWidth
		lv_filesToLoad.height = val.y-5 		
		
		chk_autoColumns.pos = [newWidth+rightPaneWidthLocked-180,0]
		chk_column1.pos = [newWidth+rightPaneWidthLocked-100,0]
		chk_column2.pos = [newWidth+rightPaneWidthLocked-100+18,0]
		chk_column3.pos = [newWidth+rightPaneWidthLocked-100+18*2,0]
		chk_column4.pos = [newWidth+rightPaneWidthLocked-100+18*3,0]
		chk_column5.pos = [newWidth+rightPaneWidthLocked-100+18*4,0]
		
		for i = 1 to theSubRollouts.count do
		(
			--theSubRollouts[i].visible = (i-1)*190 < val.x 
			theSubRollouts[i].pos = [newWidth+180*(i-1)+5, 20]
			theSubRollouts[i].height = val.y-20
		)
		
		setIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "Dialog" "FileManagerSize" (val as string)
	)
	
	on Krakatoa_PRTLoader_FileEditor moved val do 
		setIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "Dialog" "FileManagerPosition" (val as string)
	
	fn update =
	(
		if stillSelected() then
		(	
			fillInSpreadSheet lv_filesToLoad
		)	
	)


	local theSubRolloutIndex = 1

	fn updateColumnCount =
	(
		if chk_autoColumns.state do 	rightPaneWidthLocked = 180*theSubRolloutIndex+5
		if chk_column1.state do rightPaneWidthLocked = 180*1+5
		if chk_column2.state do rightPaneWidthLocked = 180*2+5
		if chk_column3.state do rightPaneWidthLocked = 180*3+5
		if chk_column4.state do rightPaneWidthLocked = 180*4+5
		if chk_column5.state do rightPaneWidthLocked = 180*5+5
		totalSize = getFileDialogSize()
		if totalSize.x < 50+rightPaneWidthLocked do totalSize.x = 50+rightPaneWidthLocked 
		print totalSize.x
		Krakatoa_PRTLoader_FileEditor.resized totalSize
	)	
	
	fn getMaxColumns =
	(
		if chk_autoColumns.state do 	return 5
		if chk_column1.state do return 1
		if chk_column2.state do return 2
		if chk_column3.state do return 3
		if chk_column4.state do return 4
		if chk_column5.state do return 5
	)
	
	fn updateSubRollouts init:false= 
	(
		if not init do for i = 1 to theRollouts.count do theRollouts[i][2] = not theRollouts[i][1].open
		for subRoll in theSubRollouts do 
			for i = subRoll.rollouts.count to 1 by -1 do 
				removeSubRollout subRoll subRoll.rollouts[i]			
		theSubRolloutIndex = 1
		local maxColumns = getMaxColumns()
		local currentHeight = 0
		for aRollout in theRollouts do
		(
			if aRollout[2] then currentHeight +=20 else currentHeight +=aRollout[3] 
			if currentHeight > (getFileDialogSize()).y-40 and theSubRolloutIndex < maxColumns do 
			(
				theSubRolloutIndex+=1
				currentHeight = aRollout[3] 
			)	
			addSubRollout theSubRollouts[theSubRolloutIndex] aRollout[1] rolledup:aRollout[2]
		)
		for subRoll in theSubRollouts do subRoll.visible = subRoll.rollouts.count > 0
		updateColumnCount()
	)
	

	
	on chk_autoColumns changed state do
	(
		chk_column2.state = chk_column3.state = chk_column4.state = chk_column5.state = false
		chk_column1.state = not state
		updateSubRollouts()
	)
	on chk_column1 changed state do
	(
		chk_column2.state = chk_column3.state = chk_column4.state = chk_column5.state = false
		chk_autoColumns.state = not state
		updateSubRollouts()
	)
	on chk_column2 changed state do
	(
		chk_column1.state = chk_column3.state = chk_column4.state = chk_column5.state = false
		chk_autoColumns.state = not state
		updateSubRollouts()
	)
	on chk_column3 changed state do
	(
		chk_column1.state = chk_column2.state = chk_column4.state = chk_column5.state = false
		chk_autoColumns.state = not state
		updateSubRollouts()
	)
	on chk_column4 changed state do
	(
		chk_column1.state = chk_column2.state = chk_column3.state = chk_column5.state = false
		chk_autoColumns.state = not state
		updateSubRollouts()
	)
	on chk_column5 changed state do
	(
		chk_column1.state = chk_column2.state = chk_column3.state = chk_column4.state = false
		chk_autoColumns.state = not state
		updateSubRollouts()
	)		
	
	/*
	on chk_lockLeftPane changed state do
	(
		if state then
		(
			leftPaneWidthLocked = lv_filesToLoad.width
		)	
		else
		(
			Krakatoa_PRTLoader_FileEditor.resized (getFileDialogSize())
			updateSubRollouts init:false
		)	
	)			
	*/
	
	fn selectByDClick_Handler =
	(
		if stillSelected() then
		(	
			toSelect = getSelection lv_filesToLoad 
			if toSelect.count > 0 do
				try(shelllaunch "explorer.exe" (getFileNamePath Krakatoa_CurrentPRTLoader.fileList[toSelect[1]]))catch()
		)	
		else
			try(destroyDialog Krakatoa_PRTLoader_FileEditor)catch()			
	)
	on lv_filesToLoad DoubleClick do selectByDClick_Handler()
	
	on Krakatoa_PRTLoader_FileEditor open do
	(
		Krakatoa_CurrentPRTLoaders = for o in selection where classof o == KrakatoaPrtLoader collect o
		if Krakatoa_CurrentPRTLoaders.count > 0 then
		(
			Krakatoa_CurrentPRTLoader = Krakatoa_CurrentPRTLoaders[1]
			Krakatoa_PRTLoader_FileEditor.title = case Krakatoa_CurrentPRTLoaders.count of
			(
			1: ("[" + Krakatoa_CurrentPRTLoader.name +"] - Krakatoa File Sequence Manager ")
			2: ("[" + Krakatoa_CurrentPRTLoader.name +"] + 1 Instance - Krakatoa File Sequence Manager ")
			default: ("[" + Krakatoa_CurrentPRTLoader.name +"] + "+ (Krakatoa_CurrentPRTLoaders.count-1) as string +" Instances - Krakatoa File Sequence Manager ")
			)		
			layout_def = #(#("File Name", 150), #("Type",40), #("View",40), #("Rend",40), #("Full Path",200), #("Found",45))
			layout_dynamic = #()
			for i in Krakatoa_CurrentPRTLoader.fileList where doesFileExist i do
			(
				for j in (FranticParticles.GetFileParticleChannels i) do
				(
					if findItem layout_dynamic j[1] == 0 do 
					(
						append layout_dynamic j[1]
						append layout_def #(j[1],60)
					)	
				)	
			)
			initListView lv_filesToLoad
			fillInSpreadSheet lv_filesToLoad
			
			Krakatoa_PRTLoader_FileEditor.resized (getFileDialogSize())
			updateSubRollouts init:true

		)	
		else
			destroyDialog Krakatoa_PRTLoader_FileEditor
	)
)
