-- Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
-- SPDX-License-Identifier: Apache-2.0
(
-----------------------------------------------
--MAGMA ACTIVE TYPE MODULE
--Started: 2013/01/04
--Edited: 	2015/12/21
-----------------------------------------------
	
local currentEditorIndex = ::MagmaActiveType_CurrentEditorIndex
local MagmaFlowEditor_Functions = ::MagmaFlowEditor_Functions  	
local magma = MagmaFlowEditor_CurrentEditors[CurrentEditorIndex][1]
local theNodeTypes = #()
local allNodeCategories = #()
local allNodeDescriptions = #()
local allBlopPaths = #()
local theOutList = #()

local theSearchResults = #()
local allBlopNames = #()
local lv, tb
global MagmaActiveType_Form
try(MagmaActiveType_Form.Close())catch()
	
local NodeToSelect = 0
	
fn resizeDialog =
(
	numEntries = theSearchResults.count
	theNewHeight = numEntries * 17
	if theNewHeight > 408 do theNewHeight = 408
	MagmaActiveType_Form.size = dotNetObject "System.Drawing.Size" 200 (18 + theNewHeight)
	lv.size = dotNetObject "System.Drawing.Size" 200 (2 + theNewHeight)
)	

fn collectMagmaNodesInfo =
(
	theNodeTypes = magma.GetTypeNames()
	sort theNodeTypes
	allNodeCategories = for i in theNodeTypes collect (magma.GetTypeCategory i)
	allNodeDescriptions = for i in theNodeTypes collect (magma.GetTypeDescription i)

	local theSourceMode = #kcm
	local theList = (MagmaFlowEditor_Functions.loadChannelsList magma mode:#input source:theSourceMode iterationmode:theIterMode )
	local channelsList = for i in theList collect i[1]
	local allChannelCategories = for i in channelsList collect "InputChannel"
	local allChannelDescriptions = for i in theList collect i[4]
		
	theUserFolder = ::Krakatoa_PresetsDirectory	
	
	allBlopCategories = #()
	allBlopDescriptions = #()
	local theBlopPaths = #()
	local theRootBlops = sort (getFiles (theUserFolder+ "\\BlackOps\\*.MagmaBLOP"))
	for f in theRootBlops do
	(
		local theName = getFileNameFile f
		append allBlopNames theName
		append theBlopPaths (substituteString f "\\" "/")
		local theFileHandle = openFile f
		local theLine = f
		if theFileHandle != undefined do
		(
			skipToString theFileHandle "\"Notes\" " 
			if not eof theFileHandle do theLine = substituteString (readLine theFileHandle) "\\n" " "
		)
		close theFileHandle
		append allBlopDescriptions theLine
		append allBlopCategories "Blop"
	)
	local theSubDirs = getDirectories (theUserFolder+ "\\BlackOps\\*")
	for d in theSubDirs do
	(
		local theCatName = filterString d "\\"
		theCatName=theCatName[theCatName.count]
		local theBlops = sort (getFiles (d+"*.MagmaBLOP"))
		for f in theBlops do
		(
			local theName = getFileNameFile f
			append allBlopNames theName
			append theBlopPaths (substituteString f "\\" "/")
			local theFileHandle = openFile f
			local theLine = f
			if theFileHandle != undefined do
			(
				skipToString theFileHandle "\"Notes\" " 
				if not eof theFileHandle do theLine = substituteString (readLine theFileHandle) "\\n" " "
			)
			close theFileHandle
			append allBlopDescriptions theLine
			append allBlopCategories ("Blop:"+theCatName)
		)						
	)

	join allBlopPaths (for i in theNodeTypes collect "")
	join theNodeTypes channelsList
	join allNodeCategories allChannelCategories
	join allNodeDescriptions	allChannelDescriptions	
	join allBlopPaths (for i in channelsList collect "")
	
	join theNodeTypes allBlopNames
	join allNodeCategories allBlopCategories
	join allNodeDescriptions allBlopDescriptions
	join allBlopPaths theBlopPaths
	
	local existingOutChannels = for i in magma.getNodes() where magma.getNodeType i == "Output" collect (magma.getNodeProperty i "channelName")
	theOutList = (MagmaFlowEditor_Functions.loadChannelsList magma mode:#output source:theSourceMode iterationmode:theIterMode )
	theOutList = for i in theOutList where (findItem existingOutChannels i[1] == 0) collect i
	local outChannelsList = for i in theOutList collect ("Out"+ i[1]) 
	join theNodeTypes outChannelsList	
	join allBlopPaths outChannelsList	
	join allNodeCategories (for i in outChannelsList collect "Output")
	join allNodeDescriptions (for i in theOutList collect i[4])
	
	local theColors = #(
		#("White", [1,1,1], "Colors", "White Color [1,1,1]"),
		#("Gray", [0.5,0.5,0.5], "Colors", "Gray Color [0.5,0.5,0.5]"),
		#("Pink", [1,0.5,0.5], "Colors", "Pink Color [1,0.5,0.5]"),
		#("Red", [1,0,0], "Colors", "Red Color [1,0,0]"),
		#("Orange", [1,0.5,0], "Colors", "Orange Color [1,0.5,0]"),
		#("Yellow", [1,1,0], "Colors", "Yellow Color [1,1,0]"),
		#("PaleYellow", [1,1,0.6], "Colors", "Pale Yellow Color [1,1,0.6]"),
		#("PaleGreen", [0.6,1,0.6], "Colors", "Pale Green Color [0,1,0]"),
		#("Green", [0,1,0], "Colors", "Green Color [0,1,0]"),
		#("Turquoise", [0.25,0.9,0.8], "Colors", "Turquoise Color [0.25,0.9,0.8]"),
		#("Cyan", [0,1,1], "Colors", "Cyan Color [0,1,1]"),
		#("SkyBlue", [0.5,0.8,0.9], "Colors", "Sky Blue Color [0.5,0.8,0.9]"),
		#("Blue", [0,0,1], "Colors", "Blue Color [0,0,1]"),
		#("NavyBlue", [0,0,0.5], "Colors", "Navy Blue Color [0,0,0.5]"),
		#("Magenta", [1,0,1], "Colors", "Magenta Color [1,0,1]"),
		#("Violet", [0.5,0,1], "Colors", "Violet Color [0.5,0,1]"),
		#("Indigo", [0.3,0,0.5], "Colors", "Indigo Color [0.25,0,0.5]"),
		#("Black", [0,0,0], "Colors", "Black Color [0,0,0]")
	)
	

	
	local theValues = #(
		#("Plus", "Add", "Aliases", "Alias For 'Add' Arithmetic Operator"),
		#("Minus", "Subtract", "Aliases", "Alias For 'Subtract' Arithmetic Operator"),
		#("Times", "Multiply", "Aliases", "Alias For 'Multiply' Arithmetic Operator"),
		
		#("Left", [-1,0,0], "VectorValues", "Left Vector [-1,0,0]"),
		#("Right", [1,0,0], "VectorValues", "Right Vector [1,0,0]"),
		#("Forward", [0,1,0], "VectorValues", "Forward Vector [0,1,0]"),
		#("Back", [0,-1,0], "VectorValues", "Backward Vector [0,-1,0]"),
		#("Up", [0,0,1], "VectorValues", "Up Vector [0,0,1]"),
		#("Down", [0,0,-1], "VectorValues", "Down Vector [0,0,-1]"),
		#("Vector", [1,0,0], "VectorValues", "Vector Value [1,0,0]"),
		#("Float", 1.0, "FloatValues", "Float Value [1.0]"),
		#("One", 1.0, "FloatValues", "Float Value Of One Point Zero [1.0]"),
		#("Zero", 0.0, "FloatValues", "Float Value Of One Point Zero [0.0]"),
		#("MinusOne", -1.0, "FloatValues", "Float Value Of Minus One Point Zero [-1.0]"),
		#("Integer", 1.0, "IntegerValues", "Integer Value [1]"),
		#("IntOne", 1.0, "IntegerValues", "Integer One Value [1]"),
		#("IntZero", 1.0, "IntegerValues", "Integer Zero Value [0]"),
		#("Frame", "CurrentTime.frame as float", "InputScripts", "Current Scene Time in Floating Point Frames"),
		#("FPS", "FrameRate as float", "InputScripts", "Current Scene Frame Rate"),
		#("TPF", "TicksPerFrame as float", "InputScripts", "Current Scene Ticks Per Frame Count"),
		#("Pi Constant", "pi", "InputScripts", "The Value of Pi [3.14159...]"),
		#("e Constant", "e", "InputScripts", "The Value of e [2.71828...]")
)
	
	for i in theValues do
	(
		append theNodeTypes i[1]
		append allBlopPaths i[2]
		append allNodeCategories i[3]
		append allNodeDescriptions i[4]
	)
	
	for i in theColors do
	(
		append theNodeTypes i[1]
		append allBlopPaths i[2]
		append allNodeCategories i[3]
		append allNodeDescriptions i[4]
	)	
)

fn getNodeColor theIndex =
(
	local theName = theNodeTypes[theIndex]
	local c = allNodeCategories[theIndex]
	local theColor = case of
	(
		(theName as name == #Output): MagmaFlowColors.OutputNode
		(theName as name == #InputValue): MagmaFlowColors.InputVectorValueNode
		(theName as name == #InputChannel): MagmaFlowColors.InputChannelNode
		(theName as name == #LoopChannel): MagmaFlowColors.InputChannelNode
		(theName as name == #InputGeometry): MagmaFlowColors.InputGeometryNode
		(theName as name == #InputParticles): MagmaFlowColors.InputParticlesNode
		(theName as name == #InputObject): MagmaFlowColors.InputObjectNode
		(theName as name == #InputScript): MagmaFlowColors.InputScriptNode
		(theName as name == #InputBoundBox): MagmaFlowColors.InputObjectNode
		(theName as name == #CurrentMesh): MagmaFlowColors.InputGeometryNode
		(theName as name == #BLOP): MagmaFlowColors.EditableBLOPNode
		default: 
		(
			case of 
			(
				(c == "Output"): MagmaFlowColors.OutputNode
				(c == "Colors"): white*0.35
				(c == "VectorValues"): MagmaFlowColors.InputVectorValueNode
				(c == "FloatValues"): MagmaFlowColors.InputFloatValueNode
				(c == "IntegerValues"): MagmaFlowColors.InputIntValueNode
				(c == "Logic"): MagmaFlowColors.LogicOperatorNode 
				(c == "Object"): MagmaFlowColors.ObjectOperatorNode
				(c == "Ember"): try(MagmaFlowColors.EmberOperatorNode)catch(color 255 200 225 )
				(c == "Loops"): try(MagmaFlowColors.EditableLoopNode)catch(color 230 255 210)
				(c == "InputChannel"): MagmaFlowColors.InputChannelNode
				(c == "InputScripts"): MagmaFlowColors.InputScriptNode
				(matchPattern c pattern:"BLOP*"): MagmaFlowColors.EditableBLOPNode
				(c == "Function"): (
					if isProperty MagmaFlowColors #FunctionOperatorNode then MagmaFlowColors.FunctionOperatorNode else MagmaFlowColors.OperatorNode
				)
				default: MagmaFlowColors.OperatorNode
			)
		)
	)	
)

local dotNetBlack = (dotNetClass "System.Drawing.Color").fromARGB  0 0 0
local dotNetWhite = (dotNetClass "System.Drawing.Color").fromARGB  255 255 255

fn searchForNode =
(
	theSearchResults = #()
	if tb.text.count > 0 do
	(
		local compareValue = 1
		local theTokens = filterString tb.text ", "
		if matchPattern tb.text pattern:"*,*" do compareValue = theTokens.count
		
		theSearchResults = for i = 1 to theNodeTypes.count where matchPattern theNodeTypes[i] pattern:(tb.text+"*") collect i
		
		local theResults = for i = 1 to theNodeTypes.count where \
			((for t in theTokens where matchPattern theNodeTypes[i] pattern:("*"+t+"*") collect t).count >= compareValue) \
			AND findItem theSearchResults i == 0 collect i
			
		if theResults.count > 0 do
		(
			append theSearchResults -1
			join theSearchResults theResults
		)

		local theResults = for i = 1 to allNodeCategories.count where \
			((for t in theTokens where matchPattern allNodeCategories[i] pattern:("*"+t+"*") collect t).count >= compareValue) \
			AND findItem theSearchResults i == 0 collect i
			
		if theResults.count > 0 do
		(
			append theSearchResults -2
			join theSearchResults theResults
		)
		
		local theResults = for i = 1 to allNodeDescriptions.count where \
			((for t in theTokens where matchPattern allNodeDescriptions[i] pattern:("*"+t+"*") collect t).count >= compareValue) \
			AND findItem theSearchResults i == 0 collect i
			
		if theResults.count > 0 do
		(
			append theSearchResults -3
			join theSearchResults theResults
		)
	)
	
	lv.Items.Clear()
	local theRange = #()
	local cnt = 0
	for i in theSearchResults do
	(
		local li
		case i of
		(
			(-1): (
					li = dotNetObject "System.Windows.Forms.ListViewItem" "Partial In NAME:"
					li.backcolor = dotNetBlack 
					li.forecolor = dotNetWhite 
					li.Tag = "DoNotCreate" 
				)
			(-2): (
					li = dotNetObject "System.Windows.Forms.ListViewItem" "In CATEGORY:"
					li.backcolor = dotNetBlack 
					li.forecolor = dotNetWhite 
					li.Tag = "DoNotCreate" 
				)
			(-3): (
					li = dotNetObject "System.Windows.Forms.ListViewItem" "In DESCRIPTION:"
					li.backcolor = dotNetBlack 
					li.forecolor = dotNetWhite 
					li.Tag = "DoNotCreate" 
				)
			default: (
				cnt +=1
				li = dotNetObject "System.Windows.Forms.ListViewItem" theNodeTypes[i]
				li.tag = allBlopPaths[i] as string
				if cnt == 1 do li.selected = true
				local theColor = (getNodeColor i)
				li.backcolor = (dotNetClass "System.Drawing.Color").fromARGB  theColor.r theColor.g theColor.b
				local subLi = li.SubItems.add allNodeCategories[i]  
				if allNodeCategories[i] == "Colors" do
				(
					local theForeColor = (allBlopPaths[i] as color) * 255
					li.forecolor = (dotNetClass "System.Drawing.Color").fromARGB theForeColor.r theForeColor.g theForeColor.b
				)
				li.ToolTipText= theNodeTypes[i] + " - " +allNodeCategories[i] + ":\n\n" +allNodeDescriptions[i]
			)
		)
		append theRange li
	)
	lv.Items.AddRange theRange 
)

fn getListViewSelection lv =
(
	try
		(for i = 1 to lv.items.count where lv.items.item[i-1].Selected collect i-1)
	catch
		#()
)	


fn createNodeFromSelection =
(
	if matchPattern tb.text pattern:"select *" then
	(
		local theTokens = filterString tb.text " \r\n"
		if theTokens.count == 2 then
		(
			theTokens[2] = case theTokens[2] of
			(
				"zero": 0
				"one": 1
				"two": 2
				"three": 3
				"four": 4
				"five": 5
				"six": 6
				"seven": 7
				"eight": 8
				"nine": 9
				"ten": 10
				"eleven": 11
				"twelve": 12
				"thirteen": 13
				"fourteen": 14
				"fifteen": 15
				"sixteen": 16
				"seventeen": 17
				"eighteen": 18
				"nineteen": 19
				"twenty": 20
				default: 	theTokens[2] as integer
			)
			if classof theTokens[2] == Integer then
			(
				theNodes = magma.getNodes()
				theIndex = findItem theNodes theTokens[2]
				if theIndex > 0 then
				(
					MagmaFlowEditor_CurrentEditors[currentEditorIndex][2].setSelectedNodes #(theIndex)
					MagmaActiveType_Form.Close()	
					MagmaFlowEditor_CurrentEditors[currentEditorIndex][2].edt_log.text = "ActiveType Closed."
					setFocus MagmaFlowEditor_CurrentEditors[currentEditorIndex][2].hc
					return true					
				)
			)
		)
	)
	
	local theSel = getListViewSelection lv
	local theVal = try(execute tb.text)catch(OK)
	if theVal == e do theVal = OK
	if theVal == pi do theVal = OK
	if theVal == undefined do theVal = OK
	local created = true
	if tb.text != "" AND tb.text != "\r\n" then
	(
		if theVal != OK then
		(
			case classof theVal of
			(
				Point3: MagmaFlowEditor_CurrentEditors[currentEditorIndex][2].createNode "InputValue" ValueType:#vector defaultValue:theVal
				color: MagmaFlowEditor_CurrentEditors[currentEditorIndex][2].createNode "InputValue" ValueType:#vector defaultValue:((theVal / 255.0) as Point3)
				Integer: MagmaFlowEditor_CurrentEditors[currentEditorIndex][2].createNode "InputValue" ValueType:#integer defaultValue:theVal
				Float: MagmaFlowEditor_CurrentEditors[currentEditorIndex][2].createNode "InputValue" ValueType:#float defaultValue:theVal
				default: created = false
			)
			if created do
			(
				MagmaFlowEditor_CurrentEditors[currentEditorIndex][2].createNodeTree init:true
				MagmaActiveType_Form.Close()	
				MagmaFlowEditor_CurrentEditors[currentEditorIndex][2].edt_log.text = "ActiveType Closed."
				setFocus MagmaFlowEditor_CurrentEditors[currentEditorIndex][2].hc
				return true
			)
		)
		if theSel.count == 1 then
		(
			local theTag = lv.Items.Item[theSel[1]].Tag
			if theTag == "DoNotCreate" do return false
			if theTag == "SelectNode" do
			(
				MagmaFlowEditor_CurrentEditors[currentEditorIndex][2].setSelectedNodes #(NodeToSelect)
				MagmaActiveType_Form.Close()	
				MagmaFlowEditor_CurrentEditors[currentEditorIndex][2].edt_log.text = "ActiveType Closed."
				setFocus MagmaFlowEditor_CurrentEditors[currentEditorIndex][2].hc
				return true
			)
			local theCategory = lv.Items.Item[theSel[1]].subitems.item[1].Text
			local theNodeName = lv.Items.Item[theSel[1]].Text
			
			case of
			(
				(theCategory == "InputChannel"): (MagmaFlowEditor_CurrentEditors[currentEditorIndex][2].createNode "InputChannel" ChannelName:theNodeName mode:#rcmenu  )
				(matchPattern theCategory pattern:"blop*"): (MagmaFlowEditor_CurrentEditors[currentEditorIndex][2].createNodeBLOP theTag)
				(matchPattern theCategory pattern:"Aliases"): (MagmaFlowEditor_CurrentEditors[currentEditorIndex][2].createNode theTag mode:#rcmenu)
				(matchPattern theCategory pattern:"colors"): (MagmaFlowEditor_CurrentEditors[currentEditorIndex][2].createNode "InputValue" ValueType:#vector defaultValue:((execute theTag) as color) mode:#rcmenu)
				(matchPattern theCategory pattern:"VectorValues"): (MagmaFlowEditor_CurrentEditors[currentEditorIndex][2].createNode "InputValue" ValueType:#vector defaultValue:((execute theTag)) mode:#rcmenu)
				(matchPattern theCategory pattern:"FloatValues"): (MagmaFlowEditor_CurrentEditors[currentEditorIndex][2].createNode "InputValue" ValueType:#float defaultValue:((execute theTag)) mode:#rcmenu)
				(matchPattern theCategory pattern:"IntegerValues"): (MagmaFlowEditor_CurrentEditors[currentEditorIndex][2].createNode "InputValue" ValueType:#integer defaultValue:((execute theTag)) mode:#rcmenu)
				(matchPattern theCategory pattern:"InputScripts"): (
					local theNewNode = MagmaFlowEditor_CurrentEditors[currentEditorIndex][2].createNode "InputScript" mode:#rcmenu theScript:theTag nodeName:theNodeName
				)
				(matchPattern theCategory pattern:"Output"): (
					local theName = (substring theNodeName 4 -1)
					local theTypeIndex = findItem (for i in theOutList collect i[1]) theName
					local theType = "float16[3]"
					if theTypeIndex > 0 do  theType = theOutList[theTypeIndex][2] + "[" + theOutList[theTypeIndex][3] as string + "]"
					(MagmaFlowEditor_CurrentEditors[currentEditorIndex][2].createNode "Output" ChannelName:theName channelType:theType mode:#rcmenu )
				)
				default: (MagmaFlowEditor_CurrentEditors[currentEditorIndex][2].createNode theNodeName mode:#rcmenu )
			)
			MagmaFlowEditor_CurrentEditors[currentEditorIndex][2].createNodeTree init:true
			MagmaActiveType_Form.Close()	
			MagmaFlowEditor_CurrentEditors[currentEditorIndex][2].edt_log.text = "ActiveType Closed."
			setFocus MagmaFlowEditor_CurrentEditors[currentEditorIndex][2].hc
		)
		else
		(
			MagmaActiveType_Form.Close()	
			MagmaFlowEditor_CurrentEditors[currentEditorIndex][2].edt_log.text = "ActiveType Closed."
			setFocus MagmaFlowEditor_CurrentEditors[currentEditorIndex][2].hc
		)
	)
	else
	(
		MagmaFlowEditor_CurrentEditors[currentEditorIndex][2].edt_log.text = "ActiveType Closed."
		MagmaActiveType_Form.Close()	
		setFocus MagmaFlowEditor_CurrentEditors[currentEditorIndex][2].hc		
	)
)
	
fn whenEnterIsPressed a b =
(
	if (bit.charAsInt b.KeyChar == 9) do MagmaActiveType_Form.selectnextcontrol MagmaActiveType_Form.ActiveControl true false false false
	if (bit.charAsInt b.KeyChar == 13) do createNodeFromSelection()
)

fn whenClicked a b =
(
	createNodeFromSelection()
)

local dnKeys=dotnetclass "System.Windows.Forms.Keys"
local theKey=false

fn txtbox_KeyDown sender eb =
(	
	if (eb.Keycode==dnKeys.Tab) OR (eb.Keycode==dnKeys.Return) OR (eb.Keycode==dnKeys.Escape) OR (eb.Keycode == dnKeys.Down) then theKey=eb.KeyCode else theKey=false
)

fn txtbox_KeyUp sender eb =
(
	if theKey!=false then 
	(
		case theKey of
		(
			(dnKeys.Tab): MagmaActiveType_Form.selectnextcontrol MagmaActiveType_Form.ActiveControl true true false false
			(dnKeys.Return): (createNodeFromSelection())
			(dnKeys.Escape): 
				(
					MagmaActiveType_Form.close() 
					MagmaFlowEditor_CurrentEditors[currentEditorIndex][2].edt_log.text = "ActiveType Canceled."
					setFocus MagmaFlowEditor_CurrentEditors[currentEditorIndex][2].hc
				)
			(dnKeys.Down): MagmaActiveType_Form.selectnextcontrol MagmaActiveType_Form.ActiveControl true true false false
		)	
	)
	else
	(
		searchForNode()
		resizeDialog()		
	)
)

fn listview_KeyDown sender eb =
(	
	if (eb.Keycode==dnKeys.Tab) OR (eb.Keycode==dnKeys.Return) OR (eb.Keycode==dnKeys.Escape) OR (eb.Keycode == dnKeys.Up) OR (eb.Keycode == dnKeys.Down) then theKey=eb.KeyCode else theKey=false
)

fn listview_KeyUp sender eb =
(
	if theKey!=false then 
	(
		case theKey of
		(
			(dnKeys.Tab): MagmaActiveType_Form.selectnextcontrol MagmaActiveType_Form.ActiveControl true false false false
			(dnKeys.Return): (createNodeFromSelection())
			(dnKeys.Escape): 
			(
				MagmaActiveType_Form.close()
				MagmaFlowEditor_CurrentEditors[currentEditorIndex][2].edt_log.text = "ActiveType Canceled."
				setFocus MagmaFlowEditor_CurrentEditors[currentEditorIndex][2].hc
			)
			(dnKeys.Up): 
			(
				local theSel = getListViewSelection lv
				if theSel.count == 1 and theSel[1] == 0 do MagmaActiveType_Form.selectnextcontrol MagmaActiveType_Form.ActiveControl false false false false
			)
		)	
	)
)

-----------------------------------------------------------------------------------
--CREATE TEXTBOX
-----------------------------------------------------------------------------------
tb = dotNetObject "System.Windows.Forms.Textbox"
tb.size = dotNetObject "System.Drawing.Size" 200 18
tb.location = dotNetObject "System.Drawing.Point" 0 0
tb.AcceptsTab = true
tb.BackColor = (dotNetClass "System.Drawing.Color").FromARGB 219 195 195
tb.BorderStyle = tb.BorderStyle.FixedSingle
tb.MultiLine = true
tb.WordWrap = false
--tb.font = dotNetObject "System.Drawing.Font" tb.font (dotNetClass "System.Drawing.FontStyle").Bold

-----------------------------------------------------------------------------------
--CREATE LISTVIEW
-----------------------------------------------------------------------------------
lv = dotNetObject "System.Windows.Forms.Listview"
lv.size = dotNetObject "System.Drawing.Size" 200 60
lv.location = dotNetObject "System.Drawing.Point" 0 16
lv.Clear()
lv.BorderStyle = lv.BorderStyle.FixedSingle--None
lv.HeaderStyle = lv.HeaderStyle.None
lv.backColor = (dotNetClass "System.Drawing.Color").fromARGB 221 221 221
lv.View = (dotNetClass "System.Windows.Forms.View").Details
lv.gridLines = false 
lv.fullRowSelect = true
lv.HotTracking = true
lv.checkboxes = false
lv.hideSelection = false
lv.multiselect = false
lv.ShowItemToolTips = true
local layout_def = #( #("Operator",104), #("Category",80))
for i in layout_def do lv.Columns.add i[1] i[2]

collectMagmaNodesInfo()

-----------------------------------------------------------------------------------
--CREATE FORM
-----------------------------------------------------------------------------------
global MagmaActiveType_Form = dotNetObject "MaxCustomControls.MaxForm"
MagmaActiveType_Form.size = dotNetObject "System.Drawing.Size" 200 14
theMouse = mouse.ScreenPos
MagmaActiveType_Form.StartPosition = MagmaActiveType_Form.StartPosition.Manual
MagmaActiveType_Form.location = dotNetObject "System.Drawing.Point" theMouse.x theMouse.y
MagmaActiveType_Form.controls.add tb
MagmaActiveType_Form.controls.add lv 
MagmaActiveType_Form.FormBorderStyle = (dotnetclass "System.Windows.Forms.FormBorderStyle").None
MagmaActiveType_Form.Opacity = 0.90
MagmaActiveType_Form.ShowInTaskbar = False


dotNet.addEventHandler lv "KeyPress" whenEnterIsPressed
dotNet.addEventHandler lv "MouseUp" whenClicked

dotnet.addEventHandler lv "KeyDown" listview_KeyDown
dotnet.addEventHandler lv "KeyUp" listview_KeyUp

dotnet.addEventHandler tb "KeyDown" txtbox_KeyDown
dotnet.addEventHandler tb "KeyUp" txtbox_KeyUp

dotNet.setLifetimeControl lv #dotnet
dotNet.setLifetimeControl tb #dotnet
dotNet.setLifetimeControl MagmaActiveType_Form #dotnet

MagmaActiveType_Form.ShowModal()
searchForNode()
tb.focus()

)
