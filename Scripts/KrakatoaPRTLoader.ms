-- Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
-- SPDX-License-Identifier: Apache-2.0
global Krakatoa_PRTLoader_FileEditor, Krakatoa_PresetsDirectory, Krakatoa_PRTLoader_SelectPartitions
global Krakatoa_PresetsArrowBitmap

plugin Geometry KrakatoaPrtLoader
name:"PRT Loader"
category:"Krakatoa"
classid:#(0x46b7f5c2, 0x4d2a17b6)
extends:KrakatoaPrtLoaderBase
replaceui:true
(
	local countdisplay, params, presets_rollout, renderingRollout, viewportRollout, particleCullingRollout
	local customPresetName = ""
	local isCreating = true

	local theDisplay = bitmap 150 80 color:((colorman.getColor #background)*255)
	local theGraphDisplay = bitmap 150 80 color:((colorman.getColor #background)*255)
	local errorBitmap = bitmap 55 20 color:red
	local noFilesBitmap = bitmap 55 20 color:(white*0.5)
	local noErrorBitmap = bitmap 55 20 color:green
	
	fn invalidate =
	(
		delegate.InvalidateObjectSpaceCache()
		presets_rollout.ddl_presets.selection = 1
		if not isCreating do customPresetName = ""
	)	
	
	fn autoLayoutOnResizeOn =
	(
		local autoResize = true
		local maxVer = maxVersion()
		if maxVer[1] == 22000 and maxVer[5] > 0 do autoResize = false
		autoResize
	)
		
	parameters rendering rollout:renderingRollout
	(
	
--RENDER-- 		
		renderLoadMode type:#integer default:2 ui:ddl_renderLoadMode animatable:false
		enabledInRender type:#boolean default:true ui:chk_enabledInRender animatable:false
		percentRenderer type:#float default:100 ui:spn_percentRenderer animatable:true --ANIMATABLE!
		useRenderLimit type:#boolean default:false ui:chk_useRenderLimit animatable:false
		renderLimit type:#float default:1000 ui:spn_RenderLimit animatable:false  
		particleColorSource type:#integer default:1 --ui:ddl_particleColorSource animatable:false --OBSOLETE 1.5.0

		loadDensities type:#boolean default:false animatable:false 

		--resetDensities type:#boolean default:false  animatable:false --ui:chk_resetDensities
		--copyDensitiesToMapChannel type:#boolean default:false animatable:false --ui:chk_copyDensitiesToMapChannel 
		--densityMapChannel type:#integer default:42 animatable:false --ui:spn_DensityMapChannel 
--RENDER HANDLERS
		on percentRenderer set val do invalidate()
		on particleColorSource set val do if ViewportParticleColorSource == 1 do invalidate()			
	)

	parameters viewportParams rollout:viewportRollout
	(
--VIEWPORT--	
		viewLoadMode type:#integer default:1 ui:ddl_viewLoadMode animatable:false
		enabledInView type:#boolean default:true ui:chk_enabledInView animatable:false
		percentViewport type:#float default:1 ui:spn_percentViewport animatable:false
		useViewportLimit type:#boolean default:false ui:chk_useViewportLimit  animatable:false
		viewportLimit type:#float default:100 ui:spn_ViewportLimit animatable:false 
		viewportParticleColorSource type:#integer default:1 --ui:ddl_ViewportParticleColorSource animatable:false --OBSOLETE
		viewportParticleDisplayMode type:#integer default:2 ui:ddl_ViewportParticleDisplayMode animatable:false	
		scaleNormals type:#float default:10 ui:spn_scaleNormals animatable:false
		ignoreMaterial type:#boolean default:false ui:chk_ignoreMaterial animatable:false
		
		showIcon type:#boolean default:true ui:chk_showIcon animatable:true
		iconSize type:#float default:30 ui:spn_iconSize animatable:false
		showCountInViewport type:#integer default:3 animatable:false
		autoUpdateGraph type:#boolean default:false animatable:false
		showBoundingBox type:#boolean default:true ui:chk_showBoundingBox animatable:false
		
--VIEWPORT HANDLERS
		on ignoreMaterial set val do 
		(
			viewportParticleColorSource = if val then 2 else 4
			invalidate()
		)
		on viewLoadMode set val do invalidate()
		on enabledInView set val do invalidate()
		on percentViewport set val do invalidate()
		on useViewportLimit set val do invalidate()
		on ViewportLimit set val do invalidate()
		on ViewportParticleColorSource set val do invalidate()
		on ViewportParticleDisplayMode set val do invalidate()
	)	

		
	parameters culling rollout:particleCullingRollout 
	(
--ICON DISPLAY--		
		gizmoBoxX type:#float default:10 ui:spn_gizmoBoxX  animatable:true
		gizmoBoxY type:#float default:10 ui:spn_gizmoBoxY animatable:true
		gizmoBoxZ type:#float default:10 ui:spn_gizmoBoxZ animatable:true
		
--CULLING--
		useCullingGizmo type:#boolean default:false ui:chk_useCullingGizmo  animatable:true
		invertCullingGizmo type:#boolean default:false ui:chk_invertCullingGizmo  animatable:true
		cullingNamedSelectionSet type:#string
		useThresholdCulling type:#boolean default:false ui:chk_useThresholdCulling animatable:true
		cullingThreshold type:#float default:1 ui:spn_cullingThreshold animatable:true
		getCullingSurfaceNormals type:#boolean default:false ui:chk_getCullingSurfaceNormals animatable:true
	)
	
	parameters main rollout:params
	(
	
--FILE LIST--
		fileList type:#filenameTab default:"" tabSizeVariable:true assetType:#Other 
		on fileList set val do try(invalidate(); params.UpdateGUI() )catch()
		fileListFlags type:#intTab tabSizeVariable:true
		
--TIMING--		
		limitToRange type:#boolean default:false ui:chk_limitToRange animatable:false
		rangeStartFrame type:#integer default:0 ui:spn_rangeStartFrame animatable:false --renamed from startFrame
		rangeEndFrame type:#integer default:100 ui:spn_rangeEndFrame animatable:false --renamed from endFrame
		
		on limitToRange set val do 
		(
			try
			(
				invalidate()
				if autoUpdateGraph do countdisplay.updateGraph()
			)catch()
		)		
		on rangeStartFrame set val do 
		(
			try
			(
				if rangeStartFrame > rangeEndFrame do rangeEndFrame = rangeStartFrame
				invalidate()
				if autoUpdateGraph do countdisplay.updateGraph()
			)catch()
		)
		on rangeEndFrame set val do 
		(
			try
			(
				if rangeEndFrame < rangeStartFrame do rangeStartFrame = rangeEndFrame 
				invalidate()
				if autoUpdateGraph do countdisplay.updateGraph()
			)catch()
		)	

		loadSingleFrame type:#boolean default:false ui:chk_loadSingleFrame animatable:false
		on loadSingleFrame set val do 
		(
			try
			(
				invalidate()
				if autoUpdateGraph do countdisplay.updateGraph()
			)catch()
		)	

		frameOffset type:#integer default:0 ui:spn_frameOffset animatable:false
		on frameOffset set val do 
		(
			try
			(
				invalidate()
				if autoUpdateGraph do countdisplay.updateGraph()
			)catch()
		)
		
		enablePlaybackGraph type:#boolean default:false ui:chk_enablePlaybackGraph animatable:false
		on enablePlaybackGraph set val do 
		(
			try
			(
				invalidate()
				if autoUpdateGraph do countdisplay.updateGraph()
			)catch()
		)

		playbackGraphTime type:#float default:0 ui:spn_playbackGraphTime animatable:true --ANIMATABLE!
		on playbackGraphTime set val do 
		(
			try
			(
				invalidate()
				if autoUpdateGraph do countdisplay.updateGraph()
			)catch()
		)
		
		beforeRangeBehavior type:#integer default:1 ui:ddl_beforeRangeBehavior animatable:false
		afterRangeBehavior type:#integer default:1 ui:ddl_afterRangeBehavior animatable:false
		on beforeRangeBehavior set val do 
		(
			try
			(
				invalidate()
				if autoUpdateGraph do countdisplay.updateGraph()
			)catch()
		)		
		on afterRangeBehavior set val do 
		(
			try
			(
				invalidate()
				if autoUpdateGraph do countdisplay.updateGraph()
			)catch()
		)			

--OPTIONS--
		useTransform type:#boolean default:true ui:chk_useTransform animatable:false
		on useTransform set val do 
		(
			presets_rollout.ddl_presets.selection = 1
		)	
		
		graphMode type:#integer animatable:false default:1
		--loadParticleNormals type:#boolean default:true animatable:false --ui:chk_loadParticleNormals 
		--on loadParticleNormals set val do try(delegate.Invalidate())catch()
		keepVelocityChannel type:#boolean default:false ui:chk_KeepVelocityChannel animatable:false

		interpolateFrames type:#boolean default:false ui:chk_interpolateFrames animatable:false
		
		/*////////////////////// RealFlow legacy load hack ///////////////////*/
		useLegacyRealflowBinLoading type:#boolean default:true animatable:false
		/*////////////////////////////////////////////////////////////////////*/
	)
	
	rollout presets_rollout "Presets" rolledup:true 
	(
		dotNetControl btn_savePreset "Button" text:"Save..." align:#left across:2 offset:[-8,-3] height:18 width:76 tooltip:"Save Current Settings as New Preset"
		dotNetControl btn_setAsDefault "Button" text:"Set Default..." align:#right offset:[8,-3] height:18 width:76 tooltip:"Save Current Settings as New Preset"
		listbox ddl_presets items:#("------Custom Settings------") width:160 align:#center offset:[0,-3] height:5
		dotNetControl btn_deletePreset "Button" text:"Delete..." align:#left across:2 offset:[-8,-3] height:18 width:76 tooltip:"Save Current Settings as New Preset"
		dotNetControl btn_explorePresets "Button" text:"Explore..." align:#right offset:[8,-3] height:18 width:76 tooltip:"Save Current Settings as New Preset"
		
		fn populatePresetsList =
		(
			theFiles = getFiles (Krakatoa_PresetsDirectory+ "\\presets\\*.KPS")
			ddl_presets.items= join #("------Custom Settings------") (for f in theFiles collect getFileNameFile f)
			if customPresetName != "" do ddl_presets.selection = findItem ddl_presets.items customPresetName 
		)
		
		on btn_explorePresets click arg  do
		(
			makeDir (Krakatoa_PresetsDirectory+ "\\presets\\") all:true
			shellLaunch "explorer.exe" (Krakatoa_PresetsDirectory+ "\\presets\\")
		)
		
		on btn_deletePreset click arg  do
		(
			thePresetFile = (Krakatoa_PresetsDirectory+ "\\presets\\" + ddl_presets.selected + ".KPS") 
			if doesFileExist thePresetFile and (querybox ("Do you really want to delete the Preset File [" + ddl_presets.selected +"]?") title:"KRAKATOA Particle File Loader: Delete Preset") do
			(
				deleteFile thePresetFile 
				populatePresetsList()
			)
		)
		
		on btn_setAsDefault click arg  do
		(
			if ddl_presets.selection == 1 then
			(
				if (querybox ("Do you really want to DISABLE Defaults Loading for Newly Created Loaders?") title:"KRAKATOA Particle File Loader: No Preset") do
				(
					setIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "PRTLoaders" "PresetName" ""
					setIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "PRTLoaders" "UsePreset" "false"
					try(Krakatoa_GUI_Preferences.refresh_GUI())catch()
				)
			)
				else
			(
				thePresetFile = (Krakatoa_PresetsDirectory+ "\\presets\\" + ddl_presets.selected + ".KPS") 
				if doesFileExist thePresetFile and (querybox ("Do you really want to SET the Preset File [" + ddl_presets.selected +"] as Default for Newly Created Loaders?") title:"KRAKATOA Particle File Loader: Default Preset") do
				(
					setIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "PRTLoaders" "PresetName" ddl_presets.selected
					setIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "PRTLoaders" "UsePreset" "true"
					try(Krakatoa_GUI_Preferences.refresh_GUI())catch()
				)			
			)
		)
		
		on btn_savePreset click arg do
		(
			createDialog Krakatoa_PRTLoader_PresetsOptions 200 500 modal:true
			if Krakatoa_PRTLoader_PresetsOptions_Filename != "" and Krakatoa_PRTLoader_PresetsOptions_Selection.count > 0 then
			(
				makeDir (Krakatoa_PresetsDirectory+ "\\presets\\") all:true
				thePresetFile = (Krakatoa_PresetsDirectory+ "\\presets\\" + Krakatoa_PRTLoader_PresetsOptions_Filename + ".KPS") 
				deleteFile thePresetFile 
				val = Krakatoa_PRTLoader_PresetsOptions_Selection
				if findItem val "Render Load Mode" > 0 do setIniSetting thePresetFile "Settings" "renderLoadMode" (renderLoadMode as string)
				if findItem val "Enabled In Renderer"  > 0 do setIniSetting thePresetFile "Settings" "enabledInRender" (enabledInRender as string)
				if findItem val "Percent In Renderer" > 0 do setIniSetting thePresetFile "Settings" "percentRenderer" (percentRenderer as string)
				if findItem val "Use Render Limit" > 0 do setIniSetting thePresetFile "Settings" "useRenderLimit" (useRenderLimit as string)
				if findItem val "Render Limit" > 0 do setIniSetting thePresetFile "Settings" "renderLimit" (renderLimit as string)
				if findItem val "View Load Mode" > 0 do setIniSetting thePresetFile "Settings" "viewLoadMode" (viewLoadMode as string)
				if findItem val "Enabled In View" > 0 do setIniSetting thePresetFile "Settings" "enabledInView" (enabledInView as string)
				if findItem val "Percent In Viewport" > 0 do setIniSetting thePresetFile "Settings" "percentViewport" (percentViewport as string)
				if findItem val "Use Viewport Limit" > 0 do setIniSetting thePresetFile "Settings" "useViewportLimit" (useViewportLimit as string)
				if findItem val "Viewport Limit" > 0 do setIniSetting thePresetFile "Settings" "viewportLimit" (viewportLimit as string)

				if findItem val "Viewport Particle Display Mode" > 0 do setIniSetting thePresetFile "Settings" "viewportParticleDisplayMode" (viewportParticleDisplayMode as string)
				if findItem val "Ignore Material" > 0 do setIniSetting thePresetFile "Settings" "ignoreMaterial" (ignoreMaterial as string)
				if findItem val "Normals Scale" > 0 do setIniSetting thePresetFile "Settings" "scaleNormals" (scaleNormals as string)
				if findItem val "Normals From Surface" > 0 do setIniSetting thePresetFile "Settings" "getCullingSurfaceNormals" (getCullingSurfaceNormals as string)
				if findItem val "Use Surface Threshold" > 0 do setIniSetting thePresetFile "Settings" "useThresholdCulling" (useThresholdCulling as string)
				if findItem val "Threshold Value" > 0 do setIniSetting thePresetFile "Settings" "cullingThreshold" (cullingThreshold as string)
				if findItem val "Limit To Range" > 0 do setIniSetting thePresetFile "Settings" "limitToRange" (limitToRange as string)
				if findItem val "Before Range Behavior" > 0 do setIniSetting thePresetFile "Settings" "beforeRangeBehavior" (beforeRangeBehavior as string)
				if findItem val "After Range Behavior" > 0 do setIniSetting thePresetFile "Settings" "afterRangeBehavior" (afterRangeBehavior as string)
				if findItem val "Load Single Frame" > 0 do setIniSetting thePresetFile "Settings" "loadSingleFrame" (loadSingleFrame as string)

				if findItem val "Frame Offset" > 0 do setIniSetting thePresetFile "Settings" "frameOffset" (frameOffset as string)
				if findItem val "Enable Playback Graph" > 0 do setIniSetting thePresetFile "Settings" "enablePlaybackGraph" (enablePlaybackGraph as string)
				if findItem val "Use Node Transform" > 0 do setIniSetting thePresetFile "Settings" "useTransform" (useTransform as string)
				if findItem val "Show Bounding Box" > 0 do setIniSetting thePresetFile "Settings" "showBoundingBox" (showBoundingBox as string)
				if findItem val "Show Icon" > 0 do setIniSetting thePresetFile "Settings" "showIcon" (showIcon as string)
				if findItem val "Icon Size" > 0 do setIniSetting thePresetFile "Settings" "iconSize" (iconSize as string)
				if findItem val "Show Count In Viewport" > 0 do setIniSetting thePresetFile "Settings" "showCountInViewport" (showCountInViewport as string)
				if findItem val "Graph Mode" > 0 do setIniSetting thePresetFile "Settings" "graphMode" (graphMode as string)
					
				populatePresetsList()
			)	
		)
		
		fn loadSettingFromPresetFile thePresetFile theName theProperty =
		(
			theVal = execute (getIniSetting thePresetFile "Settings" theName )
			if theVal != OK do 
			(
				try(setProperty this theProperty theVal)catch()
			)
		)
		
		fn loadPreset thePresetFile =
		(
			loadSettingFromPresetFile thePresetFile "renderLoadMode" #renderLoadMode 
			loadSettingFromPresetFile thePresetFile "enabledInRender" #enabledInRender  
			loadSettingFromPresetFile thePresetFile "percentRenderer" #percentRenderer 
			loadSettingFromPresetFile thePresetFile "useRenderLimit" #useRenderLimit 
			loadSettingFromPresetFile thePresetFile "RenderLimit" #RenderLimit 
			
			loadSettingFromPresetFile thePresetFile "viewLoadMode" #viewLoadMode  
			loadSettingFromPresetFile thePresetFile "enabledInView" #enabledInView  
			loadSettingFromPresetFile thePresetFile "percentViewport" #percentViewport 
			loadSettingFromPresetFile thePresetFile "useViewportLimit" #useViewportLimit 
			loadSettingFromPresetFile thePresetFile "ViewportLimit" #ViewportLimit 
			loadSettingFromPresetFile thePresetFile "ViewportParticleDisplayMode" #ViewportParticleDisplayMode 
			loadSettingFromPresetFile thePresetFile "ignoreMaterial" #ignoreMaterial 
			
			
			loadSettingFromPresetFile thePresetFile "scaleNormals" #scaleNormals 
			loadSettingFromPresetFile thePresetFile "getCullingSurfaceNormals" #getCullingSurfaceNormals 
			loadSettingFromPresetFile thePresetFile "useThresholdCulling" #useThresholdCulling 
			loadSettingFromPresetFile thePresetFile "cullingThreshold" #cullingThreshold 
			
			loadSettingFromPresetFile thePresetFile "limitToRange" #limitToRange 
			loadSettingFromPresetFile thePresetFile "beforeRangeBehavior" #beforeRangeBehavior 
			loadSettingFromPresetFile thePresetFile "afterRangeBehavior" #afterRangeBehavior 
			
			loadSettingFromPresetFile thePresetFile "loadSingleFrame" #loadSingleFrame 
			loadSettingFromPresetFile thePresetFile "frameOffset" #frameOffset 
			loadSettingFromPresetFile thePresetFile "enablePlaybackGraph" #enablePlaybackGraph 
			loadSettingFromPresetFile thePresetFile "useTransform" #useTransform 

			loadSettingFromPresetFile thePresetFile "showBoundingBox" #showBoundingBox 
			loadSettingFromPresetFile thePresetFile "showIcon" #showIcon 
			loadSettingFromPresetFile thePresetFile "iconSize" #iconSize 
			loadSettingFromPresetFile thePresetFile "showCountInViewport" #showCountInViewport 
			 
			theVal = execute (getIniSetting thePresetFile "Settings" "graphMode" ) 
			if theVal != OK do 
				try
				(
					graphMode = theVal 
					countdisplay.ddl_graphMode.selection = graphMode
					if autoUpdateGraph do countdisplay.updateGraph()
				)catch()
				
			params.UpdateGUI()
		)	
		
		on ddl_presets selected itm do
		(
			if itm > 1 do
			(
				thePresetFile = (Krakatoa_PresetsDirectory+ "\\presets\\" + ddl_presets.selected + ".KPS")
				if doesFileExist thePresetFile do
				(
					loadPreset thePresetFile
				)	
			)	
			ddl_presets.selection = itm
			customPresetName = ddl_presets.selected			
		)
		fn updateLayout =
		(
			btn_savePreset.FlatStyle = btn_savePreset.FlatStyle.System
			btn_setAsDefault.FlatStyle = btn_setAsDefault.FlatStyle.System
			btn_deletePreset.FlatStyle = btn_deletePreset.FlatStyle.System
			btn_explorePresets.FlatStyle = btn_explorePresets.FlatStyle.System
			
			btn_savePreset.width = btn_setAsDefault.width = btn_deletePreset.width = btn_explorePresets.width = (presets_rollout.width-6)/2
			btn_savePreset.pos.x = btn_deletePreset.pos.x = 2
			btn_setAsDefault.pos.x = btn_explorePresets.pos.x = (presets_rollout.width)/2
			
			ddl_presets.width = presets_rollout.width - 4
			ddl_presets.pos.x = 2
		)
		on presets_rollout open do 
		(
			if (maxVersion())[1] > 20000 do presets_rollout.autoLayoutOnResize = autoLayoutOnResizeOn() --the property is not available in 2018 and earlier, and is broken in 2020.1
			updateLayout()
			populatePresetsList()
			isCreating = false
		)	 
	)
	
	
	rollout params "Particle File Loader"
	(
		dotNetControl btn_addFiles "Button" text:"Add Files..." align:#left width:65 offset:[-10,-3] height:18 across:3 tooltip:"Click to Add Particle Files. Hold CTRL Key to open at the Default Path defined in Krakatoa Preferences."
		dotNetControl btn_removeFile "Button" text:"Remove..." align:#center width:65 offset:[20,-3] height:18 tooltip:"Click to Remove one or more selected Particle files..."
		button btn_editFiles ">>" align:#right width:25 offset:[11,-3] height:18 tooltip:"Click to open the File Sequence Context Menu..."

		dotnetcontrol dnc_filesToLoad "ListView" height:220 width:160 align:#center offset:[0,-4]
		
		checkbox chk_onInView "Viewport" across:2 align:#left offset:[0,-4] height:14
		checkbox chk_onInRender "Render" align:#right offset:[0,-4] height:14
		--groupbox grp_onInViewRender height:28 width:158 offset:[-1,-29] align:#center

		group "Timing:"		
		(
			checkbox chk_loadSingleFrame "Load Single Frame Only" offset:[-2,-3]
			checkbox chk_KeepVelocityChannel "Keep Velocity Channel" offset:[-2,-4] 
			checkbox chk_interpolateFrames "Interpolate Sub-Frames" offset:[-2,-4] 
		
			checkbox chk_enablePlaybackGraph "Graph [a]:" offset:[-2,-1] across:2
			spinner spn_playbackGraphTime "" range:[-10000000,10000000,0] fieldwidth:42 offset:[-13,-1] type:#float enabled:enablePlaybackGraph

			label lbl_frameOffset "Frame Offset:" across:2 align:#left offset:[0,-2]
			spinner spn_frameOffset range:[-10000000,10000000,0] fieldwidth:42 offset:[-13,-3] type:#integer 
			button btn_keyframeTools ">>" height:36 width:18 offset:[6,-40] align:#right

			checkbox chk_limitToRange "Limit To Custom Range:" offset:[-2,-3]
			dotNetControl btn_getCurrentSafeRange "Button" text:"Range" width:40 height:18 align:#left offset:[-3,-4] across:3 tooltip:"Check availability of frames and set the Custom Range to the intersection of all good intervals." 
			spinner spn_rangeStartFrame "" range:[-10000000,1000000,0] fieldwidth:35 offset:[-8,-3] type:#integer across:2 align:#left 
			spinner spn_rangeEndFrame "-" range:[-10000000,10000000,0] fieldwidth:42 offset:[5,-3] type:#integer align:#right
			dropdownlist ddl_beforeRangeBehavior items:#("Hold First","Blank") across:2 width:72 offset:[-3,0]
			dropdownlist ddl_afterRangeBehavior items:#("Hold Last","Blank") width:72 offset:[3,0]
			edittext txt_frame "Loading Frame: " readonly:true
		)

		checkbox chk_useTransform "Use Node Transform" offset:[0,-3]
		
		fn getListViewSelection lv =
		(
			try
				sort (for i = 1 to lv.items.count where lv.items.item[i-1].Selected collect i)
			catch
				#()
		)	
		
		fn setListViewSelection lv theSel =
		(
			try
			(
				for i = 1 to lv.items.count do lv.items.item[i-1].Selected = false
				for i in theSel do lv.items.item[i-1].Selected = true
			)catch()
		)			
		
		fn initFileListView =
		(
			local maxBgColor = (((colorman.getcolor #window)) as color)*255
			if maxBgColor.v >= 160 then
			(
				dn_distribution_bg = (dotNetClass "System.Drawing.Color").fromARGB 215 215 225 
			)
			else
			(
				dn_distribution_bg = (dotNetClass "System.Drawing.Color").fromARGB 50 50 55 
			)
			
			layout_def = #( #("L",18),  #("File",200), #("Path",200) )
			lv = dnc_filesToLoad
			lv.Clear()
			lv.backColor = dn_distribution_bg
			lv.View = (dotNetClass "System.Windows.Forms.View").Details
			lv.gridLines = true 
			lv.fullRowSelect = true
			lv.checkboxes = false
			lv.hideSelection = false
			lv.ShowItemToolTips = true				
			lv.MultiSelect = true
			--showEvents lv
			for i in layout_def do lv.Columns.add i[1] i[2]
		)			

		fn updateVRFlags =
		(
			local maxBgColor = (((colorman.getcolor #window)) as color)*255
			if maxBgColor.v >= 160 then
			(
				dn_distribution_bg = (dotNetClass "System.Drawing.Color").fromARGB 215 215 225 
				vrColor =  (dotNetClass "System.Drawing.Color").fromARGB 0 0 0
				rColor =  (dotNetClass "System.Drawing.Color").fromARGB 0 0 200
				vColor =  (dotNetClass "System.Drawing.Color").fromARGB 0 128 200
				nColor = (dotNetClass "System.Drawing.Color").fromARGB 128 128 128
			)
			else
			(
				dn_distribution_bg = (dotNetClass "System.Drawing.Color").fromARGB 50 50 55 
				vrColor =  (dotNetClass "System.Drawing.Color").fromARGB 255 255 255
				rColor =  (dotNetClass "System.Drawing.Color").fromARGB 150 170 255
				vColor =  (dotNetClass "System.Drawing.Color").fromARGB 150 255 255
				nColor =  (dotNetClass "System.Drawing.Color").fromARGB 150 150 150
			)
			
			try(
				local theSel = getListViewSelection dnc_filesToLoad
				local lv = dnc_filesToLoad
				lv.items.Clear()
				local theRange = #()
				for i = 1 to fileList.count collect 
				(
					local txt = case fileListFlags[i] of
					(
						default: "--"
						1: "v-"
						2: "-r"
						3: "vr"
					)					
					local li = dotNetObject "System.Windows.Forms.ListViewItem" txt
					local txt = case fileListFlags[i] of
					(
						default: "DISABLED"
						1: "Load Only In VIEWPORT"
						2: "Load Only In RENDERER"
						3: "Load In Both VIEWPORT And RENDERER"
					)						
					local theTooltipText = fileList[i] + "\n" + txt  
					
					local theMetaData = ""
					for j in try(FranticParticles.GetFileParticleMetadata fileList[i])catch(#()) do
					(
						local baseText = j[1]
						for kk = 1 to j[2].count do
						(
							local k = j[2][kk]
							if k[1] != "Interpretation" do
							(
								local theData = case k[1] as name of
								(
									#LengthUnitInMicrometers: ( k[2][1] as string)
									#LengthUnitInMeters: (formattedPrint k[2][1] format:"12.12g")
									#BoundBox: ( "\n  Min:["+ k[2][1] as string +","+k[2][2] as string + "," + k[2][3] as string + "]\n  Max:["+ k[2][4] as string +","+k[2][5] as string + "," + k[2][6] as string + "]" )
									#Extents: ( "\n  Min:["+ k[2][1] as string +","+k[2][2] as string + "," + k[2][3] as string + "]\n  Max:["+ k[2][4] as string +","+k[2][5] as string + "," + k[2][6] as string + "]" )
									#Coordsys: (
										case k[2][1] of
										(
											1: "Y Up RH (Maya)"
											2: "Z Up RH (3dsMax)"
											3: "Y Up LH (RealFlow)"
											4: "Z Up LH"
											default: "???"
										)
									)
									default: (
											if classof k[2] == Array then 
											(
												local combinedText = ""
												for jj in k[2] do combinedText+= jj as string + " "
												combinedText 	
											)
											else 
												k[2] as string
										)
								)
								theMetaData += k[1] + ": "+ baseText + " " + theData +"\n"
							)							
						)
					)
					
					local theChannels = try(FranticParticles.GetFileParticleChannels fileList[i])catch(#())
					if theChannels == undefined do theChannels = #()
					for c in theChannels do 
					(
						theMetaData += c[1] as string + " "+ c[2] as string  + "["+ c[3] as string +  "]\n"
					)
					
					li.tooltiptext = theTooltipText + "\n" + (theMetaData as string)
					li.forecolor = case fileListFlags[i] of
					(
						default: nColor
						1: vColor
						2: rColor
						3: vrColor
					)
					if loadSingleFrame then 
						txt = fileNameFromPath fileList[i]
					else 
						txt = FranticParticles.ReplaceSequenceNumberWithHashes (fileNameFromPath fileList[i])					
					local subLi = li.SubItems.add (txt)
					local subLi = li.SubItems.add (getfilenamePath fileList[i])
					append theRange li
				)
				lv.Items.AddRange theRange
				setListViewSelection dnc_filesToLoad theSel
			)catch()
		)
		
		fn updateVRCheckboxes =
		(
			local theSel = (getListViewSelection dnc_filesToLoad)
			local theStates = (for i in theSel where bit.get fileListFlags[i] 1 collect i)
			
			chk_onInView.triState = case of
			(
				(theStates.count == 0): 0
				(theStates.count == theSel.count): 1
				(theStates.count != theSel.count): 2
			)
			theStates = (for i in theSel where bit.get fileListFlags[i] 2 collect i)
			chk_onInRender.triState = case of
			(
				(theStates.count == 0): 0
				(theStates.count == theSel.count): 1
				(theStates.count != theSel.count): 2
			)
		)
		
		fn updateFrameText =
		(
			if(not chk_loadSingleFrame.checked) then
			(
				if(chk_enablePlaybackGraph.checked) then
					currFrame = spn_playbackGraphTime.value
				else
					currFrame =  (currentTime as integer)/TicksPerFrame
				
				currFrame += spn_frameOffset.value
				
				if(chk_limitToRange.checked) then
				(
					if(currFrame < spn_rangeStartFrame.value) then
					(
						if(ddl_beforeRangeBehavior.selected == "Hold First") then 
							currFrame = spn_rangeStartFrame.value
						else
							currFrame = "Blank"
					)
					else if(currFrame > spn_rangeEndFrame.value) then
					(
						if(ddl_afterRangeBehavior.selected == "Hold Last") then
							currFrame = spn_rangeEndFrame.value
						else
							currFrame ="Blank"
					)
				)
			)
			else
				currFrame = "File"
			
			txt_frame.text = currFrame as string
		)

		fn UpdateGUI =
		(
			updateVRFlags()
			chk_enablePlaybackGraph.enabled = spn_frameOffset.enabled = chk_limitToRange.enabled =  not chk_loadSingleFrame.checked
			spn_playbackGraphTime.enabled = chk_enablePlaybackGraph.checked and not chk_loadSingleFrame.checked
			spn_rangeStartFrame.enabled = spn_rangeEndFrame.enabled = limitToRange and not chk_loadSingleFrame.checked
			chk_KeepVelocityChannel.enabled = loadSingleFrame
			countdisplay.updateInfo()
			updateVRCheckboxes()
			updateFrameText()
			try(Krakatoa_PRTLoader_FileEditor.update())catch()
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
			for aFile in fileList do
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
				rangeStartFrame = amax (for i in theRangesArray collect i[1])
				rangeEndFrame = amin (for i in theRangesArray collect i[2])					
			)	
			pushprompt ("Safe Range Set in " + (timestamp()-st) as string + "ms.")
		)
		
		
		on btn_getCurrentSafeRange click arg do getValidRange()
		
		fn openEditor =
		(
			try(destroyDialog Krakatoa_PRTLoader_FileEditor)catch()
			theSize = execute (getIniSetting (Krakatoa_PresetsDirectory+ "\\KrakatoaPreferences.ini") "Dialog" "FileManagerSize")
			if classof theSize != Point2 do theSize = [800,500]
			thePos = execute (getIniSetting (Krakatoa_PresetsDirectory+ "\\KrakatoaPreferences.ini") "Dialog" "FileManagerPosition")
			if classof thePos != Point2 do thePos = [100,100]
			if thePos.x > sysinfo.desktopSize.x-100 do thePos.x = 100
			if thePos.y > sysinfo.desktopSize.y-100 do thePos.y = 100
			if thePos.x < 0 do thePos.x = 0
			if thePos.y < 0 do thePos.y = 0
			if theSize.x < 200 do theSize.x = 200
			if theSize.y < 200 do theSize.y = 200

			--if (maxVersion())[1]>=9000 then
				try(createDialog Krakatoa_PRTLoader_FileEditor theSize.x theSize.y thePos.x thePos.y style:#(#style_titlebar, #style_border, #style_sysmenu, #style_minimizebox, #style_resizing, #style_maximizebox  ) menu:Krakatoa_PRTLoader_FileEditor_MainMenu)catch()
			--else	try(createDialog Krakatoa_PRTLoader_FileEditor theSize.x theSize.y  thePos.x thePos.y style:#(#style_titlebar, #style_border, #style_sysmenu, #style_minimizebox  ) menu:Krakatoa_PRTLoader_FileEditor_MainMenu)catch()
		)
		
		fn addOutputFile =
		(
			if classof renderers.current == Krakatoa do
			(
				fileToAdd = FranticParticles.GetProperty "ParticleFiles"
				if fileToAdd != "" do
				(
					local addSequenceMode = getIniSetting ( getDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "Preferences" "AddFileSequenceBehavior"
					if addSequenceMode == "" do addSequenceMode = "1"
					local partitionFiles = for o in fileList collect o
					local fileFlagsList = for o in fileListFlags collect o
					if findItem partitionFiles fileToAdd == 0 then
					(
						append partitionFiles fileToAdd
						with undo "PRT File Added" on 
						(
							fileList = for o in partitionFiles collect o
							local isFirst = true
							for i = 1 to partitionFiles.count where fileFlagsList[i] == undefined do
							(
								fileFlagsList[i] = case addSequenceMode of
								(
								default: 3
								"2": 2
								"3": (
										if isFirst then
										(
											isFirst = false
											3
										)
										else
											2
									)	
								"4": 0
								)
							)	
							fileListFlags = for o in fileFlagsList collect o
						)		
						UpdateGUI()
						if Krakatoa_PRTLoader_FileEditor.open do openEditor()					
					)	
					else
						setListViewSelection dnc_filesToLoad #(findItem partitionFiles fileToAdd) --test me!
				)
			)
		)
		
		fn addOutputPartitions =
		(
			if classof renderers.current == Krakatoa do
			(
				fileToAdd = FranticParticles.GetProperty "ParticleFiles"
				if fileToAdd != "" do
				(
					local addSequenceMode = getIniSetting ( getDir #plugcfg+ "\\Krakatoa\\KrakatoaPreferences.ini") "Preferences" "AddFileSequenceBehavior"
					if addSequenceMode == "" do addSequenceMode = "1"
					local partitionFiles = for o in fileList collect o
					local fileFlagsList = for o in fileListFlags collect o
						
					local partitionCount = (FranticParticles.GetIntProperty "Partition:Count")

					local theBasePath = getFileNamePath fileToAdd
					local theBaseFilename = getFileNameFile fileToAdd
					local theBaseFileExt = getFileNameType fileToAdd
					if theBaseFileExt == "" do theBaseFileExt = ".prt"
					if matchpattern theBaseFilename pattern:"*part*of*" do
					(
						theIndex = 0
						for i = theBaseFilename.count-4 to 1 by -1 do 
						(
							if substring theBaseFilename i 5 == "_part" then
							(
								theIndex = i
								exit
							)	
						)
						theBaseFilename = substring theBaseFilename 1 (theIndex-1) 
					)							
					
					local theFileName = theBasePath + theBaseFilename + theBaseFileExt
					theFileName = (FranticParticles.ReplaceSequenceNumberWithHashes theFileName)
					theFileName = substituteString theFileName "#" "0"
					for partitionNumber = 1 to partitionCount do
					(
						local partitionFilename = FranticParticles.MakePartitionFilename theFileName partitionNumber partitionCount 
						if findItem partitionFiles partitionFilename == 0 do 
						(
							append partitionFiles partitionFilename
						)
					)
					with undo "PRT File Added" on 
					(
						fileList = for o in partitionFiles collect o
						local isFirst = true
						for i = 1 to partitionFiles.count where fileFlagsList[i] == undefined do
						(
							fileFlagsList[i] = case addSequenceMode of
							(
							default: 3
							"2": 2
							"3": (
									if isFirst then
									(
										isFirst = false
										3
									)
									else
										2
								)	
							"4": 0
							)
						)	
						fileListFlags = for o in fileFlagsList collect o
					)		
					UpdateGUI()
					if Krakatoa_PRTLoader_FileEditor.open do openEditor()					
				)
			)
		)		
		
		fn updateSelectedPartitions =
		(
			global Krakatoa_PRTLoader_AllNewPartitions = #()
			global Krakatoa_PRTLoader_AddFileSequenceBehavior_Override = getIniSetting ( getDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "Preferences" "AddFileSequenceBehavior"
			if Krakatoa_PRTLoader_AddFileSequenceBehavior_Override == "" do Krakatoa_PRTLoader_AddFileSequenceBehavior_Override = "1"
			local theSel = getListViewSelection dnc_filesToLoad
			local partitionFiles = for o in fileList collect o
			for i in theSel do
			(
				local partitionCount = (FranticParticles.GetPartitionFromFilename partitionFiles[i])[2] 
				if partitionCount > 0 do
				(
					for p = 1 to partitionCount do
					(
						local thePattern = FranticParticles.ReplacePartitionInFilename partitionFiles[i] p
						if findItem partitionFiles thePattern == 0 do 
							append Krakatoa_PRTLoader_AllNewPartitions thePattern
					)
				)
			)
			if Krakatoa_PRTLoader_AllNewPartitions.count > 0 do
			(
				createDialog Krakatoa_PRTLoader_SelectPartitions modal:true style:#(#style_titlebar, #style_border, #style_sysmenu,#style_resizing,#style_maximizebox )
				local flagList = for f in fileListFlags collect f
				
				local flagsToApply = case Krakatoa_PRTLoader_AddFileSequenceBehavior_Override of
				(
					default: 3
					"2": 2
					"3": 2
					"4": 0
					"5": 1
				)
						
				for f in Krakatoa_PRTLoader_AllNewPartitions do 
				(
					append partitionFiles f
					append flagList flagsToApply
				)
				with undo "Partitions Added" on 
				(
					fileList = for o in partitionFiles collect o
					fileListFlags = for o in flagList collect o
				)
				UpdateGUI()
				if Krakatoa_PRTLoader_FileEditor.open do openEditor()
				countdisplay.updateInfo()
				if autoUpdateGraph do countdisplay.updateGraph()
			)
		)
		
		local FileEditorRCMenu
		fn defineEditorRCMenu =
		(
			rcmenu FileEditorRCMenu 
			(
				fn isKrakatoaCurrentRenderer = classof renderers.current == Krakatoa 
				fn arePartitionsSelected = (getListViewSelection dnc_filesToLoad).count > 0
				fn canPastePaths = (
					local clipboardClass = dotNetClass  "System.Windows.Forms.Clipboard"
					local theFilesString = clipboardClass.GetText()
					theFilesString = substituteString theFilesString "\"" ""
					local thePaths = filterString theFilesString "\n"
					thePaths = for f in thePaths where not matchPattern f pattern:"*$*" collect f
					(for f in thePaths where (pathConfig.isLegalPath f) and (getFileNamePath f != "") and (findItem fileList f == 0) and (findItem #(".prt",".csv",".bin",".rpc",".las",".laz",".xyz",".e57",".sprt",".pts",".ptx",".ptg") (toLower (getFileNameType f)) > 0)  collect f).count >0
				)
				fn hasMaterial = (try($.material != undefined)catch(false))
				menuitem mnu_openPDV "OPEN Particle Data VIEWER..."
				separator sep_05 
				menuitem mnu_openEditor "OPEN File Sequence EDITOR..."
				separator sep_10 
				menuitem mnu_selectAll "SELECT All" 
				menuitem mnu_selectInvert "INVERT Selection" 
				separator sep_20 filter:isKrakatoaCurrentRenderer
				menuitem mnu_addOutputFile "ADD 'Save Particles' Sequence..." filter:isKrakatoaCurrentRenderer
				menuitem mnu_addOutputPartitions "ADD ALL 'Save Partitions' Sequences..." filter:isKrakatoaCurrentRenderer
				separator sep_30 filter:arePartitionsSelected
				menuitem mnu_updateSelectedPartitions "UPDATE Selected Partition Sequences..." filter:arePartitionsSelected
				separator sep_40 
				menuitem mnu_copyAllToClipboard "COPY ALL Filenames To Windows Clipboard" 
				menuitem mnu_copySelectedToClipboard "COPY SELECTED Filenames To Windows Clipboard" 
				separator sep_50 filter:canPastePaths
				menuitem mnu_pasteFromClipboard "PASTE Filenames From Windows Clipboard" filter:canPastePaths
				separator sep_60 filter:hasMaterial
				menuitem mnu_clearMaterial "CLEAR Material" filter:hasMaterial
				
				on mnu_clearMaterial picked do $.material = undefined
				
				on mnu_openEditor picked do openEditor()
				
				on mnu_openPDV picked do 
				(
					fileIn (FranticParticles.KrakatoaHome+"Scripts\\Krakatoa_ParticleDataViewer.ms")
				)
				
				on mnu_selectAll picked do 
				(
					setListViewSelection dnc_filesToLoad ((#{1..(fileList.count)}) as array)
					updateVRFlags()
					updateVRCheckboxes()
				)
				on mnu_selectInvert picked do 
				(
					local theSel = (getListViewSelection dnc_filesToLoad) as bitarray
					theSel = #{1..fileList.count}-theSel
					setListViewSelection dnc_filesToLoad (theSel as array)
					updateVRFlags()
					updateVRCheckboxes()
				)
				on mnu_addOutputFile picked do addOutputFile()
				on mnu_addOutputPartitions picked do addOutputPartitions()
				on mnu_updateSelectedPartitions picked do updateSelectedPartitions()
				on mnu_copySelectedToClipboard picked do
				(
					local theSel = getListViewSelection dnc_filesToLoad
					if theSel.count == 1 then 
					(
						theText =  fileList[theSel[1]]
					)
					else
					(
						theText = "--PRT LOADER FILE LIST SELECTION: [" + selection[1].name + "]\n"
						for i in theSel do theText += fileList[i] + "\n"
					)
					clipboardClass = dotNetClass  "System.Windows.Forms.Clipboard"
					clipboardClass.SetText theText
					updateVRFlags()
					updateVRCheckboxes()
				)
				on mnu_copyAllToClipboard picked do
				(
					if fileList.count == 1 then 
					(
						theText =  fileList[1]
					)
					else 
					(
						theText = "--PRT LOADER FILE LIST: [" + selection[1].name + "]\n"
						for i in fileList do theText += i + "\n"
					)		
					clipboardClass = dotNetClass  "System.Windows.Forms.Clipboard"
					clipboardClass.SetText theText
				)
				on mnu_pasteFromClipboard picked do
				(
					clipboardClass = dotNetClass  "System.Windows.Forms.Clipboard"
					local theFilesString = clipboardClass.GetText()
					theFilesString = substituteString theFilesString "\"" ""
					local theSS = theFilesString as StringStream
					theFileList = FileList
					theFileListFlags = FileListFlags
					local changesMade = false
					local addSequenceMode = getIniSetting ( getDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "Preferences" "AddFileSequenceBehavior"
					if addSequenceMode == "" do addSequenceMode = "1"
					while not eof theSS do
					(
						local theLine = readLine theSS
						if pathConfig.isLegalPath theLine and getFileNamePath theLine != "" do
						(
							if findItem fileList theLine == 0 do
							(
								append theFileList theLine
								local theFlags = case addSequenceMode of
								(
									default: 3
									"2": 2
									"3": (if theFileList.count == 1 then 3 else 2)
									"4": 0
								)
								append theFileListFlags theFlags
								changesMade = true
							)
						)
					)
					if changesMade do
					(
						FileList = theFileList 
						FileListFlags = theFileListFlags 
					)
				)
				
			)	
		)
		
		fn playbackgraph_currentSegment mode =
		(
			try(deleteKeys selection[1].playbackGraphTime.controller #allKeys)catch()
			local theCtrl = selection[1].playbackGraphTime.controller = bezier_float()
			
			
			case mode of
			(
				#linear:
				(
					theKey = addNewKey theCtrl animationrange.start
					theKey.value = animationrange.start.frame
					theKey.inTangentType = theKey.outTangentType = #linear
					
					theKey = addNewKey theCtrl animationrange.end
					theKey.value = animationrange.end.frame
					theKey.inTangentType = theKey.outTangentType = #linear
					
					setBeforeORT theCtrl #linear
					setAfterORT theCtrl #linear
				)	
				#accel:
				(
					theKey = addNewKey theCtrl animationrange.start
					theKey.value = animationrange.start.frame
					theKey.inTangentType = theKey.outTangentType = #slow
					
					theKey = addNewKey theCtrl animationrange.end
					theKey.value = animationrange.end.frame
					theKey.inTangentType = theKey.outTangentType = #fast
					
					setBeforeORT theCtrl #linear
					setAfterORT theCtrl #linear
				)
				#decel:
				(
					theKey = addNewKey theCtrl animationrange.start
					theKey.value = animationrange.start.frame
					theKey.inTangentType = theKey.outTangentType = #fast
					
					theKey = addNewKey theCtrl animationrange.end
					theKey.value = animationrange.end.frame
					theKey.inTangentType = theKey.outTangentType = #slow
					
					setBeforeORT theCtrl #linear
					setAfterORT theCtrl #linear
				)		

				#pingpong:
				(
					theKey = addNewKey theCtrl animationrange.start
					theKey.value = animationrange.start.frame
					theKey.inTangentType = theKey.outTangentType = #auto
					
					theKey = addNewKey theCtrl (animationrange.start.frame + ((animationrange.end.frame - animationrange.start.frame)/2))
					theKey.value = animationrange.end.frame
					theKey.inTangentType = theKey.outTangentType = #auto
					
					theKey = addNewKey theCtrl animationrange.end
					theKey.value = animationrange.start.frame
					theKey.inTangentType = theKey.outTangentType = #auto
					
					setBeforeORT theCtrl #linear
					setAfterORT theCtrl #linear
				)	
			)
		)
		
		fn playbackgraph_invertAnimation =
		(
			local theCtrl = try(selection[1].playbackGraphTime.controller)catch(undefined)
			if theCtrl != undefined do
			(
				try(reverseTime theCtrl theCtrl.keys[1].time theCtrl.keys[theCtrl.keys.count].time  #incLeft #incRight)catch()
				invalidate()
			)	
		)	
		
		fn playbackgraph_deleteAnimation = 
		(
			local theCtrl = try(selection[1].playbackGraphTime.controller)catch(undefined)
			if theCtrl != undefined do
				try(deleteKeys theCtrl #allKeys)catch()
		)
		
		local KeyframeToolsRCMenu 
		fn defineKeyframeToolsRCMenu =
		(
			rcmenu KeyframeToolsRCMenu
			(
				menuitem mnu_playbackgraph_currentSegment_Linear "Create LINEAR Playback Keys"
				menuitem mnu_playbackgraph_currentSegment_Accelerate "Create ACCELERATION Playback Keys"
				menuitem mnu_playbackgraph_currentSegment_Decelerate "Create DECELERATION Playback Keys"
				menuitem mnu_playbackgraph_currentSegment_PingPong "Create PING-PONG Playback Keys"
				separator sep_10 
				subMenu "Out-Of-Range Types"
				(
					menuitem mnu_playbackgraph_ORT_Before_Constant "Before CONSTANT" checked:(try(getBeforeORT selection[1].playbackGraphTime.controller == #constant)catch(false))
					menuitem mnu_playbackgraph_ORT_Before_Cycle "Before CYCLE" checked:(try(getBeforeORT selection[1].playbackGraphTime.controller == #cycle)catch(false))
					menuitem mnu_playbackgraph_ORT_Before_Loop "Before LOOP" checked:(try(getBeforeORT selection[1].playbackGraphTime.controller == #loop)catch(false))
					menuitem mnu_playbackgraph_ORT_Before_PingPong "Before PING PONG" checked:(try(getBeforeORT selection[1].playbackGraphTime.controller == #pingpong)catch(false))
					menuitem mnu_playbackgraph_ORT_Before_Linear "Before LINEAR" checked:(try(getBeforeORT selection[1].playbackGraphTime.controller == #linear)catch(false))
					menuitem mnu_playbackgraph_ORT_Before_Repeat "Before RELATIVE REPEAT" checked:(try(getBeforeORT selection[1].playbackGraphTime.controller == #relativerepeat)catch(false))
					separator sep_100
					menuitem mnu_playbackgraph_ORT_After_Constant "After CONSTANT" checked:(try(getAfterORT selection[1].playbackGraphTime.controller == #constant)catch(false))
					menuitem mnu_playbackgraph_ORT_After_Cycle "After CYCLE" checked:(try(getAfterORT selection[1].playbackGraphTime.controller == #cycle)catch(false))
					menuitem mnu_playbackgraph_ORT_After_Loop "After LOOP" checked:(try(getAfterORT selection[1].playbackGraphTime.controller == #loop)catch(false))
					menuitem mnu_playbackgraph_ORT_After_PingPong "After PING PONG" checked:(try(getAfterORT selection[1].playbackGraphTime.controller == #pingpong)catch(false))
					menuitem mnu_playbackgraph_ORT_After_Linear "After LINEAR" checked:(try(getAfterORT selection[1].playbackGraphTime.controller == #linear)catch(false))
					menuitem mnu_playbackgraph_ORT_After_Repeat "After RELATIVE REPEAT" checked:(try(getAfterORT selection[1].playbackGraphTime.controller == #relativerepeat)catch(false))
				)
				separator sep_20 
				menuitem mnu_playbackgraph_invertAnimation "INVERT Existing Animation"
				separator sep_30 
				menuitem mnu_playbackgraph_deleteAnimation "DELETE Existing Animation"
				
				on mnu_playbackgraph_ORT_Before_Constant picked do
					try(setBeforeORT selection[1].playbackGraphTime.controller #constant)catch()
				on mnu_playbackgraph_ORT_Before_Cycle picked do
					try(setBeforeORT selection[1].playbackGraphTime.controller #cycle)catch()
				on mnu_playbackgraph_ORT_Before_Loop picked do
					try(setBeforeORT selection[1].playbackGraphTime.controller #loop)catch()
				on mnu_playbackgraph_ORT_Before_PingPong picked do
					try(setBeforeORT selection[1].playbackGraphTime.controller #pingpong)catch()
				on mnu_playbackgraph_ORT_Before_Linear picked do
					try(setBeforeORT selection[1].playbackGraphTime.controller #linear)catch()
				on mnu_playbackgraph_ORT_Before_Repeat picked do
					try(setBeforeORT selection[1].playbackGraphTime.controller #relativerepeat)catch()
				
				on mnu_playbackgraph_ORT_After_Constant picked do
					try(setAfterORT selection[1].playbackGraphTime.controller #constant)catch()
				on mnu_playbackgraph_ORT_After_Cycle picked do
					try(setAfterORT selection[1].playbackGraphTime.controller #cycle)catch()
				on mnu_playbackgraph_ORT_After_Loop picked do
					try(setAfterORT selection[1].playbackGraphTime.controller #loop)catch()
				on mnu_playbackgraph_ORT_After_PingPong picked do
					try(setAfterORT selection[1].playbackGraphTime.controller #pingpong)catch()
				on mnu_playbackgraph_ORT_After_Linear picked do
					try(setAfterORT selection[1].playbackGraphTime.controller #linear)catch()
				on mnu_playbackgraph_ORT_After_Repeat picked do
					try(setAfterORT selection[1].playbackGraphTime.controller #relativerepeat)catch()				
				
				on mnu_playbackgraph_currentSegment_Linear picked do 
				(
					playbackgraph_currentSegment #linear
					updateFrameText()
				)
				on mnu_playbackgraph_currentSegment_Accelerate picked do
				(
					playbackgraph_currentSegment #accel
					updateFrameText()
				)
				on mnu_playbackgraph_currentSegment_Decelerate picked do
				(
					playbackgraph_currentSegment #decel
					updateFrameText()
				)
				on mnu_playbackgraph_currentSegment_PingPong picked do 
				(
					playbackgraph_currentSegment #pingpong
					updateFrameText()
				)
				
				on mnu_playbackgraph_invertAnimation picked do
				(					
					playbackgraph_invertAnimation()
					updateFrameText()
				)
				on mnu_playbackgraph_deleteAnimation picked do 
				(
					playbackgraph_deleteAnimation()
					updateFrameText()
				)
			)
		)
				
		on btn_keyframeTools pressed do
		(
			defineKeyframeToolsRCMenu()
			popUpMenu KeyframeToolsRCMenu pos:mouse.screenpos
		)
		
		on btn_keyframeTools rightClick do
		(
			defineKeyframeToolsRCMenu()
			popUpMenu KeyframeToolsRCMenu pos:mouse.screenpos
		)		
		
		on btn_editFiles pressed do
		(
			defineEditorRCMenu()
			popUpMenu FileEditorRCMenu pos:mouse.screenpos
		)
		on btn_editFiles rightClick do
		(
			defineEditorRCMenu()
			popUpMenu FileEditorRCMenu pos:mouse.screenpos
		)
		
		on chk_limitToRange changed state do UpdateGUI ()

		on chk_enablePlaybackGraph changed state do 
		(
			spn_playbackGraphTime.enabled = state
			countdisplay.updateInfo()
			updateFrameText()
		)	
		on chk_loadSingleFrame changed state do 
		(
			chk_limitToRange.enabled = not state
			chk_KeepVelocityChannel.enabled = state
			spn_rangeStartFrame.enabled = spn_rangeEndFrame.enabled =  chk_limitToRange.checked AND not state
			chk_enablePlaybackGraph.enabled = spn_frameOffset.enabled  = not state
			spn_playbackGraphTime.enabled = enablePlaybackGraph AND not state
			countdisplay.updateInfo()
			updateVRFlags()
			updateFrameText()
		)
		
		on spn_playbackGraphTime changed val do 
		(
			countdisplay.updateInfo()
			updateFrameText()
		)
		
		on spn_frameOffset changed val do updateFrameText()
		on spn_rangeStartFrame changed val do updateFrameText()
		on spn_rangeEndFrame changed val do updateFrameText()
		on ddl_beforeRangeBehavior selected itm do updateFrameText()
		on ddl_afterRangeBehavior selected itm do updateFrameText()
		
		on dnc_filesToLoad mouseUp arg do
		(
			updateVRFlags()
			updateVRCheckboxes()
		)
		
		on dnc_filesToLoad 	DoubleClick val do
		(
			local theSel = getListViewSelection dnc_filesToLoad
			for s in theSel do
			(
				try(shellLaunch  "explorer.exe" (getFileNamePath fileList[s]))catch()
			)
		)
			
		
		on btn_addFiles click arg do
		(
			local rootName = ""
			local pathMode = (getIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "Preferences" "CreateLoadersBehavior")
			if pathMode == "1" do
				rootName = try(FranticParticles.GetProperty "ParticleFiles")catch("")
			if pathMode == "2" or rootName == "" do	
				rootName = (getIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "Preferences" "DefaultLoaderPath")
				
			local addSequenceMode = getIniSetting ( getDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "Preferences" "AddFileSequenceBehavior"
			if addSequenceMode == "" do addSequenceMode = "1"


			--if a single entry is selected in the Particle File Loader list, its path will be used to open the next one:
			local theSel = getListViewSelection dnc_filesToLoad
			if theSel.count == 1 do
				rootName = getFileNamePath fileList[theSel[1]]
				
			--if the user is holding down the Control key while clicking and a valid Default path was defined in Preferences, OVERRIDE!	
			if Keyboard.ControlPressed do	
			(
				local theName = (getIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "Preferences" "DefaultLoaderPath")
				if doesFileExist theName do rootName = theName
			)	
			
			--If Editor is open and a single entry is selected, open the file picker at its path!
			if Krakatoa_PRTLoader_FileEditor.open == true do
			(
				theSel = Krakatoa_PRTLoader_FileEditor.getSelection Krakatoa_PRTLoader_FileEditor.lv_filesToLoad
				if theSel.count == 1 do
					rootName = getFileNamePath fileList[theSel[1]]
			)	
			
			if not (doesFileExist (getFileNamePath rootName)) do rootName = "C:\\"
			
			local fileToAdd = getOpenFileName caption:"Select the Particle File Sequence to Add" filename:rootName \
				types:"All Particle Files And Point Cloud Files|*.prt;*.sprt;*.bin;*.rpc;*.csv;*.xyz;*.las;*.laz;*.pts;*.ptx;*.ptg;*.e57|Krakatoa Particle Files (*.prt)|*.prt|RealFlow Files (*.bin,*.rpc)|*.bin;*.prc|CSV Files (*.csv)|*.csv|LAS Files (*.las,*.laz)|*.las;*.laz|Leica Point Files (*.pts,*.ptx,*.ptg)|*.pts;*.ptx;*.ptg|ASTM E57 Point Files (*.e57)|*.e57|ASCII Point Files (*.xyz,*.txt)|*.xyz;*.txt|All Files (*.*)|*.*" \
				history:"KrakatoaParticles"
			if fileToAdd != undefined do 
			(
				local addSequenceMode = getIniSetting ( getDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "Preferences" "AddFileSequenceBehavior"
				if addSequenceMode == "" do addSequenceMode = "1"
				local flagsToApply = case addSequenceMode of
				(
					default: 3
					"2": 2
					"3": 3
					"4": 0
				)				
				local partitionFiles = for o in fileList collect o
				local fileFlagsList = for o in fileListFlags collect o
				local partitionCount = (FranticParticles.GetPartitionFromFilename fileToAdd)[2] --see if the selected file has a partition count
				if partitionCount > 0 then 
				(
					local query = yesNoCancelBox  ("The selected file appears to be part of a partition with " +partitionCount as string +" sequences.\n\nPress YES to load the selected sequence and any number of Partitions.\nPress NO to load only the selected sequence.\nPress CANCEL to not load the files at all.") title:"KRAKATOA Particle File Loader: Loading Partitions"
					if query != #cancel do
					(
						with undo "Partition File Added" on 
						(
							if findItem partitionFiles fileToAdd == 0 do 
							(
								append partitionFiles fileToAdd
								append fileFlagsList flagsToApply
								fileList = for o in partitionFiles collect o
								fileListFlags = for o in fileFlagsList collect o
								setListViewSelection dnc_filesToLoad #(partitionFiles.count)
								UpdateGUI()
							)
						)
						if query == #yes do updateSelectedPartitions()
					)
				)
				else
				(
					with undo "Particle File Added" on 
					(
						if findItem partitionFiles fileToAdd == 0 do 
						(
							append partitionFiles fileToAdd
							append fileFlagsList flagsToApply
							fileList = for o in partitionFiles collect o
							fileListFlags = for o in fileFlagsList collect o							
							setListViewSelection dnc_filesToLoad #(partitionFiles.count)
							UpdateGUI()
						)
					)					
				)
				countdisplay.updateInfo()
				if autoUpdateGraph do countdisplay.updateGraph()
			)
		)
		
		on btn_removeFile click arg do
		(
			local toDelete = getListViewSelection dnc_filesToLoad
			if toDelete.count > 0 then
			(
				txt = "Are you sure you want to REMOVE the "
				txt += if toDelete.count == 1 then "File Sequence\n" else (toDelete.count as string + " File Sequences\n" )
				theCnt = toDelete.count
				if theCnt >= 50 do theCnt = 50
				for i = 1 to theCnt do txt += fileList[toDelete[i]]+"\n"
				if theCnt < toDelete.count do txt += "...and "+ (toDelete.count - theCnt) as string +" more?\n"
				if (querybox txt title:"KRAKATOA Particle File Loader: Remove File Sequence") do
				(
					with undo "PRT Remove Files" on
					(
						for i = toDelete.count to 1 by -1 do 
						(
							local theFile = fileList[toDelete[i]]
							/*
							local AllFiles = getFiles (getFileNamePath theFile + substring (getFileNameFile theFile ) 1 ((getFileNameFile theFile ).count-4) + "*" + getFileNameType theFile )
							for f in AllFiles do ATSCustomDepsOps.RemoveFileByName f
							*/
							deleteItem fileList toDelete[i]
							deleteItem fileListFlags toDelete[i]
						)	
					)	
					--atsOps.Refresh()							
					invalidate()
					--edt_path.text = ""
					UpdateGUI()
					setListViewSelection dnc_filesToLoad #()
					if Krakatoa_PRTLoader_FileEditor.open do openEditor()
				)	
			)	
			countdisplay.updateInfo()
			if autoUpdateGraph do countdisplay.updateGraph()
		)
		
		on chk_onInView changed state do 
		(
			local theSel = getListViewSelection dnc_filesToLoad 
			for i in theSel do fileListFlags[i] = bit.set fileListFlags[i] 1 state
			UpdateGUI()
			invalidate()
		)	

		on chk_onInRender changed state do 
		(
			local theSel = getListViewSelection dnc_filesToLoad 
			for i in theSel do fileListFlags[i] = bit.set fileListFlags[i] 2 state
			UpdateGUI()
			if autoUpdateGraph do countdisplay.updateGraph()
		)	
		
		fn updateLayout =
		(
			btn_addFiles.FlatStyle = btn_addFiles.FlatStyle.System
			btn_removeFile.FlatStyle = btn_removeFile.FlatStyle.System
			btn_getCurrentSafeRange.FlatStyle = btn_getCurrentSafeRange.FlatStyle.System
			
			btn_addFiles.width = btn_removeFile.width = (params.width-30)/2
			btn_addFiles.pos.x = 2
			btn_removeFile.pos.x = (params.width-25)/2
			
			dnc_filesToLoad.width = params.width-4
			dnc_filesToLoad.pos.x = 2
			ddl_beforeRangeBehavior.width = ddl_afterRangeBehavior.width =  (params.width-20)/2
			--spn_rangeStartFrame.fieldwidth = spn_rangeEndFrame.fieldwidth = (params.width-100)/2
			spn_rangeStartFrame.pos.x = params.width-80
			btn_getCurrentSafeRange.width = params.width-123
		)

		on params open do
		(
			if (maxVersion())[1] > 20000 do params.autoLayoutOnResize = autoLayoutOnResizeOn() --the property is not available in 2018 and earlier, and is broken in 2020.1	
			updateLayout()
			if Krakatoa_PresetsArrowBitmap == undefined do
			(
				try
				(
					Krakatoa_PresetsArrowBitmap_Base = openbitmap (getDir #usericons + "\\krakatoaGUI.bmp")
					global Krakatoa_PresetsArrowBitmap = bitmap 512 16 color:red
					copy Krakatoa_PresetsArrowBitmap_Base Krakatoa_PresetsArrowBitmap 
				)
				catch	
				(
					Krakatoa_PresetsArrowBitmap_Base = bitmap 512 16 color:red
					global Krakatoa_PresetsArrowBitmap = bitmap 512 16 color:red
				)
				FranticParticleRenderMXS.updateIconColors()				
			)
			try(btn_keyframeTools.images = btn_editFiles.images = #(Krakatoa_PresetsArrowBitmap,Krakatoa_PresetsArrowBitmap, 32,1,1,2,2))catch()

			updateFrameText()
			registerTimeCallback updateFrameText
			initFileListView()	
			UpdateGUI()
		)
		
		on params close do
		(
			unRegisterTimeCallback updateFrameText
		)
	)--end rollout
	
	fn createPresetsRCMenu type:#renderpercent =
	(
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
			txt += "on mnu_preset" + cnt as string + " picked do selection[1]."+ theParameter +" = "+ i as string +"\n"
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

	rollout renderingRollout "Rendering" 
	(
		progressbar prg_renderLoadMode color:red width:11 height:21 align:#left across:2 offset:[-8,-3] value:100
		dropdownlist ddl_renderLoadMode items:#("Load Every Nth Particle","Load First N Particles","Load Every Nth by ID") width:145 align:#right offset:[11,-3]
		checkbox chk_enabledInRender  align:#left across:3 offset:[-8,-3]
		dotNetControl btn_percentRenderer "Button" text:"Percent [a]" height:16 width:69 offset:[-15,-3]
		spinner spn_percentRenderer range:[0,100,100] fieldwidth:50 offset:[10,-3]
		
		checkbox chk_useRenderLimit across:3 align:#left offset:[-8,-3]
		dotNetControl btn_RenderLimit "Button" text:"Limit (x1000)" height:16 width:69 offset:[-11,-3]
		spinner spn_RenderLimit range:[0,100000,1000] fieldwidth:50 type:#float offset:[10,-3]
		
		on btn_percentRenderer click arg do
		(
			createPresetsRCMenu type:#renderpercent 
			popUpMenu Krakatoa_Presets_RCMenu position:mouse.screenPos
		)	
		on btn_RenderLimit click arg do
		(
			createPresetsRCMenu type:#renderlimit
			popUpMenu Krakatoa_Presets_RCMenu position:mouse.screenPos
		)

		fn UpdateGUI =
		(
			prg_renderLoadMode.color = case renderLoadMode of
			(
				1: (color 255 200 100)
				2: green
				3: blue
				4: yellow
				default: black
			)
		)

		on chk_enabledInRender changed state do countdisplay.updateInfo() 
		on spn_percentRenderer changed val do countdisplay.updateInfo()
		on spn_RenderLimit changed val do countdisplay.updateInfo()

		on ddl_renderLoadMode selected itm do 
		(
			UpdateGUI()
			if viewLoadMode == 1 do invalidate() 
		)	

		/*
		on chk_copyDensitiesToMapChannel changed state do 
		(
			--resetDensities = copyDensitiesToMapChannel
			UpdateGUI()
		)	
		*/
		fn updateLayout =
		(
			ddl_renderLoadMode.width = renderingRollout.width-22
			ddl_renderLoadMode.pos.x = 20
			
			btn_percentRenderer.flatStyle = btn_percentRenderer.flatStyle.System
			btn_RenderLimit.flatStyle = btn_RenderLimit.flatStyle.System
			btn_percentRenderer.width = btn_RenderLimit.width = renderingRollout.width-94
			btn_percentRenderer.pos.x = btn_RenderLimit.pos.x = 30
		)
		on renderingRollout open do
		(
			if (maxVersion())[1] > 20000 do renderingRollout.autoLayoutOnResize = autoLayoutOnResizeOn() --the property is not available in 2018 and earlier, and is broken in 2020.1
			updateLayout()
			UpdateGUI()
		)
		
	)--end rollout	
		

	rollout viewportRollout "Viewport" 
	(
		progressbar prg_viewLoadMode color:red width:11 height:21 align:#left across:2 offset:[-8,-3] value:100
		dropdownlist ddl_viewLoadMode items:#("Load Using Render Mode","Load Every Nth Particle","Load First N Particles","Load Every Nth by ID") width:145 align:#right offset:[11,-3]
		checkbox chk_enabledInView across:3 align:#left  offset:[-8,-3]
		dotNetControl btn_percentViewport "Button" text:"% of Render" height:16 width:69 offset:[-11,-3]			
		spinner spn_percentViewport range:[0,100,1] fieldwidth:50 offset:[10,-3] 
		checkbox chk_useViewportLimit  across:3 align:#left offset:[-8,-3]
		dotNetControl btn_ViewportLimit "Button" text:"Limit (x1000)" height:16 width:69 offset:[-11,-3]
		spinner spn_ViewportLimit range:[0,100000,100] fieldwidth:50 type:#float offset:[10,-3]
		--dropdownlist ddl_ViewportParticleColorSource items:#("Colors Using Render Mode","Saved Particle Colors","Loader's Wireframe Color","Loader's Material Color") width:156 align:#center offset:[1,-3] --,"Density Channel As Color"
		dropdownlist ddl_ViewportParticleDisplayMode items:#("Display As Small Dots","Display As Large Dots","Display Velocities","Display Normals","Display Tangents") width:156 align:#center offset:[1,-3]
		spinner spn_scaleNormals "Scale Normals:" range:[0,10000000,10] fieldwidth:50 type:#float offset:[8,-3]
		checkbox chk_ignoreMaterial "Ignore Material" align:#left offset:[-8,-3]
		
		checkbox chk_showBoundingBox "Display Bounding Box" offset:[-8,-4]
		checkbox chk_showIcon "Icon" across:2 offset:[-8,-4]
		spinner spn_iconSize "Size [a]:" range:[0,10000000,10] fieldwidth:50 type:#worldunits offset:[8,-3]
		--button btn_updateDisplay "UPDATE VIEW CACHE" width:156 align:#center offset:[0,-3]
		dotNetControl dnc_updateDisplay "Button" text:"UPDATE VIEW CACHE" width:156 align:#center offset:[0,-3] height:22
	
		
		on btn_percentViewport click arg do
		(
			createPresetsRCMenu type:#viewpercent 
			popUpMenu Krakatoa_Presets_RCMenu position:mouse.screenPos
		)	
	
		on btn_ViewportLimit click arg do
		(
			createPresetsRCMenu type:#viewlimit
			popUpMenu Krakatoa_Presets_RCMenu position:mouse.screenPos
		)		


		fn UpdateGUI =
		(
			spn_scaleNormals.enabled = ddl_ViewportParticleDisplayMode.selected == "Display Normals" or ddl_ViewportParticleDisplayMode.selected == "Display Tangents" 
			prg_viewLoadMode.color = case viewLoadMode of
			(
				1: white
				2: (color 255 200 100)
				3: green
				4: blue
				5: yellow
				default: black
			)			
		)


		on dnc_updateDisplay Click args do
		(
			invalidate()
			try(delegate.UpdateCullingNodes currentTime)catch()
			max views redraw
		)
		
		on spn_percentViewport changed val do countdisplay.updateInfo()
		on spn_ViewportLimit changed val do countdisplay.updateInfo()
		on chk_enabledInView changed state do countdisplay.updateInfo() 
		on ddl_ViewportParticleDisplayMode selected value do UpdateGUI()
		--on chk_copyDensitiesToMapChannel changed state do UpdateGUI()
		on ddl_viewLoadMode selected itm do UpdateGUI()
		
		fn updateLayout =
		(
			ddl_viewLoadMode.width = viewportRollout.width-22
			ddl_ViewportParticleDisplayMode.width = viewportRollout.width-4
			ddl_viewLoadMode.pos.x = 20
			ddl_ViewportParticleDisplayMode.pos.x = 2


			btn_percentViewport.flatStyle = btn_percentViewport.flatStyle.System
			btn_ViewportLimit.flatStyle = btn_ViewportLimit.flatStyle.System
			
			btn_percentViewport.width = btn_ViewportLimit.width = viewportRollout.width-94
			btn_percentViewport.pos.x = btn_ViewportLimit.pos.x = 30

			dnc_updateDisplay.FlatStyle = dnc_updateDisplay.FlatStyle.System
			dnc_updateDisplay.width = viewportRollout.width-4
			dnc_updateDisplay.pos.x = 2
		)
		
		on viewportRollout open do
		(
			if (maxVersion())[1] > 20000 do viewportRollout.autoLayoutOnResize = autoLayoutOnResizeOn() --the property is not available in 2018 and earlier, and is broken in 2020.1
			updateLayout()
			UpdateGUI()
		)		
	)--end rollout
	rollout particleCullingRollout "Culling and Deformations" 
	(
		fn filterGizmos obj = findItem GeometryClass.classes (classof obj) > 0 and findItem #(TargetObject, PF_Source, KrakatoaPrtLoader) (classof obj) == 0 

		group "Particle Culling [a]"	
		(
			checkbox chk_useCullingGizmo "On:" enabled:true offset:[-5,-3] across:2 align:#left 
			checkbox chk_invertCullingGizmo "Invert-Cull Inside" enabled:true offset:[8,-3] align:#right
			dropdownlist ddl_cullingNamedSelectionSets items:#() width:148 align:#center offset:[0,-3]
			dotNetControl pck_createNSS "Button" text:"Make Culling Named Sel.Set..." width:150 align:#center offset:[0,-3] height:20 --filter:filterGizmos

			checkbox chk_useThresholdCulling "Culling Dist.:" align:#left across:2 offset:[-5,-3]
			spinner spn_cullingThreshold range:[0,10000,100] fieldwidth:50 offset:[6,-3] type:#worldunits

			checkbox chk_getCullingSurfaceNormals "Normals From Surface" offset:[-5,-4] align:#left 
--			checkbox chk_useThresholdNormals "Normals Dist.:" align:#left across:2 offset:[-5,-3]
--			spinner spn_normalsThreshold range:[0,10000,100] fieldwidth:50 offset:[6,-3] type:#worldunits
		)	

		group "Modifier Gizmo Size:"
		(
			dotNetControl btn_getXFromObject "Button" text:"Get" across:2 align:#left offset:[-7,-5] height:18 width:30
			spinner spn_gizmoBoxX "Width [a]:" range:[0,10000000,10] type:#worldunits fieldwidth:50 offset:[5,-4]
			dotNetControl btn_getYFromObject "Button" text:"Get" across:2 align:#left offset:[-7,-5] height:18 width:30
			spinner spn_gizmoBoxY "Length [a]:" range:[0,10000000,10] type:#worldunits fieldwidth:50 offset:[5,-4]
			dotNetControl btn_getZFromObject "Button" text:"Get" across:2 align:#left offset:[-7,-5] height:18 width:30
			spinner spn_gizmoBoxZ "Height [a]:" range:[0,10000000,10] type:#worldunits fieldwidth:50 offset:[5,-4]
			dotNetControl btn_getBBoxFromObject "Button" text:"Get All From Object" width:150 align:#center offset:[0,-4] height:20
		)


		fn UpdateGUI =
		(
			ddl_cullingNamedSelectionSets.items = join #("No Culling Named Sel.Set") (for i = 1 to getNumNamedSelSets() collect getNamedSelSetName i)
			theIndex = findItem ddl_cullingNamedSelectionSets.items cullingNamedSelectionSet
			if theIndex == 0 do theIndex = 1
			ddl_cullingNamedSelectionSets.selection = theIndex
		)	
		
		fn getBBoxSizeFromObject mode:#all =
		(
			if selection.count > 0 do
			(
				local theObj = selection[1]
				local theOldTM = theObj.transform
				theObj.transform = matrix3 1
				local theMin = theObj.min
				local theMax = theObj.max
				theObj.transform = theOldTM
				if mode == #all or mode == #x do gizmoBoxX = theMax.x - theMin.x
				if mode == #all or mode == #y do gizmoBoxY = theMax.y - theMin.y
				if mode == #all or mode == #z do gizmoBoxZ = theMax.z - theMin.z
			)			
		)		

		on pck_createNSS click arg do
		(
			local theNodes = selectByName title:"Select One Or More Geometry Objects To Add to Culling Named Selection Set:" buttonText:"Create NSS" filter:filterGizmos showHidden:true single:false
			if theNodes != undefined and theNodes.count > 0 do
			(
				local theName = theNodes[1].name
				if theNodes.count > 1 do theName += "(+"+(theNodes.count-1) as string + ")"
				selectionsets[theName] = theNodes
				cullingNamedSelectionSet = theName
				with undo "Culling On" on (useCullingGizmo = true)
				delegate.UpdateCullingNodes currentTime
				UpdateGUI()
			)
		)
		


		
		on btn_getBBoxFromObject click arg do getBBoxSizeFromObject mode:#all 
		on btn_getXFromObject click arg do getBBoxSizeFromObject mode:#x
		on btn_getYFromObject click arg do getBBoxSizeFromObject mode:#y
		on btn_getZFromObject click arg do getBBoxSizeFromObject mode:#z
		
		on ddl_cullingNamedSelectionSets selected itm do 
		(
			if itm > 1 then
				cullingNamedSelectionSet = ddl_cullingNamedSelectionSets.selected
			else 
				cullingNamedSelectionSet = ""
			delegate.UpdateCullingNodes currentTime
			UpdateGUI()
		)		

		fn updateLayout =
		(
			pck_createNSS.FlatStyle = pck_createNSS.FlatStyle.System
			ddl_cullingNamedSelectionSets.width = pck_createNSS.width = particleCullingRollout.width-14
			ddl_cullingNamedSelectionSets.pos.x = pck_createNSS.pos.x = 7
			
			
			btn_getBBoxFromObject.FlatStyle = btn_getBBoxFromObject.FlatStyle.System
			btn_getBBoxFromObject.width = particleCullingRollout.width-14
			btn_getXFromObject.pos.x = btn_getYFromObject.pos.x = btn_getZFromObject.pos.x = btn_getBBoxFromObject.pos.x = 7
			
			btn_getXFromObject.FlatStyle = btn_getXFromObject.FlatStyle.System
			btn_getYFromObject.FlatStyle = btn_getYFromObject.FlatStyle.System
			btn_getZFromObject.FlatStyle = btn_getZFromObject.FlatStyle.System
			
			btn_getXFromObject.width = btn_getYFromObject.width = btn_getZFromObject.width = particleCullingRollout.width - 135
		)
		
		on particleCullingRollout open do
		(
			if (maxVersion())[1] > 20000 do particleCullingRollout.autoLayoutOnResize = autoLayoutOnResizeOn() --the property is not available in 2018 and earlier, and is broken in 2020.1
			updateLayout()
			UpdateGUI()
		)		
	)--end rollout

	
	rollout countdisplay  "Particle Counts" rolledup:true 
	(
		bitmap bmp_stateIndicator height:18 width:53 align:#left across:2 offset:[-7,-3] bitmap:noFilesBitmap
		dotNetControl btn_infoUpdate "Button" text:"Update Info" width:95 height:18 align:#right offset:[7,-3]
	
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
		dotNetControl btn_graphUpdate "Button" text:"Update Graph" width:85 height:18 align:#right offset:[0,-3]
		dotNetControl btn_disableMissingSequences "Button" text:"Don't Render Missing Files" align:#center width:143 height:20 offset:[-2,-3]
		
		fn LeadingZeros value count =
		(
			theStr = value as string
			substring "00000000000" 1 (count-(theStr.count))
		)		
		
		fn updateTimeInGraph =
		(
			if countdisplay.open == true do
			(
				local foreColor = (colorman.getColor #text)*255
				local theXScale = bmp_graph.width / (animationrange.end.frame - animationrange.start.frame + 1)
				copy theDisplay theGraphDisplay
				for v = 0 to 79 by 3 do
					setPixels theGraphDisplay [1 + (sliderTime.frame as integer - animationrange.start.frame as integer ) * theXScale ,v ] #(foreColor )
				bmp_graph.bitmap = theGraphDisplay 
			)	
		)
		
		fn updateGraphLines draw:true mode:#customRange =
		(
			local st = timestamp()
			if countdisplay.open == true or not draw do
			(
				local loopstartFrame = animationrange.start.frame as integer
				local loopendFrame = animationrange.end.frame as integer
				local totalErrors =  for i = loopstartFrame  to loopendFrame collect (fileList.count > 0)
				local errorsArray = for i = loopstartFrame  to loopendFrame collect #()
				local theSegmentCount = fileList.count
				local currentSegment = 0.0
				local cnt = 0
				for aFile in fileList do
				(
					local theName = aFile
					local currentArray = #()
					cnt += 1
					local willNotRender = fileListFlags[cnt] < 2
					for t = loopstartFrame  to loopendFrame do
					(
						prg_graphprogress.value = 100.0 * currentSegment / theSegmentCount + 100.0 / theSegmentCount *  (t-loopstartFrame)/(loopendFrame-loopstartFrame) 
						windows.processPostedMessages()
						if willNotRender then
						(
							append errorsArray[cnt] 2
						)
						else
						(
							if not loadSingleFrame do
							(
								theTime = t + frameOffset 
								if enablePlaybackGraph do
								(
									theTime = at time theTime ((floor (playbackGraphTime+0.5)) as integer)
								)
								if limitToRange do
								(
									if theTime > rangeEndFrame do theTime = rangeEndFrame
									if theTime < rangeStartFrame do
									(
									 	theTime = rangeStartFrame
									 )
								)
								theName = FranticParticles.ReplaceSequenceNumber aFile theTime 
							)	
							if doesFileExist theName then 
							(
								append errorsArray[cnt] 0
							)
							else
							(
								append errorsArray[cnt] 1
								totalErrors[errorsArray[cnt].count] = false
							)	
						)	
					)--end t loop
					currentSegment += 1.0
				)--end aFile loop
				prg_graphprogress.value	= 0
				
				if draw then
				(
					local theBGColor = ((colorman.getColor #background)*255 ) as color
					theBGColor.alpha = 0
					local theBitmap = bitmap (totalErrors.count) (theSegmentCount+1) color:theBGColor
					
					setPixels theBitmap [0,0] (for i in totalErrors collect if i then (color 0 255 0 0 ) else (color 255 0 0 0))
					local iteration = 0
					local theMultipliers = #(1.0,0.90)
					for i = 1 to errorsArray.count do
					(
						iteration = 1 - iteration 
						local thePixels = for j = 1 to errorsArray[i].count collect
						(
							if errorsArray[i][j] == 0 then 
								if totalErrors[j] then
									(color 0 230 0 0 )*theMultipliers[iteration+1]
								else	
									(color 255 230 0 0 )*theMultipliers[iteration+1]
							else	
								if errorsArray[i][j] == 1 then
									(color 230 0 0 0 )*theMultipliers[iteration+1]
								else	
									(color 230 230 230 0 )*theMultipliers[iteration+1]
						)	
						setPixels theBitmap [0,i] thePixels 
					)
					
					copy theBitmap theDisplay 
					theBitmap = undefined
					pushprompt ("PRT Graph Updated in " + (timestamp()-st) as string + "ms.")
					updateTimeInGraph()
				)
				else
				(
					if mode == #customRange then
					(
						local theStartFrame = animationRange.start
						local theEndFrame = animationRange.end
						local hasStarted = false
						local cnt = 0
						for i = loopstartFrame to loopendFrame do
						(
							cnt += 1
							if not hasStarted and totalErrors[cnt] do 
							(
								hasStarted = true
								theStartFrame = i
							)
							if hasStarted and not totalErrors[cnt] do
							(
								theEndFrame = i-1
								exit
							)
						)
						return #(theStartFrame,theEndFrame)
					)
					if mode == #DisableInRender then
					(
						for i = 1 to fileListFlags.count do
							fileListFlags[i] = bit.set fileListFlags[i] 2 (amax errorsArray[i] == 0)
						params.UpdateGUI()	
						updateGraphLines draw:true
					)
				)	
			)--end if	
		)
		
		fn updateGraphCounts =
		(
			local st = timestamp()
			if countdisplay.open == true do
			(
				local loopstartFrame = animationrange.start.frame as integer
				local loopendFrame = animationrange.end.frame as integer
				local totalSizes = for i = loopstartFrame  to loopendFrame collect -1
				local errorsArray = for i = loopstartFrame  to loopendFrame collect 0
				local unknownSizes = for i = loopstartFrame  to loopendFrame collect false
				local theSegmentCount = fileList.count
				local currentSegment = 0.0
				for aFile in fileList do
				(
					local theSizes = #()
					local theName = aFile
					for t = loopstartFrame  to loopendFrame do
					(
						prg_graphprogress.value = 100.0 * currentSegment / theSegmentCount + 100.0 / theSegmentCount *  (t-loopstartFrame)/(loopendFrame-loopstartFrame) 
						windows.processPostedMessages()
						if not loadSingleFrame do
						(
							theTime = t + frameOffset 
							if enablePlaybackGraph do
							(
								theTime = at time theTime ((floor (playbackGraphTime+0.5)) as integer)
							)
							if limitToRange do
							(
								if theTime > rangeEndFrame do theTime = rangeEndFrame
								if theTime < rangeStartFrame do
								(
								 	theTime = rangeStartFrame
								 )
							)
							theName = FranticParticles.ReplaceSequenceNumber aFile theTime 
						)	
						if doesFileExist theName then
						(
							try(theVal = FranticParticles.GetFileParticleCount theName)catch(theVal = undefined )
							case theVal of
							(
								undefined: (
										append theSizes -1
										errorsArray[theSizes.count] += 1								
									)
								(-1): (
										append theSizes 0
										if totalSizes[theSizes.count] < 0 do totalSizes[theSizes.count] = -2								
										unknownSizes[theSizes.count] = true
									)
								default: (
										append theSizes theVal
										if totalSizes[theSizes.count] < 0 do totalSizes[theSizes.count] = 0
										totalSizes[theSizes.count] += theVal
									)
							)
						)
						else	
						(
							append theSizes -1
							errorsArray[theSizes.count] += 1								
						)					
					)--end t loop
					currentSegment += 1.0
				)--end aFile loop
				prg_graphprogress.value	= 0
				
				local theHeight = 80.0
				local theBGColor = ((colorman.getColor #background)*255 ) as color
				theBGColor.alpha = 0
				local theBitmap = bitmap (totalSizes.count) (theHeight+1) color:theBGColor
				
				local theMinVal = amin totalSizes	
				if theMinVal < 0 do theMinVal = 0
				local theMaxVal = amax totalSizes
				local theScale = 1.0
				if theMaxVal != 0 do theScale = theHeight / theMaxVal 
	
				for i = 1 to totalSizes.count do 
				(
					if totalSizes[i] == -1 do
						for y = 0.0 to theHeight  do setPixels theBitmap [i-1,theHeight-y] #((color 200 0 0 0) *(1.0-y/theHeight) + theBGColor*y/theHeight )
					if unknownSizes[i] == true do
						for y = 0.0 to theHeight  do setPixels theBitmap [i-1,theHeight-y] #((color 0 200 0 0 )*(1.0-y/theHeight) + theBGColor*y/theHeight )			
				
					if totalSizes[i] >= 0 then
					(
						theHValue = (totalSizes[i] * theScale)
						if theHValue < 3 do theHValue = 3		
						for y = 0 to theHValue do
						(
							if errorsArray[i] > 0 then
								setPixels theBitmap [i-1,theHeight-y] #(color 230 0 0)
							else						
								setPixels theBitmap [i-1,theHeight-y] #(color 0 230 0)
						)	
					)		
				)
				local theAverage = 0
				local theCount = 0
				for i in totalSizes where i >= 0 do ( theAverage += i; theCount += 1)
				if theCount > 0 then theAverage /= theCount else theAverage = 0
				
				copy theBitmap theDisplay 
				theBitmap = undefined
				
				local theXScale = (1.0*bmp_graph.width) / (loopendFrame - loopstartFrame + 1)
				cnt = 0
				for i = loopstartFrame to loopendFrame do
				(
					cnt += theXScale 
					if floor(i/10) == i/10.0 do
					(
						for v = 0 to 79 do
						(
							thePixels = (getPixels theDisplay [cnt-theXScale ,v] 1)[1]
							if try(thePixels.a == 0)catch(false) do
								setPixels theDisplay [1+cnt-theXScale ,v ] #(color 165 165 180 0)
						)
					)	
				)
				pushprompt ("PRT Graph Updated in " + (timestamp()-st) as string + "ms.")
				updateTimeInGraph()
			)	
		)--end fn 
		fn updateGraph = 
		(
			case graphMode of
			(
				1: updateGraphLines()
				2: updateGraphCounts()
			)	
		)	
		
		on ddl_graphMode selected itm do 
		(
			graphMode = itm
			if autoUpdateGraph do updateGraph()
		)	
		
		on btn_graphUpdate click arg do updateGraph()
		on btn_disableMissingSequences click arg do updateGraphLines draw:false mode:#DisableInRender
		
		fn updateInfo =
		(
			if countdisplay.open == true do
			(
				chk_infoHeader03.checked = showCountInViewport > 0

				if fileList.count == 0 then
				(
					bmp_stateIndicator.bitmap = noFilesBitmap
					edt_info01.text = edt_info02.text = edt_info03.text = "none"
				)
				else
				(
					pcount = delegate.getParticleCount()
					if pcount == -1 then pcount = "???" else pcount = FranticParticleRenderMXS.addCommas (pcount as string)
					edt_info01.text = pcount 

					pcount = delegate.GetParticleCountRender()
					if pcount == -1 then pcount = "???" else pcount = FranticParticleRenderMXS.addCommas (pcount as string)
					edt_info02.text =pcount 
					
					pcount = delegate.GetParticleCountView()
					if pcount == -1 then pcount = "???" else pcount = FranticParticleRenderMXS.addCommas (pcount as string)
					edt_info03.text = pcount 
				)	
			)
		)		
		
	
		on chk_infoHeader03 changed state do
		(
			--This is for backwards compatibility - originally, values of 1 and 2 were Show Disk and Render counts respectively.
			--These were removed in v1.1 to speed things up - now only the view count can be seen in the viewport.
			if state then showCountInViewport = 3 else showCountInViewport = 0
		)		
		
		on edt_info01 changed txt do updateInfo()
		on edt_info02 changed txt do updateInfo()
		on edt_info03 changed txt do updateInfo()
		
		fn displayLastErrorMessage =
		(
			if delegate.LastErrorMessage != "" do
				messagebox delegate.LastErrorMessage title:"Krakatoa Particle Loader - Last Error Message"
		)
		
		on btn_infoUpdate click arg do 
		(
			updateInfo()
			displayLastErrorMessage()
		)	
		
		fn updateLayout =
		(
			btn_graphUpdate.FlatStyle = btn_disableMissingSequences.FlatStyle = btn_infoUpdate.FlatStyle = btn_infoUpdate.FlatStyle.System
			btn_graphUpdate.width = edt_info01.width = edt_info02.width = edt_info03.width = btn_infoUpdate.width = countdisplay.width-70
			btn_graphUpdate.pos.x = edt_info01.pos.x = edt_info02.pos.x = edt_info03.pos.x = btn_infoUpdate.pos.x = 64
			
			bmp_graph.width = ddl_graphMode.width = countdisplay.width - 8
			bmp_graph.pos.x = ddl_graphMode.pos.x = 4
			
			btn_disableMissingSequences.width = countdisplay.width - 16
			btn_disableMissingSequences.pos.x = 10
			
			theDisplay = bitmap bmp_graph.width 80 color:((colorman.getColor #background)*255)
			theGraphDisplay = bitmap bmp_graph.width 80 color:((colorman.getColor #background)*255)
		)
		
		on countdisplay open do 
		(
			if (maxVersion())[1] > 20000 do countdisplay.autoLayoutOnResize = autoLayoutOnResizeOn() --the property is not available in 2018 and earlier, and is broken in 2020.1
			updateLayout()
			ddl_graphMode.selection = graphMode
			chk_autoUpdateGraph.state = autoUpdateGraph
			if autoUpdateGraph do updateGraph()
			updateInfo()
		)	
		
		on chk_autoUpdateGraph changed state do 
		(
			autoUpdateGraph = state
			if state do updateGraph()
		)	
		
	)	


	fn showState theState =
	(
		if selection.count > 0 and selection[1].baseobject == this and countdisplay.open == true then
		(
			--format "% showState  %\n" localtime theState 
			if fileList.count > 0 then
			(
				countdisplay.bmp_stateIndicator.bitmap = case theState of
				(
					default: noFilesBitmap --white*0.5
					0: noErrorBitmap 
					1: errorBitmap
				)
			)	
			countdisplay.updateInfo()
			countdisplay.updateTimeInGraph()		
		)	
	)
	
	tool create 
	( 
		on mousePoint click do
		case click of
		(
			1: nodeTM.translation = gridPoint
			2: (
				local thePref = getIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "Preferences" "CreateLoadersBehavior"
				if thePref != "3" do try(params.btn_addFiles.pressed())catch()
				#stop
			)	
		)
		
		on mouseMove click do
		case click of
		(
			2: (
				iconSize = (length gridDist)*0.7
				gizmoBoxX = 2.2592 * iconSize
				gizmoBoxY = 1.7748 * iconSize
				gizmoBoxZ = 3 * iconSize
				)
		)
	) 
	
	on create do
	(
		isCreating = true
		params.UpdateGUI()	
		theVal = execute (getIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "PRTLoaders" "UsePreset")
		if theVal == true do
		(
			thePresetFile= (getIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "PRTLoaders" "PresetName" )
			theFullPresetFile =  (Krakatoa_PresetsDirectory+ "\\presets\\" + thePresetFile + ".KPS")
			if doesFileExist theFullPresetFile do 
			(
				presets_rollout.loadPreset theFullPresetFile 	
				customPresetName = thePresetFile
			)	
		)
		isCreating = false
		delegate.SetScriptedOwner this
		
		
		/*////////////////////// RealFlow legacy load hack ///////////////////*/
		setProperty this "useLegacyRealflowBinLoading" false
		/*////////////////////////////////////////////////////////////////////*/
	)

	on Load do 
	( 
		delegate.SetScriptedOwner this 
		if fileListFlags.count != fileList.count do for i = 1 to fileList.count do fileListFlags[i] = 3
	)
	on clone oldObj do 
	( 
		delegate.SetScriptedOwner this 
	)
	

	/*
	on detachedFromNode theNode do
	(
		for i = fileList.count to 1 by -1 do 
		(
			local theFile = fileList[i]
			local AllFiles = getFiles (getFileNamePath theFile + substring (getFileNameFile theFile ) 1 ((getFileNameFile theFile ).count-4) + "*" + getFileNameType theFile )
			for f in AllFiles do ATSCustomDepsOps.RemoveFileByName f
		)			
		atsOps.Refresh()							
	)
	*/
	
)--end plugin
--END PRT LOADER CODE


--------------------------------