-- Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
-- SPDX-License-Identifier: Apache-2.0
macroScript MeshSurfToPRT category:"Krakatoa Particle Stream"
(
	on isEnabled return selection.count == 1 and findItem GeometryClass.classes (classof $) > 0 and classof $ != TargetObject and $.classid as string != "#(1186461122, 1294604214)"
	on execute do
	(
		local theFile = getSaveFileName filename:($.name+"_Surf_0000") types:"Frantic Films Particle File (*.PRT)|*.prt" --|Comma Separated Values File (*.CSV)|*.csv
		if theFile != undefined do
		(
			local theMesh = snapshotasMesh $
			--local theStream =  KrakatoaParticleOStream theFile #("Position float32[3]", "Color float16[3]", "Density float16", "Normal float16[3]", "TextureCoord float16[3]")
			local theStream =  FranticParticles.CreateParticleOStream theFile #("Position float32[3]", "Color float16[3]", "Density float16", "Normal float16[3]", "TextureCoord float16[3]")
			local theColor = ($.wirecolor/255) as Point3
			
			seed 12345
			for f = 1 to theMesh.numfaces do
			(
				local theFace = getFace theMesh f
				local theMapFace = meshop.getMapFace theMesh 1 f
				local theNormal = getFaceNormal theMesh f
				local theFactor = (meshop.getFaceArea theMesh f) as integer
				for i = 1 to theFactor do
				(
					local theX = random 0.0 1.0
					local theY = random 0.0 1.0
					if theX+theY > 1.0 do 
					(
						theX = 1.0 - theX
						theY = 1.0 - theY						
					)
					local theZ = 1.0 - theX - theY
					local thePos = (getVert theMesh theFace.x)*theX + (getVert theMesh theFace.y)*theY + (getVert theMesh theFace.z)*theZ
					local theTCoords = (meshop.getMapVert theMesh 1 theMapFace.x)*theX + (meshop.getMapVert theMesh 1 theMapFace.y)*theY + (meshop.getMapVert theMesh 1 theMapFace.z)*theZ
					theStream.writeParticle #(thePos, theColor, 1.0, theNormal, theTCoords)
				)
			)
			theStream.close()
			delete theMesh
			local newPRTLoader = KrakatoaPRTLoader()
			newPRTLoader.fileList = #(theFile)
			newPRTLoader.fileListFlags = #(3)
			newPRTLoader.percentViewport = 100
			newPRTLoader.viewportParticleDisplayMode = 4
			newPRTLoader.ParticleColorSource = 3
			newPRTLoader.material = $.material
			select newPRTLoader
		)	
	)
)

macroScript HairPRT category:"Krakatoa Particle Stream"
(
	on isEnabled return selection.count == 1 and findItem GeometryClass.classes (classof $) > 0 and classof $ != TargetObject and $.classid as string != "#(1186461122, 1294604214)"
	on execute do
	(
		local theFile = getSaveFileName filename:($.name+"_Hair_0000") types:"Thinkbox Particle File (*.PRT)|*.prt" --|Comma Separated Values File (*.CSV)|*.csv
		if theFile != undefined do
		(
			local theMesh = snapshotasMesh $
			--local theStream =  KrakatoaParticleOStream theFile #("Position float32[3]", "Color float16[3]", "Density float16", "Normal float16[3]", "TextureCoord float16[3]")
			local theStream =  FranticParticles.CreateParticleOStream theFile #("Position float32[3]", "Color float16[3]", "Density float16", "Normal float16[3]", "TextureCoord float16[3]")
			local theColor = ($.wirecolor/255) as Point3
			local Divergence = 0.0
			local minLength = 40
			local maxLength = 60
			local densityFactor = 1.0
			seed 12345
			for f = 1 to theMesh.numfaces do
			(
				local theFace = getFace theMesh f
				local theMapFace = meshop.getMapFace theMesh 1 f
				local theNormal = getFaceNormal theMesh f
				
				local theFactor = ((meshop.getFaceArea theMesh f)*densityFactor) as integer
				if theFactor == 0 do theFactor = 1
				for i = 1 to theFactor do
				(
					theNormalD = theNormal * rotateXMatrix (random -Divergence Divergence)
					theNormalD = theNormalD * rotateYMatrix (random -Divergence Divergence)					
					local theX = random 0.0 1.0
					local theY = random 0.0 1.0
					if theX+theY > 1.0 do 
					(
						theX = 1.0 - theX
						theY = 1.0 - theY						
					)
					local theZ = 1.0 - theX - theY
					local theBend = 0.0
					local theTCoords = (meshop.getMapVert theMesh 1 theMapFace.x)*theX + (meshop.getMapVert theMesh 1 theMapFace.y)*theY + (meshop.getMapVert theMesh 1 theMapFace.z)*theZ
					local theHairLength = (random minLength maxLength)*theFactor*0.1
					local theNormal = ((getNormal theMesh theFace.x)*theX + (getNormal theMesh theFace.y)*theY + (getNormal theMesh theFace.z)*theZ)
					local thePos = ((getVert theMesh theFace.x)*theX + (getVert theMesh theFace.y)*theY + (getVert theMesh theFace.z)*theZ)
					for j = 1 to theHairLength do
					(
						thePos += (theNormalD*0.1 - [0,0,theBend])
						theBend += 0.005
						theDens = 1.0 - 1.0*j/theHairLength
						theStream.writeParticle #(thePos, theColor, theDens, theNormalD, theTCoords)
					)	
				)
			)
			theStream.close()
			delete theMesh
			local newPRTLoader = KrakatoaPRTLoader()
			newPRTLoader.fileList = #(theFile)
			newPRTLoader.fileListFlags = #(3)
			newPRTLoader.percentViewport = 100
			newPRTLoader.viewportParticleDisplayMode = 2
			newPRTLoader.ParticleColorSource = 3
			newPRTLoader.material = $.material
			newPRTLoader.wirecolor = $.wirecolor
			select newPRTLoader
		)	
	)
)

macroScript HairAndFur2PRT category:"Krakatoa Particle Stream"
(
	on isEnabled return selection.count == 1 and (for m in $.modifiers where classof m == HairMod collect m).count > 0
	on execute do
	(
		local theFile = getSaveFileName filename:($.name+"_HairAndFur_") types:"Thinkbox Particle File (*.PRT)|*.prt" --|Comma Separated Values File (*.CSV)|*.csv
		if theFile != undefined do
		(
			progressStart "Saving Hair and Fur..."
			local startTime = animationrange.start.frame
			local endTime = animationrange.end.frame 
			if not (querybox "Save Current Animation Segment?") do 
				startTime = endTime = currentTime.frame
			for t = startTime to endTime do
			(
				sliderTime = t
				local theFrameFile = FranticParticles.ReplaceSequenceNumber theFile t
				local theShape = $.modifiers[1].hair.ConvertHairsToSplines instance:$
	--			local theMesh = snapshotasmesh $
				--local theStream =  KrakatoaParticleOStream theFrameFile #("Position float32[3]", "Color float16[3]", "Density float16", "Normal float16[3]", "Tangent float16[3]") --, "TextureCoord float16[3]")
				local theStream =  FranticParticles.CreateParticleOStream theFrameFile #("Position float32[3]", "Color float16[3]", "Density float16", "Normal float16[3]", "Tangent float16[3]") --, "TextureCoord float16[3]")
				local theColor = ($.wirecolor/255) as Point3
				
				for s = 1 to numSplines theShape do
				(
					theSplineLength = getSegLengths theShape s
					theSplineLengthValue = theSplineLength[theSplineLength.count]
					theSteps = 0.2/theSplineLengthValue
					--print theSteps 
					for i = 0 to 1.0 by theSteps do
					(
						thePos = interpCurve3D theShape s i pathParam:false
						theTangent = tangentCurve3D theShape s i pathParam:false
						theUpVector = [0,0,1]
						theNormal = normalize (cross (cross theTangent theUpVector) theTangent)
						theDens = 1.0 - i
						theStream.writeParticle #(thePos, theColor, theDens, theNormal, theTangent  )					
					)
				)
				theStream.close()
				delete theShape
				if not (progressUpdate (100.0*t/(endTime-startTime))) do exit
			)	
			progressEnd()
			--delete theMesh
			local newPRTLoader = KrakatoaPRTLoader name:(uniquename "PRT_Loader_HairAndFur_")
			newPRTLoader.fileList = #(FranticParticles.ReplaceSequenceNumber theFile animationrange.start.frame)
			newPRTLoader.fileListFlags = #(3)
			newPRTLoader.percentViewport = 100
			newPRTLoader.viewportParticleDisplayMode = 2
			newPRTLoader.ParticleColorSource = 3
			newPRTLoader.material = $.material
			newPRTLoader.wirecolor = $.wirecolor
			select newPRTLoader
		)	
	)
)

macroScript Spline2PRTAdaptive category:"Krakatoa Particle Stream" 
(
	on isEnabled return selection.count == 1 and classof $ == SplineShape 

	local screenSize = getViewSize()
	local renderSize = [renderWidth,RenderHeight]
	
	fn getScreenPos thePoint = 
	(
		gw.setTransform (Matrix3 1)
		local p3TargetScreenPos = gw.transPoint thePoint
		([p3TargetScreenPos.x,p3TargetScreenPos.y]/screenSize) * renderSize
	)
	
	on execute do
	(
		screenSize = getViewSize()
		renderSize = [renderWidth,RenderHeight]
		local theFile = getSaveFileName filename:($.name+"_HairAdaptive_") types:"Thinkbox Particle File (*.PRT)|*.prt" --|Comma Separated Values File (*.CSV)|*.csv
		if theFile != undefined do
		(
			progressStart "Saving Spline To PRT..."
			local startTime = animationrange.start.frame
			local endTime = animationrange.end.frame 
			if not (querybox "Save Current Animation Segment?") do 
				startTime = endTime = currentTime.frame
			for t = startTime to endTime do
			(
				sliderTime = t
				local theFrameFile = FranticParticles.ReplaceSequenceNumber theFile t
				local theShape = $
				--local theStream =  KrakatoaParticleOStream theFrameFile #("Position float32[3]", "Color float16[3]", "Density float16", "Normal float16[3]", "Tangent float16[3]") --, "TextureCoord float16[3]")
				local theStream =  FranticParticles.CreateParticleOStream theFrameFile #("Position float32[3]", "Color float16[3]", "Density float16", "Normal float16[3]", "Tangent float16[3]") --, "TextureCoord float16[3]")
				local theColor = ($.wirecolor/255) as Point3
				
				for s = 1 to numSplines theShape do
				(
					theStep = 0.05
					lastPosition = getScreenPos (interpCurve3D theShape s 0.0 pathParam:false)
					maxDist = 0.0
					for i = 0.0 to 1.0 by theStep do
					(
						newPosition = getScreenPos (interpCurve3D theShape s i pathParam:false)
						theDist = distance lastPosition newPosition
						if theDist > maxDist do maxDist = theDist
						lastPosition = newPosition
					)
					--format "Old Distance %=%\n" s maxDist
					theStep *= (0.5/maxDist) --0.5 is the pixel coverage we want.
					--format "New Step %=%\n" s theStep
						
					for i = 0.0 to 1.0 by theStep do
					(
						thePos = interpCurve3D theShape s i pathParam:false
						theTangent = tangentCurve3D theShape s i pathParam:false
						theUpVector = [0,0,1]
						theNormal = normalize (cross (cross theTangent theUpVector) theTangent)
						theDens = (1.0 - i)*theStep*100
						theStream.writeParticle #(thePos, theColor, theDens, theNormal, theTangent  )					
					)
				)
				theStream.close()
				if not (progressUpdate (100.0*t/(endTime-startTime))) do exit
			)	
			progressEnd()
			local newPRTLoader = KrakatoaPRTLoader name:(uniquename "PRT_Loader_Spline2Hair_")
			newPRTLoader.fileList = #(FranticParticles.ReplaceSequenceNumber theFile animationrange.start.frame)
			newPRTLoader.fileListFlags = #(3)
			newPRTLoader.percentViewport = 100
			newPRTLoader.viewportParticleDisplayMode = 2
			newPRTLoader.ParticleColorSource = 3
			newPRTLoader.material = $.material
			newPRTLoader.wirecolor = $.wirecolor
			select newPRTLoader
		)	
	)
)





