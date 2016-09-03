-----------------------------------------------------------------------------------------------
-- Client Lua Script for BuffMaster
-- Copyright (c) James Parker 2014. All rights reserved
-----------------------------------------------------------------------------------------------
 
require "Window"
 
local BuffMaster = {} 
 
-----------------------------------------------------------------------------------------------
-- Initialization
-----------------------------------------------------------------------------------------------
function BuffMaster:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self 

    return o
end

function BuffMaster:Init()
	local bHasConfigureFunction = false
	local strConfigureButtonText = ""
	local tDependencies = {
	}
    Apollo.RegisterAddon(self, bHasConfigureFunction, strConfigureButtonText, tDependencies)
end
 

-----------------------------------------------------------------------------------------------
-- BuffMaster OnLoad
-----------------------------------------------------------------------------------------------
function BuffMaster:OnLoad()
	Apollo.LoadSprites("BarTextures.xml")
	self.xmlDoc = XmlDoc.CreateFromFile("BuffMaster.xml")
	self.xmlDoc:RegisterCallback("OnDocLoaded", self)
end

-----------------------------------------------------------------------------------------------
-- BuffMaster OnDocLoaded
-----------------------------------------------------------------------------------------------
function BuffMaster:OnDocLoaded()
	if self.xmlDoc ~= nil and self.xmlDoc:IsLoaded() then
	    self.wndMain = Apollo.LoadForm(self.xmlDoc, "BuffMasterForm", nil, self)
		if self.wndMain == nil then
			Apollo.AddAddonErrorText(self, "Could not load the main window for some reason.")
			return
		end
		
	    self.wndMain:Show(false, true)

	    self.buffs = BuffMasterLibs.DisplayBlock.new(self.xmlDoc)
	    self.buffs:SetName("Player Buffs")
	    self.buffs:SetPosition(0.3, 0.5)
	    self.buffs:AnchorFromTop(true)

	    self.debuffs = BuffMasterLibs.DisplayBlock.new(self.xmlDoc)
	    self.debuffs:SetName("Player Debuffs")
	    self.debuffs:SetPosition(0.7, 0.5)
	    self.debuffs:AnchorFromTop(true)

	    self.targetBuffs = BuffMasterLibs.DisplayBlock.new(self.xmlDoc)
	    self.targetBuffs:SetName("Target Buffs")
	    self.targetBuffs:SetPosition(0.3, 0.4)
	    self.targetBuffs:AnchorFromTop(false)

	    self.targetDebuffs = BuffMasterLibs.DisplayBlock.new(self.xmlDoc)
	    self.targetDebuffs:SetName("Target Debuffs")
	    self.targetDebuffs:SetPosition(0.7, 0.4)
	    self.targetDebuffs:AnchorFromTop(false)

	    self.focusBuffs = BuffMasterLibs.DisplayBlock.new(self.xmlDoc)
	    self.focusBuffs:SetName("Focus Buffs")
	    self.focusBuffs:SetPosition(0.1, 0.5)
	    self.focusBuffs:AnchorFromTop(true)
	    self.focusBuffs:SetEnabled(false)

	    self.focusDebuffs = BuffMasterLibs.DisplayBlock.new(self.xmlDoc)
	    self.focusDebuffs:SetName("Focus Debuffs")
	    self.focusDebuffs:SetPosition(0.1, 0.4)
	    self.focusDebuffs:AnchorFromTop(false)
	    self.focusDebuffs:SetEnabled(false)

	    self.cooldowns = BuffMasterLibs.DisplayBlock.new(self.xmlDoc)
	    self.cooldowns:SetName("Cooldowns")
	    self.cooldowns:SetPosition(0.5, 0.4)
	    self.cooldowns:AnchorFromTop(false)

	    if self.saveData ~= nil then
	    	self:LoadSaveData(self.saveData)
	    end
	
		self.colorPicker = BuffMasterLibs.ColorPicker.new(self.xmlDoc)

		Apollo.RegisterEventHandler("VarChange_FrameCount", "OnFrame", self)
		Apollo.RegisterSlashCommand("bm", "OnBuffMasterOn", self)

		self:InitializeConfigForm()

		self.Loaded = true
	end
end

function BuffMaster:InitializeConfigForm()
	local groupOptionsList = self.wndMain:FindChild("GroupOptionsList")
	groupOptionsList:DestroyChildren()

	local buffOptions = Apollo.LoadForm(self.xmlDoc, "SubForms.GroupOptions", groupOptionsList, self)
	buffOptions:SetData(self.buffs)
	buffOptions:FindChild("OptionsLabel"):SetText("Player Buff Bar Options")
	self:InitializeGroup(buffOptions, self.buffs)
	

	local debuffOptions = Apollo.LoadForm(self.xmlDoc, "SubForms.GroupOptions", groupOptionsList, self)
	debuffOptions:SetData(self.debuffs)
	debuffOptions:FindChild("OptionsLabel"):SetText("Player Debuff Bar Options")
	self:InitializeGroup(debuffOptions, self.debuffs)

	local targetBuffOptions = Apollo.LoadForm(self.xmlDoc, "SubForms.GroupOptions", groupOptionsList, self)
	targetBuffOptions:SetData(self.targetBuffs)
	targetBuffOptions:FindChild("OptionsLabel"):SetText("Target Buff Bar Options")
	self:InitializeGroup(targetBuffOptions, self.targetBuffs)

	local targetDebuffOptions = Apollo.LoadForm(self.xmlDoc, "SubForms.GroupOptions", groupOptionsList, self)
	targetDebuffOptions:SetData(self.targetDebuffs)
	targetDebuffOptions:FindChild("OptionsLabel"):SetText("Target Debuff Bar Options")
	self:InitializeGroup(targetDebuffOptions, self.targetDebuffs)

	local focusBuffOptions = Apollo.LoadForm(self.xmlDoc, "SubForms.GroupOptions", groupOptionsList, self)
	focusBuffOptions:SetData(self.focusBuffs)
	focusBuffOptions:FindChild("OptionsLabel"):SetText("Focus Buff Bar Options")
	self:InitializeGroup(focusBuffOptions, self.focusBuffs)

	local focusDebuffOptions = Apollo.LoadForm(self.xmlDoc, "SubForms.GroupOptions", groupOptionsList, self)
	focusDebuffOptions:SetData(self.focusDebuffs)
	focusDebuffOptions:FindChild("OptionsLabel"):SetText("Focus Debuff Bar Options")
	self:InitializeGroup(focusDebuffOptions, self.focusDebuffs)

	local cooldownOptions = Apollo.LoadForm(self.xmlDoc, "SubForms.GroupOptions", groupOptionsList, self)
	cooldownOptions:SetData(self.cooldowns)
	cooldownOptions:FindChild("OptionsLabel"):SetText("Cooldown Bar Options")
	self:InitializeGroup(cooldownOptions, self.cooldowns)
	
	groupOptionsList:ArrangeChildrenVert()
end

function BuffMaster:InitializeGroup(groupFrame, group)
	groupFrame:FindChild("Enabled"):SetCheck(group:IsEnabled())
	groupFrame:FindChild("BackgroundColor"):FindChild("Text"):SetTextColor(group.bgColor)
	groupFrame:FindChild("BarColor"):FindChild("Text"):SetTextColor(group.barColor)
	groupFrame:FindChild("StartFromTop"):SetCheck(group.anchorFromTop)
	groupFrame:FindChild("BarWidth"):SetValue(group.barSize.Width)
	groupFrame:FindChild("BarWidthValue"):SetText(string.format("%.f", group.barSize.Width))
	groupFrame:FindChild("BarHeight"):SetValue(group.barSize.Height)
	groupFrame:FindChild("BarHeightValue"):SetText(string.format("%.f", group.barSize.Height))
	groupFrame:FindChild("IncludeFilter"):SetCheck(group.includeFilter)
	groupFrame:FindChild("BarDisplay"):SetCheck(group.displayAsBar)
	local excludedOptions = groupFrame:FindChild("ExcludedOptions")
	excludedOptions:DestroyChildren()
	for _, exclusion in pairs(group.Exclusions) do
		local filter = Apollo.LoadForm(self.xmlDoc, "ExcludedOption", excludedOptions, self)
		filter:SetText(exclusion)
	end
	excludedOptions:ArrangeChildrenVert()
end

function BuffMaster:OnSave(eLevel)
	if eLevel ~= GameLib.CodeEnumAddonSaveLevel.Character then
        return nil
    end
	local saveData = { 
		buffs = self.buffs:GetSaveData(),
		debuffs = self.debuffs:GetSaveData(),
		cooldowns = self.cooldowns:GetSaveData(),
		targetBuffs = self.targetBuffs:GetSaveData(),
		targetDebuffs = self.targetDebuffs:GetSaveData(),
		focusBuffs = self.focusBuffs:GetSaveData(),
		focusDebuffs = self.focusDebuffs:GetSaveData()
	}
	
	return saveData
end

function BuffMaster:OnRestore(eLevel, tData)
	if eLevel ~= GameLib.CodeEnumAddonSaveLevel.Character then
		return nil
	end

	if self.Loaded then
		self:LoadSaveData(tData)
		self:InitializeConfigForm()	
	else
		self.saveData = tData
	end
end

function BuffMaster:LoadSaveData(tData)
	if tData.buffs then
		self.buffs:Load(tData.buffs)
	end

	if tData.debuffs then
		self.debuffs:Load(tData.debuffs)
	end

	if tData.cooldowns then
		self.cooldowns:Load(tData.cooldowns)
	end

	if tData.targetBuffs then
		self.targetBuffs:Load(tData.targetBuffs)
	end

	if tData.targetDebuffs then
		self.targetDebuffs:Load(tData.targetDebuffs)
	end

	if tData.focusBuffs then
		self.focusBuffs:Load(tData.focusBuffs)
	end

	if tData.focusDebuffs then
		self.focusDebuffs:Load(tData.focusDebuffs)
	end
end

function BuffMaster:OnFrame()
	self.currentPass = not self.currentPass

	local player = GameLib.GetPlayerUnit()
	if player then
		self.buffs:ProcessBuffs(player:GetBuffs().arBeneficial)
		self.debuffs:ProcessBuffs(player:GetBuffs().arHarmful)
		self.cooldowns:ProcessSpells()

		local focus = player:GetAlternateTarget()
		if focus then
			self.focusBuffs:ProcessBuffs(focus:GetBuffs().arBeneficial)
			self.focusDebuffs:ProcessBuffs(focus:GetBuffs().arHarmful)
		else
			self.focusBuffs:ClearAll()
			self.focusDebuffs:ClearAll()
		end
	end

	local target = GameLib.GetTargetUnit()
	if target then
		self.targetBuffs:ProcessBuffs(target:GetBuffs().arBeneficial)
		self.targetDebuffs:ProcessBuffs(target:GetBuffs().arHarmful)
	else
		self.targetBuffs:ClearAll()
		self.targetDebuffs:ClearAll()
	end

	self.buffs:ArrangeItems()
	self.debuffs:ArrangeItems()
	self.targetBuffs:ArrangeItems()
	self.targetDebuffs:ArrangeItems()
	self.focusBuffs:ArrangeItems()
	self.focusDebuffs:ArrangeItems()
	self.cooldowns:ArrangeItems()
end

-----------------------------------------------------------------------------------------------
-- BuffMaster Functions
-----------------------------------------------------------------------------------------------
-- Define general functions here

function BuffMaster:OnBuffMasterOn()
	self:InitializeConfigForm()
	self.wndMain:Invoke()
end


-----------------------------------------------------------------------------------------------
-- BuffMasterForm Functions
-----------------------------------------------------------------------------------------------
-- when the OK button is clicked
function BuffMaster:OnOK()
	self.wndMain:Close()
end

function BuffMaster:OnBuffEnabledChanged( wndHandler, wndControl, eMouseButton )
	local group = wndHandler:GetParent():GetData()
	group:SetEnabled(wndHandler:IsChecked())
end

function BuffMaster:OnResetBarPositions( wndHandler, wndControl, eMouseButton )
	self.buffs:ResetPosition()
	self.debuffs:ResetPosition()
	self.targetBuffs:ResetPosition()
	self.targetDebuffs:ResetPosition()
	self.focusBuffs:ResetPosition()
	self.focusDebuffs:ResetPosition()
	self.cooldowns:ResetPosition()
end

---------------------------------------------------------------------------------------------------
-- Appearance Functions
---------------------------------------------------------------------------------------------------

function BuffMaster:OnBarWidthChanged( wndHandler, wndControl, fNewValue, fOldValue )
	local group = wndHandler:GetParent():GetData()
	group:SetBarWidth(fNewValue)
	wndHandler:GetParent():FindChild("BarWidthValue"):SetText(string.format("%.f", fNewValue))
end

function BuffMaster:OnBarWidthValueChanged( wndHandler, wndControl, strText )
	local group = wndHandler:GetParent():GetData()
	local value = tonumber(strText)
	wndHandler:SetText(tostring(value))
	wndHandler:GetParent():FindChild("BarWidth"):SetValue(value)
	group:SetBarWidth(value)
end

function BuffMaster:OnBarHeightChanged( wndHandler, wndControl, fNewValue, fOldValue )
	local group = wndHandler:GetParent():GetData()
	group:SetBarHeight(fNewValue)
	wndHandler:GetParent():FindChild("BarHeightValue"):SetText(string.format("%.f", fNewValue))
end

function BuffMaster:OnBarHeightValueChanged( wndHandler, wndControl, strText )
	local group = wndHandler:GetParent():GetData()
	local value = tonumber(strText)
	wndHandler:SetText(tostring(value))
	wndHandler:GetParent():FindChild("BarHeight"):SetValue(value)
	group:SetBarHeight(value)
end

function BuffMaster:EditBuffBackgroundColor( wndHandler, wndControl, eMouseButton )
	local group = wndHandler:GetParent():GetData()
	local color = group.bgColor
	self.colorPicker:OpenColorPicker(color, function()
		wndHandler:FindChild("Text"):SetTextColor(color)
		group:SetBGColor(color)
	end)
end

function BuffMaster:EditBuffBarColor( wndHandler, wndControl, eMouseButton )
	local group = wndHandler:GetParent():GetData()
	local color = group.barColor
	self.colorPicker:OpenColorPicker(color, function()
		wndHandler:FindChild("Text"):SetTextColor(color)
		group:SetBarColor(color)
	end)
end

function BuffMaster:OnMoveBars( wndHandler, wndControl, eMouseButton )
	if wndHandler:GetText() == "Move Bars" then
		wndHandler:SetText("Lock Bars")
		self.buffs:SetMovable(true)
		self.debuffs:SetMovable(true)
		self.targetBuffs:SetMovable(true)
		self.targetDebuffs:SetMovable(true)
		self.focusBuffs:SetMovable(true)
		self.focusDebuffs:SetMovable(true)
		self.cooldowns:SetMovable(true)
	else
		wndHandler:SetText("Move Bars")
		self.buffs:SetMovable(false)
		self.debuffs:SetMovable(false)
		self.targetBuffs:SetMovable(false)
		self.targetDebuffs:SetMovable(false)
		self.focusBuffs:SetMovable(false)
		self.focusDebuffs:SetMovable(false)
		self.cooldowns:SetMovable(false)
	end
end


function BuffMaster:OnExcludedChanged( wndHandler, wndControl, strText )
	if strText == "" then
		wndHandler:FindChild("Placeholder"):Show(true)
	else
		wndHandler:FindChild("Placeholder"):Show(false)
	end
end

function BuffMaster:OnAddExclusion( wndHandler, wndControl, eMouseButton )
	local group = wndHandler:GetParent():GetData()
	local excludedOptions = wndHandler:GetParent():FindChild("ExcludedOptions")
	local filter = Apollo.LoadForm(self.xmlDoc, "ExcludedOption", excludedOptions, self)
	local exclusionName = wndHandler:GetParent():FindChild("Excluded"):GetText()
	filter:SetText(exclusionName)
	group:AddExclusion(exclusionName)
	excludedOptions:ArrangeChildrenVert()
end

function BuffMaster:OnExclusionRemove( wndHandler, wndControl, eMouseButton )
	local group = wndHandler:GetParent():GetData()
	local excludedOptions = wndHandler:GetParent():FindChild("ExcludedOptions")
	for _, excludedOption in pairs(excludedOptions:GetChildren()) do
		if excludedOption:IsChecked() then
			group:RemoveExclusion(excludedOption:GetText())
			excludedOption:Destroy()
		end
	end
	excludedOptions:ArrangeChildrenVert()
end

function BuffMaster:OnBuffStartFromTopChanged( wndHandler, wndControl, eMouseButton )
	local group = wndHandler:GetParent():GetData()
	group:AnchorFromTop(wndHandler:IsChecked())
end

function BuffMaster:OnIncludeFilterChanged( wndHandler, wndControl, eMouseButton )
	local group = wndHandler:GetParent():GetData()
	group:SetIncludeFilter(wndHandler:IsChecked())
end

function BuffMaster:OnBarDisplayChanged( wndHandler, wndControl, eMouseButton )
	local group = wndHandler:GetParent():GetData()
	group:SetBarDisplay(wndHandler:IsChecked())
end

-----------------------------------------------------------------------------------------------
-- BuffMaster Instance
-----------------------------------------------------------------------------------------------
local BuffMasterInst = BuffMaster:new()
BuffMasterInst:Init()
