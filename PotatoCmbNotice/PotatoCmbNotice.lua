-----------------------------------------------------------------------------------------------
-- Client Lua Script for PotatoCmbNotice
-- Copyright (c) Tyler T. Hardy. All rights reserved
-----------------------------------------------------------------------------------------------
 
require "Window"
 
-----------------------------------------------------------------------------------------------
-- PotatoCmbNotice Module Definition
-----------------------------------------------------------------------------------------------
local PotatoCmbNotice = {} 
local Defaults = _G["PUIDefaults"]["CmbNotice"]

-----------------------------------------------------------------------------------------------
-- Initialization
-----------------------------------------------------------------------------------------------

function PotatoCmbNotice:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self 

    -- initialize variables here

    return o
end

function PotatoCmbNotice:Init()
	local bHasConfigureFunction = false
	local strConfigureButtonText = ""
	local tDependencies = {
		"PotatoLib"
	}
    Apollo.RegisterAddon(self, bHasConfigureFunction, strConfigureButtonText, tDependencies)
end

function PotatoCmbNotice:Reset()
	for key, val in pairs(Defaults) do
		if key ~= "__index" then
			self[key] = TableUtil:Copy(val)
		end
	end
	
	self:Position()
	self:UpdateAppearance()
end

function PotatoCmbNotice:OnSave(eLevel)
    if eLevel ~= GameLib.CodeEnumAddonSaveLevel.Character then return end

	self.xmlDoc = nil
	
	local tSaveData = {}

    for key,val in pairs(self) do
		if key ~= "__index" then
			tSaveData[key] = val
		end
	end
	
	tSaveData.offsets = {self.wndCmbNotice:GetAnchorOffsets()}
	tSaveData.anchors = {self.wndCmbNotice:GetAnchorPoints()}

	return tSaveData
end

function PotatoCmbNotice:OnRestore(eLevel, tData) --Loaded 2nd
    if eLevel ~= GameLib.CodeEnumAddonSaveLevel.Character then return end
	
    for key,val in pairs(tData) do
		self[key] = TableUtil:Copy(val)
	end
	
	self.bLoaded = true
end

-----------------------------------------------------------------------------------------------
-- PotatoCmbNotice OnLoad
-----------------------------------------------------------------------------------------------
function PotatoCmbNotice:OnLoad() --Loaded 1st
	self.xmlDoc = XmlDoc.CreateFromFile("PotatoCmbNotice.xml")
	self.xmlDoc:RegisterCallback("OnDocLoaded", self)
end

function PotatoCmbNotice:OnDocLoaded() --Loaded 3rd
	if self.xmlDoc == nil and not self.xmlDoc:IsLoaded() then return end
	
	self.wndCmbNotice = Apollo.LoadForm(self.xmlDoc, "CombatNotice", "FixedHudStratum", self)
	
	for key, val in pairs(Defaults) do
		if key ~= "__index" then
			--[[if self[key] then
				Print("CmbNotice"..key..":Loaded")
			else
				Print("CmbNotice"..key..":Defaulted")
			end]]--
			self[key] = self[key] or val --Load from restored values (self[key] from OnRestore()), or use the default (val).
		end
	end
	
	self:Position()
	self:UpdateAppearance()
	
	Apollo.RegisterEventHandler("UnitEnteredCombat", 			"OnEnteredCombat", self)

	Apollo.RegisterEventHandler("PotatoEditor",					"EditorModeToggle", self)
	Apollo.RegisterEventHandler("PotatoReset",					"Reset", self)
	Apollo.RegisterEventHandler("PotatoSettings",				"PopulateSettingsList", self)
	Apollo.RegisterEventHandler("PotatoResetPopulate",			"PopulateResetFeatures", self)
	
	if GameLib.GetPlayerUnit ~= nil then
		self:OnCharacterCreated()
	else
		Apollo.RegisterEventHandler("CharacterCreated", "OnCharacterCreated", self)
	end
end

function PotatoCmbNotice:PopulateResetFeatures()
	PotatoLib:AddResetItem("Combat Notification", nil, self)
end

function PotatoCmbNotice:OnPRFReset()
	self:Reset()
end

-----------------------------------------------------------------------------------------------
-- PotatoCmbNotice Functions
-----------------------------------------------------------------------------------------------
-- Define general functions here

function PotatoCmbNotice:Position()
	self.wndCmbNotice:SetAnchorPoints(unpack(self.anchors))
	self.wndCmbNotice:SetAnchorOffsets(unpack(self.offsets))
	--Print(string.format("%s: %s, %s, %s, %s", self.name, unpack(self.offsets)))
end

function PotatoCmbNotice:UpdateAppearance() --Creates or updates the visual appearance of the frame. Called when the frame is customized.
	--Positioning
	--self:Position(self.anchors, self.offsets)
	
	--Background and Border
	--self.wndMountHP:FindChild("Content"):SetStyle("Picture", self.background.show)
	--PotatoLib:UpdateBorder(self.wndMountHP, self.wndMountHP:FindChild("Content"), self.border)
end

function PotatoCmbNotice:EditorModeToggle(bState)
	bEditorMode = bState
	
	if bEditorMode then
		self.wndCover = Apollo.LoadForm("../PotatoLib/PotatoLib.xml", "EditorCover", self.wndCmbNotice, self)
		self.wndCover:SetText(self.name)
		--self.wndCover:FindChild("Reset"):Show(false)
		--self.wndCover:FindChild("Lock"):Show(false)
		--[[if self.border.show then
			self.wndCover:SetAnchorOffsets(self.border.size, self.border.size, -self.border.size, -self.border.size)
		else]]--
			self.wndCover:SetAnchorOffsets(0,0,0,0)
		--end
		self.wndCmbNotice:Show(true)
	else
		self.wndCover:Destroy()
		self.wndCover = nil
		if self.wndEditor then
			self.wndEditor:Destroy()
			self.wndEditor = nil
		end
		self.wndCmbNotice:Show(GameLib.GetPlayerUnit():IsInCombat())
	end
	self.wndCmbNotice:SetStyle("Moveable", bEditorMode)
	self.wndCmbNotice:SetStyle("Sizable", bEditorMode)
	self.wndCmbNotice:SetStyle("IgnoreMouse", not bEditorMode)
end

-----------------------------------------------------------------------------------------------
-- Event Functions
-----------------------------------------------------------------------------------------------
-- Define event functions here

function PotatoCmbNotice:OnCharacterCreated()
	local unitPlayer = GameLib.GetPlayerUnit()
	
	if unitPlayer ~= nil then
		self.wndCmbNotice:Show(unitPlayer:IsInCombat(), true)
	end
	self:Position()
end

function PotatoCmbNotice:OnEnteredCombat(unit, bInCombat)
	local bShow = bInCombat
	
	if self.showFrame < 2 then
		if unit:GetName() == GameLib.GetPlayerUnit():GetName() then
			self.wndCmbNotice:Show(bInCombat, true)
		end
	else
		self.wndCmbNotice:Show(false, true)
	end
end

---------------------------------------------------------------------------------------------------
-- EditorCover Functions
---------------------------------------------------------------------------------------------------
function PotatoCmbNotice:SelectFrame(wndHandler) --TODO: Generalize and move to PLib
	local PLib = Apollo.GetAddon("PotatoLib")
	PLib:ElementSelected(wndHandler, self, true)
	
	if PLib.wndCustomize:IsVisible() then
		self:OpenEditor()
	end
end

function PotatoCmbNotice:OnEditorSettingsBtn( wndHandler, wndControl, eMouseButton, nLastRelativeMouseX, nLastRelativeMouseY, bDoubleClick, bStopPropagation )
	if wndHandler ~= wndControl then return end
	
	self:OpenEditor()
	
	self:SelectFrame(self.wndCmbNotice)
end

function PotatoCmbNotice:OnEditorLockBtn( wndHandler, wndControl, eMouseButton, nLastRelativeMouseX, nLastRelativeMouseY, bDoubleClick, bStopPropagation )
	if wndHandler ~= wndControl then return end
	
	PotatoLib:HandleLockedWnd(self.wndCmbNotice, "Combat Icon")
end

function PotatoCmbNotice:OnEditorResetBtn( wndHandler, wndControl, eMouseButton, nLastRelativeMouseX, nLastRelativeMouseY, bDoubleClick, bStopPropagation )
	if wndHandler ~= wndControl then return end
	
	self:Reset()
end

---------------------------------------------------------------------------------------------------
-- Editor Functions  --TODO: Try to merge in PLib somehow.
---------------------------------------------------------------------------------------------------

function PotatoCmbNotice:SelectFrame(wndHandler) --TODO: Generalize and move to PLib
	local PLib = Apollo.GetAddon("PotatoLib")
	PLib:ElementSelected(wndHandler, self, true)
	
	if PLib.wndCustomize:IsVisible() then
		if self.name == "Special Castbar" then
			self:OpenSpecialEditor()
		else
			self:OpenEditor()
		end
	end
end

function PotatoCmbNotice:OpenEditor()
	local PLib = Apollo.GetAddon("PotatoLib")
	PLib.wndCustomize:FindChild("EditorContent"):DestroyChildren()
	
	if self.wndEditor then
		self.wndEditor:Destroy()
		self.wndEditor = nil
	end
	
	--Populate PotatoLib editor frame; Set title
	self.wndEditor = Apollo.LoadForm(self.xmlDoc, "CmbNoteCustomize", PLib.wndCustomize:FindChild("EditorContent"), self)
	self.wndEditor:Show(true)
	PLib.wndCustomize:FindChild("Title"):SetText(self.name .. " Settings")
	PLib.wndCustomize:Show(true)
	
	--Set frame visibility
	self.wndEditor:FindChild("ShowFrame"):FindChild("Options"):SetRadioSel("ShowFrame", self.showFrame)
	
	--[[Set background visibility and color
	self.wndEditor:FindChild("Background"):FindChild("EnableBtn"):SetCheck(self.background.show)
	self.wndEditor:FindChild("Background"):FindChild("Color"):SetBGColor("FF"..self.background.color)
	self.wndEditor:FindChild("Background"):FindChild("HexText"):SetText(self.background.color)
	
	--Set border visibility and color
	self.wndEditor:FindChild("Border"):FindChild("EnableBtn"):SetCheck(self.border.show)
	self.wndEditor:FindChild("Border"):FindChild("Color"):SetBGColor("FF"..self.border.color)
	self.wndEditor:FindChild("Border"):FindChild("HexText"):SetText(self.border.color)
	--self.wndEditor:FindChild("Border"):FindChild("BorderSize:SizeValue"):SetText(self.border.size)]]--
	
	--Set position options
	local nX1, nY1, nX2, nY2 = self.wndCmbNotice:GetAnchorOffsets()
	local nAX1, nAY1, nAX2, nAY2 = self.wndCmbNotice:GetAnchorPoints()
	
	local nScreenX, nScreenY = Apollo.GetScreenSize()
	if self.wndEditor then
		if self.wndEditor:FindChild("XPos") ~= nil then
			local PLib = Apollo.GetAddon("PotatoLib")
			if PLib.bPositionCenter then
				nAX1 = nAX1-0.5
				nAY1 = nAY1-0.5
			end
			self.wndEditor:FindChild("XPos"):SetText((nAX1*nScreenX)+nX1)
			self.wndEditor:FindChild("YPos"):SetText((nAY1*nScreenY)+nY1)
			self.wndEditor:FindChild("Width"):SetText(nX2-nX1)
			self.wndEditor:FindChild("Height"):SetText(nY2-nY1)
		end
	end
end

--Frame sub-editor functions
function PotatoCmbNotice:OnShowChange( wndHandler, wndControl )
	local nShow = wndHandler:GetParent():GetRadioSel("ShowFrame")
	self.showFrame = nShow
	
	self:UpdateAppearance()
end

function PotatoCmbNotice:TxtPositionChanged( wndHandler, wndControl, strPos )
	local strChange = wndHandler:GetName()
	
	local nX1, nY1, nX2, nY2 = self.wndCmbNotice:GetAnchorOffsets()
	local nAX1, nAY1, nAX2, nAY2 = self.wndCmbNotice:GetAnchorPoints()

	local nWidth = nX2-nX1
	local nHeight = nY2-nY1
	local nScreenX, nScreenY = Apollo.GetScreenSize()
	
	local PLib = Apollo.GetAddon("PotatoLib")
	if PLib.bPositionCenter then
		nAX1 = nAX1-0.5
		nAX2 = nAX2-0.5
		nAY1 = nAY1-0.5
		nAY2 = nAY2-0.5
	end
	
	strPos = string.gsub(strPos, "[^\-0-9]", "")
	if #strPos > 1 and string.sub(strPos, 1, 1) == "0" then
		strPos = string.gsub(strPos, "0", "", 1)
	end
	
	if strPos == "" then
		strPos = "0"
	end
	
	if strPos ~= "-" then
		if strChange == "XPos" then
			self.wndCmbNotice:SetAnchorOffsets(strPos-(nAX1*nScreenX), nY1, strPos-(nAX2*nScreenX)+nWidth, nY2)
		elseif strChange == "YPos" then
			self.wndCmbNotice:SetAnchorOffsets(nX1, strPos-(nAY1*nScreenY), nX2, strPos-(nAY2*nScreenY)+nHeight)
		end
		PLib:MoveLockedWnds(self.wndCmbNotice)
	end

	wndHandler:SetText(strPos)
	wndHandler:SetSel(#strPos,#strPos)
end

function PotatoCmbNotice:TxtHWChanged( wndHandler, wndControl, strHW )
	local strChange = wndHandler:GetName()
	
	local nX1, nY1, nX2, nY2 = self.wndCmbNotice:GetAnchorOffsets()
	local nAX1, nAY1, nAX2, nAY2 = self.wndCmbNotice:GetAnchorPoints()
	
	strHW = string.gsub(strHW, "[^0-9]", "")
	if #strHW > 1 and string.sub(strHW, 1, 1) == "0" then
		strHW = string.gsub(strHW, "0", "", 1)
	end
	
	if strHW == "" then
		strHW = "0"
	end	
		
	if strChange == "Width" then
		self.wndCmbNotice:SetAnchorOffsets(nX1, nY1, nX1+strHW, nY2)
	elseif strChange == "Height" then
		self.wndCmbNotice:SetAnchorOffsets(nX1, nY1, nX2, nY1+strHW)
	end	
	
	wndHandler:SetText(strHW)
	wndHandler:SetSel(#strHW,#strHW)
end

-----------------------------------------------------------------------------------------------
-- PotatoCmbNotice Instance
-----------------------------------------------------------------------------------------------
local PotatoCmbNoticeInst = PotatoCmbNotice:new()
PotatoCmbNoticeInst:Init()
