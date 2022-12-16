-- Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
-- SPDX-License-Identifier: Apache-2.0
(
	--NODE DEFINITION ARRAY:
	--The node definition array contains the data used by the Compiler and the KCE.
	--It has 3 representations:
	--*Base - contains the compact version of the flow including unexpanded BlackOps. Stored in the .internalflow parameter of a KCM, used to generate the other representations.
	--*Expanded - contains the fully expanded version of the flow where all nested BlackOps are recursively expanded (BlackOps are a UI-level concept, the Compiler does not understand them). Stored in the .flow parameter of the KCM.
	--*Display (KrakatoaChannelEditor_DisplayNodeTreeData) - contains the array of nodes for editing. This one is being converted back to Base flow when updating. The Base is converted to Expanded for the Compiler to work with.
	
	-- #(
	--[1]: "Node Type",  --stores the signature of the node type - "Output", "Input", "Operator", "BlackOp" used by the Compiler and KCE. Once set, a node type cannot be changed.
	--[2] #(ConnectionIndices),  --stores the node's Input socket connections used by both the Compiler and KCE. Output connections are implicitly defined by Inputs of other nodes
	--[3] #("DataType",DataValues),  --stores the node data used by the Compiler. 
	
	--[4] #( --this array is used by the KCE editor and is NOT checked for consistency by the Compiler. Thus, it can contain arbitrary data. The records below are used internally:
	--[4][1]:[X,Y], --used by all nodes, stores the position of the node in the schematic view
	--[4][2]: Collapsed, --used by all nodes except for Output, true when collapsed, false when expanded.
	--[4][3]: Selected, --used by all nodes, stores the selected state of the node (this means that saving and loading a flow preserves selection!)
	--[4][4]:ID, --used by Input nodes to define the unique ID of the TrackView track used to store its controllers
	--[4][5]:#(Int,Float,Vector,LastGeoList) --used by Input nodes to store the last values of Integer, Float and Vector track. 
	--[4][6]:"LastScriptCode", --used by Input nodes to store the last used script
	--[4][7]:isConnected, --true when the node is connected, false when it is free-floating, causes the node to be drawn darker
	--[4][8]:"UserName" --used by all Nodes
	--[4][9]:"LastChannelType" --used by Input nodes
	--[4][10]:"Last Transform Object Name" --used by ToSpace/FromSpace Operators
	--[4][11]:"Position Locked" --allows the locking of a node to prevent moving with the mouse. RESERVED. Not implemented in the KCE yet.
	--[4][12]:"Control Exposed" --true/false - exposed to Modifier's UI or not
	--[4][13]:"BlackOp Info Array. -- stores info about the blackOp a node belongs to
	--[4][14]: Output Socket Flipped --true/false - whether the output socket is flipped or not.
	--[4][15]: Debug Default Values for Channels - array containing the default values for debugging purposes
	--[4][16]: User Notes - a string containing a user description of the node/BlackOp.
	
	--[4][17]: Integer Value Connection Controller. Undefined if no connection
	--[4][18]: Float Value Connection Controller. Undefined if no connection
	--[4][19]: Vector Value Connection Controller. Undefined if no connection
	
	--[4][20]: #(Pan, Zoom) Last Pan And Zoom values (stored in Output Node Only)
	
	
	--[5]: Enabled --stores the PassThrough/Enabled flag. When set to false, the node is disabled and if it has a first input and an output, the data is passed through. Used by Compiler and KCE
	--)
	
	global KrakatoaChannelNodeEditor_Rollout --the variable containing the KCE floating dialog.
	try(destroyDialog KrakatoaChannelNodeEditor_Rollout)catch() --if the dialog is open already, it should be closed first.
	
	global KrakatoaChannelNodeEditor_MacroRecorderEditor --the Macro Record Editor Dialog
	global KrakatoaChannelNodeEditor_MacroRecorderEditorMenu
	try(destroyDialog KrakatoaChannelNodeEditor_MacroRecorderEditor)catch()
	
	global KrakatoaChannelsModifier --this is the class of the KCM, just in case the KCM is evaluated after the KCE (should not happen, but better safe than sorry)
	global KrakatoaChannelEditor_LastUndoRecordNumber  --contains the index of the last undo record.
	if KrakatoaChannelEditor_LastUndoRecordNumber == undefined do KrakatoaChannelEditor_LastUndoRecordNumber = 0
	global KrakatoaChannelEditor_UndoRecordNames = #("") --contains the names of undo records for the current session.
	global KrakatoaChannelEditor_BaseNodeTreeData  = #() --used to store the base form of the node tree definition taken from the KCM
	global KrakatoaChannelEditor_DisplayNodeTreeData  --used to store the display form of the base node tree definition 
	global KrakatoaChannelEditor_NodeTreeData = #() --used for loading and saving of flows
	global KrakatoaChannelEditor_NodeTreeEditingLevel = #()
	global KrakatoaChannelEditor_NodeTreeEditingNames = #()
	global KrakatoaChannelEditor_NodeTreeEditingUndoLevel = #()
	global KrakatoaChannelEditor_ErrorTree = #()
	global KrakatoaChannelEditor_MacroRecording = #()
	global KrakatoaChannelEditor_PlaybackDuration = 1.0
	global KrakatoaChannelEditor_UndoRecordName = ""
	local currentMacroLine = 0
	local lastMacroFileName = ""
	
	local DebugModeOn = false
	
	global KrakatoaChannelEditor_DisableDragAndDrop = true
	
	local leftDepotMargin = 0
	local currentlyEditedBlackOpName = ""
	--global DisplayNodeTreeData = #() --stores the intermediate version of the NodeTreeData in the form for KCE display.

	
	global KrakatoaChannelNodeEditor_Rollout_MainMenu --contains the main menu bar of the KCE
	global KrakatoaChannelNodeEditor_NodeNameRollout, KrakatoaChannelNodeEditor_OperatorDescriptionRollout, KrakatoaChannelNodeEditor_OperatorRollout, KrakatoaChannelNodeEditor_ConnectorRollout, KrakatoaChannelNodeEditor_OutputConnectorRollout, KrakatoaChannelNodeEditor_ChannelDebugRollout --the rollouts used in the KCE "command panel"
	global KrakatoaChannelNodeEditor_InputRollout
	global KrakatoaChannelNodeEditor_ObjectPropertyRollout, KrakatoaChannelNodeEditor_GraphOutputRollout
	global KrakatoaChannelNodeEditor_CurveControl --the Curve operator's special rollout
	global KrakatoaChannelNodeEditor_CurrentModifier --contains the current KCM represented by the KCE
	global KrakatoaChannelsNodeEditor_GraphOutputBitmap
	global KrakatoaChannelNodeEditor_OutputGraphRange = #(-0.01,1.0,-0.2,1.2,5)
	global KrakatoaChannelNodeEditor_VectorDebugRollout,KrakatoaChannelNodeEditor_FloatDebugRollout
	global KrakatoaChannelsEditor_TheOldObjects = #()
	
	global KrakatoaChannelEditor_CurrentFloatController --the current float controller of a Value Input shown in the KCE's "command panel"
	global KrakatoaChannelEditor_CurrentIntController --the current integer controller of a Value Input shown in the KCE's "command panel"
	global KrakatoaChannelEditor_CurrentVectorController --the current vector controller of a Value Input shown in the KCE's "command panel"

	global KrakatoaChannelEditor_ModifierCallback --contains the callback function to be called when a modifier changes.
	global KrakatoaChannelEditor_PreSaveCallback --contains the callback function to be called before the scene is saved.
	global KrakatoaChannelEditor_TrackviewCleanupCallback --contains the callback function to be called pre-save to remove unused TV nodes
	global KrakatoaChannelEditor_fixDuplicatedKCMTrackIDs_Callback
	global KrakatoaChannelEditor_IsUpdatingExposure = false
	
	global KrakatoaChannelEditor_BlackOpData = #() --contains the definition data of a BlackOp
	global KrakatoaChannelEditor_ClipboardArray = #() --contains the copy/paste data 
	
	global KrakatoaChannelEditor_ExpandBLOPs = false 
	global KrakatoaChannelEditor_LastError = #(0,"") 
	
	global KrakatoaChannelNodeEditor_CurrentModifierPresetIsCustom = false
	
	local KrakatoaChannelEditor_UpdateDepot --contains the function called to update the Depot
	
	
	local AutoZoomExtents = false
	local scriptCodeAutoCheck = true
	local AutoReorderToggle = false
	local AutoReorderPattern = #row
	local AllowSocketFlipping = true
	local DeselectNodesOnInputDrop = true
	local AllowSubtreeCollapsing = false
	
	local operatorHeightConstant = true
	local useMousePositionOnCreation = false
	
	
	local KrakatoaChannelsEditor_isInitializing = false
	
	local	theBackgroundColor = color 192 192 198
	local	theGridColor = color 200 200 210	
	local SnapToGrid = true
	local GridSizeX = 10
	local GridSizeY = 10
	local NodeWidth = 140
	local NodeXSpace = 20
	local NodeYSpace = 1
	
	local theHeaderColor = color 80 80 128
	local theInputNodeColor = color 220 220 255
	local theNotesNodeColor = color 240 250 255
	
	local theOutputNodeColor = color 200 255 200
	local theOperatorNodeColor = color  255 235 200
	local theBoxNodeColor = color 255 200 180
	local theErrorNodeColor = color 255 64 64
	
	local theInputSocketColor = color 255 0 0
	local theChannelSocketColor = color 0 0 200
	local theFloatSocketColor = color 0 128 0
	local theIntegerSocketColor = color 128 0 255
	local theVectorSocketColor = color 0 255 200
	local theTimeSocketColor = color 255 255 0
	local theTextureMapSocketColor = color 255 128 128
	local theObjectSocketColor = color 128 0 0
	
	local theNodesCastShadows = false
	
	local DepotPlacement = #bottomrollupreverse
	local DepotAutoCollapseOnDragAndDrop = false
	local DepotShowBLOPs = true
	local DepotShowCategories = true
	local DepotNodeWidth = 60
	global KrakatoaChannelEditor_theDepotNodesArray  
	
	local UnconnectedNodesPlacement = #right
	local lastSelectionBeforeClick = 0
	
	local channelsList = #()
	local sortedChannelsList = #()		
	
	local nodeInsertMode = true

	
	--Make sure all folders exist:
	makeDir (GetDir #plugcfg + "\\Krakatoa")
	makeDir (Krakatoa_PresetsDirectory+ "\\MagmaFlows\\") all:true	
	makeDir (Krakatoa_PresetsDirectory+ "\\BlackOps") all:true	
	makeDir (GetDir #plugcfg + "\\Krakatoa\\MagmaFlowUndoRecords\\") all:true	
	makeDir (Krakatoa_PresetsDirectory+ "\\Macros\\") all:true	
	
	global KrakatoaChannelsEditor_Functions
	struct KrakatoaChannelsEditor_Functions 
	(
		
		fn escapeString txt =
		(
			txt = txt as string
			local newString = ""
			for i = txt.count to 1 by -1 do
			(
				if txt[i] == "\"" and i>1 and txt[i-1] != "\\" then
					newString = "\\\"" + newString
				else if txt[i] == "\n" and i>1 and txt[i-1] != "\\" then
					newString = "\\n" + newString
				else
					newString = txt[i] + newString 
			)
			newString 
		),
		
		fn purifyText txt =
		(
			local newString = ""
			for i = txt.count to 1 by -1 do 
				if txt[i] == "\\" or txt[i] == "\"" then () else newString =txt[i]+newString
			newString	
		),
		
		fn purifyChannelName txt =
		(
			local newString = ""
			for i = txt.count to 1 by -1 do
			(
				local theCode = bit.charAsInt txt[i] 
				if (theCode > 47 and theCode < 58) or (theCode > 64 and theCode < 91) or (theCode > 96 and theCode < 123) do 
					newString = txt[i] + newString
			)			
			newString	
		),		
		
		fn purifyTextScript txt =
		(
			local newString = ""
			for i = txt.count to 1 by -1 do 
				if txt[i] != "\\" do newString =txt[i]+newString
			newString	
		),		
		
		fn createTrackViewControllers nodeID theNode =
		(
			--print "createTrackViewControllers Called..." 
			theRootNode = try(trackViewNodes.KrakatoaChannelEditor)catch(newTrackViewNode "KrakatoaChannelEditor")
			theID = KrakatoaChannelNodeEditor_CurrentModifier.trackID
			--format "createTrackViewControllers Called with ID %\n" theID 
			theModTrack = try(execute ("trackViewNodes.KrakatoaChannelEditor.KCE_"+theID))catch(newTrackViewNode theRootNode ("KCE_"+theID))
			theNodeTrack = try(execute ("trackViewNodes.KrakatoaChannelEditor.KCE_"+theID+".Input_"+nodeID as string))catch(newTrackViewNode theModTrack ("Input_"+nodeID as string) )
				
			try
			(
				theIntController = theNodeTrack[1].controller 
			)
			catch
			(
				theIntController = float_list() --bezier_Float()
				addTrackViewController  theNodeTrack theIntController "Integer"
				theIntController[1].controller = bezier_Float()
				try(theIntController[1].controller.value = theNode[4][5][1])catch()
			)
			
			try
			(
				local theExpr = try(execute theNode[4][17])catch(undefined)
				if theExpr != undefined do
				(
					local theFloatScript = float_script()
					theFloatScript.AddTarget "KCE_Reference" theExpr
					theFloatScript.SetExpression "KCE_Reference" 
					theNodeTrack[1].controller[2].controller = theFloatScript
				)
			)catch()		
			
			try
			(
				theFloatController = theNodeTrack[2].controller
			)
			catch
			(
				theFloatController = Float_List()
				addTrackViewController  theNodeTrack theFloatController "Float" 
				theFloatController[1].controller = bezier_float()
				try(theFloatController[1].controller.value = theNode[4][5][2])catch()
			)
			
			try
			(
				local theExpr = try(execute theNode[4][18])catch(undefined)
				if theExpr != undefined do
				(
					local theFloatScript = float_script()
					theFloatScript.AddTarget "KCE_Reference" theExpr
					theFloatScript.SetExpression "KCE_Reference" 
					theNodeTrack[2].controller[2].controller = theFloatScript
				)
			)catch()
			
			--VECTOR CONTROLLER
			try
			(
				theVectorController = theNodeTrack[3].controller
			)
			catch
			(
				theVectorController = point3_list()
				addTrackViewController theNodeTrack theVectorController "Vector" 
				theVectorController[1].controller = point3_xyz()
				theVectorController[2].controller = Point3_XYZ()
				try(theVectorController[1].controller.value = theNode[4][5][3])catch()
			)

			try
			(
				local theExpr = try(execute theNode[4][19])catch(undefined)
				if theExpr != undefined do
				(
					local theFloatScript = float_script()
					theFloatScript.AddTarget "KCE_Reference" theExpr
					theFloatScript.SetExpression "KCE_Reference.x" 
					if classof theVectorController == Point3_List then
						theVectorController[2].controller[1].controller = theFloatScript
					else
						theVectorController[1].controller = theFloatScript

					local theFloatScript = float_script()
					theFloatScript.AddTarget "KCE_Reference" theExpr
					theFloatScript.SetExpression "KCE_Reference.y" 
					if classof theVectorController == Point3_List then
						theVectorController[2].controller[2].controller = theFloatScript
					else
						theVectorController[2].controller = theFloatScript
					
					
					local theFloatScript = float_script()
					theFloatScript.AddTarget "KCE_Reference" theExpr
					theFloatScript.SetExpression "KCE_Reference.z" 
					if classof theVectorController == Point3_List then
						theVectorController[2].controller[3].controller = theFloatScript
					else
						theVectorController[3].controller = theFloatScript
				)			
			)catch()
			
			"trackViewNodes.KrakatoaChannelEditor.KCE_"+theID+".Input_"+nodeID as string
		),	
		
		fn copyControllersOnClone theSourceModifier theTargetModifier =
		(
			if theSourceModifier != undefined and theTargetModifier != undefined do 
			(
				local theRootNode = try(trackViewNodes.KrakatoaChannelEditor)catch(newTrackViewNode "KrakatoaChannelEditor")
				local theSourceID = theSourceModifier.trackID
				local theTargetID = theTargetModifier.trackID
				local theSourceModTrack = try(execute ("trackViewNodes.KrakatoaChannelEditor.KCE_"+theSourceID))catch(newTrackViewNode theRootNode ("KCE_"+theSourceID))
				local theTargetModTrack = try(execute ("trackViewNodes.KrakatoaChannelEditor.KCE_"+theTargetID))catch(newTrackViewNode theRootNode ("KCE_"+theTargetID))
				local theCount = amin #(theSourceModTrack.numsubs, theTargetModTrack.numsubs)
				for i = 1 to theSourceModTrack.numsubs do
				(	
					local theTrackName = theSourceModTrack[i].name as name
					local theTargetTrack = theTargetModTrack[theTrackName]
					if theTargetTrack != undefined then
					(
						for j = 1 to 3 do
						(
							local theSourceController = theSourceModTrack[i][j].controller
							if classof theSourceController == Float_List then
							(
								try(theTargetTrack[j].controller[1].controller = copy theSourceController[1].controller)catch()
								try(if (classof theSourceController[2].controller) != float_ListDummyEntry do theTargetTrack[j].controller[2].controller = copy theSourceController[2].controller)catch()
								try(theTargetTrack[j].weight = theSourceController.weight)catch()
							)
							else if classof theSourceController == Point3_List then
							(
								try(theTargetTrack[j].controller[1].controller = copy theSourceController[1].controller)catch()
								try(if (classof theSourceController[2].controller) != float_ListDummyEntry do theTargetTrack[j].controller[2].controller = copy theSourceController[2].controller)catch()
								try(theTargetTrack[j].weight = theSourceController.weight)catch()
							)
							else if classof theTargetTrack[j].controller == Float_List then
							(
								try(theTargetTrack[j].controller[1].controller = copy theSourceController)catch()
								try(theTargetTrack[j].controller[2].controller = bezier_float())catch()
								try(theTargetTrack[j].weight = #(100,0))catch()	
							)
							else if classof theTargetTrack[j].controller == Point3_List then
							(
								try(theTargetTrack[j].controller[1].controller = copy theSourceController)catch()
								try(theTargetTrack[j].controller[2].controller = Point3_XYZ())catch()
								try(theTargetTrack[j].weight = #(100,0))catch()	
							)
						)	
					)
					--else	format "Source Track % has no target.\n" theTrackName
				)	
			)	
		),
		
		--The following function is used to ensure all IDs are updated when loading flows, BLOPs etc.
		fn fixFlowIDsAfterLoading theArray=
		(
			--format "fixFlowIDsAfterLoading Called with current modifier %\n" KrakatoaChannelNodeEditor_CurrentModifier
			for i = 1 to theArray.count do
			(
				if theArray[i][1] == "Output" then
					theArray[i][4][8] = "Output"
				else if theArray[i][1] == "BlackOp" then
				(
					theArray[i][3][2] = KrakatoaChannelsEditor_Functions.fixFlowIDsAfterLoading theArray[i][3][2] --recursively fix BLOP
				)
				else if theArray[i][1] == "Input" then
				(
					local theID = (theArray[i][4][4])					
					if theID == undefined do 
					(
						theArray[i][4][4] = theID = (random 10000 1000000) as string + "_" + (random 10000 1000000) as string
					)	
					if theArray[i][3][1] != "Channel" and theArray[i][3][1] != "TextureMap" do
						theArray[i][3][3] = KrakatoaChannelsEditor_Functions.createTrackViewControllers theID theArray[i]
					if theArray[i][3][1] == "Time" or theArray[i][3][1] == "Script" do 
						try(deleteItem theArray[i][3] 3)catch()
				)	
				else
					if theArray[i][1] != "Operator"  and theArray[i][3][3] != undefined do 
						deleteItem theArray[i][3] 3	
			)
			theArray
		),
		fn navigateToErrorModifier =
		(
			if KrakatoaChannelEditor_LastError[1] > 0 do
			(
				local theClasses = getClassInstances KrakatoaChannelsModifier 
				--join theClasses (for m in (getClassInstances Krakatoa_CustomData) collect m.MagmaHolder)
				local theModErrors = (for m in theClasses where m.trackId == KrakatoaChannelEditor_LastError[3] collect m)
				if theModErrors.count == 1 do 
				(
					max modify mode
					modPanel.setCurrentObject theModErrors[1]
					if KrakatoaChannelEditor_ErrorTree.count > 0 do
					(
						for i = KrakatoaChannelEditor_NodeTreeEditingLevel.count+1 to KrakatoaChannelEditor_ErrorTree.count-1 do
						(
							KrakatoaChannelsEditor_Functions.EditBlop KrakatoaChannelEditor_ErrorTree[i]
						)
					)
					--TODO: Navigate to deepest error level
				)
			)
		),
		fn displayError ErrorNodeIndex compilerError trackID =
		(
			--format "ERROR: % % % %\n" ErrorNodeIndex compilerError trackID  KrakatoaChannelNodeEditor_CurrentModifier.trackID
			try
			(
				KrakatoaChannelEditor_LastError = #(ErrorNodeIndex,compilerError,trackID)
				if ErrorNodeIndex > 0 then 
				(
					if trackID == KrakatoaChannelNodeEditor_CurrentModifier.trackID then
					(
						local theErrorNode = KrakatoaChannelEditor_LastError[1]
						KrakatoaChannelEditor_BaseNodeTreeData = execute (KrakatoaChannelNodeEditor_CurrentModifier.internalFlow ) --unexpanded flow
						local theNumberOfBlackOps = (for i in KrakatoaChannelEditor_BaseNodeTreeData where i[1] == "BlackOp" collect i).count
						KrakatoaChannelEditor_NodeTreeData = (execute KrakatoaChannelNodeEditor_CurrentModifier.flow) --the expanded flow
						global KrakatoaChannelEditor_ErrorTree = KrakatoaChannelEditor_NodeTreeData[theErrorNode][4][13]
						local theErrorMessage = (localtime +": ERROR in Current Flow, ")
						
						local theFlow = deepCopy KrakatoaChannelEditor_BaseNodeTreeData
						for i = 1 to KrakatoaChannelEditor_ErrorTree.count do 
						(
							theRootNode = theFlow[KrakatoaChannelEditor_ErrorTree[i]]
							local theType = case theRootNode[1] of
							(
								"BlackOp": "BLOP"
								"Operator": "OP"
								"Input": "IN"
								"Output": "OUT"
								"Connector": "CON"
								default: "???"
							)
							theErrorMessage += "[" + KrakatoaChannelEditor_ErrorTree[i] as string + " " + theType + ":" + theRootNode[4][8] + "], "
							theFlow = theRootNode[3][2]
						)
						theErrorMessage += KrakatoaChannelEditor_LastError[2]
						KrakatoaChannelNodeEditor_Rollout.lbx_log.items = append KrakatoaChannelNodeEditor_Rollout.lbx_log.items theErrorMessage
					)	
					else
					(
						local theClasses = getClassInstances KrakatoaChannelsModifier
						try(join theClasses (for m in getClassInstances Krakatoa_CustomData collect m.MagmaHolder))catch()
						local theModErrors = (for m in theClasses where try(m.LastErrorNode != 0)catch(false) collect m)
						for m in theModErrors do
						(
							local theModName = case classof KrakatoaChannelNodeEditor_CurrentModifier of
							(
								KrakatoaChannelsModifier: "Modifier ["+ m.name +"]"
								MagmaHolder: 
								(
									local result = "Data Render Element"
									local re = maxops.getRenderElementMgr #production
									for i = 0 to (re.NumRenderElements()-1) do
									(
										local el =re.getRenderElement i
										if classof el == Krakatoa_CustomData and el.MagmaHolder == KrakatoaChannelNodeEditor_CurrentModifier do result =  el.elementName
									)
									result
								)
								default:"???"
							)
							KrakatoaChannelNodeEditor_Rollout.lbx_log.items = append KrakatoaChannelNodeEditor_Rollout.lbx_log.items (localtime +": ERROR In Node " + m.ErrorNodeIndex as string + " of "+theModName+" ID:("+m.trackID as string+") : " + m.compilerError) 
						)
					)	
				)	
				KrakatoaChannelNodeEditor_Rollout.lbx_log.selection = KrakatoaChannelNodeEditor_Rollout.lbx_log.items.count
				KrakatoaChannelNodeEditor_Rollout.createNodeTree init:false
			)
			catch
			(
				KrakatoaChannelNodeEditor_Rollout.lbx_log.items = #("Failed to get the Compiler Error from Holder Object")
				KrakatoaChannelNodeEditor_Rollout.lbx_log.selection = KrakatoaChannelNodeEditor_Rollout.lbx_log.items.count
			)
		),
		
		fn updateParentModifier commitBlop:true suppressRedraw:false =
		(
			local theClasses = getClassInstances KrakatoaChannelsModifier
			try(join theClasses (for m in getClassInstances Krakatoa_CustomData collect m.MagmaHolder))catch()
			for m in theClasses do try(m.LastErrorNode = 0)catch()	--clear all errors in all modifiers		
			if KrakatoaChannelEditor_NodeTreeEditingLevel.count > 0 do 
			(
				return false --won't update when in BlackOp editing mode
			)	
			try(
				--store last pan and zoom:
				KrakatoaChannelEditor_DisplayNodeTreeData[1][4][20] = #(KrakatoaChannelNodeEditor_Rollout.hc.pan, KrakatoaChannelNodeEditor_Rollout.hc.zoom)
				--format "Storing Last Pan And Zoom Before Updating Modifier: %\n" KrakatoaChannelEditor_DisplayNodeTreeData[1][4][20]
				
				KrakatoaChannelEditor_NodeTreeData = deepCopy KrakatoaChannelEditor_DisplayNodeTreeData
				for i = 1 to KrakatoaChannelEditor_NodeTreeData.count where KrakatoaChannelEditor_NodeTreeData[i][3][1] == "Script" do
						KrakatoaChannelEditor_NodeTreeData[i][3][2] = KrakatoaChannelEditor_NodeTreeData[i][4][6] = (KrakatoaChannelsEditor_Functions.escapeString KrakatoaChannelEditor_NodeTreeData[i][4][6])
				with printAllElements on KrakatoaChannelNodeEditor_CurrentModifier.internalFlow = (KrakatoaChannelEditor_NodeTreeData as string)
				KrakatoaChannelEditor_BaseNodeTreeData = execute (KrakatoaChannelNodeEditor_CurrentModifier.internalFlow )
				KrakatoaChannelNodeEditor_CurrentModifier.flow = KrakatoaChannelsEditor_Functions.expandFlow KrakatoaChannelNodeEditor_CurrentModifier.internalFlow fixTracks:true
				if not KrakatoaChannelNodeEditor_CurrentModifier.AutomaticRenameOFF do 
				(
					if superclassof KrakatoaChannelNodeEditor_CurrentModifier == modifier then
					(
						KrakatoaChannelNodeEditor_CurrentModifier.name = "KCM_"+ KrakatoaChannelEditor_BaseNodeTreeData[1][3][1]
					)
					else
					(
						--do nothing for Render Elements for now...
					)
					KrakatoaChannelsEditor_Functions.updateEditorTitle()
				)
				if KrakatoaChannelNodeEditor_CurrentModifierPresetIsCustom == true and KrakatoaChannelNodeEditor_CurrentModifier.currentPreset != "Custom" do
				(
					KrakatoaChannelNodeEditor_CurrentModifier.currentPreset = "Custom"
					KrakatoaChannelNodeEditor_CurrentModifier.main_rollout.ddl_currentPreset.selection = 1
				)
			)catch()	
			if KrakatoaChannelEditor_LastError[1] == 0 do KrakatoaChannelNodeEditor_Rollout.lbx_log.items = #()
			KrakatoaChannelEditor_LastError = #(0,"","")
			if not suppressRedraw do KrakatoaChannelNodeEditor_Rollout.createNodeTree init:false
		),
		
		fn saveFlow theFilename =
		(
			for i = 1 to KrakatoaChannelEditor_BaseNodeTreeData.count where KrakatoaChannelEditor_BaseNodeTreeData[i][3][1] == "Script" do
					KrakatoaChannelEditor_BaseNodeTreeData[i][3][2] = KrakatoaChannelEditor_BaseNodeTreeData[i][4][6] = (KrakatoaChannelsEditor_Functions.escapeString KrakatoaChannelEditor_BaseNodeTreeData[i][4][6])
			
			if KrakatoaChannelNodeEditor_CurrentModifier.TextureMapSources.count > 0 do
			(
				local theMatLib = materialLibrary ()
				local theMatLibName = (getFileNamePath theFilename + getFileNameFile theFilename + ".mat")
				for m in KrakatoaChannelNodeEditor_CurrentModifier.TextureMapSources do
					append theMatLib m
				saveTempMaterialLibrary theMatLib theMatLibName 
			)
				
			local theFileHandle = createFile theFileName
			with PrintAllElements true	format "global KrakatoaChannelEditor_NodeTreeData = %\n" KrakatoaChannelEditor_BaseNodeTreeData to:theFileHandle 
			close theFileHandle

			KrakatoaChannelEditor_BaseNodeTreeData = execute ( with PrintAllElements true KrakatoaChannelEditor_BaseNodeTreeData as string)
			KrakatoaChannelsEditor_Functions.buildDisplayTree()
		),
		
		fn buildDisplayTree =
		(
			if KrakatoaChannelEditor_NodeTreeEditingLevel.count == 0 then
			(
				KrakatoaChannelEditor_DisplayNodeTreeData = deepCopy KrakatoaChannelEditor_BaseNodeTreeData 
			)
			else
			(
				KrakatoaChannelEditor_NodeTreeData = deepCopy KrakatoaChannelEditor_BaseNodeTreeData
				for j = 1 to KrakatoaChannelEditor_NodeTreeEditingLevel.count do
					KrakatoaChannelEditor_NodeTreeData = (KrakatoaChannelEditor_NodeTreeData[KrakatoaChannelEditor_NodeTreeEditingLevel[j]][3][2])
				KrakatoaChannelEditor_DisplayNodeTreeData = deepCopy KrakatoaChannelEditor_NodeTreeData
				for i = 1 to KrakatoaChannelEditor_DisplayNodeTreeData.count do
				(
					if KrakatoaChannelEditor_DisplayNodeTreeData[i][1] == "Connector" do KrakatoaChannelEditor_DisplayNodeTreeData[i][4][8] = KrakatoaChannelEditor_DisplayNodeTreeData[i][3][1]
					if KrakatoaChannelEditor_DisplayNodeTreeData[i][1] == "OutputConnector" do KrakatoaChannelEditor_DisplayNodeTreeData[i][4][8] = KrakatoaChannelEditor_DisplayNodeTreeData[i][3][1]
					--if KrakatoaChannelEditor_DisplayNodeTreeData[i][4][1] != undefined do KrakatoaChannelEditor_DisplayNodeTreeData[i][4][1] += [300,100]
				)
			)
		),
		
		fn commitChangesToBLOP =
		(
			txt = "KrakatoaChannelEditor_BaseNodeTreeData"
			for j = 1 to KrakatoaChannelEditor_NodeTreeEditingLevel.count do
			(
				txt += "["+KrakatoaChannelEditor_NodeTreeEditingLevel[j] as string +"][3][2]"
			)
			txt += "= KrakatoaChannelEditor_DisplayNodeTreeData"
			execute txt			
		),
		
		fn endEditingBLOP type:#yesnocancel=
		(
			if KrakatoaChannelEditor_NodeTreeEditingUndoLevel[KrakatoaChannelEditor_NodeTreeEditingUndoLevel.count] != KrakatoaChannelEditor_LastUndoRecordNumber do
			(
				local q = case type of
				(
					#yesnocancel: yesnocancelbox "Do you want to keep the changes to this BlackOp?\n\nClick [Yes] to commit the changes to the BlackOp.\nClick [No] to discard any changes made in this Edit BlackOp session.\nClick [Cancel] to continue Editing..." title:"Exit BlackOp Editing Mode"
					#yesno: querybox "Do you want to keep the changes to this BlackOp?\n\nClick [Yes] to commit the changes to the BlackOp.\nClick [No] to discard any changes made in this Edit BlackOp session." title:"Exit BlackOp Editing Mode"
				)	
				case q of
				(
					#yes: 
					(
						KrakatoaChannelEditor_DisplayNodeTreeData[1][4][20] = #(KrakatoaChannelNodeEditor_Rollout.hc.pan, KrakatoaChannelNodeEditor_Rollout.hc.zoom)					
						--format "Storing Last Pan And Zoom Before Ending BLOP Editing: %\n" KrakatoaChannelEditor_DisplayNodeTreeData[1][4][20]
						txt = "KrakatoaChannelEditor_BaseNodeTreeData"
						for j = 1 to KrakatoaChannelEditor_NodeTreeEditingLevel.count do
						(
							txt += "["+KrakatoaChannelEditor_NodeTreeEditingLevel[j] as string +"][3][2]"
						)
						txt += "= KrakatoaChannelEditor_DisplayNodeTreeData"
						execute txt
					)
					#no: ()
					#cancel: (return false)
				)
			)
			
			deleteItem KrakatoaChannelEditor_NodeTreeEditingLevel KrakatoaChannelEditor_NodeTreeEditingLevel.count
			deleteItem KrakatoaChannelEditor_NodeTreeEditingUndoLevel KrakatoaChannelEditor_NodeTreeEditingUndoLevel.count
			deleteItem KrakatoaChannelEditor_NodeTreeEditingNames KrakatoaChannelEditor_NodeTreeEditingNames.count

			
			KrakatoaChannelsEditor_Functions.buildDisplayTree()
			KrakatoaChannelNodeEditor_Rollout.createDepot()
			KrakatoaChannelsEditor_Functions.KrakatoaChannelEditor_UpdateDepot()
			
			--format "END BLOP EDIT PREVIOUS LEVEL Pan And Zoom: %\n" KrakatoaChannelEditor_DisplayNodeTreeData[1][4][20]
			KrakatoaChannelNodeEditor_Rollout.restoreLastKnownPanAndZoom() --RESTORE PAN AND ZOOM
			
			KrakatoaChannelsEditor_Functions.updateParentModifier()
			KrakatoaChannelNodeEditor_Rollout.createNodeTree init:true
			
			
			if AutoReorderToggle do KrakatoaChannelNodeEditor_Rollout.autoReorderFlow()
			if AutoZoomExtents do KrakatoaChannelNodeEditor_Rollout.zoomExtents createUndo:false	
			KrakatoaChannelNodeEditor_Rollout.createUndoRecord "End BlackOp Editing"		
			KrakatoaChannelsEditor_Functions.updateEditorTitle()						
			KrakatoaChannelNodeEditor_Rollout.displaySelectedNodeProperties()
			
			
			KrakatoaChannelsEditor_Functions.exposeControlsToModifier KrakatoaChannelNodeEditor_CurrentModifier
		),	
		
		fn EditBlop theBlopNode =
		(
			local q = true
			if KrakatoaChannelEditor_NodeTreeEditingLevel.count > 0 and KrakatoaChannelEditor_NodeTreeEditingUndoLevel[KrakatoaChannelEditor_NodeTreeEditingUndoLevel.count] != KrakatoaChannelEditor_LastUndoRecordNumber then
			(
				q = querybox "Editing a nested BlackOp will cause the current BlackOp changes to be COMMITTED!\n\nClick [Yes] to commit changes and edit the nested BlackOp.\nClick [No] to remain at the current BlackOp editing level without committing any changes." title:"Edit Nested BlackOp Commit Changes"
				if q do KrakatoaChannelsEditor_Functions.commitChangesToBLOP()
			)	
			else
				KrakatoaChannelsEditor_Functions.updateParentModifier()
			
			if q do
			(
				currentlyEditedBlackOpName = KrakatoaChannelEditor_DisplayNodeTreeData[theBlopNode][4][8]
				append KrakatoaChannelEditor_NodeTreeEditingLevel theBlopNode
				append KrakatoaChannelEditor_NodeTreeEditingUndoLevel (KrakatoaChannelEditor_LastUndoRecordNumber+1)
				append KrakatoaChannelEditor_NodeTreeEditingNames currentlyEditedBlackOpName
				KrakatoaChannelsEditor_Functions.updateEditorTitle()
				KrakatoaChannelsEditor_Functions.buildDisplayTree()
				KrakatoaChannelNodeEditor_Rollout.createDepot()
				KrakatoaChannelsEditor_Functions.KrakatoaChannelEditor_UpdateDepot()
				KrakatoaChannelNodeEditor_Rollout.createNodeTree init:true
				
				
				if AutoReorderToggle do KrakatoaChannelNodeEditor_Rollout.autoReorderFlow createUndo:false	
				if AutoZoomExtents do KrakatoaChannelNodeEditor_Rollout.zoomExtents createUndo:false	
				KrakatoaChannelNodeEditor_Rollout.displaySelectedNodeProperties()
				KrakatoaChannelNodeEditor_Rollout.createUndoRecord "Edit BlackOp"	
				
				--format "BLOP Pan And Zoom: %\n" KrakatoaChannelEditor_DisplayNodeTreeData[1][4][20] 
				KrakatoaChannelNodeEditor_Rollout.restoreLastKnownPanAndZoom() --RESTORE PAN AND ZOOM
			)			
		),		
		
			
		fn expandFlow theFlow specificNode:0 deleteBlop:true fixTracks:false =
		(
			local st = timestamp()
			
			-- For every BlackOp
			--+ Collect all SubOps and put at the end of the array
			--+ Renumber their internal links to match the new offset
			--+ Reconnect those pointing at Connectors to connect to the links listed in the same order in [2]
			--+ Delete the original BlackOp node 
			--+ Renumber all links above it to keep the connections
			-- Repeat
			
			local theConvertedFlow = execute (theFlow) --convert the string property to a MAXScript Array
			for i = 1 to theConvertedFlow.count do theConvertedFlow[i][4][13] = #(i) --index all nodes in the top array
			local notDone = true
			local theDeletedBlopsCount = 0
			while notDone do
			(
				notDone = false
				for i = 1 to theConvertedFlow.count do
				(
					local theRule = if specificNode > 0 then specificNode  == i and theConvertedFlow[i][1] == "BlackOp" else try(theConvertedFlow[i][1] == "BlackOp" )catch(false)
					if theRule then --if the node is a blackop
					(
						notDone = true --raise the flag that we are not done yet
						local basePos = theConvertedFlow[i][4][1] 
						local theNode = deepcopy theConvertedFlow[i][3][2] --copy the blackop definition
						local theOldCount = theConvertedFlow.count --store the number of nodes before expansion
						local theOutputConnector = 0
						for j = 1 to theNode.count do --go through all nodes in the BlackOps def
						(
							if theNode[j][1] == "Operator" and theConvertedFlow[i][5] == false do theNode[j][5] = false --if BlackOp set to PassThrough, do the same for all its Operators
								
							theNode[j][4][13] = deepCopy theConvertedFlow[i][4][13] --get the navigation array of the parent 
							append theNode[j][4][13] j --and store the parent of this node for error display
							
							try(theNode[j][4][1] += basePos-[300,100])catch()
							
							for c = 1 to theNode[j][2].count where theNode[j][2][c] != undefined and theNode[j][2][c] > 0 do
								theNode[j][2][c] += theOldCount
							if theNode[j][1] == "OutputConnector" do theOutputConnector = theNode[j][2][1]
						)	
						join theConvertedFlow theNode --add the content of the BLOP to the top level array
						
						--go through all nodes and see who was connected to the BLOP. Reconnect to the BLOP node that was connected to the Output Connector
						if theOutputConnector > 0 do						
							for k = 1 to theOldCount do
								for c = 1 to theConvertedFlow[k][2].count where theConvertedFlow[k][2][c] == i do theConvertedFlow[k][2][c] = theOutputConnector
								
						--collect all Connectors
						local theConnectors = for j = theOldCount+1 to theConvertedFlow.count where theConvertedFlow[j][1] == "Connector" collect j
							
						for c = 1 to theConnectors.count do
						(
							if theConvertedFlow[i][2][c] == undefined do theConvertedFlow[i][2][c] = 0 --reset all connections of the BLOP itself that are not connected yet
							local theConnectorIndex = theConnectors[c] --contains the connector node index
							local theNodeToConnect1 = theConvertedFlow[i][2][c] --points at a node in original flow that should be connected to the expanded node
							for j = theOldCount+1 to theConvertedFlow.count do 
								for k = 1 to theConvertedFlow[j][2].count do
									if theConvertedFlow[j][2][k] == theConnectorIndex do
										theConvertedFlow[j][2][k] = theNodeToConnect1
						)
						
						--delete the connector nodes from the expanded flow:
						for j = theConvertedFlow.count to theOldCount+1 by -1 do
						(
							if theConvertedFlow[j][1] == "Connector" or theConvertedFlow[j][1] == "OutputConnector" do 
							(
								deleteItem theConvertedFlow j --delete the connector node									
								for k = 1 to theConvertedFlow.count do --then go though all nodes on the list and if they were connecting to the 
									for c = 1 to theConvertedFlow[k][2].count where theConvertedFlow[k][2][c] != undefined and theConvertedFlow[k][2][c] >= j do 
										theConvertedFlow[k][2][c] -= 1
							)
						)--end j loop
						
						deleteItem theConvertedFlow i  --delete the original BLOP
						--now renumber all connections in all nodes pointing at nodes above the deleted one by subtracting 1:
						for j = 1 to theConvertedFlow.count do
							for c = 1 to theConvertedFlow[j][2].count where theConvertedFlow[j][2][c] != undefined and theConvertedFlow[j][2][c] >= i do 
								theConvertedFlow[j][2][c] -= 1
					)--end if theRule	
				)
			)--end while	
			if fixTracks do KrakatoaChannelsEditor_Functions.fixFlowIDsAfterLoading theConvertedFlow
			--format "Flow Conversion: % ms.\n" (timestamp()-st)
			with printAllElements true theConvertedFlow as string
		),
		
		fn updateEditorTitle =
		(
			local theName = case classof KrakatoaChannelNodeEditor_CurrentModifier of
			(
				default: KrakatoaChannelNodeEditor_CurrentModifier.name
				MagmaHolder: 
				(
					local result = "Data Render Element"
					local re = maxops.getRenderElementMgr #production
					for i = 0 to (re.NumRenderElements()-1) do
					(
						local el =re.getRenderElement i
						if classof el == Krakatoa_CustomData and el.MagmaHolder == KrakatoaChannelNodeEditor_CurrentModifier do result =  el.elementName
					)
					result
				)
			)
			local txt = "Krakatoa MagmaFlow Editor - ID:" + KrakatoaChannelNodeEditor_CurrentModifier.trackID as string + " - ["+ theName+"]"
			if KrakatoaChannelEditor_NodeTreeEditingLevel.count > 0 do 
			(
				txt += " - BlackOp "
				for j = 1 to KrakatoaChannelEditor_NodeTreeEditingLevel.count do txt += "["+ KrakatoaChannelEditor_NodeTreeEditingLevel[j] as string + ":" + KrakatoaChannelEditor_NodeTreeEditingNames[j] + "]>"
			)		
			if classof KrakatoaChannelNodeEditor_CurrentModifier == MagmaHolder do txt+= " - Render Element"
			txt += " - " + (if nodeInsertMode then "INSERT" else "BRANCH")
			KrakatoaChannelNodeEditor_Rollout.title = txt
		),		
		
		fn KrakatoaChannelEditor_UpdateDepot =
		(
			if KrakatoaChannelNodeEditor_CurrentModifier != undefined do
			(
				KrakatoaChannelNodeEditor_Rollout.updateDepotDefinition()
				KrakatoaChannelNodeEditor_Rollout.createNodeTree init:true
				setFocus KrakatoaChannelNodeEditor_Rollout.hc		
			)
		),
		
		fn loadChannelsList mode:#input=
		(
			channelsList = #(	
				#("Position", "float32", 3, "Particle Position"),
				#("Velocity", "float16", 3, "Particle Velocity units/sec."),
				#("Density", "float16", 1, "Particle Density"),
				#("Color", "float16", 3 , "Scatter Color/Max Vertex Color"),
				#("Absorption", "float16", 3, "Absorption Color"),
				#("Emission", "float16", 3, "Emission Color"),
				#("Eccentricity", "float16", 1, "Shading:Phase Eccentricity"),
				#("SpecularPower", "float16", 1, "Phong Shading: Spec.Power"),
				#("SpecularLevel", "float16", 1, "Phong Shading: Spec.Level"),
				#("Normal", "float16", 3, "Normal Vector (X Axis)"),
				#("Tangent", "float16", 3, "Tangent Vector (Y Axis)"),
				#("TextureCoord", "float16", 3, "3ds Max Mapping Channel 1"),
				#("Selection", "float16", 1, "Soft-Selection Weight"),
				#("Age", "float32", 1, "Particle Age"),
				#("LifeSpan", "float32", 1, "Particle Life Span"),
				#("ID", "int32", 1, "Particle ID"),
				#("MtlIndex","int32", 1, "PFlow Particle Material ID"),
				#("MXSInteger", "int32", 1, "PFlow Scripted Integer Channel"),
				#("MXSFloat", "float32", 1, "PFlow Scripted Float Channel"),
				#("MXSVector", "float16", 3, "PFlow Scripted Vector Channel"),
				#("Orientation", "float16", 4, "Particle Quaternion Orientation"),
				#("Scale", "float16", 3, "Particle Scale"),
				#("Acceleration", "float16", 3, "Particle Acceleration"),
				#("SignedDistance", "float16", 1, "Distance To Geo.Surface"),
				#("HairRoot", "float32", 3, "PRT Hair Root Pos."),
				#("HairLength", "float16", 1, "PRT Hair Length"),
				#("Distance", "float16", 1, "PRT Hair Dist. From Root"),
				#("ReferencePosition", "float32", 3, "PRT Hair Ref. Position"),				
				#("DensityGradient", "float16", 3, "PRT FumeFX Density Gradient"),
				#("Fuel", "float16", 1, "FumeFX Fuel Channel"),
				#("Fire", "float16", 1, "FumeFX Fire Channel"),
				#("Temperature", "float16", 1, "FumeFX/RealFlow Temperature"),
				#("Force", "float32", 3, "RealFlow Force Channel"),
				#("Vorticity", "float32", 3, "RealFlow Vorticity Channel"),
				#("NeighborCount", "int32", 1, "RealFlow Neighbor Count"),
				#("IsolationTime", "float32", 1, "RealFlow Isolation Time"),
				#("Viscosity", "float32", 1, "RealFlow Viscosity"),
				#("Pressure", "float32", 1, "RealFlow Pressure"),
				#("Mass", "float32", 1, "RealFlow Mass"),
				#("Radius", "float16", 1, "Frost Radius"),
				#("ShapeIndex", "int16", 1, "Frost Shape Index"),
				#("GeomTime", "float16", 1, "Frost Geometry Time")				
			)	
			if mode == #input do append channelsList #("Index", "int32", 1, "MagmaFlow Particle Index")
			if mode != #input do append channelsList #("PRTViewportVector", "float16", 3, "Custom Vector Display in Viewports")
			if mode != #input do append channelsList #("PRTViewportColor", "float16", 3, "Custom Color Display in Viewports")
			if mode == #input and classof KrakatoaChannelNodeEditor_CurrentModifier == MagmaHolder do append channelsList #("Lighting", "float16", 3 , "Light Arriving At Particle")
			local theIniFile = (Krakatoa_PresetsDirectory+"\\Krakatoa_CustomChannelsToSave.ini") 
			local customChannels = getIniSetting theIniFile
			for c in customChannels do
			(
				if findItem (for i in channelsList collect i[1]) c == 0 do
				(
					local theType = getIniSetting theIniFile c "Type"
					local theArity = getIniSetting theIniFile c "Arity"
					if theType != "" and theArity != "" do
					(
						append channelsList #(c,theType,theArity as integer,"User-Defined Channel")
					)
				)	
			)
			for i = 2 to 99 do append channelsList #("Mapping"+i as string, "float32", 3, "3ds Max Mapping Channel "+i as string)		
		),
		
		fn sortNamesAlphabetically v1 v2 =
		(
			if v1[1] > v2[1] then 1 else if v1[1] < v2[1] then -1 else 0
		),
		
		fn sortByUsage v1 v2 valArray: =
		(
			if valArray[v1] > valArray[v2] then -1 else if valArray[v1] < valArray[v2] then 1 else 0
		),		
		
		fn getSortedChannelsList sortOrder includeCustom:true nodeType:#input =
		(
			local tempArray = if includeCustom then #("[Custom Channel]") else #()
			case sortOrder of
			(
				default: (
								sortedChannelsList = deepCopy channelsList
								join tempArray (for i in channelsList collect i[1])
								
							)
				2: (
						sortedChannelsList = deepCopy channelsList
						qsort sortedChannelsList KrakatoaChannelsEditor_Functions.sortNamesAlphabetically
						local theIndexArray = for i = 1 to sortedChannelsList.count collect i
						local theUsageIniFile = if nodeType == #input then (Krakatoa_PresetsDirectory+"\\Krakatoa_MagmaFlowInputChannelsUsageHistory.ini") else (Krakatoa_PresetsDirectory+"\\Krakatoa_MagmaFlowOutputChannelsUsageHistory.ini")
						local theUsageList = for i in sortedChannelsList collect
						(
							theVal = execute (getIniSetting theUsageIniFile "UsageHistory" i[1])
							if theVal == OK do theVal = 0
							theVal
						)
						qsort theIndexArray KrakatoaChannelsEditor_Functions.sortByUsage valArray:theUsageList
						sortedChannelsList = for i in theIndexArray collect sortedChannelsList[i]
						join tempArray (for i in sortedChannelsList collect i[1])
					)
				3: (
						
						local sortedChannelsList = deepCopy channelsList
						qsort sortedChannelsList KrakatoaChannelsEditor_Functions.sortNamesAlphabetically
						join tempArray (for i in sortedChannelsList collect i[1])
					)
				4: (
						local notMappingArray = (for i in channelsList where (not matchPattern i[1] pattern:"Mapping*") collect i) 
						qsort notMappingArray  KrakatoaChannelsEditor_Functions.sortNamesAlphabetically
						local MappingArray = (for i in channelsList where (matchPattern i[1] pattern:"Mapping*") collect i) 
						qsort MappingArray  KrakatoaChannelsEditor_Functions.sortNamesAlphabetically
						sortedChannelsList = join notMappingArray MappingArray
						join tempArray (for i in sortedChannelsList collect i[1])
					)
				5: (--int,float,vector,quat
						local intsArray = (for i in channelsList where (matchPattern i[2] pattern:"int*") collect i) 
						local floatsArray = (for i in channelsList where (matchPattern i[2] pattern:"float*" and i[3] == 1 ) collect i) 
						local vectorsArray = (for i in channelsList where (matchPattern i[2] pattern:"float*" and i[3] == 3 ) collect i) 
						local quatsArray = (for i in channelsList where (matchPattern i[2] pattern:"float*" and i[3] == 4 ) collect i) 
						qsort intsArray KrakatoaChannelsEditor_Functions.sortNamesAlphabetically
						qsort floatsArray KrakatoaChannelsEditor_Functions.sortNamesAlphabetically
						qsort vectorsArray KrakatoaChannelsEditor_Functions.sortNamesAlphabetically
						qsort quatsArray KrakatoaChannelsEditor_Functions.sortNamesAlphabetically
						sortedChannelsList = #()
						join sortedChannelsList intsArray 
						join sortedChannelsList floatsArray 
						join sortedChannelsList vectorsArray 
						join sortedChannelsList quatsArray 
						join tempArray (for i in sortedChannelsList collect i[1])						
					)
				6: (--int
						local intsArray = (for i in channelsList where (matchPattern i[2] pattern:"int*") collect i) 
						qsort intsArray KrakatoaChannelsEditor_Functions.sortNamesAlphabetically
						sortedChannelsList = deepCopy intsArray
						join tempArray (for i in sortedChannelsList collect i[1])						
					)					
				7: (--float
						local floatsArray = (for i in channelsList where (matchPattern i[2] pattern:"float*" and i[3] == 1 ) collect i) 
						qsort floatsArray KrakatoaChannelsEditor_Functions.sortNamesAlphabetically
						sortedChannelsList = deepCopy floatsArray
						join tempArray (for i in sortedChannelsList collect i[1])						
					)		
				8: (--vector
						local vectorsArray = (for i in channelsList where (matchPattern i[2] pattern:"float*" and i[3] == 3 ) collect i) 
						qsort vectorsArray KrakatoaChannelsEditor_Functions.sortNamesAlphabetically
						sortedChannelsList = deepCopy vectorsArray
						join tempArray (for i in sortedChannelsList collect i[1])						
					)	
				9: (--quat
						local floatsArray = (for i in channelsList where (matchPattern i[2] pattern:"float*" and i[3] == 4 ) collect i) 
						qsort floatsArray KrakatoaChannelsEditor_Functions.sortNamesAlphabetically
						sortedChannelsList = deepCopy floatsArray
						join tempArray (for i in sortedChannelsList collect i[1])						
					)		
				10:(--prt hair
						local hairArray = (for i in channelsList where ((matchPattern i[4] pattern:"*PRT Hair*") or (findItem #("Position","Color","Density","Normal","Tangent","TextureCoord") i[1] > 0)) collect i) 
						qsort hairArray KrakatoaChannelsEditor_Functions.sortNamesAlphabetically
						sortedChannelsList = deepCopy hairArray
						join tempArray (for i in sortedChannelsList collect i[1])							
				)					
				11:(--frost
						local frostArray = (for i in channelsList where ((matchPattern i[4] pattern:"*Frost*") or (findItem #("Position","Color","Normal","Orientation","TextureCoord") i[1] > 0)) collect i) 
						qsort frostArray KrakatoaChannelsEditor_Functions.sortNamesAlphabetically
						sortedChannelsList = deepCopy frostArray
						join tempArray (for i in sortedChannelsList collect i[1])							
				)					
				12:(--fumefx
						local fumeArray = (for i in channelsList where ((matchPattern i[4] pattern:"*Fume*") or (findItem #("Position","Emission","Density","Velocity","Normal","TextureCoord") i[1] > 0)) collect i) 
						qsort fumeArray KrakatoaChannelsEditor_Functions.sortNamesAlphabetically
						sortedChannelsList = deepCopy fumeArray
						join tempArray (for i in sortedChannelsList collect i[1])							
				)					
			)
			--print sortedChannelsList
			tempArray
		),		
		
		fn isChannelFloat theChannelName =
		(
			local theResult = for i in channelsList where i[1] == theChannelName collect i
			if theResult.count == 1 then 
				matchPattern theResult[1][2] pattern:"float*" and theResult[1][3] == 1
			else 
				false
		),
		
		fn isChannelInteger theChannelName =
		(
			local theResult = for i in channelsList where i[1] == theChannelName collect i
			if theResult.count == 1 then 
				matchPattern theResult[1][2] pattern:"int*" and theResult[1][3] == 1
			else 
				false
		),		
		
		fn exposeControlsToModifier theMod =
		(
			KrakatoaChannelEditor_IsUpdatingExposure = true
			
			KrakatoaChannelsEditor_Functions.updateParentModifier suppressRedraw:true
			
			try(modpanel.setCurrentObject theMod)catch()
			try(deleteItem theMod.custAttributes (("KCM_CA_"+theMod.trackID as string) as name)	)catch()
			try(deleteItem theMod.custAttributes ("KCM_CA" as name)	)catch()
			
			try(modpanel.setCurrentObject theMod)catch()
			local theCADef2 = "rollout params \"Exposed Parameters\" category:10000\n("
			
			theCADef2 += "fn updateMod = (\n"
			theCADef2 += "local theMod = (custAttributes.getOwner this)\n"
			
			theCADef2 += "if theMod.autoUpdate do theMod.autoUpdate = theMod.autoUpdate \n"
			theCADef2 += "if KrakatoaChannelNodeEditor_Rollout.open do KrakatoaChannelNodeEditor_Rollout.createNodeTree init:false\n"
			theCADef2 += ")\n"
			
			theCADef3 = "on params open do (\n"
			
			local theCADef = "KCM_CA_DEF = attributes KCM_CA (\n"
			theCADef += "local params \n"
			theCADef += "parameters main rollout:params ( \n"
			
			local theColorPickersToUpdate = #()
			
			local theFlowToExpose = execute (KrakatoaChannelsEditor_Functions.expandFlow theMod.internalFlow fixTracks:true)
				
			cnt = 0
			for i = 2 to theFlowToExpose.count where theFlowToExpose[i][3][2] == "Float" and theFlowToExpose[i][4][12] == true do
			(
				cnt+=1
				local theName = theFlowToExpose[i][4][8]
				local theID = theFlowToExpose[i][4][4]
				theCADef += "float_"+cnt as string+ " type:#float ui:spn_"+cnt as string+" default:1 \n"
				theCADef2 += "spinner spn_"+cnt as string+" \""+i as string + ": "+theName+": \" type:#float align:#right fieldwidth:50 range:[-100000,100000,0] scale:0.01 offset:[7,0] \n"
				--theCADef2 += "button btn_"+cnt as string + " \"?\" width:12 height:18 enabled:false offset:[10,0] align:#right tooltip:\""+ theFlowToExpose[i][4][16] +"\"\n"
				theCADef2 += "on spn_"+cnt as string+" changed val do updateMod()\n"
			)--end i loop
			for i = 2 to theFlowToExpose.count where theFlowToExpose[i][3][2] == "Integer" and theFlowToExpose[i][4][12] == true do
			(
				cnt+=1
				local theName = theFlowToExpose[i][4][8]
				local theID = theFlowToExpose[i][4][4]
				theCADef += "int_"+cnt as string+ " type:#integer ui:spn_"+cnt as string+" default:1 \n"
				theCADef2 += "spinner spn_"+cnt as string+" \""+i as string + ": "+theName+": \" type:#integer align:#right fieldwidth:50 range:[-100000,100000,1] offset:[7,0] \n"
				--theCADef2 += "button btn_"+cnt as string + " \"?\" tooltip:\""+ theFlowToExpose[i][4][16] +"\"\n"
				theCADef2 += "on spn_"+cnt as string+" changed val do updateMod()\n"
			)--end i loop
			for i = 2 to theFlowToExpose.count where theFlowToExpose[i][3][2] == "Vector" and theFlowToExpose[i][4][12] == true do
			(
				local theName = theFlowToExpose[i][4][8]
				local theID = theFlowToExpose[i][4][4]
				theCADef2 += "group \""+i as string + ": "+theName+"\"(\n"

				cnt+=1				
				theCADef += "vect_"+cnt as string+ " type:#float ui:spn_"+cnt as string+"\n"
				theCADef2 += "spinner spn_"+cnt as string+" \"X: \" type:#float range:[-1000000,1000000,0] align:#right fieldwidth:50 offset:[5,-3] scale:0.01 tooltip:\""+ (if theFlowToExpose[i][4][16] == undefined then "" else theFlowToExpose[i][4][16]) +"\"\n"
				
				cnt+=1
				theCADef += "vect_"+cnt as string+ " type:#float ui:spn_"+cnt as string+"\n"
				theCADef2 += "spinner spn_"+cnt as string+" \"Y: \" type:#float range:[-1000000,1000000,0] align:#right fieldwidth:50 offset:[5,-3] scale:0.01 tooltip:\""+ (if theFlowToExpose[i][4][16] == undefined then "" else theFlowToExpose[i][4][16]) +"\"\n"
				
				cnt+=1
				theCADef += "vect_"+cnt as string+ " type:#float ui:spn_"+cnt as string+"\n"
				theCADef += "fullvect_"+cnt as string+ " type:#color animatable:false\n" --ui:clr_"+cnt as string+"\n"
				
				theCADef2 += "spinner spn_"+cnt as string+" \"Z: \" type:#float range:[-1000000,1000000,0] align:#right fieldwidth:50 offset:[5,-3] scale:0.01 tooltip:\""+ (if theFlowToExpose[i][4][16] == undefined then "" else theFlowToExpose[i][4][16]) +"\"\n"

				theCADef2 += "colorpicker clr_"+cnt as string+" \"\" align:#left offset:[-5,-56] height:50 width:48 alpha:true modal:true tooltip:\""+ (if theFlowToExpose[i][4][16] == undefined then "" else theFlowToExpose[i][4][16]) +"\"\n"
				append theColorPickersToUpdate cnt

				theCADef2 += ")--end group\n"
				
				theCADef2 += "on clr_"+cnt as string+" changed val do (\n"
				theCADef2 += "vect_"+(cnt-2) as string+ " = val.r/255.0\n"
				theCADef2 += "vect_"+(cnt-1) as string+ " = val.g/255.0\n"
				theCADef2 += "vect_"+(cnt) as string+ " = val.b/255.0\n"
				theCADef2 += "try(KrakatoaChannelNodeEditor_InputRollout.clr_color.color = val)catch()\n"
				theCADef2 += "try(KrakatoaChannelNodeEditor_InputRollout.clr_colorComplementary.color = white - val)catch()\n"
				theCADef2 += ")\n"
				
				theCADef += "on vect_"+(cnt-2) as string+ " get val do (\n"
				theCADef += "theColor = [val,vect_"+(cnt-1) as string+ ",vect_"+(cnt) as string+" ]*255.0\n"
				theCADef += "params.clr_"+cnt as string+ ".color = theColor\n"
				theCADef += "val)\n"

				theCADef += "on vect_"+(cnt-1) as string+ " get val do (\n"
				theCADef += "theColor = [vect_"+(cnt-2) as string+ ",val,vect_"+(cnt) as string+" ]*255.0\n"
				theCADef += "params.clr_"+cnt as string+ ".color = theColor\n"
				theCADef += "val)\n"
				
				theCADef += "on vect_"+(cnt) as string+ " get val do (\n"
				theCADef += "theColor = [vect_"+(cnt-2) as string+ ",vect_"+(cnt-1) as string+",val]*255.0\n"
				theCADef += "params.clr_"+cnt as string+ ".color = theColor\n"
				theCADef += "val)\n"				
				
				theCADef2 += "on spn_"+(cnt-2) as string+" changed val do (\n"
				theCADef2 += "local theColor = clr_"+cnt as string +".color \n"
				theCADef2 += "theColor.r = val*255.0\n"
				theCADef2 += "clr_"+cnt as string+ ".color = theColor\n"
				theCADef2 += "fullvect_"+cnt as string+ " = theColor\n"				
				theCADef2 += "try(KrakatoaChannelNodeEditor_InputRollout.clr_color.color = theColor)catch()\n"
				theCADef2 += "try(KrakatoaChannelNodeEditor_InputRollout.clr_colorComplementary.color = white - theColor)catch()\n"
				theCADef2 += "updateMod()\n)\n"
				
				theCADef2 += "on spn_"+(cnt-1) as string+" changed val do (\n"
				theCADef2 += "local theColor = clr_"+cnt as string +".color \n"
				theCADef2 += "theColor.g = val*255.0\n"
				--theCADef2 += "print theColor\n"
				theCADef2 += "clr_"+cnt as string+ ".color = theColor\n"
				theCADef2 += "try(KrakatoaChannelNodeEditor_InputRollout.clr_color.color = theColor)catch()\n"
				theCADef2 += "try(KrakatoaChannelNodeEditor_InputRollout.clr_colorComplementary.color = white - theColor)catch()\n"
				theCADef2 += "updateMod()\n)\n"				
				
				theCADef2 += "on spn_"+(cnt) as string+" changed val do (\n"
				theCADef2 += "local theColor = clr_"+cnt as string +".color \n"
				theCADef2 += "theColor.b = val*255.0\n"
				--theCADef2 += "print theColor\n"
				theCADef2 += "clr_"+cnt as string+ ".color = theColor\n"
				theCADef2 += "try(KrakatoaChannelNodeEditor_InputRollout.clr_color.color = theColor)catch()\n"
				theCADef2 += "try(KrakatoaChannelNodeEditor_InputRollout.clr_colorComplementary.color = white - theColor)catch()\n"
				theCADef2 += "updateMod()\n)\n"					
				
				--theCADef2 += "on spn_"+(cnt-1) as string+" changed val do (updateMod())\n"
				--theCADef2 += "on spn_"+cnt as string+" changed val do (updateMod())\n"	
				
			)--end i loop			

			theCADef += ")--end main params\n"
			
			for j in theColorPickersToUpdate do
			(
				theCADef3 += "fullvect_"+j as string +" = clr_"+j as string+".color = [vect_"+(j-2) as string+",vect_"+(j-1) as string+", vect_"+j as string+"]*255.0 \n"
			)
			
			/*theCADef3 += "local theMod = (custAttributes.getOwner this) \n"
			theCADef3 += "if theMod.needCAUpdate do (\n"
			theCADef3 += "	KrakatoaChannelsEditor_Functions.exposeControlsToModifier theMod \n"
			theCADef3 += "	theMod.needCAupdate = false \n"
			theCADef3 += ")\n"
			*/
			
			theCADef3 += ")--end on open\n"
			theCADef2 += theCADef3 
			theCADef2 += ")--end rollout\n"
			theCADef2 += ")--end def\n"
			if cnt > 0 do
			(
				--print (theCADef+theCADef2)
				KCM_CA_DEF = execute (theCADef+theCADef2)
				custAttributes.add theMod KCM_CA_DEF
				local theCAName = ("KCM_CA" as name)
				max modify mode
				try(modPanel.setCurrentObject theMod)catch()
				cnt = 0
				for i = 2 to theFlowToExpose.count where theFlowToExpose[i][3][2] == "Float" and theFlowToExpose[i][4][12] == true do
				(
					cnt+=1
					local theController = execute (theFlowToExpose[i][3][3]+"[2].controller")
					theMod.custAttributes[theCAName][cnt].value = theController.value
					theMod.custAttributes[theCAName][cnt].controller = theController
				)	
				for i = 2 to theFlowToExpose.count where theFlowToExpose[i][3][2] == "Integer" and theFlowToExpose[i][4][12] == true do
				(
					cnt+=1
					local theController = execute (theFlowToExpose[i][3][3]+"[1].controller")
					theMod.custAttributes[theCAName][cnt].value = theController.value
					theMod.custAttributes[theCAName][cnt].controller = theController
				)
				for i = 2 to theFlowToExpose.count where theFlowToExpose[i][3][2] == "Vector" and theFlowToExpose[i][4][12] == true do
				(
					cnt+=1
					--format "theFlowToExpose[i][3][3]=%\n" theFlowToExpose[i][3][3]
					local theController = execute (theFlowToExpose[i][3][3]+"[3].controller")
					
					if classof theController == Point3_List do theController = theController[1].controller
					theMod.custAttributes[theCAName][cnt].value = theController[1].controller.value
					theMod.custAttributes[theCAName][cnt].controller = theController[1].controller
					
					cnt+=1
					local theController = execute (theFlowToExpose[i][3][3]+"[3].controller")
					if classof theController == Point3_List do theController = theController[1].controller
					
					theMod.custAttributes[theCAName][cnt].value = theController[2].controller.value
					theMod.custAttributes[theCAName][cnt].controller = theController[2].controller

					cnt+=1
					local theController = execute (theFlowToExpose[i][3][3]+"[3].controller")
					if classof theController == Point3_List do theController = theController[1].controller
						
					theMod.custAttributes[theCAName][cnt].value = theController[3].controller.value
					theMod.custAttributes[theCAName][cnt].controller = theController[3].controller
				)	
				try(modpanel.setCurrentObject theMod)catch()
				setFocus KrakatoaChannelNodeEditor_Rollout.hc
			)
			KrakatoaChannelEditor_IsUpdatingExposure = false
		),
		
		fn RemoveListControllersFromTracks =
		(
			local theRootNode = try(trackViewNodes.KrakatoaChannelEditor)catch(undefined)
			local failures = 0
			local successes = 0
			if theRootNode != undefined do
			(
				for i = 1 to trackViewNodes.KrakatoaChannelEditor.numsubs do
				(
					local theModTrack = trackViewNodes.KrakatoaChannelEditor[i]
					if theModTrack != undefined do
					(
						for j = 1 to theModTrack.numsubs do --loop through nodes
						(
							theNodeTrack = theModTrack[j]
							for k = 1 to theNodeTrack.numsubs do
							(
								if classof theNodeTrack[k].controller == Float_List or classof theNodeTrack[k].controller == Point3_List do
								(
									if theNodeTrack[k].controller.weight[1] > 0 then
									(
										try
										(
											theNodeTrack[k].controller = copy theNodeTrack[k].controller[1].controller
											successes += 1
										)catch(failures += 1)
									)
									else
									(
										try
										(
											theNodeTrack[k].controller = copy theNodeTrack[k].controller[2].controller
											successes += 1
										)catch(failures += 1)
									)
								)--end if List Controller
							)--end k loop 
						)--end j loop 
					)--end if modtrack not undefined	
				)--end i loop 
			)--end if
			local txt = ""
			if successes == 0 and failures == 0 do txt = "No List Controllers were Collapsed.\n\nThis might be a scene created with Krakatoa v1.5.x,\nor it has already been collapsed!"
			if successes > 0 and failures == 0 do txt = successes as string + " List Controller"+(if successes > 1 then "s" else "")+ " were Collapsed successfully."
			if successes == 0 and failures > 0 do txt = "Failed To Collapse Any List Controllers.\n\nYour build of 3ds Max might be preventing this feature from working propertly."
			if successes > 0 and failures > 0 do txt = successes as string + " List Controller"+(if successes > 1 then "s" else "")+ " were Collapsed successfully.\n" + failures as string + " List Controller" + (if failures > 1 then "s" else "") + " Failed to Collapse for some reason."
			messagebox txt title:"Krakatoa MagmaFlow - Collapse Controllers"
		)

	)--end struct
	
	KrakatoaChannelsEditor_Functions.loadChannelsList()	

	fn KrakatoaChannelEditor_TrackviewCleanupCallback =
	(
		local theInstances = getClassInstances KrakatoaChannelsModifier
		try(join theInstances (for m in (getClassInstances Krakatoa_CustomData) where m.MagmaHolder.trackID != undefined collect m.MagmaHolder) )catch()
		local theIDs = for i in theInstances collect i.trackID
		local theRootNode = try(trackViewNodes.KrakatoaChannelEditor)catch(undefined)
		if theRootNode != undefined do
		(
			for i = trackViewNodes.KrakatoaChannelEditor.numsubs to 1 by -1 do
			(
				local theModTrack = trackViewNodes.KrakatoaChannelEditor[i]
				if theModTrack != undefined do
				(
					local theID = substring theModTrack.name 5 -1
					if findItem theIDs theID == 0 do 
						deleteTrackViewNode trackViewNodes.KrakatoaChannelEditor (execute ("trackViewNodes.KrakatoaChannelEditor."+theModTrack.name))
				)	
			)
			for i = trackViewNodes.KrakatoaChannelEditor.numsubs to 1 by -1 do --loop through all KCM tracks under the Root of MagmaFlow
			(
				local theModTrack = trackViewNodes.KrakatoaChannelEditor[i] --get the KCM track from the Root track of MagmaFlow
				if theModTrack != undefined do --if the track exists,
				(
					--format "Modifier Track %:\n" theModTrack
					local theID = substring theModTrack.name 5 -1 --grab the ID porition of its name
					local theIndex = findItem theIDs theID --and look for the ID on the IDs list which contains all existing IDs in the scene
					if theIndex > 0 do --if the ID was found in the scene,
					(
						local theData = execute theInstances[theIndex].Flow --we grab the expanded flow of the corresponding KCM Instance
						local theControllerIDs = for c = 1 to theData.count where theData[c][1] == "Input" collect  --and collect the controller string from all inputs in the flow
						(
							theData[c][4][4]
						)
						--format "Controller IDs Found in Flow:\n"
						--print theControllerIDs
						local theModsToDelete = for j = theModTrack.numsubs to 1 by -1 collect --now we loop backwards through the sub-tracks of the KCM track and collect
						(
							local theControllerID = substring theModTrack[j].name 7 -1 --the ID of the node
							if findItem theControllerIDs theControllerID == 0 then --if the ID is NOT on the list collected from the flow
								(execute ("trackViewNodes.KrakatoaChannelEditor."+theModTrack.name+"."+theModTrack[j].name))  --we collect the track for deletion
							else
								dontcollect --otherwise we don't collect 
						)
						local theRoot = execute ("trackViewNodes.KrakatoaChannelEditor."+theModTrack.name) --this is the parent of the track to delete
						--format "Tracks To Delete:\n"
						--print theModsToDelete 
						for j in theModsToDelete do deleteTrackViewNode theRoot j  --we delete all collected tracks from the parent track of the KCM
					)	
				)	
			)	
		)
	)

	fn KrakatoaChannelEditor_fixDuplicatedKCMTrackIDs_Callback theMode:#None =
	(
		local theMods = getClassInstances KrakatoaChannelsModifier
		try(join theMods (for m in (getClassInstances Krakatoa_CustomData) where m.MagmaHolder.trackID != undefined collect m.MagmaHolder) )catch()
		local theIDs = for m in theMods collect (m.trackID)
		local theFlows = for m in theMods collect (execute m.flow)
		for i = theIDs.count to 1 by -1 do
		(
			theIndex = findItem theIDs theIDs[i] 
			if theIndex != i do
			(
				local txt = ("!! Duplicated KCM IDs Found By "+ theMode as string +" Callback: "+theIDs[i]+"  -- Fixing!" )
				FranticParticles.LogProgress txt
				--format "%\n" txt
				
				local theFlow1 = for j in (execute theMods[i].flow) where j[1] == "Input" collect j
				local theFlow2 = for j in (execute theMods[theIndex].flow) where j[1] == "Input" collect j
				local trackID = ""
				do 
				(
					trackID = (random 100000 10000000) as string + "_" + (random 100000 10000000) as string 
				)
				while findItem theIDs trackID != 0			
				
				KrakatoaChannelNodeEditor_CurrentModifier = if theFlow1.count > theFlow2.count then
					theMods[theIndex]
				else
					theMods[i]
				
				local oldMod = KrakatoaChannelNodeEditor_CurrentModifier
				local oldNodeTreeData = deepCopy KrakatoaChannelEditor_NodeTreeData 
				
				KrakatoaChannelNodeEditor_CurrentModifier.trackID = trackID
				KrakatoaChannelEditor_NodeTreeData = execute KrakatoaChannelNodeEditor_CurrentModifier.internalflow
				KrakatoaChannelsEditor_Functions.fixFlowIDsAfterLoading KrakatoaChannelEditor_NodeTreeData			
				
				KrakatoaChannelNodeEditor_CurrentModifier = oldMod
				KrakatoaChannelEditor_NodeTreeData = deepCopy oldNodeTreeData
			)
		)		
	)
	

	fn loadDisplaySettings filename:"" =
	(
		if filename == "" do filename =  (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini")
		
		local theVal = (getIniSetting FileName "ParticleChannelEditor" "DepotPlacement") 
		if theVal == "" do theVal = #bottomrollupreverse
		DepotPlacement = theVal as name
		
		local theVal = execute (getIniSetting FileName "ParticleChannelEditor" "DepotAutoCollapseOnDragAndDrop") 
		if theVal == OK do theVal = false
		DepotAutoCollapseOnDragAndDrop = theVal		
				
		
		local theVal = execute (getIniSetting FileName "ParticleChannelEditor" "DepotShowCategories") 
		if theVal == OK do theVal = true
		DepotShowCategories = theVal		
		
		local theVal = execute (getIniSetting FileName "ParticleChannelEditor" "DepotShowBLOPs") 
		if theVal == OK do theVal = true
		DepotShowBLOPs = theVal		
		
		local theVal = execute (getIniSetting FileName "ParticleChannelEditor" "DepotNodeWidth") 
		if theVal == OK do theVal = 60
		DepotNodeWidth = theVal		
		
		local theVal = execute (getIniSetting FileName "ParticleChannelEditor" "AllowSubtreeCollapsing")
		if theVal == OK do theVal = true
		AllowSubtreeCollapsing = theVal
		

		local theVal = (getIniSetting FileName "ParticleChannelEditor" "UnconnectedNodesPlacement") 
		if theVal == "" do theVal = #left
		UnconnectedNodesPlacement	= theVal as name
		
		local theVal = execute (getIniSetting FileName "ParticleChannelEditor" "NodeWidth")
		if theVal == OK do theVal = 140
		NodeWidth = theVal

		local theVal = execute (getIniSetting FileName "ParticleChannelEditor" "NodeXSpace")
		if theVal == OK do theVal = 40
		NodeXSpace = theVal

		local theVal = execute (getIniSetting FileName "ParticleChannelEditor" "NodeYSpace")
		if theVal == OK do theVal = 1
		NodeYSpace = theVal		
		
		local theVal = execute (getIniSetting FileName "ParticleChannelEditor" "OperatorHeightConstant")
		if theVal == OK do theVal = true
		operatorHeightConstant = theVal
		
		theVal = execute (getIniSetting filename "ParticleChannelEditor" "SnapToGrid" )
		if theVal == OK do theVal = true
		SnapToGrid = theVal

		theVal = execute (getIniSetting filename "ParticleChannelEditor" "AutoZoomExtents" )
		if theVal == OK do theVal = false
		AutoZoomExtents = theVal		

		theVal = execute (getIniSetting filename "ParticleChannelEditor" "AutoReorderToggle" )
		if theVal == OK do theVal = false
		AutoReorderToggle = theVal
		
		theVal = execute (getIniSetting filename "ParticleChannelEditor" "AllowSocketFlipping" )
		if theVal == OK do theVal = true
		AllowSocketFlipping = theVal


		theVal = (getIniSetting filename "ParticleChannelEditor" "AutoReorderPattern" )
		if theVal == "" do theVal = "row"
		AutoReorderPattern = theVal as name
		
		theVal = execute (getIniSetting filename "ParticleChannelEditor" "UseMousePositionOnCreation" )
		if theVal == OK do theVal = false
		useMousePositionOnCreation = theVal
		
		theVal = execute (getIniSetting filename "ParticleChannelEditor" "BackgroundColor" )
		if theVal == OK do theVal = color 192 192 198
		theBackgroundColor = theVal	
		
		theVal = execute (getIniSetting filename "ParticleChannelEditor" "GridColor" )
		if theVal == OK do theVal = color 200 200 210
		theGridColor = theVal			
		
		

		theVal = execute (getIniSetting filename "ParticleChannelEditor" "DepotHeaderColor")
		if theVal == OK do theVal = color 80 80 128
		theHeaderColor  = theVal

		theVal = execute (getIniSetting filename "ParticleChannelEditor" "InputNodeColor")
		if theVal == OK do theVal = color 220 220 255
		theInputNodeColor  = theVal

		theVal = execute (getIniSetting filename "ParticleChannelEditor" "NotesNodeColor")
		if theVal == OK do theVal = color 240 250 255
		theNotesNodeColor = theVal
		
		
		
		theVal = execute (getIniSetting filename "ParticleChannelEditor" "OutputNodeColor")
		if theVal == OK do theVal = color 200 255 200
		theOutputNodeColor = theVal
		
		theVal = execute (getIniSetting filename "ParticleChannelEditor" "OperatorNodeColor")
		if theVal == OK do theVal = color  255 235 200
		theOperatorNodeColor  = theVal

		theVal = execute (getIniSetting filename "ParticleChannelEditor" "BoxNodeColor")
		if theVal == OK do theVal = color  255 200 180
		theBoxNodeColor  = theVal
		
		theVal = execute (getIniSetting filename "ParticleChannelEditor" "NodesCastShadows")
		if theVal == OK do theVal = false
		theNodesCastShadows = theVal
		
		theVal = execute (getIniSetting filename "ParticleChannelEditor" "InputSocketColor")
		if theVal == OK do theVal = color 255 0 0
		theInputSocketColor  = theVal
		
		theVal = execute (getIniSetting filename "ParticleChannelEditor" "ChannelSocketColor")
		if theVal == OK do theVal = color 0 0 200
		theChannelSocketColor  = theVal		
		
		theVal = execute (getIniSetting filename "ParticleChannelEditor" "FloatSocketColor")
		if theVal == OK do theVal = color 0 128 0
		theFloatSocketColor  = theVal		

		theVal = execute (getIniSetting filename "ParticleChannelEditor" "VectorSocketColor")
		if theVal == OK do theVal = color  0 255 200
		theVectorSocketColor  = theVal		

		theVal = execute (getIniSetting filename "ParticleChannelEditor" "IntegerSocketColor")
		if theVal == OK do theVal = color  128 0 255
		theIntegerSocketColor  = theVal			

		theVal = execute (getIniSetting filename "ParticleChannelEditor" "TextureMapSocketColor")
		if theVal == OK do theVal = color  255 128 128
		theTextureMapSocketColor  = theVal	

		theVal = execute (getIniSetting filename "ParticleChannelEditor" "ObjectSocketColor")
		if theVal == OK do theVal = color 128 0 0
		theObjectSocketColor  = theVal	
		
	)
	
	
	if KrakatoaChannelEditor_BaseNodeTreeData==undefined do 
	(
		KrakatoaChannelEditor_BaseNodeTreeData = #(
			#("Output", #(2), #("Color","float16",3), #([500,0],false,false), true )
		)
	)
	
	global KrakatoaChannelsEditor_RCMenus 
	struct KrakatoaChannelsEditor_RCMenusStruct 
	(
		ValueInputsMenu,
		channelInputsMenu,
		ArithmeticOperatorsMenu,
		FunctionOperatorsMenu,
		VectorOperatorsMenu,
		TrigonometryOperatorsMenu,
		ConvertToNodesMenu,
		TransformSpaceNodesMenu,
		SurfaceOperatorsMenu,
		LogicNodesMenu
	)
	KrakatoaChannelsEditor_RCMenus = KrakatoaChannelsEditor_RCMenusStruct()
	
	rcmenu ArithmeticOperatorsMenu 
	(
		menuItem mnu_addAddOperator "A&dd"
		menuItem mnu_addSubtractOperator "&Subtract"
		menuItem mnu_addMultiplyOperator "&Multiply"
		menuItem mnu_addDivideOperator "Di&vide"
		separator sep_100
		menuItem mnu_addPowerOperator "&Power"
		menuItem mnu_addSquareRootOperator "Square &Root"
		menuItem mnu_addLogOperator "&Logarithm"		
		separator sep_200
		menuItem mnu_addModuloOperator "M&odulo"
		menuItem mnu_addAbsoluteValueOperator "A&bsolute Value"
		menuItem mnu_addFloorOperator "&Floor"
		menuItem mnu_addCeilOperator "&Ceil"
		menuItem mnu_addNegateOperator "&Negate"
		
		on mnu_addAddOperator picked do
			KrakatoaChannelNodeEditor_Rollout.addNewOperator type:"Add" creationType:#rcmenu
		
		on mnu_addSubtractOperator picked do
			KrakatoaChannelNodeEditor_Rollout.addNewOperator type:"Subtract" creationType:#rcmenu
		
		on mnu_addMultiplyOperator picked do
			KrakatoaChannelNodeEditor_Rollout.addNewOperator type:"Multiply" creationType:#rcmenu
		
		on mnu_addDivideOperator picked do
			KrakatoaChannelNodeEditor_Rollout.addNewOperator type:"Divide" creationType:#rcmenu
		
		on mnu_addPowerOperator picked do
			KrakatoaChannelNodeEditor_Rollout.addNewOperator type:"Power" creationType:#rcmenu
			
		on mnu_addSquareRootOperator picked do
			KrakatoaChannelNodeEditor_Rollout.addNewOperator type:"SquareRoot" creationType:#rcmenu

		on mnu_addModuloOperator picked do
			KrakatoaChannelNodeEditor_Rollout.addNewOperator type:"Modulo" creationType:#rcmenu
		
		on mnu_addAbsoluteValueOperator picked do
			KrakatoaChannelNodeEditor_Rollout.addNewOperator type:"AbsoluteValue" creationType:#rcmenu

		on mnu_addFloorOperator picked do
			KrakatoaChannelNodeEditor_Rollout.addNewOperator type:"Floor" creationType:#rcmenu

		on mnu_addCeilOperator picked do
			KrakatoaChannelNodeEditor_Rollout.addNewOperator type:"Ceil" creationType:#rcmenu

		on mnu_addNegateOperator picked do
			KrakatoaChannelNodeEditor_Rollout.addNewOperator type:"Negate" creationType:#rcmenu
				
		on mnu_addLogOperator picked do
			KrakatoaChannelNodeEditor_Rollout.addNewOperator type:"Logarithm" creationType:#rcmenu
		
	)
	KrakatoaChannelsEditor_RCMenus.ArithmeticOperatorsMenu = ArithmeticOperatorsMenu
	
	rcmenu FunctionOperatorsMenu 
	(
		menuItem mnu_addBlendOperator "&Blend"
		menuItem mnu_addClampOperator "&Clamp"
		menuItem mnu_addCurveOperator "Cur&ve"
		separator sep_100
		menuItem mnu_addNoiseOperator "&Noise"
		menuItem mnu_addDNoiseOperator "&Derivative Noise"		
		
		on mnu_addBlendOperator picked do
			KrakatoaChannelNodeEditor_Rollout.addNewOperator type:"Blend" creationType:#rcmenu
		
		on mnu_addClampOperator picked do
			KrakatoaChannelNodeEditor_Rollout.addNewOperator type:"Clamp" creationType:#rcmenu
		
		on mnu_addCurveOperator picked do
			KrakatoaChannelNodeEditor_Rollout.addNewOperator type:"Curve" creationType:#rcmenu

		on mnu_addNoiseOperator picked do
			KrakatoaChannelNodeEditor_Rollout.addNewOperator type:"Noise" creationType:#rcmenu
            
        on mnu_addDNoiseOperator picked do
            KrakatoaChannelNodeEditor_Rollout.addNewOperator type:"DNoise" creationType:#rcmenu		
	)
	KrakatoaChannelsEditor_RCMenus.FunctionOperatorsMenu = FunctionOperatorsMenu
	
	rcmenu VectorOperatorsMenu 
	(
		menuItem mnu_addMagnitude "&Magnitude"
		menuItem mnu_addNormalizeOperator "&Normalize"
		menuItem mnu_addComponentSum "Component &Sum"
		separator sep_100
		menuItem mnu_addDotProduct "&Dot Product"
		menuItem mnu_addCrossProduct "&Cross Product"
		separator sep_200
		menuItem mnu_addToVector "To V&ector"
		menuItem mnu_addToScalar "&To Scalar"
		separator sep_300
		menuItem mnu_addToScalarComp1 "To Scalar - &X Component"
		menuItem mnu_addToScalarComp2 "To Scalar - &Y Component"
		menuItem mnu_addToScalarComp3 "To Scalar - &Z Component"
		
		on mnu_addNormalizeOperator picked do 
			KrakatoaChannelNodeEditor_Rollout.addNewOperator type:"Normalize" creationType:#rcmenu

		on mnu_addMagnitude picked do 
			KrakatoaChannelNodeEditor_Rollout.addNewOperator type:"Magnitude" creationType:#rcmenu

		on mnu_addComponentSum picked do 
			KrakatoaChannelNodeEditor_Rollout.addNewOperator type:"ComponentSum" creationType:#rcmenu
			

		on mnu_addDotProduct picked do 
			KrakatoaChannelNodeEditor_Rollout.addNewOperator type:"DotProduct" creationType:#rcmenu
		on mnu_addCrossProduct picked do 
			KrakatoaChannelNodeEditor_Rollout.addNewOperator type:"CrossProduct" creationType:#rcmenu		
		
		on mnu_addToScalar picked do 
			KrakatoaChannelNodeEditor_Rollout.addNewOperator type:"ToScalar" creationType:#rcmenu
		
		on mnu_addToVector picked do 
			KrakatoaChannelNodeEditor_Rollout.addNewOperator type:"ToVector" creationType:#rcmenu	
		
		on mnu_addToScalarComp1 picked do
		(
			KrakatoaChannelNodeEditor_Rollout.addNewOperator type:"ToScalar" creationType:#rcmenu
			local oldNode = KrakatoaChannelEditor_DisplayNodeTreeData.count
			KrakatoaChannelNodeEditor_Rollout.deselectAllNodes()	
			KrakatoaChannelNodeEditor_Rollout.addNewInput type:#value valueType:#integer creationType:#keyboard defaultValue:1
			KrakatoaChannelEditor_DisplayNodeTreeData[oldNode][2][2] = KrakatoaChannelEditor_DisplayNodeTreeData.count
			KrakatoaChannelNodeEditor_Rollout.createNodeTree init:true
		)
		on mnu_addToScalarComp2 picked do
		(
			KrakatoaChannelNodeEditor_Rollout.addNewOperator type:"ToScalar" creationType:#rcmenu
			local oldNode = KrakatoaChannelEditor_DisplayNodeTreeData.count			
			KrakatoaChannelNodeEditor_Rollout.deselectAllNodes()
			KrakatoaChannelNodeEditor_Rollout.addNewInput type:#value valueType:#integer creationType:#keyboard defaultValue:2
			KrakatoaChannelEditor_DisplayNodeTreeData[oldNode][2][2] = KrakatoaChannelEditor_DisplayNodeTreeData.count
			KrakatoaChannelNodeEditor_Rollout.createNodeTree init:true
		)
		on mnu_addToScalarComp3 picked do
		(
			KrakatoaChannelNodeEditor_Rollout.addNewOperator type:"ToScalar" creationType:#rcmenu
			local oldNode = KrakatoaChannelEditor_DisplayNodeTreeData.count					
			KrakatoaChannelNodeEditor_Rollout.deselectAllNodes()
			KrakatoaChannelNodeEditor_Rollout.addNewInput type:#value valueType:#integer creationType:#keyboard defaultValue:3
			KrakatoaChannelEditor_DisplayNodeTreeData[oldNode][2][2] = KrakatoaChannelEditor_DisplayNodeTreeData.count
			KrakatoaChannelNodeEditor_Rollout.createNodeTree init:true
		)
		
	)
	KrakatoaChannelsEditor_RCMenus.VectorOperatorsMenu =VectorOperatorsMenu
	
	rcmenu TrigonometryOperatorsMenu
	(
		menuItem mnu_addSin "&Sin"
		menuItem mnu_addCos "&Cos"
		menuItem mnu_addTan "&Tan"
		separator sep_100
		menuItem mnu_addASin "ASi&n"
		menuItem mnu_addACos "AC&os"
		menuItem mnu_addATan "&ATan"
		menuItem mnu_addATan2 "ATan&2"
		
		on mnu_addSin picked do 
			KrakatoaChannelNodeEditor_Rollout.addNewOperator type:"Sin" creationType:#rcmenu
		on mnu_addCos picked do 
			KrakatoaChannelNodeEditor_Rollout.addNewOperator type:"Cos" creationType:#rcmenu
		on mnu_addTan picked do 
			KrakatoaChannelNodeEditor_Rollout.addNewOperator type:"Tan" creationType:#rcmenu
		on mnu_addASin picked do 
			KrakatoaChannelNodeEditor_Rollout.addNewOperator type:"ASin" creationType:#rcmenu
		on mnu_addACos picked do 
			KrakatoaChannelNodeEditor_Rollout.addNewOperator type:"ACos" creationType:#rcmenu
		on mnu_addATan picked do 
			KrakatoaChannelNodeEditor_Rollout.addNewOperator type:"ATan"	creationType:#rcmenu	
		on mnu_addATan2 picked do 
			KrakatoaChannelNodeEditor_Rollout.addNewOperator type:"ATan2"	creationType:#rcmenu	
	)	
	KrakatoaChannelsEditor_RCMenus.TrigonometryOperatorsMenu = TrigonometryOperatorsMenu

	rcmenu ConvertToNodesMenu
	(
		menuItem mnu_addToFloat "To &Float"				
		menuItem mnu_addToInteger "To &Integer"
		separator sep_100
		menuItem mnu_addToVector "To &Vector"
		menuItem mnu_addToScalar "To &Scalar"
		separator sep_200
		menuItem mnu_addToQuat "To &Quat"
		menuItem mnu_addFromQuat "From Q&uat"

		on mnu_addFromQuat picked do
			KrakatoaChannelNodeEditor_Rollout.addNewOperator type:"FromQuat" creationType:#rcmenu
		on mnu_addToQuat picked do
			KrakatoaChannelNodeEditor_Rollout.addNewOperator type:"ToQuat" creationType:#rcmenu
		on mnu_addToVector picked do 
			KrakatoaChannelNodeEditor_Rollout.addNewOperator type:"ToVector" creationType:#rcmenu	
		on mnu_addToFloat picked do 
			KrakatoaChannelNodeEditor_Rollout.addNewOperator type:"ToFloat" creationType:#rcmenu	
		on mnu_addToInteger picked do 
			KrakatoaChannelNodeEditor_Rollout.addNewOperator type:"ToInteger" creationType:#rcmenu	
		on mnu_addToScalar picked do 
			KrakatoaChannelNodeEditor_Rollout.addNewOperator type:"ToScalar" creationType:#rcmenu
	)	
	KrakatoaChannelsEditor_RCMenus.ConvertToNodesMenu = ConvertToNodesMenu
	
	rcmenu TransformSpaceNodesMenu 
	(
		menuItem mnu_addToWorldOperator "To &World"
		menuItem mnu_addFromWorldOperator "&From World"
		separator sep_100
		menuItem mnu_addToSpaceOperator "To &Space"
		menuItem mnu_addFromSpaceOperator "From S&pace"
		separator sep_200
		menuItem mnu_addToViewOperator "To &View"
		menuItem mnu_addFromViewOperator "From V&iew"
		separator sep_300
		menuItem mnu_addTransformByQuat "Transform By &Quat"
		
		on mnu_addToWorldOperator picked do 
			KrakatoaChannelNodeEditor_Rollout.addNewOperator type:"ToWorld" creationType:#rcmenu	
		on mnu_addFromWorldOperator picked do 
			KrakatoaChannelNodeEditor_Rollout.addNewOperator type:"FromWorld" creationType:#rcmenu	
		on mnu_addToSpaceOperator picked do 
			KrakatoaChannelNodeEditor_Rollout.addNewOperator type:"ToSpace" creationType:#rcmenu	
		on mnu_addFromSpaceOperator picked do 
			KrakatoaChannelNodeEditor_Rollout.addNewOperator type:"FromSpace" creationType:#rcmenu	

		on mnu_addToViewOperator picked do 
			KrakatoaChannelNodeEditor_Rollout.addNewOperator type:"ToView" creationType:#rcmenu	
		on mnu_addFromViewOperator picked do 
			KrakatoaChannelNodeEditor_Rollout.addNewOperator type:"FromView" creationType:#rcmenu	
		
		on mnu_addTransformByQuat picked do
			KrakatoaChannelNodeEditor_Rollout.addNewOperator type:"TransformByQuat" creationType:#rcmenu
	)
	KrakatoaChannelsEditor_RCMenus.TransformSpaceNodesMenu = TransformSpaceNodesMenu
	
	rcmenu SurfaceOperatorsMenu
	(
		menuItem mnu_nearestPointOperator "&Nearest Point"
		menuItem mnu_rayIntersectOperator "&Ray Intersect"
		separator sep_100
		menuItem mnu_dataValueOperator "Surface &Data Value"
		--menuItem mnu_ValidDataValueOperator "&Valid Surface Data"
		
		
		
		on mnu_dataValueOperator picked do 
			KrakatoaChannelNodeEditor_Rollout.addNewOperator type:"SurfDataValue" creationType:#rcmenu	
		--on mnu_ValidDataValueOperator picked do 
			--KrakatoaChannelNodeEditor_Rollout.addNewOperator type:"ValidSurfData" creationType:#rcmenu	
		
		on mnu_rayIntersectOperator picked do 
			KrakatoaChannelNodeEditor_Rollout.addNewOperator type:"RayIntersect" creationType:#rcmenu	
		on mnu_nearestPointOperator picked do 
			KrakatoaChannelNodeEditor_Rollout.addNewOperator type:"NearestPoint" creationType:#rcmenu	
		
	)
	KrakatoaChannelsEditor_RCMenus.SurfaceOperatorsMenu = SurfaceOperatorsMenu
	
	rcmenu LogicNodesMenu 
	(
		menuItem mnu_addLessOperator "L&ess"
		menuItem mnu_addLessOrEqualOperator "Less Or Eq&ual"
		menuItem mnu_addGreaterOperator "&Greater"
		menuItem mnu_addGreaterOrEqualOperator "G&reater Or Equal"
		menuItem mnu_addEqualOperator "E&qual"
		separator sep_200
		menuItem mnu_addAndOperator "&AND"
		menuItem mnu_addOrOperator "&OR"
		menuItem mnu_addNotOperator "&NOT"
		separator sep_210
		menuItem mnu_addSwitchOperator "&Switch (IF/THEN/ELSE)"
		
		on mnu_addLessOperator picked do 
			KrakatoaChannelNodeEditor_Rollout.addNewOperator type:"Less" creationType:#rcmenu
		on mnu_addLessOrEqualOperator picked do 
			KrakatoaChannelNodeEditor_Rollout.addNewOperator type:"LessOrEqual" creationType:#rcmenu	
		on mnu_addGreaterOperator picked do 
			KrakatoaChannelNodeEditor_Rollout.addNewOperator type:"Greater" creationType:#rcmenu
		on mnu_addGreaterOrEqualOperator picked do 
			KrakatoaChannelNodeEditor_Rollout.addNewOperator type:"GreaterOrEqual" creationType:#rcmenu
		on mnu_addEqualOperator picked do 
			KrakatoaChannelNodeEditor_Rollout.addNewOperator type:"Equal"	creationType:#rcmenu
		
		on mnu_addAndOperator picked do 
			KrakatoaChannelNodeEditor_Rollout.addNewOperator type:"LogicalAnd" creationType:#rcmenu	
		on mnu_addOrOperator picked do 
			KrakatoaChannelNodeEditor_Rollout.addNewOperator type:"LogicalOr" creationType:#rcmenu		
		on mnu_addNotOperator picked do 
			KrakatoaChannelNodeEditor_Rollout.addNewOperator type:"LogicalNot" creationType:#rcmenu	

		on mnu_addSwitchOperator picked do
			KrakatoaChannelNodeEditor_Rollout.addNewOperator type:"Switch" creationType:#rcmenu
	)
	KrakatoaChannelsEditor_RCMenus.LogicNodesMenu = LogicNodesMenu
	
	rcmenu ValueInputsMenu 
	(
		menuItem mnu_addChannelInput "&Channel Input"
		menuItem mnu_addVectorInput "&Vector Input"
		menuItem mnu_addFloatInput "&Float Input"
		menuItem mnu_addIntegerInput "&Integer Input"
		separator sep_100
		menuItem mnu_addInputScript "&Script Input"
		menuItem mnu_addGeometryInput "&Geometry Input"
		separator sep_110
		menuItem mnu_addInputTextureMap "&TextureMap Input"
		menuItem mnu_addInputNotes "&Notes Input"

		on mnu_addChannelInput picked do
			KrakatoaChannelNodeEditor_Rollout.addNewInput type:#channel channelName:"Color" creationType:#rcmenu
		
		on mnu_addVectorInput picked do
			KrakatoaChannelNodeEditor_Rollout.addNewInput type:#value valueType:#vector creationType:#rcmenu
		
		on mnu_addFloatInput picked do
			KrakatoaChannelNodeEditor_Rollout.addNewInput type:#value valueType:#float creationType:#rcmenu
		
		on mnu_addIntegerInput picked do
			KrakatoaChannelNodeEditor_Rollout.addNewInput type:#value valueType:#integer creationType:#rcmenu


		on mnu_addInputScript picked do
			KrakatoaChannelNodeEditor_Rollout.addNewInput type:#script creationType:#rcmenu
		
		on mnu_addGeometryInput picked do
			KrakatoaChannelNodeEditor_Rollout.addNewInput type:#geometry creationType:#rcmenu

		on mnu_addInputTextureMap picked do
			KrakatoaChannelNodeEditor_Rollout.addNewInput type:#texturemap creationType:#rcmenu

		on mnu_addInputNotes picked do
			KrakatoaChannelNodeEditor_Rollout.addNewInput type:#notes creationType:#rcmenu
		
	)
	KrakatoaChannelsEditor_RCMenus.ValueInputsMenu =ValueInputsMenu
	
	rcmenu channelInputsMenu 
		-- Used: A B C D E F L M N O P S T V X Y
		-- Free:  G H J K Q R U W Z
	(
		menuItem mnu_addPositionChannel "&Position Channel"
		menuItem mnu_addVelocityChannel "&Velocity Channel"
		separator sep_100
		menuItem mnu_addColorChannel "&Color Channel"
		menuItem mnu_addEmissionChannel "&Emission Channel"
		menuItem mnu_addAbsorptionChannel "A&bsorption Channel"
		menuItem mnu_addDensityChannel "Densit&y Channel"
		separator sep_200
		menuItem mnu_addNormalChannel "&Normal Channel"
		menuItem mnu_addTangentChannel "&Tangent Channel"
		menuItem mnu_addOrientationChannel "&Orientation Channel"
		separator sep_300
		menuItem mnu_addMappingChannel "Te&xtureCoord Channel"
		menuItem mnu_addMtlIndexChannel "&MtlIndex Channel"
		separator sep_400	
		menuItem mnu_addAgeChannel "&Age Channel"
		menuItem mnu_addLifeSpanChannel "&LifeSpan Channel"
		separator sep_500	
		menuItem mnu_addIDChannel "I&D Channel"	
		menuItem mnu_addSelectionChannel "&Selection Channel"	
		separator sep_600	
		menuItem mnu_addFireChannel "&Fire Channel"	
		

		on mnu_addPositionChannel picked do
			KrakatoaChannelNodeEditor_Rollout.addNewInput type:#channel channelName:"Position" creationType:#rcmenu
		on mnu_addVelocityChannel picked do
			KrakatoaChannelNodeEditor_Rollout.addNewInput type:#channel channelName:"Velocity" creationType:#rcmenu
		
		on mnu_addColorChannel picked do
			KrakatoaChannelNodeEditor_Rollout.addNewInput type:#channel channelName:"Color" creationType:#rcmenu
		on mnu_addEmissionChannel picked do
			KrakatoaChannelNodeEditor_Rollout.addNewInput type:#channel channelName:"Emission" creationType:#rcmenu
		on mnu_addAbsorptionChannel picked do
			KrakatoaChannelNodeEditor_Rollout.addNewInput type:#channel channelName:"Absorption" creationType:#rcmenu
		on mnu_addDensityChannel picked do
			KrakatoaChannelNodeEditor_Rollout.addNewInput type:#channel channelName:"Density" creationType:#rcmenu
		
		on mnu_addNormalChannel picked do
			KrakatoaChannelNodeEditor_Rollout.addNewInput type:#channel channelName:"Normal" creationType:#rcmenu
		on mnu_addTangentChannel picked do
			KrakatoaChannelNodeEditor_Rollout.addNewInput type:#channel channelName:"Tangent" creationType:#rcmenu
		on mnu_addOrientationChannel picked do
			KrakatoaChannelNodeEditor_Rollout.addNewInput type:#channel channelName:"Orientation" creationType:#rcmenu
		
		on mnu_addMappingChannel picked do
			KrakatoaChannelNodeEditor_Rollout.addNewInput type:#channel channelName:"TextureCoord" creationType:#rcmenu
		on mnu_addMtlIndexChannel picked do
			KrakatoaChannelNodeEditor_Rollout.addNewInput type:#channel channelName:"MtlIndex" creationType:#rcmenu
		
		on mnu_addAgeChannel picked do
			KrakatoaChannelNodeEditor_Rollout.addNewInput type:#channel channelName:"Age" creationType:#rcmenu
		on mnu_addLifeSpanChannel picked do
			KrakatoaChannelNodeEditor_Rollout.addNewInput type:#channel channelName:"LifeSpan" creationType:#rcmenu
		
		on mnu_addIDChannel picked do
			KrakatoaChannelNodeEditor_Rollout.addNewInput type:#channel channelName:"ID" creationType:#rcmenu
		on mnu_addSelectionChannel picked do
			KrakatoaChannelNodeEditor_Rollout.addNewInput type:#channel channelName:"Selection" creationType:#rcmenu

		on mnu_addFireChannel picked do
			KrakatoaChannelNodeEditor_Rollout.addNewInput type:#channel channelName:"Fire" creationType:#rcmenu
		
	)
	KrakatoaChannelsEditor_RCMenus.channelInputsMenu = channelInputsMenu
	
	
	global KrakatoaChannelEditor_AddNode_RCMenu
	rcmenu KrakatoaChannelEditor_AddNode_RCMenu 
	(
		fn anythingSelected = ((KrakatoaChannelNodeEditor_Rollout.getSelectedNodes()).count > 0)
		fn moreThanOneSelected = ((KrakatoaChannelNodeEditor_Rollout.getSelectedNodes()).count > 1)
		fn depotIsOff = (DepotPlacement == #off)
		fn isInBlackOpEditingMode = (KrakatoaChannelEditor_NodeTreeEditingLevel.count > 0)
		menuItem mnu_endEditingBLOP "Exit BlackOp Editing Mode" filter:isInBlackOpEditingMode
		separator sep_10 filter:isInBlackOpEditingMode
		
		menuItem mnu_DepotOn "Enable Depot" filter:depotIsOff		
		separator sep_20 filter:depotIsOff
		
		subMenu "Inputs"
		(		
			subMenu "Channel Inputs"
			(			
				menuItem mnu_addPositionChannel "[Position] Channel Input (Shift+P)"
				menuItem mnu_addVelocityChannel "[Velocity] Channel Input (Shift+V)"
				separator sep_channelInput_10
				menuItem mnu_addColorChannel "[Color] Channel Input (Shift+C)"
				menuItem mnu_addEmissionChannel "[Emission] Channel Input (Shift+E)"
				menuItem mnu_addAbsorptionChannel "[Absorption] Channel Input (Shift+B)"
				menuItem mnu_addDensityChannel "[Density] Channel Input (Shift+D)"
				separator sep_channelInput_20
				menuItem mnu_addNormalChannel "[Normal] Channel Input (Shift+N)"
				menuItem mnu_addTangentChannel "[Tangent] Channel Input (Shift+T)"
				menuItem mnu_addOrientationChannel "[Orientation] Channel Input (Shift+O)"
				separator sep_channelInput_40
				menuItem mnu_addMappingChannel "[TextureCoord] Channel Input (Shift+M)"
				menuItem mnu_addMtlIndexChannel "[MtlIndex] Channel Input"
				separator sep_channelInput_50
				menuItem mnu_addAgeChannel "[Age] Channel Input (Shift+A)"
				menuItem mnu_addLifeSpanChannel "[LifeSpan] Channel Input (Shift+L)"
				separator sep_channelInput_60
				menuItem mnu_addIDChannel "[ID] Channel Input (Shift+I)"
				menuItem mnu_addSelectionChannel "[Selection] Channel Input (Shift+S)"
			)	
			separator sep_30
			menuItem mnu_addInputInteger "[Integer Value] Input"
			menuItem mnu_addInputFloat "[Float Value] Input"
			menuItem mnu_addInputVector "[Vector Value] Input"
			separator sep_40
			menuItem mnu_addInputTextureMap "[TextureMap] Input (M)"
			--menuItem mnu_addInputTime "[Time] Input"
			menuItem mnu_addInputScript "[Script] Input"
		)
		separator sep_50
		subMenu "&Arithmetic Operators"
		(
			menuItem mnu_addAddOperator "[Add] Operator (Num.+)"
			menuItem mnu_addSubtractOperator "[Subtract] Operator (Num.-)"
			menuItem mnu_addMultiplyOperator "[Multiply] Operator (Num.*)"
			menuItem mnu_addDivideOperator "[Divide] Operator (Num./)"
			separator sep_a_100
			menuItem mnu_addPowerOperator "[Power] Operator (6)"
			menuItem mnu_addSquareRootOperator "[SquareRoot] Operator (Ctrl+6)"
			menuItem mnu_addLogOperator "[Logarithm] Operator (7)"
			separator sep_a_200
			menuItem mnu_addModuloOperator "[Modulo] Operator (5)"
			menuItem mnu_addAbsoluteValueOperator "[AbsoluteValue] Operator"
			menuItem mnu_addFloorOperator "[Floor] Operator (Ctrl+Shift+F)"
			menuItem mnu_addCeilOperator "[Ceil] Operator (Ctrl+Shift+C)"
			menuItem mnu_addNegateOperator "[Negate] Operator (-)"
		)
		subMenu "&Function Operators"
		(
			menuItem mnu_addBlendOperator "[Blend] Operator (B)"
			menuItem mnu_addClampOperator "[Clamp] Operator"
			menuItem mnu_addCurveOperator "[Curve] Operator (`)"
			menuItem mnu_addNoiseOperator "[Noise] Operator (Ctrl+Shift+N)"
            menuItem mnu_addDNoiseOperator "[Derivative Noise] Operator"
		)
		subMenu "&Vector Operators"
		(
			menuItem mnu_addMagnitude "[Magnitude] Operator (Ctrl+M)"
			menuItem mnu_addNormalizeOperator "[Normalize] Operator (N)"
			menuItem mnu_addComponentSum "[ComponentSum] Operator"
			separator sep_v_100
			menuItem mnu_addDotProduct "[DotProduct] Operator (.)"
			menuItem mnu_addCrossProduct "[CrossProduct] Operator (,)"
		)	
		subMenu "Tri&gonometry Operators"
		(
			menuItem mnu_addSin "[Sin] Operator ([)"
			menuItem mnu_addCos "[Cos] Operator (])"
			menuItem mnu_addTan "[Tan] Operator (\)"
			separator sep_100
			menuItem mnu_addASin "[ASin] Operator ({)"
			menuItem mnu_addACos "[ACos] Operator (})"
			menuItem mnu_addATan "[ATan] Operator (|)"
			menuItem mnu_addATan2 "[ATan2] Operator (Ctrl+|)"
			
		)
		subMenu "&Conversion Operators"
		(
			menuItem mnu_addToFloat "[ToFloat] Operator (Shift+F)"				
			menuItem mnu_addToInteger "[ToInteger] Operator (Ctrl+Shift+I)"
			menuItem mnu_addToVector "[ToVector] Operator (Ctrl+Shift+V)"
			menuItem mnu_addToScalar "[ToScalar] Operator (Ctrl+Shift+S)"
            menuItem mnu_addToQuat "[ToQuat] Operator (Ctrl+Shift+Q)"
			menuItem mnu_addFromQuat "[FromQuat] Operator (Q)"
		)
		subMenu "&Transformation Operators"
		(
			menuItem mnu_addToWorldOperator "[ToWorld] Operator "
			menuItem mnu_addFromWorldOperator "[FromWorld] Operator "
			menuItem mnu_addToSpaceOperator "[ToSpace] Operator "
			menuItem mnu_addFromSpaceOperator "[FromSpace] Operator "
			menuItem mnu_addToViewOperator "[ToView] Operator "
			menuItem mnu_addFromViewOperator "[FromView] Operator "
			menuItem mnu_addTransformByQuat "[TransformByQuat]"
		)
		subMenu "&Surface Operators"
		(
			menuItem mnu_nearestPointOperator "[NearestPoint] Operator "
			menuItem mnu_rayIntersectOperator "[RayIntersect] Operator"
			menuItem mnu_dataValueOperator "[SurfDataValue] Operator"
		)
		subMenu "&Logic and Comparison Operators"
		(
			menuItem mnu_addLessOperator "[Less] < Operator (Shift+<)"
			menuItem mnu_addLessOrEqualOperator "[LessOrEqual] <= Operator "
			menuItem mnu_addGreaterOperator "[Greater] > Operator (Shift+>)"
			menuItem mnu_addGreaterOrEqualOperator "[GreaterOrEqual] >= Operator "
			menuItem mnu_addEqualOperator "[Equal] == Operator (=)"
			separator sep_200
			menuItem mnu_addAndOperator "[And] Operator "
			menuItem mnu_addOrOperator "[Or] Operator "
			menuItem mnu_addNotOperator "[Not] Operator "
			separator sep_210
			menuItem mnu_addSwitchOperator "[Switch] Operator (/)"
		)
		menuItem mnu_addChannelOperator "Operator - Automatic (O)"
		separator sep_300
		menuItem mnu_addNewBLOPInline "[BlackOp] Compound Operator From Selection" filter:moreThanOneSelected	
		menuItem mnu_addNewBLOP "[BlackOp] Compound Operator From File"
		menuItem mnu_saveBLOPDefinition "Save Selection As BlackOP" filter:moreThanOneSelected --enabled:((KrakatoaChannelNodeEditor_Rollout.getSelectedNodes()).count > 0)
		separator sep_310 filter:anythingSelected
			
		subMenu "Expose Selected..." filter:anythingSelected
		(
			menuitem mnu_selectExposedInputs "Select Exposed Inputs"
			menuitem mnu_UnExposeSelectedInputs "Unexpose Selected Inputs"
			menuitem mnu_ExposeSelectedInputs "Expose Selected Inputs"
			separator sep_500
			menuitem mnu_updateExposedInputs "Update Exposed Inputs"
		)
		separator sep_315 filter:anythingSelected
		menuItem mnu_swapInputs "Swap First Two Inputs Of Selected Operators (Ctrl+W)" filter:anythingSelected --enabled:((KrakatoaChannelNodeEditor_Rollout.getSelectedNodes()).count > 0)
		menuItem mnu_swapSecondInputs "Swap Last Two Inputs Of Selected Operators (Shift+Ctrl+W)" filter:anythingSelected --enabled:((KrakatoaChannelNodeEditor_Rollout.getSelectedNodes()).count > 0)
		menuItem mnu_toggleNode "Toggle Selected Nodes On/Off (Ctrl+P)" filter:anythingSelected --enabled:((KrakatoaChannelNodeEditor_Rollout.getSelectedNodes()).count > 0)
		separator sep_320 filter:anythingSelected
		fn clipboardFull = (KrakatoaChannelEditor_ClipboardArray.count > 0) 
		menuItem mnu_copyToClipboard "Copy Selected Nodes (Ctrl+C)" filter:anythingSelected --enabled:((KrakatoaChannelNodeEditor_Rollout.getSelectedNodes()).count > 0) 
		menuItem mnu_pasteFromClipboard "Paste (Ctrl+V)" filter:clipboardFull 
		separator sep_330 filter:anythingSelected
		
		subMenu "Disconnect..." filter:anythingSelected
		(
			menuItem mnu_disconnectAllInputsSel "Disconnect All Inputs Of Selected Nodes"	
			menuItem mnu_disconnectAllOutputsSel "Disconnect All Outputs Of Selected Nodes" --enabled:((KrakatoaChannelNodeEditor_Rollout.getSelectedNodes()).count > 0)
		)	
		separator sep_340 filter:anythingSelected
		menuItem mnu_deleteSelectedNodes "Delete Selected Nodes (Del.)" filter:anythingSelected --enabled:((KrakatoaChannelNodeEditor_Rollout.getSelectedNodes()).count > 0)

		
		on mnu_UnExposeSelectedInputs picked do
			KrakatoaChannelNodeEditor_Rollout.unexposeSelectedInputs()
		on mnu_ExposeSelectedInputs picked do
			KrakatoaChannelNodeEditor_Rollout.exposeSelectedInputs()
		on mnu_updateExposedInputs picked do
			KrakatoaChannelsEditor_Functions.exposeControlsToModifier KrakatoaChannelNodeEditor_CurrentModifier			
		on mnu_selectExposedInputs picked do
			KrakatoaChannelNodeEditor_Rollout.selectExposedInputs()

		on mnu_endEditingBLOP picked do
			KrakatoaChannelsEditor_Functions.endEditingBLOP()

		on mnu_DepotOn picked do
		(
			DepotPlacement = #bottom
			setIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "ParticleChannelEditor" "DepotPlacement" (DepotPlacement  as string)
			KrakatoaChannelsEditor_Functions.KrakatoaChannelEditor_UpdateDepot()
		)
		
		on mnu_disconnectAllInputsSel picked do
			KrakatoaChannelNodeEditor_Rollout.disconnectAllInputs Single:false
		
		on mnu_disconnectAllOutputsSel picked do
			KrakatoaChannelNodeEditor_Rollout.disconnectAllOutputs Single:false
	
		on mnu_saveBLOPDefinition picked do KrakatoaChannelNodeEditor_Rollout.saveBLOPDefinition()
			
		on mnu_copyToClipboard  picked do
			KrakatoaChannelNodeEditor_Rollout.copySelectionToClipboard()

		on mnu_pasteFromClipboard  picked do
			KrakatoaChannelNodeEditor_Rollout.pasteSelectionFromClipboard()
		
		on mnu_addNewBLOP picked do 
		(
			KrakatoaChannelNodeEditor_Rollout.addNewBLOP creationType:#rcmenu
			if AutoReorderToggle do autoReorderFlow createUndo:false
			if AutoZoomExtents do zoomExtents createUndo:false				
		)
		
		on mnu_addNewBLOPInline picked do
			KrakatoaChannelNodeEditor_Rollout.createBLOPInline creationType:#rcmenu 

		on mnu_swapInputs picked do
			KrakatoaChannelNodeEditor_Rollout.swapInputsOrder Single:false
		
		on mnu_swapSecondInputs picked do
			KrakatoaChannelNodeEditor_Rollout.swapInputsOrder Single:false Last:true
			
		
		on mnu_toggleNode picked do
			KrakatoaChannelNodeEditor_Rollout.setPassThrough Single:false
		
		on mnu_deleteSelectedNodes picked do
			KrakatoaChannelNodeEditor_Rollout.deleteSelectedNodes()
		
		on mnu_resetPan picked do
			KrakatoaChannelNodeEditor_Rollout.resetPanFactor()

		on mnu_resetZoom picked do
			KrakatoaChannelNodeEditor_Rollout.resetZoomFactor()
		
		on mnu_ZoomExtents picked do
			KrakatoaChannelNodeEditor_Rollout.ZoomExtents()
		
		on mnu_ZoomExtentsSelected picked do
			KrakatoaChannelNodeEditor_Rollout.ZoomExtentsSelected()
		
		on mnu_addPositionChannel picked do
			KrakatoaChannelNodeEditor_Rollout.addNewInput type:#channel channelName:"Position" creationType:#rcmenu
		
		
		on mnu_addColorChannel picked do
			KrakatoaChannelNodeEditor_Rollout.addNewInput type:#channel channelName:"Color" creationType:#rcmenu
		on mnu_addDensityChannel picked do
			KrakatoaChannelNodeEditor_Rollout.addNewInput type:#channel channelName:"Density" creationType:#rcmenu
		
		on mnu_addEmissionChannel picked do 
			KrakatoaChannelNodeEditor_Rollout.addNewInput type:#channel channelName:"Emission" creationType:#rcmenu
		on mnu_addAbsorptionChannel picked do 
			KrakatoaChannelNodeEditor_Rollout.addNewInput type:#channel channelName:"Absorption" creationType:#rcmenu
			
		on mnu_addOrientationChannel picked do 
			KrakatoaChannelNodeEditor_Rollout.addNewInput type:#channel channelName:"Orientation" creationType:#rcmenu
			
		on mnu_addMtlIndexChannel picked do 
			KrakatoaChannelNodeEditor_Rollout.addNewInput type:#channel channelName:"MtlIndex" creationType:#rcmenu
			
		on mnu_addSelectionChannel picked do 
			KrakatoaChannelNodeEditor_Rollout.addNewInput type:#channel channelName:"Selection" creationType:#rcmenu
		
		
		on mnu_addVelocityChannel picked do
			KrakatoaChannelNodeEditor_Rollout.addNewInput type:#channel channelName:"Velocity" creationType:#rcmenu
		on mnu_addNormalChannel picked do
			KrakatoaChannelNodeEditor_Rollout.addNewInput type:#channel channelName:"Normal" creationType:#rcmenu
		on mnu_addTangentChannel picked do
			KrakatoaChannelNodeEditor_Rollout.addNewInput type:#channel channelName:"Tangent" creationType:#rcmenu
		/*on mnu_addLightingChannel picked do
			KrakatoaChannelNodeEditor_Rollout.addNewInput type:#channel channelName:"Lighting" creationType:#rcmenu*/
		on mnu_addMappingChannel picked do
			KrakatoaChannelNodeEditor_Rollout.addNewInput type:#channel channelName:"TextureCoord" creationType:#rcmenu
		on mnu_addAgeChannel picked do
			KrakatoaChannelNodeEditor_Rollout.addNewInput type:#channel channelName:"Age" creationType:#rcmenu
		on mnu_addLifeSpanChannel picked do
			KrakatoaChannelNodeEditor_Rollout.addNewInput type:#channel channelName:"LifeSpan" creationType:#rcmenu
		
		on mnu_addIDChannel picked do
			KrakatoaChannelNodeEditor_Rollout.addNewInput type:#channel channelName:"ID" creationType:#rcmenu
		
		on mnu_addInputFloat picked do
			KrakatoaChannelNodeEditor_Rollout.addNewInput type:#value valueType:#float creationType:#rcmenu

		on mnu_addInputInteger picked do
			KrakatoaChannelNodeEditor_Rollout.addNewInput type:#value valueType:#integer creationType:#rcmenu

		on mnu_addInputVector picked do
			KrakatoaChannelNodeEditor_Rollout.addNewInput type:#value valueType:#vector creationType:#rcmenu
		
		--on mnu_addInputTime picked do KrakatoaChannelNodeEditor_Rollout.addNewInput type:#time creationType:#rcmenu

		on mnu_addInputScript picked do
			KrakatoaChannelNodeEditor_Rollout.addNewInput type:#script creationType:#rcmenu
		
		on mnu_addInputTextureMap picked do 
			KrakatoaChannelNodeEditor_Rollout.addNewInput type:#TextureMap creationType:#rcmenu
		
		on mnu_addChannelOperator picked do
			KrakatoaChannelNodeEditor_Rollout.addNewOperator creationType:#rcmenu

		on mnu_addAddOperator picked do
			KrakatoaChannelNodeEditor_Rollout.addNewOperator type:"Add" creationType:#rcmenu
		
		on mnu_addSubtractOperator picked do
			KrakatoaChannelNodeEditor_Rollout.addNewOperator type:"Subtract" creationType:#rcmenu
		
		on mnu_addMultiplyOperator picked do
			KrakatoaChannelNodeEditor_Rollout.addNewOperator type:"Multiply" creationType:#rcmenu
		
		on mnu_addDivideOperator picked do
			KrakatoaChannelNodeEditor_Rollout.addNewOperator type:"Divide" creationType:#rcmenu
		
		on mnu_addPowerOperator picked do
			KrakatoaChannelNodeEditor_Rollout.addNewOperator type:"Power" creationType:#rcmenu
			
		on mnu_addSquareRootOperator picked do
			KrakatoaChannelNodeEditor_Rollout.addNewOperator type:"SquareRoot" creationType:#rcmenu

		on mnu_addModuloOperator picked do
			KrakatoaChannelNodeEditor_Rollout.addNewOperator type:"Modulo" creationType:#rcmenu
				
		on mnu_addLogOperator picked do
			KrakatoaChannelNodeEditor_Rollout.addNewOperator type:"Logarithm" creationType:#rcmenu
			
		on mnu_addAbsoluteValueOperator picked do
			KrakatoaChannelNodeEditor_Rollout.addNewOperator type:"AbsoluteValue" creationType:#rcmenu

		on mnu_addFloorOperator picked do
			KrakatoaChannelNodeEditor_Rollout.addNewOperator type:"Floor" creationType:#rcmenu

		on mnu_addCeilOperator picked do
			KrakatoaChannelNodeEditor_Rollout.addNewOperator type:"Ceil" creationType:#rcmenu

		on mnu_addNegateOperator picked do
			KrakatoaChannelNodeEditor_Rollout.addNewOperator type:"Negate" creationType:#rcmenu
		
		on mnu_addBlendOperator picked do
			KrakatoaChannelNodeEditor_Rollout.addNewOperator type:"Blend" creationType:#rcmenu
		
		on mnu_addClampOperator picked do
			KrakatoaChannelNodeEditor_Rollout.addNewOperator type:"Clamp" creationType:#rcmenu
		
		on mnu_addCurveOperator picked do
			KrakatoaChannelNodeEditor_Rollout.addNewOperator type:"Curve" creationType:#rcmenu

		on mnu_addNoiseOperator picked do
			KrakatoaChannelNodeEditor_Rollout.addNewOperator type:"Noise" creationType:#rcmenu
            
        on mnu_addDNoiseOperator picked do
            KrakatoaChannelNodeEditor_Rollout.addNewOperator type:"DNoise" creationType:#rcmenu
		
		on mnu_addNormalizeOperator picked do 
			KrakatoaChannelNodeEditor_Rollout.addNewOperator type:"Normalize" creationType:#rcmenu

		on mnu_addMagnitude picked do 
			KrakatoaChannelNodeEditor_Rollout.addNewOperator type:"Magnitude" creationType:#rcmenu

		on mnu_addComponentSum picked do 
			KrakatoaChannelNodeEditor_Rollout.addNewOperator type:"ComponentSum" creationType:#rcmenu
			

		on mnu_addDotProduct picked do 
			KrakatoaChannelNodeEditor_Rollout.addNewOperator type:"DotProduct" creationType:#rcmenu
		on mnu_addCrossProduct picked do 
			KrakatoaChannelNodeEditor_Rollout.addNewOperator type:"CrossProduct" creationType:#rcmenu
		
		on mnu_addSin picked do 
			KrakatoaChannelNodeEditor_Rollout.addNewOperator type:"Sin" creationType:#rcmenu
		on mnu_addCos picked do 
			KrakatoaChannelNodeEditor_Rollout.addNewOperator type:"Cos" creationType:#rcmenu
		on mnu_addTan picked do 
			KrakatoaChannelNodeEditor_Rollout.addNewOperator type:"Tan" creationType:#rcmenu
		on mnu_addASin picked do 
			KrakatoaChannelNodeEditor_Rollout.addNewOperator type:"ASin" creationType:#rcmenu
		on mnu_addACos picked do 
			KrakatoaChannelNodeEditor_Rollout.addNewOperator type:"ACos" creationType:#rcmenu
		on mnu_addATan picked do 
			KrakatoaChannelNodeEditor_Rollout.addNewOperator type:"ATan"	creationType:#rcmenu	
		on mnu_addATan2 picked do 
			KrakatoaChannelNodeEditor_Rollout.addNewOperator type:"ATan2"	creationType:#rcmenu	


		on mnu_addFromQuat picked do
			KrakatoaChannelNodeEditor_Rollout.addNewOperator type:"FromQuat" creationType:#rcmenu
        on mnu_addToQuat picked do
			KrakatoaChannelNodeEditor_Rollout.addNewOperator type:"ToQuat" creationType:#rcmenu
        on mnu_addToVector picked do 
			KrakatoaChannelNodeEditor_Rollout.addNewOperator type:"ToVector" creationType:#rcmenu	
		on mnu_addToFloat picked do 
			KrakatoaChannelNodeEditor_Rollout.addNewOperator type:"ToFloat" creationType:#rcmenu	
		on mnu_addToInteger picked do 
			KrakatoaChannelNodeEditor_Rollout.addNewOperator type:"ToInteger" creationType:#rcmenu	
		on mnu_addToScalar picked do 
			KrakatoaChannelNodeEditor_Rollout.addNewOperator type:"ToScalar" creationType:#rcmenu


		on mnu_addToWorldOperator picked do 
			KrakatoaChannelNodeEditor_Rollout.addNewOperator type:"ToWorld" creationType:#rcmenu	
		on mnu_addFromWorldOperator picked do 
			KrakatoaChannelNodeEditor_Rollout.addNewOperator type:"FromWorld" creationType:#rcmenu	
		on mnu_addToSpaceOperator picked do 
			KrakatoaChannelNodeEditor_Rollout.addNewOperator type:"ToSpace" creationType:#rcmenu	
		on mnu_addFromSpaceOperator picked do 
			KrakatoaChannelNodeEditor_Rollout.addNewOperator type:"FromSpace" creationType:#rcmenu	
		on mnu_addToViewOperator picked do 
			KrakatoaChannelNodeEditor_Rollout.addNewOperator type:"ToView" creationType:#rcmenu	
		on mnu_addFromViewOperator picked do 
			KrakatoaChannelNodeEditor_Rollout.addNewOperator type:"FromView" creationType:#rcmenu	
		on mnu_addTransformByQuat picked do
			KrakatoaChannelNodeEditor_Rollout.addNewOperator type:"TransformByQuat" creationType:#rcmenu

		on mnu_dataValueOperator picked do 
			KrakatoaChannelNodeEditor_Rollout.addNewOperator type:"SurfDataValue" creationType:#rcmenu	
		--on mnu_ValidDataValueOperator picked do 
			--KrakatoaChannelNodeEditor_Rollout.addNewOperator type:"ValidSurfData" creationType:#rcmenu	
		
		
		on mnu_rayIntersectOperator picked do 
			KrakatoaChannelNodeEditor_Rollout.addNewOperator type:"RayIntersect" creationType:#rcmenu	
		on mnu_nearestPointOperator picked do 
			KrakatoaChannelNodeEditor_Rollout.addNewOperator type:"NearestPoint" creationType:#rcmenu			
		

		on mnu_addLessOperator picked do 
			KrakatoaChannelNodeEditor_Rollout.addNewOperator type:"Less" creationType:#rcmenu
		on mnu_addLessOrEqualOperator picked do 
			KrakatoaChannelNodeEditor_Rollout.addNewOperator type:"LessOrEqual" creationType:#rcmenu	
		on mnu_addGreaterOperator picked do 
			KrakatoaChannelNodeEditor_Rollout.addNewOperator type:"Greater" creationType:#rcmenu
		on mnu_addGreaterOrEqualOperator picked do 
			KrakatoaChannelNodeEditor_Rollout.addNewOperator type:"GreaterOrEqual" creationType:#rcmenu
		on mnu_addEqualOperator picked do 
			KrakatoaChannelNodeEditor_Rollout.addNewOperator type:"Equal"	creationType:#rcmenu
		
		on mnu_addAndOperator picked do 
			KrakatoaChannelNodeEditor_Rollout.addNewOperator type:"LogicalAnd" creationType:#rcmenu	
		on mnu_addOrOperator picked do 
			KrakatoaChannelNodeEditor_Rollout.addNewOperator type:"LogicalOr" creationType:#rcmenu		
		on mnu_addNotOperator picked do 
			KrakatoaChannelNodeEditor_Rollout.addNewOperator type:"LogicalNot" creationType:#rcmenu	

		on mnu_addSwitchOperator picked do
			KrakatoaChannelNodeEditor_Rollout.addNewOperator type:"Switch" creationType:#rcmenu
		
	)	
	
	rcmenu KrakatoaChannelEditor_EditNode_RCMenu 
	(
		fn isOperatorUnderMouse = ( (KrakatoaChannelNodeEditor_Rollout.lastNodeClick > 1 and KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][1] == "Operator") )
		fn isInputUnderMouse = ( (KrakatoaChannelNodeEditor_Rollout.lastNodeClick > 1 and KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][1] == "Input") )
		fn anythingSelected =((KrakatoaChannelNodeEditor_Rollout.getSelectedNodes()).count > 0)
		fn moreThanOneSelected = ((KrakatoaChannelNodeEditor_Rollout.getSelectedNodes()).count > 1)
		fn canExposeControl = (KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][3][1] == "Value") --and KrakatoaChannelEditor_NodeTreeEditingLevel.count == 0
		fn isBlackopUnderMouse = (KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][1]=="BlackOp")
		fn isBlackopOrSelection = isBlackopUnderMouse() or anythingSelected()
		fn canPaste = (KrakatoaChannelEditor_ClipboardArray.count > 0)
		fn canPasteOrSelected = (canPaste() or anythingSelected())
		fn isInBlackOpEditingMode = (KrakatoaChannelEditor_NodeTreeEditingLevel.count > 0)
		fn moreThanOneSelectedOrBLOP = (moreThanOneSelected() or isBlackopUnderMouse())
		
		menuItem mnu_endEditingBLOP "Exit BlackOp Editing Mode" filter:isInBlackOpEditingMode
		separator sep_1 filter:isInBlackOpEditingMode
		
		menuItem mnu_editBLOP "Edit BlackOp" filter:isBlackopUnderMouse
		--menuItem mnu_closeBLOP "Close BlackOp" filter:isBlackopOpen
		
		menuItem mnu_addNewBLOPInline "[BlackOp] From Selection" filter:moreThanOneSelected
		menuItem mnu_saveBLOPDefinition "Save Selection As BlackOP" filter:moreThanOneSelected
		menuItem mnu_explodeBLOP "Explode BlackOp" filter:isBlackopUnderMouse
		separator sep_10 filter:moreThanOneSelectedOrBLOP
		
		menuItem mnu_exposeControl "Expose Control" filter:canExposeControl  checked:(KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][4][12] == true)
		subMenu "Expose Selected..." filter:anythingSelected
		(
			menuitem mnu_selectExposedInputs "Select Exposed Inputs"
			menuitem mnu_UnExposeSelectedInputs "Unexpose Selected Inputs"
			menuitem mnu_ExposeSelectedInputs "Expose Selected Inputs"
			separator sep_500
			menuitem mnu_updateExposedInputs "Update Exposed Inputs"
		)
		
		separator sep_2 filter:canExposeControl
		
		menuItem mnu_disconnectAllInputs "Disconnect All Inputs"	
		menuItem mnu_disconnectAllOutputs "Disconnect All Outputs"	
		menuItem mnu_disconnectAllInputsSel "Disconnect All Inputs Of Selected Nodes"	filter:anythingSelected
		menuItem mnu_disconnectAllOutputsSel "Disconnect All Outputs Of Selected Nodes" filter:anythingSelected
		
		
		separator sep_100 filter:isBlackopOrSelection
		
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

		
		menuItem mnu_deleteNode "Delete Node Under Mouse Pointer"	
		menuItem mnu_deleteSelectedNodes "Delete Selected Nodes (Del.)" filter:anythingSelected
		
		on mnu_explodeBLOP picked do
		(
			KrakatoaChannelsEditor_Functions.updateParentModifier()
			/*if KrakatoaChannelEditor_NodeTreeEditingLevel.count == 0 then
			(
				--THIS WORKS ONLY AT TOP LEVEL
				KrakatoaChannelNodeEditor_CurrentModifier.internalFlow = KrakatoaChannelsEditor_Functions.expandFlow KrakatoaChannelNodeEditor_CurrentModifier.internalFlow specificNode:KrakatoaChannelNodeEditor_Rollout.lastNodeClick
				KrakatoaChannelNodeEditor_CurrentModifier.Flow = KrakatoaChannelsEditor_Functions.expandFlow KrakatoaChannelNodeEditor_CurrentModifier.internalFlow 
				KrakatoaChannelEditor_BaseNodeTreeData = execute KrakatoaChannelNodeEditor_CurrentModifier.internalFlow 
				KrakatoaChannelsEditor_Functions.buildDisplayTree()
				KrakatoaChannelNodeEditor_Rollout.createNodeTree init:true
				if AutoReorderToggle do KrakatoaChannelNodeEditor_Rollout.autoReorderFlow createUndo:false	
				if AutoZoomExtents do KrakatoaChannelNodeEditor_Rollout.zoomExtents createUndo:false
				KrakatoaChannelNodeEditor_Rollout.createUndoRecord "Explode BlackOp"	
				KrakatoaChannelNodeEditor_Rollout.displaySelectedNodeProperties()
			)
			else*/
			(
				local theLastIndex = KrakatoaChannelNodeEditor_Rollout.lastNodeClick
				local theConvertedFlow = deepCopy KrakatoaChannelEditor_DisplayNodeTreeData
				local theNode = deepcopy theConvertedFlow[theLastIndex][3][2]
				local basePos = theConvertedFlow[theLastIndex][4][1] 
				local theOldCount = theConvertedFlow.count --store the number of nodes before expansion
				local theOutputConnector = 0		
				
				for j = 1 to theNode.count do --go through all nodes in the BlackOps def
				(
					if theNode[j][1] == "Operator" and theConvertedFlow[theLastIndex][5] == false do theNode[j][5] = false --if BlackOp set to PassThrough, do the same for all its Operators
						
					--theNode[j][4][13] = deepCopy theConvertedFlow[i][4][13] --get the navigation array of the parent 
					--append theNode[j][4][13] j --and store the parent of this node for error display
					
					try(theNode[j][4][1] += basePos-[300,100])catch()
					
					for c = 1 to theNode[j][2].count where theNode[j][2][c] != undefined and theNode[j][2][c] > 0 do
						theNode[j][2][c] += theOldCount
					if theNode[j][1] == "OutputConnector" do theOutputConnector = theNode[j][2][1]
				)	
				join theConvertedFlow theNode --add the content of the BLOP to the top level array
				
				--go through all nodes and see who was connected to the BLOP. Reconnect to the BLOP node that was connected to the Output Connector
				if theOutputConnector > 0 do						
					for k = 1 to theOldCount do --loop through existing nodes pre-exploding
						for c = 1 to theConvertedFlow[k][2].count where theConvertedFlow[k][2][c] == theLastIndex do theConvertedFlow[k][2][c] = theOutputConnector
						
				--collect all Connectors of the exploded BLOP
				local theConnectors = for j = theOldCount+1 to theConvertedFlow.count where theConvertedFlow[j][1] == "Connector" collect j
					
				for c = 1 to theConnectors.count do
				(
					if theConvertedFlow[theLastIndex][2][c] == undefined do theConvertedFlow[theLastIndex][2][c] = 0 --reset all connections of the BLOP itself that are not connected yet
					local theConnectorIndex = theConnectors[c] --contains the connector node index
					local theNodeToConnect1 = theConvertedFlow[theLastIndex][2][c] --points at a node in original flow that should be connected to the expanded node
					for j = theOldCount+1 to theConvertedFlow.count do 
						for k = 1 to theConvertedFlow[j][2].count do
							if theConvertedFlow[j][2][k] == theConnectorIndex do
								theConvertedFlow[j][2][k] = theNodeToConnect1
				)
				
				--delete the connector nodes from the expanded flow:
				for j = theConvertedFlow.count to theOldCount+1 by -1 do
				(
					if theConvertedFlow[j][1] == "Connector" or theConvertedFlow[j][1] == "OutputConnector" do 
					(
						deleteItem theConvertedFlow j --delete the connector node									
						for k = 1 to theConvertedFlow.count do --then go though all nodes on the list and if they were connecting to the 
							for c = 1 to theConvertedFlow[k][2].count where theConvertedFlow[k][2][c] != undefined and theConvertedFlow[k][2][c] >= j do 
								theConvertedFlow[k][2][c] -= 1
					)
				)--end j loop
				
				deleteItem theConvertedFlow theLastIndex  --delete the original BLOP
				--now renumber all connections in all nodes pointing at nodes above the deleted one by subtracting 1:
				for j = 1 to theConvertedFlow.count do
					for c = 1 to theConvertedFlow[j][2].count where theConvertedFlow[j][2][c] != undefined and theConvertedFlow[j][2][c] >= theLastIndex do 
						theConvertedFlow[j][2][c] -= 1
					
				KrakatoaChannelEditor_DisplayNodeTreeData = deepCopy theConvertedFlow
					
				KrakatoaChannelNodeEditor_Rollout.createNodeTree init:true
				if AutoReorderToggle do KrakatoaChannelNodeEditor_Rollout.autoReorderFlow createUndo:false	
				if AutoZoomExtents do KrakatoaChannelNodeEditor_Rollout.zoomExtents createUndo:false
				KrakatoaChannelNodeEditor_Rollout.createUndoRecord "Explode BlackOp"	
				KrakatoaChannelNodeEditor_Rollout.displaySelectedNodeProperties()					
			)
			
		)			
		
		on mnu_flipSocketPosition picked do
		(
			if KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][4][14] == undefined do
				KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][4][14] = false
			KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][4][14] = not KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][4][14]
			KrakatoaChannelNodeEditor_Rollout.createNodeTree init:true
			KrakatoaChannelNodeEditor_Rollout.createUndoRecord "Flip Socket Position"	
		)
		
		on mnu_editBLOP  picked do 
		(
			KrakatoaChannelsEditor_Functions.EditBlop KrakatoaChannelNodeEditor_Rollout.lastNodeClick
		)
		
		on mnu_UnExposeSelectedInputs picked do
			KrakatoaChannelNodeEditor_Rollout.unexposeSelectedInputs()
		on mnu_ExposeSelectedInputs picked do
			KrakatoaChannelNodeEditor_Rollout.exposeSelectedInputs()
		on mnu_updateExposedInputs picked do
			KrakatoaChannelsEditor_Functions.exposeControlsToModifier KrakatoaChannelNodeEditor_CurrentModifier			
		on mnu_selectExposedInputs picked do
			KrakatoaChannelNodeEditor_Rollout.selectExposedInputs()		
		
		on mnu_endEditingBLOP picked do
			KrakatoaChannelsEditor_Functions.endEditingBLOP()
		
		on mnu_saveBLOPDefinition picked do KrakatoaChannelNodeEditor_Rollout.saveBLOPDefinition()
		on mnu_addNewBLOPInline picked do
			KrakatoaChannelNodeEditor_Rollout.createBLOPInline creationType:#rcmenu 		
		
		on mnu_disconnectAllInputs picked do
			KrakatoaChannelNodeEditor_Rollout.disconnectAllInputs Single:true
		
		on mnu_disconnectAllOutputs picked do
			KrakatoaChannelNodeEditor_Rollout.disconnectAllOutputs Single:true

		on mnu_disconnectAllInputsSel picked do
			KrakatoaChannelNodeEditor_Rollout.disconnectAllInputs Single:false
		
		on mnu_disconnectAllOutputsSel picked do
			KrakatoaChannelNodeEditor_Rollout.disconnectAllOutputs Single:false
		
		on mnu_copyToClipboard  picked do
			KrakatoaChannelNodeEditor_Rollout.copySelectionToClipboard()

		on mnu_pasteFromClipboard  picked do
			KrakatoaChannelNodeEditor_Rollout.pasteSelectionFromClipboard()		

		on mnu_parentSelectedNodes picked do
			KrakatoaChannelNodeEditor_Rollout.parentSelectedNodes()

		on mnu_unparentSelectedNodes picked do
			KrakatoaChannelNodeEditor_Rollout.unparentSelectedNodes()
		
		on mnu_swapInputs picked do KrakatoaChannelNodeEditor_Rollout.swapInputsOrder Single:true
		on mnu_swapLastInputs picked do KrakatoaChannelNodeEditor_Rollout.swapInputsOrder Single:true Last:true
			
		on mnu_toggleNode picked do
			KrakatoaChannelNodeEditor_Rollout.setPassThrough Single:true
		on mnu_toggleNodeSel picked do
			KrakatoaChannelNodeEditor_Rollout.setPassThrough Single:false
		
		on mnu_exposeControl picked do
		(
			if KrakatoaChannelNodeEditor_Rollout.lastNodeClick > 1 do
			(
				if KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][4][12] == undefined do KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][4][12] = false
				KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][4][12] = not KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][4][12] 
				if KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][4][12] then
					KrakatoaChannelNodeEditor_Rollout.createUndoRecord ("Expose Input Node")				
				else
					KrakatoaChannelNodeEditor_Rollout.createUndoRecord ("Unexpose Input Node")				
				if KrakatoaChannelEditor_NodeTreeEditingLevel.count == 0 do 
					KrakatoaChannelsEditor_Functions.exposeControlsToModifier KrakatoaChannelNodeEditor_CurrentModifier
				KrakatoaChannelNodeEditor_Rollout.createNodeTree init:false
			)
		)
		
		
		on mnu_deleteNode picked do
		(
			if KrakatoaChannelNodeEditor_Rollout.lastNodeClick > 1 do
			(
				local expandedFlow = execute (KrakatoaChannelsEditor_Functions.expandFlow (with PrintAllElements true KrakatoaChannelEditor_DisplayNodeTreeData as string) fixTracks:true)
				local oldExposure = for i = 1 to expandedFlow.count where expandedFlow[i][4][12] == true collect i
				
				for i = 1 to KrakatoaChannelEditor_DisplayNodeTreeData.count do
				(
					for j = 1 to KrakatoaChannelEditor_DisplayNodeTreeData[i][2].count do
					(
						if KrakatoaChannelEditor_DisplayNodeTreeData[i][2][j] == KrakatoaChannelNodeEditor_Rollout.lastNodeClick do
							KrakatoaChannelEditor_DisplayNodeTreeData[i][2][j] = 0
						if KrakatoaChannelEditor_DisplayNodeTreeData[i][2][j] > KrakatoaChannelNodeEditor_Rollout.lastNodeClick do
							KrakatoaChannelEditor_DisplayNodeTreeData[i][2][j] -= 1
					)	
				)
				deleteItem KrakatoaChannelEditor_DisplayNodeTreeData KrakatoaChannelNodeEditor_Rollout.lastNodeClick
				KrakatoaChannelNodeEditor_Rollout.createNodeTree init:true
				KrakatoaChannelNodeEditor_Rollout.createUndoRecord "Delete Node"
				
				local expandedFlow = execute (KrakatoaChannelsEditor_Functions.expandFlow (with PrintAllElements true KrakatoaChannelEditor_DisplayNodeTreeData as string) fixTracks:true)
				local newExposure = for i = 1 to expandedFlow.count where expandedFlow[i][4][12] == true collect i
				if newExposure as string != oldExposure as string do KrakatoaChannelsEditor_Functions.exposeControlsToModifier KrakatoaChannelNodeEditor_CurrentModifier

				KrakatoaChannelNodeEditor_Rollout.displaySelectedNodeProperties()
			)	
		)
		
		on mnu_deleteSelectedNodes picked do
		(
			KrakatoaChannelNodeEditor_Rollout.deleteSelectedNodes()
		)			
	)
	
	rcmenu KrakatoaChannelNodeEditor_DepotMenu
	(
		fn categoriesOn = (DepotShowCategories)
		menuItem mnu_DepotOff "Depot Off" checked: (DepotPlacement == #off)
		menuItem mnu_DepotLeft "Depot On Left" checked: (DepotPlacement == #left)
		menuItem mnu_DepotBottom "Depot At Bottom" checked: (DepotPlacement == #bottom)
		menuItem mnu_DepotBottomRollup "Depot At Bottom - Rollup" checked: (DepotPlacement == #bottomrollup)
		menuItem mnu_DepotBottomRollupReverse "Depot At Bottom - Reverse Rollup" checked: (DepotPlacement == #bottomrollupreverse)
		separator sep_10
		
		menuItem mnu_DepotShowBLOPs "Show BlackOp Categories In Depot" checked:DepotShowBLOPs
		
		separator sep_20
		menuItem mnu_DepotShowCategories "Use Depot Categories" checked:DepotShowCategories
		menuItem mnu_DepotAutoCollapseOnDragAndDrop "Auto-Collapse Categories On DragAndDrop" checked:DepotAutoCollapseOnDragAndDrop
		separator sep_30 filter:categoriesOn
		menuItem mnu_expandAllCategories "Expand All Categories (Shift+Click Category)" filter:categoriesOn
		menuItem mnu_collapseAllCategories "Collapse All Categories (Ctrl+Shift+Click Category)" filter:categoriesOn
		
		on mnu_collapseAllCategories picked do
		(
			for i = 1 to KrakatoaChannelEditor_theDepotNodesArray.count do KrakatoaChannelEditor_theDepotNodesArray[i][1][6] = false
			KrakatoaChannelsEditor_Functions.KrakatoaChannelEditor_UpdateDepot()			
			if AutoZoomExtents do KrakatoaChannelNodeEditor_Rollout.zoomExtents createUndo:false			
		)

		on mnu_expandAllCategories picked do
		(
			for i = 1 to KrakatoaChannelEditor_theDepotNodesArray.count do KrakatoaChannelEditor_theDepotNodesArray[i][1][6] = true
			KrakatoaChannelsEditor_Functions.KrakatoaChannelEditor_UpdateDepot()			
			if AutoZoomExtents do KrakatoaChannelNodeEditor_Rollout.zoomExtents createUndo:false
		)		
		
		
		on mnu_DepotShowCategories picked do 
		(
			DepotShowCategories = not DepotShowCategories
			setIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "ParticleChannelEditor" "DepotShowCategories" (DepotShowCategories as string)
			if not DepotShowCategories and (DepotPlacement == #bottomrollup or DepotPlacement == #bottomrollupreverse) do 
			(
				DepotPlacement = #bottom
				setIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "ParticleChannelEditor" "DepotPlacement" (DepotPlacement  as string)
			)	
			KrakatoaChannelsEditor_Functions.KrakatoaChannelEditor_UpdateDepot()
			if AutoZoomExtents do KrakatoaChannelNodeEditor_Rollout.zoomExtents createUndo:false	
		)		

		on mnu_DepotAutoCollapseOnDragAndDrop picked do 
		(
			DepotAutoCollapseOnDragAndDrop = not DepotAutoCollapseOnDragAndDrop
			setIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "ParticleChannelEditor" "DepotAutoCollapseOnDragAndDrop" (DepotAutoCollapseOnDragAndDrop as string)
			KrakatoaChannelNodeEditor_Rollout.CreateDepot()
			KrakatoaChannelsEditor_Functions.KrakatoaChannelEditor_UpdateDepot()
			if AutoZoomExtents do KrakatoaChannelNodeEditor_Rollout.zoomExtents createUndo:false	
		)			
		
		on mnu_DepotShowBLOPs picked do 
		(
			DepotShowBLOPs = not DepotShowBLOPs
			setIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "ParticleChannelEditor" "DepotShowBLOPs" (DepotShowBLOPs as string)
			KrakatoaChannelNodeEditor_Rollout.CreateDepot()
			KrakatoaChannelsEditor_Functions.KrakatoaChannelEditor_UpdateDepot()
			if AutoZoomExtents do KrakatoaChannelNodeEditor_Rollout.zoomExtents createUndo:false	
		)			
		
		on mnu_DepotOff picked do 
		(
			DepotPlacement = #off
			setIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "ParticleChannelEditor" "DepotPlacement" (DepotPlacement  as string)
			KrakatoaChannelsEditor_Functions.KrakatoaChannelEditor_UpdateDepot()
			if AutoZoomExtents do KrakatoaChannelNodeEditor_Rollout.zoomExtents createUndo:false	
		)	
		on mnu_DepotLeft picked do 
		(
			DepotPlacement = #left
			setIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "ParticleChannelEditor" "DepotPlacement" (DepotPlacement  as string)
			KrakatoaChannelNodeEditor_Rollout.CreateDepot()
			KrakatoaChannelsEditor_Functions.KrakatoaChannelEditor_UpdateDepot()
			if AutoZoomExtents do KrakatoaChannelNodeEditor_Rollout.zoomExtents createUndo:false	
		)	
		on mnu_DepotBottom picked do 
		(
			DepotPlacement = #bottom
			setIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "ParticleChannelEditor" "DepotPlacement" (DepotPlacement  as string)
			KrakatoaChannelNodeEditor_Rollout.CreateDepot()
			KrakatoaChannelsEditor_Functions.KrakatoaChannelEditor_UpdateDepot()
			if AutoZoomExtents do KrakatoaChannelNodeEditor_Rollout.zoomExtents createUndo:false	
		)			
		on mnu_DepotBottomRollup picked do
		(
			DepotPlacement = #bottomrollup
			DepotShowCategories = true
			setIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "ParticleChannelEditor" "DepotShowCategories" (DepotShowCategories as string)
			setIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "ParticleChannelEditor" "DepotPlacement" (DepotPlacement  as string)
			KrakatoaChannelNodeEditor_Rollout.CreateDepot()
			KrakatoaChannelsEditor_Functions.KrakatoaChannelEditor_UpdateDepot()			
			if AutoZoomExtents do KrakatoaChannelNodeEditor_Rollout.zoomExtents createUndo:false	
		)
		on mnu_DepotBottomRollupReverse picked do
		(
			DepotPlacement = #bottomrollupreverse
			DepotShowCategories = true
			setIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "ParticleChannelEditor" "DepotShowCategories" (DepotShowCategories as string)
			setIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "ParticleChannelEditor" "DepotPlacement" (DepotPlacement  as string)
			KrakatoaChannelNodeEditor_Rollout.CreateDepot()
			KrakatoaChannelsEditor_Functions.KrakatoaChannelEditor_UpdateDepot()			
			if AutoZoomExtents do KrakatoaChannelNodeEditor_Rollout.zoomExtents createUndo:false	
		)		
	)	
	
	rcmenu KrakatoaChannelNodeEditor_Rollout_MainMenu 
	(
		subMenu "File"
		(
			menuitem mnu_new "&New... (Ctrl+N)"
			separator sep_file_10
			menuitem mnu_open "&Open Flow... (Ctrl+O)"
			menuitem mnu_save "&Save Flow As... (Ctrl+S)"
			separator sep_file_20
			menuItem mnu_exploreFolder "&Explore Flows Folder..."
			separator sep_file_30
			menuItem mnu_RemoveListControllersFromTracks "&Collapse List Controllers For Use in Krakatoa v1.5.x..."
			separator sep_file_50
			menuitem mnu_close "Close... (Ctrl+Q)"
		)
		
		on mnu_RemoveListControllersFromTracks  picked do
		(
			if queryBox "Clicking [Yes] will collapse all Input Value Nodes' Controller for compatibility with Krakatoa v1.5.x.\nUse this if you intend to pass the scene to a user with an older version of Krakatoa.\nKrakatoa v1.6.0 and higher will work with collapsed controllers, but track connections will replace keyframe animation.\nNote that this operation might fail in certain builds of 3ds Max 2011 where custom track controller assignment is broken.\n\nTo keep using List Controllers to store keyframe and track connections separately, click [No].\nThis mode will only work in Krakatoa v1.6.0 and higher." title:"Krakatoa MagmaFlow Compatibility with v1.5.x" do
			(
				KrakatoaChannelsEditor_Functions.RemoveListControllersFromTracks()
				KrakatoaChannelsEditor_Functions.exposeControlsToModifier KrakatoaChannelNodeEditor_CurrentModifier		
			)
		)
		
		
		subMenu "Edit"
		(
			menuitem mnu_undo "Undo (Ctrl+Z)" enabled:KrakatoaChannelNodeEditor_Rollout.btn_undo.enabled
			menuitem mnu_redo "Redo (Ctrl+Y)" enabled:KrakatoaChannelNodeEditor_Rollout.btn_redo.enabled
			separator sep_10
			menuItem mnu_copyToClipboard "Copy (Ctrl+C)" enabled:((KrakatoaChannelNodeEditor_Rollout.getSelectedNodes()).count > 0)
			menuItem mnu_pasteFromClipboard "Paste (Ctrl+V)" enabled:(KrakatoaChannelEditor_ClipboardArray.count > 0)
			separator sep_20
			menuitem mnu_insertMode "Branch/Insert Mode Toggle (Ins)" checked:(nodeInsertMode != true)
			separator sep_25
			menuitem mnu_selectAllNodes "Select All Nodes (Ctrl+A)" 
			menuitem mnu_invertSelection "Invert Selection (Ctrl+I)"
			menuitem mnu_deselectAllNodes "Deselect All Nodes (Ctrl+D)" 
			separator sep_30
			menuitem mnu_selectUnconnectedNodes "Select Unconnected Nodes (Ctrl+U)" 
			menuitem mnu_selectDisabledNodes "Select Disabled Nodes (Ctrl+Shift+U)" 
			menuitem mnu_selectInputNodesOnly "Select All Input Nodes" 
			menuitem mnu_selectOperatorNodesOnly "Select All Operator Nodes" 
			menuitem mnu_selectBlackOpNodesOnly "Select All BlackOp Nodes" 
			separator sep_40
			menuitem mnu_growSelectionChildren "Grow Selection - Add Children (Shift+PgDn)" 
			menuitem mnu_growSelectionParents "Grow Selection - Add Parents (Shift+PgUp)" 
			separator sep_50
			menuitem mnu_deleteSelectedNodes "Delete Selected Nodes (Del)"
		)
		

		subMenu "View"
		(
			menuitem mnu_autoReorderFlow "Reorder Flow Now (Ctrl+R)"
			menuitem mnu_autoReorderToggle "Auto-Reorder - Toggle" checked:AutoReorderToggle 
			
			
			subMenu "Reorder Patterns..."
			(
				menuitem mnu_autoReorderRow "Row Pattern" checked:(AutoReorderPattern == #row)
				menuitem mnu_autoReorderAlignToTop "Top Aligned Row Pattern" checked:(AutoReorderPattern == #rowtopalign)
				menuitem mnu_AutoReorderWeighted "Weighted Row Pattern" checked:(AutoReorderPattern == #rowweighted)
				menuitem mnu_autoReorderPyramidal "Pyramidal Pattern" checked:(AutoReorderPattern == #pyramidal)
				menuitem mnu_autoReorderTree "Tree Pattern" checked:(AutoReorderPattern == #tree)
				menuitem mnu_autoReorderVTree "Vertical Tree Pattern" checked:(AutoReorderPattern == #vtree)
			)	
			
			menuitem mnu_AllowSocketFlipping "Allow Socket Auto-Flipping On Reorder - Toggle" checked:AllowSocketFlipping
			subMenu "Flip Sockets Of..."
			(
				menuitem mnu_InputsLeft "All Input Nodes Out Sockets Left" 
				menuitem mnu_InputsRight "All Input Nodes Out Sockets Right" 
				menuitem mnu_OperatorsLeft "All Operator Nodes Out Sockets Left" 
				menuitem mnu_OperatorsRight "All Operator Nodes Out Sockets Right" 
			)
			
			separator sep_110
			subMenu "Unconnected Nodes Auto-Placement..."
			(
				menuItem mnu_nodesLeft "Left Side Of Flow" checked: (UnconnectedNodesPlacement == #left)
				menuItem mnu_nodesRight "Right Side Of Flow" checked: (UnconnectedNodesPlacement == #right)
				menuItem mnu_nodesBottom "Bottom Of Flow" checked: (UnconnectedNodesPlacement == #bottom)
			)			
			separator sep_120
			menuItem mnu_AllowSubtreeCollapsing "Allow Sub-Tree Collapsing On Double-Click" checked:(AllowSubtreeCollapsing == true)
			
			separator sep_130
			menuItem mnu_AlignAllNodesToGrid "Align All Nodes To Grid (Shift+Ctrl+A)" 
			menuItem mnu_SnapToGrid "Snap To Grid - Toggle (Ctrl+G)" checked:SnapToGrid

			separator sep_140
			menuitem mnu_AutoZoomExtents "Auto-Zoom Extents - Toggle" checked:AutoZoomExtents
			menuItem mnu_ZoomExtents "Zoom Extents (Z)"
			menuItem mnu_ZoomExtentsSelected "Zoom Extents Selected (Shift+Z)"			
			separator sep_150
			menuItem mnu_resetZoom "Reset Zoom (X)"
			menuitem mnu_resetPan "Reset Pan (Shift+X)"
			
			separator sep_160
			subMenu "Depot Display..."
			(
				menuItem mnu_DepotOff "Depot Off" checked: (DepotPlacement == #off)
				menuItem mnu_DepotLeft "Depot On Left" checked: (DepotPlacement == #left)
				menuItem mnu_DepotBottom "Depot At Bottom" checked: (DepotPlacement == #bottom)
				menuItem mnu_DepotBottomRollup "Depot At Bottom - Rollup" checked: (DepotPlacement == #bottomrollup)
				menuItem mnu_DepotBottomRollupReverse "Depot At Bottom - Reverse Rollup" checked: (DepotPlacement == #bottomrollupreverse)
				separator sep_180
				menuItem mnu_DepotShowBLOPs "Show BlackOp Categories In Depot" checked:DepotShowBLOPs
				separator sep_185
				menuItem mnu_DepotShowCategories "Use Depot Categories" checked:DepotShowCategories
				menuItem mnu_DepotAutoCollapseOnDragAndDrop "Auto-Collapse Categories On DragAndDrop" checked:DepotAutoCollapseOnDragAndDrop
			)	
		)
		
		subMenu "Expose"
		(
			menuitem mnu_selectExposedInputs "Select Exposed Inputs"
			menuitem mnu_UnExposeSelectedInputs "Unexpose Selected Inputs"
			menuitem mnu_ExposeSelectedInputs "Expose Selected Inputs"
			separator sep_200
			menuitem mnu_updateExposedInputs "Update Exposed Inputs"
		)
		
		subMenu "Macro"
		(
			menuItem mnu_convertUndoBufferToRecording "Save Undo Buffer As A Macro Recording..."
			separator sep_222
			menuItem mnu_LoadMacroRecording "Load Macro Recording..."
			separator sep_226
			menuitem mnu_EditMacro "Edit Macro" enabled:(KrakatoaChannelEditor_MacroRecording.count > 0)
		)
		
		subMenu "Debug"
		(
			menuItem mnu_debugFlow "Debug Mode" checked:DebugModeOn
		)
		
		on mnu_insertMode picked do
		(
			nodeInsertMode = not nodeInsertMode 
			KrakatoaChannelsEditor_Functions.updateEditorTitle()
		)		
				
		
		on mnu_debugFlow picked do 
		(
			DebugModeOn = not DebugModeOn
			if DebugModeOn then 
				KrakatoaChannelNodeEditor_Rollout.debugFlow()
			else
				KrakatoaChannelNodeEditor_Rollout.createNodeTree init:false
			KrakatoaChannelNodeEditor_Rollout.displaySelectedNodeProperties()
		)	
		
		on mnu_InputsLeft picked do
		(
			KrakatoaChannelNodeEditor_Rollout.flipSockets #input #left
		)
		on mnu_InputsRight picked do
		(
			KrakatoaChannelNodeEditor_Rollout.flipSockets #input #right
		)
		on mnu_OperatorsLeft picked do
		(
			KrakatoaChannelNodeEditor_Rollout.flipSockets #op #left
		)
		on mnu_OperatorsRight picked do
		(
			KrakatoaChannelNodeEditor_Rollout.flipSockets #op #right
		)		
		
		on mnu_convertUndoBufferToRecording picked do
			KrakatoaChannelNodeEditor_Rollout.convertUndoBufferToRecording()
		
		on mnu_EditMacro picked do 
		(
			try(destroyDialog KrakatoaChannelNodeEditor_MacroRecorderEditor)catch()
			createDialog KrakatoaChannelNodeEditor_MacroRecorderEditor 420 300 menu:KrakatoaChannelNodeEditor_MacroRecorderEditorMenu
		)
		
		on mnu_LoadMacroRecording picked do
		(
			KrakatoaChannelNodeEditor_Rollout.LoadMacroRecording()
		)
		
		on mnu_UnExposeSelectedInputs picked do
		(
			KrakatoaChannelNodeEditor_Rollout.unexposeSelectedInputs()
		)
		on mnu_ExposeSelectedInputs picked do
		(
			KrakatoaChannelNodeEditor_Rollout.exposeSelectedInputs()
		)
		
		on mnu_updateExposedInputs picked do
		(
			KrakatoaChannelsEditor_Functions.exposeControlsToModifier KrakatoaChannelNodeEditor_CurrentModifier			
		)	
		on mnu_selectExposedInputs picked do
		(
			KrakatoaChannelNodeEditor_Rollout.selectExposedInputs()
		)
		
		subMenu "Help"
		(
			menuitem mnu_openHelp "Krakatoa MagmaFlow Editor Online Documentation..."
		)
		
		on mnu_growSelectionChildren picked do KrakatoaChannelNodeEditor_Rollout.selectChildrenNodesByParent()
		on mnu_growSelectionParents picked do KrakatoaChannelNodeEditor_Rollout.selectParentNodesByChild()
	
		
		on mnu_DepotShowCategories picked do 
		(
			DepotShowCategories = not DepotShowCategories
			setIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "ParticleChannelEditor" "DepotShowCategories" (DepotShowCategories as string)
			if not DepotShowCategories and (DepotPlacement == #bottomrollup or DepotPlacement == #bottomrollupreverse) do 
			(
				DepotPlacement = #bottom
				setIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "ParticleChannelEditor" "DepotPlacement" (DepotPlacement  as string)
			)
			KrakatoaChannelsEditor_Functions.KrakatoaChannelEditor_UpdateDepot()
		)	

		on mnu_DepotAutoCollapseOnDragAndDrop picked do 
		(
			DepotAutoCollapseOnDragAndDrop = not DepotAutoCollapseOnDragAndDrop
			setIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "ParticleChannelEditor" "DepotAutoCollapseOnDragAndDrop" (DepotAutoCollapseOnDragAndDrop as string)
			KrakatoaChannelsEditor_Functions.KrakatoaChannelEditor_UpdateDepot()
		)		

		on mnu_DepotShowBLOPs picked do 
		(
			DepotShowBLOPs = not DepotShowBLOPs
			setIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "ParticleChannelEditor" "DepotShowBLOPs" (DepotShowBLOPs as string)
			KrakatoaChannelNodeEditor_Rollout.CreateDepot()
			KrakatoaChannelsEditor_Functions.KrakatoaChannelEditor_UpdateDepot()
		)			

		on mnu_invertSelection picked do 
		(
			KrakatoaChannelNodeEditor_Rollout.invertSelection()
			if AutoZoomExtents do KrakatoaChannelNodeEditor_Rollout.zoomExtents createUndo:false	
		)
		
		on mnu_selectUnconnectedNodes picked do
		(
			KrakatoaChannelNodeEditor_Rollout.selectUnconnectedNodes()
			if AutoZoomExtents do KrakatoaChannelNodeEditor_Rollout.zoomExtents createUndo:false				
		)
		
		on mnu_selectOperatorNodesOnly picked do
		(
			KrakatoaChannelNodeEditor_Rollout.selectOperatorNodesOnly()
			if AutoZoomExtents do KrakatoaChannelNodeEditor_Rollout.zoomExtents createUndo:false				
		)

		on mnu_selectInputNodesOnly picked do
		(
			KrakatoaChannelNodeEditor_Rollout.selectInputNodesOnly()
			if AutoZoomExtents do KrakatoaChannelNodeEditor_Rollout.zoomExtents createUndo:false				
		)

		on mnu_selectBlackOpNodesOnly picked do
		(
			KrakatoaChannelNodeEditor_Rollout.selectBlackOpNodesOnly()
			if AutoZoomExtents do KrakatoaChannelNodeEditor_Rollout.zoomExtents createUndo:false				
		)		
		
		on mnu_selectDisabledNodes picked do
		(
			KrakatoaChannelNodeEditor_Rollout.selectDisabledNodes()
			if AutoZoomExtents do KrakatoaChannelNodeEditor_Rollout.zoomExtents createUndo:false					
		)
		
		on mnu_AllowSubtreeCollapsing picked do
		(
			AllowSubtreeCollapsing = not AllowSubtreeCollapsing
			setIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "ParticleChannelEditor" "AllowSubtreeCollapsing" (AllowSubtreeCollapsing as string)
			KrakatoaChannelNodeEditor_Rollout.createNodeTree init:true
		)
		
		on mnu_nodesLeft picked do
		(
			UnconnectedNodesPlacement = #left
			setIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "ParticleChannelEditor" "UnconnectedNodesPlacement" (UnconnectedNodesPlacement  as string)
			if AutoReorderToggle do KrakatoaChannelNodeEditor_Rollout.autoReorderFlow createUndo:false
			if AutoZoomExtents do KrakatoaChannelNodeEditor_Rollout.zoomExtents createUndo:false			
		)
		on mnu_nodesRight picked do
		(
			UnconnectedNodesPlacement = #right
			setIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "ParticleChannelEditor" "UnconnectedNodesPlacement" (UnconnectedNodesPlacement  as string)
			if AutoReorderToggle do KrakatoaChannelNodeEditor_Rollout.autoReorderFlow createUndo:false
			if AutoZoomExtents do KrakatoaChannelNodeEditor_Rollout.zoomExtents createUndo:false			
		)
		on mnu_nodesBottom picked do
		(
			UnconnectedNodesPlacement = #bottom
			setIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "ParticleChannelEditor" "UnconnectedNodesPlacement" (UnconnectedNodesPlacement  as string)
			if AutoReorderToggle do KrakatoaChannelNodeEditor_Rollout.autoReorderFlow createUndo:false
			if AutoZoomExtents do KrakatoaChannelNodeEditor_Rollout.zoomExtents createUndo:false			
		)		

		on mnu_DepotOff picked do 
		(
			DepotPlacement = #off
			setIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "ParticleChannelEditor" "DepotPlacement" (DepotPlacement  as string)
			KrakatoaChannelsEditor_Functions.KrakatoaChannelEditor_UpdateDepot()
		)	
		on mnu_DepotLeft picked do 
		(
			DepotPlacement = #left
			setIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "ParticleChannelEditor" "DepotPlacement" (DepotPlacement  as string)
			KrakatoaChannelNodeEditor_Rollout.CreateDepot()
			KrakatoaChannelsEditor_Functions.KrakatoaChannelEditor_UpdateDepot()
		)	
		on mnu_DepotBottom picked do 
		(
			DepotPlacement = #bottom
			setIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "ParticleChannelEditor" "DepotPlacement" (DepotPlacement  as string)
			KrakatoaChannelNodeEditor_Rollout.CreateDepot()
			KrakatoaChannelsEditor_Functions.KrakatoaChannelEditor_UpdateDepot()
		)	
		on mnu_DepotBottomRollup picked do
		(
			DepotPlacement = #bottomrollup
			DepotShowCategories = true
			setIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "ParticleChannelEditor" "DepotShowCategories" (DepotShowCategories as string)
			setIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "ParticleChannelEditor" "DepotPlacement" (DepotPlacement  as string)
			KrakatoaChannelNodeEditor_Rollout.CreateDepot()
			KrakatoaChannelsEditor_Functions.KrakatoaChannelEditor_UpdateDepot()			
		)
		on mnu_DepotBottomRollupReverse picked do
		(
			DepotPlacement = #bottomrollupreverse
			DepotShowCategories = true
			setIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "ParticleChannelEditor" "DepotShowCategories" (DepotShowCategories as string)
			setIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "ParticleChannelEditor" "DepotPlacement" (DepotPlacement  as string)
			KrakatoaChannelNodeEditor_Rollout.CreateDepot()
			KrakatoaChannelsEditor_Functions.KrakatoaChannelEditor_UpdateDepot()			
		)		
		
		on mnu_copyToClipboard  picked do
			KrakatoaChannelNodeEditor_Rollout.copySelectionToClipboard()

		on mnu_pasteFromClipboard  picked do
			KrakatoaChannelNodeEditor_Rollout.pasteSelectionFromClipboard()			
		
		
		on mnu_autoReorderFlow picked do KrakatoaChannelNodeEditor_Rollout.autoReorderFlow()
		on mnu_AutoZoomExtents picked do
		(
			AutoZoomExtents = not AutoZoomExtents  
			setIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "ParticleChannelEditor" "AutoZoomExtents" (AutoZoomExtents  as string)
			if AutoZoomExtents do KrakatoaChannelNodeEditor_Rollout.zoomExtents()			
		)
		
		on mnu_SnapToGrid picked do
		(
			KrakatoaChannelNodeEditor_Rollout.toggleSnapToGrid()
		)	
		
		on mnu_selectAllNodes picked do KrakatoaChannelNodeEditor_Rollout.selectAllNodes()
		on mnu_deselectAllNodes picked do KrakatoaChannelNodeEditor_Rollout.deselectAllNodes()
		
		on mnu_AutoReorderToggle picked do
		(
			AutoReorderToggle = not AutoReorderToggle 
			setIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "ParticleChannelEditor" "AutoReorderToggle" (AutoReorderToggle as string)
			if AutoReorderToggle do KrakatoaChannelNodeEditor_Rollout.autoReorderFlow()
			--KrakatoaChannelNodeEditor_Rollout.createNodeTree init:true				
			if AutoZoomExtents do KrakatoaChannelNodeEditor_Rollout.zoomExtents createUndo:false	
		)
		
		on mnu_AllowSocketFlipping picked do
		(
			AllowSocketFlipping = not AllowSocketFlipping
			setIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "ParticleChannelEditor" "AllowSocketFlipping" (AllowSocketFlipping as string)
			if AutoReorderToggle do KrakatoaChannelNodeEditor_Rollout.autoReorderFlow()
			if AutoZoomExtents do KrakatoaChannelNodeEditor_Rollout.zoomExtents createUndo:false	
		)
		
		on mnu_autoReorderRow picked do 
		(
			AutoReorderPattern = #row
			setIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "ParticleChannelEditor" "AutoReorderPattern" (AutoReorderPattern as string)
			KrakatoaChannelNodeEditor_Rollout.createNodeTree init:true
			if AutoReorderToggle do KrakatoaChannelNodeEditor_Rollout.autoReorderFlow()
			KrakatoaChannelNodeEditor_Rollout.createNodeTree init:true
			if AutoZoomExtents do KrakatoaChannelNodeEditor_Rollout.zoomExtents createUndo:false	
		)	

		on mnu_autoReorderAlignToTop picked do
		(
			AutoReorderPattern = #rowtopalign
			setIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "ParticleChannelEditor" "AutoReorderPattern" (AutoReorderPattern as string)			
			KrakatoaChannelNodeEditor_Rollout.createNodeTree init:true
			if AutoReorderToggle do KrakatoaChannelNodeEditor_Rollout.autoReorderFlow()
			KrakatoaChannelNodeEditor_Rollout.createNodeTree init:true
			if AutoZoomExtents do KrakatoaChannelNodeEditor_Rollout.zoomExtents createUndo:false	
		)		
		
		on mnu_AutoReorderWeighted picked do 
		(
			AutoReorderPattern = #rowweighted
			setIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "ParticleChannelEditor" "AutoReorderPattern" (AutoReorderPattern as string)
			KrakatoaChannelNodeEditor_Rollout.createNodeTree init:true
			if AutoReorderToggle do KrakatoaChannelNodeEditor_Rollout.autoReorderFlow()
			KrakatoaChannelNodeEditor_Rollout.createNodeTree init:true
			if AutoZoomExtents do KrakatoaChannelNodeEditor_Rollout.zoomExtents createUndo:false				
		)		
		on mnu_autoReorderPyramidal picked do 
		(
			AutoReorderPattern = #pyramidal	
			setIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "ParticleChannelEditor" "AutoReorderPattern" (AutoReorderPattern as string)
			KrakatoaChannelNodeEditor_Rollout.createNodeTree init:true
			if AutoReorderToggle do KrakatoaChannelNodeEditor_Rollout.autoReorderFlow()
			KrakatoaChannelNodeEditor_Rollout.createNodeTree init:true
			if AutoZoomExtents do KrakatoaChannelNodeEditor_Rollout.zoomExtents createUndo:false			
		)	
		on mnu_autoReorderTree picked do 
		(
			AutoReorderPattern = #tree
			setIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "ParticleChannelEditor" "AutoReorderPattern" (AutoReorderPattern as string)
			KrakatoaChannelNodeEditor_Rollout.createNodeTree init:true
			if AutoReorderToggle do KrakatoaChannelNodeEditor_Rollout.autoReorderFlow()
			KrakatoaChannelNodeEditor_Rollout.createNodeTree init:true
			if AutoZoomExtents do KrakatoaChannelNodeEditor_Rollout.zoomExtents createUndo:false			
		)	
		on mnu_autoReorderVTree picked do 
		(
			AutoReorderPattern = #vtree
			setIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "ParticleChannelEditor" "AutoReorderPattern" (AutoReorderPattern as string)
			KrakatoaChannelNodeEditor_Rollout.createNodeTree init:true
			if AutoReorderToggle do KrakatoaChannelNodeEditor_Rollout.autoReorderFlow()
			KrakatoaChannelNodeEditor_Rollout.createNodeTree init:true
			if AutoZoomExtents do KrakatoaChannelNodeEditor_Rollout.zoomExtents createUndo:false			
		)			
		
		
		
		on mnu_AlignAllNodesToGrid picked do KrakatoaChannelNodeEditor_Rollout.alignAllNodesToGrid()
		
		on mnu_undo  picked do KrakatoaChannelNodeEditor_Rollout.undoLastStep()

		on mnu_redo picked do KrakatoaChannelNodeEditor_Rollout.redoLastStep()
		
		on mnu_resetPan picked do KrakatoaChannelNodeEditor_Rollout.resetPanFactor()

		on mnu_resetZoom picked do KrakatoaChannelNodeEditor_Rollout.resetZoomFactor()
		
		on mnu_ZoomExtents picked do KrakatoaChannelNodeEditor_Rollout.ZoomExtents()
		
		on mnu_ZoomExtentsSelected picked do KrakatoaChannelNodeEditor_Rollout.ZoomExtentsSelected()
		
		on mnu_new picked do KrakatoaChannelNodeEditor_Rollout.newFlow()
		
		on mnu_save picked do KrakatoaChannelNodeEditor_Rollout.saveFlowAs()
		
		on mnu_open picked do KrakatoaChannelNodeEditor_Rollout.openFlow()
		
		on mnu_exploreFolder picked do
		(
			shellLaunch	(Krakatoa_PresetsDirectory+ "\\MagmaFlows\\") ""
		)
		
		
		on mnu_deleteSelectedNodes picked do KrakatoaChannelNodeEditor_Rollout.deleteSelectedNodes()
		
		on mnu_close picked do
		(
			destroyDialog KrakatoaChannelNodeEditor_Rollout
		)
	)
	
	
	rollout KrakatoaChannelNodeEditor_OptionsRollout "Display Options" category:1000
	(
		button btn_savePreset "Save Preset..." across:2 width:80 offset:[-5,0]
		button btn_loadPreset "Load Preset..." width:80 offset:[5,0]
		
		group "Background and Grid"
		(
			spinner spn_gridSizeX "Grid Width:" range:[5,100,10] type:#integer fieldwidth:30 across:2 align:#right offset:[38,0]
			button btn_resetgridSizeX "Reset" width:35 align:#right offset:[6,-3]			

			spinner spn_gridSizeY "Grid Height:" range:[5,100,10] type:#integer fieldwidth:30 across:2 align:#right offset:[38,0]
			button btn_resetgridSizeY "Reset" width:35 align:#right offset:[6,-3]			
			
			colorpicker clr_backgroundColor "Background:" align:#right across:2 fieldwidth:40 align:#right offset:[38,0] modal:false
			button btn_resetBackgroundColor "Reset" width:35 align:#right offset:[6,-1]
			
			colorpicker clr_GridColor "Grid:" align:#right across:2 fieldwidth:40 align:#right offset:[38,0] modal:false
			button btn_resetGridColor "Reset" width:35 align:#right offset:[6,-1]
		)
		
		group "Depot"
		(
			dropdownlist ddl_depotPlacement items:#("Disabled","Left","Bottom","Bottom - Rollup","Bottom - Reverse Rollup") width:150 align:#center selection:(findItem #(#off,#left,#bottom,#bottomrollup,#bottomrollupreverse) DepotPlacement)
			
			spinner spn_DepotNodeWidth "Item Width:" type:#integer range:[20,200,DepotNodeWidth] fieldwidth:30 across:2  align:#right offset:[38,0]
			button btn_resetDepotNodeWidth "Reset" width:35 align:#right offset:[6,-3]			
			
			colorpicker clr_CategoryOnColor "Category:" align:#right across:2 fieldwidth:40 align:#right offset:[38,0] modal:false
			button btn_resetCategoryOnColor "Reset" width:35 align:#right offset:[6,0]			
			checkbox chk_DepotShowCategories "Show Depot Categories" checked:DepotShowCategories
		)
		
		group "Nodes"
		(
			dropdownlist ddl_NodeWidth items:#("Node Width 80","Node Width 100","Node Width 120","Node Width 140 (default)","Node Width 160","Node Width 180","Node Width 200","Node Width 220","Node Width 240","Node Width 260","Node Width 280","Node Width 300") width:150 align:#center
			dropdownlist ddl_NodeXSpace items:#("Horiz.Spacing 0","Horiz.Spacing 10","Horiz.Spacing 20","Horiz.Spacing 30 (default)","Horiz.Spacing 40","Horiz.Spacing 50","Horiz.Spacing 60","Horiz.Spacing 70","Horiz.Spacing 80","Horiz.Spacing 90","Horiz.Spacing 100") width:150 align:#center
			dropdownlist ddl_NodeYSpace items:#("Vert.Spacing +0 (default)","Vert.Spacing +10","Vert.Spacing +20","Vert.Spacing +30","Vert.Spacing +40","Vert.Spacing +50","Vert.Spacing +60","Vert.Spacing +70","Vert.Spacing +80","Vert.Spacing +90","Vert.Spacing +100") width:150 align:#center
			
			colorpicker clr_InputColor "Input:" align:#right across:2 fieldwidth:40 align:#right offset:[38,0] modal:false
			button btn_resetInputColor "Reset" width:35 align:#right offset:[6,0]

			colorpicker clr_OperatorColor "Operator:" align:#right across:2 fieldwidth:40 align:#right offset:[38,0] modal:false
			button btn_resetOperatorColor "Reset" width:35 align:#right offset:[6,0]
			
			colorpicker clr_BoxColor "BlackOp:" align:#right across:2 fieldwidth:40 align:#right offset:[38,0] modal:false
			button btn_resetBoxColor "Reset" width:35 align:#right offset:[6,0]

			colorpicker clr_OutputColor "Output:" align:#right across:2 fieldwidth:40 align:#right offset:[38,0] modal:false
			button btn_resetOutputColor "Reset" width:35 align:#right offset:[6,0]


			colorpicker clr_NotesColor "Notes:" align:#right across:2 fieldwidth:40 align:#right offset:[38,0] modal:false
			button btn_resetNotesColor "Reset" width:35 align:#right offset:[6,0]
			
			


			checkbox chk_deselectNodesOnInputDrop "Deselect On Input Drop"
			checkbox chk_useMousePositionOnCreation "Shortcut To Mouse Pos."
			checkbox chk_operatorHeightConstant "Fixed Operator Height"
			checkbox chk_castShadows "Cast Shadows"
		)
		


		group "Sockets and Connections"
		(
			colorpicker clr_InputSocketColor "Free Input:" align:#right across:2 fieldwidth:40 align:#right offset:[38,0] modal:false
			button btn_resetInputSocketColor "Reset" width:35 align:#right offset:[6,0]
			
			colorpicker clr_ChannelSocketColor "Channel:" align:#right across:2 fieldwidth:40 align:#right offset:[38,0] modal:false
			button btn_resetChannelColor "Reset" width:35 align:#right offset:[6,0]

			colorpicker clr_IntegerSocketColor "Integer:" align:#right across:2 fieldwidth:40 align:#right offset:[38,0] modal:false
			button btn_resetIntegerColor "Reset" width:35 align:#right offset:[6,0]
			
			colorpicker clr_FloatSocketColor "Float:" align:#right across:2 fieldwidth:40 align:#right offset:[38,0] modal:false
			button btn_resetFloatColor "Reset" width:35 align:#right offset:[6,0]

			colorpicker clr_VectorSocketColor "Vector:" align:#right across:2 fieldwidth:40 align:#right offset:[38,0] modal:false
			button btn_resetVectorColor "Reset" width:35 align:#right offset:[6,0]

			colorpicker clr_TextureMapSocketColor "TextureMap:" align:#right across:2 fieldwidth:40 align:#right offset:[38,0] modal:false
			button btn_resetTextureMapColor "Reset" width:35 align:#right offset:[6,0]
			
			colorpicker clr_ObjectSocketColor "Object:" align:#right across:2 fieldwidth:40 align:#right offset:[38,0] modal:false
			button btn_resetObjectColor "Reset" width:35 align:#right offset:[6,0]
			
		)


		
		
		fn updateBackground fileName:"" =
		(
			if FileName == "" do FileName = getDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini"
			setIniSetting FileName "ParticleChannelEditor" "BackgroundColor"  (theBackgroundColor as string)
			setIniSetting FileName "ParticleChannelEditor" "GridColor"  (theGridColor as string)
			setIniSetting FileName "ParticleChannelEditor" "GridSizeX"  (GridSizeX as string)
			setIniSetting FileName "ParticleChannelEditor" "GridSizeX"  (GridSizeX as string)
			
			KrakatoaChannelNodeEditor_Rollout.showGrid SnapToGrid
			KrakatoaChannelNodeEditor_Rollout.hc.redrawView
		)
		
		fn updateNodeColors fileName:""=
		(
			if FileName == "" do FileName = getDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini"
			setIniSetting FileName "ParticleChannelEditor" "InputNodeColor"  (theInputNodeColor as string)
			setIniSetting FileName "ParticleChannelEditor" "NotesNodeColor"  (theNotesNodeColor as string)
			setIniSetting FileName "ParticleChannelEditor" "OutputNodeColor"  (theOutputNodeColor as string)
			setIniSetting FileName "ParticleChannelEditor" "OperatorNodeColor"  (theOperatorNodeColor as string)
			setIniSetting FileName "ParticleChannelEditor" "BoxNodeColor"  (theBoxNodeColor as string)
			setIniSetting FileName "ParticleChannelEditor" "NodesCastShadows" (theNodesCastShadows as string)
			setIniSetting FileName "ParticleChannelEditor" "NodeWidth" (NodeWidth as string)
			setIniSetting FileName "ParticleChannelEditor" "NodeXSpace" (NodeXSpace as string)
			setIniSetting FileName "ParticleChannelEditor" "NodeYSpace" (NodeYSpace as string)
			setIniSetting FileName "ParticleChannelEditor" "OperatorHeightConstant" (operatorHeightConstant as string)
			setIniSetting FileName "ParticleChannelEditor" "UseMousePositionOnCreation" (useMousePositionOnCreation as string)
			setIniSetting FileName "ParticleChannelEditor" "DepotHeaderColor" (theHeaderColor as string)
			setIniSetting FileName "ParticleChannelEditor" "DeselectNodesOnInputDrop" (DeselectNodesOnInputDrop as string)
			KrakatoaChannelNodeEditor_Rollout.createDepot()
			KrakatoaChannelNodeEditor_Rollout.updateDepotDefinition()
			KrakatoaChannelNodeEditor_Rollout.createNodeTree init:false
		)
		
		fn updateSocketColors filename:"" =
		(
			if FileName == "" do FileName = getDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini"
			setIniSetting FileName "ParticleChannelEditor" "InputSocketColor"  (theInputSocketColor as string)
			setIniSetting FileName "ParticleChannelEditor" "ChannelSocketColor"  (theChannelSocketColor as string)
			setIniSetting FileName "ParticleChannelEditor" "FloatSocketColor"  (theFloatSocketColor as string)				
			setIniSetting FileName "ParticleChannelEditor" "VectorSocketColor"  (theVectorSocketColor as string)				
			setIniSetting FileName "ParticleChannelEditor" "IntegerSocketColor"  (theIntegerSocketColor as string)				
			setIniSetting FileName "ParticleChannelEditor" "TextureMapSocketColor"  (theTextureMapSocketColor as string)				
			setIniSetting FileName "ParticleChannelEditor" "ObjectSocketColor"  (theObjectSocketColor as string)				
			
			KrakatoaChannelNodeEditor_Rollout.createNodeTree init:true	
		)
		

		
		fn updateGUI = 
		(
			clr_CategoryOnColor.color = theHeaderColor
			clr_GridColor.color = theGridColor
			clr_backgroundColor.color = theBackgroundColor
			spn_GridSizeX.value = gridSizeX 
			spn_GridSizeY.value = gridSizeY
			clr_InputColor.color = theInputNodeColor  
			clr_NotesColor.color = theNotesNodeColor
			clr_OutputColor.color = theOutputNodeColor 
			clr_OperatorColor.color = theOperatorNodeColor 		
			clr_BoxColor.color = theBoxNodeColor
			
			clr_InputSocketColor.color = theInputSocketColor
			clr_ChannelSocketColor.color = theChannelSocketColor
			clr_FloatSocketColor.color = theFloatSocketColor
			clr_VectorSocketColor.color = theVectorSocketColor
			clr_IntegerSocketColor.color = theIntegerSocketColor
			clr_TextureMapSocketColor.color = theTextureMapSocketColor
			clr_ObjectSocketColor.color = theObjectSocketColor
			
			chk_castShadows.state = theNodesCastShadows
			chk_useMousePositionOnCreation.state = useMousePositionOnCreation
			
			ddl_NodeWidth.selection = findItem #(80,100,120,140,160,180,200,220,240,260,280,300) NodeWidth
			ddl_NodeXSpace.selection = findItem #(0,10,20,30,40,50,60,70,80,90,100) NodeXSpace
			ddl_NodeYSpace.selection = NodeYSpace
			chk_operatorHeightConstant.state = OperatorHeightConstant
			chk_DeselectNodesOnInputDrop.state = DeselectNodesOnInputDrop
		)			
		
		on chk_DeselectNodesOnInputDrop changed state do
		(
			DeselectNodesOnInputDrop = state
			setIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "ParticleChannelEditor" "DeselectNodesOnInputDrop" (state as string)
		)
		
		on chk_DepotShowCategories changed state do
		(
			DepotShowCategories = state
			setIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "ParticleChannelEditor" "DepotShowCategories" (state as string)
			--KrakatoaChannelNodeEditor_Rollout.updateDepotDefinition()
			KrakatoaChannelsEditor_Functions.KrakatoaChannelEditor_UpdateDepot()
		)

		on ddl_NodeWidth selected itm do
		(
			NodeWidth = #(80,100,120,140,160,180,200,220,240,260,280,300)[itm]
			if AutoReorderToggle do KrakatoaChannelNodeEditor_Rollout.autoReorderFlow()
			updateNodeColors() 
			--KrakatoaChannelNodeEditor_Rollout.alignAllNodesToGrid()
		)
		
		on ddl_NodeXSpace selected itm do
		(
			NodeXSpace = #(0,10,20,30,40,50,60,70,80,90,100)[itm]
			if AutoReorderToggle do KrakatoaChannelNodeEditor_Rollout.autoReorderFlow()
			updateNodeColors()
		)
		
		on ddl_NodeYSpace selected itm do
		(
			NodeYSpace = itm
			if AutoReorderToggle do KrakatoaChannelNodeEditor_Rollout.autoReorderFlow()
			updateNodeColors()
		)
			
		
		
		on chk_useMousePositionOnCreation changed state do
		(
			useMousePositionOnCreation = state
			updateNodeColors()
		)		
		
		on chk_operatorHeightConstant changed state do 
		(
			operatorHeightConstant = state
			updateNodeColors()
			if AutoReorderToggle do KrakatoaChannelNodeEditor_Rollout.autoReorderFlow()
		)
		
		on btn_savePreset pressed do
		(
			KrakatoaChannelEditor_DisableDragAndDrop = false
			makeDir (Krakatoa_PresetsDirectory+ "\\MagmaFlowSettings\\") all:true
			local theFileName = getSaveFileName caption:"Save Krakatoa MagmaFlow Editor Display Settings To..." filename:(Krakatoa_PresetsDirectory+ "\\MagmaFlowSettings\\Settings.kms") types:"Krakatoa MagmaFlow Editor Settings (*.kms)|*.kms"
			if theFileName != undefined do
			(
				updateBackground fileName:theFileName
				updateNodeColors fileName:theFileName
				updateSocketColors fileName:theFileName
			)
		)
		on btn_loadPreset pressed do
		(
			KrakatoaChannelEditor_DisableDragAndDrop = false
			makeDir (Krakatoa_PresetsDirectory+ "\\MagmaFlowSettings\\") all:true
			local theFileName = getOpenFileName caption:"Load Krakatoa MagmaFlow Editor Display Settings From..." filename:(Krakatoa_PresetsDirectory+ "\\MagmaFlowSettings\\Settings.kms") types:"Krakatoa MagmaFlow Editor Settings (*.kms)|*.kms"
			if theFileName != undefined do
			(
				loadDisplaySettings fileName:theFileName
				KrakatoaChannelNodeEditor_Rollout.createNodeTree init:false
				KrakatoaChannelNodeEditor_Rollout.showGrid SnapToGrid
				updateGUI()
				updateBackground()
				updateNodeColors()
				updateSocketColors()
			)
		)
		


		on btn_resetInputSocketColor pressed do 
		(
			theInputSocketColor = clr_InputSocketColor.color = color 255 0 0
			updateSocketColors()		
		)
		
		on btn_resetChannelColor pressed do 
		(
			theChannelSocketColor = clr_ChannelSocketColor.color = color 0 0 200
			updateSocketColors()	
		)
		on btn_resetFloatColor pressed do 
		(
			theFloatSocketColor = clr_FloatSocketColor.color = color 0 128 0
			updateSocketColors()	
		)
		on btn_resetVectorColor pressed do 
		(
			theVectorSocketColor = clr_VectorSocketColor.color = color 0 255 200
			updateSocketColors()	
		)
		on btn_resetIntegerColor pressed do 
		(
			theIntegerSocketColor = clr_IntegerSocketColor.color = color 128 0 255
			updateSocketColors()	
		)
		on btn_resetTextureMapColor pressed do
		(
			clr_TextureMapSocketColor.color = theTextureMapSocketColor = color 255 128 128
			updateNodeColors()			
		)			
		on btn_resetObjectColor pressed do
		(
			theObjectSocketColor = clr_ObjectSocketColor.color = color 128 0 0
			updateSocketColors()	
		)
		
		on clr_InputSocketColor changed val do 
		(
			theInputSocketColor = val 
			updateSocketColors()
		)	
		on clr_ChannelSocketColor changed val do 
		(
			theChannelSocketColor = val
			updateSocketColors()
		)	
		on clr_FloatSocketColor changed val do 
		(
			theFloatSocketColor = val
			updateSocketColors()
		)
		on clr_VectorSocketColor changed val do 
		(
			theVectorSocketColor = val
			updateSocketColors()
		)
		on clr_IntegerSocketColor changed val do 
		(
			theIntegerSocketColor = val
			updateSocketColors()
		)
		on clr_TextureMapSocketColor changed val do 
		(
			theTextureMapSocketColor = val
			updateSocketColors()
		)
		on clr_ObjectSocketColor changed val do 
		(
			theObjectSocketColor = val
			updateSocketColors()
		)
		
		
		
		on clr_InputColor changed val do
		(
			theInputNodeColor = val
			updateNodeColors()
		)
		
		on clr_NotesColor changed val do
		(
			theNotesNodeColor = val
			updateNodeColors()
		)
		
		on btn_resetInputColor pressed do
		(
			clr_InputColor.color = theInputNodeColor = color 220 220 255
			updateNodeColors()			
		)
		

		
		on clr_OutputColor changed val do
		(
			theOutputNodeColor = val
			updateNodeColors()
		)
		
		on btn_resetOutputColor pressed do
		(
			clr_OutputColor.color = theOutputNodeColor = color 200 255 200
			updateNodeColors()			
		)		
		
		on btn_resetNotesColor pressed do
		(
			clr_NotesColor.color = theNotesNodeColor = color 240 250 255
			updateNodeColors()				
		)
		
		on clr_OperatorColor changed val do
		(
			theOperatorNodeColor = val
			updateNodeColors()
		)
		
		on btn_resetOperatorColor pressed do
		(
			clr_OperatorColor.color = theOperatorNodeColor = color 255 235 200
			updateNodeColors()			
		)				
		
		on clr_BoxColor changed val do
		(
			theBoxNodeColor = val
			updateNodeColors()
		)
		on btn_resetBoxColor pressed do
		(
			clr_BoxColor.color = theBoxNodeColor = color 255 200 180
			updateNodeColors()			
		)			
		
		on clr_backgroundColor changed val do
		(
			theBackgroundColor = val
			updateBackground()
		)
		
		on btn_resetBackgroundColor pressed do
		(
			clr_backgroundColor.color = theBackgroundColor = color 192 192 198
			updateBackground()
			updateBackgroundColor 
		)
		
		on clr_GridColor changed val do
		(
			theGridColor = val
			updateBackground()
		)
		
		on btn_resetGridColor pressed do
		(
			clr_GridColor.color = theGridColor = color 200 200 210
			updateBackground()
			updateBackgroundColor 
		)		
		
		on spn_gridSizeX changed val do
		(
			gridSizeX = val
			updateBackground()			
		)
		on spn_gridSizeY changed val do
		(
			gridSizeY = val
			updateBackground()			
		)	

		on btn_resetgridSizeX pressed do
		(
			spn_gridSizeX.value = gridSizeX = 10
			updateBackground()					
		)
		on btn_resetgridSizeY pressed do
		(
			spn_gridSizeY.value = gridSizeY = 10
			updateBackground()					
		)		
		
		on chk_castShadows changed val do 
		(
			KrakatoaChannelNodeEditor_Rollout.hc.drawShadows = theNodesCastShadows = val
			updateNodeColors()
		)		
		
		on clr_CategoryOnColor changed val do
		(
			theHeaderColor  = val
			updateNodeColors()
			KrakatoaChannelNodeEditor_Rollout.drawDepot init:false	
		)			
		
		on btn_resetCategoryOnColor pressed do
		(
			clr_CategoryOnColor.color = theHeaderColor = color 80 80 120
			updateNodeColors()		
			KrakatoaChannelNodeEditor_Rollout.drawDepot init:false	
		)		
		
		on btn_resetDepotNodeWidth pressed do
		(
			local FileName = (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini")
			spn_DepotNodeWidth.value = DepotNodeWidth = 70
			KrakatoaChannelNodeEditor_Rollout.drawDepot init:false			
			setIniSetting FileName "ParticleChannelEditor" "DepotNodeWidth"  (DepotNodeWidth as string)	
		)
		
		on spn_DepotNodeWidth changed val do
		(
			local FileName = (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini")
			DepotNodeWidth = val
			KrakatoaChannelNodeEditor_Rollout.drawDepot init:false			
			setIniSetting FileName "ParticleChannelEditor" "DepotNodeWidth"  (DepotNodeWidth as string)	
		)		
		
		on ddl_depotPlacement selected itm do
		(
			DepotPlacement = case itm of
			(
				default: #off
				2: #left
				3: #bottom
				4: #bottomrollup
				5: #bottomrollupreverse
			)
			setIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "ParticleChannelEditor" "DepotPlacement"  (DepotPlacement as string)	
			KrakatoaChannelNodeEditor_Rollout.CreateDepot()
			KrakatoaChannelsEditor_Functions.KrakatoaChannelEditor_UpdateDepot()
		)		
		

		on KrakatoaChannelNodeEditor_OptionsRollout open do
		(
			loadDisplaySettings()
			updateGUI()
		)
	)
	
	rollout KrakatoaChannelNodeEditor_OperatorDescriptionRollout "Operator Description" category:200
	(
		
		--group "Operator Description:" --(
			label lbl_description01 "" align:#left offset:[-10,0]
			label lbl_description02 "" align:#left offset:[-10,-3]
			label lbl_description03 "" align:#left offset:[-10,-3]
			label lbl_description04 "" align:#left offset:[-10,-3]
			label lbl_description05 "" align:#left offset:[-10,-3]
			label lbl_description06 "" align:#left offset:[-10,-3]
			label lbl_description07 "" align:#left offset:[-10,-3]
			label lbl_description08 "" align:#left offset:[-10,-3]
			label lbl_description09 "" align:#left offset:[-10,-3]
			label lbl_description10 "" align:#left offset:[-10,-3]
			label lbl_description11 "" align:#left offset:[-10,-3]
			label lbl_description12 "" align:#left offset:[-10,-3]
		--)
		
		fn updateDescription =
		(
			local theLabels = #(lbl_description01,lbl_description02,lbl_description03,lbl_description04,lbl_description05,lbl_description06,lbl_description07,lbl_description08,lbl_description09,lbl_description10,lbl_description11,lbl_description12)
			local theText = case KrakatoaChannelNodeEditor_OperatorRollout.ddl_type.selected of
			(
				--Arithmetics
				"Add": "Adds componentwise the #two Inputs together.#Both Inputs must have#matching Arity.# #1+2=3#[1,2,3]+[4,5,6]=[5,7,9]#[1,2,3]+4->Not Supported"
				"Subtract": "Subtracts componentwise#the second Input from the first.#Both Inputs must have#matching Arity.# #3--2=1#[6,5,4]--[1,2,3]=[5,3,1]#[6,5,4]--3=Not Supported#8-[1,2,3]=Not Supported"
				"Multiply": "Multiplies componentwise#the two Inputs:# #2*3=6#[1,2,3]*[4,5,6]=[4,10,18]#[1,2,3]*4=[1,2,3]*[4,4,4]=#=[4,8,12]"
				"Divide": "Divides the first Input#by the second Float Input:# #6*3=2#[4,8,12]/4=[1,2,3]#8/[8,4,2]->Not Supported#[4,10,18]/[4,5,6]->Not Supported"
				"Power": "Returns the first Input#to the Power of the second#Float Input:# #2^3=8#[2,3,4]^2=[4,9,16]#2^[1,2,3]->Not Supported#[2,3,4]^[1,2,3]->Not Supported"
				"SquareRoot": "Outputs the Principle Square Root#of the (absolute value of the) input# #25.0->5.0#2.5->0.5811388#[1.0,4.0,9.0]->[1.0,2.0,3.0]"
				"Modulo": "Calculates the remainder of#the division of Input1 by Input2.#Both Inputs must be Floats."
				"Floor": "Returns the rounded down#value of Input 1.# #2.31 --> 2.0#51.99 --> 51.0"
				"Ceil": "Returns the rounded up#value of Input 1.# #2.31 --> 3.0#51.99 --> 52.0"
				
				"Logarithm": "Calculates the natural logarithm#of Input 1# #To calculate logarithm of X#with Base B, use log(X)/log(B)"
				
				"Blend": "Blends I1 and I2 which can be#scalar or vector using#float I3 as the Blend Amount#in the range from 0.0 to 1.0:# #I1=2; I2=3; I3=0.4#->I3*2+(1.0-I3)*3=2.6#I1=[1,2,3];I2=[4,5,6];I3=0.4#->[2.8,3.8,4.8]#I1=[1,2,3];I2=4;I3=0.4#->Not Supported"
				"Clamp": "Clamps a vector or scalar I1 #between the scalar I2 and I3.#Output is same type as I1.# #I2=2; I3=6:#I1=1->2; I1=5->5; I1=9->6#I1=[1,5,9]->[2,5,6]"
				"Curve": "The Float Input in the range from#0.0 to 1.0 produces Float Output#mapped by the Curve Control."
				
				"Negate": "Changes the Sign of the Input:# #1 --> -1#[1,2,-3] --> [-1,-2,3]"
				"AbsoluteValue": "Outputs the Absolute Value of#Input 1# #-12.3->12.3#[-1,2,-3]->[1,2,3]"
				"Noise": "Outputs a Float Noise value #Input 1=Float or Vector Input.#Input 2=Octaves Integer value.#Input 3=Persistence Float value."
                "DNoise": "Outputs the partial derivative#Vector of each input#into a noise function.#Input 1=Float or Vector Input.#Input 2=Octaves Integer value.#Input 3=Persistance Float Value."
				
				
				--Vectors
				"Magnitude": "Calculates the Length of Input 1.#If a Scalar, outputs the Scalar.# #[0,0,1]->1#10.1->10.1"
				"Normalize": "Returns the Unit Vector with#the same direction as Input1#but length of 1.0# #[0,10,0]->[0,1,0]"
				"ComponentSum": "Adds the 3 Components of#the Input1 Vector together and#outputs them as a Float.# #[10.1,21.5,32.8]->64.4"
				"DotProduct": "Calculates the Dot Product of.#two Vector Inputs.#Equivalent to the projection of#the one vector onto the other#or the Cosine of their angle"
				"CrossProduct": "Calculates the Cross Product of#two Vector Inputs.#Result is a new vector#perpendicular to the two#with length equal to#the area of the parallelogram#defined by the two vectors."
				
				--Trigonometry
				"Sin": "Calculates the Sine of#the Angle provided by#the Input 1 Scalar# #Sin(0.0)->0.0#Sin(Pi/2)->1.0#Sin(Pi)->0.0#Sin(Pi*3/2)->-1.0"
				"Cos": "Calculates the Cosine of#the Angle provided by#the Input 1 Scalar# #Cos(0.0)->1.0#Cos(Pi/2)->0.0#Cos(Pi)->-1.0#Cos(Pi*3/2)->0.0"
				"Tan": "Calculates the Tangent of the#Angle provided by#the Input 1 Scalar# #Tan(0.0)->0.0#Tan(Pi/4)->1.0#Tan(Pi/3)->1.73205#Tan(Pi*2/3)->-1.73205"
				"ASin": "Calculates the Inverse of the#Sine provided by#the Input 1 Scalar#and returns the Angle as Float# #ASin(0.0)->0.0#ASin(0.5)->Pi/6#ASin(0.707107)->Pi/4#ASin(1.0)->Pi/2"
				"ACos": "Calculates the Inverse of the#Cosine provided by#the Input 1 Scalar#and returns the Angle as Float# #ACos(0.0)->Pi/2#ACos(0.5)->Pi/3#ACos(0.707107)->45.0#ACos(1.0)->0.0"
				"ATan": "Calculates the Inverse of the#Tangent provided by#the Input 1 Scalar#and returns the Angle as Float# #ATan(0.0)->0.0#ATan(1.0)->Pi/4#ATan(1.73205)->Pi/3"
				"ATan2": "Calculate the arctangent of#y/x in the range �pi to pi radians.#If x is 0, atan returns 0.#If both Inputs are 0, returns 0# #Uses the signs of both inputs#to determine the quadrant of#the return value. "
				
				--Conversion
				"FromQuat": "Takes a Quaternion Input 1#and an Integer Input 2#between 1 and 3, and#outputs to a Vector.# #NOTE: conversion from a#quaternion to vectors and back#may not produce a quaternion#that is identical to the originial."
				"ToQuat": "Takes 3 Vector Inputs and#combines them to a Quaternion:# #NOTE: conversion from vectors to#a quaternion and back#may not produce vectors#that are identical to the originials."
                "ToVector": "Takes 3 Scalar Inputs and#combines them to a Vector.# #I1=1; I2=3; I3=8->[1,3,8]"
				"ToScalar": "Takes Vector Input 1 and#outputs component specified#by Scalar Input 2 where#1=X, 2=Y, 3=Z#If I2>Arity returns 0# #I1=[10,20,30]; I2=3->30"
				"ToFloat": "Takes Integer Input 1 and#outputs a Float# #10->10.0"
				"ToInteger": "Takes Float Input 1 and#outputs an Integer by cropping#the decimal porition.# #1.234->1"
				
				--Transformation
				"ToWorld": "Transforms a Point, Vector#or Normal out of Local Space#into World Space by multiplying#with the Transformation Matrix#of the Host Object"
				"FromWorld": "Transforms a Point, Vector#or Normal out of World Space#into Local Space by multiplying#with the Inverse Transformation#Matrix of the Host Object"
				"ToSpace": "Transforms a Point, Vector#or Normal into the Space#of a selected Scene Object."
				"FromSpace": "Transforms a Point, Vector#or Normal out of the Space#of a selected Scene Object."
				"ToView": "Transforms a Point, Vector#or Normal into the#Current View space."
				"FromView": "Transforms a Point, Vector#or Normal out of the#Current View space."
				"TransformByQuat":  "Transforms a Vector or Quaternion#Input by a Quaternion Input,#producing the transformed Vector#or Quaternion"
				
				--Geometry
				"NearestPoint": "Performs a search for the#Closest Point On Surface#and produces a data set incl.#Position, Normal, Bary.Coords,#Signed Distance, Mesh Index,#Face Index and TextureCoords"
				"RayIntersect": "Performs a ray intersection#with one or more Surfaces#and produces a data set incl.#Position, Normal, Bary.Coords,#Signed Distance, Mesh Index,#Face Index and TextureCoords#at the intersection point."
				
				"SurfDataValue": "Extracts a single value#from a Surface Data Set#to be used in  the flow."
				--"ValidSurfData": "Input is Surface Data Set#Output is 1 (TRUE) if Data is valid,#or 0 (FALSE) if invalid."

				--Logic and Comparison
				"LogicalAnd": "Returns 1 (TRUE) if both#Float Inputs are non-zero (TRUE)#or 0 (FALSE) if either#Input is equal to 0 (FALSE)"
				"LogicalOr": "Returns 1 (TRUE) if at least#one of the two Float Inputs#is non-zero(TRUE)#or 0 (FALSE) if both#Inputs are equal to 0 (FALSE)"
				"LogicalNot": "Returns 1 (TRUE) if the#Float Input is 0 (FALSE)#and 0 (FALSE) if the#Float Input is a non-zero value"
				"Less": "Returns 1 (TRUE) if the#Float Input1 is less than#the Float Input2, 0 (FALSE)#otherwise."
				"LessOrEqual": "Returns 1 (TRUE) if the#Float Input1 is less or equal#to the Float Input2, 0 (FALSE)#otherwise."
				"Greater": "Returns 1 (TRUE) if the#Float Input1 is greater than#the Float Input2, 0 (FALSE)#otherwise."
				"GreaterOrEqual": "Returns 1 (TRUE) if the#Float Input1 is greater or equal#to the Float Input2, 0 (FALSE)#otherwise."
				"Equal": "Returns 1 (TRUE) if the#Float Input1 is equal to#the Float Input2, 0 (FALSE)#otherwise."
				"Switch": "Outputs Input1 if the Input3#control value is non-zero(TRUE).#Outputs Input2 if Input3 is#equal to 0 (FALSE)."
				default: "Info Not Available"
			)
			theFS = filterString theText "#"
			for i in theLabels do i.text = ""
			for i = 1 to theFS.count do
			(
				theLabels[i].text = theFS[i]
			)
		)		
		
		on KrakatoaChannelNodeEditor_OperatorDescriptionRollout open do
		(
			updateDescription()
		)		
		
		on KrakatoaChannelNodeEditor_OperatorDescriptionRollout rolledup state do
		(
			if not KrakatoaChannelsEditor_isInitializing do
			(
				setIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "ParticleChannelEditor" "OperatorDescriptionRolloutRolledup" (state as string)
			)
		)			
	)
	
	rollout KrakatoaChannelNodeEditor_CurveControl "Curve Operator" category:105
	(
		local canSave = false
		local lastPoint = 0
		
		edittext edt_presetName "" text:"Preset1" across:2 align:#left fieldwidth:140 offset:[-15,-3]
		button btn_curvePresets ">>" width:25 height:18 align:#right offset:[12,-3]
	
		CurveControl crv_CurveControl  width:169 height:228 align:#center offset:[0,-2] numCurves:1 visible:true x_range:[0,1] y_range:[-1,1] \
		uiFlags:#(#drawBG,#drawgrid,#upperToolbar,#showReset,#lowerToolbar,#ruler)  --,#scrollBars --, --#autoScroll --#constrainY
		
		spinner spn_inTangentX "In X:" type:#float range:[-1,1,0] fieldwidth:40 across:2 offset:[-2,-2] scale:0.01 enabled:false
		spinner spn_outTangentX "Out X:" type:#float range:[-1,1,0] fieldwidth:40 align:#right offset:[12,-2] scale:0.01 enabled:false
		spinner spn_inTangentY "In Y:" type:#float range:[-1,1,0] fieldwidth:40 across:2 offset:[-2,-3] scale:0.01 enabled:false
		spinner spn_outTangentY "Out Y:" type:#float range:[-1,1,0] fieldwidth:40 align:#right offset:[12,-3] scale:0.01 enabled:false
		
		button btn_flipHorizontal "Horizontal Flip" across:2 width:80 offset:[-10,-3] align:#left tooltip:""
		button btn_flipVertical "Vertical Flip" width:80 offset:[10,-3] align:#right
		button btn_mirrorVertical "Mirror Vertically About X Axis" width:160 offset:[0,-5] align:#center

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

		fn updatePresetName =
		(
			local theKeys = getIniSetting (Krakatoa_PresetsDirectory + "/MagmaFlowSettings/CurveControlPresets.ini") "Curves"
			sort theKeys
			local presetsList = for i in theKeys collect getIniSetting (Krakatoa_PresetsDirectory + "/MagmaFlowSettings/CurveControlPresets.ini") "Curves" i
			local theValue = with printAllElements true (KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][3][2] as string)
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
			if KrakatoaChannelNodeEditor_Rollout.chk_autoUpdateModifier.checked do KrakatoaChannelsEditor_Functions.updateParentModifier()
		)		
		
		fn createPresetsRCMenu =
		(
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
			
			
			local theValue = with printAllElements true (KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][3][2] as string)
			
			local txt = "rcmenu Presets_RCMenu\n(\n"
			local theIndex = findItem presetsList theValue
			if theIndex == 0 do 
			(
				txt += "menuItem mnu_AddPreset \"Add ["+ edt_presetName.text +"]\"\n" 
				txt += "on mnu_AddPreset picked do (\n"
				txt += "setIniSetting (Krakatoa_PresetsDirectory + \"/MagmaFlowSettings/CurveControlPresets.ini\") \"Curves\" \""+ edt_presetName.text + "\" \""+ theValue +"\" \n"
				txt += "KrakatoaChannelNodeEditor_CurveControl.updatePresetName()\n"
				txt += ")\n"
				txt += "separator spr_01\n" 
			)
			
			for i = 1 to theKeys.count do
			(
				txt += "menuItem mnu_preset"+ i as string +" \"" + theKeys[i] + "\" \n" 
				txt += "on mnu_preset" + i as string + " picked do (\n"
				txt += "KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][3][2] = "+ presetsList[i] +"\n"
				txt += "KrakatoaChannelNodeEditor_CurveControl.loadControlCurves()\n"
				txt += "KrakatoaChannelNodeEditor_CurveControl.updatePresetName()\n"
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
					txt += "KrakatoaChannelNodeEditor_CurveControl.updatePresetName()\n"
					txt += ")\n"
				)
				else
				(
					txt += "menuItem mnu_RemovePreset \"Remove ["+ theKeys[theIndex] +"]\"\n" 
					txt += "on mnu_RemovePreset picked do (\n"
					txt += "delIniSetting (Krakatoa_PresetsDirectory + \"/MagmaFlowSettings/CurveControlPresets.ini\") \"Curves\" \""+ theKeys[theIndex] +"\" \n"
					--txt += "print \""+ theKeys[theIndex] +"\"\n"
					txt += "KrakatoaChannelNodeEditor_CurveControl.updatePresetName()\n"
					txt += ")\n"
				)
			)	
			
			txt += ")\n"
			execute txt
		)	
		
		on btn_curvePresets pressed do
		(
			global Presets_RCMenu = createPresetsRCMenu()
			popupMenu Presets_RCMenu pos:mouse.screenpos
		)
		
		
		fn loadControlCurves =
		(
			canSave  = false
			if KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][3][2] == undefined do
			(
				KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][3][2] = #(#([0.0,0.0],[0.0,0.0],[0.0,0.0],false,true),#([1.0,1.0],[0.0,0.0],[0.0,0.0],false,true)) 
			)
			local theCount = KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][3][2].count
			crv_CurveControl.curves[1].numPoints = theCount
			crv_CurveControl.curves[1].animatable  = false
			crv_CurveControl.curves[1].color = blue
			crv_CurveControl.curves[1].width = 2
			for i = theCount to 1 by -1 do
			(
				local theVal = KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][3][2][i]
				local cp = crv_CurveControl.curves[1].points[i]
				cp.value = theVal[1]
				cp.inTangent = theVal[2]
				cp.outTangent = theVal[3]
				cp.bezier = theVal[4]
				cp.corner = theVal[5]
				cp.selected = lastPoint == i
				crv_CurveControl.curves[1].points[i] = cp
			)
			canSave = true		
			zoom crv_CurveControl #all			
		)

		fn SaveControlCurves =
		(
			if canSave do
			(
				try
				(
					local crv = crv_CurveControl.curves[1]
					local tempArray = #()
					
					for i = 1 to crv.numPoints  do
						append tempArray #(crv.points[i].value, crv.points[i].inTangent, crv.points[i].outTangent, crv.points[i].bezier, crv.points[i].corner)
					KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][3][2]	= tempArray
					updatePresetName()
				)catch()
				--if KrakatoaChannelNodeEditor_Rollout.chk_autoUpdateModifier.checked do KrakatoaChannelsEditor_Functions.updateParentModifier()
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
		

		
		on btn_flipHorizontal pressed do
		(
			SaveControlCurves()
			local tempArray = deepCopy KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][3][2]	
			for i = 1 to tempArray.count do
			(
				tempArray[i][1].x = 1.0 - tempArray[i][1].x
				temp = tempArray[i][2]
				temp.x = -temp.x
				tempArray[i][2] = [-tempArray[i][3].x, tempArray[i][3].y]
				tempArray[i][3] = temp
			)
			tempArray = for i = tempArray.count to 1 by -1 collect tempArray[i]
			KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][3][2]	= tempArray
			lastPoint = 0
			loadControlCurves()
			updatePresetName()
		)
		on btn_flipVertical pressed do
		(
			SaveControlCurves()
			local tempArray = deepCopy KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][3][2]	
			local theArray = for i = 1 to tempArray.count collect tempArray[i][1].y
			local averageY = (amax theArray - amin theArray)/2
			for i = 1 to tempArray.count do
			(
				tempArray[i][1].y = averageY*2-(tempArray[i][1].y) 
				tempArray[i][2].y = -tempArray[i][2].y
				tempArray[i][3].y = -tempArray[i][3].y
			)
			KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][3][2]	= tempArray
			lastPoint = 0
			loadControlCurves()
			updatePresetName()
		)
		
		on btn_mirrorVertical pressed do
		(
			SaveControlCurves()
			local tempArray = deepCopy KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][3][2]	
			for i = 1 to tempArray.count do
			(
				tempArray[i][1].y = -tempArray[i][1].y
				tempArray[i][2].y = -tempArray[i][2].y
				tempArray[i][3].y = -tempArray[i][3].y
			)
			KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][3][2]	= tempArray
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
		
		on spn_inTangentX changed val do setTangents #in
		on spn_inTangentY changed val do setTangents #in
		on spn_outTangentX changed val do setTangents #out
		on spn_outTangentY changed val do setTangents #out		

		
		on KrakatoaChannelNodeEditor_CurveControl open do
		(
			makeDir (Krakatoa_PresetsDirectory + "/MagmaFlowSettings") all:true
			loadControlCurves()
			updatePresetName()
			gc light:true
		)
		
		on KrakatoaChannelNodeEditor_CurveControl close do 
		(
			SaveControlCurves()
			gc light:true
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

	)
	
	rollout KrakatoaChannelNodeEditor_NodeNameRollout "Node Name and User Notes" category:50
	(
		label lbl_nodeName "Node Name:" align:#left offset:[-10,0]
		edittext edt_nodeName width:162 offset:[-4,0] align:#center
		label lbl_userNotes "User Notes:" align:#left offset:[-10,0]
		edittext edt_userNotes width:162 height:80 offset:[-4,0] align:#center
		
		on edt_nodeName entered txt do 
		(
			txt = KrakatoaChannelsEditor_Functions.purifyText txt
			KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][4][8] = txt
			if KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][4][12] == true do
			(
				KrakatoaChannelsEditor_Functions.exposeControlsToModifier KrakatoaChannelNodeEditor_CurrentModifier	
			)
			KrakatoaChannelNodeEditor_Rollout.createNodeTree init:false
			edt_nodeName.text = txt
			KrakatoaChannelNodeEditor_Rollout.createUndoRecord ("Change Node Name To [" +txt +"]")
			if KrakatoaChannelNodeEditor_Rollout.chk_autoUpdateModifier.checked do KrakatoaChannelsEditor_Functions.updateParentModifier()
		)		

		on edt_userNotes entered txt do 
		(
			txt = KrakatoaChannelsEditor_Functions.purifyText txt
			KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][4][16] = txt
			KrakatoaChannelNodeEditor_Rollout.createUndoRecord ("Edited User Notes.")
			KrakatoaChannelNodeEditor_Rollout.createNodeTree init:true
			if KrakatoaChannelNodeEditor_Rollout.chk_autoUpdateModifier.checked do KrakatoaChannelsEditor_Functions.updateParentModifier()			
		)		
		
		on KrakatoaChannelNodeEditor_NodeNameRollout open do
		(
			try(edt_nodeName.text = KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][4][8])catch()
			local theUserNotes = ""
			if KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][4][16] != undefined do 
				theUserNotes = KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][4][16]
			edt_userNotes.text = theUserNotes
		)		
		
		on KrakatoaChannelNodeEditor_NodeNameRollout rolledup state do
		(
			if not KrakatoaChannelsEditor_isInitializing do
			(
				setIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "ParticleChannelEditor" "NodeNameRolloutRolledup" (state as string)
			)
		)
	)		
	
	rollout KrakatoaChannelNodeEditor_GraphOutputRollout "Graph Output Value"  category:1
	(
		dropdownlist ddl_quality items:#("High Quality (Slow)","Medium Quality","Low Quality","Draft (Fast)","Off (Disable Graph)") width:165 align:#center offset:[0,-3]
		bitmap bmp_graphValue width:165 height:165 offset:[-2,-4]
		spinner spn_minY "Min.Y" range:[-10000,10000,-0.1] fieldwidth:35 across:2 offset:[-5,-5]
		spinner spn_maxY "Max.Y" range:[-10000,10000,3] fieldwidth:35 align:#right offset:[7,-5]
		
		fn updateOutputRange =
		(
			KrakatoaChannelNodeEditor_OutputGraphRange = #(-0.01,1.0,spn_minY.value,spn_maxY.value, ddl_quality.selection)
			KrakatoaChannelNodeEditor_Rollout.debugFlow()
		)
		
		on spn_minY changed val do updateOutputRange()
		on spn_maxY changed val do updateOutputRange()
		on ddl_quality selected val do updateOutputRange()
		
		on KrakatoaChannelNodeEditor_GraphOutputRollout open do
		(
			spn_minY.value = KrakatoaChannelNodeEditor_OutputGraphRange[3]
			spn_maxY.value = KrakatoaChannelNodeEditor_OutputGraphRange[4]
			ddl_quality.selection = KrakatoaChannelNodeEditor_OutputGraphRange[5]
		)
		
	)
	
	rollout KrakatoaChannelNodeEditor_ChannelDebugRollout "Debug Mode Values" category:90
	(
		group "Float Channel Components"
		(
			spinner spn_component1 "Component 1:" fieldwidth:60 range:[-1000000,1000000,1]
			spinner spn_component2 "Component 2:" fieldwidth:60 range:[-1000000,1000000,1]
			spinner spn_component3 "Component 3:" fieldwidth:60 range:[-1000000,1000000,1]
			spinner spn_component4 "Component 4:" fieldwidth:60 range:[-1000000,1000000,1]
		)
		group "Int. Channel"
		(
			spinner spn_Integer "Int. Channel:" fieldwidth:60 range:[-1000000,1000000,1] type:#integer
		)	
		
		checkbox chk_GraphOutput "Use To Graph Output Value" align:#left offset:[-5,0]
		group "Graph Output Min.Values"
		(
			spinner spn_mincomponent1 "Component 1:" fieldwidth:60 range:[-1000000,1000000,1]
			spinner spn_mincomponent2 "Component 2:" fieldwidth:60 range:[-1000000,1000000,1]
			spinner spn_mincomponent3 "Component 3:" fieldwidth:60 range:[-1000000,1000000,1]
			spinner spn_mincomponent4 "Component 4:" fieldwidth:60 range:[-1000000,1000000,1]
		)
		group "Graph Output Max.Values"
		(
			spinner spn_maxcomponent1 "Component 1:" fieldwidth:60 range:[-1000000,1000000,1]
			spinner spn_maxcomponent2 "Component 2:" fieldwidth:60 range:[-1000000,1000000,1]
			spinner spn_maxcomponent3 "Component 3:" fieldwidth:60 range:[-1000000,1000000,1]
			spinner spn_maxcomponent4 "Component 4:" fieldwidth:60 range:[-1000000,1000000,1]
		)
		
		fn updateControls =
		(
			if KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][4][15] == undefined do 
				KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][4][15] = #(1.0,1.0,1.0,1.0,1,0.0,0.0,0.0,0.0,1.0,1.0,1.0,1.0,false)			
			if KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][4][15][6] == undefined do KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][4][15][6] = 0.0
			if KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][4][15][7] == undefined do KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][4][15][7] = 0.0
			if KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][4][15][8] == undefined do KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][4][15][8] = 0.0
			if KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][4][15][9] == undefined do KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][4][15][9] = 0.0

			if KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][4][15][10] == undefined do KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][4][15][10] = 1.0
			if KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][4][15][11] == undefined do KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][4][15][11] = 1.0
			if KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][4][15][12] == undefined do KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][4][15][12] = 1.0
			if KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][4][15][13] == undefined do KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][4][15][13] = 1.0

			if KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][4][15][14] == undefined do KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][4][15][14] = false
			
			spn_component1.value = KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][4][15][1]
			spn_component2.value = KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][4][15][2]
			spn_component3.value = KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][4][15][3]
			spn_component4.value = KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][4][15][4]
			spn_Integer.value = KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][4][15][5]
			
			spn_mincomponent1.value = KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][4][15][6]
			spn_mincomponent2.value = KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][4][15][7]
			spn_mincomponent3.value = KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][4][15][8]
			spn_mincomponent4.value = KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][4][15][9]

			spn_maxcomponent1.value = KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][4][15][10]
			spn_maxcomponent2.value = KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][4][15][11]
			spn_maxcomponent3.value = KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][4][15][12]
			spn_maxcomponent4.value = KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][4][15][13]

			chk_GraphOutput.state = KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][4][15][14]
		)
		

		
		on spn_mincomponent1 changed val do
		(
			KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][4][15][6]  = val
			if chk_GraphOutput.state do KrakatoaChannelNodeEditor_Rollout.debugFlow()
		)
		on spn_mincomponent2 changed val do
		(
			KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][4][15][7]  = val
			if chk_GraphOutput.state do KrakatoaChannelNodeEditor_Rollout.debugFlow()
		)
		on spn_mincomponent3 changed val do
		(
			KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][4][15][8]  = val
			if chk_GraphOutput.state do KrakatoaChannelNodeEditor_Rollout.debugFlow()
		)
		on spn_mincomponent4 changed val do
		(
			KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][4][15][9]  = val
			if chk_GraphOutput.state do KrakatoaChannelNodeEditor_Rollout.debugFlow()
		)	
		on spn_maxcomponent1 changed val do
		(
			KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][4][15][10]  = val
			if chk_GraphOutput.state do KrakatoaChannelNodeEditor_Rollout.debugFlow()
		)
		on spn_maxcomponent2 changed val do
		(
			KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][4][15][11]  = val
			if chk_GraphOutput.state do KrakatoaChannelNodeEditor_Rollout.debugFlow()
		)
		on spn_maxcomponent3 changed val do
		(
			KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][4][15][12]  = val
			if chk_GraphOutput.state do KrakatoaChannelNodeEditor_Rollout.debugFlow()
		)
		on spn_maxcomponent4 changed val do
		(
			KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][4][15][13]  = val
			if chk_GraphOutput.state do KrakatoaChannelNodeEditor_Rollout.debugFlow()
		)			
		
		on chk_GraphOutput changed state do
		(
			KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][4][15][14] = state
			KrakatoaChannelNodeEditor_Rollout.debugFlow()
		)		
		
		on spn_component1 changed val do
		(
			KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][4][15][1]  = val
			if DebugModeOn do KrakatoaChannelNodeEditor_Rollout.debugFlow()
		)
		on spn_component2 changed val do
		(
			KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][4][15][2]  = val
			if DebugModeOn do KrakatoaChannelNodeEditor_Rollout.debugFlow()
		)
		on spn_component3 changed val do
		(
			KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][4][15][3]  = val
			if DebugModeOn do KrakatoaChannelNodeEditor_Rollout.debugFlow()
		)
		on spn_component4 changed val do
		(
			KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][4][15][4]  = val
			if DebugModeOn do KrakatoaChannelNodeEditor_Rollout.debugFlow()
		)		
		on spn_Integer changed val do
		(
			KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][4][15][5]  = val
			if DebugModeOn do KrakatoaChannelNodeEditor_Rollout.debugFlow()
		)				
		on KrakatoaChannelNodeEditor_ChannelDebugRollout open do updateControls()
	)
	
	rollout KrakatoaChannelNodeEditor_FloatDebugRollout "Debug Mode Values" category:90
	(
		checkbox chk_GraphOutput "Use To Graph Output Value" align:#left offset:[-5,0]
		group "Graph Output Min.Value"
		(
			spinner spn_mincomponent1 "Min.Value:" fieldwidth:60 range:[-1000000,1000000,1]
		)
		group "Graph Output Max.Value"
		(
			spinner spn_maxcomponent1 "Max.Value:" fieldwidth:60 range:[-1000000,1000000,1]
		)
		
		fn updateControls =
		(
			if KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][4][15] == undefined do 
				KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][4][15] = #(1.0,1.0,1.0,1.0,1,0.0,0.0,0.0,0.0,1.0,1.0,1.0,1.0,false)			
			if KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][4][15][6] == undefined do KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][4][15][6] = 0.0
			if KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][4][15][7] == undefined do KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][4][15][7] = 0.0
			if KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][4][15][8] == undefined do KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][4][15][8] = 0.0
			if KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][4][15][9] == undefined do KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][4][15][9] = 0.0

			if KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][4][15][10] == undefined do KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][4][15][10] = 1.0
			if KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][4][15][11] == undefined do KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][4][15][11] = 1.0
			if KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][4][15][12] == undefined do KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][4][15][12] = 1.0
			if KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][4][15][13] == undefined do KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][4][15][13] = 1.0

			if KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][4][15][14] == undefined do KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][4][15][14] = false
			
			spn_mincomponent1.value = KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][4][15][6]
			spn_maxcomponent1.value = KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][4][15][10]
			chk_GraphOutput.state = KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][4][15][14]
		)
		
		on spn_mincomponent1 changed val do
		(
			KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][4][15][6]  = val
			if chk_GraphOutput.state do KrakatoaChannelNodeEditor_Rollout.debugFlow()
		)
		on spn_maxcomponent1 changed val do
		(
			KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][4][15][10]  = val
			if chk_GraphOutput.state do KrakatoaChannelNodeEditor_Rollout.debugFlow()
		)
		on chk_GraphOutput changed state do
		(
			KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][4][15][14] = state
			KrakatoaChannelNodeEditor_Rollout.debugFlow()
		)		
		
		on KrakatoaChannelNodeEditor_FloatDebugRollout open do updateControls()
	)	
	
	rollout KrakatoaChannelNodeEditor_VectorDebugRollout "Debug Mode Values" category:90
	(
		checkbox chk_GraphOutput "Use To Graph Output Value" align:#left offset:[-5,0]
		group "Graph Output Min.Values"
		(
			spinner spn_mincomponent1 "Component 1:" fieldwidth:60 range:[-1000000,1000000,1]
			spinner spn_mincomponent2 "Component 2:" fieldwidth:60 range:[-1000000,1000000,1]
			spinner spn_mincomponent3 "Component 3:" fieldwidth:60 range:[-1000000,1000000,1]
		)
		group "Graph Output Max.Values"
		(
			spinner spn_maxcomponent1 "Component 1:" fieldwidth:60 range:[-1000000,1000000,1]
			spinner spn_maxcomponent2 "Component 2:" fieldwidth:60 range:[-1000000,1000000,1]
			spinner spn_maxcomponent3 "Component 3:" fieldwidth:60 range:[-1000000,1000000,1]
		)
		
		fn updateControls =
		(
			if KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][4][15] == undefined do 
				KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][4][15] = #(1.0,1.0,1.0,1.0,1,0.0,0.0,0.0,0.0,1.0,1.0,1.0,1.0,false)			
			if KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][4][15][6] == undefined do KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][4][15][6] = 0.0
			if KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][4][15][7] == undefined do KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][4][15][7] = 0.0
			if KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][4][15][8] == undefined do KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][4][15][8] = 0.0
			if KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][4][15][9] == undefined do KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][4][15][9] = 0.0

			if KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][4][15][10] == undefined do KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][4][15][10] = 1.0
			if KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][4][15][11] == undefined do KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][4][15][11] = 1.0
			if KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][4][15][12] == undefined do KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][4][15][12] = 1.0
			if KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][4][15][13] == undefined do KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][4][15][13] = 1.0

			if KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][4][15][14] == undefined do KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][4][15][14] = false
			
			spn_mincomponent1.value = KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][4][15][6]
			spn_mincomponent2.value = KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][4][15][7]
			spn_mincomponent3.value = KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][4][15][8]

			spn_maxcomponent1.value = KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][4][15][10]
			spn_maxcomponent2.value = KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][4][15][11]
			spn_maxcomponent3.value = KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][4][15][12]

			chk_GraphOutput.state = KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][4][15][14]
		)
		
		on spn_mincomponent1 changed val do
		(
			KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][4][15][6]  = val
			if chk_GraphOutput.state do KrakatoaChannelNodeEditor_Rollout.debugFlow()
		)
		on spn_mincomponent2 changed val do
		(
			KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][4][15][7]  = val
			if chk_GraphOutput.state do KrakatoaChannelNodeEditor_Rollout.debugFlow()
		)
		on spn_mincomponent3 changed val do
		(
			KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][4][15][8]  = val
			if chk_GraphOutput.state do KrakatoaChannelNodeEditor_Rollout.debugFlow()
		)
		on spn_maxcomponent1 changed val do
		(
			KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][4][15][10]  = val
			if chk_GraphOutput.state do KrakatoaChannelNodeEditor_Rollout.debugFlow()
		)
		on spn_maxcomponent2 changed val do
		(
			KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][4][15][11]  = val
			if chk_GraphOutput.state do KrakatoaChannelNodeEditor_Rollout.debugFlow()
		)
		on spn_maxcomponent3 changed val do
		(
			KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][4][15][12]  = val
			if chk_GraphOutput.state do KrakatoaChannelNodeEditor_Rollout.debugFlow()
		)
		
		on chk_GraphOutput changed state do
		(
			KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][4][15][14] = state
			KrakatoaChannelNodeEditor_Rollout.debugFlow()
		)		
		on KrakatoaChannelNodeEditor_VectorDebugRollout open do updateControls()
	)	
	
	rollout KrakatoaChannelNodeEditor_ColorClipboardRollout "Color Clipboard" category:105
	(
		local theIniFile = (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini")

		button btn_loadPreset "Load Set..." width:80 across:2 align:#left offset:[-10,-1]
		button btn_savePreset "Save Set..." width:80 align:#right offset:[10,-1]
		
		colorpicker clr_slot01 width:32 height:20 modal:false align:#left across:5 offset:[-10,-3] color:white 
		colorpicker clr_slot02 width:32 height:20 modal:false align:#center offset:[-4,-3] color:(white*0.75)
		colorpicker clr_slot03 width:32 height:20 modal:false align:#center offset:[0,-3] color:(white*0.5)
		colorpicker clr_slot04 width:32 height:20 modal:false align:#center offset:[4,-3] color:(white*0.25)
		colorpicker clr_slot05 width:32 height:20 modal:false align:#right offset:[10,-3] color:black

		colorpicker clr_slot06 width:32 height:20 modal:false align:#left across:5 offset:[-10,-1] color:[255,0,0]
		colorpicker clr_slot07 width:32 height:20 modal:false align:#center offset:[-4,-1] color:[255,128,0]
		colorpicker clr_slot08 width:32 height:20 modal:false align:#center offset:[0,-1] color:[255,255,0]
		colorpicker clr_slot09 width:32 height:20 modal:false align:#center offset:[4,-1] color:[128,255,0]
		colorpicker clr_slot10 width:32 height:20 modal:false align:#right offset:[10,-1] color:[0,255,0]	
		
		colorpicker clr_slot11 width:32 height:20 modal:false align:#left across:5 offset:[-10,-1] color:[0,0,255]
		colorpicker clr_slot12 width:32 height:20 modal:false align:#center offset:[-4,-1] color:[0,128,255]
		colorpicker clr_slot13 width:32 height:20 modal:false align:#center offset:[0,-1] color:[0,255,255]
		colorpicker clr_slot14 width:32 height:20 modal:false align:#center offset:[4,-1] color:[128,0,255]
		colorpicker clr_slot15 width:32 height:20 modal:false align:#right offset:[10,-1] color:[255,0,128]

		button btn_resetColorsToDefaults "Reset Defaults" width:80 across:2 align:#left offset:[-10,-1]
		button btn_clearAllColors "Clear All" width:80 align:#right offset:[10,-1]

		local theControls = #(clr_slot01,clr_slot02,clr_slot03,clr_slot04,clr_slot05,clr_slot06,clr_slot07,clr_slot08,clr_slot09,clr_slot10,clr_slot11,clr_slot12,clr_slot13,clr_slot14,clr_slot15)

		fn saveColor theFile index col =
		(
			setIniSetting theFile "ColorClipboard" ("Color"+index as string) (col as string)
		)	

		fn saveAllColors theFilePath=
		(
			for i = 1 to theControls.count do saveColor theFilePath i theControls[i].color
		)
		
		fn restoreDefaults = 
		(
			local theDefaults = #(white, (white*0.75), (white*0.5), (white*0.25), black, [255,0,0], [255,128,0], [255,255,0], [128,255,0], [0,255,0], [0,0,255], [0,128,255], [0,255,255], [128,0,255], [255,0,128])
			for i = 1 to theControls.count do theControls[i].color = theDefaults[i]
		)
		
		fn clearAllColors =
		(
			theControls[1].color = black
			theControls[theControls.count].color = white
			for i = 2 to theControls.count-1 do theControls[i].color = white*0.3
		)
		
		fn loadColors theFile=
		(
			for i = 1 to theControls.count do
			(
				theVal = execute (getIniSetting theFile "ColorClipboard" ("Color"+i as string) )
				if theVal != OK do theControls[i].color=theVal
			)
		)
		
		on clr_slot01 changed col do saveColor theIniFile 1 col
		on clr_slot02 changed col do saveColor theIniFile 2 col
		on clr_slot03 changed col do saveColor theIniFile 3 col
		on clr_slot04 changed col do saveColor theIniFile 4 col
		on clr_slot05 changed col do saveColor theIniFile 5 col
		on clr_slot06 changed col do saveColor theIniFile 6 col
		on clr_slot07 changed col do saveColor theIniFile 7 col
		on clr_slot08 changed col do saveColor theIniFile 8 col
		on clr_slot09 changed col do saveColor theIniFile 9 col
		on clr_slot10 changed col do saveColor theIniFile 10 col
		on clr_slot11 changed col do saveColor theIniFile 11 col
		on clr_slot12 changed col do saveColor theIniFile 12 col
		on clr_slot13 changed col do saveColor theIniFile 13 col
		on clr_slot14 changed col do saveColor theIniFile 14 col
		on clr_slot15 changed col do saveColor theIniFile 15 col
			
		on btn_savePreset pressed do
		(
			makeDir (Krakatoa_PresetsDirectory+ "\\ColorClipboards\\") all:true
			local theFilePath = getSaveFileName filename:(Krakatoa_PresetsDirectory+ "\\ColorClipboards\\ColorClipboardSet01.kcs") caption:"Save Color Clipboard Set..." types:"MagmaFlow Color Clipboard Set (*.kcs)|*.kcs"
			if theFilePath != undefined do saveAllColors theFilePath
		)
		
		on btn_loadPreset pressed do
		(
			makeDir (Krakatoa_PresetsDirectory+ "\\ColorClipboards\\") all:true
			local theFilePath = getOpenFileName filename:(Krakatoa_PresetsDirectory+ "\\ColorClipboards\\ColorClipboardSet01.kcs") caption:"Load Color Clipboard Set..." types:"MagmaFlow Color Clipboard Set (*.kcs)|*.kcs"
			if theFilePath != undefined do loadColors theFilePath 
		)		
		
		on btn_resetColorsToDefaults pressed do
		(
			local q = querybox "Are you sure you want to RESET all color swatches in the Clipboard to factory defaults?" title:"RESET MagmaFlow Color Clipboard"
			if q do 
			(
				restoreDefaults()
				saveAllColors theIniFile
			)
		)	

		on btn_clearAllColors pressed do
		(
			local q = querybox "Are you sure you want to CLEAR all color swatches in the Clipboard?" title:"CLEAR MagmaFlow Color Clipboard"
			if q do
			(
				clearAllColors()
				saveAllColors theIniFile
			)
		)			

		on KrakatoaChannelNodeEditor_ColorClipboardRollout open do
		(
			restoreDefaults()
			loadColors theIniFile
		)
	)

	rollout KrakatoaChannelNodeEditor_InputRollout "Input" category:100
	(
		local theObjectFlags = #{}
		local thePreviewBitmap 
		local thePreviewBlankBitmap

		fn isGeometryObject obj = findItem geometryClass.classes (classof obj) > 0 and findItem ::KrakatoaChannelsEditor_TheOldObjects obj == 0 and classof obj != TargetObject and classof obj !=PRT_Volume and classof obj != PRT_FumeFX and classof obj != KrakatoaPRTLoader 
		
		
		group "Input Node Settings:"
		(
			dropdownlist ddl_InputType "Input Type:" height:10 items:#("Channel","Value","TextureMap","Script","Geometry") width:150 align:#center offset:[0,-3] --"Time", --,"Object"
			dropdownlist ddl_ValueType "Value Type:               " height:25 items:#() width:150 align:#center offset:[0,-3]
			dropdownlist ddl_TextureOutput "Texture Output Type:               " height:25 items:#("Color (Vector)","Mono (Float)","Normal Perturb (Vector)") width:150 align:#center offset:[0,-3]
			
			pickbutton pck_pickObjectSource ">>Pick Object..." width:150 align:#center offset:[0,-35] height:30

			edittext edt_ChannelName fieldwidth:149 offset:[-3,-48] align:#center
			edittext lbl_channelInfo "" offset:[-3,-4] align:#center readonly:true fieldwidth:149
			edittext lbl_isUsedByKrakatoa "" offset:[-3,-4] align:#center readonly:true fieldwidth:149
			dropdownlist ddl_sortingOptions "Channel List Sorting:" items:#("Factory Default Order","By Usage Frequency","Alphabetical","Alphabetical, Mapping Last","Int>Float>Vector>Quat","Integers Only","Floats Only","Vectors Only","Quaternions Only","PRT Hair Channels Only","Frost Channels Only","FumeFX Channels Only") offset:[0,0] width:150 height:20 align:#center
			
			spinner spn_valueInt "Integer:" range:[-1000000000,1000000000,0] visible:false offset:[0,-71] type:#integer controller:KrakatoaChannelEditor_CurrentIntController
			spinner spn_value "Float:" range:[-1000000000,1000000000,0] visible:false offset:[0,-21] controller:KrakatoaChannelEditor_CurrentFloatController scale:0.01
			button btn_getTextureMap "Get Texture Map..." width:150 align:#center visible:false offset:[0,-10]
			button btn_putMaterialToEditor "Put To Active MEditor Slot" width:150 align:#center visible:false offset:[0,-3]
			button btn_texturePreview width:150 height:150 align:#center visible:true offset:[0,-3]
			button btn_removeTextureMap "Remove Texture Map" width:150 align:#center visible:false offset:[0,-3]
			
			spinner spn_x "X:" range:[-1000000000,1000000000,0] offset:[0,-255] visible:false controller:KrakatoaChannelEditor_CurrentVectorController[1].controller scale:0.01
			spinner spn_y "Y:" range:[-1000000000,1000000000,0] visible:false controller:KrakatoaChannelEditor_CurrentVectorController[2].controller scale:0.01
			spinner spn_z "Z:" range:[-1000000000,1000000000,0] visible:false controller:KrakatoaChannelEditor_CurrentVectorController[3].controller scale:0.01
			colorpicker clr_color "As Color" align:#right fieldwidth:72 height:18 color:white offset:[0,0] visible:true alpha:true modal:false 
			colorpicker clr_colorComplementary "Complement:" align:#right fieldwidth:72 height:14 color:black offset:[0,-3] visible:true alpha:true modal:false
			
			button btn_connectToSceneTrack "Connect To Scene Track" width:150 align:#center offset:[0,-3]
			button btn_disconnectFromTrack "Disconnect From Scene Track" width:150 align:#center offset:[0,-3]
			button btn_zoomTrackView "Zoom In Track View" width:150 align:#center offset:[0,-3]
			

			label lbl_scriptCode "Expression:" align:#left offset:[0,-190]
			edittext edt_scriptCode width:154 height:150 offset:[-3,0] align:#center 
			checkbox chk_scriptCodeAutoCheck "Auto-Check For Errors" align:#left checked:scriptCodeAutoCheck

			button btn_addObjects "Add Names..." across:2 offset:[-5,-220] width:74 align:#left tooltip:"Add Geometry Objects to the Input Node. The names of the objects will be stored in the flow, not direct object references."
			pickbutton btn_pickObjects "Pick..." offset:[5,-220] width:74 align:#right filter:isGeometryObject tooltip:"Pick Geometry Objects to add to the Input Node. The names of the objects will be stored in the flow, not direct object references."

			multiListBox lbx_geometryobjectsList "" align:#center width:154 height:10 offset:[0,-3]
			
			button btn_removeObjects "Remove Highlighted Names..." offset:[0,-3] width:150 align:#center tooltip:"Remove the Objects highlighted on the Geometry Objects list."
			button btn_selectAllObjects "Highlight All" offset:[-5,0] width:74 align:#left across:2 tooltip:"Highlight all objects on the Geometry Objects list"
			button btn_selectInvertObjects "Invert" offset:[5,0] width:74 align:#right tooltip:"Invert the highlighted objects on the Geometry Objects list"
			button btn_selectObjectsInScene "Select Highlighted In Scene"offset:[0,-3] width:150 align:#center
			
			label lbl_void123 height:80
		)
		button btn_convertToFloat "Convert To Float" width:150 pos:[8,220] tooltip:"Insert a ToFloat Operator to convert the Input value to a Floating Point value."
		button btn_convertToVector "Convert To Vector" width:150 pos:[8,220] tooltip:"Insert a ToVector Operator to convert the Input value to a Vector value."
		button btn_convertVectorX "Extract X" width:50 pos:[8,220] tooltip:"Insert a ToScalar Operator with second Input socket set to 1 to extract the X component of the Vector value."
		button btn_convertVectorY "Extract Y" width:50 pos:[59,220] tooltip:"Insert a ToScalar Operator with second Input socket set to 2 to extract the Y component of the Vector value."
		button btn_convertVectorZ "Extract Z" width:50 pos:[110,220] tooltip:"Insert a ToScalar Operator with second Input socket set to 3 to extract the Z component of the Vector value."
		
		button btn_transformToWorld "To World" width:75 pos:[8,243] tooltip:"Insert a ToWorld Operator to transform the Vector to world space."
		button btn_transformToView "To View" width:75 pos:[85,243] tooltip:"Insert a ToView Operator to transform the Vector to view space."

		button btn_sameChannelAsOutput "Same Channel As Output" width:152 pos:[8,289] tooltip:"Switches the Input to the same Channel as the current Output Node."
		
		
		fn updateGeometryObjectNames =
		(
			local theNames = for o in KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][3][2] collect 
				(if (isValidNode (getNodeByName o) ) then ("+" + o) else ("--" + o))
			lbx_geometryobjectsList.items = theNames 
		)
		
		fn point3_filter_function val = 
		(
			local result = true
			try(if classof val.anim.value != Point3 do result = false)catch(result = false)
			result
		)
		
		fn float_filter_function val = 
		(
			local result = true
			try(if classof val.anim.value != Float AND classof val.anim.value != Integer do result = false)catch(result = false)
			result
		)		
		
		fn getUsedByRendererState =
		(
			if renderers.current.classid as string == "#(-1204370534, -399920359)" or renderers.current.classid as string == "#(3090596762L, 3895046937L)" do --if Krakatoa is the Renderer
			(
				try(
					Krakatoa_GUI_Channels.updateMemChannels()
					lbl_isUsedByKrakatoa.text = if (for i in Krakatoa_GUI_Channels.activeMemChannels where matchPattern i[1] pattern:edt_ChannelName.text collect i).count == 1 then
						"Will Be Stored In PCache" 
					else 
						"Not Cacheable"
				)catch(lbl_isUsedByKrakatoa.text = "")	
			)
		)
		
		fn getConnectedNode =
		(
			local theController = case ddl_ValueType.selected of
			(
				"Integer": try(execute ("trackViewNodes.KrakatoaChannelEditor.KCE_"+KrakatoaChannelNodeEditor_CurrentModifier.trackID+".Input_"+KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][4][4]+"[1].controller"))catch(undefined)
				"Float": try(execute ("trackViewNodes.KrakatoaChannelEditor.KCE_"+KrakatoaChannelNodeEditor_CurrentModifier.trackID+".Input_"+KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][4][4]+"[2].controller"))catch(undefined)
				"Vector": try(execute ("trackViewNodes.KrakatoaChannelEditor.KCE_"+KrakatoaChannelNodeEditor_CurrentModifier.trackID+".Input_"+KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][4][4]+"[3].controller"))catch(undefined)
			)	
			if classof theController == Float_List  do theController = theController[2].controller
			if classof theController == Point3_List do theController = theController[2].controller[1].controller

			if classof theController == Float_Script then
			(
				try
				(
					local theTarget = theController.GetTarget "KCE_Reference" asObject:false
					exprForMAXObject theTarget explicitNames:true
				)
				catch("Connect To Scene Track")
			)	
			else 
				"Connect To Scene Track"
		)
		
		fn createControllers =
		(
			if KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][4][4] == undefined do 
			(
				local theNodeID = ((random 10000 1000000) as string + "_" + (random 10000 1000000) as string)
				KrakatoaChannelsEditor_Functions.createTrackViewControllers theNodeID KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick]
				KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][4][4] = theNodeID
			)
			KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][3][3] = "trackViewNodes.KrakatoaChannelEditor.KCE_"+KrakatoaChannelNodeEditor_CurrentModifier.trackID+".Input_"+KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][4][4]
			KrakatoaChannelNodeEditor_Rollout.displaySelectedNodeProperties()
		)
		
		fn storeValues =
		(
			try
			(
				if KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][4][5] == undefined do 
					KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][4][5] = #()
				case ddl_ValueType.selected of
				(
					"Integer": KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][4][5][1] = spn_valueInt.value
					"Float": KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][4][5][2] = spn_value.value
					"Vector": KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][4][5][3] = [spn_X.value,spn_y.value,spn_z.value]
				)
			)catch()	
		)
		
		fn updateBitmapPreview forceUpdate:false=
		(
			if ddl_ValueType.selection > 0 do
			(
				if ddl_ValueType.selection == 1 then
				(
					if selection.count == 1 and selection[1].material != undefined and (try(selection[1].material.diffusemap != undefined)catch(false)) then
						thePreviewBitmap = renderMap selection[1].material.diffusemap scale:500.0 --into:thePreviewBitmap 
					else
						copy thePreviewBlankBitmap thePreviewBitmap 
				)
				else
				(
					if not KrakatoaChannelNodeEditor_Rollout.chk_autoUpdateModifier.checked and forceUpdate != true then
					(
						copy thePreviewBlankBitmap thePreviewBitmap 
					)
					else
					(
						thePreviewBitmap = renderMap KrakatoaChannelNodeEditor_CurrentModifier.TextureMapSources[ddl_ValueType.selection-1] scale:500.0 --into:thePreviewBitmap 
						--display thePreviewBitmap
					)
				)
				btn_texturePreview.images = #(thePreviewBitmap,undefined,1,1,1,1,1)
			)
		)
		
		fn updateControls =
		(
			if KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][4][8] == undefined do KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][4][8] = "Untitled"
			KrakatoaChannelNodeEditor_NodeNameRollout.edt_nodeName.text = KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][4][8]
			case ddl_InputType.selected of
			(
				"Channel": 
				(
					ddl_ValueType.caption = "Channel Name:"
					if KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][3][3] != undefined do 
						deleteItem KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][3] 3
					
					if KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][4][9] == undefined do KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][4][9] = "Color"
						KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][3][2] = KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][4][9]
					
					ddl_sortingOptions.visible = lbl_isUsedByKrakatoa.visible = lbl_channelInfo.visible = ddl_ValueType.visible = true
					ddl_TextureOutput.visible = btn_texturePreview.visible = pck_pickObjectSource.visible = edt_ChannelName.visible = false
					btn_pickObjects.visible = btn_selectObjectsInScene.visible = btn_selectAllObjects.visible = btn_selectInvertObjects.visible =btn_addObjects.visible = btn_removeObjects.visible = lbx_geometryobjectsList.visible = chk_scriptCodeAutoCheck.visible = lbl_scriptCode.visible = edt_scriptCode.visible = btn_connectToSceneTrack.visible = btn_disconnectFromTrack.visible = btn_removeTextureMap.visible = btn_putMaterialToEditor.visible = btn_getTextureMap.visible = btn_zoomTrackView.visible = spn_valueInt.visible = spn_value.visible = spn_x.visible = spn_y.visible = spn_z.visible = clr_color.visible = clr_colorComplementary.visible = false
					ddl_ValueType.items =  KrakatoaChannelsEditor_Functions.getSortedChannelsList ddl_sortingOptions.selection
					edt_ChannelName.text = KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][3][2]
					btn_sameChannelAsOutput.visible = KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][3][2] != KrakatoaChannelEditor_DisplayNodeTreeData[1][3][1] AND findItem ddl_ValueType.items KrakatoaChannelEditor_DisplayNodeTreeData[1][3][1] > 0
					btn_sameChannelAsOutput.pos = [8,289]
					
					btn_convertToFloat.pos = [8,220]
					local theIndex = findItem (for i in channelsList collect i[1]) KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][3][2]
					btn_convertToFloat.visible = theIndex > 0 and matchPattern channelsList[theIndex][2] pattern:"int*" 
					
					btn_convertVectorX.pos = [8,220]
					btn_convertVectorY.pos = [59,220]
					btn_convertVectorZ.pos = [110,220]
					btn_convertToVector.pos = [8,220]
					
					btn_convertVectorX.text = "Extract X"
					btn_convertVectorY.text = "Extract Y"
					btn_convertVectorZ.text = "Extract Z"
					
					
					btn_transformToWorld.pos = [8,243] 
					btn_transformToView.pos = [85,243]					
					
					local theIndex = findItem (for i in channelsList collect i[1]) KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][3][2]
					btn_convertVectorX.visible = btn_convertVectorY.visible = btn_convertVectorZ.visible = theIndex > 0 and matchPattern channelsList[theIndex][2] pattern:"Float*" and channelsList[theIndex][3] == 3
					btn_transformToWorld.visible = btn_transformToView.visible = theIndex > 0 and matchPattern channelsList[theIndex][2] pattern:"Float*" and channelsList[theIndex][3] == 3 and (findItem #("Position","Velocity","Normal","Tangent","Acceleration") channelsList[theIndex][1] > 0)
					btn_convertToVector.visible = theIndex > 0 and matchPattern channelsList[theIndex][2] pattern:"Float*" and channelsList[theIndex][3] == 1

					local theIndex = findItem ddl_ValueType.items KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][3][2]
					if theIndex == 0 do 
					(
						theIndex = 1
						edt_ChannelName.visible = true
					)
					ddl_ValueType.selection = theIndex
					lbl_channelInfo.text = if theIndex > 1 then sortedChannelsList[theIndex-1][4] else "User-Defined Channel Name"
					getUsedByRendererState()
				)
				"Value": 
				(
					ddl_ValueType.caption = "Value Type:"
					ddl_ValueType.items = #("Vector","Float","Integer")
					ddl_ValueType.selection = findItem ddl_ValueType.items KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][3][2]
					if KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][4][4] == undefined do 
					(
						local theNodeID = ((random 10000 1000000) as string + "_" + (random 10000 1000000) as string)
						KrakatoaChannelsEditor_Functions.createTrackViewControllers theNodeID KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick]
						KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][4][4] = theNodeID
					)
					KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][3][3] = "trackViewNodes.KrakatoaChannelEditor.KCE_"+KrakatoaChannelNodeEditor_CurrentModifier.trackID+".Input_"+KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][4][4]
					if ddl_ValueType.selection ==0 do 
					(
						ddl_ValueType.selection = 1
						KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][3][2] = ddl_ValueType.selected
					)	
					btn_sameChannelAsOutput.visible = false

					case ddl_ValueType.selected of
					(
						"Integer" : (
							btn_convertToFloat.pos = [8,170]
							btn_convertToFloat.visible = btn_connectToSceneTrack.visible = btn_disconnectFromTrack.visible = btn_zoomTrackView.visible = spn_valueInt.visible = ddl_ValueType.visible = true
							btn_pickObjects.visible = btn_selectObjectsInScene.visible = ddl_TextureOutput.visible = btn_texturePreview.visible = pck_pickObjectSource.visible = btn_selectAllObjects.visible = btn_selectInvertObjects.visible =btn_addObjects.visible = btn_removeObjects.visible = lbx_geometryobjectsList.visible = ddl_sortingOptions.visible = lbl_isUsedByKrakatoa.visible = lbl_channelInfo.visible = chk_scriptCodeAutoCheck.visible = lbl_scriptCode.visible = edt_scriptCode.visible = btn_removeTextureMap.visible = btn_putMaterialToEditor.visible = btn_getTextureMap.visible = spn_value.visible = edt_ChannelName.visible = spn_x.visible = spn_y.visible = spn_z.visible = clr_color.visible = clr_colorComplementary.visible = false
							btn_convertToVector.visible = btn_transformToWorld.visible = btn_transformToView.visible = btn_convertVectorX.visible = btn_convertVectorY.visible = btn_convertVectorZ.visible = false
							spn_valueInt.enabled = KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][4][17] == undefined
							
							)						
						"Float": (
							btn_convertToVector.visible = btn_connectToSceneTrack.visible = btn_disconnectFromTrack.visible = btn_zoomTrackView.visible = ddl_ValueType.visible = spn_value.visible = true
							btn_pickObjects.visible = btn_selectObjectsInScene.visible = btn_convertToFloat.visible = ddl_TextureOutput.visible = btn_texturePreview.visible = pck_pickObjectSource.visible = btn_selectAllObjects.visible = btn_selectInvertObjects.visible =btn_addObjects.visible = btn_removeObjects.visible = lbx_geometryobjectsList.visible = ddl_sortingOptions.visible = lbl_isUsedByKrakatoa.visible = lbl_channelInfo.visible = chk_scriptCodeAutoCheck.visible = lbl_scriptCode.visible = edt_scriptCode.visible = btn_removeTextureMap.visible = btn_putMaterialToEditor.visible = btn_getTextureMap.visible = spn_valueInt.visible = edt_ChannelName.visible = spn_x.visible = spn_y.visible = spn_z.visible = clr_color.visible = clr_colorComplementary.visible = false
							btn_transformToWorld.visible = btn_transformToView.visible = btn_convertVectorX.visible = btn_convertVectorY.visible = btn_convertVectorZ.visible = false
							spn_value.enabled = KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][4][18] == undefined
							btn_convertToVector.pos = [8,170]
							)
						"Vector": (
							btn_connectToSceneTrack.visible = btn_disconnectFromTrack.visible = btn_zoomTrackView.visible = ddl_ValueType.visible = spn_x.visible = spn_y.visible = spn_z.visible = clr_color.visible = clr_colorComplementary.visible = true
							btn_convertToVector.visible = btn_pickObjects.visible = btn_selectObjectsInScene.visible = btn_convertToFloat.visible = ddl_TextureOutput.visible = btn_texturePreview.visible = pck_pickObjectSource.visible = btn_selectAllObjects.visible = btn_selectInvertObjects.visible =btn_addObjects.visible = btn_removeObjects.visible = lbx_geometryobjectsList.visible = ddl_sortingOptions.visible = lbl_isUsedByKrakatoa.visible = lbl_channelInfo.visible = chk_scriptCodeAutoCheck.visible = lbl_scriptCode.visible = edt_scriptCode.visible = btn_removeTextureMap.visible = btn_putMaterialToEditor.visible = btn_getTextureMap.visible = spn_valueInt.visible = edt_ChannelName.visible = spn_value.visible  = false
							clr_color.color = [spn_x.value, spn_y.value , spn_z.value , 1]
							clr_colorComplementary.color = white - clr_color.color
							btn_transformToWorld.visible = btn_transformToView.visible = btn_convertVectorX.visible = btn_convertVectorY.visible = btn_convertVectorZ.visible = true
							btn_convertVectorX.pos = [8,300]
							btn_convertVectorY.pos = [59,300]
							btn_convertVectorZ.pos = [110,300]							
							btn_transformToWorld.pos = [8,323] 
							btn_transformToView.pos = [85,323]
							spn_x.enabled = spn_y.enabled = spn_z.enabled = KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][4][19] == undefined
						)
					)	
					btn_connectToSceneTrack.tooltip = btn_connectToSceneTrack.text = getConnectedNode()
				)
				"TextureMap":
				(
					/*if KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][3][3] != undefined do 
						deleteItem KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][3] 3					*/
					ddl_ValueType.caption = "Texture Map:"
					ddl_TextureOutput.visible = btn_texturePreview.visible = btn_removeTextureMap.visible = btn_putMaterialToEditor.visible = btn_getTextureMap.visible = ddl_ValueType.visible = true
					btn_convertToVector.visible = btn_transformToWorld.visible = btn_transformToView.visible = btn_pickObjects.visible = btn_selectObjectsInScene.visible = btn_convertToFloat.visible = pck_pickObjectSource.visible = btn_selectAllObjects.visible = btn_selectInvertObjects.visible =btn_addObjects.visible = btn_removeObjects.visible = lbx_geometryobjectsList.visible = ddl_sortingOptions.visible = lbl_isUsedByKrakatoa.visible = lbl_channelInfo.visible = chk_scriptCodeAutoCheck.visible = lbl_scriptCode.visible = edt_scriptCode.visible = btn_connectToSceneTrack.visible = btn_disconnectFromTrack.visible = btn_zoomTrackView.visible = spn_valueInt.visible = spn_value.visible = edt_ChannelName.visible = spn_x.visible = spn_y.visible = spn_z.visible = clr_color.visible = clr_colorComplementary.visible = false
					
					ddl_ValueType.items = join #("Object's Diffuse Map") (for i in KrakatoaChannelNodeEditor_CurrentModifier.TextureMapSources collect i as string)
					if classof KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][3][2] != Integer do 
						KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][3][2] = 1
					ddl_ValueType.selection = KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][3][2]
					local theIndex = findItem #("Color","Mono","Perturb") KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][3][3]
					if theIndex == 0 do 
					(
						KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][3][3] = "Color"
						theIndex = 1
					)
					ddl_TextureOutput.selection = theIndex
					updateBitmapPreview()
					
					btn_sameChannelAsOutput.visible = false
					btn_convertVectorX.visible = btn_convertVectorY.visible = btn_convertVectorZ.visible = theIndex != 2
					
					btn_convertVectorX.pos = [8,370]
					btn_convertVectorY.pos = [59,370]
					btn_convertVectorZ.pos = [110,370]		
					
					btn_convertVectorX.text = "Extract R"
					btn_convertVectorY.text = "Extract G"
					btn_convertVectorZ.text = "Extract B"
					
				)
				/*"Time": 
				(
					if KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][3][3] != undefined do 
						deleteItem KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][3] 3					
					KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][3][2] = "Frame"
					lbl_isUsedByKrakatoa.visible = ddl_sortingOptions.visible = lbl_channelInfo.visible = chk_scriptCodeAutoCheck.visible = lbl_scriptCode.visible = edt_scriptCode.visible = btn_connectToSceneTrack.visible = btn_disconnectFromTrack.visible = btn_removeTextureMap.visible = btn_putMaterialToEditor.visible = btn_getTextureMap.visible = btn_zoomTrackView.visible = edt_ChannelName.visible = spn_valueInt.visible = ddl_ValueType.visible = spn_value.visible = spn_x.visible = spn_y.visible = spn_z.visible = clr_color.visible = clr_colorComplementary.visible = false
				)*/
				"Script": 
				(
					if KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][3][3] != undefined do 
						deleteItem KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][3] 3					
					if KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][4][6] == undefined do KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][4][6] = "0"
					KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][3][2] = KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][4][6]
					edt_scriptCode.text =  KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][3][2] 
					chk_scriptCodeAutoCheck.visible = lbl_scriptCode.visible = edt_scriptCode.visible = true
					btn_pickObjects.visible = btn_selectObjectsInScene.visible = btn_convertToFloat.visible = ddl_TextureOutput.visible = btn_texturePreview.visible = pck_pickObjectSource.visible = btn_selectAllObjects.visible = btn_selectInvertObjects.visible =btn_addObjects.visible = btn_removeObjects.visible = lbx_geometryobjectsList.visible = ddl_sortingOptions.visible = lbl_isUsedByKrakatoa.visible = lbl_channelInfo.visible = btn_connectToSceneTrack.visible = btn_disconnectFromTrack.visible = btn_removeTextureMap.visible = btn_putMaterialToEditor.visible = btn_getTextureMap.visible = btn_zoomTrackView.visible = edt_ChannelName.visible = spn_valueInt.visible = ddl_ValueType.visible = spn_value.visible = spn_x.visible = spn_y.visible = spn_z.visible = clr_color.visible = clr_colorComplementary.visible = false
					btn_convertToVector.visible = btn_transformToWorld.visible = btn_transformToView.visible = btn_convertVectorX.visible = btn_convertVectorY.visible = btn_convertVectorZ.visible = false
					btn_sameChannelAsOutput.visible = false
				)
				"Geometry":
				(
					if classof KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][3][2] != Array do KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][3][2]  = #()
					if try(classof KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][4][5][4] == Array)catch(false) do KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][3][2] = KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][4][5][4]
					btn_pickObjects.visible = btn_selectObjectsInScene.visible = btn_selectAllObjects.visible = btn_selectInvertObjects.visible =btn_addObjects.visible = btn_removeObjects.visible = lbx_geometryobjectsList.visible = true
					btn_convertToFloat.visible = ddl_TextureOutput.visible = btn_texturePreview.visible = pck_pickObjectSource.visible = chk_scriptCodeAutoCheck.visible = lbl_scriptCode.visible = edt_scriptCode.visible = ddl_sortingOptions.visible = lbl_isUsedByKrakatoa.visible = lbl_channelInfo.visible = btn_connectToSceneTrack.visible = btn_disconnectFromTrack.visible = btn_removeTextureMap.visible = btn_putMaterialToEditor.visible = btn_getTextureMap.visible = btn_zoomTrackView.visible = edt_ChannelName.visible = spn_valueInt.visible = ddl_ValueType.visible = spn_value.visible = spn_x.visible = spn_y.visible = spn_z.visible = clr_color.visible = clr_colorComplementary.visible = false
					btn_convertToVector.visible = btn_transformToWorld.visible = btn_transformToView.visible = btn_convertVectorX.visible = btn_convertVectorY.visible = btn_convertVectorZ.visible = false
					btn_sameChannelAsOutput.visible = false
					updateGeometryObjectNames()
					global KrakatoaChannelsEditor_TheOldObjects = for o in KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][3][2] collect getNodeByName o
				)
				"Object":
				(
					if KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][3][3] != undefined do 
						deleteItem KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][3] 3						
					pck_pickObjectSource.visible = true
					btn_pickObjects.visible = btn_selectObjectsInScene.visible = btn_selectAllObjects.visible = btn_selectInvertObjects.visible =btn_addObjects.visible = btn_removeObjects.visible = lbx_geometryobjectsList.visible = false
					btn_convertToFloat.visible = ddl_TextureOutput.visible = btn_texturePreview.visible = chk_scriptCodeAutoCheck.visible = lbl_scriptCode.visible = edt_scriptCode.visible = ddl_sortingOptions.visible = lbl_isUsedByKrakatoa.visible = lbl_channelInfo.visible = btn_connectToSceneTrack.visible = btn_disconnectFromTrack.visible = btn_removeTextureMap.visible = btn_putMaterialToEditor.visible = btn_getTextureMap.visible = btn_zoomTrackView.visible = edt_ChannelName.visible = spn_valueInt.visible = ddl_ValueType.visible = spn_value.visible = spn_x.visible = spn_y.visible = spn_z.visible = clr_color.visible = clr_colorComplementary.visible = false
					btn_convertToVector.visible = btn_transformToWorld.visible = btn_transformToView.visible = btn_convertVectorX.visible = btn_convertVectorY.visible = btn_convertVectorZ.visible = false
					btn_sameChannelAsOutput.visible = false
					local theObject = undefined
					local theName = KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][3][2]
					try(theObject = getNodeByName theName)catch()
					pck_pickObjectSource.caption = if theObject != undefined then theName else ">>Pick Object..."
				)
				"Notes":
				(
					pck_pickObjectSource.visible = false
					btn_sameChannelAsOutput.visible = false
					btn_pickObjects.visible = btn_selectObjectsInScene.visible = btn_selectAllObjects.visible = btn_selectInvertObjects.visible =btn_addObjects.visible = btn_removeObjects.visible =  lbx_geometryobjectsList.visible = false 
					btn_convertToFloat.visible = ddl_TextureOutput.visible = btn_texturePreview.visible = chk_scriptCodeAutoCheck.visible = lbl_scriptCode.visible = edt_scriptCode.visible = ddl_sortingOptions.visible = lbl_isUsedByKrakatoa.visible = lbl_channelInfo.visible = btn_connectToSceneTrack.visible = btn_disconnectFromTrack.visible = btn_removeTextureMap.visible = btn_putMaterialToEditor.visible = btn_getTextureMap.visible = btn_zoomTrackView.visible = edt_ChannelName.visible = spn_valueInt.visible = ddl_ValueType.visible = spn_value.visible = spn_x.visible = spn_y.visible = spn_z.visible = clr_color.visible = clr_colorComplementary.visible = false
					btn_convertToVector.visible = btn_transformToWorld.visible = btn_transformToView.visible = btn_convertVectorX.visible = btn_convertVectorY.visible = btn_convertVectorZ.visible = false
				)
			)			
		)
		
		on btn_texturePreview pressed do updateBitmapPreview forceUpdate:true
			
		on btn_convertToFloat pressed do
		(
			local oldNode = KrakatoaChannelNodeEditor_Rollout.lastNodeClick
			KrakatoaChannelNodeEditor_Rollout.addNewOperator type:"ToFloat" creationType:#keyboard	 selectNewNode:false makeUndoRecord:false
			for i = 1 to KrakatoaChannelEditor_DisplayNodeTreeData.count-1 where i != oldNode do
			(
				for j = 1 to KrakatoaChannelEditor_DisplayNodeTreeData[i][2].count do
					if KrakatoaChannelEditor_DisplayNodeTreeData[i][2][j] == oldNode do 
						KrakatoaChannelEditor_DisplayNodeTreeData[i][2][j] = KrakatoaChannelEditor_DisplayNodeTreeData.count
			)
			KrakatoaChannelNodeEditor_Rollout.createNodeTree init:true
			if AutoReorderToggle do KrakatoaChannelNodeEditor_Rollout.autoReorderFlow createUndo:false
			if AutoZoomExtents do KrakatoaChannelNodeEditor_Rollout.zoomExtents createUndo:false
			KrakatoaChannelNodeEditor_Rollout.createUndoRecord ("Integer To Float Conversion")	
			KrakatoaChannelNodeEditor_Rollout.displaySelectedNodeProperties()
			if KrakatoaChannelNodeEditor_Rollout.chk_autoUpdateModifier.checked do KrakatoaChannelsEditor_Functions.updateParentModifier()
		)
		
		on btn_convertToVector pressed do
		(
			local oldNode = KrakatoaChannelNodeEditor_Rollout.lastNodeClick
			KrakatoaChannelNodeEditor_Rollout.addNewOperator type:"ToVector" creationType:#keyboard selectNewNode:false makeUndoRecord:false
			for i = 1 to KrakatoaChannelEditor_DisplayNodeTreeData.count-1 where i != oldNode do
			(
				for j = 1 to KrakatoaChannelEditor_DisplayNodeTreeData[i][2].count do
					if KrakatoaChannelEditor_DisplayNodeTreeData[i][2][j] == oldNode do 
						KrakatoaChannelEditor_DisplayNodeTreeData[i][2][j] = KrakatoaChannelEditor_DisplayNodeTreeData.count
			)
			KrakatoaChannelNodeEditor_Rollout.createNodeTree init:true
			if AutoReorderToggle do KrakatoaChannelNodeEditor_Rollout.autoReorderFlow createUndo:false
			if AutoZoomExtents do KrakatoaChannelNodeEditor_Rollout.zoomExtents createUndo:false
			KrakatoaChannelNodeEditor_Rollout.createUndoRecord ("Float To Vector Conversion")	
			KrakatoaChannelNodeEditor_Rollout.displaySelectedNodeProperties()
			if KrakatoaChannelNodeEditor_Rollout.chk_autoUpdateModifier.checked do KrakatoaChannelsEditor_Functions.updateParentModifier()
		)
		
		fn convertVectorToScalar component undoName=
		(
			local oldNode = KrakatoaChannelNodeEditor_Rollout.lastNodeClick
			KrakatoaChannelNodeEditor_Rollout.addNewOperator type:"ToScalar" creationType:#keyboard selectNewNode:true makeUndoRecord:false
			for i = 1 to KrakatoaChannelEditor_DisplayNodeTreeData.count-1 where i != oldNode do
			(
				for j = 1 to KrakatoaChannelEditor_DisplayNodeTreeData[i][2].count do
					if KrakatoaChannelEditor_DisplayNodeTreeData[i][2][j] == oldNode do 
						KrakatoaChannelEditor_DisplayNodeTreeData[i][2][j] = KrakatoaChannelEditor_DisplayNodeTreeData.count
			)
			KrakatoaChannelNodeEditor_Rollout.addNewInput type:#value valueType:#integer creationType:#keyboard defaultValue:component makeUndoRecord:false
			KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelEditor_DisplayNodeTreeData.count][4][3] = false
			KrakatoaChannelEditor_DisplayNodeTreeData[oldNode][4][3] = true			
			
			KrakatoaChannelNodeEditor_Rollout.lastNodeClick = oldNode
			KrakatoaChannelNodeEditor_Rollout.createNodeTree init:true
			if AutoReorderToggle do KrakatoaChannelNodeEditor_Rollout.autoReorderFlow createUndo:false
			if AutoZoomExtents do KrakatoaChannelNodeEditor_Rollout.zoomExtents createUndo:false
				
			KrakatoaChannelNodeEditor_Rollout.setSelectedNodes #(oldNode)	
			KrakatoaChannelNodeEditor_Rollout.createUndoRecord (undoName)		
			KrakatoaChannelNodeEditor_Rollout.displaySelectedNodeProperties()			
			if KrakatoaChannelNodeEditor_Rollout.chk_autoUpdateModifier.checked do KrakatoaChannelsEditor_Functions.updateParentModifier()
		)
		
		fn transformVectorTo theType:"ToWorld" =
		(
			local oldNode = KrakatoaChannelNodeEditor_Rollout.lastNodeClick
			KrakatoaChannelNodeEditor_Rollout.addNewOperator type:theType creationType:#keyboard selectNewNode:false makeUndoRecord:false
			local theNewIndex = KrakatoaChannelEditor_DisplayNodeTreeData.count
			
			for i = 1 to KrakatoaChannelEditor_DisplayNodeTreeData.count-1 where i != oldNode do
			(
				for j = 1 to KrakatoaChannelEditor_DisplayNodeTreeData[i][2].count do
					if KrakatoaChannelEditor_DisplayNodeTreeData[i][2][j] == oldNode do 
						KrakatoaChannelEditor_DisplayNodeTreeData[i][2][j] = theNewIndex
			)
			KrakatoaChannelEditor_DisplayNodeTreeData[theNewIndex][4][9] = KrakatoaChannelEditor_DisplayNodeTreeData[theNewIndex][3][2] = "Point"
			if KrakatoaChannelEditor_DisplayNodeTreeData[oldNode][3][1] == "Channel" and (KrakatoaChannelEditor_DisplayNodeTreeData[oldNode][3][2] == "Normal" or KrakatoaChannelEditor_DisplayNodeTreeData[oldNode][3][2] == "Tangent") do
				KrakatoaChannelEditor_DisplayNodeTreeData[theNewIndex][4][9] = KrakatoaChannelEditor_DisplayNodeTreeData[theNewIndex][3][2] = "Normal"
			
			if KrakatoaChannelEditor_DisplayNodeTreeData[oldNode][3][1] == "Channel" and (KrakatoaChannelEditor_DisplayNodeTreeData[oldNode][3][2] == "Velocity" or KrakatoaChannelEditor_DisplayNodeTreeData[oldNode][3][2] == "Acceleration") do
				KrakatoaChannelEditor_DisplayNodeTreeData[theNewIndex][4][9] = KrakatoaChannelEditor_DisplayNodeTreeData[theNewIndex][3][2] = "Vector"
			
			KrakatoaChannelNodeEditor_Rollout.createNodeTree init:true
			KrakatoaChannelNodeEditor_Rollout.setSelectedNodes #(oldNode)	
			KrakatoaChannelNodeEditor_Rollout.createUndoRecord ("Insert Transform " + theType)		
			KrakatoaChannelNodeEditor_Rollout.displaySelectedNodeProperties()			
			if KrakatoaChannelNodeEditor_Rollout.chk_autoUpdateModifier.checked do KrakatoaChannelsEditor_Functions.updateParentModifier()			
		)
		

		
		on btn_transformToWorld pressed do
		(
			transformVectorTo theType:"ToWorld"
		)
			
		on  btn_transformToView pressed do
		(
			transformVectorTo theType:"ToView"
		)
		
		on btn_convertVectorX pressed do
		(
			convertVectorToScalar 1 "Vector To Component 1 Conversion"
		)
		on btn_convertVectorY pressed do
		(
			convertVectorToScalar 2 "Vector To Component 2 Conversion"
		)
		on btn_convertVectorZ pressed do
		(
			convertVectorToScalar 3 "Vector To Component 3 Conversion"
		)		
		
		on pck_pickObjectSource picked obj do
		(
			if isValidNode obj do
			(
				KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][3][2] = obj.name
				pck_pickObjectSource.text = obj.name
				KrakatoaChannelNodeEditor_Rollout.createNodeTree init:false
			)
		)

		
		on btn_addObjects pressed do
		(
			local theObjects = selectByName title:"Select Geometry Objects" buttonText:"Add" filter:isGeometryObject showHidden:true single:false
			if theObjects  != undefined do
			(
				join KrakatoaChannelsEditor_TheOldObjects theObjects
				if KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][4][5] == undefined do KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][4][5] = #()
				KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][4][5][4] = KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][3][2] = (for o in KrakatoaChannelsEditor_TheOldObjects where isValidNode o collect o.name) 
				updateGeometryObjectNames()
				if theObjects.count == 1 then
					KrakatoaChannelNodeEditor_Rollout.createUndoRecord ("Geometry Object ["+theObjects[1].name+"] Picked From Scene.")
				else
					KrakatoaChannelNodeEditor_Rollout.createUndoRecord (theObjects.count  as string+" Geometry Objects Added To Input Node.")
				KrakatoaChannelNodeEditor_Rollout.createNodeTree init:false
				updateControls()
				if KrakatoaChannelNodeEditor_Rollout.chk_autoUpdateModifier.checked do KrakatoaChannelsEditor_Functions.updateParentModifier()
				KrakatoaChannelNodeEditor_Rollout.updateNodeDependencies()
			)
		)		
		
		on btn_pickObjects picked obj do
		(
			if obj != undefined do 
			(
				append KrakatoaChannelsEditor_TheOldObjects obj
				KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][4][5][4] = KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][3][2] = (for o in KrakatoaChannelsEditor_TheOldObjects where isValidNode o collect o.name) 
				updateGeometryObjectNames()
				KrakatoaChannelNodeEditor_Rollout.createUndoRecord ("Geometry Object ["+obj.name+"] Picked From Scene.")
				KrakatoaChannelNodeEditor_Rollout.createNodeTree init:false
				updateControls()
				if KrakatoaChannelNodeEditor_Rollout.chk_autoUpdateModifier.checked do KrakatoaChannelsEditor_Functions.updateParentModifier()
				KrakatoaChannelNodeEditor_Rollout.updateNodeDependencies()
			)
		)
		
		on btn_removeObjects pressed do
		(
			local theSelection = lbx_geometryobjectsList.selection as array
			if theSelection.count > 0 do
			(
				--local q = querybox ("Remove "+ (if theSelection.count > 1 then theSelection.count as string + " Highlighted Geometry Objects " else "One Highlighted Geometry Object " ) + "from the list?") title:"Remove Geometry Objects?"
				--if q do
				(
					local theOldArray = deepCopy KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][3][2]
					for i = theSelection.count to 1 by -1 do deleteItem theOldArray theSelection[i]
					KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][4][5][4] = KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][3][2]	= theOldArray
					updateGeometryObjectNames()
					KrakatoaChannelNodeEditor_Rollout.createUndoRecord ("Geometry Objects Removed from Input Node.")
					KrakatoaChannelNodeEditor_Rollout.createNodeTree init:false
					updateControls()
					if KrakatoaChannelNodeEditor_Rollout.chk_autoUpdateModifier.checked do KrakatoaChannelsEditor_Functions.updateParentModifier()
					KrakatoaChannelNodeEditor_Rollout.updateNodeDependencies()
				)
			)
		)
		
		fn selectHighlightedInScene =
		(
			max select none
			select (for i in lbx_geometryobjectsList.selection where isValidNode (getNodeByName KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][3][2][i]) collect getNodeByName KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][3][2][i])
		)

		on btn_selectObjectsInScene pressed do 
		(
			selectHighlightedInScene()
		)
		
		on lbx_geometryobjectsList doubleClicked itm do
		(
			selectHighlightedInScene()
		)
		
		on btn_selectAllObjects pressed do lbx_geometryobjectsList.selection = #{1..lbx_geometryobjectsList.items.count}
		on btn_selectInvertObjects pressed do lbx_geometryobjectsList.selection = -lbx_geometryobjectsList.selection
		
		on ddl_sortingOptions selected itm do
		(
			updateControls()
			setIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "ParticleChannelEditor" "InputNodeChannelSorting" (itm as string)
		)		
		
		on chk_scriptCodeAutoCheck changed state do 
		(
			scriptCodeAutoCheck = state
			KrakatoaChannelNodeEditor_Rollout.createNodeTree init:false
		)
		
		on btn_disconnectFromTrack pressed do
		(
			local q = querybox "Are you sure you want to Disconnect the Input Node from the Scene Parameter?" title:"Disconnect From Scene Parameter"
			if q then
			(
				case ddl_ValueType.selected of
				(
					"Integer":
					(
						theTrack = execute ("trackViewNodes.KrakatoaChannelEditor.KCE_"+KrakatoaChannelNodeEditor_CurrentModifier.trackID+".Input_"+KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][4][4])
						if classof theTrack[1].controller == Float_List then
						(
							theTrack[1].controller[2].controller = bezier_float()
							theTrack[1].weight=#(100,0)
						)
						else
							theTrack[1].controller = bezier_float()
						KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][4][17] = undefined
					)
					"Float":
					(
						theTrack = execute ("trackViewNodes.KrakatoaChannelEditor.KCE_"+KrakatoaChannelNodeEditor_CurrentModifier.trackID+".Input_"+KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][4][4])
						if classof theTrack[2].controller == Float_List then
						(
							theTrack[2].controller[2].controller = bezier_float()
							theTrack[2].weight=#(100,0)
						)
						else
							theTrack[2].controller = bezier_float()
						KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][4][18] = undefined
					)				
					"Vector":
					(
						theTrack = execute ("trackViewNodes.KrakatoaChannelEditor.KCE_"+KrakatoaChannelNodeEditor_CurrentModifier.trackID+".Input_"+KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][4][4])
						if classof theTrack[3].controller == Point3_List then
						(
							theTrack[3].weight=#(100,0)
							theTrack[3][2].controller[1].controller = bezier_float()
							theTrack[3][2].controller[2].controller = bezier_float()
							theTrack[3][2].controller[3].controller = bezier_float()
						)
						else
						(
							theTrack[3][1].controller = bezier_float()
							theTrack[3][2].controller = bezier_float()
							theTrack[3][3].controller = bezier_float()
						)
						KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][4][19] = undefined
					)				
				)
				KrakatoaChannelNodeEditor_Rollout.createNodeTree init:false
				updateControls()
			)
		)		
			
		on btn_connectToSceneTrack pressed do
		(
			local theInt = 0
			theInt = bit.set theInt 10 true --hide sound track
			theInt = bit.set theInt 13 true --show hidden nodes
			theInt = bit.set theInt 27 true --focus on first selected node
			
			case ddl_ValueType.selected of
			(
				"Integer":
				(
					theTVP = trackView.pickTrackDlg float_filter_function options:theInt
					if theTVP != undefined do
					(
						local theController = theTVP.anim
						if not ((classof (superclassof theTVP.anim))==MAXWrapper) do theTVP.client[theTVP.subNum].controller = bezier_float()
						local theTrack = execute ("trackViewNodes.KrakatoaChannelEditor.KCE_"+KrakatoaChannelNodeEditor_CurrentModifier.trackID+".Input_"+KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][4][4])
						local theFloatScript = float_script()
						theFloatScript.AddTarget "KCE_Reference" theController
						theFloatScript.SetExpression "KCE_Reference" 
						if classof theTrack[1].controller == Float_List then
						(
							theTrack[1].controller[2].controller = theFloatScript
							theTrack[1].weight=#(0,100)
						)
						else
						(
							try
							(
								theTrack[1].controller = theFloatScript
							)
							catch
							(
								messagebox "A bug in 3ds Max 2011 prevented this feature from working.\n\nTry to Copy and Paste the Krakatoa Channels Modifier,\nthen delete the original and use the pasted one as a workaround." title:"ERROR"
							)
						)
						--KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][4][17]=
						KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][4][17] = (exprForMAXObject (theFloatScript.GetTarget "KCE_Reference") explicitNames:true)
						KrakatoaChannelNodeEditor_Rollout.updateNodeDependencies()
					)
				)
				"Float":
				(
					theTVP = trackView.pickTrackDlg float_filter_function options:theInt
					if theTVP != undefined do
					(
						local theController = theTVP.anim
						if not ((classof (superclassof theTVP.anim))==MAXWrapper) do theTVP.client[theTVP.subNum].controller = bezier_float()
						
						local theTrack = execute ("trackViewNodes.KrakatoaChannelEditor.KCE_"+KrakatoaChannelNodeEditor_CurrentModifier.trackID+".Input_"+KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][4][4])
						local theFloatScript = float_script()
						theFloatScript.AddTarget "KCE_Reference" theController
						theFloatScript.SetExpression "KCE_Reference" 
						if classof theTrack[2].controller == Float_List then
						(
							theTrack[2].controller[2].controller = theFloatScript
							theTrack[2].weight=#(0,100)
						)
						else
						(
							try
							(
								theTrack[2].controller = theFloatScript
							)
							catch
							(
								messagebox "A bug in 3ds Max 2011 prevented this feature from working.\n\nTry to Copy and Paste the Krakatoa Channels Modifier,\nthen delete the original and use the pasted one as a workaround." title:"ERROR"
							)
						)
						KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][4][18] = (exprForMAXObject (theFloatScript.GetTarget "KCE_Reference") explicitNames:true)
						KrakatoaChannelNodeEditor_Rollout.updateNodeDependencies()
					)
				)				
				"Vector":
				(
					theTVP = trackView.pickTrackDlg point3_filter_function options:theInt
					
					if theTVP != undefined do
					(
						local theController = theTVP.anim
						--if not ((classof (superclassof theTVP.anim))==MAXWrapper) do theTVP.client[theTVP.subNum].controller = position_xyz()
						
						local theTrack = execute ("trackViewNodes.KrakatoaChannelEditor.KCE_"+KrakatoaChannelNodeEditor_CurrentModifier.trackID+".Input_"+KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][4][4]+".Vector.controller")
						local theFloatScriptX = float_script()
						theFloatScriptX.AddTarget "KCE_Reference" theController
						theFloatScriptX.SetExpression "KCE_Reference.x" 
						
						if classof theTrack == Point3_List then
						(
							theTrack[2].controller = Point3_XYZ()
							theTrack[2].controller[1].controller = theFloatScriptX
							theTrack.weight=#(0,100)
						)
						else
						(
							try
							(
								theTrack[1].controller = theFloatScriptX
							)catch(messagebox "A bug in 3ds Max 2011 prevented this feature from working.\n\nTry to Copy and Paste the Krakatoa Channels Modifier,\nthen delete the original and use the pasted one as a workaround." title:"ERROR")
						)
						KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][4][19] = (exprForMAXObject (theFloatScriptX.GetTarget "KCE_Reference") explicitNames:true)
						
						local theFloatScriptY = float_script()
						theFloatScriptY.AddTarget "KCE_Reference" theController
						theFloatScriptY.SetExpression "KCE_Reference.y" 
						if classof theTrack == Point3_List then
						(
							theTrack[2].controller[2].controller = theFloatScriptY
						)
						else
						(
							try
							(
								theTrack[2].controller = theFloatScriptY
							)catch(messagebox "A bug in 3ds Max 2011 prevented this feature from working.\n\nTry to Copy and Paste the Krakatoa Channels Modifier,\nthen delete the original and use the pasted one as a workaround." title:"ERROR")
						)
						
						local theFloatScriptZ = float_script()
						theFloatScriptZ.AddTarget "KCE_Reference" theController
						theFloatScriptZ.SetExpression "KCE_Reference.z" 
						
						if classof theTrack == Point3_List then
						(
							theTrack[2].controller[3].controller  = theFloatScriptZ
						)
						else
						(
							try
							(
								theTrack[3].controller = theFloatScriptZ
							)catch(messagebox "A bug in 3ds Max 2011 prevented this feature from working.\n\nTry to Copy and Paste the Krakatoa Channels Modifier,\nthen delete the original and use the pasted one as a workaround." title:"ERROR")
						)
						
						try(KrakatoaChannelNodeEditor_Rollout.updateNodeDependencies())catch()
					)
				)				
			)
			KrakatoaChannelNodeEditor_Rollout.createNodeTree init:false
			updateControls()
			if KrakatoaChannelNodeEditor_Rollout.chk_autoUpdateModifier.checked do KrakatoaChannelsEditor_Functions.updateParentModifier()
		)
		
		on btn_zoomTrackView pressed do
		(
			try
			(
				trackView.open "Krakatoa MagmaFlow Editor Tracks"
				trackviews.current.rootTrack = execute "trackViewNodes.KrakatoaChannelEditor"
				trackviews.zoomOn "Krakatoa MagmaFlow Editor Tracks" (execute KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][3][3]) ddl_ValueType.selection
			)catch()	
		)			
		
		on edt_scriptCode entered txt do
		(
			theString = KrakatoaChannelsEditor_Functions.purifyTextScript txt			
			KrakatoaChannelEditor_LastError = #(0,"","")
			KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][3][2] = KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][4][6] = theString
			KrakatoaChannelNodeEditor_Rollout.createNodeTree init:false
			try
			(
				local theVal = execute theString
				if classof theVal == Integer or classof theVal == Float or classof theVal  == Point3 or classof theVal == color then
				(
					KrakatoaChannelNodeEditor_Rollout.createUndoRecord ("Script Expression Changed.")
				)	
				else
					throw "Invalid Type"
			)catch(KrakatoaChannelNodeEditor_Rollout.lbx_log.items = append KrakatoaChannelNodeEditor_Rollout.lbx_log.items (localtime +": ERROR in Script Expression:" + getCurrentException() ))	
			if KrakatoaChannelNodeEditor_Rollout.chk_autoUpdateModifier.checked do KrakatoaChannelsEditor_Functions.updateParentModifier()
			edt_scriptCode.text = theString
		)
		/*
		on  edt_scriptCode entered txt do
		(
			edt_scriptCode.text = KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][3][2]
		)
		*/
		on btn_getTextureMap pressed do
		(
			local theMap = materialBrowseDlg #maps
			if theMap != undefined and findItem KrakatoaChannelNodeEditor_CurrentModifier.TextureMapSources theMap == 0 do 
			(
				append KrakatoaChannelNodeEditor_CurrentModifier.TextureMapSources theMap
				KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][3][2]  = KrakatoaChannelNodeEditor_CurrentModifier.TextureMapSources.count + 1
				updateControls()
				KrakatoaChannelNodeEditor_Rollout.createNodeTree init:false
				if KrakatoaChannelNodeEditor_Rollout.chk_autoUpdateModifier.checked do KrakatoaChannelsEditor_Functions.updateParentModifier()				
			)	
		)
		
		on ddl_TextureOutput selected itm do 
		(
			KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][3][3] = (#("Color","Mono","Perturb"))[itm]
			KrakatoaChannelNodeEditor_Rollout.createNodeTree init:false
			KrakatoaChannelNodeEditor_Rollout.createUndoRecord ("Texture Output Changed To ["+ KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][3][3]  +"]")	
			if KrakatoaChannelNodeEditor_Rollout.chk_autoUpdateModifier.checked do KrakatoaChannelsEditor_Functions.updateParentModifier()				
			updateControls()
		)		
		
		on btn_putMaterialToEditor pressed do
		(
			if ddl_ValueType.selection > 1 do 
			(
				medit.PutMtlToMtlEditor KrakatoaChannelNodeEditor_CurrentModifier.TextureMapSources[ddl_ValueType.selection-1] (medit.GetActiveMtlSlot())
			)	
		)		
		
		on btn_removeTextureMap pressed do
		(
			local theIndex = ddl_ValueType.selection
			if theIndex > 1 do 
			(
				deleteItem KrakatoaChannelNodeEditor_CurrentModifier.TextureMapSources (theIndex-1)
				for i = 2 to KrakatoaChannelEditor_DisplayNodeTreeData.count where KrakatoaChannelEditor_DisplayNodeTreeData[i][3][1] == "TextureMap" do
				(
					if KrakatoaChannelEditor_DisplayNodeTreeData[i][3][2] == theIndex then
						KrakatoaChannelEditor_DisplayNodeTreeData[i][3][2]  = 1 
					else if KrakatoaChannelEditor_DisplayNodeTreeData[i][3][2] > theIndex do KrakatoaChannelEditor_DisplayNodeTreeData[i][3][2] -= 1
				)
				updateControls()
				KrakatoaChannelNodeEditor_Rollout.createNodeTree init:false
				if KrakatoaChannelNodeEditor_Rollout.chk_autoUpdateModifier.checked do KrakatoaChannelsEditor_Functions.updateParentModifier()
			)
		)
		
		on edt_ChannelName entered txt do
		(
			txt = KrakatoaChannelsEditor_Functions.purifyChannelName txt
			KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][4][9] = KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][3][2] = txt
			updateControls()
			KrakatoaChannelNodeEditor_Rollout.createNodeTree init:false
			KrakatoaChannelNodeEditor_Rollout.createUndoRecord ("Enter Channel Name ["+ txt +"]")
			if KrakatoaChannelNodeEditor_Rollout.chk_autoUpdateModifier.checked do KrakatoaChannelsEditor_Functions.updateParentModifier()
			edt_ChannelName.text = txt
		)
		on spn_valueInt changed val do
		(
			KrakatoaChannelNodeEditor_Rollout.createNodeTree init:false
			if KrakatoaChannelNodeEditor_Rollout.chk_autoUpdateModifier.checked do KrakatoaChannelsEditor_Functions.updateParentModifier()
			if DebugModeOn do KrakatoaChannelNodeEditor_Rollout.debugFlow()
		)		
		on spn_valueInt entered do
		(
			storeValues()
			KrakatoaChannelNodeEditor_Rollout.createUndoRecord ("Integer Value [" + spn_valueInt.value as string + "]")
			if DebugModeOn do KrakatoaChannelNodeEditor_Rollout.debugFlow()
		)
		
		on spn_value changed val do
		(
			KrakatoaChannelNodeEditor_Rollout.createNodeTree init:false
			if KrakatoaChannelNodeEditor_Rollout.chk_autoUpdateModifier.checked do KrakatoaChannelsEditor_Functions.updateParentModifier()
			if DebugModeOn do KrakatoaChannelNodeEditor_Rollout.debugFlow()
		)
		on spn_value entered do
		(
			storeValues()
			KrakatoaChannelNodeEditor_Rollout.createUndoRecord ("Float Value [" + spn_value.value as string + "]")
			if DebugModeOn do KrakatoaChannelNodeEditor_Rollout.debugFlow()
		)		
		
		on spn_x changed val do
		(
			clr_color.color.r = val*255
			clr_colorComplementary.color = white - clr_color.color
			KrakatoaChannelNodeEditor_Rollout.createNodeTree init:false
			if KrakatoaChannelNodeEditor_Rollout.chk_autoUpdateModifier.checked do KrakatoaChannelsEditor_Functions.updateParentModifier()
			if DebugModeOn do KrakatoaChannelNodeEditor_Rollout.debugFlow()
		)
		on spn_x entered do
		(
			storeValues()
			KrakatoaChannelNodeEditor_Rollout.createUndoRecord ("Vector X Value [" + spn_x.value as string + "]")
			if DebugModeOn do KrakatoaChannelNodeEditor_Rollout.debugFlow()
		)			
		
		on spn_y changed val do
		(
			clr_color.color.g = val*255
			clr_colorComplementary.color = white - clr_color.color
			KrakatoaChannelNodeEditor_Rollout.createNodeTree init:false
			if KrakatoaChannelNodeEditor_Rollout.chk_autoUpdateModifier.checked do KrakatoaChannelsEditor_Functions.updateParentModifier()
			if DebugModeOn do KrakatoaChannelNodeEditor_Rollout.debugFlow()
		)
		on spn_y entered do
		(
			storeValues()
			KrakatoaChannelNodeEditor_Rollout.createUndoRecord ("Vector Y Value [" + spn_y.value as string + "]")
			if DebugModeOn do KrakatoaChannelNodeEditor_Rollout.debugFlow()
		)			
		
		on spn_z changed val do
		(
			clr_color.color.b = val*255
			clr_colorComplementary.color = white - clr_color.color
			KrakatoaChannelNodeEditor_Rollout.createNodeTree init:false
			if KrakatoaChannelNodeEditor_Rollout.chk_autoUpdateModifier.checked do KrakatoaChannelsEditor_Functions.updateParentModifier()
			if DebugModeOn do KrakatoaChannelNodeEditor_Rollout.debugFlow()
		)	
		on spn_z entered do
		(
			storeValues()
			KrakatoaChannelNodeEditor_Rollout.createUndoRecord ("Vector Z Value [" + spn_z.value as string + "]")
			if DebugModeOn do KrakatoaChannelNodeEditor_Rollout.debugFlow()
		)			
		
		on clr_color changed val do
		(
			spn_x.value = clr_color.color.r/255.0
			spn_y.value = clr_color.color.g/255.0
			spn_z.value = clr_color.color.b/255.0
			clr_colorComplementary.color = white - clr_color.color
			storeValues()
			KrakatoaChannelNodeEditor_Rollout.createNodeTree init:false
			KrakatoaChannelNodeEditor_Rollout.createUndoRecord ("Color ["+ (val as Point3) as string + "]")
			if KrakatoaChannelNodeEditor_Rollout.chk_autoUpdateModifier.checked do KrakatoaChannelsEditor_Functions.updateParentModifier()
			if DebugModeOn do KrakatoaChannelNodeEditor_Rollout.debugFlow()
		)
		
		on clr_colorComplementary changed val do
		(
			clr_color.color = white - val
			spn_x.value = clr_color.color.r/255.0
			spn_y.value = clr_color.color.g/255.0
			spn_z.value = clr_color.color.b/255.0
			storeValues()
			KrakatoaChannelNodeEditor_Rollout.createNodeTree init:false
			KrakatoaChannelNodeEditor_Rollout.createUndoRecord ("Color ["+ (clr_color.color as Point3) as string + "]")
			if KrakatoaChannelNodeEditor_Rollout.chk_autoUpdateModifier.checked do KrakatoaChannelsEditor_Functions.updateParentModifier()
			if DebugModeOn do KrakatoaChannelNodeEditor_Rollout.debugFlow()
		)		

		on ddl_InputType selected itm do 
		(
			KrakatoaChannelEditor_LastError = #(0,"","")
			KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][3][1] = ddl_InputType.selected
			KrakatoaChannelsEditor_Functions.fixFlowIDsAfterLoading KrakatoaChannelEditor_DisplayNodeTreeData
			if itm == 2 do createControllers()
			updateControls()
			try(KrakatoaChannelNodeEditor_NodeNameRollout.edt_nodeName.text = KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][4][8] = ddl_ValueType.selected)catch()
			case ddl_InputType.selected of
			(
				"Script": KrakatoaChannelNodeEditor_NodeNameRollout.edt_nodeName.text = KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][4][8] = "Script"
				"TextureMap": KrakatoaChannelNodeEditor_NodeNameRollout.edt_nodeName.text = KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][4][8] = "Map"
				"Geometry": KrakatoaChannelNodeEditor_NodeNameRollout.edt_nodeName.text = KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][4][8] = "Geometry"
				default: ()
			)	
			
			KrakatoaChannelNodeEditor_Rollout.createNodeTree init:false
			KrakatoaChannelNodeEditor_Rollout.createUndoRecord ("Input Type [" + ddl_InputType.selected + "]")
			if KrakatoaChannelNodeEditor_Rollout.chk_autoUpdateModifier.checked do KrakatoaChannelsEditor_Functions.updateParentModifier()
			setFocus KrakatoaChannelNodeEditor_Rollout.hc
			if DebugModeOn do KrakatoaChannelNodeEditor_Rollout.debugFlow()
		)	

		fn ddl_ValueType_SelectedFN itm =
		(

			KrakatoaChannelEditor_LastError = #(0,"","")
			case ddl_InputType.selected of
			(
				"TextureMap":
				(
					KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][3][2] = ddl_ValueType.selection
					local theIndex = ddl_TextureOutput.selection
					if theIndex == 0 do theIndex = 1
					KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][3][3] = (#("Color","Mono","Perturb"))[theIndex]
					KrakatoaChannelNodeEditor_NodeNameRollout.edt_nodeName.text = KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][4][8] = "Map"
					updateControls()
					KrakatoaChannelNodeEditor_Rollout.createNodeTree init:false
					KrakatoaChannelNodeEditor_Rollout.createUndoRecord ("Set TextureMap to [" + ddl_ValueType.selected + "]")
					if KrakatoaChannelNodeEditor_Rollout.chk_autoUpdateModifier.checked do KrakatoaChannelsEditor_Functions.updateParentModifier()
					setFocus KrakatoaChannelNodeEditor_Rollout.hc
				)
				"Channel":
				(
					if itm > 1 then
					(
						KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][3][2] = KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][4][9] = KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][4][8] = ddl_ValueType.selected
						updateControls()
						KrakatoaChannelNodeEditor_Rollout.createNodeTree init:false
						KrakatoaChannelNodeEditor_Rollout.createUndoRecord ("Channel [" + ddl_ValueType.selected + "]")
						if KrakatoaChannelNodeEditor_Rollout.chk_autoUpdateModifier.checked do KrakatoaChannelsEditor_Functions.updateParentModifier()
						setFocus KrakatoaChannelNodeEditor_Rollout.hc		
						edt_ChannelName.visible = false
						theVal = execute (getIniSetting (Krakatoa_PresetsDirectory+"\\Krakatoa_MagmaFlowInputChannelsUsageHistory.ini") "UsageHistory" ddl_ValueType.selected)
						if theVal == OK do theVal = 0
						theVal += 1
						setIniSetting (Krakatoa_PresetsDirectory+"\\Krakatoa_MagmaFlowInputChannelsUsageHistory.ini") "UsageHistory" ddl_ValueType.selected (theVal as string)
						updateControls()
					)	
					else
					(
						edt_ChannelName.visible = true
						edt_ChannelName.text = KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][4][9] = KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][3][2] = "<enter name here>"
						updateControls()
						--ddl_ValueType.selection = findItem ddl_ValueType.items KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][3][2]
					)	
				)
				default:
				(
					KrakatoaChannelNodeEditor_NodeNameRollout.edt_nodeName.text = KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][3][2] = KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][4][8] = ddl_ValueType.selected
					updateControls()
					KrakatoaChannelNodeEditor_Rollout.createNodeTree init:false
					KrakatoaChannelNodeEditor_Rollout.createUndoRecord ("Value Type [" + ddl_ValueType.selected + "]")
					if KrakatoaChannelNodeEditor_Rollout.chk_autoUpdateModifier.checked do KrakatoaChannelsEditor_Functions.updateParentModifier()
					setFocus KrakatoaChannelNodeEditor_Rollout.hc
				)	
			)
			if DebugModeOn do KrakatoaChannelNodeEditor_Rollout.debugFlow()
		)
		
		on ddl_ValueType selected itm do 
		(
			ddl_ValueType_SelectedFN itm
		)	
		
		on btn_sameChannelAsOutput pressed do
		(
			local theIndex = findItem  ddl_ValueType.items KrakatoaChannelEditor_DisplayNodeTreeData[1][3][1]
			if theIndex > 0 do
			(
				ddl_ValueType_SelectedFN (ddl_ValueType.selection = theIndex)
			)
--			KrakatoaChannelNodeEditor_Rollout.createNodeTree init:true
			--KrakatoaChannelNodeEditor_Rollout.createUndoRecord ("Same Input Channel As Output: " + KrakatoaChannelEditor_DisplayNodeTreeData[1][3][1])		
			--KrakatoaChannelNodeEditor_Rollout.displaySelectedNodeProperties()	
			--if KrakatoaChannelNodeEditor_Rollout.chk_autoUpdateModifier.checked do KrakatoaChannelsEditor_Functions.updateParentModifier()	
		)		
		
		fn updateIcons =
		(
			--try(btn_moveToUsed.images = #(Krakatoa_PresetsArrowBitmap,Krakatoa_PresetsArrowBitmap, 32,16,16,18,18))catch()
			--try(btn_moveToAvailable.images = #(Krakatoa_PresetsArrowBitmap,Krakatoa_PresetsArrowBitmap, 32,15,15,17,17))catch()
		)		
		
		on KrakatoaChannelNodeEditor_InputRollout open do
		(
			if classof thePreviewBitmap != bitmap do thePreviewBitmap = bitmap 150 150
			if classof thePreviewBlankBitmap != bitmap  do thePreviewBlankBitmap = bitmap 150 150 color:(white*0.72)

			KrakatoaChannelsEditor_Functions.loadChannelsList mode:#input
			ddl_InputType.selection = findItem ddl_InputType.items KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][3][1]
			local theVal = execute (getIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "ParticleChannelEditor" "InputNodeChannelSorting" )
			if theVal == OK do theVal = 1
			ddl_sortingOptions.selection = theVal
			updateControls()
			updateIcons()
		)
	)
	
	
	
	
	rollout KrakatoaChannelNodeEditor_OutputRollout "Output" category:100
	(
		label lbl_channelName "Channel Name:" align:#left offset:[-10,-5]
		edittext edt_ChannelName fieldwidth:160 align:#center offset:[-1,-3]
		label lbl_isUsedByKrakatoa "" align:#center offset:[0,-3]
		listbox ddl_ChannelType "Standard Channel Names:" items:#() width:160 align:#center
		listbox ddl_ChannelData "Data Type:" items:#() height:4 width:100 align:#left across:2 offset:[-10,0]
		listbox ddl_ChannelArity "Arity:" items:#("1","2","3","4") height:4 width:60 align:#right offset:[10,0]
		
		
		dropdownlist ddl_sortingOptions "Channel List Sorting:" items:#("Factory Default Order","By Usage Frequency","Alphabetical","Alphabetical, Mapping Last","Int>Float>Vector>Quat","Integers Only","Floats Only","Vectors Only","Quaternions Only","PRT Hair Channels Only","Frost Channels Only","FumeFX Channels Only") offset:[0,0] width:160 height:20 align:#center
		
		fn getChannelDataAndArity =
		(
			local theName = KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][3][1]
			local theType = KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][3][2]
			local theArity = KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][3][3]
			
			if classof KrakatoaChannelNodeEditor_CurrentModifier == MagmaHolder then
			(
				ddl_ChannelData.items = #("float16","float32")
				ddl_ChannelArity.enabled = false
				ddl_ChannelArity.selection = 3
				KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][3][1] = edt_ChannelName.text = "RenderElement"
				edt_ChannelName.enabled = false
				ddl_ChannelType.visible = false
				ddl_sortingOptions.visible = false
			)
			else 
			(
				ddl_ChannelType.visible = true
				edt_ChannelName.enabled = true
				ddl_sortingOptions.visible = true
				if findItem ddl_ChannelType.items theName == 0 then --custom channel!
				(
					ddl_ChannelData.items = #("float16","float32","int8","int16","int32","uint8","uint16","uint32")
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
			ddl_ChannelData.selection = findItem ddl_ChannelData.items theType			
			ddl_ChannelArity.selection = findItem ddl_ChannelArity.items (theArity as string)
		)
		
		fn updateDataDepth =
		(
			KrakatoaChannelEditor_LastError = #(0,"","")
			KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][3][2] = ddl_ChannelData.selected
			KrakatoaChannelNodeEditor_Rollout.createNodeTree init:false
			--if KrakatoaChannelNodeEditor_Rollout.chk_autoUpdateModifier.checked do KrakatoaChannelsEditor_Functions.updateParentModifier()
		)
		
		fn updateDataArity =
		(
			KrakatoaChannelEditor_LastError = #(0,"","")
			if try(KrakatoaChannelNodeEditor_CurrentModifier.isRenderElement)catch(false) then
				KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][3][3] = 3
			else
				KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][3][3] = execute ddl_ChannelArity.selected
			KrakatoaChannelNodeEditor_Rollout.createNodeTree init:false
			--if KrakatoaChannelNodeEditor_Rollout.chk_autoUpdateModifier.checked do KrakatoaChannelsEditor_Functions.updateParentModifier()
		)
		
		fn updateSelection =
		(
			local theVal = execute (getIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "ParticleChannelEditor" "OutputNodeChannelSorting" )
			if theVal == OK do theVal = 1
			ddl_sortingOptions.selection = theVal
			
			ddl_ChannelType.items  = KrakatoaChannelsEditor_Functions.getSortedChannelsList ddl_sortingOptions.selection includeCustom:false nodeType:#output
			local theIndex = findItem ddl_ChannelType.items KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][3][1]
			ddl_ChannelType.selection = theIndex
			getChannelDataAndArity()
		)
		
		fn getUsedByRendererState =
		(
			if classof KrakatoaChannelNodeEditor_CurrentModifier != MagmaHolder then
			(
				if renderers.current.classid as string == "#(-1204370534, -399920359)" or renderers.current.classid as string == "#(3090596762L, 3895046937L)" do --if Krakatoa is the Renderer
				(
					try(
						Krakatoa_GUI_Channels.updateMemChannels()
						lbl_isUsedByKrakatoa.text = if (for i in Krakatoa_GUI_Channels.activeMemChannels where matchPattern i[1] pattern:edt_ChannelName.text collect i).count == 1 then
							"Will Be Stored In PCache" 
						else 
							"Not Cacheable"
					)catch(lbl_isUsedByKrakatoa.text = "")	
				)
			)
			else
				lbl_isUsedByKrakatoa.text = "Will Output As Render Element"
		)
		
		on ddl_sortingOptions selected itm do
		(
			setIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "ParticleChannelEditor" "OutputNodeChannelSorting" (itm as string)
			updateSelection()
			getUsedByRendererState()
		)				
		
		on edt_ChannelName entered txt do
		(
			txt = KrakatoaChannelsEditor_Functions.purifyChannelName txt
			local theIndex = findItem ddl_ChannelType.items txt
			if theIndex > 0 then
			(
				KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][3] = for i = 1 to 3 collect sortedChannelsList[theIndex][i]
			)
			else
				KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][3][1] = txt
			
			updateSelection()
			KrakatoaChannelNodeEditor_Rollout.createUndoRecord ("Enter Output Channel Name ["+ txt +"]")
			KrakatoaChannelNodeEditor_Rollout.createNodeTree init:false
			if KrakatoaChannelNodeEditor_Rollout.chk_autoUpdateModifier.checked do KrakatoaChannelsEditor_Functions.updateParentModifier()
			edt_ChannelName.text = txt
			getUsedByRendererState()
			if DebugModeOn do KrakatoaChannelNodeEditor_Rollout.debugFlow()
		)
		
		on ddl_ChannelType selected itm do
		(
			KrakatoaChannelEditor_LastError = #(0,"","")
			edt_ChannelName.text = ddl_ChannelType.selected
			local theTypeArray = for i = 1 to 3 collect sortedChannelsList[itm][i]
			if classof KrakatoaChannelNodeEditor_CurrentModifier == MagmaHolder do 
			(
				theTypeArray[2] = "float16"
				theTypeArray[3] = 3
			)
			KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][3] = deepCopy theTypeArray

			theVal = execute (getIniSetting (Krakatoa_PresetsDirectory+"\\Krakatoa_MagmaFlowOutputChannelsUsageHistory.ini") "UsageHistory" ddl_ChannelType.selected)
			if theVal == OK do theVal = 0
			theVal += 1
			setIniSetting (Krakatoa_PresetsDirectory+"\\Krakatoa_MagmaFlowOutputChannelsUsageHistory.ini") "UsageHistory" ddl_ChannelType.selected (theVal as string)
				
			updateSelection()
			getUsedByRendererState()
			getChannelDataAndArity()
			KrakatoaChannelNodeEditor_Rollout.createUndoRecord ("Output Channel Name ["+ ddl_ChannelType.selected +"]")
			KrakatoaChannelNodeEditor_Rollout.createNodeTree init:false
			if KrakatoaChannelNodeEditor_Rollout.chk_autoUpdateModifier.checked do KrakatoaChannelsEditor_Functions.updateParentModifier()
			if DebugModeOn do KrakatoaChannelNodeEditor_Rollout.debugFlow()
		)
		
		on ddl_ChannelData selected itm do
		(
			updateDataDepth()
			KrakatoaChannelNodeEditor_Rollout.createUndoRecord ("Output Channel Data ["+ddl_ChannelData.selected + "]")
			if KrakatoaChannelNodeEditor_Rollout.chk_autoUpdateModifier.checked do KrakatoaChannelsEditor_Functions.updateParentModifier()
			if DebugModeOn do KrakatoaChannelNodeEditor_Rollout.debugFlow()
		)
		
		on ddl_ChannelArity selected itm do
		(
			updateDataArity()
			KrakatoaChannelNodeEditor_Rollout.createUndoRecord ("Output Channel Arity ["+ddl_ChannelArity.selected + "]")
			if KrakatoaChannelNodeEditor_Rollout.chk_autoUpdateModifier.checked do KrakatoaChannelsEditor_Functions.updateParentModifier()
			if DebugModeOn do KrakatoaChannelNodeEditor_Rollout.debugFlow()
		)		
		
		on KrakatoaChannelNodeEditor_OutputRollout open do
		(
			KrakatoaChannelsEditor_Functions.loadChannelsList mode:#output
			edt_ChannelName.text = KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][3][1]
			ddl_ChannelType.items  = KrakatoaChannelsEditor_Functions.getSortedChannelsList ddl_sortingOptions.selection includeCustom:false
			updateSelection()
			getUsedByRendererState()
		)
	)
	
	rollout KrakatoaChannelNodeEditor_SurfDataValueOperatorRollout "Surface Data Value" category:110
	(
		local theDataTypes = #("Position","Valid","SignedDistance","FaceNormal","MeshIndex","FaceIndex","FaceMatID","SmoothGroup","BaryCoords","TextureCoord") --"SmoothNormal",
		local theValueTypes =#(#vector, #integer, #float, 		#vector, 		#integer, 		#integer, 	#integer, 	#integer, 	#vector, #vector)
		dropdownlist ddl_SurfDataValue "Surface Data Value:" items:#("Position (World Vector)","Valid (Integer)","SignedDistance (Float)","FaceNormal (World Vector)","MeshIndex (Integer)","FaceIndex (Integer)","FaceMatID (Integer)","SmoothGroup (Integer)","BaryCoords (Vector)","TextureCoord (Vector)") align:#center height:20 width:162 

		button btn_convertToFloat "Convert To Float" width:160 pos:[3,50] tooltip:"Insert a ToFloat Operator to convert the Input value to a Floating Point value."
		button btn_convertToVector "Convert To Vector" width:160 pos:[3,50] tooltip:"Insert a ToVector Operator to convert the Input value to a Vector value."
		button btn_convertVectorX "Extract X" width:53 pos:[3,50] tooltip:"Insert a ToScalar Operator with second Input socket set to 1 to extract the X component of the Vector value."
		button btn_convertVectorY "Extract Y" width:53 pos:[57,50] tooltip:"Insert a ToScalar Operator with second Input socket set to 2 to extract the Y component of the Vector value."
		button btn_convertVectorZ "Extract Z" width:53 pos:[111,50] tooltip:"Insert a ToScalar Operator with second Input socket set to 3 to extract the Z component of the Vector value."
		
		button btn_transformFromWorld "From World" width:80 pos:[3,74] tooltip:"Insert a FromWorld Operator to transform the Vector from world to object space."
		button btn_transformToView "To View" width:80 pos:[84,74] tooltip:"Insert a ToView Operator to transform the Vector to view space."
		
		fn updateButtonVisibility =
		(
			case theValueTypes[ddl_SurfDataValue.selection] of
			(
				#vector: (
					btn_convertToFloat.visible = btn_convertToVector.visible = false
					btn_transformFromWorld.visible = btn_transformToView.visible = btn_convertVectorX.visible = btn_convertVectorY.visible = btn_convertVectorZ.visible = true
				)
				#float: (
					btn_convertToFloat.visible = false
					btn_convertToVector.visible = true
					btn_transformFromWorld.visible = btn_transformToView.visible = btn_convertVectorX.visible = btn_convertVectorY.visible = btn_convertVectorZ.visible = false
				)
				#integer: (
					btn_convertToFloat.visible = true
					btn_convertToVector.visible = false
					btn_transformFromWorld.visible = btn_transformToView.visible = btn_convertVectorX.visible = btn_convertVectorY.visible = btn_convertVectorZ.visible = false
				)
				
			)
		)

		on btn_convertToFloat pressed do
		(
			local oldNode = KrakatoaChannelNodeEditor_Rollout.lastNodeClick
			KrakatoaChannelNodeEditor_Rollout.addNewOperator type:"ToFloat" creationType:#keyboard	 selectNewNode:false makeUndoRecord:false
			for i = 1 to KrakatoaChannelEditor_DisplayNodeTreeData.count-1 where i != oldNode do
			(
				for j = 1 to KrakatoaChannelEditor_DisplayNodeTreeData[i][2].count do
					if KrakatoaChannelEditor_DisplayNodeTreeData[i][2][j] == oldNode do 
						KrakatoaChannelEditor_DisplayNodeTreeData[i][2][j] = KrakatoaChannelEditor_DisplayNodeTreeData.count
			)
			KrakatoaChannelNodeEditor_Rollout.createNodeTree init:true
			if AutoReorderToggle do KrakatoaChannelNodeEditor_Rollout.autoReorderFlow createUndo:false
			if AutoZoomExtents do KrakatoaChannelNodeEditor_Rollout.zoomExtents createUndo:false
			KrakatoaChannelNodeEditor_Rollout.createUndoRecord ("Integer To Float Conversion")	
			KrakatoaChannelNodeEditor_Rollout.displaySelectedNodeProperties()
			if KrakatoaChannelNodeEditor_Rollout.chk_autoUpdateModifier.checked do KrakatoaChannelsEditor_Functions.updateParentModifier()
		)
		
		on btn_convertToVector pressed do
		(
			local oldNode = KrakatoaChannelNodeEditor_Rollout.lastNodeClick
			KrakatoaChannelNodeEditor_Rollout.addNewOperator type:"ToVector" creationType:#keyboard selectNewNode:false makeUndoRecord:false
			for i = 1 to KrakatoaChannelEditor_DisplayNodeTreeData.count-1 where i != oldNode do
			(
				for j = 1 to KrakatoaChannelEditor_DisplayNodeTreeData[i][2].count do
					if KrakatoaChannelEditor_DisplayNodeTreeData[i][2][j] == oldNode do 
						KrakatoaChannelEditor_DisplayNodeTreeData[i][2][j] = KrakatoaChannelEditor_DisplayNodeTreeData.count
			)
			KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelEditor_DisplayNodeTreeData.count][2] = #(oldNode,oldNode,oldNode)
			KrakatoaChannelNodeEditor_Rollout.createNodeTree init:true
			if AutoReorderToggle do KrakatoaChannelNodeEditor_Rollout.autoReorderFlow createUndo:false
			if AutoZoomExtents do KrakatoaChannelNodeEditor_Rollout.zoomExtents createUndo:false
			KrakatoaChannelNodeEditor_Rollout.createUndoRecord ("Float To Vector Conversion")	
			KrakatoaChannelNodeEditor_Rollout.displaySelectedNodeProperties()
			if KrakatoaChannelNodeEditor_Rollout.chk_autoUpdateModifier.checked do KrakatoaChannelsEditor_Functions.updateParentModifier()
		)
		
		fn convertVectorToScalar component undoName=
		(
			local oldNode = KrakatoaChannelNodeEditor_Rollout.lastNodeClick
			KrakatoaChannelNodeEditor_Rollout.addNewOperator type:"ToScalar" creationType:#keyboard selectNewNode:true makeUndoRecord:false
			for i = 1 to KrakatoaChannelEditor_DisplayNodeTreeData.count-1 where i != oldNode do
			(
				for j = 1 to KrakatoaChannelEditor_DisplayNodeTreeData[i][2].count do
					if KrakatoaChannelEditor_DisplayNodeTreeData[i][2][j] == oldNode do 
						KrakatoaChannelEditor_DisplayNodeTreeData[i][2][j] = KrakatoaChannelEditor_DisplayNodeTreeData.count
			)
			KrakatoaChannelNodeEditor_Rollout.addNewInput type:#value valueType:#integer creationType:#keyboard defaultValue:component makeUndoRecord:false
			KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelEditor_DisplayNodeTreeData.count][4][3] = false
			KrakatoaChannelEditor_DisplayNodeTreeData[oldNode][4][3] = true
			
			KrakatoaChannelNodeEditor_Rollout.createNodeTree init:true
			if AutoReorderToggle do KrakatoaChannelNodeEditor_Rollout.autoReorderFlow createUndo:false
			if AutoZoomExtents do KrakatoaChannelNodeEditor_Rollout.zoomExtents createUndo:false
				
			KrakatoaChannelNodeEditor_Rollout.createUndoRecord (undoName)		
			if KrakatoaChannelNodeEditor_Rollout.chk_autoUpdateModifier.checked do KrakatoaChannelsEditor_Functions.updateParentModifier()
			
			KrakatoaChannelNodeEditor_Rollout.lastNodeClick = oldNode	
			KrakatoaChannelNodeEditor_Rollout.setSelectedNodes #(oldNode)	
			KrakatoaChannelNodeEditor_Rollout.displaySelectedNodeProperties()			
		)
		
		fn transformVectorTo theType:"ToWorld" =
		(
			local oldNode = KrakatoaChannelNodeEditor_Rollout.lastNodeClick
			KrakatoaChannelNodeEditor_Rollout.addNewOperator type:theType creationType:#keyboard selectNewNode:false makeUndoRecord:false
			local theNewIndex = KrakatoaChannelEditor_DisplayNodeTreeData.count
			
			for i = 1 to KrakatoaChannelEditor_DisplayNodeTreeData.count-1 where i != oldNode do
			(
				for j = 1 to KrakatoaChannelEditor_DisplayNodeTreeData[i][2].count do
					if KrakatoaChannelEditor_DisplayNodeTreeData[i][2][j] == oldNode do 
						KrakatoaChannelEditor_DisplayNodeTreeData[i][2][j] = theNewIndex
			)
			KrakatoaChannelEditor_DisplayNodeTreeData[theNewIndex][4][9] = KrakatoaChannelEditor_DisplayNodeTreeData[theNewIndex][3][2] = "Point"
			local theOldType = KrakatoaChannelEditor_DisplayNodeTreeData[oldNode][3][2]
			if (findItem #("FaceNormal") theOldType > 0 ) do
				KrakatoaChannelEditor_DisplayNodeTreeData[theNewIndex][4][9] = KrakatoaChannelEditor_DisplayNodeTreeData[theNewIndex][3][2] = "Normal"
			
			if (findItem #("BaryCoords", "TextureCoord") theOldType > 0)  do
				KrakatoaChannelEditor_DisplayNodeTreeData[theNewIndex][4][9] = KrakatoaChannelEditor_DisplayNodeTreeData[theNewIndex][3][2] = "Vector"
			
			KrakatoaChannelNodeEditor_Rollout.createNodeTree init:true
			KrakatoaChannelNodeEditor_Rollout.setSelectedNodes #(oldNode)	
			KrakatoaChannelNodeEditor_Rollout.createUndoRecord ("Insert Transform " + theType)		
			KrakatoaChannelNodeEditor_Rollout.displaySelectedNodeProperties()			
			if KrakatoaChannelNodeEditor_Rollout.chk_autoUpdateModifier.checked do KrakatoaChannelsEditor_Functions.updateParentModifier()			
		)
		

		
		on btn_transformFromWorld pressed do
		(
			transformVectorTo theType:"FromWorld"
		)
			
		on  btn_transformToView pressed do
		(
			transformVectorTo theType:"ToView"
		)
		
		on btn_convertVectorX pressed do
		(
			convertVectorToScalar 1 "Vector To Component 1 Conversion"
		)
		on btn_convertVectorY pressed do
		(
			convertVectorToScalar 2 "Vector To Component 2 Conversion"
		)
		on btn_convertVectorZ pressed do
		(
			convertVectorToScalar 3 "Vector To Component 3 Conversion"
		)		
		
		
		on ddl_SurfDataValue selected itm do
		(
			KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][3][2] = theDataTypes[itm]
			if KrakatoaChannelNodeEditor_Rollout.chk_autoUpdateModifier.checked do KrakatoaChannelsEditor_Functions.updateParentModifier()
			KrakatoaChannelNodeEditor_Rollout.createNodeTree init:false			
			KrakatoaChannelNodeEditor_Rollout.createUndoRecord ("Changed SurfDataValue To [" + ddl_SurfDataValue.selected + "]")
			if DebugModeOn do KrakatoaChannelNodeEditor_Rollout.debugFlow()
			updateButtonVisibility()
		)
		on KrakatoaChannelNodeEditor_SurfDataValueOperatorRollout open do
		(
			local theIndex = findItem theDataTypes KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][3][2]
			if theIndex == 0 do 
			(
				theIndex = 1
				KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][3][2] = theDataTypes[1]
			)
			ddl_SurfDataValue.selection = theIndex
			updateButtonVisibility()
		)
	)
	
	rollout KrakatoaChannelNodeEditor_ObjectPropertyRollout "Object Property" category:110
	(
		dropdownlist ddl_propertyList "Standard Properties:" items:#() align:#center width:160
		edittext edt_propertyString width:162 align:#center offset:[-3,-3]
		
		fn getAllProperties =
		(
			local theProperties = #("[Custom]")
			local theInputIndex = KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][2][1]
			if theInputIndex != undefined and theInputIndex > 0 do
			(
				local theNodeName = KrakatoaChannelEditor_DisplayNodeTreeData[theInputIndex][3][2]
				if theNodeName != undefined do 
				(
					local theNode = getNodeByName theNodeName
					if isValidNode theNode do
					(
						for p in getPropNames theNode do append theProperties (p as string)
					)
				)
			)
			ddl_propertyList.items = theProperties
		)
	
		on ddl_propertyList selected itm do
		(
			if itm == 1 then
				KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][3][2] = edt_propertyString.text
			else
				KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][3][2] = edt_propertyString.text = ddl_propertyList.selected
			KrakatoaChannelNodeEditor_Rollout.createNodeTree init:false	
		)
		
		on edt_propertyString entered txt do
		(
			KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][3][2] = txt
			local theIndex = findItem ddl_propertyList.items KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][3][2] 
			if theIndex == 0 do theIndex = 1
			ddl_propertyList.selection = theIndex
			KrakatoaChannelNodeEditor_Rollout.createNodeTree init:false	
		)
		
		on KrakatoaChannelNodeEditor_ObjectPropertyRollout open do
		(
			ddl_propertyList.items = getAllProperties()
			
			local theIndex = findItem ddl_propertyList.items KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][3][2]
			if theIndex == 0 do 
			(
				theIndex = 1
				if KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][3][2] == undefined do 
					KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][3][2] = ""
			)
			ddl_propertyList.selection = theIndex
			edt_propertyString.text = KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][3][2]
		)
	)	
	
	rollout KrakatoaChannelNodeEditor_TransformationOperatorsRollout "Transformation" category:110
	(
		dropdownlist ddl_transformMode "Transform Mode:" items:#("Point","Vector","Normal") align:#center width:160
		pickbutton pck_referenceNode "Pick Reference Node..." align:#center width:160 enabled:false
		button btn_removeNodeReference "Remove Reference Node" align:#center width:160 enabled:false
		
		fn updateSceneObjectName =
		(
			local theName = KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][4][10] 
			if isValidNode (getNodeByName (theName as string)) then 
				KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][3][3] = pck_referenceNode.caption = theName 
			else			
			(
				pck_referenceNode.caption ="Pick Reference Node..."
				KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][3][3] = ""
			)	
			case KrakatoaChannelNodeEditor_OperatorRollout.ddl_type.selected of 
			(
				"ToWorld": (try(deleteItem KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][3] 3)catch())
				"FromWorld": (try(deleteItem KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][3] 3)catch())
				"ToView": (try(deleteItem KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][3] 3)catch())
				"FromView": (try(deleteItem KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][3] 3)catch())
				default: ()
			)
		)
		
		on KrakatoaChannelNodeEditor_TransformationOperatorsRollout open do
		(
			KrakatoaChannelsEditor_Functions.loadChannelsList mode:#input
			local theIndex = findItem ddl_transformMode.items KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][4][9]
			if theIndex == 0 do theIndex = 1
			KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][3][2] = KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][4][9] =  ddl_transformMode.items[theIndex]
			ddl_transformMode.selection = theIndex
			pck_referenceNode.enabled = btn_removeNodeReference.enabled = KrakatoaChannelNodeEditor_OperatorRollout.ddl_type.selection > 2 and KrakatoaChannelNodeEditor_OperatorRollout.ddl_type.selection < 5 
			updateSceneObjectName()
		)
		
		on btn_removeNodeReference pressed do
		(
			KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][3][3] = KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][4][10] = ""
			pck_referenceNode.caption = "Pick Reference Node..."
			if KrakatoaChannelNodeEditor_Rollout.chk_autoUpdateModifier.checked do KrakatoaChannelsEditor_Functions.updateParentModifier()
			KrakatoaChannelNodeEditor_Rollout.createNodeTree init:false			
			KrakatoaChannelNodeEditor_Rollout.createUndoRecord ("Removed Reference Node")
			if DebugModeOn do KrakatoaChannelNodeEditor_Rollout.debugFlow()
		)
		
		on ddl_transformMode selected itm do
		(
			KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][3][2] = KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][4][9] = ddl_transformMode.selected
			if KrakatoaChannelNodeEditor_Rollout.chk_autoUpdateModifier.checked do KrakatoaChannelsEditor_Functions.updateParentModifier()
			KrakatoaChannelNodeEditor_Rollout.createNodeTree init:false			
			KrakatoaChannelNodeEditor_Rollout.createUndoRecord ("Changed Transform Mode To [" + ddl_transformMode.selected + "]")
			if DebugModeOn do KrakatoaChannelNodeEditor_Rollout.debugFlow()
		)
		
		on pck_referenceNode picked obj do
		(
			if obj != undefined do
			(
				pck_referenceNode.caption = KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][4][10] = KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][3][3] = obj.name
				if KrakatoaChannelNodeEditor_Rollout.chk_autoUpdateModifier.checked do KrakatoaChannelsEditor_Functions.updateParentModifier()
				KrakatoaChannelNodeEditor_Rollout.createNodeTree init:false	
				KrakatoaChannelNodeEditor_Rollout.createUndoRecord ("Picked Reference Node [" + obj.name+"]")
				if DebugModeOn do KrakatoaChannelNodeEditor_Rollout.debugFlow()
			)
		)
	)

	rollout KrakatoaChannelNodeEditor_OperatorRollout "Operator" category:100
	(
		
		local theListDefs = #(
			#("Add","Subtract","Multiply","Divide","Power","SquareRoot","Modulo","AbsoluteValue","Floor","Ceil","Negate","Logarithm"), 
			#("Blend","Clamp","Curve","Noise","DNoise"),
			#("Magnitude","Normalize","ComponentSum","DotProduct","CrossProduct"),
			#("Sin","Cos","Tan","ASin","ACos","ATan","ATan2"),
			#("ToVector","ToScalar","ToFloat","ToInteger","FromQuat","ToQuat"), --,"Property"),
			#("ToWorld","FromWorld","ToSpace","FromSpace","ToView","FromView","TransformByQuat"),
			#("NearestPoint","RayIntersect","SurfDataValue"),
			#("LogicalAnd","LogicalOr","LogicalNot","Less","LessOrEqual","Greater","GreaterOrEqual","Equal","Switch")
		)		
		
		--label lbl_nodeName "Node Name:" align:#left offset:[-8,0]

		group "Operator Settings:"
		(
			dropdownlist ddl_category "Operator Category:" items:#("Arithmetic","Function","Vector","Trigonometry","Conversion","Transformation","Surface","Logic and Comparison") width:150 align:#center
			dropdownlist ddl_type "Operation Type:" width:150 align:#center height:20
			button btn_convertToFloat "Convert To Float" visible:false align:#center width:150
		)
		
		fn updateType =
		(
			KrakatoaChannelNodeEditor_Rollout.createNodeTree init:true
			KrakatoaChannelNodeEditor_OperatorDescriptionRollout.updateDescription()
			KrakatoaChannelNodeEditor_Rollout.setSelectedNodes #(KrakatoaChannelNodeEditor_Rollout.lastNodeClick)
			case ddl_category.selected of 
			(
				default: (
					try(deleteItem KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][3] 3)catch()
					if ddl_type.selected != "Curve" and ddl_type.selected != "Property" do
						try(deleteItem KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][3] 2)catch()
				)	
				"Transformation" : (
						if findItem #("ToWorld","FromWorld","ToView","FromView") KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][3][1] > 0 do
							try(deleteItem KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][3] 3)catch()
				)
				"Surface" : (
						try(deleteItem KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][3] 3)catch()
				)
			)
			btn_convertToFloat.visible = ddl_category.selected == "Logic and Comparison" and ddl_type.selected != "Switch"
			
			setFocus KrakatoaChannelNodeEditor_Rollout.hc			
		)
		
		fn updateCategories =
		(
			--KrakatoaChannelEditor_LastError = #(0,"","")
			--print "updateCategories"
			ddl_type.selection = 1
			for i = 1 to theListDefs.count do 
			(
				local theIndex = findItem theListDefs[i] KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][3][1]
				if theIndex > 0 do
				(
					ddl_category.selection = i
					ddl_type.items = theListDefs[i]			
					ddl_type.selection = theIndex
					--print theIndex
					exit
				)
			)	

			updateType()
		)	
		
		fn updateSubRollouts =
		(
			try(removeSubRollout KrakatoaChannelNodeEditor_Rollout.NodePropsSR KrakatoaChannelNodeEditor_TransformationOperatorsRollout)catch()
			try(removeSubRollout KrakatoaChannelNodeEditor_Rollout.NodePropsSR KrakatoaChannelNodeEditor_CurveControl)catch()
			try(removeSubRollout KrakatoaChannelNodeEditor_Rollout.NodePropsSR KrakatoaChannelNodeEditor_SurfDataValueOperatorRollout)catch()
			try(removeSubRollout KrakatoaChannelNodeEditor_Rollout.NodePropsSR KrakatoaChannelNodeEditor_ObjectPropertyRollout)catch()
			
			if ddl_category.selected == "Transformation" do
				addSubRollout KrakatoaChannelNodeEditor_Rollout.NodePropsSR KrakatoaChannelNodeEditor_TransformationOperatorsRollout
			if ddl_type.selected == "Curve" do
				addSubRollout KrakatoaChannelNodeEditor_Rollout.NodePropsSR KrakatoaChannelNodeEditor_CurveControl
			if ddl_type.selected == "SurfDataValue" do
				addSubRollout KrakatoaChannelNodeEditor_Rollout.NodePropsSR KrakatoaChannelNodeEditor_SurfDataValueOperatorRollout
			if ddl_type.selected == "Property" do
				addSubRollout KrakatoaChannelNodeEditor_Rollout.NodePropsSR KrakatoaChannelNodeEditor_ObjectPropertyRollout
		)
		
		on btn_convertToFloat pressed do
		(
			local oldNode = KrakatoaChannelNodeEditor_Rollout.lastNodeClick
			KrakatoaChannelNodeEditor_Rollout.addNewOperator type:"ToFloat" creationType:#keyboard	 selectNewNode:false makeUndoRecord:false
			for i = 1 to KrakatoaChannelEditor_DisplayNodeTreeData.count-1 where i != oldNode do
			(
				for j = 1 to KrakatoaChannelEditor_DisplayNodeTreeData[i][2].count do
					if KrakatoaChannelEditor_DisplayNodeTreeData[i][2][j] == oldNode do 
						KrakatoaChannelEditor_DisplayNodeTreeData[i][2][j] = KrakatoaChannelEditor_DisplayNodeTreeData.count
			)
			KrakatoaChannelNodeEditor_Rollout.createNodeTree init:true
			if AutoReorderToggle do KrakatoaChannelNodeEditor_Rollout.autoReorderFlow createUndo:false
			if AutoZoomExtents do KrakatoaChannelNodeEditor_Rollout.zoomExtents createUndo:false
			KrakatoaChannelNodeEditor_Rollout.createUndoRecord ("Integer To Float Conversion")	
			KrakatoaChannelNodeEditor_Rollout.displaySelectedNodeProperties()
			if KrakatoaChannelNodeEditor_Rollout.chk_autoUpdateModifier.checked do KrakatoaChannelsEditor_Functions.updateParentModifier()
		)
		
		on ddl_type selected itm do
		(
			KrakatoaChannelEditor_LastError = #(0,"","")
			if ddl_type.selected != undefined do
				KrakatoaChannelNodeEditor_NodeNameRollout.edt_nodeName.text = KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][3][1] = KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][4][8] = ddl_type.selected
			updateType()
			if KrakatoaChannelNodeEditor_Rollout.chk_autoUpdateModifier.checked do KrakatoaChannelsEditor_Functions.updateParentModifier()
			updateSubRollouts()
			KrakatoaChannelNodeEditor_Rollout.createUndoRecord "Change Operator Output Type"			
			if DebugModeOn do KrakatoaChannelNodeEditor_Rollout.debugFlow()
		)		
		
		on ddl_category selected itm do
		(
			KrakatoaChannelEditor_LastError = #(0,"","")
			ddl_type.items = theListDefs[itm]	
			--if ddl_type.selection > ddl_type.items.count do 
			ddl_type.selection = 1
			if ddl_type.selected != undefined do
				KrakatoaChannelNodeEditor_NodeNameRollout.edt_nodeName.text = KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][3][1] = KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][4][8] = ddl_type.selected			
			updateSubRollouts()
			updateType()
			KrakatoaChannelNodeEditor_Rollout.createUndoRecord "Change Operator Category"			
			if DebugModeOn do KrakatoaChannelNodeEditor_Rollout.debugFlow()
		)		
		
		on KrakatoaChannelNodeEditor_OperatorRollout open do
		(
			updateCategories()
			updateSubRollouts()
			KrakatoaChannelNodeEditor_OperatorDescriptionRollout.updateDescription()
		)
	)	
	
	rollout KrakatoaChannelNodeEditor_ConnectorRollout "BlackOp Connector"
	(
		label lbl_socketName "Socket Name:" align:#left offset:[-10,-3]
		edittext edt_socketName align:#center fieldwidth:160 offset:[-2,-3]
		
		on edt_socketName entered txt do
		(
			txt = KrakatoaChannelsEditor_Functions.purifyText txt
			KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][3][1] = txt
			KrakatoaChannelNodeEditor_Rollout.createNodeTree init:false
			edt_socketName.text = txt
		)
		
		on KrakatoaChannelNodeEditor_ConnectorRollout open do
		(
			edt_socketName.text = KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][3][1]
		)
	)
	
	rollout KrakatoaChannelNodeEditor_OutputConnectorRollout "BlackOp Output Connector"
	(
		--label lbl_socketName "No Properties Exposed Yet." align:#center --offset:[-10,-3]
		
		button btn_loadFromDisk "Load Definition From Disk..." align:#center width:160 height:25
		button btn_saveToDisk "Save Definition To Disk..." align:#center width:160 height:25
		button btn_exploreFolders "Explore BlackOp Folders..." align:#center width:160 height:25 
		button btn_exitEditing "EXIT BLACKOP EDITING..." align:#center width:160 height:35 offset:[0,5]
		
		on btn_exitEditing pressed do KrakatoaChannelsEditor_Functions.endEditingBLOP()

		on btn_saveToDisk pressed do
		(
			KrakatoaChannelEditor_DisableDragAndDrop = false
			makeDir (Krakatoa_PresetsDirectory+ "\\BlackOps") all:true
			local theFileName = getSaveFileName caption:"Save BlackOp Definition" filename:(Krakatoa_PresetsDirectory+ "\\BlackOps\\"+currentlyEditedBlackOpName) types:"Krakatoa Channels BlackOp (*.KCB)|*.KCB"
			if theFileName != undefined do
			(
				KrakatoaChannelEditor_BLOPArray = deepCopy KrakatoaChannelEditor_DisplayNodeTreeData
				for i = 1 to KrakatoaChannelEditor_BLOPArray.count do
				(
					if KrakatoaChannelEditor_BLOPArray[i][3][1] == "Script" do KrakatoaChannelEditor_BLOPArray[i][3][2] = KrakatoaChannelEditor_BLOPArray[i][4][6] = (KrakatoaChannelsEditor_Functions.escapeString KrakatoaChannelEditor_BLOPArray[i][4][6])
					if KrakatoaChannelEditor_BLOPArray[i][1] == "Input"  and KrakatoaChannelEditor_BLOPArray[i][3][3]  != undefined do deleteItem KrakatoaChannelEditor_BLOPArray[i][3] 3
				)
				local theFileHandle = createFile theFileName
				with PrintAllElements true	format "global KrakatoaChannelEditor_BlackOpData = %\n" KrakatoaChannelEditor_BLOPArray to:theFileHandle 
				close theFileHandle
				KrakatoaChannelEditor_BlackOpData = execute ( with PrintAllElements true KrakatoaChannelEditor_BLOPArray as string)
			)	
		)
		
		on btn_loadFromDisk pressed do
		(
			KrakatoaChannelEditor_DisableDragAndDrop = false
			local theFileName = getOpenFileName caption:"Load BlackOp Definition" filename:(Krakatoa_PresetsDirectory+ "\\BlackOps\\"+currentlyEditedBlackOpName) types:"Krakatoa Channels BlackOp (*.KCB)|*.KCB"
			if theFileName != undefined do
			(
				fileIn theFileName
				local theBLOPDef = deepcopy KrakatoaChannelEditor_BlackOpData
				KrakatoaChannelsEditor_Functions.fixFlowIDsAfterLoading theBLOPDef
				--KrakatoaChannelNodeEditor_NodeNameRollout.edt_nodeName.text = KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][4][8] = getFileNameFile theFileName
				KrakatoaChannelEditor_DisplayNodeTreeData = deepCopy theBLOPDef 
				KrakatoaChannelNodeEditor_Rollout.createNodeTree init:true
				if AutoReorderToggle do KrakatoaChannelNodeEditor_Rollout.autoReorderFlow createUndo:false
				if AutoZoomExtents do KrakatoaChannelNodeEditor_Rollout.zoomExtents createUndo:false	
				KrakatoaChannelNodeEditor_Rollout.createUndoRecord ("Load BlackOp Definition From File")
			)	
		)
		
		on btn_exploreFolders pressed do
		(
			shellLaunch (Krakatoa_PresetsDirectory+ "\\BlackOps\\") ""
		)		
	)	
	
	rollout KrakatoaChannelNodeEditor_BlackOpsRollout "BlackOp" category:100
	(
		local theConnectorNames = #()
		local theConnectorIndices = #()

		button btn_loadFromDisk "Load Definition From Disk..." align:#center width:160
		listbox lbx_inputConnections "Input Names:" align:#left width:140 offset:[-10,0]
		edittext edt_ConnectionName align:#center width:162 offset:[-2,-5]
		button btn_saveToDisk "Save Definition To Disk..." align:#center width:160
		button btn_exploreFolders "Explore BlackOp Folders..." align:#center width:160
		button btn_reorderUp "Up" width:20 height:65 align:#right offset:[10,-210] tooltip:"Move selected Input up in the list. Holding Control will not move the connection with it."
		button btn_reorderDown "Dn" width:20 height:65 align:#right offset:[10,0] tooltip:"Move selected Input down in the list. Holding Control will not move the connection with it."
		
		fn updateList =
		(
			local theNode = KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick]
			
			theConnectorNames = #()
			theConnectorIndices = #()
			
			for i = 1 to theNode[3][2].count where theNode[3][2][i][1] == "Connector" do
			(
				append theConnectorNames theNode[3][2][i][3][1]
				append theConnectorIndices i
			)
			lbx_inputConnections.items = theConnectorNames			
		)		
		
		on btn_reorderUp pressed do
		(
			local oldSelection = lbx_inputConnections.selection 
			if oldSelection > 1 do
			(
				local prevIndex = theConnectorIndices[oldSelection - 1]
				local theIndex = theConnectorIndices[oldSelection]
				local theNode = KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][3][2][prevIndex]
				KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][3][2][prevIndex]=KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][3][2][theIndex]
				KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][3][2][theIndex ] = theNode
				for i = 1 to KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][3][2].count do
				(
					for j = 1 to KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][3][2][i][2].count do
					(
						if KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][3][2][i][2][j] == theIndex then 
							KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][3][2][i][2][j] = prevIndex
						else if KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][3][2][i][2][j] == prevIndex do KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][3][2][i][2][j] = theIndex
					)
				)
				if not keyboard.ControlPressed then
				(
					local temp = KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][2][oldSelection - 1]
					KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][2][oldSelection - 1] = KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][2][oldSelection]
					KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][2][oldSelection] = temp
				)else if KrakatoaChannelNodeEditor_Rollout.chk_autoUpdateModifier.checked do KrakatoaChannelsEditor_Functions.updateParentModifier()
				updateList()
				lbx_inputConnections.selection = oldSelection - 1
				KrakatoaChannelNodeEditor_Rollout.createNodeTree init:true
				KrakatoaChannelNodeEditor_Rollout.createUndoRecord ("BlackOp Connector ["+ lbx_inputConnections.selected +"] Up.")
			)
		)
		
		on btn_reorderDown pressed do
		(
			local oldSelection = lbx_inputConnections.selection 
			if oldSelection < lbx_inputConnections.items.count do
			(
				local prevIndex = theConnectorIndices[lbx_inputConnections.selection+1]
				local theIndex = theConnectorIndices[lbx_inputConnections.selection]	
				
				local theNode= KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][3][2][prevIndex]
				KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][3][2][prevIndex]=KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][3][2][theIndex]
				KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][3][2][theIndex ] = theNode
				for i = 1 to KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][3][2].count do
				(
					for j = 1 to KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][3][2][i][2].count do
					(
						if KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][3][2][i][2][j] == theIndex then
							KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][3][2][i][2][j] = prevIndex
						else if KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][3][2][i][2][j] == prevIndex do KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][3][2][i][2][j] = theIndex
					)
				)
				if not keyboard.ControlPressed then
				(
					local temp = KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][2][oldSelection + 1]
					KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][2][oldSelection + 1] = KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][2][oldSelection]
					KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][2][oldSelection] = temp
				)	
				else if KrakatoaChannelNodeEditor_Rollout.chk_autoUpdateModifier.checked do KrakatoaChannelsEditor_Functions.updateParentModifier()
				updateList()
				lbx_inputConnections.selection = oldSelection + 1
				KrakatoaChannelNodeEditor_Rollout.createNodeTree init:true
				KrakatoaChannelNodeEditor_Rollout.createUndoRecord ("BlackOp Connector ["+ lbx_inputConnections.selected +"] Down.")
				
			)
		)		
		
		on edt_ConnectionName entered txt do
		(
			txt = KrakatoaChannelsEditor_Functions.purifyText txt
			KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][3][2][theConnectorIndices[lbx_inputConnections.selection]][3][1] = theConnectorNames[lbx_inputConnections.selection] = txt
			lbx_inputConnections.items = theConnectorNames
			KrakatoaChannelNodeEditor_Rollout.createNodeTree init:false
			KrakatoaChannelNodeEditor_Rollout.createUndoRecord ("BlackOp Input Name ["+ txt+"]")
			edt_ConnectionName.text = txt
		)
		
		on lbx_inputConnections selected itm do
		(
			edt_ConnectionName.text = lbx_inputConnections.selected
		)
		
		on btn_saveToDisk pressed do
		(
			KrakatoaChannelEditor_DisableDragAndDrop = false
			makeDir (Krakatoa_PresetsDirectory+ "\\BlackOps") all:true
			local theFileName = getSaveFileName caption:"Save BlackOp Definition" filename:(Krakatoa_PresetsDirectory+ "\\BlackOps\\"+KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][4][8]) types:"Krakatoa Channels BlackOp (*.KCB)|*.KCB"
			if theFileName != undefined do
			(
				KrakatoaChannelEditor_BLOPArray = deepCopy KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][3][2]
				for i = 1 to KrakatoaChannelEditor_BLOPArray.count do
				(
					if KrakatoaChannelEditor_BLOPArray[i][3][1] == "Script" do KrakatoaChannelEditor_BLOPArray[i][3][2] = KrakatoaChannelEditor_BLOPArray[i][4][6] = (KrakatoaChannelsEditor_Functions.escapeString KrakatoaChannelEditor_BLOPArray[i][4][6])
					if KrakatoaChannelEditor_BLOPArray[i][1] == "Input"  and KrakatoaChannelEditor_BLOPArray[i][3][3]  != undefined do deleteItem KrakatoaChannelEditor_BLOPArray[i][3] 3
				)
				local theFileHandle = createFile theFileName
				with PrintAllElements true	format "global KrakatoaChannelEditor_BlackOpData = %\n" KrakatoaChannelEditor_BLOPArray to:theFileHandle 
				close theFileHandle
				KrakatoaChannelEditor_BlackOpData = execute ( with PrintAllElements true KrakatoaChannelEditor_BLOPArray as string)
				KrakatoaChannelNodeEditor_Rollout.CreateDepot()
				KrakatoaChannelsEditor_Functions.KrakatoaChannelEditor_UpdateDepot()				
			)	
		)
		
		on btn_loadFromDisk pressed do
		(
			KrakatoaChannelEditor_DisableDragAndDrop = false
			local theFileName = getOpenFileName caption:"Load BlackOp Definition" filename:(Krakatoa_PresetsDirectory+ "\\BlackOps\\"+KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][4][8]) types:"Krakatoa Channels BlackOp (*.KCB)|*.KCB"
			if theFileName != undefined do
			(
				fileIn theFileName
				local theBLOPDef = deepcopy KrakatoaChannelEditor_BlackOpData
				KrakatoaChannelsEditor_Functions.fixFlowIDsAfterLoading theBLOPDef
				KrakatoaChannelNodeEditor_NodeNameRollout.edt_nodeName.text = KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][4][8] = getFileNameFile theFileName
				KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelNodeEditor_Rollout.lastNodeClick][3][2] = deepCopy theBLOPDef 
				KrakatoaChannelNodeEditor_Rollout.createNodeTree init:true
				if AutoReorderToggle do KrakatoaChannelNodeEditor_Rollout.autoReorderFlow createUndo:false
				if AutoZoomExtents do KrakatoaChannelNodeEditor_Rollout.zoomExtents createUndo:false	
				KrakatoaChannelNodeEditor_Rollout.createUndoRecord ("Load BlackOp Definition From File")
				if KrakatoaChannelNodeEditor_Rollout.chk_autoUpdateModifier.checked do KrakatoaChannelsEditor_Functions.updateParentModifier()
			)	
		)
		
		on btn_exploreFolders pressed do
		(
			shellLaunch (Krakatoa_PresetsDirectory+ "\\BlackOps\\") ""
		)
		

		
		on KrakatoaChannelNodeEditor_BlackOpsRollout open do
		(
			updateList()
			if theConnectorNames.count > 0 do
				edt_ConnectionName.text = theConnectorNames[1]
		)
	)
	
	rcmenu KrakatoaChannelNodeEditor_MacroRecorderEditorMenu 
	(
		subMenu "File"
		(
			menuItem mnu_loadMacro "Load Macro From Disk..."
			separator sep_10
			menuItem mnu_saveMacro "Save Macro To Disk..."
		)
		subMenu "Edit"
		(
			menuItem mnu_deleteLine "Delete Selected Line..."
		)
		
		on mnu_loadMacro picked do
		(
			KrakatoaChannelNodeEditor_Rollout.LoadMacroRecording()
		)	
		on mnu_saveMacro picked do
		(
			KrakatoaChannelNodeEditor_Rollout.saveMacroRecording()
		)
		on mnu_deleteLine picked do
		(
			KrakatoaChannelNodeEditor_MacroRecorderEditor.DeleteLineFromMacroRecording()
		)
	)
	
	rollout KrakatoaChannelNodeEditor_MacroRecorderEditor "MagmaFlow: Edit Macro Recording"
	(
		label lbl_title "Pause : Action Description" align:#left 
		listbox lbx_macroRecording width:410 height:19 offset:[-10,-1]
		spinner spn_duration across:2 align:#left fieldwidth:45 offset:[-10,0]
		edittext edt_description fieldwidth:350 align:#right offset:[6,-1]
		
		fn updateUI =
		(
			lbx_macroRecording.items = for i in KrakatoaChannelEditor_MacroRecording collect (i[5] as string + " : " + i[6])
			KrakatoaChannelNodeEditor_MacroRecorderEditor.title = "MagmaFlow: Edit Macro Recording - ["+  getFileNameFile lastMacroFileName + "]"
		)
		
		on edt_description entered txt do
		(
			KrakatoaChannelEditor_MacroRecording[lbx_macroRecording.selection][6] = KrakatoaChannelsEditor_Functions.purifyText txt
			updateUI()
		)
		
		on spn_duration changed val do
		(
			KrakatoaChannelEditor_MacroRecording[lbx_macroRecording.selection][5] = val
			updateUI()
		)
		
		fn updateControls =
		(
			edt_description.text = KrakatoaChannelEditor_MacroRecording[lbx_macroRecording.selection][6] 
			spn_duration.value = KrakatoaChannelEditor_MacroRecording[lbx_macroRecording.selection][5] 
		)
		
		fn DeleteLineFromMacroRecording =
		(
			if (querybox ("DELETE RECORD:\n\nDeleting a line from a Macro Recording cannot be undone - you will have to reload the original Macro.\nAre you sure you want to delete the line\n\n" +  KrakatoaChannelEditor_MacroRecording[lbx_macroRecording.selection][6] +"\n\n") title:"Delete Record?") then
			(
				deleteItem KrakatoaChannelEditor_MacroRecording lbx_macroRecording.selection
				if currentMacroLine > KrakatoaChannelEditor_MacroRecording.count do currentMacroLine = KrakatoaChannelEditor_MacroRecording.count
				lbx_macroRecording.selection = currentMacroLine
			)
			updateUI()
			updateControls()
		)
		
		on lbx_macroRecording selected itm do
		(
			updateControls()
			currentMacroLine = itm
			KrakatoaChannelNodeEditor_Rollout.PlayRecordLine()				
			setFocus lbx_macroRecording
		)
		
		
		on KrakatoaChannelNodeEditor_MacroRecorderEditor open do
		(
			updateUI()
			updateControls()
		)	
	)
	
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--MAIN ROLLOUT--
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
	
	rollout KrakatoaChannelNodeEditor_Rollout "Krakatoa MagamFlow Editor"
	(
		local lastMouseClick = [0,0]
		local lastNodeClick = 0			
		local displaySelectedNodeProperties, autoReorderFlow, zoomExtents
		local theNodeInvisibilityList = #{}
		local dotnetSystemInfo = dotNetClass "System.Windows.Forms.SystemInformation"
		
		KrakatoaSchematicControl hc "" width:800 height:600 pos:[0,0] 
		progressbar prg_bar width:176 height:6 pos:[0,0] color:red value:100
		subRollout NodePropsSR width:180 height:600 pos:[800,0]
		dropdownlist lbx_log width:800 height:10 pos:[0,0]
		
		checkbutton chk_autoUpdateModifier ">AUTO" width:60 height:20  pos:[800,1] 
		button btn_updateModifier "UPDATE" width:118 height:20  pos:[860,1] 
		
		button btn_zoomExtents "ZE" width:25 height:25  pos:[800,580] tooltip:"Zoom Extents; Right-Click To Reset Pan and Zoom"
		button btn_zoomExtentsSelected "ZS" width:25  height:25  pos:[820,580] tooltip:"Zoom Extents Selected; Right-Click To Reset Pan and Zoom"
		button btn_NoZoom "NZ" width:25  height:25  pos:[840,580] tooltip:"Reset Zoom; Right-Click To Reset Pan and Zoom"
		button btn_NoPoom "NP" width:25  height:25  pos:[860,580] tooltip:"Reset Pan; Right-Click To Reset Pan and Zoom"
		
		button btn_Undo "Undo" width:39 height:25 tooltip:"Click to Undo; Right-Click to display Undo History"
		button btn_Redo "Redo" width:39 height:25 tooltip:"Click to Redo; Right-Click to display Redo History"
		
		button btn_RecorderToStart "|<" width:25 height:25 visible:false
		button btn_RecorderBackOneStep "<<" width:25 height:25 visible:false
		checkbutton chk_RecorderPlay "|>"  width:25 height:25 visible:false
		button btn_RecorderForwardOneStep ">>" width:25 height:25 visible:false
		button btn_RecorderToEnd ">|"width:25 height:25 visible:false
		button btn_RecorderClose "Close" width:50 height:25 visible:false
		
		
		
		fn logInfo txt =
		(
			lbx_log.items = #(txt)
			lbx_log.selection = 1
		)
		
		on lbx_log selected itm do
		(
			KrakatoaChannelsEditor_Functions.navigateToErrorModifier()
		)	
		
		fn getSelectedNodes =
		(
			for i = 1 to KrakatoaChannelEditor_DisplayNodeTreeData.Count collect
			(
				hc.activeNode = i	
				if hc.isSelected == true then i else dontcollect
			)
		)
		
		fn getSelectedDepotButton =
		(
			for i = KrakatoaChannelEditor_DisplayNodeTreeData.Count+1 to hc.getNodeCount-1 collect
			(
				hc.activeNode = i
				if hc.isSelected == true then i-KrakatoaChannelEditor_DisplayNodeTreeData.Count else dontcollect
			)
		)
		
		fn getDepotSelection =
		(
			for i = KrakatoaChannelEditor_DisplayNodeTreeData.Count+1 to hc.getNodeCount-1 collect
			(
				hc.activeNode = i
				if hc.isSelected == true then i else dontcollect
			)
		)
		
		fn getUnSelectedNodes =
		(
			for i = 1 to KrakatoaChannelEditor_DisplayNodeTreeData.Count collect
			(
				hc.activeNode = i	
				if hc.isSelected == false then i else dontcollect
			)
		)		
		
		fn setSelectedNodes theSel =
		(
			for i = 1 to KrakatoaChannelEditor_DisplayNodeTreeData.Count do
			(
				hc.activeNode = i	
				hc.isSelected = false
			)			
			try
			(
				for i in theSel where i <= KrakatoaChannelEditor_DisplayNodeTreeData.count do
				(
					hc.activeNode = i	
					hc.isSelected = true
				)
			)catch()
		)
		
		fn setSelectedNodesInData theSel =
		(
			for i = 1 to KrakatoaChannelEditor_DisplayNodeTreeData.Count do
			(
				KrakatoaChannelEditor_DisplayNodeTreeData[i][4][3] = false
			)			
			for i in theSel do
			(
				KrakatoaChannelEditor_DisplayNodeTreeData[i][4][3] = true
			)
		)		
		

		fn updateNodeDependencies = 
		(
			--KrakatoaChannelEditor_LastError = #(0,"","")
			deleteAllChangeHandlers id:#KCE_CurrentModifierSceneParametersMonitor
			local theDepNodes = #()
			local theTabuNodes = refs.dependents KrakatoaChannelNodeEditor_CurrentModifier
			local theRoot = try(execute ("trackViewNodes.KrakatoaChannelEditor.KCE_"+KrakatoaChannelNodeEditor_CurrentModifier.trackID))catch(undefined)
			if theRoot != undefined do
			(
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
								for o in refs.dependents theTarget where classof (superclassof o) == Node and findItem theDepNodes o == 0 and findItem theTabuNodes o == 0 and isProperty o "name" do 
									append theDepNodes o
							)	
						)
					)--end t loop	
				)
				--try(KrakatoaChannelNodeEditor_CurrentModifier.nodeDependencies = theDepNodes)catch()
				
				for i in KrakatoaChannelEditor_DisplayNodeTreeData where i[3][1] == "FromSpace" or i[3][1] == "ToSpace"  do 
				(
					local theNode = try(getNodeByName i[3][3])catch(undefined)
					if isValidNode theNode and findItem theTabuNodes theNode == 0 and findItem theDepNodes theNode == 0 do 
						append theDepNodes theNode
				)
				
				for i in KrakatoaChannelEditor_DisplayNodeTreeData where i[1]=="Input" AND i[3][1] == "Geometry" do 
				(
					for o in i[3][2] do
					(
						local theNode = try(getNodeByName o)catch(undefined)
						if isValidNode theNode and findItem theTabuNodes theNode == 0 and findItem theDepNodes theNode == 0 do 
							append theDepNodes theNode
					)
				)				
				
				for i in KrakatoaChannelEditor_DisplayNodeTreeData where i[3][1] == "Script" do 
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
							if theNode != undefined and findItem theDepNodes theNode == 0 do append theDepNodes theNode
							theNodePathBegin = findString theLine "$" 
						)--end while $ found
					)--end while script reading
				)--end i loop
				
				for o in KrakatoaChannelNodeEditor_CurrentModifier.GeometryObjectsList where isValidNode (theNode=getNodeByName o) and findItem theTabuNodes theNode == 0 and findItem theDepNodes theNode == 0 do append theDepNodes theNode
				
				when parameters theDepNodes change id:#KCE_CurrentModifierSceneParametersMonitor handleAt:#redrawViews do 
					try(if chk_autoUpdateModifier.checked do KrakatoaChannelsEditor_Functions.updateParentModifier())catch()
				--format "%\n" theDepNodes
			)	
		)		
		
		fn getInputSocketColor theNode theSocketIndex =
		(
			if theNode[2][theSocketIndex] == undefined or theNode[2][theSocketIndex] < 1 then
				theInputSocketColor
			else
			(
				local theConnected = KrakatoaChannelEditor_DisplayNodeTreeData[theNode[2][theSocketIndex] ]
				if theConnected != undefined then
				(
					case theConnected[1] of
					(
						default:
						(
							if theConnected[5] == false then 
								theInputSocketColor
							else
							case theConnected[3][1] of
							(
								"Value": 
								(
									case theConnected[3][2] of
									(
										"Integer" : theIntegerSocketColor 
										"Float" : theFloatSocketColor 
										"Vector": theVectorSocketColor 
										default: red
										--"Color":   try(theConnected[3][3]*255)catch(theIntegerSocketColor)
									)											
								)
								"Time" : theTimeSocketColor 
								"Channel" : theChannelSocketColor 
								"TextureMap" : theTextureMapSocketColor
								"Script": theFloatSocketColor
								"Geometry": theObjectSocketColor
								"Object": theObjectSocketColor
								default: red
							)							
						)
						"Operator": theChannelSocketColor
						"BlackOp": theChannelSocketColor
						"Output": theChannelSocketColor
						"Connector": (color 0 255 0)						
					)
				)
				else theInputSocketColor
			)							
		)		
		fn getInputSocketName theNode theSocketIndex =
		(
			--format "%\n" theNode 
			--print theSocketIndex
			local result = "???"
			if theNode[2][theSocketIndex] == undefined or theNode[2][theSocketIndex] < 1 then --UNCONNECTED SOCKETS
			(
				if theNode[1] == "Operator" then
				(
					case theNode[3][1] of 
					(
						"Add": result = if theSocketIndex == 1 then "Vector or Float" else "Vector or Float"
						"Subtract": result = if theSocketIndex == 1 then "Vector or Float" else "Vector or Float"
						"Multiply": result = if theSocketIndex == 1 then "Vector or Float" else "Vector or Float"
						"Divide": result = if theSocketIndex == 1 then "Vector or Float" else "Float"
						"Power": result = if theSocketIndex == 1 then "Vector or Float" else "Float"
						"SquareRoot": result = "Vector or Float"
						"Modulo": result = if theSocketIndex == 1 then "Float" else "Float Divisor"
						"AbsoluteValue": result = "Vector or Float"
						"Floor": result = "Vector or Float"
						"Ceil": result = "Vector or Float"
						"Negate": result = "Vector or Float"
						"Logarithm": result = "Float"
						
						"NearestPoint": result = if theSocketIndex == 1 then "Geometry" else "Position"
						"RayIntersect": result = if theSocketIndex == 1 then "Geometry" else if theSocketIndex == 2 then "Ray Position" else "Ray Direction" 
						"SurfDataValue": result = "DataSet" 
						--"ValidSurfData": result = "DataSet"
						"FromQuat": result = if theSocketIndex == 1 then "Quaternion" else "Axis Index"							
						"ToQuat": result = if theSocketIndex == 1 then "X Axis" else if theSocketIndex == 2 then "Y Axis" else "Z Axis" 
						"Property": result = "Object"
						"Clamp": result = if theSocketIndex == 1 then "Value To Clamp" else if theSocketIndex == 2 then "Min.Limit" else "Max.Limit" 
						"ToVector": result = if theSocketIndex == 1 then "X" else if theSocketIndex == 2 then "Y" else "Z" 
						"ToScalar": result = if theSocketIndex == 1 then "Vector" else "Axis Integer" 
						"ToFloat": result = "Integer"
						"ToInteger": result = "Float"
						"Curve": result = "Float or Vector"
						"Noise" :  result = if theSocketIndex == 1 then "Float or Vector" else if theSocketIndex == 2 then "Octaves Int." else "Persistence Float" 
						"DNoise" :  result = if theSocketIndex == 1 then "Float or Vector" else if theSocketIndex == 2 then "Octaves Int." else "Persistence Float" 
						"Magnitude" : result = "Vector"
						"Normalize" : result = "Vector"
						"ComponentSum" : result = "Vector"
						"DotProduct" :  result = if theSocketIndex == 1 then "Vector 1" else "Vector 2" 
						"CrossProduct" :  result = if theSocketIndex == 1 then "Vector 1" else "Vector 2" 
						"TransformByQuat": result = if theSocketIndex == 1 then "Vector or Quat" else "Quaternion" 
						default: result = "Input " + theSocketIndex as string
					)
				)
				else
					result = "Input " + theSocketIndex as string
			)
			else
			(
				local theConnected = KrakatoaChannelEditor_DisplayNodeTreeData[theNode[2][theSocketIndex] ]
				if theConnected != undefined then
				(
					result= case theConnected[1] of
					(
						"Connector": theConnected[3][1]
						default: theConnected[4][8] as string
						"Input": (
							case theConnected[3][1] of
							(
								default: theConnected[4][8] as string
								"TextureMap": try("[" + (join #("Current") (for i in KrakatoaChannelNodeEditor_CurrentModifier.TextureMapSources collect (classof i) as string))[theConnected[3][2]]+"]")catch("Missing Map")
							)
						)
					)
				)
				else 
					result= "Input " + theSocketIndex as string
			)					
			result
		)			
		
		fn getChannelDataType theChannelName =
		(
			if matchPattern theChannelName pattern:"Index" then
			(
				"int32[1]"
			)
			else
			(
				theIndex = findItem (for i in ChannelsList collect i[1]) theChannelName
				if theIndex == 0 then "[Custom] " else ChannelsList[theIndex][2] + "[" + ChannelsList[theIndex][3] as string + "] "
			)
		)



		local addNewInput, addNewOperator, theDepotNodes, addNewBLOP, updateDepotDefinition
		
		fn collapseDepot =
		(
			if DepotAutoCollapseOnDragAndDrop do
			(
				for j = 1 to KrakatoaChannelEditor_theDepotNodesArray.count where KrakatoaChannelEditor_theDepotNodesArray[j][1][1]  == "HEAD" do
					KrakatoaChannelEditor_theDepotNodesArray[j][1][6] = false	
				updateDepotDefinition()
			)			
		)		
		
		fn createDepot =
		(
			local expandCategories = DepotPlacement != #bottomrollup and DepotPlacement != #bottomrollupreverse
			global KrakatoaChannelEditor_theDepotNodesArray =#(
			#(	
				#("HEAD","&Inp&ut",theHeaderColor,[0,0], "Inputs Group", expandCategories),
				#("IN","Channel",theInputNodeColor,[0,0], #channel, #none),
				#("IN","Vector",theInputNodeColor+[0,20,0],[0,0], #value, #vector),
				#("IN","Float",theInputNodeColor+[-20,20,-20] ,[0,0], #value, #float),
				#("IN","Integer",theInputNodeColor-[0,20,20],[0,0], #value, #integer),
				#("IN","TexMap",theInputNodeColor+ [20,0,-20],[0,0], #textureMap, #none),
				#("IN","Script",theInputNodeColor+ [20,-20,-20],[0,0], #script, #none),
				--#("IN","Object",theInputNodeColor+ [20,-30,-40],[0,0], #object, #none),
				#("IN","Geometry",theInputNodeColor+ [20,-20,-40],[0,0], #geometry, #none),
				#("NT","Notes", theNotesNodeColor, [0,0], #notes, #none)
			),
/*			
			#(	
				#("HEAD","Notes",theHeaderColor,[0,0], "Notes Group", expandCategories),
			),
			*/
			#(
				#("HEAD","&Arithmetic",theHeaderColor,[0,0], "Arithmetic Operators Group", expandCategories),
				#("OP","+ Add",theOperatorNodeColor,[0,0], "Add"),
				#("OP","- Subtract",theOperatorNodeColor,[0,0],  "Subtract"),
				#("OP","* Multiply",theOperatorNodeColor,[0,0] , "Multiply"),
				#("OP","/ Divide",theOperatorNodeColor,[0,0], "Divide"),
				#("OP","^ Power",theOperatorNodeColor,[0,0], "Power"),
				#("OP","SquareRoot",theOperatorNodeColor,[0,0], "SquareRoot"),
				#("OP","Modulo",theOperatorNodeColor,[0,0], "Modulo"),
				#("OP","Absolute",theOperatorNodeColor,[0,0], "AbsoluteValue"),
				#("OP","Floor",theOperatorNodeColor,[0,0], "Floor"),
				#("OP","Ceil",theOperatorNodeColor,[0,0], "Ceil"),
				#("OP","Negate",theOperatorNodeColor,[0,0], "Negate"),
				#("OP","Logarithm", theOperatorNodeColor,[0,0], "Logarithm")
			),
			
			#(
				#("HEAD","&Function",theHeaderColor,[0,0], "Function Operators Group", expandCategories),
				#("OP","Blend",theOperatorNodeColor,[0,0], "Blend"),
				#("OP","Clamp",theOperatorNodeColor,[0,0], "Clamp"),
				#("OP","Curve",theOperatorNodeColor,[0,0], "Curve"),
				#("OP","Noise",theOperatorNodeColor,[0,0], "Noise"),
                #("OP","DNoise",theOperatorNodeColor,[0,0], "DNoise")
			),
			
			#(
				#("HEAD","&Vector",theHeaderColor,[0,0], "Vector Operators Group",expandCategories),
				#("OP","Magnitude",theOperatorNodeColor+[0,10,0],[0,0], "Magnitude"),
				#("OP","Normalize",theOperatorNodeColor+[0,10,0],[0,0], "Normalize"),
				#("OP","CompSum",theOperatorNodeColor+[0,10,0],[0,0], "ComponentSum"),			
				#("OP","Dot",theOperatorNodeColor+[0,10,0],[0,0], "DotProduct"),			
				#("OP","Cross",theOperatorNodeColor+[0,10,0],[0,0], "CrossProduct")
			),

			#(
				#("HEAD","Tri&gonom.",theHeaderColor,[0,0], "Trigonometry Operators Group", expandCategories),
				#("OP","Sin",theOperatorNodeColor+[0,-10,0],[0,0], "Sin"),
				#("OP","Cos",theOperatorNodeColor+[0,-10,0],[0,0], "Cos"),
				#("OP","Tan",theOperatorNodeColor+[0,-10,0],[0,0], "Tan"),
				#("OP","ASin",theOperatorNodeColor+[0,-10,0],[0,0], "ASin"),
				#("OP","ACos",theOperatorNodeColor+[0,-10,0],[0,0], "ACos"),
				#("OP","ATan",theOperatorNodeColor+[0,-10,0],[0,0], "ATan"),
				#("OP","ATan2",theOperatorNodeColor+[0,-10,0],[0,0], "ATan2")
			),
			#(
				#("HEAD","&Convert",theHeaderColor,[0,0], "Conversion Group", expandCategories),
				#("OP","ToVector",theOperatorNodeColor+[-10,-10,10],[0,0], "ToVector"),
				#("OP","ToScalar",theOperatorNodeColor+[-10,-10,10],[0,0], "ToScalar"),
				#("OP","ToFloat",theOperatorNodeColor+[-10,-10,10],[0,0], "ToFloat"),
				#("OP","ToInteger",theOperatorNodeColor+[-10,-10,10],[0,0], "ToInteger"),
				#("OP","FromQuat",theOperatorNodeColor+[-10,-10,10],[0,0], "FromQuat"),
				#("OP","ToQuat",theOperatorNodeColor+[-10,-10,10],[0,0], "ToQuat")
				--#("OP","Property",theOperatorNodeColor+[-10,-10,10],[0,0], "Property")
			),

			#(
				#("HEAD","&Transform",theHeaderColor,[0,0], "Transformation Group", expandCategories),
				#("OP","ToWorld",theOperatorNodeColor+[-10,10,0],[0,0], "ToWorld"),
				#("OP","FromWorld",theOperatorNodeColor+[-10,10,0],[0,0], "FromWorld"),
				#("OP","ToSpace",theOperatorNodeColor+[-10,10,0],[0,0], "ToSpace"),
				#("OP","FromSpace",theOperatorNodeColor+[-10,10,0],[0,0], "FromSpace"),
				#("OP","ToView",theOperatorNodeColor+[-10,10,0],[0,0], "ToView"),
				#("OP","FromView",theOperatorNodeColor+[-10,10,0],[0,0], "FromView"),
				#("OP","TransByQuat",theOperatorNodeColor+[-10,10,0],[0,0], "TransformByQuat")
			),
			
			#(
				#("HEAD","&Surface",theHeaderColor,[0,0], "Surface Group", expandCategories),
				#("OP","Nearest",theOperatorNodeColor+[-10,20,20],[0,0], "NearestPoint"),
				#("OP","Ray Int.",theOperatorNodeColor+[-10,20,20],[0,0], "RayIntersect"),
				#("OP","Surf Data",theOperatorNodeColor+[-10,20,20],[0,0], "SurfDataValue")
				--#("OP","Valid Data",theOperatorNodeColor+[-10,20,20],[0,0], "ValidSurfData")
			),

			#(
				#("HEAD","&Logic",theHeaderColor,[0,0], "Boolean Logic Operators Group", expandCategories),
				#("OP","And",theOperatorNodeColor+[-10,0,10],[0,0], "LogicalAnd"),
				#("OP","Or",theOperatorNodeColor+[-10,0,10],[0,0], "LogicalOr"),
				#("OP","Not",theOperatorNodeColor+[-10,0,10],[0,0], "LogicalNot"),
				#("OP","<",theOperatorNodeColor+[-10,0,10],[0,0], "Less"),
				#("OP","<=",theOperatorNodeColor+[-10,0,10],[0,0], "LessOrEqual"),
				#("OP",">",theOperatorNodeColor+[-10,0,10],[0,0], "Greater"),
				#("OP",">=",theOperatorNodeColor+[-10,0,10],[0,0], "GreaterOrEqual"),
				#("OP","==",theOperatorNodeColor+[-10,0,10],[0,0], "Equal"),
				#("OP","Switch",theOperatorNodeColor+[-10,0,10],[0,0], "Switch")
			),
			
			#(
				#("HEAD","Loaders",theHeaderColor,[0,0], "Loaders Group", expandCategories),
				#("BLOP","BlackOp",theBoxNodeColor,[0,0], "BlackOp")
			)

			)		--end depoth def
			
			if DepotShowBLOPs do
			(
				local theRoot = (Krakatoa_PresetsDirectory+ "\\BlackOps")
				local theDirs = join #(theRoot) (getDirectories (theRoot+"\\*"))
				for d in theDirs do
				(
					local theFiles = getFiles (d+"\\*.kcb")
					if theFiles.count > 0 do
					(
						local theFS = filterString d "\\"
						local theLastDir = theFS[theFS.count]
						append KrakatoaChannelEditor_theDepotNodesArray #(#("HEAD",theLastDir,theHeaderColor,[0,0], ("["+theLastDir +"] BlackOps Folder"), false))
						for f in theFiles do
							append KrakatoaChannelEditor_theDepotNodesArray[KrakatoaChannelEditor_theDepotNodesArray.count] #("UBLOP",(getFileNameFile f),theBoxNodeColor+[-20,-20,0],[0,0], f)			
					)	
				)
			)
			if KrakatoaChannelEditor_NodeTreeEditingLevel.count > 0 do
			(
				append KrakatoaChannelEditor_theDepotNodesArray[1] #("CN","Connector",theOutputNodeColor,[0,0], #value, #connector)
			)
			
			collapseDepot()
		)
		
		fn updateDepotDefinition =
		(
			theDepotNodes = #()
			
			if DepotShowCategories == true then
			(
				for i in KrakatoaChannelEditor_theDepotNodesArray do 
				(
					if i[1][1] == "HEAD" do
						if i[1][6] == true then
							for j = 1 to i.count do append theDepotNodes (deepCopy i[j])
						else
							append theDepotNodes (deepCopy i[1])
				)		
			)
			else
			(
				for i in KrakatoaChannelEditor_theDepotNodesArray do 
					for j = 2 to i.count do append theDepotNodes (deepCopy i[j])
			)	
		)
		
		fn prepareDepotForDragAndDrop =
		(
			if DepotPlacement == #off do return false
			for i = 1 to theDepotNodes.count do
			(
				hc.activeNode = KrakatoaChannelEditor_DisplayNodeTreeData.count+i
				theDepotNodes[i][4] = hc.activeNodePos
			)				
		)
		
		fn drawDepot init:false lock:false =
		(
			if hc.height == undefined do return false --bail out if the helium control is not defined (editor is not open!)
			leftDepotMargin = 0
			if DepotPlacement == #off do return false
				
			if DepotPlacement == #bottom do
			(
				local DepotX = 0
				local theHCount = (hc.width/DepotNodeWidth/hc.zoom) 
				local theVCount = ceil (theDepotNodes.count/theHCount)
				local DepotY = (hc.height-(18+(theVCount*18/hc.zoom)))
			)
			if DepotPlacement == #left do
			(
				local DepotX = 0
				local DepotY = 0
				leftDepotMargin = DepotNodeWidth
			)
			if DepotPlacement == #bottomrollup do
			(
				local DepotX = 0
				local theHCount = KrakatoaChannelEditor_theDepotNodesArray.count
				local ArrayCnt = 1
				local theVCount = if KrakatoaChannelEditor_theDepotNodesArray[ArrayCnt][1][6] then KrakatoaChannelEditor_theDepotNodesArray[ArrayCnt].count else 1
				local DepotY = (hc.height-(18+theVCount*18/hc.zoom))
			)
			if DepotPlacement == #bottomrollupreverse do
			(
				local DepotX = 0
				local theHCount = KrakatoaChannelEditor_theDepotNodesArray.count
				local ArrayCnt = 1
				local theVCount = if KrakatoaChannelEditor_theDepotNodesArray[ArrayCnt][1][6] then KrakatoaChannelEditor_theDepotNodesArray[ArrayCnt].count else 1
				local DepotY = (hc.height-36)
			)			
			for i = 1 to theDepotNodes.count do
			(
				if init do hc.addNode
				hc.activeNode = KrakatoaChannelEditor_DisplayNodeTreeData.count+i
				hc.nodeName = theDepotNodes[i][2]
				hc.nodeColor = theDepotNodes[i][3] * (if theDepotNodes[i][1]=="HEAD" then (if theDepotNodes[i][6] == true then 1.0 else 0) else 1.0)
				hc.nodeSize = [(DepotNodeWidth-2)/hc.zoom,15/hc.zoom]
				hc.nodeCollapsedSize = hc.nodeSize 
				hc.isCollapsible  = false
				try(hc.drawLayer = 3)catch()
				--theDepotNodes[i][4] = hc.activeNodePos
				try
				(
					if lock or theDepotNodes[i][1]=="HEAD" then 
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
				case DepotPlacement of
				(
					#bottom: (
						DepotX += DepotNodeWidth
						if DepotX > hc.width-DepotNodeWidth  do
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
							DepotX += DepotNodeWidth
							leftDepotMargin = depotX+DepotNodeWidth
							DepotY=0
						)
					)	
					#bottomrollup:
					(
						DepotY += 18
						if try(theDepotNodes[i+1][1] == "HEAD")catch(false) do
						(
							DepotX += DepotNodeWidth
							ArrayCnt += 1
							theVCount = if KrakatoaChannelEditor_theDepotNodesArray[ArrayCnt][1][6] then KrakatoaChannelEditor_theDepotNodesArray[ArrayCnt].count else 1
							--format "%  %\n" ArrayCnt theVCount
							DepotY = (hc.height-(18+theVCount*18/hc.zoom))						
						)					
					)	
					#bottomrollupreverse:
					(
						DepotY -= 18
						if try(theDepotNodes[i+1][1] == "HEAD")catch(false) do
						(
							DepotX += DepotNodeWidth
							ArrayCnt += 1
							theVCount = if KrakatoaChannelEditor_theDepotNodesArray[ArrayCnt][1][6] then KrakatoaChannelEditor_theDepotNodesArray[ArrayCnt].count else 1
							--format "%  %\n" ArrayCnt theVCount
							DepotY = (hc.height-36)						
						)					
					)						
				)--end case
			)
			hc.redrawView				
		)
		


		fn getInputCount theNode =
		(
			if findItem #("ToWorld","FromWorld","ToSpace","FromSpace","ToView","FromView","Normalize","Negate","Floor","Ceil","Magnitude","SquareRoot","ComponentSum","AbsoluteValue","Sin","Cos","Tan","ASin","ACos","ATan","ToFloat","ToInteger","LogicalNot","Curve","SurfDataValue","Property","Logarithm") theNode[3][1] > 0 then 1 
			else if findItem #("Add","Subtract","Multiply","Divide","Power","Modulo","FromQuat","ToScalar","DotProduct","CrossProduct","Less","LessOrEqual","Greater","GreaterOrEqual","Equal","LogicalAnd","LogicalOr","TransformByQuat","NearestPoint","ATan2") theNode[3][1]  > 0 then 2 
			else if findItem #("Blend","Clamp","ToQuat","ToVector","Switch","Noise","DNoise","RayIntersect") theNode[3][1] > 0 then 3 
			else if findItem #("BlackOp") theNode[1] > 0 then 
			(
				(for i = 1 to theNode[3][2].count where theNode[3][2][i][1] == "Connector" collect i).count
			)
			else if theNode[1] == "Output" then 1 else 0
		)	
		
		local flagConnectedArray = #{}
		fn FlagConnectedRecursive theParent =
		(
			flagConnectedArray[theParent] = true
			try
			(
				for i in KrakatoaChannelEditor_DisplayNodeTreeData[theParent][2] where i != undefined and i > 0 and i<= KrakatoaChannelEditor_DisplayNodeTreeData.count do
					FlagConnectedRecursive i
			)catch()
		)
		
		fn FlagUnconnectedNodes =
		(
			flagConnectedArray = #{}
			local theRootIndex = 1
			for i = 1 to KrakatoaChannelEditor_DisplayNodeTreeData.count where KrakatoaChannelEditor_DisplayNodeTreeData[i][1] == "Output" or KrakatoaChannelEditor_DisplayNodeTreeData[i][1] == "OutputConnector" do theRootIndex = i
			FlagConnectedRecursive theRootIndex
			for i = 1 to KrakatoaChannelEditor_DisplayNodeTreeData.count do KrakatoaChannelEditor_DisplayNodeTreeData[i][4][7] = flagConnectedArray[i]
		)
		
	
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--DEBUGGING FUNCTIONS		
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

		local debugArray = #()
		local debugChannelsArray = #()		
		
		fn collectDebugArray theCompileFlow outputName:"DebugChannel" outputValue:[1,1,1] graphstep:0.0 =
		(
			append debugArray #(outputName, outputValue)
			append debugChannelsArray outputName
			for i = 2 to theCompileFlow.count do
			(
				if theCompileFlow[i][1] == "Input" and theCompileFlow[i][3][1] == "Channel" do 
				(
					if findItem debugChannelsArray theCompileFlow[i][3][2] == 0 do
					(
						if theCompileFlow[i][4][15] == undefined do theCompileFlow[i][4][15] = #(1.0,1.0,1.0,1.0,1,0.0,0.0,0.0,0.0,1.0,1.0,1.0,1.0,false)
						local theArityArray = for j in channelsList where j[1] == theCompileFlow[i][3][2] collect j[3]
						local theArity = if theArityArray.count == 1 then theArityArray[1] else 1
						local theTypeArray = for j in channelsList where j[1] == theCompileFlow[i][3][2] collect j[2]	
						local theType = if theTypeArray.count == 1 then substring theTypeArray[1] 1 3 else "flo"
							
						if theCompileFlow[i][4][15][14] == true then
						(
							local comp1 = theCompileFlow[i][4][15][6] + (theCompileFlow[i][4][15][10]-theCompileFlow[i][4][15][6])*graphstep
							local comp2 = theCompileFlow[i][4][15][7] + (theCompileFlow[i][4][15][11]-theCompileFlow[i][4][15][7])*graphstep
							local comp3 = theCompileFlow[i][4][15][8] + (theCompileFlow[i][4][15][12]-theCompileFlow[i][4][15][8])*graphstep
							local comp4 = theCompileFlow[i][4][15][9] + (theCompileFlow[i][4][15][13]-theCompileFlow[i][4][15][9])*graphstep
						)
						else
						(
							local comp1 = theCompileFlow[i][4][15][1] 
							local comp2 = theCompileFlow[i][4][15][2] 
							local comp3 = theCompileFlow[i][4][15][3] 
							local comp4 = theCompileFlow[i][4][15][4] 
						)
						
						local theValue = case theArity of
						(
							1: if theType == "flo" then comp1 else theCompileFlow[i][4][15][5]
							2: [comp1,comp2]
							3: [comp1,comp2,comp3]
							4: [comp1,comp2,comp3,comp4] 
						)
						append debugArray #(theCompileFlow[i][3][2], theValue)	
						append debugChannelsArray theCompileFlow[i][3][2]						
					)	
				)
			)--end i loop			
		)
		
		fn updateCompileFlow theCompileFlow graphstep:0.0 =
		(
			for i = 2 to theCompileFlow.count do
			(
				if theCompileFlow[i][1] == "Input" and theCompileFlow[i][3][1] == "Value" do 
				(
					if theCompileFlow[i][4][15] == undefined do theCompileFlow[i][4][15] = #(1.0,1.0,1.0,1.0,1,0.0,0.0,0.0,0.0,1.0,1.0,1.0,1.0,false)
					
					if 	theCompileFlow[i][3][2] == "Float" and theCompileFlow[i][4][15][14] == true do
					(
						theCompileFlow[i][3][1] = "Channel"
						theCompileFlow[i][3][2] = "FloatInput_" + i as string
						deleteItem theCompileFlow[i][3] 3
						theValue = theCompileFlow[i][4][15][6] + (theCompileFlow[i][4][15][10]-theCompileFlow[i][4][15][6])*graphstep
						append debugArray #(theCompileFlow[i][3][2], theValue)	
						append debugChannelsArray theCompileFlow[i][3][2]		
					)

					if theCompileFlow[i][3][2] == "Vector" and theCompileFlow[i][4][15][14] == true do
					(
						theCompileFlow[i][3][1] = "Channel"
						theCompileFlow[i][3][2] = "VectorInput_" + i as string
						deleteItem theCompileFlow[i][3] 3
						local comp1 = theCompileFlow[i][4][15][6] + (theCompileFlow[i][4][15][10]-theCompileFlow[i][4][15][6])*graphstep
						local comp2 = theCompileFlow[i][4][15][7] + (theCompileFlow[i][4][15][11]-theCompileFlow[i][4][15][7])*graphstep
						local comp3 = theCompileFlow[i][4][15][8] + (theCompileFlow[i][4][15][12]-theCompileFlow[i][4][15][8])*graphstep
						local theValue = [comp1,comp2,comp3]
						append debugArray #(theCompileFlow[i][3][2], theValue)	
						append debugChannelsArray theCompileFlow[i][3][2]								
					)
				)			
			)--end i loop
			theCompileFlow
		)
		
		fn debugFlow graphOutput:#thumb=
		(
			local st = timestamp()
			--max modify mode
			--modPanel.setCurrentObject KrakatoaChannelNodeEditor_CurrentModifier
			if (for o in selection where (for m in o.modifiers where m == KrakatoaChannelNodeEditor_CurrentModifier collect m).count > 0 collect o).count == 0 do return false
			
			
			local bitmapSize = 160
			local sampleStep = case KrakatoaChannelNodeEditor_OutputGraphRange[5] of
			(
				1: 80
				2: 40
				4: 10
				default: 20
			)
			if graphOutput == #large do
			(
				bitmapSize = 400
				sampleStep = 100
			)
			
			if KrakatoaChannelNodeEditor_OutputGraphRange[5] < 5 then
				KrakatoaChannelsNodeEditor_GraphOutputBitmap = bitmap bitmapSize bitmapSize color:(white*0.0)
			else
				KrakatoaChannelsNodeEditor_GraphOutputBitmap = bitmap bitmapSize bitmapSize color:(white*0.7)
			
			for k = 1 to KrakatoaChannelEditor_DisplayNodeTreeData.count where KrakatoaChannelEditor_DisplayNodeTreeData[k][1] == "Output" or KrakatoaChannelEditor_DisplayNodeTreeData[k][1] == "Operator" or KrakatoaChannelEditor_DisplayNodeTreeData[k][1] == "BlackOp"  do
			(
				local lastresults = undefined
				local lastStep = 0.0
				local doGraph = k == 1 and KrakatoaChannelNodeEditor_OutputGraphRange[5] < 5
				if doGraph then 
				(
					local startLoop = 0.0
					local endLoop = 1.0
					local stepLoop = 1.0/sampleStep
					
				)
				else
				(
					local startLoop = 1.0
					local endLoop = 1.0
					local stepLoop = 1
				)
				for graphstep = startLoop to endLoop by stepLoop do
				(
					local theDebugSubTree = deepCopy KrakatoaChannelEditor_DisplayNodeTreeData
					if k > 1 do theDebugSubTree[1][2][1] = k
						
					debugArray = #()
					debugChannelsArray = #()
					
					theDebugSubTree[1][3][1] = "MXSVector"
					theDebugSubTree[1][3][2] = "Float16"
					theDebugSubTree[1][3][3] = 3
					
					KrakatoaChannelNodeEditor_CurrentModifier.flow = (KrakatoaChannelsEditor_Functions.expandFlow (with printAllElements true theDebugSubTree as string)) 
					local theCompileFlow = execute KrakatoaChannelNodeEditor_CurrentModifier.flow
					collectDebugArray theCompileFlow outputName:"MXSVector" outputValue:[0,0,0] graphstep:graphstep
					if doGraph do 
					(
						theCompileFlow = updateCompileFlow theCompileFlow graphstep:graphstep
						KrakatoaChannelNodeEditor_CurrentModifier.flow = (with printAllElements true theCompileFlow as string)
					)
						
					--format "%\n" theDebugSubTree
					--theResult = (FranticParticles.DebugEvalKCM selection[1] KrakatoaChannelNodeEditor_CurrentModifier debugArray)
					local theResult = try ((FranticParticles.DebugEvalKCM selection[1] KrakatoaChannelNodeEditor_CurrentModifier debugArray)) catch(false)
					--print theResult 
					if theResult == false do
					(
						debugArray = #()
						debugChannelsArray = #()	
						theDebugSubTree[1][3][1] = "MXSFloat"
						theDebugSubTree[1][3][2] = "Float16"
						theDebugSubTree[1][3][3] = 1
						
						KrakatoaChannelNodeEditor_CurrentModifier.flow = (KrakatoaChannelsEditor_Functions.expandFlow (with printAllElements true theDebugSubTree as string)) 
						local theCompileFlow = execute KrakatoaChannelNodeEditor_CurrentModifier.flow
						collectDebugArray theCompileFlow outputName:"MXSFloat" outputValue:0.0 graphstep:graphstep
						if doGraph do 
						(
							theCompileFlow = updateCompileFlow theCompileFlow graphstep:graphstep
							KrakatoaChannelNodeEditor_CurrentModifier.flow = (with printAllElements true theCompileFlow as string)
						)							
						theResult = try ((FranticParticles.DebugEvalKCM selection[1] KrakatoaChannelNodeEditor_CurrentModifier debugArray)) catch(false)
					)	
					if theResult == false do
					(
						debugArray = #()
						debugChannelsArray = #()	
						theDebugSubTree[1][3][1] = "MXSInteger"
						theDebugSubTree[1][3][2] = "Int16"
						theDebugSubTree[1][3][3] = 1
						
						KrakatoaChannelNodeEditor_CurrentModifier.flow = (KrakatoaChannelsEditor_Functions.expandFlow (with printAllElements true theDebugSubTree as string)) 
						local theCompileFlow = execute KrakatoaChannelNodeEditor_CurrentModifier.flow
						collectDebugArray theCompileFlow outputName:"MXSInteger" outputValue:0 graphstep:graphstep
						if doGraph do 
						(
							theCompileFlow = updateCompileFlow theCompileFlow graphstep:graphstep
							KrakatoaChannelNodeEditor_CurrentModifier.flow = (with printAllElements true theCompileFlow as string)
						)							
						theResult = try ((FranticParticles.DebugEvalKCM selection[1] KrakatoaChannelNodeEditor_CurrentModifier debugArray)) catch(false)
					)	
					if theResult == false do --do quaternions
					(
						--print "FAILED with Int Output, Trying Quat Output"
						debugArray = #()
						debugChannelsArray = #()	
						theDebugSubTree[1][3][1] = "Orientation"
						theDebugSubTree[1][3][2] = "Float16"
						theDebugSubTree[1][3][3] = 4
						
						KrakatoaChannelNodeEditor_CurrentModifier.flow = (KrakatoaChannelsEditor_Functions.expandFlow (with printAllElements true theDebugSubTree as string)) 
						local theCompileFlow = execute KrakatoaChannelNodeEditor_CurrentModifier.flow
						collectDebugArray theCompileFlow outputName:"Orientation" outputValue:[0,0,0,1] graphstep:graphstep
						if doGraph do 
						(
							theCompileFlow = updateCompileFlow theCompileFlow graphstep:graphstep
							KrakatoaChannelNodeEditor_CurrentModifier.flow = (with printAllElements true theCompileFlow as string)
						)							
						theResult = try ((FranticParticles.DebugEvalKCM selection[1] KrakatoaChannelNodeEditor_CurrentModifier debugArray)) catch(#("FAILED"))
					)		
					
					
					if doGraph and classof theResult[1] == Float do --if the Output Node was debugged and the first component of the result was a float, we have to graph the output
					(
						local stdraw = timestamp()
						if lastresults == undefined do lastresults = deepCopy theResult
						local theStep = case theResult.count of
						(
							1: amax #( abs (lastresults[1]-theResult[1]), stepLoop )
							2: amax #( abs (lastresults[1]-theResult[1]), abs (lastresults[2]-theResult[2]), stepLoop )
							3: amax #( abs (lastresults[1]-theResult[1]), abs (lastresults[2]-theResult[2]), abs (lastresults[3]-theResult[3]), stepLoop )
							4: amax #( abs (lastresults[1]-theResult[1]), abs (lastresults[2]-theResult[2]), abs (lastresults[3]-theResult[3]), abs (lastresults[4]-theResult[4]), stepLoop )
						)
						if theStep == 0 do theStep = 1
						local XRange = (KrakatoaChannelNodeEditor_OutputGraphRange[2]-KrakatoaChannelNodeEditor_OutputGraphRange[1])
						if XRange == 0 do XRange = 0.1
						local YRange = (KrakatoaChannelNodeEditor_OutputGraphRange[4]-KrakatoaChannelNodeEditor_OutputGraphRange[3])
						if YRange == 0 do YRange = 0.1
						--if theStep > 100.0/YRange do theStep = 100.0/YRange
						if theStep > bitmapSize/(2*sampleStep) do theStep = bitmapSize/(2*sampleStep)
						
						--COORDINATE SYSTEM AXES
						local thePixels =(for j = 1 to bitmapSize collect white*0.3)
						setPixels KrakatoaChannelsNodeEditor_GraphOutputBitmap [0,bitmapSize+bitmapSize*KrakatoaChannelNodeEditor_OutputGraphRange[3]/YRange] thePixels
						for j = 1 to bitmapsize do 
							setPixels KrakatoaChannelsNodeEditor_GraphOutputBitmap [bitmapSize*(-KrakatoaChannelNodeEditor_OutputGraphRange[1])/XRange,j-1] #(white*0.3)
						
						for j = floor KrakatoaChannelNodeEditor_OutputGraphRange[1] to ceil KrakatoaChannelNodeEditor_OutputGraphRange[2] do
							setPixels KrakatoaChannelsNodeEditor_GraphOutputBitmap [bitmapSize*(j-KrakatoaChannelNodeEditor_OutputGraphRange[1])/XRange,bitmapSize+bitmapSize*KrakatoaChannelNodeEditor_OutputGraphRange[3]/YRange] #(white)

						for j = floor KrakatoaChannelNodeEditor_OutputGraphRange[3] to ceil KrakatoaChannelNodeEditor_OutputGraphRange[4] do
							setPixels KrakatoaChannelsNodeEditor_GraphOutputBitmap [bitmapSize*(-KrakatoaChannelNodeEditor_OutputGraphRange[1])/XRange,bitmapSize-bitmapSize*(j-KrakatoaChannelNodeEditor_OutputGraphRange[3])/YRange] #(white)
						
						--DRAWING THE GRAPH
						
						local backStep = if graphstep == 0 then 0 else 1	
						
						for j = 0.0 to 1.0 by (1.0/(bitmapSize*theStep)) do
						(
							local xoffset = ((graphstep-stepLoop*backStep)+j*stepLoop*backStep - KrakatoaChannelNodeEditor_OutputGraphRange[1])/XRange
							if classof theResult[1] == Float do
							(
								local yoffset = (lastresults[1] + j*(theResult[1]-lastresults[1]) - KrakatoaChannelNodeEditor_OutputGraphRange[3])/YRange
								setPixels KrakatoaChannelsNodeEditor_GraphOutputBitmap [bitmapSize*xoffset,bitmapSize-bitmapSize*yoffset] #(red)
							)
							if theResult.count > 1 do
							(
								local yoffset = (lastresults[2] + j*(theResult[2]-lastresults[2]) - KrakatoaChannelNodeEditor_OutputGraphRange[3])/YRange
								setPixels KrakatoaChannelsNodeEditor_GraphOutputBitmap [bitmapSize*xoffset,bitmapSize-bitmapSize*yoffset] #(green)
							)						
							if theResult.count > 2 do
							(
								local yoffset = (lastresults[3] + j*(theResult[3]-lastresults[3]) - KrakatoaChannelNodeEditor_OutputGraphRange[3])/YRange
								setPixels KrakatoaChannelsNodeEditor_GraphOutputBitmap [bitmapSize*xoffset,bitmapSize-bitmapSize*yoffset] #([0.5,0.5,1.0]*255)
							)
							if theResult.count > 3 do
							(
								local yoffset = (lastresults[4] + j*(theResult[4]-lastresults[4]) - KrakatoaChannelNodeEditor_OutputGraphRange[3])/YRange
								setPixels KrakatoaChannelsNodeEditor_GraphOutputBitmap [bitmapSize*xoffset,bitmapSize-bitmapSize*yoffset] #(yellow)
							)
						)--end j loop
						lastresults = deepcopy theResult
						--format "% ms\n" (timestamp()-stdraw)
					)--end k == 1
					
					
					local theResultString = theResult as string
					theResultString = substring theResultString  2 -1
					hc.activeNode = k
					hc.activeSocket = hc.getSocketCount
					hc.socketName = "DEBUG: "+ theResultString
					hc.redrawView	
					--format "Debug Result: %\n" theResultString
					lastStep = graphstep
				)--end graphstep loop
			)--end k loop
			--Restore internal flow in Modifier
			KrakatoaChannelNodeEditor_CurrentModifier.flow = (KrakatoaChannelsEditor_Functions.expandFlow KrakatoaChannelNodeEditor_CurrentModifier.internalflow) 
			KrakatoaChannelNodeEditor_GraphOutputRollout.bmp_graphValue.bitmap =  KrakatoaChannelsNodeEditor_GraphOutputBitmap
			
			popPrompt()
			pushPrompt ("MagmaFlow Debug Graph:" + (timestamp()-st) as string + "ms")
		)--end function		
		
		fn recursiveInvisibility theParent =
		(
			for j in KrakatoaChannelEditor_DisplayNodeTreeData[theParent][2] where j != undefined and j > 0 do
			(
				theNodeInvisibilityList[j] = true
				recursiveInvisibility j
			)
		)
		fn recursiveVisibility theParent =
		(
			for j in KrakatoaChannelEditor_DisplayNodeTreeData[theParent][2] where j != undefined and j > 0 do
			(
				theNodeInvisibilityList[j] = false
				recursiveVisibility j
			)
		)		
		fn scanForCollapsedNodes =
		(
			theNodeInvisibilityList = #{}
			for i = 2 to KrakatoaChannelEditor_DisplayNodeTreeData.count do
			(
				if KrakatoaChannelEditor_DisplayNodeTreeData[i][4][2] == true then
				(
					recursiveInvisibility i
				)
			)
			for i = 2 to KrakatoaChannelEditor_DisplayNodeTreeData.count do
			(
				if KrakatoaChannelEditor_DisplayNodeTreeData[i][4][2] == false and theNodeInvisibilityList[i] == false then
				(
					for j in KrakatoaChannelEditor_DisplayNodeTreeData[i][2] where j != undefined and j > 0 do
					(
						--theNodeInvisibilityList[j] = false
						--recursiveInvisibility j
					)
				)
			)			
		)

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--TREE REDRAW FUNCTIONS	
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
				
		fn createNodeTree init:false=
		(
--			KrakatoaChannelsEditor_Functions.buildDisplayTree()
			ConnectorLeftMargin = 0
			if KrakatoaChannelEditor_NodeTreeEditingLevel.count > 0 and DepotPlacement == #left do 
			(
				ConnectorLeftMargin = leftDepotMargin
			)
			if init do
			(
				for i = hc.getNodeCount to 1 by -1 do 
				(
					hc.activeNode = i	
					hc.deleteActiveNode
				)
			)	
			FlagUnconnectedNodes()
			
			if AllowSubtreeCollapsing then 
				scanForCollapsedNodes()
			else
				theNodeInvisibilityList = #{}
			
			local ErrorNodeToHighlight = KrakatoaChannelEditor_ErrorTree[KrakatoaChannelEditor_NodeTreeEditingLevel.count+1]
			
			
			local connectorCount = 0
			for i = 1 to KrakatoaChannelEditor_DisplayNodeTreeData.count do 
			(
				local currentNode = KrakatoaChannelEditor_DisplayNodeTreeData[i]
				local nodeNumber = i as string
				case currentNode[1] of
				(
					"Output": (
						if init do hc.addNode
						hc.activeNode = i
						hc.nodeName =  nodeNumber +" OUT:" + currentNode[3][1] 
						hc.nodeColor = if ErrorNodeToHighlight == i and KrakatoaChannelEditor_LastError[3] == KrakatoaChannelNodeEditor_CurrentModifier.trackID  then 
							theErrorNodeColor 
						else 
							theOutputNodeColor 
						hc.activeNodePos = currentNode[4][1] 
						hc.isCollapsible = false
						try(hc.drawLayer = 3)catch()
						try(hc.viewAlign = 1)catch()
						if init do hc.addInSocket
						hc.activeSocket = 1
						try(hc.activeSocketFlipped  = true)catch()
						hc.socketPosition = [5,17]
						hc.socketName = currentNode[3][2]+"["+currentNode[3][3] as string+"] " 
						hc.connectionColor = getInputSocketColor currentNode 1
						hc.nodeSize = [NodeWidth,30]
						hc.nodeCollapsedSize = [NodeWidth,30]							
						hc.activeNodeCollapsed  = currentNode[4][2] == true
						hc.isSelected = currentNode[4][3] == true
					)
					"OutputConnector": (
						if init do hc.addNode
						hc.activeNode = i
						hc.nodeName = currentlyEditedBlackOpName
						hc.nodeColor = theOutputNodeColor 
						--hc.activeNodePos = currentNode[4][1] 
						hc.isCollapsible = false
						try(hc.drawLayer = 3)catch()
						try(hc.viewAlign = 1)catch()
						if init do hc.addInSocket
						hc.activeSocket = 1
						try(hc.activeSocketFlipped  = true)catch()
						hc. socketPosition = [5,17]
						hc.socketName = "BlackOp Output "
						hc.connectionColor = theChannelSocketColor*0.5 --getInputSocketColor currentNode 1
						hc.nodeSize = [NodeWidth,30]
						hc.nodeCollapsedSize = [NodeWidth,30]		
						hc.activeNodeCollapsed  = currentNode[4][2] == true
						hc.isSelected = currentNode[4][3] == true
					)		
					"Connector": (
						if init do hc.addNode
						hc.activeNode = i
						hc.nodeName =  " INPUT SOCKET " + (connectorCount+1)  as string
						hc.nodeColor = theOutputNodeColor 
						hc.viewAlignOffset = [ConnectorLeftMargin,connectorCount*40] --currentNode[4][1] 
						connectorCount +=1
						hc.isCollapsible = false
						try(hc.drawLayer = 3)catch()
						try(hc.viewAlign = -1)catch()
						--try(hc.activeSocketFlipped  = true)catch()
						if init do hc.addOutSocket
						hc.activeSocket = 1
						hc.socketPosition = [5,17]
						hc.socketName = currentNode[3][1] + " " --+"["+currentNode[3][3] as string+"] " 
						hc.connectionColor = theChannelSocketColor*0.5 --getInputSocketColor currentNode 1
						hc.nodeSize = [NodeWidth,30]
						hc.nodeCollapsedSize = [NodeWidth,30]		
						hc.isSelected = currentNode[4][3] == true
						hc.activeSocketShowValue = false
					)						
					
					"BlackOp":
					(
						if init do hc.addNode
						hc.activeNode = i
						try(hc.drawLayer = 1)catch()
						hc.nodeName = nodeNumber + " BLOP:" + currentNode[4][8] as string
						hc.nodeColor = if ErrorNodeToHighlight == i and KrakatoaChannelEditor_LastError[3] == KrakatoaChannelNodeEditor_CurrentModifier.trackID  then 
							theErrorNodeColor * (if currentNode[5] == false then 0.75 else 1.0)
						else 
							theBoxNodeColor * (if currentNode[5] == false then 0.5 else 1.0)
						
						if theNodeInvisibilityList[i] then 
							hc.activeNodePos = [-1000,-1000]
						else
							hc.activeNodePos = currentNode[4][1] 		
						
						hc.isCollapsible = true

						local totalInSockets = (for j in currentNode[3][2] where j[1] == "Connector" collect j)
						for s = 1 to totalInSockets.count do 
						(
							if init do hc.addInSocket
							hc.activeSocket = s
							hc.socketPosition = [5,30+(s-1)*13]
							hc.socketName = totalInSockets[s][3][1] as string  --s as string + " " + 
							hc.connectionColor = getInputSocketColor currentNode s
							hc.activeNodeCollapsed  = currentNode[4][2] == true
							hc.isSelected = currentNode[4][3] == true		
						)
						if init do hc.addOutSocket
						hc.activeSocket = totalInSockets.count+1
						hc.socketName = "Output "
						hc.activeSocketShowValue = false
						hc.connectionColor = theChannelSocketColor * (if currentNode[5] == false then 0.5 else 1.0)
						hc.socketPosition = [110,18]					
						if currentNode[4][14] == true do 
						(
							try(hc.activeSocketFlipped  = true)catch()
						)							
						hc.nodeSize = [NodeWidth,30+(totalInSockets.count)*13]
						hc.nodeCollapsedSize = [NodeWidth,15]		
					)
					"Notes":
					(
						if init do hc.addNode
						hc.activeNode = i
						try(hc.drawLayer = -1)catch()
						hc.activeNodePos = currentNode[4][1] 			
						hc.isCollapsible = false
						if currentNode[3][1] == "Notes" do
						(
							local theNameString = currentNode[4][8]
							if theNameString == undefined do theNameString = currentNode[4][8] = "Notes"
							hc.nodeName =  nodeNumber + " INFO:"+theNameString
							hc.nodeColor = theNotesNodeColor
							local theNotes = currentNode[4][16]
							if classof theNotes != String do theNotes = ""
							local theNotesArray = filterString theNotes "\n" splitEmptyTokens:false
							local maxChars = 0
							for i = 1 to theNotesArray.count do 
							(
								if init do hc.addInSocket
								hc.activeSocket = i
								hc.socketPosition = [3,3]
								hc.socketLabelOffset = [-10,4+i*13]
								hc.socketName = theNotesArray[i]
								hc.connectionColor = theNotesNodeColor
								local theWidth = (gw.getTextExtent theNotesArray[i]).x
								if theWidth > maxChars do maxChars = theWidth
							)
							hc.nodeSize = [amax #(NodeWidth, maxChars*1.2) ,20+theNotesArray.count*13]
							hc.isSelected = currentNode[4][3] == true							
						)							
					)
					"Input": 
					(
						if init do hc.addNode
						hc.activeNode = i
						try(hc.drawLayer = 2)catch()
						
						if theNodeInvisibilityList[i] then 
							hc.activeNodePos = [-1000,-1000]
						else
							hc.activeNodePos = currentNode[4][1] 			
						
						
						if init do hc.addOutSocket
						hc.activeSocket = 1
						hc.socketPosition = [110,17]
						if currentNode[4][14] == true do 
						(
							try(hc.activeSocketFlipped  = true)catch()
						)	
						if currentNode[3][1] == "Channel" do
						(
							local theNameString = currentNode[4][8]
							if theNameString == undefined do theNameString = currentNode[4][8] = currentNode[3][2]
							hc.nodeName = nodeNumber + " IN:Channel:" + theNameString
							hc.nodeColor = if ErrorNodeToHighlight == i and KrakatoaChannelEditor_LastError[3] == KrakatoaChannelNodeEditor_CurrentModifier.trackID then 
								theErrorNodeColor * (if currentNode[5] == false then 0.75 else 1.0)
							else 
								theInputNodeColor * (if currentNode[4][7]==false then 0.9 else 1.0) * (if currentNode[5] == false then 0.5 else 1.0)
							hc.connectionColor = theChannelSocketColor * (if currentNode[5] == false then 0.5 else 1.0)
							hc.socketName = currentNode[3][2]+ " "+ getChannelDataType currentNode[3][2]
						)
						hc.activeSocketShowValue = false
						if currentNode[3][1] == "Value" then
						(
							hc.socketName = currentNode[3][2] + " "
							local theNameString = currentNode[4][8]
							if theNameString == undefined do theNameString = currentNode[4][8] = currentNode[3][2]
							case currentNode[3][2] of
							(
								"Integer" : 
								( 
									local theExpString = ""
									if currentNode[4][12] == true do theExpString +="E" 
									try(if classof (execute (currentNode[3][3]+"[1].controller")) == Float_Script do theExpString +="C" )catch()
									try(if classof (execute (currentNode[3][3]+"[1].controller[2].controller")) == Float_Script do theExpString +="C" )catch()
										
									hc.nodeName = theExpString + nodeNumber+ " IN:Int:" + theNameString
									hc.socketName ="Integer:" + (try(((floor((execute (currentNode[3][3]+"[1].controller.value"))+0.5)) as integer) as string + " ")catch("??"))
									hc.connectionColor = theIntegerSocketColor * (if currentNode[5] == false then 0.5 else 1.0) 
									hc.nodeColor = if ErrorNodeToHighlight == i and KrakatoaChannelEditor_LastError[3] == KrakatoaChannelNodeEditor_CurrentModifier.trackID then 
										theErrorNodeColor * (if currentNode[5] == false then 0.75 else 1.0)
									else 
										theInputNodeColor * (if currentNode[4][7]==false then 0.9 else 1.0) * (if currentNode[5] == false then 0.5 else 1.0) - [0,20,20]
									)
								"Float" : 
								( 
									local theExpString = ""
									if currentNode[4][12] == true do theExpString +="E" 
									try(if classof (execute (currentNode[3][3]+"[2].controller")) == Float_Script do theExpString +="C" )catch()
									try(if classof (execute (currentNode[3][3]+"[2].controller[2].controller")) == Float_Script do theExpString +="C" )catch()
										
									hc.nodeName =  theExpString + nodeNumber+ " IN:Float:" + theNameString
									hc.socketName = "Float:" + (try((execute (currentNode[3][3]+"[2].controller.value")) as string + " ")catch("?.?") )
									hc.connectionColor = theFloatSocketColor * (if currentNode[5] == false then 0.5 else 1.0) 
									hc.nodeColor = if ErrorNodeToHighlight == i and KrakatoaChannelEditor_LastError[3] == KrakatoaChannelNodeEditor_CurrentModifier.trackID then 
										theErrorNodeColor * (if currentNode[5] == false then 0.75 else 1.0)
									else 
										theInputNodeColor * (if currentNode[4][7]==false then 0.9 else 1.0) * (if currentNode[5] == false then 0.5 else 1.0) + [-20,20,-20] 
									)
								"Vector": 
								( 
									local theExpString = ""
									if currentNode[4][12] == true do theExpString +="E" 
									try(if classof (execute (currentNode[3][3]+"[3].controller[1].controller")) == Float_Script do theExpString +="C" )catch()
									try(if classof (execute (currentNode[3][3]+"[3].controller[2].controller[1].controller")) == Float_Script do theExpString +="C" )catch()
										
									hc.nodeName =  theExpString+nodeNumber+ " IN:Vector:" + theNameString
									--print (currentNode[3][3]+"[3].controller.value")
									hc.socketName =  "Vector:" + (try((execute (currentNode[3][3]+"[3].controller.value")) as string+ " ")catch("[?, ?, ?]")) --currentNode[3][2] + " " +
									hc.connectionColor = theVectorSocketColor * (if currentNode[5] == false then 0.5 else 1.0) 
									hc.nodeColor = if ErrorNodeToHighlight == i and KrakatoaChannelEditor_LastError[3] == KrakatoaChannelNodeEditor_CurrentModifier.trackID then 
										theErrorNodeColor * (if currentNode[5] == false then 0.75 else 1.0)
									else 
										theInputNodeColor * (if currentNode[4][7]==false then 0.9 else 1.0) * (if currentNode[5] == false then 0.5 else 1.0) + [0,20,0]
								)
								default:
								(
									hc.nodeName =  nodeNumber + " IN:???:" + theNameString
									hc.socketName =  "???"
									hc.connectionColor = theVectorSocketColor * (if currentNode[5] == false then 0.5 else 1.0) 
									hc.nodeColor = if ErrorNodeToHighlight == i and KrakatoaChannelEditor_LastError[3] == KrakatoaChannelNodeEditor_CurrentModifier.trackID then 
										theErrorNodeColor * (if currentNode[5] == false then 0.75 else 1.0)
									else 
										theInputNodeColor * (if currentNode[4][7]==false then 0.9 else 1.0) * (if currentNode[5] == false then 0.5 else 1.0) + [0,20,0]
								)
							)								
						)	
						if currentNode[3][1] == "Time" then
						(
							local theNameString = currentNode[4][8]
							if theNameString == undefined do theNameString = currentNode[4][8] = "Time"
							
							hc.nodeName =  nodeNumber + " IN:Time:" +theNameString
							hc.socketName = "Time "
							hc.connectionColor = theTimeSocketColor * (if currentNode[5] == false then 0.5 else 1.0)
							hc.nodeColor = if ErrorNodeToHighlight == i and KrakatoaChannelEditor_LastError[3] == KrakatoaChannelNodeEditor_CurrentModifier.trackID then 
								theErrorNodeColor * (if currentNode[5] == false then 0.75 else 1.0)
							else 
								theInputNodeColor * (if currentNode[5] == false then 0.5 else 1.0) - [0,0,40]
						)
						if currentNode[3][1] == "TextureMap" do
						(
							local theNameString = currentNode[4][8]
							if theNameString == undefined do theNameString = currentNode[4][8] = "[" + (join #("Current") (for i in KrakatoaChannelNodeEditor_CurrentModifier.TextureMapSources collect i as string))[currentNode[3][2]]+"]"
							hc.nodeName = nodeNumber +  " IN:Map:"+ theNameString 
							local txt =	try("[" + (join #("Current") (for i in KrakatoaChannelNodeEditor_CurrentModifier.TextureMapSources collect i as string))[currentNode[3][2]]+"] ")catch("Missing Map ")
							txt += (case currentNode[3][3] of
								(
									default: "[?]"
									"Color": "[C]"
									"Mono": "[M]"
									"Perturb": "[P]"
								)
							)
							hc.socketName = txt
							hc.connectionColor = theTextureMapSocketColor * (if currentNode[5] == false then 0.5 else 1.0)
							hc.nodeColor = if ErrorNodeToHighlight == i and KrakatoaChannelEditor_LastError[3] == KrakatoaChannelNodeEditor_CurrentModifier.trackID then 
								theErrorNodeColor * (if currentNode[5] == false then 0.75 else 1.0)
							else 
								theInputNodeColor * (if currentNode[4][7]==false then 0.9 else 1.0) * (if currentNode[5] == false then 0.5 else 1.0) + [20,0,-20]
						)			
									
						if currentNode[3][1] == "Geometry" do
						(
							local theNameString = currentNode[4][8]
							if theNameString == undefined do theNameString = currentNode[4][8] = "Geometry"
							hc.nodeName =  nodeNumber + " IN:"+theNameString
							hc.nodeColor = if ErrorNodeToHighlight == i and KrakatoaChannelEditor_LastError[3] == KrakatoaChannelNodeEditor_CurrentModifier.trackID then 
								theErrorNodeColor * (if currentNode[5] == false then 0.75 else 1.0)
							else 
								theInputNodeColor * (if currentNode[4][7]==false then 0.9 else 1.0) * (if currentNode[5] == false then 0.5 else 1.0) + [20,-20,-40]
							local theBaseName = "No Objects "
							if currentNode[3][2].count > 0 do theBaseName = currentNode[3][2][1] + " "
							if currentNode[3][2].count > 1 do theBaseName += "+"+(currentNode[3][2].count-1) as string + " "
							hc.socketName = theBaseName
							hc.connectionColor = theObjectSocketColor * (if currentNode[5] == false then 0.5 else 1.0)
						)
						
						if currentNode[3][1] == "Object" do
						(
							local theNameString = currentNode[4][8]
							if theNameString == undefined do theNameString = currentNode[4][8] = "Object"
							hc.nodeName =  nodeNumber + " IN:"+theNameString
							hc.nodeColor = if ErrorNodeToHighlight == i and KrakatoaChannelEditor_LastError[3] == KrakatoaChannelNodeEditor_CurrentModifier.trackID then 
								theErrorNodeColor * (if currentNode[5] == false then 0.75 else 1.0)
							else 
								theInputNodeColor * (if currentNode[4][7]==false then 0.9 else 1.0) * (if currentNode[5] == false then 0.5 else 1.0) + [20,-30,-40]
							hc.socketName = if try(isValidNode (getNodeByName currentNode[3][2]))catch(false) then
								currentNode[3][2]
							else
								"Object "
							hc.connectionColor = theObjectSocketColor * (if currentNode[5] == false then 0.5 else 1.0)
						)				

						if currentNode[3][1] == "Script" do
						(
							local theNameString = currentNode[4][8]
							if theNameString == undefined do theNameString = currentNode[4][8] = "MyScript"
							hc.nodeName =  nodeNumber + " IN:"+theNameString
							hc.socketName = "Script:Output"
							hc.nodeColor = if ErrorNodeToHighlight == i and KrakatoaChannelEditor_LastError[3] == KrakatoaChannelNodeEditor_CurrentModifier.trackID then 
								theErrorNodeColor * (if currentNode[5] == false then 0.75 else 1.0)
							else 
								theInputNodeColor * (if currentNode[4][7]==false then 0.9 else 1.0) * (if currentNode[5] == false then 0.5 else 1.0) + [20,-20,-20]
							if scriptCodeAutoCheck do
							(
								try
								(
									local theVal = execute( currentNode[3][2])
									if classof theVal == Integer or classof theVal == Float or classof theVal  == Point3 or classof theVal == color then
									(
										hc.socketName = theVal as string + " "
									)
									else
									(
										hc.socketName = "NAN "
										hc.nodeColor = color 255 128 128									
									)
								)catch
								(
									hc.socketName = "ERROR "
									hc.nodeColor = color 255 128 128
								)
							)	
							hc.connectionColor = theFloatSocketColor * (if currentNode[5] == false then 0.5 else 1.0)
						)				
						hc.nodeSize = [NodeWidth,30]
						hc.nodeCollapsedSize = [NodeWidth,15]		
						hc.activeNodeCollapsed  = currentNode[4][2] == true
						hc.isSelected = currentNode[4][3] == true
					)	
					"Operator": 
					(
						if init do hc.addNode
						hc.activeNode = i
						try(hc.drawLayer = 2)catch()
						local theNameString = currentNode[4][8]
						if theNameString == undefined do theNameString = currentNode[4][8] = currentNode[3][1]
						hc.nodeName =  nodeNumber+ " OP:" + theNameString 
						local theColorOffset = [0,0,0]
						if findItem #("Magnitude","Normalize", "ComponentSum",	"DotProduct","CrossProduct") currentNode[3][1] > 0 do theColorOffset = [0,10,0]
						if findItem #("Sin","Cos","Tan","ASin","ACos","ATan","ATan2") currentNode[3][1] > 0 do theColorOffset = [0,-10,0] 
						if findItem #("LogicalAnd", "LogicalOr", "LogicalNot", "Less", "Greater", "GreaterOrEqual", "Equal", "Switch") currentNode[3][1] > 0 do theColorOffset =  [-10,0,10]
						if findItem #("FromQuat","ToQuat","ToVector","ToScalar","ToFloat","ToInteger","Property") currentNode[3][1] > 0 do theColorOffset = [-10,-10,10]
						if findItem #("ToWorld","FromWorld","ToSpace","FromSpace","ToView","FromView","TransformByQuat") currentNode[3][1] > 0 do theColorOffset = [-10,10,10]
						if findItem #("NearestPoint","SurfDataValue","RayIntersect") currentNode[3][1] > 0 do theColorOffset = [-10,20,20]
						
						hc.nodeColor = if ErrorNodeToHighlight == i and KrakatoaChannelEditor_LastError[3] == KrakatoaChannelNodeEditor_CurrentModifier.trackID then 
							theErrorNodeColor * (if currentNode[5] == false then 0.75 else 1.0)
						else 
							(theOperatorNodeColor+theColorOffset ) * (if currentNode[4][7]==false then 0.9 else 1.0) * (if currentNode[5] == false then 0.5 else 1.0)

						if theNodeInvisibilityList[i] then 
							hc.activeNodePos = [-1000,-1000]
						else
							hc.activeNodePos = currentNode[4][1] 								

						--TWO INPUTS
						if getInputCount currentNode == 2 then
						(
							if init do hc.addInSocket
							hc.activeSocket = 1
							hc.socketPosition = [5,32]
							hc.socketName = getInputSocketName currentNode 1
							hc.connectionColor = getInputSocketColor currentNode 1
							
							if init do hc.addInSocket
							hc.activeSocket = 2
							hc.socketPosition = [5,45]
							hc.connectionColor = getInputSocketColor currentNode 2
							hc.socketName = getInputSocketName currentNode 2
							
							if init do hc.addOutSocket
							hc.activeSocket = 3
							hc.socketName = currentNode[3][1]+" "
							hc.connectionColor = color 0 0 200
							hc.activeSocketShowValue = false
							hc.socketPosition = [110,18]
							
							hc.nodeSize = if operatorHeightConstant then
								[NodeWidth , 70]
							else
								[NodeWidth , 60]
							hc.nodeCollapsedSize = [NodeWidth,15]	
							hc.activeNodeCollapsed  = currentNode[4][2] == true										
							
							if currentNode[4][14] == true do 
							(
								try(hc.activeSocketFlipped  = true)catch()
							)								
						)
					
						--ONE INPUT
						if getInputCount currentNode == 1 then
						(
							if init do hc.addInSocket
							hc.activeSocket = 1
							hc.socketPosition = [5,32]
							hc.socketName = getInputSocketName currentNode 1
							hc.connectionColor = getInputSocketColor currentNode 1
							if init do hc.addOutSocket
							hc.activeSocket = 2
							hc.socketName = if currentNode[3][1] == "ToSpace" or currentNode[3][1] == "FromSpace" then
								if currentNode[3][3] == undefined or currentNode[3][3] == "" then "<No Node> " else currentNode[3][3] as string +" "
							else if currentNode[3][1] == "SurfDataValue" then
									try(currentNode[3][2]+" ")catch("Position ")
								else if currentNode[3][1] == "Property" then
									try(currentNode[3][2]+" ")catch("Property ")
								else
									currentNode[3][1]+" "				
							if (currentNode[3][1] == "ToWorld" or currentNode[3][1] == "FromWorld" or currentNode[3][1] == "ToSpace" or currentNode[3][1] == "FromSpace"  or currentNode[3][1] == "ToView" or currentNode[3][1] == "FromView") and currentNode[3][2] != undefined do hc.socketName += "("+(substring currentNode[3][2] 1 1)+")"
								
							hc.activeSocketShowValue = false
							hc.connectionColor = color 0 0 200
							hc.socketPosition = [110,18]

							hc.nodeSize = if operatorHeightConstant then
								[NodeWidth , 70]
							else
								[NodeWidth , 50]
							hc.nodeCollapsedSize = [NodeWidth,15]	
							hc.activeNodeCollapsed  = currentNode[4][2] == true										

							if currentNode[4][14] == true do 
							(
								try(hc.activeSocketFlipped  = true)catch()
							)								
						)	
						
						--THREE INPUTS
						if getInputCount currentNode == 3 then
						(
							if init do hc.addInSocket
							hc.activeSocket = 1
							hc.socketPosition = [5,32]
							hc.socketName = getInputSocketName currentNode 1
							hc.connectionColor = getInputSocketColor currentNode 1
							
							if init do hc.addInSocket
							hc.activeSocket = 2
							hc.socketPosition = [5,45]
							hc.socketName = getInputSocketName currentNode 2
							hc.connectionColor = getInputSocketColor currentNode 2
							
							if init do hc.addInSocket
							hc.activeSocket = 3
							hc.socketPosition = [5,58]
							hc.socketName = case currentNode[3][1] of
							(
								"Switch": "Condition"
								"Blend": "Blend Ratio (0-1)"	
								default: "Input 3"
							)	
							if getInputSocketName currentNode 3 != "Input 3" do hc.socketName = getInputSocketName currentNode 3
							hc.connectionColor = getInputSocketColor currentNode 3
							
							if init do hc.addOutSocket
							hc.activeSocket = 4
							hc.socketName = currentNode[3][1]+" "
							hc.activeSocketShowValue = false
							hc.connectionColor = color 0 0 200
							hc.socketPosition = [110,18]

							hc.nodeSize = [NodeWidth,70]
							hc.nodeCollapsedSize = [NodeWidth,15]	
							hc.activeNodeCollapsed  = currentNode[4][2] == true								
							
							if currentNode[4][14] == true do 
							(
								try(hc.activeSocketFlipped  = true)catch()
							)								
						)
						hc.isSelected = currentNode[4][3] == true
					)		
				)
			)--end loop
			if init do 
			(
				--Recreate all connections
				for i = 1 to KrakatoaChannelEditor_DisplayNodeTreeData.count where theNodeInvisibilityList[i] == false do
				(
					local currentNode = KrakatoaChannelEditor_DisplayNodeTreeData[i]
					local theConnections = currentNode[2]
					for c = 1 to theConnections.count do
					(
						if theConnections[c] != undefined and theConnections[c] > 0 and theNodeInvisibilityList[theConnections[c]] == false do
						(
							hc.activeNode = theConnections[c]
							hc.activeSocket = hc.getSocketCount
							hc.toggleConnection = [i,c]
						)	
					)
				)
			)
			drawDepot init:init
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
			hc.redrawView	
		)
		
		fn restoreLastKnownPanAndZoom =
		(
			try --try to restore pan and zoom based on the output node's data
			(
				if KrakatoaChannelEditor_DisplayNodeTreeData[1][4][20] != undefined do
				(
					hc.pan = KrakatoaChannelEditor_DisplayNodeTreeData[1][4][20][1]
					hc.zoom = KrakatoaChannelEditor_DisplayNodeTreeData[1][4][20][2]
				)			
			)catch()			
		)
		
		fn handleDepotDragAndDrop =
		(
			local returnValue = false
			if DepotPlacement == #off do return false
			for i = 1 to theDepotNodes.count do
			(
				hc.activeNode = KrakatoaChannelEditor_DisplayNodeTreeData.count+i
				
				if theDepotNodes[i][4] != undefined do
				(
					if (DepotPlacement==#left and hc.activeNodePos.x > theDepotNodes[i][4].x) or ((DepotPlacement==#bottom or DepotPlacement==#bottomrollup or DepotPlacement==#bottomrollupreverse )and hc.activeNodePos.y < theDepotNodes[i][4].y) do
					(
--						format "% % % %\n" hc.activeNode hc.activeNodePos i theDepotNodes[i]
						lastMouseClick = mouse.screenpos - [NodeWidth/2,0]
						setSelectedNodes lastSelectionBeforeClick
						case theDepotNodes[i][1] of
						(
							"NT": addNewInput type:theDepotNodes[i][5] valuetype:theDepotNodes[i][6] creationType:#rcmenu
							"IN": addNewInput type:theDepotNodes[i][5] valuetype:theDepotNodes[i][6] creationType:#rcmenu
							"OP": addNewOperator type:theDepotNodes[i][5] creationType:#rcmenu
							"BLOP": addNewBLOP creationType:#rcmenu useFile:true createUndo:true
							"UBLOP": addNewBLOP creationType:#rcmenu useFile:false createUndo:true theFile:theDepotNodes[i][5]
							"CN": addNewInput type:theDepotNodes[i][5] valuetype:theDepotNodes[i][6] creationType:#rcmenu
						)	
						returnValue = true
						if DepotAutoCollapseOnDragAndDrop do
						(
							for j = 1 to KrakatoaChannelEditor_theDepotNodesArray.count where KrakatoaChannelEditor_theDepotNodesArray[j][1][1]  == "HEAD" do
								KrakatoaChannelEditor_theDepotNodesArray[j][1][6] = false		
							updateDepotDefinition()
							createNodeTree init:true
						)
						exit
					)	
				)
				hc.activeNodePos = theDepotNodes[i][4]
			)		
			hc.redrawView		
			returnValue			
		)
	
		
		fn setUndoRedoEnable = 
		(
			btn_redo.enabled = KrakatoaChannelEditor_LastUndoRecordNumber < (getFiles (GetDir #plugcfg + "\\Krakatoa\\MagmaFlowUndoRecords\\UndoRecord.*")).count 
			btn_undo.enabled = KrakatoaChannelEditor_LastUndoRecordNumber > 1
		)
		
		fn flipSockets Nodetype Side =
		(
			for i = 1 to KrakatoaChannelEditor_DisplayNodeTreeData.Count do
				if (NodeType == #input and KrakatoaChannelEditor_DisplayNodeTreeData[i][1] == "Input") or (NodeType == #op and KrakatoaChannelEditor_DisplayNodeTreeData[i][1] == "Operator") do
					KrakatoaChannelEditor_DisplayNodeTreeData[i][4][14] = (Side == #left)
			
			createNodeTree init:true
		)
		
		
		
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--UNDO/REDO FUNCTIONS		
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
		
		fn updatePlaybackBar =
		(
			prg_bar.value = 100.0 * (currentMacroLine)/(KrakatoaChannelEditor_MacroRecording.count)
		)
		
		fn updateMacroRecorderControls =
		(
			val = execute (getIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "ParticleChannelEditor" "Size" )
			if val != OK do
			(
				NodePropsSR.height = if KrakatoaChannelEditor_MacroRecording.count > 0 then val.y-80 else val.y-49
				btn_RecorderToStart.visible = btn_RecorderBackOneStep.visible = chk_RecorderPlay.visible = btn_RecorderForwardOneStep.visible = btn_RecorderToEnd.visible = btn_RecorderClose.visible = KrakatoaChannelEditor_MacroRecording.count > 0 
			)	
			--btn_RecorderToStart.enabled = currentMacroLine > 1 
			--btn_RecorderToEnd.enabled = currentMacroLine < KrakatoaChannelEditor_MacroRecording.count
			updatePlaybackBar()
		)		
		
		
		fn createUndoRecord undoText playbackDuration:1.0=
		(
			makeDir (GetDir #plugcfg + "\\Krakatoa\\MagmaFlowUndoRecords\\") all:true
			local theCount = (getFiles (GetDir #plugcfg + "\\Krakatoa\\MagmaFlowUndoRecords\\UndoRecord.*")).count
			if KrakatoaChannelEditor_LastUndoRecordNumber < theCount do 
			(
				for i = KrakatoaChannelEditor_LastUndoRecordNumber+1 to theCount do
				(
					deleteFile (GetDir #plugcfg + "\\Krakatoa\\MagmaFlowUndoRecords\\UndoRecord." + i as string)
				)
			)
			KrakatoaChannelEditor_LastUndoRecordNumber +=1
			KrakatoaChannelEditor_UndoRecordNames[KrakatoaChannelEditor_LastUndoRecordNumber] = undoText
			
			local theFileName = GetDir #plugcfg + "\\Krakatoa\\MagmaFlowUndoRecords\\UndoRecord." + KrakatoaChannelEditor_LastUndoRecordNumber as string
			local theFileHandle = createFile theFileName
			
			for i = 1 to KrakatoaChannelEditor_DisplayNodeTreeData.count where KrakatoaChannelEditor_DisplayNodeTreeData[i][3][1] == "Script" do
				KrakatoaChannelEditor_DisplayNodeTreeData[i][3][2] = KrakatoaChannelEditor_DisplayNodeTreeData[i][4][6] = (KrakatoaChannelsEditor_Functions.escapeString KrakatoaChannelEditor_DisplayNodeTreeData[i][4][6])
			
			with PrintAllElements true	format "global KrakatoaChannelEditor_NodeTreeData = %\n" KrakatoaChannelEditor_DisplayNodeTreeData to:theFileHandle 
			with PrintAllElements true	format "global KrakatoaChannelEditor_NodeTreeEditingLevel = %\n" KrakatoaChannelEditor_NodeTreeEditingLevel to:theFileHandle 
			with PrintAllElements true	format "global KrakatoaChannelEditor_NodeTreeEditingNames = %\n" KrakatoaChannelEditor_NodeTreeEditingNames to:theFileHandle 
			with PrintAllElements true	format "global KrakatoaChannelEditor_NodeTreeEditingUndoLevel = %\n" KrakatoaChannelEditor_NodeTreeEditingUndoLevel to:theFileHandle 
			format "global KrakatoaChannelEditor_PlaybackDuration = %\n" playbackDuration to:theFileHandle 
			format "global KrakatoaChannelEditor_UndoRecordName = \"%\"\n" undoText to:theFileHandle 

			close theFileHandle
			
			KrakatoaChannelEditor_DisplayNodeTreeData = execute ( with PrintAllElements true KrakatoaChannelEditor_DisplayNodeTreeData as string)
			--KrakatoaChannelsEditor_Functions.buildDisplayTree()
			setUndoRedoEnable()
			try(hc.setInfo = KrakatoaChannelEditor_UndoRecordNames[KrakatoaChannelEditor_LastUndoRecordNumber])catch()
			KrakatoaChannelNodeEditor_CurrentModifierPresetIsCustom = true
		)
		
		fn restoreInputValues =
		(
			for i = 1 to KrakatoaChannelEditor_DisplayNodeTreeData.count where KrakatoaChannelEditor_DisplayNodeTreeData[i][3][1] == "Value" and KrakatoaChannelEditor_DisplayNodeTreeData[i][4][5] != undefined do
			(
				try(
					case KrakatoaChannelEditor_DisplayNodeTreeData[i][3][2] of
					(
						"Integer": execute (KrakatoaChannelEditor_DisplayNodeTreeData[i][3][3] + "[1].controller.value = "+ KrakatoaChannelEditor_DisplayNodeTreeData[i][4][5][1] as string)
						"Float": execute (KrakatoaChannelEditor_DisplayNodeTreeData[i][3][3] + "[2].controller.value = "+ KrakatoaChannelEditor_DisplayNodeTreeData[i][4][5][2] as string)
						"Vector": 
						(
							execute (KrakatoaChannelEditor_DisplayNodeTreeData[i][3][3] + "[3].controller.value = "+ KrakatoaChannelEditor_DisplayNodeTreeData[i][4][5][3] as string)
						)
					)
				)
				catch
				(
					FranticParticles.LogWarning ("Failed To Restore Value in Node "+i as string + ":IN:"+KrakatoaChannelEditor_DisplayNodeTreeData[i][3][2]+":"+KrakatoaChannelEditor_DisplayNodeTreeData[i][4][8])
				)
			)			
		)
		
		fn undoLastStep =
		(
			KrakatoaChannelEditor_LastError = #(0,"","")
			if KrakatoaChannelEditor_LastUndoRecordNumber > 1 do
			(
				KrakatoaChannelEditor_LastUndoRecordNumber -= 1
				local expandedFlow = execute (KrakatoaChannelsEditor_Functions.expandFlow (with PrintAllElements true KrakatoaChannelEditor_DisplayNodeTreeData as string) fixTracks:true)
				local oldExposure = for i = 1 to expandedFlow.count where expandedFlow[i][4][12] == true collect i
				try
				(
					fileIn (GetDir #plugcfg + "\\Krakatoa\\MagmaFlowUndoRecords\\UndoRecord." + KrakatoaChannelEditor_LastUndoRecordNumber as string)
					KrakatoaChannelEditor_DisplayNodeTreeData = deepCopy KrakatoaChannelEditor_NodeTreeData
					expandedFlow = execute (KrakatoaChannelsEditor_Functions.expandFlow (with PrintAllElements true KrakatoaChannelEditor_DisplayNodeTreeData as string) fixTracks:true)
					local newExposure = for i = 1 to expandedFlow.count where expandedFlow[i][4][12] == true collect i
					restoreInputValues()
					createNodeTree init:true
				)catch()
			)	
			try(hc.setInfo = "Undo '" + KrakatoaChannelEditor_UndoRecordNames[KrakatoaChannelEditor_LastUndoRecordNumber+1]+"'")catch()
			createNodeTree init:false
			lbx_log.items = #()
			setUndoRedoEnable()
			if chk_autoUpdateModifier.checked do KrakatoaChannelsEditor_Functions.updateParentModifier()
			displaySelectedNodeProperties()
			
			if newExposure as string != oldExposure as string do KrakatoaChannelsEditor_Functions.exposeControlsToModifier KrakatoaChannelNodeEditor_CurrentModifier
			KrakatoaChannelsEditor_Functions.updateEditorTitle()
		)
		
		fn undoToRecord theRecord =
		(
			KrakatoaChannelEditor_LastError = #(0,"","")
			try
			(
				local expandedFlow = execute (KrakatoaChannelsEditor_Functions.expandFlow (with PrintAllElements true KrakatoaChannelEditor_DisplayNodeTreeData as string) fixTracks:true)
				local oldExposure = for i = 1 to expandedFlow.count where expandedFlow[i][4][12] == true collect i
				fileIn (GetDir #plugcfg + "\\Krakatoa\\MagmaFlowUndoRecords\\UndoRecord." + (theRecord-1) as string)
				KrakatoaChannelEditor_LastUndoRecordNumber = theRecord-1
				KrakatoaChannelEditor_DisplayNodeTreeData = deepCopy KrakatoaChannelEditor_NodeTreeData
				expandedFlow = execute (KrakatoaChannelsEditor_Functions.expandFlow (with PrintAllElements true KrakatoaChannelEditor_DisplayNodeTreeData as string) fixTracks:true)
				local newExposure = for i = 1 to expandedFlow.count where expandedFlow[i][4][12] == true collect i
				restoreInputValues()
				createNodeTree init:true
			)catch()
			
			try(hc.setInfo = "Undo To '" +KrakatoaChannelEditor_UndoRecordNames[KrakatoaChannelEditor_LastUndoRecordNumber]+"'")catch()
			setUndoRedoEnable()		
			createNodeTree init:false
			lbx_log.items = #()
			if chk_autoUpdateModifier.checked do KrakatoaChannelsEditor_Functions.updateParentModifier()			
			displaySelectedNodeProperties()		
			
			if newExposure as string != oldExposure as string do KrakatoaChannelsEditor_Functions.exposeControlsToModifier KrakatoaChannelNodeEditor_CurrentModifier
			KrakatoaChannelsEditor_Functions.updateEditorTitle()
		)
		
		fn redoToRecord theRecord =
		(
			KrakatoaChannelEditor_LastError = #(0,"","")
			try
			(
				local expandedFlow = execute (KrakatoaChannelsEditor_Functions.expandFlow (with PrintAllElements true KrakatoaChannelEditor_DisplayNodeTreeData as string) fixTracks:true)
				local oldExposure = for i = 1 to expandedFlow.count where expandedFlow[i][4][12] == true collect i
				fileIn (GetDir #plugcfg + "\\Krakatoa\\MagmaFlowUndoRecords\\UndoRecord." + (theRecord) as string)
				KrakatoaChannelEditor_LastUndoRecordNumber = theRecord
				KrakatoaChannelEditor_DisplayNodeTreeData = deepCopy KrakatoaChannelEditor_NodeTreeData
				expandedFlow = execute (KrakatoaChannelsEditor_Functions.expandFlow (with PrintAllElements true KrakatoaChannelEditor_DisplayNodeTreeData as string) fixTracks:true)
				local newExposure = for i = 1 to expandedFlow.count where expandedFlow[i][4][12] == true collect i
				restoreInputValues()	
				createNodeTree init:true
			)catch()
			try(hc.setInfo = "Redo to '" + KrakatoaChannelEditor_UndoRecordNames[KrakatoaChannelEditor_LastUndoRecordNumber]+"'")catch()
			setUndoRedoEnable()		
			displaySelectedNodeProperties()			
			if chk_autoUpdateModifier.checked do KrakatoaChannelsEditor_Functions.updateParentModifier()
			if newExposure as string != oldExposure as string do KrakatoaChannelsEditor_Functions.exposeControlsToModifier KrakatoaChannelNodeEditor_CurrentModifier
			KrakatoaChannelsEditor_Functions.updateEditorTitle()
		)		
		
		
		fn redoLastStep =
		(
			KrakatoaChannelEditor_LastError = #(0,"","")
			if KrakatoaChannelEditor_LastUndoRecordNumber < (getFiles (GetDir #plugcfg + "\\Krakatoa\\MagmaFlowUndoRecords\\UndoRecord.*")).count do
			(
				KrakatoaChannelEditor_LastUndoRecordNumber += 1
				try
				(
					local expandedFlow = execute (KrakatoaChannelsEditor_Functions.expandFlow (with PrintAllElements true KrakatoaChannelEditor_DisplayNodeTreeData as string) fixTracks:true)
					local oldExposure = for i = 1 to expandedFlow.count where expandedFlow[i][4][12] == true collect i
					fileIn (GetDir #plugcfg + "\\Krakatoa\\MagmaFlowUndoRecords\\UndoRecord." + KrakatoaChannelEditor_LastUndoRecordNumber as string)
					KrakatoaChannelEditor_DisplayNodeTreeData = deepCopy KrakatoaChannelEditor_NodeTreeData
					expandedFlow = execute (KrakatoaChannelsEditor_Functions.expandFlow (with PrintAllElements true KrakatoaChannelEditor_DisplayNodeTreeData as string) fixTracks:true)
					local newExposure = for i = 1 to expandedFlow.count where expandedFlow[i][4][12] == true collect i
					restoreInputValues()	
					createNodeTree init:true				
				)catch()
			)
			try(hc.setInfo = "Redo '" + KrakatoaChannelEditor_UndoRecordNames[KrakatoaChannelEditor_LastUndoRecordNumber]+"'")catch()
			setUndoRedoEnable()
			displaySelectedNodeProperties()
			if chk_autoUpdateModifier.checked do KrakatoaChannelsEditor_Functions.updateParentModifier()
			if newExposure as string != oldExposure as string do KrakatoaChannelsEditor_Functions.exposeControlsToModifier KrakatoaChannelNodeEditor_CurrentModifier
			KrakatoaChannelsEditor_Functions.updateEditorTitle()
		)			

		fn convertUndoBufferToRecording =
		(
			KrakatoaChannelEditor_DisableDragAndDrop = false
			makeDir (Krakatoa_PresetsDirectory+ "\\Macros\\") all:true
			local theMacroFilename = getSaveFileName filename:(Krakatoa_PresetsDirectory+ "\\Macros\\Macro.kmr") caption:"Save Macro Recording" types:"Krakatoa Macro Recording (*.kmr)|*.kmr"
			if theMacroFilename != undefined do
			(
				--createUndoRecord "Save MacroRecord"
				KrakatoaChannelEditor_MacroRecording = #()
				for i = 1 to KrakatoaChannelEditor_LastUndoRecordNumber do
				(
					fileIn (GetDir #plugcfg + "\\Krakatoa\\MagmaFlowUndoRecords\\UndoRecord." + i as string)
					--1: Tree, 2: EditingLevel 3: Names 4: UndoLevel 5: Duration 6: Name
					append KrakatoaChannelEditor_MacroRecording #(deepCopy KrakatoaChannelEditor_NodeTreeData, deepCopy KrakatoaChannelEditor_NodeTreeEditingLevel, deepCopy KrakatoaChannelEditor_NodeTreeEditingNames, deepCopy KrakatoaChannelEditor_NodeTreeEditingUndoLevel, KrakatoaChannelEditor_PlaybackDuration, KrakatoaChannelEditor_UndoRecordName)
				)
				local theFileHandle = createFile theMacroFilename
				lastMacroFileName = theMacroFilename
				with PrintAllElements true format "global KrakatoaChannelEditor_MacroRecording = %\n" KrakatoaChannelEditor_MacroRecording to:theFileHandle 
				close theFileHandle
			)
			updateMacroRecorderControls()
			--fileIn (GetDir #plugcfg + "\\Krakatoa\\MagmaFlowUndoRecords\\UndoRecord." + KrakatoaChannelEditor_LastUndoRecordNumber as string)
			--KrakatoaChannelEditor_DisplayNodeTreeData = deepCopy KrakatoaChannelEditor_NodeTreeData
		)
		
		fn saveMacroRecording =
		(
			KrakatoaChannelEditor_DisableDragAndDrop = false
			makeDir (Krakatoa_PresetsDirectory+ "\\Macros\\") all:true
			local theMacroFilename = getSaveFileName filename:lastMacroFileName caption:"Save Macro Recording" types:"Krakatoa MagmaFlow Macro Recording (*.kmr)|*.kmr"
			if theMacroFilename != undefined do
			(
				local theFileHandle = createFile theMacroFilename
				lastMacroFileName = theMacroFilename
				with PrintAllElements true format "global KrakatoaChannelEditor_MacroRecording = %\n" KrakatoaChannelEditor_MacroRecording to:theFileHandle 
				close theFileHandle
			)
		)
		
		timer tmr_macroPlayback interval:100 active:false
		
		fn LoadMacroRecording =
		(
			KrakatoaChannelEditor_DisableDragAndDrop = false
			makeDir (Krakatoa_PresetsDirectory+ "\\Macros\\") all:true
			local theMacroFilename = getOpenFileName filename:(Krakatoa_PresetsDirectory+ "\\Macros\\*.kmr") caption:"Load Macro Recording" types:"Krakatoa MagmaFlow Macro Recording (*.kmr)|*.kmr"
			if theMacroFilename != undefined do
			(
				--createUndoRecord "Load MacroRecording"
				fileIn theMacroFilename
				lastMacroFileName = theMacroFilename
				currentMacroLine = 0
				KrakatoaChannelEditor_DisplayNodeTreeData = deepCopy KrakatoaChannelEditor_MacroRecording[KrakatoaChannelEditor_MacroRecording.count][1]
				KrakatoaChannelsEditor_Functions.fixFlowIDsAfterLoading KrakatoaChannelEditor_DisplayNodeTreeData 
				createNodeTree init:true
				if KrakatoaChannelNodeEditor_MacroRecorderEditor.open do 
				(
					KrakatoaChannelNodeEditor_MacroRecorderEditor.updateUI()
					KrakatoaChannelNodeEditor_MacroRecorderEditor.updateControls()
				)	
				--KrakatoaChannelEditor_DisplayNodeTreeData = deepCopy KrakatoaChannelEditor_MacroRecording[1][1]
				--createNodeTree init:true
			)
			updateMacroRecorderControls()
		)
		
		fn PlayBackRecording = 
		(
			tmr_macroPlayback.active = true
			chk_RecorderPlay.text = "||||"
			try(chk_RecorderPlay.images = #("VCRControls_16i.bmp","VCRControls_16i.bmp", 28,9,9,10,10,true) )catch()
			chk_RecorderPlay.checked = true
		)
		
		fn StopPlayBackRecording =
		(
			tmr_macroPlayback.active = false
			chk_RecorderPlay.text = "|>"
			try(chk_RecorderPlay.images = #("VCRControls_16i.bmp","VCRControls_16i.bmp", 28,7,7,8,8,true) )catch()
			chk_RecorderPlay.checked = false
		)
		
		local lastDelay  = 1.0
		local lastPlayTime = 0
		fn PlayRecordLine =
		(
			KrakatoaChannelEditor_LastError = #(0,"","")
			KrakatoaChannelNodeEditor_Rollout.lbx_log.items = #()
			lastPlayTime = timestamp()
--			if currentMacroLine <= KrakatoaChannelEditor_MacroRecording.count then
			(
				KrakatoaChannelEditor_DisplayNodeTreeData = deepCopy KrakatoaChannelEditor_MacroRecording[currentMacroLine][1]
				KrakatoaChannelsEditor_Functions.fixFlowIDsAfterLoading KrakatoaChannelEditor_DisplayNodeTreeData 
				KrakatoaChannelEditor_NodeTreeEditingLevel = KrakatoaChannelEditor_MacroRecording[currentMacroLine][2]
				KrakatoaChannelEditor_NodeTreeEditingNames = KrakatoaChannelEditor_MacroRecording[currentMacroLine][3]
				KrakatoaChannelEditor_NodeTreeEditingUndoLevel = KrakatoaChannelEditor_MacroRecording[currentMacroLine][4]
				hc.setInfo = KrakatoaChannelEditor_MacroRecording[currentMacroLine][6] as string
				restoreInputValues()
				createNodeTree init:true
				displaySelectedNodeProperties()
				
				if AutoReorderToggle do autoReorderFlow createUndo:false
				if AutoZoomExtents do zoomExtents createUndo:false	
					
				if chk_autoUpdateModifier.checked do 
					KrakatoaChannelNodeEditor_CurrentModifier.flow = KrakatoaChannelsEditor_Functions.expandFlow (with PrintAllElements true KrakatoaChannelEditor_DisplayNodeTreeData as string)
				
				updatePlaybackBar()
				--sleep (lastDelay)
				--tmr_macroPlayback.interval = lastDelay*1000
				--lastDelay = KrakatoaChannelEditor_PlaybackDuration
			)			
			/*
			else
			(
				KrakatoaChannelsEditor_Functions.buildDisplayTree()		
				createNodeTree init:true					
				tmr_macroPlayback.active = false
				currentMacroLine = 0
				--undoLastStep()
			)
			*/
		)
		
		fn StepForwardMacroRecording =
		(
			if currentMacroLine < KrakatoaChannelEditor_MacroRecording.count do
			(
				currentMacroLine += 1
				PlayRecordLine()
			)	
		)
		fn StepBackMacroRecording =
		(
			if currentMacroLine > 1 do
			(
				currentMacroLine -= 1
				PlayRecordLine()
			)	
		)
		
		on prg_bar clicked val do 
		(
			local theVal = floor(val/100.0*KrakatoaChannelEditor_MacroRecording.count+0.5)
			if theVal != currentMacroLine and theVal > 0 do
			(
				currentMacroLine = theVal 
				if currentMacroLine < 1 do currentMacroLine  = 1
				if currentMacroLine > KrakatoaChannelEditor_MacroRecording.count do currentMacroLine  = KrakatoaChannelEditor_MacroRecording.count
				PlayRecordLine()	
			)	
		)
		
		
		on tmr_macroPlayback tick do
		(
			local nextDelay = try(KrakatoaChannelEditor_MacroRecording[currentMacroLine+1][5])catch(0)
			if (timeStamp()-lastPlayTime)/1000.0 > nextDelay do
			(
				if currentMacroLine < KrakatoaChannelEditor_MacroRecording.count then
				(
					currentMacroLine += 1
					PlayRecordLine()
				)	
				else
				(
					StopPlayBackRecording()
					KrakatoaChannelsEditor_Functions.buildDisplayTree()		
					createNodeTree init:true		
					PlayRecordLine()					
				)
			)	
		)
		
		on btn_RecorderToStart pressed do 
		(
			currentMacroLine = 1
			PlayRecordLine()			
		)	
		on btn_RecorderToEnd pressed do 
		(
			currentMacroLine = KrakatoaChannelEditor_MacroRecording.count
			PlayRecordLine()
		)	
			
		on btn_RecorderBackOneStep pressed do StepBackMacroRecording()
		on btn_RecorderForwardOneStep pressed do StepForwardMacroRecording()

		--on chk_RecorderStop pressed do StopPlayBackRecording()
		on chk_RecorderPlay changed state do 
		(
			if state then 
			(
				PlayBackRecording() 
			)	
			else 
			(
				StopPlayBackRecording()
			)
		)	
		
		on btn_RecorderClose pressed do 
		(
			local q = querybox "Are you sure you want to CLOSE the Macro Recorder?" title:"Close Macro Recorder"
			if q then
			(
				currentMacroLine = 1
				KrakatoaChannelEditor_MacroRecording = #()
				updateMacroRecorderControls()
			)	
		)
		
		
		fn createUndoRCMenu =
		(
			global KrakatoaChannelEditor_UndoRCMenu
			local txt = "rcmenu KrakatoaChannelEditor_UndoRCMenu (\n"
			for i = KrakatoaChannelEditor_LastUndoRecordNumber to 2 by -1 do
			(
				txt += "menuItem mnu_"+ i as string + " \"" + KrakatoaChannelEditor_UndoRecordNames[i] + "\"\n"
				txt += "on mnu_"+ i as string + " picked do KrakatoaChannelNodeEditor_Rollout.undoToRecord "+ i as string + "\n"
			)	
			txt += ")\n"
			execute txt
		)
		
		fn createRedoRCMenu =
		(
			global KrakatoaChannelEditor_UndoRCMenu
			local txt = "rcmenu KrakatoaChannelEditor_UndoRCMenu (\n"
			for i = KrakatoaChannelEditor_LastUndoRecordNumber+1 to KrakatoaChannelEditor_UndoRecordNames.count do
			(
				txt += "menuItem mnu_"+ i as string + " \"" + KrakatoaChannelEditor_UndoRecordNames[i] + "\"\n"
				txt += "on mnu_"+ i as string + " picked do KrakatoaChannelNodeEditor_Rollout.redoToRecord "+ i as string + "\n"
			)	
			txt += ")\n"
			execute txt
		)	

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--NODE PROPERTIES FUNCTIONS		
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
		
		fn displaySelectedNodeProperties =
		(
			for i = NodePropsSR.rollouts.count to 1 by -1 do 
				removeSubRollout NodePropsSR NodePropsSR.rollouts[i]
			if hc.selectedNodeIndex > 0 and hc.getSelectionCount == 1 and  KrakatoaChannelEditor_DisplayNodeTreeData[hc.selectedNodeIndex] != undefined do
			(
				lastNodeClick = hc.selectedNodeIndex 

				if debugModeOn do
				(
					addSubRollout NodePropsSR KrakatoaChannelNodeEditor_GraphOutputRollout rolledup:false
				)
				
				case KrakatoaChannelEditor_DisplayNodeTreeData[hc.selectedNodeIndex][1] of
				(
					"Input": 
					(
						local tempController1 = undefined
						try(tempController1 = execute (KrakatoaChannelEditor_DisplayNodeTreeData[hc.selectedNodeIndex][3][3]+"[1].controller"))catch()
						if tempController1 != undefined and classof tempController1 == Float_List do 
							tempController1 = tempController1[1].controller
						if tempController1 == undefined then
							global KrakatoaChannelEditor_CurrentIntController = 	bezier_float()
						else 
							global KrakatoaChannelEditor_CurrentIntController = tempController1
						
						local tempController2 = undefined
						try(tempController2 = execute (KrakatoaChannelEditor_DisplayNodeTreeData[hc.selectedNodeIndex][3][3]+"[2].controller"))catch()
						if tempController2 != undefined and classof tempController2 == Float_List do 
							tempController2 = tempController2[1].controller
						if tempController2 == undefined then
							global KrakatoaChannelEditor_CurrentFloatController = 	bezier_float()
						else 
							global KrakatoaChannelEditor_CurrentFloatController = tempController2
						
						local tempController3 = undefined
						try(tempController3 = execute (KrakatoaChannelEditor_DisplayNodeTreeData[hc.selectedNodeIndex][3][3]+"[3].controller"))catch()
						if tempController3 != undefined and classof tempController3 == Point3_List do 
							tempController3 = tempController3[1].controller
							
						if tempController3 == undefined then
							global KrakatoaChannelEditor_CurrentVectorController =  point3_xyz()
						else 
							global KrakatoaChannelEditor_CurrentVectorController = tempController3

						/*
						try
						(
							global KrakatoaChannelEditor_CurrentIntController = execute (KrakatoaChannelEditor_DisplayNodeTreeData[hc.selectedNodeIndex][3][3]+"[1].controller[1].controller")
							global KrakatoaChannelEditor_CurrentFloatController = execute (KrakatoaChannelEditor_DisplayNodeTreeData[hc.selectedNodeIndex][3][3]+"[2].controller[1].controller")
							global KrakatoaChannelEditor_CurrentVectorController = execute (KrakatoaChannelEditor_DisplayNodeTreeData[hc.selectedNodeIndex][3][3]+"[3].controller[1].controller")
						)
						catch
						(
							global KrakatoaChannelEditor_CurrentIntController = 	bezier_float()
							global KrakatoaChannelEditor_CurrentFloatController = 	bezier_float()
							global KrakatoaChannelEditor_CurrentVectorController = point3_xyz()
						)	
						*/
						
						local theState = execute (getIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "ParticleChannelEditor" "NodeNameRolloutRolledup")
						if theState == OK do theState = false
						KrakatoaChannelsEditor_isInitializing = true
						addSubRollout NodePropsSR KrakatoaChannelNodeEditor_NodeNameRollout rolledup:(not theState)
						addSubRollout NodePropsSR KrakatoaChannelNodeEditor_InputRollout rolledup:false
						if KrakatoaChannelEditor_DisplayNodeTreeData[hc.selectedNodeIndex][3][2] == "Vector" do
							addSubRollout NodePropsSR KrakatoaChannelNodeEditor_ColorClipboardRollout rolledup:true
						if debugModeOn do 
						(
							if KrakatoaChannelEditor_DisplayNodeTreeData[hc.selectedNodeIndex][3][1] == "Channel" do addSubRollout NodePropsSR KrakatoaChannelNodeEditor_ChannelDebugRollout rolledup:false
							if KrakatoaChannelEditor_DisplayNodeTreeData[hc.selectedNodeIndex][3][2] == "Float" do addSubRollout NodePropsSR KrakatoaChannelNodeEditor_FloatDebugRollout rolledup:false
							if KrakatoaChannelEditor_DisplayNodeTreeData[hc.selectedNodeIndex][3][2] == "Vector" do addSubRollout NodePropsSR KrakatoaChannelNodeEditor_VectorDebugRollout rolledup:false
						)
						KrakatoaChannelsEditor_isInitializing = false
					)
					"Output": 
					(
						addSubRollout NodePropsSR KrakatoaChannelNodeEditor_OutputRollout rolledup:false
					)
					"Notes":
					(
						addSubRollout NodePropsSR KrakatoaChannelNodeEditor_NodeNameRollout rolledup:false
					)
					"Operator": 
					(
						local theState = execute (getIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "ParticleChannelEditor" "NodeNameRolloutRolledup")
						if theState == OK do theState = false
							KrakatoaChannelsEditor_isInitializing = true
						addSubRollout NodePropsSR KrakatoaChannelNodeEditor_NodeNameRollout rolledup:(not theState)
						addSubRollout NodePropsSR KrakatoaChannelNodeEditor_OperatorRollout rolledup:false
						local theState = execute (getIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "ParticleChannelEditor" "OperatorDescriptionRolloutRolledup")
						if theState == OK do theState = false
							KrakatoaChannelsEditor_isInitializing = true
						addSubRollout NodePropsSR KrakatoaChannelNodeEditor_OperatorDescriptionRollout rolledup:(not theState)
						KrakatoaChannelsEditor_isInitializing = false
					)	
					"BlackOp":
					(
						local theState = execute (getIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "ParticleChannelEditor" "NodeNameRolloutRolledup")
						if theState == OK do theState = false
						KrakatoaChannelsEditor_isInitializing = true
						addSubRollout NodePropsSR KrakatoaChannelNodeEditor_NodeNameRollout rolledup:(not theState)
						addSubRollout NodePropsSR KrakatoaChannelNodeEditor_BlackOpsRollout rolledup:false
						KrakatoaChannelsEditor_isInitializing = false
					)
					"Connector":
					(
						KrakatoaChannelsEditor_isInitializing = true
						addSubRollout NodePropsSR KrakatoaChannelNodeEditor_ConnectorRollout rolledup:false
						KrakatoaChannelsEditor_isInitializing = false
					)
					"OutputConnector":
					(
						KrakatoaChannelsEditor_isInitializing = true
						addSubRollout NodePropsSR KrakatoaChannelNodeEditor_OutputConnectorRollout rolledup:false
						KrakatoaChannelsEditor_isInitializing = false
					)					
				)
			)		
			addSubRollout NodePropsSR KrakatoaChannelNodeEditor_OptionsRollout rolledup:true
			setFocus hc
		)
		
		fn displayOptions =
		(
			for i = NodePropsSR.rollouts.count to 1 by -1 do 
				removeSubRollout NodePropsSR NodePropsSR.rollouts[i]
			addSubRollout NodePropsSR KrakatoaChannelNodeEditor_OptionsRollout rolledup:false
		)

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--PAN AND ZOOM FUNCTIONS		
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
		fn resetPanFactor =
		(
			setIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "ParticleChannelEditor" "Pan" "[0,0]"	
			hc.pan = [0,0]
			createNodeTree init:false			
		)		
		
		fn resetZoomFactor =
		(
			setIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "ParticleChannelEditor" "Zoom" "1"	
			hc.zoom = 1
			createNodeTree init:false
		)
		
		fn ZoomExtents createUndo:true=
		(
			local minX = 1000000
			local maxX =-1000000
			local minY = 1000000
			local maxY =-1000000
			
			if KrakatoaChannelEditor_DisplayNodeTreeData.count > 2 then
			(
				for i = 2 to KrakatoaChannelEditor_DisplayNodeTreeData.count do
				(
					local theVal = KrakatoaChannelEditor_DisplayNodeTreeData[i][4][1]
					if theVal.x+150 > maxX do maxX = theVal.x+150
					if theVal.y+100 > maxY do maxY = theVal.y+100
					if theVal.x < minX do minX = theVal.x 
					if theVal.y < minY do minY = theVal.y
				)
				minY -=40
				theBBoxX = maxX-minX
				theBBoxY = maxY-minY
				theHCWidth = hc.width-leftDepotMargin
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
		)
		
		fn ZoomExtentsSelected createUndo:true =
		(
			local minX = 1000000
			local maxX =-1000000
			local minY = 1000000
			local maxY =-1000000
			local doZoom = 0
			if KrakatoaChannelEditor_DisplayNodeTreeData.count > 2 then
			(
				for i = 2 to KrakatoaChannelEditor_DisplayNodeTreeData.count do
				(
					hc.ActiveNode = i
					if hc.isSelected do
					(
						doZoom += 1
						local theVal = KrakatoaChannelEditor_DisplayNodeTreeData[i][4][1]
						if theVal.x+150 > maxX do maxX = theVal.x+150
						if theVal.y+100 > maxY do maxY = theVal.y+100
						if theVal.x < minX do minX = theVal.x 
						if theVal.y < minY do minY = theVal.y
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
		)		
		
		local theGridMap = #()
		local theMap = #{}
		
		fn setNodePositionRecursiveTree theNodeIndex theRefPos theXOffset maxLinks parentDir:-1 parentHeight:2=
		(
			if theMap[theNodeIndex] == true do return false
			case AutoReorderPattern of
			(
				#tree:
				(
					theActualOffset = case of
					(
						(maxLinks == 1): parentDir 
						(maxLinks == 2): if theXOffset == 1 then -1 else 1
						(maxLinks == 3): if theXOffset == 1 then -2 else if theXOffset == 2 then 0 else 2
						default: ((theXOffset-maxLinks/2.0) as integer)
					)				
				)
				#vtree:
				(
					theActualOffset = case of
					(
						--(maxLinks == 1): parentDir 
						(maxLinks == 2): if theXOffset == 1 then -1 else 1
						(maxLinks == 3): if theXOffset == 1 then -2 else if theXOffset == 2 then 0 else 2
						default: ((theXOffset-maxLinks/2.0) as integer)
					)				
				)				
				#pyramidal:
				(
					theActualOffset = case of
					(
						(maxLinks == 1): 0
						(maxLinks == 2): if theXOffset == 1 then -2 else 0
						(maxLinks == 3): if theXOffset == 1 then -2 else if theXOffset == 2 then 0 else 2
						default: ((theXOffset-maxLinks/2.0) as integer)
					)
				)
			)
			local theNewX = theRefPos.x-theActualOffset
			local theNewY = theRefPos.y+ParentHeight
			while try(theGridMap[theNewX][theNewY] != undefined or theGridMap[theNewX+1][theNewY] != undefined )catch(false) do theNewX -= 1
--			while theGridMap[theNewX][theNewY] == true do theNewY += 1
			--theGridMap[theNewX][theNewY] = theNodeIndex
			--theGridMap[theNewX+1][theNewY] = theNodeIndex
			
			
			if KrakatoaChannelEditor_DisplayNodeTreeData[theNodeIndex] != undefined do
			(
				if AllowSocketFlipping then
				(
					if AutoReorderPattern == #tree or AutoReorderPattern == #vtree then
						KrakatoaChannelEditor_DisplayNodeTreeData[theNodeIndex][4][14] = theActualOffset <= 1
					else
						KrakatoaChannelEditor_DisplayNodeTreeData[theNodeIndex][4][14] = theActualOffset == 0 
				)	
				local theLinks = for i = 1 to KrakatoaChannelEditor_DisplayNodeTreeData[theNodeIndex][2].count where KrakatoaChannelEditor_DisplayNodeTreeData[theNodeIndex][2][i] != undefined and KrakatoaChannelEditor_DisplayNodeTreeData[theNodeIndex][2][i] > 0 collect i
				theLinks = (theLinks as bitarray) as array
				/*
				local additionalYOffset = if KrakatoaChannelEditor_DisplayNodeTreeData[theNodeIndex][1] == "BlackOp" then
				(
					theSocketCount = (for j in KrakatoaChannelEditor_DisplayNodeTreeData[theNodeIndex][3][2] where j[1] == "Connector" collect j).count
					if theSocketCount > 3 then ((theSocketCount-2)/2) as integer else 0
				)else 0
				*/
				
				local theHeightFactor = if operatorHeightConstant then
					case (getInputCount KrakatoaChannelEditor_DisplayNodeTreeData[theNodeIndex]) of
					(
						0: 4
						1: 8
						2: 8
						3: 8
						default: ((getInputCount KrakatoaChannelEditor_DisplayNodeTreeData[theNodeIndex])+1)*2
					)	
				else
					case (getInputCount KrakatoaChannelEditor_DisplayNodeTreeData[theNodeIndex]) of
					(
						0: 4
						1: 5
						2: 6
						3: 8
						default: ((getInputCount KrakatoaChannelEditor_DisplayNodeTreeData[theNodeIndex])+1)*2
					)	
				theHeightFactor+=(NodeYSpace-1)
				for j = theNewY to theNewY+theHeightFactor-1 do 
				(
					theGridMap[theNewX][j] = theNodeIndex
					theGridMap[theNewX+1][j] = theNodeIndex
				)	
					
				for i = 1 to theLinks.count do
				(
					local theConnected = theLinks[i]
					if theConnected <= KrakatoaChannelEditor_DisplayNodeTreeData.count do
						setNodePositionRecursiveTree KrakatoaChannelEditor_DisplayNodeTreeData[theNodeIndex][2][theConnected] [theNewX,theNewY] i theLinks.count parentDir:theActualOffset parentHeight:theHeightFactor
				)	
			)	
			theMap[theNodeIndex] = true
		)

		
	
		fn setNodePositionRecursive theNodeIndex theRefPos =
		(
			if theMap[theNodeIndex] == true do return false
			if AutoReorderPattern != #rowtopalign do 
				while theGridMap[theRefPos.x].count < theRefPos.y-1 do append theGridMap[theRefPos.x] 0
			--for i = 1 to NodeYSpace-1 do append theGridMap[theRefPos.x] 0
				
			append theGridMap[theRefPos.x] theNodeIndex
			theYIndex = theGridMap[theRefPos.x].count
			if theYIndex > 1 and (try(KrakatoaChannelEditor_DisplayNodeTreeData[theGridMap[theRefPos.x][theYIndex-1]][1] == "Operator" and  KrakatoaChannelEditor_DisplayNodeTreeData[theGridMap[theRefPos.x][theYIndex-1]][4][2]!=true)catch(false)) do 
			(
					append theGridMap[theRefPos.x] theNodeIndex
			)	

			if theYIndex > 1 and (try(KrakatoaChannelEditor_DisplayNodeTreeData[theGridMap[theRefPos.x][theYIndex-1]][1] == "BlackOp" and KrakatoaChannelEditor_DisplayNodeTreeData[theGridMap[theRefPos.x][theYIndex-1]][4][2]!=true)catch(false)) do 
			(
				for i = 1 to KrakatoaChannelEditor_DisplayNodeTreeData[theGridMap[theRefPos.x][theYIndex-1]][2].count*0.7 do
				(
					append theGridMap[theRefPos.x] theNodeIndex
				)	
			)
			if KrakatoaChannelEditor_DisplayNodeTreeData[theNodeIndex] != undefined do
			(
				if AllowSocketFlipping do KrakatoaChannelEditor_DisplayNodeTreeData[theNodeIndex][4][14] = false
				local theLinks = for i = 1 to KrakatoaChannelEditor_DisplayNodeTreeData[theNodeIndex][2].count where KrakatoaChannelEditor_DisplayNodeTreeData[theNodeIndex][2][i] != undefined and KrakatoaChannelEditor_DisplayNodeTreeData[theNodeIndex][2][i] > 0 collect i
				theLinks = (theLinks as bitarray) as array
				for i = 1 to theLinks.count do
				(
					local theConnected = theLinks[i]
					if theConnected <= KrakatoaChannelEditor_DisplayNodeTreeData.count do
						setNodePositionRecursive KrakatoaChannelEditor_DisplayNodeTreeData[theNodeIndex][2][theConnected] [theRefPos.x+2,theYIndex]
				)	
			)	
			theMap[theNodeIndex] = true
		)

		fn weightedReorder theIndex =
		(
			local thePos = KrakatoaChannelEditor_DisplayNodeTreeData[theIndex][4][1]
			local theAverageY = 0
			local theAverageCount = 0
			for i in KrakatoaChannelEditor_DisplayNodeTreeData[theIndex][2] where i != undefined and i > 0 and i <= KrakatoaChannelEditor_DisplayNodeTreeData.count do
			(
				weightedReorder i
				hc.ActiveNode = i
				local thePos = KrakatoaChannelEditor_DisplayNodeTreeData[i][4][1].y
				local theHeight = if KrakatoaChannelEditor_DisplayNodeTreeData[i][4][2] == true then hc.nodeCollapsedSize.y else hc.nodeSize.y
				theAverageY += thePos+theHeight*0.5
				theAverageCount += 1
			)
			if theAverageCount > 0 do 
			(
				thePos.y = theAverageY/theAverageCount 
				hc.ActiveNode = theIndex
				if theAverageCount > 1 do thePos.y -= if KrakatoaChannelEditor_DisplayNodeTreeData[theIndex][4][2] == true then hc.nodeCollapsedSize.y/2 else hc.nodeSize.y/2
				KrakatoaChannelEditor_DisplayNodeTreeData[theIndex][4][1] = thePos
			)
		)
		local fixedOverlapping = false
		fn fixOverlapping theIndex =
		(
			--if KrakatoaChannelEditor_DisplayNodeTreeData[theIndex][1] == "Input" do return false
			local thePos1 = KrakatoaChannelEditor_DisplayNodeTreeData[theIndex][4][1]
			hc.ActiveNode = theIndex
			local theHeight1 = if KrakatoaChannelEditor_DisplayNodeTreeData[theIndex][4][2] == true then hc.nodeCollapsedSize.y else hc.nodeSize.y
			for j = 2 to KrakatoaChannelEditor_DisplayNodeTreeData.count do
			(
				if theIndex != j and theMap[j] == true and theMap[theIndex] == true do
				(
					thePos2 =  KrakatoaChannelEditor_DisplayNodeTreeData[j][4][1]
					hc.ActiveNode = j
					local theHeight2 = if KrakatoaChannelEditor_DisplayNodeTreeData[j][4][2] == true then hc.nodeCollapsedSize.y else hc.nodeSize.y
					theBox2 = (Box2 thePos2 (thePos2+[NodeWidth,theHeight2]))
					if contains theBox2 thePos1 do 
					(
						thePos1.y = thePos2.y + theHeight2 + 10 
						KrakatoaChannelEditor_DisplayNodeTreeData[theIndex][4][1] = thePos1
						fixedOverlapping = true
					)
					if contains theBox2 (thePos1+[NodeWidth,theHeight1]) do
					(
						thePos1.y = thePos2.y - theHeight1 - 10
						KrakatoaChannelEditor_DisplayNodeTreeData[theIndex][4][1] = thePos1						
						fixedOverlapping = true
					)
				)	
			)			
			for i in KrakatoaChannelEditor_DisplayNodeTreeData[theIndex][2] where i != undefined and i > 0 and i <= KrakatoaChannelEditor_DisplayNodeTreeData.count do
			(
				fixOverlapping i
			)		
			true			
		)
		
		local alignAllNodesToGrid
		
		fn autoReorderFlow createUndo:true =
		(
			theMap = #{}
			alreadyProcessed = #{}
			theGridMap = #()
			for i = 1 to KrakatoaChannelEditor_DisplayNodeTreeData.count do KrakatoaChannelEditor_DisplayNodeTreeData[i][4][7] = true
			for i = 1 to KrakatoaChannelEditor_DisplayNodeTreeData.count*10 do append theGridMap #()
			local theOutputIndex = 1
			if KrakatoaChannelEditor_DisplayNodeTreeData[1][1] != "Output" then 
				for i = 1 to KrakatoaChannelEditor_DisplayNodeTreeData.count do 
					if matchPattern KrakatoaChannelEditor_DisplayNodeTreeData[i][1] pattern:"*Output*" do (theOutputIndex = i; exit)
			
			case AutoReorderPattern of
			(
				#pyramidal:
				(
					theMapOffset = KrakatoaChannelEditor_DisplayNodeTreeData.count*2
					setNodePositionRecursiveTree theOutputIndex [theMapOffset,-1] 0 1
					theYMultiplier = 10
				)	
				#tree:
				(
					theMapOffset = KrakatoaChannelEditor_DisplayNodeTreeData.count*2
					setNodePositionRecursiveTree theOutputIndex [theMapOffset,-1] 0 1
					theYMultiplier = 10
				)	
				#vtree:
				(
					theMapOffset = KrakatoaChannelEditor_DisplayNodeTreeData.count*2
					setNodePositionRecursiveTree theOutputIndex [theMapOffset,-1] 0 1
					theYMultiplier = 10
				)					
				default:
				(
					theMapOffset = 3
					setNodePositionRecursive theOutputIndex [1,1]
					theYMultiplier = 40+((NodeYSpace-1)*5)
				)	
			)	
			
			local theOffset = case UnconnectedNodesPlacement of
			(
				default: [0,0]
				#right: [NodeWidth+NodeXSpace,0]
			)
			for x = 1 to theGridMap.count do
			(
				for y = 1 to theGridMap[x].count do
				(
					local theNodeIndex = theGridMap[x][y]
					if theNodeIndex != undefined and theNodeIndex > 0 and KrakatoaChannelEditor_DisplayNodeTreeData[theNodeIndex] != undefined and not alreadyProcessed[theNodeIndex] do
					(
						KrakatoaChannelEditor_DisplayNodeTreeData[theNodeIndex][4][1] = [(KrakatoaChannelNodeEditor_Rollout.hc.width+NodeXSpace)-(x-theMapOffset+2)*((NodeWidth+NodeXSpace)*0.5), 10+y*theYMultiplier] - theOffset
						theMap[theNodeIndex] = true
						if AutoReorderPattern == #pyramidal or AutoReorderPattern == #tree or  AutoReorderPattern == #vtree do alreadyProcessed[theNodeIndex] = true
					)	
				)
			)
			
			if AutoReorderPattern == #rowweighted do 
			(
				weightedReorder 1
				local DoneFixing = false
				local cnt = 0
				
				while not DoneFixing do 
				(
					cnt +=1
					fixedOverlapping = false
					fixOverlapping 1
					if cnt > 50 or fixedOverlapping == false do DoneFixing  = true
				)
				--format "% iterations\n" cnt
			)
			
			try
			(
				local theXArray = (for i in theMap collect KrakatoaChannelEditor_DisplayNodeTreeData[i][4][1].x)
				local theYArray = (for i in theMap collect KrakatoaChannelEditor_DisplayNodeTreeData[i][4][1].y)
			)catch(theXArray = theYArray = #(100))	
			local minX = amin theXArray
			local minY = amin theYArray 
			local maxX = amax theXArray
			local maxY = amax theYArray 
			
			--format "minX:% minY:% maxX:% maxY:%\n" minX minY maxX maxY
			
			local cnt = case AutoReorderPattern of
			(
				default: if UnconnectedNodesPlacement == #left or UnconnectedNodesPlacement == #right then 0 else 0
				#pyramidal: if UnconnectedNodesPlacement == #bottom then -1 else 1
				#tree: if UnconnectedNodesPlacement == #bottom then -1 else 1		
				#vtree: if UnconnectedNodesPlacement == #bottom then -1 else 1		
			)
			local cnt2 = case AutoReorderPattern of
			(
				default: if UnconnectedNodesPlacement == #left then 1 else if UnconnectedNodesPlacement == #right then 0 else 0
				#pyramidal: if UnconnectedNodesPlacement == #bottom then 0 else 1
				#tree: if UnconnectedNodesPlacement == #bottom then 0 else 1
				#vtree: if UnconnectedNodesPlacement == #bottom then 0 else 1
			)
			local defaultCnt = cnt
			for i = 2 to KrakatoaChannelEditor_DisplayNodeTreeData.count where theMap[i] == false do 
			(
				case UnconnectedNodesPlacement of
				(
					#left: (
						KrakatoaChannelEditor_DisplayNodeTreeData[i][4][1] = [minX, minY] + [-cnt2*(NodeWidth+NodeXSpace),cnt*40]
						cnt += if KrakatoaChannelEditor_DisplayNodeTreeData[i][1] == "Operator"  then 2 else 1
					)		
					#right: (
						KrakatoaChannelEditor_DisplayNodeTreeData[i][4][1] = [maxX, minY] + [(cnt2)*(NodeWidth+NodeXSpace),cnt*40]
						cnt += if KrakatoaChannelEditor_DisplayNodeTreeData[i][1] == "Operator"  then 2 else 1
					)	
					#bottom: (
						KrakatoaChannelEditor_DisplayNodeTreeData[i][4][1] = [maxX, maxY] + [-(cnt+1)*(NodeWidth+NodeXSpace),40*(cnt2+1)]
						cnt += 1
					)
				)	
				KrakatoaChannelEditor_DisplayNodeTreeData[i][4][7] = false
				if UnconnectedNodesPlacement == #bottom and cnt > KrakatoaChannelNodeEditor_Rollout.hc.width/(NodeWidth+NodeXSpace) do
				(
					cnt = defaultCnt
					cnt2 += 1
				)
				if UnconnectedNodesPlacement == #left and cnt > KrakatoaChannelNodeEditor_Rollout.hc.height/80 do
				(
					cnt = defaultCnt
					cnt2 += 1
				)							
			)
			createNodeTree init:true
			alignAllNodesToGrid createUndo:false
			if createUndo do createUndoRecord ("Reorder Nodes")
		)
		
		local theDebugFile 
		local stopRecursion = 0
		local recursionCounter = 0
		local recursionMap = #()
		
		fn followFlowRecursive theParent TheChild =
		(
			for i in KrakatoaChannelEditor_DisplayNodeTreeData[TheChild][2] where i != undefined and i > 0 do --for every ingoing connection, follow downstream
			(
				if theParent != i then --if the connection is not the parent, continue following
				(
					recursionCounter +=1
					recursionMap[i] += 1
					if recursionMap[i] > 10 do 
					(
						exit
					)
					if recursionCounter >= 255 do 
					(
						exit
					)
					followFlowRecursive theParent i					
				)	
				else
				(
					stopRecursion = theParent --if found a cyclic connection to the parent, note where
					exit
				)	
			)	
			true
		)
		
		fn checkForCyclicConnections =
		(
			for i = 2 to KrakatoaChannelEditor_DisplayNodeTreeData.count do	--for every node in the tree,
			(
				for i = 1 to KrakatoaChannelEditor_DisplayNodeTreeData.count do recursionMap[i] = 0
				stopRecursion = 0
				recursionCounter = 0
				followFlowRecursive i i	--start from this node, specifying it as the root, too.
				if stopRecursion > 0 do 
				(
					exit
				)
			)
			stopRecursion
		)
		
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--DELETE NODES FUNCTIONS--
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
		fn deleteSelectedNodes createUndo:true=
		(
			local expandedFlow = execute (KrakatoaChannelsEditor_Functions.expandFlow (with PrintAllElements true KrakatoaChannelEditor_DisplayNodeTreeData as string) fixTracks:true)
			local oldExposure = for i = 1 to expandedFlow.count where expandedFlow[i][4][12] == true collect i
			
			KrakatoaChannelEditor_LastError = #(0,"","")
			theIndices = for i = 2 to KrakatoaChannelEditor_DisplayNodeTreeData.count collect 
			(
				hc.ActiveNode = i
				if hc.isSelected then i else dontcollect
			)
			sort theIndices
			for index in theIndices.count to 1 by -1 do
			(
				for i = 1 to KrakatoaChannelEditor_DisplayNodeTreeData.count do
				(
					for j = 1 to KrakatoaChannelEditor_DisplayNodeTreeData[i][2].count do
					(
						if KrakatoaChannelEditor_DisplayNodeTreeData[i][2][j] == theIndices[index] do
							KrakatoaChannelEditor_DisplayNodeTreeData[i][2][j] = 0
						if KrakatoaChannelEditor_DisplayNodeTreeData[i][2][j] != undefined and KrakatoaChannelEditor_DisplayNodeTreeData[i][2][j] > theIndices[index] do
							KrakatoaChannelEditor_DisplayNodeTreeData[i][2][j] -= 1
					)	
				)
				deleteItem KrakatoaChannelEditor_DisplayNodeTreeData theIndices[index]
			)				
			createNodeTree init:true	
			if AutoReorderToggle do autoReorderFlow createUndo:false
			if AutoZoomExtents do zoomExtents createUndo:false
			if createUndo do 	
				if theIndices.count == 1 then
					createUndoRecord ("Delete One Selected Node")
				else
					createUndoRecord ("Delete " + theIndices.count as string + " Selected Nodes")
			local expandedFlow = execute (KrakatoaChannelsEditor_Functions.expandFlow (with PrintAllElements true KrakatoaChannelEditor_DisplayNodeTreeData as string) fixTracks:true)
			local newExposure = for i = 1 to expandedFlow.count where expandedFlow[i][4][12] == true collect i
			if newExposure as string != oldExposure as string then
				KrakatoaChannelsEditor_Functions.exposeControlsToModifier KrakatoaChannelNodeEditor_CurrentModifier
			else
				if chk_autoUpdateModifier.checked do KrakatoaChannelsEditor_Functions.updateParentModifier()
		
			displaySelectedNodeProperties()
		)
		
		
		fn removeNode deleteTheNode:true=
		(
			KrakatoaChannelEditor_LastError = #(0,"","")
			theIndices = for i = 1 to KrakatoaChannelEditor_DisplayNodeTreeData.count collect 
			(
				hc.ActiveNode = i
				if hc.isSelected and KrakatoaChannelEditor_DisplayNodeTreeData[i][1] != "Output" and KrakatoaChannelEditor_DisplayNodeTreeData[i][1] != "OutputConnector" then i else dontcollect
			)
			if theIndices.count > 0 do
			(
				local expandedFlow = execute (KrakatoaChannelsEditor_Functions.expandFlow (with PrintAllElements true KrakatoaChannelEditor_DisplayNodeTreeData as string) fixTracks:true)
				local oldExposure = for i = 1 to expandedFlow.count where expandedFlow[i][4][12] == true collect i
				
				sort theIndices
				for index in theIndices.count to 1 by -1 do --loop backwards through all nodes selected for removal
				(
					hc.ActiveNode = theIndices[index] --activate the current node
					if KrakatoaChannelEditor_DisplayNodeTreeData[theIndices[index]][2][1] != undefined and KrakatoaChannelEditor_DisplayNodeTreeData[theIndices[index]][2][1] > 1  do
					(
						hc.activeSocket = hc.getSocketCount --set the OUTPUT socket as active
						local theConnectionIndices = hc.getActiveSocketConnectingNodeIndices --get the indices of the nodes connected to the output
						for j in theConnectionIndices do --go through all nodes connected to the output and retarget them to connect to the first input of the node to be deleted.
						(
							local theIndex = try(findItem KrakatoaChannelEditor_DisplayNodeTreeData[j][2] theIndices[index])catch(0)
							if theIndex > 0 do
								KrakatoaChannelEditor_DisplayNodeTreeData[j][2][theIndex] = KrakatoaChannelEditor_DisplayNodeTreeData[theIndices[index]][2][1]
						)	
					)				
					for i = 1 to KrakatoaChannelEditor_DisplayNodeTreeData.count do
					(
						for j = 1 to KrakatoaChannelEditor_DisplayNodeTreeData[i][2].count do
						(
							if KrakatoaChannelEditor_DisplayNodeTreeData[i][2][j] == theIndices[index] do
								KrakatoaChannelEditor_DisplayNodeTreeData[i][2][j] = 0
							
							if deleteTheNode and KrakatoaChannelEditor_DisplayNodeTreeData[i][2][j] != undefined and KrakatoaChannelEditor_DisplayNodeTreeData[i][2][j] > theIndices[index] do
								KrakatoaChannelEditor_DisplayNodeTreeData[i][2][j] -= 1
						)	
					)
					if deleteTheNode then
						deleteItem KrakatoaChannelEditor_DisplayNodeTreeData theIndices[index]
					else
						KrakatoaChannelEditor_DisplayNodeTreeData[theIndices[index]][2]=#(0,0,0)
				)				
				createNodeTree init:true	
				if AutoReorderToggle do autoReorderFlow createUndo:false
				if AutoZoomExtents do zoomExtents createUndo:false
				if theIndices.count  == 1 then
					createUndoRecord ("Remove Selected Node" + (if not deleteTheNode then " from Flow." else ".") )	
				else
					createUndoRecord ("Remove " + theIndices.count as string + " Selected Nodes" + (if not deleteTheNode then " from Flow" else ""))	
				local expandedFlow = execute (KrakatoaChannelsEditor_Functions.expandFlow (with PrintAllElements true KrakatoaChannelEditor_DisplayNodeTreeData as string) fixTracks:true)
				local newExposure = for i = 1 to expandedFlow.count where expandedFlow[i][4][12] == true collect i
				if newExposure as string != oldExposure as string then
					KrakatoaChannelsEditor_Functions.exposeControlsToModifier KrakatoaChannelNodeEditor_CurrentModifier
				else 
					if chk_autoUpdateModifier.checked do KrakatoaChannelsEditor_Functions.updateParentModifier()			
					
				displaySelectedNodeProperties()						
			)	
		)

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--ADDING NODES FUNCTIONS
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
		
		local lastSelection = #(0)
		fn updateNodeSelection createUndo:true = 
		(
			hc.drawLastIndex = 1
			for i = KrakatoaChannelEditor_DisplayNodeTreeData.count to 1 by -1 do 
			(
				hc.activeNode = i	
				if hc.isSelected do 
				(
					hc.drawLastIndex = i
					if SnapToGrid == true do
					(
						thePos = hc.activeNodePos
						thePos.x = (floor (thePos.x/GridSizeX))*GridSizeX
						thePos.y = (floor (thePos.y/GridSizeY))*GridSizeY
						hc.activeNodePos = thePos
					)
				)	
				
				if theNodeInvisibilityList[i] == false do KrakatoaChannelEditor_DisplayNodeTreeData[i][4][1] = hc.activeNodePos
				KrakatoaChannelEditor_DisplayNodeTreeData[i][4][2] = hc.activeNodeCollapsed 
				KrakatoaChannelEditor_DisplayNodeTreeData[i][4][3] = hc.isSelected 
			)
			
			if lastSelection as string != (getSelectedNodes()) as string do
			(
				lastSelection = getSelectedNodes()
				if createUndo do 
					case of
					(
						(lastSelection.count == 0): createUndoRecord ("Select No Nodes")
						(lastSelection.count == 1): createUndoRecord ("Select "+ KrakatoaChannelEditor_DisplayNodeTreeData[lastSelection[1]][1] + " Node ["+ KrakatoaChannelEditor_DisplayNodeTreeData[lastSelection[1]][4][8] as string +"]")
						(lastSelection.count > 1): createUndoRecord ("Select "+lastSelection.count as string+ " Nodes")
					)	
				displaySelectedNodeProperties()
			)
			hc.redrawView
		)		
		

		
		fn deleteTrackViewControllers nodeID =
		(
			theRootNode = try(trackViewNodes.KrakatoaChannelEditor)catch(newTrackViewNode "KrakatoaChannelEditor")
			theID = KrakatoaChannelNodeEditor_CurrentModifier.trackID
			theModTrack = try(execute ("trackViewNodes.KrakatoaChannelEditor.KCE_"+theID))catch(newTrackViewNode theRootNode ("KCE_"+theID))
			theNodeTrack = try(execute ("trackViewNodes.KrakatoaChannelEditor.KCE_"+theID+".Input_"+nodeID as string))catch(newTrackViewNode theModTrack ("Input_"+nodeID as string) )
			deleteTrackViewNode theModTrack theNodeTrack
		)
		
		fn connectSelectedNodes =
		(
			local theSelection = getSelectedNodes()
			if theSelection.count == 2 do
			(
				local theTarget = undefined
				local theSource = undefined
				if matchPattern KrakatoaChannelEditor_DisplayNodeTreeData[theSelection[1]][1] pattern:"Output" then
				(
					theTarget = theSelection[1]
					theSource = theSelection[2]
				)					
				else if matchPattern KrakatoaChannelEditor_DisplayNodeTreeData[theSelection[2]][1] pattern:"Output" then
				(
					theTarget = theSelection[2]
					theSource = theSelection[1]					
				)
				else if not keyboard.shiftPressed then
				(
					if matchPattern KrakatoaChannelEditor_DisplayNodeTreeData[theSelection[2]][1] pattern:"*Op*" then 
					(
						theTarget = theSelection[2]
						theSource = theSelection[1]
					)	
					else if matchPattern KrakatoaChannelEditor_DisplayNodeTreeData[theSelection[1]][1] pattern:"*Op*" then 
					(
						theTarget = theSelection[1]
						theSource = theSelection[2]
					)						
				)
				else
				(
					if matchPattern KrakatoaChannelEditor_DisplayNodeTreeData[theSelection[1]][1] pattern:"*Op*" then 
					(
						theTarget = theSelection[1]
						theSource = theSelection[2]
					)	
					else if matchPattern KrakatoaChannelEditor_DisplayNodeTreeData[theSelection[2]][1] pattern:"*Op*" then 
					(
						theTarget = theSelection[2]
						theSource = theSelection[1]
					)	
				)	
				if theTarget != undefined do
				(
					local theSockets = KrakatoaChannelEditor_DisplayNodeTreeData[theTarget][2]
					if matchPattern KrakatoaChannelEditor_DisplayNodeTreeData[theTarget][1]  pattern:"Output" then
					(
						local oldStatus = for i in KrakatoaChannelEditor_DisplayNodeTreeData[theTarget][2] collect i
						KrakatoaChannelEditor_DisplayNodeTreeData[theTarget][2] = #(theSource)
						checkForCyclicConnections() 
						if stopRecursion > 0 do KrakatoaChannelEditor_DisplayNodeTreeData[theTarget][2] = oldStatus						
					)
					else 
					(
						local maxSocketCount = getInputCount KrakatoaChannelEditor_DisplayNodeTreeData[theTarget]

						if keyboard.controlPressed then
						(
							if keyboard.shiftPressed then
							(
								for j = maxSocketCount to 1 by -1 do
								(
									if theSockets[j] == theSource then
									(
										KrakatoaChannelEditor_DisplayNodeTreeData[theTarget][2][j] = 0
										exit
									)								
								)								
							)
							else
							(
								for j = 1 to maxSocketCount do
								(
									if theSockets[j] == theSource then
									(
										KrakatoaChannelEditor_DisplayNodeTreeData[theTarget][2][j] = 0
										exit
									)								
								)
							)
						)
						else
						(
							for j = 1 to maxSocketCount do
							(
								if theSockets[j] == undefined or theSockets[j] < 1 then
								(
									local oldStatus = for i in KrakatoaChannelEditor_DisplayNodeTreeData[theTarget][2] collect i
									KrakatoaChannelEditor_DisplayNodeTreeData[theTarget][2][j] = theSource
									checkForCyclicConnections() 
									if stopRecursion > 0 do KrakatoaChannelEditor_DisplayNodeTreeData[theTarget][2] = oldStatus
									exit
								)
							)
						)
					)	
					createNodeTree init:true
					if AutoReorderToggle do autoReorderFlow createUndo:false
					if AutoZoomExtents do zoomExtents createUndo:false	
					if keyboard.controlPressed then
						createUndoRecord "Disconnect Selected Nodes"					
					else
						createUndoRecord "Connect Selected Nodes"					
				)	
			)
			lbx_log.items = #()
			if chk_autoUpdateModifier.checked do KrakatoaChannelsEditor_Functions.updateParentModifier()	
			createNodeTree init:false
			if stopRecursion > 0 do logInfo ("Prevented Circular Connection In Node " + stopRecursion as string + "...")
		)
		
		fn getNewNodePosition type:#input =
		(
			local theSelection = getSelectedNodes()
			if theSelection.count == 0 do theSelection = for i = 2 to KrakatoaChannelEditor_DisplayNodeTreeData.count collect i
			if theSelection.count > 0 then
			(
				local theX = amin (for i in theSelection where i > 0 collect KrakatoaChannelEditor_DisplayNodeTreeData[i][4][1].x)
				local theY = amax (for i in theSelection where i > 0 collect KrakatoaChannelEditor_DisplayNodeTreeData[i][4][1].y)
				local theNode = for i in theSelection where KrakatoaChannelEditor_DisplayNodeTreeData[i][4][1] == [theX,theY] collect KrakatoaChannelEditor_DisplayNodeTreeData[i][1]
				local theNodeType = if theNode.count > 0 then theNode[1] else "Operator"
			)		
			else
			(
				theNodeType = "Input"
				local theX = 500
				local theY = 40
			)
			theY += if theNodeType == "Input" then 40 else 80
			local theCollisionNode = #(1)
			while theCollisionNode.count > 0 do
			(
				theCollisionNode = #()
				for i = 2 to KrakatoaChannelEditor_DisplayNodeTreeData.count do 
				(
					local theHeight = if KrakatoaChannelEditor_DisplayNodeTreeData[i][1] == "Input" then 30 else 70
					local theBox = Box2 KrakatoaChannelEditor_DisplayNodeTreeData[i][4][1] (KrakatoaChannelEditor_DisplayNodeTreeData[i][4][1]+[100,theHeight])
					if contains theBox [theX,theY] do append theCollisionNode i
				)	
				--format "%\n" theCollisionNode 
				for i in theCollisionNode do 
				(
					local theNodeType = KrakatoaChannelEditor_DisplayNodeTreeData[i][1]
					theY += if theNodeType == "Input" then 40 else 80
				)
			)		
			[theX,theY]
		)
		
		fn addNewInput type:#channel valueType:#float channelName:"Color" creationType:#keyboard defaultValue: makeUndoRecord:true =
		(
			KrakatoaChannelEditor_LastError = #(0,"","")
			local theSelection = getSelectedNodes()
			local thePos = if useMousePositionOnCreation or creationType==#rcmenu then 
				(lastMouseClick - (getDialogPos KrakatoaChannelNodeEditor_Rollout) - [0,40] - hc.pan) /hc.zoom
			else
				getNewNodePosition type:#input 
			seed (timestamp())
			local theNodeID = (random 10000 1000000) as string + "_" + (random 10000 1000000) as string
			case type of
			(
				#channel: append KrakatoaChannelEditor_DisplayNodeTreeData #("Input", #(), #("Channel",channelName), #(thePos, false, true, "", #(1,1,[1,1,1]),undefined,undefined,undefined,channelName,channelName ) , true)
				#value: 
				(
					case valueType of
					(
						#integer: 	(
							if defaultValue == unsupplied do defaultValue = 1
							append KrakatoaChannelEditor_DisplayNodeTreeData #("Input", #(), #("Value","Integer"), #(thePos, false, true, "", #(defaultValue,1,[1,1,1]),undefined,undefined,undefined,"Integer","Color"), true)
							)
						#float: 		
							(
								if defaultValue == unsupplied do defaultValue = 1.0
								append KrakatoaChannelEditor_DisplayNodeTreeData #("Input", #(), #("Value","Float"), #(thePos, false, true, "", #(1,defaultValue,[1,1,1]),undefined,undefined,undefined,"Float","Color"), true)
							)
						#vector: 	
							(
								if defaultValue == unsupplied do defaultValue = [1,1,1]
								append KrakatoaChannelEditor_DisplayNodeTreeData #("Input", #(), #("Value","Vector"), #(thePos, false, true, "", #(1,1,defaultValue),undefined,undefined,undefined,"Vector","Color"), true)
							)
						#connector: 	append KrakatoaChannelEditor_DisplayNodeTreeData #("Connector", #(), #("Value","Value"), #(thePos, false, true, "", #(1,1,[1,1,1]),undefined,undefined,undefined,"Connector","Color"), true)
					)	
				)	
				#time: append KrakatoaChannelEditor_DisplayNodeTreeData #("Input", #(), #("Time","Frame",0), #(thePos, false, true, "", #(1,1,[1,1,1]),undefined,undefined,undefined,"Time","Color"), true)
				#script: append KrakatoaChannelEditor_DisplayNodeTreeData #("Input", #(), #("Script","0"), #(thePos, false, true, "", #(1,1,[1,1,1]),undefined,"0",undefined,"Script","Color" ), true)
				#TextureMap: append KrakatoaChannelEditor_DisplayNodeTreeData #("Input", #(), #("TextureMap",1,"Color"), #(thePos, false, true, "", #(1,1,[1,1,1]),undefined,undefined,undefined,"TextureMap","Color"), true)
				#object: append KrakatoaChannelEditor_DisplayNodeTreeData #("Input", #(), #("Object",""), #(thePos, false, true, "", #(1,1,[1,1,1]),undefined,undefined,undefined,"O","Color"), true)
				#geometry: append KrakatoaChannelEditor_DisplayNodeTreeData #("Input", #(), #("Geometry",#()), #(thePos, false, true, "", #(1,1,[1,1,1]),undefined,undefined,undefined,"Geometry","Color"), true)
				#notes: append KrakatoaChannelEditor_DisplayNodeTreeData #("Notes", #(), #("Notes",#()), #(thePos, false, true, "", #(1,1,[1,1,1]),undefined,undefined,undefined,"Notes","Color"), true)
					
			)	
			local theControllerSignature = KrakatoaChannelsEditor_Functions.createTrackViewControllers theNodeID KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelEditor_DisplayNodeTreeData.count]
			if type == #value do 
				KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelEditor_DisplayNodeTreeData.count][3][3] = theControllerSignature
			KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelEditor_DisplayNodeTreeData.count][4][4] = theNodeID
			createNodeTree init:true
			hc.activeNode = KrakatoaChannelEditor_DisplayNodeTreeData.count
			local newNodeIndex = KrakatoaChannelEditor_DisplayNodeTreeData.count
			if DeselectNodesOnInputDrop and theSelection.count > 0 and creationType != #keyboard then
			(
				for i in theSelection do --where KrakatoaChannelEditor_DisplayNodeTreeData[i][1] == "Input" 
					KrakatoaChannelEditor_DisplayNodeTreeData[i][4][3] = false
			)
			
			KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelEditor_DisplayNodeTreeData.count][4][3] = true

			if theSelection.count == 1 and (KrakatoaChannelEditor_DisplayNodeTreeData[theSelection[1]][1] == "Operator" or KrakatoaChannelEditor_DisplayNodeTreeData[theSelection[1]][1] == "BlackOp")  do
			(
				local maxSocketCount = getInputCount KrakatoaChannelEditor_DisplayNodeTreeData[theSelection[1]]
				local theSockets = KrakatoaChannelEditor_DisplayNodeTreeData[theSelection[1]][2]
				local notConnected = true
				local cnt = 0
				local unconnectedSockets = (for i in theSockets where i == undefined or i < 1 collect i)
				if unconnectedSockets.count <= maxSocketCount and type==#value and valueType==#float and KrakatoaChannelEditor_DisplayNodeTreeData[theSelection[1]][3][1] == "ToVector" then
				(
					for i = 1 to maxSocketCount where  theSockets[i] == undefined or theSockets[i] < 1 do 
					(
						KrakatoaChannelEditor_DisplayNodeTreeData[theSelection[1]][2][i] = newNodeIndex
						if AutoReorderToggle do autoReorderFlow createUndo:false
						if AutoZoomExtents do zoomExtents createUndo:false		
						--createUndoRecord ("Auto-Connect Input Node To Operator's Input Socket "+i as string) playbackDuration:0.1
					)	
					KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelEditor_DisplayNodeTreeData.count][4][3] = false							
				)
				else
				(
					while notConnected do
					(
						cnt += 1
						if cnt <= maxSocketCount then
						(
							if (theSockets[cnt] == undefined or theSockets[cnt] < 1) do
							(
								KrakatoaChannelEditor_DisplayNodeTreeData[theSelection[1]][2][cnt] = newNodeIndex
								KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelEditor_DisplayNodeTreeData.count][4][3] = false
								notConnected = false
								if AutoReorderToggle do autoReorderFlow createUndo:false
								if AutoZoomExtents do zoomExtents createUndo:false		
								--createUndoRecord ("Auto-Connect Input Node to Operator's Input Socket "+ cnt as string) playbackDuration:0.1
							)	
						)
						else
							notConnected = false
					)
					if cnt >= maxSocketCount do 
					(
						KrakatoaChannelEditor_DisplayNodeTreeData[theSelection[1]][4][3] = false
						KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelEditor_DisplayNodeTreeData.count][4][3] = true
					)
				)	
			)
			if theSelection.count == 1 and KrakatoaChannelEditor_DisplayNodeTreeData[theSelection[1]][1] == "Output" do
			(
				KrakatoaChannelEditor_DisplayNodeTreeData[theSelection[1]][2][1] = newNodeIndex
				KrakatoaChannelEditor_DisplayNodeTreeData[theSelection[1]][4][3] = false
			)

			
			--KrakatoaChannelsEditor_Functions.buildDisplayTree()
			createNodeTree init:true
			--updateNodeSelection createUndo:false
			if AutoReorderToggle do autoReorderFlow createUndo:false
			if AutoZoomExtents do zoomExtents createUndo:false				
			if chk_autoUpdateModifier.checked do KrakatoaChannelsEditor_Functions.updateParentModifier()
			createNodeTree init:false
			lbx_log.items = #()
			
			if makeUndoRecord do
			(
				case type of
				(
					#channel: createUndoRecord "Add Channel Input "
					#value: createUndoRecord "Add Value Input"
					#time: createUndoRecord "Add Time Input"
					#script: createUndoRecord "Add Script Input"
					#textureMap: createUndoRecord "Add TextureMap Input"
					#object: createUndoRecord "Add Object Input"
					#geometry: createUndoRecord "Add Geometry Input"
					#note: createUndoRecord "Add Note Input"
				)				
			)			

			--if chk_autoUpdateModifier.checked do KrakatoaChannelsEditor_Functions.updateParentModifier()
			displaySelectedNodeProperties()
		)		
		
		
		fn addNewOperator type:""  creationType:#keyboard selectNewNode:true makeUndoRecord:true =
		(
			KrakatoaChannelEditor_LastError = #(0,"","")
			local theSelection = getSelectedNodes()
			local theType = if type == "" then "Add" else type --if no type was specified, assume Add, otherwise use whatever was passed
			local theConnectArray = if findItem theSelection 1 == 0 and (theSelection.count == 1 or theSelection.count == 2 or theSelection.count == 3) then --if one, two or three nodes are selected and the Output node is not one of them,
			(
				hc.activeNode = theSelection[1] --set the active node to the first selected node
				hc.activeSocket = hc.getSocketCount --set the output socket (which is always the last one) to be the active one
				local theIndices = hc.getActiveSocketConnectingNodeIndices --get the indices of connected nodes 
				
				--decide what to do if Shift is pressed:
				local shiftBehavior = nodeInsertMode --not keyboard.shiftPressed --by default, we will perform the INSERT into the flow if shift is not pressed
				
				
				--unless the only selected node is a Channel of type Integer (like Age or LifeSpan) and the operator is the ToFloat which uses Shift+F to add - then we insert even if Shift was pressed
				/*
				if type == "ToFloat" do shiftBehavior = true
				if type == "ToScalar" do shiftBehavior = true
				if type == "Greater" do shiftBehavior = true
				if type == "Less" do shiftBehavior = true
					*/
					--KrakatoaChannelEditor_DisplayNodeTreeData[theSelection[1]][3][1]=="Channel" and KrakatoaChannelsEditor_Functions.isChannelInteger KrakatoaChannelEditor_DisplayNodeTreeData[theSelection[1]][3][2] and type == "ToFloat" do shiftBehavior = true
				
				--or the only selected node was an Integer value and the operator is ToFloat
				--if KrakatoaChannelEditor_DisplayNodeTreeData[theSelection[1]][3][1]=="Value" and KrakatoaChannelEditor_DisplayNodeTreeData[theSelection[1]][3][2] == "Integer" and type == "ToFloat" do shiftBehavior = true
				
				if theIndices.count == 1 and theSelection.count == 1 and ShiftBehavior do 
				(
					local theIndex = findItem KrakatoaChannelEditor_DisplayNodeTreeData[theIndices[1]][2] theSelection[1]
					if theIndex > 0 do
						KrakatoaChannelEditor_DisplayNodeTreeData[theIndices[1]][2][theIndex] = KrakatoaChannelEditor_DisplayNodeTreeData.count+1
				)
				case theSelection.count of
				(
					1: 
					(
						if type == "" then --if one node is selected and no type is specified, try to figure out what Operator to create:
						(
							theType = case KrakatoaChannelEditor_DisplayNodeTreeData[theSelection[1]][3][2] of
							(
								"Vector": "Normalize"
								"Integer": "ToFloat"
								"Float": "Negate"
								"Density": "Negate"
								"Age": "ToFloat"
								"LifeSpan": "ToFloat"
								"ID": "ToFloat"
								"MtlIndex": "ToFloat"
								"MXSInteger": "ToFloat"
								"MXSFloat": "Negate"
								default: "Magnitude"
							)
							if selectNewNode == true do 
								KrakatoaChannelEditor_DisplayNodeTreeData[theSelection[1]][4][3]=false
							theReturnArray = deepCopy theSelection
							join theReturnArray #(0,0)
						)	
						else --if the type IS specified, connect the only selected node to the first socket, unless the selected node is a Boolean Operator and the type is Switch
						(
							if type == "Switch" and findItem (for i in ::KrakatoaChannelEditor_theDepotNodesArray[9] collect i[5]) KrakatoaChannelEditor_DisplayNodeTreeData[theSelection[1]][3][1] > 0 then
							(
								if selectNewNode == true do 
									KrakatoaChannelEditor_DisplayNodeTreeData[theSelection[1]][4][3]=false
								theReturnArray = deepCopy theSelection
								join #(0,0) theReturnArray 								
							)
							else
							(
								if selectNewNode == true do 
									KrakatoaChannelEditor_DisplayNodeTreeData[theSelection[1]][4][3]=false
								theReturnArray = deepCopy theSelection
								join theReturnArray #(0,0)
							)
						)
					)
					2: 
					(
						if selectNewNode == true do
						(							
							KrakatoaChannelEditor_DisplayNodeTreeData[theSelection[1]][4][3]=false
							KrakatoaChannelEditor_DisplayNodeTreeData[theSelection[2]][4][3]=false
						)
						theReturnArray = deepCopy theSelection
						join theReturnArray #(0)
						if type == "Switch" do 
						(
							local logicArray = (for i in ::KrakatoaChannelEditor_theDepotNodesArray[9] collect i[5]) 
							if findItem logicArray KrakatoaChannelEditor_DisplayNodeTreeData[theSelection[2]][3][1] > 0 then
							(
								local tempItem = theReturnArray[2]
								theReturnArray[2] = theReturnArray[3]
								theReturnArray[3] = tempItem
							)
							else if findItem logicArray KrakatoaChannelEditor_DisplayNodeTreeData[theSelection[1]][3][1] > 0 then
								(
									local tempItem = theReturnArray[1]
									theReturnArray[1] = theReturnArray[3]
									theReturnArray[3] = tempItem
								)
						)
						theReturnArray 
					)
					3: 
					(
						theReturnArray = deepCopy theSelection
						if selectNewNode == true do 						
						(
							KrakatoaChannelEditor_DisplayNodeTreeData[theSelection[1]][4][3]=false
							KrakatoaChannelEditor_DisplayNodeTreeData[theSelection[2]][4][3]=false
							KrakatoaChannelEditor_DisplayNodeTreeData[theSelection[3]][4][3]=false
						)
						if type == "" do theType = "Blend"
						
						if type == "Switch" do 
						(
							local logicArray = (for i in ::KrakatoaChannelEditor_theDepotNodesArray[9] collect i[5]) 
							if findItem logicArray KrakatoaChannelEditor_DisplayNodeTreeData[theSelection[3]][3][1] == 0 then
							(
								if findItem logicArray KrakatoaChannelEditor_DisplayNodeTreeData[theSelection[1]][3][1] > 0 then
								(
									local tempItem = theReturnArray[1]
									theReturnArray[1] = theReturnArray[3]
									theReturnArray[3] = tempItem
								)
								else if findItem logicArray KrakatoaChannelEditor_DisplayNodeTreeData[theSelection[2]][3][1] > 0 then
								(
									local tempItem = theReturnArray[2]
									theReturnArray[2] = theReturnArray[3]
									theReturnArray[3] = tempItem									
								)
							)
						)
						theReturnArray
					)
				)	
			)	
			else
				#(0,0,0)
			if theConnectArray == undefined do theConnectArray = #(0,0,0)
			
			
			local thePos = if useMousePositionOnCreation or creationType==#rcmenu then 
				(KrakatoaChannelNodeEditor_Rollout.lastMouseClick - (getDialogPos KrakatoaChannelNodeEditor_Rollout) - [10, 50] - hc.pan) /hc.zoom
			else
				getNewNodePosition type:#operator	
			/*
			format "LastMouseClick = %\n" KrakatoaChannelNodeEditor_Rollout.lastMouseClick
			format "thePos = %\n" thePos
			format "DialogPos = %\n" (getDialogPos KrakatoaChannelNodeEditor_Rollout)
			format "% %\n" hc.pan hc.zoom
			*/
			
			append KrakatoaChannelEditor_DisplayNodeTreeData #("Operator", #(0,0,0), #(theType), #(thePos,false,selectNewNode,undefined,undefined,undefined,undefined,theType,theType), true)
			
			if theType == "Curve" do 
			(
			)
			
			createNodeTree init:true
			--if AutoReorderToggle do autoReorderFlow createUndo:false
			--if AutoZoomExtents do zoomExtents createUndo:false		
				
			if theSelection.count == 1 and type == "ToVector" and \ --if toVector is added and the only selected node is a float channel, connect it to all 3 sockets:
				( KrakatoaChannelEditor_DisplayNodeTreeData[theSelection[1]][3][2] == "Float" or \
					(KrakatoaChannelEditor_DisplayNodeTreeData[theSelection[1]][3][1] == "Channel" and \
						KrakatoaChannelsEditor_Functions.isChannelFloat KrakatoaChannelEditor_DisplayNodeTreeData[theSelection[1]][3][2]) ) then
			(
				KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelEditor_DisplayNodeTreeData.count][2][1] = theConnectArray[1]
				--if makeUndoRecord == true do createUndoRecord ("AutoConnect First Input Socket") playbackDuration:0.1
				KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelEditor_DisplayNodeTreeData.count][2][2] = theConnectArray[1]
				--if makeUndoRecord == true do createUndoRecord ("AutoConnect Second Input Socket") playbackDuration:0.1
				KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelEditor_DisplayNodeTreeData.count][2][3] = theConnectArray[1]
				--if makeUndoRecord == true do createUndoRecord ("AutoConnect Third Input Socket") playbackDuration:0.1
			)			
			else --otherwise auto-connect as decided previously via theConnectArray, as long as it is not 0,0,0
			(
				KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelEditor_DisplayNodeTreeData.count][2] = theConnectArray
				--if makeUndoRecord == true do 
					--if theConnectArray as string != "#(0, 0, 0)" do createUndoRecord ("AutoConnect") playbackDuration:0.1
			)	
			
			
			createNodeTree init:true
			
			if AutoReorderToggle do autoReorderFlow createUndo:false
			if AutoZoomExtents do zoomExtents createUndo:false	
			if selectNewNode == true do 	
			(
				hc.activeNode = KrakatoaChannelEditor_DisplayNodeTreeData.count
				setSelectedNodes #(KrakatoaChannelEditor_DisplayNodeTreeData.count)
			)
			if makeUndoRecord == true do createUndoRecord ("Add ["+ theType +"] Operator")

			displaySelectedNodeProperties()		
				
			nodeInsertMode = true
			KrakatoaChannelsEditor_Functions.updateEditorTitle()
			
			if chk_autoUpdateModifier.checked do KrakatoaChannelsEditor_Functions.updateParentModifier()
			
		)
		
	
		
--INPUT TWEAKING (SWAPPING, PASS THROUGH)	

		fn disconnectAllInputs single:false =
		(
			local theSelection = getSelectedNodes()
			if single == true do
				if lastNodeClick > 1 then theSelection = #(lastNodeClick) else theSelection = #() 			
			for i in theSelection do
			(
				KrakatoaChannelEditor_DisplayNodeTreeData[i][2] = #(0,0,0)
			)		
			if theSelection.count > 0 do
			(
				createNodeTree init:true
				if AutoReorderToggle do autoReorderFlow createUndo:false
				if AutoZoomExtents do zoomExtents createUndo:false	
				createUndoRecord "Delete All Inputs"
				if single == false do setSelectedNodes theSelection
				if chk_autoUpdateModifier.checked do KrakatoaChannelsEditor_Functions.updateParentModifier()
			)		
		)
		
		fn disconnectAllOutputs single:false =
		(
			local theSelection = getSelectedNodes()
			if single == true do
				if lastNodeClick > 1 then theSelection = #(lastNodeClick) else theSelection = #() 			
			for j = 1 to KrakatoaChannelEditor_DisplayNodeTreeData.count do
			(
				for i in theSelection do
				(
					local theIndex = findItem KrakatoaChannelEditor_DisplayNodeTreeData[j][2] i
					if theIndex > 0 do KrakatoaChannelEditor_DisplayNodeTreeData[j][2][theIndex] = 0
				)		
			)
			if theSelection.count > 0 do
			(
				createNodeTree init:true
				if AutoReorderToggle do autoReorderFlow createUndo:false
				if AutoZoomExtents do zoomExtents createUndo:false	
				createUndoRecord "Delete All Inputs"
				if single == false do setSelectedNodes theSelection
				if chk_autoUpdateModifier.checked do KrakatoaChannelsEditor_Functions.updateParentModifier()
			)			
		)		
		
		
		fn swapInputsOrder single:false Last:false=
		(
			local success = false
			KrakatoaChannelEditor_LastError = #(0,"","")
			local theSelection = getSelectedNodes()
			if single == true do
				if lastNodeClick > 1 then theSelection = #(lastNodeClick) else theSelection = #() 
			for i in theSelection do
			(
				if KrakatoaChannelEditor_DisplayNodeTreeData[i][1] == "Operator" do
				(
					if (Last==true OR keyboard.ShiftPressed) and getInputCount KrakatoaChannelEditor_DisplayNodeTreeData[i] > 2 then
					(
						local temp = KrakatoaChannelEditor_DisplayNodeTreeData[i][2][2]
						KrakatoaChannelEditor_DisplayNodeTreeData[i][2][2] = KrakatoaChannelEditor_DisplayNodeTreeData[i][2][3]
						KrakatoaChannelEditor_DisplayNodeTreeData[i][2][3] = temp						
						success = true
					)
					else if getInputCount KrakatoaChannelEditor_DisplayNodeTreeData[i] > 1 do
					(
						local temp = KrakatoaChannelEditor_DisplayNodeTreeData[i][2][2]
						KrakatoaChannelEditor_DisplayNodeTreeData[i][2][2] = KrakatoaChannelEditor_DisplayNodeTreeData[i][2][1]
						KrakatoaChannelEditor_DisplayNodeTreeData[i][2][1] = temp
						success = true
					)	
				)
			)
			if theSelection.count > 0 and success == true do
			(
				if AutoReorderToggle do autoReorderFlow createUndo:false
				createNodeTree init:true					
				if AutoZoomExtents do zoomExtents createUndo:false	
				createUndoRecord "Swap Operator Inputs"
				if single == false do setSelectedNodes theSelection
				if chk_autoUpdateModifier.checked do KrakatoaChannelsEditor_Functions.updateParentModifier()
			)	
		)
		
		/*
		fn swapOutputConnections =
		(
			local theSelection = getSelectedNodes()
			if theSelection.count == 2 do
			(
				
			)
		)
		*/
		
		fn setPassThrough single:false =
		(
			KrakatoaChannelEditor_LastError = #(0,"","")
			local theSelection = getSelectedNodes()
			if single == true do
				if lastNodeClick > 1 then theSelection = #(lastNodeClick) else theSelection = #() 
			for i in theSelection do
			(
				if KrakatoaChannelEditor_DisplayNodeTreeData[i][1] != "Output" do
				(
					if KrakatoaChannelEditor_DisplayNodeTreeData[i][5] != false then 
						KrakatoaChannelEditor_DisplayNodeTreeData[i][5] = false
					else
						KrakatoaChannelEditor_DisplayNodeTreeData[i][5] = true
				)	
			)
			if theSelection.count > 0 do
			(			
				createNodeTree init:false
				if theSelection.count == 1  then
					createUndoRecord ("Toggle Node ["+ KrakatoaChannelEditor_DisplayNodeTreeData[theSelection[1]][4][8] as string +"] " + (if KrakatoaChannelEditor_DisplayNodeTreeData[theSelection[1]][5] == false then "Off" else "On") )
				else
					createUndoRecord ("Toggle "+theSelection.count as string +" Nodes On/Off")
				if single == false do setSelectedNodes theSelection			
				if chk_autoUpdateModifier.checked do KrakatoaChannelsEditor_Functions.updateParentModifier()
			)	
		)
		
		
		fn alignAllNodesToGrid createUndo:true =
		(
			for i = 1 to KrakatoaChannelEditor_DisplayNodeTreeData.count do 
			(
				hc.activeNode = i	
				thePos = hc.activeNodePos
				thePos.x = (floor (thePos.x/GridSizeX))*GridSizeX
				thePos.y = (floor (thePos.y/GridSizeY))*GridSizeY
				hc.activeNodePos = thePos
				KrakatoaChannelEditor_DisplayNodeTreeData[i][4][1] = hc.activeNodePos
			)	
			createNodeTree init:false
			if createUndo do createUndoRecord ("Align All Nodes To Grid (" + GridSizeX as string + "x" + GridSizeY as string+")")
		)


		fn showGrid enabled =
		(
			local theX = GridSizeX*hc.zoom
			local theY = GridSizeY*hc.zoom

			local theBitmap = bitmap theX theY color:theBackgroundColor 
			
			if enabled and hc.zoom > 0.9 do
			(
				thePixels = for i = 1 to theX collect theGridColor
				setPixels theBitmap [0,0] thePixels
				for i = 1 to theY do 
					setPixels theBitmap [0,i-1] #(theGridColor)
			)
			
			hc.backgroundBitmap = theBitmap
			hc.tileBackground = true
		)
		

		fn toggleSnapToGrid =
		(
			SnapToGrid = not SnapToGrid
			setIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "ParticleChannelEditor" "SnapToGrid" (SnapToGrid as string)
			showGrid SnapToGrid
			hc.redrawView			
		)		


--LOADING AND SAVING FUNCTIONS--
		fn openFlow =
		(
			KrakatoaChannelEditor_DisableDragAndDrop = false
			KrakatoaChannelEditor_LastError = #(0,"","")
			makeDir (Krakatoa_PresetsDirectory+ "\\MagmaFlows\\") all:true
			local theFileName = getOpenFileName caption:"Load Krakatoa MagmaFlow File" filename:(Krakatoa_PresetsDirectory+ "\\MagmaFlows\\Flow.kmf") types:"Krakatoa MagmaFlow File (*.KMF)|*.KMF|All Files (*.*)|*.*"
			if theFileName != undefined do
			(
				local theResult = #yes
				try 
				(
					--createUndoRecord ("Before Opening Flow File [" + getFileNameFile theFileName + "]")
					local theMapPath = (getFileNamePath theFileName + getFileNameFile theFileName  + ".mat") 
					local theMatLib = #()
					if doesFileExist theMapPath do
					(
						local theMatLib = loadTempMaterialLibrary theMapPath
						if KrakatoaChannelNodeEditor_CurrentModifier.TextureMapSources.count >= theMatLib.count then
						(
							theResult = yesnocancelbox ("The current Krakatoa Channels Modifier already contains "+KrakatoaChannelNodeEditor_CurrentModifier.TextureMapSources.count as string + " Texture Maps.\nThe incoming MagmaFlow contains "+theMatLib.count as string+" texture maps.\n\nClick [Yes] to REPLACE the existing maps with the incoming ones.\nClick [No] to KEEP AND USE the existing Texture Maps and APPEND the incoming ones.\nClick [Cancel] to CANCEL LOADING of MagmaFlow and TextureMaps.") title:"Open MagmaFlow: Replace Texture Maps?"
						)
					)
					case theResult of 
					(
						#yes: KrakatoaChannelNodeEditor_CurrentModifier.TextureMapSources = for m in theMatLib collect m
						#no:	KrakatoaChannelNodeEditor_CurrentModifier.TextureMapSources = join (for m in KrakatoaChannelNodeEditor_CurrentModifier.TextureMapSources collect m) (for m in theMatLib collect m)
					)	
					if theResult != #cancel do
					(
						fileIn theFileName
						KrakatoaChannelEditor_BaseNodeTreeData = deepCopy KrakatoaChannelEditor_NodeTreeData
						KrakatoaChannelsEditor_Functions.fixFlowIDsAfterLoading KrakatoaChannelEditor_BaseNodeTreeData
						KrakatoaChannelsEditor_Functions.buildDisplayTree()	
						createNodeTree init:true
						createUndoRecord ("Open Flow File [" + getFileNameFile theFileName + "]")
						resetPanFactor()
						resetZoomFactor()
						showGrid SnapToGrid					
						hc.redrawView							
					)
				)catch()
				KrakatoaChannelsEditor_Functions.exposeControlsToModifier KrakatoaChannelNodeEditor_CurrentModifier
			)		
			displaySelectedNodeProperties()
			if chk_autoUpdateModifier.checked do KrakatoaChannelsEditor_Functions.updateParentModifier()
			setFocus hc
		)
		
		fn saveFlowAs =
		(
			KrakatoaChannelEditor_DisableDragAndDrop = false
			makeDir (Krakatoa_PresetsDirectory+ "\\MagmaFlows\\") all:true
			local theFileName = getSaveFileName caption:"Save Krakatoa MagmaFlow File" filename:(Krakatoa_PresetsDirectory+ "\\MagmaFlows\\Flow.kmf") types:"Krakatoa MagmaFlow File (*.KMF)|*.KMF"
			if theFileName != undefined do
			(
				KrakatoaChannelsEditor_Functions.saveFlow theFileName
			)
			setFocus hc
		)		
		
		fn newFlow =
		(
			local q = querybox "Are you sure you want to start a new flow?" title:"New MagmaFlow"
			if q do 
			(
				--createUndoRecord "Before New Flow Creation"
				KrakatoaChannelEditor_DisplayNodeTreeData = #(#("Output", #(2), #("Color","float16",3), #([500,0],false,false), true )) --,#("Input", #(), #("Channel", "Color"), #([200,100], false, true), true)
				KrakatoaChannelEditor_DisplayNodeTreeData [1][4][8] = "Output"
				--KrakatoaChannelsEditor_Functions.buildDisplayTree()
				createNodeTree init:true
				createUndoRecord "Start New Flow"
				KrakatoaChannelsEditor_Functions.exposeControlsToModifier KrakatoaChannelNodeEditor_CurrentModifier
			)		
			setFocus hc			
		)				
		
		fn selectAllNodes =
		(
			setSelectedNodesInData (for i = 1 to KrakatoaChannelEditor_DisplayNodeTreeData.count collect i)
			createNodeTree init:false
			createUndoRecord "Select All Nodes"				
		)			
		
		fn invertSelection =
		(
			setSelectedNodesInData (getUnSelectedNodes())
			createNodeTree init:false
			createUndoRecord "Invert Node Selection"				
		)
		
		fn selectUnconnectedNodes =
		(
			FlagUnconnectedNodes()
			local theIndices = (for i = 2 to KrakatoaChannelEditor_DisplayNodeTreeData.count where KrakatoaChannelEditor_DisplayNodeTreeData[i][4][7] == false collect i)
			--format "%\n" theIndices
			setSelectedNodesInData theIndices 
			createNodeTree init:false
			case theIndices.count of
			(
				1: createUndoRecord ("Select One Unconnected Node")
				0: createUndoRecord ("No Unconnected Nodes Selected")
				default: createUndoRecord ("Select "+theIndices.count as string +" Unconnected Nodes")
			)
		)
		
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
		
		fn selectExposedInputs =
		(
			local theIndices = (for i = 2 to KrakatoaChannelEditor_DisplayNodeTreeData.count where KrakatoaChannelEditor_DisplayNodeTreeData[i][4][12] == true collect i)
			setSelectedNodesInData theIndices
			createNodeTree init:false
			case theIndices.count of
			(
				1:	createUndoRecord ("Select One Exposed Input Node")
				0:	createUndoRecord ("No Exposed Input Nodes Selected")
				default:	createUndoRecord ("Select "+theIndices.count as string +" Exposed Input Nodes")
			)				
		)		
		
		fn unexposeSelectedInputs =
		(
			local theSel = getSelectedNodes()
			local cnt = 0
			for i in theSel where KrakatoaChannelEditor_DisplayNodeTreeData[i][4][12] == true do 
			(
				KrakatoaChannelEditor_DisplayNodeTreeData[i][4][12] = false
				cnt +=1
			)	
			createNodeTree init:false
			case cnt of
			(
				0:	createUndoRecord ("No Selected Input Nodes Unexposed")
				default:	
				(
					createUndoRecord ("Unexpose "+cnt as string + " of "+ theSel.count as string +" Selected Nodes")
					if KrakatoaChannelEditor_NodeTreeEditingLevel.count == 0 do 
						KrakatoaChannelsEditor_Functions.exposeControlsToModifier KrakatoaChannelNodeEditor_CurrentModifier
				)	
			)				
		)
		
		fn exposeSelectedInputs =
		(
			local theSel = getSelectedNodes()
			local cnt = 0
			for i in theSel where KrakatoaChannelEditor_DisplayNodeTreeData[i][3][1] == "Value" and KrakatoaChannelEditor_DisplayNodeTreeData[i][4][12] != true do 
			(
				KrakatoaChannelEditor_DisplayNodeTreeData[i][4][12] = true
				cnt +=1
			)	
			createNodeTree init:false
			case cnt of
			(
				0:	createUndoRecord ("No Selected Input Nodes Exposed")
				default:	
				(
					createUndoRecord ("Expose "+cnt as string + " of "+ theSel.count as string +" Selected Nodes")
					if KrakatoaChannelEditor_NodeTreeEditingLevel.count == 0 do 
						KrakatoaChannelsEditor_Functions.exposeControlsToModifier KrakatoaChannelNodeEditor_CurrentModifier
				)	
			)				
		)		

		fn selectBlackOpNodesOnly =
		(
			local theIndices = (for i = 2 to KrakatoaChannelEditor_DisplayNodeTreeData.count where KrakatoaChannelEditor_DisplayNodeTreeData[i][1] == "BlackOp" collect i)
			setSelectedNodesInData theIndices
			createNodeTree init:false
			case theIndices.count of
			(
				1:	createUndoRecord ("Select One BlackOp Node")
				0:	createUndoRecord ("No BlackOp Nodes Selected")
				default: createUndoRecord ("Select "+theIndices.count as string+ " BlackOp Nodes")
			)	
		)		
		
		fn deselectAllNodes =
		(
			local theSel = getSelectedNodes()
			if theSel.count > 0 do
			(
				setSelectedNodesInData #()
				--updateNodeSelection createUndo:false
				createNodeTree init:false
				createUndoRecord "Deselect All Nodes"
			)			
		)
		
		global KrakatoaChannelEditor_BLOPArray = #()
		local theWalkArray = #()
		local averagePos = [0,0]
		fn recursiveWalkTheTree theChild =
		(
			if findItem theWalkArray theChild == 0 do 
			(
				append theWalkArray theChild
				for i in KrakatoaChannelEditor_BLOPArray[theChild][2] where i != undefined and i > 0 do
					recursiveWalkTheTree i
			)	
		)
		
		local BLOP_currentCountArray = #()
		fn isSelectionValidBLOP =
		(
			local theRootNode = 0
			local theSel = getSelectedNodes()
			if theSel.count > 1 do
			(
				BLOP_currentCountArray = #()
				KrakatoaChannelEditor_BLOPArray=#()
				local minX = 10000
				local minY = 10000
				averagePos = [0,0]
				local averageCount = 0
				for i in theSel where i > 1 do
				(
					local theNode = deepCopy KrakatoaChannelEditor_DisplayNodeTreeData[i] 
					if theNode[4][1].x < minX do minX = theNode[4][1].x 
					if theNode[4][1].y < minY do minY = theNode[4][1].y
					averagePos += theNode[4][1]
					averageCount += 1
					append KrakatoaChannelEditor_BLOPArray theNode
					append BLOP_currentCountArray i
				)	
				averagePos /= averageCount

				for i = 1 to KrakatoaChannelEditor_BLOPArray.count do
				(
					KrakatoaChannelEditor_BLOPArray[i][4][1] -= averagePos  --[minX,minY]
					KrakatoaChannelEditor_BLOPArray[i][4][1] += [300,100]
					local theCount = getInputCount KrakatoaChannelEditor_BLOPArray[i] 
					for j = 1 to theCount do
					(
						if KrakatoaChannelEditor_BLOPArray[i][2][j] != undefined and KrakatoaChannelEditor_BLOPArray[i][2][j] > 0 then
						(
							local theIndex = findItem BLOP_currentCountArray KrakatoaChannelEditor_BLOPArray[i][2][j]
							if theIndex > 0 then
								KrakatoaChannelEditor_BLOPArray[i][2][j] = theIndex
							else
							(
								local theSocketName = KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelEditor_BLOPArray[i][2][j]][4][8]
								if theSocketName == undefined do theSocketName = KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelEditor_BLOPArray[i][2][j]][3][1]
								append KrakatoaChannelEditor_BLOPArray #("Connector", #(), #(theSocketName,KrakatoaChannelEditor_BLOPArray[i][2][j]), #(), true )
								KrakatoaChannelEditor_BLOPArray[i][2][j] = KrakatoaChannelEditor_BLOPArray.count
							)	
						)
						else 
						(
							theRootNode = 0
							lbx_log.items = append lbx_log.items "--CANNOT SAVE AS BLACK OP: At least one Selected Node contains Unconnected Sockets!"
							lbx_log.selection = lbx_log.items.count
							return 0
						)
					)	
				)					
				for i = 1 to KrakatoaChannelEditor_BLOPArray.count do
				(
					theWalkArray = #()
					recursiveWalkTheTree i
					if theWalkArray.count == KrakatoaChannelEditor_BLOPArray.count then
					(
						theRootNode = i
						lbx_log.items = #()
						return theRootNode
					)
				)
			)				
			if theSel.count > 1 then
				lbx_log.items = append lbx_log.items "--CANNOT SAVE AS BLACK OP: Could Not determine a Root Node!"
			else
				lbx_log.items = append lbx_log.items "--CANNOT SAVE AS BLACK OP: Please select at least two Nodes!"
			
			lbx_log.selection = lbx_log.items.count

			theRootNode
		)
		
		fn saveBLOPDefinition =
		(
			KrakatoaChannelEditor_DisableDragAndDrop = false
			local theResult = isSelectionValidBLOP() 
			if theResult > 0 then
			(
				makeDir (Krakatoa_PresetsDirectory+ "\\BlackOps") all:true
				local theFileName = getSaveFileName caption:"Save BlackOp Definition" filename:(Krakatoa_PresetsDirectory+ "\\BlackOps\\BlackOp.kcb") types:"Krakatoa Channels BlackOp (*.KCB)|*.KCB"
				if theFileName != undefined do
				(
					append KrakatoaChannelEditor_BLOPArray #("OutputConnector", #(theResult), #(), #(), true)
					for i = 1 to KrakatoaChannelEditor_BLOPArray.count do
					(
						if KrakatoaChannelEditor_BLOPArray[i][3][1] == "Script" do KrakatoaChannelEditor_BLOPArray[i][3][2] = KrakatoaChannelEditor_BLOPArray[i][4][6] = (KrakatoaChannelsEditor_Functions.escapeString KrakatoaChannelEditor_BLOPArray[i][4][6])
						if KrakatoaChannelEditor_BLOPArray[i][1] == "Input"  and KrakatoaChannelEditor_BLOPArray[i][3][3]  != undefined do deleteItem KrakatoaChannelEditor_BLOPArray[i][3] 3
					)	
					local theFileHandle = createFile theFileName
					with PrintAllElements true	format "global KrakatoaChannelEditor_BlackOpData = %\n" KrakatoaChannelEditor_BLOPArray to:theFileHandle 
					close theFileHandle
					KrakatoaChannelEditor_BlackOpData = execute ( with PrintAllElements true KrakatoaChannelEditor_BLOPArray as string)
					--KrakatoaChannelNodeEditor_Rollout.updateDepotDefinition()
					KrakatoaChannelsEditor_Functions.KrakatoaChannelEditor_UpdateDepot()					
				)	
			)
		)
		
		fn addNewBLOP creationType:#keyboard useFile:true createUndo:true theFile:""=
		(
			KrakatoaChannelEditor_DisableDragAndDrop = false
			KrakatoaChannelEditor_LastError = #(0,"","")
			local theSelection = getSelectedNodes()
			local theConnectArray = #()
			local thePos = [0,0]
			if creationType == #average then
				thePos = averagePos
			else if useMousePositionOnCreation or creationType==#rcmenu then 
				thePos =(KrakatoaChannelNodeEditor_Rollout.lastMouseClick - (getDialogPos KrakatoaChannelNodeEditor_Rollout) - [10, 50] - hc.pan) / hc.zoom
			else
				thePos = getNewNodePosition()
			
			local theFileName = if useFile then
				getOpenFileName caption:"Load BlackOp Definition" filename:(Krakatoa_PresetsDirectory+ "\\BlackOps\\*.kcb") types:"Krakatoa Channels BlackOp (*.KCB)|*.KCB"
			else 
				theFile
			if theFileName != undefined do
			(
				if useFile or doesFileExist theFile do fileIn theFileName
				local theBLOPDef = deepcopy KrakatoaChannelEditor_BlackOpData
				KrakatoaChannelsEditor_Functions.fixFlowIDsAfterLoading theBLOPDef
				append KrakatoaChannelEditor_DisplayNodeTreeData #("BlackOp", theConnectArray, #((getFileNameFile theFileName),theBLOPDef), #(thePos,false,true,undefined,undefined,undefined,undefined,(getFileNameFile theFileName)), true)
				if createUndo do createUndoRecord ("Add BlackOp From File")					
					
				--get the input count of the new BLOP:	
				local theConnectionCount = getInputCount KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelEditor_DisplayNodeTreeData.count]
			
				
				if theSelection.count > 0 and theConnectionCount > 0 do --if the BLOP has more than 0 inputs and there is any valid selection,
				(
					local theConnectedNodes = for i = 1 to KrakatoaChannelEditor_DisplayNodeTreeData.count where findItem KrakatoaChannelEditor_DisplayNodeTreeData[i][2] theSelection[1] > 0 collect i
					if theConnectedNodes.count == 1 then
					(
						KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelEditor_DisplayNodeTreeData.count][2] = #(theSelection[1])
						local theIndex = findItem KrakatoaChannelEditor_DisplayNodeTreeData[theConnectedNodes[1]][2] theSelection[1]
						KrakatoaChannelEditor_DisplayNodeTreeData[theConnectedNodes[1]][2][theIndex] = KrakatoaChannelEditor_DisplayNodeTreeData.count
						if createUndo do createUndoRecord ("Insert BlackOp Into Existing Connection")
						for i = 2 to theSelection.count do
						(
							if i <= theConnectionCount do 
							(
								append KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelEditor_DisplayNodeTreeData.count][2] theSelection[i]
								if createUndo do createUndoRecord ("Auto-Connect ["+i as string + ":"+KrakatoaChannelEditor_DisplayNodeTreeData[theSelection[i]][4][8] as string +"] To BlackOp ["+KrakatoaChannelEditor_DisplayNodeTreeData.count as string+":"+KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelEditor_DisplayNodeTreeData.count][3][1] +"] Input " + i as string)
							)	
						)		
					)
					else
					(
						for i = 1 to theSelection.count do
							if i <= theConnectionCount do 
							(
								append KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelEditor_DisplayNodeTreeData.count][2] theSelection[i]
								if createUndo do createUndoRecord ("Auto-Connect ["+i as string + ":"+KrakatoaChannelEditor_DisplayNodeTreeData[theSelection[i]][4][8] as string +"] To BlackOp ["+KrakatoaChannelEditor_DisplayNodeTreeData.count as string+":"+KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelEditor_DisplayNodeTreeData.count][3][1] +"] Input " + i as string)
							)	
					)			
					setSelectedNodesInData #(KrakatoaChannelEditor_DisplayNodeTreeData.count)
				)		
				if theFileName != "" then
				(
					createNodeTree init:true
					hc.activeNode = KrakatoaChannelEditor_DisplayNodeTreeData.count
					setSelectedNodes #(KrakatoaChannelEditor_DisplayNodeTreeData.count)
					displaySelectedNodeProperties()			
					if chk_autoUpdateModifier.checked do KrakatoaChannelsEditor_Functions.updateParentModifier()
				)
			)	
			KrakatoaChannelsEditor_Functions.exposeControlsToModifier KrakatoaChannelNodeEditor_CurrentModifier
		)
		
		fn createBLOPInline =
		(
			local theSelection = getSelectedNodes()
			local theResult = isSelectionValidBLOP() 
			print theResult
			if theResult > 0 then
			(
				local oldCount = KrakatoaChannelEditor_DisplayNodeTreeData.count
				append KrakatoaChannelEditor_BLOPArray #("OutputConnector", #(theResult), #(), #(), true)
				for i = 1 to KrakatoaChannelEditor_BLOPArray.count do
				(
					if KrakatoaChannelEditor_BLOPArray[i][3][1] == "Script" do KrakatoaChannelEditor_BLOPArray[i][3][2] = KrakatoaChannelEditor_BLOPArray[i][4][6] = (KrakatoaChannelsEditor_Functions.escapeString KrakatoaChannelEditor_BLOPArray[i][4][6])
					if KrakatoaChannelEditor_BLOPArray[i][1] == "Input"  and KrakatoaChannelEditor_BLOPArray[i][3][3]  != undefined do deleteItem KrakatoaChannelEditor_BLOPArray[i][3] 3
				)	
				KrakatoaChannelEditor_BlackOpData = deepCopy KrakatoaChannelEditor_BLOPArray
				
				addNewBLOP creationType:#average useFile:false createUndo:false
				
				for i = 1 to KrakatoaChannelEditor_DisplayNodeTreeData.count-1 do
				(
					local theIndex = findItem KrakatoaChannelEditor_DisplayNodeTreeData[i][2] (BLOP_currentCountArray[theResult])
					if theIndex > 0 do KrakatoaChannelEditor_DisplayNodeTreeData[i][2][theIndex] = KrakatoaChannelEditor_DisplayNodeTreeData.count
				)
				local theConnectors = for i = 1 to KrakatoaChannelEditor_BlackOpData.count where KrakatoaChannelEditor_BlackOpData[i][1] == "Connector" collect KrakatoaChannelEditor_BlackOpData[i][3][2]
				KrakatoaChannelEditor_DisplayNodeTreeData[KrakatoaChannelEditor_DisplayNodeTreeData.count][2] = theConnectors
				setSelectedNodes theSelection
				deleteSelectedNodes createUndo:false
				setSelectedNodesInData #(KrakatoaChannelEditor_DisplayNodeTreeData.count)
				if AutoReorderToggle do autoReorderFlow createUndo:false
				createNodeTree init:true
				if AutoZoomExtents do zoomExtents createUndo:false				
				createUndoRecord ("Add BlackOp From Selection")	
			)	
		)		
		
		fn copySelectionToClipboard =
		(
			local theSel = getSelectedNodes()
			if theSel.count > 0 do
			(
				local currentCountArray = #()
				KrakatoaChannelEditor_ClipboardArray=#()
				local minX = 10000
				local minY = 10000
				for i in theSel where i > 1 do
				(
					local theNode = deepCopy KrakatoaChannelEditor_DisplayNodeTreeData[i] 
					if theNode[4][1].x < minX do minX = theNode[4][1].x 
					if theNode[4][1].y < minY do minY = theNode[4][1].y
					append KrakatoaChannelEditor_ClipboardArray theNode
					append currentCountArray i
				)	
				for i = 1 to KrakatoaChannelEditor_ClipboardArray.count do
				(
					KrakatoaChannelEditor_ClipboardArray[i][4][1] -= [minX,minY]
					for j = 1 to KrakatoaChannelEditor_ClipboardArray[i][2].count where KrakatoaChannelEditor_ClipboardArray[i][2][j] != undefined and KrakatoaChannelEditor_ClipboardArray[i][2][j] > 0 do
						KrakatoaChannelEditor_ClipboardArray[i][2][j] = findItem currentCountArray KrakatoaChannelEditor_ClipboardArray[i][2][j]
				)
			)	
		)
		
		fn pasteSelectionFromClipboard =
		(
			KrakatoaChannelEditor_LastError = #(0,"","")
			if KrakatoaChannelEditor_ClipboardArray.count > 0 do
			(
				local thePos = (lastMouseClick - (getDialogPos KrakatoaChannelNodeEditor_Rollout) - [0,40] - hc.pan)/hc.zoom --mouse.screenpos
				setSelectedNodes #()
				local theOldCount = KrakatoaChannelEditor_DisplayNodeTreeData.count
				local theArrayToPaste =deepCopy KrakatoaChannelEditor_ClipboardArray
				for i = 1 to theArrayToPaste.count do 
				(
					theArrayToPaste[i][4][1] += thePos 
					if theArrayToPaste[i][3][1] == "Value" do 
					(
						local theOldControllers = for c = 1 to 3 collect
							execute (theArrayToPaste[i][3][3]+"["+c as string+"].controller")
						theArrayToPaste[i][4][4] = theID = (random 10000 1000000) as string + "_" + (random 10000 1000000) as string
						theArrayToPaste[i][3][3] = KrakatoaChannelsEditor_Functions.createTrackViewControllers theID KrakatoaChannelEditor_DisplayNodeTreeData[(KrakatoaChannelEditor_DisplayNodeTreeData.count+1)]
						for c = 1 to 3 do
						(
							local newTrack = execute (theArrayToPaste[i][3][3]+"["+c as string+"]")
							if classof theOldControllers[c] == Float_List then
							(
								try(newTrack.controller[1].controller = copy theOldControllers[c][1].controller)catch()
								try(if (classof theOldControllers[c][2].controller) != float_ListDummyEntry do newTrack.controller[2].controller = copy theOldControllers[c][2].controller)catch()
								newTrack.controller.weight = theOldControllers[c].weight
							)
							else if classof theOldControllers[c] == Point3_List then
							(
								try(newTrack.controller[1].controller = copy theOldControllers[c][1].controller)catch()
								try(if (classof theOldControllers[c][2].controller) != float_ListDummyEntry do newTrack.controller[2].controller = copy theOldControllers[c][2].controller)catch()
								newTrack.controller.weight = theOldControllers[c].weight
							)
							else
								try(newTrack.controller = theOldControllers[c])catch()
						)
					)	
				)
				join KrakatoaChannelEditor_DisplayNodeTreeData theArrayToPaste 
				for i = theOldCount+1 to KrakatoaChannelEditor_DisplayNodeTreeData.count do
					for j = 1 to KrakatoaChannelEditor_DisplayNodeTreeData[i][2].count where KrakatoaChannelEditor_DisplayNodeTreeData[i][2][j] > 0 do
						KrakatoaChannelEditor_DisplayNodeTreeData[i][2][j] += theOldCount
					
				createNodeTree init:true	
				if AutoReorderToggle do autoReorderFlow createUndo:false
				createNodeTree init:false
				setSelectedNodes (for i = theOldCount+1 to KrakatoaChannelEditor_DisplayNodeTreeData.count collect i)
				if AutoZoomExtents do zoomExtents createUndo:false					
				createUndoRecord ("Paste "+ KrakatoaChannelEditor_ClipboardArray.count as string +" Nodes From Clipboard")
				
				if chk_autoUpdateModifier.checked do KrakatoaChannelsEditor_Functions.updateParentModifier()
			)	
		)
		
		
----------------------------------------------------------			
--EVENT HANDLERS
----------------------------------------------------------		
		
		on btn_zoomExtents pressed do ZoomExtents()
		on btn_zoomExtentsSelected pressed do ZoomExtentsSelected()
		on btn_NoZoom pressed do resetZoomFactor()
		on btn_NoPoom pressed do resetPanFactor()
		
		on btn_zoomExtents rightclick do (resetZoomFactor();resetPanFactor())
		on btn_zoomExtentsSelected rightclick do (resetZoomFactor();resetPanFactor())
		on btn_NoZoom rightclick do (resetZoomFactor();resetPanFactor())
		on btn_NoPoom rightclick do (resetZoomFactor();resetPanFactor())
		
		on btn_Undo pressed do undoLastStep()
		on btn_Redo pressed do redoLastStep()
		
		on btn_Undo rightClick do 
		(
			createUndoRCMenu()
			popupMenu KrakatoaChannelEditor_UndoRCMenu pos:mouse.screenpos
		)	
		on btn_Redo rightClick do 
		(
			createRedoRCMenu()
			popupMenu KrakatoaChannelEditor_UndoRCMenu pos:mouse.screenpos
		)			
		
		on hc connectionChanged fromNodeIndex toNodeIndex toSocketID fromSocketID status toSocketCount do
		(
			KrakatoaChannelEditor_LastError = #(0,"","")
			oldStatus = KrakatoaChannelEditor_DisplayNodeTreeData[toNodeIndex][2][toSocketID]
			if status == 1 then
			(
				if KrakatoaChannelEditor_DisplayNodeTreeData[toNodeIndex][1] != "Notes" do --disallow connecting to Note nodes.
					KrakatoaChannelEditor_DisplayNodeTreeData[toNodeIndex][2][toSocketID] = fromNodeIndex
			)
			else
				KrakatoaChannelEditor_DisplayNodeTreeData[toNodeIndex][2][toSocketID] = 0
			checkForCyclicConnections() 
			if stopRecursion > 0 then
			(
				KrakatoaChannelEditor_DisplayNodeTreeData[toNodeIndex][2][toSocketID] = oldStatus
				createNodeTree init:true
				logInfo ("Prevented Circular Connection In Node " + stopRecursion as string + "...")
			)
			else
			(
				createNodeTree init:true
				if AutoReorderToggle do autoReorderFlow createUndo:false		
				if AutoZoomExtents do zoomExtents createUndo:false
				if status == 1 then
					createUndoRecord ("Connect ["+ KrakatoaChannelEditor_DisplayNodeTreeData[fromNodeIndex][1] as string + ":"+ KrakatoaChannelEditor_DisplayNodeTreeData[fromNodeIndex][3][1] as string  +"] to ["+KrakatoaChannelEditor_DisplayNodeTreeData[toNodeIndex][1] as string + ":"+KrakatoaChannelEditor_DisplayNodeTreeData[toNodeIndex][3][1] as string +"]")
				else		
					createUndoRecord ("Disconnect ["+ KrakatoaChannelEditor_DisplayNodeTreeData[fromNodeIndex][1] as string + ":"+ KrakatoaChannelEditor_DisplayNodeTreeData[fromNodeIndex][3][1] as string  +"] from ["+KrakatoaChannelEditor_DisplayNodeTreeData[toNodeIndex][1] as string  + ":"+KrakatoaChannelEditor_DisplayNodeTreeData[toNodeIndex][3][1] as string +"]")
				if chk_autoUpdateModifier.checked do KrakatoaChannelsEditor_Functions.updateParentModifier()	
			)			
		)		
		
		on hc nodesDeleted do
		(
			local needUpdate = false
			KrakatoaChannelEditor_LastError = #(0,"","")
			local expandedFlow = execute (KrakatoaChannelsEditor_Functions.expandFlow (with PrintAllElements true KrakatoaChannelEditor_DisplayNodeTreeData as string) fixTracks:true)
			local oldExposure = for i = 1 to expandedFlow.count where expandedFlow[i][4][12] == true collect i
			
			theIndices = sort (for i = 1 to hc.getDeletedNodeCount collect (hc.getDeletedNodeIndex = i))
			for index in theIndices.count to 1 by -1 do
			(
				if theIndices[index] <= KrakatoaChannelEditor_DisplayNodeTreeData.count and KrakatoaChannelEditor_DisplayNodeTreeData[theIndices[index]][1] != "OutputConnector" and KrakatoaChannelEditor_DisplayNodeTreeData[theIndices[index]][1] != "Output" do
				(
					needUpdate = true
					for i = 1 to KrakatoaChannelEditor_DisplayNodeTreeData.count do
					(
						for j = 1 to KrakatoaChannelEditor_DisplayNodeTreeData[i][2].count do
						(
							if KrakatoaChannelEditor_DisplayNodeTreeData[i][2][j] == theIndices[index] do
								KrakatoaChannelEditor_DisplayNodeTreeData[i][2][j] = 0
							if KrakatoaChannelEditor_DisplayNodeTreeData[i][2][j] != undefined AND KrakatoaChannelEditor_DisplayNodeTreeData[i][2][j] > theIndices[index] do
								KrakatoaChannelEditor_DisplayNodeTreeData[i][2][j] -= 1
						)	
					)
					deleteItem KrakatoaChannelEditor_DisplayNodeTreeData theIndices[index]
				)	
			)	
			if needUpdate then
			(
				if theIndices.count == 1 then
					createUndoRecord ("Delete One Selected Node")				
				else
					createUndoRecord ("Delete " + theIndices.count as string + " Selected Nodes")				
				createNodeTree init:true			
				
				local expandedFlow = execute (KrakatoaChannelsEditor_Functions.expandFlow (with PrintAllElements true KrakatoaChannelEditor_DisplayNodeTreeData as string) fixTracks:true)
				local newExposure = for i = 1 to expandedFlow.count where expandedFlow[i][4][12] == true collect i
				if newExposure as string != oldExposure as string then
					KrakatoaChannelsEditor_Functions.exposeControlsToModifier KrakatoaChannelNodeEditor_CurrentModifier
				else 
					if chk_autoUpdateModifier.checked do KrakatoaChannelsEditor_Functions.updateParentModifier()

				if AutoReorderToggle do autoReorderFlow createUndo:false
				if AutoZoomExtents do zoomExtents createUndo:false
				displaySelectedNodeProperties()
			)	
			else
			(
				if KrakatoaChannelEditor_NodeTreeEditingLevel.count > 0 then
				(
					createNodeTree init:true
					--drawDepot init:true
				)
				else
				(
					createNodeTree init:true
				)
			)
		)

		on hc mouseScroll do
		(
			if hc.zoom > 1.2 do hc.zoom = 1.2
			showGrid SnapToGrid
			drawDepot init:false lock:true
		)
		
		on hc mButtonUp do
		(
			drawDepot init:false lock:false
		)		
		
		on hc mButtonDown do
		(
			drawDepot init:false lock:true
		)			
		
		on hc LButtonDown do
		(
			if not KrakatoaChannelEditor_DisableDragAndDrop  do
			(
				prepareDepotForDragAndDrop()
			)	
			lastSelectionBeforeClick = getSelectedNodes()
			lastMouseClick = mouse.screenpos
		)
		
		on hc LButtonUp do
		(
			local theSel = getSelectedDepotButton()
			try
			(
				hc.setInfo = case theSel.count of
				(
					1: "Depot: " + getFileNameFile theDepotNodes[theSel[1]][5]
					0: "" 
					default: "Multiple Depot Nodes Selected"
				)	
			)catch()
			--handle Depot Category Head clicking
			if theSel.count == 1 and theSel[1] <= theDepotNodes.count and theDepotNodes[theSel[1]][1] == "HEAD" then 
			(
				if (keyboard.ControlPressed and not keyboard.shiftPressed) then
				(
					if (DepotPlacement != #bottomrollup and DepotPlacement != #bottomrollupreverse) do
						for j = 1 to KrakatoaChannelEditor_theDepotNodesArray.count where KrakatoaChannelEditor_theDepotNodesArray[j][1][1]  == "HEAD" do
							KrakatoaChannelEditor_theDepotNodesArray[j][1][6] = false
					for j = 1 to KrakatoaChannelEditor_theDepotNodesArray.count where KrakatoaChannelEditor_theDepotNodesArray[j][1][2] == theDepotNodes[theSel[1]][2] do
						KrakatoaChannelEditor_theDepotNodesArray[j][1][6] = true
				)
				else if keyboard.shiftPressed and not keyboard.ControlPressed then
				(
					for j = 1 to KrakatoaChannelEditor_theDepotNodesArray.count where KrakatoaChannelEditor_theDepotNodesArray[j][1][1]  == "HEAD" do
						KrakatoaChannelEditor_theDepotNodesArray[j][1][6] = true					
				)
				else if keyboard.shiftPressed and keyboard.ControlPressed then
				(
					for j = 1 to KrakatoaChannelEditor_theDepotNodesArray.count where KrakatoaChannelEditor_theDepotNodesArray[j][1][1]  == "HEAD" do
						KrakatoaChannelEditor_theDepotNodesArray[j][1][6] = false							
				)
				else if not keyboard.shiftPressed and not keyboard.ControlPressed then
				(
					for j = 1 to KrakatoaChannelEditor_theDepotNodesArray.count do
					(
						if KrakatoaChannelEditor_theDepotNodesArray[j][1][2] == theDepotNodes[theSel[1]][2] do
						(
							KrakatoaChannelEditor_theDepotNodesArray[j][1][6] = not KrakatoaChannelEditor_theDepotNodesArray[j][1][6]
							if (DepotPlacement == #bottomrollup or DepotPlacement == #bottomrollupreverse) and KrakatoaChannelEditor_theDepotNodesArray[j][1][6] == true do 
							(
								for k = 1 to KrakatoaChannelEditor_theDepotNodesArray.count where k != j do
									KrakatoaChannelEditor_theDepotNodesArray[k][1][6] = false
							)
						)
					)
					
				)	
				updateDepotDefinition()
				createNodeTree init:true
				if AutoZoomExtents do zoomExtents createUndo:false
			)	
			else --handle Depot Drag and Drop
			(
				if not KrakatoaChannelEditor_DisableDragAndDrop  then
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
			if keyboard.shiftPressed do removeNode deleteTheNode:false
				
			--enabling this would kill connection selections. Now dragging nodes in AutoReorder mode will not reorder automatically anymore.
			--if AutoReorderToggle do autoReorderFlow createUndo:false
			if debugModeOn == true do debugFlow()	
			KrakatoaChannelEditor_DisableDragAndDrop = false --enable DND on first mouse move. This prevents from undesired DnD operations on menu commands.
			if (getSelectedNodes()).count > 0 do 
			(
				createNodeTree init:true
			)
		)
		
		fn selectNextNodeByCreationOrder =
		(
			local theSel = getSelectedNodes()
			if theSel.count == 0 do theSelected = 1
			if theSel.count > 0 do theSelected = theSel[theSel.count]
			theSelected +=1
			if theSelected > KrakatoaChannelEditor_DisplayNodeTreeData.count do theSelected = 1
			setSelectedNodes #(theSelected)
			updateNodeSelection createUndo:false
			createNodeTree init:false
			createUndoRecord ("Select Next Node " + theSelected as string )
		)
		
		fn selectPreviousNodeByCreationOrder =
		(
			local theSel = getSelectedNodes()
			if theSel.count == 0 do theSelected = 1
			if theSel.count > 0 do theSelected = theSel[theSel.count]
			theSelected -=1
			if theSelected < 1 do theSelected =  KrakatoaChannelEditor_DisplayNodeTreeData.count
			setSelectedNodes #(theSelected)
			updateNodeSelection createUndo:false
			createNodeTree init:false
			createUndoRecord ("Select Previous Node "	+ theSelected as string )
		)
		
		fn selectChildrenNodesByParent =
		(
			local theSel = getSelectedNodes()
			if theSel.count == 0 do theSel = #(1)
			local newSelection = deepCopy theSel
			for i in theSel do
				for j in KrakatoaChannelEditor_DisplayNodeTreeData[i][2] where j != undefined and j > 0 and  findItem newSelection  j == 0 do
					append newSelection j
			setSelectedNodesInData newSelection
			createNodeTree init:false
			createUndoRecord ("Grow Child Selection From " + theSel.count as string + " to " + newSelection.count as string +" Nodes." )				
		)
		
		fn selectParentNodesByChild =
		(
			local theSel = getSelectedNodes()
			if theSel.count == 0 do return false
			local newSelection = deepCopy theSel
			for i in theSel do
				for j = 1 to KrakatoaChannelEditor_DisplayNodeTreeData.count do
					for k in KrakatoaChannelEditor_DisplayNodeTreeData[j][2] where k == i and findItem newSelection j == 0 do
						append newSelection j
			setSelectedNodesInData newSelection
			createNodeTree init:false
			createUndoRecord ("Grow Parent Selection From " + theSel.count as string + " to " + newSelection.count as string +" Nodes." )					
		)
		
		

--KEYBOARD SHORTCUTS
		
		on hc keyboardDown keyCode do
		(
			--print keycode
			
			if keyCode == 8 and not keyboard.ControlPressed do removeNode deleteTheNode:(not keyboard.ShiftPressed) --Backspace
			
			if keyCode == 32 do connectSelectedNodes() --Spacebar

			if keyCode == 34 and not keyboard.ControlPressed and not keyboard.ShiftPressed do selectNextNodeByCreationOrder()
			if keyCode == 33 and not keyboard.ControlPressed and not keyboard.ShiftPressed do selectPreviousNodeByCreationOrder()
			
			if keyCode == 34 and not keyboard.ControlPressed and keyboard.ShiftPressed do selectChildrenNodesByParent()
			if keyCode == 33 and not keyboard.ControlPressed and keyboard.ShiftPressed do selectParentNodesByChild()
			
			if keyCode == 45 do 
			(
				nodeInsertMode = not nodeInsertMode
				KrakatoaChannelsEditor_Functions.updateEditorTitle()
			)
			
			if keycode == 48 do  --0
			(
				lastMouseClick = mouse.screenpos
				if not keyboard.ControlPressed and not keyboard.ShiftPressed do addNewInput type:#value valueType:#integer defaultValue:0
				if keyboard.ControlPressed and not keyboard.ShiftPressed do addNewInput type:#value valueType:#float defaultValue:0.0
				if not keyboard.ControlPressed and keyboard.ShiftPressed do addNewInput type:#value valueType:#vector defaultValue:[0,0,0]
			)					
			
			if keycode == 49 do  --1
			(
				lastMouseClick = mouse.screenpos
				if not keyboard.ControlPressed and not keyboard.ShiftPressed do addNewInput type:#value valueType:#integer defaultValue:1
				if keyboard.ControlPressed and not keyboard.ShiftPressed do addNewInput type:#value valueType:#float defaultValue:1.0
				if not keyboard.ControlPressed and keyboard.ShiftPressed do addNewInput type:#value valueType:#vector defaultValue:[1,0,0]
			)			
			if keycode == 50 do  --2
			(
				lastMouseClick = mouse.screenpos
				if not keyboard.ControlPressed and not keyboard.ShiftPressed do addNewInput type:#value valueType:#integer defaultValue:2
				if keyboard.ControlPressed and not keyboard.ShiftPressed do addNewInput type:#value valueType:#float defaultValue:2.0
				if not keyboard.ControlPressed and keyboard.ShiftPressed do addNewInput type:#value valueType:#vector defaultValue:[0,1,0]
			)		
			if keycode == 51 do  --3
			(
				lastMouseClick = mouse.screenpos
				if not keyboard.ControlPressed and not keyboard.ShiftPressed do addNewInput type:#value valueType:#integer defaultValue:3
				if keyboard.ControlPressed and not keyboard.ShiftPressed do addNewInput type:#value valueType:#float defaultValue:3.0
				if not keyboard.ControlPressed and keyboard.ShiftPressed do addNewInput type:#value valueType:#vector defaultValue:[0,0,1]
			)		
			if keycode == 52 do  --4
			(
				lastMouseClick = mouse.screenpos
				if not keyboard.ControlPressed and not keyboard.ShiftPressed do addNewInput type:#value valueType:#integer defaultValue:4
				if keyboard.ControlPressed and not keyboard.ShiftPressed do addNewInput type:#value valueType:#float defaultValue:4.0
				if not keyboard.ControlPressed and keyboard.ShiftPressed do addNewInput type:#value valueType:#vector defaultValue:[0,1,1]
			)				
			if keycode == 53 do  --5
			(
				lastMouseClick = mouse.screenpos
				if not keyboard.ControlPressed and not keyboard.ShiftPressed do addNewOperator type:"Modulo"
				if keyboard.ControlPressed and not keyboard.ShiftPressed do addNewInput type:#value valueType:#float defaultValue:5.0
				if not keyboard.ControlPressed and keyboard.ShiftPressed do addNewInput type:#value valueType:#vector defaultValue:[1,0,1]
			)				
			
			if keycode == 54 do  --6^
			(
				lastMouseClick = mouse.screenpos				
				if not keyboard.ControlPressed and not keyboard.ShiftPressed do addNewOperator type:"Power" 
				if keyboard.ControlPressed and not keyboard.ShiftPressed do addNewOperator type:"SquareRoot" --addNewInput type:#value valueType:#float defaultValue:6.0
				if not keyboard.ControlPressed and keyboard.ShiftPressed do addNewInput type:#value valueType:#vector defaultValue:[1,1,0]
			)
			
			if keycode == 55 do  --7
			(
				lastMouseClick = mouse.screenpos
				if keyboard.ControlPressed and not keyboard.ShiftPressed do addNewInput type:#value valueType:#float defaultValue:7.0
				if not keyboard.ControlPressed and keyboard.ShiftPressed do addNewInput type:#value valueType:#vector defaultValue:[1,1,1]
				if not keyboard.ControlPressed and not keyboard.ShiftPressed do addNewOperator type:"Logarithm" 
			)	

			if keycode == 56 do  --8
			(
				lastMouseClick = mouse.screenpos
				if keyboard.ControlPressed and not keyboard.ShiftPressed do addNewInput type:#value valueType:#float defaultValue:8.0
				--if not keyboard.ControlPressed and not keyboard.ShiftPressed do addNewOperator type:"NaturalLog" 
			)	
			if keycode == 57 do  --9
			(
				lastMouseClick = mouse.screenpos
				if keyboard.ControlPressed and not keyboard.ShiftPressed do addNewInput type:#value valueType:#float defaultValue:9.0
			)					
			
			
			if keycode ==65 and not keyboard.ShiftPressed and not keyboard.ControlPressed do  --A
			(
				lastMouseClick = mouse.screenpos
				--addNewOperator type:"AbsoluteValue"
				
				popupmenu KrakatoaChannelsEditor_RCMenus.ArithmeticOperatorsMenu pos:mouse.screenpos
			)		

			
			if keycode ==65 and keyboard.ShiftPressed and not keyboard.ControlPressed do  --Shift+A
			(
				lastMouseClick = mouse.screenpos
				addNewInput type:#channel channelName:"Age"
			)				

			if keycode == 65 and keyboard.ControlPressed and keyboard.ShiftPressed  do alignAllNodesToGrid() --Ctrl+Shift+A
			if keycode == 65 and keyboard.ControlPressed and not keyboard.ShiftPressed  do --Ctrl+A
			(
				selectAllNodes()
			)
			
			if keycode == 66 do 
			(
				if not keyboard.ShiftPressed and not keyboard.ControlPressed do  --B
				(
					lastMouseClick = mouse.screenpos
					addNewOperator type:"Blend" 
				)
				if keyboard.ShiftPressed and not keyboard.ControlPressed do  --Shift+B
				(				
					lastMouseClick = mouse.screenpos
					addNewInput type:#channel channelName:"Absorption"				
				)
			)	
			
			if keycode == 67 do 
			(
				if not keyboard.ShiftPressed and not keyboard.ControlPressed do --ConvertTo Nodes
				(
					lastMouseClick = mouse.screenpos
					popupmenu KrakatoaChannelsEditor_RCMenus.ConvertToNodesMenu pos:mouse.screenpos 
				)
				
				/*
				if not keyboard.ShiftPressed and not keyboard.ControlPressed then --C
				(
					lastMouseClick = mouse.screenpos
					addNewOperator type:"Clamp" 
				)	
				*/
				
				if keyboard.ShiftPressed and not keyboard.ControlPressed then --Shift+C
				(
					lastMouseClick = mouse.screenpos
					addNewInput type:#channel channelName:"Color"
				)	
				/*if keyboard.ShiftPressed and keyboard.ControlPressed then --Shift+Ctrl+C
				(
					lastMouseClick = mouse.screenpos
					addNewOperator type:"Ceil" 
				)	*/
				if not keyboard.ShiftPressed and keyboard.ControlPressed then --Ctrl+C
				(
					copySelectionToClipboard()
				)				
			)	
			
			if keycode == 68 and keyboard.ControlPressed do  --D
			(
				deselectAllNodes()
			)			

			if keycode == 68 and keyboard.ShiftPressed and not keyboard.ControlPressed do  --Shift+D
			(
				lastMouseClick = mouse.screenpos
				addNewInput type:#channel channelName:"Density"
			)	

			if keycode == 69 do
			(			
				if not keyboard.ControlPressed and keyboard.ShiftPressed  do  
				(
					lastMouseClick = mouse.screenpos
					addNewInput type:#channel channelName:"Emission"
				)			
			)
			
			if keycode == 70 do
			(
				if not keyboard.ShiftPressed and not keyboard.ControlPressed do  --F
				(
					lastMouseClick = mouse.screenpos
					popupmenu KrakatoaChannelsEditor_RCMenus.FunctionOperatorsMenu pos:mouse.screenpos
				)			
				if keyboard.ShiftPressed and keyboard.ControlPressed do --Ctrl+Shift+F
				(
					lastMouseClick = mouse.screenpos
					addNewOperator type:"Floor" 
				)					
				if keyboard.ShiftPressed and not keyboard.ControlPressed do --Shift+F
				(
					lastMouseClick = mouse.screenpos
					addNewOperator type:"ToFloat" 
				)					
			)
			
			if keycode == 71 do --G
			(
				if not keyboard.ShiftPressed and not keyboard.ControlPressed do 
				(
					lastMouseClick = mouse.screenpos
					popupmenu KrakatoaChannelsEditor_RCMenus.TrigonometryOperatorsMenu  pos:mouse.screenpos
				)
				
				if not keyboard.ShiftPressed and keyboard.ControlPressed do  
					toggleSnapToGrid	()
			)
			
			if keyCode == 73 do --I
			(
				lastMouseClick = mouse.screenpos
				
				if not keyboard.ControlPressed and not keyboard.ShiftPressed do --I
					popupmenu KrakatoaChannelsEditor_RCMenus.channelInputsMenu pos:mouse.screenpos
				
				if keyboard.ControlPressed and keyboard.ShiftPressed do --Ctrl+Shift+I
					addNewOperator type:"ToInteger" 					

				if not keyboard.ControlPressed and keyboard.ShiftPressed  do   --Shift+I
					addNewInput type:#channel channelName:"ID"

				if keyboard.ControlPressed and not keyboard.ShiftPressed do --Ctrl+I
					invertSelection()
			)	
			
			if keycode == 76 do
			(
				if keyboard.ShiftPressed and not keyboard.ControlPressed do  --Shift+L
				(
					lastMouseClick = mouse.screenpos
					addNewInput type:#channel channelName:"LifeSpan"
				)
				
				if not keyboard.ShiftPressed and not keyboard.ControlPressed do  --Logic
				(
					lastMouseClick = mouse.screenpos
					popupmenu KrakatoaChannelsEditor_RCMenus.LogicNodesMenu pos:mouse.screenpos
				)
			)	
			

			if keycode == 77 and not keyboard.ShiftPressed and not keyboard.ControlPressed do  --Shift+M
			(
				lastMouseClick = mouse.screenpos
				KrakatoaChannelNodeEditor_Rollout.addNewInput type:#TextureMap
			)	
			
			if keycode == 77 and keyboard.ShiftPressed and not keyboard.ControlPressed do  --Shift+M
			(
				lastMouseClick = mouse.screenpos
				addNewInput type:#channel channelName:"TextureCoord"
			)	
			
			if keycode == 77 and not keyboard.ShiftPressed and keyboard.ControlPressed do  --Ctrl+M
			(
				lastMouseClick = mouse.screenpos
				addNewOperator type:"Magnitude" 
			)				
			
			if keycode == 78 and not keyboard.ShiftPressed and not keyboard.ControlPressed do  --N
			(
				lastMouseClick = mouse.screenpos
				addNewOperator type:"Normalize" 
			)					
			
			
			if keyCode == 78 and not keyboard.ShiftPressed and keyboard.ControlPressed do newFlow() --Ctrl+N
			
			if keyCode == 78 and keyboard.ShiftPressed and keyboard.ControlPressed do 	--Shift+Ctrl+N
			(
				lastMouseClick = mouse.screenpos
				addNewOperator type:"Noise" 				
			)
			
			if keycode == 78 and keyboard.ShiftPressed and not keyboard.ControlPressed do  --Shift+N
			(
				lastMouseClick = mouse.screenpos
				addNewInput type:#channel channelName:"Normal"
			)	
			
			if keyCode == 79 do 
			(
				if not keyboard.ControlPressed and keyboard.ShiftPressed  do  --Shift+O
				(
					lastMouseClick = mouse.screenpos
					addNewInput type:#channel channelName:"Orientation"
				)				
				
				if  keyboard.ControlPressed and not keyboard.ShiftPressed  do   --Ctrl+O
				(
					openFlow()
				)
				
				if  not keyboard.ControlPressed and not keyboard.ShiftPressed  do   --O
				(
					lastMouseClick = mouse.screenpos
					addNewOperator()
				)	
			)

			if keycode == 80 and keyboard.ShiftPressed and not keyboard.ControlPressed do  --P
			(
				lastMouseClick = mouse.screenpos
				addNewInput type:#channel channelName:"Position"
			)	
			
			if keyCode == 80 and keyboard.ControlPressed do setPassThrough() --Ctrl+P
			
            if keyCode == 81 do
			(
				if not keyboard.ControlPressed and not keyboard.ShiftPressed do 
					addNewOperator type:"FromQuat" --q
				
				if keyboard.ControlPressed and not keyboard.ShiftPressed do 
					try(destroyDialog KrakatoaChannelNodeEditor_Rollout)catch() --Ctrl+Q
				
				if keyboard.ControlPressed and keyboard.ShiftPressed do 
					addNewOperator type:"ToQuat" 
			)
			
			if keyCode == 82 do --R
			(
				if not keyboard.ShiftPressed  and keyboard.ControlPressed do 
					autoReorderFlow() 
			)
			
			if keyCode == 83 do --S
			(
				if not keyboard.ControlPressed and not keyboard.ShiftPressed do 
				(
					lastMouseClick = mouse.screenpos
					popupmenu KrakatoaChannelsEditor_RCMenus.SurfaceOperatorsMenu pos:mouse.screenpos
				)
				
				if keyboard.ControlPressed and not keyboard.ShiftPressed  do saveFlowAs() --Ctrl+S
				
				if not keyboard.ControlPressed and keyboard.ShiftPressed  do  
				(
					lastMouseClick = mouse.screenpos
					addNewInput type:#channel channelName:"Selection"
				)
				
				if keyboard.ControlPressed and keyboard.ShiftPressed  do  
				(
					lastMouseClick = mouse.screenpos
					addNewOperator type:"ToScalar" 
				)
			)	

			if keycode == 84 do  --T
			(
				if not keyboard.ShiftPressed and not keyboard.ControlPressed do 
				(
					lastMouseClick = mouse.screenpos
					popupmenu KrakatoaChannelsEditor_RCMenus.TransformSpaceNodesMenu pos:mouse.screenpos
				)
				
				if keyboard.ShiftPressed and not keyboard.ControlPressed do  --Shift+T
				(
					lastMouseClick = mouse.screenpos
					addNewInput type:#channel channelName:"Tangent"
				)				
			)
			
			
			if keycode == 85 do --U
			(
				lastMouseClick = mouse.screenpos
				if not keyboard.ShiftPressed and not keyboard.ControlPressed do 
				(
					lastMouseClick = mouse.screenpos
					popupmenu KrakatoaChannelsEditor_RCMenus.ValueInputsMenu pos:mouse.screenpos
				)
				
				if not keyboard.ShiftPressed and keyboard.ControlPressed do selectUnconnectedNodes()
			)
						

			if keycode == 86 do  --V
			(
				
				if not keyboard.ShiftPressed and  not keyboard.ControlPressed do 
				(
					lastMouseClick = mouse.screenpos
					popupmenu KrakatoaChannelsEditor_RCMenus.VectorOperatorsMenu pos:mouse.screenpos
				)
				
				if not keyboard.ShiftPressed and  keyboard.ControlPressed do 
					pasteSelectionFromClipboard()
				
				if keyboard.ShiftPressed and not keyboard.ControlPressed do  --Shift+V
				(
					lastMouseClick = mouse.screenpos
					addNewInput type:#channel channelName:"Velocity"
				)				
				
				if keyboard.ControlPressed and keyboard.ShiftPressed  do  
				(
					lastMouseClick = mouse.screenpos
					addNewOperator type:"ToVector" 
				)				
			)
			
			
			if keyCode == 87 and keyboard.ControlPressed do swapInputsOrder() --Ctrl+W
			if keyCode == 88 do
				if not keyboard.ShiftPressed then
					resetZoomFactor() --X
				else
					resetPanFactor() --Shift+X
			
			if keyCode == 89 and keyboard.ControlPressed do redoLastStep() --Ctrl+Y
			
			if keyCode == 90 do --zoom
			(
				if keyboard.ControlPressed then
					undoLastStep()
				else
				(
					if keyboard.ShiftPressed then
						ZoomExtentsSelected()
					else
						ZoomExtents()
				)	
			)	

			if keycode == 106 and not keyboard.ControlPressed do  --NumPad *
			(
				lastMouseClick = mouse.screenpos
				addNewOperator type:"Multiply" 
			)			
			if keycode == 107 and not keyboard.ControlPressed do --NumPad +
			(
				lastMouseClick = mouse.screenpos
				addNewOperator type:"Add" 
			)
			if keyCode == 109 and not keyboard.ControlPressed do  --NumPad --
			(
				lastMouseClick = mouse.screenpos
				addNewOperator type:"Subtract" 
			)				
			if keycode == 111 and not keyboard.ControlPressed do  --NumPad /
			(
				lastMouseClick = mouse.screenpos
				addNewOperator type:"Divide" 
			)	

			if keycode == 187 do  --=
			(
				lastMouseClick = mouse.screenpos
				if not keyboard.ControlPressed and not keyboard.ShiftPressed do addNewOperator type:"Equal" 
			)					

			if keycode == 188 do  --,
			(
				lastMouseClick = mouse.screenpos
				if not keyboard.ControlPressed and not keyboard.ShiftPressed do addNewOperator type:"CrossProduct" 
				if not keyboard.ControlPressed and keyboard.ShiftPressed do addNewOperator type:"Less" 				
			)					
			
			if keyCode == 189 do 	-- -
			(
				lastMouseClick = mouse.screenpos
				addNewOperator type:"Negate" 				
			)
			
			if keycode == 190  do  --.
			(
				lastMouseClick = mouse.screenpos
				if not keyboard.ControlPressed and not keyboard.ShiftPressed do addNewOperator type:"DotProduct" 
				if not keyboard.ControlPressed and keyboard.ShiftPressed do addNewOperator type:"Greater" 
			)				
			
			if keycode == 191 and not keyboard.ControlPressed do  --/
			(
				lastMouseClick = mouse.screenpos
				addNewOperator type:"Switch" 
			)			
			if keycode == 192 and not keyboard.ControlPressed do  --`
			(
				lastMouseClick = mouse.screenpos
				addNewOperator type:"Curve"					
			)
			
			if keycode == 219 and not keyboard.ControlPressed and  not keyboard.ShiftPressed do  --[ key
			(
				addNewOperator type:"Sin" 
			)		
			if keycode == 221 and not keyboard.ControlPressed and  not keyboard.ShiftPressed do  --] key
			(
				addNewOperator type:"Cos" 
			)		
			if keycode == 220 and not keyboard.ControlPressed and  not keyboard.ShiftPressed do  --\ key
			(
				addNewOperator type:"Tan" 
			)		
			
			if keycode == 219 and not keyboard.ControlPressed and keyboard.ShiftPressed do  --{ key
			(
				addNewOperator type:"ASin" 
			)	
			if keycode == 221 and not keyboard.ControlPressed and  keyboard.ShiftPressed do  --} key
			(
				addNewOperator type:"ACos" 
			)		
			if keycode == 220 do --| key
			(
				if not keyboard.ControlPressed and  keyboard.ShiftPressed do addNewOperator type:"ATan" 
				if keyboard.ControlPressed and  keyboard.ShiftPressed do addNewOperator type:"ATan2" 
					
			)
		)
		
		fn setToolTip thePos theNodeIndex =
		(
			hc.activeNode = theNodeIndex
			local refPos = hc.ActiveNodePos 
			local refSize = hc.nodeSize
			hc.activeNode = hc.getNodeCount
			local theNotes = KrakatoaChannelEditor_DisplayNodeTreeData[theNodeIndex][4][16]
			if classof theNotes == String then
			(
				local theNotesArray = filterString theNotes "\n"
				local maxChars = 0
				local theLinesCount = amin #(theNotesArray.count,10)
				for i = 1 to theLinesCount do
				(
					hc.activeSocket = i
					hc.socketName = theNotesArray[i]
					if theNotesArray[i].count > maxChars do maxChars = theNotesArray[i].count
				)
				for i = theLinesCount+1 to 10 do
				(
					hc.activeSocket = i
					hc.socketName = ""
				)
				hc.nodeSize = [amin #(amax #(maxChars*6,refSize.x),300) ,20+theLinesCount*13]
				hc.ActiveNodePos = refPos+[refSize.x/2-hc.nodeSize.x/2,refSize.y]
			)
			else
				hc.ActiveNodePos = thePos+[-100000,-100000]
			hc.redrawView	
		)
		
		fn hideToolTip =
		(
			hc.activeNode = hc.getNodeCount
			hc.ActiveNodePos = [-100000,-100000]
			hc.redrawView	
		)
		
		on hc mouseMoved do
		(
			showTooltips = true
			if keyboard.controlPressed == true then
			(
				local lastMousePos = mouse.screenpos
				local theMouse = ((lastMousePos - (getDialogPos KrakatoaChannelNodeEditor_Rollout))-[3,42])
				local lastNodeOver= (hc.findNodeByPos = theMouse)		
				if lastNodeOver == 0 or lastNodeOver > KrakatoaChannelEditor_DisplayNodeTreeData.count or KrakatoaChannelEditor_DisplayNodeTreeData[lastNodeOver][3][1] == "Notes" then
				(
					hideToolTip()
				)
				else
				(
					setToolTip theMouse lastNodeOver
				)
			)
			else hideToolTip()
		)
		
		
		on hc RButtonDown do
		(
			lastMouseClick = mouse.screenpos
			local theHeightOffset = try(dotnetSystemInfo.CaptionHeight + dotnetSystemInfo.MenuHeight + dotnetSystemInfo.FrameBorderSize.height)catch(50)
			if KrakatoaChannelNodeEditor_Rollout.inViewport do 
				theHeightOffset = try(dotnetSystemInfo.MenuHeight+0)catch(19)
			local theWidthOffset = try(dotnetSystemInfo.FrameBorderSize.width)catch(3)
			local theMouse = (lastMouseClick - (getDialogPos KrakatoaChannelNodeEditor_Rollout))-[theWidthOffset,theHeightOffset]
			lastNodeClick = (hc.findNodeByPos = theMouse)
			if lastNodeClick == 0 then
				popupMenu KrakatoaChannelEditor_AddNode_RCMenu pos:lastMouseClick
			else if lastNodeClick > 1 and lastNodeClick <= KrakatoaChannelEditor_DisplayNodeTreeData.count do popupMenu KrakatoaChannelEditor_EditNode_RCMenu pos:lastMouseClick
			
			if (DepotPlacement != #off) and lastNodeClick>KrakatoaChannelEditor_DisplayNodeTreeData.count do popupMenu KrakatoaChannelNodeEditor_DepotMenu pos:lastMouseClick
		)		
		
		fn updateValues =
		(
			createNodeTree init:false
			try
			(
				if KrakatoaChannelNodeEditor_InputRollout.open and KrakatoaChannelNodeEditor_InputRollout.ddl_InputType.selection == 2 do 
					KrakatoaChannelNodeEditor_InputRollout.updateControls()
			)catch()	
		)
		
		on KrakatoaChannelNodeEditor_Rollout open do
		(
			try(btn_zoomExtents.images = #("krakatoa_channelEditor_16i.bmp","krakatoa_channelEditor_16a.bmp", 4,1,1,1,1,true) )catch()
			try(btn_zoomExtentsSelected.images = #("krakatoa_channelEditor_16i.bmp","krakatoa_channelEditor_16a.bmp", 4,2,2,2,2,true) )catch()
			try(btn_NoZoom.images = #("krakatoa_channelEditor_16i.bmp","krakatoa_channelEditor_16a.bmp", 4,3,3,3,3,true) )catch()
			try(btn_NoPoom.images = #("krakatoa_channelEditor_16i.bmp","krakatoa_channelEditor_16a.bmp", 4,4,4,4,4,true) )catch()
			
			try(btn_RecorderToStart.images = #("VCRControls_16i.bmp","VCRControls_16i.bmp", 28,5,5,6,6,true) )catch()
			try(btn_RecorderBackOneStep.images = #("VCRControls_16i.bmp","VCRControls_16i.bmp", 28,3,3,4,4,true) )catch()
			try(chk_RecorderPlay.images = #("VCRControls_16i.bmp","VCRControls_16i.bmp", 28,7,7,8,8,true) )catch()
			try(btn_RecorderForwardOneStep.images = #("VCRControls_16i.bmp","VCRControls_16i.bmp", 28,11,11,12,12,true) )catch()
			try(btn_RecorderToEnd.images = #("VCRControls_16i.bmp","VCRControls_16i.bmp", 28,13,13,14,14,true) )catch()
			
			try(hc.useDrawLayers = true)catch()
			loadDisplaySettings()
			createDepot()
			updateDepotDefinition()
			--KrakatoaChannelsEditor_Functions.buildDisplayTree()			
			createNodeTree init:true
			hc.drawShadows = theNodesCastShadows
			hc.allowZoom  = true
			try(hc.zoomAboutMouse = false)catch()
			hc.drawMenuBars = true
			hc.allowUIDelete = true
			hc.showInfo = true
			hc.setInfo = ""
			hc.pan = [0,0]
			lastMouseClick = (getDialogPos KrakatoaChannelNodeEditor_Rollout)+ [KrakatoaChannelNodeEditor_Rollout.width/2,KrakatoaChannelNodeEditor_Rollout.height/2]
			--format "OPEN Pan And Zoom: %\n" KrakatoaChannelEditor_DisplayNodeTreeData[1][4][20]
			restoreLastKnownPanAndZoom() --RESTORE PAN AND ZOOM

			local theVal = execute (getIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "ParticleChannelEditor" "AutoUpdate" )
			if theVal == OK do theVal = false
			chk_autoUpdateModifier.state = KrakatoaChannelNodeEditor_CurrentModifier.autoUpdate --theVal
			
			showGrid SnapToGrid
			hc.redrawView			
			
			createUndoRecord "Session Start"
			setUndoRedoEnable()
			displaySelectedNodeProperties()
			registerTimeCallback updateValues
			KrakatoaChannelsEditor_Functions.displayError KrakatoaChannelEditor_LastError[1] KrakatoaChannelEditor_LastError[2] KrakatoaChannelEditor_LastError[3]			
			--drawDepot init:true lock:true
			

			
			if autoZoomExtents do zoomExtents()
			if AutoReorderToggle do autoReorderFlow createUndo:false
			registerViewWindow KrakatoaChannelNodeEditor_Rollout	
			updateNodeDependencies()
			
			--FIXME: The following was disabled to avoid updates of dependent complex PFlows on editor opening.
			--The change might have side effects that are not clear yet!
			
			--if chk_autoUpdateModifier.checked do KrakatoaChannelsEditor_Functions.updateParentModifier()	
		)
		
		on KrakatoaChannelNodeEditor_Rollout close do
		(
			if KrakatoaChannelEditor_NodeTreeEditingLevel.count > 0 do
			(
				KrakatoaChannelsEditor_Functions.endEditingBLOP type:#yesno
			)				
			setIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "ParticleChannelEditor" "Pan" (hc.pan as string)
			setIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "ParticleChannelEditor" "Zoom" (hc.zoom as string)
			KrakatoaChannelsEditor_Functions.updateParentModifier()
			unregisterTimeCallback updateValues
			deleteAllChangeHandlers id:#KCE_CurrentModifierSceneParametersMonitor
			KrakatoaChannelEditor_DisableDragAndDrop = true
		)
		
		on btn_updateModifier pressed do 
		(
			KrakatoaChannelEditor_LastError = #(0,"","")
			lbx_log.items = #()
			KrakatoaChannelsEditor_Functions.updateParentModifier commitBlop:true
			if chk_autoUpdateModifier.checked do updateNodeDependencies()
			createNodeTree init:false
			if DebugModeOn do debugFlow()
		)
		
		on chk_autoUpdateModifier changed state do 	
		(
			KrakatoaChannelEditor_LastError = #(0,"","")
			lbx_log.items = #()
			if state then
			(
				KrakatoaChannelsEditor_Functions.updateParentModifier()
				updateNodeDependencies()
			)
			else
				deleteAllChangeHandlers id:#KCE_CurrentModifierSceneParametersMonitor
			KrakatoaChannelNodeEditor_CurrentModifier.autoUpdate = state
			setIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "ParticleChannelEditor" "AutoUpdate" (state as string)
			createNodeTree init:false
		)
		

		
		on KrakatoaChannelNodeEditor_Rollout resized val do 
		(
			hc.width = val.x-182
			hc.height = val.y-18
			
			prg_bar.pos = [val.x-178,val.y-31]
			
			lbx_log.width = val.x-176
			lbx_log.pos = [-2,val.y-19]
			
			btn_RecorderToStart.pos = [val.x-178,val.y-56]
			btn_RecorderBackOneStep.pos = [val.x-178+25,val.y-56]
			chk_RecorderPlay.pos = [val.x-178+25*2,val.y-56]
			btn_RecorderForwardOneStep.pos = [val.x-178+25*3,val.y-56]
			btn_RecorderToEnd.pos = [val.x-178+25*4,val.y-56]
			btn_RecorderClose.pos = [val.x-178+25*5,val.y-56]
			
			NodePropsSR.pos = [val.x-180,23]
			NodePropsSR.height = if KrakatoaChannelEditor_MacroRecording.count > 0 then val.y-80 else val.y-49
			
			chk_autoUpdateModifier.pos=[val.x-180,1] 
			btn_updateModifier.pos = [val.x-118,1] 			
			
			btn_zoomExtents.pos = [val.x-178,val.y-25]
			btn_zoomExtentsSelected.pos = [val.x-153,val.y-25]
			btn_NoZoom.pos = [val.x-128,val.y-25]
			btn_NoPoom.pos = [val.x-103,val.y-25]
			
			btn_Undo.pos = [val.x-78,val.y-25]
			btn_Redo.pos = [val.x-39,val.y-25]
			drawDepot init:false	lock:true
			if val.x > 100 and val.y > 100 do 
				setIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "ParticleChannelEditor" "Size" (val as string)
			updateMacroRecorderControls()
			

			if AutoReorderToggle do KrakatoaChannelNodeEditor_Rollout.autoReorderFlow createUndo:false
			if AutoZoomExtents do KrakatoaChannelNodeEditor_Rollout.zoomExtents createUndo:false			
		)
		
		on KrakatoaChannelNodeEditor_Rollout moved val do 
		(
			if val.y < sysinfo.desktopsize.y-50 do 
				setIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "ParticleChannelEditor" "Position" (val as string)		
		)	
	)
	
	fn KrakatoaChannelEditor_ModifierCallback =
	(
		if KrakatoaChannelEditor_IsUpdatingExposure == true do return false
			
		local theObj = modPanel.getCurrentObject()
		if theObj != undefined and theObj.classid as string == "#(393701632, 48107384)" and KrakatoaChannelNodeEditor_Rollout.open == true and KrakatoaChannelNodeEditor_CurrentModifier != theobj do 
		(
			if KrakatoaChannelEditor_NodeTreeEditingLevel.count > 0 do
			(
				KrakatoaChannelsEditor_Functions.endEditingBLOP type:#yesno
			)	
			KrakatoaChannelsEditor_Functions.updateParentModifier()
			if KrakatoaChannelNodeEditor_CurrentModifier != theObj do 
			(
				global KrakatoaChannelEditor_LastUndoRecordNumber = 0
			)	
			global KrakatoaChannelNodeEditor_CurrentModifier = theObj
			global KrakatoaChannelEditor_BaseNodeTreeData = execute theObj.internalFlow
			global KrakatoaChannelEditor_NodeTreeEditingLevel = #()
			global KrakatoaChannelEditor_NodeTreeEditingNames = #()
			global KrakatoaChannelEditor_NodeTreeEditingUndoLevel = #()			
			KrakatoaChannelsEditor_Functions.buildDisplayTree()
			
			KrakatoaChannelsEditor_Functions.updateEditorTitle()
			/*
			local txt = "Krakatoa MagmaFlow Editor - ID:" + KrakatoaChannelNodeEditor_CurrentModifier.trackID as string + " - ["+ KrakatoaChannelNodeEditor_CurrentModifier.name+"]" 
			if KrakatoaChannelNodeEditor_CurrentModifier.isRenderElement do txt+= " - Render Element"
			KrakatoaChannelNodeEditor_Rollout.title = txt
				*/
			KrakatoaChannelNodeEditor_Rollout.createNodeTree init:true
			KrakatoaChannelNodeEditor_Rollout.displaySelectedNodeProperties()
			KrakatoaChannelNodeEditor_Rollout.chk_autoUpdateModifier.state = KrakatoaChannelNodeEditor_CurrentModifier.autoUpdate
			--format "MOD CALLBACK Pan And Zoom: %\n" KrakatoaChannelEditor_DisplayNodeTreeData[1][4][20]
			KrakatoaChannelNodeEditor_Rollout.restoreLastKnownPanAndZoom() --RESTORE PAN AND ZOOM
			
			KrakatoaChannelNodeEditor_Rollout.drawDepot init:false 

			setFocus KrakatoaChannelNodeEditor_Rollout.hc	
		)		
	)
	
	fn KrakatoaChannelEditor_PreSaveCallback =
	(
		try(KrakatoaChannelEditor_TrackviewCleanupCallback())catch()
		if KrakatoaChannelNodeEditor_Rollout.open do
		(
			try(KrakatoaChannelsEditor_Functions.updateParentModifier())catch()		
		)
	)
	
	deleteAllChangeHandlers id:#KCE_CurrentModifierSceneParametersMonitor
	callbacks.removeScripts id:#KrakatoaChannelEditor
	callbacks.addScript #modPanelObjPostChange "KrakatoaChannelEditor_ModifierCallback()" id:#KrakatoaChannelEditor
	callbacks.addScript #filePreOpen "try(destroyDialog KrakatoaChannelNodeEditor_Rollout)catch()" id:#KrakatoaChannelEditor
	callbacks.addScript #filePreSave "KrakatoaChannelEditor_PreSaveCallback()" id:#KrakatoaChannelEditor
	callbacks.addScript #filePostOpen "try(KrakatoaChannelEditor_fixDuplicatedKCMTrackIDs_Callback theMode:#FilePostOpen)catch()" id:#KrakatoaChannelEditor
	callbacks.addScript #filePostMerge "try(KrakatoaChannelEditor_fixDuplicatedKCMTrackIDs_Callback theMode:#FilePostMerge)catch()" id:#KrakatoaChannelEditor
	
	callbacks.addScript #systemPostNew "try(destroyDialog KrakatoaChannelNodeEditor_Rollout)catch()" id:#KrakatoaChannelEditor
	callbacks.addScript #systemPostReset "try(destroyDialog KrakatoaChannelNodeEditor_Rollout)catch()" id:#KrakatoaChannelEditor
)	