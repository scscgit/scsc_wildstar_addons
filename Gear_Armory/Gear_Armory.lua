-----------------------------------------------------------------------------------------------
-- Client Lua Script for Gear_Armory
-- Copyright (c) NCsoft. All rights reserved
-----------------------------------------------------------------------------------------------
 
-----------------------------------------------------------------------------------------------
-- Gear_Armory Module Definition
-----------------------------------------------------------------------------------------------
local Gear_Armory = {} 

-----------------------------------------------------------------------------------------------
-- Localisation
-----------------------------------------------------------------------------------------------
local L = Apollo.GetPackage("Gemini:Locale-1.0").tPackage:GetLocale("Gear_Armory", true)
 
-----------------------------------------------------------------------------------------------
-- Lib gear
-----------------------------------------------------------------------------------------------
local LG = Apollo.GetPackage("Lib:LibGear-1.0").tPackage 
 
-----------------------------------------------------------------------------------------------
-- Constants
-----------------------------------------------------------------------------------------------
-- version
local Major, Minor, Patch = 1, 0, 3 
local GP_VER = string.format("%d.%d.%d", Major, Minor, Patch)
local GP_NAME = "Gear_Armory"

-----------------------------------------------------------------------------------------------
-- Plugin data
-----------------------------------------------------------------------------------------------
local tPlugin =   {
							name = GP_NAME,						-- addon name
						 version = GP_VER,						-- addon version
						  flavor = L["GP_FLAVOR"],				-- addon description
						    icon = "LOADED FROM GEAR",          -- icon plugin name for setting and ui_setting, loaded from 'gear'
						      on = true,						-- enable/disable
						 setting = {
									name = L["GP_O_SETTINGS"],  -- setting name to view in gear setting window
									-- parent setting 
									[1] =  {
											
											}, 
									},   
										
					
					   ui_setting = {							-- ui setting for gear profil
																-- sType = 'toggle_unique' (on/off state, only once can be enabled in all profil, but all can be disabled)
																-- sType = 'toggle' (on/off state)
																-- sType = 'push' (on click state)
																-- sType = 'none' (no state, only icon to identigy the plugin)
																-- sType = 'action' (no state, only push to launch action like copie to clipboard)
															  									 
									[1] = { sType = "push", Saved = nil,},  -- first setting button is always the plugin icon
											
									
									},   			
					
					}

-- comm timer to init plugin	
local tComm, bCall
-- futur array for tgear.gear updated				 
local tLastGear = nil	
-- anchor
local tAnchor = { l = 0, t = 0, r = 0, b = 0 }
				
-----------------------------------------------------------------------------------------------
-- Initialization
-----------------------------------------------------------------------------------------------
function Gear_Armory:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self 
    return o
end

function Gear_Armory:Init()
	Apollo.RegisterAddon(self, false, nil, {"Gear"})
end
 
-----------------------------------------------------------------------------------------------
-- OnLoad
-----------------------------------------------------------------------------------------------
function Gear_Armory:OnLoad()
	Apollo.RegisterEventHandler("Generic_GEAR_PLUGIN", "ON_GEAR_PLUGIN", self)      -- add event to communicate with gear
   	tComm  = ApolloTimer.Create(1, true, "_Comm", self) 							-- init comm for plugin
end

---------------------------------------------------------------------------------------------------
-- _Comm
---------------------------------------------------------------------------------------------------
function Gear_Armory:_Comm() 
		
	if LG._isaddonup("Gear") then												-- if 'gear' is running , go next
		tComm:Stop()
		tComm = nil 																-- stop init comm timer
		if bCall == nil then LG.initcomm(tPlugin) end 							-- send information about me, setting etc..
	end
end

-----------------------------------------------------------------------------------------------
--- all plugin communicate with gear in this function
-----------------------------------------------------------------------------------------------
function Gear_Armory:ON_GEAR_PLUGIN(sAction, tData)
	
	-- answer come from gear, the gear version, gear is up 
	if sAction == "G_VER" and tData.owner == GP_NAME then
		
		if bCall ~= nil then return end
		bCall = true
	end
		
	-- answer come from gear, the gear array updated
	if sAction == "G_GEAR" then
		tLastGear = tData
	end
		
	-- action request come from gear, the plugin are enable or disable, if this information is for me go next
	if sAction == "G_ON" and tData.owner == GP_NAME then
		-- update enable/disable status
		tPlugin.on = tData.on 	

		if not tPlugin.on then
			-- close dialog
			self:OnCloseDialog()	
		end	
	end
	
	-- answer come from gear, the setting plugin update, if this information is for me go next
	if sAction == "G_UI_ACTION" and tData.owner == GP_NAME then
		-- we request we want last gear array	
		Event_FireGenericEvent("Generic_GEAR_PLUGIN", "G_GET_GEAR", nil)
		-- get armory for ngearid target
		self:ShowArmory(tData.ngearid)
	end
end

-----------------------------------------------------------------------------------------------
-- ShowArmory
-----------------------------------------------------------------------------------------------
function Gear_Armory:ShowArmory(nGearId)
	
	if self.ArmoryWnd ~= nil then self.ArmoryWnd:Destroy() end
	
	local sArmory = self:GetAmoryItem(nGearId)
	if sArmory == nil then return end
	 	
	self.xmlDoc = XmlDoc.CreateFromFile("Gear_Armory.xml")
	self.ArmoryWnd = Apollo.LoadForm(self.xmlDoc, "Dialog_wnd", nil, self)
	self.ArmoryWnd:FindChild("TitleUp"):SetText(tPlugin.setting.name)
	
	local wndInside = Apollo.LoadForm(self.xmlDoc, "Inside_wnd", self.ArmoryWnd, self)
	wndInside:FindChild("ArmoryInfo_Wnd"):SetText(L["GP_ARMORY_INFO"])
	
	self.ArmoryWnd:FindChild("ClipboardCopy_Btn"):SetActionData(GameLib.CodeEnumConfirmButtonType.CopyToClipboard, sArmory)
	self:LastAnchor(self.ArmoryWnd, false)
	self.ArmoryWnd:Show(true)
end

---------------------------------------------------------------------------------------------------
-- OnCloseDialog
---------------------------------------------------------------------------------------------------
function Gear_Armory:OnCloseDialog( wndHandler, wndControl, eMouseButton )

    if self.ArmoryWnd == nil then return end
	self:LastAnchor(self.ArmoryWnd, true)
	self.ArmoryWnd:Destroy()
	self.ArmoryWnd = nil
	self.xmlDoc = nil
end

-----------------------------------------------------------------------------------------------
-- GetAmoryItem 
-----------------------------------------------------------------------------------------------
function Gear_Armory:GetAmoryItem(nGearId)

    local website = "http://ws-armory.github.io"
	local tClass =  {
					[GameLib.CodeEnumClass.Warrior] 		= Apollo.GetString("ClassWarrior"),
					[GameLib.CodeEnumClass.Engineer]		= Apollo.GetString("ClassEngineer"),
					[GameLib.CodeEnumClass.Esper] 			= Apollo.GetString("ClassESPER"),
					[GameLib.CodeEnumClass.Medic] 			= Apollo.GetString("ClassMedic"),
					[GameLib.CodeEnumClass.Stalker] 		= Apollo.GetString("ClassStalker"),
					[GameLib.CodeEnumClass.Spellslinger]	= Apollo.GetString("ClassSpellslinger"),
					}
	
	local nItemId = nil
	local url = nil
	local unit = GameLib.GetPlayerUnit()

	for nSlot, oLink in pairs(tLastGear[nGearId]) do
		
		if tonumber(nSlot) ~= nil then
			
			if nSlot ~= 6 and nSlot ~= 9 and nSlot < 17 then
			
			    local oItem = LG._SearchIn(oLink, 1) -- search in inventory 
		        if oItem ~= nil then nItemId = oItem:GetItemId() 
				else 
					 oItem = LG._SearchIn(oLink, 3) -- -- search in equipped   
					 if oItem ~= nil then nItemId = oItem:GetItemId() end 
				end
			 				
				if nItemId then
			
					if url == nil or url == '' then
						url = website .. "/?" .. nSlot .. "=" .. nItemId
					else
						url = url .. "&" .. nSlot .. "=" .. nItemId
					end
				end
			end
		end	
	end

	if url == nil then return nil end
	
	local title = unit:GetName() .. " - " .. tClass[unit:GetClassId()] .. " [" .. unit:GetLevel() .. "]"
	url = url .. "&title=" .. self:urlencode(title)

	return url
end

-----------------------------------------------------------------------------------------------
-- urlencode  https://gist.github.com/ignisdesign/4323051
-----------------------------------------------------------------------------------------------
function Gear_Armory:urlencode(str)
   if (str) then
      str = string.gsub (str, "\n", "\r\n")
      str = string.gsub (str, "([^%w ])",
         function (c) return string.format ("%%%02X", string.byte(c)) end)
      str = string.gsub (str, " ", "+")
   end
   return str    
end

-----------------------------------------------------------------------------------------------
-- LastAnchor
-----------------------------------------------------------------------------------------------
function Gear_Armory:LastAnchor(oWnd, bSave)
	
	if oWnd then
		if not bSave and tAnchor.b ~= 0 then 
			oWnd:SetAnchorOffsets(tAnchor.l, tAnchor.t, tAnchor.r, tAnchor.b)
		elseif bSave then
			tAnchor.l, tAnchor.t, tAnchor.r, tAnchor.b = oWnd:GetAnchorOffsets()
		end
	end
end

---------------------------------------------------------------------------------------------------
-- OnWndMove
---------------------------------------------------------------------------------------------------
function Gear_Armory:OnWndMove( wndHandler, wndControl, nOldLeft, nOldTop, nOldRight, nOldBottom )
	self:LastAnchor(self.ArmoryWnd, true)
end

---------------------------------------------------------------------------------------------------
-- OnSave
---------------------------------------------------------------------------------------------------
function Gear_Armory:OnSave(eLevel)
	
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
function Gear_Armory:OnRestore(eLevel,tData) 
	
	if eLevel ~= GameLib.CodeEnumAddonSaveLevel.Character then return end
	if tData.config.on ~= nil then tPlugin.on = tData.config.on end
end 

-----------------------------------------------------------------------------------------------
-- Gear_Armory Instance
-----------------------------------------------------------------------------------------------
local Gear_ArmoryInst = Gear_Armory:new()
Gear_ArmoryInst:Init()
