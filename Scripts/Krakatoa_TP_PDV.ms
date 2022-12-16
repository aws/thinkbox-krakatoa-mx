-- Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
-- SPDX-License-Identifier: Apache-2.0
tp_unregister tp_ParticleDataViewer	--unregister before you make changes in the plugin, you can test the code on tp runtime

plugin  Geometry tp_ParticleDataViewer
name:"tp_PDV"
category:"Krakatoa"
classid:#(0x108f9090, 0x567a0d17)
extends:TP_ScriptBase
invisible:true
replaceui:true
version:1
(  
	
	local DataArray = #()
	
	parameters main rollout:params
	(
		isPDV type:#boolean default:true
		lastUpdateTime type:#float default:-100000
	)
	rollout params "Particle Data Viewer Helper"
	(
		group "Info:"
		(
			label lbl_10 "This Operator can expose"
			label lbl_20 "a value to the Krakatoa "
			label lbl_30 "Particle Data Viewer."
			label lbl_35 
			label lbl_40 "Only the Point3 or the"
			label lbl_50 "Scalar Input should be"
			label lbl_60 "connected at any time."
			label lbl_70 "If both are connected, "
			label lbl_80 "only the Float Input's data"
			label lbl_90 "will be exposed."
		)
	)	
	
	fn tp_color_type =
	(
		2	--only for coloring in schematic view, 0 == condition, 1 == operator, 2 == helper, 3 == generator, 4 == initiator, 5 == shape 
	)
	
	fn tp_init_inoutputs  tp_inout =
	(
		ver = tp_inout.Version()
		if ver == 0 then 
		(	--version is 0, that means this is a new creation in the schematicview, a version > 0 let you see witch port configuration loaded 
			tp_inout.AddInput	#TP_PORT_TYPE_BOOL	  	 		"On"   				#TP_PORT_FLAG_NONE
			tp_inout.AddInput	#TP_PORT_TYPE_PARTICLE		"Particle"   			#TP_PORT_FLAG_NEEDED
			tp_inout.AddInput	#TP_PORT_TYPE_POINT3	  		"Point3"  		 	#TP_PORT_FLAG_NONE
			tp_inout.AddInput	#TP_PORT_TYPE_FLOAT	  		"Scalar"  		 	#TP_PORT_FLAG_NONE
			
			tp_inout.SetVersion 1  --importen the inoutput version must set to the actuell version
		)
		else
		(
		)
	)	
	
	fn tp_calculate tp_outid  tp_inout  tp_system =
	(
		--format "tp_outid =%\n" tp_outid 
		if tp_outid < 0 then 
		(
			if tp_inout.InputChanged 1 and tp_inout.GetInValue 0 != 0 then
			(
				local pid = tp_inout.GetInValue 1
				if currentTime != lastUpdateTime do 
				(
					DataArray = #()
					lastUpdateTime = currentTime
				)
				if pid != undefined do
				(
					if tp_inout.InputConnected   2 then
					(
						DataArray[1] = #point3
						DataArray[pid+2]=tp_inout.GetInValue 2
						--::TP_PDV_DataArray = deepCopy DataArray
					)
					if tp_inout.InputConnected   3 then
					(
						DataArray[1] = #float
						DataArray[pid+2]=tp_inout.GetInValue 3
						--::TP_PDV_DataArray = deepCopy DataArray
					)					
				)
			)
		)	
		undefined
	)
	
)
tp_register tp_ParticleDataViewer 2 --register the plunin,  arg is the type, in witch basis category this opertor shown, 0 condition, 1 operator, 2 helper