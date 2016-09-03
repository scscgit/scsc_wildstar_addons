-----------------------------------------------------------------------------------------------
-- Client Lua Script for Gear_Migrate
-- Copyright (c) NCsoft. All rights reserved
-----------------------------------------------------------------------------------------------
 
-----------------------------------------------------------------------------------------------
-- Gear_Migrate Module Definition
-----------------------------------------------------------------------------------------------
local Gear_Migrate = {} 

-----------------------------------------------------------------------------------------------
-- Localisation
-----------------------------------------------------------------------------------------------
local L = Apollo.GetPackage("Gemini:Locale-1.0").tPackage:GetLocale("Gear_Migrate", true)
 
-----------------------------------------------------------------------------------------------
-- Lib gear
-----------------------------------------------------------------------------------------------
local lGear = Apollo.GetPackage("Lib:LibGear-1.0").tPackage 
 
-----------------------------------------------------------------------------------------------
-- Constants
-----------------------------------------------------------------------------------------------
-- version
local Major, Minor, Patch = 1, 0, 2 
local GP_VER = string.format("%d.%d.%d", Major, Minor, Patch)
local GP_NAME = "Gear_Migrate"

-----------------------------------------------------------------------------------------------
-- Plugin data
-----------------------------------------------------------------------------------------------
local tPlugin =   {
							name = GP_NAME,						-- addon name
						 version = GP_VER,						-- addon version
						  flavor = L["GP_FLAVOR"],				-- addon description
						    icon = nil,   				        -- icon plugin name for setting and ui_setting, loaded from 'gear'
						      on = true,						-- enable/disable
						 setting = {
									name = L["GP_O_SETTINGS"], -- setting name to view in gear setting window
									
									[1] =  {}, 
									},   
				 
					}

-- comm timer to init plugin	
local tComm, bCall, tMigrat 	
-- to know if migration is over
local bMigrateEnd = false
			
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
	Apollo.RegisterEventHandler("Generic_GEAR_PLUGIN", "ON_GEAR_PLUGIN", self)      -- add event to communicate with gear
	tComm  = ApolloTimer.Create(1, true, "_Comm", self) 							-- init comm for plugin
end

---------------------------------------------------------------------------------------------------
-- _Comm
---------------------------------------------------------------------------------------------------
function Gear_Migrate:_Comm() 
		
	if lGear._isaddonup("Gear")	then												-- if 'gear' is running , go next
		tComm = nil 																-- stop init comm timer
		if bCall == nil then lGear.initcomm(tPlugin) end 							-- send information about me, setting etc..
	end
end

-----------------------------------------------------------------------------------------------
--- all plugin communicate with gear in this function
-----------------------------------------------------------------------------------------------
function Gear_Migrate:ON_GEAR_PLUGIN(sAction, tData)
	
	-- answer come from gear, the gear version, gear is up 
	if sAction == "G_VER" and tData.owner == GP_NAME then
		
		if bCall ~= nil then return end
		bCall = true
					
		if tPlugin.on then
			-- request last gear array
			Event_FireGenericEvent("Generic_GEAR_PLUGIN", "G_GET_GEAR", nil)
		end
	end
		
	-- answer come from gear, the gear array updated
	if sAction == "G_GEAR" then 
						
		if tPlugin.on and tData and not bMigrateEnd then
			-- start migration
			self.tData = tData
			tMigrat  = ApolloTimer.Create(1 ,true, "_Migration", self)
		end
	end
		
	-- action request come from gear, the plugin are enable or disable, if this information is for me go next
	if sAction == "G_ON" and tData.owner == GP_NAME then
		tPlugin.on = tData.on
	end
end

---------------------------------------------------------------------------------------------------
-- Migration
---------------------------------------------------------------------------------------------------
function Gear_Migrate:_Migration() 
	if GameLib.IsCharacterLoaded() and GameLib.GetPlayerUnit() ~= nil and bCall then
	    if tMigrat then self:CheckFormat(self.tData) end 
	end
end

---------------------------------------------------------------------------------------------------
-- CheckFormat
---------------------------------------------------------------------------------------------------
function Gear_Migrate:CheckFormat(tData)

        tMigrat = nil 
		self.tData = nil
				
		local tSaved = tData
		local tTempGear = {}
		
		for nGearId, peCurrent in pairs(tSaved) do
		    		 
		    tTempGear[nGearId] = {}  
			
			for nIdx, peCurrent in pairs(tSaved[nGearId]) do		
			
				if tonumber(nIdx) and tonumber(nIdx) ~= 6 and tonumber(nIdx) ~= 9 then 
							           
					local sLink = tSaved[nGearId][nIdx]
					local oItem = lGear._SearchInEquipped(sLink)
					local nSlot = nil
			
					if oItem then
						nSlot = oItem:GetSlot()
					elseif oItem == nil then 
						oItem = lGear._SearchInBag(sLink)
			    		if oItem then
							nSlot = oItem:GetSlot() 
						elseif oItem == nil then
							oItem = lGear._SearchInBank(sLink)
							if oItem then
								nSlot = oItem:GetSlot()
							end			
						end
					end
	                	                
					if nSlot then
						tTempGear[nGearId][nSlot] = sLink
					end
								
					local bAppendThis = true
					
					if nSlot == nil and sLink then
						for nSlotVerified, peCurrent in pairs(tTempGear[nGearId]) do
							if nIdx == nSlotVerified then bAppendThis = false end
						end	
																								
						if bAppendThis == true then tTempGear[nGearId][nIdx] = sLink end
					end
				end	
			end
						
			tTempGear[nGearId].name = tSaved[nGearId].name
			tTempGear[nGearId].macro = tSaved[nGearId].macro
						
			if tSaved[nGearId].las then
				tTempGear[nGearId].las = tSaved[nGearId].las
			end
		end 
				
	-- we request we want send gear array	
	local tNewGear = { gear = tTempGear }
	Event_FireGenericEvent("Generic_GEAR_PLUGIN", "G_SET_ARRAY", tNewGear)
	bMigrateEnd = true
end

---------------------------------------------------------------------------------------------------
-- OnSave
---------------------------------------------------------------------------------------------------
function Gear_Migrate:OnSave(eLevel)
	
	if eLevel ~= GameLib.CodeEnumAddonSaveLevel.Character then return end 
		
	local tData = { }
	      tData.config = {
	                            ver = GP_VER,
								 on = tPlugin.on,
						 }
		
	return tData
end 

---------------------------------------------------------------------------------------------------
-- OnRestore
---------------------------------------------------------------------------------------------------
function Gear_Migrate:OnRestore(eLevel,tData) 
	
	if eLevel ~= GameLib.CodeEnumAddonSaveLevel.Character then return end
	if tData.config.on ~= nil then tPlugin.on = tData.config.on end
end 

-----------------------------------------------------------------------------------------------
-- Gear_Migrate Instance
-----------------------------------------------------------------------------------------------
local Gear_MigrateInst = Gear_Migrate:new()
Gear_MigrateInst:Init()
