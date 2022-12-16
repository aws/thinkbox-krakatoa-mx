-- Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
-- SPDX-License-Identifier: Apache-2.0
(
	local CurrentVersion = "20160810"
	local isMenuRequested = not matchPattern (getIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini" ) "MenuSystem" "CreateMenu") pattern:"false"
	local theMainMenu = menuMan.getMainMenuBar()
	local theKrakatoaMenu = menuMan.findMenu "Krakatoa"
	local oldVersion = (getIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini" ) "MenuSystem" "LastVersion")
	if oldVersion == "" do oldVersion = "20100506"
	local needUpdate = oldVersion != CurrentVersion
	if theKrakatoaMenu != undefined and (not isMenuRequested or needUpdate) do
	(
		if needUpdate then
			try(FranticParticles.LogProgress (" >Old Krakatoa Menu Version "+oldVersion+" Found and Removed."))catch()
		else	
			try(FranticParticles.LogProgress (" >Krakatoa Menu Found and Removed at User Request via the Krakatoa Preferences"))catch()
		menuMan.unRegisterMenu theKrakatoaMenu
		menuMan.updateMenuBar() 
		theKrakatoaMenu = undefined
	)
	if theKrakatoaMenu == undefined and isMenuRequested do
	(
		if needUpdate then
			try(FranticParticles.LogProgress (" >Creating Updated Krakatoa Menu Version "+CurrentVersion+"... This can be disabled via the Krakatoa Preferences."))catch()
		else
			try(FranticParticles.LogProgress (" >Krakatoa Menu Not Found - Creating... This can be disabled via the Krakatoa Preferences."))catch()
		
		theKrakatoaMenu = menuMan.createMenu "Krakatoa"

		theMenuDefinitionArray = #(
			#(#menuitem,"KrakatoaGUIFocus","Krakatoa","Bring Krakatoa To FRONT!"),
			#(#menuitem,"KrakatoaGUI","Krakatoa","SET Krakatoa As Current Renderer / Open Krakatoa GUI"),
			#(#menuitem,"RemoveKrakatoa","Krakatoa","SWITCH BACK To Previous Renderer"),
			#(#separator),
			#(#submenustart,"Krakatoa LOG And PREFERENCES..."),
			#(#menuitem,"KrakatoaPreferences","Krakatoa","Open the Krakatoa PREFERENCES dialog..."),
			#(#menuitem,"KrakatoaLog","Krakatoa","Open the Krakatoa LOG window..."),
			#(#menuitem,"KrakatoaAutoLog","Krakatoa","AUTO-OPEN the Krakatoa Log Window on Warnings"),
			#(#menuitem,"ToggleMeditLock","Krakatoa","LOCK the Production and Material Editor Renderers"),
			#(#submenuend),
			#(#separator),
			#(#menuitem,"PRTLoader","Krakatoa","Create a PRT LOADER - hold SHIFT to create at World Origin"),
			#(#menuitem,"PRTVolume","Krakatoa","Create PRT VOLUME object(s) from selected Object(s) - hold SHIFT to create manually"),
			#(#menuitem,"PRTSurface","Krakatoa","Create PRT SURFACE object from selected Object(s) - hold SHIFT to create one per object."),
			#(#menuitem,"PRTFumeFX","Krakatoa","Create PRT FUMEFX object(s) from selected FumeFX Simulations - hold SHIFT to create manually"),
			#(#menuitem,"PRTHair","Krakatoa","Create PRT HAIR object(s) - hold SHIFT to create manually"),
			#(#menuitem,"PRTSource","Krakatoa","Create PRT SOURCE object(s) - hold SHIFT to create manually"),
			#(#separator),
			#(#menuitem,"PRTMakerDesigner","Krakatoa","Open the PRT MAKER DESIGNER utility"),
			#(#separator),
			--#(#submenustart,"Krakatoa World Space Modifiers (WSM)..."),
			#(#menuitem,"SpaceMagmaModifier","Krakatoa","Add Krakatoa MAGMA WSM to selected object(s) - hold SHIFT to instanciate"),
			#(#menuitem,"SpaceDeleteModifier","Krakatoa","Add Krakatoa DELETE WSM to selected object(s)- hold SHIFT to instanciate"),
			#(#menuitem,"SpacePRTClonerModifier","Krakatoa","Add Krakatoa PRT CLONER WSM to selected object(s) - hold SHIFT to instanciate"),
			#(#menuitem,"KrakatoaSkinWrap","Krakatoa","Add Krakatoa SKIN WRAP WSM to selected object(s) - hold SHIFT to instanciate"),
			--#(#submenuend),			
			#(#separator),
			#(#menuitem,"ChannelModifier","Krakatoa","Add Krakatoa MAGMA Modifier to selected object(s) - hold SHIFT to instanciate"),
			#(#menuitem,"DeleteModifier","Krakatoa","Add Krakatoa DELETE Modifier to selected object(s)- hold SHIFT to instanciate"),
			#(#menuitem,"PRTClonerModifier","Krakatoa","Add Krakatoa PRT CLONER Modifier to selected object(s) - hold SHIFT to instanciate"),
			#(#menuitem,"CameraModifier","Krakatoa","Add Krakatoa CAMERA Modifier to selected Cameras - hold SHIFT to instanciate"),
			#(#separator),
			#(#submenustart,"MODIFIER STACK Loading And Saving..."),
			#(#menuitem,"SaveModStack","Krakatoa","SAVE Modifier Stack To Disk..."),
			#(#menuitem,"LoadModStack","Krakatoa","LOAD Modifier Stack From Disk..."),
			#(#submenuend),
			#(#separator),
			#(#menuitem,"KrakatoaParticleDataViewer","Krakatoa","Launch the PARTICLE DATA VIEWER utility..."),
			#(#submenustart,"Other Krakatoa EXPLORERS..."),
			#(#menuitem,"KrakatoaExplorers","Krakatoa","Open the Krakatoa EXPLORERS floater..."),
			#(#menuitem,"KrakatoaMatteObjectsExplorer","Krakatoa","Launch Krakatoa MATTE OBJECTS Explorer utility. Hold SHIFT to reset columns width."),
			#(#menuitem,"KrakatoaShadows","Krakatoa","Launch Krakatoa SHADOWS Explorer utility"),
			#(#menuitem,"SchematicFlow","Krakatoa","Launch the Krakatoa SCHEMATIC FLOW utility..."),
			#(#menuitem,"KrakatoaPRTscan","Krakatoa","Launch the PRT SCANNER utility..."),
			#(#submenuend),
			#(#separator),
			#(#menuitem,"KrakatoaBirthChannelGenerator","Krakatoa","Launch the Krakatoa BIRTH CHANNEL GENERATOR utility..."),
			#(#separator),
			#(#menuitem,"AboutKrakatoa","Krakatoa","ABOUT Krakatoa...")
		)
		local theSubMenu = undefined
		for aDef in theMenuDefinitionArray do
		(
			case aDef[1] of
			(
				#menuitem:
				(
					try(
						theAction = menuMan.createActionItem aDef[2] aDef[3]
						theAction.setTitle aDef[4]
						theAction.setUseCustomTitle true
						if theSubMenu == undefined then
							theKrakatoaMenu.addItem theAction -1
						else
							theSubMenu.addItem theAction -1
					)catch()
				)
				#separator: 
				(
					try(
						theAction = menuMan.createSeparatorItem()
						if theSubMenu == undefined then
							theKrakatoaMenu.addItem theAction -1
						else
							theSubMenu.addItem theAction -1
					)catch()
				)
				#submenustart:
				(
					try(
						theSubMenu = menuMan.createMenu aDef[2]
					)catch()
				)
				#submenuend: 
				(
					try(
						theAction = menuMan.createSubMenuItem (theSubMenu.getTitle()) theSubMenu
						theKrakatoaMenu.addItem theAction -1	
					)catch()
					theSubMenu = undefined
				)
			)--end case
		)--end aDef loop
		theSubMenu = menuMan.createSubMenuItem "Krakatoa" theKrakatoaMenu
		theMainMenu.addItem theSubMenu -1
		menuMan.updateMenuBar() 
		setIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini" ) "MenuSystem" "LastVersion" CurrentVersion
	)--end if
)--end script