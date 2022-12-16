-- Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
-- SPDX-License-Identifier: Apache-2.0
global Krakatoa_GUI_ParticleLoaders, Krakatoa_GUI_PRTFumeExplorer, Krakatoa_GUI_PRTHairExplorer, Krakatoa_GUI_ThinkingParticles, Krakatoa_GUI_Particles, Krakatoa_GUI_PRTVolumeExplorer

--------------------------------------------------------------------------------------------------------------------------------------------------------------------	
--PRT VOLUME EXPLORER ROLLOUT
--------------------------------------------------------------------------------------------------------------------------------------------------------------------	
rollout Krakatoa_GUI_PRTVolumeExplorer "PRT Volume Objects" category:250 width:457
(
	local KrakatoaVolumeList = #()
	
	button btn_Help_Loaders  "Open Online Help..." width:450 height:16 align:#center offset:[0,-5] across:1 tooltip:"Opens the Krakatoa Online Help for the PRT Volume Objects rollout in the default Web Browser. Requires Internet connection."
	
	checkbutton chb_synchSelections ">Synch. Selection" across:3 width:144 align:#left checked:true offset:[-8,0] highlightcolor:KrakatoaSkinColorsStruct.Loaders tooltip:"When checked, selecting objects from the list will update the scene selection.\n\nWhen unchecked, the scene selection will not be synchronized to the list selection.\n\nHowever, selecting objects in the scene will always update the list's selection regardless of the state of this option."
	dropdownlist ddl_displayInfo items:#("Volume Source","Render Grid Settings","Random Seed Settings","Viewport Grid Settings","Viewport Limits Settings","Surface Shell Settings","Test Renderable State") width:154 align:#center offset:[2,0] tooltip:"Display the following PRT Volume properties..."
	button btn_createPRTVolume "Create PRT Volume..." width:144 align:#right offset:[10,0] tooltip:"Create a PRT Volume from selected Simulations. If no Simulations are selected, create at origin. If SHIFT pressed, create manually."
	
	multilistbox lbx_PRTVolumeInScene height:15 width:450 align:#center offset:[0,-5]
	
	button btn_selectAll "Select All Objects" width:148 align:#left across:3 offset:[-10,-5] height:18
	button btn_deselectAll "Deselect All Objects" width:149 align:#center offset:[0,-5] height:18
	button btn_selectInvert "Invert Objects Selection" width:148 align:#right offset:[10,-5] height:18
	
	button btn_hideSelected "Hide Selected Objects" width:148 align:#left across:3 offset:[-10,-3] height:18
	button btn_unhideSelected "Unhide Selected Objects" width:149 align:#center offset:[0,-3] height:18
	button btn_selectHidden "Select Hidden Objects" width:148 align:#right offset:[10,-3] height:18

	label lbl_placeholder01 "" offset:[0,-23]

	group "Align And Link"
	(
		button btn_AlignRPTVToSource "Align To Source" width:108 offset:[-5,-3] align:#left height:18 across:4
		button btn_AlignSourceToPRTV "Align To PRT Volume" width:108 offset:[-2,-3] align:#left height:18
		button btn_ParentPRTVToSource "Link To Source" width:108 offset:[2,-3] align:#right  height:18
		button btn_UnparentPRTVFromSource "Unlink From Source" width:108 offset:[5,-3] align:#right height:18
	)
	

	label lbl_placeholder02 "" offset:[0,-23]
	group "Source"
	(
		
		spinner spn_RenderSpacing "Render Spacing:" fieldwidth:45 offset:[15,-3]  range:[0.001,100000,1] align:#left type:#float across:4
		button btn_RenderSpacing "Set Value" width:60 offset:[45,-4] align:#left height:18

		spinner spn_ViewSpacing "View Spacing:" fieldwidth:45 offset:[50,-3] range:[0.001,4096,10] align:#right type:#float 
		button btn_ViewSpacing "Set Value" width:60 offset:[5,-4] align:#right height:18
		
		button btn_ViewSpacingOn1 "Spacing ON" width:108 offset:[-5,-3] align:#left  visible:false across:4 height:18
		button btn_ViewSpacingOff1 "Spacing OFF" width:108 offset:[-2,-3] align:#left visible:false height:18
		button btn_ViewSpacingOn "View Spacing ON" width:108 offset:[2,-3] align:#right  height:18
		button btn_ViewSpacingOff "View Spacing OFF" width:108 offset:[5,-3] align:#right height:18
		
	)
	label lbl_placeholder03 "" offset:[0,-23]
	group "Seeding"
	(
		button btn_subdivideON "Subdivide ON" width:108 offset:[-5,-5] align:#left   across:4 height:18
		button btn_subdivideOFF "Subdivide OFF" width:108 offset:[-2,-5] align:#left height:18
		button btn_jitterON "Jitter ON" width:108 offset:[2,-5] align:#right  height:18
		button btn_jitterOFF "Jitter OFF" width:108 offset:[5,-5] align:#right height:18

		button btn_wellON "Well Distributed ON" width:108 offset:[-5,-3] align:#left   across:4 height:18
		button btn_wellOFF "Well Distributed OFF" width:108 offset:[-2,-3] align:#left height:18
		button btn_MultipleON "Multiple ON" width:108 offset:[2,-3] align:#right  height:18
		button btn_MultipleOFF "Multiple OFF" width:108 offset:[5,-3] align:#right height:18
			
		spinner spn_GridSubdivs "Subdivisons:" fieldwidth:45 offset:[35,-3] range:[1,10,1] align:#left type:#integer across:4
		button btn_GridSubdivs "Set Value" width:60 offset:[46,-4] align:#left  height:18

		spinner spn_RandomNumber "Multi/Region:" fieldwidth:45 offset:[50,-3] range:[2,1000,1] align:#right type:#integer
		button btn_RandomNumber "Set Value" width:60 offset:[5,-4] align:#right height:18
		
		spinner spn_RandomCount "Random Count:" fieldwidth:45 offset:[19,-3] range:[1,4096,1024] align:#left type:#integer across:4 
		button btn_RandomCount "Set Value" width:60 offset:[46,-4] align:#left height:18

		spinner spn_RandomSeed "Random Seed:" fieldwidth:45 offset:[50,-3]  range:[1,100000,42] align:#right type:#integer 
		button btn_RandomSeed "Set Value" width:60 offset:[5,-4] align:#right  height:18
	)	
	label lbl_placeholder04 "" offset:[0,-23]
	group "Viewport"
	(
		button btn_ViewOn "Viewport ON" width:108 offset:[-5,-3] align:#left across:4 height:18
		button btn_ViewOff "Viewport OFF" width:108 offset:[-2,-3] align:#left  height:18
		button btn_ViewSubdivOn "Subdiv. ON" width:108 offset:[2,-3] align:#right height:18
		button btn_ViewSubdivOff "Subdiv. OFF" width:108 offset:[5,-3] align:#right height:18
		
		
		button btn_ViewPercentOn "View Percent ON" width:108 offset:[-5,-3] align:#left  across:4 height:18
		button btn_ViewPercentOff "View Percent OFF" width:108 offset:[-2,-3] align:#left height:18
		button btn_ViewLimitOn "View Limit ON" width:108 offset:[2,-3] align:#right height:18
		button btn_ViewLimitOff "View Limit OFF" width:108 offset:[5,-3] align:#right height:18

		spinner spn_ViewportPercent "Viewport Percent:" fieldwidth:45 offset:[8,-3] range:[0,100,1] align:#left type:#float across:4 
		button btn_ViewportPercent "Set Value" width:60 offset:[46,-4] align:#left  height:18

		spinner spn_ViewportLimit "Viewport Limit:" fieldwidth:45 offset:[50,-3]  range:[0,100000,1000.0] align:#right type:#float 
		button btn_ViewportLimit "Set Value" width:60 offset:[5,-4] align:#right  height:18

		spinner spn_IconSize "Icon Size:" fieldwidth:45 offset:[47,-3]  range:[0,100000,100.0] align:#left type:#float across:4 
		button btn_IconSize "Set Value" width:60 offset:[46,-4] align:#left  height:18
		
		button btn_ViewMatOff "Display Material" width:108 offset:[2,-4] align:#right  height:18
		button btn_ViewMatOn "Ignore Material" width:108 offset:[5,-4] align:#right   height:18
		
	)
	label lbl_placeholder05 "" offset:[0,-23]
	group "Miscellaneous"
	(
		button btn_ShellOn "Shell ON" width:108 offset:[-5,-3] align:#left across:4 height:18
		button btn_ShellOff "Shell OFF" width:108 offset:[-2,-3] align:#left height:18

		button btn_ShellOn2 "Shell ON" width:108 offset:[2,-3] align:#right visible:false height:18
		button btn_ShellOff2 "Shell OFF" width:108 offset:[5,-3] align:#right  visible:false height:18
		
		spinner spn_ShellStart "Shell Start:" fieldwidth:45 offset:[41,-3] range:[0,100000,0] align:#left type:#float across:4 
		button btn_ShellStart  "Set Value" width:60 offset:[46,-4] align:#left  height:18

		spinner spn_ShellEnd "Shell Thickness:" fieldwidth:45 offset:[50,-3]  range:[0,100000,1.0] align:#right type:#float 
		button btn_ShellEnd "Set Value" width:60 offset:[5,-4] align:#right  height:18
	)
	--groupbox lbl_massChangingUtility "Mass-Changing Utilities - Affect Highlighted PRT Volume Objects:" height:240 width:448 pos:[4,365] 
	
	fn registerSelectionCallback =
	(
		FranticParticles.LogDebug ("+PRT Volume Objects Rollout - Registering SELECTION Callback.")
		callbacks.addScript #selectionSetChanged "try(Krakatoa_GUI_PRTVolumeExplorer.synchSelectionFromScene())catch()" id:#Krakatoa_VolumeSelectionMonitor
	)
	
	fn registerSceneNodeCallbacks =
	(
		 FranticParticles.LogDebug ("+PRT Volume Rollout - Registering NODE Callbacks.")
		 callbacks.addScript #nodePostDelete "try(Krakatoa_GUI_PRTVolumeExplorer.nodesChanged())catch()" id:#Krakatoa_VolumeCreationDeletionMonitor
		 callbacks.addScript #nodeCreated "try(Krakatoa_GUI_PRTVolumeExplorer.nodesChanged())catch()" id:#Krakatoa_VolumeCreationDeletionMonitor
		 callbacks.addScript #nodeRenamed "try(Krakatoa_GUI_PRTVolumeExplorer.nodesChanged())catch()" id:#Krakatoa_VolumeCreationDeletionMonitor
		 callbacks.addScript #nodeHide "try(Krakatoa_GUI_PRTVolumeExplorer.nodesChanged())catch()" id:#Krakatoa_VolumeCreationDeletionMonitor
		 callbacks.addScript #nodeUnhide "try(Krakatoa_GUI_PRTVolumeExplorer.nodesChanged())catch()" id:#Krakatoa_VolumeCreationDeletionMonitor
		 if (maxVersion())[1] >=8000 do callbacks.addScript #sceneUndo "try(Krakatoa_GUI_PRTVolumeExplorer.nodesChanged())catch()" id:#Krakatoa_VolumeCreationDeletionMonitor
	)
	
	fn registerWhenConstructMonitor =
	(
		FranticParticles.LogDebug ("+PRT Volume Objects Rollout - Registering WHEN Callbacks.")
		deleteAllChangeHandlers id:#Krakatoa_VolumeParametersMonitor
		theBOs = for o in KrakatoaVolumeList collect o.baseobject --we have to monitor just the base objects to avoid updates on node PRS changes!
		when parameters theBOs change id:#Krakatoa_VolumeParametersMonitor do Krakatoa_GUI_PRTVolumeExplorer.nodesChanged()
	)
	
	fn synchSelectionToScene =
	(
		callbacks.removeScripts id:#Krakatoa_VolumeSelectionMonitor
		max select none
		select (for i in lbx_PRTVolumeInScene.selection where isValidNode KrakatoaVolumeList[i] collect KrakatoaVolumeList[i])
		registerSelectionCallback()
	)	
	
	fn synchSelectionFromScene =
	(
		lbx_PRTVolumeInScene.selection = (for o in selection where findItem KrakatoaVolumeList o > 0 collect findItem KrakatoaVolumeList o) as bitarray
	)	
	
	fn willThisObjectRender theObj =
	(
		local theLayer = theObj.layer 
		if not FranticParticles.GetBoolProperty "RenderGeometryVolumes" then "PRT Volumes are not enabled as particle source"
		else if not theObj.renderable then "Renderable Object Property is OFF" 
		else if not theObj.primaryVisibility then "Visible To Camera Object Property is OFF" 
		else if theObj.isHidden then "Object is Hidden"
		else if (theObj.isFrozen and maxOps.hideFrozenObjects) then "Frozen and Hide Frozen Objects is ON"
		else if not theLayer.on then "Layer is OFF"
		else if not theLayer.renderable then "Layer Renderable Property is OFF"
		else if theLayer.isHidden then "Layer is Hidden"
		else if not theLayer.primaryVisibility then "Layer Visible To Camera is OFF"
		else if not isValidNode theObj.TargetNode then "Source Object is Not Valid"
		else "OK"
	)	
	
	fn updateObjectssList =
	(
		--if Krakatoa_GUI_PRTVolumeExplorer.open do
		(
			KrakatoaVolumeList = for o in objects where classof o == PRT_Volume collect o
			lbx_PRTVolumeInScene.items = for o in KrakatoaVolumeList collect 
			(
				local txt = " "
				case ddl_displayInfo.selection of
				(
					1: ( 
						if isValidNode o.TargetNode then 
						(
							txt += " Source:[" + o.TargetNode.name + "]  "
							if o.parent == o.TargetNode then
							(
								if o.transform as string == o.targetNode.transform as string do txt+="Aligned And "
								txt += "Linked To Source "
							)
						)
						else
						(
							txt += " Source:<None>  "
						)
						
					)
					2: (
						local theMode = "???"
						txt+="Subd.:" +(if o.SubdivideEnabled then "ON" else "OFF")
						txt+="("+o.SubdivideCount as string+")"
						txt+=" Jitter:" +(if o.JitterSamples then if o.JitterWellDistributed then "WELL" else "ON" else "OFF")
						txt+=" Multiple:" + (if o.MultiplePerRegion then "ON" else "OFF")
						txt+= "("+o.MultiplePerRegionCount as string +")"
					)					
					3: (
						txt+= "Distinct Values:"+ o.RandomCount as string
						txt+= "  Random Seed:"+ o.RandomSeed as string
					)					
					4: (--view grid
						txt+= if o.ViewportEnabled then "View:ON  "  else "View:OFF  "
						txt+= if o.UseViewportVoxelLength then "Spacing:ON(" else "Spacing:OFF("
						txt+= o.ViewportVoxelLength as string + ")  "
						txt+= if o.ViewportDisableSubdivision then "View Subdiv.:ON" else "View Subdiv.:OFF" 
					)
					5: (--view limits
						txt+= if o.ViewportUsePercentage then "Percentage:ON("	else "Percentage:OFF("
						txt+= o.ViewportPercentage 	as string + ")"
						txt+= if o.ViewportUseLimit then "  Limit:ON("	else "  Limit:OFF("
						txt+= o.ViewportLimit 	as string + ")"
						txt+= if o.ViewportIgnoreMaterial then "  Ignore Material"	else "  Display Material"
					)
					6: (
						txt+= if o.useShell then "Shell:ON  " else "Shell:OFF  "
						txt+= "Start:" +o.ShellStart as string  + "  Thickness:"+ o.ShellThickness as string
					)
					7: (
						txt += willThisObjectRender o
					)
					default: (
					)			
				)	
				(if o.isHiddenInVpt then "--" else "+") + "["+o.name+"]"+ txt
			)	
			if chb_synchSelections.state do synchSelectionFromScene()
		)	
	)	
	

	
	fn nodesChanged =
	(
		if Krakatoa_GUI_PRTVolumeExplorer.open then
		(
			FranticParticles.LogDebug ("+PRT Volume Objects Rollout - NodesChanged Callback Executed.")
			updateObjectssList()
			registerWhenConstructMonitor()
		)
		else
			FranticParticles.LogDebug ("--PRT Volume Objects  Rollout - NodesChanged Callback SUPPRESSED - Rollout Not Open!")
	)		
	

	
	fn refresh_GUI =
	(
		updateObjectssList()
		
		/*if Krakatoa_Initializing_Hidden_Rollouts == false do 
			try(Krakatoa_GUI_PRTVolumeExplorer.open = FranticParticles.GetBoolProperty "GUI:PRTVolumeExplorerRolloutOpen")catch(Krakatoa_GUI_PRTVolumeExplorer.open=true)*/
	)
	
	on btn_AlignRPTVToSource pressed do
	(
		ddl_displayInfo.selection = 1
		for i in lbx_PRTVolumeInScene.selection do try(KrakatoaVolumeList[i].transform = KrakatoaVolumeList[i].TargetNode.transform)catch()	
		updateObjectssList()
	)
	
	on btn_AlignSourceToPRTV pressed do
	(
		ddl_displayInfo.selection = 1
		for i in lbx_PRTVolumeInScene.selection do try(KrakatoaVolumeList[i].TargetNode.transform = KrakatoaVolumeList[i].transform )catch()	
		updateObjectssList()
	)	
	on btn_ParentPRTVToSource pressed do
	(
		ddl_displayInfo.selection = 1
		for i in lbx_PRTVolumeInScene.selection do try(KrakatoaVolumeList[i].parent = KrakatoaVolumeList[i].TargetNode)catch()	
		updateObjectssList()
	)		
	on btn_UnparentPRTVFromSource pressed do
	(
		ddl_displayInfo.selection = 1
		for i in lbx_PRTVolumeInScene.selection do try(KrakatoaVolumeList[i].parent = undefined)catch()	
		updateObjectssList()
	)			
	
	on chb_synchSelections changed state do
	(
		refresh_GUI()
		if state do synchSelectionFromScene()
	)

	on lbx_PRTVolumeInScene doubleClicked itm do 
	(
		for i in lbx_PRTVolumeInScene.selection do 
			FranticParticles.LogProgress (lbx_PRTVolumeInScene.items[i])
	)		
	
	on lbx_PRTVolumeInScene selectionEnd do
	(
		if chb_synchSelections.state do synchSelectionToScene()
	)	
	

	on btn_createPRTVolume pressed do
	(
		macros.run "Krakatoa" "PRTVolume"
	)
	
	on btn_subdivideON pressed do
	(
		ddl_displayInfo.selection = 2
		for i in lbx_PRTVolumeInScene.selection do try(KrakatoaVolumeList[i].SubdivideEnabled = true)catch()	
	)	
	on btn_subdivideOFF pressed do
	(
		ddl_displayInfo.selection = 2
		for i in lbx_PRTVolumeInScene.selection do try(KrakatoaVolumeList[i].SubdivideEnabled = false)catch()	
	)	
	
	on btn_jitterON pressed do
	(
		ddl_displayInfo.selection = 2
		for i in lbx_PRTVolumeInScene.selection do try(KrakatoaVolumeList[i].JitterSamples = true)catch()	
	)	
	on btn_jitterOFF pressed do
	(
		ddl_displayInfo.selection = 2
		for i in lbx_PRTVolumeInScene.selection do try(KrakatoaVolumeList[i].JitterSamples = false)catch()	
	)		
	
	on btn_wellON pressed do
	(
		ddl_displayInfo.selection = 2
		for i in lbx_PRTVolumeInScene.selection do try(KrakatoaVolumeList[i].JitterWellDistributed = true)catch()	
	)	
	on btn_wellOFF pressed do
	(
		ddl_displayInfo.selection = 2
		for i in lbx_PRTVolumeInScene.selection do try(KrakatoaVolumeList[i].JitterWellDistributed = false)catch()	
	)		
	on btn_MultipleON pressed do
	(
		ddl_displayInfo.selection = 2
		for i in lbx_PRTVolumeInScene.selection do try(KrakatoaVolumeList[i].MultiplePerRegion = true)catch()	
	)	
	on btn_MultipleOFF pressed do
	(
		ddl_displayInfo.selection = 2
		for i in lbx_PRTVolumeInScene.selection do try(KrakatoaVolumeList[i].MultiplePerRegion = false)catch()	
	)		
	
	on btn_ViewOn pressed do
	(
		ddl_displayInfo.selection = 4
		for i in lbx_PRTVolumeInScene.selection do try(KrakatoaVolumeList[i].ViewportEnabled = on)catch()	
	)
	
	on btn_ViewOff pressed do
	(
		ddl_displayInfo.selection = 4
		for i in lbx_PRTVolumeInScene.selection do try(KrakatoaVolumeList[i].ViewportEnabled = off)catch()	
	)
	
	on btn_ViewSpacingOn pressed do
	(
		ddl_displayInfo.selection = 4
		for i in lbx_PRTVolumeInScene.selection do try(KrakatoaVolumeList[i].UseViewportVoxelLength = on)catch()	
	)
	
	on btn_ViewSpacingOff pressed do
	(
		ddl_displayInfo.selection = 4
		for i in lbx_PRTVolumeInScene.selection do try(KrakatoaVolumeList[i].UseViewportVoxelLength = off)catch()	
	)

	on btn_ViewPercentOn pressed do
	(
		ddl_displayInfo.selection = 5
		for i in lbx_PRTVolumeInScene.selection do try(KrakatoaVolumeList[i].ViewportUsePercentage = on)catch()	
	)
	on btn_ViewPercentOff pressed do
	(
		ddl_displayInfo.selection = 5
		for i in lbx_PRTVolumeInScene.selection do try(KrakatoaVolumeList[i].ViewportUsePercentage = off)catch()	
	)

	on btn_ViewLimitOn pressed do
	(
		ddl_displayInfo.selection = 5
		for i in lbx_PRTVolumeInScene.selection do try(KrakatoaVolumeList[i].ViewportUseLimit = on)catch()	
	)
	on btn_ViewLimitOff pressed do
	(
		ddl_displayInfo.selection = 5
		for i in lbx_PRTVolumeInScene.selection do try(KrakatoaVolumeList[i].ViewportUseLimit = off)catch()	
	)
	
	on btn_IconSize pressed do
	(
		ddl_displayInfo.selection = 4
		for i in lbx_PRTVolumeInScene.selection do try(KrakatoaVolumeList[i].IconSize= spn_IconSize.value)catch()	
	)	

	on btn_ViewMatOn pressed do
	(
		ddl_displayInfo.selection = 5
		for i in lbx_PRTVolumeInScene.selection do try(KrakatoaVolumeList[i].ViewportIgnoreMaterial = on)catch()	
	)
	on btn_ViewMatOff pressed do
	(
		ddl_displayInfo.selection = 5
		for i in lbx_PRTVolumeInScene.selection do try(KrakatoaVolumeList[i].ViewportIgnoreMaterial = off)catch()		
	)
	
	
	on btn_ViewSubdivOn pressed do
	(
		ddl_displayInfo.selection = 4
		for i in lbx_PRTVolumeInScene.selection do try(KrakatoaVolumeList[i].ViewportDisableSubdivision = off)catch()	
	)
	on btn_ViewSubdivOff pressed do
	(
		ddl_displayInfo.selection = 4
		for i in lbx_PRTVolumeInScene.selection do try(KrakatoaVolumeList[i].ViewportDisableSubdivision = on)catch()		
	)
	
	on btn_ShellOn pressed do
	(
		ddl_displayInfo.selection = 6
		for i in lbx_PRTVolumeInScene.selection do try(KrakatoaVolumeList[i].UseShell = on)catch()	
	)
	on btn_ShellOff pressed do
	(
		ddl_displayInfo.selection = 6
		for i in lbx_PRTVolumeInScene.selection do try(KrakatoaVolumeList[i].UseShell = off)catch()	
	)
	
	on btn_RenderSpacing pressed do
	(
		ddl_displayInfo.selection = 2
		for i in lbx_PRTVolumeInScene.selection do try(KrakatoaVolumeList[i].VoxelLength= spn_RenderSpacing.value)catch()	
	)
	
	on btn_ViewSpacing pressed do
	(
		ddl_displayInfo.selection = 4
		for i in lbx_PRTVolumeInScene.selection do try(KrakatoaVolumeList[i].ViewportVoxelLength= spn_ViewSpacing.value)catch()	
	)
	
	on btn_GridSubdivs pressed do
	(
		ddl_displayInfo.selection = 2
		for i in lbx_PRTVolumeInScene.selection do try(KrakatoaVolumeList[i].SubdivideCount= spn_GridSubdivs.value)catch()	
	)

	on btn_RandomSeed pressed do
	(
		ddl_displayInfo.selection = 3
		for i in lbx_PRTVolumeInScene.selection do try(KrakatoaVolumeList[i].RandomSeed = spn_RandomSeed.value)catch()	
	)

	on btn_RandomCount pressed do
	(
		ddl_displayInfo.selection = 3
		for i in lbx_PRTVolumeInScene.selection do try(KrakatoaVolumeList[i].RandomCount = spn_RandomCount.value)catch()	
	)
	
	on btn_RandomNumber pressed do
	(
		ddl_displayInfo.selection = 2
		for i in lbx_PRTVolumeInScene.selection do try(KrakatoaVolumeList[i].MultiplePerRegionCount = spn_RandomNumber.value)catch()	
	)

	on btn_ViewportPercent pressed do
	(
		ddl_displayInfo.selection = 5
		for i in lbx_PRTVolumeInScene.selection do try(KrakatoaVolumeList[i].ViewportPercentage = spn_ViewportPercent.value)catch()	
	)
	
	on btn_ViewportLimit pressed do
	(
		ddl_displayInfo.selection = 5
		for i in lbx_PRTVolumeInScene.selection do try(KrakatoaVolumeList[i].ViewportLimit = spn_ViewportLimit.value)catch()	
	)
	
	on btn_ShellStart pressed do
	(
		ddl_displayInfo.selection = 6
		for i in lbx_PRTVolumeInScene.selection do try(KrakatoaVolumeList[i].ShellStart = spn_ShellStart.value)catch()	
	)
	on btn_ShellEnd pressed do
	(
		ddl_displayInfo.selection = 6
		for i in lbx_PRTVolumeInScene.selection do try(KrakatoaVolumeList[i].ShellThickness = spn_ShellEnd.value)catch()	
	)

	on btn_selectAll pressed do
	(
		updateObjectssList()
		lbx_PRTVolumeInScene.selection = #{1..(lbx_PRTVolumeInScene.items.count)}
		if chb_synchSelections.state do synchSelectionToScene()
	)
	
	on btn_deselectAll pressed do
	(
		updateObjectssList()
		lbx_PRTVolumeInScene.selection = #{}
		if chb_synchSelections.state do synchSelectionToScene()
	)

	on btn_selectInvert pressed do
	(
		updateObjectssList()
		lbx_PRTVolumeInScene.selection = -lbx_PRTVolumeInScene.selection
		if chb_synchSelections.state do synchSelectionToScene()
	)	
	
	on btn_hideSelected pressed do
	(
		hide (for i in lbx_PRTVolumeInScene.selection collect KrakatoaVolumeList[i])
		updateObjectssList()
	)
	on btn_unhideSelected pressed do
	(
		unhide (for i in lbx_PRTVolumeInScene.selection collect KrakatoaVolumeList[i])
		updateObjectssList()
	)
	
	on btn_selectHidden pressed do
	(
		updateObjectssList()
		lbx_PRTVolumeInScene.selection = (for i = 1 to lbx_PRTVolumeInScene.items.count where KrakatoaVolumeList[i].isHiddenInVpt collect i)
		if chb_synchSelections.state do 
			select (for i = 1 to lbx_PRTVolumeInScene.items.count where KrakatoaVolumeList[i].isHiddenInVpt collect KrakatoaVolumeList[i])
	)			

	
	
	on ddl_displayInfo selected itm do updateObjectssList()


	on Krakatoa_GUI_PRTVolumeExplorer rolledUp val do 
	(
		try(FranticParticles.SetProperty "GUI:PRTVolumeExplorerRolloutOpen" val	)catch()
		if val then 
		(
			FranticParticles.LogDebug ("+Particle Loaders Rollout ROLLED DOWN.")
		)					
		else
			FranticParticles.LogDebug ("+Particle Loaders Rollout ROLLED UP.")	
	)			
		
	
	on Krakatoa_GUI_PRTVolumeExplorer close do 
	(
		Krakatoa_GUI_PRTVolumeExplorer.Refresh_GUI()
		
		 callbacks.removeScripts id:#Krakatoa_VolumeSelectionMonitor
		 callbacks.removeScripts id:#Krakatoa_VolumeCreationDeletionMonitor
		 deleteAllChangeHandlers id:#Krakatoa_VolumeParametersMonitor			
	)	
	
	fn updateIcons =
	(
	)	
	

	on Krakatoa_GUI_PRTVolumeExplorer open do 
	(
		updateIcons()
		Refresh_GUI()
		
		callbacks.removeScripts id:#Krakatoa_VolumeSelectionMonitor
		registerSelectionCallback()

		callbacks.removeScripts id:#Krakatoa_VolumeCreationDeletionMonitor
		registerSceneNodeCallbacks()
		 
		registerWhenConstructMonitor()				
		FranticParticles.LogDebug ("+PRT Volume Objects Rollout OPENED.")			
	)		
)

--------------------------------------------------------------------------------------------------------------------------------------------------------------------	
--PRT FUMEFX EXPLORER ROLLOUT
--------------------------------------------------------------------------------------------------------------------------------------------------------------------	
rollout Krakatoa_GUI_PRTFumeExplorer "PRT FumeFX Objects" category:300 width:457
(
	local KrakatoaFumeList = #()
	
	button btn_Help_Loaders  "Open Online Help..." width:450 height:16 align:#center offset:[0,-5] across:1 tooltip:"Opens the Krakatoa Online Help for the PRT FumeFX Objects rollout in the default Web Browser. Requires Internet connection."
	
	checkbutton chb_synchSelections ">Synch. Selection" across:3 width:144 align:#left checked:true offset:[-8,0] highlightcolor:KrakatoaSkinColorsStruct.Loaders tooltip:"When checked, selecting objects from the list will update the scene selection.\n\nWhen unchecked, the scene selection will not be synchronized to the list selection.\n\nHowever, selecting objects in the scene will always update the list's selection regardless of the state of this option."
	dropdownlist ddl_displayInfo items:#("FumeFX Source","Fire/Smoke Seeding","Region Seeding","Random Seed Settings","Viewport","Miscellaneous","Test Renderable State") width:154 align:#center offset:[2,0] tooltip:"Display the following PRT FumeFX properties..."
	button btn_createPRTFumeFX "Create PRT FumeFX..." width:144 align:#right offset:[10,0] tooltip:"Create a PRT FumeFX from selected Simulations. If no Simulations are selected, create at origin. If SHIFT pressed, create manually."
	
	multilistbox lbx_PRTFumeFXInScene height:12 width:450 align:#center offset:[0,-5]
	
	button btn_selectAll "Select All Objects" width:148 align:#left across:3 offset:[-10,-5]
	button btn_deselectAll "Deselect All Objects" width:149 align:#center offset:[0,-5]
	button btn_selectInvert "Invert Objects Selection" width:148 align:#right offset:[10,-5]
	
	button btn_hideSelected "Hide Selected Objects" width:148 align:#left across:3 offset:[-10,-3]
	button btn_unhideSelected "Unhide Selected Objects" width:149 align:#center offset:[0,-3]
	button btn_selectHidden "Select Hidden Objects" width:148 align:#right offset:[10,-3]

	--label lbl_placeholder01 ""
	
	group "Seeding"
	(
		button btn_seedInSmokeON "Seed In Smoke ON" width:108 offset:[-5,-5] align:#left   across:4
		button btn_seedInSmokeOFF "Seed In Smoke OFF" width:108 offset:[-2,-5] align:#left 
		button btn_seedInFireON "Seed In Fire ON" width:108 offset:[2,-5] align:#right  
		button btn_seedInFireOFF "Seed In Fire OFF" width:108 offset:[5,-5] align:#right 
		
		spinner spn_smokeDensityMinimum "Seed In Smoke Min.:" fieldwidth:40 offset:[0,0] range:[0,1,0] scale:0.01 align:#left across:4 
		button btn_smokeDensityMinimum "Set Value" width:60 offset:[46,-3] align:#left

		spinner spn_FireDensityMinimum "Seed In Fire Min.:" fieldwidth:40 offset:[50,0] range:[0,1,0] scale:0.01 align:#right 
		button btn_FireDensityMinimum "Set Value" width:60 offset:[5,-3] align:#right	
	)
	group "Grid"
	(
		button btn_subdivideON "Subdivide ON" width:108 offset:[-5,-5] align:#left   across:4
		button btn_subdivideOFF "Subdivide OFF" width:108 offset:[-2,-5] align:#left 
		button btn_jitterON "Jitter ON" width:108 offset:[2,-5] align:#right  
		button btn_jitterOFF "Jitter OFF" width:108 offset:[5,-5] align:#right 

		button btn_wellON "Well Distributed ON" width:108 offset:[-5,-3] align:#left   across:4
		button btn_wellOFF "Well Distributed OFF" width:108 offset:[-2,-3] align:#left 
		button btn_MultipleON "Multiple ON" width:108 offset:[2,-3] align:#right  
		button btn_MultipleOFF "Multiple OFF" width:108 offset:[5,-3] align:#right 
			
		spinner spn_GridSubdivs "Subdivisons:" fieldwidth:45 offset:[35,0] range:[1,10,1] align:#left type:#integer across:4
		button btn_GridSubdivs "Set Value" width:60 offset:[46,-3] align:#left

		spinner spn_RandomNumber "Multi/Region:" fieldwidth:45 offset:[50,0] range:[2,1000,1] align:#right type:#integer
		button btn_RandomNumber "Set Value" width:60 offset:[5,-3] align:#right
		spinner spn_RandomSeed "Random Seed:" fieldwidth:45 offset:[25,0]  range:[1,100000,42] align:#left type:#integer across:4
		button btn_RandomSeed "Set Value" width:60 offset:[46,-3] align:#left

		spinner spn_RandomCount "Random Count:" fieldwidth:45 offset:[50,0] range:[1,4096,1024] align:#right type:#integer 
		button btn_RandomCount "Set Value" width:60 offset:[5,-3] align:#right	
	)
	
	group "Viewport"
	(
		button btn_enableON "Enable In Viewport" width:108 offset:[-5,-5] align:#left   across:4
		button btn_enableOFF "Disable In Viewport" width:108 offset:[-2,-5] align:#left 
		button btn_seedMultipleInViewON "Disable Subdivisions" width:108 offset:[2,-5] align:#right  
		button btn_seedMultipleInViewOFF "Enable Subdivisions" width:108 offset:[5,-5] align:#right 
		
		button btn_percentageON "Percentage ON" width:108 offset:[-5,-3] align:#left   across:4
		button btn_percentageOFF "Percentage OFF" width:108 offset:[-2,-3] align:#left 
		spinner spn_Percentage "Percentage:" fieldwidth:45 offset:[50,0] range:[0,100,1] align:#right type:#float
		button btn_Percentage  "Set Value" width:60 offset:[5,-3] align:#right		

		button btn_limitON "Limit ON" width:108 offset:[-5,-3] align:#left   across:4
		button btn_limitOFF "Limit OFF" width:108 offset:[-2,-3] align:#left 
		spinner spn_limit "Limit (x1000):" fieldwidth:45 offset:[50,0] range:[0,10000,1000] align:#right type:#float
		button btn_limit "Set Value" width:60 offset:[5,-3] align:#right		
		
		button btn_materialON "Display Material" width:108 offset:[-5,-3] align:#left   across:4
		button btn_materialOFF "Ignore Material" width:108 offset:[-2,-3] align:#left 
		
		spinner spn_iconSize "Icon Size:" fieldwidth:45 offset:[50,0] range:[0,100000,100] align:#right type:#float
		button btn_iconSize "Set Value" width:60 offset:[5,-3] align:#right		
	)
	
	group "Miscellaneous"
	(
		button btn_noVelocityON "Disable Velocity" width:108 offset:[-5,-3] align:#left   across:4
		button btn_noVelocityOFF "Enable Velocity" width:108 offset:[-2,-3] align:#left 
		
		button btn_normalsON "Normals ON" width:108 offset:[2,-3] align:#right  
		button btn_normalsOFF "Normals OFF" width:108 offset:[5,-3] align:#right 
		
		button btn_emissionON "Emission ON" width:108 offset:[-5,-3] align:#left   across:4
		button btn_emissionOFF "Emission OFF" width:108 offset:[-2,-3] align:#left 
		spinner spn_emissionMulti "Emission Multiplier:" fieldwidth:40 offset:[50,0] range:[0,100000,100] align:#right type:#float
		button btn_emissionMulti  "Set Value" width:60 offset:[5,-3] align:#right			
	)
	--groupbox lbl_massChangingUtility "Mass-Changing Utilities - Affect Highlighted PRT FumeFX Objects:" height:230 width:448 pos:[4,365] 
	
	fn registerSelectionCallback =
	(
		FranticParticles.LogDebug ("+PRT FumeFX Objects Rollout - Registering SELECTION Callback.")
		callbacks.addScript #selectionSetChanged "try(Krakatoa_GUI_PRTFumeExplorer.synchSelectionFromScene())catch()" id:#Krakatoa_FumeFXSelectionMonitor
	)
	
	fn registerSceneNodeCallbacks =
	(
		 FranticParticles.LogDebug ("+PRT FumeFX Rollout - Registering NODE Callbacks.")
		 callbacks.addScript #nodePostDelete "try(Krakatoa_GUI_PRTFumeExplorer.nodesChanged())catch()" id:#Krakatoa_FumeFXCreationDeletionMonitor
		 callbacks.addScript #nodeCreated "try(Krakatoa_GUI_PRTFumeExplorer.nodesChanged())catch()" id:#Krakatoa_FumeFXCreationDeletionMonitor
		 callbacks.addScript #nodeRenamed "try(Krakatoa_GUI_PRTFumeExplorer.nodesChanged())catch()" id:#Krakatoa_FumeFXCreationDeletionMonitor
		 callbacks.addScript #nodeHide "try(Krakatoa_GUI_PRTFumeExplorer.nodesChanged())catch()" id:#Krakatoa_FumeFXCreationDeletionMonitor
		 callbacks.addScript #nodeUnhide "try(Krakatoa_GUI_PRTFumeExplorer.nodesChanged())catch()" id:#Krakatoa_FumeFXCreationDeletionMonitor
		 if (maxVersion())[1] >=8000 do callbacks.addScript #sceneUndo "try(Krakatoa_GUI_PRTFumeExplorer.nodesChanged())catch()" id:#Krakatoa_FumeFXCreationDeletionMonitor
	)
	
	fn registerWhenConstructMonitor =
	(
		FranticParticles.LogDebug ("+PRT FumeFX Objects Rollout - Registering WHEN Callbacks.")
		deleteAllChangeHandlers id:#Krakatoa_FumeFXParametersMonitor
		theBOs = for o in KrakatoaFumeList collect o.baseobject --we have to monitor just the base objects to avoid updates on node PRS changes!
		when parameters theBOs change id:#Krakatoa_FumeFXParametersMonitor do Krakatoa_GUI_PRTFumeExplorer.nodesChanged()
	)
	
	fn synchSelectionToScene =
	(
		callbacks.removeScripts id:#Krakatoa_FumeFXSelectionMonitor
		max select none
		select (for i in lbx_PRTFumeFXInScene.selection where isValidNode KrakatoaFumeList[i] collect KrakatoaFumeList[i])
		registerSelectionCallback()
	)	
	
	fn synchSelectionFromScene =
	(
		lbx_PRTFumeFXInScene.selection = (for o in selection where findItem KrakatoaFumeList o > 0 collect findItem KrakatoaFumeList o) as bitarray
	)	
	
	fn willThisObjectRender theObj =
	(
		local theLayer = theObj.layer 
		if not FranticParticles.GetBoolProperty "RenderFumeFX" then "PRT FumeFX objects are not enabled as particle source"
		else if not theObj.renderable then "Renderable Object Property is OFF" 
		else if not theObj.primaryVisibility then "Visible To Camera Object Property is OFF" 
		else if theObj.isHidden then "Object is Hidden"
		else if (theObj.isFrozen and maxOps.hideFrozenObjects) then "Frozen and Hide Frozen Objects is ON"
		else if not theLayer.on then "Layer is OFF"
		else if not theLayer.renderable then "Layer Renderable Property is OFF"
		else if theLayer.isHidden then "Layer is Hidden"
		else if not theLayer.primaryVisibility then "Layer Visible To Camera is OFF"
		else if not isValidNode theObj.TargetNode then "Source Object is Not Valid"
		else if not theObj.SeedInSmoke and not theObj.SeedInFire then "Both Seed In Smoke and Seed In Fire are OFF"
		else "OK"
	)		
	
	fn updateObjectssList =
	(
		--if Krakatoa_GUI_PRTFumeExplorer.open do
		(
			KrakatoaFumeList = for o in objects where classof o == PRT_FumeFX collect o
			lbx_PRTFumeFXInScene.items = for o in KrakatoaFumeList collect 
			(
				local txt = " "
				case ddl_displayInfo.selection of
				(
					1: ( 
						txt += if isValidNode o.TargetNode then 
								" Source:[" + o.TargetNode.name + "]"
							else
								" Source:<None>"
					)
					2:(
						txt += "  Seed In Smoke:"+ (if o.SeedInSmoke then "ON" else "OFF") +"  Min.:"+o.SeedInSmokeMinimum as string
						txt += "  Seed In Fire:"+ (if o.SeedInFire then "ON" else "OFF")+" Min.:"+o.SeedInFireMinimum as string
					)
					3: (
						local theMode = "???"
						txt+="Subd.:" +(if o.SubdivideEnabled then "ON" else "OFF")
						txt+="("+o.SubdivideCount as string+")"
						txt+=" Jitter:" +(if o.JitterSamples then if o.JitterWellDistributed then "WELL" else "ON" else "OFF")
						txt+=" Multiple:" + (if o.MultiplePerRegion then "ON" else "OFF")
						txt+= "("+o.MultiplePerRegionCount as string +")"
					)
					4: (
						txt+= "Distinct Values:"+ o.RandomCount as string
						txt+= "  Random Seed:"+ o.RandomSeed as string
					)						
					5: (
						txt += "View:" + (if o.ViewportEnabled then "ON" else "OFF")
						txt += " SubD:"+ (if o.ViewportDisableSubdivision then "OFF" else "ON")
						txt += " %:" + (if o.ViewportUsePercentage then "ON" else "OFF")
						txt += "(" + o.ViewportPercentage as string + "%)"	
						txt += " Lmt:" + (if o.ViewportUseLimit then "ON" else "OFF")
						txt += "("+o.ViewportLimit as string +")"
						txt += " NoMat:"+ (if o.ViewportIgnoreMaterial then "ON" else "OFF")
					)
					6: (
						txt += "  Velocity:" + (if o.DisableVelocity then "OFF" else "ON")
						txt += "  Normal:" + (if o.GenerateNormal then "ON" else "OFF")
						txt += "  Emission:" + (if o.GenerateEmission then "ON" else "OFF")
						txt += "  ("+o.EmissionMultiplier as string+")" 
					)
					7: (
						txt += willThisObjectRender o
					)
					default: (
					)			
				)	
				(if o.isHiddenInVpt then "--" else "+") + "["+o.name+"]"+ txt
			)	
			if chb_synchSelections.state do synchSelectionFromScene()
		)	
	)	
	

	
	fn nodesChanged =
	(
		if Krakatoa_GUI_PRTFumeExplorer.open then
		(
			FranticParticles.LogDebug ("+PRT FumeFX Objects Rollout - NodesChanged Callback Executed.")
			updateObjectssList()
			registerWhenConstructMonitor()
		)
		else
			FranticParticles.LogDebug ("--PRT FumeFX Objects  Rollout - NodesChanged Callback SUPPRESSED - Rollout Not Open!")
	)		
	

	
	fn refresh_GUI =
	(
		updateObjectssList()
		
		/*if Krakatoa_Initializing_Hidden_Rollouts == false do 
			try(Krakatoa_GUI_PRTFumeExplorer.open = FranticParticles.GetBoolProperty "GUI:PRTFumeFXExplorerRolloutOpen")catch()*/
	)
	
	on chb_synchSelections changed state do
	(
		refresh_GUI()
		if state do synchSelectionFromScene()
	)

	on lbx_PRTFumeFXInScene doubleClicked itm do 
	(
		for i in lbx_PRTFumeFXInScene.selection do 
			FranticParticles.LogProgress (lbx_PRTFumeFXInScene.items[i])
	)		
	
	on lbx_PRTFumeFXInScene selectionEnd do
	(
		if chb_synchSelections.state do synchSelectionToScene()
	)	
	

	on btn_createPRTFumeFX pressed do
	(
		macros.run "Krakatoa" "PRTFumeFX"
	)



	on btn_subdivideON pressed do
	(
		ddl_displayInfo.selection = 3
		for i in lbx_PRTFumeFXInScene.selection do try(KrakatoaFumeList[i].SubdivideEnabled = true)catch()	
	)	
	on btn_subdivideOFF pressed do
	(
		ddl_displayInfo.selection = 3
		for i in lbx_PRTFumeFXInScene.selection do try(KrakatoaFumeList[i].SubdivideEnabled = false)catch()	
	)	
	
	on btn_jitterON pressed do
	(
		ddl_displayInfo.selection = 3
		for i in lbx_PRTFumeFXInScene.selection do try(KrakatoaFumeList[i].JitterSamples = true)catch()	
	)	
	on btn_jitterOFF pressed do
	(
		ddl_displayInfo.selection = 3
		for i in lbx_PRTFumeFXInScene.selection do try(KrakatoaFumeList[i].JitterSamples = false)catch()	
	)		
	
	on btn_wellON pressed do
	(
		ddl_displayInfo.selection = 3
		for i in lbx_PRTFumeFXInScene.selection do try(KrakatoaFumeList[i].JitterWellDistributed = true)catch()	
	)	
	on btn_wellOFF pressed do
	(
		ddl_displayInfo.selection = 3
		for i in lbx_PRTFumeFXInScene.selection do try(KrakatoaFumeList[i].JitterWellDistributed = false)catch()	
	)		
	on btn_MultipleON pressed do
	(
		ddl_displayInfo.selection = 3
		for i in lbx_PRTFumeFXInScene.selection do try(KrakatoaFumeList[i].MultiplePerRegion = true)catch()	
	)	
	on btn_MultipleOFF pressed do
	(
		ddl_displayInfo.selection = 3
		for i in lbx_PRTFumeFXInScene.selection do try(KrakatoaFumeList[i].MultiplePerRegion = false)catch()	
	)		
	
	on btn_enableON pressed do
	(
		ddl_displayInfo.selection = 5
		for i in lbx_PRTFumeFXInScene.selection do try(KrakatoaFumeList[i].ViewportEnabled = true)catch()	
	)
	on btn_enableOFF pressed do
	(
		ddl_displayInfo.selection = 5
		for i in lbx_PRTFumeFXInScene.selection do try(KrakatoaFumeList[i].ViewportEnabled = false)catch()	
	)	
	on btn_percentageON pressed do
	(
		ddl_displayInfo.selection = 5
		for i in lbx_PRTFumeFXInScene.selection do try(KrakatoaFumeList[i].ViewportUsePercentage = true)catch()	
	)
	on btn_percentageOFF pressed do
	(
		ddl_displayInfo.selection = 5
		for i in lbx_PRTFumeFXInScene.selection do try(KrakatoaFumeList[i].ViewportUsePercentage = false)catch()	
	)		
	on btn_limitON pressed do
	(
		ddl_displayInfo.selection = 5
		for i in lbx_PRTFumeFXInScene.selection do try(KrakatoaFumeList[i].ViewportUseLimit = true)catch()	
	)
	on btn_limitOFF pressed do
	(
		ddl_displayInfo.selection = 5
		for i in lbx_PRTFumeFXInScene.selection do try(KrakatoaFumeList[i].ViewportUseLimit = false)catch()	
	)		
	on btn_materialON pressed do
	(
		ddl_displayInfo.selection = 5
		for i in lbx_PRTFumeFXInScene.selection do try(KrakatoaFumeList[i].ViewportIgnoreMaterial = false)catch()	
	)
	on btn_materialOFF pressed do
	(
		ddl_displayInfo.selection = 5
		for i in lbx_PRTFumeFXInScene.selection do try(KrakatoaFumeList[i].ViewportIgnoreMaterial = true)catch()	
	)		
	
	on btn_iconSize pressed do
	(
		ddl_displayInfo.selection = 5
		for i in lbx_PRTFumeFXInScene.selection do try(KrakatoaFumeList[i].iconSize = spn_iconSize.value)catch()	
	)		
	
	on btn_seedMultipleInViewON pressed do
	(
		ddl_displayInfo.selection = 5
		for i in lbx_PRTFumeFXInScene.selection do try(KrakatoaFumeList[i].ViewportDisableSubdivision = false)catch()	
	)
	on btn_seedMultipleInViewOFF pressed do
	(
		ddl_displayInfo.selection = 5
		for i in lbx_PRTFumeFXInScene.selection do try(KrakatoaFumeList[i].ViewportDisableSubdivision = true)catch()	
	)	
	
	on btn_noVelocityON pressed do
	(
		ddl_displayInfo.selection = 6
		for i in lbx_PRTFumeFXInScene.selection do try(KrakatoaFumeList[i].DisableVelocity = true)catch()	
	)
	on btn_noVelocityOFF pressed do
	(
		ddl_displayInfo.selection = 6
		for i in lbx_PRTFumeFXInScene.selection do try(KrakatoaFumeList[i].DisableVelocity = false)catch()	
	)

	on btn_emissionON pressed do
	(
		ddl_displayInfo.selection = 6
		for i in lbx_PRTFumeFXInScene.selection do try(KrakatoaFumeList[i].GenerateEmission = true)catch()	
	)
	on btn_emissionOFF pressed do
	(
		ddl_displayInfo.selection = 6
		for i in lbx_PRTFumeFXInScene.selection do try(KrakatoaFumeList[i].GenerateEmission = false)catch()	
	)	
	
	on btn_normalsON pressed do
	(
		ddl_displayInfo.selection = 6
		for i in lbx_PRTFumeFXInScene.selection do try(KrakatoaFumeList[i].GenerateNormal = true)catch()	
	)
	on btn_normalsOFF pressed do
	(
		ddl_displayInfo.selection = 6
		for i in lbx_PRTFumeFXInScene.selection do try(KrakatoaFumeList[i].GenerateNormal = false)catch()	
	)		
	
	
	on btn_seedInSmokeON pressed do
	(
		ddl_displayInfo.selection = 2
		for i in lbx_PRTFumeFXInScene.selection do try(KrakatoaFumeList[i].SeedInSmoke = true)catch()	
	)
	on btn_seedInSmokeOFF pressed do
	(
		ddl_displayInfo.selection = 2
		for i in lbx_PRTFumeFXInScene.selection do try(KrakatoaFumeList[i].SeedInSmoke = false)catch()	
	)		
	
	on btn_seedInFireON pressed do
	(
		ddl_displayInfo.selection = 2
		for i in lbx_PRTFumeFXInScene.selection do try(KrakatoaFumeList[i].SeedInFire = true)catch()	
	)
	on btn_seedInFireOFF pressed do
	(
		ddl_displayInfo.selection = 2
		for i in lbx_PRTFumeFXInScene.selection do try(KrakatoaFumeList[i].SeedInFire = false)catch()	
	)		
	


	on btn_GridSubdivs pressed do
	(
		ddl_displayInfo.selection = 2
		for i in lbx_PRTFumeFXInScene.selection do try(KrakatoaFumeList[i].SubdivideCount = spn_GridSubdivs.value)catch()	
	)
	on btn_RandomNumber pressed do
	(
		ddl_displayInfo.selection = 2
		for i in lbx_PRTFumeFXInScene.selection do try(KrakatoaFumeList[i].MultiplePerRegionCount = spn_RandomNumber.value)catch()	
	)
		
	
	
	on btn_RandomSeed pressed do
	(
		ddl_displayInfo.selection = 4
		for i in lbx_PRTFumeFXInScene.selection do try(KrakatoaFumeList[i].RandomSeed = spn_RandomSeed.value)catch()	
	)

	on btn_RandomCount pressed do
	(
		ddl_displayInfo.selection = 4
		for i in lbx_PRTFumeFXInScene.selection do try(KrakatoaFumeList[i].RandomCount = spn_RandomCount.value)catch()	
	)

	on btn_emissionMulti pressed do
	(
		ddl_displayInfo.selection = 6
		for i in lbx_PRTFumeFXInScene.selection do try(KrakatoaFumeList[i].EmissionMultiplier = spn_emissionMulti.value)catch()	
	)	


	on btn_Percentage pressed do
	(
		ddl_displayInfo.selection = 5
		for i in lbx_PRTFumeFXInScene.selection do try(KrakatoaFumeList[i].ViewportPercentage = spn_Percentage.value)catch()	
	)		
	
	on btn_limit pressed do
	(
		ddl_displayInfo.selection = 5
		for i in lbx_PRTFumeFXInScene.selection do try(KrakatoaFumeList[i].ViewportLimit = spn_limit.value)catch()	
	)		
		
	
	
	on btn_smokeDensityMinimum pressed do
	(
		ddl_displayInfo.selection = 2
		for i in lbx_PRTFumeFXInScene.selection do try(KrakatoaFumeList[i].SeedInSmokeMinimum = spn_smokeDensityMinimum.value)catch()	
	)
	on btn_fireDensityMinimum pressed do
	(
		ddl_displayInfo.selection = 2
		for i in lbx_PRTFumeFXInScene.selection do try(KrakatoaFumeList[i].SeedInFireMinimum = spn_fireDensityMinimum.value)catch()	
	)

	on btn_selectAll pressed do
	(
		updateObjectssList()
		lbx_PRTFumeFXInScene.selection = #{1..(lbx_PRTFumeFXInScene.items.count)}
		if chb_synchSelections.state do synchSelectionToScene()
	)
	
	on btn_deselectAll pressed do
	(
		updateObjectssList()
		lbx_PRTFumeFXInScene.selection = #{}
		if chb_synchSelections.state do synchSelectionToScene()
	)

	on btn_selectInvert pressed do
	(
		updateObjectssList()
		lbx_PRTFumeFXInScene.selection = -lbx_PRTFumeFXInScene.selection
		if chb_synchSelections.state do synchSelectionToScene()
	)	
	
	on btn_hideSelected pressed do
	(
		hide (for i in lbx_PRTFumeFXInScene.selection collect KrakatoaFumeList[i])
		updateObjectssList()
	)
	on btn_unhideSelected pressed do
	(
		unhide (for i in lbx_PRTFumeFXInScene.selection collect KrakatoaFumeList[i])
		updateObjectssList()
	)
	
	on btn_selectHidden pressed do
	(
		updateObjectssList()
		lbx_PRTFumeFXInScene.selection = (for i = 1 to lbx_PRTFumeFXInScene.items.count where KrakatoaFumeList[i].isHiddenInVpt collect i)
		if chb_synchSelections.state do 
			select (for i = 1 to lbx_PRTFumeFXInScene.items.count where KrakatoaFumeList[i].isHiddenInVpt collect KrakatoaFumeList[i])
	)			

	
	
	on ddl_displayInfo selected itm do updateObjectssList()


	on Krakatoa_GUI_PRTFumeExplorer rolledUp val do 
	(
		/*
		FranticParticles.SetProperty "GUI:PRTFumeFXExplorerRolloutOpen" val		
		if val then 
		(
			FranticParticles.LogDebug ("+Particle Loaders Rollout ROLLED DOWN.")
		)					
		else
			FranticParticles.LogDebug ("+Particle Loaders Rollout ROLLED UP.")	
		*/
	)			
		
	
	on Krakatoa_GUI_PRTFumeExplorer close do 
	(
		Krakatoa_GUI_PRTFumeExplorer.Refresh_GUI()
		
		 callbacks.removeScripts id:#Krakatoa_FumeFXSelectionMonitor
		 callbacks.removeScripts id:#Krakatoa_FumeFXCreationDeletionMonitor
		 deleteAllChangeHandlers id:#Krakatoa_FumeFXParametersMonitor			
	)	
	
	fn updateIcons =
	(
	)	
	

	on Krakatoa_GUI_PRTFumeExplorer open do 
	(
		updateIcons()
		Refresh_GUI()
		
		callbacks.removeScripts id:#Krakatoa_FumeFXSelectionMonitor
		registerSelectionCallback()

		callbacks.removeScripts id:#Krakatoa_FumeFXCreationDeletionMonitor
		registerSceneNodeCallbacks()
		 
		registerWhenConstructMonitor()				
		FranticParticles.LogDebug ("+PRT FumeFX Objects Rollout OPENED.")			
	)		
)


--------------------------------------------------------------------------------------------------------------------------------------------------------------------	
--PRT HAIR EXPLORER ROLLOUT
--------------------------------------------------------------------------------------------------------------------------------------------------------------------	
rollout Krakatoa_GUI_PRTHairExplorer "PRT Hair Objects" category:400 width:457
(
	
	local KrakatoaHairList = #()
	
	button btn_Help_Loaders  "Open Online Help..." width:450 height:16 align:#center offset:[0,-5] across:1 tooltip:"Opens the Krakatoa Online Help for the PRT Hair rollout in the default Web Browser. Requires Internet connection."
	
	checkbutton chb_synchSelections ">Synch. Selection" across:3 width:144 align:#left checked:true offset:[-8,0] highlightcolor:KrakatoaSkinColorsStruct.Loaders tooltip:"When checked, selecting objects from the list will update the scene selection.\n\nWhen unchecked, the scene selection will not be synchronized to the list selection.\n\nHowever, selecting objects in the scene will always update the list's selection regardless of the state of this option."
	dropdownlist ddl_displayInfo items:#("Hair Source","Render Settings","Viewport Settings","Reference Position") width:154 align:#center offset:[2,0] tooltip:"Display the following PRT Hair properties..."
	button btn_createPRTHair "Create PRT Hair..." width:144 align:#right offset:[10,0] tooltip:"Create a PRT Hair from selected Splines. If no Splines are selected, create at origin. If SHIFT pressed, create manually."
	
	multilistbox lbx_PRTHairsInScene height:20 width:450 align:#center offset:[0,-3]
	
	button btn_selectAll "Select All Objects" width:148 align:#left across:3 offset:[-10,-3]
	button btn_deselectAll "Deselect All Objects" width:149 align:#center offset:[0,-3]
	button btn_selectInvert "Invert Objects Selection" width:148 align:#right offset:[10,-3]
	
	button btn_hideSelected "Hide Selected Objects" width:148 align:#left across:3 offset:[-10,-3]
	button btn_unhideSelected "Unhide Selected Objects" width:149 align:#center offset:[0,-3]
	button btn_selectHidden "Select Hidden Objects" width:148 align:#right offset:[10,-3]
	
	label lbl_placeholder01 ""
	label lbl_placeholder02 ""	
	
	spinner spn_renderSpacing "Render Spacing:" range:[0.0001,10000, 0.1] fieldwidth:40 align:#left across:4 offset:[19,-6]
	button btn_renderSpacing "Set Value" width:60 align:#center offset:[20,-9]
	
	spinner spn_viewSpacing "View Spacing:" range:[0.001,10000,1] fieldwidth:40 align:#right offset:[50,-6]
	button btn_viewSpacing "Set Value" width:60 align:#right  offset:[4,-9]
	
	spinner spn_PixelSpacing "Pixel Spacing:" range:[0.001,5,0.5] fieldwidth:40 align:#left across:4 offset:[32,0]
	button btn_PixelSpacing "Set Value" width:60 align:#center   offset:[20,-3]
	
	spinner spn_viewLimit "View Hair Limit:" range:[1,10000,1000] type:#integer fieldwidth:40 align:#right offset:[50,0]
	button btn_viewLimit "Set Value" width:60 align:#right  offset:[4,-3]
	
	button btn_enableRenderViewAdaptive "Rend. Adaptive ON" width:106 align:#left across:4 offset:[-5,-3]
	button btn_disableRenderViewAdaptive "Rend. Adaptive OFF" width:106 align:#center offset:[-3,-3]
	button btn_enableViewportViewAdaptive "View Adaptive ON" width:106 align:#center offset:[5,-3]
	button btn_disableViewportViewAdaptive  "View Adaptive OFF" width:106 align:#right offset:[5,-3]
	
	button btn_enableRefPosition "Reference Pos. ON" width:106 align:#left across:4 offset:[-5,6]
	button btn_disableRefPosition "Reference Pos. OFF" width:106 align:#center offset:[-3,6]
	
	spinner spn_referenceFrame "Reference Frame:" range:[-100000,1000000,0] type:#integer fieldwidth:40 align:#right offset:[50,9]
	button btn_referenceFrame "Set Value" width:60 align:#right  offset:[4,6]

	dropdownlist ddl_sceneCameras "" items:#() width:215 offset:[-5,0] across:2
	button btn_assignCameraToSelected "Assign Camera To Highlighted PRT Hairs" width:215 align:#right offset:[2,0]
	
	dropdownlist ddl_displayMode "" items:#("Points","Tangents") width:215 offset:[-5,0] across:2
	button btn_displayMode "Set Display Mode Of Highlighted PRT Hairs" width:215 align:#right offset:[2,0]
	
	groupbox grp_renderModes "Render:" width:225 height:85 pos:[3,380] across:2 
	groupbox grp_viewportModes "Viewport:" width:223 height:85 pos:[227,380] 
	groupbox lbl_massChangingUtility "Mass-Changing Utilities - Affect Highlighted PRT Hair Objects:" height:185 width:448 pos:[3,365] 
	
	fn registerSelectionCallback =
	(
		FranticParticles.LogDebug ("+Particle Loaders Rollout - Registering SELECTION Callback.")
		callbacks.addScript #selectionSetChanged "try(Krakatoa_GUI_PRTHairExplorer.synchSelectionFromScene())catch()" id:#Krakatoa_HairSelectionMonitor
	)
	
	fn registerSceneNodeCallbacks =
	(
		 FranticParticles.LogDebug ("+PRT Hair Rollout - Registering NODE Callbacks.")
		 callbacks.addScript #nodePostDelete "try(Krakatoa_GUI_PRTHairExplorer.nodesChanged())catch()" id:#Krakatoa_HairCreationDeletionMonitor
		 callbacks.addScript #nodeCreated "try(Krakatoa_GUI_PRTHairExplorer.nodesChanged())catch()" id:#Krakatoa_HairCreationDeletionMonitor
		 callbacks.addScript #nodeRenamed "try(Krakatoa_GUI_PRTHairExplorer.nodesChanged())catch()" id:#Krakatoa_HairCreationDeletionMonitor
		 callbacks.addScript #nodeHide "try(Krakatoa_GUI_PRTHairExplorer.nodesChanged())catch()" id:#Krakatoa_HairCreationDeletionMonitor
		 callbacks.addScript #nodeUnhide "try(Krakatoa_GUI_PRTHairExplorer.nodesChanged())catch()" id:#Krakatoa_HairCreationDeletionMonitor
		 if (maxVersion())[1] >=8000 do callbacks.addScript #sceneUndo "try(Krakatoa_GUI_PRTHairExplorer.nodesChanged())catch()" id:#Krakatoa_HairCreationDeletionMonitor
	)
	
	fn registerWhenConstructMonitor =
	(
		FranticParticles.LogDebug ("+PRT Hair Rollout - Registering WHEN Callbacks.")
		deleteAllChangeHandlers id:#Krakatoa_HairParametersMonitor
		theBOs = for o in KrakatoaHairList collect o.baseobject --we have to monitor just the base objects to avoid updates on node PRS changes!
		when parameters theBOs change id:#Krakatoa_HairParametersMonitor do Krakatoa_GUI_PRTHairExplorer.nodesChanged()
	)
	
	fn synchSelectionToScene =
	(
		callbacks.removeScripts id:#Krakatoa_HairSelectionMonitor
		max select none
		select (for i in lbx_PRTHairsInScene.selection where isValidNode KrakatoaHairList[i] collect KrakatoaHairList[i])
		registerSelectionCallback()
	)	
	
	fn synchSelectionFromScene =
	(
		lbx_PRTHairsInScene.selection = (for o in selection where findItem KrakatoaHairList o > 0 collect findItem KrakatoaHairList o) as bitarray
	)	
	
	fn updateObjectssList =
	(
		--if Krakatoa_GUI_PRTHairExplorer.open do
		(
			KrakatoaHairList = for o in objects where classof o == PRT_Hair collect o
			lbx_PRTHairsInScene.items = for o in KrakatoaHairList collect 
			(
				local txt = " "
				case ddl_displayInfo.selection of
				(
					1: ( 
						txt += (if o.SourceType == 0 then 
						(
							if isValidNode o.TargetNode then 
								" Source:[" + o.TargetNode.name + "] Class:" + (classof o.TargetNode) as string +""
							else
								" Source:<None>"
						)
						else
							" Source: <File Sequence>"
						)
					)
					2: (
						txt += " Spacing:"+o.Spacing as string + "  Adaptive:"+ (if o.UseViewAdaptive then "On" else "Off") + "  Pixels:"+o.PixelSpacing as string + "  Camera:"
						txt +=if isValidNode o.CameraNode then  o.CameraNode.name else "<none>"
					)
					3: (
						txt += " Spacing:"+o.ViewportSpacing as string + "  Limit:"+ o.ViewportHairLimit as string + "  Adaptive:"+ (if o.ViewportUseViewAdaptive then "On" else "Off") + "  Display:" + (if o.ViewportDisplayType == 0 then "Points" else "Tangents")
					)
					4: (
						txt += " Reference Pos.:"+(if o.ReferencePositionEnabled then "On" else "Off") + "  Reference Frame:"+ o.ReferenceTime as string
					)
					
					default: (
					)			
				)	
				(if o.isHiddenInVpt then "--" else "+") + "["+o.name+"]"+ txt
			)	
			if chb_synchSelections.state do synchSelectionFromScene()
		)	
	)	
	
	fn updateCamerasList =
	(
		local theCameras = for o in objects where (findItem camera.classes (classof o ) > 0) collect o
		ddl_sceneCameras.items = join #("<none>") (for o in theCameras collect o.name)
		ddl_sceneCameras.selection = 1 + (findItem theCameras (viewport.getCamera()))
	)	
	
	fn nodesChanged =
	(
		--if Krakatoa_GUI_PRTHairExplorer.open then
		(
			FranticParticles.LogDebug ("+PRT Hair Rollout - NodesChanged Callback Executed.")
			updateObjectssList()
			registerWhenConstructMonitor()
			updateCamerasList()
		)
		--else FranticParticles.LogDebug ("--PRT Hair  Rollout - NodesChanged Callback SUPPRESSED - Rollout Not Open!")
	)		
	

	
	fn refresh_GUI =
	(
		updateObjectssList()
		updateCamerasList()
		

	)
	
	on chb_synchSelections changed state do
	(
		refresh_GUI()
		if state do synchSelectionFromScene()
	)

	on lbx_PRTHairsInScene doubleClicked itm do 
	(
		for i in lbx_PRTHairsInScene.selection do 
			FranticParticles.LogProgress (lbx_PRTHairsInScene.items[i])
	)		
	
	on lbx_PRTHairsInScene selectionEnd do
	(
		if chb_synchSelections.state do synchSelectionToScene()
	)	
	
	on btn_assignCameraToSelected pressed do
	(
		ddl_displayInfo.selection = 2
		local theCamera = getNodeByName ddl_sceneCameras.selected
		for i in lbx_PRTHairsInScene.selection do try(KrakatoaHairList[i].CameraNode = theCamera)catch()	
		updateObjectssList()
		select selection
	)
	
	on btn_createPRTHair pressed do
	(
		macros.run "Krakatoa" "PRTHair"
	)
	
	on btn_renderSpacing pressed do
	(
		ddl_displayInfo.selection = 2
		for i in lbx_PRTHairsInScene.selection do try(KrakatoaHairList[i].Spacing = spn_renderSpacing.value)catch()	
	)
	on btn_viewSpacing pressed do
	(
		ddl_displayInfo.selection = 3
		for i in lbx_PRTHairsInScene.selection do try(KrakatoaHairList[i].ViewportSpacing = spn_viewSpacing.value)catch()	
	)
	
	on btn_viewLimit pressed do
	(
		ddl_displayInfo.selection = 3
		for i in lbx_PRTHairsInScene.selection do try(KrakatoaHairList[i].ViewportHairLimit = spn_viewLimit.value)catch()	
	)	
	
	on btn_PixelSpacing pressed do
	(
		ddl_displayInfo.selection = 2
		for i in lbx_PRTHairsInScene.selection do try(KrakatoaHairList[i].PixelSpacing = spn_PixelSpacing.value)catch()	
	)	
	
	on btn_enableRenderViewAdaptive pressed do
	(
		ddl_displayInfo.selection = 2
		for i in lbx_PRTHairsInScene.selection do try(KrakatoaHairList[i].UseViewAdaptive = true)catch()	
	)
	on btn_disableRenderViewAdaptive pressed do
	(
		ddl_displayInfo.selection = 2
		for i in lbx_PRTHairsInScene.selection do try(KrakatoaHairList[i].UseViewAdaptive = false)catch()	
	)
	on btn_enableViewportViewAdaptive pressed do
	(
		ddl_displayInfo.selection = 3
		for i in lbx_PRTHairsInScene.selection do try(KrakatoaHairList[i].ViewportUseViewAdaptive = true)catch()	
	)
	on btn_disableViewportViewAdaptive pressed do
	(
		ddl_displayInfo.selection = 3
		for i in lbx_PRTHairsInScene.selection do try(KrakatoaHairList[i].ViewportUseViewAdaptive = false)catch()	
	)
	
	on btn_enableRefPosition pressed do
	(
		ddl_displayInfo.selection = 4
		for i in lbx_PRTHairsInScene.selection do try(KrakatoaHairList[i].ReferencePositionEnabled = false)catch()	
	)
	on btn_disableRefPosition pressed do
	(
		ddl_displayInfo.selection = 4
		for i in lbx_PRTHairsInScene.selection do try(KrakatoaHairList[i].ReferencePositionEnabled = false)catch()	
	)
	
	on btn_displayMode pressed do 
	(
		ddl_displayInfo.selection = 3
		for i in lbx_PRTHairsInScene.selection do try(KrakatoaHairList[i].ViewportDisplayType = ddl_displayMode.selection-1)catch()	
	)

	on btn_selectAll pressed do
	(
		updateObjectssList()
		lbx_PRTHairsInScene.selection = #{1..(lbx_PRTHairsInScene.items.count)}
		if chb_synchSelections.state do synchSelectionToScene()
	)
	
	on btn_deselectAll pressed do
	(
		updateObjectssList()
		lbx_PRTHairsInScene.selection = #{}
		if chb_synchSelections.state do synchSelectionToScene()
	)

	on btn_selectInvert pressed do
	(
		updateObjectssList()
		lbx_PRTHairsInScene.selection = -lbx_PRTHairsInScene.selection
		if chb_synchSelections.state do synchSelectionToScene()
	)	
	
	on btn_hideSelected pressed do
	(
		hide (for i in lbx_PRTHairsInScene.selection collect KrakatoaHairList[i])
		updateObjectssList()
	)
	on btn_unhideSelected pressed do
	(
		unhide (for i in lbx_PRTHairsInScene.selection collect KrakatoaHairList[i])
		updateObjectssList()
	)
	
	on btn_selectHidden pressed do
	(
		updateObjectssList()
		lbx_PRTHairsInScene.selection = (for i = 1 to lbx_PRTHairsInScene.items.count where KrakatoaHairList[i].isHiddenInVpt collect i)
		if chb_synchSelections.state do 
			select (for i = 1 to lbx_PRTHairsInScene.items.count where KrakatoaHairList[i].isHiddenInVpt collect KrakatoaHairList[i])
	)			

	
	
	on ddl_displayInfo selected itm do updateObjectssList()


	on Krakatoa_GUI_PRTHairExplorer rolledUp val do 
	(
		FranticParticles.SetProperty "GUI:PRTHairExplorerRolloutOpen" val		
		if val then 
		(
			FranticParticles.LogDebug ("+Particle Loaders Rollout ROLLED DOWN.")
		)					
		else
			FranticParticles.LogDebug ("+Particle Loaders Rollout ROLLED UP.")	
	)			
		
	
	on Krakatoa_GUI_PRTHairExplorer close do 
	(
		Krakatoa_GUI_PRTHairExplorer.Refresh_GUI()
		
		 callbacks.removeScripts id:#Krakatoa_HairSelectionMonitor
		 callbacks.removeScripts id:#Krakatoa_HairCreationDeletionMonitor
		 deleteAllChangeHandlers id:#Krakatoa_HairParametersMonitor			
	)	
	
	fn updateIcons =
	(
	)	
	

	on Krakatoa_GUI_PRTHairExplorer open do 
	(
		updateIcons()
		Refresh_GUI()
		
		callbacks.removeScripts id:#Krakatoa_HairSelectionMonitor
		registerSelectionCallback()

		callbacks.removeScripts id:#Krakatoa_HairCreationDeletionMonitor
		registerSceneNodeCallbacks()
		 
		registerWhenConstructMonitor()				
		FranticParticles.LogDebug ("+PRT Hair Rollout OPENED.")			
	)		
)


--------------------------------------------------------------------------------------------------------------------------------------------------------------------	
--PARTICLE LOADERS ROLLOUT
--------------------------------------------------------------------------------------------------------------------------------------------------------------------	
rollout Krakatoa_GUI_ParticleLoaders "PRT Loader Objects" category:100 width:457
(
	local KrakatoaLoadersList = #()

	button btn_Help_Loaders  "Open Online Help..." width:450 height:16 align:#center offset:[0,-5] across:1 tooltip:"Opens the Krakatoa Online Help for the PRT Loaders rollout in the default Web Browser. Requires Internet connection."
	
	on Krakatoa_GUI_ParticleLoaders moved pos do
	(
		setIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "RolloutDialogPositions" Krakatoa_GUI_ParticleLoaders.title (pos as string)
		--Krakatoa_CustomizeRollouts_Dialog.updateStripsPositions pos
	)	

	checkbutton chb_synchSelections ">Synch. Selection" across:3 width:144 align:#left checked:true offset:[-8,0] highlightcolor:KrakatoaSkinColorsStruct.Loaders tooltip:"When checked, selecting objects from the list will update the scene selection.\n\nWhen unchecked, the scene selection will not be synchronized to the list selection.\n\nHowever, selecting objects in the scene will always update the list's selection regardless of the state of this option."
	dropdownlist ddl_displayInfo items:#("Particle Files","Render Settings","Viewport Settings","Particle Display Mode","Particle Color Source","Timing","Options","Missing Frames In Scene","Missing Frames In Render","Test Renderable State") height:20 width:154 align:#center offset:[2,0] tooltip:"Display the following PRT Loader properties..."
	button btn_createLoader "Create New Loader..." width:144 align:#right offset:[10,0]
	
	multilistbox lbx_particleLoadersInScene height:20 width:450 align:#center offset:[0,-3]
	
	button btn_selectAll "Select All Loaders" width:148 align:#left across:3 offset:[-10,-3]
	button btn_deselectAll "Deselect All Loaders" width:149 align:#center offset:[0,-3]
	button btn_selectInvert "Invert Loaders Selection" width:148 align:#right offset:[10,-3]
	
	button btn_hideSelected "Hide Selected Loaders" width:148 align:#left across:3 offset:[-10,-3]
	button btn_unhideSelected "Unhide Selected Loaders" width:149 align:#center offset:[0,-3]
	button btn_selectHidden "Select Hidden Loaders" width:148 align:#right offset:[10,-3]
	
	label lbl_diskCount "Disk:" across:3 align:#left
	label lbl_renderCount "Render:" align:#center
	label lbl_viewCount "View:" align:#right
	
	label lbl_placeholder01 ""
	label lbl_placeholder02 ""

	button btn_enableInRender "Enable In Render" width:108 align:#left across:4 offset:[-6,-8]
	button btn_disableInRender "Disable In Render" width:108 align:#center offset:[-3,-8]
	button btn_enableInViewport "Enable In Viewport"  width:108 align:#center offset:[4,-8]
	button btn_disableInViewport "Disable In Viewport" width:108 align:#right offset:[6,-8]
	
	button btn_enableLimitInRender "Render Limit ON" width:108 align:#left across:4 offset:[-6,-3]
	button btn_disableLimitInRender "Render Limit OFF" width:108 align:#center offset:[-3,-3]
	button btn_enableLimitInViewport "Viewport Limit ON" width:108 align:#center offset:[4,-3]
	button btn_disableLimitInViewport "Viewport Limit OFF" width:108 align:#right offset:[6,-3]

	button btn_renderLimitPreset "Render Limit (x1000)" across:6 align:#left offset:[-6,-3] width:108 tooltip:"Click or right-click to Get, Add and Remove 'Render Limit' Preset Values..."
	spinner spn_renderLimit fieldwidth:45 range:[1,1000000,1000]  align:#center offset:[23,0] type:#float
	button btn_setRenderLimit "Set Value" width:52 align:#right  offset:[-2,-3]

	button btn_viewportLimitPreset "Viewprt.Limit (x1000)" align:#left offset:[4,-3] width:108 tooltip:"Click or right-click to Get, Add and Remove 'Viewport Limit' Preset Values..."
	spinner spn_viewportLimit fieldwidth:45 range:[1,100000,100]  align:#center offset:[33,0] type:#float
	button btn_setViewportLimit "Set Value" width:52 align:#right  offset:[8,-3]
	
	dropdownlist ddl_renderLoadMode items:#("Load Every Nth Particle","Load First N Particles","Load Every Nth By ID")	width:163 align:#left across:4 offset:[-5,-3]
	button btn_SetRenderLoadMode "Set Mode" align:#center offset:[25,-3] width:52
	
	dropdownlist ddl_viewLoadMode items:#("Load Using Render Mode","Load Every Nth Particle","Load First N Particles","Load Every Nth By ID")  width:163 align:#center offset:[32,-3]
	button btn_SetViewLoadMode "Set Mode" align:#right offset:[6,-3] width:52
	
	button btn_pasteFromClipboard "Paste File Sequences From Clipboard" width:217 align:#left across:3 offset:[-6,-3]
	
	dropdownlist ddl_ViewportParticleDisplayMode width:163 align:#right offset:[95,-3] items:#("Display As Small Dots","Display As Large Dots","Display Velocities","Display Normals","Display Tangents") 
	button  btn_SetViewportParticleDisplayMode "Set Mode" align:#right offset:[5,-3] width:52

	button btn_launchPRTScan "Launch PRT Loader Scanner Utility..." width:217 align:#left across:4 offset:[-6,-3]
	
	button btn_viewportFractionPreset "View % Of Render:" width:108 align:#center offset:[111,-3] tooltip:"Click or right-click to Get, Add and Remove 'View % Of Render' Preset Values..."
	spinner spn_viewportFraction  fieldwidth:45 range:[0,100,1]  align:#right offset:[60,0]
	button btn_viewportFraction "Set Value" width:52 align:#right  offset:[6,-3]

	button btn_launchPDViewer "Launch Particle Data Viewer..." width:217 align:#left across:3 offset:[-6,-3]
	button btn_SetIgnoreMaterialON "Ignore Material ON"  width:108 align:#right offset:[39,-3] 
	button btn_SetIgnoreMaterialOFF "Ignore Material OFF" width:108 align:#right offset:[5,-3]

	groupbox grp_renderModes "Render:" width:225 height:185 pos:[3,395] across:2 
	groupbox grp_viewportModes "Viewport:" width:223 height:185 pos:[227,395] 
	groupbox lbl_massChangingUtility "Mass-Changing Utilities - Affect Highlighted PRT Loaders:" height:200 width:448 pos:[3,380] 

	on btn_launchPRTScan pressed do macros.run "Krakatoa" "KrakatoaPRTscan"
	on btn_launchPDViewer pressed do macros.run "Krakatoa" "KrakatoaParticleDataViewer"
	
	fn registerSelectionCallback =
	(
		FranticParticles.LogDebug ("+Particle Loaders Rollout - Registering SELECTION Callback.")
		callbacks.addScript #selectionSetChanged "try(Krakatoa_GUI_ParticleLoaders.synchSelectionFromScene())catch()" id:#Krakatoa_LoaderSelectionMonitor
	)
	
	fn registerSceneNodeCallbacks =
	(
		 FranticParticles.LogDebug ("+Particle Loaders Rollout - Registering NODE Callbacks.")
		 callbacks.addScript #nodePostDelete "try(Krakatoa_GUI_ParticleLoaders.nodesChanged())catch()" id:#Krakatoa_LoaderCreationDeletionMonitor
		 callbacks.addScript #nodeCreated "try(Krakatoa_GUI_ParticleLoaders.nodesChanged())catch()" id:#Krakatoa_LoaderCreationDeletionMonitor
		 callbacks.addScript #nodeRenamed "try(Krakatoa_GUI_ParticleLoaders.nodesChanged())catch()" id:#Krakatoa_LoaderCreationDeletionMonitor
		 callbacks.addScript #nodeHide "try(Krakatoa_GUI_ParticleLoaders.nodesChanged())catch()" id:#Krakatoa_LoaderCreationDeletionMonitor
		 callbacks.addScript #nodeUnhide "try(Krakatoa_GUI_ParticleLoaders.nodesChanged())catch()" id:#Krakatoa_LoaderCreationDeletionMonitor
		 if (maxVersion())[1] >=8000 do callbacks.addScript #sceneUndo "try(Krakatoa_GUI_ParticleLoaders.nodesChanged())catch()" id:#Krakatoa_LoaderCreationDeletionMonitor
	)
	
	fn registerWhenConstructMonitor =
	(
		FranticParticles.LogDebug ("+Particle Loaders Rollout - Registering WHEN Callbacks.")
		deleteAllChangeHandlers id:#Krakatoa_LoaderParametersMonitor
		theBOs = for o in KrakatoaLoadersList collect o.baseobject --we have to monitor just the base objects to avoid updates on node PRS changes!
		when parameters theBOs change id:#Krakatoa_LoaderParametersMonitor do Krakatoa_GUI_ParticleLoaders.nodesChanged()
	)
	
	fn synchSelectionToScene =
	(
		callbacks.removeScripts id:#Krakatoa_LoaderSelectionMonitor
		max select none
		select (for i in lbx_particleLoadersInScene.selection where isValidNode KrakatoaLoadersList[i] collect KrakatoaLoadersList[i])
		registerSelectionCallback()
	)
	
	fn synchSelectionFromScene =
	(
		lbx_particleLoadersInScene.selection = (for o in selection where findItem KrakatoaLoadersList o > 0 collect findItem KrakatoaLoadersList o) as bitarray
	)
	
	fn getArrayDifference arr1 arr2 =
	(
		local array1 = for i in arr1 collect i
		local array2 = for i in arr2 collect i
		
		if array1.count > array2.count then
			for i = array2.count to 1 by -1 do 
			(
				theIndex = findItem array1 array2[i]
				if theIndex > 0 do 
				(
					deleteItem array2 i
					deleteItem array1 theIndex
				)	
			)
		else	
			for i = array1.count to 1 by -1 do 
			(
				local theIndex = findItem array2 array1[i]
				if theIndex > 0 do 
				(
					deleteItem array1 i
					deleteItem array2 theIndex
				)	
			)	
		
		if array1.count ==0 then
		(
			"OK"
		)
		else
		(
			sort (join array1 array2)
			local theNegatives = (for i in array1 where i < 1 collect i) 
			local thePositives = ((for i in array1 where i > 0 collect i) as bitarray) 
			local txt = "(" 
			if theNegatives.count > 0 do 
				txt += substring (theNegatives as string) 3 ((theNegatives as string).count-3)  
			if thePositives.numberset > 0 and theNegatives.count > 0 do txt+=", "
			if thePositives.numberset > 0 do txt += substring (thePositives as string) 3 ((thePositives as string).count-3) 
			txt += ")"
			txt
		)	
	)
	
	fn willThisObjectRender theObj =
	(
		local theLayer = theObj.layer 
		local allSequencesAreOff = true
		for i in theObj.FileListFlags where i > 1 do allSequencesAreOff = false
		if not FranticParticles.GetBoolProperty "RenderKrakatoaLoaders" then "PRT Loaders are not enabled as particle source"
		else if not theObj.renderable then "Renderable Object Property is OFF" 
		else if not theObj.primaryVisibility then "Visible To Camera Object Property is OFF" 
		else if theObj.isHidden then "Object is Hidden"
		else if (theObj.isFrozen and maxOps.hideFrozenObjects) then "Frozen and Hide Frozen Objects is ON"
		else if not theLayer.on then "Layer is OFF"
		else if not theLayer.renderable then "Layer Renderable Property is OFF"
		else if theLayer.isHidden then "Layer is Hidden"
		else if not theLayer.primaryVisibility then "Layer Visible To Camera is OFF"
		else if not theObj.enabledInRender then "Rendering>Enabled is OFF"
		else if theObj.percentRenderer == 0.0 then "Render Percent is 0.0"
		else if (theObj.useRenderLimit and theObj.renderLimit == 0.0) then "Render Limit is ON and 0.0"
		else if allSequencesAreOff then "All Sequences are OFF in Renderer"
		else "OK"
	)
	
	fn updateLoadersList =
	(
		--if Krakatoa_GUI_ParticleLoaders.open do
		(
			local diskCount = 0
			local renderCount = 0
			local viewCount = 0
			
			KrakatoaLoadersList = for o in objects where classof o == KrakatoaPrtLoader collect o
			lbx_particleLoadersInScene.items = for o in KrakatoaLoadersList collect 
			(
				diskCount += o.delegate.getParticleCount()
				if o.enabledInRender AND not o.isHiddenInVpt do renderCount += o.delegate.getParticleCountRender()
				if o.enabledInView AND not o.isHiddenInVpt do viewCount += o.delegate.getParticleCountView() 
				local txt = " "
				case ddl_displayInfo.selection of
				(
					1: (
						txt += "(" + FranticParticleRenderMXS.addCommas ((o.delegate.getParticleCount()) as string) + ") "
						txt += o.fileList.count as string + ":"
						for i in o.fileList do txt+= fileNameFromPath i + ";"
					 )
					2: (
						txt += "Render:" + (if o.enabledInRender then "On" else "Off")
						if o.enabledInRender then
						(
							txt += "(" + (((o.delegate.getParticleCountRender()) as integer)as string) 
							txt += " | " + o.percentRenderer as string + "%) "
							txt += " Limit:" + (if o.useRenderLimit then ("On (" + o.RenderLimit as string + "K)") else "Off" )
							txt += case o.renderLoadMode of
							(
								1: " Load Every Nth Particle"
								2: " Load First N Particles"
								4: " Load Every Nth By ID"
								default: " ???"
							)							
						)	
					)		
					3: (
						txt += "Viewport:" + (if o.enabledInView then "On" else "Off")
						if o.enabledInView then
						(
							txt += "(" + (((o.delegate.getParticleCountView()) as integer)as string) 
							txt += " | " + o.percentViewport as string + "% -> "+ (o.percentViewport * o.percentRenderer * 0.01) as string +"%) "
							txt += " Limit:" + (if o.useViewportLimit then ("On (" + o.ViewportLimit  as string + "K)") else "Off" )
							txt += case o.viewLoadMode of
							(
								1: " Load Using Render Mode"
								2: " Load Every Nth Particle"
								3: " Load First N Particles"
								4: " Load Every Nth By ID"								
								default: " ???"
							)
						)	
					)
					4: (
						txt += "Display As " 
						txt += case o.ViewportParticleDisplayMode of
						(
							1: "Small Dots"
							2: "Large Dots"
							3: "Velocities"
							4: "Normals"
							5: "Tangents"
							default: " ???"
						)						
					)					
					5: (
						txt += "  Viewport:"
						txt += try(if o.IgnoreMaterial then " Ignore Material, Use Color Channel" else " Use Material / Saved Color / Wirecolor" )catch(" ???")
					)	
					6: (
						txt += "Frame Offset:" + (o.frameOffset as string)
						txt += if o.loadSingleFrame  then "  Load Single Frame Only" else "  Load Whole File Sequence"
					)	
	
					7: (
						txt += "  Use Transformations:" + (if o.useTransform then "On" else "Off")
					)	
					10: (
						txt += willThisObjectRender o
					)
					default: (
						cnt = 0
						local theRenderRange 
						if ddl_displayInfo.selection == 8 then
						(
							if o.enablePlaybackGraph then
								theRenderRange = for i = animationrange.start to animationrange.end collect at time i (o.playbackGraphTime as integer +o.frameOffset ) 
							else
								theRenderRange = for i = animationrange.start to animationrange.end collect ((i.frame +o.frameOffset)  as integer )
						)
						if ddl_displayInfo.selection == 9 then
						(
							local currentSequence = #()
							case rendTimeType of
							(
								1: (
										currentSequence = #(currentTime.frame as integer) 
									)
								2: (
										currentSequence = for t in animationRange.start to animationRange.end by rendNthFrame collect (t.frame as integer)
									)
								3: (
										currentSequence = for t in rendStart to rendEnd by rendNthFrame collect (t.frame as integer)
									)
								4: (
										theFS = filterString rendPickupFrames "-"
										txt = "#{"
										for i = 1 to theFS.count-1 do txt += theFS[i]+ ".."
										txt += theFS[theFS.count] + "}"
										currentSequence = (execute txt) as array
										currentSequence = sort currentSequence 
									)	
							)
							if o.enablePlaybackGraph then
								theRenderRange = for i in currentSequence collect at time i (o.playbackGraphTime as integer +o.frameOffset) 
							else
								theRenderRange = for i in currentSequence collect (i+o.frameOffset) 
						)
						if o.limitToRange == true do
							theRenderRange = for i in theRenderRange where i >= o.rangeStartFrame and i <= o.rangeEndFrame collect i
								
						for f in o.fileList do
						(
							cnt += 1
							txt += " " + cnt as string + ":"
							if o.loadSingleFrame then 
							(
								if doesFileExist f then txt+="OK" else txt+="Missing Frame"
							)	
							else
							(
								local theFilePattern = FranticParticles.ReplaceSequenceNumberWithHashes f
								local theFS = filterString theFilePattern "#"
								theFilePattern = ""
								for i in theFS do theFilePattern += i + "*"
								local theFiles = getFiles theFilePattern
								local availableFrames = for i in theRenderRange where findItem theFiles (FranticParticles.ReplaceSequenceNumber f i) > 0 collect i
								txt += getArrayDifference theRenderRange availableFrames
							)
						)
					)			
					
				)	
				(if o.isHiddenInVpt then "--" else "+") + "["+o.name+"]"+ txt
			)	
			lbl_diskCount.text = "Disk: " + FranticParticleRenderMXS.addCommas (diskCount as string)
			Krakatoa_GUI_Channels.updateMemChannels()	
			lbl_renderCount.text = "Render: " + FranticParticleRenderMXS.addCommas ((renderCount as integer) as string) + " ("  + (renderCount * Krakatoa_GUI_Channels.MemoryBytesPerParticle / 1048576.0) as string+ " MB)"
			lbl_viewCount.text = "View: " + FranticParticleRenderMXS.addCommas ((viewCount as integer) as string)
			
			if chb_synchSelections.state do synchSelectionFromScene()
		)	
	)		
	
	fn pasteClipboardSequencesToPRTLoaders thePRTLoader =
	(
		local clipboardClass = dotNetClass  "System.Windows.Forms.Clipboard"
		local theFilesString = clipboardClass.GetText()
		local theSS = theFilesString as StringStream
		local theFileList = thePRTLoader.FileList
		local theFileListFlags = thePRTLoader.FileListFlags
		local changesMade = false
		local addSequenceMode = getIniSetting ( getDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "Preferences" "AddFileSequenceBehavior"
		if addSequenceMode == "" do addSequenceMode = "1"
		while not eof theSS do
		(
			local theLine = readLine theSS
			if pathConfig.isLegalPath theLine and getFileNamePath theLine != "" do
			(
				if findItem theFileList theLine == 0 do
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
			thePRTLoader.FileList = theFileList 
			thePRTLoader.FileListFlags = theFileListFlags 
		)	
	)
	

	
	fn createPresetsRCMenu type:#renderpercent =
	(
		case type of
		(
			#viewpercent : (
						presetName = "ViewPercentPresets"
						theParameter = "spn_viewportFraction"
					)	
			#renderlimit: (
						presetName = "RenderLimitPresets"
						theParameter = "spn_RenderLimit"
					)						
			#viewlimit: (
						presetName = "ViewLimitPresets"
						theParameter = "spn_ViewportLimit"
					)	
		)
		local presetsList = #()
		local theKeys = for i in (getIniSetting (Krakatoa_PresetsDirectory + "//KrakatoaPreferences.ini") presetName  ) collect (execute i)
		sort theKeys 
		if theKeys.count == 0 then 
		(
			theKeys = case type of
			(
				#viewpercent : #(1.0,10.0,50.0,100.0)
				#renderlimit: #(1000.0,10000.0,100000.0)
				#viewlimit: #(1.0,10.0,100.0,1000.0)
			)
			for i in theKeys do
				setIniSetting (Krakatoa_PresetsDirectory + "//KrakatoaPreferences.ini") presetName (i as string) (i as string)
		)
		for k in theKeys do
			if findItem presetsList theValue == 0 do append presetsList k

		theValue = execute ("Krakatoa_GUI_ParticleLoaders." + theParameter+".value")
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
			txt += "on mnu_preset" + cnt as string + " picked do Krakatoa_GUI_ParticleLoaders."+ theParameter +".value = "+ i as string +"\n"
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
	
	on btn_renderLimitPreset pressed do 
	(
		createPresetsRCMenu type:#renderlimit
		popupmenu Krakatoa_Presets_RCMenu pos:mouse.screenpos
	)
	on btn_renderLimitPreset rightclick do 
	(
		createPresetsRCMenu type:#renderlimit
		popupmenu Krakatoa_Presets_RCMenu pos:mouse.screenpos
	)	
	
	on btn_viewportLimitPreset pressed do 
	(
		createPresetsRCMenu type:#viewlimit
		popupmenu Krakatoa_Presets_RCMenu pos:mouse.screenpos
	)
	on btn_viewportLimitPreset rightclick do 
	(
		createPresetsRCMenu type:#viewlimit
		popupmenu Krakatoa_Presets_RCMenu pos:mouse.screenpos
	)		
	on btn_viewportFractionPreset pressed do 
	(
		createPresetsRCMenu type:#viewpercent
		popupmenu Krakatoa_Presets_RCMenu pos:mouse.screenpos
	)
	on btn_viewportFractionPreset rightclick do 
	(
		createPresetsRCMenu type:#viewpercent
		popupmenu Krakatoa_Presets_RCMenu pos:mouse.screenpos
	)		
	
	
	on btn_hideSelected pressed do
	(
		hide (for i in lbx_particleLoadersInScene.selection collect KrakatoaLoadersList [i])
		updateLoadersList()
	)
	on btn_unhideSelected pressed do
	(
		unhide (for i in lbx_particleLoadersInScene.selection collect KrakatoaLoadersList [i])
		updateLoadersList()
	)
	
	on btn_selectHidden pressed do
	(
		updateLoadersList()
		lbx_particleLoadersInScene.selection = (for i = 1 to lbx_particleLoadersInScene.items.count where KrakatoaLoadersList[i].isHiddenInVpt collect i)
		if chb_synchSelections.state do 
			select (for i = 1 to lbx_particleLoadersInScene.items.count where KrakatoaLoadersList[i].isHiddenInVpt collect KrakatoaLoadersList[i])
	)			
	
	fn nodesChanged =
	(
		if Krakatoa_GUI_ParticleLoaders.open then
		(
			FranticParticles.LogDebug ("+Particle Loaders Rollout - NodesChanged Callback Executed.")
			updateLoadersList()
			registerWhenConstructMonitor()
		)
		else
			FranticParticles.LogDebug ("--Particle Loaders Rollout - NodesChanged Callback SUPPRESSED - Rollout Not Open!")
	)
	
	fn refresh_GUI =
	(
		updateLoadersList()
		
		/*if Krakatoa_Initializing_Hidden_Rollouts == false do 
			try(Krakatoa_GUI_ParticleLoaders.open = FranticParticles.GetBoolProperty "GUI:ParticleLoadersRolloutOpen")catch()*/
	)
	
	on chb_synchSelections changed state do
	(
		refresh_GUI()
		if state do synchSelectionFromScene()
	)
	
	on lbx_particleLoadersInScene selectionEnd do
	(
		if chb_synchSelections.state do synchSelectionToScene()
	)
	
	on lbx_particleLoadersInScene doubleClicked itm do 
	(
		for i in lbx_particleLoadersInScene.selection do 
			FranticParticles.LogProgress (lbx_particleLoadersInScene.items[i])
	)	
	
	on btn_createLoader pressed do 
	(
		newLoader = try(execute "KrakatoaPrtLoader()")catch()
		updateLoadersList()
		lbx_particleLoadersInScene.selection = #{lbx_particleLoadersInScene.items.count}
		max modify mode
		if isValidNode newLoader do
		(
			select newLoader 
			local thePref = getIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "Preferences" "CreateLoadersBehavior"
			if thePref != "3" do try(newLoader.params.btn_addFiles.pressed())catch()
		)	
	)
	
	on ddl_displayInfo selected itm do updateLoadersList()
	
	on btn_selectAll pressed do
	(
		updateLoadersList()
		lbx_particleLoadersInScene.selection = #{1..(lbx_particleLoadersInScene.items.count)}
		if chb_synchSelections.state do synchSelectionToScene()
	)
	
	on btn_deselectAll pressed do
	(
		updateLoadersList()
		lbx_particleLoadersInScene.selection = #{}
		if chb_synchSelections.state do synchSelectionToScene()
	)

	on btn_selectInvert pressed do
	(
		updateLoadersList()
		lbx_particleLoadersInScene.selection = -lbx_particleLoadersInScene.selection
		if chb_synchSelections.state do synchSelectionToScene()
	)	


--ENABLED/DISABLE IN VIEWPORT AND RENDERER
	on btn_enableInViewport pressed do
	(
		ddl_displayInfo.selection = 3
		for i in lbx_particleLoadersInScene.selection do try(KrakatoaLoadersList[i].enabledInView = true)catch()
	)	
	on btn_disableInViewport pressed do
	(
		ddl_displayInfo.selection = 3
		for i in lbx_particleLoadersInScene.selection do try(KrakatoaLoadersList[i].enabledInView = false)catch()
	)	
	on btn_enableInRender pressed do
	(
		ddl_displayInfo.selection = 2
		for i in lbx_particleLoadersInScene.selection do try(KrakatoaLoadersList[i].enabledInRender = true)catch()
	)	
	on btn_disableInRender pressed do
	(
		ddl_displayInfo.selection = 2
		for i in lbx_particleLoadersInScene.selection do try(KrakatoaLoadersList[i].enabledInRender = false)catch()
	)	

--ENABLED/DISABLE LIMIT IN VIEWPORT AND RENDERER
	on btn_enableLimitInViewport pressed do
	(
		ddl_displayInfo.selection = 3
		for i in lbx_particleLoadersInScene.selection do try(KrakatoaLoadersList[i].useViewportLimit = true)catch()
	)	
	on btn_disableLimitInViewport pressed do
	(
		ddl_displayInfo.selection = 3
		for i in lbx_particleLoadersInScene.selection do try(KrakatoaLoadersList[i].useViewportLimit= false)catch()
	)	
	on btn_enableLimitInRender pressed do
	(
		ddl_displayInfo.selection = 2
		for i in lbx_particleLoadersInScene.selection do try(KrakatoaLoadersList[i].useRenderLimit= true)catch()
	)	
	on btn_disableLimitInRender pressed do
	(
		ddl_displayInfo.selection = 2
		for i in lbx_particleLoadersInScene.selection do try(KrakatoaLoadersList[i].useRenderLimit= false)catch()
	)	

	on btn_setRenderLimit pressed do 
	(
		ddl_displayInfo.selection = 2
		for i in lbx_particleLoadersInScene.selection do try(KrakatoaLoadersList[i].RenderLimit= spn_renderLimit.value)catch()
	)		

	on btn_SetViewportLimit pressed do 
	(
		ddl_displayInfo.selection = 3
		for i in lbx_particleLoadersInScene.selection do try(KrakatoaLoadersList[i].ViewportLimit = spn_ViewportLimit.value)catch()
	)		
	
	
--MASS-CHANGE PARTICLE AND COLOR LOADING MODE IN VIEWPORT AND RENDERER		
	on btn_SetViewLoadMode pressed do
	(
		ddl_displayInfo.selection = 3
		for i in lbx_particleLoadersInScene.selection do try(KrakatoaLoadersList[i].viewLoadMode = ddl_viewLoadMode.selection)catch()
	)
	
	on btn_SetRenderLoadMode pressed do
	(
		ddl_displayInfo.selection = 2
		for i in lbx_particleLoadersInScene.selection do try(KrakatoaLoadersList[i].renderLoadMode = ddl_renderLoadMode.selection)catch()
	)		
	
	on btn_SetViewportParticleDisplayMode pressed do
	(
		ddl_displayInfo.selection = 4
		for i in lbx_particleLoadersInScene.selection do try(KrakatoaLoadersList[i].viewportParticleDisplayMode = ddl_ViewportParticleDisplayMode.selection)catch()
	)
	


	on btn_viewportFraction pressed do
	(
		ddl_displayInfo.selection = 3
		for i in lbx_particleLoadersInScene.selection do try(KrakatoaLoadersList[i].percentViewport = spn_viewportFraction.value)catch()
	)
	
	/*
	on btn_SetParticleDensitySource pressed do 
	(
		ddl_displayInfo.selection = 5
		for i in lbx_particleLoadersInScene.selection do try(KrakatoaLoadersList[i].loadDensities = ckb_loadParticleDensities.state)catch()		
	)	
	*/
	
	
	on btn_SetIgnoreMaterialON pressed do
	(
		ddl_displayInfo.selection = 5
		for i in lbx_particleLoadersInScene.selection do try(KrakatoaLoadersList[i].ignoreMaterial = true)catch()	
	)
	on btn_SetIgnoreMaterialOFF pressed do
	(
		ddl_displayInfo.selection = 5
		for i in lbx_particleLoadersInScene.selection do try(KrakatoaLoadersList[i].ignoreMaterial = false)catch()	
	)
	
	
	on btn_pasteFromClipboard pressed do
	(
		ddl_displayInfo.selection = 1
		with undo "Mass-Paste From Clipboard" on 
		(
			for i in lbx_particleLoadersInScene.selection do 
				try(pasteClipboardSequencesToPRTLoaders KrakatoaLoadersList[i])catch()	
		)
	)
	
	on Krakatoa_GUI_ParticleLoaders rolledUp val do 
	(
		FranticParticles.SetProperty "GUI:ParticleLoadersRolloutOpen" val		
		if val then 
		(
			FranticParticles.LogDebug ("+Particle Loaders Rollout ROLLED DOWN.")
		)					
		else
			FranticParticles.LogDebug ("+Particle Loaders Rollout ROLLED UP.")	
	)			
		
	
	on Krakatoa_GUI_ParticleLoaders close do 
	(
		/*
		if Krakatoa_GUI_ParticleLoaders.inDialog and not Krakatoa_Closing_Floater and not Krakatoa_Initializing_Hidden_Rollouts then
		(
			setIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "RolloutVisible" Krakatoa_GUI_ParticleLoaders.title "false"
			FranticParticleRenderMXS.floatOrDockRollout Krakatoa_GUI_ParticleLoaders forceMode:#hide
			Krakatoa_GUI_ParticleLoaders.Refresh_GUI()
		)	
		*/
		 callbacks.removeScripts id:#Krakatoa_LoaderSelectionMonitor
		 callbacks.removeScripts id:#Krakatoa_LoaderCreationDeletionMonitor
		 deleteAllChangeHandlers id:#Krakatoa_LoaderParametersMonitor			
	)	
	
	fn updateIcons =
	(
		--btn_Float_Rollout.images = #(Krakatoa_PresetsArrowBitmap,Krakatoa_PresetsArrowBitmap, 32,4,4,4,4)
	)	
	

	on Krakatoa_GUI_ParticleLoaders open do 
	(
		updateIcons()
		
		--Krakatoa_CustomizeRollouts_Dialog.Refresh_GUI()
		
		Refresh_GUI()
		
		callbacks.removeScripts id:#Krakatoa_LoaderSelectionMonitor
		registerSelectionCallback()

		callbacks.removeScripts id:#Krakatoa_LoaderCreationDeletionMonitor
		registerSceneNodeCallbacks()
		 
		registerWhenConstructMonitor()				
		FranticParticles.LogDebug ("+Particle Loaders Rollout OPENED.")			
	)			
	
)--end rollout


--------------------------------------------------------------------------------------------------------------------------------------------------------------------	
--THINKING PARTICLES ROLLOUT
--------------------------------------------------------------------------------------------------------------------------------------------------------------------	

rollout Krakatoa_GUI_ThinkingParticles "Thinking Particles Groups" category:500 width:457
(
	local InactiveTPGroups = #()
	local ActiveTPGroups = #()

	button btn_Help_TP  "Open Online Help..." width:450 height:16 align:#center offset:[0,-5] tooltip:"Opens the Krakatoa Online Help for the Thinking Particles rollout in the default Web Browser. Requires Internet connection."
	
	on Krakatoa_GUI_ThinkingParticles moved pos do
	(
		setIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "RolloutDialogPositions" Krakatoa_GUI_ThinkingParticles.title (pos as string)
	)			

	multilistbox lbx_inactiveGroups " Non-Renderable TP Groups:" items:#() height:20 across:2 width:204 align:#left
	multilistbox lbx_allGroups " Renderable TP Groups:"  items:#() height:20 width:205 align:#right
	
	button btn_TPGroupsUpdate "Update TP Groups Lists" align:#left offset:[0,-3] width:120 across:6 tooltip:"Scan Scene For Thinking Particles Groups..."
	button btn_inactiveAll "All" width:40 alignt:#left offset:[34,-3] tooltip:"Select All Inactive Groups."
	button btn_inactiveInvert "Invert" width:40 alignt:#left offset:[5,-3] tooltip:"Invert Inactive Groups Selection."

	button btn_allAll "All" width:40 alignt:#right offset:[-3,-3] tooltip:"Select All Active Groups."
	button btn_allInvert "Invert" width:40 alignt:#right offset:[-32,-3] tooltip:"Invert Active Groups." 
	checkbutton chk_showFullHierarchy ">Show Full Hierarchy" align:#right offset:[3,-3] width:120 across:6 tooltip:"Expand the Hierarchy to show all Parent Groups." highlightcolor:KrakatoaSkinColorsStruct.Thinking

	label lbl_tpwarning ""
	button btn_GroupAdd ">" height:40 align:#center width:20 offset:[0,-225] tooltip:"Move the highlighted Channel to the Active list." 
	button btn_GroupRemove "<" height:40 align:#center offset:[0,-3] width:20 tooltip:"Remove the highlighted Channel from the Active list." 

	fn getSubGroups theMaster theBase theParent =
	(
		for g in getPropNames theParent where try( (classof (getProperty theParent g)) == PGroup ) catch(false)  do
		(
			local theNewBase = if chk_showFullHierarchy.checked then (theBase + "." + (g as string)) else (theBase + ".")
			if try(getProperty (getProperty theParent g) #Renderable)catch(true) then 
				append ActiveTPGroups #((getProperty theParent g), theMaster.name + theBase + "." + (g as string))
			else	
				append inactiveTPGroups #((getProperty theParent g), theMaster.name + theBase + "." + (g as string))
			getSubGroups theMaster theNewBase (getProperty theParent g)
		)
	)

	fn populateLists =
	(
		ActiveTPGroups = #() 
		inactiveTPGroups = #()
		lbl_tpwarning.text = ""
		local theTPObjects = for o in objects where classof o == Thinking collect o
		if theTPObjects.count > 0 then
		(
			local TPRolloutEnabled = try(hasProperty theTPObjects[1].GroupManager "Renderable")catch(false)
			lbx_allGroups.enabled = lbx_inactiveGroups.enabled = btn_GroupAdd.enabled = btn_GroupRemove.enabled = TPRolloutEnabled 
			btn_TPGroupsUpdate.enabled = btn_inactiveAll.enabled = btn_inactiveInvert.enabled = btn_allAll.enabled = btn_allInvert.enabled = chk_showFullHierarchy.enabled = TPRolloutEnabled 
			if not TPRolloutEnabled do lbl_tpwarning.text = "WARNING: Thinking Particles 3.0 or higher required to access Groups Renderable state."
			for o in theTPObjects do
			(
				if try(getProperty o.GroupManager #Renderable)catch(true) then --assume true if TP 2.5 which does not have #Renderable property
					append ActiveTPGroups #(o.GroupManager, o.name + ".All")
				else	
					append InactiveTPGroups #(o.GroupManager, o.name + ".All")
				theBase = if chk_showFullHierarchy.checked then ".All" else ""
				getSubGroups o theBase o.GroupManager
			)
		)
		lbx_allGroups.items = for i in ActiveTPGroups collect i[2] 
		lbx_inactiveGroups.items = for i in InactiveTPGroups collect i[2] 
	)	

	fn addGroups =
	(
		local theSel = lbx_inactiveGroups.selection as array
		for i = theSel.count to 1 by -1 do
			try(setProperty InactiveTPGroups[theSel[i]][1] #Renderable true)catch()
		populateLists()			
	)
	
	fn removeGroups =
	(
		local theSel = lbx_allGroups.selection as array
		for i = theSel.count to 1 by -1 do
			try(setProperty activeTPGroups[theSel[i]][1] #Renderable false)catch()
		populateLists()	
	)
	
	fn registerCallbacks =
	(
		FranticParticles.LogDebug ">Registering Callbacks..."
		local theTP = for o in objects where classof o == Thinking collect o
		deleteAllChangeHandlers id:#KrakatoaTPMonitor 
		if theTP.count > 0 do 
			when parameters theTP change id:#KrakatoaTPMonitor do populateLists()
	)
	fn unregisterCallbacks =
	(
		FranticParticles.LogDebug ">Unregistering Callbacks..."
		deleteAllChangeHandlers id:#KrakatoaTPMonitor 
	)		
	
	on btn_GroupAdd pressed do addGroups()
	on btn_GroupRemove pressed do removeGroups() 

	on lbx_allGroups doubleClicked itm do removeGroups()
	on lbx_inactiveGroups doubleClicked itm do addGroups()
	
	on btn_allAll pressed do lbx_allGroups.selection = #{1..lbx_allGroups.items.count}
	on btn_allInvert pressed do lbx_allGroups.selection = #{1..lbx_allGroups.items.count} - lbx_allGroups.selection

	on btn_inactiveAll pressed do lbx_inactiveGroups.selection = #{1..lbx_inactiveGroups.items.count}
	on btn_inactiveInvert pressed do lbx_inactiveGroups.selection = #{1..lbx_inactiveGroups.items.count} - lbx_inactiveGroups.selection
	
	on chk_showFullHierarchy changed state do populateLists()	


	fn refresh_GUI =
	(
		if Krakatoa_GUI_ThinkingParticles.open do registerCallbacks()
		populateLists()
		
		/*if Krakatoa_Initializing_Hidden_Rollouts == false do 
			Krakatoa_GUI_ThinkingParticles.open = FranticParticles.GetBoolProperty "GUI:ThinkingParticlesRolloutOpen"*/
	)	

	fn updateIcons =
	(
		btn_GroupAdd.images = #(Krakatoa_PresetsArrowBitmap,Krakatoa_PresetsArrowBitmap, 32,6,6,8,8)
		btn_GroupRemove.images = #(Krakatoa_PresetsArrowBitmap,Krakatoa_PresetsArrowBitmap, 32,7,7,9,9)
	)	
	
	on btn_TPGroupsUpdate pressed do 
	(
		registerCallbacks()
		populateLists()
	)	

	on Krakatoa_GUI_ThinkingParticles open do 
	(
		updateIcons()
		Refresh_GUI()
		FranticParticles.LogDebug ("+Thinking Particles Rollout OPENED.")			
	)	
	
	on Krakatoa_GUI_ThinkingParticles rolledUp val do 
	(
		FranticParticles.SetProperty "GUI:ThinkingParticlesRolloutOpen" val		
		if val then 
		(
			FranticParticles.LogDebug ("+Thinking Particles Rollout ROLLED DOWN.")
			registerCallbacks()
			populateLists()
		)	
		else
		(
			FranticParticles.LogDebug ("+Thinking Particles Rollout ROLLED UP.")	
			unregisterCallbacks()
		)	
	)			
)

--------------------------------------------------------------------------------------------------------------------------------------------------------------------	
--PARTICLE SYSTEMS ROLLOUT
--------------------------------------------------------------------------------------------------------------------------------------------------------------------	

rollout Krakatoa_GUI_Particles "Scene Particle Systems" category:1000 width:457
(
	local KrakatoaParticleSystemsList = #()
	
	button btn_Help_Systems  "Open Online Help..." width:450 height:16 align:#center offset:[0,-5] across:1 tooltip:"Opens the Krakatoa Online Help for the Scene Particle Systems rollout in the default Web Browser. Requires Internet connection."

	on Krakatoa_GUI_Particles moved pos do
	(
		setIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "RolloutDialogPositions" Krakatoa_GUI_Particles.title (pos as string)
		--Krakatoa_CustomizeRollouts_Dialog.updateStripsPositions pos
	)	
	
	checkbutton chb_synchSelections ">Synch. Selection" width:150 offset:[-8,0] align:#left checked:true highlightcolor:KrakatoaSkinColorsStruct.Systems across:3 tooltip:"When checked, selecting objects from the list will update the scene selection.\n\nWhen unchecked, the scene selection will not be synchronized to the list selection.\n\nHowever, selecting objects in the scene will always update the list's selection regardless of the state of this option."
	dropdownlist ddl_displayInfo \
	items:#("None","Particle Flow Systems","Geometry Vertices","Legacy Particles","Thinking Particles","PRT Loader Objects","PRT Volume Objects","PRT FumeFX Objects","PRT Hair Objects","PRT Maker Objects","PRT Source Objects","PRT Surface Objects","Stoke Objects","All Sources") \
	width:142 align:#center offset:[2,0] tooltip:"Display the following Particle Sources..." height:20
	checkbutton chb_showEnabledOnly ">Show Only Enabled Types" width:150 align:#right highlightcolor:KrakatoaSkinColorsStruct.Systems offset:[10,0] tooltip:"When checked, only particle source types enabled for rendering via the Krakatoa Main Controls rollout will be displayed.\n\nWhen unchecked, any sources specified by the source type drop-down list on the left will be listed, even if they are not enabled for rendering."
	
	multilistbox lbx_particleSystemsInScene height:20 width:450 align:#center offset:[0,-3]
	
	button btn_selectAll "Select All Sources" width:140 align:#left across:3 offset:[0,-3]
	button btn_deselectAll "Deselect All Sources" width:140 align:#center offset:[0,-3]
	button btn_selectInvert "Invert Sources Selection" width:140 align:#right offset:[0,-3]
	
	button btn_hideSelected "Hide Selected Sources" width:140 align:#left across:3 offset:[0,-3]
	button btn_unhideSelected "Unhide Selected Sources" width:140 align:#center offset:[0,-3]
	button btn_selectHidden "Select Hidden Sources" width:140 align:#right offset:[0,-3]

	

	fn registerSelectionCallback =
	(
		 callbacks.addScript #selectionSetChanged "try(Krakatoa_GUI_Particles.synchSelectionFromScene())catch()" id:#Krakatoa_ParticlesSelectionMonitor
	)
	
	fn registerSceneNodeCallbacks =
	(
		 callbacks.addScript #nodePostDelete "try(Krakatoa_GUI_Particles.nodesChanged())catch()" id:#Krakatoa_ParticlesCreationDeletionMonitor
		 callbacks.addScript #nodeCreated "try(Krakatoa_GUI_Particles.nodesChanged())catch()" id:#Krakatoa_ParticlesCreationDeletionMonitor
		 callbacks.addScript #nodeRenamed "try(Krakatoa_GUI_Particles.nodesChanged())catch()" id:#Krakatoa_ParticlesCreationDeletionMonitor
		 callbacks.addScript #nodeHide "try(Krakatoa_GUI_Particles.nodesChanged())catch()" id:#Krakatoa_ParticlesCreationDeletionMonitor
		 callbacks.addScript #nodeUnhide "try(Krakatoa_GUI_Particles.nodesChanged())catch()" id:#Krakatoa_ParticlesCreationDeletionMonitor
		 if (maxVersion())[1] >=8000 do callbacks.addScript #sceneUndo "try(Krakatoa_GUI_Particles.nodesChanged())catch()" id:#Krakatoa_ParticlesCreationDeletionMonitor
	)
	
	fn registerWhenConstructMonitor =
	(
		deleteAllChangeHandlers id:#Krakatoa_ParticlesParametersMonitor
		theBOs = for o in KrakatoaParticleSystemsList collect o.baseobject --we have to monitor just the base objects to avoid updates on node PRS changes!
		when parameters theBOs change id:#Krakatoa_ParticlesParametersMonitor do Krakatoa_GUI_Particles.nodesChanged()
	)
	
	fn synchSelectionToScene =
	(
		callbacks.removeScripts id:#Krakatoa_ParticlesSelectionMonitor
		max select none
		select (for i in lbx_particleSystemsInScene.selection where isValidNode KrakatoaParticleSystemsList[i] collect KrakatoaParticleSystemsList[i])
		registerSelectionCallback()
	)
	
	fn synchSelectionFromScene =
	(
		lbx_particleSystemsInScene.selection = (for o in selection where findItem KrakatoaParticleSystemsList o > 0 collect findItem KrakatoaParticleSystemsList o) as bitarray
	)
	
	

	fn updateParticlesList =
	(
		if Krakatoa_GUI_Particles.open do
		(
			local st = timestamp()
			FranticParticles.logDebug (">Populating Particle Systems List with " + ddl_displayInfo.selected )
			local legacyParticles = #(PArray, PCloud, SuperSpray, Blizzard, Snow, Spray)
			local theSystems = #()
			KrakatoaParticleSystemsList = #()
			local KrakatoaParticleSystemsText = #()
			local selectAllIndex = ddl_displayInfo.items.count
			
			if ddl_displayInfo.selection == selectAllIndex or ddl_displayInfo.selection == 2 do
			(
				if not chb_showEnabledOnly.checked OR FranticParticles.GetBoolProperty "RenderParticleFlowGeometry" or FranticParticles.GetBoolProperty "RenderParticleFlowBBox" or FranticParticles.GetBoolProperty "RenderParticleFlowPhantom" do
				(
					theSystems = (for o in objects where classof o == PF_Source collect o)
					join KrakatoaParticleSystemsList theSystems
					for o in theSystems do 
					(
						hiddenFlag = if o.isHiddenInVpt then "--" else "+"
						actualAmount = requestedAmount = (o.numParticles() / o.Quantity_Viewport * o.Quantity_Render) as integer
						if requestedAmount > o.Particle_Amount_Limit do actualAmount = o.Particle_Amount_Limit
						append KrakatoaParticleSystemsText (hiddenFlag + "["+o.name+"] - <PF Source> - Req.:" + FranticParticleRenderMXS.addCommas (requestedAmount as string) + "  Limit:" + FranticParticleRenderMXS.addCommas (o.Particle_Amount_Limit as string) + "  Actual:" + FranticParticleRenderMXS.addCommas (actualAmount as string))
					)	
				)	
			)	
			
			if ddl_displayInfo.selection == selectAllIndex or ddl_displayInfo.selection == 3 do	
			(
				if not chb_showEnabledOnly.checked OR FranticParticles.GetBoolProperty "RenderGeometryVertices" do
				(
					local useNamedSelectionSets = execute (FranticParticles.GetProperty "Matte:NamedSelectionSets")
					local matteSelSets = for i = 1 to selectionSets.count where findItem useNamedSelectionSets (getNamedSelSetName i) != 0 collect selectionSets[i]
					local matteObjects = #()
					for i in matteSelSets do 
						join matteObjects (for o in i collect o)
					
					theSystems = (for o in objects where findItem GeometryClass.classes (classof o) > 0 AND (findItem #(TargetObject, Thinking, FumeFX, PRT_FumeFX, PRT_Hair, PRT_Maker, PRT_Source, PRT_System, ParticleGroup, PF_Source, KrakatoaPrtLoader, PRT_Volume, PRT_Surface, Stoke ) (classof o.baseobject) == 0 )  AND o.renderable AND findItem KrakatoaParticleSystemsList o == 0 AND findItem legacyParticles (classof o) == 0 AND findItem matteObjects o == 0 collect o)
					join KrakatoaParticleSystemsList theSystems 
					for o in theSystems do 
					(
						theMeshCount = getTrimeshFaceCount o
						hiddenFlag = if o.isHiddenInVpt then "--" else "+"
						append KrakatoaParticleSystemsText (hiddenFlag + "["+o.name+"] - <"+ (classof o) as string +"> - Vertices:" + FranticParticleRenderMXS.addCommas ( theMeshCount[2] as string) )
					)	
				)
			)	
			
			if ddl_displayInfo.selection == selectAllIndex or ddl_displayInfo.selection == 4 do
			(
				if not chb_showEnabledOnly.checked OR FranticParticles.GetBoolProperty "RenderMaxParticles" do	
				(
					theSystems = (for o in objects where findItem legacyParticles (classof o) > 0 collect o)
					join KrakatoaParticleSystemsList theSystems 
					for o in theSystems do 
					(
						hiddenFlag = if o.isHiddenInVpt then "--" else "+"
						theVCount = particleCount o
						if isProperty o "viewPercent" then theVCount *= 100.0 / o.viewPercent 
						theVCount = (floor (theVCount+0.5)) as integer
						append KrakatoaParticleSystemsText (hiddenFlag + "["+o.name+"] - <3ds Max Legacy Particles> - Particles:" +  FranticParticleRenderMXS.addCommas (theVCount as string) )
					)	
				)
			)

			if ddl_displayInfo.selection == selectAllIndex or ddl_displayInfo.selection == 5 do
			(
				if not chb_showEnabledOnly.checked OR FranticParticles.GetBoolProperty "RenderThinkingParticles" do
				(
					theSystems = (for o in objects where classof o.baseobject == Thinking collect o)
					join KrakatoaParticleSystemsList theSystems
					for o in theSystems do 
					(
						append KrakatoaParticleSystemsText ("+["+o.name+"] - <Thinking Particles Container> ")
					)	
				)	
			)	
			
			if ddl_displayInfo.selection == selectAllIndex or ddl_displayInfo.selection == 8 do			
			(
				if not chb_showEnabledOnly.checked OR FranticParticles.GetBoolProperty "RenderFumeFX" do
				(
					theSystems = (for o in objects where classof o.baseobject == PRT_FumeFX collect o) --((findItem KrakatoaParticleSystemsList o) == 0) AND classof o != PF_Source AND classof o != Thinking AND (try(o.ParticleObjectExt;true)catch(false)) AND classof o != ParticleGroup collect o)
					join KrakatoaParticleSystemsList theSystems 
					for o in theSystems do 
					(
						hiddenFlag = if o.isHiddenInVpt then "--" else "+"
						append KrakatoaParticleSystemsText (hiddenFlag + "["+o.name+"] - <PRT FumeFX> ")
					)	
				)	
			)	
			
			if ddl_displayInfo.selection == selectAllIndex or ddl_displayInfo.selection == 7 do			
			(
				if not chb_showEnabledOnly.checked OR FranticParticles.GetBoolProperty "RenderGeometryVolumes" do
				(
					theSystems = (for o in objects where findItem GeometryClass.classes (classof o) > 0 AND FranticParticleRenderMXS.isGeoVolume o AND o.renderable AND findItem KrakatoaParticleSystemsList o == 0 collect o)
					join KrakatoaParticleSystemsList theSystems 
					for o in theSystems do 
					(
						local hiddenFlag = if o.isHiddenInVpt then "--" else "+"
						append KrakatoaParticleSystemsText (hiddenFlag + "["+o.name+"] - <PRT Volume>")
					)	
				)	
			)	

			if ddl_displayInfo.selection == selectAllIndex or ddl_displayInfo.selection == 6 do			
			(
				if not chb_showEnabledOnly.checked OR FranticParticles.GetBoolProperty "RenderKrakatoaLoaders" do
				(
					theSystems = (for o in objects where findItem GeometryClass.classes (classof o) > 0 AND FranticParticleRenderMXS.isPRTLoader o AND o.renderable AND findItem KrakatoaParticleSystemsList o == 0 collect o)
					join KrakatoaParticleSystemsList theSystems 
					for o in theSystems do 
					(
						local hiddenFlag = if o.isHiddenInVpt then "--" else "+"
						append KrakatoaParticleSystemsText (hiddenFlag + "["+o.name+"] - <PRT Loader>")
					)	
				)	
			)		

			if ddl_displayInfo.selection == selectAllIndex or ddl_displayInfo.selection == 9 do			
			(
				if not chb_showEnabledOnly.checked OR FranticParticles.GetBoolProperty "RenderPRTHair" do
				(
					theSystems = (for o in objects where classof o.baseobject == PRT_Hair AND o.renderable AND findItem KrakatoaParticleSystemsList o == 0 collect o)
					join KrakatoaParticleSystemsList theSystems 
					for o in theSystems do 
					(
						local hiddenFlag = if o.isHiddenInVpt then "--" else "+"
						append KrakatoaParticleSystemsText (hiddenFlag + "["+o.name+"] - <PRT Hair>")
					)	
				)	
			)	

			if ddl_displayInfo.selection == selectAllIndex or ddl_displayInfo.selection == 10 do			
			(
				if not chb_showEnabledOnly.checked OR FranticParticles.GetBoolProperty "RenderPRTCreator" do
				(
					theSystems = (for o in objects where classof o.baseobject == PRT_Maker AND o.renderable AND findItem KrakatoaParticleSystemsList o == 0 collect o)
					join KrakatoaParticleSystemsList theSystems 
					for o in theSystems do 
					(
						local hiddenFlag = if o.isHiddenInVpt then "--" else "+"
						append KrakatoaParticleSystemsText (hiddenFlag + "["+o.name+"] - <PRT Maker>")
					)	
				)	
			)		

			if ddl_displayInfo.selection == selectAllIndex or ddl_displayInfo.selection == 11 do			
			(
				if not chb_showEnabledOnly.checked OR FranticParticles.GetBoolProperty "RenderPRTSource" do
				(
					theSystems = (for o in objects where classof o.baseobject == PRT_Source AND o.renderable AND findItem KrakatoaParticleSystemsList o == 0 collect o)
					join KrakatoaParticleSystemsList theSystems 
					for o in theSystems do 
					(
						local hiddenFlag = if o.isHiddenInVpt then "--" else "+"
						append KrakatoaParticleSystemsText (hiddenFlag + "["+o.name+"] - <PRT Source>")
					)	
				)	
			)	
			
			if ddl_displayInfo.selection == selectAllIndex or ddl_displayInfo.selection == 12 do			
			(
				if not chb_showEnabledOnly.checked OR FranticParticles.GetBoolProperty "RenderPRTSurface" do
				(
					theSystems = (for o in objects where classof o.baseobject == PRT_Surface AND o.renderable AND findItem KrakatoaParticleSystemsList o == 0 collect o)
					join KrakatoaParticleSystemsList theSystems 
					for o in theSystems do 
					(
						local hiddenFlag = if o.isHiddenInVpt then "--" else "+"
						append KrakatoaParticleSystemsText (hiddenFlag + "["+o.name+"] - <PRT Surface>")
					)	
				)	
			)		

			if ddl_displayInfo.selection == selectAllIndex or ddl_displayInfo.selection == 13 do			
			(
				if not chb_showEnabledOnly.checked OR FranticParticles.GetBoolProperty "RenderStoke" do
				(
					theSystems = (for o in objects where classof o.baseobject == Stoke AND o.renderable AND findItem KrakatoaParticleSystemsList o == 0 collect o)
					join KrakatoaParticleSystemsList theSystems 
					for o in theSystems do 
					(
						local hiddenFlag = if o.isHiddenInVpt then "--" else "+"
						append KrakatoaParticleSystemsText (hiddenFlag + "["+o.name+"] - <Stoke>")
					)	
				)	
			)	
			
			lbx_particleSystemsInScene.items = KrakatoaParticleSystemsText 
			if ddl_displayInfo.selection > 1 do FranticParticles.logDebug (" +Particle Systems List POPULATED in " + (timestamp() - st) as string + "ms." )
		)
	)
	
	fn nodesChanged =
	(
		if Krakatoa_GUI_Particles.open do
		(
			updateParticlesList()
			registerWhenConstructMonitor()
		)	
	)		
	
	on ddl_displayInfo selected itm do updateParticlesList()

	fn refresh_GUI =
	(
			
		updateParticlesList()
		
		if Krakatoa_Initializing_Hidden_Rollouts == false do 
			Krakatoa_GUI_Particles.open = FranticParticles.GetBoolProperty "GUI:ParticleSystemsRolloutOpen"
	)
	
	on btn_selectAll pressed do
	(
		--updateParticlesList ()
		lbx_particleSystemsInScene.selection = #{1..(lbx_particleSystemsInScene.items.count)}
		if chb_synchSelections.state do synchSelectionToScene()
	)
	
	on btn_deselectAll pressed do
	(
		--updateParticlesList ()
		lbx_particleSystemsInScene.selection = #{}
		if chb_synchSelections.state do synchSelectionToScene()
	)

	on btn_selectInvert pressed do
	(
		--updateParticlesList ()
		lbx_particleSystemsInScene.selection = -lbx_particleSystemsInScene .selection
		if chb_synchSelections.state do synchSelectionToScene()
	)			
	
	on lbx_particleSystemsInScene selectionEnd do if chb_synchSelections.state do synchSelectionToScene()
	
	on btn_hideSelected pressed do
	(
		hide (for i in lbx_particleSystemsInScene.selection collect KrakatoaParticleSystemsList[i])
		--updateParticlesList()
	)
	on btn_unhideSelected pressed do
	(
		unhide (for i in lbx_particleSystemsInScene.selection collect KrakatoaParticleSystemsList[i])
		--updateParticlesList()
	)
	
	on btn_selectHidden pressed do
	(
		--updateParticlesList()
		lbx_particleSystemsInScene.selection = (for i = 1 to lbx_particleSystemsInScene.items.count where KrakatoaParticleSystemsList[i].isHiddenInVpt collect i)
		if chb_synchSelections.state do 
			select (for i = 1 to lbx_particleSystemsInScene.items.count where KrakatoaParticleSystemsList[i].isHiddenInVpt collect KrakatoaParticleSystemsList[i])
	)
	
	
	on chb_showEnabledOnly changed state do updateParticlesList()


	on Krakatoa_GUI_Particles rolledUp val do 
	(
		FranticParticles.SetProperty "GUI:ParticleSystemsRolloutOpen" val		
			if val then 
				FranticParticles.LogDebug ("+Particle Systems Rollout ROLLED DOWN.")
			else
				FranticParticles.LogDebug ("+Particle Systems Rollout ROLLED UP.")	
	)			
	
	on Krakatoa_GUI_Particles close do 
	(
		 callbacks.removeScripts id:#Krakatoa_ParticlesSelectionMonitor
		 callbacks.removeScripts id:#Krakatoa_ParticlesCreationDeletionMonitor
		 deleteAllChangeHandlers id:#Krakatoa_ParticlesParametersMonitor		
	)	
	
	fn updateIcons =
	(
		--btn_Float_Rollout.images = #(Krakatoa_PresetsArrowBitmap,Krakatoa_PresetsArrowBitmap, 32,4,4,4,4)		
	)	

	on Krakatoa_GUI_Particles open do 
	(
		Krakatoa_CustomizeRollouts_Dialog.Refresh_GUI()
		
		updateIcons()
		refresh_GUI()
		callbacks.removeScripts id:#Krakatoa_ParticlesSelectionMonitor
		registerSelectionCallback()

		callbacks.removeScripts id:#Krakatoa_ParticlesCreationDeletionMonitor
		registerSceneNodeCallbacks()
		 
		registerWhenConstructMonitor()		
		FranticParticles.LogDebug ("+Scene Particles Rollout OPENED.")			
	)			
	
)--end rollout


macroScript KrakatoaExplorers category:"Krakatoa" tooltip:"Tools For Exploring the Content Of The Scene" buttontext:"Krakatoa Scene Explorers" icon:#("Krakatoa",21)
(
	global Krakatoa_SceneExplorersFloater 
	on isEnabled return renderers.current.classid as string == "#(-1204370534, -399920359)" or renderers.current.classid as string == "#(3090596762L, 3895046937L)"
		
	on execute do
	(
		try(closeRolloutFloater ::Krakatoa_SceneExplorersFloater )catch()
		local thePos = execute (getIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "RolloutDialogPositions" ::Krakatoa_GUI_ParticleLoaders.title )
		if thePos == OK do thePos = [100,100]
		local theDesktop = sysInfo.DesktopSize
		if thePos.x > theDesktop.x-470 do thePos.x = theDesktop.x-470
		if thePos.x < 0 do thePos.x = 0
			
		if thePos.y > theDesktop.y-470 do thePos.y = theDesktop.y-470
		if thePos.y < 0 do thePos.y = 0

		Krakatoa_SceneExplorersFloater = newRolloutFloater "Krakatoa Explorers" 470 700 thePos.x thePos.y
		
		addRollout Krakatoa_GUI_ParticleLoaders Krakatoa_SceneExplorersFloater rolledup:((for o in selection where classof o.baseobject == KrakatoaPRTLoader collect o).count == 0)
		addRollout Krakatoa_GUI_Particles Krakatoa_SceneExplorersFloater rolledup:true
		addRollout Krakatoa_GUI_PRTVolumeExplorer Krakatoa_SceneExplorersFloater rolledup:((for o in selection where classof o.baseobject == PRT_Volume collect o).count == 0)
		addRollout Krakatoa_GUI_PRTFumeExplorer Krakatoa_SceneExplorersFloater rolledup:((for o in selection where classof o.baseobject == PRT_FumeFX or classof o.baseobject == FumeFX collect o).count == 0)
		addRollout Krakatoa_GUI_PRTHairExplorer Krakatoa_SceneExplorersFloater rolledup:((for o in selection where classof o.baseobject == PRT_Hair collect o).count == 0)
		
		if findItem geometryClass.classes thinking > 0  do 
			addRollout Krakatoa_GUI_ThinkingParticles Krakatoa_SceneExplorersFloater rolledup:true
		
	)
)
