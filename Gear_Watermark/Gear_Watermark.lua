-----------------------------------------------------------------------------------------------
-- Client Lua Script for Gear_OneVersion
-- Copyright (c) NCsoft. All rights reserved
-----------------------------------------------------------------------------------------------
 
-----------------------------------------------------------------------------------------------
-- Module Definition
-----------------------------------------------------------------------------------------------
local Gear_Watermark = {} 

-----------------------------------------------------------------------------------------------
-- Localisation
-----------------------------------------------------------------------------------------------
local L = Apollo.GetPackage("Gemini:Locale-1.0").tPackage:GetLocale("Gear_Watermark", true)

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
local GP_NAME = "Gear_Watermark"

-----------------------------------------------------------------------------------------------
-- Plugin data
-----------------------------------------------------------------------------------------------
local tPlugin =     {
							name = GP_NAME,						-- addon name
						 version = GP_VER,						-- addon version
						  flavor = L["GP_FLAVOR"],				-- addon description
						    icon = nil,   				        -- icon plugin name for setting and ui_setting, loaded from 'gear'
						      on = true,						-- enable/disable
						 setting = {
									name = L["GP_O_SETTINGS"],  -- setting name to view in gear setting window
									[1] =  {},
									},
					}
						
-- addon to hook
local tAddon = {
					tooltips = { [1] = "ToolTips", },
			   }

-- comm timer to init plugin	
local tComm, bCall
			   
-- futur array for tgear.gear updated				 
local tLastGear = nil	  
						
						
-----------------------------------------------------------------------------------------------
-- Initialization
-----------------------------------------------------------------------------------------------
function Gear_Watermark:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self 
    return o
end

function Gear_Watermark:Init()
	Apollo.RegisterAddon(self, false, nil, {"Gear"})
end
 
-----------------------------------------------------------------------------------------------
-- OnLoad
-----------------------------------------------------------------------------------------------
function Gear_Watermark:OnLoad()
	-- start watermark
	self.xmlDoc = XmlDoc.CreateFromFile("Gear_Watermark.xml")
	self:_WhoHook()
	Apollo.RegisterEventHandler("CloseVendorWindow",   "OnVendorWindow", self)		 -- vendor close
	Apollo.RegisterEventHandler("InvokeVendorWindow",  "OnVendorWindow", self)		 -- vendor open	
	Apollo.RegisterEventHandler("Generic_GEAR_PLUGIN", "ON_GEAR_PLUGIN", self)       -- add event to communicate with gear
   	tComm  = ApolloTimer.Create(0.1, true, "_Comm", self) 							 -- init comm for plugin
end

---------------------------------------------------------------------------------------------------
-- _Comm
---------------------------------------------------------------------------------------------------
function Gear_Watermark:_Comm() 
		
	if lGear._isaddonup("Gear")	then												-- if 'gear' is running , go next
		tComm:Stop()
		tComm = nil 																-- stop init comm timer
		if bCall == nil then lGear.initcomm(tPlugin) end 							-- send information about me, setting etc..
	end
end

-----------------------------------------------------------------------------------------------
--- all plugin communicate with gear in this function
-----------------------------------------------------------------------------------------------
function Gear_Watermark:ON_GEAR_PLUGIN(sAction, tData)
	
	-- answer come from gear, the gear version, gear is up 
	if sAction == "G_VER" and tData.owner == GP_NAME then
					
		if bCall ~= nil then return end
		bCall = true
						
		if tPlugin.on then
			-- we request we want last gear array	
			Event_FireGenericEvent("Generic_GEAR_PLUGIN", "G_GET_GEAR", nil)
		end	
	end
	
	-- answer come from gear, the gear array updated
	if sAction == "G_GEAR" then
		tLastGear = tData
	end
		
	-- action request come from gear, the plugin are enable or disable, if this information is for me go next
	if sAction == "G_ON" and tData.owner == GP_NAME then
		-- update enable/disable status
		tPlugin.on = tData.on
								
		if tPlugin.on then
			-- we request allways last gear array	
			Event_FireGenericEvent("Generic_GEAR_PLUGIN", "G_GET_GEAR", nil)
		end	
						
		-- update sell vendor window only if tab sell is selected
		if self.aVendor and self.aVendor.tWndRefs.wndVendor ~= nil and self.aVendor.tWndRefs.wndVendor:FindChild("VendorTab1"):IsChecked() then self.aVendor:Redraw() end 	
	end
end

---------------------------------------------------------------------------------------------------
-- OnSave
---------------------------------------------------------------------------------------------------
function Gear_Watermark:OnSave(eLevel)
	
	if eLevel ~= GameLib.CodeEnumAddonSaveLevel.Character then return end 
			
	-- save settings
	local tData_settings = {} 
	for _, peChild in pairs(tPlugin.setting[1]) do
	   	if tonumber(_) ~= nil  then
			tData_settings[_] = peChild.bActived
		end
	end
	
	local tData = { }
	      tData.config = {
	                       settings = tData_settings,
							    ver = GP_VER,
								 on = tPlugin.on, 
						 }
		
	return tData
end 

---------------------------------------------------------------------------------------------------
-- OnRestore
---------------------------------------------------------------------------------------------------
function Gear_Watermark:OnRestore(eLevel,tData) 
	
	if eLevel ~= GameLib.CodeEnumAddonSaveLevel.Character then return end
			
	if tData.config.settings then
    	for _, peChild in pairs(tPlugin.setting[1]) do
			-- if index number exist then restore child from actual parent
			if tData.config.settings[_] ~= nil then tPlugin.setting[1][_].bActived = tData.config.settings[_] end
		end 	
	end 
	
	if tData.config.on ~= nil then tPlugin.on = tData.config.on end
end 

-----------------------------------------------------------------------------------------------
-- WhoHook
-----------------------------------------------------------------------------------------------
function Gear_Watermark:_WhoHook() 
	
	for Category, oCurrent in pairs(tAddon) do
		-- in category
		for _=1,#oCurrent do
           
		    local sAddonName = oCurrent[_]
			local aCheckAddon = Apollo.GetAddon(sAddonName)
				
			if aCheckAddon then
				if sAddonName == "ToolTips" then 
					self:_Watermark_Tooltips(aCheckAddon)
				end
			end				
		end
	end
end

-----------------------------------------------------------------------------------------------
-- Watermark_Tooltips (Base hook tooltips code copyright TomiiKaiyodo)
-----------------------------------------------------------------------------------------------
function Gear_Watermark:_Watermark_Tooltips(oAddon)
		
	local aTooltips = oAddon
	if aTooltips == nil then return end
	
	local origCreateCallNames = aTooltips.CreateCallNames
	aTooltips.CreateCallNames = function(luaCaller)
		origCreateCallNames(luaCaller)
		local origItemTooltip = Tooltip.GetItemTooltipForm
		Tooltip.GetItemTooltipForm = function(luaCaller, wndControl, item, bStuff, nCount)
		-- function called after each mouse over a item
		    		
		   	local tGearName = nil
			if item ~= nil then tGearName = lGear._GetGearParent(item:GetChatLinkString(), tLastGear) end
			if (item ~= nil) and  (tGearName ~= nil) and tPlugin.on then
							
				wndControl:SetTooltipDoc(nil)
										
				local wndTooltip, wndTooltipComp = origItemTooltip(luaCaller, wndControl, item, bStuff, nCount)
				local wndGearTooltips = Apollo.LoadForm(self.xmlDoc, "Gear_Tooltips_wnd", wndTooltip, self)
										
				for _=1, #tGearName do

					local wndTooltips = Apollo.LoadForm(self.xmlDoc, "Tooltips_Template", wndGearTooltips, self)
					wndTooltips:SetText(tGearName[_].name)
				end
									
				wndGearTooltips:ArrangeChildrenTiles()
				local l,t,r,b = wndGearTooltips:GetAnchorOffsets()
				wndGearTooltips:Move(l, (b - (45 * #tGearName)), r, t + (45 * #tGearName))
								
				return wndTooltip, wndTooltipComp
			else
				return origItemTooltip(luaCaller, wndControl, item, bStuff, nCount)
			end
		end
	end
end 

-----------------------------------------------------------------------------------------------
-- OnVendorWindow (open/close vendor)
-----------------------------------------------------------------------------------------------
function Gear_Watermark:OnVendorWindow()
	-- get vendor (to update sell window after on/off watermark) 
	if self.aVendor == nil then self.aVendor = Apollo.GetAddon("Vendor") 
	elseif self.aVendor ~= nil then self.aVendor = nil end
end

-----------------------------------------------------------------------------------------------
-- Instance
-----------------------------------------------------------------------------------------------
local Gear_WatermarkInst = Gear_Watermark:new()
Gear_WatermarkInst:Init()
