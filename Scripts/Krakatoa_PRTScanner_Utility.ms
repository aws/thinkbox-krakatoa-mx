-- Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
-- SPDX-License-Identifier: Apache-2.0
macroScript KrakatoaPRTscan category:"Krakatoa" icon:#("krakatoa",5)
(
global Krakatoa_PRTScanResults = #()
global Krakatoa_ScanPRT_Floater
local Krakatoa_ScanPRT_Main

local theSizes = #()
local theActualSizes = #()
local thePflowActualSizes = #()
local theFiles = #()
local theTimes = #()
local theResults= #()
local theErrors = #()
local theMissingFiles = #()
local theBadFiles = #()
	
local bodyColor = "#333333"
local titleBGColor = "#555555"
local cellBGColor = "#444444"
local theCommentBGColor = "#333344"

local redColor =  "#CC0022"
local titleColor = "#FFFFFF"
local textColor = "#FFFFCC"
local linkColor = "#CCCCFF"
local grayOutColor = "#777777"

local memoryBytesPerParticle = 38


local SceneSizes = #()

fn LeadingZeros value count =
(
	theStr = value as string
	substring "00000000000" 1 (count-(theStr.count))
)

fn underscoreLocalTime txt =
(
	local newString  = ""
	for i in (filterString txt ".: /-") do newString += ("_" + i)
	newString 
)	


fn generateIndexHTML =
(
	theHTMLpath = Krakatoa_PresetsDirectory+ "\\PRTscan" 
	makeDir theHTMLpath 
	makeDir (theHTMLpath + "\\images")
	theHTMLname = theHTMLpath + "\\prtscan_"+ getFileNameFile maxFileName+ "_" + underscoreLocalTime localtime +".htm"
	theHTML = createFile theHTMLname
	
	format "<html>\n" to:theHTML
	format "<head>\n" to:theHTML
	format "<title>Krakatoa: PRT Analysis [%]</title>\n" maxfilename to:theHTML
	
	format "<meta http-equiv=\"Content-Type\" content=\"text/html; charset=iso-8859-1\">" to:theHTML
	format "</head>\n" to:theHTML
	
	format "<body bgcolor=% text=% link=% vlink=%>\n" bodyColor textColor linkColor linkColor   to:theHTML
	format "<font face=\"Verdana\">\n" to:theHTML
	
	format "<table border=\"0\" width=\"100\%\" cellspacing=\"3\" cellpadding=\"2\">\n" to:theHTML
	format "<tr><td bgcolor=%>\n" titleBGColor to:theHTML
	format "<h3 align=\"center\"><font color=%>KRAKATOA PRT ANALYSIS RESULTS</h3>\n" titleColor to:theHTML
	format "</td></tr>\n" to:theHTML
	
	format "<tr><td bgcolor=% align=\"center\"><font size=-1>Report Generated on % by %@%</font></td></tr>\n" cellBGColor  localTime sysinfo.userName sysinfo.computername to:theHTML
	format "<tr><td bgcolor=% align=\"center\"><font size=-1>Max File Name:[<b>%</b>]</font></td></tr>\n" cellBGColor (maxFilePath+MaxFileName)  to:theHTML
	format "<tr><td bgcolor=% align=\"center\"><font size=-1>Memory Reference Line:<b>%</b>MB  -  Bytes Per Particle:<b>%</b></font></td></tr>\n" cellBGColor Krakatoa_ScanPRT_Main.spn_memoryLimit.value memoryBytesPerParticle to:theHTML
	format "<tr><td bgcolor=% align=\"center\"><font size=-1>Grid:Minor Line Every <b>%</b> Frames; Major Line Every <b>%</b> Minor Lines</font></td></tr>\n" cellBGColor Krakatoa_ScanPRT_Main.spn_gridSpacing.value Krakatoa_ScanPRT_Main.spn_gridSpacingMajor.value to:theHTML
	
	if Krakatoa_ScanPRT_Main.chk_useLoaderTiming.checked do
		format "<tr><td bgcolor=% align=\"center\"><font size=-1>Showing Actual Frames Based on the Loader's Timing Settings.</font></td></tr>\n" cellBGColor to:theHTML
	if Krakatoa_ScanPRT_Main.chk_useLoaderPercentage.checked then
		format "<tr><td bgcolor=% align=\"center\"><font size=-1>Showing Both Particle Counts on Disk and Render Counts Based on the Loader's Percentage.</font></td></tr>\n" cellBGColor to:theHTML
	else	
		format "<tr><td bgcolor=% align=\"center\"><font size=-1>Showing Particle Counts on Disk.</font></td></tr>\n" cellBGColor to:theHTML
	txt = "Scanning For <b>PRT Loaders</b>"	
	if Krakatoa_ScanPRT_Main.chk_scanGeometry.checked  do txt += ", <b>Geometry Vertices</b>"
	if Krakatoa_ScanPRT_Main.chk_scanPFlows.checked do txt += ", <b>Particle Flows</b>"
	format "<tr><td bgcolor=% align=\"center\"><font size=-1>%</font></td></tr>\n" cellBGColor txt to:theHTML
	
	format "<tr><td>   </td></tr>\n" to:theHTML

	format "<tr><td bgcolor=% ><font color=% size=+1><b>%</b></font></td></tr>\n" bodyColor bodyColor "|"  to:theHTML	

	format "<tr><td>   </td></tr>\n" to:theHTML
	format "<tr><td>   </td></tr>\n" to:theHTML
	
	format "</table>\n" to:theHTML
	
	format "<table border=\"0\" width=\"500\" cellspacing=\"1\" cellpadding=\"1\" align=\"center\">\n" to:theHTML
	

	for prt = 1 to Krakatoa_PRTScanResults.count do
	(
		try(theName = Krakatoa_PRTScanResults[prt][1].name)catch(theName = maxFileName)
		local theMap = for i = 1 to Krakatoa_PRTScanResults[prt][2].count collect i
		temp = theMap[1]
		theMap[1] = theMap[theMap.count] 
		theMap[theMap.count] = temp		
		for i in theMap do
		(
			format "<tr><td colspan=3 bgcolor=% align=\"center\"><font color=% size=-2><b>[%]</b> - %</font></td></tr>\n" titleBGColor textColor theName (fileNameFromPath Krakatoa_PRTScanResults[prt][2][i][6]) to:theHTML	
			format "<tr><td bgcolor=% align=\"left\" ><font color=% size=-2>Frame <b>%</b> - Source Min:<b>%</b></font></td>\n" titleBGColor textColor (Krakatoa_PRTScanResults[prt][2][i][12]) (Krakatoa_PRTScanResults[prt][2][i][4]) to:theHTML	
			format "<td bgcolor=% align=\"center\" ><font color=% size=-2>Frame <b>%</b> - Source Max:<b>%</b> (%MB)</font></td>\n" titleBGColor textColor (Krakatoa_PRTScanResults[prt][2][i][13]) (Krakatoa_PRTScanResults[prt][2][i][3]) (Krakatoa_PRTScanResults[prt][2][i][3] * memoryBytesPerParticle / 1024.0 / 1024.0) to:theHTML	
			format "<td bgcolor=% align=\"right\" ><font color=% size=-2>Source Avg:<b>%</b></font></td></tr>\n" titleBGColor textColor (Krakatoa_PRTScanResults[prt][2][i][5] as integer) to:theHTML	

			if Krakatoa_ScanPRT_Main.chk_useLoaderPercentage.checked do			
			(
				format "<tr><td bgcolor=% align=\"left\"><font color=% size=-2 >Render Min:<b>%</b></font></td>\n" titleBGColor textColor (Krakatoa_PRTScanResults[prt][2][i][9]) to:theHTML	
				format "<td bgcolor=% align=\"center\" ><font color=% size=-2>Render Max:<b>%</b> (%MB)</font></td>\n" titleBGColor textColor Krakatoa_PRTScanResults[prt][2][i][10] (Krakatoa_PRTScanResults[prt][2][i][10] * memoryBytesPerParticle / 1024.0 / 1024.0) to:theHTML	
				format "<td bgcolor=% align=\"right\" ><font color=% size=-2>Render Avg:<b>%</b></font></td></tr>\n" titleBGColor textColor (Krakatoa_PRTScanResults[prt][2][i][11] as integer) to:theHTML	
			)
			
			Krakatoa_PRTScanResults[prt][2][i][1].filename = theHTMLpath + "\\images\\" + getFileNameFile theHTMLname + "_" + prt as string + "_"+i as string +".jpg"
			save Krakatoa_PRTScanResults[prt][2][i][1]
			
			format "<tr><td colspan=3 bgcolor=% ><font color=% size=+1><img src=\"images/%\"></img></font></td></tr>\n" bodyColor textColor (filenameFromPath Krakatoa_PRTScanResults[prt][2][i][1].filename) to:theHTML	

			format "<tr><td bgcolor=% align=\"left\"><font color=% size=-2>From:<b>%</b></font></td>\n" titleBGColor textColor (fileNameFromPath Krakatoa_PRTScanResults[prt][2][i][7]) to:theHTML	
			format "<td bgcolor=% align=\"center\" ><font color=% size=-2>Frames:<b>%</b></font></td>\n" titleBGColor textColor Krakatoa_PRTScanResults[prt][2][i][2] to:theHTML	
			format "<td bgcolor=% align=\"right\"><font color=% size=-2 >To:<b>%</b></font></td></tr>\n" titleBGColor textColor ( fileNameFromPath Krakatoa_PRTScanResults[prt][2][i][8] ) to:theHTML	
			format "<tr><td colspan=3 bgcolor=% ><font color=% size=+1>|</font></td></tr>\n" bodyColor bodyColor to:theHTML	
		)
	)--end prt	
	
	format "</table>\n" to:theHTML
	
	format "</body>\n" to:theHTML
	format "</html>\n" to:theHTML
	close theHTML 
	shelllaunch "explorer.exe" theHTMLname 
)

fn drawBitmap theLoader theMode theSizeArray thePattern colorsArray =
(
	local startFrame = animationrange.start.frame as integer
	local endFrame = animationrange.end.frame as integer
	local ScaleMode = (if Krakatoa_ScanPRT_Main.ddl_scaleMode.selection == 1 then 0 else Krakatoa_ScanPRT_Main.spn_scaleMode.value*1000) 
	local missingColors = #(Krakatoa_ScanPRT_Main.clr_missing01.color, Krakatoa_ScanPRT_Main.clr_missing02.color)
	local theHeight = Krakatoa_ScanPRT_Main.spn_GraphHeight.value as float
	local theWidth = 500.0
	if Krakatoa_ScanPRT_Main.chk_generateHTML.checked then
	(
		theHeight = Krakatoa_ScanPRT_Main.spn_HtmlHeight.value as float
		theStep = floor (Krakatoa_ScanPRT_Main.spn_HtmlWidth.value/(endFrame - startFrame + 1))
		if theStep < 1 do theStep = 1
		theWidth = (endFrame - startFrame + 1) * theStep
		if theWidth > Krakatoa_ScanPRT_Main.spn_HtmlWidth.value do theWidth = Krakatoa_ScanPRT_Main.spn_HtmlWidth.value
		if theWidth < 500 do theWidth = 500
	)	
	local theBitmap = bitmap (theSizeArray.count) (theHeight) color:(color colorsArray[3].r colorsArray[3].g colorsArray[3].b 0)
	local theMaxVal = amax theSizeArray
	local theMinVal = amin theSizeArray
	local theMaxIndex = findItem theSizeArray theMaxVal
	local theMinIndex = findItem theSizeArray theMinVal
	
	if theMinVal < 0 do theMinVal = 0
	local theActualMax = 0
	local theActualMin = 1000000
	local theActualAverage = 0.0
	local theActualCount = 0
	
	local theAverage = 0.0
	local theCount = 0
	for i in theSizeArray where i >= 0 do ( theAverage += i; theCount += 1)
	if theCount > 0 then theAverage /= theCount else theAverage = 0
	
	local theScale = if ScaleMode == 0 then 
		if theMaxVal > 0 then theHeight / theMaxVal else theHeight
	else 
		theHeight  / ScaleMode
	local iter = 1
	for i = 1 to theSizeArray.count do 
	(
		iter = 1-iter
		if theSizeArray[i] > -1 then
		(
			if theErrors[i] == 0 then
				theColor = colorsArray[iter+1]
			else	
				theColor = missingColors[iter+1]--+(#(color -50 50 50,color 0 10 10)[iter+1])
			
			if Krakatoa_ScanPRT_Main.chk_useLoaderPercentage.state then
			(
				if theLoader != undefined and classof theLoader == KrakatoaPrtLoader then
				(
					theHValue = (theSizeArray[i] * theScale)
					if theHValue < 3 do theHValue = 3
					for y = 0 to theHValue  do
						setPixels theBitmap [i-1,theHeight-y] #(theColor*2)
					theActualValue = (theSizeArray[i] * (at time theTimes[i] theLoader.percentRenderer)/100.0 ) as integer
					if not theLoader.enabledInRender do theActualValue = 0
					if theActualValue > theActualMax do theActualMax = theActualValue
					if theActualValue < theActualMin do theActualMin = theActualValue
					if theActualValue > -1 do
					(
						theActualAverage += theActualValue
						theActualCount += 1
					)	
					theHValue =theScale * theActualValue
					if theHValue > 0 and theHValue < 2 do theHValue = 2
					for y = 0 to theHValue  do
						setPixels theBitmap [i-1,theHeight-y] #(theColor)
				)
				else
				(
					case theMode of
					(
						#geometry:
						(
							theActualValue = theSizeArray[i] as integer
							if theActualValue > theActualMax do theActualMax = theActualValue
							if theActualValue < theActualMin do theActualMin = theActualValue
							if theActualValue > -1 do
							(
								theActualAverage += theActualValue
								theActualCount += 1
							)							
							theHValue = (theSizeArray[i] * theScale)
							if theHValue > 0 and theHValue < 2 do theHValue = 2
							for y = 0 to theHValue  do
								setPixels theBitmap [i-1,theHeight-y] #(theColor)					
						)	
						#maxlegacy:
						(
							theActualValue = theSizeArray[i] as integer
							if theActualValue > theActualMax do theActualMax = theActualValue
							if theActualValue < theActualMin do theActualMin = theActualValue
							if theActualValue > -1 do
							(
								theActualAverage += theActualValue
								theActualCount += 1
							)							
							theHValue = (theSizeArray[i] * theScale)
							if theHValue > 0 and theHValue < 2 do theHValue = 2
							for y = 0 to theHValue  do
								setPixels theBitmap [i-1,theHeight-y] #(theColor)					
						)						
						#pflow:
						(
							theActualValue = thePflowActualSizes[i] as integer
							if theActualValue > theActualMax do theActualMax = theActualValue
							if theActualValue < theActualMin do theActualMin = theActualValue
							if theActualValue > -1 do
							(
								theActualAverage += theActualValue
								theActualCount += 1
							)	
							theHValue = (theSizeArray[i] * theScale)
							if theHValue > 0 and theHValue < 2 do theHValue = 2
							for y = 0 to theHValue  do
								setPixels theBitmap [i-1,theHeight-y] #(theColor*2)					
							
							theHValue = (thePflowActualSizes[i] * theScale)
							if theHValue > 0 and theHValue < 2 do theHValue = 2
							for y = 0 to theHValue  do
								setPixels theBitmap [i-1,theHeight-y] #(theColor)					
						)						
						default:				
						(
							theHValue = (theSizeArray[i] * theScale)
							if theHValue > 0 and theHValue < 2 do theHValue = 2
							for y = 0 to theHValue  do
								setPixels theBitmap [i-1,theHeight-y] #(theColor*2)
							theActualValue = theActualSizes[i] as integer
							if theActualValue > theActualMax do theActualMax = theActualValue
							if theActualValue < theActualMin do theActualMin = theActualValue
							if theActualValue > -1 do
							(
								theActualAverage += theActualValue
								theActualCount += 1
							)	
							theHValue = (theActualSizes[i] * theScale)
							if theHValue > 0 and theHValue < 2 do theHValue = 2
							for y = 0 to theHValue  do
								setPixels theBitmap [i-1,theHeight-y] #(theColor)				
						)
					)--end case
				)
			)
			else
			(
				theHValue = (theSizeArray[i] * theScale)
				if theHValue > 0 and theHValue < 2 do theHValue = 2
				for y = 0 to theHValue  do
					setPixels theBitmap [i-1,theHeight-y] #(theColor)
			)		
		)		
		else
		(
			if theSizeArray[i] == -1 then
				theColor = missingColors [iter+1]
			else	
				theColor = colorsArray[iter+1] --* 0.7
			
			for y = 0 to theHeight do
				setPixels theBitmap [i-1,theHeight-y] #(theColor*(1.0-1.0*y/theHeight) + colorsArray[3]*(1.0*y/theHeight) )
		)		
	)
	local theDisplay = bitmap theWidth theHeight 
	copy theBitmap theDisplay 
	
	local theXScale = theWidth as float / (endFrame - startFrame + 1)
	cnt = 0
	for i = startFrame to endFrame do
	(
		if floor(i/Krakatoa_ScanPRT_Main.spn_gridSpacing.value) == i/(Krakatoa_ScanPRT_Main.spn_gridSpacing.value as float) do
		(
			for v = 0 to theHeight-1 do
			(
				thePixels = (getPixels theDisplay [cnt,v] 1)[1]
				if try(thePixels.a < 255)catch(false) do
				(
					if i == 0 then
						setPixels theDisplay [cnt,v ] #((color colorsArray[3].r (colorsArray[3].g*1.75) colorsArray[3].b 0)*0.5)
					else
					if floor(i/(Krakatoa_ScanPRT_Main.spn_gridSpacing.value*Krakatoa_ScanPRT_Main.spn_gridSpacingMajor.value)) == i/(Krakatoa_ScanPRT_Main.spn_gridSpacingMajor.value*Krakatoa_ScanPRT_Main.spn_gridSpacing.value as float) then
						setPixels theDisplay [cnt,v ] #((color colorsArray[3].r colorsArray[3].g (colorsArray[3].b*1.5) 0)*0.5)
					else
						setPixels theDisplay [cnt,v ] #((color colorsArray[3].r colorsArray[3].g colorsArray[3].b 0)*0.9)
				)	
			)	
		)	
		cnt += theXScale 
	)
	if theActualCount == 0 do theActualCount = 1
	case theMode of
	(
		#sequence: append theResults #(theDisplay, theSizeArray.count, theMaxVal , theMinVal , theAverage, thePattern, theFiles[1], theFiles[theFiles.count], theActualMin, theActualMax, theActualAverage/theActualCount, theMinIndex,theMaxIndex   )
		#loader: append theResults #(theDisplay, theSizeArray.count, theMaxVal , theMinVal , theAverage, ("PRT LOADER TOTALS - Vertical Scale:"+ (if scaleMode == 0 then "FIT" else scaleMode as string) ), (startFrame as string), (endFrame as string), theActualMin , theActualMax, theActualAverage/theActualCount , theMinIndex,theMaxIndex     )
		#geometry: append theResults #(theDisplay, theSizeArray.count, theMaxVal , theMinVal , theAverage, ("GEOMETRY VERTICES  - Vertical Scale:"+ (if scaleMode == 0 then "FIT" else scaleMode as string) ), (startFrame as string), (endFrame as string), theActualMin , theActualMax, theActualAverage/theActualCount , theMinIndex,theMaxIndex     )
		#maxlegacy: append theResults #(theDisplay, theSizeArray.count, theMaxVal , theMinVal , theAverage, ("MAX LEGACY PARTICLES ("+ (classof theLoader) as string +") - Vertical Scale:"+ (if scaleMode == 0 then "FIT" else scaleMode as string) ), (startFrame as string), (endFrame as string), theActualMin , theActualMax, theActualAverage/theActualCount , theMinIndex,theMaxIndex     )
		
		#pflow: append theResults #(theDisplay, theSizeArray.count, theMaxVal , theMinVal , theAverage, ("PFLOW PARTICLES - Vertical Scale:"+ (if scaleMode == 0 then "FIT" else scaleMode as string) ), (startFrame as string), (endFrame as string), theActualMin , theActualMax, theActualAverage/theActualCount , theMinIndex,theMaxIndex     )
		
		#scene: (
				theMemoryLimit = Krakatoa_ScanPRT_Main.spn_memoryLimit.value
				if theMemoryLimit  > 0 do
				(
					local theMemoryLimit = (theMemoryLimit *1024.0*1024/memoryBytesPerParticle) 
					setPixels theDisplay [0,theHeight - theMemoryLimit* theScale] (for i = 1 to theWidth collect red)
				)	
				titleText = if Krakatoa_ScanPRT_Main.rad_scanMode.state == 1 then "SCENE TOTALS" else "SELECTED SOURCES"
				#("",#( #(theDisplay, theSizeArray.count, theMaxVal , theMinVal , theAverage, (titleText+" - Vertical Scale:"+ (if scaleMode == 0 then "FIT" else scaleMode as string) ), (startFrame as string), (endFrame as string), theActualMin, theActualMax, theActualAverage/theActualCount , theMinIndex,theMaxIndex      ) ))
		)
	)
)


fn scanMaxParticles theObject =
(
	theResults = #()
	theSizes = #()
	local startFrame = animationrange.start.frame as integer
	local endFrame = animationrange.end.frame as integer
	local totalSizes = for i = startFrame  to endFrame  collect -1
	if theActualSizes.count == 0 do theActualSizes = for i = startFrame  to endFrame  collect -1	
	if SceneSizes.count == 0 do SceneSizes = for i = startFrame  to endFrame  collect -1
	if theErrors.count == 0 do theErrors = for i = startFrame  to endFrame collect 0	
	cnt = 0
	theCount = (particleCount theObject)
	for t = startFrame  to endFrame do
	(
		cnt += 1
		Krakatoa_ScanPRT_Main.prg_progressTime.value = 100.0 * cnt / (endFrame - startFrame  + 1)
		case classof theObject of
		(
			default: (
					at time t 
					(
						if theObject.viewPercent == 0 then
							theVal = 0
						else
							theVal = ((for i = 1 to theCount where particlePos theObject i != undefined collect i).count / theObject.viewPercent * 100.0) as integer
					)	
				)
				
			Spray: 
				(
					at time t 
					(
						if theObject.rendercount == 0 then 
							theVal = 0
						else
							theVal = ((for i = 1 to theCount where particlePos theObject i != undefined collect i).count* 1.0*theObject.viewportcount /theObject.rendercount )  as integer
					)		
				)	
			Snow: (
					at time t 
					(
						if theObject.rendercount == 0 then
							theVal = 0
						else
							theVal = ((for i = 1 to theCount where particlePos theObject i != undefined collect i).count* 1.0*theObject.viewportcount /theObject.rendercount )  as integer
							
					)	
				)	
		)	
		append theSizes theVal
		if SceneSizes[theSizes.count] == -1 do SceneSizes[theSizes.count] = 0
		SceneSizes[theSizes.count] += theVal
		if theActualSizes[theSizes.count] == -1 do theActualSizes[theSizes.count] = 0
		theActualSizes[theSizes.count] += theVal
		
	)--end t loop
	Krakatoa_ScanPRT_Main.prg_progressTime.value = 0
	drawBitmap theObject #maxlegacy theSizes "" #(Krakatoa_ScanPRT_Main.clr_total01.color, Krakatoa_ScanPRT_Main.clr_total02.color, Krakatoa_ScanPRT_Main.clr_total03.color)
	theResults 
)

fn scanGeometry theObject =
(
	theResults = #()
	theSizes = #()
	local startFrame = animationrange.start.frame as integer
	local endFrame = animationrange.end.frame as integer
	local totalSizes = for i = startFrame  to endFrame  collect -1
	if theActualSizes.count == 0 do theActualSizes = for i = startFrame  to endFrame  collect -1	
	if SceneSizes.count == 0 do SceneSizes = for i = startFrame  to endFrame  collect -1
	if theErrors.count == 0 do theErrors = for i = startFrame  to endFrame collect 0	
	cnt = 0
	for t = startFrame  to endFrame do
	(
		cnt += 1
		Krakatoa_ScanPRT_Main.prg_progressTime.value = 100.0 * cnt / (endFrame - startFrame  + 1)
		at time t theVal = GetTriMeshFaceCount theObject 
		append theSizes theVal[2]
		if SceneSizes[theSizes.count] == -1 do SceneSizes[theSizes.count] = 0
		SceneSizes[theSizes.count] += theVal[2]
		if theActualSizes[theSizes.count] == -1 do theActualSizes[theSizes.count] = 0
		theActualSizes[theSizes.count] += theVal[2]
		
	)--end t loop
	Krakatoa_ScanPRT_Main.prg_progressTime.value = 0
	drawBitmap undefined #geometry theSizes "" #(Krakatoa_ScanPRT_Main.clr_total01.color, Krakatoa_ScanPRT_Main.clr_total02.color, Krakatoa_ScanPRT_Main.clr_total03.color)
	theResults 
)

fn scanPFlows theSystems =
(
	theResults = #()
	thePflowActualSizes = #()
	thePFlowSizes = for i in theSystems collect #()
	local startFrame = animationrange.start.frame as integer
	local endFrame = animationrange.end.frame as integer
	local totalSizes = for i = startFrame  to endFrame  collect -1
	if theActualSizes.count == 0 do theActualSizes = for i = startFrame  to endFrame  collect -1	
	if SceneSizes.count == 0 do SceneSizes = for i = startFrame  to endFrame  collect -1
	if theErrors.count == 0 do theErrors = for i = startFrame  to endFrame collect 0	
	max create mode
	cnt = 0
	for t = startFrame  to endFrame do
	(
		sliderTime = t
		cnt += 1
		Krakatoa_ScanPRT_Main.prg_progressTime.value = 100.0 * cnt / (endFrame - startFrame +1)
		for i = 1 to theSystems.count do
		(
			o = theSystems[i]
			actualAmount = requestedAmount = (o.numParticles() / o.Quantity_Viewport * o.Quantity_Render) as integer
			if requestedAmount > o.Particle_Amount_Limit do actualAmount = o.Particle_Amount_Limit
			append thePFlowSizes[i] #(actualAmount, requestedAmount)
		)--end o loop
	)--end t loop
	sliderTime = startFrame  
	Krakatoa_ScanPRT_Main.prg_progressTime.value = 0
	for i = 1 to theSystems.count do
	(
		theSizes = #()
		for j in thePFlowSizes[i] do 
		(
			append theSizes j[2]
			append thePflowActualSizes j[1]
			if theActualSizes[theSizes.count] == -1 do theActualSizes[theSizes.count] = 0
			theActualSizes[theSizes.count]  += j[1]
			if SceneSizes[theSizes.count] == -1 do SceneSizes[theSizes.count] = 0
			SceneSizes[theSizes.count]  += j[2]
		)		
		drawBitmap undefined #pflow theSizes "" #(Krakatoa_ScanPRT_Main.clr_total01.color, Krakatoa_ScanPRT_Main.clr_total02.color, Krakatoa_ScanPRT_Main.clr_total03.color)
	)	
	append Krakatoa_PRTScanResults #(theSystems[1], theResults )	
)

fn scanFiles theLoader ScaleMode:0=
(
	theResults = #()
	local filesToScan = for f in theLoader.filelist collect f --where matchPattern (getFileNameType f) pattern:".prt" 
	local cnt = 0
	local startFrame = animationrange.start.frame as integer
	local endFrame = animationrange.end.frame as integer
	local totalSizes = for i = startFrame  to endFrame  collect -1
	if SceneSizes.count == 0 do SceneSizes = for i = startFrame  to endFrame  collect -1
	if theActualSizes.count == 0 do theActualSizes = for i = startFrame  to endFrame  collect -1
	if theErrors.count == 0 do theErrors = for i = startFrame  to endFrame collect 0
	for aFile in filesToScan do
	(
		cnt += 1
		local thePattern = FranticParticles.ReplaceSequenceNumberWithHashes aFile
		local theFS = filterString thePattern "#"
		thePattern = ""
		for i in theFS do thePattern += i + "*"		
--		getFileNamePath aFile + (substring (getFileNameFile aFile) 1 ((getFileNameFile aFile).count-4)) --+ "*" + getFileNameType aFile 
		theSizes = #()
		theFiles = #()
		theTimes = #()
		local theName = aFile
		for t = startFrame  to endFrame do
		(
			theTime = t
			if Krakatoa_ScanPRT_Main.chk_useLoaderTiming.state then
			(
				if not theLoader.loadSingleFrame do
				(
					theTime = t + theLoader.frameOffset 
					if theLoader.enablePlaybackGraph do
					(
						theTime = at time theTime theLoader.playbackGraphTime 
					)
					if theLoader.limitToRange do
					(
						if theTime > theLoader.rangeEndFrame do theTime = theLoader.rangeEndFrame
						if theTime < theLoader.rangeStartFrame do
						(
						 	theTime = theLoader.rangeStartFrame
						 )
					)
					--theName = thePattern + LeadingZeros theTime 4 + theTime as string +  getFileNameType aFile 
					theName = FranticParticles.ReplaceSequenceNumber aFile theTime
				)	
			)
			else
				theName = FranticParticles.ReplaceSequenceNumber aFile theTime
	--			theName = thePattern + LeadingZeros theTime  4 + theTime  as string +  getFileNameType aFile 
			append theFiles theName
				try(theVal = FranticParticles.GetFileParticleCount theName)catch(theVal = undefined )
			case theVal of
			(
				default:
				(
					append theSizes theVal
					if totalSizes[theSizes.count] < 0 do totalSizes[theSizes.count] = 0
					totalSizes[theSizes.count] += theVal
					if SceneSizes[theSizes.count] < 0 do SceneSizes[theSizes.count] = 0
					SceneSizes[theSizes.count] += theVal
					if theActualSizes[theSizes.count] < 0 do theActualSizes[theSizes.count] = 0
					if theLoader.enabledInRender do
						theActualSizes[theSizes.count] += theVal * (at time t theLoader.percentRenderer)/100.0
					theTimes[theSizes.count] = t
				)	
				undefined: --file is missing
				(
					append theSizes -1
					theErrors[theSizes.count] += 1
					theTimes[theSizes.count] = t
					append theMissingFiles theName 
				)
				(-1): -- the file cannot show count (CSV)
				(
					append theSizes -2
					theTimes[theSizes.count] = t
					if SceneSizes[theSizes.count] < 0 do SceneSizes[theSizes.count] = -2
					if totalSizes[theSizes.count] < 0 do totalSizes[theSizes.count] = -2
				)	
			)--end case
		)--end t loop
		if Krakatoa_ScanPRT_Main.chk_showSequenceDetails.checked do
			drawBitmap theLoader #sequence theSizes thePattern #(Krakatoa_ScanPRT_Main.clr_normal01.color, Krakatoa_ScanPRT_Main.clr_normal02.color, Krakatoa_ScanPRT_Main.clr_normal03.color)
	)--end aName
	drawBitmap theLoader #loader totalSizes "" #(Krakatoa_ScanPRT_Main.clr_total01.color, Krakatoa_ScanPRT_Main.clr_total02.color, Krakatoa_ScanPRT_Main.clr_total03.color)
	theResults
)

fn buildScanDialog =
(
	for prt = 1 to Krakatoa_PRTScanResults.count do
	(
		txt = "global Krakatoa_ScanPRT_Dialog_"+ prt as string+" \n"
		local isSceneRoot = false
		try
		(
			theName = Krakatoa_PRTScanResults[prt][1].name
		)
		catch
		(
			isSceneRoot = true
			theName = if Krakatoa_ScanPRT_Main.rad_scanMode.state == 1 then "SCENE TOTALS" else "SELECTED LOADERS" 
		)
		txt += "rollout Krakatoa_ScanPRT_Dialog_"+ prt as string +" \""+ theName +"\" width:450 rolledup:"+ (not isSceneRoot) as string+"(\n"
		local theMap = for i = 1 to Krakatoa_PRTScanResults[prt][2].count collect i
		temp = theMap[1]
		theMap[1] = theMap[theMap.count] 
		theMap[theMap.count] = temp
		for i in theMap do
		(
			if Krakatoa_ScanPRT_Main.chk_includeText.checked do
			(
			txt += "label lbl_name_" + i as string + " \"" + fileNameFromPath Krakatoa_PRTScanResults[prt][2][i][6] + "\" align:#center offset:[0,-3]\n"
		
			txt += "label lbl_min_" + i as string + " \"Frame "+ Krakatoa_PRTScanResults[prt][2][i][12] as string +" - Source Min: " +   Krakatoa_PRTScanResults[prt][2][i][4]   as string + "\" align:#left across:3 offset:[-10,-5]\n"
			txt += "label lbl_max_" + i as string + " \"Frame " + Krakatoa_PRTScanResults[prt][2][i][13] as string + " - Source Max: " + Krakatoa_PRTScanResults[prt][2][i][3]  as string + " (" + (Krakatoa_PRTScanResults[prt][2][i][3] * memoryBytesPerParticle / 1024.0 / 1024.0) as string+" MB)\" align:#center offset:[0,-5]\n"
			txt += "label lbl_average_" + i as string + " \"Source Avg: " + (Krakatoa_PRTScanResults[prt][2][i][5] as integer) as string + "\" align:#right offset:[10,-5]\n"
		
			if Krakatoa_ScanPRT_Main.chk_useLoaderPercentage.checked do			
			(
				txt += "label lbl_rmin_" + i as string + " \"Render Min: " +   Krakatoa_PRTScanResults[prt][2][i][9]   as string + "\" align:#left across:3 offset:[-10,-5]\n"
				txt += "label lbl_rmax_" + i as string + " \"Render Max: " + Krakatoa_PRTScanResults[prt][2][i][10]  as string + " (" + (Krakatoa_PRTScanResults[prt][2][i][10] * memoryBytesPerParticle / 1024.0 / 1024.0) as string+" MB)\" align:#center offset:[0,-5]\n"
				txt += "label lbl_raverage_" + i as string + " \"Render Avg: " + (Krakatoa_PRTScanResults[prt][2][i][11] as integer) as string + "\" align:#right offset:[10,-5]\n"
			)
			)
			
			txt += "bitmap img_results_" + i as string + " width:500 height:"+ Krakatoa_ScanPRT_Main.spn_GraphHeight.value as string +" align:#center bitmap:Krakatoa_PRTScanResults[" + prt as string+"][2][" + i as string + "][1] offset:[0,-4]\n"
			
			if Krakatoa_ScanPRT_Main.chk_includeText.checked do
			(
			txt += "label lbl_framestart_" + i as string + " \"From: " + fileNameFromPath Krakatoa_PRTScanResults[prt][2][i][7] + "\" align:#left across:3 offset:[-10,-8]\n"
			txt += "label lbl_framesrange_" + i as string + " \"Frames: " +Krakatoa_PRTScanResults[prt][2][i][2]as string + "\" align:#center offset:[0,-8]\n"
			txt += "label lbl_frameend_" + i as string + " \"To: " + fileNameFromPath Krakatoa_PRTScanResults[prt][2][i][8] + "\" align:#right offset:[10,-8]\n"
			
			txt += "progressbar prg_limit_" + i as string + " height:3 width:500 align:#center offset:[0,0]\n"
			)
		)
		txt+= "\n)\n"
		execute txt
		theRollout= execute ("Krakatoa_ScanPRT_Dialog_"+ prt as string)
		addRollout theRollout Krakatoa_ScanPRT_Floater 
	)--end prt loop
)

rcmenu Krakatoa_PRTScan_Presets_Menu 
(
	menuitem mnu_savePreset "Save Color Preset..."
	menuitem mnu_loadPreset "Load Color Preset..."
	
	on mnu_savePreset picked do
		Krakatoa_ScanPRT_Main.saveColorPreset()

	on mnu_loadPreset picked do
		Krakatoa_ScanPRT_Main.loadColorPreset()
		
)

rollout Krakatoa_ScanPRT_Main "Analyzer Settings"
(
	checkbutton chk_scanGeometry ">Scan Geometry Vertices" width:240 align:#left checked:false across:2 offset:[0,-3]
	checkbutton chk_scanPFlows ">Scan Particle Flow Systems" width:240 align:#right checked:false offset:[0,-3]
	checkbutton chk_scanMaxSystems ">Scan Max Legacy Particle Systems" width:240 align:#left checked:false across:2  enabled:true offset:[0,-3]
	checkbutton chk_scanTP ">Scan Thinking Particles" width:240 align:#right checked:false enabled:false offset:[0,-3]

	checkbutton chk_showSequenceDetails ">Include Details On Each PRT Sequence" width:240  align:#left across:2 checked:true offset:[0,-3]
	dropdownlist ddl_scaleMode items:#("Fit Vertical Scale To Max. Particle Count","Use Custom Vertical Scale") align:#right width:240 offset:[2,-3]
	
	checkbutton chk_useLoaderPercentage ">Respect Loader's Render Percentage" width:240 across:2 align:#left checked:true offset:[0,-3]
	spinner spn_scaleMode "Custom Vertical Scale (x1000)" range:[1,100000,100] fieldwidth:50 align:#right offset:[0,-1] type:#integer enabled:false
	
	checkbutton chk_useLoaderTiming ">Respect Loader's Timing Settings" width:240  align:#left checked:true across:2 offset:[0,-3]
	spinner spn_memoryLimit "Show Memory Reference Line (MB)" range:[0,100000,1024]  fieldwidth:50 align:#right  offset:[0,-1] type:#integer 
	
	checkbutton chk_includeText ">Include Text Labels In Internal Reports" width:240 align:#left checked:true across:2 offset:[0,-3]
	spinner spn_GraphHeight "Scanner Graph Height In Pixels:" range:[20,500,100]  fieldwidth:50 align:#right  offset:[0,-1] type:#integer 
	
	spinner spn_htmlWidth "HTML Graph Width In Pixels:" range:[500,2000,1000]  fieldwidth:50 offset:[0,-1] type:#integer across:2 --align:#left
	spinner spn_htmlHeight "HTML Graph Height In Pixels:" range:[50,500,200]  fieldwidth:50 align:#right  offset:[0,-1] type:#integer 

	spinner spn_gridSpacing "Minor Line Every N Frames:" range:[1,100000,10]  fieldwidth:50 offset:[0,2] type:#integer  across:2 --align:#right  
	spinner spn_gridSpacingMajor "Major Line Every N Minor Lines:" range:[2,100000,10]  fieldwidth:50 align:#right  offset:[0,2] type:#integer 
	
	label lbl_placeholder02 
	
	colorpicker clr_scene01 "Scene 1:" color:(color 255 200 100) across:3 align:#left offset:[3,0] modal:false height:15
	colorpicker clr_scene02 "2:" color:(color 200 100 100) align:#left offset:[-60,0] modal:false height:15
	colorpicker clr_scene03 "BG:" color:(white*0.85) align:#left offset:[-160,0] modal:false height:15
	
	colorpicker clr_total01 "Loader 1:" color:(color 100 200 100) across:3 align:#left offset:[1,0] modal:false height:15
	colorpicker clr_total02 "2:" color:(color 50 150 50) align:#left offset:[-60,0] modal:false height:15
	colorpicker clr_total03 "BG:" color:(white*0.75) align:#left offset:[-160,0] modal:false height:15
	
	colorpicker clr_Normal01 "Normal 1:" color:(color 100 150 255) across:3 align:#left offset:[1,0] modal:false height:15
	colorpicker clr_Normal02 "2:" color:(color 100 100 200) align:#left offset:[-60,0] modal:false height:15
	colorpicker clr_Normal03 "BG:" color:(white*0.65) align:#left offset:[-160,0] modal:false height:15
	
	colorpicker clr_Missing01 "Missing 1:" color:(color 200 0 0 ) across:3 align:#left offset:[-1,0] modal:false height:15
	colorpicker clr_Missing02 "2:" color:(color 150 0 0 ) align:#left offset:[-60,0] modal:false height:15
	button btn_loadSaveColors "Presets >>" width:63 align:#left offset:[-160,0] height:18

	radiobuttons rad_scanMode labels:#("Whole Scene","Selected Objects") align:#right columns:2 offset:[-10,-97]
	
	checkbutton chk_generateHTML ">HTML Report" width:118 align:#right across:2 offset:[119,0]
	checkbutton chk_generateMissingFilesText ">Missing Files Report" width:118 align:#right offset:[1,0]
	
	button btn_scan "ANALYZE SCENE..." align:#right height:30 width:240
	progressbar prg_progressTime height:6 width:240 color:blue align:#right 
	progressbar prg_progress height:6 width:240 color:red align:#right 
	
	groupbox grp_colors "Graph Colors" width:240 height:105 offset:[-5,-110]
	
	fn saveColorPreset =
	(
		makedir (Krakatoa_PresetsDirectory+ "\\ColorPresets") all:true
		local theFile = getSaveFilename caption:"Select Color Preset Name to Save..." filename:(Krakatoa_PresetsDirectory+ "\\ColorPresets\\Preset.scp") types:"Scanner Color Preset (*.scp)|*.scp"
		if theFile != undefined do
		(
			setIniSetting theFile "ScannerColors" "Scene1" (clr_scene01.color as string)
			setIniSetting theFile "ScannerColors" "Scene2" (clr_scene02.color as string)
			setIniSetting theFile "ScannerColors" "Scene3" (clr_scene03.color as string)

			setIniSetting theFile "ScannerColors" "Total1" (clr_total01.color as string)
			setIniSetting theFile "ScannerColors" "Total2" (clr_total02.color as string)
			setIniSetting theFile "ScannerColors" "Total3" (clr_total03.color as string)

			setIniSetting theFile "ScannerColors" "Normal1" (clr_Normal01.color as string)
			setIniSetting theFile "ScannerColors" "Normal2" (clr_Normal02.color as string)
			setIniSetting theFile "ScannerColors" "Normal3" (clr_Normal03.color as string)

			setIniSetting theFile "ScannerColors" "Missing1" (clr_Missing01.color as string)
			setIniSetting theFile "ScannerColors" "Missing2" (clr_Missing02.color as string)
		)
	)
	
	fn loadColorPreset =
	(
		makedir (Krakatoa_PresetsDirectory+ "\\ColorPresets") all:true
		local theFile = getOpenFilename caption:"Select Color Preset Name to Load..." filename:(Krakatoa_PresetsDirectory+ "\\ColorPresets\\") types:"Scanner Color Preset (*.scp)|*.scp"
		if theFile != undefined do
		(
			try(clr_scene01.color = execute (getIniSetting theFile "ScannerColors" "Scene1" ))catch()
			try(clr_scene02.color = execute (getIniSetting theFile "ScannerColors" "Scene2" ))catch()
			try(clr_scene03.color = execute (getIniSetting theFile "ScannerColors" "Scene3" ))catch()

			try(clr_total01.color = execute (getIniSetting theFile "ScannerColors" "Total1" ))catch()
			try(clr_total02.color = execute (getIniSetting theFile "ScannerColors" "Total2" ))catch()
			try(clr_total03.color = execute (getIniSetting theFile "ScannerColors" "Total3" ))catch()

			try(clr_Normal01.color = execute (getIniSetting theFile "ScannerColors" "Normal1" ))catch()
			try(clr_Normal02.color = execute (getIniSetting theFile "ScannerColors" "Normal2" ))catch()
			try(clr_Normal03.color = execute (getIniSetting theFile "ScannerColors" "Normal3" ))catch()

			try(clr_Missing01.color = execute (getIniSetting theFile "ScannerColors" "Missing1"))catch()
			try(clr_Missing02.color = execute (getIniSetting theFile "ScannerColors" "Missing2" ))catch()
		)	
	)
	
	fn saveSettings =
	(
		makeDir Krakatoa_PresetsDirectory all:true
		local theINI = Krakatoa_PresetsDirectory+ "\\KrakatoaParticleAnalyzer.ini"
		setIniSetting theINI "Settings" "ScanGeometry" (chk_scanGeometry.state as string)
		setIniSetting theINI "Settings" "ScanPFlows" (chk_scanPFlows.state as string)
		setIniSetting theINI "Settings" "ScanMaxSystems" (chk_scanMaxSystems.state as string)
		setIniSetting theINI "Settings" "ScanTP" (chk_scanTP.state as string)

		setIniSetting theINI "Settings" "ShowSequenceDetails" (chk_showSequenceDetails.state as string)
		setIniSetting theINI "Settings" "ScaleMode" (ddl_scaleMode.selection as string)

		setIniSetting theINI "Settings" "UseLoaderPercentage" (chk_useLoaderPercentage.state as string)
		setIniSetting theINI "Settings" "ScaleValue" (spn_scaleMode.value as string)
		
		setIniSetting theINI "Settings" "UseLoaderTiming" (chk_useLoaderTiming.state as string)
		setIniSetting theINI "Settings" "MemoryLimit" (spn_memoryLimit.value as string)
		
		setIniSetting theINI "Settings" "IncludeText" (chk_includeText.state as string)
		setIniSetting theINI "Settings" "GraphHeight" (spn_GraphHeight.value as string)

		setIniSetting theINI "Settings" "HtmlWidth" (spn_htmlWidth.value as string)
		setIniSetting theINI "Settings" "HtmlHeight" (spn_htmlHeight.value as string)

		setIniSetting theINI "Settings" "GridSpacing " (spn_gridSpacing.value as string)
		setIniSetting theINI "Settings" "GridSpacingMajor" (spn_gridSpacingMajor.value as string)

		setIniSetting theINI "Settings" "ScanMode" (rad_scanMode.state as string)

		setIniSetting theINI "Settings" "GenerateHTML" (chk_generateHTML.state as string)
		setIniSetting theINI "Settings" "GenerateMissingFilesText" (chk_generateMissingFilesText.state as string)
		
	)
	
	fn LoadSettings =
	(
		makeDir Krakatoa_PresetsDirectory all:true
		local theINI = Krakatoa_PresetsDirectory+ "\\KrakatoaParticleAnalyzer.ini"
		try(chk_scanGeometry.state = execute (getIniSetting theINI "Settings" "ScanGeometry" ))catch()
		try(chk_scanPFlows.state = execute (getIniSetting theINI "Settings" "ScanPFlows" ))catch()
		try(chk_scanMaxSystems.state = execute (getIniSetting theINI "Settings" "ScanMaxSystems"))catch()
		try(chk_scanTP.state = execute (getIniSetting theINI "Settings" "ScanTP" ))catch()

		try(chk_showSequenceDetails.state = execute (getIniSetting theINI "Settings" "ShowSequenceDetails" ))catch()
		try(ddl_scaleMode.selection = execute (getIniSetting theINI "Settings" "ScaleMode" ))catch()

		try(chk_useLoaderPercentage.state = execute (getIniSetting theINI "Settings" "UseLoaderPercentage" ))catch()
		try(spn_scaleMode.value = execute (getIniSetting theINI "Settings" "ScaleValue"))catch()
		
		try(chk_useLoaderTiming.state = execute (getIniSetting theINI "Settings" "UseLoaderTiming" ))catch()
		try(spn_memoryLimit.value = execute (getIniSetting theINI "Settings" "MemoryLimit" ))catch()
		
		try(chk_includeText.state = execute (getIniSetting theINI "Settings" "IncludeText" ))catch()
		try(spn_GraphHeight.value = execute (getIniSetting theINI "Settings" "GraphHeight"))catch()

		try(spn_htmlWidth.value = execute (getIniSetting theINI "Settings" "HtmlWidth" ))catch()
		try(spn_htmlHeight.value  = execute (getIniSetting theINI "Settings" "HtmlHeight" ))catch()

		try(spn_gridSpacing.value = execute (getIniSetting theINI "Settings" "GridSpacing " ))catch()
		try(spn_gridSpacingMajor.value = execute (getIniSetting theINI "Settings" "GridSpacingMajor" ))catch()
		
		try(rad_scanMode.state = execute (getIniSetting theINI "Settings" "ScanMode" ))catch()

		try(chk_generateHTML.state = execute (getIniSetting theINI "Settings" "GenerateHTML" ))catch()
		try(chk_generateMissingFilesText.state = execute (getIniSetting theINI "Settings" "GenerateMissingFilesText" ))catch()
	)	
	
	on ddl_scaleMode selected itm do spn_scaleMode.enabled = itm == 2
	
	on btn_loadSaveColors pressed do 
	(
		popupMenu Krakatoa_PRTScan_Presets_Menu position:mouse.screenPos
	)

	on btn_loadSaveColors pressed do 
		popupMenu Krakatoa_PRTScan_Presets_Menu position:mouse.screenPos

	on btn_loadSaveColors rightclick do 
		popupMenu Krakatoa_PRTScan_Presets_Menu position:mouse.screenPos


	fn calculateMemoryUsage theChannels =
	(
		local  totalBytes = 0
		for channel in theChannels do 
		(
			local theBytes = 0
			case channel[2] of 
			(
				"float16" : theBytes = 2
				"float32" : theBytes = 4
				"float64" : theBytes = 8
				"int8" : theBytes = 1
				"int16" : theBytes = 2
				"int32" : theBytes = 4
				"int64" : theBytes = 8
				"uint8" : theBytes = 1
				"uint16" : theBytes = 2
				"uint32" : theBytes = 4
				"uint64" : theBytes = 8
				default : ()
			)
			totalBytes += (theBytes * channel[3] )
		)
		totalBytes
	)
	
	fn updateMemChannels = 
	(
		local activeMemChannels = #()
		append activeMemChannels #("Position","float32",3)
		try
		(
			if FranticParticles.getBoolProperty "EnableMotionBlur" then 
				append activeMemChannels #("Velocity", FranticParticles.getProperty "Memory:Channel:Velocity", 3)
			if not (FranticParticles.getBoolProperty "UseGlobalColorOverride" and FranticParticles.getProperty "ParticleColorSource" == "Choose Color") then 
				append activeMemChannels #("Color",FranticParticles.getProperty "Memory:Channel:Color",3)
			append activeMemChannels #("Density",FranticParticles.getProperty "Memory:Channel:Density",1)
			if FranticParticles.getBoolProperty "UseLighting" then 
				append activeMemChannels #("Lighting", FranticParticles.getProperty "Memory:Channel:Lighting", 3)
			if FranticParticles.getBoolProperty "Lighting:Specular:Enabled" and FranticParticles.getBoolProperty "UseLighting" then 
				append activeMemChannels #("Normal", FranticParticles.getProperty "Memory:Channel:Normal", 3)
			MemoryBytesPerParticle = (calculateMemoryUsage activeMemChannels )		
		)
		catch(MemoryBytesPerParticle = 38)	
	)
		
	on btn_scan pressed do
	(
		updateMemChannels()
		SceneSizes = #()
		theActualSizes = #()
		theErrors	= #()
		theMissingFiles = #()
		theBadFiles = #()
		for i in Krakatoa_ScanPRT_Floater.rollouts.count to 2 by -1 do removeRollout Krakatoa_ScanPRT_Floater.rollouts[i] Krakatoa_ScanPRT_Floater
		Krakatoa_PRTScanResults = #()

		KrakatoaParticleSystemsList = #()
		if chk_scanPFlows.checked do
		(
			theSystems = (for o in objects where classof o == PF_Source and not o.isHiddenInVpt collect o)
			if rad_scanMode.state == 2 do theSystems = for o in theSystems where o.isSelected collect o
			if theSystems.count > 0 do 
			(
				join KrakatoaParticleSystemsList theSystems
				select theSystems
				max select invert
				theOldSelection = selection as array
				hide theOldSelection 
				scanPFlows theSystems
				unhide theOldSelection 
			)	
		)	

		local legacyParticles = #(PArray, PCloud, SuperSpray, Blizzard, Snow, Spray)		
		
		if chk_scanMaxSystems.checked do
		(
			theSystems = (for o in objects where findItem legacyParticles (classof o) > 0 and not o.isHiddenInVpt collect o)
			if rad_scanMode.state == 2 do theSystems = for o in theSystems where o.isSelected collect o
			if theSystems.count > 0 do 
			(
				join KrakatoaParticleSystemsList theSystems
				cnt = 0
				for o in theSystems do 
				(
					cnt += 1
					prg_progress.value = 100.0 * cnt / theSystems.count
					results = scanMaxParticles o
					append Krakatoa_PRTScanResults #(o, results)	
				)	
			)	
			prg_progress.value = 0
		)
		
		if chk_scanGeometry.checked do
		(
			local useNamedSelectionSets = try(execute (FranticParticles.GetProperty "Matte:NamedSelectionSets"))catch(#())
			local matteSelSets = for i = 1 to selectionSets.count where findItem useNamedSelectionSets (getNamedSelSetName i) != 0 collect selectionSets[i]
			local matteObjects = #()
			for i in matteSelSets do 
				join matteObjects (for o in i collect o)		
			theSystems = (for o in objects where findItem GeometryClass.classes (classof o) > 0 AND not o.isHiddenInVpt AND classof o != TargetObject AND findItem KrakatoaParticleSystemsList o == 0 AND classof o != ParticleGroup AND o.renderable  AND findItem legacyParticles (classof o) == 0 AND classof o != PF_Source AND findItem matteObjects o == 0 and classof o != KrakatoaPrtLoader collect o)
			if rad_scanMode.state == 2 do theSystems = for o in theSystems where o.isSelected collect o
			cnt = 0
			for o in theSystems do 
			(
				cnt += 1
				prg_progress.value = 100.0 * cnt / theSystems.count
				results = scanGeometry o
				append Krakatoa_PRTScanResults #(o, results)	
			)	
			prg_progress.value = 0
		)	

		thePRTFiles = case rad_scanMode.state of
		(
			1: for o in objects where classof o == KrakatoaPRTLoader AND not o.isHiddenInVpt collect o
			2: for o in selection where classof o == KrakatoaPRTLoader AND not o.isHiddenInVpt collect o
		)
		if thePRTFiles.count > 0 then
		(
			cnt = 0
			for o in thePRTFiles do
			(
				cnt += 1
				prg_progress.value = 100.0 * cnt / thePRTFiles.count
				results = scanFiles o ScaleMode:(if ddl_scaleMode.selection == 1 then 0 else spn_scaleMode.value*1000)
				append Krakatoa_PRTScanResults #(o, results)
			)	
		)
		if Krakatoa_PRTScanResults.count > 0 do
		(	
			result = drawBitmap undefined #scene sceneSizes "" #(clr_scene01.color, clr_scene02.color, clr_scene03.color)
			insertItem  result Krakatoa_PRTScanResults 1
			if chk_generateHTML.checked then 
				generateIndexHTML()
			else	
			(
				buildScanDialog()
				--Krakatoa_ScanPRT_Main.open = false
			)	
		)
--		else	messagebox "No PRT Loaders Selected To Scan.\nPlease select one or more PRT Loaders,\nor select none to scan all PRT Loaders in the scene." title:"Krakatoa PRT Scanner"
		prg_progress.value = 0
		prg_progressTime.value = 0
		/*
		if theBadFiles.count > 0 then 
		(
			theBadFilename = Krakatoa_PresetsDirectory+ "\\PRTscan\\BadFiles\\"  
			makeDir theBadFilename all:true
			theBadFilename += "\\BadFiles_" + getFileNameFile maxFileName+ "_" + underscoreLocalTime localtime +".BadFiles"
			theOutputFile = createFile theBadFilename 
			for i in theBadFiles do format "%\n" i to:theOutputFile 
			close theOutputFile 
			shallLaunch "notepad.exe" theBadFilename 
		)
		*/
		if chk_generateMissingFilesText.checked and theMissingFiles.count > 0 then 
		(
			theMissingFilename= Krakatoa_PresetsDirectory+ "\\PRTscan\\BadFiles\\"  
			makeDir theMissingFilename all:true
			theMissingFilename += "\\MissingFiles_" + getFileNameFile maxFileName+ "_" + underscoreLocalTime localtime +".MissingFiles"
			theOutputFile = createFile theMissingFilename
			for i in theMissingFiles do format "%\n" i to:theOutputFile 
			close theOutputFile 
			shellLaunch "notepad.exe" theMissingFilename
		)
	)--end on
	
	on spn_memoryLimit changed val do
	(
		if Krakatoa_ScanPRT_Floater.rollouts.count > 1 do
		(
			updateMemChannels()
			result = drawBitmap undefined #scene sceneSizes "" #(clr_scene01.color, clr_scene02.color, clr_scene03.color)
			Krakatoa_ScanPRT_Floater.rollouts[2].img_results_1.bitmap = result[2][1][1]
		)	
	)
	
	on Krakatoa_ScanPRT_Main close do saveSettings()
	on Krakatoa_ScanPRT_Main open do loadSettings()
	
)

try(closeRolloutFloater Krakatoa_ScanPRT_Floater )catch()
Krakatoa_ScanPRT_Floater = newRolloutFloater "Krakatoa Particle Analyzer" 520 800
addRollout Krakatoa_ScanPRT_Main Krakatoa_ScanPRT_Floater 

)