-- Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
-- SPDX-License-Identifier: Apache-2.0
global Krakatoa_PRTLoader_PresetsOptions 
global Krakatoa_PRTLoader_PresetsOptions_Filename = ""
global Krakatoa_PRTLoader_PresetsOptions_Selection = #{}
--try(destroyDialog Krakatoa_PRTLoader_PresetsOptions)catch()

rollout Krakatoa_PRTLoader_PresetsOptions "PRT Loader Preset Options"
(
local itemsToSave = #(
	
	#("Load Single Frame" , true), 
	#("Frame Offset" , true), 
	#("Enable Playback Graph" , true), 
	#("Limit To Range" , true), 
	#("Before Range Behavior" , true), 
	#("After Range Behavior" , true), 
	
	#("Use Node Transform" , true), 
	
	#("Render Load Mode", true), 
	#("Enabled In Renderer" , true), 
	#("Percent In Renderer" , true), 
	#("Use Render Limit" , true), 
	#("Render Limit" , true), 

	#("View Load Mode" , true), 
	#("Enabled In View" , true), 
	#("Percent In Viewport" , true), 
	#("Use Viewport Limit" , true), 
	#("Viewport Limit" , true), 
	#("Viewport Particle Display Mode" , true), 
	#("Normals Scale" , true), 
	#("Ignore Material" , true), 
	
	#("Show Bounding Box" , true), 
	#("Show Icon" , true), 
	#("Icon Size" , false), 

	#("Normals From Surface" , true), 
	#("Use Surface Threshold" , true), 
	#("Threshold Value" , true), 

	#("Show Count In Viewport" , true), 
	#("Graph Mode" , false) 
)

edittext edt_newPreset "Name:"  text:"PRT Loader Preset" width:190 align:#center --offset:[-3,0]
multilistbox lbx_propertiesToSave "Save The Following Properties:" items:#() height:30 width:190 align:#center
button btn_selectAll "All" width:60 height:18 across:3 align:#left offset:[-5,-3]
button btn_selectInvert "Invert" width:60 height:18 align:#center offset:[0,-3]
button btn_selectDefault "Default" width:60 height:18 align:#right offset:[5,-3]

button btn_savePreset "SAVE PRESET" height:25 width:90 across:2 offset:[0,0]
button btn_cancel "CANCEL" height:25 width:90 align:#right offset:[5,0]

on btn_selectAll pressed do lbx_propertiesToSave.selection = #{1..lbx_propertiesToSave.items.count}
on btn_selectInvert pressed do lbx_propertiesToSave.selection = -lbx_propertiesToSave.selection
on btn_selectDefault pressed do lbx_propertiesToSave.selection = (for i = 1 to itemsToSave.count where itemsToSave[i][2] collect i) as bitarray


on Krakatoa_PRTLoader_PresetsOptions open do
(
	lbx_propertiesToSave.items = for i in itemsToSave collect i[1]
	lbx_propertiesToSave.selection = (for i = 1 to itemsToSave.count where itemsToSave[i][2] collect i) as bitarray
)

on btn_savePreset pressed do
(
	Krakatoa_PRTLoader_PresetsOptions_Filename = edt_newPreset.text
	Krakatoa_PRTLoader_PresetsOptions_Selection = for i in lbx_propertiesToSave.selection collect lbx_propertiesToSave.items[i]
	destroyDialog Krakatoa_PRTLoader_PresetsOptions
)

on btn_cancel pressed do
(
	Krakatoa_PRTLoader_PresetsOptions_Filename = ""
	Krakatoa_PRTLoader_PresetsOptions_Selection = #()
	destroyDialog Krakatoa_PRTLoader_PresetsOptions
)

)

