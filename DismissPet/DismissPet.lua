-----------------------------------------------------------------------------------------------
-- Client Lua Script for DismissPet
-- Copyright (c) NCsoft. All rights reserved
-----------------------------------------------------------------------------------------------
 
require "Window"
require "Apollo"
 
-----------------------------------------------------------------------------------------------
-- DismissPet Module Definition
-----------------------------------------------------------------------------------------------
local DismissPet = {} 

local DismissPet_PetBarIsShown = nil
-----------------------------------------------------------------------------------------------
-- Initialization
-----------------------------------------------------------------------------------------------
function DismissPet:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self 

    -- initialize variables here

    return o
end

function DismissPet:Init()
	local bHasConfigureFunction = false
	local strConfigureButtonText = ""
	local tDependencies = {
		"ClassResources",
	}
    Apollo.RegisterAddon(self, bHasConfigureFunction, strConfigureButtonText, tDependencies)
end
 

-----------------------------------------------------------------------------------------------
-- DismissPet OnLoad
-----------------------------------------------------------------------------------------------
function DismissPet:OnLoad()	
    -- load our form file
	self.xmlDoc = XmlDoc.CreateFromFile("DismissPet.xml")
	Apollo.LoadSprites("spr_CM_Engineer_Pet_Container_Extra_Bar.xml")

	self.timer = ApolloTimer.Create(0.25, true, "OnClassResourcesLoaded", self)
end

-----------------------------------------------------------------------------------------------
-- DismissPet Functions
-----------------------------------------------------------------------------------------------
function DismissPet:OnClassResourcesLoaded()
	
	--Check if the player is an Engineer
	local unitPlayer = GameLib.GetPlayerUnit()
	if not unitPlayer then
		return
	end	
	local eClassId =  unitPlayer:GetClassId()
	if eClassId ~= GameLib.CodeEnumClass.Engineer then
		self.timer = nil
		return
	end
	
	--Check if ClassResources Addon is finished loading
	addonClassResources = Apollo.GetAddon("ClassResources")
	if not addonClassResources then
		Apollo.AddAddonErrorText(self, "Could not load the main window for some reason.")
		self.timer = nil
		return
	end
	if self.xmlDoc == nil or not self.xmlDoc:IsLoaded() or not addonClassResources.wndMain or not addonClassResources.wndMain:IsValid() then
		return
	end
	self.timer = nil
	
	--PostHook OnPetBtn to save settings on click
	local orig_OnPetBtn = addonClassResources.OnPetBtn
	function addonClassResources:OnPetBtn(...) 
		orig_OnPetBtn(self, ...) 
		DismissPet_PetBarIsShown = self.wndMain:FindChild("PetBarContainer"):IsShown()
		--DismissPet:SaveSettings()
	end
	
	--Register Slash Commands
	Apollo.RegisterSlashCommand("dpunlock", "DismissPetUnlock", self)
	Apollo.RegisterSlashCommand("dplock", "DismissPetLock", self)
	Apollo.RegisterSlashCommand("dpreset", "DismissPetReset", self)
	
	self:SetupButton()
	
	Apollo.RegisterEventHandler("ShowActionBarShortcut", "OnShowActionBarShortcut", self)
end

-- Load and Setup Button
function DismissPet:SetupButton()
	self.wndMain = Apollo.LoadForm(self.xmlDoc, "DismissPetWindow", addonClassResources.wndMain:FindChild("PetBarIcons"), self)
	if self.wndMain == nil then
		Apollo.AddAddonErrorText(self, "Could not load the main window for some reason.")
		return
	end
	self.wndMain:SetAnchorOffsets(141, -2, 183, 40)
	
	--Resize windows to fit DismissPet Button
	local petBar = addonClassResources.wndMain:FindChild("PetBarContainer")
	petBar:FindChild("PetBarBG"):SetSprite("spr_CM_Engineer_Pet_Container_Extra_Bar:EngineerPetBar")		
	petBar:FindChild("PetBarIcons"):SetAnchorOffsets(58, 11, 242, 55)
	petBar:FindChild("ActionBarShortcut.12"):SetAnchorOffsets(0, 0, 41, 40)
	petBar:FindChild("ActionBarShortcut.13"):SetAnchorOffsets(47, 0, 88, 40)
	petBar:FindChild("ActionBarShortcut.15"):SetAnchorOffsets(94, 0, 135, 40)	
	petBar:FindChild("StanceMenuOpenerBtn"):SetAnchorOffsets(4, 3, 67, 68)
	petBar:FindChild("StanceMenuBG"):SetAnchorOffsets(-137, -210, 137, 26)	
	petBar:FindChild("PetText"):SetAnchorOffsets(25, 55, -15, -25)
	addonClassResources.wndMain:FindChild("PetBtn"):SetAnchorOffsets(-18, 67, 19, 102)
	addonClassResources.wndMain:FindChild("PetBtn"):SetStyle("NewWindowDepth",true) --Fix the layering issue 
	
	--Restore the petBar Location. Default location petBar:SetAnchorOffsets(-109, -255, 141, -157)
	if self.petBarLoc then
		petBar:MoveToLocation(self.petBarLoc)
	end
	
	--Fix petBar size if another addon changes it.
	if petBar:GetWidth() < 225 then
		petBar:SetAnchorOffsets(-109, -255, 141, -157)
	end
	
	--Restore whether the petBar is shown
	if DismissPet_PetBarIsShown ~= nil then
		if addonClassResources.wndMain:FindChild("PetBtn"):IsShown() then
			petBar:Show(DismissPet_PetBarIsShown)
			addonClassResources.wndMain:FindChild("PetBtn"):SetCheck(not DismissPet_PetBarIsShown)
		end
	end
	
	--Restore lock/unlocked
	if self.lock then
		addonClassResources.wndMain:FindChild("PetBarContainer"):SetStyle("Moveable", false)
	else
		addonClassResources.wndMain:FindChild("PetBarContainer"):SetStyle("Moveable", true)
	end

end

-- Save the window location and whether it is shown
function DismissPet:OnSave(eType)
	if eType ~= GameLib.CodeEnumAddonSaveLevel.Character then
		return
	end
	local locWindowLocation = addonClassResources.wndMain:FindChild("PetBarContainer") and addonClassResources.wndMain:FindChild("PetBarContainer"):GetLocation() or self.petBarLoc
	local locPetBarIsShown = DismissPet_PetBarIsShown
	if locPetBarIsShown  == nil then
		locPetBarIsShown  = addonClassResources.wndMain:FindChild("PetBarContainer") and addonClassResources.wndMain:FindChild("PetBarContainer"):IsShown()
	end
	local tSaved =
	{
		tWindowLocation = locWindowLocation and locWindowLocation:ToTable() or nil,
		tPetBarIsShown = locPetBarIsShown,
		tLock = self.lock,
	}

	return tSaved	
end

-- Restore the window location and whether it was shown
function DismissPet:OnRestore(eType, tSavedData)
	if tSavedData then
		if tSavedData.tWindowLocation then
			self.petBarLoc = WindowLocation.new(tSavedData.tWindowLocation)
		end
		if tSavedData.tPetBarIsShown ~= nil then
			DismissPet_PetBarIsShown = tSavedData.tPetBarIsShown
		end
		if tSavedData.tLock ~= nil then
			self.lock = tSavedData.tLock
		end
	end
end

--Restore PetBar settings when it is summoned
function DismissPet:OnShowActionBarShortcut()
	if DismissPet_PetBarIsShown ~= nil then
		if addonClassResources.wndMain:FindChild("PetBtn"):IsShown() then
			addonClassResources.wndMain:FindChild("PetBarContainer"):Show(DismissPet_PetBarIsShown)
			addonClassResources.wndMain:FindChild("PetBtn"):SetCheck(not DismissPet_PetBarIsShown)
		end
	end
end

-- on SlashCommand "/dpunlock"
function DismissPet:DismissPetUnlock()
	addonClassResources.wndMain:FindChild("PetBarContainer"):SetStyle("Moveable", true)
	self.lock = false
end

-- on SlashCommand "/dplock"
function DismissPet:DismissPetLock()
	addonClassResources.wndMain:FindChild("PetBarContainer"):SetStyle("Moveable", false)
	self.lock = true
end

-- on SlashCommand "/dpreset"
function DismissPet:DismissPetReset()
	self:SetupButton()
	addonClassResources.wndMain:FindChild("PetBarContainer"):SetAnchorOffsets(-109, -255, 141, -157)
	--addonClassResources.wndMain:FindChild("PetBarContainer"):SetStyle("Moveable", true)
end

---------------------------------------------------------------------------------------------------
-- DismissPetBtn Functions
---------------------------------------------------------------------------------------------------

function DismissPet:OnEngineerPetBtnMouseEnter( wndHandler, wndControl, x, y )
	wndHandler:SetBGColor("white")
	local strHover = Apollo.GetString("CRB_Dismiss")
	addonClassResources.wndMain:FindChild("PetText"):SetText(strHover)
end

function DismissPet:OnEngineerPetBtnMouseExit( wndHandler, wndControl, x, y )
	wndHandler:SetBGColor("UI_AlphaPercent50")
	addonClassResources.wndMain:FindChild("PetText"):SetText(addonClassResources.wndMain:FindChild("PetText"):GetData() or "")
end

function DismissPet:OnGeneratePetCommandTooltip( wndHandler, wndControl, eToolTipType, x, y )
	local xml = nil
	xml = XmlDoc.new()
	xml:AddLine("Commands your bots to self destruct.")
	wndControl:SetTooltipDoc(xml)
end

-----------------------------------------------------------------------------------------------
-- DismissPet Instance
-----------------------------------------------------------------------------------------------
local DismissPetInst = DismissPet:new()
DismissPetInst:Init()
