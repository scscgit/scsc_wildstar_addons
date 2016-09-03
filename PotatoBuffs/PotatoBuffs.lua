-----------------------------------------------------------------------------------------------
-- Client Lua Script for PotatoBuffs
-- Copyright (c) Tyler T. Hardy. All rights reserved
-----------------------------------------------------------------------------------------------
 
require "Window"
 
-----------------------------------------------------------------------------------------------
-- PotatoBuffs Module Definition
-----------------------------------------------------------------------------------------------
local BuffBar = {}
local PotatoBuffs = {}
local Defaults = _G["PUIDefaults"]["Buffs"]
local bEditorMode = false

-----------------------------------------------------------------------------------------------
-- Initialization
-----------------------------------------------------------------------------------------------

function PotatoBuffs:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self 

    -- initialize variables here

    return o
end

function PotatoBuffs:Init()
	local bHasConfigureFunction = false
	local strConfigureButtonText = ""
	local tDependencies = {
		"PotatoLib"
	}
    Apollo.RegisterAddon(self, bHasConfigureFunction, strConfigureButtonText, tDependencies)
end

function PotatoBuffs:OnLoad() --Loaded 1st
	self.xmlDoc = XmlDoc.CreateFromFile("PotatoBuffs.xml")
	self.xmlDoc:RegisterCallback("OnDocLoaded", self)
end

function PotatoBuffs:OnDocLoaded() --Loaded 3rd
	if self.xmlDoc == nil and not self.xmlDoc:IsLoaded() then return end
	
	--Initialize all castbars
	for key, val in pairs(Defaults) do
		if type(val) == "table" and key ~= "__index" and string.find(key, "lua") then
			self[key] = BuffBar:new(self[key] or val) --Load from restored values (self[key] from OnRestore()), or use the default (val).
			if self[key] == val then
				--Print(key..":Defaulted")
			else
				--Print(key..":Loaded")
			end
			self[key]:Init(self)
		end
	end
		
	--Apollo.RegisterEventHandler("WindowManagementReady", "OnWindowManagementReady", self)
	Apollo.RegisterEventHandler("CharacterCreated", "OnCharacterCreated", self)
	Apollo.RegisterEventHandler("TargetUnitChanged", "OnTargetUnitChanged", self)
	Apollo.RegisterEventHandler("AlternateTargetUnitChanged", "OnAlternateTargetUnitChanged", self)
	Apollo.RegisterEventHandler("SubZoneChanged", "OnSubZoneChanged", self)	
	
	Apollo.RegisterEventHandler("PotatoEditor",					"EditorModeToggle", self)
	Apollo.RegisterEventHandler("PotatoReset",					"ResetAll", self)
	Apollo.RegisterEventHandler("PotatoSettings",				"PopulateSettingsList", self)
	Apollo.RegisterEventHandler("PotatoResetPopulate",			"PopulateResetFeatures", self)

	if GameLib.GetPlayerUnit() == nil then
		Apollo.RegisterEventHandler("CharacterCreated", "OnCharacterCreated", self)
	else
		self:OnCharacterCreated()
	end
	
	Apollo.RegisterEventHandler("VarChange_FrameCount", "OnFrame", self)
end

function PotatoBuffs:PopulateResetFeatures()
	PotatoLib:AddResetParent("Buffs")
	PotatoLib:AddResetParent("Debuffs")
	
	for key, val in pairs(Defaults) do
		if type(val) == "table" and key ~= "__index" and string.find(key, "lua") then
			if string.find(key, "Buffs") then
				PotatoLib:AddResetItem(val.name, "Buffs", self[key])
			elseif string.find(key, "Debuffs") then
				PotatoLib:AddResetItem(val.name, "Debuffs", self[key])
			end
		end
	end
end

function PotatoBuffs:EditorModeToggle(bState)
	bEditorMode = bState
	
	for key, val in pairs(self) do
		if type(val) == "table" and val.wndBuffBar then
			if bEditorMode then
				val.wndCover = Apollo.LoadForm("../PotatoLib/PotatoLib.xml", "EditorCover", val.wndBuffBar, val)
				val.wndCover:SetText(val.name)
				--[[if val.border.show then
					val.wndCover:SetAnchorOffsets(val.border.size, val.border.size, -val.border.size, -val.border.size)
				else]]--
					val.wndCover:SetAnchorOffsets(0,0,0,0)
				--end
				val.wndBuffBar:Show(true)
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
			val.wndBuffBar:SetStyle("Moveable", bEditorMode)
			val.wndBuffBar:SetStyle("Sizable", bEditorMode)
			val.wndBuffBar:SetStyle("IgnoreMouse", not bEditorMode)
			for _, wndBuff in pairs(val.wndBuffBar:FindChild("Buffs"):GetChildren()) do
				wndBuff:SetStyle("IgnoreMouse", bEditorMode)
			end
		end
	end
end

function PotatoBuffs:OnFrame()
	self:OnCharacterCreated() --TODO: Check to see if necessary. Performance decrease.
end

function PotatoBuffs:OnTimer()

end

function BuffBar:ShouldShow(unit)
	if unit ~= nil then
		if self.showFrame == 1 then return true end
		if self.showFrame == 2 and (not PotatoLib:IsBarFull({"HP","SP"}, unit) or PotatoLib.bInCombat) then return true end
		if self.showFrame == 3 and PotatoLib.bInCombat then return true end
	end
	
	return false
end

function PotatoBuffs:OnCharacterCreated()
	local unitPlayer = GameLib.GetPlayerUnit()
	
	if unitPlayer ~= nil then
		if not bEditorMode then
			self.luaPlayerBuffs:SetTarget(unitPlayer)
			self.luaPlayerDebuffs:SetTarget(unitPlayer)
			
			local unitTarget = unitPlayer:GetTarget()
			self.luaTargetBuffs:SetTarget(unitTarget)
			self.luaTargetDebuffs:SetTarget(unitTarget)
			
			local unitToT = unitTarget and unitTarget:GetTarget() or nil
			self.luaToTBuffs:SetTarget(unitToT)
			self.luaToTDebuffs:SetTarget(unitToT)
			
			local altPlayerTarget = unitPlayer:GetAlternateTarget()
			self.luaFocusBuffs:SetTarget(altPlayerTarget)
			self.luaFocusDebuffs:SetTarget(altPlayerTarget)
		end
	end
end

function PotatoBuffs:OnTargetUnitChanged(unitTarget)
	self.luaTargetBuffs:SetTarget(unitTarget)
	self.luaTargetDebuffs:SetTarget(unitTarget)
	--self.luaToTBuffs:SetTarget(unitTarget and unitTarget:GetTarget() or nil)
end

function PotatoBuffs:OnAlternateTargetUnitChanged(unitTarget)
	--self.luaFocusCastbar:SetTarget(altPlayerTarget)
end

function PotatoBuffs:OnSubZoneChanged(nSubZoneId, strSubZone, nSomething)
	self:OnCharacterCreated()
end

function PotatoBuffs:ResetAll()
	for key, val in pairs(Defaults) do
		if type(val) == "table" and key ~= "__index" and string.find(key, "lua") then
			self[key].wndBuffBar:Destroy()
			self[key] = nil
			
			self[key] = BuffBar:new(val)
			self[key]:Init(self)
			self[key]:Position()
		end
	end
	self:EditorModeToggle(bEditorMode)
end

function PotatoBuffs:RemoveSystems(var)
	local t = {}
	
	if type(var) ~= "table" then
		return var
	end
	
	for key, val in pairs(var) do
		if key ~= "luaBuffSystem" then
			t[key] = self:RemoveSystems(val)
		end
	end
	
	return t
end

function PotatoBuffs:OnSave(eLevel)
    if eLevel ~= GameLib.CodeEnumAddonSaveLevel.Character then return end

	self.xmlDoc = nil
	
	local tSaveData = {}

    for key,val in pairs(self) do
		if type(val) == "table" and val.luaBuffSystem then	--Is a buffbar.
			tSaveData[key] = self:RemoveSystems(val)
			tSaveData[key].anchors = {val.wndBuffBar:GetAnchorPoints()}
			tSaveData[key].offsets = {val.wndBuffBar:GetAnchorOffsets()}
		else													--Is any other variable.
			tSaveData[key] = val
		end
	end

	return tSaveData
end

function PotatoBuffs:OnRestore(eLevel, tData) --Loaded 2nd
    if eLevel ~= GameLib.CodeEnumAddonSaveLevel.Character then return end
		
    for key,val in pairs(tData) do
		self[key] = TableUtil:Copy(val)
	end
	
	self.bLoaded = true
end

-----------------------------------------------------------------------------------------------
-- BuffBar Functions
-----------------------------------------------------------------------------------------------

function BuffBar:new(o)
	o = o or {}
	setmetatable(o, self)
	self.__index = self
	return o
end

function BuffBar:Init(luaBuffSystem)
	Apollo.LinkAddon(luaBuffSystem, self)
	self.luaBuffSystem = luaBuffSystem	
	
	self.wndBuffBar = Apollo.LoadForm(luaBuffSystem.xmlDoc, "BuffBar", "FixedHudStratum", self)
	--self.wndBuffs = Apollo.LoadForm(luaBuffSystem.xmlDoc, "Buffs", self.wndBuffBar, self)
	
	self:Position()
	self:UpdateBuffBarAppearance()
end

function BuffBar:UpdateBuffBarAppearance() --Creates or updates the visual appearance of the frame. Called when the frame is customized.
	--Background and Border
	self.wndBuffBar:FindChild("Content"):SetStyle("Picture", self.background.show)
	PotatoLib:UpdateBorder(self.wndBuffBar, self.wndBuffBar:FindChild("Content"), self.border)
	
	--Adjust buff window properties.
	local xmlFramesXml = self.luaBuffSystem.xmlDoc
	local tTableData = xmlFramesXml:ToTable()
	
	tTableData[4].AlignBuffsRight = self.alignRight and 1 or 0
	tTableData[4].BeneficialBuffs = self.buffs and 1 or 0
	tTableData[4].HarmfulBuffs = self.buffs and 0 or 1
	
	if self.wndBuffs then self.wndBuffs:Destroy() end
	self.wndBuffs = Apollo.LoadForm(XmlDoc.CreateFromTable(tTableData), "Buffs", self.wndBuffBar, self)
	if self.unitTarget then
		self.wndBuffs:SetUnit(self.unitTarget)
	end
	
	xmlFramesXml = nil
end

function BuffBar:Position()
	self.wndBuffBar:SetAnchorPoints(unpack(self.anchors))
	self.wndBuffBar:SetAnchorOffsets(unpack(self.offsets))
	--Print(string.format("%s: %s, %s, %s, %s", self.name, unpack(self.offsets)))
end

function BuffBar:SetTarget(unitTarget)
	if self:ShouldShow(unitTarget) then
		if self.unitTarget ~= unitTarget then
			self.wndBuffBar:Show(unitTarget ~= nil)
			self.wndBuffs:SetUnit(unitTarget)
		end
	elseif self.wndBuffBar:IsShown() then
		self.wndBuffBar:Show(false)
	end
	self.unitTarget = unitTarget
end

function BuffBar:OnGenerateTooltip(wndHandler, wndControl, eType, spl)
	if wndControl == wndHandler then
		return nil
	end
	Tooltip.GetBuffTooltipForm(self, wndControl, spl)
end	

function BuffBar:OnCastbarResize( wndHandler, wndControl )
	if wndHandler ~= wndControl then return end
	local nBorder = self.border.size
	
	if wndHandler:FindChild("Icon"):GetWidth() ~= wndHandler:GetHeight()-nBorder*2 then
		self:FitCastIconToBar(wndHandler)
	end
end

function BuffBar:WindowMove( wndHandler, wndControl, nOldLeft, nOldTop, nOldRight, nOldBottom )
	PotatoLib:WindowMove(wndHandler)--, nOldLeft, nOldTop, true)
end

---------------------------------------------------------------------------------------------------
-- Editor Functions  --TODO: Try to merge in PLib somehow.
---------------------------------------------------------------------------------------------------

function BuffBar:SelectFrame(wndHandler) --TODO: Generalize and move to PLib
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

function BuffBar:OpenEditor()
	local PLib = Apollo.GetAddon("PotatoLib")
	PLib.wndCustomize:FindChild("EditorContent"):DestroyChildren()
	
	if self.wndEditor then
		self.wndEditor:Destroy()
		self.wndEditor = nil
	end
	
	--Populate PotatoLib editor frame; Set title
	self.wndEditor = Apollo.LoadForm(self.luaBuffSystem.xmlDoc, "BuffCustomize", PLib.wndCustomize:FindChild("EditorContent"), self)
	self.wndEditor:Show(true)
	PLib.wndCustomize:FindChild("Title"):SetText(self.name .. " Settings")
	PLib.wndCustomize:Show(true)
	
	--Set frame visibility
	self.wndEditor:FindChild("ShowFrame"):FindChild("Options"):SetRadioSel("ShowFrame", self.showFrame)
	
	--Set buff fill direction
	self.wndEditor:FindChild("FillDirection"):FindChild("Options"):SetRadioSel("BuffPos", self.alignRight and 2 or 1)
	
	--[[Set background visibility and color
	self.wndEditor:FindChild("Background"):FindChild("EnableBtn"):SetCheck(self.background.show)
	self.wndEditor:FindChild("Background"):FindChild("Color"):SetBGColor("FF"..self.background.color)
	self.wndEditor:FindChild("Background"):FindChild("HexText"):SetText(self.background.color)
	
	--Set border visibility and color
	self.wndEditor:FindChild("Border"):FindChild("EnableBtn"):SetCheck(self.border.show)
	self.wndEditor:FindChild("Border"):FindChild("Color"):SetBGColor("FF"..self.border.color)
	self.wndEditor:FindChild("Border"):FindChild("HexText"):SetText(self.border.color)
	self.wndEditor:FindChild("Border"):FindChild("BorderSize:SizeValue"):SetText(self.border.size)]]--
	
	--Set position options
	local nX1, nY1, nX2, nY2 = self.wndBuffBar:GetAnchorOffsets()
	local nAX1, nAY1, nAX2, nAY2 = self.wndBuffBar:GetAnchorPoints()
	
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
function BuffBar:OnShowChange( wndHandler, wndControl )
	local nShow = wndHandler:GetParent():GetRadioSel("ShowFrame")
	self.showFrame = nShow
	
	self:UpdateBuffBarAppearance()
end

function BuffBar:OnChangeBuffPos( wndHandler, wndControl, eMouseButton )
	local bIsRight = wndHandler:GetParent():GetRadioSel("BuffPos") == 2
	self.alignRight = bIsRight
	
	self:UpdateBuffBarAppearance()
end

--[[function BuffBar:OnChangeBG( wndHandler, wndControl, eMouseButton ) --TODO: BG options for buffs
	local bCheck = wndHandler:IsChecked()	
	self.background.show = bCheck
	
	self:UpdateBuffBarAppearance()
end

function BuffBar:IncrementBorderSize( wndHandler, wndControl, eMouseButton )
	local nChange = wndHandler:GetName() == "SizeValueUp" and 1 or -1
	
	--Set data value
	self.border.size = self.border.size + nChange
	
	if self.border.size == 1 or self.border.size == 20 then
		wndHandler:Enable(false)
	else
		for key, val in pairs(wndHandler:GetParent():GetChildren()) do
			if val.Enable then
				val:Enable(true)
			end
		end
	end	
	
	--Set editor window
	wndHandler:GetParent():FindChild("SizeValue"):SetText(self.border.size)
	
	self:UpdateBuffBarAppearance()
end

function BuffBar:OnShowBorder( wndHandler, wndControl, eMouseButton ) --TODO: REVAMP
	Print("OnShowBorder")
	local bCheck = wndHandler:IsChecked()
	self.border.show = bCheck
	
	self:UpdateBuffBarAppearance()
end]]--

function BuffBar:TxtPositionChanged( wndHandler, wndControl, strPos )
	local strChange = wndHandler:GetName()
	
	local nX1, nY1, nX2, nY2 = self.wndBuffBar:GetAnchorOffsets()
	local nAX1, nAY1, nAX2, nAY2 = self.wndBuffBar:GetAnchorPoints()

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
			self.wndBuffBar:SetAnchorOffsets(strPos-(nAX1*nScreenX), nY1, strPos-(nAX2*nScreenX)+nWidth, nY2)
		elseif strChange == "YPos" then
			self.wndBuffBar:SetAnchorOffsets(nX1, strPos-(nAY1*nScreenY), nX2, strPos-(nAY2*nScreenY)+nHeight)
		end
		PLib:MoveLockedWnds(self.wndBuffBar)
	end

	wndHandler:SetText(strPos)
	wndHandler:SetSel(#strPos,#strPos)
end

function BuffBar:TxtHWChanged( wndHandler, wndControl, strHW )
	local strChange = wndHandler:GetName()
	
	local nX1, nY1, nX2, nY2 = self.wndBuffBar:GetAnchorOffsets()
	local nAX1, nAY1, nAX2, nAY2 = self.wndBuffBar:GetAnchorPoints()
	
	strHW = string.gsub(strHW, "[^0-9]", "")
	if #strHW > 1 and string.sub(strHW, 1, 1) == "0" then
		strHW = string.gsub(strHW, "0", "", 1)
	end
	
	if strHW == "" then
		strHW = "0"
	end	
		
	if strChange == "Width" then
		self.wndBuffBar:SetAnchorOffsets(nX1, nY1, nX1+strHW, nY2)
	elseif strChange == "Height" then
		self.wndBuffBar:SetAnchorOffsets(nX1, nY1, nX2, nY1+strHW)
	end	
	
	wndHandler:SetText(strHW)
	wndHandler:SetSel(#strHW,#strHW)
end

---------------------------------------------------------------------------------------------------
-- EditorCover Functions
---------------------------------------------------------------------------------------------------

function BuffBar:OnEditorSettingsBtn( wndHandler, wndControl, eMouseButton, nLastRelativeMouseX, nLastRelativeMouseY, bDoubleClick, bStopPropagation )
	if wndHandler ~= wndControl then return end
	self:OpenEditor()
	self:SelectFrame(self.wndBuffBar)
end

function BuffBar:OnEditorLockBtn( wndHandler, wndControl, eMouseButton, nLastRelativeMouseX, nLastRelativeMouseY, bDoubleClick, bStopPropagation )
	if wndHandler ~= wndControl then return end

	PotatoLib:HandleLockedWnd(self.wndBuffBar, self.name)
end

function BuffBar:OnPRFReset()
	self:Reset()
end

function BuffBar:Reset()
	local strBuff = ""
	for key, val in pairs(self.luaBuffSystem) do
		if val == self then
			strBuff = key
			break
		end
	end
	
	for key, val in pairs(Defaults[strBuff]) do
		if key ~= "__index" then
			self[key] = TableUtil:Copy(val)
		end
	end
	
	self:Position()
	self:UpdateBuffBarAppearance()
	--TODO: RESTORE EDITOR STUFF
end

function BuffBar:OnEditorResetBtn( wndHandler, wndControl, eMouseButton, nLastRelativeMouseX, nLastRelativeMouseY, bDoubleClick, bStopPropagation )
	if wndHandler ~= wndControl then return end
	self:Reset()
end

function BuffBar:EditorSelectWindow( wndHandler, wndControl, eMouseButton, nLastRelativeMouseX, nLastRelativeMouseY, bDoubleClick, bStopPropagation )
	if wndHandler ~= wndControl then return end
	
	if bEditorMode then
		if eMouseButton == 1 then --Right-clicked
			self:OpenEditor()
		end
		self:SelectFrame(self.wndBuffBar)
	end
end

-----------------------------------------------------------------------------------------------
-- PotatoBuffs Instance
-----------------------------------------------------------------------------------------------
local PotatoBuffsInst = PotatoBuffs:new()
PotatoBuffsInst:Init()
