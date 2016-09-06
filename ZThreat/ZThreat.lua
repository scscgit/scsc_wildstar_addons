-----------------------------------------------------------------------------------------------
-- Client Lua Script for ZThreat
-- Copyright (c) NCsoft. All rights reserved
-----------------------------------------------------------------------------------------------
 
require "Apollo"
require "GameLib"
require "Window"
 
-----------------------------------------------------------------------------------------------
-- ZThreat Module Definition
-----------------------------------------------------------------------------------------------
local ZThreat = {} 
 
-----------------------------------------------------------------------------------------------
-- Constants
-----------------------------------------------------------------------------------------------
-- e.g. local kiExampleVariableMax = 999
 
-----------------------------------------------------------------------------------------------
-- Initialization
-----------------------------------------------------------------------------------------------
function ZThreat:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self 

    -- initialize variables here

    return o
end

function ZThreat:Init()
	local bHasConfigureFunction = false
	local strConfigureButtonText = ""
	local tDependencies = {
		-- "UnitOrPackageName",
	}
    Apollo.RegisterAddon(self, bHasConfigureFunction, strConfigureButtonText, tDependencies)
end
 

-----------------------------------------------------------------------------------------------
-- ZThreat OnLoad
-----------------------------------------------------------------------------------------------
function ZThreat:OnLoad()
    -- load our form file
	self.xmlDoc = XmlDoc.CreateFromFile("ZThreat.xml")
	self.xmlDoc:RegisterCallback("OnDocLoaded", self)
end

-----------------------------------------------------------------------------------------------
-- ZThreat OnDocLoaded
-----------------------------------------------------------------------------------------------
function ZThreat:OnDocLoaded()

	if self.xmlDoc ~= nil and self.xmlDoc:IsLoaded() then
	    self.wndMain = Apollo.LoadForm(self.xmlDoc, "ZThreatForm", nil, self)
		if self.wndMain == nil then
			Apollo.AddAddonErrorText(self, "Could not load the main window for some reason.")
			return
		end

		-- if the xmlDoc is no longer needed, you should set it to nil
		self.xmlDoc = nil
		
		-- Register handlers for events, slash commands and timer, etc.
		-- e.g. Apollo.RegisterEventHandler("KeyDown", "OnKeyDown", self)
		Apollo.RegisterEventHandler("TargetThreatListUpdated", "OnThreatUpdated", self)
		Apollo.RegisterEventHandler("TargetUnitChanged", "OnChangedTarget", self)
		Apollo.RegisterSlashCommand("zthreat", "OnSlash", self)
		-- Do additional Addon initialization here
		
		self.wndMain:Show(false, true)
		
		-- Whether the addon is moveable.
		self.editMode = false
		
		-- Restore saved values.
		if (self.restoreData ~= nil) then
			self.wndMain:SetAnchorOffsets(unpack(self.restoreData.offsets))
			self.wndMain:SetAnchorPoints(unpack(self.restoreData.anchors))
		end
		
		ChatSystemLib.PostOnChannel(2, "Type /zthreat to toggle moving the percentage threat indicator.")
	end
end

-----------------------------------------------------------------------------------------------
-- ZThreat Functions
-----------------------------------------------------------------------------------------------
-- Define general functions here

-- on SlashCommand "/zthreat"
function ZThreat:OnSlash()
	self.editMode = not self.editMode
	self.wndMain:Show(self.editMode, true)
	self.wndMain:SetStyle("Moveable", self.editMode)
end

function ZThreat:OnSave(eLevel)
	if (eLevel ~= GameLib.CodeEnumAddonSaveLevel.Account) then
		return nil
	end
	
	local data = {
		anchors = {self.wndMain:GetAnchorPoints()},
		offsets = {self.wndMain:GetAnchorOffsets()},
	}
	return data
end

function ZThreat:OnRestore(eLevel, tData)
	if (eLevel ~= GameLib.CodeEnumAddonSaveLevel.Account) then
		return nil
	end
	self.restoreData = tData
end

-- Disappear when the user switches/deselects target.
function ZThreat:OnChangedTarget(unitTarget)
	if not self.editMode then
		self.wndMain:Show(false, true)
	end
end

-- This runs when you have aggro, so it sets the AGGRO indicator to your name and displays
-- the 2nd highest on threat below their percentage.
function ZThreat:UpdateTankDisplay(nThreat, sClose)
	self.wndMain:FindChild("Target"):SetText("AGGRO: " .. GameLib.GetPlayerUnit():GetName())
	self.wndMain:SetText(string.format("%d%%", nThreat))
	if nThreat > 90 then
		self.wndMain:SetTextColor(ApolloColor.new("magenta"))
	else
		self.wndMain:SetTextColor(ApolloColor.new("red"))
	end
	self.wndMain:FindChild("Close"):SetText(sClose)
	self.wndMain:Show(true, true)
end

-- This runs when you don't have aggro, so it sets the AGGRO indicator to the name of the
-- top threat player and clears the lower name.
function ZThreat:UpdateDPSDisplay(nTopThreat, uTopThreat, ...)
	self.wndMain:FindChild("Close"):SetText("")
	self.wndMain:Show(true, true)
	local found = false

	-- Find yourself and calculate your threat percentage.
	for i=3, select('#', ...), 2 do
		local cUnit = select(i, ...)
		local cThreat = select(i+1, ...)

		if cUnit ~= nil and cUnit == GameLib.GetPlayerUnit() then
			local val = cThreat / nTopThreat * 100
			-- Stop strange threat values (when target is taunted, etc).
			-- Negative shows as "HI" because it's impossible to have negative threat -
			-- negative threat values seem to appear when the integer type overflows.
			if (val > 200 or val < 0) then
				self.wndMain:SetText("HI%")
			else
				self.wndMain:SetText(string.format("%d%%", val))
			end
			if val > 90 or val < 0 then
				self.wndMain:SetTextColor(ApolloColor.new("yellow"))
			else
				self.wndMain:SetTextColor(ApolloColor.new("green"))
			end
			self.wndMain:FindChild("Target"):SetText("AGGRO: " .. uTopThreat:GetName())
			found = true
			break
		end
	end

	-- XXX: Fix for disappearing mid-raid: assume the player is too low on the DPS meter to show up.
	if not found then
		self.wndMain:SetText("LO%")
		self.wndMain:SetTextColor(ApolloColor.new("green"))
		self.wndMain:FindChild("Target"):SetText("AGGRO: " .. uTopThreat:GetName())
	end
end

-- This changes the AGGRO indicator to red when the target is Taunted (i.e. forced to
-- attack the target). This is done in order to clarify that you are incapable of pulling
-- threat and that the current threat percentage may be drastically skewed.
function ZThreat:UpdateTauntStatus()
	local targetDebuffs = GameLib.GetTargetUnit():GetBuffs().arHarmful
	self.wndMain:FindChild("Target"):SetTextColor(ApolloColor.new("white"))
	for _, debuff in pairs(targetDebuffs) do
		debuffName = debuff.splEffect:GetName()
		-- These are the four "Taunt" abilities. Intimidates don't count, as they don't
		-- technically force the target to attack the tank.
		if      debuffName == "Reaver" or
				debuffName == "Plasma Blast" or
				debuffName == "Blitz" or
				debuffName == "Code Red" then
			self.wndMain:FindChild("Target"):SetTextColor(ApolloColor.new("red"))
			break;
		end
	end
end

-- Determines whether to update as if the player is a tank or as if the player is a non-tank based
-- on whether the player is the highest on the threat table.
function ZThreat:OnThreatUpdated(...)
	if select(1, ...) ~= nil then
		local topThreatUnit = select(1, ...)
		local topThreatValue = select(2, ...)
		if topThreatUnit == GameLib.GetPlayerUnit() then
			if select(3, ...) ~= nil then
				self:UpdateTankDisplay(select(4, ...) / topThreatValue * 100, select(3, ...):GetName())
			else
				self.wndMain:Show(false, true)
				return
			end
		else
			self:UpdateDPSDisplay(topThreatValue, topThreatUnit, ...)
		end
		self:UpdateTauntStatus()
	end
end

-----------------------------------------------------------------------------------------------
-- ZThreat Instance
-----------------------------------------------------------------------------------------------
local ZThreatInst = ZThreat:new()
ZThreatInst:Init()
