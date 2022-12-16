-- Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
-- SPDX-License-Identifier: Apache-2.0
(
	local MagmaFlowEditor_Functions = ::MagmaFlowEditor_Functions  

	local MagmaFlowEditor_Rollout --holds the local rollout for the editor dialog
	local magma --contains the MagmaHolder to be edited
	local MagmaFlowEditor_isInitializing = false --a flag to notify functions when the editor is being initalized so certain operations can be suspended
	local MagmaFlowEditor_DebugRollout 
	local NodeBitmapsCache = #()
	local lastErrorNode = undefined
	local lastErrorMessage = ""
	local ErrorNodesList = #()
	local currentPreset = ""
	local needToSave = false
	local DebugModeEnabled  = true
	local thePresetsFolder = ""
	
	local trackID = (random 10000 10000000) as string + "_" + (random 10000 10000000) as string
	
	--MAGMAFLOW SETTINGS STRUCT - holds all editor settings in a struct. ToDo: Save/Load Presets
	global MagmaFlowSettingsStruct
	struct MagmaFlowSettingsStruct 
	(
		NodeWidth = 120,
		SnapToGrid = true,
		GridSizeX = 10,
		GridSizeY = 10,
		DepotPlacement = #bottomrollupreverse,
		DepotNodeWidth = 80,
		DepotShowBLOPs = true,
		DepotShowCategories = true,
		DepotAutoCollapseOnDragAndDrop = true,
		DepotCategoryTransparent = true,
		nodeInsertSocket = 1,
		nodeInsertMode = true,
		AutoReorderToggle = false,
		AutoReorderPattern = #tail,
		AutoReorderBlockHeight = 4,
		AllowSocketFlipping = true,
		UnconnectedNodesPlacement = #left,
		AllowSubtreeCollapsing = true,
		AutoZoomExtents = false,
		DebugModeOn = false,
		DebugShowMinMaxMean = true,
		DebugShowOutputsInColumns = true,
		DebugSelectedOnly = false,
		DebugFormat = #mxs,
		NodeYSpace = 10,
		NodeXSpace = 10,
		NumEditingBLOPs = 0,
		playbackDuration = 5.0,
		isPickingChannelFromNode = undefined,
		insertNodeIntoFlow = false,
		showTextureMapSample = false,
		showColorSwatchSample = false,
		showInputSocketName = true,
		showInputSocketValue = true,
		DrawShadows = true,
		ElbowSize = 60,
		InputsOnTheLeftAll = false,
		InputsOnTheLeftValue = true,
		InputsOnTheLeftChannel = false,
		InputsOnTheLeftObject = false,
		InputsOnTheLeftGeometry = false,
		InputsOnTheLeftParticles = false,
		InputsOnTheLeftScript = false,
		SwapDefaultsOnInputSwap = true,
		outputNodesOnRight = true
	)
	MagmaFlowSettings = MagmaFlowSettingsStruct()
	
	local theIniFileLocation = ""
	
	fn loadDefaultSettings =
	(
		local theIniFile = (theIniFileLocation +"MagmaFlowEditor_Preferences.ini")	
		local theVal = execute (getIniSetting theIniFile "ParticleChannelEditor" "DepotNodeWidth" )
		MagmaFlowSettings.DepotNodeWidth = if theVal != OK then theVal else 80
		local theVal = execute (getIniSetting theIniFile "ParticleChannelEditor" "NodeWidth")
		MagmaFlowSettings.NodeWidth = if theVal != OK then theVal else 120
		local theVal = execute (getIniSetting theIniFile "ParticleChannelEditor" "NodeXSpace" )
		MagmaFlowSettings.NodeXSpace = if theVal != OK then theVal else 20
		local theVal = execute (getIniSetting theIniFile "ParticleChannelEditor" "NodeYSpace" )
		MagmaFlowSettings.NodeYSpace = if theVal != OK then theVal else 20
		local theVal = execute (getIniSetting theIniFile "ParticleChannelEditor" "GridXSpacing" )
		MagmaFlowSettings.GridSizeX = if theVal != OK then theVal else 10
		local theVal = execute (getIniSetting theIniFile "ParticleChannelEditor" "GridYSpacing" )
		MagmaFlowSettings.GridSizeY = if theVal != OK then theVal else 10
			
		local theVal = execute (getIniSetting theIniFile "ParticleChannelEditor" "ElbowSize")
		MagmaFlowSettings.ElbowSize = if theVal != OK then theVal else 35		
			
		local theVal = execute (getIniSetting theIniFile "ParticleChannelEditor" "DrawShadows" )
		
		MagmaFlowSettings.DrawShadows =  if theVal != OK then theVal == True else True
		
		
		local theVal = execute (getIniSetting theIniFile "InputsOnLeft" "Value" )
		if classof theVal == BooleanClass do MagmaFlowSettings.InputsOnTheLeftValue = theVal
		local theVal = execute (getIniSetting theIniFile "InputsOnLeft" "Channel" )
		if classof theVal == BooleanClass do MagmaFlowSettings.InputsOnTheLeftChannel = theVal
		local theVal = execute (getIniSetting theIniFile "InputsOnLeft" "Object" )
		if classof theVal == BooleanClass do MagmaFlowSettings.InputsOnTheLeftObject = theVal
		local theVal = execute (getIniSetting theIniFile "InputsOnLeft" "Geometry" )
		if classof theVal == BooleanClass do MagmaFlowSettings.InputsOnTheLeftGeometry = theVal
		local theVal = execute (getIniSetting theIniFile "InputsOnLeft" "Particles" )
		if classof theVal == BooleanClass do MagmaFlowSettings.InputsOnTheLeftParticles = theVal
		local theVal = execute (getIniSetting theIniFile "InputsOnLeft" "Script" )
		if classof theVal == BooleanClass do MagmaFlowSettings.InputsOnTheLeftScript = theVal
			
		local theVal = execute (getIniSetting theIniFile "Debugger" "ShowMinMaxMean" )
		MagmaFlowSettings.DebugShowMinMaxMean = if theVal != OK then theVal else true

		local theVal = execute (getIniSetting theIniFile "Debugger" "ShowOutputsInColumns" )
		MagmaFlowSettings.DebugShowOutputsInColumns = if theVal != OK then theVal else false

		local theVal = execute (getIniSetting theIniFile "Debugger" "DebugSelectedOnly" )
		MagmaFlowSettings.DebugSelectedOnly = if theVal != OK then theVal else false

		local theVal = execute (getIniSetting theIniFile "Options" "SwapDefaultsOnInputSwap" )
		MagmaFlowSettings.SwapDefaultsOnInputSwap = if theVal != OK then theVal else false
			
		local theVal = (getIniSetting theIniFile "Debugger" "DebugFormat" )
		MagmaFlowSettings.DebugFormat = if theVal == "" then #mxs else theVal as name
	)
	

	MagmaFlowEditor_Functions.loadColorScheme (theIniFileLocation + "MagmaFlowEditor_CurrentColorScheme.ini")
	
	local channelsList = #()
	local sortedChannelsList = #()		
	local editorNodeCount = 0
	local NodeCreationMenuPosition = [0,0]
	
	local CurrentIntController = bezier_float()
	local CurrentFloatController = bezier_float()
	local CurrentVectorController = Point3_xyz()
	
	local EditableBlopStack = #()

	local LastUndoRecordNumber = 0
	local UndoRecordNames = #()
	local MagmaFlowEditor_UniqueUndoID = (random 1 100000) as string + "_" + (random 1 100000) as string
	
	local DebugOverlayArray = #()
	
	local theInputSocketNames = #("1","2","3")
	local theOutputSocketNames = #()
	
	local allBlopNames = #()
	local allBlopDescriptions = #()
	
	local theUserFolder = ""
	
	local resultsArray = #()
	local debugResult
	local columnLayout = #()
	local theMinMaxMean = #()	
	local theDebuggerSelection = 1
	
	rollout MagmaFlowEditor_DebugRollout "Krakatoa Magma Debugger"
	(
		spinner spn_first "First:" range:[1,10^9,1] type:#integer fieldwidth:60 across:2 pos:[1,1] scale:100

		button btn_previous "<<< Previous" width:80 pos:[105,0] height:18 
		button btn_next "Next >>>" width:80 pos:[185,0] height:18 
		
		spinner spn_count "Count:" range:[1,10000,1000] type:#integer fieldwidth:60 pos:[270,1] scale:100
		spinner spn_nth "Nth:" range:[1,10000,1] type:#integer fieldwidth:40 pos:[380,1] 
		
		button btn_updateme "UPDATE" width:100 pos:[480,0] height:18 
		progressbar prg_progress height:6 pos:[0,18] width:580 color:red
		dotNetControl dnc_datalistview "ListView" pos:[0,24]  width:1200 height:400 
			
		fn initDataListView =
		(
			local lv = dnc_datalistview
			local layout_def = #(#("Index",40))
			local cnt = 0
			if resultsArray.count > 0 do
			(
				for i in resultsArray[1][2] do 
				(
					cnt += 1
					local theNodeType = magma.getNodeType i[1]
					local theNodeName = magma.getNodeProperty i[1] "Name"
					if theNodeName == undefined do theNodeName = theNodeType
					local columnName = (i[1] as string + ":" + theNodeType)
					if theNodeType as name == #InputChannel do columnName += " ["+ magma.getNodeProperty i[1] "channelName" + "]"
					if theNodeType as name == #Output do columnName += " ["+ magma.getNodeProperty i[1] "channelName" + "]"
					if MagmaFlowSettings.DebugShowOutputsInColumns do columnName += "->"+ columnLayout[cnt][1]
					
					if theNodeType as name != #Output do columnName += " \""+theNodeName+"\""
					local theColumnWidth = 0
					if theNodeType as name == #InputGeometry then
						theColumnWidth = (5+((magma.getNodeProperty i[1] "node") as string).count) * 6
					else
						for k = 2 to i.count do theColumnWidth+= ((i[k] as string).count + ((magma.GetNodeOutputDescription i[1] (k-1)) as string).count + 1 )* 6
					local theVal = try( execute (getIniSetting (theIniFileLocation + "MagmaFlowDebugger_Layout.ini") "DebuggerColumnWidth" (theNodeType+ "_" +columnLayout[cnt][1]+(if MagmaFlowSettings.DebugShowOutputsInColumns then "" else "_ALL") )	) )catch(OK)
					if theVal != OK do theColumnWidth = theVal

					if theColumnWidth < 60 do theColumnWidth = 60
					
					append layout_def #(columnName, theColumnWidth)
				)
			)
			lv.Clear()
			lv.backColor = (dotNetClass "System.Drawing.Color").fromARGB 221 221 225
			lv.View = (dotNetClass "System.Windows.Forms.View").Details
			lv.gridLines = true 
			lv.fullRowSelect = true 
			lv.MultiSelect = false
			lv.checkboxes = false
			lv.hideSelection = false		
			for i in layout_def do
				lv.Columns.add i[1]  i[2]
			
			--showProperties lv.Columns.Item[1]
		) 		
		
		on dnc_datalistview ColumnWidthChanged arg do 
		(
			local theIndex = arg.ColumnIndex
			if theIndex > 0 do 
			(
				local theNodeType = magma.getNodeType columnLayout[theIndex][2] + "_" +  (columnLayout[theIndex][1]) +(if MagmaFlowSettings.DebugShowOutputsInColumns then "" else "_ALL")
				--local theText = dnc_datalistview.Columns.Item[theIndex].Text
				local theWidth = dnc_datalistview.Columns.Item[theIndex].Width
				setIniSetting (theIniFileLocation + "MagmaFlowDebugger_Layout.ini") "DebuggerColumnWidth" theNodeType (theWidth as string)
			)
		)
		
		/*
		fn compileFlow =
		(
			local channelsArray = #()
			local channelNames = #()
			local nodeArray = Magma.GetNodes()
			
			resultsArray = #()
			for i = 1 to nodeArray.count do 
			(
				local theID = nodeArray[i]
				if (magma.getNodeType theID) as name == #InputChannel do
				(
					local theChannelName = magma.getNodeProperty theID "channelName"
					local theVal = 0 
					if theChannelName != "Index" do --don't add Index channel to the list!
					(
						local theChannels = MagmaFlowEditor_Functions.loadChannelsList magma
						local theChannelNames = for j in theChannels collect j[1]
						local theIndex = findItem theChannelNames theChannelName
						if theIndex > 0 then
						(
							theVal = case theChannels[theIndex][3] of
							(
								1: (if matchPattern theChannels[theIndex][2] pattern:"int*" then 0 else 0.0)
								2: [0,0]
								default: [0,0,0] 
								4: [0,0,0,1]
							)
						)
						append channelsArray #(theChannelName, theVal)
						append channelNames theChannelName
					)--end if index
				)--end if channel
			)--end i loop
			local PRTObject = (refs.dependentNodes magma)[1]
			if isValidNode PRTObject do
			(
				local oldStates = for m in PRTObject.modifiers collect m.enabled
				local theModIndex = 0
				for i = 1 to PRTObject.modifiers.count where classof PRTObject.modifiers[i] == MagmaModifier and PRTObject.modifiers[i].MagmaHolder == magma do theModIndex = i
				for i = 1 to theModIndex do PRTObject.modifiers[i].enabled = false
				classof PRTObject
				local currentStream = try(FranticParticles.GetPRTObjectIStream PRTObject false false)catch(undefined)
				if currentStream != undefined do
				(
					local theCount = currentStream.getCount()
					if theCount == undefined do theCount = spn_count.value
					theCount = amin #(theCount, spn_count.value)
					local theStep = spn_nth.value
					if theStep > theCount do theStep = theCount-1
					
					local theStreamChannels = currentStream.getChannels()
					local resultArray = #()
					theParticleRecord = #()
					currentStream.skipParticles (spn_first.value-1)
					for aParticle = 1 to theCount by theStep while theParticleRecord != undefined do
					(
						theParticleRecord = currentStream.readParticle()
						if theParticleRecord != undefined do
						(
							for c = 1 to theStreamChannels.count do
							(
								--Convert to #("Name", "type", arity) format
								theStreamChannels[c] = filterString theStreamChannels[c] " []"
								if theStreamChannels[c].count == 3 then (
									theStreamChannels[c][3] = theStreamChannels[c][3] as integer
								)else(
									theStreamChannels[c][3] = 1
								)
								
								local theIndex = findItem channelNames theStreamChannels[c][1]
								if theIndex > 0 then 
								(
									channelsArray[theIndex][2] = theParticleRecord[c]									
								)
								else
								(
									append channelNames theStreamChannels[c][1]
									append channelsArray #(theStreamChannels[c][1], theParticleRecord[c])
								)
							)
							local nodeArray = Magma.GetNodes()
							local result = try(magma.CompileAndExecute channelsArray aParticle true)catch(for i = 1 to editorNodeCount collect #(nodeArray[i], getCurrentException()  ))
							append resultsArray #(aParticle, result)
						)
					)
					currentStream.close()
				)
				local dataInWorldSpace = true
				for m = 1 to PRTObject.modifiers.count do PRTObject.modifiers[m].enabled = oldStates[m]
			)
			resultsArray
		)
		*/
		
		
		fn populateDebuggerData =
		(
			local theFormatString = case MagmaFlowSettings.DebugFormat of
			(
				default: "-8.8f"
				#format12:  "-12.12f"
				#format16:  "-16.16f"
			)

			local lv = dnc_datalistview
			local theRange = #()
			local theFirst = spn_first.value 
			if theFirst > debugResult.count do theFirst = debugResult.count
			local theLast = spn_first.value + spn_count.value
			if theLast > debugResult.count do theLast = debugResult.count
			local theStep = spn_nth.value
			if theStep > theLast-spn_first.value do theStep = theLast-spn_first.value-1
			if theStep == 0 do theStep = 1	
			
			local theNodes = magma.getNodes()
			
			if MagmaFlowSettings.DebugShowMinMaxMean do
			(
				li1 = dotNetObject "System.Windows.Forms.ListViewItem" ("Min")
				li1.tag = -1
				li1.backColor = (dotNetClass "System.Drawing.Color").fromARGB 250 221 221 
				
				li2 = dotNetObject "System.Windows.Forms.ListViewItem" ("Max")
				li2.tag = -1
				li2.backColor = (dotNetClass "System.Drawing.Color").fromARGB 221 250 221 

				li3 = dotNetObject "System.Windows.Forms.ListViewItem" ("Mean")
				li3.tag = -1
				li3.backColor = (dotNetClass "System.Drawing.Color").fromARGB 221 221 250
				
				
				for n in theNodes where (if MagmaFlowSettings.DebugSelectedOnly then magma.getnodeProperty n "Selected" == true else true) AND magma.getNodeType n != "Output" and magma.getNodeProperty n "Enabled" != false and magma.getNodeProperty n "Internal_NodeConnected" == true do
				(
					local txt1 = ""
					local txt2 = ""
					local txt3 = ""
					local theOutCount = (magma.GetNumNodeOutputs n)
					for w = 1 to theOutCount do 
					(
						local theVal = debugResult.GetNodeMinMaxMeanValue n w
						if theVal == undefined do theVal = #("N/A","N/A","N/A")
						if theVal[1] == undefined do theVal[1] = "N/A"
						if theVal[2] == undefined do theVal[2] = "N/A"
						if theVal[3] == undefined do theVal[3] = "N/A"
							
						if MagmaFlowSettings.DebugShowOutputsInColumns then
						(
							if MagmaFlowSettings.DebugFormat == #mxs or classof theVal[1] == Integer then 
							(
								li1.SubItems.add (theVal[1] as string)
								li2.SubItems.add (theVal[2] as string)
								li3.SubItems.add (theVal[3] as string)
							)
							else
							(
								li1.SubItems.add ( formattedPrint theVal[1] format:theFormatString )
								li2.SubItems.add ( formattedPrint theVal[2] format:theFormatString )
								li3.SubItems.add ( formattedPrint theVal[3] format:theFormatString )
							)
						)
						else
						(
							if theOutCount > 1 do 
							(
								local str = magma.GetNodeOutputDescription n w + ":"
								txt1 += str
								txt2 += str
								txt3 += str
							)
							if MagmaFlowSettings.DebugFormat == #mxs or classof theVal[1] == Integer then 
							(
								txt1 += theVal[1] as string + "  "
								txt2 += theVal[2] as string + "  "
								txt3 += theVal[3] as string + "  "
							)
							else
							(
								txt1 += ( formattedPrint theVal[1] format:theFormatString ) + "  "
								txt2 += ( formattedPrint theVal[2] format:theFormatString ) + "  "
								txt3 += ( formattedPrint theVal[3] format:theFormatString ) + "  "								
							)
						)
					)
					if not MagmaFlowSettings.DebugShowOutputsInColumns do
					(
						li1.SubItems.add  txt1
						li2.SubItems.add  txt2
						li3.SubItems.add  txt3
					)
				)
				append theRange li1
				append theRange li2
				append theRange li3
			)			
			
			for i = theFirst to theLast by theStep do
			(
				prg_progress.value = 100.0*i/(theLast-spn_first.value)
				local theValues = #()
				for n in theNodes where (if MagmaFlowSettings.DebugSelectedOnly then magma.getnodeProperty n "Selected" == true else true) AND magma.getNodeType n != "Output" AND magma.getNodeProperty n "Enabled" != false AND magma.getNodeProperty n "Internal_NodeConnected" == true do
				(
					if MagmaFlowSettings.DebugShowOutputsInColumns then
					(
						for w = 1 to (magma.GetNumNodeOutputs n) do 
							append theValues #(n,debugResult.GetNodeValue i n w)
					)
					else
					(
						local theColArray = #(n)
						for w = 1 to (magma.GetNumNodeOutputs n) do 
							append theColArray (debugResult.GetNodeValue i n w)
						append theValues theColArray
					)
				)
				--if theValues != undefined do
				(
					local li = dotNetObject "System.Windows.Forms.ListViewItem" (i as string)
					li.tag = i
					local txt = ""
					for j in theValues do
					(
						local theNodeType = (magma.getNodeType j[1]) as name
						if j[2] == undefined then
						(
							case theNodeType of
							(
								#CurrentMesh: txt = "Modifier Geometry Data  "
								#InputGeometry: txt = "Geometry:"+((magma.getNodeProperty j[1] "nodes") as string)+"  "
								#InputParticles: txt = "Particles:"+((magma.getNodeProperty j[1] "node") as string)+"  "
								#InputObject: txt = "Object:"+((magma.getNodeProperty j[1] "object") as string)+"  "
								default: (j[2] as string)
							)
						)
						else
						(
							txt = if j.count > 2 then "" else 
								if MagmaFlowSettings.DebugFormat == #mxs or classof j[2] == Integer then (j[2] as string) else (formattedPrint j[2] format:theFormatString) 
						)
						if j.count > 2 then
						(
							for k = 2 to j.count do
							(
								if j[k] != undefined do
								(
									local theOutputName = (magma.GetNodeOutputDescription j[1] (k-1)) 
									txt += theOutputName +":"+ (if MagmaFlowSettings.DebugFormat == #mxs or classof j[k] == Integer then (j[k] as string) else (formattedPrint j[k] format:theFormatString)) + "  " 
								)
							)
						)
						li.SubItems.add txt
					)
					append theRange li						
				)--end if
			)--end i loop
			lv.Items.AddRange theRange 
			lv.ResumeLayout false					
			prg_progress.value  = 0
		)
		
		fn compileMagmaDebugData forceUpdate:true =
		(
			local lv = dnc_datalistview
			lv.Update()
			lv.SuspendLayout()
			resultsArray = #()
			local theMod = MagmaFlowEditor_Functions.getMagmaModifier magma
			if theMod != undefined do
			(
				local theNode  = (refs.dependentNodes theMod)[1]
				if isValidNode theNode do
				(
					local theIndex = (for m = 1 to theNode.modifiers.count where theNode.modifiers[m] == theMod collect m)[1]
					local theNodes = magma.getNodes()
					
					if forceUpdate == true or debugResult == undefined do 
					(
						debugResult = undefined
						gc light:true
						debugResult = theMod.EvaluateDebug theNode theIndex
					)
					if debugResult != undefined then
					(
						resultsArray = #(#(1,#()))
						columnLayout = #()
						for n in theNodes where (if MagmaFlowSettings.DebugSelectedOnly then magma.getnodeProperty n "Selected" == true else true) AND magma.getNodeType n != "Output" AND  magma.getNodeProperty n "Enabled" != false AND magma.getNodeProperty n "Internal_NodeConnected" == true do
						(
							if MagmaFlowSettings.DebugShowOutputsInColumns then
							(
								for w = 1 to (magma.GetNumNodeOutputs n) do 
								(
									append resultsArray[1][2] #(n,debugResult.GetNodeValue 1 n w)
									append columnLayout #( (magma.GetNodeOutputDescription n w), n, w )
								)
							)
							else
							(
								local theColArray = #(n)
								for w = 1 to (magma.GetNumNodeOutputs n) do 
									append theColArray (debugResult.GetNodeValue 1 n w)
								append resultsArray[1][2] theColArray 
								append columnLayout #( (magma.GetNodeOutputDescription n 1), n, 1 )
							)
						)
						local txt = "KRAKATOA "
						txt += "Debugger - <" + theNode.name + ">." + theMod.name
						MagmaFlowEditor_DebugRollout.title = txt 				
					)
					else 
					(
						local txt = "KRAKATOA "
						txt += "Debugger - <" + theNode.name + ">." + theMod.name + " -- ERROR EVALUATING FLOW!"
						MagmaFlowEditor_DebugRollout.title = txt 							
						resultsArray = #(#(1, #())) --#(0,"ERROR","Failed To Evaluate Flow")
					)
				)
			)
			--resultsArray
		)
		
		fn updateDebugTitle =
		(
			local theNodesString = "- "
			local theNodes = refs.dependentNodes magma
			for i = 1 to theNodes.count do 
			(
				theNodesString += "<"+theNodes[i].name +">"
				theMods = for j in refs.dependents magma where ( classof j == MagmaModifier or classof j == SpaceMagmaModifier ) collect j.name
				for j = 1 to theMods.count do
					theNodesString += "." + theMods[1]+" "
				if i < theNodes.count do theNodesString += " | "
			)
			local txt = "KRAKATOA"
			txt +=" Debugger " + theNodesString
			MagmaFlowEditor_DebugRollout.title = txt 
		)		
		
		fn populateDataListView =
		(
			if debugResult != undefined do populateDebuggerData()
		)
		
		fn resizeDialog size =
		(
			dnc_datalistview.pos = [0,24]
			dnc_datalistview.width = size.x
			dnc_datalistview.height = size.y-24
		)
			
		on dnc_datalistview ColumnClick args do
		(
			if args.column > 0 do
			(
				local theID = resultsArray[1][2][args.column][1]
				local theNodes = Magma.GetNodes()
				for i = 1 to theNodes.count where theNodes[i] == theID do
				(
					MagmaFlowEditor_Rollout.setSelectedNodes #(i)
					MagmaFlowEditor_Rollout.displaySelectedNodeProperties()
					MagmaFlowEditor_Rollout.UpdateNavigator()			
					try
					(
						MagmaFlowSettings.nodeInsertSocket = columnLayout[args.column][3]
					)catch(MagmaFlowSettings.nodeInsertSocket = 1)
					MagmaFlowSettings.nodeInsertMode = true					
					MagmaFlowEditor_Rollout.updateWireColorsOnly()
				)
			)
		)		
		
		on dnc_datalistview ItemSelectionChanged args do
		( 
			theDebuggerSelection = dnc_datalistview.items.item[args.ItemIndex].tag
			MagmaFlowEditor_Rollout.createNodeTree init:false
			DebugOverlayArray = #()
		)
		
		
		on MagmaFlowEditor_DebugRollout resized size do
		(
			resizeDialog size
		)
		
		on MagmaFlowEditor_DebugRollout close do
		(
			MagmaFlowSettings.DebugModeOn = false
			MagmaFlowEditor_Rollout.createNodeTree init:false
			debugResult = undefined
			gc light:true			
		)
		
		fn updateDialog forceUpdate:true updateColumns:true =
		(
			local st0 = timestamp()
			compileMagmaDebugData forceUpdate:forceUpdate
			local st1 = timestamp()
			
			local columnLayout2 = #()
			local theNodes = magma.getNodes()
			for n in theNodes where (if MagmaFlowSettings.DebugSelectedOnly then magma.getnodeProperty n "Selected" == true else true) AND magma.getNodeType n != "Output" AND  magma.getNodeProperty n "Enabled" != false AND magma.getNodeProperty n "Internal_NodeConnected" == true do
			(
				if MagmaFlowSettings.DebugShowOutputsInColumns then
					for w = 1 to (magma.GetNumNodeOutputs n) do 
						append columnLayout2 #( (magma.GetNodeOutputDescription n w), n, w )
				else
						append columnLayout2 #( (magma.GetNodeOutputDescription n 1), n, 1 )
			)
			if columnLayout as string != columnLayout2 as string do 
			(
				updateColumns = true
			)
			
			
			if updateColumns then 
				initDataListView()
			else
				dnc_datalistview.Items.Clear()
				
			local st2 = timestamp()
			populateDataListView()
			local st3 = timestamp()
			pushprompt ((st3-st0) as string +" ms Magma Debug - Compile:"+(st1-st0) as string + " ms | Init:"+(st2-st1) as string+" ms | Populate:"+(st3-st2) as string+" ms")
			MagmaFlowEditor_Rollout.createNodeTree init:false
		)
		
		
		on btn_previous pressed do 
		(
			spn_first.value -= spn_count.value
			if spn_first.value < 1 do spn_first.value = 1
			setIniSetting (theIniFileLocation + "MagmaFlowEditor_Preferences.ini") "Debugger" "First" (spn_first.value as string)
			updateDialog forceUpdate:false updateColumns:false
		)

		on btn_next pressed do 
		(
			spn_first.value += spn_count.value
			setIniSetting (theIniFileLocation + "MagmaFlowEditor_Preferences.ini") "Debugger" "First" (spn_first.value as string)
			updateDialog forceUpdate:false updateColumns:false	
		)
		
		on btn_updateme pressed do updateDialog forceUpdate:true
		
		on spn_first changed val do
		(
			setIniSetting (theIniFileLocation + "MagmaFlowEditor_Preferences.ini") "Debugger" "First" (val as string)
			updateDialog forceUpdate:false updateColumns:false
		)
		on spn_count changed val do
		(
			setIniSetting (theIniFileLocation + "MagmaFlowEditor_Preferences.ini") "Debugger" "Count" (val as string)
			updateDialog forceUpdate:false  updateColumns:false
		)		
		on spn_nth changed val do
		(
			setIniSetting (theIniFileLocation + "MagmaFlowEditor_Preferences.ini") "Debugger" "Nth" (val as string)
			updateDialog forceUpdate:false  updateColumns:false
		)
		
		on MagmaFlowEditor_DebugRollout open do
		(
			local theIniFile = (theIniFileLocation + "MagmaFlowEditor_Preferences.ini")	
			theVal = execute (getIniSetting theIniFile "Debugger" "First" )
			if theVal == OK do theVal = 1
			spn_first.value = theVal
			theVal = execute (getIniSetting theIniFile "Debugger" "Count" )
			if theVal == OK do theVal = 100
			spn_count.value = theVal
			theVal = execute (getIniSetting theIniFile "Debugger" "Nth" )
			if theVal == OK do theVal = 1
			spn_nth.value = theVal			
			
			updateDebugTitle()
			--updateDialog()
		)
		
	)
	
	rollout MagmaFlowEditor_NodeNameRollout "Name and User Notes" category:50
	(
		local NetKeys = dotNetClass "System.Windows.Forms.Keys"
		label lbl_nodeName "Node Name:" align:#left offset:[-10,-5]
		edittext edt_nodeName width:162 offset:[-4,-4] align:#center
		label lbl_userNotes "User Notes:" align:#left offset:[-10,-2]
		--edittext edt_userNotes width:162 height:80 offset:[-4,-4] align:#center
		
		dotNetControl dnc_userNotes "System.Windows.Forms.TextBox" width:162 height:80 offset:[0,-4] align:#center
		on edt_nodeName entered txt do 
		(
			local theID = MagmaFlowEditor_Functions.getNodeID magma MagmaFlowEditor_Rollout.lastNodeClick 
			MagmaFlowEditor_Functions.setUIProperty magma theID "Name" txt
			MagmaFlowEditor_Rollout.createNodeTree init:false
			MagmaFlowEditor_Rollout.createUndoRecord ("Change Node Name To [" +txt +"]")
			MagmaFlowEditor_Rollout.exposeControlsToModifier()
		)		

		on dnc_userNotes lostfocus sender arg do 
		(
			local theID = MagmaFlowEditor_Functions.getNodeID magma MagmaFlowEditor_Rollout.lastNodeClick
			local txt = dnc_userNotes.text
			txt = substituteString txt "\r\n" "\n"
			txt = substituteString txt "\"" "'"
			magma.setNodeProperty theID "Notes" txt
			MagmaFlowEditor_Functions.setUIProperty magma theID "Notes" dnc_userNotes.text
			MagmaFlowEditor_Rollout.createUndoRecord ("Edited User Notes.")
			MagmaFlowEditor_Rollout.createNodeTree init:true
			MagmaFlowEditor_Rollout.exposeControlsToModifier()
		)
		
		on dnc_userNotes KeyDown EventArgs do
		(
			if EventArgs.KeyCode == NetKeys.Enter then
			(
				dnc_userNotes.paste("\r\n")
			)
			else if EventArgs.KeyCode == NetKeys.Tab then
			(
				dnc_userNotes.paste("\t")
			)
		)		
		
		fn RolloutOpen =
		(
			local theID = MagmaFlowEditor_Functions.getNodeID magma MagmaFlowEditor_Rollout.lastNodeClick
			local txt = MagmaFlowEditor_Functions.getNodeName magma theID
			if txt == undefined do txt = magma.getNodeType theID
			edt_nodeName.text = txt
			
			
			local theUserNotes = MagmaFlowEditor_Functions.getUIProperty magma theID "Notes" 
			if theUserNotes == undefined do theUserNotes  = ""
			theUserNotes = substituteString theUserNotes "\n" "\r\n"
			
			dnc_userNotes.multiline = true
			dnc_userNotes.AcceptsReturn = false
			dnc_userNotes.AcceptsTab = true
			
			dnc_userNotes.ScrollBars= dnc_userNotes.ScrollBars.Both
			
			local theColor = (colorman.getColor #window) * [255,270,255]
			dnc_userNotes.BackColor = dnc_userNotes.BackColor.fromARGB theColor.x theColor.y theColor.z

			local theColor = (colorman.getColor #windowtext) * 255
			dnc_userNotes.ForeColor = dnc_userNotes.ForeColor.fromARGB theColor.x theColor.y theColor.z
			
			dnc_userNotes.text = theUserNotes
		)
		
		on MagmaFlowEditor_NodeNameRollout open do
		(
			RolloutOpen()
		)
		
		on MagmaFlowEditor_NodeNameRollout rolledup state do
		(
			if not MagmaFlowEditor_isInitializing do
			(
				setIniSetting (theIniFileLocation + "MagmaFlowEditor_Preferences.ini") "MagmaEditor" "NodeNameRolloutRolledup" (state as string)
			)
		)
	)		
	
	local MagmaFlowEditor_OptionsRollout
	rcmenu MagmaFlowEditor_OptionsRollout_Menu 
	(
		menuItem mnu_loadDefault "GET Default Value"
		separator sep_10
		menuItem mnu_setCurrentValueAsDefault "SET DEFAULT For New Modifiers To The Current Value"
		separator sep_20
		menuItem mnu_resetToFactoryDefault "RESET DEFAULT For New Modifiers To Factory Default Value"
		on mnu_setCurrentValueAsDefault picked do MagmaFlowEditor_OptionsRollout.setCurrentValueAsDefault()
		on mnu_loadDefault picked do MagmaFlowEditor_OptionsRollout.loadDefault()
		on mnu_resetToFactoryDefault picked do MagmaFlowEditor_OptionsRollout.resetToFactoryDefault()
	)
	
	local MagmaFlowEditor_FilePresetsRollout
	local currentFolder = ""
	
	rcmenu MagmaPresetsFolder_RCMenu 
	(
		menuItem mnu_ExploreFolder "EXPLORE Presets Folder..."
		separator sep_10
		menuItem mnu_setFolder "SET Presets Folder Location..."
		menuItem mnu_resetFolder "RESET Presets Folder Location To Factory Default"
		
		on mnu_ExploreFolder picked do MagmaFlowEditor_FilePresetsRollout.explorePresetsFolder()
		on mnu_setFolder picked do MagmaFlowEditor_FilePresetsRollout.setPresetsFolder()
		on mnu_resetFolder picked do MagmaFlowEditor_FilePresetsRollout.resetPresetsFolder()
	)
	rollout MagmaFlowEditor_FilePresetsRollout "Preset Flows Explorer" category:1000
	(
		local NetKeys = dotNetClass "System.Windows.Forms.Keys"
		local theFoldersList = #()
		local theFilesList = #()

		button btn_FolderOptions "Presets Folder Options..." width:160 align:#center offset:[0,-4] tooltip:"Explore the Presets Folder, set to a custom path, reset to default path..."
			
		listbox ddl_PresetFolders items:#() width:160 align:#center height:5 offset:[0,-4]
		listbox ddl_currentPreset items:#() width:160 align:#center height:10 offset:[0,-5]
		dropdownlist ddl_formats items:#("Magma 1 (*.KMF)", "Magma 2 (*.MagmaScript)") width:160 align:#center selection:2 offset:[1,-5] 

		label lbl_notes align:#left offset:[-7,0]
		--edittext edt_notes " EDIT User Notes:" fieldwidth:160 align:#center height:100 offset:[0,0] labelontop:true
		dotNetControl dnc_Notes "System.Windows.Forms.TextBox" width:162 height:120 offset:[0,-4] align:#center

		
		fn updateNotes =
		(
			if ddl_currentPreset.selection == 1 then
			(
				local txt = magma.note
				txt = substituteString txt "\n" "\r\n"
				dnc_Notes.text = txt
				local theColor = (colorman.getColor #window) * [255,270,255]
				dnc_Notes.BackColor = dnc_Notes.BackColor.fromARGB theColor.x theColor.y theColor.z				
				lbl_notes.caption = "EDIT Current Flow Notes:"
			)
			else 
			(
				local txt = ""
				if ddl_currentPreset.selection > 1 do
				(
					try
					(
						local theFileHandle = openFile theFilesList[ddl_currentPreset.selection]	
						if theFileHandle != undefined then 
						(
							skipToString theFileHandle "magmaNode.note=" 
							if not eof theFileHandle do txt = execute (readLine theFileHandle )
							close theFileHandle 
						)
					)catch()
				)	
				txt = substituteString txt "\n" "\r\n"
				dnc_notes.text = txt
				local theColor = (colorman.getColor #window) * [270,255,255]
				dnc_Notes.BackColor = dnc_Notes.BackColor.fromARGB theColor.x theColor.y theColor.z				
				lbl_notes.caption = "User Notes:"
			)
		)
		
		on dnc_Notes lostfocus sender arg do 
		(
			if ddl_currentPreset.selection == 1 do
			(
				local txt = dnc_notes.text 			
				txt = substituteString txt "\r\n" "\n"
				txt = substituteString txt "\"" "'"				
				magma.note = txt
			)
		)
		
		on dnc_Notes KeyDown EventArgs do
		(
			if ddl_currentPreset.selection == 1 do
			if EventArgs.KeyCode == NetKeys.Enter then
			(
				dnc_Notes.paste("\r\n")
			)
			else if EventArgs.KeyCode == NetKeys.Tab then
			(
				dnc_Notes.paste("\t")
			)
		)		
		

		
		on btn_FolderOptions pressed do
		(
			MagmaPresetsFolder_RCMenu.mnu_ExploreFolder.text = ("EXPLORE Presets Folder ["+thePresetsFolder+"]")
			popUpMenu MagmaPresetsFolder_RCMenu pos:mouse.screenpos
		)

		fn updateFlowFolders =
		(
			local theDirectories = (getDirectories (thePresetsFolder+ "\\*"))
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
			updateNotes()
		)
		
		fn updateFlowList =
		(
			local theType = if ddl_formats.selection == 2 then ".MagmaScript" else ".KMF"
			local theFiles = if ddl_PresetFolders.selection == 1 then 
				(getFiles (thePresetsFolder+ "\\*"+theType ) )
			else
				(getFiles (thePresetsFolder+ "\\"+theFoldersList[ddl_PresetFolders.selection]+"\\*"+theType ) )
			
			theFilesList =  join #("<Edit Current Flow Notes>") theFiles 
			ddl_currentPreset.items = (for f in theFilesList collect getFileNameFile f)
			local theIndex = findItem ddl_currentPreset.items currentPreset
			if theIndex == 0 do theIndex = 1
			ddl_currentPreset.selection = theIndex	
			updateNotes()
		)
		
		on ddl_PresetFolders selected itm do
		(
			currentFolder = ddl_PresetFolders.selected
			updateFlowList()
			--currentPreset =  "Custom"
		)
		
		on ddl_formats selected itm do 
		(
			updateFlowList()
		)
		
		on ddl_currentPreset selected itm do
		(
			updateNotes()
		)
		
		on ddl_currentPreset doubleClicked itm do
		(
			--local thePath = theUserFolder+ "\\MagmaFlows\\Temp\\"
			--makeDir thePath all:true
			if itm > 1 then
			(
				/*if currentPreset == "Custom" do 
				(
					local theFileToSave = (thePath + trackID as string +".MagmaScript")
					if theFileToSave != undefined do
					(
						for i = 1 to magma.NumEditingBLOPs() do magma.PopEditableBLOP() --get out to top level
						local theFlowScript = MagmaFlowEditor_Functions.emitMAXScriptCode magma
						local theFileHandle = createFile theFileToSave 
						format "%\n" theFlowScript to:theFileHandle 
						close theFileHandle
						for i in EditableBlopStack do magma.pushEditableBLOP i
					)					
				)*/
				
				if needToSave do 
				(
					local q = querybox ("Changes to the current flow have not been saved.\n\nDo you want to save the current flow to disk\nbefore opening Preset '"+ ddl_currentPreset.selected+"'"+"?") title:"SAVE Changes?"
					if q do MagmaFlowEditor_Rollout.saveFlowToDisk()
				)
				
				currentPreset = ddl_currentPreset.selected
				currentFolder = ddl_PresetFolders.selected
				
				MagmaFlowEditor_Rollout.closeAllCurveEditors()
				magma.Reset()
				MagmaFlowEditor_Rollout.createNodeTree init:true
				
				if matchPattern (getFilenameType theFilesList[itm] ) pattern:".KMF" then
				(
					MagmaFlowEditor_Functions.convertKMF magma theFile:theFilesList[itm] 
				)
				else
				(
					::magmaNode = magma
					magma.Loading = true
					fileIn theFilesList[itm]		
					magma.Loading = false
				)
				MagmaFlowEditor_Rollout.updateModifierName forceName:("Magma_"+ getFilenameFile theFilesList[itm])

				MagmaFlowEditor_Rollout.restorePanAndZoom()
				MagmaFlowEditor_Rollout.createNodeTree init:true
				MagmaFlowEditor_Rollout.exposeControlsToModifier()
				MagmaFlowEditor_Rollout.autoReorderFlow createUndo:false
				--MagmaFlowEditor_Rollout.displaySelectedNodeProperties()
				MagmaFlowEditor_Rollout.updateNavigator fullUpdate:true
				MagmaFlowEditor_Rollout.createUndoRecord ("Load Preset ["+filenameFromPath theFilesList[itm] +"]")
				needToSave = false
				MagmaFlowEditor_Rollout.updateEditorTitle()
			)
		)

		on MagmaFlowEditor_FilePresetsRollout open do
		(
			--thePresetsFolder = theUserFolder + "\\MagmaFlows\\"
			--local theAlternativeFolder = getIniSetting (theIniFileLocation + "MagmaFlowEditor_Preferences.ini") "Magma" "AlternativePresetsFolder" 
			--if theAlternativeFolder != "" and doesFileExist theAlternativeFolder do thePresetsFolder = theAlternativeFolder
			dnc_Notes.multiline = true
			dnc_Notes.AcceptsReturn = false
			dnc_Notes.AcceptsTab = true
			local theColor = (colorman.getColor #windowtext) * 255.0
			dnc_Notes.ForeColor = dnc_Notes.ForeColor.fromARGB theColor.x theColor.y theColor.z				
			
			
			dnc_Notes.ScrollBars= dnc_Notes.ScrollBars.Both
			
			updateFlowFolders()
			updateFlowList()
			local theIndex = findItem ddl_currentPreset.items currentPreset
			if theIndex == 0 do theIndex = 1
			ddl_currentPreset.selection = theIndex
			local theIndex = findItem ddl_PresetFolders.items currentFolder
			if theIndex == 0 do theIndex = 1
			ddl_PresetFolders.selection = theIndex
			updateNotes()
		)	
		fn explorePresetsFolder =
		(
			local thePath = if ddl_PresetFolders.selection == 1 then 
				(thePresetsFolder) 
			else
				(thePresetsFolder +theFoldersList[ddl_PresetFolders.selection]+"\\") 
			shellLaunch thePath ""
		)
		fn setPresetsFolder =
		(
			local theLastPresetsFolder = thePresetsFolder
			local theLastPresetsFolderFromDisk = 	getIniSetting (theIniFileLocation + "MagmaFlowEditor_Preferences.ini") "Magma" "LastAlternativePresetsFolder"
			if theLastPresetsFolderFromDisk != "" and doesFileExist theLastPresetsFolderFromDisk do theLastPresetsFolder = theLastPresetsFolderFromDisk
			
			local thePath = getSavePath caption:"Select Magma Presets Folder" initialDir:theLastPresetsFolder
			if thePath != undefined and isDirectoryWriteable thePath do
			(
				setIniSetting (theIniFileLocation + "MagmaFlowEditor_Preferences.ini") "Magma" "LastAlternativePresetsFolder" thePresetsFolder
				thePresetsFolder = (thePath+"\\")
				setIniSetting (theIniFileLocation + "MagmaFlowEditor_Preferences.ini") "Magma" "AlternativePresetsFolder" thePresetsFolder
				updateFlowFolders()
				updateFlowList()
				local theIndex = findItem ddl_currentPreset.items currentPreset
				if theIndex == 0 do theIndex = 1
				ddl_currentPreset.selection = theIndex
				local theIndex = findItem ddl_PresetFolders.items currentFolder
				if theIndex == 0 do theIndex = 1
				ddl_PresetFolders.selection = theIndex
				updateNotes()
			)
		)
		fn resetPresetsFolder =
		(
			if theUserFolder + "\\MagmaFlows\\" == thePresetsFolder and getIniSetting (theIniFileLocation + "MagmaFlowEditor_Preferences.ini") "Magma" "AlternativePresetsFolder" == "" then
			(
				messagebox ("The Magma Presets Folder Is Already Set To Factory Default\n\n"+thePresetsFolder) title:" Magma Presets Folder To Factory Default"
			)
			else
			(
				local q = querybox ("Are you sure you want to RESET the Magma Presets Folder to\n\n" + theUserFolder + "\\MagmaFlows\\" + "\n") title:"Reset Magma Presets Folder To Factory Default?"
				if q do
				(
					setIniSetting (theIniFileLocation + "MagmaFlowEditor_Preferences.ini") "Magma" "LastAlternativePresetsFolder" thePresetsFolder
					thePresetsFolder = theUserFolder + "\\MagmaFlows\\"
					setIniSetting (theIniFileLocation + "MagmaFlowEditor_Preferences.ini") "Magma" "AlternativePresetsFolder" ""
					updateFlowFolders()
					updateFlowList()
					local theIndex = findItem ddl_currentPreset.items currentPreset
					if theIndex == 0 do theIndex = 1
					ddl_currentPreset.selection = theIndex
					local theIndex = findItem ddl_PresetFolders.items currentFolder
					if theIndex == 0 do theIndex = 1
					ddl_PresetFolders.selection = theIndex
					updateNotes()			
				)
			)
		)
		
	)
	
	
	rollout MagmaFlowEditor_OptionsRollout "Display Options" category:600
	(
		local currentPropertyForMenu = #none
		spinner spn_DepotNodeWidth "Depot Width:" type:#integer fieldwidth:40 scale:10 range:[60,120,80] across:2 align:#right offset:[55,0]
		button btn_DepotNodeWidth ">>" width:20 height:20 align:#right offset:[10,-3]
		
		spinner spn_nodeWidth "Node Width:" type:#integer fieldwidth:40 scale:10 range:[60,300,120] across:2 align:#right offset:[55,0]
		button btn_nodeWidth ">>" width:20 height:20 align:#right offset:[10,-3]
		spinner spn_ElbowSize "Elbow Node Size:" type:#integer fieldwidth:40 scale:5 range:[30,100,35] across:2 align:#right offset:[55,0]
		button btn_ElbowSize ">>" width:20 height:20 align:#right offset:[10,-3]
		
		
		spinner spn_NodeXSpace "Node X Spacing:" type:#integer fieldwidth:40 scale:10 range:[0,100,10] across:2 align:#right offset:[55,0]
		button btn_NodeXSpace ">>" width:20 height:20 align:#right offset:[10,-3]
		spinner spn_NodeYSpace "Node Y Spacing:" type:#integer fieldwidth:40 scale:10 range:[0,100,10] across:2 align:#right offset:[55,0]
		button btn_NodeYSpace ">>" width:20 height:20 align:#right offset:[10,-3]
		spinner spn_GridXSpacing "Grid X Spacing:" type:#integer fieldwidth:40 scale:5 range:[5,50,10] across:2 align:#right offset:[55,0]
		button btn_ridXSpacing ">>" width:20 height:20 align:#right offset:[10,-3]
		spinner spn_GridYSpacing "Grid Y Spacing:" type:#integer fieldwidth:40 scale:5 range:[5,50,10] across:2 align:#right offset:[55,0]
		button btn_GridYSpacing ">>" width:20 height:20 align:#right offset:[10,-3]
		
		checkbox chk_drawShadows "Draw Node Shadows" across:2
		button btn_DrawShadows ">>" width:20 height:20 align:#right offset:[10,-3]

		checkbox chk_transparentCategories "Transparent Depot" across:2
		button btn_transparentCategories	">>" width:20 height:20 align:#right offset:[10,-3]
		
		group "Color Scheme"
		(
			button btn_editColorScheme "EDIT..." width:74 align:#left offset:[-5,0] across:2
			button btn_resetColorScheme "RESET..." width:74 offset:[5,0] align:#right
			button btn_saveColorScheme "SAVE..." width:74 align:#left offset:[-5,0] across:2
			button btn_loadColorScheme "LOAD..." width:74 align:#right offset:[5,0] 
		)
		
		fn setCurrentValueAsDefault =
		(
			local theIniFile = (theIniFileLocation + "MagmaFlowEditor_Preferences.ini")
			case currentPropertyForMenu of
			(
				#DepotNodeWidth: setIniSetting theIniFile "ParticleChannelEditor" "DepotNodeWidth" (spn_DepotNodeWidth.value as string)
				#NodeWidth: setIniSetting theIniFile "ParticleChannelEditor" "NodeWidth" (spn_nodeWidth.value as string)
				#NodeXSpace: setIniSetting theIniFile "ParticleChannelEditor" "NodeXSpace" (spn_NodeXSpace.value as string)
				#NodeYSpace: setIniSetting theIniFile "ParticleChannelEditor" "NodeYSpace" (spn_NodeYSpace.value as string)
				#GridXSpacing: setIniSetting theIniFile "ParticleChannelEditor" "GridXSpacing" (spn_GridXSpacing.value as string)
				#GridYSpacing: setIniSetting theIniFile "ParticleChannelEditor" "GridYSpacing" (spn_GridYSpacing.value as string)
				#ElbowSize: setIniSetting theIniFile "ParticleChannelEditor" "ElbowSize" (spn_ElbowSize.value as string) 
				#DrawShadows: setIniSetting theIniFile "ParticleChannelEditor" "DrawShadows" (chk_DrawShadows.state as string) 
				#TransparentCategories: setIniSetting theIniFile "ParticleChannelEditor" "TransparentCategories" (chk_transparentCategories.state as string)
			)
		)
		fn loadDefault =
		(
			local theIniFile = (theIniFileLocation + "MagmaFlowEditor_Preferences.ini")
			case currentPropertyForMenu of
			(
				#DepotNodeWidth: 
				(
					local theVal = execute (getIniSetting theIniFile "ParticleChannelEditor" "DepotNodeWidth" )
					MagmaFlowSettings.DepotNodeWidth = spn_DepotNodeWidth.value = if theVal != OK then theVal else 80
				)
				#NodeWidth: 
				(
					local theVal = execute (getIniSetting theIniFile "ParticleChannelEditor" "NodeWidth")
					MagmaFlowSettings.NodeWidth = spn_nodeWidth.value = if theVal != OK then theVal else 120
				)
				#ElbowSize: 
				(
					local theVal = execute (getIniSetting theIniFile "ParticleChannelEditor" "ElbowSize")
					MagmaFlowSettings.ElbowSize = spn_ElbowSize.value = if theVal != OK then theVal else 35
				) 
				
				#NodeXSpace: 
				(
					local theVal = execute (getIniSetting theIniFile "ParticleChannelEditor" "NodeXSpace" )
					MagmaFlowSettings.NodeXSpace = spn_NodeXSpace.value = if theVal != OK then theVal else 20
				)
				#NodeYSpace: 
				(
					local theVal = execute (getIniSetting theIniFile "ParticleChannelEditor" "NodeYSpace" )
					MagmaFlowSettings.NodeYSpace = spn_NodeYSpace.value = if theVal != OK then theVal else 20
				)
				#GridXSpacing: 
				(
					local theVal = execute (getIniSetting theIniFile "ParticleChannelEditor" "GridXSpacing" )
					MagmaFlowSettings.GridSizeX = spn_GridXSpacing.value = if theVal != OK then theVal else 10
				)
				#GridYSpacing: 
				(
					local theVal = execute (getIniSetting theIniFile "ParticleChannelEditor" "GridYSpacing" )
					MagmaFlowSettings.GridSizeY = spn_GridYSpacing.value = if theVal != OK then theVal else 10
				)
				#DrawShadows: 
				(
					local theVal = execute (getIniSetting theIniFile "ParticleChannelEditor" "DrawShadows" )
					MagmaFlowSettings.DrawShadows = chk_DrawShadows.state = theVal == True
				)			
				#TransparentCategories: 
				(
					local theVal = execute (getIniSetting theIniFile "ParticleChannelEditor" "TransparentCategories")
					MagmaFlowSettings.DepotCategoryTransparent = chk_transparentCategories.state = theVal != False
				)
				
			)		
			MagmaFlowEditor_Functions.storeSettingsInMagmaHolder magma MagmaFlowSettings
			MagmaFlowEditor_Rollout.showGrid MagmaFlowSettings.SnapToGrid
			MagmaFlowEditor_Rollout.hc.drawShadows = MagmaFlowSettings.DrawShadows
			MagmaFlowEditor_Rollout.createNodeTree init:true			
			MagmaFlowEditor_Rollout.autoReorderFlow createUndo:false
		)
		fn resetToFactoryDefault =
		(
			local theIniFile = (theIniFileLocation + "MagmaFlowEditor_Preferences.ini")
			case currentPropertyForMenu of
			(
				#DepotNodeWidth: setIniSetting theIniFile "ParticleChannelEditor" "DepotNodeWidth" ""
				#NodeWidth: setIniSetting theIniFile "ParticleChannelEditor" "NodeWidth" ""
				#ElbowSize: setIniSetting theIniFile "ParticleChannelEditor" "ElbowSize" ""
				#NodeXSpace: setIniSetting theIniFile "ParticleChannelEditor" "NodeXSpace" ""
				#NodeYSpace: setIniSetting theIniFile "ParticleChannelEditor" "NodeYSpace" ""
				#GridXSpacing: setIniSetting theIniFile "ParticleChannelEditor" "GridXSpacing" ""
				#GridYSpacing: setIniSetting theIniFile "ParticleChannelEditor" "GridYSpacing" ""
				#DrawShadows: setIniSetting theIniFile "ParticleChannelEditor" "DrawShadows" ""
				#TransparentCategories: setIniSetting theIniFile "ParticleChannelEditor" "TransparentCategories" ""
			)		
			loadDefault()
		)
		
		on btn_DepotNodeWidth pressed do
		(
			currentPropertyForMenu = #DepotNodeWidth
			popupmenu MagmaFlowEditor_OptionsRollout_Menu pos:mouse.screenpos
		)
		on btn_nodeWidth pressed do
		(
			currentPropertyForMenu = #nodeWidth
			popupmenu MagmaFlowEditor_OptionsRollout_Menu pos:mouse.screenpos
		)		
		on btn_ElbowSize pressed do
		(
			currentPropertyForMenu = #elbowSize
			popupmenu MagmaFlowEditor_OptionsRollout_Menu pos:mouse.screenpos
		)		
		on btn_NodeXSpace pressed do
		(
			currentPropertyForMenu = #NodeXSpace
			popupmenu MagmaFlowEditor_OptionsRollout_Menu pos:mouse.screenpos
		)		
		on btn_NodeYSpace pressed do
		(
			currentPropertyForMenu = #NodeYSpace
			popupmenu MagmaFlowEditor_OptionsRollout_Menu pos:mouse.screenpos
		)		
		on btn_ridXSpacing pressed do
		(
			currentPropertyForMenu = #GridXSpacing
			popupmenu MagmaFlowEditor_OptionsRollout_Menu pos:mouse.screenpos
		)		
		on btn_GridYSpacing pressed do
		(
			currentPropertyForMenu = #GridYSpacing
			popupmenu MagmaFlowEditor_OptionsRollout_Menu pos:mouse.screenpos
		)		
		on btn_DrawShadows pressed do
		(
			currentPropertyForMenu = #DrawShadows
			popupmenu MagmaFlowEditor_OptionsRollout_Menu pos:mouse.screenpos
		)		
		on btn_TransparentCategories pressed do
		(
			currentPropertyForMenu = #TransparentCategories
			popupmenu MagmaFlowEditor_OptionsRollout_Menu pos:mouse.screenpos
		)		
				
		
		on btn_DepotNodeWidth rightClick do
		(
			currentPropertyForMenu = #DepotNodeWidth
			popupmenu MagmaFlowEditor_OptionsRollout_Menu pos:mouse.screenpos
		)
		on btn_nodeWidth rightClick do
		(
			currentPropertyForMenu = #nodeWidth
			popupmenu MagmaFlowEditor_OptionsRollout_Menu pos:mouse.screenpos
		)		
		on btn_ElbowSize rightClick do
		(
			currentPropertyForMenu = #elbowSize
			popupmenu MagmaFlowEditor_OptionsRollout_Menu pos:mouse.screenpos
		)		
		on btn_NodeXSpace rightClick do
		(
			currentPropertyForMenu = #NodeXSpace
			popupmenu MagmaFlowEditor_OptionsRollout_Menu pos:mouse.screenpos
		)		
		on btn_NodeYSpace rightClick do
		(
			currentPropertyForMenu = #NodeYSpace
			popupmenu MagmaFlowEditor_OptionsRollout_Menu pos:mouse.screenpos
		)		
		on btn_ridXSpacing rightClick do
		(
			currentPropertyForMenu = #GridXSpacing
			popupmenu MagmaFlowEditor_OptionsRollout_Menu pos:mouse.screenpos
		)		
		on btn_GridYSpacing rightClick do
		(
			currentPropertyForMenu = #GridYSpacing
			popupmenu MagmaFlowEditor_OptionsRollout_Menu pos:mouse.screenpos
		)		
		on btn_DrawShadows rightClick do
		(
			currentPropertyForMenu = #DrawShadows
			popupmenu MagmaFlowEditor_OptionsRollout_Menu pos:mouse.screenpos
		)			
		on btn_TransparentCategories rightClick do
		(
			currentPropertyForMenu = #TransparentCategories
			popupmenu MagmaFlowEditor_OptionsRollout_Menu pos:mouse.screenpos
		)			
				
		on btn_resetColorScheme pressed do
		(
			if (querybox "Are you sure you want to RESET the\nMagmaFlow Editor's Color Scheme to Factory Defaults?\n\nThis operation CANNOT be undone!\nYou can click [No] and SAVE the Color Scheme first!" title:"Really RESET Colors?") do
			(
				deleteFile (theIniFileLocation + "MagmaFlowEditor_CurrentColorScheme.ini")
				::MagmaFlowColors = ::MagmaFlowColorsStruct()
				MagmaFlowEditor_Rollout.createNodeTree init:true
			)
		)
		on btn_saveColorScheme pressed do
		(
			makeDir (theUserFolder+"\\ColorSchemes\\") all:true
			local theFile = getSaveFileName filename:(theUserFolder+"\\ColorSchemes\\Colors") types:"MagmaFlow Color Scheme (*.MagmaFlowColors)|*.MagmaFlowColors"
			if theFile != undefined do 
			(
				MagmaFlowEditor_Functions.saveColorScheme theFile
			)
		)
		on btn_loadColorScheme pressed do
		(
			makeDir (theUserFolder+"\\ColorSchemes\\") all:true
			local theFile = getOpenFileName filename:(theUserFolder+"\\ColorSchemes\\*.MagmaFlowColors") types:"MagmaFlow Color Scheme (*.MagmaFlowColors)|*.MagmaFlowColors"
			if theFile != undefined do 
			(			
				MagmaFlowEditor_Functions.loadColorScheme theFile
				MagmaFlowEditor_Rollout.createNodeTree init:true
			)
		)		
		on btn_editColorScheme pressed do
		(
			global MagmaFlowEditor_CurrentColorScheme = ::MagmaFlowColors 
			local theRollout = MagmaFlowEditor_Functions.createColorOptionsDialog ::MagmaFlowColors
			createDialog theRollout width:240 modal:true
			if ::MagmaFlowEditor_CurrentColorScheme != undefined do 
			(
				::MagmaFlowColors = ::MagmaFlowEditor_CurrentColorScheme
				MagmaFlowEditor_Functions.saveColorScheme (theIniFileLocation + "MagmaFlowEditor_CurrentColorScheme.ini")
				MagmaFlowEditor_Rollout.showGrid MagmaFlowSettings.SnapToGrid
			)
			MagmaFlowEditor_Rollout.createNodeTree init:true
		)
		on spn_nodeWidth changed val do 
		(
			MagmaFlowSettings.NodeWidth = val
			MagmaFlowEditor_Rollout.createNodeTree init:true
			MagmaFlowEditor_Rollout.autoReorderFlow createUndo:false
			MagmaFlowEditor_Functions.storeSettingsInMagmaHolder magma MagmaFlowSettings
		)
		on spn_elbowSize changed val do 
		(
			MagmaFlowSettings.ElbowSize = val
			MagmaFlowEditor_Rollout.createNodeTree init:true
			MagmaFlowEditor_Rollout.autoReorderFlow createUndo:false
			MagmaFlowEditor_Functions.storeSettingsInMagmaHolder magma MagmaFlowSettings
		)		
		on spn_NodeXSpace changed val do 
		(
			MagmaFlowSettings.NodeXSpace = val
			MagmaFlowEditor_Rollout.createNodeTree init:true
			MagmaFlowEditor_Rollout.autoReorderFlow createUndo:false
			MagmaFlowEditor_Functions.storeSettingsInMagmaHolder magma MagmaFlowSettings
		)
		on spn_NodeYSpace changed val do 
		(
			MagmaFlowSettings.NodeYSpace = val
			MagmaFlowEditor_Rollout.createNodeTree init:true
			MagmaFlowEditor_Rollout.autoReorderFlow createUndo:false
			MagmaFlowEditor_Functions.storeSettingsInMagmaHolder magma MagmaFlowSettings
		)	
		on spn_GridXSpacing changed val do
		(
			MagmaFlowSettings.GridSizeX = val
			MagmaFlowEditor_Rollout.showGrid MagmaFlowSettings.SnapToGrid
			MagmaFlowEditor_Rollout.createNodeTree init:true
			MagmaFlowEditor_Rollout.autoReorderFlow createUndo:false
			MagmaFlowEditor_Functions.storeSettingsInMagmaHolder magma MagmaFlowSettings
		)
		on spn_GridYSpacing changed val do
		(
			MagmaFlowSettings.GridSizeY = val
			MagmaFlowEditor_Rollout.showGrid MagmaFlowSettings.SnapToGrid
			MagmaFlowEditor_Rollout.createNodeTree init:true
			MagmaFlowEditor_Rollout.autoReorderFlow createUndo:false
			MagmaFlowEditor_Functions.storeSettingsInMagmaHolder magma MagmaFlowSettings
		)
		
		on spn_DepotNodeWidth changed val do 
		(
			MagmaFlowSettings.DepotNodeWidth = val
			MagmaFlowEditor_Rollout.createDepot()
			MagmaFlowEditor_Rollout.updateDepotDefinition()
			MagmaFlowEditor_Rollout.createNodeTree init:true
			MagmaFlowEditor_Functions.storeSettingsInMagmaHolder magma MagmaFlowSettings
		)	

		on chk_drawShadows changed state do
		(
			MagmaFlowEditor_Rollout.hc.drawShadows = MagmaFlowSettings.DrawShadows = state
			MagmaFlowEditor_Rollout.hc.redrawView
			MagmaFlowEditor_Functions.storeSettingsInMagmaHolder magma MagmaFlowSettings
		)
		
		on chk_TransparentCategories changed state do
		(
			MagmaFlowSettings.DepotCategoryTransparent = state
			MagmaFlowEditor_Rollout.createDepot()
			MagmaFlowEditor_Rollout.updateDepotDefinition()			
			MagmaFlowEditor_Rollout.createNodeTree init:true
			MagmaFlowEditor_Functions.storeSettingsInMagmaHolder magma MagmaFlowSettings
		)
		
		on MagmaFlowEditor_OptionsRollout open do
		(
			try(btn_nodeWidth.images = #(Krakatoa_PresetsArrowBitmap,Krakatoa_PresetsArrowBitmap, 32,1,1,2,2))catch()
			try(btn_ElbowSize.images = #(Krakatoa_PresetsArrowBitmap,Krakatoa_PresetsArrowBitmap, 32,1,1,2,2))catch()
			try(btn_NodeXSpace.images = #(Krakatoa_PresetsArrowBitmap,Krakatoa_PresetsArrowBitmap, 32,1,1,2,2))catch()
			try(btn_NodeYSpace.images = #(Krakatoa_PresetsArrowBitmap,Krakatoa_PresetsArrowBitmap, 32,1,1,2,2))catch()
			try(btn_DepotNodeWidth.images = #(Krakatoa_PresetsArrowBitmap,Krakatoa_PresetsArrowBitmap, 32,1,1,2,2))catch()
			try(btn_ridXSpacing.images = #(Krakatoa_PresetsArrowBitmap,Krakatoa_PresetsArrowBitmap, 32,1,1,2,2))catch()
			try(btn_GridYSpacing.images = #(Krakatoa_PresetsArrowBitmap,Krakatoa_PresetsArrowBitmap, 32,1,1,2,2))catch()
			try(btn_DrawShadows.images = #(Krakatoa_PresetsArrowBitmap,Krakatoa_PresetsArrowBitmap, 32,1,1,2,2))catch()
			try(btn_TransparentCategories.images = #(Krakatoa_PresetsArrowBitmap,Krakatoa_PresetsArrowBitmap, 32,1,1,2,2))catch()
			
			spn_nodeWidth.value = MagmaFlowSettings.NodeWidth
			spn_elbowSize.value = MagmaFlowSettings.ElbowSize
			spn_NodeXSpace.value = MagmaFlowSettings.NodeXSpace
			spn_NodeYSpace.value = MagmaFlowSettings.NodeYSpace
			spn_DepotNodeWidth.value = MagmaFlowSettings.DepotNodeWidth
			spn_GridXSpacing.value  = MagmaFlowSettings.GridSizeX
			spn_GridYSpacing.value  = MagmaFlowSettings.GridSizeY
			chk_DrawShadows.state = MagmaFlowSettings.DrawShadows
			chk_TransparentCategories.state = MagmaFlowSettings.DepotCategoryTransparent
				
		)
	)
	
	
	rollout MagmaFlowEditor_CloseEditableBLOP "BLOP/LOOP" category:60
	(
		button btn_endBLOP "Exit Sub-Level Editing" width:160 align:#center height:30 offset:[0,-5]
		
		on btn_endBLOP pressed do
		(
			if (magma.NumEditingBLOPs() > 0) do
			(
				magma.PopEditableBLOP()
				deleteItem EditableBlopStack EditableBlopStack.count
				MagmaFlowEditor_Rollout.restorePanAndZoom()
				MagmaFlowEditor_Rollout.createNodeTree init:true
				MagmaFlowEditor_Rollout.updateEditorTitle()
				MagmaFlowEditor_Rollout.displaySelectedNodeProperties()
				MagmaFlowEditor_Rollout.updateNavigator fullUpdate:true
			)
		)
		
		on MagmaFlowEditor_CloseEditableBLOP open do
		(
			local theType = (magma.getNodeProperty EditableBlopStack[EditableBlopStack.count] "uiType")
			case (theType as name) of
			(
				#loop: (
					MagmaFlowEditor_CloseEditableBLOP.title = "LOOP"
					btn_endBLOP.text = "Exit LOOP Editing"
				)
				default: (
					MagmaFlowEditor_CloseEditableBLOP.title = "BLOP"
					btn_endBLOP.text = "Exit BLOP Editing"
				)
			)
		)
	)
	
	local MagmaFlowEditor_LOOP
	local MagmaFlowEditor_DefaultType = #input
	rcmenu MagmaFlowEditor_SetDefault_Menu 
	(
		menuItem mnu_DefaultFloat "FLOAT Default Value (0.0)"
		menuItem mnu_DefaultInt "INTEGER Default Value (0)"
		menuItem mnu_DefaultVector "VECTOR Default Value ([0.0,0.0,0.0])"
		menuItem mnu_DefaultQuat "QUAT Default Value ([0.0,0.0,0.0,0.0])"
		separator sep_01
		menuItem mnu_DefaultNone "NO Default Value - Connect To Define..."
		
		on mnu_DefaultFloat picked do MagmaFlowEditor_LOOP.setDefaultValue #float
		on mnu_DefaultInt picked do MagmaFlowEditor_LOOP.setDefaultValue #int
		on mnu_DefaultVector picked do MagmaFlowEditor_LOOP.setDefaultValue #vector
		on mnu_DefaultQuat picked do MagmaFlowEditor_LOOP.setDefaultValue #quat
		on mnu_DefaultNone picked do MagmaFlowEditor_LOOP.setDefaultValue #none
	)
	
	
	rollout MagmaFlowEditor_LOOP "LOOP" category:100
	(
		local inputSocketsMap = #()
		local modifiableInputs = #()
		local nonModifiableInputs = #()
		local theID = -1

		button btn_editLOOP "Edit LOOP Body..." width:160 align:#center height:30 offset:[0,-5]

		group "Node Controls"
		(
			checkbox chk_collapsed "Collapse" offset:[8,-5] align:#right
		)
		
		group "Input Sockets:"
		(
			button btn_addInput "Add" across:3 width:45 height:18 align:#left offset:[-7,-3] tooltip:"Add New Input" 
			button btn_removeInput "Remove" width:53 height:18 align:#center offset:[-6,-3] tooltip:"Remove Selected Input..."
			button btn_setDefault "Default>>" width:57 height:18 align:#right offset:[7,-3] tooltip:"Set Input Default - Show a Menu To Select Default Value Type..."
			
			listbox lbx_inputs height:5 width:156 align:#center offset:[0,-5]
			edittext edt_inputName fieldwidth:155 align:#center offset:[-3,-6]

			button btn_moveInputUp "Move Up" across:2 width:77 height:18 align:#left offset:[-7,-5] tooltip:"Move Socket Up"
			button btn_moveInputDown "Move Down"  width:77 height:18 align:#right offset:[7,-5] tooltip:"Move Socket Down"
		)
		
		label lbl_void02 offset:[0,-22]
		group "Output Sockets:"
		(
			button btn_addOutput "Add" across:3 width:45 height:18 align:#left offset:[-7,-3] tooltip:"Add New Output"
			button btn_removeOutput "Remove" width:53 height:18 align:#center offset:[-6,-3] tooltip:"Remove Selected Output..."
			button btn_setOutputDefault "Default>>" width:57 height:18 align:#right offset:[7,-3] tooltip:"Set Output Default  - Show a Menu To Select Default Value Type..."
			
			listbox lbx_outputs  height:5 width:156 align:#center offset:[0,-5]
			edittext edt_outputName fieldwidth:155 align:#center offset:[-3,-6]

			button btn_moveOutputUp "Move Up" across:2 width:77 height:18 align:#left offset:[-7,-5] tooltip:"Move Socket Up" 
			button btn_moveOutputDown "Move Down"  width:77 height:18 align:#right offset:[7,-5] tooltip:"Move Socket Down" 
		)		

		spinner spn_maxIterations "Max. Iterations:" range:[1,10000000,1] type:#integer fieldwidth:50 align:#right
		label lbl_searchMode "Search Mode:" align:#left visible:false across:2
		dropdownlist ddl_searchMode "" items:#("Radius","Count") fieldwidth:50 align:#right visible:false offset:[0,-3]
		checkbox chk_VisibleEdgesOnly "Visible Edges Only" visible:false offset:[0,-23]

		
		fn updateGUI =
		(
			chk_collapsed.state = (magma.getNodeProperty theID "Collapsed") == true
			
			lbl_searchMode.visible = ddl_searchMode.visible = findItem (magma.GetNodePropertyNames theID #internal) "searchMode" > 0
			ddl_searchMode.selection = findItem (magma.GetNodeEnumValues theID "searchMode") (magma.GetNodeProperty theID "searchMode")
			chk_VisibleEdgesOnly.visible = magma.GetNodeType theID == "VertexLoopByEdge"
		)
		
		on ddl_searchMode selected itm do
		(
			magma.SetNodeProperty theID "searchMode" ddl_searchMode.selected
			MagmaFlowEditor_Rollout.createNodeTree init:true
		)
		
		on btn_setDefault pressed do
		(
			MagmaFlowEditor_DefaultType = #input
			popupMenu MagmaFlowEditor_SetDefault_Menu pos:mouse.screenpos
		)
		on btn_setOutputDefault pressed do
		(
			MagmaFlowEditor_DefaultType = #output
			popupMenu MagmaFlowEditor_SetDefault_Menu pos:mouse.screenpos
		)
		

		fn updateControls =
		(
			
			spn_maxIterations.value = magma.getNodeProperty theID  "maxIterations"
			updateGUI()
		)
		
		on chk_collapsed changed state do
		(
			local theID = MagmaFlowEditor_Functions.getNodeID magma MagmaFlowEditor_Rollout.lastNodeClick
			magma.DeclareExtensionProperty theID "Collapsed" 
			local theState = magma.GetNodeProperty theID "Collapsed"  
			if theState == undefined do theState = false
			theState = not theState 			
			magma.setNodeProperty theID "Collapsed" theState
			MagmaFlowEditor_Rollout.collapseBranches()
			MagmaFlowEditor_Rollout.createNodeTree init:true
		)				
		
		on spn_maxIterations changed val do
		(
			magma.setNodeProperty theID "maxIterations" val 
			MagmaFlowEditor_Rollout.createUndoRecord ("Change LOOP [" + theID as string+"] Max. Iterations To "+val as string)
		)		
		
	

		fn updateLists =
		(
			local theID = MagmaFlowEditor_Functions.getNodeID magma MagmaFlowEditor_Rollout.lastNodeClick			
			local tempArray = #()
			inputSocketsMap = #()
			for i = 1 to magma.getNodeProperty theID "numInputs" do
			(
				local theSocketName = magma.getNodeProperty theID ("BLOPInputSocketName"+i as string)
				if theSocketName == undefined or theSocketName == "" do theSocketName = "Input " + i as string
				append tempArray theSocketName
				append inputSocketsMap i
			)
			lbx_inputs.items = tempArray
			
			lbx_inputs.selection = 1
			edt_inputName.text = if lbx_inputs.selected != undefined then lbx_inputs.selected else ""
			lbx_outputs.items = for i = 1 to magma.getNodeProperty theID "numOutputs" collect
			(
				local theSocketName = magma.getNodeProperty theID ("BLOPOutputSocketName" + i as string)
				if theSocketName == undefined or theSocketName == "" do theSocketName = "Accumulator " + i as string
				theSocketName
			)		
			lbx_outputs.selection = 1
			edt_outputName.text = if lbx_outputs.selected != undefined then lbx_outputs.selected else ""
				
			chk_collapsed.state = (magma.getNodeProperty theID "Collapsed") == true
		)

		on lbx_inputs selected itm do 
		(
			if inputSocketsMap[itm] == -1 then
			(
				edt_inputName.enabled = false
				edt_inputName.text = ""
			)
			else
			(
				edt_inputName.enabled = true
				edt_inputName.text = lbx_inputs.selected
			)
		)
		on lbx_outputs selected itm do edt_outputName.text = lbx_outputs.selected
			
		on edt_inputName entered txt do 
		(
			if lbx_inputs.selection > 0 do
			(
				local theID = MagmaFlowEditor_Functions.getNodeID magma MagmaFlowEditor_Rollout.lastNodeClick
				local theName = ("BLOPInputSocketName" + inputSocketsMap[lbx_inputs.selection] as string)
				magma.declareExtensionProperty theID theName 
				magma.setNodeProperty theID theName txt
				local temp = lbx_inputs.items
				temp[lbx_inputs.selection]=txt
				lbx_inputs.items = temp
				MagmaFlowEditor_Rollout.createNodeTree init:false
			)
		)
		on edt_outputName entered txt do 
		(
			if lbx_outputs.selection > 0 do
			(
				local theID = MagmaFlowEditor_Functions.getNodeID magma MagmaFlowEditor_Rollout.lastNodeClick
				local theName = ("BLOPOutputSocketName" + lbx_outputs.selection as string)
				magma.declareExtensionProperty theID theName 
				magma.setNodeProperty theID theName txt
				local temp = lbx_outputs.items
				temp[lbx_outputs.selection]=txt
				lbx_outputs.items= temp
				MagmaFlowEditor_Rollout.createNodeTree init:false
			)
		)		
		
		on btn_addInput pressed do
		(
			local theID = MagmaFlowEditor_Functions.getNodeID magma MagmaFlowEditor_Rollout.lastNodeClick
			local newCount = ((magma.getNodeProperty theID "numInputs")+1)
			magma.setNodeProperty theID "numInputs" newCount
			local theName = ("BLOPInputSocketName" + newCount as string)
			magma.declareExtensionProperty theID theName 
			magma.setNodeProperty theID theName ("Input "+ newCount as string)
			MagmaFlowEditor_Rollout.createNodeTree init:true
			updateLists()
			lbx_inputs.selection = lbx_inputs.items.count
		)
		
		fn setDefaultValue mode =
		(
			local theID = MagmaFlowEditor_Functions.getNodeID magma MagmaFlowEditor_Rollout.lastNodeClick
			local fixedInputs = magma.getNumNodeInputs theID - magma.getNodeProperty theID "numInputs" - magma.getNodeProperty theID "numOutputs"
			local oldSelection = lbx_inputs.selection 
			local theSocket = lbx_inputs.selection + fixedInputs
			
			if MagmaFlowEditor_DefaultType  == #output do 
			(
				oldSelection = lbx_outputs.selection 
				theSocket = fixedInputs + magma.getNodeProperty theID "numInputs" + lbx_outputs.selection 
			)
			if theSocket > 0 do
			(
				case mode of
				(
					default: magma.setNodeInputDefaultValue theID theSocket 0.0
					#int: magma.setNodeInputDefaultValue theID theSocket 0
					#vector: magma.setNodeInputDefaultValue theID theSocket [0.0,0.0,0.0]
					#quat: magma.setNodeInputDefaultValue theID theSocket (quat 0.0 0.0 0.0 0.0)
					#none: magma.setNodeInputDefaultValue theID theSocket undefined
				)
				MagmaFlowEditor_Rollout.createNodeTree init:true
				MagmaFlowEditor_Rollout.displaySelectedNodeProperties()
				if MagmaFlowEditor_DefaultType  == #output then
					lbx_outputs.selection = oldSelection
				else
					lbx_inputs.selection = oldSelection
			)
		)
		
		on btn_removeInput pressed do
		(
			local q = querybox "Are you sure you want to REMOVE the selected Input socket?" title:"Remove Input Socket?"
			if q then 
			(
				local oldSelection = lbx_inputs.selection
				local theID = MagmaFlowEditor_Functions.getNodeID magma MagmaFlowEditor_Rollout.lastNodeClick

				local socketToDelete = inputSocketsMap[lbx_inputs.selection]
				local numSockets = magma.getNumNodeInputs theID 
				magma.pushEditableBLOP theID
				
				for theID2 in Magma.GetNodes() do
				(
					for c = 1 to magma.getNumNodeInputs theID2 do
					(
						local oldWire = magma.getNodeInput theID2 c
						if oldWire[1] == (magma.GetNodeInput (magma.CurrentBLOP) socketToDelete)[1] and oldWire[2] == socketToDelete do 
							magma.setNodeInput theID2 c -1 1 --remove wire
						for j = socketToDelete+1 to numSockets do
							if oldWire[1] == (magma.GetNodeInput (magma.CurrentBLOP) j)[1] and oldWire[2] == j do 
								magma.setNodeInput theID2 c (magma.GetNodeInput (magma.CurrentBLOP) (j-1))[1] (j-1) --move all others up --magma.CurrentBLOP
					)--end c loop
				)--end i loop
				magma.popEditableBLOP()
				for j = socketToDelete+1 to numSockets do
				(
					local theSocketName = magma.getNodeProperty theID ("BLOPInputSocketName"+j as string)
					if theSocketName != undefined do 
					(
						magma.declareExtensionProperty theID ("BLOPInputSocketName"+(j-1) as string)
						magma.setNodeProperty theID ("BLOPInputSocketName"+(j-1) as string) theSocketName
					)
				)
				magma.setNodeProperty theID "numInputs" ((magma.getNodeProperty theID "numInputs")-1)
				MagmaFlowEditor_Rollout.createNodeTree init:true
				updateLists()
				lbx_inputs.selection = lbx_inputs.items.count			
			)
		)
		
		fn moveSocket theID oldSelection dir:-1 =
		(
			local currentSocket = inputSocketsMap[oldSelection]
			local otherSocket = inputSocketsMap[oldSelection+dir]
			local tempName1 = magma.getNodeProperty theID ("BLOPInputSocketName"+currentSocket as string)
			local tempName2 = magma.getNodeProperty theID ("BLOPInputSocketName"+otherSocket as string)
			
			magma.DeclareExtensionProperty theID ("BLOPInputSocketName"+otherSocket as string) 
			magma.setNodeProperty theID ("BLOPInputSocketName"+otherSocket as string) tempName1 
			magma.DeclareExtensionProperty theID ("BLOPInputSocketName"+currentSocket as string) 
			magma.setNodeProperty theID ("BLOPInputSocketName"+currentSocket as string) tempName2

			magma.pushEditableBLOP theID
			
			for theID2 in Magma.GetNodes() do
			(
				for c = 1 to magma.getNumNodeInputs theID2 do
				(
					local oldWire = magma.getNodeInput theID2 c
					if oldWire[1] == (magma.GetNodeInput (magma.CurrentBLOP) currentSocket)[1] and oldWire[2] == currentSocket+1 then 
						magma.setNodeInput theID2 c (magma.GetNodeInput (magma.CurrentBLOP) (otherSocket+1))[1] (otherSocket+1)  
					else
						if oldWire[1] == (magma.GetNodeInput (magma.CurrentBLOP) otherSocket)[1] and oldWire[2] == otherSocket+1 then
							magma.setNodeInput theID2 c (magma.GetNodeInput (magma.CurrentBLOP) (currentSocket+1))[1] (currentSocket+1)  
				)--end c loop
			)--end i loop
			magma.popEditableBLOP()

			local tempSocket1 = magma.getNodeInput theID currentSocket
			local tempSocket2 = magma.getNodeInput theID otherSocket
			magma.setNodeInput theID otherSocket tempSocket1[1] tempSocket1[2]
			magma.setNodeInput theID currentSocket tempSocket2[1] tempSocket2[2]
			
			
			MagmaFlowEditor_Rollout.createNodeTree init:true
			updateLists()
		)
		
		fn moveOutputSocket theID oldSelection dir:-1 =
		(
			local tempName1 = magma.getNodeProperty theID ("BLOPOutputSocketName"+oldSelection as string)
			local tempName2 = magma.getNodeProperty theID ("BLOPOutputSocketName"+(oldSelection+dir) as string)
			magma.DeclareExtensionProperty theID ("BLOPOutputSocketName"+(oldSelection+dir) as string) 
			magma.setNodeProperty theID ("BLOPOutputSocketName"+(oldSelection+dir) as string) tempName1 
			magma.DeclareExtensionProperty theID ("BLOPOutputSocketName"+oldSelection as string) 
			magma.setNodeProperty theID ("BLOPOutputSocketName"+oldSelection as string) tempName2
			
			local theOffset = 0
			if magma.getNodeType theID == "Loop" do theOffset = 1
			magma.pushEditableBLOP theID
			local out1 = magma.GetOutput (oldSelection+theOffset)
			local out2 = magma.GetOutput (oldSelection+dir+theOffset)
			magma.setOutput (oldSelection+dir+theOffset) out1[1] out1[2]
			magma.setOutput (oldSelection+theOffset) out2[1] out2[2]
			magma.popEditableBLOP()
			updateLists()			
		)
		
		on btn_moveInputUp pressed do
		(
			local oldSelection = lbx_inputs.selection
			local theID = MagmaFlowEditor_Functions.getNodeID magma MagmaFlowEditor_Rollout.lastNodeClick
			if lbx_inputs.selection > 1 do
			(
				if inputSocketsMap[oldSelection-1] < 0 then
				(
					moveSeparator theID (oldSelection-1) dir:1
					lbx_inputs.selection = oldSelection-1 
				)
				else
				(
					moveSocket theID oldSelection dir:-1
					lbx_inputs.selection = oldSelection-1 
				)
			)
			MagmaFlowEditor_Rollout.createNodeTree init:false
		)
		on btn_moveInputDown pressed do
		(
			local oldSelection = lbx_inputs.selection
			local theID = MagmaFlowEditor_Functions.getNodeID magma MagmaFlowEditor_Rollout.lastNodeClick
			if lbx_inputs.selection < lbx_inputs.items.count do
			(
				if inputSocketsMap[oldSelection+1] < 0 then
				(
					moveSeparator theID (oldSelection+1) dir:-1
					lbx_inputs.selection = oldSelection+1 
				)
				else
				(
					moveSocket theID oldSelection dir:1
					lbx_inputs.selection = oldSelection+1 
				)
			)
			MagmaFlowEditor_Rollout.createNodeTree init:false
		)		
		
		on btn_moveOutputUp pressed do
		(
			local oldSelection = lbx_outputs.selection
			local theID = MagmaFlowEditor_Functions.getNodeID magma MagmaFlowEditor_Rollout.lastNodeClick
			if lbx_outputs.selection > 1 do
			(
				moveOutputSocket theID oldSelection dir:-1
				lbx_outputs.selection = oldSelection-1 
				magma.popEditableBLOP()
				MagmaFlowEditor_Rollout.createNodeTree init:false
			)
		)
		on btn_moveOutputDown pressed do
		(
			local oldSelection = lbx_outputs.selection
			local theID = MagmaFlowEditor_Functions.getNodeID magma MagmaFlowEditor_Rollout.lastNodeClick
			if lbx_outputs.selection <  lbx_outputs.items.count do
			(
				moveOutputSocket theID oldSelection dir:1
				lbx_outputs.selection = oldSelection+1 
				magma.popEditableBLOP()
				MagmaFlowEditor_Rollout.createNodeTree init:false
			)
		)	
		
		on btn_addOutput pressed do
		(
			local theID = MagmaFlowEditor_Functions.getNodeID magma MagmaFlowEditor_Rollout.lastNodeClick
			local newCount = ((magma.getNodeProperty theID "numOutputs")+1)
			magma.setNodeProperty theID "numOutputs" newCount
			local theName = ("BLOPOutputSocketName" + newCount as string)
			magma.declareExtensionProperty theID theName 
			magma.setNodeProperty theID theName ("Accumulator "+ newCount as string)
			MagmaFlowEditor_Rollout.createNodeTree init:true
			updateLists()
			lbx_outputs.selection = lbx_outputs.items.count
		)		
		
		on btn_removeOutput pressed do
		(
			local q = querybox "Are you sure you want to REMOVE the selected Output socket?" title:"Remove Output Socket?"
			if q then 
			(			
				local theID = MagmaFlowEditor_Functions.getNodeID magma MagmaFlowEditor_Rollout.lastNodeClick
				magma.setNodeProperty theID "numOutputs" ((magma.getNodeProperty theID "numOutputs")-1)
				MagmaFlowEditor_Rollout.createNodeTree init:true
				updateLists()
				lbx_outputs.selection = lbx_outputs.items.count		
			)
		)				
		
		
		
		on btn_editLOOP pressed do
		(
			append EditableBlopStack theID
			magma.PushEditableBLOP theID 
			MagmaFlowEditor_Rollout.restorePanAndZoom()
			MagmaFlowEditor_Rollout.createNodeTree init:true
			MagmaFlowEditor_Rollout.displaySelectedNodeProperties()
			MagmaFlowEditor_Rollout.updateNavigator fullUpdate:true
			MagmaFlowEditor_Rollout.createUndoRecord ("Edit LOOP [" + theID as string+"]")
			MagmaFlowEditor_Rollout.createNodeTree init:false
			MagmaFlowEditor_Rollout.autoReorderFlow()			
		)		
		
		fn RolloutOpen =
		(
			theID = MagmaFlowEditor_Functions.getNodeID magma MagmaFlowEditor_Rollout.lastNodeClick
			updateLists()
			updateControls()
			MagmaFlowEditor_LOOP.title = magma.getNodeType theID
		)
		on MagmaFlowEditor_LOOP open do
		(
			RolloutOpen()
		)
	)
	
	rollout MagmaFlowEditor_EditableBLOP "BLOP" category:100
	(
		local inputSocketsMap = #()
		button btn_editBLOP "Edit BLOP..." width:160 align:#center height:30 offset:[0,-5]

		button btn_loadBLOP "LOAD BLOP..." width:80  align:#left across:2 height:25 offset:[-10,-3]
		button btn_saveBLOP "SAVE BLOP..." width:80 align:#right height:25 offset:[10,-3]
		
		button btn_exploreBLOPs "Explore BLOP Folder..." width:160 align:#center offset:[0,-3]
		
		label lbl_void01 offset:[0,-22]
		group "Input Sockets:"
		(
			button btn_addInput "Add" across:3 width:50 height:18 align:#left offset:[-7,-3] tooltip:"Add New Input" 
			button btn_addInputSeparator "Separator"  width:55 height:18 align:#center offset:[0,-3] tooltip:"Insert Separator after the selected Input"
			button btn_removeInput "Remove" width:50 height:18 align:#right offset:[7,-3] tooltip:"Remove Input"
			
			listbox lbx_inputs height:6 width:156 align:#center offset:[0,-5]
			edittext edt_inputName fieldwidth:155 align:#center offset:[-3,-6]

			button btn_moveInputUp "Move Up" across:2 width:77 height:18 align:#left offset:[-7,-5] tooltip:"Move Socket Up"
			button btn_moveInputDown "Move Down"  width:77 height:18 align:#right offset:[7,-5] tooltip:"Move Socket Down"
		)
		label lbl_void02 offset:[0,-22]
		group "Output Sockets:"
		(
			button btn_addOutput "Add" across:2 width:77 height:18 align:#left offset:[-7,-3] tooltip:"Add New Output"
			--button btn_addOutputSeparator "Separator"  width:55 height:18 align:#center offset:[0,-3] tooltip:"Insert Separator after the selected Output" enabled:false
			button btn_removeOutput "Remove" width:77 height:18 align:#right offset:[7,-3] tooltip:"Remove Output"
			
			listbox lbx_outputs  height:4 width:156 align:#center offset:[0,-5]
			edittext edt_outputName fieldwidth:155 align:#center offset:[-3,-6]

			button btn_moveOutputUp "Move Up" across:2 width:77 height:18 align:#left offset:[-7,-5] tooltip:"Move Socket Up" 
			button btn_moveOutputDown "Move Down"  width:77 height:18 align:#right offset:[7,-5] tooltip:"Move Socket Down" 
		)
		
		fn updateLists =
		(
			local theID = MagmaFlowEditor_Functions.getNodeID magma MagmaFlowEditor_Rollout.lastNodeClick			
					
			local separatorLocations = magma.getNodeProperty theID "InputSocketSeparators" 
			if separatorLocations == undefined then separatorLocations = #()
			local tempArray = #()
			inputSocketsMap = #()
			for i = 1 to magma.getNumNodeInputs theID do
			(
				local theSocketName = magma.getNodeProperty theID ("BLOPInputSocketName"+i as string)
				if theSocketName == undefined or theSocketName == "" do theSocketName = "Input " + i as string
				append tempArray theSocketName
				append inputSocketsMap i
				if findItem separatorLocations i > 0 do 
				(
					append inputSocketsMap -i
					append tempArray "-------------------------------------"
				)
			)
			lbx_inputs.items = tempArray
			
			lbx_inputs.selection = 1
			edt_inputName.text = if lbx_inputs.selected != undefined then lbx_inputs.selected else ""
			lbx_outputs.items = for i = 1 to magma.getNumNodeOutputs theID collect
			(
				local theSocketName = magma.getNodeProperty theID ("BLOPOutputSocketName" + i as string)
				if theSocketName == undefined or theSocketName == "" do theSocketName = "Output " + i as string
				theSocketName
			)		
			lbx_outputs.selection = 1
			edt_outputName.text = if lbx_outputs.selected != undefined then lbx_outputs.selected else ""
		)
		
		on btn_saveBLOP pressed do
		(
			local theBLOPName = "Definition"
			local theSel = MagmaFlowEditor_Rollout.getSelectedNodes()
			if theSel.count == 1 do 
			(
				local lastID = MagmaFlowEditor_Functions.getNodeID magma theSel[theSel.count]
				if lastID > -1 do
				(
					local lastName = magma.getNodeProperty lastID "Name"
					if lastName != undefined and lastName  != "" do theBLOPName = lastName
				)
			)
			makeDir (theUserFolder+ "\\BlackOps\\") all:true
			local theFileName = getSaveFileName filename:(theUserFolder+ "\\BlackOps\\"+theBLOPName+".MagmaBLOP") types:"MagmaFlow BLOP (*.MagmaBLOP)|*.MagmaBLOP"
			if theFileName != undefined do
			(
				local theFile = createFile theFileName
				local theString = MagmaFlowEditor_Functions.emitMAXScriptCode magma specificNodes:#(MagmaFlowEditor_Rollout.lastNodeClick) isUndo:false isBlop:true
				format "%\n" theString to:theFile
				close theFile
				MagmaFlowEditor_Rollout.createDepot()
			)
		)
		
		on btn_exploreBLOPs pressed do
		(
			makeDir (theUserFolder+ "\\BlackOps\\") all:true
			shellLaunch (theUserFolder+ "\\BlackOps\\") ""
		)
		
		on btn_loadBLOP pressed do
		(
			makeDir (theUserFolder+ "\\BlackOps\\") all:true
			local theFileName = getOpenFileName filename:(theUserFolder+ "\\BlackOps\\*.MagmaBLOP") types:"Magma 2.x BLOP (*.MagmaBLOP)|*.MagmaBLOP|Magma 1.x BLOP (*.KCB)|*.KCB"
			if theFileName != undefined do
			(
				local oldID = MagmaFlowEditor_Functions.getNodeID magma MagmaFlowEditor_Rollout.lastNodeClick
				local oldPos = magma.getNodeProperty oldID "Position"
				
				local extendedProps = magma.GetNodePropertyNames oldID #custom
				
				local oldPropValues = for i in extendedProps collect magma.getNodeProperty oldID i
				local oldInputs = for i = 1 to magma.getNumNodeInputs oldID collect magma.getNodeInput oldID i
				
				local oldCount = (Magma.GetNodes()).count
				::magmaNode = magma
				
				if matchPattern (getFileNameType theFileName) pattern:".MagmaBLOP" then
				(
					local oldNotes = magma.note
					magma.Loading = true
					fileIn theFileName
					magma.Loading = false
					magma.note = oldNotes 
				)
				
				if matchPattern (getFileNameType theFileName) pattern:".KCB" then
				(
					global KrakatoaChannelEditor_BlackOpData
					fileIn theFileName
					local theNodesList = #()
					local theNodeDef = #("BlackOP",#(),#(getFileNameFile theFileName, KrakatoaChannelEditor_BlackOpData),#([0,0]))
					theNodesList[1] = MagmaFlowEditor_Functions.convertKMFBLOP magma theNodesList theNodeDef
					for c = 1 to theNodeDef[2].count where theNodeDef[2][c] != undefined and theNodeDef[2][c] > 0 do
					(
						local connectToNode = theNodesList[theNodeDef[2][c]]
						local OutputConnection = magma.getNodeProperty connectToNode "Internal_OutputSelection"
						if OutputConnection == undefined do OutputConnection = 1
						magma.SetNodeInput theNodesList[i][1] c connectToNode OutputConnection
					)
					MagmaFlowEditor_Functions.connectKMFBLOP magma theNodesList[1] theNodeDef 					
				)					
				
				local newID = MagmaFlowEditor_Functions.getNodeID magma #last
				magma.replaceNode 	oldID newID 
				magma.setNodeProperty oldID "Position" oldPos
				MagmaFlowEditor_Rollout.lastNodeClick = findItem (magma.getNodes()) oldID
					
				for i = 1 to extendedProps.count where extendedProps[i] != "InputSocketSeparators" and not matchPattern  extendedProps[i] pattern:"BLOPInputSocketName*" do 
				(
					magma.DeclareExtensionProperty oldID extendedProps[i]
					magma.setNodeProperty oldID extendedProps[i] oldPropValues[i] 
				)
				for i = 1 to magma.getNumNodeInputs oldID do
				(
					if oldInputs[i] != undefined do magma.setNodeInput oldID i oldInputs[i][1] oldInputs[i][2]
				)

				magma.declareExtensionProperty oldID "Name" 
				magma.setNodeProperty oldID "Name" (getFileNameFile theFileName)
				
				MagmaFlowEditor_Rollout.createNodeTree init:true
				updateLists()	
				MagmaFlowEditor_NodeNameRollout.RolloutOpen()
			)
		)		
		

		
		on lbx_inputs selected itm do 
		(
			if inputSocketsMap[itm] == -1 then
			(
				edt_inputName.enabled = false
				edt_inputName.text = ""
			)
			else
			(
				edt_inputName.enabled = true
				edt_inputName.text = lbx_inputs.selected
			)
		)
		on lbx_outputs selected itm do edt_outputName.text = lbx_outputs.selected
			
		on edt_inputName entered txt do 
		(
			if lbx_inputs.selection > 0 do
			(
				local theID = MagmaFlowEditor_Functions.getNodeID magma MagmaFlowEditor_Rollout.lastNodeClick
				local theName = ("BLOPInputSocketName" + inputSocketsMap[lbx_inputs.selection] as string)
				magma.declareExtensionProperty theID theName 
				magma.setNodeProperty theID theName txt
				local temp = lbx_inputs.items
				temp[lbx_inputs.selection]=txt
				lbx_inputs.items = temp
				MagmaFlowEditor_Rollout.createNodeTree init:false
			)
		)
		on edt_outputName entered txt do 
		(
			if lbx_outputs.selection > 0 do
			(
				local theID = MagmaFlowEditor_Functions.getNodeID magma MagmaFlowEditor_Rollout.lastNodeClick
				local theName = ("BLOPOutputSocketName" + lbx_outputs.selection as string)
				magma.declareExtensionProperty theID theName 
				magma.setNodeProperty theID theName txt
				local temp = lbx_outputs.items
				temp[lbx_outputs.selection]=txt
				lbx_outputs.items= temp
				MagmaFlowEditor_Rollout.createNodeTree init:false
			)
		)		
		
		on btn_addInput pressed do
		(
			local theID = MagmaFlowEditor_Functions.getNodeID magma MagmaFlowEditor_Rollout.lastNodeClick
			magma.setNumNodeInputs theID ((magma.getNumNodeInputs theID)+1)
			MagmaFlowEditor_Rollout.createNodeTree init:true
			updateLists()
			lbx_inputs.selection = lbx_inputs.items.count
		)
		
		on btn_addInputSeparator pressed do
		(
			local oldSelection = lbx_inputs.selection
			if inputSocketsMap[lbx_inputs.selection] > 0 do
			(
				local theID = MagmaFlowEditor_Functions.getNodeID magma MagmaFlowEditor_Rollout.lastNodeClick
				local separatorLocations = magma.getNodeProperty theID "InputSocketSeparators" 
				if separatorLocations == undefined then separatorLocations = #()
				if findItem separatorLocations inputSocketsMap[lbx_inputs.selection] == 0 do
				(
					append separatorLocations inputSocketsMap[lbx_inputs.selection]
					magma.declareExtensionProperty theID "InputSocketSeparators"
					magma.setNodeProperty theID "InputSocketSeparators" separatorLocations
					MagmaFlowEditor_Rollout.createNodeTree init:false
					updateLists()
					lbx_inputs.selection = oldSelection+1
				)
			)
		)		
		
		on btn_removeInput pressed do
		(
			local oldSelection = lbx_inputs.selection
			local theID = MagmaFlowEditor_Functions.getNodeID magma MagmaFlowEditor_Rollout.lastNodeClick
			if inputSocketsMap[lbx_inputs.selection] < 0 then
			(
				local separatorLocations = magma.getNodeProperty theID "InputSocketSeparators" 
				deleteItem separatorLocations (findItem separatorLocations (abs inputSocketsMap[lbx_inputs.selection]))
				magma.setNodeProperty theID "InputSocketSeparators" separatorLocations
				MagmaFlowEditor_Rollout.createNodeTree init:false
				updateLists()
				lbx_inputs.selection = oldSelection-1
			)
			else
			(
				local socketToDelete = inputSocketsMap[lbx_inputs.selection]
				local numSockets = magma.getNumNodeInputs theID 
				magma.pushEditableBLOP theID
				
				for theID2 in Magma.GetNodes() do
				(
					for c = 1 to magma.getNumNodeInputs theID2 do
					(
						local oldWire = magma.getNodeInput theID2 c
						if oldWire[1] == (magma.GetNodeInput (magma.CurrentBLOP) socketToDelete)[1] and oldWire[2] == socketToDelete do 
							magma.setNodeInput theID2 c -1 1 --remove wire
						for j = socketToDelete+1 to numSockets do
							if oldWire[1] == (magma.GetNodeInput (magma.CurrentBLOP) j)[1] and oldWire[2] == j do 
								magma.setNodeInput theID2 c (magma.GetNodeInput (magma.CurrentBLOP) (j-1))[1] (j-1) --move all others up --magma.CurrentBLOP
					)--end c loop
				)--end i loop
				magma.popEditableBLOP()
				for j = socketToDelete+1 to numSockets do
				(
					local theSocketName = magma.getNodeProperty theID ("BLOPInputSocketName"+j as string)
					if theSocketName != undefined do 
					(
						magma.declareExtensionProperty theID ("BLOPInputSocketName"+(j-1) as string)
						magma.setNodeProperty theID ("BLOPInputSocketName"+(j-1) as string) theSocketName
					)
				)
				magma.setNumNodeInputs theID (numSockets-1)
				MagmaFlowEditor_Rollout.createNodeTree init:true
				updateLists()
				lbx_inputs.selection = lbx_inputs.items.count			
			)
		)
		
		fn moveSeparator theID oldSelection dir:-1 =
		(
			local separatorLocations = magma.getNodeProperty theID "InputSocketSeparators" 
			if (dir == -1 and (abs inputSocketsMap[oldSelection]) > 1) OR (dir == 1 and (abs inputSocketsMap[oldSelection]) < magma.getNumNodeInputs theID ) do 
			(
				deleteItem separatorLocations (findItem separatorLocations (abs inputSocketsMap[oldSelection]))
				append separatorLocations ( (abs inputSocketsMap[oldSelection]) + dir )
				separatorLocations = for j in separatorLocations where j > 0 collect j
				magma.setNodeProperty theID "InputSocketSeparators" (sort separatorLocations)
				MagmaFlowEditor_Rollout.createNodeTree init:false
				updateLists()
				lbx_inputs.selection = oldSelection + dir 
			)
		)
		
		fn moveSocket theID oldSelection dir:-1 =
		(
			local currentSocket = inputSocketsMap[oldSelection]
			local otherSocket = inputSocketsMap[oldSelection+dir]
			local tempName1 = magma.getNodeProperty theID ("BLOPInputSocketName"+currentSocket as string)
			local tempName2 = magma.getNodeProperty theID ("BLOPInputSocketName"+otherSocket as string)
			
			magma.DeclareExtensionProperty theID ("BLOPInputSocketName"+otherSocket as string) 
			magma.setNodeProperty theID ("BLOPInputSocketName"+otherSocket as string) tempName1 
			magma.DeclareExtensionProperty theID ("BLOPInputSocketName"+currentSocket as string) 
			magma.setNodeProperty theID ("BLOPInputSocketName"+currentSocket as string) tempName2

			magma.pushEditableBLOP theID
			
			for theID2 in  Magma.GetNodes() do
			(
				for c = 1 to magma.getNumNodeInputs theID2 do
				(
					local oldWire = magma.getNodeInput theID2 c
					if oldWire[1] == (magma.GetNodeInput (magma.CurrentBLOP) currentSocket)[1] and oldWire[2] == currentSocket then 
						magma.setNodeInput theID2 c (magma.GetNodeInput (magma.CurrentBLOP) (otherSocket))[1] (otherSocket)  
					else
						if oldWire[1] == (magma.GetNodeInput (magma.CurrentBLOP) otherSocket)[1] and oldWire[2] == otherSocket then
							magma.setNodeInput theID2 c (magma.GetNodeInput (magma.CurrentBLOP) (currentSocket))[1] (currentSocket)  
				)--end c loop
			)--end i loop
			magma.popEditableBLOP()
			updateLists()
		)
		
		fn moveOutputSocket theID oldSelection dir:-1 =
		(
			local tempName1 = magma.getNodeProperty theID ("BLOPOutputSocketName"+oldSelection as string)
			local tempName2 = magma.getNodeProperty theID ("BLOPOutputSocketName"+(oldSelection+dir) as string)
			--if tempName1 != undefined do
			(
				magma.DeclareExtensionProperty theID ("BLOPOutputSocketName"+(oldSelection+dir) as string) 
				magma.setNodeProperty theID ("BLOPOutputSocketName"+(oldSelection+dir) as string) tempName1 
			)
			--if tempName2 != undefined do
			(
				magma.DeclareExtensionProperty theID ("BLOPOutputSocketName"+oldSelection as string) 
				magma.setNodeProperty theID ("BLOPOutputSocketName"+oldSelection as string) tempName2
			)
			
			magma.pushEditableBLOP theID
			local out1 = magma.GetOutput oldSelection
			local out2 = magma.GetOutput (oldSelection+dir)
			magma.setOutput (oldSelection+dir) out1[1] out1[2]
			magma.setOutput (oldSelection) out2[1] out2[2]
			magma.popEditableBLOP()
			updateLists()			
		)
		
		on btn_moveInputUp pressed do
		(
			local oldSelection = lbx_inputs.selection
			local theID = MagmaFlowEditor_Functions.getNodeID magma MagmaFlowEditor_Rollout.lastNodeClick
			if inputSocketsMap[lbx_inputs.selection] < 0 then
			(
				moveSeparator theID oldSelection dir:-1
			)
			else
			(
				if lbx_inputs.selection > 1 do
				(
					if inputSocketsMap[oldSelection-1] < 0 then
					(
						moveSeparator theID (oldSelection-1) dir:1
						lbx_inputs.selection = oldSelection-1 
					)
					else
					(
						moveSocket theID oldSelection dir:-1
						lbx_inputs.selection = oldSelection-1 
					)
				)
			)
			MagmaFlowEditor_Rollout.createNodeTree init:false
		)
		on btn_moveInputDown pressed do
		(
			local oldSelection = lbx_inputs.selection
			local theID = MagmaFlowEditor_Functions.getNodeID magma MagmaFlowEditor_Rollout.lastNodeClick
			if inputSocketsMap[lbx_inputs.selection] < 0 then
			(
				moveSeparator theID oldSelection dir:1
			)			
			else
			(
				if lbx_inputs.selection < lbx_inputs.items.count do
				(
					if inputSocketsMap[oldSelection+1] < 0 then
					(
						moveSeparator theID (oldSelection+1) dir:-1
						lbx_inputs.selection = oldSelection+1 
					)
					else
					(
						moveSocket theID oldSelection dir:1
						lbx_inputs.selection = oldSelection+1 
					)
				)
			)
			MagmaFlowEditor_Rollout.createNodeTree init:false
		)		
		
		on btn_moveOutputUp pressed do
		(
			local oldSelection = lbx_outputs.selection
			local theID = MagmaFlowEditor_Functions.getNodeID magma MagmaFlowEditor_Rollout.lastNodeClick
			if lbx_outputs.selection > 1 do
			(
				moveOutputSocket theID oldSelection dir:-1
				lbx_outputs.selection = oldSelection-1 
				magma.popEditableBLOP()
				MagmaFlowEditor_Rollout.createNodeTree init:false
			)
		)
		on btn_moveOutputDown pressed do
		(
			local oldSelection = lbx_outputs.selection
			local theID = MagmaFlowEditor_Functions.getNodeID magma MagmaFlowEditor_Rollout.lastNodeClick
			if lbx_outputs.selection <  lbx_outputs.items.count do
			(
				moveOutputSocket theID oldSelection dir:1
				lbx_outputs.selection = oldSelection+1 
				magma.popEditableBLOP()
				MagmaFlowEditor_Rollout.createNodeTree init:false
			)
		)	
		
		on btn_addOutput pressed do
		(
			local theID = MagmaFlowEditor_Functions.getNodeID magma MagmaFlowEditor_Rollout.lastNodeClick
			magma.setNumNodeOutputs theID ((magma.getNumNodeOutputs theID)+1)
			MagmaFlowEditor_Rollout.createNodeTree init:true
			updateLists()
			lbx_outputs.selection = lbx_outputs.items.count
		)		
		
		on btn_removeOutput pressed do
		(
			local theID = MagmaFlowEditor_Functions.getNodeID magma MagmaFlowEditor_Rollout.lastNodeClick
			magma.setNumNodeOutputs theID ((magma.getNumNodeOutputs theID)-1)
			MagmaFlowEditor_Rollout.createNodeTree init:true
			updateLists()
			lbx_outputs.selection = lbx_outputs.items.count		
		)		

		on btn_editBLOP pressed do
		(
			local theID = MagmaFlowEditor_Functions.getNodeID magma MagmaFlowEditor_Rollout.lastNodeClick
			append EditableBlopStack theID
			magma.PushEditableBLOP theID 
			MagmaFlowEditor_Rollout.restorePanAndZoom()
			MagmaFlowEditor_Rollout.createNodeTree init:true
			MagmaFlowEditor_Rollout.displaySelectedNodeProperties()
			MagmaFlowEditor_Rollout.updateNavigator fullUpdate:true
			MagmaFlowEditor_Rollout.createUndoRecord ("Edit BLOP [" + theID as string+"]")
			MagmaFlowEditor_Rollout.createNodeTree init:false
			MagmaFlowEditor_Rollout.autoReorderFlow()			
		)
		
		fn RolloutOpen =
		(
			updateLists()
		)
		
		on MagmaFlowEditor_EditableBLOP open do
		(
			RolloutOpen()
		)
	)
	
	
	rollout MagmaFlowEditor_OperatorRollout "Operator" category:100
	(
		dropdownlist ddl_category width:70 align:#left offset:[-12,-3] height:20 across:2
		dropdownlist ddl_type width:94 align:#right offset:[12,-3] height:20 
		
		checkbox chk_enabled "Enable" align:#left offset:[-5,-3] across:2 
		checkbox chk_collapsed "Collapse" offset:[8,-3] align:#right
		--checkbox chk_hideUnconnectedOutputs "Hide Unconnected Outputs" offset:[-5,-3]
		

		fn updateType =
		(
			MagmaFlowEditor_Rollout.createNodeTree init:true
			--KrakatoaChannelNodeEditor_OperatorDescriptionRollout.updateDescription()
			MagmaFlowEditor_Rollout.setSelectedNodes #(MagmaFlowEditor_Rollout.lastNodeClick)
			
			--btn_convertToFloat.visible = ddl_category.selected == "Logic and Comparison" and ddl_type.selected != "Switch"
			setFocus MagmaFlowEditor_Rollout.hc			
		)
		
		fn updateCategories =
		(
			ddl_category.items = MagmaFlowEditor_Rollout.DepotCategories
			local theID = MagmaFlowEditor_Functions.getNodeID magma MagmaFlowEditor_Rollout.lastNodeClick
			if theID >= 0 do
			(
				local theNodeType = magma.getNodeType theID
				local theNodeCategory = magma.GetTypeCategory theNodeType
				local theIndex = findItem MagmaFlowEditor_Rollout.DepotCategories theNodeCategory
				ddl_category.selection = theIndex
				local theArray = MagmaFlowEditor_Rollout.DepotDefinition[theIndex]
				ddl_type.items = for i = 2 to theArray.count collect theArray[i][2]
				local theIndex2 = findItem ddl_type.items theNodeType
				ddl_type.selection = theIndex2
			)
		)	
		

		on chk_enabled changed state do
		(
			local theID = MagmaFlowEditor_Functions.getNodeID magma MagmaFlowEditor_Rollout.lastNodeClick			
			magma.setNodeProperty theID "enabled" (not (magma.getNodeProperty theID "enabled"))
			MagmaFlowEditor_Rollout.createNodeTree init:false
		)
		
		on chk_collapsed changed state do
		(
			local theID = MagmaFlowEditor_Functions.getNodeID magma MagmaFlowEditor_Rollout.lastNodeClick
			magma.DeclareExtensionProperty theID "Collapsed" 
			local theState = magma.GetNodeProperty theID "Collapsed"  
			if theState == undefined do theState = false
			theState = not theState 			
			magma.setNodeProperty theID "Collapsed" theState
			MagmaFlowEditor_Rollout.collapseBranches()
			MagmaFlowEditor_Rollout.createNodeTree init:true
		)		
		
		/*
		on chk_hideUnconnectedOutputs changed state do
		(
			local theID = MagmaFlowEditor_Functions.getNodeID magma MagmaFlowEditor_Rollout.lastNodeClick
			magma.DeclareExtensionProperty theID "HideUnconnectedOutputs" 
			local theState = magma.GetNodeProperty theID "HideUnconnectedOutputs"  
			if theState == undefined do theState = false
			theState = not theState 
			magma.SetNodeProperty theID "HideUnconnectedOutputs" theState 
			MagmaFlowEditor_Rollout.createNodeTree init:false
		)
		*/	
		
		fn replaceNode =
		(
			if ddl_type.selected != undefined do MagmaFlowEditor_NodeNameRollout.edt_nodeName.text = ddl_type.selected
			local theOldID = MagmaFlowEditor_Functions.getNodeID magma MagmaFlowEditor_Rollout.lastNodeClick				
			local extendedProps = magma.GetNodePropertyNames theOldID #custom
			local standardProps = magma.GetNodePropertyNames theOldID #internal
			if extendedProps == undefined do extendedProps=#()
			local oldPropValues = for i in extendedProps collect magma.getNodeProperty theOldID i
			local oldStandardValues = for i in standardProps collect magma.getNodeProperty theOldID i
			
			local theOldConnections = for c = 1 to magma.GetNumNodeInputs theOldID collect magma.GetNodeInput theOldID c
			local theOldOutputConnections = magmaFlowEditor_Functions.GetConnectedNodes magma theOldID 
			local theOldSockets = for i = 1 to magma.GetNumNodeInputs theOldID collect #(magma.GetNodeInputDescription theOldID i, magma.getNodeInputDefaultValue theOldID i)
			
			theNewID = magma.CreateNode ddl_type.selected
			magma.ReplaceNode theOldID theNewID
			MagmaFlowEditor_Rollout.lastNodeClick = findItem (magma.getNodes()) theOldID
			
			if ddl_type.selected as name == #InputValue do
			(
				local theCtrl = bezier_float(); theCtrl.value = 1.0
				magma.SetNodeProperty theOldID "controller" theCtrl
			)

			for i = 1 to extendedProps.count do 
			(
				if extendedProps[i] != "DefaultsType" do
				(
					magma.DeclareExtensionProperty theOldID extendedProps[i]
					magma.setNodeProperty theOldID extendedProps[i] oldPropValues[i] 
				)
			)
			
			--Try to set any matching internal properties, for example to preserve channel lists when switching ParticleSumRadius and ParticleSumCount
			for i = 1 to standardProps.count do 
				try(magma.setNodeProperty theOldID standardProps[i] oldStandardValues[i] )catch()
			
			--Copy defaults of matching input sockets:
			for i = 1 to magma.getNumNodeInputs theOldID do
				for j = 1 to theOldSockets.count do
					if theOldSockets[j][1] == magma.GetNodeInputDescription theOldID i and classof (magma.getNodeInputDefaultValue theOldID i) == theOldSockets[j][2] do
						magma.setNodeInputDefaultValue theOldID i theOldSockets[j][2]
					
					
			MagmaFlowEditor_Functions.setUIProperty magma theOldID "Name" ddl_type.selected
			
			for c = 1 to magma.GetNumNodeInputs theOldID where theOldConnections[c] != undefined do
				magma.SetNodeInput theOldID c theOldConnections[c][1] theOldConnections[c][2]
			
			for c = 1 to magma.getNumNodeOutputs theOldID where theOldOutputConnections[c] != undefined do
				for j = 1 to theOldOutputConnections[c].count do
					magma.SetNodeInput theOldOutputConnections[c][j][1] theOldOutputConnections[c][j][2] theOldID c
				
			--DISCONNECT ANY OUTPUT SOCKETS WITH HIGHER INDEX THAN THE NEW NUMBER OF SOCKETS:
			for c = ((magma.getNumNodeOutputs theOldID)+1) to theOldOutputConnections.count where theOldOutputConnections[c] != undefined do
				for j = 1 to theOldOutputConnections[c].count do
					magma.SetNodeInput theOldOutputConnections[c][j][1] theOldOutputConnections[c][j][2] -1 1
				
			updateType()
			MagmaFlowEditor_Rollout.updateMagmaHolder()
			MagmaFlowEditor_Rollout.displaySelectedNodeProperties()
			MagmaFlowEditor_Rollout.createNodeTree init:false
			MagmaFlowEditor_Rollout.createUndoRecord "Change Operator Type"		
			MagmaFlowEditor_Rollout.exposeControlsToModifier()
		)
		
		on ddl_type selected itm do
		(
			replaceNode()
		)		
		on ddl_category selected itm do
		(
			local theArray = MagmaFlowEditor_Rollout.DepotDefinition[itm]
			ddl_type.items = for i = 2 to theArray.count collect theArray[i][2]
			ddl_type.selection = 1
			replaceNode()
		)		
		
		fn updateGUI =
		(
			local theID = MagmaFlowEditor_Functions.getNodeID magma MagmaFlowEditor_Rollout.lastNodeClick				
			chk_enabled.state = (magma.getNodeProperty theID "enabled")
			chk_collapsed.state = (magma.getNodeProperty theID "Collapsed") == true
			--chk_hideUnconnectedOutputs.state = (magma.getNodeProperty theID "HideUnconnectedOutputs") == true
		)
		
		fn RolloutOpen =
		(
			updateCategories()
			updateGUI()
			--updateSubRollouts()
			--KrakatoaChannelNodeEditor_OperatorDescriptionRollout.updateDescription()
		)			
		
		on MagmaFlowEditor_OperatorRollout open do
		(
			RolloutOpen()
		)
		
	)
	
	rollout MagmaFlowEditor_OutputRollout "Output" category:100
	(
		checkbox chk_enabled "Enable" align:#left offset:[-5,-3] across:2 
		checkbox chk_collapsed "Collapse" offset:[8,-3] align:#right
		checkbox chk_exposed "Expose" offset:[2,-3] align:#right
		
		label lbl_channelName " Channel Name:" align:#left offset:[-10,-18]
		edittext edt_ChannelName fieldwidth:139 offset:[-13,-3] align:#left across:2
		button btn_SourceChannelName "S" width:18 height:18 offset:[10,-3] align:#right tooltip:"Toggle 'Source_' prefix when used with PRTCloner Source channels, e.g. Source_Color, Source_Density, Source_Position etc."
		
		edittext lbl_isUsedByKrakatoa "" fieldwidth:160 align:#center offset:[-1,-3] readonly:true
		listbox ddl_ChannelType " Standard Channel Names:" items:#() width:160 align:#center
		
		label lbl_SearchChannels "Find:" across:3 align:#left offset:[-9,-3]
		edittext edt_SearchChannels fieldwidth:112 align:#center offset:[0,-5]
		button btn_SearchChannels "X" width:20 height:18 align:#right offset:[8,-5]
		
		listbox ddl_ChannelData " Data Type:" items:#() height:4 width:100 align:#left across:2 offset:[-10,0]
		listbox ddl_ChannelArity " Arity:" items:#("1","2","3","4") height:4 width:60 align:#right offset:[10,0]
		
		dropdownlist ddl_sortingOptions " Channel List Sorting:" items:#("Factory Default Order","By Usage Frequency","Alphabetical","Alphabetical, Mapping Last","Int>Float>Vector>Quat","Integers Only","Floats Only","Vectors Only","Quaternions Only","PRT Maker Channels Only","PRT Hair Channels Only","Frost Channels Only","FumeFX Channels Only","RealFlow Channels Only","Naiad Channels Only") offset:[0,0] width:160 height:20 align:#center
		
		fn updateGUI =
		(
			local theID = MagmaFlowEditor_Functions.getNodeID magma MagmaFlowEditor_Rollout.lastNodeClick				
			chk_enabled.state = (magma.getNodeProperty theID "enabled")
			chk_collapsed.state = (magma.getNodeProperty theID "Collapsed") == true
			--TODO: Set the list of filter options according to product - move code to global management functions
			ddl_sortingOptions.items = MagmaFlowEditor_Functions.getSortingOptionsList()
		)
		
		fn getChannelDataAndArity =
		(
			local theID = MagmaFlowEditor_Functions.getNodeID magma MagmaFlowEditor_Rollout.lastNodeClick				
			local theName = magma.getNodeProperty theID "channelName"
			local theType = magma.getNodeProperty theID "channelType"
			local theFS = filterString theType "[]"
			theType = theFS[1]
			local theArity = theFS[2] --if classof (magma.getNodeProperty theID "controller").value == Point3 then 3 else 1
			if theArity == undefined do theArity = 1
				
			if MagmaFlowEditor_Functions.isRenderElement magma then
			(
				ddl_ChannelData.items = #("float16","float32")
				ddl_ChannelArity.enabled = false
				ddl_ChannelArity.selection = 3
				edt_ChannelName.text = "RenderElement"
				edt_ChannelName.enabled = false
				ddl_ChannelType.visible = false
				ddl_sortingOptions.visible = false
				chk_exposed.visible = false
			)			
			else 
			(
				if MagmaFlowEditor_Functions.isModifier magma then
				(
					ddl_ChannelType.visible = true
					edt_ChannelName.enabled = true
					ddl_sortingOptions.visible = true
					chk_exposed.visible = true
					if findItem ddl_ChannelType.items theName == 0 then --custom channel!
					(
						ddl_ChannelData.items = #("float16","float32","int8","int16","int32","uint8","uint16","uint32")
						ddl_ChannelArity.enabled = true
					)
					else
					(
						if theName == "Scale" then
						(
							ddl_ChannelData.items = #("float16","float32","float64")
							ddl_ChannelArity.enabled = true
						)
						else
						(
							ddl_ChannelArity.enabled = false
							if matchPattern theType pattern:"float*" then
								ddl_ChannelData.items = #("float16","float32","float64")
							else if matchPattern theType pattern:"int*" then
								ddl_ChannelData.items = #("int8","int16","int32","int64")
							else if matchPattern theType pattern:"uint*" then
								ddl_ChannelData.items = #("uint8","uint16","uint32","uint64")
						)
					)
				)
			)
			
			if MagmaFlowEditor_Functions.isModifier magma do
			(
				local theRenderSettings = try(FranticParticles.getProperty ("Memory:Channel:"+theName))catch(undefined)
				if theRenderSettings != undefined do
				(
					ddl_ChannelData.items = #(theRenderSettings)
					ddl_ChannelData.selection = 1
					magma.setNodeProperty theID "channelType" (theRenderSettings+"["+theArity as string+"]")
					MagmaFlowEditor_Rollout.createNodeTree init:false
				)			
			)
			
			if not MagmaFlowEditor_Functions.isRenderElement magma do
			(
				ddl_ChannelData.selection = findItem ddl_ChannelData.items theType		
				ddl_ChannelArity.selection = findItem ddl_ChannelArity.items (theArity as string)
			)
		)		
		
		fn updateDataDepth =
		(
			local theID = MagmaFlowEditor_Functions.getNodeID magma MagmaFlowEditor_Rollout.lastNodeClick				
			magma.setNodeProperty theID "channelType" (ddl_ChannelData.selected+"["+ddl_ChannelArity.selected +"]")
			MagmaFlowEditor_Rollout.createNodeTree init:false
			MagmaFlowEditor_Rollout.updateMagmaHolder()
		)
		
		fn updateDataArity =
		(
			local theID = MagmaFlowEditor_Functions.getNodeID magma MagmaFlowEditor_Rollout.lastNodeClick				
			local theType = magma.getNodeProperty theID "channelType"
			local theFS = filterString theType "[]"
			theType = theFS[1]+"["+ddl_ChannelArity.selected+"]"
			magma.setNodeProperty theID "channelType" theType 
			MagmaFlowEditor_Rollout.createNodeTree init:false
			MagmaFlowEditor_Rollout.updateMagmaHolder()
		)
		
		fn updateSelection =
		(
			local theVal = execute (getIniSetting (theIniFileLocation + "MagmaFlowEditor_Preferences.ini") "OutputNode" "ChannelSorting" )
			if theVal == OK do theVal = 1
			ddl_sortingOptions.selection = theVal
			
			ddl_ChannelType.items  = MagmaFlowEditor_Functions.getSortedChannelsList channelsList ddl_sortingOptions.selection theIniFileLocation includeCustom:false nodeType:#output filterPattern:edt_SearchChannels.text
			
			local theID = MagmaFlowEditor_Functions.getNodeID magma MagmaFlowEditor_Rollout.lastNodeClick				
			local theChannelName = (filterString (magma.getNodeProperty theID "channelName") ": ")[1]
			local theIndex = findItem ddl_ChannelType.items theChannelName 
			ddl_ChannelType.selection = theIndex
			getChannelDataAndArity()
			updateGUI()
		)
		
		fn getUsedByRendererState =
		(
			--TODO: Move code to global management functions
			lbl_isUsedByKrakatoa.text = MagmaFlowEditor_Functions.getUsedByRendererString magma edt_ChannelName.text
		)		
		
		on edt_SearchChannels changed txt do
		(
			ddl_ChannelType.items  = MagmaFlowEditor_Functions.getSortedChannelsList channelsList ddl_sortingOptions.selection theIniFileLocation includeCustom:false filterPattern:txt
			updateSelection()
			getUsedByRendererState()			
		)
		
		on btn_SearchChannels pressed do
		(
			edt_SearchChannels.changed (edt_SearchChannels.text = "")
		)
		
		on chk_enabled changed state do
		(
			local theID = MagmaFlowEditor_Functions.getNodeID magma MagmaFlowEditor_Rollout.lastNodeClick				
			magma.setNodeProperty theID "enabled" (not (magma.getNodeProperty theID "enabled"))
			MagmaFlowEditor_Rollout.createNodeTree init:false
		)
		
		on chk_collapsed changed state do
		(
			local theID = MagmaFlowEditor_Functions.getNodeID magma MagmaFlowEditor_Rollout.lastNodeClick				
			magma.DeclareExtensionProperty theID "Collapsed" 
			local theState = magma.GetNodeProperty theID "Collapsed"  
			if theState == undefined do theState = false
			theState = not theState 			
			magma.setNodeProperty theID "Collapsed" theState
			MagmaFlowEditor_Rollout.collapseBranches()
			MagmaFlowEditor_Rollout.createNodeTree init:true
		)		

		on chk_exposed changed state do
		(
			local currentID = MagmaFlowEditor_Functions.getNodeID magma MagmaFlowEditor_Rollout.lastNodeClick	
			magma.DeclareExtensionProperty currentID "Exposed"
			magma.setNodeProperty currentID "Exposed" state
			if state do
			(
				--magma.DeclareExtensionProperty currentID "ExposedChannels"
				--magma.setNodeProperty currentID "ExposedChannels" ddl_ValueType.items
				magma.DeclareExtensionProperty currentID "ExposedChannelsSorting"
				magma.setNodeProperty currentID "ExposedChannelsSorting" ddl_sortingOptions.selected
			)
			
			MagmaFlowEditor_Rollout.exposeControlsToModifier()
			MagmaFlowEditor_Rollout.createNodeTree init:false
			MagmaFlowEditor_Rollout.createUndoRecord (if state then "Exposed Control" else "Unexposed Control")
		)				
		
		on ddl_sortingOptions selected itm do
		(
			setIniSetting (theIniFileLocation + "MagmaFlowEditor_Preferences.ini") "OutputNode" "ChannelSorting" (itm as string)
			updateSelection()
			getUsedByRendererState()
		)				
		


		on edt_ChannelName entered txt do
		(
			local theID = MagmaFlowEditor_Functions.getNodeID magma MagmaFlowEditor_Rollout.lastNodeClick				
			local txt = MagmaFlowEditor_Functions.purifyChannelName txt
			local theIndex = findItem ddl_ChannelType.items txt
			if theIndex > 0 then
			(
				magma.setNodeProperty theID "channelName" txt
			)
			else
				magma.setNodeProperty theID "channelName" txt
			
			local theIndex = 0
			for i = 1 to ChannelsList.count where ChannelsList[i][1] == txt do theIndex = i
			if theIndex > 0 do
			(
				if ChannelsList[theIndex][3] > 1 then
					magma.setNodeProperty theID "channelType" (ChannelsList[theIndex][2] + "[" +ChannelsList[theIndex][3] as string + "]")
				else
					magma.setNodeProperty theID "channelType" ChannelsList[theIndex][2]
			)			
			
			updateSelection()
			MagmaFlowEditor_Rollout.createUndoRecord ("Enter Output Channel Name ["+ txt +"]")
			MagmaFlowEditor_Rollout.createNodeTree init:false
			edt_ChannelName.text = txt
			getUsedByRendererState()
			MagmaFlowEditor_Rollout.debugFlow()
		)

		on btn_SourceChannelName pressed do
		(
			local txt = edt_ChannelName.text
			if matchPattern txt pattern:"Source_*" then
				txt = substring txt 8 -1
			else
				txt = "Source_"+ txt
			edt_ChannelName.text = txt
			local theID = MagmaFlowEditor_Functions.getNodeID magma MagmaFlowEditor_Rollout.lastNodeClick	
			magma.setNodeProperty theID "channelName" txt
			updateSelection()
			MagmaFlowEditor_Rollout.createUndoRecord ("Changed Output Channel Name ["+ txt +"]")
			MagmaFlowEditor_Rollout.createNodeTree init:false
			getUsedByRendererState()
			MagmaFlowEditor_Rollout.debugFlow()			
		)
		
		on ddl_ChannelType selected itm do
		(
			if ddl_ChannelType.selected == undefined do return false
			edt_ChannelName.text = ddl_ChannelType.selected
			--local theTypeArray = for i = 1 to 3 collect sortedChannelsList[itm][i]
			/*	
			if MagmaFlowEditor_Functions.isRenderElement magma false do  
			(
				theTypeArray[2] = "float16"
				theTypeArray[3] = 3
			)
			*/
			--KrakatoaChannelEditor_DisplayNodeTreeData[MagmaFlowEditor_Rollout.lastNodeClick][3] = deepCopy theTypeArray
			
			--updateDataDepth()
			
			--magma.ReplaceNode theOldID theNewID
			
			local theID = MagmaFlowEditor_Functions.getNodeID magma MagmaFlowEditor_Rollout.lastNodeClick				
			magma.setNodeProperty theID "channelName" ddl_ChannelType.selected
			
			local theIndex = 0
			for i = 1 to ChannelsList.count where ChannelsList[i][1] == ddl_ChannelType.selected do theIndex = i
			if theIndex > 0 do
			(
				--print theIndex
				--print ChannelsList
				if ChannelsList[theIndex][3] > 1 then
					magma.setNodeProperty theID "channelType" (ChannelsList[theIndex][2] + "[" +ChannelsList[theIndex][3] as string + "]")
				else
					magma.setNodeProperty theID "channelType" ChannelsList[theIndex][2]
			)
			
			theVal = execute (getIniSetting (theIniFileLocation + "MagmaFlowOutputChannelsUsageHistory.ini") "UsageHistory" ddl_ChannelType.selected)
			if theVal == OK do theVal = 0
			theVal += 1
			setIniSetting (theIniFileLocation + "MagmaFlowOutputChannelsUsageHistory.ini") "UsageHistory" ddl_ChannelType.selected (theVal as string)
				
			updateSelection()
			getUsedByRendererState()
			getChannelDataAndArity()
			MagmaFlowEditor_Rollout.createUndoRecord ("Output Channel Name ["+ ddl_ChannelType.selected +"]")
			MagmaFlowEditor_Rollout.createNodeTree init:false
			MagmaFlowEditor_Rollout.updateMagmaHolder()
			MagmaFlowEditor_Rollout.debugFlow()
			MagmaFlowEditor_Rollout.updateModifierName()
		)

		
		on ddl_ChannelData selected itm do
		(
			updateDataDepth()
			MagmaFlowEditor_Rollout.createUndoRecord ("Output Channel Data ["+ddl_ChannelData.selected + "]")
			MagmaFlowEditor_Rollout.updateMagmaHolder()
			MagmaFlowEditor_Rollout.debugFlow()
		)
		
		on ddl_ChannelArity selected itm do
		(
			updateDataArity()
			MagmaFlowEditor_Rollout.createUndoRecord ("Output Channel Arity ["+ddl_ChannelArity.selected + "]")
			MagmaFlowEditor_Rollout.updateMagmaHolder()
			MagmaFlowEditor_Rollout.debugFlow()
		)		

		
		fn RolloutOpen =
		(
			--TODO: Move code to global management functions
			channelsList = MagmaFlowEditor_Functions.loadChannelsList magma mode:#output
			local theID = MagmaFlowEditor_Functions.getNodeID magma MagmaFlowEditor_Rollout.lastNodeClick				
			edt_ChannelName.text = (filterString (magma.getNodeProperty theID "channelName") ": ")[1]
			ddl_ChannelType.items  = MagmaFlowEditor_Functions.getSortedChannelsList channelsList ddl_sortingOptions.selection theIniFileLocation includeCustom:false filterPattern:edt_SearchChannels.text
			chk_exposed.state = (magma.getNodeProperty theID "Exposed" ) == true
			updateSelection()
			getUsedByRendererState()
		)
		
		on MagmaFlowEditor_OutputRollout open do
		(
			RolloutOpen()
		)
	)
	
	rollout MagmaFlowEditor_InputChannelRollout "Input Channel" category:100
	(
		--group "Input Node Settings:"	(
			label lbl_channelName "Channel Name:" across:2 align:#left  offset:[-10,-4]
			checkbox chk_exposed "Expose" offset:[3,-4] align:#right
		
			edittext edt_ChannelName fieldwidth:139 offset:[-13,-3] align:#left across:2
			button btn_SourceChannelName "S" width:18 height:18 offset:[10,-3] align:#right tooltip:"Toggle 'Source_' prefix when used with PRTCloner Source channels, e.g. Source_Color, Source_Density, Source_Position etc."
			edittext lbl_channelInfo "" offset:[-3,-4] align:#center readonly:true fieldwidth:159
			edittext lbl_isUsedByKrakatoa "" offset:[-3,-4] align:#center readonly:true fieldwidth:159

			listbox ddl_ValueType height:5 items:#() width:160 align:#center offset:[0,-3] 
			label lbl_SearchChannels "Find:" across:3 align:#left offset:[-9,-3]
			edittext edt_SearchChannels fieldwidth:112 align:#center offset:[0,-5]
			button btn_SearchChannels "X" width:20 height:18 align:#right offset:[8,-5]		
		
			dropdownlist ddl_sortingOptions items:#("Factory Default Order","By Usage Frequency","Alphabetical","Alphabetical, Mapping Last","Int>Float>Vector>Quat","Integers Only","Floats Only","Vectors Only","Quaternions Only","PRT Maker Channels Only","PRT Hair Channels Only","Frost Channels Only","FumeFX Channels Only","RealFlow Channels Only","Naiad Channels Only") offset:[0,0] width:160 height:20 align:#center --"Channel List Sorting:"
			checkbox chk_existingOnly "Show Existing Channels Only" checked:true offset:[-9,-3]	
		
			checkbutton btn_matchChannelFrom "Match Channel From Node..." width:160 offset:[0,-3] align:#center tooltip:"Set the Channel by picking an existing InputChannel or Output node..."
			button btn_convertToFloat "Convert To Float" width:160 offset:[0,-3] align:#center tooltip:"Insert a ToFloat Operator to convert the Input value to a Floating Point value."
			button btn_convertToVector "Convert To Vector" width:160 align:#center offset:[0,-25] tooltip:"Insert a ToVector Operator to convert the Input value to a Vector value."
			
			button btn_convertVectorX "Extract X" width:53 across:3 offset:[-10,-25] align:#left tooltip:"Insert a Breakout Operator to extract the X component of the Vector value."
			button btn_convertVectorY "Extract Y" width:54 align:#center offset:[0,-25] tooltip:"Insert a Breakout Operator to extract the Y component of the Vector value."
			button btn_convertVectorZ "Extract Z" width:53 align:#right offset:[9,-25] tooltip:"Insert a Breakout Operator to extract the Z component of the Vector value."

			button btn_transformToWorld "To World" width:80 across:2 offset:[-10,-3] align:#left tooltip:"Insert a ToWorld Operator to transform the Vector to world space."
			button btn_transformToView "To Camera" width:80 align:#right offset:[10,-3] tooltip:"Insert a ToView Operator to transform the Vector to view space."

		--button btn_sameChannelAsOutput "Same Channel As Output" width:152 tooltip:"Switches the Input to the same Channel as the current Output Node."		
		--)
		
		on chk_exposed changed state do
		(
			local currentID = MagmaFlowEditor_Functions.getNodeID magma MagmaFlowEditor_Rollout.lastNodeClick	
			magma.DeclareExtensionProperty currentID "Exposed"
			magma.setNodeProperty currentID "Exposed" state
			if state do
			(
				--magma.DeclareExtensionProperty currentID "ExposedChannels"
				--magma.setNodeProperty currentID "ExposedChannels" ddl_ValueType.items
				magma.DeclareExtensionProperty currentID "ExposedChannelsSorting"
				magma.setNodeProperty currentID "ExposedChannelsSorting" ddl_sortingOptions.selected
			)
			
			MagmaFlowEditor_Rollout.exposeControlsToModifier()
			MagmaFlowEditor_Rollout.createNodeTree init:false
			MagmaFlowEditor_Rollout.createUndoRecord (if state then "Exposed Control" else "Unexposed Control")
		)
		
		
		fn getUsedByRendererState =
		(
			if MagmaFlowEditor_Functions.IsModifier magma then
			(
				if renderers.current.classid as string == "#(-1204370534, -399920359)" or renderers.current.classid as string == "#(3090596762L, 3895046937L)" then --if Krakatoa is the Renderer
				(
					try(
						Krakatoa_GUI_Channels.updateMemChannels()
						lbl_isUsedByKrakatoa.text = if (for i in Krakatoa_GUI_Channels.activeMemChannels where matchPattern i[1] pattern:edt_ChannelName.text collect i).count == 1 then
							"Will Be Stored In PCache" 
						else 
							"Not Cacheable"
					)catch(lbl_isUsedByKrakatoa.text = "Failed To Acquire Renderer Info")	
				)
				else lbl_isUsedByKrakatoa.text = "Current Renderer Not Krakatoa"
			)
			else lbl_isUsedByKrakatoa.text = "Will Output As Render Element"
		)		
		
		fn updateControls =
		(
			local existingOnly = execute (getIniSetting (theIniFileLocation + "MagmaFlowEditor_Preferences.ini") "InputNode" "ExistingChannelsOnly" )
			if existingOnly == OK do existingOnly = false
			chk_existingOnly.checked = existingOnly
			
			ddl_sortingOptions.items = MagmaFlowEditor_Functions.getSortingOptionsList()
			
			local theID = MagmaFlowEditor_Functions.getNodeID magma MagmaFlowEditor_Rollout.lastNodeClick				
			local theChannelName = magma.GetNodeProperty theID "channelName"
			chk_exposed.state = (magma.getNodeProperty theID "Exposed" ) == true
			
			local controlsList = #(edt_ChannelName, lbl_channelInfo, lbl_isUsedByKrakatoa, ddl_sortingOptions, btn_matchChannelFrom)

			if EditableBlopStack.count > 0 and magma.getNodeProperty EditableBlopStack[EditableBlopStack.count] "uiType" == "Loop" then 
			(
				for c in controlsList do c.visible = false
				channelsList = MagmaFlowEditor_Functions.getLoopChannelList magma EditableBlopStack[EditableBlopStack.count]
				ddl_ValueType.items =  for c in channelsList collect c[1]
				--format "%\n" channelsList
				local theIndex = findItem ddl_ValueType.items theChannelName
				if theIndex == 0 do 
				(
					theIndex = 1
					theChannelName = ddl_ValueType.items[1]
					magma.SetNodeProperty theID "channelName" theChannelName
				)
				ddl_ValueType.selection = theIndex
				btn_convertToFloat.visible = btn_convertToVector.visible = btn_convertVectorX.visible = btn_convertVectorY.visible = btn_convertVectorZ.visible = false
				for i in channelsList where i[1] == theChannelName do 
				(
					btn_convertToVector.visible = i[3] == 1 and not matchPattern i[2] pattern:"int*"
					btn_convertToFloat.visible = matchPattern i[2] pattern:"int*" and i[3] == 1
					btn_transformToWorld.visible = btn_transformToView.visible = btn_convertVectorX.visible = btn_convertVectorY.visible = btn_convertVectorZ.visible = i[3] == 3
				)
			)
			else
			(
				for c in controlsList do c.visible = true
				if chk_existingOnly.checked then
				(
					local existingChannels = #()
					local existingChannelNames = #()
					local theDeps = refs.dependentNodes magma
					for d in theDeps do
					(
						local theStream = try(FranticParticles.GetPRTObjectIStream d true false)catch(undefined)
						if theStream != undefined do
						(
							for i in (theStream.getChannels()) do 
							(
								local theFS = filterString i " []"
								append theFS "Existing Channel"			
								theFS[3] = execute theFS[3]
								if (appendIfUnique existingChannelNames theFS[1]) do 
								(
									append existingChannels theFS
								)
							)
							theStream.close()
						)
					)
					local filteredChannelsList = for c in channelsList where findItem existingChannelNames c[1] > 0 collect c
					local filteredNames = for c in filteredChannelsList collect c[1]
					for c in existingChannels where findItem filteredNames c[1] == 0 do append filteredChannelsList c
					ddl_ValueType.items =  MagmaFlowEditor_Functions.getSortedChannelsList filteredChannelsList ddl_sortingOptions.selection theIniFileLocation includeCustom:false filterPattern:edt_SearchChannels.text
				)
				else
					ddl_ValueType.items =  MagmaFlowEditor_Functions.getSortedChannelsList channelsList ddl_sortingOptions.selection theIniFileLocation includeCustom:false filterPattern:edt_SearchChannels.text

				edt_ChannelName.text = theChannelName
				local theIndex = findItem ddl_ValueType.items theChannelName
				if theIndex == 0 do edt_ChannelName.visible = true
				ddl_ValueType.selection = theIndex
				lbl_channelInfo.text = "User-Defined Channel Name"
				for i in channelsList where i[1] == theChannelName do 
				(
					btn_convertToVector.visible = i[3] == 1 and not matchPattern i[2] pattern:"int*"
					btn_convertToFloat.visible = matchPattern i[2] pattern:"int*" and i[3] == 1
					btn_transformToWorld.visible = btn_transformToView.visible = btn_convertVectorX.visible = btn_convertVectorY.visible = btn_convertVectorZ.visible = i[3] == 3
					lbl_channelInfo.text = i[4]
				)
				if lbl_channelInfo.text == "User-Defined Channel Name" and matchPattern theChannelName pattern:"Source_*" do lbl_channelInfo.text = "Custom Source_Channel Name"
				if theIndex == 0 do btn_convertToFloat.visible = btn_convertToVector.visible = btn_convertVectorX.visible = btn_convertVectorY.visible = btn_convertVectorZ.visible = false
				getUsedByRendererState()			
			)
		)
		
		on chk_existingOnly changed state do 
		(
			setIniSetting (theIniFileLocation + "MagmaFlowEditor_Preferences.ini") "InputNode" "ExistingChannelsOnly" (state as string)
			updateControls()
		)
		
		on edt_ChannelName entered txt do
		(
			txt = MagmaFlowEditor_Functions.purifyChannelName txt
			local theID = MagmaFlowEditor_Functions.getNodeID magma MagmaFlowEditor_Rollout.lastNodeClick				
			magma.setNodeProperty theID "channelName" txt
			updateControls()
			MagmaFlowEditor_Rollout.createNodeTree init:false
			MagmaFlowEditor_Rollout.createUndoRecord ("Enter Channel Name ["+ txt +"]")
			MagmaFlowEditor_Rollout.updateMagmaHolder()
			edt_ChannelName.text = txt
		)	

		on btn_SourceChannelName pressed do
		(
			local txt = edt_ChannelName.text
			if matchPattern txt pattern:"Source_*" then
				txt = substring txt 8 -1
			else
				txt = "Source_"+ txt
			edt_ChannelName.text = txt
			local theID = MagmaFlowEditor_Functions.getNodeID magma MagmaFlowEditor_Rollout.lastNodeClick		
			magma.setNodeProperty theID "channelName" txt
			updateControls()
			MagmaFlowEditor_Rollout.createNodeTree init:false
			MagmaFlowEditor_Rollout.createUndoRecord ("Change Channel Name ["+ txt +"]")
			MagmaFlowEditor_Rollout.updateMagmaHolder()
		)		
		
		on btn_matchChannelFrom changed state do
		(
			if state then
				MagmaFlowSettings.isPickingChannelFromNode = MagmaFlowEditor_Rollout.lastNodeClick
			else
				MagmaFlowSettings.isPickingChannelFromNode = undefined
		)

		on ddl_sortingOptions selected itm do
		(
			updateControls()
			setIniSetting (theIniFileLocation + "MagmaFlowEditor_Preferences.ini") "InputNode" "ChannelSorting" (itm as string)
			MagmaFlowEditor_Rollout.createDepot()
		)		
		
		fn ddl_ValueType_SelectedFN itm =
		(
			if itm > 0 then
			(
				local theID = MagmaFlowEditor_Functions.getNodeID magma MagmaFlowEditor_Rollout.lastNodeClick
				magma.setNodeProperty theID "channelName" ddl_ValueType.selected
				updateControls()
				MagmaFlowEditor_Rollout.createNodeTree init:false
				MagmaFlowEditor_Rollout.createUndoRecord ("Channel [" + ddl_ValueType.selected + "]")
				MagmaFlowEditor_Rollout.updateMagmaHolder()
				setFocus MagmaFlowEditor_Rollout.hc		
				edt_ChannelName.visible = false
				theVal = execute (getIniSetting (theIniFileLocation + "MagmaFlowInputChannelsUsageHistory.ini") "UsageHistory" ddl_ValueType.selected)
				if theVal == OK do theVal = 0
				theVal += 1
				setIniSetting (theIniFileLocation + "MagmaFlowInputChannelsUsageHistory.ini") "UsageHistory" ddl_ValueType.selected (theVal as string)
				updateControls()
			)	
			else
			(
				edt_ChannelName.visible = true
				edt_ChannelName.text = "<enter name here>"
				updateControls()
			)	
			local oldText = edt_SearchChannels.text
			MagmaFlowEditor_Rollout.displaySelectedNodeProperties()
			edt_SearchChannels.text = oldText
			updateControls()
			MagmaFlowEditor_Rollout.createNodeTree init:true
			if ddl_ValueType.selected != undefined do MagmaFlowEditor_Rollout.createUndoRecord ("Value Type [" + ddl_ValueType.selected + "]")
			MagmaFlowEditor_Rollout.updateMagmaHolder()
			if chk_exposed.checked do MagmaFlowEditor_Rollout.exposeControlsToModifier()
			setFocus MagmaFlowEditor_Rollout.hc
			MagmaFlowEditor_Rollout.debugFlow()
			--MagmaFlowEditor_Rollout.autoReorderFlow createUndo:false
		)
		
		on btn_convertVectorX pressed do
		(
			MagmaFlowSettings.nodeInsertMode = true
			MagmaFlowEditor_Rollout.createNode "Breakout" insertOutSocket:1 mode:#button
			MagmaFlowEditor_Rollout.setSelectedNodes #(MagmaFlowEditor_Rollout.lastNodeClick)
			MagmaFlowEditor_Rollout.updateMagmaHolder init:true
		)
		on btn_convertVectorY pressed do
		(
			MagmaFlowSettings.nodeInsertMode = true
			MagmaFlowEditor_Rollout.createNode "Breakout" insertOutSocket:2 mode:#button
			MagmaFlowEditor_Rollout.setSelectedNodes #(MagmaFlowEditor_Rollout.lastNodeClick)
			MagmaFlowEditor_Rollout.updateMagmaHolder init:true
		)
		on btn_convertVectorZ pressed do
		(
			MagmaFlowSettings.nodeInsertMode = true
			MagmaFlowEditor_Rollout.createNode "Breakout" insertOutSocket:3 mode:#button
			MagmaFlowEditor_Rollout.setSelectedNodes #(MagmaFlowEditor_Rollout.lastNodeClick)
			MagmaFlowEditor_Rollout.updateMagmaHolder init:true
		)			
		
		on btn_transformToWorld pressed do
		(
			MagmaFlowSettings.nodeInsertMode = true
			local currentID = MagmaFlowEditor_Functions.getNodeID magma MagmaFlowEditor_Rollout.lastNodeClick				
			local newID = MagmaFlowEditor_Rollout.createNode "ToWorld" mode:#button
			if magma.getNodeType currentID == "InputChannel" do 
			(
				if matchPattern (magma.getNodeProperty currentID "channelName" ) pattern:"*Normal" then 
					magma.setNodeProperty newID "inputType" "Normal"
				else 	if findItem #("Position","FaceCenter","FaceElementCentroid") (magma.getNodeProperty currentID "channelName") == 0 do 
					magma.setNodeProperty newID "inputType" "Vector"
			)
			MagmaFlowEditor_Rollout.setSelectedNodes #(MagmaFlowEditor_Rollout.lastNodeClick)
			MagmaFlowEditor_Rollout.updateMagmaHolder init:true
		)		
		on btn_transformToView pressed do
		(
			local lastNode = MagmaFlowEditor_Rollout.lastNodeClick
			MagmaFlowSettings.nodeInsertMode = true
			local currentID = MagmaFlowEditor_Functions.getNodeID magma lastNode
			local newID = MagmaFlowEditor_Rollout.createNode "ToCamera" mode:#button
			if magma.getNodeType currentID == "InputChannel" do 
			(
				if matchPattern (magma.getNodeProperty currentID "channelName") pattern:"*Normal" then 
					magma.setNodeProperty newID "inputType" "Normal"
				else 	if findItem #("Position","FaceCenter","FaceElementCentroid") (magma.getNodeProperty currentID "channelName") == 0 do 
					magma.setNodeProperty newID "inputType" "Vector"
			)
			MagmaFlowEditor_Rollout.setSelectedNodes #(lastNode)
			MagmaFlowEditor_Rollout.displaySelectedNodeProperties()
			MagmaFlowEditor_Rollout.updateMagmaHolder init:true
		)		
		on btn_convertToVector pressed do
		(
			MagmaFlowSettings.nodeInsertMode = true
			local currentID = MagmaFlowEditor_Functions.getNodeID magma MagmaFlowEditor_Rollout.lastNodeClick				
			local newID = MagmaFlowEditor_Rollout.createNode "ToVector" mode:#button
			magma.setNodeInput newID 1 currentID 1
			magma.setNodeInput newID 2 currentID 1
			magma.setNodeInput newID 3 currentID 1
			MagmaFlowEditor_Rollout.setSelectedNodes #(MagmaFlowEditor_Rollout.lastNodeClick)
			MagmaFlowEditor_Rollout.updateMagmaHolder init:true
		)		
		on btn_convertToFloat pressed do
		(
			MagmaFlowSettings.nodeInsertMode = true
			local currentID = MagmaFlowEditor_Functions.getNodeID magma MagmaFlowEditor_Rollout.lastNodeClick				
			local newID = MagmaFlowEditor_Rollout.createNode "ToFloat" mode:#button
			magma.setNodeInput newID 1 currentID 1
			MagmaFlowEditor_Rollout.setSelectedNodes #(MagmaFlowEditor_Rollout.lastNodeClick)
			MagmaFlowEditor_Rollout.updateMagmaHolder init:true
		)		
		
		on ddl_ValueType selected itm do 
		(
			ddl_ValueType_SelectedFN itm
		)	

		on edt_SearchChannels changed txt do
		(
			ddl_ValueType.items  = MagmaFlowEditor_Functions.getSortedChannelsList channelsList ddl_sortingOptions.selection theIniFileLocation includeCustom:false filterPattern:txt
			getUsedByRendererState()			
		)
		
		on btn_SearchChannels pressed do
		(
			edt_SearchChannels.changed (edt_SearchChannels.text = "")
		)		

		fn RolloutOpen =
		(
			channelsList = MagmaFlowEditor_Functions.loadChannelsList magma mode:#input 
			local theVal = execute (getIniSetting (theIniFileLocation + "MagmaFlowEditor_Preferences.ini") "InputNode" "ChannelSorting" )
			if theVal == OK do theVal = 1
			ddl_sortingOptions.selection = theVal
			updateControls()
			local theID = MagmaFlowEditor_Functions.getNodeID magma MagmaFlowEditor_Rollout.lastNodeClick	
			if magma.getNodeType theID	== "LoopChannel" do MagmaFlowEditor_InputChannelRollout.title = "Loop Input Channel"
		)
		
		on MagmaFlowEditor_InputChannelRollout open do
		(
			RolloutOpen()
		)		
		
	)
	
	rollout MagmaFlowEditor_InputValueRollout "Input Value" category:100
	(
		local theCtrl
		checkbox chk_exposed "Expose" align:#left offset:[-6,0] across:2
		checkbox chk_exposedInBLOP "Expose In BLOP" align:#right offset:[13,0] visible:false
		dropdownlist ddl_ValueType items:#("Vector","Float","Integer") width:70 align:#right offset:[0,-3] 
		
		spinner spn_valueInt "Integer:" range:[-1000000000,1000000000,0] visible:false offset:[0,21] type:#integer controller:CurrentIntController
		spinner spn_value "Float:" range:[-1000000000,1000000000,0] visible:false offset:[0,-21] controller:CurrentFloatController scale:0.01
		
		spinner spn_x "X:" range:[-1000000000,1000000000,0] offset:[0,-42] visible:false controller:CurrentVectorController[1].controller scale:0.01
		spinner spn_y "Y:" range:[-1000000000,1000000000,0] visible:false controller:CurrentVectorController[2].controller scale:0.01
		spinner spn_z "Z:" range:[-1000000000,1000000000,0] visible:false controller:CurrentVectorController[3].controller scale:0.01
		colorpicker clr_color "As Color:" align:#right fieldwidth:72 height:18 color:white offset:[0,0] visible:true alpha:true modal:false 
		colorpicker clr_colorComplementary "Complement:" align:#right fieldwidth:72 height:14 color:black offset:[0,-3] visible:true alpha:true modal:false
		
		button btn_convertToFloat "Convert To Float" width:150 align:#center  tooltip:"Insert a ToFloat Operator to convert the Input value to a Floating Point value."
		button btn_convertToVector "Convert To Vector" width:150 align:#center  offset:[0,-26] tooltip:"Insert a ToVector Operator to convert the Input value to a Vector value."
		button btn_convertVectorX "Extract X" width:50 across:3 offset:[-5,-26] align:#left tooltip:"Insert a Breakout Operator to extract the X component of the Vector value."
		button btn_convertVectorY "Extract Y" width:50 align:#center offset:[0,-26] tooltip:"Insert a Breakout Operator to extract the Y component of the Vector value."
		button btn_convertVectorZ "Extract Z" width:50 align:#right offset:[5,-26] tooltip:"Insert a Breakout Operator to extract the Z component of the Vector value."
		button btn_transformToWorld "To World" width:75 across:2 offset:[-5,-3] align:#left tooltip:"Insert a ToWorld Operator to transform the Vector to world space."
		button btn_transformToView "To Camera" width:75 align:#right offset:[5,-3] tooltip:"Insert a ToView Operator to transform the Vector to view space."
		
		fn updateControls =
		(
			with animate off 
			(
				local currentID = MagmaFlowEditor_Functions.getNodeID magma MagmaFlowEditor_Rollout.lastNodeClick			
				chk_exposed.state = (magma.getNodeProperty currentID "Exposed" ) == true
				chk_exposedInBLOP.state = (magma.getNodeProperty currentID "ExposedInBLOP" ) == true
				chk_exposedInBLOP.visible = (MagmaFlowSettings.NumEditingBLOPs > 0)
				theCtrl = magma.GetNodeProperty currentID "controller"
				local theCtrlIsInt = magma.GetNodeProperty currentID "forceInteger"
				
				if classof theCtrl.value == Point3 do ddl_ValueType.selection = 1  
				if classof theCtrl.value == Float and theCtrlIsInt == false do ddl_ValueType.selection = 2
				if classof theCtrl.value == Float and theCtrlIsInt == true do ddl_ValueType.selection = 3
					
				case ddl_ValueType.selected of
				(
					"Integer" : (
						chk_exposed.visible = btn_convertToFloat.visible = spn_valueInt.visible = ddl_ValueType.visible = true
						spn_value.visible = spn_x.visible = spn_y.visible = spn_z.visible = clr_color.visible = clr_colorComplementary.visible = false
						btn_convertToVector.visible = btn_transformToWorld.visible = btn_transformToView.visible = btn_convertVectorX.visible = btn_convertVectorY.visible = btn_convertVectorZ.visible = false
						spn_valueInt.enabled = true 
						)						
					"Float": (
						chk_exposed.visible = btn_convertToVector.visible = ddl_ValueType.visible = spn_value.visible = true
						spn_x.visible = spn_y.visible = spn_z.visible = clr_color.visible = clr_colorComplementary.visible = false
						btn_convertToFloat.visible = btn_transformToWorld.visible = btn_transformToView.visible = btn_convertVectorX.visible = btn_convertVectorY.visible = btn_convertVectorZ.visible = false
						spn_value.enabled = true 
						)
					"Vector": (
						chk_exposed.visible = ddl_ValueType.visible = spn_x.visible = spn_y.visible = spn_z.visible = clr_color.visible = clr_colorComplementary.visible = true
						btn_convertToVector.visible = btn_convertToFloat.visible = spn_valueInt.visible = spn_value.visible  = false
						clr_color.color = theCtrl.value*255 
						clr_colorComplementary.color = white - clr_color.color
						spn_x.value = theCtrl.value.x
						spn_y.value = theCtrl.value.y
						spn_z.value = theCtrl.value.z
						btn_transformToWorld.visible = btn_transformToView.visible = btn_convertVectorX.visible = btn_convertVectorY.visible = btn_convertVectorZ.visible = true
						spn_x.enabled = spn_y.enabled = spn_z.enabled = (classof theCtrl == point3_xyz)
					)
				)	
			)--end animate off
		)
		
		on btn_convertVectorX pressed do
		(
			MagmaFlowSettings.nodeInsertMode = true
			MagmaFlowEditor_Rollout.createNode "Breakout" insertOutSocket:1 mode:#button
			MagmaFlowEditor_Rollout.setSelectedNodes #(MagmaFlowEditor_Rollout.lastNodeClick)
			MagmaFlowEditor_Rollout.updateMagmaHolder init:true
		)
		on btn_convertVectorY pressed do
		(
			MagmaFlowSettings.nodeInsertMode = true
			MagmaFlowEditor_Rollout.createNode "Breakout" insertOutSocket:2 mode:#button
			MagmaFlowEditor_Rollout.setSelectedNodes #(MagmaFlowEditor_Rollout.lastNodeClick)
			MagmaFlowEditor_Rollout.updateMagmaHolder init:true
		)
		on btn_convertVectorZ pressed do
		(
			MagmaFlowSettings.nodeInsertMode = true
			MagmaFlowEditor_Rollout.createNode "Breakout" insertOutSocket:3 mode:#button
			MagmaFlowEditor_Rollout.setSelectedNodes #(MagmaFlowEditor_Rollout.lastNodeClick)
			MagmaFlowEditor_Rollout.updateMagmaHolder init:true
		)		
		on btn_transformToWorld pressed do
		(
			MagmaFlowSettings.nodeInsertMode = true
			--local currentID = MagmaFlowEditor_Functions.getNodeID magma MagmaFlowEditor_Rollout.lastNodeClick				
			local newID = MagmaFlowEditor_Rollout.createNode "ToWorld" mode:#button
			MagmaFlowEditor_Rollout.setSelectedNodes #(MagmaFlowEditor_Rollout.lastNodeClick)
			MagmaFlowEditor_Rollout.updateMagmaHolder init:true
		)
		on btn_transformToView pressed do
		(
			MagmaFlowSettings.nodeInsertMode = true
			--local currentID = MagmaFlowEditor_Functions.getNodeID magma MagmaFlowEditor_Rollout.lastNodeClick				
			local newID = MagmaFlowEditor_Rollout.createNode "ToCamera" mode:#button
			MagmaFlowEditor_Rollout.setSelectedNodes #(MagmaFlowEditor_Rollout.lastNodeClick)
			MagmaFlowEditor_Rollout.updateMagmaHolder init:true
		)
		
		on btn_convertToFloat pressed do
		(
			MagmaFlowSettings.nodeInsertMode = true
			local currentID = MagmaFlowEditor_Functions.getNodeID magma MagmaFlowEditor_Rollout.lastNodeClick	
			local newID = MagmaFlowEditor_Rollout.createNode "ToFloat" mode:#button
			magma.setNodeInput newID 1 currentID 1
			MagmaFlowEditor_Rollout.setSelectedNodes #(MagmaFlowEditor_Rollout.lastNodeClick)
			MagmaFlowEditor_Rollout.updateMagmaHolder init:true
		)		
		
		on btn_convertToVector pressed do
		(
			MagmaFlowSettings.nodeInsertMode = true
			local currentID = MagmaFlowEditor_Functions.getNodeID magma MagmaFlowEditor_Rollout.lastNodeClick				
			local newID = MagmaFlowEditor_Rollout.createNode "ToVector" mode:#button
			magma.setNodeInput newID 1 currentID 1
			magma.setNodeInput newID 2 currentID 1
			magma.setNodeInput newID 3 currentID 1
			MagmaFlowEditor_Rollout.setSelectedNodes #(MagmaFlowEditor_Rollout.lastNodeClick)
			MagmaFlowEditor_Rollout.updateMagmaHolder init:true
		)
		
		on chk_exposed changed state do
		(
			local currentID = MagmaFlowEditor_Functions.getNodeID magma MagmaFlowEditor_Rollout.lastNodeClick	
			magma.DeclareExtensionProperty currentID "Exposed"
			magma.setNodeProperty currentID "Exposed" state
			MagmaFlowEditor_Rollout.exposeControlsToModifier()
			MagmaFlowEditor_Rollout.createNodeTree init:false
			MagmaFlowEditor_Rollout.createUndoRecord (if state then "Exposed Control" else "Unexposed Control")
		)
		
		on chk_exposedInBLOP changed state do
		(
			local currentID = MagmaFlowEditor_Functions.getNodeID magma MagmaFlowEditor_Rollout.lastNodeClick	
			magma.DeclareExtensionProperty currentID "ExposedInBLOP"		
			magma.setNodeProperty currentID "ExposedInBLOP" state
		)
		
		on spn_valueInt changed val do
		(
			MagmaFlowEditor_Rollout.createNodeTree init:false
			MagmaFlowEditor_Rollout.updateMagmaHolder()
			MagmaFlowEditor_Rollout.debugFlow()
			local currentID = MagmaFlowEditor_Functions.getNodeID magma MagmaFlowEditor_Rollout.lastNodeClick				
			if magma.getNodeProperty currentID "Exposed" == true do
			(
				local theMod = (for i in refs.dependents magma where ( classof i == MagmaModifier or classof i == SpaceMagmaModifier ) and i.magmaHolder == magma collect i)[1]
				if theMod != undefined do 
				(
					try( if theMod.KCM_CA.params.open do modPanel.setCurrentObject theMod )catch()
				)
			)
		)		
		on spn_valueInt entered do
		(
			--storeValues()
			MagmaFlowEditor_Rollout.createUndoRecord ("Integer Value [" + spn_valueInt.value as string + "]")
			MagmaFlowEditor_Rollout.debugFlow()
		)
		
		on spn_value changed val do
		(
			MagmaFlowEditor_Rollout.createNodeTree init:false
			MagmaFlowEditor_Rollout.updateMagmaHolder()
			MagmaFlowEditor_Rollout.debugFlow()
		)
		on spn_value entered do
		(
			--storeValues()
			MagmaFlowEditor_Rollout.createUndoRecord ("Float Value [" + spn_value.value as string + "]")
			MagmaFlowEditor_Rollout.debugFlow()
		)		
		
		on spn_x changed val do
		(
			with animate off 
			(
				clr_color.color.r = val*255
				clr_colorComplementary.color = white - clr_color.color
			)
			MagmaFlowEditor_Rollout.createNodeTree init:false
			with animate off MagmaFlowEditor_Rollout.updateMagmaHolder()			
			MagmaFlowEditor_Rollout.debugFlow()
		)
		on spn_x entered do
		(
			--storeValues()
			MagmaFlowEditor_Rollout.createUndoRecord ("Vector X Value [" + spn_x.value as string + "]")
			MagmaFlowEditor_Rollout.debugFlow()
		)			
		
		on spn_y changed val do
		(
			with animate off 
			(
				clr_color.color.g = val*255
				clr_colorComplementary.color = white - clr_color.color
			)
			MagmaFlowEditor_Rollout.createNodeTree init:false
			with animate off MagmaFlowEditor_Rollout.updateMagmaHolder()			
			MagmaFlowEditor_Rollout.debugFlow()
		)
		on spn_y entered do
		(
			--storeValues()
			MagmaFlowEditor_Rollout.createUndoRecord ("Vector Y Value [" + spn_y.value as string + "]")
			MagmaFlowEditor_Rollout.debugFlow()
		)			
		
		on spn_z changed val do
		(
			with animate off 
			(
				clr_color.color.b = val*255
				clr_colorComplementary.color = white - clr_color.color
			)
			MagmaFlowEditor_Rollout.createNodeTree init:false
			MagmaFlowEditor_Rollout.updateMagmaHolder()
			MagmaFlowEditor_Rollout.debugFlow()
		)	
		on spn_z entered do
		(
			--storeValues()
			MagmaFlowEditor_Rollout.createUndoRecord ("Vector Z Value [" + spn_z.value as string + "]")
			MagmaFlowEditor_Rollout.debugFlow()
		)			
		
		on clr_color changed val do
		(
			theCtrl.value = clr_color.color/255.0
			spn_x.value = clr_color.color.r/255.0
			spn_y.value = clr_color.color.g/255.0
			spn_z.value = clr_color.color.b/255.0
			clr_colorComplementary.color = white - clr_color.color
			MagmaFlowEditor_Rollout.createNodeTree init:false
			MagmaFlowEditor_Rollout.createUndoRecord ("Color ["+ (val as Point3) as string + "]")
			MagmaFlowEditor_Rollout.updateMagmaHolder()
			MagmaFlowEditor_Rollout.debugFlow()
		)
		
		on clr_colorComplementary changed val do
		(
			clr_color.color = white - val
			theCtrl.value = clr_color.color/255.0
			
			spn_x.value = clr_color.color.r/255.0
			spn_y.value = clr_color.color.g/255.0
			spn_z.value = clr_color.color.b/255.0
			MagmaFlowEditor_Rollout.createNodeTree init:false
			MagmaFlowEditor_Rollout.createUndoRecord ("Color ["+ (clr_color.color as Point3) as string + "]")
			MagmaFlowEditor_Rollout.updateMagmaHolder()
			MagmaFlowEditor_Rollout.debugFlow()
		)	

		
		fn ddl_ValueType_SelectedFN itm =
		(
			local needExposureUpdate = false
			local theOldID = MagmaFlowEditor_Functions.getNodeID magma MagmaFlowEditor_Rollout.lastNodeClick	
			local oldValClass = classof (magma.getNodeProperty theOldID "controller").value
			local theOldType = #Float
			if oldValClass == Point3 then 
				theOldType = #Vector
			else
				if (magma.getNodeProperty theOldID "forceInteger") == true do theOldType = #Integer
			
			if theOldType == #Integer and ddl_ValueType.selected as name == #Float or theOldType == #Float and ddl_ValueType.selected as name == #Integer then
			(
				magma.SetNodeProperty theOldID "forceInteger" (ddl_ValueType.selected as name == #Integer)
			)
			else if theOldType != ddl_ValueType.selected as name do
			(
				local extendedProps = magma.GetNodePropertyNames theOldID #custom
				local oldPropValues = for p in extendedProps collect magma.getNodeProperty theOldID p
				local oldConnections = magmaFlowEditor_Functions.GetConnectedNodes magma theOldID
				
				--theNewID = magma.CreateNode "InputValue"
				theOldCtrl = magma.GetNodeProperty theOldID "controller"
				--magma.ReplaceNode theOldID theNewID
				
				case ddl_ValueType.selected as name of
				(
					#Float:
					(
						local theCtrl = bezier_float(); theCtrl.value = 1.0
						if classof theOldCtrl == Point3_xyz do theCtrl = copy theOldCtrl[1].controller
						magma.SetNodeProperty theOldID "controller" theCtrl
					)
					#Integer:
					(
						local theCtrl = bezier_float(); theCtrl.value = 1.0
						if classof theOldCtrl == Point3_xyz do theCtrl = copy theOldCtrl[1].controller
						magma.SetNodeProperty theOldID "controller" theCtrl
						magma.SetNodeProperty theOldID "forceInteger" true
					)
					#Vector:
					(
						local theCtrl = point3_xyz(); theCtrl.value = [0,0,0]
						if classof theOldCtrl == bezier_float do 
						(
							theCtrl[1].controller = copy theOldCtrl
							theCtrl[2].controller = copy theOldCtrl
							theCtrl[3].controller = copy theOldCtrl
						)
						magma.SetNodeProperty theOldID "controller" theCtrl
					)							
				)							
				
				for i = 1 to extendedProps.count do 
				(
					magma.DeclareExtensionProperty theOldID extendedProps[i]
					magma.setNodeProperty theOldID extendedProps[i] oldPropValues[i]
					if extendedProps[i] == "Exposed" and oldPropValues[i] == true do needExposureUpdate = true
				)
				
				magma.DeclareExtensionProperty theOldID "Position" 
				
				for c = 1 to oldConnections.count do
					for j in oldConnections[c] do 
						magma.setNodeInput j[1] j[2] theOldID c
				
			)
			
			MagmaFlowEditor_Rollout.lastNodeClick = findItem (magma.getNodes()) theOldID
			MagmaFlowEditor_Rollout.createNodeTree init:true	
			--updateControls()			
			MagmaFlowEditor_Rollout.displaySelectedNodeProperties()
			
			MagmaFlowEditor_Rollout.createUndoRecord ("Value Type [" + ddl_ValueType.selected + "]")
			if needExposureUpdate do 
				MagmaFlowEditor_Rollout.exposeControlsToModifier()
			MagmaFlowEditor_Rollout.updateMagmaHolder()
			
			setFocus MagmaFlowEditor_Rollout.hc
			MagmaFlowEditor_Rollout.debugFlow()
		)
		
		
		on ddl_ValueType selected itm do 
		(
			ddl_ValueType_SelectedFN itm
		)			
		
		fn RolloutOpen =
		(
			updateControls()
		)
		
		on MagmaFlowEditor_InputValueRollout open do
		(
			RolloutOpen()
		)
	)
	
	rcmenu MagmaFlowEditor_Zoom_RCMenu
	(
		menuItem mnu_resetPanAndZoom "Reset Pan and Zoom"
		separator sep_10
		menuItem mnu_resetPan "Reset Pan (Shift+X)"
		menuItem mnu_resetZoom "Reset Zoom (X)"
		separator sep_20
		menuItem mnu_zoomSelected "Zoom Selected (Shift+Z)"
		menuItem mnu_zoomExtents "Zoom Extents (Z)"

		on mnu_resetPanAndZoom picked do
		(
			MagmaFlowEditor_Rollout.resetPanFactor update:false  createUndo:false
			MagmaFlowEditor_Rollout.resetZoomFactor update:false createUndo:false
			MagmaFlowEditor_Rollout.createUndoRecord ("Reset Pan and Zoom")			
			MagmaFlowEditor_Rollout.createNodeTree init:false			
			MagmaFlowEditor_Rollout.updateNavigator fullUpdate:false
			MagmaFlowEditor_Rollout.storePanAndZoom()
		)
		on mnu_resetPan picked do
		(
			MagmaFlowEditor_Rollout.resetPanFactor()
			MagmaFlowEditor_Rollout.storePanAndZoom() 

		)
		on mnu_resetZoom picked do
		(
			MagmaFlowEditor_Rollout.resetZoomFactor()
			MagmaFlowEditor_Rollout.storePanAndZoom()
		)
		on mnu_zoomSelected picked do
		(
			MagmaFlowEditor_Rollout.ZoomExtentsSelected()
			MagmaFlowEditor_Rollout.storePanAndZoom()
		)
		on mnu_zoomExtents picked do
		(
			MagmaFlowEditor_Rollout.ZoomExtents()
			MagmaFlowEditor_Rollout.storePanAndZoom()
		)		
	)
	
	rcmenu MagmaFlowEditor_Rollout_MainMenu
	(
		fn CanPasteFromWindowsClipboard = 
		(
			local clipboardClass = dotNetClass "System.Windows.Forms.Clipboard" 
			local theFlowScript = clipboardClass.GetText()
			matchPattern theFlowScript pattern:"(--MAGMAFLOW2--*"			
		)
		
		fn CanPasteFromWindowsClipboardAndKeepWires =
		(
			local clipboardClass = dotNetClass "System.Windows.Forms.Clipboard" 
			local theFlowScript = clipboardClass.GetText()
			matchPattern theFlowScript pattern:"(--MAGMAFLOW2--*" AND trackID == ::magmaClipBoardId
		)			
		
		subMenu "File"
		(
			menuitem mnu_new "&New..."
			separator sep_file_10
			menuitem mnu_replacemxs "Load And &Replace MAXScript Flow..."
			menuitem mnu_mergemxs "Load And &Merge MAXScript Flow..."
			separator sep_file_20
			menuitem mnu_open "&Import Magma 1.x KMF Flow..."
			separator sep_file_30
			menuitem mnu_exportasmxs "Save &Flow As MAXScript..."
			menuItem mnu_exportSelectedAsMXS "Save &Selected Nodes As MAXScript..."
			separator sep_file_40
			menuItem mnu_exploreFolder "&Explore Flows Folder..."
			separator sep_file_50
			menuitem mnu_close "&Close... (Ctrl+Q)"
		)
		subMenu "Edit"
		(
			menuitem mnu_undo "Undo (Ctrl+Z)" enabled:MagmaFlowEditor_Rollout.btn_undo.enabled
			menuitem mnu_redo "Redo (Ctrl+Y)" enabled:MagmaFlowEditor_Rollout.btn_redo.enabled
			separator sep_10
			menuItem mnu_copyToClipboard "Copy (Ctrl+C)" enabled:((MagmaFlowEditor_Rollout.getSelectedNodes()).count > 0)
			menuItem mnu_pasteFromClipboard "Paste (Ctrl+V)" enabled:(CanPasteFromWindowsClipboard())
			menuItem mnu_pasteFromClipboardAndKeepWires "Paste And Preserve Connections (Ctrl+Alt+V)" enabled:(CanPasteFromWindowsClipboardAndKeepWires())
			separator sep_20
			menuitem mnu_insertMode "Branch/Insert Mode Toggle (Ins)" checked:(MagmaFlowSettings.nodeInsertMode != true)
			separator sep_25
			menuitem mnu_selectAllNodes "Select All Nodes (Ctrl+A)" 
			menuitem mnu_invertSelection "Invert Selection (Ctrl+I)"
			menuitem mnu_deselectAllNodes "Deselect All Nodes (Ctrl+D)" 
			separator sep_30
			menuitem mnu_selectUnconnectedNodes "Select Unconnected Nodes (Ctrl+U)" 
			/*
			menuitem mnu_selectDisabledNodes "Select Disabled Nodes (Ctrl+Shift+U)" 
			menuitem mnu_selectInputNodesOnly "Select All Input Nodes" 
			menuitem mnu_selectOperatorNodesOnly "Select All Operator Nodes" 
			menuitem mnu_selectBlackOpNodesOnly "Select All BlackOp Nodes" 
			separator sep_40
			menuitem mnu_growSelectionChildren "Grow Selection - Add Children (Shift+PgDn)" 
			menuitem mnu_growSelectionParents "Grow Selection - Add Parents (Shift+PgUp)" 
*/				
			separator sep_50
			menuitem mnu_exitBlop "Exit BLOP Editing" enabled:(MagmaFlowSettings.NumEditingBLOPs > 0)
			separator sep_60
			menuitem mnu_deleteSelectedNodes "Remove Selected Nodes (<--Backspace)"
		)

		on mnu_deleteSelectedNodes picked do
		(
			MagmaFlowEditor_Rollout.deleteSelectedNodes()
		)		
		
		/*
		submenu "View"
		(
			menuItem mnu_resetPanAndZoom "Reset Pan and Zoom"
			separator sep_510
			menuItem mnu_resetPan "Reset Pan"
			menuItem mnu_resetZoom "Reset Zoom"
			separator sep_520
			menuItem mnu_zoomSelected "Zoom Selected"
			menuItem mnu_zoomExtents "Zoom Extents"

			
			on mnu_resetPanAndZoom picked do
			(
				MagmaFlowEditor_Rollout.resetPanFactor update:false  createUndo:false
				MagmaFlowEditor_Rollout.resetZoomFactor update:false createUndo:false
				MagmaFlowEditor_Rollout.createUndoRecord ("Reset Pan and Zoom")			
				MagmaFlowEditor_Rollout.createNodeTree init:false			
				MagmaFlowEditor_Rollout.updateNavigator fullUpdate:false
				MagmaFlowEditor_Rollout.storePanAndZoom()
			)
			on mnu_resetPan picked do
			(
				MagmaFlowEditor_Rollout.resetPanFactor()
				MagmaFlowEditor_Rollout.storePanAndZoom() 

			)
			on mnu_resetZoom picked do
			(
				MagmaFlowEditor_Rollout.resetZoomFactor()
				MagmaFlowEditor_Rollout.storePanAndZoom()
			)
			on mnu_zoomSelected picked do
			(
				MagmaFlowEditor_Rollout.ZoomExtentsSelected()
				MagmaFlowEditor_Rollout.storePanAndZoom()
			)
			on mnu_zoomExtents picked do
			(
				MagmaFlowEditor_Rollout.ZoomExtents()
				MagmaFlowEditor_Rollout.storePanAndZoom()
			)	
			
		)
		*/
		


		subMenu "View"
		(
			menuitem mnu_autoReorderToggle "Auto-Reorder - Toggle (Ctrl+R)" checked:MagmaFlowSettings.AutoReorderToggle 
			menuitem mnu_acceptAutoOrder "Accept Auto-Reorder Results as Free Order (Ctrl+Shift+R)" enabled:MagmaFlowSettings.AutoReorderToggle 
			separator sep_105
			subMenu "Reorder Patterns..."
			(
				menuitem mnu_autoReorderTail "Tail Pattern" checked:(MagmaFlowSettings.AutoReorderPattern == #tail)
				menuitem mnu_autoReorderRow "Row Pattern" checked:(MagmaFlowSettings.AutoReorderPattern == #row)
				menuitem mnu_autoReorderBlock2 "Block 2 Pattern" checked:(MagmaFlowSettings.AutoReorderPattern == #block and MagmaFlowSettings.AutoReorderBlockHeight == 2)
				menuitem mnu_autoReorderBlock3 "Block 3 Pattern" checked:(MagmaFlowSettings.AutoReorderPattern == #block and MagmaFlowSettings.AutoReorderBlockHeight == 3)
				menuitem mnu_autoReorderBlock4 "Block 4 Pattern" checked:(MagmaFlowSettings.AutoReorderPattern == #block and MagmaFlowSettings.AutoReorderBlockHeight == 4)
			)	
			
			separator sep_130
			menuItem mnu_InputsOnTheLeft "Place INPUTS On The LEFT (Ctrl+Shift+L)" checked:(MagmaFlowSettings.InputsOnTheLeftAll  == true)
			subMenu "Inputs On The Left Options"
			(
				menuItem mnu_InputsOnTheLeftALL "Check All"  
				menuItem mnu_InputsOnTheLeftINVERT "Invert"
				separator sep_132
				menuItem mnu_InputsOnTheLeftValue "Place VALUE Inputs On The Left"  checked:(MagmaFlowSettings.InputsOnTheLeftValue  == true)
				menuItem mnu_InputsOnTheLeftChannel "Place CHANNEL Inputs On The Left"  checked:(MagmaFlowSettings.InputsOnTheLeftChannel  == true)
				menuItem mnu_InputsOnTheLeftObject "Place OBJECT Inputs On The Left"  checked:(MagmaFlowSettings.InputsOnTheLeftObject  == true)
				menuItem mnu_InputsOnTheLeftGeometry "Place GEOMETRY Inputs On The Left"  checked:(MagmaFlowSettings.InputsOnTheLeftGeometry  == true)
				menuItem mnu_InputsOnTheLeftParticles "Place PARTICLES Inputs On The Left"  checked:(MagmaFlowSettings.InputsOnTheLeftParticles  == true)
				menuItem mnu_InputsOnTheLeftScript "Place SCRIPT Inputs On The Left"  checked:(MagmaFlowSettings.InputsOnTheLeftScript  == true)
				separator sep_135
				menuItem mnu_InputsOnTheLeftSetDefault "Set As DEFAULT For New Modifiers"
			)
			menuItem mnu_outputNodesOnRight "Place OUTPUTS On The RIGHT (Ctrl+Shift+O)" checked:(MagmaFlowSettings.outputNodesOnRight == true)
			
			separator sep_140
			menuItem mnu_AlignAllNodesToGrid "ALIGN All Nodes To Grid (Ctrl+Shift+A)" 
			menuItem mnu_SnapToGrid "SNAP To Grid - Toggle (Ctrl+G)" checked:MagmaFlowSettings.SnapToGrid
			

			
			/*
			separator sep_140
			menuitem mnu_AutoZoomExtents "Auto-Zoom Extents - Toggle" checked:MagmaFlowSettings.AutoZoomExtents
			menuItem mnu_ZoomExtents "Zoom Extents (Z)"
			menuItem mnu_ZoomExtentsSelected "Zoom Extents Selected (Shift+Z)"			
			separator sep_150
			menuItem mnu_resetZoom "Reset Zoom (X)"
			menuitem mnu_resetPan "Reset Pan (Shift+X)"
			*/
			
			
			separator sep_160
			subMenu "Depot Display..."
			(
				menuItem mnu_DepotOff "Depot Off" checked: (MagmaFlowSettings.DepotPlacement == #off)
				menuItem mnu_DepotLeft "Depot On Left" checked: (MagmaFlowSettings.DepotPlacement == #left)
				menuItem mnu_DepotBottom "Depot At Bottom" checked: (MagmaFlowSettings.DepotPlacement == #bottom)
				--menuItem mnu_DepotBottomRollup "Depot At Bottom - Rollup" checked: (MagmaFlowSettings.DepotPlacement == #bottomrollup)
				menuItem mnu_DepotBottomRollupReverse "Depot At Bottom - Rollup" checked: (MagmaFlowSettings.DepotPlacement == #bottomrollupreverse)
				separator sep_180
				menuItem mnu_DepotShowBLOPs "Show BlackOp Categories In Depot" checked:MagmaFlowSettings.DepotShowBLOPs
				separator sep_185
				menuItem mnu_DepotShowCategories "Use Depot Categories" checked:MagmaFlowSettings.DepotShowCategories
				menuItem mnu_DepotAutoCollapseOnDragAndDrop "Auto-Collapse Categories On DragAndDrop" checked:MagmaFlowSettings.DepotAutoCollapseOnDragAndDrop
			)	
		)
		
		subMenu "Options"
		(
			menuItem mnu_SwapDefaultsOnInputSwap "Swap Default Values On Input Swap" checked: (MagmaFlowSettings.SwapDefaultsOnInputSwap == true)
			separator sep_110
			subMenu "Unconnected Nodes Auto-Placement..."
			(
				menuItem mnu_nodesLeft "Left Side Of Flow" checked: (MagmaFlowSettings.UnconnectedNodesPlacement == #left)
				menuItem mnu_nodesBottom "Bottom Of Flow" checked: (MagmaFlowSettings.UnconnectedNodesPlacement == #bottom)
			)		
			separator sep_120
			menuItem mnu_showInputSocketName "Show NAMES Of Connected Input Sockets" checked:(MagmaFlowSettings.showInputSocketName == true)
			menuItem mnu_showInputSocketValue "Show VALUES Of Connected Input Socket" checked:(MagmaFlowSettings.showInputSocketValue == true)
			
			menuItem mnu_showTextureMapSample "Show Texture Map SAMPLES In Nodes" checked:(MagmaFlowSettings.showTextureMapSample == true)
			menuItem mnu_showColorSwatchSample "Show COLOR SWATCHES In InputVector Nodes" checked:(MagmaFlowSettings.showColorSwatchSample == true)
			
			menuItem mnu_AllowSubtreeCollapsing "Allow Sub-Tree COLLAPSING On Double-Click" checked:(MagmaFlowSettings.AllowSubtreeCollapsing == true)
		)		
		
		on mnu_SwapDefaultsOnInputSwap picked do
		(
			MagmaFlowSettings.SwapDefaultsOnInputSwap = not MagmaFlowSettings.SwapDefaultsOnInputSwap 
			setIniSetting (theIniFileLocation + "MagmaFlowEditor_Preferences.ini") "Options" "SwapDefaultsOnInputSwap" (MagmaFlowSettings.SwapDefaultsOnInputSwap as string)
		)

		on mnu_autoReorderTail picked do 
		(
			MagmaFlowSettings.AutoReorderPattern = #tail
			MagmaFlowEditor_Rollout.reorder_dot()
			MagmaFlowEditor_Rollout.createNodeTree init:false		
			MagmaFlowEditor_Rollout.updateNavigator()			
		)
		on mnu_autoReorderRow picked do 
		(
			MagmaFlowSettings.AutoReorderPattern = #row
			MagmaFlowEditor_Rollout.reorder_dot()
			MagmaFlowEditor_Rollout.createNodeTree init:false		
			MagmaFlowEditor_Rollout.updateNavigator()			
		)		
		on mnu_autoReorderBlock2 picked do 
		(
			MagmaFlowSettings.AutoReorderPattern = #block
			MagmaFlowSettings.AutoReorderBlockHeight = 2
			MagmaFlowEditor_Rollout.reorder_dot()
			MagmaFlowEditor_Rollout.createNodeTree init:false		
			MagmaFlowEditor_Rollout.updateNavigator()			
		)
		on mnu_autoReorderBlock3 picked do 
		(
			MagmaFlowSettings.AutoReorderPattern = #block
			MagmaFlowSettings.AutoReorderBlockHeight = 3
			MagmaFlowEditor_Rollout.reorder_dot()
			MagmaFlowEditor_Rollout.createNodeTree init:false		
			MagmaFlowEditor_Rollout.updateNavigator()			
		)		
		on mnu_autoReorderBlock4 picked do 
		(
			MagmaFlowSettings.AutoReorderPattern = #block
			MagmaFlowSettings.AutoReorderBlockHeight = 4
			MagmaFlowEditor_Rollout.reorder_dot()
			MagmaFlowEditor_Rollout.createNodeTree init:false		
			MagmaFlowEditor_Rollout.updateNavigator()			
		)		
		
		
		on mnu_outputNodesOnRight picked do
		(
			MagmaFlowSettings.outputNodesOnRight = not MagmaFlowSettings.outputNodesOnRight 
			MagmaFlowEditor_Functions.setEditorProperty magma "OutputNodesOnRight" (MagmaFlowSettings.outputNodesOnRight as string)
			MagmaFlowEditor_Rollout.createNodeTree init:false		
--			MagmaFlowEditor_Rollout.updateNavigator()			
		)		
		on mnu_InputsOnTheLeft picked do
		(
			MagmaFlowSettings.InputsOnTheLeftAll = not MagmaFlowSettings.InputsOnTheLeftAll 
			MagmaFlowEditor_Functions.setEditorProperty magma "InputsOnTheLeftAll" (MagmaFlowSettings.InputsOnTheLeftAll as string)
			MagmaFlowEditor_Rollout.createNodeTree init:false		
			MagmaFlowEditor_Rollout.updateNavigator()			
		)
		on mnu_InputsOnTheLeftValue picked do
		(
			MagmaFlowSettings.InputsOnTheLeftValue = not MagmaFlowSettings.InputsOnTheLeftValue 
			MagmaFlowEditor_Functions.setEditorProperty magma "InputsOnTheLeftValue" (MagmaFlowSettings.InputsOnTheLeftValue as string)
			MagmaFlowEditor_Rollout.createNodeTree init:false		
			MagmaFlowEditor_Rollout.updateNavigator()			
		)
		on mnu_InputsOnTheLeftChannel picked do
		(
			MagmaFlowSettings.InputsOnTheLeftChannel = not MagmaFlowSettings.InputsOnTheLeftChannel 
			MagmaFlowEditor_Functions.setEditorProperty magma "InputsOnTheLeftChannel" (MagmaFlowSettings.InputsOnTheLeftChannel as string)
			MagmaFlowEditor_Rollout.createNodeTree init:false		
			MagmaFlowEditor_Rollout.updateNavigator()			
		)
		on mnu_InputsOnTheLeftObject picked do
		(
			MagmaFlowSettings.InputsOnTheLeftObject = not MagmaFlowSettings.InputsOnTheLeftObject 
			MagmaFlowEditor_Functions.setEditorProperty magma "InputsOnTheLeftObject" (MagmaFlowSettings.InputsOnTheLeftObject as string)
			MagmaFlowEditor_Rollout.createNodeTree init:false			
			MagmaFlowEditor_Rollout.updateNavigator()			
		)		
		on mnu_InputsOnTheLeftGeometry picked do
		(
			MagmaFlowSettings.InputsOnTheLeftGeometry = not MagmaFlowSettings.InputsOnTheLeftGeometry 
			MagmaFlowEditor_Functions.setEditorProperty magma "InputsOnTheLeftGeometry" (MagmaFlowSettings.InputsOnTheLeftGeometry as string)
			MagmaFlowEditor_Rollout.createNodeTree init:false		
			MagmaFlowEditor_Rollout.updateNavigator()			
		)		
		on mnu_InputsOnTheLeftParticles picked do
		(
			MagmaFlowSettings.InputsOnTheLeftParticles = not MagmaFlowSettings.InputsOnTheLeftParticles 
			MagmaFlowEditor_Functions.setEditorProperty magma "InputsOnTheLeftParticles" (MagmaFlowSettings.InputsOnTheLeftParticles as string)
			MagmaFlowEditor_Rollout.createNodeTree init:false	
			MagmaFlowEditor_Rollout.updateNavigator()			
		)	
		on mnu_InputsOnTheLeftScript picked do
		(
			MagmaFlowSettings.InputsOnTheLeftScript = not MagmaFlowSettings.InputsOnTheLeftScript 
			MagmaFlowEditor_Functions.setEditorProperty magma "InputsOnTheLeftScript" (MagmaFlowSettings.InputsOnTheLeftScript as string)
			MagmaFlowEditor_Rollout.createNodeTree init:false		
			MagmaFlowEditor_Rollout.updateNavigator()			
		)	
		on mnu_InputsOnTheLeftALL picked do
		(
			MagmaFlowSettings.InputsOnTheLeftValue = MagmaFlowSettings.InputsOnTheLeftChannel =MagmaFlowSettings.InputsOnTheLeftObject =MagmaFlowSettings.InputsOnTheLeftGeometry =MagmaFlowSettings.InputsOnTheLeftParticles =MagmaFlowSettings.InputsOnTheLeftScript = true
			MagmaFlowEditor_Functions.setEditorProperty magma "InputsOnTheLeftValue" (MagmaFlowSettings.InputsOnTheLeftValue as string)
			MagmaFlowEditor_Functions.setEditorProperty magma "InputsOnTheLeftChannel" (MagmaFlowSettings.InputsOnTheLeftChannel as string)
			MagmaFlowEditor_Functions.setEditorProperty magma "InputsOnTheLeftObject" (MagmaFlowSettings.InputsOnTheLeftObject as string)
			MagmaFlowEditor_Functions.setEditorProperty magma "InputsOnTheLeftGeometry" (MagmaFlowSettings.InputsOnTheLeftGeometry as string)
			MagmaFlowEditor_Functions.setEditorProperty magma "InputsOnTheLeftParticles" (MagmaFlowSettings.InputsOnTheLeftParticles as string)
			MagmaFlowEditor_Functions.setEditorProperty magma "InputsOnTheLeftScript" (MagmaFlowSettings.InputsOnTheLeftScript as string)
			MagmaFlowEditor_Rollout.createNodeTree init:false		
			MagmaFlowEditor_Rollout.updateNavigator()			
		)
		on mnu_InputsOnTheLeftINVERT picked do
		(
			MagmaFlowSettings.InputsOnTheLeftValue = not MagmaFlowSettings.InputsOnTheLeftValue 
			MagmaFlowSettings.InputsOnTheLeftChannel = not MagmaFlowSettings.InputsOnTheLeftChannel 
			MagmaFlowSettings.InputsOnTheLeftObject = not MagmaFlowSettings.InputsOnTheLeftObject 
			MagmaFlowSettings.InputsOnTheLeftGeometry = not MagmaFlowSettings.InputsOnTheLeftGeometry 
			MagmaFlowSettings.InputsOnTheLeftParticles = not MagmaFlowSettings.InputsOnTheLeftParticles 
			MagmaFlowSettings.InputsOnTheLeftScript = not MagmaFlowSettings.InputsOnTheLeftScript 
			MagmaFlowEditor_Functions.setEditorProperty magma "InputsOnTheLeftValue" (MagmaFlowSettings.InputsOnTheLeftValue as string)
			MagmaFlowEditor_Functions.setEditorProperty magma "InputsOnTheLeftChannel" (MagmaFlowSettings.InputsOnTheLeftChannel as string)
			MagmaFlowEditor_Functions.setEditorProperty magma "InputsOnTheLeftObject" (MagmaFlowSettings.InputsOnTheLeftObject as string)
			MagmaFlowEditor_Functions.setEditorProperty magma "InputsOnTheLeftGeometry" (MagmaFlowSettings.InputsOnTheLeftGeometry as string)
			MagmaFlowEditor_Functions.setEditorProperty magma "InputsOnTheLeftParticles" (MagmaFlowSettings.InputsOnTheLeftParticles as string)
			MagmaFlowEditor_Functions.setEditorProperty magma "InputsOnTheLeftScript" (MagmaFlowSettings.InputsOnTheLeftScript as string)
			MagmaFlowEditor_Rollout.createNodeTree init:false		
			MagmaFlowEditor_Rollout.updateNavigator()			
		)	

		on mnu_InputsOnTheLeftSetDefault picked do
		(
			local theIniFile = (theIniFileLocation + "MagmaFlowEditor_Preferences.ini")
			setIniSetting theIniFile "InputsOnLeft" "Value" (MagmaFlowSettings.InputsOnTheLeftValue as string)
			setIniSetting theIniFile "InputsOnLeft" "Channel" (MagmaFlowSettings.InputsOnTheLeftChannel as string)
			setIniSetting theIniFile "InputsOnLeft" "Object" (MagmaFlowSettings.InputsOnTheLeftObject as string)
			setIniSetting theIniFile "InputsOnLeft" "Geometry" (MagmaFlowSettings.InputsOnTheLeftGeometry as string)
			setIniSetting theIniFile "InputsOnLeft" "Particles" (MagmaFlowSettings.InputsOnTheLeftParticles as string)
			setIniSetting theIniFile "InputsOnLeft" "Script" (MagmaFlowSettings.InputsOnTheLeftScript as string)
		)

		on mnu_SnapToGrid picked do
		(
			MagmaFlowEditor_Rollout.toggleSnapToGrid()
		)
		
		on mnu_DepotAutoCollapseOnDragAndDrop picked do 
		(
			MagmaFlowSettings.DepotAutoCollapseOnDragAndDrop = not MagmaFlowSettings.DepotAutoCollapseOnDragAndDrop
			MagmaFlowEditor_Rollout.CreateDepot()
			MagmaFlowEditor_Rollout.updateDepotDefinition()
			MagmaFlowEditor_Rollout.createNodeTree init:true			
		)	

		on mnu_DepotShowCategories picked do 
		(
			MagmaFlowSettings.DepotShowCategories = not MagmaFlowSettings.DepotShowCategories
			if not MagmaFlowSettings.DepotShowCategories and (MagmaFlowSettings.DepotPlacement == #bottomrollup or MagmaFlowSettings.DepotPlacement == #bottomrollupreverse) do 
			(
				MagmaFlowSettings.DepotPlacement = #bottom
			)	
			MagmaFlowEditor_Rollout.updateDepotDefinition()
			MagmaFlowEditor_Rollout.createNodeTree init:true			
		)			
		
		on mnu_nodesLeft picked do 
		(
			MagmaFlowSettings.UnconnectedNodesPlacement = #left
			MagmaFlowEditor_Rollout.autoReorderFlow()
			MagmaFlowEditor_Rollout.updateNavigator()
		)
		on mnu_nodesBottom picked do 
		(
			MagmaFlowSettings.UnconnectedNodesPlacement = #bottom
			MagmaFlowEditor_Rollout.autoReorderFlow()
			MagmaFlowEditor_Rollout.updateNavigator()
		)
		
		on mnu_selectAllNodes picked do MagmaFlowEditor_Rollout.selectAllNodes()
		on mnu_invertSelection picked do MagmaFlowEditor_Rollout.invertSelection()
		on mnu_deselectAllNodes picked do MagmaFlowEditor_Rollout.deselectAllNodes()
		on mnu_selectUnconnectedNodes picked do MagmaFlowEditor_Rollout.selectUnconnectedNodes()
		
		on mnu_AllowSubtreeCollapsing picked do
		(
			MagmaFlowSettings.AllowSubtreeCollapsing  = not MagmaFlowSettings.AllowSubtreeCollapsing
			setIniSetting (theIniFileLocation + "MagmaFlowEditor_Preferences.ini") "Options" "AllowSubtreeCollapsing" (MagmaFlowSettings.AllowSubtreeCollapsing as string)
			MagmaFlowEditor_Rollout.collapseBranches()
			MagmaFlowEditor_Rollout.createNodeTree init:true
		)
		
		on mnu_showTextureMapSample picked do 
		(
			MagmaFlowSettings.showTextureMapSample = not MagmaFlowSettings.showTextureMapSample 
			setIniSetting (theIniFileLocation + "MagmaFlowEditor_Preferences.ini") "Options" "ShowTextureMapSample" (MagmaFlowSettings.ShowTextureMapSample as string)
			MagmaFlowEditor_Rollout.createNodeTree init:true
			MagmaFlowEditor_Rollout.autoReorderFlow()
			MagmaFlowEditor_Rollout.updateNavigator()
		)
		on mnu_showColorSwatchSample picked do 
		(
			MagmaFlowSettings.showColorSwatchSample = not MagmaFlowSettings.showColorSwatchSample 
			setIniSetting (theIniFileLocation + "MagmaFlowEditor_Preferences.ini") "Options" "ShowColorSwatchSample" (MagmaFlowSettings.ShowColorSwatchSample as string)
			MagmaFlowEditor_Rollout.createNodeTree init:true
			MagmaFlowEditor_Rollout.autoReorderFlow()
			MagmaFlowEditor_Rollout.updateNavigator()
		)
		
		on mnu_showInputSocketName picked do 
		(
			MagmaFlowSettings.showInputSocketName = not MagmaFlowSettings.showInputSocketName 
			setIniSetting (theIniFileLocation + "MagmaFlowEditor_Preferences.ini") "Options" "ShowInputSocketName" (MagmaFlowSettings.ShowInputSocketName as string)
			
			MagmaFlowEditor_Rollout.createNodeTree init:false
		)
		on mnu_showInputSocketValue picked do 
		(
			MagmaFlowSettings.showInputSocketValue = not MagmaFlowSettings.showInputSocketValue
			setIniSetting (theIniFileLocation + "MagmaFlowEditor_Preferences.ini") "Options" "ShowInputSocketValue" (MagmaFlowSettings.ShowInputSocketValue as string)
			MagmaFlowEditor_Rollout.createNodeTree init:false
		)
		
		on mnu_close picked do
		(
			destroyDialog MagmaFlowEditor_Rollout
		)
		
		on mnu_new picked do
		(
			if needToSave then
			(
				local q = querybox ("Changes to the current flow have not been saved.\n\nDo you want to SAVE the current flow to disk\nbefore starting a new one?") title:"SAVE Changes?"
				if q do MagmaFlowEditor_Rollout.saveFlowToDisk()
			)
			if (querybox "Are you sure you want to RESET the flow and start a NEW one?" title:"Start NEW Flow?") do
			(
				MagmaFlowEditor_Rollout.closeAllCurveEditors()
				magma.reset()
				MagmaFlowEditor_Rollout.exposeControlsToModifier()
				MagmaFlowEditor_Rollout.createNodeTree init:true
				MagmaFlowEditor_Rollout.displaySelectedNodeProperties()
				MagmaFlowEditor_Rollout.createUndoRecord "New Flow"
				needToSave = false
				currentPreset = ""
				MagmaFlowEditor_Rollout.updateModifierName()
				MagmaFlowEditor_Rollout.updateEditorTitle()
			)
		)
		
		on mnu_open picked do
		(
			if needToSave then
			(
				local q = querybox ("Changes to the current flow have not been saved.\n\nDo you want to SAVE the current flow to disk\nbefore importing a new one?") title:"SAVE Changes?"
				if q do MagmaFlowEditor_Rollout.saveFlowToDisk()
			)
			
			makeDir (thePresetsFolder) all:true
			local theFileName = getOpenFileName caption:"Load Krakatoa MagmaFlow File" filename:thePresetsFolder types:"Krakatoa MagmaFlow File (*.KMF)|*.KMF|All Files (*.*)|*.*" historyCategory:"MagmaFlows"
			if theFileName != undefined do
			(
				for i in EditableBlopStack do magma.PopEditableBLOP()
				EditableBlopStack = #()				
				MagmaFlowEditor_Functions.convertKMF magma theFile:theFileName 
				MagmaFlowEditor_Rollout.createNodeTree init:true
				MagmaFlowEditor_Rollout.exposeControlsToModifier()
				MagmaFlowEditor_Rollout.autoReorderFlow()
				MagmaFlowEditor_Rollout.updateNavigator fullUpdate:true
				MagmaFlowEditor_Rollout.displaySelectedNodeProperties()
				MagmaFlowEditor_Rollout.createUndoRecord ("Load Flow ["+filenameFromPath theFileName+"]")
				needToSave = false
				currentPreset = ""		
				MagmaFlowEditor_Rollout.updateEditorTitle()				
			)
		)

		on mnu_AlignAllNodesToGrid picked do MagmaFlowEditor_Rollout.alignAllNodesToGrid()
		on mnu_autoReorderFlow picked do MagmaFlowEditor_Rollout.reorder_dot()
		
		on mnu_exitBlop picked do
		(
			if (magma.NumEditingBLOPs() > 0) do
			(
				magma.PopEditableBLOP()
				deleteItem EditableBlopStack EditableBlopStack.count
				MagmaFlowEditor_Rollout.restorePanAndZoom()
				MagmaFlowEditor_Rollout.createNodeTree init:true
				MagmaFlowEditor_Rollout.updateEditorTitle()
				MagmaFlowEditor_Rollout.displaySelectedNodeProperties()
				MagmaFlowEditor_Rollout.updateNavigator fullUpdate:true
			)
		)

		on mnu_insertMode picked do 
		(
			MagmaFlowEditor_Rollout.toggleInsertMode()
			--MagmaFlowEditor_Rollout.updateEditorTitle()
		)

		on mnu_exportasmxs picked do 
		(
			MagmaFlowEditor_Rollout.saveFlowToDisk()
		)
		
		on mnu_exportSelectedAsMXS picked do 
		(
			local theSelection = MagmaFlowEditor_Rollout.getSelectedNodes()
			if theSelection.count > 0 do
			(
				makeDir (thePresetsFolder+"FlowComponent\\") all:true
				local theFileToSave = getSaveFileName filename:(thePresetsFolder+"FlowComponent\\") types:"Magma Script (*.MagmaScript)|*.MagmaScript" historyCategory:"MagmaFlows"
				if theFileToSave != undefined do
				(
					local theFlowScript = MagmaFlowEditor_Functions.emitMAXScriptCode magma specificNodes:theSelection
					local theFileHandle = createFile theFileToSave 
					format "%\n" theFlowScript to:theFileHandle 
					close theFileHandle
					MagmaFlowEditor_Rollout.displaySelectedNodeProperties()	
				)
			)
		)		
		
		on mnu_exploreFolder picked do
		(
			local theDir =thePresetsFolder
			makeDir theDir all:true
			shellLaunch theDir ""
		)
		
		on mnu_undo  picked do MagmaFlowEditor_Rollout.undoLastStep()
		on mnu_redo picked do MagmaFlowEditor_Rollout.redoLastStep()
		
		on mnu_copyToClipboard  picked do
			MagmaFlowEditor_Rollout.copySelectionToClipboard()
		
		on mnu_pasteFromClipboard picked do
			MagmaFlowEditor_Rollout.pasteSelectionFromClipboard preserveWires:false
		
		on mnu_pasteFromClipboardAndKeepWires picked do
			MagmaFlowEditor_Rollout.pasteSelectionFromClipboard preserveWires:true
		
		on mnu_replacemxs picked do
		(
			if needToSave then
			(
				local q = querybox ("Changes to the current flow have not been saved.\n\nDo you want to SAVE the current flow to disk\nbefore loading a new one?") title:"SAVE Changes?"
				if q do MagmaFlowEditor_Rollout.saveFlowToDisk()
			)
			
			makeDir thePresetsFolder all:true
			local theFileToLoad = getOpenFileName filename:thePresetsFolder types:"Magma Script (*.MagmaScript)|*.MagmaScript" historyCategory:"MagmaFlows"
			if theFileToLoad != undefined do
			(
				MagmaFlowEditor_Rollout.closeAllCurveEditors()
				magma.Reset()
				MagmaFlowEditor_Rollout.createNodeTree init:true
				::magmaNode = magma
				magma.Loading=true
				fileIn theFileToLoad
				magma.Loading=false
				MagmaFlowEditor_Rollout.restorePanAndZoom()
				MagmaFlowEditor_Rollout.createNodeTree init:true
				MagmaFlowEditor_Rollout.exposeControlsToModifier()
				MagmaFlowEditor_Rollout.autoReorderFlow createUndo:false
				MagmaFlowEditor_Rollout.displaySelectedNodeProperties()
				MagmaFlowEditor_Rollout.updateNavigator fullUpdate:true
				currentPreset = getFileNameFile theFileToLoad
				MagmaFlowEditor_Rollout.updateModifierName()
				MagmaFlowEditor_Rollout.createUndoRecord ("Load Flow ["+filenameFromPath theFileToLoad+"]")
				needToSave = false
				MagmaFlowEditor_Rollout.updateEditorTitle()				
			)
		)
		on mnu_mergemxs picked do
		(
			makeDir (thePresetsFolder) all:true
			local theFileToLoad = getOpenFileName filename:thePresetsFolder types:"Magma Script (*.MagmaScript)|*.MagmaScript" historyCategory:"MagmaFlows"
			if theFileToLoad != undefined do
			(
				local oldCount = MagmaFlowEditor_Functions.getNodeCount magma 
				::magmaNode = magma
				local oldNotes = magma.note
				magma.Loading=true
				fileIn theFileToLoad
				magma.Loading=false
				magma.note = oldNotes 
						
				local nodeArray = Magma.GetNodes()
				local newCount = nodeArray.count
						
				for i = oldCount+1 to newCount do
				(
					local theID = nodeArray[i]
					magma.setNodeProperty theID "Position" ((magma.getNodeProperty theID "Position")+[0,100])
				)
				MagmaFlowEditor_Rollout.restorePanAndZoom()
				MagmaFlowEditor_Rollout.createNodeTree init:true
				MagmaFlowEditor_Rollout.exposeControlsToModifier()
				MagmaFlowEditor_Rollout.updateEditorTitle()
				MagmaFlowEditor_Rollout.autoReorderFlow createUndo:false
				MagmaFlowEditor_Rollout.displaySelectedNodeProperties()
				MagmaFlowEditor_Rollout.updateNavigator fullUpdate:true
				MagmaFlowEditor_Rollout.createUndoRecord ("Merge Flow ["+filenameFromPath theFileToLoad+"]")
			)
		)		
		
		on mnu_DepotOff picked do 
		(
			MagmaFlowSettings.DepotPlacement = #off
			MagmaFlowEditor_Rollout.updateDepotDefinition()
			MagmaFlowEditor_Rollout.createNodeTree init:true			
		)
		on mnu_DepotLeft picked do 
		(
			MagmaFlowSettings.DepotPlacement = #left
			MagmaFlowEditor_Rollout.CreateDepot()
			MagmaFlowEditor_Rollout.updateDepotDefinition()
			MagmaFlowEditor_Rollout.createNodeTree init:true
		)		
		on mnu_DepotBottom picked do 
		(
			MagmaFlowSettings.DepotPlacement = #bottom
			MagmaFlowEditor_Rollout.CreateDepot()
			MagmaFlowEditor_Rollout.updateDepotDefinition()
			MagmaFlowEditor_Rollout.createNodeTree init:true
		)	
		on mnu_DepotBottomRollup picked do 
		(
			MagmaFlowSettings.DepotPlacement = #bottomrollup
			MagmaFlowEditor_Rollout.CreateDepot()
			MagmaFlowEditor_Rollout.updateDepotDefinition()
			MagmaFlowEditor_Rollout.createNodeTree init:true
		)	
		on mnu_DepotBottomRollupReverse picked do 
		(
			MagmaFlowSettings.DepotPlacement = #bottomrollupreverse
			MagmaFlowEditor_Rollout.CreateDepot()
			MagmaFlowEditor_Rollout.updateDepotDefinition()
			MagmaFlowEditor_Rollout.createNodeTree init:true
		)			
		
		subMenu "Expose"
		(
			menuitem mnu_selectExposedInputs "SELECT Exposed Inputs"
			menuitem mnu_UnExposeSelectedInputs "UNEXPOSE Selected Inputs"
			menuitem mnu_ExposeSelectedInputs "EXPOSE Selected Inputs"
			separator sep_200
			menuitem mnu_updateExposedInputs "UPDATE Exposed Inputs"
		)
		
		on mnu_ExposeSelectedInputs picked do
		(
			MagmaFlowEditor_Rollout.exposeControlsToModifier()
		)
		
		on mnu_selectExposedInputs picked do MagmaFlowEditor_Rollout.selectExposedInputs()
		on mnu_UnExposeSelectedInputs picked do MagmaFlowEditor_Rollout.exposeSelectedInputs newState:false
		on mnu_ExposeSelectedInputs picked do MagmaFlowEditor_Rollout.exposeSelectedInputs newState:true
		on mnu_updateExposedInputs picked do MagmaFlowEditor_Rollout.exposeControlsToModifier()
		
		subMenu "Debug"
		(
			menuItem mnu_debugFlow "Debug Mode" checked:MagmaFlowSettings.DebugModeOn enabled:DebugModeEnabled
			menuItem mnu_updateDebugDialog "Force Debug Dialog Update" enabled:MagmaFlowSettings.DebugModeOn
			separator sep_567
			menuItem mnu_showMinMaxMean "Show Min./Max./Mean Data" checked:MagmaFlowSettings.DebugShowMinMaxMean
			menuItem mnu_ShowOutputsInColumns "Show Node Outputs In Separate Columns" checked:MagmaFlowSettings.DebugShowOutputsInColumns
			menuItem mnu_DebugSelectedOnly "Show Only Selected Nodes" checked:MagmaFlowSettings.DebugSelectedOnly
			
			separator sep_570
			submenu "Set Value Decimal Precision"
			(
				menuItem mnu_debugFormatMXS "Use Default Formatting" checked:(MagmaFlowSettings.DebugFormat == #mxs)
				menuItem mnu_debugFormat8 "Use Decimal Precision 8" checked:(MagmaFlowSettings.DebugFormat == #format8)
				menuItem mnu_debugFormat12 "Use Decimal Precision 12" checked:(MagmaFlowSettings.DebugFormat == #format12)
				menuItem mnu_debugFormat16 "Use Decimal Precision 16" checked:(MagmaFlowSettings.DebugFormat == #format16)
			)
			separator sep_678
			submenu "Set Max. Debug Iterations"
			(
				menuItem mnu_debugIterations10K "Evaluate First 10,000 iterations (Default)" checked:(FranticParticles.MaxDebuggerIterations == 10000)
				menuItem mnu_debugIterations50K "Evaluate First 50,000 iterations" checked:(FranticParticles.MaxDebuggerIterations == 50000)
				menuItem mnu_debugIterations100K "Evaluate First 100,000 iterations" checked:(FranticParticles.MaxDebuggerIterations == 100000)
			)
			separator sep_789
			menuItem mnu_navigateToError "NAVIGATE to Error Node" enabled:(ErrorNodesList.count > 1)
		)		
		
		on mnu_debugFormatMXS picked do 
		(
			MagmaFlowSettings.DebugFormat = #mxs
			setIniSetting (theIniFileLocation + "MagmaFlowEditor_Preferences.ini") "Debugger" "DebugFormat" (MagmaFlowSettings.DebugFormat as string)
			if MagmaFlowEditor_DebugRollout.open do MagmaFlowEditor_DebugRollout.updateDialog forceUpdate:false
		)
		on mnu_debugFormat8 picked do 
		(
			MagmaFlowSettings.DebugFormat = #format8
			setIniSetting (theIniFileLocation + "MagmaFlowEditor_Preferences.ini") "Debugger" "DebugFormat" (MagmaFlowSettings.DebugFormat as string)
			if MagmaFlowEditor_DebugRollout.open do MagmaFlowEditor_DebugRollout.updateDialog forceUpdate:false
		)		
		on mnu_debugFormat12 picked do 
		(
			MagmaFlowSettings.DebugFormat = #format12
			setIniSetting (theIniFileLocation + "MagmaFlowEditor_Preferences.ini") "Debugger" "DebugFormat" (MagmaFlowSettings.DebugFormat as string)
			if MagmaFlowEditor_DebugRollout.open do MagmaFlowEditor_DebugRollout.updateDialog forceUpdate:false
		)		
		on mnu_debugFormat16 picked do 
		(
			MagmaFlowSettings.DebugFormat = #format16
			setIniSetting (theIniFileLocation + "MagmaFlowEditor_Preferences.ini") "Debugger" "DebugFormat" (MagmaFlowSettings.DebugFormat as string)
			if MagmaFlowEditor_DebugRollout.open do MagmaFlowEditor_DebugRollout.updateDialog forceUpdate:false
		)		
		
		
		on mnu_navigateToError picked do 
			MagmaFlowEditor_Rollout.navigateToErrorLevel()
		
		on mnu_debugIterations10K picked do FranticParticles.MaxDebuggerIterations = 10000
		on mnu_debugIterations50K picked do FranticParticles.MaxDebuggerIterations = 50000
		on mnu_debugIterations100K picked do FranticParticles.MaxDebuggerIterations = 100000
		
		on mnu_showMinMaxMean picked do 
		(
			MagmaFlowSettings.DebugShowMinMaxMean = not MagmaFlowSettings.DebugShowMinMaxMean 
			if MagmaFlowEditor_DebugRollout.open do MagmaFlowEditor_DebugRollout.updateDialog forceUpdate:false
			setIniSetting (theIniFileLocation + "MagmaFlowEditor_Preferences.ini") "Debugger" "ShowMinMaxMean" (MagmaFlowSettings.DebugShowMinMaxMean as string)	
		)
		on mnu_ShowOutputsInColumns picked do 
		(
			MagmaFlowSettings.DebugShowOutputsInColumns = not MagmaFlowSettings.DebugShowOutputsInColumns 
			if MagmaFlowEditor_DebugRollout.open do MagmaFlowEditor_DebugRollout.updateDialog forceUpdate:false
			setIniSetting (theIniFileLocation + "MagmaFlowEditor_Preferences.ini") "Debugger" "ShowOutputsInColumns" (MagmaFlowSettings.DebugShowOutputsInColumns as string)	
		)		
		on mnu_DebugSelectedOnly picked do 
		(
			MagmaFlowSettings.DebugSelectedOnly = not MagmaFlowSettings.DebugSelectedOnly 
			if MagmaFlowEditor_DebugRollout.open do MagmaFlowEditor_DebugRollout.updateDialog forceUpdate:false
			setIniSetting (theIniFileLocation + "MagmaFlowEditor_Preferences.ini") "Debugger" "DebugSelectedOnly" (MagmaFlowSettings.DebugSelectedOnly as string)	
		)			
		
		on mnu_updateDebugDialog picked do MagmaFlowEditor_DebugRollout.updateDialog()
		
		on mnu_debugFlow picked do 
		(
			MagmaFlowSettings.DebugModeOn = not MagmaFlowSettings.DebugModeOn
			MagmaFlowEditor_Rollout.debugFlow()
			MagmaFlowEditor_Rollout.createNodeTree init:false
		)
		
		on mnu_AutoReorderToggle picked do
		(
			MagmaFlowEditor_Rollout.ReorderToggle()
		)
		
		on mnu_acceptAutoOrder picked do
		(
			MagmaFlowEditor_Rollout.AcceptReorderedFlow()
		)
	)
	
	rcmenu InsertNode_RCMenu
	(
		menuitem mnu_insertNodeIntoFlow "Insert Into Flow - Enable, then Click a Free Operator to Insert..." checked:MagmaFlowSettings.insertNodeIntoFlow
		on mnu_insertNodeIntoFlow  picked do
		(
			MagmaFlowSettings.insertNodeIntoFlow = not MagmaFlowSettings.insertNodeIntoFlow
		)
	)
	
	rcmenu AddNode_RCMenu 
	(
		fn isBlopEditing = (MagmaFlowSettings.NumEditingBLOPs > 0)
		fn CanPasteFromWindowsClipboard =
		(
			local clipboardClass = dotNetClass "System.Windows.Forms.Clipboard" 
			local theFlowScript = clipboardClass.GetText()
			matchPattern theFlowScript pattern:"(--MAGMAFLOW2--*" 
		)
		fn CanPasteFromWindowsClipboardAndKeepWires =
		(
			local clipboardClass = dotNetClass "System.Windows.Forms.Clipboard" 
			local theFlowScript = clipboardClass.GetText()
			matchPattern theFlowScript pattern:"(--MAGMAFLOW2--*" AND trackID == ::magmaClipBoardId
		)		
		
		menuitem mnu_exitBlop "Exit BLOP Editing" filter:isBlopEditing
		separator sep_10 filter:isBlopEditing
		menuItem mnu_pasteFromClipboard "Paste (Ctrl+V)" enabled:(CanPasteFromWindowsClipboard())
		menuItem mnu_pasteFromClipboardAndKeepWires "Paste And Preserve Connections (Ctrl+Alt+V)" enabled:(CanPasteFromWindowsClipboardAndKeepWires())
		separator sep_20 
		menuItem mnu_addOutputNode "Create Output Node (Ctrl+O)" 
		separator sep_30 	
		menuItem mnu_createAnyNode "Create Nodes Menu... (Ctrl+`)" 
			
		on mnu_pasteFromClipboard  picked do
			MagmaFlowEditor_Rollout.pasteSelectionFromClipboard preserveWires:false
		on mnu_pasteFromClipboardAndKeepWires  picked do
			MagmaFlowEditor_Rollout.pasteSelectionFromClipboard preserveWires:true
		
		on mnu_addOutputNode picked do
		(
			MagmaFlowEditor_Rollout.addNewOutputChannel()
			setFocus MagmaFlowEditor_Rollout.hc
		)
		
		on mnu_createAnyNode picked do
		(
			MagmaFlowEditor_Rollout.showRCMenu #allNodes
		)
		
		on mnu_exitBlop picked do
		(
			if (magma.NumEditingBLOPs() > 0) do
			(
				magma.PopEditableBLOP()
				deleteItem EditableBlopStack EditableBlopStack.count
				MagmaFlowEditor_Rollout.restorePanAndZoom()
				MagmaFlowEditor_Rollout.createNodeTree init:true
				MagmaFlowEditor_Rollout.updateEditorTitle()
				MagmaFlowEditor_Rollout.displaySelectedNodeProperties()
				MagmaFlowEditor_Rollout.updateNavigator fullUpdate:true
			)
		)		
	)
	rcmenu DepotNode_RCMenu
	(
		fn categoriesOn = (MagmaFlowSettings.DepotShowCategories)
		menuItem mnu_DepotOff "Depot Off" checked: (MagmaFlowSettings.DepotPlacement == #off)
		menuItem mnu_DepotLeft "Depot On Left" checked: (MagmaFlowSettings.DepotPlacement == #left)
		menuItem mnu_DepotBottom "Depot At Bottom" checked: (MagmaFlowSettings.DepotPlacement == #bottom)
		--menuItem mnu_DepotBottomRollup "Depot At Bottom - Rollup" checked: (MagmaFlowSettings.DepotPlacement == #bottomrollup)
		menuItem mnu_DepotBottomRollupReverse "Depot At Bottom - Rollup" checked: (MagmaFlowSettings.DepotPlacement == #bottomrollupreverse)
		separator sep_10
		menuItem mnu_DepotShowBLOPs "Show BlackOp Categories In Depot" checked:MagmaFlowSettings.DepotShowBLOPs
		separator sep_20
		menuItem mnu_DepotShowCategories "Use Depot Categories" checked:MagmaFlowSettings.DepotShowCategories
		menuItem mnu_DepotAutoCollapseOnDragAndDrop "Auto-Collapse Categories On DragAndDrop" checked:MagmaFlowSettings.DepotAutoCollapseOnDragAndDrop
		separator sep_30 filter:categoriesOn
		menuItem mnu_expandAllCategories "Expand All Categories (Shift+Click Category)" filter:categoriesOn
		menuItem mnu_collapseAllCategories "Collapse All Categories (Ctrl+Shift+Click Category)" filter:categoriesOn
		
		on mnu_collapseAllCategories picked do
		(
			for j = 1 to MagmaFlowEditor_Rollout.DepotDefinition.count where MagmaFlowEditor_Rollout.DepotDefinition[j][1][1]  == "HEAD" do
				MagmaFlowEditor_Rollout.DepotDefinition[j][1][6] = false
			MagmaFlowEditor_Rollout.updateDepotDefinition()
			MagmaFlowEditor_Rollout.createNodeTree init:true			
			--if AutoZoomExtents do KrakatoaChannelNodeEditor_Rollout.zoomExtents createUndo:false			
		)

		on mnu_expandAllCategories picked do
		(
			for j = 1 to MagmaFlowEditor_Rollout.DepotDefinition.count where MagmaFlowEditor_Rollout.DepotDefinition[j][1][1]  == "HEAD" do
				MagmaFlowEditor_Rollout.DepotDefinition[j][1][6] = true
			MagmaFlowEditor_Rollout.updateDepotDefinition()
			MagmaFlowEditor_Rollout.createNodeTree init:true			
			--if AutoZoomExtents do KrakatoaChannelNodeEditor_Rollout.zoomExtents createUndo:false
		)		
		
		
		on mnu_DepotShowCategories picked do 
		(
			MagmaFlowSettings.DepotShowCategories = not MagmaFlowSettings.DepotShowCategories
			if not MagmaFlowSettings.DepotShowCategories and (MagmaFlowSettings.DepotPlacement == #bottomrollup or MagmaFlowSettings.DepotPlacement == #bottomrollupreverse) do 
			(
				MagmaFlowSettings.DepotPlacement = #bottom
			)	
			MagmaFlowEditor_Rollout.updateDepotDefinition()
			MagmaFlowEditor_Rollout.createNodeTree init:true			
		)		

		on mnu_DepotAutoCollapseOnDragAndDrop picked do 
		(
			MagmaFlowSettings.DepotAutoCollapseOnDragAndDrop = not MagmaFlowSettings.DepotAutoCollapseOnDragAndDrop
			MagmaFlowEditor_Rollout.CreateDepot()
			MagmaFlowEditor_Rollout.updateDepotDefinition()
			MagmaFlowEditor_Rollout.createNodeTree init:true			
		)			
		
		on mnu_DepotShowBLOPs picked do 
		(
			MagmaFlowSettings.DepotShowBLOPs = not MagmaFlowSettings.DepotShowBLOPs
			MagmaFlowEditor_Rollout.CreateDepot()
			MagmaFlowEditor_Rollout.updateDepotDefinition()
			MagmaFlowEditor_Rollout.createNodeTree init:true			
		)			
		
		on mnu_DepotOff picked do 
		(
			MagmaFlowSettings.DepotPlacement = #off
			MagmaFlowEditor_Rollout.updateDepotDefinition()
			MagmaFlowEditor_Rollout.createNodeTree init:true			
		)	
		on mnu_DepotLeft picked do 
		(
			MagmaFlowSettings.DepotPlacement = #left
			MagmaFlowEditor_Rollout.CreateDepot()
			MagmaFlowEditor_Rollout.updateDepotDefinition()
			MagmaFlowEditor_Rollout.createNodeTree init:true			
		)	
		on mnu_DepotBottom picked do 
		(
			MagmaFlowSettings.DepotPlacement = #bottom
			MagmaFlowEditor_Rollout.CreateDepot()
			MagmaFlowEditor_Rollout.updateDepotDefinition()
			MagmaFlowEditor_Rollout.createNodeTree init:true			
		)			
		on mnu_DepotBottomRollup picked do
		(
			MagmaFlowSettings.DepotPlacement = #bottomrollup
			MagmaFlowSettings.DepotShowCategories = true
			MagmaFlowEditor_Rollout.CreateDepot()
			MagmaFlowEditor_Rollout.updateDepotDefinition()
			MagmaFlowEditor_Rollout.createNodeTree init:true			
		)
		on mnu_DepotBottomRollupReverse picked do
		(
			MagmaFlowSettings.DepotPlacement = #bottomrollupreverse
			MagmaFlowSettings.DepotShowCategories = true
			MagmaFlowEditor_Rollout.CreateDepot()
			MagmaFlowEditor_Rollout.updateDepotDefinition()
			MagmaFlowEditor_Rollout.createNodeTree init:true			
		)	
	)	
	
	rcmenu EditNode_RCMenu 
	(
		fn isOperatorUnderMouse = true --( (MagmaFlowEditor_Rollout.lastNodeClick > 0 and (magma.GetNodeType (magma.getNodeID MagmaFlowEditor_Rollout.lastNodeClick)) == "Operator") )
		fn isInputUnderMouse = true --( (KrakatoaChannelNodeEditor_Rollout.lastNodeClick > 1 and KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][1] == "Input") )
		fn anythingSelected =((MagmaFlowEditor_Rollout.getSelectedNodes()).count > 0)
		fn moreThanOneSelected = ((MagmaFlowEditor_Rollout.getSelectedNodes()).count > 1)
		fn canExposeControl = 
		(
			try((magma.GetNodeType ((Magma.GetNodes())[MagmaFlowEditor_Rollout.lastNodeClick])) == "InputValue") catch(false)
		)
		fn isBlackopUnderMouse = 
		(
			try((magma.GetNodeType ((Magma.GetNodes())[MagmaFlowEditor_Rollout.lastNodeClick])) == "BLOP") catch(false)
		)
		fn isBlackopOrSelection = isBlackopUnderMouse() or anythingSelected()
		fn canPaste =
		(
			local clipboardClass = dotNetClass "System.Windows.Forms.Clipboard" 
			local theFlowScript = clipboardClass.GetText()
			matchPattern theFlowScript pattern:"(--MAGMAFLOW2--*" 
		)
		fn canPasteOrSelected = (canPaste() or anythingSelected())
		fn isInBlackOpEditingMode = false 
		fn moreThanOneSelectedOrBLOP = (moreThanOneSelected() or isBlackopUnderMouse())
		
		menuItem mnu_endEditingBLOP "Exit BlackOp Editing Mode" filter:isInBlackOpEditingMode
		separator sep_1 filter:isInBlackOpEditingMode
		
		menuItem mnu_editBLOP "Edit BlackOp" filter:isBlackopUnderMouse
		--menuItem mnu_closeBLOP "Close BlackOp" filter:isBlackopOpen
			
		menuItem mnu_addNewBLOPInline "[BlackOp] From Selection" filter:anythingSelected
		--menuItem mnu_saveBLOPDefinition "Save Selection As BlackOP" filter:anythingSelected
		menuItem mnu_explodeBLOP "Explode BlackOp" filter:isBlackopUnderMouse
		separator sep_10 filter:isBlackopOrSelection
			
			
		menuItem mnu_exposeControl "Expose Control" filter:canExposeControl  checked:( try(magma.getNodeProperty ((Magma.GetNodes())[MagmaFlowEditor_Rollout.lastNodeClick]) "Exposed" == true)catch(false) )
		menuitem mnu_selectExposedInputs "Select Exposed Inputs"
		subMenu "Expose Selected..." filter:anythingSelected
		(
			menuitem mnu_UnExposeSelectedInputs "Unexpose Selected Inputs"
			menuitem mnu_ExposeSelectedInputs "Expose Selected Inputs"
			separator sep_500
			menuitem mnu_updateExposedInputs "Update Exposed Inputs"
		)
		
		separator sep_2 --filter:canExposeControl
		
		menuItem mnu_disconnectAllInputs "Disconnect All Inputs of This Node"	
		menuItem mnu_disconnectAllOutputs "Disconnect All Outputs of This Node"	
		menuItem mnu_disconnectAllInputsOutputs "Disconnect All Inputs and Outputs of This Node"	
		separator sep_50  filter:anythingSelected
		menuItem mnu_disconnectAllInputsSel "Disconnect All Inputs of Selected Nodes"	filter:anythingSelected
		menuItem mnu_disconnectAllOutputsSel "Disconnect All Outputs of Selected Nodes" filter:anythingSelected
		menuItem mnu_disconnectAllInputsOutputsSel "Disconnect All Inputs and Outputs of Selected Nodes" filter:anythingSelected
		
		separator sep_100 --filter:isBlackopOrSelection
		
		menuItem mnu_copyToClipboard "Copy Selected Nodes (Ctrl+C)" filter:anythingSelected
		menuItem mnu_pasteFromClipboard "Paste (Ctrl+V)" filter:canPaste
		
		separator sep_200 filter:canPasteOrSelected
		menuItem mnu_swapInputs "Swap First Two Inputs (Ctrl+W)" filter:isOperatorUnderMouse
		menuItem mnu_swapLastInputs "Swap Last Two Inputs (Shift+Ctrl+W)" filter:isOperatorUnderMouse
		separator sep_300 filter:isOperatorUnderMouse
		
		menuItem mnu_flipSocketPosition "Flip Socket Position" --filter:isInputUnderMouse
		separator sep_310 --filter:isInputUnderMouse
		
		menuItem mnu_toggleNode "Toggle Node On/Off"		
		menuItem mnu_toggleNodeSel "Toggle Selected Nodes On/Off (Ctrl+P)"		

		separator sep_400

		
		menuItem mnu_deleteNode "Delete Node Under Mouse Pointer (Del.)"	
		menuItem mnu_deleteSelectedNodes "Remove Selected Nodes, Preserve Flow (<--Backspace)" filter:anythingSelected
		

		on mnu_editBLOP  picked do 
		(
			local theID = MagmaFlowEditor_Functions.getNodeID magma MagmaFlowEditor_Rollout.lastNodeClick
			append EditableBlopStack theID
			magma.PushEditableBLOP theID
			MagmaFlowEditor_Rollout.restorePanAndZoom()
			MagmaFlowEditor_Rollout.createNodeTree init:true
			MagmaFlowEditor_Rollout.autoReorderFlow()	
			MagmaFlowEditor_Rollout.displaySelectedNodeProperties()
			MagmaFlowEditor_Rollout.updateNavigator fullUpdate:true
			MagmaFlowEditor_Rollout.createUndoRecord ("Edit BLOP [" + theID as string+"]")
			MagmaFlowEditor_Rollout.createNodeTree init:false
		)

		on mnu_flipSocketPosition picked do
		(
			local theID = MagmaFlowEditor_Functions.getNodeID magma MagmaFlowEditor_Rollout.lastNodeClick
			magma.DeclareExtensionProperty theID "FlipSocketPosition"
			local oldValue = magma.getNodeProperty theID "FlipSocketPosition"
			if oldValue == undefined do oldValue = false
			oldValue = not oldValue 
			magma.setNodeProperty theID "FlipSocketPosition" oldValue 
			MagmaFlowEditor_Rollout.createNodeTree init:false
			MagmaFlowEditor_Rollout.createUndoRecord "Flip Socket Position"	
		)
		
		on mnu_UnExposeSelectedInputs picked do
			MagmaFlowEditor_Rollout.exposeSelectedInputs newState:false
		on mnu_ExposeSelectedInputs picked do
			MagmaFlowEditor_Rollout.exposeSelectedInputs newState:true
		on mnu_updateExposedInputs picked do
			MagmaFlowEditor_Rollout.exposeControlsToModifier()
		on mnu_selectExposedInputs picked do
			MagmaFlowEditor_Rollout.selectExposedInputs()		
		
		on mnu_explodeBLOP picked do 
		(
			local theID = MagmaFlowEditor_Functions.getNodeID magma MagmaFlowEditor_Rollout.lastNodeClick
			if theID > -1 do MagmaFlowEditor_Rollout.explodeBLOP theID
		)

		on mnu_addNewBLOPInline picked do
			MagmaFlowEditor_Rollout.createBLOPInline creationType:#rcmenu 		

		on mnu_disconnectAllInputs picked do
			MagmaFlowEditor_Rollout.disconnectAllInputs Single:true
		
		on mnu_disconnectAllOutputs picked do
			MagmaFlowEditor_Rollout.disconnectAllOutputs Single:true
		
		on mnu_disconnectAllInputsOutputs picked do
		(
			MagmaFlowEditor_Rollout.disconnectAllInputs Single:true createUndo:false
			MagmaFlowEditor_Rollout.disconnectAllOutputs Single:true
		)

		on mnu_disconnectAllInputsSel picked do
			MagmaFlowEditor_Rollout.disconnectAllInputs Single:false
		
		on mnu_disconnectAllOutputsSel picked do
			MagmaFlowEditor_Rollout.disconnectAllOutputs Single:false
		
		on mnu_disconnectAllInputsOutputsSel  picked do
		(
			MagmaFlowEditor_Rollout.disconnectAllInputs Single:false createUndo:false
			MagmaFlowEditor_Rollout.disconnectAllOutputs Single:false
		)

		on mnu_copyToClipboard  picked do
			MagmaFlowEditor_Rollout.copySelectionToClipboard()
		
		on mnu_pasteFromClipboard  picked do
			MagmaFlowEditor_Rollout.pasteSelectionFromClipboard()		

		on mnu_swapInputs picked do MagmaFlowEditor_Rollout.swapInputsOrder Single:true
		on mnu_swapLastInputs picked do MagmaFlowEditor_Rollout.swapInputsOrder Single:true Last:true

		on mnu_toggleNode picked do
			MagmaFlowEditor_Rollout.setPassThrough Single:true
		on mnu_toggleNodeSel picked do
			MagmaFlowEditor_Rollout.setPassThrough Single:false
		
		on mnu_exposeControl picked do
		(
			if MagmaFlowEditor_Rollout.lastNodeClick > 1 do
			(
				local theID = MagmaFlowEditor_Functions.getNodeID magma MagmaFlowEditor_Rollout.lastNodeClick
				magma.DeclareExtensionProperty theID "Exposed"
				local state = magma.getNodeProperty theID "Exposed" 
				if state == undefined do state = true
				state = not state
				magma.setNodeProperty theID "Exposed" state
				MagmaFlowEditor_Rollout.exposeControlsToModifier()
				MagmaFlowEditor_Rollout.createNodeTree init:false
				MagmaFlowEditor_Rollout.displaySelectedNodeProperties()
			)
		)
		
		on mnu_deleteNode picked do
		(
			local needUpdate = false
			local needExpose = false
			if MagmaFlowEditor_Rollout.lastNodeClick > 1 do
			(
				local theID = MagmaFlowEditor_Functions.getNodeID magma MagmaFlowEditor_Rollout.lastNodeClick
				if theID > -1 do --if the ID is valid, in other words not a Depot item
				(
					local theType = magma.getNodeType theID
					if theType != undefined do 
					(
						needUpdate = true
						if magma.getNodeProperty theID "Exposed" == true do needExpose = true
						magma.deleteNode theID
						for theIDtoCheck in Magma.GetNodes() do
						(
							for c = 1 to magma.getNumNodeInputs theIDtoCheck do
								if (magma.getNodeInput theIDtoCheck c)[1] == theID do 
									magma.setNodeInput theIDtoCheck c -1 1
						)--end i loop
					)--end if type	
				)--end if ID 
				if needExpose == true do MagmaFlowEditor_Rollout.exposeControlsToModifier()
				if needUpdate do
				(
					--createUndoRecord ("Delete Node")				
					MagmaFlowEditor_Rollout.autoReorderFlow createUndo:false
					--if AutoZoomExtents do zoomExtents createUndo:false
					MagmaFlowEditor_Rollout.displaySelectedNodeProperties()
				)	
				MagmaFlowEditor_Rollout.createNodeTree init:true		
				MagmaFlowEditor_Rollout.updateNavigator fullUpdate:true				
			)	
		)
		on mnu_deleteSelectedNodes picked do
		(
			MagmaFlowEditor_Rollout.deleteSelectedNodes()
		)		
	)	
	
	rollout MagmaFlowEditor_Rollout "Krakatoa MagamFlow Editor" width:1000 height:700
	(
		--LOCAL VARIABLE DEFINITIONS
		local currentMagmaNode
		local drawDepot, getSelectedNodes, setSelectedNodes, displaySelectedNodeProperties, updateMagmaHolder, createNodeTree, updateEditorTitle
		local storePanAndZoom, restorePanAndZoom, autoReorderFlow, updateNavigator, alignAllNodesToGrid, exposeControlsToModifier, toggleInsertMode
		local createUndoRecord, undoLastStep, redoLastStep, CollapseBranches, updateInsertMode, closeAllCurveEditors, addNewOutputChannel, getNewOutputChannel
		local showRCMenu
		local NodeIDMap = #()
		local lastSelection = #(0)
		local lastSelectionBeforeClick = #()
		local lastMouseClick = [0,0]
		local lastNodeClick = -1
		local DepotNodes = #()
		local DepotDefinition = #()		
		local DepotCategories = #()
		local leftDepotMargin = 0
		local DisableDragAndDrop = false
		local lastInfoMessage = ""
		local ConnectToEmpty_fromID = -1
		local ConnectToEmpty_Index = -1
		local ConnectToEmpty_SocketType = #none
		local lastWireSelection = #()
		
		local dotnetSystemInfo = dotNetClass "System.Windows.Forms.SystemInformation"
		
		include "MagmaSchematicControl.ms"  		
		--The include replaces with one of the following, depending on the product
		--KrakatoaSchematicControl hc "" width:800 height:600 pos:[0,0] 
		--EmberSchematicControl hc "" width:800 height:600 pos:[0,0] 
		--GenomeSchematicControl hc "" width:800 height:600 pos:[0,0] 
		
		progressbar prg_bar width:176 height:6 pos:[0,0] color:red value:100 visible:false
		subRollout NodePropsSR width:180 height:600 pos:[-800,0]
		bitmap bmp_navigator width:180 height:100 pos:[-800,0]
		progressbar prg_swatch width:10 height:17 pos:[0,1000] color:white value:100 
		progressbar prg_errorswatch width:10 height:17 pos:[0,1000] color:white value:100 
		
		edittext edt_log width:800  pos:[20,1000]
		
		button btn_Undo "Undo" width:39 height:18 pos:[-100,-100] tooltip:"Click to Undo last step.\n\nRight-Click to display a list of previous steps and Undo multiple steps at once."
		button btn_Redo "Redo" width:39 height:18 pos:[-100,-100] tooltip:"Click to Redo one step.\n\nRight-Click to display a list of undone steps and Redo multople steps at once."
		
		
		checkbutton chk_autoUpdateModifier ">AUTO" width:61 height:20  pos:[-200,1] tooltip:"When checked, any changes to the flow will cause the modifier to be updated.\n\nWhen unchecked, changes to the flow like adding or removing nodes or connections will not trigger a modifier update. Instead, use the UPDATE button to force updates manually when desired."
		button btn_updateModifier "UPDATE" width:118 height:20  pos:[-200,1] tooltip:"Forces an update of the modifier to show the result of the current flow in the viewport, especially when the >AUTO option is unchecked."

		button btn_RecorderToStart "|<" width:25 height:25 visible:false
		button btn_RecorderBackOneStep "<<" width:25 height:25 visible:false
		checkbutton chk_RecorderPlay "|>"  width:25 height:25 visible:false
		button btn_RecorderForwardOneStep ">>" width:25 height:25 visible:false
		button btn_RecorderToEnd ">|"width:25 height:25 visible:false
		button btn_RecorderClose "Close" width:50 height:25 visible:false
		


		fn saveSettings =
		(
			local theIniFile = (theIniFileLocation + "MagmaFlowEditor_Preferences.ini")
			setIniSetting theIniFile "Depot" "Placement" (MagmaFlowSettings.DepotPlacement as string)
			setIniSetting theIniFile "Depot" "NodeWidth" (MagmaFlowSettings.DepotNodeWidth as string)
			setIniSetting theIniFile "Depot" "ShowCategories" (MagmaFlowSettings.DepotShowCategories as string)
			setIniSetting theIniFile "Depot" "AutoCollapseOnDragAndDrop" (MagmaFlowSettings.DepotAutoCollapseOnDragAndDrop as string)
			setIniSetting theIniFile "Options" "UnconnectedNodesPlacement" (MagmaFlowSettings.UnconnectedNodesPlacement as string)
		)
		
		fn loadSettings =
		(
			local theIniFile = (theIniFileLocation + "MagmaFlowEditor_Preferences.ini")
			--print theIniFile 
			local theVal = getIniSetting theIniFile "Depot" "Placement" 
			if theVal == "" do theVal = #bottomrollupreverse
			MagmaFlowSettings.DepotPlacement = theVal as name
			if MagmaFlowSettings.DepotPlacement == #bottomrollup do MagmaFlowSettings.DepotPlacement = #bottomrollupreverse --bottomrollup is currently removed
			
			local theVal = execute (getIniSetting theIniFile "Depot" "NodeWidth" )
			if theVal == OK do theVal = 80
			MagmaFlowSettings.DepotNodeWidth = theVal
			
			local theVal = execute (getIniSetting theIniFile "Depot" "ShowCategories" )
			if theVal == OK do theVal = true
			MagmaFlowSettings.DepotShowCategories = theVal 
			
			local theVal = execute (getIniSetting theIniFile "Depot" "AutoCollapseOnDragAndDrop" )
			if theVal == OK do theVal = true
			MagmaFlowSettings.DepotAutoCollapseOnDragAndDrop = theVal 

			local theVal = (getIniSetting theIniFile "Options" "UnconnectedNodesPlacement" )
			if theVal == "" do theVal = "bottom"
			MagmaFlowSettings.UnconnectedNodesPlacement = theVal as name
			
			local theVal = execute (getIniSetting theIniFile "Options" "ShowTextureMapSample" )
			if theVal == OK do theVal = false
			MagmaFlowSettings.showTextureMapSample = theVal 
			
			local theVal = execute (getIniSetting theIniFile "Options" "ShowColorSwatchSample" )
			if theVal == OK do theVal = false
			MagmaFlowSettings.ShowColorSwatchSample = theVal 			

			local theVal = execute (getIniSetting theIniFile "Options" "ShowInputSocketName" )
			if theVal == OK do theVal = true
			MagmaFlowSettings.ShowInputSocketName = theVal 
			
			local theVal = execute (getIniSetting theIniFile "Options" "ShowInputSocketValue" )
			if theVal == OK do theVal = true
			MagmaFlowSettings.ShowInputSocketValue = theVal 	

			local theVal = execute (getIniSetting theIniFile "Options" "AllowSubtreeCollapsing" )
			if theVal == OK do theVal = true
			MagmaFlowSettings.AllowSubtreeCollapsing = theVal 	
		)
		
		fn updateErrorSwatch = 
		(
			--FIXME: Introduce MagmaOwner variable and compare to it
			local currentObjString = "Modifier"
			local theOwner = MagmaFlowEditor_Functions.getMagmaOwner magma
			local isCurrent =  modPanel.getCurrentObject() == theOwner
			if not isKindOf theOwner Modifier do currentObjString = "Object"

			if isCurrent then
			(
				prg_swatch.color = green 
				edt_log.text = "CURRENT "+currentObjString+", No Errors."
			)
			else 
			(
				prg_swatch.color = yellow
				edt_log.text = "NOT Current "+currentObjString+", No Errors."
			)
			
			if lastErrorMessage != "" then 
			(
				prg_errorswatch.color = red 
				edt_log.text = if isCurrent then "CURRENT "+currentObjString+": "+ lastErrorMessage else "NOT Current "+currentObjString+": "+ lastErrorMessage
			)
			else
				prg_errorswatch.color = green
			
			if theOwner == undefined do try(destroyDialog MagmaFlowEditor_Rollout)catch()
		)
		
		
		fn checkCurrentLevel nodeID=
		(
			local theNodes = magma.getNodes()
			local theIndex = findItem theNodes nodeID
			local returnvalue = false
			if theIndex == 0 then
			(
				for n in theNodes do
				(
					if magma.getNodeType n == "BLOP" do
					(
						--format "Checking BLOP %\n" n
						magma.PushEditableBLOP n
						append ErrorNodesList n
						returnvalue = (checkCurrentLevel nodeID)
						if not returnvalue do deleteItem ErrorNodesList ErrorNodesList.count
						magma.PopEditableBLOP()
					)
				)
				returnvalue
			)
			else
			(
				--format "Error Node Found: %\n" nodeID
				true
			)
		)
		
		fn getAllErrorNodes nodeID=
		(
			ErrorNodesList = #()
			for i = 1 to magma.NumEditingBLOPs() do magma.PopEditableBLOP() --get out to top level
			checkCurrentLevel nodeID
			for i in EditableBlopStack do magma.pushEditableBLOP i
			append ErrorNodesList nodeID
			--format "ErrorNodesList=%\n" ErrorNodesList
		)
		
		fn navigateToErrorLevel =
		(
			if ErrorNodesList.count > 1 do
			(
				for i = 1 to magma.NumEditingBLOPs() do magma.PopEditableBLOP() --get out to top level
				EditableBlopStack = #()
				
				for i = 1 to ErrorNodesList.count-1 do
				(
					magma.pushEditableBLOP ErrorNodesList[i]
					append EditableBlopStack ErrorNodesList[i]
				)
				restorePanAndZoom()
				createNodeTree init:true
				autoReorderFlow()	
				local theIndex = findItem (magma.GetNodes()) ErrorNodesList[ErrorNodesList.count]
				setSelectedNodes #(theIndex)
				displaySelectedNodeProperties()
				updateNavigator fullUpdate:true
				createUndoRecord ("Navigate To Error Node [" + ErrorNodesList[ErrorNodesList.count] as string+"]")
				createNodeTree init:false
			)
		)
		
		fn updateErrorLog NodeID:undefined ErrorMessage:undefined =
		(
			lastErrorNode = nodeID
			--format "Node % Got Error %\n" nodeID errorMessage
			if ErrorMessage == undefined then
			(
				lastErrorMessage = ""
			)
			else
			(
				ErrorMessage = substituteString ErrorMessage "\n" " |"
				ErrorMessage = substituteString ErrorMessage "\t" " "
				lastErrorMessage = errorMessage
			)
			--if NodeID != undefined do 
			(
				getAllErrorNodes NodeID
				if ErrorNodesList.count > 1 do 
				(
					allErrorNodesString = ErrorNodesList as string
					allErrorNodesString = substring allErrorNodesString 3 -1
					lastErrorMessage += " (Nested BLOP IDs: " + allErrorNodesString
				)
			)
			
			edt_log.text = lastErrorMessage
			updateErrorSwatch()
			createNodeTree init:false
			updateNavigator fullUpdate:true
		)
		
		fn updateErrorInfo =
		(
			if MagmaFlowEditor_Functions.isRenderElement magma do return false
			local theOwner = MagmaFlowEditor_Functions.getMagmaOwner magma

			local theErrorNode = -100
			local theErrorMsg = ""
			local result = try(theOwner.GetLastError OutMessage:&theErrorMsg OutNodeID:&theErrorNode)catch(true)
			if result == false do 
			(
				theErrorNode = -100
				theErrorMsg = ""
			)
			--format "Error: %: '%'\n" theErrorNode theErrorMsg 
			updateErrorLog NodeID:theErrorNode ErrorMessage:theErrorMsg				
		)		
		
		fn updateModifierName forceName:"" = 
		(
			MagmaFlowEditor_Functions.updateModifierName magma forceName:forceName
			updateEditorTitle()
		)
		
		fn updateMagmaHolder init:true updateName:true update:true =
		(
			if magma.autoUpdate do 
			(
				magma.autoUpdate = magma.autoUpdate
				local theNodes = for i in refs.dependentNodes magma where classof i.baseobject == KrakatoaPRTLoader do try(i.delegate.InvalidateObjectSpaceCache())catch()
				for i in refs.dependentNodes magma where classof i.baseobject == Stoke do try(i.delegate.ViewportEnabled = not i.delegate.ViewportEnabled; i.delegate.ViewportEnabled = not i.delegate.ViewportEnabled)catch()
				--if updateName do updateModifierName()
			)
			redrawViews()
			if update do createNodeTree init:init
		)

		fn getMouseInSchematicView mode:#default =
		(
			lastMouseClick = if mode == #rcmenu then  --if the rcmenu was invoked, use its position for node creation
				NodeCreationMenuPosition
			else
				mouse.screenpos
			local theHeightOffset = try(dotnetSystemInfo.CaptionHeight + dotnetSystemInfo.MenuHeight + dotnetSystemInfo.FrameBorderSize.height)catch(50)
			if MagmaFlowEditor_Rollout.inViewport do 
				theHeightOffset = try(dotnetSystemInfo.MenuHeight+0)catch(19)
			local theWidthOffset = try(dotnetSystemInfo.FrameBorderSize.width)catch(3)
			(lastMouseClick - (getDialogPos MagmaFlowEditor_Rollout))-[theWidthOffset,theHeightOffset]
		)

		fn getOutputSocketName theID theIndex =
		(
			if theDebuggerSelection == undefined do theDebuggerSelection = 1
			if MagmaFlowSettings.DebugModeOn and debugResult != undefined and theDebuggerSelection > 0 then
			(
				local theVal = debugResult.GetNodeValue theDebuggerSelection theID theIndex
				if theVal == Undefined do theVal = "N/A"
				theVal as string
			)
			else	
			try
			(
			if theID < 0 do return "???"
			local theType = try(magma.getNodeType theID)catch("???")
			local theTypeArray = magma.getNodeProperty theID "Internal_OutputValueTypes" 
			if theTypeArray == undefined do theTypeArray = #()
			local theConnectionTypeString = case theTypeArray[theIndex] of
			(
				default: ""
				#vector: "[V]"
				#float: "[F]"
				#int: "[ I ]"
				#quat: "[Q]"
				#bool: "[B]"
				#mesh: "[G]"
			)				
			
			local returnValue = case of
			(
				(theType as name == #BLOPSocket):
				(
					theInputSocketNames[theIndex] as string
				)
				(theType as name == #BLOP):
				(
					local theSocketName = magma.getNodeProperty theID ("BLOPOutputSocketName"+theIndex as string)
					if theSocketName != undefined then theSocketName else ("Output "+theIndex as string)
				)		
				(magma.getNodeProperty theID "uiType" == "Loop"):
				(
					local theSocketName = magma.getNodeProperty theID ("BLOPOutputSocketName"+theIndex as string)
					if theSocketName != undefined then theSocketName else ("Accumulator "+theIndex as string)
				)
				(theType as name==#elbow): 
				(
					theOtherID = magma.getNodeInput theID 1
					getOutputSocketName theOtherID[1] theOtherID[2]
				)
				(theType as name == #inputChannel): magma.GetNodeProperty theID "channelName"
				(theType as name == #loopChannel): magma.GetNodeProperty theID "channelName"
				(theType as name == #TexmapEval): 
				(
					local theVal = magma.GetNodeProperty theID "texmap"
					local theType = substring (magma.GetNodeProperty theID "resultType") 1 1
					if theVal == undefined then
						"<none> ["+theType+"]"
					else
						theVal as string +" [" +theType+"]"
				)
				(theType as name == #inputTexmap): 
				(
					local theVal = magma.GetNodeProperty theID "texmap"
					local theType = substring (magma.GetNodeProperty theID "resultType") 1 1
					if theVal == undefined then
						"<none> ["+theType+"]"
					else
						theVal as string +" [" +theType+"]"
				)
				(theType as name == #inputValue): 
				( 
					local theVal = (magma.GetNodeProperty theID "controller").value 
					local isInt = (magma.GetNodeProperty theID "forceInteger") == true
					--if isInt then (theVal as integer) as string else theVal as string
					if classof theVal == Point3 then 
						"Vector:" + theVal as string
					else if isInt then 
						"Integer:" + (theVal as integer) as string
					else 
						"Float:" + theVal as string
				)
				(theType as name == #fromWorld): ("ObjectSpace ["+ (magma.getNodeProperty theID "inputType")[1] + "]")
				(theType as name == #toWorld): ("WorldSpace ["+ (magma.getNodeProperty theID "inputType")[1] + "]")
				(theType as name == #fromCamera): ("FromCamera ["+ (magma.getNodeProperty theID "inputType")[1] + "]")
				(theType as name == #toCamera): ("CameraSpace ["+ (magma.getNodeProperty theID "inputType")[1] + "]")
				(theType as name == #fromSpace): ("WorldSpace ["+ (magma.getNodeProperty theID "inputType")[1] + "]" )
				(theType as name == #toSpace): ("Object Space ["+ (magma.getNodeProperty theID "inputType")[1] + "]" )
				(magma.GetContainerSource() == theID ): --generalizing handling of all loop inputs inside the loop body
				(
					--local modSockets = magma.getNodeProperty EditableBlopStack[EditableBlopStack.count] "outputMask"
					if theIndex == 1 then "Iteration Index" else 
					(
						local theInputsCount = magma.getNodeProperty EditableBlopStack[EditableBlopStack.count] "numInputs"
						local theOutputsCount = magma.getNodeProperty EditableBlopStack[EditableBlopStack.count] "numOutputs"
						theName = magma.getNodeProperty EditableBlopStack[EditableBlopStack.count] ("BLOPInputSocketName"+(theIndex-1) as string)
						if theName == undefined or theName == "" do theName = "Input " + (theIndex-1) as string 
						if (theIndex-1) > theInputsCount do 
						(
							theName = magma.getNodeProperty EditableBlopStack[EditableBlopStack.count] ("BLOPOutputSocketName"+(theIndex-1-theInputsCount) as string)
							if theName == undefined or theName == "" do theName = "Accumulator " + (theIndex-1) as string 
							theName = "["+theName+"]"
						)
						theName
					)
				)
				
				default: (
					if theType as name == #inputGeometry and theIndex == 1 then
					(
						local theNodes = (magma.GetNodeProperty theID "nodes")
						if theNodes == undefined do theNodes = #()
						
						if theNodes.count == 1 and isValidNode theNodes[1] then 
							theNodes[1].name
						else if theNodes.count == 0 then 
							"<None>" 
						else theNodes.count as string + " Geo.Objects"
					)
					else if theType as name == #inputObject and theIndex == 1 then 
					(
						( try ((magma.GetNodeProperty theID "object").name  )catch("<None>") )
					)
					else if theType as name == #inputParticles and theIndex == 1 then 
					(
						( try ((magma.GetNodeProperty theID "node").name  )catch("<None>") )
					)
					else
						magma.GetNodeOutputDescription theID theIndex 
				)
			)
			returnValue + " " +theConnectionTypeString
			)catch("???")
		)
		
		fn getInputSocketName theID theSocket includeValue:true =
		(
				--format "--------------------------\n"
				--format "theID=% theSocket=%\n" theID theSocket
			
			try(
				local OutOutputIndex = (magma.GetNodeInput theID theSocket)
				local theName = ""
				local theSocketName  = ""
				local theType = (magma.getNodeType theID) as name
				if magma.isNodeContainer theID then -- generalized support for all containers, including BLOPs and all LOOPs
				(
					local theInputsCount = magma.getNumNodeInputs theID
					if (magma.getNodeProperty theID "uiType") as name == #Loop then
					(
						local theCustomInputsCount = magma.getNodeProperty theID "numInputs"
						local theOutputsCount = magma.getNodeProperty theID "numOutputs"
						--format "% % % % %\n" theID theSocket theInputsCount theCustomInputsCount theOutputsCount
						
						theSocketName = magma.getNodeProperty theID ("BLOPInputSocketName"+(theSocket-(theInputsCount-theCustomInputsCount-theOutputsCount)) as string)
						if theSocketName == undefined or theSocketName == "" do theSocketName = magma.GetNodeInputDescription theID theSocket					
						
						if theSocket > theInputsCount-theOutputsCount do
						(
							theSocketName = magma.getNodeProperty theID ("BLOPOutputSocketName"+(theSocket-(theInputsCount-theOutputsCount)) as string)
							if theSocketName == undefined or theSocketName == "" do theSocketName = "Accumulator " + (theSocket-(theInputsCount-theOutputsCount)) as string
							theSocketName = "["+theSocketName+"]"
						)
					)
					else
					(
						theSocketName = magma.getNodeProperty theID ("BLOPInputSocketName"+theSocket as string)
						if theSocketName == undefined or theSocketName == "" do theSocketName = magma.GetNodeInputDescription theID theSocket					
					)
				)
				else if magma.GetContainerSource() == theID then
				(
					theSocketName = magma.GetNodeInputDescription theID theSocket
					if theSocketName == undefined do theSocketName = ("Input "+ theSocket as string)
				)
				else if theType == #Loop__Output then
				(
					if theSocket == 1 then 
						theSocketName = "Loop Condition" 
					else
					(
						theSocketName = magma.getNodeProperty EditableBlopStack[EditableBlopStack.count] ("BLOPOutputSocketName"+(theSocket-1) as string)
						if theSocketName == undefined or theSocketName == "" do theSocketName = "Accumulator " + (theSocket-1) as string
						theSocketName="["+theSocketName+"]"
					)
				)
				else if magma.GetContainerSink() == theID  then
				(
					theSocketName = magma.getNodeProperty EditableBlopStack[EditableBlopStack.count] ("BLOPOutputSocketName"+theSocket as string)
					--if theSocketName == undefined do theSocketName = ("Output "+ theSocket as string)
					if magma.getNodeProperty EditableBlopStack[EditableBlopStack.count] "uiType" == "Loop" then
					(
						if theSocketName == undefined do theSocketName = ("Accumulator "+ theSocket as string)
						theSocketName="["+theSocketName+"]"
					)
					else
						if theSocketName == undefined do theSocketName = ("Output "+ theSocket as string)
				)
				else
				(
					theSocketName = magma.GetNodeInputDescription theID theSocket
					if theSocketName == undefined do theSocketName = ("Input "+ theSocket as string)
				)
				if includeValue then
				(
					if MagmaFlowSettings.showInputSocketName do theName = theSocketName
					if OutOutputIndex[1] == -1 then 
					(
						theName = theSocketName
						local theDefaultValue = magma.getNodeInputDefaultValue theID theSocket
						if theDefaultValue != undefined do 
						(
							if not MagmaFlowSettings.showInputSocketName do theName = ""
							theName += " "+ theDefaultValue as string + ""
						)
					)
					else
					(
						if MagmaFlowSettings.showInputSocketValue do 
						(
							if MagmaFlowSettings.showInputSocketName do theName += " ("
							theName += getOutputSocketName OutOutputIndex[1] OutOutputIndex[2]
							if MagmaFlowSettings.showInputSocketName do theName += ")"
						)
					)
				)
				else
					theName = theSocketName
			)catch(theName = "???")
			theName
		)
		
		fn getInputSocketColor theID theSocket =
		(
			local OutOutputIndex = (magma.GetNodeInput theID theSocket)[1]
			local hasDefault = (magma.GetNodeInputDefaultValue theID theSocket) != undefined
			--special handling for To/FromSpace second socket:
			if not hasDefault and theSocket == 2 and findItem #(#ToSpace,#FromSpace) ((magma.getNodeType theID) as name) > 0  and isValidNode (magma.getNodeProperty theID "node") do hasDefault = true
			if OutOutputIndex == -1 then 
				if hasDefault then MagmaFlowColors.HasDefaultSocketColor else MagmaFlowColors.NeedsConnectionSocketColor 
			else
			(
				theType = try( (magma.getNodeType OutOutputIndex) as name )catch(#error)
				case theType of 
				(
					default: MagmaFlowColors.StandardSocketColor
					/*
					#InputValue: (
						local theVal = (magma.GetNodeProperty OutOutputIndex "controller").value 
						local isInt = magma.getNodeProperty OutOutputIndex "forceInteger"
						case classof theVal of
						(
							default: (if isInt then MagmaFlowColors.IntegerSocketColor else MagmaFlowColors.FloatSocketColor )
							Point3: MagmaFlowColors.VectorSocketColor
						)
					)
					#InputChannel: (
						MagmaFlowColors.StandardSocketColor
					)*/
					#error: MagmaFlowColors.ErrorSocketColor 
				)
			)
		)
		
		fn getOutputSocketColor theID theSocket =
		(
			for c = 1 to magma.getNumNodeInputs theID do
			(
				local OutOutputIndex = (magma.GetNodeInput theID c)[1]
				local hasDefault = (magma.GetNodeInputDefaultValue theID c) != undefined
				if OutOutputIndex == -1 then 
					if not hasDefault do return MagmaFlowColors.NeedsConnectionSocketColor 
			)
			
			theConnectedNodes = #()
			for theID2 in Magma.GetNodes() do
			(
				for c = 1 to magma.getNumNodeInputs theID2 do
				(
					local theWire = magma.getNodeInput theID2 c 
					if theWire != undefined do
						if theWire[1] == theID and theWire[2] == theSocket do 
							append theConnectedNodes #(theID2,c)
				)
			)
			
			--local theConnected = (magma.GetConnectedNodes theID)[theSocket]
			local theConnected = (magmaFlowEditor_Functions.getConnectedNodes magma theID)[theSocket]
			if theConnected == undefined do theConnected  = #()
			
			local theOutputConnections = #()
			for c in theConnected do 
			(
				local theWire = magma.getNodeInput c[1] c[2]
				theOutputConnections[theWire[2]] = c
			)
			if theOutputConnections[theSocket] != undefined then
			(
				if theOutputConnections[theSocket][1] < 0 then 
					color 0 100	0
				else
				(
					if magma.getNodeType theID == "InputValue" then
					(
						if (classof (magma.getNodeProperty theID "controller").value) == Float then
						(
							if magma.getNodeProperty theID "forceInteger" == true then
								MagmaFlowColors.IntegerSocketColor
							else
								MagmaFlowColors.FloatSocketColor 
						)
						else
							MagmaFlowColors.VectorSocketColor
					)
					else
						MagmaFlowColors.StandardSocketColor
				)
				--catch(MagmaFlowColors.StandardSocketColor)
			)else --MagmaFlowColors.StandardSocketColor
			if theConnectedNodes.count > 0 then
				color 140 140 200
			else
				color 0 150 0
		)		

		fn stampChildBranchConnected theChild theParent =
		(
			local parentState = magma.getNodeProperty theParent "Internal_NodeConnected" == true
			magma.setNodeProperty theChild "Internal_NodeConnected" parentState
			for c = 1 to magma.getNumNodeInputs theChild do
			(
				local theWire = magma.getNodeInput theChild c
				if theWire != undefined and theWire[1] > -1 do
					stampChildBranchConnected theWire[1] theChild
			)
		)			
		
		fn UpdateConnectivityInfo =
		(
			for theID in Magma.GetNodes() do
			(
				magma.declareExtensionProperty theID "Internal_NodeConnected"
				magma.setNodeProperty theID "Internal_NodeConnected" false
				--if magma.getNodeType theID == "Loop__Output" do magma.setNodeProperty theID "Internal_NodeConnected" true
				--magma.declareExtensionProperty theID "Internal_ConnectedNodes"
				--magma.setNodeProperty theID "Internal_ConnectedNodes" #()
			)

			if magma.NumEditingBLOPs() > 0 then
			(
				local numBLOPOutputs = magma.GetNumNodeOutputs (magma.CurrentBLOP) 
				for i = 1 to numBLOPOutputs+1 do
				(				
					local theConnection = magma.GetOutput i --get the output i
					local theConnectedID = theConnection[1] --get the ID of the node that is connected
					--format "% theConnection=% theConnectedID=%\n" i theConnection theConnectedID
					if theConnectedID != undefined and theConnectedID > -1 do
					(
						try
						(
							magma.setNodeProperty theConnectedID "Internal_NodeConnected" true
							for c = 1 to magma.getNumNodeInputs theConnectedID do
							(
								local theWire = magma.getNodeInput theConnectedID c
								if theWire != undefined and theWire[1] > -1 do
								(
									stampChildBranchConnected theWire[1] theConnectedID
								)
							)
						)
						catch
						(
							magma.setOutput i -1 -1 --fix BLOP Output Socket connected to deleted node
						)
					)
				)
			)
			else			
			(
				for theID in Magma.GetNodes() do
				(
					if magma.getNodeType theID == "Output" do 
					(
						magma.setNodeProperty theID "Internal_NodeConnected" true
						local theWire = magma.getNodeInput theID 1
						if theWire != undefined and theWire[1] > -1 do
							stampChildBranchConnected theWire[1] theID
					)--end if output
				)
			)
		)		
	
		fn updateWireColorsOnly =
		(
			local st = timestamp()
			
			local nodeArray = Magma.GetNodes()
			local nodeCount = nodeArray.count
			for n = 1 to nodeCount do 
			(
				local theID = nodeArray[n]
				
				local nodeNumber = theID as string
				local theType = magma.GetNodeType theID
				hc.activeNode = n
				
				local isSelected = (magma.getNodeProperty theID "Selected") == true
				
				local theOutCount = magma.GetNumNodeOutputs theID
				if theType == "Output" do theOutCount  = 0		
				local actualOutCount = theOutCount
				
				local isConnectedInFlow = magma.getNodeProperty theID "Internal_NodeConnected"
				if isConnectedInFlow == undefined do isConnectedInFlow = false				
				
				local st2 = timestamp()
				local theInCount = magma.GetNumNodeInputs theID
				
				--CREATE OUTPUT SOCKETS:
				local st2 = timestamp()
				local actualOutIndex = 0
				local ModifiableColor = black

				local theTypeArray = magma.getNodeProperty theID "Internal_OutputValueTypes" 
				if theTypeArray == undefined do theTypeArray = #()
				
				for i = 1 to theOutCount do
				(
					ModifiableColor = case theTypeArray[i] of
					(
						default: (MagmaFlowColors.StandardSocketColor)
						#vector: (MagmaFlowColors.VectorSocketColor)
						#float: (MagmaFlowColors.FloatSocketColor)
						#int: (MagmaFlowColors.IntegerSocketColor)
						#quat: (MagmaFlowColors.VectorSocketColor*1.5)
						#bool: (MagmaFlowColors.IntegerSocketColor)
						#mesh: (red*0.7)
						#object: (red*0.5)
					)						
					
					if (matchPattern theType pattern:"*Loop__Input") and findItem (magma.getNodeProperty (EditableBlopStack[EditableBlopStack.count]) "outputMask") (i-2) > 0 do ModifiableColor = color 200 50 0
					hc.activeSocket = theInCount + i
					hc.connectionColor = (if i == MagmaFlowSettings.nodeInsertSocket and isSelected then
						MagmaFlowColors.HighlightedSocketColor * (if isConnectedInFlow then 1.0 else 0.75)
					else
						--MagmaFlowColors.StandardSocketColor * 
						ModifiableColor * (if isConnectedInFlow then 1.0 else MagmaFlowColors.DimmUnconnectedNode)
					)
				)
			)--end node creation loop
			
			--FranticParticles.LogDebug ("MagmaFlow: Update WIRES Only Took "+((timestamp()-st)) as string + " ms." )
			

			hc.redrawView
		)
		
		fn createNodeTree init:false specificNodeId: =
		(
			local st = timestamp()
			NodeIDMap = #()
			if init do UpdateConnectivityInfo()
			--FranticParticles.LogDebug ("MagmaFlow: CreateNodeTree UpdateConnectivityInfo() Call Took "+((timestamp()-st)) as string + " ms." )
			
			--CLEAR THE DISPLAY IF INITIALIZING:
			if init do
			(
				for i = hc.getNodeCount to 1 by -1 do 
				(
					hc.activeNode = i	
					hc.deleteActiveNode
				)
			)	

			local currentX = 100
			local currentY = 100
			local outputsCounter = 0
			local inputsCounter = 0
			local inputsCounterIncrement = 40
			if magma.NumEditingBLOPs() > 0 do 
			(
				inputsCounter = 25 + 20 * magma.GetNumNodeInputs (magma.CurrentBLOP) 
			)
			
			local st1 = timestamp()
			
			local nodeArray = Magma.GetNodes()
			local nodeCount = nodeArray.count
			for n = 1 to nodeCount do 
			(
				st2 = timestamp()
				local theID = nodeArray[n]
				if specificNodeId == unsupplied or specificNodeId == theID do
				(
					local nodeNumber = theID as string
					local isExposed = (magma.getNodeProperty theID "Exposed") == true
					
					NodeIDMap[n] = theID
					local theType = magma.GetNodeType theID

					if init do hc.addNode
					hc.activeNode = n
					hc.showMiniBitmap = false
					hc.viewAlign = 0
					
					local theNodeName = ""
					if isExposed do theNodeName += "E"
					theNodeName +=nodeNumber + ":"	
					
					local theNameString = MagmaFlowEditor_Functions.getNodeName magma theID
					if theNameString == undefined then 
						theNodeName += theType
					else
						theNodeName += theNameString
					if (matchPattern theType pattern:"Output") do  theNodeName += " "+(outputsCounter+1) as string
					
					
					theNodeName += if magma.getNodeProperty theID "enabled" then "" else " [OFF]"
					
					hc.nodeName =  theNodeName
					if theType == "Elbow" do 	
					(
						case of
						(
							(MagmaFlowSettings.ElbowSize < 35): hc.nodeName = ""
							(MagmaFlowSettings.ElbowSize < 55): hc.nodeName = nodeNumber
							default:()
						)
					)
					local thePos = if MagmaFlowSettings.AutoReorderToggle then 
						(MagmaFlowEditor_Functions.getUIProperty magma theID "Internal_Position")
					else 
						(MagmaFlowEditor_Functions.getUIProperty magma theID "Position")
					hc.activeNodePos = if thePos == undefined then
					(
						if not (matchPattern theType pattern:"Output") do
							currentX += MagmaFlowSettings.NodeWidth + MagmaFlowSettings.NodeXSpace
						[currentX, currentY]
					)
					else
						thePos
					
					local isSelected = (magma.getNodeProperty theID "Selected") == true
					local isCollapsed = (magma.getNodeProperty theID "Collapsed") == true 
					local isBranchCollapsed = (magma.getNodeProperty theID "Internal_BranchCollapsed") == true
					hc.isSelected = isSelected
					hc.activeNodeCollapsed = isCollapsed
					if isBranchCollapsed do hc.activeNodePos = [-10000,-10000]
					
					--CUSTOM DISPLAY SETTINGS
					local theColorMultiplier = if magma.getNodeProperty theID "enabled" then 1.0 else 0.5
					local theColor = color 255 200 200 
					hc.drawLayer = 2
					hc.showBitmapOnly = false
					case of
					(
						(theType as name == #Missing): 
						(
							theColor = MagmaFlowColors.MissingNode
						)
						(matchPattern theType pattern:"Output"): 
						(
							--hc.isCollapsible = false
							if MagmaFlowSettings.outputNodesOnRight == true do hc.viewAlign = 1
							hc.viewAlignOffset = [0,outputsCounter*50]
							outputsCounter += 1
							theColor = MagmaFlowColors.OutputNode 
						)
						(theType as name == #InputValue): 
						(
							local theVal = try ((magma.GetNodeProperty theID "controller").value) catch("???")
							if MagmaFlowSettings.InputsOnTheLeftAll and MagmaFlowSettings.InputsOnTheLeftValue do
							(
								hc.viewAlign = -1
								hc.viewAlignOffset = if MagmaFlowSettings.DepotPlacement == #left then 
									[MagmaFlowSettings.DepotNodeWidth,inputsCounter]
								else
									[0,inputsCounter]
								
								if classof theVal == Point3 and MagmaFlowSettings.showColorSwatchSample then
									inputsCounter += 65
								else
									inputsCounter += 45
							)
							
							local isInt = magma.getNodeProperty theID "forceInteger"
							theColor = case classof theVal of
							(
								default: (if isInt then MagmaFlowColors.InputIntValueNode else MagmaFlowColors.InputFloatValueNode )
								Point3: MagmaFlowColors.InputVectorValueNode
							)
							if MagmaFlowSettings.showColorSwatchSample and classof theVal == Point3 then
							(
								local theNodeBitmap = bitmap 2 2 color:(theVal*255)
								hc.bitmapSize = [20,20]
								hc.NodeBitmap = theNodeBitmap
							)
							else
								hc.NodeBitmap = undefined							
						)
						(theType as name == #InputChannel or theType as name == #LoopChannel): 
						(
							theColor = MagmaFlowColors.InputChannelNode 

							if MagmaFlowSettings.InputsOnTheLeftAll and MagmaFlowSettings.InputsOnTheLeftChannel do
							(
								hc.viewAlign = -1
								hc.viewAlignOffset = if MagmaFlowSettings.DepotPlacement == #left then 
									[MagmaFlowSettings.DepotNodeWidth,inputsCounter]
								else
									[0,inputsCounter]
								inputsCounter += 45
							)
							
						)
						(theType as name == #InputGeometry): 
						(
							theColor = MagmaFlowColors.InputGeometryNode 
							if MagmaFlowSettings.InputsOnTheLeftAll and MagmaFlowSettings.InputsOnTheLeftGeometry do
							(
								hc.viewAlign = -1
								hc.viewAlignOffset = if MagmaFlowSettings.DepotPlacement == #left then 
									[MagmaFlowSettings.DepotNodeWidth,inputsCounter]
								else
									[0,inputsCounter]
								inputsCounter += 60
							)
						)
						(theType as name == #InputParticles):
						(
							theColor = MagmaFlowColors.InputParticlesNode
							if MagmaFlowSettings.InputsOnTheLeftAll and MagmaFlowSettings.InputsOnTheLeftParticles do
							(
								hc.viewAlign = -1
								hc.viewAlignOffset = if MagmaFlowSettings.DepotPlacement == #left then 
									[MagmaFlowSettings.DepotNodeWidth,inputsCounter]
								else
									[0,inputsCounter]
								
								--hc.viewAlignOffset = [0,inputsCounter*inputsCounterIncrement]
								inputsCounter += 60	
							)
						)
						(theType as name == #InputObject):
						(
							theColor = MagmaFlowColors.InputObjectNode
							if MagmaFlowSettings.InputsOnTheLeftAll and MagmaFlowSettings.InputsOnTheLeftObject do
							(
								hc.viewAlign = -1
								hc.viewAlignOffset = if MagmaFlowSettings.DepotPlacement == #left then 
									[MagmaFlowSettings.DepotNodeWidth,inputsCounter]
								else
									[0,inputsCounter]
								--hc.viewAlignOffset = [0,inputsCounter*inputsCounterIncrement]
								inputsCounter += 45		
							)
						)
						(theType as name == #InputScript):
						(
							theColor = MagmaFlowColors.InputScriptNode
							if MagmaFlowSettings.InputsOnTheLeftAll and MagmaFlowSettings.InputsOnTheLeftScript do
							(
								hc.viewAlign = -1
								hc.viewAlignOffset = if MagmaFlowSettings.DepotPlacement == #left then 
									[MagmaFlowSettings.DepotNodeWidth,inputsCounter]
								else
									[0,inputsCounter]
								--hc.viewAlignOffset = [0,inputsCounter*inputsCounterIncrement]
								inputsCounter += 40
							)
						)
						(theType as name == #CurrentMesh):
						(
							theColor = MagmaFlowColors.InputGeometryNode
						)
						(theType as name == #InputBoundBox):
						(
							theColor = MagmaFlowColors.InputObjectNode
						)
						(theType as name == #Elbow):
						(
							--hc.nodeBitmap = theElbowBitmap
							--hc.showBitmapOnly = true
						)
						(theType as name == #InputTexmap or theType as name == #TexmapEval):
						(
							theColor = MagmaFlowColors.InputTextureNode
							if MagmaFlowSettings.showTextureMapSample then
							(
								local theNodeBitmap = NodeBitmapsCache[theID+1]
								local theMap = magma.getNodeProperty theID "texmap"
								if theNodeBitmap == undefined and theMap != undefined then --
								(
									theNodeBitmap = renderMap theMap size:[MagmaFlowSettings.NodeWidth-6,MagmaFlowSettings.NodeWidth-6] scale:250 filter:true display:false filename:(GetDir #temp + "\\MagmaFlow_temp.bmp")
									hc.bitmapSize = [MagmaFlowSettings.NodeWidth,MagmaFlowSettings.NodeWidth]
									hc.NodeBitmap = theNodeBitmap
									hc.showMiniBitmap = true
								)
								else
									hc.NodeBitmap = undefined
							)
							else hc.NodeBitmap = undefined
						)
						(magma.IsNodeContainer theID): 
						(
							theColor = MagmaFlowColors.EditableBLOPNode  
						)
						
						(theType as name == #BlopSocket):
						(
							hc.nodeName = "BLOP INPUTS"
							hc.isCollapsible = false
							hc.viewAlign = -1
							if MagmaFlowSettings.DepotPlacement == #left do 
								hc.viewAlignOffset = [MagmaFlowSettings.DepotNodeWidth,0]
							theColor = color 200 255 200	
						)
						(theType as name == #BlopOutput):
						(
							--NodeIDMap[editorNodeCount] = -1
							hc.nodeName = "BLOP OUTPUTS"
							hc.isCollapsible = false
							hc.viewAlign = 1
							theColor = color 200 255 200							
						)							
						(matchPattern theType pattern:"*Loop__Input"):
						(
							hc.nodeName = "LOOP INPUTS"
							hc.isCollapsible = false
							hc.viewAlign = -1
							if MagmaFlowSettings.DepotPlacement == #left do 
								hc.viewAlignOffset = [MagmaFlowSettings.DepotNodeWidth,0]
							theColor = color 200 255 200	
						)
						(matchPattern theType pattern:"*Loop__Output"):
						(
							hc.nodeName = "LOOP OUTPUTS"
							hc.isCollapsible = false
							hc.viewAlign = 1
							theColor = color 200 255 200							
						)
						default: 
						(
							local theTypeCat = magma.GetTypeCategory theType
							case theTypeCat of 
							(	
								"Function": (
									theColor = if isProperty MagmaFlowColors #FunctionOperatorNode then MagmaFlowColors.FunctionOperatorNode else MagmaFlowColors.OperatorNode
								)
								"Logic": theColor = MagmaFlowColors.LogicOperatorNode
								"Ember": try(theColor = MagmaFlowColors.EmberOperatorNode)catch(color 255 200 225 )
								"Object": theColor = MagmaFlowColors.ObjectOperatorNode
								default: theColor = MagmaFlowColors.OperatorNode   
							)
						)
					)
					
					local isConnectedInFlow = magma.getNodeProperty theID "Internal_NodeConnected"
					if isConnectedInFlow == undefined do isConnectedInFlow = false
					if (findItem #(#BlopOutput, #BlopSocket) (theType as name) > 0 or matchPattern theType pattern:"*Loop__Output") do isConnectedInFlow = true
					/*
					local theExistingConnection = magma.getConnectedNodes theID
					if theExistingConnection.count > 0 and (for j in theExistingConnection where j.count > 0 collect j).count == 0 do isConnectedInFlow = false
					*/
					if not isConnectedInFlow do theColor *= MagmaFlowColors.DimmUnconnectedNode
					hc.nodeColor = theColor * theColorMultiplier
					--FranticParticles.LogDebug ("MagmaFlow: CreateNodeTree Node Creation Block Took "+((timestamp()-st2)) as string + " ms." )
					
					
					
					--HIGHLIGHT ERROR:
					if findItem ErrorNodesList theID > 0 and theID > -1 do hc.nodeColor = color 255 80 80
						
					/*FIXME: This code is slow, speed it up! */
					--local st2 = timestamp()	
					--local theExistingConnection = (magmaFlowEditor_Functions.getConnectedNodes magma theID)
					--FranticParticles.LogDebug ("MagmaFlow: CreateNodeTree getConnectedNodes Call Took "+((timestamp()-st2)) as string + " ms." )
					local theOutCount = magma.GetNumNodeOutputs theID
					--if theOutCount == 0 do theOutCount  = 1
					if theType == "Output" do theOutCount  = 0		
					
					
					local actualOutCount = 0
					/*
					if magma.getNodeProperty theID "HideUnconnectedOutputs" == true then
						for i = 1 to theOutCount where theExistingConnection[i].count > 0 do actualOutCount += 1
					else
					*/
					actualOutCount= theOutCount
					
					
					local st2 = timestamp()
					--CREATE INPUT SOCKETS:
					local theInCount = magma.GetNumNodeInputs theID
					local inputSocketPos = 5+actualOutCount*15
					local separatorLocations = magma.getNodeProperty theID "InputSocketSeparators" 
					if theType as name == #BLOPSocket do 
					(
						separatorLocations  = magma.getNodeProperty EditableBlopStack[EditableBlopStack.count] "InputSocketSeparators"
					)
					if separatorLocations == undefined then separatorLocations = #() --else separatorLocations = execute separatorLocations
					
					local theTypeArray = magma.getNodeProperty theID "Internal_OutputValueTypes" 
					if theTypeArray == undefined do theTypeArray = #()

					for i = 1 to theInCount do 
					(
						inputSocketPos += 15
						if init do hc.addInSocket
						hc.activeSocket = i
						if theType as name == #BLOPOutput then
						(
							local theSocketName = magma.getNodeProperty EditableBlopStack[EditableBlopStack.count] ("BLOPOutputSocketName"+i as string)
							if theSocketName == undefined do theSocketName = "Output " + i as string
							hc.socketName = theSocketName + " "
						)
						else
						(
							hc.socketName = getInputSocketName theID i
						)
						
						--FIXME: This is DOG SLOW, need faster code to determine socket colors
						hc.connectionColor = (getInputSocketColor theID i) * (if isConnectedInFlow then 1.0 else MagmaFlowColors.DimmUnconnectedNode)
						
						--hc.connectionColor = MagmaFlowColors.FloatSocketColor * (if isConnectedInFlow then 1.0 else MagmaFlowColors.DimmUnconnectedNode)
						hc.socketPosition = [5,inputSocketPos]
						if theType == "Elbow" then
						(
							hc.socketPosition = [4,MagmaFlowSettings.ElbowSize/2-3]
							hc.socketName = ""
						)
						if theType == "Output" do 
						(
							local theChannelName = magma.getNodeProperty theID "channelName"
							local theChannelType = magma.getNodeProperty theID "channelType"
							if MagmaFlowEditor_Functions.isRenderElement magma do 
							(
								theChannelName = "RenderElement"
							)
							hc.socketName = theChannelType 
							hc.socketPosition = [5,inputSocketPos]
							hc.nodeName = theID as string + ":OUT:" + theChannelName
						)
						if findItem separatorLocations i > 0 do inputSocketPos+=10
					)
					inputSocketPos+=15
					--FranticParticles.LogDebug ("MagmaFlow: CreateNodeTree Create Input Sockets Block Took "+((timestamp()-st2)) as string + " ms." )
					
					--CREATE OUTPUT SOCKETS:
					local st2 = timestamp()
					local actualOutIndex = 0
					local outputSocketPos = 5
					for i = 1 to theOutCount do
					(
						if init do hc.addOutSocket
						hc.activeSocket = theInCount + i
						local socketIsFlipped = if MagmaFlowSettings.AutoReorderToggle == true then false else (magma.getNodeProperty theID "FlipSocketPosition" == true)
						if theType == "Elbow" do socketIsFlipped = false
						hc.activeSocketFlipped = socketIsFlipped
						local ModifiableColor = black
						
						ModifiableColor = case theTypeArray[i] of
						(
							default: (MagmaFlowColors.StandardSocketColor)
							#vector: (MagmaFlowColors.VectorSocketColor)
							#float: (MagmaFlowColors.FloatSocketColor)
							#int: (MagmaFlowColors.IntegerSocketColor)
							#quat: (MagmaFlowColors.VectorSocketColor*1.5)
							#bool: (MagmaFlowColors.IntegerSocketColor)
							#mesh: (red*0.7)
							#object: (red*0.5)
						)						
						
						/*
						local theExistingConnection = (magmaFlowEditor_Functions.getConnectedNodes magma theID)
						if magma.getNodeProperty theID "HideUnconnectedOutputs" != true OR theExistingConnection[i].count > 0 then
						*/
						(
							actualOutIndex += 1
							if theType == "Elbow" then
								hc.socketPosition = [MagmaFlowSettings.NodeWidth-20,MagmaFlowSettings.ElbowSize/2-3]
							else if theType == "BLOPSocket" or matchPattern theType pattern:"*Loop__Output" then
							(
								outputSocketPos+=15
								hc.socketPosition = [5, outputSocketPos]
								if findItem separatorLocations i > 0 do outputSocketPos +=10
								inputSocketPos = outputSocketPos + 15
							)
							else
								if socketIsFlipped then
									hc.socketPosition = [5,5+actualOutIndex*15]
								else
									hc.socketPosition = [MagmaFlowSettings.NodeWidth-20,5+actualOutIndex*15]
								
							if (matchPattern theType pattern:"*Loop__Input") and findItem (magma.getNodeProperty (EditableBlopStack[EditableBlopStack.count]) "outputMask") (i-2) > 0 do ModifiableColor = color 200 50 0
							if theType as name == #BLOPSocket then
							(
								local theSocketName = magma.getNodeProperty EditableBlopStack[EditableBlopStack.count] ("BLOPInputSocketName"+i as string)
								if theSocketName == undefined or theSocketName == "" do theSocketName = "Input " + i as string
								hc.socketName = theSocketName 
								theInputSocketNames[i] = hc.socketName
							)
							else
								hc.socketName = (getOutputSocketName theID i) +" "
						)
						hc.activeSocketShowValue = false
						

						
						hc.connectionColor = (if i == MagmaFlowSettings.nodeInsertSocket and isSelected then
							MagmaFlowColors.HighlightedSocketColor * (if isConnectedInFlow then 1.0 else 0.75)
						else
--							MagmaFlowColors.StandardSocketColor *
							ModifiableColor * (if isConnectedInFlow then 1.0 else MagmaFlowColors.DimmUnconnectedNode)
						)
						
						
							--(getOutputSocketColor theID i)* (if isConnectedInFlow then 1.0 else MagmaFlowColors.DimmUnconnectedNode)
					)
					--FranticParticles.LogDebug ("MagmaFlow: CreateNodeTree Create Output Sockets Block Took "+((timestamp()-st2)) as string + " ms." )
					
					local theSize = if theType != "Output" then [MagmaFlowSettings.NodeWidth,inputSocketPos] else [MagmaFlowSettings.NodeWidth,35] 
					if theType == "Elbow" do 	
					(
						theSize = [MagmaFlowSettings.ElbowSize,MagmaFlowSettings.ElbowSize]
						hc.nodeNameOffset  = [0,MagmaFlowSettings.ElbowSize/5]
						hc.edgeSize = 100
						hc.activeNodeCollapsed = false
						hc.isCollapsible = true
						hc.nodeCollapsedSize = theSize
						hc.socketName = ""
					)
					hc.nodeSize = theSize
				)--end if specific ID
				try(hc.nodeCollapsedSize = [hc.nodeSize.x,25]	)catch()
			)--end node creation loop
			
			--FranticParticles.LogDebug ("MagmaFlow: CreateNodeTree N Loop Took "+((timestamp()-st1)) as string + " ms." )
			
			editorNodeCount = nodeCount
			
			local st2 = timestamp()
			--RECREATE CONNECTIONS
			if init do 
			(			
				for n = 1 to nodeCount do --loop through all nodes in the flow
				(
					local theID = nodeArray[n]
					local isBranchCollapsed = (magma.getNodeProperty theID "Internal_BranchCollapsed") == true OR (magma.getNodeProperty theID "Collapsed") == true and MagmaFlowSettings.AllowSubtreeCollapsing == true
					if not isBranchCollapsed do
					(
						for c = 1 to magma.GetNumNodeInputs theID do --get the number of inputs of the current node
						( 
							local theConnection = (magma.GetNodeInput theID c)
							if theConnection[1] >= 0 then
							(
								if (magma.getNodeProperty theConnection[1] "Internal_BranchCollapsed") != true do --AND (magma.getNodeProperty theConnection[1] "Collapsed") != true do
								(
									local theNodeIndex = findItem NodeIDMap theConnection[1] --find what node in the schematic flow it corresponds to
									if theNodeIndex > 0 do
									(
										local numOuts = magma.getNumNodeOutputs theConnection[1] 
										if magma.getNodeType theConnection[1] == "Breakout" do numOuts = 3
										hc.activeNode = theNodeIndex --set the active node to the downstream connected node 
										hc.activeSocket = hc.getSocketCount-numOuts+theConnection[2] --set the active socket to its output (last socket)
										hc.toggleConnection = [n,c]	--create a connection to the upstream node's connection c
									)
								)
							)
						)--end c loop
					)--end if branch collapsed
				)--end connection creation
			)
			--FranticParticles.LogDebug ("MagmaFlow: CreateNodeTree Recreate Connections Took "+((timestamp()-st2)) as string + " ms." )
			
			local st2 = timestamp()
			drawDepot init:init
			/*
			if init do 
			(
				hc.addNode
				hc.activeNode = hc.getNodeCount
				hc.nodeColor = color 240 250 255
				hc.nodeName = "NOTES:"
				hc.nodeSize = [30,20]
				hc.ActiveNodePos = [-1000,-1000]
				hc.drawLayer = 100
				for i = 1 to 10 do 
				(
					hc.addInSocket
					hc.activeSocket = i
					hc.socketPosition = [3,3]
					hc.socketLabelOffset = [-10,5+i*13]
					hc.socketName = ""
					hc.connectionColor = color 240 250 255
				)
			)	
			*/				
			--FranticParticles.LogDebug ("MagmaFlow: CreateNodeTree Draw Depot Took "+((timestamp()-st2)) as string + " ms." )
			
			MagmaFlowSettings.NumEditingBLOPs = magma.NumEditingBLOPs()
			st2 = timestamp()
			updateEditorTitle()
			--FranticParticles.LogDebug ("MagmaFlow: CreateNodeTree Update Title Bar Took "+((timestamp()-st2)) as string + " ms." )
			hc.redrawView	
			--FranticParticles.LogDebug ("MagmaFlow: CreateNodeTree init:"+init as string+" Took "+((timestamp()-st)) as string + " ms." )
		)--end createNodeTree fn
		
		fn debugFlow =
		(
			if MagmaFlowSettings.DebugModeOn == true then
			(
				if not MagmaFlowEditor_DebugRollout.open do
				(
					local thePos = getDialogPos MagmaFlowEditor_Rollout + [0,MagmaFlowEditor_Rollout.height+50]
					if thePos.y > sysinfo.DesktopSize.y-200 do 
						thePos = getDialogPos MagmaFlowEditor_Rollout - [0,430]
					if thePos.y < 0 do thePos = getDialogPos MagmaFlowEditor_Rollout + [0,100]
					createDialog MagmaFlowEditor_DebugRollout MagmaFlowEditor_Rollout.width 400 thePos.x thePos.y style:#(#style_titlebar, #style_border, #style_sysmenu, #style_resizing, #style_minimizebox, #style_maximizebox)
					MagmaFlowEditor_DebugRollout.resizeDialog [MagmaFlowEditor_Rollout.width, 400]
				)
				MagmaFlowEditor_DebugRollout.updateDialog()
			)
			else
			(
				try(destroyDialog MagmaFlowEditor_DebugRollout)catch()
			)
			
		)
		
-----------------------------------------
--CREATE NODE
-----------------------------------------		
		fn sortNodesByXPosition v1 v2 valArray: =
		(
			local v1i = valArray[v1]
			local v2i = valArray[v2]
			if v1i < v2i then -1 else 1
		)
		
		fn connectNodes theSelection =
		(
			local success = false
			if theSelection.count > 1 do
			(
				local nodeArray = Magma.GetNodes()
				
				local thePositions = for i in theSelection collect 
				(
					hc.activeNode = i
					if findItem #("Output","BLOPOutput") (magma.getNodeType nodeArray[i]) > 0 then
						1000000.0
					else if findItem #("BLOPSocket") (magma.getNodeType nodeArray[i]) > 0 then
						-1000000.0
					else
						hc.activeNodePos.x
				)
				
				theIndices = for i = 1 to theSelection.count collect i
				qsort theIndices  sortNodesByXPosition valArray:thePositions
				
				local theNodes = for i in theIndices collect nodeArray[theSelection[i]]
				theSelection = for i in theIndices collect theSelection[i]
					
				--format "theNodes=%\n" theNodes
				
				for m = 2 to theSelection.count do
				(
					local maxNode = theNodes[m]
					local numIns = magma.getNumNodeInputs maxNode
					for c = 1 to numIns do
					(
						local theConnection = magma.getNodeInput maxNode c
						if theConnection[1] == -1 do --if unconnected
						(						
							theDescription = magma.getNodeInputDescription maxNode c
							if matchPattern theDescription pattern:"Lookup Point*" do theDescription = "Pos"
							if matchPattern theDescription pattern:"Ray Origin*" do theDescription = "Pos"	
							if matchPattern theDescription pattern:"Ray Direction*" do theDescription = "InputValue"	
								
							local done = false
							for n = 1 to m-1 while not done do
							(
								local aNode = theNodes[n]
								if aNode > -1 do
								(
									local numOuts = magma.getNumNodeOutputs aNode
									for o = 1 to numOuts while not done do
									(
										if matchPattern (substituteString (magma.getNodeOutputDescription aNode o) " " "") pattern:("*"+theDescription+"*") do
										(
											magma.setNodeInput maxNode c aNode o
											done = true
											success = true
										)
									)
								)
							)
						)--end if
					)--end c loop
				)
				if not success and theNodes.count == 2 and theNodes[1] > -1 and magma.getNumNodeOutputs theNodes[1] == 1 do --if connecting by description failed and the left node has only one output,
				(
					local done = false
					for c = 1 to magma.getNumNodeInputs theNodes[2] while not done do
					(
						local theConnection = magma.getNodeInput theNodes[2] c
						if theConnection[1] == -1 do 
						(
							magma.setNodeInput theNodes[2] c theNodes[1] 1
							done = true		
							success	= true
						)
					)
				)
			)--end if 2 selected
			updateMagmaHolder()
			--createNodeTree init:false
			debugFlow()
			success
		)
		
		fn insertNodeIntoExistingFlow theInsertID =
		(
			local nodeArray = Magma.GetNodes()
			if magma.getNumNodeInputs theInsertID > 0 and magma.getNumNodeOutputs theInsertID > 0 and lastWireSelection[1] != undefined do
			(
				local theNode2 = nodeArray[lastWireSelection[3]]
				local theNode1 = nodeArray[lastWireSelection[1]]
				if theNode1 == theInsertID do 
					theNode1 = nodeArray[ (lastWireSelection[1]+1) ]				
				
				
				local theSocketIndex = 1
				--if findItem #(#Blend) ((magma.getNodeType theInsertID) as name) > 0 do theSocketIndex  = 3 --and findItem #(#InputChannel) (magma.getNodeType theNode1) as name == 0
				if keyboard.shiftpressed do theSocketIndex = magma.getNumNodeInputs theInsertID
				if (magma.getNodeInput theInsertID theSocketIndex)[1] == -1 do --if the socket to connect is still empty
				(
					local theOutCount = magma.getNumNodeOutputs theNode1
					local pos1 = magma.getNodeProperty theNode1 "Position"  
					if pos1 == undefined do pos1 = [0,0]
					pos1 += [0,20+theOutCount*15]
					local theType1 = (magma.getNodeType theNode1)
					if theType1 == "BLOPSocket" do pos1 = [0,0]
						
					local theType2 = (magma.getNodeType theNode2)
					if findItem #("Output","BLOPOutput") theType2 > 0 then
					(
						local cnt = 0
						local nodeArray = Magma.GetNodes()
						for j in nodeArray while j != theNode2 do if magma.getNodeType j == "Output" do cnt+= 1
						local pos2 = ([hc.width-MagmaFlowSettings.NodeWidth, 40+(cnt-1)*60]-hc.pan)/hc.zoom
					)
					else
					(
						local theOutCount = magma.getNumNodeOutputs theNode2
						local pos2 = (magma.getNodeProperty theNode2 "Position") 
						if pos2 == undefined do pos2 = [0,0]
						pos2 += [0,20+theOutCount*15]
					)							
					local theMidPos = (pos1 + pos2) / 2.0 - [0,30]
					magma.setNodeInput theInsertID theSocketIndex  theNode1  (lastWireSelection[2]-(magma.getNumNodeInputs theNode1))
					magma.setNodeInput theNode2  lastWireSelection[4] theInsertID 1
					magma.setNodeProperty theInsertID "Position" theMidPos
					createNodeTree init:true
				)
			)
			lastWireSelection = #()
			MagmaFlowSettings.insertNodeIntoFlow = false
			debugFlow()
		)		
		
		fn connectSelectedNodes =
		(
			local theSelection = getSelectedNodes()
			if lastWireSelection.count > 0 and theSelection.count == 1 then
			(
				local theInsertID = MagmaFlowEditor_Functions.getNodeID magma theSelection[1]
				insertNodeIntoExistingFlow theInsertID
			)
			else
				connectNodes theSelection
		)		
		
		fn createNode theNodeType valueType:#float defaultValue:1.0 channelName:"" channelType:"float32[3]" insertOutSocket:1 mode:#keyboard theScript:"" nodeName:"" =
		(
			local existingSelection = getSelectedNodes()
			local allSelectedAreInputs = true
			theMouse = (((getMouseInSchematicView mode:mode) - [MagmaFlowSettings.NodeWidth/2, 10]  - hc.pan ) / hc.zoom)
			local theNewNode = try(magma.createNode theNodeType)catch(undefined)
			if theNewNode != undefined do
			(
				case theNodeType as name of
				(
					#Output:
					(
						setSelectedNodes #()
						if channelName == "" then
						(
							local theChannelDef = getNewOutputChannel()
							channelName = theChannelDef[1]
							channelType = theChannelDef[2]
						)
						else
						(
							if MagmaFlowEditor_Functions.isChannelFloat magma channelName then channelType = "float16[1]" else
								if MagmaFlowEditor_Functions.isChannelInteger magma channelName then channelType = "int16"
						)
						magma.SetNodeProperty theNewNode "channelName" channelName
						magma.SetNodeProperty theNewNode "channelType" channelType
						nodeType = #output
					)
					#Missing:
					(
						magma.setNumNodeInputs theNewNode 1
						magma.setNumNodeOutputs theNewNode 1
					)
					#InputValue:
					(
						case valueType of
						(
							default:
							(
								local theCtrl = bezier_float()
								theCtrl.value = defaultValue
								magma.SetNodeProperty theNewNode "controller" theCtrl
								--format "%\n" (magma.GetNodeProperty theNewNode "controller")
								--magma.SetNodeProperty theNewNode "forceInteger" false
							)
							#integer:
							(
								local theCtrl = bezier_float()
								theCtrl.value = defaultValue
								magma.SetNodeProperty theNewNode "controller" theCtrl
								magma.SetNodeProperty theNewNode "forceInteger" true
							)
							#vector:
							(
								local theCtrl = point3_xyz()
								theCtrl.value = defaultValue
								magma.SetNodeProperty theNewNode "controller" theCtrl
							)
						)
						nodeType = #input
					)
					#InputChannel:
					(
						if channelName == "" do
						(
							channelName = "Color"
						)
						magma.SetNodeProperty theNewNode "channelName" channelName
						nodeType = #input
					)
					#LoopChannel:
					(
						if channelName == "" do
						(
							channelName = "Color"
						)
						magma.SetNodeProperty theNewNode "channelName" channelName
						nodeType = #input
					)					
					#InputParticles:
					(
						nodeType = #input
					)		
					#InputScript:
					(
						nodeType = #input
						if theScript != "" do magma.setNodeProperty theNewNode "script" theScript
						if nodeName != "" do MagmaFlowEditor_Functions.setUIProperty magma theNewNode "Name" nodeName
					)						
					#InputGeometry:
					(
						nodeType = #input
					)					
					#InputObject:
					(
						nodeType = #input
					)		
					#InputBoundBox:
					(
						nodeType = #input
					)
					#CurrentMesh:
					(
						nodeType = #input
					)		
					#InputTexmap:
					(
						nodeType = #input
					)
					default: 
					(
						nodeType = #operator
					)
				)--end case

				
				if mode == #button then
				(
					if existingSelection.count > 0 then
					(
						local thePos = [0,0]
						local nodeArray = Magma.GetNodes()
						for i in existingSelection do 
							thePos += (magma.getNodeProperty (nodeArray[i]) "Position")
						thePos /= existingSelection.count
						thePos+= [MagmaFlowSettings.NodeWidth+MagmaFlowSettings.NodeXSpace,0]
					)
					else
						thePos = theMouse
				)
				else if mode == #keyboard then
				(
					if existingSelection.count > 0 then
					(
						allSelectedAreInputs = true
						
						local nodeArray = Magma.GetNodes()
						for i in existingSelection where not matchPattern (magma.getNodeType (nodeArray[i])) pattern:"*Input*" do allSelectedAreInputs  = false
								
						local thePos = [0,0]
						local theMaxY = 0
						for i in existingSelection do 
						(
							theNPos = (magma.getNodeProperty (nodeArray[i]) "Position")
							if theNPos == undefined do theNPos = [0,0]
							thePos += theNPos
							hc.activeNode = i
							if theNPos.y+hc.nodeSize.y > theMaxY do theMaxY = theNPos.y+hc.nodeSize.y
						)
						thePos /= existingSelection.count
							
						if allSelectedAreInputs and nodeType == #input then
						(
							thePos.y = theMaxY+MagmaFlowSettings.NodeYSpace
						)
						else
						(
							
							if nodeType == #input then
								thePos -= [MagmaFlowSettings.NodeWidth+MagmaFlowSettings.NodeXSpace,0]
							else
								thePos += [MagmaFlowSettings.NodeWidth+MagmaFlowSettings.NodeXSpace,0]
						)
					)
					else
						thePos = theMouse
				)
				else if mode == #dragwire then
					thePos = theMouse
				else
					thePos = theMouse
				
				MagmaFlowEditor_Functions.setUIProperty magma theNewNode "Position" thePos
				MagmaFlowEditor_Functions.setUIProperty magma theNewNode "Selected" true				
				
				createNodeTree init:true
				
				if ConnectToEmpty_fromID == -1 and ConnectToEmpty_Index > -1 and ConnectToEmpty_SocketType == #input then
				(
					--Connecting BLOP
					try(magma.SetOutput ConnectToEmpty_Index theNewNode 1)catch()
					ConnectToEmpty_Index = -1		
					ConnectToEmpty_SocketType = #none
				)
				else
				if ConnectToEmpty_fromID > -1 and ConnectToEmpty_Index > -1 then
				(
					if ConnectToEmpty_SocketType == #input then
						try(magma.setNodeInput ConnectToEmpty_fromID ConnectToEmpty_Index theNewNode 1)catch()
					else					
					(
						local theIndex1 = MagmaFlowEditor_Functions.getIndexByID magma ConnectToEmpty_fromID
						local theIndex2 = MagmaFlowEditor_Functions.getIndexByID magma theNewNode
						local selectionIndices = getSelectedNodes()
						if findItem selectionIndices theIndex1 == 0 do append selectionIndices theIndex1 
						if findItem selectionIndices theIndex2 == 0 do append selectionIndices theIndex2
						local AutoConnectResult = false
						--if theIndex1 > 0 and theIndex2 > 0 do AutoConnectResult = connectNodes selectionIndices
						if not AutoConnectResult then
						(
							local theNewNodeType = magma.getNodeType theNewNode
							local theOldNodeSocketName = magma.GetNodeOutputDescription ConnectToEmpty_fromID ConnectToEmpty_Index
							local theExistingType = magma.getNodeType ConnectToEmpty_fromID
							local theCat = magma.GetTypeCategory theExistingType				
							local isBoolean = theCat == "Logic" and theExistingType != "Mux" and theExistingType != "Switch"
							
							if theNewNodeType == "Switch" and (matchPattern theOldNodeSocketName pattern:"IsValid" or isBoolean) then
								magma.setNodeInput theNewNode 3 ConnectToEmpty_fromID ConnectToEmpty_Index 
							else
								magma.setNodeInput theNewNode 1 ConnectToEmpty_fromID ConnectToEmpty_Index 
							if  theNewNodeType == "Output" do
							(
								local theOutputName = (magma.GetNodeOutputDescription ConnectToEmpty_fromID ConnectToEmpty_Index )
								local theChannels = MagmaFlowEditor_Functions.loadChannelsList magma
								local theChannelNames = for j in theChannels collect j[1]
								local theIndex = findItem theChannelNames theOutputName							
								if theIndex > 0 do 
								(
									--format "Setting Output To %\n" theChannels[theIndex][1]
									magma.setNodeProperty theNewNode "channelName" theChannels[theIndex][1]
									magma.setNodeProperty theNewNode "channelType" (theChannels[theIndex][2]+"["+theChannels[theIndex][3] as string+"]")
								)
							)
						)
					)
					setSelectedNodes #(MagmaFlowEditor_Functions.getIndexByID magma theNewNode)
					ConnectToEmpty_fromID = -1
					ConnectToEmpty_Index = -1
				)
				else
				(
					--AUTO-CONNECT NODES
					if theNewNode > -1 do
					(
						local nodeArray = Magma.GetNodes()
						local nodeCount = nodeArray.count
						
						--if creating a new operator
						if nodeType == #operator do
						(
							if lastWireSelection.count > 0 then --if a wire was previously selected, insert the new node into it
							(
								insertNodeIntoExistingFlow theNewNode
							)
							else
							(
								local theSocketCount = magma.getNumNodeInputs theNewNode
								/*if theNodeType == "Switch" then
								(
									local done = false
									for c = existingSelection.count to 1 by -1 while not done do
									(
										local theExistingID = nodeArray[existingSelection[c]]
										local theExistingType = magma.getNodeType theExistingID
										local theCat = magma.GetTypeCategory theExistingType				
										local isBoolean = theCat == "Logic" and theExistingType != "Mux" and theExistingType != "Switch"
										if isBoolean do 
										(
											try(magma.SetNodeInput theNewNode 3 theExistingID 1)catch()	
											MagmaFlowEditor_Functions.setUIProperty magma theExistingID "Selected" false
											deleteItem existingSelection c
											done = true
										)
									)
								)*/
								for c = 1 to existingSelection.count while c <= theSocketCount do
								(
									local theID = nodeArray[existingSelection[c]]
									if magma.getNodeType theID != "Output" then
									(
										if MagmaFlowSettings.nodeInsertMode == true then
										(
											local theExistingConnection = (magmaFlowEditor_Functions.getConnectedNodes magma theID)
											if MagmaFlowSettings.nodeInsertSocket > 0 then 
												theExistingConnection = theExistingConnection[MagmaFlowSettings.nodeInsertSocket]
											else 
												theExistingConnection = undefined
											if theExistingConnection != undefined and theExistingConnection.count > 0 do 
											(
												--Connect upstream nodes to the new node if there are existing connections
												for j in theExistingConnection do 
												(
													try(
														magma.setNodeInput j[1] j[2] theNewNode insertOutSocket
													)catch()
												)
												
												if theExistingConnection[1][1] != undefined do
												(
													if magma.getNodeType theExistingConnection[1][1] == "Output" then --figure out relative position to Output node
													(
														local cnt = 0
														for j in nodeArray while j != theExistingConnection[1][1] do if magma.getNodeType j == "Output" do cnt+= 1
														local pos1 = ([hc.width-MagmaFlowSettings.NodeWidth, 40+(cnt-1)*60]-hc.pan)/hc.zoom
													)
													else
													(
														local theOutCount = magma.getNumNodeOutputs theExistingConnection[1][1]
														local pos1 = (magma.getNodeProperty theExistingConnection[1][1] "Position") + [0,18+(theOutCount-1+theExistingConnection[1][2])*15]
														--format "pos1 = %\n" pos1
													)
													local pos2 = (magma.getNodeProperty theID "Position")
													local theMidPosition = (pos1 + pos2)/2.0
													--format "theMidPosition = %\n" theMidPosition
													magma.setNodeProperty theNewNode "Position" theMidPosition
												)
											)
											if MagmaFlowSettings.nodeInsertSocket > 0 then
												try(magma.SetNodeInput theNewNode c theID MagmaFlowSettings.nodeInsertSocket)catch()
											else
												try(magma.SetNodeInput theNewNode c theID 1)catch()									
										)
										else
										(
											try(magma.SetNodeInput theNewNode c theID MagmaFlowSettings.nodeInsertSocket)catch()
										)
									)--end not Output
									else
									(
										--if the Output node has nothing connected into it, connect to the first output socket of the new node
										if (magma.getNodeInput theID 1)[1] == -1 do magma.setNodeInput theID 1 theNewNode 1
									)
									MagmaFlowEditor_Functions.setUIProperty magma theID "Selected" false
								)		
								--format "END Trying to connect to existing selection...\n"
							)
							MagmaFlowEditor_Functions.setUIProperty magma theNewNode "Selected" true
						)
						local connectionSaturatedSockets = false
						if nodeType == #input do
						(
							local done = false
							for c = 1 to existingSelection.count do
							(
								local theID = nodeArray[existingSelection[c]]
								local theSocketCount = magma.getNumNodeInputs theID
								done = false
								for i = 1 to theSocketCount while not done do
								(
									local theInput = magma.getNodeInput theID i
									--format "theInput = %\n" theInput 
									if theInput[1] < 0 do
									(
										magma.SetNodeInput theID i theNewNode 1
										newPos = (magma.getNodeProperty theID "Position") + [-(MagmaFlowSettings.NodeWidth+MagmaFlowSettings.NodeXSpace), (i-1)*50]
										MagmaFlowEditor_Functions.setUIProperty magma theNewNode "Position" newPos
										done = true
										if i == theSocketCount do connectionSaturatedSockets = true
									)
								)
							)
							
							if mode == #keyboard then
							(
								local theID =  if existingSelection[1] == undefined then -1 else nodeArray[existingSelection[1]]
								if existingSelection.count == 1 and (magma.getNodeType theID  == "Output" or connectionSaturatedSockets) then
								(
									setSelectedNodes #()
									MagmaFlowEditor_Functions.setUIProperty magma theNewNode "Selected" true
								)
								else
								(
									setSelectedNodes existingSelection
									MagmaFlowEditor_Functions.setUIProperty magma theNewNode "Selected" allSelectedAreInputs
								)
							)
							else
							(
								setSelectedNodes #()
								MagmaFlowEditor_Functions.setUIProperty magma theNewNode "Selected" true
							)							
							if not done do 
							(	
								
							)
						)
						--If the new node is a transform node, try to adjust the transform type (Point, Vector, Normal) according to the previous node
						if findItem #(#ToWorld, #FromWorld, #ToSpace, #FromSpace ) ((magma.getNodeType theNewNode)  as name) > 0 do
						(
							local previousNode = (magma.GetNodeInput theNewNode 1)[1]
							if previousNode != undefined and previousNode > -1 do
							(
								local previousNodeType = (magma.getNodeType previousNode) as name
								if previousNodeType == #inputChannel or previousNodeType == #loopChannel do
								(
									local theChannelName = magma.getNodeProperty previousNode "channelName"
									if matchPattern theChannelName pattern:"*Normal" do magma.setNodeProperty theNewNode "inputType" "Normal"
									--if matchPattern theChannelName pattern:"*Position" do magma.setNodeProperty theNewNode "inputType" "Point"
								)
								if findItem #(#ToWorld, #FromWorld, #ToSpace, #FromSpace ) previousNodeType > 0 do
								(
									magma.setNodeProperty theNewNode "inputType" (magma.getNodeProperty previousNode "inputType")
								)
							)
						)
					)
				)--end if new node valid
			)
			lastSelection = #()
			updateMagmaHolder update:true
			autoReorderFlow update:false
			debugFlow()
			updateNavigator()
			createUndoRecord ("Created Node ["	+theNodeType +"]")
			displaySelectedNodeProperties()	
			MagmaFlowSettings.nodeInsertMode = not keyboard.shiftpressed 
			MagmaFlowSettings.nodeInsertSocket = 0
			toggleInsertMode update:false
			createNodeTree init:false --specificNodeId:theNewNode
			theNewNode
		)		
		
		fn getNewOutputChannel =
		(
			local tabuChannels = #()

			for i in Magma.GetNodes() where magma.getNodeType i == "Output" do appendIfUnique tabuChannels (magma.getNodeProperty i "channelName")

			if MagmaFlowEditor_Functions.IsRenderElement magma do sourceMode = #relement
			if sourceMode == #relement and tabuChannels.count > 0 do return false
				
			local channelsList = MagmaFlowEditor_Functions.loadChannelsList magma mode:#output 
			local channelsList2 = MagmaFlowEditor_Functions.getSortedChannelsList channelsList 2 theIniFileLocation includeCustom:false nodeType:#output
			channelsList2 = for i in channelsList2 where findItem tabuChannels i == 0 collect i
			if channelsList2.count == 0 do return false
				
			local theType = "float32[3]"
			for i in channelsList where i[1] == channelsList2[1] do 
			(
				theType = i[2]+"["+i[3] as string+"]"
			)
			if sourceMode == #relement then
				#("Color","float16[3]")
			else
				#(channelsList2[1], theType)
		)
		
		fn addNewOutputChannel =
		(
			local theChannelDef = getNewOutputChannel()
			if theChannelDef != false do
			(
				MagmaFlowEditor_Rollout.createNode "Output" channelName:theChannelDef[1] channelType:theChannelDef[2]
				createNodeTree init:true
			)
		)		
		
		
-----------------------------------------
--BLOP HANDLING
-----------------------------------------
		fn createBLOPInline =
		(
			theSel = getSelectedNodes()
			if theSel.count > 0 do
			(
				local theAveragePos = [0,0]
				local nodeArray = Magma.GetNodes()
				local theIDs = for i in theSel collect 
				(
					local theID = nodeArray[i]
					local theType = (magma.getNodeType theID) as name
					if findItem #(#BlopSocket, #BlopOutput, #Output) theType > 0 then dontcollect 
					else
					(
						theAveragePos += magma.getNodeProperty theID "Position"
						theID 
					)
				)
				if theIDs.count > 0 do 
				(
					theAveragePos /= theIDs.count
					local lastError = ""
					local theResult = try(magma.CreateBlop theIDs)catch(lastError = getCurrentException(); undefined)
					if theResult != undefined then
					(
						magma.declareExtensionProperty theResult "Position"
						magma.setNodeProperty theResult "Position" theAveragePos
						createNodeTree init:true
						updateNavigator()
						debugFlow()
						exposeControlsToModifier()
						createUndoRecord "Created BLOP from Selection"	
						
						--WTF?
						--undoLastStep()
						--redoLastStep()
					)
					else
					(
						edt_log.text = substituteString lastError "\n" "  "
					)
				)
			)
		)
		
		fn explodeBLOP nodeID =
		(
			magma.ExplodeBlop nodeID
			createUndoRecord "Explode BLOP"	
			createNodeTree init:true
			updateNavigator()
			debugFlow()
		)
		
-----------------------------------------
--DEPOT HANDLING
-----------------------------------------
		local RCMenus = #()
		local RCMenuNames = #()
		fn createDepot =
		(
			allBlopNames = #()
			allBlopDescriptions = #()
			
			DepotCategories= #()
			
			local theNodeTypes = magma.GetTypeNames()
			for i in theNodeTypes do
				appendIfUnique DepotCategories (magma.GetTypeCategory i)
			sort DepotCategories
			DepotDefinition = #()
			RCMenus = #()
			RCMenuNames = #()
			
			local theNodeTypeNames = for i in Magma.GetTypeNames() where findItem #("BLOPSocket","BLOPOutput") i == 0 collect i
			sort theNodeTypeNames
			
			local theNodesMenu = "" as stringstream
			format "rcmenu allNodes_menu (\n" to:theNodesMenu
			
			for c in DepotCategories do
			(
				theCatNodes = for i in theNodeTypeNames where try(magma.GetTypeCategory i == c)catch(false) collect 
				(
					local theColor = case i as name of
					(
						#Output: MagmaFlowColors.OutputNode
						#InputValue: MagmaFlowColors.InputVectorValueNode
						#InputChannel: MagmaFlowColors.InputChannelNode
						#LoopChannel: MagmaFlowColors.InputChannelNode
						#InputGeometry: MagmaFlowColors.InputGeometryNode
						#InputParticles: MagmaFlowColors.InputParticlesNode
						#InputObject: MagmaFlowColors.InputObjectNode
						#InputScript: MagmaFlowColors.InputScriptNode
						#InputBoundBox: MagmaFlowColors.InputObjectNode
						#CurrentMesh: MagmaFlowColors.InputGeometryNode
						#BLOP: MagmaFlowColors.EditableBLOPNode
						#Loop: MagmaFlowColors.EditableBLOPNode
						#VertexLoop: MagmaFlowColors.EditableBLOPNode
						default: 
						(
							case c of 
							(
								"Logic": MagmaFlowColors.LogicOperatorNode 
								"Object": MagmaFlowColors.ObjectOperatorNode
								"Ember": try(MagmaFlowColors.EmberOperatorNode)catch(color 255 200 225 )
								"Function": (
									if isProperty MagmaFlowColors #FunctionOperatorNode then MagmaFlowColors.FunctionOperatorNode else MagmaFlowColors.OperatorNode
								)
								default: MagmaFlowColors.OperatorNode
							)
						)
					)
					#(c, i , theColor, [0,0], c+": "+ i, true, i)
				)
				if c == "BLOP" do
				(
					local theRootBlops = sort (getFiles (theUserFolder+ "\\BlackOps\\*.MagmaBLOP"))
					for f in theRootBlops do
					(
						local theName = getFileNameFile f
						append theCatNodes #(c, theName, MagmaFlowColors.EditableBLOPNode, [0,0], c+": "+theName, true, theName, (substituteString f "\\" "/") )
						append allBlopNames theName
						local theFileHandle = openFile f
						local theLine = f
						if theFileHandle != undefined do
						(
							skipToString theFileHandle "\"Notes\" " 
							if not eof theFileHandle do theLine = substituteString (readLine theFileHandle) "\\n" " "
						)
						close theFileHandle
						append allBlopDescriptions theLine
					)
					local theSubDirs = getDirectories (theUserFolder+ "\\BlackOps\\*")
					for d in theSubDirs do
					(
						local theName = filterString d "\\"
						theName=theName[theName.count]
						if MagmaFlowSettings.DepotShowBLOPs do
							append theCatNodes #("SUBHEAD", theName , MagmaFlowColors.HeaderColor ,[0,0], "Category: "+d ,true, theName)
						local theBlops = sort (getFiles (d+"*.MagmaBLOP"))
						for f in theBlops do
						(
							local theName = getFileNameFile f
							append theCatNodes #(c, theName, MagmaFlowColors.EditableBLOPNode, [0,0], c+": "+theName, true, theName, (substituteString f "\\" "/"))
							append allBlopNames theName
							local theFileHandle = openFile f
							local theLine = f
							if theFileHandle != undefined do
							(
								skipToString theFileHandle "\"Notes\" " 
								if not eof theFileHandle do theLine = substituteString (readLine theFileHandle) "\\n" " "
							)
							close theFileHandle
							append allBlopDescriptions theLine
						)						
					)
				)
				
				local theUsedLetters=#()
				local theTabuLetter = c[1]
				if c == "Trigonometry" then theTabuLetter = "G"
				append theUsedLetters (bit.charAsInt theTabuLetter)
				for i = 1 to theCatNodes.count do ---where theCatNodes[i][1] != "SUBHEAD"
				(
					local done = false
					local theName = theCatNodes[i][2]
					if theName == "QuatToVectors" then
					(
						append theUsedLetters (bit.charAsInt "Q")
						theCatNodes[i][7] = "&QuatToVectors"
					)
					else if theName == "AngleAxisToQuat" then
					(
						append theUsedLetters (bit.charAsInt "A")
						theCatNodes[i][7] = "&AngleAxisToQuat"
					)
					else if theName == "EulerAnglesToQuat" then
					(
						append theUsedLetters (bit.charAsInt "E")
						theCatNodes[i][7] = "&EulerAnglesToQuat"
					)					
					else
					(
						for j = theName.count to 1 by -1 while not done do
						(
							local theASCII = bit.charAsInt theName[j]
							if theASCII <= 90 and findItem theUsedLetters theASCII == 0 do 
							(
								append theUsedLetters theASCII
								theCatNodes[i][7] = substring theName 1 (j-1) + "&" + substring theName j -1
								done = true
							)
						)--end j loop
						for j = 1 to theName.count while not done do
						(
							local theASCII = bit.charAsInt theName[j]
							if theASCII > 90 do theASCII -= 32
							if findItem theUsedLetters theASCII == 0 do 
							(
								append theUsedLetters theASCII
								theCatNodes[i][7] = substring theName 1 (j-1) + "&" + substring theName j -1
								done = true
							)
						)--end j loop
					)
				)
				--format "theUsedLetters=%\n" theUsedLetters
				--format "theCatNodes = %\n" theCatNodes
				
				local theMenu = "" as stringstream
				format "rcmenu %_menu (\n" c to:theMenu
				format "submenu \"%\" (\n" c to:theNodesMenu
				local theSubMenu1 = "" as stringStream
				local theSubMenu2 = "" as stringStream
				
				local needClosing = false
				local cnt = 0
				local theCurrentEditorIndex = (for i = 1 to MagmaFlowEditor_CurrentEditors.count where MagmaFlowEditor_CurrentEditors[i] != undefined and MagmaFlowEditor_CurrentEditors[i][1] == magma collect i)[1]
				for i in theCatNodes do
				(
					cnt += 1
					local theTitle = i[2]
					if theTitle as name == #InputChannel then
					(
						format "subMenu \"Input&Channel\" (\n" to:theSubMenu1
						local channelsList = MagmaFlowEditor_Functions.loadChannelsList magma mode:#input 
						local theVal = execute (getIniSetting (theIniFileLocation + "MagmaFlowEditor_Preferences.ini") "InputNode" "ChannelSorting" )
						if theVal == OK do theVal = 1	

						local existingOnly = execute (getIniSetting (theIniFileLocation + "MagmaFlowEditor_Preferences.ini") "InputNode" "ExistingChannelsOnly" )
						if existingOnly == OK do existingOnly = false
						local existingChannels = #()
						local existingChannelNames = #()
						local thePossibleVal = if existingOnly then
						(
							local theDeps = refs.dependentNodes magma
							for d in theDeps do
							(
								local theStream = try(FranticParticles.GetPRTObjectIStream d true false)catch(undefined)
								if theStream != undefined do
								(
									for i in (theStream.getChannels()) do 
									(
										local theFS = filterString i " []"
										append theFS "Existing Channel"
										theFS[3] = execute theFS[3]
										if (appendIfUnique existingChannelNames theFS[1]) do append existingChannels theFS
									)
									theStream.close()
								)
							)
							local filteredChannelsList = for c in channelsList where findItem existingChannelNames c[1] > 0 collect c
							local filteredNames = for c in filteredChannelsList collect c[1]
							for c in existingChannels where findItem filteredNames c[1] == 0 do append filteredChannelsList c
							for i in MagmaFlowEditor_Functions.getSortedChannelsList filteredChannelsList theVal theIniFileLocation collect #(i,i)
						)
						else
							for i in MagmaFlowEditor_Functions.getSortedChannelsList channelsList theVal theIniFileLocation collect #(i,i)
								
						
						--deleteItem thePossibleVal 1
						--format "% \n" thePossibleVal 
						local theMappingChannels = for theChannelName in thePossibleVal where matchPattern theChannelName[1] pattern:"Mapping*" collect theChannelName
						
						local theUsedLetters=#()
						local theTabuLetter = "C"
						append theUsedLetters (bit.charAsInt theTabuLetter)
						if theMappingChannels.count > 0 do append theUsedLetters (bit.charAsInt "M")
						
						for i = 1 to thePossibleVal.count do 
						(
							local done = false
							local theName = thePossibleVal[i][1]
							for j = theName.count to 1 by -1 while not done do
							(
								local theASCII = bit.charAsInt theName[j]
								if theASCII <= 90 and findItem theUsedLetters theASCII == 0 do 
								(
									append theUsedLetters theASCII
									thePossibleVal[i][2] = substring theName 1 (j-1) + "&" + substring theName j -1
									done = true
								)
							)--end j loop
							for j = 1 to theName.count while not done do
							(
								local theASCII = bit.charAsInt theName[j]
								if theASCII > 90 do theASCII -= 32
								if findItem theUsedLetters theASCII == 0 do 
								(
									append theUsedLetters theASCII
									thePossibleVal[i][2] = substring theName 1 (j-1) + "&" + substring theName j -1
									done = true
								)
							)--end j loop
						)						
						local channelCnt = 0
						for theChannelName in thePossibleVal where not matchPattern theChannelName[1] pattern:"Mapping*" do
						(
							channelCnt += 1
							format "menuItem mnu_inputchannel_%_% \"%\"\n" theChannelName[1] channelCnt theChannelName[2] to:theSubMenu1
							format "on mnu_inputchannel_%_% picked do (\n" theChannelName[1] channelCnt to:theSubMenu2
							format "MagmaFlowEditor_CurrentEditors[%][2].createNode \"InputChannel\" ChannelName:\"%\" mode:#rcmenu\n"  theCurrentEditorIndex theChannelName[1] to:theSubMenu2
							format "MagmaFlowEditor_CurrentEditors[%][2].createNodeTree init:true\n"  theCurrentEditorIndex to:theSubMenu2
							format ")\n" to:theSubMenu2
						)--end channel loop
						
						if theMappingChannels.count > 0 do
						(
							format "subMenu \"&Mapping Channels\" (\n" to:theSubMenu1
							for theChannelName in theMappingChannels do
							(
								channelCnt += 1
								format "menuItem mnu_inputchannel_%_% \"%\"\n" theChannelName[1] channelCnt theChannelName[2] to:theSubMenu1
								format "on mnu_inputchannel_%_% picked do (\n" theChannelName[1] channelCnt to:theSubMenu2
								format "MagmaFlowEditor_CurrentEditors[%][2].createNode \"InputChannel\" ChannelName:\"%\" mode:#rcmenu\n"  theCurrentEditorIndex theChannelName[1] to:theSubMenu2
								format "MagmaFlowEditor_CurrentEditors[%][2].createNodeTree init:true\n"  theCurrentEditorIndex to:theSubMenu2
								format ")\n" to:theSubMenu2
							)--end channel loop
							format ")\n" to:theSubMenu1
						)
						
						format ")\n" to:theSubMenu1
						
					)
					else if theTitle as name == #InputValue then
					(
						format "separator sep_inputValue \n" to:theSubMenu1
						for j in #(#("Integer","I&nteger",1),#("Float","&Float",1.0),#("Vector","&Vector",[0,0,0])) do
						(
							format "menuitem mnu_%_%_% \"InputValue:%\" \n" c cnt j[1] j[2] to:theSubMenu1
							format "on mnu_%_%_% picked do (\n" c cnt j[1] to:theSubMenu2
							format "MagmaFlowEditor_CurrentEditors[%][2].createNode \"%\" valueType:#% defaultValue:% mode:#rcmenu\n"  theCurrentEditorIndex i[2] j[1] j[3] to:theSubMenu2
							format "MagmaFlowEditor_CurrentEditors[%][2].createNodeTree init:true\n"  theCurrentEditorIndex to:theSubMenu2
							format ")\n" to:theSubMenu2
						)
					)
					else
					(
						if i[1] != "SUBHEAD" then
						(
							format "menuitem mnu_%_% \"%\" \n" c cnt i[7] to:theSubMenu1
							format "on mnu_%_% picked do (\n" c cnt to:theSubMenu2
							if i[1] == "BLOP" and i[2] != "BLOP" then
							(
								format "MagmaFlowEditor_CurrentEditors[%][2].createNodeBLOP \"%\"\n"  theCurrentEditorIndex  i[8] to:theSubMenu2
								format "MagmaFlowEditor_CurrentEditors[%][2].createNodeTree init:true\n"  theCurrentEditorIndex to:theSubMenu2
							)
							else
							(
								format "MagmaFlowEditor_CurrentEditors[%][2].createNode \"%\" mode:#rcmenu\n"  theCurrentEditorIndex i[2] to:theSubMenu2
								format "MagmaFlowEditor_CurrentEditors[%][2].createNodeTree init:true\n"  theCurrentEditorIndex to:theSubMenu2
							)
							format ")\n" to:theSubMenu2
						)
						else
						(
							if needClosing do format ")\n" to:theSubMenu1
							format "subMenu \"%\" (\n" i[7] to:theSubMenu1
							needClosing = true
						)
					)
				)
				if needClosing do format ")\n" to:theSubMenu1

				format "%" (theSubMenu1 as string) to:theMenu
				format "%" (theSubMenu2 as string) to:theMenu
				format ")\n" to:theMenu
				
				format "%" (theSubMenu1 as string) to:theNodesMenu
				format ")\n" to:theNodesMenu
				format "%" (theSubMenu2 as string) to:theNodesMenu
				
				append RCMenuNames (c as name)
				append RCMenus (execute (theMenu as string))
				local catName = c
				if catName == "Trigonometry" and MagmaFlowSettings.DepotNodeWidth < 80 do catName = "Trigonom."
				append DepotDefinition (join #(#("HEAD", catName , MagmaFlowColors.HeaderColor ,[0,0], "Category: "+c ,false)) theCatNodes)
					
			)--end c loop
			
			format ")\n" to:theNodesMenu
			append RCMenuNames #allNodes
			append RCMenus (execute (theNodesMenu as string))
			--format "%\n" (theNodesMenu as string)
		)
		
		fn updateDepotDefinition =
		(
			--print "--DepotDefinition:"
			--print DepotDefinition
			DepotNodes = #()
			if MagmaFlowSettings.DepotShowCategories == true then
			(
				for i in DepotDefinition do 
				(
					if i[1][1] == "HEAD" do
						if i[1][6] == true then
							for j = 1 to i.count do append DepotNodes (deepCopy i[j])
						else
							append DepotNodes (deepCopy i[1])
				)		
			)
			else
			(
				for i in DepotDefinition do 
					for j = 2 to i.count do append DepotNodes (deepCopy i[j])
			)	
			--print "--DepotNodes:"
			--print DepotNodes
		)		
		
		fn prepareDepotForDragAndDrop =
		(
			if MagmaFlowSettings.DepotPlacement == #off do return false
			for i = 1 to DepotNodes.count do
			(
				hc.activeNode = editorNodeCount+i
				DepotNodes[i][4] = hc.activeNodePos
			)				
		)		
		
		fn createNodeBLOP theSourceFile =
		(
			local existingSelection = getSelectedNodes()
			::magmaNode = magma
			local oldNotes = magma.note
			magma.Loading=true
			fileIn theSourceFile 
			magma.Loading=false
			magma.note = oldNotes
			local theNewNode = MagmaFlowEditor_Functions.getNodeID magma #last 
			local theMouse = (((getMouseInSchematicView mode:#keyboard) - [MagmaFlowSettings.NodeWidth/2, 10]  - hc.pan ) / hc.zoom)
			MagmaFlowEditor_Functions.setUIProperty magma theNewNode "Position" theMouse
			MagmaFlowEditor_Functions.setUIProperty magma theNewNode "Selected" true
			MagmaFlowEditor_Functions.setUIProperty magma theNewNode "Name" (getFileNameFile theSourceFile)
			if lastWireSelection.count > 0 then
			(
				insertNodeIntoExistingFlow theNewNode
			)			
			else
			(
				local nodeArray = magma.getNodes()
				local theSocketCount = magma.getNumNodeInputs theNewNode
				for c = 1 to existingSelection.count while c <= theSocketCount do
				(
					local theID = nodeArray[existingSelection[c]]
					if magma.getNodeType theID != "Output" then
					(
						if MagmaFlowSettings.nodeInsertMode == true then
						(
							local theExistingConnection = (magmaFlowEditor_Functions.getConnectedNodes magma theID)
							if MagmaFlowSettings.nodeInsertSocket > 0 then 
								theExistingConnection = theExistingConnection[MagmaFlowSettings.nodeInsertSocket]
							else 
								theExistingConnection = undefined
							if theExistingConnection != undefined and theExistingConnection.count > 0 do 
							(
								for j in theExistingConnection do 
								(
									try(
										magma.setNodeInput j[1] j[2] theNewNode 1
									)catch()
								)
								if theExistingConnection[1][1] != undefined do
								(
									if magma.getNodeType theExistingConnection[1][1] == "Output" then --figure out relative position to Output node
									(
										local cnt = 0
										for j in nodeArray while j != theExistingConnection[1][1] do if magma.getNodeType j == "Output" do cnt+= 1
										local pos1 = ([hc.width-MagmaFlowSettings.NodeWidth, 40+(cnt-1)*60]-hc.pan)/hc.zoom
									)
									else
									(
										local theOutCount = magma.getNumNodeOutputs theExistingConnection[1][1]
										local pos1 = (magma.getNodeProperty theExistingConnection[1][1] "Position") + [0,18+(theOutCount-1+theExistingConnection[1][2])*15]
										--format "pos1 = %\n" pos1
									)
									local pos2 = (magma.getNodeProperty theID "Position")
									local theMidPosition = (pos1 + pos2)/2.0
									--format "theMidPosition = %\n" theMidPosition
									magma.setNodeProperty theNewNode "Position" theMidPosition
								)
							)
							if MagmaFlowSettings.nodeInsertSocket > 0 then
								try(magma.SetNodeInput theNewNode c theID MagmaFlowSettings.nodeInsertSocket)catch()
							else
								try(magma.SetNodeInput theNewNode c theID 1)catch()									
						)
						else
						(
							try(magma.SetNodeInput theNewNode c theID MagmaFlowSettings.nodeInsertSocket)catch()
						)
					)--end not Output
					else
					(
						if (magma.getNodeInput theID 1)[1] == -1 do magma.setNodeInput theID 1 theNewNode 1
					)
					MagmaFlowEditor_Functions.setUIProperty magma theID "Selected" false
				)		
			)
			autoReorderFlow createUndo:false
			exposeControlsToModifier()
			lastSelection = #()
			displaySelectedNodeProperties()	
			createUndoRecord ("Created BLOP '"+(getFileNameFile theSourceFile)+"'")
		)
		
		fn handleDepotDragAndDrop =
		(
			local returnValue = false
			if MagmaFlowSettings.DepotPlacement == #off do return false
			local minY = hc.height-36
			for i = 1 to DepotNodes.count do
			(
				hc.activeNode = editorNodeCount+i
				if DepotNodes[i][1] != "HEAD" and DepotNodes[i][1] != "SUBHEAD" and DepotNodes[i][4] != undefined do
				(
					if (MagmaFlowSettings.DepotPlacement==#left and hc.activeNodePos.x > DepotNodes[i][4].x) or ((MagmaFlowSettings.DepotPlacement==#bottom or MagmaFlowSettings.DepotPlacement==#bottomrollup or MagmaFlowSettings.DepotPlacement==#bottomrollupreverse ) and (getMouseInSchematicView()).y < minY and hc.activeNodePos.y != DepotNodes[i][4].y) do
					(
						lastMouseClick = getMouseInSchematicView() - [MagmaFlowSettings.NodeWidth/2,0]
						local result = (hc.findNodeByPos = getMouseInSchematicView())							
							
						if result  <= (magma.GetNodes()).count and result > 0 then lastSelectionBeforeClick = #(result) else lastSelectionBeforeClick = #()
							
						setSelectedNodes lastSelectionBeforeClick
						if DepotNodes[i][1] == "BLOP" then
						(
							if DepotNodes[i][2]  == "BLOP" then
							(
								createNode DepotNodes[i][2] 
							)
							else
							(
								createNodeBLOP DepotNodes[i][8]
							)
						)
						else
						(
							if DepotNodes[i][2] == "Output" then
								addNewOutputChannel()
							else
								createNode DepotNodes[i][2] 
						)
						returnValue = true
						if MagmaFlowSettings.DepotAutoCollapseOnDragAndDrop do
						(
							createDepot()
							updateDepotDefinition()
						)
						createNodeTree init:true					
						exit
					)
				)
				hc.activeNodePos = DepotNodes[i][4]
			)		
			hc.redrawView		
			returnValue			
		)		
		
		fn drawDepot init:false lock:false =
		(
			updateDepotDefinition()
			if hc.height == undefined or depotDefinition.count == 0 do return false --bail out if the helium control is not defined (editor is not open!)
			leftDepotMargin = 0
			if MagmaFlowSettings.DepotPlacement == #off do return false
				
			if MagmaFlowSettings.DepotPlacement == #bottom do
			(
				local DepotX = 0
				local theHCount = (hc.width/MagmaFlowSettings.DepotNodeWidth/hc.zoom) 
				local theVCount = ceil (DepotNodes.count/theHCount)
				local DepotY = (hc.height-(18+(theVCount*18/hc.zoom)))
			)
			if MagmaFlowSettings.DepotPlacement == #left do
			(
				local DepotX = 0
				local DepotY = 0
				leftDepotMargin = MagmaFlowSettings.DepotNodeWidth
			)
			
			if MagmaFlowSettings.DepotPlacement == #bottomrollup do
			(
				local DepotX = 0
				local theHCount = depotDefinition.count
				local ArrayCnt = 1
				local theVCount = if depotDefinition[ArrayCnt][1][6] then depotDefinition[ArrayCnt].count else 1
				local DepotY = (hc.height-(18+theVCount*18/hc.zoom))
			)
			if MagmaFlowSettings.DepotPlacement == #bottomrollupreverse do
			(
				local DepotX = 0
				local theHCount = depotDefinition.count
				local ArrayCnt = 1
				local theVCount = if depotDefinition[ArrayCnt][1][6] then depotDefinition[ArrayCnt].count else 1
				local DepotY = (hc.height-36)
			)	
			
			theNodeCount = editorNodeCount --magma.getNumNodes()
			for i = 1 to DepotNodes.count do
			(
				if init do hc.addNode
				hc.activeNode = theNodeCount+i
				hc.nodeName = DepotNodes[i][2]
				hc.nodeColor = DepotNodes[i][3] * (if DepotNodes[i][1]=="HEAD" then (if DepotNodes[i][6] == true then 1.0 else (if MagmaFlowSettings.DepotCategoryTransparent then 0.0 else 0.01) ) else 1.0)
				hc.nodeSize = [(MagmaFlowSettings.DepotNodeWidth-2)/hc.zoom,15/hc.zoom]
				hc.nodeCollapsedSize = hc.nodeSize 
				hc.isCollapsible  = false
				try(hc.drawLayer = 3)catch()
				try
				(
					if lock then 
					(
						hc.viewAlign = -1
						hc.viewAlignOffset = [DepotX, DepotY]
					)
					else					
					(
						hc.viewAlign = 0
					)
					hc.activeNodePosRelative = [DepotX, DepotY]
				)
				catch(hc.activeNodePosRelative = [DepotX, DepotY])
				case MagmaFlowSettings.DepotPlacement of
				(
					#bottom: (
						DepotX += MagmaFlowSettings.DepotNodeWidth
						if DepotX > hc.width-MagmaFlowSettings.DepotNodeWidth  do
						(
							DepotX = 0
							DepotY+=18
						)
					)
					#left:
					(
						DepotY += 18
						if DepotY > hc.height-20 do
						(
							DepotX += MagmaFlowSettings.DepotNodeWidth
							leftDepotMargin = depotX+MagmaFlowSettings.DepotNodeWidth
							DepotY=0
						)
					)	
					/*
					#bottomrollup:
					(
						--format "depotDefinition=%\n" depotDefinition
						--format "DepotNodes=%\n" DepotNodes
						
						DepotY += 18
						if try(DepotNodes[i+1][1] == "HEAD" or DepotNodes[i+1][1] == "SUBHEAD")catch(false) do
						(
							DepotX += MagmaFlowSettings.DepotNodeWidth
							ArrayCnt += 1
							local subCategories = 1
							local theSubHeadsArray =#()
							if DepotNodes[i+1][1] == "HEAD" then 
							(
								--format "depotDefinition[ArrayCnt]=%\n" depotDefinition[ArrayCnt]
								local subHeadCount = 0
								if depotDefinition[ArrayCnt] != undefined do
								(
									for j = 1 to depotDefinition[ArrayCnt].count do
									(
										subHeadCount+=1
										if depotDefinition[ArrayCnt][j][1] == "SUBHEAD" then
										(
											append theSubHeadsArray (subHeadCount-1)
											subHeadCount = 0
										)
									)
									if theSubHeadsArray.count == 0 do theSubHeadsArray[1] = depotDefinition[ArrayCnt].count
									theVCount = if depotDefinition[ArrayCnt][1][6] then theSubHeadsArray[subCategories] else 1
								)
							)
							else if DepotNodes[i+1][1] == "SUBHEAD" then
							(
								subCategories +=1
								theVCount = theSubHeadsArray[subCategories]
							)
							DepotY = (hc.height-(18+theVCount*18/hc.zoom))						
						)					
					)	
					*/
					#bottomrollupreverse:
					(
						DepotY -= 18
						if try(DepotNodes[i+1][1] == "HEAD" or DepotNodes[i+1][1] == "SUBHEAD")catch(false) do
						(
							DepotX += MagmaFlowSettings.DepotNodeWidth
							ArrayCnt += 1
							theVCount =1 -- if try(DepotNodes[i+1][1] == "HEAD" and depotDefinition[ArrayCnt][1][6])catch(false) then depotDefinition[ArrayCnt].count else 1
							DepotY = (hc.height-36)						
						)					
					)	
				)--end case
			)
			hc.redrawView				
		)		

-----------------------------------------
--NODE SELECTION HANDLING
-----------------------------------------
		fn getSelectedNodes =
		(
			if magma != undefined then
			(
				for i = 1 to editorNodeCount collect
				(
					hc.activeNode = i	
					if hc.isSelected == true then i else dontcollect
				)
			)
			else #()
		)
		
		fn setSelectedNodes theSel =
		(
			local nodeArray = magma.GetNodes()
			for theID in nodeArray do
			(
				magma.DeclareExtensionProperty theID "Selected" 
				magma.setNodeProperty theID "Selected" false
			)			
			for i in theSel where i <= nodeArray.count do
			(
				magma.setNodeProperty nodeArray[i] "Selected" true
			)
			createNodeTree init:false
		)
		
		fn selectAllNodes =
		(
			setSelectedNodes (for i = 1 to (MagmaFlowEditor_Functions.getNodeCount magma) collect i)
			createUndoRecord "Select All Nodes"				
		)		

		fn deselectAllNodes =
		(
			setSelectedNodes #()
			createUndoRecord "Deselect All Nodes"				
		)
		
		fn invertSelection =
		(
			local theSel = (getSelectedNodes()) as bitarray
			setSelectedNodes ((#{1..editorNodeCount} - theSel) as array)
			createUndoRecord "Invert Node Selection"
		)
		
		fn selectUnconnectedNodes =
		(
			local nodeArray = magma.GetNodes()
			local theCount = nodeArray.count
			local theSel = for i = 1 to theCount where magma.getNodeProperty nodeArray[i] "Internal_NodeConnected" == false collect i
			if theSel.count > 0 do
			(
				setSelectedNodes theSel
				createUndoRecord ("Select "+theSel.count as string+ " Unconnected Node" + (if theSel.count == 1 then "" else "s"))
			)
		)
		
		/*
		fn selectDisabledNodes =
		(
			local theIndices = (for i = 2 to KrakatoaChannelEditor_DisplayNodeTreeData.count where KrakatoaChannelEditor_DisplayNodeTreeData[i][5] == false collect i)
			setSelectedNodesInData theIndices 
			createNodeTree init:false
			case theIndices.count of
			(
				1: createUndoRecord ("Select One Disabled Node")
				0: createUndoRecord ("No Disabled Nodes Selected")
				default: createUndoRecord ("Select "+theIndices.count as string +" Disabled Nodes")
			)			
		)
		
		fn selectOperatorNodesOnly =
		(
			local theIndices = (for i = 2 to KrakatoaChannelEditor_DisplayNodeTreeData.count where KrakatoaChannelEditor_DisplayNodeTreeData[i][1] == "Operator" collect i)
			setSelectedNodesInData theIndices
			createNodeTree init:false
			case theIndices.count of
			(
				1:	createUndoRecord ("Select One Operator Node")
				0:	createUndoRecord ("No Operator Nodes Selected")
				default:	createUndoRecord ("Select "+theIndices.count as string +" Operator Nodes")
			)	
		)

		fn selectInputNodesOnly =
		(
			local theIndices = (for i = 2 to KrakatoaChannelEditor_DisplayNodeTreeData.count where KrakatoaChannelEditor_DisplayNodeTreeData[i][1] == "Input" collect i)
			setSelectedNodesInData theIndices
			createNodeTree init:false
			case theIndices.count of
			(
				1:	createUndoRecord ("Select One Input Node")
				0:	createUndoRecord ("No Input Nodes Selected")
				default:	createUndoRecord ("Select "+theIndices.count as string +" Input Nodes")
			)	
		)
		*/
		
		fn getSelectedDepotButton =
		(
			for i = editorNodeCount+1 to hc.getNodeCount collect
			(
				hc.activeNode = i
				if hc.isSelected == true then i-editorNodeCount else dontcollect
			)
		)
		
		fn getDepotSelection =
		(
			for i = editorNodeCount+1 to hc.getNodeCount collect
			(
				hc.activeNode = i
				if hc.isSelected == true then i else dontcollect
			)
		)
		
		fn setUndoRedoEnable = 
		(
			
			btn_redo.enabled = LastUndoRecordNumber < (getFiles (theUserFolder + "\\MagmaFlowUndoRecords\\UndoRecord_"+MagmaFlowEditor_UniqueUndoID+".*")).count 
			btn_undo.enabled = LastUndoRecordNumber > 1
		)
		
		fn createUndoRecord undoText =
		(
			needToSave = true
			lastInfoMessage = undoText
			hc.setInfo = lastInfoMessage 
			--format "NumEditingBLOPs = %\n" (magma.NumEditingBLOPs())
			for i = 1 to magma.NumEditingBLOPs() do magma.PopEditableBLOP() --get out to top level
			::MagmaFlowEditor_EditableBlopStack = for i in EditableBlopStack collect i
			
			local theFlowScript = MagmaFlowEditor_Functions.emitMAXScriptCode magma isUndo:true thePresetName:currentPreset
			
			makeDir (theUserFolder + "\\MagmaFlowUndoRecords\\") all:true
			local theCount = (getFiles (theUserFolder + "\\MagmaFlowUndoRecords\\UndoRecord_"+MagmaFlowEditor_UniqueUndoID+".*")).count
			if LastUndoRecordNumber < theCount do 
			(
				for i = LastUndoRecordNumber+1 to theCount do
				(
					deleteFile (theUserFolder + "\\MagmaFlowUndoRecords\\UndoRecord_"+ MagmaFlowEditor_UniqueUndoID+"." + i as string)
				)
			)
			LastUndoRecordNumber +=1
			UndoRecordNames[LastUndoRecordNumber] = undoText
			
			local theFileName = theUserFolder + "\\MagmaFlowUndoRecords\\UndoRecord_"+ MagmaFlowEditor_UniqueUndoID+ "." + LastUndoRecordNumber as string
			local theFileHandle = createFile theFileName
			if theFileHandle != undefined do
			(
				with PrintAllElements true	format "%\n" theFlowScript to:theFileHandle 
				format "global MagmaFlowEditor_PlaybackDuration = %\n" MagmaFlowSettings.playbackDuration to:theFileHandle 
				format "global MagmaFlowEditor_UndoRecordName = \"%\"\n" undoText to:theFileHandle 
				format "global MagmaFlowEditor_PanAndZoom = #(%,%)\n" hc.pan hc.zoom to:theFileHandle 
			)
			close theFileHandle
			
			--navigate down to the previous editing level
			--format "CurrentBLOP=%\n" magma.CurrentBLOP
			--format "EditableBlopStack = %\n" EditableBlopStack
			for i in EditableBlopStack do magma.pushEditableBLOP i
				
			setUndoRedoEnable()
		)
		
		fn undoLastStep =
		(
			local oldExposure = #()
			local newExposure = #()
			if LastUndoRecordNumber > 1 do
			(
				LastUndoRecordNumber -= 1
				local nodeArray = magma.GetNodes()
				oldExposure = sort (for i in nodeArray where (magma.getNodeProperty i "Exposed") == true collect i)
				local theUndoFile = (theUserFolder + "\\MagmaFlowUndoRecords\\UndoRecord_"+MagmaFlowEditor_UniqueUndoID+"." + LastUndoRecordNumber as string)
				if doesFileExist theUndoFile then
				(
				--try(
					closeAllCurveEditors()
					magma.reset()
					::magmaNode = magma
					fileIn theUndoFile
					EditableBlopStack = deepCopy ::MagmaFlowEditor_EditBLOPHistory
					
					local nodeArray = magma.GetNodes()
					newExposure = sort (for i in nodeArray where (magma.getNodeProperty i "Exposed") == true collect i)
					createNodeTree init:true
				--)catch()
					try(hc.setInfo = "Undo '" + UndoRecordNames[LastUndoRecordNumber+1]+"'")catch()
					try(hc.pan = ::MagmaFlowEditor_PanAndZoom[1])catch()
					try(hc.zoom = ::MagmaFlowEditor_PanAndZoom[2])catch()
					createNodeTree init:false
					edt_log.text = ""
					setUndoRedoEnable()
					updateMagmaHolder update:false
					displaySelectedNodeProperties()
					if oldExposure.count > 0 or newExposure.count > 0 do exposeControlsToModifier()
					updateModifierName()
					updateEditorTitle()
					autoReorderFlow createUndo:false
					updateNavigator()
					debugFlow()
				)
			)
		)	

		fn redoLastStep =
		(
			local oldExposure = #()
			local newExposure = #()
			if LastUndoRecordNumber < (getFiles (theUserFolder + "\\MagmaFlowUndoRecords\\UndoRecord_"+MagmaFlowEditor_UniqueUndoID+".*")).count do
			(
				LastUndoRecordNumber += 1
				local theUndoFile = (theUserFolder + "\\MagmaFlowUndoRecords\\UndoRecord_"+MagmaFlowEditor_UniqueUndoID+"." + LastUndoRecordNumber as string)
				if doesFileExist theUndoFile then
				(
					local nodeArray = magma.GetNodes()
					oldExposure = sort (for i in nodeArray where (magma.getNodeProperty i "Exposed") == true collect i)
					closeAllCurveEditors()
					magma.reset()
					::magmaNode = magma
					fileIn theUndoFile
					EditableBlopStack =  deepCopy ::MagmaFlowEditor_EditBLOPHistory
					local nodeArray = magma.GetNodes()
					newExposure = sort (for i in nodeArray where (magma.getNodeProperty i "Exposed") == true collect i)
					createNodeTree init:true				
			
					try(hc.setInfo = "Redo '" + UndoRecordNames[LastUndoRecordNumber]+"'")catch()
					try(hc.pan = ::MagmaFlowEditor_PanAndZoom[1])catch()
					try(hc.zoom = ::MagmaFlowEditor_PanAndZoom[2])catch()
					setUndoRedoEnable()
					displaySelectedNodeProperties()
					updateMagmaHolder update:false
					if oldExposure.count > 0 or newExposure.count > 0 do exposeControlsToModifier()
					updateModifierName()
					updateEditorTitle()
					autoReorderFlow createUndo:false
					updateNavigator()
					debugFlow()
				)--end if
			)
		)		
		
		fn undoToRecord theRecord mode:#undo=
		(
			local oldExposure = #()
			local newExposure = #()
			if mode == #undo then
			(
				LastUndoRecordNumber = theRecord-1
				local prefix = "Undo To '"
			)
			else
			(
				LastUndoRecordNumber = theRecord
				local prefix = "Redo To '"
			)			
			local theUndoFile = (theUserFolder + "\\MagmaFlowUndoRecords\\UndoRecord_"+ MagmaFlowEditor_UniqueUndoID+ "." + LastUndoRecordNumber as string)
			if doesFileExist theUndoFile do
			(
				local nodeArray = magma.GetNodes()
				oldExposure = sort (for i in nodeArray where (magma.getNodeProperty i "Exposed") == true collect i)
				closeAllCurveEditors()						
				magma.reset()
				::magmaNode = magma

				fileIn theUndoFile
				EditableBlopStack = deepCopy ::MagmaFlowEditor_EditBLOPHistory
				--for i in EditableBlopStack do magma.PushEditableBlop i

				local nodeArray = magma.GetNodes()
				newExposure = sort (for i in nodeArray where (magma.getNodeProperty i "Exposed") == true collect i)
				createNodeTree init:true
				try(hc.setInfo =  prefix+UndoRecordNames[LastUndoRecordNumber]+"'")catch()
				try(hc.pan = ::MagmaFlowEditor_PanAndZoom[1])catch()
				try(hc.zoom = ::MagmaFlowEditor_PanAndZoom[2])catch()
				setUndoRedoEnable()		
				createNodeTree init:false
				edt_log.text = ""
				updateMagmaHolder update:false
				displaySelectedNodeProperties()		
				if oldExposure.count > 0 or newExposure.count > 0 do exposeControlsToModifier()
				updateModifierName()
				updateEditorTitle()
				autoReorderFlow createUndo:false
				updateNavigator()
				debugFlow()
			)--end if file exists
		)
				
		fn createUndoRCMenu =
		(
			global MagmaFlowEditor_UndoRCMenu
			local txt = "rcmenu MagmaFlowEditor_UndoRCMenu (\n"
			for i = LastUndoRecordNumber to 2 by -1 do
			(
				txt += "menuItem mnu_"+ i as string + " \"" + UndoRecordNames[i] + "\"\n"
				txt += "on mnu_"+ i as string + " picked do (for i in ::MagmaFlowEditor_CurrentEditors where i[5] == \""+ MagmaFlowEditor_UniqueUndoID +"\" do i[2].undoToRecord "+ i as string + " mode:#undo)\n"
			)	
			txt += ")\n"
			execute txt
		)
		
		fn createRedoRCMenu =
		(
			global MagmaFlowEditor_UndoRCMenu
			local txt = "rcmenu MagmaFlowEditor_UndoRCMenu (\n"
			for i = LastUndoRecordNumber+1 to UndoRecordNames.count do
			(
				txt += "menuItem mnu_"+ i as string + " \"" + UndoRecordNames[i] + "\"\n"
				txt += "on mnu_"+ i as string + " picked do (for i in ::MagmaFlowEditor_CurrentEditors where i[5] == \""+ MagmaFlowEditor_UniqueUndoID +"\" do i[2].undoToRecord "+ i as string + " mode:#redo)\n"
			)	
			txt += ")\n"
			execute txt
		)		
		
		on btn_Undo pressed do undoLastStep()
		on btn_Redo pressed do redoLastStep()
		
		on btn_Undo rightClick do 
		(
			createUndoRCMenu()
			popupMenu MagmaFlowEditor_UndoRCMenu pos:mouse.screenpos
		)	
		on btn_Redo rightClick do 
		(
			createRedoRCMenu()
			popupMenu MagmaFlowEditor_UndoRCMenu pos:mouse.screenpos
		)			
		
		
		local oldCollapseList = #()
		local newCollapseList = #()
		fn updateNodeSelection createUndo:true = 
		(
			local needCollapseUpdate = false
			CollapseBranches()
			oldCollapseList = for i in newCollapseList collect i
			newCollapseList = #()
			hc.drawLastIndex = 1
			
			local nodeArray = Magma.GetNodes()
			
			for i = editorNodeCount to 1 by -1 do 
			(
				local theID = nodeArray[i]
				--if magma.getNodeProperty theID "Internal_BranchCollapsed" != true do
				(
					hc.activeNode = i	
					if hc.activeNodePos != [-10000,-10000] do
					(
						if hc.isSelected do 
						(
							hc.drawLastIndex = i
							if MagmaFlowSettings.SnapToGrid == true and not MagmaFlowSettings.AutoReorderToggle do
							(
								local thePos = hc.activeNodePos
								thePos.x = (floor (thePos.x/MagmaFlowSettings.GridSizeX+0.5))*MagmaFlowSettings.GridSizeX
								thePos.y = (floor (thePos.y/MagmaFlowSettings.GridSizeY+0.5))*MagmaFlowSettings.GridSizeY
								hc.activeNodePos = thePos
							)
						)	
						
						if MagmaFlowSettings.AutoReorderToggle then 
							MagmaFlowEditor_Functions.setUIProperty magma theID "Internal_Position" (hc.activeNodePos)
						else
							MagmaFlowEditor_Functions.setUIProperty magma theID "Position" (hc.activeNodePos)
					)
					MagmaFlowEditor_Functions.setUIProperty magma theID "Selected" (hc.isSelected)
					MagmaFlowEditor_Functions.setUIProperty magma theID "Collapsed" (hc.activeNodeCollapsed)
					if (hc.activeNodeCollapsed) do 
					(
						--needCollapseUpdate = true
						append newCollapseList i
					)
					--if theNodeInvisibilityList[i] == false do KrakatoaChannelEditor_DisplayNodeTreeData[i][4][1] = hc.activeNodePos
					--KrakatoaChannelEditor_DisplayNodeTreeData[i][4][2] = hc.activeNodeCollapsed 
					--KrakatoaChannelEditor_DisplayNodeTreeData[i][4][3] = hc.isSelected 
				)
			)
			
			if lastSelection as string != (getSelectedNodes()) as string do
			(
				lastSelection = getSelectedNodes()
				if createUndo do 
					case of
					(
						(lastSelection.count == 0): createUndoRecord ("Select No Nodes")
						(lastSelection.count == 1): createUndoRecord ("Select "+ (try(magma.GetNodeType NodeIDMap[lastSelection[1]])catch("BLOP Inputs"))   + " Node")
						(lastSelection.count > 1): createUndoRecord ("Select "+lastSelection.count as string+ " Nodes")
					)	
				displaySelectedNodeProperties()
			)
			with PrintAllElements on
			(
				if newCollapseList as string != oldCollapseList as string then
				(
					collapseBranches()
					createNodeTree init:true
				)
			)
			hc.redrawView
		)		
		
		
		fn alignAllNodesToGrid createUndo:true =
		(
			local nodeArray = magma.GetNodes()
			local nodeCount = nodeArray.count
			for i = 1 to nodeCount do 
			(
				hc.activeNode = i	
				thePos = hc.activeNodePos
				thePos.x = (floor (thePos.x/MagmaFlowSettings.GridSizeX+0.5))*MagmaFlowSettings.GridSizeX
				thePos.y = (floor (thePos.y/MagmaFlowSettings.GridSizeY+0.5))*MagmaFlowSettings.GridSizeY
				hc.activeNodePos = thePos
					
				local theID = nodeArray[i]
				magma.setNodeProperty theID "Position" thePos
				magma.setNodeProperty theID "Internal_Position" thePos
			)	
			createNodeTree init:false
			--if createUndo do createUndoRecord ("Align All Nodes To Grid (" + GridSizeX as string + "x" + GridSizeY as string+")")
		)
		
		fn showGrid enabled =
		(
			local theX = MagmaFlowSettings.GridSizeX*hc.zoom
			local theY = MagmaFlowSettings.GridSizeY*hc.zoom

			local theBitmap = bitmap theX theY color:MagmaFlowColors.EditorBackgroundColor 
			
			if enabled and hc.zoom > 0.9 do
			(
				thePixels = for i = 1 to theX collect MagmaFlowColors.GridColor
				setPixels theBitmap [0,0] thePixels
				for i = 1 to theY do 
					setPixels theBitmap [0,i-1] #(MagmaFlowColors.GridColor)
			)
			
			hc.backgroundBitmap = theBitmap
			hc.tileBackground = true
		)
		

		fn toggleSnapToGrid =
		(
			MagmaFlowSettings.SnapToGrid = not MagmaFlowSettings.SnapToGrid
			setIniSetting (theIniFileLocation + "MagmaFlowEditor_Preferences.ini") "Grid" "SnapToGrid" (MagmaFlowSettings.SnapToGrid as string)
			showGrid MagmaFlowSettings.SnapToGrid
			hc.redrawView			
		)			
		
		fn initSchematicView =
		(
			hc.drawShadows = MagmaFlowSettings.DrawShadows
			hc.allowZoom  = true
			hc.zoomAboutMouse = false
			hc.drawMenuBars = true
			hc.allowUIDelete = true
			hc.showInfo = true
			hc.setInfo = ""
			hc.pan = [0,0]
		)
		
		
		fn openCurveEditor theID =
		(
			local existingEditors = (for i in ::MagmaFlowEditor_CurrentCurveEditors where i[1] == magma and i[2] == theID collect i)
			if existingEditors.count == 0 then
			(
				magma.declareExtensionProperty theID "CurveEditorPosition"
				local thePos = magma.getNodeProperty theID "CurveEditorPosition"
				local theHome = MagmaFlowEditor_Functions.getHomeDirectory magma
				local CurveControlEditor = fileIn (theHome + "\\Scripts\\Krakatoa_MagmaFlowCurveEditor.ms")
				::MagmaFlowEditor_CurrentMagmaHolder = magma
				::MagmaFlowEditor_CurrentMagmaNode = theID
				if thePos == undefined then
					createDialog CurveControlEditor 480 500
				else
					createDialog CurveControlEditor 480 500 thePos.x thePos.y
				
				CurveControlEditor.title = "Curve Editor - ID " + theID as string
				append ::MagmaFlowEditor_CurrentCurveEditors #(magma, theID, CurveControlEditor, MagmaFlowEditor_Rollout)
			)
			else
				setFocus (existingEditors[1][3])
		)
		
		fn closeAllCurveEditors =
		(
			for i = ::MagmaFlowEditor_CurrentCurveEditors.count to 1 by -1 where ::MagmaFlowEditor_CurrentCurveEditors[i][4] == MagmaFlowEditor_Rollout do 
			(
				try(destroyDialog MagmaFlowEditor_CurrentCurveEditors[i][3])catch()
			)
		)
		
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--EXPOSE CONTROLS FUNCTIONS		
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
		local theCADef, theCADef2, theCADef3, theCADCnt, theCALevel, theColorPickersToUpdate, theCADParentNode
		
		fn exposeSubLevel =
		(
			local txt1 = "" as stringStream
			local txt2 = "" as stringStream
			local txt3 = "" as stringStream
			
			local nodeArray = sort (magma.GetNodes())
			--format "nodeArray = %\n" nodeArray 
			local nodeCount = nodeArray.count
			
			for i = 1 to nodeCount do
			(
				local id = nodeArray[i]
				if magma.getNodeProperty id "Exposed" == true do
				(
					if findItem #(#InputGeometry, #InputObject, #InputParticles) ((magma.getNodeType id) as name) > 0 do
					(
						local theNameString1, theNameString2, theTooltip1, theTooltip2
						
						local theName = MagmaFlowEditor_Functions.getNodeName magma id 
						local theTooltip = magma.getNodeProperty id "Notes"
						local theClassString = "object"
						if theTooltip == undefined do theTooltip = theName
							
						(
							local theNameString = "Pick Scene Object..."
							case (magma.getNodeType ID) as name of
							(
								default: (
									format "fn pickObjectsFilter% obj = ( true ) \n" id to:txt2
								)
								#InputGeometry: 
								(
									format "fn pickObjectsFilter% obj = ((try(findItem ::MagmaFlowEditor_GlobalPickFilterArray% obj == 0)catch(true)) AND (findItem GeometryClass.classes (classof obj) > 0) AND (classof obj != targetObject) AND (findItem #(PF_Source,PRT_Volume,PRT_FumeFX,KrakatoaPRTLoader,PRT_Source,PRT_Maker,PRT_Hair,PRT_Surface,PRT_Field,Stoke,Stoke_Field,StokeFieldLoader,StokeFieldSIM,PHXSimulator) (classof obj.baseobject) == 0) )\n" id id to:txt2 
									theTooltip = "Get multiple Geometry Objects by name..."
									theTooltip2 = "Get one Geometry Object by clicking in the viewport..."
									
									theClassString = "nodes"
									theNameString = "Get by Name"
									theNameString2 = "Pick in Scene"
								)
								#InputParticles: 
								(
									format "fn pickObjectsFilter% obj = ( findItem #(PF_Source,PRT_Volume,PRT_FumeFX,KrakatoaPRTLoader,PRT_Source,PRT_Maker,PRT_Hair,PRT_Field,PRT_Surface,PHXSimulator) (classof obj.baseobject) > 0 and (try(findItem ::MagmaFlowEditor_GlobalPickFilterArray% obj == 0)catch(true)))\n" id id to:txt2
									theNameString = "Pick Particle Object..."
									theClassString = "node"
								)
							)
							
							--local theName = theNameString
							if theClassString == "nodes" then
							(
								theCADCnt+=1
								format "group \"%: %\" (\n" id theName to:txt2 
								format "button btn_node1_% \"%\" width:75 offset:[-7,-4] align:#left across:2 tooltip:\"%\" \n" id theNameString theTooltip to:txt2
								format "pickbutton btn_node2_% \"%\" width:75 offset:[7,-4] align:#right tooltip:\"%\" filter:pickObjectsFilter%\n" id theNameString2 theTooltip2 id to:txt2 
								
								format "multilistbox lbx_nodes% width:150 align:#center offset:[0,-4] \n" id to:txt2 
								format "button btn_removenodes% \"Remove Objects\" width:150 align:#center offset:[0,-4] tooltip:\"Remove highlighted nodes from the input's list...\" \n" id  to:txt2 
								format ")\n" to:txt2 
								
								format "fn updateNodesList% = ( try(\n" id to:txt2 
								format "local theMod = (custAttributes.getOwner this).magmaHolder\n" to:txt2 
								format "local allNodes = theMod.getNodeProperty % \"nodes\" \n" id  to:txt2 
								format "::MagmaFlowEditor_GlobalPickFilterArray% = allNodes \n" id  to:txt2 
								format "lbx_nodes%.items =  for i in allNodes collect if isValidNode i then i.name else \"<deleted>\" \n"  id to:txt2 
								format  ")catch())\n"  to:txt2 
								
								format  "on btn_removenodes% pressed do (\n" id  to:txt2 
								format  "local theMod = (custAttributes.getOwner this).magmaHolder\n"  to:txt2 
								format  "local theNodes = theMod.getNodeProperty % \"nodes\" \n" id to:txt2 
								format  "local theSel = lbx_nodes%.selection as array \n" id  to:txt2 
								format  "for i = theSel.count to 1 by -1 do deleteItem theNodes theSel[i] \n"   to:txt2 
								format  "theMod.setNodeProperty % \"nodes\" theNodes\n"  id   to:txt2 
								format  "updateNodesList%()\n" id   to:txt2 
								format  "updateMod sel:true\n"   to:txt2 
								format  ")\n"  to:txt2 
								
								format  "updateNodesList%()\n" id  to:txt3 
								
								format  "on btn_node1_% pressed do (\n" id to:txt2 
								format  "local theMod = (custAttributes.getOwner this).magmaHolder\n"  to:txt2 
								format  "local allNodes = theMod.getNodeProperty % \"nodes\" \n" id to:txt2    
								format "::MagmaFlowEditor_GlobalPickFilterArray% = allNodes \n"	id to:txt2 			
								format  "local theNodes = selectByName title:\"%\" filter:pickObjectsFilter% showHidden:true single:false \n" theNameString id   to:txt2 
								format  "if theNodes != undefined do (\nfor o in theNodes do appendIfUnique allNodes o\n"  to:txt2 
								format  "theMod.setNodeProperty % \"nodes\" allNodes\n" id to:txt2 
								format  "updateMod sel:true\n" to:txt2 
								format  "updateNodesList%()))\n" id to:txt2 
								
								format  "on btn_node2_% picked obj do (\n" id  to:txt2 
								format  "local theMod = (custAttributes.getOwner this).magmaHolder\n" to:txt2 
								format  "local allNodes = theMod.getNodeProperty % \"nodes\" \n" id to:txt2     
								format "::MagmaFlowEditor_GlobalPickFilterArray% = allNodes \n"	id 			 to:txt2 			
								format  "if obj != undefined do (\nappendIfUnique allNodes obj\n"  to:txt2 
								format  "theMod.setNodeProperty % \"nodes\" allNodes\n" id to:txt2 
								format  "updateMod sel:true\n"  to:txt2 
								format  "updateNodesList%()))\n" id to:txt2 
							)
							else
							(
								theCADCnt+=1
								format "group \"%: %\" (\n" id theName  to:txt2 
								format "pickbutton btn_node% \"%\" width:150 align:#center offset:[0,-4] tooltip:\"%\" filter:pickObjectsFilter%\n"  id  theNameString  theTooltip id to:txt2 
								format  ")\n"  to:txt2 
								
								format "fn updatePickButton% = (\n" id to:txt2 
								format "local theMod = (custAttributes.getOwner this).magmaHolder\n" to:txt2 
								format "local theNode = theMod.getNodeProperty % \"%\" \n" id theClassString to:txt2 
								format "::MagmaFlowEditor_GlobalPickFilterArray% = (join (refs.dependentNodes theMod ) #(theNode)) \n"	id to:txt2 
								/*
								format "print \"CADC:----------------------------------------\" \n"	to:txt2 
								format "print % \n" id to:txt2
								format "print (::MagmaFlowEditor_GlobalPickFilterArray% as string) \n"	id to:txt2 
								format "print \"--------------------------------------------\" \n"	id to:txt2 
								*/
								
								format "btn_node%.caption =  if isValidNode theNode then theNode.name else \"%\" \n"  id theNameString to:txt2 
								format  ")\n" to:txt2 

								format  "updatePickButton%()\n" id to:txt3
								
								format  "on btn_node% picked theNode do (\n" id  to:txt2 
								format  "local theMod = (custAttributes.getOwner this).magmaHolder\n"  to:txt2 
								format  "if isValidNode theNode do (\n"  to:txt2 
								format  "theMod.setNodeProperty % \"%\" theNode\n" id theClassString to:txt2 
								format  "updateMod sel:true\n"  to:txt2 
								format  "updatePickButton%()))\n" id to:txt2 
							)						
						)						
					)
					
					if findItem #(#Noise, #VecNoise) ((magma.getNodeType id) as name) > 0 then
					(
						theCADCnt+=1
						format "float_% type:#float default:1 \n" id to:txt1 --just a dummy track
						
						theName = MagmaFlowEditor_Functions.getNodeName magma id 
						format  "group \"%: %\"(\n" id theName to:txt2
						
						theTooltip = "Num. Octaves"
						format "spinner spn_%_1 \"Num Octaves: \" type:#integer align:#right fieldwidth:50 range:[%,%,0] scale:0.01 offset:[6,-2] tooltip:\"%\"\n" id 1 10 theTooltip to:txt2
						
						format "on spn_%_1 changed val do (\n" id to:txt2
						format "local theOwner = (custAttributes.getOwner this)\n" to:txt2
						format "local theMod = (custAttributes.getOwner this).magmaHolder\n" to:txt2 							
						format "theMod.setNodeProperty % \"numOctaves\" val \n" id to:txt2						
						format  "updateMod sel:true)\n" to:txt2
						
						format "spn_%_1.value = (custAttributes.getOwner this).magmaHolder.getNodeProperty % \"numOctaves\" \n" id id to:txt3
						
						theTooltip = "Lacunarity"
						format "spinner spn_%_2 \"Lacunarity: \" type:#float align:#right fieldwidth:50 range:[%,%,0] scale:0.01 offset:[6,-2] tooltip:\"%\"\n" id -100 100 theTooltip to:txt2
						
						format "on spn_%_2 changed val do (\n" id to:txt2
						format "local theOwner = (custAttributes.getOwner this)\n" to:txt2
						format "local theMod = (custAttributes.getOwner this).magmaHolder\n" to:txt2 						
						format "theMod.setNodeProperty % \"lacunarity\" val \n" id to:txt2	
						format  "updateMod sel:true)\n" to:txt2
						
						format "spn_%_2.value = (custAttributes.getOwner this).magmaHolder.getNodeProperty % \"lacunarity\" \n" id id to:txt3
						
						
						theTooltip = "Normalize output values between approx. -1.0 and 1.0"
						format "checkbutton chk_%_3 \">Normalize\" align:#center width:148 offset:[0,-2] tooltip:\"%\"\n" id theTooltip to:txt2
						format "on chk_%_3 changed val do (\n" id to:txt2
						format "local theOwner = (custAttributes.getOwner this)\n" to:txt2
						format "local theMod = (custAttributes.getOwner this).magmaHolder\n" to:txt2 						
						format "theMod.setNodeProperty % \"normalize\" val \n" id to:txt2			
						format "updateMod sel:true\nmax views redraw)\n" to:txt2

						format "chk_%_3.state = (custAttributes.getOwner this).magmaHolder.getNodeProperty % \"normalize\" \n" id id to:txt3

						format  ")\n" to:txt2
					)					
					
					if magma.getNodeType id == "Curve" do
					(
						theCADCnt+=1
						local theName = MagmaFlowEditor_Functions.getNodeName magma id 
						local theTooltip = magma.getNodeProperty id "Notes"
						if theTooltip  == undefined do theTooltip = id as string +": "+ theName
						format "button btn_% \"Edit %:%...\" width:150 height:30 align:#center tooltip:\"%\"\n" id id theName theTooltip to:txt2
						format "on btn_% pressed do (\n" id to:txt2
						format  "local theMod = (custAttributes.getOwner this).magmaHolder\n" to:txt2
						format "local theID = %\n" id to:txt2
						format "local theCI = theMod.getNodeProperty theId \"curve\" \n" to:txt2
						format "local existingEditors = (for i in ::MagmaFlowEditor_CurrentCurveEditors where i[1] == theMod and i[2] == theID collect i) \n" to:txt2
						format "if existingEditors.count == 0 then (\n theMod.declareExtensionProperty theID \"CurveEditorPosition\" \n" to:txt2
						format "local thePos = theMod.getNodeProperty theID \"CurveEditorPosition\" \n" to:txt2
						format "local CurveControlEditor =  fileIn (FranticParticles.KrakatoaHome + \"Scripts/Krakatoa_MagmaFlowCurveEditor.ms\") \n" to:txt2
						format "::MagmaFlowEditor_CurrentMagmaHolder = theMod \n" to:txt2
						format "::MagmaFlowEditor_CurrentMagmaNode = theID \n" to:txt2
						format "if thePos == undefined then createDialog CurveControlEditor 480 500 else createDialog CurveControlEditor 480 500 thePos.x thePos.y \n" to:txt2
						format "CurveControlEditor.title = \"Curve Editor - ID \" + theID as string + \": %\" \n" theName to:txt2
						format "append ::MagmaFlowEditor_CurrentCurveEditors #(theMod, theID, CurveControlEditor, undefined) \n" to:txt2
						format ")else setFocus (existingEditors[1][3])	\n" to:txt2
						format ")\n" to:txt2
					)
					if magma.getNodeType id == "TexmapEval" or magma.getNodeType id == "InputTexmap" do
					(
						theCADCnt+=1
						local theName = MagmaFlowEditor_Functions.getNodeName magma id 
						format "group \"%: %\" (" id theName to:txt2
						format "mapbutton map_% \"<Add Texture Map>\" width:150 align:#center offset:[0,-3]\n" id  to:txt2
						format "button btn_mapToMEdit% \"Put To MEdit\" width:75 align:#left offset:[-7,-3] across:2\n"  id to:txt2
						format "button btn_RemoveMap% \"Remove Map\" width:75 align:#right offset:[7,-3] \n" id  to:txt2
						format ")\n" to:txt2

						format "on btn_mapToMEdit% pressed do (\n" id  to:txt2
						format "local theMod = (custAttributes.getOwner this).magmaHolder\n" to:txt2
						format "local theMap = theMod.getNodeProperty % \"texmap\" \n" id to:txt2
						format "if theMap != undefined do (MatEditor.Open(); meditMaterials[medit.GetActiveMtlSlot()] = theMap)\n"   to:txt2
						format  "updateMod sel:true\n"  to:txt2
						format  ")\n"   to:txt2
						
						format "on btn_RemoveMap% pressed do (\n" id to:txt2
						format  "local theMod = (custAttributes.getOwner this).magmaHolder\n" to:txt2
						format "theMod.setNodeProperty % \"texmap\" undefined \n" id to:txt2
						format "map_%.caption = \"<Add Texture Map>\"\n" id  to:txt2
						format  "updateMod sel:true\n" to:txt2
						format  ")\n"   to:txt2
						
						format "on map_% picked aMap do (\n"  id  to:txt2
						format "map_%.caption = if aMap == undefined then \"<Add Texture Map>\" else aMap.name + \" (\" + (classof aMap) as string + \")\" \n" id to:txt2
						format  "local theMod = (custAttributes.getOwner this).magmaHolder\n" to:txt2
						format  "theMod.setNodeProperty % \"texmap\" aMap\n" id to:txt2
						format  "updateMod sel:true\n"  to:txt2
						format  ")\n"   to:txt2
						
						format "local theMod = (custAttributes.getOwner this).magmaHolder\n" to:txt3
						format "local theMap = theMod.getNodeProperty % \"texmap\" \n" id  to:txt3
						format "map_%.caption = if theMap == undefined then \"<Add Texture Map>\" else theMap.name + \" (\" + (classof theMap) as string + \")\" \n" id  to:txt3
					)
					if magma.getNodeType id == "InputChannel" or magma.getNodeType id == "LoopChannel" or magma.getNodeType id == "Output" do
					(
						local theName = MagmaFlowEditor_Functions.getNodeName magma id 
						local theTooltip = magma.getNodeProperty id "Notes"
						local theSortingMode = (magma.getNodeProperty id "ExposedChannelsSorting") as string
						
						if theTooltip == undefined do theTooltip = id as string + ": "+ theName + " - " + theSortingMode
							
						local theArray = MagmaFlowEditor_Functions.loadChannelsList magma mode:(if magma.getNodeType id == "OutputChannel" then #output else #input) 							
						theArray = MagmaFlowEditor_Functions.getSortedChannelsList theArray theSortingMode theIniFileLocation includeCustom:false --(MagmaFlowEditor_Functions.IsModifier magma)
						
						if magma.getNodeType id == "LoopChannel" and theCADParentNode != undefined do
						(
							theArray = for c in (MagmaFlowEditor_Functions.getLoopChannelList magma theCADParentNode) collect c[1]
						)
						
						theCADCnt+=1	
						format "channel_% type:#integer ui:ddl_% default:1 \n" id id to:txt1
						with PrintAllElements on 
						(
							format "dropdownlist ddl_% \"%: %\" align:#center width:150 offset:[0,-2] items:% height:20 tooltip:\"%\"\n" id id theName theArray theTooltip to:txt2
							format "on ddl_% selected itm do (\n" id to:txt2
							format  "local theMod = (custAttributes.getOwner this).magmaHolder\n" to:txt2
							format  "theMod.setNodeProperty % \"channelName\" ddl_%.selected\n" id id to:txt2
							format  "updateMod sel:true\n"  to:txt2
							format ")\n" to:txt2

							format  "local theMod = (custAttributes.getOwner this).magmaHolder\n" to:txt3
							format  "ddl_%.selection= findItem ddl_%.items (theMod.getNodeProperty % \"channelName\") \n" id id id to:txt3
						)
					)
					if magma.getNodeType id == "InputValue" do
					(
						local theName = MagmaFlowEditor_Functions.getNodeName magma id 
						local theTooltip = magma.getNodeProperty id "Notes"
						if theTooltip == undefined do theTooltip = id as string + ": "+ theName
						
						if classof (magma.getNodeProperty id "controller").value == Float and magma.getNodeProperty id "forceInteger" == false do
						(
							theCADCnt+=1
							local nextNodes = MagmaFlowEditor_Functions.getConnectedNodes magma ID
							local rangeMin = -100000
							local rangeMax = 100000
							try
							(
								if nextNodes[1].count == 1 do
								(
									if magma.getNodeType nextNodes[1][1][1] == "Clamp" do
									(
										if (magma.getNodeInput nextNodes[1][1][1] 2)[1] == -1 do rangeMin = magma.getNodeInputDefaultValue nextNodes[1][1][1] 2
										if (magma.getNodeInput nextNodes[1][1][1] 3)[1] == -1 do rangeMax = magma.getNodeInputDefaultValue nextNodes[1][1][1] 3
									)
								)
							)catch()
							format "float_% type:#float ui:spn_% default:1 \n" id id to:txt1
							format "spinner spn_% \"%: %: \" type:#float align:#right fieldwidth:50 range:[%,%,0] scale:0.01 offset:[12,-2] tooltip:\"%\"\n" id id theName rangeMin rangeMax theTooltip to:txt2
							format "on spn_% changed val do updateMod()\n" id to:txt2
						)--end if
						if classof (magma.getNodeProperty id "controller").value == Float and magma.getNodeProperty id "forceInteger" == true do
						(
							theUpstreamNode = MagmaFlowEditor_Functions.getConnectedNodes magma id
							-- format "theUpstreamNode =%\n" theUpstreamNode 
							--if theUpstreamNode[1].count == 1 do
							case of
							(
								(theUpstreamNode[1].count > 0 AND magma.getNodeType theUpstreamNode[1][1][1] == "Mux" AND theUpstreamNode[1][1][2] == magma.getNumNodeInputs theUpstreamNode[1][1][1]):
								(
									local theMuxID = theUpstreamNode[1][1][1]
									local theItems = #()
									for m = 1 to (magma.getNumNodeInputs theMuxID)-1 do
									(
										theInput = magma.getNodeInput theMuxID m
										if theInput[1] > -1 then
										(
											local theInName = magma.getNodeProperty theInput[1] "Name"
											if theInName == undefined or theInName == "" do 
											(
												theInName = getOutputSocketName theInput[1] theInput[2]
												if theInName == undefined do theInName = magma.getNodeType theInput[1]
											)
										)
										else 
											theInName = "<Unconnected>"
										append theItems ((m-1) as string +":"+theInName)
									)
									if theTooltip == undefined do theTooltip = id as string + ": "+ theName
									theCADCnt+=1
									format "int_% type:#integer default:1 \n" id to:txt1
									format "button btn_tooltip% \"?\" width:15 height:15 align:#right offset:[7,0] tooltip:\"%\"\n" id theTooltip to:txt2
									with PrintAllElements on format "listbox ddl_% \"%: %: \" align:#center width:150 offset:[0,-21] items:% height:%\n" id id theName theItems theItems.count to:txt2
									format "on ddl_% selected val do (\n" id to:txt2
									format "int_% = val-1\n" id to:txt2
									format "updateMod()\n" to:txt2
									format ")\n" to:txt2
									format "ddl_%.selection = int_%+1\n" id id to:txt3
								)
								(theUpstreamNode[1].count > 0 AND magma.getNodeType theUpstreamNode[1][1][1] == "Switch" AND theUpstreamNode[1][1][2] == magma.getNumNodeInputs theUpstreamNode[1][1][1]):
								(
									local theMuxID = theUpstreamNode[1][1][1]
									theCADCnt+=1
									format "int_% type:#integer default:1 \n" id to:txt1
									format  "checkbutton chk_% \">%: %\" align:#center width:150 offset:[0,-2] tooltip:\"%\"\n" id id theName theTooltip to:txt2
									format  "on chk_% changed val do (\n" id to:txt2
									format  "int_% = if val then 1 else 0\n" id to:txt2
									format  "updateMod()\n" to:txt2
									format  ")\n" to:txt2
									
									format "chk_%.state = (int_% != 0)\n" id id to:txt3
								)							
								default:
								(
									theCADCnt+=1
									format "int_% type:#integer ui:spn_% default:1 \n" id id to:txt1
									local theTooltip = magma.getNodeProperty id "Notes"
									if theTooltip == undefined do theTooltip = theName
									format  "spinner spn_% \"%: %: \" type:#integer align:#right fieldwidth:50 range:[-100000,100000,1] offset:[12,-2] tooltip:\"%\"\n"  id id theName theTooltip to:txt2
									format  "on spn_% changed val do updateMod()\n" id to:txt2
								)
							)
						)--end i loop
						if classof (magma.getNodeProperty id "controller").value == Point3 do
						(
							format  "group \"%: %\"(\n" id theName to:txt2

							theCADCnt+=1				
							format  "vect_%_% type:#float ui:spn_%_%\n" id theCADCnt id theCADCnt to:txt1
							
							format  "spinner spn_%_% \"X: \" type:#float range:[-1000000,1000000,0] align:#right fieldwidth:50 offset:[5,-3] scale:0.01 tooltip:\"%\"\n" id theCADCnt theTooltip to:txt2
							
							theCADCnt+=1
							format  "vect_%_% type:#float ui:spn_%_%\n" id theCADCnt id theCADCnt to:txt1
							format  "spinner spn_%_% \"Y: \" type:#float range:[-1000000,1000000,0] align:#right fieldwidth:50 offset:[5,-3] scale:0.01 tooltip:\"%\"\n" id theCADCnt theTooltip to:txt2
							
							theCADCnt+=1
							format  "vect_%_% type:#float ui:spn_%_%\n" id theCADCnt id theCADCnt to:txt1
							format  "fullvect_%_% type:#color animatable:false\n"  id theCADCnt to:txt1
							
							format  "spinner spn_%_% \"Z: \" type:#float range:[-1000000,1000000,0] align:#right fieldwidth:50 offset:[5,-3] scale:0.01 tooltip:\"%\"\n" id theCADCnt theTooltip to:txt2

							format  "colorpicker clr_%_% \"\" align:#left offset:[-5,-56] height:50 width:48 alpha:true modal:true tooltip:\"%\"\n" id theCADCnt theTooltip to:txt2
							append theColorPickersToUpdate #(id,theCADCnt)

							format  ")--end group\n"  to:txt2
							
							format  "on clr_%_% changed val do (\n" id theCADCnt to:txt2
							format  "vect_%_% = val.r/255.0\n" id (theCADCnt-2) to:txt2
							format  "vect_%_% = val.g/255.0\n" id (theCADCnt-1) to:txt2
							format  "vect_%_% = val.b/255.0\n" id theCADCnt to:txt2
							format  "updateMod()\n" to:txt2
							format  ")\n" to:txt2
							
							format  "on vect_%_% get val do (\n" id (theCADCnt-2) to:txt1
							format  "theColor = [val,vect_%_%,vect_%_%]*255.0\n" id (theCADCnt-1) id theCADCnt to:txt1
							format  "params.clr_%_%.color = theColor\n" id theCADCnt  to:txt1
							format  "val)\n" to:txt1

							format  "on vect_%_% get val do (\n" id (theCADCnt-1) to:txt1
							format  "theColor = [vect_%_%,val,vect_%_% ]*255.0\n" id (theCADCnt-2) id  (theCADCnt) to:txt1
							format  "params.clr_%_%.color = theColor\n" id theCADCnt  to:txt1
							format  "val)\n" to:txt1
							
							format  "on vect_%_% get val do (\n" id theCADCnt to:txt1
							format  "theColor = [vect_%_%,vect_%_%,val]*255.0\n" id (theCADCnt-2) id (theCADCnt-1) to:txt1
							format  "params.clr_%_%.color = theColor\n" id theCADCnt to:txt1
							format  "val)\n"				 to:txt1
							
							format  "on spn_%_% changed val do (\n" id (theCADCnt-2) to:txt2
							format  "local theColor = clr_%_%.color \n" id theCADCnt to:txt2
							format  "theColor.r = val*255.0\n" to:txt2
							format  "clr_%_%.color = theColor\n" id theCADCnt to:txt2
							format  "fullvect_%_% = theColor\n" id theCADCnt to:txt2	
							format  "updateMod()\n)\n" to:txt2
							
							format  "on spn_%_% changed val do (\n" id (theCADCnt-1) to:txt2
							format  "local theColor = clr_%_%.color \n" id theCADCnt to:txt2
							format  "theColor.g = val*255.0\n" to:txt2

							format  "clr_%_%.color = theColor\n" id theCADCnt to:txt2
							format  "updateMod()\n)\n"				 to:txt2
							
							format  "on spn_%_% changed val do (\n" id theCADCnt to:txt2
							format  "local theColor = clr_%_%.color \n" id theCADCnt to:txt2
							format  "theColor.b = val*255.0\n" to:txt2
							
							format  "clr_%_%.color = theColor\n" id theCADCnt to:txt2
							format  "updateMod()\n)\n" to:txt2
							
						)--end vector		
					)--if inputValue
				)--end if exposed
			)--end i loop	
			#(txt1 as string, txt2 as string, txt3 as string)
		)
		
		fn exposeBLOPsRecursively =
		(
			local nodeArray = sort (magma.GetNodes())
			local nodeCount = nodeArray.count
			
			for i = 1 to nodeCount do
			(
				local id = nodeArray[i]
				if magma.isNodeContainer id do
				(
					magma.pushEditableBLOP id
					theCADParentNode = id
					local theName = magma.getNodeProperty id "Name"
					if theName == undefined do theName = magma.getNodeType id 
					theCADCntBefore = theCADCnt as string
					local result = exposeSubLevel()
					if theCADCnt as string != theCADCntBefore do 
					(
						theCALevel += 1
						format "checkbutton btn_level_% \"%: %\" width:164 border:false align:#center offset:[0,-2] highlightcolor:((colorman.getColor #background)*200) height:18 checked:true tooltip:\"Exposed Controls of %\n%: %\"\n " theCALevel id theName (magma.getNodeType id) id theName  to:theCADef2
						format "on btn_level_% changed state do btn_level_%.state = true\n " theCALevel theCALevel to:theCADef2
					)
					format "%" result[1] to:theCADef 
					format "%" result[2] to:theCADef2
					format "%" result[3] to:theCADef3 
					exposeBLOPsRecursively()
					magma.popEditableBLOP()
				)
			)
		)
		
		fn connectCAControllers theCAName theMod =
		(
			for id in (sort (magma.GetNodes())) do
			(
				if magma.getNodeProperty id "Exposed" == true AND findItem #("Noise","VecNoise") (magma.getNodeType id) > 0 do
				(
					theCADCnt+=1
				)
				if magma.getNodeProperty id "Exposed" == true AND magma.getNodeType id == "InputValue" do
				(
					local theController = (magma.getNodeProperty id "controller")
					if classof theController.value == Float do
					(
						theCADCnt+=1
						theMod.custAttributes[theCAName][theCADCnt].value = theController.value
						theMod.custAttributes[theCAName][theCADCnt].controller = theController
					)	
					if classof theController.value == Point3 do
					(
						if classof theController == Point3_XYZ then
						(
							theCADCnt+=1
							theMod.custAttributes[theCAName][theCADCnt].value = theController[1].controller.value
							theMod.custAttributes[theCAName][theCADCnt].controller = theController[1].controller
							theCADCnt+=1
							theMod.custAttributes[theCAName][theCADCnt].value = theController[2].controller.value
							theMod.custAttributes[theCAName][theCADCnt].controller = theController[2].controller
							theCADCnt+=1
							theMod.custAttributes[theCAName][theCADCnt].value = theController[3].controller.value
							theMod.custAttributes[theCAName][theCADCnt].controller = theController[3].controller
						)
						else
						(
							theCADCnt+=3
						)
					)--end if Point3	
				)--end if exposed
			)--end id loop	
		)--end fn
		
		fn connectBLOPsRecursively theCAName theMod =
		(
			for id in (sort (magma.GetNodes())) do
			(
				if magma.IsNodeContainer id do 
				(
					magma.pushEditableBLOP id
					connectCAControllers theCAName theMod
					connectBLOPsRecursively theCAName theMod
					magma.popEditableBLOP()
				)
			)			
		)
		
		fn exposeControlsToModifier =
		(
			local theMod = MagmaFlowEditor_Functions.getMagmaOwner magma
			if theMod == undefined do return false
				
			theCALevel = 0
				
			KrakatoaChannelEditor_IsUpdatingExposure = true
			--KrakatoaChannelsEditor_Functions.updateParentModifier suppressRedraw:true

			local isEmberExposure = #no
			if classof theMod == SimEmber do 
				isEmberExposure = if theMod.initMagmaHolder == magma then #init else #sim

			try(modpanel.setCurrentObject theMod)catch()
				
			local CustomAttributeName = MagmaFlowEditor_Functions.getExposedCAName magma
			try(deleteItem theMod.custAttributes (CustomAttributeName as name)	)catch()
			
			try(modpanel.setCurrentObject theMod)catch()
			theCADef2 = "" as stringStream
			
			local theTitleString = "Exposed Parameters"
			if isEmberExposure != #no do 
				theTitleString = if isEmberExposure == #init then "Exposed in INITIAL STATE" else "Exposed in SIMULATION"
			
				
			format "rollout params \"%\" category:10000\n(" theTitleString to:theCADef2
			--format "edittext edt_notes \"Notes:\" labelontop:true readonly:true height:60 width:162 align:#center offset:[0,-4]\n"  to:theCADef2
			format "fn updateMod sel:false= (\n"  to:theCADef2
			format "local theMod = (custAttributes.getOwner this).magmaHolder\n"  to:theCADef2
			format "local done = false\n"  to:theCADef2
			format "for i in MagmaFlowEditor_CurrentEditors where i != undefined AND i[1] == theMod AND i[2].open while not done do (\n"  to:theCADef2
			format "i[2].updateMagmaHolder updateName:false\n"  to:theCADef2
			format "i[2].updateNodePropertiesRollouts()\n" to:theCADef2
			format "if i[4].open do (\n"  to:theCADef2
			format "i[4].updateControls()\n"  to:theCADef2
			format "i[2].createNodeTree init:false\n"  to:theCADef2
			format "done = true\n"  to:theCADef2
			format ")\n"  to:theCADef2
			format "if sel == true do (i[2].displaySelectedNodeProperties())\n"  to:theCADef2
			format "if not done and theMod.autoUpdate do theMod.autoUpdate = theMod.autoUpdate \n"  to:theCADef2
			format "))\n" to:theCADef2
			
			theCADef3 = "" as stringStream
			format "fn updateUI = ( \n"  to:theCADef3
			
			theCADef = "" as stringStream
			format "KCM_CA_DEF = attributes % (\n" CustomAttributeName to:theCADef
			format "local params \n"  to:theCADef
			format "parameters main rollout:params ( \n"  to:theCADef
			
			theColorPickersToUpdate = #()
			
			theCADCnt = 0
			
			for j = 1 to magma.NumEditingBLOPs() do magma.PopEditableBLOP()
			
			local result = exposeSubLevel()
			format "%" result[1] to:theCADef 
			format "%" result[2] to:theCADef2
			format "%" result[3] to:theCADef3 
			
			exposeBLOPsRecursively()

			format ")--end main params\n" to:theCADef
			
			for j in theColorPickersToUpdate do
			(
				format "fullvect_%_% = clr_%_%.color = [vect_%_%,vect_%_%, vect_%_%]*255.0 \n" j[1] j[2] j[1] j[2] j[1] (j[2]-2) j[1] (j[2]-1) j[1] j[2] to:theCADef3 
			)
			
			--format "edt_notes.text = (custAttributes.getOwner this).magmaHolder.note\n"to:theCADef3 
			format ")--end updateUI\n" to:theCADef3 
			format "on params open do updateUI()\n" to:theCADef3 

			format "%" (theCADef3 as string) to:theCADef2
			format ")--end rollout\n" to:theCADef2 
			format ")--end def\n" to:theCADef2 
			
			if theCADCnt > 0 do
			(
				--print (theCADef+theCADef2)
				KCM_CA_DEF = execute (theCADef as string + theCADef2 as string)
				custAttributes.add theMod KCM_CA_DEF
				
				local theCAName = (CustomAttributeName as name)
				max modify mode
				try(modPanel.setCurrentObject theMod)catch()

				theCADCnt = 0

				connectCAControllers theCAName theMod
				connectBLOPsRecursively theCAName theMod
				
				try(modpanel.setCurrentObject theMod)catch()
				--setFocus KrakatoaChannelNodeEditor_Rollout.hc
			)
			for i in EditableBlopStack do magma.pushEditableBLOP i
			KrakatoaChannelEditor_IsUpdatingExposure = false
		)		
		
		fn exposeSelectedInputs newState:true =
		(
			local needUpdate = false
			local theSel = getSelectedNodes()
			local nodeArray = Magma.GetNodes()
			
			for i in theSel do
			(
				local ID = nodeArray[i]
				local theType = magma.getNodeType ID
				if findItem #(#InputGeometry, #InputObject, #InputParticles, #InputValue, #inputChannel, #loopChannel, #Curve, #TexmapEval,#InputTexmap ) (theType as name) > 0 do
				(
					magma.DeclareExtensionProperty ID "Exposed"
					magma.setNodeProperty ID "Exposed" newState
					needUpdate = true
				)
			)
			if needUpdate do
			(
				exposeControlsToModifier()
				createNodeTree init:false
			)
			displaySelectedNodeProperties()
		)
		
		fn selectExposedInputs =
		(
			local theSel = #()
			local nodeArray = magma.GetNodes()
			local nodeCount = nodeArray.count
			
			for i = 1 to nodeCount do
			(
				local ID = nodeArray[i]
				if magma.getNodeProperty ID "Exposed" == true do
					append theSel i
			)
			setSelectedNodes theSel
		)
		
		
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--NODE PROPERTIES FUNCTIONS		
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
		fn getObjectInputNode ID type =
		(
			local result = undefined
			for i = 1 to magma.getNumNodeInputs ID do
			(
				local theInput = (magma.getNodeInput ID i)
				--format "theInput = %\n" theInput 
				if theInput != undefined and theInput[1] > -1 do
				(
					if type == #prt and (magma.getNodeType theInput[1]) == "InputParticles" do result = magma.getNodeProperty theInput[1] "node"
					if type == #prop and (magma.getNodeType theInput[1]) == "InputObject" do result = magma.getNodeProperty theInput[1] "object"
					if type == #prop and (magma.getNodeType theInput[1]) == "InputGeometry" do result = (magma.getNodeProperty theInput[1] "nodes")[1]
					if type == #geo and (magma.getNodeType theInput[1]) == "InputGeometry" do result = (magma.getNodeProperty theInput[1] "nodes")[1]
				)
			)
			result
		)
		
		fn insertConvertToFloat =
		(
			MagmaFlowSettings.nodeInsertMode = true
			local currentID = (Magma.GetNodes())[MagmaFlowEditor_Rollout.lastNodeClick]
			local newID = MagmaFlowEditor_Rollout.createNode "ToFloat" mode:#button
			magma.setNodeInput newID 1 currentID 1
			MagmaFlowEditor_Rollout.setSelectedNodes #(MagmaFlowEditor_Rollout.lastNodeClick)
			MagmaFlowEditor_Rollout.updateMagmaHolder init:true
		)
		
		fn insertNodeIntoFlow nodeName =
		(
			MagmaFlowSettings.nodeInsertMode = true
			local currentID = (Magma.GetNodes())[MagmaFlowEditor_Rollout.lastNodeClick]
			local newID = MagmaFlowEditor_Rollout.createNode nodeName mode:#button
			magma.setNodeInput newID 1 currentID 1
			MagmaFlowEditor_Rollout.setSelectedNodes #(MagmaFlowEditor_Rollout.lastNodeClick)
			MagmaFlowEditor_Rollout.updateMagmaHolder init:true			
		)
		
		fn insertFaceQuery =
		(
			MagmaFlowSettings.nodeInsertMode = true
			local currentID = (Magma.GetNodes())[MagmaFlowEditor_Rollout.lastNodeClick]
			local newID = MagmaFlowEditor_Rollout.createNode "FaceQuery" mode:#button
			local theGeoConnection = magma.getNodeInput currentID 1
			magma.setNodeInput newID 1 theGeoConnection[1] theGeoConnection[2]
			magma.setNodeInput newID 2 currentID 3
			magma.setNodeInput newID 3 currentID 4
			magma.setNodeInput newID 4 currentID 7
			MagmaFlowEditor_Rollout.setSelectedNodes #(MagmaFlowEditor_Rollout.lastNodeClick)
			MagmaFlowEditor_Rollout.updateMagmaHolder init:true			
		)
		
		fn insertParticleQuery =
		(
			MagmaFlowSettings.nodeInsertMode = true
			local currentID = (Magma.GetNodes())[MagmaFlowEditor_Rollout.lastNodeClick]
			local newID = MagmaFlowEditor_Rollout.createNode "ParticleQuery" mode:#button
			local theSourceConnection = magma.getNodeInput currentID 1
			magma.setNodeInput newID 1 theSourceConnection[1] theSourceConnection[2]
			magma.setNodeInput newID 2 currentID 3
			MagmaFlowEditor_Rollout.setSelectedNodes #(MagmaFlowEditor_Rollout.lastNodeClick)
			MagmaFlowEditor_Rollout.updateMagmaHolder init:true			
		)		
		fn getEventFromPFSource obj =
		(
			local Magma_PossibleParticleGroups = for o in refs.dependents obj where classof o == ParticleGroup AND isProperty o #name collect o
			/*
			rollout Magma_SelectParticleGroup_Dialog "Select Particle Group As Source"
			(
				listbox lbx_particleGroups items:(for i in Magma_PossibleParticleGroups collect i.name)
				on Magma_SelectParticleGroup_Dialog close do
				(
					::Magma_SelectedParticleGroup = Magma_PossibleParticleGroups[lbx_particleGroups.selection]
				)
			)
			createDialog Magma_SelectParticleGroup_Dialog modal:true
			*/
			if Magma_PossibleParticleGroups.count > 0 then Magma_PossibleParticleGroups[1] else obj
		)	

		fn refineScriptCode txt =
		(
			substituteString txt "\"" "\\\""
		)
		
		local DynamicPropertiesRollout
		fn createDynamicPropertiesRollout ID =
		(
			if ID >-1 then 
			(
				local properties = (for i in magma.getNodePropertyNames ID #internal collect
				(
					#((i +":"+ magma.getNodePropertyType ID i), i, magma.getNodeProperty id i ,magma.getNodePropertyType ID i)
				))

				local theCurrentEditorIndex = (for i = 1 to MagmaFlowEditor_CurrentEditors.count where MagmaFlowEditor_CurrentEditors[i][1] == magma collect i)[1]
				if theCurrentEditorIndex == undefined do return false
				MagmaFlowEditor_CurrentEditors[theCurrentEditorIndex][3] = ID
				
				local txt =  "" as stringStream
				format "rollout DynamicPropertiesRolloutGlobal \"Properties and Actions\" category:120 (\n" to:txt
				local cnt = 0
				local hasControls = false
				local isExposedNoiseControl = false
				
				if findItem #(#Noise,#VecNoise) ((magma.GetNodeType ID) as name) > 0  then
				(
					format "checkbox chk_exposed \"Exposed\" align:#left offset:[-10,-4] checked:%\n" (isExposedNoiseControl = (magma.getNodeProperty ID "Exposed" == True)) to:txt
					format "on chk_exposed changed state do	( \n" to:txt
					format "local theMod = MagmaFlowEditor_CurrentEditors[%][1] \n" theCurrentEditorIndex to:txt
					format "theMod.DeclareExtensionProperty MagmaFlowEditor_CurrentEditors[%][3] \"Exposed\" \n" theCurrentEditorIndex to:txt
					format "theMod.setNodeProperty MagmaFlowEditor_CurrentEditors[%][3] \"Exposed\" state \n" theCurrentEditorIndex to:txt
					format "MagmaFlowEditor_CurrentEditors[%][2].exposeControlsToModifier() \n" theCurrentEditorIndex to:txt
					format "MagmaFlowEditor_CurrentEditors[%][2].createNodeTree init:false \n" theCurrentEditorIndex to:txt
					format "MagmaFlowEditor_CurrentEditors[%][2].createUndoRecord (if state then \"Exposed Control\" else \"Unexposed Control\")) \n" theCurrentEditorIndex to:txt
					hasControls = true
				)					
				
				
				if findItem #(#Equal,#Greater,#GreaterOrEqual,#Less, #LessOrEqual, #LogicalAnd, #LogicalOr, #LogicalNot, #InVolume) ((magma.GetNodeType ID) as name) > 0 do
				(
					format "button btn_convertToFloat \"Convert To Float\" width:160 offset:[0,-3] align:#center tooltip:\"Insert a ToFloat Operator to convert the Boolean value to a Floating Point value, for example to output as Selection channel.\" \n" to:txt
					format "on btn_convertToFloat pressed do MagmaFlowEditor_CurrentEditors[%][2].insertNodeIntoFlow \"ToFloat\" \n" theCurrentEditorIndex to:txt
					hasControls = true
				)
				if findItem #(#IntersectRay,#NearestPoint) ((magma.GetNodeType ID) as name) > 0 then
				(
					format "button btn_addFaceQuery \"Add Face Query\" width:160 offset:[0,-3] align:#center tooltip:\"Creates a FaceQuery Operator to sample Face Data at the calculated Barycentric Coordinates.\" \n" to:txt
					format "on btn_addFaceQuery pressed do MagmaFlowEditor_CurrentEditors[%][2].insertFaceQuery()\n" theCurrentEditorIndex to:txt
					hasControls = true
				)
				 
				for p in properties do
				(
					cnt +=1
					local displayName = ""
					for i = 1 to p[2].count do 
					(
						if bit.charasint p[2][i] >= 65 and bit.charasint p[2][i] <= 90 do displayName += " "
						displayName += p[2][i]
					)
					if bit.charasint displayName[1] >= 97 and bit.charasint displayName[1] <= 122 do displayName[1] = bit.intAsChar ((bit.charAsInt displayName[1]) - 32)
					local theType = magma.GetNodeType ID
					
					if not matchPattern p[2] pattern:"enabled" do
					(
						local acceptedValues = magma.GetNodeEnumValues ID p[2]
						if (matchPattern p[4] pattern:"String" or matchPattern p[4] pattern:"Enum") and acceptedValues.count > 0 then
						(
							local theValue = magma.getNodeProperty ID p[2]
							format "label lbl_% \"%:\" align:#left across:2 offset:[-10,0]\n" cnt displayName to:txt
							format "dropdownlist ddl_% items:% align:#right offset:[10,-3] selection:%\n" cnt acceptedValues (findItem acceptedValues theValue) to:txt
							format "on ddl_% selected itm do (\n" cnt to:txt
							format "MagmaFlowEditor_CurrentEditors[%][1].setNodeProperty MagmaFlowEditor_CurrentEditors[%][3] \"%\" ddl_%.selected \n"  theCurrentEditorIndex theCurrentEditorIndex p[2] cnt to:txt
							format "MagmaFlowEditor_CurrentEditors[%][2].createNodeTree init:false\n" theCurrentEditorIndex  to:txt 							
							format ")\n" to:txt
							hasControls = true
						)
						else if (matchPattern p[4] pattern:"Tab<String>" ) and theType != "InputTexmap" then
						(
							if findItem #("VertexQuery","FaceQuery", "ParticleQuery", "PropertyQuery", "ParticleSumRadius", "ParticleSumCount", "InputField") theType > 0 then
							(
								local theVal = p[3]
								local lastConnection = 0
								local theConnections = MagmaFlowEditor_Functions.getConnectedNodes magma ID 
								try(for i = 1 to theConnections.count where theConnections[i].count > 0 do lastConnection = i)catch()
								local thePossibleVal = #()
								local theObject = undefined
								local maxCount = 10
								case of
								(
									(theType == "VertexQuery") : 
									(
										thePossibleVal = #("Selection","Normal")
										join thePossibleVal #("Color", "TextureCoord")
										for m = 2 to 99 do append thePossibleVal ("Mapping"+(if m < 10 then "0" else "")+m as string)
										/* --Disabling the Use Available Only code
										thePossibleVal = #("Selection","Normal")
										theObject = getObjectInputNode ID #geo
										if isValidNode theObject then
										(
											local theMesh = snapShotAsMesh theObject
											if meshop.getMapSupport theMesh 0 do append thePossibleVal "Color"
											if meshop.getMapSupport theMesh 1 do append thePossibleVal "TextureCoord"
											for m = 2 to 99 where meshop.getMapSupport theMesh m do append thePossibleVal ("Mapping"+m as string)
											delete theMesh
										)
										else
										(
											join thePossibleVal #("Color", "TextureCoord")
											for m = 2 to 99 do append thePossibleVal ("Mapping"+(if m < 10 then "0" else "")+m as string)
										)
										*/
										
										sort thePossibleVal
										--for i = 1 to thePossibleVal.count where matchPattern thePossibleVal[i] pattern:"Mapping0*" do thePossibleVal[i] = "Mapping"+substring thePossibleVal[i] (thePossibleVal[i].count) 1
										maxCount = thePossibleVal.count-1
										if maxCount < 3 do maxCount = 3
										thePossibleVal = for i in thePossibleVal where findItem theVal i == 0 collect i
										theListName = " Exposed Mesh Channels:"
										defineControl = true
									)									
									(theType == "FaceQuery") : 
									(
										thePossibleVal = #("Selection","Normal","SmoothingGroup","MtlIndex","FaceElement","FaceElementArea","FaceElementVolume","FaceElementCentroid", "FaceNormal", "FaceSelection")
										append thePossibleVal "Color"
										append thePossibleVal "TextureCoord"
										for m = 2 to 99 do append thePossibleVal ("Mapping"+(if m < 10 then "0" else "")+m as string)
										
										--Disabling the Use Available Only code
										/*theObject = getObjectInputNode ID #geo
										if isValidNode theObject then
										(
											local theMesh = snapShotAsMesh theObject
											if meshop.getMapSupport theMesh 0 do append thePossibleVal "Color"
											if meshop.getMapSupport theMesh 1 do append thePossibleVal "TextureCoord"
											for m = 2 to 99 where meshop.getMapSupport theMesh m do append thePossibleVal ("Mapping"+m as string)
											delete theMesh
										)
										else
										(
											append thePossibleVal "Color"
											append thePossibleVal "TextureCoord"
											for m = 2 to 99 do append thePossibleVal ("Mapping"+(if m < 10 then "0" else "")+m as string)
										)
										*/
										sort thePossibleVal
										for i = 1 to thePossibleVal.count where matchPattern thePossibleVal[i] pattern:"Mapping0*" do thePossibleVal[i] = "Mapping"+substring thePossibleVal[i] (thePossibleVal[i].count) 1
										maxCount = thePossibleVal.count-1
										if maxCount < 3 do maxCount = 3
										thePossibleVal = for i in thePossibleVal where findItem theVal i == 0 collect i
										theListName = " Exposed Mesh Channels:"
										defineControl = true
									)
									(theType == "ParticleQuery" OR theType =="ParticleSumRadius" OR theType == "ParticleSumCount"): 
									(
										channelsList = MagmaFlowEditor_Functions.loadChannelsList magma mode:#input 
										thePossibleVal = MagmaFlowEditor_Functions.getSortedChannelsList channelsList 3 theIniFileLocation --#("Position","Color","Normal","Velocity")
										maxCount = thePossibleVal.count-1
										thePossibleVal = for i in thePossibleVal where findItem theVal i == 0 and not matchPattern i pattern:"[*]" collect i
										theListName = " Exposed Particle Channels:"
										theObject = getObjectInputNode ID #prt
										defineControl = true
										if isValidNode theObject and magma.getNodeProperty ID "ShowAvailableChannelsOnly" == true do
										(
											try
											(
												local currentStream = FranticParticles.GetPRTObjectIStream theObject true true
												theChannels = currentStream.GetChannels()
												theChannelNames = for i in theChannels collect (filterString i " ")[1]
												currentStream.close()
												maxCount = theChannelNames.count-1
												thePossibleVal = for i in theChannelNames where findItem theVal i == 0 collect i
											)catch()
										)
									)
									(theType == "PropertyQuery" ) : 
									(
										thePossibleVal = #("Pos","Rotation","Scale","Center","Transform.Row1","Transform.Row2","Transform.Row3") --,"Visibility"
										theObject = getObjectInputNode ID #prop
										if isValidNode theObject do
										(
											local theProps = getPropNames theObject
											for p in theProps do 
											(
												local theProp = try(getProperty theObject p)catch(undefined)
												if classof theProp == ArrayParameter then
													for j = 1 to theProp.count do append thePossibleVal ((p as string)+"["+j as string +"]")
												else 
													append thePossibleVal (p as string)
											)
											for m in theObject.modifiers do
											(
												theProps = getPropNames m
												for p in theProps do
												append thePossibleVal ("modifiers[#"+m.name+"]."+p as string)
											)
										)
										maxCount = thePossibleVal.count-1
										thePossibleVal = sort (for i in thePossibleVal where findItem theVal i == 0 collect i)
										theListName = " Exposed Object Properties:"
										defineControl = true
									)	
									(theType == "InputField") :
									(
										defineControl = p[2] == "channels" 
										thePossibleVal = magma.getNodeProperty ID  "availableChannels"
										theVal = magma.getNodeProperty ID "channels"
										theListName = " Exposed Fields:"
									)
								)
								if defineControl do
								(
									with printAllElements on format "listbox lbx_on_% \"%\" items:% width:164 align:#center height:% offset:[0,-5] \n" cnt theListName theVal (amin #(maxCount,4)) to:txt
									format "edittext edt_property_% align:#left offset:[-15,-5] fieldwidth:163  \n" cnt  to:txt
									if (theType == "ParticleQuery" OR theType == "NParticlesAvg" OR theType =="ParticleSumRadius" OR theType == "ParticleSumCount" OR theType == "ParticleKernel" ) do
									(
										format "checkbutton chk_ShowAvailableChannelsOnly \">Available Channels Only\" align:#center width:164 offset:[0,-4] checked:%\n" (magma.getNodeProperty ID "ShowAvailableChannelsOnly" == true) to:txt
										format "on chk_ShowAvailableChannelsOnly changed state do (\n" to:txt
										format "MagmaFlowEditor_CurrentEditors[%][1].DeclareExtensionProperty MagmaFlowEditor_CurrentEditors[%][3] \"ShowAvailableChannelsOnly\" \n" theCurrentEditorIndex theCurrentEditorIndex to:txt
										format "MagmaFlowEditor_CurrentEditors[%][1].SetNodeProperty MagmaFlowEditor_CurrentEditors[%][3] \"ShowAvailableChannelsOnly\" state\n" theCurrentEditorIndex theCurrentEditorIndex to:txt
										format "MagmaFlowEditor_CurrentEditors[%][2].displaySelectedNodeProperties()\n" theCurrentEditorIndex  to:txt 
										format ")\n" to:txt
									)
									with printAllElements on format "dropdownlist lbx_off_% items:% width:164 align:#center height:10 offset:[0,-5] tooltip:\"Select a pre-defined Channel from the list and press [Add...] to Expose as Output...\"\n" cnt thePossibleVal to:txt --(amin #(maxCount,10)) 
									format "button btn_on_% \"Add...\" across:2 width:82 align:#left offset:[-12,-5] tooltip:\"Press to Expose the Mesh Channel selected in the drop-down list\" \n" cnt to:txt
									format "button btn_off_% \"Remove...\" width:82 align:#right offset:[12,-5] tooltip:\"Press to Un-expose the Channel selected in the list box.\"\n" cnt to:txt

										
									format "fn updateCSVProperty = (\n" to:txt
									format "MagmaFlowEditor_CurrentEditors[%][1].setNodeProperty MagmaFlowEditor_CurrentEditors[%][3] \"%\" lbx_on_%.items \n" theCurrentEditorIndex theCurrentEditorIndex p[2] cnt to:txt
									format "MagmaFlowEditor_CurrentEditors[%][2].createNodeTree init:true\n" theCurrentEditorIndex  to:txt 							
									format ")\n" to:txt
										
									format "on edt_property_% entered txt do (" cnt to:txt
									format "if txt.count > 1 do lbx_on_%.items = append lbx_on_%.items txt\n" cnt cnt to:txt								
									format "updateCSVProperty())\n" to:txt
									
									format "fn sortList theArray = (\n" to:txt
									format "for i = 1 to theArray.count where matchPattern theArray[i] pattern:\"Mapping*\" and theArray[i].count == 8 do theArray[i] = \"Mapping0\"+substring theArray[i] (theArray[i].count) 1 \n" to:txt
									format "sort theArray\n" to:txt
									format "for i = 1 to theArray.count where matchPattern theArray[i] pattern:\"Mapping0*\" do theArray[i] = \"Mapping\"+substring theArray[i] (theArray[i].count) 1 \n" to:txt
									format "theArray\n" to:txt
									format ")\n" to:txt
										
									format "fn addToList itm = (\n" to:txt
									format "if itm > 0 and itm <=  lbx_off_%.items.count do (\n" cnt to:txt
									format "lbx_on_%.items = (append lbx_on_%.items lbx_off_%.selected)\n" cnt cnt cnt to:txt
									format "lbx_off_%.items = sortList (deleteItem lbx_off_%.items itm)\n" cnt cnt to:txt
									format "updateCSVProperty()))\n" to:txt

									format "fn removeFromList itm = (\n" to:txt
									format "if itm > 0 and lbx_on_%.items.count > 0 do (\n" cnt  to:txt --and lbx_on_%.items.count-1 >= %  lastConnection cnt
									format "local theMagma = MagmaFlowEditor_CurrentEditors[%][1] \n" theCurrentEditorIndex  to:txt
									local socketOffset = 1
									if theType =="ParticleSumRadius" OR theType == "ParticleSumCount" do socketOffset = 3 
									if theType =="FaceQuery" and magma.getNodeProperty ID "exposePosition" == true do socketOffset = 1
									
									format "for i = itm+% to % do  (\n" socketOffset lastConnection to:txt
									format "local theNodes = theMagma.getNodes() \n" to:txt
									format "for j in theNodes do (\n" to:txt
									format "for c = 1 to theMagma.getNumNodeInputs j do (\n" to:txt
									format "theConnection =theMagma.getNodeInput j c \n" to:txt
									format "if theConnection[1] == % and theConnection[2] == i do (theConnection[2] = theConnection[2]-1;  theMagma.setNodeInput j c theConnection[1] theConnection[2] )\n" ID to:txt
									format ")))\n" to:txt
									format "lbx_off_%.items = sortList (if findItem lbx_off_%.items lbx_on_%.selected == 0 then append lbx_off_%.items lbx_on_%.selected else lbx_off_%.items)\n" cnt cnt cnt cnt cnt cnt to:txt
									format "if itm > 0 do lbx_on_%.items = (deleteItem lbx_on_%.items itm)\n" cnt cnt to:txt
									format "updateCSVProperty()))\n" to:txt
										
									format "on lbx_off_% doubleClicked itm do addToList itm\n" cnt to:txt
									format "on lbx_on_% selected itm do edt_property_%.text = lbx_on_%.selected\n" cnt cnt cnt to:txt
									
									format "on btn_on_% pressed do addToList lbx_off_%.selection\n" cnt cnt to:txt
									
									format "on lbx_on_% doubleClicked itm do removeFromList itm\n" cnt to:txt
									format "on btn_off_% pressed do removeFromList lbx_on_%.selection\n" cnt cnt to:txt
										
									hasControls = true
								)
							)
							else
							(
								--format "edittext edt_% \"%:\" labelOnTop:true text:\"%\" width:160 align:#center\n" cnt displayName p[3] to:txt
								--format "on edt_% entered txt do MagmaFlowEditor_CurrentEditors[%][1].setNodeProperty MagmaFlowEditor_CurrentEditors[%][3] \"%\" txt \n" cnt theCurrentEditorIndex theCurrentEditorIndex p[2] to:txt
								--hasControls = true
							)
						)
						else if matchPattern p[4] pattern:"String" then
						(
							if findItem #("InputField") theType > 0 then
							(
								format "edittext edt_% \"%:\" labelOnTop:true text:\"%\" width:160 align:#center\n" cnt displayName p[3] to:txt
								format "button btn_pick_% \"Pick Override File...\" align:#center width:160\n" cnt  to:txt
								format "on btn_pick_% pressed do (\n" cnt to:txt
								format "local theFileName = getOpenFileName types:\"FumeFX FXD Files (*.fxd)|*.fxd\"\n" to:txt
								format "if theFileName != undefined and doesFileExist theFileName do (\n" to:txt
								format "theFileName = getFileNamePath theFileName + substring (getFileNameFile theFileName) 1 ((getFileNameFile theFileName).count-4)+ \"####\" + getFileNameType theFileName\n" to:txt
								format "MagmaFlowEditor_CurrentEditors[%][1].setNodeProperty MagmaFlowEditor_CurrentEditors[%][3] \"%\" theFileName \n" theCurrentEditorIndex theCurrentEditorIndex p[2] to:txt
								format "MagmaFlowEditor_CurrentEditors[%][2].createNodeTree init:true\n" theCurrentEditorIndex  to:txt 								
								format "edt_%.text = theFileName\n" cnt to:txt
								format "))\n" to:txt
								
								format "on edt_% entered txt do MagmaFlowEditor_CurrentEditors[%][1].setNodeProperty MagmaFlowEditor_CurrentEditors[%][3] \"%\" txt \n" cnt theCurrentEditorIndex theCurrentEditorIndex p[2] to:txt
								hasControls = true
							)
							else if findItem #("InputScript") theType > 0 then
							(
								format "edittext edt_% \"%:\" labelOnTop:true text:\"%\" width:160 height:128 align:#center\n" cnt displayName (refineScriptCode p[3]) to:txt
								format "on edt_% entered txt do MagmaFlowEditor_CurrentEditors[%][1].setNodeProperty MagmaFlowEditor_CurrentEditors[%][3] \"%\" txt \n" cnt theCurrentEditorIndex theCurrentEditorIndex p[2] to:txt
								hasControls = true
							)							
							else
							(
								format "edittext edt_% \"%:\" labelOnTop:true text:\"%\" width:160 align:#center\n" cnt displayName p[3] to:txt
								format "on edt_% entered txt do MagmaFlowEditor_CurrentEditors[%][1].setNodeProperty MagmaFlowEditor_CurrentEditors[%][3] \"%\" txt \n" cnt theCurrentEditorIndex theCurrentEditorIndex p[2] to:txt
								hasControls = true
							)
						)				
						else if theType == "InputTexmap" and matchPattern p[4] pattern:"Texmap" then  
						(
							format "checkbox chk_exposed \"Exposed\" align:#left offset:[-10,-4] \n" to:txt
							format "on chk_exposed changed state do	( \n" to:txt
							format "local theMod = MagmaFlowEditor_CurrentEditors[%][1] \n" theCurrentEditorIndex to:txt
							format "theMod.DeclareExtensionProperty MagmaFlowEditor_CurrentEditors[%][3] \"Exposed\" \n" theCurrentEditorIndex to:txt
							format "theMod.setNodeProperty MagmaFlowEditor_CurrentEditors[%][3] \"Exposed\" state \n" theCurrentEditorIndex to:txt
							format "MagmaFlowEditor_CurrentEditors[%][2].exposeControlsToModifier() \n" theCurrentEditorIndex to:txt
							format "MagmaFlowEditor_CurrentEditors[%][2].createNodeTree init:false \n" theCurrentEditorIndex to:txt
							format "MagmaFlowEditor_CurrentEditors[%][2].createUndoRecord (if state then \"Exposed Control\" else \"Unexposed Control\")) \n" theCurrentEditorIndex to:txt
							
							format "mapbutton map_% \"%\" width:160 align:#center\n" cnt (if p[3] != undefined then (p[3].name + " ("+(classof p[3]) as string +")") else "<Add Texture Map>") to:txt
							format "button btn_mapToMEdit \"Put To MEdit\" width:80 align:#left offset:[-10,-3] across:2\n" to:txt
							format "button btn_RemoveMap \"Remove Map\" width:80 align:#right offset:[10,-3] \n" to:txt

							format "on btn_mapToMEdit pressed do (\n" to:txt
							format "local theMap = ::MagmaFlowEditor_CurrentEditors[%][1].getNodeProperty ::MagmaFlowEditor_CurrentEditors[%][3] \"texmap\" \n" theCurrentEditorIndex theCurrentEditorIndex to:txt
							format "if theMap != undefined do (MatEditor.Open(); meditMaterials[medit.GetActiveMtlSlot()] = theMap ))\n" to:txt
							
							format "on btn_RemoveMap pressed do (\n" to:txt
							format "::MagmaFlowEditor_CurrentEditors[%][1].setNodeProperty ::MagmaFlowEditor_CurrentEditors[%][3] \"texmap\" undefined \n" theCurrentEditorIndex theCurrentEditorIndex to:txt
							format "MagmaFlowEditor_CurrentEditors[%][2].createNodeTree init:false\n" theCurrentEditorIndex  to:txt 							
							format  ")\n" to:txt
							
							format "on map_% picked aMap do (\n" cnt to:txt
							format "map_%.caption = if aMap == undefined then \"<Add Texture Map>\" else aMap.name + \" (\" + (classof aMap) as string + \")\" \n" cnt to:txt
							format  "::MagmaFlowEditor_CurrentEditors[%][1].setNodeProperty ::MagmaFlowEditor_CurrentEditors[%][3] \"%\" aMap\n"  theCurrentEditorIndex  theCurrentEditorIndex p[2] to:txt
							format "MagmaFlowEditor_CurrentEditors[%][2].createNodeTree init:false\n" theCurrentEditorIndex  to:txt 							
							format  ")\n" to:txt
							
							format "group \"Explicit Channel Inputs:\" (" to:txt
							format "checkbox chk_exposePosition \"Position\" offset:[-5,-3] across:2\n" to:txt
							format "checkbox chk_exposeVertexColor \"Vertex Color\" offset:[-14,-3]\n" to:txt
							
							format "checkbox chk_exposeNormal \"Normal\" offset:[-5,-3] across:2\n" to:txt
							format "checkbox chk_exposeTextureCoord \"TextureCoord\" offset:[-14,-3]\n" to:txt

							format "listbox lbx_on_% \" Additional Mapping Channels:\" width:154 align:#center height:3 offset:[0,-1] \n" cnt to:txt
							format "button btn_on_% \"Add...\" across:2 width:76 align:#left offset:[-6,-5]\n" cnt to:txt
							format "button btn_off_% \"Remove...\" width:76 align:#right offset:[6,-5]\n" cnt to:txt
							format "listbox lbx_off_% width:154 align:#center height:5 offset:[0,-5]\n" cnt to:txt
							format ")\n" to:txt
							
							format "fn updateTexmapChannel = (\n" to:txt
							
							format "local theChannels = ::MagmaFlowEditor_CurrentEditors[%][1].getNodeProperty ::MagmaFlowEditor_CurrentEditors[%][3] \"channels\" \n"  theCurrentEditorIndex  theCurrentEditorIndex to:txt
							format "chk_exposePosition.checked = findItem theChannels \"Position\" > 0\n" to:txt
							format "chk_exposeNormal.checked = findItem theChannels \"Normal\" > 0 \n" to:txt
							format "chk_exposeVertexColor.checked = findItem theChannels \"Color\" > 0 \n" to:txt
							format "chk_exposeTextureCoord.checked = findItem theChannels \"TextureCoord\" > 0 \n" to:txt

							format "local theVal = for c in theChannels where matchPattern c pattern:\"Mapping*\" collect c \n" to:txt
							format "local thePossibleVal = for i = 2 to 99 where (theName = \"Mapping\"+i as string; findItem theVal theName == 0) collect theName\n" to:txt
							format "lbx_on_%.items =  theVal \n" cnt to:txt
							format "lbx_off_%.items = thePossibleVal \n" cnt to:txt
							format ")\n" to:txt							
							
							format "fn setTexmapChannel theChannel theState = (\n" to:txt
							
							format "local theChannels = ::MagmaFlowEditor_CurrentEditors[%][1].getNodeProperty ::MagmaFlowEditor_CurrentEditors[%][3] \"channels\" \n"  theCurrentEditorIndex  theCurrentEditorIndex to:txt
							
							format "if theState and findItem theChannels theChannel == 0 do append theChannels theChannel\n" to:txt
							format "if not theState and findItem theChannels theChannel > 0 do deleteItem theChannels (findItem theChannels theChannel)\n" to:txt
							format "sort theChannels\n" to:txt
							
							format "::MagmaFlowEditor_CurrentEditors[%][1].setNodeProperty ::MagmaFlowEditor_CurrentEditors[%][3] \"channels\" theChannels\n" theCurrentEditorIndex  theCurrentEditorIndex to:txt
							
							format "updateTexmapChannel()\n" to:txt
							format "MagmaFlowEditor_CurrentEditors[%][2].createNodeTree init:true\n" theCurrentEditorIndex  to:txt 							
							format ")\n" to:txt
							
							format "on chk_exposePosition changed state do setTexmapChannel \"Position\" state\n" to:txt
							format "on chk_exposeNormal changed state do setTexmapChannel \"Normal\" state\n" to:txt
							format "on chk_exposeVertexColor changed state do setTexmapChannel \"Color\" state\n" to:txt
							format "on chk_exposeTextureCoord changed state do setTexmapChannel \"TextureCoord\" state\n" to:txt
							
							format "on lbx_on_% doubleClicked itm do setTexmapChannel lbx_on_%.selected false\n" cnt cnt to:txt
							format "on lbx_off_% doubleClicked itm do setTexmapChannel lbx_off_%.selected true\n" cnt cnt to:txt
							format "on btn_on_% pressed do setTexmapChannel lbx_off_%.selected true\n" cnt cnt to:txt
							format "on btn_off_% pressed do setTexmapChannel lbx_on_%.selected false\n" cnt cnt to:txt
							
							format "on DynamicPropertiesRolloutGlobal open do (\n" to:txt
							format "updateTexmapChannel()\n" to:txt
							format "chk_exposed.state = (MagmaFlowEditor_CurrentEditors[%][1].getNodeProperty MagmaFlowEditor_CurrentEditors[%][3] \"Exposed\") == true \n" theCurrentEditorIndex theCurrentEditorIndex to:txt
							format ")\n" to:txt
							
							hasControls = true
						)
						else if theType == "TexmapEval"  and matchPattern p[4] pattern:"Texmap" then  
						(
							format "checkbox chk_exposed \"Exposed\" align:#left offset:[-10,-4] \n" to:txt
							format "on chk_exposed changed state do	( \n" to:txt
							format "local theMod = MagmaFlowEditor_CurrentEditors[%][1] \n" theCurrentEditorIndex to:txt
							format "theMod.DeclareExtensionProperty MagmaFlowEditor_CurrentEditors[%][3] \"Exposed\" \n" theCurrentEditorIndex to:txt
							format "theMod.setNodeProperty MagmaFlowEditor_CurrentEditors[%][3] \"Exposed\" state \n" theCurrentEditorIndex to:txt
							format "MagmaFlowEditor_CurrentEditors[%][2].exposeControlsToModifier() \n" theCurrentEditorIndex to:txt
							format "MagmaFlowEditor_CurrentEditors[%][2].createNodeTree init:false \n" theCurrentEditorIndex to:txt
							format "MagmaFlowEditor_CurrentEditors[%][2].createUndoRecord (if state then \"Exposed Control\" else \"Unexposed Control\")) \n" theCurrentEditorIndex to:txt

							format "mapbutton map_% \"%\" width:160 align:#center\n" cnt (if p[3] != undefined then (p[3].name + " ("+(classof p[3]) as string +")") else "<Add Texture Map>") to:txt
							format "button btn_mapToMEdit \"Put To MEdit\" width:80 align:#left offset:[-10,-3] across:2\n" to:txt
							format "button btn_RemoveMap \"Remove Map\" width:80 align:#right offset:[10,-3] \n" to:txt

							format "on btn_mapToMEdit pressed do (\n" to:txt
							format "local theMap = ::MagmaFlowEditor_CurrentEditors[%][1].getNodeProperty ::MagmaFlowEditor_CurrentEditors[%][3] \"texmap\" \n" theCurrentEditorIndex theCurrentEditorIndex to:txt
							format "if theMap != undefined do ( MatEditor.Open(); meditMaterials[medit.GetActiveMtlSlot()] = theMap))\n" to:txt
							
							format "on btn_RemoveMap pressed do (\n" to:txt
							format "::MagmaFlowEditor_CurrentEditors[%][1].setNodeProperty ::MagmaFlowEditor_CurrentEditors[%][3] \"texmap\" undefined \n" theCurrentEditorIndex theCurrentEditorIndex to:txt
							format "MagmaFlowEditor_CurrentEditors[%][2].createNodeTree init:false\n" theCurrentEditorIndex  to:txt 							
							format "if (MagmaFlowEditor_CurrentEditors[%][1].getNodeProperty MagmaFlowEditor_CurrentEditors[%][3] \"Exposed\") == true do \n" theCurrentEditorIndex theCurrentEditorIndex to:txt
							format "MagmaFlowEditor_CurrentEditors[%][2].exposeControlsToModifier() \n" theCurrentEditorIndex to:txt
							format  ")\n" to:txt
							
							format "on map_% picked aMap do (\n" cnt to:txt
							format "map_%.caption = if aMap == undefined then \"<Add Texture Map>\" else aMap.name + \" (\" + (classof aMap) as string + \")\" \n" cnt to:txt
							format  "::MagmaFlowEditor_CurrentEditors[%][1].setNodeProperty ::MagmaFlowEditor_CurrentEditors[%][3] \"%\" aMap\n"  theCurrentEditorIndex  theCurrentEditorIndex p[2] to:txt
							format "MagmaFlowEditor_CurrentEditors[%][2].createNodeTree init:false\n" theCurrentEditorIndex  to:txt 				
							format "if (MagmaFlowEditor_CurrentEditors[%][1].getNodeProperty MagmaFlowEditor_CurrentEditors[%][3] \"Exposed\") == true do \n" theCurrentEditorIndex theCurrentEditorIndex to:txt
							format "MagmaFlowEditor_CurrentEditors[%][2].exposeControlsToModifier() \n" theCurrentEditorIndex to:txt
							format  ")\n" to:txt
							
							format "group \"Explicit Channel Inputs:\" (" to:txt
							format "listbox lbx_on_% \" Additional Mapping Channels:\" width:154 align:#center height:3 offset:[0,-1] \n" cnt to:txt
							format "button btn_on_% \"Add...\" across:2 width:76 align:#left offset:[-6,-5]\n" cnt to:txt
							format "button btn_off_% \"Remove...\" width:76 align:#right offset:[6,-5]\n" cnt to:txt
							format "listbox lbx_off_% width:154 align:#center height:5 offset:[0,-5]\n" cnt to:txt
							format ")\n" to:txt
							
							format "fn updateTexmapChannel = (\n" to:txt
							format "local theChannels = ::MagmaFlowEditor_CurrentEditors[%][1].getNodeProperty ::MagmaFlowEditor_CurrentEditors[%][3] \"mapChannels\" \n"  theCurrentEditorIndex  theCurrentEditorIndex to:txt
							format "if theChannels == undefined do theChannels = #()\n" to:txt
							format "local theVal = for c in theChannels collect \"Mapping\" + c as string \n" to:txt
							format "local thePossibleVal = for i = 2 to 99 where (theName = \"Mapping\" + i as string; findItem theVal theName == 0) collect theName\n" to:txt
							format "lbx_on_%.items =  theVal \n" cnt to:txt
							format "lbx_off_%.items = thePossibleVal \n" cnt to:txt
							format ")\n" to:txt							
							
							format "fn setTexmapChannel theChannel theState = (\n" to:txt
							format "local theChannels = ::MagmaFlowEditor_CurrentEditors[%][1].getNodeProperty ::MagmaFlowEditor_CurrentEditors[%][3] \"mapChannels\" \n"  theCurrentEditorIndex  theCurrentEditorIndex to:txt
							format "if theChannels == undefined do theChannels = #()\n" to:txt
							format "theChannelNumber = (substring theChannel 8 -1) as integer \n" to:txt
							format "if theState and findItem theChannels theChannelNumber == 0 do append theChannels theChannelNumber\n" to:txt
							format "if not theState and findItem theChannels theChannelNumber > 0 do deleteItem theChannels (findItem theChannels theChannelNumber)\n" to:txt
							format "::MagmaFlowEditor_CurrentEditors[%][1].setNodeProperty ::MagmaFlowEditor_CurrentEditors[%][3] \"mapChannels\" theChannels\n" theCurrentEditorIndex  theCurrentEditorIndex to:txt
							
							format "updateTexmapChannel()\n" to:txt
							format "MagmaFlowEditor_CurrentEditors[%][2].createNodeTree init:true\n" theCurrentEditorIndex  to:txt 							
							format ")\n" to:txt
							
							format "on lbx_on_% doubleClicked itm do setTexmapChannel lbx_on_%.selected false\n" cnt cnt to:txt
							format "on lbx_off_% doubleClicked itm do setTexmapChannel lbx_off_%.selected true\n" cnt cnt to:txt
							format "on btn_on_% pressed do setTexmapChannel (lbx_off_%.selected) true\n" cnt cnt to:txt
							format "on btn_off_% pressed do setTexmapChannel (lbx_on_%.selected) false\n" cnt cnt to:txt
							
							format "on DynamicPropertiesRolloutGlobal open do ( \n" to:txt
							format "updateTexmapChannel()\n" to:txt
							format "chk_exposed.state = (MagmaFlowEditor_CurrentEditors[%][1].getNodeProperty MagmaFlowEditor_CurrentEditors[%][3] \"Exposed\") == true \n" theCurrentEditorIndex theCurrentEditorIndex to:txt
							format ")\n" to:txt

							
							hasControls = true
						)						
						else if matchPattern p[2] pattern:"curve" and matchPattern p[4] pattern:"class*" then
						(
							format "local theCI = MagmaFlowEditor_CurrentEditors[%][1].getNodeProperty MagmaFlowEditor_CurrentEditors[%][3] \"curve\" \n" theCurrentEditorIndex theCurrentEditorIndex to:txt

							format "checkbox chk_exposed \"Expose\" align:#left offset:[-10,-4] across:2 \n" to:txt
							format "on chk_exposed changed state do	( \n" to:txt
							format "local theMod = MagmaFlowEditor_CurrentEditors[%][1] \n" theCurrentEditorIndex to:txt
							format "theMod.DeclareExtensionProperty MagmaFlowEditor_CurrentEditors[%][3] \"Exposed\" \n" theCurrentEditorIndex to:txt
							format "theMod.setNodeProperty MagmaFlowEditor_CurrentEditors[%][3] \"Exposed\" state \n" theCurrentEditorIndex to:txt
							format "MagmaFlowEditor_CurrentEditors[%][2].exposeControlsToModifier() \n" theCurrentEditorIndex to:txt
							format "MagmaFlowEditor_CurrentEditors[%][2].createNodeTree init:false \n" theCurrentEditorIndex to:txt
							format "MagmaFlowEditor_CurrentEditors[%][2].createUndoRecord (if state then \"Exposed Control\" else \"Unexposed Control\")) \n" theCurrentEditorIndex to:txt
							
							format "checkbox chk_exposedInBLOP \"Expose In BLOP\" align:#right offset:[13,-4] \n"  to:txt
							format "on chk_exposedInBLOP changed state do ( \n" to:txt
							format "local theMod = MagmaFlowEditor_CurrentEditors[%][1] \n" theCurrentEditorIndex to:txt
							format "theMod.DeclareExtensionProperty MagmaFlowEditor_CurrentEditors[%][3] \"ExposedInBLOP\" \n" theCurrentEditorIndex to:txt
							format "theMod.setNodeProperty MagmaFlowEditor_CurrentEditors[%][3] \"ExposedInBLOP\" state \n" theCurrentEditorIndex to:txt
							format ")\n" to:txt
							
							format "button btn_% \"Open Curve Editor...\" width:160 align:#center height:30 offset:[0,-4] \n" cnt to:txt
							format "CurveControl crv_CurveControl width:160 height:120 align:#center offset:[0,-2] numCurves:1 visible:true enabled:false uiflags:#(#drawBG,#drawgrid,#ruler) x_range:(theCI.getDomain())\n" to:txt
							
							format "on btn_% pressed do (\n" cnt to:txt
							format "MagmaFlowEditor_CurrentEditors[%][2].openCurveEditor %\n" theCurrentEditorIndex ID to:txt
							format  ")\n" to:txt
							format "on DynamicPropertiesRolloutGlobal open do (\n" to:txt
							format "::MagmaFlowEditor_CurrentCurveThumbnail = crv_CurveControl\n" to:txt
							format "::MagmaFlowEditor_CurrentEditor = MagmaFlowEditor_CurrentEditors[%][2] \n"theCurrentEditorIndex  to:txt
							format "::MagmaFlowEditor_Functions.loadControlCurves crv_CurveControl theCI \n" to:txt
							format "chk_exposed.state = (MagmaFlowEditor_CurrentEditors[%][1].getNodeProperty MagmaFlowEditor_CurrentEditors[%][3] \"Exposed\") == true \n" theCurrentEditorIndex theCurrentEditorIndex to:txt
							format "chk_exposedInBLOP.state = (MagmaFlowEditor_CurrentEditors[%][1].getNodeProperty MagmaFlowEditor_CurrentEditors[%][3] \"ExposedInBLOP\") == true \n" theCurrentEditorIndex theCurrentEditorIndex to:txt
							format  ")\n" to:txt
							hasControls = true
						)
						else if matchPattern p[2] pattern:"nodes" and (matchPattern p[4] pattern:"class" or matchPattern p[4] pattern:"Tab<Node>") then
						(
							local theNameString1 = "Get by Name..."
							local theNameString2 = "Pick in Scene..."
							local theTooltip1 = "Get multiple Objects by name..."
							local theTooltip2 = "Get one Object by clicking in the viewport..."
							case (magma.getNodeType ID) as name of
							(
								default: (
									format "fn pickObjectsFilter% obj = ( true ) \n" cnt to:txt
								)
								#InputGeometry: 
								(
									format "fn pickObjectsFilter% obj = ((try(findItem ::MagmaFlowEditor_GlobalPickFilterArray% obj == 0)catch(true)) AND findItem GeometryClass.classes (classof obj) > 0 and classof obj != targetObject and  findItem #(PF_Source,PRT_Volume,PRT_FumeFX,KrakatoaPRTLoader,PRT_Source,PRT_Maker,PRT_Hair,PRT_Surface,PRT_Field,Stoke,Stoke_Field,StokeFieldLoader,StokeFieldSIM,PHXSimulator) (classof obj.baseobject) == 0 )\n" cnt theCurrentEditorIndex theCurrentEditorIndex cnt cnt to:txt
									--theNameString1 = "Get Objects..."
									theTooltip1 = "Get multiple Objects by name..."
									theTooltip2 = "Get one Object by clicking in the viewport..."
								)
								/*#InputParticles: 
								(
									format "fn pickObjectsFilter% obj = ( findItem #(PF_Source,PRT_Volume,PRT_FumeFX,KrakatoaPRTLoader,PRT_Source,PRT_Maker,PRT_Hair) (classof obj.baseobject) > 0 )\n" cnt to:txt
									theNameString = "Pick Particle Objects..."
								)*/
							)
							local theName1 = theNameString1
							local theName2 = theNameString2
							format "checkbox chk_exposed \"Expose\" align:#left offset:[-10,-4] across:2 \n" to:txt
							format "on chk_exposed changed state do	( \n" to:txt
							format "local theMod = MagmaFlowEditor_CurrentEditors[%][1] \n" theCurrentEditorIndex to:txt
							format "theMod.DeclareExtensionProperty MagmaFlowEditor_CurrentEditors[%][3] \"Exposed\" \n" theCurrentEditorIndex to:txt
							format "theMod.setNodeProperty MagmaFlowEditor_CurrentEditors[%][3] \"Exposed\" state \n" theCurrentEditorIndex to:txt
							format "MagmaFlowEditor_CurrentEditors[%][2].exposeControlsToModifier() \n" theCurrentEditorIndex to:txt
							format "MagmaFlowEditor_CurrentEditors[%][2].createNodeTree init:false \n" theCurrentEditorIndex to:txt
							format "MagmaFlowEditor_CurrentEditors[%][2].createUndoRecord (if state then \"Exposed Control\" else \"Unexposed Control\")) \n" theCurrentEditorIndex to:txt
							
							format "checkbox chk_exposedInBLOP \"Expose In BLOP\" align:#right offset:[13,-4] \n"  to:txt
							format "on chk_exposedInBLOP changed state do ( \n" to:txt
							format "local theMod = MagmaFlowEditor_CurrentEditors[%][1] \n" theCurrentEditorIndex to:txt
							format "theMod.DeclareExtensionProperty MagmaFlowEditor_CurrentEditors[%][3] \"ExposedInBLOP\" \n" theCurrentEditorIndex to:txt
							format "theMod.setNodeProperty MagmaFlowEditor_CurrentEditors[%][3] \"ExposedInBLOP\" state \n" theCurrentEditorIndex to:txt
							format ")\n" to:txt
							
							format "button btn_node1_% \"%\" width:82 align:#left tooltip:\"%\" across:2 offset:[-12,-1]\n" cnt theName1 theTooltip1  to:txt
							format "pickbutton btn_node2_% \"%\" width:82 align:#right tooltip:\"%\" offset:[12,-1] filter:pickObjectsFilter% \n" cnt theName2 theTooltip2 cnt to:txt
							
							format "multilistbox lbx_node% width:164 align:#center offset:[0,-3]\n" cnt to:txt
							format "button btn_removenodes% \"Remove Objects\" width:164 offset:[0,-4] align:#center tooltip:\"Remove highlighted nodes from the input's list...\" \n" cnt to:txt
							
							format "fn updateNodesList = (try(\n" to:txt
							format "local allNodes = MagmaFlowEditor_CurrentEditors[%][1].getNodeProperty MagmaFlowEditor_CurrentEditors[%][3] \"%\" \n" theCurrentEditorIndex  theCurrentEditorIndex p[2] to:txt
							format "::MagmaFlowEditor_GlobalPickFilterArray% = allNodes\n" cnt to:txt
							format "lbx_node%.items =  for i in allNodes collect if isValidNode i then i.name else \"<deleted>\" \n" cnt to:txt
							format "MagmaFlowEditor_CurrentEditors[%][2].createNodeTree init:false\n" theCurrentEditorIndex  to:txt 	
							format "chk_exposed.state = (MagmaFlowEditor_CurrentEditors[%][1].getNodeProperty MagmaFlowEditor_CurrentEditors[%][3] \"Exposed\") == true \n" theCurrentEditorIndex theCurrentEditorIndex to:txt
							format "chk_exposedInBLOP.state = (MagmaFlowEditor_CurrentEditors[%][1].getNodeProperty MagmaFlowEditor_CurrentEditors[%][3] \"ExposedInBLOP\") == true \n" theCurrentEditorIndex theCurrentEditorIndex to:txt
							
							format "try(modPanel.setCurrentObject (modPanel.getCurrentObject()))catch()\n" to:txt 	
							format ")catch())\n" to:txt
							format "on btn_removenodes% pressed do (\n" cnt to:txt
							format "local theNodes = MagmaFlowEditor_CurrentEditors[%][1].getNodeProperty MagmaFlowEditor_CurrentEditors[%][3] \"%\" \n" theCurrentEditorIndex  theCurrentEditorIndex p[2] to:txt
							format "local theSel = lbx_node%.selection as array \n" cnt to:txt
							format "for i = theSel.count to 1 by -1 do deleteItem theNodes theSel[i] \n" to:txt
							format "MagmaFlowEditor_CurrentEditors[%][1].setNodeProperty MagmaFlowEditor_CurrentEditors[%][3] \"%\" theNodes\n"  theCurrentEditorIndex  theCurrentEditorIndex p[2] to:txt
							format "updateNodesList()\n" to:txt
							format ")\n" to:txt
							format "on DynamicPropertiesRolloutGlobal open do updateNodesList()\n" to:txt
							
							format "on btn_node1_% pressed do (\n" cnt to:txt
							format "local allNodes = MagmaFlowEditor_CurrentEditors[%][1].getNodeProperty MagmaFlowEditor_CurrentEditors[%][3] \"%\" \n" theCurrentEditorIndex  theCurrentEditorIndex p[2] to:txt
							format "::MagmaFlowEditor_GlobalPickFilterArray% = allNodes\n" cnt to:txt
							format "local theNodes = selectByName title:\"%\" filter:pickObjectsFilter% showHidden:true single:false \n"  theNameString1 cnt to:txt
							format "if theNodes != undefined do (\nfor o in theNodes do appendIfUnique allNodes o\n" to:txt
							format "MagmaFlowEditor_CurrentEditors[%][1].setNodeProperty MagmaFlowEditor_CurrentEditors[%][3] \"%\" allNodes\n"  theCurrentEditorIndex  theCurrentEditorIndex p[2] to:txt
							format "updateNodesList()) )\n" to:txt
							
							format "on btn_node2_% picked obj do (\n" cnt to:txt
							format "local allNodes = MagmaFlowEditor_CurrentEditors[%][1].getNodeProperty MagmaFlowEditor_CurrentEditors[%][3] \"%\" \n" theCurrentEditorIndex  theCurrentEditorIndex p[2] to:txt
							format "if obj != undefined do (\n appendIfUnique allNodes obj\n" to:txt
							format "MagmaFlowEditor_CurrentEditors[%][1].setNodeProperty MagmaFlowEditor_CurrentEditors[%][3] \"%\" allNodes\n"  theCurrentEditorIndex  theCurrentEditorIndex p[2] to:txt
							format "updateNodesList()) )\n" to:txt							
							hasControls = true
						)
						else if matchPattern p[4] pattern:"node" then
						(
							local theNameString = "Pick Scene Object..."
							case (magma.getNodeType ID) as name of
							(
								default: (
									format "fn pickObjectFilter obj = ( true ) \n" to:txt
								)
								#InputGeometry: 
								(
									format "fn pickObjectFilter obj = ( findItem GeometryClass.classes (classof obj) > 0 and classof obj != targetObject and  findItem #(PF_Source,PRT_Volume,PRT_FumeFX,KrakatoaPRTLoader,PRT_Source,PRT_Maker,PRT_Hair,PRT_Surface,PRT_Field,Stoke,Stoke_Field,StokeFieldLoader,StokeFieldSIM,PHXSimulator) (classof obj.baseobject) == 0 )\n" to:txt
									theNameString = "Pick Geometry Object..."
								)
								#InputParticles: 
								(
									--FIXME: (findItem ::MagmaFlowEditor_GlobalPickFilterArray% obj) AND...
									format "fn pickObjectFilter obj = ( findItem #(PF_Source,PRT_Volume,PRT_FumeFX,KrakatoaPRTLoader,PRT_Source,PRT_Maker,PRT_Hair,PRT_Surface,PRT_Field,Stoke,PHXSimulator) (classof obj.baseobject) > 0 )\n" id to:txt
									theNameString = "Pick Particle Object..."
								)
								/*#InputField:
								(
									global Ember_Object_Filter = MagmaFlowEditor_Functions.getEmberObject magma
									format "fn pickObjectFilter obj = ( ::Ember_Object_Filter != obj AND findItem (join SpaceWarpObject.classes #(Stoke_Field,StokeFieldLoader,StokeFieldSIM,FumeFX)) (classof obj.baseobject) > 0 )\n" to:txt
									theNameString = "Pick Field Object..."									
								)*/
							)
							local theName = if isValidNode p[3] then p[3].name else theNameString
							--format "label lbl_% \"%:\" align:#left \n" cnt displayName to:txt
							if findItem #(#InputGeometry, #InputParticles, #InputObject) ((magma.getNodeType id) as name) > 0 do
							(
								format "checkbox chk_exposed \"Expose\" align:#left offset:[-10,-3] checked:% across:2\n" (magma.getNodeProperty id "Exposed" == true) to:txt
								format "checkbox chk_exposedInBLOP \"Expose in BLOP\" align:#right offset:[10,-3] checked:% visible:%\n" (magma.getNodeProperty id "ExposedInBLOP" == true) (MagmaFlowSettings.NumEditingBLOPs > 0) to:txt
								
								format "on chk_exposed changed state do	( \n" to:txt
								format "local theMod = MagmaFlowEditor_CurrentEditors[%][1] \n" theCurrentEditorIndex to:txt
								format "theMod.DeclareExtensionProperty MagmaFlowEditor_CurrentEditors[%][3] \"Exposed\" \n" theCurrentEditorIndex to:txt
								format "theMod.setNodeProperty MagmaFlowEditor_CurrentEditors[%][3] \"Exposed\" state \n" theCurrentEditorIndex to:txt
								format "MagmaFlowEditor_CurrentEditors[%][2].exposeControlsToModifier() \n" theCurrentEditorIndex to:txt
								format "MagmaFlowEditor_CurrentEditors[%][2].createNodeTree init:false \n" theCurrentEditorIndex to:txt
								format "MagmaFlowEditor_CurrentEditors[%][2].createUndoRecord (if state then \"Exposed Control\" else \"Unexposed Control\")) \n" theCurrentEditorIndex to:txt

								format "on chk_exposedInBLOP changed state do	( \n" to:txt
								format "local theMod = MagmaFlowEditor_CurrentEditors[%][1] \n" theCurrentEditorIndex to:txt
								format "theMod.DeclareExtensionProperty MagmaFlowEditor_CurrentEditors[%][3] \"ExposedInBLOP\" \n" theCurrentEditorIndex to:txt
								format "theMod.setNodeProperty MagmaFlowEditor_CurrentEditors[%][3] \"ExposedInBLOP\" state \n" theCurrentEditorIndex to:txt
								format ")\n" theCurrentEditorIndex to:txt
							)
							
							format "pickbutton pck_node% \"%\" width:162 align:#center tooltip:\"%\" filter:pickObjectFilter\n" cnt theName theName  to:txt
							format "on pck_node% picked obj do (\n" cnt to:txt
							format "if classof obj == PF_Source do (obj = MagmaFlowEditor_CurrentEditors[%][2].getEventFromPFSource obj) \n" theCurrentEditorIndex to:txt
							format "if isValidNode obj do (\n" to:txt
							format "pck_node%.caption = obj.name\n" cnt to:txt
							format "pck_node%.tooltip = obj.name\n" cnt to:txt
							format "MagmaFlowEditor_CurrentEditors[%][1].setNodeProperty MagmaFlowEditor_CurrentEditors[%][3] \"%\" obj\n"  theCurrentEditorIndex  theCurrentEditorIndex p[2] to:txt
							format "MagmaFlowEditor_CurrentEditors[%][2].createNodeTree init:true\n" theCurrentEditorIndex  to:txt 
							format "try(modPanel.setCurrentObject (modPanel.getCurrentObject()))catch()\n" to:txt 	
							format "))\n" to:txt
							hasControls = true
							
							if ((magma.getNodeType id) as name) == #InputObject do
							(
								format "button btn_createPropertyQuery \"Add PropertyQuery\" width:162 align:#center \n" to:txt
								format "on btn_createPropertyQuery pressed do MagmaFlowEditor_CurrentEditors[%][2].insertNodeIntoFlow \"PropertyQuery\" \n" theCurrentEditorIndex to:txt
							)
						)
						else 
						(
							if matchPattern p[4] pattern:"int" do
							(
								format "spinner spn_% \"%:\" type:#integer fieldwidth:50 range:[0,100,%] \n" cnt displayName p[3] to:txt
								format "on spn_% changed val do ( MagmaFlowEditor_CurrentEditors[%][1].setNodeProperty MagmaFlowEditor_CurrentEditors[%][3] \"%\" val \n" cnt theCurrentEditorIndex  theCurrentEditorIndex p[2] to:txt
								if isExposedNoiseControl do
								(
									format "try(modPanel.setCurrentObject (modPanel.getCurrentObject()))catch()\n" to:txt
								)
								format "\n)\n" to:txt
								hasControls = true
							)
							if matchPattern p[4] pattern:"float" do
							(
								format "spinner spn_% \"%:\" type:#float fieldwidth:50 range:[-100000,100000,%] \n" cnt displayName p[3] to:txt
								format "on spn_% changed val do ( MagmaFlowEditor_CurrentEditors[%][1].setNodeProperty MagmaFlowEditor_CurrentEditors[%][3] \"%\" val \n" cnt theCurrentEditorIndex  theCurrentEditorIndex p[2] to:txt
								if isExposedNoiseControl do
								(
									format "try(modPanel.setCurrentObject (modPanel.getCurrentObject()))catch()\n" to:txt
								)
								format "\n)\n" to:txt
								
								hasControls = true
							)		
							if matchPattern p[4] pattern:"vector" do
							(
								--format "spinner spn_% \"%:\" type:#float fieldwidth:50 range:[1,100,%] \n" cnt p[2] p[3] to:txt
								--format "on spn_% changed val do MagmaFlowEditor_CurrentEditors[%][1].setNodeProperty MagmaFlowEditor_CurrentEditors[%][3] \"%\" val \n" cnt theCurrentEditorIndex  theCurrentEditorIndex p[2] to:txt
							)		
							if matchPattern p[4] pattern:"bool" do
							(
								format "checkbutton chk_% \">%\" checked:% width:150 align:#center \n" cnt displayName p[3]  to:txt
								format "on chk_% changed val do ( \n" cnt to:txt
								format "MagmaFlowEditor_CurrentEditors[%][1].setNodeProperty MagmaFlowEditor_CurrentEditors[%][3] \"%\" val \n" theCurrentEditorIndex  theCurrentEditorIndex p[2] to:txt
								format "MagmaFlowEditor_CurrentEditors[%][2].createNodeTree init:true\n" theCurrentEditorIndex  to:txt 
								if isExposedNoiseControl do
								(
									format "try(modPanel.setCurrentObject (modPanel.getCurrentObject()))catch()\n" to:txt
								)
								format ")\n" to:txt
							)								
						)
					)
				)

				if findItem #(#NearestParticle) ((magma.GetNodeType ID) as name) > 0 then
				(
					format "button btn_addParticleQuery \"Add Particle Query\" width:160 offset:[0,-3] align:#center tooltip:\"Creates a ParticleQuery Operator to access Channel Data from the specified Particle.\" \n" to:txt
					format "on btn_addParticleQuery pressed do MagmaFlowEditor_CurrentEditors[%][2].insertParticleQuery()\n" theCurrentEditorIndex to:txt
					hasControls = true
				)				
				
				if magma.getNodeType ID == "Mux" do
				(
					format "spinner spn_muxcount \"Number Inputs:\" type:#integer fieldwidth:50 range:[3,1000,%] \n" (magma.getNumNodeInputs ID) to:txt
					format "on spn_muxcount changed val do (\n" to:txt
					format "local oldControl = MagmaFlowEditor_CurrentEditors[%][1].getNodeInput MagmaFlowEditor_CurrentEditors[%][3] (MagmaFlowEditor_CurrentEditors[%][1].getNumNodeInputs MagmaFlowEditor_CurrentEditors[%][3]) \n" theCurrentEditorIndex theCurrentEditorIndex theCurrentEditorIndex theCurrentEditorIndex to:txt 
					format "MagmaFlowEditor_CurrentEditors[%][1].setNodeInput MagmaFlowEditor_CurrentEditors[%][3] (MagmaFlowEditor_CurrentEditors[%][1].getNumNodeInputs MagmaFlowEditor_CurrentEditors[%][3]) -1 1\n" theCurrentEditorIndex theCurrentEditorIndex theCurrentEditorIndex theCurrentEditorIndex to:txt 
					format "MagmaFlowEditor_CurrentEditors[%][1].setNumNodeInputs MagmaFlowEditor_CurrentEditors[%][3] val \n" theCurrentEditorIndex  theCurrentEditorIndex to:txt
					format "MagmaFlowEditor_CurrentEditors[%][1].setNodeInput MagmaFlowEditor_CurrentEditors[%][3] val oldControl[1] oldControl[2]\n" theCurrentEditorIndex theCurrentEditorIndex to:txt 
					format "MagmaFlowEditor_CurrentEditors[%][2].updateNavigator()\n" theCurrentEditorIndex  to:txt 
					format "MagmaFlowEditor_CurrentEditors[%][2].createNodeTree init:true)\n" theCurrentEditorIndex  to:txt 
					hasControls = true
				)
				
				local theVals = for i = 1 to magma.getNumNodeInputs ID where (val = magma.getNodeInputDefaultValue ID i) != undefined and (magma.getNodeInput ID i)[1] < 0 collect i
				
				if theVals.count > 0 do
				(
					hasControls = true
					local theValueClassOverride = magma.getNodeProperty ID "DefaultsType" 
					
					if theValueClassOverride != undefined then
						theValueClassOverride  = theValueClassOverride  as name
					else 
					(
						if findItem #("TransformByQuat", "VectorsToQuat","ToVector", "Blend","Clamp","FaceQuery","MeshQuery","ParticleSumCount","ParticleSumRadius","MatrixMulVec", "PropertyQuery", "FromSpace", "ToSpace") (magma.getNodeType ID) == 0 do --,"Greater","Less","GreaterOrEqual","LessOrEqual"
						(
							theValueClassOverride = ((classof ( magma.getNodeInputDefaultValue ID theVals[1])) as string) as name
							--format "theValueClassOverride = %\n" theValueClassOverride
						)
					)
					if findItem #("VertexQuery","TexmapEval","ElementQuery","NearestPoint","IntersectRay","Noise","VecNoise") (magma.getNodeType ID) > 0 do theValueClassOverride = undefined
					
					if theValueClassOverride == #point3 do theValueClassOverride = #Vector
					format "group \"Input Defaults\"(\n" to:txt
					if theValueClassOverride != undefined do
					(
						format "label lbl_defaultType \"Value Type:\" align:#left across:2\n" to:txt
						format "dropdownlist ddl_defaultType items:#(\"Integer\",\"Float\",\"Vector\") width:80 align:#right offset:[0,-3] selection:%\n" (findItem #(#Integer,#Float,#Vector) theValueClassOverride) to:txt
						format "on ddl_defaultType selected itm do (\n" to:txt
						format "MagmaFlowEditor_CurrentEditors[%][1].DeclareExtensionProperty MagmaFlowEditor_CurrentEditors[%][3] \"DefaultsType\"\n"  theCurrentEditorIndex  theCurrentEditorIndex to:txt
						format "MagmaFlowEditor_CurrentEditors[%][1].setNodeProperty MagmaFlowEditor_CurrentEditors[%][3] \"DefaultsType\" ddl_defaultType.selected\n"  theCurrentEditorIndex  theCurrentEditorIndex to:txt
						format "MagmaFlowEditor_CurrentEditors[%][2].displaySelectedNodeProperties()\n" theCurrentEditorIndex  to:txt 
						format "MagmaFlowEditor_CurrentEditors[%][2].updateMagmaHolder()\n" theCurrentEditorIndex  to:txt
						format "MagmaFlowEditor_CurrentEditors[%][2].updateNavigator fullUpdate:true\n" theCurrentEditorIndex  to:txt
						format "MagmaFlowEditor_CurrentEditors[%][2].createNodeTree init:true\n" theCurrentEditorIndex  to:txt 
						format ")\n" to:txt
					)
					
					for i = 1 to magma.getNumNodeInputs ID where (val = magma.getNodeInputDefaultValue ID i) != undefined do
					(
						local isConnected = (magma.getNodeInput ID i)[1] > -1 
						if not isConnected do
						(
							local theValueClass = ((classof val) as string) as name
							if theValueClassOverride != undefined do
							(
								theValueClassOverride = theValueClassOverride as name
								if (theValueClass == #Float or  theValueClass == #Integer) and theValueClassOverride == #Vector then
								(
									val = [val,val,val]
									magma.SetNodeInputDefaultValue ID i val 
								)
								else if (theValueClass == #Vector or theValueClass == #Point3) and (theValueClassOverride == #Float or theValueClassOverride == #Integer) then
								(
									val = val.x
									magma.SetNodeInputDefaultValue ID i val 
								)
								else if (theValueClass == #Integer) and (theValueClassOverride == #Float) do
								(
									val = val * 1.0
									magma.SetNodeInputDefaultValue ID i val 				
								)
								
								if theValueClassOverride == #Integer do
								(
									val = (floor (val +0.5)) as integer
									magma.SetNodeInputDefaultValue ID i val 
								)
								
								theValueClass = theValueClassOverride
							)
							if theValueClass == #Float then
								(
									local theName = magma.GetNodeInputDescription ID i
									if theName == undefined do theName = "Input"									
									format "spinner spn_default% \"%:%:\" type:#float fieldwidth:45 range:[-100000000,100000000,%] \n" i  i theName val to:txt
									format "on spn_default% changed val do (\n" i to:txt
									format "MagmaFlowEditor_CurrentEditors[%][1].SetNodeInputDefaultValue MagmaFlowEditor_CurrentEditors[%][3] % val\n"  theCurrentEditorIndex  theCurrentEditorIndex i to:txt
									format "MagmaFlowEditor_CurrentEditors[%][2].updateMagmaHolder()\n" theCurrentEditorIndex to:txt
									format ")\n" to:txt
								)
								else if theValueClass == #Integer then
								(
									if findItem #("NearestPoint","IntersectRay") (magma.getNodeType ID) > 0 then
									(
										local theName = magma.GetNodeInputDescription ID i
										format "checkbutton chk_default% \"%: >%\" width:150 checked:(%!=0) \n" i  i theName val to:txt
										format "on chk_default% changed val do (\n" i to:txt
										format "MagmaFlowEditor_CurrentEditors[%][1].SetNodeInputDefaultValue MagmaFlowEditor_CurrentEditors[%][3] % (if val then 1 else 0)\n"  theCurrentEditorIndex  theCurrentEditorIndex i to:txt
										format "MagmaFlowEditor_CurrentEditors[%][2].updateMagmaHolder()\n" theCurrentEditorIndex to:txt
										format ")\n" to:txt									
									)
									else
									(
										local theName = magma.GetNodeInputDescription ID i
										if theName == undefined do theName = "Input"									
										format "spinner spn_default% \"%:%:\" type:#integer fieldwidth:45 range:[-100000000,100000000,%] \n" i  i theName val to:txt
										format "on spn_default% changed val do (\n" i to:txt
										format "MagmaFlowEditor_CurrentEditors[%][1].SetNodeInputDefaultValue MagmaFlowEditor_CurrentEditors[%][3] % val\n"  theCurrentEditorIndex  theCurrentEditorIndex i to:txt
										format "MagmaFlowEditor_CurrentEditors[%][2].updateMagmaHolder()\n" theCurrentEditorIndex to:txt
										format ")\n" to:txt									
									)
								)
								else if theValueClass == #Vector or theValueClass == #Point3 or theValueClass == #Quat do
								(
									local theSocketName = magma.GetNodeInputDescription ID i
									local theNameString = "X"
									if matchPattern theSocketName pattern:"*Color*" do theNameString = "R"
									if matchPattern theSocketName pattern:"*Texture*" do theNameString = "U"
										
									format "groupbox grp_box% \"% : %:\" align:#center width:150 height:% \n" i i theSocketName (if theValueClass == #Quat then 100 else 70) to:txt									
									format "spinner spn_default%X \"%:\" type:#float fieldwidth:50 range:[-100000000,100000000,%] offset:[0,-%] \n" i theNameString val.x (if theValueClass == #Quat then 90 else 60) to:txt
									format "on spn_default%X changed val do (\n" i to:txt
									format "local oldVal = MagmaFlowEditor_CurrentEditors[%][1].GetNodeInputDefaultValue MagmaFlowEditor_CurrentEditors[%][3] %\n"  theCurrentEditorIndex  theCurrentEditorIndex i to:txt
									if theValueClass == #Quat then
										format "MagmaFlowEditor_CurrentEditors[%][1].SetNodeInputDefaultValue MagmaFlowEditor_CurrentEditors[%][3] % (Quat val oldVal.y oldVal.z oldVal.w)\n"  theCurrentEditorIndex  theCurrentEditorIndex i to:txt
									else
										format "MagmaFlowEditor_CurrentEditors[%][1].SetNodeInputDefaultValue MagmaFlowEditor_CurrentEditors[%][3] % [val, oldVal.y, oldVal.z]\n"  theCurrentEditorIndex  theCurrentEditorIndex i to:txt
									format "MagmaFlowEditor_CurrentEditors[%][2].updateMagmaHolder()\n" theCurrentEditorIndex to:txt
									format ")\n" to:txt
									
									local theNameString = "Y"
									if matchPattern theSocketName pattern:"*Color*" do theNameString = "G"
									if matchPattern theSocketName pattern:"*Texture*" do theNameString = "V"
									
									format "spinner spn_default%Y \"%:\" type:#float fieldwidth:50 range:[-100000000,100000000,%] offset:[0,-3]\n" i theNameString val.y to:txt
									format "on spn_default%Y changed val do (\n" i to:txt
									format "local oldVal = MagmaFlowEditor_CurrentEditors[%][1].GetNodeInputDefaultValue MagmaFlowEditor_CurrentEditors[%][3] %\n"  theCurrentEditorIndex  theCurrentEditorIndex i to:txt
									if theValueClass == #Quat then
										format "MagmaFlowEditor_CurrentEditors[%][1].SetNodeInputDefaultValue MagmaFlowEditor_CurrentEditors[%][3] % (Quat oldVal.x val oldVal.z oldVal.w)\n"  theCurrentEditorIndex  theCurrentEditorIndex i to:txt
									else
										format "MagmaFlowEditor_CurrentEditors[%][1].SetNodeInputDefaultValue MagmaFlowEditor_CurrentEditors[%][3] % [oldVal.x, val, oldVal.z]\n"  theCurrentEditorIndex  theCurrentEditorIndex i to:txt
									format "MagmaFlowEditor_CurrentEditors[%][2].updateMagmaHolder()\n" theCurrentEditorIndex to:txt
									format ")\n" to:txt
									
									local theNameString = "Z"
									if matchPattern theSocketName pattern:"*Color*" do theNameString = "B"
									if matchPattern theSocketName pattern:"*Texture*" do theNameString = "W"
									
									format "spinner spn_default%Z \"%:\" type:#float fieldwidth:50 range:[-100000000,100000000,%] offset:[0,-3]\n" i theNameString val.z to:txt
									format "on spn_default%Z changed val do (\n" i to:txt
									format "local oldVal = MagmaFlowEditor_CurrentEditors[%][1].GetNodeInputDefaultValue MagmaFlowEditor_CurrentEditors[%][3] %\n"  theCurrentEditorIndex  theCurrentEditorIndex i to:txt
									if theValueClass == #Quat then
										format "MagmaFlowEditor_CurrentEditors[%][1].SetNodeInputDefaultValue MagmaFlowEditor_CurrentEditors[%][3] % (Quat oldVal.x oldVal.y val oldVal.w)\n"  theCurrentEditorIndex  theCurrentEditorIndex i to:txt
									else
										format "MagmaFlowEditor_CurrentEditors[%][1].SetNodeInputDefaultValue MagmaFlowEditor_CurrentEditors[%][3] % [oldVal.x, oldVal.y, val]\n"  theCurrentEditorIndex  theCurrentEditorIndex i to:txt
									format "MagmaFlowEditor_CurrentEditors[%][2].updateMagmaHolder()\n" theCurrentEditorIndex to:txt
									format ")\n" to:txt
									
									if theValueClass == #Quat do
									(
										local theNameString = "W"
										format "spinner spn_default%W \"%:\" type:#float fieldwidth:50 range:[-100000000,100000000,%] offset:[0,-3]\n" i theNameString val.w to:txt
										format "on spn_default%W changed val do (\n" i to:txt
										format "local oldVal = MagmaFlowEditor_CurrentEditors[%][1].GetNodeInputDefaultValue MagmaFlowEditor_CurrentEditors[%][3] %\n"  theCurrentEditorIndex  theCurrentEditorIndex i to:txt
										format "MagmaFlowEditor_CurrentEditors[%][1].SetNodeInputDefaultValue MagmaFlowEditor_CurrentEditors[%][3] % (quat oldVal.x oldVal.y oldVal.z val)\n"  theCurrentEditorIndex  theCurrentEditorIndex i to:txt
										format "MagmaFlowEditor_CurrentEditors[%][2].updateMagmaHolder()\n" theCurrentEditorIndex to:txt
										format ")\n" to:txt
									)
								)
						
						)
					)
					format ")\n" to:txt
				)		
				if not hasControls do format "label lbl_nocontols \"No Controls Exposed\" \n" to:txt
				format ")\n" to:txt
				DynamicPropertiesRollout = copy (execute (txt as string))
			)
			else false
		)
		
		local MagmaFlowEditor_BLOP_ExposedNodes_Rollout
		
		fn updateNodePropertiesRollouts =
		(
			for aRollout in NodePropsSR.rollouts do
			(
				try(aRollout.updateControls())catch()
			)
		)		
		
		fn getBLOPExposedSubOperators theID =
		(
			magma.pushEditableBLOP theID
			local exposedNodeIDs = #()
			::Magma_tempController = #()
			local theCurrentEditorIndex = (for i = 1 to MagmaFlowEditor_CurrentEditors.count where MagmaFlowEditor_CurrentEditors[i][1] == magma collect i)[1]
			local txt = "" as stringstream
			format "rollout MagmaFlowEditor_BLOP_ExposedNodes_Rollout \"Exposed BLOP Parameters\" category:50\n(\n" to:txt
			format "fn updateMod =(\n" to:txt
			format "try(modPanel.setCurrentObject (modPanel.getCurrentObject()))catch()\n" to:txt
			format ")\n" to:txt
			
			local txt2 = "" as stringstream
			format "on MagmaFlowEditor_BLOP_ExposedNodes_Rollout open do\n(\n" to:txt2

			local txt3 = "" as stringstream
			format "fn updateControls = (\n" to:txt3
			format "theMod = ::MagmaFlowEditor_CurrentEditors[%][1]\n" theCurrentEditorIndex to:txt3
			
			for id in (sort (magma.GetNodes())) do
			(
				local isExposed = magma.getNodeProperty id "ExposedInBLOP"
				if isExposed == true do 
				(
					append exposedNodeIDs id
					local theType = try(magma.getNodeType id)catch("BLOPSocket")
					local opname = magma.getNodeProperty id "Name"
					if opname == undefined do opname = theType as string 
					case of
					(
						(theType as name == #InputValue): (
							tempController = magma.getNodeProperty id "controller"
							local tempControllerIsInteger = magma.getNodeProperty id "forceInteger"
							if classof tempController.value == Float and tempControllerIsInteger == false do 
							(
								append ::Magma_tempController tempController
								format "spinner spn_inputvaluefloat_% \"%: %:\" type:#float fieldwidth:50 range:[-1000000000,1000000000,0] align:#right offset:[7,0] controller:Magma_tempController[%] scale:0.01 \n" id id opname Magma_tempController.count to:txt  
							)
							if classof tempController.value == Float and tempControllerIsInteger == true do 
							(
								append ::Magma_tempController tempController
								format "spinner spn_inputvalueint_% \"%: %:\" type:#integer fieldwidth:50 range:[-1000000000,1000000000,0] align:#right offset:[7,0] controller:Magma_tempController[%] scale:0.01 \n" id id opname Magma_tempController Magma_tempController.count to:txt  
							)		
							if classof tempController.value == Point3 do 
							(
								
								append ::Magma_tempController tempController
								format "group \"%: %\"(\n" id opname to:txt
								format "spinner spn_inputvalue_vx_% \"X:\" type:#float fieldwidth:50 offset:[0,-3] range:[-1000000000.0,1000000000.0,0] align:#right controller:Magma_tempController[%][1].controller scale:0.01\n" id Magma_tempController.count to:txt   
								format "spinner spn_inputvalue_vy_% \"Y:\" type:#float fieldwidth:50 offset:[0,-3] range:[-1000000000.0,1000000000.0,0] align:#right controller:Magma_tempController[%][2].controller scale:0.01\n" id Magma_tempController.count to:txt   
								format "spinner spn_inputvalue_vz_% \"Z:\" type:#float fieldwidth:50 offset:[0,-3] range:[-1000000000.0,1000000000.0,0] align:#right controller:Magma_tempController[%][3].controller scale:0.01\n" id Magma_tempController.count to:txt   

								format  "colorpicker clr_inputvalue_vcolor_% \"\" align:#left offset:[-5,-56] height:50 width:48 alpha:true modal:true tooltip:\"%\" color:([%,%,%]*255) \n" id "" tempController.value.x tempController.value.y tempController.value.z to:txt
								format ")\n" to:txt
								
								format "fn update_inputValue_% = (\n" id to:txt
								format "clr_inputvalue_vcolor_%.color = [spn_inputvalue_vx_%.value, spn_inputvalue_vy_%.value ,spn_inputvalue_vz_%.value]*255 \n" id id id id to:txt
								format ")\n" to:txt

								format "on spn_inputvalue_vx_% changed val do update_inputValue_%()\n" id id to:txt
								format "on spn_inputvalue_vy_% changed val do update_inputValue_%()\n" id id to:txt
								format "on spn_inputvalue_vz_% changed val do update_inputValue_%()\n" id id to:txt

								format "on clr_inputvalue_vcolor_% changed val do(\n" id to:txt
								format "spn_inputvalue_vx_%.value = val.r/255.0\n" id to:txt
								format "spn_inputvalue_vy_%.value = val.g/255.0\n" id to:txt
								format "spn_inputvalue_vz_%.value = val.b/255.0\n)\n" id to:txt
								
								format "update_inputValue_%()\n" id to:txt3
								
								
							)
						)
						(theType as name == #Curve): (
							format "button btn_% \"Edit %:%...\" width:150 height:30 align:#center tooltip:\"%\"\n" id id opname theTooltip to:txt
							format "on btn_% pressed do (\n" id to:txt
							format "theMod = ::MagmaFlowEditor_CurrentEditors[%][1]\n" theCurrentEditorIndex to:txt
							format "local theID = %\n" id to:txt
							format "local theCI = theMod.getNodeProperty theId \"curve\" \n" to:txt
							format "local existingEditors = (for i in ::MagmaFlowEditor_CurrentCurveEditors where i[1] == theMod and i[2] == theID collect i) \n" to:txt
							format "if existingEditors.count == 0 then (\n theMod.declareExtensionProperty theID \"CurveEditorPosition\" \n" to:txt
							format "local thePos = theMod.getNodeProperty theID \"CurveEditorPosition\" \n" to:txt
							format "local CurveControlEditor =  fileIn (FranticParticles.KrakatoaHome + \"Scripts/Krakatoa_MagmaFlowCurveEditor.ms\") \n" to:txt
							format "if thePos == undefined then createDialog CurveControlEditor 480 500 else createDialog CurveControlEditor 480 500 thePos.x thePos.y \n" to:txt
							format "CurveControlEditor.title = \"Curve Editor - ID \" + theID as string + \": %\" \n" theName to:txt
							format "append ::MagmaFlowEditor_CurrentCurveEditors #(theMod, theID, CurveControlEditor, undefined) \n" to:txt
							format ")else setFocus (existingEditors[1][3])	\n" to:txt
							format ")\n" to:txt
						)				
						
						(theType as name == #InputParticles OR theType as name == #InputObject ): (
							local theNameString = "Pick Scene Object..."
							
							if theType as name == #InputParticles do
							(
								local theNode = (magma.getNodeProperty id "node")
								format "fn pickObjectFilter% obj = ((try(findItem ::MagmaFlowEditor_GlobalPickFilterArray% obj == 0)catch(true)) AND findItem #(PF_Source,PRT_Volume,PRT_FumeFX,KrakatoaPRTLoader,PRT_Source,PRT_Maker,PRT_Hair,PRT_Surface,PRT_Field,Stoke,PHXSimulator) (classof obj.baseobject) > 0 )\n" id id to:txt
								theNameString = "Pick Particle Object..."
							)
							if theType as name == #InputObject do
							(
								local theNode = (magma.getNodeProperty id "object")
								format "fn pickObjectFilter% obj = ( true ) \n" id to:txt
							)
							format "::MagmaFlowEditor_GlobalPickFilterArray% = refs.dependentNodes theMod \n" id  to:txt3 
							/*
							format "print \"BLOP ----------------------------------------\" \n" to:txt3
							format "print % \n" id to:txt3
							format "print (::MagmaFlowEditor_GlobalPickFilterArray% as string) \n" id to:txt3
							format "print \"--------------------------------------------\" \n" to:txt3
							*/
							
							local theName = if isValidNode theNode then theNode.name else theNameString
								
							format "group \"%: %\" (\n" id opname to:txt
							
							format "pickbutton pck_node% \"%\" width:152 align:#center tooltip:\"%\" filter:pickObjectFilter%\n" id theName theName  id to:txt
							format "on pck_node% picked obj do (\n" id to:txt
							format "if classof obj == PF_Source do (obj = MagmaFlowEditor_CurrentEditors[%][2].getEventFromPFSource obj) \n" theCurrentEditorIndex to:txt
							format "if isValidNode obj do (\n" to:txt
							format "pck_node%.caption = obj.name\n" id  to:txt
							format "pck_node%.tooltip = obj.name\n" id  to:txt
							
							format "theMod = ::MagmaFlowEditor_CurrentEditors[%][1]\n" theCurrentEditorIndex to:txt
							if theType as name == #inputObject then
							(
								format "theMod.setNodeProperty % \"object\" obj\n" id to:txt
								format "local obj = theMod.getNodeProperty % \"object\" \n" id to:txt3
							)
							else
							(
								format "theMod.setNodeProperty % \"node\" obj\n"  id to:txt
								format "local obj = theMod.getNodeProperty % \"node\" \n" id to:txt3
							)
							format "MagmaFlowEditor_CurrentEditors[%][2].createNodeTree init:true\n" theCurrentEditorIndex  to:txt 
							format "MagmaFlowEditor_CurrentEditors[%][2].updateNodePropertiesRollouts()\n" theCurrentEditorIndex to:txt
							format "updateMod()\n" to:txt
							format ")))\n" to:txt
							
							format "if isValidNode obj do (pck_node%.caption =  obj.name \n" id to:txt3
							format "appendIfUnique ::MagmaFlowEditor_GlobalPickFilterArray% obj )\n" id to:txt3
							
						)--end single object picker
						(theType as name == #InputGeometry): (
							
							format "fn pickObjectsFilter% obj = ((try(findItem ::MagmaFlowEditor_GlobalPickFilterArray% obj == 0)catch(true)) AND (findItem GeometryClass.classes (classof obj) > 0) AND (classof obj != targetObject) AND (findItem #(PF_Source,PRT_Volume,PRT_FumeFX,KrakatoaPRTLoader,PRT_Source,PRT_Maker,PRT_Hair,PRT_Surface,PRT_Field,Stoke,Stoke_Field,StokeFieldLoader,StokeFieldSIM,PHXSimulator) (classof obj.baseobject) == 0) )\n" id id to:txt
							theTooltip = "Get multiple Geometry Objects by name..."
							theTooltip2 = "Get one Geometry Object by clicking in the viewport..."
							
							theClassString = "nodes"
							theNameString = "Get by Name"
							theNameString2 = "Pick in Scene"							
							
							format "group \"%: %\" (\n" id opname to:txt
							format "button btn_node1_% \"%\" width:75 offset:[-7,-4] align:#left across:2 tooltip:\"%\" \n" id theNameString theTooltip to:txt
							format "pickbutton btn_node2_% \"%\" width:75 offset:[7,-4] align:#right tooltip:\"%\" filter:pickObjectsFilter%\n" id theNameString2 theTooltip2 id to:txt 
							
							format "multilistbox lbx_nodes% width:150 align:#center offset:[0,-4] \n" id to:txt 
							format "button btn_removenodes% \"Remove Objects\" width:150 align:#center offset:[0,-4] tooltip:\"Remove highlighted nodes from the input's list...\" \n" id  to:txt 
							format ")\n" to:txt 
							
							format "fn updateNodesList% = ( try(\n" id to:txt 
							format "local theMod = ::MagmaFlowEditor_CurrentEditors[%][1]\n" theCurrentEditorIndex to:txt
							format "local allNodes = theMod.getNodeProperty % \"nodes\" \n" id  to:txt 
							format "::MagmaFlowEditor_GlobalPickFilterArray% = allNodes \n" id  to:txt 
							format "lbx_nodes%.items =  for i in allNodes collect if isValidNode i then i.name else \"<deleted>\" \n"  id to:txt 
							format  ")catch())\n"  to:txt 
							
							format  "on btn_removenodes% pressed do (\n" id  to:txt 
							format  "local theMod = ::MagmaFlowEditor_CurrentMagmaHolder\n" to:txt 
							format  "local theNodes = theMod.getNodeProperty % \"nodes\" \n" id to:txt 
							format  "local theSel = lbx_nodes%.selection as array \n" id  to:txt 
							format  "for i = theSel.count to 1 by -1 do deleteItem theNodes theSel[i] \n"   to:txt 
							format  "theMod.setNodeProperty % \"nodes\" theNodes\n"  id   to:txt 
							format  "updateNodesList%()\n" id   to:txt 
							format  "updateMod()\n"   to:txt 
							format  ")\n"  to:txt 
							
							format  "updateNodesList%()\n" id  to:txt2 
							
							format  "on btn_node1_% pressed do (\n" id to:txt 
							format "local theMod = ::MagmaFlowEditor_CurrentEditors[%][1]\n" theCurrentEditorIndex to:txt
							format  "local allNodes = theMod.getNodeProperty % \"nodes\" \n" id to:txt   
							format "::MagmaFlowEditor_GlobalPickFilterArray% = allNodes \n"	id to:txt 			
							format  "local theNodes = selectByName title:\"%\" filter:pickObjectsFilter% showHidden:true single:false \n" theNameString id   to:txt 
							format  "if theNodes != undefined do (\nfor o in theNodes do appendIfUnique allNodes o\n"  to:txt 
							format  "theMod.setNodeProperty % \"nodes\" allNodes\n" id to:txt 
							format  "updateMod()\n" to:txt 
							format  "updateNodesList%()))\n" id to:txt 
							
							format  "on btn_node2_% picked obj do (\n" id  to:txt 
							format "local theMod = ::MagmaFlowEditor_CurrentEditors[%][1]\n" theCurrentEditorIndex to:txt
							format  "local allNodes = theMod.getNodeProperty % \"nodes\" \n" id to:txt     
							format "::MagmaFlowEditor_GlobalPickFilterArray% = allNodes \n"	id to:txt 			
							format  "if obj != undefined do (\nappendIfUnique allNodes obj\n"  to:txt 
							format  "theMod.setNodeProperty % \"nodes\" allNodes\n" id to:txt 
							format  "updateMod()\n"  to:txt 
							format  "updateNodesList%()))\n" id to:txt 
							
						)--end multi-object picker
					
					)--end case
				)--end if exposed
			)--end id loop
			
			format ")\n" to:txt2
			format ")\n" to:txt3

			format "%\n" (txt3 as string) to:txt
			format "%\n" (txt2 as string) to:txt
			format ")\n" to:txt
			--print (txt as string)
			magma.popEditableBLOP()				
			if exposedNodeIDs.count > 0 do MagmaFlowEditor_BLOP_ExposedNodes_Rollout = copy (execute (txt as string))
			exposedNodeIDs
		)
		
		
		fn displaySelectedNodeProperties =
		(
			local st = timestamp()
			--format "displaySelectedNodeProperties selectedNodeIndex:% editorNodeCount:% getSelectionCount:%\n" hc.selectedNodeIndex editorNodeCount hc.getSelectionCount
			--FranticParticles.LogDebug "MagamFlow: displaySelectedNodeProperties() Called."
			if hc.selectedNodeIndex > 0 and hc.selectedNodeIndex <= (editorNodeCount) and hc.getSelectionCount == 1 then --hc.getNodeCount 
			(
				lastNodeClick = hc.selectedNodeIndex 
				local theID = (Magma.GetNodes())[lastNodeClick]
				local theNameState = execute (getIniSetting (theIniFileLocation + "MagmaFlowEditor_Preferences.ini") "MagmaEditor" "NodeNameRolloutRolledup")
				if theNameState == OK do theNameState = false
				local theType = try(magma.getNodeType theID)catch("BLOPSocket")
				case of
				(
					(theType as name == #InputValue): 
					(
						for i = NodePropsSR.rollouts.count to 1 by -1 where NodePropsSR.rollouts[i] != MagmaFlowEditor_NodeNameRollout and NodePropsSR.rollouts[i] != MagmaFlowEditor_OperatorRollout and NodePropsSR.rollouts[i]  != MagmaFlowEditor_OptionsRollout do  --and NodePropsSR.rollouts[i]  != MagmaFlowEditor_FilePresetsRollout 
							removeSubRollout NodePropsSR NodePropsSR.rollouts[i]
						
						local tempController = magma.getNodeProperty theID "controller"
						local tempControllerIsInteger = magma.getNodeProperty theID "forceInteger"
						
						if classof tempController.value == Float and tempControllerIsInteger == false do 
						(
							CurrentFloatController  = tempController
							CurrentIntController = bezier_float()
							CurrentVectorController = point3_xyz()
						)
						if classof tempController.value == Float and tempControllerIsInteger == true do 
						(
							CurrentFloatController  = bezier_float()
							CurrentIntController = tempController 
							CurrentVectorController = point3_xyz()
						)
						if classof tempController.value == Point3 do 
						(
							CurrentFloatController  = bezier_float()
							CurrentIntController =  bezier_float()
							if classof tempController == point3_xyz then
								CurrentVectorController = tempController 
							else 
								CurrentVectorController = Point3_xyz()
						)
						
						MagmaFlowEditor_isInitializing = true
						--createDynamicPropertiesRollout theID
						addSubRollout NodePropsSR MagmaFlowEditor_NodeNameRollout rolledup:(not theNameState)
						MagmaFlowEditor_NodeNameRollout.RolloutOpen()
						addSubRollout NodePropsSR MagmaFlowEditor_OperatorRollout rolledup:false
						MagmaFlowEditor_OperatorRollout.RolloutOpen()
						addSubRollout NodePropsSR MagmaFlowEditor_InputValueRollout rolledup:false
						MagmaFlowEditor_InputValueRollout.RolloutOpen()

						MagmaFlowEditor_isInitializing = false
					)
					(theType as name == #InputChannel OR theType as name == #LoopChannel):
					(
						MagmaFlowEditor_isInitializing = true
						for i = NodePropsSR.rollouts.count to 1 by -1 where NodePropsSR.rollouts[i] != MagmaFlowEditor_NodeNameRollout and NodePropsSR.rollouts[i] != MagmaFlowEditor_OperatorRollout and NodePropsSR.rollouts[i]  != MagmaFlowEditor_OptionsRollout   do 
							removeSubRollout NodePropsSR NodePropsSR.rollouts[i]
						
						addSubRollout NodePropsSR MagmaFlowEditor_NodeNameRollout rolledup:(not theNameState)
						MagmaFlowEditor_NodeNameRollout.RolloutOpen()
						addSubRollout NodePropsSR MagmaFlowEditor_OperatorRollout rolledup:false
						MagmaFlowEditor_OperatorRollout.RolloutOpen()
						addSubRollout NodePropsSR MagmaFlowEditor_InputChannelRollout rolledup:false
						MagmaFlowEditor_InputChannelRollout.RolloutOpen()
						
						MagmaFlowEditor_isInitializing = false
					)
					(theType as name == #BLOPSocket): ()
					(theType as name == #BLOPOutput): ()
					
					default: 
					(
						MagmaFlowEditor_isInitializing = true
						for i = NodePropsSR.rollouts.count to 1 by -1 where NodePropsSR.rollouts[i] != MagmaFlowEditor_NodeNameRollout and NodePropsSR.rollouts[i] != MagmaFlowEditor_OperatorRollout and NodePropsSR.rollouts[i]  != MagmaFlowEditor_OptionsRollout  do 
							removeSubRollout NodePropsSR NodePropsSR.rollouts[i]
						
						addSubRollout NodePropsSR MagmaFlowEditor_NodeNameRollout rolledup:(not theNameState)
						MagmaFlowEditor_NodeNameRollout.RolloutOpen()
						addSubRollout NodePropsSR MagmaFlowEditor_OperatorRollout rolledup:false
						MagmaFlowEditor_OperatorRollout.RolloutOpen()
						createDynamicPropertiesRollout theID
						addSubRollout NodePropsSR DynamicPropertiesRollout rolledup:false
						MagmaFlowEditor_isInitializing = false
					)	
					(magma.isNodeContainer theID):
					(
						MagmaFlowEditor_isInitializing = true
						for i = NodePropsSR.rollouts.count to 1 by -1 where NodePropsSR.rollouts[i] != MagmaFlowEditor_NodeNameRollout and NodePropsSR.rollouts[i] != MagmaFlowEditor_EditableBLOP and NodePropsSR.rollouts[i]  != MagmaFlowEditor_OptionsRollout do 
							removeSubRollout NodePropsSR NodePropsSR.rollouts[i]
						
						addSubRollout NodePropsSR MagmaFlowEditor_NodeNameRollout rolledup:(not theNameState)
						MagmaFlowEditor_NodeNameRollout.RolloutOpen()
						
						case (magma.getNodeProperty theID "uiType") as name of
						(
							#BLOP: (
								addSubRollout NodePropsSR MagmaFlowEditor_EditableBLOP rolledup:false
								MagmaFlowEditor_EditableBLOP.RolloutOpen()
								local exposed_nodes = getBLOPExposedSubOperators theID
								if exposed_nodes.count > 0 do 
									addSubRollout NodePropsSR MagmaFlowEditor_BLOP_ExposedNodes_Rollout rolledup:false
							)
							#Loop: (
								addSubRollout NodePropsSR MagmaFlowEditor_LOOP rolledup:false
								MagmaFlowEditor_LOOP.RolloutOpen()
							)
						)
						MagmaFlowEditor_isInitializing = false
						updateNodePropertiesRollouts()
					)
					
					(theType as name == #Output): 
					(
						for i = NodePropsSR.rollouts.count to 1 by -1 where NodePropsSR.rollouts[i] != MagmaFlowEditor_OutputRollout and NodePropsSR.rollouts[i]  != MagmaFlowEditor_OptionsRollout do 
							removeSubRollout NodePropsSR NodePropsSR.rollouts[i]
						
						addSubRollout NodePropsSR MagmaFlowEditor_OutputRollout rolledup:false
						MagmaFlowEditor_OutputRollout.RolloutOpen()
					)				
				)
			)		
			else
			(
				for i = NodePropsSR.rollouts.count to 1 by -1 do 
					removeSubRollout NodePropsSR NodePropsSR.rollouts[i]
				if EditableBlopStack.count == 0 do addSubRollout NodePropsSR MagmaFlowEditor_FilePresetsRollout rolledup:false
			)
			if EditableBlopStack.count > 0 then 
				addSubRollout NodePropsSR MagmaFlowEditor_CloseEditableBLOP
			else
				removeSubRollout NodePropsSR MagmaFlowEditor_CloseEditableBLOP

			addSubRollout NodePropsSR MagmaFlowEditor_OptionsRollout rolledup:true
			
			setFocus hc
			
			--FranticParticles.LogDebug ("MagamFlow: displaySelectedNodeProperties() Took "+ (timestamp()-st) as string + " ms.")

		)--end display selected properties fn 
		
		fn displayOptions =
		(
			for i = NodePropsSR.rollouts.count to 1 by -1 do 
				removeSubRollout NodePropsSR NodePropsSR.rollouts[i]
			addSubRollout NodePropsSR MagmaFlowEditor_OptionsRollout rolledup:false
		)

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--REORDER FLOW FUNCTIONS		
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

		fn stampChild theChild theParent =
		(
			local theChildOrderX = magma.getNodeProperty theChild "Internal_OrderX"
			local theParentOrderX = magma.getNodeProperty theParent "Internal_OrderX"
			local theChildOrderY = magma.getNodeProperty theChild "Internal_OrderY"
			local theParentOrderY = magma.getNodeProperty theParent "Internal_OrderY"
			if theChildOrderX != undefined and theChildOrderY != undefined and theParentOrderX != undefined and theParentOrderY != undefined do 
			(
				local theNewOrderX = theParentOrderX+1
				if theNewOrderX > theChildOrderX do 
					magma.setNodeProperty theChild "Internal_OrderX" theNewOrderX

				local theNewOrderY = theParentOrderY
					magma.setNodeProperty theChild "Internal_OrderY" theNewOrderY
				
				for c = 1 to magma.getNumNodeInputs theChild do
				(
					local theWire = magma.getNodeInput theChild c
					if theWire != undefined and theWire[1] > -1 do
					(
						stampChild theWire[1] theChild
					)
				)
			)
		)
		
		fn compareFN v1 v2 valArray: =
		(
			local v1i = valArray[v1]
			local v2i = valArray[v2]
			if v1i > v2i then 1 else -1
		)
 
		fn reorder_dot =
		(
			local nodeIDMapArray = #()
			local theOutputIndex = 0
			local maxPosY = 0
			local maxPosX = 0
			
			local nodeArray = magma.GetNodes()
			local nodeCount = nodeArray.count
			
			for theID in nodeArray do
			(
				magma.DeclareExtensionProperty theID "Internal_Position"
				magma.DeclareExtensionProperty theID "Internal_OrderX"
				magma.DeclareExtensionProperty theID "Internal_OrderY"
				magma.setNodeProperty theID "Internal_OrderX" 0
				magma.setNodeProperty theID "Internal_OrderY" 0
				append nodeIDMapArray theID
			)
			
			if magma.NumEditingBLOPs() > 0 then
			(
				local numBLOPOutputs = magma.GetNumNodeOutputs (magma.CurrentBLOP) 
				for i = 1 to numBLOPOutputs+1 do
				(
					theOutputIndex = i
					local theID = (magma.GetOutput i)[1]
					if theID > -1 do
					(
						magma.setNodeProperty theID "Internal_OrderX" 2
						magma.setNodeProperty theID "Internal_OrderY" i
						for j = 1 to magma.getNumNodeInputs theID do
						(
							local theWire = magma.getNodeInput theID j
							if theWire != undefined and theWire[1] > -1 do
							(
								stampChild theWire[1] theID
							)
						)--end j loop
					)--end if					
				)--end i loop
			)
			else 
			(
				for i = 1 to nodeCount do
				(
					local theID = nodeArray[i]
					if magma.getNodeType theID == "Output" do 
					(
						theOutputIndex +=1
						magma.setNodeProperty theID "Internal_OrderX" 1
						magma.setNodeProperty theID "Internal_OrderY" theOutputIndex
						local theWire = magma.getNodeInput theID 1
						if theWire != undefined and theWire[1] > -1 do
						(
							stampChild theWire[1] theID
						)
					)--end if output
				)--end i loop
			)
			
			--at this point, all nodes are stamped with internal order properties in X and Y
			--now we go and collect an array of arrays based on the internal order.
			local reorderLastLevelX = amax (for i in nodeArray collect (theVal = (magma.getNodeProperty i "Internal_OrderX"); if theVal != undefined then theVal else dontcollect) )
			if reorderLastLevelX == undefined do reorderLastLevelX = 0
			local theNodesArray = for i = 1 to reorderLastLevelX collect #()
			
			local currentYOffset = 0
			for i = 1 to nodeCount do --for every node in the current X level
			(
				local theID = nodeArray[i]
				if magma.getNodeType theID != "Output" then
				(
					local theOrderX = magma.getNodeProperty theID "Internal_OrderX"
					local theOrderY = magma.getNodeProperty theID "Internal_OrderY"
					if theOrderX > 0 do --if it is a connected one
					(
						if theNodesArray[theOrderX] == undefined do theNodesArray[theOrderX] = #()
						append theNodesArray[theOrderX] #(i, theID, theOrderX, theOrderY)
					)
				)
				else
				(
					thePos = [hc.width-(MagmaFlowSettings.NodeWidth+MagmaFlowSettings.NodeXSpace), currentYOffset]
					magma.setNodeProperty theID "Internal_Position" thePos						
					currentYOffset += 30+MagmaFlowSettings.NodeYSpace
				)
			)
			
			--now we have theNodesArray which contains sub-arrays with arrays containing the node index, ID, X and Y order
			--now we could compress any columns above 1 that have just one node in them by moving into the previous column
			if MagmaFlowSettings.AutoReorderPattern == #block or MagmaFlowSettings.AutoReorderPattern == #row do
			(
				local theBlockHeight = if MagmaFlowSettings.AutoReorderPattern == #row then 1 else MagmaFlowSettings.AutoReorderBlockHeight
				local i = 3
				while i <= theNodesArray.count do
				--for i = 3 to theNodesArray.count do --loop through each column above 2 and compress single node columns into the previous one
				(
					if theNodesArray[i].count == 1 and theNodesArray[i-1].count < theBlockHeight then 
					(
						local nodeToMove = theNodesArray[i][1]
						nodeToMove[3] = i-1
						append theNodesArray[i-1] nodeToMove
						deleteItem theNodesArray i
						--i += 1
					)
					else
						i+=1
				)				
				
				for i = 3 to theNodesArray.count do --loop through each column above 2 and sort the nodes vertically based on their connections to the previous column
				(
					local theIndexArray = for j = 1 to theNodesArray[i].count collect j
					local theRefArray = for j = 1 to theNodesArray[i].count collect
					(
						local theWire = (magmaFlowEditor_Functions.GetConnectedNodes magma theNodesArray[i][j][2])[1][1]
						if theWire == undefined then
							local theConnectedNodesBeforeIt = #()
						else
							local theConnectedNodesBeforeIt = for k = 1 to theNodesArray[i-1].count where theNodesArray[i-1][k][2] == theWire[1] collect theWire[2]
						if theConnectedNodesBeforeIt.count == 0 then 1000+theNodesArray[i][j][2] else theConnectedNodesBeforeIt[1]
					)
					qsort theIndexArray compareFN valArray:theRefArray
					theNodesArray[i] = for j in theIndexArray collect theNodesArray[i][j]
				)				
				
				local currentXOffset = hc.width - MagmaFlowSettings.NodeWidth - MagmaFlowSettings.NodeXSpace	
				
				for i = 1 to theNodesArray.count do
				(
					local currentYOffset = 0
					for j = 1 to theNodesArray[i].count do
					(
						local theID = theNodesArray[i][j][2]
						hc.activeNode =  theNodesArray[i][j][1]
						local theNodeSizeY = hc.nodeSize.y
						thePos = [currentXOffset, currentYOffset]
						currentYOffset += theNodeSizeY+MagmaFlowSettings.NodeYSpace
						if MagmaFlowSettings.showTextureMapSample and magma.getNodeProperty theID "texmap" != undefined do currentYOffset += hc.nodeSize.x
						if MagmaFlowSettings.showColorSwatchSample and (magma.getNodeType theID) as name== #InputValue and classof (magma.getNodeProperty theID "controller").value  == Point3 do currentYOffset += 20
						
						magma.setNodeProperty theID "Internal_Position" thePos
						if currentYOffset > maxPosY do maxPosY = currentYOffset 
					)
					if maxPosX > currentXOffset do maxPosX = currentXOffset
					currentXOffset -= MagmaFlowSettings.NodeWidth+MagmaFlowSettings.NodeXSpace
				)
				reorderLastLevelX = theNodesArray.count
			)
			if MagmaFlowSettings.AutoReorderPattern == #tail do
			(
				--process Output nodes first
				local currentYOffset = 0
				for j = 1 to theOutputIndex do
				(
					theUpNodes = theNodesArray[1]
					if theUpNodes != undefined do
					(
						for n in theUpNodes do
						(
							if n[4] == j do
							(
								thePos = [hc.width-n[3]*(MagmaFlowSettings.NodeWidth+MagmaFlowSettings.NodeXSpace), currentYOffset]
								magma.setNodeProperty n[2] "Internal_Position" thePos
								hc.activeNode = n[1]
								local theNodeSizeY = hc.nodeSize.y
								if MagmaFlowSettings.showTextureMapSample and magma.getNodeProperty n[2] "texmap" != undefined do theNodeSizeY += hc.nodeSize.x
								if MagmaFlowSettings.showColorSwatchSample and (magma.getNodeType n[2]) as name== #InputValue and classof (magma.getNodeProperty n[2] "controller").value  == Point3 do theNodeSizeY += 20
									
								currentYOffset += theNodeSizeY + MagmaFlowSettings.NodeYSpace						
								
								if currentYOffset > maxPosY do maxPosY = currentYOffset
								if thePos.x > maxPosX do maxPosX = thePos.x
								
							)
						)
						--currentYOffset += MagmaFlowSettings.NodeYSpace*4						
					)
				)					
				--First we process the column 2, directly connected to Outputs. Since an output has one input only, there is always one node per output!
				local currentYOffset = 0
				for j = 1 to theOutputIndex do
				(
					theUpNodes = theNodesArray[2]
					if theUpNodes != undefined do
					(
						for n in theUpNodes do
						(
							if n[4] == j do
							(
								thePos = [hc.width-n[3]*(MagmaFlowSettings.NodeWidth+MagmaFlowSettings.NodeXSpace), currentYOffset]
								magma.setNodeProperty n[2] "Internal_Position" thePos				
								hc.activeNode = n[1]
								local theNodeSizeY = hc.nodeSize.y
								if MagmaFlowSettings.showTextureMapSample and magma.getNodeProperty n[2] "texmap" != undefined do theNodeSizeY += hc.nodeSize.x
								if MagmaFlowSettings.showColorSwatchSample and (magma.getNodeType n[2]) as name== #InputValue and classof (magma.getNodeProperty n[2] "controller").value  == Point3 do theNodeSizeY += 20
									
								currentYOffset += theNodeSizeY + MagmaFlowSettings.NodeYSpace						
								
								if currentYOffset > maxPosY do maxPosY = currentYOffset
								if thePos.x > maxPosX do maxPosX = thePos.x
								
							)
						)
						--currentYOffset += MagmaFlowSettings.NodeYSpace*4						
					)
				)
			
				--Now we process one column at a time, relative to the previous one
				for i = 3 to theNodesArray.count do --loop through each column
				(
					local sortArray = #()
					for n in theNodesArray[i] do
					(
						local theSortFactors = #()
						theWires = (magmaFlowEditor_Functions.GetConnectedNodes magma n[2])
						theWires2 = #()
						for w in theWires do join theWires2 w
						for w in theWires2 where magma.getNodeProperty w[1] "Internal_OrderX" == (i-1) do --collect the wires going to the previous column
						(
							local thePos = (magma.getNodeProperty w[1] "Internal_Position").y
							local theOutCount = magma.getNumNodeOutputs w[1]
							local theNodeSizeY = hc.nodeSize.y
							local theTextureOffset = 0
							if MagmaFlowSettings.showTextureMapSample and magma.getNodeProperty w[1] "texmap" != undefined do theTextureOffset= MagmaFlowSettings.NodeWidth
							if MagmaFlowSettings.showColorSwatchSample and (magma.getNodeType w[1]) as name== #InputValue and classof (magma.getNodeProperty w[1] "controller").value  == Point3 do theTextureOffset = 20
								
							local theInSocketPos = 20+theTextureOffset+(theOutCount-1+w[2])*15
							append theSortFactors (thePos + theInSocketPos - 20 ) --collect the factor based on parent node Y and socket
						)
						append sortArray (amin theSortFactors) --collect the min. sort factor to represent the current node
					)
					local sortIndexArray = for k = 1 to theNodesArray[i].count collect k
					qsort sortIndexArray compareFN valArray:sortArray
					local currentYOffset = 0
					for k in sortIndexArray do
					(
						n = theNodesArray[i][k]
						local thePos = [hc.width-n[3]*(MagmaFlowSettings.NodeWidth+MagmaFlowSettings.NodeXSpace), currentYOffset]
						
						if thePos.y < sortArray[k] do 
						(
							currentYOffset += sortArray[k]-thePos.y
							thePos.y = sortArray[k]
						)
						magma.setNodeProperty n[2] "Internal_Position" thePos		
							
						hc.activeNode = n[1]
						local theNodeSizeY = hc.nodeSize.y
						if MagmaFlowSettings.showTextureMapSample and magma.getNodeProperty n[2] "texmap" != undefined do theNodeSizeY += hc.nodeSize.x
						if MagmaFlowSettings.showColorSwatchSample and (magma.getNodeType n[2]) as name== #InputValue and classof (magma.getNodeProperty n[2] "controller").value  == Point3 do theNodeSizeY += 20
							
						currentYOffset += theNodeSizeY + MagmaFlowSettings.NodeYSpace				
						if currentYOffset > maxPosY do maxPosY = currentYOffset
						if thePos.x > maxPosX do maxPosX = thePos.x
					)
				)
			)
			--Finally, process the unconnected nodes and put them on the far left side or bottom of the editor
			
			if MagmaFlowSettings.UnconnectedNodesPlacement == #bottom do
			(
				local currentYOffset = maxPosY --+ MagmaFlowSettings.NodeYSpace
				local currentXOffset = hc.width - MagmaFlowSettings.NodeWidth - MagmaFlowSettings.NodeXSpace	
				
				local nodeArray = magma.GetNodes()
				local nodeCount = nodeArray.count
				
				for i = nodeCount to 1 by -1 do
				(
					local theID = nodeArray[i]
					
					local theOrderX = magma.getNodeProperty theID "Internal_OrderX"
					if theOrderX == 0 do
					(
						thePos = [currentXOffset, currentYOffset]
						magma.setNodeProperty theID "Internal_Position" thePos
						hc.activeNode = i
						currentXOffset -= MagmaFlowSettings.NodeWidth + MagmaFlowSettings.NodeXSpace	
					)
				)
			)
			
			if MagmaFlowSettings.UnconnectedNodesPlacement == #left do
			(
				local currentYOffset = 0
				
				local nodeArray = magma.GetNodes()
				local nodeCount = nodeArray.count
				
				for i = 1 to nodeCount do
				(
					local theID = nodeArray[i]
					local theOrderX = magma.getNodeProperty theID "Internal_OrderX"
					if theOrderX == 0 do
					(
						thePos = [hc.width-(reorderLastLevelX+1)*(MagmaFlowSettings.NodeWidth+MagmaFlowSettings.NodeXSpace), currentYOffset]
						magma.setNodeProperty theID "Internal_Position" thePos
						hc.activeNode = i
						local theNodeSizeY = hc.nodeSize.y
						if MagmaFlowSettings.showTextureMapSample and magma.getNodeProperty theID "texmap" != undefined do theNodeSizeY += hc.nodeSize.x
						if MagmaFlowSettings.showColorSwatchSample and (magma.getNodeType theID) as name== #InputValue and classof (magma.getNodeProperty theID "controller").value  == Point3 do theNodeSizeY += 20
						currentYOffset += theNodeSizeY + MagmaFlowSettings.NodeYSpace	
					)
				)
			)
			createNodeTree init:true
		)
		
		fn autoReorderFlow update:true = 
		(
			local st = timestamp()
			if MagmaFlowSettings.AutoReorderToggle == true do 
			(
				reorder_dot()
			)
			--FranticParticles.LogDebug ("MagmaFlow: Reorder Flow Took "+((timestamp()-st)) as string + " ms." )
			if update do createNodeTree init:false
		)
		fn ReorderToggle = 
		(
			MagmaFlowSettings.AutoReorderToggle = not MagmaFlowSettings.AutoReorderToggle
			setIniSetting (theIniFileLocation + "MagmaFlowEditor_Preferences.ini") "AutoReorder" "Toggle" (MagmaFlowSettings.AutoReorderToggle as string)
			updateEditorTitle()
			autoReorderFlow()
			updateNavigator()			
		)
		
		fn AcceptReorderedFlow =
		(
			autoReorderFlow()
			local nodeArray = magma.GetNodes()
			local nodeCount = nodeArray.count
			
			for i = 1 to nodeCount do
			(
				local theID = nodeArray[i]
				local thePos = magma.getNodeProperty theID "Internal_Position"
				if thePos != undefined do magma.setNodeProperty theID "Position" thePos
			)
			createNodeTree init:false
			MagmaFlowSettings.autoReorderToggle = false
			updateEditorTitle()
			updateNavigator()	
		)
		
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--CONNECTIVITY COLLAPSE BRANCH FUNCTIONS		
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
		
		fn stampChildBranchCollapsed theChild theParent =
		(
			local parentState1 = magma.getNodeProperty theParent "Collapsed" == true
			local parentState2 = magma.getNodeProperty theParent "Internal_BranchCollapsed" == true
			magma.setNodeProperty theChild "Internal_BranchCollapsed" (parentState1 OR parentState2)
			for c = 1 to magma.getNumNodeInputs theChild do
			(
				local theWire = magma.getNodeInput theChild c
				if theWire != undefined and theWire[1] > -1 do
				(
					stampChildBranchCollapsed theWire[1] theChild
				)
			)
		)		
		
		fn stampChildBranchUncollapsed theChild =
		(
			magma.setNodeProperty theChild "Internal_BranchCollapsed" false
			for c = 1 to magma.getNumNodeInputs theChild do
			(
				local theWire = magma.getNodeInput theChild c
				if theWire != undefined and theWire[1] > -1 do
				(
					stampChildBranchUncollapsed theWire[1] 
				)
			)
		)
		
		fn CollapseBranches =
		(
			local nodeArray = magma.GetNodes()
			for theID in nodeArray do
			(
				magma.declareExtensionProperty theID "Internal_BranchCollapsed"
				magma.setNodeProperty theID "Internal_BranchCollapsed" false
			)
			if MagmaFlowSettings.AllowSubtreeCollapsing do
			(
				if magma.NumEditingBLOPs() > 0 then
				(
					local numBLOPOutputs = magma.GetNumNodeOutputs (magma.CurrentBLOP) 
					for i = 1 to numBLOPOutputs do
					(				
						local theConnection = magma.GetOutput i 
						local theConnectedID = theConnection[1] 
						if theConnectedID != undefined and theConnectedID > -1 do
						(
							try
							(
								for c = 1 to magma.getNumNodeInputs theConnectedID do
								(
									local theWire = magma.getNodeInput theConnectedID c
									if theWire != undefined and theWire[1] > -1 do
										stampChildBranchCollapsed theWire[1] theConnectedID
								)
							)catch()
						)
					)
				)
				else --top level			
				(
					for theID in nodeArray where magma.getNodeType theID == "Output" do
					(
						local theWire = magma.getNodeInput theID 1
						if theWire != undefined and theWire[1] > -1 do
							stampChildBranchCollapsed theWire[1] theID
					)
				)
				
				for theID in nodeArray where (magma.getNodeProperty theID "Internal_BranchCollapsed" == true) do
				(
					local parentLinks = MagmaFlowEditor_Functions.getConnectedNodes magma theID
					for c in parentLinks do
						for j in c do
							if magma.getNodeProperty j[1] "Internal_BranchCollapsed" != true and magma.getNodeProperty j[1] "Collapsed" != true  do 
								stampChildBranchUncollapsed theID
				)
			)
		)
		
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--VALUE TYPE FLOW FUNCTIONS		
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
		fn stampNodesByType =
		(
			local st = timestamp()
			local nodeArray = magma.GetNodes()
			local done = false
			
			for theID in nodeArray do --init. the node property with an array of all output sockets' types
			(	
				magma.declareExtensionProperty theID "Internal_OutputValueTypes"
				magma.setNodeProperty theID "Internal_OutputValueTypes" #()
			)
			local cnt = 0
			local lastCount = 0
			local theChannels = undefined
			local theFaceChannels = undefined
			
			while nodeArray.count > 0 and cnt < 10 and lastCount != nodeArray.count do
			(
				lastCount = nodeArray.count
				for  i = nodeArray.count to 1 by -1 do
				(	
					local theID  = nodeArray[i]
					local theTypeArray = magma.getNodeProperty theID "Internal_OutputValueTypes"
					local theNodeType = magma.getNodeType theID
					case of
					(
						(theNodeType as name == #FaceQuery):
						(
							if theFaceChannels == undefined do theFaceChannels = MagmaFlowEditor_Functions.loadChannelsList magma source:#genome iterationmode:#facevertex
							local theArray = #()
							if magma.getNodeProperty theID "exposePosition" do append theArray #vector
							local theExposedChannels = magma.getNodeProperty theID "channels"
							for j in theExposedChannels do
							(
								local theVal = (for c in theFaceChannels where c[1] == j collect c)[1]
								if theVal != undefined do
								(
									if matchPattern theVal[2] pattern:"int*" then
									(
										append theArray #float
									)
									else if matchPattern theVal[2] pattern:"float*" then
									(
										case theVal[3] of
										(
											default: append theArray #float
											3: append theArray #vector
											4: append theArray #quat
										)
									)
								)								
							)
							magma.setNodeProperty theID "Internal_OutputValueTypes" theArray
							deleteItem nodeArray i	
						)
						(theNodeType as name == #InputChannel):
						(
							if theChannels == undefined do theChannels = MagmaFlowEditor_Functions.loadChannelsList magma source:#genome 
							local theChannelName = magma.getNodeProperty theID "channelName"
							local theVal = (for c in theChannels where c[1] == theChannelName collect c)[1]
							if theVal != undefined do
							(
								if matchPattern theVal[2] pattern:"int*" then
								(
									magma.setNodeProperty theID "Internal_OutputValueTypes" #(#int)
									deleteItem nodeArray i											
								)
								else if matchPattern theVal[2] pattern:"float*" then
								(
									case theVal[3] of
									(
										default: magma.setNodeProperty theID "Internal_OutputValueTypes" #(#float)
										3: magma.setNodeProperty theID "Internal_OutputValueTypes" #(#vector)
										4: magma.setNodeProperty theID "Internal_OutputValueTypes" #(#quat)
									)
									deleteItem nodeArray i	
								)
							)
						)
						(theNodeType as name == #InputBoundBox): 
						(
							magma.setNodeProperty theID "Internal_OutputValueTypes" #(#float,#float,#vector)
							deleteItem nodeArray i
						)
						(theNodeType as name == #InputScript): 
						(
							local theType = case (classof (execute (magma.getNodeProperty theID "script"))) of
							(
								Float: #float
								Integert: #int
								Point3: #vector
								Quat: #quat
								default: undefined
							)
							
							magma.setNodeProperty theID "Internal_OutputValueTypes" #(theType)
							deleteItem nodeArray i
						)						
						(theNodeType as name == #InputValue): 
						(
							local theCtrl = magma.GetNodeProperty theID "controller"
							local theCtrlType = magma.getNodeProperty theID "forceInteger"
							local theType = #vector
							if classof theCtrl == Bezier_Float do theType = if theCtrlType == true then #int else #float
							magma.setNodeProperty theID "Internal_OutputValueTypes" #(theType)
							deleteItem nodeArray i
						)
						(findItem #(#Curve, #ToFloat) (theNodeType as name) > 0):
						(
							magma.setNodeProperty theID "Internal_OutputValueTypes" #(#float)
							deleteItem nodeArray i							
						)
						(findItem #(#ToWorld, #FromWorld, #ToSpace, #FromSpace) (theNodeType as name) > 0):
						(
							magma.setNodeProperty theID "Internal_OutputValueTypes" #(#vector)
							deleteItem nodeArray i							
						)						
						(findItem #(#ToInt) (theNodeType as name) > 0):
						(
							magma.setNodeProperty theID "Internal_OutputValueTypes" #(#int)
							deleteItem nodeArray i							
						)
						(findItem #(#CurrentMesh) (theNodeType as name) > 0):
						(
							magma.setNodeProperty theID "Internal_OutputValueTypes" #(#mesh)
							deleteItem nodeArray i							
						)						
						(theNodeType as name == #Breakout):
						(
							magma.setNodeProperty theID "Internal_OutputValueTypes" #(#float,#float,#float)
							deleteItem nodeArray i							
						)
						(findItem #(#Greater,#Less,#Equal,#NotEqual,#LogicalOr,#LogicalXOR,#LogicalNot,#LogicalAnd,#LessOrEqual,#GreaterOrEqual) (theNodeType as name) > 0 ):
						(
							magma.setNodeProperty theID "Internal_OutputValueTypes" #(#bool)
							deleteItem nodeArray i							
						)
						(theNodeType as name == #TexmapEval): 
						(
							local theTextureType = case (substring (magma.GetNodeProperty theID "resultType") 1 1) of
							(
								"M": #float
								default: #vector
							)
							magma.setNodeProperty theID "Internal_OutputValueTypes" #(theTextureType)
							deleteItem nodeArray i									
						)		
						(findItem #(#NearestPoint, #IntersectRay) (theNodeType as name) > 0): 						
						(
							magma.setNodeProperty theID "Internal_OutputValueTypes" #(#vector,#bool,#int,#int,#float,#vector,#vector)
							deleteItem nodeArray i								
						)
						--(findItem #(#Clamp, #Mux, #Add, #Subtract, #Multiply, #Divide) (theNodeType as name) > 0 ): 
						default: --by default, assume that the type of the first socket flows out the first output socket
						(
							local theFirstInput = (magma.getNodeInput theID 1)
							if theFirstInput[1] > -1 do
							(
								local theFirstInputType = (magma.getNodeProperty theFirstInput[1] "Internal_OutputValueTypes")[theFirstInput[2]]
								if theFirstInputType != undefined do
								(
									
									magma.setNodeProperty theID "Internal_OutputValueTypes" #(theFirstInputType)
									deleteItem nodeArray i									
								)
							)
						)
					)
				)--end i loop
				cnt+=1
			)--end while 
			format "stampNodesByType: % ms, %\n" (timestamp()-st) cnt
		)
		
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--PAN AND ZOOM FUNCTIONS		
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

		local bBoxSize, theBBoxCenter, theMin
		local navigatorBitmapBlank
		local navigatorBitmapBackground
		local navigatorBitmapForeground
		
		local theGamma = 1.0
		fn initNavigator =
		(
			theGamma = if IDisplayGamma.colorCorrectionMode == #gamma then IDisplayGamma.gamma else 1.0
			navigatorBitmapBlank = bitmap 180 100 color:MagmaFlowColors.EditorBackgroundColor gamma:(1.0/theGamma)
			navigatorBitmapBackground = bitmap 180 100 gamma:(1.0/theGamma)
			navigatorBitmapForeground = bitmap 180 100 gamma:(1.0/theGamma)
		)		
		
		fn updateNavigatorBackground =
		(
			copy navigatorBitmapBlank navigatorBitmapBackground 
			local allPositions = #()
			local minX = 1000000
			local minY = 1000000
			local maxX = -1000000
			local maxY = -1000000
			
			local nodeArray = magma.GetNodes()
			local nodeCount = nodeArray.count
			
			for i = 1 to nodeCount do
			(
				local theID = nodeArray[i]
				local isBranchCollapsed = (magma.getNodeProperty theID "Internal_BranchCollapsed") == true	
				if not isBranchCollapsed do
				(
					hc.activeNode = i
					local thePos = hc.activeNodePos --magma.getNodeProperty theID "Position"
					local theType = magma.getNodeType theID
					local goOn = true
					if findItem #("BLOPSocket","BLOPOutput") theType > 0 do goOn = false
					if theType == "Output" and MagmaFlowSettings.outputNodesOnRight do goOn = false
					if matchPattern theType pattern:"*Loop__*put" do goOn = false
					if theType == "InputValue" and MagmaFlowSettings.InputsOnTheLeftAll and MagmaFlowSettings.InputsOnTheLeftValue do goOn = false
					if theType == "InputChannel" and MagmaFlowSettings.InputsOnTheLeftAll and MagmaFlowSettings.InputsOnTheLeftChannel do goOn = false
					if theType == "LoopChannel" and MagmaFlowSettings.InputsOnTheLeftAll and MagmaFlowSettings.InputsOnTheLeftChannel do goOn = false
					if theType == "InputObject" and MagmaFlowSettings.InputsOnTheLeftAll and MagmaFlowSettings.InputsOnTheLeftObject do goOn = false
					if theType == "InputGeometry" and MagmaFlowSettings.InputsOnTheLeftAll and MagmaFlowSettings.InputsOnTheLeftGeometry do goOn = false
					if theType == "InputParticles" and MagmaFlowSettings.InputsOnTheLeftAll and MagmaFlowSettings.InputsOnTheLeftParticles do goOn = false
					if theType == "InputScript" and MagmaFlowSettings.InputsOnTheLeftAll and MagmaFlowSettings.InputsOnTheLeftScript do goOn = false
						
					if goOn do
					(
						local theNodeSize = hc.nodeSize
						if theType == "InputTexmap" and MagmaFlowSettings.showTextureMapSample and magma.getNodeProperty theID "texmap" != undefined do 
							theNodeSize+=[0,theNodeSize.x]
						append allPositions #(thePos, theNodeSize, hc.nodeColor, hc.isSelected )
						if thePos.x > maxX do maxX = thePos.x
						if thePos.x < minX do minX = thePos.x
						if thePos.y > maxY do maxY = thePos.y
						if thePos.y < minY do minY = thePos.y
					)--end if goOn
				)--end if not branch collapsed
			)--end i loop
			maxX += 140
			minX -= 20
			maxY += 140
			minY -= 20
			theMin = [minX,minY]
			theMax = [maxX, maxY]
			bBoxSize = theMax-theMin
			theColor = blue
			for i = 1 to allPositions.count do
			(
				thePos = allPositions[i][1]
				relPos1 = ((thePos - theMin) / bboxSize)*[180,100]
				relPos2 = ((thePos - theMin + allPositions[i][2]) / bboxSize)*[180,100]
				local theColors1 = for j = relPos1.x to relPos2.x collect 
				(
					if allPositions[i][4] then
						white
					else --counter-act the bitmap gamma 
					(
						c = (allPositions[i][3]*0.6)/255
						c = Point3 (c.r^theGamma) (c.g^theGamma) (c.b^theGamma)
						c *= 255
					)
				)
				local theColors2 = for j = relPos1.x to relPos2.x collect 
				(
					if allPositions[i][4] and (j == relPos1.x or j > relPos2.x-1) then
						white
					else --counter-act the bitmap gamma 
					(
						c = (allPositions[i][3]*0.9)/255
						c = Point3 (c.r^theGamma) (c.g^theGamma) (c.b^theGamma)
						c *= 255
					)
				)
				local whiteLine = for j = relPos1.x to relPos2.x collect white
				local titleHeight = relPos1.y + 2
				for j = relPos1.y to relPos2.y do
					setPixels navigatorBitmapBackground [relPos1.x, j] (if j <= titleHeight then theColors1 else (if allPositions[i][4] and j > relPos2.y-1 then whiteLine else theColors2))
			)			
		)
		
		fn updateNavigator fullUpdate:true=
		(
			if fullUpdate do updateNavigatorBackground()
			
			copy navigatorBitmapBackground navigatorBitmapForeground
			--format "Pan:%  Zoom:%\n" hc.pan hc.zoom
			--format "theMin: %  bboxSize: %\n" theMin bboxSize
			local theUpperLeft = ((-hc.pan - theMin) /bboxSize / hc.zoom)*[180,100] 
			local theBottomRight = (((-hc.pan - theMin + [hc.width, hc.height]) / hc.zoom )/ bboxSize)*[180,100] 
			theBBoxCenter = (theUpperLeft+(theBottomRight-theUpperLeft)*0.5)
			
			if theUpperLeft.x <=0 do theUpperLeft.x = 0
			if theBottomRight.x >= 179 do theBottomRight.x = 179
			if theUpperLeft.y <=0 do theUpperLeft.y = 0
			if theBottomRight.y >= 99 do theBottomRight.y = 99
				
			theColors = for i = theUpperLeft.x to theBottomRight.x collect blue
			if theUpperLeft.y != 0 do setPixels navigatorBitmapForeground theUpperLeft theColors
			if theBottomRight.y != 99 do setPixels navigatorBitmapForeground [theUpperLeft.x,theBottomRight.y] theColors
			for i = theUpperLeft.y to theBottomRight.y do 
			(
				if theUpperLeft.x != 0 do setPixels navigatorBitmapForeground [theUpperLeft.x,i] #(blue)
				if theBottomRight.x != 179 do setPixels navigatorBitmapForeground [theBottomRight.x,i] #(blue)
			)
			bmp_navigator.bitmap = navigatorBitmapForeground
			--format "Pan: %   Zoom: %\n" hc.pan hc.zoom
		)
		
		fn moveNavigatorWindow pos =
		(
			--format "pos = %  TheCenter = %\n" pos theBBoxCenter
			theOffset = (pos - theBBoxCenter)/[180,100]*bBoxSize --convert imgtag pixels to real pixels
			--format "theOffset  = %\n" theOffset
			hc.pan -= theOffset * hc.zoom
			updateNavigator fullUpdate:false
			createNodeTree init:false			
		)
		
		local leftMouseDown = false
		on MagmaFlowEditor_Rollout lbuttondown pos do
		(
			thePos = pos - bmp_navigator.pos
			if thePos.x >= 0 and thePos.y >= 0 and thePos.x < 180 and thePos.y < 100 do
			(
				leftMouseDown = true
				moveNavigatorWindow thePos			
			)
		)
		on MagmaFlowEditor_Rollout lbuttonup pos do
		(
			leftMouseDown = false
		)
		
		on MagmaFlowEditor_Rollout rbuttondown pos do
		(
			popupMenu MagmaFlowEditor_Zoom_RCMenu pos:mouse.screenpos
		)
		
		on MagmaFlowEditor_Rollout mousemove pos do
		(
			if leftMouseDown do
			(
				thePos = pos - bmp_navigator.pos
				moveNavigatorWindow thePos
			)
		)		
		
		
		fn resetPanFactor update:true createUndo:true=
		(
			hc.pan = [0,0]
			if createUndo do createUndoRecord ("Reset Pan")
			if update do
			(
				createNodeTree init:false
				updateNavigator fullUpdate:false						
			)
		)		
		
		fn resetZoomFactor update:true createUndo:true=
		(
			hc.zoom = 1
			if createUndo do createUndoRecord ("Reset Zoom")
			if update do
			(
				createNodeTree init:false
				updateNavigator fullUpdate:false			
			)
		)
		
		fn ZoomExtents createUndo:true=
		(
			local minX = 1000000
			local maxX =-1000000
			local minY = 1000000
			local maxY =-1000000
			
			local theCount = editorNodeCount
			if theCount > 1 then
			(
				for i = 1 to theCount do
				(
					local theType = magma.getNodeType (NodeIDMap[i])
					if theType != Output do
					(
						hc.activeNode = i
						local theVal = hc.activeNodePos
						if theVal.x+150 > maxX do maxX = theVal.x+150
						if theVal.y+100 > maxY do maxY = theVal.y+100
						if theVal.x < minX do minX = theVal.x 
						if theVal.y < minY do minY = theVal.y
					)
				)
				minY -=40
				theBBoxX = maxX-minX
				theBBoxY = maxY-minY
				local theHCWidth = hc.width-leftDepotMargin
				hc.zoom = amin #(1.0*theHCWidth/theBBoxX,1.0*hc.height/theBBoxY)
				if hc.zoom > 1.5 do hc.zoom = 1.5
				hc.pan = -[minX,minY]*hc.zoom + [leftDepotMargin,0]
			)
			else
			(
				hc.zoom = 1.0
				hc.pan = [0,0]
			)
			createNodeTree init:false
			if createUndo do createUndoRecord ("Zoom Extents")
			updateNavigator fullUpdate:false
		)
		
		fn ZoomExtentsSelected createUndo:true =
		(
			local minX = 1000000
			local maxX =-1000000
			local minY = 1000000
			local maxY =-1000000
			local doZoom = 0
			
			local nodeArray = Magma.GetNodes()
			local theCount = nodeArray.count --editorNodeCount
			if theCount > 1 then
			(
				for i = 1 to theCount do
				(
					local theType = magma.getNodeType (nodeArray[i])
					if theType != Output do
					(					
						hc.ActiveNode = i
						if hc.isSelected do
						(
							doZoom += 1
							local theVal = hc.activeNodePos
							if theVal.x+150 > maxX do maxX = theVal.x+150
							if theVal.y+100 > maxY do maxY = theVal.y+100
							if theVal.x < minX do minX = theVal.x 
							if theVal.y < minY do minY = theVal.y
						)		
					)
				)
				if doZoom > 1 do
				(
					minY -=40
					theBBoxX = maxX-minX
					theBBoxY = maxY-minY
					hcWidth = hc.width-leftDepotMargin
					hc.zoom = amin #(1.0*hcWidth/theBBoxX,1.0*hc.height/theBBoxY)
					if hc.zoom > 1.5 do hc.zoom = 1.5
					hc.pan = -[minX,minY]*hc.zoom + [leftDepotMargin,0]
				)
				if doZoom == 1 do 
				(
					minY -= 40
					--minX -= hc.width/4
					theBBoxX = maxX-minX
					theBBoxY = maxY-minY			
					hc.zoom = amin #(1.0*hc.width/theBBoxX,1.0*hc.height/theBBoxY)					
					if hc.zoom > 1.5 do hc.zoom = 1.5
					hc.pan = -[minX,minY]*hc.zoom + [leftDepotMargin,0]
				)
			)
			createNodeTree init:false
			if createUndo do createUndoRecord ("Zoom Extents Selected")
			updateNavigator fullUpdate:false
		)		
		
		
		
------------------------------------------------------------		
--SCHEMATIC CONTROLS EVENT HANDLERS		
------------------------------------------------------------		
		on hc connectionChanged fromNodeIndex toNodeIndex toSocketID fromSocketID status toSocketCount do
		(
			--format "% % % % % %\n" fromNodeIndex toNodeIndex toSocketID fromSocketID status toSocketCount
			if status == 1 then --CONNECTED
			(
				toID = NodeIDMap[toNodeIndex]
				fromID = NodeIDMap[fromNodeIndex]
				
				if toID == undefined or fromID == undefined do --if one of these is undefined, try to rebuild the NodeIDMap and try again.
				(
					createNodeTree init:false
					toID = NodeIDMap[toNodeIndex]
					fromID = NodeIDMap[fromNodeIndex]
				)
				
				--FranticParticles.LogDebug ("NodeIDMap=" + (with PrintAllElements on (NodeIDMap as string)))
				--FranticParticles.LogDebug ("toNodeIndex=" + toNodeIndex as string + " fromNodeIndex="+ fromNodeIndex as string + " toID="+toID as string + " fromID="+ fromID as string  )
				
				--format "NodeIDMap=%\n" NodeIDMap
				--format "toNodeIndex=%\n" toNodeIndex
				--format "fromNodeIndex=%\n" fromNodeIndex
				
				--format "toID=%\n" toID
				--format "fromID=%\n" fromID				
				
				if magma.getNodeType fromID == "BLOPSocket" then
				(
					if toID == -1 then
					(
						magma.SetOutput toSocketID fromID fromSocketID
						MagmaFlowEditor_Rollout.createUndoRecord ("Connect ["+ fromID as string + "," + fromSocketID as string + "] to [BLOP Output " + toSocketID as string +"]" )
					)
					else
					(
						magma.SetNodeInput toID toSocketID fromID fromSocketID
						MagmaFlowEditor_Rollout.createUndoRecord ("Connect ["+ fromID as string + "," + fromSocketID as string + "] to ["+ toID as string + "," + toSocketID as string +"]" )
					)
				)
				else
				(
					if toID == -1 then
					(
						local fromNodeOutputIndex = fromSocketID - magma.GetNumNodeInputs fromID
						magma.setOutput toSocketID fromID fromNodeOutputIndex
						MagmaFlowEditor_Rollout.createUndoRecord ("Connect ["+ fromID as string + "," + fromNodeOutputIndex as string+"] to [Output,"+ toSocketID as string + "]"  )
					)
					else
					(
						local fromNodeOutputIndex = fromSocketID - magma.GetNumNodeInputs fromID
						try
						(
							magma.SetNodeInput toID toSocketID fromID fromNodeOutputIndex
							MagmaFlowEditor_Rollout.createUndoRecord ("Connect ["+ fromID as string + "," + fromNodeOutputIndex as string+"] to [" +toID as string + "," + toSocketID as string + "]" )
						)catch()
					)
				)
			)
			else  --DISCONNECTED
			(
				toID = NodeIDMap[toNodeIndex] 
				if toID > -1 then
				(
					local oldConnection = magma.GetNodeInput toID toSocketID
					magma.SetNodeInput toID toSocketID -1 1
					MagmaFlowEditor_Rollout.createUndoRecord ("Disconnect [" + oldConnection[1] as string + "," + oldConnection[2] as string + "] from ["+ toID as string + ","+toSocketID as string+"] ")
				)
				else
				(
					local oldConnection = magma.GetOutput toSocketID
					magma.setOutput toSocketID -1 1
					MagmaFlowEditor_Rollout.createUndoRecord ("Disconnect [" + oldConnection[1] as string + "," + oldConnection[2] as string + "] from [BLOP Output "+toSocketID as string+"] ")
				)
				
			)
			updateMagmaHolder()

			if fromID != undefined then
			(
				if magma.getNodeType fromID == "Mux" or magma.getNodeType fromID == "Switch" do 
				(
					local theControlConnection = magma.getNodeInput fromID ((magma.getNumNodeInputs fromID))
					if magma.getNodeType theControlConnection[1] == "InputValue" and magma.getNodeProperty theControlConnection[1] "Exposed" == true do
						exposeControlsToModifier()
				)
			)
			if toID != undefined do
			(
				if magma.getNodeType toID == "Mux" or magma.getNodeType toID == "Switch" do 
				(
					local theControlConnection = magma.getNodeInput toID ((magma.getNumNodeInputs toID))
					if magma.getNodeType theControlConnection[1] == "InputValue" and magma.getNodeProperty theControlConnection[1] "Exposed" == true do
						exposeControlsToModifier()
				)
			)
			--createNodeTree init:true
			autoReorderFlow createUndo:false
			displaySelectedNodeProperties()
			createNodeTree init:false
			updateNavigator fullUpdate:true
			debugFlow()
		)		
		
		on hc connectToEmpty nodeIndex socketIndex socketType do
		(
			ConnectToEmpty_fromID = NodeIDMap[nodeIndex]
			if ConnectToEmpty_fromID == undefined do return false
			if ConnectToEmpty_fromID == -1 then
			(
				ConnectToEmpty_Index = socketIndex 
				showRCMenu #allNodes
				ConnectToEmpty_SocketType = #input
			)
			else
			(
				local theFromSocket = (magma.getNodeInput ConnectToEmpty_fromID socketIndex)[1]
				if  theFromSocket == undefined or theFromSocket > -1 do return false
				local numInputs = (magma.GetNumNodeInputs ConnectToEmpty_fromID)
				if socketIndex <= numInputs then
				(
					ConnectToEmpty_Index = socketIndex 
					ConnectToEmpty_SocketType = #input
					if magma.getNodeType ConnectToEmpty_fromID == "BLOPSocket" do ConnectToEmpty_SocketType = #output
					if matchPattern (getInputSocketName ConnectToEmpty_fromID socketIndex) pattern:"Object" then
					(
						local theNewNode = createNode "InputObject" mode:#dragwire
						setSelectedNodes #(MagmaFlowEditor_Functions.getIndexByID magma theNewNode)
						displaySelectedNodeProperties()
					)
					else if matchPattern (getInputSocketName ConnectToEmpty_fromID socketIndex) pattern:"Geometry" then
					(
						local theNewNode = createNode "InputGeometry"	mode:#dragwire
						setSelectedNodes #(MagmaFlowEditor_Functions.getIndexByID magma theNewNode)
						displaySelectedNodeProperties()
					)
					else if matchPattern (getInputSocketName ConnectToEmpty_fromID socketIndex) pattern:"Lookup Point (OS)*" or matchPattern (getInputSocketName ConnectToEmpty_fromID socketIndex) pattern:"Position" then
					(
							if keyboard.controlPressed then
								showRCMenu #allNodes
							else
							(
								local theNewNode = createNode "InputChannel" channelName:"Position" mode:#dragwire
								setSelectedNodes #(MagmaFlowEditor_Functions.getIndexByID magma theNewNode)
								displaySelectedNodeProperties()	
							)
					)			
					else if matchPattern (getInputSocketName ConnectToEmpty_fromID socketIndex) pattern:"VertexColor*" then
					(
							if keyboard.controlPressed then
								showRCMenu #allNodes
							else
							(
								local theNewNode = createNode "InputChannel" channelName:"Color" mode:#dragwire
								setSelectedNodes #(MagmaFlowEditor_Functions.getIndexByID magma theNewNode)
								displaySelectedNodeProperties()	
							)
					)						
					else if matchPattern (getInputSocketName ConnectToEmpty_fromID socketIndex) pattern:"TextureCoord*" then
					(
							if keyboard.controlPressed then
								showRCMenu #allNodes
							else
							(
								local theNewNode = createNode "InputChannel" channelName:"TextureCoord" mode:#dragwire
								setSelectedNodes #(MagmaFlowEditor_Functions.getIndexByID magma theNewNode)
								displaySelectedNodeProperties()	
							)
					)		
					else if matchPattern (getInputSocketName ConnectToEmpty_fromID socketIndex) pattern:"Normal (OS)*" then
					(
							if keyboard.controlPressed then
								showRCMenu #allNodes
							else
							(
								local theNewNode = createNode "InputChannel" channelName:"Normal" mode:#dragwire
								setSelectedNodes #(MagmaFlowEditor_Functions.getIndexByID magma theNewNode)
								displaySelectedNodeProperties()	
							)
					)		
					else if matchPattern (getInputSocketName ConnectToEmpty_fromID socketIndex) pattern:"VertIndex*" then
					(
							if keyboard.controlPressed then
								showRCMenu #allNodes
							else
							(
								local theNewNode = createNode "InputChannel" channelName:"VertexIndex" mode:#dragwire
								setSelectedNodes #(MagmaFlowEditor_Functions.getIndexByID magma theNewNode)
								displaySelectedNodeProperties()	
							)
					)			
					else if matchPattern (getInputSocketName ConnectToEmpty_fromID socketIndex) pattern:"FaceIndex*" then
					(
							if keyboard.controlPressed then
								showRCMenu #allNodes
							else
							(
								local theNewNode = createNode "InputChannel" channelName:"FaceIndex" mode:#dragwire
								setSelectedNodes #(MagmaFlowEditor_Functions.getIndexByID magma theNewNode)
								displaySelectedNodeProperties()	
							)
					)		
					else if matchPattern (getInputSocketName ConnectToEmpty_fromID socketIndex) pattern:"Index*" then
					(
							if keyboard.controlPressed then
								showRCMenu #allNodes
							else
							(
								local theNewNode = createNode "InputChannel" channelName:"Index" mode:#dragwire
								setSelectedNodes #(MagmaFlowEditor_Functions.getIndexByID magma theNewNode)
								displaySelectedNodeProperties()	
							)
					)						
					else if matchPattern (getInputSocketName ConnectToEmpty_fromID socketIndex) pattern:"Ray Direction (WS)*" then
					(
						if not keyboard.controlPressed then
							showRCMenu #allNodes
						else					
						(
							local theNewNode = createNode "InputValue" mode:#dragwire
							local theCtrl = point3_xyz(); theCtrl.value = [0,0,-1]
							magma.SetNodeProperty theNewNode "controller" theCtrl		
							setSelectedNodes #(MagmaFlowEditor_Functions.getIndexByID magma theNewNode)
							displaySelectedNodeProperties()							
						)
					)
					else if matchPattern (getInputSocketName ConnectToEmpty_fromID socketIndex) pattern:"Lookup Point (WS)*" or matchPattern (getInputSocketName ConnectToEmpty_fromID socketIndex) pattern:"Ray Origin (WS)*"  then
					(
						if keyboard.controlPressed then
							showRCMenu #allNodes
						else					
						(
							local theDeps = refs.dependentNodes magma
							if theDeps.count == 1 and classof theDeps[1].baseobject == PRT_Hair then
							(
								local theNewNode = createNode "InputChannel" channelName:"HairRoot" mode:#dragwire
								if theDeps[1].SourceType == 1 then
								(
									setSelectedNodes #(MagmaFlowEditor_Functions.getIndexByID magma theNewNode)
									displaySelectedNodeProperties()	
								)
								else
								(
									if superclassof (MagmaFlowEditor_Functions.getMagmaOwner magma) != SpacewarpModifier do
									(
										setSelectedNodes #(MagmaFlowEditor_Functions.getIndexByID magma theNewNode)
										displaySelectedNodeProperties()	
										MagmaFlowEditor_InputChannelRollout.btn_transformToWorld.pressed()					
										try
										(
											local theConverter = (Magma.GetNodes())[ (getSelectedNodes())[1] ]
											magma.setNodeProperty theConverter "inputType"	"Point"
										)catch()
										setSelectedNodes #(MagmaFlowEditor_Functions.getIndexByID magma theNewNode)
									)
									displaySelectedNodeProperties()	
								)
							)
							else
							(
								local theNewNode = createNode "InputChannel" channelName:"Position" mode:#dragwire
								setSelectedNodes #(MagmaFlowEditor_Functions.getIndexByID magma theNewNode)
								displaySelectedNodeProperties()	
								if superclassof (MagmaFlowEditor_Functions.getMagmaOwner magma) != SpacewarpModifier do
								(	
									MagmaFlowEditor_InputChannelRollout.btn_transformToWorld.pressed()				
									setSelectedNodes #(MagmaFlowEditor_Functions.getIndexByID magma theNewNode)
									displaySelectedNodeProperties()	
								)
							)
						)
					)
					else if matchPattern (getInputSocketName ConnectToEmpty_fromID socketIndex) pattern:"Particles" then
					(
						local theNewNode = createNode "InputParticles" mode:#dragwire
						setSelectedNodes #(MagmaFlowEditor_Functions.getIndexByID magma theNewNode)
						displaySelectedNodeProperties()	
					)
					else if findItem #("Posit","Norma","Color","Textu","Mappi") (substring (getInputSocketName ConnectToEmpty_fromID socketIndex) 1 5) > 0 and magma.getNodeType ConnectToEmpty_fromID == "InputTexmap" then
					(
						if keyboard.controlPressed then
							showRCMenu #allNodes
						else
						(
							local theNewNode = createNode "InputChannel" channelName:(getInputSocketName ConnectToEmpty_fromID socketIndex) mode:#dragwire
							setSelectedNodes #(MagmaFlowEditor_Functions.getIndexByID magma theNewNode)
							displaySelectedNodeProperties()	
						)
					)				
					else
					(
						if keyboard.controlPressed then
							showRCMenu #Input
						else
						(
							showRCMenu #allNodes
						)
					)
				)
				else --if dragging from an output
				(
					ConnectToEmpty_Index = socketIndex - numInputs
					ConnectToEmpty_SocketType = #output
					local theFromType = (magma.getNodeType ConnectToEmpty_fromID)
					if theFromType == "InputGeometry" then
					(
						showRCMenu #Object
					)
					else if theFromType == "InputObject" then
					(
						local theNewNode = createNode "PropertyQuery" mode:#dragwire
						setSelectedNodes #(MagmaFlowEditor_Functions.getIndexByID magma theNewNode)
						displaySelectedNodeProperties()					
					)
					else if theFromType == "InputParticles" then
					(
						if keyboard.controlPressed then
						(
							local theNewNode = createNode "ParticleQuery" mode:#dragwire
							setSelectedNodes #(MagmaFlowEditor_Functions.getIndexByID magma theNewNode)
							displaySelectedNodeProperties()					
						)
						else
							showRCMenu #Object
					)
					else
					(
						--format "General \n"
						showRCMenu #allNodes
					)
				)
			)
		)
		
		on hc connectionSelectionChanged fromNodeIndex toNodeIndex toSocketID fromSocketID do
		(
			lastWireSelection = #(fromNodeIndex, fromSocketID, toNodeIndex, toSocketID, timestamp() )
			--format "%\n" lastWireSelection 
		)
		
		fn removeNode deleteTheNode:true=
		(
			local needExposureUpdate = false
			theIndices = for i = 1 to EditorNodeCount collect 
			(
				hc.ActiveNode = i
				if hc.isSelected then i else dontcollect
			)
			if theIndices.count > 0 do
			(
				sort theIndices
				for index in theIndices.count to 1 by -1 do --loop backwards through all nodes selected for removal
				(
					local theID = MagmaFlowEditor_Functions.getNodeID magma theIndices[index]
					local firstInput = #(-1,1)
					for j = 1 to magma.getNumNodeInputs theID while firstInput[1] == -1 do
					(
						firstInput = magma.getNodeInput theID j --get the first input of the node to remove
					)
					local firstOutput = (magmaFlowEditor_Functions.GetConnectedNodes magma theID)[1] --get the nodes connected to the first output of the node to remove
					if firstOutput != undefined and firstOutput.count > 0 do 
					(
						for j in firstOutput do
							magma.setNodeInput j[1] j[2] firstInput[1] firstInput[2] --connect the upstream node's input 1 to the downstream node's output socket connected to the input 1 of the node to remove
					)
					for j = 1 to magma.getNumNodeInputs theID do magma.setNodeInput theID j -1 1 --disconnect all inputs of the node to remove
					if deleteTheNode do 
					(
						if magma.getNodeProperty theID "Exposed" == True do needExposureUpdate = true
						for theIDtoCheck in magma.GetNodes() do
						(
							for c = 1 to magma.getNumNodeInputs theIDtoCheck do
								if (magma.getNodeInput theIDtoCheck c)[1] == theID do 
									magma.setNodeInput theIDtoCheck c -1 1
						)
						magma.deleteNode theID --if deleting, delete the node
					)
				)				
				updateMagmaHolder()
				if needExposureUpdate do exposeControlsToModifier()
				autoReorderFlow createUndo:false
				displaySelectedNodeProperties()	
				updateNavigator fullUpdate:true				
				updateInsertMode()
				updateEditorTitle()
				lastSelection = #()
				debugFlow()
			)	
		)
		
		fn removeNodeFromFlow = 
		(
			removeNode deleteTheNode:false
		)	

		fn deleteSelectedNodes =
		(
			removeNode deleteTheNode:true
		)
		
		on hc nodesDeleted do
		(
			local needUpdate = false
			local theIndices = sort (for i = 1 to hc.getDeletedNodeCount collect (hc.getDeletedNodeIndex = i))
			for index in theIndices.count to 1 by -1 do
			(
				local theID = MagmaFlowEditor_Functions.getNodeID magma theIndices[index]
				if theID != undefined and theID > -1 do --if the ID is valid, in other words not a Depot item
				(
					local theType = magma.getNodeType theID
					if theType != undefined do --and theType != "Output" do 
					(
						needUpdate = true
						for theIDtoCheck in magma.GetNodes() do
							for c = 1 to magma.getNumNodeInputs theIDtoCheck do
								if (magma.getNodeInput theIDtoCheck c)[1] == theID do 
									magma.setNodeInput theIDtoCheck c -1 1
						magma.deleteNode theID
					)	
				)
			)	
			if needUpdate do
			(
				if theIndices.count == 1 then
					createUndoRecord ("Delete One Selected Node")				
				else
					createUndoRecord ("Delete " + theIndices.count as string + " Selected Nodes")				
				autoReorderFlow createUndo:false
				--if AutoZoomExtents do zoomExtents createUndo:false
				exposeControlsToModifier()
				displaySelectedNodeProperties()
			)	
			updateMagmaHolder()
			--createNodeTree init:true	
			updateNavigator fullUpdate:true		
			updateInsertMode()
			updateEditorTitle()		
			lastSelection = #()
			debugFlow()
		)		
		
		

		on hc mouseScroll do
		(
			if hc.zoom > 1.2 do hc.zoom = 1.2
			showGrid MagmaFlowSettings.SnapToGrid
			drawDepot init:false lock:true
			updateNavigator fullUpdate:false
		)
		
		fn storePanAndZoom =
		(
			if magma.NumEditingBLOPs() == 0 then
			(
				MagmaFlowEditor_Functions.setEditorProperty magma "EditorPan" (hc.pan as string)
				MagmaFlowEditor_Functions.setEditorProperty magma "EditorZoom" (hc.zoom as string)
			)
			else
			(
				local nodeArray = magma.GetNodes()
				local nodeCount = nodeArray.count
				for i = 1 to nodeCount do 
				(
					theBlopSocket = nodeArray[i]
					magma.DeclareExtensionProperty theBlopSocket  "EditorPan" 
					magma.DeclareExtensionProperty theBlopSocket  "EditorZoom" 
					magma.setNodeProperty theBlopSocket "EditorPan" hc.pan 
					magma.setNodeProperty theBlopSocket "EditorZoom" hc.zoom 
				)
			)
		)
		
		fn restorePanAndZoom =
		(
			if magma.NumEditingBLOPs() == 0 then
			(
				thePan =  (MagmaFlowEditor_Functions.getEditorProperty magma "EditorPan" )
				theZoom = (MagmaFlowEditor_Functions.getEditorProperty magma "EditorZoom" )
				if thePan != undefined do hc.pan = execute thePan
				if theZoom != undefined do hc.zoom = execute theZoom
			)
			else
			(
				local done = false
				local nodeArray = magma.GetNodes()
				local nodeCount = nodeArray.count
				
				for i = 1 to nodeCount while not done do 
				(
					theBlopSocket = nodeArray[i]
					thePan = magma.getNodeProperty theBlopSocket "EditorPan" 
					theZoom = magma.getNodeProperty theBlopSocket "EditorZoom"
					if thePan != undefined and theZoom != undefined do 
					(
						hc.pan = thePan
						hc.zoom = theZoom
						hc.redrawView	
						done = true
					)
				)
			)
			hc.redrawView	
		)		
		
		local leftButtonDown = false
		local middleButtonDown = false
		on hc mButtonUp do
		(
			middleButtonDown = false
			drawDepot init:false lock:false
			updateNavigator fullUpdate:false
			storePanAndZoom()
		)		
		
		on hc mButtonDown do
		(
			middleButtonDown = true
			drawDepot init:false lock:true
		)			
		
		on hc LButtonDown do
		(
			leftButtonDown = true
			if not DisableDragAndDrop do
			(
				prepareDepotForDragAndDrop()
			)
			lastSelectionBeforeClick = getSelectedNodes()
			lastMouseClick = mouse.screenpos
		)		
		
		fn updateInsertMode update:true=
		(
			local theSel = getSelectedNodes()
			MagmaFlowSettings.nodeInsertMode = true
			MagmaFlowSettings.nodeInsertSocket = 0
			toggleInsertMode update:update
		)		
		
		on hc LButtonUp do
		(
			leftButtonDown = false
			local theSel = getSelectedDepotButton()
			try
			(
				hc.setInfo = case theSel.count of
				(
					1: "Depot: " + DepotNodes[theSel[1]][5] --getFileNameFile
					0: "" 
					default: "Multiple Depot Nodes Selected"
				)	
			)catch()
			--handle Depot Category Head clicking
			if theSel.count == 1 and theSel[1] <= DepotNodes.count and (DepotNodes[theSel[1]][1] == "HEAD" or DepotNodes[theSel[1]][1] == "SUBHEAD") then 
			(
				if (keyboard.ControlPressed and not keyboard.shiftPressed) then
				(
					if (MagmaFlowSettings.DepotPlacement != #bottomrollup and MagmaFlowSettings.DepotPlacement != #bottomrollupreverse) do
						for j = 1 to DepotDefinition.count where DepotDefinition[j][1][1]  == "HEAD" do
							DepotDefinition[j][1][6] = false
					for j = 1 to DepotDefinition.count where DepotDefinition[j][1][2] == DepotNodes[theSel[1]][2] do
						DepotDefinition[j][1][6] = true
				)
				else if keyboard.shiftPressed and not keyboard.ControlPressed then
				(
					for j = 1 to DepotDefinition.count where DepotDefinition[j][1][1]  == "HEAD" do
						DepotDefinition[j][1][6] = true					
				)
				else if keyboard.shiftPressed and keyboard.ControlPressed then
				(
					for j = 1 to DepotDefinition.count where DepotDefinition[j][1][1]  == "HEAD" do
						DepotDefinition[j][1][6] = false							
				)
				else if not keyboard.shiftPressed and not keyboard.ControlPressed then
				(
					for j = 1 to DepotDefinition.count do
					(
						if DepotDefinition[j][1][2] == DepotNodes[theSel[1]][2] do
						(
							DepotDefinition[j][1][6] = not DepotDefinition[j][1][6]
							if (MagmaFlowSettings.DepotPlacement == #bottomrollup or MagmaFlowSettings.DepotPlacement == #bottomrollupreverse) and DepotDefinition[j][1][6] == true do 
							(
								for k = 1 to DepotDefinition.count where k != j do
									DepotDefinition[k][1][6] = false
							)
						)
					)
					
				)	
				updateDepotDefinition()
				createNodeTree init:true
				--if AutoZoomExtents do zoomExtents createUndo:false
			)	
			else --handle Depot Drag and Drop
			(
				if not DisableDragAndDrop then
				(
					local result = handleDepotDragAndDrop()
					drawDepot init:false
					if not result do updateNodeSelection()
				)	
				else 
				(
					updateNodeSelection()
				)
			)
			
			if keyboard.shiftPressed do 
			(
				removeNode deleteTheNode:false
			)
			
			if MagmaFlowSettings.isPickingChannelFromNode != undefined then
			(
				--format "%\n" MagmaFlowSettings.isPickingChannelFromNode
				local NodesSelected = getSelectedNodes()
				local NodeClick = 0
				if NodesSelected.count == 1 do NodeClick = NodesSelected[1]
				--format "NodeClick = %\n" NodeClick 
				--setSelectedNodes #(MagmaFlowSettings.isPickingChannelFromNode)
				
				local nodeArray = magma.GetNodes()
				local nodeCount = nodeArray.count
				
				if NodeClick > 0 and NodeClick <= nodeCount then 
				(
					local theID = nodeArray[NodeClick]
					local theChannel = magma.getNodeProperty theID "channelName"
					if theChannel != undefined do 
					(
						local theChannelType = magma.getNodeProperty theID "channelType"
						thePickID = (Magma.GetNodes())[ MagmaFlowSettings.isPickingChannelFromNode ]
						magma.setNodeProperty thePickID "channelName" theChannel
						--if magma.getNodeType thePickID == "Output" do
						--magma.setNodeProperty thePickID "channelType" theChannelType
						
						setSelectedNodes #(MagmaFlowSettings.isPickingChannelFromNode)
						MagmaFlowSettings.isPickingChannelFromNode = undefined
					)
				)
			)
				
			--debugFlow()	
			DisableDragAndDrop = false --enable DND on first mouse move. This prevents from undesired DnD operations on menu commands.

			if MagmaFlowSettings.insertNodeIntoFlow do
			(
				local theSelection = getSelectedNodes()
				if theSelection.count == 1 do
				(
					local theInsertID = (Magma.GetNodes())[ theSelection[1] ]
					insertNodeIntoExistingFlow theInsertID
				)
			)
			

			updateDepotDefinition()
			updateNodeSelection()
			updateInsertMode() --FIXME - this causes an update of all nodes

			local theSelection = getSelectedNodes()
			if theSelection.count != 1 do 
			(
				--print "selection is not 1, resetting"
				--lastWireSelection = #()
			)
			if hc.getSelectedConnectionNodeAndSocket == false and not keyboard.controlPressed  do  --and theSelection.count != 1 
			(
				if lastWireSelection.count > 0 and timestamp()-lastWireSelection[5] > 100.0 do
				(
					--print "wire deselected, resetting"
					lastWireSelection = #()
				)
			)
			
			drawDepot init:false
			updateNavigator()
			if MagmaFlowSettings.DebugSelectedOnly do debugFlow()
		)
		

		
		
		on hc RButtonDown do
		(
			local theMouse = getMouseInSchematicView()
			lastNodeClick = (hc.findNodeByPos = theMouse)
			if lastNodeClick > 0 and lastNodeClick <= editorNodeCount then 
			(
				popupMenu EditNode_RCMenu pos:mouse.screenpos
			)
			else if lastNodeClick  > editorNodeCount then 
				popupMenu DepotNode_RCMenu pos:mouse.screenpos
			else if lastWireSelection.count > 0 then
				popupMenu InsertNode_RCMenu pos:mouse.screenpos
			else
				popupMenu AddNode_RCMenu pos:mouse.screenpos
		)		
		
			
		local lastNodeOverID = -1
		local previousNodeOver = -1
		local theLastText = ""
		on hc mouseMoved do
		(
			showTooltips = true
			local theMouse = getMouseInSchematicView()
			lastNodeOver = (hc.findNodeByPos = theMouse)
			local theText = ""
			
			if lastNodeOver == 0 then
			(
				hc.setInfo = lastInfoMessage
				hc.redrawView
			)
			else
			(
				if lastNodeOver >= 0 and not leftButtonDown do
				(
					if lastNodeOver <= editorNodeCount then
					(
						if previousNodeOver != lastNodeOver do
						(
							lastNodeOverID  = MagmaFlowEditor_Functions.getNodeID magma lastNodeOver
							theLastText = try(magma.GetTypeDescription (magma.getNodeType lastNodeOverID) )catch("???")
									
							if lastNodeOverID > -1 do
							(
								local theNotes = magma.getNodeProperty lastNodeOverID "Notes"
								if theNotes != undefined and theNotes != "" do theLastText = substituteString theNotes "\n" " "
							)
						)
						
						theText = theLastText
						previousNodeOver = lastNodeOver
						
						if lastNodeOverID > -1 then
						(
							if MagmaFlowSettings.DebugModeOn do
							(
								for i in DebugOverlayArray where i[1] == lastNodeOverID do
								(
									local theDebugText = "DEBUG: "
									for k = 2 to i.count do theDebugText+= i[k] as string + "  "
									theText = theDebugText + "  |  " + theText 
								)
							)
						)
						else theText = ""
					)
					else --if over depot
					(
						hc.activeNode = lastNodeOver
						theText = try(magma.GetTypeDescription hc.nodeName)catch("")
						if theText == "" do 
						(
							local theIndex = findItem allBlopNames hc.nodeName
							if theIndex > 0 do theText = allBlopDescriptions[theIndex]
						)
					)
					hc.setInfo = theText
					hc.redrawView
				)
			)
			if middleButtonDown do updateNavigator fullUpdate:false
			--if leftButtonDown do updateNavigator fullUpdate:true
		)			
		
		
		fn disconnectAllInputs single:false createUndo:true =
		(
			local theSelection = getSelectedNodes()
			if single == true do
				if lastNodeClick > 1 then theSelection = #(lastNodeClick) else theSelection = #() 			

			local nodeArray = magma.GetNodes()
			local nodeCount = nodeArray.count
			for i in theSelection do
			(
				local theID = nodeArray[i]
				for c = 1 to magma.getNumNodeInputs theID do
					magma.setNodeInput theID c -1 1
			)		
			if theSelection.count > 0 do
			(
				createNodeTree init:true
				autoReorderFlow createUndo:false
				--if AutoZoomExtents do zoomExtents createUndo:false	
				if createUndo do createUndoRecord "Delete All Inputs"
				if single == false do setSelectedNodes theSelection
				updateMagmaHolder()
				debugFlow()
			)		
		)
		
		fn disconnectAllOutputs single:false createUndo:true =
		(
			local theSelection = getSelectedNodes()
			if single == true do
				if lastNodeClick > 1 then theSelection = #(lastNodeClick) else theSelection = #() 			
			
			local nodeArray = magma.GetNodes()
			local nodeCount = nodeArray.count
			for i in theSelection do
			(
				local theID = nodeArray[i]
				for n = 1 to nodeCount where n != i do
				(
					local theID2 = nodeArray[n]
					for c = 1 to magma.GetNumNodeInputs theID2 do
					(
						if (magma.getNodeInput theID2 c)[1] == theID do
							magma.setNodeInput theID2 c -1 1
					)
				)
			)		
			if theSelection.count > 0 do
			(
				createNodeTree init:true
				autoReorderFlow createUndo:false
				--if AutoZoomExtents do zoomExtents createUndo:false	
				if createUndo do createUndoRecord "Delete All Outputs"
				if single == false do setSelectedNodes theSelection
				updateMagmaHolder()
				debugFlow()
			)			
		)		
		
		
		fn swapInputsOrder single:false Last:false=
		(
			local success = false
			local theSelection = getSelectedNodes()
			if single == true do
				if lastNodeClick > 1 then theSelection = #(lastNodeClick) else theSelection = #() 
			
			local nodeArray = (Magma.GetNodes())			
			
			for i in theSelection do
			(
				local theID = nodeArray[i]
				if (Last==true OR keyboard.ShiftPressed) and magma.GetNumNodeInputs theID > 2 then
				(
					local temp1 = magma.getNodeInput theID 2 
					local temp2 = magma.getNodeInput theID 3
					magma.setNodeInput theID 2 temp2[1] temp2[2]
					magma.setNodeInput theID 3 temp1[1] temp1[2]
					if MagmaFlowSettings.SwapDefaultsOnInputSwap do
					(
						local temp1 = magma.getNodeInputDefaultValue theID 2
						local temp2 = magma.getNodeInputDefaultValue theID 3
						magma.setNodeInputDefaultValue theID 2 temp2
						magma.setNodeInputDefaultValue theID 3 temp1
					)
					success = true
				)
				else if magma.GetNumNodeInputs theID > 1 do
				(
					local temp1 = magma.getNodeInput theID 2 
					local temp2 = magma.getNodeInput theID 1
					magma.setNodeInput theID 2 temp2[1] temp2[2]
					magma.setNodeInput theID 1 temp1[1] temp1[2]
					if MagmaFlowSettings.SwapDefaultsOnInputSwap do
					(
						local temp1 = magma.getNodeInputDefaultValue theID 2
						local temp2 = magma.getNodeInputDefaultValue theID 1
						magma.setNodeInputDefaultValue theID 2 temp2
						magma.setNodeInputDefaultValue theID 1 temp1
					)
					success = true
				)	
			)
			if theSelection.count > 0 and success == true do
			(
				autoReorderFlow createUndo:false
				createNodeTree init:true					
				--if AutoZoomExtents do zoomExtents createUndo:false	
				--createUndoRecord "Swap Operator Inputs"
				if single == false do setSelectedNodes theSelection
				updateMagmaHolder()
				debugFlow()
				displaySelectedNodeProperties()
			)	
		)		
		
		
		fn setPassThrough single:false =
		(
			local theSelection = getSelectedNodes()
			if single == true do
				if lastNodeClick > 1 then theSelection = #(lastNodeClick) else theSelection = #() 
			
			local nodeArray = (Magma.GetNodes())
					
			for i in theSelection do
			(
				local theID = nodeArray[i]
				local theType = magma.getNodeType theID 
				if not matchPattern theType pattern:"Input*" do --theType != "Output" and 
					magma.setNodeProperty theID "enabled" (not (magma.getNodeProperty theID "enabled"))
			)
			if theSelection.count > 0 do
			(			
				createNodeTree init:false
				/*
				if theSelection.count == 1  then
					createUndoRecord ("Toggle Node ["+ KrakatoaChannelEditor_DisplayNodeTreeData[theSelection[1]][4][8] as string +"] " + (if KrakatoaChannelEditor_DisplayNodeTreeData[theSelection[1]][5] == false then "Off" else "On") )
				else
					createUndoRecord ("Toggle "+theSelection.count as string +" Nodes On/Off")
				if single == false do setSelectedNodes theSelection			
				*/
				updateMagmaHolder()
			)
			if theSelection.count == 1 do 
			(
				try(MagmaFlowEditor_OperatorRollout.updateGUI())catch()
				try(MagmaFlowEditor_OutputRollout.updateGUI())catch()
			)
			updateNavigator()
		)	
		
		fn updateEditorTitle = 
		(
			local txt = MagmaFlowEditor_Functions.getEditorTitlePrefix magma currentPreset

			if EditableBlopStack.count > 0 do
				for i in EditableBlopStack do txt += ">"+ i as string +":BLOP"

			if needToSave then txt += " * " else txt+= " "
			
			if MagmaFlowSettings.autoReorderToggle do 
			(
				txt += " [REORDER:" + toUpper (MagmaFlowSettings.AutoReorderPattern as string) 
				if MagmaFlowSettings.AutoReorderPattern == #block do txt+= MagmaFlowSettings.AutoReorderBlockHeight as string 
				txt += "]"
			)
			if MagmaFlowSettings.InputsOnTheLeftAll do txt += " [IN:LEFT]"
			if MagmaFlowSettings.nodeInsertSocket > 0 do
			(
				txt += (if MagmaFlowSettings.nodeInsertMode then " [INSERT " else " [CONNECT ")
				txt += MagmaFlowSettings.nodeInsertSocket as string + "] "
			)
			
			MagmaFlowEditor_Rollout.title = txt
		)
		
		fn toggleInsertMode update:true =
		(
			local theSel = getSelectedNodes()
			if theSel.count == 1 then
			(
				local theID = MagmaFlowEditor_Functions.getNodeID magma theSel[1]
				local theType = magma.getNodeType theID
				local theOuts = MagmaFlowEditor_Functions.getConnectedNodes magma theID
				local theOutCounts = amin #(magma.getNumNodeOutputs theID, theOuts.count)
				local theConnected = for c = 1 to theOutCounts where theOuts[c].count > 0 collect c
				if MagmaFlowSettings.nodeInsertMode == false and MagmaFlowSettings.nodeInsertSocket == theOuts do
				(
					MagmaFlowSettings.nodeInsertMode = true
					MagmaFlowSettings.nodeInsertSocket = 0
				)
					
				if not MagmaFlowSettings.nodeInsertMode do
				(
					if keyboard.shiftPressed then
					(
						MagmaFlowSettings.nodeInsertSocket -= 1
						if MagmaFlowSettings.nodeInsertSocket < 1 do 
						(
							MagmaFlowSettings.nodeInsertMode = true
							MagmaFlowSettings.nodeInsertSocket = theOutCounts+ 1
						)
					)
					else
					(
						MagmaFlowSettings.nodeInsertSocket += 1
						if MagmaFlowSettings.nodeInsertSocket > theOutCounts do 
						(
							MagmaFlowSettings.nodeInsertMode = true
							MagmaFlowSettings.nodeInsertSocket = 0
						)
					)
				)

				if MagmaFlowSettings.nodeInsertMode do
				(
					local done = false
					while not done do
					(
						if keyboard.shiftPressed then
						(
							MagmaFlowSettings.nodeInsertSocket -= 1
							if MagmaFlowSettings.nodeInsertSocket > 0 and theOuts[MagmaFlowSettings.nodeInsertSocket] != undefined and theOuts[MagmaFlowSettings.nodeInsertSocket].count > 0 do done = true
							if MagmaFlowSettings.nodeInsertSocket < 1 do 
							(
								MagmaFlowSettings.nodeInsertSocket = theOutCounts
								MagmaFlowSettings.nodeInsertMode = false
								done = true
							)
						)
						else
						(
							MagmaFlowSettings.nodeInsertSocket += 1
							if theOuts[MagmaFlowSettings.nodeInsertSocket] != undefined and theOuts[MagmaFlowSettings.nodeInsertSocket].count > 0 do done = true
							if MagmaFlowSettings.nodeInsertSocket > theOutCounts do 
							(
								MagmaFlowSettings.nodeInsertSocket = 1
								MagmaFlowSettings.nodeInsertMode = false
								done = true
							)
						)
					)
				)
			)
			else
				if MagmaFlowSettings.nodeInsertMode == false do 
				(
					MagmaFlowSettings.nodeInsertMode == true
					MagmaFlowSettings.nodeInsertSocket = 1 
				)
				
				if findItem #("Output","BLOPOutput") theType > 0 do 
				(
					MagmaFlowSettings.nodeInsertSocket = 0	
				)
				
			updateWireColorsOnly()
			--if update do createNodeTree init:true
			updateEditorTitle()
		)
		
		fn closeEditorDialog =
		(
			destroyDialog MagmaFlowEditor_Rollout
		)
		
		fn copySelectionToClipboard =
		(
			::magmaClipBoardId = trackId
			local theSelection = getSelectedNodes()
			local theFlowScript = MagmaFlowEditor_Functions.emitMAXScriptCode magma specificNodes:theSelection isClipboard:true editorID:trackID	
			local clipboardClass = dotNetClass "System.Windows.Forms.Clipboard" 
			clipboardClass.SetText theFlowScript
		)
		
		fn pasteSelectionFromClipboard preserveWires:false =
		(
			if keyboard.altPressed do preserveWires = true
			local clipboardClass = dotNetClass "System.Windows.Forms.Clipboard" 
			local theFlowScript = clipboardClass.GetText()
			--oldEditableBlopStack = deepCopy EditableBlopStack
			if matchPattern theFlowScript pattern:"(--MAGMAFLOW2--*" do
			(
				setSelectedNodes #()
				
				local nodeArray = magma.GetNodes()
				local oldCount = nodeArray.count
				
				::magmaNode = magma
				::magmaClipBoardId = trackId
				::magmaClipBoardPreserveWires = preserveWires
				execute theFlowScript
				--EditableBlopStack = deepCopy ::MagmaFlowEditor_EditBLOPHistory
				local averageCenter = [0,0]
				
				local nodeArray = magma.GetNodes()
				local newCount = nodeArray.count
				
				for i = oldCount+1 to newCount do
				(
					local theID = nodeArray[i]
					local thePos = magma.getNodeProperty theID "Position"
					averageCenter += thePos
				)
				if (newCount-oldCount) != 0 do averageCenter /= (newCount-oldCount)
				local theMouse = ((getMouseInSchematicView() - [MagmaFlowSettings.NodeWidth/2, 10]  - hc.pan ) / hc.zoom)
				local posOffset = theMouse  - averageCenter
				for i = oldCount+1 to newCount do
				(
					local theID = nodeArray[i]
					local thePos = magma.setNodeProperty theID "Position" ((magma.getNodeProperty theID "Position") + posOffset)
				)				
				--if oldEditableBlopStack.count > 0 do EditableBlopStack = deepCopy oldEditableBlopStack
				createNodeTree init:true
				updateEditorTitle()
				displaySelectedNodeProperties()
				updateNavigator fullUpdate:true
				debugFlow()				
				local theSelection = getSelectedNodes()
				createUndoRecord ("Paste "+theSelection.count as string + (if theSelection.count == 1 then " Node" else " Nodes") + " From Clipboard")
			)			
		)
		
		fn toggleInputsOnTheLeft =
		(
			MagmaFlowSettings.InputsOnTheLeftAll = not MagmaFlowSettings.InputsOnTheLeftAll 
			createNodeTree init:false				
			updateNavigator()			
			updateEditorTitle()
		)
		fn toggleOutputsOnTheRight =
		(
			MagmaFlowSettings.outputNodesOnRight = not MagmaFlowSettings.outputNodesOnRight
			createNodeTree init:false				
			updateNavigator()			
			--updateEditorTitle()			
		)		

		fn OpenMagmaActiveType =
		(
			NodeCreationMenuPosition = mouse.screenpos
			for i = MagmaFlowEditor_CurrentEditors.count to 1 by -1 where MagmaFlowEditor_CurrentEditors[i] != undefined and MagmaFlowEditor_CurrentEditors[i][2] == MagmaFlowEditor_Rollout do 
				::MagmaActiveType_CurrentEditorIndex = i
			local theDialogPos = getDialogPos MagmaFlowEditor_CurrentEditors[MagmaActiveType_CurrentEditorIndex][2]
			local theDialogSize = getDialogSize MagmaFlowEditor_CurrentEditors[MagmaActiveType_CurrentEditorIndex][2]
			if NodeCreationMenuPosition.x > theDialogPos.x and NodeCreationMenuPosition.y > theDialogPos.y + 40 and NodeCreationMenuPosition.x < theDialogPos.x + theDialogSize.x and NodeCreationMenuPosition.y < theDialogPos.y + theDialogSize.y do
			(
				edt_log.text = "ActiveType: Enter search pattern to list available nodes. Separator: Space=OR; Comma=AND. Up/Down Arrows=Scroll List; Enter=Done; Esc=Cancel."
				try (fileIn (FranticParticles.KrakatoaHome + "\\Scripts\\MagmaFlow_ActiveType.ms") )catch()
			)
		)		
		
-------------------------------------------------		
--KEYBOARD SHORTCUTS HANDLING
-------------------------------------------------		
		
		fn showRCMenu which =
		(
			createDepot()
			local theIndex = findItem rcmenuNames which
			if theIndex > 0 do
			(
				NodeCreationMenuPosition = mouse.screenpos
				popupmenu rcmenus[theIndex] pos:NodeCreationMenuPosition
			)
		)
		
		local keyboardDefinition = #(
			--Code, Control, Shift, type, node, parameters...
			#(8, false, false, #function, removeNode ), --Backspace
			#(8, false, true, #function, removeNodeFromFlow ), 
			
			#(32, false, false, #function, connectSelectedNodes), --Spacebar
			
			#(32, true, false, #function, OpenMagmaActiveType ), --Ctrl+Spacebar
			
			/*
			#(33, false, false, #function, selectPreviousNodeByCreationOrder),
			#(34, false, false, #function, selectNextNodeByCreationOrder),
			#(33, false, true, #function, selectParentNodesByChild),
			#(34, false, true, #function, selectChildrenNodesByParent),
			*/
			
			#(45, false, false, #function, toggleInsertMode ),
			#(45, false, true, #function, toggleInsertMode ),
			
			#(48, false, false, #inputValue, "InputValue", #integer, 0), -- zero
			#(48, true, false, #inputValue, "InputValue", #float, 0.0),
			#(48, false, true, #inputValue, "InputValue", #vector, [0,0,0]),
			#(49, false, false, #inputValue, "InputValue", #integer, 1), -- 1
			#(49, true, false, #inputValue, "InputValue", #float, 1.0),
			#(49, false, true, #inputValue, "InputValue", #vector, [1,0,0]),
			#(50, false, false, #inputValue, "InputValue", #integer, 2), -- 2
			#(50, true, false, #inputValue, "InputValue", #float, 2.0),
			#(50, false, true, #inputValue, "InputValue", #vector, [0,1,0]),
			#(51, false, false, #inputValue, "InputValue", #integer, 3), -- 3
			#(51, true, false, #inputValue, "InputValue", #float, 3.0),
			#(51, false, true, #inputValue, "InputValue", #vector, [0,0,1]),
			#(52, false, false, #inputValue, "InputValue", #integer, 4), -- 4
			#(52, true, false, #inputValue, "InputValue", #float, 4.0),
			#(52, false, true, #inputValue, "InputValue", #vector, [0,1,1]),
			#(53, false, false, #operator, "Modulo" ), -- 5
			#(53, true, false, #inputValue, "InputValue", #float, 5.0),
			#(53, false, true, #inputValue, "InputValue", #vector, [1,0,1]),
			#(54, false, false, #operator, "Power" ), -- 6
			#(54, true, false, #inputValue, "InputValue", #float, 6.0),
			#(54, false, true, #inputValue, "InputValue", #vector, [1,1,0]),
			#(55, true, false, #inputValue, "InputValue", #float, 7.0), --7
			#(55, false, true, #inputValue, "InputValue", #vector, [1,1,1]),
			#(56, true, false, #inputValue, "InputValue", #float, 8.0), --8
			#(57, true, false, #inputValue, "InputValue", #float, 9.0), --9
			
			#(65, false, false, #menu, #Arithmetic), --A
			#(65, true, false, #function, selectAllNodes), 
			#(65, false, true, #InputChannel, "InputChannel", #("Age",#("SelectionFromFaceAvg","FaceArea","FaceArea"))), 
			--#(65, true, true, #function, alignAllNodesToGrid), 
			#(65, true, true, #Output, "Output", #("Age",#("","FaceArea","FaceArea"))), 

			#(66, false, false, #menu, #BLOP),
			#(66, true, false, #operator, "Blend" ), --B
			#(66, false, true, #InputChannel, "InputChannel", #("Absorption",#("","",""))),
			#(66, true, true, #Output, "Output", #("Absorption",#("","",""))),	
			
			#(67, false, true, #InputChannel, "InputChannel", "Color"), --C
			#(67, true, false, #function, copySelectionToClipboard),
			#(67, false, false, #menu, #Convert),
			#(67, true, true, #Output, "Output", #("Color",#("","","Color"))), --C	
			
			#(68, true, false, #function, deselectAllNodes), --D
			#(68, false,true, #InputChannel, "InputChannel", #("Density",#("","",""))),
			#(68, true,true, #Output, "Output", #("Density",#("","",""))),	

			#(69, false, false, #menu, #Ember), --E
			#(69, false,true, #InputChannel, "InputChannel", #("Emission",#("","FaceElement","FaceElement"))), --E
			#(69, true,true, #Output, "Output", #("Emission",#("","FaceElement","FaceElement"))),	
			
			#(70, false, false, #menu, #Function), --F
			#(70, true, true, #operator, "ToFloat" ), 
			#(70, true, false, #operator, "Floor" ), 
			#(70, false, true, #InputChannel, "InputChannel", #("",#("","FaceIndex","FaceIndex"))),
			--#(70, true, true, #Output, "Output", #("Fire",#("","FaceIndex","FaceIndex"))),						
			
			#(71, true, false, #function, toggleSnapToGrid),
			#(71, false, true, #InputChannel, "InputChannel", #("",#("","SmoothingGroup","SmoothingGroup"))),	

			#(73, false, true, #InputChannel, "InputChannel", #("ID",#("Index","Index","Index"))), --I
			#(73, true, false, #function, invertSelection),
			--#(73, true, true, #operator, "ToInt" ), 
			#(73, false, false, #menu, #Input),
			#(73, true, true, #Output, "Output", #("ID",#("Index","Index","Index"))),	
			
			
			#(76, false, false, #menu, #Logic), --L
			#(76, false, true, #InputChannel, "InputChannel", #("LifeSpan",#("","",""))),
			#(76, true, true, #function, toggleInputsOnTheLeft),

			#(77, true, false, #operator, "Magnitude" ), --M
			#(77, false, true, #InputChannel, "InputChannel", #("TextureCoord",#("TextureCoord","",""))), --M
			#(77, true, true, #Output, "Output", #("TextureCoord",#("","","TextureCoord"))),	
			
			#(78, false, true, #InputChannel, "InputChannel", #("Normal",#("Normal","FaceNormal","Normal"))), --N
			#(78, false, false, #operator, "Normalize" ),
			#(78, true, false, #operator, "Noise" ),
			--#(78, true, true, #operator, "VecNoise" ),
			#(78, true, true, #Output, "Output", #("Normal",#("","",""))), --N	
			
			#(79, false, true, #InputChannel, "InputChannel", #("Orientation",#("","",""))), --O
			#(79, true, false, #function, addNewOutputChannel),
			#(79, false, false, #menu, #Object),
			#(79, true, true, #function, toggleOutputsOnTheRight),				
			
			
			#(80, false, true, #InputChannel, "InputChannel", #("Position",#("Position","FaceCenter","Position"))), --P
			#(80, true, false, #function, setPassThrough ),
			#(80, true, true, #Output, "Output", #("Position",#("Position","FaceCenter","Position"))),	

			#(81, false, false, #operator, "FromQuat" ), --Q
			#(81, false, true, #operator, "ToQuat" ),
			#(81, true, false, #function, closeEditorDialog ),

			#(82, true, false, #function, ReorderToggle ),--R
			#(82, true, true, #function, AcceptReorderedFlow ),
			#(82, false, false, #menu, #Trigonometry),
			
			
			#(83, false, false, #menu, #System), --S
			#(83, false, true, #InputChannel, "InputChannel", #("Selection",#("Selection","FaceSelection","Selection")) ),
			--#(81, true, false, #function, saveFlowAs ),
			#(83, true, true, #Output, "Output", #("Selection",#("Selection","FaceSelection","Selection")) ),	
			
			#(84, false, false, #menu, #Transform), --T
			#(84, false, true, #InputChannel, "InputChannel", #("Tangent",#("","",""))),
			#(84, true, true, #Output, "Output", #("Tangent",#("","",""))),		
			
			#(85, true, false, #function, selectUnconnectedNodes ),--U
			
			#(86, false, false, #menu, #Vector), --V
			--#(86, true, true, #operator, "ToVector" ),
			#(86, true, false, #function, pasteSelectionFromClipboard ),
			#(86, false, true, #InputChannel, "InputChannel", #("Velocity",#("VertexIndex","","VertexIndex"))),
			#(86, true, true, #Output, "Output", #("Velocity",#("","","VertexIndex"))),	

			#(87, true, false, #function, swapInputsOrder ), --W
			#(87, true, true, #function, swapInputsOrder ), 

			#(88, false, false, #function, resetZoomFactor ), --X
			#(88, false, true, #function, resetPanFactor ), 

			#(89, true, false, #function, redoLastStep ), --Y

			#(90, true, false, #function, undoLastStep ),  --Z
			#(90, false, true, #function, ZoomExtentsSelected ),  
			#(90, false, false, #function, ZoomExtents ),  

			#(106, false, false, #operator, "Multiply" ),
			#(107, false, false, #operator, "Add" ),
			#(109, false, false, #operator, "Subtract" ),
			#(111, false, false, #operator, "Divide" ),
			
			#(187, false, false, #operator, "Equal" ), --=
			
			#(188, false, false, #operator, "VectorCross" ), --<,
			#(188, false, true, #operator, "Less" ),
			
			#(189, false, false, #operator, "Negate" ), -- -
			
			#(190, false, false, #operator, "VectorDot" ), -->,
			#(190, false, true, #operator, "Greater" ), -->.

			#(191, false, false, #operator, "Switch" ), --/
			#(191, false, true, #operator, "Mux" ), --?

			#(192, false, true, #operator, "Curve" ), --~
			#(192, true, false, #menu, #allNodes ), --Ctrl+`
			#(192, false, false, #function, OpenMagmaActiveType ),

			#(219, false, false, #operator, "Sin" ), --[
			#(219, false, true, #operator, "ASin" ), --Shift+[
			#(220, false, false, #operator, "Tan" ), --\
			#(220, false, true, #operator, "ATan" ), --Shift+\
			#(220, true, true, #operator, "ATan2" ), --Ctrl+Shift+\
			#(221, false, false, #operator, "Cos" ), --]
			#(221, false, true, #operator, "ACos" ) --Shift+]
		)			
			
		
		on hc keyboardDown keyCode do
		(
			--print keycode
			for k in keyboardDefinition where keycode == k[1] and keyboard.ControlPressed == k[2] and keyboard.ShiftPressed == k[3] do
			(
				case k[4] of
				(
					#inputValue: createNode k[5] ValueType:k[6] defaultValue:k[7]
					#inputChannel: (
						local theChannelName = if classof k[6] == Array then
						(
							k[6][1] 
						)
						else
						(
							k[6]
						)
						if theChannelName != "" do createNode k[5] ChannelName:theChannelName
					)
					#operator: createNode k[5]
					#output: (
						local theChannelName = if classof k[6] == Array then
						(
							 k[6][1]  
						)
						else
						(
							k[6]
						)
						if theChannelName != "" do createNode k[5] ChannelName:theChannelName						
					)
					#menu: 
					(
						showRCMenu k[5]
					)
					#function: 	(k[5])()
				)
			)
		)		
			
			
		fn updateValues =
		(
			createNodeTree init:false
			try
			(
				if MagmaFlowEditor_InputValueRollout.open do --and MagmaFlowEditor_InputRollout.ddl_InputType.selection == 2 do 
					with animate off MagmaFlowEditor_InputValueRollout.updateControls()
			)catch()	
		)	
		
---------------------------------------------		
--ROLLOUT EVENT HANDLERS
---------------------------------------------		
		on chk_autoUpdateModifier changed state do 
		(
			magma.autoUpdate = state
			updateMagmaHolder()
			if state do 
			(
				updateErrorInfo()
				updateModifierName()
			)
		)
		on btn_updateModifier pressed do 
		(
			magma.autoUpdate = magma.autoUpdate
			local theNodes = for i in refs.dependentNodes magma where classof i.baseobject == KrakatoaPRTLoader do try(i.delegate.InvalidateObjectSpaceCache())catch()
			updateErrorInfo()
			createNodeTree init:true
			updateModifierName()	
		)

		
		on MagmaFlowEditor_Rollout resized val do 
		(
			hc.width = val.x-182
			hc.height = val.y-18
			
			prg_bar.pos = [val.x-178,val.y-31]
			
			edt_log.width = val.x-176-80-22
			prg_swatch.pos = [-1,val.y-18]
			prg_errorswatch.pos = [9,val.y-18]
			edt_log.pos = [20,val.y-18]
			
			btn_Undo.pos = [val.x-78-180,val.y-18]
			btn_Redo.pos = [val.x-39-180,val.y-18]			
			
			btn_RecorderToStart.pos = [val.x-178,val.y-56]
			btn_RecorderBackOneStep.pos = [val.x-178+25,val.y-56]
			chk_RecorderPlay.pos = [val.x-178+25*2,val.y-56]
			btn_RecorderForwardOneStep.pos = [val.x-178+25*3,val.y-56]
			btn_RecorderToEnd.pos = [val.x-178+25*4,val.y-56]
			btn_RecorderClose.pos = [val.x-178+25*5,val.y-56]
			
			NodePropsSR.pos = [val.x-180,21]
			NodePropsSR.height = val.y-20-100 --if KrakatoaChannelEditor_MacroRecording.count > 0 then val.y-80 else val.y-49
			bmp_navigator.pos = [val.x-180,val.y-100]
			
			chk_autoUpdateModifier.pos=[val.x-180,1] 
			btn_updateModifier.pos = [val.x-118,1] 			
			
			drawDepot init:false	lock:true
			if val.x > 100 and val.y > 100 do 
				setIniSetting (theIniFileLocation +"MagmaFlowEditor_Preferences.ini") "Editor" "Size" (val as string)
			--updateMacroRecorderControls()
			MagmaFlowEditor_Rollout.autoReorderFlow createUndo:false
			--if AutoZoomExtents do MagmaFlowEditor_Rollout.zoomExtents createUndo:false		
			if val.y > 50 do 
				MagmaFlowEditor_Functions.setEditorProperty magma "DialogSize" val
			
			updateNavigator fullUpdate:false
		)		
		
		on MagmaFlowEditor_Rollout moved val do 
		(
			if val.y < sysinfo.desktopsize.y-50 do 
			(
				setIniSetting (theIniFileLocation +"MagmaFlowEditor_Preferences.ini") "Editor" "Position" (val as string)		
				MagmaFlowEditor_Functions.setEditorProperty magma "DialogPosition" val
			)
		)			
		
		fn restoreInputsOnTheLeftSettings =
		(
			local theVal = (MagmaFlowEditor_Functions.getEditorProperty magma "InputsOnTheLeftAll")
			try(MagmaFlowSettings.InputsOnTheLeftAll = execute theVal)catch()
			local theVal =  (MagmaFlowEditor_Functions.getEditorProperty magma "InputsOnTheLeftValue")
			try(MagmaFlowSettings.InputsOnTheLeftValue = execute theVal)catch()
			local theVal = (MagmaFlowEditor_Functions.getEditorProperty magma "InputsOnTheLeftChannel")
			try(MagmaFlowSettings.InputsOnTheLeftChannel = execute theVal)catch()
			local theVal = (MagmaFlowEditor_Functions.getEditorProperty magma "InputsOnTheLeftObject")
			try(MagmaFlowSettings.InputsOnTheLeftObject = execute theVal)catch()
			local theVal = (MagmaFlowEditor_Functions.getEditorProperty magma "InputsOnTheLeftGeometry")
			try(MagmaFlowSettings.InputsOnTheLeftGeometry = execute theVal)catch()
			local theVal = (MagmaFlowEditor_Functions.getEditorProperty magma "InputsOnTheLeftParticles")
			try(MagmaFlowSettings.InputsOnTheLeftParticles = execute theVal)catch()
			local theVal = (MagmaFlowEditor_Functions.getEditorProperty magma "InputsOnTheLeftScript")
			try(MagmaFlowSettings.InputsOnTheLeftScript = execute theVal	)catch()
		)
		
		fn saveFlowToDisk =
		(
			makeDir (thePresetsFolder) all:true
			local theFileToSave = getSaveFileName filename:(thePresetsFolder+currentPreset) types:"Magma Script (*.MagmaScript)|*.MagmaScript" historyCategory:"MagmaFlows"
			if theFileToSave != undefined do
			(
				for i = 1 to magma.NumEditingBLOPs() do magma.PopEditableBLOP() --get out to top level
				local theFlowScript = MagmaFlowEditor_Functions.emitMAXScriptCode magma
				local theFileHandle = createFile theFileToSave 
				format "%\n" theFlowScript to:theFileHandle 
				close theFileHandle
				for i in EditableBlopStack do magma.pushEditableBLOP i		
				displaySelectedNodeProperties()		
				currentPreset = getFileNameFile theFileToSave
				updateModifierName()	
				needToSave = false
				updateEditorTitle()				
			)		
		)
			
		on MagmaFlowEditor_Rollout open do
		(
			local st = timestamp()

			
			for i in MagmaFlowEditor_CurrentEditors where i[2] == MagmaFlowEditor_Rollout do currentMagmaNode = magma = i[1]
				
			theUserFolder = (dotnetclass "System.Environment").GetFolderPath (dotnetclass "System.Environment+SpecialFolder").LocalApplicationData + "\\Thinkbox\\"+(MagmaFlowEditor_Functions.getProductName magma)
			makeDir theUserFolder all:true

				
			theIniFileLocation = GetDir #plugcfg
			theIniFileLocation += "\\" + (MagmaFlowEditor_Functions.getProductName magma) + "\\" 
			makeDir theIniFileLocation all:true
			
			thePresetsFolder = theUserFolder + "\\MagmaFlows\\"
			local theAlternativeFolder = getIniSetting (theIniFileLocation + "MagmaFlowEditor_Preferences.ini") "Magma" "AlternativePresetsFolder" 
			if theAlternativeFolder != "" and doesFileExist theAlternativeFolder do thePresetsFolder = theAlternativeFolder
			
			loadSettings()
			local MaxBGColor = ((colorman.getColor #background)*255) 
			if abs ((MaxBGColor as color).value - (MagmaFlowColors.EditorBackgroundColor as color).value ) > 50 do 
			(
				MagmaFlowColors.EditorBackgroundColor = MaxBGColor
				MagmaFlowColors.GridColor = MagmaFlowColors.EditorBackgroundColor + [10,10,10]
			)			
			
			loadDefaultSettings()
				
			local theSettings = MagmaFlowEditor_Functions.restoreSettingsFromMagmaHolder magma
			if theSettings != undefined do
			(
				local theVal = execute theSettings 
				for p in theVal do 
					try(setProperty MagmaFlowSettings p[1] p[2])catch()
			)
			
			DebugModeEnabled = MagmaFlowEditor_Functions.supportsDebug magma
			
			createUndoRecord ("Editor Window Opened.")
			--format "Time Until Undo Record: % ms\n" (timestamp()-st)
			
			initSchematicView()
			restorePanAndZoom()
			restoreInputsOnTheLeftSettings()
			
			--format "Time Until Create Depot: % ms\n" (timestamp()-st)

			createDepot()
			collapseBranches()
			--stampNodesByType()
			createNodeTree init:true
			showGrid MagmaFlowSettings.SnapToGrid
			initNavigator()
			updateNavigator()
			displaySelectedNodeProperties()
			chk_autoUpdateModifier.state = magma.autoUpdate
			
			updateInsertMode update:false
			
			--format "Time Until AutoReorder: % ms\n" (timestamp()-st)

			autoReorderFlow update:false
		
			needToSave = false
			updateEditorTitle()
			setUndoRedoEnable()
			--alignAllNodesToGrid()
			MagmaFlowEditor_Rollout.resized (getDialogSize MagmaFlowEditor_Rollout)
			registerTimeCallback updateValues		
				
			updateErrorInfo()
			
			--format "Time To Open Magma Editor: % ms\n" (timestamp()-st)
		)
		

		
		on MagmaFlowEditor_Rollout close do
		(
			updateModifierName()	
			try(destroyDialog MagmaFlowEditor_DebugRollout)catch()
			MagmaFlowSettings.DebugModeOn = false
			MagmaFlowEditor_Functions.storeSettingsInMagmaHolder magma MagmaFlowSettings --store all settings in AppData
			for i = 1 to magma.NumEditingBLOPs() do magma.PopEditableBLOP() --get out to top level
			saveSettings()
			closeAllCurveEditors()
			updateMagmaHolder()		
			for f in (getFiles (theIniFileLocation + "MagmaFlowUndoRecords\\UndoRecord_"+ MagmaFlowEditor_UniqueUndoID+".*"))	do deleteFile f --clear undo folder
			for i = MagmaFlowEditor_CurrentEditors.count to 1 by -1 where MagmaFlowEditor_CurrentEditors[i] != undefined and MagmaFlowEditor_CurrentEditors[i][2] == MagmaFlowEditor_Rollout do deleteItem MagmaFlowEditor_CurrentEditors i
			unregisterTimeCallback updateValues
			DisableDragAndDrop = true
		)		
	)--end rollout
	
	#(MagmaFlowEditor_Rollout,MagmaFlowEditor_Rollout_MainMenu, MagmaFlowEditor_InputValueRollout, MagmaFlowEditor_UniqueUndoID)
)--end script