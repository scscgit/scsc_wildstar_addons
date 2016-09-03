-----------------------------------------------------------------------------------------------
-- Client Lua Script for PotatoInterrupt
-- Copyright (c) Tyler Hardy 2013-2014 All rights reserved
-----------------------------------------------------------------------------------------------
 
require "Window"
 
-----------------------------------------------------------------------------------------------
-- PotatoInterrupt Module Definition
-----------------------------------------------------------------------------------------------
local InterruptArmor = {}
local PotatoInterrupt = {}
local Defaults = _G["PUIDefaults"]["Interrupt"]

-----------------------------------------------------------------------------------------------
-- Initialization
-----------------------------------------------------------------------------------------------

function PotatoInterrupt:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self 

    -- initialize variables here

    return o
end

function PotatoInterrupt:Init()
	local bHasConfigureFunction = false
	local strConfigureButtonText = ""
	local tDependencies = {
		"PotatoLib",
	}
    Apollo.RegisterAddon(self, bHasConfigureFunction, strConfigureButtonText, tDependencies)
end
 
function PotatoInterrupt:OnLoad() --Loaded 1st
	self.xmlDoc = XmlDoc.CreateFromFile("PotatoInterrupt.xml")
	self.xmlDoc:RegisterCallback("OnDocLoaded", self)
end

function PotatoInterrupt:OnDocLoaded() --Loaded 3rd
	if self.xmlDoc == nil or not self.xmlDoc:IsLoaded() then	return	end
	
	--Apollo.RegisterEventHandler("WindowManagementReady", "OnWindowManagementReady", self)
	Apollo.RegisterEventHandler("CharacterCreated", "OnCharacterCreated", self)
	Apollo.RegisterEventHandler("TargetUnitChanged", "OnTargetUnitChanged", self)
	Apollo.RegisterEventHandler("AlternateTargetUnitChanged", "OnAlternateTargetUnitChanged", self)
	
	Apollo.RegisterEventHandler("PotatoEditor",					"EditorModeToggle", self)
	Apollo.RegisterEventHandler("PotatoReset",					"ResetAll", self)
	Apollo.RegisterEventHandler("PotatoResetPopulate",			"PopulateResetFeatures", self)
	
	Apollo.RegisterEventHandler("VarChange_FrameCount", "OnFrame", self)
	--self.timer = ApolloTimer.Create(0.033, true, "OnFrame", self)
	
	for key, val in pairs(Defaults) do
		if type(val) == "table" and key ~= "__index" and string.find(key, "lua") then
			self[key] = InterruptArmor:new(self[key] or val)
			self[key]:Init(self)
		end
	end
end

function PotatoInterrupt:PopulateResetFeatures()
	PotatoLib:AddResetParent("Interrupt Armor")
	
	for key, val in pairs(Defaults) do
		if type(val) == "table" and key ~= "__index" and string.find(key, "lua") then
			PotatoLib:AddResetItem(val.name, "Interrupt Armor", self[key])
		end
	end
end

function PotatoInterrupt:OnWindowManagementReady()
	--Event_FireGenericEvent("WindowManagementAdd", {wnd = self.wndPlayerFrame.wndFrame,		strName = "[PUI] Player Frame"})
end

function PotatoInterrupt:OnFrame()
	self:OnCharacterCreated()
end

function PotatoInterrupt:OnCharacterCreated()
	local unitPlayer = GameLib.GetPlayerUnit()
	
	if unitPlayer ~= nil then
		local unitTarget = unitPlayer:GetTarget()
		local altPlayerTarget = unitPlayer:GetAlternateTarget()
	
		self.luaPlayerIA:SetTarget(unitPlayer)
		self.luaTargetIA:SetTarget(unitTarget)
		self.luaToTIA:SetTarget(unitTarget and unitTarget:GetTarget() or nil)
		self.luaFocusIA:SetTarget(altPlayerTarget)
	end
end

function PotatoInterrupt:OnTargetUnitChanged(unitTarget)
	self.luaTargetIA:SetTarget(unitTarget)
	self.luaToTIA:SetTarget(unitTarget and unitTarget:GetTarget() or nil)
end

function PotatoInterrupt:OnAlternateTargetUnitChanged(unitTarget)
	self.luaFocusIA:SetTarget(altPlayerTarget)
end

function PotatoInterrupt:EditorModeToggle(bState)
	bEditorMode = bState
	
	for key, val in pairs(self) do
		if type(val) == "table" and val.wndIA then
			if bEditorMode then
				val.wndCover = Apollo.LoadForm("../PotatoLib/PotatoLib.xml", "EditorCover", val.wndIA, val)
				val.wndCover:SetText(val.name)
				val.wndCover:FindChild("Reset"):Show(false)
				val.wndCover:FindChild("Settings"):Show(false)
				val.wndCover:FindChild("Lock"):Show(false)
				if val.border.show then
					val.wndCover:SetAnchorOffsets(val.border.size, val.border.size, -val.border.size, -val.border.size)
				else
					val.wndCover:SetAnchorOffsets(0,0,0,0)
				end
			else
				if val.wndCover then
					val.wndCover:Destroy()
					val.wndCover = nil
				end
				if val.wndEditor then
					val.wndEditor:Destroy()
					val.wndEditor = nil
				end
			end
			val.wndIA:SetStyle("Moveable", bEditorMode)
			val.wndIA:SetStyle("Sizable", bEditorMode)
			val.wndIA:SetStyle("IgnoreMouse", not bEditorMode)
			val.wndIA:Show(bEditorMode)
		end
	end
end

function PotatoInterrupt:ResetAll()
	for key, val in pairs(Defaults) do
		if type(val) == "table" and key ~= "__index" and string.find(key, "lua") then
			self[key].wndIA:Destroy()
			self[key] = nil
			
			self[key] = InterruptArmor:new(val)
			self[key]:Init(self)
		end
	end
end

function PotatoInterrupt:OnSave(eLevel)
    if eLevel ~= GameLib.CodeEnumAddonSaveLevel.Character then return end

	self.xmlDoc = nil
	
	local tSaveData = {}
	
    for key,val in pairs(self) do
		if val.luaIASystem then
			val.luaIASystem = nil
			val.anchors = {val.wndIA:GetAnchorPoints()}
			val.offsets = {val.wndIA:GetAnchorOffsets()}
		end
		tSaveData[key] = val
	end
	
	return tSaveData
end

function PotatoInterrupt:OnRestore(eLevel, tData) --Loaded 2nd
    if eLevel ~= GameLib.CodeEnumAddonSaveLevel.Character then return end
	
    for key,val in pairs(tData) do
		self[key] = TableUtil:Copy(val)
	end
end

-----------------------------------------------------------------------------------------------
-- InterruptArmor Functions
-----------------------------------------------------------------------------------------------
function InterruptArmor:new(o)
	o = o or {}
	setmetatable(o, self)
	self.__index = self
	return o
end

function InterruptArmor:Init(luaIASystem)
	Apollo.LinkAddon(luaIASystem, self)
	
	self.luaIASystem = luaIASystem
	self.wndIA = Apollo.LoadForm(luaIASystem.xmlDoc, "InterruptArmor", "FixedHudStratumHigh", self)
	
	self.unitLastTarget = nil
	
	self:CreateFrame()
end

function InterruptArmor:Reset()
	local strIA = ""
	
	for key, val in pairs(self.luaIASystem) do
		if val == self then
			strIA = key
			break
		end
	end
	
	for key, val in pairs(Defaults[strIA]) do
		if key ~= "__index" then
			self[key] = TableUtil:Copy(val)
		end
	end
	
	self:Position(self.anchors, self.offsets)
	--self:UpdateIAAppearance()
end

function InterruptArmor:OnPRFReset()
	self:Reset()
end

function InterruptArmor:CreateFrame() --Creates or updates the visual appearance of the frame. Called when the frame is customized.
	self:Position(self.anchors, self.offsets)
end

function InterruptArmor:Position(tAnchors, tOffsets)
	self.wndIA:SetAnchorPoints(unpack(tAnchors))
	self.wndIA:SetAnchorOffsets(unpack(tOffsets))
end

function InterruptArmor:SetTarget(unitTarget)
	self.unitTarget = unitTarget
	self:OnUpdate()
end

function InterruptArmor:OnUpdate()
	local bTargetChanged = false
	local unitTarget = self.unitTarget
		
	if unitTarget ~= nil and unitTarget:GetInterruptArmorMax() > 0 then		
		local nCCArmorMax = unitTarget:GetInterruptArmorMax() or 0
		
		if unitTarget:GetHealth() ~= nil and unitTarget:GetMaxHealth() > 0 then
			if not self.wndIA:IsShown() then
				self.wndIA:Show(true)
			end
			if self.wndIA:GetSprite() ~= "IABacker" then
				self.wndIA:SetSprite("PotatoSprites:IABacker")
			end
			self.wndIA:FindChild("Value"):SetText(unitTarget:GetInterruptArmorValue().."/"..unitTarget:GetInterruptArmorMax())
		else
			self.wndIA:Show(false)
		end
	elseif unitTarget ~= nil and unitTarget:GetInterruptArmorMax() == -1 then
		if unitTarget:GetHealth() ~= nil and unitTarget:GetMaxHealth() > 0 then
			if not self.wndIA:IsShown() then
				self.wndIA:Show(true)
			end
			if self.wndIA:GetSprite() ~= "IAInvuln" then
				self.wndIA:SetSprite("PotatoSprites:IAInvuln")
			end
			self.wndIA:FindChild("Value"):SetText("")
		else
			self.wndIA:Show(false)
		end
	else
		self.wndIA:Show(bEditorMode)
	end
end

-----------------------------------------------------------------------------------------------
-- PotatoInterrupt Instance
-----------------------------------------------------------------------------------------------
local PotatoInterruptInst = PotatoInterrupt:new()
PotatoInterruptInst:Init()
