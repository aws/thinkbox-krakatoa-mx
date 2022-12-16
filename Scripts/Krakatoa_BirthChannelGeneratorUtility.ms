-- Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
-- SPDX-License-Identifier: Apache-2.0
macroScript KrakatoaBirthChannelGenerator category:"Krakatoa" buttontext:"BCGen" tooltip:"Krakatoa Birth Channel Generator" icon:#("Krakatoa",31)
(
global KrakatoaBirthChannelGenerator_Rollout
try(destroyDialog KrakatoaBirthChannelGenerator_Rollout)catch()
global Krakatoa_PresetsArrowBitmap
	
rcmenu rcm_inputOptions	
(
	fn isPRTLoader =
	(
		selection.count == 1 and classof selection[1].baseobject == KrakatoaPRTLoader
	)
	fn isKrakatoaRenderer =
	(
		classof renderers.current == Krakatoa and FranticParticles.GetProperty "ParticleFiles" != ""
	)
	
	menuItem mnu_ExplorerFolder "EXPLORE Input Folder..." 
	separator sep_10
	menuItem mnu_GetFromKrakatoa "GET KRAKATOA's Save Particles Path..." enabled:(isKrakatoaRenderer())
	separator sep_20
	menuItem mnu_GetFromPRTLoader "GET SELECTED PRT Loader's First File..." enabled:(isPRTLoader())
	
	on mnu_ExplorerFolder picked do 
	(
		shellLaunch (getFileNamePath KrakatoaBirthChannelGenerator_Rollout.edt_inputSequence.text) ""
	)
	on mnu_GetFromKrakatoa picked do
	(
		KrakatoaBirthChannelGenerator_Rollout.edt_inputSequence.text = FranticParticles.ReplaceSequenceNumber (FranticParticles.GetProperty "ParticleFiles") 0
		KrakatoaBirthChannelGenerator_Rollout.autoSuggestOutputFile()
		KrakatoaBirthChannelGenerator_Rollout.updateUI()
	)
	on mnu_GetFromPRTLoader picked do
	(
		if selection.count == 1 and classof selection[1].baseobject == KrakatoaPRTLoader do
		(
			theFileList = selection[1].baseobject.fileList
			if theFileList.count > 0 do 
				KrakatoaBirthChannelGenerator_Rollout.edt_inputSequence.text = theFileList[1]
			KrakatoaBirthChannelGenerator_Rollout.autoSuggestOutputFile()
			KrakatoaBirthChannelGenerator_Rollout.updateUI()
		)
	)
)

rcmenu rcm_outputOptions	
(
	menuItem mnu_ExplorerFolder "EXPLORE Output Folder..."
	separator sep_10
	menuItem mnu_SetInputToOutput "COPY OUTPUT To Input File Sequence" enabled:(doesFileExist KrakatoaBirthChannelGenerator_Rollout.edt_outputSequence.text)
	separator sep_20
	menuItem mnu_AutoGenerateOutput "AUTO-GENERATE The Output Sequence Filename"
	
	on mnu_ExplorerFolder picked do 
	(
		shellLaunch (getFileNamePath KrakatoaBirthChannelGenerator_Rollout.edt_outputSequence.text) ""
	)
	on mnu_SetInputToOutput picked do
	(
		KrakatoaBirthChannelGenerator_Rollout.edt_inputSequence.text = KrakatoaBirthChannelGenerator_Rollout.edt_outputSequence.text
		KrakatoaBirthChannelGenerator_Rollout.autoSuggestOutputFile forceSuggest:true
		KrakatoaBirthChannelGenerator_Rollout.updateUI()
	)
	on mnu_AutoGenerateOutput picked do
	(
		KrakatoaBirthChannelGenerator_Rollout.autoSuggestOutputFile forceSuggest:true
		KrakatoaBirthChannelGenerator_Rollout.updateUI()
	)
)

local theIniFileLocation = GetDir #plugcfg + "\\Krakatoa\\BirthChannelGeneratorUtility.ini"
local theExePath = FranticParticles.KrakatoaHome + @"Utilities\"
local theEXE = theExePath + "BirthChannelGenerator.exe"

rollout KrakatoaBirthChannelGenerator_Rollout "Krakatoa Birth Channel Generator"	
(
	group "File Sequences"
	(
		button btn_pickInputSequence "Input..." across:3 width:55 height:18 align:#left offset:[-6,0] tooltip:"Select a particle file sequence to generate a Birth channel..."
		edittext edt_inputSequence fieldwidth:410 align:#center text:"" offset:[15,0]
		button btn_inputExplore ">>" width:20 height:18 align:#right offset:[5,0] tooltip:"Open the Input file sequence options menu..."

		button btn_pickOutputSequence "Output..." across:3 width:55 height:18 align:#left offset:[-6,0] tooltip:"Pick manually the particle file sequence filename to save to..."
		edittext edt_outputSequence fieldwidth:410 align:#center text:"" offset:[15,0]
		button btn_outputExplore ">>" width:20 height:18 align:#right offset:[5,0] tooltip:"Open the Output file sequence options menu..."
	)
	group "Channels"
	(
		label lbl_sourceChannel "Input Channel:" across:3 align:#left
		dropdownlist ddl_inputChannel items:#("Position") width:201 align:#center offset:[-50,-3] tooltip:"This list will show the available channels"
		checkbutton chk_autoSuggestOutput ">Auto-Suggest Output Path" align:#right offset:[0,-3] width:180 tooltip:"When checked, selecting an Input Channel from the drop-down list will automatically set the Output filename to a sub-folder with the Birth Channel's name."
		label lbl_outputChannel "Output Channel:" across:3 align:#left
		edittext edt_outputChannel text:"BirthPosition" fieldwidth:200 labelOnTop:true align:#center offset:[-50,0] 
		checkbutton chk_overwriteChannel ">Overwrite Existing Channel" align:#right offset:[0,-3] width:180 tooltip:"When checked, if the Birth channel already exists in the Input sequence, it will be overwritten.\n\nWhen unchecked, if the Birth channel already exists in the Input sequence, the conversion will not be performed."
	)
	group "Options"
	(
		label lbl_IDChannel "ID Channel:" across:4 align:#left
		dropdownlist ddl_IDChannel items:#("ID") width:200 align:#center offset:[10,-3] tooltip:"To track the birth and life of partcles, a valid ID channel must be present in the input sequence.\n\nIn most cases, the 'ID' channel should be used, unless it was saved as 'id', 'Id' or under a completely different name.\n\nThis list will show all int channels in the Input Sequence, but many of them cannot be used in place of an ID."
		button btn_currentTime "Current Time" width:70 align:#center offset:[30,-3]
		spinner spn_startFrame "Base Frame:" range:[-100000,100000,0] type:#integer fieldwidth:35 align:#right tooltip:"Defines the reference point in time to source the BirthChannel from.\n\nThe value will then propagate backward and forward in time for particles that were already born at that time.\n\nParticles born later will get their value from their time of birth.\n\nParticles that died before that time will get their value from their time of death."
		
		checkbutton chk_doNotWait ">Do Not Wait For External Utility To Complete" checked:false across:2 align:#left width:286 tooltip:"When checked, the external BirthGenerator command line utility will be launched in a hidden window, and the UI will become accessible again.\n\nWhen unchecked, the UI will be blocked until the external utility has finished processing the files."
		checkbutton chk_ignorePerFrameErrors ">Ignore Per-Frame Errors" checked:true  align:#right width:186 tooltip:"When checked, errors on individual frames, for example a missing file in the sequence, will not prevent the sequence from being generated.\n\nWhen unchecked, a frame error will cause the processing to halt."
	)
	button btn_convert "GENERATE BIRTH CHANNEL..." width:490 height:30 
	
	fn updateParticleChannels =
	(
		local oldChannel = ddl_inputChannel.selected
		local oldID = ddl_IDChannel.selected
		if doesFileExist edt_inputSequence.text then
		(
			theChannels = FranticParticles.GetFileParticleChannels edt_inputSequence.text
			ddl_inputChannel.items = for c in theChannels where c[1] != "ID" and not matchPattern c[1] pattern:"*Birth*" collect c[1]
			ddl_IDChannel.items = 	for c in theChannels where c[3] == 1 and matchPattern c[2] pattern:"int*" collect c[1]
			local index = findItem ddl_inputChannel.items oldChannel
			if index == 0 do index = 1
			ddl_inputChannel.selection = index
			local index = findItem ddl_IDChannel.items oldID
			if index == 0 do index = 1
			ddl_IDChannel.selection = index
		)
		else
			ddl_IDChannel.items = #("ID")
	)
	
	fn updateUI =
	(
		updateParticleChannels()		
		local enabled = true
		if not doesFileExist edt_inputSequence.text do enabled = false
		if ddl_IDChannel.items.count == 0 do enabled = false
		if tolower (FranticParticles.ReplaceSequenceNumberWithHashes edt_inputSequence.text) == tolower (FranticParticles.ReplaceSequenceNumberWithHashes edt_outputSequence.text) do enabled = false
		btn_convert.enabled = enabled
	)
	
	fn autoSuggestOutputFile forceSuggest:false =
	(
		if chk_autoSuggestOutput.state or forceSuggest do 
		(
			edt_outputSequence.text= getFileNamePath edt_inputSequence.text + edt_outputChannel.text + "\\" + getFileNameFile edt_inputSequence.text + ".prt"
		)
		btn_convert.text = "GENERATE BIRTH CHANNEL ["+ edt_outputChannel.text + "]..."
	)
	
	on btn_currentTime pressed do spn_startFrame.value = sliderTime.frame as integer
	on edt_outputChannel entered txt do
	(
		autoSuggestOutputFile()
	)
	
	on btn_inputExplore pressed do
	(
		popupMenu rcm_inputOptions pos:mouse.screenpos
	)
	
	on btn_outputExplore pressed do
	(
		popupMenu rcm_outputOptions pos:mouse.screenpos
	)
	
	on ddl_inputChannel selected itm do
	(
		edt_outputChannel.text = "Birth"+ ddl_inputChannel.selected
		autoSuggestOutputFile()
	)
	
	on btn_pickInputSequence pressed do
	(
		local theFile = getOpenFileName caption:"Specify Input Sequence Filename" types:"Krakatoa Particle File (*.prt)|*.prt|RealFlow Particle BIN Files (*.bin)|*.bin|Comma Separated Values (*.csv)|*.csv"
		if theFile != undefined do
		(
			edt_inputSequence.text = theFile
			setIniSetting theIniFileLocation "Files" "LastInputSequence" theFile
		)
		autoSuggestOutputFile()		
		updateUI()
	)
	on edt_inputSequence entered txt do
	(
		if doesFileExist txt then
		(
			setIniSetting theIniFileLocation "Files" "LastInputSequence" txt
			autoSuggestOutputFile()		
		)
		else
		(
			edt_inputSequence.text = getIniSetting theIniFileLocation "Files" "LastInputSequence"
		)
		updateUI()
	)
	
	on edt_outputSequence entered txt do
	(
		updateUI()
		setIniSetting theIniFileLocation "Files" "LastOutputSequence" edt_outputSequence.text
	)
	
	
	on btn_pickOutputSequence pressed do
	(
		local theFile = getSaveFileName caption:"Specify Output Sequence Filename" filename:edt_outputSequence.text types:"Krakatoa Particle File (*.prt)|*.prt" 
		if theFile != undefined do
		(
			edt_outputSequence.text = theFile
			setIniSetting theIniFileLocation "Files" "LastInputSequence" theFile
			chk_autoSuggestOutput.state = false
		)
		updateUI()
	)	
	
	fn saveSettings =
	(
		setIniSetting theIniFileLocation "Files" "LastInputSequence" edt_inputSequence.text
		setIniSetting theIniFileLocation "Files" "LastOutputSequence" edt_outputSequence.text
		setIniSetting theIniFileLocation "Options" "AutoSuggestOutput" (chk_autoSuggestOutput.state as string)
		setIniSetting theIniFileLocation "Options" "OverwriteChannel" (chk_overwriteChannel.state as string)
		setIniSetting theIniFileLocation "Options" "IgnorePerFrameErrors" (chk_ignorePerFrameErrors.state as string)
		setIniSetting theIniFileLocation "Options" "DoNotWait" (chk_doNotWait.state as string)
		if ddl_inputChannel.selection > 0 do setIniSetting theIniFileLocation "Channel" "Input" (ddl_inputChannel.selected)
	)	
	
	on btn_convert pressed do
	(
		if tolower (FranticParticles.ReplaceSequenceNumberWithHashes edt_outputSequence.text) == tolower (FranticParticles.ReplaceSequenceNumberWithHashes edt_inputSequence.text) do
		(
			messagebox "The Input and Output Sequences must be different!" title:"Same Sequences!"
			return false
		)
		local thePath = (getfilenamePath edt_outputSequence.text)
		makeDir thePath all:true
		if doesFileExist thePath then
		(
			local q = true
			if doesFileExist edt_outputSequence.text do
				q = querybox "The specified Output Sequence already exists.\nAre you sure you want to overwrite it?" title:"Overwrite Sequence?"
			if q do
			(
				shellLaunch thePath ""
				local theCmdLine = "\"" +theEXE + "\" -i \"" + edt_inputSequence.text +"\" -o \"" + edt_outputSequence.text +"\" -s " + ddl_inputChannel.selected + " -d " + edt_outputChannel.text + " --overwritefile 1 " + "--frame "+ spn_startFrame.value as string+ " "
				theCmdLine += "--overwritechannel " + (if chk_overwriteChannel.checked then "1 " else "0 ")
				if chk_ignorePerFrameErrors.checked do theCmdLine += "--ignore "
				HiddenDOSCommand theCmdLine startpath:theExePath prompt:"Processing Birth Channel... Please Wait!" donotwait:chk_doNotWait.checked
				--format "%\n" theCmdLine
			)
		)
		else
		(
			messagebox "Failed To Create Output Folder" title:"Birth Channel Generator Error:"
		)
	)
	
	on KrakatoaBirthChannelGenerator_Rollout close do saveSettings()
	
	on KrakatoaBirthChannelGenerator_Rollout open do
	(
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
		try(btn_inputExplore.images = btn_outputExplore.images = #(Krakatoa_PresetsArrowBitmap,Krakatoa_PresetsArrowBitmap, 32,1,1,2,2))catch()
		
		
		local val = execute (getIniSetting theIniFileLocation "Options" "AutoSuggestOutput")
		if val == OK do val = true
		chk_autoSuggestOutput.state =  val
		
		local val = execute ( getIniSetting theIniFileLocation "Options" "OverwriteChannel" )
		if val == OK do val = true
		chk_overwriteChannel.state =  val

		local val = execute ( getIniSetting theIniFileLocation "Options" "IgnorePerFrameErrors" )
		if val == OK do val = true
		chk_ignorePerFrameErrors.state = val
		
		local val = execute ( getIniSetting theIniFileLocation "Options" "DoNotWait" )
		if val == OK do val = true
		chk_doNotWait.state = val

		edt_inputSequence.text = getIniSetting theIniFileLocation "Files" "LastInputSequence" 
		edt_outputSequence.text = getIniSetting theIniFileLocation "Files" "LastOutputSequence" 
		if doesFileExist edt_inputSequence.text and edt_outputSequence.text == "" and chk_autoSuggestOutput.checked do autoSuggestOutputFile()
		updateUI()
		
		local val = getIniSetting theIniFileLocation "Channel" "Input"
		local index = findItem ddl_inputChannel.items val 
		if index == 0 do index = 1
		ddl_inputChannel.selection = index
		edt_outputChannel.text = "Birth"+ ddl_inputChannel.selected
	)
	
	on KrakatoaBirthChannelGenerator_Rollout moved pos do 
	(
		setINIsetting theIniFileLocation "Dialog" "Position" (pos as string)
	)	
)--end rollout
if classof FranticParticles == Interface and doesFileExist theEXE then 
(
	local pos = execute (getINIsetting theIniFileLocation "Dialog" "Position")
	
	if pos != OK then 
	(
		local theDesktop = sysInfo.DesktopSize
		if pos.x < 0 do pos.x = 0
		if pos.x > theDesktop.x do pos.x = theDesktop.x-500
		if pos.y < 0 do pos.y = 0
		if pos.y > theDesktop.y do pos.y = theDesktop.y-255
		createDialog KrakatoaBirthChannelGenerator_Rollout 500 255 pos.x pos.y
	)
	else
		createDialog KrakatoaBirthChannelGenerator_Rollout 500 255
)
else 
	messagebox "The Krakatoa MX Installation Is Incomplete.\nPlease try reinstalling!" title:"ERROR Launching Utility"
)--end macro