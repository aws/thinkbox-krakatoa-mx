-- Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
-- SPDX-License-Identifier: Apache-2.0
(
global KrakatoaPRTLoader, KrakatoaGlobalDataHolder --pre-declare class names
global Krakatoa_PresetsDirectory --pre-declare global path variable
global FranticParticleRenderMXS, FranticParticleRenderMXSStruct --pre-declare struct names
global Krakatoa_PRTIgnoreMissingFrames = false
	
try(FranticParticles.LogProgress (">KrakatoaStartup.ms Script Evaluation Start..."))catch()
--Get Krakatoa Home:
local theKRoot = try(FranticParticles.KrakatoaHome)catch(undefined)
if theKRoot != undefined then
(
	try(FranticParticles.LogProgress (" >KrakatoaHome is ["+ theKRoot +"]"))catch()
	try(FranticParticles.LogProgress (" >Krakatoa Shared Settings Folder is ["+(dotnetclass "System.Environment").GetFolderPath (dotnetclass "System.Environment+SpecialFolder").LocalApplicationData + "\\Thinkbox\\Krakatoa\\]"))catch()
	try(FranticParticles.LogProgress (" >3ds Max Version-Specific Settings Folder is ["+(GetDir #plugcfg + "\\Krakatoa") +"]"))catch()

	if not (IsNetServer()) do --if running in workstation mode,
	(
		--Update Icons If Necessary.
		local iconFiles = #("Krakatoa_24i.bmp", "Krakatoa_24a.bmp", "Krakatoa_16i.bmp", "Krakatoa_16a.bmp", "KrakatoaTools_24i.bmp", "KrakatoaTools_24a.bmp", "KrakatoaTools_16i.bmp", "KrakatoaTools_16a.bmp", "Krakatoa_ChannelEditor_16i.bmp", "Krakatoa_ChannelEditor_16a.bmp", "KrakatoaGUI.bmp")
		local updatedIcons = 0 --count the updates
		for i in iconFiles do --go through all icon files
		(
			if (maxVersion())[1] >= 9000 then
			(
				local theTarget = (GetDir #usericons + "\\" + i) --this is the target name in the user Icons folder (this is necessary for Vista!)
				local theSource = (theKRoot + "Icons\\" + i) --this is the source file in Krakatoa's Icons folder
			)
			else
			(
				local theTarget = (GetDir #ui + "\\Icons\\" + i) --this is the target name in Max's Icons folder
				local theSource = (theKRoot + "Icons\\" + i) --this is the source file in Krakatoa's Icons folder
			)	
			--if the target file exists and is different or does not exist at all, 
			if (doesFileExist theSource and doesFileExist theTarget and getFileModDate theTarget != getFileModDate theSource) or (not doesFileExist theTarget) then
			(
				try(FranticParticles.LogProgress ("  >Updating Icon File [" + i + "]"))catch() --print a message to the Log
				deleteFile theTarget  --delete the old file (MAXScript does not support direct overwriting)
				local result = copyFile theSource theTarget  --copy the new file to the Max Icons folder
				if result do updatedIcons += 1 --increment the counter.
			)	
		)	
		if updatedIcons > 0 then --if any icons were copied over,
		(
			if (maxVersion())[1] >= 9000 then --and this is Max 9 or higher,
			(
				colorMan.reiniticons() --reinitialize the icons
				try(FranticParticles.LogProgress (" +3ds Max Icon Files Have Been Reinitialized."))catch()
			)	
			else	--if Max 8, show a message to let the user know he will have to restart one more time:
				messagebox ("Krakatoa Updated " + updatedIcons as string + " Icon Files.\n3ds Max 8 does not support reloading of icons on-the-fly.\nUpdated Icons will appear AFTER A NEW START of 3ds Max.") title:"Krakatoa Icons Updated"
		)
		else 
			try(FranticParticles.LogProgress ("+All Krakatoa Icon Files Are Up To Date!"))catch()
		
		
		local theBLOPFolder = theKRoot + "\\BlackOps\\"
		local theTargetFolder = (dotnetclass "System.Environment").GetFolderPath (dotnetclass "System.Environment+SpecialFolder").LocalApplicationData + "\\Thinkbox\\Krakatoa\\BlackOps\\"
		local theDirs = getDirectories (theBLOPFolder +"*")
		for d in theDirs do
		(
			local theFS = filterString d "\\/"
			local theFolder = theFS[theFS.count]
			makeDir (theTargetFolder+theFolder) all:true
			for f in getFiles (d+"*.MagmaBLOP") do 
			(
				local result = copyFile f (theTargetFolder+theFolder+"\\"+filenameFromPath f)
				if result then 
					try(FranticParticles.LogProgress ("+Copied BlackOp ["+filenamefrompath f+"] To ["+theTargetFolder+theFolder+"]"))catch()
				--else try(FranticParticles.LogProgress ("--BlackOp Already Exists: ["+theTargetFilename+"]"))catch()
			)--end f loop
		)--end d loop
		
	)--end if workstation mode

	--Set Current Directory to the Scripts folder in Krakatoa Home:
	sysinfo.currentDir = theKRoot + "Scripts"
	try(FranticParticles.LogProgress (" >Loading PRT Loader File Manager Script..."))catch()
	fileIn (theKRoot + "Scripts\\Krakatoa_PRTLoader_FileMan.ms")
	try(FranticParticles.LogProgress (" >Loading PRT Loader Preset Manager Script..."))catch()
	fileIn (theKRoot + "Scripts\\Krakatoa_PRTLoader_PresetMan.ms")
	try(FranticParticles.LogProgress (" >Loading PRT Loader Scripted Plugin..."))catch()
	fileIn (theKRoot + "Scripts\\KrakatoaPRTLoader.ms")
	try(FranticParticles.LogProgress (" >Loading PRT Loader Manipulator Script..."))catch()
	fileIn (theKRoot + "Scripts\\Krakatoa_PRTloader_Manipulator.ms")
	try(FranticParticles.LogProgress (" >Loading Krakatoa Shadows Utility Script..."))catch()
	fileIn (theKRoot + "Scripts\\Krakatoa_Shadows_Utility.ms")
	try(FranticParticles.LogProgress (" >Loading Shadow Manipulators Script..."))catch()
	fileIn (theKRoot + "Scripts\\Krakatoa_Manipulators.ms")
	try(FranticParticles.LogProgress (" >Loading PRT Scanner Utility Script..."))catch()
	fileIn (theKRoot + "Scripts\\Krakatoa_PRTScanner_Utility.ms")
	try(FranticParticles.LogProgress (" >Loading Krakatoa Matte Objects Explorer Script..."))catch()
	fileIn (theKRoot + "Scripts\\Krakatoa_MatteObjectsExplorer.ms")
	try(FranticParticles.LogProgress (" >Loading Krakatoa GUI Script..."))catch()
	fileIn (theKRoot + "Scripts\\KrakatoaGUI.ms")
	try(FranticParticles.LogProgress (" >Loading Particle Explorers Utility Script..."))catch()
	fileIn (theKRoot + "Scripts\\Krakatoa_ParticleExplorers.ms")
	try(FranticParticles.LogProgress (" >Loading Krakatoa Toolbar MacroScripts..."))catch()
	fileIn (theKRoot + "Scripts\\KrakatoaToolbar.ms")
	try(FranticParticles.LogProgress (" >Loading Krakatoa PRT Maker Designer MacroScript..."))catch()
	try(fileIn (theKRoot + "Scripts\\Krakatoa_PRTMaker_Dialog.ms"))catch()
	try(FranticParticles.LogProgress (" >Loading Krakatoa Birth Channel Generator MacroScript..."))catch()
	try(fileIn (theKRoot + "Scripts\\Krakatoa_BirthChannelGeneratorUtility.ms"))catch()

	-- if classof KrakatoaSchematicControl == Value then
	-- (
	-- 	try(FranticParticles.LogProgress (" >Loading Krakatoa Schematic Flow Script..."))catch()
	-- 	try(fileIn (theKRoot + "Scripts\\Krakatoa_SchematicFlow.ms"))catch()
	-- 	try(FranticParticles.LogProgress (" >Loading Krakatoa Channel Node Editor GUI Script..."))catch()
	-- 	fileIn (theKRoot + "Scripts\\Krakatoa_Channel_Node_Editor.ms")
	-- 	try(FranticParticles.LogProgress (" >Loading Krakatoa Modifiers Script..."))catch()
	-- 	fileIn (theKRoot + "Scripts\\Krakatoa_PRTChannel_Modifier.ms")
	-- 	try(FranticParticles.LogProgress (" >Loading Krakatoa Magma Manager Script..."))catch()
	-- 	fileIn (theKRoot + "Scripts\\Krakatoa_MagmaFlowManager.ms")
	-- )
	-- else
	-- (
	-- 	try(FranticParticles.LogProgress (" --Helium SchamticControl plugin NOT FOUND. Cannot load MagmaFlow Editor!"))catch()
	-- 	messagebox "FATAL ERROR:The Helium Schematic Control required by the Krakatoa MagmaFlow Editor\nwas not propertly installed on this system.\n\nPlease reinstall Krakatoa or edit the plugin.ini file to include the Thinkbox version of the Helium plugin." title:"Krakatoa Startup Failed"
	-- )
	try(FranticParticles.LogProgress (" >Loading Krakatoa File Update Channels GUI Script..."))catch()
	fileIn (theKRoot + "Scripts\\Krakatoa_PFlowOperators_ChannelSelectorDialog.ms")

	if (maxVersion())[1] >= 10900 and (getIniSetting (GetDir #plugcfg + "\\Krakatoa\\KrakatoaPreferences.ini") "Preferences" "LoadVFBExtensionsOnStartup") != "false" do
	(
		try(FranticParticles.LogProgress (" >Loading Extended VFB Functions..."))catch()
		fileIn (theKRoot + "Scripts\\Krakatoa_VFB_Methods.ms")	
	)	

	--try(FranticParticles.LogProgress (" >Loading Krakatoa Menu Creator..."))catch()
	--fileIn (theKRoot + "Scripts\\KrakatoaMenuCreator.ms")	
	deleteFile ((getDir #userStartupScripts)+"\\Krakatoa_RemoveKrakatoaMenu.ms")
	copyFile (theKRoot + "Scripts\\Krakatoa_RemoveKrakatoaMenu.ms")	((getDir #userStartupScripts)+"\\Krakatoa_RemoveKrakatoaMenu.ms")
	
	callbacks.addScript #postSystemStartup "fileIn (FranticParticles.KrakatoaHome+\"/Scripts/KrakatoaMenuCreator.ms\")" id:#krakatoastartup
	
	if classof Thinking == GeometryClass do --if TP installed, try to load the TP PDV Helper
	(
		try(FranticParticles.LogProgress (" >Loading Krakatoa TP PDV Helper..."))catch()
		try(fileIn (theKRoot + "Scripts\\Krakatoa_TP_PDV.ms")	)catch()
	)
	

	try(FranticParticles.LogProgress ("+Startup Script Finished."))catch()
	--Make sure we have enough memory.
	if heapSize < 33554432 do 
	(
		local oldHeap = heapSize 
		heapSize = 33554432
		try(FranticParticles.LogProgress ("+MAXScript Heap Size Increased from "+ oldHeap as string + " to 33554432 bytes."))catch()
	)	
)
else
	format "--MaxKrakatoa.DLR failed to load, could not figure out KrakatoaHome. Not loading the rest...\n"

)

------------------------------------------------------------------------------------------------------------------------

