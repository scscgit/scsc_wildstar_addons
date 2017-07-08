-----------------------------------------------------------------------------------------------
-- Client Lua Script for Gear_Builder
-- Copyright (c) NCsoft. All rights reserved
-----------------------------------------------------------------------------------------------
 
require "GameLib"
require "AbilityBook"

-----------------------------------------------------------------------------------------------
-- Gear_Builder Module Definition
-----------------------------------------------------------------------------------------------
local Gear_Builder = {} 

-----------------------------------------------------------------------------------------------
-- Localisation
-----------------------------------------------------------------------------------------------
local L = Apollo.GetPackage("Gemini:Locale-1.0").tPackage:GetLocale("Gear_Builder", true)
 
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
local GP_NAME = "Gear_Builder"

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
local tComm, bCall, tB
-- init number of try/maxtry to detect addon	
local nTry, nMaxTry = 0, 4
-- keep builder profile
local tLastProfiles = {}
-- keep builder ngearid/profile link
local tSavedProfiles = {}
-- anchor
local tAnchor = { l = 0, t = 0, r = 0, b = 0 }	
				
-----------------------------------------------------------------------------------------------
-- Initialization
-----------------------------------------------------------------------------------------------
function Gear_Builder:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self 
    return o
end

function Gear_Builder:Init()
	Apollo.RegisterAddon(self, false, nil, {"Gear"})
end
 
-----------------------------------------------------------------------------------------------
-- OnLoad
-----------------------------------------------------------------------------------------------
function Gear_Builder:OnLoad()
	Apollo.RegisterEventHandler("Generic_GEAR_PLUGIN", "ON_GEAR_PLUGIN", self)      -- add event to communicate with gear
	Apollo.RegisterEventHandler("GenericBuilderUpdate", "ON_BUILDER_UPDATE", self)  -- add builder event
	tComm  = ApolloTimer.Create(1, true, "_Comm", self) 							-- init comm for plugin
end

---------------------------------------------------------------------------------------------------
-- _Comm
---------------------------------------------------------------------------------------------------
function Gear_Builder:_Comm() 
		
	if lGear._isaddonup("Gear")	then							                	-- if 'gear' is running , go next
		tComm:Stop()
		tComm = nil 																-- stop init comm timer
		if bCall == nil then lGear.initcomm(tPlugin) end 							-- send information about me, setting etc..
	end
end

-----------------------------------------------------------------------------------------------
--- ON_GEAR_PLUGIN (all plugin communicate with gear in this function)
-----------------------------------------------------------------------------------------------
function Gear_Builder:ON_GEAR_PLUGIN(sAction, tData)
	
	-- answer come from gear, the gear version, gear is up 
	if sAction == "G_VER" and tData.owner == GP_NAME then
		
		if bCall then return end
		bCall = true
		-- check if addon is up
		if tPlugin.on then self:B_Ini() end  							
	end
		
	-- action request come from gear, the plugin are enable or disable, if this information is for me go next
	if sAction == "G_ON" and tData.owner == GP_NAME then
		-- update enable/disable status
		tPlugin.on = tData.on 														
				
		-- ini builder..
		if tPlugin.on then  
			self:B_Ini()
		else
			-- close dialog
			self:OnCloseDialog()
			-- unlock gear 'las mod auto'
			self:B_LockLASMod(false)														 
		end  
	end
		
	-- answer come from gear, the gear set equiped
	if sAction == "G_CHANGE" then
		if tPlugin.on then  
			local nGearId = tData.ngearid
			-- activate linked profil from builder, only if gear set equipped come from gear ui
			if tSavedProfiles[nGearId] ~= nil and tData.fromui then self:B_Switch(tSavedProfiles[nGearId].root) end
			
		end
	end
	
	-- answer come from gear, a gear set deleted
	if sAction == "G_DELETE" then
	
		local nGearId = tData
		if tSavedProfiles[nGearId] then tSavedProfiles[nGearId] = nil end
		if self.BuilderWnd and self.BuilderWnd:FindChild("TitleUp"):GetData() == nGearId then
			-- close dialog
			self:OnCloseDialog()
		end
	end
		
	-- answer come from gear, the setting plugin update, if this information is for me go next
	if sAction == "G_UI_ACTION" and tData.owner == GP_NAME then
		-- get profiles for ngearid target
		self.tData = tData
		self:B_Show(tData) 
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
function Gear_Builder:B_Ini()
	nTry = 0                                                       -- init how many try we have make
	tB = ApolloTimer.Create(1 ,true, "B_Check", self) 
end 

---------------------------------------------------------------------------------------------------
-- OP_Ini
---------------------------------------------------------------------------------------------------
function Gear_Builder:B_Check()
	
	if lGear._isaddonup("Builder") then	                                           	 -- if 'builder' is running , go next
		tB = nil 																     -- destroy init comm timer
		self:B_GetData() 					   								         -- get builder profiles..
		self:B_MissingProfile()                                                      -- check missing profiles link  
		self:B_LockLASMod(true)														 -- switch to 'las auto' and lock	
	else																			 -- addon not up..
		nTry = nTry + 1																 -- inc number of try to detect him
		if nTry == nMaxTry then 													 -- after try so many times we turn off 
			tB = nil 																 -- destroy init comm timer
			tPlugin.on = false														 -- turn off plugin 
			local tData = {owner = GP_NAME, on = false,}	
			Event_FireGenericEvent("Generic_GEAR_PLUGIN", "G_SET_OFF", tData)		 -- send this to 'gear'
		end
	end
end 

---------------------------------------------------------------------------------------------------
-- B_MissingProfile (to update saved profile after turning off/on plug-in)
---------------------------------------------------------------------------------------------------
function Gear_Builder:B_MissingProfile()

    -- nothing saved, we stop here
    if tSavedProfiles == nil then return end
    -- no builder profile existing, we remove all link saved
    if tLastProfiles == nil then tSavedProfiles = {} return end
   

	for nGearId, pGearId in pairs(tSavedProfiles) do
		local nBuildId = pGearId.root
		-- if saved link profile do not exist in actual builder profil, remove link from saved
		if tLastProfiles[nBuildId] == nil then tSavedProfiles[nGearId] = nil end
		
		-- update ui setting status button
		self:B_UpdateUI(nGearId)	
	end
end 

---------------------------------------------------------------------------------------------------
-- B_UpdateUI (to update 'gear' ui profile status button)
---------------------------------------------------------------------------------------------------
function Gear_Builder:B_UpdateUI(nGearId)
	-- request to 'gear' to update ui setting status button
	local tData = { owner = GP_NAME, uiid = 1, ngearid = nGearId, saved = tSavedProfiles,}
	Event_FireGenericEvent("Generic_GEAR_PLUGIN", "G_SET_UI_SETTING", tData)	
end

---------------------------------------------------------------------------------------------------
-- B_LockLASMod (to lock/unlock 'gear' lasmod to 'las auto')
---------------------------------------------------------------------------------------------------
function Gear_Builder:B_LockLASMod(bLock)
	
	local tFunc = { lasmod = 3, lock = bLock, func = { "LASMOD_AUTO",},}
	-- request to 'gear' to switch to lasmod auto and lock
	Event_FireGenericEvent("Generic_GEAR_PLUGIN", "G_SET_FUNC", tFunc)
end

---------------------------------------------------------------------------------------------------
-- ON_BUILDER_UPDATE
---------------------------------------------------------------------------------------------------
function Gear_Builder:ON_BUILDER_UPDATE(sAction, nBuildId, tBuildUpdate)
		
	-- keep last builder profile list if array exist
    if tBuildUpdate then 
		-- create builder profile copy array
		self:B_CreateArray(tBuildUpdate)
	end
		
   	-- Answer from 'builder' after a 'B_GETBUILD' request, get all build list
	if sAction == "B_BUILD" then
		-- 
	end
			
	-- fired by 'builder' after renamed a profil
	if sAction == "B_RENAME" then
		self:B_Renamed_Removed_Profile(nBuildId, tBuildUpdate[nBuildId].name)
	end

	-- fired by 'builder' after create a new profil
	if sAction == "B_CREATE" then
		self:B_NewProfile()
	end
	
	-- fired by 'builder' after removed a profil
	if sAction == "B_DELETE" then
		self:B_Renamed_Removed_Profile(nBuildId, nil)
	end
	
	-- fired by 'builder' after used a profil
	if sAction == "B_USE" then
		--
	end
end

---------------------------------------------------------------------------------------------------
-- B_GetData
---------------------------------------------------------------------------------------------------
function Gear_Builder:B_GetData()
    -- send request to builder to get actual profil list
	Event_FireGenericEvent("GenericBuilderUpdate", "B_GETBUILD", nil, nil)         
end

---------------------------------------------------------------------------------------------------
-- B_CreateArray
---------------------------------------------------------------------------------------------------
function Gear_Builder:B_CreateArray(tBuildUpdate)

    tLastProfiles = {}
	for nBuildId, pBuild in pairs(tBuildUpdate) do
		-- create array to work
						
		tLastProfiles[nBuildId] = {
								        name = pBuild.name,
								   abilities = pBuild.abilities,
								       tiers = pBuild.abilitiesTiers,
								      innate = pBuild.innateIndex,		
								   }
	end   
end

---------------------------------------------------------------------------------------------------
-- B_NewProfile
---------------------------------------------------------------------------------------------------
function Gear_Builder:B_NewProfile()
	
	-- repopulate list if window visible
	if self.BuilderWnd then 
		self:B_Populate(self.tData.ngearid)
	end
end

---------------------------------------------------------------------------------------------------
-- B_Renamed_Removed_Profile
---------------------------------------------------------------------------------------------------
function Gear_Builder:B_Renamed_Removed_Profile(nBuildId, sNewName)
    
	-- if removed profil is actually saved for a ngearid, remove it
	for nGearId, pGearId in pairs(tSavedProfiles) do
	
		if pGearId.root == nBuildId then
			-- if snewname contain data , blank name is not nil
			if sNewName then 
				tSavedProfiles[nGearId].target = sNewName
			else
				tSavedProfiles[nGearId] = nil
				if self.BuilderWnd then self:B_SetAbilitiesPreview(nBuildId) end
			end
		end
		
		-- update ui setting status button
		self:B_UpdateUI(nGearId)	
	end
  		
	-- repopulate list if window is visible
	if self.BuilderWnd then 
	   	self:B_Populate(self.tData.ngearid)
	end
end

---------------------------------------------------------------------------------------------------
-- B_Switch
---------------------------------------------------------------------------------------------------
function Gear_Builder:B_Switch(nBuildId)
	-- send request to 'builder' to activate a profile	
	Event_FireGenericEvent("GenericBuilderUpdate", "B_ACTIVATE", nBuildId, nil)
end

-----------------------------------------------------------------------------------------------
-- B_Show
-----------------------------------------------------------------------------------------------
function Gear_Builder:B_Show(tData)

	local nGearId = tData.ngearid
	local sName = tData.name
	
	if self.BuilderWnd then self.BuilderWnd:Destroy() end
		 	
	if self.xmlDoc == nil then self.xmlDoc = XmlDoc.CreateFromFile("Gear_Builder.xml") end
	self.BuilderWnd = Apollo.LoadForm(self.xmlDoc, "Dialog_wnd", nil, self)
	self.BuilderWnd:FindChild("TitleUp"):SetText(tPlugin.setting.name)
	self.BuilderWnd:FindChild("TitleUp"):SetData(nGearId)
	
	local wndInside = Apollo.LoadForm(self.xmlDoc, "Inside_wnd", self.BuilderWnd, self)
	wndInside:FindChild("TitleUp"):SetText(sName)
		
	-- populate 
	self:B_Populate(nGearId)
	self:LastAnchor(self.BuilderWnd, false)
	self.BuilderWnd:Show(true)
end

---------------------------------------------------------------------------------------------------
-- OnCloseDialog
---------------------------------------------------------------------------------------------------
function Gear_Builder:OnCloseDialog( wndHandler, wndControl, eMouseButton )

	if self.BuilderWnd == nil then return end
	self:LastAnchor(self.BuilderWnd, true)
	self.BuilderWnd:Destroy()
	self.BuilderWnd = nil
end

---------------------------------------------------------------------------------------------------
-- OnClickDropDownBtn
---------------------------------------------------------------------------------------------------
function Gear_Builder:OnClickDropDownBtn( wndHandler, wndControl, eMouseButton )
	wndControl:FindChild("UI_list_Frame"):Show(not wndControl:FindChild("UI_list_Frame"):IsShown())
end

---------------------------------------------------------------------------------------------------
-- B_Populate
---------------------------------------------------------------------------------------------------
function Gear_Builder:B_Populate(nGearId)

    self.BuilderWnd:FindChild("item_frame"):DestroyChildren()
	
	-- duplicate array to work
	local tItems = lGear.DeepCopy(tLastProfiles)

	-- add a blank item for no selected
	tItems[0] = ".."
	local sSelected = ".."
		
	--for nBuildId, pBuild in pairs(tLastProfiles) do
	for nBuildId, pBuild in pairs(tItems) do
						
		-- add item to list
		local wndItem = Apollo.LoadForm(self.xmlDoc, "UI_list_item_Btn", self.BuilderWnd:FindChild("item_frame"), self)
		-- set item text
		local sProfile = ".."
		if nBuildId ~= 0 then 
			sProfile = pBuild.name
		end		
		wndItem:SetText(sProfile)																																						
				
		-- keep nbuildid/profile/ngearid for each item in list
		local tData = {root = nBuildId, target = sProfile, ngearid = nGearId, }
		wndItem:SetData(tData)
								
		-- if this builder profil is linked with this ngearid set text
		local tDataLink = tSavedProfiles[nGearId]
		if tDataLink and nBuildId ~= 0 then
			sSelected = tDataLink.target
			self:B_SetAbilitiesPreview(tDataLink.root)
		end
	end
		
	self.BuilderWnd:FindChild("UI_list_Btn"):SetText(sSelected)
	self.BuilderWnd:FindChild("item_frame"):ArrangeChildrenVert()
end

---------------------------------------------------------------------------------------------------
-- B_SetAbilitiesPreview
---------------------------------------------------------------------------------------------------
function Gear_Builder:B_SetAbilitiesPreview(nBuildId)

	self.BuilderWnd:FindChild("Abilities_Frame"):DestroyChildren()
	if tLastProfiles[nBuildId] ==  nil then return end
      
	-- pixie default option
	local tOptions = {
  					 loc = {
    						fPoints = {0,0,1,1},
    					   nOffsets = {5,5,-5,-5},
  					  		  },
  					 }
		
    -- create all blank	
	local wndItem = {}
	for _= 1, 9 do
		wndItem[_] = Apollo.LoadForm(self.xmlDoc, "ItemWnd", self.BuilderWnd:FindChild("Abilities_Frame"), self)
	end    

		
	-- set innate 
	local nInnate = tLastProfiles[nBuildId].innate
	local nSpell = GameLib.GetClassInnateAbilitySpells().nSpellCount	
	if nSpell >= 2 then nSpell = 2 end
	tOptions.strSprite = GameLib.GetClassInnateAbilitySpells().tSpells[nInnate * nSpell]:GetIcon()	
	wndItem[1]:AddPixie(tOptions)	
	
	-- keep innate spell object
	local nSpellId = GameLib.GetClassInnateAbilitySpells().tSpells[nInnate * nSpell]:GetId()
	local oSpell = GameLib.GetSpell(nSpellId)
	if oSpell then wndItem[1]:SetData(oSpell) end

	

    -- set abilities
	local tBuild_Ab = lGear.DeepCopy(tLastProfiles[nBuildId].abilities)
	local tAbilityList = AbilityBook.GetAbilitiesList()
		
	for _, pSpellId in pairs(tBuild_Ab) do
		
	    local oSpell, nTier, sIcon = nil, nil, nil	
		   	  
	   	-- get ability information   	
		for _=1,#tAbilityList do
			if tAbilityList[_].nId == pSpellId then
			    nTier  = tLastProfiles[nBuildId].tiers[pSpellId]
				oSpell = tAbilityList[_].tTiers[nTier].splObject
				sIcon  = oSpell:GetIcon()
				break
			end	
		end	
		
		-- keep spell object
		if oSpell then wndItem[_+1]:SetData(oSpell) end
		
		-- add pixie	
		tOptions.strSprite = sIcon
	   	wndItem[_+1]:AddPixie(tOptions)
	end
		
    self.BuilderWnd:FindChild("Abilities_Frame"):ArrangeChildrenHorz()
end

---------------------------------------------------------------------------------------------------
-- OnSpellTooltip
---------------------------------------------------------------------------------------------------
function Gear_Builder:OnSpellTooltip( wndHandler, wndControl, x, y)
	if wndControl ~= wndHandler then return end
	
	local oSpell = wndControl:GetData()	
	if oSpell then
		Tooltip.GetSpellTooltipForm(self, wndHandler, oSpell, {bTiers = true})
	end
end

---------------------------------------------------------------------------------------------------
-- OnClickItemList
---------------------------------------------------------------------------------------------------
function Gear_Builder:OnClickItemList( wndHandler, wndControl, eMouseButton )
	
	wndControl:GetParent():GetParent():Show(false)
	
	local nBuildId = wndControl:GetData().root
	local sProfile = wndControl:GetData().target
	
	-- update selected text
	local sProfileName = ".."
	if nBuildId ~= 0 then
		sProfileName = sProfile
	end		
	self.BuilderWnd:FindChild("UI_list_Btn"):SetText(sProfileName)
				
	-- save ngearid/builder link		
	if wndControl:GetData().root == 0 then 
		-- nothing selected
		tSavedProfiles[wndControl:GetData().ngearid] = nil 
	else
		-- profile selected
		tSavedProfiles[wndControl:GetData().ngearid] = { root = nBuildId, target = sProfile,}
	end
	
	self:B_SetAbilitiesPreview(nBuildId)
	-- update ui setting status button
	self:B_UpdateUI(wndControl:GetData().ngearid)
end

-----------------------------------------------------------------------------------------------
-- LastAnchor
-----------------------------------------------------------------------------------------------
function Gear_Builder:LastAnchor(oWnd, bSave)
	
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
function Gear_Builder:OnWndMove( wndHandler, wndControl, nOldLeft, nOldTop, nOldRight, nOldBottom )
	self:LastAnchor(self.BuilderWnd, true)
end

---------------------------------------------------------------------------------------------------
-- OnSave
---------------------------------------------------------------------------------------------------
function Gear_Builder:OnSave(eLevel)
	
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
function Gear_Builder:OnRestore(eLevel,tData) 
	
	if eLevel ~= GameLib.CodeEnumAddonSaveLevel.Character then return end
	if tData.config.on ~= nil then tPlugin.on = tData.config.on end
	if tData.config.link ~= nil then 
		tSavedProfiles = tData.config.link
		tPlugin.ui_setting[1].Saved = tData.config.link
	end
end 

-----------------------------------------------------------------------------------------------
-- Gear_Builder Instance
-----------------------------------------------------------------------------------------------
local Gear_BuilderInst = Gear_Builder:new()
Gear_BuilderInst:Init()
