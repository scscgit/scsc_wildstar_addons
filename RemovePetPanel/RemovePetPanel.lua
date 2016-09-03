-----------------------------------------------------------------------------------------------
-- Client Lua Script for RemovePetPanel
-- Copyright (c) NCsoft. All rights reserved
-----------------------------------------------------------------------------------------------
 
require "Window"
require "Apollo"
 
-----------------------------------------------------------------------------------------------
-- RemovePetPanel Module Definition
-----------------------------------------------------------------------------------------------
local RemovePetPanel = {} 
 
-----------------------------------------------------------------------------------------------
-- Initialization
-----------------------------------------------------------------------------------------------
function RemovePetPanel:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self 

    -- initialize variables here

    return o
end

function RemovePetPanel:Init()
	local bHasConfigureFunction = false
	local strConfigureButtonText = ""
	local tDependencies = {
	--ClassResources, ResourceReplace,
	}
    Apollo.RegisterAddon(self, bHasConfigureFunction, strConfigureButtonText, tDependencies)
end
 
-----------------------------------------------------------------------------------------------
-- RemovePetPanel OnLoad
-----------------------------------------------------------------------------------------------
function RemovePetPanel:OnLoad()
	self:InitializeHooks()
end

function RemovePetPanel:InitializeHooks()
	local crb = Apollo.GetAddon("ClassResources")
	if crb == nil then
		crb = Apollo.GetAddon("ResourceReplace")
	end	
	if crb ~= nil then
		crb.OnShowActionBarShortcut = self.OnShowActionBarShortcut
	end	
end

-----------------------------------------------------------------------------------------------
-- RemovePetPanel Functions
-----------------------------------------------------------------------------------------------
-- Define general functions here

function RemovePetPanel:OnShowActionBarShortcut(nWhichBar, bIsVisible, nNumShortcuts)
	if nWhichBar ~= 1 or not self.wndMain or not self.wndMain:IsValid() then -- 1 is hardcoded to be the engineer pet bar
		return
	end

	self.wndMain:FindChild("PetBtn"):Show(false) -- hide Pet Button
	self.wndMain:FindChild("PetBarContainer"):Show(false) -- Hide Pet Container
end

-----------------------------------------------------------------------------------------------
-- RemovePetPanel Instance
-----------------------------------------------------------------------------------------------
local RemovePetPanelInst = RemovePetPanel:new()
RemovePetPanelInst:Init()

