-- Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
-- SPDX-License-Identifier: Apache-2.0
(
	global Krakatoa_Benchmark_Dialog
	try(destroyDialog Krakatoa_Benchmark_Dialog)catch()
	
	local theVersionString = "0.0.3"
	local theResults = #()
	
	fn EnforceSettings = 
	(
		FranticParticles.setProperty "IterativeRender" "false"	
		FranticParticles.setProperty "IterativeRender:ScaleFactor" "1"	
	
		FranticParticles.setProperty "IgnoreSceneLights" "false"
		FranticParticles.setProperty "UseFilterColor" "false"
		FranticParticles.setProperty "UseEmissionColor" "false"
		FranticParticles.setProperty "AdditiveMode" "false"
	
		FranticParticles.setProperty "AbsorptionOverride:Enabled" "false"
		FranticParticles.setProperty "EmissionOverride:Enabled" "false"
		
		FranticParticles.setProperty "PostDivideByAlpha" "false"
		
		FranticParticles.setProperty "Density:LinkLightingAndRenderingDensity" "false"
		FranticParticles.setProperty "Density:DensityPerParticle" "5"
		FranticParticles.setProperty "Density:DensityExponent" "-2" 
		
		FranticParticles.setProperty "Lighting:Density:DensityPerParticle" "5"
		FranticParticles.setProperty "Lighting:Density:DensityExponent" "-3"

		FranticParticles.setProperty "RenderingMethod" "Particle Rendering"
		
		FranticParticles.setProperty "VoxelSize" "2.0"
		FranticParticles.setProperty "VoxelFilterRadius" "1"
		FranticParticles.setProperty "PhaseFunction" "Isotropic"
		FranticParticles.setProperty "PhaseEccentricity" "0"
		
		FranticParticles.setProperty "DrawPointFilter" "Bilinear" 
		FranticParticles.setProperty "AttenuationLookupFilter" "Bicubic" 
		FranticParticles.setProperty "SortingThreads" "0" 
	
		FranticParticles.setProperty "EnableMotionBlur" "false"
		FranticParticles.setProperty "EnableDepthOfField" "false"
		FranticParticles.setProperty "EnableAttenuationMapSaving" "false"
		
		FranticParticles.setProperty "RenderParticleFlowGeometry" "false"
		FranticParticles.setProperty "RenderParticleFlowBBox" "false"
		FranticParticles.setProperty "RenderParticleFlowPhantom" "false"
		FranticParticles.setProperty "RenderFumeFX" "false"
		
		FranticParticles.setProperty "RenderMaxParticles" "false"
		FranticParticles.setProperty "RenderThinkingParticles" "false"
		FranticParticles.setProperty "RenderGeometryVertices" "false"
		FranticParticles.setProperty "RenderKrakatoaLoaders" "false"
		FranticParticles.setProperty "RenderGeometryVolumes" "false"
		
		FranticParticles.setProperty "GlobalParticlePercentage" "100.0"

		FranticParticles.setProperty "GlobalDataHolder" ""
	
		FranticParticles.setProperty "EnableParticleCache" "false" 
		FranticParticles.setProperty "EnableLightingCache" "false"
		FranticParticles.setProperty "CacheLastFrame" "true"
		
		FranticParticles.setProperty "ParticleMode" "Render Scene Particles"
		FranticParticles.setProperty "ParticleFiles" ""	
		
		
	)
	
	fn createBaseScene =
	(
		resetMaxFile #noprompt
		theCamera = freecamera transform:(matrix3 [0.923879,0.382683,0] [-0.199951,0.482725,0.85264] [0.326291,-0.787737,0.522498] [120.943,-291.981,193.668])
		theLight = freeSpot transform:(matrix3 [0.608761,-0.793353,0] [0.502821,0.385828,0.773503] [-0.613661,-0.470879,0.633792] [-176.345,-133.52,183.799])
		viewport.setCamera theCamera
	)
	
	fn createPFlow numParticles:10000000=
	(
		pf=PF_Source Quantity_Viewport:1 isSelected:true
		pf.Emitter_Type = 1
		pf.Emitter_Width = pf.Emitter_Height = pf.Emitter_Length = 100
		pf.Integration_for_Render = 0
		pf.Particle_Amount_Limit = 10000000
		ParticleFlow.BeginEdit()
		a1 = RenderParticles() 
		pf.AppendAction a1 
		ParticleFlow.EndEdit() 

		x=y=1 
		pf.GetPViewLocation &x &y 

		ParticleFlow.BeginEdit() 
		ev1_a1 = Birth Emit_Start:0 Emit_Stop:0 Amount:numParticles
		ev1_a2 = Position_Icon()
		ev1_a3 = DisplayParticles Type:6 Color:(color 255 255 255)

		ev1 = Event()
		ev1.AppendAction ev1_a1
		ev1.AppendAction ev1_a2
		ev1.AppendAction ev1_a3
		ParticleFlow.EndEdit() 

		pf.appendInitialActionList ev1
		ev1.SetPViewLocation x (y+100)
		
		--if (maxVersion())[1] < 12000 do
		(
			holdMaxFile()
			fetchMaxFile quiet:true
		)		
	)
	
	fn setUpKrakatoa =
	(
		renderers.current = Krakatoa()
		EnforceSettings()

		rendTimeType = 1
		renderWidth = 640
		renderHeight = 480		
	)
	
	fn getMemReport =
	(
		local theCount = try((FranticParticles.GetCachedParticleCount()) )catch(0)
		local theMemory = try((FranticParticles.getCacheSize()) )catch(0)
		"In Memory: " + FranticParticleRenderMXS.addCommas (theCount as string) + " Particles Using " + theMemory as string+ " MB."
	)
	
	fn createMatteObjects =
	(
		local theTM = Cameras[1].transform
		local s0 = geosphere radius:10 segs:20
		for x = -3 to 3 do
			for y = -2 to 2 do
			(
				s = instance s0
				s.pos = ([x,y,-10] *20) * theTM
			)
		delete s0
	)
	
	
	fn runBenchmark1 =
	(
		local theBox = box width:107.5 height:107.5 length:107.5 pos:[0,0,-50] wirecolor:yellow
		select theBox
		macros.run "Krakatoa" "PRTVolume"
		$PRTVolume_*.VoxelLength = 0.5
		setUpKrakatoa()
		FranticParticles.setProperty "RenderGeometryVolumes" "true"		
		
		st = timestamp()
		max quick render
		local theTime1 = (timestamp()-st)
		append theResults #("Particle Rendering, Box PRT Volume Spacing 0.5, No Texture Mapping",theTime1,getMemReport() )

		st = timestamp()
		FranticParticles.SetProperty "EnableParticleCache" "true"
		max quick render
		local theTime2 = (timestamp()-st)
		append theResults #("PRT Volume Processing and Loading Time", theTime1-theTime2, getMemReport() )
		append theResults #("Particle Rendering, Box PRT Volume Spacing 0.5 Cached, No Texture Mapping",theTime2,getMemReport() )
		
		
		createMatteObjects()
		selectionsets["MatteSpheres"] = $Geosphere* as array
		FranticParticles.setProperty "Matte:UseMatteObjects" "true"
		FranticParticles.setProperty "Matte:NamedSelectionSets" "#(\"MatteSpheres\")"
		
		st = timestamp()
		max quick render
		local theTime3 = (timestamp()-st)
		append theResults #("PRT Volume, 35 Matte Objects / 28M Faces Processing Time", theTime3-theTime2, getMemReport() )
		append theResults #("Particle Rendering, Box PRT Volume Spacing 0.5 Cached, 35 Matte Objects With 28M Faces",theTime3,getMemReport() )
		
		FranticParticles.setProperty "Matte:UseMatteObjects" "false"		
		
		$PRTVolume_*.VoxelLength = 0.75
		FranticParticles.SetProperty "EnableParticleCache" "false"
		
		st = timestamp()
		max quick render
		local theTime = (timestamp()-st)
		append theResults #("Particle Rendering, Box PRT Volume Spacing 0.75, No Mapping",theTime,getMemReport() )		

		renderers.current.ColorOverrideTexmap = cellular size:50
		FranticParticles.SetProperty "ColorOverride:Enabled" true
		FranticParticles.SetProperty "ColorOverride:BlendAmount" 100.0

		st = timestamp()
		max quick render
		local theTime = (timestamp()-st)
		append theResults #("Particle Rendering, Box PRT Volume Spacing 0.75, Cellular Color Map",theTime,getMemReport() )

		renderers.current.DensityOverrideTexmap = cellular size:50
		FranticParticles.SetProperty "DensityOverride:Enabled" true
		FranticParticles.SetProperty "DensityOverride:BlendAmount" 100.0

		st = timestamp()
		max quick render
		local theTime = (timestamp()-st)
		append theResults #("Particle Rendering, Box PRT Volume Spacing 0.75, Cellular Color and Density Maps",theTime,getMemReport() )

		FranticParticles.setProperty "RenderingMethod" "Voxel Rendering"
		FranticParticles.setProperty "Density:DensityExponent" "-2" 
		FranticParticles.setProperty "Lighting:Density:DensityExponent" "-3"
		
		st = timestamp()
		max quick render
		local theTime = (timestamp()-st)
		append theResults #("Voxel Rendering, Box PRT Volume Spacing 0.75, Cellular Color and Density Maps",theTime,getMemReport() )
	)

	fn runPFlowBenchmark =
	(
		createPFlow numParticles:10000000
		setUpKrakatoa()
		FranticParticles.setProperty "RenderParticleFlowGeometry" "true"

		st = timestamp()
		max quick render
		local theTime1 = (timestamp()-st)
		append theResults #("Particle Rendering, PFlow Not Cached, No Texture Mapping",theTime1,getMemReport() )

		st = timestamp()
		max quick render
		local theTime2 = (timestamp()-st)
		append theResults #("PFlow Processing Time", theTime1-theTime2, getMemReport() )
		append theResults #("Particle Rendering, PFlow Cached, No Texture Mapping",theTime2,getMemReport() )

		
		createMatteObjects()
		selectionsets["MatteSpheres"] = $Geosphere* as array
		FranticParticles.setProperty "Matte:UseMatteObjects" "true"
		FranticParticles.setProperty "Matte:NamedSelectionSets" "#(\"MatteSpheres\")"
		
		st = timestamp()
		max quick render
		local theTime3 = (timestamp()-st)
		append theResults #("PFlow, 35 Matte Objects / 28M Faces Processing Time", theTime3-theTime2, getMemReport() )
		append theResults #("Particle Rendering, PFlow Cached, 35 Matte Objects With 28M Faces",theTime3,getMemReport() )

		FranticParticles.setProperty "Matte:UseMatteObjects" "false"		

		renderers.current.ColorOverrideTexmap = cellular size:50
		FranticParticles.SetProperty "ColorOverride:Enabled" true
		FranticParticles.SetProperty "ColorOverride:BlendAmount" 100.0

		st = timestamp()
		max quick render
		local theTime = (timestamp()-st)
		append theResults #("Particle Rendering, PFlow Cached, Cellular Color Map",theTime,getMemReport() )

		renderers.current.DensityOverrideTexmap = cellular size:50
		FranticParticles.SetProperty "DensityOverride:Enabled" true
		FranticParticles.SetProperty "DensityOverride:BlendAmount" 100.0

		st = timestamp()
		max quick render
		local theTime = (timestamp()-st)
		append theResults #("Particle Rendering, PFlow Cached, Cellular Color and Density Maps",theTime,getMemReport() )

		FranticParticles.setProperty "RenderingMethod" "Voxel Rendering"
		FranticParticles.setProperty "Density:DensityExponent" "-2" 
		FranticParticles.setProperty "Lighting:Density:DensityExponent" "-3"
		
		st = timestamp()
		max quick render
		local theTime = (timestamp()-st)
		append theResults #("Voxel Rendering, PFlow Cached, Cellular Color and Density Maps",theTime,getMemReport() )

	)
	
	fn getMaxVersion =
	(
		theVer = maxVersion()
		case (theVer[1]/1000) of
		(
			9: "3ds Max 9"
			10: "3ds Max 2008"
			11: "3ds Max 2009"
			12: "3ds Max 2010"
			13: "3ds Max 2011"
			14: "3ds Max 2012"
			default: "3ds Max"
		)
	)
	
	fn runBenchmark2 =
	(
		local theTeapot = teapot radius:60
		local theMat = standard selfillummap:(cellular size:50 fractal:true)
		theTeapot.material = theMat
		select theTeapot
		macros.run "Krakatoa" "PRTVolume"
		$PRTVolume_*.VoxelLength = 0.75
		setUpKrakatoa()
		FranticParticles.setProperty "RenderGeometryVolumes" "true"
		FranticParticles.setProperty "Density:DensityExponent" "-2" 
		FranticParticles.setProperty "Lighting:Density:DensityExponent" "-3"		
			
		st = timestamp()
		max quick render
		local theTime = (timestamp()-st)
		append theResults #("Particle Rendering, PRT Volume, Standard Material",theTime,getMemReport())

		theMat.diffuse = blue*0.3
		theMat.selfillummap.cellColor = yellow
		theMat.selfillummap.divColor1 = red*0.5
		theMat.selfillummap.divColor2 = black

		FranticParticles.setProperty "UseEmissionColor" "true"
		st = timestamp()
		max quick render
		local theTime = (timestamp()-st)
		append theResults #("Particle Rendering, PRT Volume, Standard + Cellular Self-Illumination Map",theTime,getMemReport())

		FranticParticles.setProperty "RenderingMethod" "Voxel Rendering"
		FranticParticles.setProperty "VoxelSize" "0.75"
		st = timestamp()
		max quick render
		local theTime = (timestamp()-st)
		append theResults #("Voxel Rendering, PRT Volume, Standard + Cellular Self-Illumination Map",theTime,getMemReport())		
		
		FranticParticles.setProperty "ParticleMode" "Save Particles To File Sequence"
		local theFrameName = (Krakatoa_PresetsDirectory + "\\_Benchmark_0000.prt")
		FranticParticles.setProperty "ParticleFiles" theFrameName
		st = timestamp()
		max quick render
		local theTime = (timestamp()-st)
		append theResults #("Saving Particles, PRT Volume",theTime,getMemReport())	
		
		local thePRTLoader = KrakatoaPRTLoader()
		thePRTLoader.fileList = #(theFrameName)
		thePRTLoader.fileListFlags = #(3)
		FranticParticles.setProperty "ParticleMode" "Render Scene Particles"
		FranticParticles.setProperty "ParticleFiles" ""		
		FranticParticles.setProperty "RenderGeometryVolumes" "false"		
		FranticParticles.setProperty "RenderKrakatoaLoaders" "true"
		FranticParticles.setProperty "RenderingMethod" "Particle Rendering"
		
		st = timestamp()
		max quick render
		local theTime = (timestamp()-st)
		append theResults #("Particle Rendering, PRT Loader, Loaded Colors",theTime,getMemReport())	

		thePRTLoader.material = theMat
		st = timestamp()
		max quick render
		local theTime = (timestamp()-st)
		append theResults #("Particle Rendering, PRT Loader, Standard + Cellular Self-Illumination Map",theTime,getMemReport())	
		
		addModifier thePRTLoader (bend angle:90)
		select thePRTLoader 
		st = timestamp()
		max quick render
		local theTime = (timestamp()-st)
		append theResults #("Particle Rendering, PRT Loader, Bend Modifier",theTime,getMemReport())		

		deleteModifier thePRTLoader thePRTLoader.modifiers[1]
		theCullingSphere = Geosphere radius:50
		selectionsets["CullingTest"] = #(theCullingSphere )
		thePRTLoader.cullingNamedSelectionSet = "CullingTest"
		thePRTLoader.delegate.UpdateCullingNodes currentTime		
		thePRTLoader.useCullingGizmo = true
		
		st = timestamp()
		max quick render
		local theTime = (timestamp()-st)
		append theResults #("Particle Rendering, PRT Loader, Culling By Geosphere",theTime,getMemReport())		
		deleteFile (Krakatoa_PresetsDirectory + "\\_Benchmark_0000.prt")
	)
	
	fn saveResultsToDisk =
	(
		local theFileName = Krakatoa_PresetsDirectory + "\\BenchmarkResults\\BenchmarkResults_"+ FranticParticleRenderMXS.fixTimeString localtime +".krabench"
		makeDir (getFileNamePath theFileName) all:true
		
		setIniSetting theFileName "Info" "Version" theVersionString
		setIniSetting theFileName "Info" "Date" localtime
		setIniSetting theFileName "Info" "KrakatoaVersion" FranticParticles.Version
		setIniSetting theFileName "Info" "MaxVersion" (getMaxVersion())
		setIniSetting theFileName "Info" "MaxBuild" (if is64bitApplication() then "64" else "32") 
		setIniSetting theFileName "Info" "User" sysinfo.username
		setIniSetting theFileName "Info" "Computer" sysinfo.computername
		setIniSetting theFileName "Info" "CPUs" (sysinfo.cpucount as string)
			
		for i in theResults do 
		(
			setIniSetting theFileName i[1] "Time" (i[2] as string)
			setIniSetting theFileName i[1] "Memory" i[3]
		)			
			
		local r=sysinfo.getSystemMemoryInfo() 
		for i=2 to 7 do r[i] /= (1024*1024.)
			
		setIniSetting theFileName "Memory" "UsedMemory" ((r[1] as float) as string)
		setIniSetting theFileName "Memory" "TotalPhysicalMemory" (r[2] as string)
		setIniSetting theFileName "Memory" "FreePhysicalMemory" (r[2] as string)
		setIniSetting theFileName "Memory" "TotalVirtualMemory" (r[6] as string)
		setIniSetting theFileName "Memory" "FreeVirtualMemory" (r[7] as string)
		setIniSetting theFileName "Memory" "TotalPageFileSize" (r[4] as string)
		setIniSetting theFileName "Memory" "FreePageFileSize" (r[5] as string)
		
		local r=sysinfo.getMAXMemoryInfo()
		for i=2 to 9 do r[i] /= (1024*1024.)
		
		setIniSetting theFileName "Memory" "PageFaultsCount" (r[1] as string)
		setIniSetting theFileName "Memory" "WorkingSetSize" (r[3] as string)
		setIniSetting theFileName "Memory" "WorkingSetPeak" (r[2] as string)
		
		setIniSetting theFileName "Memory" "PagedPoolSize" (r[5] as string)
		setIniSetting theFileName "Memory" "PagedPoolPeak" (r[4] as string)

		setIniSetting theFileName "Memory" "NonPagedPoolSize" (r[7] as string)
		setIniSetting theFileName "Memory" "NonPagedPoolPeak" (r[6] as string)

		setIniSetting theFileName "Memory" "PageFileUseageSize" (r[9] as string)
		setIniSetting theFileName "Memory" "PageFileUseagePeak" (r[8] as string)
	)
	
	fn loadResultsFromDisk theFileNamesArray =
	(
		local theFileName = theFileNamesArray[1]
		local theKeys = getIniSetting theFileName 
		local theIndex = (findItem theKeys "Info")
		if theIndex > 0 do deleteItem theKeys theIndex
		local theIndex = (findItem theKeys "Memory")
		if theIndex > 0 do deleteItem theKeys theIndex
		local theResults = theKeys
		local theTimes = #(	for i in theKeys collect (getIniSetting theFileName i "Time"))
		local theMemory = #(for i in theKeys collect (getIniSetting theFileName i "Memory"))

		for i = 2 to theFileNamesArray.count do
		(
			local theFileName  = theFileNamesArray[i]
			append theTimes #()
			append theMemory #()
			for k in theKeys do
			(
				local timeValue = getIniSetting theFileName k "Time"
				if timeValue != "" then
				(
					append theTimes[i] timeValue
					append theMemory[i] (getIniSetting theFileName k "Memory")
				)
				else
				(
					append theTimes[i] "0"
					append theMemory[i] "Missing"
				)
			)
		)
		
		theInfo = #()
		for i = 1 to theFileNamesArray.count do
		(
			local theFileName  = theFileNamesArray[i]
			local theArray = #(
					getIniSetting theFileName "Info" "Version" ,
					getIniSetting theFileName "Info" "Date" ,
					getIniSetting theFileName "Info" "KrakatoaVersion" ,
					getIniSetting theFileName "Info" "MaxVersion" ,
					getIniSetting theFileName "Info" "MaxBuild" ,
					getIniSetting theFileName "Info" "User" ,
					getIniSetting theFileName "Info" "Computer" ,
					getIniSetting theFileName "Info" "CPUs",
					getIniSetting theFileName "Memory" "TotalPhysicalMemory"
			)
			append theInfo theArray
		)
		#(theResults, theTimes, theMemory, theInfo)
	)
	
	fn toHexColor theRGB =
	(
		theR = bit.intAsHex (theRGB.r as integer)
		theG = bit.intAsHex (theRGB.g as integer)
		theB = bit.intAsHex (theRGB.b as integer)
		"#" + theR as string + theG as string + theB as string 
	)
	
	fn generateHTML theArray=
	(
		local theHTMLFileName = Krakatoa_PresetsDirectory + "\\BenchmarkResults\\Comparison_"+ FranticParticleRenderMXS.fixTimeString localtime +".htm"
		local theHTMLFile = createFile theHTMLFileName 
		--format "<!doctype html public \"-//w3c//dtd html 4.0 transitional//en\">\n" to:theHTMLFile
		format "<HTML>\n" to:theHTMLFile
		format "<head>\n" to:theHTMLFile
		format "<title>Krakatoa Benchmarks Comparison</title>\n" to:theHTMLFile
		--format "<meta http-equiv=\"Content-Type\" content=\"text/html; charset=iso-8859-1\">\n" to:theHTMLFile
		format "</head>\n" to:theHTMLFile
		format "<body text=#FFFFFF bgcolor=#222222 link=#FFFFCC vlink=#FFFFCC alink=#FF0000 >\n" to:theHTMLFile
		format "<font face=\"Arial,Helvetica\">" to:theHTMLFile
		local theResults = theArray[1]
		local theTimes = theArray[2]
		local theMemory = theArray[3]
		local theInfo = theArray[4]
		
		totalTimesArray = #()
		for i = 1 to theTimes.count do
		(
			totalValue = 0
			for j = 1 to theTimes[i].count do
				totalValue += (execute theTimes[i][j])
			append totalTimesArray totalValue
		)
		format "<h1>KRAKATOA BENCHMARK RESULTS COMPARISON</h1>\n" to:theHTMLFIle
		
		format "<h2>TOTAL RESULTS</h2>\n" to:theHTMLFIle
		for i = 1 to totalTimesArray.count do
		(
			local theColor = black
			maxops.colorById i &theColor
			format "<table>\n"  to:theHTMLFile
			format "<tr><td bgcolor=% width=%>"  (toHexColor theColor) (totalTimesArray[i]/1000.0) to:theHTMLFile
			format "<font size=-2 face=\"Arial,Helvetica\" color=%>%@%-% cores-%KB-%/%" (toHexColor (white-theColor)) theInfo[i][6] theInfo[i][7] theInfo[i][8] (FranticParticleRenderMXS.addCommas ((theInfo[i][9] as integer) as string)) theInfo[i][4] theInfo[i][5]  to:theHTMLFile
			format "</td><td><font face=\"Arial,Helvetica\">% sec.</td></tr>\n" (totalTimesArray[i]/1000.0) to:theHTMLFile
			format "</table>\n" to:theHTMLFile
		)
		
		format "<h2>DETAILED RESULTS</h2>\n" to:theHTMLFIle

		for r = 1 to theResults.count do
		(
			if (for i = 1 to theTimes.count where theTimes[i][r] == "0" collect i).count == 0 do
			(
				format "<table width=1000>\n"  to:theHTMLFile
				format "<tr><td bgcolor = #444455><font face=\"Arial,Helvetica\">% - (%)</td></tr>\n" theResults[r] theMemory[1][r] to:theHTMLFile
				format "</table>\n"  to:theHTMLFile
				for i = 1 to theTimes.count do
				(
					local theColor = black
					maxops.colorById i &theColor
					format "<table>\n"  to:theHTMLFile
					--if i == 1 do format "<tr><td width=1000>%</td></tr>\n" theResults[r] to:theHTMLFile
					local theTime = (execute theTimes[i][r])
					format "<tr><td bgcolor=% width=%>"  (toHexColor theColor) (theTime/100.0) to:theHTMLFile
					format "<font color=%>|"  (toHexColor theColor) to:theHTMLFile
					format "</td><td><font face=\"Arial,Helvetica\">% sec.</td></tr>\n" (theTime/1000.0) to:theHTMLFile
					format "</table>\n" to:theHTMLFile
				)
			)
		)
		
		format "</body>\n" to:theHTMLFile
		format "</HTML>\n" to:theHTMLFile
		
		close theHTMLFile
		shellLaunch theHTMLFileName ""
	)
	
	fn drawResults theArray =
	(
		local theResults = theArray[1]
		local theTimes = theArray[2]
		local theMemory = theArray[3]
		local theBitmap = bitmap 400 (theResults.count*theTimes.count+theTimes.count+1) color:(white*0.75)
		local theColors = for i = 1 to theTimes.count collect (maxops.colorById i &theColor; theColor)
		
		local y = 0
		for r = 1 to theResults.count do
		(
			for i = 1 to theTimes.count do
			(
				local theColorLine = for x = 1 to ((execute theTimes[i][r])/100.0) collect theColors[i]
				setPixels theBitmap [0,y] theColorLine
				y+= 1
			)
			y +=1
		)
		finalBitmap = bitmap 400 (theBitmap.height*10)
		copy theBitmap finalBitmap 
		display finalBitmap 
	)
	
	fn printResults theStream=
	(
		format "===============================================================\n" to:theStream
		format "==KRAKATOA RENDERING BENCHMARK v%==\n" theVersionString to:theStream
		format "===============================================================\n" to:theStream
		format "Krakatoa v%\n" FranticParticles.Version to:theStream
		format "% % bit\n"  (getMaxVersion()) (if is64bitApplication() then "64" else "32") to:theStream
		format "Created on % by %@%\n" localtime sysinfo.username sysinfo.computername to:theStream
		format "===============================================================\n" to:theStream
		for i in theResults do format "% sec. : % - %\n" (i[2]/1000.0)  i[1] i[3] to:theStream
		format "===============================================================\n" to:theStream
		local theTotalScore = 0.0
		for i in theResults do theTotalScore += i[2]
		format "TOTAL TIME: % sec.\n" (theTotalScore/1000.0) to:theStream	
		theTotalScore = 1000000.0/theTotalScore 
		theTotalScore *= 1000.0
		theTotalScore = theTotalScore as integer
		format "TOTAL SCORE: % (higher is better)\n" theTotalScore to:theStream	
		format "===============================================================\n" to:theStream
		
		format "CPU Count: %\n" sysInfo.cpucount to:theStream

		r=sysinfo.getSystemMemoryInfo() 
		for i=2 to 7 do r[i] /= (1024*1024.)
		format "UsedMemory: %\n" ((r[1] as float) as string + "%") to:theStream
		format  "PhysicalMemory: %\n" ("Total:" + r[2] as string + " MB   Used:" + (r[2]-r[3]) as string + " MB   Free:" + r[3] as string + " MB")  to:theStream
		format  "VirtualMemory: %\n" ("Total:" + r[6] as string + " MB   Used:" + (r[6]-r[7]) as string + " MB   Free:" + r[7] as string + " MB") to:theStream
		format  "PageFileSize: %\n" ("Total:" + r[4] as string + " MB   Used:" + (r[4]-r[5]) as string + " MB   Free:" + r[5] as string + " MB") to:theStream

		r=sysinfo.getMAXMemoryInfo()
		for i=2 to 9 do r[i] /= (1024*1024.)
		format  "PageFaultsCount: %\n" ((r[1] as integer) as string) to:theStream
		format  "WorkingSet: %\n" ("Size:" + r[3] as string + " MB   Peak:" + r[2] as string + " MB") to:theStream
		format  "PagedPool: %\n" ("Size:" + r[5] as string + " MB   Peak:" + r[4] as string + " MB") to:theStream
		format  "NonPagedPool: %\n" ("Size:" + r[7] as string + " MB   Peak:" + r[6] as string + " MB") to:theStream
		format  "PageFileUseage: %\n" ("Size:" + r[8] as string + " MB   Peak:" + r[9] as string + " MB") to:theStream
		format "===============================================================\n" to:theStream
	)
	
	
	rollout Krakatoa_Benchmark_Dialog "Krakatoa Benchmark"
	(
		local theFileNamesArray = #()
		button btn_doBenchmark "RUN BENCHMARK" across:2
		button btn_exploreFolder "Explore Folder"
		multilistbox lbx_AllBenchmarks "Existing Benchmarks" height:20
		button btn_compareSelected "Compare Selected Results"
		
		on btn_exploreFolder pressed do
		(
			shellLaunch (Krakatoa_PresetsDirectory + "\\BenchmarkResults\\") ""
		)
		
		fn updateUI =
		(
			theFileNamesArray = getFiles (Krakatoa_PresetsDirectory + "\\BenchmarkResults\\BenchmarkResults_*.krabench")
			lbx_AllBenchmarks.items = for i in theFIleNamesArray collect 
			(
				(getIniSetting i "Info" "User")+"@"+(getIniSetting i "Info" "Computer") + " " + (getIniSetting i "Info" "CPUs") + " Cores - "+ (getIniSetting i "Info" "MaxVersion") + "/" + (getIniSetting i  "Info" "MaxBuild") + " - Krakatoa "+ (getIniSetting i "Info" "KrakatoaVersion") + " on "+ (getIniSetting i  "Info" "Date")
			)			
		)
		
		on Krakatoa_Benchmark_Dialog open do
		(
			updateUI()
		)
		
		on btn_compareSelected pressed do
		(
			
			if lbx_AllBenchmarks.selection.numberset > 1 do
			(
				local theResultsArray = (loadResultsFromDisk (for i in lbx_AllBenchmarks.selection collect theFileNamesArray [i]))
				--drawResults theResultsArray
				generateHTML theResultsArray 
			)
		)
		
		on btn_doBenchmark pressed do
		(
			createBaseScene()
			runPFlowBenchmark()
			
			createBaseScene()
			runBenchmark1()

			createBaseScene()
			runBenchmark2()
			
			saveResultsToDisk()
			
			resetMaxFile #noprompt
			
			updateUI()
			
			/*
			local theFileName = Krakatoa_PresetsDirectory + "\\BenchmarkResults\\BenchmarkResults_"+ FranticParticleRenderMXS.fixTimeString localtime +".txt"
			makeDir (getFileNamePath theFileName) all:true
			local theStream = createFile theFileName
			printResults theStream  
			close theStream
			edit theFileName
			*/
		)
	)
	createDialog Krakatoa_Benchmark_Dialog 600 400
)

/*
--Dual QuadCore Xeon
===============================================================
==KRAKATOA RENDERING BENCHMARK v0.0.3==
===============================================================
Krakatoa v1.5.0.37775
3ds Max 2008 64 bit
===============================================================
25.625 sec. : Particle Rendering, PFlow Not Cached, No Texture Mapping - In Memory: 10,000,000 Particles Using 267.029 MB.
8.406 sec. : PFlow Processing Time - In Memory: 10,000,000 Particles Using 267.029 MB.
17.219 sec. : Particle Rendering, PFlow Cached, No Texture Mapping - In Memory: 10,000,000 Particles Using 267.029 MB.
1.313 sec. : 28M Faces Matte Objects Processing Time - In Memory: 10,000,000 Particles Using 267.029 MB.
18.532 sec. : Particle Rendering, PFlow Cached, Matte Objects 28M Faces - In Memory: 10,000,000 Particles Using 267.029 MB.
20.047 sec. : Particle Rendering, PFlow Cached, Cellular Color Map - In Memory: 10,000,000 Particles Using 267.029 MB.
22.734 sec. : Particle Rendering, PFlow Cached, Cellular Color and Density Maps - In Memory: 10,000,000 Particles Using 267.029 MB.
20.297 sec. : Voxel Rendering, PFlow Cached, Cellular Color and Density Maps - In Memory: 10,000,000 Particles Using 190.735 MB.
8.672 sec. : Particle Rendering, PRT Volume, Standard Material - In Memory: 1,606,632 Particles Using 42.9017 MB.
9.047 sec. : Particle Rendering, PRT Volume, Standard + Cellular Self-Illumination Map - In Memory: 1,606,632 Particles Using 49.0305 MB.
15.859 sec. : Voxel Rendering, PRT Volume, Standard + Cellular Self-Illumination Map - In Memory: 1,606,632 Particles Using 42.9017 MB.
9.094 sec. : Saving Particles, PRT Volume - In Memory: 0 Particles Using 0.0 MB.
4.969 sec. : Particle Rendering, PRT Loader, Loaded Colors - In Memory: 1,606,632 Particles Using 49.0305 MB.
5.516 sec. : Particle Rendering, PRT Loader, Standard + Cellular Self-Illumination Map - In Memory: 1,606,632 Particles Using 49.0305 MB.
7.0 sec. : Particle Rendering, PRT Loader, Bend Modifier - In Memory: 1,606,632 Particles Using 49.0305 MB.
4.593 sec. : Particle Rendering, PRT Loader, Culling By Geosphere - In Memory: 561,881 Particles Using 17.1472 MB.
===============================================================
TOTAL TIME: 198.923 sec.
TOTAL SCORE: 5027 (higher is better)
===============================================================
CPU Count: 8
UsedMemory: 18.0%
PhysicalMemory: Total:16381.4 MB   Used:2993.59 MB   Free:13387.8 MB
VirtualMemory: Total:8.38861e+006 MB   Used:2419.5 MB   Free:8.38619e+006 MB
PageFileSize: Total:38809.8 MB   Used:2356.33 MB   Free:36453.4 MB
PageFaultsCount: 5781382
WorkingSet: Size:432.176 MB   Peak:3918.9 MB
PagedPool: Size:1.27641 MB   Peak:1.30785 MB
NonPagedPool: Size:0.176571 MB   Peak:0.203335 MB
PageFileUseage: Size:502.098 MB   Peak:3992.71 MB
===============================================================


--Gateway FX


*/