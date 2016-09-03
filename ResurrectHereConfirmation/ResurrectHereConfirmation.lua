-----------------------------------------------------------------------------------------------
-- Client Lua Script for ResurrectHereConfirmation
-- Copyright (c) NCsoft. All rights reserved
-----------------------------------------------------------------------------------------------
 
require "Window"
 
-----------------------------------------------------------------------------------------------
-- ResurrectHereConfirmation Module Definition
-----------------------------------------------------------------------------------------------
local ResurrectHereConfirmation = {} 
 
-----------------------------------------------------------------------------------------------
-- Constants
-----------------------------------------------------------------------------------------------
-- e.g. local kiExampleVariableMax = 999
 
-----------------------------------------------------------------------------------------------
-- Initialization
-----------------------------------------------------------------------------------------------
function ResurrectHereConfirmation:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self 

    -- initialize variables here

    return o
end

function ResurrectHereConfirmation:Init()
	local bHasConfigureFunction = false
	local strConfigureButtonText = ""
	local tDependencies = {"Death"}
    Apollo.RegisterAddon(self, bHasConfigureFunction, strConfigureButtonText, tDependencies)
end
 

-----------------------------------------------------------------------------------------------
-- ResurrectHereConfirmation OnLoad
-----------------------------------------------------------------------------------------------
function ResurrectHereConfirmation:OnLoad()
    -- load our form file
	self.xmlDoc = XmlDoc.CreateFromFile("ResurrectHereConfirmation.xml")
	
	Apollo.RegisterSlashCommand("resurrect", "OnForceResurrect", self)
	
	self.Death = Apollo.GetAddon("Death") 		--know about the death addon..
	self:InitializeHooks()						--and hook into it
end

-----------------------------------------------------------------------------------------------
-- ResurrectHereConfirmation Functions
-----------------------------------------------------------------------------------------------
function ResurrectHereConfirmation:InitializeHooks()
	local fnOldOnResurrectHere = self.Death.OnResurrectHere
	self.Death.OnResurrectHere = function(tDeath)	
		tDeath.wndHereConfirm = Apollo.LoadForm(self.xmlDoc, "ResurrectHereDialog", nil, self.Death)
		tDeath.wndHereConfirm:Show(true)
		tDeath.wndResurrect:Show(false)
	end
	
	self.Death.OnConfirmResurrectHere = function(tDeath)
		tDeath.wndHereConfirm:Destroy()
		fnOldOnResurrectHere(tDeath)
	end
	
	self.Death.OnCancelResurrectHere = function(tDeath)
		tDeath.wndHereConfirm:Destroy()
		tDeath.wndResurrect:Show(true)
	end
end

function ResurrectHereConfirmation:OnForceResurrect()
	GameLib.GetPlayerUnit():Resurrect(2, 0)			--at nearest holocrypt
end


-----------------------------------------------------------------------------------------------
-- ResurrectHereConfirmation Instance
-----------------------------------------------------------------------------------------------
local ResurrectHereConfirmationInst = ResurrectHereConfirmation:new()
ResurrectHereConfirmationInst:Init()
