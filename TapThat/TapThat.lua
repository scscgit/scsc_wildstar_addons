-- Used with the FindGlobals script from http://www.wowace.com/addons/findglobals/


-----------------------------------------------------------------------------------------------
-- Client Lua Script for TapThat
-- Copyright (c) NCsoft. All rights reserved
-----------------------------------------------------------------------------------------------
 
require "Window"
require "CSIsLib" 
-----------------------------------------------------------------------------------------------
-- TapThat Module Definition
-----------------------------------------------------------------------------------------------
local TapThat = {} 

-----------------------------------------------------------------------------------------------
-- Constants
-----------------------------------------------------------------------------------------------
local CSITypeEnumerationLookupTable = {}  --Used to lookup a human friendly string from the ClientSideInteractionType enumeration
CSITypeEnumerationLookupTable[CSIsLib.ClientSideInteractionType_RapidTapping] = "RapidTapping" --Done
CSITypeEnumerationLookupTable[CSIsLib.ClientSideInteractionType_PressAndHold] = "PressAndHold" --Done
CSITypeEnumerationLookupTable[CSIsLib.ClientSideInteractionType_PrecisionTapping] = "PrecisionTapping" --Done
CSITypeEnumerationLookupTable[CSIsLib.ClientSideInteractionType_Metronome] = "Metronome" --Done
CSITypeEnumerationLookupTable[CSIsLib.ClientSideInteractionType_YesNo] = "YesNo" --Cant Do / Needs a database
CSITypeEnumerationLookupTable[CSIsLib.ClientSideInteractionType_Memory] = "Memory" --Done
CSITypeEnumerationLookupTable[CSIsLib.ClientSideInteractionType_Keypad] = "Keypad"  --??? Needs a database of entry codes?
CSITypeEnumerationLookupTable[CSIsLib.ClientSideInteractionType_RapidTappingInverse] = "RapidTappingInverse"  --Done

local sVersion = "1.8.4"
-----------------------------------------------------------------------------------------------
-- Locals
-----------------------------------------------------------------------------------------------
local tMetronomeInfo = {} --Used to store information for completing the metronome CSI
local tMemoryInfo = {nCurrentShowing = 1} --Used to store memory CSI buttons
local tOptions = {}

local tDefaultOptions = {
	RapidTapOption = true,
	PressAndHoldOption = true,
	MetronomeOption = true,
	MemoryOption = true,
	DebugOption = false,
}

function TapThat:OnSave(eType)
	if eType ~= GameLib.CodeEnumAddonSaveLevel.Character then return end
	local tSaved = {
	RapidTapOption = tOptions.RapidTapOption,
	PressAndHoldOption = tOptions.PressAndHoldOption,
	MetronomeOption = tOptions.MetronomeOption,
	MemoryOption = tOptions.MemoryOption,
	DebugOption = tOptions.DebugOption,
	}
	return tSaved
end

-----------------------------------------------------------------------------------------------
-- OnRestore is not called the first time the addon is loaded.
-- Set defaults in OnDocLoaded (race condition, be careful)
-----------------------------------------------------------------------------------------------
function TapThat:OnRestore(eType, tSavedData)
	if eType ~= GameLib.CodeEnumAddonSaveLevel.Character then return end
	for sOptionName,optionValue in pairs(tSavedData) do
		tOptions[sOptionName] = optionValue
	end
end


-----------------------------------------------------------------------------------------------
-- Initialization
-----------------------------------------------------------------------------------------------
function TapThat:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self 

    -- initialize variables here

    return o
end

function TapThat:Init()
	local bHasConfigureFunction = true
	local strConfigureButtonText = "TapThat"
	local tDependencies = {
		-- "UnitOrPackageName",
	}
    Apollo.RegisterAddon(self, bHasConfigureFunction, strConfigureButtonText, tDependencies)
end
 

-----------------------------------------------------------------------------------------------
-- TapThat OnLoad
-----------------------------------------------------------------------------------------------
function TapThat:OnLoad()
    -- load our form file
	self.xmlDoc = XmlDoc.CreateFromFile("TapThat.xml")
	self.xmlDoc:RegisterCallback("OnDocLoaded", self)
end

-----------------------------------------------------------------------------------------------
-- TapThat OnDocLoaded
-----------------------------------------------------------------------------------------------
function TapThat:OnDocLoaded()

	if self.xmlDoc ~= nil and self.xmlDoc:IsLoaded() then
	    self.wndMain = Apollo.LoadForm(self.xmlDoc, "TapThatForm", nil, self)
		if self.wndMain == nil then
			Apollo.AddAddonErrorText(self, "Could not load the main window for some reason.")
			return
		end
		
	    self.wndMain:Show(false, true)
		self.wndMain:FindChild("Title"):SetText("TapThat Options v" .. sVersion)

		-- if the xmlDoc is no longer needed, you should set it to nil
		self.xmlDoc = nil
		
		Apollo.RegisterEventHandler("ProgressClickWindowCompletionLevel", "OnProgressClickWindowCompletionLevel", self) -- Updates Progress Bar
		Apollo.RegisterEventHandler("SetProgressClickTimes", "OnSetProgressClickTimes", self)  --Fires for the Metronome CSI to tell where the keypress locations are
		Apollo.RegisterEventHandler("AcceptProgressInput", "OnAcceptProgressInput", self)  --Fires for the Memory CSI to indicate if it is showing buttons or waiting for input
		Apollo.RegisterEventHandler("HighlightProgressOption", "OnHighlightProgressOption", self)  --Fires when a Memory CSI button is highlighted
		Apollo.RegisterTimerHandler("TapThatMemoryTimer", "SendMemoryInputs", self)  --Timer used for sending Memory CSI buttons.  (only one send event is accepted per frame)
		
		Apollo.RegisterEventHandler("InterfaceMenuListHasLoaded", "OnInterfaceMenuListHasLoaded", self)
		Apollo.RegisterEventHandler("TapThatInterfaceList", "OnConfigure", self)
		Apollo.RegisterSlashCommand("tt", "OnConfigure", self)
		Apollo.RegisterSlashCommand("tapthat", "OnConfigure", self)

		--Default options  Race condition here, but order does not matter for this.
		for sOptionName, optionValue in pairs(tDefaultOptions) do
			if tOptions[sOptionName] == nil then
				tOptions[sOptionName] = optionValue
			end
		end
	end
end

-----------------------------------------------------------------------------------------------
-- TapThat OnProgressClickWindowCompletionLevel
-- This event fires when the CSI progress level is changed.
-----------------------------------------------------------------------------------------------
function TapThat:OnProgressClickWindowCompletionLevel(nPercentage, bIsReversed) -- Updates Progress Bar
	local tActiveCSI = CSIsLib.GetActiveCSI()
	if not tActiveCSI then return end
	local eType = tActiveCSI.eType
	
	TapThat:DebugPrint(CSITypeEnumerationLookupTable[eType] .. " " ..nPercentage)
	
	if eType == CSIsLib.ClientSideInteractionType_RapidTapping or eType == CSIsLib.ClientSideInteractionType_RapidTappingInverse then
		--[[ RapidTapping CSI Handler
		Rapid Tapping CSI will start when you send the first tap.  No need to call StartActiveCSI().
		Rapid Tapping just requires you to send CSIsLib.CSIProcessInteraction(true) for each tap.  
		ProgressClickWindowCompletionLevel event will fire in response to a CSIProcessInteraction call.
		We don't need a timer to know when to tap next just wait for ProgressClickWindowCompletionLevel to tap again.
		]]
		if not tOptions.RapidTapOption then return end
		TapThat:DebugPrint("RapidTapping CSI, Sending Tap")
		CSIsLib.CSIProcessInteraction(true)
		
	elseif eType == CSIsLib.ClientSideInteractionType_Metronome or eType == CSIsLib.ClientSideInteractionType_PrecisionTapping then
		--[[
		Metronome and PrecisionTapping are almost identical and we can use the same code to handle both CSIs.
		The CSI doesn't start on first keypress so call StartActiveCSI() to start.
		SetProgressClickTimes is raised after the first ProgressClickWindowCompletionLevel event is raised so avoid nil errors.
		SetProgressClickTimes is only called once per CSI so we need to store the information.
		When the bIsReversed flag is set to true the progress bar will begin counting down (moving left)
		There is usually 2 regions to click, but sometimes there is only 1 region.
		]]

		if not tOptions.MetronomeOption then return end
		if not CSIsLib.IsCSIRunning() then
			CSIsLib.StartActiveCSI()
			tMetronomeInfo = {}
			TapThat:DebugPrint("Starting " .. CSITypeEnumerationLookupTable[eType])
		end
		
		if not tMetronomeInfo or not tMetronomeInfo.isActive then return end  --Need to wait for a SetProgressClickTimes event to fire so we know when to click

		if bIsReversed ~= tMetronomeInfo.bIsReversed then --Direction Changed
			TapThat:DebugPrint("Metronome direction reversed")
			if bIsReversed then --We were moving to the right, now we are moving to the left
				if tMetronomeInfo.Swings[2].left > 0 then --Check for 2 swings or just 1
					 tMetronomeInfo.nCurrentSwing = 2
				else
					tMetronomeInfo.nCurrentSwing = 1
				end
			else --now moving right
				tMetronomeInfo.nCurrentSwing = 1
			end
			tMetronomeInfo.bIsReversed = bIsReversed
		end
		
		if tMetronomeInfo.nCurrentSwing > 0 and tMetronomeInfo.nCurrentSwing < 3 then -- If we are at swing 0 or swing 3 we need to wait for direction change to set the swing to 1 or 2
			if nPercentage > tMetronomeInfo.Swings[tMetronomeInfo.nCurrentSwing].left and nPercentage < tMetronomeInfo.Swings[tMetronomeInfo.nCurrentSwing].right then
				if not bIsReversed then --moving to the right
					tMetronomeInfo.nCurrentSwing = tMetronomeInfo.nCurrentSwing + 1
				else --moving to the left
					tMetronomeInfo.nCurrentSwing = tMetronomeInfo.nCurrentSwing - 1
				end
				CSIsLib.CSIProcessInteraction(true)
				TapThat:DebugPrint("In Metronome Range")
			end
		end
		
	elseif eType == CSIsLib.ClientSideInteractionType_PressAndHold then
		--[[
		PressAndHold is very simple.  Just call CSIProcessInteraction(true) when the event starts
		StartActiveCSI does not need to be called the event starts on the first CSIProcessInteraction call
		]]
		if not tOptions.PressAndHoldOption then return end
		if not CSIsLib.IsCSIRunning() then
			CSIsLib.CSIProcessInteraction(true)
			TapThat:DebugPrint("Starting PressAndHold")
		else --Just incase the user presses f and releases it just keep sending true to keep holding
			CSIsLib.CSIProcessInteraction(true)
		end
		
	elseif eType == CSIsLib.ClientSideInteractionType_Memory then
		--[[
		Memory CSI is more involved and OnProgressClickWindowCompletionLevel is only called once during the entire CSI so we need to handle it elsewhere.
		Requires a StartActiveCSI() call to start the CSI as it does not use CSIProcessInteraction
		]]
		local addonCheatSimon = Apollo.GetAddon("CheatSimon")
		if addonCheatSimon and addonCheatSimon.bFullAuto then return end --Let CheatSimon handle Memory CSIs.
		if not tOptions.MemoryOption then return end
		if not CSIsLib.IsCSIRunning() then
			CSIsLib.StartActiveCSI()
			tMemoryInfo = {nCurrentShowing = 1} --Clear the old list of buttons
			TapThat:DebugPrint("Starting Memory")
		end
	end
end


-----------------------------------------------------------------------------------------------
-- TapThat OnSetProgressClickTimes
-- This event fires for Metronome and PrecisionTap CSIs.
-- nWidth is the total width of the button area
-- nLocation1 is the center of the button location (0 to 100)
-- nLocation2 is the center of the second button location (0 to 100) Is 0 if there is only 1 button
-- nSwingCount is the total number of keypresses to complete the event
-- This event is only called once per CSI after the first OnProgressClickWindowCompletionLevel event fires
-----------------------------------------------------------------------------------------------
function TapThat:OnSetProgressClickTimes(nWidth, nLocation1, nLocation2, nSwingCount)
	TapThat:DebugPrint("SetProgressClickTimes Width: " .. nWidth .. " Loc1: " .. nLocation1 .. " Loc2: " .. nLocation2 .. " Swings: " .. nSwingCount)
	if not tOptions.MetronomeOption then return end
	tMetronomeInfo = {} --Clear the old data
	tMetronomeInfo.bIsReversed = false
	local nWidthOverTwo = nWidth / 2
	tMetronomeInfo.isActive = true
	tMetronomeInfo.nCurrentSwing = 1
	tMetronomeInfo.Swings = {}
	tMetronomeInfo.Swings[1] = {}
	tMetronomeInfo.Swings[1].left = nLocation1 - nWidthOverTwo  --We are give the center and total width so we need (center - half width) to get the left edge
	tMetronomeInfo.Swings[1].right = nLocation1 + nWidthOverTwo --Need to know the right edge as well for when the direction reverses.
	tMetronomeInfo.Swings[2] = {}
	tMetronomeInfo.Swings[2].left = nLocation2 - nWidthOverTwo  --If there is no second button the location will be 0.
	tMetronomeInfo.Swings[2].right = nLocation2 + nWidthOverTwo --Check for values 0 or less to determine if there is a second swing or not
end

-----------------------------------------------------------------------------------------------
-- TapThat OnAcceptProgressInput
-- This event fires for Memory CSI
-- bShouldAccept if False indicates that it is displaying the button sequence
-- 	if True indicates that it is waiting for input.
-- Is only called once when bShouldAccept changes so we need a timer to handle the send events
-----------------------------------------------------------------------------------------------
function TapThat:OnAcceptProgressInput(bShouldAccept)
	if not tOptions.MemoryOption then return end
	if bShouldAccept then --Memory CSI is ready for input
		TapThat:DebugPrint("OnAcceptProgressInput true")
		tMemoryInfo.nCurrentSending = 1 --reset sending index
		Apollo.CreateTimer("TapThatMemoryTimer", 0.01, true) --Start the recurring timer.  This could also be handled with a NextFrame event handler
	else  --Memory CSI is going to show new buttons
		TapThat:DebugPrint("OnAcceptProgressInput false")
		tMemoryInfo.nCurrentShowing = 1 --Reset the showing index
		--HighlightProgressOption events will start firing with the buttons to highlight.
		
		--Hack/Workaround.
		--Calling StopTimer on a recurring timer doesnt seem to make it completely stop so remake the timer as not recurring and then call stop
		Apollo.CreateTimer("TapThatMemoryTimer", 1, false)  --make the timer not recurring
		Apollo.StopTimer("TapThatMemoryTimer")
	end
end

-----------------------------------------------------------------------------------------------
-- TapThat OnHighlightProgressOption
-- This event fires for Memory CSI
-- nButtonId the id for the button to highlight.
-- This event is fired 1 or more times after AcceptProgressInput event is raised with bShouldAccept = false
-----------------------------------------------------------------------------------------------
function TapThat:OnHighlightProgressOption(nButtonId)
	if not tOptions.MemoryOption then return end

	--Hide the start button
	local addonCSI = Apollo.GetAddon("CSI")
	if addonCSI and addonCSI.wndMemory and addonCSI.wndMemory:FindChild("StartBtnBG") then 
		addonCSI.wndMemory:FindChild("StartBtnBG"):Show(false,true)
	end

	TapThat:DebugPrint("OnHighlightProgressOption " .. nButtonId)
	--Sanity checking.  Should always be true, but who knows?
	local tActiveCSI = CSIsLib.GetActiveCSI()
	if not tActiveCSI then return end
	local eType = tActiveCSI.eType
	if not eType == CSIsLib.ClientSideInteractionType_Memory then return end
	
	if not tMemoryInfo[tMemoryInfo.nCurrentShowing] then  --new button we dont have stored yet.
		TapThat:DebugPrint("Button " .. tMemoryInfo.nCurrentShowing .. " = " .. nButtonId)
		tMemoryInfo[tMemoryInfo.nCurrentShowing] = nButtonId  --Store the button.
		--Normally only one new button is added per cycle, but we can keep adding buttons to our list until AcceptProgressInput fires
		tMemoryInfo.nCurrentShowing = tMemoryInfo.nCurrentShowing + 1
	else --already in the table means we already saw that button, but lets make sure
		if not tMemoryInfo[tMemoryInfo.nCurrentShowing] == nButtonId then
			--Shouldn't happen, but handle this situation anyways
			TapThat:DebugPrint(tMemoryInfo.nCurrentShowing .. " = " .. tMemoryInfo[tMemoryInfo.nCurrentShowing] .. " stored. " .. nButtonId .. " sent.")
			tMemoryInfo[tMemoryInfo.nCurrentShowing] = nButtonId --Update our old stored info with the new info just incase
		end
		tMemoryInfo.nCurrentShowing = tMemoryInfo.nCurrentShowing + 1
	end
end

-----------------------------------------------------------------------------------------------
-- TapThat OnHighlightProgressOption
-- TapThat function for sending inputs for Memory CSI
-- Called on a timer since only one SelectCSIOption is processed per frame.
-----------------------------------------------------------------------------------------------
function TapThat:SendMemoryInputs()
	if not tOptions.MemoryOption then return end
	if not tMemoryInfo or not tMemoryInfo.nCurrentSending then return end
	if tMemoryInfo[tMemoryInfo.nCurrentSending] then
		TapThat:DebugPrint("Sending " .. tMemoryInfo[tMemoryInfo.nCurrentSending])
		CSIsLib.SelectCSIOption(tMemoryInfo[tMemoryInfo.nCurrentSending])
		tMemoryInfo.nCurrentSending = tMemoryInfo.nCurrentSending + 1
	else
		TapThat:DebugPrint("Finished Sending Inputs")
		--Hack/Workaround.
		--Calling StopTimer on a recurring timer doesnt seem to make it completely stop so remake the timer as not recurring and then call stop
		Apollo.CreateTimer("TapThatMemoryTimer", 1, false)
		Apollo.StopTimer("TapThatMemoryTimer")
	end	
end

-----------------------------------------------------------------------------------------------
-- TapThat DebugPrint
-- TapThat function for sending debug messages only when the debug option is set
-----------------------------------------------------------------------------------------------
function TapThat:DebugPrint(sMessage)
	if not tOptions.DebugOption then return end
	Print(sMessage)
end	


-----------------------------------------------------------------------------------------------
-- TapThatForm Functions
-----------------------------------------------------------------------------------------------
function TapThat:OnInterfaceMenuListHasLoaded()
	Event_FireGenericEvent("InterfaceMenuList_NewAddOn", "TapThat", {"TapThatInterfaceList", "", ""})
	--self:UpdateInterfaceMenuAlerts()
end

function TapThat:OnConfigure()
	--TapThat:ShowOptions()
	self.wndMain:Invoke(true)
end

-- when the OK button is clicked
function TapThat:OnOK()
	tOptions.RapidTapOption = self.wndMain:FindChild("RapidTapOption"):IsChecked()
	tOptions.PressAndHoldOption = self.wndMain:FindChild("PressAndHoldOption"):IsChecked()
	tOptions.MetronomeOption = self.wndMain:FindChild("MetronomeOption"):IsChecked()
	tOptions.MemoryOption = self.wndMain:FindChild("MemoryOption"):IsChecked()
	tOptions.DebugOption = self.wndMain:FindChild("DebugOption"):IsChecked()

	self.wndMain:Close() -- hide the window
end

-- when the Cancel button is clicked
function TapThat:OnCancel()
	self.wndMain:Close() -- hide the window
end

function TapThat:ShowOptions()
	self.wndMain:Invoke(true)
end


function TapThat:OnShow(wndHandler, wndControl)
	self.wndMain:FindChild("RapidTapOption"):SetCheck(tOptions.RapidTapOption)
	self.wndMain:FindChild("PressAndHoldOption"):SetCheck(tOptions.PressAndHoldOption)
	self.wndMain:FindChild("MetronomeOption"):SetCheck(tOptions.MetronomeOption)
	self.wndMain:FindChild("MemoryOption"):SetCheck(tOptions.MemoryOption)
	self.wndMain:FindChild("DebugOption"):SetCheck(tOptions.DebugOption)
end

-----------------------------------------------------------------------------------------------
-- TapThat Instance
-----------------------------------------------------------------------------------------------
local TapThatInst = TapThat:new()
TapThatInst:Init()
