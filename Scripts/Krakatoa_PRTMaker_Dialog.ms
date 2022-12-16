-- Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
-- SPDX-License-Identifier: Apache-2.0
macroScript PRTMakerDesigner category:"Krakatoa" icon:#("Krakatoa",36) tooltip:"Open the Krakatoa PRT Maker Designer utility"
(
global Krakatoa_PRTMaker_Dialog, Krakatoa_PRTMaker_Design_Editor_Dynamic
try(destroyDialog Krakatoa_PRTMaker_Dialog)catch()
try(cui.UnRegisterDialogBar Krakatoa_PRTMaker_Design_Editor_Dynamic)catch()	
try(destroyDialog Krakatoa_PRTMaker_Design_Editor_Dynamic)catch()	
rollout Krakatoa_PRTMaker_Dialog "Krakatoa PRT Maker Designer"	
(
	local thePRTMakers = #()
	local theThumbnail = undefined
	local collectPRTMakers, updateObjectProperties, collectPresets, updateDesignName, updatePresetInfo
	
	dropdownlist ddl_PRTMakers width:220 align:#left offset:[-5,-3] across:3 tooltip:"PRT Maker objects found in the scene. Press Create... to make a new one or UPDATE to refresh the list."
	button btn_createPRTM "Create PRT Maker" width:100 align:#right offset:[55,-3] tooltip:"Create a new PRT Maker object and add it to the list."
	button btn_updatePRTMList "UPDATE" width:80 align:#right offset:[7,-3] tooltip:"Update the UI, load new scene objects and refresh all settings."

	dropdownlist ddl_Method items:#("Disable Fractal Design Effect","Enable Fractal Design Effect") offset:[-5,-3] width:220 across:2
	checkbutton chk_dynamicReset ">Dynamic Explorer Mode" offset:[6,-3] align:#right  width:183 tooltip:"When checked, changing Affine TM Count or Random Seed will automatically RESET and APPLY the design."

	group "Quick Design Generation"
	(
		spinner spn_numTMs "Affine Transformations Count:" range:[2,100,3] type:#integer fieldwidth:50 across:2 align:#left offset:[0,-1]
		spinner spn_randomSeed "Random Seed:" range:[1,100000,12345] type:#integer fieldwidth:50 offset:[0,-1]
	)

	button btn_resetSettings "RESET TO QUICK DESIGN..." height:30 width:205 align:#left across:2 offset:[-9,-2] tooltip:"Resets the current PRT Maker Object and applies the Design with the specified Count and Random Seed"
	button btn_applySettings "APPLY DESIGN AT CURRENT TIME" height:30 width:205 align:#right offset:[9,-2] tooltip:"Sets the current PRT Maker Object to the current Design with the specified Count and Random Seed. If Auto Key is on, the Design will be keyframed as long as the Count remains the same."
	button btn_openEditor "OPEN Fractal Design Parameters Editor..." width:412 height:30 offset:[0,-2] align:#center tooltip:"Generate a Dynamic Dialog with all parameters of the current PRT Maker's Design on the current frame.\n\nChanging time will update the values.\n\nChanging values will keyframe them on the current frame."

	group "Save Design Preset"
	(
		edittext edt_presetName text:"Design1" fieldwidth:217 align:#left offset:[-7,0] across:3
		button btn_savePreset "SAVE Current Design..." width:155 align:#right offset:[110,-2] tooltip:"Saves a new Design Preset with the current frame's settings to the given file name."
		button btn_exploreDesignsFolder "E" tooltip:"Explore Designs Folder..." width:25 offset:[60,-2]
	)

	edittext edt_userComments " User Notes:" height:50 labelOnTop:true width:410 align:#center offset:[0,-3]
	listbox lbx_info height:4 width:410 align:#center offset:[0,-3]

	group "Load Design Preset"
	(
		edittext edt_filterName "Name:" text:"" fieldwidth:157 align:#left offset:[0,-3] across:2
		checkbutton chk_showOnlyMatchingDesigns ">Show Only Compatible Designs" offset:[3,-4] align:#right width:200 tooltip:"When checked, only Design Presets with Affine TM Count matching the current PRT Maker's value will be shown."

		edittext edt_filterScene "Scene:" text:"" fieldwidth:157 align:#left offset:[-2,-3] across:2
		edittext edt_filterObject "Object:" text:"" fieldwidth:157 align:#right offset:[3,-3] 
		
		
		listbox ddl_presetsList width:200 height:11 align:#left across:2 offset:[-7,-3]
		bitmap bmp_Thumbnail width:200 height:149  offset:[2,-3]
		
		
		button btn_loadPreset "LOAD Preset and RESET Design" width:200 height:30 align:#left across:2  offset:[-6,-3] tooltip:"Loads and RESETS the Design Preset by removing all existing Keyframes set from other Designs."
		button btn_mergePreset "MERGE Preset At Current Time" width:200 height:30 align:#right offset:[4,-3] tooltip:"LOADS the Design Preset and Sets KEYFRAMES on the Current Frame. Cannot Merge on Frame 0."
	)
	
	fn collectPRTMakers =
	(
		thePRTMakers = for o in objects where classof o.baseobject == PRT_Maker collect o
		ddl_PRTMakers.items = for o in thePRTMakers collect o.name
		ddl_PRTMakers.selection = ddl_PRTMakers.items.count
		btn_openEditor.enabled = btn_resetSettings.enabled = btn_applySettings.enabled = thePRTMakers.count > 0
	)
	
	fn collectPresets =
	(
		local theFilename = ::Krakatoa_PresetsDirectory + "\\PRTMakerDesigns\\" 
		local theFiles = getFiles (theFilename+"*.PRTMakerDesign")
		ddl_presetsList.items = for f in theFiles collect 
		(
			local theScene = (getIniSetting f "Info" "Scene")
			if theScene == "" do theScene = " "
			if chk_showOnlyMatchingDesigns.checked and getIniSetting f "Settings" "Iterations" != spn_numTMs.value as string then 
				dontcollect 
			else if not matchPattern (getfilenamefile f) pattern:("*"+edt_filterName.text+"*") then 
				dontcollect
			else if not matchPattern theScene pattern:("*"+edt_filterScene.text+"*") then
				dontcollect 
			else if not matchPattern (getIniSetting f "Info" "ObjectName") pattern:("*"+edt_filterObject.text+"*") then
				dontcollect 
			else
				getfilenamefile f
		)
		btn_loadPreset.enabled = btn_mergePreset.enabled = ddl_presetsList.items.count > 0 and thePRTMakers.count > 0
	)
	
	fn addMagmaModifier prtmaker =
	(
		magmaMod = magmaModifier()
		addModifier prtmaker magmaMod
		magmaNode = magmaMod.MagmaHolder
		node0 = magmaNode.createNode "Output" 
		magmaNode.setNumNodeInputs node0 1 
		magmaNode.setNumNodeOutputs node0 0 
		magmaNode.setNodeProperty node0 "channelName" "Color"
		magmaNode.setNodeProperty node0 "channelType" "float16[3]"
		magmaNode.DeclareExtensionProperty node0 "Position"
		magmaNode.SetNodeProperty node0 "Position" [100,100]
		--------------------------------------------
		node1 = magmaNode.createNode "InputChannel" 
		magmaNode.setNumNodeInputs node1 0 
		magmaNode.setNumNodeOutputs node1 1 
		magmaNode.setNodeProperty node1 "channelName" "ColorScalar"
		magmaNode.setNodeProperty node1 "channelType" ""
		magmaNode.DeclareExtensionProperty node1 "Position"
		magmaNode.SetNodeProperty node1 "Position" [420,130]
		--------------------------------------------
		node2 = magmaNode.createNode "Blend" 
		magmaNode.setNumNodeInputs node2 3 
		magmaNode.setNumNodeOutputs node2 1 
		magmaNode.setNodeInputDefaultValue node2 3 0.0
		magmaNode.DeclareExtensionProperty node2 "Position"
		magmaNode.SetNodeProperty node2 "Position" [561,0]
		--------------------------------------------
		node3 = magmaNode.createNode "InputValue" 
		magmaNode.setNumNodeInputs node3 0 
		magmaNode.setNumNodeOutputs node3 1 
		magmaNode.setNodeProperty node3 "forceInteger" false
		ctrl=Point3_XYZ(); ctrl.value = [1,0.3,0.1]
		magmaNode.setNodeProperty node3 "controller" ctrl
		magmaNode.DeclareExtensionProperty node3 "Position"
		magmaNode.SetNodeProperty node3 "Position" [421,15]
		--------------------------------------------
		node4 = magmaNode.createNode "InputValue" 
		magmaNode.setNumNodeInputs node4 0 
		magmaNode.setNumNodeOutputs node4 1 
		magmaNode.setNodeProperty node4 "forceInteger" false
		ctrl=Point3_XYZ(); ctrl.value = [0.1,0.3,1]
		magmaNode.setNodeProperty node4 "controller" ctrl
		magmaNode.DeclareExtensionProperty node4 "Position"
		magmaNode.SetNodeProperty node4 "Position" [421,70]
		--------------------------------------------
		node5 = magmaNode.createNode "Output" 
		magmaNode.setNumNodeInputs node5 1 
		magmaNode.setNumNodeOutputs node5 0 
		magmaNode.setNodeProperty node5 "channelName" "Emission"
		magmaNode.setNodeProperty node5 "channelType" "float16[3]"
		magmaNode.DeclareExtensionProperty node5 "Position"
		magmaNode.SetNodeProperty node5 "Position" [710,100]		
		--------------------------------------------		
		try(magmaNode.setNodeInput node0 1 node2 1)catch()
		try(magmaNode.setNodeInput node2 1 node3 1)catch()
		try(magmaNode.setNodeInput node2 2 node4 1)catch()
		try(magmaNode.setNodeInput node2 3 node1 1)catch()
		try(magmaNode.setNodeInput node5 1 node2 1)catch()		
		--------------------------------------------		
	)
	
	on edt_filterName changed txt do collectPresets()
	on edt_filterScene changed txt do collectPresets()
	on edt_filterObject changed txt do collectPresets()
	
	fn updateDesignName =
	(
		try
		(
			local theType = getAppData thePRTMakers[ddl_PRTMakers.selection] 20111013
			local theTypeString = case theType of
			(
					default: "BaseDesign"
					"merge": "CustomDesign"
					"reset": "CustomBase"
			)
			edt_presetName.text = theTypeString+"_" + (currentTime.frame as integer) as string + "_" + spn_numTMs.value as string + "_" + spn_randomSeed.value as string
		)catch(edt_presetName.text = "Design")
		try
		(
			Krakatoa_PRTMaker_Design_Editor_Dynamic.updateUI()
		)catch()
	)
	
	fn updateObjectProperties =
	(
		if ddl_PRTMakers.selection > 0 then
		(
			spn_randomSeed.value = thePRTMakers[ddl_PRTMakers.selection].randomSeed
			spn_numTMs.value = thePRTMakers[ddl_PRTMakers.selection].AffineTMCount
			ddl_Method.selection = thePRTMakers[ddl_PRTMakers.selection].Method + 1
		)
		else
		(
			spn_randomSeed.value = 12345
			spn_numTMs.value = 3
			ddl_Method.selection = 1
		)
		updateDesignName()
	)	
	
	
	fn buildDynamicUI obj =
	(
		try(cui.UnRegisterDialogBar Krakatoa_PRTMaker_Design_Editor_Dynamic)catch()	
		try(destroyDialog Krakatoa_PRTMaker_Design_Editor_Dynamic)catch()	

		txt = "" as stringStream
		global Krakatoa_PRTMaker_Design_Editor_Dynamic_Object = obj
		format "rollout Krakatoa_PRTMaker_Design_Editor_Dynamic \"PRT Maker : Fractal Design Parameters Editor: [%]\" width:1100 (\n" obj.name to:txt
		format "label lbl_pos_x \"Pos X:\" across:16 \n" to:txt
		format "label lbl_pos_y \"Pos Y:\" \n" to:txt
		format "label lbl_pos_z \"Pos Z:\" \n" to:txt
		
		format "label lbl_rot_x \"Rot X:\" \n" to:txt
		format "label lbl_rot_y \"Rot Y:\" \n" to:txt
		format "label lbl_rot_z \"Rot Z:\" \n" to:txt
		format "label lbl_rot_w \"Rot W:\" \n" to:txt
		
		format "label lbl_scale_x \"Scale X:\" \n" to:txt
		format "label lbl_scale_y \"Scale Y:\" \n" to:txt
		format "label lbl_scale_z \"Scale Z:\" \n" to:txt
		
		format "label lbl_skew_x \"Skew X:\" \n" to:txt
		format "label lbl_skew_y \"Skew Y:\" \n" to:txt
		format "label lbl_skew_z \"Skew Z:\" \n" to:txt
		format "label lbl_skew_w \"Skew W:\" \n" to:txt
		
		format "label lbl_skewAngle \"Skew A:\" \n" to:txt
		format "label lbl_weight \"Weight:\" \n" to:txt		
		
		for i = 1 to obj.affineTMCount do
		(
			format "spinner spn_pos_x_% \"%:\" fieldwidth:45 type:#float range:[-1,1,%] scale:0.01 across:16 \n" i i obj.TMControllers[i].Base_Transform.position.x to:txt
			format "spinner spn_pos_y_% fieldwidth:45 type:#float range:[-1,1,%] scale:0.01\n" i obj.TMControllers[i].Base_Transform.position.y to:txt
			format "spinner spn_pos_z_% fieldwidth:45 type:#float range:[-1,1,%] scale:0.01\n" i obj.TMControllers[i].Base_Transform.position.z to:txt

			format "spinner spn_rot_x_% fieldwidth:45 type:#float range:[-1,1,%] scale:0.01\n" i obj.TMControllers[i].Base_Transform.rotation.x to:txt
			format "spinner spn_rot_y_% fieldwidth:45 type:#float range:[-1,1,%] scale:0.01\n" i obj.TMControllers[i].Base_Transform.rotation.y to:txt
			format "spinner spn_rot_z_% fieldwidth:45 type:#float range:[-1,1,%] scale:0.01\n" i obj.TMControllers[i].Base_Transform.rotation.z to:txt
			format "spinner spn_rot_w_% fieldwidth:45 type:#float range:[-10000,10000,%] \n" i obj.TMControllers[i].Base_Transform.rotation.w to:txt

			format "spinner spn_scale_x_% fieldwidth:45 type:#float range:[-10.0,10,%] scale:0.01 \n" i obj.TMControllers[i].Base_Transform.scale.x to:txt
			format "spinner spn_scale_y_% fieldwidth:45 type:#float range:[-10.0,10,%] scale:0.01\n" i obj.TMControllers[i].Base_Transform.scale.y to:txt
			format "spinner spn_scale_z_% fieldwidth:45 type:#float range:[-10.0,10,%] scale:0.01\n" i obj.TMControllers[i].Base_Transform.scale.z to:txt

			format "spinner spn_skew_X_% fieldwidth:45 type:#float range:[-1,1,%] scale:0.01\n" i obj.TMControllers[i].Skew_Orientation.value.x to:txt
			format "spinner spn_skew_Y_% fieldwidth:45 type:#float range:[-1,1,%] scale:0.01\n" i obj.TMControllers[i].Skew_Orientation.value.y to:txt
			format "spinner spn_skew_Z_% fieldwidth:45 type:#float range:[-1,1,%] scale:0.01\n" i obj.TMControllers[i].Skew_Orientation.value.z to:txt
			format "spinner spn_skew_W_% fieldwidth:45 type:#float range:[-10000,10000,%] \n" i obj.TMControllers[i].Skew_Orientation.value.w to:txt
			
			format "spinner spn_skewAngle_% fieldwidth:45 type:#float range:[0.0,360,%] \n" i obj.TMControllers[i].Skew_Angle to:txt
			format "spinner spn_weight_% fieldwidth:45 type:#float range:[0.0,100,%] scale:0.01\n" i obj.TMControllers[i].Weight to:txt
			
			format "fn updateObject_% = (\n" i to:txt
			format "if not isValidNode ::Krakatoa_PRTMaker_Design_Editor_Dynamic_Object do try(cui.UnRegisterDialogBar Krakatoa_PRTMaker_Design_Editor_Dynamic; destroyDialog Krakatoa_PRTMaker_Design_Editor_Dynamic)catch()	\n" to:txt
			format "with animate on (\n" to:txt
			format "::Krakatoa_PRTMaker_Design_Editor_Dynamic_Object.TMControllers[%].Base_Transform.rotation = quat spn_rot_x_%.value spn_rot_y_%.value spn_rot_z_%.value spn_rot_w_%.value \n" i i i i i i to:txt
			format "::Krakatoa_PRTMaker_Design_Editor_Dynamic_Object.TMControllers[%].Base_Transform.scale = Point3 spn_scale_x_%.value spn_scale_y_%.value spn_scale_z_%.value \n" i i i i i to:txt
			format "::Krakatoa_PRTMaker_Design_Editor_Dynamic_Object.TMControllers[%].Base_Transform.position = Point3 spn_pos_x_%.value spn_pos_y_%.value spn_pos_z_%.value \n" i i i i i to:txt

			format "::Krakatoa_PRTMaker_Design_Editor_Dynamic_Object.TMControllers[%].Skew_Orientation = quat spn_skew_x_%.value spn_skew_y_%.value spn_skew_z_%.value spn_skew_w_%.value \n" i i i i i i to:txt

			format "::Krakatoa_PRTMaker_Design_Editor_Dynamic_Object.TMControllers[%].SkewAngle = spn_skewAngle_%.value \n" i i to:txt
			format "::Krakatoa_PRTMaker_Design_Editor_Dynamic_Object.TMControllers[%].Weight = spn_weight_%.value \n" i i to:txt
			format "))\n" to:txt
			
			format "fn updateSpinners_% = (\n" i to:txt
			format "spn_pos_x_%.value = ::Krakatoa_PRTMaker_Design_Editor_Dynamic_Object.TMControllers[%].Base_Transform.position.x \n" i i to:txt
			format "spn_pos_y_%.value = ::Krakatoa_PRTMaker_Design_Editor_Dynamic_Object.TMControllers[%].Base_Transform.position.y \n" i i to:txt
			format "spn_pos_z_%.value = ::Krakatoa_PRTMaker_Design_Editor_Dynamic_Object.TMControllers[%].Base_Transform.position.z \n" i i to:txt

			format "spn_rot_x_%.value = ::Krakatoa_PRTMaker_Design_Editor_Dynamic_Object.TMControllers[%].Base_Transform.rotation.x \n" i i to:txt
			format "spn_rot_y_%.value = ::Krakatoa_PRTMaker_Design_Editor_Dynamic_Object.TMControllers[%].Base_Transform.rotation.y \n" i i to:txt
			format "spn_rot_z_%.value = ::Krakatoa_PRTMaker_Design_Editor_Dynamic_Object.TMControllers[%].Base_Transform.rotation.z \n" i i to:txt
			format "spn_rot_w_%.value = ::Krakatoa_PRTMaker_Design_Editor_Dynamic_Object.TMControllers[%].Base_Transform.rotation.w \n" i i to:txt

			format "spn_scale_x_%.value = ::Krakatoa_PRTMaker_Design_Editor_Dynamic_Object.TMControllers[%].Base_Transform.scale.x \n" i i to:txt
			format "spn_scale_y_%.value = ::Krakatoa_PRTMaker_Design_Editor_Dynamic_Object.TMControllers[%].Base_Transform.scale.y \n" i i to:txt
			format "spn_scale_z_%.value = ::Krakatoa_PRTMaker_Design_Editor_Dynamic_Object.TMControllers[%].Base_Transform.scale.z \n" i i to:txt

			format "spn_skew_X_%.value = ::Krakatoa_PRTMaker_Design_Editor_Dynamic_Object.TMControllers[%].Skew_Orientation.value.x \n" i i to:txt
			format "spn_skew_Y_%.value = ::Krakatoa_PRTMaker_Design_Editor_Dynamic_Object.TMControllers[%].Skew_Orientation.value.y \n" i i to:txt
			format "spn_skew_Z_%.value = ::Krakatoa_PRTMaker_Design_Editor_Dynamic_Object.TMControllers[%].Skew_Orientation.value.z \n" i i to:txt
			format "spn_skew_W_%.value = ::Krakatoa_PRTMaker_Design_Editor_Dynamic_Object.TMControllers[%].Skew_Orientation.value.w \n" i i to:txt

			format "spn_skewAngle_%.value = ::Krakatoa_PRTMaker_Design_Editor_Dynamic_Object.TMControllers[%].SkewAngle \n" i i to:txt
			format "spn_weight_%.value = ::Krakatoa_PRTMaker_Design_Editor_Dynamic_Object.TMControllers[%].Weight \n" i i to:txt
			format ")\n" to:txt

			format "on spn_pos_x_% changed val do updateObject_%()\n" i i to:txt
			format "on spn_pos_y_% changed val do updateObject_%()\n" i i to:txt
			format "on spn_pos_z_% changed val do updateObject_%()\n" i i to:txt
			
			format "on spn_rot_x_% changed val do updateObject_%()\n" i i to:txt
			format "on spn_rot_y_% changed val do updateObject_%()\n" i i to:txt
			format "on spn_rot_z_% changed val do updateObject_%()\n" i i to:txt
			format "on spn_rot_w_% changed val do updateObject_%()\n" i i to:txt

			format "on spn_scale_x_% changed val do updateObject_%()\n" i i to:txt
			format "on spn_scale_y_% changed val do updateObject_%()\n" i i to:txt
			format "on spn_scale_z_% changed val do updateObject_%()\n" i i to:txt

			format "on spn_skew_X_% changed val do updateObject_%()\n" i i to:txt
			format "on spn_skew_Y_% changed val do updateObject_%()\n" i i to:txt
			format "on spn_skew_Z_% changed val do updateObject_%()\n" i i to:txt
			format "on spn_skew_W_% changed val do updateObject_%()\n" i i to:txt

			format "on spn_skewAngle_% changed val do updateObject_%()\n" i i to:txt
			format "on spn_weight_% changed val do updateObject_%()\n" i i to:txt
		)
		format "fn updateUI =(\n" to:txt
		format "if not isValidNode ::Krakatoa_PRTMaker_Design_Editor_Dynamic_Object do try(cui.UnRegisterDialogBar Krakatoa_PRTMaker_Design_Editor_Dynamic; destroyDialog Krakatoa_PRTMaker_Design_Editor_Dynamic)catch()	\n" to:txt
		for i = 1 to obj.affineTMCount do format "updateSpinners_% ()\n" i to:txt
		format ")\n" to:txt
		
		format "on Krakatoa_PRTMaker_Design_Editor_Dynamic moved pos do setIniSetting (GetDir #plugcfg + \"/Krakatoa/KrakatoaPreferences.ini\") \"PRTMakerDesignEditor\" \"Position\" (pos as string)\n" to:txt
		format ")\n" to:txt
		execute (txt as string)
		local thePos = execute (getIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "PRTMakerDesignEditor" "Position" )
		if thePos == OK do thePos = [100,100]
		local theDesktop = sysInfo.DesktopSize
		if thePos.x > theDesktop.x-470 do thePos.x = theDesktop.x - 470
		if thePos.y > theDesktop.y-200 do thePos.y = theDesktop.y - 200
		if thePos.x < 0 do thePos.x = 0
		if thePos.y < 0 do thePos.y = 0	
		createDialog ::Krakatoa_PRTMaker_Design_Editor_Dynamic pos:thePos
		cui.RegisterDialogBar ::Krakatoa_PRTMaker_Design_Editor_Dynamic style:#(#cui_dock_horz, #cui_floatable, #cui_handles, #cui_max_sized )
	)
	
	fn updateGUI =
	(
		collectPRTMakers()
		updateObjectProperties()
		collectPresets ()
		updateDesignName()
		updatePresetInfo()		
	)
	
	fn makeDesign obj reset:false= 
	(
		if not isValidNode obj do 
		(
			updateGUI()
			return false
		)
		with undo "Apply PRTM Design" on
		(
			seed spn_randomSeed.value
			if reset do obj.affineTMCount = 0
			obj.affineTMCount = spn_numTMs.value
			obj.Method = 1
			with animate (not reset)
			(
				for i = 1 to spn_numTMs.value do 
				(
					local theta = random 0.0 360.0
					local phi = acos ( random -1.0 1.0 )
					local roll = random 0.0 360.0
					
					local skewOrientation = (angleaxis roll [(sin theta)*(cos phi), (sin theta)*(sin phi), (cos theta)]) as quat
					local skewAngle = random 0.0 45.0
					
					local trans = random [-1.0, -1.0, -1.0] [1.0, 1.0, 1.0]
					local scale = random [0.2, 0.2, 0.2] [1.0, 1.0, 1.0]
					
					local u = random 0.0 360.0
					local v = acos ( random -1.0 1.0 )
					local w = random 0.0 360.0
					local rot = ( angleaxis w [(cos u)*(sin v), (sin u)*(sin v), cos v] ) as quat
					
					obj.TMControllers[i].Base_Transform.rotation = rot
					obj.TMControllers[i].Base_Transform.scale = scale
					obj.TMControllers[i].Base_Transform.position = trans --MUST be set after Rotation and Scale to create Keys correctly
					
					obj.TMControllers[i].Skew_Orientation = skewOrientation
					obj.TMControllers[i].Skew_Angle = skewAngle
					obj.TMControllers[i].Weight = 1.0			
				)--end i loop
			)
			setAppData obj 20111013 (if reset then "base" else "merge")
		)
	)--end fn	
	
	fn loadPreset obj animateIt:off =
	(
		if not isValidNode obj do 
		(
			updateGUI()
			return false
		)		
		with undo "Load PRTM Design" on
		(
			local theFilename = ::Krakatoa_PresetsDirectory + "\\PRTMakerDesigns\\" + ddl_presetsList.selected + ".PRTMakerDesign"
			local theVal = execute (getIniSetting theFilename "Settings" "Iterations")
			local theMethod = execute (getIniSetting theFilename "Settings" "Method")
			if theMethod == OK do theMethod = 1
			if theVal != OK do
			(
				if not animateIt then
				(
					obj.Method = theMethod
					obj.affineTMCount = 0
					spn_numTMs.value = obj.affineTMCount = theVal
					spn_randomSeed.value = execute (getIniSetting theFilename "Settings" "RandomSeed")
				)
				else
				(
					if theVal != obj.AffineTMCount do
					(
						q = querybox ("Selected Object Has "+obj.AffineTMCount as string +" Affine Transformations\nSpecified Design To Merge has " + theVal as string +".\n\nAre you sure you want to continue?") title:"TM Count Mismatch!"
						if not q do return false
					)
				)
				with animate animateIt
				(
					theIterations = amin #(theVal, spn_numTMs.value)
					--for j = 1 to 2 do
					for i = 1 to theIterations do 
					(
						obj.TMControllers[i].Base_Transform.rotation = execute (getIniSetting theFilename "Settings" ("Base_Transform_Rotation_"+i as string))
						obj.TMControllers[i].Base_Transform.scale = execute (getIniSetting theFilename "Settings" ("Base_Transform_Scale_"+i as string))
						obj.TMControllers[i].Base_Transform.position = execute (getIniSetting theFilename "Settings" ("Base_Transform_Position_"+i as string))
						obj.TMControllers[i].Skew_Orientation = execute (getIniSetting theFilename "Settings" ("Skew_Orientation_"+i as string))
						obj.TMControllers[i].Skew_Angle = execute (getIniSetting theFilename "Settings" ("Skew_Angle_"+i as string))
						obj.TMControllers[i].Weight = execute (getIniSetting theFilename "Settings" ("Weight_"+i as string))
							
				/*
						format "%: % = %\n" i "Base_Transform_Position" obj.TMControllers[i].Base_Transform.position
						format "%: % = %\n" i "Base_Transform_Rotation" obj.TMControllers[i].Base_Transform.rotation
						format "%: % = %\n" i "Base_Transform_Scale" obj.TMControllers[i].Base_Transform.scale
						format "%: % = %\n" i "Skew_Orientation" obj.TMControllers[i].Skew_Orientation
						format "%: % = %\n" i "Skew_Angle" obj.TMControllers[i].Skew_Angle
						format "%: % = %\n" i "Weight" obj.TMControllers[i].Weight
							*/
					)--end i loop		
					setAppData obj 20111013 (if animateIt then "merge" else "reset")
				)
			)
		)--end undo 
	)
	
	
	fn savePreset obj =
	(
		if not isValidNode obj do 
		(
			updateGUI()
			return false
		)		
		local theFilename = ::Krakatoa_PresetsDirectory + "\\PRTMakerDesigns\\" 
		makeDir theFilename all:true
		theFilename += edt_presetName.text + ".PRTMakerDesign"
		
		if not doesFileExist theFilename or querybox ("The Design Preset File ["+edt_presetName.text+"] Exists!\n\nDo you want to replace it?") title:"Design Exists!" do
		(
			setIniSetting theFilename "Info" "Scene" (maxFilePath + maxFilename)
			setIniSetting theFilename "Info" "User" sysinfo.username
			setIniSetting theFilename "Info" "Computer" sysinfo.computername
			setIniSetting theFilename "Info" "Date" localtime
			setIniSetting theFilename "Info" "ObjectName" obj.name
			
			with printAllElements on setIniSetting theFilename "Info" "UserComments" ((filterString edt_userComments.text "\n") as string)
			
			setIniSetting theFilename "Settings" "RandomSeed" (spn_randomSeed.value as string)
			setIniSetting theFilename "Settings" "Iterations" (obj.TMControllers.count as string)
			setIniSetting theFilename "Settings" "Method" (obj.Method as string)
			
			for i = 1 to obj.TMControllers.count do 
			(
				setIniSetting theFilename "Settings" ("Base_Transform_Position_"+i as string) (obj.TMControllers[i].Base_Transform.position as string)
				setIniSetting theFilename "Settings" ("Base_Transform_Rotation_"+i as string) (obj.TMControllers[i].Base_Transform.rotation  as string)
				setIniSetting theFilename "Settings" ("Base_Transform_Scale_"+i as string) (obj.TMControllers[i].Base_Transform.scale  as string)
				setIniSetting theFilename "Settings" ("Skew_Orientation_"+i as string) (obj.TMControllers[i].Skew_Orientation.value  as string)
				setIniSetting theFilename "Settings" ("Skew_Angle_"+i as string) (obj.TMControllers[i].Skew_Angle as string)
				setIniSetting theFilename "Settings" ("Weight_"+i as string) (obj.TMControllers[i].Weight as string)
			)		
			viewportBmp = gw.getViewportDib()
			viewportBmp.filename = getFileNamePath theFilename + getFileNameFile theFilename + ".jpg"
			save viewportBmp
			setIniSetting theFilename "Bitmap" "Filename" viewportBmp.filename
		)
	)
	
	on edt_userComments entered txt do
	(
		if ddl_presetsList.selection > 0 do
		(
			local theFilename = ::Krakatoa_PresetsDirectory + "\\PRTMakerDesigns\\" 
			theFilename += ddl_presetsList.selected + ".PRTMakerDesign"
			with printAllElements on setIniSetting theFilename "Info" "UserComments" ((filterString edt_userComments.text "\n") as string)
		)
	)
	
	fn updatePresetInfo =
	(
		if ddl_presetsList.selected == undefined do return false
		local theFilename = ::Krakatoa_PresetsDirectory + "\\PRTMakerDesigns\\" 
		theFilename += ddl_presetsList.selected + ".PRTMakerDesign"
		local theTextArray = execute (getIniSetting theFilename "Info" "UserComments" )
		if theTextArray == OK do theTextArray = #()
		local theText = "" as stringStream
		for i in theTextArray do format "%\r\n" i to:theText
		edt_userComments.text = theText as string		
		
		local theInfoArray = #()
		append theInfoArray ("Created by "+(getIniSetting theFilename "Info" "User")+"@" + (getIniSetting theFilename "Info" "Computer") + " on " + (getIniSetting theFilename "Info" "Date"))
		append theInfoArray ("Scene:"+(getIniSetting theFilename "Info" "Scene"))
		append theInfoArray ("Object Name: "+(getIniSetting theFilename "Info" "ObjectName" ))
		append theInfoArray ("Affine Transformations Count: "+(getIniSetting theFilename "Settings" "Iterations" ) + "    Random Seed: " + (getIniSetting theFilename "Settings" "RandomSeed"))
			
		lbx_info.items = theInfoArray
			
		local theBmpFilename = getIniSetting theFilename "Bitmap" "Filename" 
		if doesFileExist theBmpFilename then
		(
			try
			(
				theBitmap = openBitmap theBmpFilename
				copy theBitmap theThumbnail
				close theBitmap
			)catch(theThumbnail = bitmap 200 150 color:(white*0.5))
		)
		else
			theThumbnail = bitmap 200 150 color:(white*0.7)
		bmp_Thumbnail.bitmap = theThumbnail
	)
	
	on ddl_presetsList selected itm do
	(
		updatePresetInfo()
	)
	on ddl_presetsList doubleClicked itm do
	(
		if ddl_presetsList.selected == undefined do return false
		local theFilename = ::Krakatoa_PresetsDirectory + "\\PRTMakerDesigns\\" 
		theFilename += ddl_presetsList.selected + ".PRTMakerDesign"
		local theBmpFilename = getIniSetting theFilename "Bitmap" "Filename" 
		try(theBitmap = openBitmap theBmpFilename; display theBitmap)catch()
	)	
	
	on btn_exploreDesignsFolder pressed do
	(
		shellLaunch (::Krakatoa_PresetsDirectory + "\\PRTMakerDesigns\\" ) ""
	)
	
	on btn_savePreset pressed do
	(
		if ddl_PRTMakers.selection > 0 do 
		(
			savePreset thePRTMakers[ddl_PRTMakers.selection] 
			local lastDesign = edt_presetName.text
			collectPresets()
			theIndex = findItem ddl_presetsList.items  lastDesign
			if theIndex != 0 do 
			(
				ddl_presetsList.selection = theIndex
				updatePresetInfo()
			)
			updateDesignName()
		)
	)
	
	on btn_createPRTM pressed do 
	(
		local theMaker = PRT_Maker()
		theMaker.method = 1
		theMaker.affineTMCount = 3
		theMaker.ViewportCount = 100000
		theMaker.IconSize = 10
		collectPRTMakers()
		updateObjectProperties()
		makeDesign theMaker reset:true
		addMagmaModifier theMaker
		updateGUI()
	)
	
	on btn_loadPreset pressed do
	(
		if ddl_PRTMakers.selection > 0 do 
		(
			loadPreset thePRTMakers[ddl_PRTMakers.selection] animateIt:off
			local oldState = false
			if Krakatoa_PRTMaker_Design_Editor_Dynamic!= undefined do
				oldState = Krakatoa_PRTMaker_Design_Editor_Dynamic.open
			
			try(cui.UnRegisterDialogBar Krakatoa_PRTMaker_Design_Editor_Dynamic)catch()	
			try(destroyDialog Krakatoa_PRTMaker_Design_Editor_Dynamic)catch()		
			if oldState do buildDynamicUI thePRTMakers[ddl_PRTMakers.selection]
		)
		updateDesignName()
	)
	
	on btn_mergePreset pressed do
	(
		if currentTime.frame == 0 then
			messagebox "Cannot MERGE Design Preset on Frame 0.\nPlease select a different Frame and try again." title:"Cannot Merge PRT Maker Design"
		else
			if ddl_PRTMakers.selection > 0 and ddl_presetsList.selection > 0 do 
				loadPreset thePRTMakers[ddl_PRTMakers.selection] animateIt:on
		updateDesignName()			
	)
	
	on btn_applySettings pressed do
	(
		if ddl_PRTMakers.selection > 0 do 
			makeDesign thePRTMakers[ddl_PRTMakers.selection] reset:false
		updateDesignName()
	)
	
	on btn_resetSettings pressed do
	(
		if ddl_PRTMakers.selection > 0 do 
		(
			makeDesign thePRTMakers[ddl_PRTMakers.selection] reset:true
			local oldState = false
			if Krakatoa_PRTMaker_Design_Editor_Dynamic != undefined do 
				oldState = Krakatoa_PRTMaker_Design_Editor_Dynamic.open
			try(cui.UnRegisterDialogBar Krakatoa_PRTMaker_Design_Editor_Dynamic)catch()	
			try(destroyDialog Krakatoa_PRTMaker_Design_Editor_Dynamic)catch()		
			if oldState do buildDynamicUI thePRTMakers[ddl_PRTMakers.selection]
		)
		updateDesignName()
	)	
	
		
	on chk_showOnlyMatchingDesigns changed state do collectPresets()

	on ddl_Method selected itm do 
	(
		if ddl_PRTMakers.selection > 0 then
			thePRTMakers[ddl_PRTMakers.selection].Method = itm-1
	)
	
	on spn_numTMs changed state do 
	(
		collectPresets()
		if chk_dynamicReset.state do 
		(
			if ddl_PRTMakers.selection > 0 do 
				makeDesign thePRTMakers[ddl_PRTMakers.selection] reset:true
			updateDesignName()		
		)
	)
	on spn_randomSeed changed state do
	(
		if chk_dynamicReset.state do 
		(
			if ddl_PRTMakers.selection > 0 do 
				makeDesign thePRTMakers[ddl_PRTMakers.selection] reset:true
			updateDesignName()	
		)
	)
	on ddl_PRTMakers selected itm do 
	(
		try(select thePRTMakers[itm])catch()
		updateObjectProperties()
	)
	
	on btn_openEditor pressed do
	(
		if ddl_PRTMakers.selection > 0 do 
			buildDynamicUI thePRTMakers[ddl_PRTMakers.selection]
	)
	
	on Krakatoa_PRTMaker_Dialog open do
	(
		theThumbnail = bitmap 200 150 color:(white*0.7)
		updateGUI()
		registerTimeCallback updateDesignName
	)
	on btn_updatePRTMList pressed do 
	(
		updateGUI()
	)
	
	on Krakatoa_PRTMaker_Dialog close do
	(
		unregisterTimeCallback updateDesignName
		try(cui.UnRegisterDialogBar Krakatoa_PRTMaker_Design_Editor_Dynamic)catch()	
		try(destroyDialog Krakatoa_PRTMaker_Design_Editor_Dynamic)catch()	
	)
	
	on Krakatoa_PRTMaker_Dialog moved pos do setIniSetting (GetDir #plugcfg + "/Krakatoa/KrakatoaPreferences.ini") "PRTMakerDesignerDialog" "Position" (pos as string)
)

local thePos = execute (getIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "PRTMakerDesignerDialog" "Position" )
if thePos == OK do thePos = [100,100]
local theDesktop = sysInfo.DesktopSize
if thePos.x > theDesktop.x-470 do thePos.x = theDesktop.x - 470
if thePos.y > theDesktop.y-200 do thePos.y = theDesktop.y - 200
if thePos.x < 0 do thePos.x = 0
if thePos.y < 0 do thePos.y = 0	

createDialog Krakatoa_PRTMaker_Dialog width:420 pos:thePos
	
)
