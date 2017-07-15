-----------------------------------------------------------------------------------------------
-- Copyright 2015 (c) Jos_eu. All rights reserved
-- This file is part of CalmMarketplaceBtn.
-----------------------------------------------------------------------------------------------
 
require "Window"
 
local CalmMarketplaceBtn = {} 

function CalmMarketplaceBtn:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self 
    return o
end

function CalmMarketplaceBtn:Init()
	local bHasConfigureFunction = false
	local strConfigureButtonText = ""
	local tDependencies = {
		"InterfaceMenuList",
	}
    Apollo.RegisterAddon(self, bHasConfigureFunction, strConfigureButtonText, tDependencies)
end

function CalmMarketplaceBtn:OnDependencyError(strDependency, strError)
  -- ignore dependency errors, because we only did set dependecies to ensure to get loaded after the specified addons
	return true
end

function CalmMarketplaceBtn:OnLoad()
	local aInterfaceMenuList = Apollo.GetAddon("InterfaceMenuList")
	if aInterfaceMenuList and aInterfaceMenuList.wndMain then
		OverwriteMarketplaceBtnSprites(aInterfaceMenuList)
	else
		Apollo.RegisterTimerHandler("CalmMarketplaceBtn_Initialize", "OnCalmMarketplaceBtnInitialize", self)
		Apollo.CreateTimer("CalmMarketplaceBtn_Initialize", 1, false)
	end
end

function CalmMarketplaceBtn:OnCalmMarketplaceBtnInitialize()
	local aInterfaceMenuList = Apollo.GetAddon("InterfaceMenuList")
	if aInterfaceMenuList and aInterfaceMenuList.wndMain then
		Apollo.StopTimer("CalmMarketplaceBtn_Initialize")
		OverwriteMarketplaceBtnSprites(aInterfaceMenuList)
	else
		Apollo.StartTimer("CalmMarketplaceBtn_Initialize")
	end
end

function OverwriteMarketplaceBtnSprites(aInterfaceMenuList)
	local wndBtn = aInterfaceMenuList.wndMain:FindChild("OpenMarketplaceBtn")
	local wnd	= wndBtn:FindChild("MTXBtn_Runner")
	if wnd then
		wnd:SetSprite("ClientSprites:Clear")
	end
	wndBtn = aInterfaceMenuList.wndMain:FindChild("MTX")
	wnd = wndBtn:FindChild("CoinsPendingAnim")
	if wnd then
		wnd:SetSprite("ClientSprites:Clear")
	end
end

local CalmMarketplaceBtnInst = CalmMarketplaceBtn:new()
CalmMarketplaceBtnInst:Init()
