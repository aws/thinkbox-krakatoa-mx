-- Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
-- SPDX-License-Identifier: Apache-2.0
macroScript PRTClonerMan category:"Krakatoa" tooltip:"PRT Cloner Manager Dialog" buttontext:"PRTC Man"
(
	global Krakatoa_PRTCloner_Dialog 
	try(destroyDialog Krakatoa_PRTCloner_Dialog )catch()
		
	rollout Krakatoa_PRTCloner_Dialog  "Krakatoa PRT Cloner Manager"	
	(
		local thePRTCloners = #()
		local currentClones  = #()
		local currentTarget = undefined
		local currentCloner = undefined
		
		
		fn theSBNFilter o=
		(
			o != currentCloner and o != currenttarget and findItem currentClones o == 0 and findItem #(KrakatoaPRTLoader, PRT_Volume, PRT_FumeFX, PRT_Hair, PRT_Source, PRT_Maker, PRT_Cloner) (classof o) > 0
		)
		
		fn thePickFilter o =
		(
			o != currentCloner and findItem #(KrakatoaPRTLoader, PRT_Volume, PRT_FumeFX, PRT_Hair, PRT_Source, PRT_Maker, PRT_Cloner) (classof o) > 0
		)	
		
		dropdownlist ddl_PRTCloners width:190 align:#left offset:[-5,-3] across:3
		button btn_update "Update" width:50 align:#right offset:[-10,-3]
		button btn_createPRTC "Create PRT Cloner Object" width:140 align:#right offset:[7,-3]

		pickbutton pck_TargetNode ">>Pick Target (Distribution) PRT Object..." width:384 align:#center autoDisplay:true filter:thePickFilter
		
		button btn_addNode "Add Clones..." width:80 across:4 align:#right offset:[100,0] tooltip:"Add one or more PRT Objects to the Clone list."
		button btn_moveUp "Up" width:40 align:#right offset:[50,0] tooltip:"Move a single highlighted Clone PRT object UP the list."
		button btn_moveDown "Down" width:40 align:#right offset:[-2,0] tooltip:"Move a single highlighted Clone PRT object DOWN the list."
		button btn_deleteNodes "Delete Clones" align:#right width:100 offset:[7,0] tooltip:"DELETE one or more highlighted Clone PRT objects from the list."
		
		multilistbox mlb_CloneNodes " PRT Objects to Clone:" width:390 align:#center offset:[0,-20]
		
		checkbutton chk_SetScale ">Set Scale" across:2 align:#left width:160 offset:[0,-5]
		spinner spn_ScaleFactor "Scale Factor:" type:#float fieldwidth:50 align:#right
		
		checkbutton chk_ViewportLoadEveryNth ">Load Every Nth" across:2 align:#left offset:[0,-3] width:160
		spinner spn_ViewportPercentage "Viewport Percentage:" range:[0,100,100] type:#float fieldwidth:50
		
		checkbutton chk_CompensateDensity ">Compenstate Density" align:#left across:2 width:160 offset:[0,-3]
		spinner spn_ViewportLimit "Viewport Limit (x1000):" type:#float fieldwidth:50

		dropdownlist ddl_ViewportMode items:#("Viewport Mode: Normal", "Viewport Mode: PassThrough","Viewport Mode: None") align:#left width:160 offset:[0,-3] across:2
		spinner spn_ViewportSourcePercentage "Viewport Clone Percentage:" range:[0,100,100] type:#float fieldwidth:50 align:#right 

		
		fn collectPRTCloners =
		(
			thePRTCloners = for o in objects where classof o.baseobject == PRT_Cloner collect o
			ddl_PRTCloners.items = for o in thePRTCloners collect o.name
			ddl_PRTCloners.selection = ddl_PRTCloners.items.count
		)
		
		fn updateObjectProperties =
		(
			if ddl_PRTCloners.selection  > 0 do
			(
				local theObj = thePRTCloners[ddl_PRTCloners.selection ]
				if isValidNode theObj then
				(
					currentCloner = theObj
					pck_TargetNode.object = theObj.targetNode
					currentTarget = theObj.targetNode
					currentClones = for i in theObj.CloneNodes collect i
					mlb_CloneNodes.items = for i in theObj.CloneNodes collect i.name
					chk_CompensateDensity.state = theObj.CompensateDensity
					ddl_ViewportMode.selection = theObj.ViewportMode+1
					chk_SetScale.state = theObj.SetScale
					spn_ScaleFactor.value = theObj.ScaleFactor
					spn_ViewportLimit.value = theObj.ViewportLimit
					spn_ViewportPercentage.value = theObj.ViewportPercentage
					chk_ViewportLoadEveryNth.state = theObj.ViewportLoadEveryNth
					spn_ViewportSourcePercentage.value = theObj.ViewportSourcePercentage
					btn_moveUp.enabled = btn_moveDown.enabled = btn_deleteNodes.enabled = currentClones.count > 0
				)
				else currentTarget = undefined
			)
			btn_moveUp.enabled = btn_moveDown.enabled = btn_deleteNodes.enabled = ddl_ViewportMode.enabled = spn_ViewportSourcePercentage.enabled = chk_ViewportLoadEveryNth.enabled = btn_addNode.enabled = mlb_CloneNodes.enabled = chk_CompensateDensity.enabled = chk_SetScale.enabled = spn_ScaleFactor.enabled = spn_ViewportLimit.enabled = spn_ViewportPercentage.enabled = isValidNode currentTarget
		)
		
		fn applySettingsToObject =
		(
			if ddl_PRTCloners.selection  > 0 do
			(
				local theObj = thePRTCloners[ddl_PRTCloners.selection ]
				if isValidNode theObj do
				(
					currentCloner = theObj
					theObj.targetNode = pck_TargetNode.object 
					theObj.CompensateDensity = chk_CompensateDensity.state 
					theObj.ViewportMode = ddl_ViewportMode.selection - 1
					theObj.SetScale = chk_SetScale.state 
					theObj.ScaleFactor = spn_ScaleFactor.value 
					theObj.ViewportLimit = spn_ViewportLimit.value 
					theObj.ViewportPercentage = spn_ViewportPercentage.value 
					theObj.ViewportLoadEveryNth = chk_ViewportLoadEveryNth.state 
					theObj.ViewportSourcePercentage = spn_ViewportSourcePercentage.value 
				)
			)		
		)
		
		on ddl_PRTCloners selected itm do
		(
			if ddl_PRTCloners.selection  > 0 do
			(
				local theObj = thePRTCloners[ddl_PRTCloners.selection ]
				if isValidNode theObj do
				(
					currentCloner = theObj
					select currentCloner 
					updateObjectProperties()
				)
			)
		)
		
		on btn_createPRTC pressed do
		(
			PRT_Cloner()
			collectPRTCloners()
			updateObjectProperties()
		)
		
		on btn_addNode pressed do
		(
			if ddl_PRTCloners.selection  > 0 do
			(
				local theObj = thePRTCloners[ddl_PRTCloners.selection ]
				if isValidNode theObj do
				(
					currentCloner = theObj
					theSelNodes = selectByName showHidden:true filter:theSBNFilter
					if theSelNodes != undefined do
					(
						theOldNodes = for i in theObj.cloneNodes collect i
						for i in theSelNodes do appendIfUnique theOldNodes i
						theObj.cloneNodes = theOldNodes
						updateObjectProperties()
					)
				)
			)
		)
		
		on btn_update pressed do
		(
			collectPRTCloners()
			updateObjectProperties()
		)
		
		on btn_deleteNodes pressed do
		(
			if ddl_PRTCloners.selection  > 0 do
			(
				local theObj = thePRTCloners[ddl_PRTCloners.selection ]
				if isValidNode theObj do
				(
					currentCloner = theObj				
					theSelNodes = mlb_CloneNodes.selection as array
					theOldNodes = for i in theObj.cloneNodes collect i
					for i = 	theSelNodes.count to 1 by -1 do deleteItem theOldNodes i
					theObj.cloneNodes = theOldNodes
					updateObjectProperties()
				)
			)		
		)
		
		on btn_moveUp pressed do
		(
			if ddl_PRTCloners.selection  > 0 do
			(
				local theObj = thePRTCloners[ddl_PRTCloners.selection ]
				if isValidNode theObj do
				(
					local theSelNodes = mlb_CloneNodes.selection as array
					if theSelNodes.count == 1 and theSelNodes[1] > 1 do 
					(
						theOldNodes = for i in theObj.cloneNodes collect i
						theNode1 = theOldNodes[theSelNodes[1]-1]
						theOldNodes[theSelNodes[1]-1] = theOldNodes[theSelNodes[1]]
						theOldNodes[theSelNodes[1]] = theNode1 
						theObj.cloneNodes = theOldNodes
						updateObjectProperties()
						mlb_CloneNodes.selection = #{theSelNodes[1]-1}
					)
				)
			)
		)
		
		on btn_moveDown pressed do
		(
			if ddl_PRTCloners.selection  > 0 do
			(
				local theObj = thePRTCloners[ddl_PRTCloners.selection ]
				if isValidNode theObj do
				(
					local theSelNodes = mlb_CloneNodes.selection as array
					if theSelNodes.count == 1 and theSelNodes[1] < theObj.cloneNodes.count do 
					(
						theOldNodes = for i in theObj.cloneNodes collect i
						theNode1 = theOldNodes[theSelNodes[1]+1]
						theOldNodes[theSelNodes[1]+1] = theOldNodes[theSelNodes[1]]
						theOldNodes[theSelNodes[1]] = theNode1 
						theObj.cloneNodes = theOldNodes
						updateObjectProperties()
						mlb_CloneNodes.selection = #{theSelNodes[1]+1}
					)
				)
			)
		)		
		
		on pck_TargetNode picked obj do 
		(
			applySettingsToObject()
			updateObjectProperties()
		)
		on chk_CompensateDensity changed state do applySettingsToObject()
		on ddl_ViewportMode selected imt do applySettingsToObject()
		on chk_SetScale changed state do applySettingsToObject()
		on spn_ScaleFactor changed val do applySettingsToObject()
		on spn_ViewportLimit changed val do applySettingsToObject()
		on spn_ViewportPercentage changed val do applySettingsToObject() 
		on chk_ViewportLoadEveryNth changed state do applySettingsToObject()
		on spn_ViewportSourcePercentage changed val do applySettingsToObject()

		on Krakatoa_PRTCloner_Dialog open do
		(
			collectPRTCloners()
			updateObjectProperties()
		)
		
		on Krakatoa_PRTMaker_Dialog close do
		(
		)

	)--end rollout

	createDialog Krakatoa_PRTCloner_Dialog width:400
)--emd macro

