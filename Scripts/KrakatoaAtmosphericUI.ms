-- Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
-- SPDX-License-Identifier: Apache-2.0
(
local KrakatoaAtmosphericEffect_Dialog
local theEffect = ::KrakatoaAtmosphericEffect_CurrentEffect
rollout KrakatoaAtmosphericEffect_Dialog "Krakatoa Atmospheric Effect"
(
	group "Particle Objects"
	(
		button btn_addNodes "Add Particle Objects..." across:2 width:165 offset:[0,-3]
		button btn_removeNodes "Remove Particle Objects" width:165 offset:[0,-3]
		multilistbox lbx_nodes height:10 offset:[0,-4]
	)
	group "Sampling Controls"
	(
		spinner spn_voxelLength "Voxel Length:" range:[0.01,100.0,1.0] fieldwidth:45 across:3 offset:[44,-2] type:#worldunits
		button btn_voxelLengthPreset ">>" width:20 height:18 offset:[0,-3] tooltip:"Set Raymatching Voxel Length to a Preset Value, \nor Add/Remove current value to/from the Presets." 
		
		spinner spn_raymarch_step_max "Max. Step:" range:[0.1,100.0,1.0] fieldwidth:45 offset:[-13,-2] type:#float
		spinner spn_raymarch_step_min "Min. Step:" range:[0.01,10.0,0.125] fieldwidth:45 offset:[-14,0] type:#float
	)
	button btn_maxStepPreset ">>" width:20 height:18 align:#right offset:[7,-50] tooltip:"Set Raymatching Max.Step to a Preset Value, \nor Add/Remove current value to/from the Presets." 
	button btn_minStepPreset ">>" width:20 height:18 align:#right offset:[7,-1] tooltip:"Set Raymatching Min.Step to a Preset Value, \nor Add/Remove current value to/from the Presets." 
	
	group "Shading Controls"
	(
		checkbutton chk_useEmission ">Use Emission" width:165 align:#left across:2 offset:[0,-4]
		checkbutton chk_useAbsorption ">Use Absorption"  width:165 align:#right offset:[0,-4]
	)

	group "Lighting and Camera Density and Emission Scale"
	(
		spinner spn_lightDensityScale "Light Density:" range:[0.01,100.0,5.0] fieldwidth:45 across:2 offset:[-12,0]
		spinner spn_cameraDensityScale "Camera Density:" range:[0.01,100.0,5.0] fieldwidth:45 offset:[-14,0]
		spinner spn_lightDensityScaleExponent "Exponent:" range:[-30,30,-1.0] fieldwidth:45 type:#integer across:2 offset:[-12,-3]
		spinner spn_cameraDensityScaleExponent "Exponent:" range:[-30,30,-1.0] fieldwidth:45 type:#integer offset:[-14,-3]
		checkbutton chk_useLightDensityScale ">Use" width:35 height:35 align:#left offset:[-5,-40]
		spinner spn_cameraEmissionScale "Camera Emission:" range:[0.01,100.0,5.0] fieldwidth:45 align:#right offset:[-14,0]
		spinner spn_cameraEmissionScaleExponent "Exponent:" range:[-30,30,-1.0] fieldwidth:45 type:#integer align:#right offset:[-14,-4]
		checkbutton chk_useCameraEmissionScale ">Use" width:35 height:35 align:#left offset:[-5,-40]
	)
	button btn_lightingDensityPreset ">>" width:20 height:34 align:#left across:2 offset:[156,-83] tooltip:"Set Lighting Density to a Preset Value, \nor Add/Remove current value to/from the Presets." 
	button btn_cameraDensityPreset ">>" width:20 height:34 align:#right offset:[7,-83] tooltip:"Set Camera Density to a Preset Value, \nor Add/Remove current value to/from the Presets." 
	button btn_emissionStrengthPreset ">>" width:20 height:34 align:#right offset:[7,-1] tooltip:"Set Emission Strength to a Preset Value, \nor Add/Remove current value to/from the Presets." 

	fn updateIcons =
	(
		btn_voxelLengthPreset.images = btn_minStepPreset.images = btn_maxStepPreset.images = btn_emissionStrengthPreset.images = btn_cameraDensityPreset.images = btn_lightingDensityPreset.images = #(Krakatoa_PresetsArrowBitmap,Krakatoa_PresetsArrowBitmap, 32,1,1,2,2)
	)
	
	fn updateUI =
	(
		KrakatoaAtmosphericEffect_Dialog.title = "Effect: ["+ theEffect.name +"]"
		local temp = for i in KrakatoaAtmosphericEffect_Dialog.controls where not matchPattern ((classof i) as string) pattern:"Group*" collect i  
		if theEffect != undefined then
		(
			lbx_nodes.items = for i in theEffect.ParticleNodes collect if isValidNode i then i.name else "<deleted node>"

			spn_voxelLength.value = theEffect.VoxelLength
			spn_raymarch_step_max.value = theEffect.RaymarchStepMax
			spn_raymarch_step_min.value = theEffect.RaymarchStepMin
			
			chk_useEmission.state = theEffect.UseEmission	
			chk_useAbsorption.state = theEffect.UseAbsorption	
			
			spn_lightDensityScale.value = theEffect.lightDensityScale
			spn_cameraDensityScale.value = theEffect.cameraDensityScale
			spn_lightDensityScaleExponent.value = theEffect.lightDensityScaleExponent
			spn_cameraDensityScaleExponent.value = theEffect.cameraDensityScaleExponent
			chk_useLightDensityScale.state = theEffect.useLightDensityScale
			spn_cameraEmissionScale.value = theEffect.cameraEmissionScale
			spn_cameraEmissionScaleExponent.value = theEffect.cameraEmissionScaleExponent
			chk_useCameraEmissionScale.state = theEffect.useCameraEmissionScale
			
			for i in temp do i.enabled = true			
			spn_lightDensityScale.enabled = spn_lightDensityScaleExponent.enabled = chk_useLightDensityScale.state
			spn_cameraEmissionScale.enabled = spn_cameraEmissionScaleExponent.enabled = chk_useCameraEmissionScale.state
		)
		else
		(
			for i in temp do i.enabled = false
		)
	)
	
	fn createPresetsRCMenu type:#lightingdensity =
	(
		local twocontrols = false
		case type of
		(
		
			#lightingdensity: (
						presetName = "AtmosphericLightingPassDensity"
						theSpinner = "spn_lightDensityScale"
						theSpinner2 = "spn_lightDensityScaleExponent"
						theDefaultsKey = "KA:Lighting:Density"
						theDefaultsKey2 = "KA:Lighting:DensityExponent"
						twocontrols = true
					)	
			#cameradensity: (
						presetName = "AtmosphericFinalPassDensity"
						theSpinner = "spn_cameraDensityScale"
						theSpinner2 = "spn_cameraDensityScaleExponent"
						theDefaultsKey = "KA:Camera:Density"
						theDefaultsKey2 = "KA:Camera:DensityExponent"
						twocontrols = true
					)	
			#emissionstrength: (
						presetName = "AtmosphericEmissionStrength"
						theSpinner = "spn_cameraEmissionScale"
						theSpinner2 = "spn_cameraEmissionScaleExponent"
						theDefaultsKey = "KA:Emission:Strength"
						theDefaultsKey2 = "KA:Emission:StrengthExponent"	
						twocontrols = true				
					)
			#voxelsize: (
						presetName = "AtmosphericVoxelSize"
						theSpinner = "spn_voxelLength"
						theDefaultsKey = "KA:VoxelSize" 
					)							
			#minstep: (
						presetName = "AtmosphericMinStep"
						theSpinner = "spn_raymarch_step_min"
						theDefaultsKey = "KA:MinStep" 
					)
			#maxstep: (
						presetName = "AtmosphericMaxStep"
						theSpinner = "spn_raymarch_step_max"
						theDefaultsKey = "KA:MaxStep" 
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
				#lightingdensity: #("1.0E0","5.0E-1","1.0E-1","1.0E-2")
				#cameradensity: #("1.0E0","5.0E-1","1.0E-1","1.0E-2")
				#emissionstrength: #("1.0E0","1.0E-1","1.0E-2")
				#reflectionstrength: #(0.1,0.25,0.5,0.6,0.75,1.0)
				#voxelsize: #(0.1,0.25,0.5,0.75,1.0,2.0,5.0,10.0)
				#minstep: #(0.1,0.25,0.5,1.0)
				#maxstep: #(0.5,1.0,2.0)
			)
			for i in theKeys do
				setIniSetting (Krakatoa_PresetsDirectory + "//KrakatoaPreferences.ini") presetName (i as string) (i as string)
		)
		for k in theKeys do if findItem presetsList theValue == 0 do append presetsList k

		global KrakatoaAtmosphericEffect_DialogGlobal =  KrakatoaAtmosphericEffect_Dialog
		
		if twocontrols then
			theValue = (execute ("KrakatoaAtmosphericEffect_DialogGlobal."+ theSpinner +".value")) as string + "E" + (execute ("KrakatoaAtmosphericEffect_DialogGlobal."+ theSpinner2 +".value")) as string 
		else
			theValue = execute ("KrakatoaAtmosphericEffect_DialogGlobal."+ theSpinner +".value")
				
				
		local txt = StringStream ""
		format "rcmenu Presets_RCMenu\n(\n" to:txt
				
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
				format  "on mnu_preset% picked do (KrakatoaAtmosphericEffect_DialogGlobal.%.changed (KrakatoaAtmosphericEffect_DialogGlobal.%.value = %);KrakatoaAtmosphericEffect_DialogGlobal.%.changed (KrakatoaAtmosphericEffect_DialogGlobal.%.value = %))\n" cnt theSpinner theSpinner  theFS[1] theSpinner2 theSpinner2 theFS[2] to:txt
			)	
			else
				format  "on mnu_preset% picked do KrakatoaAtmosphericEffect_DialogGlobal.%.changed (KrakatoaAtmosphericEffect_DialogGlobal.%.value = %)\n" cnt theSpinner theSpinner i to:txt
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
			
		format  ")\n" to:txt
		Krakatoa_RCMenu_Struct.Presets_RCMenu = execute (txt as string)
	)	
	
	on btn_lightingDensityPreset pressed do
	(
		createPresetsRCMenu type:#lightingdensity
		popUpMenu Krakatoa_RCMenu_Struct.Presets_RCMenu position:mouse.screenPos
	)
	on btn_cameraDensityPreset pressed do
	(
		createPresetsRCMenu type:#cameradensity
		popUpMenu Krakatoa_RCMenu_Struct.Presets_RCMenu position:mouse.screenPos
	)	
	on btn_emissionStrengthPreset pressed do
	(
		createPresetsRCMenu type:#emissionstrength
		popUpMenu Krakatoa_RCMenu_Struct.Presets_RCMenu position:mouse.screenPos
	)		
	on btn_voxelLengthPreset pressed do
	(
		createPresetsRCMenu type:#voxelsize
		popUpMenu Krakatoa_RCMenu_Struct.Presets_RCMenu position:mouse.screenPos
	)
	on btn_minStepPreset pressed do
	(
		createPresetsRCMenu type:#minstep
		popUpMenu Krakatoa_RCMenu_Struct.Presets_RCMenu position:mouse.screenPos
	)	
	on btn_maxStepPreset pressed do
	(
		createPresetsRCMenu type:#maxstep
		popUpMenu Krakatoa_RCMenu_Struct.Presets_RCMenu position:mouse.screenPos
	)		
	
	on btn_lightingDensityPreset rightClick do
	(
		createPresetsRCMenu type:#lightingdensity
		popUpMenu Krakatoa_RCMenu_Struct.Presets_RCMenu position:mouse.screenPos
	)
	on btn_cameraDensityPreset rightClick do
	(
		createPresetsRCMenu type:#cameradensity
		popUpMenu Krakatoa_RCMenu_Struct.Presets_RCMenu position:mouse.screenPos
	)	
	on btn_emissionStrengthPreset rightClick do
	(
		createPresetsRCMenu type:#emissionstrength
		popUpMenu Krakatoa_RCMenu_Struct.Presets_RCMenu position:mouse.screenPos
	)		
	on btn_voxelLengthPreset rightClick do
	(
		createPresetsRCMenu type:#voxelsize
		popUpMenu Krakatoa_RCMenu_Struct.Presets_RCMenu position:mouse.screenPos
	)
	on btn_minStepPreset rightClick do
	(
		createPresetsRCMenu type:#minstep
		popUpMenu Krakatoa_RCMenu_Struct.Presets_RCMenu position:mouse.screenPos
	)	
	on btn_maxStepPreset rightClick do
	(
		createPresetsRCMenu type:#maxstep
		popUpMenu Krakatoa_RCMenu_Struct.Presets_RCMenu position:mouse.screenPos
	)	
	
	fn filterPRTObjects obj = 
	(
		findItem #(PRT_Volume, PRT_FumeFX, KrakatoaPRTLoader, PRT_Source, PRT_Maker, PRT_Hair, PF_Source, PRT_Surface, Stoke, ParticleGroup, Thinking, PArray, PCloud, SuperSpray, Blizzard, Snow, Spray, PHXSimulator) (classof obj.baseobject) > 0 and findItem theEffect.ParticleNodes obj == 0
	)
	on btn_addNodes pressed do
	(
		local theSel = selectByName filter:filterPRTObjects single:false showHidden:false
		if theSel != undefined do
		(
			for i in theSel do 
			(
				if classof i.baseobject == PF_Source then
				(
					for j in refs.dependents i.baseobject where classof j == ParticleGroup and isProperty j #Position do appendIfUnique theEffect.ParticleNodes j
				)
				else
					appendIfUnique theEffect.ParticleNodes i
			)
		)
		updateUI()
	)
	on btn_removeNodes pressed do
	(
		local theSel = lbx_nodes.selection as array
		for i = theSel.count to 1 by -1 do 
		(
			deleteItem theEffect.ParticleNodes theSel[i]
		)
		updateUI()
	)

	on spn_voxelLength changed val do if theEffect != undefined do theEffect.VoxelLength = val
	on spn_raymarch_step_max changed val do 
	(
		if theEffect != undefined do 
		(
			theEffect.RaymarchStepMax = val
			if val < theEffect.RaymarchStepMin do 
			(
				theEffect.RaymarchStepMin =  spn_raymarch_step_min.value = val
			)
		)
	)
	on spn_raymarch_step_min changed val do 
	(
		if theEffect != undefined do 
		(
			theEffect.RaymarchStepMin = val
			if val > theEffect.RaymarchStepMax do
			(
				theEffect.RaymarchStepMax = spn_raymarch_step_max.value = val
			)
		)
	)
		
	on chk_useEmission changed val do if theEffect != undefined do theEffect.useEmission = val
	on chk_useAbsorption changed val do if theEffect != undefined do theEffect.useAbsorption = val

	on spn_lightDensityScale changed val do if theEffect != undefined do theEffect.lightDensityScale = val
	on spn_cameraDensityScale changed val do if theEffect != undefined do theEffect.cameraDensityScale = val
	
	on spn_lightDensityScale changed val do if theEffect != undefined do theEffect.lightDensityScale = val
	on spn_cameraDensityScale changed val do if theEffect != undefined do theEffect.cameraDensityScale = val
	on spn_lightDensityScaleExponent changed val do if theEffect != undefined do theEffect.lightDensityScaleExponent = val
	on spn_cameraDensityScaleExponent changed val do if theEffect != undefined do theEffect.cameraDensityScaleExponent = val
		
	on spn_cameraEmissionScale changed val do if theEffect != undefined do theEffect.cameraEmissionScale = val
	on spn_cameraEmissionScaleExponent changed val do if theEffect != undefined do theEffect.cameraEmissionScaleExponent = val

	on chk_useLightDensityScale changed val do 
	(
		if theEffect != undefined do theEffect.useLightDensityScale = val
		spn_lightDensityScale.enabled = spn_lightDensityScaleExponent.enabled = val
	)
	on chk_useCameraEmissionScale changed val do 
	(
		if theEffect != undefined do theEffect.useCameraEmissionScale = val
		spn_cameraEmissionScale.enabled = spn_cameraEmissionScaleExponent.enabled = val
	)
	
	on KrakatoaAtmosphericEffect_Dialog open do
	(
		if ::Krakatoa_PresetsArrowBitmap  == undefined do
		(
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
		)
		updateIcons()
		updateUI()
	)
	
	on KrakatoaAtmosphericEffect_Dialog close do
	(
		local theIndex = 0
		for i = 1 to ::KrakatoaAtmosphericEffects_DialogsArray.count where ::KrakatoaAtmosphericEffects_DialogsArray[i] != undefined and ::KrakatoaAtmosphericEffects_DialogsArray[i][2] == KrakatoaAtmosphericEffect_Dialog do theIndex = i
		if theIndex > 0 do deleteItem ::KrakatoaAtmosphericEffects_DialogsArray theIndex
	)
)

local theIndex = 0
for i = 1 to ::KrakatoaAtmosphericEffects_DialogsArray.count where ::KrakatoaAtmosphericEffects_DialogsArray[i] != undefined and ::KrakatoaAtmosphericEffects_DialogsArray[i][1] == theEffect do theIndex = i
if theIndex == 0 then
(
	createDialog KrakatoaAtmosphericEffect_Dialog 360 400 style:#(#style_titlebar, #style_border, #style_sysmenu,#style_minimizebox )
	append ::KrakatoaAtmosphericEffects_DialogsArray #(theEffect,KrakatoaAtmosphericEffect_Dialog)
)
else
(
	try(if ::KrakatoaAtmosphericEffects_DialogsArray[theIndex][2].placement == #minimized do ::KrakatoaAtmosphericEffects_DialogsArray[theIndex][2].placement = #normal)catch()
	setFocus ::KrakatoaAtmosphericEffects_DialogsArray[theIndex][2]
)
)--end script