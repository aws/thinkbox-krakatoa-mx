-- Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
-- SPDX-License-Identifier: Apache-2.0
--Krakatoa Particle Data Viewer
(
local Krakatoa_ParticleDataViewer_Rollout 	 
local Krakatoa_ParticleDataViewer_FilterDialog
--try(destroyDialog Krakatoa_ParticleDataViewer_Rollout )catch()
--try(destroyDialog Krakatoa_ParticleDataViewer_FilterDialog )catch()
	
local Krakatoa_ParticleDataViewer_FilterMode = #and

local theIniFile = (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini" )
local currentStream 
local layout_def = #()
local ParticleSourcesList = #()
local theCollectedDataTypes = #()
local theCollectedDataArity = #()
local theTotalCount = 0
local SelectionChannelPos = 0
local theChannelNames= #()	
local viewportDisplayDataEnabler=#{1}
local SortVectorBy = #m
local loadPRTInWorldSpace = true
local evaluatePRTMaterial = true
local PositionChannelIndex = 1
local Krakatoa_ParticleDataViewer_FilterDef = #(
			--#("Position",1,#greater,0.0,true),
			--#("Position", 2, #greater, 0.0,true)
		)
local theActiveFilterDef = #()
local theCompTypes = #(#greater,#less, #greaterorequal, #lessorequal, #equal, #notequal, #contains, #startswith, #endswidth, #notcontains)
struct PFlowChannelsToDisplayStruct
(
	Velocity = true,
	ID = true,
	Group = true,
	Age = true,
	LifeSpan = true,
	Scale = true,
	Spin = true,
	Orientation = true,
	Normal = true,
	Tangent = true,
	NormalXTangent = true
)
local PFlowChannelsToDisplay = PFlowChannelsToDisplayStruct()
local theIniFile = getDir #plugcfg + "\\ParticleDataViewerSettings.ini"
local thePFlowChannels = #("Velocity", "ID",  "Group", "Age", "LifeSpan","Scale", "Spin", "Orientation", "Normal", "Tangent", "NormalXTangent") 

fn loadPFlowChannelsToDisplay =
(
	for p in thePFlowChannels do
	(
		theVal = execute (getIniSetting theIniFile "PFlow" p)
		if theVal != OK do setProperty PFlowChannelsToDisplay p theVal
	)
)

struct TPChannelsToDisplayStruct
(
	Position = true,
	Velocity = true,
	ID = true,
	Group = true,
	Age = true,
	LifeSpan = true,
	Mass = true,
	Size = true,
	Scale = true,
	PDV = true
)
local TPChannelsToDisplay = TPChannelsToDisplayStruct()
local theTPChannels = #("Position", "Velocity", "ID", "Group", "Age", "LifeSpan", "Mass", "Size", "Scale", "PDV" ) 
fn loadTPChannelsToDisplay =
(
	for p in theTPChannels do
	(
		theVal = execute (getIniSetting theIniFile "TP" p)
		if theVal != OK do setProperty TPChannelsToDisplay p theVal
	)
)

rollout PFlowChannelsToDisplay_Dialog "PDV Options: PFlow"
(
	button btn_all "All" across:2 width:66 height:17
	button btn_invert "Invert" width:66 height:17
	
	checkbox chk_PFlow_Velocity "Velocity" checked:PFlowChannelsToDisplay.Velocity
	checkbox chk_PFlow_ID "ID" checked:PFlowChannelsToDisplay.ID
	checkbox chk_PFlow_Age "Age" checked:PFlowChannelsToDisplay.Age
	checkbox chk_PFlow_LifeSpan "LifeSpan" checked:PFlowChannelsToDisplay.LifeSpan
	checkbox chk_PFlow_Group "Group" checked:PFlowChannelsToDisplay.Group
	checkbox chk_PFlow_Scale "Scale" checked:PFlowChannelsToDisplay.Scale
	checkbox chk_PFlow_Spin "Spin" checked:PFlowChannelsToDisplay.Spin
	checkbox chk_PFlow_Orientation "Orientation" checked:PFlowChannelsToDisplay.Orientation
	checkbox chk_PFlow_Normal "Normal" checked:PFlowChannelsToDisplay.Normal
	checkbox chk_PFlow_Tangent "Tangent" checked:PFlowChannelsToDisplay.Tangent
	checkbox chk_PFlow_NormalXTangent "NormalXTangent" checked:PFlowChannelsToDisplay.NormalXTangent	
	button btn_OK "OK" across:2 width:66
	button btn_Cancel "Cancel" width:66


	on btn_all pressed do
	(
		for o in PFlowChannelsToDisplay_Dialog.controls where classof o == CheckboxControl do ( o.state = true; setProperty PFlowChannelsToDisplay o.caption true)
	)
	on btn_invert pressed do
	(
		for o in PFlowChannelsToDisplay_Dialog.controls where classof o == CheckboxControl do ( o.state = not o.state; setProperty PFlowChannelsToDisplay o.caption o.state)
	)
		
	on btn_OK pressed do
	(
		for p in thePFlowChannels do setIniSetting theIniFile "PFlow" p ((getProperty PFlowChannelsToDisplay p) as string)
		destroyDialog PFlowChannelsToDisplay_Dialog
		Krakatoa_ParticleDataViewer_Rollout.updateData forceManual:true
	)
	on btn_Cancel pressed do 
	(
		destroyDialog PFlowChannelsToDisplay_Dialog
		loadPFlowChannelsToDisplay()
	)
		
	on chk_PFlow_Velocity changed state do PFlowChannelsToDisplay.Velocity = state
	on chk_PFlow_ID changed state do PFlowChannelsToDisplay.ID = state
	on chk_PFlow_Age changed state do PFlowChannelsToDisplay.Age = state
	on chk_PFlow_LifeSpan changed state do PFlowChannelsToDisplay.LifeSpan = state
	on chk_PFlow_Group changed state do PFlowChannelsToDisplay.Group = state
	on chk_PFlow_Scale changed state do PFlowChannelsToDisplay.Scale = state
	on chk_PFlow_Spin changed state do PFlowChannelsToDisplay.Spin = state
	on chk_PFlow_Orientation changed state do PFlowChannelsToDisplay.Orientation = state
	on chk_PFlow_Normal changed state do PFlowChannelsToDisplay.Normal = state
	on chk_PFlow_Tangent changed state do PFlowChannelsToDisplay.Tangent = state
	on chk_PFlow_NormalXTangent changed state do PFlowChannelsToDisplay.NormalXTangent = state
)

rollout TPChannelsToDisplay_Dialog "PDV Options: TP"
(
	button btn_all "All" across:2 width:66 height:17
	button btn_invert "Invert" width:66 height:17
	checkbox chk_TP_Position "Position" checked:TPChannelsToDisplay.Position
	checkbox chk_TP_Velocity "Velocity" checked:TPChannelsToDisplay.Velocity
	checkbox chk_TP_ID "ID" checked:TPChannelsToDisplay.ID
	checkbox chk_TP_Group "Group" checked:TPChannelsToDisplay.Group
	checkbox chk_TP_Age "Age" checked:TPChannelsToDisplay.Age
	checkbox chk_TP_LifeSpan "LifeSpan" checked:TPChannelsToDisplay.LifeSpan
	checkbox chk_TP_Mass "Mass" checked:TPChannelsToDisplay.Mass
	checkbox chk_TP_Size "Size" checked:TPChannelsToDisplay.Size
	checkbox chk_TP_Scale "Scale" checked:TPChannelsToDisplay.Scale
	checkbox chk_TP_PDV "PDV" checked:TPChannelsToDisplay.PDV
	button btn_OK "OK" across:2 width:66
	button btn_Cancel "Cancel" width:66
	
	on btn_all pressed do
	(
		for o in TPChannelsToDisplay_Dialog.controls where classof o == CheckboxControl do (o.state = true; setProperty TPChannelsToDisplay o.caption true)
	)
	on btn_invert pressed do
	(
		for o in TPChannelsToDisplay_Dialog.controls where classof o == CheckboxControl do (o.state = not o.state; setProperty TPChannelsToDisplay o.caption o.state)
	)
	
	on btn_OK pressed do
	(
		for p in theTPChannels do setIniSetting theIniFile "TP" p ((getProperty TPChannelsToDisplay p) as string)
		destroyDialog TPChannelsToDisplay_Dialog
		Krakatoa_ParticleDataViewer_Rollout.updateData forceManual:true
	)
	on btn_Cancel pressed do 
	(
		destroyDialog TPChannelsToDisplay_Dialog
		loadTPChannelsToDisplay()
	)

	on chk_TP_Position changed state do TPChannelsToDisplay.Position = state
	on chk_TP_Velocity changed state do TPChannelsToDisplay.Velocity = state
	on chk_TP_ID changed state do TPChannelsToDisplay.ID = state
	on chk_TP_Group changed state do TPChannelsToDisplay.Group = state
	on chk_TP_Age changed state do TPChannelsToDisplay.Age = state
	on chk_TP_LifeSpan changed state do TPChannelsToDisplay.LifeSpan = state
	on chk_TP_Mass changed state do TPChannelsToDisplay.Mass = state
	on chk_TP_Size changed state do TPChannelsToDisplay.Size = state
	on chk_TP_Scale changed state do TPChannelsToDisplay.Scale = state
	on chk_TP_PDV changed state do TPChannelsToDisplay.PDV = state
)

rcmenu MainMenu 
(
	subMenu "Load"
	(
		menuItem mnu_loadPRTinWorldSpace "Load PRT Objects In WORLD Space" checked:(loadPRTInWorldSpace == true)
		menuItem mnu_loadPRTinObjectSpace "Load PRT Objects In OBJECT Space" checked:(loadPRTInWorldSpace == false)
		separator sep_10
		menuItem mnu_loadPRTMaterial "Evaluate PRT Object's MATERIAL" checked:(evaluatePRTMaterial == true)
	)
	subMenu "View"
	(
		menuItem mnu_DisplayInfoList "Display Info List" checked:Krakatoa_ParticleDataViewer_Rollout.displayInfoList
		separator sep_100
		menuItem mnu_DisplayArity "Show Channel Data Type And Arity" checked:Krakatoa_ParticleDataViewer_Rollout.DisplayArity
		separator sep_110
		menuItem mnu_DisplayMXSFormat "Show Values in MAXScript Format" checked:(Krakatoa_ParticleDataViewer_Rollout.DisplayFormat == #mxs)
		menuItem mnu_DisplayFormatted8 "Show Formatted Values With Decimal Precision 8" checked:(Krakatoa_ParticleDataViewer_Rollout.DisplayFormat == #format8)
		menuItem mnu_DisplayFormatted12 "Show Formatted Values With Decimal Precision 12" checked:(Krakatoa_ParticleDataViewer_Rollout.DisplayFormat == #format12)
		menuItem mnu_DisplayFormatted16 "Show Formatted Values With Decimal Precision 16" checked:(Krakatoa_ParticleDataViewer_Rollout.DisplayFormat == #format16)
		
		separator sep_120
		
		menuItem mnu_DisplayVectorsInViewport "Draw Vectors In The Viewport" checked:Krakatoa_ParticleDataViewer_Rollout.DisplayVectorsInViewport
		menuItem mnu_ScaleVectorsInViewport10 "Scale Viewport Vectors 10x" checked:(Krakatoa_ParticleDataViewer_Rollout.ScaleVectorsInViewport == 10)
		menuItem mnu_ScaleVectorsInViewportFPS "Scale Viewport Vectors by Frame Rate" checked:(Krakatoa_ParticleDataViewer_Rollout.ScaleVectorsInViewport == FrameRate)
		menuItem mnu_ScaleVectorsInViewportTPF "Scale Viewport Vectors by Ticks Per Frame" checked:(Krakatoa_ParticleDataViewer_Rollout.ScaleVectorsInViewport == TicksPerFrame)
		menuItem mnu_ScaleVectorsInViewportTPS "Scale Viewport Vectors by Ticks Per Second (x4800)" checked:(Krakatoa_ParticleDataViewer_Rollout.ScaleVectorsInViewport == 4800)
		
		separator sep_130		
		menuItem mnu_PFlowOptions "Particle Flow Channels Display Options..."
		menuItem mnu_TPOptions "Thinking Particles Channels Display Options..."
	)
	subMenu "Sort"
	(
		menuItem mnu_SortVectorByString "Sort Vector Channels As Strings" checked:(SortVectorBy == #string)
		menuItem mnu_SortVectorByX "Sort Vector Channels By X Axis" checked:(SortVectorBy == #x)
		menuItem mnu_SortVectorByY "Sort Vector Channels By Y Axis" checked:(SortVectorBy == #y)
		menuItem mnu_SortVectorByZ "Sort Vector Channels By Z Axis" checked:(SortVectorBy == #z)
		menuItem mnu_SortVectorByMagnitude "Sort Vector Channels By Magnitude" checked:(SortVectorBy == #m)
	)
	subMenu "Output"
	(
		menuItem mnu_SelectedLinesToClipboard "Output Selected To Windows Clipboard" 
		menuItem mnu_SelectedLinesToListener "Output Selected To MAXScript Listener" 
		separator sep_210
		menuItem mnu_SelectedLinesToHTML "Output To HTML File" 
		separator sep_220
		menuItem mnu_exploreHTMLOutputFolder "Explore HTML Output Folder..."
	)
	
	on mnu_SelectedLinesToClipboard picked do
	(
		Krakatoa_ParticleDataViewer_Rollout.OutputSelectedLines toClipboard:true
	)
	on mnu_SelectedLinesToListener picked do
	(
		Krakatoa_ParticleDataViewer_Rollout.OutputSelectedLines toClipboard:false
	)	
	on mnu_SelectedLinesToHTML picked do
	(
		Krakatoa_ParticleDataViewer_Rollout.OutputSelectedLinesToHTML()
	)
	on mnu_exploreHTMLOutputFolder picked do
	(
		Krakatoa_ParticleDataViewer_Rollout.exploreHTMLOutputFolder()
	)
	
	on mnu_DisplayMXSFormat picked do
	(
		Krakatoa_ParticleDataViewer_Rollout.DisplayFormat = #mxs
		Krakatoa_ParticleDataViewer_Rollout.updateData forceManual:false
		setIniSetting  theIniFile "ParticleDataViewer" "DataFormat"  (Krakatoa_ParticleDataViewer_Rollout.DisplayFormat as string)
	)
	on mnu_DisplayFormatted8 picked do
	(
		Krakatoa_ParticleDataViewer_Rollout.DisplayFormat = #format8
		Krakatoa_ParticleDataViewer_Rollout.updateData forceManual:false
		setIniSetting  theIniFile "ParticleDataViewer" "DataFormat"  (Krakatoa_ParticleDataViewer_Rollout.DisplayFormat as string)
	)
	on mnu_DisplayFormatted12 picked do
	(
		Krakatoa_ParticleDataViewer_Rollout.DisplayFormat = #format12
		Krakatoa_ParticleDataViewer_Rollout.updateData forceManual:false
		setIniSetting  theIniFile "ParticleDataViewer" "DataFormat"  (Krakatoa_ParticleDataViewer_Rollout.DisplayFormat as string)
	)
	on mnu_DisplayFormatted16 picked do
	(
		Krakatoa_ParticleDataViewer_Rollout.DisplayFormat = #format16
		Krakatoa_ParticleDataViewer_Rollout.updateData forceManual:false
		setIniSetting  theIniFile "ParticleDataViewer" "DataFormat"  (Krakatoa_ParticleDataViewer_Rollout.DisplayFormat as string)
	)
	
	

	on mnu_loadPRTinWorldSpace picked do 
	(
		loadPRTInWorldSpace = true
		setIniSetting  theIniFile "ParticleDataViewer" "LoadPRTInWorldSpace"  (loadPRTInWorldSpace as string)
		Krakatoa_ParticleDataViewer_Rollout.updateData forceManual:false
	)
	on mnu_loadPRTinObjectSpace picked do 
	(
		loadPRTInWorldSpace = false
		setIniSetting  theIniFile "ParticleDataViewer" "LoadPRTInWorldSpace"  (loadPRTInWorldSpace as string)
		Krakatoa_ParticleDataViewer_Rollout.updateData forceManual:false
	)
	on mnu_loadPRTMaterial picked do 
	(
		evaluatePRTMaterial = not evaluatePRTMaterial
		setIniSetting  theIniFile "ParticleDataViewer" "EvaluatePRTMaterial"  (evaluatePRTMaterial as string)
		Krakatoa_ParticleDataViewer_Rollout.updateData forceManual:false
	)


	
	on mnu_DisplayInfoList picked do
	(
		Krakatoa_ParticleDataViewer_Rollout.displayInfoList = not Krakatoa_ParticleDataViewer_Rollout.displayInfoList
		setIniSetting  theIniFile "ParticleDataViewer" "DisplayInfoList"  (Krakatoa_ParticleDataViewer_Rollout.displayInfoList as string)
		Krakatoa_ParticleDataViewer_Rollout.resizeDialog (getDialogSize Krakatoa_ParticleDataViewer_Rollout)
	)
	
	on mnu_DisplayVectorsInViewport picked do
	(
		Krakatoa_ParticleDataViewer_Rollout.DisplayVectorsInViewport = not Krakatoa_ParticleDataViewer_Rollout.DisplayVectorsInViewport
		setIniSetting  theIniFile "ParticleDataViewer" "DisplayVectorsInViewport"  (Krakatoa_ParticleDataViewer_Rollout.DisplayVectorsInViewport as string)
		max views redraw
	)
	
	on mnu_ScaleVectorsInViewport10 picked do
	(
		if Krakatoa_ParticleDataViewer_Rollout.ScaleVectorsInViewport != 10 then
			Krakatoa_ParticleDataViewer_Rollout.ScaleVectorsInViewport = 10
		else
			Krakatoa_ParticleDataViewer_Rollout.ScaleVectorsInViewport = 1
		max views redraw
	)
	
	on mnu_ScaleVectorsInViewportFPS picked do
	(
		if Krakatoa_ParticleDataViewer_Rollout.ScaleVectorsInViewport != FrameRate then
			Krakatoa_ParticleDataViewer_Rollout.ScaleVectorsInViewport = FrameRate
		else
			Krakatoa_ParticleDataViewer_Rollout.ScaleVectorsInViewport = 1
		max views redraw
	)
	
	on mnu_ScaleVectorsInViewportTPF picked do
	(
		if Krakatoa_ParticleDataViewer_Rollout.ScaleVectorsInViewport != TicksPerFrame then
			Krakatoa_ParticleDataViewer_Rollout.ScaleVectorsInViewport = TicksPerFrame
		else
			Krakatoa_ParticleDataViewer_Rollout.ScaleVectorsInViewport = 1
		max views redraw
	)
	
	on mnu_ScaleVectorsInViewportTPS picked do
	(
		if Krakatoa_ParticleDataViewer_Rollout.ScaleVectorsInViewport != 4800 then
			Krakatoa_ParticleDataViewer_Rollout.ScaleVectorsInViewport = 4800
		else
			Krakatoa_ParticleDataViewer_Rollout.ScaleVectorsInViewport = 1
		max views redraw
	)	

	on mnu_SortVectorByString picked do
	(
		SortVectorBy = #string
		Krakatoa_ParticleDataViewer_Rollout.updateData forceManual:true
		Krakatoa_ParticleDataViewer_Rollout.dnc_datalistview.ListViewItemSorter = dotNetObject "ListViewItemComparer" Krakatoa_ParticleDataViewer_Rollout.lastColumnClicked Krakatoa_ParticleDataViewer_Rollout.sortDirection

	)
	on mnu_SortVectorByX picked do
	(
		SortVectorBy = #x
		Krakatoa_ParticleDataViewer_Rollout.updateData forceManual:true
		if Krakatoa_ParticleDataViewer_Rollout.lastColumnClicked > 0 do Krakatoa_ParticleDataViewer_Rollout.dnc_datalistview.ListViewItemSorter = dotNetObject "ListViewItemComparer" Krakatoa_ParticleDataViewer_Rollout.lastColumnClicked Krakatoa_ParticleDataViewer_Rollout.sortDirection
	)
	on mnu_SortVectorByY picked do
	(
		SortVectorBy = #y
		Krakatoa_ParticleDataViewer_Rollout.updateData forceManual:true
		if Krakatoa_ParticleDataViewer_Rollout.lastColumnClicked > 0 do Krakatoa_ParticleDataViewer_Rollout.dnc_datalistview.ListViewItemSorter = dotNetObject "ListViewItemComparer" Krakatoa_ParticleDataViewer_Rollout.lastColumnClicked Krakatoa_ParticleDataViewer_Rollout.sortDirection
	)
	on mnu_SortVectorByZ picked do
	(
		SortVectorBy = #z
		Krakatoa_ParticleDataViewer_Rollout.updateData forceManual:true
		if Krakatoa_ParticleDataViewer_Rollout.lastColumnClicked > 0 do Krakatoa_ParticleDataViewer_Rollout.dnc_datalistview.ListViewItemSorter = dotNetObject "ListViewItemComparer" Krakatoa_ParticleDataViewer_Rollout.lastColumnClicked Krakatoa_ParticleDataViewer_Rollout.sortDirection
	)
	on mnu_SortVectorByMagnitude picked do
	(
		SortVectorBy = #m
		Krakatoa_ParticleDataViewer_Rollout.updateData forceManual:true
		if Krakatoa_ParticleDataViewer_Rollout.lastColumnClicked > 0 do Krakatoa_ParticleDataViewer_Rollout.dnc_datalistview.ListViewItemSorter = dotNetObject "ListViewItemComparer" Krakatoa_ParticleDataViewer_Rollout.lastColumnClicked Krakatoa_ParticleDataViewer_Rollout.sortDirection
	)
	
	on mnu_DisplayArity picked do
	(
		Krakatoa_ParticleDataViewer_Rollout.DisplayArity = not Krakatoa_ParticleDataViewer_Rollout.DisplayArity
		setIniSetting  theIniFile "ParticleDataViewer" "DisplayArity"  (Krakatoa_ParticleDataViewer_Rollout.DisplayArity as string)
		Krakatoa_ParticleDataViewer_Rollout.updateChannelTitles()
	)
	on mnu_PFlowOptions picked do
	(
		createDialog PFlowChannelsToDisplay_Dialog modal:true
	)
	on mnu_TPOptions picked do
	(
		createDialog TPChannelsToDisplay_Dialog modal:true
	)	
)

loadPFlowChannelsToDisplay()
loadTPChannelsToDisplay()

local Krakatoa_ParticleDataViewer_ViewportDisplayData = #{}

rollout Krakatoa_ParticleDataViewer_FilterDialog "Krakatoa - Particle Data Viewer - Define Filter"
(
	local currentFilterLine = 1
	dropdownlist ddl_LoadFilter width:432 offset:[-2,0] across:2
	button btn_saveFilter "Save Filter..." width:140 align:#right
	
	dropdownlist ddl_channelNames "Channel" width:140 across:4 align:#left offset:[-2,2]
	dropdownlist ddl_channelComponent "Value/Component" width:140 align:#center
	dropdownlist ddl_comparisonMode "Comparison Rule" width:140 align:#center height:20 
	edittext edt_value "Value" width:140 align:#right offset:[2,1] labelOnTop:true
	button btn_addRule "Add New Rule" width:140 across:4 
	button btn_cloneFilter "Clone Selected Rule" width:140
	button btn_removeRule "Remove Selected Rule" width:140
	button btn_newFilter "Start New Filter..." width:140
	
	listbox lbx_therules align:#center
	
	radiobuttons rad_compMode labels:#("Match All Rules","Match Any Rule","Match No Rules") align:#center default:(findItem #(#and,#or,#not) Krakatoa_ParticleDataViewer_FilterMode)


	fn updateDropDownLists =
	(
		if lbx_therules.selection > 0 do
		(
			theRule = Krakatoa_ParticleDataViewer_FilterDef[lbx_therules.selection]
			ddl_channelNames.selection = findItem theChannelNames theRule[1]
			ddl_channelComponent.selection = theRule[2]+1
			ddl_comparisonMode.selection = findItem theCompTypes theRule[3]
			edt_value.text = theRule[4] as string		
		)
	)
	
	fn updateFilterDef =
	(
		theActiveFilterDef = for i in Krakatoa_ParticleDataViewer_FilterDef where i[5]==true collect i
	)
	
	
	fn updateLists =
	(
		rad_compMode.state =  findItem #(#and,#or,#not) Krakatoa_ParticleDataViewer_FilterMode
		ddl_channelNames.items = theChannelNames
		ddl_channelComponent.items = #("Value or Magnitude","Component 1","Component 2","Component 3","Component 4")
		ddl_comparisonMode.items = #("Is Greater Than","Is Less Than","Is Greater Or Equal To","Is Less Or Equal To","Is Equal To","Is Not Equal To","Contains","Starts With","Ends With","Does Not Contain")
		local theListItems = #()
		for i = 1 to Krakatoa_ParticleDataViewer_FilterDef.count do
		(
			local theIndex = findItem theChannelNames Krakatoa_ParticleDataViewer_FilterDef[i][1]
			local theComp = ddl_channelComponent.items[Krakatoa_ParticleDataViewer_FilterDef[i][2]+1] 
			local theCompIndex = findItem theCompTypes Krakatoa_ParticleDataViewer_FilterDef[i][3]
			if theIndex > 0 do 
			(
				if theCollectedDataArity[theIndex] == 1 do Krakatoa_ParticleDataViewer_FilterDef[i][2] = 0
				if Krakatoa_ParticleDataViewer_FilterDef[i][2] > theCollectedDataArity[theIndex] do Krakatoa_ParticleDataViewer_FilterDef[i][2] = theCollectedDataArity[theIndex]
				if Krakatoa_ParticleDataViewer_FilterDef[i][2] == 0 do if theCollectedDataArity[theIndex] > 1 and theCompIndex < 5 then theComp = "The Magnitude" else theComp = "The Value"
			)
			txt = if Krakatoa_ParticleDataViewer_FilterDef[i][5] == true then "+ " else "-- "
			txt +=theComp + " of Channel " +Krakatoa_ParticleDataViewer_FilterDef[i][1] + " " + ddl_comparisonMode.items[theCompIndex] + " " + Krakatoa_ParticleDataViewer_FilterDef[i][4] as string
			if i < Krakatoa_ParticleDataViewer_FilterDef.count do 
			(
				txt += (case Krakatoa_ParticleDataViewer_FilterMode of 
					(
						default: " And" 
						#or: " Or"
						#not: " NOT"
					)
				)
			)
			if i == Krakatoa_ParticleDataViewer_FilterDef.count and Krakatoa_ParticleDataViewer_FilterMode == #not do txt+=" NOT"
			
			append theListItems txt
		)
		lbx_therules.items = theListItems
		if lbx_therules.selection == 0 do lbx_therules.selection = lbx_therules.items.count
		if lbx_therules.selection > Krakatoa_ParticleDataViewer_FilterDef.count do lbx_therules.selection = lbx_therules.items.count
		updateDropDownLists()
		updateFilterDef()		
		if  Krakatoa_ParticleDataViewer_Rollout.chk_useFilter.checked do Krakatoa_ParticleDataViewer_Rollout.updateData()
		
		
	)

	fn updateFileList =
	(
		local theFiles  = getFiles (Krakatoa_PresetsDirectory+ "\\KrakatoaViewerFilters\\*.kvf")
		ddl_LoadFilter.items = for i in theFiles collect getFileNameFile i
	)	
	
	on lbx_therules doubleClicked itm do 
	(
		Krakatoa_ParticleDataViewer_FilterDef[itm][5] = not Krakatoa_ParticleDataViewer_FilterDef[itm][5] 
		updateLists()
	)
	
	on ddl_channelNames selected itm do
	(
		if itm > 0 and lbx_therules.selection > 0 do Krakatoa_ParticleDataViewer_FilterDef[lbx_therules.selection][1] = ddl_channelNames.selected
		updateLists()
	)
	on ddl_channelComponent selected itm do
	(
		if itm > 0 and lbx_therules.selection > 0 do Krakatoa_ParticleDataViewer_FilterDef[lbx_therules.selection][2] = itm-1
		updateLists()	
	)	
	on ddl_comparisonMode selected itm do
	(
		if itm > 0 and lbx_therules.selection > 0 do Krakatoa_ParticleDataViewer_FilterDef[lbx_therules.selection][3] = theCompTypes[itm]
		updateLists()
	)		
	on edt_value entered txt do
	(
		if lbx_therules.selection > 0 do
		(
			local theValue = if lbx_therules.selection > 0 and Krakatoa_ParticleDataViewer_FilterDef[lbx_therules.selection][1] == "Group" then
				txt
			else
				try(execute txt)catch(undefined)
			if theValue == OK do theValue = 0
			if theValue == undefined do theValue = 0		
			Krakatoa_ParticleDataViewer_FilterDef[lbx_therules.selection][4] = theValue
		)
		updateLists()
	)
	on rad_compMode changed state do 
	(
		Krakatoa_ParticleDataViewer_FilterMode = case state of 
		(
			1: #and 
			2: #or
			3: #not
		)
		updateLists()
	)	

	
	on lbx_therules selected itm do 
	(
		updateDropDownLists()
	)

	on btn_newFilter pressed do
	(
		local q = querybox "Are you sure you want to clear the current filter and start a new one?" title:"Start New Filter"
		if q then Krakatoa_ParticleDataViewer_FilterDef = #()
		updateLists()
	)
	
	on btn_addRule pressed do
	(
		local theValue = if lbx_therules.selection > 0 and Krakatoa_ParticleDataViewer_FilterDef[lbx_therules.selection][1] == "Group" then
			txt
		else
			execute (edt_value.text)
		if theValue == OK do theValue = 0
		if theValue == undefined do theValue = 0
		append Krakatoa_ParticleDataViewer_FilterDef #(ddl_channelNames.selected, ddl_channelComponent.selection-1, theCompTypes[ddl_comparisonMode.selection], theValue , true )
		updateLists()
		lbx_therules.selection = lbx_therules.items.count
	)
	
	on btn_cloneFilter pressed do
	(
		if lbx_therules.selection > 0 do 
			insertItem (deepCopy Krakatoa_ParticleDataViewer_FilterDef[lbx_therules.selection]) Krakatoa_ParticleDataViewer_FilterDef lbx_therules.selection
		updateLists()
	)
	
	on btn_saveFilter pressed do
	(
		makeDir (Krakatoa_PresetsDirectory+ "\\KrakatoaViewerFilters") all:true
		local theFileToSave = getSaveFileName filename:(Krakatoa_PresetsDirectory+ "\\KrakatoaViewerFilters\\Filter.kvf")  types:"Krakatoa Particle Viewer Filter (*.KVF)|*.KVF"
		if theFileToSave != undefined do
		(
			theFileHandle = createFile theFileToSave
			with PrintAllElements on format "global Krakatoa_ParticleDataViewer_FilterDef=%\n" Krakatoa_ParticleDataViewer_FilterDef to:theFileHandle 
			format "global Krakatoa_ParticleDataViewer_FilterMode=%\n" Krakatoa_ParticleDataViewer_FilterMode to:theFileHandle 
			close theFileHandle 	
			updateFileList()
		)
	)
	

	on ddl_LoadFilter selected itm do
	(
		fileIn (Krakatoa_PresetsDirectory+ "\\KrakatoaViewerFilters\\" + ddl_LoadFilter.selected+".KVF")
		Krakatoa_ParticleDataViewer_FilterDef = deepCopy ::Krakatoa_ParticleDataViewer_FilterDef
		updateLists()	
	)
	
	on btn_removeRule pressed do
	(
		if lbx_therules.selection > 0 do 
			deleteItem Krakatoa_ParticleDataViewer_FilterDef lbx_therules.selection
		updateLists()
	)
	
	on Krakatoa_ParticleDataViewer_FilterDialog open do
	(
		updateFileList()
		updateLists()
	)
	
	on Krakatoa_ParticleDataViewer_FilterDialog close do
	(
		updateFilterDef()
	)	
)
	
rollout Krakatoa_ParticleDataViewer_Rollout "Krakatoa - Particle Data Viewer"
(
	
	local theChannels 
	local theIsChannelInFileList = #()
	local displayArity = true
	local displayInfoList = true
	local DisplayVectorsInViewport = true
	local ScaleVectorsInViewport = 1
	local sortDirection = 1
	local lastColumnClicked = 0	
	local DisplayFormat = #mxs
	
	button btn_getList "Get" width:30 height:18 pos:[5,3]
	dropdownlist ddl_sources align:#left width:210 pos:[37,2] 
	spinner spn_fromIndex "First:" fieldwidth:50 type:#integer range:[1,100000000,1] pos:[250,4] scale:1000
	spinner spn_count "Count" fieldwidth:50 type:#integer range:[1,100000000,1000] pos:[340,4] scale:100
	spinner spn_everyNth "Nth:" fieldwidth:35 type:#integer range:[1,100000,1] pos:[435,4] 
	
	checkbutton chk_selectedOnly ">Selected" pos:[508,3] height:18 width:55
	
	checkbutton chk_useFilter ">Use" pos:[570,3] height:18 width:34
	button btn_setFilter "Filter..." pos:[604,3] width:50 height:18
	
	dropdownlist ddl_updateMode pos:[660,1] items:#("Manual","Auto","Stats") width:65
	button btn_update "UPDATE" pos:[725,3] width:70 height:18
	
	progressbar prg_progress height:6 offset:[-8,0] align:#left color:red width:790 
	dotNetControl dnc_datalistview "ListView" width:790 height:400 align:#center offset:[0,-4] 
	edittext edt_infoString readOnly:true bold:true fieldwidth:790 align:#center	offset:[-2,0] 
	dotNetControl dnc_infolistview "ListView" width:790 height:240 align:#center	
	

	fn createStream =
	(
		if ddl_sources.items.count > 0 and ddl_sources.selection > 0 then
		(
			try(currentStream.close())catch()
			if isValidNode ParticleSourcesList[ddl_sources.selection] then
			(
				case classof ParticleSourcesList[ddl_sources.selection] of
				(
					Thinking : currentStream = ParticleSourcesList[ddl_sources.selection]
					PF_Source : currentStream = ParticleSourcesList[ddl_sources.selection]
					default : (
						try
						(
							currentStream = FranticParticles.GetPRTObjectIStream ParticleSourcesList[ddl_sources.selection] loadPRTInWorldSpace evaluatePRTMaterial
						)
						catch
						(
							currentStream = undefined
						)
					)
				)
			)
			else
				currentStream = undefined
		)
		else 
			currentStream = undefined
	)
	
	fn getColumnSize channelName =
	(
		local theResult = case channelName of
		(
			default:100
			"Position": 150
			"ID": 70
		)
		local theVal = execute (getIniSetting theIniFile "ParticleDataViewerColumnWidth" channelName )
		if theVal != OK do theResult = theVal
		theResult
	)
	local theGroupsArray = #()
	local theGroupNames = #()
	local thePDVNodesArray = #()
	local theDSArray = #()
	fn collectGroupsRecursively theParent theName=
	(
		append theGroupsArray theParent
		append theGroupNames (theName as string)
		for i in getPropNames theParent do
		(
			theProp = getProperty theParent i
			if (classof theProp) == PGroup do
			(
				collectGroupsRecursively theProp i 
			)
		)
	)
	fn collectGroups =
	(
		theGroupsArray = #()
		collectGroupsRecursively currentStream.GroupManager "All"
	)		
	
	fn collectDSRecursively theParent =
	(
		append theDSArray theParent
		for i = 1 to theParent.numsubs where matchpattern theParent[i].name pattern:"DS*" do
			collectDSRecursively theParent[i].object
	)
	
	fn collectPDVNodes =
	(
		thePDVNodesArray = #()
		theDSArray = #()
		collectDSRecursively currentStream.MasterDynamic
		deleteItem theDSArray 1
		for ds in theDSArray do
		(
			for o in ds.Operators do--where classof o == tp_ParticleDataViewer do 
			(
				if hasProperty o #script and classof o.script == tp_ParticleDataViewer do
				(
					append thePDVNodesArray o
				)
			)
		)
	)
	
	fn initDataListView =
	(
		local lv = dnc_datalistview
		layout_def = #(#("Index",40))
		local allFileChannels = #()
		--local theChannels 
		if currentStream != undefined do
		(
			case classof currentStream of
			(
				Thinking :
				(
					theGroupsArray = #()
					theGroupNames = #()
					collectGroups()
					collectPDVNodes()
					--print thePDVNodesArray
					theChannels = #(#("PositionDT","float32",3))
					PositionChannelIndex = 1
					if TPChannelsToDisplay.Position == true do append theChannels #("Position","float32",3)
					if TPChannelsToDisplay.Velocity == true do append theChannels #("Velocity","float32",3)
					if TPChannelsToDisplay.ID == true do append theChannels #("ID","int32",1) 
					if TPChannelsToDisplay.Group == true do append theChannels #("Group","string",0)
					if TPChannelsToDisplay.Age == true do append theChannels #("Age","float32",1)  
					if TPChannelsToDisplay.LifeSpan == true do append theChannels #("LifeSpan","float32",1)
					if TPChannelsToDisplay.Mass == true do append theChannels #("Mass","float32",1)
					if TPChannelsToDisplay.Size == true do append theChannels #("Size","float32",1) 
					if TPChannelsToDisplay.Scale == true do append theChannels #("Scale","float32",3)
					if TPChannelsToDisplay.PDV == true do 
					(
						for o in thePDVNodesArray do
						(
							--print o.script.dataArray[1]
							case o.script.dataArray[1] of
							(
								default: append theChannels #(o.GetName(), "float32", 1)
								#point3: append theChannels #(o.GetName(), "float32", 3)
								#Float: append theChannels #(o.GetName(), "float32", 1)
							)
						)
					)
				)
				PF_Source : 
				(
					theGroupsArray = #()
					theGroupNames = #()
					theChannels = #(#("Position","float32",3))
					PositionChannelIndex = 1
					if PFlowChannelsToDisplay.Velocity == true do append theChannels #("Velocity","float32",3)
					if PFlowChannelsToDisplay.ID == true do append theChannels #("ID","int32",1)
					if PFlowChannelsToDisplay.Group == true do append theChannels #("Group","string",0)
					if PFlowChannelsToDisplay.Age == true do append theChannels #("Age","float32",1)
					if PFlowChannelsToDisplay.LifeSpan == true do append theChannels #("LifeSpan","float32",1)
					if PFlowChannelsToDisplay.Scale == true do append theChannels #("Scale","float32",3)
					if PFlowChannelsToDisplay.Spin == true do append theChannels #("Spin","float32",3) 
					if PFlowChannelsToDisplay.Orientation == true do append theChannels #("Orientation","float32",3)
					if PFlowChannelsToDisplay.Normal == true do append theChannels #("Normal", "float32", 3) 
					if PFlowChannelsToDisplay.Tangent == true do  append theChannels #("Tangent", "float32", 3)
					if PFlowChannelsToDisplay.NormalXTangent == true do  append theChannels #("NormalXTangent", "float32", 3)
				)
				default:
				(
					theChannels = currentStream.GetChannels()
					for i = 1 to theChannels.count do ( 
						theChannels[i] = filterString theChannels[i] " []"
						if theChannels[i].count == 3 then (
							theChannels[i][3] = theChannels[i][3] as integer
						) else (
							--This happens with "Position float32" without an arity. We assume it is 1
							theChannels[i][3] = 1
						)
					)
					
					
					allFileChannels = #()
					if classof ParticleSourcesList[ddl_sources.selection].baseobject == KrakatoaPRTLoader then
					(
						for f in ParticleSourcesList[ddl_sources.selection].fileList do
						(
							local theFile = f
							if not doesFileExist theFile do
							(
								local thePattern = (FranticParticles.ReplaceSequenceNumberWithHashes f)
								thePattern = substituteString thePattern "#" "*"
								local thePossibleFiles = getFiles thePattern
								if thePossibleFiles.count > 0 do theFile = thePossibleFiles[1]
							)
							if doesFileExist theFile do 
								for i in FranticParticles.GetFileParticleChannels theFile where findItem allFileChannels i[1] == 0 do append allFileChannels i[1]
						)
					)
					else
						allFileChannels = for i in theChannels collect i[1]
							
					PositionChannelIndex = -1
					for i = 1 to theChannels.count where matchPattern theChannels[i][1] pattern:"Position" do PositionChannelIndex = i
				)
			)
			theChannelNames = for i in theChannels collect i[1]
			theIsChannelInFileList = for i = 1 to theChannelNames.count collect (findItem allFileChannels theChannelNames[i] > 0)
			
			theCollectedDataTypes = #()
			theCollectedDataArity = #()
			SelectionChannelPos = 0
				
			for i = 1 to theChannels.count do
			(
				if displayArity == true then
					append layout_def #((if theIsChannelInFileList[i] == true then "" else ">> ")+(theChannels[i][1]+" "+theChannels[i][2]+"["+theChannels[i][3] as string+"]"),getColumnSize theChannels[i][1])
				else 
					append layout_def #(((if theIsChannelInFileList[i] == true then "" else ">> ")+theChannels[i][1]),getColumnSize theChannels[i][1])
					
				append theCollectedDataArity theChannels[i][3]
				if matchPattern theChannels[i][1] pattern:"Selection" do SelectionChannelPos = i
				
				for j = 1 to theChannels[i][3] do 
				(
					append theCollectedDataTypes #(theChannels[i][1], theChannels[i][2], theChannels[i][3], j, 10000000000000L,-10000000000000L,0,0)
				)
				if theChannels[i][3] == 3 do 
					append theCollectedDataTypes #(theChannels[i][1], theChannels[i][2], theChannels[i][3], "Magnitude", 10000000000000L,-10000000000000L,0,0)
					
			)
		)
		lv.Clear()
		lv.backColor = (dotNetClass "System.Drawing.Color").fromARGB 221 221 225
		lv.View = (dotNetClass "System.Windows.Forms.View").Details
		lv.gridLines = true 
		lv.fullRowSelect = true 
		lv.checkboxes = false
		lv.hideSelection = false		
		for i in layout_def do
			lv.Columns.add i[1]  i[2]
	) 
	
	fn updateChannelTitles =
	(
		layout_def = #(#("Index",40))
		for i = 1 to theChannels.count do
		(		
			local theSortString = ""
			if viewportDisplayDataEnabler[i+1] 	== true do theSortString = "*"
			
			if i == lastColumnClicked do
				theSortString += (if sortDirection == 1 then "[A] " else "[D] ")
			if displayArity == true then
				append layout_def #(theSortString+(if theIsChannelInFileList[i] == true then "" else ">> ")+(theChannels[i][1]+" "+theChannels[i][2]+"["+theChannels[i][3] as string+"]"),getColumnSize theChannels[i][1])
			else 
				append layout_def #((theSortString+(if theIsChannelInFileList[i] == true then "" else ">> ")+theChannels[i][1]),getColumnSize theChannels[i][1])		
		)	
		for i = 1 to layout_def.count do
			dnc_datalistview.Columns.Item[i-1].Text = layout_def[i][1]
	)
	
	fn initInfoListView =
	(
		local lv = dnc_infolistview
		local infolayout_def = #(#("Channel",100),#("Type",60),#("Cmp.",40),#("Min.",120),#("Max.",120),#("Average",120)) --,#("Median",120))
		for i = 1 to infolayout_def.count do
		(
			local theVal = execute (getIniSetting theIniFile "ParticleDataViewerInfoColumnWidth" infolayout_def[i][1])
			if theVal != OK do infolayout_def[i][2] = theVal
		)
		lv.Clear()
		lv.backColor = (dotNetClass "System.Drawing.Color").fromARGB 221 225 221 
		lv.View = (dotNetClass "System.Windows.Forms.View").Details
		lv.gridLines = true 
		lv.fullRowSelect = true 
		lv.checkboxes = false
		lv.hideSelection = false		
		for i in infolayout_def do
			lv.Columns.add i[1]  i[2]
	) 	
	
	fn getListViewSelection lv =	--returns an array of the selected ListView items
	(
		try
			for i = 1 to lv.items.count where lv.items.item[i-1].Selected collect i
		catch 
			#()
	)
	
	fn applyFilters theData =
	(
		local passedFilter = #{}
		for i = 1 to theActiveFilterDef.count do
		(
			local aRule = theActiveFilterDef[i]
			
			local theIndex = findItem theChannelNames aRule[1]
			if theIndex > 0 do
			(
				theValue = theData[theIndex]

				
				passedFilter[i] = case aRule[3]	of
				(
					#greater: (
									if aRule[2] > 0 then 
										theValue = theValue[aRule[2]]
									else 
										try(theValue = length theValue)catch()						
									try(theValue > aRule[4])catch(false)
					)
					#less: (
									if aRule[2] > 0 then 
										theValue = theValue[aRule[2]]
									else 
										try(theValue = length theValue)catch()						
									try(theValue < aRule[4])catch(false)
					)
					#greaterorequal: 
					(
									if aRule[2] > 0 then 
										theValue = theValue[aRule[2]]
									else 
										try(theValue = length theValue)catch()						
									try(theValue >= aRule[4])catch(false)
					)
					#lessorequal: (
									if aRule[2] > 0 then 
										theValue = theValue[aRule[2]]
									else 
										try(theValue = length theValue)catch()						
									try(theValue <= aRule[4])catch(false)
					)
					#equal: theValue == aRule[4]
					#notequal: theValue != aRule[4]
					#contains: matchPattern (theValue as string) pattern:("*"+aRule[4] as string + "*")
					#startswith: matchPattern (theValue as string) pattern:(aRule[4] as string + "*")
					#endswidth: matchPattern (theValue as string) pattern:("*"+aRule[4] as string)
					#notcontains: not matchPattern (theValue as string) pattern:("*"+aRule[4] as string + "*")
				)
			)
		)
		case Krakatoa_ParticleDataViewer_FilterMode of
		(
			default: passedFilter.numberset == theActiveFilterDef.count 
			#or: passedFilter.numberset > 0
			#not: passedFilter.numberset == 0
		)
	)
	
	fn redrawViewsFunction =
	(
		gw.setTransform (matrix3 1)
		if PositionChannelIndex > 0 do 
		(
			for i in Krakatoa_ParticleDataViewer_ViewportDisplayData where i <= dnc_datalistview.items.count do
			(
				local thePos = (execute dnc_datalistview.items.item[i-1].subItems.item[PositionChannelIndex].text)
				gw.Marker thePos #circle color:red
				theText = ""
				local cnt = 0
				for k in viewportDisplayDataEnabler do
				(
					theName =if k == 1 then  "" else theChannelNames[k-1]+ ":"
					theText = theName + dnc_datalistview.items.item[i-1].subItems.item[k-1].text +"  "
					gw.wText (gw.wTransPoint (thePos+[0,0,-1*(cnt)])) theText color:yellow
					
					if DisplayVectorsInViewport == true and k > 1 and theChannels[k-1][3] == 3 do
						try (gw.Polyline #(thePos, thePos+((execute dnc_datalistview.items.item[i-1].subItems.item[k-1].text)*ScaleVectorsInViewport) ) false )catch()
						
					cnt+=1
				)
			)
		)
		gw.enlargeUpdateRect #whole 
		gw.updateScreen()
	)
	
	fn readParticleDataFromTP start current =
	(
		local pid = start+current-1
		if currentStream.isAlive pid then 
		(
			theScale = 
			try
			(
				local theArray = #((currentStream.PositionDT pid 0))
				if TPChannelsToDisplay.Position == true do append theArray (currentStream.PositionDT pid -1)
				if TPChannelsToDisplay.Velocity == true do append theArray (currentStream.Velocity pid)
				if TPChannelsToDisplay.ID == true do append theArray (currentStream.UniqueID pid)
				if TPChannelsToDisplay.Group == true do append theArray theGroupNames[(findItem theGroupsArray (currentStream.Group pid))]
				if TPChannelsToDisplay.Age == true do append theArray (currentStream.Age pid).frame
				if TPChannelsToDisplay.LifeSpan == true do append theArray (currentStream.LifeSpan pid).frame
				if TPChannelsToDisplay.Mass == true do append theArray (currentStream.Mass pid)
				if TPChannelsToDisplay.Size == true do append theArray (currentStream.Size pid)
				if TPChannelsToDisplay.Scale == true do append theArray ((currentStream.TransformDT pid -1).scalepart / (currentStream.Size pid))
				if TPChannelsToDisplay.PDV == true do 
				(		
					for o in thePDVNodesArray do
					(
						local theVal = case o.script.dataArray[1] of
						(
							default: "--"
							#point3:  if o.script.dataArray[pid+2] == undefined then "--" else o.script.dataArray[pid+2]
							#Float: if o.script.dataArray[pid+2] == undefined then "--" else o.script.dataArray[pid+2]
						)
						append theArray theVal
					)
				)
				theArray
			)catch("")
		)
		else
			""
	)
	
	fn readParticleDataFromPFlow start current =
	(
		local pid = start+current
		if pid <= currentStream.numParticles() then
		(
			local returnArray = #((currentStream.getParticlePosition pid))
			if PFlowChannelsToDisplay.Velocity == true do append returnArray (currentStream.getParticleSpeed  pid)
			if PFlowChannelsToDisplay.ID == true do append returnArray (currentStream.getParticleID  pid)
			if PFlowChannelsToDisplay.Group == true do append returnArray (currentStream.getParticleGroup pid).name
			if PFlowChannelsToDisplay.Age == true do append returnArray (currentStream.getParticleAge pid).frame
			if PFlowChannelsToDisplay.LifeSpan == true do append returnArray (currentStream.getParticleLifeSpan pid).frame
			if PFlowChannelsToDisplay.Scale == true do append returnArray (currentStream.getParticleScaleXYZ pid)
			if PFlowChannelsToDisplay.Spin == true do append returnArray (theVal = ((currentStream.getParticleSpin pid) as eulerangles); [theVal.x, theVal.y, theVal.z])
			if PFlowChannelsToDisplay.Orientation == true do append returnArray (theVal = (currentStream.getParticleOrientation pid); (Point3 theVal.x theVal.y theVal.z) )
			if PFlowChannelsToDisplay.Normal == true do append returnArray (normalize (currentStream.getParticleTM pid).row1)
			if PFlowChannelsToDisplay.Tangent == true do  append returnArray (normalize (currentStream.getParticleTM pid).row2)
			if PFlowChannelsToDisplay.NormalXTangent == true do  append returnArray (normalize (currentStream.getParticleTM pid).row3)
			returnArray
		)	
		else
			""
	)
	
	fn populateDataListView =
	(
		local st = timestamp()
		local lv = dnc_datalistview
		local theRange = #()
		lv.Update()
		local rangeStart = spn_fromIndex.value
		local theMode = #prt
		local theCount = case classof currentStream of 
		(
			Thinking: (
				theMode = #tp
				currentStream.numParticles 
			)
			PF_Source: 
			(
				theMode = #pflow
				currentStream.numParticles()
			)
			default: currentStream.getCount()
		)
		

		local PRTLoadMode = if loadPRTInWorldSpace then "World Space" else "Object Space"
		local PRTMatMode = if evaluatePRTMaterial  then "+Material" else "-No Material"
		local theTitle = "Krakatoa - Particle Data Viewer - Frame "+ (currentTime.frame as integer) as string 
		if theMode == #prt do 
		(
			theTitle += " - " + PRTLoadMode + PRTMatMode
		)
		Krakatoa_ParticleDataViewer_Rollout.title = theTitle
		
		--local rangeEnd = if theCount == undefined then (rangeStart+spn_count.value-1) else amin #((rangeStart+spn_count.value-1), theCount)
		local rangeEnd = spn_count.value
		local rangeStep = spn_everyNth.value
		local cnt = rangeStep 
		local theData = ""
		theTotalCount = 0
		theAverageDivider = 0
		
		lv.SuspendLayout()
		
		local theFormatString = case Krakatoa_ParticleDataViewer_Rollout.DisplayFormat of
		(
			default: "-8.8f"
			#format12: "-12.12f"
			#format16: "-16.16f"
		)
		
		
		if classof currentStream != Thinking and classof currentStream != PF_Source do currentStream.skipParticles (rangeStart-1)
		for i = 1 to rangeEnd while theData != undefined do
		(
			prg_progress.value = 100.0 * i / (rangeEnd)
			theData = case classof currentStream of
			(
				Thinking: readParticleDataFromTP (rangeStart-1) i 
				PF_Source: readParticleDataFromPFlow (rangeStart-1) i 
				default: currentStream.readParticle()
			)
			--format "%\n" theData
			--if i >= rangeStart do
			(
				cnt+=1 
				if cnt >= rangeStep do
				(
					cnt = 0
					if theData != undefined AND theData != "" and (not chk_useFilter.checked OR applyFilters theData) AND (not chk_selectedOnly.checked OR (SelectionChannelPos > 0 and (try(theData[SelectionChannelPos] > 0.0)catch(false)) ) ) do
					(
						theTotalCount += 1
						if ddl_updateMode.selection < 3 do
						(	
							local li = dotNetObject "System.Windows.Forms.ListViewItem" ((i+rangeStart-1) as string) 
							(li.SubItems.Item 0).tag = (i+rangeStart-1) as float
							(li.SubItems.Item 0).Name = "Index"
						)
						local dataCounter = 0
						for theValue = 1 to theData.count do 
						(
							if ddl_updateMode.selection < 3 do
							(
								local theValueString = theData[theValue] as string
								if Krakatoa_ParticleDataViewer_Rollout.DisplayFormat != #mxs do
								(
									theValueString = case classof theData[theValue] of
									(
										Float: (formattedPrint theData[theValue] format:theFormatString) 
										Point3: (formattedPrint theData[theValue] format:theFormatString) 
										Quat: (formattedPrint theData[theValue] format:theFormatString) 
										default: theValueString
									)
								)								
								subLi = li.SubItems.add theValueString
								subLi.tag = case classof theData[theValue] of
								(
									default: theData[theValue] as string
									Point3: ( 
												case SortVectorBy of
												(
													default: theData[theValue] as string
													#x: theData[theValue].x
													#y: theData[theValue].y
													#z: theData[theValue].z
													#m: length theData[theValue]
												)
												/*if matchPattern layout_def[theValue+1][1] pattern:"Velocity*"  then 
													length theData[theValue]
												else 
												(
													type = dotNetClass "System.Int32[]"
													dotnet.ValueToDotNetObject #(theData[theValue].x,theData[theValue].y,theData[theValue].z,length theData[theValue]) type
												)*/
									)
									Float: theData[theValue]
									Integer: theData[theValue] as float
								)
								subLi.name = theChannelNames[theValue]
							)
							if theData[theValue] != "--" do
							(
								if theCollectedDataArity[theValue] == 1 then
								(
									dataCounter+=1
									if matchPattern theCollectedDataTypes[dataCounter][2] pattern:"int32" do theData[theValue] = theData[theValue] as Integer64
									if theData[theValue] < theCollectedDataTypes[dataCounter][5] do theCollectedDataTypes[dataCounter][5] = theData[theValue]
									if theData[theValue] > theCollectedDataTypes[dataCounter][6] do theCollectedDataTypes[dataCounter][6] = theData[theValue]
									theCollectedDataTypes[dataCounter][7] += theData[theValue]
									theCollectedDataTypes[dataCounter][8] += 1
								)
								else
								(
									for j = 1 to theCollectedDataArity[theValue] do
									(
										dataCounter+=1
										if theData[theValue][j] < theCollectedDataTypes[dataCounter][5] do theCollectedDataTypes[dataCounter][5] = theData[theValue][j]
										if theData[theValue][j] > theCollectedDataTypes[dataCounter][6] do theCollectedDataTypes[dataCounter][6] = theData[theValue][j]
										theCollectedDataTypes[dataCounter][7] += theData[theValue][j]
										theCollectedDataTypes[dataCounter][8] += 1
									)
									if theCollectedDataArity[theValue] == 3 do
									(
										dataCounter+=1
										if length theData[theValue] < theCollectedDataTypes[dataCounter][5] do theCollectedDataTypes[dataCounter][5] = length theData[theValue]
										if length theData[theValue] > theCollectedDataTypes[dataCounter][6] do theCollectedDataTypes[dataCounter][6] = length theData[theValue]
										theCollectedDataTypes[dataCounter][7] += length theData[theValue]
										theCollectedDataTypes[dataCounter][8] += 1
									)
								)
							)
						)
						if ddl_updateMode.selection < 3 do append theRange li
					)--end if theData
				)--end if cnt
			)--end if i
		)--end i loop
		if theTotalCount != 0 do 
		(
			for i = 1 to theCollectedDataTypes.count do 
			(
				if theCollectedDataTypes[i][8] != 0 then theCollectedDataTypes[i][7] /= theCollectedDataTypes[i][8] else theCollectedDataTypes[i][7] = "--" --calc. average
				if theCollectedDataTypes[i][5] == 10000000000000L do theCollectedDataTypes[i][5] = "--"
				if theCollectedDataTypes[i][6] == -10000000000000L do theCollectedDataTypes[i][6] = "--"
			)
		)
		if ddl_updateMode.selection < 3 do lv.Items.AddRange theRange 
		prg_progress.value = 0
		local txt = "Showing " + theTotalCount as string 
		if chk_selectedOnly.checked do txt+=" Selected"
		if classof currentStream != Thinking and  classof currentStream != PF_Source and currentStream.getCount() != undefined then 
			txt+=" of " + (currentStream.getCount()) as string + " Total Particles."
		else if classof currentStream == Thinking then
			txt+=" of " + (currentStream.NumParticles) as string + " Total Particles."
		else if classof currentStream == PF_Source then
			txt+=" of " + (currentStream.NumParticles()) as string + " Total Particles."
		else
			txt+=" Particles. Total Count Unknown."
		if chk_useFilter.checked do 
		(
			txt+= " Filtered by \"" 
			if Krakatoa_ParticleDataViewer_FilterMode == #not do txt+="NOT("
			for i = 1 to theActiveFilterDef.count do
			(
				theCompSign = case theActiveFilterDef[i][3] of
				(
					#greater: ">"
					#less: "<"
					#equal: "=="
					#greaterorequal: ">="
					#lessorequal: "<="
					#notequal: "!="
					#contains: " contains "
					#startswith: " starts with "
					#endswidth: " ends with " 
					#notcontains: " does not contain "
				)
				txt+= theActiveFilterDef[i][1] as string 
				if theActiveFilterDef[i][2] > 0 do txt += "["+theActiveFilterDef[i][2] as string +"] " 
				txt += theCompSign + " " + theActiveFilterDef[i][4] as string 
				if i<theActiveFilterDef.count  do txt += if Krakatoa_ParticleDataViewer_FilterMode == #or then " OR " else " AND "
			)
			if Krakatoa_ParticleDataViewer_FilterMode == #not do txt+=")"
			txt+="\""
		)			
		edt_infoString.text = txt
		lv.ResumeLayout false
		popprompt()
		pushprompt ("PDV Update in "+ (((timestamp()-st)/1000.0) as string)+"sec.")
		--format "PDV Update: %ms\n" (timestamp()-st)
	)
	fn getAverage theArray =
	(
		theSum = 0
		for i in theArray do theSum+=i
		theSum/theArray.count
	)
	fn getMedian theArray =
	(
		if theArray.count > 0 then
		(
			sort theArray
			local theIndex = theArray.count/2
			if theIndex == 0 do theIndex = 1
			theArray[theIndex]
		)
		else "N/A"
	)
	fn populateInfoListView =
	(
		local theRange = #()
		local lv = dnc_infolistview
		/*
		if classof currentStream == Thinking then
			theChannels = #(#("Position","float32",3), #("Velocity","float32",3), #("Mass","float32",1))
		else
			theChannels = currentStream.GetChannels()
		*/
		for i = 1 to theCollectedDataTypes.count do
		(
			local li = dotNetObject "System.Windows.Forms.ListViewItem" theCollectedDataTypes[i][1] --channel name
			li.SubItems.add (theCollectedDataTypes[i][2] + "["+theCollectedDataTypes[i][3] as string + "]") --channel type
			li.SubItems.add (theCollectedDataTypes[i][4] as string) --component
			li.SubItems.add (theCollectedDataTypes[i][5] as string) 
			li.SubItems.add (theCollectedDataTypes[i][6] as string)
			li.SubItems.add (theCollectedDataTypes[i][7] as string)
			append theRange li
		)
		lv.Items.AddRange theRange 
	)
	
	fn CompileComparer = 
	(
		local source = ""
		source+="using System;\n"
		source+="using System.Windows.Forms;\n"
		source+="using System.Collections;\n"
		source+="public class ListViewItemComparer : IComparer\n"
		source+="{\n"
		source+="  private int col;\n"
		source+="  private int sort;\n"
		source+="  public ListViewItemComparer()\n"
		source+="  {\n"
		source+="      col = 0;\n"
		source+="      sort = 1;\n"
		source+="  }\n"
		source+="  public ListViewItemComparer(int column, int sorting)\n"
		source+="  {\n"
		source+="    sort = sorting;\n"
		source+="    col = column;\n"
		source+="  }\n"
		source+="  public int Compare(object x, object y)\n"
		source+="  {\n"
		--source+="      return String.Compare(((ListViewItem)x).SubItems[col].Text, ((ListViewItem)y).SubItems[col].Text);\n"
		source+="      if ((((ListViewItem)x).SubItems[col].Tag.GetType() == typeof(float))){\n"
		source+="      float compResult = (((float)((ListViewItem)x).SubItems[col].Tag) - ((float)((ListViewItem)y).SubItems[col].Tag));\n"
		source+="      if (compResult>0) return sort * 1; if (compResult < 0) return sort * -1; return 0;"
		--source+="      } else { float compResult = (((((ListViewItem)x).SubItems[col].Tag).Get(3) ) - ((((ListViewItem)y).SubItems[col].Tag).Get(3) )) ;\n"
		--source+="      if (compResult>0) return sort * 1; if (compResult < 0) return sort * -1; return 0;\n}\n"

		source+="   } else \n"
		source+="   return ((String.Compare(((ListViewItem)x).SubItems[col].Text, ((ListViewItem)y).SubItems[col].Text))*sort);\n"
		
		--source+="      } else { \n"
		--source+="      float compResult = (((ListViewItem)x).SubItems[col].Tag.GetValue 3) - (((ListViewItem)y).SubItems[col].Tag.GetValue 3);\n"
		--source+="      if (compResult>0) return sort * 1; if (compResult < 0) return sort * -1; return 0;\n"
		--source+="      }\n}\n"
		source+="  }\n"
		source+="}\n"	


		csharpProvider = dotnetobject "Microsoft.CSharp.CSharpCodeProvider"
		compilerParams = dotnetobject "System.CodeDom.Compiler.CompilerParameters"
		compilerParams.ReferencedAssemblies.AddRange #("System.dll", "System.Windows.Forms.dll")
		compilerParams.GenerateInMemory = true
		compilerResults = csharpProvider.CompileAssemblyFromSource compilerParams #(source)
		if compilerResults.Errors.Count == 0 then 
		(
			compilerResults.CompiledAssembly
		)
		else
		(
			--showProperties compilerResults.CompiledAssembly.Errors
			for i = 0 to compilerResults.Errors.Count-1 do
				format "%\n" compilerResults.Errors.Item[i].ErrorText
			false
		)
	)
	


	local theAssembly = CompileComparer()	
	on dnc_datalistview ColumnClick args do
	(
		if keyboard.shiftPressed then
		(
			if keyboard.controlPressed then
				viewportDisplayDataEnabler=#{1}
			else
			if keyboard.altPressed then
				viewportDisplayDataEnabler=#{1..(theChannelNames.count+1)}
			else
				viewportDisplayDataEnabler[args.column+1] = not viewportDisplayDataEnabler[args.column+1]
			max views redraw
		)
		else --sort
		(
			if lastColumnClicked == args.Column then 
				sortDirection =  sortDirection * -1
			else 
				lastColumnClicked = args.Column 
			dnc_datalistview.ListViewItemSorter = dotNetObject "ListViewItemComparer" args.Column sortDirection
			--dnc_datalistview.Sorting = (dotNetClass "SortOrder").Ascending
		)
		updateChannelTitles()
	)
	
	fn collectParticleSources updateSelection:true =
	(
		ParticleSourcesList = for o in objects where findItem #(KrakatoaPrtLoader,PRT_Volume,PRT_Source,PRT_FumeFX, PRT_Hair, PRT_System, PRT_Maker, PRT_Cloner , Thinking, PF_Source, PRT_Ember, PRT_Surface, Stoke, PRT_Field ) (classof o.baseobject) > 0 collect o
		ddl_sources.items = for o in ParticleSourcesList collect o.name
		if updateSelection then
		(
			if selection.count == 1 and (theIndex = findItem ParticleSourcesList selection[1])>0 do
				if ddl_sources.items.count > 0 then 
					ddl_sources.selection = theIndex
				else
					ddl_sources.selection = 1
		)
		else
		(
			if ddl_sources.items.count == 0 do ddl_sources.selection = 1
		)
	)
	
	on btn_getList pressed do 
	(
		collectParticleSources updateSelection:false
	)
	
	fn updateData forceManual:false=
	(
		unregisterRedrawViewsCallback redrawViewsFunction
		Krakatoa_ParticleDataViewer_ViewportDisplayData = #{}
		if ddl_updateMode.selection > 1 or forceManual == true do
		(
			createStream()
			initDataListView()
			initInfoListView()
			if currentStream != undefined then
			(
				populateDataListView()		
				if theTotalCount > 0 do populateInfoListView()
				try(currentStream.close())catch()				
			)
			else	
				collectParticleSources updateSelection:false
		)
		registerRedrawViewsCallback redrawViewsFunction		
	)	
	
	on ddl_updateMode selected itm do
	(
		setIniSetting theIniFile "ParticleDataViewer" "UpdateMode" (itm as string)
		if itm > 1 do updateData()
	)
	
	on spn_fromIndex changed val do
	(
		updateData()
	) 
	on spn_count changed val do
	(
		updateData()
	) 

	on btn_update pressed do updateData forceManual:true
		
	on spn_everyNth changed val do
	(
		updateData()
	)
	
	on chk_selectedOnly changed state do updateData()
	on chk_useFilter changed state do updateData()
	
	on ddl_sources selected itm do
	(
		updateData()
	)	
	
	on btn_setFilter pressed do 
	(
		try(destroyDialog Krakatoa_ParticleDataViewer_FilterDialog )catch()
		createDialog Krakatoa_ParticleDataViewer_FilterDialog 600 270
	)

	on dnc_datalistview ItemSelectionChanged args do
	( 
		if not dnc_datalistview.items.item[args.item.index].selected then 
			Krakatoa_ParticleDataViewer_ViewportDisplayData[args.item.index+1] = false
			--Krakatoa_ParticleDataViewer_ViewportDisplayData = #{}
		else
			--if matchpattern args.Item.SubItems.item[1].Name pattern:"Position*" do
				Krakatoa_ParticleDataViewer_ViewportDisplayData[args.item.index+1] = true
				--append Krakatoa_ParticleDataViewer_ViewportDisplayData args.item.index
	)
	
	on dnc_datalistview mouseUp args do
	(
		max views redraw
		--redrawViewsFunction()
	)
	on dnc_datalistview mouseDown args do
	(
		max views redraw
		--redrawViewsFunction()
	)	
	
	on dnc_datalistview MouseClick args do
	(
		if args.Button == args.Button.Right do
		(
			if keyboard.ShiftPressed then 
			(
				theSel = getListViewSelection dnc_datalistview
				for i in theSel do
				(
					local txt = ""
					for j = 0 to dnc_datalistview.items.item[i-1].SubItems.count-1 do
						txt+= dnc_datalistview.items.item[i-1].SubItems.Item[j].Name + ":" +dnc_datalistview.items.item[i-1].SubItems.Item[j].Text + " "
					format "%\n" txt
				)
			)
			else
			(
				theItem = (dnc_datalistview.HitTest args.x args.y)
				subItem = theItem.SubItem
				if keyboard.controlPressed then 
					format "%: %\n"  subItem.Name subItem.Text
				else 
					format "%\n" subItem.Text
			)
		)
	)	
	
	on dnc_infolistview MouseClick args do
	(
		if args.Button == args.Button.Right do
		(
			if keyboard.ShiftPressed then 
			(
				theSel = getListViewSelection dnc_infolistview
				for i in theSel do
				(
					local txt = ""
					for j = 0 to dnc_infolistview.items.item[i-1].SubItems.count-1 do
						txt+= dnc_infolistview.Columns.Item[j].Text + ":" +dnc_infolistview.items.item[i-1].SubItems.Item[j].Text + " "
					format "%\n" txt
				)
			)
			else
			(
				theItem = (dnc_infolistview.HitTest args.x args.y)
				subItem = theItem.SubItem
				if keyboard.controlPressed then 
					format "%: %\n"  subItem.Name subItem.Text
				else 
					format "%\n" subItem.Text
			)
		)
	)		
	
	fn OutputSelectedLines ToClipboard:true =
	(
		theSel = getListViewSelection dnc_datalistview
		if theSel.count > 0 then
		(
			theSS = "" as stringstream

			for j = 0 to dnc_datalistview.items.item[0].SubItems.count-1 do
				format "% " dnc_datalistview.items.item[0].SubItems.Item[j].Name  to:theSS
			format "\n" to:theSS
			
			for i in theSel do
			(
				for j = 0 to dnc_datalistview.items.item[i-1].SubItems.count-1 do
					format "% " dnc_datalistview.items.item[i-1].SubItems.Item[j].Text to:theSS
				format "\n" to:theSS
			)		
			if ToClipboard == true then 
				setclipboardText (theSS as string)
			else
				format "%\n" (theSS as string)
		)
		else
			messagebox "Nothing Selected!\nPlease select one or more lines and try again!" title:"PDV: No Selection"
	)	
	
	fn underscoreLocalTime txt =
	(
		local newString  = ""
		for i in (filterString txt ".: /-") do newString += ("_" + i)
		newString 
	)	
	
	fn point3ToHexColor theValueString =
	(
		local theColor = execute theValueString 
		if theColor != undefined then
		(
			theColor *= 255
			bit.intAsHex theColor.x + bit.intAsHex theColor.y + bit.intAsHex theColor.z
		)
		else
			undefined
	)
	
	fn exploreHTMLOutputFolder =
	(
		theHTMLpath = Krakatoa_PresetsDirectory+ "\\ParticleDataViewerOutput" 
		makeDir theHTMLpath 
		shellLaunch "explorer.exe" theHTMLpath 
	)

	fn OutputSelectedLinesToHTML =
	(
		local theSel = getListViewSelection dnc_datalistview
		if theSel.count == 0 do 
		(
			local q = querybox "Nothing Selected, Export The Current List Content?" title:"PDV Export List?"
			if q then 
				theSel = #{1..dnc_datalistview.items.count} as array
			else
				return false
		)
		
		if Krakatoa_ParticleDataViewer_Rollout.ddl_sources.selection == 0 do return false
		local theObject = ParticleSourcesList[Krakatoa_ParticleDataViewer_Rollout.ddl_sources.selection]
		if not isValidNode theObject do return false
		
		local bodyColor = "#333333"
		local titleBGColor = "#555555"
		local cellBGColor = "#444444"
		local theCommentBGColor = "#333344"

		local redColor =  "#CC0022"
		local titleColor = "#FFFFFF"
		local textColor = "#FFFFCC"
		local linkColor = "#CCCCFF"
		local grayOutColor = "#777777"		
		
		theHTMLpath = Krakatoa_PresetsDirectory+ "\\ParticleDataViewerOutput" 
		makeDir theHTMLpath 
		theHTMLname = theHTMLpath + "\\PDV_"+ getFileNameFile maxFileName+ "_" + underscoreLocalTime localtime +".htm"
		theHTML = createFile theHTMLname
		
		format "<html>\n" to:theHTML
		format "<head>\n" to:theHTML
		format "<title>Krakatoa Particle Data Viewer [%]</title>\n" Krakatoa_ParticleDataViewer_Rollout.title to:theHTML
		
		format "<meta http-equiv=\"Content-Type\" content=\"text/html; charset=iso-8859-1\">" to:theHTML
		format "</head>\n" to:theHTML
		
		format "<body bgcolor=% text=% link=% vlink=%>\n" bodyColor textColor linkColor linkColor   to:theHTML
		format "<font face=\"Verdana\">\n" to:theHTML
		
		format "<table border=\"0\" width=\"100\%\" cellspacing=\"3\" cellpadding=\"2\">\n" to:theHTML
		format "<tr><td bgcolor=%>\n" titleBGColor to:theHTML
		format "<h3 align=\"center\"><font color=%>% - %</h3>\n" titleColor Krakatoa_ParticleDataViewer_Rollout.title  Krakatoa_ParticleDataViewer_Rollout.ddl_sources.selected to:theHTML
		format "</td></tr>\n" to:theHTML
		
		--format "<tr><td bgcolor=% align=\"center\"><font size=-1>PRT Object: %</font></td></tr>\n" cellBGColor Krakatoa_ParticleDataViewer_Rollout.ddl_sources.selected to:theHTML
		format "<tr><td bgcolor=% align=\"center\"><font size=-1>Snapshot Generated on <b>%</b> by <b>%@%</b></font></td></tr>\n" cellBGColor  localTime sysinfo.userName sysinfo.computername to:theHTML
		local maxFile = (maxFilePath+MaxFileName)
		if maxFile == "" do maxFile = "Untitled"
		format "<tr><td bgcolor=% align=\"center\"><font size=-1>Max File Name: <b>%</b></font></td></tr>\n" cellBGColor maxFile  to:theHTML
		if classof theObject.baseobject == KrakatoaPRTLoader do
		(
			local theFiles = theObject.fileList
			for f = 1 to theFiles.count do
			(
				format "<tr><td bgcolor=% align=\"center\"><font size=-1>PRT Loader File %: <b>%</b></font></td></tr>\n" cellBGColor f theFiles[f] to:theHTML
			)
		)
		format "</table>\n" to:theHTML
		
		format "<table border=\"0\" width=\"100\%\" cellspacing=\"1\" cellpadding=\"1\" align=\"center\">\n" to:theHTML
		
		local isColor = #()
		format "<tr>\n" to:theHTML
		for j = 0 to dnc_datalistview.Columns.Count-1 do
		(
			isColor[j+1] = findItem #("Color","Emission","Absorption") (filterString dnc_datalistview.Columns.Item[j].Text " ")[1] > 0
			if isColor[j+1] == true do format "<td bgcolor=%>&nbsp<br></td>" titleBGColor  to:theHTML
			format "<td bgcolor=%>%</td>" titleBGColor dnc_datalistview.Columns.Item[j].Text  to:theHTML
		)
		format "</tr>\n" to:theHTML
		
		for i = 1 to theSel.count do
		(
			prg_progress.value = 100.0 * i / theSel.count
			windows.processPostedMessages()
			format "<tr>\n" to:theHTML
			for j = 0 to dnc_datalistview.items.item[theSel[i]-1].SubItems.count-1 do
			(
				if isColor[j+1] == true do
				(
					local theCellColor = point3ToHexColor dnc_datalistview.items.item[theSel[i]-1].SubItems.Item[j].Text
					if theCellColor == undefined do theCellColor = cellBGColor
					format "<td bgcolor=%>&nbsp</td>" theCellColor to:theHTML
				)
				format "<td bgcolor=%><font size=-1>%</font></td>" cellBGColor dnc_datalistview.items.item[theSel[i]-1].SubItems.Item[j].Text to:theHTML
			)
			format "</tr>\n" to:theHTML
		)		
		
		format "</table><p><p>\n" to:theHTML
		
		
		format "<table border=\"0\" width=\"100\%\"  cellspacing=\"1\" cellpadding=\"1\" align=\"center\">\n" to:theHTML
		format "<tr>\n" to:theHTML
		for j = 0 to Krakatoa_ParticleDataViewer_Rollout.dnc_infolistview.Columns.count-1 do
		(
			format "<td bgcolor=%>%</td>" titleBGColor Krakatoa_ParticleDataViewer_Rollout.dnc_infolistview.Columns.Item[j].Text  to:theHTML
		)
		format "</tr>\n" to:theHTML		
		
		for i = 1 to dnc_infolistview.items.count do
		(
			format "<tr>\n" to:theHTML
			for j = 0 to dnc_infolistview.items.item[i-1].SubItems.count-1 do
			(
				format "<td bgcolor=%><font size=-1>%</font></td>" cellBGColor dnc_infolistview.items.item[i-1].SubItems.Item[j].Text to:theHTML
			)
			format "</tr>\n" to:theHTML
		)			
		
		format "</table>\n" to:theHTML
		
		prg_progress.value = 0
	
		format "</body>\n" to:theHTML
		format "</html>\n" to:theHTML
		close theHTML 
		shelllaunch "explorer.exe" theHTMLname 		
	)
	
	on dnc_datalistview ColumnWidthChanged arg do 
	(
		local theIndex = arg.ColumnIndex
		local theText = dnc_datalistview.Columns.Item[theIndex].Text
		theText = (filterString theText " ")[1]
		local theWidth = dnc_datalistview.Columns.Item[theIndex].Width
		setIniSetting theIniFile "ParticleDataViewerColumnWidth" theText (theWidth as string)
	)	
	
	on dnc_infolistview ColumnWidthChanged arg do 
	(
		local theIndex = arg.ColumnIndex
		local theText = dnc_infolistview.Columns.Item[theIndex].Text
		local theWidth = dnc_infolistview.Columns.Item[theIndex].Width
		setIniSetting theIniFile "ParticleDataViewerInfoColumnWidth" theText (theWidth as string)
	)	
	
	fn resizeDialog val =
	(
		dnc_datalistview.width = val.x-10
		dnc_datalistview.height = val.y-(if displayInfoList then 300 else 50)
		
		dnc_infolistview.width = val.x-10
		dnc_infolistview.height = if displayInfoList then 240 else 30
		dnc_infolistview.pos.y = dnc_datalistview.height+55
		
		edt_infoString.pos.y = dnc_datalistview.height+33
		edt_infoString.width = val.x-10		
	)	
	

	
	on Krakatoa_ParticleDataViewer_Rollout open do
	(
		makeDir (GetDir #plugcfg + "\\Krakatoa\\")
		local theVal = execute (getIniSetting theIniFile "ParticleDataViewer" "DisplayArity" )
		if theVal == OK do theVal = true
		displayArity = theVal 

		local theVal = execute (getIniSetting theIniFile "ParticleDataViewer" "DisplayInfoList" )
		if theVal == OK do theVal = true
		displayInfoList = theVal 
		if not displayInfoList do resizeDialog (getDialogSize Krakatoa_ParticleDataViewer_Rollout)
		

		local theVal = (getIniSetting theIniFile "ParticleDataViewer" "DataFormat" )
		if theVal == "" then theVal = #mxs else theVal = theVal as name
		DisplayFormat = theVal 
		
		local theVal = execute (getIniSetting theIniFile "ParticleDataViewer" "DisplayVectorsInViewport" )
		if theVal == OK do theVal = true
		DisplayVectorsInViewport = theVal 
		
		collectParticleSources()
		local theVal = execute (getIniSetting theIniFile "ParticleDataViewer" "UpdateMode" )
		if theVal == OK do theVal = 1 
		ddl_updateMode.selection = theVal
		
		local theVal = execute (getIniSetting theIniFile "ParticleDataViewer" "LoadPRTInWorldSpace" )
		if theVal == OK do theVal = true
		loadPRTInWorldSpace = theVal		

		local theVal = execute (getIniSetting theIniFile "ParticleDataViewer" "EvaluatePRTMaterial" )
		if theVal == OK do theVal = true
		evaluatePRTMaterial = theVal		
		
		updateData()
		registerRedrawViewsCallback redrawViewsFunction
	)
	

	
	on Krakatoa_ParticleDataViewer_Rollout close do
	(
		unregisterRedrawViewsCallback redrawViewsFunction
		try(destroyDialog Krakatoa_ParticleDataViewer_FilterDialog )catch()
		max views redraw
	)
	
	on Krakatoa_ParticleDataViewer_Rollout resized val do
	(
		resizeDialog val
	)
	
)--end rollout
createDialog Krakatoa_ParticleDataViewer_Rollout 800 700  style:#(#style_titlebar, #style_border, #style_sysmenu, #style_minimizebox, #style_resizing, #style_maximizebox  ) menu:MainMenu
)--end script
