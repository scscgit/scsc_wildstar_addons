-----------------------------------------------------------------------------------------------
-- Client Lua Script for Gear_Mount
-- Copyright (c) NCsoft. All rights reserved
-----------------------------------------------------------------------------------------------
 
-----------------------------------------------------------------------------------------------
-- Gear_Mount Module Definition
-----------------------------------------------------------------------------------------------
local Gear_Mount = {} 

-----------------------------------------------------------------------------------------------
-- Localisation
-----------------------------------------------------------------------------------------------
local L = Apollo.GetPackage("Gemini:Locale-1.0").tPackage:GetLocale("Gear_Mount", true)
 
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
local GP_NAME = "Gear_Mount"

-----------------------------------------------------------------------------------------------
-- Plugin data
-----------------------------------------------------------------------------------------------
local tPlugin =   {
							name = GP_NAME,						-- addon name
						 version = GP_VER,						-- addon version
						  flavor = L["GP_FLAVOR"],				-- addon description
						    icon = "LOADED FROM GEAR",          -- icon plugin name for setting and ui_setting, loaded from 'gear'
						      on = true,						-- enable/disable
						 setting = {							-- setting for settings gear 
									name = L["GP_O_SETTINGS"],  -- setting name to view in gear setting window
									-- parent setting 
									[1] =  {
											[1] = { sType = "toggle", bActived = true, sDetail = L["GP_O_SETTING_1"],}, -- don't use mount las
											}, 
									},   
									
					  ui_setting = {							-- ui setting for gear profil
																-- sType = 'toggle_unique' (on/off state, only once can be enabled in all profil, but all can be disabled)
																-- sType = 'toggle' (on/off state)
																-- sType = 'push' (on click state)
																-- sType = 'none' (no state, only icon to identigy the plugin)
					  		  
					  
									 
									    	[1] = { sType = "toggle_unique", Saved = nil,},  -- first setting button is always the plugin icon
											
									},   			
							 
					}

-- comm timer to init plugin	
local tComm, bCall
				
-----------------------------------------------------------------------------------------------
-- Initialization
-----------------------------------------------------------------------------------------------
function Gear_Mount:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self 
    return o
end

function Gear_Mount:Init()
	Apollo.RegisterAddon(self, false, nil, {"Gear"})
end
 
-----------------------------------------------------------------------------------------------
-- OnLoad
-----------------------------------------------------------------------------------------------
function Gear_Mount:OnLoad()
	Apollo.RegisterEventHandler("Generic_GEAR_PLUGIN", "ON_GEAR_PLUGIN", self)      -- add event to communicate with gear
   	tComm  = ApolloTimer.Create(1, true, "_Comm", self) 							-- init comm for plugin
end

---------------------------------------------------------------------------------------------------
-- _Comm
---------------------------------------------------------------------------------------------------
function Gear_Mount:_Comm() 
		
	if lGear._isaddonup("Gear")	then												-- if 'gear' is running , go next
		tComm:Stop()
		tComm = nil 																-- stop init comm timer
		if bCall == nil then lGear.initcomm(tPlugin) end 							-- send information about me, setting etc..
	end
end

-----------------------------------------------------------------------------------------------
--- all plugin communicate with gear in this function
-----------------------------------------------------------------------------------------------
function Gear_Mount:ON_GEAR_PLUGIN(sAction, tData)
	
	-- answer come from gear, the gear version, gear is up 
	if sAction == "G_VER" and tData.owner == GP_NAME then
		
		if bCall ~= nil then return end
		bCall = true
		
		-- get actual ngearid equipped
		Event_FireGenericEvent("Generic_GEAR_PLUGIN", "G_GET_LASTGEAR", nil)

		-- init mount event (on/off)
		self:MO_IniMount(tPlugin.on) 				
	end
	
	-- answer come from gear, the setting plugin are updated, if this information is for me go next
	if sAction == "G_SETTING" and tData.owner == GP_NAME then
		-- update setting status
		tPlugin.setting[1][tData.option].bActived = tData.actived
	end
	
	-- answer come from gear, the ui setting plugin update, if this information is for me go next
	if sAction == "G_UI_SETTING" and tData.owner == GP_NAME then
		-- update mount/gearid link
		tPlugin.ui_setting[1].Saved = tData.saved
	end
		
	-- action request come from gear, the plugin are enable or disable, if this information is for me go next
	if sAction == "G_ON" and tData.owner == GP_NAME then
		-- update enable/disable status
		tPlugin.on = tData.on 														
				
		-- get actual ngearid equipped
	    Event_FireGenericEvent("Generic_GEAR_PLUGIN", "G_GET_LASTGEAR", nil)

		-- init mount event (on/off)
		self:MO_IniMount(tPlugin.on) 
	end
	
	-- answer come from gear, the last ngearid equipped
	if sAction == "G_LASTGEAR" then
		self.nPrevGearId = tData.ngearid
	end
	
	-- answer come from gear, the gear set equiped
	if sAction == "G_CHANGE" then
		
		if tData.ngearid ~= tPlugin.ui_setting[1].Saved then
			self.nPrevGearId = tData.ngearid
		end
	end
					
	-- answer come from gear, a gear set deleted
	if sAction == "G_DELETE" then
			
		local nGearId = tData
		if tPlugin.ui_setting[1].Saved == nGearId then tPlugin.ui_setting[1].Saved = nil end
	end
end

-----------------------------------------------------------------------------------------------
-- InitMount
-----------------------------------------------------------------------------------------------
function Gear_Mount:MO_IniMount(bActivate)
	-- watch mount event
	if bActivate then 
		Apollo.RegisterEventHandler("Mount", "MO_OnMount", self)
	elseif not bActivate then
		Apollo.RemoveEventHandler("Mount")
	end
end

-----------------------------------------------------------------------------------------------
-- OnMount
-----------------------------------------------------------------------------------------------
function Gear_Mount:MO_OnMount()

	if not tPlugin.on then return end
		
    local uPlayer = GameLib.GetPlayerUnit()
	local bMounted = uPlayer:IsMounted()
	local nGearIdMount = tPlugin.ui_setting[1].Saved
	
	-- filter to prevent 'mount event fired' after use a jump in battleground
	if bMounted and GameLib.GetPlayerMountUnit() == nil then return end
	if not bMounted and self.bComeFromMount == nil then 
		self.bComeFromMount = nil
		return
	end
		
	local nId = nil
		
	-- we have equipped a mount and have a gear selected to use
	if bMounted and nGearIdMount ~= nil then
		nId = nGearIdMount
		self.bComeFromMount = true
	end
	
	-- we have unequipped a mount and have a previous gear selected to use
	if not bMounted and self.nPrevGearId ~= nil then 
		nId = self.nPrevGearId
	end
	
	if nId == nil then return end
		
	local tFunc = { ngearid = nId, func = { "SELECT", "EQUIP", "LAS",},}
	-- option 'dont use las from mount' is off
	if tPlugin.setting[1][1].bActived then
		tFunc.func = { "SELECT", "EQUIP",}
	end
		
	-- request to 'gear' to equip gear mount and use las/cos
	Event_FireGenericEvent("Generic_GEAR_PLUGIN", "G_SET_FUNC", tFunc)
end

---------------------------------------------------------------------------------------------------
-- OnSave
---------------------------------------------------------------------------------------------------
function Gear_Mount:OnSave(eLevel)
	
	if eLevel ~= GameLib.CodeEnumAddonSaveLevel.Character then return end 
		
	local tData = { }
	      tData.config = {
	                            ver = GP_VER,
								 on = tPlugin.on,
						   lasmount = tPlugin.setting[1][1].bActived,
							  mount = tPlugin.ui_setting[1].Saved,
						 }
	return tData
end 

---------------------------------------------------------------------------------------------------
-- OnRestore
---------------------------------------------------------------------------------------------------
function Gear_Mount:OnRestore(eLevel,tData) 
	
	if eLevel ~= GameLib.CodeEnumAddonSaveLevel.Character then return end
	if tData.config.on ~= nil then tPlugin.on = tData.config.on end
	if tData.config.lasmount ~= nil then tPlugin.setting[1][1].bActived = tData.config.lasmount end
	if tData.config.mount ~= nil then tPlugin.ui_setting[1].Saved = tData.config.mount end
end 

-----------------------------------------------------------------------------------------------
-- Gear_Mount Instance
-----------------------------------------------------------------------------------------------
local Gear_MountInst = Gear_Mount:new()
Gear_MountInst:Init()
