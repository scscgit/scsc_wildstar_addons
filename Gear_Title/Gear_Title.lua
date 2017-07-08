-----------------------------------------------------------------------------------------------
-- Client Lua Script for Gear_Title
-- Copyright (c) NCsoft. All rights reserved
-----------------------------------------------------------------------------------------------

require "CharacterTitle"
 
-----------------------------------------------------------------------------------------------
-- Gear_Title Module Definition
-----------------------------------------------------------------------------------------------
local Gear_Title = {} 

-----------------------------------------------------------------------------------------------
-- Localisation
-----------------------------------------------------------------------------------------------
local L = Apollo.GetPackage("Gemini:Locale-1.0").tPackage:GetLocale("Gear_Title", true)
 
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
local GP_NAME = "Gear_Title"

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
											 [1] = { sType = "toggle", bActived = true, sDetail = L["GP_O_SETTING_1"],}, -- show category	
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
																
					  				[1] = { sType = "push", Saved = nil,},  -- first setting button is always the plugin icon
											
									
									},   	
						 
					}

-- timer/var to init plugin	
local tComm, bCall, tWaitLoad
-- keep ngearid/titleid link
local tSavedProfiles = {}
-- anchor
local tAnchor = { l = 0, t = 0, r = 0, b = 0 }
-- color
local tColor = { title = "White", category = "xkcdAmber", notitle = "gray" }
				
-----------------------------------------------------------------------------------------------
-- Initialization
-----------------------------------------------------------------------------------------------
function Gear_Title:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self 
    return o
end

function Gear_Title:Init()
	Apollo.RegisterAddon(self, false, nil, {"Gear"})
end
 
-----------------------------------------------------------------------------------------------
-- OnLoad
-----------------------------------------------------------------------------------------------
function Gear_Title:OnLoad()
	Apollo.RegisterEventHandler("Generic_GEAR_PLUGIN", "ON_GEAR_PLUGIN", self)      -- add event to communicate with gear
	Apollo.RegisterEventHandler("PlayerTitleUpdate", "T_OnTitleNew", self)  		-- fired after title added/removed for player 
	tComm  = ApolloTimer.Create(1, true, "_Comm", self) 							-- init comm for plugin
end

---------------------------------------------------------------------------------------------------
-- _Comm
---------------------------------------------------------------------------------------------------
function Gear_Title:_Comm() 
		
	if lGear._isaddonup("Gear")	then							                	-- if 'gear' is running , go next
		tComm:Stop()
		tComm = nil 																-- stop init comm timer
		if bCall == nil then lGear.initcomm(tPlugin) end 							-- send information about me, setting etc..
	end
end

-----------------------------------------------------------------------------------------------
--- all plugin communicate with gear in this function
-----------------------------------------------------------------------------------------------
function Gear_Title:ON_GEAR_PLUGIN(sAction, tData)
	
	-- answer come from gear, the gear version, gear is up 
	if sAction == "G_VER" and tData.owner == GP_NAME then
		
		if bCall ~= nil then return end
		bCall = true
		
		if tPlugin.on then
					
			-- request to check status
			tWaitLoad = ApolloTimer.Create(1, true, "wait", {wait = function()
				if GameLib.IsCharacterLoaded() and GameLib.GetPlayerUnit() ~= nil and tWaitLoad then 
					self:T_CheckTitle()
					self:T_Ini()
					tWaitLoad = nil
				end	
			end})
		end	
			
	end
	
    -- answer come from gear, the setting plugin are updated, if this information is for me go next
	if sAction == "G_SETTING" and tData.owner == GP_NAME then
		-- update setting status
		tPlugin.setting[1][tData.option].bActived = tData.actived
		-- update show/hide category
		if self.TitleWnd then self:T_Populate(self.tData.ngearid) end
	end
   	
	-- action request come from gear, the plugin are enable or disable, if this information is for me go next
	if sAction == "G_ON" and tData.owner == GP_NAME then
		-- update enable/disable status
		tPlugin.on = tData.on 														
				
		-- init
		if tPlugin.on then  
			self:T_Ini()
		else
			-- close dialog
			self:OnCloseDialog()
		end  
	end
			
	-- answer come from gear, the gear set equiped
	if sAction == "G_CHANGE" then
		if tPlugin.on then  
			local nGearId = tData.ngearid
			-- equip title
			if tSavedProfiles[nGearId] then self:T_SetTitle(tSavedProfiles[nGearId]) end
		end
	end
	
	-- answer come from gear, a gear set deleted
	if sAction == "G_DELETE" then
			
		local nGearId = tData
		if tSavedProfiles[nGearId] then tSavedProfiles[nGearId] = nil end
		if self.TitleWnd and self.TitleWnd:FindChild("TitleUp"):GetData() == nGearId then
			-- close dialog
			self:OnCloseDialog()
		end
	end
		
	-- answer come from gear, the setting plugin update, if this information is for me go next
	if sAction == "G_UI_ACTION" and tData.owner == GP_NAME then
		-- get profiles for ngearid target
		self.tData = tData
		self:T_Show(tData) 
	end
	
	-- sending by 'gear', 'gear' have now a new main window
	if sAction == "G_UI_REMOVED" then
		-- close dialog
		self:OnCloseDialog()
	end
end

---------------------------------------------------------------------------------------------------
-- T_Ini (to update saved profile after turning off/on plug-in)
---------------------------------------------------------------------------------------------------
function Gear_Title:T_Ini()
	
    -- nothing saved, we stop here
  	if lGear.TableLength(tSavedProfiles) == 0 then return end
	
    for nGearId, pGearId in pairs(tSavedProfiles) do	
		-- update ui setting status button
		self:T_UpdateUI(nGearId)	
	end
end 

---------------------------------------------------------------------------------------------------
-- T_UpdateUI (to update 'gear' ui profile status button)
---------------------------------------------------------------------------------------------------
function Gear_Title:T_UpdateUI(nGearId)
   
	-- request to 'gear' to update ui setting status button
	local tData = { owner = GP_NAME, uiid = 1, ngearid = nGearId, saved = self:T_Update_tSaved(),}
	Event_FireGenericEvent("Generic_GEAR_PLUGIN", "G_SET_UI_SETTING", tData)	
end

---------------------------------------------------------------------------------------------------
-- T_Update_tSaved (to update tsavedprofiles before export data to 'gear')
---------------------------------------------------------------------------------------------------
function Gear_Title:T_Update_tSaved()
	
	-- make copy of saved array to send to gear
    local tSavedProfilesExp = lGear.DeepCopy(tSavedProfiles)
    local tSavedExp = {}
			
	for nGearId, pTitle in pairs(tSavedProfilesExp) do
		tSavedExp[nGearId] = { root = "", target = pTitle,}
	end  
	return tSavedExp	
end

---------------------------------------------------------------------------------------------------
-- T_Titles (get last array from titles)
---------------------------------------------------------------------------------------------------
function Gear_Title:T_Titles()
	
	local tTitles = CharacterTitle.GetAvailableTitles()
	self.tTitles = {}
	
	self.tTitles[0] = { 
						title = L["GP_O_TNAME_BLANK"],
						category = "",
					  }	
	
	for nTitleId, pTitleCurr in pairs(tTitles) do
		self.tTitles[nTitleId] = { 
								   title = pTitleCurr:GetTitle(),
		                           category = pTitleCurr:GetCategory(),
								 }	
	end
	
	self.tTitles[#tTitles + 1] = { 
								  title = L["GP_O_TNAME_NO"],
								  category = "",
								 }	
end

---------------------------------------------------------------------------------------------------
-- T_CheckTitle (check saved title array problem not match with array in game)
---------------------------------------------------------------------------------------------------
function Gear_Title:T_CheckTitle()

    if lGear.TableLength(tSavedProfiles) ~= 0 then 
		
		local tTitles = CharacterTitle.GetAvailableTitles()
				
		for nGearId, pTitle in pairs(tSavedProfiles) do
			-- filter for blank title
			if pTitle ~= L["GP_O_TNAME_BLANK"] then	
			
				local bFind = nil		
				for nId = 1, #tTitles do
					if tSavedProfiles[nGearId] == tTitles[nId]:GetTitle() then bFind = true break end
				end
				-- title saved not find in actual titles in game, we delete saved title 
				if bFind == nil then tSavedProfiles[nGearId] = nil end 
			end
		end
	end
end

---------------------------------------------------------------------------------------------------
-- T_FindTitleId (search title in titles game array, return otitle or nil)
---------------------------------------------------------------------------------------------------
function Gear_Title:T_FindTitleId(sTitle)
   		
	if sTitle == L["GP_O_TNAME_BLANK"] then return nil end 
		
	local tTitles = CharacterTitle.GetAvailableTitles()
	for nId = 1, #tTitles do
		if sTitle == tTitles[nId]:GetTitle() then return tTitles[nId] end
	end
		
	return nil
end

---------------------------------------------------------------------------------------------------
-- T_SetTitle
---------------------------------------------------------------------------------------------------
function Gear_Title:T_SetTitle(sTitle)
	local oTitle = self:T_FindTitleId(sTitle)
	CharacterTitle.SetTitle(oTitle) 
end

---------------------------------------------------------------------------------------------------
-- T_OnTitleNew (new title added)
---------------------------------------------------------------------------------------------------
function Gear_Title:T_OnTitleNew()
		
	-- fired after added/remove a title in array
	if lGear.TableLength(tSavedProfiles) ~= 0 then 
	   	-- update tsaved with new ntitleid
		self:T_CheckTitle()
		self:T_Ini()
	end
		
	-- repopulate list 
	if self.TitleWnd then 
		self:T_Populate(self.tData.ngearid)
	end
end

-----------------------------------------------------------------------------------------------
-- T_Show
-----------------------------------------------------------------------------------------------
function Gear_Title:T_Show(tData)

	local nGearId = tData.ngearid
	local sName = tData.name
	
	if self.TitleWnd then self.TitleWnd:Destroy() end
		 	
	self.xmlDoc = XmlDoc.CreateFromFile("Gear_Title.xml")
	self.TitleWnd = Apollo.LoadForm(self.xmlDoc, "Dialog_wnd", nil, self)
	self.TitleWnd:FindChild("TitleUp"):SetText(tPlugin.setting.name)
	self.TitleWnd:FindChild("TitleUp"):SetData(nGearId)
	
	local wndInside = Apollo.LoadForm(self.xmlDoc, "Inside_wnd", self.TitleWnd, self)
	wndInside:FindChild("TitleUp"):SetText(sName)
		
	-- populate 
	self:T_Populate(nGearId)
	self:LastAnchor(self.TitleWnd, false)
	self.TitleWnd:Show(true)
end

---------------------------------------------------------------------------------------------------
-- OnCloseDialog
---------------------------------------------------------------------------------------------------
function Gear_Title:OnCloseDialog( wndHandler, wndControl, eMouseButton )

	if self.TitleWnd == nil then return end
	self:LastAnchor(self.TitleWnd, true)
	self.TitleWnd:Destroy()
	self.TitleWnd = nil
end

---------------------------------------------------------------------------------------------------
-- OnClickDropDownBtn
---------------------------------------------------------------------------------------------------
function Gear_Title:OnClickDropDownBtn( wndHandler, wndControl, eMouseButton )
	wndControl:FindChild("UI_list_Frame"):Show(not wndControl:FindChild("UI_list_Frame"):IsShown())
end

---------------------------------------------------------------------------------------------------
-- C_Populate
---------------------------------------------------------------------------------------------------
function Gear_Title:T_Populate(nGearId)

    -- 0 = show blank title
	-- 1 - x = title
	-- #array = keep previous title
	
    self.TitleWnd:FindChild("item_frame"):DestroyChildren()
	
    -- get updated titles 
	self:T_Titles()
		
	self.nCount = lGear.TableLength(self.tTitles)
	local tSeparator = {}
	
	-- construct list
	for nTitleId = 0, self.nCount - 1 do
		-- 0 = show blank title
		-- self.nCount - 1 = none
		
	    local sCategory = self.tTitles[nTitleId].category
	
		-- add category separator
		if tPlugin.setting[1][1].bActived then
		    
			if tSeparator[sCategory] == nil and sCategory ~= "" then
				local wndItem = Apollo.LoadForm(self.xmlDoc, "Separartor_wnd", self.TitleWnd:FindChild("item_frame"), self)
				wndItem:SetText(sCategory)
				wndItem:SetData({category = sCategory})
				tSeparator[sCategory] = true
			end
		end
		
		-- add item to list
		local wndItem = Apollo.LoadForm(self.xmlDoc, "UI_list_item_Btn", self.TitleWnd:FindChild("item_frame"), self)
						
		-- set item text
		local sProfile = self.tTitles[nTitleId].title
        local sColor = tColor.title  		
		if nTitleId == self.nCount - 1 or nTitleId == 0 then 
			sProfile = String_GetWeaselString(Apollo.GetString("CRB_Brackets"), self.tTitles[nTitleId].title)
			sColor = tColor.notitle
		end		
		
		wndItem:SetTextColor(sColor)
		wndItem:SetText(sProfile)
        				
		-- keep ntitleid for each item in list
		wndItem:SetData( {ntitleid = nTitleId, category = sCategory} )
	end
	
	-- default selected text
	local sSelected = L["GP_O_TNAME_NO"]
	
	-- if this title is linked with this ngearid set text
	local sLink = tSavedProfiles[nGearId]
	if sLink then
		sSelected = sLink
	end
		
   	self.TitleWnd:FindChild("UI_list_Btn"):SetText(sSelected)
		
	-- filter by category
	self.TitleWnd:FindChild("item_frame"):ArrangeChildrenTiles(0, function(a,b) return (a:GetData().category < b:GetData().category) end)
end

---------------------------------------------------------------------------------------------------
-- OnClickItemList
---------------------------------------------------------------------------------------------------
function Gear_Title:OnClickItemList( wndHandler, wndControl, eMouseButton )
	
	wndControl:GetParent():GetParent():Show(false)
	
	local nTitleId = wndControl:GetData().ntitleid
	local nGearId = self.TitleWnd:FindChild("TitleUp"):GetData()
		
	-- update selected text and save link
	local sTitleName = self.tTitles[nTitleId].title 
	if nTitleId == self.nCount - 1 then
		-- nothing selected, remove link from tsavedprofiles
		tSavedProfiles[nGearId] = nil 
	else
		-- title selected, save link
		tSavedProfiles[nGearId] = sTitleName
	end		
	self.TitleWnd:FindChild("UI_list_Btn"):SetText(sTitleName)
		
	-- update ui setting status button
	self:T_UpdateUI(nGearId)
end

-----------------------------------------------------------------------------------------------
-- LastAnchor
-----------------------------------------------------------------------------------------------
function Gear_Title:LastAnchor(oWnd, bSave)
	
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
function Gear_Title:OnWndMove( wndHandler, wndControl, nOldLeft, nOldTop, nOldRight, nOldBottom )
	self:LastAnchor(self.TitleWnd, true)
end

---------------------------------------------------------------------------------------------------
-- OnSave
---------------------------------------------------------------------------------------------------
function Gear_Title:OnSave(eLevel)
	
	if eLevel ~= GameLib.CodeEnumAddonSaveLevel.Character then return end 
	if lGear.TableLength(tSavedProfiles) == 0 then tSavedProfiles = nil end
			
	local tData = {}
	      tData.config = {
	                            ver = GP_VER,
								 on = tPlugin.on,
						   category = tPlugin.setting[1][1].bActived,
						 	   link = tSavedProfiles,
						 }
	return tData
end 

---------------------------------------------------------------------------------------------------
-- OnRestore
---------------------------------------------------------------------------------------------------
function Gear_Title:OnRestore(eLevel,tData) 
	
	if eLevel ~= GameLib.CodeEnumAddonSaveLevel.Character then return end
	if tData.config.on ~= nil then tPlugin.on = tData.config.on end
					
	if tData.config.link then 
		tSavedProfiles = tData.config.link
	end
end 

-----------------------------------------------------------------------------------------------
-- Gear_Title Instance
-----------------------------------------------------------------------------------------------
local Gear_TitleInst = Gear_Title:new()
Gear_TitleInst:Init()
