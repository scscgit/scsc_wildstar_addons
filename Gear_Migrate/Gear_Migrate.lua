-----------------------------------------------------------------------------------------------
-- Client Lua Script for Gear_Migrate
-- Copyright (c) NCsoft. All rights reserved
-----------------------------------------------------------------------------------------------
 
-----------------------------------------------------------------------------------------------
-- Gear_Migrate Module Definition
-----------------------------------------------------------------------------------------------
local Gear_Migrate = {} 
 
-----------------------------------------------------------------------------------------------
-- Constants
-----------------------------------------------------------------------------------------------
-- version
local Major, Minor, Patch = 1, 0, 3 
local GP_VER = string.format("%d.%d.%d", Major, Minor, Patch)
local GP_NAME = "Gear_Migrate"
			
-----------------------------------------------------------------------------------------------
-- Initialization
-----------------------------------------------------------------------------------------------
function Gear_Migrate:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self 
    return o
end

function Gear_Migrate:Init()
	Apollo.RegisterAddon(self, false, nil, {"Gear"})
end
 
-----------------------------------------------------------------------------------------------
-- OnLoad
-----------------------------------------------------------------------------------------------
function Gear_Migrate:OnLoad()
	--
end

-----------------------------------------------------------------------------------------------
-- Gear_Migrate Instance
-----------------------------------------------------------------------------------------------
local Gear_MigrateInst = Gear_Migrate:new()
Gear_MigrateInst:Init()
