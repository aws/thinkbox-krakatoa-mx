-- Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
-- SPDX-License-Identifier: Apache-2.0
(
	global MagmaFlowEditor_CurrentCurveControlRollout
	local MagmaFlowEditor_CurveControlRollout
	rollout MagmaFlowEditor_CurveControlRollout "Curve Operator" 
	(
		local magma = undefined
		local canSave = false
		local lastPoint = 0
		local theCI = undefined
		local theCurveNode = undefined
		local theThumbnailControl = undefined
		local parentEditor = undefined
		local loadControlCurveFromPreset
		
		edittext edt_presetName "" text:"Preset1" across:4 align:#left fieldwidth:200 offset:[-15,-3] enabled:true
		button btn_curvePresets ">>" width:25 height:18 align:#center offset:[35,-3] enabled:true
	
		spinner spn_minX "Min.X:" range:[-100000,100000,0] fieldwidth:50 align:#right offset:[10,-1]
		spinner spn_maxX "Max.X:" range:[-100000,100000,0] fieldwidth:50 align:#right offset:[10,-1]
		
		CurveControl crv_CurveControl  width:480 height:420 align:#center offset:[0,-2] numCurves:1 visible:true uiFlags:#(#drawBG,#drawgrid,#upperToolbar,#showReset,#lowerToolbar,#ruler)  
		
		spinner spn_inTangentX "In X:" type:#float range:[-100000,100000,0] fieldwidth:50 across:4 offset:[-2,-2] scale:0.01 enabled:false
		spinner spn_outTangentX "Out X:" type:#float range:[-100000,100000,0] fieldwidth:50 align:#right offset:[12,-2] scale:0.01 enabled:false
		spinner spn_inTangentY "In Y:" type:#float range:[-100000,100000,0] fieldwidth:50 offset:[-2,-3] scale:0.01 enabled:false
		spinner spn_outTangentY "Out Y:" type:#float range:[-100000,100000,0] fieldwidth:50 align:#right offset:[12,-3] scale:0.01 enabled:false
		
		button btn_flipHorizontal "Horizontal Flip" across:3 width:155 offset:[-10,-3] align:#left tooltip:"" 
		button btn_flipVertical "Vertical Flip" width:155 offset:[0,-3] align:#center 
		button btn_mirrorVertical "Mirror Vertically About X Axis" width:155 offset:[10,-3] align:#right 
		
		fn getTangents numPoints theActualPoint:0=
		(
			local theType = false
			if canSave do
			(
				if numPoints == 1 do 
				(
					aPoint = if theActualPoint == 0 then
						(for i = 1 to crv_CurveControl.curves[1].numPoints where crv_CurveControl.curves[1].points[i].selected collect i)[1]
					else
						theActualPoint
					local thePoint = crv_CurveControl.curves[1].points[aPoint]
					spn_inTangentX.value = thePoint.inTangent.x
					spn_inTangentY.value = thePoint.inTangent.y
					spn_outTangentX.value = thePoint.outTangent.x
					spn_outTangentY.value = thePoint.outTangent.y
					theType = thePoint.bezier
					lastPoint = aPoint
				)
				spn_inTangentX.enabled = spn_outTangentX.enabled = spn_inTangentY.enabled = spn_outTangentY.enabled = numPoints == 1 AND theType == true
			)
		)

		--reads the curve from the node and returns it as array for saving as preset
		fn getCurrentCurve =
		(
			local theArray = #()
			local theCount = theCI.getNumPoints()
			local theDomain = theCI.getDomain()
			local theMin = theDomain.x
			local theRange = theDomain.y - theDomain.x
			for i = 1 to theCount do
			(
				local theVal = theCI.getPointPos i
				local inTangent = theCI.getPointIn i
				inTangent.x = inTangent.x 
				local outTangent = theCI.getPointOut i
				outTangent.x = outTangent.x
				local theFlags = (theCI.getPointFlags i)
				append theArray #(theVal, inTangent, outTangent, bit.get theFlags 1, bit.get theFlags 2)
			)		
			theArray	
		)
		
		fn updatePresetName =
		(
			local theKeys = getIniSetting (Krakatoa_PresetsDirectory + "/MagmaFlowSettings/CurveControlPresets.ini") "Curves"
			sort theKeys
			local presetsList = for i in theKeys collect getIniSetting (Krakatoa_PresetsDirectory + "/MagmaFlowSettings/CurveControlPresets.ini") "Curves" i
			local theValue = with printAllElements true (getCurrentCurve()) as string
			local theIndex = findItem presetsList theValue 
			local theName = ""
			if theIndex > 0 then
			(
				theName = theKeys[theIndex]
			)
			else
			(
				local done = false
				while not done do
				(
					theName = "Preset" + (theKeys.count+1) as string
					if findItem theKeys theName == 0 do done = true
				)
			)
			edt_presetName.text = theName
			--if KrakatoaChannelNodeEditor_Rollout.chk_autoUpdateModifier.checked do KrakatoaChannelsEditor_Functions.updateParentModifier()
		)			
		
		fn createPresetsRCMenu =
		(
			global MagmaFlowEditor_CurrentCurveControlRollout = MagmaFlowEditor_CurveControlRollout
			local theKeys = getIniSetting (Krakatoa_PresetsDirectory + "/MagmaFlowSettings/CurveControlPresets.ini") "Curves"
			sort theKeys
			local presetsList = for i in theKeys collect getIniSetting (Krakatoa_PresetsDirectory + "/MagmaFlowSettings/CurveControlPresets.ini") "Curves" i
			
			if theKeys.count == 0 do
			(
				theKeys = #("Accelerate","Decelerate","SmoothStep")
				presetsList=#(
					"#(#([0,0], [0,0], [0,0], false, true), #([1,1], [0,-1], [0,0], true, true))",
					"#(#([0,0], [0,0], [0,0], false, true), #([1,1], [-1,0], [0,0], true, true))",
					"#(#([0,0], [0,0], [0.5,0], true, true), #([1,1], [-0.5,0], [0,0], true, true))"
				)
				for i = 1 to theKeys.count do
					setIniSetting (Krakatoa_PresetsDirectory + "/MagmaFlowSettings/CurveControlPresets.ini") "Curves" theKeys[i] (presetsList[i])
			)
			
			
			local theValue = with printAllElements true (getCurrentCurve()) as string
			
			local txt = "rcmenu Presets_RCMenu\n(\n"
			local theIndex = findItem presetsList theValue
			if theIndex == 0 do 
			(
				txt += "menuItem mnu_AddPreset \"Add ["+ edt_presetName.text +"]\"\n" 
				txt += "on mnu_AddPreset picked do (\n"
				txt += "setIniSetting (Krakatoa_PresetsDirectory + \"/MagmaFlowSettings/CurveControlPresets.ini\") \"Curves\" \""+ edt_presetName.text + "\" \""+ theValue +"\" \n"
				txt += "MagmaFlowEditor_CurrentCurveControlRollout.updatePresetName()\n"
				txt += ")\n"
				txt += "separator spr_01\n" 
			)
			
			for i = 1 to theKeys.count do
			(
				txt += "menuItem mnu_preset"+ i as string +" \"" + theKeys[i] + "\" \n" 
				txt += "on mnu_preset" + i as string + " picked do (\n"
				txt += "MagmaFlowEditor_CurrentCurveControlRollout.loadControlCurveFromPreset "+ presetsList[i] +"\n"
--				txt += "MagmaFlowEditor_CurrentCurveControlRollout.loadControlCurves()\n"
--				txt += "MagmaFlowEditor_CurrentCurveControlRollout.updatePresetName()\n"
				txt += ")\n"
			)
		
			if theIndex != 0 do 
			(
				txt += "separator spr_10\n" 
				
				if theKeys[theIndex] != edt_presetName.text then
				(
					txt += "menuItem mnu_RenamePreset \"Rename ["+ theKeys[theIndex] +"] to ["+ edt_presetName.text +"]\"\n" 
					txt += "on mnu_RenamePreset picked do (\n"
					txt += "delIniSetting (Krakatoa_PresetsDirectory + \"/MagmaFlowSettings/CurveControlPresets.ini\") \"Curves\" \""+ theKeys[theIndex] +"\" \n"
					txt += "setIniSetting (Krakatoa_PresetsDirectory + \"/MagmaFlowSettings/CurveControlPresets.ini\") \"Curves\" \""+ edt_presetName.text + "\" \""+ theValue +"\" \n"
					txt += "MagmaFlowEditor_CurrentCurveControlRollout.updatePresetName()\n"
					txt += ")\n"
				)
				else
				(
					txt += "menuItem mnu_RemovePreset \"Remove ["+ theKeys[theIndex] +"]\"\n" 
					txt += "on mnu_RemovePreset picked do (\n"
					txt += "delIniSetting (Krakatoa_PresetsDirectory + \"/MagmaFlowSettings/CurveControlPresets.ini\") \"Curves\" \""+ theKeys[theIndex] +"\" \n"
					--txt += "print \""+ theKeys[theIndex] +"\"\n"
					txt += "MagmaFlowEditor_CurrentCurveControlRollout.updatePresetName()\n"
					txt += ")\n"
				)
			)	
			
			txt += ")\n"
			execute txt
		)	
		

		
		
		--This function loads curves from the Curve node and disaplay in the CurveControl
		fn loadControlCurves =
		(
			canSave  = false
			crv_CurveControl.x_range = theCI.getDomain()
			local theCount = theCI.getNumPoints()
			crv_CurveControl.curves[1].numPoints = theCount
			crv_CurveControl.curves[1].animatable  = false
			crv_CurveControl.curves[1].color = blue
			crv_CurveControl.curves[1].width = 3
			local theDomain = theCI.getDomain()
			local theMin = theDomain.x
			local theRange = theDomain.y - theDomain.x
			
			for i = theCount to 1 by -1 do
			(
				local cp = crv_CurveControl.curves[1].points[i]
				local theVal = theCI.getPointPos i
				theVal.x = theVal.x * theRange + theMin
				cp.value = theVal 
				local inTangent = theCI.getPointIn i
				inTangent.x = inTangent.x * theRange --+ theMin
				cp.inTangent = inTangent
				local outTangent = theCI.getPointOut i
				outTangent.x = outTangent.x * theRange --+ theMin
				cp.outTangent = outTangent
				local theFlags = (theCI.getPointFlags i)
				--format "theFlags = %\n" theFlags
				cp.bezier = bit.get theFlags 1
				cp.corner = bit.get theFlags 2
				cp.lock_x = false 
				cp.lock_y = false
				cp.selected = lastPoint == i
				crv_CurveControl.curves[1].points[i] = cp
			)
			canSave = true		
			zoom crv_CurveControl #all			
		)
		
		fn loadControlCurveFromPreset theValueString =
		(
			--Load from disk, set in the Curve node
			--local theValueString = "#(#([0,0], [0,0], [0.5,0], true, true), #([1,1], [-0.5,0], [0,0], true, true))"
			local theValue = theValueString
			theCI.setNumPoints theValue.count
			local theDomain = theCI.getDomain()
			local theMin = theDomain.x
			local theRange = theDomain.y - theDomain.x
			for i = 1 to theValue.count do
			(
				local theFlags = 0
				theFlags = bit.set theFlags 1 theValue[i][4]
				theFlags = bit.set theFlags 2 theValue[i][5]
				local theVal = theValue[i][1]
				theVal.x = (theVal.x - theMin) --/ theRange
				local inTangent = theValue[i][2]
				inTangent.x = (inTangent.x) --/ theRange 
				local outTangent = theValue[i][3]
				outTangent.x = (outTangent.x) --/ theRange 
				theCI.setPoint i theVal inTangent outTangent theFlags
			)
			LoadControlCurves() --update the control
		)		

		on btn_curvePresets pressed do
		(
			global Presets_RCMenu = createPresetsRCMenu()
			--loadControlCurveFromPreset()
			popupMenu Presets_RCMenu pos:mouse.screenpos
		)
				

		--This function takes curves from the CurveControl and saves in the Curve Node
		fn SaveControlCurves =
		(
			if canSave do
			(
				try(
					local crv = crv_CurveControl.curves[1]
					theCI.setNumPoints crv.numPoints  
					local theDomain = theCI.getDomain()
					local theMin = theDomain.x
					local theRange = theDomain.y - theDomain.x
					for i = 1 to crv.numPoints  do
					(
						local theFlags = 0
						theFlags = bit.set theFlags 1 crv.points[i].bezier
						theFlags = bit.set theFlags 2 crv.points[i].corner
						local theVal = crv.points[i].value 
						theVal.x = (theVal.x - theMin) / theRange
						local inTangent = crv.points[i].inTangent
						inTangent.x = (inTangent.x) / theRange 
						local outTangent = crv.points[i].outTangent
						outTangent.x = (outTangent.x) / theRange 
						theCI.setPoint i theVal inTangent outTangent theFlags
					)
					updatePresetName()
				)catch(destroyDialog MagmaFlowEditor_CurveControlRollout)
			)
		)

		fn setTangents type = 
		(
			if lastPoint > 0 do
			(
				if type == #in do 
					if crv_CurveControl.curves[1].points[lastPoint].corner == true and  crv_CurveControl.curves[1].points[lastPoint].bezier == true then 
						crv_CurveControl.curves[1].points[lastPoint].inTangent = [spn_inTangentX.value,spn_inTangentY.value]
					else
						crv_CurveControl.curves[1].points[lastPoint].outTangent = -[spn_inTangentX.value,spn_inTangentY.value]
					
				if type == #out do crv_CurveControl.curves[1].points[lastPoint].outTangent = [spn_outTangentX.value,spn_outTangentY.value]
				saveControlCurves()
				getTangents 1
			)
		)	
		
		on spn_minX changed val do 
		(
			spn_maxX.range = [val+1,100000,spn_maxX.value]
			SaveControlCurves()
			theCI.setDomain [spn_minX.value, spn_maxX.value]
			loadControlCurves()
		)
		on spn_maxX changed val do 
		(
			spn_minX.range = [-100000,val-1,spn_minX.value]
			SaveControlCurves()
			theCI.setDomain [spn_minX.value, spn_maxX.value]
			loadControlCurves()
		)
		
		on btn_flipHorizontal pressed do
		(
			SaveControlCurves()
			local theCount = theCI.getNumPoints()
			local tempArray = for i = 1 to theCount collect
			(
				#(theCI.getPointPos i, theCI.getPointIn i, theCI.getPointOut i )
			)
			for i = 1 to tempArray.count do
			(
				tempArray[i][1].x = 1.0 - tempArray[i][1].x
				temp = tempArray[i][2]
				temp.x = -temp.x
				tempArray[i][2] = [-tempArray[i][3].x, tempArray[i][3].y]
				tempArray[i][3] = temp
			)
			tempArray = for i = tempArray.count to 1 by -1 collect tempArray[i]
				
			for i = 1 to theCount do
			(
				local cp = crv_CurveControl.curves[1].points[i]
				cp.value = tempArray[i][1]
				cp.inTangent = tempArray[i][2]
				cp.outTangent = tempArray[i][3]
				cp.bezier = true 
				cp.corner = true 
				crv_CurveControl.curves[1].points[i] = cp
			)			
			lastPoint = 0
			loadControlCurves()
			updatePresetName()
		)
		on btn_flipVertical pressed do
		(
			SaveControlCurves()
			local theCount = theCI.getNumPoints()
			local tempArray = for i = 1 to theCount collect
			(
				#(theCI.getPointPos i, theCI.getPointIn i, theCI.getPointOut i )
			)
			local theArray = for i = 1 to tempArray.count collect tempArray[i][1].y
			local averageY = (amax theArray - amin theArray)/2
			for i = 1 to tempArray.count do
			(
				tempArray[i][1].y = averageY*2-(tempArray[i][1].y) 
				tempArray[i][2].y = -tempArray[i][2].y
				tempArray[i][3].y = -tempArray[i][3].y
			)
			for i = 1 to theCount do
			(
				local cp = crv_CurveControl.curves[1].points[i]
				cp.value = tempArray[i][1]
				cp.inTangent = tempArray[i][2]
				cp.outTangent = tempArray[i][3]
				cp.bezier = true 
				cp.corner = true 
				crv_CurveControl.curves[1].points[i] = cp
			)	
			lastPoint = 0
			loadControlCurves()
			updatePresetName()
		)

		on btn_mirrorVertical pressed do
		(
			SaveControlCurves()
			local theCount = theCI.getNumPoints()
			local tempArray = for i = 1 to theCount collect
			(
				#(theCI.getPointPos i, theCI.getPointIn i, theCI.getPointOut i )
			)
			for i = 1 to tempArray.count do
			(
				tempArray[i][1].y = -tempArray[i][1].y
				tempArray[i][2].y = -tempArray[i][2].y
				tempArray[i][3].y = -tempArray[i][3].y
			)
			for i = 1 to theCount do
			(
				local cp = crv_CurveControl.curves[1].points[i]
				cp.value = tempArray[i][1]
				cp.inTangent = tempArray[i][2]
				cp.outTangent = tempArray[i][3]
				cp.bezier = true 
				cp.corner = true 
				crv_CurveControl.curves[1].points[i] = cp
			)	
			lastPoint = 0
			loadControlCurves()
			updatePresetName()
		)
		
		on crv_CurveControl selChanged ci val do 
		(
			SaveControlCurves()
			getTangents val
		)
		on crv_CurveControl ptChanged ci val do 
		(
			SaveControlCurves()
		)
		on crv_CurveControl deleted ci val do 
		(
			SaveControlCurves()
			getTangents 0
		)
		on crv_CurveControl tangentChanged ci val type do 
		(
			SaveControlCurves()
			getTangents 1 theActualPoint:val
		)
		on crv_CurveControl reset ci do 
		(
			crv_CurveControl.curves[1].numPoints = 2
			local cp = crv_CurveControl.curves[1].points[1]
			cp.value = [0,0]
			cp.inTangent = [0.0,0.0]
			cp.outTangent = [0.0,0.0]
			cp.bezier = false
			cp.corner = true
			crv_CurveControl.curves[1].points[1] = cp	
			
			cp = crv_CurveControl.curves[1].points[2]
			cp.value = [1,1]
			cp.inTangent = [0.0,0.0]
			cp.outTangent = [0.0,0.0]
			cp.bezier = false
			cp.corner = true
			crv_CurveControl.curves[1].points[2] = cp		
			SaveControlCurves()
			
			zoom crv_CurveControl #all	
		)
		
		on spn_inTangentX changed val do setTangents #in
		on spn_inTangentY changed val do setTangents #in
		on spn_outTangentX changed val do setTangents #out
		on spn_outTangentY changed val do setTangents #out		

		on MagmaFlowEditor_CurveControlRollout moved pos do
		(
			magma.setNodeProperty theCurveNode "CurveEditorPosition" pos
		)
		
		on MagmaFlowEditor_CurveControlRollout open do
		(
			if Krakatoa_PresetsArrowBitmap == undefined do
			(
				try
				(
					::Krakatoa_PresetsArrowBitmap_Base = openbitmap (getDir #usericons + "\\krakatoaGUI.bmp")
					::Krakatoa_PresetsArrowBitmap = bitmap 512 16 color:red
					copy ::Krakatoa_PresetsArrowBitmap_Base ::Krakatoa_PresetsArrowBitmap 
				)
				catch	
				(
					::Krakatoa_PresetsArrowBitmap_Base = bitmap 512 16 color:red
					::Krakatoa_PresetsArrowBitmap = bitmap 512 16 color:red
				)
				FranticParticleRenderMXS.updateIconColors()
			)
			try(btn_curvePresets.images = #(Krakatoa_PresetsArrowBitmap,Krakatoa_PresetsArrowBitmap, 32,1,1,2,2))catch()			
			
			magma = ::MagmaFlowEditor_CurrentMagmaHolder
			theCurveNode = ::MagmaFlowEditor_CurrentMagmaNode
			theThumbnailControl = ::MagmaFlowEditor_CurrentCurveThumbnail
			parentEditor = ::MagmaFlowEditor_CurrentEditor
			theCI = magma.getNodeProperty theCurveNode "curve"
			local theDomain = theCI.getDomain()
			crv_CurveControl.x_range = theDomain
			spn_minX.value = theDomain.x
			spn_maxX.value = theDomain.y
			makeDir (Krakatoa_PresetsDirectory + "/MagmaFlowSettings") all:true
			loadControlCurves()
			updatePresetName()
			gc light:true
		)
		
		on MagmaFlowEditor_CurveControlRollout close do 
		(
			SaveControlCurves()
			try(parentEditor.displaySelectedNodeProperties())catch()
			--try(MagmaFlowEditor_Functions.loadControlCurves theThumbnailControl theCI)catch()
			gc light:true
			for i = ::MagmaFlowEditor_CurrentCurveEditors.count to 1 by -1 where ::MagmaFlowEditor_CurrentCurveEditors[i][3] == MagmaFlowEditor_CurveControlRollout do 
				deleteItem ::MagmaFlowEditor_CurrentCurveEditors i
		)
	)			
	
	MagmaFlowEditor_CurveControlRollout
)--end scope