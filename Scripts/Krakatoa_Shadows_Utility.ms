-- Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
-- SPDX-License-Identifier: Apache-2.0
macroScript KrakatoaShadows category:"Krakatoa" icon:#("Krakatoa",4)
(
	global Krakatoa_ShadowsExplorer_Dialog
	try(destroyDialog Krakatoa_ShadowsExplorer_Dialog)catch()
	
	rcmenu Krakatoa_ShadowsExplorer_Menu 
	(
		subMenu "Selection"
		(
			menuItem mnu_selectAll "Highlight ALL List Entries"
			menuItem mnu_selectInvert "INVERT List Highlights"
			separator sep_10
			menuitem mnu_SelectLightsWithShadowsOn "Highlight Lights With Shadows ON"
			menuitem mnu_SelectLightsWithShadowsOff "Highlight Lights With Shadows OFF"
			separator sep_20
			menuitem mnu_SelectLightsWithKrakatoaShadows "Highlight Lights WITH KRAKATOA Shadows Generator"
			menuitem mnu_SelectLightsWithoutKrakatoaShadows "Highlight Lights WITHOUT KRAKATOA Shadows Generator"
			separator sep_30
			menuItem mnu_syncSelectionToScene "Synchronize List Highlighs TO SCENE Selection" 
			menuItem mnu_syncSelectionFromScene "Synchronize Scene Selection TO LIST Highlights" 
		)
		
		subMenu "Add/Remove"
		(
			menuitem mnu_AddDefaultKrakatoaShadowsToSel "ADD Default Krakatoa Shadows"
			separator sep_110
			menuitem mnu_RestoreKrakatoaShadowsInSel "RESTORE Krakatoa Shadows"
			separator sep_120
			menuitem mnu_RemoveKrakatoaShadowsFromSel "REMOVE Krakatoa Shadows"
		)
		subMenu "Shadow Casting"
		(
			menuitem mnu_EnableShadowsSel "ENABLE Shadow Casting"
			menuitem mnu_DisableShadowsSel "DISABLE Shadow Casting"
			menuitem mnu_ToggleShadowsSel "TOGGLE Shadow Casting"
			separator sep_200
			menuitem mnu_EnableShadowsDelegate "ENABLE Geometry Shadow Casting In Highlighted Lights With Krakatoa Shadows"
			menuitem mnu_DisableShadowsDelegate "DISABLE Geometry Shadow Casting In Highlighted Lights With Krakatoa Shadows"
			menuitem mnu_ToggleShadowsDelegate "TOGGLE Geometry Shadow Casting In Highlighted Lights With Krakatoa Shadows"
			
		)
		subMenu "Map Size"
		(
			menuItem mnu_ShadowMapSize256Sel "Set Shadow Map Size To 256"
			menuItem mnu_ShadowMapSize512Sel "Set Shadow Map Size To 512"
			menuItem mnu_ShadowMapSize1024Sel "Set Shadow Map Size To 1024"
			menuItem mnu_ShadowMapSize2048Sel "Set Shadow Map Size To 2048"
			menuItem mnu_ShadowMapSize4096Sel "Set Shadow Map Size To 4096"
		)
		
		subMenu "Samples"
		(
			subMenu "Set Sample Count To..."
			(
				menuItem mnu_ShadowSamples1 "1"
				menuItem mnu_ShadowSamples2 "2"
				menuItem mnu_ShadowSamples3 "3"
				menuItem mnu_ShadowSamples4 "4"
				menuItem mnu_ShadowSamples5 "5"
				menuItem mnu_ShadowSamples8 "8"
				menuItem mnu_ShadowSamples10 "10"
			)
			separator sep_500
			menuItem mnu_ShadowSamplesCopy "COPY Sample Count From First Highlighted Light" enabled:(Krakatoa_ShadowsExplorer_Dialog.selectedItems.count > 0)
			menuItem mnu_ShadowSamplesPaste "PASTE Sample Count To Highlighted Lights" enabled:(Krakatoa_ShadowsExplorer_Dialog.ShadowSamplesClipboard!=undefined)
			separator sep_520
			subMenu "Set Sample Spacing To..."
			(			
				menuItem mnu_ShadowSampleSpacing1 "1"
				menuItem mnu_ShadowSampleSpacing2 "2"
				menuItem mnu_ShadowSampleSpacing3 "3"
				menuItem mnu_ShadowSampleSpacing4 "4"
				menuItem mnu_ShadowSampleSpacing5 "5"
				menuItem mnu_ShadowSampleSpacing10 "10"			
			)
			separator sep_540
			menuItem mnu_ShadowSampleSpacingCopy "COPY Sample Spacing From First Highlighted Light" enabled:(Krakatoa_ShadowsExplorer_Dialog.selectedItems.count > 0)
			menuItem mnu_ShadowSampleSpacingPaste "PASTE Sample Spacing To Highlighted Lights" enabled:(Krakatoa_ShadowsExplorer_Dialog.ShadowSampleSpacingClipboard!=undefined)
			separator sep_550
			menuItem mnu_ShadowSampleSpacingExp "Set Sample Spacing to EXPONENTIAL" 
			menuItem mnu_ShadowSampleSpacingLinear "Set Sample Spacing to LINEAR" 
			
		)	
		
		on mnu_ShadowSampleSpacingExp picked do Krakatoa_ShadowsExplorer_Dialog.setShadowSpacingExpLin #exp
		on mnu_ShadowSampleSpacingLinear picked do Krakatoa_ShadowsExplorer_Dialog.setShadowSpacingExpLin #lin

		on mnu_ShadowSamples1	picked do Krakatoa_ShadowsExplorer_Dialog.setShadowSamples 1
		on mnu_ShadowSamples2	picked do Krakatoa_ShadowsExplorer_Dialog.setShadowSamples 2
		on mnu_ShadowSamples3	picked do Krakatoa_ShadowsExplorer_Dialog.setShadowSamples 3
		on mnu_ShadowSamples4	picked do Krakatoa_ShadowsExplorer_Dialog.setShadowSamples 4
		on mnu_ShadowSamples5	picked do Krakatoa_ShadowsExplorer_Dialog.setShadowSamples 5
		on mnu_ShadowSamples8	picked do Krakatoa_ShadowsExplorer_Dialog.setShadowSamples 8
		on mnu_ShadowSamples10 picked do Krakatoa_ShadowsExplorer_Dialog.setShadowSamples 10
			
		on mnu_ShadowSamplesCopy picked do Krakatoa_ShadowsExplorer_Dialog.CopyShadowSamples()
		on mnu_ShadowSamplesPaste picked do Krakatoa_ShadowsExplorer_Dialog.PasteShadowSamples()

		on mnu_ShadowSampleSpacing1 picked do Krakatoa_ShadowsExplorer_Dialog.setShadowSampleSpacing 1
		on mnu_ShadowSampleSpacing2 picked do Krakatoa_ShadowsExplorer_Dialog.setShadowSampleSpacing 2
		on mnu_ShadowSampleSpacing3 picked do Krakatoa_ShadowsExplorer_Dialog.setShadowSampleSpacing 3
		on mnu_ShadowSampleSpacing4 picked do Krakatoa_ShadowsExplorer_Dialog.setShadowSampleSpacing 4
		on mnu_ShadowSampleSpacing5 picked do Krakatoa_ShadowsExplorer_Dialog.setShadowSampleSpacing 5
		on mnu_ShadowSampleSpacing10 picked do Krakatoa_ShadowsExplorer_Dialog.setShadowSampleSpacing 10
			
		on mnu_ShadowSampleSpacingCopy picked do Krakatoa_ShadowsExplorer_Dialog.CopyShadowSampleSpacing()
		on mnu_ShadowSampleSpacingPaste picked do Krakatoa_ShadowsExplorer_Dialog.PasteShadowSampleSpacing()		
		
		subMenu "Save Paths"
		(
			menuitem mnu_assignNewSavePath "Assign NEW ABSOLUTE Save Path To Highlighted Lights"
			separator sep_600
			menuitem mnu_assignDefaultFilename "Reset Highlighted Paths To DEFAULT Relative Path [$renderdir\$objectname_0000.exr]"
			separator sep_610
			menuitem mnu_setSavePathToAbsolute "Convert Highlighted RELATIVE Paths To Absolute Paths"
			menuitem mnu_setSavePathToRelative "Convert Highlighted ABSOLUTE Paths To Relative Paths"
			separator sep_650
			menuitem mnu_createSavePaths "CREATE Highlighted Save Paths"
			separator sep_660
			menuitem mnu_exploreSavePaths "EXPLORE Highlighted Save Paths"
		)
		
		subMenu "Load Paths"
		(
			menuitem mnu_assignNewLoadPath "Assign NEW LOAD Path To Selected Lights"
			separator sep_710
			menuitem mnu_explorePaths "EXPLORE Selected Load Paths"
		)

		on mnu_assignNewSavePath picked do Krakatoa_ShadowsExplorer_Dialog.assignNewSavePath()
		
		on mnu_assignNewLoadPath picked do Krakatoa_ShadowsExplorer_Dialog.assignNewPath()
		on mnu_assignDefaultFilename picked do Krakatoa_ShadowsExplorer_Dialog.assignDefaultFilename()
		on mnu_explorePaths picked do Krakatoa_ShadowsExplorer_Dialog.explorePaths()
		on mnu_setSavePathToAbsolute picked do Krakatoa_ShadowsExplorer_Dialog.setSavePathToAbsolute()
		on mnu_setSavePathToRelative picked do Krakatoa_ShadowsExplorer_Dialog.setSavePathToRelative()
		on mnu_createSavePaths picked do Krakatoa_ShadowsExplorer_Dialog.createSavePaths()
		
		menuitem mnu_refresh "Refresh!"

		
		on mnu_selectAll picked do Krakatoa_ShadowsExplorer_Dialog.selectAll()
		on mnu_selectInvert picked do Krakatoa_ShadowsExplorer_Dialog.selectInvert()
		
		
		on mnu_syncSelectionToScene picked do 
		(
			Krakatoa_ShadowsExplorer_Dialog.syncSelectionToScene()
			/*
			Krakatoa_ShadowsExplorer_Dialog.syncToScene = not Krakatoa_ShadowsExplorer_Dialog.syncToScene
			setIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini" ) "KrakatoaShadowsExplorer" "SyncToScene" (Krakatoa_ShadowsExplorer_Dialog.syncToScene as string)
			*/
		)
		on mnu_syncSelectionFromScene picked do 
		(
			Krakatoa_ShadowsExplorer_Dialog.syncSelectionFromScene()
			/*
			Krakatoa_ShadowsExplorer_Dialog.syncFromScene = not Krakatoa_ShadowsExplorer_Dialog.syncFromScene
			setIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini" ) "KrakatoaShadowsExplorer" "SyncFromScene" (Krakatoa_ShadowsExplorer_Dialog.syncFromScene as string)
			*/
		)
			
		on mnu_SelectLightsWithShadowsOn picked do Krakatoa_ShadowsExplorer_Dialog.selectByShadows true
		on mnu_SelectLightsWithShadowsOff picked do Krakatoa_ShadowsExplorer_Dialog.selectByShadows false

		on mnu_SelectLightsWithKrakatoaShadows picked do Krakatoa_ShadowsExplorer_Dialog.selectByKrakatoaShadows true
		on mnu_SelectLightsWithoutKrakatoaShadows picked do Krakatoa_ShadowsExplorer_Dialog.selectByKrakatoaShadows false
		
		on mnu_refresh picked do 
		(
			Krakatoa_ShadowsExplorer_Dialog.getLights #all
			Krakatoa_ShadowsExplorer_Dialog.initListView()
		)
		
		on mnu_AddDefaultKrakatoaShadowsToAll picked do Krakatoa_ShadowsExplorer_Dialog.addKrakatoaShadows #all
		on mnu_AddDefaultKrakatoaShadowsToSel picked do Krakatoa_ShadowsExplorer_Dialog.addKrakatoaShadows #sel
			
		on mnu_RestoreKrakatoaShadowsInAll picked do Krakatoa_ShadowsExplorer_Dialog.restoreKrakatoaShadows #all
		on mnu_RestoreKrakatoaShadowsInSel picked do Krakatoa_ShadowsExplorer_Dialog.restoreKrakatoaShadows #sel
		
		on mnu_RemoveKrakatoaShadowsFromAll picked do Krakatoa_ShadowsExplorer_Dialog.removeKrakatoaShadows #all
		on mnu_RemoveKrakatoaShadowsFromSel picked do Krakatoa_ShadowsExplorer_Dialog.removeKrakatoaShadows #sel
			
		on mnu_EnableShadowsDelegate picked do Krakatoa_ShadowsExplorer_Dialog.enableShadowsDelegate #sel
		on mnu_DisableShadowsDelegate picked do Krakatoa_ShadowsExplorer_Dialog.disableShadowsDelegate #sel
		on mnu_ToggleShadowsDelegate picked do Krakatoa_ShadowsExplorer_Dialog.toggleShadowsDelegate #sel
			
		on mnu_EnableShadowsSel picked do Krakatoa_ShadowsExplorer_Dialog.enableShadows #sel
		on mnu_DisableShadowsSel picked do Krakatoa_ShadowsExplorer_Dialog.disableShadows #sel
		on mnu_ToggleShadowsSel picked do Krakatoa_ShadowsExplorer_Dialog.toggleShadows #sel
			
		on mnu_ShadowMapSize256Sel picked do Krakatoa_ShadowsExplorer_Dialog.setShadowMapSize #sel 256
		on mnu_ShadowMapSize512Sel picked do Krakatoa_ShadowsExplorer_Dialog.setShadowMapSize #sel 512
		on mnu_ShadowMapSize1024Sel picked do Krakatoa_ShadowsExplorer_Dialog.setShadowMapSize #sel 1024
		on mnu_ShadowMapSize2048Sel picked do Krakatoa_ShadowsExplorer_Dialog.setShadowMapSize #sel 2048		
		on mnu_ShadowMapSize4096Sel picked do Krakatoa_ShadowsExplorer_Dialog.setShadowMapSize #sel 4096		
			
	)
	
	rollout Krakatoa_ShadowsExplorer_Dialog "Krakatoa Shadows Explorer"
	(
		local allLights = #()
		local theLights = #()
		local selectedItems = #()
		local callbackEnabled = true
		local syncToScene = true
		local syncFromScene = true
		local initializingView = false
		
		local ShadowSamplesClipboard = undefined
		local ShadowSampleSpacingClipboard = undefined
		
		local getSelectedItems
		
		dotNetControl dnc_listview "ListView" width:990 height:290 align:#center	
		
		fn getLights mode =
		(
			getSelectedItems()
			allLights = for o in Objects where findItem light.classes (classof o) > 0 and isProperty o #shadowGenerator collect o
			case mode of
			(
				#sel: theLights = for i in selectedItems where isValidNode allLights[i] collect allLights[i]
				default: theLights = for o in allLights collect o
			)
			theLights
		)		
		
		fn initListViewLayout =
		(
			local lv = dnc_listview
			layout_def = #(#("Light Name",100), #("On",35), #("Cast",35),#("Krakatoa",55), #("Geo.Shadows-GS",95), #("GS On",42), #("Size",38), #("Samples",52), #("Spacing",52),  #("Exp.",35), #("Save Path",200),#("Auto",35),#("Found",42),#("Load Path",800))
			lv.Clear()
			lv.backColor = (dotNetClass "System.Drawing.Color").fromARGB 221 221 225
			lv.View = (dotNetClass "System.Windows.Forms.View").Details
			lv.gridLines = true 
			lv.fullRowSelect = true 
			lv.checkboxes = false
			lv.hideSelection = false		
			for i in layout_def do
				lv.Columns.add i[1] i[2]			
		)
		
		fn initListView =
		(
			initializingView = true
			getLights #all
			local lv = dnc_listview
			lv.Items.Clear()
			local theRange = #()
			local theRedColor = (dotNetClass "System.Drawing.Color").fromARGB 200 0 0
			local theBlackColor = (dotNetClass "System.Drawing.Color").fromARGB 0 128 0 
			local theGrayColor = (dotNetClass "System.Drawing.Color").fromARGB 128 128 128
			local theGrayRedColor = (dotNetClass "System.Drawing.Color").fromARGB 180 128 128
			local theDarkGrayColor = (dotNetClass "System.Drawing.Color").fromARGB 64 64  180 			
			local theDarkGrayRedColor = (dotNetClass "System.Drawing.Color").fromARGB 128 64  64 	

			local theBoldFont = dotNetObject "System.Drawing.Font" "Arial" 8 (dotNetClass "System.Drawing.FontStyle").Bold
			local theNormalFont = dotNetObject "System.Drawing.Font" "Arial" 8 
			local theItalicFont = dotNetObject "System.Drawing.Font" "Arial" 8 (dotNetClass "System.Drawing.FontStyle").Italic
			
			for o in allLights do
			(
				local li = dotNetObject "System.Windows.Forms.ListViewItem" (o.name)
				li.name = "objectname"
				li.font = theNormalFont
				local isKrakatoaShadows = classof o.shadowGenerator == Krakatoa_Shadows 
				li.forecolor = if o.baseobject.on then 
				(
					if  o.baseobject.castshadows then
						if isKrakatoaShadows then theBlackColor else theRedColor
					else 
						if isKrakatoaShadows then theDarkGrayColor else theDarkGrayRedColor
				)
				else
					if isKrakatoaShadows then theGrayColor else theGrayRedColor  
					
				subLi = li.SubItems.add (if o.baseobject.on then "YES" else "no")
				subLi.name = "on"
				subLi = li.SubItems.add (if o.baseobject.castshadows then "YES" else "no")
				subLi.name = "cast"
				subLi = li.SubItems.add (if isKrakatoaShadows then "YES" else "no")
				subLi.name = "krakatoa"
				subLi = li.SubItems.add  (if isKrakatoaShadows then ((classof o.shadowGenerator.DelegateGenerator) as string) else (classof o.shadowGenerator as string))
				subLi.name = "geo"
					
				subLi = li.SubItems.add  (if isKrakatoaShadows then if o.shadowGenerator.DelegateOn then "YES" else "no" else "N/A")
				subLi.name = "geoon"
					
				subLi = li.SubItems.add  (if isKrakatoaShadows then o.shadowGenerator.mapSize as string else try(o.mapSize as string)catch("N/A"))
				subLi.name = "mapsize"
				subLi = li.SubItems.add  (if isKrakatoaShadows then o.shadowGenerator.ShadowSampleCount as string else "N/A" )
				subLi.name = "samplecount"
				subLi = li.SubItems.add  (if isKrakatoaShadows then units.formatValue o.shadowGenerator.ShadowSampleSpacing else "N/A" )
				subLi.name = "samplestep"	
				subLi = li.SubItems.add  (if isKrakatoaShadows then if o.shadowGenerator.ShadowSampleSpacingIsExponential then "YES" else "no" else "N/A" )
				subLi.name = "expsample"	
					
					
				local thePathExists = "no"
					
				if classof o.shadowGenerator == Krakatoa_Shadows then 
				(
					thePath = o.shadowGenerator.ShadowSavePath
					subLi = li.SubItems.add thePath
				)
				else
				(
					subLi = li.SubItems.add "N/A"
				)
				subLi.name = "savepath"					

				local autoUpdate = "N/A"
				local thePathExists = "N/A"
				if classof o.shadowGenerator == Krakatoa_Shadows then 
				(
					autoUpdate = if o.shadowGenerator.ShadowFilenameAutoUpdate then "YES" else "no"
					if o.shadowGenerator.ShadowFilename != "" then 
					(
						theLoadPath = o.shadowGenerator.ShadowFilename 
						local theHashPath = (franticParticles.ReplaceSequenceNumberWithHashes (getFileNameFile theLoadPath))
						theHashPath = substring theHashPath 1 (theHashPath.count-5)	
						local theFiles = (getFiles ((getFilenamepath theLoadPath)+ theHashPath +"*"+(getFileNameType theLoadPath)))
						if theFiles.count == 0 then thePathExists = "no" else 
						(
							li.font = theBoldFont
							thePathExists = theFiles.count as string
						)
					)
					else 
					(
						theLoadPath = "--" 
						thePathExists = "no"
					)
				)
				else 
					theLoadPath = "N/A" 		

				subLi = li.SubItems.add autoUpdate
				subLi.name = "autoupdate"
				
				subLi = li.SubItems.add  thePathExists
				subLi.name = "pathexists"
				
				subLi = li.SubItems.add  theLoadPath
				subLi.name = "loadpath"
				
				append theRange li
			)
			lv.Items.AddRange theRange 
			for i in selectedItems do
			(
				try(
					lv.items.item[i-1].selected = true
					)catch()
			)
			initializingView = false
		) 
		
		fn getSelectedItems =
		(
			if not initializingView do
			selectedItems = for i = 1 to dnc_listview.items.count where dnc_listview.items.item[i-1].selected == true collect i
		)
		
		fn selectAll =
		(
			selectedItems = for i = 1 to dnc_listview.items.count collect i
			for i in selectedItems do
				dnc_listview.items.item[i-1].selected = true
			--callbackEnabled = false
			--max select none
			--select allLights
			--callbackEnabled = true			
		)
		
		fn selectInvert=
		(
			selectedItems = for i = 1 to dnc_listview.items.count collect i
			for i in selectedItems do
				dnc_listview.items.item[i-1].selected = not dnc_listview.items.item[i-1].selected
			--callbackEnabled = false
			--max select none
			--select allLights
			--callbackEnabled = true			
		)		
		
		fn storeUserProps o =
		(
			if classof o.shadowGenerator == Krakatoa_Shadows do
			(
				setUserProp o "KrakatoaShadows_Filename" o.shadowGenerator.ShadowFilename
				setUserProp o "KrakatoaShadows_SaveFilename" o.shadowGenerator.ShadowSavePath
				setUserProp o "KrakatoaShadows_SampleCount" o.shadowGenerator.ShadowSampleCount 
				setUserProp o "KrakatoaShadows_SampleSpacing" o.shadowGenerator.ShadowSampleSpacing 
				setUserProp o "KrakatoaShadows_MapSize" o.shadowGenerator.MapSize 
				setUserProp o "KrakatoaShadows_DelegateOn" o.shadowGenerator.DelegateOn 
				setUserProp o "KrakatoaShadows_ShadowFilenameAutoUpdate" o.shadowGenerator.ShadowFilenameAutoUpdate 
				setUserProp o "KrakatoaShadows_ShadowSampleSpacingIsExponential" o.shadowGenerator.ShadowSampleSpacingIsExponential 
				setUserProp o "KrakatoaShadows_ShadowManipulatorDistance" o.shadowGenerator.ShadowManipulatorDistance 
			)		
		)		
		
		fn explorePaths =
		(
			getLights #sel
			local theKLights = for o in theLights where classof o.shadowGenerator == Krakatoa_Shadows collect o
			if theKLights.count > 0 do
			(
				thePaths = #()
				for o in theKLights do
				(
					local thePath = o.shadowGenerator.ShadowFilename 
					if thePath != undefined and findItem thePaths (getFileNamePath thePath) == 0 and doesFileExist (getFileNamePath thePath) do append thePaths (getFileNamePath thePath)
				)				
				for p in thePaths do
				(
					shellLaunch "explorer.exe" p
				)
			)
		)
		
		fn convertRelativeToAbsoluteSavePath theObject = 
		(
			local theString = theObject.shadowGenerator.ShadowSavePath
			if matchPattern theString pattern:"*$renderdir*" do
			(
				local theRenderPath = (getFileNamePath rendOutputFilename)
				if matchPattern theRenderPath pattern:"*\\" do theRenderPath = substring theRenderPath  1 (theRenderPath.count-1)
				theString = substituteString theString  "$renderdir" theRenderPath 
			)
			if matchPattern theString pattern:"*$objectname*" do
				theString = substituteString theString  "$objectname" theObject.name
			theString
		)
		
		fn convertAbsoluteToRelativeSavePath theObject = 
		(
			local theString = theObject.shadowGenerator.ShadowSavePath
			local theRenderPath = (getFileNamePath rendOutputFilename)
			if matchPattern theRenderPath pattern:"*\\" do theRenderPath = substring theRenderPath  1 (theRenderPath.count-1)
			
			if matchPattern theString pattern:(theRenderPath+"*") do
				theString = substituteString theString theRenderPath "$renderdir"  
			
			if matchPattern theString pattern:("*"+theObject.name+"*") do
				theString = substituteString theString  theObject.name "$objectname" 
			theString
		)		
		
		fn setSavePathToRelative =
		(
			getLights #sel
			local theKLights = for o in theLights where classof o.shadowGenerator == Krakatoa_Shadows collect o
			if theKLights.count > 0 do
			(
				for o in theKLights do
				(
					o.shadowGenerator.ShadowSavePath = convertAbsoluteToRelativeSavePath o
					storeUserProps o
				)
				initListView()	
			)				
		)

		fn setSavePathToAbsolute =
		(
			getLights #sel
			local theKLights = for o in theLights where classof o.shadowGenerator == Krakatoa_Shadows collect o
			if theKLights.count > 0 do
			(
				for o in theKLights do
				(
					o.shadowGenerator.ShadowSavePath = convertRelativeToAbsoluteSavePath o
					storeUserProps o
				)
				initListView()	
			)			
		)
		
		fn createSavePaths =
		(
			getLights #sel
			local theKLights = for o in theLights where classof o.shadowGenerator == Krakatoa_Shadows collect o
			if theKLights.count > 0 do
			(
				for o in theKLights do
					makeDir o.shadowGenerator.ShadowSavePath all:true
			)				
		)
		
		fn assignNewPath =
		(
			getLights #sel
			local theKLights = for o in theLights where classof o.shadowGenerator == Krakatoa_Shadows collect o
			if theKLights.count > 0 do
			(
				local oldPath = getFileNamePath rendOutputFilename
				local dataLocation = getSavePath caption:"Please Specify The Folder To Load Attenuation Maps From:" initialDir:oldPath
				if dataLocation != undefined do 
				(
					if not matchPattern dataLocation pattern:"*\\" do dataLocation+="\\"
					for o in theKLights do
					(
						o.shadowGenerator.ShadowFilename = dataLocation + o.name + "_0000.exr"
						storeUserProps o
					)
				)
				initListView()	
			)
		)
		
		fn assignNewSavePath =
		(
			getLights #sel
			local theKLights = for o in theLights where classof o.shadowGenerator == Krakatoa_Shadows collect o
			if theKLights.count > 0 do
			(
				local oldPath = ""
				for o in theKLights do
				(
					if o.shadowGenerator.ShadowFilename != "" do 
					(
						oldPath = o.shadowGenerator.ShadowFilename
						exit
					)
				)
				local dataLocation = getSavePath caption:"Please Specify The Folder To Save Attenuation Maps To:" initialDir:(getFilenamePath oldPath)
				if dataLocation != undefined do 
				(
					if not matchPattern dataLocation pattern:"*\\" do dataLocation+="\\"
					for o in theKLights do
					(
						o.shadowGenerator.ShadowSavePath = dataLocation + "$objectname_0000.exr"
						o.shadowGenerator.ShadowSavePath = convertAbsoluteToRelativeSavePath o
						storeUserProps o
					)
				)
				initListView()	
			)
		)
		
		fn assignDefaultFilename =
		(
			getLights #sel
			local theKLights = for o in theLights where classof o.shadowGenerator == Krakatoa_Shadows collect o
			if theKLights.count > 0 do
			(
				for o in theKLights do
				(
					o.shadowGenerator.ShadowSavePath = "$renderdir\$objectname_0000.exr"
					storeUserProps o
				)
				initListView()
			)			
		)
			

		
		fn CopyShadowSamples =
		(
			getLights #sel
			for o in theLights where classof o.shadowGenerator == Krakatoa_Shadows do
			(
				ShadowSamplesClipboard = o.shadowGenerator.ShadowSampleCount
				exit
			)
		)
		fn PasteShadowSamples =
		(
			getLights #sel
			for o in theLights where classof o.shadowGenerator == Krakatoa_Shadows do
			(
				o.shadowGenerator.ShadowSampleCount = ShadowSamplesClipboard
				storeUserProps o
			)
			initListView()	
		)		
		fn CopyShadowSampleSpacing =
		(
			getLights #sel
			for o in theLights where classof o.shadowGenerator == Krakatoa_Shadows do
			(
				ShadowSampleSpacingClipboard = o.shadowGenerator.ShadowSampleSpacing
				exit
			)
		)
		fn PasteShadowSampleSpacing =
		(
			getLights #sel
			for o in theLights where classof o.shadowGenerator == Krakatoa_Shadows do
			(
				o.shadowGenerator.ShadowSampleSpacing = ShadowSampleSpacingClipboard
				storeUserProps o
			)
			initListView()	
		)			
		
		fn setShadowSpacingExpLin mode =
		(
			getLights #sel
			for o in theLights where classof o.shadowGenerator == Krakatoa_Shadows do
			(
				o.shadowGenerator.ShadowSampleSpacingIsExponential = (mode == #exp)
				storeUserProps o
			)
			initListView()	
		)

		
		fn setShadowSamples val =
		(
			getLights #sel
			for o in theLights where classof o.shadowGenerator == Krakatoa_Shadows do
				o.shadowGenerator.ShadowSampleCount = val
			initListView()	
		)
		fn setShadowSampleSpacing val =
		(
			getLights #sel
			for o in theLights where classof o.shadowGenerator == Krakatoa_Shadows do
				o.shadowGenerator.ShadowSampleSpacing = val
			initListView()	
		)		
		
		fn enableShadows mode =
		(
			getLights mode 
			for o in theLights do
				try(o.baseobject.castshadows = true)catch()
			initListView()	
		)
		fn disableShadows mode =
		(
			getLights mode 
			for o in theLights do
				try(o.baseobject.castshadows = false)catch()
			initListView()	
		)		
		fn toggleShadows mode =
		(
			getLights mode 
			for o in theLights do
				try(o.baseobject.castshadows = not o.baseobject.castshadows)catch()
			initListView()	
		)		

		fn enableShadowsDelegate mode =
		(
			getLights mode 
			for o in theLights do
				try(o.shadowGenerator.DelegateOn = true)catch()
			initListView()	
		)
		fn disableShadowsDelegate mode =
		(
			getLights mode 
			for o in theLights do
				try(o.shadowGenerator.DelegateOn = false)catch()
			initListView()	
		)		
		fn toggleShadowsDelegate mode =
		(
			getLights mode 
			for o in theLights do
				try(o.shadowGenerator.DelegateOn = not o.shadowGenerator.DelegateOn)catch()
			initListView()	
		)
		
		
		fn selectByShadows mode =
		(
			getLights #all
			selectedItems = for i = 1 to allLights.count where try(allLights[i].baseobject.castshadows==mode)catch(false) collect i
			initListView()			
		)
		
		fn selectByKrakatoaShadows mode =
		(
			getLights #all
			selectedItems = for i = 1 to allLights.count where try((classof allLights[i].baseobject.shadowGenerator == Krakatoa_Shadows)==mode)catch(false)collect i
			initListView()	
		)		
		
		fn setShadowMapSize mode size =
		(
			getLights mode 
			for o in theLights where classof o.shadowGenerator == Krakatoa_Shadows do
			(
				o.shadowGenerator.MapSize = size
			)
			initListView()	
		)
		
		fn addKrakatoaShadowsToLight o =
		(
			if classof o.shadowGenerator == Krakatoa_Shadows do 
				o.shadowGenerator = if o.shadowGenerator.DelegateGenerator != undefined then o.shadowGenerator.DelegateGenerator else ShadowMap()
				
			local oldShadow = o.shadowGenerator 
			o.shadowGenerator = Krakatoa_Shadows()
			o.shadowGenerator.delegateGenerator = oldShadow 
		)
		
		fn restoreKrakatoaShadowsInLight o =
		(
			if classof o.shadowGenerator == Krakatoa_Shadows do
					o.shadowGenerator = if o.shadowGenerator.DelegateGenerator != undefined then o.shadowGenerator.DelegateGenerator else ShadowMap()
				
			local thePath = getUserProp o "KrakatoaShadows_Filename"
			if thePath != undefined then
			(
				local oldShadow = o.shadowGenerator
				o.shadowGenerator = Krakatoa_Shadows()
				o.shadowGenerator.delegateGenerator = oldShadow 
				o.shadowGenerator.ShadowFilename = thePath 
				
				local theValue = getUserProp o "KrakatoaShadows_SampleCount"
				if theValue != undefined do o.shadowGenerator.ShadowSampleCount = theValue
				
				local theValue = getUserProp o "KrakatoaShadows_SampleSpacing"
				if theValue != undefined do o.shadowGenerator.ShadowSampleSpacing = theValue
				
				local theValue = getUserProp o "KrakatoaShadows_MapSize"
				if theValue != undefined do o.shadowGenerator.MapSize = theValue	

				local theValue = getUserProp o "KrakatoaShadows_DelegateOn"
				if theValue != undefined do o.shadowGenerator.DelegateOn = theValue				
				
				local theValue = getUserProp o "KrakatoaShadows_SaveFilename"
				if theValue != undefined do o.shadowGenerator.ShadowSavePath = theValue		
				
				local theValue = getUserProp o "KrakatoaShadows_ShadowFilenameAutoUpdate"
				if theValue != undefined do o.shadowGenerator.ShadowFilenameAutoUpdate = theValue

				local theValue = getUserProp o "KrakatoaShadows_ShadowSampleSpacingIsExponential"
				if theValue != undefined do o.shadowGenerator.ShadowSampleSpacingIsExponential = theValue
					
				local theValue = getUserProp o "KrakatoaShadows_ShadowManipulatorDistance"
				if theValue != undefined do o.shadowGenerator.ShadowManipulatorDistance = theValue
				
			)--end if
		)
		
		fn restoreKrakatoaShadows mode =
		(
			getLights mode 
			for o in theLights do restoreKrakatoaShadowsInLight o
			initListView()			
		)
		
		fn addKrakatoaShadows mode =
		(
			if dataLocation !="" do
			(
				getLights mode 
				for o in theLights do addKrakatoaShadowsToLight o 
				initListView()
			)--end if
		)--end fn		
		

		
		fn removeKrakatoaShadowsFromLight o =
		(			
			if classof o.shadowGenerator == Krakatoa_Shadows do
			(
				storeUserProps o
				o.shadowGenerator = o.shadowGenerator.DelegateGenerator
			)		
		)
		

		
		fn removeKrakatoaShadows mode =
		(
			getLights mode 
			for o in theLights do removeKrakatoaShadowsFromLight o
			initListView()
		)		
		
		fn syncSelectionToScene =
		(
			getSelectedItems()
			getLights #sel
			max select none
			try(select theLights)catch()
		)
			
		on Krakatoa_ShadowsExplorer_Dialog close do
		(
			callbacks.removeScripts id:#KrakatoaShadowsExplorer
		)
		
		on dnc_listview ItemSelectionChanged args do
		(
			getSelectedItems()
		)	
		
		on dnc_listview MouseDoubleClick theClick do
		(
			local theItem = dnc_listview.GetItemAt theClick.x theClick.y
			local theRowIndex = theItem.Index + 1
			local theSubItem = (theItem.GetSubItemAt theClick.x theClick.y)
			local theColName = (theSubItem.name) as name
			if theRowIndex > 0 do
			(
				case theColName of
				(
					default: select allLights[theRowIndex]
					#on: allLights[theRowIndex].on = not allLights[theRowIndex].on 
					#geoon: (
								if classof allLights[theRowIndex].shadowGenerator == Krakatoa_Shadows then
									allLights[theRowIndex].shadowGenerator.DelegateOn = not allLights[theRowIndex].shadowGenerator.DelegateOn
								storeUserProps allLights[theRowIndex]
							)
					#autoupdate: (
								if classof allLights[theRowIndex].shadowGenerator == Krakatoa_Shadows then
									allLights[theRowIndex].shadowGenerator.ShadowFilenameAutoUpdate = not allLights[theRowIndex].shadowGenerator.ShadowFilenameAutoUpdate
								storeUserProps allLights[theRowIndex]
							)
							
					#cast: allLights[theRowIndex].baseobject.castshadows = not allLights[theRowIndex].baseobject.castshadows
					#expsample: (
										allLights[theRowIndex].baseobject.shadowGenerator.ShadowSampleSpacingIsExponential  = not allLights[theRowIndex].baseobject.shadowGenerator.ShadowSampleSpacingIsExponential
										storeUserProps allLights[theRowIndex]
									)
					#krakatoa: (
							if classof allLights[theRowIndex].shadowGenerator == Krakatoa_Shadows then
								removeKrakatoaShadowsFromLight allLights[theRowIndex]
							else
								restoreKrakatoaShadowsInLight allLights[theRowIndex]
					)--end krakatoa
					#loadpath: (
						if classof allLights[theRowIndex].shadowGenerator == Krakatoa_Shadows do
						(
							if keyboard.ControlPressed and keyboard.SHIFTPressed then
								try(shellLaunch "explorer.exe" (getFileNamePath allLights[theRowIndex].shadowGenerator.ShadowFilename))catch()
							else 
							(
								assignNewPath()
								storeUserProps allLights[theRowIndex]	
							)
						)
					)
					#savepath:
					(
						if classof allLights[theRowIndex].shadowGenerator == Krakatoa_Shadows do
						(
							if keyboard.ControlPressed and keyboard.SHIFTPressed then
							(
									local theAbsPath = convertRelativeToAbsoluteSavePath allLights[theRowIndex]
									try(shellLaunch "explorer.exe" (getFileNamePath theAbsPath))catch()
							)
							else 
							(
								assignNewSavePath()
								storeUserProps allLights[theRowIndex]
							)
						)
					)
				)--end case
			)--end if
			initListView()
		)
		
		fn syncSelectionFromScene =
		(
			getLights #all
			selectedItems = for o in selection where findItem Light.classes (classof o) > 0 and findItem allLights o > 0 collect findItem allLights o
			initListView()
		)
		
		fn registerWhenCallbacks =
		(
			local theLights = for o in selection where findItem Light.classes (classof o) > 0 collect o
			when parameters theLights change id:#KrakatoaShadowsExplorer handleAt:#redrawViews do Krakatoa_ShadowsExplorer_Dialog.initListView()
		)
			
		on Krakatoa_ShadowsExplorer_Dialog close do
		(
			deleteAllChangeHandlers id:#KrakatoaShadowsExplorer
			callbacks.removeScripts id:#KrakatoaShadowsExplorer
		)
		
		on Krakatoa_ShadowsExplorer_Dialog open do
		(
			callbacks.removeScripts id:#KrakatoaShadowsExplorer
			callbacks.addScript #postRender "Krakatoa_ShadowsExplorer_Dialog.initListView()" id:#KrakatoaShadowsExplorer
			callbacks.addScript #nodeCreated "Krakatoa_ShadowsExplorer_Dialog.initListView()" id:#KrakatoaShadowsExplorer
			callbacks.addScript #nodePostDelete "Krakatoa_ShadowsExplorer_Dialog.initListView()" id:#KrakatoaShadowsExplorer
			callbacks.addScript #selectionSetChanged "Krakatoa_ShadowsExplorer_Dialog.registerWhenCallbacks()" id:#KrakatoaShadowsExplorer
			
			getLights #all
			
			initListViewLayout()
			initListView()
			registerWhenCallbacks()
		)
		
		on Krakatoa_ShadowsExplorer_Dialog moved pos do
		(
			setIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini" ) "KrakatoaShadowsExplorer" "Position" (pos as string)
		)
	
		on Krakatoa_ShadowsExplorer_Dialog resized val do
		(
			dnc_listview.width = val.x-10
			dnc_listview.height = val.y-10
		)		
	
	)--end rollout
	
	local thePos = execute (getIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini" ) "KrakatoaShadowsExplorer" "Position")
	if thePos == OK do thePos = [200,200]
	if thePos.x > sysinfo.desktopsize.x - 800 do thePos.x = sysinfo.desktopsize.x - 800 
	if thePos.y > sysinfo.desktopsize.y - 500 do thePos.y = sysinfo.desktopsize.y - 500 
		
	createDialog Krakatoa_ShadowsExplorer_Dialog 1000 300 thePos.x thePos.y style:#(#style_titlebar, #style_border, #style_sysmenu, #style_minimizebox, #style_resizing, #style_maximizebox  ) menu:Krakatoa_ShadowsExplorer_Menu

)--end script
