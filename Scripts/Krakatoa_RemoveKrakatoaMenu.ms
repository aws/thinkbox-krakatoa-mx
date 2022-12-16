-- Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
-- SPDX-License-Identifier: Apache-2.0
(
if FranticParticles == undefined do --If Krakatoa was removed
(
	local theMainMenu = menuMan.getMainMenuBar() --find the 3ds Max Main Menu
	local theKrakatoaMenu = menuMan.findMenu "Krakatoa" --look for the "Krakatoa" entry
	try(menuMan.unRegisterMenu theKrakatoaMenu)catch() --try to remove it
	menuMan.updateMenuBar() --update the main menu bar
	deleteFile (getSourceFileName()) --delete the script from the startup folder
)
)
