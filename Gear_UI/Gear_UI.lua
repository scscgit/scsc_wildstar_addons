-----------------------------------------------------------------------------------------------
-- Client Lua Script for Gear_UI
-- Copyright (c) NCsoft. All rights reserved
-----------------------------------------------------------------------------------------------

-----------------------------------------------------------------------------------------------
-- Gear_UI Module Definition
-----------------------------------------------------------------------------------------------
local Gear_UI = {} 

-----------------------------------------------------------------------------------------------
-- Localisation
-----------------------------------------------------------------------------------------------
local L = Apollo.GetPackage("Gemini:Locale-1.0").tPackage:GetLocale("Gear_UI", true)

-----------------------------------------------------------------------------------------------
-- Hook
-----------------------------------------------------------------------------------------------
local Hook = Apollo.GetPackage("Gemini:Hook-1.0").tPackage
 
-----------------------------------------------------------------------------------------------
-- Lib gear
-----------------------------------------------------------------------------------------------
local lGear = Apollo.GetPackage("Lib:LibGear-1.0").tPackage 
 
-----------------------------------------------------------------------------------------------
-- Constants
-----------------------------------------------------------------------------------------------
-- version
local Major, Minor, Patch = 1, 0, 1 
local GP_VER = string.format("%d.%d.%d", Major, Minor, Patch)
local GP_NAME = "Gear_UI"

-----------------------------------------------------------------------------------------------
-- Plugin data
-----------------------------------------------------------------------------------------------
local tPlugin =   {
							name = GP_NAME,						-- addon name
						 version = GP_VER,						-- addon version
						  flavor = L["GP_FLAVOR"],				-- addon description
						    icon = nil,                         -- icon plugin name for setting and ui_setting, loaded from 'gear'
						      on = true,						-- enable/disable
						 setting = {
									name = L["GP_O_SETTINGS"], -- setting name to view in gear setting window
									-- parent setting 
									[1] =  {}, 
									},   
										 
					}

-- carbine 'character' addon and replacement know.					
local tAddon =  {	
					[1] = "Character",
					[2] = "RealAP",
				}       						

-- function fired with character window
local tWatch = {
                    [1] = "OnStatsBtn",
				    [2] = "OnBonusBtn",
				    [3] = "OnCostumesBtn",
				    [4] = "OpenEntitlements",
				    [5] = "OpenReputation",
			   }						
	
-- to keep size/art to restore
local tBack = { l = 0, t = 0, r = 0, b = 0, art = "BK3:btnHolo_ListView_Btm",}
-- timer/var to init plugin	
local tComm, bCall, tUI
				
-----------------------------------------------------------------------------------------------
-- Initialization
-----------------------------------------------------------------------------------------------
function Gear_UI:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self 
    return o
end

function Gear_UI:Init()
	Apollo.RegisterAddon(self, false, nil, {"Gear"})
end
 
-----------------------------------------------------------------------------------------------
-- OnLoad
-----------------------------------------------------------------------------------------------
function Gear_UI:OnLoad()
	self.xmlDoc = XmlDoc.CreateFromFile("Gear_UI.xml")
	Apollo.RegisterEventHandler("Generic_GEAR_PLUGIN", "ON_GEAR_PLUGIN", self)      -- add event to communicate with gear
	Hook:Embed(self)																-- hook
	tComm  = ApolloTimer.Create(1, true, "_Comm", self) 							-- init comm for plugin
end

---------------------------------------------------------------------------------------------------
-- _Comm
---------------------------------------------------------------------------------------------------
function Gear_UI:_Comm() 
		
	if lGear._isaddonup("Gear")	then							                	-- if 'gear' is running , go next
		tComm:Stop()
		tComm = nil 																-- stop init comm timer
		lGear.initcomm(tPlugin) 													-- send information about me, setting etc..
	end
end

-----------------------------------------------------------------------------------------------
--- all plugin communicate with gear in this function
-----------------------------------------------------------------------------------------------
function Gear_UI:ON_GEAR_PLUGIN(sAction, tData)
	
	-- answer come from gear, the gear version, gear is up 
	if sAction == "G_VER" and tData.owner == GP_NAME then
		
		if bCall then return end
		bCall = true
		
		-- init ui
		self:UI_Ini(tPlugin.on)
	end
		
	-- action request come from gear, the plugin are enable or disable, if this information is for me go next
	if sAction == "G_ON" and tData.owner == GP_NAME then
		-- update enable/disable status
		tPlugin.on = tData.on 														
		-- init ui
		self:UI_Ini(tPlugin.on)
	end
				
	-- sending by 'gear', 'gear' want to show the 'gear' panel non modal
	if sAction == "G_UI_SHOW" then
		-- if character window is not already open
		if not self.oAddon.wndCharacter:IsVisible() then
			-- open character window and show 'gear' panel
			self.oAddon:ShowCharacterWindow()
			self:OnGearBtn( nil, nil, nil)
		-- if character window is already open and 'gear' panel not show
		elseif self.oAddon.wndCharacter:IsVisible() and not self.oAddon.wndCharacterEverything:FindChild("ContentContainer"):IsVisible() then
			-- show 'gear' panel
			self:OnGearBtn( nil, nil, nil)
		-- or make a toggle hide /show only	
		else
			Event_FireGenericEvent("ToggleCharacterWindow")
		end
	end
end

---------------------------------------------------------------------------------------------------
-- UI_Wait
---------------------------------------------------------------------------------------------------
function Gear_UI:UI_Wait()
    tUI = ApolloTimer.Create(0.1 ,true, "UI_Check", self) 
end 

---------------------------------------------------------------------------------------------------
-- UI_Check
---------------------------------------------------------------------------------------------------
function Gear_UI:UI_Check()
	
	if GameLib.IsCharacterLoaded() then			   
		if tUI then self:UI_CreateBtn() end			-- create dropdownlist button								
	    tUI = nil 									-- stop init comm timer
	end
end 

---------------------------------------------------------------------------------------------------
-- UI_Ini (initialise all to use 'gear' panel to 'character' window)
---------------------------------------------------------------------------------------------------
function Gear_UI:UI_Ini(bOn)
	
	if bOn then
		self:UI_Addon(true)   			-- hook 'character' addon
		self:UI_Watch(true)				-- set hook function
		self:UI_Event(true)				-- register 'character' event
		self:UI_Wait()                  -- we wait the character is loaded to create button/panel
	else
		self:UI_Watch(false)			-- unhook function
		self:UI_Remove()                -- remove 'gear' ui from 'character' panel
		self:UI_Addon(false)   			-- unhook 'character' addon
		self:UI_Event(false)			-- remove 'character' event
	end
end

---------------------------------------------------------------------------------------------------
-- UI_Watch
---------------------------------------------------------------------------------------------------
function Gear_UI:UI_Watch(bOn)
	    	
	if not bOn then self:UnhookAll() return end	
	
	for _=1,#tWatch do
		-- watch all dropdown button event fired
		if not self:IsHooked(self.oAddon, tWatch[_]) then 
			self:PostHook(self.oAddon,tWatch[_], "UI_Hide_Panel") 
		end
	end
end

-----------------------------------------------------------------------------------------------
-- UI_Addon 
-----------------------------------------------------------------------------------------------
function Gear_UI:UI_Addon(bOn) 

    if bOn then 
		for _= 1, #tAddon do
			local oAddon = Apollo.GetAddon(tAddon[_])
			if oAddon then self.oAddon = oAddon break end
		end
	else
		self.oAddon = nil
	end	
end

---------------------------------------------------------------------------------------------------
-- UI_Event (on/off event handler)
---------------------------------------------------------------------------------------------------
function Gear_UI:UI_Event(bOn)
	if bOn then
		Apollo.RegisterEventHandler("CharacterWindowHasBeenClosed", "UI_Hide_Panel", self)
		Apollo.RegisterEventHandler("ToggleCharacterWindow", "OnToggleCharacterWindow", self)
	else
		Apollo.RemoveEventHandler("CharacterWindowHasBeenClosed", self)
		Apollo.RemoveEventHandler("ToggleCharacterWindow", self)
	end
end

---------------------------------------------------------------------------------------------------
-- UI_Hide_Panel
---------------------------------------------------------------------------------------------------
function Gear_UI:UI_Hide_Panel()
	-- hide 'gear' panel ecah time,other character panel are request
	self.oAddon.wndCharacterEverything:FindChild("ContentContainer"):Show(false)
end

---------------------------------------------------------------------------------------------------
-- OnToggleCharacterWindow
---------------------------------------------------------------------------------------------------
function Gear_UI:OnToggleCharacterWindow()
	
	if tPlugin.on then
		self:UI_Hide_Panel()
	end
end

---------------------------------------------------------------------------------------------------
-- OnGearBtn (push 'gear' character dropdownlist button
---------------------------------------------------------------------------------------------------
function Gear_UI:OnGearBtn( wndHandler, wndControl, eMouseButton )
	-- set button text and close dropdownlist
	self.oAddon.wndCharacterEverything:FindChild("DropdownBtn"):SetText(String_GetWeaselString(Apollo.GetString("Character_Display"), L["UI_CHAR_GEAR"]))
	self.oAddon.wndDropdownContents:Show(false)
	
	-- hide all other 'character' panel
	self:UI_Hide()
	
	-- show 'gear' panel
	self.oAddon.wndCharacterEverything:FindChild("ContentContainer"):Show(true)
end

---------------------------------------------------------------------------------------------------
-- UI_Hide (hide all 'character' panel)
---------------------------------------------------------------------------------------------------
function Gear_UI:UI_Hide()
	
	local tWnd = {
					[1] = "CharacterStats",
					[2] = "CharacterBonus",
					[3] = "CharacterCostumes",
					[4] = "Entitlements",
					[5] = "CharacterReputation",
				 }

	for _= 1, #tWnd do
		self.oAddon.wndCharacterEverything:FindChild(tWnd[_]):Show(false)
	end
end

---------------------------------------------------------------------------------------------------
-- UI_CreateBtn
---------------------------------------------------------------------------------------------------
function Gear_UI:UI_CreateBtn()
	    	
	if self.oAddon and self.Gear_Btn == nil then 
		         				
		self.wndDropdownContents = self.oAddon.wndCharacterEverything:FindChild("DropdownContents")
		self.Gear_Btn = Apollo.LoadForm(self.xmlDoc, "GearBtn", self.wndDropdownContents, self)	
							
		-- resize container	
		local nHeightBtn = self.Gear_Btn:GetHeight()
		tBack.l, tBack.t, tBack.r, tBack.b = self.wndDropdownContents:GetAnchorOffsets()
		self.wndDropdownContents:SetAnchorOffsets(tBack.l, tBack.t, tBack.r, tBack.b + nHeightBtn)
				
		-- change button art
		self.wndDropdownContents:FindChild("ReputationBtn"):ChangeArt("BK3:btnHolo_ListView_Mid")
				
		-- move 'gear' button in bottom
		local l,t,r,b = self.wndDropdownContents:FindChild("ReputationBtn"):GetAnchorOffsets()
		self.Gear_Btn:SetAnchorOffsets(l, t + nHeightBtn, r, b + nHeightBtn)
		self.Gear_Btn:SetText(L["UI_CHAR_GEAR"])
		
		-- hide all other 'character' panel
		self:UI_Hide()
		
		-- set 'gear' button text
		self.oAddon.wndCharacterEverything:FindChild("DropdownBtn"):SetText(String_GetWeaselString(Apollo.GetString("Character_Display"), L["UI_CHAR_GEAR"]))
		
		-- request to 'gear' to construct panel
		local oTarget = self.oAddon.wndCharacterEverything:FindChild("ContentContainer")
		self:UI_SendTarget(oTarget)
		
		-- hide 'gear' panel 
		if not self.oAddon.wndCharacterEverything:FindChild("ContentContainer"):IsVisible() then
		   self:UI_Hide_Panel()
		end
	end
end

---------------------------------------------------------------------------------------------------
-- UI_Remove
---------------------------------------------------------------------------------------------------
function Gear_UI:UI_Remove()
			
	if self.Gear_Btn then 
		-- resize container	
		self.wndDropdownContents:SetAnchorOffsets(tBack.l, tBack.t, tBack.r, tBack.b)
		-- change button art
		self.wndDropdownContents:FindChild("ReputationBtn"):ChangeArt(tBack.art)
		-- remove 'gear' button/panel 
		self.Gear_Btn:Destroy()
		self.Gear_Btn = nil
		self.wndDropdownContents = nil
		self.oAddon.wndCharacterEverything:FindChild("ContentContainer"):DestroyChildren()
		
		-- init character window to open state
		if self.oAddon.wndCharacter:IsVisible() then self.oAddon:ShowCharacterWindow() end
		
		-- send to 'gear' we have removed ui
		local tFunc = { uiremoved = true, func = { "SET_UI_TARGET",},}
	    Event_FireGenericEvent("Generic_GEAR_PLUGIN", "G_SET_FUNC", tFunc)
	end
end

---------------------------------------------------------------------------------------------------
-- UI_SendTarget 
---------------------------------------------------------------------------------------------------
function Gear_UI:UI_SendTarget(oTarget)
	
	local tFunc = { uitarget = oTarget, func = { "SET_UI_TARGET",},}
	-- request to 'gear' to use a non modal ui target
	Event_FireGenericEvent("Generic_GEAR_PLUGIN", "G_SET_FUNC", tFunc)
end

---------------------------------------------------------------------------------------------------
-- OnSave
---------------------------------------------------------------------------------------------------
function Gear_UI:OnSave(eLevel)
	
	if eLevel ~= GameLib.CodeEnumAddonSaveLevel.Character then return end 
		
	local tData = {}
	      tData.config = {
							 ver = GP_VER,
							  on = tPlugin.on,
					     }
	return tData
end 

---------------------------------------------------------------------------------------------------
-- OnRestore
---------------------------------------------------------------------------------------------------
function Gear_UI:OnRestore(eLevel,tData) 
	
	if eLevel ~= GameLib.CodeEnumAddonSaveLevel.Character then return end
	if tData.config.on ~= nil then tPlugin.on = tData.config.on end
end 

-----------------------------------------------------------------------------------------------
-- Gear_UI Instance
-----------------------------------------------------------------------------------------------
local Gear_UIInst = Gear_UI:new()
Gear_UIInst:Init()
