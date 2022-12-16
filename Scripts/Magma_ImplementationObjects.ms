-- Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
-- SPDX-License-Identifier: Apache-2.0
global KrakatoaMagmaModifier_ImplementationObject
struct KrakatoaMagmaModifier_ImplementationObject
(
	fn getProductName = (#krakatoa),
	
	fn getProductTitle = ("KRAKATOA"),	
	
	fn getOwnerType = (#modifier),		
	
	fn getGlobalInterface = (FranticParticles),
	
	fn getHomeFolder = (FranticParticles.KrakatoaHome ),
	
	fn getCAName  =	(	"KCM_CA"),
	
	fn GetExposedControlsTitle = ("Exposed Parameters"),
	
	fn getSupportsDebug magmaNode =
	(
		(for i in (refs.dependents magmaNode) where classof i == KrakatoaMXGlobalDataHolder collect i).count == 0
	),
	
	fn getRequires32BitChannels = (false),
	
	fn openEditor theMagmaHolder theMagmaOwner =
	(
		local theScript = (FranticParticles.KrakatoaHome + "\\Scripts\\Krakatoa_MagmaFlow.ms")
		::MagmaFlowEditor_Functions.OpenMagmaFlow theMagmaHolder theMagmaOwner KrakatoaMagmaModifier_ImplementationObject theScript offscreen:false
	),		
	
	fn getEditorTitlePrefix magmaNode magmaOwner currentPreset:""=
	(
		local txt = "KRAKATOA Magma Flow - "
		txt += "<"+magmaOwner.name+">"			
		txt		
	),
	fn getUsedByRendererString theMagmaHolder theChannelName =
	(
		if renderers.current.classid as string == "#(-1204370534, -399920359)" or renderers.current.classid as string == "#(3090596762L, 3895046937L)" then --if Krakatoa is the Renderer
		(
			try(
				Krakatoa_GUI_Channels.updateMemChannels()
				if (for i in Krakatoa_GUI_Channels.activeMemChannels where matchPattern i[1] pattern:theChannelName collect i).count == 1 then
					"Will Be Stored In PCache" 
				else 
					"Not Cacheable"
			)catch("Failed To Acquire Renderer Info")	
		)
		else "Current Renderer Not Krakatoa"
	),
	
	fn getIterationMode magmaOwner = (	#none),
	
	fn setIterationMode magmaOwner newMode = (false)		
)

global KrakatoaRenderElement_ImplementationObject
struct KrakatoaRenderElement_ImplementationObject
(
	fn getProductName =	(#krakatoa	),
	
	fn getProductTitle =	("KRAKATOA"),	
	
	fn getOwnerType =	(#renderelement	),		
	
	fn getGlobalInterface = (FranticParticles),
	
	fn getHomeFolder =	(FranticParticles.KrakatoaHome),
	
	fn getCAName =	("KCM_CA"),
	
	fn GetExposedControlsTitle = ("Exposed Parameters"),
	
	fn getSupportsDebug magmaNode = ( false ),	
	
	fn getRequires32BitChannels = (false),
	
	fn openEditor theMagmaHolder theMagmaOwner =
	(
		local theScript = (FranticParticles.KrakatoaHome + "\\Scripts\\Krakatoa_MagmaFlow.ms")
		::MagmaFlowEditor_Functions.OpenMagmaFlow theMagmaHolder theMagmaOwner KrakatoaRenderElement_ImplementationObject theScript offscreen:false
	),			
	
	fn getEditorTitlePrefix magmaNode magmaOwner currentPreset:"" = 	("KRAKATOA RENDER ELEMENT" ),
	
	fn getUsedByRendererString theMagmaHolder theChannelName = 	("Will Output As Render Element" ),
	
	fn getIterationMode magmaOwner = (	#none),
	
	fn setIterationMode magmaOwner newMode = (false)	
)