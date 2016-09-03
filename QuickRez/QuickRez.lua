-----------------------------------------------------------------------------------------------
-- Client Lua Script for QuickRez
-- Copyright (c) NCsoft. All rights reserved
-----------------------------------------------------------------------------------------------
 
require "Window"
 
-----------------------------------------------------------------------------------------------
-- QuickRez Module Definition
-----------------------------------------------------------------------------------------------
local QuickRez = {}
 
-----------------------------------------------------------------------------------------------
-- Initialization
-----------------------------------------------------------------------------------------------
function QuickRez:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

function QuickRez:Init()
	local bHasConfigureFunction = false
	local strConfigureButtonText = ""
	local tDependencies = {
	}
    Apollo.RegisterAddon(self, bHasConfigureFunction, strConfigureButtonText, tDependencies)
end
 

-----------------------------------------------------------------------------------------------
-- QuickRez OnLoad
-----------------------------------------------------------------------------------------------
function QuickRez:OnLoad()
    -- load our form file
	self.xmlDoc = XmlDoc.CreateFromFile("QuickRez.xml")
	self.xmlDoc:RegisterCallback("OnDocLoaded", self)
end

-----------------------------------------------------------------------------------------------
-- QuickRez OnDocLoaded
-----------------------------------------------------------------------------------------------
function QuickRez:OnDocLoaded()
	if self.xmlDoc ~= nil and self.xmlDoc:IsLoaded() then
		self.xmlDoc = nil

		Apollo.RegisterEventHandler("CasterResurrectedPlayer", "OnCasterResurrectedPlayer", self)
		Apollo.RegisterSlashCommand("qr", "OnQuickRezToggle", self)
	end
end

-----------------------------------------------------------------------------------------------
-- QuickRez Functions
------------------------------------------------------	-----------------------------------------
function QuickRez:OnCasterResurrectedPlayer()
	Apollo.RegisterEventHandler("NextFrame", "AttemptToRez", self)
end

function QuickRez:AttemptToRez()
	if GameLib.GetPlayerUnit() ~= nil then
		if not GameLib.GetPlayerUnit():IsDead() then
			Apollo.RemoveEventHandler("NextFrame", self)
			if Apollo.FindWindowByName("ResurrectDialog") ~= nil then
				Apollo.FindWindowByName("ResurrectDialog"):Show(false)
			end
		else
			GameLib.GetPlayerUnit():Resurrect(4, 0)
		end
	end
end


-----------------------------------------------------------------------------------------------
-- QuickRez Instance
-----------------------------------------------------------------------------------------------
local QuickRezInst = QuickRez:new()
QuickRezInst:Init()
