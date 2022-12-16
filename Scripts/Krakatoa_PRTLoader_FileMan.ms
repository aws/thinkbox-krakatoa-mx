-- Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
-- SPDX-License-Identifier: Apache-2.0
------------------------------------------------------------------------------------------------------------------------
--PARTICLE LOADER FILE SEQUENCE MANAGER
------------------------------------------------------------------------------------------------------------------------
global Krakatoa_PRTLoader_FileEditor
global Krakatoa_PRTLoader_FileEditor_CutCopyPasteBuffer 
if Krakatoa_PRTLoader_FileEditor_CutCopyPasteBuffer == undefined do 
	Krakatoa_PRTLoader_FileEditor_CutCopyPasteBuffer = #()
global Krakatoa_PRTLoader_FileEditor_RCMenu 
global Krakatoa_PRTLoader_FileEditor_MainMenu 
global Krakatoa_PRTLoader_SelectPartitions, Krakatoa_PresetsArrowBitmap
rcmenu Krakatoa_PRTLoader_FileEditor_MainMenu 
(
	fn isPRTLoader = try(classof Krakatoa_PRTLoader_FileEditor.currentPRTLoader.baseobject == KrakatoaPRTLoader)catch(false)

	submenu "File"
	(
		menuItem loadFiles "Load File List..."
		menuItem saveFiles "Save File List..."
		menuItem saveSelectedFiles "Save Selected Files..."
		separator file_separator01
		menuItem addFiles "Add Files..."
		separator file_separator10
		
		menuItem addFilesFromFolder "Add Files From Folder..."
		menuItem addFilesFromFolders "Add Files From Folders Recursively..."
		
		separator file_separator20
		menuItem repathFiles "Repath Selected Files..."
		separator file_separator30
		menuItem removeFiles "Remove Selected..."
		menuItem removeAll "Remove All..."
		separator file_separator40
		menuItem closeDialog "Close"
	)
	submenu "Edit"
	(
		menuItem selectAll "Select All"
		menuItem selectInvert "Select Invert"
		separator edit_separator01
		menuItem cutFiles "Cut Selected"
		menuItem copyFiles "Copy Selected"
		menuItem pasteFiles "Paste" --enabled:(doesFileExist (Krakatoa_PresetsDirectory+ "\\FileSequences\\_Clipboard.txt")) --(Krakatoa_PRTLoader_FileEditor_CutCopyPasteBuffer.count > 0)
	)
	submenu "Reorder" 
	(
		menuItem moveTop "Move To Top" 
		menuItem moveUp  "Move Up"
		menuItem moveDown  "Move Down"
		menuItem moveBottom "Move To Bottom"
		separator edit_separator02
		menuItem sortList "Sort File List"
	)	
	submenu "Toggle" 
	(
		menuItem toggleSelInView "Toggle Selected In View" enabled:(isPRTLoader())
		menuItem toggleAllInView "Toggle All In View" enabled:(isPRTLoader())
		separator toggle_separator01 enabled:(isPRTLoader())
		menuItem toggleSelInRender "Toggle Selected In Render" enabled:(isPRTLoader())
		menuItem toggleAllInRender "Toggle All In Render" enabled:(isPRTLoader())
		separator toggle_separator05 enabled:(isPRTLoader())
		--menuItem enableSelInView "Enable Selected In View" enabled:(isPRTLoader())
		--menuItem disableSelInView "Disable Selected In View" enabled:(isPRTLoader())
		menuItem enableAllInView "Enable All In View" enabled:(isPRTLoader())
		menuItem disableAllInView "Disable All In View" enabled:(isPRTLoader())
		separator toggle_separator10 enabled:(isPRTLoader())
		--menuItem enableSelInRender "Enable Selected In Render" enabled:(isPRTLoader())
		--menuItem disableSelInRender "Disable Selected In Render" enabled:(isPRTLoader())
		menuItem enableAllInRender "Enable All In Render" enabled:(isPRTLoader())
		menuItem disableAllInRender "Disable All In Render" enabled:(isPRTLoader())
		separator toggle_separator20 enabled:(isPRTLoader())
		menuItem soloSelInView "Solo Selected In View" enabled:(isPRTLoader())
		menuItem soloSelInRender "Solo Selected In Render" enabled:(isPRTLoader())
	)
	
	menuItem enableSelInView "[View ON]" enabled:(isPRTLoader())
	menuItem disableSelInView "[View OFF]" enabled:(isPRTLoader())
	
	menuItem enableSelInRender "[Rend ON]" enabled:(isPRTLoader())
	menuItem disableSelInRender "[Rend OFF]" enabled:(isPRTLoader())
		
	menuItem updateEditor "[UPDATE]" enabled:(isPRTLoader())
		
	on updateEditor picked do Krakatoa_PRTLoader_FileEditor.updateEditor()
	
	
	on saveFiles picked do Krakatoa_PRTLoader_FileEditor.saveFiles selectedOnly:false
	on saveSelectedFiles picked do Krakatoa_PRTLoader_FileEditor.saveFiles selectedOnly:true
	on loadFiles picked do Krakatoa_PRTLoader_FileEditor.loadFiles()
	
	on addFiles picked do Krakatoa_PRTLoader_FileEditor.addFiles()
	on addFilesFromFolder picked do Krakatoa_PRTLoader_FileEditor.addFilesFromFolder()
	on addFilesFromFolders picked do Krakatoa_PRTLoader_FileEditor.addFilesFromFolders()
	
	on repathFiles picked do Krakatoa_PRTLoader_FileEditor.repathFiles()
	
	on selectAll picked do Krakatoa_PRTLoader_FileEditor.selectAll()
	on selectInvert picked do Krakatoa_PRTLoader_FileEditor.selectInvert()
	
	on moveTop picked do Krakatoa_PRTLoader_FileEditor.moveBlock #top
	on moveBottom picked do Krakatoa_PRTLoader_FileEditor.moveBlock #bottom
	on moveUp picked do Krakatoa_PRTLoader_FileEditor.moveBlock #up
	on moveDown picked do Krakatoa_PRTLoader_FileEditor.moveBlock #down
	on sortList picked do Krakatoa_PRTLoader_FileEditor.sortSequences()
	
	on cutFiles picked do Krakatoa_PRTLoader_FileEditor.cutSequences()
	on copyFiles picked do Krakatoa_PRTLoader_FileEditor.copySequences()
	on pasteFiles picked do Krakatoa_PRTLoader_FileEditor.pasteSequences()
	
	on removeFiles picked do Krakatoa_PRTLoader_FileEditor.removeFiles selectedOnly:true
	on removeAll picked do Krakatoa_PRTLoader_FileEditor.removeFiles selectedOnly:false

	on closeDialog picked do try(destroyDialog Krakatoa_PRTLoader_FileEditor)catch()

	on toggleSelInView picked do Krakatoa_PRTLoader_FileEditor.ToggleVRIn #View true selectedOnly:true invert:true
	on toggleAllInView picked do Krakatoa_PRTLoader_FileEditor.ToggleVRIn #View true selectedOnly:false invert:true
	on toggleSelInRender picked do Krakatoa_PRTLoader_FileEditor.ToggleVRIn #Render true selectedOnly:true invert:true
	on toggleAllInRender picked do Krakatoa_PRTLoader_FileEditor.ToggleVRIn #Render true selectedOnly:false invert:true
	
	on enableSelInView picked do Krakatoa_PRTLoader_FileEditor.ToggleVRIn #View true selectedOnly:true
	on disableSelInView picked do Krakatoa_PRTLoader_FileEditor.ToggleVRIn #View false selectedOnly:true
	on enableAllInView picked do Krakatoa_PRTLoader_FileEditor.ToggleVRIn #View true selectedOnly:false
	on disableAllInView picked do Krakatoa_PRTLoader_FileEditor.ToggleVRIn #View false selectedOnly:false

	on enableSelInRender picked do Krakatoa_PRTLoader_FileEditor.ToggleVRIn #Render true selectedOnly:true
	on disableSelInRender picked do Krakatoa_PRTLoader_FileEditor.ToggleVRIn #Render false selectedOnly:true
	on enableAllInRender picked do Krakatoa_PRTLoader_FileEditor.ToggleVRIn #Render true selectedOnly:false
	on disableAllInRender picked do Krakatoa_PRTLoader_FileEditor.ToggleVRIn #Render false selectedOnly:false

	on soloSelInView picked do 
	(
		Krakatoa_PRTLoader_FileEditor.ToggleVRIn #View false selectedOnly:false
		Krakatoa_PRTLoader_FileEditor.ToggleVRIn #View true selectedOnly:true
	)	
	on soloSelInRender picked do 
	(
		Krakatoa_PRTLoader_FileEditor.ToggleVRIn #Render false selectedOnly:false
		Krakatoa_PRTLoader_FileEditor.ToggleVRIn #Render true selectedOnly:true
	)		
)

rcmenu Krakatoa_PRTLoader_FileEditor_RcMenu 
(
	subMenu "File List Loading And Saving"
	(
		menuItem loadFiles "Load File List..."
		menuItem saveFiles "Save File List..."
		menuItem saveSelectedFiles "Save Selected Files..."	
	)	
	separator file_separator01
	menuItem addFiles "Add Files..."
	separator file_separator10
	menuItem addFilesFromFolder "Add Files From Folder..."
	menuItem addFilesFromFolders "Add Files From Folders Recursively..."	
	separator file_separator20
	menuItem repathFiles "Repath Selected Files..."
	separator file_separator30
	menuItem selectAll "Select All"
	menuItem selectInvert "Select Invert"
	separator file_separator40
	menuItem cutFiles "Cut Selected"
	menuItem copyFiles "Copy Selected"
	menuItem pasteFiles "Paste" --enabled:(Krakatoa_PRTLoader_FileEditor_CutCopyPasteBuffer.count > 0)
	
	separator edit_separator10
	subMenu "Reorder List"
	(
		menuItem moveTop "Move To Top"
		menuItem moveUp  "Move Up"
		menuItem moveDown  "Move Down"
		menuItem moveBottom "Move To Bottom"
		separator edit_separator20
		menuItem sortList "Sort File List"
	)	
	separator edit_separator30
	subMenu "Toggle"
	(
		menuItem toggleSelInView "Toggle Selected In View"
		menuItem toggleAllInView "Toggle All In View"
		separator toggle_separator01
		menuItem toggleSelInRender "Toggle Selected In Render"
		menuItem toggleAllInRender "Toggle All In Render"
		separator toggle_separator05
		menuItem enableSelInView "Enable Selected In View"
		menuItem disableSelInView "Disable Selected In View"
		menuItem enableAllInView "Enable All In View"
		menuItem disableAllInView "Disable All In View"
		separator toggle_separator10
		menuItem enableSelInRender "Enable Selected In Render"
		menuItem disableSelInRender "Disable Selected In Render"
		menuItem enableAllInRender "Enable All In Render"
		menuItem disableAllInRender "Disable All In Render"
		separator toggle_separator20
		menuItem soloSelInView "Solo Selected In View"
		menuItem soloSelInRender "Solo Selected In Render"
	)
	separator edit_separator40
	subMenu "Remove"
	(
		menuItem removeFiles "Remove Selected..."
		menuItem removeAll "Remove All..."	
	)	


	on saveFiles picked do Krakatoa_PRTLoader_FileEditor.saveFiles selectedOnly:false
	on saveSelectedFiles picked do Krakatoa_PRTLoader_FileEditor.saveFiles selectedOnly:true
	
	on loadFiles picked do Krakatoa_PRTLoader_FileEditor.loadFiles()
	
	on addFiles picked do Krakatoa_PRTLoader_FileEditor.addFiles()
	on addFilesFromFolder picked do Krakatoa_PRTLoader_FileEditor.addFilesFromFolder()
	on addFilesFromFolders picked do Krakatoa_PRTLoader_FileEditor.addFilesFromFolders()
	
	on repathFiles picked do Krakatoa_PRTLoader_FileEditor.repathFiles()
	
	on selectAll picked do Krakatoa_PRTLoader_FileEditor.selectAll()
	on selectInvert picked do Krakatoa_PRTLoader_FileEditor.selectInvert()
	
	on moveTop picked do Krakatoa_PRTLoader_FileEditor.moveBlock #top
	on moveBottom picked do Krakatoa_PRTLoader_FileEditor.moveBlock #bottom
	on moveUp picked do Krakatoa_PRTLoader_FileEditor.moveBlock #up
	on moveDown picked do Krakatoa_PRTLoader_FileEditor.moveBlock #down
	on sortList picked do Krakatoa_PRTLoader_FileEditor.sortSequences()
	
	on cutFiles picked do Krakatoa_PRTLoader_FileEditor.cutSequences()
	on copyFiles picked do Krakatoa_PRTLoader_FileEditor.copySequences()
	on pasteFiles picked do Krakatoa_PRTLoader_FileEditor.pasteSequences()
	
	on removeFiles picked do Krakatoa_PRTLoader_FileEditor.removeFiles selectedOnly:true
	on removeAll picked do Krakatoa_PRTLoader_FileEditor.removeFiles selectedOnly:false

	on toggleSelInView picked do Krakatoa_PRTLoader_FileEditor.ToggleVRIn #View true selectedOnly:true invert:true
	on toggleAllInView picked do Krakatoa_PRTLoader_FileEditor.ToggleVRIn #View true selectedOnly:false invert:true
	on toggleSelInRender picked do Krakatoa_PRTLoader_FileEditor.ToggleVRIn #Render true selectedOnly:true invert:true
	on toggleAllInRender picked do Krakatoa_PRTLoader_FileEditor.ToggleVRIn #Render true selectedOnly:false invert:true

	on enableSelInView picked do Krakatoa_PRTLoader_FileEditor.ToggleVRIn #View true selectedOnly:true
	on disableSelInView picked do Krakatoa_PRTLoader_FileEditor.ToggleVRIn #View false selectedOnly:true
	on enableAllInView picked do Krakatoa_PRTLoader_FileEditor.ToggleVRIn #View true selectedOnly:false
	on disableAllInView picked do Krakatoa_PRTLoader_FileEditor.ToggleVRIn #View false selectedOnly:false

	on enableSelInRender picked do Krakatoa_PRTLoader_FileEditor.ToggleVRIn #Render true selectedOnly:true
	on disableSelInRender picked do Krakatoa_PRTLoader_FileEditor.ToggleVRIn #Render false selectedOnly:true
	on enableAllInRender picked do Krakatoa_PRTLoader_FileEditor.ToggleVRIn #Render true selectedOnly:false
	on disableAllInRender picked do Krakatoa_PRTLoader_FileEditor.ToggleVRIn #Render false selectedOnly:false

	on soloSelInView picked do 
	(
		Krakatoa_PRTLoader_FileEditor.ToggleVRIn #View false selectedOnly:false
		Krakatoa_PRTLoader_FileEditor.ToggleVRIn #View true selectedOnly:true
	)	
	on soloSelInRender picked do 
	(
		Krakatoa_PRTLoader_FileEditor.ToggleVRIn #Render false selectedOnly:false
		Krakatoa_PRTLoader_FileEditor.ToggleVRIn #Render true selectedOnly:true
	)	
	
)



rollout Krakatoa_PRTLoader_FileEditor "Krakatoa PRT Loader - File Sequence Manager"
(
	local currentPRTLoader
	local layout_def = #()
	local layout_dynamic = #()
	local layout_dynamic_md = #()
	
	fn getSelection lv =
	(
		local theSel = #()
		for i in 0 to lv.Items.count-1 do
		(
			li = lv.Items.item[i]
			if li.selected do append theSel (i+1)
		)
		theSel
	)		
	
	fn setSelection lv theSel =
	(
		for i in theSel do
			lv.Items.item[(i-1)].selected = true
		lv.update()		
	)
	
	fn invertSelection lv =
	(
		for i in 0 to lv.Items.count-1 do
			lv.Items.item[i].selected = not lv.Items.item[i].selected
		lv.update()	
	)	
	
	fn initListView lv = 
	(
		lv.columns.clear()	
		local lightColor = (dotNetClass "System.Drawing.Color").fromARGB 221 221 225
		local darkColor = (dotNetClass "System.Drawing.Color").fromARGB 50 50 55
		local maxBgColor = (((colorman.getcolor #window)) as color)*255
		if maxBgColor.v >= 160 then
		(
			lv.backColor = lightColor
		)
		else
		(
			lv.backColor = darkColor
		)
		
		lv.View = (dotNetClass "System.Windows.Forms.View").Details
		lv.gridLines = true
		
		lv.fullRowSelect = true 
		lv.checkboxes = false
		lv.hideSelection = false
		for i in layout_def do lv.Columns.add i[1] i[2]
	)
	
	fn getCurrentTime currentPRTLoader =
	(
		local theTime = currentTime.frame as integer 
		if currentPRTLoader.enablePlaybackGraph do theTime = (at time theTime currentPRTLoader.playbackGraphTime) as integer
		theTime += currentPRTLoader.frameOffset
		if currentPRTLoader.limitToRange do
		(
			if theTime > currentPRTLoader.rangeEndFrame do theTime = currentPRTLoader.rangeEndFrame
			if theTime < currentPRTLoader.rangeStartFrame do theTime = currentPRTLoader.rangeStartFrame
		)
		theTime
	)
	
	fn fillInSpreadSheet lv =
	(
		lv.Items.clear()	
		theRange = #() 

		local maxBgColor = (((colorman.getcolor #window)) as color)*255
		if maxBgColor.v >= 160 then
		(
			red_bg = (dotNetClass "System.Drawing.Color").fromARGB 215 0 0 
			vrColor =  (dotNetClass "System.Drawing.Color").fromARGB 0 0 0
			rColor =  (dotNetClass "System.Drawing.Color").fromARGB 0 0 200
			vColor =  (dotNetClass "System.Drawing.Color").fromARGB 0 128 200
			nColor = (dotNetClass "System.Drawing.Color").fromARGB 128 128 128
		)
		else
		(
			red_bg = (dotNetClass "System.Drawing.Color").fromARGB 255 100 100
			vrColor =  (dotNetClass "System.Drawing.Color").fromARGB 220 220 220
			rColor =  (dotNetClass "System.Drawing.Color").fromARGB 150 170 255
			vColor =  (dotNetClass "System.Drawing.Color").fromARGB 150 235 225
			nColor =  (dotNetClass "System.Drawing.Color").fromARGB 120 120 120
		)		
		local theTime = getCurrentTime currentPRTLoader
		--Krakatoa_PRTLoader_FileEditor.title = 
		for theFile = 1 to currentPRTLoader.fileList.count do
		(
			local theFileListItem = currentPRTLoader.fileList[theFile]
			if not currentPRTLoader.loadSingleFrame do
			(
				theFileListItem = FranticParticles.ReplaceSequenceNumber theFileListItem theTime
			)
			
			local li = dotNetObject "System.Windows.Forms.ListViewItem" (getFileNameFile theFileListItem)
			
			li.forecolor = case currentPRTLoader.fileListFlags[theFile] of
			(
				default: nColor
				1: vColor
				2: rColor
				3: vrColor
			)		
			if not doesFileExist theFileListItem do li.forecolor =  (dotNetClass "System.Drawing.Color").fromARGB (red_bg.r) li.forecolor.g li.forecolor.b
			
			local sub_li = li.SubItems.add (getFileNameType theFileListItem)
			if classof currentPRTLoader.baseobject == krakatoaPRTLoader do
			(
				local sub_li = li.SubItems.add (if bit.Get currentPRTLoader.fileListFlags[theFile] 1 then "View" else "--")
				local sub_li = li.SubItems.add (if bit.Get currentPRTLoader.fileListFlags[theFile] 2 then "Rend" else "--")
			)
			local sub_li = li.SubItems.add (getFileNamePath theFileListItem)
			local sub_li = li.SubItems.add (if doesFileExist theFileListItem then "Yes" else "No")
			
			for i in layout_dynamic_md do
			(
				theMetaData = "--"
				for j in try(FranticParticles.GetFileParticleMetadata theFileListItem)catch(#()) do
				(
					for kk = 1 to j[2].count do
					(
						local k = j[2][kk]
						if k[1] == i AND k[1] != "Interpretation" do
						(
							theMetaData = case k[1] as name of
							(									
								#LengthUnitInMicrometers: ( k[2][1] as string)
								#LengthUnitInMeters: (formattedPrint k[2][1] format:"12.12g")
								#BoundBox: ( "Min:["+ k[2][1] as string +","+k[2][2] as string + "," + k[2][3] as string + "] Max:["+ k[2][4] as string +","+k[2][5] as string + "," + k[2][6] as string + "]" )
								#Extents: ( "Min:["+ k[2][1] as string +","+k[2][2] as string + "," + k[2][3] as string + "] Max:["+ k[2][4] as string +","+k[2][5] as string + "," + k[2][6] as string + "]" )
								#Coordsys: (
									case k[2][1] of
									(
										1: "Y Up RH (Maya)"
										2: "Z Up RH (3dsMax)"
										3: "Y Up LH (RealFlow)"
										4: "Z Up LH"
										default: "???"
									)
								)
								default: k[2] 
							)
						)
					)
				)						
				sub_li = li.SubItems.add (theMetaData as string)
			)
			
			local theChannels = try(FranticParticles.GetFileParticleChannels theFileListItem)catch(#())
			if theChannels == undefined do theChannels = #()
			for i in layout_dynamic do
			(
				local theChannel = for c in theChannels where matchPattern c[1] pattern:i collect c
				if theChannel.count == 1 then
				(
					local semanticString = ""
					local extentsString = ""
					for j in try(FranticParticles.GetFileParticleMetadata theFileListItem)catch(#()) where j[1] == theChannel[1][1] do
					(
						for kk = 1 to j[2].count do
						(
							local k = j[2][kk]
							if k[1] == "Interpretation" do
							(
								semanticString = k[2][1] 
							)
							if k[1] == "Extents" do
							(
								extentsString = " Min:["+ k[2][1] as string + "," + k[2][2] as string +"," +k[2][3] as string +"] Max:["+ k[2][4] as string + "," + k[2][5] as string +"," +k[2][6] as string +"]"
							)
						)
					)
					sub_li = li.SubItems.add (theChannel[1][2]+"["+theChannel[1][3] as string +"] " + semanticString+extentsString)
				)
				else
					sub_li = li.SubItems.add "--"
			)
			append theRange li
		)
		--showProperties lv
		lv.Items.AddRange theRange 	
	)

	fn getFileDialogSize =
	(
		theSize = execute (getIniSetting (Krakatoa_PresetsDirectory+ "\\KrakatoaPreferences.ini") "Dialog" "FileManagerSize")
		if classof theSize != Point2 then theSize = [800,500] 
		if theSize.x < 200 do theSize.x = 200
		if theSize.y < 200 do theSize.y = 200
		theSize
	)
--End Part 1	


------------------------------------------------------------------------------------------------------------------------------------------------	
--DOT NET CONTROLS
------------------------------------------------------------------------------------------------------------------------------------------------	
	dotNetControl lv_filesToLoad "System.Windows.Forms.ListView" \
		width:((getFileDialogSize()).x-10) \
		height:((getFileDialogSize()).y-10) \
		align:#center 
	on lv_filesToLoad MouseClick itm do 
		if itm.Button.Equals itm.Button.Right then 
			popupmenu Krakatoa_PRTLoader_FileEditor_RCMenu pos:mouse.screenpos
------------------------------------------------------------------------------------------------------------------------------------------------	
		

	on Krakatoa_PRTLoader_FileEditor rbuttondown pos do
		popupmenu Krakatoa_PRTLoader_FileEditor_RCMenu pos:mouse.screenpos

	fn refreshColumns =
	(
		--currentPRTLoader.params.btn_editFiles.pressed()
	)
	
	fn stillSelected =
	(
		isValidNode currentPRTLoader and currentPRTLoader.isSelected
	)
	
	fn updateEditor =
	(	
		currentPRTLoaders = for o in selection where classof o.baseobject == KrakatoaPrtLoader or classof o.baseobject == Frost collect o
		if currentPRTLoaders.count > 0 then
		(
			currentPRTLoader = currentPRTLoaders[1]
			local theTime = getCurrentTime currentPRTLoader
			
			Krakatoa_PRTLoader_FileEditor.title = case currentPRTLoaders.count of
			(
			1: ("[" + currentPRTLoader.name +"] - File Sequence Manager - Frame "+theTime as string)
			2: ("[" + currentPRTLoader.name +"] + 1 Instance - File Sequence Manager - Frame "+theTime as string)
			default: ("[" + currentPRTLoader.name +"] + "+ (currentPRTLoaders.count-1) as string +" Instances - File Sequence Manager - Frame "+theTime as string)
			)		
			if classof currentPRTLoader == Frost then
			(
				layout_def = #(#("File Name", 150), #("Type",40), #("Full Path",200), #("Found",45))
				layout_dynamic = #()
				layout_dynamic_md = #()	
				for i in currentPRTLoader.fileList where doesFileExist i do
				(					
					for j in try(FranticParticles.GetFileParticleMetadata i)catch(#()) do
					(
						if j[1] == "" do
						(
							for k in j[2] do
							(
								if findItem layout_dynamic_md k[1] == 0 do 
								(
									append layout_dynamic_md k[1]
									append layout_def #(k[1],100)
								)							
							)
						)
					)	
				)						
					
				for i in currentPRTLoader.fileList where doesFileExist i do
				(
					for j in try(FranticParticles.GetFileParticleChannels i)catch(#()) do
					(
						if findItem layout_dynamic j[1] == 0 do 
						(
							append layout_dynamic j[1]
							append layout_def #(j[1],60)
						)	
					)	
				)				
			)
			else
			(
				
				layout_def = #(#("File Name", 150), #("Type",40), #("View",40), #("Rend",40), #("Full Path",200), #("Found",45))
				layout_dynamic = #()
				layout_dynamic_md = #()	
					
				for i in currentPRTLoader.fileList where doesFileExist i do
				(					
					for j in try(FranticParticles.GetFileParticleMetadata i)catch(#()) do
					(
						if j[1] == "" do
						(
							for k in j[2] do
							(
								if findItem layout_dynamic_md k[1] == 0 do 
								(
									append layout_dynamic_md k[1]
									append layout_def #(k[1],100)
								)							
							)
						)
					)	
				)					
				for i in currentPRTLoader.fileList where doesFileExist i do
				(
					for j in try(FranticParticles.GetFileParticleChannels i)catch(#()) do
					(
						if findItem layout_dynamic j[1] == 0 do 
						(
							append layout_dynamic j[1]
							append layout_def #(j[1],90)
						)	
					)	
				)
			)
			
			initListView lv_filesToLoad
			fillInSpreadSheet lv_filesToLoad
		)	
		else
			destroyDialog Krakatoa_PRTLoader_FileEditor	
	)	

	fn moveBlock mode =
	(
		if stillSelected()  then
		(
			if currentPRTLoader.fileList.count > 1 then
			(
				with undo "PRT Move Block" on
				(
					theSel = getSelection lv_filesToLoad
					theTemp = for i in theSel collect currentPRTLoader.fileList[i]
					local isPRTLoader = classof currentPRTLoader.baseobject == KrakatoaPRTLoader
					if isPRTLoader do theTemp2 = for i in theSel collect currentPRTLoader.fileListFlags[i]
					for i = theSel.count to 1 by -1 do 
					(
						deleteItem currentPRTLoader.fileList theSel[i]
						if isPRTLoader do deleteItem currentPRTLoader.fileListFlags theSel[i]
					)	
					case mode of
					(
						#top: 
						(
							theSel = for i = 1 to theTemp.count collect i
							currentPRTLoader.fileList = join theTemp currentPRTLoader.fileList
							if isPRTLoader do currentPRTLoader.fileListFlags = join theTemp2 currentPRTLoader.fileListFlags
						)	
						#bottom: 
						(
							currentPRTLoader.fileList = join (for i in currentPRTLoader.fileList collect i) theTemp 
							if isPRTLoader do currentPRTLoader.fileListFlags = join (for i in currentPRTLoader.fileListFlags collect i) theTemp2 
							theSel = for i = 1 to theTemp.count collect currentPRTLoader.fileList.count-i+1
						)	
						#up: 
						(
							cnt = 0
							theSel = for i in theSel collect (if i > 1 then (i-1) else i)
							for i in theSel do
							(
								cnt += 1
								currentPRTLoader.fileList = insertItem theTemp[cnt] currentPRTLoader.fileList (i)
								if isPRTLoader do currentPRTLoader.fileListFlags = insertItem theTemp2[cnt] currentPRTLoader.fileListFlags (i)
							)	
						)
						#down: 
						(
							cnt = 0
							theSel = for i in theSel collect (if i < currentPRTLoader.fileList.count then (i+1) else i)
							for i in theSel do
							(
								cnt += 1
								currentPRTLoader.fileList = insertItem theTemp[cnt] currentPRTLoader.fileList (i)
								if isPRTLoader do currentPRTLoader.fileListFlags = insertItem theTemp2[cnt] currentPRTLoader.fileListFlags (i)
							)	
						)			
					)
					fillInSpreadSheet lv_filesToLoad
					setSelection lv_filesToLoad theSel
				)	
			)
		)
		else
			try(destroyDialog Krakatoa_PRTLoader_FileEditor)catch()
	)
	
	fn compareFN v1 v2 valArray: =
	(
		local v1i = valArray[v1]
		local v2i = valArray[v2]
		if v1i > v2i then 1 else -1
	)
	
	fn sortSequences =
	(
		if stillSelected() then
		(	
			with undo "PRT Sort" on 
			(
				indexArray = for i = 1 to currentPRTLoader.fileList.count collect i
				qsort indexArray compareFN valArray:currentPRTLoader.fileList
				currentPRTLoader.fileList = for i in indexArray collect currentPRTLoader.fileList[i]
				if classof currentPRTLoader.baseobject == KrakatoaPRTLoader do 
					currentPRTLoader.fileListFlags = for i in indexArray collect currentPRTLoader.fileListFlags[i]
			)
			fillInSpreadSheet lv_filesToLoad
		)	
		else
			try(destroyDialog Krakatoa_PRTLoader_FileEditor)catch()		
	)	
	fn selectInvert = 
	( 
		if stillSelected() then
		(	
			invertSelection lv_filesToLoad 
		)	
		else
			try(destroyDialog Krakatoa_PRTLoader_FileEditor)catch()			
	)
	
	fn selectAll = 
	( 
		if stillSelected() then
		(	
			setSelection lv_filesToLoad (for i = 1 to currentPRTLoader.fileList.count collect i) 
		)
		else
			try(destroyDialog Krakatoa_PRTLoader_FileEditor)catch()	
	)
	
	fn addFilesFromFolder =
	(
		if stillSelected() then
		(	
			if classof currentPRTLoader.baseobject == KrakatoaPRTLoader then
			(
				local rootName = ""
				local pathMode = (getIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "Preferences" "CreateLoadersBehavior")
				if pathMode == "1" do
					rootName = try(FranticParticles.GetProperty "ParticleFiles")catch("")
				if pathMode == "2" or rootName == "" do	
					rootName = (getIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "Preferences" "DefaultLoaderPath")
				
				local theDir = getSavePath initialDir:rootName
				if theDir  != undefined do
				(
					local theFiles = getFiles (theDir +"\\*.prt")
					local theFilesToAdd = #()
					local theActualFilesToAdd = #()
					for f in theFiles do
					(
						theName = FranticParticles.ReplaceSequenceNumberWithHashes f
						if findItem theFilesToAdd theName == 0 do 
						(
							append theFilesToAdd theName
							append theActualFilesToAdd f
						)
					)
					local tempList = for f in currentPRTLoader.fileList collect f
					local tempFlags = for i in currentPRTLoader.fileListFlags collect i
					for f in theActualFilesToAdd where findItem tempList f == 0 do 
					(
						append tempList f
						append tempFlags 2
					)
					with undo "Add PRTs From Folder" on
					(
						currentPRTLoader.fileList = tempList
						currentPRTLoader.fileListFlags = tempFlags
					)
					updateEditor()
					select currentPRTLoader
				)
			)
		)	
		else
			try(destroyDialog Krakatoa_PRTLoader_FileEditor)catch()			
	)
	
	local foldersToScan = #()
	fn collectSubFolders theRoot =
	(
		theDirs = getDirectories (theRoot + "*")
		for d in theDirs do 
		(
			append foldersToScan d
			collectSubFolders d
		)
	)
	
	fn addFilesFromFolders =
	(
		if stillSelected() then
		(	
			if classof currentPRTLoader.baseobject == KrakatoaPRTLoader then
			(
				local rootName = ""
				local pathMode = (getIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "Preferences" "CreateLoadersBehavior")
				if pathMode == "1" do
					rootName = try(FranticParticles.GetProperty "ParticleFiles")catch("")
				if pathMode == "2" or rootName == "" do	
					rootName = (getIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "Preferences" "DefaultLoaderPath")
				
				
				local theDir = getSavePath initialDir:rootName
				if theDir  != undefined do
				(
					foldersToScan = #()
					collectSubFolders theDir
					local theFilesToAdd = #()
					local theActualFilesToAdd = #()					
					for d in foldersToScan do
					(
						local theFiles = getFiles (d +"*.prt")
						for f in theFiles do
						(
							theName = FranticParticles.ReplaceSequenceNumberWithHashes f
							if findItem theFilesToAdd theName == 0 do 
							(
								append theFilesToAdd theName
								append theActualFilesToAdd f
							)
						)
					)
					local tempList = for f in currentPRTLoader.fileList collect f
					local tempFlags = for i in currentPRTLoader.fileListFlags collect i
					for f in theActualFilesToAdd where findItem tempList f == 0 do 
					(
						append tempList f
						append tempFlags 2
					)
					with undo "Add PRTs From Folders" on
					(					
						currentPRTLoader.fileList = tempList
						currentPRTLoader.fileListFlags = tempFlags
					)
					updateEditor()
					select currentPRTLoader
				)
			)
		)	
		else
			try(destroyDialog Krakatoa_PRTLoader_FileEditor)catch()			
		
	)

	fn addFiles =
	(
		if stillSelected() then
		(	
			if classof currentPRTLoader.baseobject == KrakatoaPRTLoader then
				currentPRTLoader.params.btn_addFiles.pressed()
			else
				currentPRTLoader.particleFilesRollout.btn_addFiles.pressed()
			updateEditor()
		)	
		else
			try(destroyDialog Krakatoa_PRTLoader_FileEditor)catch()				
	)	
	
	local fullDirectoriesList = #()
	fn recurseDirectories theDirToScan =
	(
		theSubs = getDirectories (theDirToScan + "*")
		for s in theSubs do 
		(
			append fullDirectoriesList s
			recurseDirectories s
		)	
	)	

	fn repathFiles =
	(
		if stillSelected() then
		(		
			theSel = getSelection lv_filesToLoad
			if theSel.count > 0 then
			(
				with undo "PRT Repath" on 
				(
					theNewPath = getSavePath()
					if theNewPath != undefined do
					(
						fullDirectoriesList = #(theNewPath)
						recurseDirectories theNewPath
						for i in theSel do 
						(
							theBaseFile = filenameFromPath currentPRTLoader.fileList[i]
							for d in fullDirectoriesList do
							(
								theNewFile = d + theBaseFile 
								if doesFileExist theNewFile do 
								(
									currentPRTLoader.fileList[i] = theNewFile
									exit
								)
							)	
						)--end i loop
						fillInSpreadSheet lv_filesToLoad
					)--end if path defined
				)--end undo
			)--end if selection > 0
		)--end if node valid	
		else
			try(destroyDialog Krakatoa_PRTLoader_FileEditor)catch()			
	)
	
	fn removeFiles selectedOnly:true =
	(
		if stillSelected() then
		(	
			local hostRollout = if classof currentPRTLoader.baseobject == KrakatoaPRTLoader then
				currentPRTLoader.params
			else
				currentPRTLoader.particleFilesRollout
			
			if selectedOnly then 
				hostRollout.lbx_filesToLoad.selection = (getSelection lv_filesToLoad) as bitarray
			else	
				hostRollout.lbx_filesToLoad.selection = ((for i = 1 to hostRollout.lbx_filesToLoad.items.count collect i) as bitarray)
			hostRollout.btn_removeFile.pressed()
			fillInSpreadSheet lv_filesToLoad
		)	
		else
			try(destroyDialog Krakatoa_PRTLoader_FileEditor)catch()				
	)
	
	fn saveFiles selectedOnly:false UserFilename:""=
	(
		if stillSelected() then
		(	
			makeDir (Krakatoa_PresetsDirectory+ "\\FileSequences") all:true
			if UserFilename == "" then
				theSaveFile = getSaveFilename caption:"Enter Filename To Save File Sequence To:" filename:(Krakatoa_PresetsDirectory+ "\\FileSequences\\" + currentPRTLoader.name ) types:"Krakatoa PRT File List (*.kfl)|*.kfl"
			else	
				theSaveFile = (Krakatoa_PresetsDirectory+ "\\FileSequences\\") + UserFilename
			if theSaveFile != undefined do
			(
				theFileToSave = createFile theSaveFile 
				if selectedOnly then
				(
					theSel = getSelection lv_filesToLoad
					for i in theSel do 
						if classof currentPRTLoader.baseobject == KrakatoaPRTLoader then
							format "%, %\n" currentPRTLoader.fileList[i] currentPRTLoader.fileListFlags[i] to:theFileToSave 
						else 
							format "%, 3\n" currentPRTLoader.fileList[i] to:theFileToSave 
				)
				else
				(
					for i = 1 to currentPRTLoader.fileList.count do 
						if classof currentPRTLoader.baseobject == KrakatoaPRTLoader then
							format "%, %\n" currentPRTLoader.fileList[i] currentPRTLoader.fileListFlags[i] to:theFileToSave 
						else
							format "%, 3\n" currentPRTLoader.fileList[i] to:theFileToSave 
				)		
				close theFileToSave 	
			)	
		)	
	)
	
	fn loadFiles userFilename:""=
	(
		if stillSelected() then
		(	
			makeDir (Krakatoa_PresetsDirectory+ "\\FileSequences") all:true
			if userFilename == "" then
				theLoadFile = getOpenFilename caption:"Enter Filename To Load File Sequence From:" filename:(Krakatoa_PresetsDirectory+ "\\FileSequences\\") types:"Krakatoa PRT File List (*.kfl)|*.kfl"
			else
				theLoadFile = (Krakatoa_PresetsDirectory+ "\\FileSequences\\") + userFilename 
			if theLoadFile != undefined and doesFileExist theLoadFile do
			(
				theFileToLoad = openFile theLoadFile 
				local theList = #()
				local theFlags = #()
				theOldList = for i in currentPRTLoader.fileList collect i
				local isPRTLoader = classof currentPRTLoader.baseobject == krakatoaPRTLoader 
				if isPRTLoader do 
					theOldFlagList = for i in currentPRTLoader.fileListFlags collect i
				
				while not eof theFileToLoad do
				(
					thePath = readline theFileToLoad
					if not matchPattern thePath pattern:"*, *" then thePath += ", 3"
					strStream = thePath as stringStream
					local theFilePath = readDelimitedString strStream ","
					local theFileFlag = execute (readLine strStream )
					if doesFileExist theFilePath and findItem theOldList theFilePath == 0 do 
					(
						append theList theFilePath 
						append theFlags theFileFlag 
					)	
				)
				close theFileToLoad
				with undo "PRT Load List" on
				(
					currentPRTLoader.fileList = join theOldList theList 
					if isPRTLoader do 
						currentPRTLoader.fileListFlags = join theOldFlagList theFlags 
				)	
				updateEditor()
			)	
		)	
	)	
	
	fn cutSequences =
	(
		if stillSelected() then
		(	
			theSel = getSelection lv_filesToLoad
			saveFiles selectedOnly:true userFilename:"_Clipboard.txt"
			with undo "PRT Cut Sequence" on
			(
				for i = theSel.count to 1 by -1 do 
				(
					deleteItem currentPRTLoader.fileList theSel[i]
					if classof currentPRTLoader.baseobject == krakatoaPRTLoader do
						deleteItem currentPRTLoader.fileListFlags theSel[i]
				)	
			)	
			fillInSpreadSheet lv_filesToLoad
			try(modPanel.setCurrentObject currentPRTLoader.baseobject)catch()
		)	
		else
			try(destroyDialog Krakatoa_PRTLoader_FileEditor)catch()			
	)
	
	fn copySequences =
	(
		if stillSelected() then
		(		
			theSel = getSelection lv_filesToLoad
			if theSel.count > 0 then
				saveFiles selectedOnly:true userFilename:"_Clipboard.txt"
		)	
		else
			try(destroyDialog Krakatoa_PRTLoader_FileEditor)catch()			
	)	
	
	fn pasteSequences =
	(
		if stillSelected() then
		(	
			loadFiles userFilename:"_Clipboard.txt"	
		)	
		else
			try(destroyDialog Krakatoa_PRTLoader_FileEditor)catch()		
	)		
	
	
	fn ToggleVRIn VorR OnOff selectedOnly:true invert:false = 
	( 
		if stillSelected() then
		(	
			with undo "Toggle PRT Loading" on
			(				
				local oldSel = getSelection lv_filesToLoad
				if selectedOnly then 
					theSel = getSelection lv_filesToLoad
				else
					theSel = #{1..currentPRTLoader.fileListFlags.count}
				theBit = if VorR == #View then 1 else 2
				for i in theSel do
					if invert then
						currentPRTLoader.fileListFlags[i] = bit.set currentPRTLoader.fileListFlags[i] theBit (not (bit.get currentPRTLoader.fileListFlags[i] theBit))
					else
						currentPRTLoader.fileListFlags[i] = bit.set currentPRTLoader.fileListFlags[i] theBit OnOff 
				
				if modPanel.getCurrentObject() == currentPRTLoader.baseobject do 
				(
					select currentPRTLoader
					modPanel.setCurrentObject currentPRTLoader.baseobject
				)	
				fillInSpreadSheet lv_filesToLoad
				setSelection lv_filesToLoad oldSel 
			)
		)	
		else
			try(destroyDialog Krakatoa_PRTLoader_FileEditor)catch()			
	)	


	
	
	
	on Krakatoa_PRTLoader_FileEditor resized val do 
	(
		lv_filesToLoad.width = val.x-10
		lv_filesToLoad.height = val.y-10
		setIniSetting (Krakatoa_PresetsDirectory+ "\\KrakatoaPreferences.ini") "Dialog" "FileManagerSize" (val as string)
	)
	on Krakatoa_PRTLoader_FileEditor moved val do 
		setIniSetting (Krakatoa_PresetsDirectory+ "\\KrakatoaPreferences.ini") "Dialog" "FileManagerPosition" (val as string)
	
	fn update =
	(
		if stillSelected() then
		(	
			fillInSpreadSheet lv_filesToLoad
		)	
	)
	
	fn selectByDClick_Handler =
	(
		if stillSelected() then
		(	
			toSelect = getSelection lv_filesToLoad 
			if toSelect.count > 0 do
				try(shelllaunch "explorer.exe" (getFileNamePath currentPRTLoader.fileList[toSelect[1]]))catch()
		)	
		else
			try(destroyDialog Krakatoa_PRTLoader_FileEditor)catch()			
	)
	on lv_filesToLoad DoubleClick do selectByDClick_Handler()
	on Krakatoa_PRTLoader_FileEditor open do
	(
		updateEditor()
	)
)

global Krakatoa_PRTLoader_AllNewPartitions, Krakatoa_PRTLoader_AddFileSequenceBehavior_Override
rollout Krakatoa_PRTLoader_SelectPartitions "Krakatoa PRT Loader : Select Partitions To Load" width:800
(
	local confirmed = false
	button btn_selectAll "Select All" pos:[2,3] width:90 across:4
	button btn_selectNone "Select None" pos:[92,3] width:90 
	button btn_selectInvert "Invert Selection" pos:[182,3] width:90 
	spinner spn_from "From:" type:#integer range:[1,1000,1] pos:[275,5] fieldwidth:30
	spinner spn_to "To:" type:#integer range:[1,1000,100] pos:[345,5] fieldwidth:30
	spinner spn_by "By:" type:#integer range:[1,100,1] pos:[410,5] fieldwidth:30
	checkbox chk_filterExisting "Existing Files Only" pos:[472,5] checked:true
	edittext edt_pattern "Filter:" text:"" fieldwidth:150 pos:[590,6]
	button btn_clearfilter "X" width:20 height:20 pos:[772,4]
	
	multilistbox mlb_partitionsToLoad height:(amin #(Krakatoa_PRTLoader_AllNewPartitions.count,40)) width:790 align:#center
	
	
	edittext lbl_info "" width:260 align:#left offset:[-7,6] across:3 readOnly:true
	
	button btn_load "ADD SELECTED PARTITIONS" height:30 width:195 across:3 align:#right offset:[60,0] tooltip:"Add the selected partition sequences to the PRT Loader's sequence list."
	button btn_cancel "CANCEL" height:30 width:195 align:#right offset:[0,0] tooltip:"Close this dialog without adding partitions to the PRT Loader's sequence list."
	
	checkbox chk_EnableInViewport "Enable In Viewport" offset:[260,-35]
	checkbox chk_EnableInRenderer "Enable In Renderer" offset:[260,-4]
	
	
	fn updateInfo =
	(
		lbl_info.text = "Selected " + mlb_partitionsToLoad.selection.numberset as string + " of " + Krakatoa_PRTLoader_AllNewPartitions.count as string +" Partition Sequences." 
	)
	
	fn getZeros theVal theNum=
	(
		substring "000000" 1 ((theNum as string).count - (theVal as string).count)
	)
	
	fn applyFilter =
	(
		local toSelect = mlb_partitionsToLoad.selection
		for i in mlb_partitionsToLoad.selection do
		(
			if not matchPattern Krakatoa_PRTLoader_AllNewPartitions[i] pattern:("*"+edt_pattern.text+"*") do toSelect[i] = false
			if chk_filterExisting.checked and not doesFileExist Krakatoa_PRTLoader_AllNewPartitions[i] do toSelect[i] = false
		)
		mlb_partitionsToLoad.selection = toSelect 
	)
	
	fn selectRange =
	(
		local toSelect = #{}
		for i = spn_from.value to spn_to.value by spn_by.value do
		(
			for f = 1 to Krakatoa_PRTLoader_AllNewPartitions.count do
			(
				local partitionCount = (FranticParticles.GetPartitionFromFilename Krakatoa_PRTLoader_AllNewPartitions[f])[2]
				if matchPattern Krakatoa_PRTLoader_AllNewPartitions[f] pattern:("*_part"+ (getZeros i partitionCount) + i as string+"of*") do toSelect[f] = true
			)
		)
		mlb_partitionsToLoad.selection = toSelect
		applyFilter()
		updateInfo()
	)
	

	on spn_from changed val do
	(
		if val > spn_to.value do spn_to.value = val
		selectRange()
	)
	on spn_to changed val do
	(
		if val < spn_from.value do spn_from.value = val
		selectRange()
	)
	on spn_by changed val do
	(
		selectRange()
	)
	
	on edt_pattern changed txt do
	(
		selectRange()
		applyFilter()
		updateInfo()
	)
	
	on btn_selectAll pressed do 
	(
		local toSelect = #{1..mlb_partitionsToLoad.items.count}
		for i in toSelect do
		(
			if chk_filterExisting.checked and not doesFileExist Krakatoa_PRTLoader_AllNewPartitions[i] do toSelect[i] = false
		)
		mlb_partitionsToLoad.selection = toSelect 
		updateInfo()
	)
	on btn_selectInvert pressed do 
	(
		local toSelect = -mlb_partitionsToLoad.selection
		for i in toSelect do
		(
			if chk_filterExisting.checked and not doesFileExist Krakatoa_PRTLoader_AllNewPartitions[i] do toSelect[i] = false
		)
		mlb_partitionsToLoad.selection = toSelect 
		updateInfo()
	)
	on btn_selectNone pressed do 
	(
		mlb_partitionsToLoad.selection = #{}
		updateInfo()
	)
	
	on mlb_partitionsToLoad selected itm do 
	(
		applyFilter()
		updateInfo()
	)
	
	on btn_clearfilter pressed do
	(
		edt_pattern.text = ""
		selectRange()
		applyFilter()		
		updateInfo()
	)
	
	on chk_filterExisting changed state do
	(
		selectRange()
		applyFilter()		
		updateInfo()		
	)
		
	on btn_load pressed do
	(
		confirmed = true
		if chk_EnableInViewport.checked and chk_EnableInRenderer.checked do Krakatoa_PRTLoader_AddFileSequenceBehavior_Override = "1"
		if not chk_EnableInViewport.checked and not chk_EnableInRenderer.checked do Krakatoa_PRTLoader_AddFileSequenceBehavior_Override = "4" 		
		if not chk_EnableInViewport.checked and chk_EnableInRenderer.checked do Krakatoa_PRTLoader_AddFileSequenceBehavior_Override = "2" 		
		if chk_EnableInViewport.checked and not chk_EnableInRenderer.checked do Krakatoa_PRTLoader_AddFileSequenceBehavior_Override = "5" 		
			
		Krakatoa_PRTLoader_AllNewPartitions = for i in mlb_partitionsToLoad.selection collect Krakatoa_PRTLoader_AllNewPartitions[i]
		destroyDialog Krakatoa_PRTLoader_SelectPartitions
	)
	
	on btn_cancel pressed do
	(
		Krakatoa_PRTLoader_AllNewPartitions = #()
		destroyDialog Krakatoa_PRTLoader_SelectPartitions
	)
	
	on Krakatoa_PRTLoader_SelectPartitions close do
	(
		if not confirmed do Krakatoa_PRTLoader_AllNewPartitions = #()
	)	
	
	fn resizeDialog size =
	(
		if size.x < 800 do size.x = 800
			
		mlb_partitionsToLoad.width = size.x-10
		mlb_partitionsToLoad.height = size.y-60

		lbl_info.pos = [7,size.y-30]
		
		chk_EnableInViewport.pos = [273, size.y-30]
		chk_EnableInRenderer.pos = [273, size.y-15]
		
		btn_load.pos = [size.x-400,size.y-30]
		btn_cancel.pos  = [size.x-200,size.y-30]
	)
	
	on Krakatoa_PRTLoader_SelectPartitions resized size do
	(
		resizeDialog size
	)
	
	on Krakatoa_PRTLoader_SelectPartitions open do
	(
		try(btn_clearfilter.images = #(Krakatoa_PresetsArrowBitmap,Krakatoa_PresetsArrowBitmap, 32,14,14,14,14))catch()
		chk_EnableInViewport.checked = Krakatoa_PRTLoader_AddFileSequenceBehavior_Override == "1"
		chk_EnableInRenderer.checked = Krakatoa_PRTLoader_AddFileSequenceBehavior_Override != "4" 
		mlb_partitionsToLoad.items = for o in Krakatoa_PRTLoader_AllNewPartitions collect (if doesFileExist o then o else o + " [NOT FOUND]")
		selectRange()
		applyFilter()	
		updateInfo()
		resizeDialog (GetDialogSize Krakatoa_PRTLoader_SelectPartitions)
	)
)