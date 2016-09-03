-----------------------------------------------------------------------------------------------
-- Client Lua Script for Gear_Costumes
-- Copyright (c) NCsoft. All rights reserved
-----------------------------------------------------------------------------------------------

-- Add support for 'CostumeNames' addon

require "CostumesLib"
 
-----------------------------------------------------------------------------------------------
-- Gear_Costumes Module Definition
-----------------------------------------------------------------------------------------------
local Gear_Costumes = {} 

-----------------------------------------------------------------------------------------------
-- Localisation
-----------------------------------------------------------------------------------------------
local L = Apollo.GetPackage("Gemini:Locale-1.0").tPackage:GetLocale("Gear_Costumes", true)
 
-----------------------------------------------------------------------------------------------
-- Lib gear
-----------------------------------------------------------------------------------------------
local lGear = Apollo.GetPackage("Lib:LibGear-1.0").tPackage 
 
-----------------------------------------------------------------------------------------------
-- Constants
-----------------------------------------------------------------------------------------------
-- version
local Major, Minor, Patch = 1, 0, 3 
local GP_VER = string.format("%d.%d.%d", Major, Minor, Patch)
local GP_NAME = "Gear_Costumes"

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
									[1] =  {
												--[1] = { bActived = true, sDetail = L["GP_O_SETTING_1"],}, -- Use popup menu for profile setting
											}, 
									},   
						 
					  ui_setting = {							-- ui setting for gear profil
																-- sType = 'toggle_unique' (on/off state, only once can be enabled in all profil, but all can be disabled)
																-- sType = 'toggle' (on/off state)
																-- sType = 'push' (on click state)
																-- sType = 'none' (no state, only icon to identigy the plugin)
																-- sType = 'action' (no state, only push to launch action like copie to clipboard)
																-- sType = 'list' (dropdown list, only select)
																
																--sTatus = "true" (show text status 'root' data from 'saved' inside icon)
																
					  				[1] = { sType = "push", sStatus = true, Saved = nil,},  -- first setting button is always the plugin icon
											
									
									},   	
						 
					}

-- timer/var to init plugin	
local tComm, bCall
-- keep ngearid/costume link
local tSavedProfiles = {}
-- anchor
local tAnchor = { l = 0, t = 0, r = 0, b = 0 }
-- color
local tColor = { cost = "White", nocost = "gray" }
				
-----------------------------------------------------------------------------------------------
-- Initialization
-----------------------------------------------------------------------------------------------
function Gear_Costumes:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self 
    return o
end

function Gear_Costumes:Init()
	Apollo.RegisterAddon(self, false, nil, {"Gear"})
end
 
-----------------------------------------------------------------------------------------------
-- OnLoad
-----------------------------------------------------------------------------------------------
function Gear_Costumes:OnLoad()
	Apollo.RegisterEventHandler("Generic_GEAR_PLUGIN", "ON_GEAR_PLUGIN", self)      -- add event to communicate with gear
	Apollo.RegisterEventHandler("CostumeNames_Edit", "C_OnCostumeNames_Edit", self) -- add 'CostumeNames' event
	tComm  = ApolloTimer.Create(1, true, "_Comm", self) 							-- init comm for plugin
end

---------------------------------------------------------------------------------------------------
-- _Comm
---------------------------------------------------------------------------------------------------
function Gear_Costumes:_Comm() 
		
	if lGear._isaddonup("Gear")	then							                	-- if 'gear' is running , go next
		tComm = nil 																-- stop init comm timer
		if bCall == nil then lGear.initcomm(tPlugin) end 							-- send information about me, setting etc..
	end
end

-----------------------------------------------------------------------------------------------
--- all plugin communicate with gear in this function
-----------------------------------------------------------------------------------------------
function Gear_Costumes:ON_GEAR_PLUGIN(sAction, tData)
	
	-- answer come from gear, the gear version, gear is up 
	if sAction == "G_VER" and tData.owner == GP_NAME then
		
		if bCall ~= nil then return end
		bCall = true
	end
		
	-- action request come from gear, the plugin are enable or disable, if this information is for me go next
	if sAction == "G_ON" and tData.owner == GP_NAME then
		-- update enable/disable status
		tPlugin.on = tData.on 														
				
		-- init
		if tPlugin.on then  
			self:C_Ini()
		else
			-- close dialog
			self:OnCloseDialog()
		end  
	end
			
	-- answer come from gear, the gear set equiped
	if sAction == "G_CHANGE" then
		if tPlugin.on then  
			local nGearId = tData.ngearid
			-- equip costume
			if tSavedProfiles[nGearId] then self:C_Equip_COS(tSavedProfiles[nGearId]) end
		end
	end
	
	-- answer come from gear, a gear set deleted
	if sAction == "G_DELETE" then
			
		local nGearId = tData
		if tSavedProfiles[nGearId] then tSavedProfiles[nGearId] = nil end
		if self.CostumeWnd and self.CostumeWnd:FindChild("TitleUp"):GetData() == nGearId then
			-- close dialog
			self:OnCloseDialog()
		end
	end
		
	-- answer come from gear, the setting plugin update, if this information is for me go next
	if sAction == "G_UI_ACTION" and tData.owner == GP_NAME then
		-- get profiles for ngearid target
		self.tData = tData
		self:C_Show(tData) 
	end
	
	-- sending by 'gear', 'gear' have now a new main window
	if sAction == "G_UI_REMOVED" then
		-- close dialog
		self:OnCloseDialog()
	end
end

---------------------------------------------------------------------------------------------------
-- C_Ini (to update saved profile after turning off/on plug-in)
---------------------------------------------------------------------------------------------------
function Gear_Costumes:C_Ini()

    -- nothing saved, we stop here
    if tSavedProfiles == nil then return end
    	
	for nGearId, pGearId in pairs(tSavedProfiles) do	
		-- update ui setting status button
		self:C_UpdateUI(nGearId)	
	end
end 

---------------------------------------------------------------------------------------------------
-- C_UpdateUI (to update 'gear' ui profile status button)
---------------------------------------------------------------------------------------------------
function Gear_Costumes:C_UpdateUI(nGearId)
   
	-- request to 'gear' to update ui setting status button
	local tData = { owner = GP_NAME, uiid = 1, ngearid = nGearId, saved = self:C_Update_tSaved(),}
	Event_FireGenericEvent("Generic_GEAR_PLUGIN", "G_SET_UI_SETTING", tData)	
end

---------------------------------------------------------------------------------------------------
-- C_Update_tSaved (to update tsavedprofiles before export data to gear)
---------------------------------------------------------------------------------------------------
function Gear_Costumes:C_Update_tSaved()
	
	-- make copy of saved array to work
    local tSavedProfilesExp = lGear.DeepCopy(tSavedProfiles)
    -- update saved array for export, we add cos name
    local tSavedExp = {}
	
	-- CostumeNames support
	self:C_CostumeNames()
	local sName = nil
	
	for nGearId, pCosId in pairs(tSavedProfilesExp) do
		
		sName = self.tCostumeNames[pCosId] or String_GetWeaselString(Apollo.GetString("Character_CostumeNum"), pCosId)
		if pCosId == 0 then sName = L["GP_O_COSNAME_0"] end
		tSavedExp[nGearId] = { root = pCosId, target = sName,}
	end  
	return tSavedExp	
end

---------------------------------------------------------------------------------------------------
-- C_CostumeNames (get last array from 'CostumeNames' addon)
---------------------------------------------------------------------------------------------------
function Gear_Costumes:C_CostumeNames()
	
	local aCN = Apollo.GetAddon("CostumeNames")
	if aCN then 
		self.tCostumeNames = aCN.tSettings.tCostumeNames
		aCN = nil
		return
	end
	self.tCostumeNames = {}
end

---------------------------------------------------------------------------------------------------
-- C_OnCostumeNames_Edit (costume name modified)
---------------------------------------------------------------------------------------------------
function Gear_Costumes:C_OnCostumeNames_Edit()
	
    -- update saved costume name for ui and tooltips 
	self:C_Ini()
	
	-- repopulate list if window is visible
	if self.CostumeWnd then 
		self:C_Populate(self.tData.ngearid)
	end
end

-----------------------------------------------------------------------------------------------
-- C_Show
-----------------------------------------------------------------------------------------------
function Gear_Costumes:C_Show(tData)

	local nGearId = tData.ngearid
	local sName = tData.name
	
	if self.CostumeWnd then self.CostumeWnd:Destroy() end
		 	
	self.xmlDoc = XmlDoc.CreateFromFile("Gear_Costumes.xml")
	self.CostumeWnd = Apollo.LoadForm(self.xmlDoc, "Dialog_wnd", nil, self)
	self.CostumeWnd:FindChild("TitleUp"):SetText(tPlugin.setting.name)
	self.CostumeWnd:FindChild("TitleUp"):SetData(nGearId)
	
	local wndInside = Apollo.LoadForm(self.xmlDoc, "Inside_wnd", self.CostumeWnd, self)
	wndInside:FindChild("TitleUp"):SetText(sName)
		
	-- populate 
	self:C_Populate(nGearId)
	self:LastAnchor(self.CostumeWnd, false)
	self.CostumeWnd:Show(true)
end

---------------------------------------------------------------------------------------------------
-- OnCloseDialog
---------------------------------------------------------------------------------------------------
function Gear_Costumes:OnCloseDialog( wndHandler, wndControl, eMouseButton )

	if self.CostumeWnd == nil then return end
	self:LastAnchor(self.CostumeWnd, true)
	self.CostumeWnd:Destroy()
	self.CostumeWnd = nil
end

---------------------------------------------------------------------------------------------------
-- OnClickDropDownBtn
---------------------------------------------------------------------------------------------------
function Gear_Costumes:OnClickDropDownBtn( wndHandler, wndControl, eMouseButton )
	wndControl:FindChild("UI_list_Frame"):Show(not wndControl:FindChild("UI_list_Frame"):IsShown())
end

---------------------------------------------------------------------------------------------------
-- C_Populate
---------------------------------------------------------------------------------------------------
function Gear_Costumes:C_Populate(nGearId)

    self.CostumeWnd:FindChild("item_frame"):DestroyChildren()
	
	-- get updated CostumeNames
	self:C_CostumeNames()
		
	-- construct list
	self.nCount = CostumesLib.GetCostumeCount()
		
	for nCosId = 0, self.nCount + 1 do
						
		-- add item to list
		local wndItem = Apollo.LoadForm(self.xmlDoc, "UI_list_item_Btn", self.CostumeWnd:FindChild("item_frame"), self)
				
		-- set item text
		local sProfile = self.tCostumeNames[nCosId] or String_GetWeaselString(Apollo.GetString("Character_CostumeNum"), nCosId)
		local sColor = tColor.cost 
		if nCosId == 0 or nCosId == self.nCount + 1 then 
			local sProfileId = L["GP_O_COSNAME_NO"]
			if nCosId == 0 then sProfileId = L["GP_O_COSNAME_0"] end
			sColor = tColor.nocost
			sProfile = String_GetWeaselString(Apollo.GetString("CRB_Brackets"), sProfileId)
		end		
						
		wndItem:SetTextColor(sColor)
		wndItem:SetText(sProfile)																																						
				
		-- keep ngearid/cosid for each item in list
		local tData = {ngearid = nGearId, ncosid = nCosId}
		wndItem:SetData(tData)
	end
	
	-- default selected text
	local sSelected = L["GP_O_COSNAME_NO"]
	
	-- if this costume is linked with this ngearid set text
	local nDataLink = tSavedProfiles[nGearId]
	if nDataLink then
		if nDataLink == 0 then 
			sSelected = L["GP_O_COSNAME_0"] 
		else
			sSelected = self.tCostumeNames[nDataLink] or String_GetWeaselString(Apollo.GetString("Character_CostumeNum"), nDataLink)
		end
	end
		
	self.CostumeWnd:FindChild("UI_list_Btn"):SetText(sSelected)
	self.CostumeWnd:FindChild("item_frame"):ArrangeChildrenVert()
end

---------------------------------------------------------------------------------------------------
-- OnClickItemList
---------------------------------------------------------------------------------------------------
function Gear_Costumes:OnClickItemList( wndHandler, wndControl, eMouseButton )
	
	wndControl:GetParent():GetParent():Show(false)
	
	local nCosId = wndControl:GetData().ncosid
	local nGearId = wndControl:GetData().ngearid
		
	-- update selected text and save link
	local sCosName = self.tCostumeNames[nCosId] or String_GetWeaselString(Apollo.GetString("Character_CostumeNum"), nCosId)
	if nCosId == self.nCount + 1 then
		sCosName = L["GP_O_COSNAME_NO"]
		-- nothing selected, remove link from tsavedprofiles
		tSavedProfiles[nGearId] = nil 
	else
		-- costume selected, save link
		tSavedProfiles[nGearId] = nCosId
	end		
	
	
	if nCosId == 0 then sCosName = L["GP_O_COSNAME_0"] end
	self.CostumeWnd:FindChild("UI_list_Btn"):SetText(sCosName)
		
	-- update ui setting status button
	self:C_UpdateUI(wndControl:GetData().ngearid)
end

---------------------------------------------------------------------------------------------------
-- C_Equip_COS
---------------------------------------------------------------------------------------------------
function Gear_Costumes:C_Equip_COS(nCosId)

	local nActualCos = CostumesLib.GetCostumeIndex()
	if nActualCos ~= nCosId then
		CostumesLib.SetCostumeIndex(nCosId)
	end
end

-----------------------------------------------------------------------------------------------
-- LastAnchor
-----------------------------------------------------------------------------------------------
function Gear_Costumes:LastAnchor(oWnd, bSave)
	
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
function Gear_Costumes:OnWndMove( wndHandler, wndControl, nOldLeft, nOldTop, nOldRight, nOldBottom )
	self:LastAnchor(self.CostumeWnd, true)
end

---------------------------------------------------------------------------------------------------
-- OnSave
---------------------------------------------------------------------------------------------------
function Gear_Costumes:OnSave(eLevel)
	
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
function Gear_Costumes:OnRestore(eLevel,tData) 
	
	if eLevel ~= GameLib.CodeEnumAddonSaveLevel.Character then return end
	if tData.config.on ~= nil then tPlugin.on = tData.config.on end
	if tData.config.link ~= nil then 
		tSavedProfiles = tData.config.link
		tPlugin.ui_setting[1].Saved = self:C_Update_tSaved()
	end
end 

-----------------------------------------------------------------------------------------------
-- Gear_Costumes Instance
-----------------------------------------------------------------------------------------------
local Gear_CostumesInst = Gear_Costumes:new()
Gear_CostumesInst:Init()
