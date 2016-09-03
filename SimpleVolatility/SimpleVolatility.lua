-----------------------------------------------------------------------------------------------
-- Client Lua Script for SimpleVolatility
-- Copyright (c) NCsoft. All rights reserved
-----------------------------------------------------------------------------------------------
 
require "Apollo"
require "GameLib"
require "Window"
require "Unit"

-------------------------------------------------------------------------------------
-- SimpleVolatility Module Definition
-----------------------------------------------------------------------------------------------
local SimpleVolatility = {} 
local run = true

-----------------------------------------------------------------------------------------------
-- Initialization
-----------------------------------------------------------------------------------------------
function SimpleVolatility:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self 

    -- initialize variables here

    return o
end

function SimpleVolatility:Init()
	local bHasConfigureFunction = false
	local strConfigureButtonText = ""
	local tDependencies = {"ClassResources"}
    Apollo.RegisterAddon(self, bHasConfigureFunction, strConfigureButtonText, tDependencies)
end
 
-----------------------------------------------------------------------------------------------
-- SimpleVolatility OnLoad
-----------------------------------------------------------------------------------------------
function SimpleVolatility:OnLoad()
	self:InitializeHooks()	
end

function SimpleVolatility:InitializeHooks()
	local crb = Apollo.GetAddon("ClassResources")
	crb.OnEngineerUpdateTimer = self.OnEngineerUpdateTimer
end


function SimpleVolatility:OnEngineerUpdateTimer()
	local unitPlayer = GameLib.GetPlayerUnit()
	local bInCombat = unitPlayer:IsInCombat()
	local nResourceCurrent = unitPlayer:GetResource(1)
	if self.bLastInCombat == bInCombat and self.nLastCurrent == nResourceCurrent then
		return
	end
	self.bLastInCombat = bInCombat
	self.nLastCurrent = nResourceCurrent
	
	local nResourceMax = unitPlayer:GetMaxResource(1)
	local nResourcePercent = nResourceCurrent / nResourceMax
	
	self.tWindowMap["MainResourceFrame"]:SetSprite("") -- remove background art from Resource Bar
	
	self.tWindowMap["ProgressBar"]:SetMax(nResourceMax)
	self.tWindowMap["ProgressBar"]:SetProgress(nResourceCurrent)
	self.tWindowMap["ProgressText"]:SetText(String_GetWeaselString(Apollo.GetString("CRB_ProgressSimple"), nResourceCurrent, nResourceMax))
	self.tWindowMap["ProgressBacker"]:Show(nResourcePercent > 0) -- change
	self.tWindowMap["ProgressBacker"]:SetBGColor("UI_AlphaPercent25")

	if nResourcePercent <= .05 then
		self.tWindowMap["ProgressBar"]:SetStyleEx("EdgeGlow", false)
		self.tWindowMap["LeftCap"]:Show(true)
		self.tWindowMap["RightCap"]:Show(false)
	elseif nResourcePercent > .05 and nResourcePercent < .95 then
		self.tWindowMap["ProgressBar"]:SetStyleEx("EdgeGlow", true)
		self.tWindowMap["LeftCap"]:Show(false)
		self.tWindowMap["RightCap"]:Show(false)
	elseif nResourcePercent >= .95 then
		self.tWindowMap["ProgressBar"]:SetStyleEx("EdgeGlow", false)
		self.tWindowMap["LeftCap"]:Show(false)
		self.tWindowMap["RightCap"]:Show(true)
	end

	if nResourcePercent > 0 and nResourcePercent < 0.3 then
		self.tWindowMap["ProgressText"]:SetTextColor("xkcdNeonBlue")
		self.tWindowMap["ProgressBar"]:SetFullSprite("spr_CM_Engineer_BarFill_InCombat1")
		self.tWindowMap["ProgressBar"]:SetGlowSprite("spr_CM_Engineer_BarEdgeGlow_InCombat1")
	elseif nResourcePercent >= 0.3 and nResourcePercent <= 0.7 then
		self.tWindowMap["ProgressText"]:SetTextColor("xkcdNeonYellow")
		self.tWindowMap["ProgressBar"]:SetFullSprite("spr_CM_Engineer_BarFill_InCombat2")
		self.tWindowMap["ProgressBar"]:SetGlowSprite("spr_CM_Engineer_BarEdgeGlow_InCombat2")
	elseif nResourcePercent > 0.7 and nResourcePercent < 1 then
		self.tWindowMap["ProgressText"]:SetTextColor("UI_TextHoloBodyHighlight")
		self.tWindowMap["ProgressBar"]:SetFullSprite("spr_CM_Engineer_BarFill_InCombat1")
		self.tWindowMap["ProgressBar"]:SetGlowSprite("spr_CM_Engineer_BarEdgeGlow_InCombat1")
	elseif nResourcePercent == 1 then
		self.tWindowMap["ProgressText"]:SetTextColor("xkcdNeonGreen")
		self.tWindowMap["ProgressBar"]:SetFullSprite("spr_CM_Engineer_BarFill_InCombat3")
		self.tWindowMap["ProgressBar"]:SetGlowSprite("spr_CM_Engineer_BarEdgeGlow_InCombat2")	
	else
		self.tWindowMap["ProgressText"]:SetTextColor("UI_AlphaPercent0")
		self.tWindowMap["ProgressBar"]:SetFullSprite("spr_CM_Engineer_BarFill_OutOfCombat")
		self.tWindowMap["ProgressBar"]:SetGlowSprite("spr_CM_Engineer_BarEdgeGlow_OutOfCombat")
	end

	--if GameLib.IsCurrentInnateAbilityActive() then
		--self.tWindowMap["ProgressBar"]:SetFullSprite("spr_CM_Engineer_BarFill_InCombat3")
		--self.tWindowMap["MainResourceFrame"]:SetSprite("spr_CM_Engineer_Base_Innate")
	--elseif bInCombat then
		--self.tWindowMap["MainResourceFrame"]:SetSprite("spr_CM_Engineer_Base_InCombat")
	--else
		--self.tWindowMap["MainResourceFrame"]:SetSprite("spr_CM_Engineer_Base_OutOfCombat")
	--end
end

-----------------------------------------------------------------------------------------------
-- SimpleVolatility Instance
-----------------------------------------------------------------------------------------------
local SimpleVolatilityInst = SimpleVolatility:new()
SimpleVolatilityInst:Init()
