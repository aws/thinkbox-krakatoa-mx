-- Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
-- SPDX-License-Identifier: Apache-2.0
macroScript KrakatoaMatteObjectsExplorer category:"Krakatoa" icon:#("Krakatoa",25) tooltip:"Matte Objects Explorer" buttontext:"Matte Explorer"
(
	on isEnabled return renderers.current.classid as string == "#(-1204370534, -399920359)" or renderers.current.classid as string == "#(3090596762L, 3895046937L)" 
	on execute do
	(
		global Krakatoa_MatteObjectsExplorer_Dialog
		try(DestroyDialog Krakatoa_MatteObjectsExplorer_Dialog)catch()
		
		global Krakatoa_MatteExplorer_RCMenu
		rcmenu Krakatoa_MatteExplorer_RCMenu
		(
			menuItem mnu_refresh "REFRESH!"
			separator sep_10
			menuItem mnu_selectHighlighted "Select Highlighted Objects"
			
			separator sep_20
			menuItem mnu_enableRenderObject "Enable Render Object Property"
			menuItem mnu_enableCameraVis "Enable Camera Visibility"
			
			separator sep_30
			menuItem mnu_unhideobject "Unhide Object"
			menuItem mnu_unfreezeeobject "Unfreeze Object"
			separator sep_40
			
			submenu "Invert Properties..."
			(
				menuItem mnu_disableRenderObject "Disable Render Object Property"
				menuItem mnu_disableCameraVis "Disable Camera Visibility"
				menuItem mnu_hideobject "Hide Object"
				menuItem mnu_freezeeobject "Freeze Object"
			)
			
			separator sep_50
			menuItem mnu_nofrozenhidden "Don't Hide Frozen Objects" enabled:(maxOps.hideFrozenObjects == true)
			
			
			on mnu_refresh picked do Krakatoa_MatteObjectsExplorer_Dialog.enableRenderProperty #refresh
			on mnu_selectHighlighted picked do Krakatoa_MatteObjectsExplorer_Dialog.enableRenderProperty #select
				
			on mnu_enableRenderObject picked do Krakatoa_MatteObjectsExplorer_Dialog.enableRenderProperty #renderable
			on mnu_enableCameraVis picked do Krakatoa_MatteObjectsExplorer_Dialog.enableRenderProperty #cameravis
			on mnu_unhideobject picked do Krakatoa_MatteObjectsExplorer_Dialog.enableRenderProperty #unhideobject
			on mnu_unfreezeeobject picked do Krakatoa_MatteObjectsExplorer_Dialog.enableRenderProperty #unfreezeobject
			on mnu_nofrozenhidden picked do Krakatoa_MatteObjectsExplorer_Dialog.enableRenderProperty #nofrozenhidden
				
			on mnu_disableRenderObject picked do Krakatoa_MatteObjectsExplorer_Dialog.enableRenderProperty #norenderable
			on mnu_disableCameraVis picked do Krakatoa_MatteObjectsExplorer_Dialog.enableRenderProperty #nocameravis
			on mnu_hideobject picked do Krakatoa_MatteObjectsExplorer_Dialog.enableRenderProperty #hideobject
			on mnu_freezeeobject picked do Krakatoa_MatteObjectsExplorer_Dialog.enableRenderProperty #freezeobject
			
			
		)
		
		rollout Krakatoa_MatteObjectsExplorer_Dialog "Krakatoa Matte Objects Explorer"
		(
			local selectedItems = #()
			local initializingView = false
			local getSelectedItems
			
			local useNamedSelectionSets
			local matteObjects = #()
			local matteSelSets = #()
			
			dotNetControl dnc_listview "ListView" width:990 height:390 align:#center	
			
			fn updateMatteObjectsData =
			(
				useNamedSelectionSets = execute (FranticParticles.GetProperty "Matte:NamedSelectionSets")
				matteSelSets = for i = 1 to selectionSets.count where findItem useNamedSelectionSets (getNamedSelSetName i) != 0 collect selectionSets[i]
				matteObjects = #()
				for i in matteSelSets do 
					join matteObjects (for o in i collect #(o, i.name, #{}, undefined))				
				for i = 1 to matteObjects.count do
				(
					local theLayer = matteObjects[i][1].layer 
					matteObjects[i][3][1] = matteObjects[i][1].renderable  
					matteObjects[i][3][2] = matteObjects[i][1].primaryVisibility  
					matteObjects[i][3][3] = not matteObjects[i][1].isHidden  
					matteObjects[i][3][4] = not (matteObjects[i][1].isFrozen and maxOps.hideFrozenObjects)
					matteObjects[i][3][5] = theLayer.on
					matteObjects[i][3][6] = theLayer.renderable 
					matteObjects[i][3][7] = not theLayer.isHidden 
					matteObjects[i][3][8] = theLayer.primaryVisibility 
					matteObjects[i][4] = theLayer
				)
			)
			
			fn getColumnSize ColumnName =
			(
				theResult
			)		
			
			fn initListViewLayout =
			(
				local lv = dnc_listview
				layout_def = #(#("Matte Object Name",180), #("NSS",80), #("Faces",50), #("Render Obj.",75), #("Cam.Vis.",60),#("Unhidden",60),#("Frozen Unhidden",100),#("Layer Name",80),#("Layer On",60), #("Render Layer",80),#("Layer Unhidden",90),#("Layer Cam.Vis.",90))
				lv.Clear()
				lv.backColor = (dotNetClass "System.Drawing.Color").fromARGB 221 221 225
				lv.View = (dotNetClass "System.Windows.Forms.View").Details
				lv.gridLines = true 
				lv.fullRowSelect = true 
				lv.checkboxes = false
				lv.hideSelection = false		
				for i in layout_def do
				(
					local theVal = i[2]
					local theVal2 = execute (getIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini" ) "KrakatoaMatteObjectEditorColumnWidth" i[1] )
					if theVal2 != OK and not keyboard.shiftpressed do theVal = theVal2
					theCol = lv.Columns.add i[1] theVal
				)
			)
			
			fn initListView =
			(
				initializingView = true
				local lv = dnc_listview
				lv.Items.Clear()
				local theRange = #()
				local theRedColor = (dotNetClass "System.Drawing.Color").fromARGB 200 0 0
				local theGreenColor = (dotNetClass "System.Drawing.Color").fromARGB 0 128 0 

				local theBoldFont = dotNetObject "System.Drawing.Font" "Arial" 8 (dotNetClass "System.Drawing.FontStyle").Bold
				local theNormalFont = dotNetObject "System.Drawing.Font" "Arial" 8 
				local theItalicFont = dotNetObject "System.Drawing.Font" "Arial" 8 (dotNetClass "System.Drawing.FontStyle").Italic
				local goodMattesCount = 0
				local badMattesCount = 0
				
				for o in matteObjects do
				(
					local li = dotNetObject "System.Windows.Forms.ListViewItem" (o[1].name)
					li.name = "objectname"
					if o[3].numberset == o[3].count then
					(
						li.font = theNormalFont
						li.forecolor = theGreenColor
						goodMattesCount += 1
					)
					else
					(
						li.font = theBoldFont
						li.forecolor = theRedColor
						badMattesCount += 1
					)
					
					subLi = li.SubItems.add o[2]
					subLi.name = "nss"
					subLi = li.SubItems.add ((getPolygonCount o[1])[1] as string)
					subLi.name = "faces"
					subLi = li.SubItems.add (if o[3][1] then "yes" else "NO")
					subLi.name = "renderable"
					subLi = li.SubItems.add (if o[3][2] then "yes" else "NO")
					subLi.name = "camvis"
					subLi = li.SubItems.add (if o[3][3] then "yes" else "NO")
					subLi.name = "nothidden"
					subLi = li.SubItems.add (if o[3][4] then "yes" else "NO")
					subLi.name = "nothidefrozen"
					
					subLi = li.SubItems.add (o[4].name)
					subLi.name = "layername"
					
					subLi = li.SubItems.add (if o[3][5] then "yes" else "NO")
					subLi.name = "layeron"
					subLi = li.SubItems.add (if o[3][6] then "yes" else "NO")
					subLi.name = "layerrenderable"
					subLi = li.SubItems.add (if o[3][7] then "yes" else "NO")
					subLi.name = "layernothidden"
					subLi = li.SubItems.add (if o[3][8] then "yes" else "NO")
					subLi.name = "layervistocamera"
						
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
				txt = "Krakatoa Matte Objects Explorer - " 
				if matteObjects.count == 0 then 
					txt += "No Matte Objects Found"
				else if badMattesCount > 0 then 
					txt += badMattesCount as string +" Matte "+(if badMattesCount > 1 then "Objects" else "Object")+" Won't Render, " + goodMattesCount as string +" Will Render."
				else 
					txt += "No Problems Found."
				Krakatoa_MatteObjectsExplorer_Dialog.title = txt
				
			) 
			
			fn getSelectedItems =
			(
				if not initializingView do
				selectedItems = for i = 1 to dnc_listview.items.count where dnc_listview.items.item[i-1].selected == true collect i
			)
			
			fn setSelectedItems theSel =
			(
				for i in theSel do
					dnc_listview.items.item[i-1].selected = true
			)
			
			fn selectAll =
			(
				selectedItems = for i = 1 to dnc_listview.items.count collect i
				for i in selectedItems do
					dnc_listview.items.item[i-1].selected = true
			)
			
			fn selectInvert=
			(
				selectedItems = for i = 1 to dnc_listview.items.count collect i
				for i in selectedItems do
					dnc_listview.items.item[i-1].selected = not dnc_listview.items.item[i-1].selected
			)		

			fn enableRenderProperty prop =
			(
				if prop == #nofrozenhidden do maxOps.hideFrozenObjects = false
				if prop == #select do max select none
				local theSel = getSelectedItems()
				for i in theSel do 
				(
					case prop of
					(
						#renderable: try(matteObjects[i][1].renderable = true)catch()
						#cameravis: try(matteObjects[i][1].primaryVisibility = true)catch()
						#unhideobject: try(matteObjects[i][1].isHidden = false)catch()
						#unfreezeobject: try(matteObjects[i][1].isFrozen = false)catch()
						
						#norenderable: try(matteObjects[i][1].renderable = false)catch()
						#nocameravis: try(matteObjects[i][1].primaryVisibility = false)catch()
						#hideobject: try(matteObjects[i][1].isHidden = true)catch()
						#freezeobject: try(matteObjects[i][1].isFrozen = true)catch()
						
						#select: try(selectmore matteObjects[i][1])catch()
					)
				)
				updateMatteObjectsData()
				initListViewLayout()
				initListView()
				setSelectedItems theSel
				::Krakatoa_GUI_MatteObjects.updateMatteStatusLight()
			)
			
			on dnc_listview MouseClick itm do 
			(
				if itm.Button.Equals itm.Button.Right then 
					popupmenu ::Krakatoa_MatteExplorer_RCMenu pos:mouse.screenpos
			)
			
			on dnc_listview DoubleClick itm do 
			(
				local sel = getSelectedItems()
				select (for i in sel where isValidNode matteObjects[i][1] collect matteObjects[i][1])
			)			
			
			on Krakatoa_MatteObjectsExplorer_Dialog open do
			(
				updateMatteObjectsData()
				initListViewLayout()
				initListView()
			)
				
			on dnc_listview ColumnWidthChanged arg do 
			(
				local theIndex = arg.ColumnIndex
				local theText = dnc_listview.Columns.Item[theIndex].Text
				--theText = (filterString theText " ")[1]
				local theWidth = dnc_listview.Columns.Item[theIndex].Width
				setIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini" ) "KrakatoaMatteObjectEditorColumnWidth" theText (theWidth as string)
			)			
		
			on Krakatoa_MatteObjectsExplorer_Dialog moved pos do
			(
				setIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini" ) "KrakatoaMatteObjectsExplorer" "Position" (pos as string)
			)

			on Krakatoa_MatteObjectsExplorer_Dialog resized val do
			(
				dnc_listview.width = val.x-10
				dnc_listview.height = val.y-10
			)		

		)--end rollout

		local thePos = execute (getIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini" ) "KrakatoaMatteObjectsExplorer" "Position")
		if thePos == OK do thePos = [200,200]
		if thePos.x > sysinfo.desktopsize.x - 800 do thePos.x = sysinfo.desktopsize.x - 800 
		if thePos.y > sysinfo.desktopsize.y - 500 do thePos.y = sysinfo.desktopsize.y - 500 
			
		createDialog Krakatoa_MatteObjectsExplorer_Dialog 1000 400 thePos.x thePos.y style:#(#style_titlebar, #style_border, #style_sysmenu, #style_minimizebox, #style_resizing, #style_maximizebox  ) --menu:Krakatoa_ShadowsExplorer_Menu
	)
)--end scrtipt