-- Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
-- SPDX-License-Identifier: Apache-2.0
(
global Krakatoa_PFlowOperator_Functions
global Krakatoa_PFlowOperator_ChannelFloater
global Krakatoa_ChannelSelectorDialog_PFObject
global Krakatoa_PFlowOperator_ChannelDialog

struct Krakatoa_PFlowOperator_FunctionsStruct
(
	theDataArray = #(),
	RCMenuChannelIndex = 0,
	
	fn convertStringToDataArray theData =
	(
		local theFData = filterString theData ","
		theDataArray = #()
		for i = 1 to theFData.count/6 do
			append theDataArray (for j = 1 to 6 collect theFData[j+(i-1)*6])
	),
	
	fn convertDataArrayToString =
	(
		local theString = ""
		for i in theDataArray do
			for j in i do theString += j + ","
		substring theString 1 (theString.count-1)
	),
	
	fn keyOp theChannel =
	(
		RCMenuChannelIndex = theChannel
		RCMenu KeyOpMenu 
		(
			menuItem deleteAllKeys "Delete All Keys"
			on deleteAllKeys picked do 
			(
				deleteKeys Krakatoa_ChannelSelectorDialog_PFObject[Krakatoa_PFlowOperator_Functions.RCMenuChannelIndex].controller #allKeys
				Krakatoa_ChannelSelectorDialog_PFObject[Krakatoa_PFlowOperator_Functions.RCMenuChannelIndex].controller.value = 100
			)
		)
		popupMenu KeyOpMenu pos:mouse.Screenpos
	),
	
	fn returnValue=
	(
		Krakatoa_ChannelSelectorDialog_PFObject.setChannelData (Krakatoa_PFlowOperator_Functions.convertDataArrayToString())
	),
	
	fn OpenChannelSelectorDialog thePFObject =
	(
		if thePFObject.ClassID as string == "#(1788436984, 419639774)" then 
		(
			try(closeRolloutFloater Krakatoa_PFlowOperator_ChannelFloater)catch()
			global Krakatoa_ChannelSelectorDialog_PFObject = thePFObject
			local theChannelData = thePFObject.getChannelData() 
			--local theChannelData = "Position,float32,3,1,Blend,Position,ID,float32,1,0,Blend,ID,Orientation,float32,4,1,Blend,Orientation"
			Krakatoa_PFlowOperator_Functions.convertStringToDataArray theChannelData 
			
			for i = 1 to thePFObject.numsubs where thePFObject[i].controller == undefined do thePFObject[i].controller = bezier_float()
			
			local TargetChannelsByArity = #(
				#("--None--","Age","ID","MXSInteger","MXSFloat"),
				#("--None--"),
				#("--None--","Position","Velocity","Acceleration","Color","TextureCoord","Scale","MXSVector"), 
				#("--None--","Orientation")
			)
			join TargetChannelsByArity[3] (for i = 2 to 99 collect ("Mapping" + i as string))
			local TypeColorByArity = #(red,green,blue,yellow)
			
			local BlendModes = #("Blend", "Add");
			
			global Krakatoa_PFlowOperator_ChannelDialog
			local theStr = "rollout Krakatoa_PFlowOperator_ChannelDialog \"Channels\" (\n" 
			theStr += "label lbl_headers \"                     File Channel and Data Type                                      Target Channel                Blend Mode   Amount    Keys\" offset:[-5,-3]\n"
			local oldState = options.printAllElements 
			options.printAllElements = true
			for i = 1 to theDataArray.count do
			(
				theStr += "checkbutton chk_channel_"+ i as string + " \">" + theDataArray[i][1] + " - "+ theDataArray[i][2] + "[" + theDataArray[i][3] + "]\" width:250 align:#left checked:" + (theDataArray[i][4] == "1") as string + " offset:[-5,-3] across:6 \n"
				theStr += "progressbar prg_type_" + i as string + " width:10 height:21 align:#center offset:[116,-3] value:100 color:"+ TypeColorByArity[execute theDataArray[i][3]] as string +"\n"
				local theSelIndex = (findItem TargetChannelsByArity[execute theDataArray[i][3]] theDataArray[i][6]) 
				if theSelIndex == 0 do theSelIndex = 1
				theStr += "dropdownlist ddl_targetChannel_"+ i as string + " items:"+ TargetChannelsByArity[execute theDataArray[i][3]] as string +" selection:"+ theSelIndex as string +" width:150 align:#center offset:[110,-3]\n"
				local isEnabled = (not matchPattern theDataArray[i][2] pattern:"int*") as string 
				theStr += "dropdownlist ddl_blendmode_"+ i as string + " items:"+ BlendModes as string +" selection:"+ (findItem BlendModes theDataArray[i][5]) as string + " width:60 align:#right offset:[110,-3] enabled:"+ isEnabled +"\n" 
				theStr += "spinner spn_blendvalue_"+ i as string + " range:[0,10000,100] fieldwidth:45 align:#right offset:[75,1] enabled:"+ isEnabled +" controller:Krakatoa_ChannelSelectorDialog_PFObject["+ i as string+"].controller\n"
				theStr += "button btn_KeyOps_"+ i as string + "\">>\" height:16 width:18 align:#right offset:[5,1] enabled:"+ isEnabled +"\n"
				

				theStr += "on chk_channel_"+ i as string + " changed state do (Krakatoa_PFlowOperator_Functions.theDataArray["+ i as string +"][4] = if state then \"1\" else \"0\"; Krakatoa_PFlowOperator_Functions.returnValue())\n"
				theStr += "on ddl_targetChannel_"+ i as string + " selected itm do (Krakatoa_PFlowOperator_Functions.theDataArray["+ i as string +"][6] = ddl_targetChannel_"+ i as string + ".selected; Krakatoa_PFlowOperator_Functions.returnValue())\n"
				theStr += "on ddl_blendmode_"+ i as string + " selected itm do (Krakatoa_PFlowOperator_Functions.theDataArray["+ i as string +"][5] = ddl_blendmode_"+ i as string + ".selected; Krakatoa_PFlowOperator_Functions.returnValue())\n"
				theStr += "on btn_KeyOps_"+ i as string + " pressed do (Krakatoa_PFlowOperator_Functions.keyOp "+ i as string+")\n"
				
			)
			theStr += ")\n"
			options.printAllElements = oldState 

			Krakatoa_PFlowOperator_ChannelDialog = execute theStr
			theSize = (56+theDataArray.count*24)
			if theSize > sysinfo.desktopsize.y - 24 do theSize = sysinfo.desktopsize.y - 24
			theName = try((for o in refs.dependents thePFObject where o.classid as string == "#(1788436984, 419639774)" collect o)[1].name )catch("")
			Krakatoa_PFlowOperator_ChannelFloater = newRolloutFloater ("Krakatoa ParticleFlow File Operator Channels - ["+ theName +"]") 580 theSize
			addRollout Krakatoa_PFlowOperator_ChannelDialog Krakatoa_PFlowOperator_ChannelFloater 
			true
		)
		else false
	)--end fn

)--end struct
Krakatoa_PFlowOperator_Functions = Krakatoa_PFlowOperator_FunctionsStruct()

--Krakatoa_PFlowOperator_Functions.OpenChannelSelectorDialog a

)

