-- Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
-- SPDX-License-Identifier: Apache-2.0
plugin simpleManipulator KrakatoaShadowRangeManip
name:"KRAShadowRangeManip"
invisible:true
(
    local activeColor =  [1,0.8,0.6] --colorMan.getColor #manipulatorsActive
    local selectedColor =  colorMan.getColor #manipulatorsSelected
	local t_dist, spot_falloff, theAspect
	
    on canManipulate target return (superclassof target == Light and (isProperty target #shadowGenerator  AND classof target.shadowGenerator == Krakatoa_Shadows))

    on updateGizmos do
    (
        this.clearGizmos()
        if (classof target.shadowGenerator == Krakatoa_Shadows) do
		(
			local isKindOfOmni = classof target == OmniLight or classof target == miAreaLightomni
			local isKindOfDirect = classof target == Directionallight or classof target == TargetDirectionallight
			if isKindOfOmni then 
			(
				if isProperty target.ShadowGenerator #ShadowManipulatorDistance then
					t_dist = target.ShadowGenerator.ShadowManipulatorDistance 
				else
					t_dist = target.decayRadius
				spot_falloff = 45.0
				theAspect = 1.0
			)
			else
			(
				t_dist = target.ShadowGenerator.ShadowManipulatorDistance 
				spot_falloff = target.falloff/2
				try(theAspect = target.aspect)catch(theAspect=1.0)
			)
			this.addGizmoMarker #smallCircle [0,0,(-t_dist)] 0 activeColor selectedColor  
			this.addGizmoMarker #circle [0,0,(-t_dist-target.shadowGenerator.ShadowSampleSpacing)] 0 [0,1,0] selectedColor  
			this.addGizmoMarker #plusSign [0,10,(-t_dist)] 0 [0,1,0] selectedColor  
			this.addGizmoMarker #xMarker [0,-10,(-t_dist)] 0 [1,0,0] selectedColor  
			
			local exponentialMode = try(target.ShadowGenerator.ShadowSampleSpacingIsExponential)catch(false)
			local offset = 0 
			local offsetSum = 0
			if not isKindOfOmni and (isProperty target #coneShape and target.coneShape != 2) then  --spot and direct lights with cone shape 
			(
				if isKindOfDirect then
					giz = manip.makeCircle [0,0,(-t_dist)] (spot_falloff*2) 48
				else
					giz = manip.makeCircle [0,0,(-t_dist)] (t_dist * tan(spot_falloff)) 48
				this.addGizmoShape giz gizmoDontHitTest activeColor selectedColor  
				
				for i = 1 to target.shadowGenerator.ShadowSampleCount do
				(
					offset = if exponentialMode then
						target.shadowGenerator.ShadowSampleSpacing * (2^i-1)
					else
						target.shadowGenerator.ShadowSampleSpacing * i
					if isKindOfDirect then
						giz = manip.makeCircle [0,0,(-t_dist-offset)] (spot_falloff*2) 48
					else
						giz = manip.makeCircle [0,0,(-t_dist-offset)] ((t_dist+offset) * tan(spot_falloff)) 48
					local blendValue = 1.0*i/target.shadowGenerator.ShadowSampleCount
					this.addGizmoShape giz gizmoDontHitTest (activeColor*(1.0-blendValue)+[1,0,0]*(blendValue)) selectedColor  
					this.addGizmoText (i as string + ": "+units.formatValue offset) [0,0,(-t_dist-offset)] 0 (if i == target.shadowGenerator.ShadowSampleCount then [0,1,0] else [1,1,0]) [1,1,0]
				)
			)
			else 
			(
				if isKindOfOmni then  --omnis
				(
					giz = manip.makeCircle [0,0,0] t_dist 48
					this.addGizmoShape giz gizmoDontHitTest activeColor selectedColor 
					giz.transform (rotateYMatrix 90)
					this.addGizmoShape giz gizmoDontHitTest activeColor selectedColor 
					giz.transform (rotateZMatrix 90)
					this.addGizmoShape giz gizmoDontHitTest activeColor selectedColor 
					
					for i = 1 to target.shadowGenerator.ShadowSampleCount do
					(
						offset = if exponentialMode then
							target.shadowGenerator.ShadowSampleSpacing * (2^i-1)
						else
							target.shadowGenerator.ShadowSampleSpacing * i
						giz = manip.makeCircle [0,0,0] (t_dist+offset) 48
						local blendValue = 1.0*i/target.shadowGenerator.ShadowSampleCount
						local theColor = (activeColor*(1.0-blendValue)+[1,0,0]*(blendValue))
						this.addGizmoShape giz gizmoDontHitTest theColor selectedColor  
						giz.transform (rotateYMatrix 90)
						this.addGizmoShape giz gizmoDontHitTest theColor selectedColor 
						giz.transform (rotateZMatrix 90)
						this.addGizmoShape giz gizmoDontHitTest theColor selectedColor 							
						this.addGizmoText (i as string + ": "+units.formatValue offset) [0,0,(-t_dist-offset)] 0 (if i == target.shadowGenerator.ShadowSampleCount then [0,1,0] else [1,1,0]) [1,1,0]
					)
				)
				else --all other lights
				(
					giz = manip.makeGizmoShape()
					local x = (t_dist+offset) * tan spot_falloff
					if isKindOfDirect do x = spot_falloff*2
					local y = x/theAspect
					giz.AddPoint [-x ,-y, -t_dist]
					giz.AddPoint [x ,-y, -t_dist]
					giz.AddPoint [x ,y, -t_dist]
					giz.AddPoint [-x ,y, -t_dist]
					giz.AddPoint [-x ,-y, -t_dist]
					this.addGizmoShape giz gizmoDontHitTest activeColor selectedColor 
					
					for i = 1 to target.shadowGenerator.ShadowSampleCount do
					(
						offset = if exponentialMode then
							(target.shadowGenerator.ShadowSampleSpacing * (2^i-1))
						else
							target.shadowGenerator.ShadowSampleSpacing * i

						giz = manip.makeGizmoShape()
						local blendValue = 1.0*i/target.shadowGenerator.ShadowSampleCount
						local x = (t_dist+offset) * tan spot_falloff
						if isKindOfDirect do x = spot_falloff*2
						local y = x/theAspect
						giz.AddPoint [-x ,-y, -t_dist-offset]
						giz.AddPoint [x ,-y, -t_dist-offset]
						giz.AddPoint [x ,y, -t_dist-offset]
						giz.AddPoint [-x ,y, -t_dist-offset]
						giz.AddPoint [-x ,-y, -t_dist-offset]
						local theColor = (activeColor*(1.0-blendValue)+[1,0,0]*(blendValue))
						this.addGizmoShape giz gizmoDontHitTest theColor selectedColor  
						this.addGizmoText (i as string + ": "+units.formatValue offset ) [0,0,(-t_dist-offset)] 0 (if i == target.shadowGenerator.ShadowSampleCount then [0,1,0] else [1,1,0]) [1,1,0]
					)
				)
			)
			return node.name +" Start:"+ t_dist as string +"  Sample Spacing:" + units.formatValue target.shadowGenerator.ShadowSampleSpacing + "  Samples:" +target.ShadowGenerator.ShadowSampleCount as string+ "  Shadow Range:"+ units.formatValue offset 
		)
    )--end on 
	
	on mouseDown m which do
	(
		if which == 2 do target.ShadowGenerator.ShadowSampleCount += 1
		if which == 3 and target.ShadowGenerator.ShadowSampleCount > 1 do target.ShadowGenerator.ShadowSampleCount -= 1
	)

    on mouseMove m which do
    (
		if which < 2 do
		(
			local plane1 = manip.makePlaneFromNormal x_axis [0, 0, (-t_dist)]
			local plane2 = manip.makePlaneFromNormal y_axis [0, 0, (-t_dist)]
			local projectedPoint = [0,0,(-t_dist)]
			viewRay = this.getLocalViewRay m
			local pl = plane1.mostOrthogonal viewRay plane2
			res = pl.intersect viewRay &projectedPoint
			if res do
			(
				case which of
				(
					0: (
							target.ShadowGenerator.ShadowManipulatorDistance = length projectedPoint
							--try(target.decayRadius = length projectedPoint)catch()
						)
					1: 
						(
							local theVal = (length projectedPoint - t_dist)
							if theVal > 0.001 do 
							target.shadowGenerator.ShadowSampleSpacing = theVal
						)
				)
			)
		)
    )
)