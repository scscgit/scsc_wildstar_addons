-----------------------------------------------------------------------------------------------
-- Client Lua Script for Gear_OptiPlates
-- Copyright (c) NCsoft. All rights reserved
-----------------------------------------------------------------------------------------------
 
-----------------------------------------------------------------------------------------------
-- Gear_OptiPlates Module Definition
-----------------------------------------------------------------------------------------------
local Gear_OptiPlates = {} 

-----------------------------------------------------------------------------------------------
-- Localisation
-----------------------------------------------------------------------------------------------
local L = Apollo.GetPackage("Gemini:Locale-1.0").tPackage:GetLocale("Gear_OptiPlates", true)
 
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
local GP_NAME = "Gear_OptiPlates"

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
									name = L["GP_O_SETTINGS"], -- setting name to view in gear setting window
									-- parent setting 
									[1] =  {}, 
									},   
						 
					  ui_setting = {							-- ui setting for gear profil
																-- sType = 'toggle_unique' (on/off state, only once can be enabled in all profil, but all can be disabled)
																-- sType = 'toggle' (on/off state)
																-- sType = 'push' (on click state)
																-- sType = 'none' (no state, only icon to identigy the plugin)
																-- sType = 'action' (no state, only push to launch action like copie to clipboard)
																-- sType = 'list' (dropdown list, only select)
															  									 
									 [1] = { sType = "push", Saved = nil,},  -- first setting button is always the plugin icon
											
									},   	
					}

-- timer/var to init plugin	
local tComm, bCall, tOP
-- init number of try/maxtry to detect addon	
local nTry, nMaxTry = 0, 4
-- keep optiplates profile
local tLastProfiles = {}
-- keep optiplates ngearid/profile link
local tSavedProfiles = {}	
-- hook 
local aAddon
-- anchor
local tAnchor = { l = 0, t = 0, r = 0, b = 0 }
						 
-- optiplates scope sprite
local tScope = { 
					[GameLib.CodeEnumAddonSaveLevel.Account] = "Account",
					[GameLib.CodeEnumAddonSaveLevel.Character] = "Character",
					[GameLib.CodeEnumAddonSaveLevel.General] = "General",
					[GameLib.CodeEnumAddonSaveLevel.Realm] = "Realm",
				}
			
-----------------------------------------------------------------------------------------------
-- Initialization
-----------------------------------------------------------------------------------------------
function Gear_OptiPlates:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self 
    return o
end

function Gear_OptiPlates:Init()
	Apollo.RegisterAddon(self, false, nil, {"Gear"})
end
 
-----------------------------------------------------------------------------------------------
-- OnLoad
-----------------------------------------------------------------------------------------------
function Gear_OptiPlates:OnLoad()
	-- add event to communicate with gear
	Apollo.RegisterEventHandler("Generic_GEAR_PLUGIN", "ON_GEAR_PLUGIN", self)      
	-- optiplates event
	Apollo.RegisterEventHandler("OptiPlates_ProfileCreated", "OP_NewProfile", self)
    Apollo.RegisterEventHandler("OptiPlates_ProfileRemoved", "OP_RemovedProfile", self)
	tComm  = ApolloTimer.Create(1, true, "_Comm", self) 							-- init comm for plugin
end

---------------------------------------------------------------------------------------------------
-- _Comm
---------------------------------------------------------------------------------------------------
function Gear_OptiPlates:_Comm() 
		
	if lGear._isaddonup("Gear") then												-- if 'gear' is running , go next
		tComm:Stop()
		tComm = nil 																-- stop init comm timer
		if bCall == nil then lGear.initcomm(tPlugin) end 							-- send information about me, setting etc..
	end
end

-----------------------------------------------------------------------------------------------
--- all plugin communicate with gear in this function
-----------------------------------------------------------------------------------------------
function Gear_OptiPlates:ON_GEAR_PLUGIN(sAction, tData)
	
	-- answer come from gear, the gear version, gear is up 
	if sAction == "G_VER" and tData.owner == GP_NAME then
		
		if bCall ~= nil then return end
		bCall = true
		-- check if addon is up		
		if tPlugin.on then self:OP_Ini() end  							
	end
		
	-- action request come from gear, the plugin are enable or disable, if this information is for me go next
	if sAction == "G_ON" and tData.owner == GP_NAME then
		-- update enable/disable status
		tPlugin.on = tData.on 														
				
		-- ini optiplates..
		if tPlugin.on then  
			self:OP_Ini()
		else
			-- free addon
			aAddon = nil
			-- close dialog
			self:OnCloseDialog()
		end  
	end
		
	-- answer come from gear, the gear set equiped
	if sAction == "G_CHANGE" then
		if tPlugin.on then  
			local nGearId = tData.ngearid
			if tSavedProfiles[nGearId] ~= nil then self:OP_Switch(nGearId) end
		end
	end
	
	-- answer come from gear, a gear set deleted
	if sAction == "G_DELETE" then
			
		local nGearId = tData
		if tSavedProfiles[nGearId] ~= nil then tSavedProfiles[nGearId] = nil end
	end
		
	-- answer come from gear, the setting plugin update, if this information is for me go next
	if sAction == "G_UI_ACTION" and tData.owner == GP_NAME then
		-- get profiles for ngearid target
		self.tData = tData
		if aAddon ~= nil then self:OP_Show(tData) end
	end

	-- sending by 'gear', 'gear' have now a new main window
	if sAction == "G_UI_REMOVED" then
		-- close dialog
		self:OnCloseDialog()
	end
end

---------------------------------------------------------------------------------------------------
-- OP_Ini
---------------------------------------------------------------------------------------------------
function Gear_OptiPlates:OP_Ini()
	nTry = 0                                                       -- init how many try we have make
	tOP = ApolloTimer.Create(1 ,true, "OP_Check", self) 
end 

---------------------------------------------------------------------------------------------------
-- OP_Check
---------------------------------------------------------------------------------------------------
function Gear_OptiPlates:OP_Check()
	
	if lGear._isaddonup("OptiPlates") then					                		-- if 'optiplates' is running , go next
		tOP = nil 																    -- stop init comm timer
		aAddon = Apollo.GetAddon("OptiPlates")
		self:OP_GetData() 					   								        -- get data..
	else																			-- addon not up..
		nTry = nTry + 1																-- inc number of try to detect him
		if nTry == nMaxTry then 													-- after try so many times we turn off 
			tOP = nil 
			tPlugin.on = false														-- turn off plugin 
			local tData = {owner = GP_NAME, on = false,}	
			Event_FireGenericEvent("Generic_GEAR_PLUGIN", "G_SET_OFF", tData)		-- send this to 'gear'
		end
	end
end 

---------------------------------------------------------------------------------------------------
-- OP_GetData
---------------------------------------------------------------------------------------------------
function Gear_OptiPlates:OP_GetData()
	
	if aAddon == nil then return end
	local tProfiles = aAddon.setProfiles
	
	-- keep only profile
	for nScope, pScope in pairs(tProfiles) do
		if tonumber(nScope) ~= nil then -- keep only scope number
			-- create array for this scope
			tLastProfiles[nScope] = {}
			for sProlifeName, pProfile in pairs(pScope) do
				tLastProfiles[nScope][sProlifeName] = ""	
			end
		end
	end

	return tLastProfiles
end

---------------------------------------------------------------------------------------------------
-- OP_NewProfile
---------------------------------------------------------------------------------------------------
function Gear_OptiPlates:OP_NewProfile(scope, name)
	-- repopulate list if window visible
	if self.OptiPlatesWnd ~= nil then self:OP_Populate(self.tData.ngearid) end
end

---------------------------------------------------------------------------------------------------
-- OP_RemovedProfile
---------------------------------------------------------------------------------------------------
function Gear_OptiPlates:OP_RemovedProfile(scope, name)

    if name == "Default profile" then return end
	
	-- if removed profil is actually saved for a ngearid, remove it
	for nGearId, pGearId in pairs(tSavedProfiles) do
		if pGearId.root == scope and pGearId.target == name and pGearId.target ~= "Default profile" then
			tSavedProfiles[nGearId] = nil
			
			-- request to 'gear' to update ui setting status button
			local tData = { owner = GP_NAME, uiid = 1, ngearid = nGearId, saved = tSavedProfiles,}
			Event_FireGenericEvent("Generic_GEAR_PLUGIN", "G_SET_UI_SETTING", tData)	

		end
	end
   
	-- get new profile updated after removed profile from optiplates
	-- repopulate list if window is visible
	if self.OptiPlatesWnd ~= nil then 
		self:OP_Populate(self.tData.ngearid)
	end
end

---------------------------------------------------------------------------------------------------
-- OP_GetData
---------------------------------------------------------------------------------------------------
function Gear_OptiPlates:OP_Switch(nGearId)

	if aAddon == nil then return end
	aAddon:ChangeProfile(tSavedProfiles[nGearId].root, tSavedProfiles[nGearId].target)
end

-----------------------------------------------------------------------------------------------
-- OP_Show
-----------------------------------------------------------------------------------------------
function Gear_OptiPlates:OP_Show(tData)

	local nGearId = tData.ngearid
	local sName = tData.name
	
	if self.OptiPlatesWnd ~= nil then self.OptiPlatesWnd:Destroy() end
		 	
	self.xmlDoc = XmlDoc.CreateFromFile("Gear_OptiPlates.xml")
	self.OptiPlatesWnd = Apollo.LoadForm(self.xmlDoc, "Dialog_wnd", nil, self)
	self.OptiPlatesWnd:FindChild("TitleUp"):SetText(tPlugin.setting.name)
	
	local wndInside = Apollo.LoadForm(self.xmlDoc, "Inside_wnd", self.OptiPlatesWnd, self)
	wndInside:FindChild("TitleUp"):SetText(sName)
	
	-- populate list
	self:OP_Populate(nGearId)
	self:LastAnchor(self.OptiPlatesWnd, false)
	self.OptiPlatesWnd:Show(true)
end

---------------------------------------------------------------------------------------------------
-- OnCloseDialog
---------------------------------------------------------------------------------------------------
function Gear_OptiPlates:OnCloseDialog( wndHandler, wndControl, eMouseButton )

	if self.OptiPlatesWnd == nil then return end
	self:LastAnchor(self.OptiPlatesWnd, true)
	self.OptiPlatesWnd:Destroy()
	self.OptiPlatesWnd = nil
end

---------------------------------------------------------------------------------------------------
-- OnClickDropDownBtn
---------------------------------------------------------------------------------------------------
function Gear_OptiPlates:OnClickDropDownBtn( wndHandler, wndControl, eMouseButton )
	wndControl:FindChild("UI_list_Frame"):Show(not wndControl:FindChild("UI_list_Frame"):IsShown())
end

---------------------------------------------------------------------------------------------------
-- OP_Populate
---------------------------------------------------------------------------------------------------
function Gear_OptiPlates:OP_Populate(nGearId)

    self.OptiPlatesWnd:FindChild("item_frame"):DestroyChildren()

	-- construct list
	-- get saved (always [scope][profile] )
	local tItems = self:OP_GetData() 
	if tItems == nil then return end
	-- add a blank item for no selected
	tItems[0] = {[".."] = "",}
	
	for nScope, pScope in pairs(tItems) do
		-- filter for empty scope array
		if lGear.TableLengthBoth(tItems[nScope]) ~= 0 then
																	
			for sProfile, pProfile in pairs(pScope) do
				-- add item to list
				local wndItem = Apollo.LoadForm(self.xmlDoc, "UI_list_item_Btn", self.OptiPlatesWnd:FindChild("item_frame"), self)
				-- set item text
				local sScopeProfile = ".."
				if nScope ~= 0 then 
					sScopeProfile = tScope[nScope] .. " - " .. sProfile
				end		
				wndItem:SetText(sScopeProfile)																																						
				
				-- keep scope/profile/ngearid for each item in list
				local tData = {root = nScope, target = sProfile, ngearid = nGearId, }
				wndItem:SetData(tData)
								
				-- if this optiplates profil is linked with this ngearid set text
				local tDataLink = tSavedProfiles[nGearId]
				local sSelected = ".."
				if tDataLink ~= nil then
					sSelected = tScope[tDataLink.root] .. " - " .. tDataLink.target
				end
				self.OptiPlatesWnd:FindChild("UI_list_Btn"):SetText(sSelected)
			end
		end
	end
	self.OptiPlatesWnd:FindChild("item_frame"):ArrangeChildrenVert()
end

---------------------------------------------------------------------------------------------------
-- OnClickItemList
---------------------------------------------------------------------------------------------------
function Gear_OptiPlates:OnClickItemList( wndHandler, wndControl, eMouseButton )
	
	wndControl:GetParent():GetParent():Show(false)
	
	local nScope = wndControl:GetData().root
	local sProfile = wndControl:GetData().target
	
	-- update selected text
	local sScopeProfile = ".."
	if nScope ~= 0 then
		sScopeProfile = tScope[nScope] .. " - " .. sProfile
	end		
	self.OptiPlatesWnd:FindChild("UI_list_Btn"):SetText(sScopeProfile)
				
	-- save ngearid/optiplates link		
	if wndControl:GetData().root == 0 then 
		-- nothing selected
		tSavedProfiles[wndControl:GetData().ngearid] = nil 
	else
		-- profile selected
		tSavedProfiles[wndControl:GetData().ngearid] = { root = nScope, target = sProfile,}
	end
				
	-- request to 'gear' to update ui setting status button
	local tData = { owner = GP_NAME, uiid = 1, ngearid = wndControl:GetData().ngearid, saved = tSavedProfiles,}
	Event_FireGenericEvent("Generic_GEAR_PLUGIN", "G_SET_UI_SETTING", tData)
end

-----------------------------------------------------------------------------------------------
-- LastAnchor
-----------------------------------------------------------------------------------------------
function Gear_OptiPlates:LastAnchor(oWnd, bSave)
	
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
function Gear_OptiPlates:OnWndMove( wndHandler, wndControl, nOldLeft, nOldTop, nOldRight, nOldBottom )
	self:LastAnchor(self.OptiPlatesWnd, true)
end

---------------------------------------------------------------------------------------------------
-- OnSave
---------------------------------------------------------------------------------------------------
function Gear_OptiPlates:OnSave(eLevel)
	
	if eLevel ~= GameLib.CodeEnumAddonSaveLevel.Character then return end 
		
	local tData = {}
	      tData.config = {
	                            ver = GP_VER,
								 on = tPlugin.on,
							   link = tSavedProfiles,
					     }
	return tData
end 

---------------------------------------------------------------------------------------------------
-- OnRestore
---------------------------------------------------------------------------------------------------
function Gear_OptiPlates:OnRestore(eLevel,tData) 
	
	if eLevel ~= GameLib.CodeEnumAddonSaveLevel.Character then return end
	if tData.config.on ~= nil then tPlugin.on = tData.config.on end
	if tData.config.link ~= nil then 
		tSavedProfiles = tData.config.link
		tPlugin.ui_setting[1].Saved = tData.config.link
	end
end 

-----------------------------------------------------------------------------------------------
-- Gear_OptiPlates Instance
-----------------------------------------------------------------------------------------------
local Gear_OptiPlatesInst = Gear_OptiPlates:new()
Gear_OptiPlatesInst:Init()
