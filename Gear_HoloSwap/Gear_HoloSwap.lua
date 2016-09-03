-----------------------------------------------------------------------------------------------
-- Client Lua Script for Gear_OneVersion
-- Copyright (c) NCsoft. All rights reserved
-----------------------------------------------------------------------------------------------

-----------------------------------------------------------------------------------------------
-- Module Definition
-----------------------------------------------------------------------------------------------
local Gear_HoloSwap = {} 

-----------------------------------------------------------------------------------------------
-- Localisation
-----------------------------------------------------------------------------------------------
local L = Apollo.GetPackage("Gemini:Locale-1.0").tPackage:GetLocale("Gear_HoloSwap", true)

-----------------------------------------------------------------------------------------------
-- Lib gear
-----------------------------------------------------------------------------------------------
local lGear = Apollo.GetPackage("Lib:LibGear-1.0").tPackage 

-----------------------------------------------------------------------------------------------
-- GeminiColor
-----------------------------------------------------------------------------------------------
local GColor = Apollo.GetPackage("GeminiColor").tPackage 
 
-----------------------------------------------------------------------------------------------
-- Constants
-----------------------------------------------------------------------------------------------
-- version
local Major, Minor, Patch = 1, 0, 7 
local GP_VER = string.format("%d.%d.%d", Major, Minor, Patch)
local GP_NAME = "Gear_HoloSwap"

-----------------------------------------------------------------------------------------------
-- Plugin data
-----------------------------------------------------------------------------------------------
local tPlugin =     {
							name = GP_NAME,						-- addon name
						 version = GP_VER,						-- addon version
						  flavor = L["GP_FLAVOR"],				-- addon description
						    icon = "LOADED FROM GEAR",          -- icon plugin name for setting and ui_setting, loaded from 'gear'
						      on = true,						-- enable/disable
						 setting = {
									name = L["GP_O_SETTINGS"],  -- setting name to view in gear setting window
									[1] =  {
											[1] = { bActived = false, sDetail = L["GP_O_SETTING_1"],}, -- hide list after a select
											[2] = { bActived = false, sDetail = L["GP_O_SETTING_2"],}, -- hide 'holoswap' in combat
											[3] = { bActived = true,  sDetail = L["GP_O_SETTING_3"],}, -- Use category
											[4] = { sType = "push",   sDetail = L["GP_O_SETTING_4"],}, -- Advanced color setting
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

-- comm timer to init plugin	
local tComm, tWaitLoad, bCall
-- futur array for tgear.gear updated				 
local tLastGear = nil	
-- keep ngearid/category link
local tSavedProfiles = {}
-- keep category
local tCategory = {}
-- keep other setting
local tOther = {
				 opacity = 0.5,
				}
-- anchor
local tAnchor = { 
				  holo = {l = 0, t = 0, r = 0, b = 0},
				  category = {l = 0, t = 0, r = 0, b = 0},
				  color = {l = 0, t = 0, r = 0, b = 0},		
				 }  
-- selected button
local tSelect = {  -- 1 = on mouse over,  2 = profile, 3 = profile no error,  4 = profile error, 5 = button, 6 = category
					   font = { [1] = "CRB_Header14NoDrop", [2] = "CRB_Interface10_BB", },	
					  color = { [1] = "FFFFCC33", [2] = "FFFFFFFF", [3] = "FF00F53D", [4] = "FFFF6633", [5] = "FF000000", [6] = "FFFFFFFF",},  
					opacity = { [1] = 1.0, [2] = 0.8, },
				}	
	
-----------------------------------------------------------------------------------------------
-- Initialization
-----------------------------------------------------------------------------------------------
function Gear_HoloSwap:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self 
    return o
end

function Gear_HoloSwap:Init()
	Apollo.RegisterAddon(self, false, nil, {"Gear"})
end
 
-----------------------------------------------------------------------------------------------
-- OnLoad
-----------------------------------------------------------------------------------------------
function Gear_HoloSwap:OnLoad()
	
	self.xmlDoc = XmlDoc.CreateFromFile("Gear_HoloSwap.xml")
	Apollo.LoadSprites("NewSprite.xml")
	Apollo.RegisterEventHandler("Generic_GEAR_PLUGIN", "ON_GEAR_PLUGIN", self)       -- add event to communicate with gear
	Apollo.RegisterEventHandler("UnitEnteredCombat", "OnUnitEnteredCombat", self)    -- in combat
	Apollo.RegisterEventHandler("ChangeWorld", "OnChangeWorld", self)				
	   
	tComm  = ApolloTimer.Create(0.1, true, "_Comm", self) 							 -- init comm for plugin
end

---------------------------------------------------------------------------------------------------
-- _Comm
---------------------------------------------------------------------------------------------------
function Gear_HoloSwap:_Comm() 
		
	if lGear._isaddonup("Gear")	then												-- if 'gear' is running , go next
		tComm = nil 																-- stop init comm timer
		if bCall == nil then lGear.initcomm(tPlugin) end 							-- send information about me, setting etc..
	end
end

-----------------------------------------------------------------------------------------------
--- all plugin communicate with gear in this function
-----------------------------------------------------------------------------------------------
function Gear_HoloSwap:ON_GEAR_PLUGIN(sAction, tData)
	
	-- answer come from gear, the gear version, gear is up 
	if sAction == "G_VER" and tData.owner == GP_NAME then
					
		if bCall then return end
		bCall = true
						
		if tPlugin.on then
			-- we request we want last gear array and check profile equipped	
			Event_FireGenericEvent("Generic_GEAR_PLUGIN", "G_GET_GEAR", nil)
			
			-- request to check status
			tWaitLoad = ApolloTimer.Create(2, true, "wait", {wait = function()
				if GameLib.IsCharacterLoaded() and GameLib.GetPlayerUnit() ~= nil and tWaitLoad then 
					Event_FireGenericEvent("Generic_GEAR_PLUGIN", "G_GET_CHECK_GEAR", nil)
					tWaitLoad = nil
				end	
			end})
		end	
		
		-- init combat event (on/off)
		self:HS_IniEvent(tPlugin.on) 
	end
	
	-- answer come from gear, the gear array updated
	if sAction == "G_GEAR" or sAction == "G_RENAME" then
		tLastGear = tData
		
		if tPlugin.on then self:HS_Show() end
	end
	
	-- answer come from gear, the gear profile status
	if sAction == "G_CHECK_GEAR" then
	
	    local nGearId = tData.ngearid
		local tError = tData.terror
		
		if tPlugin.on then self:HS_UpdateStatus(nGearId, tError) end
	end
	
	-- answer come from gear, the setting plugin are updated, if this information is for me go next
	if sAction == "G_SETTING" and tData.owner == GP_NAME then
		
		if tData.option == 4 then self:HS_ShowColor() return end
		
		-- update setting status for option 1 - 3
		tPlugin.setting[1][tData.option].bActived = tData.actived
		
		-- setting for holo , use or not category
		if tPlugin.on and tData.option == 3 then
			self:HS_Show()
		end
	end
	
	-- answer come from gear, a gear set deleted
	if sAction == "G_DELETE" then
			
		local nGearId = tData
		if tSavedProfiles[nGearId] then tSavedProfiles[nGearId] = nil end
		if self.CategoryWnd and self.CategoryWnd:FindChild("TitleUp"):GetData() == nGearId then
			-- close category 
			self:Close("Category_Wnd")
		end
	end
		
	-- answer come from gear, the setting plugin update, if this information is for me go next
	if sAction == "G_UI_ACTION" and tData.owner == GP_NAME then
		-- get category for ngearid target
		self.tData = tData
		self:HS_ShowCategory(tData) 
	end
				
	-- action request come from gear, the plugin are enable or disable, if this information is for me go next
	if sAction == "G_ON" and tData.owner == GP_NAME then
		-- update enable/disable status
		tPlugin.on = tData.on
										
		if tPlugin.on then
			self:HS_Ini()
			-- we request always last gear array	
			Event_FireGenericEvent("Generic_GEAR_PLUGIN", "G_GET_GEAR", nil)
			Event_FireGenericEvent("Generic_GEAR_PLUGIN", "G_GET_CHECK_GEAR", nil)
		else
			-- close category/color 
			self:Close("Category_Wnd")
			self:Close("Color_Wnd")
			
			if self.HoloWnd then
				self:LastAnchor(self.HoloWnd, tAnchor.holo, true)
				self.HoloWnd:Destroy()
				self.HoloWnd = nil
			end
		end
		
		-- init combat event (on/off)
		self:HS_IniEvent(tPlugin.on)
	end
	
	-- sending by 'gear', 'gear' have now a new main window
	if sAction == "G_UI_REMOVED" then
		-- close category 
		self:Close("Category_Wnd")
	end
end

---------------------------------------------------------------------------------------------------
-- OnChangeWorld
---------------------------------------------------------------------------------------------------
function Gear_HoloSwap:OnChangeWorld()
	-- always show after zoning, to prevent player always in combat state in PVP match end
	if self.HoloWnd and tPlugin.on then self.HoloWnd:Show(true) end
end

---------------------------------------------------------------------------------------------------
-- HS_UpdateStatus
---------------------------------------------------------------------------------------------------
function Gear_HoloSwap:HS_UpdateStatus(nGearId, tError)
 		
    if self.HoloWnd == nil then return end    
	
	local sName, nCol = nil,  nil
	--  we have a profile selected
	if nGearId then 
		sName = tLastGear[nGearId].name
		--  no profle selected	
	else 
		sName = "?"
	end
	-- items equipped don't match with saved profile (missing item or we have not equipped all items after a problem) or no profile selected
	if tError or nGearId == nil then
		nCol = 4
	-- all ok	
	elseif not tError and nGearId then
		nCol = 3
	end
		
				
	self.HoloWnd:SetTextColor(tSelect.color[nCol])
	self.HoloWnd:SetText(sName)
end 

---------------------------------------------------------------------------------------------------
-- T_Ini (to update saved profile after turning off/on plug-in)
---------------------------------------------------------------------------------------------------
function Gear_HoloSwap:HS_Ini()
   
    -- nothing saved, we stop here
  	if lGear.TableLength(tSavedProfiles) == 0 then return end

    for nGearId, pGearId in pairs(tSavedProfiles) do	
		-- update ui setting status button
		self:HS_UpdateUI(nGearId)	
	end
end 

---------------------------------------------------------------------------------------------------
-- T_UpdateUI (to update 'gear' ui profile status button)
---------------------------------------------------------------------------------------------------
function Gear_HoloSwap:HS_UpdateUI(nGearId)
   
	-- request to 'gear' to update ui setting status button
	local tData = { owner = GP_NAME, uiid = 1, ngearid = nGearId, saved = self:HS_Update_tSaved(),}
	Event_FireGenericEvent("Generic_GEAR_PLUGIN", "G_SET_UI_SETTING", tData)	
end

---------------------------------------------------------------------------------------------------
-- T_Update_tSaved (to update tsavedprofiles before export data to 'gear')
---------------------------------------------------------------------------------------------------
function Gear_HoloSwap:HS_Update_tSaved()
	
	if lGear.TableLength(tSavedProfiles) == 0 then return nil end

	-- make copy of saved array to send to gear
    local tSavedProfilesExp = lGear.DeepCopy(tSavedProfiles)
    local tSavedExp = {}
			
	for nGearId, pCategory in pairs(tSavedProfilesExp) do
	   	tSavedExp[nGearId] = { root = "", target = pCategory,}
	end  
			
	return tSavedExp	
end

-----------------------------------------------------------------------------------------------
-- HS_IniEvent
-----------------------------------------------------------------------------------------------
function Gear_HoloSwap:HS_IniEvent(bActivate)
	-- watch combat event
	if bActivate then 
		Apollo.RegisterEventHandler("UnitEnteredCombat", "OnUnitEnteredCombat", self)
	elseif not bActivate then
		Apollo.RemoveEventHandler("UnitEnteredCombat")
	end
end

-----------------------------------------------------------------------------------------------
-- OnUnitEnteredCombat
-----------------------------------------------------------------------------------------------
function Gear_HoloSwap:OnUnitEnteredCombat(unitPlayer, bInCombat)

	-- stop here if setting 2 not actived
	if not tPlugin.setting[1][2].bActived then return end
	
	if unitPlayer and unitPlayer == GameLib.GetPlayerUnit() then
		if self.HoloWnd and tPlugin.on then self.HoloWnd:Show(not bInCombat) end	
	end
end

-----------------------------------------------------------------------------------------------
-- HS_ShowCategory
-----------------------------------------------------------------------------------------------
function Gear_HoloSwap:HS_ShowCategory(tData)
		
	local nGearId = tData.ngearid
	local sName = tData.name
	
	if self.CategoryWnd then self.CategoryWnd:Destroy() end
		
	self.CategoryWnd = Apollo.LoadForm(self.xmlDoc, "Dialog_wnd", nil, self)
	self.CategoryWnd:SetName("Category_Wnd")
	self.CategoryWnd:FindChild("TitleUp"):SetText(tPlugin.setting.name)
	self.CategoryWnd:FindChild("TitleUp"):SetData(nGearId)
	
	local wndInside = Apollo.LoadForm(self.xmlDoc, "Inside_wnd", self.CategoryWnd, self)
	wndInside:FindChild("TitleUp"):SetText(sName)
	wndInside:FindChild("AddCategory_Btn"):SetText(L["GP_CATADD"])
					
	-- populate 
	self:HS_PopulateCategory(nGearId)
	self:LastAnchor(self.CategoryWnd, tAnchor.category, false)
	self.CategoryWnd:Show(true)
end

-----------------------------------------------------------------------------------------------
-- HS_ShowColor
-----------------------------------------------------------------------------------------------
function Gear_HoloSwap:HS_ShowColor()
		
	if self.ColorWnd then self.ColorWnd:Destroy() end
		
	self.ColorWnd = Apollo.LoadForm(self.xmlDoc, "Dialog_wnd", nil, self)
	self.ColorWnd:SetName("Color_Wnd")
	self.ColorWnd:FindChild("TitleUp"):SetText(tPlugin.setting.name)
		
	local wndInside = Apollo.LoadForm(self.xmlDoc, "Inside_Color_wnd", self.ColorWnd, self)
	wndInside:FindChild("OpacityName_txt"): SetText(L["GP_OPACITY"])
	wndInside:FindChild("Opacity_Sb"):SetValue(tOther.opacity)
		
	for _ = 1, #tSelect.color do
		local wndColor = Apollo.LoadForm(self.xmlDoc, "wndColor_", self.ColorWnd:FindChild("BorderWnd"), self)

		wndColor:SetData(_)
		wndColor:FindChild("Color"):SetBGColor(tSelect.color[_])
		wndColor:FindChild("Color_txt"):SetText(L["GP_COLOR_" .. _ ])
	end
	
	self:LastAnchor(self.ColorWnd, tAnchor.color, false)
	self.ColorWnd:FindChild("BorderWnd"):ArrangeChildrenVert()	
	self.ColorWnd:Show(true)
end

---------------------------------------------------------------------------------------------------
-- OnCloseDialog (category)
---------------------------------------------------------------------------------------------------
function Gear_HoloSwap:OnCloseDialog( wndHandler, wndControl, eMouseButton )
	
	if wndHandler == nil then return end
	local sWnd = wndControl:GetParent():GetName()
			
	self:Close(sWnd)
end

---------------------------------------------------------------------------------------------------
-- Close
---------------------------------------------------------------------------------------------------
function Gear_HoloSwap:Close(sWnd)
		
	local oWnd = Apollo.FindWindowByName(sWnd)	
	
	if oWnd then
		if sWnd == "Category_Wnd" then self:LastAnchor(self.CategoryWnd, tAnchor.category, true) end
		if sWnd == "Color_Wnd" then self:LastAnchor(self.ColorWnd, tAnchor.color, true) end

		oWnd:Destroy()
		oWnd = nil
	end
end

---------------------------------------------------------------------------------------------------
-- OnCategoryReturn (validate category name)
---------------------------------------------------------------------------------------------------
function Gear_HoloSwap:OnCategoryReturn( wndHandler, wndControl, strText )
	
    -- if exist get previous category name for edition
	local sPrevCategory = wndControl:GetParent():GetData()
	-- remove space character start/end
	local sName = strText:match("^%s*(.-)%s*$") 
    
	-- no existing/blank name allowed
	if sName == "" or tCategory[sName] and sName ~= sPrevCategory then 
	
	    -- disable check box
		wndControl:GetParent():FindChild("Category_Btn"):Enable(false)
		
		-- if have old category name, use previous name is new name is wrong
		local sNameInit = ""
		if sPrevCategory then sNameInit = sPrevCategory end
		wndControl:SetText(sNameInit)
		wndControl:SetFocus()
		return
	end
		
	-- set item text
	wndControl:SetText(sName)
	-- enable check box
	wndControl:GetParent():FindChild("Category_Btn"):Enable(true)
	-- get ngearid
	local nGearId = self.CategoryWnd:FindChild("TitleUp"):GetData()
	-- keep category name for edition
	wndControl:GetParent():SetData(sName)
	-- delete old and save new category (no real data, but may be used after for other category option)	
	if tCategory[sPrevCategory] then tCategory[sPrevCategory] = nil end
	tCategory[sName] = ""
		
	-- if old category name exist, find and update all ngearid with this replacement category name
	if sPrevCategory then 
		self:HS_UpdateSavedProfiles(sName, sPrevCategory)
		self:HS_Show()
	end
end

---------------------------------------------------------------------------------------------------
-- OnCategoryLink
---------------------------------------------------------------------------------------------------
function Gear_HoloSwap:OnCategoryLink( wndHandler, wndControl, eMouseButton )
	
	-- get ngearid / category
	local nGearId = self.CategoryWnd:FindChild("TitleUp"):GetData()
	local sCategory = wndControl:GetParent():GetData()

	if wndControl:IsChecked() then
		-- save ngearid/category link, create array if not already exist
		if tSavedProfiles[nGearId] == nil then
			tSavedProfiles[nGearId]	= {}
    	end
		
		-- add category for actual ngearid
		table.insert(tSavedProfiles[nGearId], sCategory)
		
	elseif not wndControl:IsChecked() then
		-- remove category from ngearid
		for _ = 1, #tSavedProfiles[nGearId] do
			if tSavedProfiles[nGearId][_] == sCategory then table.remove(tSavedProfiles[nGearId], _) break end
		end
		-- remove saved profile if no category inside
		if #tSavedProfiles[nGearId] == 0 then tSavedProfiles[nGearId] = nil end
	end	
	
	-- update ui setting status button
	self:HS_UpdateUI(nGearId)
	-- update holo
	self:HS_Show()
end

---------------------------------------------------------------------------------------------------
-- OnDeleteCategory 
---------------------------------------------------------------------------------------------------
function Gear_HoloSwap:OnDeleteCategory( wndHandler, wndControl, eMouseButton )
		
	-- get ngearid / category
	local nGearId = self.CategoryWnd:FindChild("TitleUp"):GetData()
	local sCategory = wndControl:GetParent():GetData()
	
	-- remove item
	wndControl:GetParent():Destroy()
	self.CategoryWnd:FindChild("Category_FrameWnd"):ArrangeChildrenVert()
	
	-- if no category register stop here
	if sCategory == nil then  return end
	
	-- remove category
	tCategory[sCategory] = nil
	
	-- remove category from saved profile
	self:HS_RemoveCategoryProfiles(sCategory)
	-- update
	self:HS_Show()
end

---------------------------------------------------------------------------------------------------
-- HS_RemoveCategoryProfiles
---------------------------------------------------------------------------------------------------
function Gear_HoloSwap:HS_RemoveCategoryProfiles(sCategory)

    -- make copy for loop 
    local tSavedProfilesExp = lGear.DeepCopy(tSavedProfiles)
	
	for nGearId, pCategory in pairs(tSavedProfilesExp) do
	
	    for _ = 1, #pCategory do
			if tSavedProfiles[nGearId][_] == sCategory then table.remove(tSavedProfiles[nGearId], _) end
		end
		
		-- remove saved profile if no category inside
		if #tSavedProfiles[nGearId] == 0 then tSavedProfiles[nGearId] = nil end
		-- update ui
		self:HS_UpdateUI(nGearId)
	end
	
end

---------------------------------------------------------------------------------------------------
-- HS_UpdateSavedProfiles (update old category name with new name)
---------------------------------------------------------------------------------------------------
function Gear_HoloSwap:HS_UpdateSavedProfiles(sNewName, sPrevCategory)

    -- make copy for loop 
    local tSavedProfilesExp = lGear.DeepCopy(tSavedProfiles)

	for nGearId, pCategory in pairs(tSavedProfilesExp) do
	
	    for _ = 1, #pCategory do
			if pCategory[_] == sPrevCategory then tSavedProfiles[nGearId][_] = sNewName end
		end
		
		-- update ui
		self:HS_UpdateUI(nGearId)
	end
end

---------------------------------------------------------------------------------------------------
-- HS_GetCategory (search category for a ngearid saved)
---------------------------------------------------------------------------------------------------
function Gear_HoloSwap:HS_GetCategory(nGearId, sName)
    
    if tSavedProfiles[nGearId] == nil then return false end

	for _, pCategory in pairs(tSavedProfiles[nGearId]) do
	
	    for _ = 1, #pCategory do
			if pCategory == sName then return true end
		end
	end

	return false
end

---------------------------------------------------------------------------------------------------
-- HS_OnAddCategory
---------------------------------------------------------------------------------------------------
function Gear_HoloSwap:HS_OnAddCategory( wndHandler, wndControl, eMouseButton )

	-- get ngearid
	local nGearId = self.CategoryWnd:FindChild("TitleUp"):GetData()
	self:HS_AddCategory(nGearId, nil, false)	
	self.CategoryWnd:FindChild("Category_FrameWnd"):ArrangeChildrenVert()
end

---------------------------------------------------------------------------------------------------
-- HS_AddCategroy (add new category or set saved category)
---------------------------------------------------------------------------------------------------
function Gear_HoloSwap:HS_AddCategory(nGearId, sName, bCheck)

	-- add item to list
	local wndItem = Apollo.LoadForm(self.xmlDoc, "Category_Item", self.CategoryWnd:FindChild("Category_FrameWnd"), self)
	wndItem:FindChild("Category_EditBox"):SetPrompt(L["GP_PROMPT"])
	wndItem:FindChild("Category_EditBox"):SetPromptColor("xkcdBluegreen")
	wndItem:FindChild("Category_EditBox"):SetMaxTextLength(30)
	
	-- if a new category..
	if sName == nil then
		wndItem:FindChild("Category_EditBox"):SetFocus()
		wndItem:FindChild("Category_Btn"):Enable(false)
		
	else
	-- keep category name for edition
		wndItem:FindChild("Category_EditBox"):SetText(sName)
		wndItem:SetData(sName)
	end
	
	-- check/uncheck
	wndItem:FindChild("Category_Btn"):SetCheck(bCheck)
end

-----------------------------------------------------------------------------------------------
-- HS_Show
-----------------------------------------------------------------------------------------------
function Gear_HoloSwap:HS_Show()

	if self.HoloWnd == nil then
		self.HoloWnd = Apollo.LoadForm(self.xmlDoc, "Holo_Wnd", nil, self)
		-- set size limit
    	self.HoloWnd:SetSizingMinimum(150, 35)
		self.HoloWnd:SetSizingMaximum(600, 35)
		self.HoloWnd:SetOpacity(tOther.opacity)
		self.HoloWnd:FindChild("Item_FrameWnd"):SetOpacity(20, 60)
		self.HoloWnd:SetBGColor(tSelect.color[5])
		self.nWidthFrame = self.HoloWnd:FindChild("Item_FrameWnd"):GetWidth()
		self.HoloWnd:Show(true)
	end
	
	self.HoloWnd:FindChild("Item_FrameWnd"):DestroyChildren()
	
	-- populate with category
	if tPlugin.setting[1][3].bActived then
		self:HS_PopulateWithCat()
	end
	
	-- populate with profile alone
	self:HS_Populate()
	
	self:LastAnchor(self.HoloWnd, tAnchor.holo, false)
end

---------------------------------------------------------------------------------------------------
-- HS_PopulateCategory
---------------------------------------------------------------------------------------------------
function Gear_HoloSwap:HS_PopulateCategory(nGearId)

    self.CategoryWnd:FindChild("Category_FrameWnd"):DestroyChildren()
		
	for sName, pCategory in pairs(tCategory) do
		-- get is category is link with ngearid 
		local bCheck = self:HS_GetCategory(nGearId, sName)
		-- add item to list
		self:HS_AddCategory(nGearId, sName, bCheck)
	end
	
	self.CategoryWnd:FindChild("Category_FrameWnd"):ArrangeChildrenVert()
end

---------------------------------------------------------------------------------------------------
-- B_Populate
---------------------------------------------------------------------------------------------------
function Gear_HoloSwap:HS_Populate()

    --self.HoloWnd:FindChild("Item_FrameWnd"):DestroyChildren()
    if not self.HoloWnd:FindChild("Item_FrameWnd"):IsVisible() then return end
	
	-- duplicate array to work
	local tItems = lGear.DeepCopy(tLastGear)
			
	for nGearId, pContent in pairs(tItems) do
	
	   local bCreate = true
	   if tPlugin.setting[1][3].bActived then
			 if tSavedProfiles[nGearId] ~= nil then bCreate = false end
	   end	
	
	   if bCreate then
			-- add item to list
			local wndItem = Apollo.LoadForm(self.xmlDoc, "Item_Btn", self.HoloWnd:FindChild("Item_FrameWnd"), self)
			-- set item text
			wndItem:SetText(pContent.name)
			self:HS_Select(wndItem, 2, 2)
																																						
			-- keep ngearid for each item in list
			local tData = { type = 1, color = 2, data = nGearId }
			wndItem:SetData(tData)
		end	
	end
	
	self.HoloWnd:FindChild("Item_FrameWnd"):ArrangeChildrenVert(self.nArrange)
end

---------------------------------------------------------------------------------------------------
-- HS_PopulateWithCat
---------------------------------------------------------------------------------------------------
function Gear_HoloSwap:HS_PopulateWithCat()

    self.HoloWnd:FindChild("Item_FrameWnd"):DestroyChildren()
    if not self.HoloWnd:FindChild("Item_FrameWnd"):IsVisible() then return end
	
	-- get each category with all ngrearid inside
	local tItems = self:SetCategory()
				
	for sCategory, pGearId in pairs(tItems) do
			    	
		-- add item to list
		local wndItem = Apollo.LoadForm(self.xmlDoc, "Item_Btn", self.HoloWnd:FindChild("Item_FrameWnd"), self)
						
		-- set item text
		wndItem:SetText(String_GetWeaselString(Apollo.GetString("CRB_Brackets"), " " .. sCategory .. " "))
		self:HS_Select(wndItem, 2, 6)
																																						
		-- keep category name for each item in list
		local tData = { type = 2, color = 6, data = sCategory }
		wndItem:SetData(tData)
	end
	self.HoloWnd:FindChild("Item_FrameWnd"):ArrangeChildrenVert(self.nArrange)
end

---------------------------------------------------------------------------------------------------
-- HS_PopulateWithItem
---------------------------------------------------------------------------------------------------
function Gear_HoloSwap:HS_PopulateWithCatItem(sCategory)

    self.HoloWnd:FindChild("Item_FrameWnd"):DestroyChildren()
    if not self.HoloWnd:FindChild("Item_FrameWnd"):IsVisible() then return end
	
	-- get each category with all ngrearid inside
	local tItems = self:SetCategory()[sCategory]
		
	for _ = 1, #tItems do
		-- add item to list
		local wndItem = Apollo.LoadForm(self.xmlDoc, "Item_Btn", self.HoloWnd:FindChild("Item_FrameWnd"), self)
		-- set item text
		wndItem:SetText(tLastGear[tItems[_]].name)
		self:HS_Select(wndItem, 2, 2)
																																						
		-- keep ngearid for each item in list
		local tData = { type = 3, color = 2, data = tItems[_] }
		wndItem:SetData(tData)
	end
	self.HoloWnd:FindChild("Item_FrameWnd"):ArrangeChildrenVert(self.nArrange)
end

---------------------------------------------------------------------------------------------------
-- SetCategory (construct category array for all ngearid saved)
---------------------------------------------------------------------------------------------------
function Gear_HoloSwap:SetCategory()

	local tCategoryList = {}

	for sCategory, pContent in pairs(tCategory) do    

		for nGearId, pContent in pairs(tSavedProfiles) do 	
			if self:HS_GetCategory(nGearId, sCategory) then 
				if tCategoryList[sCategory] == nil then tCategoryList[sCategory] = {} end
				if tCategoryList[sCategory] then table.insert(tCategoryList[sCategory], nGearId) end
			end
		end
	end
	
	return tCategoryList
end

---------------------------------------------------------------------------------------------------
-- OnMouseOver
---------------------------------------------------------------------------------------------------
function Gear_HoloSwap:OnMouseOver( wndHandler, wndControl, x, y )
	self:HS_Select(wndControl, 1, 1)
end

---------------------------------------------------------------------------------------------------
-- OnMouseOut
---------------------------------------------------------------------------------------------------
function Gear_HoloSwap:OnMouseOut( wndHandler, wndControl, x, y )
	self:HS_Select(wndControl, 2, wndControl:GetData().color)
end

---------------------------------------------------------------------------------------------------
-- OnMouseClick
---------------------------------------------------------------------------------------------------
function Gear_HoloSwap:OnMouseClick( wndHandler, wndControl, eMouseButton, nLastRelativeMouseX, nLastRelativeMouseY, bDoubleClick, bStopPropagation )
	
	-- get if item come from category or is only profile
	-- type = 1 (profile racine)
	-- type = 2 (category)
	-- type = 3 (profile come from category)
	
	local nType = wndControl:GetData().type
	local pData = wndControl:GetData().data
	
					
	-- if right click in profile, back to category and no category profile
	if eMouseButton == GameLib.CodeEnumInputMouse.Right and nType == 3 then
		self:HS_PopulateWithCat()
		self:HS_Populate()
		return
	end
		
	-- if left click/right in category, show profile of category
	if eMouseButton == GameLib.CodeEnumInputMouse.Left and nType == 2 then
   		self:HS_PopulateWithCatItem(pData)
		return
   	end

	-- if left click in profile, send request to 'gear'
	if eMouseButton == GameLib.CodeEnumInputMouse.Left then
   		-- request to equip profile 
		local tFunc = { ngearid = pData, func = { "SELECT", "EQUIP", "LAS",},}
		Event_FireGenericEvent("Generic_GEAR_PLUGIN", "G_SET_FUNC", tFunc)
	end
	
	-- if setting 'hide profile after select' is enable
	if tPlugin.setting[1][1].bActived then 
		
		-- if profile come from category selection, back to category after select
		if tPlugin.setting[1][3].bActived and nType == 3 then
			self:HS_PopulateWithCat()
			self:HS_Populate()
		else
		-- profile come from select only, hide window
		  	self:OnMainClick()
		end
	end	
end

---------------------------------------------------------------------------------------------------
-- HS_Select
---------------------------------------------------------------------------------------------------
function Gear_HoloSwap:HS_Select(wndControl, nFont, nColor)
	wndControl:SetTextColor(tSelect.color[nColor])
	wndControl:SetFont(tSelect.font[nFont])
end

---------------------------------------------------------------------------------------------------
-- Hollow_Wnd Functions
---------------------------------------------------------------------------------------------------
function Gear_HoloSwap:OnMainClick( wndHandler, wndControl, eMouseButton, nLastRelativeMouseX, nLastRelativeMouseY, bDoubleClick, bStopPropagation )
	-- make nothing is event fired form frame.
	if wndControl ~= wndHandler then return end
	
	self.HoloWnd:FindChild("Item_FrameWnd"):Show(not self.HoloWnd:FindChild("Item_FrameWnd"):IsShown())
	
	if self.HoloWnd:FindChild("Item_FrameWnd"):IsVisible() then 
		self:MoveToUpDown(self.HoloWnd)	
		self:HS_Show()
	end
end

---------------------------------------------------------------------------------------------------
-- OnSlide
---------------------------------------------------------------------------------------------------
function Gear_HoloSwap:OnSlide( wndHandler, wndControl, fNewValue, fOldValue )
	tOther.opacity = fNewValue	
	if self.HoloWnd then self.HoloWnd:SetOpacity(fNewValue, 60) end
end

-----------------------------------------------------------------------------------------------
-- LastAnchor
-----------------------------------------------------------------------------------------------
function Gear_HoloSwap:LastAnchor(oWnd, tWndAnchor, bSave)
	
	if oWnd then
		if not bSave and tWndAnchor.b ~= 0 then 
			oWnd:SetAnchorOffsets(tWndAnchor.l, tWndAnchor.t, tWndAnchor.r, tWndAnchor.b)
		elseif bSave then
			tWndAnchor.l, tWndAnchor.t, tWndAnchor.r, tWndAnchor.b = oWnd:GetAnchorOffsets()
		end
	end
end

---------------------------------------------------------------------------------------------------
-- OnWndMove
---------------------------------------------------------------------------------------------------
function Gear_HoloSwap:OnWndMove( wndHandler, wndControl, nOldLeft, nOldTop, nOldRight, nOldBottom )
	
	self:LastAnchor(self.HoloWnd, tAnchor.holo, true)
	self:LastAnchor(self.CategoryWnd, tAnchor.category, true)
	self:LastAnchor(self.ColorWnd, tAnchor.color, true)
		
	if self.HoloWnd then self:MoveToUpDown(self.HoloWnd) end
end

---------------------------------------------------------------------------------------------------
-- MoveToUpDown
---------------------------------------------------------------------------------------------------
function Gear_HoloSwap:MoveToUpDown(oWnd)
		
	local l, t, r, b = oWnd:FindChild("Item_FrameWnd"):GetAnchorOffsets()	
	local nWidthBtn = oWnd:GetWidth()  
	local nScreenWidth, nScreenHeight = Apollo.GetScreenSize()	
	local nSwitch = nScreenHeight / 2
			
	if tAnchor.holo.t < nSwitch then 
		oWnd:FindChild("Item_FrameWnd"):Move(l, tAnchor.holo.b - tAnchor.holo.t , nWidthBtn + (self.nWidthFrame / 2) + 30, nScreenHeight)
		self.nArrange = 0
	end
		
	if tAnchor.holo.t > nSwitch then 
		oWnd:FindChild("Item_FrameWnd"):Move(l, 0 - nScreenHeight, nWidthBtn + (self.nWidthFrame / 2) + 30, nScreenHeight)
		self.nArrange = -1
	end
	
	self.HoloWnd:FindChild("Item_FrameWnd"):ArrangeChildrenVert(self.nArrange)
end

---------------------------------------------------------------------------------------------------
-- OnSave
---------------------------------------------------------------------------------------------------
function Gear_HoloSwap:OnSave(eLevel)
	
	if eLevel ~= GameLib.CodeEnumAddonSaveLevel.Character then return end 
			
	-- save settings
	local tData_settings = {} 
	for _, peChild in pairs(tPlugin.setting[1]) do
		-- don't save setting 4 push button
	   	if tonumber(_) ~= nil  and _ ~= 4 then
			tData_settings[_] = peChild.bActived
		end
	end
	
	
	if lGear.TableLength(tSavedProfiles) == 0 then tSavedProfiles = nil end
	if lGear.TableLengthBoth(tCategory) == 0 then tCategory = nil end
		
	local tData = { }
	      tData.config = {
	                       settings = tData_settings,
							  other = tOther,
							 anchor = tAnchor.holo,
							    ver = GP_VER,
								 on = tPlugin.on,
							   link = tSavedProfiles,
						   category = tCategory,	
						  holocolor = tSelect.color,	
						 }
		
	return tData
end 

---------------------------------------------------------------------------------------------------
-- OnRestore
---------------------------------------------------------------------------------------------------
function Gear_HoloSwap:OnRestore(eLevel,tData) 
	
	if eLevel ~= GameLib.CodeEnumAddonSaveLevel.Character then return end
			
	if tData.config.settings then
    	for _, peChild in pairs(tPlugin.setting[1]) do
			-- if index number exist then restore child from actual parent
			if tData.config.settings[_] ~= nil then tPlugin.setting[1][_].bActived = tData.config.settings[_] end
		end 	
	end 
	
	if tData.config.on ~= nil then tPlugin.on = tData.config.on end
	if tData.config.anchor then tAnchor.holo = tData.config.anchor end
	
	if tData.config.link then 
		tSavedProfiles = tData.config.link
		tPlugin.ui_setting[1].Saved = self:HS_Update_tSaved()
	end
	
	if tData.config.category then tCategory = tData.config.category end 
	if tData.config.other then tOther = tData.config.other end 
	
	
	if tData.config.holocolor then
		-- Merge saved color array with base color array, to keep old saved color and add new index color	 
		local tColorTmp = lGear.TableMerge(tSelect.color, tData.config.holocolor)
		tSelect.color = tColorTmp
	end
end 

---------------------------------------------------------------------------------------------------
-- ShowColorDialog (show color dialog for nidcolor selected)
---------------------------------------------------------------------------------------------------
function Gear_HoloSwap:ShowColorDialog(nIdColor)
	local sActualColor = tSelect.color[nIdColor]	
	
	if  self.CP_picker then 
		self.CP_picker:Destroy()
		self.CP_picker = nil
	end
		
    self.CP_picker = GColor:CreateColorPicker(self, "CP_Callback", true, sActualColor)

	-- stick CP to holoswap color window
	local l, t, r, b = self.ColorWnd:GetAnchorOffsets()  
    self.CP_picker:Move(l + (self.ColorWnd:GetWidth() * 3) + 220, t + self.ColorWnd:GetHeight() + 255, self.CP_picker:GetWidth() , self.CP_picker:GetHeight())

	self.CP_picker:Show(true)
end

---------------------------------------------------------------------------------------------------
-- CP_Callback 
---------------------------------------------------------------------------------------------------
function Gear_HoloSwap:CP_Callback(strColor)
    -- save color
	tSelect.color[self.nIdColor] = strColor
	-- set setting button color
	self.oWndColor:SetBGColor(strColor)

	-- get status text	
	local sSelect = self.HoloWnd:GetText()
	
		
	-- button
	if self.nIdColor == 5 then self.HoloWnd:SetBGColor(strColor) return end
	-- status
	if self.nIdColor == 4 and sSelect == "?" or 
	   self.nIdColor == 4 and sSelect ~= "?" or
	   self.nIdColor == 3 and sSelect ~= "?" then self.HoloWnd:SetTextColor(strColor) return end
	
		
	
	if self.HoloWnd:FindChild("Item_FrameWnd"):IsVisible() then 
		tChild = self.HoloWnd:FindChild("Item_FrameWnd"):GetChildren()
		local nType = nil
		
		for _ = 1, #tChild do
		
			local nTypeBtn = tChild[_]:GetData().type
			-- profile	    
			if self.nIdColor == 2 and (nTypeBtn == 3 or nTypeBtn == 1) then
				nType = nTypeBtn
			end
			-- category
			if self.nIdColor == 6 and nTypeBtn == 2 then
				nType = 2
			end
		
			if nTypeBtn == nType then tChild[_]:SetTextColor(strColor) end
		end
	end
end

---------------------------------------------------------------------------------------------------
-- OnColor
---------------------------------------------------------------------------------------------------
function Gear_HoloSwap:OnColor( wndHandler, wndControl, eMouseButton, nLastRelativeMouseX, nLastRelativeMouseY, bDoubleClick, bStopPropagation )
	if wndControl ~= wndHandler then return end
	
	self.nIdColor = wndControl:GetData()
	self.oWndColor = wndControl:FindChild("Color")
	self:ShowColorDialog(wndControl:GetData())	
end

-----------------------------------------------------------------------------------------------
-- Instance
-----------------------------------------------------------------------------------------------
local Gear_HoloSwapInst = Gear_HoloSwap:new()
Gear_HoloSwapInst:Init()
