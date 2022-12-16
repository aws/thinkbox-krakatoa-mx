-- Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
-- SPDX-License-Identifier: Apache-2.0
(
	global du = DeadlineUtil  --this is the interface exposed by the Lightning Plug-in which provides communication between Deadline and 3ds Max
	if du == undefined do  --if the script is not being run on Deadline (for testing purposes),
	(
		struct DeadlineUtilStruct   --define a stand-in struct with the same methods as the Lightning plug-in
		(
			fn SetTitle title = ( format "Title: %\n" title ),
			fn SetProgress percent = (true),
			fn FailRender msg = ( throw msg ),
			fn GetJobInfoEntry key = ( undefined ),
			fn GetAuxFilename index = ( undefined ),
			fn LogMessage msg = ( format "%\n" msg ),
			CurrentFrame = ((sliderTime as string) as integer)
		)
		du = DeadlineUtilStruct() --create an instance of the stand-in struct
	)--end if
	
	fn LeadingZeros value count =
	(
		theStr = value as string
		substring "00000000000" 1 (count-(theStr.count))
	)
	
	global st = 0
	global st1 = 0
	global framesSoFar = 0
	global lastFrameTime = 0
	global timeSoFar = 0
	global eta = 0
	global partitionNumber = 0
	global deleteExistingFiles = #prompt
	global ETAstartTime = 0
	global totalNumberOfFrames  = 0
	global cnt = 0
	global theTotalCount = 0
	global partitionFilename = ""
	global theBackupPath = ""
	
	global getFilenameFromBackupRoot
	
	global theBackupVal 
	theBackupVal = execute (FranticParticles.GetProperty "Partition:BackupRootMode")
	if theBackupVal == OK do theBackupVal = 1
	
	global preRenderFrameFunction, postRenderFrameFunction
	
	global Krakatoa_SeedIncrement_UserFunction
	
	local incrementPositionRandomSeeds 
	local incrementSpawnRandomSeeds 
	local incrementSpeedRandomSeeds 
	local incrementFumeFXRandomSeeds 
	local incrementRotationRandomSeeds 
	local incrementOtherRandomSeeds 
	local incrementLegacyRandomSeeds 
	local incrementThinkingRandomSeeds 
	
	local IncrementBox3Geometry 
	local IncrementBox3Random
	local IncrementBox3ScalarVector
	local IncrementBox3Icon
	
	local IncrementPRTModifiers
	local IncrementPRTVolumeModifiers
	local IncrementPRTFumeFXModifiers
	local IncrementGeometryModifiers
	
	local incrementBox3DiskCacheNames
	
	fn incrementSeedInPFlowOperator operator incrementValue=
	(
		if classOf operator == Cache_Disk and incrementBox3DiskCacheNames == true then
		(
			du.LogMessage ("   >Adjusting [" + operator.name + "]")
			local theFilename = operator.Write_To_File 
			local theNewFile
			if theFilename != undefined then
			(
				if not matchpattern theFilename pattern:"*_part*of*_*" then
				(
					if incrementValue >= 0 then 
					(
						setAppData operator 20070719 theFilename
						theNewFile = FranticParticles.MakePartitionFilename theFilename (incrementValue+1) (FranticParticles.GetIntProperty "Partition:Count")
					)	
					else	
					(
						theNewFile = getAppData operator 20070719
					)	
				)
				else
				(
					if incrementValue >= 0 then 
					(
						theNewFile = FranticParticles.ReplacePartitionInFilename theFilename (incrementValue+1) 
					)	
					else	
						theNewFile = getAppData operator 20070719
				)		
				operator.Write_To_File = theNewFile 
				du.LogMessage ("    +File Name of Disk Cache Operator [" + operator.name + "] adjusted to ["+ getFileNameFile theNewFile + "].")
			)
			else
				du.LogMessage ("    -Skipping Disk Cache Operator [" + operator.name + "] - No Filename Found!")
		)
		else if classOf operator == Birth_Particle_File then 
		(
			du.LogMessage ("   >Adjusting [" + operator.name + "]")
			operator.LoadFilePartition = true
			operator.FilePartitionPart = operator.FilePartitionPart + incrementValue
			du.LogMessage ("    +File Partition Part in Birth Particle File Operator [" + operator.name + "] adjusted by ["+ incrementValue as string +"] to [" + operator.FilePartitionPart as string + "].")
		) 
		else if isProperty operator "Random_Seed" then 
		(
			local operatorClass = (classOf operator) as string
			if  (matchPattern operatorClass pattern:"*position*")  then 
			(
				if incrementPositionRandomSeeds do
				(
					du.LogMessage ("   >Adjusting Position Operator [" + operator.name + "]")
					operator.Random_Seed = operator.Random_Seed + incrementValue
					du.LogMessage ("    +Random Seed in Position Operator [" + operator.name + "] adjusted by ["+ incrementValue as string +"] to [" + operator.Random_Seed as string + "].")
				)	
			) 
			else if (matchPattern operatorClass pattern:"*spawn*")  then 
			(
				if incrementSpawnRandomSeeds do
				(
					du.LogMessage ("   >Adjusting Spawn Operator [" + operator.name + "]")
					operator.Random_Seed = operator.Random_Seed + incrementValue
					du.LogMessage ("    +Random Seed in Spawn Operator [" + operator.name + "] adjusted by ["+ incrementValue as string +"] to [" + operator.Random_Seed as string + "].")
				)	
			) 
			else if (matchPattern operatorClass pattern:"*speed*")  then 
			(
				if incrementSpeedRandomSeeds do
				(
					du.LogMessage ("   >Adjusting Speed Operator [" + operator.name + "]")
					operator.Random_Seed = operator.Random_Seed + incrementValue
					du.LogMessage ("    +Random Seed in Speed Operator [" + operator.name + "] adjusted by ["+ incrementValue as string +"] to [" + operator.Random_Seed as string + "].")
				)	
			)
			else if (matchPattern operatorClass pattern:"*rotation*")  then 
			(
				if incrementRotationRandomSeeds do
				(
					du.LogMessage ("   >Adjusting Rotation Operator [" + operator.name + "]")
					operator.Random_Seed = operator.Random_Seed + incrementValue
					du.LogMessage ("    +Random Seed in Rotation Operator [" + operator.name + "] adjusted by ["+ incrementValue as string +"] to [" + operator.Random_Seed as string + "].")
				)	
			)
			else if (matchPattern operatorClass pattern:"*fumefx*")  then 
			(
				if incrementFumeFXRandomSeeds do
				(
					du.LogMessage ("   >Adjusting FumeFX Operator [" + operator.name + "]")
					operator.Random_Seed = operator.Random_Seed + incrementValue
					du.LogMessage ("    +Random Seed in FumeFX Operator [" + operator.name + "] adjusted by ["+ incrementValue as string +"] to [" + operator.Random_Seed as string + "].")
				)	
			)
			else if incrementOtherRandomSeeds  then 
			(
				du.LogMessage ("   >Adjusting Other Operator [" + operator.name + "]")
				operator.Random_Seed = operator.Random_Seed + incrementValue
				du.LogMessage ("    +Random Seed in Operator [" + operator.name + "] adjusted by ["+ incrementValue as string +"] to [" + operator.Random_Seed as string + "].")
			)
		) 
		else if operator != undefined and isProperty operator "Micro_Seed" then 
		(
			du.LogMessage ("   >Adjusting Micro Seed in [" + operator.name + "]")
			operator.Micro_Seed = operator.Micro_Seed + incrementValue
			du.LogMessage ("    +Micro Seed in Operator [" + operator.name + "] adjusted by ["+ incrementValue as string +"] to [" + operator.Micro_Seed as string + "].")
		)
		else if operator != undefined and isProperty operator "SubOperators" and operator.SubOperators.count > 0 then
		(
			du.LogMessage ("   >Adjusting Sub-Operators in Box#3 Data Operator [" + operator.name + "]")
			for subOp in operator.SubOperators do
			(
				if matchPattern ((classof subOp) as string) pattern:"geometryReferenceTarget" and IncrementBox3Geometry do
				(
					local theSubOpName = try(subOp.getName())catch(subOp.name)
					if matchpattern theSubOpName pattern:"*noseed*" then
						du.LogMessage ("   >Skipping Geometry Sub-Operator - NOSEED Requested via Sub-Operator's Name...")
					else
					(
						du.LogMessage ("   >Adjusting Geometry Sub-Operator...")
						subOp.random_seed = subOp.random_seed + incrementValue
						du.LogMessage ("    +Random Seed in Geometry Sub-Operator adjusted by ["+ incrementValue as string +"] to [" + subOp.Random_Seed as string + "].")
					)	
				)
				if matchPattern ((classof subOp) as string) pattern:"randomReferenceTarget" and IncrementBox3Random do
				(
					local theSubOpName = try(subOp.getName())catch(subOp.name)
					if matchpattern theSubOpName pattern:"*noseed*" then
						du.LogMessage ("   >Skipping Random Sub-Operator - NOSEED Requested via Sub-Operator's Name...")
					else
					(
						du.LogMessage ("   >Adjusting Random Sub-Operator...")
						subOp.random_seed = subOp.random_seed + incrementValue
						du.LogMessage ("    +Random Seed in Random Sub-Operator adjusted by ["+ incrementValue as string +"] to [" + subOp.Random_Seed as string + "].")
					)	
				)	
				if (matchPattern ((classof subOp) as string) pattern:"Scalar"  or matchPattern ((classof subOp) as string) pattern:"Vector" ) and IncrementBox3ScalarVector do
				(
					local theSubOpName = try(subOp.getName())catch(subOp.name)
					if matchpattern theSubOpName pattern:"*noseed*" then
						du.LogMessage ("   >Skipping "+ (classof subOp) as string+ " Sub-Operator - NOSEED Requested via Sub-Operator's Name...")
					else
					(
						du.LogMessage ("   >Adjusting "+ (classof subOp) as string+" Sub-Operator...")
						subOp.random_seed = subOp.random_seed + incrementValue
						du.LogMessage ("    +Random Seed in "+ (classof subOp) as string+ " Sub-Operator adjusted by ["+ incrementValue as string +"] to [" + subOp.Random_Seed as string + "].")
					)	
				)	
				if matchPattern ((classof subOp) as string) pattern:"Icon"  and IncrementBox3Icon do
				(
					local theSubOpName = try(subOp.getName())catch(subOp.name)
					if matchpattern theSubOpName pattern:"*noseed*" then
						du.LogMessage ("   >Skipping Icon Sub-Operator - NOSEED Requested via Sub-Operator's Name...")
					else
					(
						du.LogMessage ("   >Adjusting Icon Sub-Operator...")
						subOp.random_seed = subOp.random_seed + incrementValue
						du.LogMessage ("    +Random Seed in Icon Sub-Operator adjusted by ["+ incrementValue as string +"] to [" + subOp.Random_Seed as string + "].")
					)	
				)				
			)
		)		
	)	
	
	--RECURSIVE UPDATE BY SOLITUDE:
	fn incrementdsops g ds incrementvalue =
	(
		for op = 1 to ds.Operators.count do
		(
			local theOp = ds.Operators[op]
			local theOpName = try(theOp.name)catch(undefined)
			if theOpName == undefined do theOpName = try(theOp.getName())catch(undefined)
			if theOpName == undefined do theOpName = ""
			if (isProperty theOp "RandomSeed" or matchpattern theOpName pattern:"*RandomSeed*" == true) and (matchpattern theOpName pattern:"*NOSEED*" == false) then
			(
				du.LogMessage (" >Adjusting Random Seed in TP [" + g.name + "], Dynamic Set "+ ds as string +", Operator "+ op as string+"...")
				if (matchpattern theOpName pattern:"*RandomSeed*" == true) then
				(
					try 
                    (
                        theOp.value += incrementValue
						du.LogMessage (" +Value in TP Input containing '*Randomseed*' in the name adjusted by ["+ incrementValue as string +"] to [" + theOp.value as string + "].")
                    ) catch()
				)
				if isProperty theOp "RandomSeed" then
				(
					theOp.randomSeed += incrementValue
    				du.LogMessage ("  +Random Seed in TP Operator adjusted by ["+ incrementValue as string +"] to [" + theOp.randomSeed as string + "].")
				)
			)
		)--end op loop
		for dssub = 1 to ds.numsubs do
		(
			if (try((not matchPattern ds[dssub].comment pattern:"*NOSEED*") and (matchpattern ds[dssub].name pattern:"DS*")) catch(false)) do
			(
				incrementdsops g ds[dssub] incrementvalue
			)
		)
	)

	fn recursiveincrementTP theTP incrementvalue =
	(
		local theMD = theTP.MasterDynamic
		for i = 1 to themd.numsubs where try((matchpattern theMD[i].name pattern:"DS*") and (not matchPattern theMD[i].comment pattern:"*NOSEED*"))catch(false) do   
			incrementdsops theTP theMD[i] incrementvalue
	)		
	
	-- This function increments the random seeds 
	fn IncrementAllPartitionValues incrementValue  = 
	(
		try(Krakatoa_SeedIncrement_UserFunction incrementValue)catch() --try to call the global function - users can define this function to get notified when seeds change
		global Krakatoa_SeedIncrement_LastValue = incrementValue --set the global variable to the last seed increment.
	
		local theObjectsToAffect = try(execute (FranticParticles.GetProperty "Partition:AffectSeedsInObjects"))catch(#())
		local theObjects
		if theObjectsToAffect.count > 0 then
		(
			theObjects = for g in theObjects where findItem theObjectsToAffect g.name > 0 collect g
			selectedOnly = true
		)	
		else
		(
			theObjects = objects as array
			selectedOnly = false
		)
		
		du.LogMessage (">Adjusting Random Seeds in " + (if selectedOnly then "Selected Objects by [" else "Scene Objects by [")+ incrementValue as string + "]..." )
		
		incrementPositionRandomSeeds = FranticParticles.GetBoolProperty "Partition:IncrementPositionRandomSeeds"
		incrementSpawnRandomSeeds = FranticParticles.GetBoolProperty "Partition:IncrementSpawnRandomSeeds"
		incrementSpeedRandomSeeds = FranticParticles.GetBoolProperty "Partition:IncrementSpeedRandomSeeds"
		incrementFumeFXRandomSeeds = FranticParticles.GetBoolProperty "Partition:IncrementFumeFXRandomSeeds"
		
		incrementRotationRandomSeeds = FranticParticles.GetBoolProperty "Partition:IncrementRotationRandomSeeds"
		incrementOtherRandomSeeds = FranticParticles.GetBoolProperty "Partition:IncrementOtherRandomSeeds"
		incrementLegacyRandomSeeds = FranticParticles.GetBoolProperty "Partition:IncrementLegacyRandomSeeds"
		incrementThinkingRandomSeeds = FranticParticles.GetBoolProperty "Partition:IncrementThinkingRandomSeeds"

		IncrementBox3Geometry = FranticParticles.GetBoolProperty "Partition:IncrementBox3Geometry"
		IncrementBox3Random= FranticParticles.GetBoolProperty "Partition:IncrementBox3Random"
		IncrementBox3ScalarVector= FranticParticles.GetBoolProperty "Partition:IncrementBox3ScalarVector"
		IncrementBox3Icon= FranticParticles.GetBoolProperty "Partition:IncrementBox3Icon"
		
		IncrementPRTModifiers = try(FranticParticles.GetBoolProperty  "Partition:IncrementPRTModifiers" )catch(false)
		IncrementPRTVolumeModifiers = try(FranticParticles.GetBoolProperty  "Partition:IncrementPRTVolumeModifiers")catch(false)
		IncrementPRTFumeFXModifiers = try(FranticParticles.GetBoolProperty  "Partition:IncrementPRTFumeFXModifiers")catch(false)
		IncrementGeometryModifiers = try(FranticParticles.GetBoolProperty  "Partition:IncrementGeometryModifiers")catch(false)
		
		
		incrementBox3DiskCacheNames = FranticParticles.GetBoolProperty "Partition:IncrementBox3DiskCacheNames"
		
	
		du.LogMessage ("   *Increment PFlow Position Seeds:                        " + incrementPositionRandomSeeds as string)
		du.LogMessage ("   *Increment PFlow Spawn Seeds:                           " + incrementSpawnRandomSeeds as string)
		du.LogMessage ("   *Increment PFlow Speed Seeds:                           " + incrementSpeedRandomSeeds as string)
		du.LogMessage ("   *Increment PFlow FumeFX Seeds:                          " + incrementFumeFXRandomSeeds as string)
		du.LogMessage ("   *Increment PFlow Rotation Seeds:                        " + incrementRotationRandomSeeds as string)
		du.LogMessage ("   *Increment PFlow Other Seeds:                           " + incrementOtherRandomSeeds as string)
		du.LogMessage ("   *Increment Max Legacy Particles Seeds:                  " + incrementLegacyRandomSeeds as string)
		du.LogMessage ("   *Increment Thinking Particles Seeds:                    " + incrementThinkingRandomSeeds as string)
		du.LogMessage ("   ")		
		du.LogMessage ("   *Increment PFlow Box#3 Geometry Sub-Operators:          " + incrementBox3Geometry as string)
		du.LogMessage ("   *Increment PFlow Box#3 Random Sub-Operators:            " + incrementBox3Random as string)
		du.LogMessage ("   *Increment PFlow Box#3 Scalar and Vector Sub-Operators: " + incrementBox3ScalarVector as string)
		du.LogMessage ("   *Increment PFlow Box#3 Icon Sub-Operators:              " + incrementBox3Icon as string)
		du.LogMessage ("   ")		
		du.LogMessage ("   *Increment PRT Loader Modifiers:                        " + IncrementPRTModifiers as string)
		du.LogMessage ("   *Increment PRT Volume, PRT Surface and Modifiers:       " + IncrementPRTVolumeModifiers as string)
		du.LogMessage ("   *Increment PRT FumeFX and Modifiers:                    " + IncrementPRTFumeFXModifiers as string)
		du.LogMessage ("   *Increment Geometry Modifiers:                          " + IncrementGeometryModifiers as string)
		du.LogMessage ("   *Increment PFlow Box#3 Disk Cache Filenames:            " + incrementBox3DiskCacheNames as string)
		
		
		for g in theObjects do 
		(
			case classOf g of
			(
				PF_Source: 
				(
					if not matchPattern (g.name) pattern:"*noseed*" then
					(
						for j = 1 to g.numActions() do 
						(
							local operator = g.getAction j
							if not matchPattern operator.name pattern:"*noseed*" then
							(
								incrementSeedInPFlowOperator operator incrementValue
							)	
							else
								du.LogMessage ("   -Skipping PFlow Operator [" + operator.name + "] - NOSEED Requested via Operator's Name...")
						)--end j loop
						du.LogMessage (" >Processing Events in PFlow Source [" + g.name + "]")
						for i = 1 to g.baseObject.numSubs do 
						(
							local event = g.baseObject[i]
							if matchpattern ((classOf event.object) as string) pattern:"Event" do 
							(
								if not matchPattern (event.name) pattern:"*noseed*" then
								(
									du.LogMessage ("  >Processing Operators in PFlow Event [" + event.name + "]")
									for j = 1 to event.numActions() do 
									(
										local operator = event.getAction j
										if not matchPattern operator.name pattern:"*noseed*" then
										(
											incrementSeedInPFlowOperator operator incrementValue
										)	
										else
											du.LogMessage ("   -Skipping PFlow Operator [" + operator.name + "] - NOSEED Requested via Operator's Name...")
									)--end j loop
								)
								else	
									du.LogMessage ("  -Skipping All Operators in PFlow Event [" + event.name + "] - NOSEED Requested via Event's Name...")
							)--end if event
						)--end i loop
					)
					else	
						du.LogMessage (" -Skipping All Events in PFlow [" + g.name + "] - NOSEED Requested via PF_Source's Name...")
				)--end pf_source case
				PCloud: (
							if matchPattern (g.name) pattern:"*noseed*" then
								du.LogMessage (" -Skipping PCloud [" + g.name + "] - NOSEED requested via Object's Name.")
							else
							(
								du.LogMessage (" >Adjusting Random Seed in PCloud [" + g.name + "]")
								g.seed += incrementValue
								du.LogMessage ("  +Random Seed in PCloud [" + g.name + "] adjusted by ["+ incrementValue as string +"] to [" + g.seed as string + "].")
							)	
						)
				Blizzard: (
							if matchPattern (g.name) pattern:"*noseed*" then
								du.LogMessage (" -Skipping Blizzard [" + g.name + "] - NOSEED requested via Object's Name.")
							else
							(
								du.LogMessage (" >Adjusting Random Seed in Blizzard [" + g.name + "]")
								g.seed += incrementValue
								du.LogMessage ("  +Random Seed in Blizzard [" + g.name + "] adjusted by ["+ incrementValue as string +"] to [" + g.seed as string + "].")
							)	
						)
				PArray: (
							if matchPattern (g.name) pattern:"*noseed*" then
								du.LogMessage (" -Skipping PArray [" + g.name + "] - NOSEED requested via Object's Name.")
							else
							(
								du.LogMessage (" >Adjusting Random Seed in PArray [" + g.name + "]")
								g.seed += incrementValue
								du.LogMessage ("  +Random Seed in PArray [" + g.name + "] adjusted by ["+ incrementValue as string +"] to [" + g.seed as string + "].")
							)	
						)
				SuperSpray: (
							if matchPattern (g.name) pattern:"*noseed*" then
								du.LogMessage (" -Skipping SuperSpray [" + g.name + "] - NOSEED requested via Object's Name.")
							else
							(
								du.LogMessage (" >Adjusting Random Seed in SuperSpray [" + g.name + "]")
								g.seed += incrementValue
								du.LogMessage ("  +Random Seed in SuperSpray [" + g.name + "] adjusted by ["+ incrementValue as string +"] to [" + g.seed as string + "].")
							)
						)
				Thinking: ( --new code by Solitude
						if incrementThinkingRandomSeeds then
						(
							if matchPattern (g.name) pattern:"*noseed*" then
								du.LogMessage (" -Skipping Thinking Particles [" + g.name + "] - NOSEED requested via Object's Name.")
							else
								recursiveincrementTP g incrementvalue
						)--end if TP on   
					)--end TP case
					KrakatoaPRTLoader: (
						if IncrementPRTModifiers then
						(
							if matchPattern (g.name) pattern:"*noseed*" then
								du.LogMessage (" -Skipping PRT Loader [" + g.name + "] - NOSEED requested via Object's Name.")
							else
							(
								for m in g.modifiers where isProperty m #seed do
								(
									if matchPattern m.name pattern:"*noseed*" then
									(
										du.LogMessage (" -Skipping Modifier ["+m as string+"] on [" + g.name + "] - NOSEED requested via Modifier's Name.")
									)
									else
									(
										du.LogMessage (" >Adjusting Random Seed in Object [" + g.name + "], Modifier ["+ m as string +"]...")
										m.seed += incrementValue
										du.LogMessage ("  +Random Seed in Object adjusted by ["+ incrementValue as string +"] to [" + m.Seed as string + "].")
									)
								)
							)
						)	
					)--end PRT Loader case
					PRT_Volume: (
						if IncrementPRTVolumeModifiers then
						(
							if matchPattern (g.name) pattern:"*noseed*" then
								du.LogMessage (" -Skipping PRT Volume [" + g.name + "] - NOSEED requested via Object's Name.")
							else
							(
								try
								(
									du.LogMessage (" >Adjusting Random Seed in PRT Volume [" + g.name + "] Base Object...")
									g.RandomSeed += incrementValue
									du.LogMessage ("  +Random Seed in PRT Volume Base Object adjusted by ["+ incrementValue as string +"] to [" + g.RandomSeed as string + "].")
								)
								catch
								(
									du.LogMessage (" -Failed to adjust PRT Volume Base Object Random Seed.")
								)								
								for m in g.modifiers where isProperty m #seed do
								(
									if matchPattern m.name pattern:"*noseed*" then
									(
										du.LogMessage (" -Skipping Modifier ["+m as string+"] on [" + g.name + "] - NOSEED requested via Modifier's Name.")
									)
									else
									(
										du.LogMessage(" >Adjusting Random Seed in PRT Volume [" + g.name + "], Modifier ["+ m as string +"]...")
										m.seed += incrementValue
										du.LogMessage ("  +Random Seed in PRT Volume Modifier adjusted by ["+ incrementValue as string +"] to [" + m.Seed as string + "].")
									)
								)
							)
						)	
					)--end PRT Volume case	
					PRT_Surface: (
						if IncrementPRTVolumeModifiers then
						(
							if matchPattern (g.name) pattern:"*noseed*" then
								du.LogMessage (" -Skipping PRT Surface [" + g.name + "] - NOSEED requested via Object's Name.")
							else
							(
								try
								(
									du.LogMessage (" >Adjusting Random Seed in PRT FumeFX [" + g.name + "] Base Object...")
									g.RandomSeed += incrementValue
									du.LogMessage ("  +Random Seed in PRT Surface Base Object adjusted by ["+ incrementValue as string +"] to [" + g.RandomSeed as string + "].")
								)
								catch
								(
									du.LogMessage (" -Failed to adjust PRT Surface Base Object Random Seed.")
								)
								for m in g.modifiers where isProperty m #seed do
								(
									if matchPattern m.name pattern:"*noseed*" then
									(
										du.LogMessage (" -Skipping Modifier ["+m as string+"] on [" + g.name + "] - NOSEED requested via Modifier's Name.")
									)
									else
									(
										du.LogMessage (" >Adjusting Random Seed in PRT Surface [" + g.name + "], Modifier ["+ m as string +"]...")
										m.seed += incrementValue
										du.LogMessage ("  +Random Seed in PRT Surface Modifier adjusted by ["+ incrementValue as string +"] to [" + m.Seed as string + "].")
									)
								)
							)
						)	
					)--end PRT Surface case						
					PRT_FumeFX: (
						if IncrementPRTFumeFXModifiers then
						(
							if matchPattern (g.name) pattern:"*noseed*" then
								du.LogMessage (" -Skipping PRT FumeFX [" + g.name + "] - NOSEED requested via Object's Name.")
							else
							(
								try
								(
									du.LogMessage (" >Adjusting Random Seed in PRT FumeFX [" + g.name + "] Base Object...")
									g.RandomSeed += incrementValue
									du.LogMessage ("  +Random Seed in PRT FumeFX Base Object adjusted by ["+ incrementValue as string +"] to [" + g.RandomSeed as string + "].")
								)
								catch
								(
									du.LogMessage (" -Failed to adjust PRT FumeFX Base Object Random Seed.")
								)								
								for m in g.modifiers where isProperty m #seed do
								(
									if matchPattern m.name pattern:"*noseed*" then
									(
										du.LogMessage (" -Skipping Modifier ["+m as string+"] on [" + g.name + "] - NOSEED requested via Modifier's Name.")
									)
									else
									(
										du.LogMessage(" >Adjusting Random Seed in PRT FumeFX [" + g.name + "], Modifier ["+ m as string +"]...")
										m.seed += incrementValue
										du.LogMessage ("  +Random Seed in PRT FumeFX adjusted by ["+ incrementValue as string +"] to [" + m.Seed as string + "].")
									)
								)
							)
						)	
					)--end PRT Volume case							
					default: (
						if IncrementGeometryModifiers then
						(
							if matchPattern (g.name) pattern:"*noseed*" then
								du.LogMessage (" -Skipping Geometry Object [" + g.name + "] - NOSEED requested via Object's Name.")
							else
							(
								for m in g.modifiers where isProperty m #seed do
								(
									if matchPattern m.name pattern:"*noseed*" then
									(
										du.LogMessage (" -Skipping Modifier ["+m as string+"] on [" + g.name + "] - NOSEED requested via Modifier's Name.")
									)
									else
									(
										du.LogMessage (" >Adjusting Random Seed in Object [" + g.name + "], Modifier ["+ m as string +"]...")
										m.seed += incrementValue
										du.LogMessage ("  +Random Seed in Object adjusted by ["+ incrementValue as string +"] to [" + m.Seed as string + "].")
									)
								)
							)
						)--end if	
					)--end default handling of modifiers					
			)--end case			
		)--end g loop
		du.LogMessage (">Adjusting Random Seeds FINISHED.")
		true
	)--end fn	
	
	fn getFilenameFromBackupRoot =
	(
		local val = FranticParticles.GetProperty "Partition:BackupRoot"
		if val != "" do
		(
			local theNextVal = FranticParticles.GetProperty "ParticleFilesProject"
			if theNextVal != "" then
			(
				if not matchPattern theNextVal pattern:"*\\" and not matchPattern theNextVal pattern:"*/" do theNextVal += "\\"
				val += theNextVal
			)
			theNextVal = FranticParticles.GetProperty "ParticleFilesSequence"
			if theNextVal != "" then
			(
				if not matchPattern theNextVal pattern:"*\\" and not matchPattern theNextVal pattern:"*/" do theNextVal += "\\"
				val += theNextVal
			)
			theNextVal = FranticParticles.GetProperty "ParticleFilesTake"
			if theNextVal != "" then
			(
				if not matchPattern theNextVal pattern:"*\\" and not matchPattern theNextVal pattern:"*/" do theNextVal += "\\"
				val += theNextVal
			)			
		)	
		val 
	)		
	
	du.SetTitle "KRAKATOA PARTITIONING..." --set the job title 
	du.LogMessage "Starting Krakatoa Partition Job..." --output a message to the log
	ETAstartTime = st = timestamp() --get the current system time
	
	partitionNumber = du.CurrentFrame
	totalPartitions = (FranticParticles.GetIntProperty "Partition:Count")
	
	du.LogMessage (">Current Partition Is..." + partitionNumber as string + " of " + totalPartitions as string)
	du.LogMessage ">Incrementing Seeds..."
	IncrementAllPartitionValues (partitionNumber-1) 
	du.LogMessage "+Incremented Seeds..."

	local theFullBaseFileName = (FranticParticles.GetProperty "ParticleFiles")
	local theBasePath = getFileNamePath theFullBaseFileName
	local theBaseFilename = getFileNameFile theFullBaseFileName
	local theBaseType = getFileNameType theFullBaseFileName
	if matchpattern theBaseFilename pattern:"*part*of*" then
	(
		theIndex = 0
		for i = theBaseFilename.count-4 to 1 by -1 do 
		(
			if substring theBaseFilename i 5 == "_part" then
			(
				theIndex = i
				exit
			)	
		)
		theBaseFilename = substring theBaseFilename 1 (theIndex-1) 
	)
	
	partitionFilename = FranticParticles.MakePartitionFilename (theBasePath + theBaseFilename+theBaseType) partitionNumber totalPartitions
	
	FranticParticles.SetProperty "ParticleFiles" partitionFilename
	du.LogMessage (">File Name: " + partitionFilename)
	local theSavePath = (getFileNamePath partitionFilename)
	local result = makeDir theSavePath all:true
	if result then du.LogMessage ("+Created Save Path [" + theSavePath  +"] which did not exist previously.")
	
	local currentSequence = #()
	
	case rendTimeType of
	(
		1: (
				currentSequence = #(currentTime.frame as integer) 
			)
		2: (
				currentSequence = for t in animationRange.start to animationRange.end by rendNthFrame collect (t.frame as integer)
			)
		3: (
				currentSequence = for t in rendStart to rendEnd by rendNthFrame collect (t.frame as integer)
			)
		4: (
				theFS = filterString rendPickupFrames "-"
				txt = "#{"
				for i = 1 to theFS.count-1 do txt += theFS[i]+ ".."
				txt += theFS[theFS.count] + "}"
				currentSequence = (execute txt) as array
			)
	)
	
	theTotalCount = currentSequence.count
	du.LogMessage (">Starting Partitioning of " + theTotalCount as string + " Frames...")
	cnt = 0
	du.LogMessage (">Backup Mode Is " + #("DO NOTHING","COPY","MOVE")[theBackupVal] )
	if theBackupVal > 1 do
	(
		theBackupPath = getFilenameFromBackupRoot()
		makeDir theBackupPath all:true
	)

	fn preRenderFrameFunction =
	(
		st1 = timestamp()
		cnt += 1
		framesSoFar += 1
		du.setProgress ( 100.0 * cnt/theTotalCount)
		timeSoFar = (timestamp() - ETAstartTime) * 0.001
		eta =  timeSoFar / framesSoFar  *  (theTotalCount - framesSoFar)

		local txt = ">Partition "+partitionNumber as string + " of " + totalPartitions as string
		txt+= " - Frame "+(currentTime.frame as integer) as string + " ("+ cnt as string+ "/" + theTotalCount as string +") "
		txt+=" - Elapsed:"+ (FranticParticleRenderMXS.convertToHMS timeSoFar) as string
		txt+=" - Remaining:" + (FranticParticleRenderMXS.convertToHMS eta) as string 
		du.LogMessage txt
		du.setTitle txt
	)
	
	fn postRenderFrameFunction=
	(
		if theBackupVal > 1 do
		(
			aFile = FranticParticles.ReplaceSequenceNumber partitionFilename (currentTime.frame as integer)
			local targetFile = (theBackupPath + fileNameFromPath aFile)
			if doesFileExist targetFile do deleteFile targetFile 
			local result = copyFile aFile targetFile 
			if result == true then
			(
				if theBackupVal == 3 do deleteFile aFile
				du.LogMessage ("+" + #("","COPIED","MOVED")[theBackupVal] +" ["+ aFile + "] to ["+ targetFile +"].")
			)	
			else
				du.LogMessage ("--FAILED to " + #("","copy","move")[theBackupVal] +" ["+ aFile + "] to ["+ targetFile +"].")
		)
		lastFrameTime = (timestamp() - st1)/1000.0
		du.LogMessage ("+Frame Save Time: "+ FranticParticleRenderMXS.convertToHMS lastFrameTime) 
	)
	
	callbacks.removeScripts id:#Krakatoa_TP_Partitioning
	callbacks.addScript #preRenderFrame "preRenderFrameFunction()"  id:#Krakatoa_TP_Partitioning
	callbacks.addScript #postRenderFrame "postRenderFrameFunction()"  id:#Krakatoa_TP_Partitioning
	
	case rendTimeType of
	(
		1: render frame:#current
		2: render framerange:#active nthframe:rendNThFrame  vfb:off
		3: render fromframe:rendStart  toframe:rendEnd  nthframe:rendNThFrame vfb:off
		4: (for theFrame in currentSequence do render frame:theFrame vfb:off)
	)
	
	du.LogMessage (">Partitioning Finished in "+ ((timestamp() - st)/1000.0) as string + " sec.") --output the partitioning duration
	
	du.LogMessage ">Decrementing Seeds..."
	IncrementAllPartitionValues -(partitionNumber-1) 
	du.LogMessage (">Task Finished in "+ ((timestamp() - st)/1000.0) as string + " sec.") --output the task duration
	du.LogMessage ">Done."
	if (theTotalCount == framesSoFar) then true else false --return true if the task has finished successfully, return false to fail the task if the rendered count did not match the expected count
)--end script
