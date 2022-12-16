-- Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
-- SPDX-License-Identifier: Apache-2.0
plugin simpleManipulator PRTLoaderManip
    name:"PRTLoaderManip"
    invisible:true
(
    local greenColor =  colorMan.getColor #manipulatorsActive
    local redColor =    colorMan.getColor #manipulatorsSelected
	local yellowColor = colorMan.getColor #manipulatorsInactive
	local currentMode = 0
	
    on canManipulate target return (isProperty target #percentViewport) and (isProperty target #iconSize)
	
	
    on updateGizmos do
    (
		local flags = gizmoDontHitTest
        this.clearGizmos()
		
		--GIZMO 0
        local giz = manip.makeGizmoShape()
		local thePos = [target.iconSize*1.2, (target.percentViewport*0.02*target.iconSize)-target.iconSize,0]
		giz.addPoint thePos 
		giz.addPoint (thePos + [1,0.7,0]*target.iconSize*0.1)
		giz.addPoint (thePos + [1,-0.7,0]*target.iconSize*0.1)
		giz.addPoint thePos 
        this.addGizmoShape giz 0 greenColor redColor  
		
		--GIZMO 1
		this.addGizmoMarker #hollowBox [target.IconSize*1.15,-target.IconSize*0.95,0] 0 greenColor redColor  
		
		
		--GIZMO 2
		giz = manip.makeGizmoShape()
		giz.addPoint [target.iconSize*1.2, -target.iconSize*1.0,0]
		giz.addPoint [target.iconSize*1.2, target.iconSize*1.0,0]
		this.addGizmoShape giz flags greenColor greenColor 
		
		--GIZMO 3
        local giz = manip.makeGizmoShape()
		local thePos = [target.iconSize*1.2, (target.percentRenderer*0.02*target.iconSize)-target.iconSize,0]
		giz.addPoint thePos 
		giz.addPoint (thePos + [-1,0.7,0]*target.iconSize*0.1)
		giz.addPoint (thePos + [-1,-0.7,0]*target.iconSize*0.1)
		giz.addPoint thePos 
        this.addGizmoShape giz 0 greenColor redColor  
		
        case currentMode of
		(
			1: "IconSize: " + target.iconSize as string 
			0: "View %:" + target.percentViewport as string 
			3: "Render %:" + target.percentRenderer as string 
			default: ""
		)	
    )

    on mouseMove m which do
    (
		currentMode = which
        local pl = manip.makePlaneFromNormal z_axis [0, 0, 0],
        projectedPoint = [0,0,0]
        viewRay = this.getLocalViewRay m
        res = pl.intersect viewRay &projectedPoint
        if res then
		(
			case which of
			(
				0:
				(
					target.percentViewport = 50.0 * ((projectedPoint.y + target.iconSize) / target.iconSize )
					if target.percentViewport > 100 do target.percentViewport = 100
					if target.percentViewport < 0 do target.percentViewport = 0
					if not keyboard.SHIFTPressed  do target.percentViewport = (floor (target.percentViewport / 10.0+ 0.5) ) * 10.0
				)
				1: 
				(
					target.iconSize = (length projectedPoint)*0.68
				)
				3:
				(
					target.percentRenderer = 50.0 * ((projectedPoint.y + target.iconSize) / target.iconSize )
					if target.percentRenderer > 100 do target.percentRenderer = 100
					if target.percentRenderer < 0 do target.percentRenderer = 0
					if not keyboard.SHIFTPressed do target.percentRenderer = (floor (target.percentRenderer / 10.0+ 0.5) ) * 10.0
				)				
				default: ()
			)--end case
		)--end if	
    )--end on
)


plugin simpleManipulator KrakatoaCameraModManip
    name:"KrakatoaCameraModManip"
    invisible:true
(
    local greenColor =  colorMan.getColor #manipulatorsActive
    local redColor =    colorMan.getColor #manipulatorsSelected
	local yellowColor = colorMan.getColor #manipulatorsInactive
	local cyanColor = Point3 0.5 0.7 1.0
	local targetDist = 100.0
	
    on canManipulate target return (isProperty target #useCameraType) and (isProperty target #fov)
	
	
    on updateGizmos do
    (
		local flags = gizmoDontHitTest
        this.clearGizmos()
		targetDist = target.focalDepth
			
		local circleX = targetDist * cos (target.FOV/2.0-90)
		local circleY = targetDist * sin (target.FOV/2.0-90)
		local Ycorner = circleX/GetRendImageAspect()
		
		--GIZMO 0 and 1
		this.addGizmoMarker #hollowBox [circleX, 0, circleY] 0 greenColor redColor  
		this.addGizmoMarker #hollowBox [-circleX, 0, circleY] 0 greenColor redColor  
		
		--GIZMO 2
		this.addGizmoMarker #bigBox [0, 0, -targetDist] 0 greenColor redColor  
		
		--OTHER GIZMOS
		local giz = manip.makeCircle [0,0,0] targetDist 64
		giz.transform (rotateXmatrix 90)
		this.addGizmoShape giz flags yellowColor greenColor 
		
		if target.useCameraType == true and target.cameraType == 2 then
		(
			local giz = manip.makeGizmoShape()
			giz.AddPoint [circleX, Ycorner,circleY]
			giz.AddPoint [-circleX,Ycorner,circleY]
			giz.AddPoint [-circleX,-Ycorner,circleY]
			giz.AddPoint [circleX,-Ycorner,circleY]
			giz.AddPoint [circleX,Ycorner,circleY]
			
			giz.AddPoint [circleX,Ycorner,0]
			giz.AddPoint [circleX,-Ycorner,0]
			giz.AddPoint [-circleX,-Ycorner,0]
			giz.AddPoint [-circleX,Ycorner,0]
			giz.AddPoint [circleX,Ycorner,0]
			
			giz.startNewLine()
			giz.AddPoint [-circleX,Ycorner,0]
			giz.AddPoint [-circleX,Ycorner,circleY]

			giz.startNewLine()
			giz.AddPoint [-circleX,-Ycorner,0]
			giz.AddPoint [-circleX,-Ycorner,circleY]
			
			giz.startNewLine()
			giz.AddPoint [circleX,-Ycorner,0]
			giz.AddPoint [circleX,-Ycorner,circleY]
			this.addGizmoShape giz flags cyanColor cyanColor  
		)
		else if target.useCameraType == true and target.cameraType == 3 then
		(
			local theColor = if circleY > 0 then yellowColor else cyanColor
			
			local giz = manip.makeCircle [0,0,0] targetDist 64
			this.addGizmoShape giz flags theColor theColor  

			giz.transform (rotateYmatrix 90)
			this.addGizmoShape giz flags theColor theColor  
			
			local giz = manip.makeGizmoShape()
			giz.AddPoint [-circleX,0,circleY]			
			giz.AddPoint [0,0,0]
			giz.AddPoint [circleX,0,circleY]		
			giz.startNewLine()
			giz.AddPoint [0,-circleX,circleY]			
			giz.AddPoint [0,0,0]
			giz.AddPoint [0,circleX,circleY]				
			this.addGizmoShape giz flags cyanColor cyanColor  			
			
			local giz = manip.makeCircle [0,0,circleY] -circleX 64
			this.addGizmoShape giz flags cyanColor cyanColor  
		)
		else
		(
			local giz = manip.makeGizmoShape()
			giz.AddPoint [circleX, Ycorner,circleY]
			giz.AddPoint [-circleX,Ycorner,circleY]
			giz.AddPoint [-circleX,-Ycorner,circleY]
			giz.AddPoint [circleX,-Ycorner,circleY]
			giz.AddPoint [circleX,Ycorner,circleY]
			
			giz.AddPoint [0,0,0]
			giz.AddPoint [-circleX,Ycorner,circleY]
			giz.startNewLine()
			giz.AddPoint [0,0,0]
			giz.AddPoint [-circleX,-Ycorner,circleY]
			giz.startNewLine()
			giz.AddPoint [0,0,0]
			giz.AddPoint [circleX,-Ycorner,circleY]
			
			giz.startNewLine()
			giz.AddPoint [0,0,0]
			giz.AddPoint [circleX,0,circleY]
			giz.startNewLine()
			giz.AddPoint [0,0,0]
			giz.AddPoint [-circleX,0,circleY]
			
			this.addGizmoShape giz flags cyanColor cyanColor  
		)
		
		if circleY > 0 and (target.cameraType != 3 or target.useCameraType == false) do
		(
			local giz = manip.makeGizmoShape()
			giz.startNewLine()
			giz.AddPoint [-circleX,Ycorner,circleY]
			giz.AddPoint [-circleX,Ycorner,-targetDist]
			giz.AddPoint [-circleX,-Ycorner,-targetDist]			
			giz.AddPoint [-circleX,-Ycorner,circleY]
			
			giz.startNewLine()
			giz.AddPoint [circleX,Ycorner,circleY]
			giz.AddPoint [circleX,Ycorner,-targetDist]
			giz.AddPoint [circleX,-Ycorner,-targetDist]			
			giz.AddPoint [circleX,-Ycorner,circleY]		

			giz.startNewLine()	
			if target.cameraType != 2 do giz.AddPoint [0,0,0]
			giz.AddPoint [-circleX,Ycorner,-targetDist]		
			giz.AddPoint [circleX,Ycorner,-targetDist]			
			
			giz.startNewLine()	
			if target.cameraType != 2 do giz.AddPoint [0,0,0]
			giz.AddPoint [-circleX,-Ycorner,-targetDist]		
			giz.AddPoint [circleX,-Ycorner,-targetDist]			
			
			if target.cameraType != 2 do
			(
				giz.startNewLine()	
				giz.AddPoint [circleX,-Ycorner,-targetDist]		
				giz.AddPoint [0,0,0]
				giz.AddPoint [circleX,Ycorner,-targetDist]			
			)

			this.addGizmoShape giz flags yellowColor yellowColor  
		)
		local typeString = "3dsMax "
		if target.useCameraType == true do
		(
			typeString = case target.CameraType of
			(
				1: "Perspective "
				2: "Ortho "
				3: "Spherical "
			)
		)
		this.addGizmoText (typeString  + "Camera\n" + (if target.useFov then "Override FOV: " else "FOV: ") + target.fov as string + " deg.\n"  + (if target.focalDepthOn then "Override Focal Depth: " else "Focal Depth:: ") + target.focalDepth as string )  [0,0,-targetDist*1.05] gizmoActiveViewportOnly yellowColor yellowColor
        
		undefined
    )

    on mouseMove m which do
    (
        local pl1 = manip.makePlaneFromNormal y_axis [0, 0, 0]
        local pl2 = manip.makePlaneFromNormal x_axis [0, 0, 0]
		
        local projectedPoint1 = [0,0,0]
        local projectedPoint2 = [0,0,0]
		
        local viewRay = this.getLocalViewRay m
		local pl3 = pl2.mostOrthogonal viewRay pl1
		
        local res1 = pl1.intersect viewRay &projectedPoint1
        local res2 = pl3.intersect viewRay &projectedPoint2
		
        if res1 then
		(
			case which of
			(
				0: (
						local val = (2 * atan (projectedPoint1.z / projectedPoint1.x)  )
						if projectedPoint1.x > 0 then 
						(
							if projectedPoint1.z < 0 then
								val = 180 - abs val 
							else 
								val = 180 + val 
							if val < 0 do val = 0
						)
						else val = 0
						target.fov = val 
					)
				1: (
						local val = (2 * atan (projectedPoint1.z / projectedPoint1.x)  )
						if projectedPoint1.x < 0 then 
						(
							if projectedPoint1.z < 0 then
								val = 180 - abs val 
							else 
								val = 180 - val 
							if val < 0 do val = 0
						)
						else val = 0
						target.fov = val 
					)					
				2: ()
			)--end case
		)--end if	
        if res2 then
		(
			case which of
			(
				2: (
					local val = (-projectedPoint2.z)
					if val < 0.001 do val = 0.001
					target.focalDepth = val
				)				
			)--end case
		)--end if		
		
    )--end on
)