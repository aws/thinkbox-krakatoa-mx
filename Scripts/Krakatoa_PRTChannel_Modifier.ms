-- Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
-- SPDX-License-Identifier: Apache-2.0
plugin geometry KrakatoaMXGlobalDataHolder
category:"Krakatoa"
invisible:true
classid:#(0x46b7f5c3, 0x624e587c)
replaceui:true
extends:Global_Override_Dummy
(
	parameters main rollout:params
	(
		notes type:#string ui:edt_notes default:"Enter Notes Here..."
	)
	
	rollout params "Krakatoa Global Override"
	(
		group "About"
		(
			label lbl_about01 "This Object is a Holder for" align:#left offset:[-3,0]
			label lbl_about10 "Global Channel Modifiers" align:#left offset:[-3,0]
			label lbl_about20 "applied by Krakatoa to all" align:#left offset:[-3,0]
			label lbl_about30 "particles in world space at" align:#left offset:[-3,0]
			label lbl_about40 "the end of the loading process." align:#left offset:[-3,0]
		)
		
		button btn_addNewModifier "Add New Channels Modifier..." height:30 width:155 align:#center offset:[-1,0]

		edittext edt_notes height:80 width:160 align:#center offset:[-3,0]
		
		on btn_addNewModifier pressed do
		(
			if selection.count == 1 do 
			(
				local theMod = KrakatoaChannelsModifier()
				addModifier $ theMod
				modPanel.setCurrentObject $.baseobject
			)	
		)
	)	
)

plugin simpleObject KrakatoaGlobalDataHolder
name:"KrakatoaGlobalOverride"
category:"Krakatoa"
invisible:true
classid:#(0x46b7f5c2, 0x624e587b)
replaceui:true
(
	parameters main rollout:params
	(
		notes type:#string ui:edt_notes default:"Enter Notes Here..."
	)
	
	rollout params "Krakatoa Global Override"
	(
		group "About"
		(
			label lbl_about01 "This Object is a Holder for" align:#left offset:[-3,0]
			label lbl_about10 "Global Channel Modifiers" align:#left offset:[-3,0]
			label lbl_about20 "applied by Krakatoa to all" align:#left offset:[-3,0]
			label lbl_about30 "particles in world space at" align:#left offset:[-3,0]
			label lbl_about40 "the end of the loading process." align:#left offset:[-3,0]
		)
		
		button btn_addNewModifier "Add New Channels Modifier..." height:30 width:155 align:#center offset:[-1,0]

		edittext edt_notes height:80 width:160 align:#center offset:[-3,0]
		
		on btn_addNewModifier pressed do
		(
			if selection.count == 1 do 
			(
				local theMod = KrakatoaChannelsModifier()
				addModifier $ theMod
				modPanel.setCurrentObject $.baseobject
			)	
		)
	)
	
	tool create
	(
		on mousePoint click do
		(
			#stop
		)
	)
	
	on buildMesh do
	(
		setMesh mesh verts:#() faces:#()
	)
	
)

plugin simpleObject KrakatoaRenderElementsDataHolder
name:"KrakatoaRenderElements"
category:"Krakatoa"
invisible:true
classid:#(0x46b7f5c4, 0x624e587c)
replaceui:true
(
	parameters main rollout:params
	(
		notes type:#string ui:edt_notes default:"Enter Notes Here..."
	)
	
	rollout params "Krakatoa Render Elements"
	(
		group "About"
		(
			label lbl_about01 "This Object is a Holder for" align:#left offset:[-3,0]
			label lbl_about10 "Krakatoa Channel Modifiers" align:#left offset:[-3,0]
			label lbl_about20 "defining particle data to be" align:#left offset:[-3,0]
			label lbl_about30 "written out to image files" align:#left offset:[-3,0]
			label lbl_about40 "as Render Elements." align:#left offset:[-3,0]
		)
		
		button btn_addNewModifier "Add New Channels Modifier..." height:30 width:155 align:#center offset:[-1,0]

		edittext edt_notes height:80 width:160 align:#center offset:[-3,0]
		
		on btn_addNewModifier pressed do
		(
			if selection.count == 1 do 
			(
				local theMod = KrakatoaChannelsModifier()
				theMod.isRenderElement = true
				addModifier $ theMod
				modPanel.setCurrentObject $.baseobject
			)	
		)
	)
	
	tool create
	(
		on mousePoint click do
		(
			#stop
		)
	)
	
	on buildMesh do
	(
		setMesh mesh verts:#() faces:#()
	)
	
)

/*
plugin modifier KrakatoaFumeFX
classid:#(0x134f9c74, 0x366b0b02)
name:"Krakatoa FumeFX"
(
	parameters main rollout:params
	(
		enableRendering type:#boolean default:true ui:chk_enableRendering animatable:false
		--jitterAmount type:#float default:0.0 ui:spn_jitterAmount animatable:true
		--seed type:#integer default:12345 ui:spn_Seed animatable:false
		
		velocity_channel type:#boolean default:true ui:chk_velocity_channel 
		temperature_channel type:#boolean default:false ui:chk_temperature_channel 
		fuel_channel type:#boolean default:false ui:chk_fuel_channel
	)
	rollout params "Krakatoa FumeFX Modifier"
	(
		group "Info"
		(
			label lbl_info01 "Controls the conversion of"
			label lbl_info02 "FumeFX simulation data"
			label lbl_info03 "into Krakatoa particles"
		)
		group "Particle Distribution" 
		(
			checkbox chk_enableRendering "Enabled"
			--spinner spn_jitterAmount "Jitter %:[a]" range:[0.0,100.0,10.0] fieldwidth:50 scale:1.0 enabled:false
			--spinner spn_Seed "Random Seed:" range:[1,100000,1] type:#integer fieldwidth:50 enabled:false
		)	
		group "Disabled FumeFX Channels:"
		(
			checkbox chk_velocity_channel "Velocity"
			checkbox chk_temperature_channel "Temperature"
			checkbox chk_fuel_channel "Fuel"
		)
	)
)
*/


plugin modifier KrakatoaCameraModifier
classid:#(0x134f9c63, 0x366ca300)
name:"Krakatoa Camera"
(
	local params
	parameters main rollout:params
	(
		useCameraType type:#boolean default:false ui:chk_useCameraType animatable:false
		cameraType type:#integer default:3 ui:rad_cameraType animatable:false
		useFOV type:#boolean default:false ui:chk_useFOV animatable:false
		FOV type:#float default:180 ui:spn_FOV animatable:true
		dofOn type:#boolean default:true ui:chk_dofOn animatable:false
		fStop type:#float default:2.0 ui:spn_fstop animatable:true
		useSubPixelOffset type:#boolean default:false ui:chk_useSubPixelOffset animatable:false
		SubPixelOffsetX type:#float default:0.0 ui:spn_SubPixelOffsetX animatable:true
		SubPixelOffsetY type:#float default:0.0 ui:spn_SubPixelOffsetY animatable:true
		focalDepthOn type:#boolean default:false ui:chk_focalDepthOn animatable:false
		focalDepth type:#float default:100 ui:spn_focalDepth animatable:true
		
		applyBokehFilter type:#boolean default:false animatable:false ui:chk_applyBokehFilter
		BokehFilter type:#texturemap ui:map_BokehFilter
		applyBlendRGB type:#boolean default:true animatable:false ui:chk_applyBlendRGB 
		BlendRGB type:#float animatable:true default:50.0 ui:spn_BlendRGB
		BokehMipmapResCoefficient type:#integer animatable:true default:1 ui:spn_mipmapResCoefficient

		applyAnamorphicSqueeze type:#boolean default:true animatable:false ui:chk_applyAnamorphicSqueeze
		anamorphicSqueeze type:#float default:1.0 animatable:true ui:spn_anamorphicSqueeze
	)	
	

	rollout params "Krakatoa Camera"
	(
		local theCanvasBitmap, theEraserBitmap, theBokehTextureBitmap,theCircleOfConfusionBitmap 
		local theWorkBitmap, theWorkBitmap2, theAnamorphicBitmap
		local theBitmapSize = 100
		
		group "Info"
		(
			label lbl_info01 "Overrides Camera Properties" offset:[0,-3]
			label lbl_info02 "for Rendering in Krakatoa" offset:[0,-3]
		)		
		checkbutton chk_enableManipulators ">Enable Manipulate Mode" width:154 align:#center checked:manipulateMode offset:[0,-3]
		label lbl_enableManipulators offset:[0,-25]
		group ""
		(
			checkbox chk_useCameraType "Override Lens Type" offset:[-4,-10]
			radiobuttons rad_cameraType labels:#("Perspective Lens","Ortho Lens","Spherical Lens") width:145 align:#left offset:[12,0]
		)
		group ""
		(			
			checkbox chk_useFOV "Override Field Of View" offset:[-4,-10]
			spinner spn_FOV "FOV (deg.)" range:[0.01,360.0,45] fieldwidth:50 across:2 align:#left offset:[6,0]
			button btn_FOVPreset ">>" align:#right height:17 width:20 offset:[5,-1]
		)

		group ""
		(		
			checkbox chk_dofOn "Override Depth Of Field" offset:[-4,-10]
			spinner spn_fstop "f-stop:" fieldwidth:50 across:2 align:#left offset:[26,0] scale:0.01 range:[0.001,100.0,2.0]
			button btn_fstopPreset ">>" align:#right height:17 width:20 offset:[5,-1]
			
			checkbox chk_focalDepthOn "Override Focal Depth" offset:[-4,-2]
			spinner spn_focalDepth "Focal Depth:" fieldwidth:50 across:2 align:#left offset:[-2,0] scale:0.01 range:[0.001,10000000.0,100.0]
			button btn_focalDepthPreset ">>" align:#right height:17 width:20 offset:[5,-1]
		)
		group ""
		(
			mapbutton map_BokehFilter "<Bokeh Filter Texture>" width:150 align:#center offset:[0,-10] tooltip:"The Alpha channel of the texture map will control the Bokeh shape if 'Use Alpha As Bokeh Filter' is checked.\n\nThe RGB channels will control the color of the Bokeh if Blend RGB is checked and the Percentage is higher than zero."
			checkbox chk_applyBokehFilter "Use Alpha As Bokeh Filter" offset:[-4,-2] tooltip:"When checked, the Alpha channel of the texture map (if available) will be used to control the shape of the Bokeh effect."
			checkbox chk_applyBlendRGB "Blend RGB" offset:[-4,0] across:3 tooltip:"When checked, the RGB channels of the texture map (if available) will be used to blend with the particle's color."
			spinner spn_blendRGB fieldwidth:40 across:2 align:#center offset:[29,0] scale:1.0 range:[0.0,100.0,0.0] tooltip:"Blend RGB Percentage. Animatable."
			button btn_blendRGBPreset ">>" align:#right height:17 width:20 offset:[8,-1] tooltip:"Set the Blend RGB Percentage using a preset\n\nAdd/Remove presets from the list."
			spinner spn_mipmapResCoefficient "Mip-Map Scale" across:2 fieldwidth:40 align:#center offset:[29,0] type:#integer scale:1 range:[1, 256, 1] tooltip: "Adjust blend map Mip-Map resolution to prevent banding."
			button btn_mipMapResCoefficientPreset ">>" align:#right height:17 width:20 offset:[8,-1] tooltip:"Set the Blend map Mip-Map resolution to prevent banding."

			button btn_anamorphicSqueeze "Update Preview" align:#center width:theBitmapSize tooltip:"Click to update the preview..."
			bitmap bmp_anamorphicSqueeze height:theBitmapSize width:theBitmapSize offset:[0,-5]

			checkbox chk_applyAnamorphicSqueeze "Apply Anamorphic Squeeze" offset:[-4,-4]
			spinner spn_anamorphicSqueeze "Squeeze Factor:" fieldwidth:35 across:2 align:#right offset:[52,-1] scale:0.01 range:[0.1,10.0,1.0]
			button btn_anamorphicSqueezePreset ">>" align:#right height:17 width:20 offset:[5,-2]
		)
		
		group ""
		(
			checkbox chk_useSubPixelOffset "Apply Sub-Pixel Offset" offset:[-4,-10]
			spinner spn_SubPixelOffsetX "Offset X:" fieldwidth:50 across:2 align:#left offset:[15,0] scale:0.1 range:[-1.0,1.0,0.0]
			button btn_SubPixelOffsetXPreset ">>" align:#right height:17 width:20 offset:[5,-1]
			spinner spn_SubPixelOffsetY "Offset Y:" fieldwidth:50 across:2 align:#left offset:[15,0] scale:0.1 range:[-1.0,1.0,0.0]
			button btn_SubPixelOffsetYPreset ">>" align:#right height:17 width:20 offset:[5,-1]
		)	

		
		fn blendFunction1 c1 p1 c2 p2 =
		(
			(white*(c1.a/255.0)*(1.0-(BlendRGB/100.0))) + (c1*(BlendRGB/100.0))
		)
		fn blendFunction2 c1 p1 c2 p2 =
		(
			white*(c1.a/255.0)
		)
		fn blendFunction3 c1 p1 c2 p2 =
		(
			[(c1.r*c2.r), (c1.g*c2.g), (c1.b*c2.b)]/255
		)
		
		fn previewAnamorphicSqueeze =
		(
			copy theEraserBitmap theCanvasBitmap --clear the target bitmap
			copy theEraserBitmap theWorkBitmap
			
			if BokehFilter != undefined and applyBokehFilter then
				copy theBokehTextureBitmap theWorkBitmap --set the new map to the rendered texture
			else
				copy theCircleOfConfusionBitmap theWorkBitmap --set the new map to the circular texture			
			
			if  BokehFilter != undefined and applyBokehFilter and applyBlendRGB do 
					pasteBitmap theWorkBitmap theWorkBitmap2 [0,0] [0,0] type:#function function:blendFunction1 --use the texture for both
			if 	BokehFilter != undefined and not applyBokehFilter and applyBlendRGB do  --if only the RGB will be used, multiply by the circle shape
			(
					copy theCircleOfConfusionBitmap theWorkBitmap
					pasteBitmap theBokehTextureBitmap theWorkBitmap [0,0] [0,0] type:#function function:blendFunction3 --multiply the RGB of the texture with the circle 
					pasteBitmap theWorkBitmap theWorkBitmap2 [0,0] [0,0] type:#function function:blendFunction1 -- blend the result onto white
			)
			if 	BokehFilter != undefined and applyBokehFilter and not applyBlendRGB do --if only the Alpha will be used,
			(
					pasteBitmap theWorkBitmap theWorkBitmap2 [0,0] [0,0] type:#function function:blendFunction2 -- #blend 
			)
			if BokehFilter == undefined or ( not applyBokehFilter and not applyBlendRGB) do --if the map is not there or completely disabled, use the circle
			(
				pasteBitmap theWorkBitmap theWorkBitmap2 [0,0] [0,0] type:#function function:blendFunction2 -- #blend 
			)			
			
			if applyAnamorphicSqueeze then
			(
				if anamorphicSqueeze > 1.0 then
				(
					theHeight = theBitmapSize
					theWidth = theHeight/anamorphicSqueeze
					thePosX = (theBitmapSize-theWidth)/2
					thePosY = 0
				)
				else
				(
					theWidth = theBitmapSize
					theHeight = theWidth*anamorphicSqueeze
					thePosX = 0 
					thePosY = (theBitmapSize-theHeight)/2					
				)
			)
			else 
			(
				theWidth = theBitmapSize
				theHeight = theBitmapSize
				thePosX = 0
				thePosY = 0				
			)
			theAnamorphicBitmap = bitmap theWidth theHeight --anamorphic version
			copy theWorkBitmap2 theAnamorphicBitmap --copy the result of the blending to rescale
			pasteBitmap theAnamorphicBitmap theCanvasBitmap [0,0] [(theBitmapSize-theWidth)/2,(theBitmapSize-theHeight)/2] type:#copy --now paste the scaled version back into the bitmap
			bmp_anamorphicSqueeze.bitmap = theCanvasBitmap
		)
		
		fn createPresetsRCMenu type:#fov =
		(
			case type of
			(
				#fov: (
							presetName = "CameraFieldOfView"
							theParameter = "FOV"
						)	
				#fstop : (
							presetName = "CameraFStop"
							theParameter = "fstop"
						)	
				#FocalDepth: (
							presetName = "FocalDepth"
							theParameter = "focalDepth"
						)		
				#offsetX: (
							presetName = "SubPixelOffsetX"
							theParameter = "SubPixelOffsetX"
						)		
				#offsetY: (
							presetName = "SubPixelOffsetY"
							theParameter = "SubPixelOffsetY"
						)		
				#blendRGB: (
							presetName = "blendRGB"
							theParameter = "blendRGB"
					)
				#mipMapResCoefficient: (
							presetName = "BokehMipmapResCoefficient"
							theParameter = "BokehMipmapResCoefficient"							
					)
				#anamorphicSqueeze: (
							presetName = "anamorphicSqueeze"
							theParameter = "anamorphicSqueeze"					
					)
			)
			local presetsList = #()
			local theKeys = for i in (getIniSetting (Krakatoa_PresetsDirectory + "//KrakatoaPreferences.ini") presetName  ) collect (execute i)
			sort theKeys 
			if theKeys.count == 0 then 
			(
				theKeys = case type of
				(
					#fov: #(45.0,90.0,180.0,360.0)
					#fstop : #(0.5,1.0,2.0,3.0,4.0)
					#focalDepth : #(10.0,100.0,200.0,300.0,400.0,500.0,1000.0)
					#offsetX: #(-1.0,-0.5,0.0,0.5,1.0)
					#offsetY: #(-1.0,-0.5,0.0,0.5,1.0)
					#blendRGB: #(0.0,10.0,25.0,33.0,50.0,75.0,100.0)
					#mipMapResCoefficient: #(1,4,8,16)
					#anamorphicSqueeze: #(0.5,1.0,2.0)
				)
				for i in theKeys do
					setIniSetting (Krakatoa_PresetsDirectory + "//KrakatoaPreferences.ini") presetName (i as string) (i as string)
			)
			for k in theKeys do
				if findItem presetsList theValue == 0 do append presetsList k

			theValue = execute ("(modPanel.getCurrentObject())." + theParameter)
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
				txt += "on mnu_preset" + cnt as string + " picked do ( (modPanel.getCurrentObject())."+ theParameter +" = "+ i as string +"\n try((modPanel.getCurrentObject()).params.previewAnamorphicSqueeze())catch() )\n"
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
		
		
		on chk_enableManipulators changed state do
		(
			manipulateMode = state
		)
		
		on map_BokehFilter rightClick do
		(
			rcmenu rcm_BokehFilterMap
			(
				menuItem mnu_removeMap "Remove Map"
				on mnu_removeMap picked do 
				(
					BokehFilter = undefined
					applyBokehFilter = false
					previewAnamorphicSqueeze()
				)
			)
			popupMenu rcm_BokehFilterMap pos:mouse.screenpos
		)
		
		
		on btn_FOVPreset pressed do 
		(
			createPresetsRCMenu type:#fov 
			popUpMenu Krakatoa_Presets_RCMenu position:mouse.screenPos		
		)
		
		on btn_FOVPreset rightClick do 
		(
			createPresetsRCMenu type:#fov 
			popUpMenu Krakatoa_Presets_RCMenu position:mouse.screenPos		
		)		
		
		on btn_fstopPreset pressed do 
		(
			createPresetsRCMenu type:#fstop 
			popUpMenu Krakatoa_Presets_RCMenu position:mouse.screenPos		
		)

		on btn_fstopPreset rightClick do 
		(
			createPresetsRCMenu type:#fstop 
			popUpMenu Krakatoa_Presets_RCMenu position:mouse.screenPos		
		)	
		
		on btn_SubPixelOffsetXPreset pressed do 
		(
			createPresetsRCMenu type:#offsetX
			popUpMenu Krakatoa_Presets_RCMenu position:mouse.screenPos		
		)

		on btn_SubPixelOffsetXPreset rightClick do 
		(
			createPresetsRCMenu type:#offsetX
			popUpMenu Krakatoa_Presets_RCMenu position:mouse.screenPos		
		)		

		on btn_SubPixelOffsetYPreset pressed do 
		(
			createPresetsRCMenu type:#offsetY
			popUpMenu Krakatoa_Presets_RCMenu position:mouse.screenPos		
		)

		on btn_SubPixelOffsetYPreset rightClick do 
		(
			createPresetsRCMenu type:#offsetY
			popUpMenu Krakatoa_Presets_RCMenu position:mouse.screenPos		
		)
		
		
		on btn_focalDepthPreset pressed do 
		(
			createPresetsRCMenu type:#focalDepth
			popUpMenu Krakatoa_Presets_RCMenu position:mouse.screenPos		
		)			
		on btn_focalDepthPreset rightClick do 
		(
			createPresetsRCMenu type:#focalDepth
			popUpMenu Krakatoa_Presets_RCMenu position:mouse.screenPos		
		)		

		on btn_blendRGBPreset pressed do 
		(
			createPresetsRCMenu type:#blendRGB
			popUpMenu Krakatoa_Presets_RCMenu position:mouse.screenPos		
		)			
		on btn_blendRGBPreset rightClick do 
		(
			createPresetsRCMenu type:#blendRGB
			popUpMenu Krakatoa_Presets_RCMenu position:mouse.screenPos		
		)		
		
		on btn_mipMapResCoefficientPreset pressed do 
		(
			createPresetsRCMenu type:#mipMapResCoefficient
			popUpMenu Krakatoa_Presets_RCMenu position:mouse.screenPos		
		)			
		on btn_mipMapResCoefficientPreset rightClick do 
		(
			createPresetsRCMenu type:#mipMapResCoefficient
			popUpMenu Krakatoa_Presets_RCMenu position:mouse.screenPos		
		)		
		
		on btn_anamorphicSqueezePreset pressed do 
		(
			createPresetsRCMenu type:#anamorphicSqueeze
			popUpMenu Krakatoa_Presets_RCMenu position:mouse.screenPos		
		)			
		on btn_anamorphicSqueezePreset rightClick do 
		(
			createPresetsRCMenu type:#anamorphicSqueeze
			popUpMenu Krakatoa_Presets_RCMenu position:mouse.screenPos		
		)			

		on chk_applyBokehFilter changed state do 
		(
			if BokehFilter != undefined do renderMap BokehFilter size:[140,140] into:theBokehTextureBitmap
			previewAnamorphicSqueeze()
		)
		on btn_anamorphicSqueeze pressed do 
		(
			if BokehFilter != undefined do renderMap BokehFilter size:[140,140] into:theBokehTextureBitmap
			previewAnamorphicSqueeze()				
		)
		on spn_anamorphicSqueeze changed val do previewAnamorphicSqueeze()
		on spn_blendRGB changed val do previewAnamorphicSqueeze()
		on chk_applyAnamorphicSqueeze changed state do previewAnamorphicSqueeze()
		on chk_applyBlendRGB changed state do 
		(
			if BokehFilter != undefined do renderMap BokehFilter size:[140,140] into:theBokehTextureBitmap
			previewAnamorphicSqueeze()
		)
		
		on params open do
		(
			chk_enableManipulators.state = manipulateMode = true
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
			try(btn_FOVPreset.images = #(Krakatoa_PresetsArrowBitmap,Krakatoa_PresetsArrowBitmap, 32,1,1,2,2))catch()		
			try(btn_fstopPreset.images = 	#(Krakatoa_PresetsArrowBitmap,Krakatoa_PresetsArrowBitmap, 32,1,1,2,2))catch()		
			try(btn_focalDepthPreset.images = #(Krakatoa_PresetsArrowBitmap,Krakatoa_PresetsArrowBitmap, 32,1,1,2,2))catch()		
			try(btn_SubPixelOffsetXPreset.images = #(Krakatoa_PresetsArrowBitmap,Krakatoa_PresetsArrowBitmap, 32,1,1,2,2))catch()		
			try(btn_SubPixelOffsetYPreset.images = #(Krakatoa_PresetsArrowBitmap,Krakatoa_PresetsArrowBitmap, 32,1,1,2,2))catch()		
			try(btn_blendRGBPreset.images = #(Krakatoa_PresetsArrowBitmap,Krakatoa_PresetsArrowBitmap, 32,1,1,2,2))catch()	
			try(btn_mipMapResCoefficientPreset.images = #(Krakatoa_PresetsArrowBitmap,Krakatoa_PresetsArrowBitmap, 32,1,1,2,2))catch()	
			try(btn_anamorphicSqueezePreset.images = #(Krakatoa_PresetsArrowBitmap,Krakatoa_PresetsArrowBitmap, 32,1,1,2,2))catch()	

			theCanvasBitmap = bitmap theBitmapSize theBitmapSize color:[0,0,0,0]
			theEraserBitmap = bitmap theBitmapSize theBitmapSize color:[0,0,0,0]
			theWorkBitmap = bitmap theBitmapSize theBitmapSize color:[0,0,0,0]
			theWorkBitmap2 = bitmap theBitmapSize theBitmapSize color:[0,0,0,0]
			theAnamorphicBitmap = bitmap theBitmapSize theBitmapSize color:[0,0,0,0]
			theBokehTextureBitmap = bitmap theBitmapSize theBitmapSize color:[0,0,0,0]
			theCircleOfConfusionBitmap	= bitmap theBitmapSize theBitmapSize color:[0,0,0,0]
			local radius = (theBitmapSize/2)-4
			local center = (theBitmapSize/2)
				
			for i = 0 to 90 by 0.5 do
			(
				theColor = for z = 1 to (cos i)*radius*2 collect white
				setPixels theCircleOfConfusionBitmap [center-(cos i)*radius, center+(sin i)*radius] theColor
				setPixels theCircleOfConfusionBitmap [center-(cos i)*radius, center-(sin i)*radius] theColor
			)				
			if BokehFilter != undefined do renderMap BokehFilter size:[theBitmapSize,theBitmapSize] into:theBokehTextureBitmap
			previewAnamorphicSqueeze()	
		)
	)
)

global KrakatoaChannelsEditor_Functions, KrakatoaChannelNodeEditor_Rollout

/*
plugin material KrakatoaChannelsMaterial
name:"KrakatoaChannels"
classID:#(0x76f94723, 0x27aa1193)
extends:Standard replaceUI:true version:1
( 
	parameters main rollout:main_rollout
	(
		flow type:#string default:"#(#(\"Output\", #(2), #(\"Color\",\"float16\",3), #([350,0],false, false,undefined,undefined,undefined,undefined,\"Output\" ), true ) ,#(\"Input\", #(), #(\"Channel\", \"Color\"), #([200,100], false, true, undefined, undefined, undefined, true, \"Color\", \"Color\"), true))" 
		internalFlow type:#string default:"#(#(\"Output\", #(2), #(\"Color\",\"float16\",3), #([350,0],false, false,undefined,undefined,undefined,undefined,\"Output\" ), true ) ,#(\"Input\", #(), #(\"Channel\", \"Color\"), #([200,100], false, true, undefined, undefined, undefined, true, \"Color\", \"Color\"), true))" 
		note type:#string default:"Enter Notes Here..."
		trackID type:#string default:"0" ui:edt_trackID
		TextureMapSources type:#TextureMapTab tabSizeVariable:true
		currentPreset type:#string default:"Custom"
		currentFolder type:#string default:""
		autoUpdate type:#boolean default:false animatable:false ui:chk_autoupdate
		interactiveMode type:#boolean default:false animatable:false ui:chk_interactiveMode
		AutomaticRenameOff type:#boolean default:false animatable:false ui:chk_AutomaticRenameOFF
	)		
	
	rollout main_rollout "Krakatoa Channels Modifier"
	(
		local theFoldersList = #()
		local theFilesList = #()
	
		button btn_openChannelsEditor "Open MagmaFlow Editor..." width:300 height:30 align:#center

		dropdownlist ddl_PresetFolders items:#() width:300 align:#center
		dropdownlist ddl_currentPreset items:#() width:300 align:#center
		
		edittext edt_notes height:100 width:300 align:#center offset:[-3,0]
		edittext edt_trackID "ID:" width:300 align:#center offset:[0,0] enabled:false
		checkbutton chk_autoupdate ">AUTO UPDATE" width:300 align:#center
		group "Interactive Updates"
		(
			checkbutton chk_interactiveMode ">Interactive Mode (SLOW!)" width:300 align:#center tooltip:"Interactive Changes to Dependency Objects (Parameters Connected To Input Nodes) will update the KCM."
			button btn_disableAll "Disable All In Scene" width:300 align:#center
		)	
		checkbutton chk_AutomaticRenameOFF ">Disable Auto-Renaming" width:300 align:#center
		
		fn openEditor =
		(
			try(destroyDialog KrakatoaChannelNodeEditor_Rollout)catch()
			global KrakatoaChannelEditor_LastUndoRecordNumber = 0
			global KrakatoaChannelNodeEditor_CurrentModifier = this
			global KrakatoaChannelEditor_BaseNodeTreeData = execute internalFlow
			KrakatoaChannelsEditor_Functions.fixFlowIDsAfterLoading KrakatoaChannelEditor_BaseNodeTreeData	
			KrakatoaChannelsEditor_Functions.buildDisplayTree()
			
			local theSize = execute (getIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "ParticleChannelEditor" "Size")
			if theSize == OK do theSize = [980,600]
			if theSize.x < 400 do theSize.x = 400
			if theSize.y < 200 do theSize.y = 200
			
			local thePos = execute (getIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "ParticleChannelEditor" "Position")
			if thePos == OK do thePos = [100,100]
			if thePos.y > sysinfo.DesktopSize.y - 200 do thePos.y = sysinfo.DesktopSize.y - 200
			createDialog KrakatoaChannelNodeEditor_Rollout theSize.x theSize.y thePos.x thePos.y style:#(#style_titlebar, #style_border, #style_sysmenu, #style_resizing, #style_minimizebox, #style_maximizebox) menu:KrakatoaChannelNodeEditor_Rollout_MainMenu
			KrakatoaChannelNodeEditor_Rollout.resized theSize	
			KrakatoaChannelNodeEditor_Rollout.title = "Krakatoa MagmaFlow Editor - ID:"  + KrakatoaChannelNodeEditor_CurrentModifier.trackID as string +" - ["+ KrakatoaChannelNodeEditor_CurrentModifier.name+"]"
			setFocus KrakatoaChannelNodeEditor_Rollout.hc		
		)
		

		on chk_interactiveMode changed state do
		(
			if state then 
				updateNodeDependencies() 
			else 
				disableNodeDependencies()
		)
		
		on btn_disableAll pressed do
		(
			deleteAllChangeHandlers id:#KCM_InteractiveMode 
			--persistent global Krakatoa_KCM_InteractiveMode_ModifiersList = #()
			persistent global Krakatoa_KCM_InteractiveMode_NodesList = #()
			for m in getClassInstances KrakatoaChannelsModifier do m.interactiveMode = false
		)
		
		on chk_autoupdate changed state do
		(
			if KrakatoaChannelNodeEditor_Rollout.open do 
				KrakatoaChannelNodeEditor_Rollout.chk_autoUpdateModifier.checked = state
			setIniSetting (getDir #plugcfg+ "\\Krakatoa\\KrakatoaPreferences.ini") "ParticleChannelEditor" "AutoUpdate" (state as string)
		)
		
		on chk_expandFlow changed state do
		(
			openEditor()
		)
		
		on btn_openChannelsEditor pressed do
		(
			openEditor()
		)
		
		
		fn updateFlowFolders =
		(
			local theDirectories = (getDirectories (Krakatoa_PresetsDirectory+ "\\MagmaFlows\\*"))
			theDirectories = for i in theDirectories collect 
			(
				local theFS = (filterString i "\\")
				local theDir = theFS[theFS.count]
				if matchPattern theDir pattern:"BlackOps" or matchPattern theDir pattern:"Temp" then dontcollect else theDir
			)
			theFoldersList = join #("[MagmaFlows Root Folder]") theDirectories
			ddl_PresetFolders.items = theFoldersList 
			local theIndex = findItem theFoldersList currentFolder
			if theIndex == 0 do theIndex = 1
			ddl_PresetFolders.selection = theIndex
		)
		
		fn updateFlowList =
		(
			local theFiles = if ddl_PresetFolders.selection == 1 then 
				(getFiles (Krakatoa_PresetsDirectory+ "\\MagmaFlows\\*.kmf") )
			else
				(getFiles (Krakatoa_PresetsDirectory+ "\\MagmaFlows\\"+theFoldersList[ddl_PresetFolders.selection]+"\\*.kmf") )
			
			theFilesList =  join #("[Custom Flow]") theFiles 
			ddl_currentPreset.items = (for f in theFilesList collect getFileNameFile f)
			local theIndex = findItem ddl_currentPreset.items currentPreset
			if theIndex == 0 do theIndex = 1
			ddl_currentPreset.selection = theIndex			
		)
		
		on ddl_PresetFolders selected itm do
		(
			currentFolder = ddl_PresetFolders.selected
			updateFlowList()
			--currentPreset =  "Custom"
		)
		
		on ddl_currentPreset selected itm do
		(
			global KrakatoaChannelNodeEditor_CurrentModifier = this
			local thePath = Krakatoa_PresetsDirectory+ "\\MagmaFlows\\Temp\\"
			makeDir thePath all:true
			if itm > 1 then
			(
				if currentPreset == "Custom" do KrakatoaChannelsEditor_Functions.saveFlow (thePath + trackID as string +".kmf")
				currentPreset = ddl_currentPreset.selected
				currentFolder = ddl_PresetFolders.selected
				fileIn theFilesList[itm]
				KrakatoaChannelEditor_BaseNodeTreeData = deepCopy KrakatoaChannelEditor_NodeTreeData
				KrakatoaChannelsEditor_Functions.fixFlowIDsAfterLoading KrakatoaChannelEditor_BaseNodeTreeData
				KrakatoaChannelsEditor_Functions.buildDisplayTree() 			
				KrakatoaChannelsEditor_Functions.updateParentModifier()
				KrakatoaChannelsEditor_Functions.exposeControlsToModifier this
				if KrakatoaChannelNodeEditor_Rollout.open do KrakatoaChannelNodeEditor_Rollout.createNodeTree init:true
			)	
			else if itm == 1 and doesFileExist (thePath + trackID as string +".kmf") do
			(
				currentPreset =  "Custom"
				fileIn (thePath + trackID as string +".kmf")
				KrakatoaChannelEditor_BaseNodeTreeData = deepCopy KrakatoaChannelEditor_NodeTreeData
				KrakatoaChannelsEditor_Functions.fixFlowIDsAfterLoading KrakatoaChannelEditor_BaseNodeTreeData
				KrakatoaChannelsEditor_Functions.buildDisplayTree() 			
				KrakatoaChannelsEditor_Functions.updateParentModifier()
				KrakatoaChannelsEditor_Functions.exposeControlsToModifier this
				if KrakatoaChannelNodeEditor_Rollout.open do KrakatoaChannelNodeEditor_Rollout.createNodeTree init:true
			)
		)
		
		on edt_notes entered txt do 
		(
			note = txt
			try(Krakatoa_GUI_RenderGlobalValues.updateModifierStackData())catch()
		)
		
		on main_rollout open do
		(
			edt_notes.text = note
			updateFlowFolders()
			updateFlowList()
			local theIndex = findItem ddl_currentPreset.items currentPreset
			if theIndex == 0 do theIndex = 1
			ddl_currentPreset.selection = theIndex
			local theIndex = findItem ddl_PresetFolders.items currentFolder
			if theIndex == 0 do theIndex = 1
			ddl_PresetFolders.selection = theIndex
		)
	)	
	on create do
	(
		seed (timestamp())
		local existingIDs = for o in (getClassInstances KrakatoaChannelsModifier)  collect o.TrackID
		do (
			trackID = (random 100000 10000000) as string + "_" + (random 100000 10000000) as string 
		)while findItem existingIDs trackID != 0
		
		local theVal = execute (getIniSetting (getDir #plugcfg+ "\\Krakatoa\\KrakatoaPreferences.ini") "ParticleChannelEditor" "AutoUpdate" )
		if theVal == OK do theVal = false		
		autoUpdate = theVal	
	)	
	
	on postLoad do
	(
		initArrays()
		KrakatoaChannelNodeEditor_CurrentModifier = this
		KrakatoaChannelEditor_NodeTreeData = execute internalFlow
		KrakatoaChannelsEditor_Functions.fixFlowIDsAfterLoading KrakatoaChannelEditor_NodeTreeData
		internalFlow = with PrintAllElements true (KrakatoaChannelEditor_NodeTreeData as string)
		flow = KrakatoaChannelsEditor_Functions.expandFlow internalFlow --fixtracks:true			
		if interactiveMode do updateNodeDependencies()
	)
	
	on clone theOriginal do 
	(
		try(destroyDialog KrakatoaChannelNodeEditor_Rollout)catch()
		seed (timestamp())
		local existingIDs = for o in (getClassInstances KrakatoaChannelsModifier)  collect o.TrackID
		do (
			trackID = (random 100000 10000000) as string + "_" + (random 100000 10000000) as string 
		)while findItem existingIDs trackID != 0
		
		KrakatoaChannelNodeEditor_CurrentModifier = this
		KrakatoaChannelEditor_NodeTreeData = execute internalFlow
		KrakatoaChannelsEditor_Functions.fixFlowIDsAfterLoading KrakatoaChannelEditor_NodeTreeData
		KrakatoaChannelsEditor_Functions.copyControllersOnClone theOriginal this
		internalFlow = with PrintAllElements true (KrakatoaChannelEditor_NodeTreeData as string)
		flow = KrakatoaChannelsEditor_Functions.expandFlow internalFlow --fixtracks:true
	)	
)
*/

plugin modifier KrakatoaDeleteModifier
classid:#(0x7fc844e7, 0x1fe348d5)
name:"Krakatoa Delete"
(
	
	local showMissingIDWarning= true
	
	parameters main rollout:main_rollout
	(
		SelectionMode type:#integer default:1 ui:rad_SelectionMode animatable:false
		ResetSelection type:#boolean default:true ui:chk_ResetSelection animatable:false
	)
	
	rollout main_rollout "Krakatoa Delete"
	(
		radiobuttons rad_SelectionMode "Delete Particles Using" labels:#("Selection Greater Than Zero", "Soft-Selection + ID Channel")
		on rad_selectionMode changed state do showMissingIDWarning = true
		
		checkbox chk_ResetSelection "Reset Selection Afterwards" align:#left checked:true offset:[-11,0]
	)
	
)

plugin modifier KrakatoaChannelsModifier
classid:#(0x17776900, 0x2de0f78)
name:"Krakatoa Channels"
(
	local main_rollout
	local compilerError = "" --obsolete
	local LastErrorMessage = ""
	local ErrorNodeIndex = 0 --obsolete
	local LastErrorNode = 0
	local setCompilerError 
	local isCloningModifier = false

	
	parameters main rollout:main_rollout
	(
		flow type:#string default:"#(#(\"Output\", #(2), #(\"Color\",\"float16\",3), #([350,0],false, false,undefined,undefined,undefined,undefined,\"Output\" ), true ) ,#(\"Input\", #(), #(\"Channel\", \"Color\"), #([200,100], false, true, undefined, undefined, undefined, true, \"Color\", \"Color\"), true))" 
		internalFlow type:#string default:"#(#(\"Output\", #(2), #(\"Color\",\"float16\",3), #([350,0],false, false,undefined,undefined,undefined,undefined,\"Output\" ), true ) ,#(\"Input\", #(), #(\"Channel\", \"Color\"), #([200,100], false, true, undefined, undefined, undefined, true, \"Color\", \"Color\"), true))" 
		note type:#string default:"Enter Notes Here..."
		trackID type:#string default:"0" ui:edt_trackID
		TextureMapSources type:#TextureMapTab tabSizeVariable:true
		currentPreset type:#string default:"Custom"
		currentFolder type:#string default:""
		autoUpdate type:#boolean default:false animatable:false ui:chk_autoupdate
		interactiveMode type:#boolean default:false animatable:false ui:chk_interactiveMode
		AutomaticRenameOff type:#boolean default:false animatable:false ui:chk_AutomaticRenameOFF
		GeometryObjectsList type:#StringTab tabSizeVariable:true
		needCAupdate type:#boolean default:false animatable:false
		isRenderElement type:#boolean default:false animatable:false
		ForceUpdate type:#float default:0.0 animatable:true
		
		on flow set val do
		(
		)
		
		on internalFlow set val do
		(
			--if KrakatoaChannelNodeEditor_CurrentModifier  == undefined do KrakatoaChannelNodeEditor_CurrentModifier = this
			--flow = KrakatoaChannelsEditor_Functions.expandFlow val
		)
	)	


	fn setCompilerError theNodeIndex theError =
	(
		LastErrorNode = ErrorNodeIndex = theNodeIndex
		LastErrorMessage = compilerError = theError
		KrakatoaChannelsEditor_Functions.displayError ErrorNodeIndex compilerError trackID
		if ::KrakatoaChannelNodeEditor_Rollout.open then 
			::KrakatoaChannelNodeEditor_CurrentModifier != this
		else
			true
	)	

	fn deleteNodeDependencies =
	(
		deleteAllChangeHandlers id:#KCM_InteractiveMode 
	)
	
	fn getDepNodes =
	(
		local Krakatoa_theDepNodes = #()
		local theTabuNodes = refs.dependents this
		local theRoot = try(execute ("trackViewNodes.KrakatoaChannelEditor.KCE_"+trackID))catch(undefined)
		if theRoot != undefined do
		(
			local theExecutedFlow = (execute internalFlow)
			for i = 1 to theRoot.numsubs do
			(
				theTrack = theRoot[i] 
				for t in #(theTrack[1],theTrack[2],theTrack[3]) do
				(
					local theController = t.controller
					
					if classof theController == Float_List do try(theController = theController[2].controller)catch()
					if classof theController == Point3_List do try(theController = theController[2].controller[1].controller)catch()
					if classof theController == Point3_XYZ do try(theController = theController[1].controller)catch()
					
					if classof theController == Float_Script do
					(
						local theTarget = try(theController.getTarget "KCE_Reference") catch(undefined)
						if theTarget != undefined do
						(
							for o in refs.dependents theTarget where classof (superclassof o) == Node and findItem Krakatoa_theDepNodes o == 0 and findItem theTabuNodes o == 0 and isProperty o "name" do 
								append Krakatoa_theDepNodes o
						)	
					)
					
				)--end t loop	
			)
					
			--try(KrakatoaChannelNodeEditor_CurrentModifier.nodeDependencies = Krakatoa_theDepNodes)catch()
			for i in theExecutedFlow where i[3][1] == "Script" do 
			(
				local theScript = i[3][2] as stringStream
				while not eof theScript do
				(
					local theLine = readLine theScript
					local theNodePathBegin = findString theLine "$" 
					while theNodePathBegin != undefined do
					(
						theLine = (substring theLine (theNodePathBegin+1) -1)
						local theFS = filterString theLine ". "
						local theNode = try(getNodeByName theFS[1])catch(undefined)
						if theNode != undefined and findItem Krakatoa_theDepNodes theNode == 0 do append Krakatoa_theDepNodes theNode
						theNodePathBegin = findString theLine "$" 
					)--end while $ found
				)--end while script reading
			)--end i loop			
				
			for i in theExecutedFlow where i[3][1] == "FromSpace" or i[3][1] == "ToSpace"  do 
			(
				local theNode = try(getNodeByName i[3][3])catch(undefined)
				if isValidNode theNode and findItem theTabuNodes theNode == 0 do append Krakatoa_theDepNodes theNode
			)
			
			for i in theExecutedFlow where i[1]=="Input" AND i[3][1] == "Geometry" do 
			(
				for o in i[3][2] do
				(
					local theNode = try(getNodeByName o)catch(undefined)
					if isValidNode theNode and findItem theTabuNodes theNode == 0 and findItem Krakatoa_theDepNodes theNode == 0 do 
						append Krakatoa_theDepNodes theNode
				)
			)				
		)	
		Krakatoa_theDepNodes
	)
	
	fn registerCallback =
	(
		global Krakatoa_KCM_InteractiveMode_NodesList
		deleteAllChangeHandlers id:#KCM_InteractiveMode 
		local theNodes = for o in Krakatoa_KCM_InteractiveMode_NodesList where isValidNode o[1] collect o[1]
		when parameters theNodes change id:#KCM_InteractiveMode handleAt:#redrawViews theObject do
		(
			try
			(
				for o in Krakatoa_KCM_InteractiveMode_NodesList where o[1] == theObject do 
					for m in o[2] do m.interactiveMode = m.interactiveMode
			)catch(print "Error in KCM Callback!")
		)
		

	)	
	
	fn initArrays =
	(
		--persistent global Krakatoa_KCM_InteractiveMode_ModifiersList 
		persistent global Krakatoa_KCM_InteractiveMode_NodesList 
			
		--if Krakatoa_KCM_InteractiveMode_ModifiersList == undefined do Krakatoa_KCM_InteractiveMode_ModifiersList = #()	
		if Krakatoa_KCM_InteractiveMode_NodesList == undefined do Krakatoa_KCM_InteractiveMode_NodesList = #()			
	)
	
	fn updateNodeDependencies = 
	(
		initArrays()
		
		local Krakatoa_theDepNodes = getDepNodes()
		
		/*
		if findItem Krakatoa_KCM_InteractiveMode_ModifiersList this == 0 do 
			append Krakatoa_KCM_InteractiveMode_ModifiersList this
		*/
		
		for o in Krakatoa_theDepNodes do 
		(
			theIndex = for i = 1 to Krakatoa_KCM_InteractiveMode_NodesList.count where Krakatoa_KCM_InteractiveMode_NodesList[i][1] == o collect i
			if theIndex.count > 0 then
			(
				append Krakatoa_KCM_InteractiveMode_NodesList[theIndex[1]][2] this
			)	
			else
			(
				append Krakatoa_KCM_InteractiveMode_NodesList #(o, #(this))
			)
		)	
		registerCallback()
		--with animate on at time -10000 ForceUpdate = -10000
		--with animate on at time 10000 ForceUpdate = 10000
		if this.ForceUpdate.controller == undefined do this.ForceUpdate.controller = bezier_float()
		setBeforeORT this.ForceUpdate.controller #relativeRepeat
		setAfterORT this.ForceUpdate.controller #relativeRepeat
	)	

	
	fn disableNodeDependencies =
	(
		--persistent global Krakatoa_KCM_InteractiveMode_ModifiersList 
		persistent global Krakatoa_KCM_InteractiveMode_NodesList 
			
		--if Krakatoa_KCM_InteractiveMode_ModifiersList == undefined do Krakatoa_KCM_InteractiveMode_ModifiersList = #()	
		if Krakatoa_KCM_InteractiveMode_NodesList == undefined do Krakatoa_KCM_InteractiveMode_NodesList = #()	
		
		local Krakatoa_theDepNodes = getDepNodes()
		for o in Krakatoa_theDepNodes do 
		(
			for i = 1 to Krakatoa_KCM_InteractiveMode_NodesList.count where Krakatoa_KCM_InteractiveMode_NodesList[i][1] == o do
			(
				local theIndex = findItem Krakatoa_KCM_InteractiveMode_NodesList[i][2] this
				if theIndex > 0 do deleteItem Krakatoa_KCM_InteractiveMode_NodesList[i][2] theIndex
			)
		)
		registerCallback()
		--deleteKeys this.ForceUpdate.controller #allKeys
		if this.ForceUpdate.controller == undefined do this.ForceUpdate.controller = bezier_float()
		setBeforeORT this.ForceUpdate.controller #constant
		setAfterORT this.ForceUpdate.controller #constant		
	)
	
	rollout main_rollout "Krakatoa Channels Modifier" category:1
	(
		local theFoldersList = #()
		local theFilesList = #()
		
		group "NOTE:"
		(
			label lbl_KMXNode1 "This Modifier is OBSOLETE."
			label lbl_KMXNode2 "It provides the Magma 1.6"
			label lbl_KMXNode3 "functionality for compatibility"
			label lbl_KMXNode4 "purposes only!"
			label lbl_KMXNode5 ""
			label lbl_KMXNode6 "Please consider using the"
			label lbl_KMXNode7 "MagmaModifier introduced in"
			label lbl_KMXNode8 "Krakatoa MX 2 to access all"
			label lbl_KMXNode9 "recent improvements and "
			label lbl_KMXNode10 "advanced MAGMA 2 features!"
		)
		
	
		button btn_openChannelsEditor "Open MagmaFlow Editor..." width:158 height:30 align:#center

		dropdownlist ddl_PresetFolders items:#() width:160 align:#center
		dropdownlist ddl_currentPreset items:#() width:160 align:#center
		button btn_exploreFolder "Explore Presets Folder..." width:160 align:#center
		edittext edt_notes height:100 width:160 align:#center offset:[-3,0]
		edittext edt_trackID "ID:" width:155 align:#center offset:[0,0] enabled:false
		checkbutton chk_autoupdate ">AUTO UPDATE" width:155 align:#center
		group "Interactive Updates"
		(
			checkbutton chk_interactiveMode ">Interactive Mode (SLOW!)" width:148 align:#center tooltip:"Interactive Changes to Dependency Objects (Parameters Connected To Input Nodes) will update the KCM."
			button btn_disableAll "Disable All In Scene" width:148 align:#center
		)	
		checkbutton chk_AutomaticRenameOFF ">Disable Auto-Renaming" width:155 align:#center
		button btn_UpdateExposedParameters "Update Exposed Parameters!" width:155 align:#center visible:needCAupdate tooltip:"This KCM was cloned and its Exposed Parameters (if any) have not been updated yet. Please press the button to fix the Exposed Parameters."
		
		on btn_exploreFolder pressed do
		(
			local thePath = if ddl_PresetFolders.selection == 1 then 
				(Krakatoa_PresetsDirectory+ "\\MagmaFlows\\") 
			else
				(Krakatoa_PresetsDirectory+ "\\MagmaFlows\\"+theFoldersList[ddl_PresetFolders.selection]+"\\") 
			shellLaunch thePath ""
		)
		
		fn openEditor =
		(
			::FranticParticleRenderMXS.openMagmaFlowEditor this
		)
		

		on chk_interactiveMode changed state do
		(
			if state then 
				updateNodeDependencies() 
			else 
				disableNodeDependencies()
		)
		
		on btn_disableAll pressed do
		(
			deleteAllChangeHandlers id:#KCM_InteractiveMode 
			--persistent global Krakatoa_KCM_InteractiveMode_ModifiersList = #()
			persistent global Krakatoa_KCM_InteractiveMode_NodesList = #()
			for m in getClassInstances KrakatoaChannelsModifier do 
			(
				m.interactiveMode = false
				try
				(
					setBeforeORT m.ForceUpdate.controller #constant
					setAfterORT m.ForceUpdate.controller #constant		
				)catch()
			)
		)
		
		on chk_autoupdate changed state do
		(
			if KrakatoaChannelNodeEditor_Rollout.open do 
				KrakatoaChannelNodeEditor_Rollout.chk_autoUpdateModifier.checked = state
			setIniSetting (getDir #plugcfg+ "\\Krakatoa\\KrakatoaPreferences.ini") "ParticleChannelEditor" "AutoUpdate" (state as string)
		)
		
		on btn_openChannelsEditor pressed do
		(
			--openEditor()
			::FranticParticleRenderMXS.openMagmaFlowEditor this
			if needCAupdate do 
			(
				KrakatoaChannelsEditor_Functions.exposeControlsToModifier this
				needCAupdate = false
				btn_UpdateExposedParameters.visible = false
			)					
		)
		
		
		fn updateFlowFolders =
		(
			local theDirectories = (getDirectories (Krakatoa_PresetsDirectory+ "\\MagmaFlows\\*"))
			theDirectories = for i in theDirectories collect 
			(
				local theFS = (filterString i "\\")
				local theDir = theFS[theFS.count]
				if matchPattern theDir pattern:"BlackOps" or matchPattern theDir pattern:"Temp" then dontcollect else theDir
			)
			theFoldersList = join #("[MagmaFlows Root Folder]") theDirectories
			ddl_PresetFolders.items = theFoldersList 
			local theIndex = findItem theFoldersList currentFolder
			if theIndex == 0 do theIndex = 1
			ddl_PresetFolders.selection = theIndex
		)
		
		fn updateFlowList =
		(
			local theFiles = if ddl_PresetFolders.selection == 1 then 
				(getFiles (Krakatoa_PresetsDirectory+ "\\MagmaFlows\\*.kmf") )
			else
				(getFiles (Krakatoa_PresetsDirectory+ "\\MagmaFlows\\"+theFoldersList[ddl_PresetFolders.selection]+"\\*.kmf") )
			
			theFilesList =  join #("[Custom Flow]") theFiles 
			ddl_currentPreset.items = (for f in theFilesList collect getFileNameFile f)
			local theIndex = findItem ddl_currentPreset.items currentPreset
			if theIndex == 0 do theIndex = 1
			ddl_currentPreset.selection = theIndex			
		)
		
		on ddl_PresetFolders selected itm do
		(
			currentFolder = ddl_PresetFolders.selected
			updateFlowList()
			--currentPreset =  "Custom"
		)
		
		on ddl_currentPreset selected itm do
		(
			global KrakatoaChannelNodeEditor_CurrentModifier = this
			local thePath = Krakatoa_PresetsDirectory+ "\\MagmaFlows\\Temp\\"
			makeDir thePath all:true
			if itm > 1 then
			(
				if currentPreset == "Custom" do 
				(
					KrakatoaChannelsEditor_Functions.saveFlow (thePath + trackID as string +".kmf")
				)
				currentPreset = ddl_currentPreset.selected
				currentFolder = ddl_PresetFolders.selected
				local theMapPath = (getFileNamePath theFilesList[itm] + getFileNameFile theFilesList[itm]  + ".mat") 
				if doesFileExist theMapPath do
				(
					local theMatLib = loadTempMaterialLibrary theMapPath
					TextureMapSources = for m in theMatLib collect m
				)
				
				fileIn theFilesList[itm]
				KrakatoaChannelEditor_BaseNodeTreeData = deepCopy KrakatoaChannelEditor_NodeTreeData
				KrakatoaChannelsEditor_Functions.fixFlowIDsAfterLoading KrakatoaChannelEditor_BaseNodeTreeData
				KrakatoaChannelsEditor_Functions.buildDisplayTree() 		
				global KrakatoaChannelNodeEditor_CurrentModifierPresetIsCustom = false				
				KrakatoaChannelsEditor_Functions.updateParentModifier()
				KrakatoaChannelsEditor_Functions.exposeControlsToModifier this
				if KrakatoaChannelNodeEditor_Rollout.open do KrakatoaChannelNodeEditor_Rollout.createNodeTree init:true
				global KrakatoaChannelNodeEditor_CurrentModifierPresetIsCustom = false
			)	
			else if itm == 1 and doesFileExist (thePath + trackID as string +".kmf") do
			(
				currentPreset =  "Custom"
				fileIn (thePath + trackID as string +".kmf")
				KrakatoaChannelEditor_BaseNodeTreeData = deepCopy KrakatoaChannelEditor_NodeTreeData
				KrakatoaChannelsEditor_Functions.fixFlowIDsAfterLoading KrakatoaChannelEditor_BaseNodeTreeData
				KrakatoaChannelsEditor_Functions.buildDisplayTree() 			
				KrakatoaChannelsEditor_Functions.updateParentModifier()
				KrakatoaChannelsEditor_Functions.exposeControlsToModifier this
				if KrakatoaChannelNodeEditor_Rollout.open do KrakatoaChannelNodeEditor_Rollout.createNodeTree init:true
				global KrakatoaChannelNodeEditor_CurrentModifierPresetIsCustom = true	
			)
		)
		
		on edt_notes entered txt do 
		(
			note = txt
			try(Krakatoa_GUI_RenderGlobalValues.updateModifierStackData())catch()
		)
		
		on btn_UpdateExposedParameters pressed do
		(
			--openEditor()
			::FranticParticleRenderMXS.openMagmaFlowEditor this
			KrakatoaChannelsEditor_Functions.exposeControlsToModifier this
			needCAupdate = false
			btn_UpdateExposedParameters.visible = false
		)
			
		
		on main_rollout open do
		(
			edt_notes.text = note
			updateFlowFolders()
			updateFlowList()
			local theIndex = findItem ddl_currentPreset.items currentPreset
			if theIndex == 0 do theIndex = 1
			ddl_currentPreset.selection = theIndex
			local theIndex = findItem ddl_PresetFolders.items currentFolder
			if theIndex == 0 do theIndex = 1
			ddl_PresetFolders.selection = theIndex
			/*if needCAupdate and not isCloningModifier do
			(
				--openEditor()
				::FranticParticleRenderMXS.openMagmaFlowEditor this
				KrakatoaChannelsEditor_Functions.exposeControlsToModifier this
				needCAupdate = false
			)*/
		)
	)
	on create do
	(
		seed (timestamp())
			
		local theClasses = (getClassInstances KrakatoaChannelsModifier)
		local theREMagmaHolders = #()
		local re = maxOps.GetCurRenderElementMgr()
		if re != undefined do
		(
			for i = 0 to (re.numrenderelements()-1) do
			(
				el = re.getrenderelement i
				if classof el == Krakatoa_CustomData and el.MagmaHolder.trackID != undefined do append theREMagmaHolders el.MagmaHolder
			)
			join theClasses theREMagmaHolders 
		)
		local existingIDs = for o in theClasses collect o.TrackID

		do (
			trackID = (random 100000 10000000) as string + "_" + (random 100000 10000000) as string 
		)while findItem existingIDs trackID != 0
		
		local theVal = execute (getIniSetting (getDir #plugcfg+ "\\Krakatoa\\KrakatoaPreferences.ini") "ParticleChannelEditor" "AutoUpdate" )
		if theVal == OK do theVal = false		
		autoUpdate = theVal	
		if selection.count == 1 and classof $ == KrakatoaRenderElementsDataHolder do isRenderElement = true
	)	
	
	on postLoad do
	(
		initArrays()
		KrakatoaChannelNodeEditor_CurrentModifier = this
		KrakatoaChannelEditor_NodeTreeData = execute internalFlow
		KrakatoaChannelsEditor_Functions.fixFlowIDsAfterLoading KrakatoaChannelEditor_NodeTreeData
		internalFlow = with PrintAllElements true (KrakatoaChannelEditor_NodeTreeData as string)
		flow = KrakatoaChannelsEditor_Functions.expandFlow internalFlow --fixtracks:true			
		if interactiveMode do updateNodeDependencies()
	)
	

	on clone theOriginal do 
	(
		isCloningModifier = true
		try(destroyDialog KrakatoaChannelNodeEditor_Rollout)catch()
		seed (timestamp())
			
		local theClasses = (getClassInstances KrakatoaChannelsModifier)
		local theREMagmaHolders = #()
		local re = maxOps.GetCurRenderElementMgr()
		if re!= undefined do
		(
			for i = 0 to (re.numrenderelements()-1) do
			(
				el = re.getrenderelement i
				if classof el == Krakatoa_CustomData and el.MagmaHolder.trackID != undefined do append theREMagmaHolders el.MagmaHolder
			)
		)
		join theClasses theREMagmaHolders 
		local existingIDs = for o in theClasses collect o.TrackID
			
		do (
			trackID = (random 100000 10000000) as string + "_" + (random 100000 10000000) as string 
		)while findItem existingIDs trackID != 0
		
		KrakatoaChannelNodeEditor_CurrentModifier = this
		KrakatoaChannelEditor_NodeTreeData = execute internalFlow
		KrakatoaChannelsEditor_Functions.fixFlowIDsAfterLoading KrakatoaChannelEditor_NodeTreeData
		KrakatoaChannelsEditor_Functions.copyControllersOnClone theOriginal this
		internalFlow = with PrintAllElements true (KrakatoaChannelEditor_NodeTreeData as string)
		flow = KrakatoaChannelsEditor_Functions.expandFlow internalFlow --fixtracks:true
		needCAupdate = true
		isCloningModifier = false
		--FIXME: Causes problems:
		--KrakatoaChannelsEditor_Functions.exposeControlsToModifier this
	)
)
