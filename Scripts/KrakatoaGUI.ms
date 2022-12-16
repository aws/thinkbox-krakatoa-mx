-- Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
-- SPDX-License-Identifier: Apache-2.0
-- In case Deadline is in use, the Deadline interfaces need to be declared global.
global SMTDSettings, SMTDFunctions, FranticParticleRenderMXS, SMTDPaths, XMLSceneUtils
global FranticParticleRenderInitCheck 
global KrakatoaChannelsModifier, KrakatoaChannelNodeEditor_Rollout, KrakatoaChannelsEditor_Functions, KrakatoaChannelNodeEditor_Rollout_MainMenu
global Krakatoa_GUI_ShaderDynamic
global Krakatoa_CustomizeRollouts_Dialog, Krakatoa_GUI_Value_History_Dialog
global Krakatoa_ThumbnailsPreviewStrip_Rollout_Left, Krakatoa_ThumbnailsPreviewStrip_Rollout_Right
global KrakatoaGlobalDataHolder, KrakatoaMXGlobalDataHolder, MagmaFlowEditor_Functions
global Krakatoa_SceneExplorersFloater
global KrakatoaChannelNodeEditor_CurrentModifier, KrakatoaChannelEditor_BaseNodeTreeData, KrakatoaChannelEditor_NodeTreeData
global KrakatoaPostRenderCacheableSettings = undefined
global KrakatoaGUIOpeningManually = false
global KrakatoaLastRendererStorage 
if KrakatoaLastRendererStorage == undefined do 
	KrakatoaLastRendererStorage = #()
global KrakatoaAtmosphericEffects_DialogsArray
if KrakatoaAtmosphericEffects_DialogsArray == undefined do 
	KrakatoaAtmosphericEffects_DialogsArray = #()

global Krakatoa_HashSubAnims = #()

--global Krakatoa_PRTIgnoreMissingFrames = false

global Krakatoa_PresetsDirectory = (dotnetclass "System.Environment").GetFolderPath (dotnetclass "System.Environment+SpecialFolder").LocalApplicationData + "\\Thinkbox\\Krakatoa"
makeDir (Krakatoa_PresetsDirectory  + "\\presets") all:true
makeDir (Krakatoa_PresetsDirectory  + "\\history") 
makeDir (Krakatoa_PresetsDirectory  + "\\samples")
makeDir (GetDir #plugcfg + "\\Krakatoa") all:true


global Krakatoa_PresetsArrowBitmap, Krakatoa_PresetsArrowBitmap_Base
global Krakatoa_updateSchematicFlow

global Krakatoa_Closing_Floater = false
global Krakatoa_Initializing_Hidden_Rollouts = false
global Krakatoa_PresetIniFile
global Krakatoa_PresetDialogMode = #save
global Krakatoa_SavePresetDialog    	--the dialog rollout
global Krakatoa_DoExportTable = #() --list of rollout controls flags (true to save, false to skip)
global Krakatoa_ObjectsTable = #()  	--list of rollout controls to save
global Krakatoa_IsRendering = false  	--set by the local partitioning code to avoid the call of initialization function and associated prints to Log window
global Krakatoa_VFB_Overlay_Rollout, Krakatoa_VFB_Left_Rollout, Krakatoa_VFB_Right_Rollout --rollouts of the VFB Overlay in Max 2009 and higher
global Krakatoa_CustomizeRollouts_Dialog 

(
	--CUSTOM SKIN COLORS
	struct KrakatoaSkinColorsStructDef 
	(
		UseCustomColors = false,
		History = white,
		Main = color 255 200 150,
		Channels = white,
		Partitioning = color 200 255 200,
		Systems = color 255 200 150,
		Loaders = color 255 200 255,
		Thinking = color 255 150 200,
		Matte = color 255 255 200,
		APME = white,
		Preferences = white,
		VFB = color 255 200 150,
		GlobalRenderValues = color 255 200 150,
		ShaderParameters = color 255 200 150
	)
	global KrakatoaSkinColorsStruct = KrakatoaSkinColorsStructDef()
)

global Krakatoa_LoadSkinColors 
fn Krakatoa_LoadSkinColors =
(
	local theDefaultColor =  ((colorman.getColor #activeCommand)*255) as color
	local KrakatoaPreferencesINI = (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini" )
	local theValue  = execute (getIniSetting KrakatoaPreferencesINI "SkinColors" "UseCustomColors")
	KrakatoaSkinColorsStruct.UseCustomColors = if theValue == OK then false else theValue

	theValue = execute (getIniSetting KrakatoaPreferencesINI "SkinColors" "History")
	KrakatoaSkinColorsStruct.History = if KrakatoaSkinColorsStruct.UseCustomColors and classof theValue == Color then theValue else theDefaultColor

	theValue = execute (getIniSetting KrakatoaPreferencesINI "SkinColors" "Main")
	KrakatoaSkinColorsStruct.Main = if KrakatoaSkinColorsStruct.UseCustomColors and classof theValue == Color then theValue else theDefaultColor
	
	theValue = execute (getIniSetting KrakatoaPreferencesINI "SkinColors" "Channels")
	KrakatoaSkinColorsStruct.Channels = if KrakatoaSkinColorsStruct.UseCustomColors and classof theValue == Color then theValue else theDefaultColor
	
	theValue = execute (getIniSetting KrakatoaPreferencesINI "SkinColors" "Partitioning") 
	KrakatoaSkinColorsStruct.Partitioning = if KrakatoaSkinColorsStruct.UseCustomColors and classof theValue == Color then theValue else theDefaultColor

	theValue = execute (getIniSetting KrakatoaPreferencesINI "SkinColors" "Systems") 
	KrakatoaSkinColorsStruct.Systems = if KrakatoaSkinColorsStruct.UseCustomColors and classof theValue == Color then theValue else theDefaultColor

	theValue = execute (getIniSetting KrakatoaPreferencesINI "SkinColors" "Loaders") 
	KrakatoaSkinColorsStruct.Loaders = if KrakatoaSkinColorsStruct.UseCustomColors and classof theValue == Color then theValue else theDefaultColor

	theValue = execute (getIniSetting KrakatoaPreferencesINI "SkinColors" "Thinking") 
	KrakatoaSkinColorsStruct.Thinking = if KrakatoaSkinColorsStruct.UseCustomColors and classof theValue == Color then theValue else theDefaultColor

	theValue = execute (getIniSetting KrakatoaPreferencesINI "SkinColors" "Matte") 
	KrakatoaSkinColorsStruct.Matte = if KrakatoaSkinColorsStruct.UseCustomColors and classof theValue == Color then theValue else theDefaultColor


	theValue = execute (getIniSetting KrakatoaPreferencesINI "SkinColors" "APME") 
	KrakatoaSkinColorsStruct.APME = if KrakatoaSkinColorsStruct.UseCustomColors and classof theValue == Color then theValue else theDefaultColor

	theValue = execute (getIniSetting KrakatoaPreferencesINI "SkinColors" "Preferences")  
	KrakatoaSkinColorsStruct.Preferences = if KrakatoaSkinColorsStruct.UseCustomColors and classof theValue == Color then theValue else theDefaultColor
		
	theValue = execute (getIniSetting KrakatoaPreferencesINI "SkinColors" "VFB")  
	KrakatoaSkinColorsStruct.VFB = if KrakatoaSkinColorsStruct.UseCustomColors and classof theValue == Color then theValue else theDefaultColor

	theValue = execute (getIniSetting KrakatoaPreferencesINI "SkinColors" "GlobalRenderValues")  
	KrakatoaSkinColorsStruct.GlobalRenderValues = if KrakatoaSkinColorsStruct.UseCustomColors and classof theValue == Color then theValue else theDefaultColor

	theValue = execute (getIniSetting KrakatoaPreferencesINI "SkinColors" "ShaderParameters")  
	KrakatoaSkinColorsStruct.ShaderParameters = if KrakatoaSkinColorsStruct.UseCustomColors and classof theValue == Color then theValue else theDefaultColor
	
	true
)

Krakatoa_LoadSkinColors()

--------------------------------------------------
--GLOBAL VARIABLE DEFINITIONS--
--------------------------------------------------

global Krakatoa_GUI_Main, Krakatoa_GUI_Target, Krakatoa_GUI_SaveParticles 
global Krakatoa_GUI_MatteObjects, Krakatoa_GUI_Partition, Krakatoa_GUI_Presets, Krakatoa_GUI_Notes, Krakatoa_GUI_ParticleLoaders, Krakatoa_GUI_PRTHairExplorer, Krakatoa_GUI_PRTFumeFXExplorer, Krakatoa_GUI_Particles --, Krakatoa_GUI_Shadows
global Krakatoa_GUI_History_Dialog, Krakatoa_GUI_AmbientPME, Krakatoa_GUI_Channels, Krakatoa_GUI_ThinkingParticles, Krakatoa_GUI_RenderGlobalValues
global Krakatoa_GUI_FileSortingProgress_Dialog
global Krakatoa_GUI_About
global Krakatoa_Gui_floater, Krakatoa_Gui_floater_2, Krakatoa_Gui_floater_3
global Krakatoa_Preferences_Floater, Krakatoa_GUI_Preferences_Colors, Krakatoa_GUI_Preferences_System, Krakatoa_GUI_Preferences, Krakatoa_GUI_KSRExporter_Preferences
global Krakatoa_SeedIncrement_UserFunction
global Krakatoa_SeedIncrement_LastValue

try(closeRolloutFloater Krakatoa_Gui_floater) catch()
try(closeRolloutFloater Krakatoa_GUI_Floater_2)catch()
if Krakatoa_GUI_Floater_2 == undefined do
	Krakatoa_GUI_Floater_2 = newRolloutFloater "Krakatoa Secondary Floater" 10 10 10 10
try(closeRolloutFloater Krakatoa_GUI_Floater_2)catch()

try(destroyDialog Krakatoa_GUI_Notes)catch()	
try(destroyDialog Krakatoa_GUI_About)catch()	
try(closeRolloutFloater Krakatoa_SceneExplorersFloater)catch()				
try(closeRolloutFloater Krakatoa_Preferences_Floater)catch()

--Make sure MAXScript has enough Heap Memory for complex stuff. Default is 7.5MB, we give it 32MB.
if heapSize < 33554432 do heapSize = 33554432
	


rollout Krakatoa_GUI_FileSortingProgress_Dialog "Krakatoa: Collecting And Sorting Data"
(
	label lbl_feedback "" align:#center
	progressbar prg_progress color:blue height:10 align:#center visible:false
)	


rollout Krakatoa_GUI_ShaderDynamic "Shader Parameters" category:8 width:460 ( ) --standin
	

--------------------------------------------------------------------------------------------------------------------------------------------------------------------	
--CUSTOMIZE GUI ROLLOUT	
--------------------------------------------------------------------------------------------------------------------------------------------------------------------	

rollout Krakatoa_CustomizeRollouts_Dialog "Manage Krakatoa GUI Rollouts" category:0 rolledup:true
(
	local hiddenRollouts = #()
	local visibleRollouts = #()
	
	button btn_Help_ManageRollouts  "Open Online Help..." height:16 width:100 align:#left offset:[-10,-5] across:2 tooltip:"Opens the Krakatoa Online Help for the Manage Krakatoa GUI Rollouts rollout in the default Web Browser. Requires Internet connection."
	button btn_BackTo_Main "Back To Main Controls..." height:16 width:350 offset:[10,-5] align:#right tooltip:"Closes the rollout and sets focus on the Main Controls rollout."

	on btn_BackTo_Main pressed do
	(
		Krakatoa_CustomizeRollouts_Dialog.open = false
		FranticParticleRenderMXS.BackToMainControls()
	)		
	
	on btn_BackTo_Main rightclick do
	(
		Krakatoa_CustomizeRollouts_Dialog.open = false
		FranticParticleRenderMXS.BackToMainControls()
	)			
	
	
	edittext edt_RolloutVisibilityPreset across:4 align:#left offset:[-10,0]  width:175
	button btn_saveVisibilityPreset "SAVE" align:#center offset:[28,0] width:40 height:18
	dropdownlist ddl_rolloutVisibilityPreset  align:#center offset:[45,-1] width:175 tooltip:"Custom Rollout Presets..."
	button btn_loadVisibilityPreset "LOAD" align:#right width:40 offset:[12,0] height:18
	
	multilistbox lbx_hiddenRollouts "Hidden Rollouts" across:2 height:10 offset:[-10,0] 
	multilistbox lbx_visibleRollouts "Visible Rollouts [F]loat [D]ocked [S]econdary" height:10 offset:[10,0]
	
	button btn_selectAllHidden "All" 				width:42 height:20 align:#left offset:[-10,-5] across:10 tooltip:"Select ALL Hidden Rollouts"
	button btn_selectInvertHidden "Invert" 	width:42 height:20 align:#left offset:[-10,-5] tooltip:"INVERT the Hidden Rollouts Selection"
	button btn_selectDockedHidden "Sel.[D]" 		width:42 height:20 align:#left offset:[-10,-5] tooltip:"Select Hidden Rollouts that are DOCKED."
	button btn_selectFloatingHidden "Sel.[F]" 	width:42 height:20 align:#left offset:[-10,-5] tooltip:"Select Hidden Rollouts that are FLOATED."
	button btn_selectSecondaryHidden "Sel.[S]" width:42 height:20 align:#left offset:[-10,-5] tooltip:"Select Hidden Rollouts that are Docked to the SECONDARY Floater."

	button btn_selectAllVisible "All" 				width:42 height:20 align:#right offset:[10,-5] tooltip:"Select ALL Visible Rollouts"
	button btn_selectInvertVisible "Invert" 	width:42 height:20 align:#right offset:[10,-5] tooltip:"INVERT the Visible Rollouts Selection"
	button btn_selectDockedVisible "Sel.[D]" 		width:42 height:20 align:#right offset:[10,-5] tooltip:"Select Visible Rollouts that are DOCKED."
	button btn_selectFloatingVisible "Sel.[F]" 		width:42 height:20 align:#right offset:[10,-5] tooltip:"Select Visible Rollouts that are FLOATED."
	button btn_selectSecondaryVisible "Sel.[S]" 	width:42 height:20 align:#right offset:[10,-5] tooltip:"Select Visible Rollouts that are Docked to the SECONDARY Floater."
	

	button btn_dockHidden "Dock" 				width:71 height:20 align:#left offset:[-10,-3] across:6 tooltip:"Set Selected Hidden Rollouts To DOCKED. Will affect a rollout when it is unhidden."
	button btn_floatHidden "Float" 				width:70 height:20 align:#left offset:[-9,-3] tooltip:"Set Selected Hidden Rollouts To FLOATING. Will affect a rollout when it is unhidden."
	button btn_secondaryHidden "Secondary" width:71 height:20 align:#left offset:[-9,-3] tooltip:"Set Selected Hidden Rollouts To Docked To SECONDARY Floater. Will affect a rollout when it is unhidden."
	
	button btn_dockVisible "Dock" 				width:71 height:20 align:#right offset:[13,-3] tooltip:"Set Selected Visible Rollouts To DOCKED."
	button btn_floatVisible "Float" 				width:70 height:20 align:#right offset:[13,-3] tooltip:"Set Selected Visible Rollouts To FLOATING."
	button btn_secondaryVisible "Secondary" width:71 height:20 align:#right offset:[14,-3] tooltip:"Set Selected Visible Rollouts To Docked To SECONDARY Floater."
	
	button btn_moveRight ">" width:20 height:50 pos:[219,80] 
	button btn_moveLeft "<" width:20 height:50 pos:[219,130] 
	
	fn updateIcons =
	(
		btn_moveRight.images = #(Krakatoa_PresetsArrowBitmap,Krakatoa_PresetsArrowBitmap, 32,6,6,8,8)
		btn_moveLeft.images = #(Krakatoa_PresetsArrowBitmap,Krakatoa_PresetsArrowBitmap, 32,7,7,9,9)
	)
	
	local allRollouts = #(
			Krakatoa_GUI_Presets, 
			Krakatoa_GUI_RenderGlobalValues,
			Krakatoa_GUI_ShaderDynamic, 
			Krakatoa_GUI_Main, 
			Krakatoa_GUI_SaveParticles,
			Krakatoa_GUI_Channels, 
			Krakatoa_GUI_Partition, 
			Krakatoa_GUI_MatteObjects, 
			Krakatoa_GUI_AmbientPME
	)	
	
	fn Refresh_GUI =
	(
		hiddenRollouts = #()
		visibleRollouts = #()		
		local allRollouts = #(
				Krakatoa_GUI_Presets, 
				Krakatoa_GUI_RenderGlobalValues,
				Krakatoa_GUI_Main, 
				Krakatoa_GUI_ShaderDynamic, 			
				Krakatoa_GUI_SaveParticles,
				Krakatoa_GUI_Channels, 
				Krakatoa_GUI_Partition, 
				Krakatoa_GUI_MatteObjects, 
				Krakatoa_GUI_AmbientPME
		)	
			

		for i in allRollouts do
		(
			local theState =  execute (getIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "RolloutVisible" i.title) 
			if theState == OK do theState = true
			if theState then append visibleRollouts i else append hiddenRollouts i  
		)
		lbx_hiddenRollouts.items = for i in hiddenRollouts collect 
		(
			local theDockedState = execute (getIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "RolloutDocked" i.title) 
			if theDockedState == OK then theDockedState = true
			local theDockString = "F"
			if theDockedState then 
			(
				theDockString = "D" 
				local theDockHost = (getIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "RolloutDockHost" i.title) 	
				if theDockHost == "2" do theDockString = "S"
			)
			"["+theDockString+"] " + i.title
		)	
		lbx_visibleRollouts.items = for i in visibleRollouts collect 
		(
			local theDockedState = execute (getIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "RolloutDocked" i.title) 
			if theDockedState == OK then theDockedState = true
			local theDockString = "F"
			if theDockedState then 
			(
				theDockString = "D" 
				local theDockHost = (getIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "RolloutDockHost" i.title) 	
				if theDockHost == "2" do theDockString = "S"
			)
			"["+theDockString+"] " + i.title
		)	
		
		local theLayoutPresetFiles = getFiles (Krakatoa_PresetsDirectory + "\\*.krl")
		local theArray = for i in theLayoutPresetFiles collect (getFileNameFile i)
		theArray  = join #("") theArray 
		ddl_rolloutVisibilityPreset.items = theArray 
	)

	fn moveRight =
	(
		local theArray = lbx_hiddenRollouts.selection as array
		local HiddenArray = for i in hiddenRollouts collect i
		for i = theArray.count to 1 by -1 do
		(			
			setIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "RolloutVisible" HiddenArray[theArray[i]].title "true"
			try(destroyDialog HiddenArray[theArray[i]])catch()
			try(removeRollout HiddenArray[theArray[i]] Krakatoa_Gui_floater_3)catch()
			--addRollout hiddenRollouts[theArray[i]] Krakatoa_Gui_floater rolledup:false
			
			local theState = execute (getIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "RolloutDocked" HiddenArray[theArray[i]].title)
			local theHost = (getIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "RolloutDockHost" HiddenArray[theArray[i]].title)
			if theState != false then
			(
				if theHost == "2" then
					FranticParticleRenderMXS.floatOrDockRollout HiddenArray[theArray[i]] forceMode:#dock2
				else
					FranticParticleRenderMXS.floatOrDockRollout HiddenArray[theArray[i]] forceMode:#dock
			)	
			else
				FranticParticleRenderMXS.floatOrDockRollout HiddenArray[theArray[i]] forceMode:#float
		)	
		Refresh_GUI()			
	)
	fn moveLeft =
	(
		local theArray = lbx_visibleRollouts.selection as array
		local VisibleArray = for i in visibleRollouts collect i
		for i = theArray.count to 1 by -1 do
		(
			setIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "RolloutVisible" VisibleArray[theArray[i]].title "false"
			try(destroyDialog VisibleArray[theArray[i]])catch()
			try(removeRollout VisibleArray[theArray[i]] Krakatoa_Gui_floater)catch()
			try(removeRollout VisibleArray[theArray[i]] Krakatoa_Gui_floater_2)catch()
			addRollout VisibleArray[theArray[i]] Krakatoa_Gui_floater_3 --MOVING TO HIDDEN FLOATER
		)	
		if Krakatoa_Gui_floater_2.rollouts.count == 0 do closeRolloutFloater Krakatoa_Gui_floater_2		
		Refresh_GUI()
	)
	
	fn updateHidden =
	(
		local RolloutsToUpdate = #(
				Krakatoa_GUI_RenderGlobalValues,
				Krakatoa_GUI_Main, 
				Krakatoa_GUI_SaveParticles, 
				Krakatoa_GUI_Channels, 
				Krakatoa_GUI_Partition, 
				Krakatoa_GUI_MatteObjects,  
				Krakatoa_GUI_AmbientPME
		)			
		global Krakatoa_Initializing_Hidden_Rollouts = true
		if Krakatoa_GUI_Floater_3  == undefined do Krakatoa_GUI_Floater_3  = newRolloutFloater "Krakatoa OFF" 480 100 -10000 -10000
		try(Krakatoa_GUI_Floater_3.visible = false)catch()
		for i in RolloutsToUpdate do
		(	
			local currentState =  execute (getIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "RolloutVisible" i.title ) 
			if currentState == OK do currentState = true
			if not currentState or Krakatoa_GUI_Floater == undefined or Krakatoa_GUI_Floater.open == false do 
			(
				if findItem Krakatoa_GUI_Floater_3.rollouts i == 0 do addRollout i Krakatoa_GUI_Floater_3 
			)	
		)	
		global Krakatoa_Initializing_Hidden_Rollouts = false
	)
	
	on btn_floatAll pressed do
	(
		for i in allRollouts do
		(	
			local currentState =  execute (getIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "RolloutDocked" i.title ) 
			if currentState == OK do currentState = true
			if currentState do FranticParticleRenderMXS.floatOrDockRollout i forceMode:#float
		)	
		Refresh_GUI()
	)
	on btn_dockAll pressed do
	(
		for i in allRollouts do
		(
			local currentState =  execute (getIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "RolloutDocked" i.title ) 
			if currentState == OK do currentState = true
			if not currentState do FranticParticleRenderMXS.floatOrDockRollout i forceMode:#dock
		)		
		Refresh_GUI()
	)		
	on btn_toggleDockFloatAll pressed do
	(
		for i in allRollouts do
			FranticParticleRenderMXS.floatOrDockRollout i forceMode:#none
		Refresh_GUI()
	)			


	
	on btn_selectAllHidden pressed do
	(
		lbx_hiddenRollouts.selection = #{1..lbx_hiddenRollouts.items.count}
	)
	on btn_selectInvertHidden pressed do
	(
		lbx_hiddenRollouts.selection = -lbx_hiddenRollouts.selection
	)
	on btn_selectDockedHidden pressed do 
	(
		lbx_hiddenRollouts.selection = for i = 1 to lbx_hiddenRollouts.items.count where matchPattern lbx_hiddenRollouts.items[i] pattern:"*[D]*" collect i
	)
	on btn_selectFloatingHidden pressed do 
	(
		lbx_hiddenRollouts.selection = for i = 1 to lbx_hiddenRollouts.items.count where matchPattern lbx_hiddenRollouts.items[i] pattern:"*[F]*" collect i
	)	
	on btn_selectSecondaryHidden pressed do 
	(
		lbx_hiddenRollouts.selection = for i = 1 to lbx_hiddenRollouts.items.count where matchPattern lbx_hiddenRollouts.items[i] pattern:"*[S]*" collect i
	)
	
	on btn_dockHidden pressed do
	(
		for i in lbx_hiddenRollouts.selection do
		(
			setIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "RolloutDocked" hiddenRollouts[i].title "true"
			setIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "RolloutDockHost" hiddenRollouts[i].title "1"
		)
		Refresh_GUI()
	)		
	on btn_floatHidden pressed do
	(
		for i in lbx_hiddenRollouts.selection do
		(
			setIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "RolloutDocked" hiddenRollouts[i].title "false"
		)
		Refresh_GUI()
	)		
	on btn_secondaryHidden pressed do
	(
		for i in lbx_hiddenRollouts.selection do
		(
			setIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "RolloutDocked" hiddenRollouts[i].title "true"
			setIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "RolloutDockHost" hiddenRollouts[i].title "2"
		)
		Refresh_GUI()
	)		
	
	
	
	
	on btn_selectAllVisible pressed do
	(
		lbx_visibleRollouts.selection = #{1..lbx_visibleRollouts.items.count}
	)
	on btn_selectInvertVisible pressed do
	(
		lbx_visibleRollouts.selection = -lbx_visibleRollouts.selection
	)	
	on btn_selectDockedVisible pressed do 
	(
		lbx_visibleRollouts.selection = for i = 1 to lbx_visibleRollouts.items.count where matchPattern lbx_visibleRollouts.items[i] pattern:"*[D]*" collect i
	)
	on btn_selectFloatingVisible pressed do 
	(
		lbx_visibleRollouts.selection = for i = 1 to lbx_visibleRollouts.items.count where matchPattern lbx_visibleRollouts.items[i] pattern:"*[F]*" collect i
	)	
	on btn_selectSecondaryVisible pressed do 
	(
		lbx_visibleRollouts.selection = for i = 1 to lbx_visibleRollouts.items.count where matchPattern lbx_visibleRollouts.items[i] pattern:"*[S]*" collect i
	)		
	on btn_dockVisible pressed do
	(
		local oldSel = lbx_visibleRollouts.selection
		local VisibleArray = for i in visibleRollouts collect i
		for i in lbx_visibleRollouts.selection do
			FranticParticleRenderMXS.floatOrDockRollout VisibleArray[i] forceMode:#dock
		Refresh_GUI()
		lbx_visibleRollouts.selection = oldSel
	)	
	on btn_floatVisible pressed do
	(
		local oldSel = lbx_visibleRollouts.selection
		local VisibleArray = for i in visibleRollouts collect i
		for i in oldSel do
			FranticParticleRenderMXS.floatOrDockRollout VisibleArray[i] forceMode:#float
		Refresh_GUI()
		lbx_visibleRollouts.selection = oldSel
	)		
	on btn_secondaryVisible pressed do
	(
		local oldSel = lbx_visibleRollouts.selection
		local VisibleArray = for i in visibleRollouts collect i
		for i in lbx_visibleRollouts.selection do
			FranticParticleRenderMXS.floatOrDockRollout VisibleArray[i] forceMode:#dock2
		Refresh_GUI()
		lbx_visibleRollouts.selection = oldSel
	)		
	
	on lbx_visibleRollouts doubleClicked itm do moveLeft()
	on lbx_hiddenRollouts doubleClicked itm do moveRight()
	
	on btn_moveLeft pressed do moveLeft()
	on btn_moveRight pressed do moveRight()
	
	on btn_saveVisibilityPreset pressed do
	(
		if edt_RolloutVisibilityPreset.text != "" do
		(
			local theSourceFile =(GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") 
			local theTargetFile = (Krakatoa_PresetsDirectory + "\\"+ edt_RolloutVisibilityPreset.text +".krl")
			for i in allRollouts do
			(
				local currentState =  execute (getIniSetting theSourceFile "RolloutDocked" i.title ) 
				if currentState == OK do currentState = true
				local currentVis = execute (getIniSetting theSourceFile "RolloutVisible" i.title ) 
				if currentVis == OK do currentVis = true
				local currentPos = getIniSetting theSourceFile "RolloutDialogPositions" i.title
				local currentHost = getIniSetting theSourceFile "RolloutDockHost" i.title
				if currentHost == "" do currentHost = "1"
				
				setIniSetting theTargetFile "RolloutVisible" i.title (currentVis as string)
				setIniSetting theTargetFile "RolloutDocked" i.title (currentState as string)
				setIniSetting theTargetFile "RolloutDockHost" i.title currentHost 
				setIniSetting theTargetFile "RolloutDialogPositions" i.title currentPos
			)					
			Refresh_GUI()
		)
	)
	on btn_loadVisibilityPreset pressed do
	(
		if ddl_rolloutVisibilityPreset.selected != "" do
		(
			local theTargetFile =(GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") 
			local theSourceFile= (Krakatoa_PresetsDirectory + "\\"+ ddl_rolloutVisibilityPreset.selected +".krl")
			
			for i in allRollouts do
			(
				local currentState =  execute (getIniSetting theSourceFile "RolloutDocked" i.title ) 
				if currentState == OK do currentState = true
				local currentVis = 	execute (getIniSetting theSourceFile "RolloutVisible" i.title ) 
				if currentVis == OK do currentVis = true
				local currentHost = (getIniSetting theSourceFile "RolloutDockHost" i.title ) 
				if currentHost == "" do currentHost = "1"
					
				setIniSetting theTargetFile "RolloutVisible" i.title (currentVis as string)
				setIniSetting theTargetFile "RolloutDocked" i.title (currentState as string)
				setIniSetting theTargetFile "RolloutDockHost" i.title currentHost 
				
				try(destroyDialog i)catch()
				try(removeRollout i Krakatoa_Gui_floater)catch()
				if currentVis then
				(
					if currentState then 
					(
						if currentHost == "2" then
							FranticParticleRenderMXS.floatOrDockRollout i forceMode:#dock2
						else	
							FranticParticleRenderMXS.floatOrDockRollout i forceMode:#dock
					)	
					else
						FranticParticleRenderMXS.floatOrDockRollout i forceMode:#float
				)	
			)					
		)
		Refresh_GUI()
	)		
	
	on ddl_rolloutVisibilityPreset selected itm do
	(
		edt_RolloutVisibilityPreset.text = ddl_rolloutVisibilityPreset.selected
	)
	
	fn updateStripsPositions pos =
	(
		if Krakatoa_Gui_floater == undefined or Krakatoa_Gui_floater_2 == undefined do return false
		local theState = execute (getIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "RolloutDocked" Krakatoa_GUI_Presets.title)
		local theHost = (getIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "RolloutDockHost" Krakatoa_GUI_Presets.title)
		local theLeftPos = pos
		local theRightPos = pos
		if theState != false then --it is docked!
		(
			if theHost == "2" then --if docked in secondary, the Pos = 
			(
				theRightPos = Krakatoa_Gui_floater_2.pos+[484,0]
				if FranticParticleRenderMXS.lockSecondaryToPrimaryFloater then
					theLeftPos = Krakatoa_Gui_floater.pos-[126,0]
				else
					theLeftPos = Krakatoa_Gui_floater_2.pos-[126,0]
			)
			else
			(
				if Krakatoa_Gui_floater_2.open then
					theRightPos = Krakatoa_Gui_floater_2.pos+[484,0]
				else
					theRightPos = Krakatoa_Gui_floater.pos+[484,0]
				
				theLeftPos = Krakatoa_Gui_floater.pos-[126,0]
			)
		)
		else
		(
			theLeftPos = (getDialogPos Krakatoa_GUI_Presets)-[126,0]
			theRightPos = (getDialogPos Krakatoa_GUI_Presets)+[462,0]
		)
		
		if Krakatoa_ThumbnailsPreviewStrip_Rollout_Left != undefined and Krakatoa_ThumbnailsPreviewStrip_Rollout_Left.open do
		(
			setDialogPos Krakatoa_ThumbnailsPreviewStrip_Rollout_Left theLeftPos
		)
		if Krakatoa_ThumbnailsPreviewStrip_Rollout_Right != undefined and Krakatoa_ThumbnailsPreviewStrip_Rollout_Right.open do
		(
			setDialogPos Krakatoa_ThumbnailsPreviewStrip_Rollout_Right theRightPos
		)
	)

	on Krakatoa_CustomizeRollouts_Dialog moved pos do 
	(
		FranticParticles.SetProperty "GUI:Position" (pos as string)
		setINIsetting (getDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "Dialog" "Position" (pos as string)
		--print Krakatoa_Gui_floater.placement

		if FranticParticleRenderMXS.lockSecondaryToPrimaryFloater do
		(
			if Krakatoa_GUI_Floater_2.placement != #minimized do 
				Krakatoa_GUI_Floater_2.pos = pos + [484,0]
			try(Krakatoa_Gui_floater_2.placement = Krakatoa_Gui_floater.placement)catch()
		)	
		updateStripsPositions pos
	)	
	on Krakatoa_CustomizeRollouts_Dialog resized size do 
	(
		FranticParticles.SetProperty "GUI:Size" (size as string)
		try(Krakatoa_GUI_Floater_2.size = size)catch()
	)
	
	on Krakatoa_CustomizeRollouts_Dialog close do
	(
		global Krakatoa_Closing_Floater = true
		
		for i in allRollouts do 
			try(destroyDialog i)catch()
		
		try(closeRolloutFloater Krakatoa_GUI_Floater_2)catch()
		try(closeRolloutFloater Krakatoa_GUI_Floater_3)catch()
		try(destroyDialog Krakatoa_GUI_Value_History_Dialog)catch()
		try(destroyDialog Krakatoa_GUI_ShaderDynamic)catch()
		try(destroyDialog Krakatoa_ThumbnailsPreviewStrip_Rollout_Left)catch()
		try(destroyDialog Krakatoa_ThumbnailsPreviewStrip_Rollout_Right)catch()
		
		global Krakatoa_Closing_Floater = false
		global KrakatoaGuiOpen = false
		updateToolbarButtons()
		FranticParticles.LogProgress "+Krakatoa GUI CLOSED."
		FranticParticles.LogProgress ("-----" +localtime + "--------------------------")
		FranticParticles.LogProgress ("                                                                 ")
	)
	
	on Krakatoa_CustomizeRollouts_Dialog open do
	(
		updateIcons()
		Refresh_GUI()
	)
)



--------------------------------------------------------------------------------------------------------------------------------------------------------------------	
--RIGHT CLICK CONTEXT MENUS
--------------------------------------------------------------------------------------------------------------------------------------------------------------------	
(
	global Krakatoa_RCMenu_Struct 
	struct Krakatoa_RCMenu_StructDef 
	(
		Float_Rollout_RCMenu,
		ParticleCache_RCMenu,
		RenderButton_RCMenu,
		IterativeOptions_RCMenu,
		History_FilterValue_RCMenu,
		Presets_RCMenu,
		Load_Save_Rollout_RCMenu,
		HistoryPatternOptions01_RCMenu,
		HistoryPatternOptions02_RCMenu,
		GlobalHolderOptions_RCMenu,
		PRTVolume_Options_RCMenu,
		PRTSurface_Options_RCMenu,
		PRTFumeFX_Options_RCMenu,
		PRTSource_Options_RCMenu,
		PRTHair_Options_RCMenu,
		
		SpecificLightRenderElement_Options_RCMenu,
		
		Float_Rollout_RCMenu_CurrentRollout,
		IterativeOptions_Selection="1",
		IterativeOptions_ScaleDensity = false,
		SpecificLightRenderElement_CurrentElement = undefined
	)
	Krakatoa_RCMenu_Struct = Krakatoa_RCMenu_StructDef()
	
	rcmenu SpecificLightRenderElement_Options_RCMenu
	(
		fn lightIsHidden =
		(
			try(Krakatoa_RCMenu_Struct.SpecificLightRenderElement_CurrentElement.lightNode.isHidden)catch(false)
		)		
		fn lightIsValid =
		(
			try(isValidNode Krakatoa_RCMenu_Struct.SpecificLightRenderElement_CurrentElement.lightNode)catch(false)
		)		
		
		menuItem lightObject_select "Select Light..." enabled:(lightIsValid())
		separator sep_10
		menuItem lightObject_hide "Hide Light" enabled:(lightIsValid()) checked:(lightIsHidden())
		separator sep_20
		menuItem lightObject_remove "Remove Light" enabled:(lightIsValid())
		on lightObject_select picked do
		(
			max select none
			max modify mode
			try(select Krakatoa_RCMenu_Struct.SpecificLightRenderElement_CurrentElement.lightNode)catch()
		)
		on lightObject_hide picked do
		(
			try(Krakatoa_RCMenu_Struct.SpecificLightRenderElement_CurrentElement.lightNode.isHidden = not Krakatoa_RCMenu_Struct.SpecificLightRenderElement_CurrentElement.lightNode.isHidden )catch()
			try(if Krakatoa_RCMenu_Struct.SpecificLightRenderElement_CurrentElement.lightNode.isHidden do deselect Krakatoa_RCMenu_Struct.SpecificLightRenderElement_CurrentElement.lightNode)catch()
		)
		on lightObject_remove picked do
		(
			try(Krakatoa_RCMenu_Struct.SpecificLightRenderElement_CurrentElement.lightNode = undefined )catch()
		)		
	)
	Krakatoa_RCMenu_Struct.SpecificLightRenderElement_Options_RCMenu = SpecificLightRenderElement_Options_RCMenu

	rcmenu PRTSource_Options_RCMenu 
	(
		fn targetIsBBox =
		(
			try(selection[1].TargetNode.boxMode)catch(false)
		)	
		fn targetIsNonRenderable =
		(
			try(not selection[1].TargetNode.renderable)catch(false)
		)
		fn targetIsXRay =
		(
			try(selection[1].TargetNode.xray)catch(false)
		)
		
		fn targetIsValid =
		(
			try(selection[1].TargetNode != undefined)catch(false)
		)	
		fn targetIsHidden =
		(
			try(selection[1].TargetNode.isHidden)catch(false)
		)
		fn targetIsFrozen =
		(
			try(selection[1].TargetNode.isFrozen)catch(false)
		)		
		fn targetObjectHasMaterial =
		(
			try(selection[1].TargetNode.material != undefined)catch(false)
		)


		menuItem open_pdv "OPEN Particle Data VIEWER..." 
		on open_pdv picked do fileIn (FranticParticles.KrakatoaHome+"Scripts\\Krakatoa_ParticleDataViewer.ms")
		separator sep_05		
		menuItem targetObject_select "SELECT Source Object..." enabled:(targetIsValid())
		separator sep_10
		menuItem targetObject_hide "HIDE Source Object" checked:(targetIsHidden()) enabled:(targetIsValid())
		menuItem targetObject_bbox "BOUNDING BOX Display Of Source Object" checked:(targetIsBBox()) enabled:(targetIsValid())
		menuItem targetObject_nonrenderable "DON'T RENDER Source Object" checked:(targetIsNonRenderable()) enabled:(targetIsValid())
		
		separator sep_20		
		menuItem targetObject_setDefaults "STORE Above Settings As Defaults"  enabled:(targetIsValid())
		separator sep_30		
			
		submenu "Inherit Source Object Settings..."
		(
			menuItem targetObject_setWirecolor "Set PRT Source COLOR To Source Object's Color" enabled:(targetIsValid())
			menuItem targetObject_setMaterial "Set PRT Source MATERIAL To Source Object's Material" enabled:(targetObjectHasMaterial())
			menuItem targetObject_setName "Set PRT Source Object NAME From Source Object's Name " enabled:(targetIsValid())
			separator sep_40				
			menuItem targetObject_alignPRTSToSource "ALIGN PRT SOURCE To Source Object" enabled:(targetIsValid())
			menuItem targetObject_alignSourceToPRTS "ALIGN SOURCE Object To PRT Source" enabled:(targetIsValid())
			menuItem targetObject_parentPRTStoSource "LINK PRT Source To Source Object" enabled:(targetIsValid())
		)
		separator sep_50
		menuItem targetObject_removeMaterial "CLEAR Material" 			
		separator sep_60
		menuItem targetObject_remove "REMOVE Source Object"  enabled:(targetIsValid())		

		on targetObject_select picked do 
		(
			try(select selection[1].TargetNode)catch()
		)
		on targetObject_hide picked do 
		(
			try(selection[1].TargetNode.isHidden = not selection[1].TargetNode.isHidden)catch()
		)	
		
		on targetObject_setName picked do
		(
			try
			(
				selection[1].name = "_temp"
				selection[1].name = uniquename ("PRTSource_"+selection[1].TargetNode.name+"_")
			)catch()
		)
		on targetObject_alignPRTSToSource picked do
		(
			try(selection[1].transform = selection[1].TargetNode.transform)catch()
		)	
		on targetObject_alignSourceToPRTS picked do
		(
			try(selection[1].TargetNode.transform = selection[1].transform)catch()
		)
		
		on targetObject_parentPRTStoSource picked do
		(
			try(selection[1].parent = selection[1].TargetNode)catch()
		)		
		
		on targetObject_bbox picked do 
		(
			try(selection[1].TargetNode.boxMode = not selection[1].TargetNode.boxMode )catch()
		)		
		on targetObject_nonrenderable picked do 
		(
			try(selection[1].TargetNode.renderable = not selection[1].TargetNode.renderable )catch()
		)	
		on targetObject_seethru picked do 
		(
			try(selection[1].TargetNode.xray = not selection[1].TargetNode.xray)catch()
		)	
		on targetObject_setMaterial picked do
		(
			try
			(
				selection[1].material = selection[1].TargetNode.material
				pushprompt ("Assigned Source Object's Material ["+selection[1].TargetNode.material as string+"] to ["+selection[1].name+"]")
			)catch()
		)
		on targetObject_setWirecolor picked do
		(
			try(selection[1].wirecolor = selection[1].TargetNode.wirecolor)catch()
		)		
		
		on targetObject_setDefaults picked do
		(
			try
			(
				local currentObject = selection[1].TargetNode
				local theMode = if currentObject.isHidden == true then 4
				else if currentObject.renderable == false and currentObject.boxMode == false then 1
				else if currentObject.renderable == true and currentObject.boxMode == true then 2 
				else if currentObject.renderable == false and currentObject.boxMode == true then 3
				else 5
				setIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "Preferences" "CreatePRTSourceBehavior" (theMode as string)
			)catch()
		)
		
		on targetObject_removeMaterial picked do
		(
			try
			(
				selection[1].material = undefined
				pushprompt ("Cleated Material of ["+selection[1].name+"]")
			)catch()
		)		
		
		on targetObject_remove picked do
		(
			try
			(
				selection[1].TargetNode.isHidden = false
				selection[1].TargetNode = undefined
				select selection[1]
				pushprompt ("Removed Source Object of ["+selection[1].name+"]")
			)catch()
		)					
	)
	Krakatoa_RCMenu_Struct.PRTSource_Options_RCMenu = PRTSource_Options_RCMenu
	
	rcmenu PRTFumeFX_Options_RCMenu
	(
		fn fumeIsValid =
		(
			try(selection[1].TargetNode != undefined)catch(false)
		)	
		fn fumeIsHidden =
		(
			try(selection[1].TargetNode.isHidden)catch(false)
		)
		fn fumeIsFrozen =
		(
			try(selection[1].TargetNode.isFrozen)catch(false)
		)	

		menuItem open_pdv "OPEN Particle Data VIEWER..." 
		on open_pdv picked do fileIn (FranticParticles.KrakatoaHome+"Scripts\\Krakatoa_ParticleDataViewer.ms")
		separator sep_05		
		menuItem fumeObject_select "SELECT FumeFX Source..." enabled:(fumeIsValid())
		separator sep_10
		menuItem fumeObject_hide "HIDE FumeFX Source" checked:(fumeIsHidden()) enabled:(fumeIsValid())
		separator sep_20				
		menuItem fumeObject_setName "RENAME PRT FumeFX Object By Source's Name " enabled:(fumeIsValid())
		menuItem fumeObject_setIconSize "Set PRT FumeFX Object ICON SIZE From Source's Bounding Box" enabled:(fumeIsValid())
		separator sep_30				
		menuItem fumeObject_alignObjectToSim "ALIGN PRT FumeFX Object To FumeFX Source" enabled:(fumeIsValid())
		separator sep_40
		menuItem fumeObject_assignDefaultMaterial "ASSIGN Krakatoa Material"
		menuItem fumeObject_removeMaterial "CLEAR Material" 				
		separator sep_50
		menuItem fumeObject_remove "REMOVE FumeFX Source"  enabled:(fumeIsValid())
			
		on fumeObject_select picked do 
		(
			try(select selection[1].TargetNode)catch()
		)
		on fumeObject_hide picked do 
		(
			try(selection[1].TargetNode.isHidden = not selection[1].TargetNode.isHidden)catch()
		)			
		on fumeObject_setName picked do
		(
			try
			(
				selection[1].name = "_temp"
				selection[1].name = uniquename ("PRTFume_"+selection[1].TargetNode.name+"_")
			)catch()
		)
		on fumeObject_alignObjectToSim picked do
		(
			try(selection[1].transform = selection[1].TargetNode.transform)catch()
		)	
		on fumeObject_setIconSize picked do
		(
			try
			(
				selection[1].iconSize = amax #(selection[1].TargetNode.width, selection[1].TargetNode.length ) 
			)catch()
		)
		on fumeObject_assignDefaultMaterial picked do
		(
			try
			(
				local q = true
				if selection[1].material != undefined do
				(
					q = querybox ("The PRT FumeFX Object already has a material assigned:\n\n["+selection[1].material as string+"]\n\nAre you sure you want to replace it?") title:"PRT FumeFX Material"
				)
				if q do
				(
					local kmat = Krakatoa_Material() 
					kmat.ScatteringColor = white				
					kmat.name = "KMat_"+selection[1].name
					selection[1].material = kmat
					pushprompt ("Assigned new Krakatoa Material to ["+selection[1].name+"]")
				)
			)catch()
		)
		on fumeObject_removeMaterial picked do 
		(
			try
			(
				selection[1].material = undefined
				pushprompt ("Cleated Material of ["+selection[1].name+"]")
			)catch()
		)
		on fumeObject_remove picked do
		(
			try
			(
				selection[1].TargetNode.isHidden = false
				selection[1].TargetNode = undefined
				select selection[1]
			)catch()
		)		
	)
	Krakatoa_RCMenu_Struct.PRTFumeFX_Options_RCMenu = PRTFumeFX_Options_RCMenu
	
	rcmenu PRTSurface_Options_RCMenu
	(
		fn somethingIsSelected =
		(
			isValidNode selection[1].SelectedSource 
		)
		fn sourceIsValid =
		(
			try(selection[1].SourceNodes.count > 0)catch(false)
		)
		fn sourceIsHidden =
		(
			try((for o in selection[1].SourceNodes where not o.isHidden collect o).count == 0 )catch(false)
		)
		fn sourceIsFrozen =
		(
			try((for o in selection[1].SourceNodes where not o.isFrozen collect o).count == 0 )catch(false)
		)		
		fn sourceIsBBox =
		(
			try((for o in selection[1].SourceNodes where not o.boxMode collect o).count == 0 )catch(false)
		)	
		fn sourceIsNonRenderable =
		(
			try((for o in selection[1].SourceNodes where o.renderable collect o).count == 0 )catch(false)
		)
		fn sourceIsXRay =
		(
			try((for o in selection[1].SourceNodes where not o.xray collect o).count == 0 )catch(false)
		)
		
		fn sourceIsFrozenInGray =
		(
			try((for o in selection[1].SourceNodes where not o.showfrozeningray collect o).count == 0 )catch(false)
		)
		
		
		menuItem open_pdv "OPEN Particle Data VIEWER..." 
		on open_pdv picked do fileIn (FranticParticles.KrakatoaHome+"Scripts\\Krakatoa_ParticleDataViewer.ms")
		separator sep_05		
		menuItem mnu_selectHighlighed "SELECT Highlighted Object In the Scene" enabled:(somethingIsSelected())
		separator sep_10
		menuItem sourceObject_hide "HIDE Source Objects" checked:(sourceIsHidden()) enabled:(sourceIsValid())
		menuItem sourceObject_bbox "BOUNDING BOX Display of Source Objects" checked:(sourceIsBBox()) enabled:(sourceIsValid())
		menuItem sourceObject_nonrenderable "DON'T RENDER Source Objects" checked:(sourceIsNonRenderable()) enabled:(sourceIsValid())		
		separator sep_20
		menuItem setIconSize "ICON SIZE from Source Objects' Bounding Box XY" enabled:(sourceIsValid())		
		menuItem setName "RENAME from Source Objects' Names" enabled:(sourceIsValid())		
			
		separator sep_30
		menuItem alignToSources "ALIGN To Source Objects' Center Or Single Source's Pivot" enabled:(sourceIsValid())		
			
			
		on setName picked do
		(
			local theObjs = (for o in selection[1].SourceNodes where isValidNode o collect o)
			if theObjs.count > 1 then
			(
				selection[1].name = uniquename ("PRTSurface_Multi"+theObjs.count as string +"_")
			)
			else
			(
				selection[1].name = uniquename ("PRTSurface_"+theObjs[1].name +"_")
			)			
		)
			
		on alignToSources picked do
		(
			local theObjs = (for o in selection[1].SourceNodes where isValidNode o collect o)
			if theObjs.count == 1 then 
				selection[1].transform = theObjs[1].transform
			else
			(
				selection[1].transform = matrix3 1
				local theCenter = [0,0,0]
				for o in theObjs do theCenter+= o.center
				theCenter/=theObjs.count
				selection[1].pos = theCenter
			)
		)			
			
		on setIconSize picked do
		(
			local theObjX = (for o in selection[1].SourceNodes where isValidNode o collect (o.max.x-o.min.x))
			local theObjY = (for o in selection[1].SourceNodes where isValidNode o collect (o.max.y-o.min.y))
			local theMaxX = amax 	theObjX
			local theMaxY = amax 	theObjY
			selection[1].IconSize = amin theMaxX theMaxY
		)
		
		on mnu_selectHighlighed picked do
		(
			local obj = selection[1].baseobject.SelectedSource
			if isValidNode obj do select obj
		)
		
		on sourceObject_hide picked do
		(
			local isHidden = sourceIsHidden()
			local theObjs = (for o in selection[1].SourceNodes where isValidNode o collect o)
			if isHidden then
				unhide theObjs
			else
				hide theObjs
		)
		on sourceObject_bbox picked do
		(
			local theState = sourceIsBBox()
			for o in selection[1].SourceNodes where isValidNode o do o.boxMode = not theState
		)
		on sourceObject_nonrenderable picked do
		(
			local theState = sourceIsNonRenderable()
			for o in selection[1].SourceNodes where isValidNode o do o.renderable = theState 
		)		
		
	)

	Krakatoa_RCMenu_Struct.PRTSurface_Options_RCMenu = PRTSurface_Options_RCMenu
	
	rcmenu PRTVolume_Options_RCMenu 
	(
		fn volumeIsValid =
		(
			try(selection[1].TargetNode != undefined)catch(false)
		)
		fn volumeIsHidden =
		(
			try(selection[1].TargetNode.isHidden)catch(false)
		)
		fn volumeIsFrozen =
		(
			try(selection[1].TargetNode.isFrozen)catch(false)
		)		
		fn volumeIsBBox =
		(
			try(selection[1].TargetNode.boxMode)catch(false)
		)	
		fn volumeIsNonRenderable =
		(
			try(not selection[1].TargetNode.renderable)catch(false)
		)
		fn volumeIsXRay =
		(
			try(selection[1].TargetNode.xray)catch(false)
		)
		
		fn volumeIsFrozenInGray =
		(
			try(selection[1].TargetNode.showfrozeningray)catch(false)
		)
		fn volumeObjectHasMaterial =
		(
			try(selection[1].TargetNode.material != undefined)catch(false)
		)


		menuItem open_pdv "OPEN Particle Data VIEWER..." 
		on open_pdv picked do fileIn (FranticParticles.KrakatoaHome+"Scripts\\Krakatoa_ParticleDataViewer.ms")
		separator sep_05		
		menuItem volumeObject_select "Select" enabled:(volumeIsValid())
		separator sep_10
		menuItem volumeObject_hide "HIDE Source Object" checked:(volumeIsHidden()) enabled:(volumeIsValid())
		menuItem volumeObject_bbox "BOUNDING BOX Display Of Source Object" checked:(volumeIsBBox()) enabled:(volumeIsValid())
		menuItem volumeObject_nonrenderable "DON'T RENDER Source Object" checked:(volumeIsNonRenderable()) enabled:(volumeIsValid())
		separator sep_20
		menuItem volumeObject_setDefaults "STORE Above Settings As Defaults"  enabled:(volumeIsValid())
		separator sep_30
		submenu "More Source Object Display Options..."  enabled:(volumeIsValid())
		(
			menuItem volumeObject_seethru "SEE-THRU Source Object" checked:(volumeIsXRay()) enabled:(volumeIsValid())
			menuItem volumeObject_freeze "FREEZE Source Object" checked:(volumeIsFrozen()) enabled:(volumeIsValid())
			menuItem volumeObject_frozenasgray "FROZEN AS GRAY Display Of Source Object" checked:(volumeIsFrozenInGray()) enabled:(volumeIsValid())
		)
		submenu "Inherit Source Object Settings..."
		(
			menuItem volumeObject_setWirecolor "Set PRT Volume Object COLOR To Source Object's Color" enabled:(volumeIsValid())
			menuItem volumeObject_setMaterial "Set PRT Volume MATERIAL To Source Object's Material" enabled:(volumeObjectHasMaterial())
			menuItem volumeObject_setName "Set PRT Volume NAME from Source Object's Name" enabled:(volumeIsValid())
			menuItem volumeObject_setIconSize "Set ICON SIZE from Source Object's Bounding Box" enabled:(volumeIsValid())
			separator sep_100				
			menuItem volumeObject_setViewportSpacing "Set Default VIEWPORT SPACING From Bounding Box" enabled:(volumeIsValid())
			separator sep_110				
			menuItem volumeObject_alignPRTVToVO "ALIGN PRT VOLUME To Source Object" enabled:(volumeIsValid())
			menuItem volumeObject_alignVOToPRTV "ALIGN SOURCE Object To PRT Volume" enabled:(volumeIsValid())
			menuItem volumeObject_parentPRTVtoVO "LINK PRT Volume To Source Object" enabled:(volumeIsValid())
				
			separator sep_120	
			menuItem volumeObject_inheritVertexSelection "INHERIT Source Object's VERTEX SELECTION Via Modifier" enabled:(volumeIsValid())
		)

		separator sep_200
		menuItem volumeObject_removeMaterial "CLEAR Material" 
		separator sep_210
		menuItem volumeObject_remove "REMOVE Source Object"  enabled:(volumeIsValid())
			
		on volumeObject_alignPRTVToVO picked do
		(
			try(selection[1].transform = selection[1].TargetNode.transform)catch()
		)
		on volumeObject_alignVOToPRTV picked do
		(
			try(selection[1].TargetNode.transform = selection[1].transform)catch()
		)
		
		on volumeObject_parentPRTVtoVO picked do
		(
			try(selection[1].parent = selection[1].TargetNode)catch()
		)
			
		on volumeObject_setMaterial picked do
		(
			try
			(
				selection[1].material = selection[1].TargetNode.material
				pushprompt ("Assigned Source Object's Material ["+selection[1].TargetNode.material as string+"] to ["+selection[1].name+"]")
			)catch()
		)
		on volumeObject_setWirecolor picked do
		(
			try(selection[1].wirecolor = selection[1].TargetNode.wirecolor)catch()
		)
		on volumeObject_setName picked do
		(
			try
			(
				selection[1].name = "_temp"
				selection[1].name = uniquename ("PRTVolume_"+selection[1].TargetNode.name+"_")
			)catch()
		)
		
		on volumeObject_setViewportSpacing picked do
		(
			try
			(			
				local theBBox = selection[1].TargetNode.max-selection[1].TargetNode.min
				local theMaxSize = amax #(theBBox.x, theBBox.y, theBBox.z)
				local theSpacingFactor = execute (getIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "Preferences" "PRTVolumeSpacingFactor")
				if theSpacingFactor == OK do theSpacingFactor = 50.0				
				selection[1].ViewportVoxelLength = theMaxSize/theSpacingFactor
			)catch()
		)

		on volumeObject_setIconSize picked do
		(
			try
			(			
				local theBBox = selection[1].TargetNode.max-selection[1].TargetNode.min
				local theMaxSize = amax #(theBBox.x, theBBox.y, 10.0)
				selection[1].iconSize = theMaxSize
			)catch()			
		)
		
		
		on volumeObject_remove picked do
		(
			try
			(
				selection[1].TargetNode.renderable = true
				selection[1].TargetNode.isHidden = false
				selection[1].TargetNode.boxMode = false
				selection[1].TargetNode = undefined
				select selection[1]
			)catch()
		)
		
		on volumeObject_removeMaterial picked do
		(
			try
			(
				selection[1].material = undefined
				pushprompt ("Cleated Material of ["+selection[1].name+"]")
			)catch()
		)
		
		
			
		on volumeObject_select picked do 
		(
			try(select selection[1].TargetNode)catch()
		)
		on volumeObject_hide picked do 
		(
			try(selection[1].TargetNode.isHidden = not selection[1].TargetNode.isHidden)catch()
		)		

		on volumeObject_bbox picked do 
		(
			try(selection[1].TargetNode.boxMode = not selection[1].TargetNode.boxMode )catch()
		)		
		on volumeObject_nonrenderable picked do 
		(
			try(selection[1].TargetNode.renderable = not selection[1].TargetNode.renderable )catch()
		)	
		on volumeObject_seethru picked do 
		(
			try(selection[1].TargetNode.xray = not selection[1].TargetNode.xray)catch()
		)		
		on volumeObject_freeze picked do 
		(
			try(selection[1].TargetNode.isFrozen = not selection[1].TargetNode.isFrozen )catch()
		)		
		on volumeObject_frozenasgray picked do 
		(
			try(selection[1].TargetNode.showfrozeningray = not selection[1].TargetNode.showfrozeningray)catch()
		)				
		
		on volumeObject_inheritVertexSelection picked do
		(
			try
			(
				local theToMeshMod = Turn_To_Mesh()
				theToMeshMod.selectionLevel = 2
				addModifier selection[1].TargetNode theToMeshMod
			)catch()
		)
		
		on volumeObject_setDefaults picked do
		(
			try
			(
				local currentObject = selection[1].TargetNode
				local theMode = if currentObject.isHidden == true then 4
				else if currentObject.renderable == false and currentObject.boxMode == false then 1
				else if currentObject.renderable == true and currentObject.boxMode == true then 2 
				else if currentObject.renderable == false and currentObject.boxMode == true then 3
				else 5
				setIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "Preferences" "CreatePRTVolumeBehavior" (theMode as string)
			)catch()
		)
			
	)
	Krakatoa_RCMenu_Struct.PRTVolume_Options_RCMenu = PRTVolume_Options_RCMenu
	
	
	rcmenu PRTHair_Options_RCMenu 
	(
		fn objectIsValid =
		(
			try(selection[1].SourceType == 0 AND selection[1].TargetNode != undefined)catch(false)
		)
		fn objectIsHidden =
		(
			try(selection[1].SourceType == 0 AND selection[1].TargetNode.isHidden)catch(false)
		)
		fn objectIsFrozen =
		(
			try(selection[1].SourceType == 0 AND selection[1].TargetNode.isFrozen)catch(false)
		)		
		fn objectIsBBox =
		(
			try(selection[1].SourceType == 0 AND selection[1].TargetNode.boxMode)catch(false)
		)	
		fn objectIsNonRenderable =
		(
			try(selection[1].SourceType == 0 AND not selection[1].TargetNode.renderable)catch(false)
		)
		fn objectIsXRay =
		(
			try(selection[1].SourceType == 0 AND selection[1].TargetNode.xray)catch(false)
		)
		
		fn objectIsFrozenInGray =
		(
			try(selection[1].SourceType == 0 AND selection[1].TargetNode.showfrozeningray)catch(false)
		)
		fn objectHasMaterial =
		(
			try(selection[1].SourceType == 0 AND selection[1].TargetNode.material != undefined)catch(false)
		)
		fn wholeSceneHair = 
		(
			try(selection[1].SourceType == 1)catch(false)
		)
		
		menuItem open_pdv "OPEN Particle Data VIEWER..." 
		on open_pdv picked do fileIn (FranticParticles.KrakatoaHome+"Scripts\\Krakatoa_ParticleDataViewer.ms")
		separator sep_05		
		menuItem object_select "Select" filter:objectIsValid
		separator sep_10 filter:objectIsValid
		menuItem object_hide "HIDE Source Object" checked:(objectIsHidden()) filter:objectIsValid
		menuItem object_bbox "BOUNDING BOX Display Of Source Object" checked:(objectIsBBox()) filter:objectIsValid
		menuItem object_freeze "FREEZE Source Object" checked:(objectIsFrozen()) filter:objectIsValid
		menuItem object_frozenasgray "FROZEN AS GRAY Display Of Source Object" checked:(objectIsFrozenInGray()) filter:objectIsValid
		separator sep_100 filter:objectIsValid				
		menuItem object_setWirecolor "Set PRT Hair Object COLOR To Source Object's Color" filter:objectIsValid
		menuItem object_setMaterial "Set PRT Hair MATERIAL To Source Object's Material" filter:objectIsValid
		menuItem object_setName "Set PRT Hair NAME from Source Object's Name" filter:objectIsValid
		separator sep_110 filter:objectIsValid			
		menuItem object_alignPRTHToSource "ALIGN PRT HAIR To Source Object" filter:objectIsValid
		menuItem object_alignSourceToPRTH "ALIGN SOURCE Object To PRT Hair" filter:objectIsValid
		menuItem object_parentPRTHtoSource "LINK PRT Hair To Source Object" filter:objectIsValid
		menuItem object_alignPRTHToWorld "ALIGN PRT HAIR To WORLD Origin" filter:wholeSceneHair
		separator sep_200 filter:objectIsValid
		separator sep_201 filter:wholeSceneHair

			
		menuItem object_removeMaterial "CLEAR Material" 
		separator sep_210 filter:objectIsValid
		menuItem object_remove "REMOVE Source Object"  filter:objectIsValid
			
		on object_alignPRTHToSource picked do
		(
			try(selection[1].transform = selection[1].TargetNode.transform)catch()
		)
		on object_alignSourceToPRTH picked do
		(
			try(selection[1].TargetNode.transform = selection[1].transform)catch()
		)
		
		on object_parentPRTHtoSource picked do
		(
			try(selection[1].parent = selection[1].TargetNode)catch()
		)
		
		on object_alignPRTHToWorld picked do
		(
			try(selection[1].transform = matrix3 1)catch()
			try(selection[1].parent = undefined)catch()
		)
			
		on object_setMaterial picked do
		(
			try
			(
				selection[1].material = selection[1].TargetNode.material
				pushprompt ("Assigned Source Object's Material ["+selection[1].TargetNode.material as string+"] to ["+selection[1].name+"]")
			)catch()
		)
		on object_setWirecolor picked do
		(
			try(selection[1].wirecolor = selection[1].TargetNode.wirecolor)catch()
		)
		on object_setName picked do
		(
			try
			(
				selection[1].name = "_temp"
				selection[1].name = uniquename ("PRTHair_"+selection[1].TargetNode.name+"_")
			)catch()
		)
		
		/*
		on object_setViewportSpacing picked do
		(
			try
			(			
				local theBBox = selection[1].TargetNode.max-selection[1].TargetNode.min
				local theMaxSize = amax #(theBBox.x, theBBox.y, theBBox.z)
				local theSpacingFactor = execute (getIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "Preferences" "PRTVolumeSpacingFactor")
				if theSpacingFactor == OK do theSpacingFactor = 50.0				
				selection[1].ViewportVoxelLength = theMaxSize/theSpacingFactor
			)catch()
		)

		on object_setIconSize picked do
		(
			try
			(			
				local theBBox = selection[1].TargetNode.max-selection[1].TargetNode.min
				local theMaxSize = amax #(theBBox.x, theBBox.y, 10.0)
				selection[1].iconSize = theMaxSize
			)catch()			
		)
		*/
		
		on object_remove picked do
		(
			try
			(
				selection[1].TargetNode.renderable = true
				selection[1].TargetNode.isHidden = false
				selection[1].TargetNode.boxMode = false
				selection[1].TargetNode = undefined
				select selection[1]
			)catch()
		)
		
		on object_removeMaterial picked do
		(
			try
			(
				selection[1].material = undefined
				pushprompt ("Cleated Material of ["+selection[1].name+"]")
			)catch()
		)
		
		
			
		on object_select picked do 
		(
			try(select selection[1].TargetNode)catch()
		)
		on object_hide picked do 
		(
			try(selection[1].TargetNode.isHidden = not selection[1].TargetNode.isHidden)catch()
		)		

		on object_bbox picked do 
		(
			try(selection[1].TargetNode.boxMode = not selection[1].TargetNode.boxMode )catch()
		)		
		on object_nonrenderable picked do 
		(
			try(selection[1].TargetNode.renderable = not selection[1].TargetNode.renderable )catch()
		)	
		/*
		on object_seethru picked do 
		(
			try(selection[1].TargetNode.xray = not selection[1].TargetNode.xray)catch()
		)	*/	
		on object_freeze picked do 
		(
			try(selection[1].TargetNode.isFrozen = not selection[1].TargetNode.isFrozen )catch()
		)		
		on object_frozenasgray picked do 
		(
			try(selection[1].TargetNode.showfrozeningray = not selection[1].TargetNode.showfrozeningray)catch()
		)				
		
		on object_inheritVertexSelection picked do
		(
			try
			(
				local theToMeshMod = Turn_To_Mesh()
				theToMeshMod.selectionLevel = 2
				addModifier selection[1].TargetNode theToMeshMod
			)catch()
		)
		
		on object_setDefaults picked do
		(
			try
			(
				local currentObject = selection[1].TargetNode
				local theMode = if currentObject.isHidden == true then 4
				else if currentObject.renderable == false and currentObject.boxMode == false then 1
				else if currentObject.renderable == true and currentObject.boxMode == true then 2 
				else if currentObject.renderable == false and currentObject.boxMode == true then 3
				else 5
				setIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "Preferences" "CreatePRTVolumeBehavior" (theMode as string)
			)catch()
		)
			
	)
	
	Krakatoa_RCMenu_Struct.PRTHair_Options_RCMenu = PRTHair_Options_RCMenu
	
	
	rcmenu Load_Save_Rollout_RCMenu
	(
		menuItem save_Rollout_Preset "Save this Rollout's Controls as Preset..."
		menuItem load_Rollout_Preset "Load this Rollout's Controls from Preset..."
		separator sep_10
		submenu "More Options..."
		(
			menuItem save_All_Preset "Save All Controls as Preset..."
			menuItem load_All_Preset "Load All Controls from Preset..."
			separator sep_20
			menuItem load_Rollout_History "Load this Rollout's Controls from History..."
			menuItem load_All_History "Load All Controls from History..."
		)
		
		on save_Rollout_Preset picked do
		(
			FranticParticleRenderMXS.UpdateAllHiddenRollouts()
			FranticParticleRenderMXS.LoadSave_SingleRollout = Krakatoa_RCMenu_Struct.Float_Rollout_RCMenu_CurrentRollout
			FranticParticleRenderMXS.PresetFilterString = ""
			Krakatoa_PresetDialogMode = #save
			FranticParticleRenderMXS.displaySavePresetDialog()
		)	
		
		on load_Rollout_Preset picked do
		(
			FranticParticleRenderMXS.LoadSave_SingleRollout = Krakatoa_RCMenu_Struct.Float_Rollout_RCMenu_CurrentRollout
			FranticParticleRenderMXS.PresetFilterString = "*_"+ FranticParticleRenderMXS.fixTimeString Krakatoa_RCMenu_Struct.Float_Rollout_RCMenu_CurrentRollout.title
			Krakatoa_PresetDialogMode = #load
			FranticParticleRenderMXS.displaySavePresetDialog()
		)		
		
		on save_All_Preset picked do
		(
			FranticParticleRenderMXS.LoadSave_SingleRollout = undefined 
			FranticParticleRenderMXS.PresetFilterString = ""
			Krakatoa_PresetDialogMode = #save
			FranticParticleRenderMXS.displaySavePresetDialog()
		)	
		
		on load_All_Preset picked do
		(
			FranticParticleRenderMXS.LoadSave_SingleRollout = undefined
			FranticParticleRenderMXS.PresetFilterString = ""
			Krakatoa_PresetDialogMode = #load
			FranticParticleRenderMXS.displaySavePresetDialog()
		)		

		on load_Rollout_History picked do
		(
			FranticParticleRenderMXS.LoadSave_SingleRollout = Krakatoa_RCMenu_Struct.Float_Rollout_RCMenu_CurrentRollout
			FranticParticleRenderMXS.PresetFilterString = getFileNameFile maxFileName
			Krakatoa_PresetDialogMode = #loadHistory
			FranticParticleRenderMXS.displaySavePresetDialog()
		)		
		
		on load_All_History picked do
		(
			FranticParticleRenderMXS.LoadSave_SingleRollout = undefined
			FranticParticleRenderMXS.PresetFilterString = ""
			Krakatoa_PresetDialogMode = #loadHistory
			FranticParticleRenderMXS.displaySavePresetDialog()
		)			
	)
	Krakatoa_RCMenu_Struct.Load_Save_Rollout_RCMenu = Load_Save_Rollout_RCMenu

	rcmenu Float_Rollout_RCMenu
	(
		fn isNotInDialog = (not Krakatoa_RCMenu_Struct.Float_Rollout_RCMenu_CurrentRollout.inDialog)
		fn isInDialog = Krakatoa_RCMenu_Struct.Float_Rollout_RCMenu_CurrentRollout.inDialog
		fn isNotInFloater1 = try(findItem Krakatoa_GUI_Floater.rollouts Krakatoa_RCMenu_Struct.Float_Rollout_RCMenu_CurrentRollout == 0)catch(true)
		fn isNotInFloater2 = try(findItem Krakatoa_GUI_Floater_2.rollouts Krakatoa_RCMenu_Struct.Float_Rollout_RCMenu_CurrentRollout == 0)catch(true)
		fn isInFloater2 = try(findItem Krakatoa_GUI_Floater_2.rollouts Krakatoa_RCMenu_Struct.Float_Rollout_RCMenu_CurrentRollout > 0)catch(false)
		fn isNotHidden theRollout = ((execute (getIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "RolloutVisible" theRollout.title)) == true)
		
		menuitem mnu_floatAsDialog "Float Rollout as Free Dialog (Click)" filter:isNotInDialog
		
		menuitem mnu_dockRolloutInPrimaryFloater "Dock Rollout in Primary Floater (SHIFT+Click)" filter:isInFloater2 
		menuitem mnu_dockDialogInPrimaryFloater "Dock Rollout in Primary Floater (Click)" filter:isInDialog 
		
		menuitem mnu_dockRolloutInSecondaryFloater "Dock Rollout in Secondary Floater (SHIFT+Click)" filter:isNotInFloater2
		separator sep_10
		menuitem mnu_disableRollout "Hide Rollout (Ctrl+Click)" 
		separator sep_20
		menuitem mnu_label1 "Select: Toggle Visibility, SHIFT+Select: Navigate To:" enabled:false
		menuitem mnu_label2 "SHIFT+Select: Navigate To:" enabled:false
		menuitem mnu_label3 "CTRL+Select: Dock To Primary Floater:" enabled:false
		menuitem mnu_label4 "SHIFT+CTRL+Select: Dock To Secondary Floater:" enabled:false
		
		menuitem mnu_togglePresets "Presets and History" checked:(isNotHidden Krakatoa_GUI_Presets)
		menuitem mnu_toggleGlobals "Global Render Values"  checked:(isNotHidden Krakatoa_GUI_RenderGlobalValues )
		menuitem mnu_toggleShader "Shader Parameters" checked:(isNotHidden Krakatoa_GUI_ShaderDynamic)
		menuitem mnu_toggleMain "Main Controls" checked:(isNotHidden Krakatoa_GUI_Main )
		menuitem mnu_toggleSave "Save Particles" checked:(isNotHidden Krakatoa_GUI_SaveParticles )
		menuitem mnu_toggleChannels "Memory Channels" checked:(isNotHidden Krakatoa_GUI_Channels )
		menuitem mnu_togglePartitioning "Partitioning" checked:(isNotHidden Krakatoa_GUI_Partition )
		menuitem mnu_toggleMatte "Matte Objects" checked:(isNotHidden Krakatoa_GUI_MatteObjects )
		menuitem mnu_toggleAPME "Ambient PME" checked:(isNotHidden Krakatoa_GUI_AmbientPME)
		
		separator sep_100
		menuitem mnu_lockSecondaryToPrimaryFloater "Lock Secondary To Primary Floater" checked:FranticParticleRenderMXS.lockSecondaryToPrimaryFloater
		
		on mnu_togglePresets picked do FranticParticleRenderMXS.ToggleRolloutVisibility Krakatoa_GUI_Presets
		on mnu_toggleGlobals picked do FranticParticleRenderMXS.ToggleRolloutVisibility Krakatoa_GUI_RenderGlobalValues
		on mnu_toggleShader picked do FranticParticleRenderMXS.ToggleRolloutVisibility Krakatoa_GUI_ShaderDynamic
		on mnu_toggleMain picked do FranticParticleRenderMXS.ToggleRolloutVisibility Krakatoa_GUI_Main
		on mnu_toggleSave picked do FranticParticleRenderMXS.ToggleRolloutVisibility Krakatoa_GUI_SaveParticles
		on mnu_toggleChannels picked do FranticParticleRenderMXS.ToggleRolloutVisibility Krakatoa_GUI_Channels
		on mnu_togglePartitioning picked do FranticParticleRenderMXS.ToggleRolloutVisibility Krakatoa_GUI_Partition
		on mnu_toggleMatte picked do FranticParticleRenderMXS.ToggleRolloutVisibility Krakatoa_GUI_MatteObjects
		on mnu_toggleAPME picked do FranticParticleRenderMXS.ToggleRolloutVisibility Krakatoa_GUI_AmbientPME
			
		
		on mnu_lockSecondaryToPrimaryFloater picked do
		(
			FranticParticleRenderMXS.lockSecondaryToPrimaryFloater = not FranticParticleRenderMXS.lockSecondaryToPrimaryFloater
			if FranticParticleRenderMXS.lockSecondaryToPrimaryFloater then
			(
				local thePos = execute(FranticParticles.GetProperty "GUI:Position")
				if FranticParticleRenderMXS.lockSecondaryToPrimaryFloater do
					Krakatoa_GUI_Floater_2.pos = thePos + [484,0]
			)	
		)
		
		on mnu_floatAsDialog picked do
		(
			FranticParticleRenderMXS.floatOrDockRollout Krakatoa_RCMenu_Struct.Float_Rollout_RCMenu_CurrentRollout forceMode:#float
		)
		on mnu_dockRolloutInPrimaryFloater picked do
		(
			FranticParticleRenderMXS.floatOrDockRollout Krakatoa_RCMenu_Struct.Float_Rollout_RCMenu_CurrentRollout forceMode:#dock
		)
		on mnu_dockDialogInPrimaryFloater	picked do
		(
			FranticParticleRenderMXS.floatOrDockRollout Krakatoa_RCMenu_Struct.Float_Rollout_RCMenu_CurrentRollout forceMode:#dock
		)
		

		
		on mnu_dockRolloutInSecondaryFloater picked do
		(
			FranticParticleRenderMXS.floatOrDockRollout Krakatoa_RCMenu_Struct.Float_Rollout_RCMenu_CurrentRollout forceMode:#dock2
		)
		on mnu_disableRollout picked do
		(
			setIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "RolloutVisible" Krakatoa_RCMenu_Struct.Float_Rollout_RCMenu_CurrentRollout.title "false"
			try(destroyDialog Krakatoa_RCMenu_Struct.Float_Rollout_RCMenu_CurrentRollout)catch()
			try(removeRollout Krakatoa_RCMenu_Struct.Float_Rollout_RCMenu_CurrentRollout Krakatoa_Gui_floater)catch()
			try(removeRollout Krakatoa_RCMenu_Struct.Float_Rollout_RCMenu_CurrentRollout Krakatoa_Gui_floater_2)catch()
			addRollout Krakatoa_RCMenu_Struct.Float_Rollout_RCMenu_CurrentRollout Krakatoa_Gui_floater_3
			if Krakatoa_Gui_floater_2.rollouts.count == 0 do closeRolloutFloater Krakatoa_Gui_floater_2		
			Krakatoa_CustomizeRollouts_Dialog.refresh_GUI()
		)		
	)	

	Krakatoa_RCMenu_Struct.Float_Rollout_RCMenu = Float_Rollout_RCMenu
	
	rcmenu ParticleCache_RCMenu 
	(
		menuitem mnu_cacheSize "In Memory: 0 Particles using 0.0 MB"
		separator spr_cache01
		menuitem mnu_ClearLightingCache "Clear Lighting Cache Only"
		menuitem mnu_ClearCaches "Clear Both Caches"
		separator spr_cache02
		menuitem mnu_cacheLastFrame "Keep Last Frame In Cache" checked:(FranticParticles.GetBoolProperty "CacheLastFrame")
		menuitem mnu_UseCacheInWorkerMode "Use Cache In Worker Mode" checked:(FranticParticles.GetBoolProperty "UseCacheInWorkerMode")
		
		on mnu_UseCacheInWorkerMode picked do
		(
			if not (FranticParticles.GetBoolProperty "UseCacheInWorkerMode") then
			(
				local q = querybox "You requested to turn ON the option to KEEP PARTICLES IN CACHE during Network Rendering\n\nThis means that the first frame loaded by a machine will be kept in memory and rendered on all frames.\nThis is a very special and DANGEROUS mode! It will be enabled for THIS SCENE ONLY and will not be sticky for other sessions.\n\nPlease confirm you really know what you are doing by clicking [Yes]. If you did not understand the above warning, you should probably click [No]." title:"REALLY Enable PCache In Worker Mode?"
				if q == true do FranticParticles.SetProperty "UseCacheInWorkerMode" "true"
			)
			else
			(
				FranticParticles.SetProperty "UseCacheInWorkerMode" "false"
			)	
		)
		
		on mnu_cacheSize picked do FranticParticles.LogStats mnu_cacheSize.text
		on mnu_cacheLastFrame picked do 
		(
			FranticParticles.SetProperty "CacheLastFrame" (not (FranticParticles.GetBoolProperty "CacheLastFrame"))
		)	
		on mnu_ClearLightingCache picked do 
		(
			FranticParticles.InvalidateLightingCache()
			Krakatoa_GUI_Main.refreshCacheStatus()
			Krakatoa_GUI_Channels.updateMemChannels()
			try(Krakatoa_VFB_Overlay_Rollout.refresh_GUI())catch()
			try(Krakatoa_updateSchematicFlow())catch()
		)	
		on mnu_ClearCaches picked do 
		(
			FranticParticles.InvalidateParticleCache()
			Krakatoa_GUI_Main.refreshCacheStatus()
			Krakatoa_GUI_Channels.updateMemChannels()
			try(Krakatoa_VFB_Overlay_Rollout.refresh_GUI())catch()
			try(Krakatoa_updateSchematicFlow())catch()
		)	
	)

	Krakatoa_RCMenu_Struct.ParticleCache_RCMenu = ParticleCache_RCMenu

	rcmenu RenderButton_RCMenu
	(
		fn filterFN = ((FranticParticles.GetProperty "ParticleMode") != "Save Particles To File Sequence")
		fn filterSaveFN  = ((FranticParticles.GetProperty "ParticleMode") == "Save Particles To File Sequence")
		fn filterViewImageFN = ((FranticParticles.GetProperty "ParticleMode") != "Save Particles To File Sequence" AND rendOutputFileName != "" and doesFileExist (FranticParticles.ReplaceSequenceNumber rendOutputFileName (currentTime.frame as integer)) )
		fn filterBBFN = (FranticParticleRenderMXS.DeadlineDetected > 0)
		--menuitem mnu_IgnoreMissingFrames "Ignore Missing Particle Files" checked:(Krakatoa_PRTIgnoreMissingFrames == true)
		--separator spr_01
		
		menuitem mnu_RenderSceneDialog "Open [Common] Tab In Render Setup Dialog..." checked:(renderSceneDialog.isOpen() and (tabbedDialogs.getCurrentPage #render) as string == "#(1379758294, 1692354418)")
		menuitem mnu_RenderElementsDialog "Open [Render Elements] Tab In Render Setup Dialog..." checked:(renderSceneDialog.isOpen() and (tabbedDialogs.getCurrentPage #render) as string == "#(1547006576, 1564889954)")
			
		menuitem mnu_KeepRenderSceneDialogOpen "Keep Render Setup Dialog Open" checked:((getIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "Preferences" "KeepRenderSceneDialogOpen")=="true")
		separator spr_05
		
		
		menuitem mnu_SaveRenderPath "Save Render Output" checked:rendSaveFile enabled:(rendOutputFileName != "") filter:filterFN 
		menuitem mnu_SetSaveRenderPath "Set Render Output Filename..." checked:(rendOutputFileName != "") filter:filterFN 
		menuitem mnu_exploreRenderPath "Explore Render Path..." enabled:(rendOutputFileName != "") filter:filterFN 
		submenu "Open Rendered Frame" filter:filterViewImageFN 
		(
			menuitem mnu_openInVFB "In Rendered Frame Window (VFB)..." enabled:(rendOutputFileName != "" and doesFileExist (FranticParticles.ReplaceSequenceNumber rendOutputFileName (currentTime.frame as integer)) ) filter:filterFN 
			menuitem mnu_openInExternalViewer "In External Viewer..." enabled:(rendOutputFileName != "" and doesFileExist (FranticParticles.ReplaceSequenceNumber rendOutputFileName (currentTime.frame as integer)) ) filter:filterFN 
			separator sep_101
			menuitem mnu_openInRAMPlayer "In RAM Player..." enabled:(rendOutputFileName != "" and doesFileExist (FranticParticles.ReplaceSequenceNumber rendOutputFileName (currentTime.frame as integer)) )filter:filterFN 
			menuitem mnu_openSequenceInRAMPlayerA "As Sequence In RAM Player Channel A..." enabled:(rendOutputFileName != "" and doesFileExist (FranticParticles.ReplaceSequenceNumber rendOutputFileName (currentTime.frame as integer)) )filter:filterFN 
				
		)
		separator spr_10 filter:filterFN 
		
		menuitem mnu_SetSaveParticlesPath "Set Save Particles Filename..." filter:filterSaveFN 
		menuitem mnu_exploreSaveParticlesPath "Explore Save Particles Path..." enabled:(FranticParticles.GetProperty "ParticleFiles" != "") filter:filterSaveFN 
		separator spr_20 filter:filterSaveFN 
		
		menuitem mnu_singleFrame "Single Frame" checked:(rendTimeType == 1)
		menuitem mnu_activeSegment "Active Segment" checked:(rendTimeType == 2)
		menuitem mnu_customRange "Custom Range" checked:(rendTimeType == 3)
		menuitem mnu_CustomFrames "Custom Frames" checked:(rendTimeType == 4)
--		separator spr_20 filter:filterFN
--		menuitem mnu_NetRender "Net Render Using Backburner" checked:rendUseNet enabled:((FranticParticles.GetProperty "ParticleMode")!="Save Particles To File Sequence") filter:filterBBFN 
--		separator spr_30 filter:filterBBFN
--		menuitem mnu_SaveAttenuationMaps "Save Attenuation Maps" checked:(FranticParticles.GetBoolProperty "EnableAttenuationMapSaving") enabled:(rendSaveFile and rendOutputFileName != "") filter:filterFN
		
		--on mnu_IgnoreMissingFrames picked do Krakatoa_PRTIgnoreMissingFrames = not Krakatoa_PRTIgnoreMissingFrames
		
		on mnu_openInVFB picked do
		(
			gc light:true
			local theImageViewer = openBitmap (FranticParticles.ReplaceSequenceNumber rendOutputFileName (currentTime.frame as integer))
			display theImageViewer
		)
		on mnu_openInExternalViewer picked do
		(
			shellLaunch (FranticParticles.ReplaceSequenceNumber rendOutputFileName (currentTime.frame as integer)) ""
		)
		
		on mnu_openInRAMPlayer picked do
		(
			gc light:true
			RAMPlayer (FranticParticles.ReplaceSequenceNumber rendOutputFileName (currentTime.frame as integer)) ""
		)
		on mnu_openSequenceInRAMPlayerA picked do
		(
			gc light:true
			local theBaseFilename = substituteString (FranticParticles.ReplaceSequenceNumberWithHashes rendOutputFileName) "####" "*"
			local theFiles = sort (getFiles theBaseFilename)
			if theFiles.count > 0 do 
			(
				local theIFLFIleName = getFileNamePath rendOutputFileName + getFileNameFile rendOutputFileName + ".ifl"
				local theIFLFile = createFile theIFLFIleName
				for f in theFiles do format "%\n" (fileNameFromPath f) to:theIFLFile
				close theIFLFile
			)
			RAMPlayer theIFLFIleName ""
		)
		
		on mnu_SaveAttenuationMaps picked do 
		(
			local theState = (FranticParticles.GetBoolProperty "EnableAttenuationMapSaving")
			theState = not theState 
			FranticParticles.SetProperty "EnableAttenuationMapSaving" (theState as string)
			--Krakatoa_GUI_Shadows.refresh_GUI()
		)
		
		on mnu_RenderSceneDialog picked do 
		(
			if renderSceneDialog.isOpen() and (tabbedDialogs.getCurrentPage #render) as string == "#(1379758294, 1692354418)" then 
			(
				renderSceneDialog.close() 
			)
			else 
			(
				renderSceneDialog.open() 
				tabbedDialogs.setCurrentPage #render #(1379758294, 1692354418)
			)
		)
		on mnu_KeepRenderSceneDialogOpen picked do
		(
			local theVal = ((getIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "Preferences" "KeepRenderSceneDialogOpen")=="true")		
			setIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "Preferences" "KeepRenderSceneDialogOpen" ((not theVal) as string)
		)
		on mnu_RenderElementsDialog picked do
		(
			if renderSceneDialog.isOpen() and (tabbedDialogs.getCurrentPage #render) as string == "#(1547006576, 1564889954)" then 
			(
				renderSceneDialog.close() 
			)
			else 
			(
				RenderSceneDialog.open()
				tabbedDialogs.setCurrentPage #render #(1547006576, 1564889954)			
			)
		)
		
		on mnu_exploreRenderPath picked do shelllaunch "explorer.exe" (getFileNamePath rendOutputFileName)
		on mnu_SaveRenderPath picked do 
		(
			local oldState = renderSceneDialog.isOpen()
			local keepOpen = ((getIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "Preferences" "KeepRenderSceneDialogOpen")=="true")
			if oldState do oldTab = tabbedDialogs.getCurrentPage #render 
			renderSceneDialog.close()
			rendSaveFile = not rendSaveFile 
			if oldState and keepOpen do 
			(
				renderSceneDialog.open()
				tabbedDialogs.setCurrentPage #render oldTab
			)
			try(Krakatoa_updateSchematicFlow())catch()
		)	

		on mnu_SetSaveRenderPath picked do 
		(
			local oldState = renderSceneDialog.isOpen()
			local keepOpen = ((getIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "Preferences" "KeepRenderSceneDialogOpen")=="true")
			if oldState do oldTab = tabbedDialogs.getCurrentPage #render 
			renderSceneDialog.close()
			theBitmapPath = getBitmapSaveFileName filename:rendOutputFilename
			if theBitmapPath != undefined do
			(
				rendOutputFilename = theBitmapPath 
				rendSaveFile = true
			)	
			if oldState and keepOpen do 
			(
				renderSceneDialog.open()	
				tabbedDialogs.setCurrentPage #render oldTab
			)
			try(Krakatoa_updateSchematicFlow())catch()
		)	

		
		on mnu_SetSaveParticlesPath picked do 
		(
			Krakatoa_GUI_SaveParticles.btn_particleFiles.pressed()
			
		)
		on mnu_exploreSaveParticlesPath picked do Krakatoa_GUI_SaveParticles.btn_ExploreTake.pressed()
		
		on mnu_singleFrame picked do 
		(
			local oldState = renderSceneDialog.isOpen()
			local keepOpen = ((getIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "Preferences" "KeepRenderSceneDialogOpen")=="true")
			if oldState do oldTab = tabbedDialogs.getCurrentPage #render 
			renderSceneDialog.close()
			rendTimeType = 1
			if oldState and keepOpen do 
			(
				renderSceneDialog.open()
				tabbedDialogs.setCurrentPage #render oldTab
			)
			Krakatoa_GUI_Main.refresh_GUI()
		)	
		on mnu_activeSegment picked do 
		(
			local oldState = renderSceneDialog.isOpen()
			local keepOpen = ((getIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "Preferences" "KeepRenderSceneDialogOpen")=="true")
			if oldState do oldTab = tabbedDialogs.getCurrentPage #render 
			renderSceneDialog.close()
			rendTimeType = 2
			if oldState and keepOpen do 
			(
				renderSceneDialog.open()
				tabbedDialogs.setCurrentPage #render oldTab
			)
			Krakatoa_GUI_Main.refresh_GUI()
		)	
		on mnu_customRange picked do 
		(
			local oldState = renderSceneDialog.isOpen()
			local keepOpen = ((getIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "Preferences" "KeepRenderSceneDialogOpen")=="true")
			if oldState do oldTab = tabbedDialogs.getCurrentPage #render 
			renderSceneDialog.close()
			rendTimeType = 3
			if oldState and keepOpen do 
			(
				renderSceneDialog.open()
				tabbedDialogs.setCurrentPage #render oldTab
			)
			Krakatoa_GUI_Main.refresh_GUI()
		)	
		on mnu_CustomFrames picked do 
		(
			local oldState = renderSceneDialog.isOpen()
			local keepOpen = ((getIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "Preferences" "KeepRenderSceneDialogOpen")=="true")
			if oldState do oldTab = tabbedDialogs.getCurrentPage #render 
			renderSceneDialog.close()
			rendTimeType = 4
			if oldState and keepOpen do 
			(
				renderSceneDialog.open()
				tabbedDialogs.setCurrentPage #render oldTab
			)
			Krakatoa_GUI_Main.refresh_GUI()
		)	
	)--end menu
	Krakatoa_RCMenu_Struct.RenderButton_RCMenu = RenderButton_RCMenu
	
	
	
	rcmenu IterativeOptions_RCMenu 
	(
		menuitem mnu_renderRes_2 "Double Resolution" checked:((FranticParticles.GetProperty "IterativeRender:ScaleFactor") =="2")
		separator sep_10
		menuitem mnu_renderRes_1 "Full Resolution" checked:((FranticParticles.GetProperty "IterativeRender:ScaleFactor") =="1")
		separator sep_20
		menuitem mnu_renderRes_1_2 "1/2 Resolution" checked:((FranticParticles.GetProperty "IterativeRender:ScaleFactor") =="1/2")
		menuitem mnu_renderRes_1_4 "1/4 Resolution" checked:((FranticParticles.GetProperty "IterativeRender:ScaleFactor") =="1/4")
		menuitem mnu_renderRes_1_8 "1/8 Resolution" checked:((FranticParticles.GetProperty "IterativeRender:ScaleFactor") =="1/8")
		menuitem mnu_renderRes_1_16 "1/16 Resolution" checked:((FranticParticles.GetProperty "IterativeRender:ScaleFactor") =="1/16")
		--separator sep_30
		--menuitem mnu_ScaleDensity "Scale Density" checked:(Krakatoa_RCMenu_Struct.IterativeOptions_ScaleDensity)
		
		on mnu_ScaleDensity picked do 
		(
			Krakatoa_RCMenu_Struct.IterativeOptions_ScaleDensity = not Krakatoa_RCMenu_Struct.IterativeOptions_ScaleDensity
		)	
		
		on mnu_renderRes_2 picked do 
		(
			FranticParticles.SetProperty "IterativeRender:ScaleFactor" "2"
			Krakatoa_GUI_Main.updateIterativeRenderText()
			try(Krakatoa_VFB_Right_Rollout.refresh_GUI())catch()
		)	
		on mnu_renderRes_1 picked do 
		(
			FranticParticles.SetProperty "IterativeRender:ScaleFactor" "1"
			Krakatoa_GUI_Main.updateIterativeRenderText()
			try(Krakatoa_VFB_Right_Rollout.refresh_GUI())catch()
		)	
		on mnu_renderRes_1_2 picked do 
		(
			FranticParticles.SetProperty "IterativeRender:ScaleFactor" "1/2"
			Krakatoa_GUI_Main.updateIterativeRenderText()
			try(Krakatoa_VFB_Right_Rollout.refresh_GUI())catch()
		)	
		on mnu_renderRes_1_4 picked do 
		(
			FranticParticles.SetProperty "IterativeRender:ScaleFactor" "1/4"
			Krakatoa_GUI_Main.updateIterativeRenderText()
			try(Krakatoa_VFB_Right_Rollout.refresh_GUI())catch()
		)	
		on mnu_renderRes_1_8 picked do 
		(
			FranticParticles.SetProperty "IterativeRender:ScaleFactor" "1/8"
			Krakatoa_GUI_Main.updateIterativeRenderText()
			try(Krakatoa_VFB_Right_Rollout.refresh_GUI())catch()
		)	
		on mnu_renderRes_1_16 picked do 
		(
			FranticParticles.SetProperty "IterativeRender:ScaleFactor" "1/16"
			Krakatoa_GUI_Main.updateIterativeRenderText()
			try(Krakatoa_VFB_Right_Rollout.refresh_GUI())catch()
		)	
			
	)
	Krakatoa_RCMenu_Struct.IterativeOptions_RCMenu = IterativeOptions_RCMenu
	
	rcmenu HistoryPatternOptions01_RCMenu 
	(
		fn filterFN =
		(
			Krakatoa_GUI_Presets.ddl_historyFiles01.selection > 0
		)
		fn	filterSceneFN = Krakatoa_GUI_Presets.rad_files01.state == 2 and maxFileName != ""
		fn filterClearFN = Krakatoa_GUI_Presets.edt_filter01.text.count > 0
		
		menuitem mnu_getFromList "Get Search Pattern From RECORD Name" filter:filterFN 
		menuitem mnu_getFromMaxScene "Get Search Pattern From SCENE File Name" filter:filterSceneFN 
		menuitem mnu_clear "CLEAR Search Pattern" filter:filterClearFN 
		
		on mnu_getFromList picked do 
		(
			if Krakatoa_GUI_Presets.ddl_historyFiles01.selection > 0 do
			(
				if Krakatoa_GUI_Presets.rad_files01.state == 1 then 
					theString = Krakatoa_GUI_Presets.ddl_historyFiles01.selected 
				else
				(
					theString = ""
					theFS = filterString Krakatoa_GUI_Presets.ddl_historyFiles01.selected "_"
					for i = 1 to theFS.count-6 do theString+= theFS[i] + "_"
				)
				Krakatoa_GUI_Presets.edt_filter01.changed (Krakatoa_GUI_Presets.edt_filter01.text = theString)
			)	
		)	
		
		on mnu_getFromMaxScene picked do 
		(
			Krakatoa_GUI_Presets.edt_filter01.changed (Krakatoa_GUI_Presets.edt_filter01.text = getFileNameFile maxFileName)
		)	

		on mnu_clear picked do 
		(
			Krakatoa_GUI_Presets.edt_filter01.changed (Krakatoa_GUI_Presets.edt_filter01.text = "")
		)			
		
	)
	Krakatoa_RCMenu_Struct.HistoryPatternOptions01_RCMenu = HistoryPatternOptions01_RCMenu	
	
	rcmenu HistoryPatternOptions02_RCMenu 
	(
		fn filterFN =
		(
			Krakatoa_GUI_Presets.ddl_historyFiles01.selection > 1
		)	
		fn	filterSceneFN = Krakatoa_GUI_Presets.rad_files02.state == 2 and maxFileName != ""
		fn filterClearFN = Krakatoa_GUI_Presets.edt_filter02.text.count > 0
			
		menuitem mnu_getFromList "Get Search Pattern From RECORD Name" filter:filterFN 
		menuitem mnu_getFromMaxScene "Get Search Pattern From SCENE File Name" filter:filterSceneFN 
		menuitem mnu_clear "CLEAR Search Pattern" filter:filterClearFN 
		
		on mnu_getFromList picked do 
		(
			if Krakatoa_GUI_Presets.ddl_historyFiles02.selection > 0 do
			(
				if Krakatoa_GUI_Presets.rad_files02.state == 1 then 
					theString = Krakatoa_GUI_Presets.ddl_historyFiles02.selected 
				else
				(
					theString = ""
					theFS = filterString Krakatoa_GUI_Presets.ddl_historyFiles02.selected "_"
					for i = 1 to theFS.count-6 do theString+= theFS[i] + "_"
				)
				Krakatoa_GUI_Presets.edt_filter02.changed (Krakatoa_GUI_Presets.edt_filter02.text = theString)
			)	
		)	
		
		on mnu_getFromMaxScene picked do 
		(
			Krakatoa_GUI_Presets.edt_filter02.changed (Krakatoa_GUI_Presets.edt_filter02.text = getFileNameFile maxFileName)
		)	

		on mnu_clear picked do 
		(
			Krakatoa_GUI_Presets.edt_filter02.changed (Krakatoa_GUI_Presets.edt_filter02.text = "")
		)			
		
	)
	Krakatoa_RCMenu_Struct.HistoryPatternOptions02_RCMenu = HistoryPatternOptions02_RCMenu		

)--end local scope






--------------------------------------------------------------------------------------------------------------------------------------------------------------------	
--PRESETS AND HISTORY ROLLOUT	
--------------------------------------------------------------------------------------------------------------------------------------------------------------------	
rollout Krakatoa_GUI_Presets "Presets and History" rolledup:true category:3 width:457
(
	local theLockOffset = 0
	local ComparisonArray = #()
	local leftBitmap 
	local rightBitmap 
	local emptyBitmap
	local leftBitmapFileName = ""
	local rightBitmapFileName = ""
	local leftBitmapPreview, rightBitmapPreview 
	local theBitmap01
	local MissingBitmap1, MissingBitmap2
	local thePresetFiles = #()
	local theHistoryFiles = #() 
	local updateThumbnailsPreviewStrip
	
	button btn_Help_History  "Open Online Help..." height:16 width:100 align:#left offset:[-10,-5] across:3 tooltip:"Opens the Krakatoa Online Help for the Presets and History rollout in the default Web Browser. Requires Internet connection."
	button btn_BackTo_Main "Back To Main Controls..." height:16 width:328 offset:[40,-5] align:#center tooltip:"Closes the rollout and sets focus on\nthe Main Controls rollout."
	button btn_Float_Rollout ">" height:16 width:20 offset:[10,-5] align:#right tooltip:"Float/Dock the Rollout.\nRight-Click for Menu..." 
	on btn_BackTo_Main pressed do
	(
		Krakatoa_GUI_Presets.open = false
		FranticParticleRenderMXS.BackToMainControls()
	)		
	on btn_BackTo_Main rightclick do
	(
		Krakatoa_GUI_Presets.open = false
		FranticParticleRenderMXS.BackToMainControls()
	)		
	
	button btn_savePresetAll "Save Preset..." width:110 align:#left offset:[-10,-3] across:4 tooltip:"Press to open the Krakatoa Presets SAVE dialog."
	button btn_loadPresetAll "Load Preset..." width:110 align:#center offset:[-2,-3] tooltip:"Press to open the Krakatoa Presets LOAD dialog."
	button btn_loadHistory "Load From History..." width:110 align:#center offset:[4,-3] tooltip:"Press to open the Krakatoa History LOAD dialog."
	button btn_ExplorePresetDir "Explore Folder..." width:111 align:#right offset:[11,-3] tooltip:"Press to open the Krakatoa Presets/History folder in Windows Explorer to delete, copy, edit and otherwise manage Preset, History and Thumbnail files."
	
	checkbutton chk_SaveRenderHistory ">Save Render History" checked:true offset:[-6,-2] across:2 width:223 highlightcolor:KrakatoaSkinColorsStruct.History
	checkbutton chk_SaveImageSample ">Save Image Sample" checked:true offset:[5,-2] width:223 highlightcolor:KrakatoaSkinColorsStruct.History

	radiobuttons rad_files01 labels:#("Presets","History") across:5 align:#left default:2 offset:[0,-1] columns:2
	button btn_update "Update" width:60 height:20 align:#center tooltip:"Force a refresh the comparison list." offset:[20,-3] 
	button btn_align "Align" width:60 height:20 align:#center tooltip:"Align the comparison lists with an offset of one. Both lists must be in the same display mode - either Presets or History." offset:[-5,-3]
	checkbutton chk_lock ">Scroll Lock" width:70 height:20 offset:[-25,-3] align:#center tooltip:"Lock Selection in Left and Right drop-down list. Scrolling the one list will scoll the other with constant offset."  highlightcolor:KrakatoaSkinColorsStruct.History
	radiobuttons rad_files02 labels:#("Presets","History") align:#right offset:[8,-1] columns:2 default:2

	edittext edt_filter01 width:208 align:#left offset:[-14,-4] across:4
	button btn_filterOptions01 ">>" width:15 height:17 align:#left offset:[90,-4] 
	edittext edt_filter02 width:208 align:#right offset:[99,-4]
	button btn_filterOptions02 ">>" width:15 height:17 align:#right offset:[10,-4] 
	
	dropdownlist ddl_historyFiles01 items:#("[Current]") width:224 across:2 align:#left offset:[-10,-2]
	dropdownlist ddl_historyFiles02 items:#("[Current]") width:224 align:#right offset:[10,-2]
	
	listbox lbx_compareSettings width:451 align:#center height:6 offset:[-1,-4]
	
	edittext edt_settings01 width:190 align:#left offset:[-14,-4] across:4
	button btn_get01 "Set..." width:35 height:18 align:#left offset:[71,-4]
	edittext edt_settings02 width:190 align:#right offset:[83,-4]
	button btn_get02 "Set..." width:35 height:18 align:#right offset:[12,-4]
	
	listbox lbx_SceneInfo01 width:451 height:10 align:#center offset:[-1,-2]
	listbox lbx_SceneInfo02 width:451 height:10 align:#center offset:[-1,-7]

	button btn_openLeftStrip "Open Left Strip..." width:148 align:#left across:3 offset:[-10,-4]
	button btn_compareImages "Compare in RAM Player..." width:150 align:#center offset:[1,-4] tooltip:"Open one or both images (if available) in RAM Player for viewing or A|B comparison"
	button btn_openRightStrip "Open Right Strip..." width:148 align:#right offset:[11,-4]

	button btn_imagefile01 width:224 height:168 align:#left across:2 offset:[-10,-4]
	button btn_imagefile02 width:224 height:168 align:#right offset:[10,-4]
	
	fn updateIcons =
	(
		btn_Float_Rollout.images= #(Krakatoa_PresetsArrowBitmap,Krakatoa_PresetsArrowBitmap, 32,4,4,4,4)
		btn_filterOptions01.images = #(Krakatoa_PresetsArrowBitmap,Krakatoa_PresetsArrowBitmap, 32,1,1,2,2)
		btn_filterOptions02.images = #(Krakatoa_PresetsArrowBitmap,Krakatoa_PresetsArrowBitmap, 32,1,1,2,2)
	)	
	
	
	
	fn rebuildPresetsCache =
	(
		local st = timestamp()
		try(destroyDialog Krakatoa_GUI_FileSortingProgress_Dialog)catch()
		createDialog Krakatoa_GUI_FileSortingProgress_Dialog 400 40
		Krakatoa_GUI_FileSortingProgress_Dialog.prg_progress.visible = true
		FranticParticles.LogDebug (">Rebuilding Preset Cache...")
		local theFiles = getFiles (Krakatoa_PresetsDirectory + "\\presets\\*.KrakatoaPreset") 
		Krakatoa_GUI_FileSortingProgress_Dialog.lbl_feedback.text = "Sorting "+ theFiles.count as string +" Presets... This might take a while!"
		local theCache = createFile (Krakatoa_PresetsDirectory+"\\_PresetsCache.List")
		local cnt = 0
		local theSortedFiles = (FranticParticleRenderMXS.sortFilesByDate theFiles)
		Krakatoa_GUI_FileSortingProgress_Dialog.lbl_feedback.text = "Rebuilding Presets Cache with "+ theFiles.count as string +" Entries... This might take a while!"
		for f in theSortedFiles do 
		(
			format "%\n" (getFileNameFile f) to:theCache
			append thePresetFiles (getFileNameFile f)
			cnt += 1
			Krakatoa_GUI_FileSortingProgress_Dialog.prg_progress.value = 50.0*cnt/theFiles.count
		)	
		close theCache	
		FranticParticles.LogDebug (" +" + theFiles.count as string + " Preset File(s) Cached.")
		try(destroyDialog Krakatoa_GUI_FileSortingProgress_Dialog)catch()
		FranticParticles.LogDebug (" +Rebuilding Preset Cache FINISHED in " + (timestamp() - st) as string + "ms.")		
	)
	
	fn rebuildHistoryCache =
	(
		local st = timestamp()
		try(destroyDialog Krakatoa_GUI_FileSortingProgress_Dialog)catch()
		createDialog Krakatoa_GUI_FileSortingProgress_Dialog 400 40
		Krakatoa_GUI_FileSortingProgress_Dialog.prg_progress.visible = true
		FranticParticles.LogDebug (">Rebuilding History Cache...")
		local theFiles = getFiles (Krakatoa_PresetsDirectory + "\\history\\*.KrakatoaSettings") 
		Krakatoa_GUI_FileSortingProgress_Dialog.lbl_feedback.text = "Sorting "+ theFiles.count as string +" History files... This might take a while!"
		local theCache = createFile (Krakatoa_PresetsDirectory+"\\_HistoryCache.List")
		local cnt = 0
		local theSortedFiles = (FranticParticleRenderMXS.sortFilesByDate theFiles)
		Krakatoa_GUI_FileSortingProgress_Dialog.lbl_feedback.text = "Rebuilding History Cache with "+ theFiles.count as string +" Entries... This might take a while!"
		for f in theSortedFiles do
		(
			format "%\n" (getFileNameFile f) to:theCache
			append theHistoryFiles (getFileNameFile f)
			cnt += 1
			Krakatoa_GUI_FileSortingProgress_Dialog.prg_progress.value = 50+50.0*cnt/theFiles.count				
		)				
		close theCache	
		FranticParticles.LogDebug (" +" + theFiles.count as string + " History File(s) Cached.")
		try(destroyDialog Krakatoa_GUI_FileSortingProgress_Dialog)catch()
		FranticParticles.LogDebug (" +Rebuilding History Cache FINISHED in " + (timestamp() - st) as string + "ms.")
	)
	
	local buildThumbnailsPreviewStrip
	
	fn updateLists =
	(	
		local st = timestamp()
		FranticParticles.LogDebug (">Updating History and Preset Lists...")
		if not doesFileExist (Krakatoa_PresetsDirectory+"\\_PresetsCache.List") do
			rebuildPresetsCache()
		if not doesFileExist (Krakatoa_PresetsDirectory+"\\_HistoryCache.List")  do 
			rebuildHistoryCache()
		
		local theCache = openFile (Krakatoa_PresetsDirectory+"\\_PresetsCache.List")
		thePresetFiles = #()
		while not eof theCache do
			append thePresetFiles (readline theCache)
		close theCache	

		local theCache = openFile (Krakatoa_PresetsDirectory+"\\_HistoryCache.List")
		theHistoryFiles = #()
		while not eof theCache do
			append theHistoryFiles (readline theCache)
		close theCache	
		
		if theHistoryFiles.count != (getFiles (Krakatoa_PresetsDirectory + "\\history\\*.KrakatoaSettings") ).count do rebuildHistoryCache()
		if thePresetFiles.count != (getFiles (Krakatoa_PresetsDirectory + "\\presets\\*.KrakatoaPreset") ).count do rebuildPresetsCache()
		
		local thePattern01 = "*"
		local thePattern02 = "*"
		if edt_filter01.text != "" do thePattern01 = edt_filter01.text + "*"
		if edt_filter02.text != "" do thePattern02 = edt_filter02.text + "*"
		
		ddl_historyFiles01.items = if rad_files01.state == 2 then 
			for i = theHistoryFiles.count to 1 by -1 where matchPattern theHistoryFiles[i] pattern:thePattern01 collect theHistoryFiles[i]
		else	
			for i = thePresetFiles.count to 1 by -1 where matchPattern thePresetFiles[i] pattern:thePattern01 collect thePresetFiles[i]

		ddl_historyFiles02.items = if rad_files02.state == 2 then
			join #("[Current]") (for i = theHistoryFiles.count to 1 by -1 where matchPattern theHistoryFiles[i] pattern:thePattern02 collect theHistoryFiles[i]) 
		else	
			join #("[Current]") (for i = thePresetFiles.count to 1 by -1 where matchPattern thePresetFiles[i] pattern:thePattern02 collect thePresetFiles[i])	
		if ddl_historyFiles01.selection == 0 and ddl_historyFiles01.items.count > 0 do ddl_historyFiles01.selection = ddl_historyFiles01.items.count
		if ddl_historyFiles02.selection == 0 and ddl_historyFiles02.items.count > 0 do ddl_historyFiles02.selection = ddl_historyFiles02.items.count
		try(ddl_historyFiles01.tooltip = ddl_historyFiles01.selected)catch()
		try(ddl_historyFiles02.tooltip = ddl_historyFiles02.selected)catch()
		
		if Krakatoa_ThumbnailsPreviewStrip_Rollout_Left != undefined and Krakatoa_ThumbnailsPreviewStrip_Rollout_Left.open do buildThumbnailsPreviewStrip theSide:"Left"
		if Krakatoa_ThumbnailsPreviewStrip_Rollout_Right != undefined and Krakatoa_ThumbnailsPreviewStrip_Rollout_Right.open do buildThumbnailsPreviewStrip theSide:"Right"
			
		FranticParticles.LogDebug (" +Updating History and Preset Lists FINISHED in " + (timestamp() - st) as string + "ms." )
	)
	
	fn compareSettings =
	(
		local st = timestamp()
		FranticParticles.LogDebug (">Comparing Settings...")
		if ddl_historyFiles01.selection > 0 and ddl_historyFiles02.selection > 0 then
		(
			if rad_files01.state == 1 then
				file01 = Krakatoa_PresetsDirectory + "\\presets\\" + ddl_historyFiles01.selected + ".KrakatoaPreset"
			else	
				file01 = Krakatoa_PresetsDirectory + "\\history\\" + ddl_historyFiles01.selected+ ".KrakatoaSettings"
			if ddl_historyFiles02.selection == 1 then
			(
				file02 = Krakatoa_PresetsDirectory + "\\_CurrentSettings.KrakatoaSettings" 
				deleteFile file02
				FranticParticleRenderMXS.savePresetAll file02
			)	
			else
			(			
				if rad_files02.state == 1 then
					file02 = Krakatoa_PresetsDirectory + "\\presets\\" + ddl_historyFiles02.selected+ ".KrakatoaPreset"
				else	
					file02 = Krakatoa_PresetsDirectory + "\\history\\" + ddl_historyFiles02.selected+ ".KrakatoaSettings"
			)		
				
			ComparisonArray = FranticParticleRenderMXS.compareSettings file01 file02
			local tempArray = #()
			for i in ComparisonArray do
			(
				local theRollout = execute i[1]
				if theRollout != undefined then
					theRolloutName = theRollout.title
				else
					theRolloutName = i[1]
				if matchPattern theRolloutName pattern:"Krakatoa:*" do theRolloutName = substring theRolloutName 11 -1					
				if matchPattern theRolloutName pattern:"Krakatoa_*" do theRolloutName = substring theRolloutName 10 -1					
					
				local theRolloutControl = try(execute (i[1] + "." + i[2]))catch(undefined)
				local theRolloutControlName = if theRolloutControl == undefined then  
				(
					i[2] 
				)	
				else 
				(
					if theRolloutControl.caption == "" then 
						if matchPattern theRolloutControl.name pattern:"ddl_*" then substring theRolloutControl.name 5 -1 else theRolloutControl.name
					else 
						if matchPattern theRolloutControl.name pattern:"pkb_*" then substring theRolloutControl.name 5 -1 else theRolloutControl.caption
				)	
				append tempArray  (theRolloutName  +": "+ theRolloutControlName + " ["+ i[3] + "]>>[" + i[4] + "]")
			)
			lbx_compareSettings.items = tempArray
			if tempArray.count > 0 and lbx_compareSettings.selection > 0 then 
			(
				edt_settings01.text = ComparisonArray[lbx_compareSettings.selection][3]
				edt_settings02.text = ComparisonArray[lbx_compareSettings.selection][4]			
			)
			else
				edt_settings01.text = edt_settings02.text = ""
			edt_settings02.enabled = btn_get02.enabled = ddl_historyFiles02.selection > 1 	
			
			tempArray1 = #()
			theKeys = getIniSetting file01 "SceneInfo"
			for k in theKeys do 
			(
				if k == "RenderTime" or k=="SaveTime" then
				(
					local theVal = getIniSetting file01 "SceneInfo" k
					local theTime1 = (filterString theVal " ")[1]
					local theVal2 = getIniSetting file02 "SceneInfo" k
					if theVal2 == "" then
						append tempArray1 (k + ":" + theVal)
					else
					(
						local theTime2 = (filterString theVal2 " ")[1]
						local theDifference = execute (theTime1 +"-"+theTime2)
						local theFactor = execute ("1.0*"+theTime1 +"/"+theTime2)
						local theSign = if theDifference > 0 then " slower" else if theDifference == 0 then "" else " faster"
						append tempArray1 (k + ":" + theVal + " (" + (abs theDifference) as string + " seconds"+theSign+" : "+theFactor as string+"x)")
					)
				)
				else
					append tempArray1 (k + ":" + getIniSetting file01 "SceneInfo" k)
			)
			lbx_SceneInfo01.items = tempArray1	
	
			tempArray2 = #()
			theKeys = getIniSetting file02 "SceneInfo"
			for k in theKeys do 
			(
				if k == "RenderTime" or k=="SaveTime" then
				(
					local theVal = getIniSetting file02 "SceneInfo" k
					local theTime1 = (filterString theVal " ")[1]
					local theVal2 = getIniSetting file01 "SceneInfo" k
					if theVal2 == "" then
						append tempArray2 (k + ":" + theVal)
					else
					(
						local theTime2 = (filterString theVal2 " ")[1]
						local theDifference = execute (theTime1 +"-"+theTime2)
						local theFactor = execute ("1.0*"+theTime1 +"/"+theTime2)
						local theSign = if theDifference > 0 then " slower" else if theDifference == 0 then "" else " faster"
						append tempArray2 (k + ":" + theVal + " (" + (abs theDifference) as string + " seconds"+theSign+" : "+theFactor as string+"x)")
					)
				)
				else
					append tempArray2 (k + ":" + getIniSetting file02 "SceneInfo" k)
			)
			lbx_SceneInfo02.items = tempArray2	

			theSample01 = getIniSetting file01 "SampleImage" "Filename"
			if theSample01 != "" then
			(
				theSample01 = Krakatoa_PresetsDirectory + "\\samples\\" + theSample01
				theCache01 = getFileNamePath theSample01 + getFileNameFile theSample01 + ".JPG"
				if doesFileExist theCache01 then
				(
					theBitmap01 = openBitmap theCache01
					copy theBitmap01 leftBitmap 
					theBitmap01 = undefined
					btn_imagefile01.images = #(leftBitmap, emptyBitmap, 1,1,1,1,1 )
					leftBitmapFileName = theSample01 
				)
				else if doesFileExist theSample01 then
				(
					theBitmap01 = openBitmap theSample01
					local tempBitmap = bitmap 213 160
					copy theBitmap01 tempBitmap
					theBitmap01 = undefined
					tempBitmap.filename = theCache01
					save tempBitmap
					close tempBitmap
					leftBitmap = openBitmap theCache01
					btn_imagefile01.images = #(leftBitmap, emptyBitmap, 1,1,1,1,1 )
					leftBitmapFileName = theSample01 
				)	
				else
				(
					copy MissingBitmap1 leftBitmap
					btn_imagefile01.images = #(leftBitmap, emptyBitmap, 1,1,1,1,1 )
					leftBitmapFileName = ""					
				)
			)
			else
			(
				copy MissingBitmap2 leftBitmap
				btn_imagefile01.images = #(leftBitmap, emptyBitmap, 1,1,1,1,1 )
				leftBitmapFileName = ""
			)	

			theSample02 = getIniSetting file02 "SampleImage" "Filename"
			if theSample02 != "" then
			(
				theSample02 = Krakatoa_PresetsDirectory + "\\samples\\" + theSample02
				theCache02 = getFileNamePath theSample02 + getFileNameFile theSample02 + ".JPG"
				if doesFileExist theCache02 then
				(
					theBitmap01 = openBitmap theCache02
					copy theBitmap01 rightBitmap 
					theBitmap01 = undefined
					btn_imagefile02.images = #(rightBitmap, emptyBitmap, 1,1,1,1,1 )
					rightBitmapFileName = theSample02
				)
				else if doesFileExist theSample02 then 
				(
					theBitmap01 = openBitmap theSample02 
					local tempBitmap = bitmap 213 160
					copy theBitmap01 tempBitmap 
					tempBitmap.filename = theCache02
					save tempBitmap 
					close tempBitmap 
					tempBitmap = undefined
					theBitmap01 = undefined
					rightBitmap	= openBitmap theCache02
					btn_imagefile02.images = #(rightBitmap, emptyBitmap, 1,1,1,1,1 )
					rightBitmapFileName = theSample02
				)	
				else
				(
					copy MissingBitmap1 rightBitmap
					btn_imagefile02.images = #(rightBitmap, emptyBitmap, 1,1,1,1,1 )	
					rightBitmapFileName = ""
				)						
			)
			else
			(
				copy MissingBitmap2 rightBitmap				
				btn_imagefile02.images = #(rightBitmap, emptyBitmap, 1,1,1,1,1 )	
				rightBitmapFileName = ""
			)	
		)--end if	
		FranticParticles.LogDebug (" +Comparing Settings FINISHED in " + (timestamp() - st) as string + "ms." )
	)
	
	fn ddl_historyFiles01_SelectedFN itm =
	(
		ddl_historyFiles01.selection = itm
		if chk_lock.checked do 
		(
			theOffset = itm - theLockOffset
			if theOffset > 0 and theOffset <=ddl_historyFiles02.items.count do
				ddl_historyFiles02.selection = theOffset
		)	
		compareSettings()
		try(ddl_historyFiles01.tooltip = ddl_historyFiles01.selected)catch()	
	)
	
	fn ddl_historyFiles02_SelectedFN itm =
	(
		ddl_historyFiles02.selection = itm
		if chk_lock.checked do 
		(
			theOffset = itm + theLockOffset 
			if theOffset > 0 and theOffset <=ddl_historyFiles01.items.count do
				ddl_historyFiles01.selection = theOffset
		)	
		compareSettings()
		try(ddl_historyFiles02.tooltip = ddl_historyFiles02.selected)catch()
	)	
	
	fn getThumbnailBitmap theFilename =
	(
		theResult = bitmap 110 82
		copy MissingBitmap2 theResult 
		if theFilename == "" do return theResult
		theSample01 = Krakatoa_PresetsDirectory + "\\samples\\" + theFilename
		theCache01 = getFileNamePath theSample01 + getFileNameFile theFilename + ".JPG"
		if doesFileExist theSample01 then
		(
			if not doesFileExist theCache01 then
			(
				local leftBitmap = bitmap 213 160
				theBitmap01 = openBitmap theSample01
				copy theBitmap01 leftBitmap
				close theBitmap01
				leftBitmap.filename = theCache01
				save leftBitmap
				copy leftBitmap theResult
				close leftBitmap
				leftBitmap = undefined
				theBitmap01 = undefined
			)
			else
			(
				theBitmap01 = openBitmap theCache01
				copy theBitmap01 theResult
				close theBitmap01
				theBitmap01 = undefined
			)
		)
		theResult	
	)
	
	fn ThumbnailStripButtonPressed theIndex theSide =
	(
		if theSide == #left then
			ddl_historyFiles01_SelectedFN (ddl_historyFiles01.items.count-theIndex+1)
		else
			ddl_historyFiles02_SelectedFN (ddl_historyFiles02.items.count-theIndex+1)
		
		try(updateThumbnailsPreviewStrip theSide:"Left")catch()
		try(updateThumbnailsPreviewStrip theSide:"Right")catch()
	)
	
	fn showSampleFile theIndex theSide  =
	(
		local theSample = if theSide == #left then
			getIniSetting (Krakatoa_PresetsDirectory + "\\history\\" +ddl_historyFiles01.items[ddl_historyFiles01.items.count-theIndex+1] + ".KrakatoaSettings") "SampleImage" "Filename"
		else
			getIniSetting (Krakatoa_PresetsDirectory + "\\history\\" +ddl_historyFiles02.items[ddl_historyFiles02.items.count-theIndex+1] + ".KrakatoaSettings") "SampleImage" "Filename"
		if theSample != "" then
		(
			theSampleImage = Krakatoa_PresetsDirectory + "\\samples\\" + theSample
			if doesFileExist theSampleImage do
			(
				leftBitmapPreview = openbitmap theSampleImage 
				display leftBitmapPreview 					
			)
		)
	)
	
	fn updateThumbnailsPreviewStrip theSide:"Left" =
	(
		try (
		case theSide of
		(
			"Left": Krakatoa_ThumbnailsPreviewStrip_Rollout_Left.spn_currentPos.changed (Krakatoa_ThumbnailsPreviewStrip_Rollout_Left.spn_currentPos.value = ddl_historyFiles01.items.count-ddl_historyFiles01.selection+1)
			"Right": Krakatoa_ThumbnailsPreviewStrip_Rollout_Right.spn_currentPos.changed (Krakatoa_ThumbnailsPreviewStrip_Rollout_Right.spn_currentPos.value = ddl_historyFiles02.items.count-ddl_historyFiles02.selection+1)
		)
		)catch()
	)
	
	fn buildThumbnailsPreviewStrip theSide:"Left" =
	(
		local st = timestamp()
		local theCount = (ceil ((execute (FranticParticles.GetProperty "GUI:Size")).y)/83) as integer
		
		txt = stringStream ""
		txt2 = stringStream ""
		
		format "local imagesArray = #(" to:txt2
		format "try(destroyDialog Krakatoa_ThumbnailsPreviewStrip_Rollout_%)catch()\n" theSide to:txt
		format "gc light:true\n" to:txt
		format "rollout Krakatoa_ThumbnailsPreviewStrip_Rollout_% \"% Strip\" (\n" theSide theSide to:txt
		format "local theScrollbarBGDefault \n" to:txt
		format "local theScrollbarBG\n" to:txt
		format "local theScrollbarHandle\n" to:txt
		
		format "local theMouseDown = false\n" to:txt
		format "local theScrollbarValue = 0\n" to:txt
		format "local theScrollbarHeight = (%*83)\n" theCount to:txt
		format "local theHandleHeight = 20\n" to:txt

		format "local emptyBitmap\n" to:txt
		format "local heapFreeValue = heapFree\n" to:txt
		format "local theListToConnectTo = if % then Krakatoa_GUI_Presets.ddl_historyFiles01 else Krakatoa_GUI_Presets.ddl_historyFiles02 \n" (theSide == "Left") to:txt 
		format "local totalCount = theListToConnectTo.items.count\n" to:txt
		format "local currentIndex = (theListToConnectTo.items.count-theListToConnectTo.selection+1) \n"  to:txt
		
		format "button btn_up \"Page Up\" width:55 height:18 align:#left across:2 offset:[-12,-5] tooltip:(\"Left-click to go ONE PAGE UP. \nRight-click to go HALF A PAGE UP.\")\n" to:txt
		format "button btn_down \"Page Down\" width:62 height:18 align:#right offset:[12,-5] tooltip:(\"Left-click to go ONE PAGE DOWN. \nRight-click to go HALF A PAGE DOWN.\")\n" to:txt
		format "spinner spn_currentPos offset:[-14,-4] fieldwidth:58 align:#left across:2 type:#integer\n " to:txt
		format "button btn_totalCount \" of %\" width:50 height:18 align:#right offset:[12,-5] tooltip:\"Left-click to go to latest image. \nRight-click to go to the oldest image.\"\n" Krakatoa_GUI_Presets.ddl_historyFiles01.items.count to:txt
		format "progressbar prg_progress width:120 height:6 color:red align:#center value:100 offset:[0,-4]\n" to:txt
		
		for i = 1 to theCount do
		(
			
			format "button btn_strip_% width:110 height:82 align:#center offset:[-5,-4]\n" i to:txt
			format "local img_strip_%\n" i to:txt
			format "img_strip_%," i to:txt2
			format "on btn_strip_% pressed do \n" i to:txt
			format "Krakatoa_GUI_Presets.ThumbnailStripButtonPressed (currentIndex-%+1) #%\n" i theSide to:txt
			format "on btn_strip_% rightclick do \n" i to:txt
			format "Krakatoa_GUI_Presets.showSampleFile (currentIndex-%+1) #%\n" i theSide to:txt
		)--end i loop
		
		format "undefined)\n" to:txt2
		format "%" (txt2 as string) to:txt

		format "bitmap img_scrollbar height:theScrollbarHeight width:8 pos:[112,44] \n" to:txt

		format "fn updateThumbnails = (\n" to:txt
		format "for i = 1 to % do (\n" theCount to:txt
		format "prg_progress.value = 100.0*i/%\n" theCount to:txt
		format "if currentIndex-i+1 <= totalCount and totalCount != 0 and currentIndex-i+1 > 0 then (\n" to:txt
		format "local theItem = Krakatoa_PresetsDirectory + \"\\\\history\\\\\" + theListToConnectTo.items[theListToConnectTo.items.count-currentIndex+i]+ \".KrakatoaSettings\" \n" to:txt
		format "local theSample01 = getIniSetting theItem \"SampleImage\" \"Filename\"	\n" to:txt
		format "imagesArray[i]= Krakatoa_GUI_Presets.getThumbnailBitmap theSample01 \n" to:txt
		format "Krakatoa_ThumbnailsPreviewStrip_Rollout_%.controls[i+5].visible = true\n" theSide to:txt
		format "Krakatoa_ThumbnailsPreviewStrip_Rollout_%.controls[i+5].images = #(imagesArray[i], emptyBitmap, 1,1,1,1,1) \n" theSide to:txt
		format "Krakatoa_ThumbnailsPreviewStrip_Rollout_%.controls[i+5].tooltip =  theListToConnectTo.items[theListToConnectTo.items.count-currentIndex+i]\n" theSide to:txt
		format ")else(\n" to:txt
		format "if currentIndex-i <= 0 then (\n" to:txt
		format "Krakatoa_ThumbnailsPreviewStrip_Rollout_%.controls[i+5].visible = false\n" theSide to:txt
		format ")else(\n" to:txt
		format "Krakatoa_ThumbnailsPreviewStrip_Rollout_%.controls[i+5].visible = true\n" theSide to:txt
		format "Krakatoa_ThumbnailsPreviewStrip_Rollout_%.controls[i+5].images = #(emptyBitmap, emptyBitmap, 1,1,1,1,1) \n" theSide to:txt
		format "Krakatoa_ThumbnailsPreviewStrip_Rollout_%.controls[i+5].tooltip =  \"No Record.\"\n" theSide to:txt
		format "))--end if\n" to:txt
		format ")--end i loop\n" to:txt
		format "if (heapFreeValue - heapFree) > 1000000.0 do (heapFreeValue = heapFree; gc light:true)\n"  to:txt
		format "prg_progress.value = 0)--end fn\n" to:txt

		format "fn updateScrollbar theVal = (\n" to:txt
		format "copy theScrollbarBGDefault theScrollbarBG\n" to:txt
		format "pasteBitmap theScrollbarHandle theScrollbarBG [0,0] [0,theVal]\n" to:txt
		format "img_scrollbar.bitmap = theScrollbarBG\n" to:txt
		format ")--end fn\n" to:txt

		format "on spn_currentPos changed val do (\n" to:txt
		format "currentIndex = spn_currentPos.value\n" to:txt
		format "if not theMouseDown do updateScrollbar (theScrollbarValue = ceil ((theScrollbarHeight-20) * (1.0-1.0*currentIndex / totalCount)))\n" to:txt
		format "updateThumbnails()\n" to:txt
		
		format ")\n" to:txt
		
		format "fn mouseMoveUpdate theVal = (\n" to:txt
		format "if theMouseDown do (\n" to:txt
		format "theScrollbarValue = (theVal-[112,44]).y\n" to:txt
		format "if theScrollbarValue > theScrollbarHeight-theHandleHeight do theScrollbarValue = theScrollbarHeight-theHandleHeight\n" to:txt
		format "if theScrollbarValue < 1 do theScrollbarValue = 1\n" to:txt
		format "currentIndex = (totalCount*(1.0-theScrollbarValue/(theScrollbarHeight-theHandleHeight))) as integer\n" to:txt
		format "if currentIndex > totalCount do currentIndex = totalCount\n" to:txt
		format "if currentIndex < 1 do currentIndex = 1\n" to:txt
		format "updateScrollbar theScrollbarValue\n" to:txt
		format "if currentIndex != 0 do spn_currentPos.changed (spn_currentPos.value = currentIndex)\n" to:txt
		format "))\n" to:txt			
		
		format "on Krakatoa_ThumbnailsPreviewStrip_Rollout_% lbuttondown thePos do (if thePos.x>110 and thePos.y > 43 do (theMouseDown = true; mouseMoveUpdate (thePos-10)))\n" theSide to:txt
		format "on Krakatoa_ThumbnailsPreviewStrip_Rollout_% lbuttonup thePos do theMouseDown = false\n" theSide to:txt

		format "on Krakatoa_ThumbnailsPreviewStrip_Rollout_% mousemove thePos do mouseMoveUpdate (thePos-10)\n" theSide to:txt
		
		format "on btn_totalCount pressed do spn_currentPos.changed (spn_currentPos.value = totalCount) \n" to:txt
		format "on btn_totalCount rightclick do spn_currentPos.changed (spn_currentPos.value = 1) \n" to:txt
		
		format "on Krakatoa_ThumbnailsPreviewStrip_Rollout_% open do (\n" theSide to:txt
		format "theScrollbarBG = bitmap 8 theScrollbarHeight color:(white*0.1)\n" to:txt
		format "theScrollbarBGDefault = bitmap 8 theScrollbarHeight color:(white*0.1)\n" to:txt
		format "theScrollbarHandle = bitmap 8 theHandleHeight color:(white*0.5)\n" to:txt
		format "theColors = for i = 1 to 8 collect (white*0.85)\n" to:txt
		format "for i = 0 to 7 by 2 do setPixels theScrollbarHandle [0,7+i] theColors\n" to:txt
		
		format "emptyBitmap = bitmap 110 80 color:(red*0.7)\n" to:txt
		format "copy Krakatoa_GUI_Presets.MissingBitmap2 emptyBitmap\n" to:txt
		format "if totalCount < 0 do totalCount = 0\n" to:txt
		format "spn_currentPos.range = [1,totalCount, currentIndex]\n" to:txt
		format "spn_currentPos.changed (spn_currentPos.value = currentIndex))\n" to:txt
		
		format "fn pageDown theVal = (currentIndex-=theVal; if currentIndex < 1 do currentIndex = 1; spn_currentPos.value = currentIndex; updateThumbnails())\n" to:txt
		format "fn pageUp theVal = (currentIndex+=theVal; if currentIndex > totalCount do currentIndex = totalCount ; spn_currentPos.value = currentIndex; updateThumbnails())\n" to:txt
		
		format "on btn_down pressed do pageDown(%)\n" theCount to:txt
		format "on btn_down rightclick do pageDown(%)\n" (theCount/2) to:txt
		
		format "on btn_up pressed do pageUp(%)\n" (theCount) to:txt
		format "on btn_up rightclick do pageUp(%)\n" (theCount/2) to:txt
	
		format ")\n" to:txt
		format "createDialog Krakatoa_ThumbnailsPreviewStrip_Rollout_% 120 %  pos:(Krakatoa_Gui_floater.pos+%) \n"	theSide	(45+theCount*83) (if theSide == "Left" then "[-126,0]" else "[484,0]") to:txt
		
		execute (txt as string)
		Krakatoa_CustomizeRollouts_Dialog.updateStripsPositions [0,0]
	)
	
	on btn_imagefile01 rightclick do buildThumbnailsPreviewStrip theSide:"Left"
	on btn_imagefile02 rightclick do buildThumbnailsPreviewStrip theSide:"Right"
		
	on btn_openLeftStrip pressed do buildThumbnailsPreviewStrip theSide:"Left"
	on btn_openRightStrip pressed do buildThumbnailsPreviewStrip theSide:"Right"

	on btn_filterOptions01 pressed do 
	(
		popupMenu Krakatoa_RCMenu_Struct.HistoryPatternOptions01_RCMenu pos:mouse.screenpos
	)
	on btn_filterOptions01 rightclick do 
	(
		popupMenu Krakatoa_RCMenu_Struct.HistoryPatternOptions01_RCMenu pos:mouse.screenpos
	)	
	on btn_filterOptions02 pressed do 
	(
		popupMenu Krakatoa_RCMenu_Struct.HistoryPatternOptions02_RCMenu pos:mouse.screenpos
	)
	on btn_filterOptions02 rightclick do 
	(
		popupMenu Krakatoa_RCMenu_Struct.HistoryPatternOptions02_RCMenu pos:mouse.screenpos
	)	
	
	on edt_filter01 changed txt do 
	(
		updateLists()
		compareSettings()
		setFocus edt_filter01
	)
	on edt_filter02 changed txt do
	(
		updateLists()
		compareSettings()
		setFocus edt_filter02
	)
	
	on btn_compareImages pressed do
	(
		if doesFileExist leftBitmapFileName and doesFileExist rightBitmapFileName then
			RAMPlayer leftBitmapFileName rightBitmapFileName 
			else if not doesFileExist leftBitmapFileName and doesFileExist rightBitmapFileName then
				RAMPlayer "" rightBitmapFileName 
				else if doesFileExist leftBitmapFileName and not doesFileExist rightBitmapFileName then
					RAMPlayer leftBitmapFileName "" 
	)
	
	on btn_imagefile01 pressed do 
	(
		if doesFileExist leftBitmapFileName do 
		(
			leftBitmapPreview = openbitmap leftBitmapFileName 
			display leftBitmapPreview 
		)	
	)	
	
	on btn_imagefile02 pressed do 
	(
		if doesFileExist rightBitmapFileName do 
		(
			rightBitmapPreview = openbitmap rightBitmapFileName 
			display rightBitmapPreview 
		)	
	)	
	on btn_deletePreset01 pressed do
	(
		if ddl_historyFiles01.selection > 0  then
		(
			local q = yesnocancelbox ("Click YES to delete both [" +ddl_historyFiles01.selected +"] and its Thumbnail.\nClick NO to delete the Thumbnail only.\nClick CANCEL to not delete anything.") title:"Delete"
			local theInfoFile = if rad_files01.state == 1 then
				Krakatoa_PresetsDirectory + "\\presets\\" + ddl_historyFiles01.selected + ".KrakatoaPreset"
			else	
				Krakatoa_PresetsDirectory + "\\history\\" + ddl_historyFiles01.selected+ ".KrakatoaSettings"			
			if q != #cancel and doesFileExist leftBitmapFileName do deleteFile leftBitmapFileName 
			if q == #yes do deleteFile theInfoFile 
			if q != #cancel do 
			(
				updateLists()
				compareSettings()		
			)	
		)		
	)
	on btn_deletePreset02 pressed do
	(
		if ddl_historyFiles02.selection > 1 then
		(
			local q = yesnocancelbox ("Click YES to delete both [" +ddl_historyFiles02.selected +"] and its Thumbnail.\nClick NO to delete the Thumbnail only.\nClick CANCEL to not delete anything.") title:"Delete"
			local theInfoFile = if rad_files02.state == 1 then
				Krakatoa_PresetsDirectory + "\\presets\\" + ddl_historyFiles02.selected + ".KrakatoaPreset"
			else	
				Krakatoa_PresetsDirectory + "\\history\\" + ddl_historyFiles02.selected+ ".KrakatoaSettings"			
			if q != #cancel and doesFileExist rightBitmapFileName do deleteFile rightBitmapFileName 
			if q == #yes do deleteFile theInfoFile 
			if q != #cancel do
			(
				updateLists()
				compareSettings()	
			)	
		)		
	)		


	fn setCurrentValue valueIndex =
	(
		if lbx_compareSettings.selection > 0 do
		(
			theItem = ComparisonArray[lbx_compareSettings.selection]
			local theRollout = execute theItem[1]
			local theControl = try(execute (theItem[1] + "." + theItem [2]))catch(undefined)
			if theControl != undefined do
			(
				theValue = theItem[valueIndex]
				case classof theControl of
				(
					SpinnerControl: try(theControl.changed (theControl.value = execute theValue))catch()
					CheckButtonControl:	try(theControl.changed (theControl.state = execute theValue))catch()
					ColorPickerControl: try(theControl.changed (theControl.color = execute theValue))catch()
					ListBoxControl: (
						if theControl == Krakatoa_GUI_MatteObjects.lbx_useNamedSelectionSets do
							(theControl.items = execute theValue; Krakatoa_GUI_MatteObjects.saveSelectionSets();Krakatoa_GUI_MatteObjects.updateSelectionSets())
					)
					PickerControl: 
					(
					)	
					MultiListBoxControl: (
							if theControl== Krakatoa_GUI_SaveParticles.lbx_activeChannels do
							(
								try
								(
									FranticParticles.setProperty "ActiveParticleChannels" theValue
									Krakatoa_GUI_SaveParticles.populateLists()
								)catch()
							)							
					)
					ComboBoxControl: (
										try(
											theFN = execute (theRollout.name +"." + theControl.name + "_SelectedFN")
											theFN (theControl.selection = findItem theControl.items theValue)
										)catch()
									)			
					EditTextControl: try(theControl.entered (theControl.text = theValue))catch()							
				)
			)
			if ddl_historyFiles02.selection == 1 do compareSettings()		
		)	
	)

	fn Refresh_GUI =
	(
		/*local theState =  execute (getIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "RolloutVisible" Krakatoa_GUI_Presets.title) 
		if theState == OK do theState = true
		if not theState and Krakatoa_Initializing_Hidden_Rollouts == false do return false 				*/
		
		if Krakatoa_Initializing_Hidden_Rollouts == false do 
			try(Krakatoa_GUI_Presets.open = FranticParticles.GetBoolProperty "GUI:PresetsRolloutOpen")catch()
		try(chk_SaveImageSample.state = FranticParticles.GetBoolProperty "Presets:SaveImageSample" )catch()
		try(chk_SaveRenderHistory.state = FranticParticles.GetBoolProperty  "Presets:SaveRenderHistory" )catch()
		if Krakatoa_GUI_Presets.open do 
		(
			updateLists()
			compareSettings()
		)	
	)
	
	on Krakatoa_GUI_Presets rolledUp val do 
	(
			FranticParticles.SetProperty "GUI:PresetsRolloutOpen" (val as string)
			if val then 
			(
				updateLists()
				compareSettings()
				FranticParticles.LogDebug ("+Presets Rollout ROLLED DOWN.")
			)	
			else
				FranticParticles.LogDebug ("+Presets Rollout ROLLED UP.")
	)	


	
	
	on chk_SaveRenderHistory changed state do 
	(
		FranticParticles.SetProperty "Presets:SaveRenderHistory" (state as string)
		try(Krakatoa_VFB_Overlay_Rollout.Refresh_GUI())catch()
	)
	on chk_SaveImageSample changed state do
	(
		FranticParticles.SetProperty "Presets:SaveImageSample" (state as string)
		try(Krakatoa_VFB_Overlay_Rollout.Refresh_GUI())catch()
	)	
	
	on btn_savePresetAll pressed do
	(
		FranticParticleRenderMXS.LoadSave_SingleRollout = undefined
		FranticParticleRenderMXS.UpdateAllHiddenRollouts()
		FranticParticleRenderMXS.PresetFilterString = ""
		Krakatoa_PresetDialogMode = #save
		FranticParticleRenderMXS.displaySavePresetDialog()
		updateLists()
		compareSettings()
	)

	on btn_loadPresetAll pressed do
	(
		FranticParticleRenderMXS.LoadSave_SingleRollout = undefined
		FranticParticleRenderMXS.PresetFilterString = ""
		Krakatoa_PresetDialogMode = #load
		FranticParticleRenderMXS.displaySavePresetDialog()
		updateLists()
		compareSettings()			
	)

	on btn_loadHistory pressed do
	(
		FranticParticleRenderMXS.LoadSave_SingleRollout = undefined
		FranticParticleRenderMXS.PresetFilterString = ""
		Krakatoa_PresetDialogMode = #loadHistory
		FranticParticleRenderMXS.displaySavePresetDialog()
		updateLists()
		compareSettings()
	)		
	
	on btn_ExplorePresetDir pressed do
		ShellLaunch "Explorer.exe" (Krakatoa_PresetsDirectory)
	
	on lbx_compareSettings selected itm do
	(
		edt_settings01.text = ComparisonArray[itm][3]
		edt_settings02.text = ComparisonArray[itm][4]
		btn_get02.enabled = edt_settings02.enabled =ddl_historyFiles02.selection > 1 
	)	
	
	on lbx_compareSettings doubleClicked itm do
		setCurrentValue (if ddl_historyFiles02.selection == 1 then 3 else 4)
	
	on btn_get01 pressed do
		setCurrentValue 3

	on btn_get02 pressed do
		setCurrentValue 4
	
	on btn_update pressed do 
	(
		updateLists()
		compareSettings()
	)	
	
	on rad_files01 changed state do 
	(
		updateLists()
		compareSettings()
	)
	on rad_files02 changed state do 
	(
		updateLists()
		compareSettings()
	)
	
	on ddl_historyFiles01 selected itm do 
	(
		ddl_historyFiles01_SelectedFN itm
		try(updateThumbnailsPreviewStrip theSide:"Left")catch()
		try(updateThumbnailsPreviewStrip theSide:"Right")catch()
		setFocus ddl_historyFiles01
	)
	
	on ddl_historyFiles02 selected itm do 
	(
		ddl_historyFiles02_SelectedFN itm
		try(updateThumbnailsPreviewStrip theSide:"Left")catch()
		try(updateThumbnailsPreviewStrip theSide:"Right")catch()
		setFocus ddl_historyFiles02
	)
	
	on btn_align pressed do
	(
		if rad_files01.state == rad_files02.state then
		(
			ddl_historyFiles02.selection = ddl_historyFiles01.selection
			theLockOffset = 1
			compareSettings()
			if Krakatoa_ThumbnailsPreviewStrip_Rollout_Right != undefined and Krakatoa_ThumbnailsPreviewStrip_Rollout_Right.open do 
			(
				updateThumbnailsPreviewStrip theSide:"Right"
				setFocus btn_align
			)
		)	
	)
	
	on chk_lock changed state do 
		if state then theLockOffset = ddl_historyFiles01.selection - ddl_historyFiles02.selection

	fn doubleClickInfo theString =
	(
		if matchPattern theString pattern:"Path:*" then
		(
			local thePath = getFileNamePath (substring theString 6 -1)
			format "%\n" thePath
			if doesFileExist thePath do ShellLaunch "Explorer.exe" thePath
		)	
		else if matchPattern theString pattern:"Output:*" then
		(
			local thePath = (substring theString 8 -1)
			format "%\n" thePath
			if doesFileExist (getFileNamePath thePath) do ShellLaunch "Explorer.exe" (getFileNamePath thePath)
		)	
		else if matchPattern theString pattern:"ViewTM:*" then
		(
			local theTM = try(execute (substring theString 8 -1))catch(undefined)
			format "%\n" theTM
			if classof theTM == Matrix3 do 
			(
				viewport.setType #view_persp_user
				try(viewport.setTM theTM)catch()
			)
		)
		else if matchPattern theString pattern:"Camera:*" then
		(
			local theCamera = getNodeByName (substring theString 8 -1)
			if isValidNode theCamera and viewport.CanSetToViewport theCamera do
			(
				viewport.setCamera theCamera
			)
		)
		else if matchPattern theString pattern:"Frame:*" then 
		(
			try(sliderTime = execute ((filterString theString ":")[2]))catch()
		)
		else format "%\n" theString
	)
	
	on lbx_SceneInfo01 doubleClicked itm do
	(
		doubleClickInfo lbx_SceneInfo01.selected
	)
	on lbx_SceneInfo02 doubleClicked itm do
	(
		doubleClickInfo lbx_SceneInfo02.selected
	)		
	

	on btn_Float_Rollout pressed do
	(
		FranticParticleRenderMXS.FloatRolloutButtonPressed Krakatoa_GUI_Presets
	)		

	on btn_Float_Rollout rightClick do
	(
		Krakatoa_RCMenu_Struct.Float_Rollout_RCMenu_CurrentRollout = Krakatoa_GUI_Presets
		popupMenu Krakatoa_RCMenu_Struct.Float_Rollout_RCMenu pos:mouse.screenpos
	)

	on Krakatoa_GUI_Presets moved pos do
	(
		setIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "RolloutDialogPositions" Krakatoa_GUI_Presets.title (pos as string)
		Krakatoa_CustomizeRollouts_Dialog.updateStripsPositions pos
	)
	
	on Krakatoa_GUI_Presets close do 
	(
		if Krakatoa_GUI_Presets.inDialog and not Krakatoa_Closing_Floater and not Krakatoa_Initializing_Hidden_Rollouts then
		(
			setIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "RolloutVisible" Krakatoa_GUI_Presets.title "false"
			FranticParticleRenderMXS.floatOrDockRollout Krakatoa_GUI_Presets forceMode:#hide
			Krakatoa_CustomizeRollouts_Dialog.Refresh_GUI()
		)	
	)	

	on Krakatoa_GUI_Presets open do 
	(
		updateIcons()
		leftBitmap = bitmap 213 160
		rightBitmap = bitmap 213 160
		emptyBitmap = bitmap 213 160 color:(white*0.5)
		
		MissingBitmap1 = bitmap 220 165 color:(white*0.5)
		MissingBitmap2 = bitmap 220 165 color:(white*0.7)
		for i = 0 to 219 do 
		(
			setPixels MissingBitmap1 [i,i*0.75] #(red,red)
			setPixels MissingBitmap1 [219-i,i*0.75] #(red,red)
			setPixels MissingBitmap2 [i,i*0.75] #(red,red)
			setPixels MissingBitmap2 [219-i,i*0.75] #(red,red)
		)	
		
		--if not Krakatoa_Initializing_Hidden_Rollouts do setIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "RolloutVisible" Krakatoa_GUI_Presets.title "true"
		Krakatoa_CustomizeRollouts_Dialog.Refresh_GUI()
		
		Refresh_GUI()
		FranticParticles.LogDebug ("+Presets Rollout OPENED.")			
	)	
	
)--end rollout



--------------------------------------------------------------------------------------------------------------------------------------------------------------------	
--USER NOTES ROLLOUT	
--------------------------------------------------------------------------------------------------------------------------------------------------------------------	
rollout Krakatoa_GUI_Notes "Krakatoa User Notes"  rolledup:true category:120 width:457
(

	button btn_Help_Notes  "Open Online Help..." height:16 width:450 align:#center offset:[0,-5] across:1 tooltip:"Opens the Krakatoa Online Help for the Notes rollout in the default Web Browser. Requires Internet connection."
	
	on Krakatoa_GUI_Notes moved pos do
	(
		setIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "RolloutDialogPositions" Krakatoa_GUI_Notes.title (pos as string)
	)		
	
	label lbl_userNotes01 "Please use this field to enter your notes regarding the current setup"
	label lbl_userNotes02 "and anything others should know when loading and rendering your scene."
	
	edittext edt_userNotes width:440 height:200 align:#center
	
	label lbl_userNotes03 "NOTE that Presets and History files will not consider this field a property"
	label lbl_userNotes04 "but the text will be stored and displayed as part of the general Scene Info."
	
	on edt_userNotes entered txt do 
		try(FranticParticles.SetProperty "UserNotes" txt)catch()
	
	fn updateIcons =
	(
		--btn_Float_Rollout.images = #(Krakatoa_PresetsArrowBitmap,Krakatoa_PresetsArrowBitmap, 32,4,4,4,4)
	)
		
	fn refresh_GUI = 
	(
		/*local theState =  execute (getIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "RolloutVisible" Krakatoa_GUI_Notes.title) 
		if theState == OK do theState = true
		if not theState and Krakatoa_Initializing_Hidden_Rollouts == false do return false 				*/
		
		--if Krakatoa_Initializing_Hidden_Rollouts == false do try(Krakatoa_GUI_Notes.open = FranticParticles.GetBoolProperty "GUI:UserNotesRolloutOpen")catch()		
		try(edt_userNotes.text = FranticParticles.GetProperty "UserNotes")catch()
	)	

	/*
	on Krakatoa_GUI_Notes close do 
	(
		if Krakatoa_GUI_Notes.inDialog and not Krakatoa_Closing_Floater  and not Krakatoa_Initializing_Hidden_Rollouts then
		(
			setIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "RolloutVisible" Krakatoa_GUI_Notes.title "false"
			FranticParticleRenderMXS.floatOrDockRollout Krakatoa_GUI_Notes forceMode:#hide
			Krakatoa_CustomizeRollouts_Dialog.Refresh_GUI()
		)	
	)	
	*/
	on Krakatoa_GUI_Notes open do 
	(
		--updateIcons()
		--if not Krakatoa_Initializing_Hidden_Rollouts do setIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "RolloutVisible" Krakatoa_GUI_Notes.title "true"
		--Krakatoa_CustomizeRollouts_Dialog.Refresh_GUI()
		
		Refresh_GUI()
		FranticParticles.LogDebug ("+Notes Rollout OPENED.")			
	)	
	
	/*
	on Krakatoa_GUI_Notes rolledUp val do 
	(
			FranticParticles.SetProperty "GUI:UserNotesRolloutOpen" val
			if val then 
				FranticParticles.LogDebug ("+User Notes Rollout ROLLED DOWN.")
			else
			FranticParticles.LogDebug ("+User Notes Rollout ROLLED UP.")			
	)	
	*/
)--end rollout





--------------------------------------------------------------------------------------------------------------------------------------------------------------------	
--SAVE FILE HISTORY DIALOG ROLLOUT
--------------------------------------------------------------------------------------------------------------------------------------------------------------------	
rollout Krakatoa_GUI_History_Dialog "Krakatoa Save File History"
(
	local filteredValues = #()
	listbox lbx_history height:20 width:820 align:#center
	edittext edt_filterValue "Filter Value:" fieldwidth:120 pos:[5,280] 
	button btn_ValueFilterOptions ">>" width:20 height:18 pos:[185,280] 
	
	edittext edt_filterPath "Filter Path:" fieldwidth:120 pos:[220,280] 
	button btn_PathFilterOptions ">>" width:20 height:18 pos:[395,280] 
	

	
	checkbox chk_order "Newest On Top" checked:true pos:[500,275] 
	checkbox chk_showPaths "Show Full Path" checked:true pos:[500,290] 
	
	button btn_ok "OK" height:25 width:90 pos:[620,280] 
	button btn_cancel "Cancel" height:25 width:90 pos:[720,280] 
	
	fn createPresetsMenu type:#value =
	(
		case type of
		(
			#value: (
						targetControl = "edt_filterValue"
						presetName = "HistoryDialogFilterValue"
						)
			#path: (
						targetControl = "edt_filterPath"
						presetName = "HistoryDialogFilterPath"
					)
		)
		
		local presetsList = #()
		local theKeys =getIniSetting (Krakatoa_PresetsDirectory + "\\KrakatoaPreferences.ini") presetName 
		sort theKeys 			
		for k in theKeys do
			if findItem presetsList k == 0 do append presetsList k
		local theValue = execute ("Krakatoa_GUI_History_Dialog."+ targetControl +".text")			
			
		local txt = StringStream ""
		format "rcmenu History_FilterValue_RCMenu \n(\n"	to:txt
		if findItem presetsList theValue == 0 and theValue.count > 0 do 
		(
			format "menuItem mnu_AddPreset \"Add [%]\"\n" theValue to:txt
			format "on mnu_AddPreset picked do setIniSetting (Krakatoa_PresetsDirectory + \"//KrakatoaPreferences.ini\") \"%\" \"%\" \"%\" \n" presetName theValue theValue to:txt
			format "separator spr_01\n" 	to:txt
		)	
			
		cnt = 0
		for i in presetsList do
		(
			cnt += 1
			format  "menuItem mnu_preset% \"%\" \n" cnt i to:txt
			format  "on mnu_preset% picked do Krakatoa_GUI_History_Dialog.%.changed (Krakatoa_GUI_History_Dialog.%.text = \"%\")\n" cnt targetControl targetControl i to:txt
		)
		
		if findItem presetsList theValue != 0 do 
		(
			format "separator spr_10\n"  to:txt
			format "menuItem mnu_RemovePreset \"Remove [%]\"\n" theValue to:txt
			format  "on mnu_RemovePreset picked do delIniSetting (Krakatoa_PresetsDirectory + \"//KrakatoaPreferences.ini\") \"%\" \"%\" \n" presetName theValue to:txt
		)				
		
		if cnt > 0 do format  "separator sep_last \n"  to:txt
		format  "menuitem mnu_clearValueFilter \"Clear Value Filter\" \n"  to:txt
		format  "on mnu_clearValueFilter picked do \n(\n"  to:txt
		format  "Krakatoa_GUI_History_Dialog.%.changed (Krakatoa_GUI_History_Dialog.%.text = \"\") \n"  targetControl targetControl to:txt
		format  "Krakatoa_GUI_History_Dialog.updateList())\n"  to:txt
		
		format  ")\n"  to:txt
		Krakatoa_RCMenu_Struct.History_FilterValue_RCMenu = execute (txt as string)
	)
	
	fn updateList =
	(
		filteredValues = #()
		if chk_order.checked then
		(
			startValue = Krakatoa_GUI_SaveParticles.allValues.count 
			endValue = 1
			stepValue = -1
		)
		else
		(
			startValue = 1
			endValue= Krakatoa_GUI_SaveParticles.allValues.count 
			stepValue = 1				
		)
		lbx_history.items = for i = startValue to endValue by stepValue collect 
		(
			if matchPattern Krakatoa_GUI_SaveParticles.allValues[i] pattern:("*"+edt_filterValue.text + "*") AND matchPattern Krakatoa_GUI_SaveParticles.allPaths[i] pattern:("*"+edt_filterPath.text + "*") then
			(
				append filteredValues Krakatoa_GUI_SaveParticles.allValues[i]
				(Krakatoa_GUI_SaveParticles.allValues[i] + (if chk_showPaths.checked then ("   ["+ Krakatoa_GUI_SaveParticles.allPaths[i] + "]") else "") )
			)	
			else
				dontcollect
		)	
	)

	on btn_ValueFilterOptions pressed do 	
	(
		createPresetsMenu type:#value
		popupMenu Krakatoa_RCMenu_Struct.History_FilterValue_RCMenu position:mouse.screenpos
	)	
	on btn_PathFilterOptions pressed do 
	(
		createPresetsMenu type:#path
		popupMenu Krakatoa_RCMenu_Struct.History_FilterValue_RCMenu position:mouse.screenpos
	)			
	on edt_filterValue changed txt do 
	(
		updateList()
		setIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini" ) "HistoryDialog" "LastFilterValuePattern" txt
	)	
	on edt_filterPath changed txt do 
	(
		updateList()
		setIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini" ) "HistoryDialog" "LastFilterPathPattern" txt
	)	
	
	on chk_order changed state do 
	(
		updateList()
		setIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini" ) "HistoryDialog" "NewestOnTop" (state as string)
	)	
	on chk_showPaths changed state do 
	(
		updateList()
		setIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini" ) "HistoryDialog" "ShowFullPath" (state as string)
	)	

	
	on btn_cancel pressed do 
	(
		Krakatoa_GUI_SaveParticles.historyValue = undefined
		destroyDialog Krakatoa_GUI_History_Dialog
	)	
	on btn_ok pressed do 
	(
		if lbx_history.selection > 0 do Krakatoa_GUI_SaveParticles.historyValue = filteredValues[lbx_history.selection]
		destroyDialog Krakatoa_GUI_History_Dialog
	)	
	on lbx_history doubleclicked itm do 
	(
		Krakatoa_GUI_SaveParticles.historyValue = filteredValues[lbx_history.selection]
		destroyDialog Krakatoa_GUI_History_Dialog		
	)
	
	fn updateIcons =
	(
		btn_ValueFilterOptions.images = #(Krakatoa_PresetsArrowBitmap,Krakatoa_PresetsArrowBitmap, 32,1,1,2,2)
		btn_PathFilterOptions.images =#(Krakatoa_PresetsArrowBitmap,Krakatoa_PresetsArrowBitmap, 32,1,1,2,2)
	)	
	
	on Krakatoa_GUI_History_Dialog open do 
	(
		updateIcons()
		
		theVal = execute (getIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini" ) "HistoryDialog" "NewestOnTop")
		if classof theVal != BooleanClass do theVal = true
		chk_order.state = theVal 
		theVal = execute (getIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini" ) "HistoryDialog" "ShowFullPath")
		if classof theVal != BooleanClass do theVal = true
		chk_showPaths.state = theVal 
		edt_filterValue.text = getIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini" ) "HistoryDialog" "LastFilterValuePattern" 
		edt_filterPath.text = getIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini" ) "HistoryDialog" "LastFilterPathPattern" 
		updateList()
	)
)--end rollout

global Krakatoa_GUI_RenderGlobalValues_MapOptions
global Krakatoa_GUI_RenderGlobalValues_MapClipboard = undefined
global Krakatoa_GUI_RenderGlobalValues_MapOptions_Selection = #color
rcmenu Krakatoa_GUI_RenderGlobalValues_MapOptions 
(
	fn isMapValid =
	(
		local theMap = case Krakatoa_GUI_RenderGlobalValues_MapOptions_Selection of
		(
			#color: renderers.current.ColorOverrideTexmap 
			#emission: renderers.current.emissionOverrideTexmap 
			#absorption: renderers.current.absorptionOverrideTexmap 
			#density: renderers.current.densityOverrideTexmap 
		)
		theMap != undefined
	)
	menuitem mnu_ColorHistory "Color History"
	separator sep_10
	menuitem mnu_getMapFromEditor "Get Map From Active Material Editor Slot" enabled:(superclassof (medit.GetCurMtl()) == textureMap )
	separator sep_20
	menuitem mnu_copyMap "Copy Map" enabled:(isMapValid())
	menuitem mnu_pasteMapAsCopy "Paste Map As Copy" enabled:(Krakatoa_GUI_RenderGlobalValues_MapClipboard != undefined)
	menuitem mnu_pasteMapAsInstance "Paste Map As Instance" enabled:(Krakatoa_GUI_RenderGlobalValues_MapClipboard != undefined)
	separator sep_30
	menuitem mnu_putMapToEditor "Put Map To Active Material Editor Slot" enabled:(isMapValid())
	separator sep_40
	menuitem mnu_removeMap "Remove Map..." enabled:(isMapValid())
	
	on mnu_ColorHistory picked do
	(
		case Krakatoa_GUI_RenderGlobalValues_MapOptions_Selection of
		(
			#color: FranticParticleRenderMXSStruct.getValueFromKrakatoaHistory "Krakatoa_GUI_RenderGlobalValues" "clr_colorOverride" "Override Color" Krakatoa_GUI_RenderGlobalValues.clr_colorOverride.color pos:mouse.screenpos
			#emission: FranticParticleRenderMXSStruct.getValueFromKrakatoaHistory "Krakatoa_GUI_RenderGlobalValues" "clr_emissionOverride" "Override Emission Color" Krakatoa_GUI_RenderGlobalValues.clr_emissionOverride.color pos:mouse.screenpos
			#absorption: FranticParticleRenderMXSStruct.getValueFromKrakatoaHistory "Krakatoa_GUI_RenderGlobalValues" "clr_absorptionOverride" "Override Absorption Color" Krakatoa_GUI_RenderGlobalValues.clr_absorptionOverride.color pos:mouse.screenpos
			#density: FranticParticleRenderMXSStruct.getValueFromKrakatoaHistory "Krakatoa_GUI_RenderGlobalValues" "clr_densityOverride" "Override Density Color" Krakatoa_GUI_RenderGlobalValues.clr_densityOverride.color pos:mouse.screenpos
		)		
	)	
	
	on mnu_copyMap picked do
	(
		Krakatoa_GUI_RenderGlobalValues_MapClipboard = case Krakatoa_GUI_RenderGlobalValues_MapOptions_Selection of
		(
			#color: renderers.current.ColorOverrideTexmap 
			#emission: renderers.current.emissionOverrideTexmap 
			#absorption: renderers.current.absorptionOverrideTexmap 
			#density: renderers.current.densityOverrideTexmap 
		)
	)
	
	on mnu_pasteMapAsCopy picked do
	(
		local theMap = copy Krakatoa_GUI_RenderGlobalValues_MapClipboard
		if superclassof theMap == textureMap then
		(
			case Krakatoa_GUI_RenderGlobalValues_MapOptions_Selection of
			(
				#color: renderers.current.ColorOverrideTexmap = theMap
				#emission: renderers.current.emissionOverrideTexmap = theMap
				#absorption: renderers.current.absorptionOverrideTexmap = theMap
				#density: renderers.current.densityOverrideTexmap = theMap
			)
		)	
		Krakatoa_GUI_RenderGlobalValues.refresh_GUI()		
		Krakatoa_GUI_RenderGlobalValues.updateMapSlotNames()
	)		

	on mnu_pasteMapAsInstance picked do
	(
		local theMap = Krakatoa_GUI_RenderGlobalValues_MapClipboard
		if superclassof theMap == textureMap then
		(
			case Krakatoa_GUI_RenderGlobalValues_MapOptions_Selection of
			(
				#color: renderers.current.ColorOverrideTexmap = theMap
				#emission: renderers.current.emissionOverrideTexmap = theMap
				#absorption: renderers.current.absorptionOverrideTexmap = theMap
				#density: renderers.current.densityOverrideTexmap = theMap
			)
		)	
		Krakatoa_GUI_RenderGlobalValues.refresh_GUI()		
		Krakatoa_GUI_RenderGlobalValues.updateMapSlotNames()
	)		
	
	on mnu_getMapFromEditor picked do
	(
		local theMap = medit.GetCurMtl()
		if superclassof theMap == textureMap then
		(
			case Krakatoa_GUI_RenderGlobalValues_MapOptions_Selection of
			(
				#color: renderers.current.ColorOverrideTexmap = theMap
				#emission: renderers.current.emissionOverrideTexmap = theMap
				#absorption: renderers.current.absorptionOverrideTexmap = theMap
				#density: renderers.current.densityOverrideTexmap = theMap
			)
		)	
		Krakatoa_GUI_RenderGlobalValues.refresh_GUI()		
		Krakatoa_GUI_RenderGlobalValues.updateMapSlotNames()
	)	
	
	on mnu_putMapToEditor picked do
	(
		local theMap = case Krakatoa_GUI_RenderGlobalValues_MapOptions_Selection of
		(
			#color: renderers.current.ColorOverrideTexmap 
			#emission: renderers.current.emissionOverrideTexmap 
			#absorption: renderers.current.absorptionOverrideTexmap 
			#density: renderers.current.densityOverrideTexmap 
		)
		if theMap != undefined do 
		(
			medit.PutMtlToMtlEditor theMap (medit.GetActiveMtlSlot())
			MatEditor.Open()
		)
	)		
	
	on mnu_removeMap  picked do
	(
		local theMap = case Krakatoa_GUI_RenderGlobalValues_MapOptions_Selection of
		(
				#color: Krakatoa_GUI_RenderGlobalValues.map_colorOverrideTexmap.text
				#emission: Krakatoa_GUI_RenderGlobalValues.map_emissionOverrideTexmap.text
				#absorption: Krakatoa_GUI_RenderGlobalValues.map_absorptionOverrideTexmap.text 
				#density: Krakatoa_GUI_RenderGlobalValues.map_densityOverrideTexmap.text 
		)			
		if theMap != "None" do
		(
			local q = querybox ("Are you sure you want to REMOVE the Map ["+theMap+"] from the " + Krakatoa_GUI_RenderGlobalValues_MapOptions_Selection as string + " slot?") title:"Remove Override Map?"
			if q do
			(
				case Krakatoa_GUI_RenderGlobalValues_MapOptions_Selection of
				(
					#color: renderers.current.ColorOverrideTexmap = undefined
					#emission: renderers.current.emissionOverrideTexmap = undefined
					#absorption: renderers.current.absorptionOverrideTexmap = undefined
					#density: renderers.current.densityOverrideTexmap = undefined
				)
				Krakatoa_GUI_RenderGlobalValues.refresh_GUI()
				Krakatoa_GUI_RenderGlobalValues.updateMapSlotNames()
			)	
		)	
	)
)

--------------------------------------------------------------------------------------------------------------------------------------------------------------------	
--RENDER GLOBAL VALUES ROLLOUT	
--------------------------------------------------------------------------------------------------------------------------------------------------------------------	
rollout Krakatoa_GUI_RenderGlobalValues "Global Render Values" rolledUp:true  category:7 width:457
(

	button btn_LoadSave_Main "<>" across:4 align:#left width:20 height:16 offset:[-10,-5] tooltip:"Load and Save Presets For This Rollout Only" 
	button btn_Help_Main  "Open Online Help..." width:100 height:16 align:#center offset:[-100,-5] tooltip:"Opens the Krakatoa Online Help for the Global Render Values rollout in the default Web Browser. Requires Internet connection."
	button btn_BackTo_Main "Back To Main Controls..." height:16 width:308 offset:[-3,-5] align:#center tooltip:"Closes the rollout and sets focus on\nthe Main Controls rollout."
	button btn_Float_Rollout ">" height:16 width:20 offset:[10,-5] align:#right tooltip:"Float/Dock the Rollout.\nRight-Click for Menu..." 
	
	on btn_BackTo_Main pressed do
	(
		Krakatoa_GUI_RenderGlobalValues.open = false
		FranticParticleRenderMXS.BackToMainControls()	
	)		
	on btn_BackTo_Main rightclick do
	(
		Krakatoa_GUI_RenderGlobalValues.open = false
		FranticParticleRenderMXS.BackToMainControls()	
	)		

	on btn_LoadSave_Main pressed do 
	(
		Krakatoa_RCMenu_Struct.Float_Rollout_RCMenu_CurrentRollout = Krakatoa_GUI_RenderGlobalValues
		popupMenu Krakatoa_RCMenu_Struct.Load_Save_Rollout_RCMenu pos:mouse.screenpos
	)	
	on btn_LoadSave_Main rightClick do 
	(
		Krakatoa_RCMenu_Struct.Float_Rollout_RCMenu_CurrentRollout = Krakatoa_GUI_RenderGlobalValues
		popupMenu Krakatoa_RCMenu_Struct.Load_Save_Rollout_RCMenu pos:mouse.screenpos
	)	

	on btn_Float_Rollout pressed do
	(
		FranticParticleRenderMXS.FloatRolloutButtonPressed Krakatoa_GUI_RenderGlobalValues
	)		
	on btn_Float_Rollout rightClick do
	(
		Krakatoa_RCMenu_Struct.Float_Rollout_RCMenu_CurrentRollout = Krakatoa_GUI_RenderGlobalValues
		popupMenu Krakatoa_RCMenu_Struct.Float_Rollout_RCMenu pos:mouse.screenpos
	)		
		
	on Krakatoa_GUI_RenderGlobalValues moved pos do
	(
		setIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "RolloutDialogPositions" Krakatoa_GUI_RenderGlobalValues.title (pos as string)
		Krakatoa_CustomizeRollouts_Dialog.updateStripsPositions pos
	)	
	
	group "Background Color Override"
	(
		checkbutton ckb_overrideEnvironmentColor  ">Override Background Color" width:200 height:20 offset:[-5,-4] align:#left across:3 tooltip:"When checked, the 3ds Max Environment Background color will be overridden by the RGBA of the color picker." highlightcolor:KrakatoaSkinColorsStruct.GlobalRenderValues
		colorpicker clr_backgroundColor "Background Color And Alpha:" alpha:true align:#right offset:[129,-4] modal:false fieldwidth:45
		button btn_backgroundColorHistory "H" width:20 height:20 align:#right offset:[8,-4] tooltip:"Click or right-click to open the Background Color Value History dialog."
	)
	
	on btn_backgroundColorHistory pressed do
		FranticParticleRenderMXSStruct.getValueFromKrakatoaHistory "Krakatoa_GUI_RenderGlobalValues" "clr_backgroundColor" "Background Color" clr_backgroundColor.color pos:mouse.screenpos
	on btn_backgroundColorHistory rightclick do
		FranticParticleRenderMXSStruct.getValueFromKrakatoaHistory "Krakatoa_GUI_RenderGlobalValues" "clr_backgroundColor" "Background Color" clr_backgroundColor.color pos:mouse.screenpos
	

	group "Global Shading Channel Overrides" 	
	(
		--Channel specific overrides.
		checkbutton chk_enableColorOverride ">Override Color" align:#left across:5 width:142 height:20 offset:[-5,-3] tooltip:"When checked, the Color (Scatter) channel of all particles will be overriden with the specified color or map." highlightcolor:KrakatoaSkinColorsStruct.GlobalRenderValues
		colorpicker clr_colorOverride "" alpha:false align:#left modal:false fieldwidth:38 offset:[48,-3]
		spinner spn_colorOverrideBlend "" range:[0,100,100] type:#float align:#left fieldwidth:40 offset:[2,-1]
		mapbutton map_colorOverrideTexmap "None" align:#left width:190 height:20 offset:[-32,-3] tooltip:"Click to select a Color Override Map, or right-click to open the Color Override Options menu."
		button btn_colorOverrideOptions ">>" width:20 height:20 align:#right offset:[7,-3] tooltip:"Click or right-click to open the Options menu."

		checkbutton chk_enableEmissionOverride ">Override Emission" align:#left width:110 across:6 height:20 offset:[-5,-4] tooltip:"When checked, the Emission channel of all particles will be overriden with the specified color or map." highlightcolor:KrakatoaSkinColorsStruct.GlobalRenderValues
		checkbutton chk_useEmission ">Use" width:32 height:20 align:#left offset:[35,-4] tooltip:"When checked, the Emission Channel will be allocated and used by the renderer. Duplicate of [>Use Emission] in the Main Controls rollout." highlightcolor:KrakatoaSkinColorsStruct.GlobalRenderValues
		colorpicker clr_emissionOverride "" alpha:false align:#left modal:false fieldwidth:38 offset:[-8,-4]
		spinner spn_emissionOverrideBlend "" range:[0,100,100] type:#float align:#left fieldwidth:40 offset:[-39,-2]
		mapbutton map_emissionOverrideTexmap "None" align:#left width:190 height:20 offset:[-58,-4] tooltip:"Click to select an Emission Override Map, or right-click to open the Emission Override Options menu."
		button btn_emissionOverrideOptions ">>" width:20 height:20 align:#right offset:[11,-4] tooltip:"Click or right-click to open the Options menu."
		
		checkbutton chk_enableAbsorptionOverride ">Override Absorption" align:#left across:7 width:110 height:20 offset:[-5,-4] tooltip:"When checked, the Absorption channel of all particles will be overriden with the specified color or map." highlightcolor:KrakatoaSkinColorsStruct.GlobalRenderValues
		checkbutton chk_useAbsorption ">Use" width:32 height:20 align:#left offset:[45,-4] tooltip:"When checked, the Absorption Channel will be allocated and used by the renderer. Duplicate of [>Use Absorption] in the Main Controls rollout." highlightcolor:KrakatoaSkinColorsStruct.GlobalRenderValues
		colorpicker clr_absorptionOverride "" alpha:false align:#center modal:false fieldwidth:19 offset:[-7,-4]
		colorpicker clr_absorptionOverrideTarget "" alpha:false align:#center modal:false fieldwidth:19 offset:[-49,-4]
		spinner spn_absorptionOverrideBlend "" range:[0,100,100] type:#float align:#left fieldwidth:40 offset:[-70,-2]
		mapbutton map_absorptionOverrideTexmap "None" align:#left width:190 height:20 offset:[-79,-4] tooltip:"Click to select an Absorption Override Map, or right-click to open the Absorption Override Options menu."
		button btn_absorptionOverrideOptions ">>" width:20 height:20 align:#right offset:[10,-4] tooltip:"Click or right-click to open the Options menu."
		
		checkbutton chk_enableDensityOverride ">Override Density" align:#left across:5 width:142 height:20  offset:[-5,-4] tooltip:"When checked, the Density channel of all particles will be overriden with the specified color's and/or map's value." highlightcolor:KrakatoaSkinColorsStruct.GlobalRenderValues
		colorpicker clr_densityOverride "" alpha:false align:#left modal:false fieldwidth:38 offset:[48,-4] color:white
		spinner spn_densityOverrideBlend "" range:[0,100,100] type:#float align:#left fieldwidth:40 offset:[2,-2]
		mapbutton map_densityOverrideTexmap "None" align:#left width:190 height:20 offset:[-32,-4] tooltip:"Click to select a Density Override Map, or right-click to open the Density Override Options menu."
		button btn_densityOverrideOptions ">>" width:20 height:20 align:#right offset:[7,-4] tooltip:"Click or right-click to open the Options menu."
		
		--end of Channel specific overrides.
	)
	


	group "Global Channel Override Sets - Apply Krakatoa Channel Modifiers To All Loaded Particles"
	(
		listbox ddl_GlobalDataHolder offset:[-5,-3] width:218 align:#left  items:#() height:7 across:2 --"Global Channel Override Sets:" 
		listbox ddl_ModifierStackNavigation offset:[5,-3] width:222 align:#right items:#() height:7 --"Modifiers: DblClick=Edit Ctrl+DblClick=Toggle"

		button btn_createNewGlobalData "Create New Global Override Set" height:22 across:7 width:191 align:#left offset:[-5,-5] tooltip:"Creates a new Global Override Set of Channels Modifiers which will be applied to the world state of all particles after their loading." 
		button btn_deleteSet "X" width:25 height:22 align:#center offset:[108,-5] tooltip:"Deletes the selected Global Override Set and its Modifiers after asking politely." 
		button btn_CreateModifier "+" width:25 height:22 align:#center offset:[75,-5] tooltip:"Adds a new default Channel Modifier to the Global Override Set." 
		button btn_LoadModifier "Load..." width:55 height:22 align:#center offset:[55,-5] tooltip:"Loads a Flow from disk and adds a Channel Modifier to the Global Override Set." 
		button btn_ToggleModifier "Toggle" width:55 height:22 align:#right offset:[47,-5] tooltip:"Toggles the selected Channel Modifier On and Off. You can also Ctrl+DoubleClick to Toggle a Modifier." 
		button btn_editModifier "Edit..." width:55 height:22 align:#right offset:[42,-5] tooltip:"Opens the MagmaFlow Editor for the selected Channel Modifier. You can also DoubleClick a Modifier to Edit."
		button btn_DeleteModifier "X" width:25 height:22 align:#right offset:[7,-5] tooltip:"Deletes the selected Channel Modifier From the Global Override Set." 
	)	
	
	group "Post-Processing"
	(
		checkbutton ckb_postDivideByAlpha ">Post-Divide RGB by Alpha" width:440  align:#center offset:[0,-3]  tooltip:"When checked, the RGB values will be divided by the alpha value." highlightcolor:KrakatoaSkinColorsStruct.GlobalRenderValues
	)
	
	on ckb_postDivideByAlpha changed val do 
	(
		FranticParticles.SetProperty "PostDivideByAlpha" (val as string)
		Krakatoa_GUI_Main.update2009VFBControls side:#left
	)		
	on ckb_postDivideByAlpha rightClick do 
		FranticParticleRenderMXS.createDefaultsRCMenu "PostDivideByAlpha" ">Post-Divide by Alpha"
	
	
	on Krakatoa_GUI_RenderGlobalValues rolledUp val do 
	(
		if val == Krakatoa_GUI_RenderGlobalValues.open then
		(
			FranticParticles.SetProperty "GUI:RenderGlobalValuesRolloutOpen" (val as string)
			if val then 
				FranticParticles.LogDebug ("+Render Global Values Rollout ROLLED DOWN.")
			else
				FranticParticles.LogDebug ("+Render Global Values ROLLED UP or CHANGED HEIGHT.")
		)
	)


	fn updateModifierStackData =
	(
		local theNode = getNodeByName (FranticParticles.GetProperty "GlobalDataHolder")
		local theModNames = #()
		local theSelection = ddl_ModifierStackNavigation.selection
		if isValidNode theNode do
		(
			local theMods = for m in theNode.modifiers collect m
			theModNames = for m in theMods collect 
			(
				local theName = m.name 
				if classof m == MagmaModifier do
				(
					theName = ""
					local theNodes = m.MagmaHolder.getNodes()
					for theID in theNodes do
					(
						local theType = m.MagmaHolder.getNodeType theID
						if theType == "Output" do 
						(
							if m.MagmaHolder.GetNodeProperty theID "enabled" then 
							(
								channelDelimiterLeft = "" 
								channelDelimiterRight = "|" 
							)
							else
							(
								channelDelimiterLeft = "("
								channelDelimiterRight = ")|" 
							)
							theName += channelDelimiterLeft+(m.MagmaHolder.GetNodeProperty theID "channelName")+channelDelimiterRight
						)
					)
					if matchPattern theName pattern:"*|" do theName = substring theName 1 (theName.count-1)
				)
				(if not m.enabled then "--" else "") + theName
			)
			append theModNames "==Base Object=="
			local theArray = for m in theNode.modifiers collect m
			append theArray theNode.baseobject
			local theIndex = findItem theArray (modPanel.getCurrentObject())
			if theIndex > 0 do theSelection = theIndex
		)
		ddl_ModifierStackNavigation.items = theModNames
		ddl_ModifierStackNavigation.selection = theSelection
		Krakatoa_GUI_Main.update2009VFBControls side:#left
		try(Krakatoa_updateSchematicFlow())catch()
	)	
	
	fn openEditor theMod =
	(
		try(::MagmaFlowEditor_Functions.OpenMagmaFlowEditor theMod.MagmaHolder)catch()
	)	
	
	fn createDefaultColorFlow magmaNode =
	(
		local node0 = magmaNode.createNode "Output" 
		magmaNode.setNumNodeInputs node0 1 
		magmaNode.setNumNodeOutputs node0 0 
		magmaNode.setNodeProperty node0 "channelName" "Color"
		magmaNode.setNodeProperty node0 "channelType" "float16[3]"
		magmaNode.DeclareExtensionProperty node0 "Position"
		magmaNode.SetNodeProperty node0 "Position" [930,70]
		local node1 = magmaNode.createNode "InputChannel" 
		magmaNode.setNumNodeInputs node1 0 
		magmaNode.setNumNodeOutputs node1 1 
		magmaNode.setNodeProperty node1 "channelName" "Color"
		magmaNode.setNodeProperty node1 "channelType" ""
		magmaNode.DeclareExtensionProperty node1 "Name"
		magmaNode.SetNodeProperty node1 "Name" "InputChannel"
		magmaNode.DeclareExtensionProperty node1 "Position"
		magmaNode.SetNodeProperty node1 "Position" [570,170]
		magmaNode.setNodeInput node0 1 node1 1
	)
	
	
	fn updateMapSlotNames =
	(
		try
		(
			
			map_colorOverrideTexmap.text = if renderers.current.ColorOverrideTexmap != undefined then
				renderers.current.ColorOverrideTexmap.name + " (" + (classof renderers.current.ColorOverrideTexmap) as string + ")"
			else "None"

			map_absorptionOverrideTexmap.text = if renderers.current.AbsorptionOverrideTexmap != undefined then
				renderers.current.AbsorptionOverrideTexmap.name + " (" + (classof renderers.current.AbsorptionOverrideTexmap) as string + ")"
			else "None"		
			
			map_emissionOverrideTexmap.text = if renderers.current.EmissionOverrideTexmap != undefined then 
				renderers.current.EmissionOverrideTexmap.name + " (" + (classof renderers.current.EmissionOverrideTexmap) as string + ")"
			else "None"		
			
			map_densityOverrideTexmap.text = if renderers.current.DensityOverrideTexmap != undefined then 
				renderers.current.DensityOverrideTexmap.name + " (" + (classof renderers.current.DensityOverrideTexmap) as string + ")"
			else "None"		
		
		)catch()
	)
	
	fn updateIcons =
	(
		btn_LoadSave_Main.images = #(Krakatoa_PresetsArrowBitmap,Krakatoa_PresetsArrowBitmap, 32,3,3,3,3)
		btn_Float_Rollout.images = #(Krakatoa_PresetsArrowBitmap,Krakatoa_PresetsArrowBitmap, 32,4,4,4,4)
		
		btn_backgroundColorHistory.images = #(Krakatoa_PresetsArrowBitmap,Krakatoa_PresetsArrowBitmap, 32,10,10,10,10)
		
		btn_colorOverrideOptions.images = #(Krakatoa_PresetsArrowBitmap,Krakatoa_PresetsArrowBitmap, 32,1,1,2,2)
		btn_emissionOverrideOptions.images = #(Krakatoa_PresetsArrowBitmap,Krakatoa_PresetsArrowBitmap, 32,1,1,2,2)
		btn_absorptionOverrideOptions.images = #(Krakatoa_PresetsArrowBitmap,Krakatoa_PresetsArrowBitmap, 32,1,1,2,2)
		btn_densityOverrideOptions.images = #(Krakatoa_PresetsArrowBitmap,Krakatoa_PresetsArrowBitmap, 32,1,1,2,2)
		
		btn_CreateModifier.images = #(Krakatoa_PresetsArrowBitmap,Krakatoa_PresetsArrowBitmap, 32,13,13,13,13)
		btn_DeleteModifier.images = #(Krakatoa_PresetsArrowBitmap,Krakatoa_PresetsArrowBitmap, 32,14,14,14,14)		
		btn_deleteSet.images = #(Krakatoa_PresetsArrowBitmap,Krakatoa_PresetsArrowBitmap, 32,14,14,14,14)		
	)		
	
	fn refresh_GUI =
	(
		/*local theState =  execute (getIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "RolloutVisible" Krakatoa_GUI_RenderGlobalValues.title) 
		if theState == OK do theState = true
		if not theState and Krakatoa_Initializing_Hidden_Rollouts == false do return false 		*/
		
		
		updateIcons()
		
		ddl_GlobalDataHolder.items = join #("--Global Channel Overrides DISABLED--") (for o in objects where classof o.baseobject == KrakatoaGlobalDataHolder or classof o.baseobject == KrakatoaMXGlobalDataHolder collect o.name)
		local theIndex = findItem ddl_GlobalDataHolder.items (FranticParticles.GetProperty "GlobalDataHolder")
		if theIndex == 0 do 
		(
			theIndex = 1
			FranticParticles.setProperty "GlobalDataHolder" ""
		)	
		
		ddl_GlobalDataHolder.selection = theIndex
		
		ckb_overrideEnvironmentColor.state = not (FranticParticles.GetBoolProperty "UseEnvironmentColor")
		clr_backgroundColor.color = (execute (FranticParticles.GetProperty "BackgroundColor"))
		--clr_backgroundColor.enabled = ckb_overrideEnvironmentColor.state
		
		chk_enableColorOverride.state = ( FranticParticles.GetBoolProperty "ColorOverride:Enabled" )
		clr_colorOverride.color = ( execute (FranticParticles.GetProperty "ColorOverride:Color") )
		spn_colorOverrideBlend.value = ( FranticParticles.GetFloatProperty "ColorOverride:BlendAmount" )
		--map_colorOverrideTexmap.map = ( renderers.current.ColorOverrideTexmap )
		
		chk_enableAbsorptionOverride.state = ( FranticParticles.GetBoolProperty "AbsorptionOverride:Enabled" )
		clr_absorptionOverride.color = ( execute (FranticParticles.GetProperty "AbsorptionOverride:Color") )
		clr_absorptionOverrideTarget.color = white - clr_absorptionOverride.color 
		spn_absorptionOverrideBlend.value = ( FranticParticles.GetFloatProperty "AbsorptionOverride:BlendAmount" )
			
		--map_absorptionOverrideTexmap.map = ( renderers.current.AbsorptionOverrideTexmap )

		
		chk_enableEmissionOverride.state = ( FranticParticles.GetBoolProperty "EmissionOverride:Enabled" )
		clr_emissionOverride.color = ( execute (FranticParticles.GetProperty "EmissionOverride:Color") )
		spn_emissionOverrideBlend.value = ( FranticParticles.GetFloatProperty "EmissionOverride:BlendAmount" )
		--map_emissionOverrideTexmap.map = ( renderers.current.EmissionOverrideTexmap )

		
		--chk_enableEmissionOverride.enabled = clr_emissionOverride.enabled = spn_emissionOverrideBlend.enabled = map_emissionOverrideTexmap.enabled = FranticParticles.GetBoolProperty "UseEmissionColor"
		
		chk_enableDensityOverride.state = ( FranticParticles.GetBoolProperty "DensityOverride:Enabled" )
		spn_densityOverrideBlend.value = ( FranticParticles.GetFloatProperty "DensityOverride:BlendAmount" )
		clr_densityOverride.color = white * ( execute (FranticParticles.GetProperty "DensityOverride:Value") )
		
		--map_densityOverrideTexmap.map = ( renderers.current.DensityOverrideTexmap )
		
		chk_useEmission.state = (FranticParticles.GetBoolProperty "UseEmissionColor")		
		chk_useAbsorption.state = (FranticParticles.GetBoolProperty "UseFilterColor")
		
		ckb_postDivideByAlpha.checked = FranticParticles.GetBoolProperty "PostDivideByAlpha"
		

		updateMapSlotNames()
		
		updateModifierStackData()
		try(Krakatoa_updateSchematicFlow())catch()
			
		if Krakatoa_Initializing_Hidden_Rollouts == false do 
			try(Krakatoa_GUI_RenderGlobalValues.open = FranticParticles.GetBoolProperty "GUI:RenderGlobalValuesRolloutOpen")catch()
		
		Krakatoa_GUI_Main.refreshCacheStatus()	
	)
	

	
	fn colorOverrideMenu =
	(
		Krakatoa_GUI_RenderGlobalValues_MapOptions_Selection = #color
		popupMenu Krakatoa_GUI_RenderGlobalValues_MapOptions	pos:mouse.screenPos
	)

	
	on chk_useEmission changed val do 
	(
		FranticParticles.SetProperty "UseEmissionColor" (val as string)
		try(Krakatoa_GUI_Main.refresh_Gui())catch()
		Krakatoa_GUI_Channels.updateMemChannels()
		Krakatoa_GUI_Main.update2009VFBControls side:#left		
	)	
	
	on chk_useEmission rightclick do 
		FranticParticleRenderMXS.createDefaultsRCMenu "UseEmissionColor" ">Use Emission"

	on chk_useAbsorption rightclick do 
		FranticParticleRenderMXS.createDefaultsRCMenu "UseFilterColor" ">Use Absorption"

	on chk_useAbsorption changed val do 
	(
		FranticParticles.SetProperty "UseFilterColor" (val as string)
		try(Krakatoa_GUI_Main.refresh_Gui())catch()
		Krakatoa_GUI_Channels.updateMemChannels()
		Krakatoa_GUI_Main.update2009VFBControls side:#left		
	)		
	
	
	on btn_colorOverrideOptions pressed do colorOverrideMenu()
	on btn_colorOverrideOptions rightClick do colorOverrideMenu()
	on map_colorOverrideTexmap rightclick do colorOverrideMenu()
	
	fn emissionOverrideMenu =
	(
		Krakatoa_GUI_RenderGlobalValues_MapOptions_Selection = #emission
		popupMenu Krakatoa_GUI_RenderGlobalValues_MapOptions	pos:mouse.screenPos		
	)
		
	on btn_emissionOverrideOptions pressed do emissionOverrideMenu()
	on btn_emissionOverrideOptions rightClick do emissionOverrideMenu()
	on map_emissionOverrideTexmap rightClick do emissionOverrideMenu()
	
	fn absorptionOverrideMenu = 
	(
		Krakatoa_GUI_RenderGlobalValues_MapOptions_Selection = #absorption
		popupMenu Krakatoa_GUI_RenderGlobalValues_MapOptions	pos:mouse.screenPos
	)
	on btn_absorptionOverrideOptions pressed do absorptionOverrideMenu()
	on btn_absorptionOverrideOptions rightClick do absorptionOverrideMenu()
	on map_absorptionOverrideTexmap rightClick do absorptionOverrideMenu()
	
	fn densityOverrideMenu =
	(
		Krakatoa_GUI_RenderGlobalValues_MapOptions_Selection = #density
		popupMenu Krakatoa_GUI_RenderGlobalValues_MapOptions	pos:mouse.screenPos
	)
	on btn_densityOverrideOptions pressed do densityOverrideMenu()
	on btn_densityOverrideOptions rightClick do densityOverrideMenu()
	on map_densityOverrideTexmap rightClick do densityOverrideMenu()
	
	on ckb_overrideEnvironmentColor changed state do 
	(
		--clr_backgroundColor.enabled = state		
		FranticParticles.SetProperty "UseEnvironmentColor" ((not state) as string)
		Krakatoa_GUI_Channels.updateMemChannels()
		try(Krakatoa_GUI_ParticleLoaders.updateLoadersList())catch()
		Krakatoa_GUI_Main.update2009VFBControls side:#left
	)
	on ckb_overrideEnvironmentColor rightClick do 
		FranticParticleRenderMXS.createDefaultsRCMenu "UseEnvironmentColor" "Use Environment Color] - Inverse Of [>Override Background Color"

	on clr_backgroundColor changed val do 
	(
		FranticParticles.SetProperty "BackgroundColor" (val as string)
		Krakatoa_GUI_Main.update2009VFBControls side:#left
		Krakatoa_GUI_Main.refreshCacheStatus()
	)
	
	on chk_enableColorOverride changed val do 
	( 
		FranticParticles.SetProperty "ColorOverride:Enabled" (val as string) 
		Krakatoa_GUI_Main.update2009VFBControls side:#left
		try(Krakatoa_GUI_Main.refresh_Gui())catch()
	)
	on chk_enableColorOverride rightClick do 
		FranticParticleRenderMXS.createDefaultsRCMenu "ColorOverride:Enabled" ">Override Color"
	
	on clr_colorOverride changed val do 
	( 
		FranticParticles.SetProperty "ColorOverride:Color" (val as string) 
		Krakatoa_GUI_Main.update2009VFBControls side:#left
		Krakatoa_GUI_Main.refreshCacheStatus()
	)
	on spn_colorOverrideBlend changed val do 
	( 
		FranticParticles.SetProperty "ColorOverride:BlendAmount" (val as string) 
		Krakatoa_GUI_Main.update2009VFBControls side:#left
		Krakatoa_GUI_Main.refreshCacheStatus()
	)
	on map_colorOverrideTexmap picked val do 
	(
		--map_colorOverrideTexmap.caption = if(val != undefined) then (val.name) else ("None")
		try(renderers.current.ColorOverrideTexmap = val)catch()
		refresh_GUI()
		Krakatoa_GUI_Main.update2009VFBControls side:#left
		Krakatoa_GUI_Main.refreshCacheStatus()
	)
	on chk_enableAbsorptionOverride changed val do 
	( 
		FranticParticles.SetProperty "AbsorptionOverride:Enabled" (val as string) 
		Krakatoa_GUI_Main.update2009VFBControls side:#left
		try(Krakatoa_GUI_Main.refresh_Gui())catch()		
		Krakatoa_GUI_Main.refreshCacheStatus()
	)
	on chk_enableAbsorptionOverride rightClick do 
		FranticParticleRenderMXS.createDefaultsRCMenu "AbsorptionOverride:Enabled" ">Override Absorption"

	on clr_absorptionOverride changed val do 
	(
		FranticParticles.SetProperty "AbsorptionOverride:Color" (val as string) 
		clr_absorptionOverrideTarget.color = white - val
		Krakatoa_GUI_Main.update2009VFBControls side:#left
		Krakatoa_GUI_Main.refreshCacheStatus()
	)
	on clr_absorptionOverrideTarget changed val do 
	(
		clr_absorptionOverride.color = white - val
		FranticParticles.SetProperty "AbsorptionOverride:Color" (clr_absorptionOverride.color as string) 
		Krakatoa_GUI_Main.update2009VFBControls side:#left
		Krakatoa_GUI_Main.refreshCacheStatus()
	)	
	on spn_absorptionOverrideBlend changed val do 
	( 
		FranticParticles.SetProperty "AbsorptionOverride:BlendAmount" (val as string) 
		Krakatoa_GUI_Main.update2009VFBControls side:#left
		Krakatoa_GUI_Main.refreshCacheStatus()
	)
	on map_absorptionOverrideTexmap picked val do 
	(
		--map_absorptionOverrideTexmap.caption = if(val != undefined) then (val.name) else ("None")
		try(renderers.current.AbsorptionOverrideTexmap = val)catch()
		refresh_GUI()
		Krakatoa_GUI_Main.update2009VFBControls side:#left
		Krakatoa_GUI_Main.refreshCacheStatus()
	)
	on chk_enableEmissionOverride changed val do 
	( 
		FranticParticles.SetProperty "EmissionOverride:Enabled" (val as string) 
		Krakatoa_GUI_Main.update2009VFBControls side:#left
		try(Krakatoa_GUI_Main.refresh_Gui())catch()
		Krakatoa_GUI_Main.refreshCacheStatus()
	)
	on chk_enableEmissionOverride rightClick do 
		FranticParticleRenderMXS.createDefaultsRCMenu "EmissionOverride:Enabled" ">Override Emission"

	on clr_emissionOverride changed val do 
	( 
		FranticParticles.SetProperty "EmissionOverride:Color" (val as string) 
		Krakatoa_GUI_Main.update2009VFBControls side:#left
		Krakatoa_GUI_Main.refreshCacheStatus()
	)
	on spn_emissionOverrideBlend changed val do 
	(
		FranticParticles.SetProperty "EmissionOverride:BlendAmount" (val as string) 
		Krakatoa_GUI_Main.update2009VFBControls side:#left
		Krakatoa_GUI_Main.refreshCacheStatus()
	)
		
	on map_emissionOverrideTexmap picked val do 
	(
		--map_emissionOverrideTexmap.caption = if(val != undefined) then (val.name) else ("None")
		try(renderers.current.EmissionOverrideTexmap = val)catch()
		refresh_GUI()
		Krakatoa_GUI_Main.update2009VFBControls side:#left
		Krakatoa_GUI_Main.refreshCacheStatus()
	)
	on chk_enableDensityOverride changed val do 
	( 
		FranticParticles.SetProperty "DensityOverride:Enabled" (val as string) 
		Krakatoa_GUI_Main.update2009VFBControls side:#left
		try(Krakatoa_GUI_Main.refresh_Gui())catch()
		Krakatoa_GUI_Main.refreshCacheStatus()
	)
	on chk_enableDensityOverride rightClick do 
		FranticParticleRenderMXS.createDefaultsRCMenu "DensityOverride:Enabled" ">Override Density"

	on spn_densityOverrideBlend changed val do 
	( 
		FranticParticles.SetProperty "DensityOverride:BlendAmount" (val as string) 
		Krakatoa_GUI_Main.update2009VFBControls side:#left
		Krakatoa_GUI_Main.refreshCacheStatus()
	)
	on clr_densityOverride changed val do 
	( 
		FranticParticles.SetProperty "DensityOverride:Value" ((val.value/255) as string)
		Krakatoa_GUI_Main.update2009VFBControls side:#left
		Krakatoa_GUI_Main.refreshCacheStatus()
	)	
	on map_densityOverrideTexmap picked val do 
	(
		--map_densityOverrideTexmap.caption = if(val != undefined) then (val.name) else ("None")
		try(renderers.current.DensityOverrideTexmap = val)catch()
		refresh_GUI()
		Krakatoa_GUI_Main.update2009VFBControls side:#left
		Krakatoa_GUI_Main.refreshCacheStatus()
	)
	
	fn createNewOverrideSet =
	(
		--if (querybox "Create a New Global Channel Override Set?" title:"Krakatoa") then
		with undo "New Krakatoa Override Set" on
		(
			local newNode = KrakatoaMXGlobalDataHolder()
			newNode.name = uniquename "KCMOverrideSet"
			FranticParticles.SetProperty "GlobalDataHolder" newNode.name
			newNode.isHidden = newNode.isFrozen = true
			local theMod = magmaModifier name:"KCM_Color"
			addModifier newNode theMod
			createDefaultColorFlow theMod.magmaHolder
		)
		--print  (FranticParticles.GetProperty "GlobalDataHolder")
		refresh_GUI()
		--print  (FranticParticles.GetProperty "GlobalDataHolder")
		
		max modify mode
		modPanel.setCurrentObject theMod node:newNode ui:true
		updateModifierStackData()
		Krakatoa_GUI_Main.update2009VFBControls side:#left
		Krakatoa_GUI_Main.refreshCacheStatus()
		openEditor theMod 	
	)
	
	on btn_createNewGlobalData pressed do
	(
		createNewOverrideSet ()
		Krakatoa_GUI_Main.refreshCacheStatus()
	)	
	
	on btn_deleteSet pressed do
	(
		local theNode = (getNodeByName (FranticParticles.GetProperty "GlobalDataHolder")) 
		if isValidNode theNode do
		(
			local q = querybox ("Are you sure you want to DELETE the Global Override Set ["+ (FranticParticles.GetProperty "GlobalDataHolder")+"]?") title:"Delete Global Override Set?"
			if q do
			(
				with undo "Delete Global Override Set" on delete theNode
				refresh_GUI()
			)
		)
		Krakatoa_GUI_Main.refreshCacheStatus()
	)	
	
	on btn_CreateModifier pressed do
	(
		local theNode = (getNodeByName (FranticParticles.GetProperty "GlobalDataHolder")) 
		if not isValidNode theNode do
		(
			with undo "New Krakatoa Override Set" on
			(
				local theNode = KrakatoaMXGlobalDataHolder()
				theNode.name = uniquename "KCMOverrideSet"
				theNode.isHidden = theNode.isFrozen = true
			)
			FranticParticles.SetProperty "GlobalDataHolder" theNode.name
			updateModifierStackData()
			refresh_GUI()
		)
		if isValidNode theNode do
		(		
			max modify mode
			with undo "New Krakatoa Override Modifier" on
			(
				local theMod = MagmaModifier name:"KCM_Color"
				addModifier theNode theMod
				createDefaultColorFlow theMod.magmaHolder
			)	
			modPanel.setCurrentObject theMod node:theNode ui:true
			updateModifierStackData()
			openEditor theMod 
		)	
		Krakatoa_GUI_Main.update2009VFBControls side:#left
		Krakatoa_GUI_Main.refreshCacheStatus()
	)
	
	on btn_LoadModifier pressed do
	(
		local theNode = (getNodeByName (FranticParticles.GetProperty "GlobalDataHolder")) 
		if not isValidNode theNode do
		(
			with undo "New Krakatoa Override Set" on
			(
				local theNode = KrakatoaMXGlobalDataHolder()
				theNode.name = uniquename "KCMOverrideSet"
				theNode.isHidden = theNode.isFrozen = true
			)
			FranticParticles.SetProperty "GlobalDataHolder" theNode.name
			refresh_GUI()
			updateModifierStackData()
			Krakatoa_GUI_Main.update2009VFBControls side:#left
		)
		if isValidNode theNode do
		(		
			local theFileName = getOpenFileName caption:"Load Krakatoa MagmaFlow File" filename:(Krakatoa_PresetsDirectory+ "\\MagmaFlows\\Flow.kmf") types:"Krakatoa MagmaFlow 1.x or 2.x Files (*.KMF,*.MagmaScript)|*.KMF;*.MagmaScript|Krakatoa MagmaFlow 1.x File (*.KMF)|*.KMF|Krakatoa MagmaFlow 2 File (*.MagmaScript)|*.MagmaScript|All Files (*.*)|*.*"
			if theFileName != undefined do
			(
				max modify mode
				with undo "Load Krakatoa Override Modifier" on
				(
					local theMod = MagmaModifier name:"Magma"
					addModifier theNode theMod
				)	
				modPanel.setCurrentObject theMod node:theNode ui:true
				local theResult = #yes
				--try (
					--createUndoRecord ("Before Opening Flow File [" + getFileNameFile theFileName + "]")
				if matchPattern (getFileNameType theFileName) pattern:"*.KMF" do
				(
					MagmaFlowEditor_Functions.convertKMF  theMod.magmaHolder theFile:theFileName
				)
				if matchPattern (getFileNameType theFileName) pattern:"*.MagmaScript" do
				(
					::magmaNode = theMod.magmaHolder
					fileIn theFileName
				)
				openEditor theMod 				
				updateModifierStackData()
			)	
			/*	
					local theMapPath = (getFileNamePath theFileName + getFileNameFile theFileName  + ".mat") 
					local theMatLib = #()
					if doesFileExist theMapPath do
					(
						local theMatLib = loadTempMaterialLibrary theMapPath
						if KrakatoaChannelNodeEditor_CurrentModifier.TextureMapSources.count >= theMatLib.count then
						(
							theResult = yesnocancelbox ("The current Krakatoa Channels Modifier already contains "+KrakatoaChannelNodeEditor_CurrentModifier.TextureMapSources.count as string + " Texture Maps.\nThe incoming MagmaFlow contains "+theMatLib.count as string+" texture maps.\n\nClick [Yes] to REPLACE the existing maps with the incoming ones.\nClick [No] to KEEP AND USE the existing Texture Maps and APPEND the incoming ones.\nClick [Cancel] to CANCEL LOADING of MagmaFlow and TextureMaps.") title:"Open MagmaFlow: Replace Texture Maps?"
						)
					)
					case theResult of 
					(
						#yes: KrakatoaChannelNodeEditor_CurrentModifier.TextureMapSources = for m in theMatLib collect m
						#no:	KrakatoaChannelNodeEditor_CurrentModifier.TextureMapSources = join (for m in KrakatoaChannelNodeEditor_CurrentModifier.TextureMapSources collect m) (for m in theMatLib collect m)
					)	
					if theResult != #cancel do
					(
						fileIn theFileName
						KrakatoaChannelEditor_BaseNodeTreeData = deepCopy KrakatoaChannelEditor_NodeTreeData
						KrakatoaChannelsEditor_Functions.fixFlowIDsAfterLoading KrakatoaChannelEditor_BaseNodeTreeData
						KrakatoaChannelsEditor_Functions.buildDisplayTree()	
						KrakatoaChannelNodeEditor_Rollout.createNodeTree init:true
						KrakatoaChannelNodeEditor_Rollout.createUndoRecord ("Open Flow File [" + getFileNameFile theFileName + "]")
						KrakatoaChannelNodeEditor_Rollout.resetPanFactor()
						KrakatoaChannelNodeEditor_Rollout.resetZoomFactor()
						--KrakatoaChannelNodeEditor_Rollout.showGrid SnapToGrid					
						KrakatoaChannelNodeEditor_Rollout.hc.redrawView							
					)
				--)catch()
				KrakatoaChannelsEditor_Functions.exposeControlsToModifier KrakatoaChannelNodeEditor_CurrentModifier
				updateModifierStackData()
			)		
			*/
		)	
		Krakatoa_GUI_Main.update2009VFBControls side:#left
		Krakatoa_GUI_Main.refreshCacheStatus()
	)
	
	
	on btn_DeleteModifier pressed do
	(
		local theNode = (getNodeByName (FranticParticles.GetProperty "GlobalDataHolder")) 
		if isValidNode theNode and ddl_ModifierStackNavigation.selection < ddl_ModifierStackNavigation.items.count do
		(		
			with undo "Delete Krakatoa Override Modifier" on
			(
				deleteModifier theNode theNode.modifiers[ddl_ModifierStackNavigation.selection]
			)	
			updateModifierStackData()
		)			
		Krakatoa_GUI_Main.update2009VFBControls side:#left
		Krakatoa_GUI_Main.refreshCacheStatus()
	)
	on btn_ToggleModifier pressed do
	(
		local theNode = (getNodeByName (FranticParticles.GetProperty "GlobalDataHolder")) 
		if isValidNode theNode and ddl_ModifierStackNavigation.selection < ddl_ModifierStackNavigation.items.count do
		(		
			try(theNode.modifiers[ddl_ModifierStackNavigation.selection].enabled = not theNode.modifiers[ddl_ModifierStackNavigation.selection].enabled)catch()
			updateModifierStackData()
		)		
		Krakatoa_GUI_Main.update2009VFBControls side:#left	
		Krakatoa_GUI_Main.refreshCacheStatus()		
	)	
	on btn_EditModifier pressed do
	(
		local theNode = (getNodeByName (FranticParticles.GetProperty "GlobalDataHolder")) 
		if isValidNode theNode and ddl_ModifierStackNavigation.selection < ddl_ModifierStackNavigation.items.count do
		(		
			openEditor theNode.modifiers[ddl_ModifierStackNavigation.selection]
		)		
	)		

	
	on ddl_GlobalDataHolder selected itm do
	(
		if itm == 1 then 
		(
			FranticParticles.SetProperty "GlobalDataHolder" "" 
			max select none
		)
		else 
		(
			FranticParticles.SetProperty "GlobalDataHolder" ddl_GlobalDataHolder.selected
			local theNode = getNodeByName ddl_GlobalDataHolder.selected
			if isValidNode theNode then
			(
				max modify mode
				select theNode
				--modPanel.setCurrentObject theNode.baseobject
				setFocus ddl_GlobalDataHolder
			)	
			else			
			(
				refresh_GUI()
			)	
		)	
		updateModifierStackData()
		Krakatoa_GUI_Main.update2009VFBControls side:#left	
		Krakatoa_GUI_Main.refreshCacheStatus()		
	)
	
	on ddl_ModifierStackNavigation selected itm do
	(
		local theNode = (getNodeByName (FranticParticles.GetProperty "GlobalDataHolder")) 
		if isValidNode theNode do
		(
			max modify mode
			if ddl_ModifierStackNavigation.items.count == itm then
				modPanel.setCurrentObject theNode node:theNode ui:true
			else
				try(modPanel.setCurrentObject theNode.modifiers[itm] node:theNode ui:true)catch()
		)
	)
	
	on ddl_ModifierStackNavigation doubleclicked itm do
	(
		local theNode = (getNodeByName (FranticParticles.GetProperty "GlobalDataHolder")) 
		if isValidNode theNode do
		(
			if keyboard.controlPressed then
			(
				if itm < ddl_ModifierStackNavigation.items.count do
				(
					try(theNode.modifiers[itm].enabled = not theNode.modifiers[itm].enabled)catch()
					updateModifierStackData()
					ddl_ModifierStackNavigation.selection = itm
				)
			)
			else
			(
				max modify mode
				if itm < ddl_ModifierStackNavigation.items.count do
				(
					try(modPanel.setCurrentObject theNode.modifiers[itm] node:theNode ui:true)catch()
					openEditor theNode.modifiers[itm]	
				)	
			)	
		)
	)
	
	on Krakatoa_GUI_RenderGlobalValues close do 
	(
		if Krakatoa_GUI_RenderGlobalValues.inDialog and not Krakatoa_Closing_Floater and not Krakatoa_Initializing_Hidden_Rollouts then
		(
			setIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "RolloutVisible" Krakatoa_GUI_RenderGlobalValues.title "false"
			FranticParticleRenderMXS.floatOrDockRollout Krakatoa_GUI_RenderGlobalValues forceMode:#hide
			Krakatoa_CustomizeRollouts_Dialog.Refresh_GUI()
		)			
		callbacks.removeScripts id:#KrakatoaGlobalOverridesModPanel
	)

	on Krakatoa_GUI_RenderGlobalValues open do 
	(
		--if not Krakatoa_Initializing_Hidden_Rollouts do setIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "RolloutVisible" Krakatoa_GUI_RenderGlobalValues.title "true"
		Krakatoa_CustomizeRollouts_Dialog.Refresh_GUI()
		
		refresh_GUI()
		callbacks.removeScripts id:#KrakatoaGlobalOverridesModPanel
		
		if not Krakatoa_Initializing_Hidden_Rollouts do
		(
			callbacks.addScript #sceneUndo "try(Krakatoa_GUI_RenderGlobalValues.refresh_GUI())catch()" id:#KrakatoaGlobalOverridesModPanel
			callbacks.addScript #nodePostDelete "try(Krakatoa_GUI_RenderGlobalValues.refresh_GUI())catch()" id:#KrakatoaGlobalOverridesModPanel
			callbacks.addScript #modPanelObjPostChange "try(Krakatoa_GUI_RenderGlobalValues.updateModifierStackData())catch()" id:#KrakatoaGlobalOverridesModPanel
		)
	)
)--end rollout


--------------------------------------------------------------------------------------------------------------------------------------------------------------------	
--MAIN CONTROLS ROLLOUT	
--------------------------------------------------------------------------------------------------------------------------------------------------------------------	
rollout Krakatoa_GUI_Main "Main Controls" rolledUp:false category:10 width:457
(
	local theCachedChannelsArray = #()
	
	button btn_LoadSave_Main "<>" across:8 align:#left width:20 height:16 offset:[-10,-5] tooltip:"Load and Save Presets For This Rollout Only" 
	button btn_Help_Main "Open Online Help..." height:16 width:100 offset:[-43,-5] align:#left tooltip:"Opens the Krakatoa Online Help for the Main Controls Rollout in the default Web Browser. Requires Internet connection."

	button btn_GoTo_01 "Manage" height:16 width:60 offset:[5,-5] align:#left tooltip:"Click or Right-Click to jump to the\nManage GUI Rollout."
	button btn_GoTo_02 "History" height:16 width:60 offset:[17,-5] align:#center tooltip:"Click or Right-Click to jump to the\nPresets and History Rollout."
	button btn_GoTo_03 "Globals" height:16 width:60 offset:[24,-5] align:#center tooltip:"Click or Right-Click to jump to the\nRender Globals Rollout."
	button btn_GoTo_04 "Memory" height:16 width:60 offset:[35,-5] align:#right tooltip:"Click or Right-Click to jump to the\nMemory Channels Rollout."
	button btn_GoTo_05 "Partitions" height:16 width:65 offset:[47,-5] align:#right tooltip:"Click or Right-Click to jump to the\nPartitioning Rollout."
	
	button btn_Float_Rollout ">" height:16 width:20 offset:[15,-5] align:#right tooltip:"Float/Dock the Rollout.\nRight-Click for Menu..." 

		on btn_LoadSave_Main pressed do 
	(
		Krakatoa_RCMenu_Struct.Float_Rollout_RCMenu_CurrentRollout = Krakatoa_GUI_Main
		popupMenu Krakatoa_RCMenu_Struct.Load_Save_Rollout_RCMenu pos:mouse.screenpos
	)	
	on btn_LoadSave_Main rightClick do 
	(
		Krakatoa_RCMenu_Struct.Float_Rollout_RCMenu_CurrentRollout = Krakatoa_GUI_Main
		popupMenu Krakatoa_RCMenu_Struct.Load_Save_Rollout_RCMenu pos:mouse.screenpos
	)	

	on btn_Float_Rollout pressed do
	(
		FranticParticleRenderMXS.FloatRolloutButtonPressed Krakatoa_GUI_Main
	)		
	on btn_Float_Rollout rightClick do
	(
		Krakatoa_RCMenu_Struct.Float_Rollout_RCMenu_CurrentRollout = Krakatoa_GUI_Main
		popupMenu Krakatoa_RCMenu_Struct.Float_Rollout_RCMenu pos:mouse.screenpos
	)		
		
	on Krakatoa_GUI_Main moved pos do
	(
		setIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "RolloutDialogPositions" Krakatoa_GUI_Main.title (pos as string)
		Krakatoa_CustomizeRollouts_Dialog.updateStripsPositions pos
	)
	
	label lbl_lightingandshading height:1 offset:[0,-10] visible:false
	group "Lighting and Shading"
	(
		bitmap bmp_RenderingMethod width:10 height:21 across:5 align:#left offset:[-5,-4] 
		dropdownlist ddl_RenderingMethod items:#("Particle Rendering","Voxel Rendering") width:130 align:#left offset:[-80,-4] tooltip:"Render Mode - \nParticle Rendering uses pixel-sized points, \nVoxel Rendering registers particles on a grid and shades it."
		spinner spn_VoxelSize "Voxel Size:" range:[0,10000000,1] align:#left fieldwidth:37 type:#float offset:[4,-1]
		button btn_VoxelSizePreset ">>" width:20 height:18 align:#left offset:[19,-2] tooltip:"Voxel Size Presets..."	
		checkbutton ckb_AdditiveMode ">Force Additive Mode" width:138  height:18 align:#right offset:[7,-2] highlightcolor:KrakatoaSkinColorsStruct.Main tooltip:"When checked, forces Additive Rendering by internally copying the Color channel to the Emission channel, while setting Color and Absorption to Black." 

		bitmap bmp_shadingMode width:10 height:21 across:5 align:#left offset:[-5,-8] 
		dropdownlist ddl_shadingMode width:130 align:#left offset:[-80,-8] items:#("Isotropic","Phong Surface","Henyey-Greenstein","Schlick","Kajiya-Kay Hair","Marschner Hair") tooltip:"Light Scatter Phase Function -\nIsotropic scatters uniformly in all directions;\nPhong Surface scatters based on particle Normals;\nHenyey-Greenstein and Schlick scatter based on the angle between light and camera;\nKajiya-Kay and Marschner scatter based on hair Tangents."	
		
		spinner spn_VoxelFilterRadius "Filter Radius:" range:[1,100,1] type:#integer fieldwidth:37 offset:[18,-6]
		button btn_VoxelFilterRadiusPreset ">>" width:20 height:18 align:#left offset:[19,-7] tooltip:"Voxel Filter Radius Presets..." 
		checkbutton ckb_useFilterColor ">Use Absorption" width:138  height:18 align:#right offset:[7,-7] tooltip:"When checked, the Absorption Channel R,G and B components of light will be attenuated separately based on the Absorption Channel value." highlightcolor:KrakatoaSkinColorsStruct.Main

		label lbl_void10 offset:[0,-25] visible:false
	)
	
	label lbl_void20 offset:[0,-22] visible:false
	
	group "Lighting Pass Filtering and Density | Final Pass Filtering, Density"
	(
		checkbutton ckb_IgnoreSceneLights ">Ignore Scene Lights" width:140  height:18 align:#left offset:[-5,-4] highlightcolor:KrakatoaSkinColorsStruct.Main tooltip:"When checked, scene lights will be assumed OFF. Use Emission Channel to make particles visible."
		
		dropdownlist ddl_attenuationLookupFilter items:#("Shadow Filter:Nearest","Shadow Filter:Bilinear","Shadow Filter:Bicubic") width:143 align:#left offset:[-7,-4] across:6 tooltip:"Self-Shadow Filter used in Particle Mode when drawing the Attenuation Map for a light source. Default is Bicubic."
		spinner spn_shadowBilinearFilter fieldwidth:48 offset:[52,-2] type:#Integer range:[1,64,1] tooltip:"When the Filter is set to Bilinear, defines the Self-Shadow Filter's Sample Size.\n\nHigher values produce smoother results with less detail."
		button btn_shadowBilinearFilterPreset ">>" width:20 height:19 offset:[27,-3] tooltip:"Set the Bilinear Filter's Size to a Preset Value, \nor Add/Remove current value to/from the Presets."
		
		dropdownlist ddl_drawPointFilter items:#("Draw Point Filter:Nearest","Draw Point Filter:Bilinear","Draw Point Filter:Bicubic") width:143 align:#left offset:[2,-2] tooltip:"Draw Point Filter used in Particle Mode when drawing the particles to the Output Image. Default is Biliear, Bicubic looks smoother at cost of speed."
		spinner spn_drawBilinearFilter fieldwidth:48 offset:[61,0] type:#Integer range:[1,64,1] tooltip:"When the Filter is set to Bilinear, defines the Draw Point Filter's Sample Size.\n\nHigher values produce blurrier results with less detail."
		button btn_drawBilinearFilterPreset ">>" width:20 height:19 align:#right offset:[11,-1] tooltip:"Set the Bilinear Filter's Size to a Preset Value, \nor Add/Remove current value to/from the Presets."
		
		spinner spn_LightingDensityPerParticle "Lighting Density:" range:[0,10000000,1]  across:2 fieldwidth:48 type:#float offset:[-22,-3]
		spinner spn_densityPerParticle "Final Pass Density:" range:[0,10000000,1] align:#right fieldwidth:48 type:#float offset:[-14,-3]

		spinner spn_LightingDensityExponent  "Exponent (10^x):" range:[-30,30,0] across:2 fieldwidth:48 type:#integer offset:[-22,-3]
		spinner spn_densityExponent  "Density Exponent (10^x):" range:[-30,30,0] align:#right fieldwidth:48 type:#integer offset:[-14,-3]

		checkbutton ckb_linkLightingAndRenderingDensity ">Use" width:45 height:27 align:#left offset:[-5,-40] tooltip:"When checked, separate Lighting Pass Density controls will become available. \n\nWhen unchecked, the Render Pass Density settings will be used by the Lighting Pass." highlightcolor:KrakatoaSkinColorsStruct.Main
		checkbutton ckb_relativeLightingDensity ">Rel." width:45 height:27 align:#left offset:[-5,-4] tooltip:"When checked, the Lighting Pass Density can be set as a fraction of the Render Pass Density.\n\nWhen unchecked, the Lighting Pass Density can be set as an absolute value." highlightcolor:KrakatoaSkinColorsStruct.Main

		button btn_lightingDensityPreset ">>" width:20 height:34 align:#left across:2 offset:[194,-59] tooltip:"Set Lighting Pass Density to a Preset Value, \nor Add/Remove current value to/from the Presets." 
		button btn_finalDensityPreset ">>" width:20 height:34 align:#right offset:[7,-59] tooltip:"Set Final Pass Density to a Preset Value, \nor Add/Remove current value to/from the Presets." 
		
		edittext edt_LightingDensityFullValue "Resulting Value:" align:#left across:2 fieldwidth:77 offset:[55,-3] readOnly:true --range:[0,10000000,100.0] type:#float 
		edittext edt_FinalDensityFullValue "Resulting Value:" align:#right fieldwidth:77 offset:[6,-3] readOnly:true --range:[0,10000000,100.0] type:#float 
	)
	
	label lbl_placeHolderDensity offset:[0,-22] visible:false
	group "Emission And Reflections"
	(
		checkbutton ckb_useEmissionColor ">Use Emission" width:220  height:18 align:#left offset:[-5,-5] across:2 tooltip:"When checked, the Emission channel will be allocated and taken into account to make particles self-illuminated." highlightcolor:KrakatoaSkinColorsStruct.Main
		spinner spn_emissionStrength "Emission Strength:" range:[0,10000000,1] align:#right fieldwidth:48 type:#float offset:[-14,-5]
		
		checkbutton ckb_useEnvironmentReflections ">Use Environment Reflections" align:#left  height:18 width:220 offset:[-5,-4] across:2 highlightcolor:KrakatoaSkinColorsStruct.Main tooltip:"When checked, particles with valid Normals will look up Texels from the 3ds Max Environment Map and use their Color as Additional Lighting." 
		spinner spn_emissionStrengthExponent "Exponent (10^x):" range:[-30,30,0] align:#right fieldwidth:48 type:#integer offset:[-14,-5]

		checkbutton ckb_allocateReflectionStrengthChannel ">Allocate ReflectionStrength" across:3 offset:[1,-4] height:18 width:150 tooltip:"When checked, a per-particle ReflectionStrength channel will be allocated in memory if either >Use Emission or >Use Environment Reflections is checked.\n\nThe channel will be populated with the per-particle ReflectionStrength channel values if available, or with 1.0 if not available.\n\nWhen unchecked, all particles will use the UI value to the right of this checkbutton." highlightcolor:KrakatoaSkinColorsStruct.Main
		spinner spn_reflectionStrength range:[0,100,1] align:#left fieldwidth:38 type:#float offset:[2,-3]  scale:0.01 tooltip:"When >Allocate ReflectionStrength is unchecked, this value will define the Reflection Strength of every particle.\n\nWhen >Allocate ReflectionStrength is checked, this value will be used to SCALE the ReflectionStrength channel of particles. If a particle does not have such channel, a default of 1.0 will be assumed and SCALED by this value."
		edittext edt_emissionStrengthResultingValue "Resulting Value:" align:#right fieldwidth:77 offset:[6,-5] readOnly:true --range:[0,10000000,100.0] type:#float 
		
		button btn_reflectionStrengthPreset ">>" width:20 height:18 align:#right offset:[-216,-23] tooltip:"Set Reflection Strength to a Preset Value, \nor Add/Remove current value to/from the Presets." 
		button btn_emissionStrengthPreset ">>" width:20 height:34 align:#right offset:[6,-61] tooltip:"Set Emission Strength to a Preset Value, \nor Add/Remove current value to/from the Presets." 

		checkbutton ckb_useEmissionStrength ">Use" width:45 height:28 align:#center offset:[25,-39] tooltip:"When unchecked, the Final Pass Density will be used for Emission Strength.\n\nWhen checked, separate Emission Strength controls will become available.\n\nEnabled when >Use Emission is checked." highlightcolor:KrakatoaSkinColorsStruct.Main
		checkbutton ckb_relativeEmissionStrength ">Rel." width:45 height:28 align:#center offset:[25,-4] tooltip:"When checked, the Emission Strength can be set as a fraction of the Render Pass Density.\n\nWhen unchecked, the Emission Strength can be set as an absolute value." highlightcolor:KrakatoaSkinColorsStruct.Main
	)

		
	fn update2009VFBControls side: = 
	(	
		case side of
		(
			#left: try(Krakatoa_VFB_Left_Rollout.refresh_GUI())catch() --update VFB Overlay in Max 2009+
			#right: 	try(Krakatoa_VFB_Right_Rollout.refresh_GUI())catch() --update VFB Overlay in Max 2009+
			default: (
				try(Krakatoa_VFB_Left_Rollout.refresh_GUI())catch()
				try(Krakatoa_VFB_Right_Rollout.refresh_GUI())catch()
			)
		)	
		try(Krakatoa_VFB_Overlay_Rollout.refresh_GUI())catch()
		updateToolbarButtons()
	)
	

	fn convertSourcesToString =
	(
		local theStringArray = #()
		if FranticParticles.GetBoolProperty "RenderParticleFlowGeometry" do append theStringArray "PF Geometry"
		if FranticParticles.GetBoolProperty "RenderParticleFlowPhantom" do append theStringArray "PF Phantom"
		if FranticParticles.GetBoolProperty "RenderParticleFlowBBox" do append theStringArray "PF Box"
		if FranticParticles.GetBoolProperty "RenderMaxParticles" do append theStringArray "Legacy"
			
		if FranticParticles.GetBoolProperty "RenderThinkingParticles" do append theStringArray "TP"
		if FranticParticles.GetBoolProperty "RenderFumeFX" do append theStringArray "FumeFX"
		if FranticParticles.GetBoolProperty "RenderPhoenixFD" do append theStringArray "Phoenix"
		if FranticParticles.GetBoolProperty "RenderGeometryVertices" do append theStringArray "Vertices"
			
		if FranticParticles.GetBoolProperty "RenderKrakatoaLoaders" do append theStringArray "PRT"
		if FranticParticles.GetBoolProperty "RenderGeometryVolumes" do append theStringArray "Volumes"
		if FranticParticles.GetBoolProperty "RenderPRTSurface" do append theStringArray "Surfaces"
		if FranticParticles.GetBoolProperty "RenderPRTHair" do append theStringArray "Hair"
			
		if FranticParticles.GetBoolProperty "RenderPRTCreator" do append theStringArray "Makers"
		if FranticParticles.GetBoolProperty "RenderPRTSource" do append theStringArray "Sources"
		if FranticParticles.GetBoolProperty "RenderPRTField" do append theStringArray "PRTField"
		if FranticParticles.GetBoolProperty "RenderStoke" do append theStringArray "Stoke"
		
		theString = ""
		if theStringArray.count == 0 then 
			theString = "None"
		else if theStringArray.count == 16 then 
			theString = "All"
		else	
		(
			for i = 1 to theStringArray.count-1 do theString += theStringArray[i]+","
			theString += theStringArray[theStringArray.count]
		)	
		theString	
	)
	
	fn convertSourcesFromString theString =
	(
		if theString == "None" then 
			theStringArray = #()
		else
			if theString == "All" then
				theStringArray = #("PF Geometry","PF Phantom","PF Box","Legacy","TP","FumeFX","Phoenix","Vertices","PRT","Volumes","Surfaces","Hair","Makers","Sources","PRTField","Stoke")
			else
				theStringArray = filterString theString ","
		FranticParticles.SetProperty "RenderParticleFlowGeometry" (findItem theStringArray "PF Geometry" > 0)
		FranticParticles.SetProperty "RenderParticleFlowPhantom" (findItem theStringArray "PF Phantom" > 0)
		FranticParticles.SetProperty "RenderParticleFlowBBox" (findItem theStringArray "PF Box" > 0)
		FranticParticles.SetProperty "RenderMaxParticles" (findItem theStringArray "Legacy" > 0)

		FranticParticles.SetProperty "RenderThinkingParticles" (findItem theStringArray "TP" > 0)
		FranticParticles.SetProperty "RenderFumeFX" (findItem theStringArray "FumeFX" > 0)
		FranticParticles.SetProperty "RenderPhoenixFD" (findItem theStringArray "Phoenix" > 0)
		FranticParticles.SetProperty "RenderGeometryVertices" (findItem theStringArray "Vertices" > 0)
			
		FranticParticles.SetProperty "RenderKrakatoaLoaders" (findItem theStringArray "PRT" > 0)
		FranticParticles.SetProperty "RenderGeometryVolumes" (findItem theStringArray "Volumes" > 0)
		FranticParticles.SetProperty "RenderPRTSurface" (findItem theStringArray "Surfaces" > 0)
		FranticParticles.SetProperty "RenderPRTHair" (findItem theStringArray "Hair" > 0)
			
		FranticParticles.SetProperty "RenderPRTCreator" (findItem theStringArray "Makers" > 0)
		FranticParticles.SetProperty "RenderPRTSource" (findItem theStringArray "Sources" > 0)
		FranticParticles.SetProperty "RenderPRTField" (findItem theStringArray "PRTField" > 0)
		FranticParticles.SetProperty "RenderStoke" (findItem theStringArray "Stoke" > 0)
		
		Krakatoa_GUI_Main.refresh_GUI()
	)
	
	fn createSourcePresetsRCMenu =
	(
		presetName = "UseParticlesFrom"
		local presetsList = #()
		local theKeys = getIniSetting (Krakatoa_PresetsDirectory + "//KrakatoaPreferences.ini") presetName  
		sort theKeys 
		if theKeys.count == 0 then 
		(
			theKeys = #("All","PF Geometry,PF Phantom,Legacy,PRT","PF Geometry,PF Phantom,Legacy,PRT,Vertices","None")
			for i in theKeys do
				setIniSetting (Krakatoa_PresetsDirectory + "//KrakatoaPreferences.ini") presetName (i as string) (i as string)
		)
		theValue = convertSourcesToString()
		for k in theKeys do appendIfUnique presetsList k
		
		local txt = StringStream ""
		format "rcmenu Presets_RCMenu\n(\n" to:txt
		
		if findItem presetsList theValue == 0 do 
		(
			format "menuItem mnu_AddPreset \"Add [%]\"\n" theValue to:txt
			format "on mnu_AddPreset picked do setIniSetting (Krakatoa_PresetsDirectory + \"//KrakatoaPreferences.ini\") \"%\" \"%\" \"%\" \n" presetName theValue theValue to:txt
			format "separator spr_01\n" to:txt
		)	
		
		cnt = 0
		for i in presetsList do
		(
			cnt += 1
			format "menuItem mnu_preset% \"%\" \n" cnt i to:txt
			format "on mnu_preset% picked do (Krakatoa_GUI_Main.convertSourcesFromString \"%\" )\n" cnt i to:txt
		)
		
		if findItem presetsList theValue != 0 do 
		(
			format "separator spr_10\n"  to:txt
			format "menuItem mnu_RemovePreset \"Remove [%]\"\n" theValue to:txt
			format "on mnu_RemovePreset picked do delIniSetting (Krakatoa_PresetsDirectory + \"//KrakatoaPreferences.ini\") \"%\" \"%\" \n" presetName theValue to:txt
		)	

		format "separator spr_20\n" to:txt
		local currentDefault = getIniSetting (getDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "SourceDefaults" (FranticParticles.GetProperty "ParticleMode")
		if currentDefault == "" do currentDefault = "--Not Set--"
		format "menuItem mnu_SetDefault \"Set [%] as Default For [%] mode - Current Default: %\"\n"  theValue  (FranticParticles.GetProperty "ParticleMode")  currentDefault to:txt
		format "on mnu_SetDefault picked do setIniSetting (getDir #plugcfg +  \"/Krakatoa/KrakatoaPreferences.ini\") \"SourceDefaults\" \"%\" \"%\" \n" (FranticParticles.GetProperty "ParticleMode") theValue to:txt
		format "separator spr_30\n"  to:txt
		theState = getIniSetting (getDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "Preferences" "SwitchSourceDefaultsByRenderMode"
		if theState == "" do theState = "false"
		
		format "menuItem mnu_EnableDefault \"Switch To User Defaults on 'Particle Render Mode' change.\" checked:%\n" theState to:txt
		format "on mnu_EnableDefault picked do setIniSetting (getDir #plugcfg + \"/Krakatoa/KrakatoaPreferences.ini\") \"Preferences\" \"SwitchSourceDefaultsByRenderMode\" ((not %) as string) \n" theState to:txt
		format ")\n" to:txt
		Krakatoa_RCMenu_Struct.Presets_RCMenu = execute (txt as string)
	)

	fn createPresetsRCMenu type:#mblur =
	(
		local twocontrols = false
		case type of
		(
			#shadowBilinearFilter: (
						presetName = "ShadowBilinearFilter"
						theSpinner = "spn_shadowBilinearFilter"
						theDefaultsKey = "ShadowBilinearFilter" 
						)
			#drawBilinearFilter: (
						presetName = "DrawBilinearFilter"
						theSpinner = "spn_drawBilinearFilter"
						theDefaultsKey = "DrawBilinearFilter" 
						)
						
			#mblur: (
						presetName = "MotionBlurPresets"
						theSpinner = "spn_motionBlurSegments"
						theDefaultsKey = "MotionBlurSegments" 
					)	
			#geosamples: (
						presetName = "MatteMotionBlurSegments"
						theSpinner = "spn_matteMotionBlurSegments"
						theDefaultsKey = "MatteMotionBlurSegments" 				
					)
			#shutter: (
						presetName = "ShutterPresets"
						theSpinner = "spn_blurShutter"
						theDefaultsKey = "ShutterAngleInDegrees"
					)	
			#bias: (
						presetName = "MotionBlurBiasPresets"
						theSpinner = "spn_blurBias"
						theDefaultsKey = "ShutterBias"
					)						
			#dofsamplerate: (
						presetName = "DOFSampleRatePresets"
						theSpinner = "spn_depthOfFieldSampleRate"
						theDefaultsKey = "DepthOfFieldSampleRate"
					)	
			#globalpercentage: (
						presetName = "GlobalPercentagePresets"
						theSpinner = "spn_GlobalParticlePercentage"
						theDefaultsKey = "GlobalParticlePercentage"
					)		
			#lightingdensity: (
						presetName = "LightingPassDensity"
						theSpinner = "spn_LightingDensityPerParticle"
						theSpinner2 = "spn_LightingDensityExponent"
						theDefaultsKey = "Lighting:Density:DensityPerParticle"
						theDefaultsKey2 = "Lighting:Density:DensityExponent"
						twocontrols = true
					)	
			#lightingdensityrelative: (
						presetName = "LightingPassDensityRelative"
						theSpinner = "spn_LightingDensityPerParticle"
						theSpinner2 = "spn_LightingDensityExponent"
						theDefaultsKey = "Lighting:Density:RelativeDensityPerParticle"
						theDefaultsKey2 = "Lighting:Density:RelativeDensityExponent"
						twocontrols = true
			)				
			#finaldensity: (
						presetName = "FinalPassDensity"
						theSpinner = "spn_densityPerParticle"
						theSpinner2 = "spn_densityExponent"
						theDefaultsKey = "Density:DensityPerParticle"
						theDefaultsKey2 = "Density:DensityExponent"
						twocontrols = true
					)	
			#emissionstrength: (
						presetName = "EmissionStrength"
						theSpinner = "spn_EmissionStrength"
						theSpinner2 = "spn_EmissionStrengthExponent"
						theDefaultsKey = "Emission:Strength"
						theDefaultsKey2 = "Emission:StrengthExponent"	
						twocontrols = true				
					)
			#emissionstrengthrelative: (
						presetName = "EmissionStrengthRelative"
						theSpinner = "spn_EmissionStrength"
						theSpinner2 = "spn_EmissionStrengthExponent"
						theDefaultsKey = "Emission:RelativeStrength"
						theDefaultsKey2 = "Emission:RelativeStrengthExponent"	
						twocontrols = true				
					)					
			#reflectionstrength: (
						presetName = "ReflectionStrength"
						theSpinner = "spn_ReflectionStrength"
						theDefaultsKey = "EnvironmentReflectionStrength"
					)					
			#voxelsize: (
						presetName = "VoxelSize"
						theSpinner = "spn_VoxelSize"
						theDefaultsKey = "VoxelSize" 
					)							
			#VoxelFilterRadius: (
						presetName = "VoxelFilterRadius"
						theSpinner = "spn_VoxelFilterRadius"
						theDefaultsKey = "VoxelFilterRadius" 
					)
			#PhaseEccentricity: (
						presetName = "PhaseEccentricity"
						theSpinner = "spn_PhaseEccentricity"
						theDefaultsKey = "PhaseEccentricity" 
					)	
			#smoothness: (
						presetName = "AdaptiveMotionBlurSmoothness"
						theSpinner = "spn_AdaptiveMotionBlurSmoothness"
						theDefaultsKey = "AdaptiveMotionBlurSmoothness"
					)						
			#upperbound: (
						presetName = "AdaptiveMotionBlurSegmentUpperBound"
						theSpinner = "spn_AdaptiveMotionBlurSegmentUpperBound"
						theDefaultsKey = "AdaptiveMotionBlurSegmentUpperBound"
					)						
			#lowerbound: (
						presetName = "AdaptiveMotionBlurSegmentLowerBound"
						theSpinner = "spn_AdaptiveMotionBlurSegmentLowerBound"
						theDefaultsKey = "AdaptiveMotionBlurSegmentLowerBound"
					)
			#adaptivembexponent: (
						presetName = "AdaptiveMotionBlurExponent"
						theSpinner = "spn_AdaptiveMotionBlurExponent"
						theDefaultsKey = "AdaptiveMotionBlurExponent"
					)					
		)
		local presetsList = #()
		local theKeys = if twocontrols then
			for i in (getIniSetting (Krakatoa_PresetsDirectory + "//KrakatoaPreferences.ini") presetName  ) collect i
		else
			for i in (getIniSetting (Krakatoa_PresetsDirectory + "//KrakatoaPreferences.ini") presetName  ) collect (execute i)
			
		sort theKeys 
		if theKeys.count == 0 then 
		(
			theKeys = case type of
			(
				#shadowBilinearFilter: #(1,2,4,8,16)
				#drawBilinearFilter: #(1,2,4,8,16)
				#mblur: #(2,8,16,32)
				#geosamples: #(1,2,3,4,8,10,12,16)
				#shutter: #(90.0,180.0,360.0)
				#bias: #(-1.0,0.0,1.0)
				#dofsamplerate: #(0.1,1.0,3.0,5.0,10.0)
				#globalpercentage: #(1.0,10.0,25.0,33.0,50.0,66.6,75.0,100.0)
				#lightingdensity: #("1.0E0","1.0E-1","1.0E-2")
				#lightingdensityrelative: #("1.0E0","1.0E-1","1.0E-2")
				#finaldensity: #("1.0E0","1.0E-1","1.0E-2")
				#emissionstrength: #("1.0E0","1.0E-1","1.0E-2")
				#emissionstrengthrelative: #("1.0E0","1.0E-1","1.0E-2")
				#reflectionstrength: #(0.1,0.25,0.5,0.6,0.75,1.0)
				#voxelsize: #(0.1,0.25,0.5,0.75,1.0)
				#VoxelFilterRadius: #(1,2,3,4,5,10)
				#PhaseEccentricity: #(-1.0,-0.5,0.0,0.5,1.0)
				#smoothness: #(0.01,0.1,0.5,1.0,1.5,2.0)
				#upperbound: #(16,32,48,64,128,256)
				#lowerbound: #(16,32,48,64,128,256)
				#adaptivembexponent: #(0.5,0.75,1.0,1.5,2.0)
			)
			for i in theKeys do
				setIniSetting (Krakatoa_PresetsDirectory + "//KrakatoaPreferences.ini") presetName (i as string) (i as string)
		)
		for k in theKeys do appendIfUnique presetsList k
		
		if twocontrols then
			theValue = (execute ("Krakatoa_GUI_Main."+ theSpinner +".value")) as string + "E" + (execute ("Krakatoa_GUI_Main."+ theSpinner2 +".value")) as string 
		else
			theValue = execute ("Krakatoa_GUI_Main."+ theSpinner +".value")
				
				
		local txt = StringStream ""
		format "rcmenu Presets_RCMenu\n(\n" to:txt
		if type == #emissionstrength do
		(
			format "menuItem mnu_CopyDensity \"Get From 'Final Pass Density' Controls\"\n" to:txt
			format "on mnu_CopyDensity picked do (\n" to:txt
			format "FranticParticles.SetProperty \"Emission:Strength\" (FranticParticles.GetProperty \"Density:DensityPerParticle\") \n" to:txt
			format "FranticParticles.SetProperty \"Emission:StrengthExponent\" (FranticParticles.GetProperty \"Density:DensityExponent\") \n" to:txt
			format "Krakatoa_GUI_Main.Refresh_GUI())\n" to:txt
			format "separator spr_10\n"  to:txt
		)
		if type == #finaldensity do
		(
			format "menuItem mnu_CopyDensity \"Get From 'Emission Strength' Controls\"\n" to:txt
			format "on mnu_CopyDensity picked do (\n" to:txt
			format "FranticParticles.SetProperty \"Density:DensityPerParticle\"  (FranticParticles.GetProperty \"Emission:Strength\") \n" to:txt
			format "FranticParticles.SetProperty \"Density:DensityExponent\" (FranticParticles.GetProperty \"Emission:StrengthExponent\" ) \n" to:txt
			format "Krakatoa_GUI_Main.Refresh_GUI())\n" to:txt
			format "separator spr_10\n"  to:txt
		)		
		if findItem presetsList theValue == 0 do 
		(
			format "menuItem mnu_AddPreset \"Add [%]\"\n" theValue to:txt
			format "on mnu_AddPreset picked do setIniSetting (Krakatoa_PresetsDirectory + \"//KrakatoaPreferences.ini\") \"%\" \"%\" \"%\" \n" presetName theValue theValue to:txt
			format "separator spr_20\n"  to:txt
		)	
		
		cnt = 0
		for i in presetsList do
		(
			cnt += 1
			format  "menuItem mnu_preset% \"%\" \n" cnt i to:txt
			if twocontrols then
			(
				local theFS = filterString i "E"
				format  "on mnu_preset% picked do (Krakatoa_GUI_Main.%.changed (Krakatoa_GUI_Main.%.value = %);Krakatoa_GUI_Main.%.changed (Krakatoa_GUI_Main.%.value = %))\n" cnt theSpinner theSpinner  theFS[1] theSpinner2 theSpinner2 theFS[2] to:txt
			)	
			else
				format  "on mnu_preset% picked do Krakatoa_GUI_Main.%.changed (Krakatoa_GUI_Main.%.value = %)\n" cnt theSpinner theSpinner i to:txt
		)
		
		if findItem presetsList theValue != 0 do 
		(
			format  "separator spr_30\n"  to:txt
			format  "menuItem mnu_RemovePreset \"Remove [%]\"\n"  theValue  to:txt
			format  "on mnu_RemovePreset picked do delIniSetting (Krakatoa_PresetsDirectory + \"/KrakatoaPreferences.ini\") \"%\" \"%\" \n" presetName theValue to:txt
		)	
		
		local currentDefault = getIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaDefaults.ini") "Defaults" theDefaultsKey
		if currentDefault == "" do currentDefault = "--Not Set--"
		if twocontrols then
		(
			local currentDefault2 = getIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaDefaults.ini") "Defaults" theDefaultsKey2
			if currentDefault2 != "" do currentDefault += "E"+currentDefault2 
		)	
			
		
		format  "separator spr_40\n" 	 to:txt
		if currentDefault != theValue as string do
		(
		
		format  "menuItem mnu_MakeDefault \"Set [%] as Default \"\n" theValue to:txt
		if twocontrols then
		(
			local theFS = filterString theValue "E"
			format  "on mnu_MakeDefault picked do (\n" to:txt
			format  "setIniSetting (GetDir #plugcfg + \"/Krakatoa/KrakatoaDefaults.ini\") \"Defaults\" \"%\" \"%\" \n" theDefaultsKey theFS[1] to:txt
			format  "setIniSetting (GetDir #plugcfg + \"/Krakatoa/KrakatoaDefaults.ini\") \"Defaults\" \"%\" \"%\" \n" theDefaultsKey2 theFS[2] to:txt
			format  ")\n" to:txt
		)
		else	
			format  "on mnu_MakeDefault picked do setIniSetting (GetDir #plugcfg + \"/Krakatoa/KrakatoaDefaults.ini\") \"Defaults\" \"%\" \"%\" \n" theDefaultsKey theValue to:txt
		)

		if currentDefault != "--Not Set--" do
		(
			format  "menuItem mnu_ResetDefault \"Reset Default [%]\"\n"  currentDefault to:txt
			if twocontrols then
			(
				local theFS = filterString theValue "E"
				format  "on mnu_ResetDefault picked do (\n" to:txt
				format  "delIniSetting (GetDir #plugcfg + \"/Krakatoa/KrakatoaDefaults.ini\") \"Defaults\" \"%\" \n" theDefaultsKey to:txt
				format  "delIniSetting (GetDir #plugcfg + \"/Krakatoa/KrakatoaDefaults.ini\") \"Defaults\" \"%\" \n" theDefaultsKey2 to:txt
				format  ")\n" to:txt
			)
			else	
				format  "on mnu_ResetDefault picked do delIniSetting (GetDir #plugcfg + \"/Krakatoa/KrakatoaDefaults.ini\") \"Defaults\" \"%\"\n" theDefaultsKey to:txt
		)		
		
		format  ")\n" to:txt
		Krakatoa_RCMenu_Struct.Presets_RCMenu = execute (txt as string)
	)

	label lbl_mblurplaceholder height:1 offset:[0,-9]
	group "Motion Blur and Depth Of Field"
	(
		checkbutton ckb_enableMotionBlur ">Enable Motion Blur" width:145 height:18 offset:[-3,-5] align:#left tooltip:"Toggle Motion Blur and related controls On and Off." enabled:true highlightcolor:KrakatoaSkinColorsStruct.Main across:3
		checkbutton ckb_jitteredMotionBlur ">Jittered Motion Blur" width:145 height:18 offset:[0,-5] align:#center tooltip:"When checked, samples will be jittered within the time segment.\n\nWhen unchecked, each sample will be centered to its time segment."  highlightcolor:KrakatoaSkinColorsStruct.Main
		checkbutton ckb_deformationMotionBlur ">Sub-Sample Geometry" width:145 height:18 offset:[4,-5] align:#right tooltip:"When checked, Matte Object Deformations will be taken into account."  highlightcolor:KrakatoaSkinColorsStruct.Main 
		
		spinner spn_motionBlurSegments  "Particle Segments:" range:[1,1000,2] fieldwidth:50 type:#integer   offset:[-21,-1] across:2 tooltip:"Number of Motion Blur Segments when rendering particles. Defines how many particle passes to draw to generate the final image."
		spinner spn_blurShutter  "Motion Blur Shutter (degs):" range:[0,100000,180] fieldwidth:50 type:#float align:#right offset:[-16,-1] tooltip:"Motion Blur duration defines as Shutter Angle.\n180 degrees mean half a frame.\n360 degrees mean full frame."
		
		spinner spn_matteMotionBlurSegments  "Matte Segments:" range:[1,100,2] fieldwidth:50 type:#integer offset:[-21,-1] across:2 tooltip:"Specifies the number of Matte Object animation segments to sample."
		spinner spn_blurBias  "Motion Blur Bias:" range:[-1,1,0] fieldwidth:50 type:#float align:#right offset:[-16,-1] tooltip:"Controls the Motion Blur Bias of Particles and Matte Objects.\nA value of 0 means Centered."

		checkbutton chk_useMatteSegments ">Use" width:45 height:20 align:#left offset:[-3,-26] tooltip:"When unchecked, the Particle Segments value will be used for Matte Segements, too.\n\nWhen checked, the Matte Segments value will be decoupled and can be used to undersample the matte objects animation for faster performance/lower precision." highlightcolor:KrakatoaSkinColorsStruct.Main
		
		button btn_motionBlurPresets ">>" width:20 height:18 align:#center offset:[-10,-41] tooltip:"Set Motion Blur Segments to a Preset Value, \nAdd/Remove current value to/from the Presets, \nor save as Startup Default." 
		button btn_matteMotionBlurSegmentsPreset ">>" width:20 height:18 align:#center offset:[-10,-3] tooltip:"Set Matte Objects Motion Blur Segments to a Preset Value, \nAdd/Remove current value to/from the Presets, or save as Startup Default." 
		
		button btn_blurShutterPresets ">>" width:20 height:18 align:#right offset:[4,-43] tooltip:"Set Motion Blur Shutter to a Preset Value, \nAdd/Remove current value to/from the Presets, or save as Startup Default." 
		button btn_blurBiasPresets ">>" width:20 height:18 align:#right offset:[4,-3] tooltip:"Set Motion Blur Bias to a Preset Value, \nAdd/Remove current value to/from the Presets, or save as Startup Default." 

		checkbutton chk_EnableAdaptiveMotionBlur ">Adaptive Motion Blur" width:218 height:18 offset:[-3,-5] align:#left across:2 highlightcolor:KrakatoaSkinColorsStruct.Main
		checkbutton ckb_disableCameraMotionBlur ">Disable Blur From Camera Motion " width:218 height:18 offset:[5,-5] align:#right tooltip:"When checked, the animation of the Camera will be ignored when calculating Motion Blur.\n\nWhen unchecked, the Camera motion will be taken into account." enabled:true highlightcolor:KrakatoaSkinColorsStruct.Main 

		spinner spn_AdaptiveMotionBlurSegmentLowerBound  "Min. Segments:" range:[1,1024,2] fieldwidth:50 type:#integer   offset:[-21,-1] across:2 tooltip:"Minimum number of Adaptive Motion Blur Segments when rendering particles. Defines the least number of particle passes to draw to generate the final image."
		spinner spn_AdaptiveMotionBlurSegmentUpperBound  "Max. Segments:" range:[1,1024,64] fieldwidth:50 type:#integer align:#right offset:[-16,-1] tooltip:"Maximum number of Adaptive Motion Blur Segments when rendering particles. Defines the highest number of particle passes to draw to generate the final image."

		spinner spn_AdaptiveMotionBlurSmoothness  "Smoothness:" range:[0.01,10,1] fieldwidth:50 type:#float scale:0.01 offset:[-21,-1] across:2 tooltip:"Set Adaptive Motion Blur Segments Minimum to a Preset Value, \nAdd/Remove current value to/from the Presets, \nor save as Startup Default." 
		spinner spn_AdaptiveMotionBlurExponent "Smoothness Bias:" range:[0.01,10,1] fieldwidth:50 type:#float scale:0.01 align:#right offset:[-16,-1] tooltip:""

		button btn_AdaptiveMotionBlurSegmentLowerBoundPresets ">>" width:20 height:18 align:#center offset:[-10,-42]  tooltip:"Set Adaptive Motion Blur Segments Minimum to a Preset Value, \nAdd/Remove current value to/from the Presets, or save as Startup Default." 
		button btn_AdaptiveMotionBlurSegmentUpperBoundPresets ">>" width:20 height:18 align:#right offset:[4,-23] tooltip:"Set Adaptive Motion Blur Segments Maximum to a Preset Value, \nAdd/Remove current value to/from the Presets, or save as Startup Default." 


		button btn_AdaptiveMotionBlurSmoothnessPresets ">>" width:20 height:18 align:#center offset:[-10,-3] tooltip:"Set Adaptive Motion Blur Smoothness to a Preset Value, \nAdd/Remove current value to/from the Presets, or save as Startup Default." 
		button btn_AdaptiveMotionBlurExponentPresets ">>" width:20 height:18 align:#right offset:[4,-23] tooltip:"Set Adaptive Motion Blur Smoothness Bias to a Preset Value, \nAdd/Remove current value to/from the Presets, or save as Startup Default." 
	)
	
	label lbl_dofplaceholder height:1 offset:[0,-18]
	group ""
	(
		checkbutton ckb_enableDepthOfField ">Enable Depth Of Field" width:135 height:18 offset:[-5,-7] align:#left tooltip:"Toggle Depth Of Field On and Off." enabled:true highlightcolor:KrakatoaSkinColorsStruct.Main across:4
		checkbutton ckb_AllocateBokehBlendInfluence	">Allocate BokehBlendInfluence" width:163 height:18 offset:[50,-7] align:#center tooltip:"Allocate 'BokehBlendInfluence' Channel" highlightcolor:KrakatoaSkinColorsStruct.Main
		
		spinner spn_depthOfFieldSampleRate  "Sample Rate:" offset:[92,-5] range:[0.01,1000,2] fieldwidth:40 type:#float align:#right 
		button btn_depthOfFieldPresets ">>" width:20 height:18 align:#right offset:[6,-6] tooltip:"Set Depth Of Field Sample Rate to a Preset Value, \nAdd/Remove current value to/from the Presets, \nor save as Startup Default." 
	)
	
	imgtag img_particleModebackground1 width:477 height:3 offset:[-12,-3] align:#center enabled:false

	dropdownlist ddl_particleMode width:280 offset:[-9,-4] align:#left items:#("Render Scene Particles","Save Particles To File Sequence","Light Scene Particles") across:3 tooltip:"Render Target - \nRender Scene Particles renders to Output Image;\nSave Particles saves to a particle file sequence;\nLight Scene Particles only performs lighting for saving Attenuation Maps." --,"Export To Krakatoa SR"
	
	spinner spn_GlobalParticlePercentage "Load Percentage:" range:[0,100,100] offset:[130,-1] type:#float fieldwidth:45 align:#right across:2 enabled:true
	button btn_GlobalPercentagePresets ">>" width:20 height:18 align:#right offset:[8,-2] tooltip:"Set Global Load Percentage to a Preset Value, or Add/Remove current value to/from the Presets." enabled:true 
	
	checkbutton chk_Render_PFlowGeometry ">PF Geo." width:70 height:20 align:#left across:4 offset:[-10,-3] tooltip:"Toggle Rendering of Particle Flow particles whose Render Type is set to Geometry in the Render Operator" highlightcolor:KrakatoaSkinColorsStruct.Main
	checkbutton chk_Render_PFlowPhantom ">PF Phan." width:70 height:20 align:#left offset:[-47,-3] tooltip:"Toggle Rendering of Particle Flow particles whose Render Type is set to Phantom in the Render Operator" highlightcolor:KrakatoaSkinColorsStruct.Main
	checkbutton chk_Render_PFlowBBox ">PF BBox" width:70 height:20 align:#left  offset:[-84,-3] tooltip:"Toggle Rendering of Particle Flow particles whose Render Type is set to Bounding Box in the Render Operator" highlightcolor:KrakatoaSkinColorsStruct.Main
	checkbutton chk_Render_MaxParticles ">Legacy" width:70 height:20 align:#left offset:[-121,-3] tooltip:"Toggle Rendering of 3ds Max Legacy Particles (Spray, Snow, PArray, PCloud, Super Spray etc.)" highlightcolor:KrakatoaSkinColorsStruct.Main
	
	checkbutton chk_Render_ThinkingParticles ">Thinking" width:70 height:20 align:#left across:4 offset:[-10,-4] tooltip:"Toggle Rendering of Cebas Thinking Particles" highlightcolor:KrakatoaSkinColorsStruct.Main
	checkbutton chk_Render_FumeFX ">PRT FFX" width:70 height:20 align:#left offset:[-47,-4]  tooltip:"Toggle Rendering of Krakatoa PRT FumeFX objects systems." highlightcolor:KrakatoaSkinColorsStruct.Main enabled:true
	checkbutton chk_Render_PhoenixFD ">Phoenix" width:70 height:20 align:#left offset:[-84,-4]  tooltip:"Toggle Rendering of Chaos Group Phoenix FD systems." highlightcolor:KrakatoaSkinColorsStruct.Main enabled:true
	checkbutton chk_Render_GeometryVertices ">Geo.Verts" width:70 height:20 align:#left offset:[-121,-4] tooltip:"Toggle Rendering of visible Scene Geometry Objects (Vertices as Particles) - excluding Geometry Objects assigned as Matte Objects via Named Selection Sets."  highlightcolor:KrakatoaSkinColorsStruct.Main
	
	checkbutton chk_Render_KrakatoaLoaders  ">PRT Loader" width:70 height:20 align:#left across:4 offset:[-10,-4]	tooltip:"Toggle Rendering of Krakatoa PRT Loader objects." highlightcolor:KrakatoaSkinColorsStruct.Main
	checkbutton chk_Render_GeometryVolumes ">PRT Volume" width:70 height:20 align:#left offset:[-47,-4] tooltip:"Toggle Rendering of Krakatoa PRT Volume objects." highlightcolor:KrakatoaSkinColorsStruct.Main
	checkbutton chk_Render_GeometrySurfaces ">PRT Surface" width:70 height:20 align:#left offset:[-84,-4] tooltip:"Toggle Rendering of Krakatoa PRT Surface objects." highlightcolor:KrakatoaSkinColorsStruct.Main
	checkbutton chk_Render_PRTHair  ">PRT Hair" width:70 height:20 align:#left offset:[-121,-4]	tooltip:"Toggle Rendering of Krakatoa PRT Hair objects." highlightcolor:KrakatoaSkinColorsStruct.Main
	

	checkbutton chk_Render_PRTMakers ">PRT Maker" width:70 height:20 align:#left across:4 offset:[-10,-4] tooltip:"Toggle Rendering of Krakatoa PRT Maker objects." highlightcolor:KrakatoaSkinColorsStruct.Main
	checkbutton chk_Render_PRTSource ">PRT Source" width:70 height:20 align:#left offset:[-47,-4]  tooltip:"Toggle Rendering of Krakatoa PRT Source objects." highlightcolor:KrakatoaSkinColorsStruct.Main 
	checkbutton chk_Render_PRTField ">PRT Field" width:70 height:20 align:#left offset:[-84,-4]  tooltip:"Toggle Rendering of Stoke PRT Field objects." highlightcolor:KrakatoaSkinColorsStruct.Main 
	checkbutton chk_Render_Stoke ">Stoke" width:70 height:20 align:#left offset:[-121,-4] tooltip:"Render Stoke Objects" highlightcolor:KrakatoaSkinColorsStruct.Main
	
	button btn_useParticlesFromPresets ">>" width:15 height:83 align:#center offset:[62,-88] tooltip:"Load, Create and Manage Presets for the 'Load Particles From...' Options" 
	
	checkbutton chk_iterativeRender ">Iterative [Full]" align:#right width:80 height:18 offset:[204,-88]  across:2 tooltip:"When checked, the current frame will be rendered and NOT saved to disk. Only affects the RENDER button in Krakatoa, not the Max Render controls." highlightcolor:KrakatoaSkinColorsStruct.Main
	button btn_iterativeRenderSettings ">>" width:20 height:18 align:#right offset:[9,-88] tooltip:"Click or Right-Click to open context menu with Output Resolution Scale options..."

	button btn_quickRender "RENDER" align:#right width:100 height:64 offset:[8,-4] tooltip:"Click to Render or Save Particles. \nRight-click to open Render Context Menu."
	
	checkbutton btn_enableLightingCache  ">LCache" align:#right width:50 height:38 offset:[-95,-88] tooltip:"When checked, all particles for the Lighting Pass of the current frame will be cached temporarily to RAM when first rendering.\nRendering again will use the cache.\n\nRight-click for Cache Options..." highlightcolor:KrakatoaSkinColorsStruct.Main
	progressbar prg_cacheStatus align:#right width:50 height:8 value:100 color:green offset:[-94,-6] 
	checkbutton btn_enableParticleCache  ">PCache" align:#right width:50 height:38 offset:[-95,-5] tooltip:"When checked, all particles for the Final Pass of the current frame will be cached temporarily to RAM when first rendering. \nRendering again will use the cache.\n\nRight-click for Cache Options..." highlightcolor:KrakatoaSkinColorsStruct.Main

	imgtag img_particleModebackground2 width:474 height:3 offset:[-10,-3] align:#center enabled:false
	imgtag img_particleModebackground3 width:3 height:111 offset:[-13,-97-21] align:#left enabled:false
	imgtag img_particleModebackground4 width:3 height:111 offset:[9,-95-21] align:#right enabled:false
	
	groupbox grp_overrides "Advanced Overrides" width:225 height:36 across:2 offset:[-10,-3]
	groupbox grp_post "Shadow Data Saving"  width:226 height:36 offset:[-1,-3]

	checkbutton ckb_ignoreMissingParticles ">Ignore Missing PRTs" width:112 height:18  across:4 align:#left offset:[-7,-27] highlightcolor:(color 255 160 160)  tooltip:"When checked, PRT Loaders containing missing files will cause no errors. Good for test-rendering incomplete sequences." 
--	checkbutton chb_allowPRTLoaderOverwriting ">Overwrite PRTs" width:104 height:18  align:#left offset:[1,-27] highlightcolor:(color 255 160 160) tooltip:"When checked, saving to a PRT sequence whose name is used by a source PRT Loader in the scene will cause no error."
	checkbutton chb_multiThreadedLoading ">Fast PRT Loading" width:104 height:18  align:#left offset:[-1,-27] highlightcolor:(color 255 160 160) tooltip:"When checked, loading multiple PRT file sequences within a single PRT Loader will be multi-threaded.\nRecommended for fast iterative rendering on a workstation.\n\nWhen unchecked, only one thread will be used.\nRecommended for network rendering."
	
	checkbutton chk_SaveAttenuation ">Save Attenuation Maps" width:150 height:18  align:#right offset:[46,-27]  tooltip:"When checked, lights using Krakatoa Shadows generator will save Attenuation Maps to disk." highlightcolor:KrakatoaSkinColorsStruct.Main
	button btn_OpenShadowsExplorer "Explore..." width:65  height:18 align:#right offset:[5,-27]  tooltip:"Click to open the Krakatoa Shadows Explorer tool." highlightcolor:KrakatoaSkinColorsStruct.Main
	
	on btn_OpenShadowsExplorer pressed do macros.run "Krakatoa" "KrakatoaShadows"
	
	--label lbl_advancedoverrides height:0
	
	group "Other Feature States Overview - Right-Click Buttons to Navigate to Detailed Settings"
	(
		checkbutton chk_overrideColor ">Override Color" across:4 width:110 offset:[-6,-4] height:18 align:#left highlightcolor:KrakatoaSkinColorsStruct.Main tooltip:"Duplicates the functionality of the >Override Color option in the Global Render Values rollout. Right-click to navigate to the Global Render Values rollout."
		checkbutton chk_overrideEmission ">Override Emission" width:110 offset:[0,-4] height:18 align:#center highlightcolor:KrakatoaSkinColorsStruct.Main tooltip:"Duplicates the functionality of the >Override Emission option in the Global Render Values rollout. Right-click to navigate to the Global Render Values rollout."
		checkbutton chk_overrideAbsorption ">Override Absorption" width:110 offset:[4,-4] height:18 align:#center highlightcolor:KrakatoaSkinColorsStruct.Main tooltip:"Duplicates the functionality of the >Override Absorption option in the Global Render Values rollout. Right-click to navigate to the Global Render Values rollout."
		checkbutton chk_overrideDensity ">Override Density" width:110 offset:[9,-4] height:18 align:#right highlightcolor:KrakatoaSkinColorsStruct.Main tooltip:"Duplicates the functionality of the >Override Density option in the Global Render Values rollout. Right-click to navigate to the Global Render Values rollout."
		
		checkbutton chk_matteObjects ">Use Matte Objects" across:4 width:110 offset:[-6,-4] height:18 align:#left highlightcolor:KrakatoaSkinColorsStruct.Main tooltip:"Duplicates the functionality of the >Use Matte Objects option in the Matte Objects rollout. Right-click to navigate to the Matte Objects rollout."
		checkbutton chk_matteObjectsLayers ">Save Multi.Layers" width:110 offset:[0,-4] height:18 align:#center highlightcolor:KrakatoaSkinColorsStruct.Main tooltip:"Duplicates the functionality of the >Save Multi.Layers option in the Matte Objects rollout. Right-click to navigate to the Matte Objects rollout."
		checkbutton chk_useDepthMaps ">Use Depth Map Files" width:110 offset:[4,-4] height:18 align:#center highlightcolor:KrakatoaSkinColorsStruct.Main tooltip:"Duplicates the functionality of the >Use Depth Map File Sequence option in the Matte Objects rollout. Right-click to navigate to the Matte Objects rollout."
		checkbutton chk_APME ">Use APME" width:110 offset:[9,-4] height:18 align:#right highlightcolor:KrakatoaSkinColorsStruct.Main tooltip:"Duplicates the functionality of the >Use APME option in the Ambient PME rollout. Right-click to navigate to the Ambient PME rollout."
	)		
	
	button btn_Tools_01 "Schematic" height:16 width:63 across:7 offset:[-8,-2] align:#left tooltip:"Click or Right-Click to open the Krakatoa Schematic Flow utility."
	button btn_Tools_02 "PD Viewer" height:16 width:63 offset:[-5,-2] align:#left tooltip:"Click or Right-Click to open the Krakatoa Particle Data Viewer utility."
	button btn_Tools_03 "PRT Scan" height:16 width:63 offset:[-1,-2] align:#center tooltip:"Click or Right-Click to open the Krakatoa PRT Scanner utility."
	button btn_Tools_04 "Explorers" height:16 width:63 offset:[2,-2] align:#center tooltip:"Click or Right-Click to open the Krakatoa Explorers floater."
	button btn_Tools_05 "Preferences" height:16 width:63 offset:[5,-2] align:#center tooltip:"Click or Right-Click to open the Krakatoa Preferences dialog."	
	button btn_Tools_06 "Notes" height:16 width:63 offset:[9,-2] align:#right tooltip:"Click or Right-Click to open the User Notes dialog."	
	button btn_Tools_07 "Log" height:16 width:63 offset:[12,-2] align:#right tooltip:"Click or Right-Click to open the Krakatoa Log Window."	
	
	on btn_Tools_01 pressed do macros.run "Krakatoa" "SchematicFlow"
	on btn_Tools_01 rightclick do macros.run "Krakatoa" "SchematicFlow"		
		
	on btn_Tools_02 pressed do macros.run "Krakatoa" "KrakatoaParticleDataViewer"
	on btn_Tools_02 rightclick do macros.run "Krakatoa" "KrakatoaParticleDataViewer"		
	
	on btn_Tools_03 pressed do macros.run "Krakatoa" "KrakatoaPRTscan"
	on btn_Tools_03 rightclick do macros.run "Krakatoa" "KrakatoaPRTscan"		

	on btn_Tools_04 pressed do macros.run "Krakatoa" "KrakatoaExplorers"
	on btn_Tools_04 rightclick do macros.run "Krakatoa" "KrakatoaExplorers"		

	on btn_Tools_05 pressed do macros.run "Krakatoa" "KrakatoaPreferences"
	on btn_Tools_05 rightclick do macros.run "Krakatoa" "KrakatoaPreferences"		

	on btn_Tools_06 pressed do macros.run "Krakatoa" "KrakatoaNotes"
	on btn_Tools_06 rightclick do macros.run "Krakatoa" "KrakatoaNotes"		

	on btn_Tools_07 pressed do 
	(
		FranticParticles.LogWindowVisible = true
		updateToolbarButtons()		
	)
	on btn_Tools_07 rightclick do 
	(
		FranticParticles.LogWindowVisible = true
		updateToolbarButtons()
	)
	
	on ddl_RenderingMethod rightclick do
		FranticParticleRenderMXS.createDefaultsRCMenu "RenderingMethod" "Rendering Method"
	
	on ddl_shadingMode rightclick do
	(
		FranticParticleRenderMXS.createDefaultsRCMenu "PhaseFunction" "Phase Function (Shading Mode)"
	)
	
	on ddl_particleMode rightclick do
		FranticParticleRenderMXS.createDefaultsRCMenu "ParticleMode" "Rendering Mode"
	
	on btn_VoxelFilterRadiusPreset pressed do
	(
		createPresetsRCMenu type:#VoxelFilterRadius
		popUpMenu Krakatoa_RCMenu_Struct.Presets_RCMenu position:mouse.screenPos
	)	
	
	on btn_VoxelFilterRadiusPreset rightclick do
	(
		createPresetsRCMenu type:#VoxelFilterRadius
		popUpMenu Krakatoa_RCMenu_Struct.Presets_RCMenu position:mouse.screenPos
	)	

	
	on ckb_AdditiveMode changed state do
	(
		FranticParticles.SetProperty "AdditiveMode" (state as string)
		FranticParticles.SetProperty "Density:DensityMethod" (if state then "Additive Density" else "Volumetric Density")
		ckb_useEmissionColor.enabled = ckb_useFilterColor.enabled = not state
		Krakatoa_GUI_Channels.updateMemChannels()
		Krakatoa_GUI_Main.update2009VFBControls side:#left
		try(Krakatoa_updateSchematicFlow())catch()
	)
	
	on ckb_AdditiveMode rightclick do
		FranticParticleRenderMXS.createDefaultsRCMenu "AdditiveMode" ">Force Additive Mode"


	on btn_VoxelSizePreset pressed do
	(
		createPresetsRCMenu type:#voxelsize
		popUpMenu Krakatoa_RCMenu_Struct.Presets_RCMenu position:mouse.screenPos
		update2009VFBControls side:#left
	)	
	on btn_VoxelSizePreset rightclick do
	(
		createPresetsRCMenu type:#voxelsize
		popUpMenu Krakatoa_RCMenu_Struct.Presets_RCMenu position:mouse.screenPos
		update2009VFBControls side:#left		
	)	
	
	on btn_shadowBilinearFilterPreset pressed do
	(
		createPresetsRCMenu type:#shadowBilinearFilter
		popUpMenu Krakatoa_RCMenu_Struct.Presets_RCMenu position:mouse.screenPos
		update2009VFBControls side:#left
	)
	on btn_shadowBilinearFilterPreset rightclick do
	(
		createPresetsRCMenu type:#shadowBilinearFilter
		popUpMenu Krakatoa_RCMenu_Struct.Presets_RCMenu position:mouse.screenPos
		update2009VFBControls side:#left
	)	
	
	on btn_drawBilinearFilterPreset pressed do
	(
		createPresetsRCMenu type:#drawBilinearFilter
		popUpMenu Krakatoa_RCMenu_Struct.Presets_RCMenu position:mouse.screenPos
		update2009VFBControls side:#left		
	)
	on btn_drawBilinearFilterPreset rightclick do
	(
		createPresetsRCMenu type:#drawBilinearFilter
		popUpMenu Krakatoa_RCMenu_Struct.Presets_RCMenu position:mouse.screenPos
		update2009VFBControls side:#left		
	)	
	
	on btn_lightingDensityPreset pressed do
	(
		if ckb_relativeLightingDensity.checked then
			createPresetsRCMenu type:#lightingdensityrelative
		else
			createPresetsRCMenu type:#lightingdensity
		popUpMenu Krakatoa_RCMenu_Struct.Presets_RCMenu position:mouse.screenPos
		update2009VFBControls side:#left
	)	
	on btn_lightingDensityPreset rightclick do
	(
		if ckb_relativeLightingDensity.checked then
			createPresetsRCMenu type:#lightingdensityrelative
		else
			createPresetsRCMenu type:#lightingdensity
		popUpMenu Krakatoa_RCMenu_Struct.Presets_RCMenu position:mouse.screenPos
		update2009VFBControls side:#left
	)	
	
	on btn_finalDensityPreset pressed do
	(
		createPresetsRCMenu type:#finaldensity
		popUpMenu Krakatoa_RCMenu_Struct.Presets_RCMenu position:mouse.screenPos
		update2009VFBControls side:#left
	)	
	on btn_finalDensityPreset rightclick do
	(
		createPresetsRCMenu type:#finaldensity
		popUpMenu Krakatoa_RCMenu_Struct.Presets_RCMenu position:mouse.screenPos
		update2009VFBControls side:#left
	)			
	
	on btn_emissionStrengthPreset pressed do
	(
		if ckb_relativeEmissionStrength.checked then
			createPresetsRCMenu type:#emissionstrengthrelative
		else
			createPresetsRCMenu type:#emissionstrength
		popUpMenu Krakatoa_RCMenu_Struct.Presets_RCMenu position:mouse.screenPos
		update2009VFBControls side:#left
	)	
	on btn_emissionStrengthPreset rightclick do
	(
		if ckb_relativeEmissionStrength.checked then
			createPresetsRCMenu type:#emissionstrengthrelative
		else
			createPresetsRCMenu type:#emissionstrength
		popUpMenu Krakatoa_RCMenu_Struct.Presets_RCMenu position:mouse.screenPos
		update2009VFBControls side:#left
	)		
	
	on btn_reflectionStrengthPreset pressed do
	(
		createPresetsRCMenu type:#reflectionstrength
		popUpMenu Krakatoa_RCMenu_Struct.Presets_RCMenu position:mouse.screenPos
		update2009VFBControls side:#left
	)	
	on btn_reflectionStrengthPreset rightclick do
	(
		createPresetsRCMenu type:#reflectionstrength
		popUpMenu Krakatoa_RCMenu_Struct.Presets_RCMenu position:mouse.screenPos
		update2009VFBControls side:#left
	)			
	
	on btn_motionBlurPresets pressed do
	(
		createPresetsRCMenu type:#mblur
		popUpMenu Krakatoa_RCMenu_Struct.Presets_RCMenu position:mouse.screenPos
		update2009VFBControls side:#right
	)
	
	on btn_matteMotionBlurSegmentsPreset pressed do
	(
		createPresetsRCMenu type:#geosamples
		popUpMenu Krakatoa_RCMenu_Struct.Presets_RCMenu position:mouse.screenPos
		update2009VFBControls side:#right
	)
	
	on btn_blurShutterPresets pressed do
	(
		createPresetsRCMenu type:#shutter
		popUpMenu Krakatoa_RCMenu_Struct.Presets_RCMenu position:mouse.screenPos		
		update2009VFBControls side:#right
	)
	on btn_blurBiasPresets pressed do
	(
		createPresetsRCMenu type:#bias
		popUpMenu Krakatoa_RCMenu_Struct.Presets_RCMenu position:mouse.screenPos		
		update2009VFBControls side:#right
	)		
	on btn_AdaptiveMotionBlurSmoothnessPresets pressed do
	(
		createPresetsRCMenu type:#smoothness
		popUpMenu Krakatoa_RCMenu_Struct.Presets_RCMenu position:mouse.screenPos		
		update2009VFBControls side:#right
	)	
	on btn_AdaptiveMotionBlurExponentPresets pressed do
	(
		createPresetsRCMenu type:#adaptivembexponent
		popUpMenu Krakatoa_RCMenu_Struct.Presets_RCMenu position:mouse.screenPos		
		update2009VFBControls side:#right
	)		

	on btn_AdaptiveMotionBlurSegmentUpperBoundPresets pressed do
	(
		createPresetsRCMenu type:#upperbound
		popUpMenu Krakatoa_RCMenu_Struct.Presets_RCMenu position:mouse.screenPos		
		update2009VFBControls side:#right
	)	

	on btn_AdaptiveMotionBlurSegmentLowerBoundPresets pressed do
	(
		createPresetsRCMenu type:#lowerbound
		popUpMenu Krakatoa_RCMenu_Struct.Presets_RCMenu position:mouse.screenPos		
		update2009VFBControls side:#right
	)	
	
	on btn_depthOfFieldPresets pressed do
	(
		createPresetsRCMenu type:#dofsamplerate
		popUpMenu Krakatoa_RCMenu_Struct.Presets_RCMenu position:mouse.screenPos	
		update2009VFBControls side:#right		
	)	
	
	on btn_GlobalPercentagePresets pressed do
	(
		createPresetsRCMenu type:#globalpercentage
		popUpMenu Krakatoa_RCMenu_Struct.Presets_RCMenu position:mouse.screenPos	
		update2009VFBControls side:#right 
	)	


	on btn_motionBlurPresets rightclick do
	(
		createPresetsRCMenu type:#mblur
		popUpMenu Krakatoa_RCMenu_Struct.Presets_RCMenu position:mouse.screenPos
	)
	
	on btn_matteMotionBlurSegmentsPreset rightclick do
	(
		createPresetsRCMenu type:#geosamples
		popUpMenu Krakatoa_RCMenu_Struct.Presets_RCMenu position:mouse.screenPos
	)	
	
	on btn_blurShutterPresets rightclick do
	(
		createPresetsRCMenu type:#shutter
		popUpMenu Krakatoa_RCMenu_Struct.Presets_RCMenu position:mouse.screenPos		
	)
	on btn_blurBiasPresets rightclick do
	(
		createPresetsRCMenu type:#bias
		popUpMenu Krakatoa_RCMenu_Struct.Presets_RCMenu position:mouse.screenPos		
	)		
	on btn_AdaptiveMotionBlurSmoothnessPresets rightclick do
	(
		createPresetsRCMenu type:#smoothness
		popUpMenu Krakatoa_RCMenu_Struct.Presets_RCMenu position:mouse.screenPos		
		update2009VFBControls side:#right
	)		
	on btn_AdaptiveMotionBlurExponentPresets rightclick do
	(
		createPresetsRCMenu type:#adaptivembexponent
		popUpMenu Krakatoa_RCMenu_Struct.Presets_RCMenu position:mouse.screenPos		
		update2009VFBControls side:#right
	)		
	on btn_AdaptiveMotionBlurSegmentUpperBoundPresets rightclick do
	(
		createPresetsRCMenu type:#upperbound
		popUpMenu Krakatoa_RCMenu_Struct.Presets_RCMenu position:mouse.screenPos		
		update2009VFBControls side:#right
	)		
	on btn_AdaptiveMotionBlurSegmentLowerBoundPresets rightclick do
	(
		createPresetsRCMenu type:#lowerbound
		popUpMenu Krakatoa_RCMenu_Struct.Presets_RCMenu position:mouse.screenPos		
		update2009VFBControls side:#right
	)		
	
	on btn_depthOfFieldPresets rightclick do
	(
		createPresetsRCMenu type:#dofsamplerate
		popUpMenu Krakatoa_RCMenu_Struct.Presets_RCMenu position:mouse.screenPos		
	)		

	on btn_GlobalPercentagePresets rightclick do
	(
		createPresetsRCMenu type:#globalpercentage
		popUpMenu Krakatoa_RCMenu_Struct.Presets_RCMenu position:mouse.screenPos		
	)	


	on ckb_ignoreMissingParticles rightClick do
		FranticParticleRenderMXS.createDefaultsRCMenu "IgnoreMissingParticles" ">Ignore Missing Particles"
	on chb_allowPRTLoaderOverwriting rightClick do
		FranticParticleRenderMXS.createDefaultsRCMenu "AllowPRTLoaderOverwriting" ">Overwrite PRTs"
	on chb_multiThreadedLoading rightClick do
		FranticParticleRenderMXS.createDefaultsRCMenu "Performance:MT:Loading" ">Fast PRT Loading"
	
	
	on btn_useParticlesFromPresets pressed do 
	(
		createSourcePresetsRCMenu()
		popUpMenu Krakatoa_RCMenu_Struct.Presets_RCMenu position:mouse.screenPos		
	)
	on btn_useParticlesFromPresets rightClick do 
	(
		createSourcePresetsRCMenu()
		popUpMenu Krakatoa_RCMenu_Struct.Presets_RCMenu position:mouse.screenPos		
	)	
	
	on spn_GlobalParticlePercentage changed val do 
	(
		FranticParticles.SetProperty "GlobalParticlePercentage" (val as string)
		update2009VFBControls()
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
		chk_iterativeRender.text = (">Iterative ["+theString+"]")
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
		try(Krakatoa_VFB_Right_Rollout.refreshCacheStatus())catch()
		try(Krakatoa_GUI_Channels.updateMemChannels())catch()
	)
	
	fn tweakControlPositions =
	(
		--NOTE: The following absolute positions are enforced to prevent foreign language layouts that produce different spacing from shifting controls around.
		--This should be disabled for relative placement edits and regenerated afterwards
		
		--for i in Krakatoa_GUI_Main.controls do try(format "%.pos = % \n" i.name i.pos)catch()
		try(
			
			btn_LoadSave_Main.pos = [3,2] 
			btn_Help_Main.pos = [23,2] 
			btn_GoTo_01.pos = [124,2] 
			btn_GoTo_02.pos = [185,2] 
			btn_GoTo_03.pos = [245,2] 
			btn_GoTo_04.pos = [306,2] 
			btn_GoTo_05.pos = [366,2] 
			btn_Float_Rollout.pos = [432,2] 
			lbl_lightingandshading.pos = [228,13] 
			bmp_RenderingMethod.pos = [8,34] 
			ddl_RenderingMethod.pos = [19,34] 
			spn_VoxelSize.pos = [277,37] 
			btn_VoxelSizePreset.pos = [290,36] 
			ckb_AdditiveMode.pos = [312,36] 
			bmp_shadingMode.pos = [8,56] 
			ddl_shadingMode.pos = [19,56] 
			spn_VoxelFilterRadius.pos = [277,58] 
			btn_VoxelFilterRadiusPreset.pos = [290,57] 
			ckb_useFilterColor.pos = [312,57] 
			lbl_void10.pos = [228,61] 
			lbl_void20.pos = [228,63] 
			ckb_IgnoreSceneLights.pos = [8,96] 
			ddl_attenuationLookupFilter.pos = [6,115] 
			spn_shadowBilinearFilter.pos = [195,117] 
			btn_shadowBilinearFilterPreset.pos = [207,116] 
			ddl_drawPointFilter.pos = [228,117] 
			spn_drawBilinearFilter.pos = [417,119] 
			btn_drawBilinearFilterPreset.pos = [430,118] 
			spn_LightingDensityPerParticle.pos = [194,141] 
			spn_densityPerParticle.pos = [417,141] 
			spn_LightingDensityExponent.pos = [194,159] 
			spn_densityExponent.pos = [417,159] 
			ckb_linkLightingAndRenderingDensity.pos = [8,140] 
			ckb_relativeLightingDensity.pos = [8,168] 
			btn_lightingDensityPreset.pos = [207,141] 
			btn_finalDensityPreset.pos = [430,141] 
			edt_LightingDensityFullValue.pos = [149,177] 
			edt_FinalDensityFullValue.pos = [372,177] 
			lbl_placeHolderDensity.pos = [228,183] 
			ckb_useEmissionColor.pos = [8,215] 
			spn_emissionStrength.pos = [417,215] 
			ckb_useEnvironmentReflections.pos = [8,234] 
			spn_emissionStrengthExponent.pos = [417,233] 
			ckb_allocateReflectionStrengthChannel.pos = [8,253] 
			spn_reflectionStrength.pos = [195,254] 
			edt_emissionStrengthResultingValue.pos = [371,252] 
			btn_reflectionStrengthPreset.pos = [208,253] 
			btn_emissionStrengthPreset.pos = [430,215] 
			ckb_useEmissionStrength.pos = [231,215] 
			ckb_relativeEmissionStrength.pos = [231,244] 
			lbl_mblurplaceholder.pos = [228,274] 
			ckb_enableMotionBlur.pos = [10,294] 
			ckb_jitteredMotionBlur.pos = [155,294] 
			ckb_deformationMotionBlur.pos = [301,294] 
			spn_motionBlurSegments.pos = [195,316] 
			spn_blurShutter.pos = [415,316] 
			spn_matteMotionBlurSegments.pos = [195,336] 
			spn_blurBias.pos = [415,336] 
			chk_useMatteSegments.pos = [10,331] 
			btn_motionBlurPresets.pos = [208,315] 
			btn_matteMotionBlurSegmentsPreset.pos = [208,335] 
			btn_blurShutterPresets.pos = [428,315] 
			btn_blurBiasPresets.pos = [428,335] 
			chk_EnableAdaptiveMotionBlur.pos = [10,353] 
			ckb_disableCameraMotionBlur.pos = [230,353] 
			spn_AdaptiveMotionBlurSegmentLowerBound.pos = [195,375] 
			spn_AdaptiveMotionBlurSegmentUpperBound.pos = [415,375] 
			spn_AdaptiveMotionBlurSmoothness.pos = [195,395] 
			spn_AdaptiveMotionBlurExponent.pos = [415,395] 
			btn_AdaptiveMotionBlurSegmentLowerBoundPresets.pos = [208,374] 
			btn_AdaptiveMotionBlurSegmentUpperBoundPresets.pos = [428,374] 
			btn_AdaptiveMotionBlurSmoothnessPresets.pos = [208,394] 
			btn_AdaptiveMotionBlurExponentPresets.pos = [428,394] 
			lbl_dofplaceholder.pos = [228,405] 
			ckb_enableDepthOfField.pos = [8,423] 
			ckb_AllocateBokehBlendInfluence.pos = [142,423] 
			spn_depthOfFieldSampleRate.pos = [414,425] 
			btn_depthOfFieldPresets.pos = [427,424] 
			img_particleModebackground1.pos = [-22,450] 
			ddl_particleMode.pos = [4,454] 
			spn_GlobalParticlePercentage.pos = [417,457] 
			btn_GlobalPercentagePresets.pos = [430,456] 
			chk_Render_PFlowGeometry.pos = [3,478] 
			chk_Render_PFlowPhantom.pos = [73,478] 
			chk_Render_PFlowBBox.pos = [143,478] 
			chk_Render_MaxParticles.pos = [213,478] 
			chk_Render_ThinkingParticles.pos = [3,499] 
			chk_Render_FumeFX.pos = [73,499] 
			chk_Render_PhoenixFD.pos = [143,499] 
			chk_Render_GeometryVertices.pos = [213,499] 
			chk_Render_KrakatoaLoaders.pos = [3,520] 
			chk_Render_GeometryVolumes.pos = [73,520] 
			chk_Render_GeometrySurfaces.pos = [143,520] 
			chk_Render_PRTHair.pos = [213,520] 
			chk_Render_PRTMakers.pos = [3,541] 
			chk_Render_PRTSource.pos = [73,541] 
			chk_Render_PRTField.pos = [143,541] 
			chk_Render_Stoke.pos = [213,541] 
			btn_useParticlesFromPresets.pos = [283,478] 
			chk_iterativeRender.pos = [352,478] 
			btn_iterativeRenderSettings.pos = [432,478] 
			btn_quickRender.pos = [352,497] 
			btn_enableLightingCache.pos = [299,478] 
			prg_cacheStatus.pos = [300,515] 
			btn_enableParticleCache.pos = [299,523] 
			img_particleModebackground2.pos = [-19,563] 
			img_particleModebackground3.pos = [0,453] 
			img_particleModebackground4.pos = [453,453] 
			grp_overrides.pos = [3,566] 
			grp_post.pos = [227,566] 
			ckb_ignoreMissingParticles.pos = [6,580] 
			chb_multiThreadedLoading.pos = [119,580] 
			chk_SaveAttenuation.pos = [230,580] 
			btn_OpenShadowsExplorer.pos = [381,580] 
			chk_overrideColor.pos = [7,618] 
			chk_overrideEmission.pos = [118,618] 
			chk_overrideAbsorption.pos = [229,618] 
			chk_overrideDensity.pos = [340,618] 
			chk_matteObjects.pos = [7,637] 
			chk_matteObjectsLayers.pos = [118,637] 
			chk_useDepthMaps.pos = [229,637] 
			chk_APME.pos = [340,637] 
			btn_Tools_01.pos = [5,664] 
			btn_Tools_02.pos = [69,664] 
			btn_Tools_03.pos = [133,664] 
			btn_Tools_04.pos = [197,664] 
			btn_Tools_05.pos = [261,664] 
			btn_Tools_06.pos = [325,664] 
			btn_Tools_07.pos = [389,664] 				
		)catch()
	)

	fn updateIcons =
	(
		btn_LoadSave_Main.images = #(Krakatoa_PresetsArrowBitmap,Krakatoa_PresetsArrowBitmap, 32,3,3,3,3)		
		btn_Float_Rollout.images = #(Krakatoa_PresetsArrowBitmap,Krakatoa_PresetsArrowBitmap, 32,4,4,4,4)
		
		btn_VoxelSizePreset.images = #(Krakatoa_PresetsArrowBitmap,Krakatoa_PresetsArrowBitmap, 32,1,1,2,2)	
		btn_VoxelFilterRadiusPreset.images = #(Krakatoa_PresetsArrowBitmap,Krakatoa_PresetsArrowBitmap, 32,1,1,2,2)
		
		--btn_PhaseEccentricityPreset.images = #(Krakatoa_PresetsArrowBitmap,Krakatoa_PresetsArrowBitmap, 32,1,1,2,2)

		btn_shadowBilinearFilterPreset.images = #(Krakatoa_PresetsArrowBitmap,Krakatoa_PresetsArrowBitmap, 32,1,1,2,2)
		btn_drawBilinearFilterPreset.images = #(Krakatoa_PresetsArrowBitmap,Krakatoa_PresetsArrowBitmap, 32,1,1,2,2)
		
		btn_lightingDensityPreset.images = #(Krakatoa_PresetsArrowBitmap,Krakatoa_PresetsArrowBitmap, 32,1,1,2,2)
		btn_finalDensityPreset.images = #(Krakatoa_PresetsArrowBitmap,Krakatoa_PresetsArrowBitmap, 32,1,1,2,2)
		btn_emissionStrengthPreset.images = #(Krakatoa_PresetsArrowBitmap,Krakatoa_PresetsArrowBitmap, 32,1,1,2,2)
		btn_reflectionStrengthPreset.images = #(Krakatoa_PresetsArrowBitmap,Krakatoa_PresetsArrowBitmap, 32,1,1,2,2)
		
		btn_motionBlurPresets.images = #(Krakatoa_PresetsArrowBitmap,Krakatoa_PresetsArrowBitmap, 32,1,1,2,2)
		btn_matteMotionBlurSegmentsPreset.images = #(Krakatoa_PresetsArrowBitmap,Krakatoa_PresetsArrowBitmap, 32,1,1,2,2)
		btn_blurShutterPresets.images = #(Krakatoa_PresetsArrowBitmap,Krakatoa_PresetsArrowBitmap, 32,1,1,2,2)
		btn_blurBiasPresets.images = #(Krakatoa_PresetsArrowBitmap,Krakatoa_PresetsArrowBitmap, 32,1,1,2,2)

		btn_AdaptiveMotionBlurSmoothnessPresets.images = #(Krakatoa_PresetsArrowBitmap,Krakatoa_PresetsArrowBitmap, 32,1,1,2,2)
		btn_AdaptiveMotionBlurSegmentUpperBoundPresets.images = #(Krakatoa_PresetsArrowBitmap,Krakatoa_PresetsArrowBitmap, 32,1,1,2,2)
		btn_AdaptiveMotionBlurSegmentLowerBoundPresets.images = #(Krakatoa_PresetsArrowBitmap,Krakatoa_PresetsArrowBitmap, 32,1,1,2,2)
		btn_AdaptiveMotionBlurExponentPresets.images = #(Krakatoa_PresetsArrowBitmap,Krakatoa_PresetsArrowBitmap, 32,1,1,2,2)
		
		btn_depthOfFieldPresets.images = #(Krakatoa_PresetsArrowBitmap,Krakatoa_PresetsArrowBitmap, 32,1,1,2,2)
		
		btn_GlobalPercentagePresets.images = #(Krakatoa_PresetsArrowBitmap,Krakatoa_PresetsArrowBitmap, 32,1,1,2,2)
		btn_useParticlesFromPresets.images = #(Krakatoa_PresetsArrowBitmap,Krakatoa_PresetsArrowBitmap, 32,1,1,2,2)
		
		btn_iterativeRenderSettings.images = #(Krakatoa_PresetsArrowBitmap,Krakatoa_PresetsArrowBitmap, 32,1,1,2,2)
		
		
	)			
	
	--MAIN CONTROLS ROLLOUT REFRESH GUI
	fn refresh_GUI = 
	(
		tweakControlPositions() --NOTE: Remark this to disable control position enforcement
		
		img_particleModebackground1.bitmap = img_particleModebackground2.bitmap = img_particleModebackground3.bitmap = img_particleModebackground4.bitmap = case (FranticParticles.GetProperty "ParticleMode") of 
		(
			default : undefined
			"Save Particles To File Sequence": (bitmap 1 1 color:(color 255 150 150))
			"Light Scene Particles": (bitmap 1 1 color:(color 255 255 150))
			"Export To Krakatoa SR": (bitmap 1 1 color:(color 150 255 255))
		)	
		
		FranticParticleRenderMXS.SetDropDownValue ddl_particleMode (FranticParticles.GetProperty "ParticleMode")
		chk_iterativeRender.state = FranticParticles.GetBoolProperty "IterativeRender"

		local inParticleMode = (FranticParticles.GetProperty "RenderingMethod") == "Particle Rendering"
		local enableSaveParticleFileControls = (FranticParticles.GetProperty "ParticleMode") == "Save Particles To File Sequence"
		local inRenderParticlesMode = (FranticParticles.GetProperty "ParticleMode") == "Render Scene Particles"
		local inKrakatoaSRMode = matchPattern (FranticParticles.GetProperty "ParticleMode") pattern:"*Krakatoa SR*"


		local enableLightingControls = (FranticParticles.GetProperty "Density:DensityMethod") != "Additive Density"
		
		spn_VoxelSize.value = FranticParticles.GetFloatProperty "VoxelSize" 
		spn_VoxelFilterRadius.value = FranticParticles.GetFloatProperty "VoxelFilterRadius" 
		

		ckb_linkLightingAndRenderingDensity.checked = not (FranticParticles.GetBoolProperty "Density:LinkLightingAndRenderingDensity")
		ckb_relativeLightingDensity.checked = FranticParticles.GetBoolProperty "Density:RelativeLightingDensity"
		
		spn_densityPerParticle.value = FranticParticles.GetFloatProperty "Density:DensityPerParticle"
		spn_densityExponent.value = FranticParticles.GetIntProperty "Density:DensityExponent"
		edt_FinalDensityFullValue.text = formattedPrint (1.0d0 * spn_densityPerParticle.value  * (10.0^spn_densityExponent.value))
		
		if ckb_relativeLightingDensity.checked then
		(
			spn_lightingDensityPerParticle.value = FranticParticles.GetFloatProperty "Lighting:Density:RelativeDensityPerParticle"
			spn_lightingDensityExponent.value = FranticParticles.GetIntProperty "Lighting:Density:RelativeDensityExponent"	
			edt_LightingDensityFullValue.text = formattedPrint ( (1.0d0 * spn_densityPerParticle.value*(10.0^spn_densityExponent.value)) * (1.0d0 * spn_lightingDensityPerParticle.value * (10.0 ^ spn_lightingDensityExponent.value)) ) --format:"8.4g"
				
			local newLPD = spn_densityPerParticle.value*spn_lightingDensityPerParticle.value 
			local newLPDE =  spn_densityExponent.value + spn_lightingDensityExponent.value
			FranticParticles.SetProperty "Lighting:Density:DensityPerParticle" (newLPD as string)
			FranticParticles.SetProperty "Lighting:Density:DensityExponent" (newLPDE as string)
		)
		else
		(
			spn_lightingDensityPerParticle.value = FranticParticles.GetFloatProperty "Lighting:Density:DensityPerParticle"
			spn_lightingDensityExponent.value = FranticParticles.GetIntProperty "Lighting:Density:DensityExponent"
			edt_LightingDensityFullValue.text = formattedPrint (1.0d0 * spn_lightingDensityPerParticle.value  * (10.0^spn_lightingDensityExponent.value))
		)
		
		ckb_useEmissionStrength.checked = FranticParticles.GetBoolProperty "Emission:UseStrength"
		ckb_relativeEmissionStrength.checked = FranticParticles.GetBoolProperty "Emission:UseRelativeStrength"
		
		if ckb_relativeEmissionStrength.checked then
		(
			spn_emissionStrength.value = FranticParticles.GetFloatProperty "Emission:RelativeStrength"
			spn_emissionStrengthExponent.value = FranticParticles.GetIntProperty "Emission:RelativeStrengthExponent"	
			edt_emissionStrengthResultingValue.text = formattedPrint ( (1.0d0 * spn_densityPerParticle.value*(10.0^spn_densityExponent.value)) * (1.0d0 * spn_emissionStrength.value * (10.0 ^ spn_emissionStrengthExponent.value)) ) 
				
			local newES = spn_densityPerParticle.value*spn_emissionStrength.value 
			local newESE =  spn_densityExponent.value + spn_emissionStrengthExponent.value
			FranticParticles.SetProperty "Emission:Strength" (newES as string)
			FranticParticles.SetProperty "Emission:StrengthExponent" (newESE as string)
		)
		else
		(
			spn_emissionStrength.value = FranticParticles.GetFloatProperty "Emission:Strength"
			spn_emissionStrengthExponent.value = FranticParticles.GetIntProperty "Emission:StrengthExponent"
			edt_emissionStrengthResultingValue.text = formattedPrint (1.0d0 * spn_emissionStrength.value  * (10.0^spn_emissionStrengthExponent.value)) 
		)
			
			
		edt_emissionStrengthResultingValue.enabled = spn_emissionStrength.enabled = spn_emissionStrengthExponent.enabled = btn_emissionStrengthPreset.enabled = (FranticParticles.GetBoolProperty "Emission:UseStrength") AND (FranticParticles.GetBoolProperty "UseEmissionColor")
		ckb_relativeEmissionStrength.enabled = ckb_useEmissionStrength.enabled = (FranticParticles.GetBoolProperty "UseEmissionColor")
			
		ckb_enableMotionBlur.checked = FranticParticles.GetBoolProperty "EnableMotionBlur" 
		ckb_disableCameraMotionBlur.checked = FranticParticles.GetBoolProperty "DisableCameraMotionBlur" 
		
		ckb_jitteredMotionBlur.checked = FranticParticles.GetBoolProperty "JitteredMotionBlur"
		ckb_deformationMotionBlur.checked = FranticParticles.GetBoolProperty "DeformationMotionBlur"
		spn_motionBlurSegments.value = FranticParticles.GetFloatProperty "MotionBlurSegments"
		spn_matteMotionBlurSegments.value = FranticParticles.GetFloatProperty "MatteMotionBlurSegments"
		chk_useMatteSegments.checked = FranticParticles.GetBoolProperty "UseMatteMotionBlurSegments"
		spn_blurShutter.value = FranticParticles.GetFloatProperty "ShutterAngleInDegrees"
		spn_blurBias.value = FranticParticles.GetFloatProperty "ShutterBias"
		
		chk_EnableAdaptiveMotionBlur.state = FranticParticles.GetBoolProperty "EnableAdaptiveMotionBlur"
		spn_AdaptiveMotionBlurSmoothness.value = FranticParticles.GetFloatProperty "AdaptiveMotionBlurSmoothness"
		spn_AdaptiveMotionBlurExponent.value = FranticParticles.GetFloatProperty "AdaptiveMotionBlurExponent"
				
		spn_AdaptiveMotionBlurSegmentLowerBound.value = FranticParticles.GetFloatProperty "AdaptiveMotionBlurSegmentLowerBound"
		spn_AdaptiveMotionBlurSegmentUpperBound.value = FranticParticles.GetFloatProperty "AdaptiveMotionBlurSegmentUpperBound"
	
		spn_AdaptiveMotionBlurExponent.enabled = spn_AdaptiveMotionBlurSmoothness.enabled = spn_AdaptiveMotionBlurSegmentLowerBound.enabled = spn_AdaptiveMotionBlurSegmentUpperBound.enabled = chk_EnableAdaptiveMotionBlur.state AND ckb_enableMotionBlur.checked 
		btn_AdaptiveMotionBlurExponentPresets.enabled = btn_AdaptiveMotionBlurSmoothnessPresets.enabled = btn_AdaptiveMotionBlurSegmentUpperBoundPresets.enabled = btn_AdaptiveMotionBlurSegmentLowerBoundPresets.enabled = chk_EnableAdaptiveMotionBlur.state AND ckb_enableMotionBlur.checked 
		
		
		btn_matteMotionBlurSegmentsPreset.enabled = spn_matteMotionBlurSegments.enabled = chk_useMatteSegments.checked and ckb_enableMotionBlur.checked
		ckb_disableCameraMotionBlur.enabled = btn_blurShutterPresets.enabled = btn_motionBlurPresets.enabled = spn_blurShutter.enabled = ckb_deformationMotionBlur.enabled = chk_useMatteSegments.enabled = spn_motionBlurSegments.enabled = ckb_jitteredMotionBlur.enabled = ckb_enableMotionBlur.checked
		chk_EnableAdaptiveMotionBlur.enabled = ckb_enableMotionBlur.checked 
		btn_blurBiasPresets.enabled = spn_blurBias.enabled = true --should always be enabled because it affects particles even when MBlur is off.

		ckb_enableDepthOfField.checked = FranticParticles.GetBoolProperty "EnableDepthOfField" 
		spn_depthOfFieldSampleRate.value = FranticParticles.GetFloatProperty "DepthOfFieldSampleRate"
		ckb_AllocateBokehBlendInfluence.enabled = btn_depthOfFieldPresets.enabled = spn_depthOfFieldSampleRate.enabled = inParticleMode and ckb_enableDepthOfField.checked 
		ckb_AllocateBokehBlendInfluence.checked = FranticParticles.GetBoolProperty "Channel:Allocate:BokehBlendInfluence"
		
		chk_matteObjects.state = FranticParticles.GetBoolProperty "Matte:UseMatteObjects"
		chk_matteObjectsLayers.state = FranticParticles.GetBoolProperty "Matte:SaveMultipleLayers"
		chk_UseDepthMaps.state = FranticParticles.GetBoolProperty "Matte:UseDepthMapFiles"
		chk_APME.state = FranticParticles.GetBoolProperty "PME:UseExtinction"
		chk_SaveAttenuation.state = FranticParticles.GetBoolProperty "EnableAttenuationMapSaving"
		
		
		chk_overrideColor.state = FranticParticles.GetBoolProperty "ColorOverride:Enabled"
		chk_overrideEmission.state = FranticParticles.GetBoolProperty "EmissionOverride:Enabled"
		chk_overrideAbsorption.state = FranticParticles.GetBoolProperty "AbsorptionOverride:Enabled"
		chk_overrideDensity.state = FranticParticles.GetBoolProperty "DensityOverride:Enabled"
		
		FranticParticleRenderMXS.SetDropDownValue ddl_RenderingMethod (FranticParticles.GetProperty "RenderingMethod")
		
		try
		(
			bmp_RenderingMethod.bitmap = case ddl_RenderingMethod.selection of
			(
				default: bitmap 10 20 color:white
				2: bitmap 10 20 color:(color 100 100 255)
			)
		)catch()
		
		chk_Render_PFlowGeometry.state = FranticParticles.GetBoolProperty "RenderParticleFlowGeometry" 
		chk_Render_PFlowBBox.state = FranticParticles.GetBoolProperty "RenderParticleFlowBBox" 
		chk_Render_PFlowPhantom.state = FranticParticles.GetBoolProperty "RenderParticleFlowPhantom" 
		chk_Render_MaxParticles.state = FranticParticles.GetBoolProperty "RenderMaxParticles" 

		chk_Render_ThinkingParticles.state = FranticParticles.GetBoolProperty "RenderThinkingParticles" 
		chk_Render_FumeFX.state = FranticParticles.GetBoolProperty "RenderFumeFX" 
		chk_Render_PhoenixFD.state = FranticParticles.GetBoolProperty "RenderPhoenixFD" 
		chk_Render_GeometryVertices.state = FranticParticles.GetBoolProperty "RenderGeometryVertices" 
		
		
		chk_Render_KrakatoaLoaders.state = FranticParticles.GetBoolProperty "RenderKrakatoaLoaders" 
		chk_Render_GeometryVolumes.state = FranticParticles.GetBoolProperty "RenderGeometryVolumes" 
		chk_Render_GeometrySurfaces.state = FranticParticles.GetBoolProperty "RenderPRTSurface"
		chk_Render_PRTHair.state = FranticParticles.GetBoolProperty "RenderPRTHair" 

		chk_Render_PRTMakers.state = FranticParticles.GetBoolProperty "RenderPRTCreator"
		chk_Render_PRTSource.state = FranticParticles.GetBoolProperty "RenderPRTSource"
		chk_Render_PRTField.state = FranticParticles.GetBoolProperty "RenderPRTField"
		chk_Render_Stoke.state = FranticParticles.GetBoolProperty "RenderStoke"
		
		
		ckb_ignoreMissingParticles.state = FranticParticles.GetBoolProperty "IgnoreMissingParticles" 
		--chb_allowPRTLoaderOverwriting.state = FranticParticles.GetBoolProperty "AllowPRTLoaderOverwriting" 
		chb_multiThreadedLoading.state = FranticParticles.GetBoolProperty "Performance:MT:Loading"
		
		spn_GlobalParticlePercentage.value = (FranticParticles.GetFloatProperty "GlobalParticlePercentage") 
		
		ckb_IgnoreSceneLights.checked = (FranticParticles.GetBoolProperty "IgnoreSceneLights")

		ckb_useEnvironmentReflections.state = (FranticParticles.GetBoolProperty "UseEnvironmentReflections")
		ckb_allocateReflectionStrengthChannel.state = (FranticParticles.GetBoolProperty "Channel:Allocate:ReflectionStrength")

		ckb_useFilterColor.state = (FranticParticles.GetBoolProperty "UseFilterColor")
		ckb_useEmissionColor.state = (FranticParticles.GetBoolProperty "UseEmissionColor")
		
		local drawFilter = (FranticParticles.GetProperty "DrawPointFilter")
		ddl_drawPointFilter.selection = 2
		theFilterSize = 1
		btn_drawBilinearFilterPreset.enabled = spn_drawBilinearFilter.enabled = false
		if matchPattern drawFilter pattern:"Nearest*" do ddl_drawPointFilter.selection = 1
		if matchPattern drawFilter pattern:"Bicubic*" do ddl_drawPointFilter.selection = 3
		if matchPattern drawFilter pattern:"Bilinear*" do 
		(
			spn_drawBilinearFilter.value = 1
			if drawFilter.count > 8 do 
				theFilterSize = execute (substring drawFilter 9 -1)
			if superclassof theFilterSize != Number do theFilterSize = 1
			spn_drawBilinearFilter.value = theFilterSize
			btn_drawBilinearFilterPreset.enabled = spn_drawBilinearFilter.enabled = true
		)
		
		local shadowFilter = (FranticParticles.GetProperty "AttenuationLookupFilter")
		ddl_attenuationLookupFilter.selection = 3
		theFilterSize = 1
		btn_shadowBilinearFilterPreset.enabled = spn_shadowBilinearFilter.enabled = false
		if matchPattern shadowFilter pattern:"Nearest*" do ddl_attenuationLookupFilter.selection = 1
		if matchPattern shadowFilter pattern:"Bicubic*" do ddl_attenuationLookupFilter.selection = 3
		if matchPattern shadowFilter pattern:"Bilinear*" do 
		(
			ddl_attenuationLookupFilter.selection = 2
			spn_shadowBilinearFilter.value = 1
			if shadowFilter.count > 8 do 
				theFilterSize = execute (substring shadowFilter 9 -1)
			if superclassof theFilterSize != Number do theFilterSize = 1
			spn_shadowBilinearFilter.value = theFilterSize
			btn_shadowBilinearFilterPreset.enabled = spn_shadowBilinearFilter.enabled = not ckb_IgnoreSceneLights.checked AND inParticleMode 
		)			
		
		--Backwards Compatibility: If the file used Additive Density in earlier versions of Krakatoa, set AdditiveMode to true:
		if (FranticParticles.GetProperty "Density:DensityMethod") == "Additive Density" do (FranticParticles.SetProperty "AdditiveMode" "true")
		ckb_AdditiveMode.state = (FranticParticles.GetBoolProperty "AdditiveMode")
		ckb_useEmissionColor.enabled = ckb_useFilterColor.enabled = not ckb_AdditiveMode.state 
		
		spn_reflectionStrength.value = FranticParticles.GetFloatProperty "EnvironmentReflectionStrength"
		
		--ckb_allocateReflectionStrengthChannel.enabled = btn_reflectionStrengthPreset.enabled = spn_reflectionStrength.enabled = (ckb_useEnvironmentReflections.checked or ckb_useEmissionColor.checked)

		if enableSaveParticleFileControls then
		(
			btn_quickRender.caption = "SAVE PARTICLES"
			btn_quickRender.tooltip = "Click to Save Particles to a File Sequence. \n\nRight-click to open Render Context Menu."

			chk_iterativeRender.enabled = btn_iterativeRenderSettings.enabled = false
			chk_iterativeRender.checked = false
			FranticParticles.SetProperty "IterativeRender" "false"
			try(DaylightSimulationUtilities.SetRenderIterative false)catch()
		)	
		else
		(
			if inKrakatoaSRMode then
			(
				if chk_iterativeRender.checked then
				(
					btn_quickRender.caption = "EXPORT FRAME"
					btn_quickRender.tooltip = "Click to Export the current frame to Krakatoa SR. \n\nRight-click to open Render Context Menu."
				)
				else
				(
					btn_quickRender.caption = "EXPORT"
					btn_quickRender.tooltip = "Click to Export to Krakatoa SR. \n\nRight-click to open Render Context Menu."
				)
			)
			else
			(
				if chk_iterativeRender.checked then
				(
					btn_quickRender.caption = "RENDER FRAME"
					btn_quickRender.tooltip = "Click to Render Current Frame\nwithout saving image to disk. \n\nRight-click to open Render Context Menu."
				)
				else				
				(
					btn_quickRender.caption = "RENDER"
					btn_quickRender.tooltip = "Click to Render according to the \nRender Setup Dialog Time and Output settings. \n\nRight-click to open Render Context Menu."
				)
			)
			chk_iterativeRender.enabled = btn_iterativeRenderSettings.enabled = true
		)
		
		
		btn_enableParticleCache.enabled = not enableSaveParticleFileControls  
		btn_enableLightingCache.enabled = not enableSaveParticleFileControls and not ckb_IgnoreSceneLights.checked
		btn_enableParticleCache.state = FranticParticles.GetBoolProperty "EnableParticleCache" 
		btn_enableLightingCache.state = FranticParticles.GetBoolProperty "EnableLightingCache" 

		--refreshCacheStatus()

		FranticParticleRenderMXS.SetDropDownValue ddl_shadingMode (FranticParticles.GetProperty "PhaseFunction")
		
		try
		(
			bmp_shadingMode.bitmap = case ddl_shadingMode.selection of
			(
				default: bitmap 10 20 color:white
				2: bitmap 10 20 color:(color 100 100 255)
				3: bitmap 10 20 color:(color 255 200 100)
				4: bitmap 10 20 color:(color 100 255 100)
				5: bitmap 10 20 color:(color 100 200 250)
				6: bitmap 10 20 color:(color 200 50 255)
			)
		)catch()
		
		ddl_attenuationLookupFilter.enabled = not ckb_IgnoreSceneLights.checked AND inParticleMode 
		ddl_drawPointFilter.enabled = inParticleMode 
		
		edt_LightingDensityFullValue.enabled = ckb_relativeLightingDensity.enabled = btn_lightingDensityPreset.enabled = spn_LightingDensityPerParticle.enabled = spn_LightingDensityExponent.enabled = ckb_linkLightingAndRenderingDensity.checked AND not ckb_IgnoreSceneLights.checked 
		--btn_lightingDensityPreset.visible = spn_LightingDensityPerParticle.visible = spn_LightingDensityExponent.visible = not ckb_relativeLightingDensity.checked
		--spn_LightingDensityPerParticleRelative.visible = ckb_relativeLightingDensity.checked
		btn_VoxelSizePreset.enabled = spn_VoxelSize.enabled = spn_VoxelFilterRadius.enabled = btn_VoxelFilterRadiusPreset.enabled = (FranticParticles.GetProperty "RenderingMethod") != "Particle Rendering" AND inRenderParticlesMode
		ckb_linkLightingAndRenderingDensity.enabled = not ckb_IgnoreSceneLights.checked 
		
		if Krakatoa_GUI_Partition.open do Krakatoa_GUI_Partition.refresh_GUI()
		refreshCacheStatus()
		update2009VFBControls()
		updateIterativeRenderText()
		try(Krakatoa_updateSchematicFlow())catch()
		
		if Krakatoa_Initializing_Hidden_Rollouts == false do 
			try(Krakatoa_GUI_Main.open = FranticParticles.GetBoolProperty "GUI:MainControlsRolloutOpen")catch()

	)
	

	on chk_SaveAttenuation rightclick do FranticParticleRenderMXS.createDefaultsRCMenu "EnableAttenuationMapSaving" ">Save Attenuation Maps"
	
	
	on chk_matteObjects changed state do 
	(
		FranticParticles.SetProperty "Matte:UseMatteObjects" (state as string)
		try(Krakatoa_GUI_MatteObjects.refresh_GUI())catch()
		update2009VFBControls()
		try(Krakatoa_updateSchematicFlow())catch()
	)
	
	on chk_matteObjectsLayers changed state do
	(
		FranticParticles.SetProperty "Matte:SaveMultipleLayers" (state as string)
		if state do 
			FranticParticleRenderMXS.addRenderElement "OccludedLayer" ""
		FranticParticleRenderMXS.toggleRenderElementByClass Krakatoa_OccludedLayer state			
		
		try(Krakatoa_GUI_MatteObjects.refresh_GUI())catch()
		update2009VFBControls()
		try(Krakatoa_updateSchematicFlow())catch()
	)	
	on chk_UseDepthMaps changed state do
	(
		FranticParticles.SetProperty "Matte:UseDepthMapFiles" (state as string)
		try(Krakatoa_GUI_MatteObjects.refresh_GUI())catch()
		update2009VFBControls()
		try(Krakatoa_updateSchematicFlow())catch()
	)		
	
	
	on chk_APME changed state do 
	(
		FranticParticles.SetProperty "PME:UseExtinction" (state as string)
		try(Krakatoa_GUI_AmbientPME.refresh_GUI())catch()
		update2009VFBControls()
		try(Krakatoa_updateSchematicFlow())catch()
	)
	on chk_SaveAttenuation changed state do 
	(
		FranticParticles.SetProperty "EnableAttenuationMapSaving"	(state as string)
		--try(Krakatoa_GUI_Shadows.refresh_GUI())catch()
		update2009VFBControls()
		try(Krakatoa_updateSchematicFlow())catch()
	)	
	
	on chk_overrideColor changed state do 
	(
		FranticParticles.SetProperty "ColorOverride:Enabled"	(state as string)
		try(Krakatoa_GUI_RenderGlobalValues.refresh_GUI())catch()
		update2009VFBControls side:#left
	)		
	
	on chk_overrideEmission changed state do 
	(
		FranticParticles.SetProperty "EmissionOverride:Enabled"	(state as string)
		try(Krakatoa_GUI_RenderGlobalValues.refresh_GUI())catch()
		update2009VFBControls side:#left
	)		
	
	on chk_overrideAbsorption changed state do 
	(
		FranticParticles.SetProperty "AbsorptionOverride:Enabled"	(state as string)
		try(Krakatoa_GUI_RenderGlobalValues.refresh_GUI())catch()
		update2009VFBControls side:#left
	)	

	on chk_overrideDensity changed state do 
	(
		FranticParticles.SetProperty "DensityOverride:Enabled"	(state as string)
		try(Krakatoa_GUI_RenderGlobalValues.refresh_GUI())catch()
		update2009VFBControls side:#left
	)		
	
	on btn_GoTo_01 pressed do FranticParticleRenderMXS.navigateToKrakatoaRollout Krakatoa_CustomizeRollouts_Dialog
	on btn_GoTo_02 pressed do FranticParticleRenderMXS.navigateToKrakatoaRollout Krakatoa_GUI_Presets	
	on btn_GoTo_03  pressed do FranticParticleRenderMXS.navigateToKrakatoaRollout Krakatoa_GUI_RenderGlobalValues
	on btn_GoTo_04 pressed do FranticParticleRenderMXS.navigateToKrakatoaRollout Krakatoa_GUI_Channels
	on btn_GoTo_05 pressed do FranticParticleRenderMXS.navigateToKrakatoaRollout Krakatoa_GUI_Partition

	on btn_GoTo_01 rightclick do FranticParticleRenderMXS.navigateToKrakatoaRollout Krakatoa_CustomizeRollouts_Dialog	
	on btn_GoTo_02 rightclick do FranticParticleRenderMXS.navigateToKrakatoaRollout Krakatoa_GUI_Presets	
	on btn_GoTo_03 rightclick do FranticParticleRenderMXS.navigateToKrakatoaRollout Krakatoa_GUI_RenderGlobalValues
	on btn_GoTo_04 rightclick do FranticParticleRenderMXS.navigateToKrakatoaRollout Krakatoa_GUI_Channels	
	on btn_GoTo_05 rightclick do FranticParticleRenderMXS.navigateToKrakatoaRollout Krakatoa_GUI_Partition	
	
	on chk_matteObjects rightclick do FranticParticleRenderMXS.navigateToKrakatoaRollout Krakatoa_GUI_MatteObjects
	on chk_matteObjectsLayers rightclick do FranticParticleRenderMXS.navigateToKrakatoaRollout Krakatoa_GUI_MatteObjects
	on chk_useDepthMaps rightclick do FranticParticleRenderMXS.navigateToKrakatoaRollout Krakatoa_GUI_MatteObjects	
	--on chk_DepthMapFiles rightclick do FranticParticleRenderMXS.navigateToKrakatoaRollout Krakatoa_GUI_MatteObjects
	on chk_APME rightclick do FranticParticleRenderMXS.navigateToKrakatoaRollout Krakatoa_GUI_AmbientPME
		
	on chk_overrideColor rightclick do FranticParticleRenderMXS.navigateToKrakatoaRollout Krakatoa_GUI_RenderGlobalValues	
	on chk_overrideEmission rightclick do FranticParticleRenderMXS.navigateToKrakatoaRollout Krakatoa_GUI_RenderGlobalValues	
	on chk_overrideAbsorption rightclick do FranticParticleRenderMXS.navigateToKrakatoaRollout Krakatoa_GUI_RenderGlobalValues	
	on chk_overrideDensity rightclick do FranticParticleRenderMXS.navigateToKrakatoaRollout Krakatoa_GUI_RenderGlobalValues	
		
	fn ddl_shadingMode_SelectedFN itm =
	(
		FranticParticles.SetProperty "PhaseFunction" ddl_shadingMode.selected
		FranticParticleRenderMXS.defineShaderRollout (FranticParticles.GetProperty "PhaseFunction")
		Krakatoa_GUI_Channels.updateMemChannels()
		update2009VFBControls  side:#left
	)
	
	on ddl_shadingMode selected itm do
	(
		ddl_shadingMode_SelectedFN itm
		refresh_GUI()
	)

	on ckb_useEnvironmentReflections changed state do
	(
		FranticParticles.SetProperty "UseEnvironmentReflections" (state as string)
		Krakatoa_GUI_Channels.updateMemChannels()
		update2009VFBControls side:#left
		refreshCacheStatus()
		--ckb_allocateReflectionStrengthChannel.enabled = btn_reflectionStrengthPreset.enabled = spn_reflectionStrength.enabled = (ckb_useEnvironmentReflections.checked or ckb_useEmissionColor.checked)
		try(Krakatoa_updateSchematicFlow())catch()
	)
	
	on spn_reflectionStrength changed val do
	(
		FranticParticles.SetProperty "EnvironmentReflectionStrength" (val as string)
		update2009VFBControls side:#left
	)
	
	on ckb_allocateReflectionStrengthChannel changed state do
	(
		FranticParticles.SetProperty "Channel:Allocate:ReflectionStrength" (state as string)
		refreshCacheStatus()
		Krakatoa_GUI_Channels.updateMemChannels()
		update2009VFBControls side:#left
		try(Krakatoa_updateSchematicFlow())catch()
	)
	
	
	on ckb_useEnvironmentReflections rightClick do 
		FranticParticleRenderMXS.createDefaultsRCMenu "UseEnvironmentReflections" ">Use Environment Reflections"

	on ckb_allocateReflectionStrengthChannel rightClick do 
		FranticParticleRenderMXS.createDefaultsRCMenu "Channel:Allocate:ReflectionStrength" ">Allocate ReflectionStrength"

	
	on chk_iterativeRender changed state do 
	(
		FranticParticles.SetProperty "IterativeRender" (state as string)
		try(DaylightSimulationUtilities.SetRenderIterative state)catch()
		refresh_GUI()
		update2009VFBControls side:#right
	)	

	
	on chk_iterativeRender rightClick do popupMenu Krakatoa_RCMenu_Struct.IterativeOptions_RCMenu pos:mouse.screenpos	
	on btn_iterativeRenderSettings pressed do popupMenu Krakatoa_RCMenu_Struct.IterativeOptions_RCMenu pos:mouse.screenpos
	on btn_iterativeRenderSettings rightClick do popupMenu Krakatoa_RCMenu_Struct.IterativeOptions_RCMenu pos:mouse.screenpos
		
	on ckb_ignoreMissingParticles changed state do
	(
		FranticParticles.SetProperty "IgnoreMissingParticles" (state as string)
	)	
	on chb_multiThreadedLoading changed state do 
	(
		FranticParticles.SetProperty "Performance:MT:Loading" (state as string)
	)

	on chb_allowPRTLoaderOverwriting changed state do
	(
		FranticParticles.SetProperty "AllowPRTLoaderOverwriting" (state as string)
	)
	
	on btn_enableLightingCache changed state do
	(
		if not state then 
		(
			--try(FranticParticles.InvalidateLightingCache())catch()
			FranticParticles.SetProperty "EnableLightingCache" false
			FranticParticles.LogProgress "+Lighting Cache Disabled."
			refresh_GUI()
		)
		else	
		(
			FranticParticles.SetProperty "EnableLightingCache" true
			FranticParticles.LogProgress "+Lighting Cache Enabled."
			btn_enableParticleCache.changed (btn_enableParticleCache.state = true)
		)	
		update2009VFBControls side:#right
	)
	
	on btn_enableParticleCache changed state do
	(
		if not state then 
		(
			if not FranticParticles.getBoolProperty "CacheLastFrame" do 
				try(FranticParticles.InvalidateParticleCache())catch()
			FranticParticles.SetProperty "EnableParticleCache" false
			FranticParticles.LogProgress "+Particle Cache Disabled."
			btn_enableLightingCache.changed (btn_enableLightingCache.state = false)
		)
		else	
		(
			FranticParticles.SetProperty "EnableParticleCache" true
			FranticParticles.LogProgress "+Particle Cache Enabled."
		)	
		refresh_GUI()
		update2009VFBControls side:#right
	)
	
	fn showCacheSize = 
	(
		local theCount = try((FranticParticles.GetCachedParticleCount()) as string)catch("???")
		local theMemory = try((FranticParticles.getCacheSize()) as string)catch("???")
		Krakatoa_RCMenu_Struct.ParticleCache_RCMenu.mnu_cacheSize.text =  "In Memory: "+ FranticParticleRenderMXS.addCommas theCount +" Particles using " + theMemory  + " MB"
		popupmenu Krakatoa_RCMenu_Struct.ParticleCache_RCMenu position:mouse.ScreenPos 			
	)
	
	on btn_enableParticleCache rightclick do showCacheSize()
	on btn_enableLightingCache rightclick do showCacheSize()
	
	on btn_quickRender rightclick do 
	(
		if renderSceneDialog.isOpen() do renderSceneDialog.commit()
		Krakatoa_RCMenu_Struct.RenderButton_RCMenu.mnu_singleFrame.text = "Single Frame [" + (currentTime.frame as integer) as string + "]"
		Krakatoa_RCMenu_Struct.RenderButton_RCMenu.mnu_activeSegment.text = "Active Segment [" + (animationrange.start.frame as integer) as string + "-" + (animationrange.end.frame as integer) as string + "] Nth: " + rendNthFrame as string
		Krakatoa_RCMenu_Struct.RenderButton_RCMenu.mnu_customRange.text = "Custom Range [" + (rendStart.frame as integer) as string + "-" + (rendEnd .frame as integer) as string + "] Nth: " + rendNthFrame as string
		Krakatoa_RCMenu_Struct.RenderButton_RCMenu.mnu_CustomFrames.text = "Custom Frames ["  + rendPickupFrames + "] Nth: " + rendNthFrame as string
		popupmenu Krakatoa_RCMenu_Struct.RenderButton_RCMenu position:mouse.ScreenPos 
	)	

	on chk_Render_PFlowGeometry changed state do 
	(
		FranticParticles.SetProperty "RenderParticleFlowGeometry" (state as string)
		refreshCacheStatus()
		try(Krakatoa_GUI_Particles.refresh_GUI())catch()
		update2009VFBControls side:#right
		try(Krakatoa_updateSchematicFlow())catch()
	)	
	on chk_Render_PFlowGeometry rightClick do 
		FranticParticleRenderMXS.createDefaultsRCMenu "RenderParticleFlowGeometry" ">PFlow Geometry"
	
	on chk_Render_PFlowBBox changed state do 
	(
		FranticParticles.SetProperty "RenderParticleFlowBBox" (state as string)
		refreshCacheStatus()
		try(Krakatoa_GUI_Particles.refresh_GUI())catch()
		update2009VFBControls side:#right
		try(Krakatoa_updateSchematicFlow())catch()
	)	
	on chk_Render_PFlowBBox rightClick do 
		FranticParticleRenderMXS.createDefaultsRCMenu "RenderParticleFlowBBox" ">PFlow BBox"
	
	on chk_Render_PFlowPhantom changed state do 
	(
		FranticParticles.SetProperty "RenderParticleFlowPhantom" (state as string)
		refreshCacheStatus()
		try(Krakatoa_GUI_Particles.refresh_GUI())catch()
		update2009VFBControls side:#right
		try(Krakatoa_updateSchematicFlow())catch()
	)	
	on chk_Render_PFlowPhantom rightClick do 
		FranticParticleRenderMXS.createDefaultsRCMenu "RenderParticleFlowPhantom" ">PFlow Phantom"
	
	on chk_Render_FumeFX changed state do 
	(
		FranticParticles.SetProperty "RenderFumeFX" (state as string)
		refreshCacheStatus()
		try(Krakatoa_GUI_Particles.refresh_GUI())catch()
		update2009VFBControls side:#right
		try(Krakatoa_updateSchematicFlow())catch()
	)	
	on chk_Render_FumeFX rightClick do 
		FranticParticleRenderMXS.createDefaultsRCMenu "RenderFumeFX" ">FumeFX"
	
	on chk_Render_PRTHair changed state do 
	(
		FranticParticles.SetProperty "RenderPRTHair" (state as string)
		refreshCacheStatus()
		try(Krakatoa_GUI_Particles.refresh_GUI())catch()
		update2009VFBControls side:#right
		try(Krakatoa_updateSchematicFlow())catch()
	)	
	on chk_Render_PRTHair rightClick do 
		FranticParticleRenderMXS.createDefaultsRCMenu "RenderPRTHair" ">PRT Hair"	
	
	on chk_Render_PRTMakers changed state do 
	(
		FranticParticles.SetProperty "RenderPRTCreator" (state as string)
		refreshCacheStatus()
		try(Krakatoa_GUI_Particles.refresh_GUI())catch()
		update2009VFBControls side:#right
		try(Krakatoa_updateSchematicFlow())catch()
	)	
	on chk_Render_PRTMakers rightClick do 
		FranticParticleRenderMXS.createDefaultsRCMenu "RenderPRTCreator" ">PRT Maker"	

	on chk_Render_PRTSource changed state do 
	(
		FranticParticles.SetProperty "RenderPRTSource" (state as string)
		refreshCacheStatus()
		try(Krakatoa_GUI_Particles.refresh_GUI())catch()
		update2009VFBControls side:#right
		try(Krakatoa_updateSchematicFlow())catch()
	)	
	on chk_Render_PRTSource rightClick do 
		FranticParticleRenderMXS.createDefaultsRCMenu "RenderPRTSource" ">PRT Source"	
	
	
	on chk_Render_MaxParticles changed state do 
	(
		FranticParticles.SetProperty "RenderMaxParticles" (state as string)
		refreshCacheStatus()
		try(Krakatoa_GUI_Particles.refresh_GUI())catch()
		update2009VFBControls side:#right
		try(Krakatoa_updateSchematicFlow())catch()
	)	
	on chk_Render_MaxParticles rightClick do 
		FranticParticleRenderMXS.createDefaultsRCMenu "RenderMaxParticles" ">Legacy Particles"
	
	on chk_Render_ThinkingParticles changed state do 
	(
		FranticParticles.SetProperty "RenderThinkingParticles" (state as string)
		refreshCacheStatus()
		try(Krakatoa_GUI_Particles.refresh_GUI())catch()
		update2009VFBControls side:#right
		try(Krakatoa_updateSchematicFlow())catch()
	)	
	on chk_Render_ThinkingParticles rightClick do 
		FranticParticleRenderMXS.createDefaultsRCMenu "RenderThinkingParticles" ">ThinkingParticles"
	
	on chk_Render_GeometryVertices changed state do 
	(
		FranticParticles.SetProperty "RenderGeometryVertices" (state as string)
		refreshCacheStatus()
		try(Krakatoa_GUI_Particles.refresh_GUI())catch()
		update2009VFBControls side:#right
		try(Krakatoa_updateSchematicFlow())catch()
	)	
	on chk_Render_GeometryVertices rightClick do 
		FranticParticleRenderMXS.createDefaultsRCMenu "RenderGeometryVertices" ">Geometry Vertices"
	
	on chk_Render_KrakatoaLoaders changed state do 
	(
		FranticParticles.SetProperty "RenderKrakatoaLoaders" (state as string)
		refreshCacheStatus()
		try(Krakatoa_GUI_Particles.refresh_GUI())catch()
		update2009VFBControls side:#right
		try(Krakatoa_updateSchematicFlow())catch()
	)	
	on chk_Render_KrakatoaLoaders rightClick do 
		FranticParticleRenderMXS.createDefaultsRCMenu "RenderKrakatoaLoaders" ">PRT Loaders"
	
	on chk_Render_GeometryVolumes changed state do 
	(
		FranticParticles.SetProperty "RenderGeometryVolumes" (state as string)
		refreshCacheStatus()
		try(Krakatoa_GUI_Particles.refresh_GUI())catch()
		update2009VFBControls side:#right
		try(Krakatoa_updateSchematicFlow())catch()
	)	
	on chk_Render_GeometryVolumes rightClick do 
		FranticParticleRenderMXS.createDefaultsRCMenu "RenderGeometryVolumes" ">PRT Volumes"

	on chk_Render_GeometrySurfaces changed state do 
	(
		FranticParticles.SetProperty "RenderPRTSurface" (state as string)
		refreshCacheStatus()
		try(Krakatoa_GUI_Particles.refresh_GUI())catch()
		update2009VFBControls side:#right
		try(Krakatoa_updateSchematicFlow())catch()
	)	
	on chk_Render_GeometrySurfaces rightClick do 
		FranticParticleRenderMXS.createDefaultsRCMenu "RenderPRTSurface" ">PRT Surfaces"	
	
	on chk_Render_PRTField changed state do 
	(
		FranticParticles.SetProperty "RenderPRTField" (state as string)
		refreshCacheStatus()
		try(Krakatoa_GUI_Particles.refresh_GUI())catch()
		update2009VFBControls side:#right
		try(Krakatoa_updateSchematicFlow())catch()
	)	
	on chk_Render_PRTField rightClick do 
		FranticParticleRenderMXS.createDefaultsRCMenu "RenderPRTField" ">PRT Field"		
	
	on chk_Render_PhoenixFD changed state do 
	(
		FranticParticles.SetProperty "RenderPhoenixFD" (state as string)
		refreshCacheStatus()
		try(Krakatoa_GUI_Particles.refresh_GUI())catch()
		update2009VFBControls side:#right
		try(Krakatoa_updateSchematicFlow())catch()
	)	
	on chk_Render_PhoenixFD rightClick do 
		FranticParticleRenderMXS.createDefaultsRCMenu "RenderPhoenixFD" ">Phoenix"		
	
	on chk_Render_Stoke changed state do 
	(
		FranticParticles.SetProperty "RenderStoke" (state as string)
		refreshCacheStatus()
		try(Krakatoa_GUI_Particles.refresh_GUI())catch()
		update2009VFBControls side:#right
		try(Krakatoa_updateSchematicFlow())catch()
	)	
	on chk_Render_Stoke rightClick do 
		FranticParticleRenderMXS.createDefaultsRCMenu "RenderStoke" ">Stoke"			
	
	on spn_VoxelSize changed value do
	(
		FranticParticles.SetProperty "VoxelSize" (value as string)
		update2009VFBControls side:#left
	)
	
	on spn_VoxelFilterRadius changed value do
	(
		FranticParticles.SetProperty "VoxelFilterRadius" (value as string)
		update2009VFBControls side:#left
	)


/*
	fn ddl_densityMethod_SelectedFN val = 
	(
		FranticParticles.SetProperty "Density:DensityMethod" ddl_densityMethod.text
		update2009VFBControls side:#left
	)
	on ddl_densityMethod selected val do 
	(
		ddl_densityMethod_SelectedFN val
		refresh_GUI()
	)	
*/	
	fn ddl_RenderingMethod_SelectedFN val =
	(
		FranticParticles.SetProperty "RenderingMethod" ddl_RenderingMethod.text
		refresh_GUI()
		Krakatoa_GUI_Channels.updateMemChannels()
		update2009VFBControls side:#left
	)
	on ddl_RenderingMethod selected val do ddl_RenderingMethod_SelectedFN val		
	
	on spn_densityPerParticle changed val do 
	(
		FranticParticles.SetProperty "Density:DensityPerParticle" (val as string)
		refresh_GUI()
		update2009VFBControls side:#left
	)	
	on spn_densityExponent changed val do 
	(
		FranticParticles.SetProperty "Density:DensityExponent" (val as string)
		refresh_GUI()
		update2009VFBControls side:#left
	)	
	
	on spn_lightingDensityPerParticle changed val do 
	(
		if ckb_relativeLightingDensity.checked then
			FranticParticles.SetProperty "Lighting:Density:RelativeDensityPerParticle" (val as string)
		else
			FranticParticles.SetProperty "Lighting:Density:DensityPerParticle" (val as string)
		refresh_GUI()
		update2009VFBControls side:#left
	)	
	on spn_lightingDensityExponent changed val do 
	(
		if ckb_relativeLightingDensity.checked then
			FranticParticles.SetProperty "Lighting:Density:RelativeDensityExponent" (val as string)
		else
			FranticParticles.SetProperty "Lighting:Density:DensityExponent" (val as string)
		refresh_GUI()
		update2009VFBControls side:#left
	)	
	
	on spn_EmissionStrength changed val do 
	(
		if ckb_relativeEmissionStrength.checked then
			FranticParticles.SetProperty "Emission:RelativeStrength" (val as string)
		else
			FranticParticles.SetProperty "Emission:Strength" (val as string)
		refresh_GUI()
		update2009VFBControls side:#left
	)	
	on spn_EmissionStrengthExponent changed val do 
	(
		if ckb_relativeEmissionStrength.checked then
			FranticParticles.SetProperty "Emission:RelativeStrengthExponent" (val as string)
		else
			FranticParticles.SetProperty "Emission:StrengthExponent" (val as string)
		refresh_GUI()
		update2009VFBControls side:#left
	)		
	

	on ckb_enableMotionBlur changed val do 
	(
		FranticParticles.SetProperty "EnableMotionBlur" (val as string)
		refresh_GUI()
		Krakatoa_GUI_Channels.updateMemChannels()
		try(Krakatoa_GUI_ParticleLoaders.updateLoadersList())catch()
		--refreshCacheStatus()
		--update2009VFBControls side:#right
		--try(Krakatoa_updateSchematicFlow())catch()
	)
	on ckb_enableMotionBlur rightClick do 
		FranticParticleRenderMXS.createDefaultsRCMenu "EnableMotionBlur" ">Enable Motion Blur"
	
	on ckb_disableCameraMotionBlur changed val do 
	(
		FranticParticles.SetProperty "DisableCameraMotionBlur" (val as string)
		refresh_GUI()
	)
	on ckb_disableCameraMotionBlur rightClick do 
		FranticParticleRenderMXS.createDefaultsRCMenu "DisableCameraMotionBlur" ">Disable Blur From Camera Motion"
	
	on ckb_enableDepthOfField changed val do 
	(
		FranticParticles.SetProperty "EnableDepthOfField" (val as string)
		refresh_GUI()
		--update2009VFBControls side:#right
		--try(Krakatoa_updateSchematicFlow())catch()
	)	
	on ckb_enableDepthOfField rightClick do 
		FranticParticleRenderMXS.createDefaultsRCMenu "EnableDepthOfField" ">Enable Depth Of Field"
	
	on ckb_AllocateBokehBlendInfluence changed val do
	(
		FranticParticles.SetProperty "Channel:Allocate:BokehBlendInfluence" (val as string)
		refresh_GUI()		
	)
	on ckb_AllocateBokehBlendInfluence rightClick do 
		FranticParticleRenderMXS.createDefaultsRCMenu "Channel:Allocate:BokehBlendInfluence" ">Allocate BokehBlendInfluence"
	
	
	on ckb_jitteredMotionBlur changed val do 
	(
		FranticParticles.SetProperty "JitteredMotionBlur" (val as string)
		Krakatoa_GUI_Channels.updateMemChannels()
		try(Krakatoa_GUI_ParticleLoaders.updateLoadersList())catch()
		refreshCacheStatus()
		update2009VFBControls side:#right
		try(Krakatoa_updateSchematicFlow())catch()
	)	
	
	on ckb_jitteredMotionBlur rightClick do 
		FranticParticleRenderMXS.createDefaultsRCMenu "JitteredMotionBlur" ">Jittered Motion Blur"
	
	on ckb_deformationMotionBlur changed val do 
	(
		FranticParticles.SetProperty "DeformationMotionBlur" (val as string)
		update2009VFBControls side:#right
		try(Krakatoa_updateSchematicFlow())catch()
	)	
		
	on ckb_deformationMotionBlur rightClick do 
		FranticParticleRenderMXS.createDefaultsRCMenu "DeformationMotionBlur" ">Deformation Motion Blur"
	
	on chk_useMatteSegments changed val do 
	(
		FranticParticles.SetProperty "UseMatteMotionBlurSegments" (val as string)
		btn_matteMotionBlurSegmentsPreset.enabled = spn_matteMotionBlurSegments.enabled = val
		
		update2009VFBControls side:#right
		try(Krakatoa_updateSchematicFlow())catch()
	)	
		
	on chk_useMatteSegments rightClick do 
		FranticParticleRenderMXS.createDefaultsRCMenu "UseMatteMotionBlurSegments" ">Use Matte Motion Blur Segments"	
	
	
	on spn_motionBlurSegments changed val do 
	(
		FranticParticles.SetProperty "MotionBlurSegments" (val as string)
		update2009VFBControls side:#right
		try(Krakatoa_updateSchematicFlow())catch()
	)
	
	on spn_matteMotionBlurSegments changed val do
	(
		FranticParticles.SetProperty "MatteMotionBlurSegments" (val as string)
		update2009VFBControls side:#right
		try(Krakatoa_updateSchematicFlow())catch()
	)
	
	on spn_depthOfFieldSampleRate changed val do 
	(
		FranticParticles.SetProperty "DepthOfFieldSampleRate" (val as string)
		update2009VFBControls side:#right
		try(Krakatoa_updateSchematicFlow())catch()
	)
	
	on spn_blurShutter changed val do 
	(
		FranticParticles.SetProperty "ShutterAngleInDegrees" (val  as string)
		update2009VFBControls side:#right
		try(Krakatoa_updateSchematicFlow())catch()
	)	
	on spn_blurBias changed val do 
	(
		FranticParticles.SetProperty "ShutterBias" (val as string)
		update2009VFBControls side:#right
		try(Krakatoa_updateSchematicFlow())catch()
	)

	on chk_EnableAdaptiveMotionBlur changed state do 
	(
		FranticParticles.SetProperty "EnableAdaptiveMotionBlur" (state as string)
		spn_AdaptiveMotionBlurExponent.enabled = spn_AdaptiveMotionBlurSmoothness.enabled = spn_AdaptiveMotionBlurSegmentLowerBound.enabled = spn_AdaptiveMotionBlurSegmentUpperBound.enabled = state
		btn_AdaptiveMotionBlurExponentPresets.enabled = btn_AdaptiveMotionBlurSmoothnessPresets.enabled = btn_AdaptiveMotionBlurSegmentUpperBoundPresets.enabled = btn_AdaptiveMotionBlurSegmentLowerBoundPresets.enabled = state
		update2009VFBControls side:#right
	)
	on spn_AdaptiveMotionBlurSmoothness changed val do 
	(
		FranticParticles.SetProperty "AdaptiveMotionBlurSmoothness" (val as string)
		update2009VFBControls side:#right
	)
	on spn_AdaptiveMotionBlurExponent changed val do
	(
		FranticParticles.SetProperty "AdaptiveMotionBlurExponent" (val as string)
		update2009VFBControls side:#right			
	)
	on spn_AdaptiveMotionBlurSegmentLowerBound changed val do 
	(
		FranticParticles.SetProperty "AdaptiveMotionBlurSegmentLowerBound" (val as string)
		if val > spn_AdaptiveMotionBlurSegmentUpperBound.value do spn_AdaptiveMotionBlurSegmentUpperBound.changed (spn_AdaptiveMotionBlurSegmentUpperBound.value = val)
		update2009VFBControls side:#right
	)
	on spn_AdaptiveMotionBlurSegmentUpperBound changed val do 
	(
		FranticParticles.SetProperty "AdaptiveMotionBlurSegmentUpperBound" (val as string)		
		if val < spn_AdaptiveMotionBlurSegmentLowerBound.value do spn_AdaptiveMotionBlurSegmentLowerBound.changed (spn_AdaptiveMotionBlurSegmentLowerBound.value = val)
		update2009VFBControls side:#right
	)
	
	
	
	fn ddl_particleMode_SelectedFN val =
	(
		FranticParticles.SetProperty "ParticleMode" ddl_particleMode.text
		Krakatoa_GUI_SaveParticles.open = val == 2
		
		--THIS IS A USER PREFERENCE
		local thePref = (getIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "Preferences" "SaveModeTogglePartitionsRollout")
		case thePref of
		(
			default: Krakatoa_GUI_Partition.open = val == 2 --open if Save mode, close if Render or Light Mode
			"2": if val == 1 or val == 2 do Krakatoa_GUI_Partition.open = false --close if Render or Light mode
			"3": if val == 2 do Krakatoa_GUI_Partition.open = true --open if Save mode
			"4": ( )  --do nothing
		)
		
		--LOAD DEFAULT SOURCE SETTINGS - ALSO A PREFERENCE
		local thePref = (getIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "Preferences" "SwitchSourceDefaultsByRenderMode")
		if thePref == "true" then
		(
			local theString = getIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "SourceDefaults" (FranticParticles.GetProperty "ParticleMode")
			if theString != "" do convertSourcesFromString theString	
		)	
		refresh_GUI()
		update2009VFBControls()
		setFocus ddl_particleMode
	)
	
	on ddl_particleMode selected val do ddl_particleMode_SelectedFN val 
		

	on ckb_useEmissionStrength changed state do
	(
		FranticParticles.SetProperty "Emission:UseStrength" (state as string)
		edt_emissionStrengthResultingValue.enabled = ckb_relativeEmissionStrength.enabled = spn_emissionStrength.enabled = spn_emissionStrengthExponent.enabled = btn_emissionStrengthPreset.enabled = state AND (FranticParticles.GetBoolProperty "UseEmissionColor")
		update2009VFBControls side:#left
	)
	
	on ckb_relativeEmissionStrength changed state do
	(
		FranticParticles.SetProperty "Emission:UseRelativeStrength" (state as string)
		if state do
		(
			local oldFPD = FranticParticles.GetFloatProperty "Density:DensityPerParticle"
			local oldFPDE = FranticParticles.GetIntProperty "Density:DensityExponent"	
			local oldES = FranticParticles.GetFloatProperty "Emission:Strength"
			local oldESE = FranticParticles.GetIntProperty "Emission:StrengthExponent"
				
			local newES = oldES / oldFPD
			local newESE =  oldESE - oldFPDE
			FranticParticles.SetProperty "Emission:RelativeStrength" (newES as string)
			FranticParticles.SetProperty "Emission:RelativeStrengthExponent" (newESE as string)
		)
		refresh_GUI()
		update2009VFBControls side:#left				
	)
	
	on ckb_relativeLightingDensity changed state do
	(
		FranticParticles.SetProperty "Density:RelativeLightingDensity" (state as string)
		if state do
		(
			local oldFPD = FranticParticles.GetFloatProperty "Density:DensityPerParticle"
			local oldFPDE = FranticParticles.GetIntProperty "Density:DensityExponent"	
			local oldLPD = FranticParticles.GetFloatProperty "Lighting:Density:DensityPerParticle"
			local oldLPDE = FranticParticles.GetIntProperty "Lighting:Density:DensityExponent"	
				
			local newLPD = oldLPD/ oldFPD
			local newLPDE =  oldLPDE - oldFPDE
			FranticParticles.SetProperty "Lighting:Density:RelativeDensityPerParticle" (newLPD as string)
			FranticParticles.SetProperty "Lighting:Density:RelativeDensityExponent" (newLPDE as string)
		)
		refresh_GUI()
		update2009VFBControls side:#left		
	)
	
	on ckb_linkLightingAndRenderingDensity changed state do
	(	
		FranticParticles.SetProperty "Density:LinkLightingAndRenderingDensity" (not state)
		--btn_lightingDensityPreset.enabled = spn_LightingDensityPerParticle.enabled = spn_LightingDensityExponent.enabled = state AND not ckb_IgnoreSceneLights.checked
		--ddl_attenuationLookupFilter.enabled = state AND not ckb_IgnoreSceneLights.checked and (FranticParticles.GetProperty "RenderingMethod") == "Particle Rendering"
		refresh_GUI()
		update2009VFBControls side:#left
	)	

	on ckb_linkLightingAndRenderingDensity  rightClick do 
		FranticParticleRenderMXS.createDefaultsRCMenu "Density:LinkLightingAndRenderingDensity" "Link Lighting And Rendering Density] - the inverse of [>Use Lighting Pass Density Settings"
	
	fn ddl_drawPointFilter_selectedFN val = 
	(
		local theFilter = #("Nearest Neighbor","Bilinear","Bicubic")[val]
		if theFilter == "Bilinear" and spn_drawBilinearFilter.value > 1 do theFilter += spn_drawBilinearFilter.value as string
		FranticParticles.SetProperty "DrawPointFilter" theFilter
		update2009VFBControls side:#left		
		Refresh_GUI()
	)
	on ddl_drawPointFilter selected val do ddl_drawPointFilter_selectedFN val 
	
	fn ddl_attenuationLookupFilter_SelectedFN val = 
	(
		local theFilter = #("Nearest Neighbor","Bilinear","Bicubic")[val]
		if theFilter == "Bilinear" and spn_shadowBilinearFilter.value > 1 do theFilter += spn_shadowBilinearFilter.value as string
		FranticParticles.SetProperty "AttenuationLookupFilter" theFilter 
		update2009VFBControls side:#left		
		Refresh_GUI()
	)
	on ddl_attenuationLookupFilter selected val do ddl_attenuationLookupFilter_SelectedFN val 
		
	on spn_shadowBilinearFilter changed val do
	(
		theFilter = "Bilinear"
		if val > 1 do theFilter += val as string
		FranticParticles.SetProperty "AttenuationLookupFilter" theFilter 
		update2009VFBControls side:#left		
	)
	on spn_drawBilinearFilter changed val do
	(
		theFilter = "Bilinear"
		if val > 1 do theFilter += val as string
		FranticParticles.SetProperty "DrawPointFilter" theFilter 
		update2009VFBControls side:#left		
	)	
	
	on ckb_IgnoreSceneLights changed val do 
	(
		FranticParticles.SetProperty "IgnoreSceneLights" (val as string)
		FranticParticles.SetProperty "UseLighting" (not val) --FIXME:Temporary
		
		btn_enableLightingCache.enabled =  not((FranticParticles.GetProperty "ParticleMode") == "Save Particles To File Sequence") and not val
		if not btn_enableLightingCache.enabled do 
		(
			--btn_enableLightingCache.checked = false
			--FranticParticles.SetProperty "EnableLightingCache" "false"
			--try(FranticParticles.InvalidateLightingCache())catch()
		)	
		--ckb_linkLightingAndRenderingDensity.enabled = not val
		--ddl_attenuationLookupFilter.enabled = spn_LightingDensityPerParticle.enabled = spn_LightingDensityExponent.enabled = not val AND ckb_linkLightingAndRenderingDensity.state
		refresh_GUI()
		Krakatoa_GUI_Channels.updateMemChannels()
		try(Krakatoa_GUI_ParticleLoaders.updateLoadersList())catch()
		refreshCacheStatus()
		update2009VFBControls()			
		try(Krakatoa_updateSchematicFlow())catch()
	)
	on ckb_IgnoreSceneLights rightClick do 
		FranticParticleRenderMXS.createDefaultsRCMenu "IgnoreSceneLights" ">Ignore Scene Lights"
	
	
	on ckb_useFilterColor changed state do 
	(
		FranticParticles.SetProperty "UseFilterColor" (state as string)
		update2009VFBControls side:#left
		try(Krakatoa_GUI_RenderGlobalValues.refresh_GUI())catch()
		Krakatoa_GUI_Channels.updateMemChannels()
	)
	on ckb_useFilterColor rightClick do 
		FranticParticleRenderMXS.createDefaultsRCMenu "UseFilterColor" ">Use Absorption"
	
	on ckb_useEmissionColor changed state do 
	(
		edt_emissionStrengthResultingValue.enabled = ckb_relativeEmissionStrength.enabled = spn_emissionStrength.enabled = spn_emissionStrengthExponent.enabled = btn_emissionStrengthPreset.enabled = state and (FranticParticles.GetBoolProperty "Emission:UseStrength")
		ckb_useEmissionStrength.enabled = state
		FranticParticles.SetProperty "UseEmissionColor" (state as string)
		update2009VFBControls side:#left
		--ckb_allocateReflectionStrengthChannel.enabled = 
		--btn_reflectionStrengthPreset.enabled = spn_reflectionStrength.enabled = (ckb_useEnvironmentReflections.checked or ckb_useEmissionColor.checked)
		Krakatoa_GUI_Channels.updateMemChannels()
		try(Krakatoa_GUI_RenderGlobalValues.refresh_GUI())catch()
	)
	on ckb_useEmissionColor rightClick do 
		FranticParticleRenderMXS.createDefaultsRCMenu "UseEmissionColor" ">Use Emission"


	on prg_cacheStatus clicked val do 
	(
		FranticParticleRenderMXS.navigateToKrakatoaRollout Krakatoa_GUI_Channels
	)	

	on btn_quickRender pressed do 
	(
		if matchPattern (FranticParticles.GetProperty "ParticleMode") pattern:"*Krakatoa SR*" then
		(
			FranticParticleRenderMXS.exportPythonFile()
		)
		else if not FranticParticleRenderMXS.checkForHairFarmEffect() do
		(
			FranticParticles.LogProgress ("                                                                 ")
			FranticParticles.LogProgress ("-----" +localtime + "--------------------------")			
			if (FranticParticles.GetBoolProperty "IterativeRender") and ((FranticParticles.GetProperty "ParticleMode") != "Save Particles To File Sequence") then --chk_iterativeRender.enabled then 
			(
				local oldState = renderSceneDialog.isOpen()
				renderSceneDialog.close()
				local re = maxops.getRenderElementMgr #production
				local oldREActive = re.GetElementsActive() 
				re.SetElementsActive false
				
				local oldSaveFile = rendSaveFile 
				local oldTimeType = rendTimeType 
				
				rendSaveFile = false
				rendTimeType = 1
				local oldWidth = renderWidth
				local oldHeight = renderHeight
				
				local theScaleFactor = case (FranticParticles.GetProperty "IterativeRender:ScaleFactor") of --Krakatoa_RCMenu_Struct.IterativeOptions_Selection of
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
					(messagebox "KABOOM!\n3ds Max attempted to crash, but the Krakatoa GUI caught the exception.\nThis is usually a sign that there has been a memory problem or other instability inside the 3ds Max system\nand not necessarily something wrong with Krakatoa or your scene.\nPlease try to save a copy of your work and restart 3ds Max immediately.\n\nIf the problem persists, please contact Krakatoa Support - support@thinkboxsoftware.com" title:"Krakatoa Prevented A Big Explosion!")

				FranticParticles.setProperty "Density:DensityPerParticle" (oldDensity as string)
				rendTimeType = oldTimeType 
				rendSaveFile = oldSaveFile 
				renderWidth = oldWidth 
				renderHeight = oldHeight

				re.SetElementsActive oldREActive
				if oldState do renderSceneDialog.Open()
				
			)
			else
			(
				if ((FranticParticles.GetProperty "ParticleMode") == "Save Particles To File Sequence") then
				(
					local theSequence = (FranticParticles.GetProperty "ParticleFiles")
					if theSequence != "" then
					(
						local theFrameRange = case rendTimeType of
						(
							1: "Current Single Frame "+(sliderTime.frame as integer) as string
							2: "Active Time Segment " + (animationRange.start.frame as integer) as string + " to " + (animationRange.end.frame as integer) as string
							3: "Custom Range "+(rendStart.frame as integer) as string + " to " + (rendEnd.frame as integer) as string
							4: "Frames "+rendPickupFrames 
						)
						local txt = "You are about to SAVE\n   -->"+ theFrameRange +"<--\nto the particles file sequence\n\n"+  theSequence +"\n\nincluding the following Channels:\n\n"
						
						local activeChannelsSettings = FranticParticles.getProperty "ActiveParticleChannels"
						local theFS = filterString activeChannelsSettings ","
						local activeChannels = #()
						for i = 1 to theFS.count by 3 do 
						(
							txt += (theFS[i] + " " + theFS[i+1] + "["+ theFS[i+2] + "] \n")
						)				
						txt += "\nClick [Yes] to CONTINUE with saving.\nClick [No] to EXIT and adjust the settings."
						local q = querybox txt title:("KRAKATOA:"+(FranticParticles.GetProperty "ParticleMode"))
						if q do 
							try(max quick render)
							catch(messagebox "KABOOM!\n3ds Max attempted to crash, but the Krakatoa GUI caught the exception.\nThis is usually a sign that there has been a memory problem or other instability inside the 3ds Max system\nand not necessarily something wrong with Krakatoa or your scene.\nPlease try to save a copy of your work and restart 3ds Max immediately.\n\nIf the problem persists, please contact Krakatoa Support - support@thinkboxsoftware.com" title:"Krakatoa Prevented A Big Explosion!")
					)
					else 
						messagebox "Please specify a valid Save Path in the Save Particles rollout!" title:"KRAKATOA: No Save Path Specified"
				)
				else
					try(max quick render)
					catch
						(messagebox "KABOOM!\n3ds Max attempted to crash, but the Krakatoa GUI caught the exception.\nThis is usually a sign that there has been a memory problem or other instability inside the 3ds Max system\nand not necessarily something wrong with Krakatoa or your scene.\nPlease try to save a copy of your work and restart 3ds Max immediately.\n\nIf the problem persists, please contact Krakatoa Support - support@thinkboxsoftware.com" title:"Krakatoa Prevented A Big Explosion!")
			)
		)
	)
	
	on Krakatoa_GUI_Main rolledUp val do 
	(
		--Not sure why, but in Max 2017, this condition is sometimes false...
		if val == Krakatoa_GUI_MAIN.open then
		(
			FranticParticles.SetProperty "GUI:MainControlsRolloutOpen" (val as string)
			if val and Krakatoa_GUI_MAIN.open then 
			(
				FranticParticles.LogDebug ("+Main Controls Rollout ROLLED DOWN.")
			)	
			else
				FranticParticles.LogDebug ("+Main Controls Rollout ROLLED UP or CHANGED HEIGHT.")
		)
	)
		

	on Krakatoa_GUI_Main close do 
	(
		if Krakatoa_GUI_Main.inDialog and not Krakatoa_Closing_Floater and not Krakatoa_Initializing_Hidden_Rollouts then
		(
			setIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "RolloutVisible" Krakatoa_GUI_Main.title "false"
			FranticParticleRenderMXS.floatOrDockRollout Krakatoa_GUI_Main forceMode:#hide
			Krakatoa_CustomizeRollouts_Dialog.Refresh_GUI()
		)	
	)	

	on Krakatoa_GUI_Main open do 
	(
		FranticParticles.LogDebug (">Opening Main Controls Rollout:")		
		
		--theBitmap = bitmap theSize theSize 
		--theBlankBitmap = bitmap theSize theSize color:[90,90,90]
		--theDisabledBitmap = bitmap theSize theSize color:[160,160,160]
		
		local st1 = timestamp()
		Krakatoa_CustomizeRollouts_Dialog.Refresh_GUI()
		FranticParticles.LogDebug ("+Customize Rollouts Refresh GUI took "+(timestamp()-st1) as string + " milliseconds.")		

		local st1 = timestamp()
		Refresh_GUI()
		FranticParticles.LogDebug ("+Main Controls Refresh GUI took "+(timestamp()-st1) as string + " milliseconds.")		

		local st1 = timestamp()
		updateIcons()
		FranticParticles.LogDebug ("+Icons Updated in "+(timestamp()-st1) as string + " milliseconds.")		
		
		FranticParticles.LogDebug ("+Main Controls Rollout OPENED.")			
	)			
)--end rollout

--------------------------------------------------------------------------------------------------------------------------------------------------------------------	
--PARTICLE SAVING ROLLOUT 
--------------------------------------------------------------------------------------------------------------------------------------------------------------------	

rollout Krakatoa_GUI_SaveParticles "Save Particles" rolledup:true category:20 width:457
(
	local activeChannels = #()
	local inactiveChannels = #()
	local allPossibleChannels = #()	
	
	local allPaths = #()
	local allValues = #()
	local historyValue = undefined
	
	button btn_LoadSave_SaveParticles "<>" across:4 align:#left width:20 height:16 offset:[-10,-5] tooltip:"Load and Save Presets For This Rollout Only" 
	button btn_Help_SaveParticles  "Open Online Help..." width:100 height:16 align:#center offset:[-100,-5] tooltip:"Opens the Krakatoa Online Help for the Save Particles rollout in the default Web Browser. Requires Internet connection."
	button btn_BackTo_Main "Back To Main Controls..." height:16 width:308 offset:[-3,-5] align:#center tooltip:"Closes the rollout and sets focus on\nthe Main Controls rollout."
	button btn_Float_Rollout ">" height:16 width:20 offset:[10,-5] align:#right tooltip:"Float/Dock the Rollout.\nRight-Click for Menu..." 
	

	
	on btn_BackTo_Main pressed do
	(
		Krakatoa_GUI_SaveParticles.open = false
		FranticParticleRenderMXS.BackToMainControls()	
	)	
	on btn_BackTo_Main rightclick do
	(
		Krakatoa_GUI_SaveParticles.open = false
		FranticParticleRenderMXS.BackToMainControls()	
	)		
	
	on btn_LoadSave_SaveParticles pressed do 
	(
		Krakatoa_RCMenu_Struct.Float_Rollout_RCMenu_CurrentRollout = Krakatoa_GUI_SaveParticles
		popupMenu Krakatoa_RCMenu_Struct.Load_Save_Rollout_RCMenu pos:mouse.screenpos
	)	
	on btn_LoadSave_SaveParticles rightClick do 
	(
		Krakatoa_RCMenu_Struct.Float_Rollout_RCMenu_CurrentRollout = Krakatoa_GUI_SaveParticles
		popupMenu Krakatoa_RCMenu_Struct.Load_Save_Rollout_RCMenu pos:mouse.screenpos
	)	
	
	on btn_Float_Rollout pressed do
	(
		FranticParticleRenderMXS.FloatRolloutButtonPressed Krakatoa_GUI_SaveParticles
	)		
	on btn_Float_Rollout rightClick do
	(
		Krakatoa_RCMenu_Struct.Float_Rollout_RCMenu_CurrentRollout = Krakatoa_GUI_SaveParticles
		popupMenu Krakatoa_RCMenu_Struct.Float_Rollout_RCMenu pos:mouse.screenpos
	)

	on Krakatoa_GUI_SaveParticles moved pos do
	(
		setIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "RolloutDialogPositions" Krakatoa_GUI_SaveParticles.title (pos as string)
		Krakatoa_CustomizeRollouts_Dialog.updateStripsPositions pos
	)			

	group "Simple Save Path Controls"
	(
		button btn_particleFilesHistory "H" width:18 height:20 offset:[-5,-2] align:#left across:4 tooltip:"Browse Particle File Sequence History. Particle Render Mode will be changed to Save Particles To File Sequence automatically if a valid path is picked." 
		button btn_particleFiles "..." width:18 height:20 offset:[-93,-2] align:#left tooltip:"Select Path and File Name to Save Particle Files To. Particle Render Mode will be changed to Save Particles To File Sequence automatically if a valid path is specified."
		edittext edt_particleFiles "Path" fieldwidth:357 align:#center offset:[-44,0] 
		button btn_ExploreSavePath "E" align:#right width:16 height:20 offset:[6,-2] tooltip:"Open Current Save Path In Windows Explorer..." 
	)	
	group "Detailed Save Path Controls"
	(
		button btn_BaseHistory "H" width:18 height:20 offset:[-5,-4] align:#left across:3 tooltip:"Browse Root Path History..." 
		edittext edt_particleFilesBase "Root" fieldwidth:355 align:#left offset:[-111,-2] 
		button btn_ExploreBase "E" align:#right width:18 height:20 offset:[5,-4] tooltip:"Open Root Path In Windows Explorer..."  

		button btn_ProjectHistory "H" width:18 height:20 offset:[-5,-4] align:#left across:3 tooltip:"Browse Project History..." 
		edittext edt_particleFilesProject "Project" fieldwidth:355 align:#left offset:[-121,-2] 
		button btn_ExploreProjectPath "E" align:#right width:18 height:20 offset:[5,-4] tooltip:"Open Project Path In Windows Explorer..."  

		button btn_SequenceHistory "H" width:18 height:20 offset:[-5,-4] align:#left across:3 tooltip:"Browse Sequence History" 
		edittext edt_particleFilesSequence "Seq." fieldwidth:355 align:#left offset:[-110,-2] 
		button btn_ExploreSequencePath "E" align:#right width:18 height:20 offset:[5,-4] tooltip:"Open Sequence Path In Windows Explorer..." 

		button btn_TakeHistory "H" width:18 height:20 offset:[-5,-4] align:#left across:6 tooltip:"Browse Take History" 
		edittext edt_particleFilesTake "Take" fieldwidth:268 align:#left offset:[-41,-2] 
		button btn_TakeMajorUp "M+" align:#right width:28 height:20 offset:[144,-4] tooltip:"Increment MAJOR version (200,300,400...)" 
		button btn_TakeMinorUp "m+" align:#right width:28 height:20 offset:[102,-4] tooltip:"Increment minor version (110,120,130...)" 
		button btn_TakeUp "i+" align:#right width:28 height:20 offset:[60,-4] tooltip:"Increment take (101,102,103...)"
		button btn_ExploreTake "E" align:#right width:18 height:20 offset:[8,-4] tooltip:"Open Take Path In Windows Explorer..." 

		button btn_FilenameHistory "H" width:18 height:20 offset:[-5,-4] align:#left across:6 tooltip:"Browse File Name History" 
		edittext edt_particleFilesName "File" fieldwidth:268 align:#left offset:[-32,-2] 
		button btn_TypePrt ".prt" align:#right width:28 height:20 offset:[144,-4] tooltip:"Thinkbox Particle Format" 
		button btn_TypeCsv ".csv" align:#right width:28 height:20 offset:[102,-4] tooltip:"Comma Separated Values File" 
		button btn_TypeBin ".bin" align:#right width:28 height:20 offset:[60,-4] tooltip:"RealFlow 4 Particle BIN Format"
		button btn_getFilenameFromMax "M" align:#right width:18 height:20 offset:[8,-4] tooltip:"Get 3ds Max Scene Name, or set to 'Particles' if Untitled." 
	)
	checkbutton ckb_skipExistingFiles ">Skip Existing Files When Saving or Partitioning" align:#center width:450 height:20  highlightcolor:KrakatoaSkinColorsStruct.Partitioning  tooltip:"When checked, existing particle files will not be overwritten but skipped, causing only non-existent files to be written."
	
	group "After a Partition is saved,"
	(
		dropdownlist ddl_BackupRootMode items:#("LEAVE the file sequence at the Save Path listed above.","COPY the file sequence to the Backup Path defined below:","MOVE the file sequence to the Backup Path defined below:") width:375 align:#right offset:[3,-2]
		button btn_BackupRootHistory "H" width:18 height:20 offset:[-7,-4] align:#left across:4 tooltip:"Browse Root Path History..." visible:false
		button btn_particleFilesBackup "..." width:18 height:20 offset:[-95,-4] align:#left tooltip:"Select Path and File Name to Save Particle Files To. Particle Render Mode will be changed to Save Particles To File Sequence automatically if a valid path is specified."
		edittext edt_particleFilesBackupRoot "Root" fieldwidth:355 align:#center offset:[-44,-2] 
		button btn_ExploreBackupRoot "E" align:#right width:18 height:20 offset:[5,-4] tooltip:"Open Backup Root Path In Windows Explorer..."  
		edittext edt_particleFilesBackupPath "Backup Path" fieldwidth:355 align:#left offset:[-7,-2] across:2 enabled:false
		button btn_ExploreBackupPath "E" align:#right width:18 height:20 offset:[3,-4] tooltip:"Open Backup Root Path In Windows Explorer..."  
	)
	
	group "Particle Channels To Save To Disk"
	(
		multilistbox lbx_allChannels " Do Not Save Channels:" items:#() height:12 across:2 width:204 align:#left offset:[0,-5]
		multilistbox lbx_activeChannels " Save Channels:" items:#() height:12 width:205 align:#right offset:[0,-5]
		
		checkbutton ckb_showMappingChannels ">All Mapping Channels" align:#left offset:[0,-3] width:120 across:9 tooltip:"Show all Mapping Channels." highlightcolor:KrakatoaSkinColorsStruct.Channels
		button btn_allAll "All" width:40 alignt:#left offset:[70,-3] tooltip:"Select All Inactive Channels."
		button btn_allInvert "Invert" width:40 alignt:#left offset:[67,-3] tooltip:"Invert Inactive Channels Selection."

		button btn_activeAll "All" width:40 alignt:#center offset:[82,-3] tooltip:"Select All Active Channels."
		button btn_activeInvert "Invert" width:40 alignt:#center offset:[79,-3] tooltip:"Invert Active Channels Selection."
		
		button btn_make16 "16" width:40 alignt:#right offset:[70,-3] tooltip:"Switch the Selected Channels To 16 bit Precision."
		button btn_make32 "32" width:40 alignt:#right offset:[64,-3] tooltip:"Switch the Selected Channels To 32 bit Precision."
		button btn_make64 "64" width:40 alignt:#right offset:[57,-3] tooltip:"Switch the Selected Channels To 64 bit Precision."
		label lbl_MemoryUsed "" offset:[0,-184] align:#right
	)
	
	group "Save Lighting As Emission"
	(
		checkbutton chk_saveLightingAsEmission ">Compute Lighting And Copy Lighting Channel Into Emission Channel When Saving" width:440 tooltip:"When checked, Lighting will be calculated during Saving and the Lighting Channel Data will be copied to the Emission channel resulting in a Pre-Lit Particle Sequence"
	)
	
	group "Edit Custom Save Channels (Marked with * on the above Lists)"
	(
		button btn_addNewChannel "Add" across:5 width:25 align:#left offset:[-3,-3] tooltip:"Add New / Update Existing Custom Channel Definition"
		edittext edt_newChannelName "" fieldwidth:280 align:#left offset:[-65,-1]
		dropdownlist ddl_ChannelType items:#("float16","float32","float64","int8","int16","int32","int64","uint8","uint16","uint32","uint64") width:60 align:#right height:20 offset:[110,-3]
		dropdownlist ddl_ChannelArity items:#("1","2","3","4") width:40 align:#right offset:[65,-3]
		button btn_removeChannel "X" width:25 align:#right offset:[5,-3] tooltip:"Remove Custom Channel"
	)	
	
	button btn_ChannelAdd ">" height:50 align:#center width:20 offset:[0,-295] tooltip:"Move the Selected Channels to the 'Save Channels' list." 
	button btn_ChannelRemove "<" height:50 align:#center offset:[0,-3] width:20 tooltip:"Move the Selected Channels to the 'Do Not Save Channels' list." 
	button btn_ChannelPresets ">>" width:20 height:50 align:#center offset:[0,3] tooltip:"Add, Remove and Load Channel Presets..." 	
	


---SAVE CHANNELS FUNCTIONS AND HANDLERS 	
	fn getAllChannels =
	(
		allPossibleChannels = #(
			#("Position", "float32", 3),
			#("Velocity", "float16", 3),
			#("Density", "float16", 1),
			#("Color", "float16", 3),

			#("Absorption", "float16", 3),
			#("Emission", "float16", 3),
			#("Eccentricity", "float16", 1),
			#("SpecularPower", "float16", 1),
			#("SpecularLevel", "float16", 1),			
			#("ReflectionStrength", "float16", 1),			
			
			#("Normal", "float16", 3),
			#("Tangent", "float16", 3),
			#("TextureCoord", "float16", 3),
			--#("Lighting", "float16", 3),
			
			#("Selection", "float16", 1),
			#("Age", "float32", 1),
			#("LifeSpan", "float32", 1),			
			#("ID", "int32", 1),
			
			#("MtlIndex","int16", 1),
			#("MXSInteger", "int16", 1),
			#("MXSFloat", "float16", 1),
			#("MXSVector", "float16", 3),
			#("Orientation", "float16", 4),
			#("Scale", "float16", 3),
			#("Radius", "float32", 1),
			#("Acceleration", "float16", 3),
			#("SignedDistance", "float16", 1),
			#("SignedDistanceGradient", "float16", 3),
			
			#("Fire", "float16", 1),
			#("Fuel", "float16", 1),
			#("Temperature", "float16", 1),
			#("DensityGradient", "float16", 3),
			#("Vorticity", "float16", 3)
		)
		local theIniFile = (Krakatoa_PresetsDirectory+"\\Krakatoa_CustomChannelsToSave.ini") 
		local customChannels = getIniSetting theIniFile
		for c in customChannels do
		(
			if findItem (for i in allPossibleChannels collect i[1]) c == 0 do
			(
				local theType = getIniSetting theIniFile c "Type"
				local theArity = getIniSetting theIniFile c "Arity"
				if theType != "" and theArity != "" do
				(
					append allPossibleChannels #(c,theType,theArity,true)
				)
			)	
		)
		
		if ckb_showMappingChannels.checked do
			for i = 2 to 99 do append allPossibleChannels #("Mapping"+i as string, "float16", 3)
		
	)	

	fn populateLists =
	(
		getAllChannels()
		local activeChannelsSettings = FranticParticles.getProperty "ActiveParticleChannels"
		theFS = filterString activeChannelsSettings ","
		activeChannels = #()
		for i = 1 to theFS.count by 3 do 
		(
			local userChannel = (for j in allPossibleChannels where j[1] == theFS[i] and j[4]==true collect j).count > 0 
			append activeChannels #(theFS[i], theFS[i+1],theFS[i+2] as integer, userChannel )
		)	

		local activeNames = for i in activeChannels collect i[1]
		inactiveChannels = for i in allPossibleChannels where findItem activeNames i[1] == 0 collect i
		lbx_allChannels.items = for i in inactiveChannels collect 
		(
			local userChannel = if i[4]==true then "* " else ""
			if i[3] == 1 then
				(userChannel + i[1] + "  :  " + i[2]  )
			else
				(userChannel + i[1] + "  :  " + i[2] + "[" + i[3] as string  + "]" )
		)
		lbx_activeChannels.items = for i in activeChannels collect 
		(
			local userChannel = if i[4]==true then "* " else ""
			if i[3] == 1 then
				(userChannel+i[1] + "  :  " + i[2])
			else
				(userChannel+i[1] + "  :  " + i[2] + "[" + i[3] as string + "]" )
		)	
		local theMemPerParticle = FranticParticleRenderMXS.calculateMemoryUsage activeChannels
		local txt = "Bytes/Particle:"+ theMemPerParticle[1] as string
		if theMemPerParticle[2] > 0 do txt += "(+"+theMemPerParticle[2] as string + "?)"
		lbl_MemoryUsed.text = txt
	)
	
	on edt_newChannelName entered val do
	(
		local txt = ""
		for i = edt_newChannelName.text.count to 1 by -1 do
		(
			local theCode = bit.charAsInt edt_newChannelName.text[i] 
			if (theCode > 47 and theCode < 58) or (theCode > 64 and theCode < 91) or (theCode > 96 and theCode < 123) do 
				txt = edt_newChannelName.text[i] + txt
		)
		edt_newChannelName.text = txt	
	)
	
	on btn_addNewChannel pressed do
	(
		if edt_newChannelName.text != "" and edt_newChannelName.text.count > 3 do --and findItem (for i in allPossibleChannels collect i[1]) edt_newChannelName.text == 0 do
		(
			setIniSetting (Krakatoa_PresetsDirectory+"\\Krakatoa_CustomChannelsToSave.ini") edt_newChannelName.text "Type" ddl_ChannelType.selected
			setIniSetting (Krakatoa_PresetsDirectory+"\\Krakatoa_CustomChannelsToSave.ini") edt_newChannelName.text "Arity" ddl_ChannelArity.selected
			--getAllChannels()
			populateLists()
		)
		
	)
	on btn_removeChannel pressed do
	(
		if edt_newChannelName.text != "" do 
		(
			if (getIniSetting (Krakatoa_PresetsDirectory+"\\Krakatoa_CustomChannelsToSave.ini") edt_newChannelName.text).count > 0 do
				delIniSetting (Krakatoa_PresetsDirectory+"\\Krakatoa_CustomChannelsToSave.ini") edt_newChannelName.text
			--getAllChannels()
			populateLists()
		)
	)
	
	on ckb_showMappingChannels changed state do populateLists()
	
	fn storeActiveChannels =
	(
		local thePropValue = ""
		for i in activeChannels do thePropValue += i[1] + "," + i[2] + "," + i[3] as string + ","
		if activeChannels.count > 0 do thePropValue = substring thePropValue 1 (thePropValue.count-1)
		FranticParticles.setProperty "ActiveParticleChannels" thePropValue
		
		/*
		local thePropValue = ""
		for i in inactiveChannels do thePropValue += i[1] + "," + i[2] + "," + i[3] as string + ","
		if inactiveChannels.count > 0 do thePropValue = substring thePropValue 1 (thePropValue.count-1)
		FranticParticles.setProperty "InactiveParticleChannels" thePropValue
		*/
	)
	
	fn addChannel =
	(
		local theArray = lbx_allChannels.selection as array
		local toSelect = for i in lbx_activeChannels.selection collect activeChannels[i][1]
		local newSelection = #{} 
		
		for j = theArray.count to 1 by -1 do
		(
			theIndex = theArray[j]
			append activeChannels inactiveChannels[theIndex]
			append toSelect inactiveChannels[theIndex][1]
			deleteItem inactiveChannels theIndex
			--local theNames = for i in inactiveChannels collect i[1]
			--activeChannels = for i in allChannels where findItem theNames i[1] == 0 collect i
		)		
		storeActiveChannels()
		populateLists()
		for j in toSelect do 
			for i = 1 to activeChannels.count where activeChannels[i][1] == j do append newSelection i
		lbx_activeChannels.selection = newSelection 
		lbx_allChannels.selection = #{}
	)
	
	fn removeChannel = 
	(
		local theArray = lbx_activeChannels.selection as array
		local toSelect = for i in lbx_allChannels.selection collect inactiveChannels[i][1]
		local newSelection = #{} 
		for j = theArray.count to 1 by -1 do
		(
			local theIndex = theArray[j]
			if not activeChannels[theIndex][1] == "Position" do
			(
				append inactiveChannels activeChannels[theIndex]
				append toSelect activeChannels[theIndex][1]
				deleteItem activeChannels theIndex
			)	
		)		
		storeActiveChannels()
		populateLists()
		for j in toSelect do 
			for i = 1 to inactiveChannels.count where inactiveChannels[i][1] == j do append newSelection i
		lbx_allChannels.selection = newSelection
		lbx_activeChannels.selection = #{}
	)

	fn convertChannelsToString =
	(
		local theStringArray = #()
		for c in allPossibleChannels do
		(
			for i in activeChannels do
			(
				if c[1] == i[1] then append theStringArray i
			)
		)			
		local theString1 = ""
		local theString2 = ""
		for i = 1 to theStringArray.count-1 do theString1 += theStringArray[i][1]+","
		theString1 += theStringArray[theStringArray.count][1]
		for i = 1 to theStringArray.count-1 do theString2 += theStringArray[i][1]+","+theStringArray[i][2]+","+theStringArray[i][3] as string+","
		theString2 += theStringArray[theStringArray.count][1]+","+theStringArray[theStringArray.count][2]+","+theStringArray[theStringArray.count][3] as string
		#(theString1, theString2)
	)
	
	fn convertSourcesFromString theString =
	(
		FranticParticles.setProperty "ActiveParticleChannels" theString
		populateLists()
		--::Krakatoa_GUI_Channels.refresh_GUI()
	)
	
	fn setChannelsFromSelectedNodes =
	(
		local sceneSelection = for o in selection where findItem #(KrakatoaPrtLoader, PRT_Volume, PRT_FumeFX, PRT_Source, PRT_Surface, PRT_Hair, PRT_Maker ) (classof o.baseobject) > 0 collect o
		if sceneSelection.count > 0 do
		(
			local theChannelNames = #()
			local theChannelDefs = #()
			for o in sceneSelection do
			(
				local theInterface = FranticParticles.GetPRTObjectIStream o true true
				local theChannels = theInterface.GetChannels()
				for i in theChannels do 
				(
					local theFS = filterString i " []"
					if findItem theChannelNames theFS[1] == 0 do
					(
						append theChannelNames theFS[1]
						append theChannelDefs theFS
					)
				)
				theInterface.Close()
			)
			local thePropValue = ""
			if theChannelDefs.count > 0 do
			(
				for i in theChannelDefs do thePropValue += i[1] + "," + i[2] + "," + i[3] as string + ","
				if theChannelDefs.count > 0 do thePropValue = substring thePropValue 1 (thePropValue.count-1)
				FranticParticles.setProperty "ActiveParticleChannels" thePropValue	
				populateLists()
			)
		)
	)
	fn appendChannelsFromSelectedNodes =
	(
		local sceneSelection = for o in selection where findItem #(KrakatoaPrtLoader, PRT_Volume, PRT_FumeFX, PRT_Source, PRT_Surface, PRT_Hair, PRT_Maker ) (classof o.baseobject) > 0 collect o
		
		local activeChannelsSettings = FranticParticles.getProperty "ActiveParticleChannels"
		local theFS = filterString activeChannelsSettings ","
		activeChannels = #()
		for i = 1 to theFS.count by 3 do 
		(
			local userChannel = (for j in allPossibleChannels where j[1] == theFS[i] and j[4]==true collect j).count > 0 
			append activeChannels #(theFS[i], theFS[i+1],theFS[i+2] as integer, userChannel )
		)	

		local theChannelNames = for i in activeChannels collect i[1]		
		for o in sceneSelection do
		(
			local theInterface = FranticParticles.GetPRTObjectIStream o true true
			local theChannels = theInterface.GetChannels()
			for i in theChannels do 
			(
				local theFS = filterString i " []"
				if findItem theChannelNames theFS[1] == 0 do
				(
					append theChannelNames theFS[1]
					append activeChannels theFS
				)
			)
			theInterface.Close()
		)
		local thePropValue = ""
		for i in activeChannels do thePropValue += i[1] + "," + i[2] + "," + i[3] as string + ","
		if activeChannels.count > 0 do thePropValue = substring thePropValue 1 (thePropValue.count-1)
		FranticParticles.setProperty "ActiveParticleChannels" thePropValue	
		populateLists()		
	)	
	
	fn createChannelPresetsRCMenu =
	(
		presetName = "ChannelPresets"
		local presetsList = #()
		local presetsValuesList = #()
		local theKeys = getIniSetting (Krakatoa_PresetsDirectory + "//KrakatoaPreferences.ini") presetName  
		sort theKeys 
		if theKeys.count == 0 then 
		(
			theKeys = #("Position,Velocity","Position,Velocity,Density,Color,Normal,ID")
			theVals = #("Position,float32,3,Velocity,float16,3","Position,float32,3,Velocity,float16,3,Density,float16,1,Color,float16,3,Normal,float16,3,ID,int32,1")
			for i = 1 to theKeys.count do
				setIniSetting (Krakatoa_PresetsDirectory + "//KrakatoaPreferences.ini") presetName theKeys[i] theVals[i]
		)
		
		local theValue = convertChannelsToString()
		for k in theKeys do
		(
			append presetsList k
			append presetsValuesList (getIniSetting (Krakatoa_PresetsDirectory + "//KrakatoaPreferences.ini") presetName k)
		)
			
		local txt = StringStream ""
		format "rcmenu Presets_RCMenu\n(\n" to:txt
		

		
		if findItem presetsList theValue[1] == 0 do 
		(
			format  "menuItem mnu_AddPreset \"Add [%]\"\n" theValue[1] to:txt
			format  "on mnu_AddPreset picked do setIniSetting (Krakatoa_PresetsDirectory + \"//KrakatoaPreferences.ini\") \"%\" \"%\" \"%\" \n" presetName theValue[1] theValue[2] to:txt
			format  "separator spr_110\n"  to:txt
		)	
		
		if (theIndex = findItem presetsList theValue[1]) != 0 and presetsValuesList[theIndex] != theValue[2] do 
		(
			format  "menuItem mnu_UpdatePreset \"Update [%]\"\n" theValue[1] to:txt
			format  "on mnu_UpdatePreset picked do setIniSetting (Krakatoa_PresetsDirectory + \"//KrakatoaPreferences.ini\") \"%\" \"%\" \"%\" \n" presetName theValue[1] theValue[2] to:txt
			format  "separator spr_120\n"  to:txt
		)	
		
		cnt = 0
		for i = 1 to presetsList.count do
		(
			cnt += 1
			format  "menuItem mnu_preset% \"%\" \n"  cnt presetsList[i] to:txt
			format  "on mnu_preset% picked do (Krakatoa_GUI_SaveParticles.convertSourcesFromString \"%\" )\n" cnt presetsValuesList[i] to:txt
		)
		
		if findItem presetsList theValue[1] != 0 do 
		(
			format  "separator spr_200\n"  to:txt
			format  "menuItem mnu_RemovePreset \"Remove [%]\"\n" theValue[1] to:txt
			format  "on mnu_RemovePreset picked do delIniSetting (Krakatoa_PresetsDirectory + \"//KrakatoaPreferences.ini\") \"%\" \"%\" \n" presetName theValue[1] to:txt
		)	
		
		local currentDefault = getIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaDefaults.ini") "Defaults" "ActiveParticleChannels"
		if currentDefault == "" do currentDefault = "--Not Set--"
		
		format  "separator spr_20\n" 	to:txt
		if currentDefault != theValue[2] as string do
		(
			format  "menuItem mnu_MakeDefault \"Set [%] as Default\"\n" theValue[1] to:txt
			format  "on mnu_MakeDefault picked do setIniSetting (GetDir #plugcfg + \"/Krakatoa/KrakatoaDefaults.ini\") \"Defaults\" \"ActiveParticleChannels\" \"%\" \n" theValue[2] to:txt
		)

		if currentDefault != "--Not Set--" do
		(
			format  "menuItem mnu_ResetDefault \"Reset Default\"\n"  to:txt
			format  "on mnu_ResetDefault picked do delIniSetting (GetDir #plugcfg + \"/Krakatoa/KrakatoaDefaults.ini\") \"Defaults\" \"ActiveParticleChannels\"\n" to:txt
		)			

		format  "separator spr_300\n"  to:txt
		format "menuItem mnu_setChannelsFromSelectedNodes \"SET Channels List From Selected PRT Objects\"\n" to:txt
		format  "on mnu_setChannelsFromSelectedNodes picked do (Krakatoa_GUI_SaveParticles.setChannelsFromSelectedNodes()) \n" to:txt
		
		format "menuItem mnu_appendChannelsFromSelectedNodes \"APPEND Channels From Selected PRT Objects\"\n" to:txt
		format  "on mnu_appendChannelsFromSelectedNodes picked do (Krakatoa_GUI_SaveParticles.appendChannelsFromSelectedNodes()) \n" to:txt
		

		format  ")\n" to:txt
		Krakatoa_RCMenu_Struct.Presets_RCMenu = execute (txt as string)
	)
	
	on btn_ChannelPresets pressed do
	(
		createChannelPresetsRCMenu()
		popUpMenu Krakatoa_RCMenu_Struct.Presets_RCMenu position:mouse.screenPos
	)
	
	on btn_ChannelPresets rightClick do
	(
		createChannelPresetsRCMenu()
		popUpMenu Krakatoa_RCMenu_Struct.Presets_RCMenu position:mouse.screenPos
	)	

	
	on btn_ChannelAdd pressed do addChannel()
	on btn_ChannelRemove pressed do removeChannel()
	on lbx_allChannels doubleClicked itm do addChannel()
	on lbx_activeChannels doubleClicked itm do removeChannel()
	
	on lbx_allChannels selectionend do 
	(
		if lbx_allChannels.selection.numberset == 1 do 
		(
			if inactiveChannels[(lbx_allChannels.selection as array)[1]][4] == true do
			(
				edt_newChannelName.text = inactiveChannels[(lbx_allChannels.selection as array)[1]][1]
				ddl_ChannelType.selection = findItem  ddl_ChannelType.items inactiveChannels[(lbx_allChannels.selection as array)[1]][2]
				ddl_ChannelArity.selection = findItem  ddl_ChannelArity.items (inactiveChannels[(lbx_allChannels.selection as array)[1]][3] as string)
			)	
		)	
	)
	
	on lbx_activeChannels selectionend do 
	(
		if lbx_activeChannels.selection.numberset == 1 do 
		(
			if activeChannels[(lbx_activeChannels.selection as array)[1]][4] == true do
			(
				edt_newChannelName.text = activeChannels[(lbx_activeChannels.selection as array)[1]][1]
				ddl_ChannelType.selection = findItem  ddl_ChannelType.items activeChannels[(lbx_activeChannels.selection as array)[1]][2]
				ddl_ChannelArity.selection = findItem  ddl_ChannelArity.items (activeChannels[(lbx_activeChannels.selection as array)[1]][3] as string)
			)	
		)	
	)	
	
	on btn_allAll pressed do lbx_allChannels.selection = #{1..lbx_allChannels.items.count}
	on btn_allInvert pressed do lbx_allChannels.selection = #{1..lbx_allChannels.items.count} - lbx_allChannels.selection

	on btn_activeAll pressed do lbx_activeChannels.selection = #{1..lbx_activeChannels.items.count}
	on btn_activeInvert pressed do lbx_activeChannels.selection = #{1..lbx_activeChannels.items.count} - lbx_activeChannels.selection
	
	on btn_make16 pressed do 
	(
		for i in lbx_activeChannels.selection where not matchPattern activeChannels[i][1] pattern:"Position" do
		(
			if matchpattern activeChannels[i][2] pattern:"float*" do activeChannels[i][2] = "float16"
			if matchpattern activeChannels[i][2] pattern:"int*" do activeChannels[i][2] = "int16"
			if matchpattern activeChannels[i][2] pattern:"uint*" do activeChannels[i][2] = "uint16"
		)
		storeActiveChannels()
		populateLists()			
	)
	on btn_make32 pressed do 
	(
		for i in lbx_activeChannels.selection do
		(
			if matchpattern activeChannels[i][2] pattern:"float*" do activeChannels[i][2] = "float32"
			if matchpattern activeChannels[i][2] pattern:"int*" do activeChannels[i][2] = "int32"
			if matchpattern activeChannels[i][2] pattern:"uint*" do activeChannels[i][2] = "uint32"
		)
		storeActiveChannels()
		populateLists()			
	)	
	on btn_make64 pressed do 
	(
		for i in lbx_activeChannels.selection where not matchPattern activeChannels[i][1] pattern:"Position" do
		(
			if matchpattern activeChannels[i][2] pattern:"float*" do activeChannels[i][2] = "float64"
			if matchpattern activeChannels[i][2] pattern:"int*" do activeChannels[i][2] = "int64"
			if matchpattern activeChannels[i][2] pattern:"uint*" do activeChannels[i][2] = "uint64"
		)
		storeActiveChannels()
		populateLists()			
	)	
	
	on chk_saveLightingAsEmission changed state do
	(
		FranticParticles.SetProperty "SaveLightingAsEmission" (state as string)
		if state do
		(
			local theIndex = for i = 1 to lbx_allChannels.items.count where matchPattern lbx_allChannels.items[i] pattern:"Emission*" collect i
			if theIndex.count == 1 do 
			(
				lbx_allChannels.selection = #{theIndex[1]}
				addChannel()
			)	
		)
		try(Krakatoa_updateSchematicFlow())catch()
	)	
	
	on chk_saveLightingAsEmission rightclick do
		FranticParticleRenderMXS.createDefaultsRCMenu "SaveLightingAsEmission" "Copy Lighting Channel Into Emission Channel When Saving"
	
	
---SAVING CONTROLS HANDLERS	
	on ckb_skipExistingFiles changed state do 
	(
		FranticParticles.SetProperty "SkipExistingParticleFiles" (state as string)
		try(Krakatoa_GUI_Partition.refresh_GUI())catch()
	)
	
	on ckb_skipExistingFiles rightclick do 
		FranticParticleRenderMXS.createDefaultsRCMenu "SkipExistingParticleFiles" "Skip Existing Files When Saving or Partitioning"
		
	
	fn tweakControlPositions =
	(
		try
		(
		edt_particleFiles.pos = [72,edt_particleFiles.pos.y]
		
		edt_particleFilesBase.pos = [72,edt_particleFilesBase.pos.y]
		edt_particleFilesProject.pos = [72,edt_particleFilesProject.pos.y]
		edt_particleFilesSequence.pos = [72,edt_particleFilesSequence.pos.y]
		edt_particleFilesTake.pos = [72,edt_particleFilesTake.pos.y]
		edt_particleFilesName.pos = [72,edt_particleFilesName.pos.y]
		
		edt_particleFilesBackupRoot.pos = [72,edt_particleFilesBackupRoot.pos.y]
		edt_particleFilesBackupPath.pos = [72,edt_particleFilesBackupPath.pos.y]
		)catch()
		
		try
		(
			btn_allAll.pos = [134,btn_activeAll.pos.y]
			btn_allInvert.pos = [174,btn_activeInvert.pos.y]
			
			btn_activeAll.pos = [240,btn_activeAll.pos.y]
			btn_activeInvert.pos = [280,btn_activeInvert.pos.y]
		)catch()		
	)	
	
	fn isTake theTake =
	(
		local theValues = #()
		for i = theTake.count to 1 by -1 do 
		(
			if bit.charAsInt theTake[i] >= 48 and bit.charAsInt theTake[i] <= 57 then
				append theValues theTake[i]
			else	
				exit
		)	
		local txt = ""
		for i = theValues.count to 1 by -1 do txt += theValues[i]
		if txt.count > 0 then 
			#(substring theTake 1 (theTake.count - theValues.count), txt as integer)
		else
			undefined	
	)
	


	fn resolveAdvancedPathStructure =
	(	
		local val = FranticParticles.GetProperty "ParticleFiles" 
		if val != "" do
		(
			isNetworkPath = matchpattern val pattern:"\\\\*" 
			local fString = filterString val "\\/"
			if isNetworkPath do fString[1] = "\\\\" + fString[1]
			fString = for i = fString.count to 1 by -1 collect fString[i]
			fString = for i in fString where i.count > 0 collect i
			
			FranticParticles.SetProperty "ParticleFilesName" (edt_particleFilesName.text = fString[1])
			deleteItem fString 1
			if fString.count > 0 do
			(
				if isTake fString[1] != undefined then
				(
					FranticParticles.SetProperty "ParticleFilesTake" (edt_particleFilesTake.text = fString[1])
					deleteItem fString 1
				)	
				else
					FranticParticles.SetProperty "ParticleFilesTake" (edt_particleFilesTake.text = "")
					
				case fString.count of
				(
					0: ()
					1: (
						FranticParticles.SetProperty "ParticleFilesBase" (edt_particleFilesBase.text = fString[1])
						FranticParticles.SetProperty "ParticleFilesProject" (edt_particleFilesProject.text = "")
						FranticParticles.SetProperty "ParticleFilesSequence" (edt_ParticleFilesSequence.text = "")
						)
					2:
					(
							FranticParticles.SetProperty "ParticleFilesProject" (edt_particleFilesProject.text = fString[1])
							FranticParticles.SetProperty "ParticleFilesBase" (edt_particleFilesBase.text = fString[2])
							FranticParticles.SetProperty "ParticleFilesSequence" (edt_ParticleFilesSequence.text = "")
					)
					3:
					(
							FranticParticles.SetProperty "ParticleFilesSequence" (edt_ParticleFilesSequence.text = fString[1])
							FranticParticles.SetProperty "ParticleFilesProject" (edt_particleFilesProject.text = fString[2])
							FranticParticles.SetProperty "ParticleFilesBase" (edt_particleFilesBase.text = fString[3])
					)
					default:
					(
							FranticParticles.SetProperty "ParticleFilesSequence" (edt_ParticleFilesSequence.text = fString[1])
							FranticParticles.SetProperty "ParticleFilesProject" (edt_particleFilesProject.text = fString[2])
							local theRoot = ""
							for i = fString.count to 3 by -1 do theRoot += fString[i] + "\\"
								FranticParticles.SetProperty "ParticleFilesBase" (edt_particleFilesBase.text = theRoot)
					)		
				)--end case
			)	
		)
	)
	
	fn getFilenameFromBackupRoot =
	(
		local val = FranticParticles.GetProperty "Partition:BackupRoot"
		if val != "" do
		(
			local theNextVal = FranticParticles.GetProperty "ParticleFilesProject"
			if theNextVal != "" then
			(
				if not matchPattern theNextVal pattern:"*\\" and not matchPattern theNextVal pattern:"*/" do theNextVal += "\\"
				val += theNextVal
			)
			theNextVal = FranticParticles.GetProperty "ParticleFilesSequence"
			if theNextVal != "" then
			(
				if not matchPattern theNextVal pattern:"*\\" and not matchPattern theNextVal pattern:"*/" do theNextVal += "\\"
				val += theNextVal
			)
			theNextVal = FranticParticles.GetProperty "ParticleFilesTake"
			if theNextVal != "" then
			(
				if not matchPattern theNextVal pattern:"*\\" and not matchPattern theNextVal pattern:"*/" do theNextVal += "\\"
				val += theNextVal
			)			
		)	
		val 
	)		
	
	fn validateBackupPath txt =
	(
		if doesFileExist txt then
		(
			if txt[txt.count] != "\\" do txt+= "\\"
			FranticParticles.SetProperty "Partition:BackupRoot" (txt as string)
		)
		else
			if txt != "" do messagebox ("The specified path\n"+ txt +"does not exist!\n\nReverting to last stored value...") title:"Krakatoa: Local Partition Backup Path"
		edt_particleFilesBackupRoot.text = FranticParticles.GetProperty "Partition:BackupRoot"
		if edt_particleFilesBase.text != "" and edt_particleFilesBase.text == edt_particleFilesBackupRoot.text then
		(
			messagebox "The SAVE path and the BACKUP path can not be the same!" title:"Krakatoa: Local Partition Backup Path"
			FranticParticles.SetProperty "Partition:BackupRoot" ""
			edt_particleFilesBackupRoot.text = ""
		)
		edt_particleFilesBackupPath.text = getFilenameFromBackupRoot()	
	)			
	
	fn checkValidSaveFileName val =
	(
		val = trimRight (trimLeft val)
		local txt = ""
		local fString = (filterString val "\\/")
		if fString.count > 0 do
		(
			if matchPattern val pattern:"\\\\*" do fString[1] = "\\\\" + fString[1]
			for i = 1 to fString.count-1 do txt += fString[i] + "\\"
			txt += fString[fString.count]
			val = txt
			local q = false
			if getFileNamePath val != "" AND not doesFileExist (getFileNamePath val) do
			(
				q = querybox ("The path\n"+ (getFileNamePath val) +"\ndoes NOT exist.\nShould it be CREATED?") title:"Save Path Does Not Exist"
				if q do makeDir (getFileNamePath val) all:true --create the full path if it does not exist and the user wants to create it.
			)	
			if doesFileExist (getFileNamePath val) then 
			(
--					if not matchPattern (getFileNameFile val) pattern:"*_" do val = getFileNamePath val + (getFileNameFile val) + "_" + getFileNameType val
				if not matchpattern (getFileNameType val) pattern:".prt" and \
					not matchpattern (getFileNameType val) pattern:".csv" and \
					not matchpattern (getFileNameType val) pattern:".bin" do val = getFileNamePath val + getFilenameFile val + ".prt"
				FranticParticles.SetProperty "ParticleFiles" (edt_particleFiles.text = val)
				resolveAdvancedPathStructure()
			)	
			else --if the path does not exist, revert to the previously stored path
			(
				edt_particleFiles.text = FranticParticles.GetProperty "ParticleFiles" 
				resolveAdvancedPathStructure()
				if q do messagebox "The path you entered could not be created!\nReverting to the last stored path." title:"Failed To Create Directory"
			)			
		)
		if ddl_BackupRootMode.selection > 1 do validateBackupPath edt_particleFilesBackupRoot.text
	)
	


	
	fn buildFilenameFromAdvancedPath =
	(
		local val = FranticParticles.GetProperty "ParticleFilesBase"
			
		if not matchPattern val pattern:"*\\" and not matchPattern val pattern:"*/" do val += "\\"
		
		
		local theNextVal = FranticParticles.GetProperty "ParticleFilesProject"
		if theNextVal != "" then
		(
			if not matchPattern theNextVal pattern:"*\\" and not matchPattern theNextVal pattern:"*/" do theNextVal += "\\"
			val += theNextVal
		)
		theNextVal = FranticParticles.GetProperty "ParticleFilesSequence"
		if theNextVal != "" then
		(
			if not matchPattern theNextVal pattern:"*\\" and not matchPattern theNextVal pattern:"*/" do theNextVal += "\\"
			val += theNextVal
		)
		theNextVal = FranticParticles.GetProperty "ParticleFilesTake"
		if theNextVal != "" then
		(
			if not matchPattern theNextVal pattern:"*\\" and not matchPattern theNextVal pattern:"*/" do theNextVal += "\\"
			val += theNextVal
		)			
		theNextVal = FranticParticles.GetProperty "ParticleFilesName"
		if theNextVal != "" then
		(
--				if not matchpattern (getFileNameFile theNextVal) pattern:"*_" then 
--					theNextVal = (getFileNameFile theNextVal) + "_" + getFileNameType theNextVal
			val += theNextVal
		)
		else
			val += "particles_.prt"
			
		checkValidSaveFileName val	
	)
	

	fn checkForValidBinFile =
	(
		local theMode = getIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "Preferences" "RealFlowBinFileSaving"
		if theMode == "3" then return true
		local theFileName = FranticParticles.GetProperty "ParticleFilesName" 
		if theFileName != "" and matchpattern (getFileNameType theFileName) pattern:".bin" then
		(
			local txt = getFileNameFile theFileName
			local theValues = #()
			for i = txt.count to 1 by -1 do 
			(
				if bit.charAsInt txt[i] >= 48 and bit.charAsInt txt[i] <= 57 then
					append theValues txt[i]
				else	
					exit
			)					
			if theValues.count < 5 then
			(
				local theResult = true
				if theMode == "1" then
				(
					local theWarning = "WARNING:\nRealFlow expects Particle BIN files to contain 5 trailing digits in the file name.\n"
					if  theValues.count == 1 then
						theWarning += "The file name you specified contains only one digit and does not satisfy this requirement.\n"
					else	if theValues.count == 0 then
						theWarning += "The file name you specified contains no digits and does not satisfy this requirement.\n"
					else
						theWarning += "The file name you specified contains only "+  theValues.count as string +" digits and does not satisfy this requirement.\n"
					theWarning += "The files you are about to generate would not be usable with RealFlow 4 and its related importers.\n"
					theWarning += "\nPress [Yes] to fix the file name automatically.\n"
					theWarning += "Press [No] to leave the file name as is.\n\n"
					theWarning += "This warning can be disabled in the Preferences rollout."
					
					theResult = querybox theWarning title:"Krakatoa Saving RealFlow4 BIN Files"
				)
				if theResult then
				(
					thePrefix = substring "00000" 1 (5-theValues.count)
					for i in theValues do thePrefix += i
					newName = substring txt 1 (txt.count-theValues.count) + thePrefix
					 FranticParticles.SetProperty "ParticleFilesName" (newName + ".bin")
					 buildFilenameFromAdvancedPath()
				)
			)	
		)
	)			
	
	fn setSaveFileControlsVisibility state enable:true = 
	(
		btn_BaseHistory.enabled = edt_particleFilesBase.enabled= btn_ExploreBase.enabled=  enable
		btn_ProjectHistory.enabled= edt_particleFilesProject.enabled= btn_ExploreProjectPath.enabled= enable
		btn_SequenceHistory.enabled= edt_particleFilesSequence.enabled= btn_ExploreSequencePath.enabled= enable
		btn_FilenameHistory.enabled= edt_particleFilesName.enabled= btn_getFilenameFromMax.enabled= enable
		btn_TakeHistory.enabled= edt_particleFilesTake.enabled=  btn_TakeMajorUp.enabled= btn_TakeMinorUp.enabled= btn_TakeUp.enabled= btn_ExploreTake.enabled= enable
		btn_TypePrt.enabled= btn_TypeCsv.enabled= btn_TypeBin.enabled= enable
	)
	
	fn refresh_GUI = 
	(
		tweakControlPositions()
		
		local enableSaveParticleFileControls = (FranticParticles.GetProperty "ParticleMode") == "Save Particles To File Sequence"
		
		edt_particleFiles.text = FranticParticles.GetProperty "ParticleFiles"
		resolveAdvancedPathStructure()
		
		local theVal = execute (FranticParticles.GetProperty "Partition:BackupRootMode")
		if theVal == OK do theVal = 1
		ddl_BackupRootMode.selection = theVal
		edt_particleFilesBackupRoot.text = FranticParticles.GetProperty "Partition:BackupRoot"
		edt_particleFilesBackupPath.text = getFilenameFromBackupRoot()
		ckb_skipExistingFiles.state = FranticParticles.GetBoolProperty "SkipExistingParticleFiles" 
		
		populateLists()	
		
		chk_saveLightingAsEmission.state = FranticParticles.GetBoolProperty "SaveLightingAsEmission"
		
		try(Krakatoa_GUI_Partition.refresh_GUI())catch()
		if Krakatoa_Initializing_Hidden_Rollouts == false do 
			Krakatoa_GUI_SaveParticles.open = FranticParticles.GetBoolProperty "GUI:SaveParticlesRolloutOpen" or enableSaveParticleFileControls 
	)	

	fn takeUp mode:#increment =
	(
		local theFile = FranticParticles.GetProperty "ParticleFiles" 
		if theFile != "" do
		(
			local theTake = FranticParticles.GetProperty "ParticleFilesTake" 
			local theValues = #()
			for i = theTake.count to 1 by -1 do 
			(
				if bit.charAsInt theTake[i] >= 48 and bit.charAsInt theTake[i] <= 57 then
					append theValues theTake[i]
				else	
					exit
			)	
			theValue = ""
			for i = theValues.count to 1 by -1 do theValue += theValues[i]
			case mode of
			(
			#increment: theValue = ((theValue as integer) + 1)
			#minor: (
					theValue = 10 * ((theValue as integer)/10) 
					theValue += 10
				)
			#major: (
					theValue = 100 * ((theValue as integer)/100) 
					theValue += 100
				)
			)
			if theValues.count == 0 then 
			(
				theBase = "v"
				theCount = 3
			)	
			else	
			(
				theBase = substring theTake 1 (theTake.count - theValues.count)
				theCount = theValues.count 
			)			
			FranticParticles.SetProperty "ParticleFilesTake" (edt_particleFilesTake.text = theBase + (FranticParticleRenderMXS.LeadingZeros theValue theCount) + (theValue as string) )
			buildFilenameFromAdvancedPath()
		)			
	)
	
	on btn_TakeUp pressed do takeUp mode:#increment
	on btn_TakeMinorUp pressed do takeUp mode:#minor
	on btn_TakeMajorUp pressed do takeUp mode:#major

	
	fn getFromKrakatoaHistory mode:#particleFiles theControl: searchKey: =
	(
		local st = timestamp()
		allPaths = #()
		allValues = #()		
		local thePathsCacheFile = Krakatoa_PresetsDirectory + "\\Paths_"+searchKey+".Cache"
		if not doesFileExist thePathsCacheFile do FranticParticleRenderMXS.rebuildPathsCache searchKey
		
		local theKeys = getIniSetting thePathsCacheFile searchKey
		for k in theKeys where not matchPattern k pattern:"*_Paths" do
		(
			append allValues k
			append allPaths (getIniSetting thePathsCacheFile searchKey ("("+k+")_Paths") )
		)
		pushPrompt ("Save Paths History Cache Loaded in "+ (((timestamp()-st)/1000.0) as string + " sec."))
		
		createDialog Krakatoa_GUI_History_Dialog 820 310 modal:true
		if historyValue != undefined do 
		(
			case mode of
			(
				#Files:
				(
					FranticParticles.SetProperty searchKey (theControl.text = historyValue)
					FranticParticles.SetProperty "ParticleMode" "Save Particles To File Sequence"
					refresh_GUI()		
					try(Krakatoa_GUI_Main.refresh_GUI())catch()
					resolveAdvancedPathStructure()			
				)
				#PreferencesPRT: ()
				default:
				(
					FranticParticles.SetProperty searchKey (theControl.text = historyValue)
					buildFilenameFromAdvancedPath ()			
				)	
			)	
		)	
	)
	
	on btn_particleFilesHistory pressed do 
	(
		getFromKrakatoaHistory mode:#Files theControl:edt_particleFiles searchKey:"ParticleFiles"
	)
	on btn_BaseHistory pressed do getFromKrakatoaHistory mode:#Base theControl:edt_particleFilesBase searchKey:"ParticleFilesBase"
	on btn_ProjectHistory pressed do getFromKrakatoaHistory mode:#Project theControl:edt_ParticleFilesProject searchKey:"ParticleFilesProject"
	on btn_SequenceHistory pressed do getFromKrakatoaHistory mode:#Sequence theControl:edt_ParticleFilesSequence searchKey:"ParticleFilesSequence"
	on btn_TakeHistory pressed do getFromKrakatoaHistory mode:#Take theControl:edt_ParticleFilesTake searchKey:"ParticleFilesTake"
	on btn_FilenameHistory pressed do getFromKrakatoaHistory mode:#Name theControl:edt_ParticleFilesName searchKey:"ParticleFilesName"
	
	on btn_getFilenameFromMax pressed do
	(
		FranticParticles.SetProperty "ParticleFilesName"  (edt_particleFilesName.text = if maxFileName == "" then "particles_" else ((getFileNameFile maxFileName)+"_"))
		buildFilenameFromAdvancedPath ()	
	)
	
	on edt_particleFiles entered val do 
	(
		if val == "" then
		(
			FranticParticles.SetProperty "ParticleFiles" ""
			FranticParticles.SetProperty "ParticleFilesBase" ""
			FranticParticles.SetProperty "ParticleFilesProject" ""
			FranticParticles.SetProperty "ParticleFilesSequence" ""
			FranticParticles.SetProperty "ParticleFilesTake" ""
			FranticParticles.SetProperty "ParticleFilesName" ""
			edt_particleFiles.text = edt_particleFilesBase.text = edt_particleFilesProject.text = edt_particleFilesSequence.text = edt_particleFilesTake.text = edt_particleFilesName.text = ""
			refresh_GUI()
		)
		else
		(
			checkValidSaveFileName val 
			checkForValidBinFile()
		)
	)	
	on edt_particleFilesBase entered txt do 
	(
		FranticParticles.SetProperty "ParticleFilesBase" (trimRight (trimLeft txt)) 
		buildFilenameFromAdvancedPath()
	)
	on edt_particleFilesProject entered txt do 
	(
		FranticParticles.SetProperty "ParticleFilesProject" (trimRight (trimLeft txt))
		buildFilenameFromAdvancedPath()
	)
	on edt_particleFilesSequence entered txt do 
	(
		FranticParticles.SetProperty "ParticleFilesSequence" (trimRight (trimLeft txt))
		buildFilenameFromAdvancedPath()
	)
	on edt_particleFilesTake entered txt do 
	(
		FranticParticles.SetProperty "ParticleFilesTake" (trimRight (trimLeft txt))
		buildFilenameFromAdvancedPath()
	)
	on edt_particleFilesName entered txt do 
	(
		local theVal = trimRight (trimLeft txt)
		theVal = (filterString theVal "\\/?*!" )[1] 
		if theVal == undefined do theVal = "Particles"
		FranticParticles.SetProperty "ParticleFilesName" theVal
		edt_particleFilesName.text = theVal
		buildFilenameFromAdvancedPath()
		checkForValidBinFile()
	)
	
	fn particleFiles_Pressed_FN =
	(
		local rootName = (FranticParticles.GetProperty "ParticleFiles")
		rootNameBase = getFileNamePath rootName + getFileNameFile rootName 
		if rootName == "" do 
			rootNameBase= (getIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "Preferences" "DefaultLoaderPath") + "particles_"
			
		local newParticleFiles = case (substring (getFileNameType rootName) 2 -1 )  as name of
		(
			default: getSaveFileName caption:"Select the Particle File Sequence to Save" filename:rootNameBase types:"Thinkbox Particle Files (*.prt)|*.prt|Comma Separated Value (*.csv)|*.csv|RealFlow 4 (*.bin)|*.bin" history:"KrakatoaParticles"
			#csv: getSaveFileName caption:"Select the Particle File Sequence to Save" filename:rootNameBase types:"Comma Separated Value (*.csv)|*.csv|Frantic Particle Files (*.prt)|*.prt|RealFlow 4 (*.bin)|*.bin" history:"KrakatoaParticles"
			#bin: getSaveFileName caption:"Select the Particle File Sequence to Save" filename:rootNameBase types:"RealFlow 4 (*.bin)|*.bin|Frantic Particle Files (*.prt)|*.prt|Comma Separated Value (*.csv)|*.csv" history:"KrakatoaParticles"
		)
		if newParticleFiles != undefined do 
		(
			theFileName = getFileNameFile newParticleFiles
--				if not matchpattern theFileName pattern:"*_" do newParticleFiles = getFileNamePath newParticleFiles + theFileName + "_" + getFileNameType newParticleFiles
			FranticParticles.SetProperty "ParticleFiles" newParticleFiles
			FranticParticles.SetProperty "ParticleMode" "Save Particles To File Sequence"
			Krakatoa_GUI_Main.refresh_GUI()
			checkForValidBinFile()
			refresh_GUI()
		)	
	)
	on btn_particleFiles pressed do 
	(
		particleFiles_Pressed_FN()
	)

	fn changePrtFileType theType =
	(
		theFileName = FranticParticles.GetProperty "ParticleFilesName" 
		if theFileName != "" then
		(
			FranticParticles.SetProperty "ParticleFilesName" (getFileNameFile theFileName + theType )
			buildFilenameFromAdvancedPath()
		)	
	)
	on btn_TypePrt pressed do changePrtFileType ".prt"
	on btn_TypeCsv pressed do changePrtFileType ".csv"
	on btn_TypeBin pressed do 
	(
		changePrtFileType ".bin"
		checkForValidBinFile()
	)	
	
	
	fn explorePath thePath =
	(
		if doesFileExist thePath then 
			shelllaunch "explorer.exe" thePath
		else
			messagebox ("The Specified Path \n"+ thePath +"\nDoes Not Exist Yet.") title:"Krakatoa: Explore Path"		
	)
	
	on btn_ExploreSavePath pressed do
	(
		explorePath (getFileNamePath edt_particleFiles.text)
	)

	
	on btn_ExploreBase pressed do
	(	
		explorePath (FranticParticles.GetProperty "ParticleFilesBase")
	)
	
	on btn_ExploreProjectPath pressed do
	(	
		val = (FranticParticles.GetProperty "ParticleFilesBase")
		if matchPattern val pattern:"*/" do val[val.count] = "\\"
		if not matchPattern val pattern:"*\\" do val += "\\"
		val += (FranticParticles.GetProperty "ParticleFilesProject")
		explorePath val 
	)	

	on btn_ExploreSequencePath pressed do
	(	
		val = (FranticParticles.GetProperty "ParticleFilesBase")
		if matchPattern val pattern:"*/" do val[val.count] = "\\"
		if not matchPattern val pattern:"*\\" do val += "\\"
		nextval = (FranticParticles.GetProperty "ParticleFilesProject")
		if nextval != "" do
		(
			if matchPattern nextval pattern:"*/" do nextval[nextval.count] = "\\"
			if not matchPattern nextval pattern:"*\\" do nextval += "\\"
			val += nextval
		)
		nextval = (FranticParticles.GetProperty "ParticleFilesSequence")
		if nextval != "" do
		(
			if matchPattern nextval pattern:"*/" do nextval[nextval.count] = "\\"
			if not matchPattern nextval pattern:"*\\" do nextval += "\\"
			val += nextval
		)
		explorePath val 
	)	

	on btn_ExploreTake pressed do
	(	
		val = (FranticParticles.GetProperty "ParticleFilesBase")
		if matchPattern val pattern:"*/" do val[val.count] = "\\"
		if not matchPattern val pattern:"*\\" do val += "\\"
		nextval = (FranticParticles.GetProperty "ParticleFilesProject")
		if nextval != "" do
		(
			if matchPattern nextval pattern:"*/" do nextval[nextval.count] = "\\"
			if not matchPattern nextval pattern:"*\\" do nextval += "\\"
			val += nextval
		)
		nextval = (FranticParticles.GetProperty "ParticleFilesSequence")
		if nextval != "" do
		(
			if matchPattern nextval pattern:"*/" do nextval[nextval.count] = "\\"
			if not matchPattern nextval pattern:"*\\" do nextval += "\\"
			val += nextval
		)
		nextval = (FranticParticles.GetProperty "ParticleFilesTake")
		if nextval != "" do
		(
			if matchPattern nextval pattern:"*/" do nextval[nextval.count] = "\\"
			if not matchPattern nextval pattern:"*\\" do nextval += "\\"
			val += nextval
		)			
		explorePath val 
	)		

	on ddl_BackupRootMode selected itm do 
	(
		FranticParticles.SetProperty "Partition:BackupRootMode" (itm as string)
		if itm > 1 do validateBackupPath edt_particleFilesBackupRoot.text
	)
	on edt_particleFilesBackupRoot entered txt do validateBackupPath txt

	on btn_particleFilesBackup pressed do
	(
		local theBackupRoot = getSavePath caption:"Krakatoa: Select Backup Root" initialDir:(FranticParticles.GetProperty "Partition:BackupRoot")
		if theBackupRoot != undefined do
		(
			validateBackupPath theBackupRoot
		)
	)
	
	on btn_ExploreBackupRoot pressed do
	(	
		explorePath edt_particleFilesBackupRoot.text
	)		
	on btn_ExploreBackupPath pressed do
	(	
		explorePath edt_particleFilesBackupPath.text
	)	


	on Krakatoa_GUI_SaveParticles close do 
	(
		if Krakatoa_GUI_SaveParticles.inDialog and not Krakatoa_Closing_Floater and not Krakatoa_Initializing_Hidden_Rollouts then
		(
			setIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "RolloutVisible" Krakatoa_GUI_SaveParticles.title "false"
			FranticParticleRenderMXS.floatOrDockRollout Krakatoa_GUI_SaveParticles forceMode:#hide
			Krakatoa_CustomizeRollouts_Dialog.Refresh_GUI()
		)	
	)	
	
	fn updateIcons =
	(
		btn_LoadSave_SaveParticles.images = #(Krakatoa_PresetsArrowBitmap,Krakatoa_PresetsArrowBitmap, 32,3,3,3,3)		
		btn_Float_Rollout.images = #(Krakatoa_PresetsArrowBitmap,Krakatoa_PresetsArrowBitmap, 32,4,4,4,4)

		btn_particleFilesHistory.images = #(Krakatoa_PresetsArrowBitmap,Krakatoa_PresetsArrowBitmap, 32,10,10,10,10)
		btn_particleFiles.images = #(Krakatoa_PresetsArrowBitmap,Krakatoa_PresetsArrowBitmap, 32,11,11,11,11)
		
		btn_BaseHistory.images = #(Krakatoa_PresetsArrowBitmap,Krakatoa_PresetsArrowBitmap, 32,10,10,10,10)
		btn_ProjectHistory.images = #(Krakatoa_PresetsArrowBitmap,Krakatoa_PresetsArrowBitmap, 32,10,10,10,10)
		btn_SequenceHistory.images = #(Krakatoa_PresetsArrowBitmap,Krakatoa_PresetsArrowBitmap, 32,10,10,10,10)
		btn_TakeHistory.images = #(Krakatoa_PresetsArrowBitmap,Krakatoa_PresetsArrowBitmap, 32,10,10,10,10)
		btn_FilenameHistory.images = #(Krakatoa_PresetsArrowBitmap,Krakatoa_PresetsArrowBitmap, 32,10,10,10,10)
		
		btn_ExploreSavePath.images = #(Krakatoa_PresetsArrowBitmap,Krakatoa_PresetsArrowBitmap, 32,12,12,12,12)
		btn_ExploreBase.images = #(Krakatoa_PresetsArrowBitmap,Krakatoa_PresetsArrowBitmap, 32,12,12,12,12)
		btn_ExploreProjectPath.images = #(Krakatoa_PresetsArrowBitmap,Krakatoa_PresetsArrowBitmap, 32,12,12,12,12)
		btn_ExploreSequencePath.images = #(Krakatoa_PresetsArrowBitmap,Krakatoa_PresetsArrowBitmap, 32,12,12,12,12)
		btn_ExploreTake.images = #(Krakatoa_PresetsArrowBitmap,Krakatoa_PresetsArrowBitmap, 32,12,12,12,12)
		
		btn_ExploreBackupRoot.images = #(Krakatoa_PresetsArrowBitmap,Krakatoa_PresetsArrowBitmap, 32,12,12,12,12)
		btn_ExploreBackupPath.images = #(Krakatoa_PresetsArrowBitmap,Krakatoa_PresetsArrowBitmap, 32,12,12,12,12)
		
		btn_BackupRootHistory.images = #(Krakatoa_PresetsArrowBitmap,Krakatoa_PresetsArrowBitmap, 32,10,10,10,10)
		btn_particleFilesBackup.images = #(Krakatoa_PresetsArrowBitmap,Krakatoa_PresetsArrowBitmap, 32,11,11,11,11)
		

		btn_ChannelAdd.images = #(Krakatoa_PresetsArrowBitmap,Krakatoa_PresetsArrowBitmap, 32,6,6,8,8)
		btn_ChannelRemove.images = #(Krakatoa_PresetsArrowBitmap,Krakatoa_PresetsArrowBitmap, 32,7,7,9,9)
		
		btn_addNewChannel.images = #(Krakatoa_PresetsArrowBitmap,Krakatoa_PresetsArrowBitmap, 32,13,13,13,13)
		btn_removeChannel.images = #(Krakatoa_PresetsArrowBitmap,Krakatoa_PresetsArrowBitmap, 32,14,14,14,14)		
		
		btn_ChannelPresets.images = #(Krakatoa_PresetsArrowBitmap,Krakatoa_PresetsArrowBitmap, 32,1,1,2,2) 		
	)

	on Krakatoa_GUI_SaveParticles open do 
	(
		updateIcons()
		
		Krakatoa_CustomizeRollouts_Dialog.Refresh_GUI()
		
		Refresh_GUI()
		FranticParticles.LogDebug ("+Save Particles Rollout OPENED.")			
	)			
)
--------------------------------------------------------------------------------------------------------------------------------------------------------------------	
--PARTICLE CHANNELS ROLLOUT 
--------------------------------------------------------------------------------------------------------------------------------------------------------------------	

rollout Krakatoa_GUI_Channels "Memory Channels" rolledup:true category:30 width:457
(	
	local activeMemChannels = #()
	local inactiveMemChannels = #()
	
	local MemoryBytesPerParticle = 38

	local RAMdisplay = 3
	
	button btn_LoadSave_Channels "<>" across:4 align:#left width:20 height:16 offset:[-10,-5] tooltip:"Load and Save Presets For This Rollout Only" 
	button btn_Help_Channels  "Open Online Help..." width:100 height:16 align:#center offset:[-100,-5] tooltip:"Opens the Krakatoa Online Help for the Channels rollout in the default Web Browser. Requires Internet connection."
	button btn_BackTo_Main "Back To Main Controls..." height:16 width:308 offset:[-3,-5] align:#center tooltip:"Closes the rollout and sets focus on\nthe Main Controls rollout."
	button btn_Float_Rollout ">" height:16 width:20 offset:[10,-5] align:#right tooltip:"Float/Dock the Rollout.\nRight-Click for Menu..." 
	
	
	
	on btn_BackTo_Main pressed do
	(
		Krakatoa_GUI_Channels.open = false
		FranticParticleRenderMXS.BackToMainControls()
	)	
	on btn_BackTo_Main rightclick do
	(
		Krakatoa_GUI_Channels.open = false
		FranticParticleRenderMXS.BackToMainControls()
	)		
	
	on btn_LoadSave_Channels pressed do 
	(
		Krakatoa_RCMenu_Struct.Float_Rollout_RCMenu_CurrentRollout = Krakatoa_GUI_Channels
		popupMenu Krakatoa_RCMenu_Struct.Load_Save_Rollout_RCMenu pos:mouse.screenpos
	)	
	on btn_LoadSave_Channels rightClick do 
	(
		Krakatoa_RCMenu_Struct.Float_Rollout_RCMenu_CurrentRollout = Krakatoa_GUI_Channels
		popupMenu Krakatoa_RCMenu_Struct.Load_Save_Rollout_RCMenu pos:mouse.screenpos
	)		
	
	on btn_Float_Rollout pressed do
	(
		FranticParticleRenderMXS.FloatRolloutButtonPressed Krakatoa_GUI_Channels
	)		
	on btn_Float_Rollout rightClick do
	(
		Krakatoa_RCMenu_Struct.Float_Rollout_RCMenu_CurrentRollout = Krakatoa_GUI_Channels
		popupMenu Krakatoa_RCMenu_Struct.Float_Rollout_RCMenu pos:mouse.screenpos
	)			
	
	on Krakatoa_GUI_Channels moved pos do
	(
		setIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "RolloutDialogPositions" Krakatoa_GUI_Channels.title (pos as string)
		Krakatoa_CustomizeRollouts_Dialog.updateStripsPositions pos
	)		

	group "Particle Channels To Load Into Memory    + Cached   -- NOT Cached "
	(
		multilistbox lbx_allMemoryChannels " Inactive Channels:" items:#() height:15 across:2 width:204 align:#left offset:[0,-3]
		multilistbox lbx_activeMemoryChannels " Active Channels:" items:#() height:15 width:205 align:#right offset:[0,-3]
	)
	
	button btn_memmake16 "16" width:20 height:35 alignt:#center offset:[0,-150] tooltip:"Switch the Selected Channels To 16 bit Precision." 
	button btn_memmake32 "32" width:20 height:35 alignt:#center offset:[0,-3] tooltip:"Switch the Selected Channels To 32 bit Precision."
	button btn_memmake64 "64" width:20 height:50 alignt:#center offset:[0,15] visible:false tooltip:"Switch the Selected Channels To 64 bit Precision." 

	group "Cache Information"
	(
		label lbl_CurrentCache "" offset:[0,-3] align:#left
		progressbar prg_CacheIndicator width:30 height:18 value:100 align:#left across:2
		label lbl_CacheDescription "" align:#left offset:[-180,3]
		listbox lbx_changesinfo items:#() width:440 height:5 align:#center
	)
	
	group "Suggested Initial Memory When Final Particle Count Cannot Be Determined"
	(
		checkbutton chk_UsePreAllocation ">Pre-Allocate Memory" width:210 across:4 offset:[5,-2]
		spinner spn_PreAllocationParticleCount "for " range:[1,10000000,10] type:#float fieldwidth:90 offset:[110,0] align:#center
		button btn_PreAllocationCountPresets ">>" width:22 height:18 align:#right offset:[32,-1] tooltip:"Set Pre-Allocation Particle Count to a Preset Value, or Add/Remove current value to/from the Presets." 
		label lbl_PreAllocationParticleCount "Million Particles." offset:[5,1] align:#right
	)

	group "Particle Count / Memory Calculator"
	(
		spinner spn_particleCount "" range:[0,10000000,1] type:#float across:6 fieldwidth:90 offset:[0,0] align:#left
		button btn_countPresets ">>" width:22 height:18 align:#right offset:[-18,-1] tooltip:"Set Particle Count to a Preset Value, or Add/Remove current value to/from the Presets." 
		label lbl_particleCount "Million Particles Require" offset:[10,2]
		spinner spn_MemoryUsage "" range:[0,1000000,3000] type:#float fieldwidth:90 offset:[66,0] align:#right
		button btn_memoryPresets ">>" width:22 height:18 align:#right offset:[18,-1] tooltip:"Set Memory to a Preset Value, or Add/Remove current value to/from the Presets." 
		button btn_RAM "GB Memory." align:#right height:18 offset:[10,-1] width:63 tooltip:"Click to cycle the Memory display between GigaBytes and MegaBytes."
	)
	group "Memory Usage / Image Buffers / Multi-Threading Report"
	(
		dotNetControl dnc_imageBuffersReport "System.Windows.Forms.TextBox" width:440 height:130 offset:[0,-4] align:#center 
		spinner spn_FrameBufferAvailPhysMemoryFraction "Percentage of Available Memory for Image Buffers:" align:#right fieldwidth:40 range:[1,100,70] scale:1.0 tooltip:"Defines the percentage of available physical memory to use for Image Buffers.\n\nOne Image Buffer will be allocated per output per thread, and can consume a lot of memory at high output resolutions with many threads.\n\nReduce this valie if memory cannot be allocated during rendering."
		spinner spn_RenderThreadLimit "Render Threads Limit (0=No Limit):" range:[0,16,0] fieldwidth:40 offset:[0,-2]  type:#integer align:#right tooltip:"Caps the number of Lighting Pass and Final Pass Drawing threads even if memory and core count allow for more threads.\n\nSet to 0 to use all threads determined by Krakatoa." --across:2 offset:[192,0] 
		button btn_updateReport "Refresh Report" width:112 height:35 align:#left offset:[0,-40] 
	)
	
	button btn_KrakatoaMemoryUsed "" pos:[330,37] width:112 height:17 tooltip:"Press to Updated the Memory Channels and Bytes/Particle Display."
	
	fn updateImageBuffersReport =
	(
		try
		(
			dnc_imageBuffersReport.multiline = true
			dnc_imageBuffersReport.Clear()
			dnc_imageBuffersReport.ReadOnly =  true
			local theForeColor = (colorman.getColor #windowtext) * 255
			dnc_imageBuffersReport.ForeColor = dnc_imageBuffersReport.ForeColor.fromARGB theForeColor.x theForeColor.y theForeColor.z			
			
			local multiThread_Loading = FranticParticles.GetBoolProperty "Performance:MT:Loading"
			local multiThread_Sorting = FranticParticles.GetBoolProperty "Performance:MT:Sorting"
			local multiThread_Lighting = FranticParticles.GetBoolProperty "Performance:MT:Lighting"
			local multiThread_Drawing = FranticParticles.GetBoolProperty "Performance:MT:Drawing"		
			
			renderSceneDialog.commit()
			local memoryInfo = sysinfo.getSystemMemoryInfo()
			local txt = "" as stringStream
			
			format "% MB Installed Physical Memory, % Threads Maximum%.\r\n" (memoryInfo[2]/1024.0/1024) (sysinfo.cpucount) (if spn_RenderThreadLimit.value != 0 and sysinfo.cpucount > spn_RenderThreadLimit.value then (", Limited to "+spn_RenderThreadLimit.value as string) else "") to:txt
			local mttext = ""
			if not multiThread_Loading do mttext += " Loading" 
			if not multiThread_Sorting do 
			(
				if mttext.count > 0 do mttext += "," 
				mttext += " Sorting" 
			)
			if not multiThread_Lighting do 
			(
				if mttext.count > 0 do mttext += "," 
				mttext +=" Lighting" 
			)
			if not multiThread_Drawing do 
			(
				if mttext.count > 0 do mttext += " and" 
				mttext +=" Drawing" 
			)
			if mttext.count > 0 do format "Multi-Threaded% Disabled.\r\n" mttext to:txt
			
			local theMem = (FranticParticleRenderMXS.calculateMemoryUsage activeMemChannels)
			local particleMemoryInMB = ((theMem[1]+theMem[2]) * spn_particleCount.value * 1000000) / 1024^2
			local theCacheMemory = try((FranticParticles.getCacheSize()) )catch(0) --current cache memory will be available at render time, so we need to add it to what the OS gives us as free memory...
			local freeMemory = (memoryInfo[3]/1024.0^2)+theCacheMemory
			local freeMemoryAfterParticles = (freeMemory-particleMemoryInMB)
			format "% MB Free Physical Memory, % MB after loading % Million Particles.\r\n" freeMemory freeMemoryAfterParticles spn_particleCount.value to:txt
			if  freeMemoryAfterParticles < 0 then
			(
				theColor = (colorman.getColor #window) * [290,225,225]
				format "% Million Particles CANNOT FIT in the Available Free Memory!\r\n" spn_particleCount.value to:txt
				format "Please reduce the Particle Count or free up some Memory!\r\n" to:txt
			)
			else
			(
			
				local memoryPerBuffer = ((renderWidth*renderHeight*24.0)/1024^2)
				format "%x% Output Resolution, % MB Memory Per Image Buffer.\r\n"  renderWidth  renderHeight memoryPerBuffer to:txt 
				
				local imageBuffersCount = 1
				local re = maxops.getRenderElementMgr #production
				if re.GetElementsActive() do
				(
					for i = 0 to (re.NumRenderElements()-1) do
					(
						local el =re.getRenderElement i		
						if el.enabled do imageBuffersCount+=1
					)
				)
				local totalBufferMemory = (memoryPerBuffer*imageBuffersCount)
				local imageBuffersString = imageBuffersCount as string + " Image Buffer"+ (if imageBuffersCount == 1 then "" else "s")
				format "% MB Total Memory for %\r\n" totalBufferMemory imageBuffersString to:txt
				
				local memoryFraction = FranticParticles.GetFloatProperty "FrameBufferAvailPhysMemoryFraction"
				local allowedMemoryForImageBuffers = (freeMemory-particleMemoryInMB) * memoryFraction
				local possibleThreads = (floor (allowedMemoryForImageBuffers/totalBufferMemory)) as integer
				if possibleThreads > sysinfo.cpucount do possibleThreads = sysinfo.cpucount
				if spn_RenderThreadLimit.value != 0 and possibleThreads > spn_RenderThreadLimit.value	do possibleThreads = spn_RenderThreadLimit.value
				if not multiThread_Drawing do possibleThreads = 1
				local theColor = (colorman.getColor #window) * [225,290,225]
				if possibleThreads < 1 then
				(
					theColor = (colorman.getColor #window) * [290,225,225]
					format "NO Image Buffers can fit in % MB (%\%) of Free Memory !\r\n" allowedMemoryForImageBuffers (memoryFraction*100.0) to:txt
					format "Please reduce the Particle Count, the Resolution,\r\n" to:txt
					format "%or free up some Memory!\r\n" (if imageBuffersCount > 1 then "remove some Render Elements, " else "") to:txt
				)
				else	
				(
					format "% Thread% with % each can fit in % MB (%\%) of Free Memory.\r\n" possibleThreads (if possibleThreads == 1 then "" else "s") imageBuffersString allowedMemoryForImageBuffers (memoryFraction*100.0)  to:txt
				)
			)
			dnc_imageBuffersReport.BackColor = dnc_imageBuffersReport.BackColor.fromARGB theColor.x theColor.y theColor.z
			dnc_imageBuffersReport.paste(txt as string)
		)catch()
	)
		
	on spn_FrameBufferAvailPhysMemoryFraction changed val do 
	(
		FranticParticles.setProperty "FrameBufferAvailPhysMemoryFraction" ((val/100.0) as string)
		updateImageBuffersReport()
	)
	on spn_RenderThreadLimit changed val do 
	(
		FranticParticles.SetProperty "RenderThreadLimit" (val as string)
		updateImageBuffersReport()
	)
	
	on btn_updateReport pressed do updateImageBuffersReport()

	
	fn updateMemoryCalculator =
	(
		btn_RAM.text = case RAMdisplay of
		(
			3: "GB Memory"
			2: "MB Memory"
		)		
		local theMem = (FranticParticleRenderMXS.calculateMemoryUsage activeMemChannels)
		spn_MemoryUsage.value = ((theMem[1]+theMem[2]) * spn_particleCount.value * 1000000) / 1024^RAMdisplay
		updateImageBuffersReport()
	)
	
	on spn_particleCount changed val do
	(
		updateMemoryCalculator()
		FranticParticles.SetProperty "ParticleCountMemoryCalculator:Count" (spn_particleCount.value as string)
	)
	
	on spn_MemoryUsage changed val do
	(
		local theMem = (FranticParticleRenderMXS.calculateMemoryUsage activeMemChannels)
		spn_particleCount.value = (val*(1024^RAMdisplay) / (theMem[1]+theMem[2])) * 0.000001
	)
	
	on btn_RAM pressed do
	(
		RAMdisplay -= 1
		if RAMdisplay < 2 do RAMdisplay = 3
		updateMemoryCalculator()
	)
	
	
	fn updateMemChannels = 
	(
		FranticParticleRenderMXS.IsCacheValid() 
		inactiveMemChannels = #(
			#("Lighting", undefined, 3),
			#("Velocity", undefined, 3),
			#("Emission", undefined, 3),
			#("Absorption", undefined, 3)	,
			#("Tangent", undefined, 3),
			#("Normal", undefined, 3),
			#("MBlurTime", undefined, 1),
			#("Eccentricity", undefined, 1),
			#("SpecularPower", undefined, 1),
			#("SpecularLevel", undefined, 1),
			#("SpecularGlossiness", undefined, 1),
			#("SpecularShift", undefined, 1)	,
			#("Specular2Level", undefined, 1)	,
			#("Specular2Glossiness", undefined, 1),
			#("Specular2Shift", undefined, 1),
			#("GlintLevel", undefined, 1),
			#("GlintSize", undefined, 1),
			#("GlintGlossiness", undefined, 1),
			#("DiffuseLevel", undefined, 1),
			
			#("TextureCoord", undefined, 3),
			#("MXSVector", undefined, 3),
			#("MXSFloat", undefined, 1),
			#("MXSInteger", undefined, 1),
			
			#("Scale", undefined, 3),
			#("Acceleration", undefined, 3),
			#("DensityGradient", undefined, 3),
			#("SignedDistance", undefined, 1),
			#("Fire", undefined, 1),
			#("Fuel", undefined, 1),
			#("Temperature", undefined, 1),
			#("Age", undefined, 1),
			#("LifeSpan", undefined, 1),
			#("ID", undefined, 1),
			#("MtlIndex", undefined, 1)
		)	
		
		for i = 2 to 99 do 
		(
			append inactiveMemChannels #("Mapping"+i as string, undefined, 3)
		)
		
		for i = 1 to inactiveMemChannels.count do
		(
			theName = inactiveMemChannels[i][1]
			if theName == "Eccentricity" do theName = "PhaseEccentricity"
			inactiveMemChannels[i][2] = try(FranticParticles.getProperty ("Memory:Channel:"+theName))catch("???")
		)
		
		activeMemChannels = try(FranticParticles.GetRenderParticleChannels())catch(#()) 
		
		activeMemChannelNames = for i in activeMemChannels collect i[1]
		
		for i = inactiveMemChannels.count to 1 by -1 do
		(
			if findItem activeMemChannelNames inactiveMemChannels[i][1] > 0 do deleteItem inactiveMemChannels i
		)
		
		lbx_allMemoryChannels.items = for i in inactiveMemChannels collect 
		(
			local isCached = if FranticParticles.getCacheSize() == 0.0 then "-- " else
				if findItem Krakatoa_GUI_Main.theCachedChannelsArray i[1] > 0 then "+ " else "-- "
			if i[3] == 1 then
				(isCached + i[1] + "  :  " + i[2] )
			else
				(isCached + i[1] + "  :  " + i[2] + "[" + i[3] as string  + "]")
		)

		lbx_activeMemoryChannels.items = for i in activeMemChannels collect 
		(
			local isCached = if FranticParticles.getCacheSize() == 0.0 then "-- " else
				if findItem Krakatoa_GUI_Main.theCachedChannelsArray i[1] > 0 then "+ " else "-- "
			if i[3] == 1 then
				(isCached + i[1] + "  :  " + i[2])
			else
				(isCached + i[1] + "  :  " + i[2] + "[" + i[3] as string + "]")
		)
		
		local theMemPerParticle = FranticParticleRenderMXS.calculateMemoryUsage activeMemChannels
		local txt = "Bytes/Particle:"+ theMemPerParticle[1] as string
		if theMemPerParticle[2] > 0 do txt += "(+"+theMemPerParticle[2] as string + "?)"
		btn_KrakatoaMemoryUsed.text = txt
		
		--MemoryBytesPerParticle = (FranticParticleRenderMXS.calculateMemoryUsage activeMemChannels )		
		--btn_KrakatoaMemoryUsed.text = "Bytes/Particle:"+ MemoryBytesPerParticle as string
		updateMemoryCalculator()
		--spn_particleCount.changed spn_particleCount.value
		
		--lbl_MemoryUsed.text = "Bytes/Particle:"+ (FranticParticleRenderMXS.calculateMemoryUsage activeChannels) as string

		
		local theCount = try((FranticParticles.GetCachedParticleCount()) )catch(0)
		local theMemory = try((FranticParticles.getCacheSize()) )catch(0)
		local txt = if FranticParticles.GetBoolProperty "EnableParticleCache" then "PCache ON - " else "PCache OFF - "
		txt += if FranticParticles.GetBoolProperty "EnableLightingCache" then "LCache ON - " else "LCache OFF - "
		
		lbl_currentCache.text = txt += FranticParticleRenderMXS.addCommas (theCount as string) + " Particles Using " + theMemory as string+ " MB In Memory"
		
		prg_CacheIndicator.color = Krakatoa_GUI_Main.prg_cacheStatus.color
		lbl_CacheDescription.text = case FranticParticleRenderMXS.IsCacheValid() of
		(
			default:"EMPTY Cache, no particles have been loaded."
			#valid: "VALID Cache, all required Particle Channels have been allocated."
			#validchanged: "VALID Cache, but changes to these settings will be IGNORED when PCache is ON:"
			#invalid: "INVALID Cache, required Particle Channels are missing and will cause a RELOAD."
		)
		
		if prg_CacheIndicator.color == green then
			lbx_changesinfo.items = #()
		else
		(
			lbx_changesinfo.items = FranticParticleRenderMXS.getChangedCacheableProperties()
			lbx_changesinfo.selection = lbx_changesinfo.items.count
		)
	)

	on btn_KrakatoaMemoryUsed pressed do updateMemChannels()
	
	fn changeMemoryChannelTo type =
	(
		for i in lbx_activeMemoryChannels.selection do
		(
			local theName = activeMemChannels[i][1]
			if theName == "Eccentricity" do theName = "PhaseEccentricity"
			try ( FranticParticles.setProperty ("Memory:Channel:"+theName) type )catch()
		)
		for i in lbx_allMemoryChannels.selection do
		(
			local theName = inactiveMemChannels[i][1]
			if theName == "Eccentricity" do theName = "PhaseEccentricity"
			try ( FranticParticles.setProperty ("Memory:Channel:"+theName) type )catch()
		)
		updateMemChannels()		
	)
	
	fn createPresetsRCMenu type:#memory =
	(
		case type of
		(
			#memory : (
						presetName = "ParticleCountCalculatorMB"
						theSpinner = "spn_MemoryUsage"
					)	
			#count: (
						presetName = "MemoryCalculator"
						theSpinner = "spn_ParticleCount"
					)	
			#preallocationcount: (
						presetName = "MemoryPreAllocationCount"
						theSpinner = "spn_PreAllocationParticleCount"
						theDefaultsKey = "Memory:PreAllocation:ParticleCountInMillions" 
					)	
		)
		
		local presetsList = #()
		local theKeys = for i in (getIniSetting (Krakatoa_PresetsDirectory + "//KrakatoaPreferences.ini") presetName  ) collect (execute i)
		sort theKeys 
		if theKeys.count == 0 then 
		(
			theKeys = case type of
			(
				#memory: #(1024.0,2048.0,4096.0,6144.0,8192.0,12288.0,16384.0,24576.0,32768.0,49152.0,65536.0,98304.0,131072.0)
				#count: #(1.0,5.0,10.0,20.0,30.0,40.0,50.0,100.0,200.0,500.0,1000.0)
				#preallocationcount: #(10.0,20.0,30.0,40.0,50.0,100.0,200.0,500.0,1000.0)
			)
			for i in theKeys do
				setIniSetting (Krakatoa_PresetsDirectory + "//KrakatoaPreferences.ini") presetName (i as string) (i as string)
		)
		
		for k in theKeys do if findItem presetsList k == 0 do append presetsList k
		if type == #memory and RAMdisplay == 3 do 
			presetsList = for k in presetsList collect k /= 1024.0

		theValue = execute ("Krakatoa_GUI_Channels."+ theSpinner +".value")
		local txt = stringStream ""
		format "rcmenu Presets_RCMenu\n(\n" to:txt
		
		if type == #preallocationcount do 
		(
			format  "menuItem mnu_CopyToCalculator \"Copy [%] To Calculator\"\n" theValue to:txt
			format  "on mnu_CopyToCalculator picked do  Krakatoa_GUI_Channels.spn_ParticleCount.changed (Krakatoa_GUI_Channels.spn_ParticleCount.value = %)\n" theValue to:txt
			format  "separator spr_02\n" 		 to:txt

			local currentDefault = getIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaDefaults.ini") "Defaults" theDefaultsKey
			if currentDefault == "" do currentDefault = "--Not Set--"
		)
		if type == #count do 
		(
			format  "menuItem mnu_CopyToPreAllocation \"Copy [%] To Pre-Allocation Count\"\n" theValue  to:txt
			format  "on mnu_CopyToPreAllocation picked do Krakatoa_GUI_Channels.spn_PreAllocationParticleCount.changed (Krakatoa_GUI_Channels.spn_PreAllocationParticleCount.value = %) \n" theValue to:txt
			format  "separator spr_02\n" 			 to:txt
		)		
		
		if findItem presetsList theValue == 0 do 
		(
			format  "menuItem mnu_AddPreset \"Add [%]\"\n" theValue to:txt
			if type == #memory and RAMdisplay == 3 do theValue *= 1024.0
			format  "on mnu_AddPreset picked do setIniSetting (Krakatoa_PresetsDirectory + \"//KrakatoaPreferences.ini\") \"%\" \"%\" \"%\" \n" presetName theValue theValue to:txt
			format  "separator spr_05\n"  to:txt
		)	
		
		cnt = 0
		for i in presetsList do
		(
			local theValue = i
			cnt += 1
			/*if type == #memory do
			(
				if RAMdisplay == 3 do theValue /= 1024.0
			)*/
			format  "menuItem mnu_preset% \"%\" \n" cnt theValue to:txt
			format  "on mnu_preset% picked do Krakatoa_GUI_Channels.%.changed (Krakatoa_GUI_Channels.%.value = %)\n" cnt theSpinner theSpinner theValue to:txt
		)
		
		if findItem presetsList theValue != 0 do 
		(
			format  "separator spr_10\n"  to:txt
			format  "menuItem mnu_RemovePreset \"Remove [%]\"\n" theValue  to:txt
			if type == #memory and RAMdisplay == 3 do theValue *= 1024.0
			format  "on mnu_RemovePreset picked do delIniSetting (Krakatoa_PresetsDirectory + \"//KrakatoaPreferences.ini\") \"%\" \"%\" \n" presetName theValue to:txt
		)	
		

		if type == #preallocationcount do
		(
			format  "separator spr_20\n" 	 to:txt
			if currentDefault != theValue as string do
			(
				format  "menuItem mnu_MakeDefault \"Set [%] as Default \"\n" theValue to:txt
				format  "on mnu_MakeDefault picked do setIniSetting (GetDir #plugcfg + \"/Krakatoa/KrakatoaDefaults.ini\") \"Defaults\" \"%\" \"%\" \n" theDefaultsKey theValue to:txt

				if currentDefault != "--Not Set--" do
				(
					format  "menuItem mnu_ResetDefault \"Reset Default [%]\"\n" currentDefault to:txt
					format  "on mnu_ResetDefault picked do delIniSetting (GetDir #plugcfg + \"/Krakatoa/KrakatoaDefaults.ini\") \"Defaults\" \"%\"\n" theDefaultsKey to:txt
				)
			)			
		)
		
		format  ")\n" to:txt
		Krakatoa_RCMenu_Struct.Presets_RCMenu = execute (txt as string)
	)


	on btn_memmake16 pressed do changeMemoryChannelTo "float16"
	on btn_memmake32 pressed do changeMemoryChannelTo "float32"
	--on btn_memmake64 pressed do changeMemoryChannelTo "float64"
	

	on btn_countPresets pressed do 
	(
		createPresetsRCMenu type:#count 
		popUpMenu Krakatoa_RCMenu_Struct.Presets_RCMenu position:mouse.screenPos
	)	
	on btn_countPresets rightClick do 
	(
		createPresetsRCMenu type:#count 
		popUpMenu Krakatoa_RCMenu_Struct.Presets_RCMenu position:mouse.screenPos			
	)
	on btn_memoryPresets pressed do 
	(
		createPresetsRCMenu type:#memory 
		popUpMenu Krakatoa_RCMenu_Struct.Presets_RCMenu position:mouse.screenPos			
	)	
	
	on btn_memoryPresets rightClick do 		
	(
		createPresetsRCMenu type:#memory 
		popUpMenu Krakatoa_RCMenu_Struct.Presets_RCMenu position:mouse.screenPos
	)
	
--MEMORY PRE-ALLOCATION HANDLERS
	on spn_PreAllocationParticleCount changed val do
	(
		FranticParticles.SetProperty "Memory:PreAllocation:ParticleCountInMillions" (val as string)
	)
	
	on chk_UsePreAllocation changed state do
	(
		FranticParticles.SetProperty "Memory:PreAllocation:Use" (state as string)
	)
	
	on chk_UsePreAllocation rightclick do
		FranticParticleRenderMXS.createDefaultsRCMenu "Memory:PreAllocation:Use" "Use Pre-Allocation"
	
	
	on btn_PreAllocationCountPresets pressed do 
	(
		createPresetsRCMenu type:#preallocationcount 
		popUpMenu Krakatoa_RCMenu_Struct.Presets_RCMenu position:mouse.screenPos
	)	
	on btn_PreAllocationCountPresets  rightClick do 
	(
		createPresetsRCMenu type:#preallocationcount  
		popUpMenu Krakatoa_RCMenu_Struct.Presets_RCMenu position:mouse.screenPos			
	)	

	fn refresh_GUI =
	(
		spn_particleCount.value = execute (FranticParticles.GetProperty "ParticleCountMemoryCalculator:Count")

		spn_PreAllocationParticleCount.value = FranticParticles.GetFloatProperty "Memory:PreAllocation:ParticleCountInMillions" 
		chk_UsePreAllocation.state  = FranticParticles.GetBoolProperty "Memory:PreAllocation:Use" 
		
		spn_RenderThreadLimit.value = FranticParticles.getIntProperty "RenderThreadLimit"
		spn_FrameBufferAvailPhysMemoryFraction.value = (FranticParticles.getFloatProperty "FrameBufferAvailPhysMemoryFraction")*100.0

		updateMemChannels()
		
		if Krakatoa_Initializing_Hidden_Rollouts == false do 
			Krakatoa_GUI_Channels.open = FranticParticles.GetBoolProperty "GUI:ParticleChannelsRolloutOpen"
	)

	on Krakatoa_GUI_Channels close do 
	(
		if Krakatoa_GUI_Channels.inDialog and not Krakatoa_Closing_Floater and not Krakatoa_Initializing_Hidden_Rollouts then
		(
			setIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "RolloutVisible" Krakatoa_GUI_Channels.title "false"
			FranticParticleRenderMXS.floatOrDockRollout Krakatoa_GUI_Channels forceMode:#hide
			Krakatoa_CustomizeRollouts_Dialog.Refresh_GUI()
		)	
	)	
	
	fn updateIcons =
	(
		btn_LoadSave_Channels.images = #(Krakatoa_PresetsArrowBitmap,Krakatoa_PresetsArrowBitmap, 32,3,3,3,3)
		btn_Float_Rollout.images = #(Krakatoa_PresetsArrowBitmap,Krakatoa_PresetsArrowBitmap, 32,4,4,4,4)
		
		btn_PreAllocationCountPresets.images = #(Krakatoa_PresetsArrowBitmap,Krakatoa_PresetsArrowBitmap, 32,1,1,2,2)
		btn_countPresets.images = #(Krakatoa_PresetsArrowBitmap,Krakatoa_PresetsArrowBitmap, 32,1,1,2,2)
		btn_memoryPresets.images = #(Krakatoa_PresetsArrowBitmap,Krakatoa_PresetsArrowBitmap, 32,1,1,2,2)
	)		

	on Krakatoa_GUI_Channels open do 
	(
		updateIcons()
		
		Krakatoa_CustomizeRollouts_Dialog.Refresh_GUI()
		
		Refresh_GUI()
		FranticParticles.LogDebug ("+Memory Channels Rollout OPENED.")			
	)			
	
	on Krakatoa_GUI_Channels rolledUp val do 
	(
			FranticParticles.SetProperty "GUI:ParticleChannelsRolloutOpen" val		
			if val then 
				FranticParticles.LogDebug ("+Memory Channels Rollout ROLLED DOWN.")
			else
			FranticParticles.LogDebug ("+Memory Channels Rollout ROLLED UP.")	
	)			
)





--------------------------------------------------------------------------------------------------------------------------------------------------------------------	
--MATTE OBJECTS ROLLOUT	
--------------------------------------------------------------------------------------------------------------------------------------------------------------------	
rollout Krakatoa_GUI_MatteObjects "Matte Objects" category:45 width:457
(
	button btn_LoadSave_MatteObjects "<>" across:4 align:#left width:20 height:16 offset:[-10,-5] tooltip:"Load and Save Presets For This Rollout Only" 
	button btn_Help_MatteObjects  "Open Online Help..." width:100 height:16 align:#center offset:[-100,-5] tooltip:"Opens the Krakatoa Online Help for the Matte Objects rollout in the default Web Browser. Requires Internet connection."
	button btn_BackTo_Main "Back To Main Controls..." height:16 width:308 offset:[-3,-5] align:#center tooltip:"Closes the rollout and sets focus on\nthe Main Controls rollout."
	button btn_Float_Rollout ">" height:16 width:20 offset:[10,-5] align:#right tooltip:"Float/Dock the Rollout.\nRight-Click for Menu..." 
	
	on btn_BackTo_Main pressed do
	(
		Krakatoa_GUI_MatteObjects.open = false
		FranticParticleRenderMXS.BackToMainControls()
	)	
	on btn_BackTo_Main rightclick do
	(
		Krakatoa_GUI_MatteObjects.open = false
		FranticParticleRenderMXS.BackToMainControls()
	)		

	on btn_LoadSave_MatteObjects pressed do 
	(
		Krakatoa_RCMenu_Struct.Float_Rollout_RCMenu_CurrentRollout = Krakatoa_GUI_MatteObjects
		popupMenu Krakatoa_RCMenu_Struct.Load_Save_Rollout_RCMenu pos:mouse.screenpos
	)	
	on btn_LoadSave_MatteObjects rightClick do 
	(
		Krakatoa_RCMenu_Struct.Float_Rollout_RCMenu_CurrentRollout = Krakatoa_GUI_MatteObjects
		popupMenu Krakatoa_RCMenu_Struct.Load_Save_Rollout_RCMenu pos:mouse.screenpos
	)		
	
	on btn_Float_Rollout pressed do
	(
		FranticParticleRenderMXS.FloatRolloutButtonPressed Krakatoa_GUI_MatteObjects
	)		
	on btn_Float_Rollout rightClick do
	(
		Krakatoa_RCMenu_Struct.Float_Rollout_RCMenu_CurrentRollout = Krakatoa_GUI_MatteObjects
		popupMenu Krakatoa_RCMenu_Struct.Float_Rollout_RCMenu pos:mouse.screenpos
	)	

	on Krakatoa_GUI_MatteObjects moved pos do
	(
		setIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "RolloutDialogPositions" Krakatoa_GUI_MatteObjects.title (pos as string)
		Krakatoa_CustomizeRollouts_Dialog.updateStripsPositions pos
	)	
	

	checkbutton ckb_useMatteObjects ">Enable Matte Objects" across:3 width:148 align:#left offset:[-9,0] tooltip:"When checked, Matte Objects specified via Named Selection Sets will be considered during lighting and rendering." highlightcolor:KrakatoaSkinColorsStruct.Matte 
	spinner spn_MatteRayDivisions "SuperSampling:" range:[1,10,1] type:#integer fieldwidth:55 align:#center offset:[0,3]
	checkbutton ckb_saveMultipleLayers ">Save Multiple Layers" width:148 align:#right offset:[9,0] tooltip:"When checked, saves two image layers for easier anti-aliasing when compositing.\n\nThis creates a 'Krakatoa Occluded Layer' Render Element in the Render Setup Dialog >\nRender Elements tab." highlightcolor:KrakatoaSkinColorsStruct.Matte

	group "Define Matte Objects using one or more Named Selection Sets:"
	(
		listbox lbx_allNamedSelectionSets "  Available Named Selection Sets:" items:#() height:6 across:2 width:212 align:#left offset:[-7,0] 
		listbox lbx_useNamedSelectionSets " Matte Objects Named Selection Sets:" items:#() height:6 width:212 align:#right offset:[7,0] 
		
		button btn_update "Update Named Selection Sets Lists" width:210 align:#left offset:[-7,-5] across:3 tooltip:"Update both Named Selection Sets lists manually to reflect name changes, new and deleted selection sets etc."
		button btn_selectInScene "Select Highlighted" width:106 align:#right offset:[46,-5] tooltip:"Select the objects in the scene stored in the currently highlighted Matte Objects Named Selection Set ."
		button btn_selectAllInScene "Select All" width:106 align:#right offset:[9,-5] tooltip:"Select the objects in the scene stored in all Matte Objects Named Selection Sets."
		edittext edt_info readOnly:true fieldwidth:442 align:#center offset:[-2,0]
		progressbar prg_matteObjectsState height:21 width:21 across:2 align:#left offset:[-6,0] value:100
		button btn_openMatteExplorer "Open Krakatoa Matte Objects Explorer..." width:420 align:#right offset:[6,0]
	)
	button btn_selectionSetAdd ">" height:40 align:#center width:20 offset:[0,-166] tooltip:"Move the highlighted Named Selection Set to the Matte Objects Named Selection Sets list. All geometry objects in it will become matte objects." 
	button btn_selectionSetRemove "<" height:40 align:#center offset:[0,-5] width:20 tooltip:"Remove the highlighted Named Selection Set from the Matte Objects Named Selection Sets list." 

	label lbl_void01 height:72
	
	group "Create New or Update existing Named Selection Set from Scene Selection:"
	(
		edittext edt_createNewSelSet "NSS:" text:"KrakatoaMatteObjects" across:2 width:214 align:#left offset:[-2,0]
		button btn_createNewSelSet "Create/Update Named Selection Set" width:214 align:#right offset:[0,0] height:18 tooltip:"Select objects, enter NSS name and press to create a new selection set. Select an existing NSS from the Matte Objects NSS list, select objects in the scene and press to update."
	)	
	
	group "Load Initial Depth Map File Sequence:"
	(
		checkbutton chk_useDepthMapFiles ">Use Depth Map File Sequence" width:214 align:#left offset:[-5,-3] across:2 highlightcolor:KrakatoaSkinColorsStruct.Matte tooltip:"When checked, the image sequence provided below will be loaded as an initial Z-Depth Map for Matting particles. This is espectially useful for Matting with render-time generated geometry, for example micropolygon displaced surfaces that cannot be directly represented as Geometry in 3ds Max, or for Matting with information from other applications."
		spinner spn_DepthMapNear "Z Near:" range:[0,100000000,0] fieldwidth:100 align:#right offset:[3,-3] type:#worldunits
		dropdownlist ddl_DepthMapMode items:#("Camera Space Z Depth","Normalized Z Depth","Inverted Normalized Z Depth")  align:#left width:214 offset:[-4,-3] across:2 tooltip:"Select Depth Map Format - \nCamera Space Z Depth stores the value in real-world units;\nNormalized Z-Depth uses Near and Far values with black being closest;\nInverted Normalized Z-Depth is used by 3ds Max with Near and Far values and black being farthest."
		spinner spn_DepthMapFar "Z Far:" range:[0,100000000,0] fieldwidth:100 align:#right offset:[3,-3] type:#worldunits
		
		button btn_depthMapFiles "..." width:18 height:20 offset:[-5,-2] align:#left across:3 tooltip:"Opens a File Browser for selecting the Depth Map Image Sequence."
		edittext edt_depthMapFiles "" fieldwidth:405 align:#center offset:[0,0] 
		button btn_ExploreDepthMapPath "E" align:#right width:18 height:20 offset:[9,-2] tooltip:"Open Current Path In Windows Explorer..."
	)
	
	fn updateMatteStatusLight =
	(
		local useNamedSelectionSets = execute (FranticParticles.GetProperty "Matte:NamedSelectionSets")
		local matteSelSets = for i = 1 to selectionSets.count where findItem useNamedSelectionSets (getNamedSelSetName i) != 0 collect selectionSets[i]
		local matteObjects = #()
		local BadMattesCount = 0
		for i in matteSelSets do 
			join matteObjects (for o in i collect #(o, i.name, #{}))				
		for i = 1 to matteObjects.count do
		(
			local theLayer = matteObjects[i][1].layer 
			matteObjects[i][3][1] = matteObjects[i][1].renderable  
			matteObjects[i][3][2] = matteObjects[i][1].primaryVisibility  
			matteObjects[i][3][3] = not matteObjects[i][1].isHidden  
			matteObjects[i][3][4] = not (matteObjects[i][1].isFrozen and maxOps.hideFrozenObjects)
			matteObjects[i][3][5] = theLayer.on
			matteObjects[i][3][6] = theLayer.renderable 
			matteObjects[i][3][7] = not theLayer.isHidden 
			matteObjects[i][3][8] = theLayer.primaryVisibility 
			if matteObjects[i][3].numberset != matteObjects[i][3].count do BadMattesCount += 1
		)
		if matteObjects.count == 0 then
		(
			prg_matteObjectsState.color = white*0.75
			btn_openMatteExplorer.text = "NO MATTE OBJECTS DEFINED - Open Krakatoa Matte Objects Explorer..." 
		)
		else if BadMattesCount == matteObjects.count then 
		(
			prg_matteObjectsState.color = red
			btn_openMatteExplorer.text = "NO MATTE OBJECTS WILL RENDER - Open Krakatoa Matte Objects Explorer..." 
		)
		else if BadMattesCount == 0 then 
		(
			prg_matteObjectsState.color = green
			btn_openMatteExplorer.text = "All Matte Objects OK - Open Krakatoa Matte Objects Explorer..." 
		)
		else 	
		(
			prg_matteObjectsState.color = (color 255 255 100)
			btn_openMatteExplorer.text = BadMattesCount as string +" MATTE OBJECT"+ (if BadMattesCount!=1 then "S" else "") + " WILL NOT RENDER - Open Krakatoa Matte Objects Explorer..." 
		)
	)	
	
	fn updateInfo =
	(
		local st = timestamp()
		if lbx_useNamedSelectionSets.items.count == 0 then
			edt_info.text = "No Matte Selection Sets Defined."
		else
		(
			local totalObjects = 0
			local totalFaces = 0
			local selectedObjects = 0
			local selectedFaces = 0
			for i = 1 to lbx_useNamedSelectionSets.items.count do
			(
				local theObjectsArray = (selectionSets[lbx_useNamedSelectionSets.items[i]])
				if theObjectsArray != undefined do
				(
					for o in theObjectsArray do
					(
						totalObjects += 1
						local theFaces = (getPolygonCount o)[1]
						totalFaces += theFaces
						if lbx_useNamedSelectionSets.selection == i do 
						(
							selectedObjects +=1
							selectedFaces += theFaces
						)
					)
				)
			)
			local txt = "" as stringStream
			format "Highlighted Set Has % Matte % (% Faces) Out Of % (% Faces)" selectedObjects (if totalObjects ==1 then "Object" else "Objects") (FranticParticleRenderMXS.addCommas (selectedFaces as string)) totalObjects  (FranticParticleRenderMXS.addCommas  (totalFaces as string))  to:txt
			edt_info.text = txt as string
		)
		updateMatteStatusLight()
		--format "% ms\n" (timestamp()-st)
	)
	
	on prg_matteObjectsState clicked val do updateInfo()
	
	
	fn saveSelectionSets =
	(
		local txt = "" as stringStream
		format "#(" to:txt
		if lbx_useNamedSelectionSets.items.count > 0 do
		(
			for i = 1 to lbx_useNamedSelectionSets.items.count-1 do 
				format "\"%\"," lbx_useNamedSelectionSets.items[i] to:txt 
			format "\"%\"" lbx_useNamedSelectionSets.items[lbx_useNamedSelectionSets.items.count] to:txt
		)	
		format ")" to:txt
		FranticParticles.SetProperty "Matte:NamedSelectionSets" (txt as string)
	)			
	
	fn updateSelectionSets =
	(
		local theArray  = execute (FranticParticles.GetProperty "Matte:NamedSelectionSets")
		lbx_useNamedSelectionSets.items = theArray 
		lbx_allNamedSelectionSets.items = for i = 1 to selectionsets.count where findItem theArray (getNamedSelSetName i) == 0 collect (getNamedSelSetName i)
		saveSelectionSets()
		try(Krakatoa_GUI_Particles.updateParticlesList())catch()
		updateInfo()
	)
	
	fn renamedSelectionSets theNames =
	(
		tempArray = lbx_useNamedSelectionSets.items
		for i = 1 to tempArray.count do if tempArray[i] == theNames[1] do tempArray[i] = theNames[2]
		lbx_useNamedSelectionSets.items = tempArray 
		updateSelectionSets()
	)
	
	fn updateObjectTags =
	(
		local tempArray = lbx_useNamedSelectionSets.items
		for o in objects do
		(
			local theTags = #()
			for nss in tempArray where try(findItem selectionSets[nss] o > 0)catch(false) do append theTags nss
			with printAllElements on setUserProp o "KrakatoaMatteObjectNSS" (theTags as string)
		)
	)	
	
	on btn_openMatteExplorer pressed do 
		try(macros.run "Krakatoa" "KrakatoaMatteObjectsExplorer")catch()

	on lbx_allNamedSelectionSets doubleClicked itm do
	(
		tempArray = lbx_useNamedSelectionSets.items
		append tempArray lbx_allNamedSelectionSets.selected 
		lbx_useNamedSelectionSets.items = tempArray
		saveSelectionSets()
		updateSelectionSets()
		updateObjectTags()
	)	

	on btn_selectionSetAdd pressed do 
	(		
		if lbx_allNamedSelectionSets.selection > 0 do
		(
			tempArray = lbx_useNamedSelectionSets.items
			append tempArray lbx_allNamedSelectionSets.selected 
			lbx_useNamedSelectionSets.items = tempArray
			saveSelectionSets()
			updateSelectionSets()		
			updateObjectTags()			
		)	
	)
	
	on lbx_useNamedSelectionSets doubleClicked itm do
	(
		tempArray = lbx_useNamedSelectionSets.items
		deleteItem tempArray itm
		lbx_useNamedSelectionSets.items = tempArray
		saveSelectionSets()
		updateSelectionSets()				
		updateObjectTags()
	)
	
	on lbx_useNamedSelectionSets selected itm do 
	(
		try(edt_createNewSelSet.text = lbx_useNamedSelectionSets.selected)catch()
		updateInfo()
	)
		
	
	on btn_selectionSetRemove pressed do 
	(		
		if lbx_useNamedSelectionSets.selection > 0 do
		(
			local tempArray = lbx_useNamedSelectionSets.items
			deleteItem tempArray lbx_useNamedSelectionSets.selection
			lbx_useNamedSelectionSets.items = tempArray
			saveSelectionSets()
			updateSelectionSets()				
			updateObjectTags()			
		)	
	)			
	on btn_update pressed do updateSelectionSets()
	
	on btn_selectAllInScene pressed do 
	(
		updateSelectionSets()	
		max select none
		for i = 1 to selectionsets.count where findItem lbx_useNamedSelectionSets.items (getNamedSelSetName i) != 0 do selectmore selectionsets[i]
	)	
	on btn_selectInScene pressed do 
	(
		updateSelectionSets()	
		max select none
		for i = 1 to selectionsets.count where lbx_useNamedSelectionSets.selected == (getNamedSelSetName i) do select selectionsets[i]
	)	
	
	on btn_createNewSelSet pressed do
	(
		if selection.count > 0 then
		(
			if edt_createNewSelSet.text != "" then
			(
				local theObjects = for o in selection where (findItem geometryClass.classes (classof o) > 0 and findItem #(TargetObject, KrakatoaPrtLoader, PF_Source, PRT_Volume, PRT_FumeFX, PRT_Source, PRT_Surface, PRT_Hair, PRT_Maker) (classof o.baseobject) == 0) OR (classof o.baseobject == XRefObject AND isKindOf o.actualBaseObject GeometryClass) collect o
				if theObjects.count > 0 then
				(
					selectionSets[edt_createNewSelSet.text] = theObjects 
					tempArray = lbx_useNamedSelectionSets.items
					if findItem tempArray edt_createNewSelSet.text == 0 do
					(
						append tempArray edt_createNewSelSet.text
						lbx_useNamedSelectionSets.items = tempArray
						saveSelectionSets()
					)	
					updateSelectionSets()
					updateObjectTags()
				)	
				else
					messagebox "The Current Selection Does Not Contain Any Valid Matte Objects\n" title:"Cannot Create Matte Objects Selection Set"
			)
			else
				messagebox "Please enter a valid name for the selection set\n" title:"Cannot Create Matte Objects Selection Set"
		)
		else		
			messagebox "Please select some Geometry Objects in the scene!" title:"Cannot Create Matte Objects Selection Set"
	)		

	on spn_MatteRayDivisions changed val do FranticParticles.SetProperty "Matte:RayDivisions" (val as string)
	on ckb_saveMultipleLayers changed state do 
	(
		FranticParticles.SetProperty "Matte:SaveMultipleLayers" (state as string)
		if state do 
			FranticParticleRenderMXS.addRenderElement "OccludedLayer" ""
		FranticParticleRenderMXS.toggleRenderElementByClass Krakatoa_OccludedLayer state			
		try(Krakatoa_GUI_Main.refresh_GUI())catch()
	)

	fn refresh_GUI = 
	(
		chk_useDepthMapFiles.checked = FranticParticles.GetBoolProperty "Matte:UseDepthMapFiles" 
		edt_DepthMapFiles.text = FranticParticles.GetProperty "Matte:DepthMapFiles" 
		
		FranticParticleRenderMXS.SetDropDownValue ddl_DepthMapMode (FranticParticles.GetProperty "Matte:DepthMapMode")
		spn_DepthMapNear.value  = FranticParticles.GetFloatProperty "Matte:DepthMapNear" 
		spn_DepthMapFar.value = FranticParticles.GetFloatProperty "Matte:DepthMapFar" 
		spn_DepthMapNear.enabled = spn_DepthMapFar.enabled = ddl_DepthMapMode.selection > 1
		ckb_useMatteObjects.checked = FranticParticles.GetBoolProperty "Matte:UseMatteObjects"
		ckb_saveMultipleLayers.checked = FranticParticles.GetBoolProperty "Matte:SaveMultipleLayers"
		spn_MatteRayDivisions.value = FranticParticles.GetIntProperty "Matte:RayDivisions" 
		
		updateSelectionSets()
		callbacks.removeScripts id:#KrakatoaNamedSelectionSetMonitor 
		try 
		(
			callbacks.addScript #NamedSelSetCreated "try(Krakatoa_GUI_MatteObjects.updateSelectionSets())catch()" id:#KrakatoaNamedSelectionSetMonitor 
			callbacks.addScript #NamedSelSetDeleted "try(Krakatoa_GUI_MatteObjects.updateSelectionSets())catch()" id:#KrakatoaNamedSelectionSetMonitor 
			callbacks.addScript #NamedSelSetRenamed "try(Krakatoa_GUI_MatteObjects.renamedSelectionSets (callbacks.notificationParam()))catch()" id:#KrakatoaNamedSelectionSetMonitor 
		)catch()	
		
		if Krakatoa_Initializing_Hidden_Rollouts == false do 
			try(Krakatoa_GUI_MatteObjects.open = FranticParticles.GetBoolProperty "GUI:MatteObjectsRolloutOpen")catch()
	)
	
	on Krakatoa_GUI_MatteObjects rolledUp val do 
	(
			FranticParticles.SetProperty "GUI:MatteObjectsRolloutOpen" val
			if val then 
				FranticParticles.LogDebug ("+Matte Objects Rollout ROLLED DOWN.")
			else
				FranticParticles.LogDebug ("+Matte Objects Rollout ROLLED UP.")	
		)

	on ckb_useMatteObjects changed state do 
	(
		FranticParticles.SetProperty "Matte:UseMatteObjects" state
		updateToolbarButtons()
		try(Krakatoa_GUI_Main.refresh_GUI())catch()
		try(Krakatoa_VFB_Overlay_Rollout.Refresh_GUI())catch()
	)	
	
	on ckb_useMatteObjects rightClick do 
		FranticParticleRenderMXS.createDefaultsRCMenu "Matte:UseMatteObjects" ">Enable Matte Objects"
	
	on edt_depthMapFiles changed val do FranticParticles.SetProperty "Matte:DepthMapFiles" val

	on ckb_saveMultipleLayers rightClick do 
		FranticParticleRenderMXS.createDefaultsRCMenu "Matte:SaveMultipleLayers" ">Save Multiple Layers"

	
	on btn_depthMapFiles pressed do (
		local newFile
		newFile = getOpenFileName caption:"Select the Depth Map Sequence to Load" filename:(FranticParticles.GetProperty "Matte:DepthMapFiles") types:"OpenEXR Files (*.exr)|*.exr|All(*.*)|*.*" history:"KrakatoaDepthMaps"
		if newFile != undefined do (
			FranticParticles.SetProperty "Matte:DepthMapFiles" newFile 
			refresh_GUI()
		)
		try(Krakatoa_VFB_Overlay_Rollout.Refresh_GUI())catch()
	)

	on ddl_DepthMapMode selected itm do 
	(
		FranticParticles.SetProperty "Matte:DepthMapMode" ddl_DepthMapMode.selected
		spn_DepthMapNear.enabled = spn_DepthMapFar.enabled = itm > 1
	)	
	
	on spn_DepthMapNear changed val do 
	(
		if val > spn_DepthMapFar.value do 
		(
			spn_DepthMapFar.value = val 
			FranticParticles.SetProperty "Matte:DepthMapFar" (val as string)
		)
		FranticParticles.SetProperty "Matte:DepthMapNear" (val as string)
	)	
	on spn_DepthMapFar changed val do 
	(
		if val < spn_DepthMapNear .value do 
		(
			spn_DepthMapNear.value = val
			FranticParticles.SetProperty "Matte:DepthMapFar" (val as string)
		)	
		FranticParticles.SetProperty "Matte:DepthMapFar" (val as string)
	)	

	on chk_useDepthMapFiles changed state do 
	(
		FranticParticles.SetProperty "Matte:UseDepthMapFiles" state
		try(Krakatoa_GUI_Main.refresh_GUI())catch()
		refresh_GUI()
	)	
	on chk_useDepthMapFiles rightClick do 
		FranticParticleRenderMXS.createDefaultsRCMenu "Matte:UseDepthMapFiles" ">Use Depth Map File Sequence"

	on Krakatoa_GUI_MatteObjects close do 
	(
		if Krakatoa_GUI_MatteObjects.inDialog and not Krakatoa_Closing_Floater and not Krakatoa_Initializing_Hidden_Rollouts then
		(
			setIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "RolloutVisible" Krakatoa_GUI_MatteObjects.title "false"
			FranticParticleRenderMXS.floatOrDockRollout Krakatoa_GUI_MatteObjects forceMode:#hide
			Krakatoa_CustomizeRollouts_Dialog.Refresh_GUI()
		)	
	)	
	
	fn updateIcons =
	(
		btn_LoadSave_MatteObjects.images = #(Krakatoa_PresetsArrowBitmap,Krakatoa_PresetsArrowBitmap, 32,3,3,3,3)
		btn_Float_Rollout.images = #(Krakatoa_PresetsArrowBitmap,Krakatoa_PresetsArrowBitmap, 32,4,4,4,4)
		
		btn_selectionSetAdd.images = #(Krakatoa_PresetsArrowBitmap,Krakatoa_PresetsArrowBitmap, 32,6,6,8,8)
		btn_selectionSetRemove.images = #(Krakatoa_PresetsArrowBitmap,Krakatoa_PresetsArrowBitmap, 32,7,7,9,9)
		
		btn_depthMapFiles.images = #(Krakatoa_PresetsArrowBitmap,Krakatoa_PresetsArrowBitmap, 32,11,11,11,11)
		btn_ExploreDepthMapPath.images = #(Krakatoa_PresetsArrowBitmap,Krakatoa_PresetsArrowBitmap, 32,12,12,12,12)			
	)	

	on Krakatoa_GUI_MatteObjects open do 
	(
		updateIcons()
		Krakatoa_CustomizeRollouts_Dialog.Refresh_GUI()
		
		Refresh_GUI()
		FranticParticles.LogDebug ("+Matte Objects Rollout OPENED.")			
	)			
	
)--end rollout


global Krakatoa_JobNameRCMenu 
rcmenu Krakatoa_JobNameRCMenu 
(
	local default = getIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaDeadlineSettings.ini") "Default" "DeadlineJobNameSource" 
	menuItem mnu_getMaxFileName "MAX Scene Name"
	menuItem mnu_getSavePath "Project_Sequence_Take from Save Path"
	separator sep_01
	subMenu "Set Default Behavior"
	(
		menuItem mnu_setMaxFileName "Use MAX Scene Name" checked:(default != "SavePath")
		menuItem mnu_setSavePath "Use Project_Sequence_Take from Save Path" checked:(default == "SavePath")
	)
	on mnu_getMaxFileName picked do
		Krakatoa_GUI_Partition.jobNameFromMaxName()
	on mnu_getSavePath picked do
		Krakatoa_GUI_Partition.jobNameFromSavePath()
	on mnu_setMaxFileName picked do
		setIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaDeadlineSettings.ini") "Default" "DeadlineJobNameSource" "MaxSceneName"
	on mnu_setSavePath picked do
		setIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaDeadlineSettings.ini") "Default" "DeadlineJobNameSource" "SavePath"
)

global Krakatoa_JobCommentRCMenu 
rcmenu Krakatoa_JobCommentRCMenu 
(
	local default = getIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaDeadlineSettings.ini") "Default" "DeadlineCommentSource" 
	menuItem mnu_default "Default Comment"
	menuItem mnu_getSavePath "Project_Sequence_Take from Save Path"
	separator sep_01
	subMenu "Set Default Behavior"
	(
		menuItem mnu_setdefault "Use Default Comment" checked:(default != "SavePath")
		menuItem mnu_setSavePath "Use Project_Sequence_Take from Save Path" checked:(default == "SavePath")
	)
	on mnu_default picked do
		Krakatoa_GUI_Partition.defaultComment ()
	on mnu_getSavePath picked do
		Krakatoa_GUI_Partition.CommentFromSavePath()
	on mnu_setdefault picked do
		setIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaDeadlineSettings.ini") "Default" "DeadlineCommentSource" "Default"
	on mnu_setSavePath picked do
		setIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaDeadlineSettings.ini") "Default" "DeadlineCommentSource" "SavePath"
)


--------------------------------------------------------------------------------------------------------------------------------------------------------------------	
--PARTICLE FLOW PARTITIONING ROLLOUT	
--------------------------------------------------------------------------------------------------------------------------------------------------------------------	
rollout Krakatoa_GUI_Partition "Partitioning" category:25 width:457
(
	local KrakatoaIniPath = GetDir #plugcfg + "\\Krakatoa\\KrakatoaDeadlineSettings.ini"

	button btn_LoadSave_Partition "<>" across:4 align:#left width:20 height:16 offset:[-10,-5] tooltip:"Load and Save Presets For This Rollout Only" 
	button btn_Help_Partition  "Open Online Help..." width:100 height:16 align:#center offset:[-100,-5] tooltip:"Opens the Krakatoa Online Help for the Partitioning rollout in the default Web Browser. Requires Internet connection."
	button btn_BackTo_Main "Back To Main Controls..." height:16 width:308 offset:[-3,-5] align:#center tooltip:"Closes the rollout and sets focus on\nthe Main Controls rollout."
	button btn_Float_Rollout ">" height:16 width:20 offset:[10,-5] align:#right tooltip:"Float/Dock the Rollout.\nRight-Click for Menu..." 
	
	
	on btn_BackTo_Main pressed do
	(
		Krakatoa_GUI_Partition.open = false
		FranticParticleRenderMXS.BackToMainControls()
	)	
	on btn_BackTo_Main rightclick do
	(
		Krakatoa_GUI_Partition.open = false
		FranticParticleRenderMXS.BackToMainControls()
	)		

	on btn_LoadSave_Partition pressed do 
	(
		Krakatoa_RCMenu_Struct.Float_Rollout_RCMenu_CurrentRollout = Krakatoa_GUI_Partition
		popupMenu Krakatoa_RCMenu_Struct.Load_Save_Rollout_RCMenu pos:mouse.screenpos
	)	
	on btn_LoadSave_Partition rightClick do 
	(
		Krakatoa_RCMenu_Struct.Float_Rollout_RCMenu_CurrentRollout = Krakatoa_GUI_Partition
		popupMenu Krakatoa_RCMenu_Struct.Load_Save_Rollout_RCMenu pos:mouse.screenpos
	)	
	
	on btn_Float_Rollout pressed do
	(
		FranticParticleRenderMXS.FloatRolloutButtonPressed Krakatoa_GUI_Partition
	)		
	on btn_Float_Rollout rightClick do
	(
		Krakatoa_RCMenu_Struct.Float_Rollout_RCMenu_CurrentRollout = Krakatoa_GUI_Partition
		popupMenu Krakatoa_RCMenu_Struct.Float_Rollout_RCMenu pos:mouse.screenpos
	)			

	on Krakatoa_GUI_Partition moved pos do
	(
		setIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "RolloutDialogPositions" Krakatoa_GUI_Partition.title (pos as string)
		Krakatoa_CustomizeRollouts_Dialog.updateStripsPositions pos
	)			
	
	spinner spn_partitionCount "Partition Count: " range:[2,100,2] fieldwidth:50 type:#integer align:#left offset:[0,0] across:3
	spinner spn_PartitionStart "Partition Range From: " range:[1,100,1] type:#integer align:#center offset:[40,0] fieldwidth:50 
	spinner spn_PartitionEnd "To: " range:[1,100,1] type:#integer align:#right offset:[0,0] fieldwidth:50 

	group "Increment Random Seeds Of"
	(
		checkbutton ckb_incrementPositionRandomSeeds ">PFlow Position" align:#left width:106 height:20  across:4 highlightcolor:KrakatoaSkinColorsStruct.Partitioning tooltip:"Toggle the incrementing of Random Seeds in Particle Flow Position Operators."
		checkbutton ckb_incrementSpawnRandomSeeds ">PFlow Spawn" align:#center width:106 height:20 highlightcolor:KrakatoaSkinColorsStruct.Partitioning tooltip:"Toggle the incrementing of Random Seeds in Particle Flow Spawn and CollisionSpawn Operators."
		checkbutton ckb_incrementSpeedRandomSeeds ">PFlow Speed " align:#center width:106 height:20 highlightcolor:KrakatoaSkinColorsStruct.Partitioning tooltip:"Toggle the incrementing of Random Seeds in Particle Flow Speed, SpeedByIcon and SpeedBySurface Operators."
		checkbutton ckb_incrementRotationRandomSeeds ">PFlow Rotation" align:#right width:106 height:20  highlightcolor:KrakatoaSkinColorsStruct.Partitioning tooltip:"Toggle the incrementing of Random Seeds in Particle Flow Rotation Operators."
		
		checkbutton ckb_incrementFumeFXRandomSeeds ">PFlow FumeFX" align:#left width:106 height:20 across:4 offset:[0,-3] highlightcolor:KrakatoaSkinColorsStruct.Partitioning tooltip:"Toggle the incrementing of Random Seeds in Particle Flow FumeFX Operators."
		checkbutton ckb_incrementOtherRandomSeeds ">PFlow Others" align:#center width:106 height:20 offset:[0,-3] highlightcolor:KrakatoaSkinColorsStruct.Partitioning tooltip:"Toggle the incrementing of Random Seeds in any Particle Flow Operators that expose a Uniqueness spinner but are not handled by the other categories."
		checkbutton ckb_incrementLegacyRandomSeeds ">Legacy Particles" align:#center width:106 height:20 offset:[0,-3] highlightcolor:KrakatoaSkinColorsStruct.Partitioning tooltip:"Toggle the incrementing of Random Seeds in 3ds Max Legacy Particles Systems like PArray, PCloud, SuperSpray and Blizzard."
		checkbutton ckb_incrementThinkingRandomSeeds ">ThinkingParticles" align:#right width:106 height:20 offset:[0,-3] highlightcolor:KrakatoaSkinColorsStruct.Partitioning tooltip:"Toggle the incrementing of Random Seeds in Thinking Particles Operators."
		
		checkbutton ckb_incrementBox3Geometry ">Box#3 Geometry" align:#left width:106 height:20 across:4 offset:[0,-3] highlightcolor:KrakatoaSkinColorsStruct.Partitioning tooltip:"Toggle the incrementing of Random Seeds in Particle Flow Tools Box #3 Geometry Sub-Operators."
		checkbutton ckb_incrementBox3Random  ">Box#3 Random" align:#center width:106 height:20 offset:[0,-3] highlightcolor:KrakatoaSkinColorsStruct.Partitioning tooltip:"Toggle the incrementing of Random Seeds in Particle Flow Tools Box #3 Random Sub-Operators."
		checkbutton ckb_incrementBox3ScalarVector ">Box#3 Sclr/Vector" align:#center width:106 height:20 offset:[0,-3] highlightcolor:KrakatoaSkinColorsStruct.Partitioning tooltip:"Toggle the incrementing of Random Seeds in Particle Flow Tools Box #3 Scalar and Vector Sub-Operators."
		checkbutton ckb_incrementBox3Icon ">Box#3 Icon" align:#right width:106 height:20 offset:[0,-3] highlightcolor:KrakatoaSkinColorsStruct.Partitioning tooltip:"Toggle the incrementing of Random Seeds in Particle Flow Tools Box #3 Icon Sub-Operators."

		checkbutton ckb_incrementPRTModifiers ">PRT Loaders" align:#left width:106 height:20 across:4 offset:[0,-3] highlightcolor:KrakatoaSkinColorsStruct.Partitioning tooltip:"Toggle the incrementing of Random Seeds in PRT Loader Modifiers"
		checkbutton ckb_incrementPRTVolumeModifiers ">PRT Vol/Surf." align:#left width:106 height:20 across:2 offset:[0,-3] highlightcolor:KrakatoaSkinColorsStruct.Partitioning tooltip:"Toggle the incrementing of Random Seeds in PRT Volume and PRT Surface Base Objects and Modifiers"
		checkbutton ckb_incrementPRTFumeFXModifiers ">PRT FumeFX" align:#left width:106 height:20 across:2 offset:[0,-3] highlightcolor:KrakatoaSkinColorsStruct.Partitioning tooltip:"Toggle the incrementing of Random Seeds in PRT FumeFX Base Objects and Modifiers"
		checkbutton ckb_incrementGeometryModifiers ">Geometry" align:#right width:106 height:20 offset:[0,-3] highlightcolor:KrakatoaSkinColorsStruct.Partitioning tooltip:"Toggle the incrementing of Random Seeds in Geometry Modifiers"
		
		label lbl_exclude01 "NOTE: To exclude specific operators, events or objects, add NOSEED to their name."
		groupbox grp_exclude01 offset:[0,-27] height:25 width:430

		checkbutton ckb_incrementSelectedOnly ">Affect Seeds of Selected Objects Only" align:#left width:214 height:20 across:2 highlightcolor:KrakatoaSkinColorsStruct.Partitioning
		checkbutton ckb_incrementBox3DiskCaches ">Increment Box#3 Disk Cache Filenames" align:#right width:214 height:20  highlightcolor:KrakatoaSkinColorsStruct.Partitioning
	)	
	
	label lbl_placeHolder01 
	
	button btn_saveCurrentPartitionLocally "Generate Partition Range Locally..." align:#left width:210 height:30 across:2 offset:[0,-3]
	button btn_submitCustomPartition "Submit Partition Range To Deadline" align:#right width:210 height:30 offset:[0,-3]
	
	button btn_savePartitionsLocally "Generate All Partitions Locally..." align:#left width:210 height:30 across:2 offset:[0,-3]
	button btn_submitPartitionJobs "Submit All Partitions To Deadline" align:#right width:210 height:30 offset:[0,-3]

	dropdownlist ddl_localPartitionMode items:#("Sequential Within Current Scene","Parallel Via Command Line Rendering") align:#left width:210  offset:[0,0] across:2
	dropdownlist ddl_deadlinePartitionMode items:#("One Job Only, Partitions As Tasks","One Job Per Partition, Frames As Tasks") align:#right width:210  offset:[0,0]
	groupBox grp_partlocal "Local" width:220 height:105 offset:[-4,-110] across:2
	groupBox grp_partdeadline "Deadline" width:220 height:105 offset:[0,-110]

	checkbutton ckb_skipExistingFiles ">Skip Existing Files When Saving" width:440 height:20 align:#center highlightcolor:KrakatoaSkinColorsStruct.Partitioning  offset:[0,0] tooltip:"When checked, existing particle files will not be overwritten but skipped, causing only non-existent files to be written."
	
	
	progressbar prg_partprogress height:8 color:red align:#center
	progressbar prg_progress height:8 color:blue align:#center offset:[0,-3]
	label lbl_progress01 "" height:16 align:#center offset:[0,-4]
	label lbl_progress02 "" height:16 align:#center offset:[0,-4]
	
	group "Deadline Submission Settings"
	(
		edittext edt_jobname "Job Name:" fieldwidth:358 align:#left offset:[-2,0] across:2
		button btn_getJobNameMenu ">>" width:18 height:18 offset:[1,0] align:#right tooltip:"Open Menu to Set the Job Name to Max File Name or to Save Path Project/Sequence/Take..." 

		edittext edt_comment "Comment:" fieldwidth:358 align:#left offset:[2,0] across:2
		button btn_getCommentMenu ">>" width:18 height:18 offset:[1,0] align:#right tooltip:"Open Menu to Set the Comment to Max File Name or to Save Path Project/Sequence/Take..." 
		
		edittext edt_user "Name:" fieldwidth:130 align:#left offset:[18,0] across:2
		edittext edt_dept "Department:" fieldwidth:170 align:#right

		label lbl_pools "Pool:" align:#left offset:[24,2] across:2
		dropdownList ddl_poollist "" width:380 align:#right offset:[3,-2]
		
		label lbl_category "Group:" align:#left offset:[3,3] across:2
		dropdownlist ddl_category items:#() align:#right width:380 offset:[3,0]
		
		--checkbutton chk_onlypool ">Render Only On Machines In Pool" width:180 align:#right offset:[0,-3] highlightcolor:KrakatoaSkinColorsStruct.Partitioning

		label lbl_priority "Priority:" align:#left offset:[12,2] across:3
		progressbar sld_priority width:325 height:18 range:[0,100,50] type:#integer align:#center offset:[1,0]
		spinner spn_priority "" type:#integer fieldwidth:35 align:#right  offset:[0,1]
		
		spinner spn_machineLimit "Number of Machines Working Concurrently" range:[1,1000,1] type:#integer align:#left fieldwidth:35 offset:[-4,2] across:2 tooltip:"This value defines the number of Deadline Workers that are allowed to process Tasks of the Partitioning Job at the same time.\n\nIt is a good idea to limit the number of Workers when saving very large PRT files over the network."
		spinner spn_chunkSize "Frames Per Task: " range:[1,1000,1] type:#integer  align:#right  fieldwidth:35 offset:[-1,2] tooltip:"This value is used when in 'One Job Per Partition' mode to define the number of frames to be processed as a single Task.\n\nThis can reduce some latency between Tasks, but if any frame of a Task fails, all frames in that chunk will be reprocessed." --Render Task Chunk Size 

		spinner spn_MaxTasksPerWorker "Concurrent Tasks Per Machine: " range:[1,16,1] type:#integer align:#left fieldwidth:35 offset:[48,2] across:2  tooltip:"When set to a value higher than 1, a single Worker will launch that number of 3ds Max instances and generate Partitions in parallel."
		checkbutton chk_LimitTasksToNumberOfCpus ">Limit To Worker's Task Limit" align:#right  offset:[0,-1]  width:180 highlightcolor:KrakatoaSkinColorsStruct.Partitioning tooltip:"Deadline Workers provide a Task Limit option typically set to the number of CPUs.\n\nWhen this option is checked, the number of Concurrent Tasks Per Machine will be clamped by the Worker's Task Limit."
	)
	button btn_openDeadlineMonitor "Open Deadline Monitor..." align:#center width:446 --height:30 
	
	dropdownlist ddl_useDeadlineVersion items:#("Do Not Detect Deadline","Detect and Use Deadline") width:222 across:2 align:#left offset:[-7,-1]
	button btn_detectDeadlineNow "Detect Deadline Now!" width:214 align:#right tooltip:"Search for Deadline 3, 4 and higher and load submission functions if found." width:222 offset:[7,-1]
	
	label lbl_getDeadline01 "DEADLINE WAS NOT DETECTED ON YOUR SYSTEM!" visible:false pos:[15,400]
	
	fn tweakControlPositions =
	(
		try(edt_jobname.pos = [66,edt_jobname.pos.y])catch()
		try(edt_comment.pos = [66,edt_comment.pos.y])catch()
		try(edt_user.pos = [66,edt_user.pos.y])catch()
		try(edt_dept.pos = [273,edt_dept.pos.y])catch()
	)

	fn job_priority_update val =
	(
		if val <= 100 do
		(
			theRed = (255.0 - 255.0*val/100.0)*2.0
			if theRed > 255 do theRed = 255
			theGreen = 512.0*val/100.0
			if theGreen > 255 do theGreen = 255
			sld_priority.color = [theRed, theGreen, 0]
			sld_priority.value = spn_priority.value = val
		)
		val
	)		

	fn displayPoolsList =
	(
		if SMTDSettings.PoolsSort then
		(
			local tempArray = for i in SMTDSettings.Pools collect i
			ddl_poollist.items = sort tempArray 
		)	
		else
			ddl_poollist.items = SMTDSettings.Pools
			
		local theIndex = findItem ddl_poollist.items SMTDSettings.PoolName
		if theIndex > 0 then 
			ddl_poollist.selection = theIndex 
		else	
			ddl_poollist.selection = 1
	)	
	
	fn jobNameFromMaxName =
	(
		local theName = getFileNameFile maxFileName
		if theName == "" do theName = "Untitled 3ds Max Krakatoa Partition Job"
		edt_jobname.text = theName
	)		
	
	fn jobNameFromSavePath =
	(
		local theName = (FranticParticles.GetProperty "ParticleFilesProject") + "_" + FranticParticles.GetProperty "ParticleFilesSequence" + "_" + FranticParticles.GetProperty "ParticleFilesTake" 
		if theName != "__" do 
			edt_jobname.text = theName
	)
	
	on btn_getJobNameMenu pressed do popUpMenu Krakatoa_JobNameRCMenu pos:(mouse.ScreenPos) 
	on btn_getJobNameMenu rightclick do popUpMenu Krakatoa_JobNameRCMenu pos:(mouse.ScreenPos) 
	
	
	fn defaultComment =
	(
		local theVersion = case ((maxVersion())[1]/1000) of
		(
			10: "2008"
			11: "2009"
			12: "2010"
			13: "2011"
			14: "2012"
			15: "2013"
			16: "2014"
			17: "2015"
			18: "2016"
			19: "2017"
			default: ("v" + ((maxVersion())[1]/1000.0) as string)
		)
		edt_comment.text = ("3ds Max " + theVersion + " Krakatoa v"+ FranticParticles.Version +" Partition Submission")
	)	
	fn CommentFromSavePath =
	(
		local theName = (FranticParticles.GetProperty "ParticleFilesProject") + "_" + FranticParticles.GetProperty "ParticleFilesSequence" + "_" + FranticParticles.GetProperty "ParticleFilesTake" 
		if theName != "__" do 
			edt_comment.text = (theName + " Krakatoa v"+ FranticParticles.Version +" Partition Submission")
	)	

	on btn_getCommentMenu pressed do popUpMenu Krakatoa_JobCommentRCMenu pos:(mouse.ScreenPos) 
	on btn_getCommentMenu rightclick do popUpMenu Krakatoa_JobCommentRCMenu pos:(mouse.ScreenPos) 
	
	--on edt_jobname entered txt do SMTDSettings.jobName = txt
	--on edt_comment entered txt do SMTDSettings.comment = txt
	on edt_user entered txt do SMTDSettings.UserName = txt
	on edt_dept entered txt do setIniSetting SMTDPaths.InIFile "JobSettings"  "Department"  (SMTDSettings.Department = txt)
	on ddl_category selected itm do setIniSetting KrakatoaIniPath "JobSettings"  "Group"  (SMTDSettings.Group = ddl_category.selected)
	
	--on chk_onlypool changed state do setIniSetting KrakatoaIniPath "JobSettings"  "PoolExclusive" ( (SMTDSettings.PoolExclusive = state) as string)
	on spn_priority changed value do setIniSetting KrakatoaIniPath "JobSettings"  "Priority" ( (SMTDSettings.Priority= (job_priority_update value)) as string )
	on sld_priority clicked value do setIniSetting KrakatoaIniPath "JobSettings"  "Priority" ( (SMTDSettings.Priority= (job_priority_update value)) as string )
	on ddl_poollist selected itm do setIniSetting KrakatoaIniPath "JobSettings"  "PoolName" (SMTDSettings.PoolName = ddl_poollist.selected) 
	on spn_machineLimit changed value do setIniSetting KrakatoaIniPath  "JobSettings"  "MachineLimit" ( (SMTDSettings.MachineLimit  = value) as string) 
	on spn_chunkSize changed value do setIniSetting KrakatoaIniPath  "JobSettings"  "ChunkSize" ( (SMTDSettings.ChunkSize = value) as string)

	--NOT AVAILABLE IN DEADLINE 2.6
	on spn_MaxTasksPerWorker changed value do 
	(
		try(setIniSetting KrakatoaIniPath  "JobSettings"  "MaxTasksPerWorker" ( (SMTDSettings.MaxTasksPerWorker = value) as string))catch()
	)	
	on chk_LimitTasksToNumberOfCpus changed value do 
	(
		try(setIniSetting KrakatoaIniPath  "JobSettings"  "LimitTasksToNumberOfCpus" ( (SMTDSettings.LimitTasksToNumberOfCpus = value) as string))catch()
	)
	
	on btn_openDeadlineMonitor pressed do 
	(
		try(shellLaunch (SMTDPaths.bindir + "DeadlineMonitor.exe") "")catch()
	)	
	
	local incrementPositionRandomSeeds 
	local incrementSpawnRandomSeeds 
	local incrementSpeedRandomSeeds 
	local incrementFumeFXRandomSeeds 
	local incrementRotationRandomSeeds 
	local incrementOtherRandomSeeds 
	local incrementLegacyRandomSeeds 
	local incrementThinkingRandomSeeds

	local IncrementBox3Geometry 
	local IncrementBox3Random
	local IncrementBox3ScalarVector
	local IncrementBox3Icon
	
	local IncrementPRTModifiers
	local IncrementPRTVolumeModifiers
	local IncrementPRTFumeModifiers
	local IncrementGeometryModifiers
	
	local incrementBox3DiskCacheNames
	
	fn incrementSeedInPFlowOperator operator incrementValue=
	(
		if classOf operator == Cache_Disk and incrementBox3DiskCacheNames == true then
		(
			FranticParticles.LogProgress ("   >Adjusting [" + operator.name + "]")
			local theFilename = operator.Write_To_File 
			if theFilename != undefined then
			(
				if not matchpattern theFilename pattern:"*_part*of*_*" then
				(
					if incrementValue >= 0 then 
					(
						setAppData operator 20070719 theFilename
						theNewFile = FranticParticles.MakePartitionFilename theFilename (incrementValue+1) (FranticParticles.GetIntProperty "Partition:Count")
					)	
					else	
					(
						theNewFile = getAppData operator 20070719
						if theNewFile == undefined do theNewFile = theFilename
					)	
				)
				else
				(
					if incrementValue > 0 then 
					(
						theNewFile = FranticParticles.ReplacePartitionInFilename theFilename (incrementValue+1) 
					)	
					else	
					(
						theNewFile = getAppData operator 20070719
					)	
				)		
				operator.Write_To_File = theNewFile 
				FranticParticles.LogProgress ("    +File Name of Disk Cache Operator [" + operator.name + "] adjusted to ["+ getFileNameFile theNewFile + "].")
			)
			else
				FranticParticles.LogProgress ("    -Skipping Disk Cache Operator [" + operator.name + "] - No Filename Found!")
		)

		else 	if classOf operator == Birth_Particle_File then 
		(
			FranticParticles.LogProgress ("   >Adjusting [" + operator.name + "]")
			operator.LoadFilePartition = true
			operator.FilePartitionPart = operator.FilePartitionPart + incrementValue
			FranticParticles.LogProgress ("    +File Partition Part in Birth Particle File Operator [" + operator.name + "] adjusted by ["+ incrementValue as string +"] to [" + operator.FilePartitionPart as string + "].")
		) 
		else if isProperty operator "Random_Seed" then 
		(
			local operatorClass = (classOf operator) as string
			if  (matchPattern operatorClass pattern:"*position*")  then 
			(
				if incrementPositionRandomSeeds do
				(
					FranticParticles.LogProgress ("   >Adjusting Position Operator [" + operator.name + "]")
					operator.Random_Seed = operator.Random_Seed + incrementValue
					FranticParticles.LogProgress ("    +Random Seed in Position Operator [" + operator.name + "] adjusted by ["+ incrementValue as string +"] to [" + operator.Random_Seed as string + "].")
				)	
			) 
			else if (matchPattern operatorClass pattern:"*spawn*")  then 
			(
				if incrementSpawnRandomSeeds do
				(
					FranticParticles.LogProgress ("   >Adjusting Spawn Operator [" + operator.name + "]")
					operator.Random_Seed = operator.Random_Seed + incrementValue
					FranticParticles.LogProgress ("    +Random Seed in Spawn Operator [" + operator.name + "] adjusted by ["+ incrementValue as string +"] to [" + operator.Random_Seed as string + "].")
				)	
			) 
			else if (matchPattern operatorClass pattern:"*speed*")  then 
			(
				if incrementSpeedRandomSeeds do
				(
					FranticParticles.LogProgress ("   >Adjusting Speed Operator [" + operator.name + "]")
					operator.Random_Seed = operator.Random_Seed + incrementValue
					FranticParticles.LogProgress ("    +Random Seed in Speed Operator [" + operator.name + "] adjusted by ["+ incrementValue as string +"] to [" + operator.Random_Seed as string + "].")
				)	
			)
			else if (matchPattern operatorClass pattern:"*rotation*")  then 
			(
				if incrementRotationRandomSeeds do
				(
					FranticParticles.LogProgress ("   >Adjusting Rotation Operator [" + operator.name + "]")
					operator.Random_Seed = operator.Random_Seed + incrementValue
					FranticParticles.LogProgress ("    +Random Seed in Rotation Operator [" + operator.name + "] adjusted by ["+ incrementValue as string +"] to [" + operator.Random_Seed as string + "].")
				)	
			)
			else if (matchPattern operatorClass pattern:"*fumefx*")  then 
			(
				if incrementFumeFXRandomSeeds do
				(
					FranticParticles.LogProgress ("   >Adjusting FumeFX Operator [" + operator.name + "]")
					operator.Random_Seed = operator.Random_Seed + incrementValue
					FranticParticles.LogProgress ("    +Random Seed in FumeFX Operator [" + operator.name + "] adjusted by ["+ incrementValue as string +"] to [" + operator.Random_Seed as string + "].")
				)	
			)
			else if incrementOtherRandomSeeds  then 
			(
				FranticParticles.LogProgress ("   >Adjusting Other Operator [" + operator.name + "]")
				operator.Random_Seed = operator.Random_Seed + incrementValue
				FranticParticles.LogProgress ("    +Random Seed in Operator [" + operator.name + "] adjusted by ["+ incrementValue as string +"] to [" + operator.Random_Seed as string + "].")
			)
		) 
		else if operator != undefined and isProperty operator "Micro_Seed" then 
		(
			FranticParticles.LogProgress ("   >Adjusting Micro Seed in [" + operator.name + "]")
			operator.Micro_Seed = operator.Micro_Seed + incrementValue
			FranticParticles.LogProgress ("    +Micro Seed in Operator [" + operator.name + "] adjusted by ["+ incrementValue as string +"] to [" + operator.Micro_Seed as string + "].")
		)
		else if operator != undefined and isProperty operator "SubOperators" and operator.SubOperators.count > 0 then
		(
			FranticParticles.LogProgress ("   >Adjusting Sub-Operators in Box#3 Data Operator [" + operator.name + "]")
			for subOp in operator.SubOperators do
			(
				if matchPattern ((classof subOp) as string) pattern:"geometryReferenceTarget" and IncrementBox3Geometry do
				(
					local theSubOpName = try(subOp.getName())catch(subOp.name)
					if matchpattern theSubOpName pattern:"*noseed*" then
						FranticParticles.LogProgress ("   >Skipping Geometry Sub-Operator - NOSEED Requested via Sub-Operator's Name...")
					else
					(
						FranticParticles.LogProgress ("   >Adjusting Geometry Sub-Operator...")
						subOp.random_seed = subOp.random_seed + incrementValue
						FranticParticles.LogProgress ("    +Random Seed in Geometry Sub-Operator adjusted by ["+ incrementValue as string +"] to [" + subOp.Random_Seed as string + "].")
					)	
				)
				if matchPattern ((classof subOp) as string) pattern:"randomReferenceTarget" and IncrementBox3Random do
				(
					local theSubOpName = try(subOp.getName())catch(subOp.name)
					if matchpattern theSubOpName pattern:"*noseed*" then
						FranticParticles.LogProgress ("   >Skipping Random Sub-Operator - NOSEED Requested via Sub-Operator's Name...")
					else
					(
						FranticParticles.LogProgress ("   >Adjusting Random Sub-Operator...")
						subOp.random_seed = subOp.random_seed + incrementValue
						FranticParticles.LogProgress ("    +Random Seed in Random Sub-Operator adjusted by ["+ incrementValue as string +"] to [" + subOp.Random_Seed as string + "].")
					)	
				)	
				if (matchPattern ((classof subOp) as string) pattern:"Scalar"  or matchPattern ((classof subOp) as string) pattern:"Vector" ) and IncrementBox3ScalarVector do
				(
					local theSubOpName = try(subOp.getName())catch(subOp.name)
					if matchpattern theSubOpName pattern:"*noseed*" then
						FranticParticles.LogProgress ("   >Skipping "+ (classof subOp) as string+ " Sub-Operator - NOSEED Requested via Sub-Operator's Name...")
					else
					(
						FranticParticles.LogProgress ("   >Adjusting "+ (classof subOp) as string+" Sub-Operator...")
						subOp.random_seed = subOp.random_seed + incrementValue
						FranticParticles.LogProgress ("    +Random Seed in "+ (classof subOp) as string+ " Sub-Operator adjusted by ["+ incrementValue as string +"] to [" + subOp.Random_Seed as string + "].")
					)	
				)	
				if matchPattern ((classof subOp) as string) pattern:"Icon"  and IncrementBox3Icon do
				(
					local theSubOpName = try(subOp.getName())catch(subOp.name)
					if matchpattern theSubOpName pattern:"*noseed*" then
						FranticParticles.LogProgress ("   >Skipping Icon Sub-Operator - NOSEED Requested via Sub-Operator's Name...")
					else
					(
						FranticParticles.LogProgress ("   >Adjusting Icon Sub-Operator...")
						subOp.random_seed = subOp.random_seed + incrementValue
						FranticParticles.LogProgress ("    +Random Seed in Icon Sub-Operator adjusted by ["+ incrementValue as string +"] to [" + subOp.Random_Seed as string + "].")
					)	
				)				
			)
		)
	)
	
	
	--RECURSIVE UPDATE BY SOLITUDE:
	fn incrementdsops g ds incrementvalue =
	(
		try(FranticParticles.LogProgress (" >Scanning TP [" + g.name + "], Dynamic Set "+ ds as string +" for Operators..."))catch()
		for op = 1 to ds.Operators.count do
		(
			local theOp = ds.Operators[op]
			local theOpName = try(theOp.name)catch(undefined)
			if theOpName == undefined do theOpName = try(theOp.getName())catch(undefined)
			if theOpName == undefined do theOpName = ""
			if (isProperty theOp "RandomSeed" or matchpattern theOpName pattern:"*RandomSeed*" == true) and (matchpattern theOpName pattern:"*NOSEED*" == false) then
			(
				FranticParticles.LogProgress (" >Adjusting Random Seed in TP [" + g.name + "], Dynamic Set "+ ds as string +", Operator "+ op as string+"...")
				if (matchpattern theOpName pattern:"*RandomSeed*" == true) then
				(
					try 
					(
						theOp.value += incrementValue
						FranticParticles.LogProgress (" +Value in TP Input containing '*Randomseed*' in the name adjusted by ["+ incrementValue as string +"] to [" + theOp.value as string + "].")
					)catch()
				)
				if isProperty theOp "RandomSeed" then
				(
					theOp.randomSeed += incrementValue
					FranticParticles.LogProgress (" +Random Seed in TP Operator adjusted by ["+ incrementValue as string +"] to [" + theOp.randomSeed as string + "].")
				)
			)
		)--end op loop
		for dssub = 1 to ds.numsubs do
		(
			if (try((not matchPattern ds[dssub].comment pattern:"*NOSEED*") and (matchpattern ds[dssub].name pattern:"DS*"))catch(false)) do
			(
				incrementdsops g ds[dssub] incrementvalue
			)
		)
	)

	fn recursiveincrementTP theTP incrementvalue =
	(
		local theMD = theTP.MasterDynamic
		for i = 1 to theMD.numsubs where try((matchpattern theMD[i].name pattern:"DS*") and (not matchPattern theMD[i].comment pattern:"*NOSEED*"))catch(false)  do   
		(
			incrementdsops theTP theMD[i] incrementvalue
		)
	)	

	-- This function increments the partition
	fn IncrementAllPartitionValues incrementValue selectedOnly:false = 
	(
		try(Krakatoa_SeedIncrement_UserFunction incrementValue)catch() --try to call the global function - users can define this function to get notified when seeds change
		global Krakatoa_SeedIncrement_LastValue = incrementValue --set the global variable to the last seed increment.
	

		FranticParticles.LogProgress (">Adjusting Random Seeds in " + (if selectedOnly then "Selected Objects by [" else "Scene Objects by [")+ incrementValue as string + "]..." )
		incrementPositionRandomSeeds = FranticParticles.GetBoolProperty "Partition:IncrementPositionRandomSeeds"
		incrementSpawnRandomSeeds = FranticParticles.GetBoolProperty "Partition:IncrementSpawnRandomSeeds"
		incrementSpeedRandomSeeds = FranticParticles.GetBoolProperty "Partition:IncrementSpeedRandomSeeds"
		incrementRotationRandomSeeds = FranticParticles.GetBoolProperty "Partition:IncrementRotationRandomSeeds"
		
		incrementFumeFXRandomSeeds = FranticParticles.GetBoolProperty "Partition:IncrementFumeFXRandomSeeds"
		incrementOtherRandomSeeds = FranticParticles.GetBoolProperty "Partition:IncrementOtherRandomSeeds"
		incrementLegacyRandomSeeds = FranticParticles.GetBoolProperty "Partition:IncrementLegacyRandomSeeds"
		incrementThinkingRandomSeeds = FranticParticles.GetBoolProperty "Partition:IncrementThinkingRandomSeeds"

		IncrementBox3Geometry = FranticParticles.GetBoolProperty "Partition:IncrementBox3Geometry"
		IncrementBox3Random= FranticParticles.GetBoolProperty "Partition:IncrementBox3Random"
		IncrementBox3ScalarVector= FranticParticles.GetBoolProperty "Partition:IncrementBox3ScalarVector"
		IncrementBox3Icon= FranticParticles.GetBoolProperty "Partition:IncrementBox3Icon"

		incrementBox3DiskCacheNames = FranticParticles.GetBoolProperty "Partition:IncrementBox3DiskCacheNames"
		
		IncrementPRTModifiers = FranticParticles.GetBoolProperty  "Partition:IncrementPRTModifiers" 
		IncrementPRTVolumeModifiers = FranticParticles.GetBoolProperty  "Partition:IncrementPRTVolumeModifiers" 
		IncrementPRTFumeModifiers = FranticParticles.GetBoolProperty  "Partition:IncrementPRTFumeFXModifiers" 
		IncrementGeometryModifiers = FranticParticles.GetBoolProperty  "Partition:IncrementGeometryModifiers" 		
		
		
		FranticParticles.LogProgress ("   *Increment PFlow Position Seeds:                        " + incrementPositionRandomSeeds as string)
		FranticParticles.LogProgress ("   *Increment PFlow Spawn Seeds:                           " + incrementSpawnRandomSeeds as string)
		FranticParticles.LogProgress ("   *Increment PFlow Speed Seeds:                           " + incrementSpeedRandomSeeds as string)
		FranticParticles.LogProgress ("   *Increment PFlow FumeFX Seeds:                          " + incrementFumeFXRandomSeeds as string)
		FranticParticles.LogProgress ("   *Increment PFlow Rotation Seeds:                        " + incrementRotationRandomSeeds as string)
		FranticParticles.LogProgress ("   *Increment PFlow Other Seeds:                           " + incrementOtherRandomSeeds as string)
		FranticParticles.LogProgress ("   *Increment Max Legacy Particles Seeds:                  " + incrementLegacyRandomSeeds as string)
		FranticParticles.LogProgress ("   *Increment Thinking Particles Seeds:                    " + IncrementThinkingRandomSeeds as string)
		FranticParticles.LogProgress ("   " )
		FranticParticles.LogProgress ("   *Increment PFlow Box#3 Geometry Sub-Operators:          " + incrementBox3Geometry as string)
		FranticParticles.LogProgress ("   *Increment PFlow Box#3 Random Sub-Operators:            " + incrementBox3Random as string)
		FranticParticles.LogProgress ("   *Increment PFlow Box#3 Scalar and Vector Sub-Operators: " + incrementBox3ScalarVector as string)
		FranticParticles.LogProgress ("   *Increment PFlow Box#3 Icon Sub-Operators:              " + incrementBox3Icon as string)
		FranticParticles.LogProgress ("   " )
		FranticParticles.LogProgress ("   *Increment PRT Loader Modifiers:                        " + IncrementPRTModifiers as string)
		FranticParticles.LogProgress ("   *Increment PRT Volume, PRT Surface and Modifiers:       " + IncrementPRTVolumeModifiers as string)
		FranticParticles.LogProgress ("   *Increment PRT FumeFX and Modifiers:                    " + IncrementPRTFumeModifiers as string)
		
		FranticParticles.LogProgress ("   *Increment Geometry Modifiers:                          " + IncrementGeometryModifiers as string)

		FranticParticles.LogProgress ("   *Increment PFlow Box#3 Disk Cache Filenames:            " + incrementBox3DiskCacheNames as string)
		

		
		local theObjects = if selectedOnly then selection as array else objects as array
		for g in theObjects do 
		(
			case classOf g of
			(
				PF_Source: 
				(
					if not matchPattern (g.name) pattern:"*noseed*" then
					(
						FranticParticles.LogProgress (" >Processing Operators in PFlow Source [" + g.name + "]")
						for j = 1 to g.numActions() do 
						(
							local operator = g.getAction j
							if not matchPattern operator.name pattern:"*noseed*" then
							(
								incrementSeedInPFlowOperator operator incrementValue
							)	
							else
								FranticParticles.LogProgress ("   -Skipping PFlow Operator [" + operator.name + "] - NOSEED Requested via Operator's Name...")
						)--end j loop	
						FranticParticles.LogProgress (" >Processing Events in PFlow Source [" + g.name + "]")
						for i = 1 to g.baseObject.numSubs do 
						(
							local event = g.baseObject[i]
							if matchpattern ((classOf event.object) as string) pattern:"Event" do 
							(
								if not matchPattern (event.name) pattern:"*noseed*" then
								(
									FranticParticles.LogProgress ("  >Processing Operators in PFlow Event [" + event.name + "]")
									for j = 1 to event.numActions() do 
									(
										local operator = event.getAction j
										if not matchPattern operator.name pattern:"*noseed*" then
										(
											incrementSeedInPFlowOperator operator incrementValue
										)	
										else
											FranticParticles.LogProgress ("   -Skipping PFlow Operator [" + operator.name + "] - NOSEED Requested via Operator's Name...")
									)--end j loop
								)
								else	
									FranticParticles.LogProgress ("  -Skipping All Operators in PFlow Event [" + event.name + "] - NOSEED Requested via Event's Name...")
							)--end if event event
						)--end i loop
					)		
					else	
						FranticParticles.LogProgress (" -Skipping All Events in PFlow [" + g.name + "] - NOSEED Requested via PF_Source's Name...")
				)--end pf_source case
				PCloud: (
							if incrementLegacyRandomSeeds then
							(
								if matchPattern (g.name) pattern:"*noseed*" then
									FranticParticles.LogProgress (" -Skipping PCloud [" + g.name + "] - NOSEED requested via Object's Name.")
								else
								(
									FranticParticles.LogProgress (" >Adjusting Random Seed in PCloud [" + g.name + "]")
									g.seed += incrementValue
									FranticParticles.LogProgress ("  +Random Seed in PCloud [" + g.name + "] adjusted by ["+ incrementValue as string +"] to [" + g.seed as string + "].")
								)	
							)	
						)
				Blizzard: (
							if incrementLegacyRandomSeeds then
							(
								if matchPattern (g.name) pattern:"*noseed*" then
									FranticParticles.LogProgress (" -Skipping Blizzard [" + g.name + "] - NOSEED requested via Object's Name.")
								else
								(
									FranticParticles.LogProgress (" >Adjusting Random Seed in Blizzard [" + g.name + "]")
									g.seed += incrementValue
									FranticParticles.LogProgress ("  +Random Seed in Blizzard [" + g.name + "] adjusted by ["+ incrementValue as string +"] to [" + g.seed as string + "].")
								)	
							)	
						)
				PArray: (
							if incrementLegacyRandomSeeds then
							(
								if matchPattern (g.name) pattern:"*noseed*" then
									FranticParticles.LogProgress (" -Skipping PArray [" + g.name + "] - NOSEED requested via Object's Name.")
								else
								(
									FranticParticles.LogProgress (" >Adjusting Random Seed in PArray [" + g.name + "]")
									g.seed += incrementValue
									FranticParticles.LogProgress ("  +Random Seed in PArray [" + g.name + "] adjusted by ["+ incrementValue as string +"] to [" + g.seed as string + "].")
								)	
							)	
						)
				SuperSpray: (
							if incrementLegacyRandomSeeds then
							(
								if matchPattern (g.name) pattern:"*noseed*" then
									FranticParticles.LogProgress (" -Skipping SuperSpray [" + g.name + "] - NOSEED requested via Object's Name.")
								else
								(
									FranticParticles.LogProgress (" >Adjusting Random Seed in SuperSpray [" + g.name + "]")
									g.seed += incrementValue
									FranticParticles.LogProgress ("  +Random Seed in SuperSpray [" + g.name + "] adjusted by ["+ incrementValue as string +"] to [" + g.seed as string + "].")
								)
							)	
						)
				Thinking: ( --new code by Solitude
						if incrementThinkingRandomSeeds then
						(
							if matchPattern (g.name) pattern:"*noseed*" then
								FranticParticles.LogProgress (" -Skipping Thinking Particles [" + g.name + "] - NOSEED requested via Object's Name.")
							else
								recursiveincrementTP g incrementvalue
						)--end if TP on   
					)--end TP case
					KrakatoaPRTLoader: (
						if IncrementPRTModifiers then
						(
							if matchPattern (g.name) pattern:"*noseed*" then
								FranticParticles.LogProgress (" -Skipping PRT Loader [" + g.name + "] - NOSEED requested via Object's Name.")
							else
							(
								for m in g.modifiers where isProperty m #seed do
								(
									if matchPattern m.name pattern:"*noseed*" then
									(
										FranticParticles.LogProgress (" -Skipping Modifier ["+m as string+"] on [" + g.name + "] - NOSEED requested via Modifier's Name.")
									)
									else
									(
										FranticParticles.LogProgress (" >Adjusting Random Seed in PRT Loader [" + g.name + "], Modifier ["+ m as string +"]...")
										m.seed += incrementValue
										FranticParticles.LogProgress ("  +Random Seed in PRT Loader adjusted by ["+ incrementValue as string +"] to [" + m.Seed as string + "].")
									)
								)
							)
						)	
					)--end PRT Loader case
					PRT_Volume: (
						if IncrementPRTVolumeModifiers then
						(
							if matchPattern (g.name) pattern:"*noseed*" then
								FranticParticles.LogProgress (" -Skipping PRT Volume [" + g.name + "] - NOSEED requested via Object's Name.")
							else
							(
								try
								(
									FranticParticles.LogProgress (" >Adjusting Random Seed in PRT Volume [" + g.name + "] Base Object...")
									g.RandomSeed += incrementValue
									FranticParticles.LogProgress ("  +Random Seed in PRT Volume Base Object adjusted by ["+ incrementValue as string +"] to [" + g.RandomSeed as string + "].")
								)
								catch
								(
									FranticParticles.LogProgress (" -Failed to adjust PRT Volume Base Object Random Seed.")
								)
								for m in g.modifiers where isProperty m #seed do
								(
									if matchPattern m.name pattern:"*noseed*" then
									(
										FranticParticles.LogProgress (" -Skipping Modifier ["+m as string+"] on [" + g.name + "] - NOSEED requested via Modifier's Name.")
									)
									else
									(
										FranticParticles.LogProgress (" >Adjusting Random Seed in PRT Volume [" + g.name + "], Modifier ["+ m as string +"]...")
										m.seed += incrementValue
										FranticParticles.LogProgress ("  +Random Seed in PRT Volume Modifier adjusted by ["+ incrementValue as string +"] to [" + m.Seed as string + "].")
									)
								)
							)
						)	
					)--end PRT Volume case			
					PRT_FumeFX: (
						if IncrementPRTFumeModifiers then
						(
							if matchPattern (g.name) pattern:"*noseed*" then
								FranticParticles.LogProgress (" -Skipping PRT FumeFX [" + g.name + "] - NOSEED requested via Object's Name.")
							else
							(
								try
								(
									FranticParticles.LogProgress (" >Adjusting Random Seed in PRT FumeFX [" + g.name + "] Base Object...")
									g.RandomSeed += incrementValue
									FranticParticles.LogProgress ("  +Random Seed in PRT FumeFX Base Object adjusted by ["+ incrementValue as string +"] to [" + g.RandomSeed as string + "].")
								)
								catch
								(
									FranticParticles.LogProgress (" -Failed to adjust PRT FumeFX Base Object Random Seed.")
								)
								for m in g.modifiers where isProperty m #seed do
								(
									if matchPattern m.name pattern:"*noseed*" then
									(
										FranticParticles.LogProgress (" -Skipping Modifier ["+m as string+"] on [" + g.name + "] - NOSEED requested via Modifier's Name.")
									)
									else
									(
										FranticParticles.LogProgress (" >Adjusting Random Seed in PRT FumeFX [" + g.name + "], Modifier ["+ m as string +"]...")
										m.seed += incrementValue
										FranticParticles.LogProgress ("  +Random Seed in PRT FumeFX Modifier adjusted by ["+ incrementValue as string +"] to [" + m.Seed as string + "].")
									)
								)
							)
						)	
					)--end PRT FumeFX case		
					PRT_Surface: (
						if IncrementPRTVolumeModifiers then
						(
							if matchPattern (g.name) pattern:"*noseed*" then
								FranticParticles.LogProgress (" -Skipping PRT Surface [" + g.name + "] - NOSEED requested via Object's Name.")
							else
							(
								try
								(
									FranticParticles.LogProgress (" >Adjusting Random Seed in PRT FumeFX [" + g.name + "] Base Object...")
									g.RandomSeed += incrementValue
									FranticParticles.LogProgress ("  +Random Seed in PRT Surface Base Object adjusted by ["+ incrementValue as string +"] to [" + g.RandomSeed as string + "].")
								)
								catch
								(
									FranticParticles.LogProgress (" -Failed to adjust PRT Surface Base Object Random Seed.")
								)
								for m in g.modifiers where isProperty m #seed do
								(
									if matchPattern m.name pattern:"*noseed*" then
									(
										FranticParticles.LogProgress (" -Skipping Modifier ["+m as string+"] on [" + g.name + "] - NOSEED requested via Modifier's Name.")
									)
									else
									(
										FranticParticles.LogProgress (" >Adjusting Random Seed in PRT Surface [" + g.name + "], Modifier ["+ m as string +"]...")
										m.seed += incrementValue
										FranticParticles.LogProgress ("  +Random Seed in PRT Surface Modifier adjusted by ["+ incrementValue as string +"] to [" + m.Seed as string + "].")
									)
								)
							)
						)	
					)--end PRT Surface case						
					default: (
						if IncrementGeometryModifiers then
						(
							if matchPattern (g.name) pattern:"*noseed*" then
								FranticParticles.LogProgress (" -Skipping Geometry Object [" + g.name + "] - NOSEED requested via Object's Name.")
							else
							(
								for m in g.modifiers where isProperty m #seed do
								(
									if matchPattern m.name pattern:"*noseed*" then
									(
										FranticParticles.LogProgress (" -Skipping Modifier ["+m as string+"] on [" + g.name + "] - NOSEED requested via Modifier's Name.")
									)
									else
									(
										FranticParticles.LogProgress (" >Adjusting Random Seed in Object [" + g.name + "], Modifier ["+ m as string +"]...")
										m.seed += incrementValue
										FranticParticles.LogProgress ("  +Random Seed in Object adjusted by ["+ incrementValue as string +"] to [" + m.Seed as string + "].")
									)
								)
							)
						)	
					)--end default handling of modifiers
			)--end case			
		)--end g loop
		FranticParticles.LogProgress (">Adjusting Random Seeds FINISHED.")
		true
	)--end fn
	
	fn GetFramesString = 
	(
		local ss = stringStream ""
		case rendTimeType of
		(
			1: format "%" (currentTime.frame as integer) to:ss
			2: format "% to %" animationRange.start animationRange.end to:ss
			3: format "% to %" rendStart rendEnd to:ss
			4: format "%" rendPickupFrames to:ss
		)
		ss as string
	)
	
	fn SubmissionSanityCheck = 
	(
		if FranticParticles.GetProperty "ParticleFiles" == "" do (
			messageBox "Please indicate a path to save the particles to." title:"Krakatoa"
			return false
		)
		
		if ddl_deadlinePartitionMode.selection > 1 do
		(
			local firstBirth = FranticParticleRenderMXS.GetEarliestBirthFrame()
			if sliderTime > firstBirth do 
			(
				local str = "3ds Max is going to refresh the particle sources once per partition.\n"
				str += "This may be unnecessary if you change the slider time to frame " + (firstBirth as string) + "\n\n"
				str += "Press [Yes] to change the time slider to frame "+ firstBirth as string+"\n"
				str += "Press [No] to continue on the current frame\n"
				str += "Press [Cancel] to cancel partitioning submission."
				local result = yesNoCancelBox str title:"WARNING!"
				if result== #yes do sliderTime = firstBirth
				if result == #cancel do return false
			)
		)	
		true
	)

	fn getINI theCategory theKey theDefault executeIt:true=
	(
		local result 
		if executeIt then
		(
			result = try(execute (getIniSetting KrakatoaIniPath theCategory theKey))catch(OK)
			if result == OK do result = theDefault
		)
		else 
		(
			result = (getIniSetting KrakatoaIniPath theCategory theKey)
			if result == "" do result = theDefault
		)	
		result
	)		
	
	fn SubmitJob partitionStart partitionEnd partCount partitionMode:#tasks PartitionRange:true timeout:3600 =
	(
		local initialArgs = ""
		local oldJobName = SMTDSettings.JobName 
		local oldComment = SMTDSettings.Comment 
		SMTDSettings.Comment = edt_comment.text
		SMTDSettings.JobName = edt_jobname.text
		
		SMTDSettings.DeadlineSubmissionSuccessful = false
		SMTDSettings.DeadlineSubmissionLastJobID = "failed"
		renderSceneDialog.Commit()

		local TempMaxFile = SMTDPaths.TempDir + maxFileName
		if maxFileName == "" do TempMaxFile += "untitled.max"
		if (doesFileExist TempMaxFile) do deleteFile TempMaxFile
		result = SMTDFunctions.SaveMaxFileCopy TempMaxFile
		if result != undefined do return result
		
		theFrameSequence = ""
		
--SET TASKS IN A SINGLE JOB TO CALCULATE ALL PARTITIONS USING A SCRIPT
		if partitionMode == #tasks do 
		(
			if PartitionRange then
			(	
				for i = partitionStart to partitionEnd-1 do theFrameSequence+= i as string + ","
				theFrameSequence += partitionEnd as string
			)
			else
			(
				for i = 1 to partCount-1 do theFrameSequence+= i as string + ","
				theFrameSequence += partCount as string
			)	
			
			oldMXS = SMTDSettings.SubmitAsMXSJob 
			oldMXSFile = SMTDSettings.MAXScriptFile 
			oldSingleTask = SMTDSettings.SingleTaskJob
			oldWSMode = SMTDSettings.ForceWorkstationMode 
			
			MAXScriptFile	= FranticParticles.KrakatoaHome + "Scripts\\KrakatoaPartitionTasksOnDeadline.ms"
				
			SMTDSettings.SubmitAsMXSJob = true
			SMTDSettings.MAXScriptFile = MAXScriptFile 
			SMTDSettings.SingleTaskJob = true
			SMTDSettings.ForceWorkstationMode = false
				
			if not doesFileExist MAXScriptFile do 
			(
				SMTDSettings.SubmitAsMXSJob = oldMXS 
				SMTDSettings.MAXScriptFile = oldMXSFile 
				SMTDSettings.SingleTaskJob = oldSingleTask 		
				SMTDSettings.ForceWorkstationMode = oldWSMode
				return #PartitionScriptNotFound
			)	
			
		)
--END TASK PER PARTITION
			
		local theOverridePath = FranticParticles.GetProperty "ParticleFiles"
		if ((SMTDFunctions.CreateSubmitInfoFile SMTDPaths.SubmitInfofile customFrameSequence:theFrameSequence customOutputFile:theOverridePath  ) != true) do return #SubmitInfoFileCreationFailed
		if ((SMTDFunctions.CreateJobInfoFile SMTDPaths.JobInfofile renderOutputOverride:theOverridePath ) != true) do return #JobInfoFileCreationFailed
		
		if not doesFileExist SMTDPaths.SubmitInfofile do return #SubmitInfoFileMissing
		if not doesFileExist SMTDPaths.JobInfofile do return #JobInfoFileMissing
		
		initialArgs += "\"" +SMTDPaths.SubmitInfofile + "\" \"" + SMTDPaths.JobInfofile  + "\" \"" + TempMaxFile  + "\" "
		
		if partitionMode == #tasks do 
		(				
			initialArgs += "\"" + MAXScriptFile + "\" "	

			SMTDSettings.SubmitAsMXSJob = oldMXS 
			SMTDSettings.MAXScriptFile = oldMXSFile 
			SMTDSettings.SingleTaskJob = oldSingleTask 		
			SMTDSettings.ForceWorkstationMode = oldWSMode
		)	
		
		local retCode = SMTDFunctions.waitForCommandToComplete initialArgs timeout
		
		SMTDSettings.JobName  = oldJobName 
		SMTDSettings.Comment = oldComment 

		SMTD_LastMessage = SMTDFunctions.getRenderMessage()
		if retCode == #success then
		(
			SMTDSettings.DeadlineSubmissionSuccessful = true
			SMTDFunctions.getJobIDFromMessage SMTD_LastMessage
			try(FF_AssetTracker_Functions.TrackDeadlineRender SMTDSettings.DeadlineSubmissionLastJobID)catch()
		)	
		retCode 
	)		
	
	fn SubmitOnePartitionJobToDeadline partitionStart partitionEnd quiet:false partitionMode:#tasks PartitionRange:true = 
	(
		if( (not quiet) AND (not SubmissionSanityCheck()) ) do
			return false

		-- Save some values that we change temporarily
		local savedRenderTarget = FranticParticles.GetProperty "RenderTarget"
		local savedParticleFiles = FranticParticles.GetProperty "ParticleFiles"	
		local savedJobName = SMTDSettings.jobName
		local savedOOM = SMTDSettings.OutOfOrderMethod
		local savedPreviewJob = SMTDSettings.RenderFramesPreviewJob 
		local savedOneCPUPerTask = SMTDSettings.OneCpuPerTask			
		
		/*ENFORCE SETTINGS! - This is to avoid conflicts with SMTD GUI that might have been opened AFTER Krakatoa and could overwrite these values! */
		try(SMTDSettings.SequentialJob = true)catch() --available sequential rendering in Deadline 2.6 and up only!
		SMTDSettings.LimitEnabled = true --always enabled limit
		SMTDSettings.MachineLimit = getInI "JobSettings" "MachineLimit" SMTDSettings.MachineLimit --set the limit from the INI
		if SMTDSettings.MachineLimit == 0 do SMTDSettings.MachineLimit = 1
		
		SMTDSettings.RenderFramesPreviewJob = false
		SMTDSettings.OutOfOrderMethod = #normal
		SMTDSettings.OneCpuPerTask = true
	
		-- Close the render scene dialog so we can change render properties
		renderSceneDialog.close()
		rendSaveFile = false			
		
		-- Don't want to save xml files for
		FranticParticles.SetProperty "RenderTarget" "Direct Render"
		
		local partitionCount = (FranticParticles.GetIntProperty "Partition:Count")
		if partitionMode == #tasks then
		(
			try(SMTDSettings.MaxTasksPerWorker = getInI "JobSettings" "MaxTasksPerWorker" SMTDSettings.MaxTasksPerWorker )catch()
			try(SMTDSettings.LimitTasksToNumberOfCpus = getInI "JobSettings" "LimitTasksToNumberOfCpus" SMTDSettings.LimitTasksToNumberOfCpus )catch()
			SMTDSettings.ChunkSize = 1
			if ckb_incrementSelectedOnly.checked then
				FranticParticles.SetProperty "Partition:AffectSeedsInObjects" ((for o in selection collect o.name) as string)
			else	
				FranticParticles.SetProperty "Partition:AffectSeedsInObjects" "#()"
			
			if PartitionRange then
			(
				SMTDSettings.jobName = savedJobName + " [RANGE "+(partitionStart as string) + " TO " + partitionEnd as string + " OF " + partitionCount as string +" PARTS] "
				partitionCount = partitionEnd - partitionStart + 1
			)	
			else	
				SMTDSettings.jobName = savedJobName + " ["+(partitionCount as string) + " PARTS] "
		)	
		else
		(
			SMTDSettings.ChunkSize = getInI "JobSettings" "ChunkSize" SMTDSettings.ChunkSize  --set the chunk size from the INI
			try(SMTDSettings.MaxTasksPerWorker = 1)catch()
			SMTDSettings.jobName = savedJobName + " [PART " + (partitionStart as string) + " OF " + (partitionCount as string) + "]"
			local partitionFilename = FranticParticles.MakePartitionFilename savedParticleFiles partitionStart partitionCount
			FranticParticles.SetProperty "ParticleFiles" partitionFilename
		)	
		
		local result = SubmitJob partitionStart partitionEnd partitionCount partitionMode:partitionMode PartitionRange:PartitionRange
			
		-- Restore all the partition values to their original
		FranticParticles.SetProperty "RenderTarget" savedRenderTarget
		FranticParticles.SetProperty "ParticleFiles" savedParticleFiles
		SMTDSettings.jobName = savedJobName
		SMTDSettings.OutOfOrderMethod = savedOOM
		SMTDSettings.RenderFramesPreviewJob = savedPreviewJob
		SMTDSettings.OneCpuPerTask = savedOneCPUPerTask
		
		if( not quiet ) do (
			SMTD_LastMessage = SMTDFunctions.getRenderMessage()
			local strstr = SMTD_LastMessage as stringStream
			local txt = ""
			while not eof strstr do 
			(
				local theLine = (readline strstr)
				FranticParticles.LogProgress theLine
				txt += theLine + "\n"
			)	
		
			if( result == #success ) then
			(
				
				theMessage = "Deadline Submission SUCCESSFUL.\n" 
				theMessage += "Partitions Submitted: " + partitionCount as string  + "\n\n"
				theMessage += txt 
				MessageBox  theMessage title:"Krakatoa Deadline Submission"
			)	
			else
			(
				case result of
				(
					#PartitionScriptNotFound: 
					(
						theMessage = "Deadline Submission FAILED!\n\nCould not locate the MAXScript Component\n[KrakatoaPartitionTasksOnDeadline.ms]\n" 
					)	
					#SubmitInfoFileCreationFailed:
					(
						theMessage = "Deadline Submission FAILED!\n\nCould not create Submit Info File.\n" 
					)
					#JobInfoFileCreationFailed:
					(
						theMessage = "Deadline Submission FAILED!\n\nCould not create Job Info File.\n" 
					)
					#SubmitInfoFileMissing:
					(
						theMessage = "Deadline Submission FAILED!\n\nCould not find the Submit Info File.\n" 
					)
					#JobInfoFileMissing:
					(
						theMessage = "Deadline Submission FAILED!\n\nCould not find the Job Info File.\n" 						
					)
					default: 
					(
						theMessage = "Deadline Submission FAILED!\n\n" + txt
					)	
				)	
				MessageBox theMessage title:"Krakatoa Deadline Submission"
			)					
		)
		result == #success
	)
	
	fn checkForMissingUVChannels =
	(
		local activeChannelsSettings = FranticParticles.getProperty "ActiveParticleChannels"
		theFS = filterString activeChannelsSettings ","
		local theActiveChannels = #()
		for i = 1 to theFS.count by 3 do 
			append theActiveChannels theFS[i]
		
		local theChannels = FranticParticleRenderMXS.getSceneMappingChannelsUsed()
		local theMissingChannels = #()
		if theChannels[1] and (findItem theActiveChannels "TextureCoord") == 0 do append theMissingChannels "TextureCoord"
		for c in theChannels where c != 1 do 
		(
			local theName = "Mapping"+c as string
			if (findItem theActiveChannels theName) == 0 do 
				append theMissingChannels theName
		)	
		
		if theMissingChannels.count > 0 then
		(
			if theMissingChannels.count == 1 then 
			(
				local txt = "The following Mapping Channel has been requested via Particle Flow Operators or Box #3 SubOps\nbut is not enabled for saving in the Channels rollout.\n\n"
				local theChannelsSingularPlural="this channel"
			)
			else
			(
				local txt = "The following Mapping Channels have been requested via Particle Flow Operators or Box #3 SubOps\nbut are not enabled for saving in the Channels rollout.\n\n"
				local theChannelsSingularPlural="these channels"
			)	
			for i in theMissingChannels do txt += i + "\n"
			txt +="\nClick [Yes] to ADD "+ theChannelsSingularPlural +" to the list of Channels To Save and continue Partitioning.\nClick [No] to IGNORE this warning and continue Partitioning.\n"
			local answer = querybox txt title:"KRAKATOA: Potentially Missing Mapping Channels!"
			if answer then
			(
				for i in theMissingChannels do 
					activeChannelsSettings += ","+ i + ",float32,3"
					
				--if matchPattern activeChannelsSettings pattern:"*," do activeChannelsSettings = substring activeChannelsSettings 1 (activeChannelsSettings.count-1)
				FranticParticles.setProperty "ActiveParticleChannels" activeChannelsSettings
				Krakatoa_GUI_Channels.refresh_GUI()
			)
		)
	)
	
	--on btn_checkForMissingUVChannels pressed do checkForMissingUVChannels()
	
	fn SubmitPartitionJobsToDeadline mode:#all = 
	(
		if( not SubmissionSanityCheck() ) do
			return false

		local partitionCount = (FranticParticles.GetIntProperty "Partition:Count")
		if mode==#all then
		(
			local startPartition = 1
			local endPartition = partitionCount 
			local numberOfPartitionsToProcess = partitionCount
		)
		else	
		(
			local startPartition = spn_PartitionStart.value
			local endPartition = spn_PartitionEnd.value
			local numberOfPartitionsToProcess = endPartition - startPartition + 1
		)		
		
		local partitionRange = spn_PartitionEnd.value - spn_PartitionStart.value + 1
		local theCountString = if mode == #all then 
			(partitionCount as string) 
		else 
			((numberOfPartitionsToProcess as string) + " of " + (partitionCount as string) + " ("+ startPartition as string + " to " + endPartition as string +")")
		local respository = if(SMTDSettings.CurrentRepository == "") then SMTDFunctions.GetNetworkRoot() else SMTDSettings.CurrentRepository
		local statusMsg =	"Submitting " + theCountString + " Partitions to Deadline.\n" +
							"Frames: " + GetFramesString() + "\n" +
							"Repository: " + respository  + "\n" +
							"Machine Limit: " + (SMTDSettings.MachineLimit as string) + "\n" +
							"Enforce Sequential Rendering: " + (SMTDSettings.SequentialJob as string) + "\n" +
							"Filename: " + (FranticParticles.GetProperty "ParticleFiles") + "\n"
		
		local theViewportCamera = viewport.getCamera()
		local oldMultiPassState = false
		if isValidNode theViewportCamera do 
		(
			try
			(
				oldMultiPassState = theViewportCamera.mpassEnabled 
				theViewportCamera.mpassEnabled = false
				if oldMultiPassState do FranticParticles.LogDebug "+Temporarily Disabled Viewport Camera MPass Effects To Avoid Multiple File Saving."
			)
			catch(FranticParticles.LogDebug "--Failed to Disable Viewport Camera MPass Effects To Avoid Multiple File Saving.")
		)			
		
		local partitionProgressCounter = 0
		for partitionNumber = startPartition  to endPartition do 
		(
			partitionProgressCounter+=1
			prg_progress.value = 100.0 * partitionProgressCounter / numberOfPartitionsToProcess 
			statusMsg += "Partition " + (partitionNumber as string) + " of " + (partitionCount as string) + ": "

			IncrementAllPartitionValues (partitionNumber-1) selectedOnly:ckb_incrementSelectedOnly.state
			
			if(SubmitOnePartitionJobToDeadline partitionNumber partitionNumber quiet:true partitionMode:#jobs PartitionRange:false) then 
				statusMsg += "Successful\n" 
			else 
				statusMsg += "FAILED\n"
			
			IncrementAllPartitionValues -(partitionNumber-1) selectedOnly:ckb_incrementSelectedOnly.state
		)
		prg_progress.value = 0
		if isValidNode theViewportCamera do 
		(
			try
			(
				theViewportCamera.mpassEnabled = oldMultiPassState
				if oldMultiPassState do FranticParticles.LogDebug "+Re-enabled Viewport Camera MPass Effects."
			)
			catch()
		)				
		MessageBox statusMsg title:"Krakatoa Deadline Submission"
		true
	)
	
	fn updateDeadlineControls =
	(
		/*if FranticParticleRenderMXS.DeadlineDetected == 2 do
		(
			chk_onlypool.state = SMTDSettings.PoolExclusive
			chk_onlypool.enabled = true

			if SMTDSettings.Categories.count == 0 do SMTDFunctions.CollectCategories()
			ddl_category.items = SMTDSettings.Categories
			local theIndex = findItem SMTDSettings.Categories SMTDSettings.Category
			if theIndex == 0 then theIndex = 1
			ddl_category.selection = theIndex
			btn_openDeadlineMonitor.caption = "Open Deadline Monitor 2.x..."
			lbl_category.caption = "Category:"
		)*/
		if FranticParticleRenderMXS.DeadlineDetected == 3 do 
		(
			--chk_onlypool.enabled = chk_onlypool.state = false
			try
			(
				if SMTDSettings.Groups.count == 0 do SMTDFunctions.CollectGroups()
				ddl_category.items = SMTDSettings.Groups
				local theIndex = findItem SMTDSettings.Groups SMTDSettings.Group
				if theIndex == 0 then theIndex = 1
				ddl_category.selection = theIndex
			)catch()	
			btn_openDeadlineMonitor.caption = "Open Deadline Monitor..."
			lbl_category.caption = "    Group:"
		)				
	)
		
	
	fn refresh_GUI =
	(
		
		--FranticParticleRenderMXS.DeadlineDetected = 0  --force to no deadline for debugging purposes
		tweakControlPositions()
		oldState = try(FranticParticles.GetBoolProperty "GUI:ParticlePartitioningRolloutOpen")catch(false)
		
		local enableSaveParticleFileControls = (FranticParticles.GetProperty "ParticleMode") == "Save Particles To File Sequence"
		
		spn_partitionCount.value = FranticParticles.GetIntProperty "Partition:Count"
		spn_PartitionStart.range = [1,spn_partitionCount.value,spn_PartitionStart.value]
		spn_PartitionEnd.range = [1,spn_partitionCount.value,spn_PartitionEnd.value]
		
		ckb_incrementPositionRandomSeeds.checked = FranticParticles.GetBoolProperty "Partition:IncrementPositionRandomSeeds"
		ckb_incrementSpawnRandomSeeds.checked = FranticParticles.GetBoolProperty "Partition:IncrementSpawnRandomSeeds"
		ckb_incrementSpeedRandomSeeds.checked = FranticParticles.GetBoolProperty "Partition:IncrementSpeedRandomSeeds"
		ckb_incrementRotationRandomSeeds.checked = FranticParticles.GetBoolProperty "Partition:IncrementRotationRandomSeeds"
		
		ckb_incrementFumeFXRandomSeeds.checked = FranticParticles.GetBoolProperty "Partition:IncrementFumeFXRandomSeeds"
		ckb_incrementOtherRandomSeeds.checked = FranticParticles.GetBoolProperty "Partition:IncrementOtherRandomSeeds"
		ckb_incrementLegacyRandomSeeds.checked = FranticParticles.GetBoolProperty "Partition:IncrementLegacyRandomSeeds"
		ckb_incrementThinkingRandomSeeds.checked = FranticParticles.GetBoolProperty "Partition:IncrementThinkingRandomSeeds"
		
		ckb_incrementBox3Geometry.checked = FranticParticles.GetBoolProperty "Partition:IncrementBox3Geometry" 
		ckb_incrementBox3Random.checked = FranticParticles.GetBoolProperty "Partition:IncrementBox3Random" 
		ckb_incrementBox3ScalarVector.checked = FranticParticles.GetBoolProperty "Partition:IncrementBox3ScalarVector" 
		ckb_incrementBox3Icon.checked = FranticParticles.GetBoolProperty "Partition:IncrementBox3Icon" 
		
		ckb_incrementPRTModifiers.checked = FranticParticles.GetBoolProperty "Partition:IncrementPRTModifiers"  
		ckb_incrementPRTVolumeModifiers.checked = FranticParticles.GetBoolProperty "Partition:IncrementPRTVolumeModifiers"  
		ckb_incrementPRTFumeFXModifiers.checked = FranticParticles.GetBoolProperty "Partition:IncrementPRTFumeFXModifiers" 
		ckb_incrementGeometryModifiers.checked = FranticParticles.GetBoolProperty "Partition:IncrementGeometryModifiers"  
		
		ckb_incrementBox3DiskCaches.state =  FranticParticles.GetBoolProperty "Partition:IncrementBox3DiskCacheNames"
		
		ckb_incrementSelectedOnly.checked = FranticParticles.GetBoolProperty "Partition:IncrementSelectedOnly"
		ckb_skipExistingFiles.checked = FranticParticles.GetBoolProperty "SkipExistingParticleFiles" 

		btn_openDeadlineMonitor.enabled =  FranticParticleRenderMXS.DeadlineDetected > 0 and enableSaveParticleFileControls
		btn_submitPartitionJobs.enabled =  FranticParticleRenderMXS.DeadlineDetected > 0 and enableSaveParticleFileControls
		btn_submitCustomPartition.enabled =  FranticParticleRenderMXS.DeadlineDetected > 0 and enableSaveParticleFileControls
		
		ckb_skipExistingFiles.enabled = btn_saveCurrentPartitionLocally.enabled = ckb_incrementSelectedOnly.enabled = btn_savePartitionsLocally.enabled = enableSaveParticleFileControls 
		ckb_incrementBox3DiskCaches.enabled = ckb_incrementLegacyRandomSeeds.enabled = ckb_incrementThinkingRandomSeeds.enabled = ckb_incrementRotationRandomSeeds.enabled = ckb_incrementFumeFXRandomSeeds.enabled = ckb_incrementOtherRandomSeeds.enabled = ckb_incrementPositionRandomSeeds.enabled = ckb_incrementSpawnRandomSeeds.enabled = ckb_incrementSpeedRandomSeeds.enabled = enableSaveParticleFileControls 
		ckb_incrementBox3Geometry.enabled = ckb_incrementBox3Random.enabled = ckb_incrementBox3ScalarVector.enabled = ckb_incrementBox3Icon.enabled = enableSaveParticleFileControls 
		spn_partitionCount.enabled = spn_PartitionStart.enabled = spn_PartitionEnd.enabled = enableSaveParticleFileControls 
		spn_MaxTasksPerWorker.enabled = chk_LimitTasksToNumberOfCpus.enabled = enableSaveParticleFileControls 
		ckb_incrementPRTFumeFXModifiers.enabled = ckb_incrementPRTModifiers.enabled = ckb_incrementPRTVolumeModifiers.enabled = ckb_incrementGeometryModifiers.enabled = enableSaveParticleFileControls 
		ddl_localPartitionMode.enabled = enableSaveParticleFileControls
		
		local KrakatoaPreferencesINI = (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini" )
		local theVal = execute (getIniSetting KrakatoaPreferencesINI  "Partitioning"  "LocalPartitionMode")
		if theVal == OK do theVal = 1
		ddl_localPartitionMode.selection = theVal
		

		--DEADLINE DETECTION--
		local theDeadlineVal = getIniSetting KrakatoaPreferencesINI "Deadline" "DetectDeadline"
		ddl_useDeadlineVersion.selection = case theDeadlineVal of
		(
			default: 1
			"2": 2
			"3": 2
		)

		
		if FranticParticleRenderMXS.DeadlineDetected == 3 then
		(
			--Overwrite some settings using the Krakatoa settings INI file:
			
			SMTDSettings.Priority = getInI "JobSettings" "Priority" SMTDSettings.Priority
			SMTDSettings.PoolName = getInI "JobSettings" "PoolName" SMTDSettings.PoolName executeIt:false
			SMTDSettings.Category = getInI "JobSettings" "Category" SMTDSettings.Category executeIt:false
			
			if SMTDSettings.Pools.count == 0 do SMTDFunctions.CollectPools()
			displayPoolsList()
			
			job_priority_update SMTDSettings.Priority
			
			local defaultMode = getIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaDeadlineSettings.ini") "Default" "DeadlineJobNameSource"
			if defaultMode == "SavePath" then 
				jobNameFromSavePath()
			else	
				jobNameFromMaxName()
		
			local defaultMode = getIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaDeadlineSettings.ini") "Default" "DeadlineCommentSource"
			if defaultMode == "SavePath" then CommentFromSavePath() else defaultComment()
			
			edt_user.text = SMTDFunctions.GetDeadlineUser()
			SMTDSettings.UserName = edt_user.text
			
			edt_dept.text = SMTDSettings.Department
			
			spn_chunkSize.value = getInI "JobSettings" "ChunkSize" SMTDSettings.ChunkSize 
			
			if SMTDSettings.MachineLimit == 0 do SMTDSettings.MachineLimit = 1
			spn_machineLimit.value = getInI "JobSettings" "MachineLimit" SMTDSettings.MachineLimit
			
			ddl_deadlinePartitionMode.selection = getIni "JobSettings" "DeadlinePartitionMode" 1
			
			try(
				spn_MaxTasksPerWorker.value = getIni "JobSettings"  "MaxTasksPerWorker" SMTDSettings.MaxTasksPerWorker 
				chk_LimitTasksToNumberOfCpus.checked = getIni "JobSettings"  "LimitTasksToNumberOfCpus" SMTDSettings.LimitTasksToNumberOfCpus 
			)catch()
			
			ddl_deadlinePartitionMode.visible = spn_MaxTasksPerWorker.visible = chk_LimitTasksToNumberOfCpus.visible = true
			edt_jobname.visible = btn_getJobNameMenu.visible = btn_getCommentMenu.visible = edt_comment.visible = edt_user.visible = edt_dept.visible = ddl_category.visible = true
			lbl_pools.visible = ddl_poollist.visible = sld_priority.visible = spn_priority.visible = true
			spn_machineLimit.visible = spn_chunkSize.visible = lbl_category.visible = true
			lbl_priority.visible = true
			
			lbl_getDeadline01.visible = lbl_getDeadline02.visible = lbl_getDeadline03.visible = lbl_getDeadline04.visible = url_getDeadline01.visible = false 
			
			btn_getJobNameMenu.enabled = btn_getCommentMenu.enabled = edt_jobname.enabled = edt_comment.enabled= edt_user.enabled= edt_dept.enabled= ddl_category.enabled= enableSaveParticleFileControls 
			lbl_pools.enabled= ddl_poollist.enabled= sld_priority.enabled= spn_priority.enabled= enableSaveParticleFileControls 
			spn_machineLimit.enabled = lbl_category.enabled= enableSaveParticleFileControls 
			lbl_priority.enabled= enableSaveParticleFileControls 
			lbl_getDeadline01.enabled= lbl_getDeadline02.enabled= lbl_getDeadline03.enabled= lbl_getDeadline04.enabled= url_getDeadline01.enabled= enableSaveParticleFileControls 
			ddl_deadlinePartitionMode.enabled = enableSaveParticleFileControls 
			deadline27installed =try(isProperty SMTDSettings "LimitTasksToNumberOfCpus")catch(false)
			spn_MaxTasksPerWorker.enabled = chk_LimitTasksToNumberOfCpus.enabled = (((getIni "JobSettings" "DeadlinePartitionMode" 1) == 1) AND deadline27installed AND enableSaveParticleFileControls ) 
			spn_chunkSize.enabled= (getIni "JobSettings" "DeadlinePartitionMode" 1) != 1
			
		)	
		else
		(
			ddl_deadlinePartitionMode.enabled = spn_MaxTasksPerWorker.visible = chk_LimitTasksToNumberOfCpus.visible = false
			edt_jobname.visible = btn_getJobNameMenu.visible = btn_getCommentMenu.visible = edt_comment.visible = edt_user.visible = edt_dept.visible = ddl_category.visible = false
			lbl_pools.visible = ddl_poollist.visible = sld_priority.visible = spn_priority.visible = false
			spn_machineLimit.visible = spn_chunkSize.visible = lbl_category.visible = false
			lbl_priority.visible = false
			lbl_getDeadline01.visible = lbl_getDeadline02.visible = lbl_getDeadline03.visible = lbl_getDeadline04.visible = url_getDeadline01.visible = true 
		)
		
		if Krakatoa_Initializing_Hidden_Rollouts == false do Krakatoa_GUI_Partition.open = oldState
	)
	
	on ckb_incrementSelectedOnly changed state do FranticParticles.SetProperty "Partition:IncrementSelectedOnly" (state as string)
	on ckb_incrementBox3DiskCaches changed state do FranticParticles.SetProperty "Partition:IncrementBox3DiskCacheNames" (state as string)
	
	on ddl_deadlinePartitionMode selected itm do 
	(
		setIniSetting KrakatoaIniPath  "JobSettings"  "DeadlinePartitionMode" (itm as string) 
		Refresh_GUI()
	)	
	
	on ddl_localPartitionMode selected itm do 
	(
		local KrakatoaPreferencesINI = (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini" )
		setIniSetting KrakatoaPreferencesINI  "Partitioning"  "LocalPartitionMode" (itm as string) 
	)	


	on btn_detectDeadlineNow pressed do 
	(
		--Krakatoa_GUI_Partition.open = false
		FranticParticleRenderMXS.detectDeadline timeout:5000 forceloading:true
		Krakatoa_GUI_Partition.refresh_GUI()	
		--Krakatoa_GUI_Partition.open = true
	)

	on ddl_useDeadlineVersion selected itm do
	(
		local KrakatoaPreferencesINI = (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini" )
		setIniSetting KrakatoaPreferencesINI "Deadline" "DetectDeadline"	(itm as string)
		--Krakatoa_GUI_Partition.open = false
		FranticParticleRenderMXS.detectDeadline timeout:5000 forceloading:false
		if itm == 2 and FranticParticleRenderMXS.DeadlineDetected != 3 then 
			messagebox "WARNING:\nDeadline was NOT DETECTED on your system." title:"Krakatoa and Deadline Integration"
		Krakatoa_GUI_Partition.refresh_GUI()	
		--Krakatoa_GUI_Partition.open = true
	)	

	on spn_partitionCount changed val do 
	(
		FranticParticles.SetProperty "Partition:Count" val
		spn_PartitionStart.range = [1,val,spn_PartitionStart.value]
		spn_PartitionEnd.range = [1,val,spn_PartitionEnd.value]
	)	
	
	on spn_PartitionStart changed val do 
	(
		if spn_PartitionEnd.value < val do spn_PartitionEnd.value = val
	)
	
	on spn_PartitionEnd changed val do 
	(
		if spn_PartitionStart.value > val do spn_PartitionStart.value = val
	)
	
	local st1 = 0
	local	framesSoFar = 0
	local	lastFrameTime = 0
	local timeSoFar = 0
	local eta = 0
	local partitionCount = 0
	local startPartition = 0
	local endPartition = 0
	local numberOfPartitionsToProcess = 0
	local partitionNumber = 0
	local deleteExistingFiles = #prompt
	local ETAstartTime = 0
	local totalNumberOfFrames  = 0
	local cnt = 0
	local theTotalCount = 0
	local wasCanceled = false
	local totalNumberOfFrames = 0
	local partitionFilename = ""
	local goOn = true
	local theFilesToBackup = #()
	
	fn preRenderFrameFunction =
	(
		st1 = timestamp()
		cnt += 1
		framesSoFar += 1
		prg_partprogress.value = ( 100.0 * cnt/theTotalCount)
		timeSoFar = (timestamp() - ETAstartTime) * 0.001
		eta =  timeSoFar / framesSoFar  *  (totalNumberOfFrames - framesSoFar)
		lbl_progress01.text = "Partition:" +  partitionNumber as string+ " ("+ (partitionNumber - startPartition + 1) as string + "/"+(endPartition - startPartition + 1) as string  + ") - Range:"+startPartition  as string +" to "+ endPartition as string + " - Frame:" + (currentTime.frame as integer) as string + " ("+ cnt as string+ "/" + theTotalCount as string +") - Total Frames:" + framesSoFar as string + " of " + totalNumberOfFrames as string + ", " + (totalNumberOfFrames - framesSoFar) as string +" left."
		lbl_progress02.text = "Last Frame:" + (FranticParticleRenderMXS.convertToHMS lastFrameTime)+ " - Elapsed:"+ (FranticParticleRenderMXS.convertToHMS timeSoFar) as string +" - Remaining:" + (FranticParticleRenderMXS.convertToHMS eta) as string +" - Press Esc To Cancel."
		checkFilename = FranticParticles.ReplaceSequenceNumber partitionFilename (currentTime.frame as integer)
		if deleteExistingFiles == #delete  do 
		(
			local res = deleteFile checkFilename 
			if res then FranticParticles.LogDebug (">Overwriting Existing File ["+checkFilename+"]")
		)
		if deleteExistingFiles == #prompt and doesFileExist checkFilename and not (FranticParticles.GetBoolProperty "SkipExistingParticleFiles") do 
		(
			local theYNC = yesNoCancelBox ("The Particle File \n[" + checkFilename + "]\n already exists.\n\nPress [Yes] if you want to overwrite this file AND ANY OTHER FILES that might exist in the partition.\nPress [No] to get prompted for EACH existing file.\nPress [Cancel] to cancel the partitioning!") title:"Krakatoa Partitioning: Overwrite Existing Files?"
			if theYNC == #cancel do 
			(
				goOn = false
				wasCanceled = true
				FranticParticles.LogProgress  ("-Local Partition Creation Canceled by User")
			)	
			if theYNC == #yes do 
			(
				deleteFile  checkFilename 
				deleteExistingFiles = #delete
			)
			if theYNC == #no do deleteExistingFiles = #defaultprompt
		)	
		if goOn do append theFilesToBackup checkFilename
	)
	
	fn postRenderFrameFunction val=
	(
		lastFrameTime = (timestamp() - st1)/1000.0
		FranticParticles.LogProgress ("  >Partition " + partitionNumber as string + " ("+ (partitionNumber - startPartition + 1) as string + "/"+(endPartition - startPartition + 1) as string  + ") - Range:"+startPartition  as string +" to "+ endPartition as string + " - Frame:" + (currentTime.frame as integer) as string + " ("+ cnt as string+ "/" + theTotalCount as string +") - Total Frames:" + framesSoFar as string + " of " + totalNumberOfFrames as string + ", " + (totalNumberOfFrames - framesSoFar) as string +" left.")
		FranticParticles.LogProgress ("  >Frame Save Time: "+ FranticParticleRenderMXS.convertToHMS lastFrameTime) 
	)
	
	fn hasPFlowToSave =
	(
		thePFsources = for o in objects where classof o == PF_Source and not o.isHiddenInVpt and o.Enable_Particles collect o
		PFenabled = try(FranticParticles.GetBoolProperty "RenderParticleFlowGeometry" or FranticParticles.GetBoolProperty "RenderParticleFlowPhantom" or FranticParticles.GetBoolProperty "RenderParticleFlowBBox" )catch(false)
		thePFsources.count > 0 and PFenabled
	)
	
	fn savePartitionsLocally mode:#all=
	(
		FranticParticles.LogProgress ">Starting Local Partitions Saving..."
		local oldescapeEnabled = escapeEnabled 
		local oldSaveHistory = FranticParticles.GetBoolProperty  "Presets:SaveRenderHistory"
		local savedParticleFiles = FranticParticles.GetProperty "ParticleFiles"	
		FranticParticles.SetProperty  "Presets:SaveRenderHistory" false
		renderSceneDialog.close()
		local currentSequence = #()
		local oldRendTimeType = rendTimeType
		local oldRendStart = rendStart 
		local oldRendEnd  = rendEnd 

		case rendTimeType of
		(
			1: (
					currentSequence = #(sliderTime.frame as integer) 
				)
			2: (
					currentSequence = for t in animationRange.start to animationRange.end by rendNthFrame collect (t.frame as integer)
				)
			3: (
					currentSequence = for t in rendStart to rendEnd by rendNthFrame collect (t.frame as integer)
				)
			4: (
					theFS = filterString rendPickupFrames "-"
					local txt = "#{"
					for i = 1 to theFS.count-1 do txt += theFS[i]+ ".."
					txt += theFS[theFS.count] + "}"
					currentSequence = (execute txt) as array
				)	
		)
		
		if currentSequence.count == 1 and hasPFlowToSave() do 
		(
			local txt = ("You have set Krakatoa to Partition FRAME "+ currentSequence[1] as string +" ONLY!\n") 
			txt += "Note that Particle Flow would not update seeds correctly if saving a single frame,\n"
			txt += "so if you click [Yes], two frames - "+ currentSequence[1] as string + " and "+ (currentSequence[1]+1) as string +" will be saved instead.\n"
			txt += "\nClick [Yes] to use frames " +currentSequence[1] as string + " and "+ (currentSequence[1]+1) as string +" only\n"
			txt += "Click [No] to use the current scene range from "+ (animationRange.start.frame as integer) as string + " to "+ (animationRange.end.frame as integer) as string +" instead.\n"
			txt += "Click [Cancel] to abort Partitioning and change your settings."
			local q = yesNoCancelBox txt title:"KRAKATOA: Single Frame Partitioning"
			if q == #yes do 
			(
				append currentSequence (currentSequence[1]+1)
				rendTimeType = 3
				rendStart = currentSequence[1] 
				rendEnd = currentSequence[1]+1 
			)
			if q == #no do 
			(
				currentSequence = for t in animationRange.start to animationRange.end by rendNthFrame collect (t.frame as integer)
				rendTimeType = 2
			)
			if q == #cancel do return ""
		)	
		
		escapeEnabled = false
		local wasCanceled  = false
		partitionCount = (FranticParticles.GetIntProperty "Partition:Count")
		
		if mode==#all then
		(
			startPartition = 1
			endPartition = partitionCount 
			numberOfPartitionsToProcess = partitionCount
		)
		else	
		(
			startPartition = spn_PartitionStart.value
			endPartition = spn_PartitionEnd.value
			numberOfPartitionsToProcess = endPartition - startPartition + 1
		)
		
		local theBaseFullFileName = (FranticParticles.GetProperty "ParticleFiles")
		local theBasePath = getFileNamePath theBaseFullFileName
		local theBaseFilename = getFileNameFile theBaseFullFileName
		local theBaseFileExt = getFileNameType theBaseFullFileName
		if theBaseFileExt == "" do theBaseFileExt = ".prt"
		
		totalNumberOfFrames = currentSequence.count * numberOfPartitionsToProcess 
		framesSoFar = 0
		lastFrameTime = 0
		deleteExistingFiles = #prompt
		ETAstartTime = timestamp()
	
		local theZeroCount = 4
		if matchPattern theBaseFileExt pattern:".bin" do theZeroCount = 5
		
		if theBaseFileName.count > 0 then 
		(
			--if the viewport is a camera view, remember its old mpass state and disable mpass effects
			local theViewportCamera = viewport.getCamera()
			local oldMultiPassState = false
			if isValidNode theViewportCamera do 
			(
				try
				(
					oldMultiPassState = theViewportCamera.mpassEnabled 
					theViewportCamera.mpassEnabled = false
					if oldMultiPassState do FranticParticles.LogDebug "+Temporarily Disabled Viewport Camera MPass Effects To Avoid Multiple File Saving."
				)catch(FranticParticles.LogDebug "--Failed to Disable Viewport Camera MPass Effects To Avoid Multiple File Saving.")	
			)		

			callbacks.removeScripts id:#Krakatoa_TP_Partitioning
			callbacks.addScript #preRenderFrame "Krakatoa_GUI_Partition.preRenderFrameFunction()"  id:#Krakatoa_TP_Partitioning
			callbacks.addScript #postRenderFrame "Krakatoa_GUI_Partition.postRenderFrameFunction (callbacks.notificationParam())"  id:#Krakatoa_TP_Partitioning

			goOn = true
			local partitionProgressCounter = 0
			for pnum = startPartition  to endPartition do 
			(
				partitionNumber = pnum
				partitionProgressCounter += 1
				st = timestamp()
				theFilesToBackup = #()
				prg_progress.value = 100.0 * partitionProgressCounter / numberOfPartitionsToProcess 
				if matchpattern theBaseFilename pattern:"*part*of*" then
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
				IncrementAllPartitionValues (partitionNumber-1) selectedOnly:ckb_incrementSelectedOnly.state
				partitionFilename = FranticParticles.MakePartitionFilename (theBasePath + theBaseFilename+theBaseFileExt) partitionNumber partitionCount
				FranticParticles.SetProperty "ParticleFiles" partitionFilename
				
				if ddl_localPartitionMode.selection == 2 then
				(
					FranticParticles.LogProgress (localtime + " : Starting Scene Saving For Local Command Line Partition "+ partitionNumber as string + "...")
					local theMaxFilePath = getFileNamePath partitionFilename + getFileNameFile partitionFilename + ".max"
					local theBatchFilePath = getFileNamePath partitionFilename + getFileNameFile partitionFilename + ".bat"
					saveMaxFile theMaxFilePath clearNeedSaveFlag:false useNewFile:false quiet:true
					local theCmdString = "\""+ getDir #maxroot + "\3dsmaxcmd\" -outputName:\"\" \""+theMaxFilePath+"\""
					local theBatchFile = createFile theBatchFilePath
					format "%\n" theCmdString to:theBatchFile
					format "@pause\n " to:theBatchFile
					close theBatchFile
					--shellLaunch theBatchFilePath ""
					FranticParticles.LogProgress (localtime + " : Finished Scene Saving For Local Command Line Partition "+ partitionNumber as string + ".")
				)
				else
				(
					theTotalCount = currentSequence.count 
					FranticParticles.LogProgress (localtime + " : Starting Partition "+ partitionNumber as string + " with " + theTotalCount  as string + " Frames...")
					cnt = 0
					wasCanceled = false
					
					if FranticParticles.GetBoolProperty "SkipExistingParticleFiles" then
					(
						deleteExistingFiles = #never
					)
					else
					(
						for t in currentSequence do
						(
							checkFilename = FranticParticles.ReplaceSequenceNumber partitionFilename t
							if deleteExistingFiles == #delete  do deleteFile checkFilename 
							if deleteExistingFiles == #prompt and doesFileExist checkFilename do 
							(
								local theYNC = yesNoCancelBox ("The Particle File \n[" + checkFilename + "]\n already exists.\n\nPress [Yes] if you want to overwrite this file AND ANY OTHER FILES that might exist in the partition.\nPress [No] to get prompted for EACH existing file.\nPress [Cancel] to cancel the partitioning!") title:"Krakatoa Partitioning: Overwrite Existing Files?"
								if theYNC == #cancel do 
								(
									goOn = false
									wasCanceled = true
									FranticParticles.LogProgress  ("-Local Partition Creation Canceled by User")
									exit
								)	
								if theYNC == #yes do 
								(
									deleteFile checkFilename 
									deleteExistingFiles = #delete
									exit
								)
								if theYNC == #no do deleteExistingFiles = #defaultprompt
							)						
						)
					)
					if goOn then
					(
						max quick render
						if theTotalCount-cnt > 0 do --if the total number of frames in the partition was not reached, most probably it was canceled!
						(
							wasCanceled = true
							goOn = false
							FranticParticles.LogProgress ">Partitioning Was Canceled..."
						)
					)
				)
	
-----------------------------------------------------------------------------------------------------------------------------------------------------------------				
				FranticParticles.LogProgress ">Decrementing Seeds..."
				IncrementAllPartitionValues -(partitionNumber-1) selectedOnly:ckb_incrementSelectedOnly.state
				FranticParticles.SetProperty "ParticleFiles" savedParticleFiles 
				if not wasCanceled do 
					FranticParticles.LogProgress (localtime + " : Finished Partition "+ partitionNumber as string +" in "+ FranticParticleRenderMXS.convertToHMS ((timestamp() - st)/1000.0)) --output the task duration
				
				local theVal = execute (FranticParticles.GetProperty "Partition:BackupRootMode")
				if theVal == OK do theVal = 1
				if theVal > 1 do
				(
					local q = if wasCanceled then
						querybox ("Local Partitioning was cancelled, but a backup operation has been requested.\n\nClick [YES] to perform the Backup.\nClick [NO] to skip Backup and exit.") title:"Krakatoa: Cancel Backup Too?"
					else
						true	
					
					if q then 
					(
						FranticParticles.LogProgress (#("","COPY","MOVING")[theVal] +" of local partition files to backup directory requested!")
						local theBackupPath = Krakatoa_GUI_SaveParticles.getFilenameFromBackupRoot()
						makeDir theBackupPath all:true
						if doesFileExist theBackupPath then
						(
							FranticParticles.LogProgress ("+Backup Path [" + theBackupPath + "] is VALID.")
							local cnt = 0
							prg_partprogress.color = green
							for f in theFilesToBackup do
							(
								cnt += 1
								prg_partprogress.value = ( 100.0 * cnt/theFilesToBackup.count)
								local targetFile = (theBackupPath + fileNameFromPath f)
								lbl_progress01.text = #("","COPYING","MOVING")[theVal] + " " + filenameFromPath f
								lbl_progress02.text = "to " + theBackupPath 
								if doesFileExist targetFile do deleteFile targetFile 
								local result = copyFile f targetFile 
								if result == true then
								(
									if theVal == 3 do deleteFile f
									FranticParticles.LogProgress ("+" + #("","COPIED","MOVED")[theVal] +" ["+ f + "] to ["+ targetFile +"].")
								)	
								else
									FranticParticles.LogProgress ("--FAILED to " + #("","copy","move")[theVal] +" ["+ f + "] to ["+ targetFile +"].")
							)--end f loop
							prg_partprogress.color = red
						)
						else
							FranticParticles.LogProgress ("--Backup Path [" + theBackupPath + "] is not accessible.")
					)
					else		
						FranticParticles.LogProgress ("--User requested no backup.")
				)--end backup
				if wasCanceled do exit
			)--end partition loop
			prg_progress.value = 0
			prg_partprogress.value = 0
			if isValidNode theViewportCamera do --if the viewport is a camera and it haf mpass enabled, restore it
			(
				try
				(
					theViewportCamera.mpassEnabled = oldMultiPassState 
					if oldMultiPassState do FranticParticles.LogDebug "+Re-enabled Viewport Camera MPass Effects."
				)
				catch()
			)				
		)
		else
			messagebox "No Save Name Specified, Cannot Create Partitions!" title:"Krakatoa Partitions"

		rendTimeType = oldRendTimeType 
		rendStart = oldRendStart 
		rendEnd = oldRendEnd  
		
		FranticParticles.SetProperty  "Presets:SaveRenderHistory" oldSaveHistory 
		lbl_progress01.text = lbl_progress02.text = ""
		callbacks.removeScripts id:#Krakatoa_TP_Partitioning
	)	

	on btn_savePartitionsLocally pressed do 
	(
		checkForMissingUVChannels()
		savePartitionsLocally mode:#all
	)	
	on btn_saveCurrentPartitionLocally pressed do 
	(
		checkForMissingUVChannels()
		savePartitionsLocally mode:#one
	)	
	on ckb_skipExistingFiles changed state do 
	(
		FranticParticles.SetProperty "SkipExistingParticleFiles" (state as string)
		try(Krakatoa_GUI_SaveParticles.Refresh_Gui())catch()
	)
	
	on ckb_skipExistingFiles rightclick do 
		FranticParticleRenderMXS.createDefaultsRCMenu "SkipExistingParticleFiles" "Skip Existing Files When Saving"
	
	
	on ckb_incrementPositionRandomSeeds changed state do FranticParticles.SetProperty "Partition:IncrementPositionRandomSeeds" state
	on ckb_incrementSpawnRandomSeeds changed state do FranticParticles.SetProperty "Partition:IncrementSpawnRandomSeeds" state
	on ckb_incrementSpeedRandomSeeds changed state do FranticParticles.SetProperty "Partition:IncrementSpeedRandomSeeds" state
	on ckb_incrementRotationRandomSeeds changed state do FranticParticles.SetProperty "Partition:IncrementRotationRandomSeeds" state
		
	on ckb_incrementFumeFXRandomSeeds changed state do FranticParticles.SetProperty "Partition:IncrementFumeFXRandomSeeds" state
	on ckb_incrementOtherRandomSeeds changed state do FranticParticles.SetProperty "Partition:IncrementOtherRandomSeeds" state
	on ckb_incrementLegacyRandomSeeds changed state do FranticParticles.SetProperty "Partition:IncrementLegacyRandomSeeds" state
	on ckb_incrementThinkingRandomSeeds changed state do FranticParticles.SetProperty "Partition:IncrementThinkingRandomSeeds" state
	
	on ckb_incrementBox3Geometry changed state do FranticParticles.SetProperty "Partition:IncrementBox3Geometry" state
	on ckb_incrementBox3Random changed state do FranticParticles.SetProperty "Partition:IncrementBox3Random" state
	on ckb_incrementBox3ScalarVector changed state do FranticParticles.SetProperty "Partition:IncrementBox3ScalarVector" state
	on ckb_incrementBox3Icon changed state do FranticParticles.SetProperty "Partition:IncrementBox3Icon" state		
		
	on ckb_incrementPRTModifiers changed state do FranticParticles.SetProperty "Partition:IncrementPRTModifiers" state
	on ckb_incrementPRTVolumeModifiers changed state do FranticParticles.SetProperty "Partition:IncrementPRTVolumeModifiers" state
	on ckb_incrementPRTFumeFXModifiers changed state do FranticParticles.SetProperty "Partition:IncrementPRTFumeFXModifiers" state
	on ckb_incrementGeometryModifiers changed state do FranticParticles.SetProperty "Partition:IncrementGeometryModifiers"  state
		
	on ckb_incrementPositionRandomSeeds rightclick do
		FranticParticleRenderMXS.createDefaultsRCMenu "Partition:IncrementPositionRandomSeeds" "Increment PFlow Position Random Seeds"

	on ckb_incrementSpawnRandomSeeds rightclick do
		FranticParticleRenderMXS.createDefaultsRCMenu "Partition:IncrementSpawnRandomSeeds" "Increment PFlow Spawn Random Seeds"

	on ckb_incrementSpeedRandomSeeds rightclick do
		FranticParticleRenderMXS.createDefaultsRCMenu "Partition:IncrementSpeedRandomSeeds" "Increment PFlow Speed Random Seeds"

	on ckb_incrementRotationRandomSeeds rightclick do
		FranticParticleRenderMXS.createDefaultsRCMenu "Partition:IncrementRotationRandomSeeds" "Increment PFlow Rotation Random Seeds"
	
	
	on ckb_incrementFumeFXRandomSeeds rightclick do
		FranticParticleRenderMXS.createDefaultsRCMenu "Partition:IncrementFumeFXRandomSeeds" "Increment FumeFX Random Seeds"

	on ckb_incrementOtherRandomSeeds rightclick do
		FranticParticleRenderMXS.createDefaultsRCMenu "Partition:IncrementOtherRandomSeeds" "Increment OtherRandom Seeds"

	on ckb_incrementLegacyRandomSeeds rightclick do
		FranticParticleRenderMXS.createDefaultsRCMenu "Partition:IncrementLegacyRandomSeeds" "Increment Legacy Random Seeds"

	on ckb_incrementThinkingRandomSeeds rightclick do
		FranticParticleRenderMXS.createDefaultsRCMenu "Partition:IncrementThinkingRandomSeeds" "Increment Thinking Particles Random Seeds"
	
	
	on ckb_incrementBox3Geometry rightclick do
		FranticParticleRenderMXS.createDefaultsRCMenu "Partition:IncrementBox3Geometry" "Increment Geometry Ops Random Seeds"

	on ckb_incrementBox3Random rightclick do
		FranticParticleRenderMXS.createDefaultsRCMenu "Partition:IncrementBox3Random" "Increment Box#3 Random Ops Random Seeds"

	on ckb_incrementBox3ScalarVector rightclick do
		FranticParticleRenderMXS.createDefaultsRCMenu "Partition:IncrementBox3ScalarVector" "Increment Box#3 Scalar/Vector Ops Random Seeds"

	on ckb_incrementBox3Icon rightclick do
		FranticParticleRenderMXS.createDefaultsRCMenu "Partition:IncrementBox3Icon" "Increment Box#3 Icon Random Seeds"
	
	
	on ckb_incrementPRTModifiers rightclick do
		FranticParticleRenderMXS.createDefaultsRCMenu "Partition:IncrementPRTModifiers" "Increment PRT Loader Modifiers Random Seeds"

	on ckb_incrementPRTVolumeModifiers rightclick do
		FranticParticleRenderMXS.createDefaultsRCMenu "Partition:IncrementPRTVolumeModifiers" "Increment PRT Volume Modifiers Random Seeds"

	on ckb_incrementPRTFumeFXModifiers rightclick do
		FranticParticleRenderMXS.createDefaultsRCMenu "Partition:IncrementPRTFumeFXModifiers" "Increment PRT FumeFX Modifiers Random Seeds"
	
	

	on ckb_incrementGeometryModifiers rightclick do
		FranticParticleRenderMXS.createDefaultsRCMenu "Partition:IncrementGeometryModifiers" "Increment Geometry Modifiers Random Seeds"	
	
	on btn_submitPartitionJobs pressed do 
	(
		local oldRenderSceneDialog = renderSceneDialog.isOpen()
		renderSceneDialog.close()
		local oldRendTimeType = rendTimeType 
		local oldRendStart = rendStart
		local oldRendEnd = rendEnd
		if oldRendTimeType == 1 do
		(
			rendTimeType = 3
			rendStart = currentTime.frame
			rendEnd = currentTime.frame+1
		)		
		checkForMissingUVChannels()
		--SetAllFilePartitionCounts (FranticParticles.GetIntProperty "Partition:Count")
		if ddl_deadlinePartitionMode.selection == 1 then
		(
			(SubmitOnePartitionJobToDeadline 2 spn_PartitionCount.value quiet:false partitionMode:#tasks PartitionRange:false)
		)
		else
			SubmitPartitionJobsToDeadline mode:#all
		
		if oldRendTimeType == 1 do
		(
			rendTimeType = 1
			rendStart = oldRendStart
			rendEnd = oldRendEnd
		)		
		if oldRenderSceneDialog do renderSceneDialog.Open()		
	)
	
	on btn_submitCustomPartition pressed do 
	(
		local oldRenderSceneDialog = renderSceneDialog.isOpen()
		renderSceneDialog.close()
		local oldRendTimeType = rendTimeType 
		local oldRendStart = rendStart
		local oldRendEnd = rendEnd
		if oldRendTimeType == 1 do
		(
			rendTimeType = 3
			rendStart = currentTime.frame
			rendEnd = currentTime.frame+1
		)
		checkForMissingUVChannels()
		if ddl_deadlinePartitionMode.selection == 1 then
		(
			(SubmitOnePartitionJobToDeadline spn_PartitionStart.value spn_PartitionEnd.value quiet:false partitionMode:#tasks PartitionRange:true)
		)
		else
			SubmitPartitionJobsToDeadline mode:#range
		
		if oldRendTimeType == 1 do
		(
			rendTimeType = 1
			rendStart = oldRendStart
			rendEnd = oldRendEnd
		)		
		if oldRenderSceneDialog do renderSceneDialog.Open()
	)
	
	on Krakatoa_GUI_Partition rolledUp val do 
	(
			FranticParticles.SetProperty "GUI:ParticlePartitioningRolloutOpen" val
			if val then 
			(
				FranticParticleRenderMXS.DetectDeadline forceloading:false
				FranticParticles.LogDebug ("+Particle Partitioning Rollout ROLLED DOWN.")
				updateDeadlineControls()				
				Refresh_GUI()			
			)	
			else
				FranticParticles.LogDebug ("+Particle Partitioning Rollout ROLLED UP.")
	)		

	on Krakatoa_GUI_Partition close do 
	(
		if Krakatoa_GUI_Partition.inDialog and not Krakatoa_Closing_Floater and not Krakatoa_Initializing_Hidden_Rollouts then
		(
			setIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "RolloutVisible" Krakatoa_GUI_Partition.title "false"
			FranticParticleRenderMXS.floatOrDockRollout Krakatoa_GUI_Partition forceMode:#hide
			Krakatoa_CustomizeRollouts_Dialog.Refresh_GUI()
		)	
	)	
	
	fn updateIcons =
	(
		btn_LoadSave_Partition.images= #(Krakatoa_PresetsArrowBitmap,Krakatoa_PresetsArrowBitmap, 32,3,3,3,3)		
		btn_Float_Rollout.images = #(Krakatoa_PresetsArrowBitmap,Krakatoa_PresetsArrowBitmap, 32,4,4,4,4)
		btn_getJobNameMenu.images = #(Krakatoa_PresetsArrowBitmap,Krakatoa_PresetsArrowBitmap, 32,1,1,2,2)
		btn_getCommentMenu.images = #(Krakatoa_PresetsArrowBitmap,Krakatoa_PresetsArrowBitmap, 32,1,1,2,2)
	)	

	on Krakatoa_GUI_Partition open do 
	(
		updateIcons()
		Krakatoa_CustomizeRollouts_Dialog.Refresh_GUI()
		updateDeadlineControls()
		Refresh_GUI()
		FranticParticles.LogDebug ("+Partitioning Rollout OPENED.")			
	)			
)--end rollout

-------------------------------------- 
--PREFERENCES ROLLOUTS	
-------------------------------------- 

rollout Krakatoa_GUI_Preferences_Colors "User Interface Colors" category:300
(
	button btn_Help_Preferences "Open Online Help..." width:450 height:16 offset:[0,-5] align:#center tooltip:"Opens the Krakatoa Online Help for the User Interface Colors rollout in the default Web Browser. Requires Internet connection."

	group "Custom Checkbutton Colors"
	(
		checkbutton ckb_useSkinColors ">Use Custom Checkbutton Colors" width:214 across:2 offset:[0,-4] align:#left highlightcolor:KrakatoaSkinColorsStruct.Preferences
		button btn_updateColors "Update Colors Now (Restart GUI)..." width:214 align:#right offset:[0,-4]
		
		dropdownlist ddl_SkinColor offset:[0,-4] items:#("Presets and History Rolllout", "Global Render Values Rollout", "Main Controls Rollout", "Channels Rollout", "Partitioning Rollout", "Scene Particles Rollout", "Particle Loaders Rollout", "Thinking Particles Rollout", "Matte Objects Rollout", "APME Rollout","Preferences Rollout","VFB (3ds Max 2009+)")  align:#left width:214 across:2
		colorpicker clr_CheckbuttonColor "Checkbutton Color:" offset:[0,-4] color:KrakatoaSkinColorsStruct.History fieldwidth:40 align:#right modal:false
		
		button btn_SaveSkinColors "Save Checkbutton Colors As Preset..." width:214 across:2 align:#left offset:[0,-4]
		button btn_LoadSkinColors "Load Checkbutton Colors From Preset..." width:214 align:#right offset:[0,-4]
	)
	
	group "Icon Color Correction"
	(
		dropdownlist ddl_absRel items:#("Relative Offset","Absolute Value") across:4 offset:[0,-6]
		
		spinner spn_IconColorHue "Hue:" range:[-255,255,0]  type:#integer fieldwidth:40 offset:[-10,-4]
		spinner spn_IconColorSat "Saturation:" range:[-255,255,0]  type:#integer fieldwidth:40 offset:[0,-4]
		spinner spn_IconColorValue "Value:" range:[-255,255,0] type:#integer fieldwidth:40 offset:[0,-4]
		
		edittext edt_presetname "Load/Save Custom Icon Colors Preset:" text:"CustomIconsColors" across:2 align:#right fieldwidth:200 offset:[195,-4] 
		button btn_IconColorPreset ">>" width:20 height:18 align:#right offset:[0,-4]
	)
	
	fn createPresetsRCMenu  =
	(
		presetName = "IconColorPresets"
		presetsList = #(
				#("Light Blue", 1,0, 0, 0),
				#("Intense Blue", 1,0, 166, 0),
				#("Orange With Black Border", 1,136, 136, 25),
				#("Bright Yellow With Gray Border", 1,136, 40, 85),
				#("Bright Green With Dark Green Border", 1,-80, 160, 0),
				#("Dark Gray With Neon Border", 1,-175, -185, 70),
				#("White Border", 2,0, -16, 255),
				#("Cyan Border", 2,0, -120, 255),
				#("Yellow Border", 2,175, -120, 255)
			)
		local builtInPresetsCount = presetsList.count
		local theKeys = for i in (getIniSetting (Krakatoa_PresetsDirectory + "//KrakatoaPreferences.ini") presetName ) collect i
		searchList = for i in presetsList collect i[1]
		for k in theKeys do
		(
			try
			(
				local val = execute (getIniSetting (Krakatoa_PresetsDirectory + "//KrakatoaPreferences.ini") presetName k)
				local valMode = execute (getIniSetting (Krakatoa_PresetsDirectory + "//KrakatoaPreferences.ini") presetName (k+"_Mode"))
				append presetsList #(k, valMode, val.x, val.y, val.z)
				append searchList k
			)catch()	
		)	

		theValue0 = Krakatoa_GUI_Preferences_Colors.ddl_absRel.selection
		theValue1 = Krakatoa_GUI_Preferences_Colors.spn_IconColorHue.value
		theValue2 = Krakatoa_GUI_Preferences_Colors.spn_IconColorSat.value
		theValue3 = Krakatoa_GUI_Preferences_Colors.spn_IconColorValue.value
		
		searchValue =edt_presetname.text
		storeValue = ("[" +theValue1  as string + "," +theValue2   as string + "," + theValue3 as string + "]")
		
		local txt = stringStream ""
		format "rcmenu Presets_RCMenu\n(\n" to:txt
		
		if findItem searchList searchValue == 0 do 
		(
			format  "menuItem mnu_AddPreset \"Add '%'\"\n" searchValue to:txt
			format  "on mnu_AddPreset picked do (\n" to:txt
			format  "setIniSetting (Krakatoa_PresetsDirectory + \"//KrakatoaPreferences.ini\") \"%\" \"%\" \"%\" \n" presetName searchValue storeValue to:txt
			format  "setIniSetting (Krakatoa_PresetsDirectory + \"//KrakatoaPreferences.ini\") \"%\" \"%_Mode\" \"%\" \n" presetName searchValue theValue0 to:txt
			format  ")\n" to:txt
			format  "separator spr_01\n"  to:txt
		)	
		if findItem searchList searchValue > builtInPresetsCount do 
		(
			format  "menuItem mnu_AddPreset \"Update '%'\"\n" searchValue to:txt
			format  "on mnu_AddPreset picked do (\n" to:txt
			format  "setIniSetting (Krakatoa_PresetsDirectory + \"//KrakatoaPreferences.ini\") \"%\" \"%\" \"%\" \n" presetName searchValue storeValue to:txt
			format  "setIniSetting (Krakatoa_PresetsDirectory + \"//KrakatoaPreferences.ini\") \"%\" \"%_Mode\" \"%\" \n" presetName searchValue theValue0 to:txt
			format  ")\n" to:txt
			format  "separator spr_02\n"  to:txt
		)
		
		cnt = 0
		for i in presetsList do
		(
			cnt += 1
			format  "menuItem mnu_preset% \"%]\" \n" cnt (i[1] + (if i[2] == 1 then " R" else " A" ) + " ["+ i[3] as string + ","+ i[4] as string + "," + i[5] as string)  to:txt
			format  "on mnu_preset% picked do (\n" cnt to:txt
			format  "Krakatoa_GUI_Preferences_Colors.edt_presetname.text = \"%\"\n" i[1] to:txt
			format  "Krakatoa_GUI_Preferences_Colors.ddl_absRel_selectedFN (Krakatoa_GUI_Preferences_Colors.ddl_absRel.selection = %)\n" i[2] to:txt
			format  "Krakatoa_GUI_Preferences_Colors.spn_IconColorHue.changed (Krakatoa_GUI_Preferences_Colors.spn_IconColorHue.value = %)\n" i[3] to:txt
			format  "Krakatoa_GUI_Preferences_Colors.spn_IconColorSat.changed (Krakatoa_GUI_Preferences_Colors.spn_IconColorSat.value = %)\n" i[4] to:txt
			format  "Krakatoa_GUI_Preferences_Colors.spn_IconColorValue.changed (Krakatoa_GUI_Preferences_Colors.spn_IconColorValue.value = %)\n" i[5] to:txt
			format  ")\n" to:txt
		)
		if findItem searchList searchValue > builtInPresetsCount do 
		(
			format  "separator spr_09\n"  to:txt
			format  "menuItem mnu_RemovePreset \"Remove '%'\"\n" searchValue  to:txt
			format  "on mnu_RemovePreset picked do (\n" to:txt
			format  "delIniSetting (Krakatoa_PresetsDirectory + \"//KrakatoaPreferences.ini\") \"%\" \"%\" \n" presetName searchValue to:txt
			format  "delIniSetting (Krakatoa_PresetsDirectory + \"//KrakatoaPreferences.ini\") \"%\" \"%_Mode\" \n" presetName searchValue to:txt
			format  ")\n" to:txt
		)	
		format  ")\n" to:txt
		Krakatoa_RCMenu_Struct.Presets_RCMenu = execute (txt as string)
	)	
	
	on btn_IconColorPreset pressed do
	(
		createPresetsRCMenu()
		popupMenu Krakatoa_RCMenu_Struct.Presets_RCMenu  pos:mouse.screenpos
	)
	
	
	on spn_IconColorHue changed val do 
	(
		setIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini" ) "IconColors"  "Hue" (val as string)
		FranticParticleRenderMXS.updateIconColors()
	)
	on spn_IconColorSat changed val do 
	(
		setIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini" ) "IconColors"  "Saturation" (val as string)
		FranticParticleRenderMXS.updateIconColors()
	)
	on spn_IconColorValue changed val do 
	(
		setIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini" ) "IconColors"  "Value" (val as string)
		FranticParticleRenderMXS.updateIconColors()
	)
	
	fn ddl_absRel_selectedFN itm =
	(
		setIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini" ) "IconColors"  "AbsoluteRelative" (itm as string)
		FranticParticleRenderMXS.updateIconColors()		
	)
	
	on ddl_absRel selected itm do
	(
		ddl_absRel_selectedFN itm
	)
	
	
	fn getCurrentSkinColor theKey &theProperty =
	(
		local theValue = execute (getIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini" ) "SkinColors" theKey)
		theProperty = if classof theValue == Color then theValue else (colorman.getColor #itemHilight)*255
	)
	
	fn setCurrentSkinColor theKey &theProperty theColor = 
	(
		setIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini" ) "SkinColors" theKey  ((theProperty = theColor) as string)
	)
	
	fn updateSkinColorDisplay itm =
	(
		clr_CheckbuttonColor.color = case itm of
		(
			1: getCurrentSkinColor "History" &KrakatoaSkinColorsStruct.History
			2: getCurrentSkinColor "GlobalRenderValues" &KrakatoaSkinColorsStruct.GlobalRenderValues
			3: getCurrentSkinColor "Main" &KrakatoaSkinColorsStruct.Main
			4: getCurrentSkinColor "Channels" &KrakatoaSkinColorsStruct.Channels
			5: getCurrentSkinColor "Partitioning" &KrakatoaSkinColorsStruct.Partitioning
			6: getCurrentSkinColor "Systems" &KrakatoaSkinColorsStruct.Systems
			7: getCurrentSkinColor "Loaders" &KrakatoaSkinColorsStruct.Loaders
			8: getCurrentSkinColor "Thinking" &KrakatoaSkinColorsStruct.Thinking
			9: getCurrentSkinColor "Matte" &KrakatoaSkinColorsStruct.Matte
			10: getCurrentSkinColor "APME" &KrakatoaSkinColorsStruct.APME
			11: getCurrentSkinColor "Preferences" &KrakatoaSkinColorsStruct.Preferences
			12: getCurrentSkinColor "VFB" &KrakatoaSkinColorsStruct.VFB				
		)		
		Krakatoa_LoadSkinColors()
	)
	
	fn saveSkinColors =
	(
		makedir (Krakatoa_PresetsDirectory+ "\\ColorPresets") all:true
		local theFile = getSaveFilename caption:"Select Custom Checkbutton Colors Preset Name to Save..." filename:(Krakatoa_PresetsDirectory + "\\ColorPresets\\Preset.kcp") types:"Krakatoa Color Preset (*.kcp)|*.kcp" history:"KrakatoaPresets"
		if theFile != undefined do
		(
			setIniSetting theFile "CheckbuttonColors" "History" ((getCurrentSkinColor "History" &KrakatoaSkinColorsStruct.History) as string)
			setIniSetting theFile "CheckbuttonColors" "Main" ((getCurrentSkinColor "Main" &KrakatoaSkinColorsStruct.Main) as string)
			setIniSetting theFile "CheckbuttonColors" "Channels" ((getCurrentSkinColor "Channels" &KrakatoaSkinColorsStruct.Channels) as string)
			setIniSetting theFile "CheckbuttonColors" "Partitioning" ((getCurrentSkinColor "Partitioning" &KrakatoaSkinColorsStruct.Partitioning) as string)
			setIniSetting theFile "CheckbuttonColors" "Systems" ((getCurrentSkinColor "Systems" &KrakatoaSkinColorsStruct.Systems) as string)
			setIniSetting theFile "CheckbuttonColors" "Loaders" ((getCurrentSkinColor "Loaders" &KrakatoaSkinColorsStruct.Loaders) as string)
			setIniSetting theFile "CheckbuttonColors" "Thinking" ((getCurrentSkinColor "Thinking" &KrakatoaSkinColorsStruct.Thinking) as string)
			setIniSetting theFile "CheckbuttonColors" "Matte" ((getCurrentSkinColor "Matte" &KrakatoaSkinColorsStruct.Matte) as string)
			setIniSetting theFile "CheckbuttonColors" "APME" ((getCurrentSkinColor "APME" &KrakatoaSkinColorsStruct.APME) as string)
			setIniSetting theFile "CheckbuttonColors" "Preferences" ((getCurrentSkinColor "Preferences" &KrakatoaSkinColorsStruct.Preferences) as string)
			setIniSetting theFile "CheckbuttonColors" "VFB" ((getCurrentSkinColor "VFB" &KrakatoaSkinColorsStruct.VFB) as string)
			setIniSetting theFile "CheckbuttonColors" "GlobalRenderValues" ((getCurrentSkinColor "GlobalRenderValues" &KrakatoaSkinColorsStruct.GlobalRenderValues) as string)
		)
	)
	
	fn loadSkinColors =
	(
		makedir (Krakatoa_PresetsDirectory+ "\\ColorPresets") all:true
		local theFile = getOpenFilename caption:"Select Custom Checkbutton Colors Preset Name to Load..." filename:(Krakatoa_PresetsDirectory + "\\ColorPresets\\") types:"Krakatoa Color Preset (*.kcp)|*.kcp" history:"KrakatoaPresets"
		if theFile != undefined do
		(
			try(setCurrentSkinColor "History" &KrakatoaSkinColorsStruct.History  (execute (getIniSetting theFile "CheckbuttonColors" "History")))catch()
			try(setCurrentSkinColor "Main" &KrakatoaSkinColorsStruct.Main (execute (getIniSetting theFile "CheckbuttonColors" "Main")))catch()
			try(setCurrentSkinColor "Channels" &KrakatoaSkinColorsStruct.Channels (execute (getIniSetting theFile "CheckbuttonColors" "Channels")))catch()
			try(setCurrentSkinColor "Partitioning" &KrakatoaSkinColorsStruct.Partitioning (execute (getIniSetting theFile "CheckbuttonColors" "Partitioning")))catch()
			try(setCurrentSkinColor "Systems" &KrakatoaSkinColorsStruct.Systems (execute (getIniSetting theFile "CheckbuttonColors" "Systems")))catch()
			try(setCurrentSkinColor "Loaders" &KrakatoaSkinColorsStruct.Loaders (execute (getIniSetting theFile "CheckbuttonColors" "Loaders")))catch()
			try(setCurrentSkinColor "Thinking" &KrakatoaSkinColorsStruct.Thinking (execute (getIniSetting theFile "CheckbuttonColors" "Thinking")))catch()
			try(setCurrentSkinColor "Matte" &KrakatoaSkinColorsStruct.Matte (execute (getIniSetting theFile "CheckbuttonColors" "Matte")))catch()
			try(setCurrentSkinColor "APME" &KrakatoaSkinColorsStruct.APME (execute (getIniSetting theFile "CheckbuttonColors" "APME")))catch()
			try(setCurrentSkinColor "Preferences" &KrakatoaSkinColorsStruct.Preferences (execute (getIniSetting theFile "CheckbuttonColors" "Preferences")))catch()
			try(setCurrentSkinColor "VFB" &KrakatoaSkinColorsStruct.VFB (execute (getIniSetting theFile "CheckbuttonColors" "VFB")))catch()
			try(setCurrentSkinColor "GlobalRenderValues" &KrakatoaSkinColorsStruct.GlobalRenderValues (execute (getIniSetting theFile "CheckbuttonColors" "GlobalRenderValues")))catch()
			
			updateSkinColorDisplay ddl_SkinColor.selection
		)
	)			
	
	
		
	fn refresh_GUI =
	(			
		local KrakatoaPreferencesINI = (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini" )
		local theVal = execute (getIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "SkinColors" "UseCustomColors")
		ckb_useSkinColors.checked = if theVal == OK then false else theVal

		local theVal = execute (getIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini" ) "SkinColors" "LastSelection" )
		ddl_SkinColor.selection = if theVal == OK then 1 else theVal

		
		updateSkinColorDisplay ddl_SkinColor.selection
		
		local Hue = execute (getIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini" ) "IconColors"  "Hue")
		if Hue == OK do Hue = 0
		local Sat = execute (getIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini" ) "IconColors"  "Saturation")
		if Sat == OK do Sat = 0
		local Val= execute (getIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini" ) "IconColors"  "Value")
		if Val == OK do Val = 0		
			
		local AbsRel= execute (getIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini" ) "IconColors"  "AbsoluteRelative")
		if AbsRel == OK do AbsRel = 1
			
		spn_IconColorHue.value = Hue
		spn_IconColorSat.value = Sat
		spn_IconColorValue.value = Val
		ddl_absRel.selection  = AbsRel


		if Krakatoa_Initializing_Hidden_Rollouts == false do 
			try(Krakatoa_GUI_Preferences_Colors.open = FranticParticles.GetBoolProperty "GUI:PreferencesColorsRolloutOpen")catch()
	)
	
	on ckb_useSkinColors changed state do
	(
		setIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "SkinColors" "UseCustomColors" ((KrakatoaSkinColorsStruct.UseCustomColors = state) as string)
	)
	
	on btn_updateColors pressed do
	(
		Krakatoa_LoadSkinColors()
		FranticParticleRenderMXS.OpenGUI()		
	)
	
	on ddl_SkinColor selected itm do
	(
		updateSkinColorDisplay itm
		setIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini" ) "SkinColors" "LastSelection" (itm as string)
	)
	
	on clr_CheckbuttonColor changed theColor do
	(
		case ddl_SkinColor.selection of
		(
			1: setCurrentSkinColor "History" &KrakatoaSkinColorsStruct.History  theColor
			2: setCurrentSkinColor "GlobalRenderValues" &KrakatoaSkinColorsStruct.GlobalRenderValues theColor
			3: setCurrentSkinColor "Main" &KrakatoaSkinColorsStruct.Main theColor
			4: setCurrentSkinColor "Channels" &KrakatoaSkinColorsStruct.Channels theColor
			5: setCurrentSkinColor "Partitioning" &KrakatoaSkinColorsStruct.Partitioning theColor
			6: setCurrentSkinColor "Systems" &KrakatoaSkinColorsStruct.Systems theColor
			7: setCurrentSkinColor "Loaders" &KrakatoaSkinColorsStruct.Loaders theColor
			8: setCurrentSkinColor "Thinking" &KrakatoaSkinColorsStruct.Thinking theColor
			9: setCurrentSkinColor "Matte" &KrakatoaSkinColorsStruct.Matte theColor
			10: setCurrentSkinColor "APME" &KrakatoaSkinColorsStruct.APME theColor
			11: setCurrentSkinColor "Preferences" &KrakatoaSkinColorsStruct.Preferences theColor
			12: setCurrentSkinColor "VFB" &KrakatoaSkinColorsStruct.VFB theColor
		)			
	)
	
	on btn_SaveSkinColors pressed do saveSkinColors()
	on btn_LoadSkinColors pressed do LoadSkinColors()	
	
	
	on Krakatoa_GUI_Preferences_Colors rolledUp val do 
	(
			FranticParticles.SetProperty "GUI:PreferencesColorsRolloutOpen" val
			if val then 
				FranticParticles.LogDebug ("+Color Preferences Rollout ROLLED DOWN.")
			else
				FranticParticles.LogDebug ("+Color Preferences Rollout ROLLED UP.")
	)	
	

	fn updateIcons =
	(
		btn_IconColorPreset.images = #(Krakatoa_PresetsArrowBitmap,Krakatoa_PresetsArrowBitmap, 32,1,1,2,2)		
	)	
	
	on Krakatoa_GUI_Preferences_Colors open do 
	(
		updateIcons()
		Refresh_GUI()
		FranticParticles.LogDebug ("+Color Preferences Rollout OPENED.")			
	)				
)--end color preferences rollout

rollout Krakatoa_GUI_Preferences_System "System Preferences" category:100
(
	button btn_Help_Preferences "Open Online Help..." width:450 height:16 offset:[0,-5] align:#center tooltip:"Opens the Krakatoa Online Help for the System Preferences rollout in the default Web Browser. Requires Internet connection."

	on Krakatoa_GUI_Preferences_System moved pos do
	(
		setIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "RolloutDialogPositions" Krakatoa_GUI_Preferences.title (pos as string)
		--Krakatoa_CustomizeRollouts_Dialog.updateStripsPositions pos
	)	

	group "Performance"
	(
		checkbutton chk_multiThread_Loading ">Multi-Thread Partition LOADING" width:214 align:#left offset:[0,-4] across:2
		checkbutton chk_multiThread_Sorting ">Multi-Thread Particle SORTING" width:214 align:#right offset:[0,-4]
		checkbutton chk_multiThread_Lighting ">Multi-Thread Particle LIGHTING" width:214 align:#left offset:[0,-4] across:2
		checkbutton chk_multiThread_Drawing ">Multi-Thread Particle DRAWING" width:214 align:#right offset:[0,-4]
		
		spinner spn_FrameBufferAvailPhysMemoryFraction "Image Buffers Avail. Memory %:" across:2 align:#left fieldwidth:40 range:[1,100,70] scale:1.0 tooltip:"Defines the percentage of available physical memory to use for Image Buffers.\n\nOne Image Buffer will be allocated per output per thread, and can consume a lot of memory at high output resolutions with many threads.\n\nReduce this valie if memory cannot be allocated during rendering."
		spinner spn_RenderThreadLimit "Render Threads Limit (0=No Limit):" range:[0,16,0] fieldwidth:30 type:#integer align:#right tooltip:"Caps the number of Lighting Pass and Final Pass Drawing threads even if memory and core count allow for more threads.\n\nSet to 0 to use all threads determined by Krakatoa." --across:2 offset:[192,0] 
		--button btn_RenderThreadLimit_Presets ">>" width:20 height:17 align:#right offset:[0,-1]
	)	
	
	group "Particle Flow Systems"
	(
		checkbutton chk_autoincreasePflowSystemLimit ">Auto-Increase PFlow System Limit" width:214 across:2 offset:[0,-4] align:#left tooltip:"By default, Particle Flow Systems are limited to only 100K particles. To work well with Krakatoa, the limit should be increased. Enable this checkbutton to increase the limit automatically." highlightcolor:KrakatoaSkinColorsStruct.Preferences
		button btn_increasePflowSystemLimit "Increase PFlow System Limit Now!" width:214 align:#right offset:[0,-4] tooltip:"By default, Particle Flow Systems are limited to only 100K particles. To work well with Krakatoa, the limit should be increased. Press this button to increase the limit now."
	)
	
	group "Log Window"	
	(
		checkbutton chk_AutoOpenLogOnOutput ">Auto-Open Log Window On Warnings" width:214 across:2 offset:[0,-4] align:#left highlightcolor:KrakatoaSkinColorsStruct.Preferences
		button btn_OpenLogWindow "Open The Log Window Now!" width:214 align:#right offset:[0,-4]
	)		
	
	group "Old Files Loading"
	(
		checkbutton chk_convertMagmaVersion ">Convert Magma 1.x KCMs and CustomData Render Elements On Loading" width:440 align:#center
	)

	on chk_convertMagmaVersion changed state do 
	(
		::Krakatoa_ConvertMagmaVersion = state
	)
	
	fn refresh_GUI =
	(			

		local KrakatoaPreferencesINI = (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini" )
		
		theKVersion = FranticParticles.Version	
			
		if Krakatoa_Gui_floater != undefined do 
			Krakatoa_Gui_floater.title = ("Krakatoa v" + theKVersion + " - Primary Floater ")
		
		try(chk_autoincreasePflowSystemLimit.state = execute (getIniSetting KrakatoaPreferencesINI "System" "AutoIncreasePflowSystemLimit" ))catch(chk_autoincreasePflowSystemLimit.state = true)

			
		/*	
		--SORTING THREADS--
		local theIndex = findItem #("0","1","2","4","6","8","12","16","24","32") (FranticParticles.getProperty "SortingThreads")
		if theIndex == 0 do theIndex = 1
		ddl_sortingThreads.selection = theIndex
		*/
		chk_multiThread_Loading.checked = FranticParticles.GetBoolProperty "Performance:MT:Loading"
		chk_multiThread_Sorting.checked = FranticParticles.GetBoolProperty "Performance:MT:Sorting"
		chk_multiThread_Lighting.checked = FranticParticles.GetBoolProperty "Performance:MT:Lighting"
		chk_multiThread_Drawing.checked = FranticParticles.GetBoolProperty "Performance:MT:Drawing"
		spn_RenderThreadLimit.value = FranticParticles.getIntProperty "RenderThreadLimit"
		spn_FrameBufferAvailPhysMemoryFraction.value = (FranticParticles.getFloatProperty "FrameBufferAvailPhysMemoryFraction")*100.0
		
		chk_AutoOpenLogOnOutput.state = FranticParticles.PopupLogWindowOnMessage 
			
		chk_convertMagmaVersion.checked = ::Krakatoa_ConvertMagmaVersion == true

		if Krakatoa_Initializing_Hidden_Rollouts == false do 
			try(Krakatoa_GUI_Preferences_System.open = FranticParticles.GetBoolProperty "GUI:PreferencesSystemRolloutOpen")catch()
	)	

	on Krakatoa_GUI_Preferences_System rolledUp val do 
	(
			FranticParticles.SetProperty "GUI:PreferencesSystemRolloutOpen" val
			if val then 
				FranticParticles.LogDebug ("+System Preferences Rollout ROLLED DOWN.")
			else
				FranticParticles.LogDebug ("+System Preferences Rollout ROLLED UP.")
	)	
	
	fn updateIcons =
	(
			
	)
	
	/*
	fn ddl_sortingThreads_SelectedFN itm =
	(
		FranticParticles.setProperty "SortingThreads" (#("0","1","2","4","6","8","12","16","24","32"))[itm]
	)
	
	on ddl_sortingThreads selected itm do
	(
		ddl_sortingThreads_SelectedFN itm
	)	
	*/
	
	on chk_multiThread_Loading changed state do 
	(
		FranticParticles.SetProperty "Performance:MT:Loading" (state as string)
		try(Krakatoa_GUI_Channels.Refresh_GUI())catch()
	)
	on chk_multiThread_Sorting changed state do 
	(
		FranticParticles.SetProperty "Performance:MT:Sorting" (state as string)
		try(Krakatoa_GUI_Channels.Refresh_GUI())catch()
	)
	on chk_multiThread_Lighting changed state do 
	(
		FranticParticles.SetProperty "Performance:MT:Lighting" (state as string)
		try(Krakatoa_GUI_Channels.Refresh_GUI())catch()
	)
	on chk_multiThread_Drawing  changed state do 
	(
		FranticParticles.SetProperty "Performance:MT:Drawing" (state as string)
		try(Krakatoa_GUI_Channels.Refresh_GUI())catch()
	)
	on spn_RenderThreadLimit changed val do 
	(
		FranticParticles.SetProperty "RenderThreadLimit" (val as string)
		try(Krakatoa_GUI_Channels.Refresh_GUI())catch()
	)
	on spn_FrameBufferAvailPhysMemoryFraction changed val do 
	(
		FranticParticles.setProperty "FrameBufferAvailPhysMemoryFraction" ((val/100.0) as string)
		try(Krakatoa_GUI_Channels.Refresh_GUI())catch()
	)
	on spn_RenderThreadLimit changed val do 
	(
		FranticParticles.SetProperty "RenderThreadLimit" (val as string)
		try(Krakatoa_GUI_Channels.Refresh_GUI())catch()
	)
	on spn_FrameBufferAvailPhysMemoryFraction changed val do 
	(
		FranticParticles.setProperty "FrameBufferAvailPhysMemoryFraction" ((val/100.0) as string)
		try(Krakatoa_GUI_Channels.Refresh_GUI())catch()
	)
	on spn_RenderThreadLimit changed val do 
	(
		FranticParticles.SetProperty "RenderThreadLimit" (val as string)
		try(Krakatoa_GUI_Channels.Refresh_GUI())catch()
	)
	on spn_FrameBufferAvailPhysMemoryFraction changed val do 
	(
		FranticParticles.setProperty "FrameBufferAvailPhysMemoryFraction" ((val/100.0) as string)
		try(Krakatoa_GUI_Channels.Refresh_GUI())catch()
	)

	
	on btn_increasePflowSystemLimit pressed do FranticParticleRenderMXS.increasePFlowSystemLimits()
	on chk_autoincreasePflowSystemLimit changed state  do
		setIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "System" "AutoIncreasePflowSystemLimit" (state as string)

	on ddl_PRTpresets selected itm do
	(
		if itm > 0 do
			setIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "PRTLoaders" "PresetName" ddl_PRTpresets.selected
			
	)
	
	on chk_UsePRTPreset changed state do
	(
		setIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "PRTLoaders" "UsePreset" (state as string)
	)

	on chk_AutoOpenLogOnOutput changed state do 
	(
		FranticParticles.PopupLogWindowOnMessage = state
		updateToolbarButtons()
		setIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "System" "PopupLogWindowOnMessage" (FranticParticles.PopupLogWindowOnMessage as string)
	)
	
	on btn_OpenLogWindow pressed do 
	(
		FranticParticles.LogWindowVisible = true
		updateToolbarButtons()
	)
	
	on Krakatoa_GUI_Preferences_System open do 
	(
		--updateIcons()
		Refresh_GUI()
		FranticParticles.LogDebug ("+System Preferences Rollout OPENED.")			
	)			
	
)


--TODO: Add options for PRT Volume creation (box, hide, do nothing)

rollout Krakatoa_GUI_Preferences "User Interface and Interaction Preferences" rolledup:true category:200 width:457
(
	button btn_Help_Preferences "Open Online Help..." width:450 height:16 offset:[0,-5] align:#center tooltip:"Opens the Krakatoa Online Help for the User Interface and Interaction Preferences rollout in the default Web Browser. Requires Internet connection."

	on Krakatoa_GUI_Preferences moved pos do
	(
		setIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "RolloutDialogPositions" Krakatoa_GUI_Preferences.title (pos as string)
		--Krakatoa_CustomizeRollouts_Dialog.updateStripsPositions pos
	)			
	
	group "User Interface Extensions"
	(
		checkbutton chk_LoadVFBExtensions ">Load VFB Extensions On Startup" width:214 offset:[0,-4] across:2 tooltip:"Load the Rendered Frame Window (a.k.a. VFB or Virtual Frame Buffer) Extensions of Krakatoa on 3ds Max startup. If you checked this, you have to restart 3ds Max for the Extensions to appear!" align:#center highlightcolor:KrakatoaSkinColorsStruct.Preferences --enabled:false --((maxVersion())[1] > 10900)
		checkbutton chk_KrakatoaMenu ">Show Krakatoa Menu Item In Main Menu" width:214 offset:[0,-4] tooltip:"When checked (defaut), the Krakatoa menu will be added to Main Menu. When unchecked, the Krakatoa menu will be removed from the Main Menu" align:#right highlightcolor:KrakatoaSkinColorsStruct.Preferences 
	)	

	group "Factory and User-Defined Startup Defaults "
	(
		button btn_SaveDefaults "Save Current Settings As User Defaults..." width:214 offset:[0,-4] tooltip:"Store Current Settings as Initial Defaults for future Krakatoa Sessions." align:#left across:2
		button btn_ResetFactoryDefaults "Revert To Factory Defaults..." width:214 offset:[0,-4] tooltip:"Remove Custom Settings and Restore Factory Defaults for future Krakatoa Sessions." align:#right
	)
	
	group "User-Defined UI Behaviors"	
	(
		button btn_beginnerSettings "BEGINNER" width:140 across:3 align:#left offset:[0,-4] tooltip:"Switches the Behavior Preferences listed below to the most verbose settings. Krakatoa will try to help you by prompting in various situations which can be annoying for advanced users."
		button btn_advancedSettings "ADVANCED" width:140  align:#center offset:[0,-4] tooltip:"Switches the Behavior Preferences listed below to their less intrusive settings. Krakatoa will try to fix problems and make useful decisions for you without asking."
		button btn_expertSettings "EXPERT" width:140 align:#right offset:[0,-4] tooltip:"Switches the Behavior Preferences listed below to their least intrusive settings. Krakatoa will try not to interfere with your workflow, assuming you know what you are doing even when it makes no sense."
	)
	
	group "When switching between Krakatoa and other renderers,"
	(
		dropdownlist ddl_storeRenderOutputPathOnRenderSwitchBehavior "" items:#("Ask me about Restoring the Last Render Output Path used by the Renderer","Do NOT Ask me but Do Restore the Last Render Output Path used by the Renderer","Do NOT Ask me and Do NOT Restore the Last Render Output Path used by the Renderer") width:440 align:#center 
		dropdownlist ddl_SwitchedToRendererMessageBehavior "" items:#("Show a Message Window with the Renderer Type","Show the Renderer Type in the Prompt Only","Do NOT Show the Renderer Type") width:440 align:#center 
	)
	
	group "When adding or removing Shader Render Elements via the Shader Parameters rollout,"
	(
		dropdownlist ddl_OpenRenderElementsTabOnChange "" items:#("Open the Render Setup dialog at the [Render Elements] Tab.","Do NOT Open the Render Setup dialog at the [Render Elements] Tab.") width:440 align:#center 
	)
	
	group "When saving to RealFlow 4 BIN files with less than 5 trailing digits in the File Name,"
	(
		dropdownlist ddl_binFileSaving "" items:#("Warn Me About The Problem And Suggest To Fix Automatically","Fix Problem By Adding Trailing Zeros Without Warning","Do NOT Do Anything") width:440 align:#center 
	)
	
	group "When switching to and from 'Save Particles To File Sequence' Mode,"
	(
		dropdownlist ddl_saveModeTogglesPartitionsRollout  items:#("Open and Close the 'Particle Partitioning' Rollout","Do NOT Open, But Do Close When Switching To 'Render Scene Particles'","Open, But Do NOT Close When Switching To 'Render Scene Particles'","Do NOT Change 'Particle Partitioning' Rollout Open/Close State At All.") width:440 align:#center
	)
	
	group "When Creating a New PRT Volume from Selected Geometry,"
	(
		dropdownlist ddl_createPRTVolumeBehavior	items:#("Turn OFF the Source Geometry's Renderable property","Switch the Display of the Source Geometry to Bounding BOX","Turn OFF the Renderable property AND Switch Source Geometry to Bounding BOX","Hide the Source Geometry object","Do NOT Change the Source Geometry object") width:440 align:#center
		spinner spn_createPRTSpacing "Viewport Spacing Factor (higher values produce more particles, default is 50.0):" scale:10 fieldwidth:40 align:#right range:[10,100,50]
	)
	
	group "When Creating a New PRT Loader,"
	(
		dropdownlist ddl_createLoadersBehavior  items:#("Open File Dialog After Loader Creation At Current Save Path, If None - At Default Path","Open File Dialog After Loader Creation At Default Path","Do NOT Open File Dialog After Loader Creation.") width:440 align:#center
	)
	group "Default Path For New PRT Loader"
	(
		button btn_DefaultPathHistory "H" width:18 height:20 offset:[-6,-4] align:#left across:4 tooltip:"Browse Save Particles Paths History And Select a Default Path To Open the PRT Loader's Add... File Browser At..." 
		button btn_PickDefaultLoaderPath  "..." width:18 height:20 offset:[-95,-4] align:#left tooltip:"Select a Default Path To Open the PRT Loader's Add... File Browser At..."
		edittext edt_DefaultLoaderPath "Path" fieldwidth:358 align:#left offset:[-181,-2] 
		button btn_ExploreDefaultPath "E" align:#right width:18 height:20 offset:[7,-4] tooltip:"Open Default PRT Loader File Browser Path In Windows Explorer..."  
	)
	
	group "When Creating a New PRT Loader," 	
	(
		checkbutton chk_UsePRTPreset ">Apply Preset To New PRT Loader:" width:214 offset:[0,-4] tooltip:"Store Current Settings as Initial Defaults for future Krakatoa Sessions." align:#left across:2 highlightcolor:KrakatoaSkinColorsStruct.Preferences
		dropdownlist ddl_PRTpresets items:#("") width:214 align:#right offset:[0,-4] 
	)
		
	group "When Adding File Sequences to PRT Loader,"
	(
		dropdownlist ddl_addFileSequenceBehavior  items:#("Set ALL Sequences To Display In BOTH Viewport And Renderer","Set NO Sequences To Display In Viewport, ALL To Display In Renderer","Set ONLY FIRST Sequence To Display In Viewport,ALL In Renderer","Set ALL To Display NEITHER In Viewport NOR In Renderer") width:440 align:#center
	)		
	
	on spn_createPRTSpacing changed val do
	(
		setIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "Preferences" "PRTVolumeSpacingFactor" (val as string)
	)
	
	fn refresh_GUI =
	(			
		local KrakatoaPreferencesINI = (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini" )

		try(ddl_OpenRenderElementsTabOnChange.selection = execute (getIniSetting KrakatoaPreferencesINI "Preferences" "OpenRenderElementsTabOnChange"))catch()
		try(ddl_binFileSaving.selection = execute (getIniSetting KrakatoaPreferencesINI "Preferences" "RealFlowBinFileSaving"))catch()
		try(ddl_saveModeTogglesPartitionsRollout.selection = execute (getIniSetting KrakatoaPreferencesINI "Preferences" "SaveModeTogglePartitionsRollout"))catch()
		try(ddl_createPRTVolumeBehavior.selection = execute (getIniSetting KrakatoaPreferencesINI "Preferences" "CreatePRTVolumeBehavior"))catch()
		try(ddl_createLoadersBehavior.selection = execute (getIniSetting KrakatoaPreferencesINI "Preferences" "CreateLoadersBehavior"))catch()
		try(ddl_addFileSequenceBehavior.selection = execute (getIniSetting KrakatoaPreferencesINI "Preferences" "AddFileSequenceBehavior"))catch()
		try(ddl_storeRenderOutputPathOnRenderSwitchBehavior.selection = execute (getIniSetting KrakatoaPreferencesINI "Preferences" "StoreRenderOutputPathOnRenderSwitchBehavior"))catch()
		try(ddl_SwitchedToRendererMessageBehavior.selection = execute (getIniSetting KrakatoaPreferencesINI "Preferences" "SwitchedToRendererMessageBehavior"))catch()

		edt_DefaultLoaderPath.text = getIniSetting KrakatoaPreferencesINI "Preferences" "DefaultLoaderPath"
		
		try(spn_createPRTSpacing.value = execute (getIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "Preferences" "PRTVolumeSpacingFactor"))catch()
			
		chk_LoadVFBExtensions.state = (getIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "Preferences" "LoadVFBExtensionsOnStartup") == "true"
		chk_KrakatoaMenu.checked = not matchPattern (getIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini" ) "MenuSystem" "CreateMenu") pattern:"false"

		theFiles = getFiles (Krakatoa_PresetsDirectory + "\\presets\\*.KPS")
		ddl_PRTpresets.items= join #() (for f in theFiles collect getFileNameFile f)
		theVal = execute (getIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "PRTLoaders" "UsePreset")
		chk_UsePRTPreset.checked = if theVal != OK then theVal else false
		theIndex = findItem ddl_PRTpresets.items (getIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "PRTLoaders" "PresetName" )
		ddl_PRTpresets.selection = theIndex
			
			
		if Krakatoa_Initializing_Hidden_Rollouts == false do 
			try(Krakatoa_GUI_Preferences.open = FranticParticles.GetBoolProperty "GUI:PreferencesRolloutOpen")catch()
	)	
	
	
	on btn_SaveDefaults pressed do 
	(
		if querybox "Do you want to SAVE the current Renderer Settings as initial DEFAULTS for future Krakatoa Sessions?" title:"Krakatoa: Save Defaults" then 
			FranticParticleRenderMXS.saveCustomDefaults()
	)
	
	on btn_ResetFactoryDefaults pressed do
	(
		if querybox "Do you want to RESET the initial DEFAULTS for future Krakatoa Sessions to the Factory Defaults?\n\nThis will rename the file 'KrakatoaDefaults.ini' to 'KrakatoaDefaults.bak' in the \Plugcfg folder of 3ds Max\nand thus cause new instances of Krakatoa to start up with Factory Default settings intead of User Defaults." title:"Krakatoa: Reset Factory Defaults" then 
		(
			deleteFile (GetDir #plugcfg + "\\Krakatoa\\KrakatoaDefaults.bak") 
			renameFile (GetDir #plugcfg + "\\Krakatoa\\KrakatoaDefaults.ini") (GetDir #plugcfg + "\\Krakatoa\\KrakatoaDefaults.bak")
		)
	)
	

	on ddl_OpenRenderElementsTabOnChange selected itm do
		setIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "Preferences" "OpenRenderElementsTabOnChange" (itm as string)
	
	
	--on ddl_blendedModeSwitch selected itm do setIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "Preferences" "BlendModeSwitch" (itm as string)
	on ddl_binFileSaving selected itm do
		setIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "Preferences" "RealFlowBinFileSaving" (itm as string)
	on ddl_saveModeTogglesPartitionsRollout selected itm do	
		setIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "Preferences" "SaveModeTogglePartitionsRollout" (itm as string)
	on ddl_createLoadersBehavior selected itm do
		setIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "Preferences" "CreateLoadersBehavior" (ddl_createLoadersBehavior.selection as string)
	on ddl_addFileSequenceBehavior 	selected itm do
		setIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "Preferences" "AddFileSequenceBehavior" (ddl_addFileSequenceBehavior.selection as string)

	on ddl_storeRenderOutputPathOnRenderSwitchBehavior selected itm do
		setIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "Preferences" "StoreRenderOutputPathOnRenderSwitchBehavior" (ddl_storeRenderOutputPathOnRenderSwitchBehavior.selection as string)
	
	on ddl_SwitchedToRendererMessageBehavior selected itm do
		setIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "Preferences" "SwitchedToRendererMessageBehavior" (itm as string)
	
	on ddl_createPRTVolumeBehavior selected itm do
		setIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "Preferences" "CreatePRTVolumeBehavior" (itm as string)
		
	
	on btn_DefaultPathHistory pressed do
	( 
		local st = timestamp()
		Krakatoa_GUI_SaveParticles.allPaths = #()
		Krakatoa_GUI_SaveParticles.allValues = #()
		Krakatoa_GUI_SaveParticles.getFromKrakatoaHistory mode:#PreferencesPRT theControl:edt_particleFiles searchKey:"ParticleFiles"
		if Krakatoa_GUI_SaveParticles.historyValue != undefined do 
		(
			Krakatoa_GUI_SaveParticles.historyValue = getFileNamePath Krakatoa_GUI_SaveParticles.historyValue
			if not matchPattern Krakatoa_GUI_SaveParticles.historyValue pattern:"*\\" do
				Krakatoa_GUI_SaveParticles.historyValue += "\\"
			setIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "Preferences" "DefaultLoaderPath" (edt_DefaultLoaderPath.text = Krakatoa_GUI_SaveParticles.historyValue)
		)	
	)	
	
	on btn_PickDefaultLoaderPath pressed do
	(
		local newDefaultPath = getSavePath caption:"Select the Particle File Sequence to Save" 
		if newDefaultPath != undefined do 
		(
			if not matchPattern newDefaultPath pattern:"*\\" do newDefaultPath += "\\"
			setIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "Preferences" "DefaultLoaderPath" (edt_DefaultLoaderPath.text = newDefaultPath)
		)			
	)
	
	on edt_DefaultLoaderPath entered txt do
	(
		if doesFileExist txt then
		(
			if not matchPattern txt pattern:"*\\" do txt += "\\"
			setIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "Preferences" "DefaultLoaderPath" txt
			edt_DefaultLoaderPath.text = txt
		)	
		else	
			edt_DefaultLoaderPath.text = getIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "Preferences" "DefaultLoaderPath" 
	)

	on btn_ExploreDefaultPath pressed do
	(
		if doesFileExist edt_DefaultLoaderPath.text then
			shellLaunch "explorer.exe" edt_DefaultLoaderPath.text
	)
	
	on chk_KrakatoaMenu changed state do
	(
		setIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini" ) "MenuSystem" "CreateMenu" (state as string)
		try(fileIn (FranticParticles.KrakatoaHome + "Scripts\\KrakatoaMenuCreator.ms") )catch()
	)
	
	on chk_LoadVFBExtensions changed state do 
	(
		setIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "Preferences" "LoadVFBExtensionsOnStartup" (state as string)
	)	
	
	
	on Krakatoa_GUI_Preferences rolledUp val do 
	(
			FranticParticles.SetProperty "GUI:PreferencesRolloutOpen" val
			if val then 
				FranticParticles.LogDebug ("+Preferences Rollout ROLLED DOWN.")
			else
				FranticParticles.LogDebug ("+Preferences Rollout ROLLED UP.")
	)	
	
	fn updateIcons =
	(
		btn_ExploreDefaultPath.images = #(Krakatoa_PresetsArrowBitmap,Krakatoa_PresetsArrowBitmap, 32,12,12,12,12)
		btn_DefaultPathHistory.images = #(Krakatoa_PresetsArrowBitmap,Krakatoa_PresetsArrowBitmap, 32,10,10,10,10)
		btn_PickDefaultLoaderPath.images = #(Krakatoa_PresetsArrowBitmap,Krakatoa_PresetsArrowBitmap, 32,11,11,11,11)		
	)	
	
	on Krakatoa_GUI_Preferences open do 
	(
		updateIcons()
		Refresh_GUI()
		FranticParticles.LogDebug ("+Preferences Rollout OPENED.")			
	)			
	
	
	on btn_beginnerSettings pressed do
	(
		--setIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "Preferences" "BlendModeSwitch" "1"
		setIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "Preferences" "StoreRenderOutputPathOnRenderSwitchBehavior" "1"
		setIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "Preferences" "SwitchedToRendererMessageBehavior" "1"
		
		setIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "Preferences" "OpenRenderElementsTabOnChange" "1"
		setIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "Preferences" "RealFlowBinFileSaving" "1"
		setIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "Preferences" "SaveModeTogglePartitionsRollout" "1"
		setIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "Preferences" "CreateLoadersBehavior" "1"
		setIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "Preferences" "AddFileSequenceBehavior" "1"
		setIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "Preferences" "CreatePRTVolumeBehavior" "1"
		
		refresh_GUI()	
	)
	on btn_advancedSettings pressed do
	(
		--setIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "Preferences" "BlendModeSwitch" "2"
		
		setIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "Preferences" "StoreRenderOutputPathOnRenderSwitchBehavior" "2"
		setIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "Preferences" "SwitchedToRendererMessageBehavior" "2"
		
		setIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "Preferences" "OpenRenderElementsTabOnChange" "2"
		setIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "Preferences" "RealFlowBinFileSaving" "2"
		setIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "Preferences" "SaveModeTogglePartitionsRollout" "2"
		setIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "Preferences" "CreateLoadersBehavior" "2"
		setIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "Preferences" "AddFileSequenceBehavior" "2"
		setIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "Preferences" "CreatePRTVolumeBehavior" "3"
		
		refresh_GUI()	
	)	
	on btn_expertSettings pressed do
	(
		--setIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "Preferences" "BlendModeSwitch" "3"
		setIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "Preferences" "StoreRenderOutputPathOnRenderSwitchBehavior" "3"
		setIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "Preferences" "SwitchedToRendererMessageBehavior" "3"
		
		setIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "Preferences" "OpenRenderElementsTabOnChange" "2"
		setIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "Preferences" "RealFlowBinFileSaving" "3"
		setIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "Preferences" "SaveModeTogglePartitionsRollout" "4"
		setIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "Preferences" "CreateLoadersBehavior" "3"
		setIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "Preferences" "AddFileSequenceBehavior" "4"

		setIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "Preferences" "CreatePRTVolumeBehavior" "5"		
		refresh_GUI()	
	)	
)--end rollout

rollout Krakatoa_GUI_KSRExporter_Preferences "Krakatoa SR Exporter Preferences" category:210 width:457
(
	group "Export Preferences"
	(
		checkbutton chk_forceHairAsPRTExport ">Force Baking of PRT Hair to PRT Files" width:440 align:#center highlightcolor:KrakatoaSkinColorsStruct.Preferences tooltip:"When unchecked, PRT Hair without modifiers and texture maps can be exported as a Splines file and the particles will be generated by Krakatoa SR. \n\nWhen checked, PRT Hair will always be baked to PRT files."
		checkbutton chk_forcePRTAsPRTExport ">Force Baking of PRT Loaders to PRT Files" width:440 align:#center highlightcolor:KrakatoaSkinColorsStruct.Preferences tooltip:"When unchecked, PRT Loaders without modifiers and texture maps can be exported without baking and will use the original sequences. \n\nWhen checked, PRT Loaders will always be baked to new PRT files."
		--checkbutton chk_forceWorldSpacePRTExport ">Force Export of all PRT Files in World Space" width:440 align:#center highlightcolor:KrakatoaSkinColorsStruct.Preferences tooltip:"When unchecked, every particle system will be exported in object space using its object transformations.\n\nWhen checked, every particle system will be exported in world space."
		--checkbutton chk_forceSinglePRTExport ">Export all Scene Particles as a Single PRT File in World Space" width:440 align:#center highlightcolor:KrakatoaSkinColorsStruct.Preferences tooltip:"When unchecked, every particle system will be exported as a separate entity with its own data file.\n\nWhen checked, all particles will be combined into one single PRT file."
		--checkbutton chk_exportMemoryChannelsOnly ">Export All Avaialble Particle Data Channels" width:440 align:#center highlightcolor:KrakatoaSkinColorsStruct.Preferences tooltip:"When unchecked, only the memory channels required for rendering will be exported.\n\nWhen checked, all channels found in the particle system will be exported."
	)
	group "After Successful Python Scene Description Export, "
	(
		checkbutton chk_openPythonForEditing ">Open Python Scene File for Editing" width:280 offset:[4,0] align:#right highlightcolor:KrakatoaSkinColorsStruct.Preferences tooltip:"When unchecked, the exported Python file will be written to disk but not opened for editing. \n\nWhen checked, the exported Python file will be saved and opened for editing."
		edittext edt_pythonEditorLocation "Path To Python Source Editor:" text:"notepad.exe" labelOnTop:true fieldwidth:440 align:#center offset:[0,-22]
		
		checkbutton chk_runPythonFile ">Run the Python Scene File to Render a Frame" width:280 offset:[4,0] align:#right highlightcolor:KrakatoaSkinColorsStruct.Preferences tooltip:"When unchecked, the exported Python file will be written to disk but not rendered automatically. \n\nWhen checked, the exported Python file will be launched with Python.exe."
		edittext edt_pythonLocation "Path To Python Executable:" text:"c:\\python26\\python.exe" labelOnTop:true fieldwidth:440 align:#center offset:[0,-22]

		checkbutton chk_PauseAfterExecutingPython ">Pause BAT File After Python Execution" width:440 align:#center highlightcolor:KrakatoaSkinColorsStruct.Preferences tooltip:"When unchecked, the Command Window will close after Python execution has completed. \n\nWhen checked, a PAUSE will be added to the end of the BAT file to keep the Command Window open."
	)
	fn Refresh_GUI =
	(
		chk_forceHairAsPRTExport.checked = (execute (getIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "KSRPreferences" "ForceHairAsPRTExport")) == true
		chk_forcePRTAsPRTExport.checked = (execute (getIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "KSRPreferences" "ForcePRTAsPRTExport")) == true 	
		--chk_forceWorldSpacePRTExport.checked = (execute (getIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "KSRPreferences" "ForceWorldSpace")) == true
		--chk_forceSinglePRTExport.checked = (execute (getIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "KSRPreferences" "ExportSinglePRT")) == true
		--chk_exportMemoryChannelsOnly.checked = (execute (getIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "KSRPreferences" "ExportAllChannels")) == true
			
		chk_openPythonForEditing.checked = (execute (getIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "KSRPreferences" "OpenPythonForEditing")) != false
		chk_runPythonFile.checked = (execute (getIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "KSRPreferences" "RunPythonFile")) != false
			
		chk_PauseAfterExecutingPython.checked = (execute (getIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "KSRPreferences" "PauseAfterExecutingPython")) != false
			
		local thePath = getIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "KSRPreferences" "PathToPythonExecutable"
		if not doesFileExist thePath do thePath = "c:\\python26\\python.exe"
		if not doesFileExist thePath do thePath = ""
		edt_pythonLocation.text = thePath
		
		local thePath = getIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "KSRPreferences" "PathToPythonEditor"
		if not MatchPattern thePath pattern:"*.exe" do thePath = "notepad.exe"
		edt_pythonEditorLocation.text = thePath
	)
	
	on edt_pythonEditorLocation entered txt do 
	(
		local thePath = txt
		if not MatchPattern thePath pattern:"*.exe" do thePath = "notepad.exe"
		setIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "KSRPreferences" "PathToPythonEditor" (thePath as string)
		edt_pythonEditorLocation.text = thePath
	)
	on edt_pythonLocation entered txt do 
	(
		local thePath = txt
		if not MatchPattern thePath pattern:"*python.exe" or not doesFileExist thePath do thePath = "c:\\python26\\python.exe"
		setIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "KSRPreferences" "PathToPythonExecutable" (thePath as string)
		edt_pythonLocation.text = thePath
	)
	
	on chk_forceHairAsPRTExport changed state do setIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "KSRPreferences" "ForceHairAsPRTExport" (state as string)
	on chk_forcePRTAsPRTExport changed state do setIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "KSRPreferences" "ForcePRTAsPRTExport" (state as string)
	--on chk_forceWorldSpacePRTExport changed state do setIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "KSRPreferences" "ForceWorldSpace" (state as string)
	--on chk_forceSinglePRTExport changed state do setIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "KSRPreferences" "ExportSinglePRT" (state as string)
	--on chk_exportMemoryChannelsOnly changed state do setIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "KSRPreferences" "ExportAllChannels" (state as string)
	
	on chk_openPythonForEditing changed state do setIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "KSRPreferences" "OpenPythonForEditing" (state as string)
	on chk_runPythonFile changed state do setIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "KSRPreferences" "RunPythonFile" (state as string)
	
	on chk_PauseAfterExecutingPython changed state do setIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "KSRPreferences" "PauseAfterExecutingPython" (state as string)
	
	on Krakatoa_GUI_KSRExporter_Preferences open do
	(
		if matchPattern (FranticParticles.GetProperty "ParticleMode") pattern:"*Krakatoa SR*"	do Krakatoa_GUI_KSRExporter_Preferences.open = true
		
		Refresh_GUI()
		FranticParticles.LogDebug ("+Krakatoa SR Exporter Preferences Rollout OPENED.")					
	)
)--end rollout

rollout Krakatoa_GUI_AmbientPME "Ambient PME" category:48 width:457
(
	local thePMEBitmap --= bitmap 400 1
	local thePMEMasterBitmap --= bitmap 440 20

	button btn_LoadSave_APME "<>" across:4 align:#left width:20 height:16 offset:[-10,-5] tooltip:"Load and Save Presets For This Rollout Only" 
	button btn_Help_APME  "Open Online Help..." width:100 height:16 align:#center offset:[-100,-5] tooltip:"Opens the Krakatoa Online Help for the Ambient PME rollout in the default Web Browser. Requires Internet connection."
	button btn_BackTo_Main "Back To Main Controls..." height:16 width:308 offset:[-3,-5] align:#center tooltip:"Closes the rollout and sets focus on\nthe Main Controls rollout."
	button btn_Float_Rollout ">" height:16 width:20 offset:[10,-5] align:#right tooltip:"Float/Dock the Rollout.\nRight-Click for Menu..." 
	

	
	on btn_BackTo_Main pressed do
	(
		Krakatoa_GUI_AmbientPME.open = false
		FranticParticleRenderMXS.BackToMainControls()
	)	
	on btn_BackTo_Main rightclick do
	(
		Krakatoa_GUI_AmbientPME.open = false
		FranticParticleRenderMXS.BackToMainControls()
	)		
	
	on btn_LoadSave_APME pressed do 
	(
		Krakatoa_RCMenu_Struct.Float_Rollout_RCMenu_CurrentRollout = Krakatoa_GUI_AmbientPME
		popupMenu Krakatoa_RCMenu_Struct.Load_Save_Rollout_RCMenu pos:mouse.screenpos
	)	
	on btn_LoadSave_APME rightClick do 
	(
		Krakatoa_RCMenu_Struct.Float_Rollout_RCMenu_CurrentRollout = Krakatoa_GUI_AmbientPME
		popupMenu Krakatoa_RCMenu_Struct.Load_Save_Rollout_RCMenu pos:mouse.screenpos
	)	
	
	on btn_Float_Rollout pressed do
	(
		FranticParticleRenderMXS.FloatRolloutButtonPressed Krakatoa_GUI_AmbientPME
	)		
	on btn_Float_Rollout rightClick do
	(
		Krakatoa_RCMenu_Struct.Float_Rollout_RCMenu_CurrentRollout = Krakatoa_GUI_AmbientPME
		popupMenu Krakatoa_RCMenu_Struct.Float_Rollout_RCMenu pos:mouse.screenpos
	)			

	on Krakatoa_GUI_AmbientPME moved pos do
	(
		setIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "RolloutDialogPositions" Krakatoa_GUI_AmbientPME.title (pos as string)
		Krakatoa_CustomizeRollouts_Dialog.updateStripsPositions pos
	)			

	checkbutton chk_PMEfreeMode "--" width:23 across:3 align:#left offset:[-10,0] height:22 tooltip:"Allow Negative Extinction Values (For Masking Purposes Only, NOT A VALID PHYSICAL BEHAVIOR!)" highlightcolor:KrakatoaSkinColorsStruct.APME
	checkbutton chk_useAmbientPME ">Use Ambient Participating Medium Extinction (APME)" width:400 height:22  align:#center offset:[0,0] tooltip:"Toggle Ambient Participating Medium Extinction On and Off." highlightcolor:KrakatoaSkinColorsStruct.APME
	button btn_PMEPresets ">>" width:23 height:22 align:#right offset:[10,0] tooltip:"Add, Remove and Load Ambient Participating Medium Extinction Preset Settings." 
	

	checkbutton chk_PMELockSpinners ">Link Values" width:100 align:#left across:3 offset:[-10,-3] tooltip:"Link Values - one spinner changes all three spinners proportionally. All spinners must be set to NON-ZERO values!" enabled:false highlightcolor:KrakatoaSkinColorsStruct.APME
	button btn_PMEAlignSpinners "Align To Blue..." width:100 align:#center offset:[-72,-3] tooltip:"Synch Spinner Values - Red and Green will be set to the Blue Value."
	edittext edt_presetname "Preset Name:" text:"Preset" across:3 fieldwidth:175 align:#right offset:[10,0]

	spinner spn_ExtinctionRed "Red Extinction:" range:[0.0,10000.0,0.0] scale:0.1 fieldwidth:50 across:3 align:#left offset:[-10,3]
	spinner spn_ExtinctionGreen "Green Extinction:" range:[0.0,10000.0,0.0] scale:0.1 fieldwidth:50 align:#center offset:[0,3]
	spinner spn_ExtinctionBlue "Blue Extinction:" range:[0.0,10000.0,0.0] scale:0.1 fieldwidth:50 align:#right offset:[10,3]
	
	group "Extinction Explorer"
	(
		spinner spn_PMEStart "Start:" range:[0,1000000,0] fieldwidth:60 across:2 align:#left offset:[-3,0] type:#worldunits
		spinner spn_PMEDistance "Distance from Start:" range:[0,1000000,1000] fieldwidth:60 align:#right offset:[3,0] type:#worldunits
	
		label lbl_startColorPercent align:#left across:3 offset:[-3,0]
		label lbl_midColorPercent align:#center offset:[0,0]
		label lbl_endColorPercent align:#right offset:[3,0]
		
		colorpicker clr_PMEBaseColor "" color:white height:20 fieldwidth:18 align:#left offset:[-10,-4] modal:false across:3
		bitmap bmp_PMEdisplay width:400 height:21 align:#center offset:[2,-4]
		colorpicker clr_PMETarget "" color:white height:20 fieldwidth:18 align:#right offset:[8,-4] modal:false
		
		label lbl_startColor align:#left across:3 offset:[-3,-8]
		label lbl_midColor align:#center offset:[0,-8]
		label lbl_endColor align:#right offset:[3,-8]
		
	)
	
	group "Extinction By Object Volume:"	
	(
		listbox lbx_allNamedSelectionSets "Named Selection Sets:" items:#() height:6 across:2 width:204 align:#left
		listbox lbx_useNamedSelectionSets "APME Objects Named Selection Sets:" items:#() height:6 width:205 align:#right
		button btn_update "Update Named Selection Set Lists" width:214 align:#left offset:[0,-3] across:3 tooltip:"Update both Named Selection Sets lists manually to reflect name changes, new and deleted selection sets etc."
		button btn_selectInScene "Select Highlighted" width:106 align:#right offset:[37,-3] tooltip:"Select the objects in the scene stored in the currently highlighted APME Objects Named Selection Set ."
		button btn_selectAllInScene "Select All" width:106 align:#right offset:[1,-3] tooltip:"Select the objects in the scene stored in all APME Objects Named Selection Sets."

		button btn_selectionSetAdd ">" height:40 align:#center width:20 offset:[0,-112] tooltip:"Move the highlighted Named Selection Set to the Matte Objects Named Selection Sets list. All geometry objects in it will become APME objects." 
		button btn_selectionSetRemove "<" height:40 align:#center offset:[0,-3] width:20 tooltip:"Remove the highlighted Named Selection Set from the APME Objects Named Selection Sets list." 
		
		edittext edt_createNewSelSet "NSS:" text:"KrakatoaAPMEObjects" across:2 width:214 align:#left offset:[-2,30]
		button btn_createNewSelSet "Create/Update APME Selection Set" width:214 align:#right offset:[0,30] height:18 tooltip:"Select objects, enter NSS name and press to create a new selection set. Select an existing NSS from the PME Objects NSS list, select objects in the scene and press to update."
	)
	
	
	
	fn saveSelectionSets =
	(
		local txt = "#("
		if lbx_useNamedSelectionSets.items.count > 0 do
		(
			for i = 1 to lbx_useNamedSelectionSets.items.count-1 do txt += "\"" + lbx_useNamedSelectionSets.items[i] as string + "\","
			txt += "\"" + lbx_useNamedSelectionSets.items[lbx_useNamedSelectionSets.items.count] as string + "\""
		)	
		txt += ")"
		FranticParticles.SetProperty "PME:NamedSelectionSets" txt
	)			
	
	fn updateSelectionSets =
	(
		theArray = execute (FranticParticles.GetProperty "PME:NamedSelectionSets")
		lbx_useNamedSelectionSets.items = theArray
		lbx_allNamedSelectionSets.items = for i = 1 to selectionsets.count where findItem theArray (getNamedSelSetName i) == 0 collect (getNamedSelSetName i)
		saveSelectionSets()
		--Krakatoa_GUI_Particles.updateParticlesList()
	)
	
	fn renamedSelectionSets theNames =
	(
		tempArray = lbx_useNamedSelectionSets.items
		for i = 1 to tempArray.count do if tempArray[i] == theNames[1] do tempArray[i] = theNames[2]
		lbx_useNamedSelectionSets.items = tempArray 
		updateSelectionSets()
	)

	on lbx_allNamedSelectionSets doubleClicked itm do
	(
		tempArray = lbx_useNamedSelectionSets.items
		append tempArray lbx_allNamedSelectionSets.selected 
		lbx_useNamedSelectionSets.items = tempArray
		saveSelectionSets()
		updateSelectionSets()
	)	

	on btn_selectionSetAdd pressed do 
	(		
		if lbx_allNamedSelectionSets.selection > 0 do
		(
			tempArray = lbx_useNamedSelectionSets.items
			append tempArray lbx_allNamedSelectionSets.selected 
			lbx_useNamedSelectionSets.items = tempArray
			saveSelectionSets()
			updateSelectionSets()				
		)	
	)
	
	on lbx_useNamedSelectionSets doubleClicked itm do
	(
		tempArray = lbx_useNamedSelectionSets.items
		deleteItem tempArray itm
		lbx_useNamedSelectionSets.items = tempArray
		saveSelectionSets()
		updateSelectionSets()				
	)
	
	on lbx_useNamedSelectionSets selected itm do edt_createNewSelSet.text = lbx_useNamedSelectionSets.selected
		
	
	on btn_selectionSetRemove pressed do 
	(		
		if lbx_useNamedSelectionSets.selection > 0 do
		(
			tempArray = lbx_useNamedSelectionSets.items
			deleteItem tempArray lbx_useNamedSelectionSets.selection
			lbx_useNamedSelectionSets.items = tempArray
			saveSelectionSets()
			updateSelectionSets()				
		)	
	)			
	on btn_update pressed do updateSelectionSets()
	
	on btn_selectAllInScene pressed do 
	(
		updateSelectionSets()	
		max select none
		for i = 1 to selectionsets.count where findItem lbx_useNamedSelectionSets.items (getNamedSelSetName i) != 0 do selectmore selectionsets[i]
	)	
	on btn_selectInScene pressed do 
	(
		updateSelectionSets()	
		max select none
		for i = 1 to selectionsets.count where lbx_useNamedSelectionSets.selected == (getNamedSelSetName i) do select selectionsets[i]
	)	
	
	on btn_createNewSelSet pressed do
	(
		if selection.count > 0 then
		(
			if edt_createNewSelSet.text != "" then
			(
				local theObjects = for o in selection where findItem geometryClass.classes (classof o) > 0 and classof o != TargetObject and classof o != KrakatoaPrtLoader and classof o != PF_Source collect o
				if theObjects.count > 0 then
				(
					selectionSets[edt_createNewSelSet.text] = theObjects 
					tempArray = lbx_useNamedSelectionSets.items
					if findItem tempArray edt_createNewSelSet.text == 0 do
					(
						append tempArray edt_createNewSelSet.text
						lbx_useNamedSelectionSets.items = tempArray
						saveSelectionSets()
					)	
					updateSelectionSets()
				)	
				else
					messagebox "The Current Selection Does Not Contain Any Valid Geometry Objects\n" title:"Cannot Create APME Objects Selection Set"
			)
			else
				messagebox "Please enter a valid name for the selection set\n" title:"Cannot Create APME Objects Selection Set"
		)
		else		
			messagebox "Please select some Geometry Objects in the scene!" title:"Cannot Create APME Objects Selection Set"
	)			
	
	fn createPresetsRCMenu  =
	(
		presetName = "PMEPresets"
		presetsList = #(
				#("Clear Oceanic Water", 36.889, 11.75, 0.73),
				#("Polluted Oceanic Water", 66.1, 9.2, 8.4),
				#("Average Coastal Water", 100.0, 23.7, 33.3)
			)
		local builtInPresetsCount = presetsList.count
		local theKeys = for i in (getIniSetting (Krakatoa_PresetsDirectory + "//KrakatoaPreferences.ini") presetName ) collect i
		searchList = for i in presetsList collect i[1]
		for k in theKeys do
		(
			try
			(
				val = execute (getIniSetting (Krakatoa_PresetsDirectory + "//KrakatoaPreferences.ini") presetName k)
				append presetsList #(k, val.x, val.y, val.z)
				append searchList k --(val.x as string + ", " +val.y as string + ", " + val.z as string)
			)catch()	
		)	

		theValue1 = Krakatoa_GUI_AmbientPME.spn_ExtinctionRed.value
		theValue2 = Krakatoa_GUI_AmbientPME.spn_ExtinctionGreen.value
		theValue3 = Krakatoa_GUI_AmbientPME.spn_ExtinctionBlue.value
		
		--searchValue =  (theValue1  as string + ", " +theValue2   as string + ", " + theValue3 as string)
		searchValue =edt_presetname.text
		storeValue = ("[" +theValue1  as string + "," +theValue2   as string + "," + theValue3 as string + "]")
		
		local txt = StringStream ""
		format "rcmenu Presets_RCMenu\n(\n" to:txt
		
		if findItem searchList searchValue == 0 do 
		(
			format  "menuItem mnu_AddPreset \"Add '%'\"\n"  searchValue  to:txt
			format  "on mnu_AddPreset picked do setIniSetting (Krakatoa_PresetsDirectory + \"//KrakatoaPreferences.ini\") \"%\" \"%\" \"%\" \n" presetName searchValue storeValue to:txt
			format  "separator spr_01\n"  to:txt
		)	
		if findItem searchList searchValue > builtInPresetsCount do 
		(
			format  "menuItem mnu_AddPreset \"Update '%'\"\n" searchValue to:txt
			format  "on mnu_AddPreset picked do setIniSetting (Krakatoa_PresetsDirectory + \"//KrakatoaPreferences.ini\") \"%\" \"%\" \"%\" \n" presetName searchValue storeValue to:txt
			format  "separator spr_02\n"  to:txt
		)
		
		cnt = 0
		for i in presetsList do
		(
			cnt += 1
			format  "menuItem mnu_preset% \"% [%,%,%]\" \n" cnt  i[1] i[2] i[3] i[4] to:txt
			format  "on mnu_preset% picked do (\nKrakatoa_GUI_AmbientPME.spn_ExtinctionRed.changed (Krakatoa_GUI_AmbientPME.spn_ExtinctionRed.value = %)\n" cnt i[2] to:txt
			format  "Krakatoa_GUI_AmbientPME.spn_ExtinctionGreen.changed (Krakatoa_GUI_AmbientPME.spn_ExtinctionGreen.value = %)\n" i[3] to:txt
			format  "Krakatoa_GUI_AmbientPME.edt_presetname.text = \"%\"\n" i[1] to:txt
			format  "Krakatoa_GUI_AmbientPME.spn_ExtinctionBlue.changed (Krakatoa_GUI_AmbientPME.spn_ExtinctionBlue.value = % )\n)\n" i[4] to:txt
		)
		if findItem searchList searchValue > builtInPresetsCount do 
		(
			format  "separator spr_09\n"  to:txt
			format  "menuItem mnu_RemovePreset \"Remove '%'\"\n" searchValue   to:txt
			format  "on mnu_RemovePreset picked do delIniSetting (Krakatoa_PresetsDirectory + \"//KrakatoaPreferences.ini\") \"%\" \"%\" \n" presetName searchValue to:txt
		)	
		format  ")\n" to:txt
		Krakatoa_RCMenu_Struct.Presets_RCMenu = execute (txt as string)
	)
	
	fn getExtinction =
	(
		local baseColor = clr_PMEBaseColor.color
		local theTargetColor = clr_PMETarget.color
		if clr_PMETarget.color.r == 0 and baseColor.r != 0 do clr_PMETarget.color.r = 0.0001
		if clr_PMETarget.color.g == 0 and baseColor.r != 0 do clr_PMETarget.color.g = 0.0001
		if clr_PMETarget.color.b == 0 and baseColor.r != 0 do clr_PMETarget.color.b = 0.0001
		
		local theDist = spn_PMEStart.value + spn_PMEDistance.value
		
		--Clamp Target Color Channels to Base Color Channels -We cannot get brighter!
		if theTargetColor.r > baseColor.r do theTargetColor.r = baseColor.r
		if theTargetColor.g > baseColor.g do theTargetColor.g = baseColor.g
		if theTargetColor.b > baseColor.b do theTargetColor.b = baseColor.b
		
		--Calculate the Extinctions for R, G and B channel
		minR = if baseColor.r > 0 then -(log (theTargetColor.r / baseColor.r) / theDist) else 0
		minG = if baseColor.g > 0 then -(log (theTargetColor.g / baseColor.g) / theDist) else 0
		minB = if baseColor.b > 0 then -(log (theTargetColor.b / baseColor.b) / theDist) else 0
		
		--If the result is very small, round it down to 0 (otherwise spinners show -0.0 which looks bad)
		if minR < 0.0001 do minR = 0
		if minG < 0.0001 do minG = 0
		if minB < 0.0001 do minB = 0
		[minR, minG, minB]
	)
	
	fn setExtinction = 
	(
		thePMEBitmap = bitmap 400 1
		thePMEMasterBitmap = bitmap 440 20

		unitsMultiplier = case units.SystemType of
		(
			#inches:1
			#millimeters: 25.4
			#centimeters: 2.54
			#meters:0.0254
			#kilometers:0.0000254
			#feet:0.0833333
			#miles:0.0000157828
			default:1
		)
		local thePME = ([spn_ExtinctionRed.value, spn_ExtinctionGreen.value, spn_ExtinctionBlue.value]/10000.0 *3.53 / unitsMultiplier  ) -- 
		local deltaDist = spn_PMEDistance.value/400.0
		local baseColor = clr_PMEBaseColor.color
		local visibility_r, visibility_g, visibility_b
		for i = 0 to 399 do
		(
			visibility_r =  baseColor.r * exp( -thePME.x * (spn_PMEStart.value + i*deltaDist)   )
			visibility_g = baseColor.g * exp( -thePME.y * (spn_PMEStart.value + i*deltaDist)  )
			visibility_b = baseColor.b * exp( -thePME.z * (spn_PMEStart.value + i*deltaDist)  )
			setPixels thePMEBitmap [i,0] #( ([visibility_r,visibility_g,visibility_b]) )
			if i == 0 do lbl_startColor.text = "Reference:" + [visibility_r,visibility_g,visibility_b] as string
		)	
		if visibility_r > 255 do visibility_r = 255
		if visibility_g > 255 do visibility_g = 255
		if visibility_b> 255 do visibility_b = 255
		
		clr_PMETarget.color =  [visibility_r,visibility_g,visibility_b] 
		lbl_endColor.text = "Target:" + [visibility_r,visibility_g,visibility_b] as string
		
		lbl_startColorPercent.text = "Lost: R:"+ \
			(if baseColor.r > 0 then (100.0- visibility_r / baseColor.r  * 100.0) as string else "0") + "% G:" + \
			(if baseColor.g > 0 then (100.0- visibility_g / baseColor.g  * 100.0) as string else "0") + "% B:" + \
			(if baseColor.b > 0 then (100.0- visibility_b / baseColor.b  * 100.0) as string else "0") + "%"
		lbl_endColorPercent.text = "Left: R:"+ \
			(if baseColor.r > 0 then (visibility_r / baseColor.r  * 100.0) as string else "100") + "% G:" + \
			(if baseColor.g > 0 then (visibility_g / baseColor.g  * 100.0) as string else "100") + "% B:" + \
			(if baseColor.b > 0 then (visibility_b / baseColor.b  * 100.0) as string else "100") + "%"
		
		copy thePMEBitmap thePMEMasterBitmap
		bmp_PMEdisplay.bitmap = thePMEMasterBitmap
		try(Krakatoa_VFB_Overlay_Rollout.updateAPME())catch()
		FranticParticles.SetProperty "AmbientParticipatingMediumExtinction" (thePME  as string)
		FranticParticles.SetProperty "ExtinctionRed" (spn_ExtinctionRed.value as string)
		FranticParticles.SetProperty "ExtinctionGreen" (spn_ExtinctionGreen.value as string)
		FranticParticles.SetProperty "ExtinctionBlue" (spn_ExtinctionBlue.value as string)
		FranticParticles.SetProperty "ExtinctionStart" (spn_PMEStart.value as string)
		FranticParticles.SetProperty "ExtinctionDistance" (spn_PMEDistance.value as string)
		chk_PMELockSpinners.enabled = spn_ExtinctionBlue.value != 0 and spn_ExtinctionRed.value != 0 and spn_ExtinctionGreen.value != 0 
	)
	
	on clr_PMETarget changed clr do
	(
		unitsMultiplier = case units.SystemType of
		(
			#inches:1
			#millimeters: 25.4
			#centimeters: 2.54
			#meters:0.0254
			#kilometers:0.0000254
			#feet:0.0833333
			#miles:0.0000157828
			default:1
		)		
		result = (getExtinction()) * 10000.0 / 3.53 * unitsMultiplier 
		spn_ExtinctionRed.value = result.x 
		spn_ExtinctionGreen.value = result.y 
		spn_ExtinctionBlue.value = result.z 
		setExtinction()
	)
	
	fn updateFreeMode state =
	(
		if state then 
		(
			spn_ExtinctionRed.range = [-10000.0,10000.0,spn_ExtinctionRed.value]
			spn_ExtinctionGreen.range = [-10000.0,10000.0,spn_ExtinctionGreen.value]
			spn_ExtinctionBlue.range = [-10000.0,10000.0,spn_ExtinctionBlue.value]
			clr_PMETarget.enabled = false
		)
		else
		(
			spn_ExtinctionRed.range = [0.0,10000.0,if spn_ExtinctionRed.value >= 0 then spn_ExtinctionRed.value else 0]
			spn_ExtinctionGreen.range = [0.0,10000.0,if spn_ExtinctionGreen.value >= 0 then spn_ExtinctionGreen.value else 0]
			spn_ExtinctionBlue.range = [0.0,10000.0,if spn_ExtinctionBlue.value >= 0 then spn_ExtinctionBlue.value else 0]
			clr_PMETarget.enabled = true
		)
	)
	
	on chk_PMEfreeMode changed state do
	(
		FranticParticles.SetProperty "PME:FreeMode" (state as string)
		updateFreeMode state
		setExtinction()	
	)		
	on chk_PMEfreeMode rightClick do 
	(
		FranticParticleRenderMXS.createDefaultsRCMenu "PME:FreeMode" "--"
		--popUpMenu Krakatoa_RCMenu_Struct.Presets_RCMenu position:mouse.screenPos		
	)			

	local redToBlueExtFactor
	local greenToBlueExtFactor
	local redToGreenExtFactor

	on chk_PMELockSpinners changed state do
	(
		if spn_ExtinctionBlue.value == 0 or spn_ExtinctionRed.value == 0 or spn_ExtinctionGreen.value == 0 then
		(
			chk_PMELockSpinners.state = false
			chk_PMELockSpinners.enabled = false
		)
		else
		(
			redToBlueExtFactor = spn_ExtinctionRed.value / spn_ExtinctionBlue.value
			greenToBlueExtFactor = spn_ExtinctionGreen.value / spn_ExtinctionBlue.value
		)	
	)
	
	on spn_ExtinctionRed changed val do 
	(
		if chk_PMELockSpinners.checked then
		(
			spn_ExtinctionBlue.value = spn_ExtinctionRed.value / redToBlueExtFactor 
			spn_ExtinctionGreen.value =  spn_ExtinctionBlue.value * greenToBlueExtFactor
		)
		setExtinction()
	)	
	on spn_ExtinctionGreen changed val do 
	(
		if chk_PMELockSpinners.checked then
		(
			spn_ExtinctionBlue.value = spn_ExtinctionGreen.value / greenToBlueExtFactor 
			spn_ExtinctionRed.value = spn_ExtinctionBlue.value * redToBlueExtFactor
		)		
		setExtinction()
	)	
	on spn_ExtinctionBlue changed val do
	(
		if chk_PMELockSpinners.checked then
		(
			spn_ExtinctionGreen.value = spn_ExtinctionBlue.value  * greenToBlueExtFactor
			spn_ExtinctionRed.value = spn_ExtinctionBlue.value * redToBlueExtFactor 
		)		
		setExtinction()
	)	

	on btn_PMEAlignSpinners pressed do
	(		
		spn_ExtinctionRed.value = spn_ExtinctionGreen.value = spn_ExtinctionBlue.value
		greenToBlueExtFactor = redToBlueExtFactor = 1.0
		setExtinction()
	)
	
	
	on spn_PMEStart changed val do setExtinction()
	on spn_PMEDistance changed val do setExtinction()
	on clr_PMEBaseColor changed val do 
	(
		FranticParticles.SetProperty  "PME:ReferenceColor" (val as string)
		setExtinction()	
	)	
	on chk_useAmbientPME changed state do 
	(
		FranticParticles.SetProperty "PME:UseExtinction" (state as string) 
		setExtinction()	
		updateToolbarButtons()
		try(Krakatoa_GUI_Main.refresh_GUI())catch()
		try(Krakatoa_VFB_Overlay_Rollout.Refresh_GUI())catch()
		try(Krakatoa_updateSchematicFlow())catch()
	)	
	
	on chk_useAmbientPME rightClick do 
	(
		FranticParticleRenderMXS.createDefaultsRCMenu "PME:UseExtinction" ">Use APME"
		--popUpMenu Krakatoa_RCMenu_Struct.Presets_RCMenu position:mouse.screenPos		
	)		
	
	on btn_PMEPresets pressed do 
	(
		createPresetsRCMenu()
		popUpMenu Krakatoa_RCMenu_Struct.Presets_RCMenu position:mouse.screenPos
	)
	
	fn refresh_GUI =
	(
		chk_PMEfreeMode.state = (FranticParticles.GetBoolProperty "PME:FreeMode")
		updateFreeMode chk_PMEfreeMode.state 
		spn_ExtinctionRed.value = (FranticParticles.GetFloatProperty "ExtinctionRed") 
		spn_ExtinctionGreen.value = (FranticParticles.GetFloatProperty "ExtinctionGreen") 
		spn_ExtinctionBlue.value = (FranticParticles.GetFloatProperty "ExtinctionBlue") 
		chk_useAmbientPME.state = (FranticParticles.GetBoolProperty "PME:UseExtinction") 
		spn_PMEStart.value = (FranticParticles.GetFloatProperty "ExtinctionStart")
		spn_PMEDistance.value = (FranticParticles.GetFloatProperty "ExtinctionDistance" )
		clr_PMEBaseColor.color = (execute (FranticParticles.GetProperty  "PME:ReferenceColor"))
		
		setExtinction()	
		
		--ddl_PMEMode.selection = FindItem #("raytrace","all") (FranticParticles.GetProperty "PME:CalculationMode")
		updateSelectionSets()
		
		callbacks.removeScripts id:#KrakatoaPMENamedSelectionSetMonitor 
		try --Works only in 3ds Max 9 and higher
		(
			callbacks.addScript #NamedSelSetCreated "try(Krakatoa_GUI_AmbientPME.updateSelectionSets())catch()" id:#KrakatoaPMENamedSelectionSetMonitor 
			callbacks.addScript #NamedSelSetDeleted "try(Krakatoa_GUI_AmbientPME.updateSelectionSets())catch()" id:#KrakatoaPMENamedSelectionSetMonitor 
			callbacks.addScript #NamedSelSetRenamed "try(Krakatoa_GUI_AmbientPME.renamedSelectionSets (callbacks.notificationParam()))catch()" id:#KrakatoaPMENamedSelectionSetMonitor 
		)catch()	
		
		--if Krakatoa_Initializing_Hidden_Rollouts == false do 
		try(Krakatoa_GUI_AmbientPME.open = FranticParticles.GetBoolProperty "GUI:AmbientPMERolloutOpen")catch()
	)
	on Krakatoa_GUI_AmbientPME rolledUp val do 
	(
			FranticParticles.SetProperty "GUI:AmbientPMERolloutOpen" val
			if val then 
				FranticParticles.LogDebug ("+Ambient PME Rollout ROLLED DOWN.")
			else
				FranticParticles.LogDebug ("+Ambient PME Rollout ROLLED UP.")	
	)		

	on Krakatoa_GUI_AmbientPME close do 
	(
		--Called only when in a dialog
		if Krakatoa_GUI_AmbientPME.inDialog and not Krakatoa_Closing_Floater and not Krakatoa_Initializing_Hidden_Rollouts do
		(
			setIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "RolloutVisible" Krakatoa_GUI_AmbientPME.title "false"
			FranticParticleRenderMXS.floatOrDockRollout Krakatoa_GUI_AmbientPME forceMode:#hide
			Krakatoa_CustomizeRollouts_Dialog.Refresh_GUI()
		)	
	)	
	

	fn updateIcons =
	(
		btn_LoadSave_APME.images = #(Krakatoa_PresetsArrowBitmap,Krakatoa_PresetsArrowBitmap, 32,3,3,3,3)		
		btn_Float_Rollout.images = #(Krakatoa_PresetsArrowBitmap,Krakatoa_PresetsArrowBitmap, 32,4,4,4,4)
		btn_PMEPresets.images=#(Krakatoa_PresetsArrowBitmap,Krakatoa_PresetsArrowBitmap, 32,1,1,2,2)
		
		btn_selectionSetAdd.images = #(Krakatoa_PresetsArrowBitmap,Krakatoa_PresetsArrowBitmap, 32,6,6,8,8)
		btn_selectionSetRemove.images = #(Krakatoa_PresetsArrowBitmap,Krakatoa_PresetsArrowBitmap, 32,7,7,9,9)
	)		

	on Krakatoa_GUI_AmbientPME open do 
	(
		updateIcons()
		
		Krakatoa_CustomizeRollouts_Dialog.Refresh_GUI()
		
		Refresh_GUI()
		FranticParticles.LogDebug ("+Ambient PME Rollout OPENED.")			
	)			
)--end rollout

-------------------------------------- 
--ABOUT ROLLOUT	
-------------------------------------- 
rollout Krakatoa_GUI_About "About" rolledup:true category:130 width:540
(
	button btn_Help_About "Open Krakatoa Online Help..." width:530 height:16 offset:[0,-5] align:#center across:1 tooltip:"Opens the Krakatoa Online Help for the About rollout in the default Web Browser. Requires Internet connection."
	on btn_Help_About pressed do shellLaunch "http://www.thinkboxsoftware.com/krak-about" ""		

	on Krakatoa_GUI_About moved pos do
	(
		setIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "RolloutDialogPositions" Krakatoa_GUI_About.title (pos as string)
	)	
	
	imgtag bmp_logo width:530 height:174 style:#bmp_center align:#center --transparent:(color 192 192 192)	 pos:[285,40]
	
	edittext edt_version "" text:"" readonly:true fieldwidth:250 align:#left offset:[-5,-2] across:3
	label lbl_dlrdate "Plug-in DLL Date:" align:#center offset:[60,0]
	edittext edt_dlrdate "" text:"" readonly:true fieldwidth:150 align:#right offset:[1,-2]
	label lbl_installationfolder "Installation Folder:" across:2 align:#left 
	edittext edt_installationfolder "" text:"" readonly:true fieldwidth:415 align:#right offset:[0,-2]
	label lbl_Krakatoa_30 "" align:#left
	
	group ""
	(
			label lbl_url_01 "Thinkbox Website:" across:2 align:#left
			hyperlink url_01 "http://www.thinkboxsoftware.com" address:"http://www.thinkboxsoftware.com/"  align:#left offset:[-100,0]

			label lbl_url_04 "Support Forums:" across:2 align:#left
			hyperlink url_04 "http://forums.thinkboxsoftware.com/" address:"http://forums.thinkboxsoftware.com/"  align:#left  offset:[-100,0]
	)
	label lbl_attributions "3rd Party Software Attributions:" align:#left offset:[0,2] across:2
	button btn_copyattributions "Copy To Clipboard" align:#right height:20 offset:[0,-3]
	dotNetControl dnc_attributions "System.Windows.Forms.TextBox" width:520  height:300 offset:[0,-4] align:#center
	
	
	on btn_copyattributions pressed do 
	(
		dnc_attributions.SelectAll()
		dnc_attributions.Copy()
	)	
	
	fn refresh_GUI = 
	(
		edt_version.text = ("KRAKATOA MX Version " + FranticParticles.Version)
		local maxVer = (((maxVersion())[1]/1000)-2) as string
		if maxVer == "16" do maxVer = "15"			
		if maxVer == "14" do maxVer = "13"			
		edt_installationfolder.text = FranticParticles.KrakatoaHome
		edt_dlrdate.text = try(getFileModDate (FranticParticles.KrakatoaHome + "3dsMax20"+maxVer+"\\MaxKrakatoa.dlr"))catch("???")

		lbl_Krakatoa_30.text = ("")				
		try
		(
			dnc_attributions.multiline = true
			dnc_attributions.AcceptsReturn = false
			dnc_attributions.AcceptsTab = false
			dnc_attributions.WordWrap = false
			dnc_attributions.ScrollBars= dnc_attributions.ScrollBars.Both
			
			local theColor = (colorman.getColor #window) * [255,255,270]
			dnc_attributions.BackColor = dnc_attributions.BackColor.fromARGB theColor.x theColor.y theColor.z

			local theColor = (colorman.getColor #windowtext) * 255
			dnc_attributions.ForeColor = dnc_attributions.ForeColor.fromARGB theColor.x theColor.y theColor.z
			
			local txt = "" as StringStream
			local theAttribFile = openFile (FranticParticles.KrakatoaHome + "\\Legal\\third_party_licenses.txt")
			if theAttribFile != undefined do
			(
				while not eof theAttribFile do
				(
					format "%\r\n" (readLine theAttribFile) to: txt
				)
			)
			close theAttribFile
			dnc_attributions.text = txt as string
		)
		catch
		(
			dnc_attributions.text = "No attributions found in the Legal folder of the Krakatoa installation."
		)
	)
	
	local theLogoBitmap, theLogoBitmap2 
	fn updateLogo theBlue =
	(
		try(
			theLogoBitmap = (openbitmap (FranticParticles.KrakatoaHome +"\\Icons\\Krakatoa_Splash.tga"))
			theBGColor = (colorman.getColor #background)*255
			theForeColor = (white - theBGColor + color 0 0 theBlue) * 0.5
			bmp_logo.bitmap = theLogoBitmap
			theLogoBitmap = undefined
			url_02.color = url_03.color = url_06.color = url_07.color = theForeColor 
			url_02.hoverColor = url_03.hoverColor = url_06.hoverColor = url_07.hoverColor = theForeColor * 1.2
		)	
		catch()		
	)
	
	on Krakatoa_GUI_About rolledUp val do 
	(
		if val then 
		(
			updateLogo 200
			FranticParticles.LogDebug ("+About Rollout ROLLED DOWN.")
		)	
		else
		(
			FranticParticles.LogDebug ("+About Rollout ROLLED UP.")			
		)	
	)	

	on Krakatoa_GUI_About close do 
	(
	)	
	
	fn updateIcons =
	(
	)	

	on Krakatoa_GUI_About open do 
	(
		updateLogo 200
		Refresh_GUI()
		FranticParticles.LogDebug ("+About Rollout OPENED.")			
	)			
)--end rollout


-----------------------------------------------------------------------------------------------------------------------------------------------------------
--Render Scene Dialog Floater - related code starts here
-----------------------------------------------------------------------------------------------------------------------------------------------------------
 
struct FranticParticleRenderMXSStruct (

DeadlineDetected = 0,
tagCounter = 0,
lastFrameRenderStartTime = 0,
lastFrameRenderEndTime = 0,
lastFrameRenderTime = 0,
lockSecondaryToPrimaryFloater = true,
LoadSave_SingleRollout = undefined,
PresetFilterString = "",	
PreChangeRendererInstance = undefined,
theCacheablePropNames = #(
		#("ColorOverride:Enabled", "Override Color"),
		#("ColorOverride:Color", "Color Override Color)"),
		#("ColorOverride:BlendAmount" , "Color Override Map Blend Amount"),
		#("AbsorptionOverride:Enabled" , "Override Absorption"),
		#("AbsorptionOverride:Color","Absorption Override Color"),
		#("AbsorptionOverride:BlendAmount" ,"Absorption Override Map Blend Amount"),
		#("EmissionOverride:Enabled" ,"Override Emission"),
		#("EmissionOverride:Color" ,"Emission Override Color"),
		#("EmissionOverride:BlendAmount","Emission Override Map Blend Amount"),
		#("DensityOverride:Enabled" ,"Override Density"),
		#("DensityOverride:Value","Density Override Color"),
		#("DensityOverride:BlendAmount" ,"Density Override Map Blend Amount"),
		#("RenderParticleFlowGeometry" ,"Use Particle Flow Geometry"),
		#("RenderParticleFlowBBox" ,"Use Particle Flow BBox"),
		#("RenderParticleFlowPhantom" ,"Use Particle Flow Phantom"),
		#("RenderFumeFX" ,"Use FumeFX Simulations"),
		#("RenderPRTHair" ,"Use PRT Hair Objects"),
		#("RenderPRTCreator" ,"Use PRT Maker Objects"),
		#("RenderPRTSource" ,"Use PRT Source Objects"),
		#("RenderMaxParticles" ,"Use 3ds Max Legacy Particle Systems"),
		#("RenderThinkingParticles" ,"Use Thinking Particles Systems"),
		#("RenderGeometryVertices" ,"Use Geometry Vertices As Particles"),
		#("RenderKrakatoaLoaders" ,"Use PRT Loader Objects"),
		#("RenderGeometryVolumes" ,"Use PRT Volume Objects"),
		#("RenderPRTSurface", "Use PRT Surface Objects"),
		#("RenderPhoenixFD", "Use Phoenix FD Objects"),
		#("RenderPRTField", "Use Stoke PRT Field Objects"),
		#("RenderStoke", "Use Stoke Objects"),
		
		#("GlobalParticlePercentage" ,"Global Particle Percentage"),
		#("GlobalDataHolder","Global Channels Override Set")
	),
	
fn postRendererChanged =
(
	if renderers.current.classid as string == "#(-1204370534, -399920359)" or renderers.current.classid as string == "#(3090596762L, 3895046937L)" then
	(
		if not KrakatoaGUIOpeningManually do
			try(FranticParticleRenderMXS.OpenGUI() )catch(messagebox ("Failed To Launch Krakatoa GUI:\n" + getCurrentException()) title:"Krakatoa Error")
	)
	else
	(
		FranticParticleRenderMXS.closerRolloutFloaters debugMessage:"Received #PostRendererChange Notification."
	)
),	
	
fn closerRolloutFloaters debugMessage:"Closed"=
(
	--local wasOpen = try(Krakatoa_Gui_floater.open or Krakatoa_Gui_floater_2.open)catch(false)
	--FranticParticleRenderMXS.PreChangeRendererInstance 
	--if classof renderers.current != Krakatoa then
	(
		try
		(
			closeRolloutFloater Krakatoa_Gui_floater
			FranticParticles.LogDebug (">Krakatoa GUI Floater " + debugMessage)
		)catch()
		try
		(
			closeRolloutFloater Krakatoa_Gui_floater_2
			FranticParticles.LogDebug (">Krakatoa Secondary Floater " + debugMessage)
		)catch()
		try
		(
			closeRolloutFloater Krakatoa_Gui_floater_3
			FranticParticles.LogDebug (">Krakatoa Hidden Floater " + debugMessage)
		)catch()
		try
		(
			closeRolloutFloater Krakatoa_Preferences_Floater
			FranticParticles.LogDebug (">Krakatoa Preferences Floater " + debugMessage)
		)catch()
		try
		(
			closeRolloutFloater Krakatoa_SceneExplorersFloater
			FranticParticles.LogDebug (">Krakatoa Scene Explorers Floater " + debugMessage)
		)catch()		
		for i = ::KrakatoaAtmosphericEffects_DialogsArray.count to 1 by -1 do
			try(destroyDialog ::KrakatoaAtmosphericEffects_DialogsArray[i][2])catch()
			
		FranticParticles.LogWindowVisible = false
		updateToolbarButtons()
	)
	
	--if (classof renderers.current) == Krakatoa and wasOpen do FranticParticleRenderMXS.GlobalRefreshGUI()
	--FranticParticleRenderMXS.OpenGUI()
),	

fn AdjustDialogPositionOnDesktop thePos DialogWidth BottomOffset dialogName:""=
(
	local theDesktop = (dotNetClass "System.Windows.Forms.SystemInformation").VirtualScreen
	if thePos.x > theDesktop.Right - DialogWidth do 
	(
		local newPos = theDesktop.Right - DialogWidth
		FranticParticles.LogDebug ("+Adjusted "+dialogName+" Horizontal Position To Desktop Size ("+(thePos.x as integer) as string+" -> "+ newPos as string +")")
		thePos.x = newPos
	)
	if thePos.x < theDesktop.Left do 
	(
		local newPos = theDesktop.Left
		FranticParticles.LogDebug ("+Adjusted "+dialogName+" Horizontal Position To Desktop Size ("+(thePos.x as integer) as string+" -> "+ newPos as string +")")
		thePos.x = newPos
	)
	if thePos.y > theDesktop.Bottom - BottomOffset do 
	(
		local newPos = theDesktop.Bottom - BottomOffset
		FranticParticles.LogDebug ("+Adjusted "+dialogName+" Vertical Position To Desktop Size ("+(thePos.y as integer) as string+" -> "+ newPos as string +")")
		thePos.y = newPos
	)	
	if thePos.y < theDesktop.Top do 
	(
		local newPos = theDesktop.Top
		FranticParticles.LogDebug ("+Adjusted "+dialogName+" Vertical Position To Desktop Size ("+(thePos.y as integer) as string+" -> "+ newPos as string +")")
		thePos.y = newPos
	)
	thePos
),

fn isGeoVolume obj =
(
	classof obj.baseobject == PRT_Volume
),

fn isGeoSurface obj =
(
	classof obj.baseobject == PRT_Surface
),

fn isPRTLoader obj =
(
	classof obj.baseobject == KrakatoaPRTLoader
),

fn getGeoVolumeEstimatedCount PRTobj=
(
	try(
		local obj = PRTobj.targetNode
		local theVolumeCount = "???"
		if isValidNode obj do
		(
			local theTM = (inverse obj.transform) 
			local theMin = (nodeLocalBoundingBox obj)[1] * theTM 
			local theMax = (nodeLocalBoundingBox obj)[2] * theTM
			local theBox = theMax-theMin
			local theSize = theBox / obj.VoxelLength 
			local theMaxCount = (floor (theSize.x+0.5) * floor (theSize.y+0.5) * floor (theSize.z+0.5) ) as integer
			local theMeshVolume = FranticParticleRenderMXS.CalculateVolume obj
			local theBoxVolume = theBox.x * theBox.y * theBox.z
			theVolumeCount = (theMaxCount * (theMeshVolume / abs theBoxVolume)) as integer
			FranticParticleRenderMXS.addCommas (theVolumeCount as string)
		)	
	)catch("???")	
),

fn DetectDeadline timeout:5000 forceloading:false = 
(
	global Krakatoa_LoadingDeadline_Rollout
	try(destroyDialog Krakatoa_LoadingDeadline_Rollout)catch()
	rollout Krakatoa_LoadingDeadline_Rollout "Krakatoa - Deadline Integration..."
	(
		label lbl_progress "Checking For Deadline, Please Wait..."
	)
	
	FranticParticles.LogProgress ">Detecting Deadline Render Manager..."
	FranticParticleRenderMXS.DeadlineDetected = 0

	local KrakatoaPreferencesINI = (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini" )
	local theDetectValue = getIniSetting KrakatoaPreferencesINI "Deadline" "DetectDeadline"
	if theDetectValue == "2" do theDetectValue = "3" --older versions of Krakatoa supported Deadline 2.6+. This one does not.
	if theDetectValue == "" do theDetectValue == "1"
	
	if theDetectValue == "1" do --if Deadline detection was explicitly disabled, return without checking.
	(
		FranticParticles.LogWarning "  -Deadline Support is Explicitly DISABLED. Use the drop-down list under Partitioning to change..."
		try(destroyDialog Krakatoa_LoadingDeadline_Rollout)catch()
		return false
	)	
	
	--If Deadline functionality is already loaded in Max, figure out which version it was without reloading and if it was the one we wanted:
	if forceloading == false and SMTDPaths != undefined then 
	(
		if isProperty SMTDPaths #HomeDir and theDetectValue == "3" do
		(
			FranticParticles.LogProgress "  +Submit Max To Deadline Functions ALREADY LOADED!"
			FranticParticleRenderMXS.DeadlineDetected = 3
			try(destroyDialog Krakatoa_LoadingDeadline_Rollout)catch()
			return true	
		)	
		if not isProperty SMTDPaths #HomeDir do
		(
			FranticParticles.LogError "  -Submit Max To Deadline Functions 2.x detected but NOT SUPPORTED!"
			FranticParticleRenderMXS.DeadlineDetected = 2
			try(destroyDialog Krakatoa_LoadingDeadline_Rollout)catch()
			return false 
		)
		forceloading = true
	)
	try(destroyDialog SMTD_MainRollout)catch() --close the SMTD Dialog if open
	createDialog Krakatoa_LoadingDeadline_Rollout 400 25
	Krakatoa_LoadingDeadline_Rollout.lbl_progress.text = "Detecting Deadline Render Manager. This might take a while...."
	
	if theDetectValue == "" or theDetectValue == "3" do
	(
		--Try to detect Deadline 3.x 
		try(
			Krakatoa_LoadingDeadline_Rollout.lbl_progress.text = "Looking for Deadline Render Manager. This might take a while..."
			local result = -2
				
			local submitOutputFile = sysInfo.tempdir + "submitOutput.txt"
			local submitExitCodeFile = sysInfo.tempdir + "submitExitCode.txt"
			
			deleteFile submitOutputFile
			deleteFile submitExitCodeFile
					
			local deadlinePath = ""
			local sysEnvDotNet = dotNetClass "System.Environment"
			local deadlinePathEnvVar = sysEnvDotNet.GetEnvironmentVariable("DEADLINE_PATH")
			if deadlinePathEnvVar != undefined and deadlinePathEnvVar != "" then (
				deadlinePath = deadlinePathEnvVar
				local endingChar = substring deadlinePath (deadlinePath.count) 1
				if endingChar != "\\" and endingChar != "/" then
					deadlinePath = deadlinePath + "\\"
			)
			
			local deadlineCommandStr = "\"" + deadlinePath + "deadlinecommandbg.exe\""
			local commandArguments = "-outputfiles \"" + submitOutputFile + "\" \"" + submitExitCodeFile + "\" -getrepositoryroot"
			
			ShellLaunch deadlineCommandStr commandArguments
					
			local startTimeStamp = timestamp()
			local ready = false
			while not ready do
			(
				sleep 0.15
				if doesFileExist submitExitCodeFile do
				(
					local theFile = openFile submitExitCodeFile
					try
					(
						result = readValue theFile
					)
					catch
					(
						FranticParticles.LogWarning "  -Error reading the Exit Code File of DeadlineCommandBg.exe!"
						result = -2
					)
					try(close theFile)catch()
					ready = true
				)	
				if timestamp() - startTimeStamp > timeout then 
				(
					result = -3
					FranticParticles.LogWarning "  -Call to DeadlineCommandBg.exe timed out. The PATH to Deadline binary folder might not be set or Deadline might not be installed correctly."
					ready = true
				)	
			)
			
			if result == 0 then
			(
				local resultFile = OpenFile submitOutputFile
				local resultMsg = ""
				if (resultFile != undefined) do
				(
					try(resultMsg = readLine resultFile)catch()
					try(close resultFile)catch()
				)
				local deadlineRoot = resultMsg
				FranticParticles.LogProgress "  +Deadline Render Manager DETECTED on your system!"
				FranticParticles.LogProgress ("  +Repository found at ["+deadlineRoot+"]")
				
				Krakatoa_LoadingDeadline_Rollout.lbl_progress.text = "Deadline DETECTED, Loading Functions and Settings..."
				if SMTDPaths == undefined or SMTDSettings == undefined or SMTDFunctions == undefined or forceloading==true or theDetectValue == "" then 
				(
					local deadlineSubmitFunctions = deadlineRoot + "\\submission\\3dsmax\\Main\\SubmitMaxToDeadline_Functions.ms"
					if not doesFileExist deadlineSubmitFunctions  do deadlineSubmitFunctions = deadlineRoot + "\\submission\\3dsmax\\SubmitMaxToDeadline_Functions.ms"
					if deadlineRoot != "" and (doesFileExist deadlineSubmitFunctions) then 
					(
						setIniSetting (Krakatoa_PresetsDirectory + "//KrakatoaPreferences.ini") "Deadline" "LastRepositoryPath" deadlineRoot
						try(
							local st = timestamp()
							local theTarget = (GetDir #userscripts + "\\" + filenameFrompath deadlineSubmitFunctions)
							FranticParticles.LogDebug ("  >About to check File Info of file ["+deadlineSubmitFunctions+"]")
							local theInfo1 = FranticParticleRenderMXS.getFileInfoDotNet deadlineSubmitFunctions
							FranticParticles.LogDebug ("  +FileInfo1=" + theInfo1 as string)
							local theInfo2 = #("","","")
							if doesFileExist theTarget do 
							(
								FranticParticles.LogDebug (">About to check File Info of file ["+theTarget+"]")
								theInfo2 = FranticParticleRenderMXS.getFileInfoDotNet theTarget							
							)
							FranticParticles.LogDebug ("  +FileInfo2=" + theInfo2 as string)
							if theInfo1[2] != theInfo2[2] or theInfo1[3] != theInfo2[3] then
							(
								FranticParticles.LogDebug ("  --Repository and Local Function files did not match!")
								deleteFile theTarget
								copyFile deadlineSubmitFunctions theTarget
								fileIn theTarget quiet:true				
								FranticParticles.LogProgress ("  +COPIED latest Submit Max To Deadline Functions from Deadline Repository." )
							)
							else
							(
								FranticParticles.LogDebug ("  >About to load local copy...")
								fileIn theTarget quiet:true	
								FranticParticles.LogProgress ("  +FOUND a local up-to-date copy of Submit Max To Deadline Functions file." )
							)
							SMTDFunctions.loadSettings()
							FranticParticleRenderMXS.DeadlineDetected = 3
							FranticParticles.LogProgress ("  +LOADED Submit Max To Deadline Functions in " + (timestamp()-st) as string + "ms." )
							if theDetectValue == "" do 
							(
								setIniSetting KrakatoaPreferencesINI "Deadline" "DetectDeadline" "3"
								theDetectValue = "3"
								FranticParticles.LogProgress "  +Loading Deadline set as DEFAULT Preference!"	
							)	
						)catch FranticParticles.LogError "  -FAILED to load Submit Max To Deadline Functions!"
					) 
				) 
				else 
					FranticParticles.LogProgress "  +Deadline Functions Already Loaded!"
			)
		)catch(FranticParticles.LogError "  -Unable To Detect Deadline!")
	)--end if search for Deadline 3.0
	
	if FranticParticleRenderMXS.DeadlineDetected < 3 then
		FranticParticles.LogWarning "  -FAILED to Detect a supported version (3, 4 or higher) of Deadline Render Manager."
	try(destroyDialog Krakatoa_LoadingDeadline_Rollout)catch()
),

fn LeadingZeros value count =
(
	local theStr = value as string
	local theCount = count-(theStr.count)
	if theCount < 1 then "" else substring "00000000000" 1 theCount
),

fn addCommas txt =
(
	if matchPattern txt pattern:"*L" do txt = substring txt 1 (txt.count-1)
	if matchPattern txt pattern:"*P" do txt = substring txt 1 (txt.count-1)
	theDot = findString txt "."
	if theDot == undefined then 
	(
		newTxt = "" 
		
		theDot = txt.count
	)	
	else 
	(
		newTxt = substring txt theDot -1
		theDot -= 1
	)
	cnt = 0
	for i = theDot to 1 by -1 do
	(
		cnt +=1
		newTxt = txt[i] + newTxt
		if cnt == 3 and i > 1 and txt[i-1] != "-" do 
		(
			newTxt = "," + newTxt
			cnt = 0
		)	
	)
	newTxt
),

fn CalculateVolume obj = 
( 
	local Volume= 0.0 
	local Center= [0.0, 0.0, 0.0] 
	local theMesh = snapshotasmesh obj
	local numFaces = theMesh.numfaces 
	for i = 1 to numFaces do 
	( 
	local Face= getFace theMesh i 
	local vert2 = getVert theMesh Face.z 
	local vert1 = getVert theMesh Face.y 
	local vert0 = getVert theMesh Face.x 
	local dV = Dot (Cross (vert1 - vert0) (vert2 - vert0)) vert0
	Volume+= dV 
	Center+= (vert0 + vert1 + vert2) * dV 
	) 
	delete theMesh
	Volume /= 6 
),

fn convertToHMS theTimeInSec precision:#integer =
(
	theHours = (floor (theTimeInSec/3600) ) as integer
	theMinutes = (floor ((theTimeInSec- theHours*3600)/60) as integer)
	if precision == #integer then
		theSeconds = (theTimeInSec - theHours*3600 - theMinutes * 60) as integer
	else
		theSeconds = (theTimeInSec - theHours*3600 - theMinutes * 60) 
	theHoursString = theHours as string
	if theHoursString.count == 1 do theHoursString = "0" + theHoursString 
	theMinutesString = theMinutes as string
	if theMinutesString .count == 1 do theMinutesString = "0" + theMinutesString 
	theSecondsString = theSeconds as string
	if theSecondsString .count == 1 do theSecondsString = "0" + theSecondsString 
	theHoursString + ":" + theMinutesString + ":" + theSecondsString 
),

------------------------------------------
--REFRESH ALL UI CONTROLS IN ALL ROLLOUTS
------------------------------------------
fn GlobalRefreshGUI = (
	FranticParticles.LogDebug ">Global Refresh GUI Called..."
	if Krakatoa_Gui_floater != undefined and Krakatoa_Gui_floater.open then 
	(
		try(Krakatoa_GUI_Presets.refresh_GUI())catch()
		try(Krakatoa_GUI_Channels.refresh_GUI())catch()
		try(Krakatoa_GUI_ThinkingParticles.refresh_GUI())catch()
		try(Krakatoa_GUI_Partition.refresh_GUI())catch()
		try(Krakatoa_GUI_ParticleLoaders.refresh_GUI())catch()
		try(Krakatoa_GUI_MatteObjects.refresh_GUI())catch()
		try(Krakatoa_GUI_Preferences.refresh_GUI())catch()
		try(Krakatoa_GUI_Preferences_Colors.refresh_GUI())catch()
		try(Krakatoa_GUI_KSRExporter_Preferences.refresh_GUI())catch()
		try(Krakatoa_GUI_Particles.refresh_GUI())catch()
		try(Krakatoa_GUI_Notes.refresh_GUI())catch()
		try(Krakatoa_GUI_About.refresh_GUI())catch()
		try(Krakatoa_GUI_AmbientPME.refresh_GUI())catch()
		try(Krakatoa_GUI_Main.refresh_GUI())catch()
		try(FranticParticleRenderMXS.defineShaderRollout (FranticParticles.GetProperty "PhaseFunction"))catch()
		--Krakatoa_GUI_Main.scrollPos = 0
		FranticParticles.LogDebug "  +Global Refresh GUI Finished."
	)
	else
		FranticParticles.LogDebug "  -No Refresh - GUI Floater Not Open."
),

fn OpenKrakatoaAtmosphericDialog arg =
(
	global KrakatoaAtmosphericEffect_CurrentEffect = arg
	fileIn (FranticParticles.KrakatoaHome + "scripts\\KrakatoaAtmosphericUI.ms")
),

fn OpenSpecificLightRenderElementOptionsRCMenu arg =
(
	Krakatoa_RCMenu_Struct.SpecificLightRenderElement_CurrentElement = arg
	popupMenu Krakatoa_RCMenu_Struct.SpecificLightRenderElement_Options_RCMenu pos:mouse.screenpos 
),

fn OpenPRTVolumeOptionsRCMenu =
(
	try(Krakatoa_RCMenu_Struct.PRTVolume_Options_RCMenu.volumeObject_select.text = "SELECT ["+selection[1].TargetNode.name+"] Volume Object...")catch()
	--try(Krakatoa_RCMenu_Struct.PRTVolume_Options_RCMenu.volumeObject_setName.text = "Set PRT Volume's Name To [" + uniquename ("PRTVolume_"+selection[1].TargetNode.name+"_") + "]")catch()
	try(
		local theBBox = selection[1].TargetNode.max-selection[1].TargetNode.min
		local theMaxSize = amax #(theBBox.x, theBBox.y, theBBox.z)			
		local theSpacingFactor = execute (getIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "Preferences" "PRTVolumeSpacingFactor")
		if theSpacingFactor == OK do theSpacingFactor = 50.0				
		Krakatoa_RCMenu_Struct.PRTVolume_Options_RCMenu.volumeObject_setViewportSpacing.text = "Set Viewport Spacing To ["+(theMaxSize/theSpacingFactor) as string+"] Based On Volume Object's Size" 
	)catch()
	popupMenu Krakatoa_RCMenu_Struct.PRTVolume_Options_RCMenu pos:mouse.screenpos 
),

fn OpenPRTSurfaceOptionsRCMenu =
(
	--try(Krakatoa_RCMenu_Struct.PRTSurface_Options_RCMenu.surfaceObject_select.text = "Select ["+selection[1].TargetNode.name+"] Volume Object...")catch()
	--try(Krakatoa_RCMenu_Struct.PRTVolume_Options_RCMenu.volumeObject_setName.text = "Set PRT Volume's Name To [" + uniquename ("PRTVolume_"+selection[1].TargetNode.name+"_") + "]")catch()
	popupMenu Krakatoa_RCMenu_Struct.PRTSurface_Options_RCMenu pos:mouse.screenpos 	
),

fn OpenPRTFumeFXOptionsRCMenu =
(
	try(Krakatoa_RCMenu_Struct.PRTFumeFX_Options_RCMenu.fumeObject_select.text = "SELECT ["+selection[1].TargetNode.name+"] FumeFX Source...")catch()
	popupMenu Krakatoa_RCMenu_Struct.PRTFumeFX_Options_RCMenu pos:mouse.screenpos 	
),

fn OpenPRTSourceOptionsRCMenu =
(
	try(Krakatoa_RCMenu_Struct.PRTSource_Options_RCMenu.targetObject_select.text = "SELECT ["+selection[1].TargetNode.name+"] Source Object...")catch()
	popupMenu Krakatoa_RCMenu_Struct.PRTSource_Options_RCMenu pos:mouse.screenpos 		
),

fn OpenPRTHairOptionsRCMenu =
(
	try(Krakatoa_RCMenu_Struct.PRTHair_Options_RCMenu.Object_select.text = "SELECT ["+selection[1].TargetNode.name+"] Source Object...")catch()
	popupMenu Krakatoa_RCMenu_Struct.PRTHair_Options_RCMenu pos:mouse.screenpos 		
),

fn PRTVolumeObjectSetupOnPick =
(
	local theVolume = (for i in selection where classof i == PRT_Volume collect i)[1]
	if theVolume != undefined do
	(
		local theBBox = theVolume.TargetNode.max-theVolume.TargetNode.min
		local theMaxSize = amax #(theBBox.x, theBBox.y, theBBox.z)
		local theSpacingFactor = execute (getIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "Preferences" "PRTVolumeSpacingFactor")
		if theSpacingFactor == OK do theSpacingFactor = 50.0				
		theVolume.ViewportVoxelLength = theMaxSize/theSpacingFactor
		theVolume.wirecolor = theVolume.TargetNode.wirecolor
		if theVolume.material == undefined do theVolume.material = theVolume.TargetNode.material
		--newVolume.name = uniquename ("PRTVolume_" + theVolume.TargetNode.name + "_")
		local thePref = getIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "Preferences" "CreatePRTVolumeBehavior"
		case thePref of
		(
			default: () --do nothing, option 5
			"1" : (theVolume.TargetNode.renderable = false)
			"2" : (theVolume.TargetNode.boxMode = true)
			"3" : (theVolume.TargetNode.boxMode = true; theVolume.TargetNode.renderable = false)
			"4" : (hide theVolume.TargetNode)
		)
	)	
),

fn storeCacheableSettings =
(
	local tempArray = #()
	for i in theCacheablePropNames do
		append tempArray (FranticParticles.getProperty i[1])
	tempArray 
),

fn getChangedCacheableProperties =
(
	local currentSettings = FranticParticleRenderMXS.storeCacheableSettings()
	local changedSettings = #()
	if ::KrakatoaPostRenderCacheableSettings != undefined do
	(
		for i = 1 to currentSettings.count do 
		(
			try(
				if (currentSettings[i] as string != ::KrakatoaPostRenderCacheableSettings[i] as string) do
				(
					append changedSettings ("["+ theCacheablePropNames[i][2] + "] changed from ["+::KrakatoaPostRenderCacheableSettings[i] as string +"] to [" + currentSettings[i] as string +"].")
				)
			)catch()
		)
	)
	changedSettings
),

fn SettingsUnmodifiedSinceCacheCreation =
(
	with printAllElements on ((FranticParticleRenderMXS.storeCacheableSettings() as string) == KrakatoaPostRenderCacheableSettings as string)
),

KrakatoaPropertiesList = #(
	--#(1:Property Name, 2:default, 3: store defaults, 4: obsolete)
	#("RenderingMethod", "Particle Rendering", true, false),
	
	#("IterativeRender", "false", true, false),
	#("IterativeRender:ScaleFactor", "1", true, false),
	#("UseLighting", "true", false, true), --FIXME: Temporary leftover for backwards compatibility

	#("IgnoreSceneLights", "false", true, false),
	#("BackgroundColor", "(color 0 0 0 0)", true, false),
	#("UseEnvironmentColor", "true"	, true, false),
	#("UseEnvironmentReflections", "false"	, true, false),
	#("EnvironmentReflectionStrength", "1.0", true, false),
	#("UseFilterColor", "false", true, false),
	#("UseEmissionColor", "false", true, false),
	--#("UseScatterColor", "true", true, false),
	#("AdditiveMode", "false", true, false),

	#("ColorOverride:Enabled", "false", true, false),
	#("ColorOverride:Color", "(color 255 255 255)", true, false),
	#("ColorOverride:BlendAmount", "100.0", true, false),
	#("AbsorptionOverride:Enabled", "false", true, false),
	#("AbsorptionOverride:Color", "(color 0 0 0)", true, false),
	#("AbsorptionOverride:BlendAmount", "100.0", true, false),
	#("EmissionOverride:Enabled", "false", true, false),
	#("EmissionOverride:Color", "(color 255 255 255)", true, false),
	#("EmissionOverride:BlendAmount", "100.0", true, false),
	
	#("DensityOverride:Value", "1.0", true, false),
	#("DensityOverride:Enabled", "false", true, false),
	#("DensityOverride:BlendAmount", "100.0", true, false),

	#("PostDivideByAlpha", "false", true, false),
	
	#("Density:RelativeLightingDensity", "false", true, false),
	
	#("Density:LinkLightingAndRenderingDensity", "true", true, false),
	#("Density:DensityMethod", "Volumetric Density", false, true), --For Backwards Compatibility
	#("DensityScalingSource", "Material Opacity", false, true),  --FIXME: Should be removed
	#("Density:DensityPerParticle", "5", true, false),
	#("Density:DensityExponent", "-1" , true, false),
	#("Emission:Strength", "1", true, false),
	#("Emission:StrengthExponent", "0" , true, false),
	#("Emission:UseStrength", "false", true, false),
	#("Emission:UseRelativeStrength", "false", true, false),
	#("Emission:RelativeStrength", "1", true, false),
	#("Emission:RelativeStrengthExponent", "0", true, false),
	
	#("Lighting:Density:DensityMethod", "Volumetric Density", false, true),  --For Backwards Compatibility
	#("Lighting:Density:DensityPerParticle", "5", true, false),
	#("Lighting:Density:DensityExponent", "-1", true, false),
	#("Lighting:Density:RelativeDensityPerParticle", "1", true, false),
	#("Lighting:Density:RelativeDensityExponent", "0", true, false),	

	#("VoxelSize", "0.5", true, false),
	#("VoxelFilterRadius", "1", true, false),
	#("Voxel:NumDensitySamples", "2", true, false),
	#("Voxel:NumLightSamples", "2", true, false), --OBSOLETE?
	#("PhaseFunction", "Isotropic", true, false),
	#("PhaseEccentricity", "0", true, false),
	
	#("UseDepthMaps", "true", false, true), --OBSOLETE, backwards compatibility to 1.1.x
	#("DrawPointFilter", "Bilinear" , true, false),
	#("AttenuationLookupFilter", "Bicubic" , true, false),
	#("SortingThreads", "0" , true, true), --OBSOLETE
	
	#("Performance:MT:Loading", "false", false, false),
	#("Performance:MT:Sorting", "true", false, false),
	#("Performance:MT:Lighting", "true", false, false),
	#("Performance:MT:Drawing", "true", false, false),	
	#("RenderThreadLimit", "0", false, false),		
	#("FrameBufferAvailPhysMemoryFraction", "0.7", false, false),	

	#("EnableMotionBlur", "false", true, false),
	#("EnableDepthOfField", "false", true, false),
	#("Channel:Allocate:BokehBlendInfluence", "false", true, false),
	#("EnableAttenuationMapSaving", "false", true, false),
	
	#("MotionBlurSegments", "2", true, false),
	#("JitteredMotionBlur", "false", true, false),
	#("DeformationMotionBlur", "false", true, false),
	#("MatteMotionBlurSegments", "1", true, false),
	#("UseMatteMotionBlurSegments", "false", true, false),
	#("DisableCameraMotionBlur", "false", true, false),
	
	
	#("EnableAdaptiveMotionBlur", "false", true, false),
	#("AdaptiveMotionBlurSegmentLowerBound", "2", true, false),
	#("AdaptiveMotionBlurSegmentUpperBound", "64", true, false),
	#("AdaptiveMotionBlurSmoothness", "1.0", true, false),
	#("AdaptiveMotionBlurExponent", "1.0", true, false),
	
	
	#("ShutterAngleInDegrees", "180", true, false),
	#("ShutterBias", "0", true, false),
	#("DepthOfFieldSampleRate", "0.1" , true, false), 

	#("IgnoreMissingParticles", "false", true, false),
	#("AllowPRTLoaderOverwriting", "false", true, false),

	#("RenderParticleFlowGeometry", "true", true, false),
	#("RenderParticleFlowBBox", "false", true, false),
	#("RenderParticleFlowPhantom", "true", true, false),
	#("RenderFumeFX", "true", true, false),
	#("RenderPRTHair", "true", true, false),
	#("RenderPRTCreator", "true", true, false),
	#("RenderPRTSource", "true", true, false),
	
	#("RenderMaxParticles", "true", true, false),
	#("RenderThinkingParticles", "false", true, false),
	#("RenderGeometryVertices", "false", true, false),
	#("RenderKrakatoaLoaders", "true", true, false),
	#("RenderGeometryVolumes", "true", true, false),
	#("RenderPRTSurface", "true", true, false),
	#("RenderPhoenixFD", "true", true, false),
	#("RenderPRTField", "true", true, false),
	#("RenderStoke", "true", true, false),
	
	#("GlobalParticlePercentage", "100.0", true, false),
	
	#("UseGlobalDataHolder", "true", false, true), --OBSOLETE
	#("GlobalDataHolder", "", true, false),
	
	#("Lighting:Specular:SpecularPower", "10.0", true, false),
	#("Lighting:Specular:Level", "100.0", true, false),

	#("Channel:Allocate:SpecularPower", "false", true, false),
	#("Channel:Allocate:SpecularLevel", "false", true, false),
	#("Channel:Allocate:PhaseEccentricity", "false", true, false),

	#("Channel:Allocate:ReflectionStrength", "false", true, false),

	#("Lighting:Specular:Anisotropy", "0.0", false, true), --OBSOLETE
	#("Lighting:Reflectance:Level", "100.0", false, true),  --OBSOLETE
	
	#("EnableParticleCache", "false" , true, false),
	#("EnableLightingCache", "false", true, false),
	#("CacheLastFrame", "true", true, false),
	#("UseCacheInWorkerMode", "false", true, false),
	
	-- Settings for Particle Data	
	#("ParticleMode", "Render Scene Particles", true, false),
	#("ParticleFiles", "", true, false),
	
	#("ParticleFilesBase", "", false, false),
	#("ParticleFilesProject", "",false, false),
	#("ParticleFilesSequence", "",false, false),
	#("ParticleFilesTake", "",false, false),
	#("ParticleFilesName", "",false, false),
	
	-- Settings for Particle Partitioning
	#("Partition:Count", "10", true, false),
	#("Partition:IncrementPositionRandomSeeds", "true", true, false),
	#("Partition:IncrementSpawnRandomSeeds", "true", true, false),
	#("Partition:IncrementSpeedRandomSeeds", "true", true, false),
	#("Partition:IncrementRotationRandomSeeds", "true", true, false),
	
	#("Partition:IncrementFumeFXRandomSeeds", "true", true, false),
	#("Partition:IncrementOtherRandomSeeds", "true", true, false),
	#("Partition:IncrementLegacyRandomSeeds", "true", true, false),
	#("Partition:IncrementThinkingRandomSeeds", "true", true, false),

	#("Partition:IncrementBox3Geometry", "true", true, false),
	#("Partition:IncrementBox3Random", "true", true, false),
	#("Partition:IncrementBox3ScalarVector", "true", true, false),
	#("Partition:IncrementBox3Icon", "true", true, false),
	
	#("Partition:IncrementPRTModifiers", "false", true, false),
	#("Partition:IncrementPRTVolumeModifiers", "false", true, false),
	#("Partition:IncrementPRTFumeFXModifiers", "false", true, false),
	
	#("Partition:IncrementGeometryModifiers", "false", true, false),
	
	#("Partition:IncrementBox3DiskCacheNames", "false", true, false),
	
	#("Partition:AffectSeedsInObjects", "#()", true, false),
	#("Partition:IncrementSelectedOnly", "false", true, false),
	--#("Partition:skipExistingFiles", "false"	, true, false),
	#("Partition:BackupRootMode", "1"	, true, false),
	#("Partition:BackupRoot", ""	, true, false),
	
	#("SkipExistingParticleFiles", "false", true, false),
		
	--Channels
	#("Memory:Channel:Velocity", "float16", true, false),
	#("Memory:Channel:Color", "float16", true, false),
	#("Memory:Channel:Density", "float16", true, false),
	#("Memory:Channel:Normal", "float16", true, false),
	#("Memory:Channel:Tangent", "float16", true, false),
	#("Memory:Channel:Lighting", "float16", true, false),
	#("Memory:Channel:Absorption", "float16", true, false),
	#("Memory:Channel:Emission", "float16", true, false),
	#("Memory:Channel:MBlurTime", "float16", true, false),
	
	#("Memory:Channel:SpecularPower", "float16", true, false),
	#("Memory:Channel:SpecularLevel", "float16", true, false),
	#("Memory:Channel:PhaseEccentricity", "float16", true, false),
	
	#("Memory:Channel:SpecularGlossiness", "float16", true, false),
	#("Memory:Channel:SpecularShift", "float16", true, false),
	#("Memory:Channel:Specular2Level", "float16", true, false),
	#("Memory:Channel:Specular2Glossiness", "float16", true, false),
	#("Memory:Channel:Specular2Shift", "float16", true, false),
	#("Memory:Channel:GlintLevel", "float16", true, false),
	#("Memory:Channel:GlintSize", "float16", true, false),
	#("Memory:Channel:GlintGlossiness", "float16", true, false),
	#("Memory:Channel:DiffuseLevel", "float16", true, false),
	#("Memory:Channel:__Element_Diffuse", "float16", true, false),
	#("Memory:Channel:__Element_Specular", "float16", true, false),
	
	#("Memory:Channel:TextureCoord", "float16", true, false),
	#("Memory:Channel:MXSVector", "float16", true, false),
	#("Memory:Channel:MXSFloat", "float16", true, false),
	#("Memory:Channel:MXSInteger", "int16", true, false),
	#("Memory:Channel:Scale", "float16", true, false),
	#("Memory:Channel:Acceleration", "float16", true, false),
	#("Memory:Channel:DensityGradient", "float16", true, false),
	#("Memory:Channel:SignedDistance", "float16", true, false),

	#("Memory:Channel:Fire", "float16", true, false),
	#("Memory:Channel:Fuel", "float16", true, false),
	#("Memory:Channel:Temperature", "float16", true, false),
	#("Memory:Channel:Age", "float32", true, false),
	#("Memory:Channel:LifeSpan", "float32", true, false),
	#("Memory:Channel:ID", "int32", true, false),
	#("Memory:Channel:MtlIndex", "int16", true, false),
	
	#("Memory:Channel:Mapping2", "float16", true, false),	
	#("Memory:Channel:Mapping3", "float16", true, false),	
	#("Memory:Channel:Mapping4", "float16", true, false),	
	#("Memory:Channel:Mapping5", "float16", true, false),	
	#("Memory:Channel:Mapping6", "float16", true, false),	
	#("Memory:Channel:Mapping7", "float16", true, false),	
	#("Memory:Channel:Mapping8", "float16", true, false),	
	#("Memory:Channel:Mapping9", "float16", true, false),	
	#("Memory:Channel:Mapping10", "float16", true, false),	
	
	#("Memory:Channel:Mapping11", "float16", true, false),	
	#("Memory:Channel:Mapping12", "float16", true, false),	
	#("Memory:Channel:Mapping13", "float16", true, false),	
	#("Memory:Channel:Mapping14", "float16", true, false),	
	#("Memory:Channel:Mapping15", "float16", true, false),	
	#("Memory:Channel:Mapping16", "float16", true, false),	
	#("Memory:Channel:Mapping17", "float16", true, false),	
	#("Memory:Channel:Mapping18", "float16", true, false),	
	#("Memory:Channel:Mapping19", "float16", true, false),		
	#("Memory:Channel:Mapping20", "float16", true, false),	

	#("Memory:Channel:Mapping21", "float16", true, false),	
	#("Memory:Channel:Mapping22", "float16", true, false),	
	#("Memory:Channel:Mapping23", "float16", true, false),	
	#("Memory:Channel:Mapping24", "float16", true, false),	
	#("Memory:Channel:Mapping25", "float16", true, false),	
	#("Memory:Channel:Mapping26", "float16", true, false),	
	#("Memory:Channel:Mapping27", "float16", true, false),	
	#("Memory:Channel:Mapping28", "float16", true, false),	
	#("Memory:Channel:Mapping29", "float16", true, false),		
	#("Memory:Channel:Mapping30", "float16", true, false),	

	#("Memory:Channel:Mapping31", "float16", true, false),	
	#("Memory:Channel:Mapping32", "float16", true, false),	
	#("Memory:Channel:Mapping33", "float16", true, false),	
	#("Memory:Channel:Mapping34", "float16", true, false),	
	#("Memory:Channel:Mapping35", "float16", true, false),	
	#("Memory:Channel:Mapping36", "float16", true, false),	
	#("Memory:Channel:Mapping37", "float16", true, false),	
	#("Memory:Channel:Mapping38", "float16", true, false),	
	#("Memory:Channel:Mapping39", "float16", true, false),		
	#("Memory:Channel:Mapping40", "float16", true, false),	

	#("Memory:Channel:Mapping41", "float16", true, false),	
	#("Memory:Channel:Mapping42", "float16", true, false),	
	#("Memory:Channel:Mapping43", "float16", true, false),	
	#("Memory:Channel:Mapping44", "float16", true, false),	
	#("Memory:Channel:Mapping45", "float16", true, false),	
	#("Memory:Channel:Mapping46", "float16", true, false),	
	#("Memory:Channel:Mapping47", "float16", true, false),	
	#("Memory:Channel:Mapping48", "float16", true, false),	
	#("Memory:Channel:Mapping49", "float16", true, false),		
	#("Memory:Channel:Mapping50", "float16", true, false),	

	#("Memory:Channel:Mapping51", "float16", true, false),	
	#("Memory:Channel:Mapping52", "float16", true, false),	
	#("Memory:Channel:Mapping53", "float16", true, false),	
	#("Memory:Channel:Mapping54", "float16", true, false),	
	#("Memory:Channel:Mapping55", "float16", true, false),	
	#("Memory:Channel:Mapping56", "float16", true, false),	
	#("Memory:Channel:Mapping57", "float16", true, false),	
	#("Memory:Channel:Mapping58", "float16", true, false),	
	#("Memory:Channel:Mapping59", "float16", true, false),		
	#("Memory:Channel:Mapping60", "float16", true, false),	

	#("Memory:Channel:Mapping61", "float16", true, false),	
	#("Memory:Channel:Mapping62", "float16", true, false),	
	#("Memory:Channel:Mapping63", "float16", true, false),	
	#("Memory:Channel:Mapping64", "float16", true, false),	
	#("Memory:Channel:Mapping65", "float16", true, false),	
	#("Memory:Channel:Mapping66", "float16", true, false),	
	#("Memory:Channel:Mapping67", "float16", true, false),	
	#("Memory:Channel:Mapping68", "float16", true, false),	
	#("Memory:Channel:Mapping69", "float16", true, false),		
	#("Memory:Channel:Mapping70", "float16", true, false),	

	#("Memory:Channel:Mapping71", "float16", true, false),	
	#("Memory:Channel:Mapping72", "float16", true, false),	
	#("Memory:Channel:Mapping73", "float16", true, false),	
	#("Memory:Channel:Mapping74", "float16", true, false),	
	#("Memory:Channel:Mapping75", "float16", true, false),	
	#("Memory:Channel:Mapping76", "float16", true, false),	
	#("Memory:Channel:Mapping77", "float16", true, false),	
	#("Memory:Channel:Mapping78", "float16", true, false),	
	#("Memory:Channel:Mapping79", "float16", true, false),		
	#("Memory:Channel:Mapping80", "float16", true, false),	

	#("Memory:Channel:Mapping81", "float16", true, false),	
	#("Memory:Channel:Mapping82", "float16", true, false),	
	#("Memory:Channel:Mapping83", "float16", true, false),	
	#("Memory:Channel:Mapping84", "float16", true, false),	
	#("Memory:Channel:Mapping85", "float16", true, false),	
	#("Memory:Channel:Mapping86", "float16", true, false),	
	#("Memory:Channel:Mapping87", "float16", true, false),	
	#("Memory:Channel:Mapping88", "float16", true, false),	
	#("Memory:Channel:Mapping89", "float16", true, false),		
	#("Memory:Channel:Mapping90", "float16", true, false),	
	
	#("Memory:Channel:Mapping91", "float16", true, false),	
	#("Memory:Channel:Mapping92", "float16", true, false),	
	#("Memory:Channel:Mapping93", "float16", true, false),	
	#("Memory:Channel:Mapping94", "float16", true, false),	
	#("Memory:Channel:Mapping95", "float16", true, false),	
	#("Memory:Channel:Mapping96", "float16", true, false),	
	#("Memory:Channel:Mapping97", "float16", true, false),	
	#("Memory:Channel:Mapping98", "float16", true, false),	
	#("Memory:Channel:Mapping99", "float16", true, false),		
	
	#("Memory:PreAllocation:Use", "false", true, false),
	#("Memory:PreAllocation:ParticleCountInMillions", "10.0", true, false),
	
	--#("InactiveParticleChannels", "Age,float32,1,Orientation,float32,4,TextureCoord,float16,3,MtlIndex,int32,1", true, false), --obsolete
	#("ActiveParticleChannels", "Position,float32,3,Velocity,float16,3,Density,float16,1,Color,float16,3,Normal,float16,3,ID,int32,1", true, false),
	
	#("SaveLightingAsEmission", "false", true, false),
	
	#("ParticleCountMemoryCalculator:Count", "100.0", true, false),
	
	#("RenderElementsHolder", "", true, false),
	
	--Settings for Thinking Particles Groups:
	#("InactiveTPGroups", "", true, false),
	
	-- Settings for Render Target
	#("RenderTarget", "Direct Render", false, true),
	#("XMLOutputFiles", "", false, true),

	-- Settings for Matte Objects
	#("Matte:UseMatteObjects", "false", true, false),
	#("Matte:DepthMapFiles", "", true, false),
	#("Matte:UseDepthMapFiles", "false", true, false),
	#("Matte:DepthMapNear", "0.0", true, false),
	#("Matte:DepthMapFar", "1000.0", true, false),
	#("Matte:DepthMapMode", "Camera Space Z Depth", true, false),
	#("Matte:NamedSelectionSets", "#()", true, false),
	#("Matte:RayDivisions", "4", true, false),
	#("Matte:SaveMultipleLayers", "false", true, false),
	
	--APME Settings
	#("AmbientParticipatingMediumExtinction", "0,0,0", true, false),
	#("ExtinctionRed", "66.1", true, false),
	#("ExtinctionGreen", "9.2", true, false),
	#("ExtinctionBlue", "8.4"		, true, false),
	#("ExtinctionStart", "0"		, true, false),
	#("ExtinctionDistance", "1000.0"	, true, false),
	#("PME:NamedSelectionSets", "#()"	, true, false),
	#("PME:FreeMode", "false"	, true, false),
	#("PME:UseExtinction", "false"	, true, false),
	#("PME:ReferenceColor", "color 255 255 255"			, true, false),
	
	-- Settings for the GUI
	#("GUI:Position", undefined, false, false),
	#("GUI:Size", "[470,740]", true, false),
	
	#("GUI:PresetsRolloutOpen", "false", true, false),
	#("GUI:RenderGlobalValuesRolloutOpen", "false", true, false),
	#("GUI:MainControlsRolloutOpen", "true", true, false),
	#("GUI:SaveParticlesRolloutOpen", "false", true, false),
	
	#("GUI:ParticlePartitioningRolloutOpen", "false", true, false),
	#("GUI:ParticleSystemsRolloutOpen", "false", true, false),
	#("GUI:ShadowsRolloutOpen", "false", true, false),

	#("GUI:ParticleChannelsRolloutOpen", "false", true, false),
	#("GUI:ThinkingParticlesRolloutOpen", "false", true, false),
	
	#("GUI:ParticleLoadersRolloutOpen", "false", true, false),
	#("GUI:PRTHairExplorerRolloutOpen", "false", true, false),
	#("GUI:PRTFumeFXExplorerRolloutOpen", "false", true, false),
	#("GUI:PRTVolumeExplorerRolloutOpen", "false", true, false),
	
	#("GUI:MatteObjectsRolloutOpen", "false", true, false),
	#("GUI:RenderTargetRolloutOpen", "false", true, false),
	
	#("GUI:PreferencesRolloutOpen", "true", true, false),
	#("GUI:PreferencesColorsRolloutOpen", "false", true, false),
	#("GUI:PreferencesSystemRolloutOpen", "false", true, false),
	
	#("GUI:AmbientPMERolloutOpen", "false", true, false),
	#("GUI:UserNotesRolloutOpen", "false", true, false),
	#("GUI:AboutRolloutOpen", "false", true, false),
	
	#("GUI:ShaderDynamicRolloutOpen", "true", true, false),
	
	--Settings for the Presets and User Notes
	#("Presets:SaveRenderHistory", "true", true, false),
	#("Presets:SaveImageSample", "true" , true, false),
	#("UserNotes", "", true, false),
	
	--#("ForceWatermark", "false", true, false), --WHAT IS THIS?
	
	#("VFB:InteractiveUpdate", "false", true, false),
	#("VFB:InteractiveUpdateThreshold", "2000", true, false)					
),

fn getPropNames Obsolete:#include =
(
	case obsolete of
	(
		#skip: for i in KrakatoaPropertiesList where i[4] == false collect i[1]
		default: for i in KrakatoaPropertiesList collect i[1]
		#only: for i in KrakatoaPropertiesList where i[4] == true collect i[1]
	)
),

fn loadiniDefaultSettings =
(
	FranticParticles.LogDebug (" >Loading User Defaults...")
	
	local theDefaultsIniFile = (GetDir #plugcfg  + "\\Krakatoa\\KrakatoaDefaults.ini")
	local theKeys = getIniSetting theDefaultsIniFile "Defaults" 

	for i in KrakatoaPropertiesList where i[3] == true AND findItem theKeys i[1] > 0 do
	(
		local theVal = getIniSetting theDefaultsIniFile "Defaults" i[1]
		FranticParticles.AddProperty i[1] theVal
		FranticParticles.LogDebug ("  >Setting ["+ i[1] +"] to User Default value of ["  + theVal + "]")
	)
),

------------------------------------------
--INITIALIZES THE SETTINGS IN A NEW RENDERER INSTANCE
------------------------------------------
-- The properties map is fairly strict about property names, and any property that gets used has to first
-- be added with AddProperty before it can be accessed.  
-- By doing this strict checking, typos in properties can be caught immediately instead of forming unnoticed bugs.
fn InitRenderer =
(
		local st = timestamp()
		FranticParticles.LogProgress (">Initializing Krakatoa Renderer v" + FranticParticles.Version + "...")
		-- Settings for Main Controls
	
		for i in KrakatoaPropertiesList do
				FranticParticles.addProperty i[1] i[2]
		
		for i in #("Henyey-Greenstein", "Schlick", "Phong Surface", "Kajiya-Kay Hair", "Marschner Hair") do FranticParticleRenderMXS.initDynamicShaderProperties (FranticParticleRenderMXS.getShaderPropList i) i
		
		FranticParticleRenderMXS.loadiniDefaultSettings()

		FranticParticles.LogProgress ("  +Krakatoa Renderer INITIALIZED in " + (timestamp() - st) as string + " milliseconds.")
),

fn saveCustomDefaults =
(
	local theDefaultsIniFile = (GetDir #plugcfg  + "\\Krakatoa\\KrakatoaDefaults.ini")
	deleteFile theDefaultsIniFile 
	
	for i in KrakatoaPropertiesList where i[3] == true do
		setIniSetting theDefaultsIniFile "Defaults"  i[1] (FranticParticles.GetProperty i[1])
),

--Result will be #( isEnabled, colorMultipier, #(Color Gradient), opacityMultiplier, #(Opacity Curve), isTCB )
fn getFumeShaderParameters fumeNode = 
(
    local result = #()
    local fumeShader = fumeNode.GetShader()
    local isTCB = false
    
    append result ( fumeShader.ShadeFire )
    if( fumeShader.ShadeFire ) do (
        local colorGradient = #()
        local opacityCurve = #()
        
        if( hasProperty fumeShader "Fire_Color_Gradient" ) do (
            local fcg = fumeShader.Fire_Color_Gradient
            case (fcg.GetMode() ) of (
                0: ( append colorGradient #( 0, fcg[1].Color, #(0,0,0,0,0) ) )
                1: (
                    local numKeys = ( fcg.NumKeys() )
                    for i = 0 to (numKeys-1) do (
                        append colorGradient #( fcg[i+1].Position, fcg[i+1].Color, #(0,0,0,0,0) )
                    )
                )
                2: ( 
					local numKeys = ( fcg.NumKeys() )
					for i = 0 to (numKeys-1) do (
							append colorGradient #( fcg[i+1].Position, fcg[i+1].Color, #(fcg[i+1].Tension,fcg[i+1].Continuinity,-fcg[i+1].Bias,fcg[i+1].EaseTo,fcg[i+1].EaseFrom) )
					)
                    isTCB = true
				)
            )
        )
        
        if( hasProperty fumeShader "Fire_Opacity_AFC" ) do (
            local afc = fumeShader.Fire_Opacity_AFC
            if( afc.GetMode() != 0 ) do (
                local numKnots = afc.NumKnots()
                for i = 0 to (numKnots-1) do (
					if ( afc.GetKnotType(i) == 0 ) then ( --Case where in FumeFX we have a 'smooth' control point, we treat it as a cardinal spline
						local prevKnot = afc.GetKnot (i  - 1)
						local nextKnot = afc.GetKnot (i + 1)
						local tangent = [(nextKnot.x - prevKnot.x) / 2, (nextKnot.y - prevKnot.y) / 2] / 3.0
						append opacityCurve #( (afc.GetKnot i), (-tangent), (tangent) )
					) else ( --All other cases can be generalized to bezier curves
						append opacityCurve #( (afc.GetKnot i), (afc[i + 1].InVec), (afc[i + 1].OutVec) )
					)
                )
            )
        )
		
		local gridSpacing = fumeNode.GridSpacing
        
        append result ( fumeShader.Fire_Brightness * gridSpacing * gridSpacing * gridSpacing )
        append result colorGradient
        append result ( fumeShader.Fire_Opacity )
        append result opacityCurve
        append result isTCB
    )
    result
),

------------------------------------------
--POST LOAD EVENT FOR BACKWARDS COMPATIBILITY FIXES
------------------------------------------
fn PostLoadEvent =
(
	-- Loading a new file requires a global GUI refresh
	local st = timestamp()
	FranticParticleRenderMXS.GlobalRefreshGUI()

	FranticParticles.LogDebug ("  +PostLoadEvent Function FINISHED in " + (timestamp()-st) as string + " milliseconds.")
),

fn increasePFlowSystemLimits =
(
	FranticParticles.LogDebug ">Setting System Limit of all Particle Flow Emitters to 100 Million Particles..."
	cnt = 0
	for o in objects where classof o == PF_Source do 
	(
		if o.Particle_Amount_Limit < 100000000 do o.Particle_Amount_Limit = 100000000
		cnt += 1
	)	
	case of
	(
		(cnt == 0): (FranticParticles.LogDebug ("  -No Particle Flow Emitters found.")	)
		(cnt == 1): (FranticParticles.LogDebug ("  +One Particle Flow Emitter Processed.") )
		default: (FranticParticles.LogDebug ("  +"+ cnt as string +" Particle Flow Emitters Processed.") )
	)
		
),

-------------------------------------- 
--CALLED ON SAVE?
------------------------------------- 
fn CloseGUI =
(
	FranticParticles.LogDebug ">CloseGUI Function Called. Not implemented."
),


fn CancelGUI =
(
	FranticParticles.LogDebug ">CancelGUI Function Called. Not implemented."
),

-- This function sets the dropdown selection value to the item which matches the given string input.
-- The purpose of this is to store all drop down list items as text labels instead of integers, so we can
-- change the ordering and add new items in the middle without breaking compatibility.
fn SetDropDownValue dropDown value = 
(
	local i, valueToSet = 1
	try
	(
		for i = 1 to dropDown.items.count do 
		(
			if value == dropDown.items[i] do 
			(
				valueToSet = i
			)
		)
		dropDown.selection = valueToSet
	)catch()
),

fn updateIconColors =
(
	local Hue = execute (getIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini" ) "IconColors"  "Hue")
	if Hue == OK do Hue = 0
	local Sat = execute (getIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini" ) "IconColors"  "Saturation")
	if Sat == OK do Sat = 0
	local Val= execute (getIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini" ) "IconColors"  "Value")
	if Val == OK do Val = 0
	local AbsRel= execute (getIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini" ) "IconColors"  "AbsoluteRelative")
	if AbsRel == OK do AbsRel = 1
		
	local thePow=1.0
	try
	(
		thePow=(1.0/(if IDisplayGamma.colorCorrectionMode == #gamma then IDisplayGamma.gamma else 1.0))
	)catch()
	
	copy Krakatoa_PresetsArrowBitmap_Base Krakatoa_PresetsArrowBitmap 
	
	for i = 0 to Krakatoa_PresetsArrowBitmap.height-1 do
	(
		local thePixels = getPixels Krakatoa_PresetsArrowBitmap [0,i] Krakatoa_PresetsArrowBitmap.width
		for j = 1 to thePixels.count do 
		(
			local thePixel = thePixels[j] 
			thePixel.s = (thePixel.s as float) ^ (thePow) 
			
			if thePixel.v < 255 do 
			(
				case AbsRel of
				(
					1: (
							thePixel.h += Hue 
							thePixel.s += Sat --(Sat as float)^thePow 
							thePixel.v += Val
					)
					default:
					(
							thePixel.h = Hue
							thePixel.s = Sat
							thePixel.v = Val
					)
				)
			)	
			thePixels[j] = thePixel 
		)		
		setPixels Krakatoa_PresetsArrowBitmap [0,i] thePixels
	)		
	try(Krakatoa_CustomizeRollouts_Dialog.updateIcons())catch()
	try(Krakatoa_GUI_History_Dialog.updateIcons())catch()
	try(Krakatoa_GUI_Presets.updateIcons())catch()
	try(Krakatoa_GUI_RenderGlobalValues.updateIcons())catch()
	try(Krakatoa_GUI_ShaderDynamic.updateIcons())catch()
	try(Krakatoa_GUI_Main.updateIcons())catch()
	try(Krakatoa_GUI_SaveParticles.updateIcons())catch()
	try(Krakatoa_GUI_Channels.updateIcons())catch()
	try(Krakatoa_GUI_ThinkingParticles.updateIcons())catch()
	try(Krakatoa_GUI_Partition.updateIcons())catch()
	try(Krakatoa_GUI_ParticleLoaders.updateIcons())catch()
	try(Krakatoa_GUI_MatteObjects.updateIcons())catch()
	try(Krakatoa_GUI_Preferences.updateIcons())catch()
	try(Krakatoa_GUI_Preferences_Colors.updateIcons())catch()
	try(Krakatoa_GUI_Particles.updateIcons())catch()
	try(Krakatoa_GUI_Notes.updateIcons())catch()
	try(Krakatoa_GUI_About.updateIcons())catch()
	try(Krakatoa_GUI_AmbientPME.updateIcons())catch()
	try(Krakatoa_VFB_Left_Rollout.updateIcons())catch()
	try(Krakatoa_VFB_Right_Rollout.updateIcons())catch()
	try(Krakatoa_VFB_Overlay_Rollout.updateIcons())catch()
		
),


-------------------------------------- 
--HELPER FUNCTIONS
--------------------------------------
fn GetEarliestBirthFrame = (
	FranticParticles.LogDebug ">GetEarliestBirthFrame Function Called."
	local emit_start = 99999999	--arbitrarily large number
	
	--Traverse each particle source.
	for o in objects where (classof o == PF_Source) do(

		--Traverse all the active(ie. fertile && renderable) Events
		for i = 1 to o.getNumInitialActionLists() do (
			local event = o.getInitialActionList i
			if( event.isActivated() and (event.isActionActive 1) == 1 ) do (
				
				--Check for a birth operator in operator slot 1
				local birth_op = (event.getAction 1)
				if(try(birth_op.isFertile())catch(false)) do (
					local cur_start = try( (event.getAction 1).Emit_Start / TicksPerFrame )catch( emit_start )
					if( cur_start < emit_start ) do emit_start = cur_start
				)
			)
		)--1 to o.getNumInitialActionLists()
	)--o in objects
	if emit_start == 99999999 do return 0 --if the large number was not changed, we can as well use 0
	emit_start as integer
),

fn getSceneMappingChannelsUsed =
(
	local theMappingChannelsUsed = #{}
	
	try(
		local theObjects = getClassInstances OutputStandard
		if theObjects.count > 0 do
			theMappingChannelsUsed += (for i in theObjects where i.Data_Type==9 collect i.Map_Channel) as bitarray
	)catch()
	
	try(
		theObjects = getClassInstances mapping
		if theObjects.count > 0 do
			theMappingChannelsUsed += (for i in theObjects collect i.Map_Channel) as bitarray
	)catch()

	try(
		theObjects = getClassInstances Mapping_Object
			for o in theObjects do
				theMappingChannelsUsed += (for i = 1 to 32 where o.Acquire_From_Mapping_Channels[i] collect i) as bitarray
	)catch()
	theMappingChannelsUsed	
),

----------------------------------------------------------
--Preset Saving And Loading Functions
----------------------------------------------------------
fn saveRolloutPreset theRollout thePresetFile =
(
	FranticParticles.LogDebug (">Saving Settings of " + theRollout as string)

	local doNotShowThese = #(
			Krakatoa_GUI_Main.edt_LightingDensityFullValue,
			Krakatoa_GUI_Main.edt_FinalDensityFullValue,
			Krakatoa_GUI_Main.edt_emissionStrengthResultingValue,
		
			Krakatoa_GUI_Partition.edt_jobname,
			Krakatoa_GUI_Partition.edt_comment,
			Krakatoa_GUI_Partition.edt_user ,
			Krakatoa_GUI_Partition.edt_dept ,
			Krakatoa_GUI_Partition.ddl_category,
			Krakatoa_GUI_Partition.ddl_poollist,
			Krakatoa_GUI_Partition.sld_priority,
			Krakatoa_GUI_Partition.spn_priority,
			Krakatoa_GUI_Partition.spn_chunkSize, 
			Krakatoa_GUI_Partition.spn_machineLimit,
			
			Krakatoa_GUI_Channels.spn_particleCount,
			Krakatoa_GUI_Channels.spn_MemoryUsage,
			
			Krakatoa_GUI_MatteObjects.edt_createNewSelSet,
			Krakatoa_GUI_MatteObjects.edt_info,
			Krakatoa_GUI_AmbientPME.edt_createNewSelSet
	)
	
	
	for i in theRollout.controls do 
	(
		try
		(
			if findItem doNotShowThese i == 0 do
			(
				case (classof i) of
				(
					SpinnerControl: setIniSetting thePresetFile theRollout.name i.name (i.value as string)
					CheckButtonControl: setIniSetting thePresetFile theRollout.name i.name (i.state as string)
					ColorPickerControl: setIniSetting thePresetFile theRollout.name i.name (i.color as string)
					ComboBoxControl: setIniSetting thePresetFile theRollout.name i.name (i.selected as string)
					ListBoxControl: (
									if i == Krakatoa_GUI_MatteObjects.lbx_useNamedSelectionSets do
									(
										txt = "#("
										if i.items.count > 0 do
										(
											for j = 1 to i.items.count-1 do txt += "\"" + i.items[j] as string + "\","
											txt += "\"" + i.items[i.items.count] as string + "\""
										)	
										txt += ")"
										setIniSetting thePresetFile theRollout.name i.name txt 
									)	
								)
					PickerControl: (
								)	
					MultiListBoxControl: (
										if i == Krakatoa_GUI_SaveParticles.lbx_activeChannels do
										(
											setIniSetting thePresetFile theRollout.name i.name (FranticParticles.getProperty "ActiveParticleChannels")
										)	
									)
					EditTextControl: (
									if i != Krakatoa_GUI_Notes.edt_userNotes AND i != Krakatoa_GUI_MatteObjects.edt_createNewSelSet do 
										setIniSetting thePresetFile theRollout.name i.name i.text 
									)
				)--end case
			)--end if	
		)catch()	
	)--end i loop
	FranticParticles.LogDebug "  +Rollout Settings SAVED."	
),
fn loadRolloutPreset theRollout thePresetFile =
(
	FranticParticles.LogDebug (">Loading Settings of " + theRollout as string)
	for i in theRollout.controls where classof i != GroupStartControl and classof i != GroupEndControl do 
	(
		theValue = getIniSetting thePresetFile theRollout.name i.name
		case (classof i) of
		(
			SpinnerControl: (
							if theValue != "" do try(i.set (i.value = execute theValue))catch()
						)
			CheckButtonControl: (
							if theValue != "" do try(i.changed (i.state = execute theValue))catch()
						)			
			ColorPickerControl: (
							if theValue != "" do try(i.changed (i.color = execute theValue))catch()
						)	
			PickerControl: (
						)							
			MultiListBoxControl: (
								if i == Krakatoa_GUI_SaveParticles.lbx_activeChannels do
								(
									try
									(
										FranticParticles.setProperty "ActiveParticleChannels" theValue
										Krakatoa_GUI_SaveParticles.populateLists()
									)catch()
								)					
							)						
			ComboBoxControl: (
							if theValue != "" do 
							(
								try(
									theFN = execute (theRollout.name +"." + i.name + "_SelectedFN")
									theFN (i.selection = findItem i.items theValue)
								)catch()
							)			
						)	
			ListBoxControl: (
							if i == Krakatoa_GUI_MatteObjects.lbx_useNamedSelectionSets do
							(
								try(Krakatoa_GUI_MatteObjects.lbx_useNamedSelectionSets.items = execute theValue; Krakatoa_GUI_MatteObjects.saveSelectionSets() )catch()
							)	
						)						
			EditTextControl: 
			(
				if i != Krakatoa_GUI_Notes.edt_userNotes AND i != Krakatoa_GUI_MatteObjects.edt_createNewSelSet do
					try(i.entered (i.text = TheValue))catch()
			)
		)
	)	
	try(theRollout.Refresh_GUI())catch()
	FranticParticles.LogDebug "  +Rollout Presets LOADED."	
),

fn framePreRender arg =
(
	--FIXME: Temp. workaround for older script's bug:
	if FranticParticles.getProperty "GlobalDataHolder" != "" and not isValidNode (getNodeByName (FranticParticles.getProperty "GlobalDataHolder")) do 
		FranticParticles.setProperty "GlobalDataHolder" ""	
	
	try(FranticParticles.setProperty "UseGlobalColorOverride" "false")catch() --disable old color override property if set from 1.1.x
	
	FranticParticleRenderMXS.lastFrameRenderStartTime = timestamp()
	FranticParticleRenderMXS.lastFrameRenderTime = currentTime
),

fn framePostRender =
(
	FranticParticleRenderMXS.lastFrameRenderEndTime = timestamp()
	if isNetServer() do return 0

	if (not FranticParticles.getBoolProperty "EnableParticleCache") or KrakatoaPostRenderCacheableSettings == undefined do
	(
		::KrakatoaPostRenderCacheableSettings = with printAllElements on (FranticParticleRenderMXS.storeCacheableSettings()) --as string
	)
	updateToolbarButtons() --this enforces the PCX and LCX icons on the Krakatoa Toolbar to refresh
),

fn getMaxVersionString =
(
	local maxVersionName = case ((maxVersion())[1]/1000) of
	(
		default: "3ds Max"
		8: "3ds Max 8"
		9: "3ds Max 9"
		10: "3ds Max 2008"
		11: "3ds Max 2009"
		12: "3ds Max 2010"
		13: "3ds Max 2011"
		14: "3ds Max 2012"
		15: "3ds Max 2013"
		16: "3ds Max 2014"
		17: "3ds Max 2015"
		18: "3ds Max 2016"
		19: "3ds Max 2017"
	)
	maxVersionName += if is64bitApplication() then " 64 bit" else " 32 bit"
	maxVersionName 
),

fn saveSceneInfo thePresetFile =
(
	FranticParticles.LogDebug (">Saving Scene Info to [" + fileNameFromPath thePresetFile +"]...")
	renderSceneDialog.commit()
	setIniSetting thePresetFile "SceneInfo" "Path" maxFilePath
	setIniSetting thePresetFile "SceneInfo" "Name" maxFileName
	setIniSetting thePresetFile "SceneInfo" "Date" localtime
	setIniSetting thePresetFile "SceneInfo" "Output" rendOutputFileName
	local maxVersionName = FranticParticleRenderMXS.getMaxVersionString()
	setIniSetting thePresetFile "SceneInfo" "Build" (FranticParticles.Version + " - " + maxVersionName)
	try(setIniSetting thePresetFile "SceneInfo" "Cache" (Krakatoa_GUI_Channels.updateMemChannels()))catch()


	local theGeoVolumes = (for o in objects where classof o.baseobject == PRT_Volume AND o.renderable collect o)
	local theGeoSurfaces = (for o in objects where classof o.baseobject == PRT_Surface AND o.renderable collect o)
	local thePRTFumes = (for o in objects where classof o.baseobject == PRT_FumeFX AND o.renderable collect o)
	local thePRTHairs = (for o in objects where classof o.baseobject == PRT_Hair AND o.renderable collect o)
	local thePRTMakers = (for o in objects where classof o.baseobject == PRT_Maker AND o.renderable collect o)
	local thePRTSources = (for o in objects where classof o.baseobject == PRT_Source AND o.renderable collect o)
		
	local objectCount = "Lights:" + ((for o in objects where findItem light.classes (classof o) > 0 collect o).count as string)
	objectCount += ", Geometry:" + ((for o in objects where findItem geometryClass.classes (classof o) > 0 AND findItem #(TargetObject, PF_Source, ParticleGroup,KrakatoaPRTLoader,Thinking,PRT_Volume,PRT_Surface,PRT_FumeFX,PRT_Hair,PRT_Maker,PRT_Source) (classof o.baseobject) == 0 collect o).count as string)
	
	local thePFlowEmitters = (for o in objects where classof o == PF_Source collect o)
	objectCount += ", PFlows:" + (thePFlowEmitters.count as string)
	
	local theThinking = for o in objects where classof o == Thinking collect o
	objectCount += ", Thinking:" + (theThinking.count as string)

	local thePRTLoaders = (for o in objects where classof o == KrakatoaPrtLoader collect o)
	objectCount += ", PRTLoaders:" + (thePRTLoaders.count as string)

	objectCount += ", PRTVolumes:" + (theGeoVolumes.count as string)
	objectCount += ", PRTSurfaces:" + (theGeoSurfaces.count as string)
	objectCount += ", PRTFumeFX:" + (thePRTFumes.count as string)
	objectCount += ", PRTHair:" + (thePRTHairs.count as string)
	objectCount += ", PRTMaker:" + (thePRTMakers.count as string)
	objectCount += ", PRTSource:" + (thePRTSources.count as string)

	setIniSetting thePresetFile "SceneInfo" "Objects" objectCount 
	
	for pfs in thePFlowEmitters do
	(
		actualAmount = requestedAmount = pfs.numParticles() / pfs.Quantity_Viewport * pfs.Quantity_Render
		if requestedAmount > pfs.Particle_Amount_Limit do actualAmount = pfs.Particle_Amount_Limit
		setIniSetting thePresetFile "SceneInfo" ("PFSource:" + pfs.name) (" render:"+actualAmount as string + " req:" + requestedAmount as string + " limit:" +  pfs.Particle_Amount_Limit as string)
	)	
	
	theNotes = try((FranticParticles.GetProperty "UserNotes") as stringStream)catch("" as stringStream)
	cnt = 0
	while not eof theNotes do
	(
		cnt += 1
		setIniSetting thePresetFile "SceneInfo" ("Note " + cnt as string) (readLine theNotes)
	)
	FranticParticles.LogDebug "+Scene Info SAVED."
),


fn savePresetAll thePresetFile =
(
	FranticParticles.LogDebug (">Saving Preset File [" + fileNameFromPath thePresetFile +"]...")
	--for r in Krakatoa_Gui_floater.rollouts where r != Krakatoa_GUI_Presets and r != Krakatoa_GUI_About and r != Krakatoa_GUI_Notes AND r != Krakatoa_GUI_ParticleLoaders do 
	Krakatoa_CustomizeRollouts_Dialog.updateHidden()
	local allRollouts = #(
			Krakatoa_GUI_RenderGlobalValues,
			Krakatoa_GUI_ShaderDynamic,
			Krakatoa_GUI_Main, 
			Krakatoa_GUI_SaveParticles,
			Krakatoa_GUI_Channels, 
			Krakatoa_GUI_Partition, 
			Krakatoa_GUI_MatteObjects, 
			Krakatoa_GUI_AmbientPME
			--Krakatoa_GUI_ThinkingParticles,
			--Krakatoa_GUI_Shadows
		)		
	for r in allRollouts do
	(
		FranticParticleRenderMXS.saveRolloutPreset r thePresetFile 
	)	
	FranticParticleRenderMXS.saveSceneInfo thePresetFile
	FranticParticles.LogDebug "  +Preset File SAVED."
),

fn loadPresetAll thePresetFile =
(
	FranticParticles.LogDebug (">Loading Preset File [" + fileNameFromPath thePresetFile +"]...")
	local allRollouts = #(
			Krakatoa_GUI_RenderGlobalValues,
			Krakatoa_GUI_ShaderDynamic,
			Krakatoa_GUI_Main, 
			Krakatoa_GUI_SaveParticles,
			Krakatoa_GUI_Channels, 
			Krakatoa_GUI_Partition, 
			Krakatoa_GUI_MatteObjects, 
			Krakatoa_GUI_AmbientPME
		)		
	for r in allRollouts do	
	(
		FranticParticleRenderMXS.loadRolloutPreset r thePresetFile 
	)	
	FranticParticles.LogDebug "  +Preset File LOADED."
),

fn fixTimeString txt =
(
	local badStrings = "\\/:. "
	for i = 1 to txt.count do 
		if findString badStrings txt[i] != undefined do txt[i] = "_"
	txt	
),

fn saveAllValueCaches theFileName =
(
	FranticParticleRenderMXS.addValueToKrakatoaHistoryCache "Background Color" (FranticParticles.getProperty "BackgroundColor") theFileName "Krakatoa_GUI_RenderGlobalValues" "clr_backgroundColor"
	FranticParticleRenderMXS.addValueToKrakatoaHistoryCache "Override Color" (FranticParticles.getProperty "ColorOverride:Color") theFileName "Krakatoa_GUI_RenderGlobalValues" "clr_colorOverride"
	FranticParticleRenderMXS.addValueToKrakatoaHistoryCache "Override Emission Color" (FranticParticles.getProperty "EmissionOverride:Color") theFileName "Krakatoa_GUI_RenderGlobalValues" "clr_emissionOverride"
	FranticParticleRenderMXS.addValueToKrakatoaHistoryCache "Override Absorption Color" (FranticParticles.getProperty "AbsorptionOverride:Color") theFileName "Krakatoa_GUI_RenderGlobalValues" "clr_absorptionOverride"
	local theVal = 255.0*(FranticParticles.getFloatProperty "DensityOverride:Value")
	FranticParticleRenderMXS.addValueToKrakatoaHistoryCache "Override Density Color" ((color theVal theVal theVal) as string) theFileName "Krakatoa_GUI_RenderGlobalValues" "clr_densityOverride"
),

fn saveRenderHistory =
(
	if (IsNetServer()) do return 0
	FranticParticles.LogDebug (">FN saveRenderHistory() Called.")
	local st = timestamp()
	Krakatoa_GUI_Main.refreshCacheStatus()
	Krakatoa_GUI_Channels.updateMemChannels()
	if FranticParticles.GetBoolProperty "Presets:SaveRenderHistory" then --Krakatoa_Gui_floater.open and 
	(
		FranticParticles.LogDebug (">Saving Render History...")
		theFile = getFileNameFile maxFileName + "_" + FranticParticleRenderMXS.fixTimeString localtime 
		theHistoryFile = Krakatoa_PresetsDirectory + "\\history\\" + theFile + ".KrakatoaSettings"
		
		savePresetAll theHistoryFile 
		saveSceneInfo theHistoryFile 
		
		if not doesFileExist (Krakatoa_PresetsDirectory+"\\_HistoryCache.List") do 
			Krakatoa_GUI_Presets.rebuildHistoryCache()
		try
		(
			FranticParticles.LogDebug ("  >Adding Render History To Cache...")
			theCache = openFile (Krakatoa_PresetsDirectory+"\\_HistoryCache.List") mode:"at"
			format "%\n" (getFileNameFile theHistoryFile) to:theCache
			close theCache
		)catch(FranticParticles.LogDebug ("  -Failed to add History File to CACHE."))	
		FranticParticleRenderMXS.saveAllValueCaches theHistoryFile
		
		if FranticParticles.GetBoolProperty "Presets:SaveImageSample" AND FranticParticles.GetProperty "ParticleMode" == "Render Scene Particles" then
		(
			local theLastImage = getLastRenderedImage()
			theLastImage.filename = Krakatoa_PresetsDirectory + "\\samples\\" + theFile + ".exr"
			save theLastImage
			close theLastImage
			setIniSetting theHistoryFile "SampleImage" "Filename" (theFile + ".exr")
			setIniSetting theHistoryFile "SceneInfo" "RenderTime" (((timestamp()-FranticParticleRenderMXS.lastFrameRenderStartTime)/1000.0) as string + " sec.")
			setIniSetting theHistoryFile "SceneInfo" "Frame" (FranticParticleRenderMXS.lastFrameRenderTime.frame as string) 
			local theCount = try((FranticParticles.GetCachedParticleCount()) as string)catch("???")
			local theMemory = try((FranticParticles.getCacheSize()) as string)catch("???")
			setIniSetting theHistoryFile "SceneInfo" "PCache"   (FranticParticleRenderMXS.addCommas theCount +" Particles using " + theMemory  + " MB")
--			delete theLastImage --this was causing an early exit from the function!
			theLastImage = undefined
			gc light:true
		)
		else
		(
			setIniSetting theHistoryFile "SceneInfo" "SaveTime" (((FranticParticleRenderMXS.lastFrameRenderEndTime-FranticParticleRenderMXS.lastFrameRenderStartTime)/1000.0) as string + " sec." )
			setIniSetting theHistoryFile "SceneInfo" "Frame" (FranticParticleRenderMXS.lastFrameRenderTime.frame as string) 
			setIniSetting theHistoryFile "SceneInfo" "ParticleFiles" (FranticParticles.GetProperty "ParticleFiles")
			setIniSetting theHistoryFile "SceneInfo" "ParticleFilesBase" (FranticParticles.GetProperty "ParticleFilesBase")
			setIniSetting theHistoryFile "SceneInfo" "ParticleFilesProject" (FranticParticles.GetProperty "ParticleFilesProject")
			setIniSetting theHistoryFile "SceneInfo" "ParticleFilesSequence" (FranticParticles.GetProperty "ParticleFilesSequence")
			setIniSetting theHistoryFile "SceneInfo" "ParticleFilesTake" (FranticParticles.GetProperty "ParticleFilesTake")
			setIniSetting theHistoryFile "SceneInfo" "ParticleFilesName" (FranticParticles.GetProperty "ParticleFilesName")
			FranticParticleRenderMXS.addToPathsCache()
		)	
		if FranticParticles.GetProperty "ParticleMode" == "Render Scene Particles" then
		(
			local theCamera = viewport.getCamera()
			if isValidNode theCamera then
				setIniSetting theHistoryFile "SceneInfo" "Camera" (theCamera.name as string)
			else
				setIniSetting theHistoryFile "SceneInfo" "ViewType" (viewport.getType() as string)
			setIniSetting theHistoryFile "SceneInfo" "ViewTM" ((viewport.getTM()) as string)
			local theThreads = (FranticParticles.getProperty "SortingThreads")
			if theThreads == "0" do theThreads = sysinfo.cpucount as string
			setIniSetting theHistoryFile "SceneInfo" "Threads" theThreads
		)
		
		local r=sysinfo.getSystemMemoryInfo()
		for i=2 to 7 do r[i] /= (1024*1024.)
		setIniSetting theHistoryFile "SceneInfo" "UsedMemory" ((r[1] as float) as string + "%")
		setIniSetting theHistoryFile "SceneInfo" "PhysicalMemory" ("Total:" + r[2] as string + " MB   Used:" + (r[2]-r[3]) as string + " MB   Free:" + r[3] as string + " MB")
		setIniSetting theHistoryFile "SceneInfo" "VirtualMemory" ("Total:" + r[6] as string + " MB   Used:" + (r[6]-r[7]) as string + " MB   Free:" + r[7] as string + " MB")
		setIniSetting theHistoryFile "SceneInfo" "PageFileSize" ("Total:" + r[4] as string + " MB   Used:" + (r[4]-r[5]) as string + " MB   Free:" + r[5] as string + " MB")
		
		r=sysinfo.getMAXMemoryInfo()
		for i=2 to 9 do r[i] /= (1024*1024.)
		setIniSetting theHistoryFile "SceneInfo" "PageFaultsCount" ((r[1] as integer) as string)
		setIniSetting theHistoryFile "SceneInfo" "WorkingSet" ("Size:" + r[3] as string + " MB   Peak:" + r[2] as string + " MB")
		setIniSetting theHistoryFile "SceneInfo" "PagedPool" ("Size:" + r[5] as string + " MB   Peak:" + r[4] as string + " MB")
		setIniSetting theHistoryFile "SceneInfo" "NonPagedPool" ("Size:" + r[7] as string + " MB   Peak:" + r[6] as string + " MB")
		setIniSetting theHistoryFile "SceneInfo" "PageFileUseage" ("Size:" + r[8] as string + " MB   Peak:" + r[9] as string + " MB")
		
		try(Krakatoa_GUI_Presets.btn_update.pressed())catch()
			
		FranticParticles.LogDebug ("  +Render History SAVED in " + (timestamp()-st) as string + " milliseconds.")
	)
	else
	(
		FranticParticles.LogDebug ("  -Render History NOT SAVED!")
	)	
	try(Krakatoa_updateSchematicFlow())catch()
),

fn initTreeView tv =
(
	local st = timestamp()
	FranticParticles.LogDebug (">Initializing TreeView...")
	tv.nodes.Clear()
	tv.checkboxes = true
	Krakatoa_DoExportTable = #()
	Krakatoa_ObjectsTable = #()
	tagCounter = 0
	FranticParticles.LogDebug ("  +TreeView INITIALIZED in " + (timestamp()-st) as string + " milliseconds." )
),

fn addChildren tv theNode theChildren theParent =
(
	for c in theChildren do
	(
		if classof c == RolloutClass then 
		(
			tagCounter += 1
			newNode = theNode.Nodes.add c.title
			newNode.checked = if FranticParticleRenderMXS.LoadSave_SingleRollout == undefined then true else FranticParticleRenderMXS.LoadSave_SingleRollout == c
			Krakatoa_DoExportTable[tagCounter] = newNode.checked
			
			newNode.forecolor = (dotNetClass "System.Drawing.Color").fromARGB 0 0 100 
			Krakatoa_ObjectsTable[tagCounter] = #(undefined, c)
			newNode.tag = dotNetMXSValue tagCounter 	
			FranticParticleRenderMXS.addChildren tv newNode c.controls c
		)
		goOn = true
		theControlClass = classof c 
		if theControlClass == SpinnerControl or theControlClass == CheckButtonControl or theControlClass == ColorPickerControl or theControlClass == EditTextControl or theControlClass == ComboBoxControl or theControlClass == MultiListBoxControl or theControlClass == PickerControl or theControlClass == ListBoxControl do
		(
			if Krakatoa_PresetDialogMode == #load or Krakatoa_PresetDialogMode == #loadHistory then
			(
				theKeys = getIniSetting Krakatoa_PresetIniFile theParent.name
				if findItem theKeys c.name > 0 then 
					theValueString = getIniSetting Krakatoa_PresetIniFile theParent.name c.name
				else
					GoOn = false
			)	
			else
			(
				case theControlClass of 
				(
					SpinnerControl: theValueString = c.value as string
					CheckButtonControl: theValueString = c.state as string
					ColorPickerControl: theValueString = c.color as string
					PickerControl: theValueString = if c.object!=undefined then c.object.name else "Pick Node"
					ListBoxControl: (
									theValueString = c.items as string
									if c != Krakatoa_GUI_MatteObjects.lbx_useNamedSelectionSets do GoOn = false
								)	
					MultiListBoxControl: (
						theValueString = c.items as string
						if c != Krakatoa_GUI_SaveParticles.lbx_activeChannels do GoOn = false
					)
					EditTextControl: theValueString = c.text 
					ComboBoxControl: theValueString = c.selected
					default: (GoOn = false)
				)--end case
			)	
			doNotShowThese = #(
				
					Krakatoa_GUI_Main.edt_LightingDensityFullValue,
					Krakatoa_GUI_Main.edt_FinalDensityFullValue,
					Krakatoa_GUI_Main.edt_emissionStrengthResultingValue,				
					Krakatoa_GUI_Partition.edt_jobname,
					Krakatoa_GUI_Partition.edt_comment,
					Krakatoa_GUI_Partition.edt_user ,
					Krakatoa_GUI_Partition.edt_dept ,
					Krakatoa_GUI_Partition.ddl_category,
					Krakatoa_GUI_Partition.ddl_poollist,
					Krakatoa_GUI_Partition.sld_priority,
					Krakatoa_GUI_Partition.spn_priority,
					Krakatoa_GUI_Partition.spn_chunkSize, 
					Krakatoa_GUI_Partition.spn_machineLimit,
					Krakatoa_GUI_MatteObjects.edt_createNewSelSet,
					Krakatoa_GUI_MatteObjects.edt_info,
					Krakatoa_GUI_RenderGlobalValues.map_colorOverrideTexmap,
					Krakatoa_GUI_RenderGlobalValues.map_emissionOverrideTexmap,
					Krakatoa_GUI_RenderGlobalValues.map_absorptionOverrideTexmap,
					Krakatoa_GUI_RenderGlobalValues.map_densityOverrideTexmap,
					Krakatoa_GUI_AmbientPME.edt_presetname
			)
			
			if findItem doNotShowThese c > 0 do GoOn = false
			if GoOn then
			(
				if c.caption == "" then txt = c.name else txt = trimLeft c.caption				
				if matchPattern txt pattern:"ddl_*" do txt = substring txt 5 -1
				if matchPattern txt pattern:"lbx_*" do txt = substring txt 5 -1
					
				txt += " ["+ theValueString +"]"
				
				newNode = theNode.Nodes.add txt 
				newNode.checked = true
				tagCounter += 1
				Krakatoa_ObjectsTable[tagCounter] = #(theParent , c)
				Krakatoa_DoExportTable[tagCounter] = true
				newNode.tag = dotNetMXSValue tagCounter 
			)--end if goOn
		)--end if class	
	)--end c loop
),

fn fillInTreeView tv =
(
	local st = timestamp()
	FranticParticles.LogDebug (">Populating TreeView...")
	theRoot = tv.nodes.add "" 
	case Krakatoa_PresetDialogMode of
	(
		#save: 
			(
				theRoot.text = "SAVE Krakatoa Render Dialog Preset"
				theRoot.forecolor = (dotNetClass "System.Drawing.Color").fromARGB 200 0 0 
			)	
		#load: 
			(
				if Krakatoa_SavePresetDialog.ddl_presetsToLoad.selected != undefined then 
					theRoot.text = "LOAD Krakatoa Render Dialog Preset [" + Krakatoa_SavePresetDialog.ddl_presetsToLoad.selected + "]"
				else	
					theRoot.text = "NO RENDER PRESETS FOUND!"
				theRoot.forecolor = (dotNetClass "System.Drawing.Color").fromARGB 0 100 0 
			)	
		#loadHistory: 
			(
				if Krakatoa_SavePresetDialog.ddl_presetsToLoad.selected != undefined then 
					theRoot.text = "LOAD Krakatoa Render History [" + Krakatoa_SavePresetDialog.ddl_presetsToLoad.selected + "]"
				else	
					theRoot.text = "NO RENDER HISTORY FILES FOUND!"
				theRoot.forecolor = (dotNetClass "System.Drawing.Color").fromARGB 0 100 0  
			)						
	)	
	theRoot.checked = true
	
	tagCounter += 1
	Krakatoa_ObjectsTable[tagCounter] = #(undefined,Krakatoa_Gui_floater)
	Krakatoa_DoExportTable[tagCounter] = false
	local rootNodes = #(
		Krakatoa_GUI_RenderGlobalValues,
		Krakatoa_GUI_ShaderDynamic,
		Krakatoa_GUI_Main, 
		Krakatoa_GUI_SaveParticles,
		Krakatoa_GUI_Channels, 
		Krakatoa_GUI_Partition, 
		Krakatoa_GUI_MatteObjects, 
		Krakatoa_GUI_AmbientPME
		--Krakatoa_GUI_ThinkingParticles,
		--Krakatoa_GUI_Shadows
	)
	
	--if Krakatoa_PresetDialogMode == #save and FranticParticleRenderMXS.LoadSave_SingleRollout != undefined and classof FranticParticleRenderMXS.LoadSave_SingleRollout== RolloutClass do
		--rootNodes = #(FranticParticleRenderMXS.LoadSave_SingleRollout)
	
	if Krakatoa_PresetDialogMode == #save do
	(
		FranticParticleRenderMXS.addChildren tv theRoot rootNodes Krakatoa_Gui_floater 
	)	
	if Krakatoa_PresetDialogMode == #load or Krakatoa_PresetDialogMode == #loadHistory do
	(
		if Krakatoa_SavePresetDialog.ddl_presetsToLoad.selected != undefined then 
		(
			theCategories = getIniSetting Krakatoa_PresetIniFile 
			rootNodes = for o in rootNodes where findItem theCategories o.name > 0 collect o
			FranticParticleRenderMXS.addChildren tv theRoot rootNodes Krakatoa_Gui_floater 
		)	
	)	
	theRoot.tag = dotNetMXSValue tagCounter 			
	theRoot.expand()
	FranticParticles.LogDebug ("  +TreeView POPULATED in " + (timestamp()-st) as string + " milliseconds." )
),

fn loadSaveButtonPressed =
(
	if Krakatoa_PresetDialogMode == #save do
	(
		deleteFile Krakatoa_PresetIniFile
		exportCurrentRollout = false
		for o = 1 to Krakatoa_ObjectsTable.count do
		(
			theRollout = Krakatoa_ObjectsTable[o][1]
			theControl = Krakatoa_ObjectsTable[o][2]
			if theRollout == undefined do exportCurrentRollout = Krakatoa_DoExportTable[o]
			if exportCurrentRollout and theRollout != undefined and Krakatoa_DoExportTable[o] == true do
			(
				case (classof theControl) of
				(
					SpinnerControl: setIniSetting Krakatoa_PresetIniFile theRollout.name theControl.name (theControl.value as string)
					CheckButtonControl: setIniSetting Krakatoa_PresetIniFile theRollout.name theControl.name (theControl.state as string)
					ColorPickerControl: setIniSetting Krakatoa_PresetIniFile theRollout.name theControl.name (theControl.color as string)
					ComboBoxControl: setIniSetting Krakatoa_PresetIniFile theRollout.name theControl.name theControl.selected
					ListBoxControl: (
							if theControl == Krakatoa_GUI_MatteObjects.lbx_useNamedSelectionSets do
							(
								txt = "#("
								if theControl.items.count > 0 do
								(
									for i = 1 to theControl.items.count-1 do txt += "\"" + theControl.items[i] as string + "\","
									txt += "\"" + theControl.items[theControl.items.count] as string + "\""
								)	
								txt += ")"
								setIniSetting Krakatoa_PresetIniFile theRollout.name theControl.name txt 
							)	
						)					
					PickerControl: (
								)								
					MultiListBoxControl: (
							if theControl == Krakatoa_GUI_SaveParticles.lbx_activeChannels do
							(
								setIniSetting Krakatoa_PresetIniFile theRollout.name theControl.name (FranticParticles.getProperty "ActiveParticleChannels")
							)							
						)
					
					EditTextControl: (
										if theControl != Krakatoa_GUI_Notes.edt_userNotes AND theControl != Krakatoa_GUI_MatteObjects.edt_createNewSelSet then
											setIniSetting Krakatoa_PresetIniFile theRollout.name theControl.name theControl.text
									)	
				)--end case
			)
		)--end o loop
		FranticParticleRenderMXS.saveSceneInfo Krakatoa_PresetIniFile	
		try(Krakatoa_GUI_Presets.btn_update.pressed())catch()		
		FranticParticleRenderMXS.LoadSave_SingleRollout = undefined
	)--end save
		
	if Krakatoa_PresetDialogMode == #load or Krakatoa_PresetDialogMode == #loadHistory do
	(
			exportCurrentRollout = false
			for o = 1 to Krakatoa_ObjectsTable.count do
			(
				theRollout = Krakatoa_ObjectsTable[o][1]
				theControl = Krakatoa_ObjectsTable[o][2]
				if theRollout == undefined do exportCurrentRollout = Krakatoa_DoExportTable[o]
				if exportCurrentRollout and theRollout != undefined and Krakatoa_DoExportTable[o] == true do
				(
					theValue = getIniSetting Krakatoa_PresetIniFile theRollout.name theControl.name
					case (classof theControl) of
					(
						SpinnerControl: (
										if theValue != "" do try(theControl.changed (theControl.value = execute theValue))catch()
									)
						CheckButtonControl: (
										if theValue != "" do try(theControl.changed (theControl.state = execute theValue))catch()
									)			
						ColorPickerControl: (
										if theValue != "" do try(theControl.changed (theControl.color = execute theValue))catch()
									)	
						PickerControl: (
									)												
						MultiListBoxControl: (
										if theControl == Krakatoa_GUI_SaveParticles.lbx_activeChannels do
										(
											try
											(
												FranticParticles.setProperty "ActiveParticleChannels" theValue
												Krakatoa_GUI_SaveParticles.populateLists()
											)catch()
										)								
									)												
						ComboBoxControl: (
										if theValue != "" do 
										(
											try(
												theFN = execute (theRollout.name +"." + theControl.name + "_SelectedFN")
												theFN (theControl.selection = findItem theControl.items theValue)
											)catch()
										)			
									)		
						ListBoxControl: (
							if theControl == Krakatoa_GUI_MatteObjects.lbx_useNamedSelectionSets do
							(
								try(Krakatoa_GUI_MatteObjects.lbx_useNamedSelectionSets.items = execute theValue; Krakatoa_GUI_MatteObjects.saveSelectionSets())catch()
							)	
						)		
						EditTextControl: 
						(
							if theControl != Krakatoa_GUI_Notes.edt_userNotes AND theControl  != Krakatoa_GUI_MatteObjects.edt_createNewSelSet do
								try(theControl.changed (theControl.text = theValue))catch()
						)					
					)	
				)
			)--end o loop
			local allRollouts = #(
				Krakatoa_GUI_RenderGlobalValues,
				Krakatoa_GUI_Main, 
				Krakatoa_GUI_SaveParticles,
				Krakatoa_GUI_Channels, 
				Krakatoa_GUI_Partition, 
				Krakatoa_GUI_MatteObjects, 
				Krakatoa_GUI_AmbientPME
				--Krakatoa_GUI_ThinkingParticles,
				--Krakatoa_GUI_Shadows
			)				
			for i in allRollouts do try(i.Refresh_GUI())catch()
			FranticParticleRenderMXS.defineShaderRollout (FranticParticles.GetProperty "PhaseFunction")			
	)--end load
	try(destroyDialog Krakatoa_SavePresetDialog)catch()
),

fn compareFN v1 v2 valArray: =
(
	if valArray[v1] > valArray[v2] then 1 else -1
),

fn sortFilesByDate theFiles feedback:#none=
(
	if theFiles.count == 0 do return #()
	
	local theYearIndex = 3 --init. a variable to store the position of the year
	local theMonthIndex = 1 --init. a variable to store the position of the month
	local theDayIndex = 2 --init. a variable to store the position of the day
	--collect all creation dates as string-filtered arrays
	if feedback == #history do Krakatoa_GUI_FileSortingProgress_Dialog.lbl_feedback.text = "Collecting File Creation Dates..."
	theFileDates = for f in theFiles collect filterString (getFileCreateDate f) " /\\:.;_"
	
	if feedback == #history do Krakatoa_GUI_FileSortingProgress_Dialog.lbl_feedback.text = "Collecting Indices For Sorting..."
	indexArray = for i = 1 to theFileDates.count collect i --collect indices for qsorting
	
	--add a leading zero to any entries with just 1 character
	if feedback == #history do Krakatoa_GUI_FileSortingProgress_Dialog.lbl_feedback.text = "Adding Leading Zeros..."
	for f = 1 to theFileDates.count do for i = 1 to theFileDates[f].count do if theFileDates[f][i].count == 1 do theFileDates[f][i] = "0" + theFileDates[f][i]
	--add 12 to the hours if the last entry is PM
	if feedback == #history do Krakatoa_GUI_FileSortingProgress_Dialog.lbl_feedback.text = "Converting to 24 Hours Format..."
	for f = 1 to theFileDates.count where try(matchPattern theFileDates[f][7] pattern:"PM")catch(false) do theFileDates[f][4] = (execute theFileDates[f][4] + 12) as string
	--go through all elements of the first date and find the position of the entry with 4 digits - that should be the year
	
--REMOVED, CREATION DATE APPEARS TO BE CONSISTENT BETWEEN WINDOWS INSTALLATIONS
	--for i = 1 to theFileDates[1].count where theFileDates[1][i].count == 4 do theYearIndex = i
	
--REMOVED, CREATION DATE APPEARS TO BE CONSISTENT BETWEEN WINDOWS INSTALLATIONS
	--go through all arrays until a monthIndex is resolved
	/*
	for f in theFileDates while theMonthIndex == 0 do
	(
		case theYearIndex of
		(
			1: ( --if the year is the first entry, look for second and third entry greater than 12 - that would be the day
				if execute f[2] > 12 do (theMonthIndex = 3; theDayIndex = 2)
				if execute f[3] > 12 do (theMonthIndex = 2; theDayIndex = 3)
			)
			3: (--if the year is the third entry, lool for first and second entry greater than 12 - that would be the day
				if execute f[1] > 12 do (theMonthIndex = 2; theDayIndex = 1)
				if execute f[2] > 12 do (theMonthIndex = 1; theDayIndex = 2)
			)
		)--end case
	)--end f loop
	*/
	--now collect all 6 elements based on the indices we detected as a single string - year first, then month, then day, then time
	if feedback == #history do Krakatoa_GUI_FileSortingProgress_Dialog.lbl_feedback.text = "Building Array For Sorting..."
	theFileDates = for f in theFileDates collect f[theYearIndex]+f[theMonthIndex]+f[theDayIndex]+f[4]+f[5]+f[6]
	--qsort the index array by passing the array of date strings as value array for comparisson
	if feedback == #history do Krakatoa_GUI_FileSortingProgress_Dialog.lbl_feedback.text = "Sorting History By Creation Date..."
	qsort indexArray FranticParticleRenderMXS.compareFN valArray:theFileDates
	--finally, use the sorted index array to collect and return the files in the inverse creation order - newest on top:
	if feedback == #history do Krakatoa_GUI_FileSortingProgress_Dialog.lbl_feedback.text = "Collecting Sorted Results..."
	for i in indexArray collect theFiles[i]
),

fn presetToLoadDDLSelected itm =
(
	if itm > 0 then
	(
		if Krakatoa_PresetDialogMode == #load do 
			Krakatoa_PresetIniFile = (Krakatoa_PresetsDirectory + "\\presets\\" + Krakatoa_SavePresetDialog.ddl_presetsToLoad.selected + ".KrakatoaPreset")
			
		if Krakatoa_PresetDialogMode == #loadHistory do 
			Krakatoa_PresetIniFile = (Krakatoa_PresetsDirectory + "\\history\\" + Krakatoa_SavePresetDialog.ddl_presetsToLoad.selected + ".KrakatoaSettings")
		
		if doesFileExist Krakatoa_PresetIniFile then
		(
			Krakatoa_SavePresetDialog.btn_loadsave.enabled = true
			--FranticParticleRenderMXS.initTreeView Krakatoa_SavePresetDialog.dn_tv 
		)	
		else
		(
			Krakatoa_SavePresetDialog.btn_loadsave.enabled = false
		)	
	)	
	else	
	(
		Krakatoa_PresetIniFile = ""
		Krakatoa_SavePresetDialog.btn_loadsave.enabled = false
	)	
	local theShadingMode = getIniSetting Krakatoa_PresetIniFile "Krakatoa_GUI_Main" "ddl_shadingMode"
	if theShadingMode != "" do FranticParticleRenderMXS.defineShaderRollout theShadingMode 
	FranticParticleRenderMXS.initTreeView Krakatoa_SavePresetDialog.dn_tv 
	FranticParticleRenderMXS.fillInTreeView Krakatoa_SavePresetDialog.dn_tv 
),

fn loadSaveDialogOpen =
(
	local st = timestamp()
	FranticParticles.LogDebug (">Opening Load/Save Dialog...")
	case Krakatoa_PresetDialogMode of
	(
		#load: 
		(
			Krakatoa_SavePresetDialog.title = "Krakatoa: LOAD Render Preset"
			Krakatoa_SavePresetDialog.btn_loadsave.caption = "LOAD PRESET..." 
			Krakatoa_SavePresetDialog.lbl_edittext.text = "Filter Pattern:"
			theFiles = getFiles (Krakatoa_PresetsDirectory + "\\presets\\"+ FranticParticleRenderMXS.PresetFilterString +"*.KrakatoaPreset")
			if theFiles.count == 0 then 
			(
				Krakatoa_SavePresetDialog.btn_loadsave.enabled = false
				Krakatoa_SavePresetDialog.ddl_presetsToLoad.items = #()
			)	
			else
			(
				theFiles = FranticParticleRenderMXS.sortFilesByDate theFiles 
				Krakatoa_SavePresetDialog.ddl_presetsToLoad.items = for f in theFiles collect getFileNameFile f
				if Krakatoa_GUI_Presets.rad_files01.state == 1 then
				(
					try		
						Krakatoa_SavePresetDialog.ddl_presetsToLoad.selection = findItem Krakatoa_SavePresetDialog.ddl_presetsToLoad.items Krakatoa_GUI_Presets.ddl_historyFiles01.selected
					catch
						Krakatoa_SavePresetDialog.ddl_presetsToLoad.selection = 1
				)
				else
					Krakatoa_SavePresetDialog.ddl_presetsToLoad.selection = 1
				
				FranticParticleRenderMXS.presetToLoadDDLSelected Krakatoa_SavePresetDialog.ddl_presetsToLoad.selection
				
				Krakatoa_PresetIniFile = (Krakatoa_PresetsDirectory + "\\presets\\" + Krakatoa_SavePresetDialog.ddl_presetsToLoad.selected + ".KrakatoaPreset")
			)	
			FranticParticles.LogDebug ("  +Load Preset Dialog OPENED in " + (timestamp()-st) as string + " milliseconds.")
		)
		#loadHistory: 
		(
			Krakatoa_SavePresetDialog.title = "Krakatoa: LOAD Render History Settings:"
			Krakatoa_SavePresetDialog.btn_loadsave.caption = "LOAD HISTORY..." 
			Krakatoa_SavePresetDialog.lbl_edittext.text = "Filter Pattern:"
			--theFiles = getFiles (Krakatoa_PresetsDirectory + "\\history\\"+FranticParticleRenderMXS.PresetFilterString+ "*.KrakatoaSettings")
			theFiles = deepCopy Krakatoa_GUI_Presets.theHistoryFiles --using the History Cache to speed up access.
			if theFiles.count == 0 then 
			(
				Krakatoa_SavePresetDialog.btn_loadsave.enabled = false
				Krakatoa_SavePresetDialog.ddl_presetsToLoad.items = #()
			)	
			else
			(
				--theFiles = FranticParticleRenderMXS.sortFilesByDate theFiles 
				Krakatoa_SavePresetDialog.ddl_presetsToLoad.items = theFiles --for f in theFiles collect getFileNameFile f
				Krakatoa_SavePresetDialog.ddl_presetsToLoad.selection = 1	
				if Krakatoa_GUI_Presets.open and Krakatoa_GUI_Presets.rad_files01.state == 2 do
					try		
						Krakatoa_SavePresetDialog.ddl_presetsToLoad.selection = findItem Krakatoa_SavePresetDialog.ddl_presetsToLoad.items Krakatoa_GUI_Presets.ddl_historyFiles01.selected
					catch()
							
				Krakatoa_PresetIniFile = (Krakatoa_PresetsDirectory + "\\history\\" + Krakatoa_SavePresetDialog.ddl_presetsToLoad.selected + ".KrakatoaSettings")
				FranticParticles.LogDebug ("  +Load History Dialog OPENED in " + (timestamp()-st) as string + " milliseconds.")
			)	
		)					
		#save: 
		(
			theFiles = getFiles (Krakatoa_PresetsDirectory + "\\presets\\*.KrakatoaPreset")
			theFiles = FranticParticleRenderMXS.sortFilesByDate theFiles 
			Krakatoa_SavePresetDialog.ddl_presetsToLoad.items = for f in theFiles collect getFileNameFile f
		
			Krakatoa_SavePresetDialog.title = "Krakatoa: SAVE Render Preset"
			Krakatoa_SavePresetDialog.btn_loadsave.caption = "SAVE PRESET..." 
			Krakatoa_SavePresetDialog.lbl_edittext.text = "Preset Name:"
			local thePresetFileName = if maxFileName != "" then (getFileNameFile maxFileName) else "Preset"
			if FranticParticleRenderMXS.LoadSave_SingleRollout != undefined do thePresetFileName += "_" + FranticParticleRenderMXS.fixTimeString FranticParticleRenderMXS.LoadSave_SingleRollout.title
			Krakatoa_SavePresetDialog.edt_presetsToSave.text = thePresetFileName
			Krakatoa_PresetIniFile = (Krakatoa_PresetsDirectory + "\\presets\\" + Krakatoa_SavePresetDialog.edt_presetsToSave.text + ".KrakatoaPreset")
			FranticParticles.LogDebug ("  +Save Preset Dialog OPENED in " + (timestamp()-st) as string + " milliseconds.")
		)
	)		
),

fn UpdateAllHiddenRollouts =
(
	Krakatoa_CustomizeRollouts_Dialog.updateHidden()
),

fn displaySavePresetDialog =
(
	local st = timestamp()
	try(destroyDialog Krakatoa_SavePresetDialog)catch()
	rollout Krakatoa_SavePresetDialog "" 
	(
		dotNetControl dn_tv "TreeView" width:590 height:590 align:#center
		
		button btn_cancel "Cancel" height:40 width:60 align:#left across:2 offset:[-5,-3]
		button btn_loadsave "SAVE PRESET..." height:40 width:100 align:#right offset:[5,-3]
		label lbl_edittext "Filter Pattern:" pos:[75,598]
		edittext edt_presetsToSave text:"" width:347 pos:[136,597]
		dropdownlist ddl_presetsToLoad width:410 pos:[75,616]
			
		on btn_cancel pressed do 
		(
			try(destroyDialog Krakatoa_SavePresetDialog)catch()
			FranticParticleRenderMXS.defineShaderRollout (FranticParticles.GetProperty "PhaseFunction")	
		)

		on btn_loadsave pressed do FranticParticleRenderMXS.loadSaveButtonPressed()

		on dn_tv AfterCheck arg do
			if arg.node.tag != undefined do 
				Krakatoa_DoExportTable[arg.node.tag.value] = arg.node.checked

		on edt_presetsToSave entered txt do 
		(
			if Krakatoa_PresetDialogMode == #save then
				Krakatoa_PresetIniFile = (Krakatoa_PresetsDirectory + "/presets/" + txt + ".KrakatoaPreset") 
		)
		
		on edt_presetsToSave changed txt do 
		(
			if Krakatoa_PresetDialogMode != #save then
			(
				FranticParticleRenderMXS.PresetFilterString = txt
				FranticParticleRenderMXS.loadSaveDialogOpen()
				FranticParticleRenderMXS.presetToLoadDDLSelected ddl_presetsToLoad.selection
			)				
		)		
		
		on ddl_presetsToLoad selected itm do 
		(
			if Krakatoa_PresetDialogMode == #save then
				edt_presetsToSave.entered (edt_presetsToSave.text = ddl_presetsToLoad.selected)
			else
				FranticParticleRenderMXS.presetToLoadDDLSelected itm
		)	
			
		on Krakatoa_SavePresetDialog open do 
		(
			if Krakatoa_PresetDialogMode != #save do edt_presetsToSave.text = FranticParticleRenderMXS.PresetFilterString 
			FranticParticleRenderMXS.loadSaveDialogOpen()
			FranticParticleRenderMXS.initTreeView dn_tv
			FranticParticleRenderMXS.fillInTreeView dn_tv
		)
	)
	createDialog Krakatoa_SavePresetDialog 600 640 --modal:true	
	FranticParticles.LogDebug ("  +Dialog Using DotNet TreeView Control CREATED in " + (timestamp()-st) as string + " milliseconds.")

),


fn compareSettings theFile1 theFile2 =
(
	FranticParticles.LogDebug ">FN CompareSettings() Called."
	FranticParticles.LogDebug ("   File 1: [" + filenamefrompath theFile1 + "]")
	FranticParticles.LogDebug ("   File 2: [" + filenamefrompath theFile2 + "]")
	
	theDiffsArray = #()
	theCats1 = for i in getIniSetting theFile1 where i != "SceneInfo" and i != "SampleImage" collect i
	theCats2 = for i in getIniSetting theFile2 where i != "SceneInfo" and i != "SampleImage" collect i
	for c in theCats1 do
	(
		theKeys1 = (getIniSetting theFile1 c)
		theKeys2 = (getIniSetting theFile2 c)
		for k in theKeys1 do
		(
			theVal1 = getIniSetting theFile1 c k
			if findItem theKeys2 k == 0 then
			(
				append theDiffsArray #(c, k, theVal1, "no such key" )
			)
			else
			(
				theVal2 = getIniSetting theFile2 c k
				if theVal1 != theVal2 then
					append theDiffsArray #(c, k, theVal1, theVal2)
			)	
		)
		for k in theKeys2 do
		(
			theVal2 = getIniSetting theFile2 c k
			if findItem theKeys1 k == 0 then
				append theDiffsArray #(c, k, "no such key", theVal2 )
		)	
	)	
	for c in theCats2 do
	(
		if findItem theCats1 c == 0 then
		(
			theKeys2 = (getIniSetting theFile2 c)
			for k in theKeys2 do
			(
				theVal2 = getIniSetting theFile2 c k
				append theDiffsArray #(c, k, "no such key", theVal2 )
			)	
		)
	)
	case of
	(
		(theDiffsArray.count == 0): (FranticParticles.LogDebug ("  +CompareSettings Function Finished. No Differences Found."))
		(theDiffsArray.count == 1): (FranticParticles.LogDebug ("  +CompareSettings Function Finished. One Difference Found."))
		(theDiffsArray.count > 1): (FranticParticles.LogDebug ("  +CompareSettings Function Finished. " + theDiffsArray.count as string +" Differences Found."))
	)	
	theDiffsArray 
),

fn floatOrDockRollout theRollout forceMode:#none =
(
	local st1 = timestamp()
	
	local okToCloseCompletely = #(
			--Krakatoa_GUI_Presets, 
			--Krakatoa_GUI_Channels, 
			Krakatoa_GUI_Particles,
			Krakatoa_GUI_ParticleLoaders, 
			Krakatoa_GUI_ThinkingParticles,
			--Krakatoa_GUI_Shadows,
			--Krakatoa_GUI_Preferences, 
			Krakatoa_GUI_Notes, 
			Krakatoa_GUI_About		
	)
	
	local currentVisibility = execute (getIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "RolloutVisible" theRollout.title ) 
	if currentVisibility == false or forceMode==#hide do
	(
		try(removeRollout theRollout Krakatoa_Gui_floater)catch()
		try(removeRollout theRollout Krakatoa_Gui_floater_2)catch()
		try(destroyDialog theRollout)catch()
		setIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "RolloutVisible" theRollout.title "false"
		--if findItem okToCloseCompletely theRollout == 0 do 
		addRollout theRollout Krakatoa_Gui_floater_3 rolledup:true
		return true
	)
	
	FranticParticles.LogDebug ("+floatOrDockRollout Step 1: " + (timestamp() - st1) as string + " milliseconds."	)	
	local st1 = timestamp()
	
	--if currentVisibility == false then return false
	local currentState =  execute (getIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "RolloutDocked" theRollout.title ) 
	
	
	if currentState == OK do currentState = true
		
	if (currentState and forceMode == #none) or forceMode == #float then --if it is docked and no forcing was requested, or if floating was requested,
	(
		try(removeRollout theRollout Krakatoa_Gui_floater)catch()
		try(removeRollout theRollout Krakatoa_Gui_floater_2)catch()
		try(destroyDialog theRollout)catch()
		local thePos = execute (getIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "RolloutDialogPositions" theRollout.title) 
		if thePos != OK then
		(
			thePos = FranticParticleRenderMXS.AdjustDialogPositionOnDesktop thePos 470 400	dialogName:(theRollout.title+" Dialog")
			createDialog theRollout style:#(#style_titlebar,#style_minimizebox,#style_sysmenu) pos:thePos
		)	
		else
			createDialog theRollout style:#(#style_titlebar,#style_minimizebox,#style_sysmenu)
		
		setIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "RolloutDocked" theRollout.title "false"
		setIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "RolloutVisible" theRollout.title "true"
		try(theRollout.btn_Float_Rollout.text = "<")catch()
		try(theRollout.btn_Float_Rollout.images = #(Krakatoa_PresetsArrowBitmap,Krakatoa_PresetsArrowBitmap, 32,5,5,5,5))catch()
		try(if Krakatoa_Gui_floater_2.rollouts.count == 0 do closeRolloutFloater Krakatoa_Gui_floater_2)catch()
	)
	
	FranticParticles.LogDebug ("+floatOrDockRollout Step 2: " + (timestamp() - st1) as string + " milliseconds."	)	
	local st1 = timestamp()
	
	
	if (not currentState and forceMode == #none) or forceMode == #dock then --if floater and no docking requested, or if docking was forced,
	(
		
		local st2 = timestamp()
		
		try(destroyDialog theRollout)catch()
		try(removeRollout theRollout Krakatoa_Gui_floater)catch()
		try(removeRollout theRollout Krakatoa_Gui_floater_2)catch()
		FranticParticles.LogDebug ("+floatOrDockRollout Removing Rollout From Floater took " + (timestamp() - st2) as string + " milliseconds."	)	
		local st2 = timestamp()

		
		try (addRollout theRollout Krakatoa_Gui_floater rolledup:true)catch()
		FranticParticles.LogDebug ("+floatOrDockRollout Adding Rollout To Floater took " + (timestamp() - st2) as string + " milliseconds."	)	
		local st2 = timestamp()
		
		setIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "RolloutDocked" theRollout.title "true"
		setIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "RolloutDockHost" theRollout.title "1"
		setIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "RolloutVisible" theRollout.title "true"
		try(theRollout.btn_Float_Rollout.text = ">")catch()
		try(theRollout.btn_Float_Rollout.images = #(Krakatoa_PresetsArrowBitmap,Krakatoa_PresetsArrowBitmap, 32,4,4,4,4))catch()
		try(if Krakatoa_Gui_floater_2.rollouts.count == 0 do closeRolloutFloater Krakatoa_Gui_floater_2)catch()
		FranticParticles.LogDebug ("+floatOrDockRollout Finishing took " + (timestamp() - st2) as string + " milliseconds."	)	
	)
	
	FranticParticles.LogDebug ("+floatOrDockRollout Step 3: " + (timestamp() - st1) as string + " milliseconds."	)	
	local st1 = timestamp()
	
	
	if forceMode == #dock2 then --if docking to Secondary Floater was forces,
	(
		try(destroyDialog theRollout)catch()
		try(removeRollout theRollout Krakatoa_Gui_floater)catch()
		try(removeRollout theRollout Krakatoa_Gui_floater_2)catch()
		
		if Krakatoa_Gui_floater_2 == undefined or Krakatoa_Gui_floater_2.open == false do 
		(
			theSize = execute (FranticParticles.GetProperty "GUI:Size")	
			--theKVersion = substituteString FranticParticles.Version "1.6.80" "2.0.0"
			theKVersion = FranticParticles.Version 
			Krakatoa_Gui_floater_2 = NewRolloutFloater ("Krakatoa v" + theKVersion +" - Secondary Floater") theSize.x theSize.y (Krakatoa_Gui_floater.pos.x+theSize.x+14)  Krakatoa_Gui_floater.pos.y
		)	
		try(addRollout theRollout Krakatoa_Gui_floater_2 rolledup:true)catch()
		setIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "RolloutDocked" theRollout.title "true"
		setIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "RolloutDockHost" theRollout.title "2"
		setIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "RolloutVisible" theRollout.title "true"
		try(theRollout.btn_Float_Rollout.text = "<")catch()
		try(theRollout.btn_Float_Rollout.images = #(Krakatoa_PresetsArrowBitmap,Krakatoa_PresetsArrowBitmap, 32,5,5,5,5))catch()
	)	
	FranticParticles.LogDebug ("+floatOrDockRollout Step 4: " + (timestamp() - st1) as string + " milliseconds."	)	
	local st1 = timestamp()
	
	Krakatoa_CustomizeRollouts_Dialog.updateStripsPositions [0,0]
	
	FranticParticles.LogDebug ("+floatOrDockRollout Step 5: " + (timestamp() - st1) as string + " milliseconds."	)	
),

fn FloatRolloutButtonPressed theRollout =
(
	if keyboard.shiftPressed then 
	(	
		if theRollout.inDialog then
			FranticParticleRenderMXS.floatOrDockRollout theRollout forceMode:#dock2
		else if findItem Krakatoa_GUI_Floater.rollouts theRollout == 0 then
			FranticParticleRenderMXS.floatOrDockRollout theRollout forceMode:#dock
		else if findItem Krakatoa_GUI_Floater_2.rollouts theRollout == 0 do
			FranticParticleRenderMXS.floatOrDockRollout theRollout forceMode:#dock2
	)	
	else if keyboard.controlPressed then
	(
		try(destroyDialog theRollout)catch()
		try(removeRollout theRollout Krakatoa_Gui_floater)catch()
		try(removeRollout theRollout Krakatoa_Gui_floater_2)catch()		
		setIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "RolloutVisible" theRollout.title "false"
		try(if Krakatoa_Gui_floater_2.rollouts.count == 0 do closeRolloutFloater Krakatoa_Gui_floater_2)catch()
	)
	else
		FranticParticleRenderMXS.floatOrDockRollout theRollout
	Krakatoa_CustomizeRollouts_Dialog.Refresh_GUI()			
),

fn rebuildPathsCache searchKey =
(
	FranticParticles.LogDebug (">FN rebuildPathsCache() Called For ["+searchKey+"]")
	local st = timestamp()
	local allPaths = #()
	local allValues = #()
	local theCacheFile = (Krakatoa_PresetsDirectory+"\\_HistoryCache.List")
	if not doesFileExist theCacheFile do Krakatoa_GUI_Presets.rebuildHistoryCache()
	local theHistoryCache = openFile theCacheFile
	local theHistoryFiles = #()
	seek theHistoryCache #eof
	local maxlen=filepos theHistoryCache
	seek theHistoryCache 0
	local res = readChars theHistoryCache maxlen errorAtEOF:false
	close theHistoryCache
	local theLinesArray = filterString res "\n"

	local cnt = 0
	for aFile in theLinesArray do
	(
		cnt+=1
		pushPrompt (cnt as string + " of " + theLinesArray.count as string + " History Records (" + (100.0*cnt/theLinesArray.count) as string + "%) Processed...")
		local f =  ( Krakatoa_PresetsDirectory + "\\history\\" + aFile + ".KrakatoaSettings")
		if (thePath = (getIniSetting f "SceneInfo" searchKey)) != "" do 
		(
			if findItem allValues thePath == 0 then
			(
				append allPaths (getIniSetting f "SceneInfo" "ParticleFiles")
				append allValues thePath
			)
		)	
	)	
	
	local thePathsCacheFile = Krakatoa_PresetsDirectory + "\\Paths_"+searchKey+".Cache"
	for i = 1 to allValues.count do 
	(
		setIniSetting thePathsCacheFile searchKey allValues[i] allValues[i]
		setIniSetting thePathsCacheFile searchKey ("("+allValues[i]+")_Paths") allPaths[i]  
	)
	
	FranticParticles.LogProgress (">History Cache contained " + theLinesArray.count as string + " Records."  )
	FranticParticles.LogProgress ("+History Dialog Opened in "+ (((timestamp()-st)/1000.0) as string + " seconds."))
	pushPrompt ("Cache Rebuilt in "+ (((timestamp()-st)/1000.0) as string + " seconds."))
	FranticParticles.LogDebug ">FN rebuildPathsCache() Ended"
),


fn addToPathsCache =
(
	FranticParticles.LogDebug ">FN addToPathsCache() Called"
	local theKeys = #("ParticleFiles", "ParticleFilesBase", "ParticleFilesProject", "ParticleFilesSequence", "ParticleFilesTake", "ParticleFilesName")
	for searchKey in theKeys do
	(
		local thePathsCacheFile = Krakatoa_PresetsDirectory + "\\Paths_"+searchKey+".Cache"
		if not doesFileExist thePathsCacheFile do 
			FranticParticleRenderMXS.rebuildPathsCache searchKey
		
		local theValue = FranticParticles.getProperty searchKey
		if getIniSetting thePathsCacheFile searchKey (theValue) == "" then
		(
			setIniSetting thePathsCacheFile searchKey theValue theValue
			setIniSetting thePathsCacheFile searchKey ("("+theValue+")_Paths") (FranticParticles.getProperty "ParticleFiles")
		)
	)
	FranticParticles.LogDebug ">FN addToPathsCache() Ended"
),


fn rebuildValueCache title rolloutSignature searchKey =
(
	FranticParticles.LogDebug ">FN rebuildValueCache() Called"
	local st = timestamp()
	local allPaths = #()
	local allValues = #()	
	
	local theCacheFile = (Krakatoa_PresetsDirectory+"\\_HistoryCache.List")
	if not doesFileExist theCacheFile do Krakatoa_GUI_Presets.rebuildHistoryCache()
	local theHistoryCache = openFile theCacheFile
	local theHistoryFiles = #()
	seek theHistoryCache #eof
	local maxlen=filepos theHistoryCache
	seek theHistoryCache 0
	local res = readChars theHistoryCache maxlen errorAtEOF:false
	close theHistoryCache
	local theLinesArray = filterString res "\n"
	try(destroyDialog Krakatoa_GUI_Value_History_Dialog )catch()

	local cnt = 0
	for aFile in theLinesArray do
	(
		cnt+=1
		pushPrompt (cnt as string + " of " + theLinesArray.count as string + " History Records (" + (100.0*cnt/theLinesArray.count) as string + "%) Processed...")
		local f =  ( Krakatoa_PresetsDirectory + "\\history\\" +  aFile + ".KrakatoaSettings")
		if (theVal = (getIniSetting f rolloutSignature searchKey)) != "" do 
		(
			local theIndex = findItem allValues theVal 
			if theIndex == 0 then
			(
				append allPaths #(aFile)
				append allValues theVal
			)
			else
			(
				append allPaths[theIndex] aFile
			)
		)	
	)	
	local theValueCacheFile = (Krakatoa_PresetsDirectory + "\\"+title+".Cache")
	for i = 1 to allValues.count do 
	(
		setIniSetting theValueCacheFile title allValues[i] allValues[i]
		local thePathsString = ""
		for p in allPaths[i] do thePathsString+=p+"|"
		setIniSetting theValueCacheFile title (allValues[i]+"_Paths") thePathsString  
	)
	FranticParticles.LogDebug (">History Cache contained " + theLinesArray.count as string + " Records."  )
	FranticParticles.LogProgress ("+Value Cache Rebuilt in "+ (((timestamp()-st)/1000.0) as string + " sec."))
	pushPrompt ("Value Cache Rebuilt in "+ (((timestamp()-st)/1000.0) as string + " sec."))
	FranticParticles.LogDebug ">FN rebuildValueCache() Ended"
),

fn addValueToKrakatoaHistoryCache title theValue theFileName rolloutSignature searchKey =
(
	FranticParticles.LogDebug ">FN addValueToKrakatoaHistoryCache() called"
	local allPaths = #()
	local allValues = #()	
	local theValueCacheFile = (Krakatoa_PresetsDirectory + "\\"+title+".Cache")
	if not doesFileExist theValueCacheFile then 
		rebuildValueCache title rolloutSignature searchKey
	else
		FranticParticles.LogDebug ("Value Cache File ["+title+"] Exists.")
		
	if getIniSetting theValueCacheFile title theValue == "" then
	(
		setIniSetting theValueCacheFile title theValue theValue 
		setIniSetting theValueCacheFile title (theValue + "_Paths") ((getFileNameFile theFileName) + "|") 
		FranticParticles.LogDebug ("Value ["+theValue+ "] Does Not Exist In Cache, Adding Value and Path Records...")
	)
	else
	(
		local theString = getIniSetting theValueCacheFile title (theValue + "_Paths")
		theString += (getFileNameFile theFileName) + "|"
		setIniSetting theValueCacheFile title (theValue + "_Paths") theString 
		FranticParticles.LogDebug ("Value ["+theValue+ "] Exists In Cache, Adding Path Record...")
	)
	FranticParticles.LogDebug ">FN addValueToKrakatoaHistoryCache() Ended"
),

fn getValueFromKrakatoaHistory rolloutSignature searchKey title originalValue pos:[100,100] =
(
	FranticParticles.LogDebug ">FN getValueFromKrakatoaHistory() called"
	local st = timestamp()
	local allPaths = #()
	local allValues = #()
	
	local theValueCacheFile = (Krakatoa_PresetsDirectory + "\\"+title+".Cache")
	if not doesFileExist theValueCacheFile or keyboard.shiftPressed do 
	(
		deleteFile theValueCacheFile
		FranticParticleRenderMXS.rebuildValueCache title rolloutSignature searchKey
	)
		
	local theKeys = getIniSetting theValueCacheFile title
	for k in theKeys where not matchPattern k pattern:"*_Paths" do
	(
		append allValues k
		append allPaths (for p in (filterString (getIniSetting theValueCacheFile title (k+"_Paths") ) "|" ) collect getFileNameFile p)
	)
	pushPrompt ("Value History Cache Loaded in "+ (((timestamp()-st)/1000.0) as string + " sec."))
	
	local txt = stringStream ""
	format "rollout Krakatoa_GUI_Value_History_Dialog \"Krakatoa Value History: [%]\" (\n" title to:txt
	local theX = 0
	local theY = 2
	if allValues.count > 0 do
	(
		local theClass = classof (execute allValues[1])
		if theClass == color do
		(
			format "dropdownlist ddl_info items:#() pos:[2,2] width:383\n" to:txt
			format "progressbar prg_color_0 width:382 height:20 value:100 pos:[2,24] color:%\n" originalValue to:txt
			format "on prg_color_0 clicked val do %.%.color = %\n" rolloutSignature searchKey originalValue to:txt
		)
		
		for i = 1 to allValues.count do
		(
			case theClass of
			(
				color: (
							local theColorString = allValues[i]
							if title == "Override Density Color" do
							(
								local theColor = execute allValues[i]
								theColorString = (color theColor.value theColor.value theColor.value) as string 
							)
					
							format "progressbar prg_color_% width:30 height:20 value:100 pos:[%,%] color:%\n" i (2+theX*32) (2+theY*22) theColorString to:txt
							format "on prg_color_% clicked val do (\n" i to:txt
							format "%.%.color = %\n" rolloutSignature searchKey theColorString to:txt
							with printAllElements on (format "ddl_info.items= %\n" (allPaths[i] as string) to:txt )
							format  "ddl_info.selection=1\n" to:txt
							format ")\n" to:txt
							theX += 1
							if theX >= 12 do 
							(
								theX = 0
								theY +=1
							)				
						)
			)
		)
		format "\n)" to:txt
		try(destroyDialog Krakatoa_GUI_Value_History_Dialog)catch()
		try
		(
			Krakatoa_GUI_Value_History_Dialog = execute (txt as string)
			createDialog Krakatoa_GUI_Value_History_Dialog width:386 pos:(pos+[20,-20]) style:#(#style_toolwindow,#style_sysmenu)
		)catch(messagebox "Failed To Create History Dialog..." title:"ERROR")
	)
),

fn getFileInfoDotNet theFileName =
(
	local fileLookup = dotnetobject "System.IO.DirectoryInfo" (getFileNamePath theFileName)
	local allMatchingFiles = #()
	try (
		allMatchingFiles = fileLookup.getFiles (filenamefrompath theFileName) 
	) catch()
	if allMatchingFiles.count == 1 then
	(
		local dotNetFile = allMatchingFiles[1]
		local fname = dotNetFile.FullName
		local date_ = dotNetFile.lastWriteTime.ToString()
		local size_ = dotNetFile.length
		#(fname, date_, size_)
	)
	else
		#()
),

fn calculateMemoryUsage theChannels =
(
	local totalBytes = 0
	local totalUnknownBytes = 0
	for channel in theChannels do 
	(
		local theBytes = 0
		local UnknownBytes = 0
		case channel[2] of 
		(
			"float16" : theBytes = 2
			"float32" : theBytes = 4
			"float64" : theBytes = 8
			"int8" : theBytes = 1
			"int16" : theBytes = 2
			"int32" : theBytes = 4
			"int64" : theBytes = 8
			"uint8" : theBytes = 1
			"uint16" : theBytes = 2
			"uint32" : theBytes = 4
			"uint64" : theBytes = 8
			"unknown" : unknownBytes = 6
			default : ()
		)
		totalBytes += (theBytes * channel[3] )
		totalUnknownBytes += unknownBytes
	)
	--totalBytes += 8 - mod totalBytes 8
	#(totalBytes, totalUnknownBytes)
),

fn underscoreString intext =
(
	local txt = copy intext
	local badStrings = "\\/:.,- "
	for i = 1 to txt.count do 
		if findString badStrings txt[i] != undefined do txt[i] = "_"
	txt	
),	

fn getShaderPropList theShaderName =
(
	case theShaderName of
	(
		default: (
			local controlsDefinition = #(
				#(#drawing, #group, 1, ""),
				#(#label, #none, 1, "Label01", "Isotropic Shading Does Not Expose Any Parameters.")
			)
		)
		"Henyey-Greenstein": (
				local controlsDefinition = #(
					#(#drawing, #group, 1, "Henyey-Greenstein Eccentricity Controls"),
					#(#channel, #float, 1, "Eccentricity", "[-1,1,0]", "0.1","Channel:Allocate:PhaseEccentricity","PhaseEccentricity")
				)
		)	
		"Schlick": (
				local controlsDefinition = #(
					#(#drawing, #group, 1, "Schlick Eccentricity Controls"),
					#(#channel, #float, 1, "Eccentricity", "[-1,1,0]", "0.1","Channel:Allocate:PhaseEccentricity","PhaseEccentricity")
				)
		)			
		"Phong Surface": (
				local controlsDefinition = #(
					#(#drawing, #group, 4, "Phong Surface Specularity Controls"),
					#(#renderelement, #boolean, 1, "Diffuse", "false", "Diffuse"),
					#(#renderelement, #boolean, 1, "Specular", "false", "Specular"),
					#(#channel, #float, 1, "SpecularPower", "[0,1000,10]", "0.1","Channel:Allocate:SpecularPower","Lighting:Specular:SpecularPower" ),--Shader:Kayjiya:SpecularPower:Enabled
					#(#channel, #float, 1, "SpecularLevel", "[0,100000,100]", "1.0","Channel:Allocate:SpecularLevel","Lighting:Specular:Level")
					--#(#channel, #float, 3, "SpecularColor", "red")
				)
		)
		"Kajiya-Kay Hair": (
				local controlsDefinition = #(
					#(#drawing, #group, 4, "Kajiya-Kai Hair Specularity Controls"),
					#(#renderelement, #boolean, 1, "Diffuse", "false", "Diffuse"),
					#(#renderelement, #boolean, 1, "Specular", "false", "Specular"),
					#(#channel, #float, 1, "SpecularPower", "[0,1000,10]", "0.1","Channel:Allocate:SpecularPower","Lighting:Specular:SpecularPower"),--Shader:Kayjiya:SpecularPower:Enabled
					#(#channel, #float, 1, "SpecularLevel", "[0,100000,100]", "1.0","Channel:Allocate:SpecularLevel","Lighting:Specular:Level")
					/*
					#(#drawing, #group, 6, "Just Some Demonstrations Of Other Control Types"),
					#(#channel, #float, 3, "SpecularColor", "red"),
					#(#parameter, #float, 1, "Float Parameter", "[-100,100,100]", "0.01"),
					#(#parameter, #float, 3, "Color Parameter", "[1,1,0.5]", ""),
					#(#parameter, #integer, 1, "Int. Parameter", "[-100,100,100]", "10"),
					#(#parameter, #dropdownlist, 1, "Some Drop-Down List", "#(\"First Option\",\"Second Option\",\"Third Option\",\"Yet Another Option\")"),
					#(#parameter, #boolean, 1, "Some Boolean Switch", "false")
					*/
				)
		)
		"Marschner Hair": (
				local controlsDefinition = #(
					#(#drawing, #group, 1, ""),
					#(#label, #none, 1, "Label01", "Marschner Hair Controls"),
					
					#(#drawing, #group, 4, "Specular Highlight 1"),
					#(#renderelement, #boolean, 1, "Specular", "false", "Specular"),
					#(#channel, #float, 1, "SpecularLevel", "[0,100000,25]", "1.0","Shader:Marschner Hair:SpecularLevel:Varying","Shader:Marschner Hair:SpecularLevel"),
					#(#channel, #float, 1, "SpecularGlossiness", "[0,1000,300]", "0.1","Shader:Marschner Hair:SpecularGlossiness:Varying","Shader:Marschner Hair:SpecularGlossiness"),
					#(#channel, #float, 1, "SpecularShift", "[-1,1,0.1]", "0.1","Shader:Marschner Hair:SpecularShift:Varying","Shader:Marschner Hair:SpecularShift"),
					
					#(#drawing, #group, 4, "Specular Highlight 2"),
					#(#renderelement, #boolean, 1, "Specular2", "false", "Specular2"),
					#(#channel, #float, 1, "Specular2Level", "[0,100000,90]", "1.0","Shader:Marschner Hair:Specular2Level:Varying","Shader:Marschner Hair:Specular2Level"),
					#(#channel, #float, 1, "Specular2Glossiness", "[0,1000,30]", "0.1","Shader:Marschner Hair:Specular2Glossiness:Varying","Shader:Marschner Hair:Specular2Glossiness"),
					#(#channel, #float, 1, "Specular2Shift", "[-1,1,-0.1]", "0.1","Shader:Marschner Hair:Specular2Shift:Varying","Shader:Marschner Hair:Specular2Shift"),
					
					#(#drawing, #group, 4, "Glint Highlight"),
					#(#renderelement, #boolean, 1, "Glint", "false", "Glint"),
					#(#channel, #float, 1, "GlintLevel", "[0,100000,400]", "1.0","Shader:Marschner Hair:GlintLevel:Varying","Shader:Marschner Hair:GlintLevel"),
					#(#channel, #float, 1, "GlintSize", "[0,360,0.5]", "0.1","Shader:Marschner Hair:GlintSize:Varying","Shader:Marschner Hair:GlintSize"),
					#(#channel, #float, 1, "GlintGlossiness", "[0,360,10]", "0.1","Shader:Marschner Hair:GlintGlossiness:Varying","Shader:Marschner Hair:GlintGlossiness"),
					
					#(#drawing, #group, 2, "Diffuse Component"),
					#(#renderelement, #boolean, 1, "Diffuse", "false", "Diffuse"),
					#(#channel, #float, 1, "DiffuseLevel", "[0,100,100]", "1.0","Shader:Marschner Hair:DiffuseLevel:Varying","Shader:Marschner Hair:DiffuseLevel")
				)
		)		
	)	
	controlsDefinition
),

fn checkForHairFarmEffect showMessage:true=
(
	local result = false
	for i = 1 to numAtmospherics do
	(
		theEffect = getAtmospheric i
		if classof theEffect == Hair_Farm_Renderer and not (IsActive theEffect) do result = true
	)
	if result and showMessage do 
	(
		editAtmosphere()
		messagebox "A DISABLED HairFarm Atmospheric Effect was detected in the Environment > Atmosphere Dialog!\n\nThis will cause HairFarm to produce NO HAIR without any warnings.\nPlease enable the effect or delete it completely to ensure correct hair generation!" title:"Krakatoa - Hair Farm"
	)
	result
),

fn initDynamicShaderProperties controlsDefinition theShaderName =
(

	local allPropNames = FranticParticleRenderMXS.getPropNames()
	
	for theDef in controlsDefinition do
	(
		case theDef[1] of
		(
			#renderelement:
			(
				local thePropName = if theDef[7] == undefined then
					"RenderElement:"+theShaderName+":"+theDef[4]+":Create"
				else
					theDef[7]
				
				try
					FranticParticles.GetProperty thePropName
				catch
				(
					FranticParticles.AddProperty thePropName theDef[5]
					if findItem allPropNames thePropName == 0 do append KrakatoaPropertiesList #(thePropName, theDef[5], true, false)
				)
			)
			#parameter:
			(
				case theDef[2] of
				(
					#boolean: 
					(
						local thePropName=("Shader:"+theShaderName+":"+theDef[4]+":State")
						try
							FranticParticles.GetProperty thePropName
						catch		
						(
							FranticParticles.AddProperty thePropName theDef[5]
							if findItem allPropNames thePropName == 0 do append KrakatoaPropertiesList #(thePropName, theDef[5], true, false)
						)
					)
					#float: 
					(
						case theDef[3] of
						(
						1: (
								local thePropName=("Shader:"+theShaderName+":"+theDef[4]+":Value")
								try
									FranticParticles.GetProperty thePropName
								catch
								(
									local theDefVal = (filterString theDef[5] "[],")[3]
									FranticParticles.AddProperty thePropName 
									if findItem allPropNames thePropName == 0 do append KrakatoaPropertiesList #(thePropName, theDefVal , true, false)
								)
						)
						3: (
								local thePropName=("Shader:"+theShaderName+":"+theDef[4]+":Value")
								try
									FranticParticles.GetProperty thePropName
								catch
								(
									FranticParticles.AddProperty thePropName theDef[5] 			
									if findItem allPropNames thePropName == 0 do append KrakatoaPropertiesList #(thePropName, theDef[5], true, false)								
								)
							)--end arity 3
						)--end arity case 
					)--end float param case
					#integer:
					(
						local thePropName=("Shader:"+theShaderName+":"+theDef[4]+":Value")
						try
							FranticParticles.GetProperty thePropName
						catch
						(
							local theDefVal = (filterString theDef[5] "[],")[3]
							FranticParticles.AddProperty thePropName theDefVal
							if findItem allPropNames thePropName == 0 do append KrakatoaPropertiesList #(thePropName, theDefVal, true, false)
						)
					)
					#dropdownlist:
					(
						local thePropName=("Shader:"+theShaderName+":"+theDef[4]+":Value")
						try
							FranticParticles.GetProperty thePropName
						catch
						(
							local theDefVal = (execute theDef[5])[1]
							FranticParticles.AddProperty thePropName theDefVal
							if findItem allPropNames thePropName == 0 do append KrakatoaPropertiesList #(thePropName, theDefVal, true, false)	
						)
					)
				)--end param type case				
			)--end parameter case
			#channel:
			(
				local thePropName = if theDef[7] == undefined then
					"Shader:"+theShaderName+":"+theDef[4]+":UseChannel"
				else
					theDef[7]


				--format "Initializing %\n" thePropName
				
				try
					FranticParticles.GetProperty thePropName
				catch
					FranticParticles.AddProperty thePropName "false"
				
				if FranticParticles.GetProperty thePropName == undefined do  FranticParticles.AddProperty thePropName "false"
					
				if findItem allPropNames thePropName == 0 do append KrakatoaPropertiesList #(thePropName, "false", true, false)	
				
				case theDef[2] of
				(
					#float: 
					(
						case theDef[3] of
						(
						1: (
								local thePropName= if theDef[8] == undefined then 
									("Shader:"+theShaderName+":"+theDef[4]+":ChannelDefault")
								else 
									theDef[8] 
								try
									FranticParticles.GetProperty thePropName
								catch
									FranticParticles.AddProperty thePropName (filterString theDef[5] "[],")[3]
								if FranticParticles.GetProperty thePropName == undefined do  FranticParticles.AddProperty thePropName (filterString theDef[5] "[],")[3]
								if findItem allPropNames thePropName == 0 do append KrakatoaPropertiesList #(thePropName, (filterString theDef[5] "[],")[3], true, false)	
							)
						3: (
								local thePropName=if theDef[8] == undefined then 
									("Shader:"+theShaderName+":"+theDef[4]+":ChannelDefault")
								else
									theDef[8]
								try
									FranticParticles.GetProperty thePropName
								catch
									FranticParticles.AddProperty thePropName theDef[5] 				
								if FranticParticles.GetProperty thePropName == undefined do  FranticParticles.AddProperty thePropName theDef[5] 		
								if findItem allPropNames thePropName == 0 do append KrakatoaPropertiesList #(thePropName, theDef[5] , true, false)	
							)--end arity 3
						)--end arity case 
					)--end float channel case
				)--end channel case
			)--end channel case
		)--end case
	)--end theDef loop	
),

fn hasRenderElement theShaderName theCompName =
(
	local re = maxops.getRenderElementMgr #production
	for i = 0 to (re.NumRenderElements()-1) do
	(
		local el =re.getRenderElement i
		case theShaderName of
		(
			"OccludedLayer":
			(
				if classof el == Krakatoa_OccludedLayer do return true
			)			
			"Phong Surface": 
			(
				case theCompName of
				(
					"Diffuse": (if (classof el == Krakatoa_Diffuse) do return true )
					"Specular": (if (classof el == Krakatoa_Specular) do return true )
				)
			)	
			"Marschner Hair":
			(
				case theCompName of
				(
					"Diffuse": (if (classof el == Krakatoa_Diffuse)do return true )
					"Glint": (if (classof el == Krakatoa_Glint)do return true )
					"Specular": (if (classof el == Krakatoa_Specular)do return true )
					"Specular2": (if (classof el == Krakatoa_Specular2)do return true )
				)				
			)
			"Kajiya-Kay Hair":
			(
				case theCompName of
				(
					"Diffuse": (if (classof el == Krakatoa_Diffuse) do return true )
					"Specular": (if (classof el == Krakatoa_Specular) do return true )
				)					
			)			
		)
		--if classof el == KrakatoaShaderElement and el.shadername == theShaderName and el.shaderComponentName == theCompName do return true
	)
	false
),

fn addRenderElement theShaderName theCompName =
(
	local re = maxops.getRenderElementMgr #production
	local theElement = undefined
	if not FranticParticleRenderMXS.hasRenderElement theShaderName theCompName then
	(
		case theShaderName of
		(
			"OccludedLayer":
			(
				theElement = Krakatoa_OccludedLayer()
			)
			"Phong Surface": 
			(
				case theCompName of
				(
					"Diffuse": theElement = Krakatoa_Diffuse()
					"Specular": theElement = Krakatoa_Specular()
				)
			)
			"Marschner Hair":
			(
				case theCompName of
				(
					"Diffuse": theElement = Krakatoa_Diffuse()
					"Glint": theElement = Krakatoa_Glint()
					"Specular": theElement = Krakatoa_Specular()
					"Specular2": theElement = Krakatoa_Specular2()
				)				
			)
			"Kajiya-Kay Hair":
			(
				case theCompName of
				(
					"Diffuse": theElement = Krakatoa_Diffuse()
					"Specular": theElement = Krakatoa_Specular()
				)					
			)
		)--end case
		if 	theElement != undefined then
		(
			re.addRenderElement theElement
			true
		)
		else 
			false
		--theElement.shadername = theShaderName
		--theElement.shaderComponentName = theCompName
		true
	)
	else false
),

fn removeRenderElement theShaderName theCompName =
(
	local re = maxops.getRenderElementMgr #production
	for i = 0 to (re.NumRenderElements()-1) do
	(
		local el =re.getRenderElement i
		case theShaderName of
		(
			"Phong Surface": 
			(
				case theCompName of
				(
					"Diffuse": (if classof el == Krakatoa_Diffuse do (re.RemoveRenderElement el; return true))
					"Specular": (if classof el == Krakatoa_Specular do (re.RemoveRenderElement el; return true)) 
				)
			)	
			"Marschner Hair":
			(
				case theCompName of
				(
					"Diffuse": (if classof el == Krakatoa_Diffuse do (re.RemoveRenderElement el; return true))
					"Glint": (if classof el == Krakatoa_Glint do (re.RemoveRenderElement el; return true))
					"Specular": (if classof el == Krakatoa_Specular do (re.RemoveRenderElement el; return true)) 
					"Specular2": (if classof el == Krakatoa_Specular2 do (re.RemoveRenderElement el; return true)) 
				)				
			)
			"Kajiya-Kay Hair":
			(
				case theCompName of
				(
					"Diffuse": (if classof el == Krakatoa_Diffuse do (re.RemoveRenderElement el; return true))
					"Specular": (if classof el == Krakatoa_Specular do (re.RemoveRenderElement el; return true)) 
				)					
			)			
		)		
		
		/*
		if classof el == KrakatoaShaderElement and el.shadername == theShaderName and el.shaderComponentName == theCompName do
		(
			re.RemoveRenderElement el
			return true
		)
		*/
	)
	false
),

fn toggleRenderElementByClass theClass theState =
(
	local re = maxops.getRenderElementMgr #production
	for i = 0 to (re.NumRenderElements()-1) do
	(
		local el =re.getRenderElement i
		if classof el == theClass do 
			el.enabled = theState
	)
),

fn openRenderElementsDialog =
(
	local thePref = (getIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "Preferences" "OpenRenderElementsTabOnChange")
	if thePref == "" do thePref = "1"
	if thePref == "1" do
	(
		RenderSceneDialog.open()
		tabbedDialogs.setCurrentPage #render #(1547006576, 1564889954)	
	)	
),



fn defineShaderRollout theShaderName=
(
	Krakatoa_Closing_Floater = true
	try(removeRollout Krakatoa_GUI_ShaderDynamic Krakatoa_Gui_floater)catch()
	try(removeRollout Krakatoa_GUI_ShaderDynamic Krakatoa_Gui_floater_2)catch()
	try(removeRollout Krakatoa_GUI_ShaderDynamic Krakatoa_Gui_floater_3)catch()
	try(destroyDialog Krakatoa_GUI_ShaderDynamic)catch()		
	Krakatoa_Closing_Floater = false
	
	controlsDefinition = FranticParticleRenderMXS.getShaderPropList theShaderName

	local txt = stringStream ""
	format "rollout Krakatoa_GUI_ShaderDynamic \"Shader Parameters\" category:8 width:460 rolledup:true(\n" to:txt
	
	format "button btn_LoadSave_ShaderDynamic \"<>\" across:4 align:#left width:20 height:16 offset:[-10,-5] tooltip:\"Load and Save Presets For This Rollout Only\" \n" to:txt
	
	format "button btn_Help_ShaderParameters  \"Open Online Help...\" height:16 width:100 align:#center offset:[-100,-5] across:3 tooltip:\"Opens the Krakatoa Online Help for the Shader Parameters rollout in the default Web Browser. Requires Internet connection.\"\n" to:txt
	format "button btn_BackTo_Main \"Back To Main Controls...\" height:16 width:308 offset:[-3,-5] align:#center tooltip:\"Closes the rollout and sets focus on the Main Controls rollout.\"\n" to:txt
	format "button btn_Float_Rollout \">\" height:16 width:20 offset:[10,-5] align:#right tooltip:\"Float/Dock the Rollout.\\nRight-Click for Menu...\" \n" to:txt
	
	format "on btn_BackTo_Main pressed do(\n" to:txt
	format "Krakatoa_GUI_ShaderDynamic.open = false\n" to:txt
	format "FranticParticleRenderMXS.BackToMainControls())\n" to:txt
	format "on btn_BackTo_Main rightclick do(\n" to:txt
	format "Krakatoa_GUI_ShaderDynamic.open = false\n" to:txt
	format "FranticParticleRenderMXS.BackToMainControls())\n" to:txt	

	format "on btn_LoadSave_ShaderDynamic pressed do (\n" to:txt
	format "Krakatoa_RCMenu_Struct.Float_Rollout_RCMenu_CurrentRollout = Krakatoa_GUI_ShaderDynamic\n" to:txt
	format "popupMenu Krakatoa_RCMenu_Struct.Load_Save_Rollout_RCMenu pos:mouse.screenpos )	\n" to:txt
		
	format "on btn_LoadSave_ShaderDynamic rightClick do (\n" to:txt
	format "Krakatoa_RCMenu_Struct.Float_Rollout_RCMenu_CurrentRollout = Krakatoa_GUI_ShaderDynamic \n" to:txt
	format "popupMenu Krakatoa_RCMenu_Struct.Load_Save_Rollout_RCMenu pos:mouse.screenpos)	\n" to:txt

	format "on btn_Float_Rollout pressed do FranticParticleRenderMXS.FloatRolloutButtonPressed Krakatoa_GUI_ShaderDynamic\n" to:txt
			
	format "on btn_Float_Rollout rightClick do (\n" to:txt
	format "Krakatoa_RCMenu_Struct.Float_Rollout_RCMenu_CurrentRollout = Krakatoa_GUI_ShaderDynamic\n" to:txt
	format "popupMenu Krakatoa_RCMenu_Struct.Float_Rollout_RCMenu pos:mouse.screenpos)	\n"	 to:txt
	
	format "on Krakatoa_GUI_ShaderDynamic moved pos do \n" to:txt
	format "setIniSetting (GetDir #plugcfg + \"/Krakatoa/KrakatoaPreferences.ini\") \"RolloutDialogPositions\" Krakatoa_GUI_ShaderDynamic.title (pos as string) \n" to:txt
	
	
	format "on Krakatoa_GUI_ShaderDynamic rolledUp val do (\n" to:txt
	format "if Krakatoa_GUI_ShaderDynamic.open == val then (\n" to:txt
	format "FranticParticles.SetProperty \"GUI:ShaderDynamicRolloutOpen\" val\n" to:txt
	format "if val then (FranticParticles.LogDebug (\"+Shader Parameters Rollout ROLLED DOWN.\")) else (FranticParticles.LogDebug (\"+Shader Parameters  Rollout ROLLED UP or CHANGED HEIGHT.\"))\n" to:txt
	format ")\n)\n" to:txt
	
	format "on Krakatoa_GUI_ShaderDynamic close do 	(\n" to:txt
	format "if Krakatoa_GUI_ShaderDynamic.inDialog and not Krakatoa_Closing_Floater and not Krakatoa_Initializing_Hidden_Rollouts do (\n" to:txt
	format "setIniSetting (GetDir #plugcfg + \"/Krakatoa/KrakatoaPreferences.ini\") \"RolloutVisible\" Krakatoa_GUI_ShaderDynamic.title \"false\" \n" to:txt
	format "Krakatoa_CustomizeRollouts_Dialog.Refresh_GUI()		))	\n" to:txt
	
	format "fn updateIcons =	(\n" to:txt
	format "btn_LoadSave_ShaderDynamic.images = #(Krakatoa_PresetsArrowBitmap,Krakatoa_PresetsArrowBitmap, 32,3,3,3,3)	\n" to:txt
	format "btn_Float_Rollout.images = #(Krakatoa_PresetsArrowBitmap,Krakatoa_PresetsArrowBitmap, 32,4,4,4,4)\n" to:txt
	format ")\n"	 to:txt
	
	local txt4 = stringStream ""
	format "fn updateRenderElementsVisibility = (\n" to:txt4
	
	local txt2 = stringStream ""
	format "on Krakatoa_GUI_ShaderDynamic open do (\nupdateIcons()\n" to:txt2
	format "if Krakatoa_Initializing_Hidden_Rollouts == false do try(Krakatoa_GUI_ShaderDynamic.open = FranticParticles.GetBoolProperty \"GUI:ShaderDynamicRolloutOpen\")catch()\n" to:txt2
	
	local txt3 = stringStream "" --for event handlers
	local theGroupCounter = 0
	local theGroupEnd = 0
	for theDef in controlsDefinition do
	(
		case theDef[1] of
		(
			#drawing:
			(
				if theDef[2] == #group do
				(
					theGroupCounter = 0
					theGroupEnd = theDef[3]+1 
					format "group \"%\" (\n" theDef[4] to:txt
				)
			)
			#label:
			(
				local theVOffset = if theGroupCounter == 1 then -7 else 0
				format "label lbl% \"%\" align:#center offset:[0,%]\n" theDef[4] theDef[5] theVOffset to:txt
			)
			#parameter:
			(
				case theDef[2] of
				(
					#boolean: 
					(
						local controlName = FranticParticleRenderMXS.underscoreString theDef[4]
						format "checkbutton chk_% \">%\" state:% width:240 align:#right offset:[5,-1] \n" controlName theDef[4] theDef[5] to:txt
						local thePropName=("Shader:"+theShaderName+":"+theDef[4]+":State")
						format "on chk_% changed state do(\n" controlName to:txt3
						format "FranticParticles.AddProperty \"%\" (state as string)\n" thePropName to:txt3
						try
							FranticParticles.GetProperty thePropName
						catch
							FranticParticles.AddProperty thePropName theDef[5]
						format ")\n" to:txt3
						
						format "on chk_% rightclick do(\n" controlName to:txt3
						format "FranticParticleRenderMXS.createDefaultsRCMenu \"%\" \">%\" )\n" thePropName theDef[4] to:txt3
						
						format "try( chk_%.state = FranticParticles.getBoolProperty \"%\" )catch()\n" controlName thePropName to:txt2
					)
					#float: 
					(
						case theDef[3] of
						(
						1: (
								local controlName = FranticParticleRenderMXS.underscoreString theDef[4]
								format "spinner spn_% \"%:\" range:% scale:% fieldwidth:50 type:#float align:#right offset:[5,-1] \n" controlName theDef[4] theDef[5] theDef[6] to:txt
								local thePropName=("Shader:"+theShaderName+":"+theDef[4]+":Value")
								format "on spn_% changed val do(\n" controlName to:txt3
								format "FranticParticles.AddProperty \"%\" (val as string)\n" thePropName to:txt3
								try
									FranticParticles.GetProperty thePropName
								catch
									FranticParticles.AddProperty thePropName (filterString theDef[5] "[],")[3]
								format ")\n" to:txt3
								format "try( spn_%.value = FranticParticles.getFloatProperty \"%\" )catch()\n" controlName thePropName to:txt2
						)
						3: (
								local controlName = FranticParticleRenderMXS.underscoreString theDef[4]
								format "colorpicker clr_% \"%:\" color:% fieldwidth:59 align:#right offset:[5,-1] modal:false alpha:true\n" controlName theDef[4] theDef[5] to:txt
								local thePropName=("Shader:"+theShaderName+":"+theDef[4]+":Value")
								try
									FranticParticles.GetProperty thePropName
								catch
									FranticParticles.AddProperty thePropName theDef[5] 						
								format "on clr_% changed val do(\n" controlName to:txt3
								format "FranticParticles.AddProperty \"%\" (val as string)\n" thePropName to:txt3
								format ")\n" to:txt3
								format "try( clr_%.color = execute (FranticParticles.getProperty \"%\") )catch()\n" controlName thePropName to:txt2
							)--end arity 3
						)--end arity case 
					)--end float param case
					#integer:
					(
						local controlName = FranticParticleRenderMXS.underscoreString theDef[4]
						format "spinner spn_% \"%:\" range:% scale:% fieldwidth:50 type:#integer align:#right offset:[5,-1] \n" controlName theDef[4] theDef[5] theDef[6] to:txt
						local thePropName=("Shader:"+theShaderName+":"+theDef[4]+":Value")
						format "on spn_% changed val do(\n" controlName to:txt3
						format "FranticParticles.AddProperty \"%\" (val as string)\n" thePropName to:txt3
						try
							FranticParticles.GetProperty thePropName
						catch
							FranticParticles.AddProperty thePropName (filterString theDef[5] "[],")[3]
						format ")\n" to:txt3
						format "try( spn_%.value = FranticParticles.getIntProperty \"%\" )catch()\n" controlName thePropName to:txt2
					)
					#dropdownlist:
					(
						local controlName = FranticParticleRenderMXS.underscoreString theDef[4]
						format "label lbl_% \"%:..................................................\" across:2 align:#left offset:[0,1]\n" controlName theDef[4]  to:txt
						format "dropdownlist ddl_% items:% width:240 align:#right offset:[7,-1] \n" controlName theDef[5] to:txt
						local thePropName=("Shader:"+theShaderName+":"+theDef[4]+":Value")
						format "on ddl_% selected itm do(\n" controlName to:txt3
						format "FranticParticles.AddProperty \"%\" (ddl_%.selected)\n" thePropName controlName to:txt3
						try
							FranticParticles.GetProperty thePropName
						catch
							FranticParticles.AddProperty thePropName (execute theDef[5])[1]
						format ")\n" to:txt3
						format "try( ddl_%.selection = findItem ddl_%.items (FranticParticles.getProperty \"%\") )catch()\n" controlName controlName thePropName to:txt2
					)
				)--end param type case				
			)--end parameter case
			#channel:
			(
				local controlName = FranticParticleRenderMXS.underscoreString theDef[4]
				local thePropName = if theDef[7] == undefined then
					"Shader:"+theShaderName+":"+theDef[4]+":UseChannel"
				else
					theDef[7]
				
				try
					FranticParticles.GetProperty thePropName
				catch
					FranticParticles.AddProperty thePropName "false"
				
				format "checkbutton chk_Use% \">Per-particle [%] Channel\" width:220 across:2 offset:[-5,-3] align:#left tooltip:\"When checked, the % Channel will be allocated in memory, initialized to the default value and can be set and modified by a Krakatoa Channel Modifier.\\nWhen unchecked, the Default value will be used directly for all particles without memory overhead.\"\n" controlName theDef[4] theDef[4] to:txt
				format "on chk_Use% changed state do(\n" controlName to:txt3
				format "FranticParticles.AddProperty \"%\" (state as string)\n" thePropName to:txt3
				format "Krakatoa_GUI_Channels.updateMemChannels()\n" to:txt3
				format "try(Krakatoa_updateSchematicFlow())catch()\n" to:txt3
				format "Krakatoa_GUI_Main.update2009VFBControls side:#left\n" to:txt3
				format ")\n" to:txt3
				
				format "on chk_Use% rightclick do(\n" controlName  to:txt3
				format "FranticParticleRenderMXS.createDefaultsRCMenu \"%\" \">Allocate % Channel\" )\n" thePropName theDef[4] to:txt3
				format "try( chk_Use%.state = FranticParticles.getBoolProperty \"%\" )catch()\n" controlName thePropName to:txt2
				
				case theDef[2] of
				(
					#float: 
					(
						case theDef[3] of
						(
						1: (
								format "spinner spn_% \"Default %:\" range:% scale:% fieldwidth:50 type:#float align:#right offset:[6,1] \n" controlName theDef[4] theDef[5] theDef[6] to:txt
								local thePropName= if theDef[8] == undefined then 
									("Shader:"+theShaderName+":"+theDef[4]+":ChannelDefault")
								else 
									theDef[8] 
								format "on spn_% changed val do(\n" controlName to:txt3
								format "FranticParticles.AddProperty \"%\" (val as string)\n" thePropName to:txt3
								try
									FranticParticles.GetProperty thePropName
								catch
									FranticParticles.AddProperty thePropName (filterString theDef[5] "[],")[3]
								format ")\n" to:txt3
								format "try( spn_%.value = FranticParticles.getFloatProperty \"%\" )catch()\n" controlName thePropName to:txt2
							)
						3: (
								format "colorpicker clr_% \"Default %:\" color:% fieldwidth:59 align:#right offset:[6,-3] modal:false alpha:true\n" controlName theDef[4] theDef[5] to:txt
								local thePropName=if theDef[8] == undefined then 
									("Shader:"+theShaderName+":"+theDef[4]+":ChannelDefault")
								else
									theDef[8]
								try
									FranticParticles.GetProperty thePropName
								catch
									FranticParticles.AddProperty thePropName theDef[5] 						
								format "on clr_% changed val do(\n" controlName to:txt3
								format "FranticParticles.AddProperty \"%\" (val as string)\n" thePropName to:txt3
								format ")\n" to:txt3
								format "try( clr_%.color = execute (FranticParticles.getProperty \"%\") )catch()\n" controlName thePropName to:txt2
							)--end arity 3
						)--end arity case 
					)--end float channel case
				)--end type case
			)--end channel case
			#renderelement:
			(
				local controlName = FranticParticleRenderMXS.underscoreString theDef[4]
				local thePropName = if theDef[7] == undefined then
					"RenderElement:"+theShaderName+":"+theDef[4]+":Create"
				else
					theDef[7]				
				format "button btn_Create% \"Create [%] Render Element\" width:300 across:2 offset:[-5,-3] align:#left tooltip:\"Add a % Render Element to the Render Elements Tab of the Render Setup Dialog.\" enabled:(not FranticParticleRenderMXS.hasRenderElement \"%\" \"%\") \n" controlName theDef[4] theDef[4] theShaderName theDef[6] to:txt
				format "button btn_Delete% \"Delete Render Element\" width:140 offset:[5,-3] align:#right tooltip:\"Delete the % Render Element.\" enabled:(FranticParticleRenderMXS.hasRenderElement \"%\" \"%\") \n" controlName theDef[4] theShaderName theDef[6] to:txt
				format "on btn_Create% pressed do(\n" controlName to:txt3
				format "FranticParticleRenderMXS.addRenderElement \"%\" \"%\" \n" theShaderName theDef[6] to:txt3
				format "try(Krakatoa_updateSchematicFlow())catch()\n" to:txt3
				format "btn_Create%.enabled = (not FranticParticleRenderMXS.hasRenderElement \"%\" \"%\") \n" controlName theShaderName theDef[6] to:txt4
				format "btn_Delete%.enabled = (FranticParticleRenderMXS.hasRenderElement \"%\" \"%\") \n" controlName theShaderName theDef[6] to:txt4
				format "updateRenderElementsVisibility()\n" to:txt3
				format "FranticParticleRenderMXS.openRenderElementsDialog()\n" to:txt3
				format ")\n" to:txt3

				format "on btn_Delete% pressed do(\n" controlName to:txt3
				format "FranticParticleRenderMXS.removeRenderElement \"%\" \"%\" \n" theShaderName theDef[6] to:txt3
				format "try(Krakatoa_updateSchematicFlow())catch()\n" to:txt3
				format "btn_Create%.enabled = (not FranticParticleRenderMXS.hasRenderElement \"%\" \"%\") \n" controlName theShaderName theDef[6] to:txt4
				format "btn_Delete%.enabled = (FranticParticleRenderMXS.hasRenderElement \"%\" \"%\") \n" controlName theShaderName theDef[6] to:txt4
				format "updateRenderElementsVisibility()\n" to:txt3
				format "FranticParticleRenderMXS.openRenderElementsDialog()\n" to:txt3
				
				format ")\n"	to:txt3
				
				format "on chk_Create% rightclick do(\n" controlName to:txt3
				format "FranticParticleRenderMXS.createDefaultsRCMenu \"%\" \">Create % Render Element\" )\n" thePropName theDef[4] to:txt3
				
				format "try( chk_Create%.state = FranticParticles.getBoolProperty \"%\" )catch()\n" controlName thePropName to:txt2
			)--end re case			
		)--end case
		theGroupCounter += 1
		if theGroupCounter == theGroupEnd do 
			format ")\n" to:txt
			
	)--end theDef loop
	if theGroupCounter < theGroupEnd do format ")\n" to:txt
		
	format "updateRenderElementsVisibility()\n" to:txt2
	format ")\n" to:txt2

	format ")\n" to:txt4
	format "%\n" (txt4 as string) to:txt
	format "%\n" (txt3 as string) to:txt
	format "%)\n" (txt2 as string) to:txt
	
	execute (txt as string)
	
	local theState = execute (getIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "RolloutVisible" Krakatoa_GUI_ShaderDynamic.title)
	if theState == OK do 
		theState = true
		
	if theState then
	(
		local theDockedState = execute (getIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "RolloutDocked" Krakatoa_GUI_ShaderDynamic.title)
		if theDockedState == OK do theDockedState = true
		local theDockHost = (getIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "RolloutDockHost" Krakatoa_GUI_ShaderDynamic.title)
		if theDockHost == "" do theDockHost = "1"
			
		if theDockedState then
		(	
				if theDockHost == "2" then
					FranticParticleRenderMXS.floatOrDockRollout Krakatoa_GUI_ShaderDynamic forceMode:#dock2
				else	
					FranticParticleRenderMXS.floatOrDockRollout Krakatoa_GUI_ShaderDynamic forceMode:#dock
		)
		else
			FranticParticleRenderMXS.floatOrDockRollout Krakatoa_GUI_ShaderDynamic forceMode:#float
		FranticParticles.LogDebug ("+Added '" + Krakatoa_GUI_ShaderDynamic.title +"' Rollout to Krakatoa GUI Floater.")
	)	
	else
		FranticParticleRenderMXS.floatOrDockRollout Krakatoa_GUI_ShaderDynamic forceMode:#hide	
),

fn GetCompressOnSaveState =
(
	getIniSetting (GetMaxIniFile()) "Performance" "WriteCompressed" == "1"
),

fn BackToMainControls =
(
	if findItem Krakatoa_Gui_floater.rollouts Krakatoa_GUI_Main > 0 then
	(
		if not Krakatoa_Gui_floater.open do FranticParticleRenderMXS.OpenGUI()
		for i in Krakatoa_Gui_floater.rollouts do i.open = false
		Krakatoa_GUI_Main.open = true
		Krakatoa_GUI_Main.scrollPos = 0 
	)
	else if findItem Krakatoa_Gui_floater_2.rollouts Krakatoa_GUI_Main > 0 then
	(
		if not Krakatoa_Gui_floater_2.open do FranticParticleRenderMXS.OpenGUI()				
		for i in Krakatoa_Gui_floater_2.rollouts do i.open = false

		Krakatoa_GUI_Main.open = true
		Krakatoa_GUI_Main.scrollPos = 0 
	)
	else if findItem Krakatoa_Gui_floater_3.rollouts Krakatoa_GUI_Main > 0 then
	(
		try(removeRollout Krakatoa_GUI_Main Krakatoa_Gui_floater_3)catch()
		setIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "RolloutVisible" Krakatoa_GUI_Main.title "true"
		setIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "RolloutDocked" Krakatoa_GUI_Main.title "false"		
		FranticParticleRenderMXS.floatOrDockRollout Krakatoa_GUI_Main forceMode:#float
		--try(createDialog Krakatoa_GUI_Main)catch()
	)
	else 
	(
		createDialog Krakatoa_GUI_Main		
	)
),

fn createDefaultsRCMenu theKey theName=
(
	local theCurrentValue = getIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaDefaults.ini") "Defaults" theKey
	if theCurrentValue == "" do theCurrentValue = "--Not Set--"
	local theNewValue = FranticParticles.getProperty theKey 
	
	local txt = stringStream ""
	format "rcmenu Presets_RCMenu\n(\n" to:txt
	
	if theCurrentValue != theNewValue do
	(
		format "menuItem mnu_MakeDefault \"Save [%] as Startup Default for [%] - Current Default:%\" \n" theNewValue theName theCurrentValue to:txt
		format "on mnu_MakeDefault picked do setIniSetting (GetDir #plugcfg + \"/Krakatoa/KrakatoaDefaults.ini\") \"Defaults\" \"%\" \"%\" \n" theKey theNewValue to:txt
	)
	if theCurrentValue != "--Not Set--" do
	(
		format "menuItem mnu_RemoveDefault \"Remove [%] from [%] Startup Default - Use the Factory Default instead.\" \n" theCurrentValue theName to:txt
		format "on mnu_RemoveDefault picked do delIniSetting (GetDir #plugcfg  + \"/Krakatoa/KrakatoaDefaults.ini\") \"Defaults\" \"%\"\n" theKey to:txt
	)	
	format ")\n" to:txt
	Krakatoa_RCMenu_Struct.Presets_RCMenu = execute (txt as string)
	popUpMenu Krakatoa_RCMenu_Struct.Presets_RCMenu position:mouse.screenPos
),

fn IsCacheValid =
(
	try
	(
		local theCachedChannels = FranticParticles.GetCachedParticleChannels()
		local theRenderChannels = FranticParticles.GetRenderParticleChannels()
	)
	catch
	(	
		local theCachedChannels = #(#("Position","float32[3]"),#("Velocity","float16[3]"), #("Density","float16[1]"), #("Color","float16[3]") ) 
		local theRenderChannels = Krakatoa_GUI_Channels.activeMemChannels
	)	
	Krakatoa_GUI_Main.theCachedChannelsArray = for i in theCachedChannels collect i[1]
	theMissingChannels = for i in theRenderChannels where findItem Krakatoa_GUI_Main.theCachedChannelsArray i[1] == 0 collect i[1]
	local result = if theMissingChannels.count == 0 then 
		if FranticParticleRenderMXS.SettingsUnmodifiedSinceCacheCreation() then #valid else #validchanged
	else 
		#invalid
	if FranticParticles.getCacheSize() == 0.0 do result = #empty
	result
),

fn setDefaultMagmaFlow theHost =
(
		if classof theHost == MagmaHolder and theHost.Flow == "#()"  do
			theHost.internalFlow = theHost.Flow = "#(#(\"Output\", #(2), #(\"RenderElement\",\"float16\",3), #([350,0],false, false,undefined,undefined,undefined,undefined,\"Output\" ), true ) ,#(\"Input\", #(), #(\"Channel\", \"Color\"), #([200,100], false, true, undefined, undefined, undefined, true, \"Color\", \"Color\"), true))" 
),

fn navigateToKrakatoaRollout theRollout =
(
--		if Krakatoa_Gui_floater == undefined do macros.run "Krakatoa" "KrakatoaGUI"
	local currentState = (execute (getIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "RolloutVisible" theRollout.title)) == true
	if not currentState do FranticParticleRenderMXS.ToggleRolloutVisibility theRollout
	
	try(
		if findItem Krakatoa_Gui_floater.rollouts theRollout > 0 then
		(
			if not Krakatoa_Gui_floater.open do FranticParticleRenderMXS.OpenGUI()
			for i in Krakatoa_Gui_floater.rollouts do i.open = false
			theRollout.open = true
			--theRollout.scrollPos = 0 
		)
		else if findItem Krakatoa_Gui_floater_2.rollouts theRollout > 0 then
		(
			if not Krakatoa_Gui_floater_2.open do FranticParticleRenderMXS.OpenGUI()				
			for i in Krakatoa_GUI_Floater_2.rollouts do i.open = false
			theRollout.open = true
			--theRollout.scrollPos = 0 
		)
		else 
		(
			if not theRollout.open do
			(
				try(destroyDialog theRollout)catch()
				createDialog theRollout
			)
		)
	)
	catch
	(
		try(destroyDialog theRollout)catch()
		try(createDialog theRollout)catch()
	)
),

fn ToggleRolloutVisibility theRollout =
(
	local currentState = execute (getIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "RolloutVisible" theRollout.title)
	if currentState == OK do currentState = false
	if currentState then
	(
		if keyboard.shiftPressed and keyboard.controlPressed then 
			FranticParticleRenderMXS.floatOrDockRollout theRollout forceMode:#dock2
		else 
			if keyboard.controlPressed then 
				FranticParticleRenderMXS.floatOrDockRollout theRollout forceMode:#dock
			else
				FranticParticleRenderMXS.floatOrDockRollout theRollout forceMode:#hide
	)
	else
	(
		local currentlyDocked = execute (getIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "RolloutDocked" theRollout.title)
		if currentlyDocked == OK do currentlyDocked = true
		local DockHost = getIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "RolloutDockHost" theRollout.title 	
		if DockHost == "" do DockHost = "1"
		setIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "RolloutVisible" theRollout.title "true"			
		try(destroyDialog theRollout)catch()
		try(removeRollout theRollout Krakatoa_GUI_Floater_3)catch()
		if currentlyDocked then
		(
			if DockHost == "1" then
				addRollout theRollout Krakatoa_GUI_Floater
			else
				addRollout theRollout Krakatoa_GUI_Floater_2
		)
		else
		(
			local thePos = execute (getIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "RolloutDialogPositions" theRollout.title) 
			if thePos != OK then
			(
				thePos = FranticParticleRenderMXS.AdjustDialogPositionOnDesktop thePos 470 400 dialogName:(theRollout.title+" Dialog")
				createDialog theRollout style:#(#style_titlebar,#style_minimizebox,#style_sysmenu) pos:thePos
			)	
			else
				createDialog theRollout style:#(#style_titlebar,#style_minimizebox,#style_sysmenu)			
		)
	)
	if keyboard.shiftPressed do FranticParticleRenderMXS.navigateToKrakatoaRollout theRollout
),


fn openMagmaFlowEditor theHost =
(
	FranticParticles.LogDebug ">FN openMagmaFlowEditor() called."
	try(destroyDialog KrakatoaChannelNodeEditor_Rollout)catch()
	global KrakatoaChannelEditor_LastUndoRecordNumber = 0
	global KrakatoaChannelNodeEditor_CurrentModifier = theHost
	global KrakatoaChannelEditor_BaseNodeTreeData = execute KrakatoaChannelNodeEditor_CurrentModifier.internalFlow
	if KrakatoaChannelEditor_BaseNodeTreeData.count == 0 do
	(
		if classof KrakatoaChannelNodeEditor_CurrentModifier == MagmaHolder then
			KrakatoaChannelNodeEditor_CurrentModifier.internalFlow = KrakatoaChannelNodeEditor_CurrentModifier.Flow = "#(#(\"Output\", #(2), #(\"RenderElement\",\"float16\",3), #([350,0],false, false,undefined,undefined,undefined,undefined,\"Output\" ), true ) ,#(\"Input\", #(), #(\"Channel\", \"Color\"), #([200,100], false, true, undefined, undefined, undefined, true, \"Color\", \"Color\"), true))" 
		else
			KrakatoaChannelNodeEditor_CurrentModifier.internalFlow = KrakatoaChannelNodeEditor_CurrentModifier.Flow = "#(#(\"Output\", #(2), #(\"Color\",\"float16\",3), #([350,0],false, false,undefined,undefined,undefined,undefined,\"Output\" ), true ) ,#(\"Input\", #(), #(\"Channel\", \"Color\"), #([200,100], false, true, undefined, undefined, undefined, true, \"Color\", \"Color\"), true))" 
		global KrakatoaChannelEditor_BaseNodeTreeData = execute KrakatoaChannelNodeEditor_CurrentModifier.internalFlow
	)
	if KrakatoaChannelNodeEditor_CurrentModifier.trackID == undefined do
	(
		local theClasses = (getClassInstances KrakatoaChannelsModifier)
		local theREMagmaHolders = #()
		local re = maxOps.GetCurRenderElementMgr()
		for i = 0 to (re.numrenderelements()-1) do
		(
			el = re.getrenderelement i
			if classof el == Krakatoa_CustomData and el.MagmaHolder.trackID != undefined do append theREMagmaHolders el.MagmaHolder
		)
		join theClasses theREMagmaHolders 
		local existingIDs = for o in theClasses collect o.TrackID
		do 
		(
			KrakatoaChannelNodeEditor_CurrentModifier.trackID = (random 100000 10000000) as string + "_" + (random 100000 10000000) as string 
		)
		while findItem existingIDs KrakatoaChannelNodeEditor_CurrentModifier.trackID != 0
	)
	
	KrakatoaChannelsEditor_Functions.fixFlowIDsAfterLoading KrakatoaChannelEditor_BaseNodeTreeData	
	
	KrakatoaChannelsEditor_Functions.buildDisplayTree()
	
	local theSize = execute (getIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "ParticleChannelEditor" "Size")
	if theSize == OK do theSize = [980,600]
	if theSize.x < 400 do theSize.x = 400
	if theSize.y < 200 do theSize.y = 200
	
	local thePos = execute (getIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "ParticleChannelEditor" "Position")
	if thePos == OK do thePos = [100,100]
	if thePos.x < 0 do thePos.x = 0
	if thePos.y < 0 do thePos.y = 0
	if thePos.x > sysinfo.DesktopSize.x - theSize.x do thePos.x = sysinfo.DesktopSize.x - theSize.x
	if thePos.y > sysinfo.DesktopSize.y - theSize.y do thePos.y = sysinfo.DesktopSize.y - theSize.y
	createDialog KrakatoaChannelNodeEditor_Rollout theSize.x theSize.y thePos.x thePos.y style:#(#style_titlebar, #style_border, #style_sysmenu, #style_resizing, #style_minimizebox, #style_maximizebox) menu:KrakatoaChannelNodeEditor_Rollout_MainMenu
	KrakatoaChannelNodeEditor_Rollout.resized theSize	
	--KrakatoaChannelNodeEditor_Rollout.title = "Krakatoa MagmaFlow Editor - ID:"  + KrakatoaChannelNodeEditor_CurrentModifier.trackID as string +" - ["+ KrakatoaChannelNodeEditor_CurrentModifier.name+"]"
	KrakatoaChannelsEditor_Functions.updateEditorTitle()
	setFocus KrakatoaChannelNodeEditor_Rollout.hc		
	FranticParticles.LogDebug ">FN openMagmaFlowEditor() Ended."
),

fn fixNamedSelectionSets =
(
	local nssNames = for i in selectionSets collect i.name
	local nssContent = for i in selectionSets collect (for o in i collect o)
	for o in objects do
	(
		local theVal = getUserProp o "KrakatoaMatteObjectNSS" 
		if classof theVal == String do
		(
			try(theVal = execute theVal)catch(theVal = #())
			for nss in theVal do
			(
				theIndex = findItem nssNames nss
				if theIndex == 0 then
				(
					append nssNames nss
					append nssContent #(o)
				)
				else
				(
					appendIfUnique nssContent[theIndex] o 
				)
			)
		)
	)
	for i = 1 to nssNames.count do
	(
		with PrintAllElements on 
		(
			if selectionSets[nssNames[i]] == undefined then
				selectionSets[nssNames[i]] = nssContent[i]
			else
				if (for o in selectionSets[nssNames[i]] collect o) as string != nssContent[i] as string do
					selectionSets[nssNames[i]] = nssContent[i]
		)
	)
),

fn displayRendererSwitchPrompt =
(
	local txt = ("Switched renderer to ["+ (classof renderers.current) as string +"]")
	local pref = execute (getIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini" ) "Preferences" "SwitchedToRendererMessageBehavior")
	case pref of
	(
		default: messagebox txt title:"Krakatoa: Switch To Renderer"
		2: pushprompt txt
		3: ()
	)					
),

--------------------------------------------------------------------------------------------------------------------------------------------------------------------	
--DEFINE ALL UI ROLLOUTS
--------------------------------------------------------------------------------------------------------------------------------------------------------------------	
fn OpenGUI initOnly:false=
(
	FranticParticles.LogDebug ("FN OpenGUI() called with initOnly:"+initOnly as string)
	if IsNetServer() do 
	(
		FranticParticles.LogDebug ("Network Mode Detected, returning from OpenGUI() call.")
		return -1 
	)

	
	
	--Create OccludeLayer Render Element if the SaveMultipleLayers property introduced in v1.5.0 is true
	try
	(
		if FranticParticles.GetBoolProperty "Matte:SaveMultipleLayers" do 
		(
			FranticParticleRenderMXS.addRenderElement "OccludedLayer" ""
			FranticParticleRenderMXS.toggleRenderElementByClass Krakatoa_OccludedLayer true		
		)
	)catch()
	
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
	
	local openGUIst = timestamp()
	FranticParticles.LogProgress ("                                                                 ")
	FranticParticles.LogProgress ("-----"+ localtime + "--------------------------")
	FranticParticles.LogProgress ">Opening Krakatoa GUI..."
	
	local theMaxVersion = (MaxVersion())[1]/1000
	local canUseRPSFile = not FranticParticleRenderMXS.GetCompressOnSaveState() or theMaxVersion < 12 or theMaxVersion > 13 or not is64bitApplication()
	
	if renderers.current.classid as string != "#(-1204370534, -399920359)" and renderers.current.classid as string != "#(3090596762L, 3895046937L)" then --if not Krakatoa
	(
		FranticParticles.LogDebug ("  -Current Renderer is not Krakatoa - it is "+ (classof renderers.current) as string  )
		
		if canUseRPSFile then 
		(
			FranticParticles.LogDebug ("  +Can use Render Presets for storing/restoring renderers.")
			
			if doesFileExist ((getdir #renderpresets) + "\\backup_last_krakatoa_settings.rps") then
			(
				local txt = "The Production Renderer must be set to Krakatoa to access its UI.\n\n"
				txt +="The current Production Renderer is [" + (classof renderers.current) as string +"]\n\n"
				
				txt +="The current Renderer's settings will be saved as Render Preset 'backup_pre_krakatoa_assignment.rps'\n"
				txt +="and can be easily restored by using the\n'Switch Back From Krakatoa To Previous Renderer' icon/menu item.\n\n"
				txt +="Press [Yes] to LOAD the last known Krakatoa settings from disk.\n"
				txt +="Press [No] to SWITCH to Krakatoa using the DEFAULT settings.\n"
				txt +="Press [Cancel] to LEAVE ["+ (classof renderers.current) as string + "] as current renderer.\n"
				local q = yesNoCancelBox txt title:("Switch To Krakatoa v" + FranticParticles.Version)
				
				case q of 
				(
					#yes: (
						local lastRenderDialogState =renderSceneDialog.isOpen()
						renderSceneDialog.close()
						setIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini" ) "SwitchRenderer" "LastNonKrakatoaOutputPath" rendOutputFilename 
						
						RenderPresets.Save 0 ((getdir #renderpresets) + "\\backup_pre_krakatoa_assignment.rps") #{1,4..64} 
						FranticParticles.LogDebug ("  +Current Renderer's settings backed up.")
					
						local oldColorCorrectionMode = try(IDisplayGamma.colorCorrectionMode)catch(undefined)
						local oldLUTFileName = try(IDisplayGamma.LUTFileName)catch(undefined)
						local oldgamma  = try(IDisplayGamma.gamma )catch(undefined)
						local oldcolorCorrectionPrefMode = try(IDisplayGamma.colorCorrectionPrefMode )catch(undefined)
						local oldcoloraffectColorPickers  = try(IDisplayGamma.affectColorPickers )catch(undefined)
						local oldaffectMEdit = try(IDisplayGamma.affectMEdit  )catch(undefined)
						
						SetQuietMode true
						renderpresets.LoadAll 0 ((getdir #renderpresets) + "\\backup_last_krakatoa_settings.rps" )		
						SetQuietMode false
						
						try(if oldColorCorrectionMode != undefined do IDisplayGamma.colorCorrectionMode = oldColorCorrectionMode)catch()
						try(if oldLUTFileName != undefined do IDisplayGamma.LUTFileName = oldLUTFileName)catch()
						try(if oldgamma != undefined do IDisplayGamma.gamma = oldgamma)catch()
						try(if oldcolorCorrectionPrefMode != undefined do IDisplayGamma.colorCorrectionPrefMode = oldcolorCorrectionPrefMode)catch()
						try(if oldcoloraffectColorPickers != undefined do IDisplayGamma.affectColorPickers = oldcoloraffectColorPickers)catch()
						try(if oldaffectMEdit != undefined do IDisplayGamma.affectMEdit = oldaffectMEdit)catch()
						
						renderers.medit_locked=false
						renderers.medit = Default_Scanline_Renderer()
						local pref = execute (getIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini" ) "Preferences" "StoreRenderOutputPathOnRenderSwitchBehavior")
						if pref == OK do pref = 1
						if pref < 3 do
						(
							local lastPath = getIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini" ) "SwitchRenderer" "LastKrakatoaOutputPath" 
							if lastPath != "" do 
							if pref == 2  or (querybox ("Previous Krakatoa Output Save Path Found:\n\n"+lastPath+"\n\nDo you want to restore it?") title:"Restore Krakatoa Save Path") do
								rendOutputFilename = lastPath
						)
						if lastRenderDialogState do renderSceneDialog.Open()
						if renderers.current.classid as string != "#(-1204370534, -399920359)" and renderers.current.classid as string != "#(3090596762L, 3895046937L)" then 
						(
							FranticParticles.LogDebug ("  -Failed to load last Krakatoa settings from preset.")
							popPrompt()
							pushprompt "Failed to load last Krakatoa settings from preset."							
							return 0
						)
						else	
						(
							FranticParticles.LogDebug ("  +Current Renderer set to Krakatoa using last known settings.")
							popPrompt()
							pushprompt "Current Renderer set to Krakatoa with last known settings."							
						)	
					)
					#no: (
						local lastRenderDialogState =renderSceneDialog.isOpen()
						renderSceneDialog.close()
						setIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini" ) "SwitchRenderer" "LastNonKrakatoaOutputPath" rendOutputFilename 
						if canUseRPSFile then
						(
							RenderPresets.Save 0 ((getdir #renderpresets) + "\\backup_pre_krakatoa_assignment.rps") #{1,4..64} 			
							FranticParticles.LogDebug ("  +Current Renderer's settings backed up.")
						)
						else
						(
							
						)
						renderers.current = Krakatoa()
						renderers.medit_locked=false
						renderers.medit = Default_Scanline_Renderer()
						if lastRenderDialogState do renderSceneDialog.Open()
						FranticParticles.LogDebug ("  +Current Renderer set to Krakatoa with default settings.")
						popPrompt()
						pushprompt "Current Renderer set to Krakatoa with default settings."					
					)
					#cancel: 
					( 
						FranticParticles.LogDebug ("  -Krakatoa assignment canceled by user.")
						popPrompt()
						pushprompt "Krakatoa assignment canceled."					
						return 0 
					)
				)	
			)
			else
			(
				local q = querybox ("Production Renderer must be set to Krakatoa to access its UI.\nThe current renderer is ["+ (classof renderers.current) as string +"]\nDo you want to set Krakatoa as your renderer?\n\nThe current renderer's settings will be saved as Render Preset\n'backup_pre_krakatoa_assignment.rps'.") title:"Switch To Krakatoa"
				if q then 
				(
					local lastRenderDialogState =renderSceneDialog.isOpen()
					renderSceneDialog.close()
					setIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini" ) "SwitchRenderer" "LastNonKrakatoaOutputPath" rendOutputFilename 
					RenderPresets.Save 0 ((getdir #renderpresets) + "\\backup_pre_krakatoa_assignment.rps") #{1,4..64} 
					FranticParticles.LogDebug ("  +Current Renderer's settings backed up.")
					--callbacks.removeScripts #postRendererChange id:#KrakatoaParticles
					renderers.current = Krakatoa()
					renderers.medit_locked=false
					renderers.medit = Default_Scanline_Renderer()
					if lastRenderDialogState do renderSceneDialog.Open()
					--callbacks.addScript #postRendererChange "FranticParticleRenderMXS.postRendererChanged()" id:#KrakatoaParticles
					FranticParticles.LogDebug ("  +Current Renderer set to Krakatoa with default settings.")
					popPrompt()
					pushprompt "Current Renderer set to Krakatoa with default settings."
				)	
				else
				(
					FranticParticles.LogDebug ("  -Krakatoa assignment canceled by user.")
					popPrompt()
					pushprompt "Krakatoa assignment canceled."
					return 0
				)	
			)	
		)
		else --cannot use render presets
		(
			FranticParticles.LogDebug ("  -Cannot use Render Presets for storing/restoring renderers because Compress On Save is checked.")
			local txt = "The Production Renderer must be set to Krakatoa to access its UI.\n\n"
			txt +="The current Production Renderer is [" + (classof renderers.current) as string +"]\n\n"
			txt +="The current Renderer's settings\nCANNOT BE SAVED TO DISK as Render Preset\n"
			txt +="because the option\nCustomize>Preferences>Files>Compress On Save is ON\n"
			txt +="and could cause Render Preset file corruption\nin this version of 3ds Max!\n\n"
			
			txt +="The current renderer will be stored TEMPORARILY in memory\n"
			txt +="for the duration of the CURRENT SESSION \n"
			txt +="and can be easily restored by using the\n'Switch Back From Krakatoa To Previous Renderer' icon/menu item.\n\n"
			
			if KrakatoaLastRendererStorage[1] != undefined then --Krakatoa is stored in memory
			(
				txt +="Press [Yes] to load the last known Krakatoa settings from MEMORY storage.\n"
				txt +="Press [No] to set Krakatoa as the current renderer using DEFAULT settings.\n"
				txt +="Press [Cancel] to LEAVE "+ (classof renderers.current) as string + " as the current renderer.\n"
				local q = yesNoCancelBox txt title:("Switch To Krakatoa v" + FranticParticles.Version)
				case q of 
				(
					#yes:
					(
						local lastRenderDialogState =renderSceneDialog.isOpen()
						renderSceneDialog.close()
						setIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini" ) "SwitchRenderer" "LastNonKrakatoaOutputPath" rendOutputFilename 
						
						KrakatoaLastRendererStorage[2] = renderers.current
						KrakatoaLastRendererStorage[4] = #()
						local theManager = maxOps.GetCurRenderElementMgr()
						try(KrakatoaLastRendererStorage[4][1] = theManager.GetElementsActive() )catch()
						try(KrakatoaLastRendererStorage[4][2] = theManager.GetDisplayElements() )catch()
						try(KrakatoaLastRendererStorage[4][3] = theManager.NumRenderElements() )catch()
						for i = 1 to theManager.NumRenderElements() do
						(
							try(KrakatoaLastRendererStorage[4][i+3] = theManager.GetRenderElement (i-1) )catch()
						)						
						
						renderers.current = KrakatoaLastRendererStorage[1]
						
						renderers.medit_locked=false
						renderers.medit = Default_Scanline_Renderer()
						local pref = execute (getIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini" ) "Preferences" "StoreRenderOutputPathOnRenderSwitchBehavior")
						if pref == OK do pref = 1
						if pref < 3 do
						(
							local lastPath = getIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini" ) "SwitchRenderer" "LastKrakatoaOutputPath" 
							if lastPath != "" do 
							if pref == 2  or (querybox ("Previous Krakatoa Output Save Path Found:\n\n"+lastPath+"\n\nDo you want to restore it?") title:"Restore Krakatoa Save Path") do
								rendOutputFilename = lastPath
						)

						local theManager = maxOps.GetCurRenderElementMgr()
						theManager.RemoveAllRenderElements()						
						if KrakatoaLastRendererStorage[3] != undefined do
						(
							theManager.SetElementsActive KrakatoaLastRendererStorage[3][1]
							theManager.SetDisplayElements KrakatoaLastRendererStorage[3][2]
							local theCount = KrakatoaLastRendererStorage[3][3]
							for i = 1 to theCount do
							(
								theManager.AddRenderElement KrakatoaLastRendererStorage[3][i+3]
							)
						)
						
						
						if lastRenderDialogState do renderSceneDialog.Open()		
						FranticParticleRenderMXS.displayRendererSwitchPrompt()						
					)
					#no:
					(
						KrakatoaLastRendererStorage[2] = renderers.current
						renderers.current = Krakatoa()	
						FranticParticleRenderMXS.displayRendererSwitchPrompt()
					)
					#cancel: 
					( 
						FranticParticles.LogDebug ("  -Krakatoa assignment canceled by user.")
						popPrompt()
						pushprompt "Krakatoa assignment canceled."					
						return 0 
					)				
				)
			)
			else --Krakatoa is not stored in memory
			(
				txt +="NO PREVIOUS Krakatoa settings were found\nin the memory storage.\n\n"
				txt +="Press [Yes] to SET [Krakatoa] as the current renderer with DEFAULT settings.\n"
				txt +="Press [No] to LEAVE ["+ (classof renderers.current) as string + "] as the current renderer.\n"
				local q = querybox txt title:("Switch To Krakatoa v" + FranticParticles.Version)
				if q then
				(
					local lastRenderDialogState =renderSceneDialog.isOpen()
					renderSceneDialog.close()
					setIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini" ) "SwitchRenderer" "LastNonKrakatoaOutputPath" rendOutputFilename 
					
					KrakatoaLastRendererStorage[2] = renderers.current
					renderers.current = Krakatoa()
					renderers.medit_locked=false
					renderers.medit = Default_Scanline_Renderer()
					local pref = execute (getIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini" ) "Preferences" "StoreRenderOutputPathOnRenderSwitchBehavior")
					if pref == OK do pref = 1
					if pref < 3 do
					(
						local lastPath = getIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini" ) "SwitchRenderer" "LastKrakatoaOutputPath" 
						if lastPath != "" do 
						if pref == 2  or (querybox ("Previous Krakatoa Output Save Path Found:\n\n"+lastPath+"\n\nDo you want to restore it?") title:"Restore Krakatoa Save Path") do
							rendOutputFilename = lastPath
					)
					if lastRenderDialogState do renderSceneDialog.Open()		
					FranticParticleRenderMXS.displayRendererSwitchPrompt()					
				)
				else
				(
					FranticParticles.LogDebug ("  -Krakatoa assignment canceled by user.")
					popPrompt()
					pushprompt "Krakatoa assignment canceled."					
					return 0 					
				)
			)
		)
	)
	
	try(destroyDialog Krakatoa_SavePresetDialog)catch()
	try(closeRolloutFloater Krakatoa_Preferences_Floater)catch()	
	try(destroyDialog Krakatoa_GUI_Notes)catch()	
	try(destroyDialog Krakatoa_GUI_About)catch()	
	try(closeRolloutFloater Krakatoa_SceneExplorersFloater)catch()
	
	
	--MAKE SURE THE PREFERENCES ARE INITIALIZED TO BEGINNER MODE THE FIRST TIME KRAKATOA IS RUN

	local KrakatoaPreferencesINI = GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini"
	if getIniSetting KrakatoaPreferencesINI "Preferences" "StoreRenderOutputPathOnRenderSwitchBehavior" == "" do
	(
		setIniSetting KrakatoaPreferencesINI "Preferences" "StoreRenderOutputPathOnRenderSwitchBehavior" "1"
		FranticParticles.LogDebug "+Render Output Path Restore Preference Set To BEGINNER Setting."
	)
	
	if getIniSetting KrakatoaPreferencesINI "Preferences" "SwitchedToRendererMessageBehavior" == "" do
	(
		setIniSetting KrakatoaPreferencesINI "Preferences" "SwitchedToRendererMessageBehavior" "1"
		FranticParticles.LogDebug "+Switch To Previous Renderer Message Preference Set To BEGINNER Setting."
	)
	
	if getIniSetting KrakatoaPreferencesINI "Preferences" "OpenRenderElementsTabOnChange" == "" do
	(
		setIniSetting KrakatoaPreferencesINI "Preferences" "OpenRenderElementsTabOnChange" "2"
		FranticParticles.LogDebug "+Render Elements Tab Opening Preference Set To ADVANCED Setting."
	)		
	
	if getIniSetting KrakatoaPreferencesINI "Preferences" "RealFlowBinFileSaving" == "" do
	(
		setIniSetting KrakatoaPreferencesINI "Preferences" "RealFlowBinFileSaving" "1"
		FranticParticles.LogDebug "+RealFlow4 BIN Files Saving Preference Set To BEGINNER Setting."
	)		
	if getIniSetting KrakatoaPreferencesINI "Preferences" "SaveModeTogglePartitionsRollout" == "" do
	(
		setIniSetting KrakatoaPreferencesINI "Preferences" "SaveModeTogglePartitionsRollout" "2"
		FranticParticles.LogDebug "+Save Mode Toggle Partition Rollout Preference Set To ADVANCED Setting."
	)
	if getIniSetting KrakatoaPreferencesINI "Preferences" "CreateLoadersBehavior" == "" do
	(
		setIniSetting KrakatoaPreferencesINI "Preferences" "CreateLoadersBehavior" "1"	
		FranticParticles.LogDebug "+Create Loaders Behavior Preference Set To BEGINNER Setting."
	)	
	if getIniSetting KrakatoaPreferencesINI "Preferences" "AddFileSequenceBehavior" == "" do
	(
		setIniSetting KrakatoaPreferencesINI "Preferences" "AddFileSequenceBehavior" "1"	
		FranticParticles.LogDebug "+Add File Sequence To Loaders Behavior Preference Set To BEGINNER Setting."
	)	
	if getIniSetting KrakatoaPreferencesINI "Preferences" "CreatePRTVolumeBehavior" == "" do
	(
		setIniSetting KrakatoaPreferencesINI "Preferences" "CreatePRTVolumeBehavior" "1"	
		FranticParticles.LogDebug "+PRT Volume From Selection Behavior Preference Set To BEGINNER Setting."
	)	
	
	
/*	FranticParticles.LogDebug ">Unregistering Krakatoa Render History Callbacks..."
	callbacks.removeScripts id:#KrakatoaRenderHistory
	FranticParticles.LogDebug ">Registering Krakatoa Render History Callbacks..."
	callbacks.addScript #preRenderFrame "try(FranticParticleRenderMXS.framePreRender()) catch()" id:#KrakatoaRenderHistory
	callbacks.addScript #postRender "try(FranticParticleRenderMXS.framePostRender()) catch(); try(FranticParticleRenderMXS.saveRenderHistory()) catch()" id:#KrakatoaRenderHistory	
	*/
	if  initOnly then
	(
		Krakatoa_CustomizeRollouts_Dialog.updateHidden()		
		FranticParticles.LogProgress ("+Krakatoa GUI INITIALIZED in " + (timestamp() - openGUIst) as string + "ms."  )
	)
	else
	(
		--FranticParticleRenderMXS.DetectDeadline forceloading:false
		try(closeRolloutFloater Krakatoa_Gui_floater) catch()
		try(closeRolloutFloater Krakatoa_Gui_floater_3)catch()
		theSize = execute (FranticParticles.GetProperty "GUI:Size")	
		theKVersion = FranticParticles.Version 
		local theTitle =  ("Krakatoa v" + theKVersion + " - Primary Floater "  )
		local thePos = FranticParticles.GetProperty "GUI:Position"
		if thePos != undefined do thePos = execute thePos
		if classof thePos == Point2 then
		(
			thePos = FranticParticleRenderMXS.AdjustDialogPositionOnDesktop thePos 470 400 dialogName:"Main Floater"	
			Krakatoa_Gui_floater = newRolloutFloater theTitle theSize.x theSize.y thePos.x thePos.y
			FranticParticles.LogDebug "+Created Krakatoa GUI Floater At Last Position Stored In Renderer."
		) 
		else
		(
			thePos = execute (getINIsetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "Dialog" "Position")
			if thePos != OK then
			(
				thePos = FranticParticleRenderMXS.AdjustDialogPositionOnDesktop thePos 470 400 dialogName:"Main Floater"	
				Krakatoa_Gui_floater = newRolloutFloater theTitle theSize.x theSize.y thePos.x thePos.y
				FranticParticles.LogDebug "+Created Krakatoa GUI Floater At Last Position Stored In INI File."
			)
			else
			(		
				Krakatoa_Gui_floater = newRolloutFloater theTitle  theSize.x theSize.y	
				FranticParticles.LogDebug "+Created Krakatoa GUI Floater At Default Position"
			)	
		)
		
		Krakatoa_Gui_floater_3 = newRolloutFloater "Krakatoa OFF" theSize.x theSize.y -10000 -10000
		try(Krakatoa_GUI_Floater_3.visible = false)catch()

		addRollout Krakatoa_CustomizeRollouts_Dialog Krakatoa_Gui_floater
		defineShaderRollout (FranticParticles.GetProperty "PhaseFunction")
		
		local allRollouts = #(
			Krakatoa_GUI_RenderGlobalValues,
			Krakatoa_GUI_Main,
			Krakatoa_GUI_SaveParticles,
			Krakatoa_GUI_Partition, 
			Krakatoa_GUI_Channels, 
			Krakatoa_GUI_MatteObjects, 
			Krakatoa_GUI_AmbientPME,
			Krakatoa_GUI_Presets
		)	
	
		for i in allRollouts do
		(
			local st1 = timestamp()
			local theState = execute (getIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "RolloutVisible" i.title)
			if theState == OK do theState = true
				
			if theState then
			(
				local st2 = timestamp()
				local theDockedState = execute (getIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "RolloutDocked" i.title)
				if theDockedState == OK do theDockedState = true
				local theDockHost = (getIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "RolloutDockHost" i.title)
				if theDockHost == "" do theDockHost = "1"
				FranticParticles.LogDebug ("+Preparation For Docking Took " + (timestamp() - st2) as string + " milliseconds."	)						
				
				local st2 = timestamp()				
				if theDockedState then
				(	
						if theDockHost == "2" then
							FranticParticleRenderMXS.floatOrDockRollout i forceMode:#dock2
						else	
							FranticParticleRenderMXS.floatOrDockRollout i forceMode:#dock
				)
				else
					FranticParticleRenderMXS.floatOrDockRollout i forceMode:#float
				FranticParticles.LogDebug ("+FloatOrDockRollout() Took " + (timestamp() - st2) as string + " milliseconds."	)
				FranticParticles.LogDebug ("+Added '" + i.title +"' Rollout to Krakatoa GUI Floater.")
			)	
			else
				FranticParticleRenderMXS.floatOrDockRollout i forceMode:#hide
			FranticParticles.LogDebug ("+Processing '"+ i.title +"' took " + (timestamp() - st1) as string + " milliseconds."	)	
		)
		
		FranticParticleRenderMXS.updateIconColors()
		Krakatoa_CustomizeRollouts_Dialog.updateHidden()		

		--defineShaderRollout (FranticParticles.GetProperty "PhaseFunction")

		
		if Krakatoa_GUI_Presets.open do Krakatoa_GUI_Presets.compareSettings()

		global KrakatoaGuiOpen = true
		updateToolbarButtons()
		try(if execute (getIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "System" "AutoIncreasePflowSystemLimit" ) then FranticParticleRenderMXS.increasePFlowSystemLimits())catch(FranticParticleRenderMXS.increasePFlowSystemLimits())
		FranticParticles.LogProgress ("+Krakatoa GUI Floater OPENED in " + (timestamp() - openGUIst) as string + "ms."  )
	)--end if initOnly
	
	FranticParticles.LogDebug (">FN OpenGUI() Ended.")
),--end OpenGUI fn

fn convertTransform theTM =
(
	local theString = "\n\t"+ theTM.row1.x as string + "," + theTM.row1.y as string + "," +theTM.row1.z as string +",0, \n" 
	theString += "\t"+theTM.row2.x as string + "," + theTM.row2.y as string + "," +theTM.row2.z as string +",0, \n"
	theString += "\t"+theTM.row3.x as string + "," + theTM.row3.y as string + "," +theTM.row3.z as string +",0, \n"
	theString += "\t"+theTM.row4.x as string + "," + theTM.row4.y as string + "," +theTM.row4.z as string +",1 "	
	theString
),
fn convertColorToPython theColor =
(
	theColor /= 255.0
	"("+theColor.r as string + "," + theColor.g as string + "," + theColor.b as string + ")"
),
fn HFOV2VFOV theHAngle theAspect =
(
	2.0 * atan (tan (theHAngle/2) /theAspect)
),
fn validateObjectNameAsFileName theName =
(
	local newName = ""
	for i = 1 to theName.count do
	(
		local theCode = bit.charAsInt theName[i]
		if i > 1 AND (theCode < 48 OR (theCode > 57 AND theCode < 65) OR (theCode > 90 AND theCode < 97) OR theCode > 122) then 
			newName +="_"
		else 
			newName +=theName[i]
	)
	newName
),

fn collectHashSubAnims obj =
(
	if obj != undefined do append Krakatoa_HashSubAnims obj
	for i = 1 to obj.numsubs do
	(
		try(FranticParticleRenderMXS.collectHashSubAnims obj[i].object)catch(FranticParticleRenderMXS.collectHashSubAnims obj[i])
	)
),

fn prepareOBJExporterForKSR =
(
	local theObjIni = objexp.getIniName()
	setIniSetting theObjIni "General" "Preset" "<NONE>"
	setIniSetting theObjIni "Geometry" "FlipZyAxis" "0"
	setIniSetting theObjIni "Geometry" "Shapes" "0"
	setIniSetting theObjIni "Geometry" "ExportHiddenObjects" "0"
	setIniSetting theObjIni "Geometry" "FaceType" "0"
	setIniSetting theObjIni "Geometry" "TextureCoords" "0"
	setIniSetting theObjIni "Geometry" "Normals" "1"
	setIniSetting theObjIni "Geometry" "ObjScale" "1.000000"
	setIniSetting theObjIni "Material" "UseMaterial" "0"
	setIniSetting theObjIni "Output" "RelativeIndex" "0"
	setIniSetting theObjIni "Output" "Target" "0"
	setIniSetting theObjIni "Output" "Precision" "4"
	setIniSetting theObjIni "Optimize" "optVertex" "0"
	setIniSetting theObjIni "Optimize" "optNormals" "0"
	setIniSetting theObjIni "Optimize" "optTextureCoords" "0"
),

fn getHashString obj =
(
	local st = timestamp()
	Krakatoa_HashSubAnims = #()
	FranticParticleRenderMXS.collectHashSubAnims obj
	local theTotalString = "" as stringStream 
	for i in Krakatoa_HashSubAnims do 
		format "%\n" (try(i.value)catch("")) to:theTotalString
	for i in ::getPropNames obj do --need to enforce global scope to access the native getPropNames function
		format "%\n" (getProperty obj i) to:theTotalString
	for m in obj.modifiers where classof m == Magmamodifier and m.enabled do
		format "%\n" (MagmaFlowEditor_Functions.emitMAXScriptCode m.MagmaHolder) to:theTotalString 
	
	local theHash = ((dotNetObject "System.String" ( theTotalString as string )).GetHashCode()) as string
	theTotalString = undefined
	FranticParticles.LogDebug ("  >HashCode Generation Time for ["+obj.name+"] was "+ (timestamp()-st) as string + " milliseconds." )
	theHash	
),
	
fn exportPythonFile =
(
	local sttotal = timestamp()
	FranticParticles.LogProgress ("                                                                 ")
	FranticParticles.LogProgress ("-----" +localtime + "--------------------------")
	FranticParticles.LogProgress (">Export To Krakatoa SR Python Scene File Requested.") 
	renderSceneDialog.commit()	--Make sure the render dialog is updated
	if rendOutputFilename == "" do 
	(
		FranticParticles.LogError ("--Failed to Export To Krakatoa SR - no output file name specified!")
		messagebox "Cannot EXPORT the scene for Krakatoa SR - no output file name specified!\n\nPlease specify the render output file name in the Render Setup dialog..." title:"Krakatoa SR Export Error"
		renderSceneDialog.open()
		return false --if the render output file name is not specified, get out of here...
	)
		
	--Create a Python file in the output folder:
	local theFileName = getFileNamePath rendOutputFilename + "SCENE\\" +getFileNamefile rendOutputFilename  + ".py"
	theFileName = FranticParticles.ReplaceSequenceNumber theFileName (currentTime.frame as integer)
	local result = makeDir (getFileNamePath theFileName) all:true
	if result then 
		FranticParticles.LogProgress ("+Created Scene Output Folder ["+getFileNamePath theFileName+"]") 
	else 
	(
		FranticParticles.LogError ("--FAILED To Create Scene Output Folder ["+getFileNamePath theFileName+"]")
		return false
	)
	
	local theFile = createFile theFileName
	if theFile != undefined then 
		FranticParticles.LogProgress ("+Writing To Scene File ["+theFileName+"]") 
	else
	(
		FranticParticles.LogError ("--FAILED To Create Scene File ["+theFileName+"]") 
		return false
	)
	
	--Output Header Info:
	format "#==============================================================\n" to:theFile
	format "# Krakatoa SR Scene File \n" to:theFile
	format "# Exported using Krakatoa MX v%\n" FranticParticles.Version to:theFile
	format "# Exported from %\n" (FranticParticleRenderMXS.getMaxVersionString()) to:theFile
	format "# Exported by %@% on %\n" sysinfo.username sysinfo.computername localtime to:theFile
	format "#==============================================================\n" to:theFile
	format "# Source File: %\n" maxFileName  to:theFile
	format "# Source Path: %\n" maxFilePath to:theFile
	format "#==============================================================\n" to:theFile
	format "\n" to:theFile

	format "from datetime import datetime\n" to:theFile		
	format "import KrakatoaSR\n" to:theFile
	format "ri = KrakatoaSR.Ri()\n\n" to:theFile
		
	local theBGColor =  if (FranticParticles.GetBoolProperty "UseEnvironmentColor") then backgroundColor else execute (FranticParticles.GetProperty "BackgroundColor")
	format "ri.Option( \"render\", \"BackgroundColor\", % )\n" (FranticParticleRenderMXS.convertColorToPython theBGColor) to:theFile  --#if not set, black is used.

	--Define the supported properties to be exporter.
	--Array elements contain the KrakatoaSR name, the KrakatoaMX name, and the Value Type
	local thePropertiesToExport = #(
		#("DensityPerParticle","Density:DensityPerParticle", #value),
		#("DensityExponent","Density:DensityExponent", #value),
		#("UseEmissionColor","UseEmissionColor",#boolean),
		#("VoxelFilterRadius","VoxelFilterRadius", #value),
		#("VoxelSize","VoxelSize", #value),
		#("DrawPointFilter","DrawPointFilter", #string),
		#("AttenuationLookupFilter","AttenuationLookupFilter",#string),
		#("AdditiveMode","AdditiveMode",#boolean),
		#("SaveMultipleLayers","Matte:SaveMultipleLayers", #boolean),
		--#("EnableDepthOfField","EnableDepthOfField",#boolean),
		#("DepthOfFieldSampleRate","DepthOfFieldSampleRate", #value),
		#("MatteRendererRayDivisions","Matte:RayDivisions", #value),
		#("MotionBlurJitterParticles", "JitteredMotionBlur", #boolean)
	)
	
	--Loop through all properties and write them out as Options:
	for p in thePropertiesToExport do 
	(
		local theVal = (FranticParticles.GetProperty p[2])
		if p[3] == #Boolean do theVal = if execute theVal then "True" else "False"
		if p[3] == #Color do 
			theVal = FranticParticleRenderMXS.convertColorToPython (execute theVal)
		if p[3] == #string then
			format "ri.Option( \"render\", \"%\", \"%\" )\n" p[1] theVal  to:theFile
		else
			format "ri.Option( \"render\", \"%\", % )\n" p[1] theVal  to:theFile
	)
	
	format "ri.Option( \"render\", \"MotionBlurParticleSegments\", % )\n" (FranticParticles.getProperty "MotionBlurSegments" )  to:theFile
	
	local thePrefix = if FranticParticles.GetBoolProperty "Density:LinkLightingAndRenderingDensity" then "#" else ""
	format "%ri.Option( \"render\", \"LightingDensityPerParticle\", % )\n" thePrefix (FranticParticles.GetProperty "Lighting:Density:DensityPerParticle") to:theFile  --#if not set, "DensityPerParticle" is used.
	format "%ri.Option( \"render\", \"LightingDensityExponent\", % )\n" thePrefix (FranticParticles.GetProperty "Lighting:Density:DensityExponent") to:theFile    --#if not set, "DensityExponent" is used.
	
	local thePrefix = if FranticParticles.GetBoolProperty "Emission:UseStrength" then "" else "#"
	format "%ri.Option( \"render\", \"EmissionStrength\", % )\n" thePrefix (FranticParticles.GetProperty "Emission:Strength" ) to:theFile            --#if not set, "DensityPerParticle" is used.
	format "%ri.Option( \"render\", \"EmissionStrengthExponent\", % )\n" thePrefix (FranticParticles.GetProperty "Emission:StrengthExponent" )  to:theFile    --#if not set, "DensityExponent" is used.
	
	local theRenderMethod = case (FranticParticles.GetProperty "RenderingMethod") of
	(
		default: "particle"
		"Voxel Rendering": "voxel"
	)
	format "ri.Option( \"render\", \"RenderingMethod\", \"%\" )  \n" theRenderMethod to:theFile --#value options are "particle", "voxel" and "raytrace"
	format "\n" to:theFile


	--GLOBAL OVERRIDES
	format "#==============================================================\n" to:theFile
	format "# GLOBAL OVERRIDES:\n" to:theFile
	format "#==============================================================\n" to:theFile
	local theColor = (execute (FranticParticles.GetProperty "ColorOverride:Color"))/255.0
	format "%ri.ChannelOperation( \"Set\", \"Color\", (%,%,%) )\n" (if FranticParticles.GetBoolProperty "ColorOverride:Enabled" then "" else "#") theColor.r theColor.g theColor.b to:theFile	
	local theColor = (execute (FranticParticles.GetProperty "EmissionOverride:Color"))/255.0
	format "%ri.ChannelOperation( \"Set\", \"Emission\", (%,%,%) )\n" (if FranticParticles.GetBoolProperty "EmissionOverride:Enabled" then "" else "#") theColor.r theColor.g theColor.b to:theFile	
	local theColor = (execute (FranticParticles.GetProperty "AbsorptionOverride:Color"))/255.0
	format "%ri.ChannelOperation( \"Set\", \"Absorption\", (%,%,%) )\n" (if FranticParticles.GetBoolProperty "AbsorptionOverride:Enabled" then "" else "#") theColor.r theColor.g theColor.b to:theFile	
	format "\n" to:theFile	
		
	--CAMERA:
	format "#==============================================================\n" to:theFile
	format "# FRAME / VIEW / CAMERA / OUTPUT:\n" to:theFile
	format "#==============================================================\n" to:theFile
	--Output the Frame info:
	local theFrameToRender = (currentTime.frame as integer)
	format "ri.FrameBegin( % )\n" theFrameToRender to:theFile
	format "ri.Format( %, %, % )\n" RenderWidth renderHeight RenderPixelAspect to:theFile
	format "ri.Display( \"%\", \"file\", \"rgba\" )\n" (filenameFromPath (FranticParticles.ReplaceSequenceNumber rendOutputFilename theFrameToRender))  to:theFile
	
	--RENDER ELEMENTS
	local theREMan = MaxOps.GetCurRenderElementMgr() 
	for j = 0 to (theREMan.numrenderelements() - 1) do
	(
		local theRE = theREMan.getrenderelement j
		local theREFilename = theREMan.GetRenderElementFileName j
		case (classof theRE) of
		(
			Krakatoa_Normal: format "ri.Display( \"+%\", \"file\", \"N\" )\n" (filenameFromPath (FranticParticles.ReplaceSequenceNumber theREFilename theFrameToRender))  to:theFile
			Krakatoa_ZDepth: format "ri.Display( \"+%\", \"file\", \"z\" )\n" (filenameFromPath (FranticParticles.ReplaceSequenceNumber theREFilename theFrameToRender))  to:theFile
			Krakatoa_Velocity: format "ri.Display( \"+%\", \"file\", \"Velocity\" )\n" (filenameFromPath (FranticParticles.ReplaceSequenceNumber theREFilename theFrameToRender))  to:theFile
			Krakatoa_OccludedLayer: format "ri.Display( \"+%\", \"file\", \"occluded\" )\n" (filenameFromPath (FranticParticles.ReplaceSequenceNumber theREFilename theFrameToRender))  to:theFile
		)
	)
	
	--Output the current view parameters:
	local theViewType = viewport.getType()  --get the current view type
	local theCamera = viewport.getCamera()
	local theFOV = viewport.getFOV()
	local theAspect = 1.0*renderWidth/renderHeight
	if theAspect > 1.0 do theFOV = FranticParticleRenderMXS.HFOV2VFOV theFOV theAspect 
		
	if theCamera != undefined do
	(
		local camMod = theCamera.modifiers[#Krakatoa_Camera] 
		if camMod != undefined do
		(
			local focalLengthInMM = GetRendApertureWidth() / (2.0 * tan( theCamera.fov * 0.5 ) )
			local focalLength = case units.SystemType of --FIXME: Add support for KM and MILES
			(
				#feet: (focalLengthInMM / (25.4*12))
				#inches:  (focalLengthInMM / 25.4)
				#centimeters: (focalLengthInMM / 10.0)
				#meters: (focalLengthInMM / 1000.0)
				default: focalLengthInMM
			)
			local fstop = if camMod.dofOn then ( camMod.fStop ) else ( 1e+10 )
			local focalDist = try
			(
				if matchPattern ((classof theCamera) as string) pattern:"*target*" then
					theCamera.targetDistance
				else
					theCamera.baseobject.targetDistance 
			)catch(100.0)
			if camMod.focalDepthOn do focalDist = camMod.focalDepth
				
			format "%ri.DepthOfField( %, %, % ) \n" (if FranticParticles.getBoolProperty "EnableDepthOfField" then "" else "#") fstop focalLength focalDist to:theFile
		)
	)
	
	--if the type is perspective, camera or light, use perspective, otherwise ortho 
	local theTypeString = if findItem #(#view_persp_user, #view_camera, #view_spot ) theViewType > 0 then 
		if theCamera != undefined and theCamera.orthoProjection then "orthographic" else "perspective"
	else
		"orthographic"
	format "ri.Projection( \"%\", \"fov\", % )\n" theTypeString theFOV to:theFile
		
	local ShutterDegrees = FranticParticles.GetFloatProperty "ShutterAngleInDegrees"
	local blurBias = FranticParticles.GetFloatProperty "ShutterBias"		
	local shutterValue = (ShutterDegrees/360.0) * ( 1.0/FrameRate)
	local shutterStart = -shutterValue*((1-blurBias)/2.0)
	local shutterEnd = shutterValue+shutterStart		
	format "%ri.Shutter( %,% ) \n\n" (if FranticParticles.GetBoolProperty "EnableMotionBlur" then "" else "#") shutterStart shutterEnd to:theFile		
		
	local theCamera = viewport.getCamera()
	if FranticParticles.GetBoolProperty "EnableMotionBlur" and isValidNode theCamera then 
	(
		format "ri.MotionBegin(\n" to:theFile
		local theTimes = for t = shutterStart to shutterEnd by ((shutterEnd-shutterStart)/9) collect t
		for t = 1 to theTimes.count-1 do
		(
			format "\t%,\n" theTimes[t] to:theFile
		)
		format "\t%)\n" theTimes[theTimes.count] to:theFile
		for t in theTimes do
		(
			at time (currentTime.frame+t*FrameRate) 
			(
				--format "Camera Time = %\n" (currentTime.frame+t) 
				local theTM = inverse theCamera.transform  --inverse of camera TM
				theTM *= matrix3 [1,0,0] [0,1,0] [0,0,-1] [0,0,0]
				format "ri.Transform( % )\n" (FranticParticleRenderMXS.convertTransform theTM) to:theFile
			)
			--format "ri.Transform( % )\n" (FranticParticleRenderMXS.convertTransform theTM) to:theFile
		)
		format "ri.MotionEnd()\n" to:theFile
	)
	else
	(
		local theTM =  getViewTM() --inverse of camera TM
		theTM *= matrix3 [1,0,0] [0,1,0] [0,0,-1] [0,0,0]
		format "ri.Transform( % )\n" (FranticParticleRenderMXS.convertTransform theTM) to:theFile
	)
	
	format "\n" to:theFile
	format "ri.WorldBegin()\n" to:theFile
	format "\n" to:theFile
		
	--EXPORT LIGHTS:
	format "#==============================================================\n" to:theFile
	format "# SCENE LIGHTS:\n" to:theFile
	format "#==============================================================\n" to:theFile
	
	for aLight in Lights where try(aLight.on)catch(false) do
	(
		format "ri.AttributeBegin()\n" to:theFile
		format "ri.Transform( % )\n" (FranticParticleRenderMXS.convertTransform aLight.transform) to:theFile
		
		local theType = if aLight.Type == #targetDirect or aLight.Type == #FreeDirect then "directlight" 
			else if aLight.Type == #targetSpot or aLight.Type == #FreeSpot then "spotlight" else "pointlight"
		
		format "ri.LightSource( \"%\", \"%\",\n" theType aLight.name to:theFile
		local theMultiplier = aLight.Multiplier * 4 * Pi
		theMultiplier /= (aLight.decayRadius^(aLight.attenDecay-1))
		local theFlux = aLight.color / 255.0 * theMultiplier
		format "\t\"Flux\", (%,%,%), \n" theFlux.r theFlux.g theFlux.b to:theFile
		format "\t\"DecayExponent\", %, \n" (aLight.attenDecay-1) to:theFile
		format "\t\"ShadowsEnabled\", %, \n" (if aLight.baseobject.castshadows then "True" else "False")  to:theFile
		format "\t\"ShadowDensity\", %, \n" aLight.shadowMultiplier to:theFile
		format "\t\"ShadowMapWidth\", %, \n" aLight.mapsize to:theFile
		format "\t\"UseNearAttenuation\", %, \n" (if aLight.useNearAtten then "True" else "False" ) to:theFile
		format "\t\"UseFarAttenuation\", %, \n" (if aLight.useFarAtten then "True" else "False" ) to:theFile
		format "\t\"NearAttenuationStart\", %, \n" aLight.nearAttenStart to:theFile
		format "\t\"NearAttenuationEnd\", %, \n" aLight.nearAttenEnd to:theFile
		format "\t\"FarAttenuationStart\", %, \n" aLight.farAttenStart to:theFile
		format "\t\"FarAttenuationEnd\", %, \n" aLight.farAttenEnd to:theFile
		if isProperty aLight "coneShape" do
		(
			format "\t\"LightShape\", \"%\",  \n" (if aLight.coneShape == 1 then "round" else "square") to:theFile
			format "\t\"LightAspect\", %, \n" aLight.aspect to:theFile
		)
		if theType == "spotlight" then 
		(
			format "\t\"InnerConeAngle\", %, \n" aLight.hotspot to:theFile
			format "\t\"OuterConeAngle\", %,	\n" aLight.falloff to:theFile			
		) 
		else if theType == "directlight" then
		(
			format "\t\"InnerRadius\", %, \n" aLight.hotspot to:theFile
			format "\t\"OuterRadius\", %,	\n" aLight.falloff to:theFile
		)
	
		--export the attenuation map saving property
		if ( FranticParticles.GetProperty "EnableAttenuationMapSaving" as BooleanClass ) then (
			if aLight.castShadows and classof aLight.shadowGenerator == Krakatoa_Shadows then
			(
				local savePath = aLight.shadowGenerator.ShadowSavePath
				if savePath != "" then
				(
					savePath = substituteString savePath "\\" "/"
					savePath = substituteString savePath "$renderdir" "."
					savePath = substituteString savePath "$objectname" aLight.name
					savePath = FranticParticles.ReplaceSequenceNumber  savePath (currentTime.frame as integer)
					format "\t\"AttenuationMapSavePath\", \"%\",	\n" savePath to:theFile
					format "\t\"AttenuationMapDepthSamples\", %,	\n" aLight.shadowGenerator.ShadowSampleCount to:theFile
					format "\t\"AttenuationMapSampleSpacing\", %,	\n" aLight.shadowGenerator.ShadowSampleSpacing to:theFile
					format "\t\"AttenuationMapExponentialSpacing\", %,	\n" ( if aLight.shadowGenerator.ShadowSampleSpacingIsExponential then "True" else "False" ) to:theFile
				)
			)
		)
		
		format ")\n" to:theFile
		format "ri.AttributeEnd()\n" to:theFile
		format "ri.Illuminate( \"%\", True )\n" aLight.name to:theFile
		format "\n" to:theFile
	)--end for aLight loop

	format "#==============================================================\n" to:theFile
	format "# PHASE FUNCTION:\n" to:theFile
	format "#==============================================================\n" to:theFile
	
	theShadingMode = FranticParticles.GetProperty "PhaseFunction"
	case theShadingMode of
	(
		"Isotropic": 
		(
			format "ri.Surface( \"Isotropic\" ) \n" to:theFile
		)
		"Phong Surface": 
		(
			format "ri.Surface( \"Phong Surface\", \n" to:theFile
			format "\t\"SpecularLevel\", %, \n" (FranticParticles.getProperty "Lighting:Specular:Level") to:theFile
			format "\t\"SpecularLevelVarying\", %, \n" (if matchPattern (FranticParticles.getProperty "Channel:Allocate:SpecularLevel") pattern:"true" then "True" else "False") to:theFile
			format "\t\"SpecularPower\", %, \n" (FranticParticles.getProperty "Lighting:Specular:SpecularPower") to:theFile
			format "\t\"SpecularPowerVarying\", % ) \n" (if matchPattern (FranticParticles.getProperty "Channel:Allocate:SpecularPower") pattern:"true" then "True" else "False") to:theFile
		)
		"Henyey-Greenstein":
		(
			format "ri.Surface( \"Henyey-Greenstein\", \n" to:theFile
			format "\t\"Eccentricity\", %, \n" (FranticParticles.getProperty "PhaseEccentricity") to:theFile
			format "\t\"EccentrictyVarying\", % ) \n" (if matchPattern (FranticParticles.getProperty "Channel:Allocate:PhaseEccentricity") pattern:"true" then "True" else "False") to:theFile
		)
		"Schlick":
		(
			format "ri.Surface( \"Schlick\", \n" to:theFile
			format "\t\"Eccentricity\", %, \n" (FranticParticles.getProperty "PhaseEccentricity") to:theFile
			format "\t\"EccentrictyVarying\", % ) \n" (if matchPattern (FranticParticles.getProperty "Channel:Allocate:PhaseEccentricity") pattern:"true" then "True" else "False") to:theFile
		)
		"Kajiya-Kay Hair":
		(
			format "ri.Surface( \"Kajiya-Kay Hair\", \n" to:theFile
			format "\t\"SpecularLevel\", %, \n" (FranticParticles.getProperty "Lighting:Specular:Level") to:theFile
			format "\t\"SpecularLevelVarying\", %, \n" (if matchPattern (FranticParticles.getProperty "Channel:Allocate:SpecularLevel") pattern:"true" then "True" else "False") to:theFile
			format "\t\"SpecularPower\", %, \n" (FranticParticles.getProperty "Lighting:Specular:SpecularPower") to:theFile
			format "\t\"SpecularPowerVarying\", % ) \n" (if matchPattern (FranticParticles.getProperty "Channel:Allocate:SpecularPower") pattern:"true" then "True" else "False") to:theFile
		)
		"Marschner Hair":
		(
			format "ri.Surface( \"Marschner\", \n" to:theFile
			format "\t\"SpecularGlossinessVarying\", %, \n" (if matchPattern (FranticParticles.getProperty "Shader:Marschner Hair:SpecularGlossiness:Varying") pattern:"true" then "True" else "False") to:theFile  
			format "\t\"SpecularGlossiness\", %, \n" (FranticParticles.getProperty "Shader:Marschner Hair:SpecularGlossiness") to:theFile 
			format "\t\"SpecularLevelVarying\", %, \n" (if matchPattern (FranticParticles.getProperty "Shader:Marschner Hair:SpecularLevel:Varying") pattern:"true" then "True" else "False") to:theFile
			format "\t\"SpecularLevel\", %, \n" (FranticParticles.getProperty "Shader:Marschner Hair:SpecularLevel") to:theFile 
			format "\t\"SpecularShiftVarying\", %, \n" (if matchPattern (FranticParticles.getProperty "Shader:Marschner Hair:SpecularShift:Varying") pattern:"true" then "True" else "False") to:theFile
			format "\t\"SpecularShift\", %, \n" (FranticParticles.getProperty "Shader:Marschner Hair:SpecularShift") to:theFile 
			format "\t\"Specular2GlossinessVarying\", %, \n" (if matchPattern (FranticParticles.getProperty "Shader:Marschner Hair:Specular2Glossiness:Varying") pattern:"true" then "True" else "False") to:theFile
			format "\t\"Specular2Glossiness\", %, \n" (FranticParticles.getProperty "Shader:Marschner Hair:Specular2Glossiness") to:theFile 
			format "\t\"Specular2LevelVarying\", %, \n" (if matchPattern (FranticParticles.getProperty "Shader:Marschner Hair:Specular2Level:Varying") pattern:"true" then "True" else "False") to:theFile
			format "\t\"Specular2Level\", %, \n" (FranticParticles.getProperty "Shader:Marschner Hair:Specular2Level") to:theFile 
			format "\t\"Specular2ShiftVarying\", %, \n" (if matchPattern (FranticParticles.getProperty "Shader:Marschner Hair:Specular2Shift:Varying") pattern:"true" then "True" else "False") to:theFile
			format "\t\"Specular2Shift\", %, \n" (FranticParticles.getProperty "Shader:Marschner Hair:Specular2Shift") to:theFile 
			format "\t\"GlintLevelVarying\", %, \n" (if matchPattern (FranticParticles.getProperty "Shader:Marschner Hair:GlintLevel:Varying") pattern:"true" then "True" else "False") to:theFile
			format "\t\"GlintLevel\", %, \n" (FranticParticles.getProperty "Shader:Marschner Hair:GlintLevel") to:theFile 
			format "\t\"GlintSizeVarying\", %, \n" (if matchPattern (FranticParticles.getProperty "Shader:Marschner Hair:GlintSize:Varying") pattern:"true" then "True" else "False") to:theFile
			format "\t\"GlintSize\", %, \n" (FranticParticles.getProperty "Shader:Marschner Hair:GlintSize") to:theFile 
			format "\t\"GlintGlossinessVarying\", %, \n" (if matchPattern (FranticParticles.getProperty "Shader:Marschner Hair:GlintGlossiness:Varying") pattern:"true" then "True" else "False") to:theFile
			format "\t\"GlintGlossiness\", %, \n" (FranticParticles.getProperty "Shader:Marschner Hair:GlintGlossiness") to:theFile 
			format "\t\"DiffuseLevelVarying\", %, \n" (if matchPattern (FranticParticles.getProperty "Shader:Marschner Hair:DiffuseLevel:Varying") pattern:"true" then "True" else "False") to:theFile
			format "\t\"DiffuseLevel\", % ) 	\n" (FranticParticles.getProperty "Shader:Marschner Hair:DiffuseLevel") to:theFile 
		)
	)
	format "\n" to:theFile	

	local stmatte = timestamp()
	local matteObjects = #()
	if FranticParticles.GetBoolProperty "Matte:UseMatteObjects" do
	(
		local useNamedSelectionSets = execute (FranticParticles.GetProperty "Matte:NamedSelectionSets")
		local matteSelSets = for i = 1 to selectionSets.count where findItem useNamedSelectionSets (getNamedSelSetName i) != 0 collect selectionSets[i]
			for i in matteSelSets do 
				join matteObjects (for o in i collect o)		
	)
	
	if matteObjects.count > 0 do
	(
		oldSel = selection as array
		prepareOBJExporterForKSR()
		
		FranticParticles.LogProgress (">Exporting "+  matteObjects.count  as string +" Matte Object"+(if matteObjects.count == 1 then "" else "s")+"...") 
		for i = 1 to matteObjects.count do 
		(
			local theFilenameToSave = (getFileNamePath rendOutputFilename + "MATTE\\" + FranticParticleRenderMXS.validateObjectNameAsFileName matteObjects[i].name +"_matte.obj")
			makeDir (getFileNamePath theFilenameToSave) all:true
			theFilenameToSave = FranticParticles.ReplaceSequenceNumber  theFilenameToSave (currentTime.frame as integer)
			
			select matteObjects[i]
			exportFile theFilenameToSave  #noPrompt selectedOnly:true
			FranticParticles.LogProgress ("  +Exported Matte Object ["+matteObjects[i].name+"] to ["+theFilenameToSave+"]") 
			
			format "#==============================================================\n" to:theFile
			format "# %/%: MATTE OBJECT  [%]:\n" i matteObjects.count matteObjects[i].name to:theFile
			format "#==============================================================\n" to:theFile
			format "ri.AttributeBegin()\n" to:theFile
			format "ri.Transform( % )\n" (FranticParticleRenderMXS.convertTransform (matrix3 1)) to:theFile
			format "ri.MeshFile( \"%\" )\n" ("MATTE/"+(filenameFromPath theFilenameToSave)) to:theFile
			format "ri.AttributeEnd()\n" to:theFile
			format "\n" to:theFile			
		)--end i loop
		
		select oldSel
		FranticParticles.LogProgress ("+FINISHED Exporting "+ matteObjects.count  as string + " Matte Object"+(if matteObjects.count == 1 then "" else "s")+" in "+ ((timestamp()-stmatte)/1000.0) as string + " seconds." ) 
	)
	
	if FranticParticles.GetBoolProperty "RenderKrakatoaLoaders" do
	(
		local stprt = timestamp()
		local thePRTLoaders = for o in objects where classof o.baseobject == KrakatoaPRTLoader collect o
		thePRTLoaders = for o in thePRTLoaders where o.enabledInRender and o.renderable and not o.isHiddenInVpt collect o			
		if thePRTLoaders.count > 0 do
		(
			FranticParticles.LogProgress (">Exporting "+  thePRTLoaders.count  as string +" Krakatoa PRT Loader Object"+(if thePRTLoaders.count == 1 then "" else "s")+"...") 
			for aLoader in thePRTLoaders do
			(		
				format "#==============================================================\n" to:theFile
				format "# PRT LOADER [%]:\n" aLoader.name to:theFile
				format "#==============================================================\n" to:theFile
				format "ri.AttributeBegin()\n" to:theFile
				local exportAsPRT = (execute (getIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "KSRPreferences" "ForcePRTAsPRTExport")) == true 	

				if not exportAsPRT and aLoader.material != undefined and isProperty aLoader.material #diffusecolor then
				(
					local c = aLoader.material.diffusecolor / 255.0
					format "ri.ChannelOperation( \"Set\", \"Color\", (%,%,%) )\n" c.r c.g c.b to:theFile
				)
				if aLoader.material != undefined and isProperty aLoader.material #diffusemap and aLoader.material.diffusemap != undefined do exportAsPRT = true
				
				local theMods = for m in aLoader.modifiers where m.enabled collect m --collect enabled modifiers
				if theMods.count > 0 do exportAsPRT = true --if there are any active modifiers, export as PRT
					
				if exportAsPRT then
				(
					format "ri.Transform( % )\n" (FranticParticleRenderMXS.convertTransform (matrix3 1)) to:theFile
					local theFilenameToSave = getFileNamePath rendOutputFilename + "PRT\\" + FranticParticleRenderMXS.validateObjectNameAsFileName aLoader.name + "_.prt"
					makeDir (getFileNamePath theFilenameToSave) all:true
					theFilenameToSave = FranticParticles.ReplaceSequenceNumber theFilenameToSave (currentTime.frame as integer)
					local result = try(FranticParticles.SaveParticleObjectsToFile #(aLoader) theFilenameToSave #() )catch(false)--save all relevant channels
					if result do
						format "ri.PointsFile( \"%\" )\n" ("PRT/"+filenameFromPath theFilenameToSave) to:theFile
					FranticParticles.LogProgress ("  +Exported PRT Loader Object ["+aLoader.name+"] to ["+theFilenameToSave+"]") 
				)
				else
				(
					if aLoader.useTransform then
						format "ri.Transform( % )\n" (FranticParticleRenderMXS.convertTransform aLoader.transform) to:theFile
					else
						format "ri.Transform( % )\n" (FranticParticleRenderMXS.convertTransform (matrix3 1)) to:theFile
					
					for i = 1 to aLoader.fileList.count do
					(
						local aFile = aLoader.fileList[i]
						local thePrefix = if bit.get aLoader.fileListFlags[i] 2 then "" else "#"
						if not aLoader.loadSingleFrame do 
							aFile = FranticParticles.ReplaceSequenceNumber aFile (currentTime.frame as integer)	
						format "%ri.PointsFile( \"%\" )\n" thePrefix (substituteString aFile "\\" "/") to:theFile
						FranticParticles.LogProgress ("  +Reusing PRT Loader Object ["+aLoader.name+"] File List: ["+aFile+"]") 
					)
				)
				format "ri.AttributeEnd()\n" to:theFile
				format "\n" to:theFile
			)--end aLoader loop
			FranticParticles.LogProgress ("+FINISHED Exporting "+  thePRTLoaders.count  as string +" PRT Loader Object"+(if thePRTLoaders.count == 1 then "" else "s")+" in "+ ((timestamp()-stprt)/1000.0) as string + " seconds." ) 
		)
	)
	
	if FranticParticles.GetBoolProperty "RenderParticleFlowGeometry" OR FranticParticles.GetBoolProperty "RenderParticleFlowBBox" OR FranticParticles.GetBoolProperty "RenderParticleFlowPhantom" do
	(
		local thePFSources = (for o in objects where classof o.baseobject == PF_Source and o.Enable_Particles collect o)
		for o in thePFSources do
		(
			local theEvents = for i in refs.dependents o where classof i == ParticleGroup and isProperty i #position collect i
			format "#==============================================================\n" to:theFile
			format "# PARTICLE FLOW [%] AS PRT:\n" o.name to:theFile
			format "#==============================================================\n" to:theFile
			format "ri.AttributeBegin()\n" to:theFile
			format "ri.Transform( % )\n" (FranticParticleRenderMXS.convertTransform (matrix3 1)) to:theFile
			local theFilenameToSave = getFileNamePath rendOutputFilename + "PRT\\" +FranticParticleRenderMXS.validateObjectNameAsFileName o.name + "_.prt"
			makeDir (getFileNamePath theFilenameToSave) all:true
			theFilenameToSave = FranticParticles.ReplaceSequenceNumber theFilenameToSave (currentTime.frame as integer)
			local result = FranticParticles.SaveParticleObjectsToFile theEvents theFilenameToSave #() --save all relevant channels, FIXME: Optional!
			format "ri.PointsFile( \"%\" )\n" ("PRT/"+filenameFromPath theFilenameToSave) to:theFile
			format "ri.AttributeEnd()\n" to:theFile
			format "\n" to:theFile		
			FranticParticles.LogProgress ("  +Exported Particle Flow ["+o.name+"] to ["+theFilenameToSave+"]") 				
		)
	)
	--FranticParticles.GetBoolProperty "RenderMaxParticles" 
	--FranticParticles.GetBoolProperty "RenderThinkingParticles" 
	--FranticParticles.GetBoolProperty "RenderGeometryVertices"
	
	local theObjectsToExport = #()
	if FranticParticles.GetBoolProperty "RenderGeometryVolumes" do join theObjectsToExport 	(for o in objects where classof o.baseobject == PRT_Volume collect o)
	if FranticParticles.GetBoolProperty "RenderFumeFX" do join theObjectsToExport 	(for o in objects where classof o.baseobject == PRT_FumeFX collect o)
	--if FranticParticles.GetBoolProperty "RenderPRTCreator" do join theObjectsToExport 	(for o in objects where classof o.baseobject == PRT_Maker collect o)
	if FranticParticles.GetBoolProperty "RenderPRTSource" do join theObjectsToExport 	(for o in objects where classof o.baseobject == PRT_Source collect o)
	theObjectsToExport = for o in theObjectsToExport where o.renderable and not o.isHiddenInVpt collect o
	if theObjectsToExport.count > 0 do
	(
		local stprt = timestamp()
		FranticParticles.LogProgress (">Exporting "+  theObjectsToExport.count  as string +" Object"+(if theObjectsToExport.count == 1 then "" else "s")+" As PRT...") 
		for o in theObjectsToExport do
		(
			local theFilenameToSave = getFileNamePath rendOutputFilename + "PRT\\" +FranticParticleRenderMXS.validateObjectNameAsFileName o.name + "_.prt"
			theFilenameToSave = FranticParticles.ReplaceSequenceNumber theFilenameToSave (currentTime.frame as integer)
			local needToSave = true
			local theCurrentHash = FranticParticleRenderMXS.getHashString o 
			if doesFileExist theFilenameToSave do
			(
				local theOldHash = getIniSetting (getFileNamePath rendOutputFilename + "PRT\\Hash.ini") (FranticParticleRenderMXS.validateObjectNameAsFileName o.name) ((currentTime.frame as integer) as string) 
				if matchPattern theOldHash pattern:theCurrentHash do needToSave = false
			)
			
			format "#==============================================================\n" to:theFile
			format "# % OBJECT [%] AS PRT:\n" (classof o.baseobject) o.name to:theFile
			format "#==============================================================\n" to:theFile
			format "ri.AttributeBegin()\n" to:theFile
			format "ri.Transform( % )\n" (FranticParticleRenderMXS.convertTransform (matrix3 1)) to:theFile
			
			if needToSave then
			(
				makeDir (getFileNamePath theFilenameToSave) all:true
				local result = FranticParticles.SaveParticleObjectsToFile #(o) theFilenameToSave #() --save all relevant channels, FIXME: Optional!
				setIniSetting (getFileNamePath rendOutputFilename + "PRT\\Hash.ini") (FranticParticleRenderMXS.validateObjectNameAsFileName o.name) ((currentTime.frame as integer) as string) theCurrentHash 
				FranticParticles.LogProgress ("  +Exported "+ (classof o.baseobject) as string+" Object ["+o.name+"] to ["+theFilenameToSave+"]") 
				
			)
			else
				FranticParticles.LogProgress ("  >Skipping PRT export of " + (classof o.baseobject) as string+" Object ["+o.name +"] due to matching HashCode ["+theCurrentHash+"]") 
			
			format "ri.PointsFile( \"%\" )\n" ("PRT/"+filenameFromPath theFilenameToSave) to:theFile
			format "ri.AttributeEnd()\n" to:theFile
			format "\n" to:theFile		
		)
		FranticParticles.LogProgress ("+FINISHED Exporting "+  theObjectsToExport.count  as string +" Object"+(if theObjectsToExport.count == 1 then "" else "s")+" As PRTs in "+ ((timestamp()-stprt)/1000.0) as string + " seconds." ) 
	)
	
	if FranticParticles.GetBoolProperty "RenderPRTCreator" do (
		local theObjectsToExport = #()
		join theObjectsToExport 	(for o in objects where classof o.baseobject == PRT_Maker collect o)
		format "we;'re going to export % makers\n" ((theObjectsToExport.count) as string)
		
		--TODO: CHECK IF WE NEED TO EXPORT THIS AS A PRT (LIKE THE HAIR DOES BELOW)
		for aPRTMaker in theObjectsToExport do
		(
				FranticParticles.LogProgress (">Exporting PRT Maker Object ["+aPRTMaker.name+"]...") 				
				format "#==============================================================\n" to:theFile
				format "#PRT MAKER [%]:\n" aPRTMaker.name to:theFile
				format "#==============================================================\n" to:theFile
				format "ri.AttributeBegin()\n" to:theFile
				format "ri.Transform( % )\n" (FranticParticleRenderMXS.convertTransform (aPRTMaker.transform)) to:theFile
				local particleCount = aPRTMaker.ParticleCount
				local randomSeed = aPRTMaker.RandomSeed
				local affineTMCount = aPRTMaker.tmControllers.count
				local colorGradCount = 2
				local exportStr = "ri.FractalPoints( " + (particleCount as string) + ", " + (randomSeed as string) + ", " + (affineTMCount as string) + ", " + (colorGradCount as string) + ","
				format "%\n" exportStr to:theFile
				for i=1 to aPRTMaker.tmControllers.count do (
					local pos = aPRTMaker.tmControllers[i].base_transform.Position
					exportStr = "    \"AffineTMPosition[" + ((i-1) as string) + "]\", (" + (pos.x as string) + ", " + (pos.y as string) + ", " + (pos.z as string) + "),"
					format "%\n" exportStr to:theFile
					local rot = aPRTMaker.tmControllers[i].base_transform.Rotation
					exportStr = "    \"AffineTMRotation[" + ((i-1) as string) + "]\", (" + (rot.x as string) + ", " + (rot.y as string) + ", " + (rot.z as string) + ", " + (rot.w as string) + "),"
					format "%\n" exportStr to:theFile
					local tscale = aPRTMaker.tmControllers[i].base_transform.Scale
					exportStr = "    \"AffineTMScale[" + ((i-1) as string) + "]\", (" + (tscale.x as string) + ", " + (tscale.y as string) + ", " + (tscale.z as string) + "),"
					format "%\n" exportStr to:theFile
					local skewO = aPRTMaker.tmControllers[i].Skew_Orientation.value
					exportStr = "    \"AffineTMSkew[" + ((i-1) as string) + "]\", (" + (skewO.x as string) + ", " + (skewO.y as string) + ", " + (skewO.z as string) + ", " + (skewO.w as string) + "),"
					format "%\n" exportStr to:theFile
					local skewA = aPRTMaker.tmControllers[i].Skew_Angle
					exportStr = "    \"AffineTMSkewAngle[" + ((i-1) as string) + "]\", " + (skewA as string) + ","
					format "%\n" exportStr to:theFile
					local weight = aPRTMaker.tmControllers[i].Weight
					exportStr = "    \"AffineTMWeight[" + ((i-1) as string) + "]\", " + (weight as string) + ","
					format "%\n" exportStr to:theFile
				)
				format ") \n\n" to:theFile
					
				format "ri.AttributeEnd()\n" to:theFile
				format "\n" to:theFile
				FranticParticles.LogProgress ("+FINISHED Exporting PRT Maker Object "+ aPRTMaker.name +"." ) 
		)
		
	)	
	
	if FranticParticles.GetBoolProperty "RenderPRTHair" do
	(
		local stprt = timestamp()
		local thePRTHairs = for o in objects where classof o.baseobject == PRT_Hair collect o
		thePRTHairs = for o in thePRTHairs where o.renderable and not o.isHiddenInVpt collect o			
		local exportAsPRT = (execute (getIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "KSRPreferences" "ForceHairAsPRTExport")) == true
		for aHair in thePRTHairs do
		(
			local theMods = for m in aHair.modifiers where m.enabled collect m --collect enabled modifiers
			if theMods.count > 0 do exportAsPRT = true --if there are any active modifiers, export as PRT
			if aHair.material != undefined and classof aHair.material == Standard and aHair.material.diffusemap != undefined do exportAsPRT = true
			if aHair.TargetNode == undefined do exportAsPRT = true
			
			if not exportAsPRT then
			(
				FranticParticles.LogProgress (">Exporting PRT Hair Object ["+aHair.name+"] As Splines...") 				
				format "#==============================================================\n" to:theFile
				format "#PRT HAIR [%] FROM SPLINE NODE [%]:\n" aHair.name aHair.TargetNode.name to:theFile
				format "#==============================================================\n" to:theFile
				format "ri.AttributeBegin()\n" to:theFile

				format "ri.Transform( % )\n" (FranticParticleRenderMXS.convertTransform (aHair.transform)) to:theFile
				
				if classof aHair.material == Standard do
				(
					local c = aHair.material.diffusecolor / 255.0
					format "ri.ChannelOperation( \"Set\", \"Color\", (%,%,%) )\n" c.r c.g c.b to:theFile
				)
				format "ri.Option( \"curves\", \"WorldSpacing\", % ) \n" aHair.Spacing to:theFile
				format "ri.Option( \"curves\", \"DensityFalloff\", % ) \n" aHair.DensityFalloff to:theFile
				
				--format "ri.Option( "curves", "PixelSpacing", 0.5 ) \n" to:theFile
				
				local theTarget = getFileNamePath rendOutputFilename + "CURVES\\"+ FranticParticleRenderMXS.validateObjectNameAsFileName aHair.name + "_.curves"
				makeDir (getFileNamePath theTarget) all:true
				FranticParticles.SaveHairFile false aHair.TargetNode theTarget currentTime.frame currentTime.frame
				format "ri.CurvesFile( \"%\") \n" ("CURVES\\"+FranticParticles.ReplaceSequenceNumber (fileNameFromPath theTarget) (currentTime.frame as integer)) to:theFile
				format "ri.AttributeEnd()\n" to:theFile
				format "\n" to:theFile
				FranticParticles.LogProgress ("+FINISHED Exporting PRT Hair Object "+ aHair.name +" As Splines in "+ ((timestamp()-stprt)/1000.0) as string + " seconds." ) 
			)--end if

			if exportAsPRT and thePRTHairs.count > 0 do
			(
				FranticParticles.LogProgress (">Exporting "+  thePRTHairs.count  as string +" PRT Hair Object"+(if thePRTHairs.count == 1 then "" else "s")+" As PRT...") 
				for o in thePRTHairs do
				(
					format "#==============================================================\n" to:theFile
					format "# PRT HAIR [%] AS PRT:\n" o.name to:theFile
					format "#==============================================================\n" to:theFile
					format "ri.AttributeBegin()\n" to:theFile
					local theFilenameToSave = getFileNamePath rendOutputFilename + "PRT/"+ FranticParticleRenderMXS.validateObjectNameAsFileName o.name + "_.prt"
					makeDir (getFileNamePath theFilenameToSave) all:true
					theFilenameToSave = FranticParticles.ReplaceSequenceNumber theFilenameToSave (currentTime.frame as integer)
					local result = FranticParticles.SaveParticleObjectsToFile #(o) theFilenameToSave #() --save all relevant channels
					format "ri.Transform( % )\n" (FranticParticleRenderMXS.convertTransform (matrix3 1)) to:theFile
					format "ri.PointsFile( \"%\" )\n" ("PRT\\"+filenameFromPath theFilenameToSave) to:theFile
					format "ri.AttributeEnd()\n" to:theFile
					format "\n" to:theFile			
				)
				FranticParticles.LogProgress ("+Exporting "+ thePRTHairs.count  as string +" PRT Hair Object"+(if thePRTHairs.count == 1 then "" else "s")+" As PRT FINISHED in "+ ((timestamp()-stprt)/1000.0) as string + " seconds." ) 
			)--end if
		)--end a Hair loop
	)--end render hair
	format "#==============================================================\n" to:theFile
	format "t0 = datetime.now()\n" to:theFile
	format "ri.WorldEnd()\n" to:theFile
	format "t1 = datetime.now()\n" to:theFile
	format "print (t1-t0)	\n" to:theFile
	format "ri.FrameEnd()\n" to:theFile
	close theFile 
	
	local thePath = getIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "KSRPreferences" "PathToPythonExecutable"
	if not doesFileExist thePath do thePath = "c:\\python26\\python.exe"
	if not doesFileExist thePath do thePath = ""
	if thePath != "" do
	(
		local theBatFilename = getFileNamePath rendOutputFilename  + "RENDER_"+getFileNameFile rendOutputFilename + ".bat"
		theBatFilename = FranticParticles.ReplaceSequenceNumber theBatFilename (currentTime.frame as integer)
		local theBatFile = createFile theBatFilename 
		format "% \"%\"\n" thePath theFileName to:theBatFile
		if (execute (getIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "KSRPreferences" "PauseAfterExecutingPython")) != false do 
			format "@pause\n" to:theBatFile
		close theBatFile 
		if (execute (getIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "KSRPreferences" "RunPythonFile")) != false do 
		(
			FranticParticles.LogProgress (">Attempting to Launch Krakatoa SR Rendering using ["+ theBatFilename +"]" ) 
			shellLaunch theBatFilename ""
		)
	)
	
	if (execute (getIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "KSRPreferences" "OpenPythonForEditing")) != false do 	
	(
		local thePath = getIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "KSRPreferences" "PathToPythonEditor"
		if not MatchPattern thePath pattern:"*.exe" do thePath = "notepad.exe"
		FranticParticles.LogProgress (">Attempting to open Python File for Editing using ["+ thePath +"]" ) 
		shellLaunch thePath theFileName 
	)
	FranticParticles.LogProgress (">FINISHED Exporting Scene As Krakatoa SR Python File in "+ ((timestamp()-sttotal)/1000.0) as string + " seconds." ) 
	FranticParticles.LogProgress ("-----" +localtime + "--------------------------")
		
)--end Python export fn
	
) -- end FranticParticleRenderMXSStruct

FranticParticleRenderMXS = FranticParticleRenderMXSStruct()

-- When the renderer changes, we should close the UI, because all its values will become invalid.
callbacks.removeScripts id:#KrakatoaParticles


--callbacks.addScript #preRendererChange "FranticParticleRenderMXS.PreChangeRendererInstance=renderers.current" id:#KrakatoaParticles
callbacks.addScript #postRendererChange "FranticParticleRenderMXS.postRendererChanged()" id:#KrakatoaParticles
callbacks.addScript #systemPostReset "(FranticParticleRenderMXS.closerRolloutFloaters debugMessage:\"Received #SystemPostReset Notification.\"); try(FranticParticles.InvalidateParticleCache())catch()" id:#KrakatoaParticles
callbacks.addScript #systemPostNew "(FranticParticleRenderMXS.closerRolloutFloaters debugMessage:\"Received #SystemPostNew Notification.\"); try(FranticParticles.InvalidateParticleCache())catch()" id:#KrakatoaParticles
callbacks.addScript #filePostOpen "FranticParticleRenderMXS.closerRolloutFloaters debugMessage:\"Received #SystemPreOpen Notification.\"" id:#KrakatoaParticles

callbacks.addScript #filePostOpen "if Krakatoa_GUI_Floater==undefined and classof renderers.current == Krakatoa and not (IsNetServer()) do (FranticParticleRenderMXS.OpenGUI initOnly:true)" id:#KrakatoaParticles

FranticParticles.LogDebug ">Unregistering Krakatoa Render History Callbacks..."
callbacks.removeScripts id:#KrakatoaRenderHistory
FranticParticles.LogDebug ">Registering Krakatoa Render History Callbacks..."
callbacks.addScript #preRenderFrame "try(FranticParticleRenderMXS.framePreRender( callbacks.notificationParam() )) catch()" id:#KrakatoaRenderHistory
callbacks.addScript #postRender "try(FranticParticleRenderMXS.framePostRender()) catch(); try(FranticParticleRenderMXS.saveRenderHistory()) catch()" id:#KrakatoaRenderHistory	

callbacks.removeScripts id:#KrakatoaNSSWatcher
callbacks.addScript #filePostMerge "try(FranticParticleRenderMXS.fixNamedSelectionSets())catch()" id:#KrakatoaNSSWatcher
callbacks.addScript #filePostOpen "try(FranticParticleRenderMXS.fixNamedSelectionSets())catch()" id:#KrakatoaNSSWatcher

try(FranticParticles.PopupLogWindowOnMessage = execute (getIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "System" "PopupLogWindowOnMessage" ))catch()

macroScript KrakatoaGUI category:"Krakatoa" tooltip:"Toggle Krakatoa UI / Assign Krakatoa" buttontext:"Krakatoa GUI" icon:#("Krakatoa",1)
(
	global KrakatoaGuiOpen
	if KrakatoaGuiOpen== undefined do KrakatoaGuiOpen= true
	on isChecked return try(Krakatoa_Gui_floater.open And KrakatoaGuiOpen)catch(false)
	on isEnabled return try(FranticParticles.Version != undefined)catch(false)
	on execute do
	(
		if try(Krakatoa_Gui_floater.open)catch(false) then
			try(closeRolloutFloater Krakatoa_Gui_floater)catch()
		else
		(
			KrakatoaGUIOpeningManually = true
			try(FranticParticleRenderMXS.OpenGUI() )catch(messagebox ("Failed To Launch Krakatoa GUI:\n" + getCurrentException()) title:"Krakatoa Error")
			KrakatoaGUIOpeningManually  = false
		)
	)
)

macroScript KrakatoaGUIFocus category:"Krakatoa" tooltip:"Bring Krakatoa to Front If Assigned / Switch to Krakatoa if Not Assigned" buttontext:"Krakatoa GUI" icon:#("Krakatoa",20)
(
	on isEnabled return FranticParticles != undefined
	on execute do
	(
		if try(Krakatoa_Gui_floater == undefined or Krakatoa_Gui_floater.open == false)catch(true) then
		(
			macros.run "Krakatoa" "KrakatoaGUI"
		)
		else
		(
			try(if Krakatoa_Gui_floater.placement == #minimized do Krakatoa_Gui_floater.placement = #normal)catch()
			try(if Krakatoa_Gui_floater_2.placement == #minimized do Krakatoa_Gui_floater_2.placement = #normal)catch()
				
			local allRollouts = #(
				Krakatoa_GUI_Presets,
				Krakatoa_GUI_MatteObjects, 
				Krakatoa_GUI_ShaderDynamic, 
				Krakatoa_GUI_RenderGlobalValues,
				Krakatoa_GUI_AmbientPME, 
				Krakatoa_GUI_Main,
				Krakatoa_GUI_SaveParticles,
				Krakatoa_GUI_Partition, 
				Krakatoa_GUI_Channels
			)		
			for i in allRollouts do 
			(
				try(if i.placement == #minimized do i.placement = #normal)catch()
				try (setFocus i)catch()
			)
			try(setFocus Krakatoa_Gui_floater_2.rollouts[1])catch()
			try(setFocus Krakatoa_Gui_floater.rollouts[1])catch()
			try(setFocus Krakatoa_SceneExplorersFloater.rollouts[1])catch()
		)
	)
)

macroScript KrakatoaPreferences category:"Krakatoa" tooltip:"Preferences - Customize the Behavior of the Krakatoa UI and Tools" buttontext:"Krakatoa Preferences" icon:#("Krakatoa",22)
(
	on isEnabled return renderers.current.classid as string == "#(-1204370534, -399920359)" or renderers.current.classid as string == "#(3090596762L, 3895046937L)"
	on execute do
	(
		try(closeRolloutFloater Krakatoa_Preferences_Floater)catch()
		local thePos = execute (getIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "RolloutDialogPositions" Krakatoa_GUI_Preferences.title )
		if thePos != OK then
		(
			if thePos.y > sysinfo.desktopsize.y - 800 do thePos.y = sysinfo.desktopsize.y - 800 
			Krakatoa_Preferences_Floater = newRolloutFloater "Krakatoa Preferences" 470 800 thePos.x thePos.y
		)
		else		
			Krakatoa_Preferences_Floater = newRolloutFloater "Krakatoa Preferences" 470 800
			--createDialog Krakatoa_GUI_Preferences
		addRollout Krakatoa_GUI_Preferences_System Krakatoa_Preferences_Floater rolledup:true
		addRollout Krakatoa_GUI_Preferences Krakatoa_Preferences_Floater rolledup:true
		--addRollout Krakatoa_GUI_KSRExporter_Preferences Krakatoa_Preferences_Floater rolledup:true
		addRollout Krakatoa_GUI_Preferences_Colors Krakatoa_Preferences_Floater rolledup:true
	)
)

macroScript KrakatoaNotes category:"Krakatoa" tooltip:"Open the Krakatoa Scene Notes dialog..." buttontext:"Krakatoa Notes" icon:#("Krakatoa",23)
(
	on isEnabled return renderers.current.classid as string == "#(-1204370534, -399920359)" or renderers.current.classid as string == "#(3090596762L, 3895046937L)"
	on execute do
	(
		try(destroyDialog Krakatoa_GUI_Notes)catch()
		local thePos = execute (getIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "RolloutDialogPositions" Krakatoa_GUI_Notes.title )
		if thePos != OK then
		(
			if thePos.y > sysinfo.desktopsize.y - 800 do thePos.y = sysinfo.desktopsize.y - 800 
			createDialog Krakatoa_GUI_Notes pos:thePos
		)
		else		
			createDialog Krakatoa_GUI_Notes
	)
)

macroScript AboutKrakatoa category:"Krakatoa" tooltip:"About Krakatoa..." buttontext:"About Krakatoa" icon:#("Krakatoa",24)
(
	on isEnabled return isKindOf FranticParticles Interface --renderers.current.classid as string == "#(-1204370534, -399920359)" or renderers.current.classid as string == "#(3090596762L, 3895046937L)"
	on execute do
	(
		try(destroyDialog Krakatoa_GUI_About)catch()
		local thePos = execute (getIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "RolloutDialogPositions" Krakatoa_GUI_About.title )
		if thePos != OK then
		(
			if thePos.y > sysinfo.desktopsize.y - 800 do thePos.y = sysinfo.desktopsize.y - 800 
			createDialog Krakatoa_GUI_About pos:thePos
		)
		else		
			createDialog Krakatoa_GUI_About
	)
)

macroScript RemoveKrakatoa category:"Krakatoa" tooltip:"Switch Back From Krakatoa To Previous Renderer" buttontext:"Krakatoa GUI" icon:#("Krakatoa",6)
(
	on isEnabled return renderers.current.classid as string == "#(-1204370534, -399920359)" or renderers.current.classid as string == "#(3090596762L, 3895046937L)"
	on execute do
	(
		
		local theMaxVersion = (MaxVersion())[1]/1000
		local canUseRPSFile = not FranticParticleRenderMXS.GetCompressOnSaveState() or theMaxVersion < 12 or theMaxVersion > 13 or not is64bitApplication()
		
		if canUseRPSFile then
		(
			local lastRendererPresetFilename  = ((getdir #renderpresets) + "\\backup_pre_krakatoa_assignment.rps")
			if doesFileExist lastRendererPresetFilename then
			(
				local theLastRendererName = renderpresets.MapIndexToCategory  lastRendererPresetFilename  32
				local theQuery = querybox ("Are you sure you want to REMOVE Krakatoa\nfrom the Production Renderer slot\nand switch to the last known settings of\n["+theLastRendererName+"]?\n\nA backup of your current Krakatoa settings will be saved as 'backup_last_krakatoa_settings.rps'") title:"Krakatoa: Switch To Previous Renderer"
				if theQuery then
				(
					local lastRenderDialogState =renderSceneDialog.isOpen()
					renderSceneDialog.close()
					setIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini" ) "SwitchRenderer" "LastKrakatoaOutputPath" rendOutputFilename
					try(destroyDialog Krakatoa_GUI_Notes)catch()	
					try(destroyDialog Krakatoa_GUI_About)catch()	
					try(closeRolloutFloater Krakatoa_SceneExplorersFloater)catch()				
					try(destroyDialog Krakatoa_GUI_Preferences)catch()
					RenderPresets.Save 0 ((getdir #renderpresets) + "\\backup_last_krakatoa_settings.rps") #{1,4..64} 
					
					local oldColorCorrectionMode = try(IDisplayGamma.colorCorrectionMode)catch(undefined)
					local oldLUTFileName = try(IDisplayGamma.LUTFileName)catch(undefined)
					local oldgamma  = try(IDisplayGamma.gamma )catch(undefined)
					local oldcolorCorrectionPrefMode = try(IDisplayGamma.colorCorrectionPrefMode )catch(undefined)
					local oldcoloraffectColorPickers  = try(IDisplayGamma.affectColorPickers )catch(undefined)
					local oldaffectMEdit = try(IDisplayGamma.affectMEdit  )catch(undefined)
					
					SetQuietMode true
					renderpresets.LoadAll 0 lastRendererPresetFilename 
					SetQuietMode false
					
					try(if oldColorCorrectionMode != undefined do IDisplayGamma.colorCorrectionMode = oldColorCorrectionMode)catch()
					try(if oldLUTFileName != undefined do IDisplayGamma.LUTFileName = oldLUTFileName)catch()
					try(if oldgamma != undefined do IDisplayGamma.gamma = oldgamma)catch()
					try(if oldcolorCorrectionPrefMode != undefined do IDisplayGamma.colorCorrectionPrefMode = oldcolorCorrectionPrefMode)catch()
					try(if oldcoloraffectColorPickers != undefined do IDisplayGamma.affectColorPickers = oldcoloraffectColorPickers)catch()
					try(if oldaffectMEdit != undefined do IDisplayGamma.affectMEdit = oldaffectMEdit)catch()
					
					local pref = execute (getIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini" ) "Preferences" "StoreRenderOutputPathOnRenderSwitchBehavior")
					if pref == OK do pref = 1
					if pref < 3 then 
					(
						local lastPath = getIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini" ) "SwitchRenderer" "LastNonKrakatoaOutputPath" 
						if lastPath != "" do 
						if pref == 2 or (querybox ("Previous Non-Krakatoa Output Save Path Found:\n\n"+lastPath+"\n\nDo you want to restore it?") title:"Restore Save Path") do
							rendOutputFilename = lastPath
					)
					if lastRenderDialogState do renderSceneDialog.Open()
					FranticParticleRenderMXS.displayRendererSwitchPrompt()
				)	
			)	
			else
			(
				local theQuery = querybox "No previously saved Render Preset found.\n\nSwitch to Default Scanline Renderer?" title:"Krakatoa: Switch To Previous Renderer"
				if theQuery do 
				(
					try(destroyDialog Krakatoa_GUI_Notes)catch()	
					try(destroyDialog Krakatoa_GUI_About)catch()	
					try(closeRolloutFloater Krakatoa_SceneExplorersFloater)catch()				
					try(destroyDialog Krakatoa_GUI_Preferences)catch()
					renderers.current = Default_Scanline_Renderer()	
					FranticParticleRenderMXS.displayRendererSwitchPrompt()
				)
			)	
		)
		else
		(
			if KrakatoaLastRendererStorage[2] == undefined then
			(
				local theQuery = querybox "No previously Renderer could be found in the memory storage.\n\nSwitch to Default Scanline Renderer?" title:"Krakatoa: Switch To Default Scanline Renderer"
				if theQuery do 
				(
					try(destroyDialog Krakatoa_GUI_Notes)catch()	
					try(destroyDialog Krakatoa_GUI_About)catch()	
					try(closeRolloutFloater Krakatoa_SceneExplorersFloater)catch()				
					try(destroyDialog Krakatoa_GUI_Preferences)catch()
					renderers.current = Default_Scanline_Renderer()	
					local theManager = maxOps.GetCurRenderElementMgr()
					theManager.RemoveAllRenderElements()			
					theManager.SetElementsActive true
					theManager.SetDisplayElements true
					FranticParticleRenderMXS.displayRendererSwitchPrompt()
				)
			)
			else
			(
				local theQuery = querybox ("This will REMOVE Krakatoa from the Production Renderer slot\nand switch to the last known settings of ["+(classof KrakatoaLastRendererStorage[2]) as string +"]\n\nA backup of your current Krakatoa settings will be stored in MEMORY\nfor the duration of the current session and can be easily restored using\nthe 'Open Krakatoa GUI' icon/menu item.") title:"Krakatoa: Switch To Previous Renderer From Memory Storage"
				if theQuery then
				(
					local lastRenderDialogState =renderSceneDialog.isOpen()
					renderSceneDialog.close()					
					
					KrakatoaLastRendererStorage[1] = renderers.current
					
					local theManager = maxOps.GetCurRenderElementMgr()
					KrakatoaLastRendererStorage[3] = #()
					KrakatoaLastRendererStorage[3][1] = theManager.GetElementsActive() 
					KrakatoaLastRendererStorage[3][2] = theManager.GetDisplayElements()
					KrakatoaLastRendererStorage[3][3] = theManager.NumRenderElements() 
					for i = 1 to theManager.NumRenderElements() do
					(
						try(KrakatoaLastRendererStorage[3][i+3] = theManager.GetRenderElement (i-1) )catch()
					)						
					
					
					renderers.current = KrakatoaLastRendererStorage[2]

					local theManager = maxOps.GetCurRenderElementMgr()
					theManager.RemoveAllRenderElements()

					if KrakatoaLastRendererStorage[4] != undefined do
					(
						theManager.SetElementsActive KrakatoaLastRendererStorage[4][1]
						theManager.SetDisplayElements KrakatoaLastRendererStorage[4][2] 
						local theCount = KrakatoaLastRendererStorage[4][3]
						for i = 1 to theCount do
						(
							theManager.AddRenderElement KrakatoaLastRendererStorage[4][i+3]
						)
					)					
					
					local pref = execute (getIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini" ) "Preferences" "StoreRenderOutputPathOnRenderSwitchBehavior")
					if pref == OK do pref = 1
					if pref < 3 then 
					(
						local lastPath = getIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini" ) "SwitchRenderer" "LastNonKrakatoaOutputPath" 
						if lastPath != "" do 
						if pref == 2 or (querybox ("Previous Non-Krakatoa Output Save Path Found:\n\n"+lastPath+"\n\nDo you want to restore it?") title:"Restore Save Path") do
							rendOutputFilename = lastPath
					)
					if lastRenderDialogState do renderSceneDialog.Open()
					FranticParticleRenderMXS.displayRendererSwitchPrompt()
				)
			)		
		)
		
	)	
	--else	messagebox ("The current renderer is already set to  ["+ (classof renderers.current) as string + "].") title:"Krakatoa: Switch To Previous Renderer"
)



macroScript KrakatoaLog category:"Krakatoa" tooltip:"Toggle Krakatoa Log Window On/Off" buttontext:"Krakatoa Log Window" icon:#("Krakatoa",2)
(
	on isChecked return try(FranticParticles.LogWindowVisible)catch(false)
	on isEnabled return try(FranticParticles.Version != undefined)catch(false)
	on execute do
	(
		try(FranticParticles.LogWindowVisible = not FranticParticles.LogWindowVisible)catch()
	)
)

macroScript KrakatoaAutoLog category:"Krakatoa" tooltip:"Auto-Open Log Window On Warnings On/Off" buttontext:"Krakatoa Auto-Open Log" icon:#("Krakatoa",3)
(
	on isChecked return try(FranticParticles.PopupLogWindowOnMessage )catch(false)
	on isEnabled return try(FranticParticles.Version != undefined)catch(false)
	on execute do
	(
		try
		(
			FranticParticles.PopupLogWindowOnMessage = not FranticParticles.PopupLogWindowOnMessage 
			setIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "System" "PopupLogWindowOnMessage" (FranticParticles.PopupLogWindowOnMessage as string)
			Krakatoa_GUI_Preferences_System.refresh_GUI()
		)catch()
	)
)

macroScript ToggleMeditLock category:"Krakatoa" tooltip:"Toggle Material Editor Renderer Lock To Production Renderer" icon:#("Krakatoa",13)
(
	on isChecked return renderers.medit_locked
	on execute do renderers.medit_locked = not renderers.medit_locked
)

macroScript PRTLoader category:"Krakatoa" tooltip:"PRT Loader - hold SHIFT to create at Origin" icon:#("Krakatoa",7)
(
	on isChecked return (try (mcrUtils.IsCreating KrakatoaPRTLoader)catch(false))
	on isEnabled return KrakatoaPRTLoader != undefined		
	on execute do 
	(
		if keyboard.shiftPressed then
		(
			local newLoader = KrakatoaPRTLoader()
			if isValidNode newLoader do
			(
				select newLoader 
				local thePref = getIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "Preferences" "CreateLoadersBehavior"
				if thePref != "3" do try(newLoader.params.btn_addFiles.pressed())catch()
			)				
			max modify mode
		)	
		else
			StartObjectCreation KrakatoaPRTLoader
	)	
)


macroScript PRTVolume category:"Krakatoa" tooltip:"PRT Volume - Select Source(s) and Click to Create, or Hold SHIFT to Create Manually in the Viewport" icon:#("Krakatoa",8)
(
	on isChecked return  (try(mcrUtils.IsCreating PRT_Volume)catch(false)) 
	on isEnabled return PRT_Volume != undefined	
	on execute do 
	(
		--local legacyParticles = #(PArray, PCloud, SuperSpray, Blizzard, Snow, Spray)
		local theObjects = (for o in selection where (findItem shape.classes (classof o) > 0) OR  (findItem GeometryClass.classes (classof o) > 0 AND findItem #(TargetObject, KrakatoaPrtLoader, ParticleGroup, PF_Source) (classof o.baseobject) == 0 AND not (matchPattern ((classof o) as string) pattern:"PRT_*")) collect o) --AND findItem legacyParticles (classof o) == 0 
		if keyboard.shiftPressed or theObjects.count == 0 then
		(
			StartObjectCreation PRT_Volume
		)
		else
		(
			local toSelect = for o in theObjects collect
			(
				local theBBox = o.max-o.min
				local theMaxSize = amax #(theBBox.x, theBBox.y, theBBox.z)
				local newVolume = PRT_Volume()
				local theSpacingFactor = execute (getIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "Preferences" "PRTVolumeSpacingFactor")
				if theSpacingFactor == OK do theSpacingFactor = 50.0
				newVolume.ViewportVoxelLength = theMaxSize/theSpacingFactor
				newVolume.iconsize = amax #(theBBox.x, theBBox.y, 10.0)
				newVolume.transform = o.transform
				newVolume.TargetNode = o
				newVolume.wirecolor = o.wirecolor
				newVolume.material = o.material
				newVolume.name = uniquename ("PRTVolume_" + o.name + "_")
				local thePref = getIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "Preferences" "CreatePRTVolumeBehavior"
				case thePref of
				(
					default: () --do nothing, option 5
					"1" : (o.renderable = false)
					"2" : (o.boxMode = true)
					"3" : (o.boxMode = true; o.renderable = false)
					"4" : (hide o)
				)
				newVolume
			)	
			select toSelect
			max modify mode	
		)	
	)	
)

macroScript PRTSurface category:"Krakatoa" tooltip:"PRT Surface - Select Source(s) and Click to Create one Surface from all, or Hold SHIFT to a Surface per selected object. Deselect all and click to create manually in the viewport." icon:#("Krakatoa",28)
(
	on isChecked return  (try(mcrUtils.IsCreating PRT_Surface)catch(false)) 
	on isEnabled return PRT_Surface != undefined	
	on execute do 
	(
		local theObjects = (for o in selection where (findItem shape.classes (classof o) > 0) OR  (findItem GeometryClass.classes (classof o) > 0 AND findItem #(TargetObject, KrakatoaPrtLoader, ParticleGroup, PF_Source, Thinking, Stoke) (classof o.baseobject) == 0 AND not (matchPattern ((classof o) as string) pattern:"PRT_*")) collect o) 
		if theObjects.count == 0 then
		(
			StartObjectCreation PRT_Surface
		)
		else
		(
			if keyboard.shiftPressed then
			(
				local toSelect = for o in theObjects collect
				(
					local newObject = PRT_Surface()
					newObject.SourceNodes = #(o)
					newObject.transform = o.transform
					newObject.wirecolor = o.wirecolor
					newObject.material = o.material
					newObject.name = uniquename ("PRTSurface_" + o.name + "_")
					local thePref = getIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "Preferences" "CreatePRTVolumeBehavior"
					case thePref of
					(
						default: () --do nothing, option 5
						"1" : (o.renderable = false)
						"2" : (o.boxMode = true)
						"3" : (o.boxMode = true; o.renderable = false)
						"4" : (hide o)
					)
					newObject
				)	
				select toSelect	
				max modify mode					
			)
			else
			(
				local newObject = PRT_Surface()
				if theObjects.count > 1 then
				(
					newObject.name = uniquename ("PRTSurface_Multi"+theObjects.count as string +"_")
				)
				else
				(
					newObject.name = uniquename ("PRTSurface_"+theObjects[1].name +"_")
					newObject.transform = theObjects[1].transform
				)
				newObject.SourceNodes = theObjects				
				local thePref = getIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "Preferences" "CreatePRTVolumeBehavior"
				case thePref of
				(
					default: () --do nothing, option 5
					"1" : (theObjects.renderable = false)
					"2" : (theObjects.boxMode = true)
					"3" : (theObjects.boxMode = true; theObjects.renderable = false)
					"4" : (hide theObjects)
				)				
				select newObject
				max modify mode	
			)
		)	
	)	
)


macroScript PRTFumeFX category:"Krakatoa" tooltip:"PRT FumeFX - Select Source(s) and Click to Create, or Hold SHIFT to Create Manually in the Viewport" icon:#("Krakatoa",16)
(
	on isChecked return (try(mcrUtils.IsCreating PRT_FumeFX)catch(false))
	on isEnabled return PRT_FumeFX != undefined	
	on execute do 
	(
		local theObjects = (for o in selection where (classof o) == FumeFX collect o)
		if keyboard.shiftPressed or theObjects.count == 0 then
		(
			StartObjectCreation PRT_FumeFX
		)
		else
		(
			local toSelect = for o in theObjects collect
			(
				local newFume = PRT_FumeFX()
				newFume.iconsize = amax #(o.width, o.length, 10.0 ) 
				newFume.transform = o.transform
				newFume.TargetNode = o
				newFume.wirecolor = o.wirecolor
				--newFume.material = o.material --BAD, BAD Idea!
				newFume.name = uniquename ("PRTFume_" + o.name + "_")
				newFume
			)	
			select toSelect
			max modify mode	
		)	
	)	
)

macroScript PRTMaker category:"Krakatoa" tooltip:"PRT Maker - Click to Create manually, or Hold SHIFT and Click to Create at World Origin" icon:#("Krakatoa",26)
(
	on isChecked return (try(mcrUtils.IsCreating PRT_Maker)catch(false))
	on isEnabled return PRT_Maker != undefined	
	on execute do 
	(
		if not keyboard.shiftPressed then
		(
			StartObjectCreation PRT_Maker
		)
		else
		(
			select (PRT_Maker())
			max modify mode
		)	
	)	
)

macroScript PRTSource category:"Krakatoa" tooltip:"PRT Source - Click to Create manually, or Hold SHIFT and Click to Create at World Origin" icon:#("Krakatoa",27)
(
	on isChecked return (try(mcrUtils.IsCreating PRT_Source)catch(false))
	on isEnabled return PRT_Source != undefined	
	on execute do  (
		local theObjects = (for o in selection where (findItem shape.classes (classof o) > 0) OR  (findItem GeometryClass.classes (classof o) > 0 AND findItem #(TargetObject, ParticleGroup) (classof o.baseobject) == 0) OR (matchPattern ((classof o) as string) pattern:"PRT_*") collect o) --AND findItem legacyParticles (classof o) == 0 
		if keyboard.shiftPressed or theObjects.count == 0 then
		(
			StartObjectCreation PRT_Source
		)
		else
		(
			max modify mode
			local toSelect = for o in theObjects collect
			(
				local theBBox = o.max-o.min
				local theMaxSize = amax #(theBBox.x, theBBox.y, theBBox.z)
				local newSource = PRT_Source()
				newSource.iconsize = amax #(theBBox.x, theBBox.y, 10.0)
				newSource.transform = o.transform
				newSource.TargetNode = o
				newSource.wirecolor = o.wirecolor
				newSource.material = o.material
				newSource.name = uniquename ("PRTSource_" + o.name + "_")
				local thePref = getIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "Preferences" "CreatePRTSourceBehavior" 
				if classof o == PF_Source do thePref = 0
				case thePref of
				(
					default: () --do nothing, option 5
					"1" : (o.renderable = false)
					"2" : (o.boxMode = true)
					"3" : (o.boxMode = true; o.renderable = false)
					"4" : (hide o)
				)
				newSource
			)	
			select toSelect
		)			
	)	
)


macroScript PRTHair category:"Krakatoa" tooltip:"PRT Hair - Select Source(s) and Click to Create, or Hold SHIFT to Create Manually in the Viewport" icon:#("Krakatoa",12)
(
	on isChecked return try(mcrUtils.IsCreating PRT_Hair)catch(false)
	on isEnabled return PRT_Hair != undefined	
	on execute do 
	(
		local theObjects = (for o in selection where findItem Shape.classes (classof o) > 0  collect o) 
		if keyboard.shiftPressed then
		(
			StartObjectCreation PRT_Hair
		)
		else
		(
			if theObjects.count == 0 then
			(
				select (PRT_Hair())
			)
			else
			(
				local toSelect = for o in theObjects collect
				(
					local newObject = PRT_Hair()
					newObject.SourceType = 0
					newObject.TargetNode = o
					newObject.transform = o.transform
					newObject.name = uniquename ("PRTHair_" + o.name + "_")
					newObject
				)	
				select toSelect
			)	
			max modify mode	
		)
	)	
)

/*
macroScript PRTHairCamUpdate category:"Krakatoa" tooltip:"PRT Hair Camera Update" icon:#("Krakatoa",15)
(
	on isEnabled return isValidNode (viewport.getCamera()) 
	on execute do
	(
		theHairs = for o in objects where classof o == PRT_Hair collect o
		theHairs.CameraNode = viewport.getCamera()
		theHairs.UseViewAdaptive = true
	)
)
*/

macroScript ChannelModifier category:"Krakatoa" tooltip:"Krakatoa Magma Modifier - hold SHIFT to Instanciate among Selection" icon:#("Krakatoa",9)
(
	on isEnabled return (selection.count > 0 and MagmaModifier != undefined)
	on execute do 
	(
		local theObjects = (for o in selection where findItem #(KrakatoaPrtLoader, Stoke ) (classof o.baseobject) > 0 or (MatchPattern ((classof o.baseobject) as string) pattern:"PRT_*" ) or classof o.baseobject == KrakatoaMXGlobalDataHolder collect o)
		if keyboard.shiftPressed then
		(
			try
			(
				local newModifier= MagmaModifier()
				newModifier.name = "Magma"
				for o in theObjects do addModifier o newModifier
				max modify mode
				::MagmaFlowEditor_Functions.OpenMagmaFlowEditor newModifier.MagmaHolder offscreen:false 
				select selection
			)catch()
		)	
		else
		(
			max modify mode				
			if theObjects.count == 1 and modPanel.getCurrentObject() != undefined then
			(
				local newModifier = MagmaModifier()
				newModifier.name = "Magma"
				modPanel.addModToSelection newModifier
				::MagmaFlowEditor_Functions.OpenMagmaFlowEditor newModifier.MagmaHolder offscreen:false 
			)
			else
			(
				try
				(
					for o in theObjects do 
					(
						local newModifier = MagmaModifier()
						newModifier.name = "Magma"
						addModifier o newModifier
					)
				)catch()
			)
		)
	)	
)

macroScript SpaceMagmaModifier category:"Krakatoa" tooltip:"Krakatoa Magma WSM - hold SHIFT to Instanciate among Selection" icon:#("Krakatoa",30)
(
	on isEnabled return (selection.count > 0 and SpaceMagmaModifier != undefined)
	on execute do 
	(
		local theObjects = (for o in selection where findItem #(KrakatoaPrtLoader, Stoke ) (classof o.baseobject) > 0 or (MatchPattern ((classof o.baseobject) as string) pattern:"PRT_*" ) or classof o.baseobject == KrakatoaMXGlobalDataHolder collect o)
		if keyboard.shiftPressed then
		(
			try
			(
				local newModifier = SpaceMagmaModifier()
				newModifier.name = "Magma"
				for o in theObjects do addModifier o newModifier
				max modify mode
				::MagmaFlowEditor_Functions.OpenMagmaFlowEditor newModifier.MagmaHolder offscreen:false 
				select selection
			)catch()
		)	
		else
		(
			max modify mode	
			if theObjects.count == 1 and modPanel.getCurrentObject() != undefined then
			(
				local newModifier = SpaceMagmaModifier()
				newModifier.name = "Magma"
				modPanel.addModToSelection newModifier
				::MagmaFlowEditor_Functions.OpenMagmaFlowEditor newModifier.MagmaHolder offscreen:false 
			)
			else
			(
				try
				(
					for o in theObjects do 
					(
						local newModifier = SpaceMagmaModifier()
						newModifier.name = "Magma"
						addModifier o newModifier
					)
				)catch()
			)
			max modify mode
		)
	)	
)

macroScript AddMagmaPreset category:"Krakatoa" tooltip:"Add a Magma Modifier Preset to the Selection. Hold SHIFT to add a unique copy to multiple selected objects." icon:#("Krakatoa",29)
(
	on isEnabled return (selection.count > 0 and MagmaModifier != undefined)
	on execute do
	(
		::MagmaFlowEditor_Functions.createPresetsRCMenu mode:#macro
	)
)

macroScript DeleteModifier category:"Krakatoa" tooltip:"Krakatoa Delete Modifier - hold SHIFT to Instanciate among Selection" icon:#("Krakatoa",11)
(
	on isEnabled return (selection.count > 0 and KrakatoaDeleteModifier != undefined)
	on execute do 
	(
		local theObjects = (for o in selection where findItem #(KrakatoaPrtLoader, Stoke ) (classof o.baseobject) > 0 or (MatchPattern ((classof o.baseobject) as string) pattern:"PRT_*" ) collect o)
		if keyboard.shiftPressed then
		(
			try
			(
				local newModifier = KrakatoaDeleteModifier()
				for o in theObjects do addModifier o newModifier
				max modify mode
			)catch()
		)	
		else
		(
			try(for o in theObjects do addModifier o (KrakatoaDeleteModifier()))catch()
			max modify mode
		)
	)	
)

macroScript SpaceDeleteModifier category:"Krakatoa" tooltip:"Krakatoa Delete WSM - hold SHIFT to Instanciate among Selection" icon:#("Krakatoa",34)
(
	on isEnabled return (selection.count > 0 and Krakatoa_Delete != undefined)
	on execute do 
	(
		local theObjects = (for o in selection where findItem #(KrakatoaPrtLoader, Stoke ) (classof o.baseobject) > 0 or (MatchPattern ((classof o.baseobject) as string) pattern:"PRT_*" ) collect o)
		if keyboard.shiftPressed then
		(
			try
			(
				local newModifier = Krakatoa_Delete()
				for o in theObjects do addModifier o newModifier
				max modify mode
			)catch()
		)	
		else
		(
			try(for o in theObjects do addModifier o (Krakatoa_Delete()))catch()
			max modify mode
		)
	)	
)
macroScript PRTClonerModifier category:"Krakatoa" tooltip:"Krakatoa PRT Cloner Modifier - hold SHIFT to Instanciate among Selection" icon:#("Krakatoa",35)
(
	on isEnabled return (selection.count > 0 and Krakatoa_PRTCloner != undefined)
	on execute do 
	(
		local theObjects = (for o in selection where findItem #(KrakatoaPrtLoader, Stoke ) (classof o.baseobject) > 0 or (MatchPattern ((classof o.baseobject) as string) pattern:"PRT_*" ) collect o)
		if keyboard.shiftPressed then
		(
			try
			(
				local newModifier = Krakatoa_PRTCloner()
				for o in theObjects do addModifier o newModifier
				max modify mode
			)catch()
		)	
		else
		(
			try(for o in theObjects do addModifier o (Krakatoa_PRTCloner()))catch()
			max modify mode
		)
	)	
)
macroScript SpacePRTClonerModifier category:"Krakatoa" tooltip:"Krakatoa PRT Cloner WSM - hold SHIFT to Instanciate among Selection" icon:#("Krakatoa",33)
(
	on isEnabled return (selection.count > 0 and Krakatoa_PRTClonerSpacewarpModifier != undefined)
	on execute do 
	(
		local theObjects = (for o in selection where findItem #(KrakatoaPrtLoader, Stoke ) (classof o.baseobject) > 0 or (MatchPattern ((classof o.baseobject) as string) pattern:"PRT_*" ) collect o)
		if keyboard.shiftPressed then
		(
			try
			(
				local newModifier = Krakatoa_PRTClonerSpacewarpModifier()
				for o in theObjects do addModifier o newModifier
				max modify mode
			)catch()
		)	
		else
		(
			try(for o in theObjects do addModifier o (Krakatoa_PRTClonerSpacewarpModifier()))catch()
			max modify mode
		)
	)	
)
macroScript KrakatoaSkinWrap category:"Krakatoa" tooltip:"Krakatoa Skin Wrap WSM - hold SHIFT to Instanciate among Selection" icon:#("Krakatoa",32)
(
	on isEnabled return (selection.count > 0 and Krakatoa_Skin_Wrap != undefined)
	on execute do 
	(
		local theObjects = (for o in selection where findItem #(KrakatoaPrtLoader, Stoke ) (classof o.baseobject) > 0 or (MatchPattern ((classof o.baseobject) as string) pattern:"PRT_*" ) collect o)
		if keyboard.shiftPressed then
		(
			try
			(
				local newModifier = Krakatoa_Skin_Wrap()
				for o in theObjects do addModifier o newModifier
				max modify mode
			)catch()
		)	
		else
		(
			try(for o in theObjects do addModifier o (Krakatoa_Skin_Wrap()))catch()
			max modify mode
		)
	)	
)


macroScript CameraModifier category:"Krakatoa" tooltip:"Krakatoa Camera Modifier - hold SHIFT to Instanciate among Selection" icon:#("Krakatoa",15)
(
	on isEnabled return ( ((for o in selection where findItem camera.classes (classof o) > 0 collect o).count > 0) AND KrakatoaCameraModifier != undefined  )
	on execute do 
	(
		local theObjects = (for o in selection where findItem camera.classes (classof o) > 0 collect o)
		if keyboard.shiftPressed then
		(
			try
			(
				local newModifier = KrakatoaCameraModifier()
				for o in theObjects do addModifier o newModifier
				max modify mode
			)catch()
		)	
		else
		(
			try(for o in theObjects do addModifier o (KrakatoaCameraModifier()))catch()
			max modify mode
		)
	)	
)

macroScript SaveModStack category:"Krakatoa" icon:#("Krakatoa",17)
(
fn saveMagmaFlowPackage theSource theFilename =
(
	theOutputFilename = "c:\\temp\\_MagmaFlow_Package.max"
	theOldName = theSource.name
	theSource.name = "MagmaFlow_PackageObject"
	saveNodes theSource theFilename quiet:true
	theSource.name = theOldName
)
on isEnabled return selection.count == 1
on execute do 
(
	local theStartPath = "*"
	if Krakatoa_PresetsDirectory != undefined do theStartPath = Krakatoa_PresetsDirectory  + "\\modstacks\\"+$.name+".ModStack" 
	local theFile = getSaveFileName caption:"Select a Modifier Stack Package to Save" filename:theStartPath types:"3ds Max Modifier Stack Package (*.ModStack)|*.ModStack"
	if theFile != undefined do 
		saveMagmaFlowPackage $ theFile
)
)

macroScript LoadModStack category:"Krakatoa" icon:#("Krakatoa",18)
(
fn loadMagmaFlowPackage theTarget theFilename =
(
	with undo "Paste Mod Package" on
	(
		mergeMaxFile theFilename #noRedraw #mergeDups #useSceneMtlDups #neverReparent quiet:true
		theSource = getNodeByName "MagmaFlow_PackageObject"
		max modify mode
		for i = theSource.modifiers.count to 1 by -1 do
		(
			if validModifier theTarget theSource.modifiers[i] do 
			(
				select theTarget
				--print theSource.modifiers[i]
				addModifier theTarget (copy theSource.modifiers[i])
				theTarget.modifiers[1].name = theSource.modifiers[i].name
			)
		)
		delete theSource
	)
)
on isEnabled return selection.count > 0
on execute do 
(
	local theStartPath = "*"
	if Krakatoa_PresetsDirectory != undefined do theStartPath = Krakatoa_PresetsDirectory  + "\\modstacks\\*.ModStack" 
	local theFile = getOpenFileName caption:"Select a Modifier Stack Package to Load" filename:theStartPath types:"3ds Max Modifier Stack Package (*.ModStack)|*.ModStack"
	if theFile != undefined do 
		loadMagmaFlowPackage $ theFile
)
)

macroScript KrakatoaParticleDataViewer category:"Krakatoa" buttontext:"PRT Data Viewer" tooltip:"Krakatoa Particle Data Viewer" icon:#("Krakatoa",19)
(
	on isEnabled return FranticParticles != undefined
	on execute do
	(
		fileIn (FranticParticles.KrakatoaHome+"Scripts\\Krakatoa_ParticleDataViewer.ms")
	)
)

(
	struct PRTSourceCallbacksDef
	(
		fn on_PFEventListOptions_pressed prtSourceNode =
		(
			rcmenu PRTSource_PFEventListOptions_RCMenu
			(
				menuitem mnu_removeDeletedEvents "Remove Deleted Events"
				
				on mnu_removeDeletedEvents picked do
				(
					with undo "PRTSource Remove Deleted" on
					(
						local thePRTSourceBaseObject = modPanel.getCurrentObject()
						local newEventList = (for o in thePRTSourceBaseObject.pfEventList where o != undefined collect o)
						if newEventList.count != thePRTSourceBaseObject.pfEventList.count do
						(
							thePRTSourceBaseObject.pfEventList = #()
							thePRTSourceBaseObject.pfEventList = newEventList
						)
					)
				)
			)
			if modPanel.getCurrentObject() == undefined do return()
			popUpMenu PRTSource_PFEventListOptions_RCMenu pos:mouse.screenpos
		),

		fn on_TPGroupListOptions_pressed prtSourceNode =
		(
			rcmenu PRTSource_TPGroupListOptions_RCMenu
			(
				menuitem mnu_removeDeletedEvents "Remove Deleted Groups"

				on mnu_removeDeletedEvents picked do
				(
					with undo "PRTSource Remove Deleted" on
					(
						local thePRTSourceBaseObject = modPanel.getCurrentObject()
						local newGroupList = (for o in thePRTSourceBaseObject.tpGroupList where o != undefined collect o)
						if newGroupList.count != thePRTSourceBaseObject.tpGroupList.count do
						(
							thePRTSourceBaseObject.tpGroupList = #()
							thePRTSourceBaseObject.tpGroupList = newGroupList
						)
					)
				)
			)
			if modPanel.getCurrentObject() == undefined do return()
			popUpMenu PRTSource_TPGroupListOptions_RCMenu pos:mouse.screenpos
		)
	)
	global PRTSourceCallbacks = PRTSourceCallbacksDef()
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
	)	
)	

fn playbackgraph_deleteAnimation = 
(
	local theCtrl = try(selection[1].playbackGraphTime.controller)catch(undefined)
	if theCtrl != undefined do
		try(deleteKeys theCtrl #allKeys)catch()
)

global PRTFFX_KeyframeToolsRCMenu 
rcmenu PRTFFX_KeyframeToolsRCMenu
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
	)
	on mnu_playbackgraph_currentSegment_Accelerate picked do
	(
		playbackgraph_currentSegment #accel
	)
	on mnu_playbackgraph_currentSegment_Decelerate picked do
	(
		playbackgraph_currentSegment #decel
	)
	on mnu_playbackgraph_currentSegment_PingPong picked do 
	(
		playbackgraph_currentSegment #pingpong
	)
	
	on mnu_playbackgraph_invertAnimation picked do
	(					
		playbackgraph_invertAnimation()
	)
	on mnu_playbackgraph_deleteAnimation picked do 
	(
		playbackgraph_deleteAnimation()
	)
)
	
global PRTFFX_openPlaybackGraphMenu	 --Fixme: add PRTFFX_ prefix to this function 
fn PRTFFX_openPlaybackGraphMenu = --Fixme: add PRTFFX_ prefix to this function 
(
	popUpMenu PRTFFX_KeyframeToolsRCMenu pos:mouse.screenpos
)

