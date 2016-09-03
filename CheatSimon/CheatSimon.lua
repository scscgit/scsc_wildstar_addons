-----------------------------------------------------------------------------------------------
-- Client Lua Script for CheatSimon
-- Copyright (c) NCsoft. All rights reserved
-----------------------------------------------------------------------------------------------
 
require "Window"
require "CSIsLib"
-----------------------------------------------------------------------------------------------
-- CheatSimon Module Definition
-----------------------------------------------------------------------------------------------
local CheatSimon = {} 
 
-----------------------------------------------------------------------------------------------
-- Constants
-----------------------------------------------------------------------------------------------
 
local enumKeys = {
	{
		icon = "CRB_CSI_Memory:btn_CSI_MemoryOrangePressed",
		name = "Orange"
	},
	{
		icon = "CRB_CSI_Memory:btn_CSI_MemoryGreenPressed",
		name = "Green"
	},
	{
		icon = "CRB_CSI_Memory:btn_CSI_MemoryBluePressed",
		name = "Blue"
	},
	{
		icon = "CRB_CSI_Memory:btn_CSI_MemoryPurplePressed",
		name = "Purple"
	}
}
-----------------------------------------------------------------------------------------------
-- Initialization
-----------------------------------------------------------------------------------------------
function CheatSimon:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self 

    -- initialize variables here
	o.bFullAuto = true	

    return o
end

function CheatSimon:Init()
	local bHasConfigureFunction = false
	local strConfigureButtonText = ""
	local tDependencies = {
		-- "UnitOrPackageName",
	}
    Apollo.RegisterAddon(self, bHasConfigureFunction, strConfigureButtonText, tDependencies)
end
 

-----------------------------------------------------------------------------------------------
-- CheatSimon OnLoad
-----------------------------------------------------------------------------------------------
function CheatSimon:OnLoad()
    -- load our form file
	self.xmlDoc = XmlDoc.CreateFromFile("CheatSimon.xml")
	self.xmlDoc:RegisterCallback("OnDocLoaded", self)
end

-----------------------------------------------------------------------------------------------
-- CheatSimon OnDocLoaded
-----------------------------------------------------------------------------------------------
function CheatSimon:OnDocLoaded()

	if self.xmlDoc ~= nil and self.xmlDoc:IsLoaded() then	
		-- Register handlers for events, slash commands and timer, etc.
		Apollo.RegisterEventHandler("HighlightProgressOption", "OnHighlightProgressOption", self)
		Apollo.RegisterEventHandler("ProgressClickWindowDisplay", "OnProgressClickWindowDisplay", self) --starting a CSI
		Apollo.RegisterEventHandler("AcceptProgressInput", "OnAcceptProgressInput", self)
		-- Do additional Addon initialization here
		self.bNewSequence = true
		Apollo.RegisterTimerHandler("ButtonEnterDelay", "OnButtonEnterDelay", self)
	end
end

-----------------------------------------------------------------------------------------------
-- CheatSimon Functions
-----------------------------------------------------------------------------------------------
function CheatSimon:OnHighlightProgressOption(nOption)
	if self.bNewSequence then
		self.tKeySequence = {}
		self.nKeyCount = 0
		self.bNewSequence = false
	end
	self.nKeyCount = self.nKeyCount + 1
	self.tKeySequence[self.nKeyCount] = {id=nOption}
	self:RebuildButtonList()
end

function CheatSimon:OnProgressClickWindowDisplay(bShow)
	local tActiveCSI = CSIsLib.GetActiveCSI()
	if not tActiveCSI then
		return
	end
	if tActiveCSI.eType ~= CSIsLib.ClientSideInteractionType_Memory then return end --not memory game
	if not self.wndMain then
		self:SetUpMainWindow()
	end
	--Fix for tapthat not properly letting cheatsimon handle the memory game
	tt = Apollo.GetAddon("TapThat")
	if tt then
		tt.SendMemoryInputs = function() return end
	end

	self.bNewSequence = true
	self.tKeySequence = {}
	self:RebuildButtonList()
end

function CheatSimon:OnAcceptProgressInput(bShouldAccept)
	self.bNewSequence = true
	if bShouldAccept then
		if self.bFullAuto then
			self:AutoEnterButtons()
		end
	end
end

function CheatSimon:AutoEnterButtons()
	Apollo.CreateTimer("ButtonEnterDelay",0.1,false)
end

function CheatSimon:OnButtonEnterDelay()
	if self.tKeySequence == nil or not CSIsLib.GetActiveCSI() then --something happend, player ended event early, damage taken, etc... reset
		return 
	end --check for active game
	if #self.tKeySequence > 1 then --stop condition
		Apollo.CreateTimer("ButtonEnterDelay",0.1,false)
	end
	
	CSIsLib.SelectCSIOption(self.tKeySequence[1].id) --send first keypress
	table.remove(self.tKeySequence,1) --remove the sent keypress
	self:RebuildButtonList()
end

function CheatSimon:RebuildButtonList()
	self.wndMain:FindChild("WindowKeySequence"):DestroyChildren()
	for key,value in pairs(self.tKeySequence) do
		local wndKeyPressed = Apollo.LoadForm(self.xmlDoc, "ListKeyItem", self.wndMain:FindChild("WindowKeySequence"), self)
		wndKeyPressed:FindChild("WindowKeyName"):SetText(enumKeys[self.tKeySequence[key].id].name)
		wndKeyPressed:FindChild("WindowMemoryButton"):SetSprite(enumKeys[self.tKeySequence[key].id].icon)
		wndKeyPressed:SetText(key)
	end
	self.wndMain:FindChild("WindowKeySequence"):ArrangeChildrenVert()
end
-----------------------------------------------------------------------------------------------
-- CheatSimonForm Functions
-----------------------------------------------------------------------------------------------

function CheatSimon:OnMainFormShow( wndHandler, wndControl )
	--either showing or hiding we want to clear out the list
	self.wndMain:FindChild("WindowKeySequence"):DestroyChildren()
end

function CheatSimon:SetUpMainWindow()
	local wndCSI = Apollo.GetAddon("CSI")
	self.wndMain = Apollo.LoadForm(self.xmlDoc, "CheatSimonForm", wndCSI.wndMemory, self) --attach to carbine memory window
	self.wndMain:FindChild("ButtonToggleFullAuto"):SetCheck(self.bFullAuto)
end

function CheatSimon:OnSave(eType)
	if eType ~= GameLib.CodeEnumAddonSaveLevel.Character then
        return
	end
	tData = {}
	tData.bFullAuto = self.bFullAuto
	return tData
end

function CheatSimon:OnRestore(eType, tData)
	if eType ~= GameLib.CodeEnumAddonSaveLevel.Character then
        return
	end
	self.bFullAuto = tData.bFullAuto or true
end

function CheatSimon:OnFullAutoToggle( wndHandler, wndControl, eMouseButton )
	self.bFullAuto = not self.bFullAuto
end

-----------------------------------------------------------------------------------------------
-- CheatSimon Instance
-----------------------------------------------------------------------------------------------
local CheatSimonInst = CheatSimon:new()
CheatSimonInst:Init()
